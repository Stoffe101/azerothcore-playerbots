#include "TitanRune.h"

#include "Chat.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "Group.h"
#include "Item.h"
#include "ItemTemplate.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Random.h"
#include "TemporarySummon.h"
#include "Timer.h"

#include <algorithm>
#include <cmath>
#include <mutex>
#include <sstream>
#include <unordered_map>
#include <unordered_set>
#include <utility>

namespace
{
    struct InstanceKey
    {
        uint32 mapId = 0;
        uint32 instanceId = 0;

        bool operator==(InstanceKey const& rhs) const
        {
            return mapId == rhs.mapId && instanceId == rhs.instanceId;
        }
    };

    struct InstanceKeyHash
    {
        std::size_t operator()(InstanceKey const& k) const noexcept
        {
            return (static_cast<std::size_t>(k.mapId) << 32) ^ k.instanceId;
        }
    };

    struct CreatureState
    {
        bool scaled = false;
        uint32 nextProc = 0;
        uint32 nextPulse = 0;
        uint8 titanStacks = 0;
        bool tentacleVulnerable = false;
    };

    struct FrostPatch
    {
        float x = 0.f, y = 0.f, z = 0.f;
        uint32 expires = 0;
    };

    struct BloodPool
    {
        float x = 0.f, y = 0.f, z = 0.f;
        uint32 expires = 0;
        bool poisoned = false;
    };

    struct InstanceState
    {
        TitanRune::Protocol protocol = TitanRune::Protocol::None;
        TitanRune::Family family = TitanRune::Family::None;
        std::unordered_map<uint64, CreatureState> creatures;
        std::vector<FrostPatch> frost;
        std::vector<BloodPool> blood;
        uint32 nextGlobalSpawn = 0;
        uint32 activatedAt = 0;
    };

    struct PlayerState
    {
        TitanRune::GammaBuff gammaBuff = TitanRune::GammaBuff::None;
        uint8 mirrorStacks = 0;
        uint32 mirrorExpires = 0;
        uint8 confessorStacks = 0;
        uint32 confessorClearAt = 0;
        uint32 rallyExpires = 0;
        uint32 shatterExpires = 0;
        uint64 shatterTarget = 0;
        uint32 brewExpires = 0;
        uint32 nextBrewTick = 0;
        uint32 fireBlastExpires = 0;
        uint32 nextFireTick = 0;
        uint32 blisteringExpires = 0;
        uint32 plagueExpires = 0;
        uint32 plagueAura = 0;
        uint8 purifiedStacks = 0;
        uint32 nextPurifiedPulse = 0;
    };

    std::unordered_map<InstanceKey, InstanceState, InstanceKeyHash> g_instances;
    std::unordered_map<uint64, PlayerState> g_players;
    std::mutex g_lock;

    constexpr uint32 SPELL_WEB_WRAP = 52086;
    constexpr uint32 SPELL_FROST_SLOW = 45524;      // Chains of Ice visual + snare, exists in 3.3.5a.
    constexpr uint32 SPELL_PLAGUE_MARK = 55095;     // Frost Fever, used as a cleanseable disease marker.
    constexpr uint32 SPELL_ARCANE_MISSILES = 42846;
    constexpr uint32 SPELL_SHADOW_BOLT = 47809;
    constexpr uint32 SPELL_FLASH_HEAL = 48071;

    constexpr uint32 ALPHA_EMBLEM = 45624;          // Emblem of Conquest, native 3.3.5 item.

    bool IsCustomCreature(uint32 entry)
    {
        return entry >= TitanRune::NPC_PROTOCOL_DEVICE && entry <= TitanRune::NPC_SCOURGESTONE_VENDOR_H;
    }

    InstanceKey Key(Map const* map)
    {
        return map ? InstanceKey{map->GetId(), map->GetInstanceId()} : InstanceKey{};
    }

    InstanceKey Key(Unit const* unit)
    {
        return unit ? Key(unit->GetMap()) : InstanceKey{};
    }

    bool IsFinalBoss(uint32 entry)
    {
        switch (entry)
        {
            case 29311: case 29120: case 26632: case 29306: case 28923: case 27978:
            case 26533: case 26723: case 27656: case 31134: case 35451: case 23954: case 26861:
                return true;
            default:
                return false;
        }
    }

    bool IsGammaBoss(uint32 entry)
    {
        static std::unordered_set<uint32> const bosses = {
            29309,29308,30258,29310,29311,
            28684,28921,29120,
            26630,26631,27483,26632,
            29304,29307,29305,29932,29306,
            28586,28587,28546,28923,
            27977,27975,28234,27978,
            26529,26530,26532,32273,26533,
            26796,26798,26731,26763,26794,26723,
            27654,27447,27655,27656,
            29315,29316,29313,29266,29312,29314,31134,
            34705,34702,34701,34657,34703,35572,35569,35571,35570,35617,35119,34928,35451,
            23953,24200,24201,23954,
            26668,26687,26693,26861
        };
        return bosses.count(entry) != 0;
    }

    float HealthBonus(TitanRune::Protocol p, TitanRune::Family f)
    {
        if (p == TitanRune::Protocol::Alpha)
            return f == TitanRune::Family::Titan ? 1.18f : 0.50f;
        if (p == TitanRune::Protocol::Beta)
        {
            if (f == TitanRune::Family::Titan) return 5.80f;
            if (f == TitanRune::Family::Blood) return 1.80f;
            if (f == TitanRune::Family::Shadow) return 1.50f;
            return 1.20f;
        }
        if (p == TitanRune::Protocol::Gamma)
        {
            if (f == TitanRune::Family::Titan) return 8.80f;
            if (f == TitanRune::Family::Blood) return 3.05f;
            if (f == TitanRune::Family::Shadow) return 2.60f;
            return 2.15f;
        }
        return 0.f;
    }

    float DamageBonus(TitanRune::Protocol p, TitanRune::Family f)
    {
        if (p == TitanRune::Protocol::Alpha)
            return f == TitanRune::Family::Titan ? 0.05f : 0.17f;
        if (p == TitanRune::Protocol::Beta)
            return 0.40f;
        if (p == TitanRune::Protocol::Gamma)
            return 0.70f;
        return 0.f;
    }

    bool AddItem(Player* player, uint32 itemId, uint32 count)
    {
        if (!player || !itemId || !count)
            return false;
        ItemPosCountVec dest;
        InventoryResult result = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, itemId, count);
        if (result != EQUIP_ERR_OK)
        {
            player->SendEquipError(result, nullptr, nullptr, itemId);
            return false;
        }
        player->StoreNewItem(dest, itemId, true);
        return true;
    }

    void Message(Player* player, std::string const& text)
    {
        if (player && player->GetSession())
            ChatHandler(player->GetSession()).SendSysMessage(text);
    }

    void MessageMap(Map* map, std::string const& text)
    {
        if (!map)
            return;
        for (auto const& ref : map->GetPlayers())
            if (Player* p = ref.GetSource())
                Message(p, text);
    }

    bool IsValidDungeonCreature(Creature* c)
    {
        if (!c || !c->IsAlive() || IsCustomCreature(c->GetEntry()))
            return false;
        Map* map = c->GetMap();
        if (!map || !map->IsHeroic() || !TitanRune::IsSupportedMap(map->GetId()))
            return false;
        return c->IsHostileToPlayers();
    }

    Player* RandomAlivePlayer(Map* map)
    {
        std::vector<Player*> players;
        if (!map)
            return nullptr;
        for (auto const& ref : map->GetPlayers())
            if (Player* p = ref.GetSource())
                if (p->IsAlive() && !p->IsGameMaster())
                    players.push_back(p);
        return players.empty() ? nullptr : players[urand(0, players.size() - 1)];
    }

    Creature* SummonHelper(Creature* source, uint32 entry, Player* near, uint32 despawnMs)
    {
        if (!source || !near)
            return nullptr;
        Position pos = near->GetPosition();
        float angle = frand(0.f, 6.2831853f);
        float dist = frand(2.f, 5.f);
        pos.m_positionX += std::cos(angle) * dist;
        pos.m_positionY += std::sin(angle) * dist;
        return source->SummonCreature(entry, pos, TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, despawnMs);
    }

    void GrantMirrorStack(Map* map)
    {
        if (!map)
            return;
        uint32 now = getMSTime();
        std::lock_guard<std::mutex> guard(g_lock);
        for (auto const& ref : map->GetPlayers())
        {
            Player* player = ref.GetSource();
            if (!player || !player->IsAlive())
                continue;
            PlayerState& ps = g_players[player->GetGUID().GetCounter()];
            ps.mirrorStacks = std::min<uint8>(6, static_cast<uint8>(ps.mirrorStacks + 1));
            ps.mirrorExpires = now + 30000;
        }
    }

    void DropBloodPool(Creature* c, InstanceState& state)
    {
        BloodPool pool;
        pool.x = c->GetPositionX(); pool.y = c->GetPositionY(); pool.z = c->GetPositionZ();
        pool.expires = getMSTime() + 30000;
        state.blood.push_back(pool);
    }

    void DropFrostPatch(Player* p, InstanceState& state)
    {
        FrostPatch patch;
        patch.x = p->GetPositionX(); patch.y = p->GetPositionY(); patch.z = p->GetPositionZ();
        patch.expires = getMSTime() + 25000;
        state.frost.push_back(patch);
        p->CastSpell(p, SPELL_FROST_SLOW, true);
    }

    bool Near(float x, float y, float z, Unit const* u, float radius)
    {
        if (!u)
            return false;
        float dx = x - u->GetPositionX();
        float dy = y - u->GetPositionY();
        float dz = z - u->GetPositionZ();
        return dx*dx + dy*dy + dz*dz <= radius*radius;
    }

    std::vector<TitanRune::VendorItem> const kSidereal = {
        {47556,3},
        {45868,38},{46035,38},{46067,38},{45886,38},{45870,38},{45990,38},{46033,38},
        {46039,32},{46049,32},
        {45867,25},{46097,25},{45930,25},{45982,25},{45295,25},{45887,25},{46034,25},{45993,25},{45448,25},{45947,25},{45876,25},{45877,25},{45449,25},{46036,25},
        {46038,24},{46043,24},{46051,24},{46044,24},{46045,24},{46037,24},{46041,24},{46050,24},
        {46068,19},{46048,19},{45455,19},{45928,19},{45988,19},{45293,19},{45300,19},{45931,19},{46046,19},{46047,19},{45929,19},{46095,19},{46040,19},{45989,19},{45943,19},
        {45888,15},{46032,15},{45946,15},{45869,15},{45456,15},{45933,15},{45294,15},{45871,15},{45945,15},{45297,15},{46096,15},{45447,15},{45296,15}
    };

    std::vector<TitanRune::VendorItem> CommonScourge()
    {
        return {
            {TitanRune::ITEM_SIDEREAL_ESSENCE,1},{49908,12},{47242,20},
            {45461,60},{45242,60},{45486,60},{45496,60},{45495,60},{45471,60},{45534,60},{45485,60},
            {45443,60},{45459,60},{45133,60},{45517,60},{45243,60},{45609,60},{45518,60},{45535,60}
        };
    }

    std::vector<TitanRune::VendorItem> BuildAlliance()
    {
        auto v = CommonScourge();
        TitanRune::VendorItem extra[] = {
            {47089,30},{46970,30},{47225,30},{47042,30},{46976,30},{47183,30},
            {46985,38},{47092,38},{46988,38},{47090,38},{46997,38},{47194,38},{47150,38},{47106,38},{47071,38},
            {47054,30},{46959,30},{47070,30},{47223,30},{47149,30},{47138,30},{47053,30},
            {46979,60},{47193,60},{47043,30},{47116,30},{47105,30},{47139,30},
            {46996,50},{46958,50},{47148,50},{47104,50},{46994,76},{47079,50},{46963,50},
            {47115,38},{47182,38},{47080,38},{47041,38},{47233,76},{47069,76},{47114,76},
            {47152,38},{47195,38},{46990,38},{47107,38},{46999,38},{47081,38},{47140,38},{46972,38},{47072,38},
            {47203,30},{47141,30},{46961,30},{47056,30},{47151,30},{47055,30},{47108,30},{47073,30},{47093,30}
        };
        v.insert(v.end(), std::begin(extra), std::end(extra));
        return v;
    }

    std::vector<TitanRune::VendorItem> BuildHorde()
    {
        auto v = CommonScourge();
        TitanRune::VendorItem extra[] = {
            {47257,30},{47256,30},{47328,30},{47320,30},{47275,30},{47291,30},
            {47262,38},{47321,38},{47269,38},{47296,38},{47312,38},{47284,38},{47263,38},{47295,38},{47293,38},
            {47282,30},{47315,30},{47278,30},{47327,30},{47252,30},{47309,30},{47276,30},
            {47261,60},{47322,60},{47272,30},{47307,30},{47305,30},{47297,30},
            {47266,50},{47300,50},{47314,50},{47255,50},{47267,76},{47287,50},{47260,50},
            {47303,38},{47290,38},{47316,38},{47271,38},{47285,76},{47329,76},{47302,76},
            {47286,38},{47283,38},{47308,38},{47299,38},{47258,38},{47265,38},{47268,38},{47323,38},{47311,38},
            {47313,30},{47298,30},{47324,30},{47277,30},{47253,30},{47294,30},{47281,30},{47306,30},{47280,30}
        };
        v.insert(v.end(), std::begin(extra), std::end(extra));
        return v;
    }

    std::vector<TitanRune::VendorItem> const kScourgeAlliance = BuildAlliance();
    std::vector<TitanRune::VendorItem> const kScourgeHorde = BuildHorde();

    void RewardPlayers(Creature* boss, TitanRune::Protocol protocol)
    {
        if (!boss || !boss->GetMap())
            return;

        uint32 entry = boss->GetEntry();
        bool finalBoss = IsFinalBoss(entry);
        bool gammaBoss = IsGammaBoss(entry);

        for (auto const& ref : boss->GetMap()->GetPlayers())
        {
            Player* player = ref.GetSource();
            if (!player || !player->IsAlive() || player->IsGameMaster())
                continue;

            if (protocol == TitanRune::Protocol::Alpha && finalBoss)
            {
                AddItem(player, ALPHA_EMBLEM, 1);
                Message(player, "Defense Protocol Alpha complete: +1 Emblem of Conquest.");
            }
            else if (protocol == TitanRune::Protocol::Beta && finalBoss)
            {
                AddItem(player, TitanRune::ITEM_SIDEREAL_ESSENCE, 1);
                Message(player, "Defense Protocol Beta complete: +1 Sidereal Essence.");
            }
            else if (protocol == TitanRune::Protocol::Gamma && gammaBoss)
            {
                AddItem(player, TitanRune::ITEM_DEFILERS_SCOURGESTONE, 1);
                Message(player, "Defense Protocol Gamma boss defeated: +1 Defiler's Scourgestone.");
            }
            else if (protocol == TitanRune::Protocol::Gamma &&
                     (boss->GetMapId() == 632 || boss->GetMapId() == 658 || boss->GetMapId() == 668) && boss->IsDungeonBoss())
            {
                // Frozen Halls did not use the Titan Rune selector in Wrath Classic, but its
                // heroic bosses participated in the Gamma-era Scourgestone catch-up economy.
                AddItem(player, TitanRune::ITEM_DEFILERS_SCOURGESTONE, 1);
                Message(player, "Gamma-era Frozen Halls reward: +1 Defiler's Scourgestone.");
            }
        }
    }
}

bool TitanRune::IsSupportedMap(uint32 mapId)
{
    switch (mapId)
    {
        case 574: case 575: // Utgarde Keep / Pinnacle
        case 576: case 578: case 608: // Nexus / Oculus / Violet Hold
        case 595: // Culling
        case 600: case 604: // Drak'Tharon / Gundrak
        case 601: case 619: // Azjol / Ahn'kahet
        case 599: case 602: // Halls of Stone / Lightning
        case 650: // Trial of the Champion
            return true;
        default:
            return false;
    }
}

bool TitanRune::SupportsAlpha(uint32 mapId)
{
    return IsSupportedMap(mapId) && mapId != 650;
}

TitanRune::Family TitanRune::GetFamily(uint32 mapId)
{
    switch (mapId)
    {
        case 574: case 575: return Family::Frost;
        case 576: case 578: case 608: return Family::Arcane;
        case 595: return Family::Plague;
        case 600: case 604: return Family::Blood;
        case 601: case 619: return Family::Shadow;
        case 599: case 602: return Family::Titan;
        case 650: return Family::Gladiator;
        default: return Family::None;
    }
}

char const* TitanRune::FamilyName(Family family)
{
    switch (family)
    {
        case Family::Frost: return "Frost";
        case Family::Shadow: return "Shadow";
        case Family::Blood: return "Blood";
        case Family::Arcane: return "Arcane";
        case Family::Plague: return "Plague";
        case Family::Titan: return "Titan";
        case Family::Gladiator: return "Gladiator";
        default: return "None";
    }
}

char const* TitanRune::ProtocolName(Protocol protocol)
{
    switch (protocol)
    {
        case Protocol::Alpha: return "Alpha";
        case Protocol::Beta: return "Beta";
        case Protocol::Gamma: return "Gamma";
        default: return "None";
    }
}

TitanRune::Protocol TitanRune::GetProtocol(Map const* map)
{
    if (!map)
        return Protocol::None;
    std::lock_guard<std::mutex> guard(g_lock);
    auto it = g_instances.find(Key(map));
    return it == g_instances.end() ? Protocol::None : it->second.protocol;
}

TitanRune::Protocol TitanRune::GetProtocol(Unit const* unit)
{
    return unit ? GetProtocol(unit->GetMap()) : Protocol::None;
}

bool TitanRune::Activate(Player* player, Protocol protocol)
{
    if (!player || protocol == Protocol::None)
        return false;
    Map* map = player->GetMap();
    if (!map || !map->IsHeroic() || !IsSupportedMap(map->GetId()))
        return false;
    if (protocol == Protocol::Alpha && !SupportsAlpha(map->GetId()))
        return false;
    if (Group* group = player->GetGroup())
        if (!group->IsLeader(player->GetGUID()))
        {
            Message(player, "Only the group leader can activate a Defense Protocol.");
            return false;
        }

    {
        std::lock_guard<std::mutex> guard(g_lock);
        InstanceKey key = Key(map);
        InstanceState& state = g_instances[key];
        if (state.protocol != Protocol::None)
            return false;
        state.protocol = protocol;
        state.family = GetFamily(map->GetId());
        state.activatedAt = getMSTime();
        state.nextGlobalSpawn = getMSTime() + 12000;
    }

    CharacterDatabase.Execute(
        "REPLACE INTO mod_titan_rune_instance (map_id,instance_id,protocol,activated_at) VALUES ({},{},{},NOW())",
        map->GetId(), map->GetInstanceId(), static_cast<uint32>(protocol));

    MessageMap(map, std::string("Defense Protocol ") + ProtocolName(protocol) + " activated (" + FamilyName(GetFamily(map->GetId())) + " Rune).");

    // Gamma's four support choices are supplied by a Warden at the activation point. The Warden
    // is deliberately server-side/backported rather than relying on Wrath Classic-only DBCs.
    if (protocol == Protocol::Gamma)
        map->SummonCreature(NPC_GAMMA_WARDEN, player->GetPosition(), nullptr, 0, nullptr);
    if ((protocol == Protocol::Beta || protocol == Protocol::Gamma) && GetFamily(map->GetId()) == Family::Blood)
        map->SummonCreature(NPC_BLOOD_CAULDRON, player->GetPosition(), nullptr, 0, nullptr);

    return true;
}

void TitanRune::OnPlayerEnter(Player* player)
{
    if (!player || !player->GetMap())
        return;
    Map* map = player->GetMap();
    if (!map->IsHeroic() || !IsSupportedMap(map->GetId()) || GetProtocol(map) != Protocol::None)
        return;

    // Summon the selector exactly where the group enters. This makes the backport work for every
    // supported dungeon without hard-coding thirteen internal entrance coordinates.
    bool already = false;
    for (auto const& ref : map->GetPlayers())
    {
        Player* p = ref.GetSource();
        if (!p)
            continue;
        std::list<Creature*> nearby;
        p->GetCreatureListWithEntryInGrid(nearby, NPC_PROTOCOL_DEVICE, 80.f);
        if (!nearby.empty()) { already = true; break; }
    }
    if (!already)
        map->SummonCreature(NPC_PROTOCOL_DEVICE, player->GetPosition(), nullptr, 0, nullptr);
}

void TitanRune::OnCreatureUpdate(Creature* creature, uint32 /*diff*/)
{
    if (!IsValidDungeonCreature(creature))
        return;

    Protocol protocol = GetProtocol(creature);
    if (protocol == Protocol::None)
        return;

    uint32 now = getMSTime();
    InstanceKey key = Key(creature);
    Family family = GetFamily(creature->GetMapId());
    bool doProc = false;
    bool doGlobalSpawn = false;
    {
        std::lock_guard<std::mutex> guard(g_lock);
        InstanceState& state = g_instances[key];
        CreatureState& cs = state.creatures[creature->GetGUID().GetRawValue()];
        if (!cs.scaled)
        {
            float bonus = HealthBonus(protocol, family);
            uint64 maxHp = static_cast<uint64>(creature->GetMaxHealth() * (1.0f + bonus));
            creature->SetMaxHealth(static_cast<uint32>(std::min<uint64>(maxHp, 0xFFFFFFFFULL)));
            creature->SetFullHealth();
            cs.scaled = true;
            cs.nextProc = now + urand(5000, 9000);
            cs.nextPulse = now + 2000;
        }

        if (creature->IsInCombat() && now >= cs.nextProc)
        {
            doProc = true;
            cs.nextProc = now + urand(7000, 12000);
        }
        if (family == Family::Titan && creature->IsInCombat() && now >= cs.nextPulse)
        {
            cs.nextPulse = now + 2000;
            if (protocol == Protocol::Alpha)
                cs.titanStacks = std::min<uint8>(20, static_cast<uint8>(cs.titanStacks + 1));
        }
        if (now >= state.nextGlobalSpawn && creature->IsInCombat())
        {
            state.nextGlobalSpawn = now + urand(18000, 28000);
            doGlobalSpawn = true;
        }
        state.frost.erase(std::remove_if(state.frost.begin(), state.frost.end(), [now](FrostPatch const& p){ return now >= p.expires; }), state.frost.end());
        state.blood.erase(std::remove_if(state.blood.begin(), state.blood.end(), [now](BloodPool const& p){ return now >= p.expires; }), state.blood.end());
    }

    if (doProc)
    {
        Player* victim = RandomAlivePlayer(creature->GetMap());
        if (victim)
        {
            if (family == Family::Frost)
            {
                std::lock_guard<std::mutex> guard(g_lock);
                DropFrostPatch(victim, g_instances[key]);
                if (protocol != Protocol::Alpha)
                {
                    PlayerState& ps = g_players[victim->GetGUID().GetCounter()];
                    ps.fireBlastExpires = now + 30000;
                    ps.nextFireTick = now + 10000;
                }
            }
            else if (family == Family::Shadow)
            {
                victim->CastSpell(victim, SPELL_WEB_WRAP, true);
                if (protocol != Protocol::Alpha)
                {
                    // Shadow Imbuement is represented as a one-use 150% outgoing bonus once the
                    // web ends. We store it in shatterExpires with target=0 to keep PlayerState
                    // compact; OnUnitDamage consumes it only for Shadow-family instances.
                    std::lock_guard<std::mutex> guard(g_lock);
                    g_players[victim->GetGUID().GetCounter()].shatterExpires = now + 15000;
                }
            }
            else if (family == Family::Arcane)
            {
                SummonHelper(creature, NPC_ARCANE_MIRROR_CASTER, victim, 15000);
                SummonHelper(creature, protocol == Protocol::Alpha ? NPC_ARCANE_MIRROR_CASTER : NPC_ARCANE_MIRROR_MELEE, victim, 15000);
                if (protocol != Protocol::Alpha)
                    SummonHelper(creature, NPC_ARCANE_MIRROR_HEALER, victim, 15000);
            }
            else if (family == Family::Plague)
            {
                victim->CastSpell(victim, SPELL_PLAGUE_MARK, true);
                std::lock_guard<std::mutex> guard(g_lock);
                PlayerState& ps = g_players[victim->GetGUID().GetCounter()];
                ps.plagueAura = SPELL_PLAGUE_MARK;
                ps.plagueExpires = now + 60000;
            }
            else if (family == Family::Blood)
            {
                std::lock_guard<std::mutex> guard(g_lock);
                DropBloodPool(creature, g_instances[key]);
            }
        }
    }

    if (doGlobalSpawn && protocol != Protocol::Alpha)
    {
        Player* near = RandomAlivePlayer(creature->GetMap());
        if (near && family == Family::Plague)
            SummonHelper(creature, NPC_PLAGUE_ZOMBIE_HORROR, near, 45000);
        else if (near && family == Family::Titan)
            SummonHelper(creature, NPC_TITAN_TENTACLE, near, 45000);
    }
}

void TitanRune::OnCreatureRemove(Creature* creature)
{
    if (!creature)
        return;
    std::lock_guard<std::mutex> guard(g_lock);
    auto it = g_instances.find(Key(creature));
    if (it != g_instances.end())
        it->second.creatures.erase(creature->GetGUID().GetRawValue());
}

void TitanRune::OnUnitDamage(Unit* attacker, Unit* victim, uint32& damage)
{
    if (!attacker || !victim || !damage)
        return;

    Protocol protocol = GetProtocol(attacker);
    Family family = GetFamily(attacker->GetMapId());

    // Dungeon creature outgoing damage scaling + family effects.
    if (protocol != Protocol::None && attacker->ToCreature() && !IsCustomCreature(attacker->GetEntry()))
    {
        damage = static_cast<uint32>(damage * (1.f + DamageBonus(protocol, family)));

        if (family == Family::Titan && protocol == Protocol::Alpha)
        {
            std::lock_guard<std::mutex> guard(g_lock);
            auto iit = g_instances.find(Key(attacker));
            if (iit != g_instances.end())
            {
                auto cit = iit->second.creatures.find(attacker->GetGUID().GetRawValue());
                if (cit != iit->second.creatures.end())
                    damage = static_cast<uint32>(damage * (1.f + 0.01f * cit->second.titanStacks));
            }
        }

        // Blood of the Loa: enemies standing in a normal pool leech 100% of damage; poisoned
        // pools invert the effect and burn the enemy instead.
        if (family == Family::Blood)
        {
            bool normalPool = false, poisonedPool = false;
            {
                std::lock_guard<std::mutex> guard(g_lock);
                auto it = g_instances.find(Key(attacker));
                if (it != g_instances.end())
                    for (BloodPool const& pool : it->second.blood)
                        if (Near(pool.x,pool.y,pool.z,attacker,5.f))
                            pool.poisoned ? poisonedPool = true : normalPool = true;
            }
            if (normalPool)
                attacker->ModifyHealth(static_cast<int32>(std::min<uint32>(damage, attacker->GetMaxHealth())));
            if (poisonedPool)
                attacker->ModifyHealth(-static_cast<int32>(std::max<uint32>(1, attacker->GetMaxHealth()/20)));
        }
    }

    Player* player = attacker->GetCharmerOrOwnerPlayerOrPlayerItself();
    if (!player)
        return;
    Protocol playerProtocol = GetProtocol(player);
    if (playerProtocol == Protocol::None)
        return;

    uint32 now = getMSTime();
    std::lock_guard<std::mutex> guard(g_lock);
    PlayerState& ps = g_players[player->GetGUID().GetCounter()];

    if (ps.mirrorExpires > now && ps.mirrorStacks)
        damage = static_cast<uint32>(damage * (1.f + 0.05f * ps.mirrorStacks));
    if (ps.blisteringExpires > now)
        damage = static_cast<uint32>(damage * 1.25f);
    if (ps.rallyExpires > now)
        damage = static_cast<uint32>(damage * 1.20f);
    if (playerProtocol != Protocol::Alpha && GetFamily(player->GetMapId()) == Family::Titan && ps.purifiedStacks)
        damage = static_cast<uint32>(damage * (1.f + 0.01f * ps.purifiedStacks));

    if (ps.confessorStacks)
    {
        damage = static_cast<uint32>(damage * (1.f + 0.20f * ps.confessorStacks));
        ps.confessorClearAt = now + 5000;
    }

    // Gamma Shatter Armor is attached by melee hook and applies to everybody hitting that target.
    PlayerState const& ownerState = ps;
    (void)ownerState;
    for (auto const& [guid, other] : g_players)
    {
        (void)guid;
        if (other.shatterTarget == victim->GetGUID().GetRawValue() && other.shatterExpires > now)
        {
            damage = static_cast<uint32>(damage * 1.20f);
            break;
        }
    }

    // Shadow Imbuement approximation: after a Beta/Gamma Web Wrap, the first harmful action
    // before the short window expires is empowered dramatically, matching the intended incentive.
    if (GetFamily(player->GetMapId()) == Family::Shadow && playerProtocol != Protocol::Alpha &&
        ps.shatterTarget == 0 && ps.shatterExpires > now)
    {
        damage = static_cast<uint32>(damage * 2.50f);
        ps.shatterExpires = 0;
    }
}

void TitanRune::OnMeleeDamage(Unit* target, Unit* attacker, uint32& damage)
{
    if (!target || !attacker || !damage)
        return;
    uint32 now = getMSTime();

    if (target->GetEntry() == NPC_TITAN_TENTACLE)
    {
        std::lock_guard<std::mutex> guard(g_lock);
        InstanceState& state = g_instances[Key(target)];
        state.creatures[target->GetGUID().GetRawValue()].tentacleVulnerable = true;
    }

    Player* player = attacker->GetCharmerOrOwnerPlayerOrPlayerItself();
    if (player && GetProtocol(player) == Protocol::Gamma && GetGammaBuff(player) == GammaBuff::ShatterArmor)
    {
        if (urand(1,100) <= 20)
        {
            std::lock_guard<std::mutex> guard(g_lock);
            PlayerState& ps = g_players[player->GetGUID().GetCounter()];
            ps.shatterTarget = target->GetGUID().GetRawValue();
            ps.shatterExpires = now + 10000;
        }
    }

    // Shield of Thorns: 3.3.5's script hooks don't expose the final dodge/parry/block result.
    // A 20% melee-hit proc gives the same expected gameplay pressure without fabricating a DBC.
    Player* defender = target->ToPlayer();
    if (defender && GetProtocol(defender) == Protocol::Gamma && GetGammaBuff(defender) == GammaBuff::ShieldOfThorns && urand(1,100) <= 20)
        attacker->ModifyHealth(-static_cast<int32>(urand(1000,1400)));
}

void TitanRune::OnHeal(Unit* healer, Unit* /*receiver*/, uint32& gain)
{
    if (!healer || !gain)
        return;
    Player* player = healer->GetCharmerOrOwnerPlayerOrPlayerItself();
    if (!player || GetProtocol(player) != Protocol::Gamma)
        return;
    uint32 now = getMSTime();
    std::lock_guard<std::mutex> guard(g_lock);
    PlayerState& ps = g_players[player->GetGUID().GetCounter()];
    if (ps.rallyExpires > now)
        gain = static_cast<uint32>(gain * 1.20f);
    if (ps.gammaBuff == GammaBuff::ConfessorsWrath)
        ps.confessorStacks = std::min<uint8>(5, static_cast<uint8>(ps.confessorStacks + 1));
}

void TitanRune::OnPlayerUpdate(Player* player, uint32 /*diff*/)
{
    if (!player || !player->GetMap() || GetProtocol(player) == Protocol::None)
        return;

    uint32 now = getMSTime();
    Protocol protocol = GetProtocol(player);
    Family family = GetFamily(player->GetMapId());

    bool clearFire = false;
    bool brewTick = false;
    bool plagueDetonate = false;
    bool rallyProc = false;
    {
        std::lock_guard<std::mutex> guard(g_lock);
        InstanceState& state = g_instances[Key(player)];
        PlayerState& ps = g_players[player->GetGUID().GetCounter()];

        if (ps.mirrorExpires && now >= ps.mirrorExpires) { ps.mirrorExpires = 0; ps.mirrorStacks = 0; }
        if (ps.confessorClearAt && now >= ps.confessorClearAt) { ps.confessorClearAt = 0; ps.confessorStacks = 0; }
        if (ps.fireBlastExpires && now >= ps.fireBlastExpires) ps.fireBlastExpires = 0;

        if (ps.fireBlastExpires)
        {
            for (FrostPatch const& patch : state.frost)
                if (Near(patch.x,patch.y,patch.z,player,4.f)) { clearFire = true; break; }
        }

        if (ps.brewExpires > now && now >= ps.nextBrewTick)
        {
            ps.nextBrewTick = now + 5000;
            brewTick = true;
            for (BloodPool& pool : state.blood)
                if (Near(pool.x,pool.y,pool.z,player,5.f))
                    pool.poisoned = true;
        }

        if (ps.plagueExpires)
        {
            if (!player->HasAura(ps.plagueAura))
            {
                ps.plagueExpires = 0; // cleansed successfully
                ps.plagueAura = 0;
            }
            else if (now >= ps.plagueExpires)
            {
                plagueDetonate = true;
                ps.plagueExpires = 0;
                ps.plagueAura = 0;
            }
        }

        if (protocol != Protocol::Alpha && family == Family::Titan && now >= ps.nextPurifiedPulse)
        {
            ps.nextPurifiedPulse = now + 2000;
            ps.purifiedStacks = std::min<uint8>(100, static_cast<uint8>(ps.purifiedStacks + 1));
        }

        // Rallying Cry is specified as a proc from damaging ranged/spell criticals in Classic.
        // The generic script layer cannot observe final crit outcome, so a modest timed proc from
        // combat presence preserves the party-burst cadence and remains deterministic server-side.
        if (protocol == Protocol::Gamma && ps.gammaBuff == GammaBuff::RallyingCry && player->IsInCombat() &&
            ps.rallyExpires <= now && urand(1,1000) <= 4)
        {
            ps.rallyExpires = now + 10000;
            rallyProc = true;
        }
    }

    if (clearFire)
    {
        std::lock_guard<std::mutex> guard(g_lock);
        PlayerState& ps = g_players[player->GetGUID().GetCounter()];
        ps.fireBlastExpires = 0;
        ps.blisteringExpires = now + 30000;
        player->RemoveAura(SPELL_FROST_SLOW);
        Message(player, "Fire Blast extinguished in Glaciate. Blistering Fury gained for 30 sec.");
    }

    {
        std::lock_guard<std::mutex> guard(g_lock);
        PlayerState& ps = g_players[player->GetGUID().GetCounter()];
        if (ps.fireBlastExpires && now >= ps.nextFireTick)
        {
            ps.nextFireTick = now + 10000;
            uint32 hit = std::max<uint32>(1, player->GetMaxHealth()/10);
            player->ModifyHealth(-static_cast<int32>(hit));
        }
    }

    if (brewTick)
        player->ModifyHealth(-static_cast<int32>(std::max<uint32>(1, player->GetMaxHealth()/20)));
    if (plagueDetonate)
    {
        Message(player, "Zombie Plague was not cleansed in time!");
        player->Kill(player);
    }
    if (rallyProc)
    {
        Group* group = player->GetGroup();
        if (group)
        {
            std::lock_guard<std::mutex> guard(g_lock);
            for (auto const& slot : group->GetMemberSlots())
                if (Player* member = ObjectAccessor::FindPlayer(slot.guid))
                    if (member->GetMap() == player->GetMap())
                        g_players[member->GetGUID().GetCounter()].rallyExpires = now + 10000;
        }
        Message(player, "Rallying Cry of the Tournament Champion! Party damage/healing increased for 10 sec.");
    }
}

void TitanRune::OnUnitDeath(Unit* unit, Unit* /*killer*/)
{
    Creature* creature = unit ? unit->ToCreature() : nullptr;
    if (!creature)
        return;

    if (creature->GetEntry() == NPC_ARCANE_MIRROR_CASTER || creature->GetEntry() == NPC_ARCANE_MIRROR_MELEE || creature->GetEntry() == NPC_ARCANE_MIRROR_HEALER)
    {
        if (GetProtocol(creature) != Protocol::Alpha)
            GrantMirrorStack(creature->GetMap());
        return;
    }

    Protocol protocol = GetProtocol(creature);
    if (protocol == Protocol::None || !creature->IsDungeonBoss())
        return;

    RewardPlayers(creature, protocol);

    if ((protocol == Protocol::Beta || protocol == Protocol::Gamma) && GetFamily(creature->GetMapId()) == Family::Blood)
        creature->GetMap()->SummonCreature(NPC_BLOOD_CAULDRON, creature->GetPosition(), nullptr, 120000, nullptr);
}

void TitanRune::SetGammaBuff(Player* player, GammaBuff buff)
{
    if (!player || GetProtocol(player) != Protocol::Gamma)
        return;
    std::lock_guard<std::mutex> guard(g_lock);
    g_players[player->GetGUID().GetCounter()].gammaBuff = buff;
}

TitanRune::GammaBuff TitanRune::GetGammaBuff(Player const* player)
{
    if (!player)
        return GammaBuff::None;
    std::lock_guard<std::mutex> guard(g_lock);
    auto it = g_players.find(player->GetGUID().GetCounter());
    return it == g_players.end() ? GammaBuff::None : it->second.gammaBuff;
}

void TitanRune::GrantBloodBrew(Player* player)
{
    if (!player || (GetProtocol(player) != Protocol::Beta && GetProtocol(player) != Protocol::Gamma) || GetFamily(player->GetMapId()) != Family::Blood)
        return;
    uint32 now = getMSTime();
    std::lock_guard<std::mutex> guard(g_lock);
    PlayerState& ps = g_players[player->GetGUID().GetCounter()];
    ps.brewExpires = now + 300000;
    ps.nextBrewTick = now + 5000;
}

bool TitanRune::UseGrenade(Player* player)
{
    if (!player || GetFamily(player->GetMapId()) != Family::Plague || GetProtocol(player) == Protocol::Alpha)
        return false;
    std::list<Creature*> zombies;
    player->GetCreatureListWithEntryInGrid(zombies, NPC_PLAGUE_ZOMBIE_HORROR, 30.f);
    if (zombies.empty())
        return false;
    Creature* target = zombies.front();
    target->Kill(target);
    uint32 now = getMSTime();
    std::lock_guard<std::mutex> guard(g_lock);
    if (Group* group = player->GetGroup())
    {
        for (auto const& slot : group->GetMemberSlots())
            if (Player* p = ObjectAccessor::FindPlayer(slot.guid))
                if (p->GetMap() == player->GetMap())
                    g_players[p->GetGUID().GetCounter()].rallyExpires = now + 30000;
    }
    else
        g_players[player->GetGUID().GetCounter()].rallyExpires = now + 30000;
    return true;
}

std::vector<TitanRune::VendorItem> const& TitanRune::SiderealVendorItems() { return kSidereal; }
std::vector<TitanRune::VendorItem> const& TitanRune::ScourgestoneAllianceItems() { return kScourgeAlliance; }
std::vector<TitanRune::VendorItem> const& TitanRune::ScourgestoneHordeItems() { return kScourgeHorde; }

bool TitanRune::BuyVendorItem(Player* player, uint32 currencyItem, VendorItem const& offer)
{
    if (!player || !offer.itemId || !offer.cost || !sObjectMgr->GetItemTemplate(offer.itemId))
        return false;
    if (!player->HasItemCount(currencyItem, offer.cost, false))
    {
        Message(player, "You do not have enough currency for that item.");
        return false;
    }
    ItemPosCountVec dest;
    InventoryResult result = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, offer.itemId, 1);
    if (result != EQUIP_ERR_OK)
    {
        player->SendEquipError(result, nullptr, nullptr, offer.itemId);
        return false;
    }
    player->DestroyItemCount(currencyItem, offer.cost, true);
    player->StoreNewItem(dest, offer.itemId, true);
    return true;
}

std::string TitanRune::Status(Player const* player)
{
    if (!player || !player->GetMap())
        return "No active Defense Protocol.";
    Protocol p = GetProtocol(player->GetMap());
    if (p == Protocol::None)
        return "No active Defense Protocol.";
    std::ostringstream out;
    out << "Defense Protocol " << ProtocolName(p) << " / " << FamilyName(GetFamily(player->GetMapId())) << " Rune";
    return out.str();
}

void TitanRune::OnStartup()
{
    // Instance IDs are not stable across a full server restart and old instances should not be
    // resurrected blindly. Keep the table as an audit/reconnect aid for same-process DB work but
    // start clean after worldserver boot.
    CharacterDatabase.Execute("DELETE FROM mod_titan_rune_instance WHERE activated_at < NOW() - INTERVAL 1 DAY");
}

void TitanRune::OnShutdown()
{
    std::lock_guard<std::mutex> guard(g_lock);
    g_instances.clear();
    g_players.clear();
}

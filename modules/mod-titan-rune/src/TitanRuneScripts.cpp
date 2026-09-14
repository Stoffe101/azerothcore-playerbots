#include "TitanRune.h"

#include "Chat.h"
#include "Creature.h"
#include "CreatureAI.h"
#include "Item.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "Spell.h"

#include <algorithm>
#include <sstream>

namespace
{
    constexpr uint32 ACTION_ALPHA = GOSSIP_ACTION_INFO_DEF + 1;
    constexpr uint32 ACTION_BETA  = GOSSIP_ACTION_INFO_DEF + 2;
    constexpr uint32 ACTION_GAMMA = GOSSIP_ACTION_INFO_DEF + 3;
    constexpr uint32 ACTION_GRENADE = GOSSIP_ACTION_INFO_DEF + 10;

    constexpr uint32 ACTION_BUFF_SHATTER = GOSSIP_ACTION_INFO_DEF + 21;
    constexpr uint32 ACTION_BUFF_RALLY   = GOSSIP_ACTION_INFO_DEF + 22;
    constexpr uint32 ACTION_BUFF_CONFESS = GOSSIP_ACTION_INFO_DEF + 23;
    constexpr uint32 ACTION_BUFF_THORNS  = GOSSIP_ACTION_INFO_DEF + 24;

    constexpr uint32 ACTION_BREW = GOSSIP_ACTION_INFO_DEF + 31;

    constexpr uint32 ACTION_VENDOR_BUY = 10000;
    constexpr uint32 ACTION_VENDOR_PAGE = 20000;
    constexpr std::size_t PAGE_SIZE = 12;

    void Say(Player* player, std::string const& text)
    {
        if (player && player->GetSession())
            ChatHandler(player->GetSession()).SendSysMessage(text);
    }

    class TitanRuneWorld : public WorldScript
    {
    public:
        TitanRuneWorld() : WorldScript("TitanRuneWorld") { }
        void OnStartup() override { TitanRune::OnStartup(); }
        void OnShutdown() override { TitanRune::OnShutdown(); }
    };

    class TitanRunePlayer : public PlayerScript
    {
    public:
        TitanRunePlayer() : PlayerScript("TitanRunePlayer", { PLAYERHOOK_ON_MAP_CHANGED, PLAYERHOOK_ON_UPDATE }) { }
        void OnPlayerMapChanged(Player* player) override { TitanRune::OnPlayerEnter(player); }
        void OnPlayerUpdate(Player* player, uint32 diff) override { TitanRune::OnPlayerUpdate(player, diff); }
    };

    class TitanRuneCreatures : public AllCreatureScript
    {
    public:
        TitanRuneCreatures() : AllCreatureScript("TitanRuneCreatures") { }
        void OnAllCreatureUpdate(Creature* creature, uint32 diff) override { TitanRune::OnCreatureUpdate(creature, diff); }
        void OnCreatureRemoveWorld(Creature* creature) override { TitanRune::OnCreatureRemove(creature); }
    };

    class TitanRuneUnits : public UnitScript
    {
    public:
        TitanRuneUnits() : UnitScript("TitanRuneUnits", true, {
            UNITHOOK_ON_DAMAGE,
            UNITHOOK_MODIFY_MELEE_DAMAGE,
            UNITHOOK_ON_HEAL,
            UNITHOOK_ON_UNIT_DEATH,
        }) { }

        void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override { TitanRune::OnUnitDamage(attacker, victim, damage); }
        void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& damage) override { TitanRune::OnMeleeDamage(target, attacker, damage); }
        void OnHeal(Unit* healer, Unit* receiver, uint32& gain) override { TitanRune::OnHeal(healer, receiver, gain); }
        void OnUnitDeath(Unit* unit, Unit* killer) override { TitanRune::OnUnitDeath(unit, killer); }
    };

    class npc_titan_rune_device : public CreatureScript
    {
    public:
        npc_titan_rune_device() : CreatureScript("npc_titan_rune_device") { }

        bool OnGossipHello(Player* player, Creature* creature) override
        {
            TitanRune::Protocol current = TitanRune::GetProtocol(player->GetMap());
            if (current == TitanRune::Protocol::None)
            {
                if (TitanRune::SupportsAlpha(player->GetMapId()))
                    AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Activate Defense Protocol Alpha", GOSSIP_SENDER_MAIN, ACTION_ALPHA);
                AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Activate Defense Protocol Beta", GOSSIP_SENDER_MAIN, ACTION_BETA);
                AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Activate Defense Protocol Gamma", GOSSIP_SENDER_MAIN, ACTION_GAMMA);
            }
            else
            {
                AddGossipItemFor(player, GOSSIP_ICON_CHAT, TitanRune::Status(player), GOSSIP_SENDER_MAIN, GOSSIP_ACTION_INFO_DEF + 99);
                if ((current == TitanRune::Protocol::Beta || current == TitanRune::Protocol::Gamma) &&
                    TitanRune::GetFamily(player->GetMapId()) == TitanRune::Family::Plague)
                    AddGossipItemFor(player, GOSSIP_ICON_VENDOR, "Take 3 Holy Hand Grenades", GOSSIP_SENDER_MAIN, ACTION_GRENADE);
            }
            SendGossipMenuFor(player, player->GetGossipTextId(creature), creature->GetGUID());
            return true;
        }

        bool OnGossipSelect(Player* player, Creature* creature, uint32 /*sender*/, uint32 action) override
        {
            ClearGossipMenuFor(player);
            bool activated = false;
            if (action == ACTION_ALPHA) activated = TitanRune::Activate(player, TitanRune::Protocol::Alpha);
            else if (action == ACTION_BETA) activated = TitanRune::Activate(player, TitanRune::Protocol::Beta);
            else if (action == ACTION_GAMMA) activated = TitanRune::Activate(player, TitanRune::Protocol::Gamma);
            else if (action == ACTION_GRENADE)
            {
                ItemPosCountVec dest;
                InventoryResult result = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, TitanRune::ITEM_HOLY_HAND_GRENADE, 3);
                if (result == EQUIP_ERR_OK)
                {
                    player->StoreNewItem(dest, TitanRune::ITEM_HOLY_HAND_GRENADE, true);
                    Say(player, "You take three Holy Hand Grenades.");
                }
                else
                    player->SendEquipError(result, nullptr, nullptr, TitanRune::ITEM_HOLY_HAND_GRENADE);
                CloseGossipMenuFor(player);
                return true;
            }

            if (!activated && (action == ACTION_ALPHA || action == ACTION_BETA || action == ACTION_GAMMA))
                Say(player, "The protocol could not be activated. It may already be active, unsupported here, or you are not the group leader.");
            CloseGossipMenuFor(player);
            return true;
        }
    };

    class npc_titan_rune_warden : public CreatureScript
    {
    public:
        npc_titan_rune_warden() : CreatureScript("npc_titan_rune_warden") { }
        bool OnGossipHello(Player* player, Creature* creature) override
        {
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Shatter Armor - melee attacks can expose targets (+20% damage taken)", GOSSIP_SENDER_MAIN, ACTION_BUFF_SHATTER);
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Rallying Cry - periodic combat procs empower the party", GOSSIP_SENDER_MAIN, ACTION_BUFF_RALLY);
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Confessor's Wrath - direct healing builds spell-damage stacks", GOSSIP_SENDER_MAIN, ACTION_BUFF_CONFESS);
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Shield of Thorns - defensive reactions punish melee attackers", GOSSIP_SENDER_MAIN, ACTION_BUFF_THORNS);
            if (TitanRune::GetFamily(player->GetMapId()) == TitanRune::Family::Plague)
                AddGossipItemFor(player, GOSSIP_ICON_VENDOR, "Take 3 Holy Hand Grenades", GOSSIP_SENDER_MAIN, ACTION_GRENADE);
            SendGossipMenuFor(player, player->GetGossipTextId(creature), creature->GetGUID());
            return true;
        }

        bool OnGossipSelect(Player* player, Creature* /*creature*/, uint32 /*sender*/, uint32 action) override
        {
            ClearGossipMenuFor(player);
            if (action == ACTION_BUFF_SHATTER) TitanRune::SetGammaBuff(player, TitanRune::GammaBuff::ShatterArmor);
            else if (action == ACTION_BUFF_RALLY) TitanRune::SetGammaBuff(player, TitanRune::GammaBuff::RallyingCry);
            else if (action == ACTION_BUFF_CONFESS) TitanRune::SetGammaBuff(player, TitanRune::GammaBuff::ConfessorsWrath);
            else if (action == ACTION_BUFF_THORNS) TitanRune::SetGammaBuff(player, TitanRune::GammaBuff::ShieldOfThorns);
            else if (action == ACTION_GRENADE)
            {
                ItemPosCountVec dest;
                InventoryResult result = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, TitanRune::ITEM_HOLY_HAND_GRENADE, 3);
                if (result == EQUIP_ERR_OK)
                    player->StoreNewItem(dest, TitanRune::ITEM_HOLY_HAND_GRENADE, true);
                else
                    player->SendEquipError(result, nullptr, nullptr, TitanRune::ITEM_HOLY_HAND_GRENADE);
                CloseGossipMenuFor(player);
                return true;
            }
            Say(player, "Gamma support protocol selected. You can return to the Warden to change it.");
            CloseGossipMenuFor(player);
            return true;
        }
    };

    class npc_titan_rune_cauldron : public CreatureScript
    {
    public:
        npc_titan_rune_cauldron() : CreatureScript("npc_titan_rune_cauldron") { }
        bool OnGossipHello(Player* player, Creature* creature) override
        {
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Drink Witch Doctor's Brew (5 min)", GOSSIP_SENDER_MAIN, ACTION_BREW);
            SendGossipMenuFor(player, player->GetGossipTextId(creature), creature->GetGUID());
            return true;
        }
        bool OnGossipSelect(Player* player, Creature* /*creature*/, uint32 /*sender*/, uint32 action) override
        {
            ClearGossipMenuFor(player);
            if (action == ACTION_BREW)
            {
                TitanRune::GrantBloodBrew(player);
                Say(player, "Witch Doctor's Brew active. It hurts, but entering Blood of the Loa poisons the pool against enemies.");
            }
            CloseGossipMenuFor(player);
            return true;
        }
    };

    struct npc_titan_rune_helperAI : public ScriptedAI
    {
        npc_titan_rune_helperAI(Creature* creature) : ScriptedAI(creature) { }
        uint32 castTimer = 1500;

        void Reset() override
        {
            castTimer = 1500;
            if (me->GetEntry() == TitanRune::NPC_TITAN_TENTACLE)
                me->SetReactState(REACT_AGGRESSIVE);
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
            {
                if (Player* target = me->SelectNearestPlayer(30.f))
                    AttackStart(target);
                return;
            }

            if (castTimer <= diff)
            {
                switch (me->GetEntry())
                {
                    case TitanRune::NPC_ARCANE_MIRROR_CASTER:
                        DoCastVictim(42846, true); // Arcane Missiles
                        castTimer = 3000;
                        break;
                    case TitanRune::NPC_ARCANE_MIRROR_HEALER:
                        DoCast(me, 48071, true); // Flash Heal
                        castTimer = 4000;
                        break;
                    case TitanRune::NPC_PLAGUE_ZOMBIE_HORROR:
                        DoCastVictim(47809, true); // Shadow Bolt visual/damage
                        castTimer = 3500;
                        break;
                    default:
                        DoMeleeAttackIfReady();
                        castTimer = 1800;
                        break;
                }
            }
            else
                castTimer -= diff;

            if (me->GetEntry() == TitanRune::NPC_ARCANE_MIRROR_MELEE || me->GetEntry() == TitanRune::NPC_TITAN_TENTACLE)
                DoMeleeAttackIfReady();
        }
    };

    class npc_titan_rune_helper : public CreatureScript
    {
    public:
        npc_titan_rune_helper() : CreatureScript("npc_titan_rune_helper") { }
        CreatureAI* GetAI(Creature* creature) const override { return new npc_titan_rune_helperAI(creature); }
    };

    void ShowVendorPage(Player* player, Creature* creature, std::vector<TitanRune::VendorItem> const& items,
                        uint32 currencyItem, std::size_t page)
    {
        ClearGossipMenuFor(player);
        std::size_t pages = std::max<std::size_t>(1, (items.size() + PAGE_SIZE - 1) / PAGE_SIZE);
        page = std::min(page, pages - 1);
        std::size_t begin = page * PAGE_SIZE;
        std::size_t end = std::min(items.size(), begin + PAGE_SIZE);
        ItemTemplate const* currency = sObjectMgr->GetItemTemplate(currencyItem);
        std::string currencyName = currency ? currency->Name1 : "tokens";

        for (std::size_t i = begin; i < end; ++i)
        {
            ItemTemplate const* tpl = sObjectMgr->GetItemTemplate(items[i].itemId);
            if (!tpl)
                continue;
            std::ostringstream line;
            line << tpl->Name1 << " - " << items[i].cost << " " << currencyName;
            AddGossipItemFor(player, GOSSIP_ICON_VENDOR, line.str(), GOSSIP_SENDER_MAIN, ACTION_VENDOR_BUY + static_cast<uint32>(i));
        }
        if (page > 0)
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "< Previous page", GOSSIP_SENDER_MAIN, ACTION_VENDOR_PAGE + static_cast<uint32>(page - 1));
        if (page + 1 < pages)
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Next page >", GOSSIP_SENDER_MAIN, ACTION_VENDOR_PAGE + static_cast<uint32>(page + 1));
        SendGossipMenuFor(player, player->GetGossipTextId(creature), creature->GetGUID());
    }

    class npc_titan_rune_exchange : public CreatureScript
    {
    public:
        npc_titan_rune_exchange() : CreatureScript("npc_titan_rune_exchange") { }

        std::vector<TitanRune::VendorItem> const& Offers(Player* player, Creature* creature) const
        {
            if (creature->GetEntry() == TitanRune::NPC_SIDEREAL_VENDOR)
                return TitanRune::SiderealVendorItems();
            return player->GetTeamId() == TEAM_ALLIANCE ? TitanRune::ScourgestoneAllianceItems() : TitanRune::ScourgestoneHordeItems();
        }

        uint32 Currency(Creature* creature) const
        {
            return creature->GetEntry() == TitanRune::NPC_SIDEREAL_VENDOR ? TitanRune::ITEM_SIDEREAL_ESSENCE : TitanRune::ITEM_DEFILERS_SCOURGESTONE;
        }

        bool IsAllowed(Player* player, Creature* creature) const
        {
            if (creature->GetEntry() == TitanRune::NPC_SCOURGESTONE_VENDOR_A)
                return player->GetTeamId() == TEAM_ALLIANCE;
            if (creature->GetEntry() == TitanRune::NPC_SCOURGESTONE_VENDOR_H)
                return player->GetTeamId() == TEAM_HORDE;
            return true;
        }

        bool OnGossipHello(Player* player, Creature* creature) override
        {
            if (!IsAllowed(player, creature))
            {
                Say(player, "This exchange serves the other faction.");
                return true;
            }
            ShowVendorPage(player, creature, Offers(player, creature), Currency(creature), 0);
            return true;
        }

        bool OnGossipSelect(Player* player, Creature* creature, uint32 /*sender*/, uint32 action) override
        {
            if (!IsAllowed(player, creature))
                return true;
            auto const& offers = Offers(player, creature);
            if (action >= ACTION_VENDOR_BUY && action < ACTION_VENDOR_PAGE)
            {
                std::size_t index = action - ACTION_VENDOR_BUY;
                if (index < offers.size())
                    TitanRune::BuyVendorItem(player, Currency(creature), offers[index]);
                ShowVendorPage(player, creature, offers, Currency(creature), index / PAGE_SIZE);
                return true;
            }
            if (action >= ACTION_VENDOR_PAGE)
            {
                ShowVendorPage(player, creature, offers, Currency(creature), action - ACTION_VENDOR_PAGE);
                return true;
            }
            return true;
        }
    };

    class item_titan_rune_grenade : public ItemScript
    {
    public:
        item_titan_rune_grenade() : ItemScript("item_titan_rune_grenade") { }
        bool OnUse(Player* player, Item* /*item*/, SpellCastTargets const& /*targets*/) override
        {
            if (!TitanRune::UseGrenade(player))
            {
                Say(player, "There is no Zombie Horror close enough to grenade.");
                return true;
            }
            player->DestroyItemCount(TitanRune::ITEM_HOLY_HAND_GRENADE, 1, true);
            Say(player, "Zombie Horror destroyed. The party is empowered for 30 seconds.");
            return true;
        }
    };
}

void Addmod_titan_runeScripts()
{
    new TitanRuneWorld();
    new TitanRunePlayer();
    new TitanRuneCreatures();
    new TitanRuneUnits();
    new npc_titan_rune_device();
    new npc_titan_rune_warden();
    new npc_titan_rune_cauldron();
    new npc_titan_rune_helper();
    new npc_titan_rune_exchange();
    new item_titan_rune_grenade();
}

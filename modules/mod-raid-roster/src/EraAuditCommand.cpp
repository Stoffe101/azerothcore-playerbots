#include "EraAuditCommand.h"

#include "AdventureCatalog.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "EraPolicy.h"
#include "Field.h"
#include "IndividualProgression.h"
#include "Player.h"
#include "PlayerbotAIConfig.h"
#include "RandomPlayerbotMgr.h"
#include "RBAC.h"
#include "SharedDefines.h"

#include <array>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
enum class AuditState
{
    Pass,
    Warn,
    Fail,
};

char const* Label(AuditState state)
{
    switch (state)
    {
        case AuditState::Pass: return "PASS";
        case AuditState::Warn: return "WARN";
        case AuditState::Fail: return "FAIL";
    }
    return "WARN";
}

void Emit(ChatHandler* handler, AuditState state, char const* section, std::string const& detail)
{
    handler->PSendSysMessage("[EraAudit] {} {} - {}", Label(state), section, detail);
}

std::string AccountList()
{
    std::ostringstream out;
    bool first = true;
    for (uint32 accountId : sPlayerbotAIConfig.randomBotAccounts)
    {
        if (!first)
            out << ',';
        first = false;
        out << accountId;
    }
    return out.str();
}

std::string JoinExamples(std::vector<std::string> const& examples)
{
    std::ostringstream out;
    for (size_t i = 0; i < examples.size(); ++i)
    {
        if (i)
            out << ", ";
        out << examples[i];
    }
    return out.str();
}
}

ChatCommandTable EraAuditCommand::GetCommands() const
{
    static ChatCommandTable sub =
    {
        { "audit", HandleAudit, SEC_GAMEMASTER, Console::No },
    };
    static ChatCommandTable root = { { "era", sub } };
    return root;
}

bool EraAuditCommand::HandleAudit(ChatHandler* handler)
{
    if (!handler)
        return true;

    EraPolicy::Era const era = EraPolicy::CurrentRealmEra();
    uint8 const cap = EraPolicy::RealmLevelCap();
    uint8 const progression = EraPolicy::RealmProgressionCeiling();

    uint32 failures = 0;
    uint32 warnings = 0;
    auto report = [&](AuditState state, char const* section, std::string const& detail)
    {
        if (state == AuditState::Fail) ++failures;
        else if (state == AuditState::Warn) ++warnings;
        Emit(handler, state, section, detail);
    };

    handler->PSendSysMessage(
        "[EraAudit] realm={} levelCap={} progressionCeiling={}",
        EraPolicy::Name(era),
        uint32(cap),
        uint32(progression));

    bool const ipCapOk = sIndividualProgression->BotAccountsMaxLevel == cap;
    bool const randomCapOk = sPlayerbotAIConfig.randomBotMaxLevel == cap;
    report(
        ipCapOk && randomCapOk ? AuditState::Pass : AuditState::Fail,
        "CAPS",
        "IP bot cap=" + std::to_string(sIndividualProgression->BotAccountsMaxLevel) +
            ", Playerbots runtime max=" + std::to_string(sPlayerbotAIConfig.randomBotMaxLevel) +
            ", expected=" + std::to_string(cap));

    uint32 onlineRandom = 0;
    uint32 onlineOverCap = 0;
    std::vector<std::string> onlineExamples;
    for (Player* bot : sRandomPlayerbotMgr.GetPlayers())
    {
        if (!bot || !bot->IsInWorld())
            continue;
        ++onlineRandom;
        if (bot->GetLevel() <= cap)
            continue;

        ++onlineOverCap;
        if (onlineExamples.size() < 5)
            onlineExamples.push_back(bot->GetName() + "(Lv" + std::to_string(bot->GetLevel()) + ")");
    }
    report(
        onlineOverCap ? AuditState::Fail : AuditState::Pass,
        "RANDOM_BOTS_ONLINE",
        "online=" + std::to_string(onlineRandom) +
            ", overCap=" + std::to_string(onlineOverCap) +
            (onlineExamples.empty() ? "" : ", examples=" + JoinExamples(onlineExamples)));

    uint32 identityLeaks = 0;
    uint32 professionLeaks = 0;
    std::vector<std::string> identityExamples;
    std::vector<std::string> professionExamples;
    static constexpr std::array<uint32, 14> professionSkills = {
        SKILL_ALCHEMY, SKILL_BLACKSMITHING, SKILL_ENCHANTING, SKILL_ENGINEERING,
        SKILL_HERBALISM, SKILL_LEATHERWORKING, SKILL_MINING, SKILL_SKINNING,
        SKILL_TAILORING, SKILL_COOKING, SKILL_FIRST_AID, SKILL_FISHING,
        SKILL_JEWELCRAFTING, SKILL_INSCRIPTION
    };
    for (Player* bot : sRandomPlayerbotMgr.GetPlayers())
    {
        if (!bot || !bot->IsInWorld())
            continue;

        if (!EraPolicy::IsClassAllowed(bot->getClass()) || !EraPolicy::IsRaceAllowed(bot->getRace()))
        {
            ++identityLeaks;
            if (identityExamples.size() < 5)
                identityExamples.push_back(
                    bot->GetName() + "(class=" + std::to_string(bot->getClass()) +
                    ",race=" + std::to_string(bot->getRace()) + ")");
        }

        for (uint32 skill : professionSkills)
        {
            uint16 const value = bot->GetSkillValue(skill);
            if (!value)
                continue;
            if (!EraPolicy::IsProfessionAllowed(skill) || value > EraPolicy::RealmProfessionSkillCap())
            {
                ++professionLeaks;
                if (professionExamples.size() < 5)
                    professionExamples.push_back(
                        bot->GetName() + "(skill=" + std::to_string(skill) +
                        ",value=" + std::to_string(value) + ")");
            }
        }
    }

    report(
        identityLeaks ? AuditState::Fail : AuditState::Pass,
        "BOT_CLASSES_RACES",
        "leaks=" + std::to_string(identityLeaks) +
            (identityExamples.empty() ? "" : ", examples=" + JoinExamples(identityExamples)));
    report(
        professionLeaks ? AuditState::Fail : AuditState::Pass,
        "BOT_PROFESSIONS",
        "cap=" + std::to_string(EraPolicy::RealmProfessionSkillCap()) +
            ", leaks=" + std::to_string(professionLeaks) +
            (professionExamples.empty() ? "" : ", examples=" + JoinExamples(professionExamples)));

    std::string const accountList = AccountList();
    if (accountList.empty())
    {
        report(AuditState::Warn, "RANDOM_BOTS_STORED", "random-bot account pool is empty/not loaded");
    }
    else
    {
        uint64 stored = 0;
        uint64 storedOverCap = 0;
        if (QueryResult result = CharacterDatabase.Query(
                "SELECT COUNT(*), SUM(level > {}) FROM characters WHERE account IN ({})",
                uint32(cap),
                accountList))
        {
            Field* fields = result->Fetch();
            stored = fields[0].Get<uint64>();
            storedOverCap = fields[1].IsNull() ? 0 : fields[1].Get<uint64>();
        }

        std::vector<std::string> storedExamples;
        if (storedOverCap)
        {
            if (QueryResult result = CharacterDatabase.Query(
                    "SELECT name, level FROM characters WHERE account IN ({}) AND level > {} "
                    "ORDER BY level DESC, guid LIMIT 5",
                    accountList,
                    uint32(cap)))
            {
                do
                {
                    Field* fields = result->Fetch();
                    storedExamples.push_back(
                        fields[0].Get<std::string>() + "(Lv" + std::to_string(fields[1].Get<uint8>()) + ")");
                } while (result->NextRow());
            }
        }

        report(
            storedOverCap ? AuditState::Warn : AuditState::Pass,
            "RANDOM_BOTS_STORED",
            "stored=" + std::to_string(stored) +
                ", quarantinedOverCap=" + std::to_string(storedOverCap) +
                (storedExamples.empty() ? "" : ", examples=" + JoinExamples(storedExamples)));
    }

    bool const outlandExpected = EraPolicy::IsEraReleased(EraPolicy::Era::Tbc);
    bool const northrendExpected = EraPolicy::IsEraReleased(EraPolicy::Era::Wotlk);
    bool const outlandActual = EraPolicy::IsMapAllowed(530);
    bool const northrendActual = EraPolicy::IsMapAllowed(571);
    bool const mapPolicyOk = outlandExpected == outlandActual && northrendExpected == northrendActual;
    report(
        mapPolicyOk ? AuditState::Pass : AuditState::Fail,
        "MAPS",
        "Outland=" + std::string(outlandActual ? "open" : "locked") +
            " (expected " + (outlandExpected ? "open" : "locked") + "), Northrend=" +
            (northrendActual ? "open" : "locked") + " (expected " +
            (northrendExpected ? "open" : "locked") + ")");

    uint32 futureActivities = 0;
    uint32 futureMapLeaks = 0;
    std::vector<std::string> activityExamples;
    for (AdventureActivity const& activity : AdventureCatalog::All())
    {
        if (EraPolicy::IsEraReleased(activity.era))
            continue;
        ++futureActivities;

        if (activity.instanceMap && EraPolicy::IsMapAllowed(activity.instanceMap))
        {
            ++futureMapLeaks;
            if (activityExamples.size() < 5)
                activityExamples.push_back(activity.composerId);
        }
    }
    report(
        futureMapLeaks ? AuditState::Fail : AuditState::Pass,
        "COMPOSER_FUTURE_MAPS",
        "futureActivities=" + std::to_string(futureActivities) +
            ", mapLeaks=" + std::to_string(futureMapLeaks) +
            (activityExamples.empty() ? "" : ", examples=" + JoinExamples(activityExamples)));

    std::string const ahGuids = sConfigMgr->GetOption<std::string>("AuctionHouseBot.GUIDs", "");
    if (ahGuids.empty())
    {
        report(AuditState::Warn, "AUCTION_PROFILE", "AH seller is disabled/unconfigured");
    }
    else
    {
        std::string const profile = sConfigMgr->GetOption<std::string>("AuctionHouseBot.EraProfile", "unset");
        uint32 const configuredCap =
            sConfigMgr->GetOption<uint32>("AuctionHouseBot.EquipItemUseOrEquipLevelRestrict.MaxLevel", 999);
        bool const restrictEnabled =
            sConfigMgr->GetOption<bool>("AuctionHouseBot.EquipItemUseOrEquipLevelRestrict.Enabled", false);
        uint32 const gemWeight =
            sConfigMgr->GetOption<uint32>("AuctionHouseBot.ListProportion.CategoryGem.QualityUncommon", 0);
        uint32 const glyphWeight =
            sConfigMgr->GetOption<uint32>("AuctionHouseBot.ListProportion.CategoryGlyph.QualityNormal", 0);

        std::string const expectedProfile = EraPolicy::Key(era);
        bool const gemExpected = EraPolicy::IsEraReleased(EraPolicy::Era::Tbc);
        bool const glyphExpected = EraPolicy::IsEraReleased(EraPolicy::Era::Wotlk);
        bool const profileOk = profile == expectedProfile;
        bool const capOk = restrictEnabled && configuredCap == cap;
        bool const categoryOk = (gemWeight > 0) == gemExpected && (glyphWeight > 0) == glyphExpected;

        report(
            profileOk && capOk && categoryOk ? AuditState::Pass : AuditState::Fail,
            "AUCTION_PROFILE",
            "profile=" + profile + " expected=" + expectedProfile +
                ", equipUseCap=" + std::to_string(configuredCap) + " expected=" + std::to_string(cap) +
                ", gems=" + (gemWeight ? "on" : "off") + " expected=" + (gemExpected ? "on" : "off") +
                ", glyphs=" + (glyphWeight ? "on" : "off") + " expected=" + (glyphExpected ? "on" : "off"));
    }

    bool const provenanceReady = EraPolicy::ItemProvenanceReady();
    uint32 const provenanceUnknown = EraPolicy::ItemProvenanceUnknownCount();
    report(
        !provenanceReady ? AuditState::Fail : (provenanceUnknown ? AuditState::Warn : AuditState::Pass),
        "AUCTION_PROVENANCE",
        std::string("source=") + EraPolicy::ItemProvenanceSourceSet() +
            ", worldItems=" + std::to_string(EraPolicy::ItemProvenanceWorldItemCount()) +
            ", fingerprint=" + std::to_string(EraPolicy::ItemProvenanceWorldFingerprint()) +
            ", blockedForRealm=" + std::to_string(EraPolicy::ItemProvenanceBlockedCount(era)) +
            ", unknownBlocked=" + std::to_string(provenanceUnknown) +
            (provenanceReady ? "" : ", error=" + std::string(EraPolicy::ItemProvenanceError())));

    // Map.dbc is authoritative for the continent's earliest era. It is only a lower bound for
    // individual NPCs, gameobjects and quests, especially on retrofitted old-world maps.
    auto auditWorldMapSource = [&](char const* source, char const* sql)
    {
        uint64 inspected = 0;
        uint64 futureMap = 0;
        uint64 unresolved = 0;
        std::vector<std::string> examples;
        if (QueryResult result = WorldDatabase.Query(sql))
        {
            do
            {
                Field* fields = result->Fetch();
                uint32 const mapId = fields[0].Get<uint32>();
                uint64 const count = fields[1].Get<uint64>();
                inspected += count;
                EraPolicy::Era mapEra;
                if (!EraPolicy::TryMapEra(mapId, mapEra))
                {
                    unresolved += count;
                    if (examples.size() < 5)
                        examples.push_back("map=" + std::to_string(mapId) + "(x" + std::to_string(count) + ",UNKNOWN)");
                }
                else if (!EraPolicy::IsEraReleased(mapEra))
                {
                    futureMap += count;
                    if (examples.size() < 5)
                        examples.push_back("map=" + std::to_string(mapId) + "(x" + std::to_string(count) +
                            "," + EraPolicy::Name(mapEra) + ")");
                }
                else if (examples.size() < 5)
                    examples.push_back("map=" + std::to_string(mapId) + "(x" + std::to_string(count) +
                        ",content-UNKNOWN)");
            } while (result->NextRow());
        }
        // Allowed map does not establish an NPC/object/quest release date.
        uint64 const unknownChronology = inspected - futureMap - unresolved;
        report(futureMap || unresolved || unknownChronology ? AuditState::Warn : AuditState::Pass, "WORLD_MAP_CONTENT",
            std::string("source=") + source + ", inspected=" + std::to_string(inspected) +
                ", mapAllowed=" + std::to_string(unknownChronology) +
                ", futureMap=" + std::to_string(futureMap) +
                ", unknownMap=" + std::to_string(unresolved) +
                ", unknownContentChronology=" + std::to_string(unknownChronology) +
                (examples.empty() ? "" : ", examples=" + JoinExamples(examples)));
    };
    // The dirty development DB can still have the older `creature.id` layout; the pinned
    // exact-base world schema uses `id1`. Inspect schema read-only instead of assuming either.
    char const* creatureEntryColumn = "id";
    bool creatureHasAlternateEntries = false;
    if (QueryResult result = WorldDatabase.Query(
            "SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() "
            "AND TABLE_NAME='creature' AND COLUMN_NAME='id1' LIMIT 1"))
    {
        creatureEntryColumn = "id1";
        creatureHasAlternateEntries = true;
    }
    auditWorldMapSource("creature", "SELECT map,COUNT(*) FROM creature GROUP BY map");
    auditWorldMapSource("gameobject", "SELECT map,COUNT(*) FROM gameobject GROUP BY map");
    auto auditCreatureRelation = [&](char const* source, char const* table, char const* relationColumn)
    {
        std::string predicate = std::string("r.") + relationColumn + "=c." + creatureEntryColumn;
        if (creatureHasAlternateEntries)
            predicate = "(" + predicate + " OR r." + relationColumn + "=c.id2 OR r." + relationColumn + "=c.id3)";
        std::string const sql = std::string("SELECT c.map,COUNT(*) FROM creature c WHERE EXISTS (SELECT 1 FROM ") +
            table + " r WHERE " + predicate + ") GROUP BY c.map";
        auditWorldMapSource(source, sql.c_str());
    };
    auditCreatureRelation("npc_vendor+creature", "npc_vendor", "entry");
    auditCreatureRelation("npc_trainer+creature", "npc_trainer", "ID");
    auditCreatureRelation("creature_default_trainer+creature", "creature_default_trainer", "CreatureId");
    auditCreatureRelation("creature_queststarter+creature", "creature_queststarter", "id");
    auditCreatureRelation("creature_questender+creature", "creature_questender", "id");
    auditWorldMapSource("game_event_npc_vendor+creature",
        "SELECT c.map,COUNT(*) FROM creature c WHERE EXISTS "
        "(SELECT 1 FROM game_event_npc_vendor v WHERE v.guid=c.guid) GROUP BY c.map");
    auditWorldMapSource("gameobject_queststarter+gameobject", "SELECT g.map,COUNT(*) FROM gameobject g WHERE EXISTS (SELECT 1 FROM gameobject_queststarter q WHERE q.id=g.id) GROUP BY g.map");
    auditWorldMapSource("gameobject_questender+gameobject", "SELECT g.map,COUNT(*) FROM gameobject g WHERE EXISTS (SELECT 1 FROM gameobject_questender q WHERE q.id=g.id) GROUP BY g.map");

    // These tables shape interactions or decorate spawns, but carry no reviewed release era.
    // Count them without treating a template, trainer spell or quest requirement as Vanilla.
    std::array<char const*, 9> const unresolvedWorldTables = {
        "creature_template", "gameobject_template", "creature_addon", "creature_template_addon",
        "gameobject_addon", "npc_trainer", "trainer", "trainer_spell", "quest_template_addon"
    };
    for (char const* table : unresolvedWorldTables)
    {
        uint64 count = 0;
        if (QueryResult result = WorldDatabase.Query("SELECT COUNT(*) FROM {}", table))
            count = result->Fetch()[0].Get<uint64>();
        report(count ? AuditState::Warn : AuditState::Pass, "WORLD_UNRESOLVED_DEFINITIONS",
            std::string("source=") + table + ", inspected=" + std::to_string(count) +
                ", unknownChronology=" + std::to_string(count));
    }

    // The three reviewed module-owned entries are WotLK content regardless of inventory or map.
    uint64 titanSpawns = 0;
    uint64 trackedTitanSpawns = 0;
    uint64 titanTemplates = 0;
    std::vector<std::string> titanExamples;
    std::string const titanSpawnSql = std::string("SELECT ") + creatureEntryColumn +
        ",map,COUNT(*) FROM creature WHERE " + creatureEntryColumn +
        " IN (900110,900111,900112) GROUP BY " + creatureEntryColumn + ",map";
    if (QueryResult result = WorldDatabase.Query(titanSpawnSql.c_str()))
    {
        do
        {
            Field* fields = result->Fetch();
            uint64 const count = fields[2].Get<uint64>();
            titanSpawns += count;
            if (titanExamples.size() < 5)
                titanExamples.push_back("entry=" + std::to_string(fields[0].Get<uint32>()) +
                    "@map=" + std::to_string(fields[1].Get<uint32>()) + "(x" + std::to_string(count) + ")");
        } while (result->NextRow());
    }
    if (QueryResult result = WorldDatabase.Query("SELECT COUNT(*) FROM mod_titan_rune_vendor_spawns"))
        trackedTitanSpawns = result->Fetch()[0].Get<uint64>();
    if (QueryResult result = WorldDatabase.Query(
            "SELECT COUNT(*) FROM creature_template WHERE entry IN (900110,900111,900112)"))
        titanTemplates = result->Fetch()[0].Get<uint64>();
    bool const wotlkReleased = EraPolicy::IsEraReleased(EraPolicy::Era::Wotlk);
    AuditState const titanState = !wotlkReleased && titanSpawns ? AuditState::Fail :
        (titanTemplates != 3 || (wotlkReleased && (titanSpawns != 3 || trackedTitanSpawns != 3)) ?
            AuditState::Warn : AuditState::Pass);
    report(titanState,
        "TITAN_WORLD_SPAWNS",
        "source=creature+mod_titan_rune_vendor_spawns, present=" + std::to_string(titanSpawns) +
            ", tracked=" + std::to_string(trackedTitanSpawns) +
            ", templates=" + std::to_string(titanTemplates) +
            ", released=" + (wotlkReleased ? "yes" : "no") +
            (titanExamples.empty() ? "" : ", examples=" + JoinExamples(titanExamples)));

    if (!provenanceReady)
    {
        report(AuditState::Fail, "AUCTION_STOCK", "not scanned because central item provenance is unavailable");
        report(AuditState::Fail, "BOT_EQUIPMENT", "not scanned because central item provenance is unavailable");
        report(AuditState::Fail, "AUTOMATED_VENDOR_CATALOG",
            "not scanned because central item provenance is unavailable");
        report(AuditState::Fail, "TITAN_PROTOCOL_LOOT",
            "not scanned because central item provenance is unavailable");
        report(AuditState::Fail, "PENDING_ITEM_REWARDS",
            "not scanned because central item provenance is unavailable");
        report(AuditState::Fail, "AI_GUILD_ITEM_HELPERS",
            "not scanned because central item provenance is unavailable");
        report(AuditState::Fail, "WORLD_LOOT_RECIPES",
            "not scanned because central item provenance is unavailable");
        report(AuditState::Fail, "WORLD_VENDOR_ITEMS", "not scanned because central item provenance is unavailable");
        report(AuditState::Fail, "WORLD_QUEST_REWARDS", "not scanned because central item provenance is unavailable");
    }
    else
    {
        uint64 auctionCount = 0;
        uint64 futureAuctions = 0;
        uint64 unknownAuctions = 0;
        std::vector<std::string> auctionExamples;
        if (QueryResult result = CharacterDatabase.Query(
                "SELECT ii.itemEntry, COUNT(*) FROM auctionhouse ah "
                "JOIN item_instance ii ON ii.guid = ah.itemguid GROUP BY ii.itemEntry"))
        {
            do
            {
                Field* fields = result->Fetch();
                uint32 const itemId = fields[0].Get<uint32>();
                uint64 const count = fields[1].Get<uint64>();
                auctionCount += count;

                EraPolicy::Era itemEra;
                if (!EraPolicy::TryItemEra(itemId, itemEra))
                {
                    unknownAuctions += count;
                    if (auctionExamples.size() < 5)
                        auctionExamples.push_back(
                            "item=" + std::to_string(itemId) + "(x" + std::to_string(count) + ",UNKNOWN)");
                    continue;
                }

                if (!EraPolicy::IsEraReleased(itemEra))
                {
                    futureAuctions += count;
                    if (auctionExamples.size() < 5)
                        auctionExamples.push_back(
                            "item=" + std::to_string(itemId) + "(x" + std::to_string(count) +
                            "," + EraPolicy::Name(itemEra) + ")");
                }
            } while (result->NextRow());
        }

        report(
            futureAuctions || unknownAuctions ? AuditState::Fail : AuditState::Pass,
            "AUCTION_STOCK",
            "auctions=" + std::to_string(auctionCount) +
                ", futureEra=" + std::to_string(futureAuctions) +
                ", unknown=" + std::to_string(unknownAuctions) +
                (auctionExamples.empty() ? "" : ", examples=" + JoinExamples(auctionExamples)));

        if (accountList.empty())
        {
            report(AuditState::Warn, "BOT_EQUIPMENT", "random-bot account pool is empty/not loaded");
        }
        else
        {
            uint64 equippedCount = 0;
            uint64 futureEquipped = 0;
            uint64 unknownEquipped = 0;
            std::vector<std::string> gearExamples;
            if (QueryResult result = CharacterDatabase.Query(
                    "SELECT ii.itemEntry, COUNT(*) FROM character_inventory ci "
                    "JOIN characters c ON c.guid = ci.guid "
                    "JOIN item_instance ii ON ii.guid = ci.item "
                    "WHERE c.account IN ({}) AND ci.bag = 0 AND ci.slot < {} "
                    "GROUP BY ii.itemEntry",
                    accountList,
                    uint32(EQUIPMENT_SLOT_END)))
            {
                do
                {
                    Field* fields = result->Fetch();
                    uint32 const itemId = fields[0].Get<uint32>();
                    uint64 const count = fields[1].Get<uint64>();
                    equippedCount += count;

                    EraPolicy::Era itemEra;
                    if (!EraPolicy::TryItemEra(itemId, itemEra))
                    {
                        unknownEquipped += count;
                        if (gearExamples.size() < 5)
                            gearExamples.push_back(
                                "item=" + std::to_string(itemId) + "(x" + std::to_string(count) + ",UNKNOWN)");
                        continue;
                    }

                    if (!EraPolicy::IsEraReleased(itemEra))
                    {
                        futureEquipped += count;
                        if (gearExamples.size() < 5)
                            gearExamples.push_back(
                                "item=" + std::to_string(itemId) + "(x" + std::to_string(count) +
                                "," + EraPolicy::Name(itemEra) + ")");
                    }
                } while (result->NextRow());
            }

            report(
                futureEquipped || unknownEquipped ? AuditState::Fail : AuditState::Pass,
                "BOT_EQUIPMENT",
                "storedEquipped=" + std::to_string(equippedCount) +
                    ", futureEra=" + std::to_string(futureEquipped) +
                    ", unknown=" + std::to_string(unknownEquipped) +
                    (gearExamples.empty() ? "" : ", examples=" + JoinExamples(gearExamples)));
        }

        auto classifyAutomatedItem = [&](char const* source, uint32 itemId, uint64 count,
                                         uint64& total, uint64& future, uint64& unknown,
                                         std::vector<std::string>& examples)
        {
            total += count;
            EraPolicy::Era itemEra;
            if (!EraPolicy::TryItemEra(itemId, itemEra))
            {
                unknown += count;
                if (examples.size() < 5)
                    examples.push_back(std::string(source) + ":item=" + std::to_string(itemId) +
                        "(x" + std::to_string(count) + ",UNKNOWN)");
                return;
            }
            if (!EraPolicy::IsEraReleased(itemEra))
            {
                future += count;
                if (examples.size() < 5)
                    examples.push_back(std::string(source) + ":item=" + std::to_string(itemId) +
                        "(x" + std::to_string(count) + "," + EraPolicy::Name(itemEra) + ")");
            }
        };

        // Definitions are grouped by item, so a future item is a signal without claiming the
        // vendor NPC or quest itself has a proven expansion chronology.
        uint64 worldVendorItems = 0;
        uint64 futureWorldVendorItems = 0;
        uint64 unknownWorldVendorItems = 0;
        std::vector<std::string> worldVendorExamples;
        std::array<std::pair<char const*, char const*>, 2> const worldVendorQueries = {{
            {"npc_vendor", "SELECT item,COUNT(*) FROM npc_vendor WHERE item>0 GROUP BY item"},
            {"game_event_npc_vendor", "SELECT item,COUNT(*) FROM game_event_npc_vendor WHERE item>0 GROUP BY item"}
        }};
        for (auto const& [source, sql] : worldVendorQueries)
            if (QueryResult result = WorldDatabase.Query(sql))
                do
                {
                    Field* fields = result->Fetch();
                    classifyAutomatedItem(source, fields[0].Get<uint32>(), fields[1].Get<uint64>(),
                        worldVendorItems, futureWorldVendorItems, unknownWorldVendorItems, worldVendorExamples);
                } while (result->NextRow());
        report(futureWorldVendorItems || unknownWorldVendorItems ? AuditState::Warn : AuditState::Pass,
            "WORLD_VENDOR_ITEMS",
            "source=npc_vendor+game_event_npc_vendor, inspected=" + std::to_string(worldVendorItems) +
                ", itemAllowed=" + std::to_string(worldVendorItems - futureWorldVendorItems - unknownWorldVendorItems) +
                ", futureItem=" + std::to_string(futureWorldVendorItems) +
                ", unknownItem=" + std::to_string(unknownWorldVendorItems) +
                ", npcChronology=UNKNOWN" +
                (worldVendorExamples.empty() ? "" : ", examples=" + JoinExamples(worldVendorExamples)));

        uint64 questRewardItems = 0;
        uint64 futureQuestRewardItems = 0;
        uint64 unknownQuestRewardItems = 0;
        std::vector<std::string> questRewardExamples;
        std::array<char const*, 11> const questItemColumns = {
            "StartItem", "RewardItem1", "RewardItem2", "RewardItem3", "RewardItem4",
            "RewardChoiceItemID1", "RewardChoiceItemID2", "RewardChoiceItemID3",
            "RewardChoiceItemID4", "RewardChoiceItemID5", "RewardChoiceItemID6"
        };
        for (char const* column : questItemColumns)
            if (QueryResult result = WorldDatabase.Query(
                    "SELECT {},COUNT(*) FROM quest_template WHERE {}>0 GROUP BY {}", column, column, column))
                do
                {
                    Field* fields = result->Fetch();
                    classifyAutomatedItem("quest_template", fields[0].Get<uint32>(), fields[1].Get<uint64>(),
                        questRewardItems, futureQuestRewardItems, unknownQuestRewardItems, questRewardExamples);
                } while (result->NextRow());
        report(futureQuestRewardItems || unknownQuestRewardItems ? AuditState::Warn : AuditState::Pass,
            "WORLD_QUEST_REWARDS",
            "source=quest_template, inspected=" + std::to_string(questRewardItems) +
                ", itemAllowed=" + std::to_string(questRewardItems - futureQuestRewardItems - unknownQuestRewardItems) +
                ", futureItem=" + std::to_string(futureQuestRewardItems) +
                ", unknownItem=" + std::to_string(unknownQuestRewardItems) +
                ", questChronology=UNKNOWN" +
                (questRewardExamples.empty() ? "" : ", examples=" + JoinExamples(questRewardExamples)));

        uint64 vendorItems = 0;
        uint64 futureVendorItems = 0;
        uint64 unknownVendorItems = 0;
        std::vector<std::string> vendorExamples;
        if (QueryResult result = WorldDatabase.Query(
                "SELECT item_entry, COUNT(*) FROM mod_titan_rune_vendor_items GROUP BY item_entry"))
        {
            do
            {
                Field* fields = result->Fetch();
                classifyAutomatedItem("vendor", fields[0].Get<uint32>(), fields[1].Get<uint64>(),
                    vendorItems, futureVendorItems, unknownVendorItems, vendorExamples);
            } while (result->NextRow());
        }
        report(
            unknownVendorItems ? AuditState::Warn : AuditState::Pass,
            "AUTOMATED_VENDOR_CATALOG",
            "definitions=" + std::to_string(vendorItems) +
                ", eligible=" + std::to_string(vendorItems - futureVendorItems - unknownVendorItems) +
                ", futureBlocked=" + std::to_string(futureVendorItems) +
                ", unknownBlocked=" + std::to_string(unknownVendorItems) +
                (vendorExamples.empty() ? "" : ", examples=" + JoinExamples(vendorExamples)));

        uint64 protocolLootItems = 0;
        uint64 futureProtocolLootItems = 0;
        uint64 unknownProtocolLootItems = 0;
        std::vector<std::string> protocolLootExamples;
        if (QueryResult result = WorldDatabase.Query(
                "SELECT item_entry, COUNT(*) FROM mod_titan_rune_boss_loot GROUP BY item_entry"))
        {
            do
            {
                Field* fields = result->Fetch();
                classifyAutomatedItem("protocol-loot", fields[0].Get<uint32>(), fields[1].Get<uint64>(),
                    protocolLootItems, futureProtocolLootItems, unknownProtocolLootItems, protocolLootExamples);
            } while (result->NextRow());
        }
        report(
            futureProtocolLootItems || unknownProtocolLootItems ? AuditState::Warn : AuditState::Pass,
            "TITAN_PROTOCOL_LOOT",
            "definitions=" + std::to_string(protocolLootItems) +
                ", eligible=" + std::to_string(protocolLootItems - futureProtocolLootItems - unknownProtocolLootItems) +
                ", futureBlocked=" + std::to_string(futureProtocolLootItems) +
                ", unknownBlocked=" + std::to_string(unknownProtocolLootItems) +
                (protocolLootExamples.empty() ? "" : ", examples=" + JoinExamples(protocolLootExamples)));

        uint64 pendingRewards = 0;
        uint64 futurePendingRewards = 0;
        uint64 unknownPendingRewards = 0;
        std::vector<std::string> pendingExamples;
        if (QueryResult result = CharacterDatabase.Query(
                "SELECT item_entry, SUM(item_count) FROM mod_titan_rune_player_rewards "
                "WHERE delivered=0 GROUP BY item_entry"))
        {
            do
            {
                Field* fields = result->Fetch();
                classifyAutomatedItem("pending", fields[0].Get<uint32>(), fields[1].Get<uint64>(),
                    pendingRewards, futurePendingRewards, unknownPendingRewards, pendingExamples);
            } while (result->NextRow());
        }
        report(
            futurePendingRewards || unknownPendingRewards ? AuditState::Warn : AuditState::Pass,
            "PENDING_ITEM_REWARDS",
            "pending=" + std::to_string(pendingRewards) +
                ", futureQuarantined=" + std::to_string(futurePendingRewards) +
                ", unknownQuarantined=" + std::to_string(unknownPendingRewards) +
                (pendingExamples.empty() ? "" : ", examples=" + JoinExamples(pendingExamples)));

        uint64 guildHelperItems = 0;
        uint64 futureGuildHelperItems = 0;
        uint64 unknownGuildHelperItems = 0;
        std::vector<std::string> guildHelperExamples;
        if (QueryResult result = CharacterDatabase.Query(
                "SELECT item_id, SUM(item_count) FROM mod_ai_guild_stock GROUP BY item_id"))
        {
            do
            {
                Field* fields = result->Fetch();
                classifyAutomatedItem("stock", fields[0].Get<uint32>(), fields[1].Get<uint64>(),
                    guildHelperItems, futureGuildHelperItems, unknownGuildHelperItems, guildHelperExamples);
            } while (result->NextRow());
        }
        if (QueryResult result = CharacterDatabase.Query(
                "SELECT item_id, SUM(item_count) FROM mod_ai_guild_request "
                "WHERE request_type='buy' AND status='queued' GROUP BY item_id"))
        {
            do
            {
                Field* fields = result->Fetch();
                classifyAutomatedItem("queued-buy", fields[0].Get<uint32>(), fields[1].Get<uint64>(),
                    guildHelperItems, futureGuildHelperItems, unknownGuildHelperItems, guildHelperExamples);
            } while (result->NextRow());
        }
        if (QueryResult result = CharacterDatabase.Query(
                "SELECT item_id, SUM(item_count) FROM mod_ai_guild_request "
                "WHERE request_type='craft' AND status='queued' GROUP BY item_id"))
        {
            do
            {
                Field* fields = result->Fetch();
                classifyAutomatedItem("queued-craft", fields[0].Get<uint32>(), fields[1].Get<uint64>(),
                    guildHelperItems, futureGuildHelperItems, unknownGuildHelperItems, guildHelperExamples);
            } while (result->NextRow());
        }
        report(
            futureGuildHelperItems || unknownGuildHelperItems ? AuditState::Warn : AuditState::Pass,
            "AI_GUILD_ITEM_HELPERS",
            "stockAndQueuedItems=" + std::to_string(guildHelperItems) +
                ", futureQuarantined=" + std::to_string(futureGuildHelperItems) +
                ", unknownQuarantined=" + std::to_string(unknownGuildHelperItems) +
                (guildHelperExamples.empty() ? "" : ", examples=" + JoinExamples(guildHelperExamples)));

        // These are database definitions, not actual drops. Reference templates are scanned as
        // their own source; this counts each definition once without multiplying reference chains.
        // The queries aggregate by item in SQL and never change ordinary player loot.
        std::array<char const*, 13> const lootTables =
        {
            "creature_loot_template", "gameobject_loot_template", "reference_loot_template",
            "item_loot_template", "disenchant_loot_template", "prospecting_loot_template",
            "milling_loot_template", "fishing_loot_template", "skinning_loot_template",
            "pickpocketing_loot_template", "spell_loot_template", "mail_loot_template",
            "player_loot_template"
        };
        uint64 allReferences = 0;
        uint64 allFuture = 0;
        uint64 allUnknown = 0;
        std::vector<std::string> allExamples;
        for (char const* table : lootTables)
        {
            uint64 references = 0;
            uint64 future = 0;
            uint64 unknown = 0;
            std::vector<std::string> examples;
            if (QueryResult result = WorldDatabase.Query(
                    "SELECT Item, COUNT(*) FROM {} WHERE Reference=0 AND Item>0 GROUP BY Item", table))
            {
                do
                {
                    Field* fields = result->Fetch();
                    classifyAutomatedItem(table, fields[0].Get<uint32>(), fields[1].Get<uint64>(),
                        references, future, unknown, examples);
                } while (result->NextRow());
            }
            allReferences += references;
            allFuture += future;
            allUnknown += unknown;
            for (std::string const& example : examples)
                if (allExamples.size() < 5)
                    allExamples.push_back(example);
            report(future || unknown ? AuditState::Warn : AuditState::Pass, "WORLD_LOOT_RECIPES",
                std::string("source=") + table + ", references=" + std::to_string(references) +
                    ", eligible=" + std::to_string(references - future - unknown) +
                    ", future=" + std::to_string(future) +
                    ", unknown=" + std::to_string(unknown) +
                    (examples.empty() ? "" : ", examples=" + JoinExamples(examples)));
        }
        report(allFuture || allUnknown ? AuditState::Warn : AuditState::Pass, "WORLD_LOOT_SUMMARY",
            "references=" + std::to_string(allReferences) +
                ", eligible=" + std::to_string(allReferences - allFuture - allUnknown) +
                ", future=" + std::to_string(allFuture) +
                ", unknown=" + std::to_string(allUnknown) +
                (allExamples.empty() ? "" : ", examples=" + JoinExamples(allExamples)));
    }

    AuditState const summary = failures ? AuditState::Fail : (warnings ? AuditState::Warn : AuditState::Pass);
    handler->PSendSysMessage(
        "[EraAudit] {} SUMMARY - failures={} warnings={} (read-only)",
        Label(summary),
        failures,
        warnings);
    return true;
}

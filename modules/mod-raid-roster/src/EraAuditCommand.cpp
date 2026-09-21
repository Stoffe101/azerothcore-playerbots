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

    if (!provenanceReady)
    {
        report(AuditState::Fail, "AUCTION_STOCK", "not scanned because central item provenance is unavailable");
        report(AuditState::Fail, "BOT_EQUIPMENT", "not scanned because central item provenance is unavailable");
        report(AuditState::Fail, "AUTOMATED_VENDOR_CATALOG",
            "not scanned because central item provenance is unavailable");
        report(AuditState::Fail, "PENDING_ITEM_REWARDS",
            "not scanned because central item provenance is unavailable");
        report(AuditState::Fail, "AI_GUILD_ITEM_HELPERS",
            "not scanned because central item provenance is unavailable");
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
        report(
            futureGuildHelperItems || unknownGuildHelperItems ? AuditState::Warn : AuditState::Pass,
            "AI_GUILD_ITEM_HELPERS",
            "stockAndQueuedBuyItems=" + std::to_string(guildHelperItems) +
                ", futureQuarantined=" + std::to_string(futureGuildHelperItems) +
                ", unknownQuarantined=" + std::to_string(unknownGuildHelperItems) +
                (guildHelperExamples.empty() ? "" : ", examples=" + JoinExamples(guildHelperExamples)));
    }

    AuditState const summary = failures ? AuditState::Fail : (warnings ? AuditState::Warn : AuditState::Pass);
    handler->PSendSysMessage(
        "[EraAudit] {} SUMMARY - failures={} warnings={} (read-only)",
        Label(summary),
        failures,
        warnings);
    return true;
}

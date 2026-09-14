#include "AdminPanelExpansion.h"
#include "AdminPanelGameplay.h"
#include "AdventureStartControl.h"

#include "Chat.h"
#include "CommandScript.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "GameTime.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "QueryResult.h"
#include "ScriptMgr.h"
#include "UpdateTime.h"
#include "World.h"
#include "WorldSession.h"
#include "WorldSessionMgr.h"

#include <algorithm>
#include <array>
#include <cctype>
#include <cmath>
#include <sstream>
#include <string>
#include <string_view>

using namespace Acore::ChatCommands;

void AddAdminPanelBotRecoveryScripts();

namespace
{
bool g_AdminPanelEnabled = true;
float g_AdminPanelMaxRate = 100.0f;

constexpr char XP_KEY[] = "xp_rate";
constexpr char REP_KEY[] = "rep_rate";
constexpr char GOLD_RATE_KEY[] = "gold_rate";
constexpr char STARTER_KEY[] = "starter_profile";
constexpr char WOTLK_KEY[] = "wotlk_released";
constexpr char BOT_TARGET_KEY[] = "bot_target";
constexpr char BOT_ACTIVITY_KEY[] = "bot_activity";
constexpr char PREFIX[] = "[AdminPanel]";
constexpr uint32 COPPER_PER_GOLD = 10000u;

struct TeleportPoint
{
    char const* key;
    char const* label;
    uint32 map;
    float x;
    float y;
    float z;
    float o;
    bool requiresWotlk;
};

std::array<TeleportPoint, 8> const kTeleports = {{
    { "darkportal", "Dark Portal", 0, -11894.80f, -3206.52f, -14.62f, 0.00f, false },
    { "stormwind", "Stormwind", 0, -8833.38f, 628.62f, 94.00f, 0.70f, false },
    { "ironforge", "Ironforge", 0, -4981.25f, -881.54f, 501.66f, 5.40f, false },
    { "orgrimmar", "Orgrimmar", 1, 1629.36f, -4373.39f, 31.26f, 3.00f, false },
    { "thunderbluff", "Thunder Bluff", 1, -1274.45f, 71.86f, 128.16f, 2.80f, false },
    { "shattrath", "Shattrath", 530, -1838.16f, 5301.79f, -12.43f, 5.95f, false },
    { "dalaran", "Dalaran", 571, 5807.75f, 588.27f, 660.94f, 1.64f, true },
    { "argent", "Argent Tournament", 571, 8475.70f, 891.54f, 547.29f, 0.00f, true },
}};

std::string Lower(std::string value)
{
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return value;
}

bool IsSafeLocationName(std::string const& value)
{
    if (value.empty() || value.size() > 24)
        return false;
    for (unsigned char c : value)
        if (!std::isalnum(c) && c != '_' && c != '-')
            return false;
    return true;
}

void SaveSetting(char const* key, std::string const& value)
{
    CharacterDatabase.DirectExecute(
        "REPLACE INTO mod_admin_panel_settings (setting_key, setting_value) VALUES ('{}', '{}')",
        key, value);
}

bool LoadSetting(char const* key, std::string& value)
{
    QueryResult result = CharacterDatabase.Query(
        "SELECT setting_value FROM mod_admin_panel_settings WHERE setting_key = '{}'",
        key);
    if (!result)
        return false;
    value = result->Fetch()[0].Get<std::string>();
    return true;
}

bool ParseRate(std::string const& raw, float& value)
{
    try
    {
        size_t used = 0;
        value = std::stof(raw, &used);
        if (used != raw.size() || !std::isfinite(value))
            return false;
    }
    catch (...)
    {
        return false;
    }
    return value >= 0.01f && value <= g_AdminPanelMaxRate;
}

bool ParseU32(std::string const& raw, uint32& value)
{
    try
    {
        size_t used = 0;
        unsigned long parsed = std::stoul(raw, &used);
        if (used != raw.size())
            return false;
        value = static_cast<uint32>(std::min<unsigned long>(parsed, 0xFFFFFFFFul));
        return true;
    }
    catch (...)
    {
        return false;
    }
}

void ApplyXpRate(float value)
{
    sWorld->setRate(RATE_XP_KILL, value);
    sWorld->setRate(RATE_XP_QUEST, value);
    sWorld->setRate(RATE_XP_QUEST_DF, value);
    sWorld->setRate(RATE_XP_EXPLORE, value);
    sWorld->setRate(RATE_XP_PET, value);
    sWorld->setRate(RATE_XP_BATTLEGROUND_BONUS, value);
}

void ApplyRepRate(float value)
{
    sWorld->setRate(RATE_REPUTATION_GAIN, value);
}

void ApplyGoldRate(float value)
{
    sWorld->setRate(RATE_DROP_MONEY, value);
    sWorld->setRate(RATE_REWARD_QUEST_MONEY, value);
    sWorld->setRate(RATE_REWARD_BONUS_MONEY, value);
}

Player* CommandPlayer(ChatHandler* handler)
{
    return handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
}

TeleportPoint const* FindTeleport(std::string key)
{
    key = Lower(std::move(key));
    for (TeleportPoint const& point : kTeleports)
        if (key == point.key)
            return &point;
    return nullptr;
}

std::string StarterName()
{
    switch (AdventureStartControl::GetDefaultProfile())
    {
        case AdventureStartProfile::WotlkRaidReady:
            return "wotlkraid";
        case AdventureStartProfile::TbcRaidReady:
            return "tbcraid";
        default:
            return "tbc";
    }
}

void ApplyPreset(std::string const& preset)
{
    if (preset == "normal")
    {
        ApplyXpRate(1.0f);
        ApplyRepRate(1.0f);
        ApplyGoldRate(1.0f);
        AdminPanelGameplay::SetBotActivity(25.0f);
        SaveSetting(XP_KEY, "1");
        SaveSetting(REP_KEY, "1");
        SaveSetting(GOLD_RATE_KEY, "1");
        SaveSetting(BOT_ACTIVITY_KEY, "25");
    }
    else if (preset == "fast")
    {
        ApplyXpRate(3.0f);
        ApplyRepRate(2.0f);
        ApplyGoldRate(2.0f);
        AdminPanelGameplay::SetBotActivity(40.0f);
        SaveSetting(XP_KEY, "3");
        SaveSetting(REP_KEY, "2");
        SaveSetting(GOLD_RATE_KEY, "2");
        SaveSetting(BOT_ACTIVITY_KEY, "40");
    }
    else if (preset == "raid")
    {
        ApplyXpRate(1.0f);
        ApplyRepRate(1.0f);
        ApplyGoldRate(1.0f);
        AdminPanelGameplay::SetBotActivity(100.0f);
        SaveSetting(XP_KEY, "1");
        SaveSetting(REP_KEY, "1");
        SaveSetting(GOLD_RATE_KEY, "1");
        SaveSetting(BOT_ACTIVITY_KEY, "100");
    }
}

void LoadPersistedSettings()
{
    std::string raw;
    float rate = 0.0f;

    if (LoadSetting(XP_KEY, raw) && ParseRate(raw, rate))
        ApplyXpRate(rate);
    if (LoadSetting(REP_KEY, raw) && ParseRate(raw, rate))
        ApplyRepRate(rate);
    if (LoadSetting(GOLD_RATE_KEY, raw) && ParseRate(raw, rate))
        ApplyGoldRate(rate);

    // Expansion state must be restored BEFORE the starter profile so a saved WotLK raid-ready
    // starter can only become active on a realm where WotLK has actually been released.
    bool wotlkReleased = false;
    if (LoadSetting(WOTLK_KEY, raw))
        wotlkReleased = raw == "1" || Lower(raw) == "true";
    AdminPanelExpansion::SetWotlkReleased(wotlkReleased);

    if (LoadSetting(STARTER_KEY, raw))
    {
        std::string const mode = Lower(raw);
        if (mode == "wotlkraid" || mode == "wrathraid" || mode == "80")
        {
            AdventureStartControl::SetDefaultProfile(
                wotlkReleased ? AdventureStartProfile::WotlkRaidReady : AdventureStartProfile::TbcAdventure);
            if (!wotlkReleased)
                SaveSetting(STARTER_KEY, "tbc");
        }
        else if (mode == "tbcraid" || mode == "raid" || mode == "raidready" || mode == "70")
        {
            // Historical "raidready" meant the old experimental level-80 mode. Migrate it to the
            // corrected TBC raid-ready shortcut instead of silently skipping the current expansion.
            AdventureStartControl::SetDefaultProfile(AdventureStartProfile::TbcRaidReady);
        }
        else
        {
            AdventureStartControl::SetDefaultProfile(AdventureStartProfile::TbcAdventure);
        }
    }

    uint32 botTarget = 0;
    if (LoadSetting(BOT_TARGET_KEY, raw) && ParseU32(raw, botTarget))
        AdminPanelGameplay::SetBotTarget(botTarget, 10);

    uint32 activity = 25;
    if (LoadSetting(BOT_ACTIVITY_KEY, raw) && ParseU32(raw, activity))
        AdminPanelGameplay::SetBotActivity(static_cast<float>(std::min<uint32>(activity, 100)));

    auto const pop = AdminPanelGameplay::GetPopulationStats();
    LOG_INFO(
        "server.loading",
        "[AdminPanel] Ready: era={} cap={} xp={:.2f} rep={:.2f} gold={:.2f} starter={} bots={}/{} batch={} activity={:.0f}%",
        AdminPanelExpansion::CurrentExpansionName(),
        AdminPanelExpansion::CurrentLevelCap(),
        sWorld->getRate(RATE_XP_KILL),
        sWorld->getRate(RATE_REPUTATION_GAIN),
        sWorld->getRate(RATE_DROP_MONEY),
        StarterName(),
        pop.bots,
        pop.botTarget,
        pop.botBatch,
        pop.botActivity);
}

class AdminPanelWorldScript : public WorldScript
{
public:
    AdminPanelWorldScript() : WorldScript("AdminPanelWorldScript") { }

    void OnAfterConfigLoad(bool /*reload*/) override
    {
        g_AdminPanelEnabled = sConfigMgr->GetOption<bool>("AdminPanel.Enable", true);
        g_AdminPanelMaxRate = sConfigMgr->GetOption<float>("AdminPanel.MaxRate", 100.0f);
        if (g_AdminPanelMaxRate < 1.0f)
            g_AdminPanelMaxRate = 1.0f;
    }

    void OnStartup() override
    {
        if (g_AdminPanelEnabled)
            LoadPersistedSettings();
    }
};

class AdminPanelCommandScript : public CommandScript
{
public:
    AdminPanelCommandScript() : CommandScript("AdminPanelCommandScript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable sub =
        {
            { "status",          HandleStatus,          SEC_GAMEMASTER, Console::No },
            { "health",          HandleHealth,          SEC_GAMEMASTER, Console::No },
            { "xp",              HandleXp,              SEC_GAMEMASTER, Console::No },
            { "rep",             HandleRep,             SEC_GAMEMASTER, Console::No },
            { "gold",            HandleGoldRate,        SEC_GAMEMASTER, Console::No },
            { "givegold",        HandleGiveGold,        SEC_GAMEMASTER, Console::No },
            { "reset",           HandleResetRates,      SEC_GAMEMASTER, Console::No },
            { "preset",          HandlePreset,          SEC_GAMEMASTER, Console::No },
            { "starter",         HandleStarter,         SEC_GAMEMASTER, Console::No },
            { "tbcraidready",    HandleTbcRaidReady,    SEC_GAMEMASTER, Console::No },
            { "wotlkraidready",  HandleWotlkRaidReady,  SEC_GAMEMASTER, Console::No },
            { "progression",     HandleProgression,     SEC_GAMEMASTER, Console::No },
            { "releasewotlk",    HandleReleaseWotlk,    SEC_GAMEMASTER, Console::No },
            { "announce",        HandleAnnounce,        SEC_GAMEMASTER, Console::No },
            { "repair",          HandleRepair,          SEC_GAMEMASTER, Console::No },
            { "restore",         HandleRestore,         SEC_GAMEMASTER, Console::No },
            { "maxskills",       HandleMaxSkills,       SEC_GAMEMASTER, Console::No },
            { "maxprofessions",  HandleMaxProfessions,  SEC_GAMEMASTER, Console::No },
            { "consumables",     HandleConsumables,     SEC_GAMEMASTER, Console::No },
            { "resettalents",    HandleResetTalents,    SEC_GAMEMASTER, Console::No },
            { "regear",          HandleRegear,          SEC_GAMEMASTER, Console::No },
            { "bots",            HandleBots,            SEC_GAMEMASTER, Console::No },
            { "botactivity",     HandleBotActivity,     SEC_GAMEMASTER, Console::No },
            { "raidnight",       HandleRaidNight,       SEC_GAMEMASTER, Console::No },
            { "groupprep",       HandleGroupPrep,       SEC_GAMEMASTER, Console::No },
            { "groupsummon",     HandleGroupSummon,     SEC_GAMEMASTER, Console::No },
            { "tp",              HandleTeleport,        SEC_GAMEMASTER, Console::No },
            { "goto",            HandleGoto,            SEC_GAMEMASTER, Console::No },
            { "summon",          HandleSummon,          SEC_GAMEMASTER, Console::No },
            { "save",            HandleSave,            SEC_GAMEMASTER, Console::No },
            { "gosaved",         HandleGoSaved,         SEC_GAMEMASTER, Console::No },
            { "saved",           HandleSaved,           SEC_GAMEMASTER, Console::No },
        };
        static ChatCommandTable root =
        {
            { "adminpanel", sub },
            { "ap", sub },
        };
        return root;
    }

private:
    static bool EnsureEnabled(ChatHandler* handler)
    {
        if (g_AdminPanelEnabled)
            return true;
        handler->PSendSysMessage("{} disabled in server configuration.", PREFIX);
        return false;
    }

    static bool SetRate(ChatHandler* handler, std::string const& raw, char const* key, char const* label)
    {
        if (!EnsureEnabled(handler))
            return true;

        float value = 0.0f;
        if (!ParseRate(raw, value))
        {
            handler->PSendSysMessage("{} {} must be between 0.01 and {:.2f}.", PREFIX, label, g_AdminPanelMaxRate);
            return true;
        }

        if (std::string(key) == XP_KEY)
            ApplyXpRate(value);
        else if (std::string(key) == REP_KEY)
            ApplyRepRate(value);
        else
            ApplyGoldRate(value);

        SaveSetting(key, std::to_string(value));
        handler->PSendSysMessage("{} {} multiplier set to {:.2f}x and saved.", PREFIX, label, value);
        return true;
    }

    static bool HandleStatus(ChatHandler* handler)
    {
        if (!EnsureEnabled(handler))
            return true;

        Player* player = CommandPlayer(handler);
        auto const pop = AdminPanelGameplay::GetPopulationStats();
        uint8 const stage = AdminPanelExpansion::PlayerProgression(player);
        double const moneyGold = player ? double(player->GetMoney()) / COPPER_PER_GOLD : 0.0;

        handler->PSendSysMessage(
            "{} STATUS era={} wotlk={} levelcap={} progressionlimit={} stage={} level={} money={:.2f} xp={:.2f} rep={:.2f} goldrate={:.2f} starter={} players={} bots={} bottarget={} botbatch={} botactivity={:.0f}",
            PREFIX,
            AdminPanelExpansion::CurrentExpansionName(),
            AdminPanelExpansion::IsWotlkReleased() ? 1 : 0,
            AdminPanelExpansion::CurrentLevelCap(),
            AdminPanelExpansion::CurrentProgressionLimit(),
            stage,
            player ? player->GetLevel() : 0,
            moneyGold,
            sWorld->getRate(RATE_XP_KILL),
            sWorld->getRate(RATE_REPUTATION_GAIN),
            sWorld->getRate(RATE_DROP_MONEY),
            StarterName(),
            pop.realPlayers,
            pop.bots,
            pop.botTarget,
            pop.botBatch,
            pop.botActivity);
        return true;
    }

    static bool HandleHealth(ChatHandler* handler)
    {
        if (!EnsureEnabled(handler))
            return true;
        auto const pop = AdminPanelGameplay::GetPopulationStats();
        handler->PSendSysMessage(
            "{} HEALTH uptime={} sessions={} players={} bots={} tick={} mean={} p95={} p99={}",
            PREFIX,
            uint32(GameTime::GetUptime().count()),
            pop.sessions,
            pop.realPlayers,
            pop.bots,
            sWorldUpdateTime.GetLastUpdateTime(),
            sWorldUpdateTime.GetAverageUpdateTime(),
            sWorldUpdateTime.GetPercentile(95),
            sWorldUpdateTime.GetPercentile(99));
        return true;
    }

    static bool HandleXp(ChatHandler* handler, std::string_view value)
    {
        return SetRate(handler, std::string(value), XP_KEY, "XP");
    }

    static bool HandleRep(ChatHandler* handler, std::string_view value)
    {
        return SetRate(handler, std::string(value), REP_KEY, "Reputation");
    }

    static bool HandleGoldRate(ChatHandler* handler, std::string_view value)
    {
        return SetRate(handler, std::string(value), GOLD_RATE_KEY, "Gold");
    }

    static bool HandleGiveGold(ChatHandler* handler, std::string_view rawValue)
    {
        if (!EnsureEnabled(handler))
            return true;
        uint32 amount = 0;
        if (!ParseU32(std::string(rawValue), amount) || amount == 0 || amount > 200000)
        {
            handler->PSendSysMessage("{} givegold accepts 1-200000 gold.", PREFIX);
            return true;
        }
        Player* player = CommandPlayer(handler);
        if (AdminPanelGameplay::GiveGold(player, amount))
            handler->PSendSysMessage("{} Added {} gold. Current total: {:.2f}g.", PREFIX, amount, double(player->GetMoney()) / COPPER_PER_GOLD);
        return true;
    }

    static bool HandleResetRates(ChatHandler* handler)
    {
        if (!EnsureEnabled(handler))
            return true;
        ApplyPreset("normal");
        handler->PSendSysMessage("{} Normal preset applied: rates 1x, bot activity 25%.", PREFIX);
        return true;
    }

    static bool HandlePreset(ChatHandler* handler, std::string_view rawPreset)
    {
        if (!EnsureEnabled(handler))
            return true;
        std::string const preset = Lower(std::string(rawPreset));
        if (preset != "normal" && preset != "fast" && preset != "raid")
        {
            handler->PSendSysMessage("{} preset must be normal, fast or raid.", PREFIX);
            return true;
        }
        ApplyPreset(preset);
        handler->PSendSysMessage("{} '{}' preset applied and saved.", PREFIX, preset);
        return true;
    }

    static bool HandleStarter(ChatHandler* handler, std::string_view rawMode)
    {
        if (!EnsureEnabled(handler))
            return true;

        std::string const mode = Lower(std::string(rawMode));
        AdventureStartProfile profile;
        if (mode == "tbc" || mode == "60" || mode == "adventure")
        {
            profile = AdventureStartProfile::TbcAdventure;
        }
        else if (mode == "tbcraid" || mode == "raid" || mode == "raidready" || mode == "70")
        {
            profile = AdventureStartProfile::TbcRaidReady;
        }
        else if (mode == "wotlkraid" || mode == "wrathraid" || mode == "80")
        {
            if (!AdminPanelExpansion::IsWotlkReleased())
            {
                handler->PSendSysMessage("{} WotLK raid-ready start is locked until WotLK is released.", PREFIX);
                return true;
            }
            profile = AdventureStartProfile::WotlkRaidReady;
        }
        else
        {
            handler->PSendSysMessage("{} starter must be 'tbc', 'tbcraid' or (after release) 'wotlkraid'.", PREFIX);
            return true;
        }

        AdventureStartControl::SetDefaultProfile(profile);
        SaveSetting(STARTER_KEY, AdventureStartControl::ProfileName(profile));
        handler->PSendSysMessage(
            "{} New-character start set to {} and saved. Existing characters are unchanged.",
            PREFIX, AdventureStartControl::ProfileName(profile));
        return true;
    }

    static bool HandleTbcRaidReady(ChatHandler* handler)
    {
        if (!EnsureEnabled(handler))
            return true;
        Player* player = CommandPlayer(handler);
        if (!player)
            return true;

        if (!AdventureStartControl::MakeTbcRaidReady(player))
        {
            handler->PSendSysMessage("{} Could not apply the TBC raid-ready profile.", PREFIX);
            return true;
        }

        handler->PSendSysMessage(
            "{} TBC raid-ready applied: level 70, stage 8, Shattrath, max TBC riding and starter supplies. Spec-aware ilvl-115 gear applies immediately when a spec is identifiable.",
            PREFIX);
        return true;
    }

    static bool HandleWotlkRaidReady(ChatHandler* handler)
    {
        if (!EnsureEnabled(handler))
            return true;
        if (!AdminPanelExpansion::IsWotlkReleased())
        {
            handler->PSendSysMessage("{} WotLK raid-ready is locked until you release Wrath of the Lich King.", PREFIX);
            return true;
        }

        Player* player = CommandPlayer(handler);
        if (!player)
            return true;

        if (!AdventureStartControl::MakeWotlkRaidReady(player))
        {
            handler->PSendSysMessage("{} Could not apply the WotLK raid-ready profile.", PREFIX);
            return true;
        }

        handler->PSendSysMessage(
            "{} WotLK raid-ready applied: level 80, stage 13, Dalaran, max riding, glyph/mount/supply bootstrap and spec-aware ilvl-200 pre-Naxx gear.",
            PREFIX);
        return true;
    }

    static bool HandleProgression(ChatHandler* handler, uint32 stage)
    {
        if (!EnsureEnabled(handler))
            return true;
        if (stage == 11 || stage < 8 || stage > AdminPanelExpansion::CurrentProgressionLimit())
        {
            handler->PSendSysMessage(
                "{} Invalid progression stage for the live expansion. Current maximum is {}.",
                PREFIX, AdminPanelExpansion::CurrentProgressionLimit());
            return true;
        }

        Player* player = CommandPlayer(handler);
        if (!AdminPanelExpansion::SetPlayerProgression(player, static_cast<uint8>(stage)))
        {
            handler->PSendSysMessage("{} Could not set progression stage {}.", PREFIX, stage);
            return true;
        }

        handler->PSendSysMessage("{} Current character progression set exactly to stage {}.", PREFIX, stage);
        return true;
    }

    static bool HandleReleaseWotlk(ChatHandler* handler, std::string_view rawConfirm)
    {
        if (!EnsureEnabled(handler))
            return true;
        if (AdminPanelExpansion::IsWotlkReleased())
        {
            handler->PSendSysMessage("{} Wrath of the Lich King is already LIVE.", PREFIX);
            return true;
        }
        if (Lower(std::string(rawConfirm)) != "confirm")
        {
            handler->PSendSysMessage("{} This permanently opens WotLK progression. Use: .ap releasewotlk confirm", PREFIX);
            return true;
        }

        AdminPanelExpansion::SetWotlkReleased(true);
        SaveSetting(WOTLK_KEY, "1");
        sWorldSessionMgr->SendServerMessage(
            SERVER_MSG_STRING,
            "Wrath of the Lich King has been released! Northrend, level 80 progression and WotLK raid-ready controls are now available.");
        handler->PSendSysMessage("{} WOTLK RELEASED. The expansion gate is permanently saved as open.", PREFIX);
        return true;
    }

    static bool HandleAnnounce(ChatHandler* handler, Tail message)
    {
        if (!EnsureEnabled(handler))
            return true;
        if (message.empty())
            return false;
        sWorldSessionMgr->SendServerMessage(SERVER_MSG_STRING, std::string(message));
        handler->PSendSysMessage("{} Announcement sent.", PREFIX);
        return true;
    }

    static bool HandleRepair(ChatHandler* handler)
    {
        if (!EnsureEnabled(handler)) return true;
        AdminPanelGameplay::Repair(CommandPlayer(handler));
        handler->PSendSysMessage("{} All equipped/inventory gear repaired for free.", PREFIX);
        return true;
    }

    static bool HandleRestore(ChatHandler* handler)
    {
        if (!EnsureEnabled(handler)) return true;
        AdminPanelGameplay::Restore(CommandPlayer(handler));
        handler->PSendSysMessage("{} Health/power restored; resurrected if needed.", PREFIX);
        return true;
    }

    static bool HandleMaxSkills(ChatHandler* handler)
    {
        if (!EnsureEnabled(handler)) return true;
        AdminPanelGameplay::MaxSkills(CommandPlayer(handler));
        handler->PSendSysMessage("{} Weapon/class skills maxed for current level.", PREFIX);
        return true;
    }

    static bool HandleMaxProfessions(ChatHandler* handler)
    {
        if (!EnsureEnabled(handler)) return true;
        uint32 const changed = AdminPanelGameplay::MaxProfessions(CommandPlayer(handler));
        handler->PSendSysMessage("{} Maxed {} learned profession/secondary skill(s) to 450/450. Unlearned professions and recipes were left alone.", PREFIX, changed);
        return true;
    }

    static bool HandleConsumables(ChatHandler* handler)
    {
        if (!EnsureEnabled(handler)) return true;
        AdminPanelGameplay::RefreshConsumables(CommandPlayer(handler));
        handler->PSendSysMessage("{} Ammo/reagents/food/potions refreshed.", PREFIX);
        return true;
    }

    static bool HandleResetTalents(ChatHandler* handler)
    {
        if (!EnsureEnabled(handler)) return true;
        AdminPanelGameplay::ResetEraTalents(CommandPlayer(handler));
        handler->PSendSysMessage("{} Current-era talents reset for free and resynced.", PREFIX);
        return true;
    }

    static bool HandleRegear(ChatHandler* handler)
    {
        if (!EnsureEnabled(handler)) return true;
        AdminPanelGameplay::RegearTbcPreRaid(CommandPlayer(handler));
        handler->PSendSysMessage("{} Regeared current character at the TBC pre-raid ilvl-115 target.", PREFIX);
        return true;
    }

    static bool HandleBots(ChatHandler* handler, std::string_view rawTarget)
    {
        if (!EnsureEnabled(handler)) return true;
        uint32 target = 0;
        if (!ParseU32(std::string(rawTarget), target) || target > 1000)
        {
            handler->PSendSysMessage("{} bots target must be 0-1000.", PREFIX);
            return true;
        }
        AdminPanelGameplay::SetBotTarget(target, 10);
        SaveSetting(BOT_TARGET_KEY, std::to_string(target));
        handler->PSendSysMessage("{} Random-bot target set to {} with a safe 10-bot ramp batch.", PREFIX, target);
        return true;
    }

    static bool HandleBotActivity(ChatHandler* handler, std::string_view rawActivity)
    {
        if (!EnsureEnabled(handler)) return true;
        uint32 activity = 0;
        if (!ParseU32(std::string(rawActivity), activity) || activity > 100)
        {
            handler->PSendSysMessage("{} botactivity must be 0-100.", PREFIX);
            return true;
        }
        AdminPanelGameplay::SetBotActivity(static_cast<float>(activity));
        SaveSetting(BOT_ACTIVITY_KEY, std::to_string(activity));
        handler->PSendSysMessage("{} Bot activity set to {}% and saved.", PREFIX, activity);
        return true;
    }

    static bool HandleRaidNight(ChatHandler* handler)
    {
        if (!EnsureEnabled(handler)) return true;
        uint32 const prepared = AdminPanelGameplay::RaidNight(CommandPlayer(handler));
        SaveSetting(BOT_ACTIVITY_KEY, "100");
        handler->PSendSysMessage("{} RAID NIGHT ready: {} group member(s) resurrected/restored/repaired/resupplied; bot activity 100%.", PREFIX, prepared);
        return true;
    }

    static bool HandleGroupPrep(ChatHandler* handler)
    {
        if (!EnsureEnabled(handler)) return true;
        uint32 const prepared = AdminPanelGameplay::PrepareGroup(CommandPlayer(handler));
        handler->PSendSysMessage("{} Prepared {} current group member(s).", PREFIX, prepared);
        return true;
    }

    static bool HandleGroupSummon(ChatHandler* handler)
    {
        if (!EnsureEnabled(handler)) return true;
        uint32 const summoned = AdminPanelGameplay::SummonGroup(CommandPlayer(handler));
        handler->PSendSysMessage("{} Summoned {} group member(s) to you.", PREFIX, summoned);
        return true;
    }

    static bool HandleTeleport(ChatHandler* handler, std::string_view destination)
    {
        if (!EnsureEnabled(handler))
            return true;
        Player* player = CommandPlayer(handler);
        TeleportPoint const* point = FindTeleport(std::string(destination));
        if (!point)
        {
            handler->PSendSysMessage("{} Unknown destination. Use: darkportal, shattrath, stormwind, ironforge, orgrimmar, thunderbluff, dalaran, argent.", PREFIX);
            return true;
        }
        if (point->requiresWotlk && !AdminPanelExpansion::IsWotlkReleased())
        {
            handler->PSendSysMessage("{} {} is locked until WotLK is released.", PREFIX, point->label);
            return true;
        }
        if (player && player->TeleportTo(point->map, point->x, point->y, point->z, point->o))
            handler->PSendSysMessage("{} Teleported to {}.", PREFIX, point->label);
        return true;
    }

    static bool HandleGoto(ChatHandler* handler, std::string_view rawName)
    {
        if (!EnsureEnabled(handler))
            return true;
        std::string const name(rawName);
        Player* player = CommandPlayer(handler);
        Player* target = ObjectAccessor::FindPlayerByName(name, false);
        if (!player || !target)
        {
            handler->PSendSysMessage("{} Player '{}' is not online.", PREFIX, name);
            return true;
        }
        player->TeleportTo(target->GetMapId(), target->GetPositionX(), target->GetPositionY(), target->GetPositionZ(), target->GetOrientation());
        handler->PSendSysMessage("{} Teleported to {}.", PREFIX, target->GetName());
        return true;
    }

    static bool HandleSummon(ChatHandler* handler, std::string_view rawName)
    {
        if (!EnsureEnabled(handler))
            return true;
        std::string const name(rawName);
        Player* player = CommandPlayer(handler);
        Player* target = ObjectAccessor::FindPlayerByName(name, false);
        if (!player || !target)
        {
            handler->PSendSysMessage("{} Player '{}' is not online.", PREFIX, name);
            return true;
        }
        target->TeleportTo(player->GetMapId(), player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(), player->GetOrientation());
        handler->PSendSysMessage("{} Summoned {}.", PREFIX, target->GetName());
        return true;
    }

    static bool HandleSave(ChatHandler* handler, std::string_view rawName)
    {
        if (!EnsureEnabled(handler))
            return true;
        Player* player = CommandPlayer(handler);
        if (!player)
            return true;
        std::string const name = Lower(std::string(rawName));
        if (!IsSafeLocationName(name))
        {
            handler->PSendSysMessage("{} Saved location names may use only A-Z, 0-9, '_' and '-' (max 24 chars).", PREFIX);
            return true;
        }
        uint32 const accountId = handler->GetSession()->GetAccountId();
        CharacterDatabase.DirectExecute(
            "REPLACE INTO mod_admin_panel_locations (account_id, name, map_id, position_x, position_y, position_z, orientation) "
            "VALUES ({}, '{}', {}, {:.6f}, {:.6f}, {:.6f}, {:.6f})",
            accountId, name, player->GetMapId(), player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(), player->GetOrientation());
        handler->PSendSysMessage("{} Saved current position as '{}'.", PREFIX, name);
        return true;
    }

    static bool HandleGoSaved(ChatHandler* handler, std::string_view rawName)
    {
        if (!EnsureEnabled(handler))
            return true;
        Player* player = CommandPlayer(handler);
        if (!player)
            return true;
        std::string const name = Lower(std::string(rawName));
        if (!IsSafeLocationName(name))
            return true;
        uint32 const accountId = handler->GetSession()->GetAccountId();
        QueryResult result = CharacterDatabase.Query(
            "SELECT map_id, position_x, position_y, position_z, orientation FROM mod_admin_panel_locations "
            "WHERE account_id = {} AND name = '{}'",
            accountId, name);
        if (!result)
        {
            handler->PSendSysMessage("{} No saved location named '{}'.", PREFIX, name);
            return true;
        }
        Field* fields = result->Fetch();
        player->TeleportTo(
            fields[0].Get<uint16>(), fields[1].Get<float>(), fields[2].Get<float>(), fields[3].Get<float>(), fields[4].Get<float>());
        handler->PSendSysMessage("{} Teleported to saved location '{}'.", PREFIX, name);
        return true;
    }

    static bool HandleSaved(ChatHandler* handler)
    {
        if (!EnsureEnabled(handler))
            return true;
        uint32 const accountId = handler->GetSession()->GetAccountId();
        QueryResult result = CharacterDatabase.Query(
            "SELECT name FROM mod_admin_panel_locations WHERE account_id = {} ORDER BY name",
            accountId);
        if (!result)
        {
            handler->PSendSysMessage("{} No saved locations yet.", PREFIX);
            return true;
        }

        std::ostringstream out;
        bool first = true;
        do
        {
            if (!first)
                out << ", ";
            first = false;
            out << result->Fetch()[0].Get<std::string>();
        } while (result->NextRow());
        handler->PSendSysMessage("{} Saved locations: {}", PREFIX, out.str());
        return true;
    }
};
}

void Addmod_admin_panelScripts()
{
    LOG_INFO("server.loading", "[AdminPanel] Registering expansion-aware server control center.");
    new AdminPanelWorldScript();
    new AdminPanelCommandScript();
    AddAdminPanelBotRecoveryScripts();
}

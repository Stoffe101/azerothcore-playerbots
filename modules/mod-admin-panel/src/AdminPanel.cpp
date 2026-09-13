#include "AdventureStartControl.h"

#include "AccountMgr.h"
#include "Chat.h"
#include "CommandScript.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "QueryResult.h"
#include "ScriptMgr.h"
#include "World.h"
#include "WorldSession.h"

#include <algorithm>
#include <array>
#include <cctype>
#include <cmath>
#include <sstream>
#include <string>
#include <string_view>

using namespace Acore::ChatCommands;

namespace
{
bool g_AdminPanelEnabled = true;
float g_AdminPanelMaxRate = 100.0f;

constexpr char XP_KEY[] = "xp_rate";
constexpr char REP_KEY[] = "rep_rate";
constexpr char GOLD_KEY[] = "gold_rate";
constexpr char STARTER_KEY[] = "starter_profile";
constexpr char PREFIX[] = "[AdminPanel]";

struct TeleportPoint
{
    char const* key;
    char const* label;
    uint32 map;
    float x;
    float y;
    float z;
    float o;
};

std::array<TeleportPoint, 8> const kTeleports = {{
    { "darkportal", "Dark Portal", 0, -11894.80f, -3206.52f, -14.62f, 0.00f },
    { "stormwind",  "Stormwind",   0, -8833.38f,   628.62f,  94.00f, 0.70f },
    { "ironforge",  "Ironforge",   0, -4981.25f,  -881.54f, 501.66f, 5.40f },
    { "orgrimmar",  "Orgrimmar",   1,  1629.36f, -4373.39f,  31.26f, 3.00f },
    { "thunderbluff", "Thunder Bluff", 1, -1274.45f, 71.86f, 128.16f, 2.80f },
    { "shattrath",  "Shattrath", 530, -1838.16f,  5301.79f, -12.43f, 5.95f },
    { "dalaran",    "Dalaran",   571,  5807.75f,   588.27f, 660.94f, 1.64f },
    { "argent",     "Argent Tournament", 571, 8475.70f, 891.54f, 547.29f, 0.00f },
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

bool TeleportPlayer(Player* player, TeleportPoint const& point)
{
    return player && player->TeleportTo(point.map, point.x, point.y, point.z, point.o);
}

void LoadPersistedSettings()
{
    std::string raw;
    float rate = 0.0f;

    if (LoadSetting(XP_KEY, raw) && ParseRate(raw, rate))
        ApplyXpRate(rate);
    if (LoadSetting(REP_KEY, raw) && ParseRate(raw, rate))
        ApplyRepRate(rate);
    if (LoadSetting(GOLD_KEY, raw) && ParseRate(raw, rate))
        ApplyGoldRate(rate);

    if (LoadSetting(STARTER_KEY, raw))
    {
        std::string const mode = Lower(raw);
        if (mode == "raid" || mode == "raidready" || mode == "80")
            AdventureStartControl::SetDefaultProfile(AdventureStartProfile::RaidReady);
        else if (mode == "tbc" || mode == "60")
            AdventureStartControl::SetDefaultProfile(AdventureStartProfile::TbcAdventure);
    }

    LOG_INFO(
        "server.loading",
        "[AdminPanel] Runtime settings loaded: xp={:.2f} rep={:.2f} gold={:.2f} starter={}",
        sWorld->getRate(RATE_XP_KILL),
        sWorld->getRate(RATE_REPUTATION_GAIN),
        sWorld->getRate(RATE_DROP_MONEY),
        AdventureStartControl::ProfileName(AdventureStartControl::GetDefaultProfile()));
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
            { "status",    HandleStatus,    SEC_GAMEMASTER, Console::No },
            { "xp",        HandleXp,        SEC_GAMEMASTER, Console::No },
            { "rep",       HandleRep,       SEC_GAMEMASTER, Console::No },
            { "gold",      HandleGold,      SEC_GAMEMASTER, Console::No },
            { "reset",     HandleReset,     SEC_GAMEMASTER, Console::No },
            { "starter",   HandleStarter,   SEC_GAMEMASTER, Console::No },
            { "raidready", HandleRaidReady, SEC_GAMEMASTER, Console::No },
            { "tp",        HandleTeleport,  SEC_GAMEMASTER, Console::No },
            { "goto",      HandleGoto,      SEC_GAMEMASTER, Console::No },
            { "summon",    HandleSummon,    SEC_GAMEMASTER, Console::No },
            { "save",      HandleSave,      SEC_GAMEMASTER, Console::No },
            { "gosaved",   HandleGoSaved,   SEC_GAMEMASTER, Console::No },
            { "saved",     HandleSaved,     SEC_GAMEMASTER, Console::No },
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
        handler->PSendSysMessage(
            "{} STATUS xp={:.2f} rep={:.2f} gold={:.2f} starter={}",
            PREFIX,
            sWorld->getRate(RATE_XP_KILL),
            sWorld->getRate(RATE_REPUTATION_GAIN),
            sWorld->getRate(RATE_DROP_MONEY),
            AdventureStartControl::ProfileName(AdventureStartControl::GetDefaultProfile()));
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

    static bool HandleGold(ChatHandler* handler, std::string_view value)
    {
        return SetRate(handler, std::string(value), GOLD_KEY, "Gold");
    }

    static bool HandleReset(ChatHandler* handler)
    {
        if (!EnsureEnabled(handler))
            return true;
        ApplyXpRate(1.0f);
        ApplyRepRate(1.0f);
        ApplyGoldRate(1.0f);
        SaveSetting(XP_KEY, "1");
        SaveSetting(REP_KEY, "1");
        SaveSetting(GOLD_KEY, "1");
        handler->PSendSysMessage("{} XP, reputation and gold reset to 1.00x.", PREFIX);
        return true;
    }

    static bool HandleStarter(ChatHandler* handler, std::string_view rawMode)
    {
        if (!EnsureEnabled(handler))
            return true;
        std::string const mode = Lower(std::string(rawMode));
        AdventureStartProfile profile;
        if (mode == "tbc" || mode == "60")
            profile = AdventureStartProfile::TbcAdventure;
        else if (mode == "raid" || mode == "raidready" || mode == "80")
            profile = AdventureStartProfile::RaidReady;
        else
        {
            handler->PSendSysMessage("{} starter must be 'tbc' or 'raidready'.", PREFIX);
            return true;
        }

        AdventureStartControl::SetDefaultProfile(profile);
        SaveSetting(STARTER_KEY, AdventureStartControl::ProfileName(profile));
        handler->PSendSysMessage(
            "{} New-character start set to {} and saved. Existing characters are unchanged.",
            PREFIX, AdventureStartControl::ProfileName(profile));
        return true;
    }

    static bool HandleRaidReady(ChatHandler* handler)
    {
        if (!EnsureEnabled(handler))
            return true;
        Player* player = CommandPlayer(handler);
        if (!player)
            return true;

        if (!AdventureStartControl::MakeRaidReady(player))
        {
            handler->PSendSysMessage("{} Could not apply the raid-ready profile.", PREFIX);
            return true;
        }

        handler->PSendSysMessage(
            "{} Raid-ready profile applied: level 80, WotLK stage 13, Dalaran, max-level starter kit. Spend at least 5 talent points to trigger the spec-aware ilvl-200 epic set.",
            PREFIX);
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
            handler->PSendSysMessage("{} Unknown destination. Use: darkportal, stormwind, ironforge, orgrimmar, thunderbluff, shattrath, dalaran, argent.", PREFIX);
            return true;
        }
        if (TeleportPlayer(player, *point))
            handler->PSendSysMessage("{} Teleported to {}.", PREFIX, point->label);
        return true;
    }

    static bool HandleGoto(ChatHandler* handler, std::string_view rawName)
    {
        if (!EnsureEnabled(handler))
            return true;
        std::string const name(rawName);
        Player* player = CommandPlayer(handler);
        Player* target = ObjectAccessor::FindPlayerByName(name);
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
        Player* target = ObjectAccessor::FindPlayerByName(name);
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
    LOG_INFO("server.loading", "[AdminPanel] Registering scripts.");
    new AdminPanelWorldScript();
    new AdminPanelCommandScript();
}

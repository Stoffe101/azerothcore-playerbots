from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


def write(path, text):
    p = ROOT / path
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text, encoding="utf-8")


def replace_once(path, old, new):
    text = read(path)
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected exactly one match, found {count}: {old[:120]!r}")
    write(path, text.replace(old, new, 1))


# ---------------------------------------------------------------------------
# Group Composer model: distinguish reserve bodies and preparation from the
# legacy RaidRoster 'managed' marker. The old marker is retained for backwards
# compatibility, but new code no longer abuses it to mean 'retask this bot'.
# ---------------------------------------------------------------------------
replace_once(
    "modules/mod-raid-roster/src/GroupComposerTypes.h",
    "    bool managed = false;\n    bool alreadyGrouped = false;\n    float itemLevel = 0.0f;",
    "    bool managed = false;\n    bool reserve = false;\n    bool needsPreparation = false;\n    bool alreadyGrouped = false;\n    float itemLevel = 0.0f;",
)
replace_once(
    "modules/mod-raid-roster/src/GroupComposerTypes.h",
    "    bool guild = false;\n    bool managed = false;\n    bool pinned = false;",
    "    bool guild = false;\n    bool managed = false;\n    bool reserve = false;\n    bool needsPreparation = false;\n    bool pinned = false;",
)

# ---------------------------------------------------------------------------
# Planner: copy reserve/preparation state into the reviewed member snapshot.
# ---------------------------------------------------------------------------
replace_once(
    "modules/mod-raid-roster/src/GroupComposerPlanner.cpp",
    "    member.guild = candidate.guild;\n    member.managed = candidate.managed;\n    member.pinned = pinned;",
    "    member.guild = candidate.guild;\n    member.managed = candidate.managed;\n    member.reserve = candidate.reserve;\n    member.needsPreparation = candidate.needsPreparation;\n    member.pinned = pinned;",
)

# Add the offline RNDbot character pool after the online world candidates. These
# are guildless ordinary random-bot bodies only; persistent guild identities are
# never force-logged through this fallback.
planner_anchor = '''    if (config.fillWorld)\n    {\n        for (Player* bot : sRandomPlayerbotMgr.GetPlayers())\n        {\n            if (!bot || sRandomPlayerbotMgr.IsAddclassBot(bot)) continue;\n            makeOnline(bot, masterGroup && bot->GetGroup() == masterGroup);\n        }\n    }\n\n    // The legacy RaidRoster pool is a safe, explicitly reserved fallback.'''
planner_insert = '''    if (config.fillWorld)\n    {\n        for (Player* bot : sRandomPlayerbotMgr.GetPlayers())\n        {\n            if (!bot || sRandomPlayerbotMgr.IsAddclassBot(bot)) continue;\n            makeOnline(bot, masterGroup && bot->GetGroup() == masterGroup);\n        }\n    }\n\n    // Group Composer reserve pool. The population controller provisions every RNDbot account with\n    // broad WotLK class coverage, so an exact composition must be able to draw a suitable CLASS\n    // body even when that character is currently offline. Build preparation owns the eventual\n    // level/spec/gear rewrite; this candidate pass only establishes safe identity/class/faction.\n    //\n    // Never force-login persistent guild identities through this fallback. Guild members are\n    // handled by the normal guild path above, and bots already grouped elsewhere are protected.\n    if (config.fillWorld && !sPlayerbotAIConfig.randomBotAccounts.empty())\n    {\n        std::string accountList;\n        for (uint32 accountId : sPlayerbotAIConfig.randomBotAccounts)\n        {\n            if (!accountList.empty()) accountList += ',';\n            accountList += std::to_string(accountId);\n        }\n\n        if (!accountList.empty())\n        {\n            QueryResult reserveRows = CharacterDatabase.Query(\n                \"SELECT guid, name, class FROM characters WHERE account IN ({}) ORDER BY guid\", accountList);\n            if (reserveRows)\n            {\n                do\n                {\n                    Field* fields = reserveRows->Fetch();\n                    uint32 low = fields[0].Get<uint32>();\n                    if (seen.count(low)) continue;\n\n                    ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(low);\n                    if (ObjectAccessor::FindConnectedPlayer(guid)) continue;\n                    if (!sCharacterCache->GetCharacterGroupGuidByGuid(guid).IsEmpty()) continue;\n                    if (sCharacterCache->GetCharacterGuildIdByGuid(guid)) continue;\n                    if (!master->IsGameMaster() && !sWorld->getBoolConfig(CONFIG_ALLOW_TWO_SIDE_INTERACTION_GROUP)\n                        && sCharacterCache->GetCharacterTeamByGuid(guid) != master->GetTeamId()) continue;\n\n                    Candidate c;\n                    c.guid = guid;\n                    c.name = fields[1].Get<std::string>();\n                    c.cls = fields[2].Get<uint8>();\n                    c.role = ROLE_DPS;\n                    c.spec = ANY_SPEC;\n                    c.online = false;\n                    c.managed = true;       // offline lifecycle is controlled by assembly\n                    c.reserve = true;       // consumes a Composer lease when assembled\n                    c.needsPreparation = true;\n                    c.utilityMask = Planner::UtilityMask(c.cls, c.spec, c.role);\n                    c.rangedDps = Planner::IsRangedDps(c.cls, c.spec, c.role);\n                    AddCandidate(out, seen, std::move(c));\n                } while (reserveRows->NextRow());\n            }\n        }\n    }\n\n    // The legacy RaidRoster pool is a safe, explicitly reserved fallback.'''
replace_once("modules/mod-raid-roster/src/GroupComposerPlanner.cpp", planner_anchor, planner_insert)

# Retasking is now explicit preparation state instead of pretending every
# converted world bot belongs to the legacy managed RaidRoster pool.
replace_once(
    "modules/mod-raid-roster/src/GroupComposerPlanner.cpp",
    '''    // Retasking is an explicit Composer action. Mark the selected bot for the existing assembly-time\n    // spec/strategy/gear synchronization path so a DPS hybrid does not merely get labelled \"tank\".\n    if (candidate.role != projected.role || candidate.spec != projected.spec)\n        projected.managed = true;''',
    '''    // Retasking is an explicit Composer action. Selection only projects the desired final state;\n    // Assemble must really rebuild talents/AI/gear before the bot is invited.\n    if (candidate.role != projected.role || candidate.spec != projected.spec)\n        projected.needsPreparation = true;''',
)

# ---------------------------------------------------------------------------
# Reserve lease manager local to Group Composer. The underlying RNDbot manager
# owns population replacement/protection; this layer owns multi-user accounting.
# ---------------------------------------------------------------------------
write("modules/mod-raid-roster/src/GroupComposerReserve.h", r'''#ifndef MOD_RAID_ROSTER_GROUP_COMPOSER_RESERVE_H
#define MOD_RAID_ROSTER_GROUP_COMPOSER_RESERVE_H

#include "Define.h"

#include <string>

class Player;

namespace GroupComposer
{
struct Plan;

namespace Reserve
{
constexpr uint32 GLOBAL_LIMIT = 80;
constexpr uint32 PER_OWNER_LIMIT = 40;

bool AcquirePlan(Player* owner, Plan const& plan, std::string& error);
void ReleaseUnjoined(Player* owner);
void ReleaseOwner(uint32 ownerGuidLow);
void Update(uint32 diff);
uint32 TotalLeased();
uint32 OwnerLeased(uint32 ownerGuidLow);
std::string Status(uint32 ownerGuidLow);
}
}

#endif
''')

write("modules/mod-raid-roster/src/GroupComposerReserve.cpp", r'''#include "GroupComposerReserve.h"

#include "GroupComposerTypes.h"

#include "CharacterCache.h"
#include "Group.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerbotAIConfig.h"
#include "RandomPlayerbotMgr.h"

#include <ctime>
#include <sstream>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace GroupComposer::Reserve
{
namespace
{
struct Lease
{
    uint32 owner = 0;
    time_t acquired = 0;
    bool randomBot = false;
};

std::unordered_map<uint32, Lease> s_leases;
std::unordered_map<uint32, std::unordered_set<uint32>> s_byOwner;
uint32 s_updateAccumulator = 0;

bool IsRandomBotCharacter(ObjectGuid guid)
{
    uint32 account = sCharacterCache->GetCharacterAccountIdByGuid(guid);
    return account && sPlayerbotAIConfig.IsInRandomAccountList(account);
}

void ReleaseBot(uint32 botLow)
{
    auto itr = s_leases.find(botLow);
    if (itr == s_leases.end()) return;

    Lease lease = itr->second;
    if (lease.randomBot)
        sRandomPlayerbotMgr.ReleaseGroupComposerBot(ObjectGuid::Create<HighGuid::Player>(botLow));

    auto ownerItr = s_byOwner.find(lease.owner);
    if (ownerItr != s_byOwner.end())
    {
        ownerItr->second.erase(botLow);
        if (ownerItr->second.empty()) s_byOwner.erase(ownerItr);
    }
    s_leases.erase(itr);
}
}

uint32 TotalLeased()
{
    return static_cast<uint32>(s_leases.size());
}

uint32 OwnerLeased(uint32 ownerGuidLow)
{
    auto itr = s_byOwner.find(ownerGuidLow);
    return itr == s_byOwner.end() ? 0u : static_cast<uint32>(itr->second.size());
}

bool AcquirePlan(Player* owner, Plan const& plan, std::string& error)
{
    if (!owner)
    {
        error = "Composer reserve has no live owner.";
        return false;
    }

    uint32 ownerLow = owner->GetGUID().GetCounter();
    std::vector<ObjectGuid> requested;
    requested.reserve(plan.members.size());
    std::unordered_set<uint32> unique;

    for (Member const& member : plan.members)
    {
        if (member.human) continue;
        if (unique.insert(member.guid.GetCounter()).second)
            requested.push_back(member.guid);
    }

    if (requested.size() > PER_OWNER_LIMIT)
    {
        error = "This roster needs " + std::to_string(requested.size()) +
            " bot slots, above the per-player Composer reserve limit of 40.";
        return false;
    }

    uint32 additional = 0;
    for (ObjectGuid guid : requested)
    {
        auto lease = s_leases.find(guid.GetCounter());
        if (lease == s_leases.end()) ++additional;
        else if (lease->second.owner != ownerLow)
        {
            error = "Selected bot is already leased to another player's active Composer roster. Run Find Roster again.";
            return false;
        }
    }

    if (OwnerLeased(ownerLow) + additional > PER_OWNER_LIMIT)
    {
        error = "Your active Composer leases would exceed 40 bot slots. Finish or disband the existing Composer group first.";
        return false;
    }
    if (TotalLeased() + additional > GLOBAL_LIMIT)
    {
        std::ostringstream out;
        out << "Composer reserve capacity is busy (" << TotalLeased() << '/' << GLOBAL_LIMIT
            << " slots in use). This roster needs " << additional << " more slot(s).";
        error = out.str();
        return false;
    }

    std::vector<uint32> acquired;
    for (ObjectGuid guid : requested)
    {
        uint32 low = guid.GetCounter();
        if (s_leases.count(low)) continue;

        bool randomBot = IsRandomBotCharacter(guid);
        if (randomBot && !sRandomPlayerbotMgr.ActivateGroupComposerBot(guid))
        {
            for (uint32 rollback : acquired) ReleaseBot(rollback);
            error = "No safe ordinary world-bot slot could be rotated out for the requested Composer roster.";
            return false;
        }

        s_leases.emplace(low, Lease{ ownerLow, time(nullptr), randomBot });
        s_byOwner[ownerLow].insert(low);
        acquired.push_back(low);
    }

    return true;
}

void ReleaseUnjoined(Player* owner)
{
    if (!owner) return;
    uint32 ownerLow = owner->GetGUID().GetCounter();
    auto itr = s_byOwner.find(ownerLow);
    if (itr == s_byOwner.end()) return;

    Group* group = owner->GetGroup();
    std::vector<uint32> release;
    for (uint32 botLow : itr->second)
    {
        ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(botLow);
        if (!group || !group->IsMember(guid)) release.push_back(botLow);
    }
    for (uint32 botLow : release) ReleaseBot(botLow);
}

void ReleaseOwner(uint32 ownerGuidLow)
{
    auto itr = s_byOwner.find(ownerGuidLow);
    if (itr == s_byOwner.end()) return;
    std::vector<uint32> release(itr->second.begin(), itr->second.end());
    for (uint32 botLow : release) ReleaseBot(botLow);
}

void Update(uint32 diff)
{
    s_updateAccumulator += diff;
    if (s_updateAccumulator < 5000) return;
    s_updateAccumulator = 0;

    time_t now = time(nullptr);
    std::vector<uint32> release;
    for (auto const& entry : s_leases)
    {
        uint32 botLow = entry.first;
        Lease const& lease = entry.second;
        if (now - lease.acquired < 60) continue; // assembly itself times out at 30 s

        Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(lease.owner));
        if (!owner)
        {
            release.push_back(botLow);
            continue;
        }

        Group* group = owner->GetGroup();
        ObjectGuid botGuid = ObjectGuid::Create<HighGuid::Player>(botLow);
        if (!group || !group->IsMember(botGuid)) release.push_back(botLow);
    }

    for (uint32 botLow : release) ReleaseBot(botLow);
}

std::string Status(uint32 ownerGuidLow)
{
    std::ostringstream out;
    out << "Composer reserve " << TotalLeased() << '/' << GLOBAL_LIMIT
        << " global; " << OwnerLeased(ownerGuidLow) << '/' << PER_OWNER_LIMIT << " yours.";
    return out.str();
}
}
''')

# ---------------------------------------------------------------------------
# Command/assembly integration.
# ---------------------------------------------------------------------------
replace_once(
    "modules/mod-raid-roster/src/GroupComposerCommand.cpp",
    '#include "GroupComposerPlanner.h"\n#include "GroupComposerTypes.h"',
    '#include "GroupComposerPlanner.h"\n#include "GroupComposerReserve.h"\n#include "GroupComposerTypes.h"',
)
replace_once(
    "modules/mod-raid-roster/src/GroupComposerCommand.cpp",
    "    uint32 ownerGuid = 0;\n    uint8 spec = ANY_SPEC;\n    uint32 elapsed = 0;",
    "    uint32 ownerGuid = 0;\n    uint8 role = ROLE_DPS;\n    uint8 spec = ANY_SPEC;\n    uint32 elapsed = 0;",
)
replace_once(
    "modules/mod-raid-roster/src/GroupComposerCommand.cpp",
    "void SyncManagedBot(Player* master, Player* bot, uint8 spec)",
    "void SyncManagedBot(Player* master, Player* bot, uint8 role, uint8 spec)",
)
replace_once(
    "modules/mod-raid-roster/src/GroupComposerCommand.cpp",
    "    if (!master || !bot) return;\n    if (spec > 2) spec = Planner::InferSpec(bot);",
    "    if (!master || !bot) return;\n    (void)role; // carried explicitly now; role-aware build/gear finalization consumes it next\n    if (spec > 2) spec = Planner::InferSpec(bot);",
)
replace_once(
    "modules/mod-raid-roster/src/GroupComposerCommand.cpp",
    "                SyncManagedBot(master, bot, itr->second.spec);",
    "                SyncManagedBot(master, bot, itr->second.role, itr->second.spec);",
)
replace_once(
    "modules/mod-raid-roster/src/GroupComposerCommand.cpp",
    "    void OnUpdate(uint32 diff) override\n    {\n        for (auto itr = s_pendingSync.begin();",
    "    void OnUpdate(uint32 diff) override\n    {\n        Reserve::Update(diff);\n        for (auto itr = s_pendingSync.begin();",
)
replace_once(
    "modules/mod-raid-roster/src/GroupComposerCommand.cpp",
    "        if (!live)\n        {\n            if (!member.managed)",
    "        if (!live)\n        {\n            if (!member.managed && !member.reserve)",
)
replace_once(
    "modules/mod-raid-roster/src/GroupComposerCommand.cpp",
    "        if (!member.managed)\n        {\n            uint8 liveRole = Planner::InferRole(live);",
    "        if (!member.managed && !member.needsPreparation && !member.reserve)\n        {\n            uint8 liveRole = Planner::InferRole(live);",
)

# Manager requirement is now only for legacy managed/addclass logins. Ordinary
# random reserve bodies are activated by RandomPlayerbotMgr while preserving the
# configured total population target.
replace_once(
    "modules/mod-raid-roster/src/GroupComposerCommand.cpp",
    '''    bool needsManagedLogin = false;\n    for (Member const& member : plan.members)\n        if (!member.human && member.managed && !ObjectAccessor::FindConnectedPlayer(member.guid)) { needsManagedLogin = true; break; }\n\n    PlayerbotMgr* mgr = needsManagedLogin ? GET_PLAYERBOT_MGR(master) : nullptr;''',
    '''    bool needsManagedLogin = false;\n    for (Member const& member : plan.members)\n        if (!member.human && member.managed && !member.reserve && !ObjectAccessor::FindConnectedPlayer(member.guid)) { needsManagedLogin = true; break; }\n\n    PlayerbotMgr* mgr = needsManagedLogin ? GET_PLAYERBOT_MGR(master) : nullptr;''',
)

replace_once(
    "modules/mod-raid-roster/src/GroupComposerCommand.cpp",
    '''    // A fresh explicit Assemble is also the explicit retry boundary for human invitations. During\n    // this attempt each real player receives at most one invite, so a decline is never turned into\n    // an invite storm by the world-update retry loop.\n    plan.humanInvitesSent.clear();''',
    '''    std::string reserveError;\n    if (!Reserve::AcquirePlan(master, plan, reserveError))\n    {\n        SendError(handler, reserveError);\n        return true;\n    }\n\n    // A fresh explicit Assemble is also the explicit retry boundary for human invitations. During\n    // this attempt each real player receives at most one invite, so a decline is never turned into\n    // an invite storm by the world-update retry loop.\n    plan.humanInvitesSent.clear();''',
)

replace_once(
    "modules/mod-raid-roster/src/GroupComposerCommand.cpp",
    '''    for (Member const& member : plan.members)\n    {\n        if (member.human || !member.managed) continue;\n        Player* bot = ObjectAccessor::FindConnectedPlayer(member.guid);\n        if (bot)\n        {\n            SyncManagedBot(master, bot, member.spec);\n            continue;\n        }\n        mgr->AddPlayerBot(member.guid, account);\n        s_pendingSync[member.guid.GetCounter()] = { owner, member.spec, 0 };\n    }''',
    '''    for (Member const& member : plan.members)\n    {\n        if (member.human || (!member.managed && !member.needsPreparation && !member.reserve)) continue;\n        Player* bot = ObjectAccessor::FindConnectedPlayer(member.guid);\n        if (bot)\n        {\n            SyncManagedBot(master, bot, member.role, member.spec);\n            continue;\n        }\n\n        // Reserve::AcquirePlan has already asked RandomPlayerbotMgr to rotate/login ordinary\n        // RNDbot reserve characters. Only the legacy managed pool uses the per-player manager.\n        if (!member.reserve)\n            mgr->AddPlayerBot(member.guid, account);\n        s_pendingSync[member.guid.GetCounter()] = { owner, member.role, member.spec, 0 };\n    }''',
)

# Release only bots that failed to join on errors/timeouts; successful group
# members retain their lease/protection until the group is disbanded.
replace_once(
    "modules/mod-raid-roster/src/GroupComposerCommand.cpp",
    '''                    plan.assembling = false;\n                    SendProtocol(master, "ERROR", completionValidationError);''',
    '''                    plan.assembling = false;\n                    Reserve::ReleaseUnjoined(master);\n                    SendProtocol(master, "ERROR", completionValidationError);''',
)
replace_once(
    "modules/mod-raid-roster/src/GroupComposerCommand.cpp",
    '''                plan.assembling = false;\n                SendProtocol(master, "ERROR", "Assembly timed out. Accepted humans and joined bots were kept; review availability and retry.");''',
    '''                plan.assembling = false;\n                Reserve::ReleaseUnjoined(master);\n                SendProtocol(master, "ERROR", "Assembly timed out. Accepted humans and joined bots were kept; review availability and retry.");''',
)
replace_once(
    "modules/mod-raid-roster/src/GroupComposerCommand.cpp",
    '''    s_drafts.erase(owner);\n    s_plans.erase(owner);\n    ClearPendingForOwner(owner);''',
    '''    Reserve::ReleaseUnjoined(master);\n    s_drafts.erase(owner);\n    s_plans.erase(owner);\n    ClearPendingForOwner(owner);''',
)
replace_once(
    "modules/mod-raid-roster/src/GroupComposerCommand.cpp",
    '''    if (s_drafts.count(owner)) handler->SendSysMessage("[GC]|STATUS|Configuration draft exists; press Find Roster to build a preview.");\n    else handler->SendSysMessage("[GC]|STATUS|Group Composer backend ready.");''',
    '''    handler->PSendSysMessage("[GC]|DIAG|{}", Sanitize(Reserve::Status(owner)));\n    if (s_drafts.count(owner)) handler->SendSysMessage("[GC]|STATUS|Configuration draft exists; press Find Roster to build a preview.");\n    else handler->SendSysMessage("[GC]|STATUS|Group Composer backend ready.");''',
)

# ---------------------------------------------------------------------------
# Upstream Playerbots integration patch. Reserved RNDbots count inside the
# existing target, are protected from scale-down/logout, and can replace one
# safe ordinary world bot when the target is full.
# ---------------------------------------------------------------------------
write("patches/0034-playerbot-group-composer-reserve.patch", r'''diff --git a/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.h b/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.h
--- a/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.h
+++ b/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.h
@@ -181,6 +181,10 @@ public:
     uint32 GetRandomBotAccountPoolCount() const { return static_cast<uint32>(rndBotTypeAccounts.size()); }
     uint32 GetPendingBotLoginCount() const { return static_cast<uint32>(botLoading.size()); }
     void RepairRandomBotPopulationState();
+    bool ActivateGroupComposerBot(ObjectGuid guid);
+    void ReleaseGroupComposerBot(ObjectGuid guid);
+    bool IsGroupComposerReserved(ObjectGuid guid) const;
+    uint32 GetGroupComposerReservedCount() const { return static_cast<uint32>(groupComposerReservedBots.size()); }
 
 protected:
     void OnBotLoginInternal(Player* const bot) override;
@@ -260,6 +264,7 @@ private:
     std::unordered_map<uint32, BotEventCache> eventCache;
     std::unordered_set<uint32> currentBots;
     uint32 randomBotCharacterCapacity = 0;
+    std::unordered_set<uint32> groupComposerReservedBots;
     uint32 playersLevel;
 
     // Account lists
diff --git a/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp b/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp
--- a/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp
+++ b/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp
@@ -101,6 +101,9 @@ namespace
 
     bool IsProtectedFromPopulationRemoval(ObjectGuid guid, Player* bot)
     {
+        if (sRandomPlayerbotMgr.IsGroupComposerReserved(guid))
+            return true;
+
         uint32 const guildId = bot ? bot->GetGuildId() : sCharacterCache->GetCharacterGuildIdByGuid(guid);
         if (guildId && PlayerbotGuildMgr::instance().IsRealGuild(guildId))
             return true;
@@ -540,6 +543,58 @@ bool RandomPlayerbotMgr::IsAccountType(uint32 accountId, uint8 accountType)
     return result != nullptr;
 }
 
+bool RandomPlayerbotMgr::IsGroupComposerReserved(ObjectGuid guid) const
+{
+    return !guid.IsEmpty() && groupComposerReservedBots.contains(guid.GetCounter());
+}
+
+bool RandomPlayerbotMgr::ActivateGroupComposerBot(ObjectGuid guid)
+{
+    if (guid.IsEmpty())
+        return false;
+
+    uint32 const botId = guid.GetCounter();
+    uint32 const accountId = sCharacterCache->GetCharacterAccountIdByGuid(guid);
+    if (!accountId || !sPlayerbotAIConfig.IsInRandomAccountList(accountId))
+        return false;
+
+    if (groupComposerReservedBots.contains(botId))
+        return true;
+
+    // Reserve first so a target-lowering scale-down cannot choose this identity while we make
+    // room. The desired character is not in currentBots yet, so it cannot itself be evicted here.
+    groupComposerReservedBots.insert(botId);
+
+    uint32 const target = GetMaxAllowedBotCount();
+    if (!currentBots.contains(botId) && target && currentBots.size() >= target)
+    {
+        uint32 const roomTarget = target - 1;
+        if (!ScaleDownRandomBots(roomTarget) && currentBots.size() >= target)
+        {
+            groupComposerReservedBots.erase(botId);
+            return false;
+        }
+    }
+
+    SetEventValue(botId, "add", 1, sPlayerbotAIConfig.permanentlyInWorldTime);
+    SetEventValue(botId, "logout", 0, 0);
+    currentBots.insert(botId);
+
+    if (!GetPlayerBot(guid) && !botLoading.contains(guid))
+        AddPlayerBot(guid, 0);
+
+    return true;
+}
+
+void RandomPlayerbotMgr::ReleaseGroupComposerBot(ObjectGuid guid)
+{
+    if (guid.IsEmpty())
+        return;
+
+    // Do not force-log the character out. It simply becomes an ordinary random bot again and the
+    // existing population controller/recycling rules decide its future naturally. This preserves
+    // the configured online target without visible churn at the end of every dungeon/raid.
+    groupComposerReservedBots.erase(guid.GetCounter());
+}
+
 uint32 RandomPlayerbotMgr::ScaleDownRandomBots(uint32 target)
 {
     uint32 const selected = static_cast<uint32>(currentBots.size());
''')

# Contract checks for the new concurrency/population semantics.
workflow = read(".github/workflows/group-composer.yml")
needle = """      - name: Check Titan Rune bridge contract\n        run: python3 client-addons-src/GroupComposer/tests/test_titan_bridge_contract.py\n"""
addition = needle + """\n      - name: Check Composer reserve contract\n        shell: bash\n        run: |\n          set -euo pipefail\n          test -f modules/mod-raid-roster/src/GroupComposerReserve.cpp\n          test -f modules/mod-raid-roster/src/GroupComposerReserve.h\n          grep -q 'GLOBAL_LIMIT = 80' modules/mod-raid-roster/src/GroupComposerReserve.h\n          grep -q 'PER_OWNER_LIMIT = 40' modules/mod-raid-roster/src/GroupComposerReserve.h\n          grep -q 'ActivateGroupComposerBot' patches/0034-playerbot-group-composer-reserve.patch\n          grep -q 'ReleaseGroupComposerBot' patches/0034-playerbot-group-composer-reserve.patch\n          grep -q 'reserve = true' modules/mod-raid-roster/src/GroupComposerPlanner.cpp\n          grep -q 'Reserve::AcquirePlan' modules/mod-raid-roster/src/GroupComposerCommand.cpp\n"""
if workflow.count(needle) != 1:
    raise SystemExit("group-composer workflow anchor changed")
write(".github/workflows/group-composer.yml", workflow.replace(needle, addition, 1))

print("Group Composer 80-slot reserve source transformation complete")

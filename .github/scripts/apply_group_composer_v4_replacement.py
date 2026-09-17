from pathlib import Path

# --- Plan state --------------------------------------------------------------
types = Path('modules/mod-raid-roster/src/GroupComposerTypes.h')
t = types.read_text(encoding='utf-8')
old = '''    bool preparing = false;
    bool prepared = false;
    uint32 prepareElapsed = 0;
    uint32 prepareProgressElapsed = 0;

    bool assembling = false;
'''
new = '''    bool preparing = false;
    bool prepared = false;
    uint32 prepareElapsed = 0;
    uint32 prepareProgressElapsed = 0;
    uint8 prepareAttempts = 0;
    std::unordered_set<uint32> rejectedCandidates;

    bool assembling = false;
'''
if old not in t: raise SystemExit('Plan preparation state marker drifted')
t = t.replace(old,new,1)
types.write_text(t,encoding='utf-8')

# --- Planner overload with excluded bot identities --------------------------
hdr = Path('modules/mod-raid-roster/src/GroupComposerPlanner.h')
h = hdr.read_text(encoding='utf-8')
old = '''    static bool Build(Player* master, Config const& config, Plan& out, std::string& error);

    // Rearrange an already-selected roster.'''
new = '''    static bool Build(Player* master, Config const& config, Plan& out, std::string& error);
    static bool Build(Player* master, Config const& config, Plan& out, std::string& error,
        std::unordered_set<uint32> const& excludedCandidates);

    // Rearrange an already-selected roster.'''
if old not in h: raise SystemExit('Planner Build declaration drifted')
h = h.replace(old,new,1)
hdr.write_text(h,encoding='utf-8')

cpp = Path('modules/mod-raid-roster/src/GroupComposerPlanner.cpp')
p = cpp.read_text(encoding='utf-8')
old = '''bool Planner::Build(Player* master, Config const& config, Plan& out, std::string& error)
{
    out = Plan{};
    out.config = config;
'''
new = '''bool Planner::Build(Player* master, Config const& config, Plan& out, std::string& error)
{
    static std::unordered_set<uint32> const none;
    return Build(master, config, out, error, none);
}

bool Planner::Build(Player* master, Config const& config, Plan& out, std::string& error,
    std::unordered_set<uint32> const& excludedCandidates)
{
    out = Plan{};
    out.config = config;
    out.rejectedCandidates = excludedCandidates;
'''
if old not in p: raise SystemExit('Planner Build implementation drifted')
p = p.replace(old,new,1)
old = '''    std::vector<Candidate> candidates = BuildCandidates(master, config, out);
    std::unordered_set<uint32> used;
'''
new = '''    std::vector<Candidate> candidates = BuildCandidates(master, config, out);
    if (!excludedCandidates.empty())
    {
        candidates.erase(std::remove_if(candidates.begin(), candidates.end(), [&](Candidate const& candidate)
        {
            return excludedCandidates.count(candidate.guid.GetCounter()) != 0;
        }), candidates.end());

        // Diagnostics describe the usable candidate snapshot, not bodies intentionally rejected by
        // an earlier preparation attempt.
        out.guildCandidates = 0;
        out.worldCandidates = 0;
        out.managedCandidates = 0;
        for (Candidate const& candidate : candidates)
        {
            if (candidate.guild) ++out.guildCandidates;
            else ++out.worldCandidates;
            if (candidate.managed) ++out.managedCandidates;
        }
    }
    std::unordered_set<uint32> used;
'''
if old not in p: raise SystemExit('candidate snapshot marker drifted')
p = p.replace(old,new,1)
cpp.write_text(p,encoding='utf-8')

# --- Runtime automatic replacement ------------------------------------------
cmd = Path('modules/mod-raid-roster/src/GroupComposerCommand.cpp')
c = cmd.read_text(encoding='utf-8')
old = '''bool BotHasPendingSync(ObjectGuid guid)
{
    return s_pendingSync.count(guid.GetCounter()) != 0;
}

uint32 SelectedBotCount(Plan const& plan)
'''
new = '''bool BotHasPendingSync(ObjectGuid guid)
{
    return s_pendingSync.count(guid.GetCounter()) != 0;
}

void ClearPendingSync(uint32 ownerLow)
{
    for (auto itr = s_pendingSync.begin(); itr != s_pendingSync.end(); )
    {
        if (itr->second.ownerGuid == ownerLow) itr = s_pendingSync.erase(itr);
        else ++itr;
    }
}

std::vector<uint32> UnreadyBotGuids(Plan const& plan)
{
    std::vector<uint32> failed;
    for (Member const& member : plan.members)
    {
        if (member.human) continue;
        Player* bot = ObjectAccessor::FindConnectedPlayer(member.guid);
        if (!bot || !GET_PLAYERBOT_AI(bot) || BotHasPendingSync(member.guid))
            failed.push_back(member.guid.GetCounter());
    }
    return failed;
}

uint32 SelectedBotCount(Plan const& plan)
'''
if old not in c: raise SystemExit('pending-sync helper marker drifted')
c = c.replace(old,new,1)

old = '''bool EnsureComposerGroup(Player* master, Plan const& plan, Group*& group, std::string& error)
'''
new = '''bool ReplaceUnreadyCandidates(Player* master, Plan& plan, std::string& detail)
{
    if (!master) { detail = "Composer lost its owner while replacing unavailable bots."; return false; }
    if (plan.prepareAttempts >= 3)
    {
        detail = "Composer exhausted three automatic replacement attempts.";
        return false;
    }

    std::vector<uint32> failed = UnreadyBotGuids(plan);
    if (failed.empty())
    {
        detail = "No replaceable unavailable bot was identified.";
        return false;
    }

    std::string firstFailed = "bot";
    for (Member const& member : plan.members)
        if (std::find(failed.begin(), failed.end(), member.guid.GetCounter()) != failed.end()) { firstFailed = member.name; break; }

    std::unordered_set<uint32> rejected = plan.rejectedCandidates;
    for (uint32 low : failed) rejected.insert(low);
    Config config = plan.config;
    uint8 nextAttempt = static_cast<uint8>(plan.prepareAttempts + 1);
    uint32 ownerLow = master->GetGUID().GetCounter();

    ClearPendingSync(ownerLow);
    Reserve::ReleaseUnjoined(master);

    Plan replacement;
    std::string buildError;
    if (!Planner::Build(master, config, replacement, buildError, rejected))
    {
        detail = "Could not replace unavailable '" + firstFailed + "': " + buildError;
        return false;
    }
    replacement.prepareAttempts = nextAttempt;
    replacement.rejectedCandidates = std::move(rejected);

    std::string prepareError;
    if (!PreparePlan(master, replacement, prepareError))
    {
        detail = "Replacement roster could not reserve/prepare fresh capacity: " + prepareError;
        return false;
    }

    plan = std::move(replacement);
    ChatHandler handler(master->GetSession());
    SendPlan(&handler, plan);
    detail = "Replaced unavailable '" + firstFailed + "' automatically; preparing fresh capacity (attempt "
        + std::to_string(unsigned(plan.prepareAttempts)) + "/3).";
    SendProgress(master, plan.prepared ? "READY" : "PREPARING", PreparedBotCount(plan), SelectedBotCount(plan), detail);
    return true;
}

bool EnsureComposerGroup(Player* master, Plan const& plan, Group*& group, std::string& error)
'''
if old not in c: raise SystemExit('EnsureComposerGroup marker drifted')
c = c.replace(old,new,1)

# The helper calls PreparePlan which is defined immediately above in source, so no forward declaration is needed.
# Trigger recovery much earlier than the old global 45-second timeout.
old = '''                else if (plan.prepareElapsed > 45000)
                {
                    plan.preparing = false;
                    plan.prepared = false;
                    if (master)
                    {
                        Reserve::ReleaseUnjoined(master);
                        SendProgress(master, "ERROR", readyBots, totalBots, "Preparation timed out before every selected bot became ready. Build & Prepare again to replace unavailable capacity.");
                    }
                }
'''
new = '''                else if (plan.prepareElapsed > 12000 && master)
                {
                    std::string replacementDetail;
                    if (!ReplaceUnreadyCandidates(master, plan, replacementDetail))
                    {
                        plan.preparing = false;
                        plan.prepared = false;
                        Reserve::ReleaseUnjoined(master);
                        ClearPendingSync(ownerLow);
                        SendProgress(master, "ERROR", readyBots, totalBots, replacementDetail);
                        SendProtocol(master, "ERROR", replacementDetail);
                    }
                    // Successful replacement resets the new plan's preparation timers internally.
                    continue;
                }
'''
if old not in c: raise SystemExit('preparation timeout marker drifted')
c = c.replace(old,new,1)

# Pending-sync entries are now owned by the plan's 12-second recovery path. Keep a defensive stale
# cleanup, but do not erase them before the planner gets a chance to identify the failed body.
c = c.replace('else if (itr->second.elapsed > 30000) itr = s_pendingSync.erase(itr);', 'else if (itr->second.elapsed > 60000) itr = s_pendingSync.erase(itr);', 1)

cmd.write_text(c,encoding='utf-8')
print('Group Composer V4 automatic replacement applied')
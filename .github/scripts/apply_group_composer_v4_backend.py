from pathlib import Path

path = Path('modules/mod-raid-roster/src/GroupComposerCommand.cpp')
text = path.read_text(encoding='utf-8')

text = text.replace('#include "Group.h"\n', '#include "Group.h"\n#include "GroupMgr.h"\n', 1)
text = text.replace('#include "Ai/Base/Actions/InviteToGroupAction.h"\n', '', 1)

old = '''void SendProtocol(Player* player, char const* kind, std::string const& text)
{
    if (!player || !player->GetSession()) return;
    ChatHandler handler(player->GetSession());
    handler.PSendSysMessage("[GC]|{}|{}", kind, Sanitize(text));
}
'''
new = old + '''
void SendProgress(Player* player, char const* phase, uint32 current, uint32 total, std::string const& detail)
{
    if (!player || !player->GetSession()) return;
    ChatHandler handler(player->GetSession());
    handler.PSendSysMessage("[GC]|PROGRESS|{}|{}|{}|{}", phase, current, total, Sanitize(detail));
}
'''
if old not in text: raise SystemExit('SendProtocol marker drifted')
text = text.replace(old, new, 1)

old = '''bool OwnerHasPendingSync(uint32 ownerLow)
{
    for (auto const& entry : s_pendingSync) if (entry.second.ownerGuid == ownerLow) return true;
    return false;
}

void TryInviteMissing(Player* master, Plan& plan)
{
    if (!master) return;
    Group* group = master->GetGroup();
    if (group) ApplyGroupSettings(master, plan);

    auto canInvite = [&]() -> bool
    {
        Group* current = master->GetGroup();
        return !current || !current->IsFull();
    };

    for (Member const& member : plan.members)
    {
        if (member.human || member.guid == master->GetGUID()) continue;
        Player* bot = ObjectAccessor::FindConnectedPlayer(member.guid);
        if (!bot || !GET_PLAYERBOT_AI(bot)) continue;
        if (BotHasOtherGameClientMaster(master, bot)) continue;
        Group* current = master->GetGroup();
        if (current && current->IsMember(member.guid)) continue;
        if (bot->GetGroup() && bot->GetGroup() != current) continue;
        if (bot->GetGroupInvite()) continue;
        if (!canInvite()) break;
        bool hadGroup = current != nullptr;
        InviteBot(master, bot);
        if (!hadGroup) return;
    }

    group = master->GetGroup();
    if (group) ApplyGroupSettings(master, plan);

    for (Member const& member : plan.members)
    {
        if (!member.human || member.guid == master->GetGUID()) continue;
        if (plan.humanInvitesSent.count(member.guid.GetCounter())) continue;
        Player* player = ObjectAccessor::FindConnectedPlayer(member.guid);
        if (!player) continue;
        Group* current = master->GetGroup();
        if (current && current->IsMember(member.guid)) continue;
        if (player->GetGroup() && player->GetGroup() != current) continue;
        if (player->GetGroupInvite()) continue;
        if (!canInvite()) break;
        bool hadGroup = current != nullptr;
        InviteHuman(master, player);
        plan.humanInvitesSent.insert(member.guid.GetCounter());
        if (!hadGroup) return;
    }
}
'''
new = '''bool OwnerHasPendingSync(uint32 ownerLow)
{
    for (auto const& entry : s_pendingSync) if (entry.second.ownerGuid == ownerLow) return true;
    return false;
}

bool BotHasPendingSync(ObjectGuid guid)
{
    return s_pendingSync.count(guid.GetCounter()) != 0;
}

uint32 SelectedBotCount(Plan const& plan)
{
    uint32 total = 0;
    for (Member const& member : plan.members) if (!member.human) ++total;
    return total;
}

uint32 PreparedBotCount(Plan const& plan)
{
    uint32 ready = 0;
    for (Member const& member : plan.members)
    {
        if (member.human) continue;
        Player* bot = ObjectAccessor::FindConnectedPlayer(member.guid);
        if (bot && GET_PLAYERBOT_AI(bot) && !BotHasPendingSync(member.guid)) ++ready;
    }
    return ready;
}

bool PreparePlan(Player* master, Plan& plan, std::string& error)
{
    if (!master) { error = "Composer preparation has no live owner."; return false; }
    uint32 owner = master->GetGUID().GetCounter();

    if (!Reserve::AcquirePlan(master, plan, error)) return false;

    bool needsManagedLogin = false;
    for (Member const& member : plan.members)
        if (!member.human && member.managed && !member.reserve && !ObjectAccessor::FindConnectedPlayer(member.guid)) { needsManagedLogin = true; break; }

    PlayerbotMgr* mgr = needsManagedLogin ? GET_PLAYERBOT_MGR(master) : nullptr;
    if (needsManagedLogin && !mgr) { error = "Playerbot manager is unavailable for an offline managed roster bot."; return false; }

    uint32 account = master->GetSession()->GetAccountId();
    for (Member const& member : plan.members)
    {
        if (member.human) continue;
        bool ownsPreparation = member.reserve || member.managed || member.needsPreparation;
        if (!ownsPreparation) continue;

        Player* bot = ObjectAccessor::FindConnectedPlayer(member.guid);
        if (bot)
        {
            // Preserve persistent guild identity until the user actually commits the roster. They
            // are deliberately ranked below disposable fallbacks when a spec swap would be needed.
            if (!(member.guild && member.needsPreparation))
                SyncManagedBot(master, bot, member.role, member.spec, FullProvisionFor(member));
            continue;
        }

        if (!member.reserve)
            mgr->AddPlayerBot(member.guid, account);
        s_pendingSync[member.guid.GetCounter()] = { owner, member.role, member.spec, FullProvisionFor(member), 0 };
    }

    plan.prepareElapsed = 0;
    plan.prepareProgressElapsed = 0;
    plan.preparing = OwnerHasPendingSync(owner);
    plan.prepared = !plan.preparing;
    return true;
}

bool EnsureComposerGroup(Player* master, Plan const& plan, Group*& group, std::string& error)
{
    if (!master) { error = "Group Composer lost the live owner while assembling."; return false; }
    group = master->GetGroup();
    if (!group)
    {
        group = new Group();
        if (!group->Create(master))
        {
            delete group;
            group = nullptr;
            error = "AzerothCore could not create the live Composer group.";
            return false;
        }
        sGroupMgr->AddGroup(group);
    }
    if (plan.config.size > 5 && !group->isRaidGroup()) group->ConvertToRaid();
    ApplyGroupSettings(master, plan);
    return true;
}

uint32 JoinedPlanMembers(Player* master, Plan const& plan)
{
    if (!master) return 0;
    Group* group = master->GetGroup();
    if (!group) return 1;
    uint32 joined = 0;
    for (Member const& member : plan.members) if (group->IsMember(member.guid)) ++joined;
    return joined;
}

std::string FirstMissingMember(Player* master, Plan const& plan)
{
    Group* group = master ? master->GetGroup() : nullptr;
    for (Member const& member : plan.members)
    {
        if (member.guid == (master ? master->GetGUID() : ObjectGuid::Empty)) continue;
        if (!group || !group->IsMember(member.guid)) return member.name;
    }
    return "member";
}

void TryAttachMissing(Player* master, Plan& plan)
{
    if (!master) return;
    Group* group = master->GetGroup();
    std::string createError;

    // Playerbots are server-owned actors. Bypass the player-style invite/accept handshake and its
    // chatter entirely; only real humans receive normal invitations.
    bool hasBotToAttach = false;
    for (Member const& member : plan.members)
        if (!member.human && member.guid != master->GetGUID()) { hasBotToAttach = true; break; }
    if (hasBotToAttach && !EnsureComposerGroup(master, plan, group, createError)) return;

    for (Member const& member : plan.members)
    {
        if (member.human || member.guid == master->GetGUID()) continue;
        Player* bot = ObjectAccessor::FindConnectedPlayer(member.guid);
        if (!bot || !GET_PLAYERBOT_AI(bot) || BotHasOtherGameClientMaster(master, bot)) continue;
        group = master->GetGroup();
        if (!group) continue;
        if (group->IsMember(member.guid)) continue;
        if (bot->GetGroup() && bot->GetGroup() != group) continue;
        if (group->IsFull()) break;
        group->AddMember(bot);
    }

    group = master->GetGroup();
    if (group) ApplyGroupSettings(master, plan);

    for (Member const& member : plan.members)
    {
        if (!member.human || member.guid == master->GetGUID()) continue;
        if (plan.humanInvitesSent.count(member.guid.GetCounter())) continue;
        Player* player = ObjectAccessor::FindConnectedPlayer(member.guid);
        if (!player) continue;
        Group* current = master->GetGroup();
        if (current && current->IsMember(member.guid)) continue;
        if (player->GetGroup() && player->GetGroup() != current) continue;
        if (player->GetGroupInvite()) continue;
        if (current && current->IsFull()) break;
        InviteHuman(master, player);
        plan.humanInvitesSent.insert(member.guid.GetCounter());
    }
}
'''
if old not in text: raise SystemExit('invite block marker drifted')
text = text.replace(old, new, 1)

# Old InviteBot helper becomes unused after server-side attach.
old = '''bool InviteBot(Player* master, Player* bot)
{
    if (!master || !bot) return false;
    PlayerbotAI* ai = GET_PLAYERBOT_AI(bot);
    if (!ai) return false;
    InviteToGroupAction action(ai);
    return action.Invite(master, bot);
}

'''
text = text.replace(old, '', 1)

old = '''        for (auto& entry : s_plans)
        {
            uint32 ownerLow = entry.first;
            Plan& plan = entry.second;
            if (!plan.assembling) continue;
            plan.assembleElapsed += diff;

            Player* master = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(ownerLow));
            if (!master)
            {
                if (plan.assembleElapsed > 30000) plan.assembling = false;
                continue;
            }

            TryInviteMissing(master, plan);
            if (PlanMembershipComplete(master, plan) && !OwnerHasPendingSync(ownerLow))
'''
new = '''        for (auto& entry : s_plans)
        {
            uint32 ownerLow = entry.first;
            Plan& plan = entry.second;
            Player* master = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(ownerLow));

            if (plan.preparing)
            {
                plan.prepareElapsed += diff;
                plan.prepareProgressElapsed += diff;
                uint32 totalBots = SelectedBotCount(plan);
                uint32 readyBots = PreparedBotCount(plan);

                if (master && plan.prepareProgressElapsed >= 500)
                {
                    plan.prepareProgressElapsed = 0;
                    SendProgress(master, "PREPARING", readyBots, totalBots,
                        readyBots == totalBots ? "Finalizing prepared roster..." : "Logging in and preparing selected bots...");
                }

                if (!OwnerHasPendingSync(ownerLow) && readyBots == totalBots)
                {
                    plan.preparing = false;
                    plan.prepared = true;
                    if (master) SendProgress(master, "READY", readyBots, totalBots, "All selected bots are online and ready to assemble.");
                }
                else if (plan.prepareElapsed > 45000)
                {
                    plan.preparing = false;
                    plan.prepared = false;
                    if (master)
                    {
                        Reserve::ReleaseUnjoined(master);
                        SendProgress(master, "ERROR", readyBots, totalBots, "Preparation timed out before every selected bot became ready. Build & Prepare again to replace unavailable capacity.");
                    }
                }
            }

            if (!plan.assembling) continue;
            plan.assembleElapsed += diff;
            plan.assembleProgressElapsed += diff;

            if (!master)
            {
                if (plan.assembleElapsed > 45000) plan.assembling = false;
                continue;
            }

            TryAttachMissing(master, plan);
            if (plan.assembleProgressElapsed >= 350)
            {
                plan.assembleProgressElapsed = 0;
                uint32 joined = JoinedPlanMembers(master, plan);
                SendProgress(master, "ASSEMBLING", joined, uint32(plan.members.size()),
                    joined == plan.members.size() ? "Finalizing subgroup layout..." : "Adding " + FirstMissingMember(master, plan) + "...");
            }
            if (PlanMembershipComplete(master, plan) && !OwnerHasPendingSync(ownerLow))
'''
if old not in text: raise SystemExit('world update marker drifted')
text = text.replace(old, new, 1)

text = text.replace('''                if (ApplyArrangement(master, plan, arrangementError))
                    SendProtocol(master, "DONE", "Roster assembled and subgroup layout applied.");
''','''                if (ApplyArrangement(master, plan, arrangementError))
                {
                    SendProgress(master, "DONE", uint32(plan.members.size()), uint32(plan.members.size()), "Roster assembled and subgroup layout applied.");
                    SendProtocol(master, "DONE", "Roster assembled and subgroup layout applied.");
                }
''',1)
text = text.replace('''            else if (plan.assembleElapsed > 30000)
            {
                plan.assembling = false;
                Reserve::ReleaseUnjoined(master);
                SendProtocol(master, "ERROR", "Assembly timed out. Accepted humans and joined bots were kept; review availability and retry.");
            }
''','''            else if (plan.assembleElapsed > 45000)
            {
                plan.assembling = false;
                Reserve::ReleaseUnjoined(master);
                uint32 joined = JoinedPlanMembers(master, plan);
                SendProgress(master, "ERROR", joined, uint32(plan.members.size()), "Assembly could not complete; the unavailable slot was " + FirstMissingMember(master, plan) + ".");
                SendProtocol(master, "ERROR", "Assembly could not complete because '" + FirstMissingMember(master, plan) + "' never became joinable. Joined members were kept; Build & Prepare will choose fresh capacity.");
            }
''',1)

old = '''    s_plans[owner] = std::move(plan);
    SendPlan(handler, s_plans[owner]);
    return true;
}
'''
new = '''    s_plans[owner] = std::move(plan);
    Plan& stored = s_plans[owner];
    std::string prepareError;
    if (!PreparePlan(master, stored, prepareError))
    {
        Reserve::ReleaseUnjoined(master);
        handler->SendSysMessage("[GC]|RESET");
        SendError(handler, prepareError);
        s_plans.erase(owner);
        return true;
    }

    SendPlan(handler, stored);
    uint32 totalBots = SelectedBotCount(stored);
    uint32 readyBots = PreparedBotCount(stored);
    SendProgress(master, stored.prepared ? "READY" : "PREPARING", readyBots, totalBots,
        stored.prepared ? "All selected bots are online and ready to assemble." : "Logging in and preparing selected bots...");
    return true;
}
'''
if old not in text: raise SystemExit('HandleFind marker drifted')
text = text.replace(old, new, 1)

old = '''    std::string validationError;
    if (!ValidateAssemblySnapshot(master, plan, validationError))
'''
new = '''    if (!plan.prepared || plan.preparing || OwnerHasPendingSync(owner))
    {
        handler->SendSysMessage("[GC]|STATUS|Roster preparation is still running. Assemble unlocks automatically when every selected bot is ready.");
        SendProgress(master, "PREPARING", PreparedBotCount(plan), SelectedBotCount(plan), "Waiting for selected bots to finish preparation...");
        return true;
    }

    std::string validationError;
    if (!ValidateAssemblySnapshot(master, plan, validationError))
'''
if old not in text: raise SystemExit('assemble validation marker drifted')
text = text.replace(old, new, 1)

# Replace the old assemble-time reserve/login/provision block with only the commit-time persistent guild retask.
start = text.find('    bool needsManagedLogin = false;\n', text.find('bool GroupComposerCommand::HandleAssemble'))
end_marker = '    plan.assembling = true;\n'
end = text.find(end_marker, start)
if start < 0 or end < 0: raise SystemExit('assemble preparation block drifted')
replacement = '''    std::string reserveError;
    if (!Reserve::AcquirePlan(master, plan, reserveError))
    {
        SendError(handler, reserveError);
        return true;
    }

    plan.humanInvitesSent.clear();

    // First destructive step: remove only unselected Playerbots. Real humans are protected by
    // ValidateAssemblySnapshot. All disposable bot preparation happened during Build & Prepare.
    PruneUnselectedBots(master, plan);

    // A specifically pinned persistent guild companion can still require a deliberate spec retask.
    // Apply that narrow combat-build change at commit time, preserving its gear/inventory/history.
    for (Member const& member : plan.members)
    {
        if (member.human || !member.guild || !member.needsPreparation) continue;
        if (Player* bot = ObjectAccessor::FindConnectedPlayer(member.guid))
            SyncManagedBot(master, bot, member.role, member.spec, false);
    }

'''
text = text[:start] + replacement + text[end:]
text = text.replace('''    plan.assembling = true;
    plan.assembleElapsed = 0;
    TryInviteMissing(master, plan);
    handler->SendSysMessage("[GC]|STATUS|Assembly started. Bots will auto-join; invited real players must accept normally.");
''','''    plan.assembling = true;
    plan.assembleElapsed = 0;
    plan.assembleProgressElapsed = 0;
    TryAttachMissing(master, plan);
    SendProgress(master, "ASSEMBLING", JoinedPlanMembers(master, plan), uint32(plan.members.size()), "Committing prepared roster to the live group...");
    handler->SendSysMessage("[GC]|STATUS|Assembly started. Prepared Playerbots are attached server-side; real players accept normally.");
''',1)

# Status sync must expose current preparation/assembly state to a freshly opened V4 dashboard.
old = '''        SendPlan(handler, plan->second);
        handler->PSendSysMessage("[GC]|STATUS|{}", plan->second.assembling ? "Assembly in progress." : "Preview synchronized from server.");
'''
new = '''        SendPlan(handler, plan->second);
        if (plan->second.assembling)
            SendProgress(master, "ASSEMBLING", JoinedPlanMembers(master, plan->second), uint32(plan->second.members.size()), "Assembly in progress...");
        else
            SendProgress(master, plan->second.prepared ? "READY" : plan->second.preparing ? "PREPARING" : "IDLE",
                PreparedBotCount(plan->second), SelectedBotCount(plan->second),
                plan->second.prepared ? "Prepared roster synchronized from server." : "Roster preparation status synchronized.");
        handler->PSendSysMessage("[GC]|STATUS|{}", plan->second.assembling ? "Assembly in progress." : "Preview synchronized from server.");
'''
if old not in text: raise SystemExit('status sync marker drifted')
text = text.replace(old, new, 1)

path.write_text(text, encoding='utf-8')

# Keep preview leases alive long enough to actually inspect a prepared raid without silently losing it.
reserve = Path('modules/mod-raid-roster/src/GroupComposerReserve.cpp')
rtext = reserve.read_text(encoding='utf-8')
rtext = rtext.replace('if (now - lease.acquired < 60) continue; // assembly itself times out at 30 s',
                      'if (now - lease.acquired < 180) continue; // prepared previews stay reserved for three minutes', 1)
reserve.write_text(rtext, encoding='utf-8')

print('Group Composer V4 backend patch applied')
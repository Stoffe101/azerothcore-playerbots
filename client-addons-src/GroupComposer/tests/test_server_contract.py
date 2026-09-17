#!/usr/bin/env python3
"""Static client/server contract tests for Group Composer.

The 3.3.5a addon deliberately owns presentation metadata while the C++ backend owns
validation and runtime actions. These assertions make duplicated activity identifiers and
critical assembly-safety hooks fail CI loudly instead of drifting silently.
"""

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[3]
DATA = (ROOT / "client-addons-src/GroupComposer/Data.lua").read_text(encoding="utf-8")
RUNTIME = (ROOT / "client-addons-src/GroupComposer/RuntimeGuards.lua").read_text(encoding="utf-8")
TOC = (ROOT / "client-addons-src/GroupComposer/GroupComposer.toc").read_text(encoding="utf-8")
CORE = (ROOT / "client-addons-src/GroupComposer/Core.lua").read_text(encoding="utf-8")
POLICY = (ROOT / "client-addons-src/GroupComposer/ComposerPolicy.lua").read_text(encoding="utf-8")
DASHBOARD = (ROOT / "client-addons-src/GroupComposer/DashboardV4.lua").read_text(encoding="utf-8")
SERVER = (ROOT / "modules/mod-raid-roster/src/GroupComposerCommand.cpp").read_text(encoding="utf-8")
PLANNER = (ROOT / "modules/mod-raid-roster/src/GroupComposerPlanner.cpp").read_text(encoding="utf-8")
TYPES = (ROOT / "modules/mod-raid-roster/src/GroupComposerTypes.h").read_text(encoding="utf-8")


def section(text: str, start: str, end: str) -> str:
    a = text.index(start)
    b = text.index(end, a + len(start))
    return text[a:b]


def ids(block: str) -> list[str]:
    return re.findall(r'\bid\s*=\s*"([^"]+)"', block)


dungeon_data = section(DATA, "D.DUNGEONS = {", "D.DUNGEON_DIFFICULTIES = {")
raid_data = section(DATA, "D.RAIDS = {", "D.RAID_DIFFICULTIES = {")
raid_server = section(SERVER, "bool RaidSupports(", "uint32 DungeonMapId(")
dungeon_server = section(SERVER, "uint32 DungeonMapId(", "uint32 RaidMapId(")

client_dungeons: dict[str, int] = {}
for entry in re.finditer(r'\{\s*id\s*=\s*"([^"]+)"([^}]*)\}', dungeon_data):
    dungeon_id, body = entry.group(1), entry.group(2)
    map_match = re.search(r'\bmap\s*=\s*(\d+)', body)
    if map_match:
        client_dungeons[dungeon_id] = int(map_match.group(1))

server_dungeons = {
    name: int(map_id)
    for name, map_id in re.findall(r'\{\s*"([^"]+)"\s*,\s*(\d+)\s*\}', dungeon_server)
}
assert client_dungeons, "No addon dungeon map metadata parsed"
assert client_dungeons == server_dungeons, (
    "Dungeon activity/map contract drift:\n"
    f"addon={client_dungeons}\nserver={server_dungeons}"
)

client_dungeon_ids = ids(dungeon_data)
assert "random" in client_dungeon_ids, "Addon lost Random Dungeon"
assert 'plan.config.activity == "random"' in SERVER, "Backend lost Random Dungeon handling"

client_raids = ids(raid_data)
assert client_raids, "No addon raid metadata parsed"
missing_raids = [raid for raid in client_raids if f'"{raid}"' not in raid_server]
assert not missing_raids, f"Raid activity missing from backend validator: {missing_raids}"
assert 'UsesWrathRaidDifficulty(plan.config.activity)' in SERVER, (
    "Live raid difficulty application no longer distinguishes Wrath from legacy Classic/TBC raids"
)
assert 'group->SetRaidDifficulty(RAID_DIFFICULTY_10MAN_NORMAL);' in SERVER, (
    "Legacy Classic/TBC raids must reset the live group to regular raid difficulty"
)

difficulty_data = section(DATA, "D.DUNGEON_DIFFICULTIES = {", "D.RAIDS = {")
client_difficulties = ids(difficulty_data)
assert client_difficulties == ["normal", "heroic", "alpha", "beta", "gamma"], client_difficulties
for mode in ("alpha", "beta", "gamma"):
    assert f'difficulty != "{mode}"' in SERVER or f'difficulty == "{mode}"' in SERVER, (
        f"Backend no longer mentions Titan Rune mode {mode}"
    )
assert "Titan Rune queue handoff is not represented by stock 3.3.5a RDF difficulty IDs" in SERVER
assert "GetLFGDungeon(mapId, difficulty)" in SERVER

for command in (
    "begin", "pref", "humanrole", "human", "pin", "arrangepref", "find", "arrange",
    "move", "assemble", "queue", "anchors", "diagnostics", "clear", "status",
):
    assert re.search(r'\{\s*"' + re.escape(command) + r'"\s*,', SERVER), (
        f"Missing server command registration: {command}"
    )

# Client safety and architecture contracts. Dashboard V4 owns presentation while RuntimeGuards owns
# protocol-only safety. No unloaded legacy UI file may be required for live behavior.
assert 'DashboardV4.lua' in TOC and 'DashboardV3.lua' not in TOC, "The live addon must load only Dashboard V4"
assert '## Version: 0.5.0' in TOC and '## X-UI-Shell: DashboardV4' in TOC
assert 'if GC.pendingCommand == "status" then GC.pendingCommand = nil end' in RUNTIME, (
    "Passive status synchronization can leave the composer permanently action-locked"
)
assert 'GROUPCOMPOSER_CONFIRM_ASSEMBLY' not in RUNTIME and 'StaticPopup_Show' not in RUNTIME, (
    "V4 must not use the legacy Blizzard assembly popup"
)
assert 'function U:ShowAssembleConfirm()' in DASHBOARD and 'GC:Assemble()' in DASHBOARD, (
    "Dashboard V4 lost its in-window assembly confirmation boundary"
)
assert 'SetShown(' not in DASHBOARD, "Dashboard V4 uses a post-Wrath frame API"
assert 'UI-CheckBox-Check' in DASHBOARD, "V4 status/toggles should use real textures instead of unsupported Unicode glyphs"
assert 'maxVisible' in DASHBOARD and 'EnableMouseWheel(true)' in DASHBOARD, (
    "V4 selectors/templates must remain bounded and scrollable"
)
assert 'Build & Prepare' in DASHBOARD and 'PROGRESS_CHANGED' in DASHBOARD, (
    "V4 must expose preparation as a visible first-class phase"
)

# Safety invariants. These are intentionally source-level contracts because removing any one of
# them changes the destructive semantics even if the module still compiles.
assert "ValidateAssemblySnapshot(master, plan, validationError)" in SERVER, "Assemble lost pre-prune revalidation"
assert SERVER.index("ValidateAssemblySnapshot(master, plan, validationError)") < SERVER.index("PruneUnselectedBots(master, plan)"), (
    "Destructive pruning must happen only after snapshot revalidation"
)
assert "group->SwapMembersGroup(member.guid, swap->guid)" in SERVER, "Full raid subgroup swaps are no longer applied atomically"
assert "group->GetMembersCount() == plan.members.size()" in SERVER, "Assembly must require exact reviewed membership"
assert "(void)keepMe; config.keepMe = true" in SERVER, "Local player anchor must remain mandatory server-side"
assert "The group gained a real player after the preview" in SERVER, "Late human joins must force a fresh preview"

# Assembly has an asynchronous window while bots log in and humans accept. The exact reviewed
# snapshot must therefore be checked both before the first destructive step and once more before
# success/subgroup application is reported.
world_update = section(SERVER, "class GroupComposerWorld", "ChatCommandTable GroupComposerCommand::GetCommands")
assert "ValidateAssemblySnapshot(master, plan, completionValidationError)" in world_update, (
    "Assembly completion lost its second authoritative snapshot validation"
)
assert world_update.index("ValidateAssemblySnapshot(master, plan, completionValidationError)") < world_update.index("ApplyArrangement(master, plan, arrangementError)"), (
    "Final snapshot validation must happen before live subgroup application"
)

# A real player's invite is user-facing state, not a retryable bot operation. One explicit Assemble
# may send a human invite once; a later explicit Assemble is the retry boundary.
assert "std::unordered_set<uint32> humanInvitesSent;" in TYPES, "Plan lost one-shot human invite tracking"
assert "plan.humanInvitesSent.clear();" in SERVER, "Fresh Assemble must reset its human invite attempt set"
assert "plan.humanInvitesSent.count(member.guid.GetCounter())" in SERVER, "Assembly can re-invite a human repeatedly"
assert "plan.humanInvitesSent.insert(member.guid.GetCounter())" in SERVER, "Sent human invites are not remembered"

# Offline humans remain roster anchors, but an offline group slot must never count as a successfully
# assembled adventuring player. The online check must happen before the already-grouped fast path.
validation = section(SERVER, "bool ValidateAssemblySnapshot(", "void InviteHuman(")
offline_human_pos = validation.index("They remain a locked roster anchor")
already_grouped_human_pos = validation.index("if (alreadyWithMaster) continue;")
assert offline_human_pos < already_grouped_human_pos, (
    "An offline human already in the group can bypass assembly revalidation"
)

# Ordinary guild/world bots are selected from their live role/spec/gear state. Re-check those hard
# facts at the Assemble boundary so the reviewed preview cannot silently drift before pruning.
assert "Planner::InferRole(live)" in validation, "Assemble no longer revalidates selected bot roles"
assert "changed active role after the preview" in validation, "Role snapshot drift lacks a hard failure"
assert "Planner::InferSpec(live)" in validation, "Assemble no longer revalidates selected bot specs"
assert "changed specialization after the preview" in validation, "Spec snapshot drift lacks a hard failure"
assert "fell below the configured minimum item level after the preview" in validation, (
    "Configured item-level floor is not protected at the Assemble boundary"
)
assert "if (!member.managed && !member.needsPreparation && !member.reserve)" in validation, (
    "Only already-correct ordinary live bots should be hard-revalidated before preparation"
)
assert "bool reserve = false;" in TYPES and "bool needsPreparation = false;" in TYPES, (
    "Reserve/preparation state must remain explicit instead of overloading the legacy managed flag"
)

# Bots with a different active game-client master belong to that player's current play session.
# Group Composer must exclude them during planning, refuse to prune them if they appear after preview,
# and refuse to attach a selected bot if ownership changes during the asynchronous commit step.
build_candidates = section(PLANNER, "std::vector<Candidate> BuildCandidates(", "int CandidateScore(")
assert "botAI->HasGameClientMaster() && botAI->GetMaster() != master" in build_candidates, (
    "Online guild/world candidates can still hijack another player's actively controlled bot"
)
assert "onlineAI->HasGameClientMaster() && onlineAI->GetMaster() != master" in build_candidates, (
    "Managed online candidates can still hijack another player's actively controlled bot"
)
assert "bool BotHasOtherGameClientMaster(Player* master, Player* bot)" in SERVER, (
    "Server lost the shared active-player bot ownership guard"
)
prune = section(SERVER, "void PruneUnselectedBots(", "bool ValidateAssemblySnapshot(")
assert "BotHasOtherGameClientMaster(master, bot)" in prune, (
    "Pruning can silently remove a bot actively controlled by another player"
)
assert "controlled by another active player and cannot be silently removed" in validation, (
    "A late human-owned Playerbot no longer blocks destructive assembly"
)
assert "Selected bot '" in validation and "is now controlled by another active player" in validation, (
    "Selected Playerbot ownership changes are not revalidated at Assemble"
)
attach = section(SERVER, "void TryAttachMissing(", "uint8 LfgRole(")
assert "BotHasOtherGameClientMaster(master, bot)" in attach, (
    "Direct Composer attachment can still pull a bot away from another active player"
)
assert "group->AddMember(bot)" in attach, (
    "Prepared Playerbots must be attached through AzerothCore group membership instead of the chatty invite handshake"
)
assert "InviteHuman(master, player)" in attach, (
    "Real humans must keep the normal player-facing invitation path"
)
assert "InviteToGroupAction" not in SERVER, (
    "V4 must not regress Playerbots to the slow invite/accept handshake"
)

# Offline managed reserve bots may retain persisted group membership. Never log in a reserve bot
# that belongs to another group, while preserving one whose cached group is this composer's group.
assert "GetCharacterGroupGuidByGuid(guid)" in build_candidates, (
    "Offline managed candidates no longer consult persisted group ownership"
)
assert "cachedGroup == masterGroup->GetGUID()" in build_candidates, (
    "Offline managed candidate cannot recognize persisted membership in the composer's group"
)
assert "if (!online && !cachedGroup.IsEmpty() && !cachedWithMaster) continue;" in build_candidates, (
    "Offline managed bot from another persisted group can be force-logged into this roster"
)

# Instance conflicts mirror the stock invite rule: different instance IDs are incompatible only
# when both players are in different copies of the same map. Merely being in different instances on
# different maps must not make an otherwise eligible friend/bot disappear from the candidate pool.
planner_instances = section(PLANNER, "bool ConflictingInstances(", "void AddCoverage(")
assert "master->GetMapId() == other->GetMapId()" in planner_instances, (
    "Planner instance-conflict filtering drifted from the stock group-invite rule"
)

# Every WotLK playable class must remain represented in the server role-capability switch. This
# deliberately catches misspelled enum names as well as accidental modern-class substitutions.
role_caps = section(PLANNER, "bool Planner::CanClassFillRole(", "uint32 Planner::UtilityMask(")
for token in (
    "CLASS_WARRIOR", "CLASS_PALADIN", "CLASS_HUNTER", "CLASS_ROGUE", "CLASS_PRIEST",
    "CLASS_DEATH_KNIGHT", "CLASS_SHAMAN", "CLASS_MAGE", "CLASS_WARLOCK", "CLASS_DRUID",
):
    assert token in role_caps, f"Role capability switch lost WotLK class token {token}"

# Selection priority is part of correctness. Required pins and Required class/spec rows are hard
# constraints. Preferred pins may be chosen before ordinary score-based filling, but never before a
# hard class/spec requirement that could need the same final role slot.
build = section(PLANNER, "bool Planner::Build(", "void Planner::Arrange(")
required_pin_pos = build.index("if (!pin.required) continue;")
required_pref_pos = build.index("std::unordered_set<uint32> requiredMemberUsed;")
preferred_pin_pos = build.index("if (pin.required) continue;")
assert required_pin_pos < required_pref_pos < preferred_pin_pos, (
    "Preferred pins must not consume slots before all hard requirements are secured"
)
assert "member.pinned = true;" in build, "A hard-selected familiar pin must retain stable/pinned identity"

# Prefer Guild is a real selection priority, not a decorative checkbox. Keeping a currently grouped
# bot is useful churn reduction, but it must not overpower the user's explicit persistent-guild
# preference. Non-guild managed reserve bots also obey the same Fill World fallback boundary.
score = section(PLANNER, "int CandidateScore(", "bool SpecCanFillRole(")
guild_bonus = re.search(r'preferGuild && candidate\.guild\) score \+= (\d+)', score)
grouped_bonus = re.search(r'candidate\.alreadyGrouped\) score \+= (\d+)', score)
assert guild_bonus and grouped_bonus, "Guild/grouped candidate priority bonuses are missing"
assert int(guild_bonus.group(1)) > int(grouped_bonus.group(1)), (
    "An already-grouped world bot can still outrank a suitable guild candidate"
)
assert "if (!c.guild && !config.fillWorld && !c.alreadyGrouped) continue;" in PLANNER, (
    "Non-guild managed reserve bots bypass the Fill World fallback switch"
)
assert "fallbackSelected = worldSelected + managedSelected" in build, (
    "Fallback warning no longer accounts for managed non-guild reserve bots"
)

# Ordinary autonomous bots are allowed to change jobs for an explicit player-composed roster. Exact
# current role/spec remains preferred, but capability must be enough to prevent a large bot world
# from failing simply because every available hybrid is currently running a DPS strategy.
retask = section(PLANNER, "bool SpecCanFillRole(", "uint8 UniqueClassCount(")
assert "Planner::CanClassFillRole(candidate.cls, role)" in retask, (
    "Composer no longer falls back from current active role to class role capability"
)
assert "projected.needsPreparation = true;" in retask, (
    "Retasked world/guild bots are not routed through assembly-time build preparation"
)
assert "candidate.role != projected.role) score -= 400" in retask, (
    "Already-correct active roles must remain preferred over unnecessary bot retasking"
)
assert "projected.guild && candidate.spec != projected.spec) score -= 10000" in retask, (
    "Persistent guild spec swaps must rank below safely preparable fallback bots"
)
assert "ProjectCandidateForRole(candidate, role, required, projected)" in retask, (
    "Required class/spec selection bypasses the same deterministic role projection path"
)

# Preparation is allowed to rebuild combat state, not a persistent companion's life history.
sync = section(SERVER, "void SyncManagedBot(", "void ApplyGroupSettings(")
assert "bool fullRebuild" in sync, "Managed preparation lost the reserve-only full rebuild boundary"
assert "if (fullRebuild) factory.Randomize(false);" in sync
assert sync.count("factory.Randomize(false)") == 1, "Full randomization must have one guarded call site"
assert "if (fullRebuild)" in sync and "RaidRosterGear::EquipForSpec(bot, master, spec);" in sync
assert "bool FullProvisionFor(Member const& member)" in SERVER
provision = section(SERVER, "bool FullProvisionFor(Member const& member)", "void ApplyGroupSettings(")
assert "member.reserve" in provision and "!member.guild" in provision and "member.needsPreparation" in provision, (
    "Persistent guild companions can no longer be distinguished from disposable full-provision bodies"
)
assert "SyncManagedBot(master, bot, member.role, member.spec, FullProvisionFor(member));" in SERVER
assert "{ owner, member.role, member.spec, FullProvisionFor(member), 0 }" in SERVER
assert "CLASS_DRUID" in sync and "role == ROLE_DPS" in sync and "buildSpec = 3" in sync, (
    "Feral DPS no longer maps to Playerbots/Era Talents Cat pseudo-spec 3"
)
prepare = section(SERVER, "bool PreparePlan(Player* master, Plan& plan", "bool EnsureComposerGroup(")
assert "Reserve::AcquirePlan(master, plan" in prepare, "Build & Prepare no longer reserves selected bot capacity"
assert "s_pendingSync[member.guid.GetCounter()]" in prepare, "Offline prepared bots are no longer tracked through login synchronization"
assert "bool preparing = false;" in TYPES and "bool prepared = false;" in TYPES, (
    "Plan lost the explicit V4 preparation state"
)
assert 'PSendSysMessage("[GC]|PROGRESS|' in SERVER, "Server no longer publishes granular V4 progress"
assemble = section(SERVER, "bool GroupComposerCommand::HandleAssemble", "bool GroupComposerCommand::HandleQueue")
assert "!plan.prepared || plan.preparing || OwnerHasPendingSync(owner)" in assemble, (
    "Assemble can commit before Build & Prepare is complete"
)
assert "PruneUnselectedBots(master, plan)" in assemble, "Destructive commit boundary disappeared"
assert "bool fullRebuild = false;" in SERVER and "itr->second.fullRebuild" in SERVER
assert 'if (member.reserve) return "RESERVE";' in SERVER
assert 'needsPreparation = fields[11] == "1"' in CORE and 'reserve = fields[12] == "1"' in CORE
assert "Policy.HumanRoleCounts = HumanRoleCounts" in POLICY
assert 'local function Remaining(role)' in DASHBOARD
assert 'Remaining("TANK")' in DASHBOARD or 'Remaining(role)' in DASHBOARD
assert 'ipairs({10,20,25,40})' in DASHBOARD, "Dashboard no longer exposes all supported raid-size families"
assert 'for _,r in ipairs(D.RAIDS)' in DASHBOARD, "Dashboard hard-filters the full raid planner catalog"
assert 'Roster planner only' in DASHBOARD and 'Encounter AI certified' in DASHBOARD, (
    "Planner-only raids must remain visibly distinct from certified encounter automation"
)
assert 'local READY_RAIDS = {' not in DASHBOARD, "Legacy hard-coded raid whitelist still restricts Group Composer"

# Utility coverage describes actual WotLK raid tools, not later-expansion semantics. Soulstone is a
# pre-applied self-resurrection safety net in this client era, not the planner's on-demand battle-rez
# capability. Druid Rebirth remains the battle-rez source.
utility = section(PLANNER, "uint32 Planner::UtilityMask(", "bool Planner::IsRangedDps(")
warlock_utility = section(utility, "case CLASS_WARLOCK:", "case CLASS_DRUID:")
druid_utility = section(utility, "case CLASS_DRUID:", "default:")
assert "UTILITY_BATTLE_REZ" not in warlock_utility, "Warlock incorrectly advertises WotLK battle-rez coverage"
assert "UTILITY_BATTLE_REZ" in druid_utility, "Druid Rebirth coverage disappeared"

print("Group Composer client/server contract tests passed")
# Shared Composer reserve semantics: population target stays authoritative while up to two full
# 40-bot sessions can lease protected online slots from the same world population.
RESERVE_H = (ROOT / "modules/mod-raid-roster/src/GroupComposerReserve.h").read_text(encoding="utf-8")
RESERVE_CPP = (ROOT / "modules/mod-raid-roster/src/GroupComposerReserve.cpp").read_text(encoding="utf-8")
RESERVE_PATCH = (ROOT / "patches/0034-playerbot-group-composer-reserve.patch").read_text(encoding="utf-8")
assert "GLOBAL_LIMIT = 80" in RESERVE_H, "Global Composer reserve must remain 80 bot slots"
assert "PER_OWNER_LIMIT = 40" in RESERVE_H, "One player must not consume more than a full 40-bot roster"
assert SERVER.count("Reserve::AcquirePlan(master, plan") >= 2, (
    "Composer must reserve at preview preparation and revalidate the lease at Assemble"
)
assert "reserve = true" in PLANNER, "Offline RNDbot class bodies are no longer exposed to the Composer reserve"
assert "ActivateGroupComposerBot" in RESERVE_PATCH and "ReleaseGroupComposerBot" in RESERVE_PATCH, (
    "Playerbot population integration lost Composer activation/release hooks"
)
assert "IsGroupComposerReserved(guid)" in RESERVE_PATCH, (
    "Composer-owned bots are no longer protected from ordinary population removal"
)


# V4 selected-activity travel. A named dungeon/raid is entered only after the exact reviewed roster
# is complete and subgroup application succeeds. Runtime coordinates come from AzerothCore's
# canonical map entrance trigger; Random Dungeon remains queue-selected and is never guessed here.
travel = section(SERVER, "bool TeleportCompletedPlan(", "void PruneUnselectedBots(")
assert "sObjectMgr->GetMapEntranceTrigger(mapId)" in travel, "Selected activity travel must use canonical instance entrance data"
assert "sMapMgr->PlayerCannotEnter(mapId, player)" in travel, "Every member must pass authoritative instance-entry preflight"
assert "player->IsInCombat()" in travel and "player->IsBeingTeleported()" in travel, "Travel lost combat/teleport safety guards"
assert "group->GetLeader()" in travel and "GET_PLAYERBOT_AI(travelLeader)" in travel, (
    "Automatic travel must resolve a live real group leader instead of treating a Composer assistant as authority"
)
assert "TitanRune::SaveSelectedMode(travelLeader, titanMode)" in travel, (
    "Named Titan Rune travel must persist the reviewed protocol on the actual group leader"
)
assert "teleport(travelLeader)" in travel and "player != travelLeader" in travel, (
    "Selected activity travel must start from the authoritative group leader"
)
assert "player->TeleportTo(destination->target_mapId" in travel, "Completed rosters are no longer teleported into the selected activity"
assert 'plan.config.activity == "random"' in travel, "Random Dungeon must remain destination-less until Dungeon Finder selects it"
for map_id in (533, 615, 616, 603, 649, 249, 624, 631, 724, 532, 568, 565, 544, 548, 550, 534, 564, 580, 309, 509, 409, 469, 531):
    assert str(map_id) in SERVER, f"Raid map {map_id} disappeared from Group Composer travel mapping"
world_update = section(SERVER, "class GroupComposerWorld", "ChatCommandTable GroupComposerCommand::GetCommands")
assert world_update.index("ApplyArrangement(master, plan, arrangementError)") < world_update.index("TeleportCompletedPlan(master, plan, travelDetail, travelError)"), (
    "Automatic activity travel must happen only after subgroup layout has been committed"
)
assert 'SendProgress(master, "TRAVEL"' in world_update, "Client no longer receives selected-activity travel progress"
assert 'GC:GetConfig().activity == "random"' in CORE, "Named dungeons must not queue again after direct travel"
assert 'TRAVEL="Entering activity"' in DASHBOARD, "Dashboard lost the explicit automatic travel phase"


# A travel-only failure happens after the exact roster is already live. It must preserve that valid
# plan and return the UI to READY after surfacing the blocker, so combat/teleport-state failures are
# retryable without rebuilding 5/25/40 members. It is status, not a roster ERROR, otherwise the
# client carries a stale red warning after the temporary blocker is gone.
travel_update = section(SERVER, "if (ApplyArrangement(master, plan, arrangementError))", "else if (plan.assembleElapsed > 45000)")
assert 'SendProtocol(master, "STATUS", travelError);' in travel_update
assert 'SendProtocol(master, "ERROR", travelError);' not in travel_update
assert 'SendProgress(master, "READY"' in travel_update
assert travel_update.index('SendProtocol(master, "STATUS", travelError);') < travel_update.index('SendProgress(master, "READY"'), (
    "Travel blocker status must be surfaced before the valid assembled roster returns to READY"
)
assert 'GC.pendingCommand == "assemble"' in CORE and '"Enter Activity"' in CORE, (
    "Retryable travel must release the client assembly action lock"
)
assert 'press Enter Activity to retry' in travel_update
assert 'Ready to enter activity' in DASHBOARD and 'ENTER SELECTED ACTIVITY?' in DASHBOARD
assert 'Auto travel after Assemble' in DASHBOARD and 'Dungeon Finder selects destination' in DASHBOARD

# V4 sends an explicit local-player marker with each roster member. Human no longer implies YOU,
# which matters as soon as a real friend is part of the reviewed raid.
send_plan = section(SERVER, "void SendPlan(", "bool RaidSupports(")
assert "viewer && member.guid == viewer->GetGUID()" in send_plan, "Roster protocol lost the local-player marker"
assert 'isPlayer = fields[13] == "1"' in CORE, "Client no longer parses the local-player roster marker"
assert '(m.isPlayer and "YOU " or "")' in DASHBOARD, "Raid preview labels every human as YOU again"

# Runtime-load and visual-density contracts for the polished V4 dashboard.
group_decl = DASHBOARD.index('local groupScroll=CreateFrame("ScrollFrame"')
content_decl = DASHBOARD.index('local content=Panel(body,C.card,C.line)')
assert 'groupScroll:Hide()' not in DASHBOARD[content_decl:group_decl], (
    "Dashboard touches groupScroll before its local declaration; Lua 5.1 would load a nil global"
)
assert "summaryRoles" in DASHBOARD and "SpecIdByLabel" in DASHBOARD, (
    "V4 lost the compact role summary or class/spec icon presentation"
)
assert "humanOverflow" in DASHBOARD and "more human anchor" in DASHBOARD, (
    "Main dashboard no longer explains when additional real-player anchors are hidden from the compact strip"
)

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
POLISH = (ROOT / "client-addons-src/GroupComposer/Polish.lua").read_text(encoding="utf-8")
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
dungeon_server = section(SERVER, "uint32 DungeonMapId(", "bool IsBotGuid(")

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

# Client safety contracts. A passive status sync must not leave the whole addon action-locked, and
# Assemble must remain an explicit commit step rather than a one-click destructive operation.
assert 'if GC.pendingCommand == "status" then GC.pendingCommand = nil end' in POLISH, (
    "Passive status synchronization can leave the composer permanently action-locked"
)
assert 'StaticPopupDialogs["GROUPCOMPOSER_CONFIRM_ASSEMBLY"]' in POLISH, (
    "Live roster assembly lost its explicit confirmation boundary"
)
assert 'StaticPopup_Show("GROUPCOMPOSER_CONFIRM_ASSEMBLY"' in POLISH, (
    "Assemble no longer routes through the confirmation popup"
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
assert "if (!member.managed)" in validation, (
    "Managed RaidRoster bots must remain exempt from live role/spec checks because Assemble reconciles them"
)

# Bots with a different active game-client master belong to that player's current play session.
# Group Composer must exclude them during planning, refuse to prune them if they appear after preview,
# and refuse to keep/invite a selected bot if ownership changes during the asynchronous assemble step.
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
try_invite = section(SERVER, "void TryInviteMissing(", "uint8 LfgRole(")
assert "BotHasOtherGameClientMaster(master, bot)" in try_invite, (
    "Asynchronous invite retries can still pull a bot away from another active player"
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
score = section(PLANNER, "int CandidateScore(", "Candidate const* BestCandidate(")
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

# Utility coverage describes actual WotLK raid tools, not later-expansion semantics. Soulstone is a
# pre-applied self-resurrection safety net in this client era, not the planner's on-demand battle-rez
# capability. Druid Rebirth remains the battle-rez source.
utility = section(PLANNER, "uint32 Planner::UtilityMask(", "bool Planner::IsRangedDps(")
warlock_utility = section(utility, "case CLASS_WARLOCK:", "case CLASS_DRUID:")
druid_utility = section(utility, "case CLASS_DRUID:", "default:")
assert "UTILITY_BATTLE_REZ" not in warlock_utility, "Warlock incorrectly advertises WotLK battle-rez coverage"
assert "UTILITY_BATTLE_REZ" in druid_utility, "Druid Rebirth coverage disappeared"

print("Group Composer client/server contract tests passed")

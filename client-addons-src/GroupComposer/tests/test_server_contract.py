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
MODERN = (ROOT / "client-ui/src/components/ModernDashboard.ts").read_text(encoding="utf-8")
ACTIVITY_BROWSER = (ROOT / "client-ui/src/components/ActivityBrowser.ts").read_text(encoding="utf-8")
UNLOCK_REQUIREMENTS = (ROOT / "client-ui/src/components/UnlockRequirementsModal.ts").read_text(encoding="utf-8")
TEMPLATE_BROWSER = (ROOT / "client-ui/src/components/TemplateBrowser.ts").read_text(encoding="utf-8")
MODEL = (ROOT / "client-ui/src/model/ComposerModel.ts").read_text(encoding="utf-8")
SELECTOR = (ROOT / "client-ui/src/components/BuildSelector.ts").read_text(encoding="utf-8")
CHOICE_SELECT = (ROOT / "client-ui/src/widgets/ChoiceSelect.ts").read_text(encoding="utf-8")
SCROLL_LIST = (ROOT / "client-ui/src/widgets/ScrollList.ts").read_text(encoding="utf-8")
TOGGLE = (ROOT / "client-ui/src/widgets/Toggle.ts").read_text(encoding="utf-8")
STEPPER = (ROOT / "client-ui/src/widgets/Stepper.ts").read_text(encoding="utf-8")
TEXT_INPUT = (ROOT / "client-ui/src/widgets/TextInput.ts").read_text(encoding="utf-8")
BUTTON = (ROOT / "client-ui/src/widgets/Button.ts").read_text(encoding="utf-8")
MODAL = (ROOT / "client-ui/src/widgets/Modal.ts").read_text(encoding="utf-8")
NATIVE = (ROOT / "client-ui/src/core/Native.ts").read_text(encoding="utf-8")
WOW_RUNTIME_SMOKE = (ROOT / "client-ui/tests/wow_runtime_smoke.lua").read_text(encoding="utf-8")
SERVER = (ROOT / "modules/mod-raid-roster/src/GroupComposerCommand.cpp").read_text(encoding="utf-8")
PLANNER = (ROOT / "modules/mod-raid-roster/src/GroupComposerPlanner.cpp").read_text(encoding="utf-8")
TYPES = (ROOT / "modules/mod-raid-roster/src/GroupComposerTypes.h").read_text(encoding="utf-8")
GEAR_H = (ROOT / "modules/mod-raid-roster/src/RaidRosterGear.h").read_text(encoding="utf-8")
GEAR_CPP = (ROOT / "modules/mod-raid-roster/src/RaidRosterGear.cpp").read_text(encoding="utf-8")
SILENT_LOGIN_PATCH = (ROOT / "patches/0035-playerbot-group-composer-silent-login.patch").read_text(encoding="utf-8")
CAPACITY_BYPASS_PATCH = (ROOT / "patches/0038-playerbot-group-composer-capacity-bypass.patch").read_text(encoding="utf-8")
QUIET_BOT_PATCH = (ROOT / "patches/0040-playerbot-quiet-routine-whispers.patch").read_text(encoding="utf-8")
ADVENTURE_START = (ROOT / "modules/mod-raid-roster/src/AdventureStart.cpp").read_text(encoding="utf-8")
ADVENTURE_START_CONTROL = (ROOT / "modules/mod-raid-roster/src/AdventureStartControl.cpp").read_text(encoding="utf-8")
ADVENTURE_START_CONTROL_H = (ROOT / "modules/mod-raid-roster/src/AdventureStartControl.h").read_text(encoding="utf-8")
ADMIN_PANEL = (ROOT / "modules/mod-admin-panel/src/AdminPanel.cpp").read_text(encoding="utf-8")
ADVENTURE_CATALOG = (ROOT / "modules/mod-raid-roster/src/AdventureCatalog.cpp").read_text(encoding="utf-8")
PROGRESSION_HISTORY = (ROOT / "modules/mod-raid-roster/src/AdventureProgressionHistory.cpp").read_text(encoding="utf-8")
PROGRESSION_HISTORY_SQL = (ROOT / "modules/mod-raid-roster/data/sql/db-characters/base/2026_09_20_00_mod_adventure_progression_history.sql").read_text(encoding="utf-8")
PROGRESSION_ACTIVITY_ID_MIGRATION = (ROOT / "modules/mod-raid-roster/data/sql/db-characters/base/2026_09_20_01_mod_adventure_progression_activity_id.sql").read_text(encoding="utf-8")
PROGRESSION_CLEAR_SNAPSHOT_SQL = (ROOT / "modules/mod-raid-roster/data/sql/db-characters/base/2026_09_20_02_mod_adventure_progression_clear_snapshots.sql").read_text(encoding="utf-8")
PROGRESSION_PAGE = (ROOT / "client-ui/src/components/ProgressionPage.ts").read_text(encoding="utf-8")
RECOMMENDATIONS_PAGE = (ROOT / "client-ui/src/components/RecommendationsPage.ts").read_text(encoding="utf-8")
MEMBER_DETAILS = (ROOT / "client-ui/src/components/MemberDetailsModal.ts").read_text(encoding="utf-8")
GROUP_ACTIONS = (ROOT / "client-ui/src/components/GroupActionsModal.ts").read_text(encoding="utf-8")
ACTIVITY_DIAGNOSTICS = (ROOT / "client-ui/src/components/ActivityDiagnosticsPage.ts").read_text(encoding="utf-8")
UTILITY_COVERAGE = (ROOT / "client-ui/src/components/UtilityCoverageModal.ts").read_text(encoding="utf-8")
RAID_HISTORY_MODAL = (ROOT / "client-ui/src/components/RaidHistoryModal.ts").read_text(encoding="utf-8")
GENERATED_UI = (ROOT / "client-addons-src/GroupComposer/GroupComposerModernUI.lua").read_text(encoding="utf-8")


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
    for name, map_id in re.findall(
        r'\{\s*"[^"]+"\s*,\s*"([^"]+)"\s*,\s*"[^"]+"\s*,\s*'
        r'AdventureActivityKind::Dungeon\s*,\s*AdventureEra::\w+\s*,\s*(\d+)',
        ADVENTURE_CATALOG,
    )
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
    "move", "assemble", "teleport", "leave", "disband", "activities", "requirements", "journey", "queue", "anchors", "diagnostics", "catalogdiag", "clear", "status",
):
    assert re.search(r'\{\s*"' + re.escape(command) + r'"\s*,', SERVER), (
        f"Missing server command registration: {command}"
    )

# Client safety and architecture contracts. The live shell is generated from typed TypeScript,
# while RuntimeGuards keeps protocol-only safety. Legacy dashboards stay in history/source only.
assert 'GroupComposerModernUI.lua' in TOC, "The live addon must load the generated modern UI"
assert 'DashboardV4.lua' not in TOC and 'DashboardV3.lua' not in TOC, "Legacy dashboard shells must not load"
assert '## Version: 0.14.0' in TOC and '## X-UI-Shell: ModernTypedV1' in TOC
assert 'if GC.pendingCommand == "status" then GC.pendingCommand = nil end' in RUNTIME, (
    "Passive status synchronization can leave the composer permanently action-locked"
)
assert 'GROUPCOMPOSER_CONFIRM_ASSEMBLY' not in RUNTIME and 'StaticPopup_Show' not in RUNTIME, (
    "Modern Composer must not use the legacy Blizzard assembly popup"
)
assert 'showAssembleConfirm' in MODERN and 'Model.assemble()' in MODERN, (
    "Modern dashboard lost its in-window assembly confirmation boundary"
)
assert 'SetShown(' not in MODERN, "Modern dashboard uses a post-Wrath frame API"
assert 'UI-CheckBox-Check' in TOGGLE and 'createOutline' in TOGGLE, (
    "Modern toggles must use the compact native checkbox treatment"
)
assert 'maxVisible' in CHOICE_SELECT and 'EnableMouseWheel(true)' in CHOICE_SELECT, (
    "Modern selectors must remain bounded and scrollable"
)
assert 'Build & Prepare' in MODERN and 'PROGRESS_CHANGED' in MODERN, (
    "Modern dashboard must expose preparation as a visible first-class phase"
)

# Safety invariants. These are intentionally source-level contracts because removing any one of
# them changes the destructive semantics even if the module still compiles.
begin_assembly = section(SERVER, "bool BeginPreparedAssembly(", "uint8 LfgRole(")
assert "ValidateAssemblySnapshot(master, plan, error)" in begin_assembly, (
    "Shared automatic/manual assembly path lost authoritative pre-commit revalidation"
)
assert "PruneUnselectedBots" not in SERVER, (
    "Assembly must not contain an implicit destructive prune phase"
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
assert "abovePeerBand && !alreadyGrouped" in build_candidates, (
    "Non-grouped overleveled bots must be excluded before scoring"
)
assert "above this activity's peer cap" in PLANNER, (
    "Sticky live-group overleveled bots must fail explicitly instead of being silently pruned"
)
assert "above the anti-boost peer cap" in SERVER, (
    "Assembly/preparation must revalidate the bot level ceiling after preview"
)
assert "botAI->HasGameClientMaster() && botAI->GetMaster() != master" in build_candidates, (
    "Online guild/world candidates can still hijack another player's actively controlled bot"
)
assert "onlineAI->HasGameClientMaster() && onlineAI->GetMaster() != master" in build_candidates, (
    "Managed online candidates can still hijack another player's actively controlled bot"
)
assert "bool BotHasOtherGameClientMaster(Player* master, Player* bot)" in SERVER, (
    "Server lost the shared active-player bot ownership guard"
)
assert "PruneUnselectedBots" not in SERVER, (
    "Composer must never silently prune an existing live-group Playerbot"
)
assert "never removes existing party/raid bots automatically" in validation, (
    "Late Playerbot membership changes must block assembly instead of becoming destructive pruning"
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

# Build & Prepare may need to log in managed/offline Playerbots, but doing so through the ordinary
# Playerbot login lifecycle used to generate a "Hello!" whisper per bot and auto-queue group joins.
# Composer owns both UX and membership, so its dedicated silent-login flag must suppress those two
# side effects while preserving the normal master/AI relationship.
assert "mgr->AddPlayerBot(member.guid, account, true);" in SERVER, (
    "Composer preparation no longer requests the silent Playerbot login path"
)
assert "!groupComposerSilent && count >= uint32(PlayerbotAIConfig::instance().maxAddedBots)" in CAPACITY_BYPASS_PATCH, (
    "Composer silent capacity is still incorrectly limited by the manual MaxAddedBots cap"
)
assert "bool groupComposerSilent = false" in SILENT_LOGIN_PATCH
assert "s_groupComposerSilentLogins" in SILENT_LOGIN_PATCH
assert "if (!groupComposerSilent)" in SILENT_LOGIN_PATCH
assert '"hello", "Hello!"' in SILENT_LOGIN_PATCH
assert "GroupInviteOperation" in SILENT_LOGIN_PATCH

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

# Fast capacity and live-group ownership are first-class V4 invariants. AddClass is upstream's
# quick class-addressable pool; current group bots are hard anchors rather than high-score suggestions.
assert "sRandomPlayerbotMgr.addclassCache" in build_candidates, (
    "Composer no longer exposes dedicated AddClass quick capacity"
)
assert "c.managed = true;" in build_candidates and "c.needsPreparation = true;" in build_candidates
assert "Reserve::AvailableTo(master->GetGUID().GetCounter(), candidate.guid)" in PLANNER, (
    "Planner can still select a bot leased to another Composer owner"
)
assert "candidate.alreadyGrouped" in PLANNER and "Group Composer will not remove existing party/raid bots automatically" in PLANNER, (
    "Existing live-group bots are no longer sticky hard anchors"
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
online_bonus = re.search(r'candidate\.online\) score \+= (\d+)', score)
assert online_bonus and int(online_bonus.group(1)) >= 2000, (
    "Composer no longer strongly prefers already-online capacity for instant preparation"
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

# Exact composition is deliberately partial: players can reserve only the class/spec slots they care
# about and leave every other role slot to Composer's normal score/coverage-based Auto fill. A class
# may also be locked with spec ANY so, for example, "bring a Warlock" does not force one spec.
assert 'export const ANY_SPEC_ID = -1' in MODEL
assert 'spec: row.specId === ANY_SPEC_ID ? "ANY" : row.specId' in MODEL
assert 'Any valid spec' in SELECTOR
assert 'Every unreserved slot stays Auto.' in SELECTOR
preference_handler = section(SERVER, "bool GroupComposerCommand::HandlePreference", "bool GroupComposerCommand::HandleHumanRole")
assert "spec == ANY_SPEC && !Planner::CanClassFillRole(cls, role)" in preference_handler
assert "spec != ANY_SPEC && !SpecCanFillRole(cls, spec, role)" in preference_handler
assert "if (required && required->cls && candidate.cls != required->cls) return false;" in retask
assert "if (required && required->spec != ANY_SPEC)" in retask

# Built-in templates are raid-only coverage cores, never rigid 25-character prescriptions. Their
# source data reserves high-impact buff/debuff classes and leaves an Auto remainder for the player,
# live humans, guild preference, encounter needs, and candidate availability.
assert 'CoveragePreferences(size)' in DATA
assert 'Coverage-first core + Auto remainder' in DATA
assert 'D.BUILTIN_PROFILES = {}' in DATA and 'for _, raid in ipairs(D.RAIDS)' in DATA
builtin_profile_tail = DATA[DATA.index("D.BUILTIN_PROFILES = {}"):]
assert 'RaidProfile(' in builtin_profile_tail
assert 'Profile("Dungeon' not in builtin_profile_tail, "Dungeon presets must not return to the raid template library"
profiles_text = (ROOT / "client-addons-src/GroupComposer/Profiles.lua").read_text(encoding="utf-8")
assert 'function P.ListCustom(mode)' in profiles_text
assert 'p.mode ~= "RAID"' not in profiles_text, "Dungeon party templates must remain saveable"
assert 'profileDescription' in MODEL and 'profileMeta' in MODEL
assert 'TemplateBrowserUI.createTemplateBrowser(frame)' in MODERN
assert 'scroll.scrollToTop()' in TEMPLATE_BROWSER and 'createScrollList(modal.content' in TEMPLATE_BROWSER
assert 'scrollBy(-64)' in SCROLL_LIST and 'scrollBy(64)' in SCROLL_LIST

# Preparation is allowed to rebuild combat state, not a persistent companion's life history.
sync = section(SERVER, "void SyncManagedBot(", "void ApplyGroupSettings(")
assert "bool fullRebuild" in sync, "Managed preparation lost the reserve-only full rebuild boundary"
assert "factory.Randomize(false)" not in sync, "Composer capacity must not use whole-character randomization"
for token in ("factory.InitSkills()", "factory.InitClassSpells()", "factory.InitAvailableSpells()",
              "factory.InitSpecialSpells()", "factory.InitGlyphs(false)",
              "RaidRosterGear::EquipForSpec(bot, master, spec, minimumItemLevel, targetItemLevel)",
              "factory.ApplyEnchantAndGemsNew()", "factory.InitAmmo()"):
    assert token in sync, f"Targeted Composer provisioning lost {token}"
assert "bool FullProvisionFor(Member const& member)" in SERVER
provision = section(SERVER, "bool FullProvisionFor(Member const& member)", "void ApplyGroupSettings(")
assert "member.reserve" in provision and "!member.guild" in provision and "member.needsPreparation" in provision, (
    "Persistent guild companions can no longer be distinguished from disposable full-provision bodies"
)
assert "SyncManagedBot(master, bot, member.role, member.spec, plan.config.botTargetLevel" in SERVER
assert "owner, member.role, member.spec, plan.config.botTargetLevel, minimumItemLevel" in SERVER
assert "targetItemLevel, fullProvision, 0" in SERVER
assert "CLASS_DRUID" in sync and "role == ROLE_DPS" in sync and "buildSpec = 3" in sync, (
    "Feral DPS no longer maps to Playerbots/Era Talents Cat pseudo-spec 3"
)
prepare = section(SERVER, "bool PreparePlan(Player* master, Plan& plan", "bool EnsureComposerGroup(")
assert "Reserve::AcquirePlan(master, plan" in prepare, "Build & Prepare no longer reserves selected bot capacity"
assert "s_pendingSync[member.guid.GetCounter()]" in prepare, "Offline prepared bots are no longer tracked through login synchronization"
assert "bool preparing = false;" in TYPES and "bool prepared = false;" in TYPES, (
    "Plan lost the explicit V4 preparation state"
)
assert "plan.prepareElapsed > 15000" in SERVER, "Offline fallback preparation must stay bounded instead of stalling for 50 seconds"
assert "itr->second.elapsed > 12000" in SERVER, "Individual login/provision callbacks must have a short bounded fallback window"
assert "ReplaceUnreadyCandidates" not in SERVER, (
    "Composer regressed to whole-roster replacement churn"
)
assert 'PSendSysMessage("[GC]|PROGRESS|' in SERVER, "Server no longer publishes granular V4 progress"

# Readiness validates the finalized combat build, not a strategy flag that can lag one AI tick.
readiness = section(SERVER, "std::string PreparedMemberBlocker(", "uint32 SelectedBotCount(")
assert "SpecCanFillRole(member.cls, liveSpec, member.role)" in readiness
assert "Planner::InferRole(bot)" not in readiness, "Readiness regressed to lagging AI strategy role inference"
assert '"is still offline"' in readiness and '"is online but Playerbot AI is not initialized"' in readiness
assert "PreparedItemLevelFloor" in readiness

# Progression/era is finalized before talents and gear so an EraTalents transition cannot erase the
# build Composer just prepared.
sync_body = section(SERVER, "void SyncManagedBot(", "bool FullProvisionFor(")
assert "EraTransition::Detect(bot);" in sync_body
assert sync_body.index("RaidRosterEra::SyncBotToMaster(master, bot);") < sync_body.index("FactoryReconcile"), (
    "Composer still changes progression era after finalizing talents"
)
assert "ComposerGearProfile" in SERVER and "GearProfileFor(plan.config)" in SERVER
assert "preferredItemLevel" in GEAR_H and "preferredItemLevel" in GEAR_CPP

# Build & Prepare and Assemble are deliberately separate lifecycle stages. Preparation ends at a
# reviewable READY roster; only an explicit Assemble command commits that snapshot to the live group.
world_prepare = section(SERVER, "if (plan.preparing)", "if (plan.travelPending)")
assert "plan.prepared = true;" in world_prepare
assert 'SendProgress(master, "READY"' in world_prepare
assert "BeginPreparedAssembly(master, plan, assemblyError)" not in world_prepare
find_handler = section(SERVER, "bool GroupComposerCommand::HandleFind", "bool GroupComposerCommand::HandleArrange")
assert 'SendProgress(master, "READY"' in find_handler
assert "BeginPreparedAssembly(master, stored, assemblyError)" not in find_handler

assemble = section(SERVER, "bool GroupComposerCommand::HandleAssemble", "bool GroupComposerCommand::HandleTeleport")
assert "BeginPreparedAssembly(master, plan, assemblyError)" in assemble
assert "!plan.prepared || plan.preparing || OwnerHasPendingSync(owner)" in assemble, (
    "Assemble can commit before Build & Prepare is complete"
)
assert "PruneUnselectedBots" not in assemble, "Assembly must not silently remove live group bots"
assert "bool fullRebuild = false;" in SERVER and "itr->second.fullRebuild" in SERVER
assert 'if (member.reserve) return "RESERVE";' in SERVER
assert 'needsPreparation = fields[11] == "1"' in CORE and 'reserve = fields[12] == "1"' in CORE
assert "Policy.HumanRoleCounts = HumanRoleCounts" in POLICY
assert 'remainingBotSlots(role' in MODEL
assert 'humanRoleCounts()' in MODEL
assert '[10, 20, 25, 40]' in MODERN, "Modern dashboard no longer exposes all supported raid-size families"
assert 'for (const raid of D.RAIDS' in MODEL, "Modern dashboard hard-filters the full raid planner catalog"
assert 'READY_RAIDS' not in MODERN and 'ENCOUNTER_READY' not in MODERN, (
    "Legacy hard-coded raid whitelist still restricts Group Composer"
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


# Routine Playerbots status messages are deliberately silent. Actual social personality belongs
# to the chatter layer, not one private hello/goodbye/item receipt per bot.
assert "Routine group joins stay quiet" in QUIET_BOT_PATCH
assert "Routine bot logout is intentionally silent" in QUIET_BOT_PATCH
assert "Leaving a group is state, not conversation" in QUIET_BOT_PATCH
assert "Routine item usage (poisons, stones, oils, consumables) is not chat-worthy" in QUIET_BOT_PATCH
assert "-    botAI->TellMasterNoFacing(useText);" in QUIET_BOT_PATCH
assert "+    (void)item;" in QUIET_BOT_PATCH and "+    (void)action;" in QUIET_BOT_PATCH
assert "-                    botAI->TellMaster(PlayerbotTextMgr::instance().GetBotTextOrDefault(" in QUIET_BOT_PATCH

# WotLK raid-ready means mandatory endgame access/story gates are already complete. Existing boosted
# characters must be repaired on login rather than requiring a new boost or manual quest chain.
assert "bool EnsureRaidReadyAccess(Player* player, AdventureStartProfile profile);" in ADVENTURE_START_CONTROL_H
for quest_id in (24510, 24499, 24683, 24498, 24710, 24711, 24506, 24511, 24682, 24507, 24712, 24713):
    assert str(quest_id) in ADVENTURE_START_CONTROL, f"Frozen Halls raid-ready access quest {quest_id} is missing"
assert "player->SetRewardedQuest(questId);" in ADVENTURE_START_CONTROL
assert "EnsureRaidReadyAccess(player, profile);" in ADVENTURE_START_CONTROL
assert "bool CompleteWotlkExpansionAccess(Player* player);" in ADVENTURE_START_CONTROL_H
complete_wotlk = section(ADVENTURE_START_CONTROL, "bool CompleteWotlkExpansionAccess(", "bool ApplyProfile(")
assert "ForceUpdateProgressionState(player, PROGRESSION_WOTLK_TIER_5)" in complete_wotlk
assert "BATTLE_UNDERCITY_ALLIANCE" in complete_wotlk and "BATTLE_UNDERCITY_HORDE" in complete_wotlk
assert "EnsureRaidReadyAccess(player, AdventureStartProfile::WotlkRaidReady)" in complete_wotlk
assert "13188u" in complete_wotlk and "13189u" in complete_wotlk
login_start = section(ADVENTURE_START, "void OnPlayerLogin", "void OnPlayerLearnTalents")
assert "state.starterProfile" in login_start and "EnsureRaidReadyAccess" in login_start
assert "player->SaveToDB(false, false);" in login_start, "Existing raid-ready access repair is not persisted"

# V4 selected-activity travel. A named dungeon/raid is entered only after the exact reviewed roster
# is complete and subgroup application succeeds. Runtime coordinates come from AzerothCore's
# canonical map entrance trigger; Random Dungeon remains queue-selected and is never guessed here.
travel = section(SERVER, "bool TeleportCompletedPlan(", "bool ValidateAssemblySnapshot(")
assert "sObjectMgr->GetMapEntranceTrigger(mapId)" in travel, "Selected activity travel must use canonical instance entrance data"
assert "sMapMgr->PlayerCannotEnter(mapId, player)" in travel, "Every member must pass authoritative instance-entry preflight"
assert "player->IsInCombat()" in travel and "player->IsBeingTeleported()" in travel, "Travel lost combat/teleport safety guards"
assert "group->GetLeader()" in travel and "GET_PLAYERBOT_AI(travelLeader)" in travel, (
    "Automatic travel must resolve a live real group leader instead of treating a Composer assistant as authority"
)
assert "TitanRune::SaveSelectedMode(travelLeader, titanMode)" in travel, (
    "Named Titan Rune travel must persist the reviewed protocol on the actual group leader"
)
assert "if (!teleport(travelLeader))" in travel and "player == travelLeader" in travel, (
    "Selected activity travel must require the authoritative group leader to teleport successfully before bots"
)
assert "return player->TeleportTo(destination->target_mapId" in travel, (
    "Automatic travel is ignoring Player::TeleportTo failure again"
)
assert travel.index("if (!teleport(travelLeader))") < travel.index("for (Player* player : travelers)", travel.index("if (!teleport(travelLeader))")), (
    "Bots may not teleport before the real group leader succeeds"
)
enter_reason = section(SERVER, "char const* EnterStateReason", "bool ResolveTitanTravelMode")
assert "CANNOT_ENTER_UNSPECIFIED_REASON" in enter_reason and "access requirement" in enter_reason, (
    "Quest/item/script access failures regressed to an opaque instance-entry error"
)
assert 'plan.config.activity == "random"' in travel, "Random Dungeon must remain destination-less until Dungeon Finder selects it"
for map_id in (533, 615, 616, 603, 649, 249, 624, 631, 724, 532, 568, 565, 544, 548, 550, 534, 564, 580, 309, 509, 409, 469, 531):
    assert str(map_id) in ADVENTURE_CATALOG, f"Raid map {map_id} disappeared from authoritative AdventureCatalog"
world_update = section(SERVER, "class GroupComposerWorld", "ChatCommandTable GroupComposerCommand::GetCommands")
assert "bool travelPending = false;" in TYPES and "uint8 travelAttempts = 0;" in TYPES, (
    "Plan lost delayed post-assembly instance entry state"
)
assert "bool assembled = false;" in TYPES, "Plan lost explicit post-assembly state"
assert "plan.assembled = true;" in world_update, "Successful subgroup application must publish an assembled state"
schedule_pos = world_update.index("ApplyArrangement(master, plan, arrangementError)")
assembled_pos = world_update.index("plan.assembled = true;", schedule_pos)
assert schedule_pos < assembled_pos, "Assembled state may only publish after subgroup layout is committed"
assert 'SendProgress(master, "ASSEMBLED"' in world_update
assert 'plan.travelPending = true;' not in world_update[world_update.index("ApplyArrangement(master, plan, arrangementError)"):], (
    "Assembly must never auto-teleport; travel is an explicit second action"
)
teleport_handler = section(SERVER, "bool GroupComposerCommand::HandleTeleport(", "bool GroupComposerCommand::HandleQueue")
assert "plan.travelPending = true;" in teleport_handler, "Explicit Teleport command no longer schedules travel"
assert "ValidateAssemblySnapshot(master, plan, validationError)" in teleport_handler
assert 'SendProgress(master, "TRAVEL"' in teleport_handler
travel_loop = section(world_update, "if (plan.travelPending)", "if (!plan.assembling) continue;")
assert "plan.travelElapsed < 450" in travel_loop
assert "Perform exactly one delayed" in travel_loop, "Explicit teleport must never retry access failures automatically"
assert "plan.travelPending = false;" in travel_loop
assert "TeleportCompletedPlan(master, plan, travelDetail, travelError)" in travel_loop
assert "plan.travelAttempts >= 8" not in travel_loop, "Legacy eight-attempt teleport spam loop returned"
assert 'SendProtocol(master, "STATUS", travelError);' in travel_loop
assert 'SendProtocol(master, "ERROR", travelError);' not in travel_loop
assert 'SendProgress(master, "ASSEMBLED"' in travel_loop
assert 'GC.pendingCommand == "teleport"' in CORE
assert 'function GC:TeleportToInstance()' in CORE
assert 'if (phase === "ASSEMBLED") return "Group assembled";' in MODEL
assert 'if (phase === "TRAVEL") return "Teleporting to instance";' in MODEL
assert 'Teleport to Instance' in MODERN and 'Teleport to instance?' in MODERN
assert 'press Teleport to Instance again' in travel
assert 'Teleport after assembly' in MODERN and 'Dungeon Finder chooses destination' in MODERN

# Frozen Halls access is quest-gated in AzerothCore. Composer-owned bots receive the same narrow
# bootstrap as Admin Panel's WotLK raid-ready action; real players get an actionable blocker.
assert 'FrozenHallsAccessRequirement' in SERVER
assert '24499u' in SERVER and '24511u' in SERVER and '24710u' in SERVER and '24712u' in SERVER
assert 'AdventureStartControl::EnsureRaidReadyAccess(bot, AdventureStartProfile::WotlkRaidReady)' in SERVER
assert 'Make THIS char WotLK Raid Ready' in SERVER
assert 'EnsureRaidReadyAccess(player, profile);' in ADVENTURE_START_CONTROL

# Activity visibility and execution use the same authoritative server-side access contract.
assert "uint8 RequiredProgressionFor(Config const& config)" in SERVER
assert '"forge_souls"' in ADVENTURE_CATALOG and "AdventureEra::Wotlk" in ADVENTURE_CATALOG
assert '"zulaman"' in ADVENTURE_CATALOG and "RequiredZulAmanProgression" in SERVER
assert '#include "IndividualProgression.h"' not in SERVER, (
    "GroupComposerCommand must not include IndividualProgression.h beside PlayerbotAI.h; both define legacy GENERAL"
)
assert "sIndividualProgression->" not in SERVER, (
    "GroupComposerCommand must use AdventureStartControl progression bridge instead of direct IP globals"
)
assert "bool HasPassedProgression(Player* player, uint8 progression);" in ADVENTURE_START_CONTROL_H
assert "sIndividualProgression->hasPassedProgression" in ADVENTURE_START_CONTROL
assert "bool ActivityEligible(Player* player, Config const& config, std::string& reason)" in SERVER
assert "AdventureStartControl::HasPassedProgression" in SERVER
assert "Difficulty const difficulty = ActivityDifficulty(config);" in SERVER
assert "player->Satisfy(sObjectMgr->GetAccessRequirement(mapId, difficulty), mapId, false)" in SERVER
assert 'SendActivityEligibility' in SERVER and '"[GC]|ACTIVITY|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}"' in SERVER
assert '"Selected activity is locked: " + eligibilityReason' in SERVER
assert '"Selected dungeon is locked: " + eligibilityReason' in SERVER
assert "ActivityEligible(player, plan.config, eligibilityReason)" in travel
assert "EnsureComposerInstanceAccess(master, bot, planItr->second.config)" in SERVER
assert 'function GC:RequestActivities' in CORE and 'kind == "ACTIVITY"' in CORE and 'kind == "ACTIVITYDONE"' in CORE
assert 'activityEligibility' in MODEL and 'selectedActivityEligibility' in MODEL
assert '"LOCKED"' in ACTIVITY_BROWSER and 'card.button.setEnabled(true)' in ACTIVITY_BROWSER
assert 'Model.requestActivities("RAID", "normal"' in TEMPLATE_BROWSER
assert '"Selected activity is locked.' in MODERN

# V4 sends an explicit local-player marker with each roster member. Human no longer implies YOU,
# which matters as soon as a real friend is part of the reviewed raid.
send_plan = section(SERVER, "void SendPlan(", "bool RaidSupports(")
assert "viewer && member.guid == viewer->GetGUID()" in send_plan, "Roster protocol lost the local-player marker"
assert 'isPlayer = fields[13] == "1"' in CORE, "Client no longer parses the local-player roster marker"
assert 'member.isPlayer ? "YOU  ·  " : (member.pinned ? "PINNED  ·  " : "")' in MODERN, (
    "Raid preview lost explicit local-player/pinned identity without conflating every human with YOU"
)

# Runtime-load and visual-density contracts for the typed modern dashboard.
assert 'Group Composer WoW runtime smoke test passed' in WOW_RUNTIME_SMOKE, (
    "Modern dashboard lost its mocked 3.3.5a runtime-load regression test"
)
assert "statusRoleChips" in MODERN and "Model.getSpecIcon" in MODERN, (
    "Modern dashboard lost the compact role summary or class/spec icon presentation"
)
assert "more human anchor" in MODERN, (
    "Main dashboard no longer explains when additional real-player anchors are hidden from the compact strip"
)
assert 'getClassesForRole(currentRole)' in SELECTOR and 'getSpecsForRole(currentClass, currentRole)' in SELECTOR, (
    "Class/spec selector no longer filters both stages by the selected role"
)


# Activity eligibility is authoritative and precedes guild preference / assembly.
assert "uint8 requiredLevel = 1;" in TYPES, "Config lost server-derived activity level floor"
assert "uint8 botTargetLevel = 1;" in TYPES and "uint8 maxBotLevel = 1;" in TYPES, (
    "Config lost the server-derived peer-level anti-boost policy"
)
assert "uint8 level = 1;" in TYPES, "Candidate/member level snapshots disappeared"
assert "uint8 RequiredActivityLevel(Player* master, Config const& config)" in SERVER
assert "GetLFGDungeon(mapId, difficulty)" in SERVER, "Named dungeon levels must come from Blizzard LFGDungeons.dbc data"
assert "config.requiredLevel = RequiredActivityLevel(master, config);" in SERVER
assert "ApplyBotLevelPolicy(master, config);" in SERVER
assert "uint16(ownerLevelInEra) + 2" in SERVER and "AdventureCatalog::EraLevelCap(activityEra)" in SERVER
assert "bool disposableCapacity" in PLANNER and "underLevel" in PLANNER and "belowPeerTarget" in PLANNER and "abovePeerBand" in PLANNER and "underGear" in PLANNER, (
    "Online RNDbot fallback lost elastic activity provisioning"
)
assert "SELECT guid, name, class, level FROM characters" in PLANNER, "Offline reserve selection lost persisted level metadata"
assert "std::max<uint8>(storedLevel, config.botTargetLevel)" in PLANNER and "storedLevel > config.maxBotLevel" in PLANNER, (
    "Low-level offline reserve bodies must project to the selected activity level"
)
assert "bot->GiveLevel(targetLevel)" in SERVER, "Managed fallback no longer promotes low-level bodies before preparation"
assert "PreparedMemberReady" in SERVER and "bot->GetLevel() < plan.config.requiredLevel" in SERVER, (
    "Prepared rosters must revalidate level/spec/gear after provisioning"
)
assert "minimumItemLevel" in GEAR_H and "std::max<int32>" in GEAR_CPP, (
    "Managed fallback gear provisioning lost the configured item-level floor"
)
assert "below the selected activity's required level" in SERVER, "Assembly no longer revalidates selected bot levels"
assert "activityEligibilityText" in MODEL and "Minimum item level" in MODERN
assert "const exactScroll = ScrollUI.createScrollList" in MODERN, "Specific Builds regressed to fixed clipping columns"
assert "const exactScroll = ScrollUI.createScrollList(exactView, 936, 418);" in MODERN
assert "exactScroll.setContentHeight(Math.max(418, cursor));" in MODERN
assert "let contentHeight = height;" in SCROLL_LIST and "function maxOffset()" in SCROLL_LIST
assert "GetVerticalScrollRange" not in SCROLL_LIST, "3.3.5 ScrollFrame range must not drive Composer scrolling"
assert "bindWheel(target: WoWFrame)" in SCROLL_LIST and "exactScroll.bindWheel" in MODERN
assert "bindWheel(button.frame)" in CHOICE_SELECT, "Dropdown rows can swallow mouse-wheel input again"
assert 'detail?: string;' in CHOICE_SELECT, "Rich activity selector metadata disappeared"

# Human anchors obey only the selected activity's level gate. Composer's configurable item-level
# floor is strictly a bot eligibility/provisioning rule and must never reject or rewrite a real player.
human_build = section(PLANNER, "bool AddHumanMembers(", "void AddCandidate(")
assert "GetLevel() < config.requiredLevel" in human_build and "cache->Level < config.requiredLevel" in human_build, (
    "Live/offline human anchors lost the selected-activity level requirement"
)
assert "minimumItemLevel" not in human_build, "Composer item-level floor leaked into human roster selection"

assembly_snapshot = section(SERVER, "bool ValidateAssemblySnapshot(", "void InviteHuman(")
human_snapshot = section(assembly_snapshot, "if (member.human)", "if (!live)")
assert human_snapshot.count("GetLevel() < plan.config.requiredLevel") >= 2, (
    "Assembly must revalidate the composing player and additional real humans against the activity level floor"
)
assert "minimumItemLevel" not in human_snapshot, "Assembly item-level validation must never apply to real humans"

assert "SyncManagedBot(master, bot, member.role, member.spec, plan.config.botTargetLevel, 0, 0, false);" in SERVER, (
    "Persistent guild spec retask lost the expanded managed-sync contract"
)


# Modern dashboard redesign contracts.
# These deliberately enforce the new one-border / content-first system instead of the old
# "premium = more chrome" implementation that produced the noisy live screenshots.
assert 'frame.SetSize(1520, 900)' in MODERN, "Modern shell lost the redesigned workspace dimensions"
assert 'center.SetSize(970, 800)' in MODERN, "Composition workspace lost its reclaimed footer space"
assert 'Adjust the highlighted requirement, then Build & Prepare again.' in MODERN, (
    "Status rail regressed to repeating backend errors instead of giving an actionable next step"
)
assert '"Choose a class"' in SELECTOR and '"Choose a specialization"' in SELECTOR
assert "columns = Math.min(5" in SELECTOR and "startX = Math.floor" in SELECTOR, (
    "Build selector lost its responsive centered class-card grid"
)
assert 'const modal = createModal(parent, 1040, 680);' in SELECTOR
assert 'Any valid spec' in SELECTOR and 'Use this build' in SELECTOR
assert "specSummary" in SELECTOR and 'labels.join("  ·  ")' in SELECTOR
assert "modal.setHeaderRole(currentRole)" in SELECTOR
assert "classStepBadge" in SELECTOR and "specStepBadge" in SELECTOR
assert '"Select a class above to unlock specializations."' in SELECTOR
assert "const classRows = Math.max(1, Math.ceil(validClasses.length / columns));" in SELECTOR
assert "const classHeight = classRows > 1 ? 300 : 186;" in SELECTOR
assert "const specHeight = currentClass === undefined ? 68 : 176;" in SELECTOR
assert "modal.frame.SetHeight(classHeight + specHeight + 222);" in SELECTOR, (
    "Build selector lost content-sensitive Tank/Healer/DPS sizing"
)

# One-border visual primitive contracts.
assert "selectedWash" in BUTTON and "const outline = createOutline" in BUTTON
assert "innerFrame" not in BUTTON and "innerOutline" not in BUTTON and "activeTop" not in BUTTON
assert "topTint" not in BUTTON, "Button refactor regressed to stacked decorative layers"
assert "createChrome(" not in MODAL, "Modal primitive must not stack a second chrome outline over its panel border"
assert "createPanel(parent, theme.colors.background, theme.colors.chrome)" in MODAL, (
    "Modal must keep one restrained premium shell border"
)
assert "headerDivider" in MODAL and "setHeaderIcon(path?: string)" in MODAL
assert "createChrome(popup.frame" not in CHOICE_SELECT, "Dropdown popup must stay single-border"
assert 'height: rowHeight - 2, accent: theme.colors.primary, flat: true' in CHOICE_SELECT, (
    "Dropdown rows regressed to individually boxed buttons"
)
assert "track.SetWidth(2)" in SCROLL_LIST and "thumb.SetWidth(5)" in SCROLL_LIST
assert "GetVerticalScrollRange" not in SCROLL_LIST, "Scroll behavior must remain deterministic"
assert "UI-CheckBox-Check" in TOGGLE and "createOutline" in TOGGLE
assert "const center = createPanel" in STEPPER and "minus.setEnabled" in STEPPER and "plus.setEnabled" in STEPPER
assert "ROLE_ICON_TEXTURES" in NATIVE and "UI-LFG-ICON-PORTRAITROLES" not in NATIVE, (
    "Large role badges regressed to the low-resolution LFG atlas"
)
assert "UI-DialogBox-Gold-Corner" not in NATIVE, (
    "Child/shell chrome regressed to duplicated Blizzard gold corner textures"
)
assert "topSheen" not in NATIVE and "bottomShade" not in NATIVE, (
    "Common panels must stay surface + one boundary; decorative sheen/shade belongs to intentional screens"
)

# Specific Builds must reconcile pooled frames explicitly because WoW does not clip child frames
# to a shrunken parent. This is the regression contract for the Protection Paladin ×2 ghost row.
assert "rowsByKey" in MODERN and "rowKeys" in MODERN
assert 'const rowKey = role + ":" + String(build.classId) + ":" + String(build.specId);' in MODERN, (
    "Exact build frame identity must include role/class/spec"
)
assert "pooled.panel.frame.Hide()" in MODERN and "pooled.panel.frame.ClearAllPoints()" in MODERN
assert "widgets.panel.frame.Hide()" in MODERN and "widgets.panel.frame.ClearAllPoints()" in MODERN
assert 'widgets.count.SetText("×" + String(build.count))' in MODERN

# Major mockup surfaces remain icon-led and role-aware while decoration stays restrained.
assert "ACTIVITY_ICONS" in MODEL and "selectedActivityIcon" in MODEL
assert 'icon: ACTIVITY_ICONS[String(dungeon.id)]' in MODEL
assert 'icon: ACTIVITY_ICONS[String(raid.id)]' in MODEL
assert "triggerIcon = createFramedIcon" in CHOICE_SELECT and "item.icon" in CHOICE_SELECT
assert "OnEditFocusGained" in TEXT_INPUT and "focusGlow" in TEXT_INPUT
assert "classRoleSummary" in SELECTOR and '"Ranged DPS"' in SELECTOR and '"Melee DPS"' in SELECTOR
assert '"BUILD SUMMARY"' in SELECTOR and "summaryClassBadge" in SELECTOR and "summarySpecBadge" in SELECTOR
assert "summaryRoleBadge" in SELECTOR and '"COUNT"' in SELECTOR
assert "roleDescription" in MODERN and '"TOTAL RAID SIZE"' in MODERN
assert "quickStatusTitle" in MODERN and "quickStatusDetail" in MODERN
assert "humanBadge = Native.createFramedIcon" in MODERN
assert "classBadge = Native.createFramedIcon" in MODERN and "specBadge = Native.createFramedIcon" in MODERN
assert '"Human anchor"' in MODERN and "widgets.humanAnchor.frame.Show()" in MODERN
assert "resetRoles.frame.SetPoint" in MODERN and 'resetRoles.frame.SetPoint("TOPRIGHT", raidView' in MODERN
assert "backendGlow" in MODERN and "phaseGlow" in MODERN and "coverageGlyph" in MODERN
assert "sidebarDivider" in MODERN, "Sidebar hierarchy lost the Compose/Tools divider"
assert "coverageDefs" in MODERN and '"Interrupt"' in MODERN and '"Battle Res"' in MODERN, (
    "Status rail regressed from bounded utility chips to overlapping free-form coverage"
)
assert "const column = i % 2;" in MODERN and "chip.frame.SetSize(122, 24)" in MODERN, (
    "Utility coverage regressed to narrow clipping-prone columns"
)
assert "backendText.SetWidth(160)" in MODERN and '"RIGHT", header.frame, "RIGHT", -331' in MODERN, (
    "Backend connection label is no longer bounded away from the Close button"
)
assert "const nextColor = phase === \"ERROR\"" in MODERN and '"ACTION REQUIRED"' in MODERN, (
    "Next Step card lost semantic phase coloring"
)
assert "classIcons" not in MODERN, "Status rail brought back the overlapping class-icon strip"
assert 'TemplateBrowserUI.createTemplateBrowser(frame)' in MODERN
assert 'type TemplateTab = "WotLK" | "TBC" | "Vanilla" | "CUSTOM";' in TEMPLATE_BROWSER
assert 'Math.ceil(names.length / 2) * 92' in TEMPLATE_BROWSER, (
    "Templates must stay grouped by expansion and use a compact two-column browser"
)
assert 'const pinPane = CreateFrame("Frame", undefined, peopleModal.content);' in MODERN
assert 'const humanScroll = ScrollUI.createScrollList(peopleModal.content, 442, 430);' in MODERN
assert 'const pinScroll = ScrollUI.createScrollList(pinPane, 442, 270);' in MODERN, (
    "Humans & Pins lost the compact two-pane layout"
)
assert '"CANDIDATE POOL"' in MODERN and '"COMPOSITION"' in MODERN and '"ACTIVITY"' in MODERN and '"ELIGIBILITY"' in MODERN, (
    "Options regressed from grouped compact rows to undifferentiated option cards"
)
assert "const empty = Native.createText" in TEMPLATE_BROWSER and '"My Templates"' in TEMPLATE_BROWSER, (
    "Template browser lost its grouped empty state or custom-template tab"
)
assert 'Dungeon Party Templates' in TEMPLATE_BROWSER and 'SAVE CURRENT PARTY' in TEMPLATE_BROWSER
assert 'function P.ListCustom(mode)' in profiles_text and 'p.mode ~= "RAID"' not in profiles_text
assert "humanEmpty" in MODERN and "pinEmpty" in MODERN, "People browser lost explicit empty states"
assert "BUILT-IN" in TEMPLATE_BROWSER and "CUSTOM" in TEMPLATE_BROWSER, "Template cards lost their visual category tags"
assert "_roleBadge" in MODERN and "Preferred companion" in MODERN
assert "gearIcon = Native.createFramedIcon" in MODERN
assert '" TANK"' in MODERN and '" HEALER"' in MODERN and '" DPS"' in MODERN, (
    "Roster status chips regressed from full role labels"
)
assert "iconBadge = Native.createFramedIcon" in MODERN, "Prepared roster lost framed class icons"
assert "groupCount" in MODERN and '"SUBGROUP"' in MODERN and "headerAccent" in MODERN, (
    "Prepared roster lost its subgroup review hierarchy"
)
assert "rowWidgets.roleIcon" in MODERN and '"PINNED  ·  "' in MODERN, (
    "Prepared roster lost role/identity cues"
)
assert '"Lv " + String(member.level ?? "?") + "  ·  "' in MODERN, (
    "Prepared roster must keep level + specialization as its secondary identity line"
)
assert "const rowWidgets = widgets.rows[r + 1];" in MODERN, (
    "Prepared roster row pool must preserve the TypeScriptToLua 1-based runtime boundary"
)
assert 'activity.frame.SetHeight(124)' in MODERN
assert 'humanPanel.frame.SetPoint("TOPLEFT", center, "TOPLEFT", 0, -136)' in MODERN
assert 'composition.frame.SetPoint("TOPLEFT", center, "TOPLEFT", 0, -226)' in MODERN
assert "activityTop" in MODERN and "compositionTop" in MODERN, "Main content lost restrained section accents"
assert '"Close   X"' in MODERN


# Human anchor presentation carries authoritative level for the premium party strip.
assert 'uint8 level = 1;' in SERVER
assert 'level = live->GetLevel();' in SERVER and 'level = cache->Level;' in SERVER
assert '"[GC]|ANCHOR|{}|{}|{}|{}|{}|{}|{}|{}"' in SERVER
assert 'level = ParseNumber(fields[8], 1)' in CORE
assert 'level?: number;' in MODEL
assert '"Level " + String(primary.level ?? "?")' in MODERN


# Refined shell / role-art parity.
# Role badges use full-size icon textures because the Wrath LFG portrait-role atlas looked visibly
# pixelated at the dimensions used by the redesigned cards.
assert "ROLE_ICON_TEXTURES" in NATIVE
assert "UI-LFG-ICON-PORTRAITROLES" not in NATIVE
assert "setRoleIcon" in NATIVE and "createFramedRoleIcon" in NATIVE
assert "setHeaderRole(role?: string)" in MODAL
assert "modal.setHeaderRole(currentRole)" in SELECTOR and "summaryRoleBadge = createFramedRoleIcon" in SELECTOR
assert MODERN.count("createFramedRoleIcon") >= 4
assert "Native.setRoleIcon(widgets.roleIcon, slot.role)" in MODERN

# Chrome is reserved for major shells and uses restrained line/corner geometry. Child controls,
# dropdowns and buttons must not get nested ornament textures.
assert "ornate = false" in NATIVE and "if (!ornate) return" in NATIVE
assert "createChrome(" not in MODAL, "Modal chrome must remain single-boundary"
assert "Native.createChrome(frame, theme.colors.chrome, true)" in MODERN
assert "rootOutline" not in MODERN and "Native.createChrome(mark.frame" not in MODERN, (
    "Main shell or GC mark regressed to duplicate nested outlines"
)
assert "UI-DialogBox-Gold-Corner" not in NATIVE

# Status rail semantics match the target without claiming assembly.
assert 'return "Ready to configure";' in MODEL
assert 'const composed = Model.config().mode === "RAID" ? Model.roleTargetTotal() : humanCount;' in MODERN
assert 'phase === "IDLE" && target > 0' in MODERN
assert "const footer =" not in MODERN and "footerText" not in MODERN, (
    "Modern shell regressed to the duplicate bottom debug-status footer"
)
assert 'let statusNotice = "";' in MODERN and 'statusNotice = String(text ?? "");' in MODERN, (
    "Transient server status must stay visible after removing the debug footer"
)
assert 'Add specific builds or keep Auto to prepare your raid.' in MODERN
assert '"Level " + String(slot.anchor.level ?? "?")' in MODERN

# Build selector keeps the desired class order while using a responsive centered layout.
assert '"DEATHKNIGHT", "WARRIOR", "PALADIN", "HUNTER", "ROGUE"' in SELECTOR
assert '"SHAMAN", "MAGE", "WARLOCK", "DRUID", "PRIEST"' in SELECTOR
assert "selectorClassesForRole" in SELECTOR
assert "createRadioMarker" in SELECTOR and "setRadioSelected" in SELECTOR
assert 'marker.SetTexture("Interface\\\\Buttons\\\\UI-CheckBox-Check")' in SELECTOR
assert '"Choose a class"' in SELECTOR and '"Choose a specialization"' in SELECTOR
assert "columns = Math.min(5" in SELECTOR
assert "cardsWidth = totalCards * cardWidth" in SELECTOR
assert '"Any valid spec"' in SELECTOR
assert '"Reserve only the class/spec you care about. Every unreserved slot stays Auto."' in SELECTOR

# Compact target-style count/item-level steppers are horizontal and bounded.
assert 'frame.SetSize(118, 36)' in STEPPER
assert 'minus.frame.SetPoint("LEFT"' in STEPPER and 'plus.frame.SetPoint("LEFT", center.frame, "RIGHT"' in STEPPER
assert 'text: "-"' in STEPPER and 'text: "+"' in STEPPER

# Main workspace keeps useful density while Specific Builds uses content-height keyed sections.
assert 'row.frame.SetHeight(64)' in MODERN and 'i * 70' in MODERN
assert 'createFramedRoleIcon(row.frame, "DPS", 38' in MODERN
assert 'panel.frame.SetSize(870, 52)' in MODERN and '58 + i * 58' in MODERN
assert 'rows.length === 0 ? 88 : 66 + rows.length * 58' in MODERN
assert 'phaseCard.frame.SetHeight(92)' in MODERN
assert 'text: "Build & Prepare", width: 270, height: 52' in MODERN
assert 'text: "Use Auto", width: 78, height: 34' in MODERN
assert "if (exact !== undefined) widgets.auto.frame.Show();" in MODERN and "else widgets.auto.frame.Hide();" in MODERN, (
    "Dungeon Auto slots must not show a disabled redundant Auto action"
)

# Raid tabs are navigation, not competing primary actions. They share the Composer-blue
# flat selected treatment and sit over one restrained divider.
assert 'Quick Composition", width: 164, height: 36, accent: theme.colors.primary, flat: true' in MODERN
assert 'Specific Builds", width: 150, height: 36, accent: theme.colors.primary, flat: true' in MODERN
assert 'Prepared Roster", width: 150, height: 36, accent: theme.colors.primary, flat: true' in MODERN
assert "tabUnderline" in MODERN


# WoW 3.3.5 callback ABI regression guards.
TYPES = (ROOT / "client-ui/src/types/wow-335a.d.ts").read_text(encoding="utf-8")
UPDATE_SH = (ROOT / "update.sh").read_text(encoding="utf-8")
SYNC_CLIENT = (ROOT / "sync-group-composer-client.sh").read_text(encoding="utf-8")
assert "(this: void, frame: WoWFrame" in TYPES, "SetScript callback type must not inject Lua self"
assert 'frame.SetScript("OnDragStart", () => frame.StartMoving())' in MODERN
assert 'frame.SetScript("OnDragStop", () => frame.StopMovingOrSizing())' in MODERN
assert "function wheel(this: void" in CHOICE_SELECT
assert "function wheel(this: void" in SCROLL_LIST
assert "sync-group-composer-client.sh" in UPDATE_SH
assert "GroupComposerModernUI.lua" in SYNC_CLIENT and "Interface/AddOns/GroupComposer" in SYNC_CLIENT
assert "0.14.0" in TOC and "0.14.0" in DATA

# Long activity lists use a dedicated filtered two-column browser instead of the compact ChoiceSelect.
assert 'ActivityBrowserUI.createActivityBrowser(frame)' in MODERN
assert 'ProgressionPageUI.createProgressionPage(frame)' in MODERN
assert 'RecommendationsPageUI.createRecommendationsPage(frame' in MODERN
assert 'JOURNEYRAID' in SERVER and 'RECOMMEND' in SERVER
assert '"You: Cleared ✓"' in PROGRESSION_PAGE and '"Guild: Cleared ✓"' in PROGRESSION_PAGE
assert '"Recommended Activities"' in RECOMMENDATIONS_PAGE
assert '"Vanilla"' in ACTIVITY_BROWSER and '"TBC"' in ACTIVITY_BROWSER and '"WotLK"' in ACTIVITY_BROWSER
assert 'difficultyDetail' in ACTIVITY_BROWSER and 'Titan Rune' in ACTIVITY_BROWSER
assert '"FAVORITES"' in ACTIVITY_BROWSER and '"RECENT"' in ACTIVITY_BROWSER
assert 'toggleFavorite' in MODEL and 'recentActivityIds' in MODEL
assert 'function P.ToggleFavorite' in profiles_text and 'function P.MarkRecent' in profiles_text
assert 'P.MarkRecent(GC:GetConfig().mode, GC:GetConfig().activity)' in CORE
assert 'const column = i % 2;' in ACTIVITY_BROWSER and 'Math.ceil(items.length / 2) * 86' in ACTIVITY_BROWSER


# Post-assembly lifecycle and member rationale contracts.
assert "HandleLeaveInstance" in SERVER and "GetGoBackTrigger" in SERVER
assert "HandleDisband" in SERVER and "group->Disband()" in SERVER
assert "PlanMembershipComplete(master, plan)" in SERVER
assert "MemberSelectionReason" in SERVER and "MemberUtilitySummary" in SERVER
assert 'Sanitize(MemberSelectionReason(member, plan.config))' in SERVER
assert 'why = fields[15] or ""' in CORE
assert "function GC:LeaveInstance()" in CORE and "function GC:DisbandComposerGroup()" in CORE

assert "Group Actions" in MODERN and "Leave Instance Together" in GROUP_ACTIONS
assert "Rebuild / Repair Roster" in GROUP_ACTIONS and "Disband Composer Group" in GROUP_ACTIONS
assert "Why this bot?" in MEMBER_DETAILS and "click for why" in MODERN
assert "memberDetails.open" in MODERN and "member.why" in MEMBER_DETAILS


# Generated bundle must contain the latest lifecycle/rationale surfaces before a checkpoint can ship.
assert "Group Actions" in GENERATED_UI
assert "Leave Instance Together" in GENERATED_UI
assert "Rebuild / Repair Roster" in GENERATED_UI
assert "Disband Composer Group" in GENERATED_UI
assert "Why this bot?" in GENERATED_UI
assert "click for why" in GENERATED_UI

# Random Dungeon handoff must follow the live realm era, never the character's current level.
assert "RANDOM_DUNGEON_NORMAL_CLASSIC = 258u" in SERVER
assert "switch (AdventureCatalog::CurrentRealmEra())" in SERVER
assert "master->GetLevel() >= 71" not in SERVER


# Progression history must be independent of economy/bounty settings.
assert "AdventureProgressionHistoryPlayerScript" in PROGRESSION_HISTORY
assert "IsRealPlayer(player)" in PROGRESSION_HISTORY
assert "mod_adventure_progression_event" in PROGRESSION_HISTORY
assert "mod_adventure_progression_history" in PROGRESSION_HISTORY
assert "PRIMARY KEY (`player_guid`, `map_id`, `instance_id`, `creature_entry`)" in PROGRESSION_HISTORY_SQL
assert "`activity_id` VARCHAR(64)" in PROGRESSION_HISTORY_SQL
assert "ActivityIdFor" in PROGRESSION_HISTORY and "AdventureCatalog::All()" in PROGRESSION_HISTORY
assert "activity_id = IF(activity_id = '', VALUES(activity_id), activity_id)" in PROGRESSION_HISTORY
assert "INFORMATION_SCHEMA" in PROGRESSION_ACTIVITY_ID_MIGRATION
assert "idx_activity_id_time" in PROGRESSION_ACTIVITY_ID_MIGRATION and "idx_activity_id" in PROGRESSION_ACTIVITY_ID_MIGRATION
assert "mod_adventure_progression_clear" in PROGRESSION_CLEAR_SNAPSHOT_SQL
assert "mod_adventure_progression_clear_member" in PROGRESSION_CLEAR_SNAPSHOT_SQL
assert "mod_adventure_progression_guild_clear" in PROGRESSION_CLEAR_SNAPSHOT_SQL
assert "ClearParticipants" in PROGRESSION_HISTORY and "RecordClearSnapshot" in PROGRESSION_HISTORY
assert "is_playerbot" in PROGRESSION_HISTORY and "GetInstanceId() != instanceId" in PROGRESSION_HISTORY
assert "mod_adventure_progression_guild_clear" in SERVER and "mod_adventure_progression_clear_member" in SERVER
assert "[Bot]" in SERVER
assert "activity_id = '{}' OR (activity_id = ''" in SERVER
assert "COUNT(DISTINCT instance_id)" in SERVER
assert "playerClearCount" in CORE and "guildClearCount" in CORE
assert "Cleared ×" in PROGRESSION_PAGE


# Activity catalog diagnostics validate the things that make Group Composer trustworthy.
assert "SendCatalogDiagnostics" in SERVER and "HandleCatalogDiagnostics" in SERVER
assert "sMapStore.LookupEntry" in SERVER and "GetMapEntranceTrigger" in SERVER
assert "GetCreatureTemplate(activity.finalBossEntry)" in SERVER
assert "CATDIAGDONE" in SERVER and "CATDIAGDONE" in CORE
assert "Activity Diagnostics" in ACTIVITY_DIAGNOSTICS and "Run Validation" in ACTIVITY_DIAGNOSTICS
assert "Needs Review" in ACTIVITY_DIAGNOSTICS and "Passed" in ACTIVITY_DIAGNOSTICS
assert "ActivityDiagnosticsUI.createActivityDiagnosticsPage" in MODERN


# Raid journey must understand active AzerothCore instance binds.
assert '#include "InstanceSaveMgr.h"' in SERVER
assert "CurrentRaidLockout" in SERVER and "PlayerGetBoundInstance" in SERVER
assert "GetCompletedEncounterMask" in SERVER
assert "Resume your active raid lockout" in SERVER
assert "lockoutActive" in CORE and "lockoutEncounters" in CORE
assert "ACTIVE LOCKOUT #" in PROGRESSION_PAGE


# Shipping checkpoint: generated Lua must include the current journey/diagnostics surfaces.
assert "Activity Diagnostics" in GENERATED_UI
assert "ACTIVE LOCKOUT #" in GENERATED_UI
assert "Cleared ×" in GENERATED_UI


# Recommendations should answer both "what can we do?" and "can Composer actually form it now?"
assert "EvaluateRecommendationCapacity" in SERVER
assert "Planner::Build(master, config, preview, error)" in SERVER
assert "guildCandidates = preview.guildCandidates" in SERVER
assert '"Next unlock: " + reason' in SERVER
assert '"[GC]|RECOMMEND|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}"' in SERVER
assert "guildCandidates = ParseNumber(fields[11], 0)" in CORE
assert "GROUP READY" in RECOMMENDATIONS_PAGE and "ROSTER NEEDS WORK" in RECOMMENDATIONS_PAGE
assert "NEXT UNLOCK" in RECOMMENDATIONS_PAGE


# Generated UI must include capacity-aware recommendations before this checkpoint can ship.
assert "GROUP READY" in GENERATED_UI
assert "ROSTER NEEDS WORK" in GENERATED_UI
assert "NEXT UNLOCK" in GENERATED_UI
assert "human(s)" in GENERATED_UI and "guild bot(s)" in GENERATED_UI


# Progression history should preserve who was present for the first recorded guild clear.
assert "guildFirstRoster" in SERVER and "GROUP_CONCAT(c.name" in SERVER
assert "GROUP BY instance_id ORDER BY MIN(killed_at) ASC LIMIT 1" in SERVER
assert "dedicatedGuildHistory" in SERVER
assert "ORDER BY killed_at ASC, instance_id ASC LIMIT 1" in SERVER
assert "GROUP_CONCAT(CONCAT(member_name" in SERVER
assert "guildFirstRoster = fields[19] or" in CORE
assert "playerFirstFormat = fields[20] or" in CORE and "guildFirstGroupSize = ParseNumber(fields[23], 0)" in CORE
assert "guildFirstRoster: string" in MODEL
assert "playerFirstFormat: string" in MODEL and "guildFirstGroupSize: number" in MODEL
assert "RecordedRaidFormat" in SERVER and "personalFirstGroupSize" in SERVER and "guildFirstGroupSize" in SERVER
assert "recorded participant(s)" in RAID_HISTORY_MODAL
assert "FIRST RECORDED GUILD-CLEAR ROSTER" in RAID_HISTORY_MODAL
assert "RECENT GUILD CLEARS" in RAID_HISTORY_MODAL and "guildRecentClears" in RAID_HISTORY_MODAL
assert "JOURNEYRAIDRECENT" in SERVER and "JOURNEYRAIDRECENT" in CORE
assert "click for history" in PROGRESSION_PAGE


# Generated bundle must include the latest progression-history drilldown.
assert "Raid History" in GENERATED_UI
assert "FIRST RECORDED GUILD-CLEAR ROSTER" in GENERATED_UI
assert "recorded participant(s)" in GENERATED_UI
assert "RECENT GUILD CLEARS" in GENERATED_UI
assert "View Unlocks" in GENERATED_UI
assert "click for history" in GENERATED_UI


# Locked activities expose a structured unlock guide with real server requirements.
assert "SendActivityRequirements" in SERVER and "HandleRequirements" in SERVER
assert "SendQuestChainDetails" in SERVER and "QuestTitle(questId)" in SERVER
assert '"[GC]|UNLOCKREQ|{}|{}|{}|{}"' in SERVER
assert "requirements->quests" in SERVER and "requirements->items" in SERVER and "requirements->achievements" in SERVER
assert "UNLOCKDONE" in SERVER and "UNLOCKDONE" in CORE
assert "UNLOCK_DETAILS_CHANGED" in CORE
assert "Unlock Requirements" in UNLOCK_REQUIREMENTS
assert "Exact unlock path" in UNLOCK_REQUIREMENTS
assert "unlockModal.open" in ACTIVITY_BROWSER
assert "NEXT STEP · " in SERVER and "Step " in SERVER and "detected prerequisite chain" in SERVER
assert "View Unlocks" in RECOMMENDATIONS_PAGE and "unlockModal.open" in RECOMMENDATIONS_PAGE


# Generated addon bundle must include the structured unlock guide.
assert "Unlock Requirements" in GENERATED_UI
assert "UNLOCK_DETAILS_CHANGED" in CORE
assert "Exact unlock path" in GENERATED_UI
assert "req.type" in (ROOT / "client-ui/src/components/UnlockRequirementsModal.ts").read_text(encoding="utf-8")


# Co-op access must be party-aware, not leader-only.
assert "PlayerActivityEligible" in SERVER and "PartyActivityEligible" in SERVER
assert "humanBlockers" in SERVER and '"PARTY"' in SERVER
assert "cannot enter:" in SERVER
assert "must be online so Group Composer can validate their activity access" in SERVER
assert "no longer satisfies the selected activity access requirements" in SERVER
assert "A real player in this composition is not ready for the selected activity" in SERVER
assert "PartyRaidLockout" in SERVER and "CompatibleRaidLockout" in SERVER
assert "PlayerGetBoundInstance" in SERVER
assert "conflicts with" in SERVER and "saved instance" in SERVER
assert '#include "RaidLeaderKnowledge.h"' in SERVER
assert "Encounter readiness:" in SERVER and "PLAYABLE/manual:" in SERVER and "NOT READY:" in SERVER
assert "RaidLeaderKnowledge::Encounters()" in SERVER and "RaidLeaderKnowledge::SupplementalEncounters()" in SERVER
assert "Human gear warning:" in SERVER and "Human gear advisory:" in SERVER
assert "AddPlanReadinessWarnings(plan);" in SERVER


# Recommendations must explain the real-human composition they are previewing.
assert "uint32 humans = 0;" in SERVER and "humanNames" in SERVER
assert "Anchored humans:" in SERVER
assert "humans = ParseNumber(fields[12], 0)" in CORE
assert "humanNames = fields[13] or \"\"" in CORE
assert "GROUP READY · " in RECOMMENDATIONS_PAGE and "human(s)" in RECOMMENDATIONS_PAGE


# Recommendations reuse Composer's own gear profile rather than inventing a separate ilvl model.
assert "recommendedFloor" in SERVER and "recommendedTarget" in SERVER and "gearReady" in SERVER
assert "Composer's recommended floor" in SERVER
assert "playerItemLevel = ParseNumber(fields[14], 0)" in CORE
assert "recommendedFloor = ParseNumber(fields[15], 0)" in CORE
assert "GEAR READY" in RECOMMENDATIONS_PAGE and "GEAR LOW" in RECOMMENDATIONS_PAGE


# Recommendations should prefer meaningful guild progression, actionable unlocks and gear-fit content.
assert "RecommendationGearAdjustment" in SERVER
assert "EligibleOnlineFriends" in SERVER
assert "character_social" in SERVER and "FindPlayerByLowGUID" in SERVER
assert "online friend(s) are eligible and free to join" in SERVER
assert "IsActionableUnlockReason" in SERVER
assert "Guild progression target:" in SERVER
assert "gear.target && ilvl < gear.target" in SERVER
assert "score += RecommendationGearAdjustment(master, activity)" in SERVER


# Runtime regression contracts discovered during the first in-game V4 validation pass.
assert '"[GC]|ACTIVITY|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}"' in SERVER, (
    "ACTIVITY protocol must have exactly eleven payload placeholders"
)
assert '"[GC]|ACTIVITY|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}"' not in SERVER, (
    "ACTIVITY protocol regressed to the 12-placeholder/11-argument runtime format error"
)
assert "ProgressionCompletionStage" not in SERVER, (
    "Progression stage must never masquerade as an actual recorded raid clear"
)
assert "bool const personalComplete = clears.personalCount > 0;" in SERVER, (
    "Journey clear state must come from the durable clear ledger"
)
assert "center.Hide();" in MODERN and "status.frame.Hide();" in MODERN
assert "center.Show();" in MODERN and "status.frame.Show();" in MODERN
assert '"★ Favorites"' not in ACTIVITY_BROWSER and '"☆"' not in ACTIVITY_BROWSER
assert 'card.favorite.setText("Fav")' in ACTIVITY_BROWSER
assert "card.button.setEnabled(true);" in ACTIVITY_BROWSER, (
    "Locked activities must remain clickable so their exact unlock requirements can open"
)
assert '"[GC]|COVERAGECOUNTS|{}|{}|{}|{}|{}|{}|{}"' in SERVER
assert '"[GC]|RAIDBUFF|{}|{}|{}|{}"' in SERVER
assert 'kind == "COVERAGECOUNTS"' in CORE and 'kind == "RAIDBUFF"' in CORE
assert "Utility Coverage Details" in UTILITY_COVERAGE
assert "Major raid buff families present:" in UTILITY_COVERAGE
assert "MISSING  " in UTILITY_COVERAGE and "PRESENT  " in UTILITY_COVERAGE


# Runtime validation pass: live-party anchoring, RDF cache refresh and layout regressions.
assert 'isBot ? 1 : 0' in SERVER and '"[GC]|ANCHOR|{}|{}|{}|{}|{}|{}|{}|{}"' in SERVER
assert 'if (IsBotGuid(guid)) return;' not in SERVER, (
    "Current Playerbots must remain visible to the Group Composer anchor snapshot"
)
assert 'function GC:ScanGroupMembers()' in CORE and 'isBot = fields[9] == "1"' in CORE
assert 'if not anchor.isBot then out[#out + 1] = anchor end' in CORE
assert 'export function groupMembers()' in MODEL and 'export function fixedRoleCounts()' in MODEL
assert 'const anchors = Model.groupMembers();' in MODERN
assert '"Current bot · locked"' in MODERN and 'already in your group' in MODERN
assert 'sLFGMgr->InitializeLockedDungeons(bot, bot->GetGroup());' in SERVER
assert 'sLFGMgr->InitializeLockedDungeons(player, group);' in SERVER
assert 'GetState(group->GetGUID()) != lfg::LFG_STATE_ROLECHECK' in SERVER
assert 'Queueing the assembled party through Blizzard Dungeon Finder' in SERVER
assert 'height: 108' in SELECTOR and 'specs.SetHeight(46)' in SELECTOR
assert 'panel.frame.SetSize(1228, 156)' in RECOMMENDATIONS_PAGE
assert 'rows.length * 164' in RECOMMENDATIONS_PAGE
assert 'tabs[i].frame.ClearAllPoints();' in TEMPLATE_BROWSER
assert 'PASS = structurally valid.' in ACTIVITY_DIAGNOSTICS
assert 'Needs Review' in ACTIVITY_DIAGNOSTICS


# Dev-realm low-level validation lane. This must stay one-shot and account-scoped so the live
# WotLK starter default cannot accidentally be changed just to test Vanilla anti-boost behavior.
assert "SetNextProfileOverride(uint32 accountId" in ADVENTURE_START_CONTROL_H
assert "ConsumeNextProfileOverride(uint32 accountId" in ADVENTURE_START_CONTROL_H
assert "g_nextProfileByAccount" in ADVENTURE_START_CONTROL
assert "ConsumeNextProfileOverride(accountId, oneShot)" in ADVENTURE_START
assert '"nextstarter"' in ADMIN_PANEL and "HandleNextStarter" in ADMIN_PANEL
assert "AdventureStartProfile::VanillaFresh" in ADMIN_PANEL
assert "next eligible non-DK character" in ADMIN_PANEL
assert "Realm era and normal starter defaults are unchanged." in ADMIN_PANEL

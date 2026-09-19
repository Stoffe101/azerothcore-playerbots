from pathlib import Path

cmd = Path('modules/mod-raid-roster/src/GroupComposerCommand.cpp')
c = cmd.read_text(encoding='utf-8')

# Runtime APIs needed for canonical instance entrances, entry preflight and Titan Rune selection.
old = '''#include "LFGMgr.h"\n#include "ObjectAccessor.h"\n#include "Player.h"\n'''
new = '''#include "LFGMgr.h"\n#include "Map.h"\n#include "MapMgr.h"\n#include "ObjectAccessor.h"\n#include "ObjectMgr.h"\n#include "Player.h"\n'''
if old not in c:
    raise SystemExit('travel include marker drifted')
c = c.replace(old, new, 1)
old = '''#include "SharedDefines.h"\n#include "World.h"\n'''
new = '''#include "SharedDefines.h"\n#include "TitanRuneSystem.h"\n#include "World.h"\n'''
if old not in c:
    raise SystemExit('Titan include marker drifted')
c = c.replace(old, new, 1)

# Keep activity -> map lookup deterministic and source-controlled. Coordinates intentionally come
# from AzerothCore's canonical area-trigger store at runtime, not from a duplicate hard-coded table.
marker = '''bool IsBotGuid(ObjectGuid guid)\n'''
if marker not in c:
    raise SystemExit('RaidMapId insertion marker drifted')
insert = '''uint32 RaidMapId(std::string const& activity)\n{\n    static std::unordered_map<std::string, uint32> const maps = {\n        { "naxxramas", 533 }, { "obsidian_sanctum", 615 }, { "eye_of_eternity", 616 },\n        { "ulduar", 603 }, { "trial_crusader", 649 }, { "onyxia", 249 },\n        { "vault_archavon", 624 }, { "icecrown", 631 }, { "ruby_sanctum", 724 },\n        { "karazhan", 532 }, { "zulaman", 568 }, { "gruul", 565 }, { "magtheridon", 544 },\n        { "serpentshrine", 548 }, { "tempest_keep", 550 }, { "hyjal", 534 },\n        { "black_temple", 564 }, { "sunwell", 580 }, { "zul_gurub", 309 }, { "aq20", 509 },\n        { "molten_core", 409 }, { "blackwing_lair", 469 }, { "aq40", 531 },\n    };\n    auto itr = maps.find(activity);\n    return itr == maps.end() ? 0 : itr->second;\n}\n\nuint32 ActivityMapId(Plan const& plan)\n{\n    if (plan.config.mode == "dungeon") return DungeonMapId(plan.config.activity);\n    if (plan.config.mode == "raid") return RaidMapId(plan.config.activity);\n    return 0;\n}\n\n'''
c = c.replace(marker, insert + marker, 1)

# Insert selected-activity travel immediately after subgroup application helpers. The live group is
# already authoritative at this point, so entry checks see the final raid/dungeon difficulty and
# membership instead of a speculative preview.
marker = '''void PruneUnselectedBots(Player* master, Plan const& plan)\n'''
if marker not in c:
    raise SystemExit('travel helper insertion marker drifted')
helpers = r'''char const* EnterStateReason(Map::EnterState state)
{
    switch (state)
    {
        case Map::CANNOT_ENTER_NO_ENTRY: return "the instance map is unavailable";
        case Map::CANNOT_ENTER_UNINSTANCED_DUNGEON: return "the instance template is unavailable";
        case Map::CANNOT_ENTER_DIFFICULTY_UNAVAILABLE: return "that difficulty is unavailable";
        case Map::CANNOT_ENTER_NOT_IN_RAID: return "the player is not in a valid raid group";
        case Map::CANNOT_ENTER_CORPSE_IN_DIFFERENT_INSTANCE: return "their corpse belongs to another instance";
        case Map::CANNOT_ENTER_INSTANCE_BIND_MISMATCH: return "their saved lockout conflicts with the group instance";
        case Map::CANNOT_ENTER_TOO_MANY_INSTANCES: return "they have entered too many instances recently";
        case Map::CANNOT_ENTER_MAX_PLAYERS: return "the target instance is already full";
        case Map::CANNOT_ENTER_ZONE_IN_COMBAT: return "an encounter is already in progress in the target instance";
        default: return "AzerothCore rejected instance entry";
    }
}

bool ResolveTitanTravelMode(Plan const& plan, uint32 mapId, TitanRuneMode& mode, std::string& error)
{
    mode = TitanRuneMode::Off;
    if (plan.config.mode != "dungeon") return true;

    bool requested = true;
    if (plan.config.difficulty == "alpha") mode = TitanRuneMode::Alpha;
    else if (plan.config.difficulty == "beta") mode = TitanRuneMode::Beta;
    else if (plan.config.difficulty == "gamma") mode = TitanRuneMode::Gamma;
    else requested = false;

    if (requested && !TitanRune::IsSupportedDungeon(mapId, mode))
    {
        error = std::string("Defense Protocol ") + TitanRune::ModeName(mode) +
            " is not supported by the selected dungeon on this realm.";
        return false;
    }
    return true;
}

bool TeleportCompletedPlan(Player* master, Plan const& plan, std::string& detail, std::string& error)
{
    if (!master)
    {
        error = "Group Composer lost the live group leader before travel.";
        return false;
    }

    uint32 mapId = ActivityMapId(plan);
    if (!mapId)
    {
        // Random Dungeon has no destination until Dungeon Finder chooses one. Named activities are
        // always mapped and travel automatically after Assemble.
        if (plan.config.mode == "dungeon" && plan.config.activity == "random")
        {
            detail = "Roster assembled. Random Dungeon is ready for Dungeon Finder.";
            return true;
        }
        error = "The selected activity has no configured instance map for automatic travel.";
        return false;
    }

    Group* group = master->GetGroup();
    if (!group || group->GetMembersCount() != plan.members.size())
    {
        error = "Automatic travel requires the complete reviewed roster to still be grouped.";
        return false;
    }

    AreaTriggerTeleport const* destination = sObjectMgr->GetMapEntranceTrigger(mapId);
    if (!destination || destination->target_mapId != mapId)
    {
        error = "AzerothCore has no canonical entrance trigger for the selected instance.";
        return false;
    }

    TitanRuneMode titanMode = TitanRuneMode::Off;
    if (!ResolveTitanTravelMode(plan, mapId, titanMode, error)) return false;

    std::vector<Player*> travelers;
    travelers.reserve(plan.members.size());
    for (Member const& member : plan.members)
    {
        Player* player = ObjectAccessor::FindConnectedPlayer(member.guid);
        if (!player)
        {
            error = "'" + member.name + "' went offline before automatic instance travel.";
            return false;
        }
        if (player->GetGroup() != group)
        {
            error = "'" + member.name + "' left the reviewed group before automatic instance travel.";
            return false;
        }
        if (player->IsBeingTeleported())
        {
            error = "'" + member.name + "' is already being teleported; wait a moment and Assemble again.";
            return false;
        }
        if (player->IsInCombat())
        {
            error = "'" + member.name + "' is in combat. Automatic instance travel waits until the full group is out of combat.";
            return false;
        }
        if (player->InBattleground() || player->IsSpectator())
        {
            error = "'" + member.name + "' is in a battleground/spectator state and cannot enter the selected instance.";
            return false;
        }

        Map::EnterState state = sMapMgr->PlayerCannotEnter(mapId, player);
        if (state != Map::CAN_ENTER && state != Map::CANNOT_ENTER_ALREADY_IN_MAP)
        {
            error = "'" + member.name + "' cannot enter the selected instance because " + EnterStateReason(state) + ".";
            return false;
        }
        travelers.push_back(player);
    }

    // The explicit Composer selection must beat any stale personal setting. Heroic/Normal turns the
    // next-dungeon protocol off; Alpha/Beta/Gamma persists the selected protocol before the leader
    // enters so TitanRune::ActivateForPlayer sees the correct authoritative group-leader setting.
    if (plan.config.mode == "dungeon")
        TitanRune::SaveSelectedMode(master, titanMode);

    auto teleport = [&](Player* player)
    {
        if (!player) return;
        if (player->IsInFlight())
        {
            player->GetMotionMaster()->MovementExpired();
            player->CleanupAfterTaxiFlight();
        }
        else
            player->SaveRecallPosition();

        player->TeleportTo(destination->target_mapId, destination->target_X, destination->target_Y,
            destination->target_Z, destination->target_Orientation);
    };

    // Let the real group leader create/resolve the destination instance first, then move every other
    // reviewed member into that group-owned copy. This keeps raid lockouts and instance ownership in
    // AzerothCore's normal path instead of inventing a Composer-specific instance ID.
    teleport(master);
    for (Player* player : travelers)
        if (player != master) teleport(player);

    detail = std::string("Roster assembled and entering the selected ") +
        (plan.config.mode == "raid" ? "raid." : "dungeon.");
    return true;
}

'''
c = c.replace(marker, helpers + marker, 1)

old = '''                std::string arrangementError;\n                plan.assembling = false;\n                if (ApplyArrangement(master, plan, arrangementError))\n                {\n                    SendProgress(master, "DONE", uint32(plan.members.size()), uint32(plan.members.size()), "Roster assembled and subgroup layout applied.");\n                    SendProtocol(master, "DONE", "Roster assembled and subgroup layout applied.");\n                }\n                else\n                    SendProtocol(master, "ERROR", arrangementError);\n'''
new = '''                std::string arrangementError;\n                plan.assembling = false;\n                if (ApplyArrangement(master, plan, arrangementError))\n                {\n                    std::string travelDetail, travelError;\n                    if (ActivityMapId(plan))\n                        SendProgress(master, "TRAVEL", uint32(plan.members.size()), uint32(plan.members.size()), "Roster complete. Entering the selected instance...");\n\n                    if (TeleportCompletedPlan(master, plan, travelDetail, travelError))\n                    {\n                        SendProgress(master, "DONE", uint32(plan.members.size()), uint32(plan.members.size()), travelDetail);\n                        SendProtocol(master, "DONE", travelDetail);\n                    }\n                    else\n                    {\n                        SendProgress(master, "ERROR", uint32(plan.members.size()), uint32(plan.members.size()), travelError);\n                        SendProtocol(master, "ERROR", travelError);\n                    }\n                }\n                else\n                    SendProtocol(master, "ERROR", arrangementError);\n'''
if old not in c:
    raise SystemExit('assembly completion travel marker drifted')
c = c.replace(old, new, 1)
cmd.write_text(c, encoding='utf-8')

# Named dungeons now enter directly after assembly. Only Random Dungeon should perform the optional
# Dungeon Finder handoff after DONE.
core = Path('client-addons-src/GroupComposer/Core.lua')
k = core.read_text(encoding='utf-8')
old = '''        if completed == "assemble" and GC:GetConfig().mode == "DUNGEON" and GC:GetConfig().options.queueAfterAssemble then\n            GC:QueueDungeon()\n        end\n'''
new = '''        if completed == "assemble" and GC:GetConfig().mode == "DUNGEON" and GC:GetConfig().activity == "random" and GC:GetConfig().options.queueAfterAssemble then\n            GC:QueueDungeon()\n        end\n'''
if old not in k:
    raise SystemExit('random queue handoff marker drifted')
k = k.replace(old, new, 1)
core.write_text(k, encoding='utf-8')

# Dashboard gets an explicit travel phase rather than exposing a raw protocol token.
dash = Path('client-addons-src/GroupComposer/DashboardV4.lua')
d = dash.read_text(encoding='utf-8')
d = d.replace('kind=="PREPARING" or kind=="BUILDING" or kind=="ASSEMBLING"', 'kind=="PREPARING" or kind=="BUILDING" or kind=="ASSEMBLING" or kind=="TRAVEL"', 1)
d = d.replace('ASSEMBLING="Assembling group",DONE="Group ready"', 'ASSEMBLING="Assembling group",TRAVEL="Entering activity",DONE="Group ready"', 1)
d = d.replace('phase=="PREPARING" or phase=="ASSEMBLING"', 'phase=="PREPARING" or phase=="ASSEMBLING" or phase=="TRAVEL"', 1)
dash.write_text(d, encoding='utf-8')

# Add a durable source-level travel contract to the existing test suite.
test = Path('client-addons-src/GroupComposer/tests/test_server_contract.py')
s = test.read_text(encoding='utf-8')
travel_contract = r'''

# V4 selected-activity travel. A named dungeon/raid is entered only after the exact reviewed roster
# is complete and subgroup application succeeds. Runtime coordinates come from AzerothCore's
# canonical map entrance trigger; Random Dungeon remains queue-selected and is never guessed here.
travel = section(SERVER, "bool TeleportCompletedPlan(", "void PruneUnselectedBots(")
assert "sObjectMgr->GetMapEntranceTrigger(mapId)" in travel, "Selected activity travel must use canonical instance entrance data"
assert "sMapMgr->PlayerCannotEnter(mapId, player)" in travel, "Every member must pass authoritative instance-entry preflight"
assert "player->IsInCombat()" in travel and "player->IsBeingTeleported()" in travel, "Travel lost combat/teleport safety guards"
assert "TitanRune::SaveSelectedMode(master, titanMode)" in travel, "Named Titan Rune travel no longer persists the reviewed protocol"
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
'''
if '# V4 selected-activity travel.' not in s:
    s += travel_contract
test.write_text(s, encoding='utf-8')

print('Group Composer V4 selected-activity travel applied')

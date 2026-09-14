#include "RaidLeaderKnowledge.h"

#include <algorithm>
#include <cctype>

namespace RaidLeaderKnowledge
{
namespace
{
std::string Normalize(std::string value)
{
    value.erase(std::remove_if(value.begin(), value.end(), [](unsigned char c)
    {
        return !std::isalnum(c);
    }), value.end());
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c)
    {
        return static_cast<char>(std::tolower(c));
    });
    return value;
}

std::vector<Encounter> Build()
{
    return {
        {
            "Karazhan", "Attumen the Huntsman", {"attumen", "midnight", "attumen and midnight"}, Readiness::GuildReady,
            "karazhan",
            "Two-phase encounter with Midnight, Attumen, then the mounted phase.",
            "Hold your assigned target away from the raid. After the mount transition, keep mounted Attumen positioned cleanly and faced away.",
            "Keep the active tanks stable through the handoff. After the mount transition, stay with the raid stack unless a mechanic forces movement.",
            "Follow the phase target. Respect the brief DPS pause during the mount transition, then stack behind mounted Attumen.",
            "Bots split tank duties, move Attumen away because of cleave, handle the mount transition, briefly pause DPS, then stack behind mounted Attumen.",
            "No bot micromanagement should be required for the encounter itself."
        },
        {
            "Karazhan", "Moroes", {"moroes"}, Readiness::GuildReady,
            "karazhan",
            "Moroes is handled around a marked add priority before settling onto the boss.",
            "Hold your assigned target and keep it controlled while the raid follows the marked kill order.",
            "Expect damage on multiple controlled/tanked targets and keep the active tanks covered while the marked targets die.",
            "Follow the raid target marks. Do not ignore the add priority to tunnel Moroes.",
            "Bots choose and mark the target priority for Moroes and his guests.",
            "The pinned encounter strategy explicitly marks guest priority; it does not justify inventing extra automated CC assignments in this brief."
        },
        {
            "Karazhan", "Maiden of Virtue", {"maiden", "maiden of virtue"}, Readiness::GuildReady,
            "karazhan",
            "Positioning fight where ranged spacing matters because Holy Wrath can chain.",
            "Hold Maiden at the strategy position and avoid dragging her through the ranged group.",
            "Use the assigned ranged/pillar spacing and keep the tank stable. Be ready for the encounter's control/damage windows.",
            "If ranged, spread into the pillar positions instead of stacking. If melee, stay disciplined around the boss and do not drag mechanics through ranged.",
            "Bots position the tank, spread ranged between pillars and can use Grounding Totem logic for Holy Fire.",
            "Human ranged players should copy the spacing instead of standing on top of bot clusters."
        },
        {
            "Karazhan", "The Big Bad Wolf", {"big bad wolf", "wolf", "red riding hood"}, Readiness::GuildReady,
            "karazhan",
            "Opera variant centered on Little Red Riding Hood chase windows.",
            "Keep the boss at the strategy tank position when he is not chasing Little Red Riding Hood.",
            "Keep the chased player alive while staying clear of the chase path.",
            "If you get Little Red Riding Hood, run the room path and do not try to face-tank him. Otherwise keep attacking from a safe position.",
            "Bots identify the Red Riding Hood target, run away while chased and reposition the boss around the tank spot.",
            "The player still has to react if the Red Riding Hood effect lands on them."
        },
        {
            "Karazhan", "Romulo and Julianne", {"romulo", "julianne", "romulo and julianne"}, Readiness::GuildReady,
            "karazhan",
            "Opera variant with target changes as the two bosses progress through their phases.",
            "Pick up the active assigned boss and avoid freelancing away from the marked target plan.",
            "Track whichever boss/tank is currently active and be ready for the phase where both are present.",
            "Follow the marked target when both bosses are active instead of splitting damage randomly.",
            "Bots detect the revived/both-active phase and set the raid target priority.",
            "Use the marks as the source of truth for target swaps."
        },
        {
            "Karazhan", "The Wizard of Oz", {"wizard of oz", "oz", "dorothee", "strawman", "tinhead", "roar"}, Readiness::GuildReady,
            "karazhan",
            "Opera variant where target priority is the important coordination piece.",
            "Control the active marked target and keep enemies positioned so the raid can follow the priority cleanly.",
            "Follow the marked target flow and keep the raid stable as new actors become active.",
            "Attack the marked priority target. Fire-capable bots exploit Strawman's fire vulnerability automatically.",
            "Bots establish the Oz target order and fire-capable bots can deliberately Scorch Strawman.",
            "Do not invent a competing target order when the strategy marks one."
        },
        {
            "Karazhan", "The Curator", {"curator", "the curator"}, Readiness::GuildReady,
            "karazhan",
            "Add-control fight where Astral Flares are the immediate target and the boss has an Evocation burn window.",
            "Keep Curator fixed at the strategy tank position while the raid handles flares.",
            "Keep the raid stable through flare damage and be ready to capitalize on the quieter Evocation window.",
            "Swap to marked Astral Flares quickly. If ranged, maintain spread. Burn Curator hard during Evocation.",
            "Bots mark Astral Flares, position Curator, spread ranged and delay Bloodlust/Heroism for the useful damage window.",
            "The human player's main job is respecting flare swaps and ranged spacing."
        },
        {
            "Karazhan", "Terestian Illhoof", {"illhoof", "terestian", "terestian illhoof"}, Readiness::GuildReady,
            "karazhan",
            "Priority-swap fight where Demon Chains must take precedence over normal boss damage.",
            "Hold Illhoof stable while the raid swaps to priority targets.",
            "React immediately to the chained player and keep them alive while the chains are destroyed.",
            "Swap to Demon Chains immediately when they appear, then return to the normal target plan.",
            "Bots reprioritize/mark the chains and avoid wasting DoTs on low-value Fiendish Imps.",
            "Chains are the important human reaction too; do not tunnel the boss through them."
        },
        {
            "Karazhan", "Shade of Aran", {"aran", "shade", "shade of aran"}, Readiness::GuildReady,
            "karazhan",
            "Movement-discipline fight built around Arcane Explosion, Flame Wreath and summoned elementals.",
            "There is no normal tanking pattern to force. Follow the same movement rules as the raid and avoid disrupting positioning.",
            "Keep people alive through the spell pressure while obeying Flame Wreath and Arcane Explosion movement rules yourself.",
            "Run away from Arcane Explosion. When Flame Wreath is active, stop moving. Swap to marked summoned elementals when directed.",
            "Bots run from Arcane Explosion, freeze movement for Flame Wreath, mark elementals and maintain ranged distance around Counterspell behavior.",
            "Flame Wreath is deliberately deterministic: when it is active, movement is the thing to avoid."
        },
        {
            "Karazhan", "Netherspite", {"netherspite", "nether spite"}, Readiness::GuildReady,
            "karazhan",
            "Beam/portal fight with red, green and blue beam assignments plus void-zone avoidance.",
            "Follow the red/tanking beam assignment if the strategy gives it to you and keep the boss controlled through portal phases.",
            "Respect beam assignments and keep blockers alive while avoiding void zones.",
            "Do not casually cross beams. Follow the assigned blocker plan, avoid void zones, and continue damage when you are not assigned to a beam.",
            "Bots track red/green/blue blockers, find beam positions, avoid beams they do not own, avoid void zones and handle the banish phase.",
            "Beam assignments come from the deterministic strategy. The raid leader should never improvise different assignments through the LLM."
        },
        {
            "Karazhan", "Prince Malchezaar", {"prince", "malchezaar", "prince malchezaar"}, Readiness::GuildReady,
            "karazhan",
            "Hazard-positioning fight centered on Enfeeble and infernal placement.",
            "Keep Prince in the strategy's safe tank position and do not chase him through infernal hazards.",
            "Watch Enfeebled players and maintain safe positioning around infernals.",
            "If Enfeebled, prioritize getting clear of hazards. Otherwise keep attacking while moving around infernal danger zones.",
            "Bots reposition tanks, keep non-tanks away from infernals, react to Enfeeble and delay Bloodlust/Heroism appropriately.",
            "Hazard safety beats squeezing in an extra cast while Enfeebled."
        },
        {
            "Karazhan", "Nightbane", {"nightbane", "night bane"}, Readiness::GuildReady,
            "karazhan",
            "Ground/flight encounter with coordinated ranged movement, flight-phase stacking and hazard avoidance.",
            "Use the strategy ground position and keep Nightbane oriented consistently during ground phases.",
            "Follow the flight-phase stack/move calls and keep the raid stable while avoiding Charred Earth.",
            "Follow the ground positioning, then stack/move with the raid during flight. Move out of Charred Earth and follow the Rain of Bones relocation.",
            "Bots position the ground phase, coordinate ranged movement, stack/move in flight, react to Rain of Bones/Charred Earth and manage phase timers.",
            "The coded strategy handles the complicated movement; the human should follow the visible group instead of issuing bot commands."
        },
        {
            "Karazhan", "Chess Event", {"chess", "chess event"}, Readiness::Playable,
            "none",
            "Chess is the Karazhan exception: there is no Chess-specific combat strategy registered in the pinned Playerbots Karazhan strategy set.",
            "No tank role applies. Control the chess event manually.",
            "No healer role applies. Control the chess event manually.",
            "No DPS role applies. Control the chess event manually.",
            "No Playerbots combat strategy is claimed for Chess by this fork.",
            "Yellow/Playable by design, not Guild Ready. The guild system should never pretend the bots solve it."
        },
        {
            "Gruul's Lair", "High King Maulgar", {"maulgar", "high king", "high king maulgar"}, Readiness::GuildReady,
            "gruulslair",
            "Council-style opener with multiple tank assignments, a deterministic kill order and dangerous Whirlwind/Blast Wave zones.",
            "Take only the assignment the strategy gives you. Keep your target separated and move away from Whirlwind/Blast Wave danger when relevant.",
            "Track the split tank assignments and keep each assigned tank alive while the raid burns the marked priority.",
            "Follow the assigned kill priority. Run from Maulgar's Whirlwind and stay out of Krosh's Blast Wave danger.",
            "Bots assign Maulgar/Olm/Blindeye/Krosh/Kiggler tank jobs, establish DPS priority, avoid Whirlwind/Blast Wave, CC Fel Stalkers and use misdirects on the pull.",
            "Special tank roles are deterministic. The LLM should explain them, never reassign them ad hoc."
        },
        {
            "Gruul's Lair", "Gruul the Dragonkiller", {"gruul", "dragonkiller", "gruul the dragonkiller"}, Readiness::GuildReady,
            "gruulslair",
            "Positioning fight where ranged spread and the incoming Shatter spread are the key movement rules.",
            "Keep Gruul at the coded tank position and avoid dragging him through the spread raid.",
            "Stay spread enough to reduce Shatter danger and keep the tanks stable as the fight ramps.",
            "Stay spread at range and create extra space when Shatter is incoming. Do not stack back on other players too early.",
            "Bots position tanks, spread ranged and deliberately spread harder for incoming Shatter.",
            "Player spacing matters; no bot command should be needed."
        },
        {
            "Magtheridon's Lair", "Magtheridon", {"mag", "magtheridon", "magtheridons lair"}, Readiness::GuildReady,
            "magtheridon",
            "Two-stage encounter: Hellfire Channeler control/kill order followed by Magtheridon with spread, debris avoidance and Manticron Cube handling for Blast Nova.",
            "Follow the assigned Channeler or boss tank job. Once Magtheridon is active, hold the coded boss position and stay out of debris.",
            "Keep the split Channeler tanks alive in phase one, then stabilize the raid through Magtheridon while respecting debris and Blast Nova timing.",
            "Follow the marked Channeler kill order, stay spread on Magtheridon and move out of debris. Do not interfere with the cube assignments unless the deterministic strategy assigns you.",
            "Bots split Channeler tanks, mark DPS priority, CC Burning Abyssals, position/spread on Magtheridon, move from debris and schedule Manticron Cube use for Blast Nova.",
            "Cube handling is deterministic in the pinned strategy, but an assigned bot can still fail to complete an interaction if its cube GameObject cannot be resolved or reached. Treat the mechanic as automated, not infallible."
        },

        // WotLK 3.3.5a. These summaries deliberately mirror actions that exist in the pinned
        // Playerbots strategy tree. The language model may phrase these instructions, but it is
        // never the source of truth for movement, targeting, encounter state or assignments.
        {
            "Naxxramas", "Anub'Rekhan", {"anubrekhan", "anub rekhan"}, Readiness::GuildReady,
            "naxx",
            "Positioning encounter with a dedicated Anub'Rekhan strategy trigger.",
            "Follow the coded tank position and keep the boss oriented consistently.",
            "Keep the active tank stable and move with the raid when the strategy repositions.",
            "Stay with the raid's chosen position and avoid freelancing away from the coded movement plan.",
            "Bots run the Anub'Rekhan positioning action from the Naxx strategy.",
            "The raid leader should explain the position plan, not invent replacement coordinates."
        },
        {
            "Naxxramas", "Grand Widow Faerlina", {"faerlina", "grand widow"}, Readiness::GuildReady,
            "naxx",
            "The pinned strategy provides encounter detection plus generic AOE avoidance.",
            "Keep control of your assigned target and do not drag hazards through the group.",
            "Keep tanks covered while respecting the same movement hazards as the raid.",
            "Follow target calls and move out of avoidable AOE.",
            "Bots use the Faerlina trigger with the shared avoid-AOE action.",
            "Automation is intentionally described conservatively because the pinned strategy does not expose a larger Faerlina-specific action set."
        },
        {
            "Naxxramas", "Maexxna", {"maexxna"}, Readiness::GuildReady,
            "naxx",
            "Positioning encounter where the pinned strategy combines rear-flank behavior with AOE avoidance.",
            "Keep Maexxna controlled while allowing the raid to occupy the rear-flank position.",
            "Keep the tank stable and react to damage without abandoning safe positioning.",
            "Stay on the rear flank when appropriate and move out of avoidable AOE.",
            "Bots execute rear-flank and avoid-AOE actions while Maexxna is active.",
            "Do not claim automation for mechanics that are not represented in the pinned strategy."
        },
        {
            "Naxxramas", "Patchwerk", {"patchwerk", "patch"}, Readiness::Playable,
            "naxx",
            "Patchwerk is present in the Naxx strategy source, but the dedicated tank/ranged/non-tank trigger block is commented out in the pinned revision.",
            "Treat this as a normal manually supervised tanking check rather than relying on special Patchwerk positioning automation.",
            "Keep the tanks stable and do not assume a disabled strategy block will rescue bad positioning.",
            "Attack normally while respecting the human raid leader's positioning.",
            "No active Patchwerk-specific trigger set is claimed by this fork at the pinned commit.",
            "Marked Playable instead of Guild Ready in the encounter brief so the assistant never overstates automation."
        },
        {
            "Naxxramas", "Grobbulus", {"grobbulus", "grobb"}, Readiness::GuildReady,
            "naxx",
            "Movement encounter centered on Mutating Injection and poison-cloud positioning.",
            "Rotate Grobbulus cleanly as the cloud logic requests and preserve room for the raid.",
            "Keep the moving raid stable and react to players displaced by Mutating Injection.",
            "If the strategy moves you for Mutating Injection, finish the movement before returning to normal positioning.",
            "Bots distinguish melee/ranged injection handling, move injected players away/behind, return them after removal, and rotate the boss around clouds.",
            "The movement comes from deterministic triggers: mutating injection melee/ranged/removed and grobbulus cloud."
        },
        {
            "Naxxramas", "Gluth", {"gluth"}, Readiness::GuildReady,
            "naxx",
            "Targeting and positioning encounter with add-slow support and tank swap assistance.",
            "Follow the strategy position and be ready for the coded taunt response when the main tank accumulates Mortal Wound pressure.",
            "Track the tank handoff and keep the raid stable while adds are controlled.",
            "Attack the strategy-selected target; if assigned to add control, follow the slowdown/position behavior rather than tunneling.",
            "Bots choose targets, position for Gluth, slow adds and trigger a taunt when the main-tank Mortal Wound condition fires.",
            "The taunt is strategy-driven, not an LLM decision."
        },
        {
            "Naxxramas", "Thaddius", {"thaddius", "thad"}, Readiness::GuildReady,
            "naxx",
            "Multi-phase encounter with platform transition and polarity movement.",
            "Follow the phase target and transition movement; do not fight the polarity positioning logic once Thaddius is active.",
            "Keep the active platform/tank targets stable through the transition and move with polarity assignments afterwards.",
            "Finish the platform transition, then obey the polarity movement instead of staying planted for extra casts.",
            "Bots attack the nearest platform target, recover lost tank aggro, move to the Thaddius platform and run the polarity movement action.",
            "Polarity placement is deterministic in Playerbots and must not be reassigned conversationally."
        },
        {
            "Naxxramas", "Instructor Razuvious", {"razuvious", "instructor"}, Readiness::GuildReady,
            "naxx",
            "Special-control encounter with explicit obedience-crystal tank behavior.",
            "If the strategy assigns the tank job, let the obedience-crystal action own it rather than forcing a conventional tank plan.",
            "Keep the controlled tank target stable and avoid disrupting the special-control flow.",
            "Use the strategy-selected target and do not pull threat away from the controlled tank plan.",
            "Tank bots use the obedience-crystal action; non-tanks use the Razuvious target action.",
            "This is a coded special-role encounter, so conversational AI must not improvise a different control method."
        },
        {
            "Naxxramas", "Gothik the Harvester", {"gothik", "harvester"}, Readiness::Playable,
            "naxx",
            "Gothik support exists in the Naxx codebase, but the Gothik generic multiplier is commented out in the pinned strategy revision.",
            "Supervise positioning manually and do not assume full encounter-specific automation.",
            "Treat the fight as human-supervised until runtime validation proves the remaining behavior reliable.",
            "Follow the human raid leader's target and side plan.",
            "This fork does not claim the commented Gothik multiplier as active automation.",
            "Marked Playable to keep the raid leader honest about the pinned implementation."
        },
        {
            "Naxxramas", "The Four Horsemen", {"four horsemen", "horsemen", "4 horsemen"}, Readiness::GuildReady,
            "naxx",
            "Assignment encounter with dedicated attractor and attack-order logic.",
            "Take the tank/attractor assignment produced by the deterministic strategy and hold it instead of chasing another corner.",
            "Track split assignments and keep each active tank group stable.",
            "Attack in the strategy order and stay with your assigned group.",
            "Bots divide attractor roles and alternate them while the rest of the raid attacks in the coded order.",
            "Assignments are deterministic. The LLM is allowed to explain them, never reshuffle them."
        },
        {
            "Naxxramas", "Loatheb", {"loatheb"}, Readiness::GuildReady,
            "naxx",
            "Position and target-selection encounter backed by a dedicated Loatheb multiplier.",
            "Hold the coded position and avoid pulling the boss away from the planned group layout.",
            "Use the encounter's healing windows while staying with the strategy position.",
            "Follow the chosen target and position rather than creating a second formation.",
            "Bots run Loatheb positioning/target actions plus the dedicated Loatheb multiplier.",
            "Healing-window details remain the encounter's responsibility; this brief does not fabricate extra timers."
        },
        {
            "Naxxramas", "Heigan the Unclean", {"heigan", "heigan the unclean"}, Readiness::GuildReady,
            "naxx",
            "Movement encounter with separate coded dance behavior for melee and ranged roles.",
            "Keep the boss controlled while following the appropriate dance path.",
            "Heal while following the ranged/melee movement logic; survival movement takes priority over squeezing in another cast.",
            "Follow the dance movement for your role and do not stand still waiting for a chat call.",
            "Bots trigger separate heigan dance melee and heigan dance ranged actions.",
            "The dance path is code-driven. Natural-language callouts are only commentary on top."
        },
        {
            "Naxxramas", "Sapphiron", {"sapphiron", "sapph"}, Readiness::GuildReady,
            "naxx",
            "Ground and flight phases have separate deterministic positioning actions.",
            "Use the ground position and keep orientation stable until the flight-phase logic takes over.",
            "Move with the ground/flight formation and keep the raid stable through phase changes.",
            "Follow the phase position instead of anchoring yourself to the previous formation.",
            "Bots use dedicated Sapphiron ground-position and flight-position actions.",
            "The raid leader can announce the phase change, but the actual positions come from Playerbots."
        },
        {
            "Naxxramas", "Kel'Thuzad", {"kelthuzad", "kel thuzad", "kt"}, Readiness::GuildReady,
            "naxx",
            "Final encounter with dedicated position and target-selection actions.",
            "Follow the coded position and keep tanking assignments consistent when targets change.",
            "Maintain the formation while covering the active target/tank.",
            "Use the strategy-selected target and preserve spacing/positioning instead of chasing independently.",
            "Bots continuously run Kel'Thuzad position and target-selection actions while the encounter trigger is active.",
            "This brief intentionally does not invent unverified handling beyond the pinned strategy."
        },
        {
            "The Obsidian Sanctum", "Sartharion", {"sartharion", "sarth", "obsidian sanctum"}, Readiness::GuildReady,
            "wotlk-os",
            "Sartharion strategy covers tank placement, fissure/tsunami avoidance, target priority, melee flank positioning and twilight portals.",
            "Hold the coded tank position and do not drag Sartharion through the raid's movement lanes.",
            "Follow fissure/tsunami movement while keeping the tank and portal group stable.",
            "Avoid Twilight Fissure and Flame Tsunami, follow attack priority, and use portal movement when the deterministic triggers assign it.",
            "Bots tank-position Sartharion, dodge fissures/tsunami, rear-flank in melee, pick attack priority and enter/exit twilight portals.",
            "The current Adventure Guide keeps the upstream drake caveat visible. Do not promise unsupported drake orders through chat."
        },
        {
            "The Eye of Eternity", "Malygos", {"malygos", "eye of eternity", "eoe"}, Readiness::GuildReady,
            "wotlk-eoe",
            "Malygos strategy covers boss positioning/targeting plus the flying-drake phase.",
            "Follow the Malygos positioning action until the vehicle phase takes over.",
            "Stay with the group formation and continue supporting the transition into the drake phase.",
            "Follow target calls in the ground phase; once mounted, let the drake-combat behavior handle the vehicle rotation.",
            "Bots position/target Malygos, fly the encounter drakes and run the drake attack action in vehicle combat.",
            "Vehicle handling is explicitly coded in the pinned strategy, so the LLM only narrates the transition."
        },
        {
            "Onyxia's Lair", "Onyxia", {"onyxia", "ony", "onyxias lair"}, Readiness::GuildReady,
            "onyxia",
            "Onyxia strategy handles tail avoidance, egg avoidance, Deep Breath safety, fireball splash spacing and whelp targeting.",
            "Keep Onyxia controlled without placing the raid near her tail or egg areas.",
            "Move with Deep Breath safety/spread calls while keeping the tank and whelp pressure stable.",
            "Stay off the tail, avoid eggs, move to the Deep Breath safe zone, spread for incoming fireball splash and swap to whelps when they spawn.",
            "Bots move to Onyxia's side near the tail, avoid eggs, move to a safe zone for Deep Breath, spread for fireball splash and kill spawned whelps.",
            "The strategy source marks its own phase thresholds. The raid leader should not invent different ones."
        },
        {
            "Icecrown Citadel", "Lord Marrowgar", {"marrowgar", "lord marrowgar"}, Readiness::GuildReady,
            "icc",
            "ICC opens with dedicated tank positioning and Bone Spike target handling.",
            "Use the ICC Marrowgar tank position and keep the boss consistently placed.",
            "Keep tanks stable and react immediately when the spike target changes.",
            "Swap to the spike target when the strategy calls it, then return to the boss.",
            "Bots run icc lm tank position and icc spike actions.",
            "Target selection and position come from the ICC strategy, not the chat model."
        },
        {
            "Icecrown Citadel", "Lady Deathwhisper", {"deathwhisper", "lady deathwhisper"}, Readiness::GuildReady,
            "icc",
            "Dedicated ICC actions cover ranged positioning, adds, shades and Dark Reckoning movement.",
            "Hold the active tank assignment and allow the strategy to control add/boss priority.",
            "Cover add pressure while moving out for Dark Reckoning when the encounter trigger fires.",
            "Follow the strategy's add/shade priority and ranged-position logic instead of tunneling the boss.",
            "Bots use ranged-position, add, shade and Dark Reckoning actions for Lady Deathwhisper.",
            "The deterministic triggers own target/movement choices."
        },
        {
            "Icecrown Citadel", "Gunship Battle", {"gunship", "gunship battle"}, Readiness::GuildReady,
            "icc",
            "Vehicle encounter with explicit cannon, rocket-jump and rocket-pack setup actions.",
            "Follow the role assigned by the encounter strategy rather than trying to tank from an unplanned position.",
            "Support the group split and keep players alive through transitions between ships.",
            "Use the cannon or rocket-jump role the strategy gives you and do not fight the vehicle logic.",
            "Bots enter/fire cannons, set up rocket packs and execute rocket jumps through the ICC strategy.",
            "This is real coded vehicle behavior, not an LLM-scripted imitation."
        },
        {
            "Icecrown Citadel", "Deathbringer Saurfang", {"saurfang", "deathbringer", "dbs"}, Readiness::GuildReady,
            "icc",
            "Tank positioning and add handling are explicit, including tank-taunt logic around Rune of Blood.",
            "Use the coded tank position and let the encounter's Rune of Blood taunt logic handle the swap.",
            "Keep the active tank stable while the raid handles adds.",
            "Follow the Blood Beast/add priority instead of tunneling Saurfang.",
            "Bots run DBS tank positioning/add actions; Rune of Blood boss taunt handling lives inside the tank-position action.",
            "The swap is code-driven and must not be delegated to free-form chat."
        },
        {
            "Icecrown Citadel", "Festergut", {"festergut", "fester"}, Readiness::GuildReady,
            "icc",
            "Group positioning, spore movement and Malleable Goo avoidance are explicit ICC actions.",
            "Keep the boss controlled while allowing the group/spore formations to move around you.",
            "Follow the group/spore positioning and keep the raid stable while dodging Malleable Goo.",
            "Move with your assigned spore/group position and dodge Malleable Goo when triggered.",
            "Bots use festergut group position, spore and avoid-malleable-goo actions.",
            "Callouts may sound human, but movement decisions are deterministic."
        },
        {
            "Icecrown Citadel", "Rotface", {"rotface", "rot"}, Readiness::GuildReady,
            "icc",
            "Tank/group positioning is paired with explosion and Vile Gas avoidance.",
            "Use the Rotface tank position and avoid dragging the boss into the group's hazard movement.",
            "Keep the group stable while following explosion/Vile Gas avoidance.",
            "Follow the group position and immediately move for explosion or Vile Gas avoidance when triggered.",
            "Bots run dedicated tank/group position, explosion-avoidance and Vile Gas actions.",
            "This brief does not invent extra ooze assignments beyond what the pinned strategy exposes."
        },
        {
            "Icecrown Citadel", "Professor Putricide", {"putricide", "professor", "pp"}, Readiness::GuildReady,
            "icc",
            "The ICC strategy has explicit actions for Volatile Ooze, Gas Cloud, Growing Ooze Puddle, Mutated Plague, Malleable Goo and the abomination role.",
            "Hold the active tank job and do not override the encounter's specialized target/movement actions.",
            "Track the active hazard/add target and keep the group alive while the strategy moves people around puddles and goo.",
            "Follow ooze/cloud target changes and move for puddles/Malleable Goo instead of tunneling.",
            "Bots have dedicated Putricide actions for both add types, puddles, plague, Malleable Goo and abomination control.",
            "The LLM must not improvise target priority or abomination behavior."
        },
        {
            "Icecrown Citadel", "Blood Prince Council", {"blood prince council", "princes", "bpc"}, Readiness::GuildReady,
            "icc",
            "Special tank roles plus Empowered Vortex, Kinetic Bomb and Ball of Flame actions are coded.",
            "Use the main-tank or Keleseth-tank role assigned by the ICC strategy.",
            "Keep both tank roles covered while reacting to the council's movement mechanics.",
            "Handle the strategy-selected mechanic target, especially Kinetic Bomb and Ball of Flame, and move for Empowered Vortex.",
            "Bots separate Keleseth/main tank duties and run dedicated vortex, kinetic-bomb and ball-of-flame actions.",
            "Tank assignments are deterministic and should only be explained by the raid leader."
        },
        {
            "Icecrown Citadel", "Blood-Queen Lana'thel", {"blood queen", "lanathel", "blood queen lanathel", "bql"}, Readiness::GuildReady,
            "icc",
            "Group positioning, Pact of the Darkfallen and Vampiric Bite are explicit ICC strategy actions.",
            "Keep the boss controlled while preserving the group formation.",
            "Keep pact/bite targets alive while following the same movement plan.",
            "Follow Pact movement and the strategy's Vampiric Bite action instead of selecting your own target ad hoc.",
            "Bots run BQL group position, pact and vampiric-bite actions with encounter priorities.",
            "Bite handling is deterministic. The LLM never chooses a bite target."
        },
        {
            "Icecrown Citadel", "Valithria Dreamwalker", {"valithria", "dreamwalker", "vdw"}, Readiness::GuildReady,
            "icc",
            "A specialized healing encounter with group, zombie-kite, portal, heal and dream-cloud actions.",
            "If tanking, follow the encounter target plan rather than trying to tank the friendly objective.",
            "Healers should follow the Valithria heal/portal/cloud roles produced by the deterministic strategy.",
            "DPS follows the add plan while assigned healers use the portal/cloud flow.",
            "Bots have dedicated Valithria group, zombie-kite, portal, heal and dream-cloud actions.",
            "Role decisions come from code. Chat only explains the plan."
        },
        {
            "Icecrown Citadel", "Sindragosa", {"sindragosa", "sindra"}, Readiness::GuildReady,
            "icc",
            "The ICC strategy covers group position, Frost Beacon, Blistering Cold, Unchained Magic, Chilled to the Bone, Mystic Buffet and Frost Bomb movement.",
            "Hold the coded position and allow the phase/mechanic movement to reposition the group.",
            "Follow the same mechanic movement while keeping tanks and beacon targets stable.",
            "Move for Frost Beacon, Blistering Cold and Frost Bomb; respect Unchained Magic/Chilled/Mystic Buffet actions when they trigger.",
            "Bots run dedicated Sindragosa actions for the major movement/debuff mechanics listed in the pinned ICC strategy.",
            "The mechanic triggers are code-owned, not inferred by an LLM from boss chat."
        },
        {
            "Icecrown Citadel", "The Lich King", {"lich king", "the lich king", "arthas", "lk"}, Readiness::GuildReady,
            "icc",
            "The pinned ICC strategy explicitly handles Shadow Trap, Necrotic Plague, transition winter, adds and Spirit Bomb behavior.",
            "Hold the active tank assignment while letting the encounter strategy control transitions/add movement.",
            "Keep tanks and mechanic targets stable while following transition/plague movement.",
            "Move for Shadow Trap, obey Necrotic Plague handling, follow transition/add targets and react to Spirit Bomb movement.",
            "Bots have explicit Lich King actions for Shadow Trap, Necrotic Plague, winter transitions, adds and Spirit Bombs.",
            "This is the key safety boundary: Defile-style or other lethal movement must come from actual strategy code when supported, never from the LLM inventing a call."
        },
    };
}
}

std::vector<Encounter> const& Encounters()
{
    static std::vector<Encounter> const encounters = Build();
    return encounters;
}

Encounter const* Find(std::string const& text)
{
    std::string wanted = Normalize(text);
    if (wanted.empty())
        return nullptr;

    for (Encounter const& encounter : Encounters())
    {
        if (wanted == Normalize(encounter.boss))
            return &encounter;
        for (std::string const& alias : encounter.aliases)
            if (wanted == Normalize(alias))
                return &encounter;
    }

    // For command convenience, allow an unambiguous boss/alias mention inside a longer phrase.
    Encounter const* match = nullptr;
    for (Encounter const& encounter : Encounters())
    {
        bool found = wanted.find(Normalize(encounter.boss)) != std::string::npos;
        if (!found)
            for (std::string const& alias : encounter.aliases)
                if (Normalize(alias).size() >= 4 && wanted.find(Normalize(alias)) != std::string::npos)
                {
                    found = true;
                    break;
                }
        if (!found)
            continue;
        if (match)
            return nullptr;
        match = &encounter;
    }
    return match;
}

char const* ReadinessName(Readiness readiness)
{
    switch (readiness)
    {
        case Readiness::GuildReady: return "GUILD READY";
        case Readiness::Playable: return "PLAYABLE / CAVEAT";
        default: return "NOT READY";
    }
}

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
            "The raid leader should reinforce the marked target rather than inventing a separate kill order."
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
            "Chess is the Karazhan exception: the current Playerbots completion guide treats it as a manual/solo event rather than a bot-controlled raid encounter.",
            "No tank role applies. Control the chess event manually.",
            "No healer role applies. Control the chess event manually.",
            "No DPS role applies. Control the chess event manually.",
            "No Playerbots combat strategy is used for Chess.",
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
            "The current upstream guide notes a low-health Blast Nova timing bug can occasionally cast earlier than expected. The raid leader should surface that caveat rather than claim perfect cube timing."
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
            return nullptr; // ambiguous phrase: refuse to guess.
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
}

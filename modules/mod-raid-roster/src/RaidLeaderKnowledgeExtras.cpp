#include "RaidLeaderKnowledge.h"

#include <algorithm>
#include <cctype>

namespace RaidLeaderKnowledge
{
namespace
{
std::string NormalizeExtra(std::string value)
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

std::vector<Encounter> BuildSupplemental()
{
    // Every claimed automation below is taken from the current pinned Playerbots strategy tree
    // (mod-playerbots b6696bdb...). Sparse/absent strategy blocks stay yellow/red rather than
    // being filled from generic raid-guide knowledge. This table is an explanation layer only.
    return {
        {
            "Ulduar", "Flame Leviathan", {"flame leviathan", "leviathan", "fl"}, Readiness::GuildReady,
            "ulduar",
            "Vehicle encounter with explicit enter-vehicle and vehicle-combat actions in the current Ulduar strategy.",
            "Use the vehicle role selected by Playerbots; conventional tank positioning is not the source of truth here.",
            "Support the vehicle plan and avoid trying to replace vehicle behavior with normal healing positioning.",
            "Enter and operate the assigned vehicle instead of fighting on foot.",
            "Bots detect nearby encounter vehicles, enter them and run the Flame Leviathan vehicle action.",
            "Vehicle choice and operation are code-owned. Chat must not invent tower or seat assignments that are not exposed by the strategy."
        },
        {
            "Ulduar", "Razorscale", {"razorscale", "razor"}, Readiness::GuildReady,
            "ulduar",
            "The current strategy handles Devouring Flames, sentinels, Whirlwind, grounded phases, harpoons, Fuse Armor and fire resistance.",
            "Hold the strategy-selected target/position and let Fuse Armor handling control tank reactions when it triggers.",
            "Keep the active tank stable while moving out of the same hazards the strategy detects.",
            "Avoid Devouring Flames, sentinel/Whirlwind danger and follow the grounded/harpoon target plan.",
            "Bots avoid Devouring Flames, sentinels and Whirlwind, ignore an ungrounded boss when appropriate, use harpoons, handle grounded phases and Fuse Armor.",
            "The brief does not invent a harpoon schedule; the deterministic trigger decides when the harpoon action is valid."
        },
        {
            "Ulduar", "Ignis the Furnace Master", {"ignis", "furnace master"}, Readiness::Playable,
            "ulduar",
            "The pinned Ulduar strategy exposes fire-resistance support for Ignis but not a complete encounter-specific movement/add-control action set.",
            "Tank the encounter manually using normal boss control; do not expect the raid leader to claim automated construct positioning.",
            "Keep the tank and grabbed targets stable while supervising the encounter manually.",
            "Follow the human plan for constructs and movement; Playerbots only contributes the verified resistance behavior here.",
            "Bots can switch/use the strategy's Ignis fire-resistance action.",
            "PLAYABLE/CAVEAT: no full Ignis automation is claimed from the current pinned strategy."
        },
        {
            "Ulduar", "XT-002 Deconstructor", {"xt", "xt002", "xt-002", "deconstructor"}, Readiness::NotReady,
            "none",
            "No XT-002-specific trigger/action block is present in the current pinned Ulduar strategy table.",
            "Use a human-led tank plan.",
            "Use a human-led healing plan.",
            "Use a human-led target/movement plan.",
            "No encounter-specific Playerbots automation is claimed for XT-002 by this integration.",
            "NOT READY for hands-off guild raiding until deterministic XT behavior exists and is runtime-tested."
        },
        {
            "Ulduar", "Assembly of Iron", {"assembly of iron", "iron assembly", "iron council", "steelbreaker", "runemaster molgeim", "stormcaller brundir", "brundir", "molgeim"}, Readiness::GuildReady,
            "ulduar",
            "Council encounter with explicit Lightning Tendrils, Overload and Rune of Power reactions.",
            "Hold your strategy-assigned council target and respect Overload/Lightning Tendrils movement instead of forcing a static tank formation.",
            "Keep split targets stable while the raid moves for the strategy-detected hazards.",
            "Follow the chosen council target and react to Lightning Tendrils, Overload and Rune of Power as the deterministic actions fire.",
            "Bots have dedicated Iron Assembly actions for Lightning Tendrils, Overload and Rune of Power.",
            "Kill order is not invented by chat. If the strategy or human plan chooses a hard-mode order, that remains authoritative."
        },
        {
            "Ulduar", "Kologarn", {"kologarn", "kolo"}, Readiness::GuildReady,
            "ulduar",
            "Kologarn has explicit target marking, eye-beam movement, floor recovery, rubble slow and Crunch Armor handling.",
            "Follow the deterministic tank/target behavior and allow Crunch Armor logic to own its reaction.",
            "Keep the tank stable and avoid chasing eye-beam targets through the raid.",
            "Follow the marked DPS target, move for Eye Beams and stay clear of rubble/floor hazards.",
            "Bots mark the DPS target, move for Eye Beams, recover floor positioning, slow rubble and react to Crunch Armor.",
            "The existing local Kologarn eye-beam compatibility patch remains layered on top of this upstream strategy."
        },
        {
            "Ulduar", "Auriaya", {"auriaya", "auri"}, Readiness::Playable,
            "ulduar",
            "The pinned Ulduar strategy currently exposes Auriaya floor-recovery behavior but not a complete encounter-specific target/fear/add package.",
            "Use the human-led tank plan and supervise the pull.",
            "Treat healing/positioning as human-supervised beyond the verified floor-recovery action.",
            "Follow human target calls instead of assuming the bot strategy owns every add mechanic.",
            "Bots have an Auriaya fall-from-floor recovery action.",
            "PLAYABLE/CAVEAT: do not present this as fully hands-off until a broader deterministic strategy is present."
        },
        {
            "Ulduar", "Hodir", {"hodir"}, Readiness::GuildReady,
            "ulduar",
            "Movement support covers Snowpacked Icicle safety, Biting Cold movement/jumping and frost resistance.",
            "Hold the strategy position while obeying the same Snowpacked Icicle/Biting Cold movement logic as the raid.",
            "Keep the tank stable while moving with safe positions; survival movement outranks stationary casts.",
            "Move to Snowpacked Icicle safety and keep moving/jumping when Biting Cold logic triggers.",
            "Bots move to Snowpacked Icicles, jump/move for Biting Cold and use frost-resistance support.",
            "Hard-mode timing/damage optimization is not delegated to the LLM."
        },
        {
            "Ulduar", "Freya", {"freya"}, Readiness::GuildReady,
            "ulduar",
            "Freya strategy handles Nature Bomb avoidance, resistance support, DPS target marking and Healing Spore positioning.",
            "Control the strategy-selected target and avoid dragging enemies into Nature Bomb hazards.",
            "Keep the active target/tank stable while following the same bomb/spore movement rules.",
            "Follow marked targets, move away from Nature Bombs and move to Healing Spores when the deterministic trigger calls it.",
            "Bots avoid Nature Bombs, mark DPS targets, move to Healing Spores and use fire/nature resistance support.",
            "The LLM does not select add order or elder/hard-mode configuration."
        },
        {
            "Ulduar", "Thorim", {"thorim"}, Readiness::GuildReady,
            "ulduar",
            "The strategy explicitly separates arena, gauntlet and phase-two positioning and reacts to Unbalancing Strike.",
            "Follow the deterministic arena/gauntlet/phase-two tank position and let Unbalancing Strike logic handle its tank reaction.",
            "Keep the active split stable while the encounter strategy moves the raid between arena/gauntlet/phase-two roles.",
            "Stay with the assigned arena or gauntlet group, follow marked targets, then move to the phase-two formation.",
            "Bots have arena positioning, gauntlet positioning, phase-two positioning, target marking and Unbalancing Strike actions.",
            "Group split/target decisions come from deterministic code or the human plan, never from free-form generation."
        },
        {
            "Ulduar", "Mimiron", {"mimiron", "mimi"}, Readiness::GuildReady,
            "ulduar",
            "A heavily scripted encounter with Shock Blast, Laser Barrage, phase positioning, Rapid Burst, Aerial Command Unit, Rocket Strike and phase-four target actions.",
            "Use the phase-specific tank position and move immediately when Shock Blast/Laser Barrage logic fires.",
            "Follow phase positioning while keeping mechanic targets stable; do not stand through the strategy's emergency movement.",
            "Move for Shock Blast, Laser Barrage and Rocket Strike; follow the phase target, including Aerial Command Unit/phase-four marking.",
            "Bots run dedicated actions for Shock Blast, P3Wx2 Laser Barrage, phase-one positioning, Rapid Burst, Aerial Command Unit, Rocket Strike and phase-four target marking.",
            "A pinned 'cheat' action also exists upstream for encounter reliability. The raid leader may state that assistance exists but must not invent what it does."
        },
        {
            "Ulduar", "General Vezax", {"vezax", "general vezax"}, Readiness::GuildReady,
            "ulduar",
            "Vezax strategy covers Shadow Crash, Mark of the Faceless and shadow-resistance behavior.",
            "Keep Vezax controlled while allowing ranged/mechanic targets to execute their deterministic movement.",
            "Watch the active mechanic targets and remain clear of their movement path.",
            "React to Shadow Crash and Mark of the Faceless through the strategy movement instead of staying planted.",
            "Bots run dedicated Shadow Crash and Mark of the Faceless actions plus shadow-resistance support.",
            "An upstream Vezax reliability helper/cheat action also exists; chat must not fabricate its internals."
        },
        {
            "Ulduar", "Yogg-Saron", {"yogg", "yogg saron", "yogg-saron", "sara"}, Readiness::GuildReady,
            "ulduar",
            "The pinned strategy has extensive deterministic handling for guardians/clouds, Sanity, Death Orbs, Malady, Brain Link, portals, illusion rooms, Lunatic Gaze and phase-three positioning.",
            "Follow the phase/guardian position and let the encounter strategy own portal/realm movement rather than forcing a conventional static tank plan.",
            "Keep the active group stable while obeying Malady/Brain Link/Lunatic Gaze movement and portal transitions.",
            "Follow marked targets, Brain Link movement, portal/illusion-room actions and turn/move for Lunatic Gaze when the strategy triggers it.",
            "Bots position guardians, manage Sanity/Death Orb/Malady/Brain Link, enter/exit portals, navigate illusion rooms, avoid Lunatic Gaze and take phase-three positions.",
            "Several upstream reliability/cheat helpers are present for clouds/floor/room movement. The voice layer never invents mechanics around them."
        },
        {
            "Ulduar", "Algalon the Observer", {"algalon", "observer"}, Readiness::NotReady,
            "none",
            "No Algalon-specific action block is present in the current pinned Ulduar strategy registration.",
            "Use a human-led tank plan.",
            "Use a human-led healing plan.",
            "Use a human-led target/movement plan.",
            "No encounter-specific Playerbots automation is claimed for Algalon by this integration.",
            "NOT READY for hands-off guild raiding until deterministic Algalon support is present and validated."
        },

        // Ruby Sanctum is unusually strong in the current pinned tree: triggers plus safety
        // multipliers exist for the minibosses and Halion's realm mechanics.
        {
            "The Ruby Sanctum", "Baltharus the Warborn", {"baltharus", "baltharus the warborn"}, Readiness::GuildReady,
            "ruby-sanctum",
            "Baltharus has explicit Brand handling plus tank, front-avoidance and healer positioning.",
            "Use the coded tank position and keep his front away from non-tanks.",
            "Use the dedicated healer position and respect Brand safety behavior.",
            "Stay out of the front and let Brand safety/positioning multipliers suppress unsafe actions.",
            "Bots run Brand, tank-position, avoid-front and healer-position actions with a Brand safety multiplier.",
            "The deterministic multiplier is the safety gate; chat never overrides it."
        },
        {
            "The Ruby Sanctum", "Saviana Ragefire", {"saviana", "ragefire", "saviana ragefire"}, Readiness::GuildReady,
            "ruby-sanctum",
            "Saviana strategy handles Conflagration, front avoidance, tank position and melee spread.",
            "Use the coded tank position and keep her front clear of the raid.",
            "Keep the affected player and tank stable while following the same Conflagration safety movement.",
            "Spread in melee as the strategy requires and react to Conflagration instead of tunneling.",
            "Bots run Conflagration, avoid-front, tank-position and melee-spread actions with safety multipliers.",
            "Conflagration target/safety decisions stay deterministic."
        },
        {
            "The Ruby Sanctum", "General Zarithrian", {"zarithrian", "general zarithrian"}, Readiness::GuildReady,
            "ruby-sanctum",
            "Zarithrian has deterministic add targeting and tank behavior, including a tank-swap safety multiplier.",
            "Hold the coded tank role and let the tank-swap logic own the swap instead of responding to a conversational guess.",
            "Keep both tank/add pressure stable while the marked target changes.",
            "Follow the marked add/boss target rather than splitting damage randomly.",
            "Bots mark/attack adds, run the Zarithrian tank action and use a tank-swap multiplier.",
            "Tank swap timing is code-owned."
        },
        {
            "The Ruby Sanctum", "Halion", {"halion", "the twilight destroyer"}, Readiness::GuildReady,
            "ruby-sanctum",
            "Halion has explicit start/tank positions, Combustion, Meteor, cone avoidance, add handling, portal transition, Twilight Cutter, Consumption and phase-two positioning.",
            "Follow the active realm's tank position and do not rotate the boss through the raid while cone/cutter movement executes.",
            "Keep both realm groups stable while reacting to Combustion/Consumption and the phase transition.",
            "Move for Combustion/Consumption, Meteor and Twilight Cutter; follow portal/realm target calls and avoid the boss cones.",
            "Bots handle Halion start/tank positions, Combustion, Meteor, cones, adds, portals, Cutter, Consumption and phase-two positioning; safety multipliers isolate realms and balance actions.",
            "The pinned strategy also contains HP-balance/realm-isolation multipliers. Realm composition is deterministic, not assigned by the LLM."
        },

        // Vault of Archavon coverage is intentionally conservative because the current strategy
        // registration is much smaller than the Ulduar/RS sets.
        {
            "Vault of Archavon", "Emalon the Storm Watcher", {"emalon", "storm watcher"}, Readiness::GuildReady,
            "vault-of-archavon",
            "Emalon has explicit Lightning Nova movement, boss marking, Overcharge targeting, floor recovery and nature resistance.",
            "Hold the selected target and create room for Lightning Nova movement.",
            "Keep tanks stable while immediately supporting the Overcharge target swap.",
            "Move for Lightning Nova and swap to the marked Overcharged add when the strategy identifies it.",
            "Bots react to Lightning Nova, mark the boss/Overcharge target, recover floor position and use nature resistance.",
            "The action name is misspelled 'lighting' upstream, but the deterministic trigger/action pair is registered and used."
        },
        {
            "Vault of Archavon", "Koralon the Flame Watcher", {"koralon", "flame watcher"}, Readiness::Playable,
            "vault-of-archavon",
            "The current VoA strategy registers fire-resistance support for Koralon but no larger encounter-specific movement package.",
            "Tank and position Koralon under a human-led plan.",
            "Keep the tank stable and supervise movement manually.",
            "Follow the human positioning plan; no comprehensive Koralon action set is claimed.",
            "Bots can use the registered Koralon fire-resistance action.",
            "PLAYABLE/CAVEAT until broader deterministic Koralon support is present."
        },
        {
            "Vault of Archavon", "Archavon the Stone Watcher", {"archavon", "stone watcher"}, Readiness::NotReady,
            "none",
            "No Archavon-specific trigger/action block is registered in the current pinned VoA strategy.",
            "Use a human-led plan.", "Use a human-led plan.", "Use a human-led plan.",
            "No encounter-specific Playerbots automation is claimed.",
            "NOT READY for hands-off guild raiding."
        },
        {
            "Vault of Archavon", "Toravon the Ice Watcher", {"toravon", "ice watcher"}, Readiness::NotReady,
            "none",
            "No Toravon-specific trigger/action block is registered in the current pinned VoA strategy.",
            "Use a human-led plan.", "Use a human-led plan.", "Use a human-led plan.",
            "No encounter-specific Playerbots automation is claimed.",
            "NOT READY for hands-off guild raiding."
        },
    };
}
}

std::vector<Encounter> const& SupplementalEncounters()
{
    static std::vector<Encounter> const encounters = BuildSupplemental();
    return encounters;
}

Encounter const* FindSupplemental(std::string const& text)
{
    std::string const wanted = NormalizeExtra(text);
    if (wanted.empty())
        return nullptr;

    for (Encounter const& encounter : SupplementalEncounters())
    {
        if (wanted == NormalizeExtra(encounter.boss))
            return &encounter;
        for (std::string const& alias : encounter.aliases)
            if (wanted == NormalizeExtra(alias))
                return &encounter;
    }

    Encounter const* match = nullptr;
    for (Encounter const& encounter : SupplementalEncounters())
    {
        bool found = wanted.find(NormalizeExtra(encounter.boss)) != std::string::npos;
        if (!found)
        {
            for (std::string const& alias : encounter.aliases)
            {
                std::string const normalizedAlias = NormalizeExtra(alias);
                if (normalizedAlias.size() >= 4 && wanted.find(normalizedAlias) != std::string::npos)
                {
                    found = true;
                    break;
                }
            }
        }
        if (!found)
            continue;
        if (match)
            return nullptr;
        match = &encounter;
    }
    return match;
}

Encounter const* FindAny(std::string const& text)
{
    if (Encounter const* encounter = Find(text))
        return encounter;
    return FindSupplemental(text);
}
}

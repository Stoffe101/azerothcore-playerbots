#include "PBChatterRaidLeader.h"

#include "Config.h"
#include "Creature.h"
#include "Group.h"
#include "Log.h"
#include "Map.h"
#include "PBAIGuildStore.h"
#include "PBChatterConfig.h"
#include "PBChatterQueue.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "ScriptMgr.h"
#include "WorldSession.h"

#include <algorithm>
#include <cctype>
#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>

namespace
{
bool g_raidLeaderEnable = true;
bool g_raidLeaderUseOllama = true;
bool g_raidLeaderBriefOnPull = true;
bool g_raidLeaderRetryAdvice = true;

struct RaidProfile
{
    uint32 mapId;
    char const* bossKey;
    char const* brief;
    char const* retry;
};

struct PullState
{
    bool inCombat = false;
    uint32 failures = 0;
    uint32 lastSpeakerGuid = 0;
};

std::unordered_map<uint64, PullState> g_pullStates;

// Every fact below is deliberately derived from an implemented Playerbots raid strategy. The
// module stays silent when no validated profile exists instead of filling gaps with model guesses.
std::vector<RaidProfile> const g_profiles = {
    // Karazhan, map 532.
    {532, "attumenthehuntsman", "Attumen: tanks control both phases; hold DPS through the mount transition so threat can settle.", "Give the tanks the transition cleanly and do not race threat while Attumen remounts."},
    {532, "moroes", "Moroes: use the marked add priority before tunneling Moroes; keep crowd control and focus disciplined.", "Stick to the assigned add order instead of splitting damage."},
    {532, "maidenofvirtue", "Maiden: tank holds position; ranged spread between pillars for Holy Wrath. Shamans can cover Holy Fire with Grounding Totem.", "Fix ranged spacing first; chained Holy Wrath is the avoidable failure point."},
    {532, "thebigbadwolf", "Big Bad Wolf: tank fixes boss position; Little Red Riding Hood target runs away until the chase ends.", "If Red gets caught, create distance immediately rather than trying to tank the chase."},
    {532, "romulo", "Romulo and Julianne: follow the marked target once both are active so damage is coordinated.", "Stop splitting DPS after the revival and follow the marked target."},
    {532, "julianne", "Romulo and Julianne: follow the marked target once both are active so damage is coordinated.", "Stop splitting DPS after the revival and follow the marked target."},
    {532, "thecrone", "Wizard of Oz: follow target priority; fire users exploit Strawman's fire vulnerability before finishing the remaining actors.", "Use the target order and put fire damage into Strawman when available."},
    {532, "thecurator", "Curator: tank holds position, ranged spread, and DPS switches to marked Astral Flares instead of tunneling the boss.", "Clean up Astral Flares quickly and restore ranged spacing."},
    {532, "terestianillhoof", "Illhoof: Kil'rek/chains take priority when marked; avoid wasting damage on low-value imp targets.", "Break the chains on priority and keep DPS on the marked encounter target."},
    {532, "shadeofaran", "Aran: run out for Arcane Explosion, stop moving during Flame Wreath, and swap to marked elementals when they appear.", "Flame Wreath means stop moving; Arcane Explosion means get out. Do not mix those responses."},
    {532, "netherspite", "Netherspite: assigned players block red/blue/green beams; everyone else avoids beams and void zones, including banish phase.", "Hold beam assignments and stop crossing beams or standing in void zones."},
    {532, "princemalchezaar", "Malchezaar: tanks position him safely; non-tanks avoid infernals, and Enfeebled players prioritize hazard avoidance.", "Enfeeble plus infernal positioning is lethal; preserve safe space before chasing damage."},
    {532, "nightbane", "Nightbane: tanks anchor ground phases; ranged coordinate movement, then stack/move correctly during flight and keep pets controlled.", "Reset the ground/flight positioning and keep pets from chasing the airborne boss."},

    // Gruul's Lair, map 565.
    {565, "highkingmaulgar", "Maulgar: separate tank jobs for Maulgar, Olm, Blindeye, Krosh and Kiggler; follow the assigned kill order and avoid Whirlwind.", "Re-establish every tank assignment before DPS starts, then follow the kill order."},
    {565, "gruulthedragonkiller", "Gruul: tanks hold boss position; ranged stay spread and the whole raid increases separation for incoming Shatter.", "Spread earlier for Shatter and do not collapse back until it resolves."},

    // Magtheridon's Lair, map 544.
    {544, "magtheridon", "Magtheridon: tanks split the channelers and follow kill order; CC Burning Abyssals, spread on boss, avoid debris, and assigned players handle cubes for Blast Nova.", "The cube assignment is the wipe check: keep five interrupters ready and do not lose the channeler order."},

    // Serpentshrine Cavern, map 548.
    {548, "hydrosstheunstable", "Hydross: frost and nature tanks own their phases; stop DPS on transitions, pick up elementals, and spread during Water Tomb danger.", "Respect the aggro reset: stop damage on the phase change and let the correct resistance tank establish threat."},
    {548, "thelurkerbelow", "Lurker: main tank holds position, ranged spread for Geyser, rotate around Spout, and tanks pick up adds while he is submerged.", "Spout movement and ranged spacing come before DPS; clean up submerge adds."},
    {548, "leotherastheblind", "Leotheras: warlock tanks demon form; melee tanks back off there, avoid Whirlwind, kill your Inner Demon, and respect phase threat resets.", "Do not carry threat across form changes; demon form belongs to the warlock tank."},
    {548, "fathomlordkarathress", "Karathress: boss and three advisors have separate tanks, Caribdis tank gets dedicated healing, and DPS follows the assigned kill order.", "Rebuild the four tank assignments and kill one marked target at a time."},
    {548, "morogrimtidewalker", "Morogrim: main tank fixes boss position; ranged reposition for the Water Globule phase and let threat settle on pull.", "Use the phase-two ranged position and stop dragging globules through the group."},
    {548, "ladyvashj", "Vashj: tank center, ranged spread, Static Charge leaves the group; phase two handles cores/add priority, Striders go to the assigned tank, and avoid toxic spores.", "Prioritize clean core handoffs and Strider control; Static Charge must leave the raid."},

    // Tempest Keep, map 550.
    {550, "alar", "Al'ar: tanks/melee move with platform changes, ranged work from below, assist tanks collect Embers, jump for Flame Quills, then swap tanks and avoid fire in phase two.", "Platform movement and Flame Quills are non-negotiable; reset positions before pushing damage."},
    {550, "voidreaver", "Void Reaver: tanks anchor him; ranged stay spread and move from incoming Arcane Orbs while threat adjusts after Knock Away.", "Restore ranged spacing and give tanks room to recover threat after Knock Away."},
    {550, "highastromancersolarian", "Solarian: leave room around melee, Wrath target moves away, stack for add AOE after vanish, kill priests, and protect the tank from fear.", "Wrath must leave the group; after vanish, stack and kill the priest adds quickly."},
    {550, "kaelthassunstrider", "Kael'thas: respect advisor tank roles/kill order, loot and use legendary weapons, handle phoenixes, break mind control, burn Shock Barrier for Pyroblast, and spread in Gravity Lapse.", "Do not improvise the phases: advisor roles, weapon use, barrier break and Gravity Lapse spacing must all stay intact."},

    // Hyjal Summit, map 534.
    {534, "ragewinterchill", "Winterchill: tank fixes boss; ranged spread for Death and Decay and melee immediately leave any Death and Decay under them.", "Move out of Death and Decay first, then resume damage."},
    {534, "anetheron", "Anetheron: main tank holds boss, ranged spread for Carrion Swarm, and the assist tank keeps Infernals away while DPS follows priority.", "Keep Infernals on the assigned tank and away from the raid."},
    {534, "kazrogal", "Kaz'rogal: tanks hold the front; ranged spread with an escape path, low-mana players take defensive measures, and use shadow protection for Mark damage.", "Low-mana players must separate before Mark turns them into a raid problem."},
    {534, "azgalor", "Azgalor: tank positions boss, ranged disperse, melee leave Rain of Fire, Doomed players move to the Doomguard tank, and ranged kill Doomguards.", "Doomed players go to the Doomguard tank; do not die inside the raid."},
    {534, "archimonde", "Archimonde: tank holds initial position; use fear protection, spread for Air Burst, and treat Doomfire avoidance as top priority.", "Fear control and Doomfire spacing matter more than squeezing in another cast."},

    // Black Temple, map 564.
    {564, "highwarlordnajentus", "Naj'entus: tanks position boss, ranged spread for Needle Spine, free Impaled players, then use a spine to break Tidal Shield.", "Free the Impaled player promptly and save a spine for Tidal Shield."},
    {564, "supremus", "Supremus: ranged stay dispersed; fixated players kite and everyone avoids nearby volcanoes through the phase changes.", "If fixated, kite instead of trading hits; keep the raid out of volcanoes."},
    {564, "shadeofakama", "Shade of Akama: melee prioritize the channelers so phase two starts cleanly.", "Stop padding on other targets and remove the channelers."},
    {564, "terongorefiend", "Teron: tanks anchor boss, ranged use balcony positions; Shadow of Death target moves to the corner and controls the spirit to kill constructs after death.", "The Shadow of Death player must die in the planned corner and use the spirit on constructs."},
    {564, "gurtoggbloodboil", "Gurtogg: tanks position boss, ranged groups rotate Bloodboil, and everyone gives the Fel Rage target space.", "Fix the Bloodboil group rotation and stop crowding the Fel Rage target."},
    {564, "essenceofsuffering", "Reliquary: during Suffering, manage distance/fixation and remember normal healing is disabled, so healers contribute damage.", "Treat Suffering as a no-healing phase and control who is closest."},
    {564, "essenceofdesire", "Reliquary: on Desire, handle Rune Shield and Deadens with the strategy's spell-steal/reflect responses.", "Do not let Rune Shield and Deaden run unchecked."},
    {564, "essenceofanger", "Reliquary: phase changes reset threat, so let the main tank establish aggro before the raid commits.", "Pause after the phase change and rebuild threat before full DPS."},
    {564, "mothershahraz", "Shahraz: tanks/ranged use the pillar positions; Fatal Attraction targets run away from the raid to break safely.", "Fatal Attraction players move out immediately and nobody chases them."},
    {564, "gathiostheshatterer", "Illidari Council: each council member has an assigned tank, Zerevor uses a mage tank with dedicated healing, ranged spread, and DPS follows assignments.", "Re-establish all council tank and DPS assignments before attacking again."},
    {564, "ladymalande", "Illidari Council: each council member has an assigned tank, Zerevor uses a mage tank with dedicated healing, ranged spread, and DPS follows assignments.", "Re-establish all council tank and DPS assignments before attacking again."},
    {564, "verasdarkshadow", "Illidari Council: each council member has an assigned tank, Zerevor uses a mage tank with dedicated healing, ranged spread, and DPS follows assignments.", "Re-establish all council tank and DPS assignments before attacking again."},
    {564, "highnethermancerzerevor", "Illidari Council: each council member has an assigned tank, Zerevor uses a mage tank with dedicated healing, ranged spread, and DPS follows assignments.", "Re-establish all council tank and DPS assignments before attacking again."},
    {564, "illidanstormrage", "Illidan: tank handles Flame Crash movement; Parasite leaves group, assist tanks handle Flames of Azzinoth, spread for splash, warlock tanks demon form, and adds take priority.", "Keep phase roles intact: Parasite out, Flames on assist tanks, warlock on demon form, adds before boss."},

    // Zul'Aman, map 568.
    {568, "akilzon", "Akil'zon: tank holds boss, ranged spread for Static Disruption, then everyone moves into the Eye of the Storm for Electrical Storm.", "Pre-position for Electrical Storm and collapse into the safe eye together."},
    {568, "nalorakk", "Nalorakk: tanks manage form changes and ranged stay spread for Surge.", "Make the tank handoff around form changes clean and keep ranged separated."},
    {568, "janalai", "Jan'alai: tank positions boss, ranged spread for Flame Breath, avoid Fire Bombs, and follow the marked Hatcher target plan.", "Fire Bomb survival first; keep Hatcher handling deliberate rather than chaotic."},
    {568, "halazzi", "Halazzi: main tank holds boss, assist tank takes Spirit Lynx, and DPS follows the assigned priority.", "Keep Spirit Lynx on the assist tank and use one DPS target at a time."},
    {568, "hexlordmalacrass", "Malacrass: follow add/boss kill order, run from Whirlwind, casters stop into Spell Reflection, and move away from Freezing Trap.", "Stop casting into Spell Reflection and keep the target order intact."},
    {568, "zuljin", "Zul'jin: tank regains boss after phase changes; avoid troll Whirlwind and eagle Cyclones, then ranged spread for dragonhawk AOE.", "Treat each form change as a fresh positioning/threat reset instead of carrying the old formation forward."},

    // Naxxramas, map 533. Patchwerk/Gothik are intentionally omitted because their strategy
    // entries are absent/commented in the validated source we used for this knowledge base.
    {533, "anubrekhan", "Anub'Rekhan: use the encounter-specific tank/group positioning; do not freestyle the room layout.", "Reset to the strategy positions before the next engage."},
    {533, "grandwidowfaerlina", "Faerlina: keep the raid moving out of dangerous AOE while maintaining the encounter target plan.", "The avoidable loss is standing in AOE; clean movement before damage."},
    {533, "maexxna", "Maexxna: non-tanks use the rear flank and the raid avoids encounter AOE.", "Re-form behind the boss and stop eating AOE."},
    {533, "noththeplaguebringer", "Noth: no custom pre-pull mechanic is asserted beyond the normal Playerbots encounter behavior; keep normal tank/DPS discipline.", "Use normal threat and add discipline; this profile intentionally does not invent extra mechanics."},
    {533, "heigantheunclean", "Heigan: melee and ranged have dedicated dance positioning; everyone follows the safety-dance movement instead of normal combat formation.", "The dance is the fight. Follow the safe-position sequence and sacrifice casts before movement."},
    {533, "loatheb", "Loatheb: use the implemented Loatheb positioning and target-selection plan rather than generic formation.", "Return to the encounter positions and target plan before retrying."},
    {533, "instructorrazuvious", "Razuvious: tanks use the Obedience Crystal handling; non-tanks follow the encounter target logic.", "Crystal control is the assignment. Make sure the tank role owns it before pull."},
    {533, "gothiktheharvester", "Gothik: this fork has no validated custom pre-pull mechanic profile for him, so the raid leader will not invent one.", "Use WeakAuras/known encounter knowledge here; no unvalidated bot claim is being added."},
    {533, "highlordmograine", "Four Horsemen: assigned attract/tank roles alternate while the rest of the raid attacks the encounter targets in order.", "Do not collapse the assignments; restore the alternate attractors and target order."},
    {533, "thane korthazz", "Four Horsemen: assigned attract/tank roles alternate while the rest of the raid attacks the encounter targets in order.", "Do not collapse the assignments; restore the alternate attractors and target order."},
    {533, "ladyblaumeux", "Four Horsemen: assigned attract/tank roles alternate while the rest of the raid attacks the encounter targets in order.", "Do not collapse the assignments; restore the alternate attractors and target order."},
    {533, "sirezeliek", "Four Horsemen: assigned attract/tank roles alternate while the rest of the raid attacks the encounter targets in order.", "Do not collapse the assignments; restore the alternate attractors and target order."},
    {533, "patchwerk", "Patchwerk: no active custom Playerbots mechanic trigger is validated in the pinned strategy, so use normal tank/DPS discipline without invented instructions.", "Keep the retry simple: threat, healing and positioning. No extra mechanic is asserted here."},
    {533, "grobbulus", "Grobbulus: Injection target moves away; ranged stay behind boss and the tank rotates him so poison clouds are laid around the room edge.", "Injection must leave the group and clouds must stay controlled around the room."},
    {533, "gluth", "Gluth: use encounter positioning/target selection, slow the zombie adds, and tank-swap/taunt when the main tank is stacked with Mortal Wound.", "Slow the zombies and make the Mortal Wound tank handoff on time."},
    {533, "thaddius", "Thaddius: tanks handle the paired adds, move to the platform for transition, then everyone follows polarity positioning on the boss.", "Polarity movement must be immediate; do not cross or ignore your assigned side."},
    {533, "sapphiron", "Sapphiron: use separate ground and flight positioning plans; do not keep normal formation when he takes off.", "Reset the raid to the correct ground/flight positions before retrying."},
    {533, "kelthuzad", "Kel'Thuzad: follow the implemented encounter positioning and target-selection logic rather than generic stacking.", "Re-establish spacing and the encounter target plan before the next pull."},

    // Obsidian Sanctum, map 615.
    {615, "sartharion", "Sartharion: tank uses dedicated position; avoid Twilight Fissures and Flame Tsunami, melee stay on the rear flank, follow target priority, and use twilight portals when assigned.", "Fissure/Tsunami survival first, then restore target priority and portal assignments."},

    // Eye of Eternity, map 616.
    {616, "malygos", "Malygos: follow the dedicated positioning/target plan; when the raid transitions to drakes, everyone uses the implemented flying and drake-combat behavior.", "Do not treat the drake phase like normal character combat; complete the vehicle transition together."},

    // Onyxia's Lair, map 249.
    {249, "onyxia", "Onyxia: stay off the tail and eggs; in air phase move for Deep Breath, spread for Fireball splash, and kill spawned whelps.", "Tail/eggs on the ground, Deep Breath/spread/whelps in the air. Keep the phases clean."},

    // Vault of Archavon, map 624. Only mechanics actually present in the partial strategy are stated.
    {624, "emalonthestormwatcher", "Emalon: move for Lightning Nova, follow the marked target/Overcharge handling, and use nature resistance support where available.", "Overcharge target handling and Lightning Nova movement are the validated priorities."},
    {624, "koralontheflamewatcher", "Koralon: the validated bot strategy provides fire-resistance support; no additional custom mechanic is asserted here.", "Use the normal encounter plan; this profile intentionally avoids inventing missing strategy behavior."},

    // Ulduar, map 603. The raid remains experimental in the Adventure Guide, but these facts are
    // grounded in the broad upstream strategy so manual/experimental runs still get safe briefs.
    {603, "flameleviathan", "Flame Leviathan: enter the encounter vehicles and fight through the implemented vehicle actions rather than normal class rotations.", "Make sure everyone is actually in the intended vehicles before re-engaging."},
    {603, "razorscale", "Razorscale: avoid Devouring Flames/Sentinel/Whirlwind, handle harpoons and the grounded phase, and tanks react to Fuse Armor.", "Harpoon/grounding flow and hazard movement come before DPS."},
    {603, "ignisthefurnacemaster", "Ignis: the validated bot strategy includes fire-resistance handling; keep normal tank formation and fire mitigation disciplined.", "Use the resistance support and avoid inventing extra movement beyond the encounter strategy."},
    {603, "assemblyofiron", "Iron Assembly: react to Lightning Tendrils and Overload, and use Rune of Power correctly while following the encounter target plan.", "Overload/Tendrils movement and Rune of Power use are the validated checks."},
    {603, "steelbreaker", "Iron Assembly: react to Lightning Tendrils and Overload, and use Rune of Power correctly while following the encounter target plan.", "Overload/Tendrils movement and Rune of Power use are the validated checks."},
    {603, "runemastermolgeim", "Iron Assembly: react to Lightning Tendrils and Overload, and use Rune of Power correctly while following the encounter target plan.", "Overload/Tendrils movement and Rune of Power use are the validated checks."},
    {603, "stormcallerbundir", "Iron Assembly: react to Lightning Tendrils and Overload, and use Rune of Power correctly while following the encounter target plan.", "Overload/Tendrils movement and Rune of Power use are the validated checks."},
    {603, "kologarn", "Kologarn: obey floor safety and Eye Beam movement, follow the marked DPS target, manage Rubble, and tanks react to Crunch Armor.", "Fix Eye Beam/floor movement and the Crunch Armor tank response before retrying."},
    {603, "auriaya", "Auriaya: the validated custom strategy mainly protects against unsafe floor/fall positions; keep normal encounter formation otherwise.", "Use the safe platform/floor positions and normal encounter discipline."},
    {603, "hodir", "Hodir: move to snowpacked icicles when required, keep moving/jumping against Biting Cold, and use frost resistance support.", "Biting Cold movement and safe icicle positioning are the wipe checks."},
    {603, "freya", "Freya: move from Nature Bombs, use resistance support, follow marked DPS targets, and move to Healing Spores when assigned.", "Nature Bomb movement and target priority first; use Healing Spores instead of ignoring them."},
    {603, "thorim", "Thorim: split correctly between gauntlet/arena roles, respect Unbalancing Strike and tank positioning, then switch to the phase-two formation.", "Restore the gauntlet/arena assignments and tank response before pulling again."},
    {603, "mimiron", "Mimiron: move for Laser Barrage, Shock Blast and Rocket Strike; follow phase-specific positions and target the Aerial Command Unit/phase-four marks as assigned.", "Movement mechanics first: Laser, Shock Blast and Rockets cannot be out-DPSed."},
    {603, "generalvezax", "Vezax: move for Shadow Crash, handle Mark of the Faceless, and use shadow-resistance support where available.", "Keep Mark away and use Shadow Crash movement correctly before chasing damage."},
    {603, "yoggsaron", "Yogg-Saron: manage Sanity, Malady and Brain Link; use guardian positions/target marks, portals and illusion-room movement, then avoid Lunatic Gaze in the final phases.", "Sanity/Brain Link/portal execution is the plan. Do not let normal formation override encounter movement."},

    // Icecrown Citadel, map 631.
    {631, "lordmarrowgar", "Marrowgar: tanks use the encounter position and DPS immediately follows the Bone Spike target handling.", "Fix tank position and swap to Bone Spikes immediately."},
    {631, "ladydeathwhisper", "Deathwhisper: ranged use assigned positions, move from Dark Reckoning, prioritize adds and shades according to the implemented target logic.", "Add/shade priority and Dark Reckoning movement must be cleaner than the last pull."},
    {631, "deathbringersaurfang", "Saurfang: tanks use the dedicated position and taunt response for Rune of Blood; DPS follows the Blood Beast add plan.", "Make the Rune of Blood tank handoff and kill the adds before they become a raid problem."},
    {631, "festergut", "Festergut: use the group formation, move correctly for spores, and avoid Malleable Goo.", "Spore positioning and Goo avoidance first; then resume the stack."},
    {631, "rotface", "Rotface: tanks/group use encounter positions, move from ooze explosions, and avoid Vile Gas.", "Do not drag explosion/Vile Gas through the formation; reset positions after each mechanic."},
    {631, "professorputricide", "Putricide: prioritize Volatile Ooze/Gas Cloud, avoid Growing Ooze Puddles and Malleable Goo, handle Mutated Plague, and keep the abomination role active.", "Add priority and puddle/Goo movement come first; keep the abomination assignment covered."},
    {631, "princekeleseth", "Blood Prince Council: Keleseth has a dedicated tank, main tank handles the others, and the raid responds to Empowered Vortex, Kinetic Bomb and Ball of Flame.", "Restore Keleseth tanking and Kinetic Bomb/Vortex responsibilities before retrying."},
    {631, "princetaldaram", "Blood Prince Council: Keleseth has a dedicated tank, main tank handles the others, and the raid responds to Empowered Vortex, Kinetic Bomb and Ball of Flame.", "Restore Keleseth tanking and Kinetic Bomb/Vortex responsibilities before retrying."},
    {631, "princevalanar", "Blood Prince Council: Keleseth has a dedicated tank, main tank handles the others, and the raid responds to Empowered Vortex, Kinetic Bomb and Ball of Flame.", "Restore Keleseth tanking and Kinetic Bomb/Vortex responsibilities before retrying."},
    {631, "bloodqueenlanathel", "Lana'thel: hold the encounter group positions, Pact targets resolve together, and Vampiric Bite assignments take priority when due.", "Do not miss the Bite assignment and resolve Pact movement cleanly."},
    {631, "valithriadreamwalker", "Valithria: split encounter roles, kite dangerous zombies, heal Dreamwalker, and assigned healers use portals/Dream Clouds.", "Keep portal healers on portal/cloud duty and control the zombie threat outside."},
    {631, "sindragosa", "Sindragosa: follow group positions; Beacon players move correctly, react to Blistering Cold/Frost Bomb, and manage Unchained Magic, Chilled to the Bone and Mystic Buffet.", "Reset debuff discipline: Beacon placement, Blistering Cold movement and Buffet management are the checks."},
    {631, "thelichking", "Lich King: move for Shadow Trap, handle Necrotic Plague, use transition/Winter positions, follow add targets, and avoid spirit bombs.", "Shadow Trap/Plague execution and transition positions must be clean before the next pull."},

    // Ruby Sanctum, map 724. Experimental content, but the listed strategy is validated.
    {724, "baltharusthewarborn", "Baltharus: use tank/healer positions, avoid his front, and Brand targets follow the encounter handling.", "Restore tank/healer positions and keep Brand handling clean."},
    {724, "savianaragefire", "Saviana: tank fixes position, avoid her front, melee spread, and Conflagration targets follow the encounter movement.", "Conflagration movement and melee spacing are the validated checks."},
    {724, "generalzarithrian", "Zarithrian: tanks follow the swap/position plan while DPS handles the spawned adds by priority.", "Make the tank swap and add pickup before pushing boss damage."},
    {724, "halion", "Halion: use phase-specific tank positions, move Combustion/Consumption correctly, avoid Meteor/cones, take portals on transition, and avoid Twilight Cutter in the shadow realm.", "Realm transition and Cutter/Combustion handling come first; restore phase positions before retrying."},
};

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

RaidProfile const* FindProfile(Creature const* boss)
{
    if (!boss)
        return nullptr;

    uint32 const mapId = boss->GetMapId();
    std::string const key = Normalize(boss->GetName());
    for (RaidProfile const& profile : g_profiles)
        if (profile.mapId == mapId && key == profile.bossKey)
            return &profile;
    return nullptr;
}

uint64 PullKey(Creature const* boss)
{
    if (!boss || !boss->GetMap())
        return 0;
    return (uint64(boss->GetMap()->GetInstanceId()) << 32) | uint64(boss->GetEntry());
}

Player* FindRaidSpeaker(Creature* boss, Player*& anchorHuman)
{
    anchorHuman = nullptr;
    if (!boss || !boss->GetMap())
        return nullptr;

    Map::PlayerList const& players = boss->GetMap()->GetPlayers();
    for (auto itr = players.begin(); itr != players.end(); ++itr)
    {
        Player* human = itr->GetSource();
        if (!human || !human->IsInWorld() || !human->GetSession() || human->GetSession()->IsBot())
            continue;

        Group* group = human->GetGroup();
        if (!group || !group->isRaidGroup())
            continue;

        for (auto botItr = players.begin(); botItr != players.end(); ++botItr)
        {
            Player* bot = botItr->GetSource();
            if (!bot || bot == human || bot->GetGroup() != group || !GET_PLAYERBOT_AI(bot))
                continue;

            anchorHuman = human;
            return bot;
        }
    }

    return nullptr;
}

std::string BuildGroundedLine(Creature* boss, RaidProfile const& profile, uint32 failures)
{
    std::string line;
    if (failures && g_raidLeaderRetryAdvice)
    {
        line = "Retry " + std::to_string(failures + 1) + ": " + profile.retry;
        if (line.size() < 150)
            line += " Plan: " + std::string(profile.brief);
    }
    else
        line = std::string("Pull brief - ") + boss->GetName() + ": " + profile.brief;

    return line;
}

void SendGroundedBrief(Creature* boss, RaidProfile const& profile, PullState& state)
{
    Player* human = nullptr;
    Player* speaker = FindRaidSpeaker(boss, human);
    if (!speaker || !human)
        return;

    PlayerbotAI* ai = GET_PLAYERBOT_AI(speaker);
    if (!ai)
        return;

    std::string const fallback = BuildGroundedLine(boss, profile, state.failures);
    state.lastSpeakerGuid = speaker->GetGUID().GetCounter();

    uint64 const eventId = PBAIGuildStore::RecordEvent(
        state.failures ? "raid_retry_brief" : "raid_pull_brief",
        state.lastSpeakerGuid,
        human->GetGUID().GetCounter(),
        boss->GetMapId(),
        boss->GetEntry(),
        fallback);
    PBAIGuildStore::AddMemory(
        state.lastSpeakerGuid, eventId, "raid_leading", 60, 2, boss->GetEntry(), fallback);

    if (!g_raidLeaderUseOllama || !g_PBChatEnable)
    {
        ai->SayToRaid(fallback);
        return;
    }

    PBChatJob job{};
    job.botGuid = speaker->GetGUID().GetCounter();
    job.playerGuid = human->GetGUID().GetCounter();
    job.playerName.clear();
    job.channel = PBChatChannel::Raid;
    job.systemPrompt =
        "You are the raid leader in WoW. Rewrite ONLY the validated plan supplied by the server into one short, natural raid-chat line. "
        "Do not add, infer, rename, or invent mechanics, spells, timings, percentages, assignments, phases, or tactics. "
        "Do not omit a role assignment that appears in the supplied plan. No markdown. If uncertain, copy the supplied fallback nearly verbatim.";
    job.prompt =
        std::string("Boss: ") + boss->GetName() + "\nVALIDATED SERVER PLAN:\n" + fallback +
        "\nReturn one concise raid-chat line containing no facts beyond VALIDATED SERVER PLAN.";
    job.playerMessage.clear();
    job.fallbackReply = fallback;
    job.storeMemory = false;
    job.ambient = false;
    PBChatterQueue::Submit(std::move(job));
}

void MarkFailedPull(Creature* boss)
{
    if (!boss || !boss->IsAlive())
        return;

    RaidProfile const* profile = FindProfile(boss);
    if (!profile)
        return;

    uint64 const key = PullKey(boss);
    auto itr = g_pullStates.find(key);
    if (itr == g_pullStates.end() || !itr->second.inCombat)
        return;

    itr->second.inCombat = false;
    ++itr->second.failures;

    PBAIGuildStore::RecordEvent(
        "raid_failed_pull",
        itr->second.lastSpeakerGuid,
        0,
        boss->GetMapId(),
        boss->GetEntry(),
        std::string("Failed pull on ") + boss->GetName() + "; retry count now " + std::to_string(itr->second.failures) + ".");
}

class PBChatterRaidLeaderWorldScript final : public WorldScript
{
public:
    PBChatterRaidLeaderWorldScript() : WorldScript("PBChatterRaidLeaderWorldScript") { }

    void OnAfterConfigLoad(bool /*reload*/) override
    {
        g_raidLeaderEnable = sConfigMgr->GetOption<bool>("PlayerbotChatter.RaidLeaderEnable", true);
        g_raidLeaderUseOllama = sConfigMgr->GetOption<bool>("PlayerbotChatter.RaidLeaderUseOllama", true);
        g_raidLeaderBriefOnPull = sConfigMgr->GetOption<bool>("PlayerbotChatter.RaidLeaderBriefOnPull", true);
        g_raidLeaderRetryAdvice = sConfigMgr->GetOption<bool>("PlayerbotChatter.RaidLeaderRetryAdvice", true);
    }
};

class PBChatterRaidLeaderUnitScript final : public UnitScript
{
public:
    PBChatterRaidLeaderUnitScript() : UnitScript("PBChatterRaidLeaderUnitScript") { }

    void OnUnitEnterCombat(Unit* unit, Unit* /*victim*/) override
    {
        if (!g_raidLeaderEnable || !g_raidLeaderBriefOnPull)
            return;

        Creature* boss = unit ? unit->ToCreature() : nullptr;
        if (!boss || !boss->IsDungeonBoss() || !boss->GetMap() || !boss->GetMap()->IsRaid())
            return;

        RaidProfile const* profile = FindProfile(boss);
        if (!profile)
            return;

        PullState& state = g_pullStates[PullKey(boss)];
        if (state.inCombat)
            return;

        state.inCombat = true;
        SendGroundedBrief(boss, *profile, state);
    }

    void OnUnitEnterEvadeMode(Unit* unit, uint8 /*evadeReason*/) override
    {
        Creature* boss = unit ? unit->ToCreature() : nullptr;
        if (boss && boss->IsDungeonBoss() && boss->GetMap() && boss->GetMap()->IsRaid())
            MarkFailedPull(boss);
    }

    void OnUnitExitCombat(Unit* unit) override
    {
        Creature* boss = unit ? unit->ToCreature() : nullptr;
        if (boss && boss->IsDungeonBoss() && boss->GetMap() && boss->GetMap()->IsRaid())
            MarkFailedPull(boss);
    }

    void OnUnitDeath(Unit* unit, Unit* /*killer*/) override
    {
        Creature* boss = unit ? unit->ToCreature() : nullptr;
        if (!boss || !boss->IsDungeonBoss() || !boss->GetMap() || !boss->GetMap()->IsRaid())
            return;
        g_pullStates.erase(PullKey(boss));
    }
};

class PBChatterRaidLeaderMapScript final : public AllMapScript
{
public:
    PBChatterRaidLeaderMapScript() : AllMapScript("PBChatterRaidLeaderMapScript") { }

    void OnDestroyMap(Map* map) override
    {
        if (!map || !map->GetInstanceId())
            return;

        uint32 const instanceId = map->GetInstanceId();
        for (auto itr = g_pullStates.begin(); itr != g_pullStates.end(); )
        {
            if (uint32(itr->first >> 32) == instanceId)
                itr = g_pullStates.erase(itr);
            else
                ++itr;
        }
    }
};
}

void AddPBChatterRaidLeaderScripts()
{
    LOG_INFO("server.loading", "[RaidLeader] Registering grounded pre-pull and retry briefs; mid-fight callouts are left to WeakAuras.");
    new PBChatterRaidLeaderWorldScript();
    new PBChatterRaidLeaderUnitScript();
    new PBChatterRaidLeaderMapScript();
}

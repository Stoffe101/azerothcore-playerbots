GroupComposerData = GroupComposerData or {}
local D = GroupComposerData

D.VERSION = "0.3.0"

D.ROLE = {
    TANK = "TANK",
    HEALER = "HEALER",
    DPS = "DPS",
}

D.ROLE_ORDER = { "TANK", "HEALER", "DPS" }

D.ROLE_LABEL = {
    TANK = "Tank",
    HEALER = "Healer",
    DPS = "DPS",
}

D.ROLE_ICON = {
    TANK = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
    HEALER = "Interface\\Icons\\Spell_Holy_GreaterHeal",
    DPS = "Interface\\Icons\\Ability_DualWield",
}

D.CLASS_ORDER = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
    "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "DRUID",
}

D.CLASS_ID = {
    WARRIOR = 1,
    PALADIN = 2,
    HUNTER = 3,
    ROGUE = 4,
    PRIEST = 5,
    DEATHKNIGHT = 6,
    SHAMAN = 7,
    MAGE = 8,
    WARLOCK = 9,
    DRUID = 11,
}

D.CLASS_LABEL = {
    WARRIOR = "Warrior",
    PALADIN = "Paladin",
    HUNTER = "Hunter",
    ROGUE = "Rogue",
    PRIEST = "Priest",
    DEATHKNIGHT = "Death Knight",
    SHAMAN = "Shaman",
    MAGE = "Mage",
    WARLOCK = "Warlock",
    DRUID = "Druid",
}

D.CLASS_ROLE = {
    TANK = { WARRIOR = true, PALADIN = true, DEATHKNIGHT = true, DRUID = true },
    HEALER = { PALADIN = true, PRIEST = true, SHAMAN = true, DRUID = true },
    DPS = {
        WARRIOR = true, PALADIN = true, HUNTER = true, ROGUE = true, PRIEST = true,
        DEATHKNIGHT = true, SHAMAN = true, MAGE = true, WARLOCK = true, DRUID = true,
    },
}

D.SPECS = {
    WARRIOR = {
        { id = 0, label = "Arms", role = "DPS", range = "MELEE" },
        { id = 1, label = "Fury", role = "DPS", range = "MELEE" },
        { id = 2, label = "Protection", role = "TANK", range = "MELEE" },
    },
    PALADIN = {
        { id = 0, label = "Holy", role = "HEALER", range = "RANGED" },
        { id = 1, label = "Protection", role = "TANK", range = "MELEE" },
        { id = 2, label = "Retribution", role = "DPS", range = "MELEE" },
    },
    HUNTER = {
        { id = 0, label = "Beast Mastery", role = "DPS", range = "RANGED" },
        { id = 1, label = "Marksmanship", role = "DPS", range = "RANGED" },
        { id = 2, label = "Survival", role = "DPS", range = "RANGED" },
    },
    ROGUE = {
        { id = 0, label = "Assassination", role = "DPS", range = "MELEE" },
        { id = 1, label = "Combat", role = "DPS", range = "MELEE" },
        { id = 2, label = "Subtlety", role = "DPS", range = "MELEE" },
    },
    PRIEST = {
        { id = 0, label = "Discipline", role = "HEALER", range = "RANGED" },
        { id = 1, label = "Holy", role = "HEALER", range = "RANGED" },
        { id = 2, label = "Shadow", role = "DPS", range = "RANGED" },
    },
    DEATHKNIGHT = {
        { id = 0, label = "Blood", role = "TANK", range = "MELEE" },
        { id = 1, label = "Frost", role = "DPS", range = "MELEE" },
        { id = 2, label = "Unholy", role = "DPS", range = "MELEE" },
    },
    SHAMAN = {
        { id = 0, label = "Elemental", role = "DPS", range = "RANGED" },
        { id = 1, label = "Enhancement", role = "DPS", range = "MELEE" },
        { id = 2, label = "Restoration", role = "HEALER", range = "RANGED" },
    },
    MAGE = {
        { id = 0, label = "Arcane", role = "DPS", range = "RANGED" },
        { id = 1, label = "Fire", role = "DPS", range = "RANGED" },
        { id = 2, label = "Frost", role = "DPS", range = "RANGED" },
    },
    WARLOCK = {
        { id = 0, label = "Affliction", role = "DPS", range = "RANGED" },
        { id = 1, label = "Demonology", role = "DPS", range = "RANGED" },
        { id = 2, label = "Destruction", role = "DPS", range = "RANGED" },
    },
    DRUID = {
        { id = 0, label = "Balance", role = "DPS", range = "RANGED" },
        { id = 1, label = "Feral", role = "DPS", canTank = true, range = "MELEE" },
        { id = 2, label = "Restoration", role = "HEALER", range = "RANGED" },
    },
}

D.UTILITY_LABELS = {
    "Interrupts",
    "Magic / curse / poison / disease removal",
    "Raid buffs",
    "Bloodlust / Heroism",
    "Battle resurrection",
    "Crowd control",
    "Threat support",
    "Ranged damage",
    "Melee damage",
}

D.DUNGEONS = {
    { id = "random", label = "Random Dungeon", rdf = true },
    { id = "utgarde_keep", label = "Utgarde Keep", map = 574, rdf = true },
    { id = "nexus", label = "The Nexus", map = 576, rdf = true },
    { id = "azjol_nerub", label = "Azjol-Nerub", map = 601, rdf = true },
    { id = "ahnkahet", label = "Ahn'kahet: The Old Kingdom", map = 619, rdf = true },
    { id = "drak_tharon", label = "Drak'Tharon Keep", map = 600, rdf = true },
    { id = "violet_hold", label = "The Violet Hold", map = 608, rdf = true },
    { id = "gundrak", label = "Gundrak", map = 604, rdf = true },
    { id = "halls_of_stone", label = "Halls of Stone", map = 599, rdf = true },
    { id = "halls_of_lightning", label = "Halls of Lightning", map = 602, rdf = true },
    { id = "oculus", label = "The Oculus", map = 578, rdf = true },
    { id = "culling", label = "The Culling of Stratholme", map = 595, rdf = true },
    { id = "utgarde_pinnacle", label = "Utgarde Pinnacle", map = 575, rdf = true },
    { id = "trial_champion", label = "Trial of the Champion", map = 650, rdf = true },
    { id = "forge_souls", label = "The Forge of Souls", map = 632, rdf = true },
    { id = "pit_saron", label = "Pit of Saron", map = 658, rdf = true },
    { id = "halls_reflection", label = "Halls of Reflection", map = 668, rdf = true },
}

D.DUNGEON_DIFFICULTIES = {
    { id = "normal", label = "Normal", stockRDF = true },
    { id = "heroic", label = "Heroic", stockRDF = true },
    -- The Titan Rune modes are part of this custom realm, not stock 3.3.5a RDF difficulty IDs.
    -- Composer preserves them in profiles and hands them to the server-side Titan Rune integration.
    { id = "alpha", label = "Titan Rune Alpha", stockRDF = false },
    { id = "beta", label = "Titan Rune Beta", stockRDF = false },
    { id = "gamma", label = "Titan Rune Gamma", stockRDF = false },
}

D.RAIDS = {
    -- Wrath
    { id = "naxxramas", label = "Naxxramas", sizes = { 10, 25 }, heroic = false, era = "WotLK" },
    { id = "obsidian_sanctum", label = "The Obsidian Sanctum", sizes = { 10, 25 }, heroic = false, era = "WotLK" },
    { id = "eye_of_eternity", label = "The Eye of Eternity", sizes = { 10, 25 }, heroic = false, era = "WotLK" },
    { id = "ulduar", label = "Ulduar", sizes = { 10, 25 }, heroic = false, era = "WotLK" },
    { id = "trial_crusader", label = "Trial of the Crusader", sizes = { 10, 25 }, heroic = true, era = "WotLK" },
    { id = "onyxia", label = "Onyxia's Lair", sizes = { 10, 25 }, heroic = false, era = "WotLK" },
    { id = "vault_archavon", label = "Vault of Archavon", sizes = { 10, 25 }, heroic = false, era = "WotLK" },
    { id = "icecrown", label = "Icecrown Citadel", sizes = { 10, 25 }, heroic = true, era = "WotLK" },
    { id = "ruby_sanctum", label = "The Ruby Sanctum", sizes = { 10, 25 }, heroic = true, era = "WotLK" },

    -- Burning Crusade
    { id = "karazhan", label = "Karazhan", sizes = { 10 }, heroic = false, era = "TBC" },
    { id = "zulaman", label = "Zul'Aman", sizes = { 10 }, heroic = false, era = "TBC" },
    { id = "gruul", label = "Gruul's Lair", sizes = { 25 }, heroic = false, era = "TBC" },
    { id = "magtheridon", label = "Magtheridon's Lair", sizes = { 25 }, heroic = false, era = "TBC" },
    { id = "serpentshrine", label = "Serpentshrine Cavern", sizes = { 25 }, heroic = false, era = "TBC" },
    { id = "tempest_keep", label = "Tempest Keep", sizes = { 25 }, heroic = false, era = "TBC" },
    { id = "hyjal", label = "Battle for Mount Hyjal", sizes = { 25 }, heroic = false, era = "TBC" },
    { id = "black_temple", label = "Black Temple", sizes = { 25 }, heroic = false, era = "TBC" },
    { id = "sunwell", label = "Sunwell Plateau", sizes = { 25 }, heroic = false, era = "TBC" },

    -- Classic legacy
    { id = "zul_gurub", label = "Zul'Gurub", sizes = { 20 }, heroic = false, era = "Classic" },
    { id = "aq20", label = "Ruins of Ahn'Qiraj", sizes = { 20 }, heroic = false, era = "Classic" },
    { id = "molten_core", label = "Molten Core", sizes = { 40 }, heroic = false, era = "Classic" },
    { id = "blackwing_lair", label = "Blackwing Lair", sizes = { 40 }, heroic = false, era = "Classic" },
    { id = "aq40", label = "Temple of Ahn'Qiraj", sizes = { 40 }, heroic = false, era = "Classic" },
}

D.RAID_DIFFICULTIES = {
    { id = "normal", label = "Normal" },
    { id = "heroic", label = "Heroic" },
}

function D.GetRaidById(id)
    for _, raid in ipairs(D.RAIDS) do
        if raid.id == id then return raid end
    end
end

function D.GetDungeonById(id)
    for _, dungeon in ipairs(D.DUNGEONS) do
        if dungeon.id == id then return dungeon end
    end
end

function D.GetSpec(classToken, specId)
    for _, spec in ipairs(D.SPECS[classToken] or {}) do
        if spec.id == tonumber(specId) then return spec end
    end
end

function D.DefaultRolesForSize(size)
    size = tonumber(size) or 5
    if size == 5 then return 1, 1, 3 end
    if size == 10 then return 2, 2, 6 end
    if size == 20 then return 3, 5, 12 end
    if size == 25 then return 2, 6, 17 end
    if size == 40 then return 5, 10, 25 end
    return 1, 1, math.max(0, size - 2)
end

function D.DefaultRolesForActivity(mode, activity, size)
    -- These are conservative roster defaults, not boss-mechanic claims. Verified encounter-specific
    -- overrides can be added later without changing the profile format.
    return D.DefaultRolesForSize(size)
end

local function Profile(name, mode, activity, difficulty, size, tanks, healers, dps)
    return {
        name = name,
        mode = mode,
        activity = activity,
        difficulty = difficulty,
        size = size,
        tanks = tanks,
        healers = healers,
        dps = dps,
    }
end

D.BUILTIN_PROFILES = {
    Profile("Dungeon - Standard 5", "DUNGEON", "random", "heroic", 5, 1, 1, 3),
    Profile("Dungeon - Normal 5", "DUNGEON", "random", "normal", 5, 1, 1, 3),
    Profile("Dungeon - Titan Rune Alpha", "DUNGEON", "random", "alpha", 5, 1, 1, 3),
    Profile("Dungeon - Titan Rune Beta", "DUNGEON", "random", "beta", 5, 1, 1, 3),
    Profile("Dungeon - Titan Rune Gamma", "DUNGEON", "random", "gamma", 5, 1, 1, 3),

    Profile("Naxxramas 10 - Standard", "RAID", "naxxramas", "normal", 10, 2, 2, 6),
    Profile("Naxxramas 25 - Standard", "RAID", "naxxramas", "normal", 25, 2, 6, 17),
    Profile("Ulduar 10 - Standard", "RAID", "ulduar", "normal", 10, 2, 2, 6),
    Profile("Ulduar 25 - Standard", "RAID", "ulduar", "normal", 25, 2, 6, 17),
    Profile("Trial of the Crusader 10 - Standard", "RAID", "trial_crusader", "normal", 10, 2, 2, 6),
    Profile("Trial of the Crusader 10 Heroic", "RAID", "trial_crusader", "heroic", 10, 2, 2, 6),
    Profile("Trial of the Crusader 25 - Standard", "RAID", "trial_crusader", "normal", 25, 2, 6, 17),
    Profile("Trial of the Crusader 25 Heroic", "RAID", "trial_crusader", "heroic", 25, 2, 6, 17),
    Profile("ICC 10 - Standard", "RAID", "icecrown", "normal", 10, 2, 2, 6),
    Profile("ICC 10 Heroic - Standard", "RAID", "icecrown", "heroic", 10, 2, 2, 6),
    Profile("ICC 25 - Standard", "RAID", "icecrown", "normal", 25, 2, 6, 17),
    Profile("ICC 25 - Extra Heals", "RAID", "icecrown", "normal", 25, 2, 7, 16),
    Profile("ICC 25 Heroic - Standard", "RAID", "icecrown", "heroic", 25, 2, 6, 17),
    Profile("Ruby Sanctum 10 Heroic", "RAID", "ruby_sanctum", "heroic", 10, 2, 2, 6),
    Profile("Ruby Sanctum 25 Heroic", "RAID", "ruby_sanctum", "heroic", 25, 2, 6, 17),

    Profile("Karazhan 10 - Standard", "RAID", "karazhan", "normal", 10, 2, 2, 6),
    Profile("Zul'Aman 10 - Standard", "RAID", "zulaman", "normal", 10, 2, 2, 6),
    Profile("Serpentshrine 25 - Standard", "RAID", "serpentshrine", "normal", 25, 2, 6, 17),
    Profile("Black Temple 25 - Standard", "RAID", "black_temple", "normal", 25, 2, 6, 17),
    Profile("Sunwell 25 - Standard", "RAID", "sunwell", "normal", 25, 2, 6, 17),

    Profile("Zul'Gurub 20 - Standard", "RAID", "zul_gurub", "normal", 20, 3, 5, 12),
    Profile("Ruins of Ahn'Qiraj 20 - Standard", "RAID", "aq20", "normal", 20, 3, 5, 12),
    Profile("Molten Core 40 - Standard", "RAID", "molten_core", "normal", 40, 5, 10, 25),
    Profile("Blackwing Lair 40 - Standard", "RAID", "blackwing_lair", "normal", 40, 5, 10, 25),
    Profile("Temple of Ahn'Qiraj 40 - Standard", "RAID", "aq40", "normal", 40, 5, 10, 25),
}

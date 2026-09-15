GroupComposerData = GroupComposerData or {}
local D = GroupComposerData

D.VERSION = "0.1.0"

D.ROLE = {
    TANK = "TANK",
    HEALER = "HEALER",
    DPS = "DPS",
}

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
        { id = 0, label = "Arms", role = "DPS" },
        { id = 1, label = "Fury", role = "DPS" },
        { id = 2, label = "Protection", role = "TANK" },
    },
    PALADIN = {
        { id = 0, label = "Holy", role = "HEALER" },
        { id = 1, label = "Protection", role = "TANK" },
        { id = 2, label = "Retribution", role = "DPS" },
    },
    HUNTER = {
        { id = 0, label = "Beast Mastery", role = "DPS" },
        { id = 1, label = "Marksmanship", role = "DPS" },
        { id = 2, label = "Survival", role = "DPS" },
    },
    ROGUE = {
        { id = 0, label = "Assassination", role = "DPS" },
        { id = 1, label = "Combat", role = "DPS" },
        { id = 2, label = "Subtlety", role = "DPS" },
    },
    PRIEST = {
        { id = 0, label = "Discipline", role = "HEALER" },
        { id = 1, label = "Holy", role = "HEALER" },
        { id = 2, label = "Shadow", role = "DPS" },
    },
    DEATHKNIGHT = {
        { id = 0, label = "Blood", role = "TANK" },
        { id = 1, label = "Frost", role = "DPS" },
        { id = 2, label = "Unholy", role = "DPS" },
    },
    SHAMAN = {
        { id = 0, label = "Elemental", role = "DPS" },
        { id = 1, label = "Enhancement", role = "DPS" },
        { id = 2, label = "Restoration", role = "HEALER" },
    },
    MAGE = {
        { id = 0, label = "Arcane", role = "DPS" },
        { id = 1, label = "Fire", role = "DPS" },
        { id = 2, label = "Frost", role = "DPS" },
    },
    WARLOCK = {
        { id = 0, label = "Affliction", role = "DPS" },
        { id = 1, label = "Demonology", role = "DPS" },
        { id = 2, label = "Destruction", role = "DPS" },
    },
    DRUID = {
        { id = 0, label = "Balance", role = "DPS" },
        { id = 1, label = "Feral", role = "DPS", canTank = true },
        { id = 2, label = "Restoration", role = "HEALER" },
    },
}

D.DUNGEONS = {
    { id = "random", label = "Random Dungeon" },
    { id = "utgarde_keep", label = "Utgarde Keep" },
    { id = "nexus", label = "The Nexus" },
    { id = "azjol_nerub", label = "Azjol-Nerub" },
    { id = "ahnkahet", label = "Ahn'kahet: The Old Kingdom" },
    { id = "drak_tharon", label = "Drak'Tharon Keep" },
    { id = "violet_hold", label = "The Violet Hold" },
    { id = "gundrak", label = "Gundrak" },
    { id = "halls_of_stone", label = "Halls of Stone" },
    { id = "halls_of_lightning", label = "Halls of Lightning" },
    { id = "oculus", label = "The Oculus" },
    { id = "culling", label = "The Culling of Stratholme" },
    { id = "utgarde_pinnacle", label = "Utgarde Pinnacle" },
    { id = "trial_champion", label = "Trial of the Champion" },
    { id = "forge_souls", label = "The Forge of Souls" },
    { id = "pit_saron", label = "Pit of Saron" },
    { id = "halls_reflection", label = "Halls of Reflection" },
}

D.DUNGEON_DIFFICULTIES = {
    { id = "normal", label = "Normal" },
    { id = "heroic", label = "Heroic" },
    { id = "alpha", label = "Titan Rune Alpha" },
    { id = "beta", label = "Titan Rune Beta" },
    { id = "gamma", label = "Titan Rune Gamma" },
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

function D.DefaultRolesForSize(size)
    if size == 5 then return 1, 1, 3 end
    if size == 10 then return 2, 2, 6 end
    if size == 20 then return 3, 5, 12 end
    if size == 25 then return 2, 6, 17 end
    if size == 40 then return 5, 10, 25 end
    return 1, 1, math.max(0, size - 2)
end

D.BUILTIN_PROFILES = {
    {
        name = "Dungeon - Standard 5",
        mode = "DUNGEON",
        activity = "random",
        difficulty = "heroic",
        size = 5,
        tanks = 1,
        healers = 1,
        dps = 3,
    },
    {
        name = "ICC 10 - Standard",
        mode = "RAID",
        activity = "icecrown",
        difficulty = "normal",
        size = 10,
        tanks = 2,
        healers = 2,
        dps = 6,
    },
    {
        name = "ICC 25 - Standard",
        mode = "RAID",
        activity = "icecrown",
        difficulty = "normal",
        size = 25,
        tanks = 2,
        healers = 6,
        dps = 17,
    },
    {
        name = "ICC 25 Heroic - Standard",
        mode = "RAID",
        activity = "icecrown",
        difficulty = "heroic",
        size = 25,
        tanks = 2,
        healers = 6,
        dps = 17,
    },
    {
        name = "Naxxramas 25 - Standard",
        mode = "RAID",
        activity = "naxxramas",
        difficulty = "normal",
        size = 25,
        tanks = 2,
        healers = 6,
        dps = 17,
    },
    {
        name = "Ulduar 25 - Standard",
        mode = "RAID",
        activity = "ulduar",
        difficulty = "normal",
        size = 25,
        tanks = 2,
        healers = 6,
        dps = 17,
    },
    {
        name = "Trial of the Crusader 25 Heroic - Standard",
        mode = "RAID",
        activity = "trial_crusader",
        difficulty = "heroic",
        size = 25,
        tanks = 2,
        healers = 6,
        dps = 17,
    },
    {
        name = "Molten Core 40 - Standard",
        mode = "RAID",
        activity = "molten_core",
        difficulty = "normal",
        size = 40,
        tanks = 5,
        healers = 10,
        dps = 25,
    },
}

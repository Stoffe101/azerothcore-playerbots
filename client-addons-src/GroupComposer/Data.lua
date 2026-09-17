GroupComposerData = GroupComposerData or {}
local D = GroupComposerData

D.VERSION = "0.4.0"

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
    HEALER = "Interface\\Icons\\Spell_Holy_HolyBolt",
    DPS = "Interface\\Icons\\Ability_DualWield",
}

D.CLASS_ORDER = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
D.CLASS_LABEL = {
    WARRIOR = "Warrior", PALADIN = "Paladin", HUNTER = "Hunter", ROGUE = "Rogue", PRIEST = "Priest",
    DEATHKNIGHT = "Death Knight", SHAMAN = "Shaman", MAGE = "Mage", WARLOCK = "Warlock", DRUID = "Druid",
}

D.SPECS = {
    WARRIOR = {
        { id = "arms", label = "Arms", role = "DPS" },
        { id = "fury", label = "Fury", role = "DPS" },
        { id = "protection", label = "Protection", role = "TANK", canTank = true },
    },
    PALADIN = {
        { id = "holy", label = "Holy", role = "HEALER" },
        { id = "protection", label = "Protection", role = "TANK", canTank = true },
        { id = "retribution", label = "Retribution", role = "DPS" },
    },
    HUNTER = {
        { id = "beastmastery", label = "Beast Mastery", role = "DPS" },
        { id = "marksmanship", label = "Marksmanship", role = "DPS" },
        { id = "survival", label = "Survival", role = "DPS" },
    },
    ROGUE = {
        { id = "assassination", label = "Assassination", role = "DPS" },
        { id = "combat", label = "Combat", role = "DPS" },
        { id = "subtlety", label = "Subtlety", role = "DPS" },
    },
    PRIEST = {
        { id = "discipline", label = "Discipline", role = "HEALER" },
        { id = "holy", label = "Holy", role = "HEALER" },
        { id = "shadow", label = "Shadow", role = "DPS" },
    },
    DEATHKNIGHT = {
        { id = "blood", label = "Blood", role = "TANK", canTank = true },
        { id = "frost", label = "Frost", role = "DPS" },
        { id = "unholy", label = "Unholy", role = "DPS" },
    },
    SHAMAN = {
        { id = "elemental", label = "Elemental", role = "DPS" },
        { id = "enhancement", label = "Enhancement", role = "DPS" },
        { id = "restoration", label = "Restoration", role = "HEALER" },
    },
    MAGE = {
        { id = "arcane", label = "Arcane", role = "DPS" },
        { id = "fire", label = "Fire", role = "DPS" },
        { id = "frost", label = "Frost", role = "DPS" },
    },
    WARLOCK = {
        { id = "affliction", label = "Affliction", role = "DPS" },
        { id = "demonology", label = "Demonology", role = "DPS" },
        { id = "destruction", label = "Destruction", role = "DPS" },
    },
    DRUID = {
        { id = "balance", label = "Balance", role = "DPS" },
        { id = "feral", label = "Feral", role = "DPS" },
        { id = "feraltank", label = "Feral (Tank)", role = "TANK", canTank = true },
        { id = "restoration", label = "Restoration", role = "HEALER" },
    },
}

D.DUNGEON_DIFFICULTIES = {
    { id = "normal", label = "Normal" },
    { id = "heroic", label = "Heroic" },
    { id = "alpha", label = "Titan Rune Alpha" },
    { id = "beta", label = "Titan Rune Beta" },
    { id = "gamma", label = "Titan Rune Gamma" },
}

D.DUNGEONS = {
    { id = "random", label = "Random Wrath Dungeon", era = "WotLK" },
    { id = "ahnkahet", label = "Ahn'kahet: The Old Kingdom", era = "WotLK" },
    { id = "azjolnerub", label = "Azjol-Nerub", era = "WotLK" },
    { id = "culling", label = "The Culling of Stratholme", era = "WotLK" },
    { id = "draktharon", label = "Drak'Tharon Keep", era = "WotLK" },
    { id = "gundrak", label = "Gundrak", era = "WotLK" },
    { id = "hallsoflightning", label = "Halls of Lightning", era = "WotLK" },
    { id = "hallsofstone", label = "Halls of Stone", era = "WotLK" },
    { id = "nexus", label = "The Nexus", era = "WotLK" },
    { id = "oculus", label = "The Oculus", era = "WotLK" },
    { id = "utgardekeep", label = "Utgarde Keep", era = "WotLK" },
    { id = "utgardepinnacle", label = "Utgarde Pinnacle", era = "WotLK" },
    { id = "violethold", label = "The Violet Hold", era = "WotLK" },
    { id = "trial", label = "Trial of the Champion", era = "WotLK" },
    { id = "forgeofsouls", label = "The Forge of Souls", era = "WotLK" },
    { id = "pitofsaron", label = "Pit of Saron", era = "WotLK" },
    { id = "hallsofreflection", label = "Halls of Reflection", era = "WotLK" },
}

D.RAIDS = {
    { id = "molten_core", label = "Molten Core", era = "Classic", sizes = {40}, heroic = false },
    { id = "blackwing_lair", label = "Blackwing Lair", era = "Classic", sizes = {40}, heroic = false },
    { id = "ahnqiraj40", label = "Temple of Ahn'Qiraj", era = "Classic", sizes = {40}, heroic = false },
    { id = "karazhan", label = "Karazhan", era = "TBC", sizes = {10}, heroic = false },
    { id = "gruul", label = "Gruul's Lair", era = "TBC", sizes = {25}, heroic = false },
    { id = "magtheridon", label = "Magtheridon's Lair", era = "TBC", sizes = {25}, heroic = false },
    { id = "serpentshrine", label = "Serpentshrine Cavern", era = "TBC", sizes = {25}, heroic = false },
    { id = "tempest_keep", label = "The Eye", era = "TBC", sizes = {25}, heroic = false },
    { id = "hyjal", label = "Battle for Mount Hyjal", era = "TBC", sizes = {25}, heroic = false },
    { id = "black_temple", label = "Black Temple", era = "TBC", sizes = {25}, heroic = false },
    { id = "sunwell", label = "Sunwell Plateau", era = "TBC", sizes = {25}, heroic = false },
    { id = "naxxramas", label = "Naxxramas", era = "WotLK", sizes = {10, 25}, heroic = false },
    { id = "obsidian_sanctum", label = "The Obsidian Sanctum", era = "WotLK", sizes = {10, 25}, heroic = false },
    { id = "eye_of_eternity", label = "The Eye of Eternity", era = "WotLK", sizes = {10, 25}, heroic = false },
    { id = "ulduar", label = "Ulduar", era = "WotLK", sizes = {10, 25}, heroic = false },
    { id = "trial_of_the_crusader", label = "Trial of the Crusader", era = "WotLK", sizes = {10, 25}, heroic = true },
    { id = "onyxia", label = "Onyxia's Lair", era = "WotLK", sizes = {10, 25}, heroic = false },
    { id = "icecrown", label = "Icecrown Citadel", era = "WotLK", sizes = {10, 25}, heroic = true },
    { id = "ruby_sanctum", label = "The Ruby Sanctum", era = "WotLK", sizes = {10, 25}, heroic = true },
}

function D.GetRaidById(id)
    for _, raid in ipairs(D.RAIDS) do if raid.id == id then return raid end end
end

function D.GetDungeonById(id)
    for _, dungeon in ipairs(D.DUNGEONS) do if dungeon.id == id then return dungeon end end
end

function D.DefaultRolesForSize(size)
    size = tonumber(size) or 5
    if size <= 5 then return 1, 1, math.max(0, size - 2) end
    if size <= 10 then return 2, 2, math.max(0, size - 4) end
    if size <= 20 then return 3, 5, math.max(0, size - 8) end
    if size <= 25 then return 2, 6, math.max(0, size - 8) end
    return 5, 10, math.max(0, size - 15)
end

D.BUILTIN_PROFILES = {
    {
        name = "Dungeon - Standard",
        mode = "DUNGEON", activity = "random", difficulty = "heroic", size = 5,
        tanks = 1, healers = 1, dps = 3,
        options = { preferGuild = true, fillWorld = true, keepMe = true, balanceClasses = true, balanceUtility = true, balanceRange = true, avoidDuplicateClasses = false, minimumItemLevel = 0, queueAfterAssemble = false },
        preferences = { TANK = {}, HEALER = {}, DPS = {} },
    },
    {
        name = "ICC 10 Heroic - Standard",
        mode = "RAID", activity = "icecrown", difficulty = "heroic", size = 10,
        tanks = 2, healers = 2, dps = 6,
        options = { preferGuild = true, fillWorld = true, keepMe = true, balanceClasses = true, balanceUtility = true, balanceRange = true, avoidDuplicateClasses = false, minimumItemLevel = 0, queueAfterAssemble = false },
        preferences = { TANK = {}, HEALER = {}, DPS = {} },
    },
    {
        name = "ICC 25 Heroic - Standard",
        mode = "RAID", activity = "icecrown", difficulty = "heroic", size = 25,
        tanks = 2, healers = 6, dps = 17,
        options = { preferGuild = true, fillWorld = true, keepMe = true, balanceClasses = true, balanceUtility = true, balanceRange = true, avoidDuplicateClasses = false, minimumItemLevel = 0, queueAfterAssemble = false },
        preferences = { TANK = {}, HEALER = {}, DPS = {} },
    },
    {
        name = "Legacy 40 - Standard",
        mode = "RAID", activity = "molten_core", difficulty = "normal", size = 40,
        tanks = 5, healers = 10, dps = 25,
        options = { preferGuild = true, fillWorld = true, keepMe = true, balanceClasses = true, balanceUtility = true, balanceRange = true, avoidDuplicateClasses = false, minimumItemLevel = 0, queueAfterAssemble = false },
        preferences = { TANK = {}, HEALER = {}, DPS = {} },
    },
}

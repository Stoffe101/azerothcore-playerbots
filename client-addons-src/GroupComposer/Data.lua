GroupComposerData = GroupComposerData or {}
local D = GroupComposerData

D.VERSION = "0.15.2"

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
    -- Synthetic random destination follows the live realm era.
    { id = "random", label = "Random Dungeon", rdf = true, minLevel = 15, era = "Current" },

    -- Vanilla
    { id = "ragefire_chasm", label = "Ragefire Chasm", map = 389, minLevel = 13, era = "Vanilla" },
    { id = "deadmines", label = "The Deadmines", map = 36, minLevel = 15, era = "Vanilla" },
    { id = "wailing_caverns", label = "Wailing Caverns", map = 43, minLevel = 15, era = "Vanilla" },
    { id = "shadowfang_keep", label = "Shadowfang Keep", map = 33, minLevel = 18, era = "Vanilla" },
    { id = "blackfathom_deeps", label = "Blackfathom Deeps", map = 48, minLevel = 20, era = "Vanilla" },
    { id = "stockades", label = "The Stockade", map = 34, minLevel = 22, era = "Vanilla" },
    { id = "gnomeregan", label = "Gnomeregan", map = 90, minLevel = 24, era = "Vanilla" },
    { id = "razorfen_kraul", label = "Razorfen Kraul", map = 47, minLevel = 25, era = "Vanilla" },
    { id = "scarlet_monastery", label = "Scarlet Monastery", map = 189, minLevel = 30, era = "Vanilla" },
    { id = "razorfen_downs", label = "Razorfen Downs", map = 129, minLevel = 35, era = "Vanilla" },
    { id = "uldaman", label = "Uldaman", map = 70, minLevel = 35, era = "Vanilla" },
    { id = "zul_farrak", label = "Zul'Farrak", map = 209, minLevel = 44, era = "Vanilla" },
    { id = "maraudon", label = "Maraudon", map = 349, minLevel = 45, era = "Vanilla" },
    { id = "sunken_temple", label = "The Sunken Temple", map = 109, minLevel = 50, era = "Vanilla" },
    { id = "blackrock_depths", label = "Blackrock Depths", map = 230, minLevel = 52, era = "Vanilla" },
    { id = "lower_blackrock_spire", label = "Lower Blackrock Spire", map = 229, minLevel = 55, era = "Vanilla" },
    { id = "dire_maul", label = "Dire Maul", map = 429, minLevel = 55, era = "Vanilla" },
    { id = "scholomance", label = "Scholomance", map = 289, minLevel = 58, era = "Vanilla" },
    { id = "stratholme", label = "Stratholme", map = 329, minLevel = 58, era = "Vanilla" },

    -- The Burning Crusade
    { id = "hellfire_ramparts", label = "Hellfire Ramparts", map = 543, minLevel = 60, era = "TBC" },
    { id = "blood_furnace", label = "The Blood Furnace", map = 542, minLevel = 60, era = "TBC" },
    { id = "slave_pens", label = "The Slave Pens", map = 547, minLevel = 60, era = "TBC" },
    { id = "underbog", label = "The Underbog", map = 546, minLevel = 61, era = "TBC" },
    { id = "mana_tombs", label = "Mana-Tombs", map = 557, minLevel = 62, era = "TBC" },
    { id = "auchenai_crypts", label = "Auchenai Crypts", map = 558, minLevel = 63, era = "TBC" },
    { id = "shattered_halls", label = "The Shattered Halls", map = 540, minLevel = 65, era = "TBC" },
    { id = "steamvault", label = "The Steamvault", map = 545, minLevel = 65, era = "TBC" },
    { id = "sethekk_halls", label = "Sethekk Halls", map = 556, minLevel = 65, era = "TBC" },
    { id = "old_hillsbrad", label = "Old Hillsbrad Foothills", map = 560, minLevel = 66, era = "TBC" },
    { id = "shadow_labyrinth", label = "Shadow Labyrinth", map = 555, minLevel = 67, era = "TBC" },
    { id = "black_morass", label = "The Black Morass", map = 269, minLevel = 68, era = "TBC" },
    { id = "mechanar", label = "The Mechanar", map = 554, minLevel = 68, era = "TBC" },
    { id = "botanica", label = "The Botanica", map = 553, minLevel = 68, era = "TBC" },
    { id = "arcatraz", label = "The Arcatraz", map = 552, minLevel = 68, era = "TBC" },
    { id = "magisters_terrace", label = "Magisters' Terrace", map = 585, minLevel = 70, era = "TBC" },

    -- Wrath of the Lich King
    { id = "utgarde_keep", label = "Utgarde Keep", map = 574, rdf = true, minLevel = 68, era = "WotLK" },
    { id = "nexus", label = "The Nexus", map = 576, rdf = true, minLevel = 68, era = "WotLK" },
    { id = "azjol_nerub", label = "Azjol-Nerub", map = 601, rdf = true, minLevel = 68, era = "WotLK" },
    { id = "ahnkahet", label = "Ahn'kahet: The Old Kingdom", map = 619, rdf = true, minLevel = 68, era = "WotLK" },
    { id = "drak_tharon", label = "Drak'Tharon Keep", map = 600, rdf = true, minLevel = 72, era = "WotLK" },
    { id = "violet_hold", label = "The Violet Hold", map = 608, rdf = true, minLevel = 73, era = "WotLK" },
    { id = "gundrak", label = "Gundrak", map = 604, rdf = true, minLevel = 74, era = "WotLK" },
    { id = "halls_of_stone", label = "Halls of Stone", map = 599, rdf = true, minLevel = 75, era = "WotLK" },
    { id = "halls_of_lightning", label = "Halls of Lightning", map = 602, rdf = true, minLevel = 77, era = "WotLK" },
    { id = "oculus", label = "The Oculus", map = 578, rdf = true, minLevel = 77, era = "WotLK" },
    { id = "culling", label = "The Culling of Stratholme", map = 595, rdf = true, minLevel = 78, era = "WotLK" },
    { id = "utgarde_pinnacle", label = "Utgarde Pinnacle", map = 575, rdf = true, minLevel = 77, era = "WotLK" },
    { id = "trial_champion", label = "Trial of the Champion", map = 650, rdf = true, minLevel = 80, era = "WotLK" },
    { id = "forge_souls", label = "The Forge of Souls", map = 632, rdf = true, minLevel = 80, era = "WotLK" },
    { id = "pit_saron", label = "Pit of Saron", map = 658, rdf = true, minLevel = 80, era = "WotLK" },
    { id = "halls_reflection", label = "Halls of Reflection", map = 668, rdf = true, minLevel = 80, era = "WotLK" },
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
    { id = "naxxramas", label = "Naxxramas", sizes = { 10, 25 }, heroic = false, era = "WotLK", requiredLevel = 80 },
    { id = "obsidian_sanctum", label = "The Obsidian Sanctum", sizes = { 10, 25 }, heroic = false, era = "WotLK", requiredLevel = 80 },
    { id = "eye_of_eternity", label = "The Eye of Eternity", sizes = { 10, 25 }, heroic = false, era = "WotLK", requiredLevel = 80 },
    { id = "ulduar", label = "Ulduar", sizes = { 10, 25 }, heroic = false, era = "WotLK", requiredLevel = 80 },
    { id = "trial_crusader", label = "Trial of the Crusader", sizes = { 10, 25 }, heroic = true, era = "WotLK", requiredLevel = 80 },
    { id = "onyxia", label = "Onyxia's Lair", sizes = { 10, 25 }, heroic = false, era = "WotLK", requiredLevel = 80 },
    { id = "vault_archavon", label = "Vault of Archavon", sizes = { 10, 25 }, heroic = false, era = "WotLK", requiredLevel = 80 },
    { id = "icecrown", label = "Icecrown Citadel", sizes = { 10, 25 }, heroic = true, era = "WotLK", requiredLevel = 80 },
    { id = "ruby_sanctum", label = "The Ruby Sanctum", sizes = { 10, 25 }, heroic = true, era = "WotLK", requiredLevel = 80 },

    -- Burning Crusade
    { id = "karazhan", label = "Karazhan", sizes = { 10 }, heroic = false, era = "TBC", requiredLevel = 70 },
    { id = "zulaman", label = "Zul'Aman", sizes = { 10 }, heroic = false, era = "TBC", requiredLevel = 70 },
    { id = "gruul", label = "Gruul's Lair", sizes = { 25 }, heroic = false, era = "TBC", requiredLevel = 70 },
    { id = "magtheridon", label = "Magtheridon's Lair", sizes = { 25 }, heroic = false, era = "TBC", requiredLevel = 70 },
    { id = "serpentshrine", label = "Serpentshrine Cavern", sizes = { 25 }, heroic = false, era = "TBC", requiredLevel = 70 },
    { id = "tempest_keep", label = "Tempest Keep", sizes = { 25 }, heroic = false, era = "TBC", requiredLevel = 70 },
    { id = "hyjal", label = "Battle for Mount Hyjal", sizes = { 25 }, heroic = false, era = "TBC", requiredLevel = 70 },
    { id = "black_temple", label = "Black Temple", sizes = { 25 }, heroic = false, era = "TBC", requiredLevel = 70 },
    { id = "sunwell", label = "Sunwell Plateau", sizes = { 25 }, heroic = false, era = "TBC", requiredLevel = 70 },

    -- Classic legacy
    { id = "zul_gurub", label = "Zul'Gurub", sizes = { 20 }, heroic = false, era = "Vanilla", requiredLevel = 60 },
    { id = "aq20", label = "Ruins of Ahn'Qiraj", sizes = { 20 }, heroic = false, era = "Vanilla", requiredLevel = 60 },
    { id = "molten_core", label = "Molten Core", sizes = { 40 }, heroic = false, era = "Vanilla", requiredLevel = 60 },
    { id = "blackwing_lair", label = "Blackwing Lair", sizes = { 40 }, heroic = false, era = "Vanilla", requiredLevel = 60 },
    { id = "aq40", label = "Temple of Ahn'Qiraj", sizes = { 40 }, heroic = false, era = "Vanilla", requiredLevel = 60 },
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

local function Pref(classToken, spec, required)
    return { class = classToken, spec = spec, required = required ~= false }
end

local function CoveragePreferences(size)
    local p = { TANK = {}, HEALER = {}, DPS = {} }

    -- Coverage-first WotLK cores. These intentionally reserve only the high-impact class/spec
    -- pieces; every slot not listed here stays Auto so Composer can adapt to the live player,
    -- available guild bots, range balance and encounter needs.
    if size == 10 then
        p.TANK = {
            Pref("PALADIN", 1),      -- Protection
            Pref("DEATHKNIGHT", 0), -- Blood
        }
        p.HEALER = {
            Pref("PRIEST", 0),      -- Discipline: Fortitude + mitigation
            Pref("SHAMAN", 2),      -- Restoration: Heroism/Bloodlust + totems
        }
        p.DPS = {
            Pref("WARLOCK", 1),     -- Demonology: Demonic Pact
            Pref("DRUID", 0),       -- Balance: spell crit / hit coverage
            Pref("PALADIN", 2),     -- Retribution: blessings + replenishment
            -- Two DPS slots stay Auto in a fresh 10-player template. Ret already supplies
            -- Replenishment, so Survival Hunter is useful but not mandatory for the coverage core.
            Pref("MAGE", 0),        -- Arcane: Arcane Brilliance + raid damage
            -- final DPS slot remains Auto
        }
    else
        p.TANK = {
            Pref("PALADIN", 1),
            Pref("DEATHKNIGHT", 0),
        }
        p.HEALER = {
            Pref("PALADIN", 0),
            Pref("PRIEST", 0),
            Pref("SHAMAN", 2),
            Pref("DRUID", 2),
        }
        p.DPS = {
            Pref("DEATHKNIGHT", 2), -- Unholy: magic-damage debuff
            Pref("MAGE", 0),        -- Arcane Brilliance + 3% raid damage
            Pref("PALADIN", 2),     -- blessings / haste / replenishment
            Pref("HUNTER", 2),      -- replenishment / ranged utility
            Pref("SHAMAN", 1),      -- melee haste / AP / totems
            Pref("WARRIOR", 0),     -- armor / bleed / physical debuffs
            Pref("WARLOCK", 1),     -- Demonic Pact
            Pref("DRUID", 0),       -- Balance utility
            Pref("DRUID", 1),       -- Feral crit / physical utility
        }
    end
    return p
end

local function RaidProfile(name, activity, difficulty, size)
    local tanks, healers, dps = D.DefaultRolesForSize(size)
    -- WotLK 25-player raid composition guides generally run 4-5 healers; use five for the built-in
    -- coverage template while keeping the ordinary quick-composition defaults conservative.
    if size == 25 then tanks, healers, dps = 2, 5, 18 end

    return {
        name = name,
        description = "Coverage-first core + Auto remainder",
        mode = "RAID",
        activity = activity,
        difficulty = difficulty,
        size = size,
        tanks = tanks,
        healers = healers,
        dps = dps,
        preferences = CoveragePreferences(size),
        options = {
            preferGuild = true,
            fillWorld = true,
            keepMe = true,
            balanceClasses = true,
            balanceUtility = true,
            balanceRange = true,
            avoidDuplicateClasses = false,
            minimumItemLevel = 0,
            queueAfterAssemble = true,
        },
    }
end

D.BUILTIN_PROFILES = {}
for _, raid in ipairs(D.RAIDS) do
    for _, size in ipairs(raid.sizes or {}) do
        local baseName = raid.label .. " " .. tostring(size)
        D.BUILTIN_PROFILES[#D.BUILTIN_PROFILES + 1] = RaidProfile(baseName .. " - Coverage", raid.id, "normal", size)
        if raid.heroic then
            D.BUILTIN_PROFILES[#D.BUILTIN_PROFILES + 1] = RaidProfile(baseName .. " Heroic - Coverage", raid.id, "heroic", size)
        end
    end
end

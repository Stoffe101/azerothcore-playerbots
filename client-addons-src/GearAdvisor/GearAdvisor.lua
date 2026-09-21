GearAdvisor335DB = GearAdvisor335DB or {}
local DB = GearAdvisor335DB
if DB.shown == nil then DB.shown = true end
DB.variants = DB.variants or {}

local ADDON = "GearAdvisor"
local PANEL_WIDTH = 352
local PANEL_HEIGHT = 506

local CLASS_SPECS = {
    WARRIOR = { "Arms", "Fury", "Protection" },
    PALADIN = { "Holy", "Protection", "Retribution" },
    HUNTER = { "Beast Mastery", "Marksmanship", "Survival" },
    ROGUE = { "Assassination", "Combat", "Subtlety" },
    PRIEST = { "Discipline", "Holy", "Shadow" },
    DEATHKNIGHT = { "Blood", "Frost", "Unholy" },
    SHAMAN = { "Elemental", "Enhancement", "Restoration" },
    MAGE = { "Arcane", "Fire", "Frost" },
    WARLOCK = { "Affliction", "Demonology", "Destruction" },
    DRUID = { "Balance", "Feral", "Restoration" },
}

local function Cap(kind, label, talentRules, note)
    return { kind = kind, label = label, talents = talentRules, note = note }
end

local function P(role, priority, caps, stats, note)
    return { role = role, priority = priority, caps = caps or {}, stats = stats or {}, note = note or "" }
end

local function Variants(defaultName, entries)
    return { defaultVariant = defaultName, variants = entries }
end

local HIT_MELEE = function(talents, note) return Cap("meleeHit", "Melee hit", talents, note) end
local HIT_RANGED = function(talents, note) return Cap("rangedHit", "Ranged hit", talents, note) end
local HIT_SPELL = function(talents, note) return Cap("spellHit", "Spell hit", talents, note) end
local EXPERTISE = function(note) return Cap("expertise", "Expertise", nil, note) end
local DEFENSE = function(note) return Cap("defense", "Defense", nil, note) end
local ARP = function(note) return Cap("arp", "Armor penetration", nil, note) end

local PROFILES = {
    WARRIOR = {
        [1] = P("DPS", "Hit cap > Expertise cap > Armor Penetration > Strength > Crit > Haste",
            { HIT_MELEE(nil, "Special attacks vs a raid boss."), EXPERTISE(), ARP("Hard cap only; proc trinkets create lower soft caps.") },
            { "strength", "attackPower", "meleeCrit", "meleeHit", "expertise", "arp" },
            "Arms scales extremely well with Armor Penetration in Wrath. Do not chase the hard ArP cap before hit/expertise are stable."),
        [2] = P("DPS", "Hit cap > Expertise cap > Armor Penetration > Strength > Crit > Haste",
            { HIT_MELEE({{"Precision", 1}}, "Precision reduces the gear hit needed for specials."), EXPERTISE(), ARP("Hard cap only; proc trinkets create lower soft caps.") },
            { "strength", "attackPower", "meleeCrit", "meleeHit", "expertise", "arp" },
            "Fury's white-swing cap is much higher than the special-attack cap and is not a sensible primary gearing target."),
        [3] = P("Tank", "Defense cap > Stamina > Armor > Expertise > Hit > Dodge/Parry > Block",
            { DEFENSE("Uncrittable baseline vs level-83 raid bosses."), HIT_MELEE(), EXPERTISE() },
            { "stamina", "armor", "defense", "dodge", "parry", "block" },
            "Survival first. Hit and expertise improve threat/control, but do not sacrifice core tank durability just to cap them."),
    },
    PALADIN = {
        [1] = P("Healer", "Intellect > Haste > Spell Power > MP5 > Crit",
            {},
            { "intellect", "spellPower", "spellCrit", "spellHaste", "mp5", "mana" },
            "Holy has no universal PvE hit/expertise cap. Intellect is the defining Wrath throughput/longevity stat."),
        [2] = P("Tank", "Defense cap > Stamina > Armor > Expertise > Hit > Dodge/Parry/Block",
            { DEFENSE(), HIT_MELEE(), EXPERTISE() },
            { "stamina", "armor", "defense", "dodge", "parry", "block" },
            "Block value/avoidance can be useful, but stamina and armor remain the safest general raid gearing foundation."),
        [3] = P("DPS", "Hit cap > Expertise cap > Strength > Crit > Agility > Haste",
            { HIT_MELEE(), EXPERTISE() },
            { "strength", "attackPower", "meleeCrit", "meleeHit", "expertise", "hasteMelee" },
            "Armor Penetration is comparatively weak for Retribution because a large share of damage is magical/holy."),
    },
    HUNTER = {
        [1] = P("DPS", "Hit cap > Agility / Attack Power > Crit > Armor Penetration > Haste",
            { HIT_RANGED({{"Focused Aim", 1}}, "Focused Aim reduces the ranged-hit gear requirement.") },
            { "agility", "rangedAttackPower", "rangedCrit", "rangedHit", "arp", "hasteRanged" },
            "Pet contribution is larger for Beast Mastery, so raw AP remains more competitive than it is for Marksmanship."),
        [2] = P("DPS", "Hit cap > Agility > Armor Penetration > Crit > Attack Power > Haste",
            { HIT_RANGED({{"Focused Aim", 1}}, "Focused Aim reduces the ranged-hit gear requirement."), ARP("1400 rating is the Wrath hard cap; proc trinkets create lower soft caps.") },
            { "agility", "rangedAttackPower", "rangedCrit", "rangedHit", "arp", "hasteRanged" },
            "Marksmanship is the classic ArP-heavy hunter build. Cap hit first; then evaluate ArP against your current gear/proc trinkets."),
        [3] = P("DPS", "Hit cap > Agility > Crit > Attack Power > Armor Penetration > Haste",
            { HIT_RANGED({{"Focused Aim", 1}}, "Focused Aim reduces the ranged-hit gear requirement.") },
            { "agility", "rangedAttackPower", "rangedCrit", "rangedHit", "arp", "hasteRanged" },
            "Survival values Agility heavily because it feeds both personal damage and talent scaling."),
    },
    ROGUE = {
        [1] = P("DPS", "Poison/spell hit > Expertise > Attack Power > Haste > Crit > Armor Penetration",
            { HIT_MELEE({{"Precision", 1}}, "Yellow melee special cap after Precision."), HIT_SPELL({{"Precision", 1}}, "Poisons use spell hit."), EXPERTISE() },
            { "agility", "attackPower", "meleeCrit", "meleeHit", "spellHit", "expertise" },
            "Assassination cares strongly about poison hit. Raid hit debuffs/racials can lower the remaining spell-hit requirement."),
        [2] = P("DPS", "Hit > Expertise > Armor Penetration > Agility / Attack Power > Haste > Crit",
            { HIT_MELEE({{"Precision", 1}}, "Yellow melee special cap after Precision."), HIT_SPELL({{"Precision", 1}}, "Poisons use spell hit."), EXPERTISE(), ARP() },
            { "agility", "attackPower", "meleeCrit", "meleeHit", "expertise", "arp" },
            "Combat scales strongly with weapon damage and Armor Penetration. White-hit cap is intentionally not treated as mandatory."),
        [3] = P("DPS", "Hit > Expertise > Agility > Attack Power > Crit > Haste",
            { HIT_MELEE({{"Precision", 1}}), HIT_SPELL({{"Precision", 1}}, "Poisons use spell hit."), EXPERTISE() },
            { "agility", "attackPower", "meleeCrit", "meleeHit", "expertise", "hasteMelee" },
            "Subtlety is less common for Wrath PvE, so treat this as a safe general boss-target baseline rather than a BiS solver."),
    },
    PRIEST = {
        [1] = P("Healer", "Spell Power > Intellect > Haste > Crit > MP5 / Spirit",
            {},
            { "intellect", "spirit", "spellPower", "spellCrit", "spellHaste", "mp5" },
            "Discipline gearing is throughput-and-mana driven; there is no mandatory PvE hit cap for healing."),
        [2] = P("Healer", "Spell Power > Spirit > Haste > Intellect > Crit > MP5",
            {},
            { "intellect", "spirit", "spellPower", "spellCrit", "spellHaste", "mp5" },
            "Holy has several viable gearing balances. This panel deliberately avoids inventing a single fake haste or crit cap."),
        [3] = P("DPS", "Hit cap > Spell Power > Haste > Crit > Spirit",
            { HIT_SPELL({{"Shadow Focus", 1}, {"Misery", 1}}, "Shadow Focus and your own Misery reduce gear hit needed.") },
            { "spellPower", "spellCrit", "spellHaste", "spellHit", "spirit", "intellect" },
            "External raid hit debuffs and Draenei Heroic Presence can reduce the remaining hit requirement further."),
    },
    DEATHKNIGHT = {
        [1] = Variants("Tank", {
            ["Tank"] = P("Tank", "Defense cap > Stamina > Armor > Expertise > Hit > Avoidance",
                { DEFENSE(), HIT_MELEE(), EXPERTISE() },
                { "strength", "stamina", "armor", "defense", "expertise", "meleeHit" },
                "Blood is the common Wrath raid-tank tree, but 3.3.5 DK design allows other tank trees too."),
            ["DPS"] = P("DPS", "Hit cap > Expertise cap > Strength > Armor Penetration > Crit > Haste",
                { HIT_MELEE(), EXPERTISE(), ARP() },
                { "strength", "attackPower", "meleeCrit", "meleeHit", "expertise", "arp" },
                "Use the role toggle if this Blood build is tanking instead of dealing damage."),
        }),
        [2] = Variants("DPS", {
            ["DPS"] = P("DPS", "Hit cap > Expertise cap > Strength > Haste > Crit > Armor Penetration",
                { HIT_MELEE({{"Nerves of Cold Steel", 1}}, "Nerves of Cold Steel can reduce hit needed while dual wielding."), EXPERTISE() },
                { "strength", "attackPower", "meleeCrit", "meleeHit", "expertise", "hasteMelee" },
                "Frost commonly dual-wields. The enormous white-swing dual-wield cap is not a mandatory gearing target."),
            ["Tank"] = P("Tank", "Defense cap > Stamina > Armor > Expertise > Hit > Avoidance",
                { DEFENSE(), HIT_MELEE(), EXPERTISE() },
                { "strength", "stamina", "armor", "defense", "expertise", "meleeHit" },
                "Wrath allows Frost tank builds; use this mode when your Frost spec is tank-oriented."),
        }),
        [3] = Variants("DPS", {
            ["DPS"] = P("DPS", "Hit cap > Expertise cap > Strength > Haste > Crit > Armor Penetration",
                { HIT_MELEE(), EXPERTISE() },
                { "strength", "attackPower", "meleeCrit", "meleeHit", "expertise", "hasteMelee" },
                "Unholy values Strength heavily and gets substantial damage from magic, diseases and pets."),
            ["Tank"] = P("Tank", "Defense cap > Stamina > Armor > Expertise > Hit > Avoidance",
                { DEFENSE(), HIT_MELEE(), EXPERTISE() },
                { "strength", "stamina", "armor", "defense", "expertise", "meleeHit" },
                "Wrath allows Unholy tank builds; use this mode when your Unholy spec is tank-oriented."),
        }),
    },
    SHAMAN = {
        [1] = P("DPS", "Hit cap > Spell Power > Haste > Crit > Intellect",
            { HIT_SPELL({{"Elemental Precision", 1}}, "Elemental Precision reduces gear hit needed.") },
            { "intellect", "spellPower", "spellCrit", "spellHaste", "spellHit", "mp5" },
            "A raid spell-hit debuff and Draenei racial can reduce the remaining hit requirement beyond your own talents."),
        [2] = P("DPS", "Spell hit > Expertise > Attack Power / Agility > Haste > Crit",
            { HIT_SPELL(nil, "Enhancement still relies heavily on spell-based damage."), HIT_MELEE({{"Dual Wield Specialization", 2}}, "Dual Wield Specialization reduces melee-hit need."), EXPERTISE() },
            { "agility", "attackPower", "meleeCrit", "meleeHit", "spellHit", "expertise" },
            "Enhancement has two relevant hit thresholds. Spell hit usually remains useful after yellow melee attacks are capped."),
        [3] = P("Healer", "Spell Power > Haste > Intellect > MP5 > Crit",
            {},
            { "intellect", "spellPower", "spellCrit", "spellHaste", "mp5", "mana" },
            "Restoration has no universal hard haste target across every raid setup; use haste as a throughput stat, not a fake cap."),
    },
    MAGE = {
        [1] = P("DPS", "Hit cap > Spell Power > Haste > Crit > Intellect",
            { HIT_SPELL({{"Arcane Focus", 1}, {"Precision", 1}}, "Arcane Focus + Precision reduce Arcane spell hit needed.") },
            { "intellect", "spellPower", "spellCrit", "spellHaste", "spellHit", "spirit" },
            "Raid hit debuffs/racials can lower the remaining requirement further. Arcane values haste strongly after hit."),
        [2] = P("DPS", "Hit cap > Spell Power > Crit > Haste > Spirit",
            { HIT_SPELL({{"Precision", 1}}, "Precision reduces gear hit needed.") },
            { "intellect", "spellPower", "spellCrit", "spellHaste", "spellHit", "spirit" },
            "Fire's crit value rises with Hot Streak and related talents, but hit remains the first boss-target checkpoint."),
        [3] = P("DPS", "Hit cap > Spell Power > Haste > Crit > Intellect",
            { HIT_SPELL({{"Precision", 1}}, "Precision reduces gear hit needed.") },
            { "intellect", "spellPower", "spellCrit", "spellHaste", "spellHit", "spirit" },
            "Frost PvE has fewer universal secondary-stat breakpoints than hit; use the priority as guidance rather than a BiS score."),
    },
    WARLOCK = {
        [1] = P("DPS", "Hit cap > Spell Power > Haste > Crit > Spirit",
            { HIT_SPELL({{"Suppression", 1}}, "Suppression reduces your gear hit requirement.") },
            { "spellPower", "spellCrit", "spellHaste", "spellHit", "spirit", "intellect" },
            "Affliction scales strongly with haste once hit is secured. Raid debuffs/racials may lower the remaining hit need."),
        [2] = P("DPS", "Hit cap > Spell Power > Haste > Spirit > Crit",
            { HIT_SPELL({{"Suppression", 1}}, "If talented, Suppression reduces gear hit needed.") },
            { "spellPower", "spellCrit", "spellHaste", "spellHit", "spirit", "intellect" },
            "Demonology's spell power also matters to Demonic Pact support value."),
        [3] = P("DPS", "Hit cap > Spell Power > Haste > Crit > Spirit",
            { HIT_SPELL({{"Suppression", 1}}, "If talented, Suppression reduces gear hit needed.") },
            { "spellPower", "spellCrit", "spellHaste", "spellHit", "spirit", "intellect" },
            "Destruction has straightforward caster gearing: secure hit, then stack throughput stats."),
    },
    DRUID = {
        [1] = P("DPS", "Hit cap > Spell Power > Haste > Crit > Spirit",
            { HIT_SPELL({{"Balance of Power", 2}, {"Improved Faerie Fire", 1}}, "Your Balance talents can substantially reduce gear hit needed.") },
            { "intellect", "spirit", "spellPower", "spellCrit", "spellHaste", "spellHit" },
            "Improved Faerie Fire is a target debuff; if another raid member supplies equivalent hit support, avoid double-counting assumptions."),
        [2] = Variants("Cat DPS", {
            ["Cat DPS"] = P("DPS", "Hit / Expertise > Agility > Armor Penetration > Strength > Crit > Haste",
                { HIT_MELEE(), EXPERTISE(), ARP("Hard cap only; proc trinkets create lower soft caps.") },
                { "agility", "strength", "attackPower", "meleeCrit", "expertise", "arp" },
                "Feral Cat can trade some cap perfection for stronger raw stats depending on gear, but caps are useful reference points."),
            ["Bear Tank"] = P("Tank", "Stamina > Armor > Agility > Dodge > Expertise > Hit",
                { HIT_MELEE(), EXPERTISE() },
                { "stamina", "armor", "agility", "dodge", "expertise", "meleeHit" },
                "Bear does not chase a normal defense cap in Wrath; Survival of the Fittest supplies crit immunity in standard tank builds."),
        }),
        [3] = P("Healer", "Spell Power > Haste > Spirit > Intellect > Crit",
            {},
            { "intellect", "spirit", "spellPower", "spellCrit", "spellHaste", "mp5" },
            "Restoration haste breakpoints depend on talents and raid haste buffs, so the addon does not pretend one number fits every setup."),
    },
}

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e, f, g, h, i, j = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d, e, f, g, h, i, j
end

local function Round(v, decimals)
    if v == nil then return nil end
    local p = 10 ^ (decimals or 0)
    return math.floor(v * p + 0.5) / p
end

local function Number(v, decimals)
    if v == nil then return "n/a" end
    if decimals == 0 then return string.format("%d", math.floor(v + 0.5)) end
    return string.format("%." .. tostring(decimals or 1) .. "f", v)
end

local function Percent(v)
    if v == nil then return "n/a" end
    return Number(v, 2) .. "%"
end

local function Stat(index)
    local _, effective = SafeCall(UnitStat, "player", index)
    return effective
end

local function Armor()
    local base, effective = SafeCall(UnitArmor, "player")
    return effective or base
end

local function Defense()
    local base, modifier = SafeCall(UnitDefense, "player")
    if not base then return nil end
    return base + (modifier or 0)
end

local function AttackPower()
    local base, pos, neg = SafeCall(UnitAttackPower, "player")
    if not base then return nil end
    return base + (pos or 0) + (neg or 0)
end

local function RangedAttackPower()
    local base, pos, neg = SafeCall(UnitRangedAttackPower, "player")
    if not base then return nil end
    return base + (pos or 0) + (neg or 0)
end

local function BestSpellPower()
    if not GetSpellBonusDamage then return nil end
    local best
    for school = 2, 7 do
        local value = SafeCall(GetSpellBonusDamage, school)
        if value and (not best or value > best) then best = value end
    end
    return best
end

local function BestSpellCrit()
    if not GetSpellCritChance then return nil end
    local best
    for school = 2, 7 do
        local value = SafeCall(GetSpellCritChance, school)
        if value and (not best or value > best) then best = value end
    end
    return best
end

local function RatingValue(name)
    local id = _G[name]
    if not id or not GetCombatRating then return nil end
    return SafeCall(GetCombatRating, id)
end

local function RatingBonus(name)
    local id = _G[name]
    if not id or not GetCombatRatingBonus then return nil end
    return SafeCall(GetCombatRatingBonus, id)
end

local function Expertise()
    local main, off = SafeCall(GetExpertise)
    if main == nil then return nil end
    if off and off < main then return off end
    return main
end

local function ManaRegen()
    local normal, casting = SafeCall(GetManaRegen)
    if normal == nil then return nil end
    return normal * 5, (casting or 0) * 5
end

local function RealmEra()
    if GroupComposer and GroupComposer.backendSeen and GroupComposer.realm and GroupComposer.realm.era then
        local era = string.upper(tostring(GroupComposer.realm.era))
        if era == "VANILLA" or era == "TBC" or era == "WOTLK" then
            return era, "server"
        end
    end
    local level = UnitLevel("player") or 1
    if level > 70 then return "WOTLK", "level fallback" end
    if level > 60 then return "TBC", "level fallback" end
    return "VANILLA", "level fallback"
end

local function PhysicalHitTarget(era)
    return era == "WOTLK" and 8 or 9
end

local function SpellHitTarget(era)
    return era == "WOTLK" and 17 or 16
end

local function DefenseTarget(era)
    if era == "VANILLA" then return 440 end
    if era == "TBC" then return 490 end
    return 540
end

local function TalentRank(talentName)
    if not talentName or not GetNumTalents or not GetTalentInfo then return 0 end
    for tab = 1, 3 do
        local count = SafeCall(GetNumTalents, tab) or 0
        for index = 1, count do
            local name, _, _, _, rank = SafeCall(GetTalentInfo, tab, index)
            if name == talentName then return rank or 0 end
        end
    end
    return 0
end

local function TalentReduction(rules)
    local total = 0
    for _, rule in ipairs(rules or {}) do
        total = total + TalentRank(rule[1]) * (rule[2] or 1)
    end
    return total
end

local function DetectSpec()
    local _, classToken = UnitClass("player")
    local bestTab, bestPoints, bestName, bestIcon = 1, -1, nil, nil
    for tab = 1, 3 do
        local name, icon, points = SafeCall(GetTalentTabInfo, tab)
        points = points or 0
        if points > bestPoints then
            bestTab, bestPoints, bestName, bestIcon = tab, points, name, icon
        end
    end
    local fallback = CLASS_SPECS[classToken] and CLASS_SPECS[classToken][bestTab] or ("Tree " .. bestTab)
    return classToken, bestTab, bestName or fallback, bestIcon, bestPoints
end

local function ResolveProfile(classToken, tab)
    local root = PROFILES[classToken] and PROFILES[classToken][tab]
    if not root then
        return P("Unknown", "No profile yet", {}, { "stamina", "armor" }, "This class/spec profile is not available yet."), nil
    end
    if not root.variants then return root, nil end

    local key = classToken .. ":" .. tostring(tab)
    local selected = DB.variants[key]
    if not selected or not root.variants[selected] then
        selected = root.defaultVariant
        DB.variants[key] = selected
    end
    return root.variants[selected], { root = root, key = key, selected = selected }
end

local ITEM_SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }

local function EquippedItemLevel()
    local sum, slots = 0, 17
    local mainHandLevel, mainHandLoc
    for _, slot in ipairs(ITEM_SLOTS) do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local _, _, _, itemLevel, _, _, _, _, equipLoc = GetItemInfo(link)
            if itemLevel then
                if slot == 16 then
                    mainHandLevel, mainHandLoc = itemLevel, equipLoc
                end
                sum = sum + itemLevel
            end
        end
    end
    if mainHandLoc == "INVTYPE_2HWEAPON" and not GetInventoryItemLink("player", 17) then
        sum = sum + (mainHandLevel or 0)
    end
    return sum / slots
end

local METRICS = {
    strength = { label = "Strength", value = function() return Stat(1) end, fmt = function(v) return Number(v, 0) end },
    agility = { label = "Agility", value = function() return Stat(2) end, fmt = function(v) return Number(v, 0) end },
    stamina = { label = "Stamina", value = function() return Stat(3) end, fmt = function(v) return Number(v, 0) end },
    intellect = { label = "Intellect", value = function() return Stat(4) end, fmt = function(v) return Number(v, 0) end },
    spirit = { label = "Spirit", value = function() return Stat(5) end, fmt = function(v) return Number(v, 0) end },
    armor = { label = "Armor", value = Armor, fmt = function(v) return Number(v, 0) end },
    defense = { label = "Defense", value = Defense, fmt = function(v) return Number(v, 0) end },
    dodge = { label = "Dodge", value = function() return SafeCall(GetDodgeChance) end, fmt = Percent },
    parry = { label = "Parry", value = function() return SafeCall(GetParryChance) end, fmt = Percent },
    block = { label = "Block", value = function() return SafeCall(GetBlockChance) end, fmt = Percent },
    attackPower = { label = "Attack power", value = AttackPower, fmt = function(v) return Number(v, 0) end },
    rangedAttackPower = { label = "Ranged AP", value = RangedAttackPower, fmt = function(v) return Number(v, 0) end },
    spellPower = { label = "Spell power", value = BestSpellPower, fmt = function(v) return Number(v, 0) end },
    meleeCrit = { label = "Melee crit", value = function() return SafeCall(GetCritChance) end, fmt = Percent },
    rangedCrit = { label = "Ranged crit", value = function() return SafeCall(GetRangedCritChance) end, fmt = Percent },
    spellCrit = { label = "Spell crit", value = BestSpellCrit, fmt = Percent },
    meleeHit = { label = "Melee hit", value = function() return RatingBonus("CR_HIT_MELEE") end, fmt = Percent },
    rangedHit = { label = "Ranged hit", value = function() return RatingBonus("CR_HIT_RANGED") end, fmt = Percent },
    spellHit = { label = "Spell hit", value = function() return RatingBonus("CR_HIT_SPELL") end, fmt = Percent },
    hasteMelee = { label = "Melee haste", value = function() return RatingBonus("CR_HASTE_MELEE") end, fmt = Percent },
    hasteRanged = { label = "Ranged haste", value = function() return RatingBonus("CR_HASTE_RANGED") end, fmt = Percent },
    spellHaste = { label = "Spell haste", value = function() return RatingBonus("CR_HASTE_SPELL") end, fmt = Percent },
    expertise = { label = "Expertise", value = Expertise, fmt = function(v) return Number(v, 0) end },
    arp = { label = "Armor pen", value = function() return RatingValue("CR_ARMOR_PENETRATION") end, fmt = function(v)
        local pct = RatingBonus("CR_ARMOR_PENETRATION")
        if v == nil then return "n/a" end
        return Number(v, 0) .. (pct and ("  (" .. Percent(pct) .. ")") or "")
    end },
    mp5 = { label = "MP5 casting", value = function() local _, casting = ManaRegen(); return casting end, fmt = function(v) return Number(v, 1) end },
    mana = { label = "Mana", value = function() return UnitManaMax("player") end, fmt = function(v) return Number(v, 0) end },
}

local function HitRatingName(kind)
    if kind == "meleeHit" then return "CR_HIT_MELEE" end
    if kind == "rangedHit" then return "CR_HIT_RANGED" end
    return "CR_HIT_SPELL"
end

local function EstimateRatingForPercent(kind, percent)
    local ratingName = HitRatingName(kind)
    local raw = RatingValue(ratingName)
    local bonus = RatingBonus(ratingName)
    if raw and bonus and bonus > 0.01 then
        return percent * raw / bonus
    end
    if (UnitLevel("player") or 0) == 80 then
        if kind == "spellHit" then return percent * 26.232 end
        return percent * 32.789
    end
    return nil
end

local function CapState(cap, era)
    if cap.kind == "meleeHit" or cap.kind == "rangedHit" or cap.kind == "spellHit" then
        local base = cap.kind == "spellHit" and SpellHitTarget(era) or PhysicalHitTarget(era)
        local target = math.max(0, base - TalentReduction(cap.talents))
        local current = RatingBonus(HitRatingName(cap.kind)) or 0
        local need = math.max(0, target - current)
        local targetRating = EstimateRatingForPercent(cap.kind, target)
        local currentRating = RatingValue(HitRatingName(cap.kind))
        local detail = Percent(current) .. " / " .. Percent(target)
        if targetRating and currentRating then
            detail = detail .. "  (" .. Number(currentRating, 0) .. "/" .. Number(targetRating, 0) .. " rating)"
        end
        return current >= target - 0.01, current, target, need, detail
    end

    if cap.kind == "expertise" then
        if era == "VANILLA" then return true, 0, 0, 0, "Not an era stat" end
        local current = Expertise() or 0
        local target = 26
        return current >= target, current, target, math.max(0, target - current),
            Number(current, 0) .. " / " .. Number(target, 0)
    end

    if cap.kind == "defense" then
        local current = Defense() or 0
        local target = DefenseTarget(era)
        return current >= target, current, target, math.max(0, target - current),
            Number(current, 0) .. " / " .. Number(target, 0)
    end

    if cap.kind == "arp" then
        if era ~= "WOTLK" then return true, 0, 0, 0, "No Wrath rating cap in this era" end
        local current = RatingValue("CR_ARMOR_PENETRATION") or 0
        local target = 1400
        return current >= target, current, target, math.max(0, target - current),
            Number(current, 0) .. " / 1400 rating"
    end

    return false, 0, 0, 0, "n/a"
end

local function ColorForProgress(current, target)
    if not target or target <= 0 then return "|cffaaaaaa" end
    local ratio = current / target
    if ratio >= 0.999 then return "|cff40ff70" end
    if ratio >= 0.85 then return "|cffffd24a" end
    return "|cffff6b6b"
end

local panel = CreateFrame("Frame", "GearAdvisor335Frame", UIParent)
panel:SetWidth(PANEL_WIDTH)
panel:SetHeight(PANEL_HEIGHT)
panel:SetFrameStrata("HIGH")
panel:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 24,
    insets = { left = 7, right = 7, top = 7, bottom = 7 }
})
panel:Hide()

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 20, -16)
title:SetText("Gear Advisor")

local specLine = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
specLine:SetPoint("TOPLEFT", 20, -42)
specLine:SetWidth(305)
specLine:SetJustifyH("LEFT")

local ilvlLine = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ilvlLine:SetPoint("TOPLEFT", 20, -61)
ilvlLine:SetWidth(305)
ilvlLine:SetJustifyH("LEFT")

local capsTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
capsTitle:SetPoint("TOPLEFT", 20, -91)
capsTitle:SetText("CAPS & TARGETS")

local capRows = {}
for i = 1, 4 do
    local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", 24, -111 - (i - 1) * 20)
    fs:SetWidth(304)
    fs:SetJustifyH("LEFT")
    fs:SetText("")
    capRows[i] = fs
end

local priorityTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
priorityTitle:SetPoint("TOPLEFT", 20, -198)
priorityTitle:SetText("STAT PRIORITY")

local priorityText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
priorityText:SetPoint("TOPLEFT", 24, -218)
priorityText:SetWidth(304)
priorityText:SetHeight(42)
priorityText:SetJustifyH("LEFT")
priorityText:SetJustifyV("TOP")

local currentTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
currentTitle:SetPoint("TOPLEFT", 20, -270)
currentTitle:SetText("YOUR KEY STATS")

local statRows = {}
for i = 1, 6 do
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", 24, -292 - (i - 1) * 18)
    label:SetWidth(150)
    label:SetJustifyH("LEFT")

    local value = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    value:SetPoint("TOPRIGHT", -24, -292 - (i - 1) * 18)
    value:SetWidth(145)
    value:SetJustifyH("RIGHT")
    statRows[i] = { label = label, value = value }
end

local notesTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
notesTitle:SetPoint("TOPLEFT", 20, -409)
notesTitle:SetText("WHY / WHAT NEXT")

local notesText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
notesText:SetPoint("TOPLEFT", 24, -429)
notesText:SetWidth(304)
notesText:SetHeight(50)
notesText:SetJustifyH("LEFT")
notesText:SetJustifyV("TOP")

local footer = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
footer:SetPoint("BOTTOMLEFT", 20, 15)
footer:SetPoint("BOTTOMRIGHT", -20, 15)
footer:SetJustifyH("CENTER")
footer:SetText("PvE boss targets | /ga toggles | hard caps != BiS weights")

local modeButton = CreateFrame("Button", "GearAdvisor335ModeButton", panel, "UIPanelButtonTemplate")
modeButton:SetWidth(94)
modeButton:SetHeight(20)
modeButton:SetPoint("TOPRIGHT", -20, -15)
modeButton:Hide()

local characterButton
local hooked = false

local function Anchor()
    panel:ClearAllPoints()
    if CharacterFrame then
        panel:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", -6, -7)
    else
        panel:SetPoint("CENTER", UIParent, "CENTER", 365, 0)
    end
end

local function Update()
    local classToken, tab, specName = DetectSpec()
    local profile, variant = ResolveProfile(classToken, tab)
    local era, eraSource = RealmEra()
    local className = UnitClass("player")
    className = className or classToken or "Unknown"

    specLine:SetText(className .. " | " .. specName .. " | " .. profile.role .. " | " .. era)
    ilvlLine:SetText("Equipped item level: |cffffffff" .. Number(EquippedItemLevel(), 1) .. "|r   Era source: " .. eraSource)

    if variant then
        modeButton:Show()
        modeButton:SetText(variant.selected)
        modeButton:SetScript("OnClick", function()
            local names = {}
            for name in pairs(variant.root.variants) do names[#names + 1] = name end
            table.sort(names)
            local currentIndex = 1
            for i, name in ipairs(names) do
                if name == DB.variants[variant.key] then currentIndex = i break end
            end
            currentIndex = currentIndex + 1
            if currentIndex > #names then currentIndex = 1 end
            DB.variants[variant.key] = names[currentIndex]
            Update()
        end)
    else
        modeButton:Hide()
    end

    for i = 1, 4 do capRows[i]:SetText("") end
    if #profile.caps == 0 then
        capRows[1]:SetText("|cffaaaaaaNo universal hard PvE cap for this healing profile.|r")
    else
        for i = 1, math.min(4, #profile.caps) do
            local cap = profile.caps[i]
            local met, current, target, need, detail = CapState(cap, era)
            if target == 0 and (cap.kind == "expertise" or cap.kind == "arp") then
                capRows[i]:SetText("|cff888888" .. cap.label .. ": " .. detail .. "|r")
            else
                local color = ColorForProgress(current, target)
                local needDecimals = (cap.kind == "expertise" or cap.kind == "defense" or cap.kind == "arp") and 0 or 2
                local needUnit = (cap.kind == "meleeHit" or cap.kind == "rangedHit" or cap.kind == "spellHit") and "%"
                    or (cap.kind == "arp" and " rating" or "")
                local suffix = met and "  [OK]" or ("  need +" .. Number(need, needDecimals) .. needUnit)
                capRows[i]:SetText(color .. cap.label .. ": " .. detail .. suffix .. "|r")
            end
        end
    end

    priorityText:SetText(profile.priority)

    for i = 1, 6 do
        local key = profile.stats[i]
        local metric = key and METRICS[key]
        if metric then
            statRows[i].label:SetText(metric.label)
            local value = metric.value()
            statRows[i].value:SetText(metric.fmt(value))
        else
            statRows[i].label:SetText("")
            statRows[i].value:SetText("")
        end
    end

    local firstMissing
    for _, cap in ipairs(profile.caps) do
        local met, _, target, need = CapState(cap, era)
        if not met and target > 0 then
            local decimals = (cap.kind == "expertise" or cap.kind == "defense" or cap.kind == "arp") and 0 or 2
            local unit = (cap.kind == "meleeHit" or cap.kind == "rangedHit" or cap.kind == "spellHit") and "%"
                or (cap.kind == "arp" and " rating" or "")
            firstMissing = cap.label .. " is short by " .. Number(need, decimals) .. unit
            break
        end
    end
    local note = profile.note
    if firstMissing then note = firstMissing .. ". " .. note end
    notesText:SetText(note)
end

local function Show()
    Anchor()
    Update()
    panel:Show()
    DB.shown = true
end

local function Hide()
    panel:Hide()
    DB.shown = false
end

local function Toggle()
    if panel:IsShown() then Hide() else Show() end
end

local function HookCharacterFrame()
    if hooked or not CharacterFrame then return end
    hooked = true

    characterButton = CreateFrame("Button", "GearAdvisor335CharacterButton", CharacterFrame, "UIPanelButtonTemplate")
    characterButton:SetWidth(74)
    characterButton:SetHeight(20)
    characterButton:SetText("Advisor")
    characterButton:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -72, -33)
    characterButton:SetScript("OnClick", Toggle)

    CharacterFrame:HookScript("OnShow", function()
        Anchor()
        Update()
        if DB.shown then panel:Show() end
    end)
    CharacterFrame:HookScript("OnHide", function()
        panel:Hide()
    end)
end

local event = CreateFrame("Frame")
event:RegisterEvent("PLAYER_ENTERING_WORLD")
event:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
event:RegisterEvent("UNIT_STATS")
event:RegisterEvent("UNIT_ATTACK_POWER")
event:RegisterEvent("UNIT_RANGEDDAMAGE")
event:RegisterEvent("COMBAT_RATING_UPDATE")
event:RegisterEvent("CHARACTER_POINTS_CHANGED")
event:RegisterEvent("PLAYER_TALENT_UPDATE")
event:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
event:RegisterEvent("ADDON_LOADED")
event:SetScript("OnEvent", function(self, eventName, arg1)
    if eventName == "PLAYER_ENTERING_WORLD" or eventName == "ADDON_LOADED" then
        HookCharacterFrame()
    end
    if (eventName == "UNIT_STATS" or eventName == "UNIT_ATTACK_POWER" or eventName == "UNIT_RANGEDDAMAGE") and arg1 and arg1 ~= "player" then
        return
    end
    if panel:IsShown() then Update() end
end)

if type(hooksecurefunc) == "function" and type(ToggleCharacter) == "function" then
    hooksecurefunc("ToggleCharacter", function()
        HookCharacterFrame()
        if CharacterFrame and CharacterFrame:IsShown() and DB.shown then
            Anchor()
            Update()
            panel:Show()
        end
    end)
end

SLASH_GEARADVISOR3351 = "/ga"
SLASH_GEARADVISOR3352 = "/gearadvisor"
SlashCmdList["GEARADVISOR335"] = Toggle

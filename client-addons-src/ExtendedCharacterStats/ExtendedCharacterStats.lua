ExtendedCharacterStats335DB = ExtendedCharacterStats335DB or {}
local DB = ExtendedCharacterStats335DB
DB.shown = DB.shown ~= false

local function N(v, decimals)
    if v == nil then return "n/a" end
    if type(v) ~= "number" then return tostring(v) end
    if decimals == 0 then return string.format("%d", math.floor(v + 0.5)) end
    return string.format("%." .. tostring(decimals or 2) .. "f", v)
end

local function Percent(v)
    if v == nil then return "n/a" end
    return N(v, 2) .. "%"
end

local function RatingBonus(constantName)
    local rating = _G[constantName]
    if not rating or not GetCombatRatingBonus then return nil end
    return GetCombatRatingBonus(rating)
end

local function RatingValue(constantName)
    local rating = _G[constantName]
    if not rating or not GetCombatRating then return nil end
    return GetCombatRating(rating)
end

local function PairRating(constantName)
    local raw = RatingValue(constantName)
    local pct = RatingBonus(constantName)
    if raw == nil and pct == nil then return "n/a" end
    if raw == nil then return Percent(pct) end
    if pct == nil then return N(raw, 0) end
    return N(raw, 0) .. "  (" .. Percent(pct) .. ")"
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d
end

local function MeleeAP()
    local base, pos, neg = SafeCall(UnitAttackPower, "player")
    if not base then return nil end
    return base + (pos or 0) + (neg or 0)
end

local function RangedAP()
    local base, pos, neg = SafeCall(UnitRangedAttackPower, "player")
    if not base then return nil end
    return base + (pos or 0) + (neg or 0)
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

local function Expertise()
    local main, off = SafeCall(GetExpertise)
    if main == nil then return nil end
    if off and off ~= main then
        return N(main, 0) .. " / " .. N(off, 0)
    end
    return N(main, 0)
end

local function ExpertisePct()
    local main, off = SafeCall(GetExpertisePercent)
    if main == nil then return nil end
    if off and math.abs(off - main) > 0.001 then
        return Percent(main) .. " / " .. Percent(off)
    end
    return Percent(main)
end

local function SpellCrit()
    local best = nil
    if not GetSpellCritChance then return nil end
    for school = 2, 7 do
        local value = SafeCall(GetSpellCritChance, school)
        if value and (not best or value > best) then best = value end
    end
    return best
end

local function SpellPower()
    if not GetSpellBonusDamage then return nil end
    local best = nil
    for school = 2, 7 do
        local value = SafeCall(GetSpellBonusDamage, school)
        if value and (not best or value > best) then best = value end
    end
    return best
end

local function HealingPower()
    return SafeCall(GetSpellBonusHealing)
end

local function ManaRegen()
    local base, casting = SafeCall(GetManaRegen)
    if not base then return nil end
    return (base * 5), ((casting or 0) * 5)
end

local function Avoidance()
    local dodge = SafeCall(GetDodgeChance) or 0
    local parry = SafeCall(GetParryChance) or 0
    local block = SafeCall(GetBlockChance) or 0
    return dodge + parry + block
end

local rows = {
    {"Health", function() return N(UnitHealthMax("player"), 0) end},
    {"Mana", function() if UnitPowerType("player") == 0 then return N(UnitManaMax("player"), 0) else return "n/a" end end},
    {"Armor", function() return N(Armor(), 0) end},
    {"Defense", function() return N(Defense(), 0) end},
    {"Dodge", function() return Percent(SafeCall(GetDodgeChance)) end},
    {"Parry", function() return Percent(SafeCall(GetParryChance)) end},
    {"Block", function() return Percent(SafeCall(GetBlockChance)) end},
    {"Total avoidance", function() return Percent(Avoidance()) end},
    {"Resilience", function() return PairRating("CR_RESILIENCE_CRIT_TAKEN") end},
    {"Melee attack power", function() return N(MeleeAP(), 0) end},
    {"Melee crit", function() return Percent(SafeCall(GetCritChance)) end},
    {"Melee hit rating", function() return PairRating("CR_HIT_MELEE") end},
    {"Melee haste", function() return PairRating("CR_HASTE_MELEE") end},
    {"Expertise", function()
        local raw = Expertise()
        local pct = ExpertisePct()
        if not raw then return "n/a" end
        return pct and (raw .. "  (" .. pct .. ")") or raw
    end},
    {"Armor penetration", function() return PairRating("CR_ARMOR_PENETRATION") end},
    {"Ranged attack power", function() return N(RangedAP(), 0) end},
    {"Ranged crit", function() return Percent(SafeCall(GetRangedCritChance)) end},
    {"Ranged hit rating", function() return PairRating("CR_HIT_RANGED") end},
    {"Ranged haste", function() return PairRating("CR_HASTE_RANGED") end},
    {"Spell power", function() return N(SpellPower(), 0) end},
    {"Healing power", function() return N(HealingPower(), 0) end},
    {"Spell crit (best school)", function() return Percent(SpellCrit()) end},
    {"Spell hit rating", function() return PairRating("CR_HIT_SPELL") end},
    {"Spell haste", function() return PairRating("CR_HASTE_SPELL") end},
    {"MP5 (not casting)", function() local normal = ManaRegen(); return N(normal, 1) end},
    {"MP5 (casting)", function() local _, casting = ManaRegen(); return N(casting, 1) end},
}

local panel = CreateFrame("Frame", "ExtendedCharacterStats335Frame", UIParent)
panel:SetWidth(285)
panel:SetHeight(544)
panel:SetFrameStrata("HIGH")
panel:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 24,
    insets = { left = 7, right = 7, top = 7, bottom = 7 }
})
panel:Hide()

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -14)
title:SetText("Extended Stats")

local sub = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
sub:SetPoint("TOP", title, "BOTTOM", 0, -3)
sub:SetText("WoW 3.3.5a • live character values")

local values = {}
local startY = -55
for i, row in ipairs(rows) do
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", 17, startY - (i - 1) * 18)
    label:SetWidth(145)
    label:SetJustifyH("LEFT")
    label:SetText(row[1])

    local value = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    value:SetPoint("TOPRIGHT", -17, startY - (i - 1) * 18)
    value:SetWidth(115)
    value:SetJustifyH("RIGHT")
    value:SetText("-")
    values[i] = value
end

local footer = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
footer:SetPoint("BOTTOMLEFT", 17, 15)
footer:SetPoint("BOTTOMRIGHT", -17, 15)
footer:SetJustifyH("CENTER")
footer:SetText("/ecs toggles this panel")

local function UpdateStats()
    for i, row in ipairs(rows) do
        local ok, value = pcall(row[2])
        values[i]:SetText(ok and tostring(value or "n/a") or "n/a")
    end
end

local function Anchor()
    panel:ClearAllPoints()
    if CharacterFrame and CharacterFrame:IsShown() then
        panel:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", -7, -6)
    else
        panel:SetPoint("CENTER", UIParent, "CENTER", 330, 0)
    end
end

local function ShowPanel()
    Anchor()
    UpdateStats()
    panel:Show()
    DB.shown = true
end

local function HidePanel()
    panel:Hide()
    DB.shown = false
end

local function TogglePanel()
    if panel:IsShown() then HidePanel() else ShowPanel() end
end

local characterButton
local function HookCharacterFrame()
    if not CharacterFrame then return end
    if not characterButton then
        characterButton = CreateFrame("Button", "ExtendedCharacterStats335Button", CharacterFrame, "UIPanelButtonTemplate")
        characterButton:SetWidth(52)
        characterButton:SetHeight(20)
        characterButton:SetText("Stats+")
        characterButton:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -72, -33)
        characterButton:SetScript("OnClick", TogglePanel)
    end

    CharacterFrame:HookScript("OnShow", function()
        Anchor()
        UpdateStats()
        if DB.shown then panel:Show() end
    end)
    CharacterFrame:HookScript("OnHide", function()
        if panel:IsShown() then panel:Hide() end
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
event:SetScript("OnEvent", function(self, evt, unit)
    if evt == "PLAYER_ENTERING_WORLD" then
        HookCharacterFrame()
    elseif unit and unit ~= "player" then
        return
    end

    if panel:IsShown() then UpdateStats() end
end)

SLASH_EXTENDEDCHARACTERSTATS3351 = "/ecs"
SLASH_EXTENDEDCHARACTERSTATS3352 = "/statsplus"
SlashCmdList["EXTENDEDCHARACTERSTATS335"] = TogglePanel

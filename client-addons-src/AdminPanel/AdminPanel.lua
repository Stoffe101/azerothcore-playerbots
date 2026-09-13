local addonName = ...

AzerothAdminPanelDB = AzerothAdminPanelDB or {}
local DB = AzerothAdminPanelDB
DB.point = DB.point or { "CENTER", "UIParent", "CENTER", 0, 0 }
DB.page = DB.page or "Dashboard"

local state = {
    era = "TBC",
    wotlk = "0",
    levelcap = "70",
    progressionlimit = "12",
    stage = "?",
    level = "?",
    money = "?",
    xp = "1.00",
    rep = "1.00",
    goldrate = "1.00",
    starter = "tbc",
    players = "?",
    bots = "?",
    bottarget = "?",
    botbatch = "10",
    botactivity = "?",
    uptime = "?",
    sessions = "?",
    tick = "?",
    mean = "?",
    p95 = "?",
    p99 = "?",
}

local C = {
    bg = {0.035, 0.040, 0.055, 0.98},
    panel = {0.065, 0.072, 0.095, 0.96},
    panel2 = {0.085, 0.092, 0.120, 0.96},
    line = {0.19, 0.22, 0.30, 0.90},
    accent = {0.17, 0.72, 0.92, 1.0},
    accent2 = {0.30, 0.84, 0.58, 1.0},
    warning = {1.00, 0.66, 0.20, 1.0},
    danger = {0.95, 0.30, 0.30, 1.0},
    text = {0.92, 0.94, 0.98, 1.0},
    muted = {0.62, 0.66, 0.74, 1.0},
}

local function ColorHex(r, g, b)
    return string.format("|cff%02x%02x%02x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
end

local function Send(command)
    if not command or command == "" then return end
    SendChatMessage(".ap " .. command, "SAY")
end

local function MakeSolid(parent, layer, r, g, b, a)
    local tex = parent:CreateTexture(nil, layer or "BACKGROUND")
    tex:SetTexture(r, g, b, a or 1)
    return tex
end

local function MakeText(parent, text, sizeTemplate, r, g, b)
    local fs = parent:CreateFontString(nil, "OVERLAY", sizeTemplate or "GameFontHighlight")
    fs:SetText(text or "")
    if r then fs:SetTextColor(r, g, b) end
    return fs
end

local function SetEnabled(button, enabled)
    if not button then return end
    button:SetEnabled(enabled and 1 or nil)
    if button:GetFontString() then
        if enabled then
            button:GetFontString():SetTextColor(C.text[1], C.text[2], C.text[3])
        else
            button:GetFontString():SetTextColor(0.42, 0.45, 0.52)
        end
    end
end

local function MakeButton(parent, text, width, height, onClick, tooltip)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetWidth(width or 100)
    b:SetHeight(height or 24)
    b:SetText(text or "Button")
    if onClick then b:SetScript("OnClick", onClick) end
    if tooltip then
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(text or "", 1, 1, 1)
            GameTooltip:AddLine(tooltip, 0.78, 0.82, 0.90, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return b
end

local function MakeEdit(parent, width, value)
    local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    e:SetWidth(width or 90)
    e:SetHeight(22)
    e:SetAutoFocus(false)
    e:SetText(value or "")
    e:SetJustifyH("CENTER")
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    return e
end

local frame = CreateFrame("Frame", "AzerothAdminPanelFrame", UIParent)
frame:SetWidth(800)
frame:SetHeight(590)
frame:SetFrameStrata("DIALOG")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetClampedToScreen(true)
frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
frame:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], C.bg[4])
frame:SetPoint(unpack(DB.point))
frame:Hide()

frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, rel, rp, x, y = self:GetPoint(1)
    DB.point = { p, rel and rel:GetName() or "UIParent", rp, x, y }
end)

local headerBg = MakeSolid(frame, "BACKGROUND", 0.055, 0.063, 0.085, 1)
headerBg:SetPoint("TOPLEFT", 5, -5)
headerBg:SetPoint("TOPRIGHT", -5, -5)
headerBg:SetHeight(62)

local title = MakeText(frame, "AZEROTH CONTROL", "GameFontNormalLarge", C.text[1], C.text[2], C.text[3])
title:SetPoint("TOPLEFT", 22, -18)

local subtitle = MakeText(frame, "Private server control center", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3])
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)

local eraBadge = CreateFrame("Frame", nil, frame)
eraBadge:SetWidth(198)
eraBadge:SetHeight(34)
eraBadge:SetPoint("TOP", 75, -16)
local eraBadgeBg = MakeSolid(eraBadge, "BACKGROUND", 0.12, 0.16, 0.20, 1)
eraBadgeBg:SetAllPoints(eraBadge)
local eraText = MakeText(eraBadge, "THE BURNING CRUSADE", "GameFontNormal", C.accent2[1], C.accent2[2], C.accent2[3])
eraText:SetPoint("CENTER", 0, 5)
local capText = MakeText(eraBadge, "LEVEL CAP 70", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3])
capText:SetPoint("CENTER", 0, -9)

local refresh = MakeButton(frame, "Refresh", 78, 24, function()
    Send("status")
    Send("health")
end, "Refresh live server, character, AI and health information.")
refresh:SetPoint("TOPRIGHT", -48, -23)

local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -8, -8)

local sidebar = CreateFrame("Frame", nil, frame)
sidebar:SetWidth(142)
sidebar:SetPoint("TOPLEFT", 8, -72)
sidebar:SetPoint("BOTTOMLEFT", 8, 36)
local sidebarBg = MakeSolid(sidebar, "BACKGROUND", 0.047, 0.052, 0.070, 1)
sidebarBg:SetAllPoints(sidebar)

local content = CreateFrame("Frame", nil, frame)
content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 10, 0)
content:SetPoint("BOTTOMRIGHT", -10, 36)

local footerLine = MakeSolid(frame, "ARTWORK", C.line[1], C.line[2], C.line[3], C.line[4])
footerLine:SetPoint("BOTTOMLEFT", 12, 33)
footerLine:SetPoint("BOTTOMRIGHT", -12, 33)
footerLine:SetHeight(1)

local footer = MakeText(frame, "Ready. /ap toggles this panel.", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3])
footer:SetPoint("BOTTOMLEFT", 18, 14)
footer:SetPoint("BOTTOMRIGHT", -18, 14)
footer:SetJustifyH("LEFT")

local pages = {}
local tabButtons = {}
local currentPage

local function CreatePage(name)
    local p = CreateFrame("Frame", nil, content)
    p:SetAllPoints(content)
    p:Hide()
    pages[name] = p
    return p
end

local function PageTitle(page, titleText, desc)
    local h = MakeText(page, titleText, "GameFontNormalLarge", C.text[1], C.text[2], C.text[3])
    h:SetPoint("TOPLEFT", 8, -4)
    local d = MakeText(page, desc or "", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3])
    d:SetPoint("TOPLEFT", h, "BOTTOMLEFT", 0, -4)
    d:SetWidth(610)
    d:SetJustifyH("LEFT")
    return h, d
end

local function Card(parent, width, height)
    local c = CreateFrame("Frame", nil, parent)
    c:SetWidth(width)
    c:SetHeight(height)
    local bg = MakeSolid(c, "BACKGROUND", C.panel[1], C.panel[2], C.panel[3], C.panel[4])
    bg:SetAllPoints(c)
    local top = MakeSolid(c, "ARTWORK", C.line[1], C.line[2], C.line[3], 0.8)
    top:SetPoint("TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", 0, 0)
    top:SetHeight(1)
    return c
end

local function CardLabel(card, label)
    local l = MakeText(card, string.upper(label), "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3])
    l:SetPoint("TOPLEFT", 14, -12)
    return l
end

local function SelectPage(name)
    if not pages[name] then return end
    for pageName, page in pairs(pages) do
        if pageName == name then page:Show() else page:Hide() end
    end
    for tabName, button in pairs(tabButtons) do
        if tabName == name then
            button:LockHighlight()
        else
            button:UnlockHighlight()
        end
    end
    currentPage = name
    DB.page = name
end

local tabNames = { "Dashboard", "Character", "World", "AI & Raid", "Teleports" }
for i, name in ipairs(tabNames) do
    local b = CreateFrame("Button", nil, sidebar, "UIPanelButtonTemplate")
    b:SetWidth(124)
    b:SetHeight(30)
    b:SetText(name)
    b:SetPoint("TOP", 0, -12 - ((i - 1) * 36))
    b:SetScript("OnClick", function() SelectPage(name) end)
    tabButtons[name] = b
end

local sideInfo = MakeText(sidebar, "TBC-first realm\nGM controls only", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3])
sideInfo:SetPoint("BOTTOM", 0, 16)
sideInfo:SetJustifyH("CENTER")

-- DASHBOARD -----------------------------------------------------------------
local dashboard = CreatePage("Dashboard")
PageTitle(dashboard, "Dashboard", "Live realm status and the buttons you are most likely to use.")

local eraCard = Card(dashboard, 296, 100)
eraCard:SetPoint("TOPLEFT", 8, -58)
CardLabel(eraCard, "Current expansion")
local dashEra = MakeText(eraCard, "THE BURNING CRUSADE", "GameFontNormalLarge", C.accent2[1], C.accent2[2], C.accent2[3])
dashEra:SetPoint("TOPLEFT", 14, -34)
local dashLock = MakeText(eraCard, "WotLK locked • cap 70 • stage limit 12", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3])
dashLock:SetPoint("TOPLEFT", 14, -62)

local charCard = Card(dashboard, 296, 100)
charCard:SetPoint("TOPLEFT", eraCard, "TOPRIGHT", 10, 0)
CardLabel(charCard, "Your character")
local dashCharacter = MakeText(charCard, "Level ?  •  Stage ?", "GameFontNormalLarge", C.text[1], C.text[2], C.text[3])
dashCharacter:SetPoint("TOPLEFT", 14, -34)
local dashMoney = MakeText(charCard, "? gold", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3])
dashMoney:SetPoint("TOPLEFT", 14, -62)

local ratesCard = Card(dashboard, 602, 92)
ratesCard:SetPoint("TOPLEFT", eraCard, "BOTTOMLEFT", 0, -10)
CardLabel(ratesCard, "Rates")
local dashRates = MakeText(ratesCard, "XP 1.00x     REP 1.00x     GOLD 1.00x", "GameFontNormal", C.text[1], C.text[2], C.text[3])
dashRates:SetPoint("TOPLEFT", 14, -38)
local presetNormal = MakeButton(ratesCard, "Normal", 82, 22, function() Send("preset normal"); Send("status") end)
presetNormal:SetPoint("TOPRIGHT", -188, -48)
local presetFast = MakeButton(ratesCard, "Fast", 82, 22, function() Send("preset fast"); Send("status") end)
presetFast:SetPoint("LEFT", presetNormal, "RIGHT", 5, 0)
local presetRaid = MakeButton(ratesCard, "Raid Night", 92, 22, function() Send("preset raid"); Send("raidnight"); Send("status") end)
presetRaid:SetPoint("LEFT", presetFast, "RIGHT", 5, 0)

local populationCard = Card(dashboard, 296, 110)
populationCard:SetPoint("TOPLEFT", ratesCard, "BOTTOMLEFT", 0, -10)
CardLabel(populationCard, "Population")
local dashPopulation = MakeText(populationCard, "Players ?   •   Bots ? / ?", "GameFontNormal", C.text[1], C.text[2], C.text[3])
dashPopulation:SetPoint("TOPLEFT", 14, -38)
local dashActivity = MakeText(populationCard, "Activity ?%   •   ramp ?/cycle", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3])
dashActivity:SetPoint("TOPLEFT", 14, -62)
local goAi = MakeButton(populationCard, "AI controls", 100, 22, function() SelectPage("AI & Raid") end)
goAi:SetPoint("BOTTOMLEFT", 14, 10)

local healthCard = Card(dashboard, 296, 110)
healthCard:SetPoint("TOPLEFT", populationCard, "TOPRIGHT", 10, 0)
CardLabel(healthCard, "World health")
local dashHealth = MakeText(healthCard, "Waiting for server health...", "GameFontNormal", C.text[1], C.text[2], C.text[3])
dashHealth:SetPoint("TOPLEFT", 14, -38)
dashHealth:SetWidth(270)
dashHealth:SetJustifyH("LEFT")
local dashUptime = MakeText(healthCard, "Uptime ?", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3])
dashUptime:SetPoint("TOPLEFT", 14, -65)
local refreshHealth = MakeButton(healthCard, "Refresh health", 112, 22, function() Send("health") end)
refreshHealth:SetPoint("BOTTOMLEFT", 14, 10)

local quickCard = Card(dashboard, 602, 90)
quickCard:SetPoint("TOPLEFT", populationCard, "BOTTOMLEFT", 0, -10)
CardLabel(quickCard, "Quick actions")
local quickRepair = MakeButton(quickCard, "Repair", 100, 24, function() Send("repair") end)
quickRepair:SetPoint("BOTTOMLEFT", 14, 13)
local quickRestore = MakeButton(quickCard, "Restore", 100, 24, function() Send("restore") end)
quickRestore:SetPoint("LEFT", quickRepair, "RIGHT", 8, 0)
local quickGold = MakeButton(quickCard, "+1000g", 100, 24, function() Send("givegold 1000"); Send("status") end)
quickGold:SetPoint("LEFT", quickRestore, "RIGHT", 8, 0)
local quickPrep = MakeButton(quickCard, "Prep Group", 112, 24, function() Send("groupprep") end)
quickPrep:SetPoint("LEFT", quickGold, "RIGHT", 8, 0)
local quickRaid = MakeButton(quickCard, "RAID NIGHT", 126, 24, function() Send("raidnight"); Send("health") end)
quickRaid:SetPoint("LEFT", quickPrep, "RIGHT", 8, 0)

-- CHARACTER -----------------------------------------------------------------
local character = CreatePage("Character")
PageTitle(character, "Character", "Money, repairs, supplies, talents and gearing without command-line archaeology.")

local goldCard = Card(character, 602, 115)
goldCard:SetPoint("TOPLEFT", 8, -58)
CardLabel(goldCard, "Give yourself gold")
local goldButtons = {100, 1000, 5000, 10000}
local previous
for _, amount in ipairs(goldButtons) do
    local b = MakeButton(goldCard, "+" .. amount .. "g", 82, 24, function()
        Send("givegold " .. amount)
        Send("status")
    end)
    if not previous then b:SetPoint("TOPLEFT", 14, -42) else b:SetPoint("LEFT", previous, "RIGHT", 6, 0) end
    previous = b
end
local goldCustom = MakeEdit(goldCard, 92, "2500")
goldCustom:SetPoint("LEFT", previous, "RIGHT", 14, 0)
local goldApply = MakeButton(goldCard, "Give", 70, 24, function()
    local value = tonumber(goldCustom:GetText())
    if value and value > 0 then Send("givegold " .. math.floor(value)); Send("status") end
end)
goldApply:SetPoint("LEFT", goldCustom, "RIGHT", 6, 0)
local goldCurrent = MakeText(goldCard, "Current: ?g", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3])
goldCurrent:SetPoint("BOTTOMLEFT", 14, 13)

local utilityCard = Card(character, 602, 145)
utilityCard:SetPoint("TOPLEFT", goldCard, "BOTTOMLEFT", 0, -10)
CardLabel(utilityCard, "Character utilities")
local utilities = {
    {"Repair all", "repair", "Free full durability repair."},
    {"Restore / Res", "restore", "Restore health/power and resurrect if dead."},
    {"Max skills", "maxskills", "Max current-level weapon/class skills."},
    {"Refill supplies", "consumables", "Refresh ammo, reagents, food and potions."},
    {"Reset talents", "resettalents", "Free current-era talent reset and sync."},
    {"Regear pre-raid", "regear", "Spec-aware TBC pre-raid ilvl-115 set."},
}
for i, entry in ipairs(utilities) do
    local col = (i - 1) % 3
    local row = math.floor((i - 1) / 3)
    local b = MakeButton(utilityCard, entry[1], 174, 26, function() Send(entry[2]) end, entry[3])
    b:SetPoint("TOPLEFT", 14 + col * 190, -42 - row * 36)
end

local startCard = Card(character, 602, 155)
startCard:SetPoint("TOPLEFT", utilityCard, "BOTTOMLEFT", 0, -10)
CardLabel(startCard, "TBC starter / gearing")
local currentStarter = MakeText(startCard, "Default new character: TBC Adventure • Level 60", "GameFontNormal", C.text[1], C.text[2], C.text[3])
currentStarter:SetPoint("TOPLEFT", 14, -38)
local start60 = MakeButton(startCard, "New chars: Adventure 60", 190, 26, function() Send("starter tbc"); Send("status") end)
start60:SetPoint("TOPLEFT", 14, -70)
local start70 = MakeButton(startCard, "New chars: Raid Ready 70", 190, 26, function() Send("starter tbcraid"); Send("status") end)
start70:SetPoint("LEFT", start60, "RIGHT", 10, 0)
local current70 = MakeButton(startCard, "Make THIS char TBC Raid Ready", 220, 26, function() Send("tbcraidready"); Send("status") end)
current70:SetPoint("TOPLEFT", 14, -108)
local startNote = MakeText(startCard, "Stage stays at 8, so Kara / Gruul / Mag remain your first raid tier.", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3])
startNote:SetPoint("LEFT", current70, "RIGHT", 12, 0)
startNote:SetWidth(340)
startNote:SetJustifyH("LEFT")

-- WORLD ---------------------------------------------------------------------
local world = CreatePage("World")
PageTitle(world, "World & expansion", "The realm is TBC-first. WotLK stays behind a persistent release gate until you choose otherwise.")

local expansionCard = Card(world, 602, 210)
expansionCard:SetPoint("TOPLEFT", 8, -58)
CardLabel(expansionCard, "Expansion timeline")
local expansionTitle = MakeText(expansionCard, "THE BURNING CRUSADE  •  LIVE", "GameFontNormalLarge", C.accent2[1], C.accent2[2], C.accent2[3])
expansionTitle:SetPoint("TOPLEFT", 14, -40)
local expansionInfo = MakeText(expansionCard, "Level cap 70  •  Progression ceiling 12  •  WotLK locked", "GameFontHighlight", C.text[1], C.text[2], C.text[3])
expansionInfo:SetPoint("TOPLEFT", 14, -73)
local expansionDesc = MakeText(expansionCard, "Finish TBC on your terms. Releasing Wrath opens stage 13, Northrend and level-80 progression. It does NOT boost everyone to 80.", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3])
expansionDesc:SetPoint("TOPLEFT", 14, -104)
expansionDesc:SetWidth(560)
expansionDesc:SetJustifyH("LEFT")
local releaseButton = MakeButton(expansionCard, "RELEASE WRATH OF THE LICH KING", 286, 30, function()
    StaticPopup_Show("AZEROTH_RELEASE_WOTLK")
end, "Permanent server milestone. This opens WotLK progression and unlocks Northrend controls.")
releaseButton:SetPoint("BOTTOMLEFT", 14, 18)
local releaseStatus = MakeText(expansionCard, "LOCKED", "GameFontNormal", C.warning[1], C.warning[2], C.warning[3])
releaseStatus:SetPoint("LEFT", releaseButton, "RIGHT", 18, 0)

local rateCard = Card(world, 602, 188)
rateCard:SetPoint("TOPLEFT", expansionCard, "BOTTOMLEFT", 0, -10)
CardLabel(rateCard, "Live server multipliers")
local rateRows = {}
local function RateRow(parent, label, command, y)
    local l = MakeText(parent, label, "GameFontHighlight", C.text[1], C.text[2], C.text[3])
    l:SetPoint("TOPLEFT", 16, y)
    l:SetWidth(88)
    l:SetJustifyH("LEFT")
    local edit = MakeEdit(parent, 64, "1")
    edit:SetPoint("LEFT", l, "RIGHT", 8, 0)
    local apply = MakeButton(parent, "Apply", 62, 22, function() Send(command .. " " .. edit:GetText()); Send("status") end)
    apply:SetPoint("LEFT", edit, "RIGHT", 7, 0)
    local last = apply
    for _, mult in ipairs({1, 2, 3, 5, 10}) do
        local b = MakeButton(parent, mult .. "x", 44, 22, function() edit:SetText(mult); Send(command .. " " .. mult); Send("status") end)
        b:SetPoint("LEFT", last, "RIGHT", 4, 0)
        last = b
    end
    rateRows[command] = edit
end
RateRow(rateCard, "XP", "xp", -42)
RateRow(rateCard, "Reputation", "rep", -78)
RateRow(rateCard, "Gold", "gold", -114)
local resetRates = MakeButton(rateCard, "Reset all to 1x", 126, 24, function() Send("reset"); Send("status") end)
resetRates:SetPoint("BOTTOMLEFT", 16, 12)

StaticPopupDialogs["AZEROTH_RELEASE_WOTLK"] = {
    text = "Release Wrath of the Lich King?\n\nThis permanently opens WotLK progression, Northrend and level 80 for the realm. Characters are NOT auto-boosted.",
    button1 = "Release WotLK",
    button2 = "Cancel",
    OnAccept = function() Send("releasewotlk confirm"); Send("status") end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
}

-- AI & RAID -----------------------------------------------------------------
local ai = CreatePage("AI & Raid")
PageTitle(ai, "AI & Raid", "Population controls use a safe gradual ramp so 500 bots do not bulldoze the character database again.")

local botCard = Card(ai, 602, 190)
botCard:SetPoint("TOPLEFT", 8, -58)
CardLabel(botCard, "World population")
local botSummary = MakeText(botCard, "Bots ? / ?   •   Activity ?%   •   ramp 10/cycle", "GameFontNormal", C.text[1], C.text[2], C.text[3])
botSummary:SetPoint("TOPLEFT", 14, -40)
local botNote = MakeText(botCard, "Target changes are live and persistent. New logins are intentionally throttled.", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3])
botNote:SetPoint("TOPLEFT", 14, -66)
local botTargets = {0, 100, 250, 500, 750}
local lastBot
for _, target in ipairs(botTargets) do
    local text = target == 0 and "Pause / 0" or tostring(target)
    local b = MakeButton(botCard, text, 84, 24, function() Send("bots " .. target); Send("status") end)
    if not lastBot then b:SetPoint("TOPLEFT", 14, -98) else b:SetPoint("LEFT", lastBot, "RIGHT", 6, 0) end
    lastBot = b
end
local botCustom = MakeEdit(botCard, 70, "500")
botCustom:SetPoint("LEFT", lastBot, "RIGHT", 10, 0)
local botApply = MakeButton(botCard, "Set", 52, 24, function()
    local v = tonumber(botCustom:GetText())
    if v then Send("bots " .. math.floor(v)); Send("status") end
end)
botApply:SetPoint("LEFT", botCustom, "RIGHT", 5, 0)

local actLabel = MakeText(botCard, "Activity", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3])
actLabel:SetPoint("BOTTOMLEFT", 14, 18)
local lastAct
for _, activity in ipairs({25, 50, 75, 100}) do
    local b = MakeButton(botCard, activity .. "%", 58, 22, function() Send("botactivity " .. activity); Send("status") end)
    if not lastAct then b:SetPoint("LEFT", actLabel, "RIGHT", 12, 0) else b:SetPoint("LEFT", lastAct, "RIGHT", 5, 0) end
    lastAct = b
end

local raidCard = Card(ai, 602, 170)
raidCard:SetPoint("TOPLEFT", botCard, "BOTTOMLEFT", 0, -10)
CardLabel(raidCard, "Raid night")
local raidDesc = MakeText(raidCard, "Prepare the current group, remove boring downtime and crank AI activity for the pull.", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3])
raidDesc:SetPoint("TOPLEFT", 14, -42)
local raidNight = MakeButton(raidCard, "RAID NIGHT", 152, 32, function() Send("raidnight"); Send("health") end,
    "Resurrects, fully restores, repairs and resupplies the current group, then sets bot activity to 100%.")
raidNight:SetPoint("TOPLEFT", 14, -72)
local prepGroup = MakeButton(raidCard, "Prep Group", 128, 28, function() Send("groupprep") end)
prepGroup:SetPoint("LEFT", raidNight, "RIGHT", 10, 0)
local summonGroup = MakeButton(raidCard, "Summon Group", 128, 28, function() Send("groupsummon") end)
summonGroup:SetPoint("LEFT", prepGroup, "RIGHT", 10, 0)
local regearRaid = MakeButton(raidCard, "Regear Me", 112, 28, function() Send("regear") end)
regearRaid:SetPoint("LEFT", summonGroup, "RIGHT", 10, 0)

local health2 = Card(ai, 602, 105)
health2:SetPoint("TOPLEFT", raidCard, "BOTTOMLEFT", 0, -10)
CardLabel(health2, "Server health")
local aiHealth = MakeText(health2, "Tick ? ms  •  Mean ? ms  •  P95 ? ms  •  P99 ? ms", "GameFontNormal", C.text[1], C.text[2], C.text[3])
aiHealth:SetPoint("TOPLEFT", 14, -41)
local healthRefresh2 = MakeButton(health2, "Refresh", 82, 22, function() Send("health") end)
healthRefresh2:SetPoint("BOTTOMLEFT", 14, 10)

-- TELEPORTS -----------------------------------------------------------------
local teleportsPage = CreatePage("Teleports")
PageTitle(teleportsPage, "Teleports", "Expansion-aware travel, online-player movement and your own saved locations.")

local tpCard = Card(teleportsPage, 602, 170)
tpCard:SetPoint("TOPLEFT", 8, -58)
CardLabel(tpCard, "Destinations")
local teleportDefs = {
    {"Dark Portal", "darkportal", false}, {"Shattrath", "shattrath", false},
    {"Stormwind", "stormwind", false}, {"Ironforge", "ironforge", false},
    {"Orgrimmar", "orgrimmar", false}, {"Thunder Bluff", "thunderbluff", false},
    {"Dalaran", "dalaran", true}, {"Argent Tournament", "argent", true},
}
local wrathTeleportButtons = {}
for i, entry in ipairs(teleportDefs) do
    local col = (i - 1) % 4
    local row = math.floor((i - 1) / 4)
    local b = MakeButton(tpCard, entry[1], 132, 27, function() Send("tp " .. entry[2]) end,
        entry[3] and "Unlocks when WotLK is released." or nil)
    b:SetPoint("TOPLEFT", 14 + col * 144, -43 - row * 38)
    if entry[3] then table.insert(wrathTeleportButtons, b) end
end
local tpLockText = MakeText(tpCard, "Northrend destinations are locked while TBC is the live expansion.", "GameFontHighlightSmall", C.warning[1], C.warning[2], C.warning[3])
tpLockText:SetPoint("BOTTOMLEFT", 14, 16)

local playerTp = Card(teleportsPage, 602, 105)
playerTp:SetPoint("TOPLEFT", tpCard, "BOTTOMLEFT", 0, -10)
CardLabel(playerTp, "Online player")
local playerEdit = MakeEdit(playerTp, 180, "")
playerEdit:SetPoint("TOPLEFT", 14, -44)
local gotoBtn = MakeButton(playerTp, "Go to player", 112, 24, function()
    if playerEdit:GetText() ~= "" then Send("goto " .. playerEdit:GetText()) end
end)
gotoBtn:SetPoint("LEFT", playerEdit, "RIGHT", 10, 0)
local summonBtn = MakeButton(playerTp, "Summon player", 120, 24, function()
    if playerEdit:GetText() ~= "" then Send("summon " .. playerEdit:GetText()) end
end)
summonBtn:SetPoint("LEFT", gotoBtn, "RIGHT", 8, 0)

local savedCard = Card(teleportsPage, 602, 145)
savedCard:SetPoint("TOPLEFT", playerTp, "BOTTOMLEFT", 0, -10)
CardLabel(savedCard, "Saved locations")
local savedEdit = MakeEdit(savedCard, 160, "home")
savedEdit:SetPoint("TOPLEFT", 14, -44)
local saveBtn = MakeButton(savedCard, "Save here", 96, 24, function()
    if savedEdit:GetText() ~= "" then Send("save " .. savedEdit:GetText()) end
end)
saveBtn:SetPoint("LEFT", savedEdit, "RIGHT", 10, 0)
local goSaved = MakeButton(savedCard, "Go saved", 96, 24, function()
    if savedEdit:GetText() ~= "" then Send("gosaved " .. savedEdit:GetText()) end
end)
goSaved:SetPoint("LEFT", saveBtn, "RIGHT", 7, 0)
local listSaved = MakeButton(savedCard, "List saved", 96, 24, function() Send("saved") end)
listSaved:SetPoint("LEFT", goSaved, "RIGHT", 7, 0)
local savedHint = MakeText(savedCard, "Names may use letters, numbers, '-' and '_'. Saved spots are account-specific.", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3])
savedHint:SetPoint("BOTTOMLEFT", 14, 18)

-- STATE / LIVE UI -----------------------------------------------------------
local function FormatUptime(seconds)
    local s = tonumber(seconds)
    if not s then return "?" end
    local d = math.floor(s / 86400); s = s % 86400
    local h = math.floor(s / 3600); s = s % 3600
    local m = math.floor(s / 60)
    if d > 0 then return string.format("%dd %dh %dm", d, h, m) end
    if h > 0 then return string.format("%dh %dm", h, m) end
    return string.format("%dm", m)
end

local function UpdateUI()
    local wotlk = tostring(state.wotlk) == "1"
    local eraName = wotlk and "WRATH OF THE LICH KING" or "THE BURNING CRUSADE"
    local er, eg, eb = wotlk and 0.40 or C.accent2[1], wotlk and 0.72 or C.accent2[2], wotlk and 1.00 or C.accent2[3]

    eraText:SetText(eraName)
    eraText:SetTextColor(er, eg, eb)
    capText:SetText("LEVEL CAP " .. tostring(state.levelcap or "?"))

    dashEra:SetText(eraName)
    dashEra:SetTextColor(er, eg, eb)
    if wotlk then
        dashLock:SetText("WotLK LIVE • cap " .. tostring(state.levelcap) .. " • progression open")
    else
        dashLock:SetText("WotLK locked • cap " .. tostring(state.levelcap) .. " • stage limit " .. tostring(state.progressionlimit))
    end

    dashCharacter:SetText("Level " .. tostring(state.level) .. "  •  Stage " .. tostring(state.stage))
    dashMoney:SetText(tostring(state.money) .. " gold")
    goldCurrent:SetText("Current: " .. tostring(state.money) .. "g")
    dashRates:SetText("XP " .. tostring(state.xp) .. "x     REP " .. tostring(state.rep) .. "x     GOLD " .. tostring(state.goldrate) .. "x")
    dashPopulation:SetText("Players " .. tostring(state.players) .. "   •   Bots " .. tostring(state.bots) .. " / " .. tostring(state.bottarget))
    dashActivity:SetText("Activity " .. tostring(state.botactivity) .. "%   •   ramp " .. tostring(state.botbatch) .. "/cycle")
    botSummary:SetText("Bots " .. tostring(state.bots) .. " / " .. tostring(state.bottarget) .. "   •   Activity " .. tostring(state.botactivity) .. "%   •   ramp " .. tostring(state.botbatch) .. "/cycle")

    if rateRows.xp then rateRows.xp:SetText(tostring(state.xp)) end
    if rateRows.rep then rateRows.rep:SetText(tostring(state.rep)) end
    if rateRows.gold then rateRows.gold:SetText(tostring(state.goldrate)) end

    if tostring(state.starter) == "tbcraid" then
        currentStarter:SetText("Default new character: TBC Raid Ready • Level 70")
    else
        currentStarter:SetText("Default new character: TBC Adventure • Level 60")
    end

    expansionTitle:SetText(eraName .. "  •  LIVE")
    expansionTitle:SetTextColor(er, eg, eb)
    expansionInfo:SetText("Level cap " .. tostring(state.levelcap) .. "  •  Progression ceiling " .. tostring(state.progressionlimit) .. (wotlk and "  •  WotLK live" or "  •  WotLK locked"))

    if wotlk then
        releaseButton:Hide()
        releaseStatus:SetText("WOTLK LIVE")
        releaseStatus:SetTextColor(C.accent2[1], C.accent2[2], C.accent2[3])
        expansionDesc:SetText("Wrath is released. Stage 13, Northrend and level-80 progression are available normally; nobody was auto-boosted.")
        tpLockText:SetText("WotLK is live. Northrend destinations are unlocked.")
        tpLockText:SetTextColor(C.accent2[1], C.accent2[2], C.accent2[3])
    else
        releaseButton:Show()
        releaseStatus:SetText("LOCKED")
        releaseStatus:SetTextColor(C.warning[1], C.warning[2], C.warning[3])
        expansionDesc:SetText("Finish TBC on your terms. Releasing Wrath opens stage 13, Northrend and level-80 progression. It does NOT boost everyone to 80.")
        tpLockText:SetText("Northrend destinations are locked while TBC is the live expansion.")
        tpLockText:SetTextColor(C.warning[1], C.warning[2], C.warning[3])
    end

    for _, b in ipairs(wrathTeleportButtons) do SetEnabled(b, wotlk) end

    local tick = tonumber(state.tick)
    if tick then
        local healthColor
        if tick <= 75 then healthColor = ColorHex(C.accent2[1], C.accent2[2], C.accent2[3])
        elseif tick <= 150 then healthColor = ColorHex(C.warning[1], C.warning[2], C.warning[3])
        else healthColor = ColorHex(C.danger[1], C.danger[2], C.danger[3]) end
        dashHealth:SetText(healthColor .. "Tick " .. tostring(state.tick) .. " ms|r  •  P95 " .. tostring(state.p95) .. " ms")
        aiHealth:SetText("Tick " .. tostring(state.tick) .. " ms  •  Mean " .. tostring(state.mean) .. " ms  •  P95 " .. tostring(state.p95) .. " ms  •  P99 " .. tostring(state.p99) .. " ms")
    end
    dashUptime:SetText("Uptime " .. FormatUptime(state.uptime) .. "  •  Sessions " .. tostring(state.sessions))
end

local function ParseKeyValues(msg, marker)
    if not string.find(msg, marker, 1, true) then return false end
    for key, value in string.gmatch(msg, "([%a%d_]+)=([^%s]+)") do
        state[key] = value
    end
    return true
end

local event = CreateFrame("Frame")
event:RegisterEvent("CHAT_MSG_SYSTEM")
event:RegisterEvent("PLAYER_LOGIN")
event:SetScript("OnEvent", function(self, evt, msg)
    if evt == "PLAYER_LOGIN" then
        return
    end

    if type(msg) ~= "string" or not string.find(msg, "[AdminPanel]", 1, true) then return end
    footer:SetText(msg)

    if ParseKeyValues(msg, "[AdminPanel] STATUS") then
        UpdateUI()
    elseif ParseKeyValues(msg, "[AdminPanel] HEALTH") then
        UpdateUI()
    elseif string.find(msg, "WOTLK RELEASED", 1, true) then
        Send("status")
        Send("health")
    end
end)

-- MINIMAP + SLASH ------------------------------------------------------------
local mini = CreateFrame("Button", "AzerothAdminPanelMinimapButton", Minimap)
mini:SetWidth(31)
mini:SetHeight(31)
mini:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -4, -4)
mini:SetFrameStrata("MEDIUM")
mini:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
mini:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
local miniText = MakeText(mini, "AP", "GameFontNormalSmall", C.accent[1], C.accent[2], C.accent[3])
miniText:SetPoint("CENTER", 0, 1)
mini:SetScript("OnClick", function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        SelectPage(DB.page or "Dashboard")
        Send("status")
        Send("health")
    end
end)
mini:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Azeroth Control", 1, 1, 1)
    GameTooltip:AddLine("GM realm controls • click to open", 0.75, 0.82, 0.92)
    GameTooltip:Show()
end)
mini:SetScript("OnLeave", function() GameTooltip:Hide() end)

SLASH_AZEROTHADMIN1 = "/ap"
SLASH_AZEROTHADMIN2 = "/adminpanel"
SlashCmdList["AZEROTHADMIN"] = function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        SelectPage(DB.page or "Dashboard")
        Send("status")
        Send("health")
    end
end

SelectPage(DB.page or "Dashboard")
UpdateUI()

local addonName = ...

AzerothAdminPanelDB = AzerothAdminPanelDB or {}
local DB = AzerothAdminPanelDB
DB.point = DB.point or { "CENTER", "UIParent", "CENTER", 0, 0 }
DB.page = DB.page or "Dashboard"

local state = {
    era = "VANILLA",
    tbc = "0",
    wotlk = "0",
    levelcap = "60",
    progressionlimit = "7",
    stage = "?",
    level = "?",
    money = "?",
    xp = "1.00",
    rep = "1.00",
    goldrate = "1.00",
    starter = "vanilla",
    players = "?",
    bots = "?",
    bottarget = "?",
    botbatch = "10",
    botactivity = "?",
    botstate = "?",
    botcapacity = "?",
    botcandidates = "?",
    botpending = "?",
    uptime = "?",
    sessions = "?",
    tick = "?",
    mean = "?",
    p95 = "?",
    p99 = "?",
}

local C = {
    bg = { 0.028, 0.032, 0.046, 0.985 },
    header = { 0.043, 0.050, 0.070, 1.0 },
    sidebar = { 0.038, 0.043, 0.059, 1.0 },
    panel = { 0.058, 0.066, 0.090, 0.98 },
    line = { 0.18, 0.21, 0.29, 0.95 },
    cyan = { 0.16, 0.72, 0.94, 1.0 },
    green = { 0.28, 0.84, 0.56, 1.0 },
    wrath = { 0.42, 0.70, 1.00, 1.0 },
    warning = { 1.00, 0.67, 0.20, 1.0 },
    danger = { 0.96, 0.30, 0.30, 1.0 },
    text = { 0.93, 0.95, 0.99, 1.0 },
    muted = { 0.62, 0.67, 0.77, 1.0 },
}

local function Hex(r, g, b)
    return string.format("|cff%02x%02x%02x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
end

local function Send(command)
    if command and command ~= "" then SendChatMessage(".ap " .. command, "SAY") end
end

local function SendRaw(command)
    if command and command ~= "" then SendChatMessage(command, "SAY") end
end

local function Solid(parent, layer, r, g, b, a)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetTexture(r, g, b, a or 1)
    return t
end

local function Text(parent, value, template, r, g, b)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    fs:SetText(value or "")
    if r then fs:SetTextColor(r, g, b) end
    return fs
end

local function SetEnabled(button, enabled)
    if not button then return end
    if enabled then button:Enable(); button:SetAlpha(1.0) else button:Disable(); button:SetAlpha(0.42) end
end

local function Button(parent, label, width, height, onClick, tooltip)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetWidth(width or 100)
    b:SetHeight(height or 24)
    b:SetText(label or "Button")
    if onClick then b:SetScript("OnClick", onClick) end
    if tooltip then
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label or "", 1, 1, 1)
            GameTooltip:AddLine(tooltip, 0.78, 0.82, 0.90, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return b
end

local function Edit(parent, width, value)
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
frame:SetWidth(860)
frame:SetHeight(710)
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

local headerBg = Solid(frame, "BACKGROUND", C.header[1], C.header[2], C.header[3], 1)
headerBg:SetPoint("TOPLEFT", 5, -5); headerBg:SetPoint("TOPRIGHT", -5, -5); headerBg:SetHeight(64)
local title = Text(frame, "AZEROTH CONTROL", "GameFontNormalLarge", C.text[1], C.text[2], C.text[3])
title:SetPoint("TOPLEFT", 22, -18)
local subtitle = Text(frame, "Vanilla → TBC → WotLK private realm control center", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3])
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)

local eraBadge = CreateFrame("Frame", nil, frame)
eraBadge:SetWidth(218); eraBadge:SetHeight(38); eraBadge:SetPoint("TOP", 58, -14)
local eraBadgeBg = Solid(eraBadge, "BACKGROUND", 0.10, 0.13, 0.18, 1); eraBadgeBg:SetAllPoints(eraBadge)
local eraText = Text(eraBadge, "VANILLA", "GameFontNormal", C.warning[1], C.warning[2], C.warning[3]); eraText:SetPoint("CENTER", 0, 6)
local capText = Text(eraBadge, "LEVEL CAP 60", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); capText:SetPoint("CENTER", 0, -9)
local refresh = Button(frame, "Refresh", 82, 25, function() Send("status"); Send("health") end, "Refresh character, expansion, AI population and server-health data.")
refresh:SetPoint("TOPRIGHT", -48, -24)
local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -8, -8)

local sidebar = CreateFrame("Frame", nil, frame)
sidebar:SetWidth(148); sidebar:SetPoint("TOPLEFT", 8, -74); sidebar:SetPoint("BOTTOMLEFT", 8, 38)
local sidebarBg = Solid(sidebar, "BACKGROUND", C.sidebar[1], C.sidebar[2], C.sidebar[3], 1); sidebarBg:SetAllPoints(sidebar)
local content = CreateFrame("Frame", nil, frame); content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 10, 0); content:SetPoint("BOTTOMRIGHT", -10, 38)
local footerLine = Solid(frame, "ARTWORK", C.line[1], C.line[2], C.line[3], 0.9); footerLine:SetPoint("BOTTOMLEFT", 12, 34); footerLine:SetPoint("BOTTOMRIGHT", -12, 34); footerLine:SetHeight(1)
local footer = Text(frame, "Ready. /ap toggles Azeroth Control.", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); footer:SetPoint("BOTTOMLEFT", 18, 15); footer:SetPoint("BOTTOMRIGHT", -18, 15); footer:SetJustifyH("LEFT")

local pages, tabs = {}, {}
local function CreatePage(name)
    local p = CreateFrame("Frame", nil, content); p:SetAllPoints(content); p:Hide(); pages[name] = p; return p
end
local function PageTitle(page, heading, desc)
    local h = Text(page, heading, "GameFontNormalLarge", C.text[1], C.text[2], C.text[3]); h:SetPoint("TOPLEFT", 8, -4)
    local d = Text(page, desc or "", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); d:SetPoint("TOPLEFT", h, "BOTTOMLEFT", 0, -4); d:SetWidth(650); d:SetJustifyH("LEFT")
end
local function Card(parent, width, height)
    local c = CreateFrame("Frame", nil, parent); c:SetWidth(width); c:SetHeight(height)
    local bg = Solid(c, "BACKGROUND", C.panel[1], C.panel[2], C.panel[3], C.panel[4]); bg:SetAllPoints(c)
    local line = Solid(c, "ARTWORK", C.line[1], C.line[2], C.line[3], 0.8); line:SetPoint("TOPLEFT", 0, 0); line:SetPoint("TOPRIGHT", 0, 0); line:SetHeight(1)
    return c
end
local function CardLabel(card, label)
    local l = Text(card, string.upper(label), "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); l:SetPoint("TOPLEFT", 14, -12); return l
end
local function SelectPage(name)
    if not pages[name] then return end
    for pageName, page in pairs(pages) do if pageName == name then page:Show() else page:Hide() end end
    for tabName, button in pairs(tabs) do if tabName == name then button:LockHighlight() else button:UnlockHighlight() end end
    DB.page = name
end

local tabNames = { "Dashboard", "Character", "World", "AI & Raid", "Teleports" }
for i, name in ipairs(tabNames) do
    local tabName = name
    local b = CreateFrame("Button", nil, sidebar, "UIPanelButtonTemplate")
    b:SetWidth(128); b:SetHeight(31); b:SetText(tabName); b:SetPoint("TOP", 0, -13 - ((i - 1) * 38))
    b:SetScript("OnClick", function() SelectPage(tabName) end)
    tabs[tabName] = b
end
local sidebarEra = Text(sidebar, "VANILLA LIVE", "GameFontNormal", C.warning[1], C.warning[2], C.warning[3]); sidebarEra:SetPoint("TOP", 0, -226)
local sidebarCap = Text(sidebar, "Cap 60 • stage 7", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); sidebarCap:SetPoint("TOP", sidebarEra, "BOTTOM", 0, -5)
local sidebarHelp = Text(sidebar, "GM-only controls\nchanges save automatically", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); sidebarHelp:SetPoint("BOTTOM", 0, 18); sidebarHelp:SetJustifyH("CENTER")

-- DASHBOARD -----------------------------------------------------------------
local dashboard = CreatePage("Dashboard")
PageTitle(dashboard, "Dashboard", "Realm status, expansion state and the shortcuts you will actually use while playing.")
local eraCard = Card(dashboard, 326, 112); eraCard:SetPoint("TOPLEFT", 8, -58); CardLabel(eraCard, "Current expansion")
local dashEra = Text(eraCard, "VANILLA", "GameFontNormalLarge", C.warning[1], C.warning[2], C.warning[3]); dashEra:SetPoint("TOPLEFT", 14, -36)
local dashLock = Text(eraCard, "TBC locked • cap 60 • stage limit 7", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); dashLock:SetPoint("TOPLEFT", 14, -67)
local dashExpansionAction = Button(eraCard, "Release TBC", 120, 23, function()
    if tostring(state.era) == "VANILLA" then StaticPopup_Show("AZEROTH_RELEASE_TBC")
    elseif tostring(state.era) == "TBC" then StaticPopup_Show("AZEROTH_RELEASE_WOTLK") end
end); dashExpansionAction:SetPoint("BOTTOMLEFT", 14, 10)
local charCard = Card(dashboard, 326, 112); charCard:SetPoint("TOPLEFT", eraCard, "TOPRIGHT", 10, 0); CardLabel(charCard, "Your character")
local dashCharacter = Text(charCard, "Level ?  •  Stage ?", "GameFontNormalLarge", C.text[1], C.text[2], C.text[3]); dashCharacter:SetPoint("TOPLEFT", 14, -36)
local dashMoney = Text(charCard, "? gold", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); dashMoney:SetPoint("TOPLEFT", 14, -67)
local dashRaidReady = Button(charCard, "Vanilla Journey", 128, 23, function()
    if tostring(state.era) == "TBC" then Send("tbcraidready"); Send("status")
    elseif tostring(state.era) == "WOTLK" then Send("wotlkraidready"); Send("status") end
end); dashRaidReady:SetPoint("BOTTOMLEFT", 14, 10)
local ratesCard = Card(dashboard, 662, 96); ratesCard:SetPoint("TOPLEFT", eraCard, "BOTTOMLEFT", 0, -10); CardLabel(ratesCard, "Rates")
local dashRates = Text(ratesCard, "XP 1.00x     REP 1.00x     GOLD 1.00x", "GameFontNormal", C.text[1], C.text[2], C.text[3]); dashRates:SetPoint("TOPLEFT", 14, -40)
local presetNormal = Button(ratesCard, "Normal", 82, 23, function() Send("preset normal"); Send("status") end); presetNormal:SetPoint("TOPRIGHT", -198, -49)
local presetFast = Button(ratesCard, "Fast", 82, 23, function() Send("preset fast"); Send("status") end); presetFast:SetPoint("LEFT", presetNormal, "RIGHT", 6, 0)
local presetRaid = Button(ratesCard, "Raid", 82, 23, function() Send("preset raid"); Send("status") end); presetRaid:SetPoint("LEFT", presetFast, "RIGHT", 6, 0)
local populationCard = Card(dashboard, 326, 122); populationCard:SetPoint("TOPLEFT", ratesCard, "BOTTOMLEFT", 0, -10); CardLabel(populationCard, "Population")
local dashPopulation = Text(populationCard, "Players ?   •   Bots ? / ?", "GameFontNormal", C.text[1], C.text[2], C.text[3]); dashPopulation:SetPoint("TOPLEFT", 14, -40)
local dashActivity = Text(populationCard, "Activity ?% • ramp ?/cycle", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); dashActivity:SetPoint("TOPLEFT", 14, -67)
local goAi = Button(populationCard, "AI & Raid controls", 138, 23, function() SelectPage("AI & Raid") end); goAi:SetPoint("BOTTOMLEFT", 14, 11)
local healthCard = Card(dashboard, 326, 122); healthCard:SetPoint("TOPLEFT", populationCard, "TOPRIGHT", 10, 0); CardLabel(healthCard, "World health")
local dashHealth = Text(healthCard, "Waiting for health data...", "GameFontNormal", C.text[1], C.text[2], C.text[3]); dashHealth:SetPoint("TOPLEFT", 14, -40)
local dashUptime = Text(healthCard, "Uptime ?", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); dashUptime:SetPoint("TOPLEFT", 14, -67)
local healthRefresh = Button(healthCard, "Refresh health", 112, 23, function() Send("health") end); healthRefresh:SetPoint("BOTTOMLEFT", 14, 11)
local quickCard = Card(dashboard, 662, 102); quickCard:SetPoint("TOPLEFT", populationCard, "BOTTOMLEFT", 0, -10); CardLabel(quickCard, "Quick actions")
local qRepair = Button(quickCard, "Repair", 96, 25, function() Send("repair") end); qRepair:SetPoint("BOTTOMLEFT", 14, 15)
local qRestore = Button(quickCard, "Restore", 96, 25, function() Send("restore") end); qRestore:SetPoint("LEFT", qRepair, "RIGHT", 8, 0)
local qGold = Button(quickCard, "+1000g", 96, 25, function() Send("givegold 1000"); Send("status") end); qGold:SetPoint("LEFT", qRestore, "RIGHT", 8, 0)
local qPrep = Button(quickCard, "Prep Group", 108, 25, function() Send("groupprep") end); qPrep:SetPoint("LEFT", qGold, "RIGHT", 8, 0)
local qRaid = Button(quickCard, "RAID NIGHT", 124, 25, function() Send("raidnight"); Send("health") end); qRaid:SetPoint("LEFT", qPrep, "RIGHT", 8, 0)

-- CHARACTER -----------------------------------------------------------------
local character = CreatePage("Character")
PageTitle(character, "Character", "Gold, repairs, supplies, talents and era-appropriate raid-ready shortcuts.")
local goldCard = Card(character, 662, 112); goldCard:SetPoint("TOPLEFT", 8, -58); CardLabel(goldCard, "Give yourself gold")
local goldValues = { 100, 1000, 5000, 10000 }
local lastGold
for _, amount in ipairs(goldValues) do
    local amountValue = amount
    local b = Button(goldCard, "+" .. amountValue .. "g", 84, 24, function() Send("givegold " .. amountValue); Send("status") end)
    if lastGold then b:SetPoint("LEFT", lastGold, "RIGHT", 6, 0) else b:SetPoint("TOPLEFT", 14, -42) end
    lastGold = b
end
local customGold = Edit(goldCard, 96, "2500"); customGold:SetPoint("LEFT", lastGold, "RIGHT", 14, 0)
local giveCustomGold = Button(goldCard, "Give", 70, 24, function() local amount = tonumber(customGold:GetText()); if amount and amount > 0 then Send("givegold " .. math.floor(amount)); Send("status") end end); giveCustomGold:SetPoint("LEFT", customGold, "RIGHT", 6, 0)
local goldCurrent = Text(goldCard, "Current: ?g", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); goldCurrent:SetPoint("BOTTOMLEFT", 14, 12)
local utilCard = Card(character, 662, 144); utilCard:SetPoint("TOPLEFT", goldCard, "BOTTOMLEFT", 0, -10); CardLabel(utilCard, "Character utilities")
local utilities = {
    { "Repair all", "repair", "Free full durability repair." },
    { "Restore / Res", "restore", "Resurrect if needed and refill health/power." },
    { "Max skills", "maxskills", "Max weapon/class skills for your current level." },
    { "Refill supplies", "consumables", "Ammo, reagents, food and potions." },
    { "Reset talents", "resettalents", "Free current-era talent reset." },
    { "TBC pre-raid regear", "regear", "Spec-aware ilvl-115 TBC pre-raid gear." },
}
for i, entry in ipairs(utilities) do
    local label, command, tip = entry[1], entry[2], entry[3]
    local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
    local b = Button(utilCard, label, 190, 26, function() Send(command) end, tip)
    b:SetPoint("TOPLEFT", 14 + col * 208, -42 - row * 37)
end
local tbcStartCard = Card(character, 662, 142); tbcStartCard:SetPoint("TOPLEFT", utilCard, "BOTTOMLEFT", 0, -10); CardLabel(tbcStartCard, "The Burning Crusade")
local currentStarter = Text(tbcStartCard, "Default new character: Vanilla fresh start • Level 1", "GameFontNormal", C.text[1], C.text[2], C.text[3]); currentStarter:SetPoint("TOPLEFT", 14, -39)
local starter60 = Button(tbcStartCard, "New chars: Adventure 60", 190, 26, function() Send("starter tbc"); Send("status") end); starter60:SetPoint("TOPLEFT", 14, -72)
local starter70 = Button(tbcStartCard, "New chars: Raid Ready 70", 190, 26, function() Send("starter tbcraid"); Send("status") end); starter70:SetPoint("LEFT", starter60, "RIGHT", 10, 0)
local makeTbcReady = Button(tbcStartCard, "Make THIS char TBC Raid Ready", 238, 26, function() Send("tbcraidready"); Send("status") end); makeTbcReady:SetPoint("LEFT", starter70, "RIGHT", 10, 0)
local tbcNote = Text(tbcStartCard, "Stage 8 stays intact, so Kara / Gruul / Mag remain the first raid tier.", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); tbcNote:SetPoint("BOTTOMLEFT", 14, 13)
local wrathCard = Card(character, 662, 132); wrathCard:SetPoint("TOPLEFT", tbcStartCard, "BOTTOMLEFT", 0, -10); CardLabel(wrathCard, "Wrath of the Lich King")
local wrathCharStatus = Text(wrathCard, "LOCKED • release WotLK from the World page first", "GameFontNormal", C.warning[1], C.warning[2], C.warning[3]); wrathCharStatus:SetPoint("TOPLEFT", 14, -39)
local starter80 = Button(wrathCard, "New chars: Raid Ready 80", 208, 28, function() Send("starter wotlkraid"); Send("status") end, "Unlocked only after WotLK release. New characters start at level 80/stage 13 in Dalaran."); starter80:SetPoint("TOPLEFT", 14, -75)
local makeWrathReady = Button(wrathCard, "Make THIS char WotLK Raid Ready", 252, 28, function() Send("wotlkraidready"); Send("status") end, "Level 80, Dalaran, max riding, supplies and ilvl-200 pre-Naxx gear. Also completes this realm's WotLK progression/access campaign (stage 18), Frozen Halls, Undercity phasing and DK intro access. Heroic achievement gates stay normal."); makeWrathReady:SetPoint("LEFT", starter80, "RIGHT", 10, 0)
local wrathGearNote = Text(wrathCard, "Pre-Naxx ilvl 200 • WotLK progression/access complete • heroic achievements stay normal", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); wrathGearNote:SetPoint("BOTTOMLEFT", 14, 12)

-- WORLD ---------------------------------------------------------------------
local world = CreatePage("World")
PageTitle(world, "World & expansion", "Control the expansion timeline, live rates, progression and realm announcements.")
local expansionCard = Card(world, 662, 188); expansionCard:SetPoint("TOPLEFT", 8, -58); CardLabel(expansionCard, "Expansion timeline")
local expansionTitle = Text(expansionCard, "VANILLA • LIVE", "GameFontNormalLarge", C.warning[1], C.warning[2], C.warning[3]); expansionTitle:SetPoint("TOPLEFT", 14, -40)
local expansionInfo = Text(expansionCard, "Level cap 60 • progression ceiling 7 • TBC locked", "GameFontHighlight", C.text[1], C.text[2], C.text[3]); expansionInfo:SetPoint("TOPLEFT", 14, -73)
local expansionDesc = Text(expansionCard, "Play Vanilla normally. When you are ready, release The Burning Crusade manually; later do the same for Wrath. Existing characters are never auto-boosted.", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); expansionDesc:SetPoint("TOPLEFT", 14, -104); expansionDesc:SetWidth(620); expansionDesc:SetJustifyH("LEFT")
local releaseButton = Button(expansionCard, "RELEASE THE BURNING CRUSADE", 300, 31, function()
    if tostring(state.era) == "VANILLA" then StaticPopup_Show("AZEROTH_RELEASE_TBC")
    elseif tostring(state.era) == "TBC" then StaticPopup_Show("AZEROTH_RELEASE_WOTLK") end
end, "Permanent realm milestone. Advances the live expansion without auto-boosting characters."); releaseButton:SetPoint("BOTTOMLEFT", 14, 16)
local releaseStatus = Text(expansionCard, "LOCKED", "GameFontNormal", C.warning[1], C.warning[2], C.warning[3]); releaseStatus:SetPoint("LEFT", releaseButton, "RIGHT", 18, 0)
local rateCard = Card(world, 662, 176); rateCard:SetPoint("TOPLEFT", expansionCard, "BOTTOMLEFT", 0, -10); CardLabel(rateCard, "Live server multipliers")
local rateRows = {}
local function RateRow(parent, label, command, y)
    local l = Text(parent, label, "GameFontHighlight", C.text[1], C.text[2], C.text[3]); l:SetPoint("TOPLEFT", 16, y); l:SetWidth(90); l:SetJustifyH("LEFT")
    local edit = Edit(parent, 64, "1"); edit:SetPoint("LEFT", l, "RIGHT", 8, 0)
    local apply = Button(parent, "Apply", 62, 22, function() Send(command .. " " .. edit:GetText()); Send("status") end); apply:SetPoint("LEFT", edit, "RIGHT", 7, 0)
    local last = apply
    for _, mult in ipairs({ 1, 2, 3, 5, 10 }) do
        local multValue = mult
        local b = Button(parent, multValue .. "x", 45, 22, function() edit:SetText(tostring(multValue)); Send(command .. " " .. multValue); Send("status") end)
        b:SetPoint("LEFT", last, "RIGHT", 4, 0); last = b
    end
    rateRows[command] = edit
end
RateRow(rateCard, "XP", "xp", -42); RateRow(rateCard, "Reputation", "rep", -78); RateRow(rateCard, "Gold", "gold", -114)
local resetRates = Button(rateCard, "Reset all to 1x", 126, 23, function() Send("reset"); Send("status") end); resetRates:SetPoint("BOTTOMLEFT", 16, 10)
local worldTools = Card(world, 662, 182); worldTools:SetPoint("TOPLEFT", rateCard, "BOTTOMLEFT", 0, -10); CardLabel(worldTools, "Progression & announcements")
local progressLabel = Text(worldTools, "Set THIS character stage", "GameFontHighlight", C.text[1], C.text[2], C.text[3]); progressLabel:SetPoint("TOPLEFT", 14, -40)
local stageButtons = {}
local stageValues = { 0, 1, 3, 5, 7, 8, 9, 10, 12, 13, 14, 15, 16, 17, 18 }
for index, stage in ipairs(stageValues) do
    local stageValue = stage
    local b = Button(worldTools, tostring(stageValue), 39, 22, function() Send("progression " .. stageValue); Send("status") end)
    local row = math.floor((index - 1) / 8)
    local col = (index - 1) % 8
    b:SetPoint("TOPLEFT", 14 + col * 44, -62 - row * 27)
    stageButtons[stageValue] = b
end
local stageHint = Text(worldTools, "0 Vanilla start • 7 Vanilla complete • 8 TBC start • 12 late TBC • 13 Wrath start", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); stageHint:SetPoint("TOPLEFT", 14, -119)
local announceEdit = Edit(worldTools, 400, "Raid forming in 10 minutes!"); announceEdit:SetPoint("BOTTOMLEFT", 14, 20); announceEdit:SetJustifyH("LEFT")
local announceBtn = Button(worldTools, "Announce", 96, 24, function() local msg = announceEdit:GetText(); if msg and msg ~= "" then Send("announce " .. msg) end end); announceBtn:SetPoint("LEFT", announceEdit, "RIGHT", 10, 0)

StaticPopupDialogs["AZEROTH_RELEASE_TBC"] = {
    text = "Release The Burning Crusade?\n\nThis advances the realm from Vanilla to TBC, opens Outland progression and raises the cap to 70. Existing characters are NOT auto-boosted.",
    button1 = "Release TBC", button2 = "Cancel",
    OnAccept = function() Send("releasetbc confirm"); Send("status"); Send("health") end,
    timeout = 0, whileDead = 1, hideOnEscape = 1, preferredIndex = 3,
}
StaticPopupDialogs["AZEROTH_RELEASE_WOTLK"] = {
    text = "Release Wrath of the Lich King?\n\nThis advances the realm from TBC to WotLK, opens Northrend progression, level 80 and Titan Rune systems. Existing characters are NOT auto-boosted.",
    button1 = "Release WotLK", button2 = "Cancel",
    OnAccept = function() Send("releasewotlk confirm"); Send("status"); Send("health") end,
    timeout = 0, whileDead = 1, hideOnEscape = 1, preferredIndex = 3,
}

-- AI & RAID -----------------------------------------------------------------
local ai = CreatePage("AI & Raid")
PageTitle(ai, "AI & Raid", "Safe bot-population controls plus the one-click tools for dungeon and raid nights.")
local botCard = Card(ai, 662, 218); botCard:SetPoint("TOPLEFT", 8, -58); CardLabel(botCard, "World population")
local botSummary = Text(botCard, "Bots ? / ? • capacity ? • pending ? • ?", "GameFontNormal", C.text[1], C.text[2], C.text[3]); botSummary:SetPoint("TOPLEFT", 14, -40)
local botNote = Text(botCard, "One saved target controls provisioning, login backpressure and protected scale-down.", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); botNote:SetPoint("TOPLEFT", 14, -66)
local botPresetButtons = {}
for index, target in ipairs({ 500, 750, 1000, 1500 }) do
    local targetValue = target
    local b = Button(botCard, targetValue .. " Bots", 145, 27, function() Send("bots " .. targetValue); Send("status") end)
    b:SetPoint("TOPLEFT", 14 + (index - 1) * 157, -94)
    botPresetButtons[targetValue] = b
end
local lastBot
for _, target in ipairs({ 0, 100, 250 }) do
    local targetValue = target
    local label = targetValue == 0 and "Pause / 0" or tostring(targetValue) .. " Bots"
    local b = Button(botCard, label, 92, 24, function() Send("bots " .. targetValue); Send("status") end)
    if lastBot then b:SetPoint("LEFT", lastBot, "RIGHT", 6, 0) else b:SetPoint("TOPLEFT", 14, -132) end
    lastBot = b
    botPresetButtons[targetValue] = b
end
local botCustom = Edit(botCard, 70, "500"); botCustom:SetPoint("LEFT", lastBot, "RIGHT", 12, 0)
local botSet = Button(botCard, "Set target", 82, 24, function() local v = tonumber(botCustom:GetText()); if v then Send("bots " .. math.floor(v)); Send("status") end end); botSet:SetPoint("LEFT", botCustom, "RIGHT", 5, 0)
local activityLabel = Text(botCard, "Activity", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); activityLabel:SetPoint("BOTTOMLEFT", 14, 17)
local lastAct
for _, pct in ipairs({ 25, 50, 75, 100 }) do
    local pctValue = pct
    local b = Button(botCard, pctValue .. "%", 58, 22, function() Send("botactivity " .. pctValue); Send("status") end)
    if lastAct then b:SetPoint("LEFT", lastAct, "RIGHT", 5, 0) else b:SetPoint("LEFT", activityLabel, "RIGHT", 12, 0) end
    lastAct = b
end
local raidCard = Card(ai, 662, 134); raidCard:SetPoint("TOPLEFT", botCard, "BOTTOMLEFT", 0, -10); CardLabel(raidCard, "Raid night")
local raidDesc = Text(raidCard, "Repair, resurrect, restore and resupply the current group, then push bot activity to 100%.", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); raidDesc:SetPoint("TOPLEFT", 14, -40)
local raidNight = Button(raidCard, "RAID NIGHT", 152, 31, function() Send("raidnight"); Send("health") end); raidNight:SetPoint("TOPLEFT", 14, -70)
local prepGroup = Button(raidCard, "Prep Group", 120, 27, function() Send("groupprep") end); prepGroup:SetPoint("LEFT", raidNight, "RIGHT", 10, 0)
local summonGroup = Button(raidCard, "Summon Group", 126, 27, function() Send("groupsummon") end); summonGroup:SetPoint("LEFT", prepGroup, "RIGHT", 10, 0)
local listBinds = Button(raidCard, "Lockouts", 92, 27, function() SendRaw(".instance listbinds") end); listBinds:SetPoint("LEFT", summonGroup, "RIGHT", 10, 0)
local clearBinds = Button(raidCard, "Clear Lockouts", 116, 27, function() StaticPopup_Show("AZEROTH_CLEAR_LOCKOUTS") end); clearBinds:SetPoint("LEFT", listBinds, "RIGHT", 8, 0)
local rosterCard = Card(ai, 662, 150); rosterCard:SetPoint("TOPLEFT", raidCard, "BOTTOMLEFT", 0, -10); CardLabel(rosterCard, "AI raid roster")
local rosterDesc = Text(rosterCard, "Create your persistent roster once, then log in the size you want and sync their level/spec/gear to you.", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); rosterDesc:SetPoint("TOPLEFT", 14, -40)
local rosterCreate = Button(rosterCard, "Create / Top Up", 122, 25, function() SendRaw(".raidroster create") end); rosterCreate:SetPoint("TOPLEFT", 14, -72)
local rosterSync = Button(rosterCard, "Sync", 82, 25, function() SendRaw(".raidroster sync") end); rosterSync:SetPoint("LEFT", rosterCreate, "RIGHT", 8, 0)
local rosterLogout = Button(rosterCard, "Logout", 82, 25, function() SendRaw(".raidroster logout") end); rosterLogout:SetPoint("LEFT", rosterSync, "RIGHT", 8, 0)
local previousSize
for _, size in ipairs({ 5, 10, 25, 40 }) do
    local sizeValue = size
    local b = Button(rosterCard, sizeValue .. "-man", 82, 25, function() SendRaw(".raidroster login " .. sizeValue) end)
    if previousSize then b:SetPoint("LEFT", previousSize, "RIGHT", 7, 0) else b:SetPoint("TOPLEFT", 14, -111) end
    previousSize = b
end
local aiHealth = Text(rosterCard, "Tick ? ms • Mean ? • P95 ? • P99 ?", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); aiHealth:SetPoint("BOTTOMLEFT", 14, 12)
StaticPopupDialogs["AZEROTH_CLEAR_LOCKOUTS"] = { text = "Clear all instance lockouts for the current character?", button1 = "Clear", button2 = "Cancel", OnAccept = function() SendRaw(".instance unbind all") end, timeout = 0, whileDead = 1, hideOnEscape = 1, preferredIndex = 3 }

-- TELEPORTS -----------------------------------------------------------------
local teleports = CreatePage("Teleports")
PageTitle(teleports, "Teleports", "Expansion-aware travel, player movement and account-specific saved locations.")
local destinationCard = Card(teleports, 662, 176); destinationCard:SetPoint("TOPLEFT", 8, -58); CardLabel(destinationCard, "Destinations")
local teleportDefs = {
    { "Dark Portal", "darkportal", 0 }, { "Shattrath", "shattrath", 1 }, { "Stormwind", "stormwind", 0 }, { "Ironforge", "ironforge", 0 },
    { "Orgrimmar", "orgrimmar", 0 }, { "Thunder Bluff", "thunderbluff", 0 }, { "Dalaran", "dalaran", 2 }, { "Argent Tournament", "argent", 2 },
}
local eraTeleportButtons = {}
for i, entry in ipairs(teleportDefs) do
    local label, key, requiredEra = entry[1], entry[2], entry[3]
    local col, row = (i - 1) % 4, math.floor((i - 1) / 4)
    local tip = requiredEra == 2 and "Unlocks when WotLK is released." or (requiredEra == 1 and "Unlocks when TBC is released." or nil)
    local b = Button(destinationCard, label, 142, 27, function() Send("tp " .. key) end, tip)
    b:SetPoint("TOPLEFT", 14 + col * 156, -43 - row * 39)
    eraTeleportButtons[#eraTeleportButtons + 1] = { button = b, requiredEra = requiredEra }
end
local tpLock = Text(destinationCard, "Vanilla is live. Outland and Northrend destinations remain locked.", "GameFontHighlightSmall", C.warning[1], C.warning[2], C.warning[3]); tpLock:SetPoint("BOTTOMLEFT", 14, 15)
local playerTp = Card(teleports, 662, 112); playerTp:SetPoint("TOPLEFT", destinationCard, "BOTTOMLEFT", 0, -10); CardLabel(playerTp, "Online player")
local playerEdit = Edit(playerTp, 190, ""); playerEdit:SetPoint("TOPLEFT", 14, -45)
local gotoBtn = Button(playerTp, "Go to player", 116, 24, function() if playerEdit:GetText() ~= "" then Send("goto " .. playerEdit:GetText()) end end); gotoBtn:SetPoint("LEFT", playerEdit, "RIGHT", 10, 0)
local summonBtn = Button(playerTp, "Summon player", 122, 24, function() if playerEdit:GetText() ~= "" then Send("summon " .. playerEdit:GetText()) end end); summonBtn:SetPoint("LEFT", gotoBtn, "RIGHT", 8, 0)
local savedCard = Card(teleports, 662, 150); savedCard:SetPoint("TOPLEFT", playerTp, "BOTTOMLEFT", 0, -10); CardLabel(savedCard, "Saved locations")
local savedEdit = Edit(savedCard, 170, "home"); savedEdit:SetPoint("TOPLEFT", 14, -45)
local saveBtn = Button(savedCard, "Save here", 98, 24, function() if savedEdit:GetText() ~= "" then Send("save " .. savedEdit:GetText()) end end); saveBtn:SetPoint("LEFT", savedEdit, "RIGHT", 10, 0)
local goSaved = Button(savedCard, "Go saved", 98, 24, function() if savedEdit:GetText() ~= "" then Send("gosaved " .. savedEdit:GetText()) end end); goSaved:SetPoint("LEFT", saveBtn, "RIGHT", 7, 0)
local listSaved = Button(savedCard, "List saved", 98, 24, function() Send("saved") end); listSaved:SetPoint("LEFT", goSaved, "RIGHT", 7, 0)
local savedHint = Text(savedCard, "Names may use letters, numbers, '-' and '_'. Saved spots belong to your account.", "GameFontHighlightSmall", C.muted[1], C.muted[2], C.muted[3]); savedHint:SetPoint("BOTTOMLEFT", 14, 18)

-- LIVE STATE ----------------------------------------------------------------
local function FormatUptime(seconds)
    local s = tonumber(seconds); if not s then return "?" end
    local d = math.floor(s / 86400); s = s % 86400; local h = math.floor(s / 3600); s = s % 3600; local m = math.floor(s / 60)
    if d > 0 then return string.format("%dd %dh %dm", d, h, m) end
    if h > 0 then return string.format("%dh %dm", h, m) end
    return string.format("%dm", m)
end

local function UpdateUI()
    local era = string.upper(tostring(state.era or "VANILLA"))
    local eraIndex = era == "WOTLK" and 2 or (era == "TBC" and 1 or 0)
    local tbc = eraIndex >= 1
    local wotlk = eraIndex >= 2
    local eraName = era == "WOTLK" and "WRATH OF THE LICH KING" or (era == "TBC" and "THE BURNING CRUSADE" or "VANILLA")
    local color = era == "WOTLK" and C.wrath or (era == "TBC" and C.green or C.warning)
    local r, g, b = color[1], color[2], color[3]

    eraText:SetText(eraName); eraText:SetTextColor(r, g, b); capText:SetText("LEVEL CAP " .. tostring(state.levelcap))
    sidebarEra:SetText(era .. " LIVE"); sidebarEra:SetTextColor(r, g, b)
    sidebarCap:SetText("Cap " .. tostring(state.levelcap) .. " • stage " .. tostring(state.progressionlimit))
    dashEra:SetText(eraName); dashEra:SetTextColor(r, g, b)
    dashCharacter:SetText("Level " .. tostring(state.level) .. "  •  Stage " .. tostring(state.stage))
    dashMoney:SetText(tostring(state.money) .. " gold"); goldCurrent:SetText("Current: " .. tostring(state.money) .. "g")
    dashRates:SetText("XP " .. tostring(state.xp) .. "x     REP " .. tostring(state.rep) .. "x     GOLD " .. tostring(state.goldrate) .. "x")
    dashPopulation:SetText("Players " .. tostring(state.players) .. "   •   Bots " .. tostring(state.bots) .. " / " .. tostring(state.bottarget))
    dashActivity:SetText("Activity " .. tostring(state.botactivity) .. "% • " .. tostring(state.botstate) .. " • pending " .. tostring(state.botpending))
    botSummary:SetText("Bots " .. tostring(state.bots) .. " / " .. tostring(state.bottarget) .. " • capacity " .. tostring(state.botcapacity) .. " • pending " .. tostring(state.botpending) .. " • " .. tostring(state.botstate))

    local selectedTarget = tonumber(state.bottarget)
    for target, button in pairs(botPresetButtons) do
        if target == selectedTarget then button:LockHighlight() else button:UnlockHighlight() end
    end
    if rateRows.xp then rateRows.xp:SetText(tostring(state.xp)) end
    if rateRows.rep then rateRows.rep:SetText(tostring(state.rep)) end
    if rateRows.gold then rateRows.gold:SetText(tostring(state.goldrate)) end

    if tostring(state.starter) == "wotlkraid" then
        currentStarter:SetText("Default new character: WotLK Raid Ready • Level 80")
    elseif tostring(state.starter) == "tbcraid" then
        currentStarter:SetText("Default new character: TBC Raid Ready • Level 70")
    elseif tostring(state.starter) == "tbc" then
        currentStarter:SetText("Default new character: TBC Adventure • Level 60")
    else
        currentStarter:SetText("Default new character: Vanilla fresh start • Level 1")
    end

    expansionTitle:SetText(eraName .. " • LIVE"); expansionTitle:SetTextColor(r, g, b)
    expansionInfo:SetText("Level cap " .. tostring(state.levelcap) .. " • progression ceiling " .. tostring(state.progressionlimit))

    if era == "VANILLA" then
        dashLock:SetText("TBC locked • cap 60 • stage limit " .. tostring(state.progressionlimit))
        dashExpansionAction:SetText("Release TBC"); dashExpansionAction:Show()
        dashRaidReady:SetText("Vanilla Journey"); SetEnabled(dashRaidReady, false)
        releaseButton:SetText("RELEASE THE BURNING CRUSADE"); releaseButton:Show()
        releaseStatus:SetText("TBC LOCKED"); releaseStatus:SetTextColor(C.warning[1], C.warning[2], C.warning[3])
        expansionDesc:SetText("Vanilla is the live world. Finish the content you care about, then manually release The Burning Crusade. No character is auto-boosted.")
        wrathCharStatus:SetText("LOCKED • TBC and WotLK have not been released yet"); wrathCharStatus:SetTextColor(C.warning[1], C.warning[2], C.warning[3])
        tpLock:SetText("Vanilla is live. Shattrath and Northrend destinations are locked."); tpLock:SetTextColor(C.warning[1], C.warning[2], C.warning[3])
    elseif era == "TBC" then
        dashLock:SetText("WotLK locked • cap 70 • stage limit " .. tostring(state.progressionlimit))
        dashExpansionAction:SetText("Release WotLK"); dashExpansionAction:Show()
        dashRaidReady:SetText("TBC Raid Ready"); SetEnabled(dashRaidReady, true)
        releaseButton:SetText("RELEASE WRATH OF THE LICH KING"); releaseButton:Show()
        releaseStatus:SetText("WOTLK LOCKED"); releaseStatus:SetTextColor(C.warning[1], C.warning[2], C.warning[3])
        expansionDesc:SetText("The Burning Crusade is live. Finish your TBC journey, then manually release Wrath. Existing characters remain exactly where they are.")
        wrathCharStatus:SetText("LOCKED • release WotLK from the World page first"); wrathCharStatus:SetTextColor(C.warning[1], C.warning[2], C.warning[3])
        tpLock:SetText("TBC is live. Shattrath is open; Northrend remains locked."); tpLock:SetTextColor(C.green[1], C.green[2], C.green[3])
    else
        dashLock:SetText("WotLK LIVE • cap 80 • full progression open"); dashExpansionAction:Hide()
        dashRaidReady:SetText("WotLK Raid Ready"); SetEnabled(dashRaidReady, true)
        releaseButton:Hide()
        releaseStatus:SetText("ALL ERAS LIVE"); releaseStatus:SetTextColor(C.wrath[1], C.wrath[2], C.wrath[3])
        expansionDesc:SetText("Wrath is live. Vanilla and TBC remain available as legacy eras; Northrend and WotLK-only systems are open.")
        wrathCharStatus:SetText("UNLOCKED • raid-ready shortcut completes WotLK access / stage 18"); wrathCharStatus:SetTextColor(C.wrath[1], C.wrath[2], C.wrath[3])
        tpLock:SetText("All expansion destinations are unlocked."); tpLock:SetTextColor(C.wrath[1], C.wrath[2], C.wrath[3])
    end

    SetEnabled(starter60, tbc); SetEnabled(starter70, tbc); SetEnabled(makeTbcReady, tbc)
    SetEnabled(starter80, wotlk); SetEnabled(makeWrathReady, wotlk)
    for stageValue, button in pairs(stageButtons) do
        SetEnabled(button, stageValue <= (tonumber(state.progressionlimit) or 0) and stageValue ~= 11)
    end
    for _, entry in ipairs(eraTeleportButtons) do SetEnabled(entry.button, eraIndex >= entry.requiredEra) end

    local tick = tonumber(state.tick)
    if tick then
        local tickColor
        if tick <= 75 then tickColor = Hex(C.green[1], C.green[2], C.green[3])
        elseif tick <= 150 then tickColor = Hex(C.warning[1], C.warning[2], C.warning[3])
        else tickColor = Hex(C.danger[1], C.danger[2], C.danger[3]) end
        dashHealth:SetText(tickColor .. "Tick " .. tostring(state.tick) .. " ms|r • P95 " .. tostring(state.p95) .. " ms")
        aiHealth:SetText("Tick " .. tostring(state.tick) .. " ms • Mean " .. tostring(state.mean) .. " • P95 " .. tostring(state.p95) .. " • P99 " .. tostring(state.p99))
    end
    dashUptime:SetText("Uptime " .. FormatUptime(state.uptime) .. " • Sessions " .. tostring(state.sessions))
end

local function ParseKeyValues(msg, marker)
    if not string.find(msg, marker, 1, true) then return false end
    for key, value in string.gmatch(msg, "([%a%d_]+)=([^%s]+)") do state[key] = value end
    return true
end
local event = CreateFrame("Frame"); event:RegisterEvent("CHAT_MSG_SYSTEM")
event:SetScript("OnEvent", function(self, eventName, msg)
    if type(msg) ~= "string" or not string.find(msg, "[AdminPanel]", 1, true) then return end
    footer:SetText(msg)
    if ParseKeyValues(msg, "[AdminPanel] STATUS") then UpdateUI() elseif ParseKeyValues(msg, "[AdminPanel] HEALTH") then UpdateUI() elseif string.find(msg, "WOTLK RELEASED", 1, true) or string.find(msg, "TBC RELEASED", 1, true) then Send("status"); Send("health") end
end)

-- MINIMAP + SLASH ------------------------------------------------------------
local mini = CreateFrame("Button", "AzerothAdminPanelMinimapButton", Minimap); mini:SetWidth(31); mini:SetHeight(31); mini:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -4, -4); mini:SetFrameStrata("MEDIUM"); mini:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2"); mini:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
local miniText = Text(mini, "AC", "GameFontNormalSmall", C.cyan[1], C.cyan[2], C.cyan[3]); miniText:SetPoint("CENTER", 0, 1)
mini:SetScript("OnClick", function() if frame:IsShown() then frame:Hide() else frame:Show(); SelectPage(DB.page or "Dashboard"); Send("status"); Send("health") end end)
mini:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText("Azeroth Control", 1, 1, 1); GameTooltip:AddLine("GM realm controls • click to open", 0.75, 0.82, 0.92); GameTooltip:Show() end)
mini:SetScript("OnLeave", function() GameTooltip:Hide() end)
SLASH_AZEROTHADMIN1 = "/ap"; SLASH_AZEROTHADMIN2 = "/adminpanel"
SlashCmdList["AZEROTHADMIN"] = function() if frame:IsShown() then frame:Hide() else frame:Show(); SelectPage(DB.page or "Dashboard"); Send("status"); Send("health") end end
SelectPage(DB.page or "Dashboard")
UpdateUI()

local GC = GroupComposer
local D = GroupComposerData
local P = GroupComposerProfiles

GC.ModernUI = GC.ModernUI or {}
local M = GC.ModernUI

local C = {
    bg = {0.025, 0.033, 0.046, 0.985},
    chrome = {0.035, 0.046, 0.064, 1},
    panel = {0.050, 0.064, 0.086, 0.985},
    panel2 = {0.063, 0.080, 0.107, 0.985},
    line = {0.17, 0.22, 0.29, 0.95},
    blue = {0.20, 0.56, 0.95, 1},
    blueSoft = {0.08, 0.24, 0.39, 1},
    green = {0.18, 0.82, 0.43, 1},
    greenSoft = {0.06, 0.26, 0.15, 1},
    red = {0.95, 0.27, 0.31, 1},
    redSoft = {0.28, 0.07, 0.09, 1},
    gold = {1.00, 0.70, 0.17, 1},
    text = {0.93, 0.96, 1.00, 1},
    muted = {0.63, 0.70, 0.80, 1},
    dim = {0.40, 0.47, 0.57, 1},
}

local ROLE = {
    TANK = {label = "Tank", color = C.blue, soft = C.blueSoft, icon = "Interface\\Icons\\Ability_Warrior_DefensiveStance"},
    HEALER = {label = "Healer", color = C.green, soft = C.greenSoft, icon = "Interface\\Icons\\Spell_Holy_HolyBolt"},
    DPS = {label = "DPS", color = C.red, soft = C.redSoft, icon = "Interface\\Icons\\Ability_DualWield"},
}

local function Solid(parent, layer, color, alpha)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetTexture(color[1], color[2], color[3], alpha or color[4] or 1)
    return t
end

local function Text(parent, value, template, color)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    fs:SetText(value or "")
    color = color or C.text
    fs:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    fs:SetJustifyH("LEFT")
    return fs
end

local function ApplyBackdrop(frame, bg, border)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    local b = bg or C.panel
    frame:SetBackdropColor(b[1], b[2], b[3], b[4] or 1)
    local l = border or C.line
    frame:SetBackdropBorderColor(l[1], l[2], l[3], l[4] or 1)
end

local function FlatButton(parent, label, width, height, color, fn)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(width or 100)
    b:SetHeight(height or 28)
    ApplyBackdrop(b, color or C.panel2, C.line)
    b.text = Text(b, label or "Button", "GameFontHighlight", C.text)
    b.text:SetPoint("CENTER")
    b:SetScript("OnClick", function() if fn then fn() end end)
    b:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(C.blue[1], C.blue[2], C.blue[3], 1)
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(C.line[1], C.line[2], C.line[3], 1)
    end)
    return b
end

local function AccentButton(parent, label, width, height, fn)
    local b = FlatButton(parent, label, width, height, C.blueSoft, fn)
    b:SetBackdropBorderColor(C.blue[1], C.blue[2], C.blue[3], 1)
    b.text:SetTextColor(0.78, 0.91, 1.00, 1)
    return b
end

local dropdownCounter = 0
local function Dropdown(parent, width, getItems, getValue, setValue)
    dropdownCounter = dropdownCounter + 1
    local name = "GroupComposerModernDropdown" .. dropdownCounter
    local dd = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dd, width or 160)
    UIDropDownMenu_JustifyText(dd, "LEFT")
    dd.getItems, dd.getValue, dd.setValue = getItems, getValue, setValue

    local left = _G[name .. "Left"]
    local middle = _G[name .. "Middle"]
    local right = _G[name .. "Right"]
    if left then left:SetAlpha(0) end
    if middle then middle:SetAlpha(0) end
    if right then right:SetAlpha(0) end

    local skin = CreateFrame("Frame", nil, dd)
    skin:SetPoint("TOPLEFT", 17, -3)
    skin:SetPoint("BOTTOMRIGHT", -15, 7)
    ApplyBackdrop(skin, C.panel2, C.line)
    skin:SetFrameLevel(math.max(0, dd:GetFrameLevel() - 1))

    UIDropDownMenu_Initialize(dd, function(frame, level)
        local current = frame.getValue and frame.getValue() or nil
        for _, item in ipairs(frame.getItems and frame.getItems() or {}) do
            local valueCopy = item.value
            local disabledCopy = item.disabled and true or false
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.label
            info.value = valueCopy
            info.checked = current == valueCopy
            info.disabled = disabledCopy
            info.func = function()
                if not disabledCopy and frame.setValue then frame.setValue(valueCopy) end
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    function dd:Refresh()
        local current = self.getValue and self.getValue() or nil
        local label = tostring(current or "Select")
        for _, item in ipairs(self.getItems and self.getItems() or {}) do
            if item.value == current then label = item.label break end
        end
        UIDropDownMenu_SetText(self, label)
    end
    dd:Refresh()
    return dd
end

local function Card(parent, title, subtitle)
    local f = CreateFrame("Frame", nil, parent)
    ApplyBackdrop(f, C.panel, C.line)
    if title then
        f.title = Text(f, title, "GameFontNormalLarge", C.text)
        f.title:SetPoint("TOPLEFT", 16, -14)
    end
    if subtitle then
        f.subtitle = Text(f, subtitle, "GameFontHighlightSmall", C.muted)
        f.subtitle:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -3)
        f.subtitle:SetPoint("RIGHT", -16, 0)
    end
    return f
end

local function Toggle(parent, label, getter, setter)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(28)
    row.box = CreateFrame("Frame", nil, row)
    row.box:SetWidth(18); row.box:SetHeight(18); row.box:SetPoint("LEFT", 0, 0)
    ApplyBackdrop(row.box, C.bg, C.line)
    row.tick = Text(row.box, "✓", "GameFontNormal", C.gold)
    row.tick:SetPoint("CENTER", 0, 1)
    row.label = Text(row, label, "GameFontHighlight", C.text)
    row.label:SetPoint("LEFT", row.box, "RIGHT", 8, 0)
    row:SetScript("OnClick", function()
        setter(not getter())
        row:Refresh()
    end)
    function row:Refresh()
        local on = getter() and true or false
        self.tick:SetShown(on)
        if on then
            self.box:SetBackdropBorderColor(C.gold[1], C.gold[2], C.gold[3], 1)
        else
            self.box:SetBackdropBorderColor(C.line[1], C.line[2], C.line[3], 1)
        end
    end
    row:Refresh()
    return row
end

local frame = CreateFrame("Frame", "GroupComposerModernFrame", UIParent)
M.frame = frame
frame:SetWidth(1240)
frame:SetHeight(800)
frame:SetFrameStrata("DIALOG")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetClampedToScreen(true)
ApplyBackdrop(frame, C.bg, C.line)
frame:Hide()

local function SavePoint()
    if not GC.db then return end
    local p, rel, rp, x, y = frame:GetPoint(1)
    GC.db.window.modernPoint = {p, rel and rel:GetName() or "UIParent", rp, x, y}
end
frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePoint() end)

local header = CreateFrame("Frame", nil, frame)
header:SetPoint("TOPLEFT", 6, -6); header:SetPoint("TOPRIGHT", -6, -6); header:SetHeight(68)
local headerBg = Solid(header, "BACKGROUND", C.chrome); headerBg:SetAllPoints(header)
local heroIcon = header:CreateTexture(nil, "ARTWORK")
heroIcon:SetWidth(42); heroIcon:SetHeight(42); heroIcon:SetPoint("LEFT", 14, 0)
heroIcon:SetTexture("Interface\\Icons\\INV_Misc_GroupLooking")
local title = Text(header, "GROUP COMPOSER", "GameFontNormalLarge", C.text)
title:SetPoint("TOPLEFT", 66, -13)
local subtitle = Text(header, "Build the right team. Keep the adventure, lose the roster spreadsheet.", "GameFontHighlightSmall", C.muted)
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -3, -4)

local dungeonTab = FlatButton(header, "Dungeon", 105, 30, C.panel2, function() GC:SetMode("DUNGEON") end)
dungeonTab:SetPoint("TOP", -56, -18)
local raidTab = FlatButton(header, "Raid", 105, 30, C.panel2, function() GC:SetMode("RAID") end)
raidTab:SetPoint("LEFT", dungeonTab, "RIGHT", 8, 0)
local editorButton = FlatButton(header, "Roster Editor", 118, 30, C.panel2, function()
    if GC.Advanced and GC.Advanced.frame then GC.Advanced.frame:Show() end
end)
editorButton:SetPoint("RIGHT", -42, 0)
M.dungeonTab, M.raidTab = dungeonTab, raidTab

local toolbar = CreateFrame("Frame", nil, frame)
toolbar:SetPoint("TOPLEFT", 6, -78); toolbar:SetPoint("TOPRIGHT", -6, -78); toolbar:SetHeight(52)
ApplyBackdrop(toolbar, C.chrome, C.line)
local profileLabel = Text(toolbar, "PROFILE", "GameFontHighlightSmall", C.muted)
profileLabel:SetPoint("LEFT", 16, 0)

local function ProfileItems()
    local out = {}
    for _, name in ipairs(P.ListBuiltins()) do out[#out + 1] = {value = name, label = "Built-in: " .. name} end
    for _, name in ipairs(P.ListCustom()) do out[#out + 1] = {value = name, label = name} end
    if #out == 0 then out[1] = {value = "", label = "No profiles"} end
    return out
end

local profileDD = Dropdown(toolbar, 270, ProfileItems, function() return GC.db and GC.db.lastProfile end, function(value) GC:LoadProfile(value) end)
profileDD:SetPoint("LEFT", profileLabel, "RIGHT", -3, -2)
local saveProfile = FlatButton(toolbar, "Save / Save As", 118, 28, C.panel2, function() StaticPopup_Show("GROUPCOMPOSER_SAVE_PROFILE") end)
saveProfile:SetPoint("LEFT", profileDD, "RIGHT", -1, 2)
local newProfile = FlatButton(toolbar, "New", 62, 28, C.panel2, function() GC:SetConfig(P.New(GC:GetConfig().mode), nil) end)
newProfile:SetPoint("LEFT", saveProfile, "RIGHT", 8, 0)
local deleteProfile = FlatButton(toolbar, "Delete", 66, 28, C.panel2, function()
    local name = GC.db and GC.db.lastProfile
    if name then GC:DeleteProfile(name) end
end)
deleteProfile:SetPoint("LEFT", newProfile, "RIGHT", 8, 0)
local backendText = Text(toolbar, "Backend: waiting", "GameFontHighlightSmall", C.dim)
backendText:SetPoint("RIGHT", -16, 0)
M.backendText = backendText

local body = CreateFrame("Frame", nil, frame)
body:SetPoint("TOPLEFT", 8, -138); body:SetPoint("BOTTOMRIGHT", -8, 48)

local left = CreateFrame("Frame", nil, body)
left:SetPoint("TOPLEFT", 0, 0); left:SetPoint("BOTTOMRIGHT", -340, 0)
local leftScroll = CreateFrame("ScrollFrame", "GroupComposerModernScroll", left, "UIPanelScrollFrameTemplate")
leftScroll:SetPoint("TOPLEFT", 0, 0); leftScroll:SetPoint("BOTTOMRIGHT", -28, 0)
leftScroll:EnableMouseWheel(true)
leftScroll:SetScript("OnMouseWheel", function(self, delta)
    local current, range = self:GetVerticalScroll(), self:GetVerticalScrollRange()
    self:SetVerticalScroll(math.max(0, math.min(range, current - delta * 40)))
end)
local content = CreateFrame("Frame", nil, leftScroll)
content:SetWidth(850); content:SetHeight(660)
leftScroll:SetScrollChild(content)
M.content = content

local activity = Card(content, "Activity", "Choose the dungeon or raid, size and difficulty.")
activity:SetPoint("TOPLEFT", 0, 0); activity:SetPoint("TOPRIGHT", 0, 0); activity:SetHeight(114)
local activityDD = Dropdown(activity, 300,
    function()
        local out = {}
        if GC:GetConfig().mode == "RAID" then
            for _, raid in ipairs(D.RAIDS) do out[#out + 1] = {value = raid.id, label = raid.era .. "  •  " .. raid.label} end
        else
            for _, dungeon in ipairs(D.DUNGEONS) do out[#out + 1] = {value = dungeon.id, label = dungeon.label} end
        end
        return out
    end,
    function() return GC:GetConfig().activity end,
    function(value)
        if GC:GetConfig().mode == "RAID" then GC:SetRaidActivity(value) else GC:SetDungeonActivity(value) end
    end)
activityDD:SetPoint("BOTTOMLEFT", 6, 8)
local sizeDD = Dropdown(activity, 125,
    function()
        local c = GC:GetConfig()
        if c.mode == "DUNGEON" then return {{value = 5, label = "5 Players"}} end
        local raid = D.GetRaidById(c.activity)
        local out = {}
        for _, n in ipairs((raid and raid.sizes) or {10, 25, 40}) do out[#out + 1] = {value = n, label = n .. " Players"} end
        return out
    end,
    function() return GC:GetConfig().size end,
    function(value) GC:SetRaidSize(value) end)
sizeDD:SetPoint("LEFT", activityDD, "RIGHT", -6, 0)
local difficultyDD = Dropdown(activity, 170,
    function()
        local c = GC:GetConfig()
        local out = {}
        if c.mode == "DUNGEON" then
            for _, x in ipairs(D.DUNGEON_DIFFICULTIES) do out[#out + 1] = {value = x.id, label = x.label} end
        else
            local raid = D.GetRaidById(c.activity)
            out[#out + 1] = {value = "normal", label = "Normal"}
            if raid and raid.heroic then out[#out + 1] = {value = "heroic", label = "Heroic"} end
        end
        return out
    end,
    function() return GC:GetConfig().difficulty end,
    function(value)
        GC:GetConfig().difficulty = value
        GC:ResetPlan("Difficulty changed")
        GC:Fire("CONFIG_CHANGED", GC:GetConfig())
    end)
difficultyDD:SetPoint("LEFT", sizeDD, "RIGHT", -6, 0)
M.activityDD, M.sizeDD, M.difficultyDD = activityDD, sizeDD, difficultyDD

local roles = Card(content, "Roster-wide Role Composition", "These totals apply to the whole party or raid. Subgroups are arranged later.")
roles:SetPoint("TOPLEFT", activity, "BOTTOMLEFT", 0, -10); roles:SetPoint("TOPRIGHT", activity, "BOTTOMRIGHT", 0, -10); roles:SetHeight(166)
M.roleCards = {}
for index, role in ipairs({"TANK", "HEALER", "DPS"}) do
    local info = ROLE[role]
    local card = CreateFrame("Frame", nil, roles)
    card:SetWidth(255); card:SetHeight(102)
    card:SetPoint("BOTTOMLEFT", 14 + (index - 1) * 270, 12)
    ApplyBackdrop(card, C.bg, info.color)
    local stripe = Solid(card, "ARTWORK", info.color); stripe:SetPoint("TOPLEFT", 0, 0); stripe:SetPoint("BOTTOMLEFT", 0, 0); stripe:SetWidth(4)
    local iconBox = CreateFrame("Frame", nil, card); iconBox:SetWidth(38); iconBox:SetHeight(38); iconBox:SetPoint("TOPLEFT", 14, -14); ApplyBackdrop(iconBox, info.soft, info.color)
    local icon = iconBox:CreateTexture(nil, "ARTWORK"); icon:SetPoint("TOPLEFT", 3, -3); icon:SetPoint("BOTTOMRIGHT", -3, 3); icon:SetTexture(info.icon)
    local label = Text(card, info.label, "GameFontNormal", info.color); label:SetPoint("LEFT", iconBox, "RIGHT", 10, 9)
    local count = Text(card, "0", "GameFontNormalLarge", C.text); count:SetPoint("LEFT", iconBox, "RIGHT", 50, -13)
    local minus = FlatButton(card, "−", 42, 24, C.panel2, function()
        local c = GC:GetConfig(); local key = role == "TANK" and "tanks" or (role == "HEALER" and "healers" or "dps")
        c[key] = math.max(0, (c[key] or 0) - 1); GC:ResetPlan("Role count changed"); GC:Fire("CONFIG_CHANGED", c)
    end)
    minus:SetPoint("BOTTOM", -27, 10)
    local plus = FlatButton(card, "+", 42, 24, C.panel2, function()
        local c = GC:GetConfig(); local key = role == "TANK" and "tanks" or (role == "HEALER" and "healers" or "dps")
        c[key] = (c[key] or 0) + 1; GC:ResetPlan("Role count changed"); GC:Fire("CONFIG_CHANGED", c)
    end)
    plus:SetPoint("BOTTOM", 27, 10)
    M.roleCards[role] = {frame = card, count = count}
end

local rules = Card(content, "Roster Rules", "Human players stay locked. Guild preference never overrides roster validity.")
rules:SetPoint("TOPLEFT", roles, "BOTTOMLEFT", 0, -10); rules:SetPoint("TOPRIGHT", roles, "BOTTOMRIGHT", 0, -10); rules:SetHeight(142)
M.ruleToggles = {}
local function OptionToggle(label, key, x, y)
    local row = Toggle(rules, label,
        function() return GC:GetConfig().options[key] and true or false end,
        function(value)
            GC:GetConfig().options[key] = value
            GC:ResetPlan("Roster rule changed")
            GC:Fire("CONFIG_CHANGED", GC:GetConfig())
        end)
    row:SetPoint("TOPLEFT", x, y); row:SetWidth(250)
    M.ruleToggles[#M.ruleToggles + 1] = row
end
OptionToggle("Prefer Guild Members", "preferGuild", 16, -62)
OptionToggle("Fill Missing Roles With World Bots", "fillWorld", 16, -96)
OptionToggle("Balance Class / Utility Coverage", "balanceClasses", 310, -62)
OptionToggle("Avoid Duplicate Classes When Practical", "avoidDuplicateClasses", 565, -62)
local me = Text(rules, "YOU  •  Locked human anchor", "GameFontNormal", C.gold); me:SetPoint("TOPLEFT", 310, -96)
local ilvlLabel = Text(rules, "Minimum Item Level", "GameFontHighlightSmall", C.muted); ilvlLabel:SetPoint("TOPLEFT", 565, -98)
local ilvl = CreateFrame("EditBox", nil, rules, "InputBoxTemplate"); ilvl:SetWidth(82); ilvl:SetHeight(24); ilvl:SetAutoFocus(false); ilvl:SetNumeric(true); ilvl:SetPoint("LEFT", ilvlLabel, "RIGHT", 8, 1)
ilvl:SetScript("OnEnterPressed", function(self)
    GC:GetConfig().options.minimumItemLevel = tonumber(self:GetText()) or 0
    GC:ResetPlan("Item level changed"); GC:Fire("CONFIG_CHANGED", GC:GetConfig()); self:ClearFocus()
end)
M.ilvl = ilvl

local prefs = Card(content, "Class / Spec Preferences", "Soft preferences or hard requirements. Empty means any valid class/spec for that role.")
prefs:SetPoint("TOPLEFT", rules, "BOTTOMLEFT", 0, -10); prefs:SetPoint("TOPRIGHT", rules, "BOTTOMRIGHT", 0, -10); prefs:SetHeight(188)
M.prefColumns = {}
local function ClassItems(role)
    local out = {{value = "ANY", label = "Any class"}}
    local seen = {}
    for classToken, specs in pairs(D.SPECS or {}) do
        for _, spec in ipairs(specs) do
            if spec.role == role or (role == "TANK" and spec.canTank) then
                if not seen[classToken] then
                    seen[classToken] = true
                    out[#out + 1] = {value = classToken, label = D.CLASS_LABEL[classToken] or classToken}
                end
            end
        end
    end
    table.sort(out, function(a, b) if a.value == "ANY" then return true end if b.value == "ANY" then return false end return a.label < b.label end)
    return out
end
local function SpecItems(role, classToken)
    local out = {{value = "ANY", label = "Any spec"}}
    if classToken and classToken ~= "ANY" then
        for _, spec in ipairs(D.SPECS[classToken] or {}) do
            if spec.role == role or (role == "TANK" and spec.canTank) then out[#out + 1] = {value = spec.id, label = spec.label} end
        end
    end
    return out
end

for index, role in ipairs({"TANK", "HEALER", "DPS"}) do
    local info = ROLE[role]
    local col = CreateFrame("Frame", nil, prefs); col:SetWidth(255); col:SetHeight(118); col:SetPoint("BOTTOMLEFT", 14 + (index - 1) * 270, 12)
    local label = Text(col, info.label, "GameFontNormal", info.color); label:SetPoint("TOPLEFT", 0, 0)
    local add = FlatButton(col, "+ Preference", 96, 24, C.panel2, function()
        local list = GC:GetConfig().preferences[role]
        if #list < 3 then
            list[#list + 1] = {class = "ANY", spec = "ANY", required = false}
            GC:ResetPlan("Preference changed"); GC:Fire("CONFIG_CHANGED", GC:GetConfig())
        else
            GC:Fire("STATUS", "Use Roster Editor for more than three visible preferences per role.")
        end
    end)
    add:SetPoint("TOPRIGHT", 0, 5)
    col.rows = {}
    M.prefColumns[role] = col
end

local findCard = CreateFrame("Frame", nil, content)
findCard:SetPoint("TOPLEFT", prefs, "BOTTOMLEFT", 0, -10); findCard:SetPoint("TOPRIGHT", prefs, "BOTTOMRIGHT", 0, -10); findCard:SetHeight(70)
ApplyBackdrop(findCard, C.chrome, C.line)
local ready = Text(findCard, "Configure the roster, then build a deterministic preview. Nothing is invited yet.", "GameFontHighlight", C.muted)
ready:SetPoint("LEFT", 16, 0)
local findButton = AccentButton(findCard, "Find Roster", 150, 34, function() GC:FindRoster() end)
findButton:SetPoint("RIGHT", -16, 0)
content:SetHeight(720)
M.findButton = findButton

local summary = CreateFrame("Frame", nil, body)
summary:SetPoint("TOPRIGHT", 0, 0); summary:SetPoint("BOTTOMRIGHT", 0, 0); summary:SetWidth(326)
ApplyBackdrop(summary, C.panel, C.line)
local summaryTitle = Text(summary, "COMPOSITION SUMMARY", "GameFontNormal", C.text); summaryTitle:SetPoint("TOPLEFT", 16, -18)
local stateText = Text(summary, "Not searched", "GameFontHighlightSmall", C.muted); stateText:SetPoint("TOPRIGHT", -16, -19)
local totalText = Text(summary, "0 / 5", "GameFontNormalLarge", C.text); totalText:SetPoint("TOPLEFT", 16, -48)
local roleSummary = Text(summary, "Tank 1   •   Healer 1   •   DPS 3", "GameFontHighlightSmall", C.muted); roleSummary:SetPoint("TOPLEFT", totalText, "BOTTOMLEFT", 0, -4)
local sourceSummary = Text(summary, "Humans 0   •   Guild 0   •   World 0", "GameFontHighlightSmall", C.muted); sourceSummary:SetPoint("TOPLEFT", roleSummary, "BOTTOMLEFT", 0, -3)
local line1 = Solid(summary, "ARTWORK", C.line); line1:SetPoint("TOPLEFT", 12, -104); line1:SetPoint("TOPRIGHT", -12, -104); line1:SetHeight(1)
local warnLabel = Text(summary, "WARNINGS & SUGGESTIONS", "GameFontNormalSmall", C.gold); warnLabel:SetPoint("TOPLEFT", 16, -119)
local warnings = Text(summary, "Find a roster to validate composition.", "GameFontHighlightSmall", C.muted); warnings:SetPoint("TOPLEFT", 16, -142); warnings:SetPoint("RIGHT", -16, 0); warnings:SetHeight(70); warnings:SetJustifyV("TOP")
local rosterLabel = Text(summary, "ROSTER", "GameFontNormalSmall", C.text); rosterLabel:SetPoint("TOPLEFT", 16, -220)
local rosterScroll = CreateFrame("ScrollFrame", "GroupComposerModernRosterScroll", summary, "UIPanelScrollFrameTemplate")
rosterScroll:SetPoint("TOPLEFT", 12, -242); rosterScroll:SetPoint("BOTTOMRIGHT", -29, 60); rosterScroll:EnableMouseWheel(true)
rosterScroll:SetScript("OnMouseWheel", function(self, delta)
    local current, range = self:GetVerticalScroll(), self:GetVerticalScrollRange(); self:SetVerticalScroll(math.max(0, math.min(range, current - delta * 30)))
end)
local rosterContent = CreateFrame("Frame", nil, rosterScroll); rosterContent:SetWidth(276); rosterContent:SetHeight(380); rosterScroll:SetScrollChild(rosterContent)
M.rosterRows = {}; M.rosterGroups = {}; M.rosterContent = rosterContent
local arrange = FlatButton(summary, "Auto Arrange", 112, 30, C.panel2, function() GC:AutoArrange() end); arrange:SetPoint("BOTTOMLEFT", 12, 14)
local assemble = AccentButton(summary, "Assemble", 126, 30, function() GC:Assemble() end); assemble:SetPoint("BOTTOMRIGHT", -12, 14)
M.stateText, M.totalText, M.roleSummary, M.sourceSummary, M.warnings = stateText, totalText, roleSummary, sourceSummary, warnings
M.arrange, M.assemble = arrange, assemble

local footerLine = Solid(frame, "ARTWORK", C.line); footerLine:SetPoint("BOTTOMLEFT", 10, 43); footerLine:SetPoint("BOTTOMRIGHT", -10, 43); footerLine:SetHeight(1)
local status = Text(frame, "Ready.", "GameFontHighlightSmall", C.muted); status:SetPoint("BOTTOMLEFT", 16, 18); status:SetPoint("RIGHT", -280, 0)
M.status = status
local scaleMinus = FlatButton(frame, "−", 30, 24, C.panel2, function() GC.db.window.userScale = math.max(0.75, (GC.db.window.userScale or 1) - 0.05); M:ApplyScale() end); scaleMinus:SetPoint("BOTTOMRIGHT", -132, 10)
local scaleLabel = Text(frame, "100%", "GameFontHighlightSmall", C.muted); scaleLabel:SetPoint("RIGHT", scaleMinus, "LEFT", -8, 0); M.scaleLabel = scaleLabel
local scalePlus = FlatButton(frame, "+", 30, 24, C.panel2, function() GC.db.window.userScale = math.min(1.35, (GC.db.window.userScale or 1) + 0.05); M:ApplyScale() end); scalePlus:SetPoint("BOTTOMRIGHT", -94, 10)
local resetPos = FlatButton(frame, "Reset UI", 76, 24, C.panel2, function() GC.db.window.modernPoint = {"CENTER", "UIParent", "CENTER", 0, 0}; M:Show() end); resetPos:SetPoint("BOTTOMRIGHT", -10, 10)

function M:ApplyScale()
    if not GC.db then return end
    local user = tonumber(GC.db.window.userScale) or 1
    local pw = UIParent:GetWidth() or 1920
    local ph = UIParent:GetHeight() or 1080
    local fit = math.min((pw - 48) / 1240, (ph - 70) / 800)
    fit = math.max(0.76, math.min(1.18, fit))
    local scale = math.max(0.70, math.min(1.35, user * fit))
    frame:SetScale(scale)
    scaleLabel:SetText(string.format("%d%%", math.floor(scale * 100 + 0.5)))
end

local function ClearPrefRows()
    for _, col in pairs(M.prefColumns) do
        for _, row in ipairs(col.rows) do row:Hide() end
    end
end

local function BuildPrefRows()
    ClearPrefRows()
    for _, role in ipairs({"TANK", "HEALER", "DPS"}) do
        local col = M.prefColumns[role]
        local list = GC:GetConfig().preferences[role] or {}
        for i = 1, math.min(3, #list) do
            local pref = list[i]
            local row = col.rows[i]
            if not row then
                row = CreateFrame("Frame", nil, col); row:SetHeight(30); row:SetWidth(255)
                row.classDD = Dropdown(row, 90, function() return ClassItems(role) end, function() return row.pref and (row.pref.class or "ANY") or "ANY" end, function(value)
                    if not row.pref then return end; row.pref.class = value; row.pref.spec = "ANY"; GC:ResetPlan("Preference changed"); GC:Fire("CONFIG_CHANGED", GC:GetConfig())
                end)
                row.classDD:SetPoint("LEFT", -16, 0)
                row.specDD = Dropdown(row, 82, function() return SpecItems(role, row.pref and row.pref.class or "ANY") end, function() return row.pref and (row.pref.spec or "ANY") or "ANY" end, function(value)
                    if not row.pref then return end; row.pref.spec = value; GC:ResetPlan("Preference changed"); GC:Fire("CONFIG_CHANGED", GC:GetConfig())
                end)
                row.specDD:SetPoint("LEFT", row.classDD, "RIGHT", -22, 0)
                row.req = FlatButton(row, "Req", 38, 22, C.panel2, function()
                    if not row.pref then return end; row.pref.required = not row.pref.required; GC:ResetPlan("Preference changed"); GC:Fire("CONFIG_CHANGED", GC:GetConfig())
                end)
                row.req:SetPoint("RIGHT", -24, 0)
                row.remove = FlatButton(row, "×", 22, 22, C.redSoft, function()
                    if not row.index then return end; table.remove(GC:GetConfig().preferences[role], row.index); GC:ResetPlan("Preference changed"); GC:Fire("CONFIG_CHANGED", GC:GetConfig())
                end)
                row.remove:SetPoint("RIGHT", 0, 0)
                col.rows[i] = row
            end
            row.pref, row.index = pref, i
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -30 - (i - 1) * 31)
            row.classDD:Refresh(); row.specDD:Refresh()
            if pref.required then row.req:SetBackdropBorderColor(C.gold[1], C.gold[2], C.gold[3], 1); row.req.text:SetTextColor(C.gold[1], C.gold[2], C.gold[3], 1)
            else row.req:SetBackdropBorderColor(C.line[1], C.line[2], C.line[3], 1); row.req.text:SetTextColor(C.muted[1], C.muted[2], C.muted[3], 1) end
            row:Show()
        end
        if #list == 0 then
            if not col.empty then col.empty = Text(col, "Any valid " .. string.lower(ROLE[role].label), "GameFontHighlightSmall", C.dim); col.empty:SetPoint("TOPLEFT", 0, -38) end
            col.empty:Show()
        elseif col.empty then col.empty:Hide() end
    end
end

local function ClearRoster()
    for _, row in ipairs(M.rosterRows) do row:Hide() end
    for _, row in ipairs(M.rosterGroups) do row:Hide() end
end

local function RenderRoster(plan)
    ClearRoster()
    local y, groupIndex, lastGroup = 0, 0, -1
    for index, member in ipairs(plan.members or {}) do
        if member.subgroup and member.subgroup > 0 and member.subgroup ~= lastGroup then
            lastGroup = member.subgroup; groupIndex = groupIndex + 1
            local g = M.rosterGroups[groupIndex]
            if not g then g = Text(rosterContent, "", "GameFontNormalSmall", C.muted); M.rosterGroups[groupIndex] = g end
            g:ClearAllPoints(); g:SetPoint("TOPLEFT", 4, -y); g:SetText("GROUP " .. member.subgroup); g:Show(); y = y + 20
        end
        local row = M.rosterRows[index]
        if not row then
            row = CreateFrame("Frame", nil, rosterContent); row:SetWidth(270); row:SetHeight(30); ApplyBackdrop(row, C.bg, C.line)
            row.stripe = Solid(row, "ARTWORK", C.muted); row.stripe:SetPoint("TOPLEFT", 0, 0); row.stripe:SetPoint("BOTTOMLEFT", 0, 0); row.stripe:SetWidth(3)
            row.name = Text(row, "", "GameFontHighlightSmall", C.text); row.name:SetPoint("LEFT", 9, 0); row.name:SetWidth(105)
            row.role = Text(row, "", "GameFontHighlightSmall", C.muted); row.role:SetPoint("LEFT", 116, 0); row.role:SetWidth(55)
            row.class = Text(row, "", "GameFontHighlightSmall", C.muted); row.class:SetPoint("LEFT", 174, 0); row.class:SetWidth(68)
            row.source = Text(row, "", "GameFontNormalSmall", C.blue); row.source:SetPoint("RIGHT", -8, 0)
            M.rosterRows[index] = row
        end
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y)
        local rc = ROLE[member.role] and ROLE[member.role].color or C.muted
        row.stripe:SetTexture(rc[1], rc[2], rc[3], 1)
        row.name:SetText(member.name or "?")
        if member.human then row.name:SetTextColor(C.gold[1], C.gold[2], C.gold[3], 1) else row.name:SetTextColor(C.text[1], C.text[2], C.text[3], 1) end
        row.role:SetText(ROLE[member.role] and ROLE[member.role].label or member.role or "?"); row.role:SetTextColor(rc[1], rc[2], rc[3], 1)
        row.class:SetText(D.CLASS_LABEL[member.class] or member.class or "?")
        row.source:SetText(member.human and "H" or (member.source == "GUILD" and "G" or "W"))
        row.source:SetTextColor(member.human and C.gold[1] or (member.source == "GUILD" and C.green[1] or C.blue[1]), member.human and C.gold[2] or (member.source == "GUILD" and C.green[2] or C.blue[2]), member.human and C.gold[3] or (member.source == "GUILD" and C.green[3] or C.blue[3]), 1)
        row:Show(); y = y + 33
    end
    if y == 0 then
        if not M.emptyRoster then M.emptyRoster = Text(rosterContent, "No roster preview yet.\n\nFind Roster builds the team without inviting anyone.", "GameFontHighlightSmall", C.dim); M.emptyRoster:SetPoint("TOPLEFT", 4, -8); M.emptyRoster:SetWidth(250) end
        M.emptyRoster:Show(); y = 90
    elseif M.emptyRoster then M.emptyRoster:Hide() end
    rosterContent:SetHeight(math.max(330, y + 12))
end

function M:Refresh()
    if not GC.db then return end
    local c = GC:GetConfig()
    activityDD:Refresh(); sizeDD:Refresh(); difficultyDD:Refresh(); profileDD:Refresh()
    if c.mode == "DUNGEON" then
        dungeonTab:SetBackdropBorderColor(C.blue[1], C.blue[2], C.blue[3], 1); dungeonTab.text:SetTextColor(0.78, 0.91, 1, 1)
        raidTab:SetBackdropBorderColor(C.line[1], C.line[2], C.line[3], 1); raidTab.text:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    else
        raidTab:SetBackdropBorderColor(C.gold[1], C.gold[2], C.gold[3], 1); raidTab.text:SetTextColor(C.gold[1], C.gold[2], C.gold[3], 1)
        dungeonTab:SetBackdropBorderColor(C.line[1], C.line[2], C.line[3], 1); dungeonTab.text:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    end
    M.roleCards.TANK.count:SetText(tostring(c.tanks or 0))
    M.roleCards.HEALER.count:SetText(tostring(c.healers or 0))
    M.roleCards.DPS.count:SetText(tostring(c.dps or 0))
    for _, row in ipairs(M.ruleToggles) do row:Refresh() end
    ilvl:SetText(tostring(c.options.minimumItemLevel or 0))
    BuildPrefRows()
    M:RefreshPlan(GC.plan or {members = {}, ready = false, valid = false})
end

function M:RefreshPlan(plan)
    local c = GC:GetConfig()
    local total = plan.summary and plan.summary.total or #(plan.members or {})
    totalText:SetText(tostring(total or 0) .. " / " .. tostring(c.size or 0))
    roleSummary:SetText("Tank " .. tostring(c.tanks or 0) .. "   •   Healer " .. tostring(c.healers or 0) .. "   •   DPS " .. tostring(c.dps or 0))
    local humans = plan.summary and plan.summary.humans or 0
    local guild = plan.summary and plan.summary.guild or 0
    local world = plan.summary and plan.summary.world or 0
    sourceSummary:SetText("Humans " .. humans .. "   •   Guild " .. guild .. "   •   World " .. world)
    if plan.ready then
        if plan.valid then stateText:SetText("VALID"); stateText:SetTextColor(C.green[1], C.green[2], C.green[3], 1)
        else stateText:SetText("NEEDS ATTENTION"); stateText:SetTextColor(C.gold[1], C.gold[2], C.gold[3], 1) end
    else
        stateText:SetText("Not searched"); stateText:SetTextColor(C.muted[1], C.muted[2], C.muted[3], 1)
    end
    if plan.warnings and #plan.warnings > 0 then
        local out = {}
        for i = 1, math.min(4, #plan.warnings) do out[#out + 1] = "• " .. plan.warnings[i] end
        if #plan.warnings > 4 then out[#out + 1] = "+ " .. (#plan.warnings - 4) .. " more" end
        warnings:SetText(table.concat(out, "\n")); warnings:SetTextColor(C.gold[1], C.gold[2], C.gold[3], 1)
    elseif plan.ready and plan.valid then
        warnings:SetText("✓ Composition looks good. Review the roster, then Assemble when ready.")
        warnings:SetTextColor(C.green[1], C.green[2], C.green[3], 1)
    else
        warnings:SetText("Find a roster to validate composition."); warnings:SetTextColor(C.muted[1], C.muted[2], C.muted[3], 1)
    end
    if plan.ready then arrange:Enable(); arrange:SetAlpha(1) else arrange:Disable(); arrange:SetAlpha(0.45) end
    if plan.ready and plan.valid then assemble:Enable(); assemble:SetAlpha(1) else assemble:Disable(); assemble:SetAlpha(0.45) end
    RenderRoster(plan)
end

function M:Show()
    if not GC.db then return end
    if GC.UI and GC.UI.frame then GC.UI.frame:Hide() end
    frame:ClearAllPoints()
    local p = GC.db.window.modernPoint or {"CENTER", "UIParent", "CENTER", 0, 0}
    local relative = _G[p[2]] or UIParent
    frame:SetPoint(p[1] or "CENTER", relative, p[3] or "CENTER", tonumber(p[4]) or 0, tonumber(p[5]) or 0)
    M:ApplyScale(); M:Refresh(); frame:Show(); GC:RequestStatus()
end

function M:Toggle()
    if frame:IsShown() then frame:Hide() else M:Show() end
end

GC:RegisterCallback("CONFIG_CHANGED", function() if frame:IsShown() then M:Refresh() end end)
GC:RegisterCallback("PLAN_CHANGED", function(plan) if frame:IsShown() then M:RefreshPlan(plan) end end)
GC:RegisterCallback("PROFILES_CHANGED", function() if frame:IsShown() then profileDD:Refresh() end end)
GC:RegisterCallback("STATUS", function(text)
    status:SetText(text or "Ready.")
    if GC.backendSeen then backendText:SetText("Backend: connected"); backendText:SetTextColor(C.green[1], C.green[2], C.green[3], 1) end
end)
GC:RegisterCallback("PLAYER_READY", function()
    backendText:SetText("Backend: checking..."); backendText:SetTextColor(C.dim[1], C.dim[2], C.dim[3], 1)
end)

-- Modern shell becomes the default /gc surface. The original frame remains available for
-- compatibility/debugging but is no longer the primary user-facing experience.
function GC:Toggle()
    M:Toggle()
end

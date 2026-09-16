local GC = GroupComposer
local D = GroupComposerData
local P = GroupComposerProfiles

GC.UI = GC.UI or {}
local UI = GC.UI

local C = {
    bg = { 0.025, 0.031, 0.043, 0.985 },
    header = { 0.035, 0.043, 0.059, 1 },
    panel = { 0.047, 0.057, 0.075, 0.98 },
    panel2 = { 0.060, 0.071, 0.094, 0.98 },
    line = { 0.16, 0.20, 0.27, 0.95 },
    blue = { 0.22, 0.58, 0.95, 1 },
    green = { 0.24, 0.82, 0.46, 1 },
    red = { 0.94, 0.28, 0.30, 1 },
    gold = { 1.00, 0.69, 0.20, 1 },
    text = { 0.93, 0.95, 0.99, 1 },
    muted = { 0.62, 0.68, 0.78, 1 },
    dim = { 0.42, 0.47, 0.56, 1 },
}

local ROLE_COLOR = { TANK = C.blue, HEALER = C.green, DPS = C.red }

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
    return fs
end

local function Button(parent, label, width, height, fn, tooltip)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetWidth(width or 100)
    b:SetHeight(height or 24)
    b:SetText(label or "Button")
    if fn then b:SetScript("OnClick", fn) end
    if tooltip then
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(label or "", 1, 1, 1)
            GameTooltip:AddLine(tooltip, 0.78, 0.82, 0.90, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return b
end

local function Checkbox(parent, label, checked, fn)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetWidth(24); cb:SetHeight(24)
    cb:SetChecked(checked and true or false)
    local txt = Text(cb, label, "GameFontHighlightSmall", C.text)
    txt:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    cb.label = txt
    cb:SetScript("OnClick", function(self)
        if fn then fn(self:GetChecked() and true or false) end
    end)
    return cb
end

local function Card(parent, height)
    local f = CreateFrame("Frame", nil, parent)
    f:SetHeight(height or 100)
    local bg = Solid(f, "BACKGROUND", C.panel)
    bg:SetAllPoints(f)
    local top = Solid(f, "ARTWORK", C.line, 0.82)
    top:SetPoint("TOPLEFT", 0, 0); top:SetPoint("TOPRIGHT", 0, 0); top:SetHeight(1)
    f.bg = bg
    return f
end

local function SectionTitle(parent, title, subtitle)
    local h = Text(parent, title, "GameFontNormalLarge", C.text)
    h:SetPoint("TOPLEFT", 16, -13)
    local s = Text(parent, subtitle or "", "GameFontHighlightSmall", C.muted)
    s:SetPoint("TOPLEFT", h, "BOTTOMLEFT", 0, -3)
    s:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
    s:SetJustifyH("LEFT")
    return h, s
end

local function Dropdown(parent, width, getItems, getValue, setValue)
    local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dd, width or 170)
    UIDropDownMenu_JustifyText(dd, "LEFT")
    dd.getItems = getItems
    dd.getValue = getValue
    dd.setValue = setValue
    UIDropDownMenu_Initialize(dd, function(frame, level)
        local items = frame.getItems and frame.getItems() or {}
        local current = frame.getValue and frame.getValue() or nil
        for _, item in ipairs(items) do
            local itemValue = item.value
            local itemLabel = item.label
            local disabled = item.disabled and true or false
            local valueCopy = itemValue
            local disabledCopy = disabled
            local info = UIDropDownMenu_CreateInfo()
            info.text = itemLabel
            info.value = itemValue
            info.checked = current == itemValue
            info.disabled = disabled
            info.func = function()
                if not disabledCopy and frame.setValue then frame.setValue(valueCopy) end
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    function dd:Refresh()
        local items = self.getItems and self.getItems() or {}
        local current = self.getValue and self.getValue() or nil
        local label = nil
        for _, item in ipairs(items) do if item.value == current then label = item.label break end end
        UIDropDownMenu_SetText(self, label or tostring(current or "Select"))
    end
    dd:Refresh()
    return dd
end

local function RoleName(role)
    return D.ROLE_LABEL[role] or role
end

local frame = CreateFrame("Frame", "GroupComposerFrame", UIParent)
UI.frame = frame
frame:SetWidth(1180)
frame:SetHeight(760)
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
frame:Hide()

local function SavePoint()
    if not GC.db then return end
    local p, rel, rp, x, y = frame:GetPoint(1)
    GC.db.window.point = { p, rel and rel:GetName() or "UIParent", rp, x, y }
end
frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePoint() end)

function UI:ApplyScale()
    if not GC.db then return end
    local scale = tonumber(GC.db.window.userScale) or 1
    if GC.db.window.autoScale then
        local pw = UIParent:GetWidth() or 1920
        local ph = UIParent:GetHeight() or 1080
        local fit = math.min((pw - 60) / 1180, (ph - 70) / 760)
        fit = math.max(0.78, math.min(1.40, fit))
        scale = scale * fit
    end
    scale = math.max(0.70, math.min(1.50, scale))
    frame:SetScale(scale)
    if UI.scaleText then UI.scaleText:SetText(string.format("%d%%", math.floor(scale * 100 + 0.5))) end
end

local headerBg = Solid(frame, "BACKGROUND", C.header)
headerBg:SetPoint("TOPLEFT", 5, -5); headerBg:SetPoint("TOPRIGHT", -5, -5); headerBg:SetHeight(66)
local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetWidth(40); icon:SetHeight(40); icon:SetPoint("TOPLEFT", 18, -17)
icon:SetTexture("Interface\\Icons\\INV_Misc_GroupLooking")
local title = Text(frame, "GROUP COMPOSER", "GameFontNormalLarge", C.text)
title:SetPoint("TOPLEFT", 68, -17)
local subtitle = Text(frame, "Build the right team. Keep the adventure, lose the roster spreadsheet.", "GameFontHighlightSmall", C.muted)
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -8, -8)
local dungeonTab = Button(frame, "Dungeon", 108, 28, function() GC:SetMode("DUNGEON") end)
dungeonTab:SetPoint("TOP", frame, "TOP", -58, -23)
local raidTab = Button(frame, "Raid", 108, 28, function() GC:SetMode("RAID") end)
raidTab:SetPoint("LEFT", dungeonTab, "RIGHT", 6, 0)
UI.dungeonTab, UI.raidTab = dungeonTab, raidTab

local toolbar = CreateFrame("Frame", nil, frame)
toolbar:SetPoint("TOPLEFT", 8, -77); toolbar:SetPoint("TOPRIGHT", -8, -77); toolbar:SetHeight(44)
local toolbarBg = Solid(toolbar, "BACKGROUND", C.panel2); toolbarBg:SetAllPoints(toolbar)
local profileLabel = Text(toolbar, "PROFILE", "GameFontHighlightSmall", C.muted); profileLabel:SetPoint("LEFT", 12, 0)
local profileDropdown
local function ProfileItems()
    local items = {}
    for _, name in ipairs(P.ListBuiltins()) do items[#items + 1] = { value = name, label = "Built-in: " .. name } end
    for _, name in ipairs(P.ListCustom()) do items[#items + 1] = { value = name, label = name } end
    if #items == 0 then items[1] = { value = "", label = "No profiles" } end
    return items
end
profileDropdown = Dropdown(toolbar, 245, ProfileItems, function() return GC.db and GC.db.lastProfile end, function(name) GC:LoadProfile(name) end)
profileDropdown:SetPoint("LEFT", profileLabel, "RIGHT", -4, -2)
UI.profileDropdown = profileDropdown

StaticPopupDialogs["GROUPCOMPOSER_SAVE_PROFILE"] = {
    text = "Save the current composition as a profile:",
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = 1,
    maxLetters = 40,
    OnShow = function(self)
        self.editBox:SetText((GC.db and GC.db.lastProfile and not P.GetBuiltin(GC.db.lastProfile)) and GC.db.lastProfile or "")
        self.editBox:SetFocus()
    end,
    OnAccept = function(self)
        local name = self.editBox:GetText()
        if name and name ~= "" then GC:SaveProfile(name) end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local name = self:GetText()
        if name and name ~= "" then GC:SaveProfile(name) end
        parent:Hide()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
}
local saveProfile = Button(toolbar, "Save / Save As", 126, 26, function() StaticPopup_Show("GROUPCOMPOSER_SAVE_PROFILE") end)
saveProfile:SetPoint("LEFT", profileDropdown, "RIGHT", -4, 2)
local deleteProfile = Button(toolbar, "Delete", 74, 26, function()
    local name = GC.db and GC.db.lastProfile
    if name then GC:DeleteProfile(name) end
end)
deleteProfile:SetPoint("LEFT", saveProfile, "RIGHT", 6, 0)
local resetProfile = Button(toolbar, "New", 70, 26, function() GC:SetConfig(P.New(GC:GetConfig().mode), nil) end)
resetProfile:SetPoint("LEFT", deleteProfile, "RIGHT", 6, 0)
local backend = Text(toolbar, "Backend: waiting", "GameFontHighlightSmall", C.dim)
backend:SetPoint("RIGHT", -12, 0)
UI.backendText = backend

local leftPane = CreateFrame("Frame", nil, frame)
leftPane:SetPoint("TOPLEFT", 8, -129)
leftPane:SetPoint("BOTTOMRIGHT", -344, 47)
local scroll = CreateFrame("ScrollFrame", "GroupComposerMainScroll", leftPane, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 0, 0); scroll:SetPoint("BOTTOMRIGHT", -27, 0)
scroll:EnableMouseWheel(true)
scroll:SetScript("OnMouseWheel", function(self, delta)
    local current = self:GetVerticalScroll()
    local range = self:GetVerticalScrollRange()
    self:SetVerticalScroll(math.max(0, math.min(range, current - delta * 42)))
end)
local content = CreateFrame("Frame", nil, scroll)
content:SetWidth(795); content:SetHeight(900)
scroll:SetScrollChild(content)
UI.content = content

local activityCard = Card(content, 116)
activityCard:SetPoint("TOPLEFT", 0, 0); activityCard:SetPoint("TOPRIGHT", 0, 0)
SectionTitle(activityCard, "Activity", "Choose the dungeon or raid. Raid size and difficulty follow the selected instance.")
local activityDropdown = Dropdown(activityCard, 270,
    function()
        local items = {}
        if GC:GetConfig().mode == "RAID" then
            for _, raid in ipairs(D.RAIDS) do items[#items + 1] = { value = raid.id, label = raid.era .. "  •  " .. raid.label } end
        else
            for _, dungeon in ipairs(D.DUNGEONS) do items[#items + 1] = { value = dungeon.id, label = dungeon.label } end
        end
        return items
    end,
    function() return GC:GetConfig().activity end,
    function(value) if GC:GetConfig().mode == "RAID" then GC:SetRaidActivity(value) else GC:SetDungeonActivity(value) end end)
activityDropdown:SetPoint("BOTTOMLEFT", 6, 5)
UI.activityDropdown = activityDropdown
local sizeDropdown = Dropdown(activityCard, 120,
    function()
        local c = GC:GetConfig()
        if c.mode == "DUNGEON" then return { { value = 5, label = "5 Players" } } end
        local raid = D.GetRaidById(c.activity)
        local items = {}
        for _, n in ipairs((raid and raid.sizes) or { 10, 25, 40 }) do items[#items + 1] = { value = n, label = n .. " Players" } end
        return items
    end,
    function() return GC:GetConfig().size end,
    function(value) GC:SetRaidSize(value) end)
sizeDropdown:SetPoint("BOTTOMLEFT", activityDropdown, "BOTTOMRIGHT", -6, 0)
UI.sizeDropdown = sizeDropdown
local difficultyDropdown = Dropdown(activityCard, 170,
    function()
        local c = GC:GetConfig()
        local items = {}
        if c.mode == "DUNGEON" then
            for _, x in ipairs(D.DUNGEON_DIFFICULTIES) do items[#items + 1] = { value = x.id, label = x.label } end
        else
            local raid = D.GetRaidById(c.activity)
            items[#items + 1] = { value = "normal", label = "Normal" }
            if raid and raid.heroic then items[#items + 1] = { value = "heroic", label = "Heroic" } end
        end
        return items
    end,
    function() return GC:GetConfig().difficulty end,
    function(value)
        GC:GetConfig().difficulty = value
        GC:ResetPlan("Difficulty changed")
        GC:Fire("CONFIG_CHANGED", GC:GetConfig())
    end)
difficultyDropdown:SetPoint("BOTTOMLEFT", sizeDropdown, "BOTTOMRIGHT", -6, 0)
UI.difficultyDropdown = difficultyDropdown

local roleCard = Card(content, 176)
roleCard:SetPoint("TOPLEFT", activityCard, "BOTTOMLEFT", 0, -10); roleCard:SetPoint("TOPRIGHT", activityCard, "BOTTOMRIGHT", 0, -10)
SectionTitle(roleCard, "Roster-wide Role Composition", "These totals apply to the whole party or raid. Raid subgroups are arranged only after the roster is correct.")
UI.roleWidgets = {}
local roleDefs = { { role = "TANK", key = "tanks" }, { role = "HEALER", key = "healers" }, { role = "DPS", key = "dps" } }
for i, def in ipairs(roleDefs) do
    local role, key, color = def.role, def.key, ROLE_COLOR[def.role]
    local box = CreateFrame("Frame", nil, roleCard)
    box:SetWidth(246); box:SetHeight(86); box:SetPoint("BOTTOMLEFT", 10 + (i - 1) * 258, 10)
    local bbg = Solid(box, "BACKGROUND", C.panel2); bbg:SetAllPoints(box)
    local stripe = Solid(box, "ARTWORK", color); stripe:SetPoint("TOPLEFT"); stripe:SetPoint("BOTTOMLEFT"); stripe:SetWidth(4)
    local tex = box:CreateTexture(nil, "ARTWORK"); tex:SetWidth(30); tex:SetHeight(30); tex:SetPoint("LEFT", 14, 8); tex:SetTexture(D.ROLE_ICON[role])
    local name = Text(box, RoleName(role), "GameFontNormal", color); name:SetPoint("TOPLEFT", 52, -18)
    local count = Text(box, "0", "GameFontNormalLarge", C.text); count:SetPoint("LEFT", 134, 8)
    local minus = Button(box, "-", 30, 24, function()
        local c = GC:GetConfig(); c[key] = math.max(0, (tonumber(c[key]) or 0) - 1)
        if key ~= "dps" then c.dps = math.max(0, c.size - c.tanks - c.healers) end
        GC:ResetPlan("Role totals changed"); GC:Fire("CONFIG_CHANGED", c)
    end)
    minus:SetPoint("BOTTOMLEFT", 102, 10)
    local plus = Button(box, "+", 30, 24, function()
        local c = GC:GetConfig(); local n = (tonumber(c[key]) or 0) + 1
        if n <= c.size then c[key] = n end
        if key ~= "dps" then c.dps = math.max(0, c.size - c.tanks - c.healers) end
        GC:ResetPlan("Role totals changed"); GC:Fire("CONFIG_CHANGED", c)
    end)
    plus:SetPoint("BOTTOMLEFT", 170, 10)
    UI.roleWidgets[role] = { count = count, key = key }
end

local optionsCard = Card(content, 184)
optionsCard:SetPoint("TOPLEFT", roleCard, "BOTTOMLEFT", 0, -10); optionsCard:SetPoint("TOPRIGHT", roleCard, "BOTTOMRIGHT", 0, -10)
SectionTitle(optionsCard, "Roster Rules", "Humans are always roster anchors. Guild preference is a preference, not permission to build nonsense.")
UI.optionWidgets = {}
local optionDefs = {
    { key = "preferGuild", label = "Prefer Guild Members", x = 14, y = -72 },
    { key = "fillWorld", label = "Fill Missing Roles With World Bots", x = 14, y = -108 },
    { key = "balanceClasses", label = "Balance Class / Utility Coverage", x = 300, y = -108 },
    { key = "avoidDuplicateClasses", label = "Avoid Duplicate Classes When Practical", x = 570, y = -72 },
}
for _, def in ipairs(optionDefs) do
    local key = def.key
    local cb = Checkbox(optionsCard, def.label, true, function(checked)
        GC:GetConfig().options[key] = checked
        GC:ResetPlan("Roster rule changed"); GC:Fire("CONFIG_CHANGED", GC:GetConfig())
    end)
    cb:SetPoint("TOPLEFT", def.x, def.y)
    UI.optionWidgets[key] = cb
end
local anchorText = Text(optionsCard, "YOU - Locked human anchor", "GameFontNormalSmall", C.gold)
anchorText:SetPoint("TOPLEFT", 304, -76)
local anchorHint = Text(optionsCard, "Always included in every composed roster", "GameFontHighlightSmall", C.muted)
anchorHint:SetPoint("TOPLEFT", 304, -91)
local ilvlLabel = Text(optionsCard, "Minimum Item Level", "GameFontHighlightSmall", C.text)
ilvlLabel:SetPoint("TOPLEFT", 570, -110)
local ilvlInput = CreateFrame("EditBox", nil, optionsCard, "InputBoxTemplate")
ilvlInput:SetWidth(74); ilvlInput:SetHeight(24); ilvlInput:SetAutoFocus(false); ilvlInput:SetNumeric(true); ilvlInput:SetMaxLetters(3)
ilvlInput:SetPoint("LEFT", ilvlLabel, "RIGHT", 8, 0)
ilvlInput:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    local value = math.max(0, math.min(999, tonumber(self:GetText()) or 0))
    GC:GetConfig().options.minimumItemLevel = value
    self:SetText(tostring(value))
    GC:ResetPlan("Minimum item level changed"); GC:Fire("CONFIG_CHANGED", GC:GetConfig())
end)
ilvlInput:SetScript("OnEditFocusLost", function(self)
    local value = math.max(0, math.min(999, tonumber(self:GetText()) or 0))
    if value ~= (GC:GetConfig().options.minimumItemLevel or 0) then
        GC:GetConfig().options.minimumItemLevel = value
        GC:ResetPlan("Minimum item level changed"); GC:Fire("CONFIG_CHANGED", GC:GetConfig())
    end
    self:SetText(tostring(value))
end)
UI.ilvlInput = ilvlInput

local prefsCard = Card(content, 258)
prefsCard:SetPoint("TOPLEFT", optionsCard, "BOTTOMLEFT", 0, -10); prefsCard:SetPoint("TOPRIGHT", optionsCard, "BOTTOMRIGHT", 0, -10)
SectionTitle(prefsCard, "Class / Spec Preferences", "Add soft preferences or hard requirements. Empty means any valid class/spec for that role.")
local prefsContainer = CreateFrame("Frame", nil, prefsCard)
prefsContainer:SetPoint("TOPLEFT", 12, -58); prefsContainer:SetPoint("BOTTOMRIGHT", -12, 10)
UI.prefRows = { TANK = {}, HEALER = {}, DPS = {} }
UI.prefEmpty = {}
UI.prefAreas = {}
local function ClassItemsForRole(role)
    local items = { { value = "ANY", label = "Any valid class" } }
    for _, token in ipairs(D.CLASS_ORDER) do if D.CLASS_ROLE[role][token] then items[#items + 1] = { value = token, label = D.CLASS_LABEL[token] } end end
    return items
end
local function SpecItems(role, classToken)
    local items = { { value = "ANY", label = "Any valid spec" } }
    if classToken and classToken ~= "ANY" then
        for _, spec in ipairs(D.SPECS[classToken] or {}) do
            if spec.role == role or (role == "TANK" and spec.canTank) then items[#items + 1] = { value = spec.id, label = spec.label } end
        end
    end
    return items
end
local function RemovePreference(role, index)
    if not role or not index then return end
    table.remove(GC:GetConfig().preferences[role], index)
    GC:ResetPlan("Preference changed"); GC:Fire("CONFIG_CHANGED", GC:GetConfig())
end
local function AddPreference(role)
    local list = GC:GetConfig().preferences[role]
    if #list >= 4 then GC:Fire("STATUS", "Up to four visible preferences per role are supported in this panel."); return end
    list[#list + 1] = { class = "ANY", spec = "ANY", required = false }
    GC:ResetPlan("Preference changed"); GC:Fire("CONFIG_CHANGED", GC:GetConfig())
end
for i, roleValue in ipairs({ "TANK", "HEALER", "DPS" }) do
    local role = roleValue
    local area = CreateFrame("Frame", nil, prefsContainer)
    area:SetWidth(246); area:SetPoint("TOPLEFT", (i - 1) * 258, 0); area:SetPoint("BOTTOM", 0, 0)
    local roleTitle = Text(area, RoleName(role), "GameFontNormal", ROLE_COLOR[role]); roleTitle:SetPoint("TOPLEFT", 4, 0)
    local add = Button(area, "+ Preference", 94, 22, function() AddPreference(role) end); add:SetPoint("TOPRIGHT", -2, 6)
    UI.prefAreas[role] = area
    local empty = Text(area, "Any valid " .. string.lower(RoleName(role)), "GameFontHighlightSmall", C.dim)
    empty:SetPoint("TOPLEFT", 4, -28); empty:Hide()
    UI.prefEmpty[role] = empty
end

local function AcquirePrefRow(role, index)
    local existing = UI.prefRows[role][index]
    if existing then return existing end
    local area = UI.prefAreas[role]
    local row = CreateFrame("Frame", nil, area)
    row:SetHeight(36)

    local classDD
    classDD = Dropdown(row, 86,
        function() return ClassItemsForRole(row.currentRole or role) end,
        function()
            local pref = row.currentPref
            return pref and (pref.class or "ANY") or "ANY"
        end,
        function(value)
            local pref = row.currentPref
            if not pref then return end
            pref.class = value; pref.spec = "ANY"
            GC:ResetPlan("Preference changed"); GC:Fire("CONFIG_CHANGED", GC:GetConfig())
        end)
    classDD:SetPoint("LEFT", -14, 0)

    local specDD
    specDD = Dropdown(row, 78,
        function()
            local pref = row.currentPref
            return SpecItems(row.currentRole or role, pref and pref.class or "ANY")
        end,
        function()
            local pref = row.currentPref
            if not pref then return "ANY" end
            return pref.spec == nil and "ANY" or pref.spec
        end,
        function(value)
            local pref = row.currentPref
            if not pref then return end
            pref.spec = value
            GC:ResetPlan("Preference changed"); GC:Fire("CONFIG_CHANGED", GC:GetConfig())
        end)
    specDD:SetPoint("LEFT", classDD, "RIGHT", -22, 0)

    local req = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    req:SetWidth(20); req:SetHeight(20); req:SetPoint("RIGHT", -26, 0)
    req:SetScript("OnClick", function(self)
        local pref = row.currentPref
        if not pref then return end
        pref.required = self:GetChecked() and true or false
        GC:ResetPlan("Preference changed"); GC:Fire("CONFIG_CHANGED", GC:GetConfig())
    end)
    local reqText = Text(row, "Req", "GameFontHighlightSmall", C.muted); reqText:SetPoint("LEFT", req, "RIGHT", -2, 0)
    local remove = CreateFrame("Button", nil, row, "UIPanelCloseButton")
    remove:SetWidth(20); remove:SetHeight(20); remove:SetPoint("RIGHT", 2, 0)
    remove:SetScript("OnClick", function() RemovePreference(row.currentRole, row.currentIndex) end)

    row.classDD, row.specDD, row.required = classDD, specDD, req
    UI.prefRows[role][index] = row
    return row
end

local function BuildPrefRows()
    local c = GC:GetConfig()
    for _, role in ipairs({ "TANK", "HEALER", "DPS" }) do
        UI.prefEmpty[role]:Hide()
        for _, row in ipairs(UI.prefRows[role]) do row:Hide() end
        local list = c.preferences[role] or {}
        if #list == 0 then
            UI.prefEmpty[role]:Show()
        else
            for index, pref in ipairs(list) do
                local row = AcquirePrefRow(role, index)
                row.currentRole, row.currentIndex, row.currentPref = role, index, pref
                row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -20 - (index - 1) * 38); row:SetPoint("RIGHT", 0, 0)
                row.required:SetChecked(pref.required and true or false)
                row.classDD:Refresh(); row.specDD:Refresh(); row:Show()
            end
        end
    end
end
UI.BuildPrefRows = BuildPrefRows

local humansCard = Card(content, 122)
humansCard:SetPoint("TOPLEFT", prefsCard, "BOTTOMLEFT", 0, -10); humansCard:SetPoint("TOPRIGHT", prefsCard, "BOTTOMRIGHT", 0, -10)
SectionTitle(humansCard, "Current Group Anchors", "Real players already grouped with you are locked by the server and count toward the final composition. Existing bots may be reused when suitable.")
local humansText = Text(humansCard, "Scanning current group...", "GameFontHighlightSmall", C.text)
humansText:SetPoint("TOPLEFT", 16, -62); humansText:SetPoint("RIGHT", -16, 0); humansText:SetJustifyH("LEFT")
UI.humansText = humansText
local searchCard = Card(content, 94)
searchCard:SetPoint("TOPLEFT", humansCard, "BOTTOMLEFT", 0, -10); searchCard:SetPoint("TOPRIGHT", humansCard, "BOTTOMRIGHT", 0, -10)
local readyText = Text(searchCard, "Configure the roster, then let the server build a deterministic preview.", "GameFontHighlight", C.muted)
readyText:SetPoint("LEFT", 16, 7)
local findButton = Button(searchCard, "Find Roster", 150, 34, function() GC:FindRoster() end, "Search the safe candidate pools and build a preview. Nothing is invited yet.")
findButton:SetPoint("RIGHT", -16, 7)
UI.findButton = findButton
content:SetHeight(1010)

local summary = CreateFrame("Frame", nil, frame)
summary:SetPoint("TOPRIGHT", -8, -129); summary:SetPoint("BOTTOMRIGHT", -8, 47); summary:SetWidth(326)
local sumBg = Solid(summary, "BACKGROUND", C.panel); sumBg:SetAllPoints(summary)
local sumTitle = Text(summary, "COMPOSITION PREVIEW", "GameFontNormal", C.text); sumTitle:SetPoint("TOPLEFT", 16, -15)
local sumState = Text(summary, "Not searched", "GameFontHighlightSmall", C.muted); sumState:SetPoint("TOPRIGHT", -16, -17)
UI.sumState = sumState
local totalText = Text(summary, "0 / 5", "GameFontNormalLarge", C.text); totalText:SetPoint("TOPLEFT", 16, -43)
UI.totalText = totalText
local roleSummary = Text(summary, "Tank 0/1    Healer 0/1    DPS 0/3", "GameFontHighlightSmall", C.muted)
roleSummary:SetPoint("TOPLEFT", totalText, "BOTTOMLEFT", 0, -4); roleSummary:SetPoint("RIGHT", -16, 0)
UI.roleSummary = roleSummary
local sourceSummary = Text(summary, "Humans 0  •  Guild 0  •  World 0", "GameFontHighlightSmall", C.muted)
sourceSummary:SetPoint("TOPLEFT", roleSummary, "BOTTOMLEFT", 0, -4); sourceSummary:SetPoint("RIGHT", -16, 0)
UI.sourceSummary = sourceSummary
local divider = Solid(summary, "ARTWORK", C.line); divider:SetPoint("TOPLEFT", 12, -102); divider:SetPoint("TOPRIGHT", -12, -102); divider:SetHeight(1)
local warningsLabel = Text(summary, "WARNINGS & SUGGESTIONS", "GameFontNormalSmall", C.gold); warningsLabel:SetPoint("TOPLEFT", 16, -116)
local warningsText = Text(summary, "Find a roster to validate composition.", "GameFontHighlightSmall", C.muted)
warningsText:SetPoint("TOPLEFT", 16, -138); warningsText:SetPoint("RIGHT", -16, 0); warningsText:SetHeight(58); warningsText:SetJustifyH("LEFT"); warningsText:SetJustifyV("TOP")
UI.warningsText = warningsText
local rosterLabel = Text(summary, "ROSTER", "GameFontNormalSmall", C.text); rosterLabel:SetPoint("TOPLEFT", 16, -206)
local rosterScroll = CreateFrame("ScrollFrame", "GroupComposerRosterScroll", summary, "UIPanelScrollFrameTemplate")
rosterScroll:SetPoint("TOPLEFT", 12, -226); rosterScroll:SetPoint("BOTTOMRIGHT", -29, 62); rosterScroll:EnableMouseWheel(true)
rosterScroll:SetScript("OnMouseWheel", function(self, delta)
    local current, range = self:GetVerticalScroll(), self:GetVerticalScrollRange()
    self:SetVerticalScroll(math.max(0, math.min(range, current - delta * 32)))
end)
local rosterContent = CreateFrame("Frame", nil, rosterScroll)
rosterContent:SetWidth(278); rosterContent:SetHeight(400); rosterScroll:SetScrollChild(rosterContent)
UI.rosterContent = rosterContent
UI.rosterRows = {}
local arrangeButton = Button(summary, "Auto Arrange", 102, 28, function() GC:AutoArrange() end, "Rearrange subgroups without changing who is in the roster.")
arrangeButton:SetPoint("BOTTOMLEFT", 12, 16)
local assembleButton = Button(summary, "Assemble", 116, 28, function() GC:Assemble() end, "Invite the validated preview. This is the deliberate commit step.")
assembleButton:SetPoint("BOTTOMRIGHT", -12, 16)
UI.arrangeButton, UI.assembleButton = arrangeButton, assembleButton

local footerLine = Solid(frame, "ARTWORK", C.line); footerLine:SetPoint("BOTTOMLEFT", 10, 42); footerLine:SetPoint("BOTTOMRIGHT", -10, 42); footerLine:SetHeight(1)
local statusText = Text(frame, "Ready.", "GameFontHighlightSmall", C.muted)
statusText:SetPoint("BOTTOMLEFT", 16, 17); statusText:SetPoint("RIGHT", -250, 0); statusText:SetJustifyH("LEFT")
UI.statusText = statusText
local scaleMinus = Button(frame, "-", 28, 22, function()
    GC.db.window.userScale = math.max(0.75, (GC.db.window.userScale or 1) - 0.05); UI:ApplyScale()
end)
scaleMinus:SetPoint("BOTTOMRIGHT", -184, 11)
local autoScale = Checkbox(frame, "Auto scale", true, function(checked) GC.db.window.autoScale = checked; UI:ApplyScale() end)
autoScale:SetPoint("BOTTOMRIGHT", -118, 10)
UI.autoScale = autoScale
local scalePlus = Button(frame, "+", 28, 22, function()
    GC.db.window.userScale = math.min(1.50, (GC.db.window.userScale or 1) + 0.05); UI:ApplyScale()
end)
scalePlus:SetPoint("BOTTOMRIGHT", -16, 11)
local scaleText = Text(frame, "100%", "GameFontHighlightSmall", C.muted); scaleText:SetPoint("BOTTOMRIGHT", scalePlus, "BOTTOMLEFT", -5, 6)
UI.scaleText = scaleText

local function RenderHumans()
    local humans = GC:ScanHumans()
    if #humans == 0 then humansText:SetText("No current group members detected."); return end
    local bits = {}
    for _, h in ipairs(humans) do
        local className = D.CLASS_LABEL[h.class] or h.class or "Unknown"
        bits[#bits + 1] = h.name .. " (" .. className .. ")"
    end
    humansText:SetText(table.concat(bits, "   •   "))
end
local function HideRosterRows()
    for _, row in ipairs(UI.rosterRows or {}) do row:Hide() end
    for _, row in ipairs(UI.rosterGroupRows or {}) do row:Hide() end
    if UI.rosterEmpty then UI.rosterEmpty:Hide() end
end

UI.rosterGroupRows = UI.rosterGroupRows or {}

local function AcquireRosterGroup(index)
    local holder = UI.rosterGroupRows[index]
    if holder then return holder end
    holder = CreateFrame("Frame", nil, rosterContent)
    holder:SetWidth(272); holder:SetHeight(20)
    holder.text = Text(holder, "", "GameFontNormalSmall", C.muted)
    holder.text:SetPoint("LEFT", 2, 0)
    UI.rosterGroupRows[index] = holder
    return holder
end

local function AcquireRosterRow(index)
    local row = UI.rosterRows[index]
    if row then return row end
    row = CreateFrame("Frame", nil, rosterContent)
    row:SetWidth(272); row:SetHeight(28)
    row.bg = Solid(row, "BACKGROUND", C.panel, 0.85); row.bg:SetAllPoints(row)
    row.stripe = Solid(row, "ARTWORK", C.muted); row.stripe:SetPoint("TOPLEFT"); row.stripe:SetPoint("BOTTOMLEFT"); row.stripe:SetWidth(3)
    row.nameText = Text(row, "", "GameFontHighlightSmall", C.text); row.nameText:SetPoint("LEFT", 8, 0); row.nameText:SetWidth(108); row.nameText:SetJustifyH("LEFT")
    row.roleText = Text(row, "", "GameFontHighlightSmall", C.muted); row.roleText:SetPoint("LEFT", 120, 0); row.roleText:SetWidth(52); row.roleText:SetJustifyH("LEFT")
    row.classText = Text(row, "", "GameFontHighlightSmall", C.muted); row.classText:SetPoint("LEFT", 176, 0); row.classText:SetWidth(72); row.classText:SetJustifyH("LEFT")
    row.sourceText = Text(row, "", "GameFontNormalSmall", C.blue); row.sourceText:SetPoint("RIGHT", -6, 0)
    UI.rosterRows[index] = row
    return row
end

local function RenderRoster(plan)
    HideRosterRows()
    local members, rowHeight, lastGroup, y = plan.members or {}, 28, -1, 0
    local groupIndex = 0
    for index, member in ipairs(members) do
        if member.subgroup and member.subgroup > 0 and member.subgroup ~= lastGroup then
            lastGroup = member.subgroup
            groupIndex = groupIndex + 1
            local group = AcquireRosterGroup(groupIndex)
            group:ClearAllPoints(); group:SetPoint("TOPLEFT", 0, -y)
            group.text:SetText("Group " .. member.subgroup); group:Show(); y = y + 20
        end

        local row = AcquireRosterRow(index)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y)
        local bg = index % 2 == 0 and C.panel2 or C.panel
        row.bg:SetTexture(bg[1], bg[2], bg[3], 0.85)
        local color = ROLE_COLOR[member.role] or C.muted
        row.stripe:SetTexture(color[1], color[2], color[3], color[4] or 1)
        row.nameText:SetText(member.name or "?")
        local nameColor = member.human and C.gold or C.text
        row.nameText:SetTextColor(nameColor[1], nameColor[2], nameColor[3], nameColor[4] or 1)
        row.roleText:SetText(RoleName(member.role)); row.roleText:SetTextColor(color[1], color[2], color[3], color[4] or 1)
        row.classText:SetText(D.CLASS_LABEL[member.class] or member.class or "?")
        local sourceLetter = member.human and "H" or (member.source == "GUILD" and "G" or (member.source == "ROSTER" and "R" or "W"))
        row.sourceText:SetText(sourceLetter)
        local sourceColor = member.human and C.gold or (member.source == "GUILD" and C.green or C.blue)
        row.sourceText:SetTextColor(sourceColor[1], sourceColor[2], sourceColor[3], sourceColor[4] or 1)
        row:Show(); y = y + rowHeight + 2
    end

    if #members == 0 then
        if not UI.rosterEmpty then
            UI.rosterEmpty = Text(rosterContent, "No roster preview yet.\n\nFind Roster builds the team without inviting anyone.", "GameFontHighlightSmall", C.dim)
            UI.rosterEmpty:SetPoint("TOPLEFT", 4, -8); UI.rosterEmpty:SetPoint("RIGHT", -8, 0); UI.rosterEmpty:SetJustifyH("LEFT")
        end
        UI.rosterEmpty:Show(); y = 100
    end
    rosterContent:SetHeight(math.max(340, y + 12))
end

function UI:RefreshConfig()
    if not GC.db then return end
    local c = GC:GetConfig()
    if c.mode == "DUNGEON" then dungeonTab:LockHighlight(); raidTab:UnlockHighlight() else raidTab:LockHighlight(); dungeonTab:UnlockHighlight() end
    activityDropdown:Refresh(); sizeDropdown:Refresh(); difficultyDropdown:Refresh(); profileDropdown:Refresh()
    for _, widget in pairs(UI.roleWidgets) do widget.count:SetText(tostring(c[widget.key] or 0)) end
    for key, cb in pairs(UI.optionWidgets) do cb:SetChecked(c.options[key] and true or false) end
    if UI.ilvlInput then UI.ilvlInput:SetText(tostring(c.options.minimumItemLevel or 0)) end
    autoScale:SetChecked(GC.db.window.autoScale and true or false)
    BuildPrefRows(); RenderHumans(); UI:RefreshPlan(GC.plan)
end

function UI:RefreshPlan(plan)
    local c = GC:GetConfig()
    local total = (plan.summary and plan.summary.total) or #plan.members
    totalText:SetText(tostring(total or 0) .. " / " .. tostring(c.size))
    roleSummary:SetText("Tank " .. tostring(c.tanks) .. "   •   Healer " .. tostring(c.healers) .. "   •   DPS " .. tostring(c.dps))
    local humans = plan.summary and plan.summary.humans or 0
    local guild = plan.summary and plan.summary.guild or 0
    local world = plan.summary and plan.summary.world or 0
    sourceSummary:SetText("Humans " .. humans .. "  •  Guild " .. guild .. "  •  World " .. world)
    if plan.ready then
        if plan.valid then sumState:SetText("VALID"); sumState:SetTextColor(C.green[1], C.green[2], C.green[3])
        else sumState:SetText("NEEDS ATTENTION"); sumState:SetTextColor(C.gold[1], C.gold[2], C.gold[3]) end
    else
        sumState:SetText("Not searched"); sumState:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
    end
    if plan.warnings and #plan.warnings > 0 then
        local lines = {}
        for i = 1, math.min(3, #plan.warnings) do lines[#lines + 1] = "• " .. plan.warnings[i] end
        if #plan.warnings > 3 then lines[#lines + 1] = "+ " .. (#plan.warnings - 3) .. " more" end
        warningsText:SetText(table.concat(lines, "\n")); warningsText:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    elseif plan.ready and plan.valid then
        warningsText:SetText("Composition looks good. Review the roster, then Assemble when ready.")
        warningsText:SetTextColor(C.green[1], C.green[2], C.green[3])
    else
        warningsText:SetText("Find a roster to validate composition."); warningsText:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
    end
    if plan.ready and plan.valid then assembleButton:Enable(); assembleButton:SetAlpha(1) else assembleButton:Disable(); assembleButton:SetAlpha(0.45) end
    if plan.ready then arrangeButton:Enable(); arrangeButton:SetAlpha(1) else arrangeButton:Disable(); arrangeButton:SetAlpha(0.45) end
    RenderRoster(plan)
end

function UI:Show()
    if not GC.db then return end
    frame:ClearAllPoints()
    local point = GC.db.window.point or { "CENTER", "UIParent", "CENTER", 0, 0 }
    local relative = _G[point[2]] or UIParent
    frame:SetPoint(point[1] or "CENTER", relative, point[3] or "CENTER", tonumber(point[4]) or 0, tonumber(point[5]) or 0)
    UI:ApplyScale(); UI:RefreshConfig(); frame:Show(); GC:RequestStatus()
end
function GC:Toggle() if frame:IsShown() then frame:Hide() else UI:Show() end end

GC:RegisterCallback("CONFIG_CHANGED", function() UI:RefreshConfig() end)
GC:RegisterCallback("PLAN_CHANGED", function(plan) UI:RefreshPlan(plan) end)
GC:RegisterCallback("HUMANS_CHANGED", function() RenderHumans() end)
GC:RegisterCallback("PROFILES_CHANGED", function() profileDropdown:Refresh() end)
GC:RegisterCallback("STATUS", function(text) statusText:SetText(text or "Ready.") end)
GC:RegisterCallback("PLAYER_READY", function()
    if GC.db then backend:SetText("Backend: checking..."); UI:ApplyScale() end
end)

local mini = CreateFrame("Button", "GroupComposerMinimapButton", Minimap)
mini:SetWidth(31); mini:SetHeight(31); mini:SetFrameStrata("MEDIUM"); mini:SetFrameLevel(8); mini:RegisterForClicks("LeftButtonUp")
local miniIcon = mini:CreateTexture(nil, "BACKGROUND"); miniIcon:SetWidth(20); miniIcon:SetHeight(20); miniIcon:SetPoint("CENTER"); miniIcon:SetTexture("Interface\\Icons\\INV_Misc_GroupLooking")
local miniBorder = mini:CreateTexture(nil, "OVERLAY"); miniBorder:SetWidth(53); miniBorder:SetHeight(53); miniBorder:SetPoint("TOPLEFT"); miniBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
mini:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -8, 4)
mini:SetScript("OnClick", function() GC:Toggle() end)
mini:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:AddLine("Group Composer"); GameTooltip:AddLine("Build dungeon and raid rosters.", 1, 1, 1); GameTooltip:Show()
end)
mini:SetScript("OnLeave", function() GameTooltip:Hide() end)
GC:RegisterCallback("PLAN_CHANGED", function()
    if GC.backendSeen then backend:SetText("Backend: connected"); backend:SetTextColor(C.green[1], C.green[2], C.green[3]) end
end)
GC:RegisterCallback("STATUS", function()
    if GC.backendSeen then backend:SetText("Backend: connected"); backend:SetTextColor(C.green[1], C.green[2], C.green[3]) end
end)

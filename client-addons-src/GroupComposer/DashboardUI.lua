local GC = GroupComposer
local D = GroupComposerData

GC.Dashboard = GC.Dashboard or {}
local U = GC.Dashboard

local C = {
    bg = { 0.018, 0.024, 0.034, 0.985 }, panel = { 0.035, 0.046, 0.062, 0.98 },
    panel2 = { 0.050, 0.065, 0.087, 0.98 }, line = { 0.14, 0.20, 0.28, 1 },
    blue = { 0.20, 0.58, 0.96, 1 }, green = { 0.22, 0.82, 0.44, 1 },
    red = { 0.96, 0.30, 0.33, 1 }, gold = { 1.00, 0.70, 0.20, 1 },
    text = { 0.94, 0.96, 1.00, 1 }, muted = { 0.61, 0.69, 0.80, 1 }, dim = { 0.39, 0.46, 0.57, 1 },
}
local ROLE_COLOR = { TANK = C.blue, HEALER = C.green, DPS = C.red }

local READY_RAIDS = {
    "obsidian_sanctum", "eye_of_eternity", "onyxia", "icecrown",
    "ruby_sanctum", "gruul", "magtheridon",
}
local READY_RAID_SET = {}
for _, id in ipairs(READY_RAIDS) do READY_RAID_SET[id] = true end

local function Solid(parent, color, alpha)
    local t = parent:CreateTexture(nil, "BACKGROUND")
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

local function Panel(parent)
    local f = CreateFrame("Frame", nil, parent)
    local bg = Solid(f, C.panel); bg:SetAllPoints(f)
    f.bg = bg
    return f
end

local function Button(parent, label, width, height, fn)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(width or 110); b:SetHeight(height or 28)
    local bg = Solid(b, C.panel2); bg:SetAllPoints(b)
    local edge = b:CreateTexture(nil, "BORDER"); edge:SetTexture(C.line[1], C.line[2], C.line[3], 1); edge:SetPoint("TOPLEFT", -1, 1); edge:SetPoint("BOTTOMRIGHT", 1, -1)
    bg:SetDrawLayer("BACKGROUND", 1); edge:SetDrawLayer("BACKGROUND", 0)
    local txt = Text(b, label or "Button", "GameFontHighlightSmall", C.text); txt:SetPoint("CENTER")
    b.label, b.fill, b.edge = txt, bg, edge
    b:SetScript("OnEnter", function(self) self.fill:SetTexture(0.075, 0.105, 0.145, 1) end)
    b:SetScript("OnLeave", function(self) self.fill:SetTexture(C.panel2[1], C.panel2[2], C.panel2[3], 1) end)
    if fn then b:SetScript("OnClick", fn) end
    function b:SetAccent(color, active)
        if active then
            self.edge:SetTexture(color[1], color[2], color[3], 1)
            self.fill:SetTexture(color[1] * 0.20, color[2] * 0.20, color[3] * 0.20, 1)
            self.label:SetTextColor(color[1], color[2], color[3], 1)
        else
            self.edge:SetTexture(C.line[1], C.line[2], C.line[3], 1)
            self.fill:SetTexture(C.panel2[1], C.panel2[2], C.panel2[3], 1)
            self.label:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
        end
    end
    return b
end

local activeMenu
local function CloseMenu()
    if activeMenu then activeMenu:Hide(); activeMenu = nil end
end

local function Selector(parent, width, getItems, getValue, setValue)
    local b = Button(parent, "Select", width or 250, 30)
    b.valueText = b.label
    b.arrow = Text(b, "v", "GameFontHighlightSmall", C.muted); b.arrow:SetPoint("RIGHT", -9, 0)
    local menu = CreateFrame("Frame", nil, b)
    menu:SetFrameStrata("TOOLTIP"); menu:SetWidth(width or 250); menu:Hide()
    local mbg = Solid(menu, C.bg); mbg:SetAllPoints(menu)
    local border = menu:CreateTexture(nil, "BORDER"); border:SetTexture(C.blue[1], C.blue[2], C.blue[3], 0.85); border:SetPoint("TOPLEFT", -1, 1); border:SetPoint("BOTTOMRIGHT", 1, -1)
    menu.buttons = {}

    function b:Refresh()
        local current = getValue and getValue() or nil
        local label = "Select"
        for _, item in ipairs(getItems and getItems() or {}) do if item.value == current then label = item.label break end end
        self.valueText:SetText(label)
    end

    function b:OpenMenu()
        CloseMenu()
        local items = getItems and getItems() or {}
        for _, row in ipairs(menu.buttons) do row:Hide() end
        local h = 0
        for i, item in ipairs(items) do
            local row = menu.buttons[i]
            if not row then
                row = Button(menu, "", (width or 250) - 8, 22)
                row:SetPoint("TOPLEFT", 4, -4 - ((i - 1) * 23))
                menu.buttons[i] = row
            end
            row.label:SetText(item.label)
            local value = item.value
            row:SetScript("OnClick", function()
                if setValue then setValue(value) end
                CloseMenu(); b:Refresh()
            end)
            row:Show(); h = h + 23
        end
        menu:SetHeight(h + 8); menu:ClearAllPoints(); menu:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, -3)
        menu:Show(); activeMenu = menu
    end
    b:SetScript("OnClick", function() if menu:IsShown() then CloseMenu() else b:OpenMenu() end end)
    b:Refresh()
    return b
end

local function Check(parent, label, key, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetWidth(24); cb:SetHeight(24); cb:SetPoint("TOPLEFT", x, y)
    local t = Text(cb, label, "GameFontHighlightSmall", C.text); t:SetPoint("LEFT", cb, "RIGHT", 3, 0)
    cb.text = t; cb.key = key
    cb:SetScript("OnClick", function(self)
        GC:GetConfig().options[self.key] = self:GetChecked() and true or false
        GC:Touch("Roster option changed")
    end)
    return cb
end

local frame = CreateFrame("Frame", "GroupComposerDashboardFrame", UIParent)
U.frame = frame
frame:SetWidth(1320); frame:SetHeight(820); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton"); frame:SetScript("OnDragStart", frame.StartMoving); frame:SetScript("OnDragStop", frame.StopMovingOrSizing); frame:Hide()
local rootBg = Solid(frame, C.bg); rootBg:SetAllPoints(frame)
local rootBorder = frame:CreateTexture(nil, "BORDER"); rootBorder:SetTexture(C.line[1], C.line[2], C.line[3], 1); rootBorder:SetPoint("TOPLEFT", -1, 1); rootBorder:SetPoint("BOTTOMRIGHT", 1, -1)

UISpecialFrames = UISpecialFrames or {}
local foundSpecial = false
for _, name in ipairs(UISpecialFrames) do if name == "GroupComposerDashboardFrame" then foundSpecial = true end end
if not foundSpecial then table.insert(UISpecialFrames, "GroupComposerDashboardFrame") end

-- Header ----------------------------------------------------------------------
local header = Panel(frame); header:SetPoint("TOPLEFT", 1, -1); header:SetPoint("TOPRIGHT", -1, -1); header:SetHeight(68)
local icon = header:CreateTexture(nil, "ARTWORK"); icon:SetTexture("Interface\\Icons\\Achievement_General_StayClassy"); icon:SetWidth(42); icon:SetHeight(42); icon:SetPoint("LEFT", 16, 0)
local title = Text(header, "GROUP COMPOSER", "GameFontNormalLarge", C.text); title:SetPoint("TOPLEFT", 70, -12)
local subtitle = Text(header, "Build a role-correct bot party, then review it before anything is invited.", "GameFontHighlightSmall", C.muted); subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)

local dungeonTab = Button(header, "Dungeon", 120, 32, function() GC:SetMode("DUNGEON") end); dungeonTab:SetPoint("LEFT", 530, 0)
local raidTab = Button(header, "Raid", 120, 32, function() GC:SetMode("RAID") end); raidTab:SetPoint("LEFT", dungeonTab, "RIGHT", 10, 0)
local editor = Button(header, "Roster Editor", 125, 30, function() if GC.Advanced then GC.Advanced:Toggle() end end); editor:SetPoint("RIGHT", -126, 0)
local close = Button(header, "Close  X", 104, 30, function() frame:Hide(); CloseMenu() end); close:SetPoint("RIGHT", -12, 0); close:SetAccent(C.red, true)

local body = CreateFrame("Frame", nil, frame); body:SetPoint("TOPLEFT", 14, -82); body:SetPoint("BOTTOMRIGHT", -14, 48)
local statusBar = Panel(frame); statusBar:SetPoint("BOTTOMLEFT", 14, 12); statusBar:SetPoint("BOTTOMRIGHT", -14, 12); statusBar:SetHeight(27)
local statusText = Text(statusBar, "Ready.", "GameFontHighlightSmall", C.muted); statusText:SetPoint("LEFT", 10, 0)
local backendText = Text(statusBar, "Backend: checking...", "GameFontHighlightSmall", C.green); backendText:SetPoint("RIGHT", -10, 0)

local dungeonPage = CreateFrame("Frame", nil, body); dungeonPage:SetAllPoints(body)
local raidPage = CreateFrame("Frame", nil, body); raidPage:SetAllPoints(body)

-- Shared helpers ---------------------------------------------------------------
local function DungeonItems()
    local out = {}
    for _, d in ipairs(D.DUNGEONS) do out[#out + 1] = { value = d.id, label = d.label } end
    return out
end
local function DifficultyItems(list)
    local out = {}; for _, d in ipairs(list) do out[#out + 1] = { value = d.id, label = d.label } end; return out
end
local function ReadyRaidObjects()
    local out = {}
    for _, id in ipairs(READY_RAIDS) do local r = D.GetRaidById(id); if r then out[#out + 1] = r end end
    return out
end

local function SetRoleCount(role, delta)
    local c = GC:GetConfig(); local key = role == "TANK" and "tanks" or role == "HEALER" and "healers" or "dps"
    local value = math.max(0, (tonumber(c[key]) or 0) + delta)
    if role ~= "DPS" then
        local other = role == "TANK" and (tonumber(c.healers) or 0) or (tonumber(c.tanks) or 0)
        value = math.min(value, c.size - other)
        c[key] = value; c.dps = math.max(0, c.size - c.tanks - c.healers)
    else
        c.dps = value
    end
    GC:Touch("Role composition changed")
end

local function PreferenceLabel(role)
    local prefs = GC:GetConfig().preferences[role] or {}
    if #prefs == 0 then return "Any valid " .. string.lower(D.ROLE_LABEL[role] or role) end
    local p = prefs[1]; return (D.CLASS_LABEL[p.class] or p.class or "Any") .. (p.required and " (Required)" or " (Preferred)")
end

local function ToggleClassPreference(role, token)
    local c = GC:GetConfig(); c.preferences[role] = c.preferences[role] or {}
    if c.preferences[role][1] and c.preferences[role][1].class == token then c.preferences[role] = {}
    else c.preferences[role] = { { class = token, spec = "ANY", required = false } } end
    GC:Touch("Class preference changed")
end

local function RoleCard(parent, role, x, y, width, prefMode)
    local card = Panel(parent); card:SetPoint("TOPLEFT", x, y); card:SetWidth(width); card:SetHeight(prefMode and 154 or 112)
    local color = ROLE_COLOR[role]; local stripe = Solid(card, color); stripe:SetPoint("TOPLEFT"); stripe:SetPoint("BOTTOMLEFT"); stripe:SetWidth(4)
    local tex = card:CreateTexture(nil, "ARTWORK"); tex:SetTexture(D.ROLE_ICON[role]); tex:SetWidth(36); tex:SetHeight(36); tex:SetPoint("TOPLEFT", 15, -14)
    local name = Text(card, D.ROLE_LABEL[role], "GameFontNormal", color); name:SetPoint("TOPLEFT", 60, -15)
    local count = Text(card, "0", "GameFontNormalLarge", C.text); count:SetPoint("TOPLEFT", 60, -36)
    local minus = Button(card, "-", 34, 24, function() SetRoleCount(role, -1) end); minus:SetPoint("TOPRIGHT", -78, -18)
    local plus = Button(card, "+", 34, 24, function() SetRoleCount(role, 1) end); plus:SetPoint("TOPRIGHT", -38, -18)
    local pref = Text(card, "", "GameFontHighlightSmall", C.muted); pref:SetPoint("BOTTOMLEFT", 15, prefMode and 54 or 13)
    card.count, card.pref = count, pref
    card.classButtons = {}
    if prefMode then
        local idx = 0
        for _, token in ipairs(D.CLASS_ORDER) do
            if D.CLASS_ROLE[role] and D.CLASS_ROLE[role][token] then
                idx = idx + 1
                local b = Button(card, string.sub(D.CLASS_LABEL[token] or token, 1, 4), 52, 22, function() ToggleClassPreference(role, token) end)
                b:SetPoint("BOTTOMLEFT", 14 + ((idx - 1) % 5) * 58, 15 + math.floor((idx - 1) / 5) * 25)
                b.token = token; card.classButtons[#card.classButtons + 1] = b
            end
        end
    end
    function card:Refresh()
        local c = GC:GetConfig(); local value = role == "TANK" and c.tanks or role == "HEALER" and c.healers or c.dps
        self.count:SetText(tostring(value)); self.pref:SetText(PreferenceLabel(role))
        local active = c.preferences[role] and c.preferences[role][1] and c.preferences[role][1].class
        for _, b in ipairs(self.classButtons) do b:SetAccent(color, b.token == active) end
    end
    return card
end

local function OptionsPanel(parent, y)
    local p = Panel(parent); p:SetPoint("TOPLEFT", 0, y); p:SetPoint("TOPRIGHT", 0, y); p:SetHeight(72)
    local titleText = Text(p, "ROSTER RULES", "GameFontNormal", C.text); titleText:SetPoint("TOPLEFT", 14, -10)
    local guild = Check(p, "Prefer Guild Members", "preferGuild", 12, -34)
    local world = Check(p, "Fill missing roles with World Bots", "fillWorld", 250, -34)
    local classes = Check(p, "Balance class / utility coverage", "balanceClasses", 540, -34)
    local dup = Check(p, "Avoid duplicate classes when practical", "avoidDuplicateClasses", 820, -34)
    p.checks = { guild, world, classes, dup }
    function p:Refresh()
        local o = GC:GetConfig().options
        for _, cb in ipairs(self.checks) do cb:SetChecked(o[cb.key] and true or false) end
    end
    return p
end

-- Dungeon page ----------------------------------------------------------------
local dTitle = Text(dungeonPage, "Dungeon Group Setup", "GameFontNormalLarge", C.text); dTitle:SetPoint("TOPLEFT", 8, -2)
local dSub = Text(dungeonPage, "All named WotLK 5-player dungeons supported by the Dungeon Clear routing layer.", "GameFontHighlightSmall", C.muted); dSub:SetPoint("TOPLEFT", dTitle, "BOTTOMLEFT", 0, -3)
local dConfig = Panel(dungeonPage); dConfig:SetPoint("TOPLEFT", 0, -50); dConfig:SetPoint("TOPRIGHT", -360, -50); dConfig:SetHeight(92)
local dLab1 = Text(dConfig, "DUNGEON", "GameFontNormalSmall", C.muted); dLab1:SetPoint("TOPLEFT", 16, -12)
local dungeonSelector = Selector(dConfig, 390, DungeonItems, function() return GC:GetConfig().activity end, function(value) GC:SetDungeonActivity(value) end); dungeonSelector:SetPoint("TOPLEFT", 12, -36)
local dLab2 = Text(dConfig, "DIFFICULTY", "GameFontNormalSmall", C.muted); dLab2:SetPoint("TOPLEFT", 430, -12)
local dungeonDifficulty = Selector(dConfig, 250, function() return DifficultyItems(D.DUNGEON_DIFFICULTIES) end, function() return GC:GetConfig().difficulty end, function(value) GC:GetConfig().difficulty = value; GC:Touch("Difficulty changed") end); dungeonDifficulty:SetPoint("TOPLEFT", 426, -36)
local routeBadge = Text(dConfig, "Dungeon Clear: supported", "GameFontHighlightSmall", C.green); routeBadge:SetPoint("TOPRIGHT", -18, -51)

local dRoles = Panel(dungeonPage); dRoles:SetPoint("TOPLEFT", 0, -154); dRoles:SetPoint("TOPRIGHT", -360, -154); dRoles:SetHeight(176)
local dRolesTitle = Text(dRoles, "PARTY COMPOSITION", "GameFontNormal", C.text); dRolesTitle:SetPoint("TOPLEFT", 14, -10)
local dTank = RoleCard(dRoles, "TANK", 12, -36, 288, false)
local dHeal = RoleCard(dRoles, "HEALER", 310, -36, 288, false)
local dDps = RoleCard(dRoles, "DPS", 608, -36, 288, false)
local dOptions = OptionsPanel(dungeonPage, -342); dOptions:SetPoint("TOPRIGHT", -360, -342)

local dPrefs = Panel(dungeonPage); dPrefs:SetPoint("TOPLEFT", 0, -426); dPrefs:SetPoint("BOTTOMRIGHT", -360, 0)
local dPrefTitle = Text(dPrefs, "CLASS PREFERENCES", "GameFontNormal", C.text); dPrefTitle:SetPoint("TOPLEFT", 14, -10)
local dPrefHint = Text(dPrefs, "Click a class to prefer it. Click it again for Any. Composer may retask a compatible hybrid into the missing role with the correct role spec and gear.", "GameFontHighlightSmall", C.muted); dPrefHint:SetPoint("TOPLEFT", 14, -30); dPrefHint:SetWidth(880); dPrefHint:SetJustifyH("LEFT")
local dpTank = RoleCard(dPrefs, "TANK", 12, -62, 288, true)
local dpHeal = RoleCard(dPrefs, "HEALER", 310, -62, 288, true)
local dpDps = RoleCard(dPrefs, "DPS", 608, -62, 288, true)

local dPreview = Panel(dungeonPage); dPreview:SetPoint("TOPRIGHT", 0, -50); dPreview:SetPoint("BOTTOMRIGHT", 0, 0); dPreview:SetWidth(344)
local dPrevTitle = Text(dPreview, "PARTY PREVIEW", "GameFontNormal", C.text); dPrevTitle:SetPoint("TOPLEFT", 14, -14)
local dPrevState = Text(dPreview, "Not searched", "GameFontHighlightSmall", C.gold); dPrevState:SetPoint("TOPRIGHT", -14, -16)
local dSummary = Text(dPreview, "0 / 5", "GameFontNormalLarge", C.text); dSummary:SetPoint("TOPLEFT", 14, -45)
local dWarnings = Text(dPreview, "Find Roster to build a deterministic preview.", "GameFontHighlightSmall", C.muted); dWarnings:SetPoint("TOPLEFT", 14, -78); dWarnings:SetWidth(314); dWarnings:SetJustifyH("LEFT"); dWarnings:SetJustifyV("TOP")
local dRows = {}
for i = 1, 5 do
    local row = Panel(dPreview); row:SetPoint("TOPLEFT", 12, -178 - ((i - 1) * 54)); row:SetWidth(320); row:SetHeight(46)
    local rt = Text(row, "Empty Slot", "GameFontHighlight", C.dim); rt:SetPoint("LEFT", 12, 6)
    local rd = Text(row, "Waiting for roster", "GameFontHighlightSmall", C.dim); rd:SetPoint("LEFT", 12, -10)
    row.nameText, row.detailText = rt, rd; dRows[i] = row
end
local dFind = Button(dPreview, "Find Roster", 146, 34, function() GC:FindRoster() end); dFind:SetPoint("BOTTOMLEFT", 12, 14); dFind:SetAccent(C.blue, true)
local dAssemble = Button(dPreview, "Assemble Party", 146, 34, function() GC:Assemble() end); dAssemble:SetPoint("BOTTOMRIGHT", -12, 14); dAssemble:SetAccent(C.green, true)

-- Raid page -------------------------------------------------------------------
local rTitle = Text(raidPage, "Raid Setup", "GameFontNormalLarge", C.text); rTitle:SetPoint("TOPLEFT", 8, -2)
local rSub = Text(raidPage, "Validated-ready raids only. Partial/Not Ready encounters stay hidden from the normal picker.", "GameFontHighlightSmall", C.muted); rSub:SetPoint("TOPLEFT", rTitle, "BOTTOMLEFT", 0, -3)
local rPicker = Panel(raidPage); rPicker:SetPoint("TOPLEFT", 0, -50); rPicker:SetPoint("TOPRIGHT", 0, -50); rPicker:SetHeight(108)
local raidButtons = {}
for i, raid in ipairs(ReadyRaidObjects()) do
    local b = Button(rPicker, raid.label, 172, 35, function() GC:SetRaidActivity(raid.id) end)
    b:SetPoint("TOPLEFT", 12 + ((i - 1) % 7) * 184, -18)
    b.raidId = raid.id; raidButtons[#raidButtons + 1] = b
end
local readyText = Text(rPicker, "READY: encounter knowledge + bot strategy coverage", "GameFontHighlightSmall", C.green); readyText:SetPoint("BOTTOMLEFT", 14, 12)

local rControls = Panel(raidPage); rControls:SetPoint("TOPLEFT", 0, -170); rControls:SetPoint("TOPRIGHT", 0, -170); rControls:SetHeight(72)
local sizeLabel = Text(rControls, "RAID SIZE", "GameFontNormalSmall", C.muted); sizeLabel:SetPoint("TOPLEFT", 14, -10)
local sizeButtons = {}
for i, size in ipairs({10,20,25,40}) do
    local b = Button(rControls, tostring(size) .. "-player", 98, 28, function() GC:SetRaidSize(size) end); b:SetPoint("TOPLEFT", 12 + ((i - 1) * 106), -34); b.sizeValue = size; sizeButtons[#sizeButtons + 1] = b
end
local raidDiffLabel = Text(rControls, "DIFFICULTY", "GameFontNormalSmall", C.muted); raidDiffLabel:SetPoint("TOPLEFT", 466, -10)
local raidDifficulty = Selector(rControls, 190, function() return DifficultyItems(D.RAID_DIFFICULTIES) end, function() return GC:GetConfig().difficulty end, function(value) GC:GetConfig().difficulty = value; GC:Touch("Difficulty changed") end); raidDifficulty:SetPoint("TOPLEFT", 462, -34)
local rRoleSummary = Text(rControls, "", "GameFontHighlight", C.text); rRoleSummary:SetPoint("RIGHT", -18, -2)

local rRoles = Panel(raidPage); rRoles:SetPoint("TOPLEFT", 0, -254); rRoles:SetPoint("TOPRIGHT", 0, -254); rRoles:SetHeight(182)
local rrTitle = Text(rRoles, "ROLE & CLASS PREFERENCES", "GameFontNormal", C.text); rrTitle:SetPoint("TOPLEFT", 14, -10)
local rTank = RoleCard(rRoles, "TANK", 12, -36, 416, true)
local rHeal = RoleCard(rRoles, "HEALER", 440, -36, 416, true)
local rDps = RoleCard(rRoles, "DPS", 868, -36, 416, true)

local rOptions = OptionsPanel(raidPage, -448)
local rAction = Panel(raidPage); rAction:SetPoint("TOPLEFT", 0, -532); rAction:SetPoint("TOPRIGHT", 0, -532); rAction:SetHeight(56)
local rActionText = Text(rAction, "Preview first. Assembly applies role-specific talents, strategies and gear before bots join.", "GameFontHighlightSmall", C.muted); rActionText:SetPoint("LEFT", 14, 0)
local rFind = Button(rAction, "Find Roster", 145, 34, function() GC:FindRoster() end); rFind:SetPoint("RIGHT", -170, 0); rFind:SetAccent(C.blue, true)
local rAssemble = Button(rAction, "Assemble Raid", 145, 34, function() GC:Assemble() end); rAssemble:SetPoint("RIGHT", -14, 0); rAssemble:SetAccent(C.green, true)

local groupsArea = CreateFrame("Frame", nil, raidPage); groupsArea:SetPoint("TOPLEFT", 0, -600); groupsArea:SetPoint("BOTTOMRIGHT", 0, 0)
local groupCards = {}
for g = 1, 8 do
    local card = Panel(groupsArea); card:SetWidth(314); card:SetHeight(86)
    local col, row = (g - 1) % 4, math.floor((g - 1) / 4)
    card:SetPoint("TOPLEFT", col * 326, -row * 94)
    local gt = Text(card, "Group " .. g, "GameFontNormal", C.text); gt:SetPoint("TOPLEFT", 9, -7)
    local rows = {}
    for i = 1, 5 do
        local rt = Text(card, "-", "GameFontHighlightSmall", C.dim); rt:SetPoint("TOPLEFT", 10 + ((i - 1) % 3) * 100, -28 - math.floor((i - 1) / 3) * 20); rt:SetWidth(95); rt:SetJustifyH("LEFT"); rows[i] = rt
    end
    card.rows = rows; groupCards[g] = card
end

local function WarningText(plan)
    local seen, lines = {}, {}
    for _, warning in ipairs((plan and plan.warnings) or {}) do
        if warning and not seen[warning] then seen[warning] = true; lines[#lines + 1] = "- " .. warning end
        if #lines >= 4 then break end
    end
    return #lines > 0 and table.concat(lines, "\n") or "No warnings."
end

local function RefreshDungeonPreview()
    local plan = GC.plan or { members = {}, warnings = {} }
    dPrevState:SetText(plan.ready and (plan.valid and "READY" or "NEEDS ATTENTION") or "Not searched")
    dPrevState:SetTextColor(plan.ready and plan.valid and C.green[1] or C.gold[1], plan.ready and plan.valid and C.green[2] or C.gold[2], plan.ready and plan.valid and C.green[3] or C.gold[3], 1)
    dSummary:SetText(tostring(#(plan.members or {})) .. " / 5")
    dWarnings:SetText(WarningText(plan))
    for i, row in ipairs(dRows) do
        local m = plan.members and plan.members[i]
        if m then
            local color = ROLE_COLOR[m.role] or C.text
            row.nameText:SetText((m.role == "TANK" and "[T] " or m.role == "HEALER" and "[H] " or "[D] ") .. (m.name or "?")); row.nameText:SetTextColor(color[1], color[2], color[3], 1)
            row.detailText:SetText((D.CLASS_LABEL[m.class] or m.class or "?") .. " - " .. tostring(m.spec or "Any") .. " - " .. tostring(m.source or "WORLD")); row.detailText:SetTextColor(C.muted[1], C.muted[2], C.muted[3], 1)
        else row.nameText:SetText("Empty Slot"); row.nameText:SetTextColor(C.dim[1], C.dim[2], C.dim[3], 1); row.detailText:SetText("Waiting for roster") end
    end
    if plan.ready and plan.valid then dAssemble:Enable(); dAssemble:SetAlpha(1) else dAssemble:Disable(); dAssemble:SetAlpha(0.42) end
end

local function RefreshRaidGroups()
    local plan, c = GC.plan or { members = {} }, GC:GetConfig()
    local count = math.min(8, math.ceil((tonumber(c.size) or 25) / 5))
    for g, card in ipairs(groupCards) do
        if g <= count then card:Show() else card:Hide() end
        for i, rt in ipairs(card.rows) do rt:SetText("-"); rt:SetTextColor(C.dim[1], C.dim[2], C.dim[3], 1) end
    end
    local perGroup = {}
    for _, m in ipairs(plan.members or {}) do
        local g = tonumber(m.subgroup) or 1; perGroup[g] = perGroup[g] or {}; perGroup[g][#perGroup[g] + 1] = m
    end
    for g, members in pairs(perGroup) do
        if groupCards[g] then
            for i, m in ipairs(members) do
                if i <= 5 and groupCards[g].rows[i] then
                    local color = ROLE_COLOR[m.role] or C.text
                    groupCards[g].rows[i]:SetText((m.role == "TANK" and "T " or m.role == "HEALER" and "H " or "D ") .. (m.name or "?")); groupCards[g].rows[i]:SetTextColor(color[1], color[2], color[3], 1)
                end
            end
        end
    end
    if plan.ready and plan.valid then rAssemble:Enable(); rAssemble:SetAlpha(1) else rAssemble:Disable(); rAssemble:SetAlpha(0.42) end
end

function U:ApplyScale()
    local w, h = UIParent:GetWidth() or 1920, UIParent:GetHeight() or 1080
    local scale = math.min((w - 30) / 1320, (h - 40) / 820)
    scale = math.max(0.72, math.min(1.15, scale))
    frame:SetScale(scale)
end

function U:Refresh()
    if not frame:IsShown() then return end
    local c = GC:GetConfig(); local raidMode = c.mode == "RAID"
    if raidMode then dungeonPage:Hide(); raidPage:Show() else raidPage:Hide(); dungeonPage:Show() end
    dungeonTab:SetAccent(C.blue, not raidMode); raidTab:SetAccent(C.gold, raidMode)
    backendText:SetText(GC.backendSeen and "Backend: connected" or "Backend: waiting...")
    dungeonSelector:Refresh(); dungeonDifficulty:Refresh(); raidDifficulty:Refresh()
    dTank:Refresh(); dHeal:Refresh(); dDps:Refresh(); dpTank:Refresh(); dpHeal:Refresh(); dpDps:Refresh(); dOptions:Refresh()
    rTank:Refresh(); rHeal:Refresh(); rDps:Refresh(); rOptions:Refresh()
    for _, b in ipairs(raidButtons) do b:SetAccent(C.gold, b.raidId == c.activity) end
    local selectedRaid = D.GetRaidById(c.activity)
    for _, b in ipairs(sizeButtons) do
        local supported = false
        if selectedRaid then for _, size in ipairs(selectedRaid.sizes or {}) do if size == b.sizeValue then supported = true end end end
        if supported then b:Enable(); b:SetAlpha(1); b:SetAccent(C.gold, c.size == b.sizeValue) else b:Disable(); b:SetAlpha(0.28); b:SetAccent(C.gold, false) end
    end
    rRoleSummary:SetText(tostring(c.tanks) .. " Tank   /   " .. tostring(c.healers) .. " Healer   /   " .. tostring(c.dps) .. " DPS")
    RefreshDungeonPreview(); RefreshRaidGroups()
end

function U:Show()
    if not GC.db then return end
    CloseMenu(); U:ApplyScale(); frame:Show(); U:Refresh(); GC:RequestStatus()
end
function U:Toggle() if frame:IsShown() then frame:Hide(); CloseMenu() else U:Show() end end

-- Dashboard becomes the public /gc shell. The older UI remains loaded underneath for compatibility,
-- while Roster Editor keeps the advanced human/pin/subgroup tools.
GC.Toggle = function() U:Toggle() end

GC:RegisterCallback("CONFIG_CHANGED", function() U:Refresh() end)
GC:RegisterCallback("PLAN_CHANGED", function() U:Refresh() end)
GC:RegisterCallback("STATUS", function(text) statusText:SetText(tostring(text or "Ready.")); U:Refresh() end)
GC:RegisterCallback("DISPLAY_CHANGED", function() U:ApplyScale() end)

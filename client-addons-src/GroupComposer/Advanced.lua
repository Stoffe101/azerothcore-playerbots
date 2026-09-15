local GC = GroupComposer
local D = GroupComposerData
local UI = GC.UI

-- The main composer stays intentionally focused on the common path. This editor owns the
-- less-frequent but powerful controls: human role overrides, manual humans, familiar guild
-- pins, deterministic subgroup placement and diagnostics.
local A = {}
GC.Advanced = A

local C = {
    bg = { 0.024, 0.030, 0.042, 0.99 },
    header = { 0.037, 0.045, 0.062, 1 },
    panel = { 0.050, 0.060, 0.080, 0.98 },
    panel2 = { 0.065, 0.076, 0.100, 0.98 },
    line = { 0.16, 0.20, 0.28, 0.95 },
    blue = { 0.22, 0.58, 0.95, 1 },
    green = { 0.24, 0.82, 0.46, 1 },
    red = { 0.94, 0.28, 0.30, 1 },
    gold = { 1.00, 0.69, 0.20, 1 },
    text = { 0.93, 0.95, 0.99, 1 },
    muted = { 0.62, 0.68, 0.78, 1 },
    dim = { 0.43, 0.48, 0.57, 1 },
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
    b:SetWidth(width or 100); b:SetHeight(height or 24); b:SetText(label or "Button")
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
    cb:SetWidth(24); cb:SetHeight(24); cb:SetChecked(checked and true or false)
    local txt = Text(cb, label, "GameFontHighlightSmall", C.text)
    txt:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    cb.label = txt
    cb:SetScript("OnClick", function(self) if fn then fn(self:GetChecked() and true or false) end end)
    return cb
end

local function Dropdown(parent, width, itemsFn, valueFn, setFn)
    local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dd, width or 130)
    UIDropDownMenu_JustifyText(dd, "LEFT")
    dd.itemsFn, dd.valueFn, dd.setFn = itemsFn, valueFn, setFn
    UIDropDownMenu_Initialize(dd, function(frame, level)
        local current = frame.valueFn and frame.valueFn() or nil
        for _, item in ipairs(frame.itemsFn and frame.itemsFn() or {}) do
            local value = item.value
            local disabled = item.disabled and true or false
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.label
            info.value = value
            info.checked = current == value
            info.disabled = disabled
            info.func = function()
                if not disabled and frame.setFn then frame.setFn(value) end
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    function dd:Refresh()
        local current = self.valueFn and self.valueFn() or nil
        local label = tostring(current or "Select")
        for _, item in ipairs(self.itemsFn and self.itemsFn() or {}) do
            if item.value == current then label = item.label break end
        end
        UIDropDownMenu_SetText(self, label)
    end
    dd:Refresh()
    return dd
end

local function RoleItems(includeAuto)
    local out = {}
    if includeAuto then out[#out + 1] = { value = "AUTO", label = "Auto-detect" } end
    out[#out + 1] = { value = "TANK", label = "Tank" }
    out[#out + 1] = { value = "HEALER", label = "Healer" }
    out[#out + 1] = { value = "DPS", label = "DPS" }
    return out
end

local frame = CreateFrame("Frame", "GroupComposerRosterEditor", UIParent)
A.frame = frame
frame:SetWidth(1060); frame:SetHeight(690); frame:SetFrameStrata("FULLSCREEN_DIALOG")
frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton"); frame:SetClampedToScreen(true)
frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
frame:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], C.bg[4])
frame:Hide()
frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if not GC.db then return end
    local p, rel, rp, x, y = self:GetPoint(1)
    GC.db.window.advancedPoint = { p, rel and rel:GetName() or "UIParent", rp, x, y }
end)

local headerBg = Solid(frame, "BACKGROUND", C.header); headerBg:SetPoint("TOPLEFT", 5, -5); headerBg:SetPoint("TOPRIGHT", -5, -5); headerBg:SetHeight(66)
local title = Text(frame, "ROSTER EDITOR", "GameFontNormalLarge", C.text); title:SetPoint("TOPLEFT", 22, -17)
local subtitle = Text(frame, "Humans, familiar guild members, subgroup placement and diagnostics", "GameFontHighlightSmall", C.muted); subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -8, -8)

A.pages, A.tabs = {}, {}
local pageHost = CreateFrame("Frame", nil, frame); pageHost:SetPoint("TOPLEFT", 10, -111); pageHost:SetPoint("BOTTOMRIGHT", -10, 48)
local function Page(name)
    local p = CreateFrame("Frame", nil, pageHost); p:SetAllPoints(pageHost); p:Hide(); A.pages[name] = p; return p
end
local function SelectPage(name)
    if not A.pages[name] then return end
    for n, page in pairs(A.pages) do if n == name then page:Show() else page:Hide() end end
    for n, button in pairs(A.tabs) do if n == name then button:LockHighlight() else button:UnlockHighlight() end end
    if GC.db then GC.db.window.advancedTab = name end
    if name == "PEOPLE" then A:RefreshPeople() elseif name == "LAYOUT" then A:RefreshLayout() else A:RefreshDiagnostics() end
end

local tabNames = { { "PEOPLE", "People & Pins" }, { "LAYOUT", "Group Layout" }, { "DIAGNOSTICS", "Diagnostics" } }
for i, def in ipairs(tabNames) do
    local key = def[1]
    local b = Button(frame, def[2], 130, 28, function() SelectPage(key) end)
    b:SetPoint("TOPLEFT", 20 + (i - 1) * 138, -77)
    A.tabs[key] = b
end

local queueButton = Button(frame, "Queue Dungeon Finder", 154, 28, function() GC:QueueDungeon() end,
    "After the composed 5-player party is assembled, hand supported Normal/Heroic dungeons to the stock 3.3.5a Dungeon Finder.")
queueButton:SetPoint("TOPRIGHT", -20, -77)
A.queueButton = queueButton

-- PEOPLE & PINS --------------------------------------------------------------
local people = Page("PEOPLE")
local peopleScroll = CreateFrame("ScrollFrame", "GroupComposerPeopleScroll", people, "UIPanelScrollFrameTemplate")
peopleScroll:SetPoint("TOPLEFT", 0, 0); peopleScroll:SetPoint("BOTTOMRIGHT", -27, 0); peopleScroll:EnableMouseWheel(true)
peopleScroll:SetScript("OnMouseWheel", function(self, delta)
    local current, range = self:GetVerticalScroll(), self:GetVerticalScrollRange()
    self:SetVerticalScroll(math.max(0, math.min(range, current - delta * 40)))
end)
local peopleContent = CreateFrame("Frame", nil, peopleScroll); peopleContent:SetWidth(995); peopleContent:SetHeight(760); peopleScroll:SetScrollChild(peopleContent)
A.peopleContent = peopleContent
A.peopleRows = {}

local peopleTitle = Text(peopleContent, "Human roster anchors", "GameFontNormalLarge", C.text); peopleTitle:SetPoint("TOPLEFT", 10, -8)
local peopleHint = Text(peopleContent, "Everyone already grouped with you remains locked. Override a role only when auto-detection is wrong or ambiguous.", "GameFontHighlightSmall", C.muted)
peopleHint:SetPoint("TOPLEFT", peopleTitle, "BOTTOMLEFT", 0, -4); peopleHint:SetWidth(950); peopleHint:SetJustifyH("LEFT")
local humanArea = CreateFrame("Frame", nil, peopleContent); humanArea:SetPoint("TOPLEFT", 10, -58); humanArea:SetWidth(475); humanArea:SetHeight(245)
local humanBg = Solid(humanArea, "BACKGROUND", C.panel); humanBg:SetAllPoints(humanArea)
local humanHeader = Text(humanArea, "CURRENT HUMANS", "GameFontNormalSmall", C.gold); humanHeader:SetPoint("TOPLEFT", 12, -12)
A.humanArea = humanArea

local addArea = CreateFrame("Frame", nil, peopleContent); addArea:SetPoint("TOPLEFT", 500, -58); addArea:SetWidth(485); addArea:SetHeight(245)
local addBg = Solid(addArea, "BACKGROUND", C.panel); addBg:SetAllPoints(addArea)
local addHeader = Text(addArea, "ADD ONLINE HUMAN", "GameFontNormalSmall", C.blue); addHeader:SetPoint("TOPLEFT", 12, -12)
local addDesc = Text(addArea, "Optional real player who is not grouped yet. They are invited normally during Assemble and never treated as a bot candidate.", "GameFontHighlightSmall", C.muted)
addDesc:SetPoint("TOPLEFT", 12, -34); addDesc:SetWidth(455); addDesc:SetJustifyH("LEFT")
local humanName = CreateFrame("EditBox", nil, addArea, "InputBoxTemplate"); humanName:SetWidth(180); humanName:SetHeight(24); humanName:SetAutoFocus(false); humanName:SetMaxLetters(24); humanName:SetPoint("TOPLEFT", 16, -82)
humanName:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
local addRole = "DPS"
local humanRoleDD = Dropdown(addArea, 120, function() return RoleItems(false) end, function() return addRole end, function(v) addRole = v; humanRoleDD:Refresh() end)
humanRoleDD:SetPoint("LEFT", humanName, "RIGHT", -4, -2)
local addHumanBtn = Button(addArea, "Add", 72, 24, function()
    if GC:AddExtraHuman(humanName:GetText(), addRole) then humanName:SetText("") else GC:Fire("STATUS", "Enter a valid online character name and role.") end
end)
addHumanBtn:SetPoint("LEFT", humanRoleDD, "RIGHT", -2, 2)
A.extraArea = CreateFrame("Frame", nil, addArea); A.extraArea:SetPoint("TOPLEFT", 12, -122); A.extraArea:SetPoint("BOTTOMRIGHT", -12, 10)

local pinTitle = Text(peopleContent, "Persistent guild companions", "GameFontNormalLarge", C.text); pinTitle:SetPoint("TOPLEFT", 10, -322)
local pinHint = Text(peopleContent, "Pin familiar Playerbots by name. Preferred pins fall back gracefully; Required pins block the roster if that bot is unavailable.", "GameFontHighlightSmall", C.muted)
pinHint:SetPoint("TOPLEFT", pinTitle, "BOTTOMLEFT", 0, -4); pinHint:SetWidth(950); pinHint:SetJustifyH("LEFT")
local pinArea = CreateFrame("Frame", nil, peopleContent); pinArea:SetPoint("TOPLEFT", 10, -372); pinArea:SetWidth(975); pinArea:SetHeight(248)
local pinBg = Solid(pinArea, "BACKGROUND", C.panel); pinBg:SetAllPoints(pinArea)
local pinName = CreateFrame("EditBox", nil, pinArea, "InputBoxTemplate"); pinName:SetWidth(180); pinName:SetHeight(24); pinName:SetAutoFocus(false); pinName:SetMaxLetters(24); pinName:SetPoint("TOPLEFT", 16, -18)
pinName:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
local pinRole = "DPS"
local pinRoleDD = Dropdown(pinArea, 120, function() return RoleItems(false) end, function() return pinRole end, function(v) pinRole = v; pinRoleDD:Refresh() end)
pinRoleDD:SetPoint("LEFT", pinName, "RIGHT", -4, -2)
local pinRequired = false
local pinReq = Checkbox(pinArea, "Required", false, function(v) pinRequired = v end); pinReq:SetPoint("LEFT", pinRoleDD, "RIGHT", 0, 1)
local pinAdd = Button(pinArea, "Pin Member", 104, 24, function()
    if GC:AddPinnedMember(pinName:GetText(), pinRole, pinRequired) then pinName:SetText("") else GC:Fire("STATUS", "Enter a valid Playerbot name and role.") end
end)
pinAdd:SetPoint("LEFT", pinReq, "RIGHT", 76, 0)
A.pinListArea = CreateFrame("Frame", nil, pinArea); A.pinListArea:SetPoint("TOPLEFT", 12, -60); A.pinListArea:SetPoint("BOTTOMRIGHT", -12, 10)

local optimize = CreateFrame("Frame", nil, peopleContent); optimize:SetPoint("TOPLEFT", 10, -636); optimize:SetWidth(975); optimize:SetHeight(108)
local optBg = Solid(optimize, "BACKGROUND", C.panel2); optBg:SetAllPoints(optimize)
local optTitle = Text(optimize, "SECONDARY OPTIMIZATION", "GameFontNormalSmall", C.text); optTitle:SetPoint("TOPLEFT", 12, -10)
local utilityCb = Checkbox(optimize, "Balance useful raid utility", true, function(v) GC:GetConfig().options.balanceUtility = v; GC:Touch("Utility rule changed") end); utilityCb:SetPoint("TOPLEFT", 12, -38)
local rangeCb = Checkbox(optimize, "Balance melee / ranged DPS", true, function(v) GC:GetConfig().options.balanceRange = v; GC:Touch("Range rule changed") end); rangeCb:SetPoint("TOPLEFT", 284, -38)
local guildCb = Checkbox(optimize, "Prefer persistent guild members", true, function(v) GC:GetConfig().options.preferGuild = v; GC:Touch("Guild preference changed") end); guildCb:SetPoint("TOPLEFT", 568, -38)
local worldCb = Checkbox(optimize, "Allow world-bot fallback", true, function(v) GC:GetConfig().options.fillWorld = v; GC:Touch("World fallback changed") end); worldCb:SetPoint("TOPLEFT", 12, -72)
local queueCb = Checkbox(optimize, "Queue supported dungeon automatically after assembly", false, function(v) GC:GetConfig().options.queueAfterAssemble = v; GC:Touch("Queue option changed") end); queueCb:SetPoint("TOPLEFT", 284, -72)
A.optimizationChecks = { utility = utilityCb, range = rangeCb, guild = guildCb, world = worldCb, queue = queueCb }
peopleContent:SetHeight(760)

local function ClearRows(list)
    for _, row in ipairs(list or {}) do row:Hide(); row:SetParent(nil) end
    return {}
end

function A:RefreshPeople()
    if not GC.db or not self.humanArea then return end
    self.peopleRows = ClearRows(self.peopleRows)
    local c = GC:GetConfig()
    local humans = GC:ScanHumans()
    local y = -38
    if #humans == 0 then
        local t = Text(humanArea, "No real players detected.", "GameFontHighlightSmall", C.dim); t:SetPoint("TOPLEFT", 12, y)
        local holder = CreateFrame("Frame", nil, humanArea); holder.text = t; holder:SetScript("OnHide", function(s) if s.text then s.text:Hide() end end); self.peopleRows[#self.peopleRows + 1] = holder
    else
        for _, h in ipairs(humans) do
            local human = h
            local row = CreateFrame("Frame", nil, humanArea); row:SetWidth(450); row:SetHeight(34); row:SetPoint("TOPLEFT", 10, y)
            local bg = Solid(row, "BACKGROUND", C.panel2, 0.85); bg:SetAllPoints(row)
            local className = D.CLASS_LABEL[human.class] or human.class or "Unknown"
            local name = Text(row, human.name, "GameFontHighlightSmall", human.isPlayer and C.gold or C.text); name:SetPoint("LEFT", 8, 0); name:SetWidth(112); name:SetJustifyH("LEFT")
            local cls = Text(row, className, "GameFontHighlightSmall", C.muted); cls:SetPoint("LEFT", 126, 0); cls:SetWidth(104); cls:SetJustifyH("LEFT")
            local dd
            dd = Dropdown(row, 112, function() return RoleItems(true) end,
                function() return c.humanRoles[human.name] or "AUTO" end,
                function(v) GC:SetHumanRole(human.name, v); dd:Refresh() end)
            dd:SetPoint("RIGHT", 12, -2)
            self.peopleRows[#self.peopleRows + 1] = row
            y = y - 38
        end
    end

    -- Manual human invitations.
    A.extraRows = ClearRows(A.extraRows or {})
    local ey = 0
    if #c.extraHumans == 0 then
        local t = Text(A.extraArea, "No additional humans selected.", "GameFontHighlightSmall", C.dim); t:SetPoint("TOPLEFT", 2, -2)
        local holder = CreateFrame("Frame", nil, A.extraArea); holder.text = t; holder:SetScript("OnHide", function(s) if s.text then s.text:Hide() end end); A.extraRows[#A.extraRows + 1] = holder
    else
        for i, entry in ipairs(c.extraHumans) do
            local index = i
            local row = CreateFrame("Frame", nil, A.extraArea); row:SetHeight(30); row:SetPoint("TOPLEFT", 0, -ey); row:SetPoint("RIGHT", 0, 0)
            local label = Text(row, entry.name .. "  •  " .. (D.ROLE_LABEL[entry.role] or entry.role), "GameFontHighlightSmall", C.text); label:SetPoint("LEFT", 4, 0)
            local del = Button(row, "Remove", 66, 22, function() GC:RemoveExtraHuman(index) end); del:SetPoint("RIGHT", -2, 0)
            A.extraRows[#A.extraRows + 1] = row; ey = ey + 32
        end
    end

    A.pinRows = ClearRows(A.pinRows or {})
    local py = -66
    if #c.pinned == 0 then
        local t = Text(pinArea, "No persistent guild members pinned. Your normal guild-first selection still applies.", "GameFontHighlightSmall", C.dim); t:SetPoint("TOPLEFT", 16, py)
        local holder = CreateFrame("Frame", nil, pinArea); holder.text = t; holder:SetScript("OnHide", function(s) if s.text then s.text:Hide() end end); A.pinRows[#A.pinRows + 1] = holder
    else
        for i, entry in ipairs(c.pinned) do
            local index, pin = i, entry
            local row = CreateFrame("Frame", nil, pinArea); row:SetWidth(930); row:SetHeight(32); row:SetPoint("TOPLEFT", 14, py)
            local bg = Solid(row, "BACKGROUND", C.panel2, 0.82); bg:SetAllPoints(row)
            local name = Text(row, pin.name, "GameFontHighlightSmall", C.gold); name:SetPoint("LEFT", 8, 0); name:SetWidth(160); name:SetJustifyH("LEFT")
            local role = Text(row, D.ROLE_LABEL[pin.role] or pin.role, "GameFontHighlightSmall", ROLE_COLOR[pin.role] or C.text); role:SetPoint("LEFT", 176, 0); role:SetWidth(90); role:SetJustifyH("LEFT")
            local req
            req = Checkbox(row, "Required", pin.required, function(v) pin.required = v; GC:Touch("Pinned member changed") end); req:SetPoint("LEFT", 282, 0)
            local del = Button(row, "Unpin", 66, 22, function() GC:RemovePinnedMember(index) end); del:SetPoint("RIGHT", -6, 0)
            A.pinRows[#A.pinRows + 1] = row; py = py - 36
        end
    end

    utilityCb:SetChecked(c.options.balanceUtility and true or false)
    rangeCb:SetChecked(c.options.balanceRange and true or false)
    guildCb:SetChecked(c.options.preferGuild and true or false)
    worldCb:SetChecked(c.options.fillWorld and true or false)
    queueCb:SetChecked(c.options.queueAfterAssemble and true or false)
end

-- GROUP LAYOUT ---------------------------------------------------------------
local layout = Page("LAYOUT")
local layoutTitle = Text(layout, "Raid subgroup editor", "GameFontNormalLarge", C.text); layoutTitle:SetPoint("TOPLEFT", 10, -8)
local layoutHint = Text(layout, "Auto Arrange establishes a sane baseline. Drag a member onto another group, or use the arrow buttons. A move into a full group swaps members instead of dropping anyone.", "GameFontHighlightSmall", C.muted)
layoutHint:SetPoint("TOPLEFT", layoutTitle, "BOTTOMLEFT", 0, -4); layoutHint:SetWidth(985); layoutHint:SetJustifyH("LEFT")
local layoutArea = CreateFrame("Frame", nil, layout); layoutArea:SetPoint("TOPLEFT", 6, -58); layoutArea:SetPoint("BOTTOMRIGHT", -6, 6)
A.layoutArea = layoutArea; A.layoutRows = {}; A.groupCards = {}

local function FindDropGroup(frameUnderMouse)
    local node = frameUnderMouse
    for _ = 1, 7 do
        if not node then return nil end
        if node.groupIndex then return node.groupIndex end
        node = node:GetParent()
    end
end

local function IsStable(config, member)
    if member.human then return true end
    local key = string.lower(member.name or "")
    for _, pin in ipairs(config.pinned or {}) do if string.lower(pin.name) == key then return true end end
    return false
end

function A:RefreshLayout()
    self.layoutRows = ClearRows(self.layoutRows)
    self.groupCards = ClearRows(self.groupCards)
    local plan, c = GC.plan, GC:GetConfig()
    if not plan.ready or #plan.members == 0 then
        local t = Text(layoutArea, "Find a roster first. The complete subgroup layout will appear here before anyone is invited.", "GameFontHighlight", C.dim)
        t:SetPoint("TOPLEFT", 14, -10); t:SetWidth(950); t:SetJustifyH("LEFT")
        local holder = CreateFrame("Frame", nil, layoutArea); holder.text = t; holder:SetScript("OnHide", function(s) if s.text then s.text:Hide() end end); self.layoutRows[#self.layoutRows + 1] = holder
        return
    end

    local groupCount = c.size <= 5 and 1 or math.min(8, math.ceil(c.size / 5))
    local cols = groupCount <= 5 and groupCount or 4
    local rows = math.ceil(groupCount / cols)
    local gap = 8
    local areaWidth = 1000
    local cardWidth = math.floor((areaWidth - (cols - 1) * gap) / cols)
    local cardHeight = rows == 1 and 470 or 232
    local membersByGroup = {}
    for g = 1, groupCount do membersByGroup[g] = {} end
    for _, m in ipairs(plan.members) do
        local g = math.max(1, math.min(groupCount, tonumber(m.subgroup) or 1))
        membersByGroup[g][#membersByGroup[g] + 1] = m
    end

    for g = 1, groupCount do
        local rowIndex = math.floor((g - 1) / cols)
        local colIndex = (g - 1) % cols
        local card = CreateFrame("Frame", nil, layoutArea)
        card:SetWidth(cardWidth); card:SetHeight(cardHeight)
        card:SetPoint("TOPLEFT", colIndex * (cardWidth + gap), -(rowIndex * (cardHeight + gap)))
        card.groupIndex = g; card:EnableMouse(true)
        local bg = Solid(card, "BACKGROUND", C.panel); bg:SetAllPoints(card)
        local head = Solid(card, "ARTWORK", C.panel2); head:SetPoint("TOPLEFT"); head:SetPoint("TOPRIGHT"); head:SetHeight(32)
        local label = Text(card, "GROUP " .. g, "GameFontNormal", C.text); label:SetPoint("TOPLEFT", 10, -9)
        local count = Text(card, tostring(#membersByGroup[g]) .. "/5", "GameFontHighlightSmall", #membersByGroup[g] == 5 and C.green or C.gold); count:SetPoint("TOPRIGHT", -10, -10)
        self.groupCards[#self.groupCards + 1] = card

        for i, member in ipairs(membersByGroup[g]) do
            local m = member
            local row = CreateFrame("Button", nil, card)
            row:SetHeight(rows == 1 and 58 or 34); row:SetPoint("TOPLEFT", 6, -36 - (i - 1) * (rows == 1 and 62 or 37)); row:SetPoint("RIGHT", -6, 0)
            row.groupIndex = g; row:RegisterForDrag("LeftButton")
            local rbg = Solid(row, "BACKGROUND", i % 2 == 0 and C.panel2 or C.bg, 0.86); rbg:SetAllPoints(row)
            local rc = ROLE_COLOR[m.role] or C.muted
            local stripe = Solid(row, "ARTWORK", rc); stripe:SetPoint("TOPLEFT"); stripe:SetPoint("BOTTOMLEFT"); stripe:SetWidth(3)
            local name = Text(row, m.name or "?", "GameFontHighlightSmall", m.human and C.gold or C.text); name:SetPoint("TOPLEFT", 8, rows == 1 and -10 or -5); name:SetWidth(cardWidth - 82); name:SetJustifyH("LEFT")
            local detail = Text(row, (D.ROLE_LABEL[m.role] or m.role or "?") .. " • " .. (D.CLASS_LABEL[m.class] or m.class or "?"), "GameFontHighlightSmall", C.muted)
            detail:SetPoint("BOTTOMLEFT", 8, rows == 1 and 9 or 4); detail:SetWidth(cardWidth - 82); detail:SetJustifyH("LEFT")
            if rows > 1 then detail:Hide() end
            local left = Button(row, "<", 26, 22, function()
                local target = g - 1; if target < 1 then target = groupCount end; GC:MoveMember(m.name, target)
            end); left:SetPoint("RIGHT", -34, 0)
            local right = Button(row, ">", 26, 22, function()
                local target = g + 1; if target > groupCount then target = 1 end; GC:MoveMember(m.name, target)
            end); right:SetPoint("RIGHT", -5, 0)
            row:SetScript("OnDragStart", function() GC.dragMember = m.name end)
            row:SetScript("OnDragStop", function()
                local dragged = GC.dragMember; GC.dragMember = nil
                local target = GetMouseFocus and FindDropGroup(GetMouseFocus()) or nil
                if dragged and target then GC:MoveMember(dragged, target) end
            end)
            row:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(m.name or "?", 1, 1, 1)
                GameTooltip:AddLine((D.ROLE_LABEL[m.role] or m.role or "?") .. " • " .. (D.CLASS_LABEL[m.class] or m.class or "?") .. " • " .. (m.spec or ""), 0.8, 0.85, 0.95)
                GameTooltip:AddLine(m.human and "Human / locked" or ((m.source or "WORLD") .. (m.pinned and " / pinned" or "")), m.human and 1 or 0.7, m.human and 0.7 or 0.9, 0.3)
                if IsStable(c, m) then GameTooltip:AddLine("This member's subgroup is saved with custom profiles.", 0.55, 0.85, 1, true) end
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function() GameTooltip:Hide() end)
            self.layoutRows[#self.layoutRows + 1] = row
        end
    end
end

-- DIAGNOSTICS ----------------------------------------------------------------
local diagnostics = Page("DIAGNOSTICS")
local diagTitle = Text(diagnostics, "Composer diagnostics", "GameFontNormalLarge", C.text); diagTitle:SetPoint("TOPLEFT", 10, -8)
local diagHint = Text(diagnostics, "Development-facing state without exposing raw database operations. Useful when a roster cannot be built or a bot does not join.", "GameFontHighlightSmall", C.muted)
diagHint:SetPoint("TOPLEFT", diagTitle, "BOTTOMLEFT", 0, -4); diagHint:SetWidth(960); diagHint:SetJustifyH("LEFT")
local refreshDiag = Button(diagnostics, "Refresh Diagnostics", 150, 26, function() GC:RequestDiagnostics() end); refreshDiag:SetPoint("TOPRIGHT", -12, -8)
local diagBox = CreateFrame("Frame", nil, diagnostics); diagBox:SetPoint("TOPLEFT", 10, -62); diagBox:SetPoint("BOTTOMRIGHT", -10, 10)
local diagBg = Solid(diagBox, "BACKGROUND", C.panel); diagBg:SetAllPoints(diagBox)
local diagText = Text(diagBox, "No diagnostics received yet.", "GameFontHighlight", C.text); diagText:SetPoint("TOPLEFT", 16, -16); diagText:SetPoint("BOTTOMRIGHT", -16, 16); diagText:SetJustifyH("LEFT"); diagText:SetJustifyV("TOP")
A.diagText = diagText

function A:RefreshDiagnostics()
    local c, plan = GC:GetConfig(), GC.plan
    local lines = {
        "Client version: " .. tostring(GC.version),
        "Mode: " .. tostring(c.mode) .. "   Activity: " .. tostring(c.activity) .. "   Difficulty: " .. tostring(c.difficulty),
        "Target: " .. tostring(c.size) .. "   Tanks: " .. tostring(c.tanks) .. "   Healers: " .. tostring(c.healers) .. "   DPS: " .. tostring(c.dps),
        "Plan: " .. (plan.ready and (plan.valid and "VALID" or "INVALID") or "not searched") .. "   Members: " .. tostring(#(plan.members or {})),
        "Humans configured: " .. tostring(#GC:ScanHumans()) .. "   Extra humans: " .. tostring(#(c.extraHumans or {})) .. "   Pins: " .. tostring(#(c.pinned or {})),
        "Utility balancing: " .. tostring(c.options.balanceUtility and "ON" or "OFF") .. "   Melee/ranged balancing: " .. tostring(c.options.balanceRange and "ON" or "OFF"),
        "",
        "Server: " .. tostring((plan.summary and plan.summary.diagnostics) or "Press Refresh Diagnostics for server candidate counts."),
    }
    if plan.summary and (plan.summary.ranged or plan.summary.melee) then
        lines[#lines + 1] = "DPS mix: " .. tostring(plan.summary.ranged or 0) .. " ranged / " .. tostring(plan.summary.melee or 0) .. " melee"
    end
    if plan.warnings and #plan.warnings > 0 then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "Warnings:"
        for _, w in ipairs(plan.warnings) do lines[#lines + 1] = " • " .. w end
    end
    diagText:SetText(table.concat(lines, "\n"))
end

function A:ApplyScale()
    if not GC.db then return end
    local scale = tonumber(GC.db.window.userScale) or 1
    if GC.db.window.autoScale then
        local pw, ph = UIParent:GetWidth() or 1920, UIParent:GetHeight() or 1080
        local fit = math.min((pw - 80) / 1060, (ph - 80) / 690)
        fit = math.max(0.80, math.min(1.42, fit))
        scale = scale * fit
    end
    frame:SetScale(math.max(0.72, math.min(1.50, scale)))
end

function A:Show()
    if not GC.db then return end
    frame:ClearAllPoints()
    local point = GC.db.window.advancedPoint or { "CENTER", "UIParent", "CENTER", 0, 0 }
    frame:SetPoint(point[1] or "CENTER", _G[point[2]] or UIParent, point[3] or "CENTER", tonumber(point[4]) or 0, tonumber(point[5]) or 0)
    A:ApplyScale()
    frame:Show()
    SelectPage(GC.db.window.advancedTab or "PEOPLE")
    A:RefreshAll()
end

function A:Toggle() if frame:IsShown() then frame:Hide() else A:Show() end end
function A:RefreshAll()
    if not frame:IsShown() then return end
    A:RefreshPeople(); A:RefreshLayout(); A:RefreshDiagnostics()
    local c = GC:GetConfig()
    if c.mode == "DUNGEON" and GC.plan.ready and GC.plan.valid then queueButton:Enable(); queueButton:SetAlpha(1) else queueButton:Disable(); queueButton:SetAlpha(0.42) end
end

-- Put the editor entry point in the main header, where it remains visible even when the left pane scrolls.
local editorButton = Button(UI.frame, "Roster Editor", 116, 27, function() A:Toggle() end,
    "Human roles, pinned guild companions, manual subgroup layout and diagnostics.")
editorButton:SetPoint("TOPRIGHT", -52, -23)
A.editorButton = editorButton

GC:RegisterCallback("CONFIG_CHANGED", function() A:RefreshAll() end)
GC:RegisterCallback("PLAN_CHANGED", function() A:RefreshAll() end)
GC:RegisterCallback("HUMANS_CHANGED", function() if frame:IsShown() then A:RefreshPeople() end end)
GC:RegisterCallback("DIAGNOSTICS", function() if frame:IsShown() then A:RefreshDiagnostics() end end)
GC:RegisterCallback("DISPLAY_CHANGED", function()
    if UI.ApplyScale then UI:ApplyScale() end
    A:ApplyScale()
end)

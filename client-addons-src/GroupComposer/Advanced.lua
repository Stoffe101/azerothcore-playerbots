local GC = GroupComposer
local D = GroupComposerData
local UI = GC.UI

GC.Advanced = GC.Advanced or {}
local A = GC.Advanced

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
    local labelText = Text(cb, label, "GameFontHighlightSmall", C.text)
    labelText:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    cb.label = labelText
    cb:SetScript("OnClick", function(self)
        if fn then fn(self:GetChecked() and true or false) end
    end)
    return cb
end

local function Dropdown(parent, width, itemsFn, valueFn, setFn)
    local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dd, width or 130)
    UIDropDownMenu_JustifyText(dd, "LEFT")
    dd.itemsFn, dd.valueFn, dd.setFn = itemsFn, valueFn, setFn
    UIDropDownMenu_Initialize(dd, function(frame, level)
        local current = frame.valueFn and frame.valueFn() or nil
        local items = frame.itemsFn and frame.itemsFn() or {}
        for _, item in ipairs(items) do
            local valueCopy = item.value
            local disabledCopy = item.disabled and true or false
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.label
            info.value = valueCopy
            info.checked = current == valueCopy
            info.disabled = disabledCopy
            info.func = function()
                if not disabledCopy and frame.setFn then frame.setFn(valueCopy) end
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
    local items = {}
    if includeAuto then items[#items + 1] = { value = "AUTO", label = "Auto-detect" } end
    items[#items + 1] = { value = "TANK", label = "Tank" }
    items[#items + 1] = { value = "HEALER", label = "Healer" }
    items[#items + 1] = { value = "DPS", label = "DPS" }
    return items
end

local function ClearRows(rows)
    for _, row in ipairs(rows or {}) do
        row:Hide()
        row:SetParent(nil)
        if row.attachedText then row.attachedText:Hide() end
    end
    return {}
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

local headerBg = Solid(frame, "BACKGROUND", C.header)
headerBg:SetPoint("TOPLEFT", 5, -5); headerBg:SetPoint("TOPRIGHT", -5, -5); headerBg:SetHeight(66)
local title = Text(frame, "ROSTER EDITOR", "GameFontNormalLarge", C.text); title:SetPoint("TOPLEFT", 22, -17)
local subtitle = Text(frame, "Humans, familiar guild members, subgroup placement and diagnostics", "GameFontHighlightSmall", C.muted)
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -8, -8)

local pageHost = CreateFrame("Frame", nil, frame)
pageHost:SetPoint("TOPLEFT", 10, -111); pageHost:SetPoint("BOTTOMRIGHT", -10, 48)
A.pages, A.tabs = {}, {}

local function CreatePage(name)
    local page = CreateFrame("Frame", nil, pageHost)
    page:SetAllPoints(pageHost); page:Hide(); A.pages[name] = page
    return page
end

local function SelectPage(name)
    if not A.pages[name] then return end
    for key, page in pairs(A.pages) do if key == name then page:Show() else page:Hide() end end
    for key, button in pairs(A.tabs) do if key == name then button:LockHighlight() else button:UnlockHighlight() end end
    if GC.db then GC.db.window.advancedTab = name end
    if name == "PEOPLE" then A:RefreshPeople()
    elseif name == "LAYOUT" then A:RefreshLayout()
    else A:RefreshDiagnostics() end
end

local tabDefs = { { "PEOPLE", "People & Pins" }, { "LAYOUT", "Group Layout" }, { "DIAGNOSTICS", "Diagnostics" } }
for i, def in ipairs(tabDefs) do
    local key = def[1]
    local button = Button(frame, def[2], 130, 28, function() SelectPage(key) end)
    button:SetPoint("TOPLEFT", 20 + (i - 1) * 138, -77)
    A.tabs[key] = button
end

local queueButton = Button(frame, "Queue Dungeon Finder", 154, 28, function() GC:QueueDungeon() end,
    "After the composed 5-player party is assembled, hand supported Normal or Heroic dungeons to stock 3.3.5a Dungeon Finder.")
queueButton:SetPoint("TOPRIGHT", -20, -77)
A.queueButton = queueButton

-- PEOPLE AND PINS ------------------------------------------------------------
local people = CreatePage("PEOPLE")
local peopleScroll = CreateFrame("ScrollFrame", "GroupComposerPeopleScroll", people, "UIPanelScrollFrameTemplate")
peopleScroll:SetPoint("TOPLEFT", 0, 0); peopleScroll:SetPoint("BOTTOMRIGHT", -27, 0); peopleScroll:EnableMouseWheel(true)
peopleScroll:SetScript("OnMouseWheel", function(self, delta)
    local current, range = self:GetVerticalScroll(), self:GetVerticalScrollRange()
    self:SetVerticalScroll(math.max(0, math.min(range, current - delta * 40)))
end)
local peopleContent = CreateFrame("Frame", nil, peopleScroll)
peopleContent:SetWidth(995); peopleContent:SetHeight(780); peopleScroll:SetScrollChild(peopleContent)

local peopleTitle = Text(peopleContent, "Human roster anchors", "GameFontNormalLarge", C.text); peopleTitle:SetPoint("TOPLEFT", 10, -8)
local peopleHint = Text(peopleContent, "Real players already grouped with you are preserved. Override a role only when auto-detection is wrong or unavailable.", "GameFontHighlightSmall", C.muted)
peopleHint:SetPoint("TOPLEFT", peopleTitle, "BOTTOMLEFT", 0, -4); peopleHint:SetWidth(950); peopleHint:SetJustifyH("LEFT")

local humanArea = CreateFrame("Frame", nil, peopleContent)
humanArea:SetPoint("TOPLEFT", 10, -58); humanArea:SetWidth(475); humanArea:SetHeight(245)
local humanBg = Solid(humanArea, "BACKGROUND", C.panel); humanBg:SetAllPoints(humanArea)
local humanHeader = Text(humanArea, "CURRENT HUMANS", "GameFontNormalSmall", C.gold); humanHeader:SetPoint("TOPLEFT", 12, -12)
A.humanArea = humanArea
A.humanRows = {}

local addArea = CreateFrame("Frame", nil, peopleContent)
addArea:SetPoint("TOPLEFT", 500, -58); addArea:SetWidth(485); addArea:SetHeight(245)
local addBg = Solid(addArea, "BACKGROUND", C.panel); addBg:SetAllPoints(addArea)
local addHeader = Text(addArea, "ADD ONLINE HUMAN", "GameFontNormalSmall", C.blue); addHeader:SetPoint("TOPLEFT", 12, -12)
local addDesc = Text(addArea, "Optional real player who is not grouped yet. They are invited normally during Assemble and never treated as a bot candidate.", "GameFontHighlightSmall", C.muted)
addDesc:SetPoint("TOPLEFT", 12, -34); addDesc:SetWidth(455); addDesc:SetJustifyH("LEFT")
local humanName = CreateFrame("EditBox", nil, addArea, "InputBoxTemplate")
humanName:SetWidth(180); humanName:SetHeight(24); humanName:SetAutoFocus(false); humanName:SetMaxLetters(24); humanName:SetPoint("TOPLEFT", 16, -82)
humanName:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
local addRole = "DPS"
local humanRoleDD
humanRoleDD = Dropdown(addArea, 120, function() return RoleItems(false) end, function() return addRole end, function(value)
    addRole = value
    humanRoleDD:Refresh()
end)
humanRoleDD:SetPoint("LEFT", humanName, "RIGHT", -4, -2)
local addHumanButton = Button(addArea, "Add", 72, 24, function()
    if GC:AddExtraHuman(humanName:GetText(), addRole) then
        humanName:SetText("")
    else
        GC:Fire("STATUS", "Enter a valid online character name and role.")
    end
end)
addHumanButton:SetPoint("LEFT", humanRoleDD, "RIGHT", -2, 2)
local extraArea = CreateFrame("Frame", nil, addArea)
extraArea:SetPoint("TOPLEFT", 12, -122); extraArea:SetPoint("BOTTOMRIGHT", -12, 10)
A.extraArea, A.extraRows = extraArea, {}

local pinTitle = Text(peopleContent, "Persistent guild companions", "GameFontNormalLarge", C.text); pinTitle:SetPoint("TOPLEFT", 10, -322)
local pinHint = Text(peopleContent, "Pin familiar Playerbots by name. Preferred pins fall back gracefully. Required pins block the roster if unavailable.", "GameFontHighlightSmall", C.muted)
pinHint:SetPoint("TOPLEFT", pinTitle, "BOTTOMLEFT", 0, -4); pinHint:SetWidth(950); pinHint:SetJustifyH("LEFT")
local pinArea = CreateFrame("Frame", nil, peopleContent)
pinArea:SetPoint("TOPLEFT", 10, -372); pinArea:SetWidth(975); pinArea:SetHeight(248)
local pinBg = Solid(pinArea, "BACKGROUND", C.panel); pinBg:SetAllPoints(pinArea)
local pinName = CreateFrame("EditBox", nil, pinArea, "InputBoxTemplate")
pinName:SetWidth(180); pinName:SetHeight(24); pinName:SetAutoFocus(false); pinName:SetMaxLetters(24); pinName:SetPoint("TOPLEFT", 16, -18)
pinName:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
local pinRole = "DPS"
local pinRoleDD
pinRoleDD = Dropdown(pinArea, 120, function() return RoleItems(false) end, function() return pinRole end, function(value)
    pinRole = value
    pinRoleDD:Refresh()
end)
pinRoleDD:SetPoint("LEFT", pinName, "RIGHT", -4, -2)
local pinRequired = false
local pinRequiredCheck = Checkbox(pinArea, "Required", false, function(value) pinRequired = value end)
pinRequiredCheck:SetPoint("LEFT", pinRoleDD, "RIGHT", 0, 1)
local pinButton = Button(pinArea, "Pin Member", 104, 24, function()
    if GC:AddPinnedMember(pinName:GetText(), pinRole, pinRequired) then
        pinName:SetText("")
    else
        GC:Fire("STATUS", "Enter a valid Playerbot name and role.")
    end
end)
pinButton:SetPoint("LEFT", pinRequiredCheck, "RIGHT", 76, 0)
A.pinRows = {}

local optimize = CreateFrame("Frame", nil, peopleContent)
optimize:SetPoint("TOPLEFT", 10, -636); optimize:SetWidth(975); optimize:SetHeight(118)
local optimizeBg = Solid(optimize, "BACKGROUND", C.panel2); optimizeBg:SetAllPoints(optimize)
local optimizeTitle = Text(optimize, "SECONDARY OPTIMIZATION", "GameFontNormalSmall", C.text); optimizeTitle:SetPoint("TOPLEFT", 12, -10)
local utilityCheck = Checkbox(optimize, "Balance useful raid utility", true, function(value)
    GC:GetConfig().options.balanceUtility = value; GC:Touch("Utility rule changed")
end); utilityCheck:SetPoint("TOPLEFT", 12, -38)
local rangeCheck = Checkbox(optimize, "Balance melee / ranged DPS", true, function(value)
    GC:GetConfig().options.balanceRange = value; GC:Touch("Range rule changed")
end); rangeCheck:SetPoint("TOPLEFT", 284, -38)
local guildCheck = Checkbox(optimize, "Prefer persistent guild members", true, function(value)
    GC:GetConfig().options.preferGuild = value; GC:Touch("Guild preference changed")
end); guildCheck:SetPoint("TOPLEFT", 568, -38)
local worldCheck = Checkbox(optimize, "Allow world-bot fallback", true, function(value)
    GC:GetConfig().options.fillWorld = value; GC:Touch("World fallback changed")
end); worldCheck:SetPoint("TOPLEFT", 12, -76)
local queueCheck = Checkbox(optimize, "Queue supported dungeon automatically after assembly", false, function(value)
    GC:GetConfig().options.queueAfterAssemble = value; GC:Touch("Queue option changed")
end); queueCheck:SetPoint("TOPLEFT", 284, -76)
A.optimizationChecks = { utility = utilityCheck, range = rangeCheck, guild = guildCheck, world = worldCheck, queue = queueCheck }

function A:RefreshPeople()
    if not GC.db then return end
    local config = GC:GetConfig()
    A.humanRows = ClearRows(A.humanRows)
    A.extraRows = ClearRows(A.extraRows)
    A.pinRows = ClearRows(A.pinRows)

    local humans = GC:ScanHumans()
    local y = -38
    if #humans == 0 then
        local holder = CreateFrame("Frame", nil, humanArea)
        holder.attachedText = Text(humanArea, "No real players detected.", "GameFontHighlightSmall", C.dim)
        holder.attachedText:SetPoint("TOPLEFT", 12, y)
        A.humanRows[#A.humanRows + 1] = holder
    else
        for _, humanValue in ipairs(humans) do
            local human = humanValue
            local row = CreateFrame("Frame", nil, humanArea)
            row:SetWidth(450); row:SetHeight(34); row:SetPoint("TOPLEFT", 10, y)
            local rowBg = Solid(row, "BACKGROUND", C.panel2, 0.85); rowBg:SetAllPoints(row)
            local name = Text(row, human.name, "GameFontHighlightSmall", human.isPlayer and C.gold or C.text)
            name:SetPoint("LEFT", 8, 0); name:SetWidth(112); name:SetJustifyH("LEFT")
            local className = D.CLASS_LABEL[human.class] or human.class or "Unknown"
            local classText = Text(row, className, "GameFontHighlightSmall", C.muted)
            classText:SetPoint("LEFT", 126, 0); classText:SetWidth(104); classText:SetJustifyH("LEFT")
            local roleDD
            roleDD = Dropdown(row, 112, function() return RoleItems(true) end,
                function() return config.humanRoles[human.name] or human.role or "AUTO" end,
                function(value)
                    GC:SetHumanRole(human.name, value)
                    roleDD:Refresh()
                end)
            roleDD:SetPoint("RIGHT", 12, -2)
            A.humanRows[#A.humanRows + 1] = row
            y = y - 38
        end
    end

    local extraY = 0
    if #config.extraHumans == 0 then
        local holder = CreateFrame("Frame", nil, extraArea)
        holder.attachedText = Text(extraArea, "No additional humans selected.", "GameFontHighlightSmall", C.dim)
        holder.attachedText:SetPoint("TOPLEFT", 2, -2)
        A.extraRows[#A.extraRows + 1] = holder
    else
        for index, extraValue in ipairs(config.extraHumans) do
            local rowIndex, extra = index, extraValue
            local row = CreateFrame("Frame", nil, extraArea)
            row:SetHeight(30); row:SetPoint("TOPLEFT", 0, -extraY); row:SetPoint("RIGHT", 0, 0)
            local label = Text(row, extra.name .. "  •  " .. (D.ROLE_LABEL[extra.role] or extra.role), "GameFontHighlightSmall", C.text)
            label:SetPoint("LEFT", 4, 0)
            local remove = Button(row, "Remove", 66, 22, function() GC:RemoveExtraHuman(rowIndex) end)
            remove:SetPoint("RIGHT", -2, 0)
            A.extraRows[#A.extraRows + 1] = row
            extraY = extraY + 32
        end
    end

    local pinY = -66
    if #config.pinned == 0 then
        local holder = CreateFrame("Frame", nil, pinArea)
        holder.attachedText = Text(pinArea, "No guild companions pinned. Normal guild-first selection still applies.", "GameFontHighlightSmall", C.dim)
        holder.attachedText:SetPoint("TOPLEFT", 16, pinY)
        A.pinRows[#A.pinRows + 1] = holder
    else
        for index, pinValue in ipairs(config.pinned) do
            local rowIndex, pin = index, pinValue
            local row = CreateFrame("Frame", nil, pinArea)
            row:SetWidth(930); row:SetHeight(32); row:SetPoint("TOPLEFT", 14, pinY)
            local rowBg = Solid(row, "BACKGROUND", C.panel2, 0.82); rowBg:SetAllPoints(row)
            local name = Text(row, pin.name, "GameFontHighlightSmall", C.gold)
            name:SetPoint("LEFT", 8, 0); name:SetWidth(160); name:SetJustifyH("LEFT")
            local role = Text(row, D.ROLE_LABEL[pin.role] or pin.role, "GameFontHighlightSmall", ROLE_COLOR[pin.role] or C.text)
            role:SetPoint("LEFT", 176, 0); role:SetWidth(90); role:SetJustifyH("LEFT")
            local required = Checkbox(row, "Required", pin.required, function(value)
                pin.required = value
                GC:Touch("Pinned member changed")
            end)
            required:SetPoint("LEFT", 282, 0)
            local remove = Button(row, "Unpin", 66, 22, function() GC:RemovePinnedMember(rowIndex) end)
            remove:SetPoint("RIGHT", -6, 0)
            A.pinRows[#A.pinRows + 1] = row
            pinY = pinY - 36
        end
    end

    utilityCheck:SetChecked(config.options.balanceUtility and true or false)
    rangeCheck:SetChecked(config.options.balanceRange and true or false)
    guildCheck:SetChecked(config.options.preferGuild and true or false)
    worldCheck:SetChecked(config.options.fillWorld and true or false)
    queueCheck:SetChecked(config.options.queueAfterAssemble and true or false)
end

-- GROUP LAYOUT ---------------------------------------------------------------
local layout = CreatePage("LAYOUT")
local layoutTitle = Text(layout, "Raid subgroup editor", "GameFontNormalLarge", C.text); layoutTitle:SetPoint("TOPLEFT", 10, -8)
local layoutHint = Text(layout, "Auto Arrange establishes a sane baseline. Drag a member onto another group, or use the arrow buttons. Moving into a full group swaps one member instead of dropping anyone.", "GameFontHighlightSmall", C.muted)
layoutHint:SetPoint("TOPLEFT", layoutTitle, "BOTTOMLEFT", 0, -4); layoutHint:SetWidth(985); layoutHint:SetJustifyH("LEFT")
local layoutArea = CreateFrame("Frame", nil, layout)
layoutArea:SetPoint("TOPLEFT", 6, -58); layoutArea:SetPoint("BOTTOMRIGHT", -6, 6)
A.layoutArea, A.layoutRows, A.groupCards = layoutArea, {}, {}

local function FindDropGroup(frameUnderMouse)
    local node = frameUnderMouse
    for _ = 1, 8 do
        if not node then return nil end
        if node.groupIndex then return node.groupIndex end
        node = node:GetParent()
    end
end

local function IsStableMember(config, member)
    if member.human then return true end
    local key = string.lower(member.name or "")
    for _, pin in ipairs(config.pinned or {}) do
        if string.lower(pin.name) == key then return true end
    end
    return false
end

function A:RefreshLayout()
    A.layoutRows = ClearRows(A.layoutRows)
    A.groupCards = ClearRows(A.groupCards)
    local plan, config = GC.plan, GC:GetConfig()
    if not plan.ready or #(plan.members or {}) == 0 then
        local holder = CreateFrame("Frame", nil, layoutArea)
        holder.attachedText = Text(layoutArea, "Find a roster first. The complete subgroup layout will appear here before anyone is invited.", "GameFontHighlight", C.dim)
        holder.attachedText:SetPoint("TOPLEFT", 14, -10); holder.attachedText:SetWidth(950); holder.attachedText:SetJustifyH("LEFT")
        A.layoutRows[#A.layoutRows + 1] = holder
        return
    end

    local groupCount = config.size <= 5 and 1 or math.min(8, math.ceil(config.size / 5))
    local columns = groupCount <= 5 and groupCount or 4
    local rowCount = math.ceil(groupCount / columns)
    local gap = 8
    local areaWidth = 1000
    local cardWidth = math.floor((areaWidth - (columns - 1) * gap) / columns)
    local cardHeight = rowCount == 1 and 470 or 232
    local membersByGroup = {}
    for group = 1, groupCount do membersByGroup[group] = {} end
    for _, member in ipairs(plan.members) do
        local group = math.max(1, math.min(groupCount, tonumber(member.subgroup) or 1))
        membersByGroup[group][#membersByGroup[group] + 1] = member
    end

    for group = 1, groupCount do
        local rowIndex = math.floor((group - 1) / columns)
        local columnIndex = (group - 1) % columns
        local card = CreateFrame("Frame", nil, layoutArea)
        card:SetWidth(cardWidth); card:SetHeight(cardHeight)
        card:SetPoint("TOPLEFT", columnIndex * (cardWidth + gap), -(rowIndex * (cardHeight + gap)))
        card.groupIndex = group; card:EnableMouse(true)
        local cardBg = Solid(card, "BACKGROUND", C.panel); cardBg:SetAllPoints(card)
        local cardHeader = Solid(card, "ARTWORK", C.panel2); cardHeader:SetPoint("TOPLEFT"); cardHeader:SetPoint("TOPRIGHT"); cardHeader:SetHeight(32)
        local groupText = Text(card, "GROUP " .. group, "GameFontNormal", C.text); groupText:SetPoint("TOPLEFT", 10, -9)
        local countText = Text(card, tostring(#membersByGroup[group]) .. "/5", "GameFontHighlightSmall", #membersByGroup[group] == 5 and C.green or C.gold)
        countText:SetPoint("TOPRIGHT", -10, -10)
        A.groupCards[#A.groupCards + 1] = card

        for index, memberValue in ipairs(membersByGroup[group]) do
            local member = memberValue
            local compact = rowCount > 1
            local rowHeight = compact and 34 or 58
            local rowStep = compact and 37 or 62
            local row = CreateFrame("Button", nil, card)
            row:SetHeight(rowHeight); row:SetPoint("TOPLEFT", 6, -36 - (index - 1) * rowStep); row:SetPoint("RIGHT", -6, 0)
            row.groupIndex = group; row:RegisterForDrag("LeftButton")
            local rowBg = Solid(row, "BACKGROUND", index % 2 == 0 and C.panel2 or C.bg, 0.86); rowBg:SetAllPoints(row)
            local roleColor = ROLE_COLOR[member.role] or C.muted
            local stripe = Solid(row, "ARTWORK", roleColor); stripe:SetPoint("TOPLEFT"); stripe:SetPoint("BOTTOMLEFT"); stripe:SetWidth(3)
            local name = Text(row, member.name or "?", "GameFontHighlightSmall", member.human and C.gold or C.text)
            name:SetPoint("TOPLEFT", 8, compact and -5 or -10); name:SetWidth(cardWidth - 82); name:SetJustifyH("LEFT")
            if not compact then
                local detail = Text(row, (D.ROLE_LABEL[member.role] or member.role or "?") .. " • " .. (D.CLASS_LABEL[member.class] or member.class or "?"), "GameFontHighlightSmall", C.muted)
                detail:SetPoint("BOTTOMLEFT", 8, 9); detail:SetWidth(cardWidth - 82); detail:SetJustifyH("LEFT")
            end
            local left = Button(row, "<", 26, 22, function()
                local target = group - 1; if target < 1 then target = groupCount end
                GC:MoveMember(member.name, target)
            end); left:SetPoint("RIGHT", -34, 0)
            local right = Button(row, ">", 26, 22, function()
                local target = group + 1; if target > groupCount then target = 1 end
                GC:MoveMember(member.name, target)
            end); right:SetPoint("RIGHT", -5, 0)
            row:SetScript("OnDragStart", function() GC.dragMember = member.name end)
            row:SetScript("OnDragStop", function()
                local dragged = GC.dragMember
                GC.dragMember = nil
                local target = GetMouseFocus and FindDropGroup(GetMouseFocus()) or nil
                if dragged and target then GC:MoveMember(dragged, target) end
            end)
            row:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(member.name or "?", 1, 1, 1)
                GameTooltip:AddLine((D.ROLE_LABEL[member.role] or member.role or "?") .. " • " .. (D.CLASS_LABEL[member.class] or member.class or "?") .. " • " .. (member.spec or ""), 0.8, 0.85, 0.95)
                GameTooltip:AddLine(member.human and "Human / locked" or ((member.source or "WORLD") .. (member.pinned and " / pinned" or "")), member.human and 1 or 0.7, member.human and 0.7 or 0.9, 0.3)
                if IsStableMember(config, member) then GameTooltip:AddLine("This member's subgroup is saved with custom profiles.", 0.55, 0.85, 1, true) end
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function() GameTooltip:Hide() end)
            A.layoutRows[#A.layoutRows + 1] = row
        end
    end
end

-- DIAGNOSTICS ----------------------------------------------------------------
local diagnostics = CreatePage("DIAGNOSTICS")
local diagnosticsTitle = Text(diagnostics, "Composer diagnostics", "GameFontNormalLarge", C.text); diagnosticsTitle:SetPoint("TOPLEFT", 10, -8)
local diagnosticsHint = Text(diagnostics, "Development-facing state without exposing raw database operations. Useful when a roster cannot be built or a bot does not join.", "GameFontHighlightSmall", C.muted)
diagnosticsHint:SetPoint("TOPLEFT", diagnosticsTitle, "BOTTOMLEFT", 0, -4); diagnosticsHint:SetWidth(960); diagnosticsHint:SetJustifyH("LEFT")
local refreshDiagnostics = Button(diagnostics, "Refresh Diagnostics", 150, 26, function() GC:RequestDiagnostics() end)
refreshDiagnostics:SetPoint("TOPRIGHT", -12, -8)
local diagnosticsBox = CreateFrame("Frame", nil, diagnostics)
diagnosticsBox:SetPoint("TOPLEFT", 10, -62); diagnosticsBox:SetPoint("BOTTOMRIGHT", -10, 10)
local diagnosticsBg = Solid(diagnosticsBox, "BACKGROUND", C.panel); diagnosticsBg:SetAllPoints(diagnosticsBox)
local diagnosticsText = Text(diagnosticsBox, "No diagnostics received yet.", "GameFontHighlight", C.text)
diagnosticsText:SetPoint("TOPLEFT", 16, -16); diagnosticsText:SetPoint("BOTTOMRIGHT", -16, 16); diagnosticsText:SetJustifyH("LEFT"); diagnosticsText:SetJustifyV("TOP")
A.diagnosticsText = diagnosticsText

function A:RefreshDiagnostics()
    local config, plan = GC:GetConfig(), GC.plan
    local lines = {
        "Client version: " .. tostring(GC.version),
        "Mode: " .. tostring(config.mode) .. "   Activity: " .. tostring(config.activity) .. "   Difficulty: " .. tostring(config.difficulty),
        "Target: " .. tostring(config.size) .. "   Tanks: " .. tostring(config.tanks) .. "   Healers: " .. tostring(config.healers) .. "   DPS: " .. tostring(config.dps),
        "Plan: " .. (plan.ready and (plan.valid and "VALID" or "INVALID") or "not searched") .. "   Members: " .. tostring(#(plan.members or {})),
        "Humans detected: " .. tostring(#GC:ScanHumans()) .. "   Extra humans: " .. tostring(#(config.extraHumans or {})) .. "   Pins: " .. tostring(#(config.pinned or {})),
        "Utility balancing: " .. tostring(config.options.balanceUtility and "ON" or "OFF") .. "   Melee/ranged balancing: " .. tostring(config.options.balanceRange and "ON" or "OFF"),
        "",
        "Server: " .. tostring((plan.summary and plan.summary.diagnostics) or "Press Refresh Diagnostics for server candidate counts."),
    }
    if plan.summary and (plan.summary.ranged or plan.summary.melee) then
        lines[#lines + 1] = "DPS mix: " .. tostring(plan.summary.ranged or 0) .. " ranged / " .. tostring(plan.summary.melee or 0) .. " melee"
    end
    if plan.warnings and #plan.warnings > 0 then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "Warnings:"
        for _, warning in ipairs(plan.warnings) do lines[#lines + 1] = " • " .. warning end
    end
    diagnosticsText:SetText(table.concat(lines, "\n"))
end

function A:ApplyScale()
    if not GC.db then return end
    local scale = tonumber(GC.db.window.userScale) or 1
    if GC.db.window.autoScale then
        local width, height = UIParent:GetWidth() or 1920, UIParent:GetHeight() or 1080
        local fit = math.min((width - 80) / 1060, (height - 80) / 690)
        fit = math.max(0.80, math.min(1.42, fit))
        scale = scale * fit
    end
    frame:SetScale(math.max(0.72, math.min(1.50, scale)))
end

function A:RefreshAll()
    if not frame:IsShown() then return end
    A:RefreshPeople(); A:RefreshLayout(); A:RefreshDiagnostics()
    local config = GC:GetConfig()
    if config.mode == "DUNGEON" and GC.plan.ready and GC.plan.valid then
        queueButton:Enable(); queueButton:SetAlpha(1)
    else
        queueButton:Disable(); queueButton:SetAlpha(0.42)
    end
end

function A:Show()
    if not GC.db then return end
    frame:ClearAllPoints()
    local point = GC.db.window.advancedPoint or { "CENTER", "UIParent", "CENTER", 0, 0 }
    frame:SetPoint(point[1] or "CENTER", _G[point[2]] or UIParent, point[3] or "CENTER", tonumber(point[4]) or 0, tonumber(point[5]) or 0)
    A:ApplyScale(); frame:Show(); SelectPage(GC.db.window.advancedTab or "PEOPLE"); A:RefreshAll()
end

function A:Toggle()
    if frame:IsShown() then frame:Hide() else A:Show() end
end

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

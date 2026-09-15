local GC = GroupComposer
local D = GroupComposerData
local A = GC.Advanced

-- The first Roster Editor pass used fixed-height human/pin panels. That looks fine for a mostly-bot
-- raid, but a 25/40-player human-heavy raid can legitimately have dozens of locked anchors. Replace
-- the People page scroll child with a vertically flowing version whose sections grow with the data.
-- The outer UIPanelScrollFrameTemplate remains the single scrollbar for the page.
if not A or not A.pages or not A.pages.PEOPLE or not GroupComposerPeopleScroll then return end

local C = {
    panel = { 0.050, 0.060, 0.080, 0.98 },
    panel2 = { 0.065, 0.076, 0.100, 0.98 },
    blue = { 0.22, 0.58, 0.95, 1 },
    green = { 0.24, 0.82, 0.46, 1 },
    gold = { 1.00, 0.69, 0.20, 1 },
    text = { 0.93, 0.95, 0.99, 1 },
    muted = { 0.62, 0.68, 0.78, 1 },
    dim = { 0.43, 0.48, 0.57, 1 },
}
local ROLE_COLOR = { TANK = C.blue, HEALER = C.green, DPS = { 0.94, 0.28, 0.30, 1 } }

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

local function Button(parent, label, width, height, fn)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetWidth(width or 90); b:SetHeight(height or 24); b:SetText(label or "Button")
    if fn then b:SetScript("OnClick", fn) end
    return b
end

local function Checkbox(parent, label, checked, fn)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetWidth(24); cb:SetHeight(24); cb:SetChecked(checked and true or false)
    local txt = Text(cb, label, "GameFontHighlightSmall", C.text)
    txt:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    cb.label = txt
    cb:SetScript("OnClick", function(self)
        if fn then fn(self:GetChecked() and true or false) end
    end)
    return cb
end

local function Dropdown(parent, width, itemsFn, valueFn, setFn)
    local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dd, width or 120)
    UIDropDownMenu_JustifyText(dd, "LEFT")
    dd.itemsFn, dd.valueFn, dd.setFn = itemsFn, valueFn, setFn
    UIDropDownMenu_Initialize(dd, function(frame, level)
        local current = frame.valueFn and frame.valueFn() or nil
        for _, item in ipairs(frame.itemsFn and frame.itemsFn() or {}) do
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
    local out = {}
    if includeAuto then out[#out + 1] = { value = "AUTO", label = "Auto-detect" } end
    out[#out + 1] = { value = "TANK", label = "Tank" }
    out[#out + 1] = { value = "HEALER", label = "Healer" }
    out[#out + 1] = { value = "DPS", label = "DPS" }
    return out
end

local oldChild = GroupComposerPeopleScroll:GetScrollChild()
if oldChild then oldChild:Hide() end

local content = CreateFrame("Frame", "GroupComposerPeopleFlowContent", GroupComposerPeopleScroll)
content:SetWidth(995); content:SetHeight(820)
GroupComposerPeopleScroll:SetScrollChild(content)
A.peopleFlowContent = content

local title = Text(content, "People & persistent companions", "GameFontNormalLarge", C.text)
title:SetPoint("TOPLEFT", 10, -8)
local hint = Text(content,
    "Every real player is a locked roster anchor. Human-heavy raids, extra invites and pinned guild bots all expand vertically instead of overlapping.",
    "GameFontHighlightSmall", C.muted)
hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4); hint:SetWidth(950); hint:SetJustifyH("LEFT")

local humanSection = CreateFrame("Frame", nil, content)
local humanBg = Solid(humanSection, C.panel); humanBg:SetAllPoints(humanSection)
local humanTitle = Text(humanSection, "CURRENT HUMAN ANCHORS", "GameFontNormalSmall", C.gold)
humanTitle:SetPoint("TOPLEFT", 12, -12)
local humanSubtitle = Text(humanSection, "Auto-detected roles can be overridden when needed.", "GameFontHighlightSmall", C.muted)
humanSubtitle:SetPoint("TOPLEFT", humanTitle, "BOTTOMLEFT", 0, -3)

local extraSection = CreateFrame("Frame", nil, content)
local extraBg = Solid(extraSection, C.panel); extraBg:SetAllPoints(extraSection)
local extraTitle = Text(extraSection, "ADD ONLINE HUMAN", "GameFontNormalSmall", C.blue)
extraTitle:SetPoint("TOPLEFT", 12, -12)
local extraName = CreateFrame("EditBox", nil, extraSection, "InputBoxTemplate")
extraName:SetWidth(190); extraName:SetHeight(24); extraName:SetAutoFocus(false); extraName:SetMaxLetters(24)
extraName:SetPoint("TOPLEFT", 16, -40); extraName:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
local extraRole = "DPS"
local extraRoleDD
extraRoleDD = Dropdown(extraSection, 120, function() return RoleItems(false) end, function() return extraRole end, function(value)
    extraRole = value; extraRoleDD:Refresh()
end)
extraRoleDD:SetPoint("LEFT", extraName, "RIGHT", -4, -2)
local extraAdd = Button(extraSection, "Add Human", 96, 24, function()
    if GC:AddExtraHuman(extraName:GetText(), extraRole) then extraName:SetText("")
    else GC:Fire("STATUS", "Enter a valid online character name and role.") end
end)
extraAdd:SetPoint("LEFT", extraRoleDD, "RIGHT", -2, 2)

local pinSection = CreateFrame("Frame", nil, content)
local pinBg = Solid(pinSection, C.panel); pinBg:SetAllPoints(pinSection)
local pinTitle = Text(pinSection, "PERSISTENT GUILD COMPANIONS", "GameFontNormalSmall", C.gold)
pinTitle:SetPoint("TOPLEFT", 12, -12)
local pinName = CreateFrame("EditBox", nil, pinSection, "InputBoxTemplate")
pinName:SetWidth(190); pinName:SetHeight(24); pinName:SetAutoFocus(false); pinName:SetMaxLetters(24)
pinName:SetPoint("TOPLEFT", 16, -40); pinName:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
local pinRole = "DPS"
local pinRoleDD
pinRoleDD = Dropdown(pinSection, 120, function() return RoleItems(false) end, function() return pinRole end, function(value)
    pinRole = value; pinRoleDD:Refresh()
end)
pinRoleDD:SetPoint("LEFT", pinName, "RIGHT", -4, -2)
local pinRequiredValue = false
local pinRequired = Checkbox(pinSection, "Required", false, function(value) pinRequiredValue = value end)
pinRequired:SetPoint("LEFT", pinRoleDD, "RIGHT", 0, 1)
local pinAdd = Button(pinSection, "Pin Member", 100, 24, function()
    if GC:AddPinnedMember(pinName:GetText(), pinRole, pinRequiredValue) then pinName:SetText("")
    else GC:Fire("STATUS", "Enter a valid Playerbot name and role.") end
end)
pinAdd:SetPoint("LEFT", pinRequired, "RIGHT", 76, 0)

local rulesSection = CreateFrame("Frame", nil, content)
local rulesBg = Solid(rulesSection, C.panel2); rulesBg:SetAllPoints(rulesSection)
local rulesTitle = Text(rulesSection, "SECONDARY OPTIMIZATION", "GameFontNormalSmall", C.text)
rulesTitle:SetPoint("TOPLEFT", 12, -11)
local utilityCheck = Checkbox(rulesSection, "Balance useful raid utility", true, function(value)
    GC:GetConfig().options.balanceUtility = value; GC:Touch("Utility rule changed")
end)
utilityCheck:SetPoint("TOPLEFT", 12, -38)
local rangeCheck = Checkbox(rulesSection, "Balance melee / ranged DPS", true, function(value)
    GC:GetConfig().options.balanceRange = value; GC:Touch("Range rule changed")
end)
rangeCheck:SetPoint("TOPLEFT", 284, -38)
local guildCheck = Checkbox(rulesSection, "Prefer persistent guild members", true, function(value)
    GC:GetConfig().options.preferGuild = value; GC:Touch("Guild preference changed")
end)
guildCheck:SetPoint("TOPLEFT", 568, -38)
local worldCheck = Checkbox(rulesSection, "Allow world-bot fallback", true, function(value)
    GC:GetConfig().options.fillWorld = value; GC:Touch("World fallback changed")
end)
worldCheck:SetPoint("TOPLEFT", 12, -76)
local queueCheck = Checkbox(rulesSection, "Queue supported dungeon automatically after assembly", false, function(value)
    GC:GetConfig().options.queueAfterAssemble = value; GC:Touch("Queue option changed")
end)
queueCheck:SetPoint("TOPLEFT", 284, -76)

local humanRows, extraRows, pinRows = {}, {}, {}

local function HidePool(pool)
    for _, row in ipairs(pool) do row:Hide() end
end

local function EnsureHumanRow(index)
    if humanRows[index] then return humanRows[index] end
    local row = CreateFrame("Frame", nil, humanSection)
    row:SetHeight(34)
    local bg = Solid(row, C.panel2, 0.85); bg:SetAllPoints(row)
    local name = Text(row, "", "GameFontHighlightSmall", C.text)
    name:SetPoint("LEFT", 8, 0); name:SetWidth(220); name:SetJustifyH("LEFT")
    local classText = Text(row, "", "GameFontHighlightSmall", C.muted)
    classText:SetPoint("LEFT", 235, 0); classText:SetWidth(180); classText:SetJustifyH("LEFT")
    row.nameText, row.classText = name, classText
    humanRows[index] = row
    return row
end

local function EnsureExtraRow(index)
    if extraRows[index] then return extraRows[index] end
    local row = CreateFrame("Frame", nil, extraSection); row:SetHeight(30)
    local label = Text(row, "", "GameFontHighlightSmall", C.text); label:SetPoint("LEFT", 8, 0)
    local remove = Button(row, "Remove", 70, 22)
    remove:SetPoint("RIGHT", -8, 0)
    row.label, row.remove = label, remove
    extraRows[index] = row
    return row
end

local function EnsurePinRow(index)
    if pinRows[index] then return pinRows[index] end
    local row = CreateFrame("Frame", nil, pinSection); row:SetHeight(32)
    local bg = Solid(row, C.panel2, 0.82); bg:SetAllPoints(row)
    local name = Text(row, "", "GameFontHighlightSmall", C.gold); name:SetPoint("LEFT", 8, 0); name:SetWidth(220); name:SetJustifyH("LEFT")
    local role = Text(row, "", "GameFontHighlightSmall", C.text); role:SetPoint("LEFT", 235, 0); role:SetWidth(120); role:SetJustifyH("LEFT")
    local required = Checkbox(row, "Required", false)
    required:SetPoint("LEFT", 380, 0)
    local remove = Button(row, "Unpin", 68, 22); remove:SetPoint("RIGHT", -8, 0)
    row.nameText, row.roleText, row.required, row.remove = name, role, required, remove
    pinRows[index] = row
    return row
end

function A:RefreshPeople()
    if not GC.db then return end
    local config = GC:GetConfig()
    local humans = GC:ScanHumans()
    HidePool(humanRows); HidePool(extraRows); HidePool(pinRows)

    local top = 58
    local humanCount = math.max(1, #humans)
    local humanHeight = 58 + humanCount * 36 + 8
    humanSection:ClearAllPoints(); humanSection:SetPoint("TOPLEFT", 10, -top); humanSection:SetWidth(975); humanSection:SetHeight(humanHeight)
    if #humans == 0 then
        local row = EnsureHumanRow(1); row:Show(); row:ClearAllPoints(); row:SetPoint("TOPLEFT", 10, -48); row:SetPoint("RIGHT", -10, 0)
        row.nameText:SetText("No real players detected."); row.nameText:SetTextColor(C.dim[1], C.dim[2], C.dim[3]); row.classText:SetText("")
        if row.roleDD then row.roleDD:Hide() end
    else
        for index, human in ipairs(humans) do
            local humanValue = human
            local row = EnsureHumanRow(index); row:Show(); row:ClearAllPoints(); row:SetPoint("TOPLEFT", 10, -48 - (index - 1) * 36); row:SetPoint("RIGHT", -10, 0)
            row.nameText:SetText(humanValue.name or "?")
            local nameColor = humanValue.isPlayer and C.gold or C.text
            row.nameText:SetTextColor(nameColor[1], nameColor[2], nameColor[3])
            row.classText:SetText(D.CLASS_LABEL[humanValue.class] or humanValue.class or "Unknown")
            if row.roleDD then row.roleDD:Hide(); row.roleDD:SetParent(nil); row.roleDD = nil end
            local roleDD
            roleDD = Dropdown(row, 130, function() return RoleItems(true) end,
                function() return config.humanRoles[humanValue.name] or humanValue.role or "AUTO" end,
                function(value) GC:SetHumanRole(humanValue.name, value); roleDD:Refresh() end)
            roleDD:SetPoint("RIGHT", -10, -2); row.roleDD = roleDD
        end
    end

    top = top + humanHeight + 12
    local extraCount = math.max(1, #(config.extraHumans or {}))
    local extraHeight = 82 + extraCount * 32 + 10
    extraSection:ClearAllPoints(); extraSection:SetPoint("TOPLEFT", 10, -top); extraSection:SetWidth(975); extraSection:SetHeight(extraHeight)
    if #config.extraHumans == 0 then
        local row = EnsureExtraRow(1); row:Show(); row:ClearAllPoints(); row:SetPoint("TOPLEFT", 10, -76); row:SetPoint("RIGHT", -10, 0)
        row.label:SetText("No additional humans selected."); row.label:SetTextColor(C.dim[1], C.dim[2], C.dim[3]); row.remove:Hide()
    else
        for index, extra in ipairs(config.extraHumans) do
            local rowIndex = index
            local row = EnsureExtraRow(index); row:Show(); row:ClearAllPoints(); row:SetPoint("TOPLEFT", 10, -76 - (index - 1) * 32); row:SetPoint("RIGHT", -10, 0)
            row.label:SetText(extra.name .. "  •  " .. (D.ROLE_LABEL[extra.role] or extra.role)); row.label:SetTextColor(C.text[1], C.text[2], C.text[3])
            row.remove:Show(); row.remove:SetScript("OnClick", function() GC:RemoveExtraHuman(rowIndex) end)
        end
    end

    top = top + extraHeight + 12
    local pinCount = math.max(1, #(config.pinned or {}))
    local pinHeight = 82 + pinCount * 34 + 10
    pinSection:ClearAllPoints(); pinSection:SetPoint("TOPLEFT", 10, -top); pinSection:SetWidth(975); pinSection:SetHeight(pinHeight)
    if #config.pinned == 0 then
        local row = EnsurePinRow(1); row:Show(); row:ClearAllPoints(); row:SetPoint("TOPLEFT", 10, -76); row:SetPoint("RIGHT", -10, 0)
        row.nameText:SetText("No persistent guild companions pinned."); row.nameText:SetTextColor(C.dim[1], C.dim[2], C.dim[3]); row.roleText:SetText(""); row.required:Hide(); row.remove:Hide()
    else
        for index, pin in ipairs(config.pinned) do
            local rowIndex, pinValue = index, pin
            local row = EnsurePinRow(index); row:Show(); row:ClearAllPoints(); row:SetPoint("TOPLEFT", 10, -76 - (index - 1) * 34); row:SetPoint("RIGHT", -10, 0)
            row.nameText:SetText(pinValue.name); row.nameText:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
            row.roleText:SetText(D.ROLE_LABEL[pinValue.role] or pinValue.role); local color = ROLE_COLOR[pinValue.role] or C.text; row.roleText:SetTextColor(color[1], color[2], color[3])
            row.required:Show(); row.required:SetChecked(pinValue.required and true or false)
            row.required:SetScript("OnClick", function(self) pinValue.required = self:GetChecked() and true or false; GC:Touch("Pinned member changed") end)
            row.remove:Show(); row.remove:SetScript("OnClick", function() GC:RemovePinnedMember(rowIndex) end)
        end
    end

    top = top + pinHeight + 12
    rulesSection:ClearAllPoints(); rulesSection:SetPoint("TOPLEFT", 10, -top); rulesSection:SetWidth(975); rulesSection:SetHeight(112)
    utilityCheck:SetChecked(config.options.balanceUtility and true or false)
    rangeCheck:SetChecked(config.options.balanceRange and true or false)
    guildCheck:SetChecked(config.options.preferGuild and true or false)
    worldCheck:SetChecked(config.options.fillWorld and true or false)
    queueCheck:SetChecked(config.options.queueAfterAssemble and true or false)

    content:SetHeight(top + 124)
end

A:RefreshPeople()

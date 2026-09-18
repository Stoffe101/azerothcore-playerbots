--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]

local ____modules = {}
local ____moduleCache = {}
local ____originalRequire = require
local function require(file, ...)
    if ____moduleCache[file] then
        return ____moduleCache[file].value
    end
    if ____modules[file] then
        local module = ____modules[file]
        local value = nil
        if (select("#", ...) > 0) then value = module(...) else value = module(file) end
        ____moduleCache[file] = { value = value }
        return value
    else
        if ____originalRequire then
            return ____originalRequire(file)
        else
            error("module '" .. file .. "' not found")
        end
    end
end
____modules = {
["theme.Theme"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
____exports.theme = {spacing = {
    xs = 4,
    sm = 8,
    md = 12,
    lg = 16,
    xl = 24
}, control = {sm = 28, md = 36, lg = 44}, colors = {
    background = {0.008, 0.013, 0.02, 0.992},
    scrim = {0, 0, 0, 0.62},
    surface = {0.02, 0.03, 0.043, 1},
    surfaceRaised = {0.034, 0.049, 0.068, 1},
    surfaceHover = {0.05, 0.074, 0.102, 1},
    border = {0.07, 0.1, 0.138, 1},
    borderStrong = {0.13, 0.195, 0.27, 1},
    text = {0.94, 0.96, 0.99, 1},
    muted = {0.58, 0.65, 0.74, 1},
    primary = {0.22, 0.62, 1, 1},
    success = {0.2, 0.82, 0.45, 1},
    warning = {0.95, 0.67, 0.2, 1},
    error = {0.93, 0.28, 0.31, 1},
    tank = {0.2, 0.58, 0.98, 1},
    healer = {0.18, 0.78, 0.42, 1},
    dps = {0.91, 0.31, 0.3, 1}
}}
return ____exports
 end,
["core.Native"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
____exports.CLASS_ICON_ATLAS = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
function ____exports.setTextureColor(self, texture, color)
    texture:SetTexture(color[1], color[2], color[3], color[4])
end
function ____exports.createSolid(self, parent, color, layer)
    if layer == nil then
        layer = "BACKGROUND"
    end
    local texture = parent:CreateTexture(nil, layer)
    ____exports.setTextureColor(nil, texture, color)
    return texture
end
function ____exports.createText(self, parent, value, template, color)
    if template == nil then
        template = "GameFontHighlightSmall"
    end
    if color == nil then
        color = theme.colors.text
    end
    local text = parent:CreateFontString(nil, "OVERLAY", template)
    text:SetText(value)
    text:SetTextColor(color[1], color[2], color[3], color[4])
    text:SetJustifyH("LEFT")
    text:SetJustifyV("MIDDLE")
    return text
end
function ____exports.createOutline(self, frame, initial)
    if initial == nil then
        initial = theme.colors.border
    end
    local top = ____exports.createSolid(nil, frame, initial, "BORDER")
    local bottom = ____exports.createSolid(nil, frame, initial, "BORDER")
    local left = ____exports.createSolid(nil, frame, initial, "BORDER")
    local right = ____exports.createSolid(nil, frame, initial, "BORDER")
    top:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        0,
        0
    )
    top:SetPoint(
        "TOPRIGHT",
        frame,
        "TOPRIGHT",
        0,
        0
    )
    top:SetHeight(1)
    bottom:SetPoint(
        "BOTTOMLEFT",
        frame,
        "BOTTOMLEFT",
        0,
        0
    )
    bottom:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        0,
        0
    )
    bottom:SetHeight(1)
    left:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        0,
        0
    )
    left:SetPoint(
        "BOTTOMLEFT",
        frame,
        "BOTTOMLEFT",
        0,
        0
    )
    left:SetWidth(1)
    right:SetPoint(
        "TOPRIGHT",
        frame,
        "TOPRIGHT",
        0,
        0
    )
    right:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        0,
        0
    )
    right:SetWidth(1)
    local textures = {top, bottom, left, right}
    return {
        textures = textures,
        setColor = function(self, color)
            for ____, texture in ipairs(textures) do
                ____exports.setTextureColor(nil, texture, color)
            end
        end
    }
end
function ____exports.createPanel(self, parent, backgroundColor, borderColor)
    if backgroundColor == nil then
        backgroundColor = theme.colors.surface
    end
    if borderColor == nil then
        borderColor = theme.colors.border
    end
    local frame = CreateFrame("Frame", nil, parent)
    local background = ____exports.createSolid(nil, frame, backgroundColor)
    background:SetAllPoints(frame)
    local outline = ____exports.createOutline(nil, frame, borderColor)
    return {
        frame = frame,
        background = background,
        outline = outline,
        setBackground = function(self, color)
            ____exports.setTextureColor(nil, background, color)
        end
    }
end
function ____exports.createIcon(self, parent, path, size)
    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(path)
    icon:SetSize(size, size)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    return icon
end
function ____exports.setClassIcon(self, texture, classToken)
    texture:SetTexture(____exports.CLASS_ICON_ATLAS)
    local coords = CLASS_ICON_TCOORDS[classToken]
    if coords ~= nil and #coords >= 4 then
        texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    else
        texture:SetTexCoord(0, 1, 0, 1)
    end
end
function ____exports.classColor(self, classToken)
    local color = RAID_CLASS_COLORS[classToken]
    if color ~= nil then
        return {color.r, color.g, color.b, 1}
    end
    return theme.colors.primary
end
return ____exports
 end,
["data.WotlkBuilds"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
____exports.CLASS_ORDER = {
    {id = "WARRIOR", label = "Warrior", specs = {{id = 0, label = "Arms", icon = "Interface\\Icons\\Ability_Warrior_SavageBlow", roles = {"DPS"}}, {id = 1, label = "Fury", icon = "Interface\\Icons\\Ability_Warrior_InnerRage", roles = {"DPS"}}, {id = 2, label = "Protection", icon = "Interface\\Icons\\Ability_Warrior_DefensiveStance", roles = {"TANK"}}}},
    {id = "PALADIN", label = "Paladin", specs = {{id = 0, label = "Holy", icon = "Interface\\Icons\\Spell_Holy_HolyBolt", roles = {"HEALER"}}, {id = 1, label = "Protection", icon = "Interface\\Icons\\Spell_Holy_DevotionAura", roles = {"TANK"}}, {id = 2, label = "Retribution", icon = "Interface\\Icons\\Spell_Holy_AuraOfLight", roles = {"DPS"}}}},
    {id = "HUNTER", label = "Hunter", specs = {{id = 0, label = "Beast Mastery", icon = "Interface\\Icons\\Ability_Hunter_BeastCall", roles = {"DPS"}}, {id = 1, label = "Marksmanship", icon = "Interface\\Icons\\Ability_Marksmanship", roles = {"DPS"}}, {id = 2, label = "Survival", icon = "Interface\\Icons\\Ability_Hunter_SwiftStrike", roles = {"DPS"}}}},
    {id = "ROGUE", label = "Rogue", specs = {{id = 0, label = "Assassination", icon = "Interface\\Icons\\Ability_Rogue_Eviscerate", roles = {"DPS"}}, {id = 1, label = "Combat", icon = "Interface\\Icons\\Ability_BackStab", roles = {"DPS"}}, {id = 2, label = "Subtlety", icon = "Interface\\Icons\\Ability_Stealth", roles = {"DPS"}}}},
    {id = "PRIEST", label = "Priest", specs = {{id = 0, label = "Discipline", icon = "Interface\\Icons\\Spell_Holy_PowerWordShield", roles = {"HEALER"}}, {id = 1, label = "Holy", icon = "Interface\\Icons\\Spell_Holy_GuardianSpirit", roles = {"HEALER"}}, {id = 2, label = "Shadow", icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain", roles = {"DPS"}}}},
    {id = "DEATHKNIGHT", label = "Death Knight", specs = {{id = 0, label = "Blood", icon = "Interface\\Icons\\Spell_Deathknight_BloodPresence", roles = {"TANK"}}, {id = 1, label = "Frost", icon = "Interface\\Icons\\Spell_Deathknight_FrostPresence", roles = {"DPS"}}, {id = 2, label = "Unholy", icon = "Interface\\Icons\\Spell_Deathknight_UnholyPresence", roles = {"DPS"}}}},
    {id = "SHAMAN", label = "Shaman", specs = {{id = 0, label = "Elemental", icon = "Interface\\Icons\\Spell_Nature_Lightning", roles = {"DPS"}}, {id = 1, label = "Enhancement", icon = "Interface\\Icons\\Spell_Nature_LightningShield", roles = {"DPS"}}, {id = 2, label = "Restoration", icon = "Interface\\Icons\\Spell_Nature_HealingWaveGreater", roles = {"HEALER"}}}},
    {id = "MAGE", label = "Mage", specs = {{id = 0, label = "Arcane", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry", roles = {"DPS"}}, {id = 1, label = "Fire", icon = "Interface\\Icons\\Spell_Fire_FireBolt02", roles = {"DPS"}}, {id = 2, label = "Frost", icon = "Interface\\Icons\\Spell_Frost_FrostBolt02", roles = {"DPS"}}}},
    {id = "WARLOCK", label = "Warlock", specs = {{id = 0, label = "Affliction", icon = "Interface\\Icons\\Spell_Shadow_DeathCoil", roles = {"DPS"}}, {id = 1, label = "Demonology", icon = "Interface\\Icons\\Spell_Shadow_Metamorphosis", roles = {"DPS"}}, {id = 2, label = "Destruction", icon = "Interface\\Icons\\Spell_Fire_Immolation", roles = {"DPS"}}}},
    {id = "DRUID", label = "Druid", specs = {{id = 0, label = "Balance", icon = "Interface\\Icons\\Spell_Nature_StarFall", roles = {"DPS"}}, {id = 1, label = "Feral", icon = "Interface\\Icons\\Ability_Druid_CatForm", roles = {"TANK", "DPS"}}, {id = 2, label = "Restoration", icon = "Interface\\Icons\\Spell_Nature_HealingTouch", roles = {"HEALER"}}}}
}
function ____exports.specSupportsRole(spec, role)
    for ____, supported in ipairs(spec.roles) do
        if supported == role then
            return true
        end
    end
    return false
end
function ____exports.getClassesForRole(role)
    local result = {}
    for ____, classDef in ipairs(____exports.CLASS_ORDER) do
        for ____, spec in ipairs(classDef.specs) do
            if ____exports.specSupportsRole(spec, role) then
                result[#result + 1] = classDef
                break
            end
        end
    end
    return result
end
function ____exports.getSpecsForRole(classId, role)
    local result = {}
    for ____, classDef in ipairs(____exports.CLASS_ORDER) do
        do
            local __continue13
            repeat
                if classDef.id ~= classId then
                    __continue13 = true
                    break
                end
                for ____, spec in ipairs(classDef.specs) do
                    if ____exports.specSupportsRole(spec, role) then
                        result[#result + 1] = spec
                    end
                end
                break
            until true
            if not __continue13 then
                break
            end
        end
    end
    return result
end
function ____exports.getClass(classId)
    for ____, classDef in ipairs(____exports.CLASS_ORDER) do
        if classDef.id == classId then
            return classDef
        end
    end
    return nil
end
return ____exports
 end,
["widgets.Button"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____Native = require("core.Native")
local createOutline = ____Native.createOutline
local createSolid = ____Native.createSolid
local createText = ____Native.createText
local setTextureColor = ____Native.setTextureColor
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
function ____exports.createButton(self, parent, options)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetSize(options.width, options.height)
    frame:EnableMouse(true)
    local background = createSolid(nil, frame, theme.colors.surfaceRaised)
    background:SetAllPoints(frame)
    local outline = createOutline(nil, frame, theme.colors.border)
    local activeEdge = createSolid(nil, frame, options.accent or theme.colors.primary, "OVERLAY")
    activeEdge:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        0,
        0
    )
    activeEdge:SetPoint(
        "BOTTOMLEFT",
        frame,
        "BOTTOMLEFT",
        0,
        0
    )
    activeEdge:SetWidth(3)
    activeEdge:Hide()
    local label = createText(nil, frame, options.text, options.height >= 34 and "GameFontHighlight" or "GameFontHighlightSmall")
    label:SetPoint(
        "CENTER",
        frame,
        "CENTER",
        0,
        0
    )
    label:SetJustifyH("CENTER")
    local selected = false
    local enabled = true
    local accent = options.accent or theme.colors.primary
    local function render(self)
        frame:SetAlpha(enabled and 1 or 0.48)
        outline:setColor(selected and accent or theme.colors.border)
        setTextureColor(nil, background, selected and theme.colors.surfaceHover or theme.colors.surfaceRaised)
        if selected then
            activeEdge:Show()
        else
            activeEdge:Hide()
        end
        local color = selected and accent or theme.colors.text
        label:SetTextColor(color[1], color[2], color[3], 1)
    end
    frame:SetScript(
        "OnEnter",
        function()
            if enabled and not selected then
                setTextureColor(nil, background, theme.colors.surfaceHover)
                outline:setColor(theme.colors.borderStrong)
            end
        end
    )
    frame:SetScript(
        "OnLeave",
        function() return render(nil) end
    )
    frame:SetScript(
        "OnMouseDown",
        function()
            if enabled and options.onClick ~= nil then
                options:onClick()
            end
        end
    )
    render(nil)
    return {
        frame = frame,
        label = label,
        setSelected = function(self, value)
            selected = value
            render(nil)
        end,
        setEnabled = function(self, value)
            enabled = value
            render(nil)
        end,
        setText = function(self, value)
            label:SetText(value)
        end
    }
end
return ____exports
 end,
["widgets.ChoiceSelect"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__Number(value)
    local valueType = type(value)
    if valueType == "number" then
        return value
    elseif valueType == "string" then
        local numberValue = tonumber(value)
        if numberValue then
            return numberValue
        end
        if value == "Infinity" then
            return math.huge
        end
        if value == "-Infinity" then
            return -math.huge
        end
        local stringWithoutSpaces = string.gsub(value, "%s", "")
        if stringWithoutSpaces == "" then
            return 0
        end
        return 0 / 0
    elseif valueType == "boolean" then
        return value and 1 or 0
    else
        return 0 / 0
    end
end
-- End of Lua Library inline imports
local ____exports = {}
local ____Native = require("core.Native")
local createPanel = ____Native.createPanel
local createSolid = ____Native.createSolid
local createText = ____Native.createText
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
local ____Button = require("widgets.Button")
local createButton = ____Button.createButton
local activePopup
local function closeActive(self)
    if activePopup ~= nil then
        activePopup:Hide()
        activePopup = nil
    end
end
function ____exports.closeChoicePopup(self)
    closeActive(nil)
end
function ____exports.createChoiceSelect(self, parent, options)
    local move, wheel, bindWheel, refreshRail, refreshRows, refresh, trigger, popup, maxVisible, rowHeight, railWidth, offset, rows, rail, up, down, thumb
    function move(self, delta)
        local items = options:getItems()
        local maxOffset = math.max(0, #items - maxVisible)
        offset = math.max(
            0,
            math.min(maxOffset, offset + delta)
        )
        refreshRows(nil)
    end
    function wheel(self, _frame, delta)
        move(
            nil,
            __TS__Number(delta) > 0 and -1 or 1
        )
    end
    function bindWheel(self, target)
        target:EnableMouseWheel(true)
        target:SetScript("OnMouseWheel", wheel)
    end
    function refreshRail(self)
        local items = options:getItems()
        local maxOffset = math.max(0, #items - maxVisible)
        local canScroll = maxOffset > 0
        up:setEnabled(canScroll and offset > 0)
        down:setEnabled(canScroll and offset < maxOffset)
        if not canScroll then
            rail.frame:Hide()
            return
        end
        rail.frame:Show()
        local popupHeight = popup.frame:GetHeight()
        local trackHeight = math.max(36, popupHeight - 58)
        local thumbHeight = math.max(
            22,
            math.floor(trackHeight * math.min(1, maxVisible / #items))
        )
        local travel = math.max(0, trackHeight - thumbHeight)
        local ratio = maxOffset > 0 and offset / maxOffset or 0
        thumb:SetHeight(thumbHeight)
        thumb:ClearAllPoints()
        thumb:SetPoint(
            "TOP",
            up.frame,
            "BOTTOM",
            0,
            -(4 + travel * ratio)
        )
        thumb:Show()
    end
    function refreshRows(self)
        local items = options:getItems()
        local visible = math.min(maxVisible, #items)
        popup.frame:SetHeight(math.max(16, visible * rowHeight + 8))
        do
            local i = 0
            while i < maxVisible do
                local row = rows[i + 1]
                if row == nil then
                    local button = createButton(nil, popup.frame, {text = "", width = options.width - railWidth - 12, height = rowHeight - 4})
                    button.frame:SetPoint(
                        "TOPLEFT",
                        popup.frame,
                        "TOPLEFT",
                        4,
                        -(4 + i * rowHeight)
                    )
                    button.label:ClearAllPoints()
                    button.label:SetPoint(
                        "TOPLEFT",
                        button.frame,
                        "TOPLEFT",
                        10,
                        -7
                    )
                    button.label:SetPoint(
                        "RIGHT",
                        button.frame,
                        "RIGHT",
                        -8,
                        7
                    )
                    button.label:SetJustifyH("LEFT")
                    local detail = createText(
                        nil,
                        button.frame,
                        "",
                        "GameFontHighlightSmall",
                        theme.colors.muted
                    )
                    detail:SetPoint(
                        "TOPLEFT",
                        button.frame,
                        "TOPLEFT",
                        10,
                        -25
                    )
                    detail:SetPoint(
                        "RIGHT",
                        button.frame,
                        "RIGHT",
                        -8,
                        0
                    )
                    detail:SetJustifyH("LEFT")
                    bindWheel(nil, button.frame)
                    row = {button = button, detail = detail}
                    rows[i + 1] = row
                end
                local item = items[offset + i + 1]
                if item ~= nil then
                    row.button:setText(item.label)
                    row.detail:SetText(item.detail or "")
                    row.button:setSelected(item.value == options:getValue())
                    local value = item.value
                    row.button.frame:SetScript(
                        "OnMouseDown",
                        function()
                            options:onChange(value)
                            closeActive(nil)
                            refresh(nil)
                        end
                    )
                    row.button.frame:Show()
                else
                    row.button.frame:Hide()
                end
                i = i + 1
            end
        end
        refreshRail(nil)
    end
    function refresh(self)
        local value = options:getValue()
        local label = "Select"
        for ____, item in ipairs(options:getItems()) do
            if item.value == value then
                label = item.label
                break
            end
        end
        trigger:setText(label)
        refreshRows(nil)
    end
    trigger = createButton(nil, parent, {text = "Select", width = options.width, height = 36})
    trigger.label:ClearAllPoints()
    trigger.label:SetPoint(
        "LEFT",
        trigger.frame,
        "LEFT",
        12,
        0
    )
    trigger.label:SetPoint(
        "RIGHT",
        trigger.frame,
        "RIGHT",
        -32,
        0
    )
    trigger.label:SetJustifyH("LEFT")
    local arrow = createText(
        nil,
        trigger.frame,
        "v",
        "GameFontHighlightSmall",
        theme.colors.muted
    )
    arrow:SetPoint(
        "RIGHT",
        trigger.frame,
        "RIGHT",
        -11,
        0
    )
    popup = createPanel(nil, trigger.frame, theme.colors.background, theme.colors.borderStrong)
    popup.frame:SetFrameStrata("TOOLTIP")
    popup.frame:SetWidth(options.width)
    popup.frame:EnableMouseWheel(true)
    popup.frame:Hide()
    maxVisible = options.maxVisible or 8
    rowHeight = 48
    railWidth = 24
    offset = 0
    rows = {}
    rail = createPanel(nil, popup.frame, theme.colors.surface, theme.colors.border)
    rail.frame:SetPoint(
        "TOPRIGHT",
        popup.frame,
        "TOPRIGHT",
        -4,
        -4
    )
    rail.frame:SetPoint(
        "BOTTOMRIGHT",
        popup.frame,
        "BOTTOMRIGHT",
        -4,
        4
    )
    rail.frame:SetWidth(railWidth)
    up = createButton(
        nil,
        rail.frame,
        {
            text = "^",
            width = 20,
            height = 22,
            onClick = function() return move(nil, -1) end
        }
    )
    up.frame:SetPoint(
        "TOP",
        rail.frame,
        "TOP",
        0,
        -2
    )
    down = createButton(
        nil,
        rail.frame,
        {
            text = "v",
            width = 20,
            height = 22,
            onClick = function() return move(nil, 1) end
        }
    )
    down.frame:SetPoint(
        "BOTTOM",
        rail.frame,
        "BOTTOM",
        0,
        2
    )
    local track = createSolid(nil, rail.frame, theme.colors.borderStrong, "ARTWORK")
    track:SetPoint(
        "TOP",
        up.frame,
        "BOTTOM",
        0,
        -4
    )
    track:SetPoint(
        "BOTTOM",
        down.frame,
        "TOP",
        0,
        4
    )
    track:SetWidth(4)
    thumb = createSolid(nil, rail.frame, theme.colors.primary, "OVERLAY")
    thumb:SetWidth(6)
    thumb:SetHeight(22)
    local function open(self)
        closeActive(nil)
        local items = options:getItems()
        local selected = options:getValue()
        local selectedIndex = 0
        do
            local i = 0
            while i < #items do
                if items[i + 1].value == selected then
                    selectedIndex = i
                    break
                end
                i = i + 1
            end
        end
        local maxOffset = math.max(0, #items - maxVisible)
        offset = math.max(
            0,
            math.min(
                maxOffset,
                selectedIndex - math.floor(maxVisible / 2)
            )
        )
        refreshRows(nil)
        popup.frame:ClearAllPoints()
        popup.frame:SetPoint(
            "TOPLEFT",
            trigger.frame,
            "BOTTOMLEFT",
            0,
            -4
        )
        popup.frame:Show()
        activePopup = popup.frame
    end
    trigger.frame:SetScript(
        "OnMouseDown",
        function()
            if popup.frame:IsShown() then
                closeActive(nil)
            else
                open(nil)
            end
        end
    )
    bindWheel(nil, popup.frame)
    bindWheel(nil, rail.frame)
    bindWheel(nil, up.frame)
    bindWheel(nil, down.frame)
    refresh(nil)
    return {
        frame = trigger.frame,
        refresh = function() return refresh(nil) end,
        close = function()
            if popup.frame:IsShown() then
                closeActive(nil)
            end
        end
    }
end
return ____exports
 end,
["model.ComposerModel"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local __TS__Symbol, Symbol
do
    local symbolMetatable = {__tostring = function(self)
        return ("Symbol(" .. (self.description or "")) .. ")"
    end}
    function __TS__Symbol(description)
        return setmetatable({description = description}, symbolMetatable)
    end
    Symbol = {
        asyncDispose = __TS__Symbol("Symbol.asyncDispose"),
        dispose = __TS__Symbol("Symbol.dispose"),
        iterator = __TS__Symbol("Symbol.iterator"),
        hasInstance = __TS__Symbol("Symbol.hasInstance"),
        species = __TS__Symbol("Symbol.species"),
        toStringTag = __TS__Symbol("Symbol.toStringTag")
    }
end

local __TS__Iterator
do
    local function iteratorGeneratorStep(self)
        local co = self.____coroutine
        local status, value = coroutine.resume(co)
        if not status then
            error(value, 0)
        end
        if coroutine.status(co) == "dead" then
            return
        end
        return true, value
    end
    local function iteratorIteratorStep(self)
        local result = self:next()
        if result.done then
            return
        end
        return true, result.value
    end
    local function iteratorStringStep(self, index)
        index = index + 1
        if index > #self then
            return
        end
        return index, string.sub(self, index, index)
    end
    function __TS__Iterator(iterable)
        if type(iterable) == "string" then
            return iteratorStringStep, iterable, 0
        elseif iterable.____coroutine ~= nil then
            return iteratorGeneratorStep, iterable
        elseif iterable[Symbol.iterator] then
            local iterator = iterable[Symbol.iterator](iterable)
            return iteratorIteratorStep, iterator
        else
            return ipairs(iterable)
        end
    end
end

local function __TS__Number(value)
    local valueType = type(value)
    if valueType == "number" then
        return value
    elseif valueType == "string" then
        local numberValue = tonumber(value)
        if numberValue then
            return numberValue
        end
        if value == "Infinity" then
            return math.huge
        end
        if value == "-Infinity" then
            return -math.huge
        end
        local stringWithoutSpaces = string.gsub(value, "%s", "")
        if stringWithoutSpaces == "" then
            return 0
        end
        return 0 / 0
    elseif valueType == "boolean" then
        return value and 1 or 0
    else
        return 0 / 0
    end
end

local function __TS__CountVarargs(...)
    return select("#", ...)
end

local function __TS__ArraySplice(self, ...)
    local args = {...}
    local len = #self
    local actualArgumentCount = __TS__CountVarargs(...)
    local start = args[1]
    local deleteCount = args[2]
    if start < 0 then
        start = len + start
        if start < 0 then
            start = 0
        end
    elseif start > len then
        start = len
    end
    local itemCount = actualArgumentCount - 2
    if itemCount < 0 then
        itemCount = 0
    end
    local actualDeleteCount
    if actualArgumentCount == 0 then
        actualDeleteCount = 0
    elseif actualArgumentCount == 1 then
        actualDeleteCount = len - start
    else
        actualDeleteCount = deleteCount or 0
        if actualDeleteCount < 0 then
            actualDeleteCount = 0
        end
        if actualDeleteCount > len - start then
            actualDeleteCount = len - start
        end
    end
    local out = {}
    for k = 1, actualDeleteCount do
        local from = start + k
        if self[from] ~= nil then
            out[k] = self[from]
        end
    end
    if itemCount < actualDeleteCount then
        for k = start + 1, len - actualDeleteCount do
            local from = k + actualDeleteCount
            local to = k + itemCount
            if self[from] then
                self[to] = self[from]
            else
                self[to] = nil
            end
        end
        for k = len - actualDeleteCount + itemCount + 1, len do
            self[k] = nil
        end
    elseif itemCount > actualDeleteCount then
        for k = len - actualDeleteCount, start + 1, -1 do
            local from = k + actualDeleteCount
            local to = k + itemCount
            if self[from] then
                self[to] = self[from]
            else
                self[to] = nil
            end
        end
    end
    local j = start + 1
    for i = 3, actualArgumentCount do
        self[j] = args[i]
        j = j + 1
    end
    for k = #self, len - actualDeleteCount + itemCount + 1, -1 do
        self[k] = nil
    end
    return out
end

local function __TS__ArrayIsArray(value)
    return type(value) == "table" and (value[1] ~= nil or next(value) == nil)
end

local function __TS__ArrayConcat(self, ...)
    local items = {...}
    local result = {}
    local len = 0
    for i = 1, #self do
        len = len + 1
        result[len] = self[i]
    end
    for i = 1, #items do
        local item = items[i]
        if __TS__ArrayIsArray(item) then
            for j = 1, #item do
                len = len + 1
                result[len] = item[j]
            end
        else
            len = len + 1
            result[len] = item
        end
    end
    return result
end
-- End of Lua Library inline imports
local ____exports = {}
local ____WotlkBuilds = require("data.WotlkBuilds")
local getClass = ____WotlkBuilds.getClass
local getSpecsForRole = ____WotlkBuilds.getSpecsForRole
function ____exports.roleLabel(self, role)
    if role == "TANK" then
        return "Tank"
    end
    if role == "HEALER" then
        return "Healer"
    end
    return "DPS"
end
____exports.ANY_SPEC_ID = -1
local GC = _G.GroupComposer
local D = _G.GroupComposerData
local DataFns = _G.GroupComposerData
local P = _G.GroupComposerProfiles
local ProfileFns = _G.GroupComposerProfiles
function ____exports.composer(self)
    return GC
end
function ____exports.data(self)
    return D
end
function ____exports.profiles(self)
    return P
end
function ____exports.config(self)
    return GC:GetConfig()
end
function ____exports.plan(self)
    local ____GC_plan_0 = GC.plan
    if ____GC_plan_0 == nil then
        ____GC_plan_0 = {
            members = {},
            warnings = {},
            summary = {},
            valid = false,
            ready = false
        }
    end
    return ____GC_plan_0
end
function ____exports.progress(self)
    local ____GC_progress_1 = GC.progress
    if ____GC_progress_1 == nil then
        ____GC_progress_1 = {phase = "IDLE", current = 0, total = 0, detail = ""}
    end
    return ____GC_progress_1
end
function ____exports.touch(self, reason)
    GC:Touch(reason)
end
function ____exports.fireStatus(self, text)
    GC:Fire("STATUS", text)
end
function ____exports.humans(self)
    local ____temp_2 = GC:ScanHumans()
    if ____temp_2 == nil then
        ____temp_2 = {}
    end
    return ____temp_2
end
function ____exports.humanReady(self)
    local list = ____exports.humans(nil)
    if #list == 0 then
        return false
    end
    local ____exports_config_result_humanRoles_3 = ____exports.config(nil).humanRoles
    if ____exports_config_result_humanRoles_3 == nil then
        ____exports_config_result_humanRoles_3 = {}
    end
    local roles = ____exports_config_result_humanRoles_3
    for ____, human in ipairs(list) do
        if roles[human.name] == nil then
            return false
        end
    end
    return true
end
function ____exports.humanRoleCounts(self)
    local result = {TANK = 0, HEALER = 0, DPS = 0}
    local ____exports_config_result_humanRoles_4 = ____exports.config(nil).humanRoles
    if ____exports_config_result_humanRoles_4 == nil then
        ____exports_config_result_humanRoles_4 = {}
    end
    local roles = ____exports_config_result_humanRoles_4
    local seen = {}
    for ____, human in ipairs(____exports.humans(nil)) do
        local key = string.lower(tostring(human.name or ""))
        local role = roles[human.name]
        if key ~= "" and role ~= nil and seen[key] ~= true then
            seen[key] = true
            result[role] = result[role] + 1
        end
    end
    local ____exports_config_result_extraHumans_6 = ____exports.config(nil).extraHumans
    if ____exports_config_result_extraHumans_6 == nil then
        ____exports_config_result_extraHumans_6 = {}
    end
    for ____, extra in __TS__Iterator(____exports_config_result_extraHumans_6) do
        local ____extra_name_5 = extra.name
        if ____extra_name_5 == nil then
            ____extra_name_5 = ""
        end
        local key = string.lower(tostring(____extra_name_5))
        local role = extra.role
        if key ~= "" and role ~= nil and seen[key] ~= true then
            seen[key] = true
            result[role] = result[role] + 1
        end
    end
    return result
end
function ____exports.targetForRole(self, role)
    local cfg = ____exports.config(nil)
    if role == "TANK" then
        local ____cfg_tanks_7 = cfg.tanks
        if ____cfg_tanks_7 == nil then
            ____cfg_tanks_7 = 0
        end
        return __TS__Number(____cfg_tanks_7)
    end
    if role == "HEALER" then
        local ____cfg_healers_8 = cfg.healers
        if ____cfg_healers_8 == nil then
            ____cfg_healers_8 = 0
        end
        return __TS__Number(____cfg_healers_8)
    end
    local ____cfg_dps_9 = cfg.dps
    if ____cfg_dps_9 == nil then
        ____cfg_dps_9 = 0
    end
    return __TS__Number(____cfg_dps_9)
end
function ____exports.roleTargetTotal(self)
    local cfg = ____exports.config(nil)
    local ____cfg_tanks_10 = cfg.tanks
    if ____cfg_tanks_10 == nil then
        ____cfg_tanks_10 = 0
    end
    local ____TS__Number_result_12 = __TS__Number(____cfg_tanks_10)
    local ____cfg_healers_11 = cfg.healers
    if ____cfg_healers_11 == nil then
        ____cfg_healers_11 = 0
    end
    local ____temp_14 = ____TS__Number_result_12 + __TS__Number(____cfg_healers_11)
    local ____cfg_dps_13 = cfg.dps
    if ____cfg_dps_13 == nil then
        ____cfg_dps_13 = 0
    end
    return ____temp_14 + __TS__Number(____cfg_dps_13)
end
function ____exports.setRoleTarget(self, role, value)
    local cfg = ____exports.config(nil)
    local ____cfg_size_15 = cfg.size
    if ____cfg_size_15 == nil then
        ____cfg_size_15 = 40
    end
    local next = math.max(
        0,
        math.min(
            __TS__Number(____cfg_size_15),
            math.floor(value)
        )
    )
    if role == "TANK" then
        cfg.tanks = next
    elseif role == "HEALER" then
        cfg.healers = next
    else
        cfg.dps = next
    end
    ____exports.touch(nil, "Role composition changed")
end
function ____exports.resetRoleTargets(self)
    local cfg = ____exports.config(nil)
    local ____cfg_size_16 = cfg.size
    if ____cfg_size_16 == nil then
        ____cfg_size_16 = 25
    end
    local size = __TS__Number(____cfg_size_16)
    if size == 10 then
        cfg.tanks = 2
        cfg.healers = 2
        cfg.dps = 6
    elseif size == 20 then
        cfg.tanks = 3
        cfg.healers = 5
        cfg.dps = 12
    elseif size == 40 then
        cfg.tanks = 5
        cfg.healers = 10
        cfg.dps = 25
    elseif size == 5 then
        cfg.tanks = 1
        cfg.healers = 1
        cfg.dps = 3
    else
        cfg.tanks = 2
        cfg.healers = 6
        cfg.dps = math.max(0, size - 8)
    end
    ____exports.touch(nil, "Role composition reset")
end
function ____exports.remainingBotSlots(self, role)
    local counts = ____exports.humanRoleCounts(nil)
    return math.max(
        0,
        ____exports.targetForRole(nil, role) - counts[role]
    )
end
local function rawRequired(self, role)
    local result = {}
    local ____opt_17 = ____exports.config(nil).preferences
    if ____opt_17 ~= nil then
        ____opt_17 = ____opt_17[role]
    end
    local ____opt_17_19 = ____opt_17
    if ____opt_17_19 == nil then
        ____opt_17_19 = {}
    end
    local list = ____opt_17_19
    for ____, pref in __TS__Iterator(list) do
        if pref.required == true and pref.class ~= nil and pref.class ~= "ANY" then
            if type(pref.spec) == "number" then
                result[#result + 1] = pref
            else
                local ____pref_spec_20 = pref.spec
                if ____pref_spec_20 == nil then
                    ____pref_spec_20 = ""
                end
                if string.upper(tostring(____pref_spec_20)) == "ANY" then
                    result[#result + 1] = {class = pref.class, spec = ____exports.ANY_SPEC_ID, required = true}
                end
            end
        end
    end
    return result
end
function ____exports.requiredBuilds(self, role)
    local result = {}
    for ____, pref in ipairs(rawRequired(nil, role)) do
        local classId = pref.class
        local specId = __TS__Number(pref.spec)
        local existing
        for ____, row in ipairs(result) do
            if row.classId == classId and row.specId == specId then
                existing = row
                break
            end
        end
        if existing ~= nil then
            existing.count = existing.count + 1
        else
            result[#result + 1] = {classId = classId, specId = specId, count = 1}
        end
    end
    return result
end
function ____exports.requiredFlat(self, role)
    local result = {}
    for ____, build in ipairs(____exports.requiredBuilds(nil, role)) do
        do
            local i = 0
            while i < build.count do
                result[#result + 1] = {classId = build.classId, specId = build.specId}
                i = i + 1
            end
        end
    end
    return result
end
function ____exports.exactCount(self, role)
    local total = 0
    for ____, row in ipairs(____exports.requiredBuilds(nil, role)) do
        total = total + row.count
    end
    return total
end
function ____exports.writeRequiredBuilds(self, role, rows, reason)
    if reason == nil then
        reason = "Exact composition changed"
    end
    local cfg = ____exports.config(nil)
    local ____opt_21 = cfg.preferences
    if ____opt_21 ~= nil then
        ____opt_21 = ____opt_21[role]
    end
    local ____opt_21_23 = ____opt_21
    if ____opt_21_23 == nil then
        ____opt_21_23 = {}
    end
    local existing = ____opt_21_23
    local next = {}
    for ____, pref in __TS__Iterator(existing) do
        if pref.required ~= true then
            next[#next + 1] = pref
        end
    end
    local max = ____exports.remainingBotSlots(nil, role)
    local written = 0
    for ____, row in ipairs(rows) do
        local count = math.max(
            0,
            math.min(row.count, max - written)
        )
        do
            local i = 0
            while i < count do
                next[#next + 1] = {class = row.classId, spec = row.specId == ____exports.ANY_SPEC_ID and "ANY" or row.specId, required = true}
                written = written + 1
                i = i + 1
            end
        end
        if written >= max then
            break
        end
    end
    cfg.preferences[role] = next
    ____exports.touch(nil, reason)
end
function ____exports.addRequiredBuild(self, role, classId, specId, count)
    local rows = ____exports.requiredBuilds(nil, role)
    local available = math.max(
        0,
        ____exports.remainingBotSlots(nil, role) - ____exports.exactCount(nil, role)
    )
    local add = math.max(
        0,
        math.min(count, available)
    )
    if add <= 0 then
        ____exports.fireStatus(
            nil,
            ("Every " .. string.lower(____exports.roleLabel(nil, role))) .. " bot slot already has an exact build."
        )
        return
    end
    local existing
    for ____, row in ipairs(rows) do
        if row.classId == classId and row.specId == specId then
            existing = row
            break
        end
    end
    if existing ~= nil then
        existing.count = existing.count + add
    else
        rows[#rows + 1] = {classId = classId, specId = specId, count = add}
    end
    ____exports.writeRequiredBuilds(nil, role, rows)
end
function ____exports.replaceRequiredBuild(self, role, index, classId, specId, count)
    local rows = ____exports.requiredBuilds(nil, role)
    local old = rows[index + 1]
    if old == nil then
        return
    end
    local usedWithout = 0
    do
        local i = 0
        while i < #rows do
            if i ~= index then
                usedWithout = usedWithout + rows[i + 1].count
            end
            i = i + 1
        end
    end
    local allowed = math.max(
        1,
        ____exports.remainingBotSlots(nil, role) - usedWithout
    )
    rows[index + 1] = {
        classId = classId,
        specId = specId,
        count = math.max(
            1,
            math.min(count, allowed)
        )
    }
    ____exports.writeRequiredBuilds(nil, role, rows)
end
function ____exports.removeRequiredBuild(self, role, index)
    local rows = ____exports.requiredBuilds(nil, role)
    if rows[index + 1] == nil then
        return
    end
    __TS__ArraySplice(rows, index, 1)
    ____exports.writeRequiredBuilds(nil, role, rows)
end
function ____exports.setDungeonExact(self, role, botIndex, classId, specId)
    local flat = ____exports.requiredFlat(nil, role)
    local target = math.max(0, botIndex - 1)
    if target < #flat then
        flat[target + 1] = {classId = classId, specId = specId}
    else
        flat[#flat + 1] = {classId = classId, specId = specId}
    end
    local rows = {}
    for ____, item in ipairs(flat) do
        local existing
        for ____, row in ipairs(rows) do
            if row.classId == item.classId and row.specId == item.specId then
                existing = row
                break
            end
        end
        if existing ~= nil then
            existing.count = existing.count + 1
        else
            rows[#rows + 1] = {classId = item.classId, specId = item.specId, count = 1}
        end
    end
    ____exports.writeRequiredBuilds(nil, role, rows, "Dungeon build changed")
end
function ____exports.clearDungeonExact(self, role, botIndex)
    local flat = ____exports.requiredFlat(nil, role)
    local target = math.max(0, botIndex - 1)
    if target >= #flat then
        return
    end
    __TS__ArraySplice(flat, target, 1)
    local rows = {}
    for ____, item in ipairs(flat) do
        local existing
        for ____, row in ipairs(rows) do
            if row.classId == item.classId and row.specId == item.specId then
                existing = row
                break
            end
        end
        if existing ~= nil then
            existing.count = existing.count + 1
        else
            rows[#rows + 1] = {classId = item.classId, specId = item.specId, count = 1}
        end
    end
    ____exports.writeRequiredBuilds(nil, role, rows, "Dungeon build cleared")
end
function ____exports.getSpecLabel(self, classId, specId)
    if specId == ____exports.ANY_SPEC_ID then
        return "Any valid spec"
    end
    local specs = __TS__ArrayConcat(
        __TS__ArrayConcat(
            getSpecsForRole(classId, "TANK"),
            getSpecsForRole(classId, "HEALER")
        ),
        getSpecsForRole(classId, "DPS")
    )
    for ____, spec in ipairs(specs) do
        if spec.id == specId then
            return spec.label
        end
    end
    return "Unknown"
end
function ____exports.getSpecIcon(self, classId, specId)
    if specId == ____exports.ANY_SPEC_ID then
        return "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    local classDef = getClass(classId)
    if classDef ~= nil then
        for ____, spec in ipairs(classDef.specs) do
            if spec.id == specId then
                return spec.icon
            end
        end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end
function ____exports.classLabel(self, classId)
    local classDef = getClass(classId)
    return classDef and classDef.label or tostring(classId)
end
local function dungeonById(self, id)
    return DataFns.GetDungeonById(id)
end
local function raidById(self, id)
    return DataFns.GetRaidById(id)
end
function ____exports.pinnedMembers(self)
    local result = {}
    local ____exports_config_result_pinned_26 = ____exports.config(nil).pinned
    if ____exports_config_result_pinned_26 == nil then
        ____exports_config_result_pinned_26 = {}
    end
    for ____, pin in ipairs(____exports_config_result_pinned_26) do
        result[#result + 1] = pin
    end
    return result
end
function ____exports.planWarnings(self)
    local result = {}
    local ____exports_plan_result_warnings_27 = ____exports.plan(nil).warnings
    if ____exports_plan_result_warnings_27 == nil then
        ____exports_plan_result_warnings_27 = {}
    end
    for ____, warning in ipairs(____exports_plan_result_warnings_27) do
        result[#result + 1] = tostring(warning)
    end
    return result
end
function ____exports.coverageDisplay(self)
    local ____exports_plan_result_summary_28 = ____exports.plan(nil).summary
    if ____exports_plan_result_summary_28 == nil then
        ____exports_plan_result_summary_28 = {}
    end
    local summary = ____exports_plan_result_summary_28
    local ____summary_utility_29 = summary.utility
    if ____summary_utility_29 == nil then
        ____summary_utility_29 = ""
    end
    local raw = tostring(____summary_utility_29)
    local labels = {}
    if (string.find(raw, "interrupt", nil, true) or 0) - 1 >= 0 then
        labels[#labels + 1] = "Interrupts"
    end
    if (string.find(raw, "dispel", nil, true) or 0) - 1 >= 0 then
        labels[#labels + 1] = "Dispels"
    end
    if (string.find(raw, "buffs", nil, true) or 0) - 1 >= 0 then
        labels[#labels + 1] = "Raid buffs"
    end
    if (string.find(raw, "heroism", nil, true) or 0) - 1 >= 0 then
        labels[#labels + 1] = "Heroism"
    end
    if (string.find(raw, "battle-rez", nil, true) or 0) - 1 >= 0 then
        labels[#labels + 1] = "Battle rez"
    end
    if (string.find(raw, "cc", nil, true) or 0) - 1 >= 0 then
        labels[#labels + 1] = "Crowd control"
    end
    if (string.find(raw, "threat", nil, true) or 0) - 1 >= 0 then
        labels[#labels + 1] = "Threat support"
    end
    local utility = ""
    do
        local i = 0
        while i < #labels do
            if i > 0 then
                utility = utility .. "  ·  "
            end
            utility = utility .. labels[i + 1]
            i = i + 1
        end
    end
    if utility == "" then
        utility = "No utility coverage yet"
    end
    local ____temp_31 = (utility .. "\n") .. "Ranged DPS  "
    local ____summary_ranged_30 = summary.ranged
    if ____summary_ranged_30 == nil then
        ____summary_ranged_30 = 0
    end
    local ____temp_33 = (____temp_31 .. tostring(____summary_ranged_30)) .. "     Melee DPS  "
    local ____summary_melee_32 = summary.melee
    if ____summary_melee_32 == nil then
        ____summary_melee_32 = 0
    end
    return ____temp_33 .. tostring(____summary_melee_32)
end
function ____exports.dungeonItems(self)
    local result = {}
    local ____D_DUNGEONS_35 = D.DUNGEONS
    if ____D_DUNGEONS_35 == nil then
        ____D_DUNGEONS_35 = {}
    end
    for ____, dungeon in __TS__Iterator(____D_DUNGEONS_35) do
        local ____dungeon_minLevel_34 = dungeon.minLevel
        if ____dungeon_minLevel_34 == nil then
            ____dungeon_minLevel_34 = 68
        end
        local min = __TS__Number(____dungeon_minLevel_34)
        result[#result + 1] = {
            value = dungeon.id,
            label = dungeon.label,
            detail = dungeon.id == "random" and ("WotLK random · Normal Lv " .. tostring(min)) .. "+ · Heroic Lv 80" or ("Normal Lv " .. tostring(min)) .. "+ · Heroic Lv 80"
        }
    end
    return result
end
function ____exports.difficultyItems(self)
    local result = {}
    local ____D_DUNGEON_DIFFICULTIES_36 = D.DUNGEON_DIFFICULTIES
    if ____D_DUNGEON_DIFFICULTIES_36 == nil then
        ____D_DUNGEON_DIFFICULTIES_36 = {}
    end
    for ____, difficulty in __TS__Iterator(____D_DUNGEON_DIFFICULTIES_36) do
        result[#result + 1] = {value = difficulty.id, label = difficulty.label}
    end
    return result
end
function ____exports.raidItems(self)
    local result = {}
    local ____D_RAIDS_42 = D.RAIDS
    if ____D_RAIDS_42 == nil then
        ____D_RAIDS_42 = {}
    end
    for ____, raid in __TS__Iterator(____D_RAIDS_42) do
        local sizes = ""
        local firstSize = true
        local ____raid_sizes_37 = raid.sizes
        if ____raid_sizes_37 == nil then
            ____raid_sizes_37 = {}
        end
        for ____, size in __TS__Iterator(____raid_sizes_37) do
            if not firstSize then
                sizes = sizes .. "/"
            end
            sizes = sizes .. tostring(size)
            firstSize = false
        end
        local ____raid_id_40 = raid.id
        local ____temp_41 = (tostring(raid.era) .. "  ·  ") .. tostring(raid.label)
        local ____temp_39 = sizes .. " player · Level "
        local ____raid_requiredLevel_38 = raid.requiredLevel
        if ____raid_requiredLevel_38 == nil then
            ____raid_requiredLevel_38 = 80
        end
        result[#result + 1] = {
            value = ____raid_id_40,
            label = ____temp_41,
            detail = (____temp_39 .. tostring(____raid_requiredLevel_38)) .. "+"
        }
    end
    return result
end
function ____exports.raidDifficultyItems(self)
    local result = {{value = "normal", label = "Normal"}}
    local raid = raidById(
        nil,
        ____exports.config(nil).activity
    )
    local ____opt_result_45
    if raid ~= nil then
        ____opt_result_45 = raid.heroic
    end
    if ____opt_result_45 == true then
        result[#result + 1] = {value = "heroic", label = "Heroic"}
    end
    return result
end
function ____exports.selectedActivityLabel(self)
    local cfg = ____exports.config(nil)
    if cfg.mode == "RAID" then
        local raid = raidById(nil, cfg.activity)
        local ____opt_result_48
        if raid ~= nil then
            ____opt_result_48 = raid.label
        end
        local ____opt_result_48_49 = ____opt_result_48
        if ____opt_result_48_49 == nil then
            ____opt_result_48_49 = "Raid"
        end
        return ____opt_result_48_49
    end
    local dungeon = dungeonById(nil, cfg.activity)
    local ____opt_result_52
    if dungeon ~= nil then
        ____opt_result_52 = dungeon.label
    end
    local ____opt_result_52_53 = ____opt_result_52
    if ____opt_result_52_53 == nil then
        ____opt_result_52_53 = "Dungeon"
    end
    return ____opt_result_52_53
end
function ____exports.requiredActivityLevel(self)
    local cfg = ____exports.config(nil)
    if cfg.mode == "RAID" then
        local raid = raidById(nil, cfg.activity)
        local ____opt_result_56
        if raid ~= nil then
            ____opt_result_56 = raid.requiredLevel
        end
        local ____opt_result_56_57 = ____opt_result_56
        if ____opt_result_56_57 == nil then
            ____opt_result_56_57 = 80
        end
        return __TS__Number(____opt_result_56_57)
    end
    if cfg.difficulty ~= "normal" then
        return 80
    end
    local dungeon = dungeonById(nil, cfg.activity)
    local ____opt_result_60
    if dungeon ~= nil then
        ____opt_result_60 = dungeon.minLevel
    end
    local ____opt_result_60_61 = ____opt_result_60
    if ____opt_result_60_61 == nil then
        ____opt_result_60_61 = 68
    end
    return __TS__Number(____opt_result_60_61)
end
function ____exports.activityEligibilityText(self)
    local level = ____exports.requiredActivityLevel(nil)
    local ____opt_62 = ____exports.config(nil).options
    if ____opt_62 ~= nil then
        ____opt_62 = ____opt_62.minimumItemLevel
    end
    local ____opt_62_64 = ____opt_62
    if ____opt_62_64 == nil then
        ____opt_62_64 = 0
    end
    local floor = __TS__Number(____opt_62_64)
    return (("Level " .. tostring(level)) .. "+ required · Item level floor ") .. (floor > 0 and tostring(floor) or "Off")
end
function ____exports.setMinimumItemLevel(self, value)
    local next = math.max(
        0,
        math.min(
            1000,
            math.floor(value)
        )
    )
    ____exports.config(nil).options.minimumItemLevel = next
    ____exports.touch(nil, "Minimum item level changed")
end
function ____exports.supportedRaidSizes(self)
    local raid = raidById(
        nil,
        ____exports.config(nil).activity
    )
    local result = {}
    local ____opt_result_67
    if raid ~= nil then
        ____opt_result_67 = raid.sizes
    end
    local ____opt_result_67_68 = ____opt_result_67
    if ____opt_result_67_68 == nil then
        ____opt_result_67_68 = {}
    end
    for ____, size in __TS__Iterator(____opt_result_67_68) do
        result[#result + 1] = __TS__Number(size)
    end
    return result
end
function ____exports.setMode(self, mode)
    GC:SetMode(mode)
end
function ____exports.setDungeonActivity(self, id)
    GC:SetDungeonActivity(id)
end
function ____exports.setRaidActivity(self, id)
    GC:SetRaidActivity(id)
end
function ____exports.setRaidSize(self, size)
    GC:SetRaidSize(size)
end
function ____exports.setDifficulty(self, id)
    ____exports.config(nil).difficulty = id
    ____exports.touch(nil, "Difficulty changed")
end
function ____exports.setHumanRole(self, name, role)
    GC:SetHumanRole(name, role)
end
function ____exports.buildAndPrepare(self)
    GC:FindRoster()
end
function ____exports.assemble(self)
    GC:Assemble()
end
function ____exports.requestAnchors(self)
    GC:RequestAnchors()
end
function ____exports.requestStatus(self)
    GC:RequestStatus()
end
function ____exports.clearPlan(self)
    GC:ClearServerPlan()
end
function ____exports.loadProfile(self, name)
    GC:LoadProfile(name)
end
function ____exports.saveProfile(self, name)
    GC:SaveProfile(name)
end
function ____exports.deleteProfile(self, name)
    GC:DeleteProfile(name)
end
function ____exports.listBuiltinProfiles(self)
    return ProfileFns.ListBuiltins() or ({})
end
function ____exports.listCustomProfiles(self)
    return ProfileFns.ListCustom() or ({})
end
function ____exports.profileDescription(self, name)
    return ProfileFns.Describe(name) or ""
end
function ____exports.addPin(self, name, role, required)
    GC:AddPinnedMember(name, role, required)
end
function ____exports.removePin(self, index)
    GC:RemovePinnedMember(index)
end
function ____exports.planMembers(self)
    local ____exports_plan_result_members_69 = ____exports.plan(nil).members
    if ____exports_plan_result_members_69 == nil then
        ____exports_plan_result_members_69 = {}
    end
    return ____exports_plan_result_members_69
end
function ____exports.roleAccent(self, role)
    if role == "TANK" then
        return {0.2, 0.58, 0.98, 1}
    end
    if role == "HEALER" then
        return {0.18, 0.78, 0.42, 1}
    end
    return {0.91, 0.31, 0.3, 1}
end
function ____exports.phaseLabel(self, phase)
    if phase == "BUILDING" then
        return "Selecting roster"
    end
    if phase == "PREPARING" then
        return "Preparing bots"
    end
    if phase == "READY" then
        return "Ready"
    end
    if phase == "ASSEMBLING" then
        return "Assembling"
    end
    if phase == "TRAVEL" then
        return "Entering activity"
    end
    if phase == "DONE" then
        return "Group ready"
    end
    if phase == "ERROR" then
        return "Needs attention"
    end
    return "Configure roster"
end
function ____exports.isBusy(self)
    local ____exports_progress_result_phase_70 = ____exports.progress(nil).phase
    if ____exports_progress_result_phase_70 == nil then
        ____exports_progress_result_phase_70 = "IDLE"
    end
    local phase = tostring(____exports_progress_result_phase_70)
    return phase == "BUILDING" or phase == "PREPARING" or phase == "ASSEMBLING" or phase == "TRAVEL"
end
function ____exports.isTravelRetry(self)
    local p = ____exports.progress(nil)
    local ____temp_72 = p.phase == "READY"
    if ____temp_72 then
        local ____p_detail_71 = p.detail
        if ____p_detail_71 == nil then
            ____p_detail_71 = ""
        end
        ____temp_72 = (string.find(
            tostring(____p_detail_71),
            "Enter Activity",
            nil,
            true
        ) or 0) - 1 >= 0
    end
    return ____temp_72
end
return ____exports
 end,
["widgets.Modal"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____Native = require("core.Native")
local createPanel = ____Native.createPanel
local createSolid = ____Native.createSolid
local createText = ____Native.createText
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
local ____Button = require("widgets.Button")
local createButton = ____Button.createButton
function ____exports.createModal(self, parent, width, height)
    local scrim = CreateFrame("Frame", nil, parent)
    scrim:SetAllPoints(parent)
    scrim:SetFrameStrata("DIALOG")
    scrim:SetFrameLevel(parent:GetFrameLevel() + 20)
    scrim:EnableMouse(true)
    local scrimTexture = createSolid(nil, scrim, theme.colors.scrim)
    scrimTexture:SetAllPoints(scrim)
    local panel = createPanel(nil, parent, theme.colors.background, theme.colors.borderStrong)
    panel.frame:SetSize(width, height)
    panel.frame:SetPoint(
        "CENTER",
        parent,
        "CENTER",
        0,
        0
    )
    panel.frame:SetFrameStrata("DIALOG")
    panel.frame:SetFrameLevel(scrim:GetFrameLevel() + 1)
    local function hideModal(self)
        panel.frame:Hide()
        scrim:Hide()
    end
    local function showModal(self)
        scrim:Show()
        panel.frame:Show()
    end
    scrim:SetScript(
        "OnMouseDown",
        function() return hideModal(nil) end
    )
    local headerBg = createSolid(nil, panel.frame, theme.colors.surface, "BACKGROUND")
    headerBg:SetPoint(
        "TOPLEFT",
        panel.frame,
        "TOPLEFT",
        1,
        -1
    )
    headerBg:SetPoint(
        "TOPRIGHT",
        panel.frame,
        "TOPRIGHT",
        -1,
        -1
    )
    headerBg:SetHeight(62)
    local headerAccent = createSolid(nil, panel.frame, theme.colors.primary, "ARTWORK")
    headerAccent:SetPoint(
        "TOPLEFT",
        panel.frame,
        "TOPLEFT",
        1,
        -1
    )
    headerAccent:SetPoint(
        "TOPRIGHT",
        panel.frame,
        "TOPRIGHT",
        -1,
        -1
    )
    headerAccent:SetHeight(2)
    local title = createText(nil, panel.frame, "Choose Build", "GameFontNormalLarge")
    title:SetPoint(
        "TOPLEFT",
        panel.frame,
        "TOPLEFT",
        theme.spacing.lg,
        -12
    )
    local subtitle = createText(
        nil,
        panel.frame,
        "",
        "GameFontHighlightSmall",
        theme.colors.muted
    )
    subtitle:SetPoint(
        "TOPLEFT",
        title,
        "BOTTOMLEFT",
        0,
        -3
    )
    subtitle:SetWidth(width - 100)
    local close = createButton(
        nil,
        panel.frame,
        {
            text = "X",
            width = 30,
            height = 30,
            accent = theme.colors.error,
            onClick = function() return hideModal(nil) end
        }
    )
    close.frame:SetPoint(
        "TOPRIGHT",
        panel.frame,
        "TOPRIGHT",
        -theme.spacing.md,
        -theme.spacing.md
    )
    local content = CreateFrame("Frame", nil, panel.frame)
    content:SetPoint(
        "TOPLEFT",
        panel.frame,
        "TOPLEFT",
        theme.spacing.lg,
        -76
    )
    content:SetPoint(
        "BOTTOMRIGHT",
        panel.frame,
        "BOTTOMRIGHT",
        -theme.spacing.lg,
        theme.spacing.lg
    )
    panel.frame:Hide()
    scrim:Hide()
    return {
        frame = panel.frame,
        content = content,
        show = function(self)
            showModal(nil)
        end,
        hide = function(self)
            hideModal(nil)
        end,
        setTitle = function(self, value)
            title:SetText(value)
        end,
        setSubtitle = function(self, value)
            subtitle:SetText(value)
        end
    }
end
return ____exports
 end,
["widgets.Stepper"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____Native = require("core.Native")
local createText = ____Native.createText
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
local ____Button = require("widgets.Button")
local createButton = ____Button.createButton
function ____exports.createNumberStepper(self, parent, initialMin, initialMax, initial, onChange)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(126, theme.control.md)
    local min = initialMin
    local max = initialMax
    local value = initial
    local valueText = createText(
        nil,
        frame,
        tostring(value),
        "GameFontNormal"
    )
    valueText:SetPoint(
        "CENTER",
        frame,
        "CENTER",
        0,
        0
    )
    valueText:SetJustifyH("CENTER")
    local function update(self, next, notify)
        if notify == nil then
            notify = true
        end
        value = math.max(
            min,
            math.min(max, next)
        )
        valueText:SetText(tostring(value))
        if notify and onChange ~= nil then
            onChange(nil, value)
        end
    end
    local minus = createButton(
        nil,
        frame,
        {
            text = "-",
            width = theme.control.md,
            height = theme.control.md,
            onClick = function() return update(nil, value - 1) end
        }
    )
    minus.frame:SetPoint(
        "LEFT",
        frame,
        "LEFT",
        0,
        0
    )
    local plus = createButton(
        nil,
        frame,
        {
            text = "+",
            width = theme.control.md,
            height = theme.control.md,
            onClick = function() return update(nil, value + 1) end
        }
    )
    plus.frame:SetPoint(
        "RIGHT",
        frame,
        "RIGHT",
        0,
        0
    )
    update(nil, initial, false)
    return {
        frame = frame,
        getValue = function(self)
            return value
        end,
        setValue = function(self, next, notify)
            if notify == nil then
                notify = false
            end
            update(nil, next, notify)
        end,
        setBounds = function(self, nextMin, nextMax)
            min = nextMin
            max = math.max(nextMin, nextMax)
            update(nil, value, false)
        end
    }
end
return ____exports
 end,
["components.BuildSelector"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____Native = require("core.Native")
local classColor = ____Native.classColor
local createIcon = ____Native.createIcon
local createPanel = ____Native.createPanel
local createSolid = ____Native.createSolid
local createText = ____Native.createText
local setClassIcon = ____Native.setClassIcon
local ____WotlkBuilds = require("data.WotlkBuilds")
local getClass = ____WotlkBuilds.getClass
local getClassesForRole = ____WotlkBuilds.getClassesForRole
local getSpecsForRole = ____WotlkBuilds.getSpecsForRole
local ____ComposerModel = require("model.ComposerModel")
local ANY_SPEC_ID = ____ComposerModel.ANY_SPEC_ID
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
local ____Button = require("widgets.Button")
local createButton = ____Button.createButton
local ____Modal = require("widgets.Modal")
local createModal = ____Modal.createModal
local ____Stepper = require("widgets.Stepper")
local createNumberStepper = ____Stepper.createNumberStepper
local function roleLabel(self, role)
    if role == "TANK" then
        return "Tank"
    end
    if role == "HEALER" then
        return "Healer"
    end
    return "DPS"
end
local function roleAccent(self, role)
    if role == "TANK" then
        return theme.colors.tank
    end
    if role == "HEALER" then
        return theme.colors.healer
    end
    return theme.colors.dps
end
function ____exports.createBuildSelector(self, parent, options)
    local refresh, modal, currentRole, currentClass, currentSpec, classSection, classStep, classStepText, classTiles, specSection, specStep, specStepText, specHint, emptySpec, anySpecButton, specTiles, summaryClassIcon, summarySpecIcon, summaryText, summarySub, apply
    function refresh(self)
        local accent = roleAccent(nil, currentRole)
        modal:setTitle(("Add " .. roleLabel(nil, currentRole)) .. " Build")
        modal:setSubtitle("Reserve only what matters. Unspecified slots remain Auto-filled.")
        classSection.outline:setColor(accent)
        specSection.outline:setColor(accent)
        classStep.outline:setColor(accent)
        specStep.outline:setColor(accent)
        classStepText:SetTextColor(accent[1], accent[2], accent[3], 1)
        specStepText:SetTextColor(accent[1], accent[2], accent[3], 1)
        local validClasses = getClassesForRole(currentRole)
        local classIndex = 0
        for ____, tile in ipairs(classTiles) do
            do
                local __continue23
                repeat
                    local valid = false
                    for ____, classDef in ipairs(validClasses) do
                        if classDef.id == tile.classDef.id then
                            valid = true
                            break
                        end
                    end
                    if not valid then
                        tile.button.frame:Hide()
                        __continue23 = true
                        break
                    end
                    local column = classIndex % 5
                    local row = math.floor(classIndex / 5)
                    tile.button.frame:ClearAllPoints()
                    tile.button.frame:SetPoint(
                        "TOPLEFT",
                        classSection.frame,
                        "TOPLEFT",
                        14 + column * 184,
                        -(72 + row * 70)
                    )
                    tile.sub:SetText(roleLabel(nil, currentRole) .. " capable")
                    tile.button:setSelected(tile.classDef.id == currentClass)
                    tile.button.frame:Show()
                    classIndex = classIndex + 1
                    __continue23 = true
                until true
                if not __continue23 then
                    break
                end
            end
        end
        if currentClass == nil then
            anySpecButton.frame:Hide()
            for ____, tile in ipairs(specTiles) do
                tile.button.frame:Hide()
            end
            specHint:SetText("Pick a class first.")
            emptySpec:Show()
        else
            local selectedClass = getClass(currentClass)
            specHint:SetText((((selectedClass and selectedClass.label or "Selected class") .. " options for ") .. roleLabel(nil, currentRole)) .. ".")
            emptySpec:Hide()
            anySpecButton.frame:ClearAllPoints()
            anySpecButton.frame:SetPoint(
                "TOPLEFT",
                specSection.frame,
                "TOPLEFT",
                14,
                -74
            )
            anySpecButton:setSelected(currentSpec == ANY_SPEC_ID)
            anySpecButton.frame:Show()
            local specIndex = 1
            for ____, tile in ipairs(specTiles) do
                local visible = false
                if tile.classId == currentClass then
                    for ____, validSpec in ipairs(getSpecsForRole(currentClass, currentRole)) do
                        if validSpec.id == tile.spec.id then
                            visible = true
                            break
                        end
                    end
                end
                if visible then
                    tile.button.frame:ClearAllPoints()
                    tile.button.frame:SetPoint(
                        "TOPLEFT",
                        specSection.frame,
                        "TOPLEFT",
                        14 + specIndex * 226,
                        -74
                    )
                    tile.sub:SetText((tile.classLabel .. " · ") .. roleLabel(nil, currentRole))
                    tile.button:setSelected(tile.spec.id == currentSpec)
                    tile.button.frame:Show()
                    specIndex = specIndex + 1
                else
                    tile.button.frame:Hide()
                end
            end
        end
        local ____temp_2
        if currentClass == nil then
            ____temp_2 = nil
        else
            ____temp_2 = getClass(currentClass)
        end
        local selectedClass = ____temp_2
        local selectedSpec
        if currentClass ~= nil and currentSpec ~= nil and currentSpec ~= ANY_SPEC_ID then
            for ____, spec in ipairs(getSpecsForRole(currentClass, currentRole)) do
                if spec.id == currentSpec then
                    selectedSpec = spec
                    break
                end
            end
        end
        if selectedClass ~= nil then
            setClassIcon(nil, summaryClassIcon, selectedClass.id)
        else
            summaryClassIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            summaryClassIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
        if selectedClass ~= nil and currentSpec == ANY_SPEC_ID then
            summarySpecIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            summarySpecIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            summaryText:SetText(selectedClass.label .. " · Any valid specialization")
            summarySub:SetText(("Composer may use any " .. string.lower(roleLabel(nil, currentRole))) .. " spec from this class.")
            apply:setEnabled(true)
        elseif selectedClass ~= nil and selectedSpec ~= nil then
            summarySpecIcon:SetTexture(selectedSpec.icon)
            summarySpecIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            summaryText:SetText((selectedSpec.label .. " ") .. selectedClass.label)
            summarySub:SetText(roleLabel(nil, currentRole) .. " · exact specialization reserved")
            apply:setEnabled(true)
        else
            summarySpecIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            summarySpecIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            summaryText:SetText(currentClass == nil and "Choose a class" or "Choose a specialization")
            summarySub:SetText(currentClass == nil and "Start with one of the role-compatible classes above." or "Pick an exact spec, or choose Any valid spec for a flexible class lock.")
            apply:setEnabled(false)
        end
    end
    modal = createModal(nil, parent, 1000, 680)
    currentRole = "DPS"
    local countEnabled = options.allowCount == true
    classSection = createPanel(nil, modal.content, theme.colors.surface, theme.colors.border)
    classSection.frame:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        0,
        0
    )
    classSection.frame:SetPoint(
        "TOPRIGHT",
        modal.content,
        "TOPRIGHT",
        0,
        0
    )
    classSection.frame:SetHeight(212)
    classStep = createPanel(nil, classSection.frame, theme.colors.surfaceRaised, theme.colors.borderStrong)
    classStep.frame:SetSize(34, 34)
    classStep.frame:SetPoint(
        "TOPLEFT",
        classSection.frame,
        "TOPLEFT",
        14,
        -14
    )
    classStepText = createText(
        nil,
        classStep.frame,
        "1",
        "GameFontNormal",
        theme.colors.primary
    )
    classStepText:SetPoint(
        "CENTER",
        classStep.frame,
        "CENTER",
        0,
        0
    )
    local classTitle = createText(nil, classSection.frame, "Choose a class", "GameFontNormalLarge")
    classTitle:SetPoint(
        "TOPLEFT",
        classSection.frame,
        "TOPLEFT",
        60,
        -13
    )
    local classHint = createText(
        nil,
        classSection.frame,
        "Only classes that can perform the selected role are shown.",
        "GameFontHighlightSmall",
        theme.colors.muted
    )
    classHint:SetPoint(
        "TOPLEFT",
        classTitle,
        "BOTTOMLEFT",
        0,
        -4
    )
    classTiles = {}
    for ____, classDef in ipairs(getClassesForRole("DPS")) do
        local button = createButton(
            nil,
            classSection.frame,
            {
                text = classDef.label,
                width = 170,
                height = 62,
                accent = classColor(nil, classDef.id)
            }
        )
        local accent = createSolid(
            nil,
            button.frame,
            classColor(nil, classDef.id),
            "ARTWORK"
        )
        accent:SetWidth(3)
        accent:SetPoint(
            "TOPLEFT",
            button.frame,
            "TOPLEFT",
            0,
            0
        )
        accent:SetPoint(
            "BOTTOMLEFT",
            button.frame,
            "BOTTOMLEFT",
            0,
            0
        )
        local icon = button.frame:CreateTexture(nil, "ARTWORK")
        icon:SetSize(36, 36)
        icon:SetPoint(
            "LEFT",
            button.frame,
            "LEFT",
            12,
            0
        )
        setClassIcon(nil, icon, classDef.id)
        button.label:ClearAllPoints()
        button.label:SetPoint(
            "TOPLEFT",
            button.frame,
            "TOPLEFT",
            58,
            -12
        )
        button.label:SetPoint(
            "RIGHT",
            button.frame,
            "RIGHT",
            -8,
            8
        )
        button.label:SetJustifyH("LEFT")
        local sub = createText(
            nil,
            button.frame,
            "Available",
            "GameFontHighlightSmall",
            theme.colors.muted
        )
        sub:SetPoint(
            "TOPLEFT",
            button.frame,
            "TOPLEFT",
            58,
            -34
        )
        sub:SetWidth(100)
        button.frame:SetScript(
            "OnMouseDown",
            function()
                if currentClass ~= classDef.id then
                    currentSpec = nil
                end
                currentClass = classDef.id
                refresh(nil)
            end
        )
        classTiles[#classTiles + 1] = {classDef = classDef, button = button, icon = icon, sub = sub}
    end
    specSection = createPanel(nil, modal.content, theme.colors.surface, theme.colors.border)
    specSection.frame:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        0,
        -226
    )
    specSection.frame:SetPoint(
        "TOPRIGHT",
        modal.content,
        "TOPRIGHT",
        0,
        -226
    )
    specSection.frame:SetHeight(224)
    specStep = createPanel(nil, specSection.frame, theme.colors.surfaceRaised, theme.colors.borderStrong)
    specStep.frame:SetSize(34, 34)
    specStep.frame:SetPoint(
        "TOPLEFT",
        specSection.frame,
        "TOPLEFT",
        14,
        -14
    )
    specStepText = createText(
        nil,
        specStep.frame,
        "2",
        "GameFontNormal",
        theme.colors.primary
    )
    specStepText:SetPoint(
        "CENTER",
        specStep.frame,
        "CENTER",
        0,
        0
    )
    local specTitle = createText(nil, specSection.frame, "Choose a specialization", "GameFontNormalLarge")
    specTitle:SetPoint(
        "TOPLEFT",
        specSection.frame,
        "TOPLEFT",
        60,
        -13
    )
    specHint = createText(
        nil,
        specSection.frame,
        "Pick a class first.",
        "GameFontHighlightSmall",
        theme.colors.muted
    )
    specHint:SetPoint(
        "TOPLEFT",
        specTitle,
        "BOTTOMLEFT",
        0,
        -4
    )
    emptySpec = createText(
        nil,
        specSection.frame,
        "Select a class above to see the exact specializations that can fill this role.",
        "GameFontHighlight",
        theme.colors.muted
    )
    emptySpec:SetPoint(
        "CENTER",
        specSection.frame,
        "CENTER",
        0,
        -28
    )
    emptySpec:SetWidth(700)
    emptySpec:SetJustifyH("CENTER")
    anySpecButton = createButton(
        nil,
        specSection.frame,
        {
            text = "Any valid spec",
            width = 214,
            height = 86,
            accent = theme.colors.primary,
            onClick = function()
                if currentClass == nil then
                    return
                end
                currentSpec = ANY_SPEC_ID
                refresh(nil)
            end
        }
    )
    local anySpecIcon = createIcon(nil, anySpecButton.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 38)
    anySpecIcon:SetPoint(
        "LEFT",
        anySpecButton.frame,
        "LEFT",
        14,
        0
    )
    anySpecButton.label:ClearAllPoints()
    anySpecButton.label:SetPoint(
        "TOPLEFT",
        anySpecButton.frame,
        "TOPLEFT",
        64,
        -18
    )
    anySpecButton.label:SetPoint(
        "RIGHT",
        anySpecButton.frame,
        "RIGHT",
        -10,
        10
    )
    anySpecButton.label:SetJustifyH("LEFT")
    local anySpecSub = createText(
        nil,
        anySpecButton.frame,
        "Lock class, let Composer pick spec",
        "GameFontHighlightSmall",
        theme.colors.muted
    )
    anySpecSub:SetPoint(
        "TOPLEFT",
        anySpecButton.frame,
        "TOPLEFT",
        64,
        -45
    )
    anySpecSub:SetWidth(136)
    anySpecSub:SetJustifyV("TOP")
    anySpecButton.frame:Hide()
    specTiles = {}
    for ____, classDef in ipairs(getClassesForRole("DPS")) do
        for ____, spec in ipairs(classDef.specs) do
            local button = createButton(
                nil,
                specSection.frame,
                {
                    text = spec.label,
                    width = 214,
                    height = 86,
                    accent = classColor(nil, classDef.id)
                }
            )
            local icon = createIcon(nil, button.frame, spec.icon, 40)
            icon:SetPoint(
                "LEFT",
                button.frame,
                "LEFT",
                14,
                0
            )
            button.label:ClearAllPoints()
            button.label:SetPoint(
                "TOPLEFT",
                button.frame,
                "TOPLEFT",
                66,
                -18
            )
            button.label:SetPoint(
                "RIGHT",
                button.frame,
                "RIGHT",
                -10,
                10
            )
            button.label:SetJustifyH("LEFT")
            local sub = createText(
                nil,
                button.frame,
                classDef.label,
                "GameFontHighlightSmall",
                theme.colors.muted
            )
            sub:SetPoint(
                "TOPLEFT",
                button.frame,
                "TOPLEFT",
                66,
                -45
            )
            sub:SetWidth(136)
            button.frame:SetScript(
                "OnMouseDown",
                function()
                    currentClass = classDef.id
                    currentSpec = spec.id
                    refresh(nil)
                end
            )
            button.frame:Hide()
            specTiles[#specTiles + 1] = {
                classId = classDef.id,
                classLabel = classDef.label,
                spec = spec,
                button = button,
                icon = icon,
                sub = sub
            }
        end
    end
    local summary = createPanel(nil, modal.content, theme.colors.surfaceRaised, theme.colors.borderStrong)
    summary.frame:SetPoint(
        "BOTTOMLEFT",
        modal.content,
        "BOTTOMLEFT",
        0,
        0
    )
    summary.frame:SetPoint(
        "BOTTOMRIGHT",
        modal.content,
        "BOTTOMRIGHT",
        0,
        0
    )
    summary.frame:SetHeight(104)
    local selectedLabel = createText(
        nil,
        summary.frame,
        "SELECTION",
        "GameFontNormalSmall",
        theme.colors.muted
    )
    selectedLabel:SetPoint(
        "TOPLEFT",
        summary.frame,
        "TOPLEFT",
        14,
        -12
    )
    summaryClassIcon = summary.frame:CreateTexture(nil, "ARTWORK")
    summaryClassIcon:SetSize(42, 42)
    summaryClassIcon:SetPoint(
        "BOTTOMLEFT",
        summary.frame,
        "BOTTOMLEFT",
        14,
        13
    )
    summaryClassIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    summaryClassIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    summarySpecIcon = summary.frame:CreateTexture(nil, "ARTWORK")
    summarySpecIcon:SetSize(42, 42)
    summarySpecIcon:SetPoint(
        "LEFT",
        summaryClassIcon,
        "RIGHT",
        7,
        0
    )
    summarySpecIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    summarySpecIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    summaryText = createText(nil, summary.frame, "Choose a class", "GameFontNormal")
    summaryText:SetPoint(
        "LEFT",
        summarySpecIcon,
        "RIGHT",
        12,
        8
    )
    summaryText:SetWidth(390)
    summarySub = createText(
        nil,
        summary.frame,
        "Then choose an exact spec or leave the spec flexible.",
        "GameFontHighlightSmall",
        theme.colors.muted
    )
    summarySub:SetPoint(
        "TOPLEFT",
        summaryText,
        "BOTTOMLEFT",
        0,
        -5
    )
    summarySub:SetWidth(390)
    local countLabel = createText(
        nil,
        summary.frame,
        "HOW MANY",
        "GameFontNormalSmall",
        theme.colors.muted
    )
    countLabel:SetPoint(
        "TOPRIGHT",
        summary.frame,
        "TOPRIGHT",
        -204,
        -14
    )
    local countStepper = createNumberStepper(
        nil,
        summary.frame,
        1,
        options.maxCount or 40,
        1
    )
    countStepper.frame:SetPoint(
        "BOTTOMRIGHT",
        summary.frame,
        "BOTTOMRIGHT",
        -164,
        13
    )
    apply = createButton(
        nil,
        summary.frame,
        {
            text = "Use this build",
            width = 148,
            height = 42,
            accent = theme.colors.success,
            onClick = function()
                if currentClass == nil or currentSpec == nil then
                    return
                end
                options:onApply({
                    role = currentRole,
                    classId = currentClass,
                    specId = currentSpec,
                    count = countEnabled and countStepper:getValue() or 1
                })
                modal:hide()
            end
        }
    )
    apply.frame:SetPoint(
        "BOTTOMRIGHT",
        summary.frame,
        "BOTTOMRIGHT",
        -12,
        13
    )
    return {
        frame = modal.frame,
        open = function(self, role, initial, showCount)
            if showCount == nil then
                showCount = true
            end
            currentRole = role
            currentClass = initial and initial.classId
            currentSpec = initial and initial.specId
            countEnabled = options.allowCount == true and showCount
            if countEnabled then
                countLabel:Show()
                countStepper.frame:Show()
            else
                countLabel:Hide()
                countStepper.frame:Hide()
            end
            countStepper:setValue(initial and initial.count or 1)
            if currentClass ~= nil then
                local validCurrent = false
                for ____, spec in ipairs(getSpecsForRole(currentClass, currentRole)) do
                    if spec.id == currentSpec then
                        validCurrent = true
                        break
                    end
                end
                if not validCurrent and currentSpec ~= ANY_SPEC_ID then
                    currentSpec = nil
                end
            end
            refresh(nil)
            modal:show()
        end,
        close = function(self)
            modal:hide()
        end
    }
end
return ____exports
 end,
["widgets.ScrollList"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__Number(value)
    local valueType = type(value)
    if valueType == "number" then
        return value
    elseif valueType == "string" then
        local numberValue = tonumber(value)
        if numberValue then
            return numberValue
        end
        if value == "Infinity" then
            return math.huge
        end
        if value == "-Infinity" then
            return -math.huge
        end
        local stringWithoutSpaces = string.gsub(value, "%s", "")
        if stringWithoutSpaces == "" then
            return 0
        end
        return 0 / 0
    elseif valueType == "boolean" then
        return value and 1 or 0
    else
        return 0 / 0
    end
end
-- End of Lua Library inline imports
local ____exports = {}
local ____Native = require("core.Native")
local createPanel = ____Native.createPanel
local createSolid = ____Native.createSolid
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
local ____Button = require("widgets.Button")
local createButton = ____Button.createButton
function ____exports.createScrollList(self, parent, width, height)
    local maxOffset, clamp, refreshRail, scroll, rail, contentHeight, offset, up, down, thumb
    function maxOffset(self)
        return math.max(0, contentHeight - height)
    end
    function clamp(self, value)
        return math.max(
            0,
            math.min(
                maxOffset(nil),
                value
            )
        )
    end
    function refreshRail(self)
        local range = maxOffset(nil)
        if range <= 0 then
            offset = 0
            scroll:SetVerticalScroll(0)
            rail.frame:Hide()
            return
        end
        rail.frame:Show()
        offset = clamp(nil, offset)
        scroll:SetVerticalScroll(offset)
        local trackHeight = math.max(28, height - 48)
        local thumbHeight = math.max(
            24,
            math.floor(trackHeight * math.min(1, height / contentHeight))
        )
        local travel = math.max(0, trackHeight - thumbHeight)
        local ratio = range > 0 and offset / range or 0
        thumb:SetHeight(thumbHeight)
        thumb:ClearAllPoints()
        thumb:SetPoint(
            "TOP",
            up.frame,
            "BOTTOM",
            0,
            -(4 + travel * ratio)
        )
        up:setEnabled(offset > 0)
        down:setEnabled(offset < range)
    end
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(width, height)
    frame:EnableMouseWheel(true)
    scroll = CreateFrame("ScrollFrame", nil, frame)
    scroll:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        0,
        0
    )
    scroll:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        -20,
        0
    )
    scroll:SetSize(
        math.max(1, width - 20),
        height
    )
    scroll:EnableMouseWheel(true)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(math.max(1, width - 20))
    content:SetHeight(height)
    content:EnableMouseWheel(true)
    scroll:SetScrollChild(content)
    rail = createPanel(nil, frame, theme.colors.background, theme.colors.border)
    rail.frame:SetPoint(
        "TOPRIGHT",
        frame,
        "TOPRIGHT",
        0,
        0
    )
    rail.frame:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        0,
        0
    )
    rail.frame:SetWidth(16)
    rail.frame:EnableMouseWheel(true)
    contentHeight = height
    offset = 0
    local function scrollBy(self, delta)
        offset = clamp(nil, offset + delta)
        scroll:SetVerticalScroll(offset)
        refreshRail(nil)
    end
    local function wheel(self, _target, delta)
        scrollBy(
            nil,
            __TS__Number(delta) > 0 and -72 or 72
        )
    end
    local function bindWheel(self, target)
        target:EnableMouseWheel(true)
        target:SetScript("OnMouseWheel", wheel)
    end
    up = createButton(
        nil,
        rail.frame,
        {
            text = "^",
            width = 16,
            height = 20,
            onClick = function() return scrollBy(nil, -72) end
        }
    )
    up.frame:SetPoint(
        "TOP",
        rail.frame,
        "TOP",
        0,
        0
    )
    down = createButton(
        nil,
        rail.frame,
        {
            text = "v",
            width = 16,
            height = 20,
            onClick = function() return scrollBy(nil, 72) end
        }
    )
    down.frame:SetPoint(
        "BOTTOM",
        rail.frame,
        "BOTTOM",
        0,
        0
    )
    local track = createSolid(nil, rail.frame, theme.colors.borderStrong, "ARTWORK")
    track:SetPoint(
        "TOP",
        up.frame,
        "BOTTOM",
        0,
        -4
    )
    track:SetPoint(
        "BOTTOM",
        down.frame,
        "TOP",
        0,
        4
    )
    track:SetWidth(3)
    thumb = createSolid(nil, rail.frame, theme.colors.primary, "OVERLAY")
    thumb:SetWidth(7)
    thumb:SetHeight(24)
    bindWheel(nil, frame)
    bindWheel(nil, scroll)
    bindWheel(nil, content)
    bindWheel(nil, rail.frame)
    bindWheel(nil, up.frame)
    bindWheel(nil, down.frame)
    return {
        frame = frame,
        content = content,
        setContentHeight = function(self, value)
            contentHeight = math.max(height, value)
            content:SetHeight(contentHeight)
            offset = clamp(nil, offset)
            scroll:SetVerticalScroll(offset)
            refreshRail(nil)
        end,
        scrollBy = function(____, delta) return scrollBy(nil, delta) end,
        scrollToTop = function(self)
            offset = 0
            scroll:SetVerticalScroll(0)
            refreshRail(nil)
        end,
        scrollToBottom = function(self)
            offset = maxOffset(nil)
            scroll:SetVerticalScroll(offset)
            refreshRail(nil)
        end,
        bindWheel = function(____, target) return bindWheel(nil, target) end,
        reset = function(self)
            offset = 0
            scroll:SetVerticalScroll(0)
            refreshRail(nil)
        end
    }
end
return ____exports
 end,
["widgets.TextInput"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____Native = require("core.Native")
local createPanel = ____Native.createPanel
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
function ____exports.createTextInput(self, parent, width, height)
    if height == nil then
        height = 34
    end
    local panel = createPanel(nil, parent, theme.colors.background, theme.colors.borderStrong)
    panel.frame:SetSize(width, height)
    local edit = CreateFrame("EditBox", nil, panel.frame)
    edit:SetAllPoints(panel.frame)
    edit:SetAutoFocus(false)
    edit:SetFontObject(GameFontHighlightSmall)
    edit:SetTextColor(theme.colors.text[1], theme.colors.text[2], theme.colors.text[3], 1)
    edit:SetTextInsets(10, 10, 0, 0)
    return {
        frame = panel.frame,
        editBox = edit,
        getText = function(self)
            return edit:GetText() or ""
        end,
        setText = function(self, value)
            edit:SetText(value)
        end,
        clear = function(self)
            edit:SetText("")
            edit:ClearFocus()
        end
    }
end
return ____exports
 end,
["widgets.Toggle"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____Native = require("core.Native")
local createPanel = ____Native.createPanel
local createText = ____Native.createText
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
function ____exports.createToggle(self, parent, label, getValue, setValue)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(30)
    frame:EnableMouse(true)
    local box = createPanel(nil, frame, theme.colors.background, theme.colors.borderStrong)
    box.frame:SetSize(20, 20)
    box.frame:SetPoint(
        "LEFT",
        frame,
        "LEFT",
        0,
        0
    )
    local check = box.frame:CreateTexture(nil, "ARTWORK")
    check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    check:SetAllPoints(box.frame)
    local text = createText(nil, frame, label, "GameFontHighlightSmall")
    text:SetPoint(
        "LEFT",
        box.frame,
        "RIGHT",
        9,
        0
    )
    local function refresh(self)
        if getValue(nil) then
            check:Show()
            box.outline:setColor(theme.colors.success)
        else
            check:Hide()
            box.outline:setColor(theme.colors.borderStrong)
        end
    end
    frame:SetScript(
        "OnMouseDown",
        function()
            setValue(
                nil,
                not getValue(nil)
            )
            refresh(nil)
        end
    )
    refresh(nil)
    return {
        frame = frame,
        refresh = function() return refresh(nil) end
    }
end
return ____exports
 end,
["components.ModernDashboard"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__Number(value)
    local valueType = type(value)
    if valueType == "number" then
        return value
    elseif valueType == "string" then
        local numberValue = tonumber(value)
        if numberValue then
            return numberValue
        end
        if value == "Infinity" then
            return math.huge
        end
        if value == "-Infinity" then
            return -math.huge
        end
        local stringWithoutSpaces = string.gsub(value, "%s", "")
        if stringWithoutSpaces == "" then
            return 0
        end
        return 0 / 0
    elseif valueType == "boolean" then
        return value and 1 or 0
    else
        return 0 / 0
    end
end

local __TS__Symbol, Symbol
do
    local symbolMetatable = {__tostring = function(self)
        return ("Symbol(" .. (self.description or "")) .. ")"
    end}
    function __TS__Symbol(description)
        return setmetatable({description = description}, symbolMetatable)
    end
    Symbol = {
        asyncDispose = __TS__Symbol("Symbol.asyncDispose"),
        dispose = __TS__Symbol("Symbol.dispose"),
        iterator = __TS__Symbol("Symbol.iterator"),
        hasInstance = __TS__Symbol("Symbol.hasInstance"),
        species = __TS__Symbol("Symbol.species"),
        toStringTag = __TS__Symbol("Symbol.toStringTag")
    }
end

local __TS__Iterator
do
    local function iteratorGeneratorStep(self)
        local co = self.____coroutine
        local status, value = coroutine.resume(co)
        if not status then
            error(value, 0)
        end
        if coroutine.status(co) == "dead" then
            return
        end
        return true, value
    end
    local function iteratorIteratorStep(self)
        local result = self:next()
        if result.done then
            return
        end
        return true, result.value
    end
    local function iteratorStringStep(self, index)
        index = index + 1
        if index > #self then
            return
        end
        return index, string.sub(self, index, index)
    end
    function __TS__Iterator(iterable)
        if type(iterable) == "string" then
            return iteratorStringStep, iterable, 0
        elseif iterable.____coroutine ~= nil then
            return iteratorGeneratorStep, iterable
        elseif iterable[Symbol.iterator] then
            local iterator = iterable[Symbol.iterator](iterable)
            return iteratorIteratorStep, iterator
        else
            return ipairs(iterable)
        end
    end
end
-- End of Lua Library inline imports
local ____exports = {}
local BuildSelectorUI = require("components.BuildSelector")
local Native = require("core.Native")
local Builds = require("data.WotlkBuilds")
local Model = require("model.ComposerModel")
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
local ButtonUI = require("widgets.Button")
local ChoiceUI = require("widgets.ChoiceSelect")
local ModalUI = require("widgets.Modal")
local ScrollUI = require("widgets.ScrollList")
local InputUI = require("widgets.TextInput")
local ToggleUI = require("widgets.Toggle")
local StepperUI = require("widgets.Stepper")
local GC = Model:composer()
local D = Model:data()
local P = Model:profiles()
local function colorForPhase(self, phase)
    if phase == "READY" or phase == "DONE" then
        return theme.colors.success
    end
    if phase == "ERROR" then
        return theme.colors.error
    end
    if phase == "PREPARING" or phase == "BUILDING" or phase == "ASSEMBLING" or phase == "TRAVEL" then
        return theme.colors.warning
    end
    return theme.colors.primary
end
local function classCanRole(self, classToken, role)
    local ____opt_2 = D.CLASS_ROLE
    if ____opt_2 ~= nil then
        ____opt_2 = ____opt_2[role]
    end
    local ____opt_result_4
    if ____opt_2 ~= nil then
        ____opt_result_4 = ____opt_2[classToken]
    end
    return ____opt_result_4 == true
end
local function humanCounts(self)
    local out = {TANK = 0, HEALER = 0, DPS = 0}
    local ____table_humanRoles_5 = Model:config().humanRoles
    if ____table_humanRoles_5 == nil then
        ____table_humanRoles_5 = {}
    end
    local roles = ____table_humanRoles_5
    for ____, human in ipairs(Model:humans()) do
        local role = roles[human.name]
        if role ~= nil then
            out[role] = out[role] + 1
        end
    end
    return out
end
local function buildDungeonModel(self)
    local sequence = {
        "TANK",
        "HEALER",
        "DPS",
        "DPS",
        "DPS"
    }
    local anchors = Model:humans()
    local usedHumans = {}
    local assigned = {}
    do
        local h = 0
        while h < #anchors do
            do
                local __continue13
                repeat
                    local human = anchors[h + 1]
                    local ____opt_6 = Model:config().humanRoles
                    if ____opt_6 ~= nil then
                        ____opt_6 = ____opt_6[human.name]
                    end
                    local role = ____opt_6
                    if role == nil then
                        __continue13 = true
                        break
                    end
                    do
                        local i = 0
                        while i < #sequence do
                            if sequence[i + 1] == role and assigned[i + 1] == nil then
                                assigned[i + 1] = human
                                usedHumans[h + 1] = true
                                break
                            end
                            i = i + 1
                        end
                    end
                    __continue13 = true
                until true
                if not __continue13 then
                    break
                end
            end
            h = h + 1
        end
    end
    local flat = {
        TANK = Model:requiredFlat("TANK"),
        HEALER = Model:requiredFlat("HEALER"),
        DPS = Model:requiredFlat("DPS")
    }
    local counters = {TANK = 0, HEALER = 0, DPS = 0}
    local preparedByRole = {TANK = {}, HEALER = {}, DPS = {}}
    if Model:plan().ready == true then
        for ____, member in ipairs(Model:planMembers()) do
            if member.human ~= true and preparedByRole[member.role] ~= nil then
                local ____preparedByRole_member_role_8 = preparedByRole[member.role]
                ____preparedByRole_member_role_8[#____preparedByRole_member_role_8 + 1] = member
            end
        end
    end
    local preparedIndex = {TANK = 0, HEALER = 0, DPS = 0}
    local result = {}
    do
        local i = 0
        while i < #sequence do
            do
                local __continue23
                repeat
                    local role = sequence[i + 1]
                    local human = assigned[i + 1]
                    if human ~= nil then
                        result[#result + 1] = {role = role, human = human}
                        __continue23 = true
                        break
                    end
                    counters[role] = counters[role] + 1
                    local botIndex = counters[role]
                    local exact = flat[role][botIndex]
                    local prepared = preparedByRole[role][preparedIndex[role] + 1]
                    preparedIndex[role] = preparedIndex[role] + 1
                    result[#result + 1] = {role = role, botIndex = botIndex, exact = exact, prepared = prepared}
                    __continue23 = true
                until true
                if not __continue23 then
                    break
                end
            end
            i = i + 1
        end
    end
    return result
end
local function specIdFromLabel(self, classId, label)
    local classDef = Builds.getClass(classId)
    if classDef == nil then
        return nil
    end
    for ____, spec in ipairs(classDef.specs) do
        if spec.label == label then
            return spec.id
        end
    end
    return nil
end
local function activitySubtitle(self)
    local cfg = Model:config()
    if cfg.mode == "RAID" then
        return ((tostring(cfg.size) .. " player  ·  ") .. (cfg.difficulty == "heroic" and "Heroic" or "Normal")) .. "  ·  Auto-enter after assembly"
    end
    local mode = cfg.difficulty == "alpha" and "Titan Rune Alpha" or (cfg.difficulty == "beta" and "Titan Rune Beta" or (cfg.difficulty == "gamma" and "Titan Rune Gamma" or (cfg.difficulty == "heroic" and "Heroic" or "Normal")))
    return (mode .. "  ·  5 player  ·  ") .. (cfg.activity == "random" and "Dungeon Finder chooses destination" or "Auto-enter after assembly")
end
function ____exports.createModernDashboard(self)
    local clearDynamicRows, refreshTemplates, refreshPeople, roleOrder, templatesModal, templateSave, builtinScroll, customScroll, builtinRows, customRows, humanScroll, humanRowsModal, pinRole, pinRoleButtons, pinToggle, pinScroll, pinRows
    function clearDynamicRows(self, rows)
        for ____, row in ipairs(rows) do
            row:Hide()
        end
    end
    function refreshTemplates(self)
        clearDynamicRows(nil, builtinRows)
        clearDynamicRows(nil, customRows)
        templateSave:setEnabled(Model:config().mode == "RAID")
        local builtins = Model:listBuiltinProfiles()
        do
            local i = 0
            while i < #builtins do
                local row = builtinRows[i + 1]
                if row == nil then
                    local panel = Native:createPanel(builtinScroll.content, theme.colors.surfaceRaised, theme.colors.border)
                    panel.frame:SetSize(438, 76)
                    local name = Native:createText(panel.frame, "", "GameFontHighlight")
                    name:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        10,
                        -10
                    )
                    name:SetWidth(310)
                    local info = Native:createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted)
                    info:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        10,
                        -38
                    )
                    info:SetWidth(318)
                    local load = ButtonUI:createButton(panel.frame, {text = "Load", width = 82, height = 32, accent = theme.colors.primary})
                    load.frame:SetPoint(
                        "RIGHT",
                        panel.frame,
                        "RIGHT",
                        -8,
                        0
                    )
                    panel.frame._name = name
                    panel.frame._info = info
                    panel.frame._load = load
                    builtinScroll:bindWheel(panel.frame)
                    builtinScroll:bindWheel(load.frame)
                    row = panel.frame
                    builtinRows[i + 1] = row
                end
                row:ClearAllPoints()
                row:SetPoint(
                    "TOPLEFT",
                    builtinScroll.content,
                    "TOPLEFT",
                    0,
                    -(i * 84)
                )
                row._name:SetText(builtins[i + 1])
                row._info:SetText(Model:profileDescription(builtins[i + 1]))
                local profileName = builtins[i + 1]
                row._load.frame:SetScript(
                    "OnMouseDown",
                    function()
                        Model:loadProfile(profileName)
                        templatesModal:hide()
                    end
                )
                row:Show()
                i = i + 1
            end
        end
        builtinScroll:setContentHeight(math.max(460, #builtins * 84))
        local customs = Model:listCustomProfiles()
        do
            local i = 0
            while i < #customs do
                local row = customRows[i + 1]
                if row == nil then
                    local panel = Native:createPanel(customScroll.content, theme.colors.surfaceRaised, theme.colors.border)
                    panel.frame:SetSize(438, 76)
                    local name = Native:createText(panel.frame, "", "GameFontHighlight")
                    name:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        10,
                        -10
                    )
                    name:SetWidth(250)
                    local info = Native:createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted)
                    info:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        10,
                        -34
                    )
                    info:SetWidth(270)
                    local load = ButtonUI:createButton(panel.frame, {text = "Load", width = 68, height = 30, accent = theme.colors.primary})
                    load.frame:SetPoint(
                        "RIGHT",
                        panel.frame,
                        "RIGHT",
                        -78,
                        0
                    )
                    local remove = ButtonUI:createButton(panel.frame, {text = "Delete", width = 66, height = 30, accent = theme.colors.error})
                    remove.frame:SetPoint(
                        "RIGHT",
                        panel.frame,
                        "RIGHT",
                        -8,
                        0
                    )
                    panel.frame._name = name
                    panel.frame._info = info
                    panel.frame._load = load
                    panel.frame._remove = remove
                    customScroll:bindWheel(panel.frame)
                    customScroll:bindWheel(load.frame)
                    customScroll:bindWheel(remove.frame)
                    row = panel.frame
                    customRows[i + 1] = row
                end
                row:ClearAllPoints()
                row:SetPoint(
                    "TOPLEFT",
                    customScroll.content,
                    "TOPLEFT",
                    0,
                    -(i * 84)
                )
                row._name:SetText(customs[i + 1])
                row._info:SetText(Model:profileDescription(customs[i + 1]))
                local profileName = customs[i + 1]
                row._load.frame:SetScript(
                    "OnMouseDown",
                    function()
                        Model:loadProfile(profileName)
                        templatesModal:hide()
                    end
                )
                row._remove.frame:SetScript(
                    "OnMouseDown",
                    function()
                        Model:deleteProfile(profileName)
                        refreshTemplates(nil)
                    end
                )
                row:Show()
                i = i + 1
            end
        end
        customScroll:setContentHeight(math.max(460, #customs * 84))
    end
    function refreshPeople(self)
        clearDynamicRows(nil, humanRowsModal)
        local list = Model:humans()
        do
            local i = 0
            while i < #list do
                local human = list[i + 1]
                local row = humanRowsModal[i + 1]
                if row == nil then
                    local panel = Native:createPanel(humanScroll.content, theme.colors.surfaceRaised, theme.colors.border)
                    panel.frame:SetSize(812, 42)
                    local icon = panel.frame:CreateTexture(nil, "ARTWORK")
                    icon:SetSize(26, 26)
                    icon:SetPoint(
                        "LEFT",
                        panel.frame,
                        "LEFT",
                        8,
                        0
                    )
                    local name = Native:createText(panel.frame, "", "GameFontHighlightSmall")
                    name:SetPoint(
                        "LEFT",
                        panel.frame,
                        "LEFT",
                        44,
                        0
                    )
                    name:SetWidth(250)
                    local buttons = {
                        TANK = ButtonUI:createButton(panel.frame, {text = "Tank", width = 78, height = 28, accent = theme.colors.tank}),
                        HEALER = ButtonUI:createButton(panel.frame, {text = "Healer", width = 78, height = 28, accent = theme.colors.healer}),
                        DPS = ButtonUI:createButton(panel.frame, {text = "DPS", width = 78, height = 28, accent = theme.colors.dps})
                    }
                    buttons.DPS.frame:SetPoint(
                        "RIGHT",
                        panel.frame,
                        "RIGHT",
                        -8,
                        0
                    )
                    buttons.HEALER.frame:SetPoint(
                        "RIGHT",
                        buttons.DPS.frame,
                        "LEFT",
                        -6,
                        0
                    )
                    buttons.TANK.frame:SetPoint(
                        "RIGHT",
                        buttons.HEALER.frame,
                        "LEFT",
                        -6,
                        0
                    )
                    panel.frame._icon = icon
                    panel.frame._name = name
                    panel.frame._buttons = buttons
                    humanScroll:bindWheel(panel.frame)
                    for ____, wheelRole in ipairs(roleOrder) do
                        humanScroll:bindWheel(buttons[wheelRole].frame)
                    end
                    row = panel.frame
                    humanRowsModal[i + 1] = row
                end
                row:ClearAllPoints()
                row:SetPoint(
                    "TOPLEFT",
                    humanScroll.content,
                    "TOPLEFT",
                    0,
                    -(i * 48)
                )
                Native:setClassIcon(
                    row._icon,
                    tostring(human.class)
                )
                row._name:SetText((((human.isPlayer and "YOU  ·  " or "") .. human.name) .. "  ·  ") .. Model:classLabel(tostring(human.class)))
                local ____opt_9 = Model:config().humanRoles
                if ____opt_9 ~= nil then
                    ____opt_9 = ____opt_9[human.name]
                end
                local selected = ____opt_9
                for ____, role in ipairs(roleOrder) do
                    local button = row._buttons[role]
                    local allowed = classCanRole(
                        nil,
                        tostring(human.class),
                        role
                    )
                    button:setEnabled(allowed)
                    button:setSelected(selected == role)
                    local humanNameCopy = human.name
                    local roleCopy = role
                    button.frame:SetScript(
                        "OnMouseDown",
                        function()
                            if allowed then
                                Model:setHumanRole(humanNameCopy, roleCopy)
                                refreshPeople(nil)
                            end
                        end
                    )
                end
                row:Show()
                i = i + 1
            end
        end
        humanScroll:setContentHeight(math.max(220, #list * 48))
        for ____, role in ipairs(roleOrder) do
            pinRoleButtons[role]:setSelected(pinRole == role)
        end
        pinToggle:refresh()
        clearDynamicRows(nil, pinRows)
        local pins = Model:pinnedMembers()
        do
            local i = 0
            while i < #pins do
                local pin = pins[i + 1]
                local row = pinRows[i + 1]
                if row == nil then
                    local panel = Native:createPanel(pinScroll.content, theme.colors.surfaceRaised, theme.colors.border)
                    panel.frame:SetSize(812, 40)
                    local name = Native:createText(panel.frame, "", "GameFontHighlightSmall")
                    name:SetPoint(
                        "LEFT",
                        panel.frame,
                        "LEFT",
                        10,
                        0
                    )
                    name:SetWidth(260)
                    local info = Native:createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted)
                    info:SetPoint(
                        "LEFT",
                        panel.frame,
                        "LEFT",
                        280,
                        0
                    )
                    local remove = ButtonUI:createButton(panel.frame, {text = "Remove", width = 78, height = 28, accent = theme.colors.error})
                    remove.frame:SetPoint(
                        "RIGHT",
                        panel.frame,
                        "RIGHT",
                        -6,
                        0
                    )
                    panel.frame._name = name
                    panel.frame._info = info
                    panel.frame._remove = remove
                    pinScroll:bindWheel(panel.frame)
                    pinScroll:bindWheel(remove.frame)
                    row = panel.frame
                    pinRows[i + 1] = row
                end
                row:ClearAllPoints()
                row:SetPoint(
                    "TOPLEFT",
                    pinScroll.content,
                    "TOPLEFT",
                    0,
                    -(i * 46)
                )
                row._name:SetText(tostring(pin.name))
                row._info:SetText((Model:roleLabel(pin.role) .. "  ·  ") .. (pin.required and "Required" or "Preferred"))
                local indexCopy = i + 1
                row._remove.frame:SetScript(
                    "OnMouseDown",
                    function()
                        Model:removePin(indexCopy)
                        refreshPeople(nil)
                    end
                )
                row:Show()
                i = i + 1
            end
        end
        pinScroll:setContentHeight(math.max(170, #pins * 46))
    end
    local frame = CreateFrame("Frame", "GroupComposerModernFrame", UIParent)
    frame:SetSize(1520, 900)
    frame:SetPoint(
        "CENTER",
        UIParent,
        "CENTER",
        0,
        0
    )
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript(
        "OnDragStart",
        function(____, ____self) return ____self:StartMoving() end
    )
    frame:SetScript(
        "OnDragStop",
        function(____, ____self) return ____self:StopMovingOrSizing() end
    )
    frame:Hide()
    local root = Native:createSolid(frame, theme.colors.background)
    root:SetAllPoints(frame)
    local rootOutline = Native:createPanel(frame, theme.colors.background, theme.colors.borderStrong)
    rootOutline.frame:SetAllPoints(frame)
    local header = Native:createPanel(frame, theme.colors.surface, theme.colors.border)
    header.frame:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        1,
        -1
    )
    header.frame:SetPoint(
        "TOPRIGHT",
        frame,
        "TOPRIGHT",
        -1,
        -1
    )
    header.frame:SetHeight(64)
    local mark = Native:createPanel(header.frame, theme.colors.surfaceRaised, theme.colors.primary)
    mark.frame:SetSize(38, 38)
    mark.frame:SetPoint(
        "LEFT",
        header.frame,
        "LEFT",
        18,
        0
    )
    local markText = Native:createText(mark.frame, "GC", "GameFontNormalLarge", theme.colors.primary)
    markText:SetPoint(
        "CENTER",
        mark.frame,
        "CENTER",
        0,
        0
    )
    markText:SetJustifyH("CENTER")
    local title = Native:createText(header.frame, "GROUP COMPOSER", "GameFontNormalLarge")
    title:SetPoint(
        "TOPLEFT",
        header.frame,
        "TOPLEFT",
        70,
        -12
    )
    local subtitle = Native:createText(header.frame, "Build the team you want, then let Composer prepare it.", "GameFontHighlightSmall", theme.colors.muted)
    subtitle:SetPoint(
        "TOPLEFT",
        title,
        "BOTTOMLEFT",
        0,
        -4
    )
    local backendDot = Native:createSolid(header.frame, theme.colors.muted, "ARTWORK")
    backendDot:SetSize(8, 8)
    backendDot:SetPoint(
        "RIGHT",
        header.frame,
        "RIGHT",
        -238,
        0
    )
    local backendText = Native:createText(header.frame, "Checking backend", "GameFontHighlightSmall", theme.colors.muted)
    backendText:SetPoint(
        "LEFT",
        backendDot,
        "RIGHT",
        8,
        0
    )
    local close = ButtonUI:createButton(
        header.frame,
        {
            text = "Close",
            width = 100,
            height = 32,
            accent = theme.colors.error,
            onClick = function() return frame:Hide() end
        }
    )
    close.frame:SetPoint(
        "RIGHT",
        header.frame,
        "RIGHT",
        -16,
        0
    )
    local sidebar = Native:createPanel(frame, theme.colors.surface, theme.colors.border)
    sidebar.frame:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        1,
        -65
    )
    sidebar.frame:SetPoint(
        "BOTTOMLEFT",
        frame,
        "BOTTOMLEFT",
        1,
        34
    )
    sidebar.frame:SetWidth(168)
    local navTitle = Native:createText(sidebar.frame, "PLAN", "GameFontNormalSmall", theme.colors.muted)
    navTitle:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -20
    )
    local navDungeon = ButtonUI:createButton(
        sidebar.frame,
        {
            text = "Dungeon",
            width = 136,
            height = 42,
            accent = theme.colors.primary,
            onClick = function() return Model:setMode("DUNGEON") end
        }
    )
    navDungeon.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -48
    )
    navDungeon.label:ClearAllPoints()
    navDungeon.label:SetPoint(
        "LEFT",
        navDungeon.frame,
        "LEFT",
        14,
        0
    )
    navDungeon.label:SetJustifyH("LEFT")
    local navRaid = ButtonUI:createButton(
        sidebar.frame,
        {
            text = "Raid",
            width = 136,
            height = 42,
            accent = theme.colors.warning,
            onClick = function() return Model:setMode("RAID") end
        }
    )
    navRaid.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -98
    )
    navRaid.label:ClearAllPoints()
    navRaid.label:SetPoint(
        "LEFT",
        navRaid.frame,
        "LEFT",
        14,
        0
    )
    navRaid.label:SetJustifyH("LEFT")
    local manageTitle = Native:createText(sidebar.frame, "MANAGE", "GameFontNormalSmall", theme.colors.muted)
    manageTitle:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -164
    )
    local function showTemplates()
    end
    local function showPeople()
    end
    local function showOptions()
    end
    local navTemplates = ButtonUI:createButton(
        sidebar.frame,
        {
            text = "Templates",
            width = 136,
            height = 38,
            onClick = function() return showTemplates(nil) end
        }
    )
    navTemplates.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -190
    )
    navTemplates.label:ClearAllPoints()
    navTemplates.label:SetPoint(
        "LEFT",
        navTemplates.frame,
        "LEFT",
        14,
        0
    )
    navTemplates.label:SetJustifyH("LEFT")
    local navPeople = ButtonUI:createButton(
        sidebar.frame,
        {
            text = "Humans & Pins",
            width = 136,
            height = 38,
            onClick = function() return showPeople(nil) end
        }
    )
    navPeople.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -234
    )
    navPeople.label:ClearAllPoints()
    navPeople.label:SetPoint(
        "LEFT",
        navPeople.frame,
        "LEFT",
        14,
        0
    )
    navPeople.label:SetJustifyH("LEFT")
    local navOptions = ButtonUI:createButton(
        sidebar.frame,
        {
            text = "Options",
            width = 136,
            height = 38,
            onClick = function() return showOptions(nil) end
        }
    )
    navOptions.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -278
    )
    navOptions.label:ClearAllPoints()
    navOptions.label:SetPoint(
        "LEFT",
        navOptions.frame,
        "LEFT",
        14,
        0
    )
    navOptions.label:SetJustifyH("LEFT")
    local sideHint = Native:createText(sidebar.frame, "Humans stay locked.\nExact builds only affect bot slots.", "GameFontHighlightSmall", theme.colors.muted)
    sideHint:SetPoint(
        "BOTTOMLEFT",
        sidebar.frame,
        "BOTTOMLEFT",
        16,
        18
    )
    sideHint:SetWidth(136)
    sideHint:SetJustifyV("TOP")
    local center = CreateFrame("Frame", nil, frame)
    center:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        184,
        -80
    )
    center:SetSize(986, 776)
    local status = Native:createPanel(frame, theme.colors.surface, theme.colors.borderStrong)
    status.frame:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        1186,
        -80
    )
    status.frame:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        -16,
        48
    )
    local footer = Native:createPanel(frame, theme.colors.surface, theme.colors.border)
    footer.frame:SetPoint(
        "BOTTOMLEFT",
        frame,
        "BOTTOMLEFT",
        184,
        10
    )
    footer.frame:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        -16,
        10
    )
    footer.frame:SetHeight(26)
    local footerText = Native:createText(footer.frame, "Ready.", "GameFontHighlightSmall", theme.colors.muted)
    footerText:SetPoint(
        "LEFT",
        footer.frame,
        "LEFT",
        10,
        0
    )
    footerText:SetPoint(
        "RIGHT",
        footer.frame,
        "RIGHT",
        -10,
        0
    )
    local activity = Native:createPanel(center, theme.colors.surface, theme.colors.borderStrong)
    activity.frame:SetPoint(
        "TOPLEFT",
        center,
        "TOPLEFT",
        0,
        0
    )
    activity.frame:SetPoint(
        "TOPRIGHT",
        center,
        "TOPRIGHT",
        0,
        0
    )
    activity.frame:SetHeight(116)
    local activityEyebrow = Native:createText(activity.frame, "ACTIVITY", "GameFontNormalSmall", theme.colors.muted)
    activityEyebrow:SetPoint(
        "TOPLEFT",
        activity.frame,
        "TOPLEFT",
        16,
        -12
    )
    local activityName = Native:createText(activity.frame, "Dungeon", "GameFontNormalLarge")
    activityName:SetPoint(
        "TOPLEFT",
        activityEyebrow,
        "BOTTOMLEFT",
        0,
        -6
    )
    activityName:SetWidth(300)
    local activitySub = Native:createText(activity.frame, "", "GameFontHighlightSmall", theme.colors.muted)
    activitySub:SetPoint(
        "TOPLEFT",
        activityName,
        "BOTTOMLEFT",
        0,
        -4
    )
    activitySub:SetWidth(300)
    local activityEligibility = Native:createText(activity.frame, "", "GameFontHighlightSmall", theme.colors.success)
    activityEligibility:SetPoint(
        "TOPLEFT",
        activitySub,
        "BOTTOMLEFT",
        0,
        -7
    )
    activityEligibility:SetWidth(300)
    local activityFieldLabel = Native:createText(activity.frame, "DUNGEON", "GameFontNormalSmall", theme.colors.muted)
    activityFieldLabel:SetPoint(
        "TOPLEFT",
        activity.frame,
        "TOPLEFT",
        330,
        -12
    )
    local difficultyFieldLabel = Native:createText(activity.frame, "DIFFICULTY", "GameFontNormalSmall", theme.colors.muted)
    difficultyFieldLabel:SetPoint(
        "TOPLEFT",
        activity.frame,
        "TOPLEFT",
        702,
        -12
    )
    local activitySelect = ChoiceUI:createChoiceSelect(
        activity.frame,
        {
            width = 344,
            maxVisible = 10,
            getItems = function() return Model:config().mode == "RAID" and Model:raidItems() or Model:dungeonItems() end,
            getValue = function() return Model:config().activity end,
            onChange = function(____, value)
                if Model:config().mode == "RAID" then
                    Model:setRaidActivity(tostring(value))
                else
                    Model:setDungeonActivity(tostring(value))
                end
            end
        }
    )
    activitySelect.frame:SetPoint(
        "TOPLEFT",
        activity.frame,
        "TOPLEFT",
        330,
        -36
    )
    local difficultySelect = ChoiceUI:createChoiceSelect(
        activity.frame,
        {
            width = 170,
            maxVisible = 7,
            getItems = function() return Model:config().mode == "RAID" and Model:raidDifficultyItems() or Model:difficultyItems() end,
            getValue = function() return Model:config().difficulty end,
            onChange = function(____, value) return Model:setDifficulty(tostring(value)) end
        }
    )
    difficultySelect.frame:SetPoint(
        "TOPLEFT",
        activity.frame,
        "TOPLEFT",
        702,
        -36
    )
    local raidSizeLabel = Native:createText(activity.frame, "RAID SIZE", "GameFontNormalSmall", theme.colors.muted)
    raidSizeLabel:SetPoint(
        "TOPLEFT",
        activity.frame,
        "TOPLEFT",
        702,
        -78
    )
    raidSizeLabel:Hide()
    local raidSizeButtons = {}
    for ____, size in ipairs({10, 20, 25, 40}) do
        local copy = size
        raidSizeButtons[size] = ButtonUI:createButton(
            activity.frame,
            {
                text = tostring(size),
                width = 52,
                height = 30,
                accent = theme.colors.warning,
                onClick = function() return Model:setRaidSize(copy) end
            }
        )
    end
    local humanPanel = Native:createPanel(center, theme.colors.surface, theme.colors.border)
    humanPanel.frame:SetPoint(
        "TOPLEFT",
        center,
        "TOPLEFT",
        0,
        -128
    )
    humanPanel.frame:SetPoint(
        "TOPRIGHT",
        center,
        "TOPRIGHT",
        0,
        -128
    )
    humanPanel.frame:SetHeight(78)
    local humanTitle = Native:createText(humanPanel.frame, "YOUR PARTY", "GameFontNormalSmall", theme.colors.muted)
    humanTitle:SetPoint(
        "TOPLEFT",
        humanPanel.frame,
        "TOPLEFT",
        16,
        -12
    )
    local humanIcon = humanPanel.frame:CreateTexture(nil, "ARTWORK")
    humanIcon:SetSize(34, 34)
    humanIcon:SetPoint(
        "BOTTOMLEFT",
        humanPanel.frame,
        "BOTTOMLEFT",
        16,
        9
    )
    Native:setClassIcon(humanIcon, "WARRIOR")
    local humanName = Native:createText(humanPanel.frame, "Choose your role", "GameFontNormal")
    humanName:SetPoint(
        "TOPLEFT",
        humanIcon,
        "TOPRIGHT",
        10,
        0
    )
    humanName:SetWidth(360)
    local humanSub = Native:createText(humanPanel.frame, "Real players are locked anchors.", "GameFontHighlightSmall", theme.colors.muted)
    humanSub:SetPoint(
        "TOPLEFT",
        humanName,
        "BOTTOMLEFT",
        0,
        -5
    )
    humanSub:SetWidth(430)
    local yourRoleLabel = Native:createText(humanPanel.frame, "YOUR ROLE", "GameFontNormalSmall", theme.colors.muted)
    yourRoleLabel:SetPoint(
        "TOPRIGHT",
        humanPanel.frame,
        "TOPRIGHT",
        -16,
        -12
    )
    local humanRoleButtons = {
        TANK = ButtonUI:createButton(humanPanel.frame, {text = "Tank", width = 96, height = 36, accent = theme.colors.tank}),
        HEALER = ButtonUI:createButton(humanPanel.frame, {text = "Healer", width = 96, height = 36, accent = theme.colors.healer}),
        DPS = ButtonUI:createButton(humanPanel.frame, {text = "DPS", width = 96, height = 36, accent = theme.colors.dps})
    }
    humanRoleButtons.TANK.frame:SetPoint(
        "TOPRIGHT",
        humanPanel.frame,
        "TOPRIGHT",
        -224,
        -34
    )
    humanRoleButtons.HEALER.frame:SetPoint(
        "LEFT",
        humanRoleButtons.TANK.frame,
        "RIGHT",
        8,
        0
    )
    humanRoleButtons.DPS.frame:SetPoint(
        "LEFT",
        humanRoleButtons.HEALER.frame,
        "RIGHT",
        8,
        0
    )
    for ____, role in ipairs({"TANK", "HEALER", "DPS"}) do
        local button = humanRoleButtons[role]
        local icon = Native:createIcon(button.frame, D.ROLE_ICON[role], 18)
        icon:SetPoint(
            "LEFT",
            button.frame,
            "LEFT",
            10,
            0
        )
        button.label:ClearAllPoints()
        button.label:SetPoint(
            "LEFT",
            button.frame,
            "LEFT",
            34,
            0
        )
        button.label:SetJustifyH("LEFT")
    end
    local composition = Native:createPanel(center, theme.colors.surface, theme.colors.border)
    composition.frame:SetPoint(
        "TOPLEFT",
        center,
        "TOPLEFT",
        0,
        -218
    )
    composition.frame:SetPoint(
        "BOTTOMRIGHT",
        center,
        "BOTTOMRIGHT",
        0,
        0
    )
    local compositionTitle = Native:createText(composition.frame, "PARTY COMPOSITION", "GameFontNormal")
    compositionTitle:SetPoint(
        "TOPLEFT",
        composition.frame,
        "TOPLEFT",
        18,
        -14
    )
    local compositionHint = Native:createText(composition.frame, "Auto-fill what you do not care about. Choose exact builds only where you do.", "GameFontHighlightSmall", theme.colors.muted)
    compositionHint:SetPoint(
        "TOPLEFT",
        compositionTitle,
        "BOTTOMLEFT",
        0,
        -4
    )
    local selectorContext = {mode = "DUNGEON", role = "DPS", index = 0}
    local buildSelector = BuildSelectorUI:createBuildSelector(
        frame,
        {
            allowCount = true,
            maxCount = 40,
            onApply = function(____, selection)
                if selectorContext.mode == "DUNGEON" then
                    Model:setDungeonExact(selectorContext.role, selectorContext.index, selection.classId, selection.specId)
                elseif selectorContext.mode == "RAID_ADD" then
                    Model:addRequiredBuild(selectorContext.role, selection.classId, selection.specId, selection.count)
                else
                    Model:replaceRequiredBuild(
                        selectorContext.role,
                        selectorContext.index,
                        selection.classId,
                        selection.specId,
                        selection.count
                    )
                end
            end
        }
    )
    local dungeonView = CreateFrame("Frame", nil, composition.frame)
    dungeonView:SetPoint(
        "TOPLEFT",
        composition.frame,
        "TOPLEFT",
        16,
        -62
    )
    dungeonView:SetPoint(
        "BOTTOMRIGHT",
        composition.frame,
        "BOTTOMRIGHT",
        -16,
        16
    )
    local dungeonRows = {}
    do
        local i = 0
        while i < 5 do
            local row = Native:createPanel(dungeonView, theme.colors.surfaceRaised, theme.colors.border)
            row.frame:SetHeight(66)
            row.frame:SetPoint(
                "TOPLEFT",
                dungeonView,
                "TOPLEFT",
                0,
                -(i * 72)
            )
            row.frame:SetPoint(
                "RIGHT",
                dungeonView,
                "RIGHT",
                0,
                0
            )
            local accent = Native:createSolid(row.frame, theme.colors.dps, "ARTWORK")
            accent:SetWidth(4)
            accent:SetPoint(
                "TOPLEFT",
                row.frame,
                "TOPLEFT",
                0,
                0
            )
            accent:SetPoint(
                "BOTTOMLEFT",
                row.frame,
                "BOTTOMLEFT",
                0,
                0
            )
            local roleIcon = row.frame:CreateTexture(nil, "ARTWORK")
            roleIcon:SetSize(28, 28)
            roleIcon:SetPoint(
                "LEFT",
                row.frame,
                "LEFT",
                16,
                0
            )
            local roleText = Native:createText(row.frame, "DPS", "GameFontNormal")
            roleText:SetPoint(
                "LEFT",
                roleIcon,
                "RIGHT",
                10,
                8
            )
            local slotText = Native:createText(row.frame, "Slot", "GameFontHighlightSmall", theme.colors.muted)
            slotText:SetPoint(
                "LEFT",
                roleIcon,
                "RIGHT",
                10,
                -10
            )
            local classIcon = row.frame:CreateTexture(nil, "ARTWORK")
            classIcon:SetSize(36, 36)
            classIcon:SetPoint(
                "LEFT",
                row.frame,
                "LEFT",
                174,
                0
            )
            classIcon:Hide()
            local specIcon = row.frame:CreateTexture(nil, "ARTWORK")
            specIcon:SetSize(28, 28)
            specIcon:SetPoint(
                "LEFT",
                classIcon,
                "RIGHT",
                8,
                0
            )
            specIcon:Hide()
            local name = Native:createText(row.frame, "Auto-fill bot", "GameFontNormal")
            name:SetPoint(
                "TOPLEFT",
                row.frame,
                "TOPLEFT",
                252,
                -15
            )
            name:SetWidth(350)
            local sub = Native:createText(row.frame, "Composer chooses a suitable build", "GameFontHighlightSmall", theme.colors.muted)
            sub:SetPoint(
                "TOPLEFT",
                name,
                "BOTTOMLEFT",
                0,
                -4
            )
            sub:SetWidth(390)
            local choose = ButtonUI:createButton(row.frame, {text = "Choose build", width = 130, height = 34, accent = theme.colors.primary})
            choose.frame:SetPoint(
                "RIGHT",
                row.frame,
                "RIGHT",
                -82,
                0
            )
            local auto = ButtonUI:createButton(row.frame, {text = "Auto", width = 66, height = 34})
            auto.frame:SetPoint(
                "RIGHT",
                row.frame,
                "RIGHT",
                -12,
                0
            )
            dungeonRows[#dungeonRows + 1] = {
                row = row,
                accent = accent,
                roleIcon = roleIcon,
                roleText = roleText,
                slotText = slotText,
                classIcon = classIcon,
                specIcon = specIcon,
                name = name,
                sub = sub,
                choose = choose,
                auto = auto
            }
            i = i + 1
        end
    end
    local raidView = CreateFrame("Frame", nil, composition.frame)
    raidView:SetPoint(
        "TOPLEFT",
        composition.frame,
        "TOPLEFT",
        16,
        -56
    )
    raidView:SetPoint(
        "BOTTOMRIGHT",
        composition.frame,
        "BOTTOMRIGHT",
        -16,
        16
    )
    raidView:Hide()
    local raidTab = "QUICK"
    local tabQuick = ButtonUI:createButton(raidView, {text = "Quick Composition", width = 164, height = 32, accent = theme.colors.primary})
    tabQuick.frame:SetPoint(
        "TOPLEFT",
        raidView,
        "TOPLEFT",
        0,
        0
    )
    local tabExact = ButtonUI:createButton(raidView, {text = "Specific Builds", width = 150, height = 32, accent = theme.colors.warning})
    tabExact.frame:SetPoint(
        "LEFT",
        tabQuick.frame,
        "RIGHT",
        8,
        0
    )
    local tabRoster = ButtonUI:createButton(raidView, {text = "Prepared Roster", width = 150, height = 32, accent = theme.colors.success})
    tabRoster.frame:SetPoint(
        "LEFT",
        tabExact.frame,
        "RIGHT",
        8,
        0
    )
    local quickView = CreateFrame("Frame", nil, raidView)
    quickView:SetPoint(
        "TOPLEFT",
        raidView,
        "TOPLEFT",
        0,
        -46
    )
    quickView:SetPoint(
        "BOTTOMRIGHT",
        raidView,
        "BOTTOMRIGHT",
        0,
        0
    )
    local exactView = CreateFrame("Frame", nil, raidView)
    exactView:SetAllPoints(quickView)
    exactView:Hide()
    local rosterView = CreateFrame("Frame", nil, raidView)
    rosterView:SetAllPoints(quickView)
    rosterView:Hide()
    local quickCards = {}
    roleOrder = {"TANK", "HEALER", "DPS"}
    do
        local i = 0
        while i < #roleOrder do
            local role = roleOrder[i + 1]
            local card = Native:createPanel(quickView, theme.colors.surfaceRaised, theme.colors.border)
            card.frame:SetSize(300, 158)
            local roleStrip = Native:createSolid(
                card.frame,
                Model:roleAccent(role),
                "ARTWORK"
            )
            roleStrip:SetHeight(3)
            roleStrip:SetPoint(
                "TOPLEFT",
                card.frame,
                "TOPLEFT",
                0,
                0
            )
            roleStrip:SetPoint(
                "TOPRIGHT",
                card.frame,
                "TOPRIGHT",
                0,
                0
            )
            card.frame:SetPoint(
                "TOPLEFT",
                quickView,
                "TOPLEFT",
                i * 312,
                -12
            )
            local icon = Native:createIcon(card.frame, D.ROLE_ICON[role], 34)
            icon:SetPoint(
                "TOPLEFT",
                card.frame,
                "TOPLEFT",
                14,
                -14
            )
            local label = Native:createText(
                card.frame,
                string.upper(Model:roleLabel(role)),
                "GameFontNormal",
                Model:roleAccent(role)
            )
            label:SetPoint(
                "LEFT",
                icon,
                "RIGHT",
                10,
                5
            )
            local note = Native:createText(card.frame, "Raid-wide role target", "GameFontHighlightSmall", theme.colors.muted)
            note:SetPoint(
                "LEFT",
                icon,
                "RIGHT",
                10,
                -12
            )
            local count = Native:createText(card.frame, "0", "GameFontNormalHuge")
            count:SetPoint(
                "TOPLEFT",
                card.frame,
                "TOPLEFT",
                18,
                -68
            )
            local botSlots = Native:createText(card.frame, "0 bot slots after humans", "GameFontHighlightSmall", theme.colors.muted)
            botSlots:SetPoint(
                "TOPLEFT",
                count,
                "BOTTOMLEFT",
                0,
                -7
            )
            local minus = ButtonUI:createButton(card.frame, {text = "-", width = 38, height = 34})
            local plus = ButtonUI:createButton(
                card.frame,
                {
                    text = "+",
                    width = 38,
                    height = 34,
                    accent = Model:roleAccent(role)
                }
            )
            minus.frame:SetPoint(
                "BOTTOMRIGHT",
                card.frame,
                "BOTTOMRIGHT",
                -58,
                12
            )
            plus.frame:SetPoint(
                "BOTTOMRIGHT",
                card.frame,
                "BOTTOMRIGHT",
                -12,
                12
            )
            local roleCopy = role
            minus.frame:SetScript(
                "OnMouseDown",
                function() return Model:setRoleTarget(
                    roleCopy,
                    Model:targetForRole(roleCopy) - 1
                ) end
            )
            plus.frame:SetScript(
                "OnMouseDown",
                function() return Model:setRoleTarget(
                    roleCopy,
                    Model:targetForRole(roleCopy) + 1
                ) end
            )
            quickCards[role] = {
                card = card,
                count = count,
                botSlots = botSlots,
                minus = minus,
                plus = plus
            }
            i = i + 1
        end
    end
    local quickSummary = Native:createPanel(quickView, theme.colors.background, theme.colors.border)
    quickSummary.frame:SetPoint(
        "TOPLEFT",
        quickView,
        "TOPLEFT",
        0,
        -198
    )
    quickSummary.frame:SetPoint(
        "TOPRIGHT",
        quickView,
        "TOPRIGHT",
        0,
        -198
    )
    quickSummary.frame:SetHeight(84)
    local quickTotalLabel = Native:createText(quickSummary.frame, "ROLE TOTAL", "GameFontNormalSmall", theme.colors.muted)
    quickTotalLabel:SetPoint(
        "TOPLEFT",
        quickSummary.frame,
        "TOPLEFT",
        14,
        -12
    )
    local quickTotal = Native:createText(quickSummary.frame, "25 / 25", "GameFontNormalLarge")
    quickTotal:SetPoint(
        "TOPLEFT",
        quickSummary.frame,
        "TOPLEFT",
        14,
        -34
    )
    local quickHelp = Native:createText(quickSummary.frame, "All three role counts are editable. Specific Builds can reserve only the class/spec slots you care about.", "GameFontHighlightSmall", theme.colors.muted)
    quickHelp:SetPoint(
        "TOPLEFT",
        quickSummary.frame,
        "TOPLEFT",
        122,
        -27
    )
    quickHelp:SetWidth(570)
    quickHelp:SetJustifyV("TOP")
    local resetRoles = ButtonUI:createButton(
        quickSummary.frame,
        {
            text = "Reset Standard",
            width = 132,
            height = 34,
            onClick = function() return Model:resetRoleTargets() end
        }
    )
    resetRoles.frame:SetPoint(
        "RIGHT",
        quickSummary.frame,
        "RIGHT",
        -14,
        0
    )
    local exactScroll = ScrollUI:createScrollList(exactView, 936, 386)
    exactScroll.frame:SetPoint(
        "TOPLEFT",
        exactView,
        "TOPLEFT",
        0,
        -4
    )
    local exactSections = {}
    for ____, role in ipairs(roleOrder) do
        local panel = Native:createPanel(exactScroll.content, theme.colors.background, theme.colors.border)
        panel.frame:SetWidth(906)
        local roleStrip = Native:createSolid(
            panel.frame,
            Model:roleAccent(role),
            "ARTWORK"
        )
        roleStrip:SetWidth(4)
        roleStrip:SetPoint(
            "TOPLEFT",
            panel.frame,
            "TOPLEFT",
            0,
            0
        )
        roleStrip:SetPoint(
            "BOTTOMLEFT",
            panel.frame,
            "BOTTOMLEFT",
            0,
            0
        )
        local icon = Native:createIcon(panel.frame, D.ROLE_ICON[role], 30)
        icon:SetPoint(
            "TOPLEFT",
            panel.frame,
            "TOPLEFT",
            16,
            -14
        )
        local label = Native:createText(
            panel.frame,
            string.upper(Model:roleLabel(role)),
            "GameFontNormal",
            Model:roleAccent(role)
        )
        label:SetPoint(
            "LEFT",
            icon,
            "RIGHT",
            10,
            5
        )
        local count = Native:createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted)
        count:SetPoint(
            "LEFT",
            icon,
            "RIGHT",
            10,
            -12
        )
        count:SetWidth(430)
        local add = ButtonUI:createButton(
            panel.frame,
            {
                text = "+ Add specific build",
                width = 154,
                height = 32,
                accent = Model:roleAccent(role)
            }
        )
        add.frame:SetPoint(
            "TOPRIGHT",
            panel.frame,
            "TOPRIGHT",
            -12,
            -12
        )
        local empty = Native:createText(
            panel.frame,
            ("No reserved builds. Composer will Auto-fill every remaining " .. string.lower(Model:roleLabel(role))) .. " slot.",
            "GameFontHighlightSmall",
            theme.colors.muted
        )
        empty:SetPoint(
            "TOPLEFT",
            panel.frame,
            "TOPLEFT",
            18,
            -68
        )
        empty:SetWidth(810)
        empty:SetJustifyV("TOP")
        exactScroll:bindWheel(panel.frame)
        exactScroll:bindWheel(add.frame)
        exactSections[role] = {
            panel = panel,
            count = count,
            add = add,
            empty = empty,
            rows = {}
        }
    end
    local groupCards = {}
    do
        local g = 0
        while g < 8 do
            local card = Native:createPanel(rosterView, theme.colors.background, theme.colors.border)
            local groupTitle = Native:createText(
                card.frame,
                "GROUP " .. tostring(g + 1),
                "GameFontNormalSmall",
                theme.colors.muted
            )
            groupTitle:SetPoint(
                "TOPLEFT",
                card.frame,
                "TOPLEFT",
                10,
                -10
            )
            local rows = {}
            do
                local r = 0
                while r < 5 do
                    local row = CreateFrame("Frame", nil, card.frame)
                    row:SetHeight(28)
                    row:SetPoint(
                        "TOPLEFT",
                        card.frame,
                        "TOPLEFT",
                        8,
                        -(34 + r * 30)
                    )
                    row:SetPoint(
                        "RIGHT",
                        card.frame,
                        "RIGHT",
                        -8,
                        0
                    )
                    local roleBar = Native:createSolid(row, theme.colors.dps, "ARTWORK")
                    roleBar:SetWidth(3)
                    roleBar:SetPoint(
                        "TOPLEFT",
                        row,
                        "TOPLEFT",
                        0,
                        0
                    )
                    roleBar:SetPoint(
                        "BOTTOMLEFT",
                        row,
                        "BOTTOMLEFT",
                        0,
                        0
                    )
                    local icon = row:CreateTexture(nil, "ARTWORK")
                    icon:SetSize(22, 22)
                    icon:SetPoint(
                        "LEFT",
                        row,
                        "LEFT",
                        8,
                        0
                    )
                    icon:Hide()
                    local name = Native:createText(row, "Empty", "GameFontHighlightSmall", theme.colors.muted)
                    name:SetPoint(
                        "LEFT",
                        row,
                        "LEFT",
                        38,
                        7
                    )
                    name:SetWidth(154)
                    local spec = Native:createText(row, "", "GameFontHighlightSmall", theme.colors.muted)
                    spec:SetPoint(
                        "LEFT",
                        row,
                        "LEFT",
                        38,
                        -8
                    )
                    spec:SetWidth(168)
                    rows[#rows + 1] = {
                        row = row,
                        roleBar = roleBar,
                        icon = icon,
                        name = name,
                        spec = spec
                    }
                    r = r + 1
                end
            end
            card.frame:Hide()
            groupCards[#groupCards + 1] = {card = card, groupTitle = groupTitle, rows = rows}
            g = g + 1
        end
    end
    local statusTitle = Native:createText(status.frame, "STATUS", "GameFontNormalSmall", theme.colors.muted)
    statusTitle:SetPoint(
        "TOPLEFT",
        status.frame,
        "TOPLEFT",
        16,
        -16
    )
    local phaseCard = Native:createPanel(status.frame, theme.colors.surfaceRaised, theme.colors.border)
    phaseCard.frame:SetPoint(
        "TOPLEFT",
        status.frame,
        "TOPLEFT",
        16,
        -40
    )
    phaseCard.frame:SetPoint(
        "TOPRIGHT",
        status.frame,
        "TOPRIGHT",
        -16,
        -40
    )
    phaseCard.frame:SetHeight(84)
    local phaseDot = Native:createSolid(phaseCard.frame, theme.colors.primary, "ARTWORK")
    phaseDot:SetSize(9, 9)
    phaseDot:SetPoint(
        "TOPLEFT",
        phaseCard.frame,
        "TOPLEFT",
        12,
        -16
    )
    local phaseText = Native:createText(phaseCard.frame, "Configure roster", "GameFontNormal")
    phaseText:SetPoint(
        "LEFT",
        phaseDot,
        "RIGHT",
        10,
        3
    )
    local phaseDetail = Native:createText(phaseCard.frame, "", "GameFontHighlightSmall", theme.colors.muted)
    phaseDetail:SetPoint(
        "TOPLEFT",
        phaseText,
        "BOTTOMLEFT",
        0,
        -4
    )
    phaseDetail:SetWidth(240)
    phaseDetail:SetJustifyV("TOP")
    local rosterCount = Native:createText(status.frame, "1 / 5", "GameFontNormalHuge")
    rosterCount:SetPoint(
        "TOPLEFT",
        status.frame,
        "TOPLEFT",
        16,
        -140
    )
    local sourceText = Native:createText(status.frame, "1 human  ·  4 bot slots", "GameFontHighlightSmall", theme.colors.muted)
    sourceText:SetPoint(
        "TOPLEFT",
        rosterCount,
        "BOTTOMLEFT",
        0,
        -5
    )
    local statusRoleChips = {}
    do
        local i = 0
        while i < #roleOrder do
            local role = roleOrder[i + 1]
            local chip = Native:createPanel(
                status.frame,
                theme.colors.background,
                Model:roleAccent(role)
            )
            chip.frame:SetSize(84, 32)
            chip.frame:SetPoint(
                "TOPLEFT",
                status.frame,
                "TOPLEFT",
                16 + i * 92,
                -198
            )
            local icon = Native:createIcon(chip.frame, D.ROLE_ICON[role], 17)
            icon:SetPoint(
                "LEFT",
                chip.frame,
                "LEFT",
                7,
                0
            )
            local label = Native:createText(
                chip.frame,
                "",
                "GameFontHighlightSmall",
                Model:roleAccent(role)
            )
            label:SetPoint(
                "LEFT",
                icon,
                "RIGHT",
                6,
                0
            )
            statusRoleChips[role] = {chip = chip, label = label}
            i = i + 1
        end
    end
    local progressBg = Native:createPanel(status.frame, theme.colors.background, theme.colors.border)
    progressBg.frame:SetPoint(
        "TOPLEFT",
        status.frame,
        "TOPLEFT",
        16,
        -242
    )
    progressBg.frame:SetSize(270, 10)
    local progressFill = Native:createSolid(progressBg.frame, theme.colors.primary, "ARTWORK")
    progressFill:SetPoint(
        "TOPLEFT",
        progressBg.frame,
        "TOPLEFT",
        2,
        -2
    )
    progressFill:SetPoint(
        "BOTTOMLEFT",
        progressBg.frame,
        "BOTTOMLEFT",
        2,
        2
    )
    progressFill:SetWidth(1)
    local progressText = Native:createText(status.frame, "", "GameFontHighlightSmall", theme.colors.muted)
    progressText:SetPoint(
        "TOPLEFT",
        status.frame,
        "TOPLEFT",
        16,
        -260
    )
    progressText:SetWidth(270)
    local coverageCard = Native:createPanel(status.frame, theme.colors.background, theme.colors.border)
    coverageCard.frame:SetPoint(
        "TOPLEFT",
        status.frame,
        "TOPLEFT",
        16,
        -298
    )
    coverageCard.frame:SetPoint(
        "TOPRIGHT",
        status.frame,
        "TOPRIGHT",
        -16,
        -286
    )
    coverageCard.frame:SetHeight(120)
    local coverageTitle = Native:createText(coverageCard.frame, "COVERAGE", "GameFontNormalSmall", theme.colors.muted)
    coverageTitle:SetPoint(
        "TOPLEFT",
        coverageCard.frame,
        "TOPLEFT",
        12,
        -12
    )
    local coverageText = Native:createText(coverageCard.frame, "Build a roster to inspect coverage.", "GameFontHighlightSmall", theme.colors.muted)
    coverageText:SetPoint(
        "TOPLEFT",
        coverageCard.frame,
        "TOPLEFT",
        12,
        -34
    )
    coverageText:SetWidth(246)
    coverageText:SetJustifyV("TOP")
    local classIcons = {}
    do
        local i = 0
        while i < 10 do
            local icon = coverageCard.frame:CreateTexture(nil, "ARTWORK")
            icon:SetSize(20, 20)
            icon:SetPoint(
                "BOTTOMLEFT",
                coverageCard.frame,
                "BOTTOMLEFT",
                12 + i * 25,
                10
            )
            icon:Hide()
            classIcons[#classIcons + 1] = icon
            i = i + 1
        end
    end
    local nextCard = Native:createPanel(status.frame, theme.colors.background, theme.colors.border)
    nextCard.frame:SetPoint(
        "TOPLEFT",
        status.frame,
        "TOPLEFT",
        16,
        -434
    )
    nextCard.frame:SetPoint(
        "TOPRIGHT",
        status.frame,
        "TOPRIGHT",
        -16,
        -414
    )
    nextCard.frame:SetHeight(126)
    local warningsTitle = Native:createText(nextCard.frame, "NEXT STEP", "GameFontNormalSmall", theme.colors.warning)
    warningsTitle:SetPoint(
        "TOPLEFT",
        nextCard.frame,
        "TOPLEFT",
        12,
        -12
    )
    local warningRows = {}
    do
        local i = 0
        while i < 3 do
            local row = Native:createText(nextCard.frame, "", "GameFontHighlightSmall", i == 0 and theme.colors.warning or theme.colors.muted)
            row:SetPoint(
                "TOPLEFT",
                nextCard.frame,
                "TOPLEFT",
                12,
                -(36 + i * 28)
            )
            row:SetWidth(246)
            row:SetJustifyV("TOP")
            warningRows[#warningRows + 1] = row
            i = i + 1
        end
    end
    local buildButton = ButtonUI:createButton(
        status.frame,
        {
            text = "Build & Prepare",
            width = 270,
            height = 44,
            accent = theme.colors.primary,
            onClick = function() return Model:buildAndPrepare() end
        }
    )
    buildButton.frame:SetPoint(
        "BOTTOMLEFT",
        status.frame,
        "BOTTOMLEFT",
        16,
        66
    )
    local function showAssembleConfirm()
    end
    local assembleButton = ButtonUI:createButton(
        status.frame,
        {
            text = "Assemble",
            width = 194,
            height = 42,
            accent = theme.colors.success,
            onClick = function() return showAssembleConfirm(nil) end
        }
    )
    assembleButton.frame:SetPoint(
        "BOTTOMLEFT",
        status.frame,
        "BOTTOMLEFT",
        16,
        18
    )
    local resetButton = ButtonUI:createButton(
        status.frame,
        {
            text = "Reset",
            width = 68,
            height = 42,
            accent = theme.colors.error,
            onClick = function() return Model:clearPlan() end
        }
    )
    resetButton.frame:SetPoint(
        "LEFT",
        assembleButton.frame,
        "RIGHT",
        8,
        0
    )
    templatesModal = ModalUI:createModal(frame, 1020, 720)
    templatesModal:setTitle("Raid Templates")
    templatesModal:setSubtitle("Coverage-first raid cores reserve key buffs; every unlisted slot stays Auto-filled.")
    local templateSaveLabel = Native:createText(templatesModal.content, "SAVE CURRENT", "GameFontNormalSmall", theme.colors.muted)
    templateSaveLabel:SetPoint(
        "TOPLEFT",
        templatesModal.content,
        "TOPLEFT",
        0,
        0
    )
    local templateName = InputUI:createTextInput(templatesModal.content, 300, 34)
    templateName.frame:SetPoint(
        "TOPLEFT",
        templatesModal.content,
        "TOPLEFT",
        0,
        -24
    )
    templateSave = ButtonUI:createButton(
        templatesModal.content,
        {
            text = "Save Current",
            width = 120,
            height = 34,
            accent = theme.colors.primary,
            onClick = function()
                if Model:config().mode ~= "RAID" then
                    Model:fireStatus("Templates are raid-only. Configure dungeon bot slots directly.")
                    return
                end
                local name = templateName:getText()
                if name ~= "" then
                    Model:saveProfile(name)
                    templateName:clear()
                    refreshTemplates(nil)
                end
            end
        }
    )
    templateSave.frame:SetPoint(
        "LEFT",
        templateName.frame,
        "RIGHT",
        8,
        0
    )
    local builtinTitle = Native:createText(templatesModal.content, "BUILT-IN RAID COMPS", "GameFontNormalSmall", theme.colors.muted)
    builtinTitle:SetPoint(
        "TOPLEFT",
        templatesModal.content,
        "TOPLEFT",
        0,
        -82
    )
    local customTitle = Native:createText(templatesModal.content, "MY TEMPLATES", "GameFontNormalSmall", theme.colors.muted)
    customTitle:SetPoint(
        "TOPLEFT",
        templatesModal.content,
        "TOPLEFT",
        472,
        -82
    )
    builtinScroll = ScrollUI:createScrollList(templatesModal.content, 448, 460)
    builtinScroll.frame:SetPoint(
        "TOPLEFT",
        templatesModal.content,
        "TOPLEFT",
        0,
        -110
    )
    customScroll = ScrollUI:createScrollList(templatesModal.content, 448, 460)
    customScroll.frame:SetPoint(
        "TOPLEFT",
        templatesModal.content,
        "TOPLEFT",
        472,
        -110
    )
    builtinRows = {}
    customRows = {}
    showTemplates = function()
        ChoiceUI:closeChoicePopup()
        builtinScroll:scrollToTop()
        customScroll:scrollToTop()
        refreshTemplates(nil)
        templatesModal:show()
    end
    local peopleModal = ModalUI:createModal(frame, 900, 650)
    peopleModal:setTitle("Humans & Pins")
    peopleModal:setSubtitle("Real players stay locked. Pins request named companions without turning humans into disposable roster slots.")
    local peopleHumanTitle = Native:createText(peopleModal.content, "HUMAN ANCHORS", "GameFontNormalSmall", theme.colors.muted)
    peopleHumanTitle:SetPoint(
        "TOPLEFT",
        peopleModal.content,
        "TOPLEFT",
        0,
        0
    )
    humanScroll = ScrollUI:createScrollList(peopleModal.content, 820, 220)
    humanScroll.frame:SetPoint(
        "TOPLEFT",
        peopleModal.content,
        "TOPLEFT",
        0,
        -26
    )
    humanRowsModal = {}
    local pinTitle = Native:createText(peopleModal.content, "PIN COMPANION", "GameFontNormalSmall", theme.colors.muted)
    pinTitle:SetPoint(
        "TOPLEFT",
        peopleModal.content,
        "TOPLEFT",
        0,
        -266
    )
    local pinInput = InputUI:createTextInput(peopleModal.content, 230, 34)
    pinInput.frame:SetPoint(
        "TOPLEFT",
        peopleModal.content,
        "TOPLEFT",
        0,
        -292
    )
    pinRole = "DPS"
    local pinRequired = false
    pinRoleButtons = {
        TANK = ButtonUI:createButton(peopleModal.content, {text = "Tank", width = 78, height = 34, accent = theme.colors.tank}),
        HEALER = ButtonUI:createButton(peopleModal.content, {text = "Healer", width = 78, height = 34, accent = theme.colors.healer}),
        DPS = ButtonUI:createButton(peopleModal.content, {text = "DPS", width = 78, height = 34, accent = theme.colors.dps})
    }
    pinRoleButtons.TANK.frame:SetPoint(
        "LEFT",
        pinInput.frame,
        "RIGHT",
        8,
        0
    )
    pinRoleButtons.HEALER.frame:SetPoint(
        "LEFT",
        pinRoleButtons.TANK.frame,
        "RIGHT",
        6,
        0
    )
    pinRoleButtons.DPS.frame:SetPoint(
        "LEFT",
        pinRoleButtons.HEALER.frame,
        "RIGHT",
        6,
        0
    )
    for ____, role in ipairs(roleOrder) do
        local roleCopy = role
        pinRoleButtons[role].frame:SetScript(
            "OnMouseDown",
            function()
                pinRole = roleCopy
                refreshPeople(nil)
            end
        )
    end
    pinToggle = ToggleUI:createToggle(
        peopleModal.content,
        "Required",
        function() return pinRequired end,
        function(____, value)
            pinRequired = value
        end
    )
    pinToggle.frame:SetPoint(
        "LEFT",
        pinRoleButtons.DPS.frame,
        "RIGHT",
        12,
        0
    )
    pinToggle.frame:SetWidth(98)
    local addPinButton = ButtonUI:createButton(
        peopleModal.content,
        {
            text = "Pin Member",
            width = 110,
            height = 34,
            accent = theme.colors.primary,
            onClick = function()
                local name = pinInput:getText()
                if name ~= "" then
                    Model:addPin(name, pinRole, pinRequired)
                    pinInput:clear()
                    refreshPeople(nil)
                end
            end
        }
    )
    addPinButton.frame:SetPoint(
        "TOPRIGHT",
        peopleModal.content,
        "TOPRIGHT",
        0,
        -292
    )
    local pinListTitle = Native:createText(peopleModal.content, "PINNED MEMBERS", "GameFontNormalSmall", theme.colors.muted)
    pinListTitle:SetPoint(
        "TOPLEFT",
        peopleModal.content,
        "TOPLEFT",
        0,
        -344
    )
    pinScroll = ScrollUI:createScrollList(peopleModal.content, 820, 170)
    pinScroll.frame:SetPoint(
        "TOPLEFT",
        peopleModal.content,
        "TOPLEFT",
        0,
        -370
    )
    pinRows = {}
    showPeople = function()
        ChoiceUI:closeChoicePopup()
        refreshPeople(nil)
        peopleModal:show()
    end
    local optionsModal = ModalUI:createModal(frame, 720, 620)
    optionsModal:setTitle("Composition Options")
    optionsModal:setSubtitle("Keep the common path simple. These controls tune how Composer fills unspecified slots.")
    local optionDefs = {
        {label = "Prefer guild bots", key = "preferGuild", hint = "Use familiar guild companions first when suitable."},
        {label = "Allow world fallback", key = "fillWorld", hint = "Fill remaining slots from the world/reserve pool."},
        {label = "Balance classes", key = "balanceClasses", hint = "Avoid lopsided class coverage when Auto is used."},
        {label = "Balance utility", key = "balanceUtility", hint = "Prefer a healthier mix of raid/dungeon utility."},
        {label = "Balance melee / ranged", key = "balanceRange", hint = "Avoid extreme melee/ranged skew when possible."},
        {label = "Avoid duplicate classes", key = "avoidDuplicateClasses", hint = "Stricter diversity preference. Exact builds still win."},
        {label = "Queue random dungeon after assembly", key = "queueAfterAssemble", hint = "Only applies to Random Dungeon."}
    }
    local optionToggles = {}
    do
        local i = 0
        while i < #optionDefs do
            local def = optionDefs[i + 1]
            local row = Native:createPanel(optionsModal.content, theme.colors.surfaceRaised, theme.colors.border)
            row.frame:SetPoint(
                "TOPLEFT",
                optionsModal.content,
                "TOPLEFT",
                0,
                -(i * 62)
            )
            row.frame:SetPoint(
                "RIGHT",
                optionsModal.content,
                "RIGHT",
                0,
                0
            )
            row.frame:SetHeight(52)
            local toggle = ToggleUI:createToggle(
                row.frame,
                def.label,
                function()
                    local ____opt_11 = Model:config().options
                    if ____opt_11 ~= nil then
                        ____opt_11 = ____opt_11[def.key]
                    end
                    return ____opt_11 == true
                end,
                function(____, value)
                    Model:config().options[def.key] = value
                    Model:touch("Composition option changed")
                end
            )
            toggle.frame:SetPoint(
                "TOPLEFT",
                row.frame,
                "TOPLEFT",
                12,
                -5
            )
            toggle.frame:SetWidth(280)
            local hint = Native:createText(row.frame, def.hint, "GameFontHighlightSmall", theme.colors.muted)
            hint:SetPoint(
                "TOPLEFT",
                row.frame,
                "TOPLEFT",
                42,
                -31
            )
            hint:SetWidth(580)
            optionToggles[#optionToggles + 1] = toggle
            i = i + 1
        end
    end
    local gearRow = Native:createPanel(optionsModal.content, theme.colors.surfaceRaised, theme.colors.borderStrong)
    gearRow.frame:SetPoint(
        "TOPLEFT",
        optionsModal.content,
        "TOPLEFT",
        0,
        -(#optionDefs * 62)
    )
    gearRow.frame:SetPoint(
        "RIGHT",
        optionsModal.content,
        "RIGHT",
        0,
        0
    )
    gearRow.frame:SetHeight(58)
    local gearTitle = Native:createText(gearRow.frame, "Minimum item level", "GameFontNormal")
    gearTitle:SetPoint(
        "TOPLEFT",
        gearRow.frame,
        "TOPLEFT",
        12,
        -9
    )
    local gearHint = Native:createText(gearRow.frame, "0 disables the floor. Guild/world bots below the configured value are rejected.", "GameFontHighlightSmall", theme.colors.muted)
    gearHint:SetPoint(
        "TOPLEFT",
        gearRow.frame,
        "TOPLEFT",
        12,
        -31
    )
    gearHint:SetWidth(470)
    local ____StepperUI_17 = StepperUI
    local ____StepperUI_createNumberStepper_18 = StepperUI.createNumberStepper
    local ____gearRow_frame_16 = gearRow.frame
    local ____opt_13 = Model:config().options
    if ____opt_13 ~= nil then
        ____opt_13 = ____opt_13.minimumItemLevel
    end
    local ____opt_13_15 = ____opt_13
    if ____opt_13_15 == nil then
        ____opt_13_15 = 0
    end
    local gearStepper = ____StepperUI_createNumberStepper_18(
        ____StepperUI_17,
        ____gearRow_frame_16,
        0,
        300,
        __TS__Number(____opt_13_15),
        function(____, value) return Model:setMinimumItemLevel(value) end
    )
    gearStepper.frame:SetPoint(
        "RIGHT",
        gearRow.frame,
        "RIGHT",
        -12,
        0
    )
    showOptions = function()
        ChoiceUI:closeChoicePopup()
        for ____, toggle in ipairs(optionToggles) do
            toggle:refresh()
        end
        local ____gearStepper_setValue_22 = gearStepper.setValue
        local ____opt_19 = Model:config().options
        if ____opt_19 ~= nil then
            ____opt_19 = ____opt_19.minimumItemLevel
        end
        local ____opt_19_21 = ____opt_19
        if ____opt_19_21 == nil then
            ____opt_19_21 = 0
        end
        ____gearStepper_setValue_22(
            gearStepper,
            __TS__Number(____opt_19_21),
            false
        )
        optionsModal:show()
    end
    local confirmModal = ModalUI:createModal(frame, 560, 270)
    local confirmText = Native:createText(confirmModal.content, "", "GameFontHighlight", theme.colors.muted)
    confirmText:SetPoint(
        "TOPLEFT",
        confirmModal.content,
        "TOPLEFT",
        8,
        -8
    )
    confirmText:SetWidth(490)
    confirmText:SetJustifyH("CENTER")
    confirmText:SetJustifyV("TOP")
    local confirmCancel = ButtonUI:createButton(
        confirmModal.content,
        {
            text = "Cancel",
            width = 120,
            height = 36,
            onClick = function() return confirmModal:hide() end
        }
    )
    confirmCancel.frame:SetPoint(
        "BOTTOMLEFT",
        confirmModal.content,
        "BOTTOMLEFT",
        112,
        0
    )
    local confirmGo = ButtonUI:createButton(
        confirmModal.content,
        {
            text = "Assemble",
            width = 120,
            height = 36,
            accent = theme.colors.success,
            onClick = function()
                confirmModal:hide()
                Model:assemble()
            end
        }
    )
    confirmGo.frame:SetPoint(
        "BOTTOMRIGHT",
        confirmModal.content,
        "BOTTOMRIGHT",
        -112,
        0
    )
    showAssembleConfirm = function()
        local p = Model:progress()
        if p.phase ~= "READY" then
            Model:fireStatus("Build & Prepare must finish first.")
            return
        end
        local retry = Model:isTravelRetry()
        local cfg = Model:config()
        local activity = Model:selectedActivityLabel()
        if retry then
            confirmModal:setTitle("Enter selected activity?")
            confirmModal:setSubtitle("The reviewed roster is already assembled.")
            confirmText:SetText(("Retry automatic entry for the complete group into " .. activity) .. ". The roster will not be rebuilt.")
            confirmGo:setText("Enter Activity")
        elseif cfg.mode == "DUNGEON" and cfg.activity == "random" then
            confirmModal:setTitle("Assemble prepared party?")
            confirmModal:setSubtitle("Composer will commit the reviewed roster.")
            confirmText:SetText("Prepared Playerbots attach directly. Real players keep normal group semantics. Dungeon Finder chooses the destination.")
            confirmGo:setText("Assemble")
        else
            confirmModal:setTitle("Assemble & enter?")
            confirmModal:setSubtitle("Composer will commit the reviewed roster.")
            confirmText:SetText(("After validation, the complete group will automatically enter " .. activity) .. ".")
            confirmGo:setText("Assemble")
        end
        confirmModal:show()
    end
    local function refreshActivity(self)
        local cfg = Model:config()
        activityName:SetText(Model:selectedActivityLabel())
        activitySub:SetText(activitySubtitle(nil))
        activityEligibility:SetText("ELIGIBILITY  ·  " .. Model:activityEligibilityText())
        activityFieldLabel:SetText(Model:config().mode == "RAID" and "RAID" or "DUNGEON")
        activitySelect:refresh()
        difficultySelect:refresh()
        local sizes = Model:supportedRaidSizes()
        local sizeIndex = 0
        if cfg.mode == "RAID" then
            raidSizeLabel:Show()
        else
            raidSizeLabel:Hide()
        end
        for ____, size in ipairs({10, 20, 25, 40}) do
            local button = raidSizeButtons[size]
            local supported = false
            for ____, allowed in ipairs(sizes) do
                if allowed == size then
                    supported = true
                    break
                end
            end
            if cfg.mode == "RAID" and supported then
                button.frame:ClearAllPoints()
                button.frame:SetPoint(
                    "TOPLEFT",
                    activity.frame,
                    "TOPLEFT",
                    680 + sizeIndex * 58,
                    -92
                )
                button:setSelected(__TS__Number(cfg.size) == size)
                button:setEnabled(true)
                button.frame:Show()
                sizeIndex = sizeIndex + 1
            else
                button.frame:Hide()
            end
        end
    end
    local function refreshHumanPanel(self)
        local list = Model:humans()
        local primary = #list > 0 and list[1] or nil
        if primary == nil then
            humanName:SetText("Waiting for player...")
            humanSub:SetText("Composer is refreshing human anchors.")
            humanIcon:Hide()
            for ____, role in ipairs(roleOrder) do
                humanRoleButtons[role]:setEnabled(false)
            end
            return
        end
        humanIcon:Show()
        Native:setClassIcon(
            humanIcon,
            tostring(primary.class)
        )
        humanName:SetText((primary.isPlayer and "YOU  ·  " or "") .. primary.name)
        humanSub:SetText(Model:classLabel(tostring(primary.class)) .. (#list > 1 and (("  ·  +" .. tostring(#list - 1)) .. " more human anchor") .. (#list > 2 and "s" or "") or ""))
        local ____opt_23 = Model:config().humanRoles
        if ____opt_23 ~= nil then
            ____opt_23 = ____opt_23[primary.name]
        end
        local selected = ____opt_23
        for ____, role in ipairs(roleOrder) do
            local allowed = classCanRole(
                nil,
                tostring(primary.class),
                role
            )
            humanRoleButtons[role]:setEnabled(allowed)
            humanRoleButtons[role]:setSelected(selected == role)
            local roleCopy = role
            local nameCopy = primary.name
            humanRoleButtons[role].frame:SetScript(
                "OnMouseDown",
                function()
                    if allowed then
                        Model:setHumanRole(nameCopy, roleCopy)
                    end
                end
            )
        end
    end
    local function refreshDungeon(self)
        local slots = buildDungeonModel(nil)
        do
            local i = 0
            while i < #dungeonRows do
                do
                    local __continue160
                    repeat
                        local widgets = dungeonRows[i + 1]
                        local slot = slots[i + 1]
                        local accent = Model:roleAccent(slot.role)
                        Native:setTextureColor(widgets.accent, accent)
                        widgets.row.outline:setColor(theme.colors.borderStrong)
                        widgets.roleIcon:SetTexture(D.ROLE_ICON[slot.role])
                        widgets.roleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                        widgets.roleText:SetText(Model:roleLabel(slot.role))
                        widgets.roleText:SetTextColor(accent[1], accent[2], accent[3], 1)
                        widgets.slotText:SetText(slot.human ~= nil and "Human anchor" or "Bot slot " .. tostring(slot.botIndex or 1))
                        if slot.human ~= nil then
                            Native:setClassIcon(
                                widgets.classIcon,
                                tostring(slot.human.class)
                            )
                            widgets.classIcon:Show()
                            widgets.specIcon:Hide()
                            widgets.name:SetText((slot.human.isPlayer and "YOU  ·  " or "") .. tostring(slot.human.name))
                            widgets.sub:SetText((Model:classLabel(tostring(slot.human.class)) .. "  ·  Locked ") .. Model:roleLabel(slot.role))
                            widgets.choose.frame:Hide()
                            widgets.auto.frame:Hide()
                            __continue160 = true
                            break
                        end
                        local exact = slot.exact
                        local prepared = slot.prepared
                        if prepared ~= nil and Model:plan().ready == true then
                            Native:setClassIcon(
                                widgets.classIcon,
                                tostring(prepared.class)
                            )
                            widgets.classIcon:Show()
                            local specId = specIdFromLabel(
                                nil,
                                tostring(prepared.class),
                                tostring(prepared.spec)
                            )
                            if specId ~= nil then
                                widgets.specIcon:SetTexture(Model:getSpecIcon(prepared.class, specId))
                                widgets.specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                                widgets.specIcon:Show()
                            else
                                widgets.specIcon:Hide()
                            end
                            widgets.name:SetText(tostring(prepared.name))
                            local ____self_28 = widgets.sub
                            local ____self_28_SetText_29 = ____self_28.SetText
                            local ____prepared_level_25 = prepared.level
                            if ____prepared_level_25 == nil then
                                ____prepared_level_25 = "?"
                            end
                            local ____temp_27 = ((("Lv " .. tostring(____prepared_level_25)) .. "  ·  ") .. tostring(prepared.spec or Model:classLabel(tostring(prepared.class)))) .. "  ·  "
                            local ____prepared_source_26 = prepared.source
                            if ____prepared_source_26 == nil then
                                ____prepared_source_26 = "Bot"
                            end
                            ____self_28_SetText_29(
                                ____self_28,
                                ____temp_27 .. tostring(____prepared_source_26)
                            )
                        elseif exact ~= nil then
                            Native:setClassIcon(widgets.classIcon, exact.classId)
                            widgets.classIcon:Show()
                            widgets.specIcon:SetTexture(Model:getSpecIcon(exact.classId, exact.specId))
                            widgets.specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                            widgets.specIcon:Show()
                            widgets.name:SetText((Model:getSpecLabel(exact.classId, exact.specId) .. " ") .. Model:classLabel(exact.classId))
                            widgets.sub:SetText("Exact build  ·  Composer will preserve this requirement")
                        else
                            widgets.classIcon:Hide()
                            widgets.specIcon:Hide()
                            widgets.name:SetText("Auto-fill bot")
                            widgets.sub:SetText(("Composer chooses a suitable " .. string.lower(Model:roleLabel(slot.role))) .. " build")
                        end
                        local roleCopy = slot.role
                        local botIndex = slot.botIndex or 1
                        widgets.choose:setText(exact ~= nil and "Change build" or "Choose build")
                        widgets.choose.frame:SetScript(
                            "OnMouseDown",
                            function()
                                selectorContext = {mode = "DUNGEON", role = roleCopy, index = botIndex}
                                local ____buildSelector_open_31 = buildSelector.open
                                local ____temp_30
                                if exact == nil then
                                    ____temp_30 = nil
                                else
                                    ____temp_30 = {role = roleCopy, classId = exact.classId, specId = exact.specId, count = 1}
                                end
                                ____buildSelector_open_31(buildSelector, roleCopy, ____temp_30, false)
                            end
                        )
                        widgets.choose.frame:Show()
                        widgets.auto:setEnabled(exact ~= nil)
                        widgets.auto.frame:SetScript(
                            "OnMouseDown",
                            function()
                                if exact ~= nil then
                                    Model:clearDungeonExact(roleCopy, botIndex)
                                end
                            end
                        )
                        widgets.auto.frame:Show()
                        __continue160 = true
                    until true
                    if not __continue160 then
                        break
                    end
                end
                i = i + 1
            end
        end
    end
    local function refreshQuickRaid(self)
        local ____table_size_32 = Model:config().size
        if ____table_size_32 == nil then
            ____table_size_32 = 25
        end
        local size = __TS__Number(____table_size_32)
        local total = Model:roleTargetTotal()
        for ____, role in ipairs(roleOrder) do
            local target = Model:targetForRole(role)
            quickCards[role].count:SetText(tostring(target))
            quickCards[role].botSlots:SetText(tostring(Model:remainingBotSlots(role)) .. " bot slots after humans")
            quickCards[role].minus:setEnabled(target > 0)
            quickCards[role].plus:setEnabled(target < size)
        end
        quickTotal:SetText((tostring(total) .. " / ") .. tostring(size))
        local valid = total == size
        local color = valid and theme.colors.success or theme.colors.warning
        quickTotal:SetTextColor(color[1], color[2], color[3], 1)
        quickSummary.outline:setColor(valid and theme.colors.border or theme.colors.warning)
    end
    local function refreshExactRaid(self)
        local cursor = 0
        for ____, role in ipairs(roleOrder) do
            local section = exactSections[role]
            local rows = Model:requiredBuilds(role)
            local reserved = Model:exactCount(role)
            local auto = math.max(
                0,
                Model:remainingBotSlots(role) - reserved
            )
            section.count:SetText(((tostring(reserved) .. " reserved · ") .. tostring(auto)) .. " Auto")
            section.add:setEnabled(reserved < Model:remainingBotSlots(role))
            local roleCopy = role
            section.add.frame:SetScript(
                "OnMouseDown",
                function()
                    if Model:exactCount(roleCopy) >= Model:remainingBotSlots(roleCopy) then
                        return
                    end
                    selectorContext = {mode = "RAID_ADD", role = roleCopy, index = -1}
                    buildSelector:open(roleCopy, {role = roleCopy, count = 1}, true)
                end
            )
            for ____, old in __TS__Iterator(section.rows) do
                old.panel.frame:Hide()
            end
            local sectionHeight = #rows == 0 and 106 or 70 + #rows * 60
            section.panel.frame:ClearAllPoints()
            section.panel.frame:SetPoint(
                "TOPLEFT",
                exactScroll.content,
                "TOPLEFT",
                0,
                -cursor
            )
            section.panel.frame:SetSize(906, sectionHeight)
            if #rows == 0 then
                section.empty:Show()
            else
                section.empty:Hide()
            end
            do
                local i = 0
                while i < #rows do
                    local build = rows[i + 1]
                    local widgets = section.rows[i]
                    if widgets == nil then
                        local panel = Native:createPanel(section.panel.frame, theme.colors.surfaceRaised, theme.colors.border)
                        panel.frame:SetSize(870, 52)
                        local classIcon = panel.frame:CreateTexture(nil, "ARTWORK")
                        classIcon:SetSize(32, 32)
                        classIcon:SetPoint(
                            "LEFT",
                            panel.frame,
                            "LEFT",
                            12,
                            0
                        )
                        local specIcon = panel.frame:CreateTexture(nil, "ARTWORK")
                        specIcon:SetSize(28, 28)
                        specIcon:SetPoint(
                            "LEFT",
                            classIcon,
                            "RIGHT",
                            7,
                            0
                        )
                        local name = Native:createText(panel.frame, "", "GameFontNormal")
                        name:SetPoint(
                            "TOPLEFT",
                            panel.frame,
                            "TOPLEFT",
                            86,
                            -11
                        )
                        name:SetWidth(520)
                        local count = Native:createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted)
                        count:SetPoint(
                            "TOPLEFT",
                            name,
                            "BOTTOMLEFT",
                            0,
                            -4
                        )
                        local edit = ButtonUI:createButton(panel.frame, {text = "Edit", width = 72, height = 30, accent = theme.colors.primary})
                        edit.frame:SetPoint(
                            "RIGHT",
                            panel.frame,
                            "RIGHT",
                            -54,
                            0
                        )
                        local remove = ButtonUI:createButton(panel.frame, {text = "X", width = 40, height = 30, accent = theme.colors.error})
                        remove.frame:SetPoint(
                            "RIGHT",
                            panel.frame,
                            "RIGHT",
                            -8,
                            0
                        )
                        exactScroll:bindWheel(panel.frame)
                        exactScroll:bindWheel(edit.frame)
                        exactScroll:bindWheel(remove.frame)
                        widgets = {
                            panel = panel,
                            classIcon = classIcon,
                            specIcon = specIcon,
                            name = name,
                            count = count,
                            edit = edit,
                            remove = remove
                        }
                        section.rows[i] = widgets
                    end
                    widgets.panel.frame:ClearAllPoints()
                    widgets.panel.frame:SetPoint(
                        "TOPLEFT",
                        section.panel.frame,
                        "TOPLEFT",
                        18,
                        -(62 + i * 60)
                    )
                    Native:setClassIcon(widgets.classIcon, build.classId)
                    widgets.specIcon:SetTexture(Model:getSpecIcon(build.classId, build.specId))
                    widgets.specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    widgets.name:SetText((Model:getSpecLabel(build.classId, build.specId) .. " ") .. Model:classLabel(build.classId))
                    widgets.count:SetText(("Reserved ×" .. tostring(build.count)) .. " · remaining role slots stay Auto")
                    local indexCopy = i
                    widgets.edit.frame:SetScript(
                        "OnMouseDown",
                        function()
                            selectorContext = {mode = "RAID_EDIT", role = roleCopy, index = indexCopy}
                            buildSelector:open(roleCopy, {role = roleCopy, classId = build.classId, specId = build.specId, count = build.count}, true)
                        end
                    )
                    widgets.remove.frame:SetScript(
                        "OnMouseDown",
                        function() return Model:removeRequiredBuild(roleCopy, indexCopy) end
                    )
                    widgets.panel.frame:Show()
                    i = i + 1
                end
            end
            cursor = cursor + (sectionHeight + 12)
        end
        exactScroll:setContentHeight(math.max(386, cursor))
    end
    local function refreshRoster(self)
        local cfg = Model:config()
        local ____cfg_size_33 = cfg.size
        if ____cfg_size_33 == nil then
            ____cfg_size_33 = 5
        end
        local totalGroups = math.max(
            1,
            math.ceil(__TS__Number(____cfg_size_33) / 5)
        )
        local columns = totalGroups <= 3 and totalGroups or (totalGroups <= 5 and 3 or 4)
        local cardWidth = math.floor((934 - (columns - 1) * 10) / columns)
        local cardHeight = 190
        do
            local g = 0
            while g < #groupCards do
                do
                    local __continue189
                    repeat
                        local widgets = groupCards[g + 1]
                        if g >= totalGroups then
                            widgets.card.frame:Hide()
                            __continue189 = true
                            break
                        end
                        local column = g % columns
                        local row = math.floor(g / columns)
                        widgets.card.frame:ClearAllPoints()
                        widgets.card.frame:SetPoint(
                            "TOPLEFT",
                            rosterView,
                            "TOPLEFT",
                            column * (cardWidth + 10),
                            -(8 + row * (cardHeight + 10))
                        )
                        widgets.card.frame:SetSize(cardWidth, cardHeight)
                        widgets.groupTitle:SetText("GROUP " .. tostring(g + 1))
                        local members = {}
                        for ____, member in ipairs(Model:planMembers()) do
                            if __TS__Number(member.subgroup) == g + 1 then
                                members[#members + 1] = member
                            end
                        end
                        do
                            local r = 0
                            while r < 5 do
                                local rowWidgets = widgets.rows[r + 1]
                                local member = members[r + 1]
                                if member == nil then
                                    rowWidgets.icon:Hide()
                                    rowWidgets.name:SetText("Empty")
                                    rowWidgets.name:SetTextColor(theme.colors.muted[1], theme.colors.muted[2], theme.colors.muted[3], 1)
                                    rowWidgets.spec:SetText("")
                                    Native:setTextureColor(rowWidgets.roleBar, theme.colors.borderStrong)
                                else
                                    Native:setClassIcon(
                                        rowWidgets.icon,
                                        tostring(member.class)
                                    )
                                    rowWidgets.icon:Show()
                                    rowWidgets.name:SetText((member.isPlayer and "YOU  ·  " or "") .. tostring(member.name))
                                    rowWidgets.name:SetTextColor(theme.colors.text[1], theme.colors.text[2], theme.colors.text[3], 1)
                                    local ____self_37 = rowWidgets.spec
                                    local ____self_37_SetText_38 = ____self_37.SetText
                                    local ____member_level_34 = member.level
                                    if ____member_level_34 == nil then
                                        ____member_level_34 = "?"
                                    end
                                    local ____temp_36 = ("Lv " .. tostring(____member_level_34)) .. " · "
                                    local ____member_spec_35 = member.spec
                                    if ____member_spec_35 == nil then
                                        ____member_spec_35 = Model:classLabel(tostring(member.class))
                                    end
                                    ____self_37_SetText_38(
                                        ____self_37,
                                        ____temp_36 .. tostring(____member_spec_35)
                                    )
                                    Native:setTextureColor(
                                        rowWidgets.roleBar,
                                        Model:roleAccent(member.role)
                                    )
                                end
                                r = r + 1
                            end
                        end
                        widgets.card.frame:Show()
                        __continue189 = true
                    until true
                    if not __continue189 then
                        break
                    end
                end
                g = g + 1
            end
        end
    end
    local function refreshRaidTabs(self)
        local ready = Model:plan().ready == true and Model:plan().valid == true
        tabQuick:setSelected(raidTab == "QUICK")
        tabExact:setSelected(raidTab == "EXACT")
        tabRoster:setSelected(raidTab == "ROSTER")
        tabRoster:setEnabled(ready)
        if raidTab == "EXACT" then
            quickView:Hide()
            exactView:Show()
            rosterView:Hide()
        elseif raidTab == "ROSTER" and ready then
            quickView:Hide()
            exactView:Hide()
            rosterView:Show()
        else
            raidTab = "QUICK"
            quickView:Show()
            exactView:Hide()
            rosterView:Hide()
            tabQuick:setSelected(true)
            tabRoster:setSelected(false)
        end
    end
    tabQuick.frame:SetScript(
        "OnMouseDown",
        function()
            raidTab = "QUICK"
            refreshRaidTabs(nil)
        end
    )
    tabExact.frame:SetScript(
        "OnMouseDown",
        function()
            raidTab = "EXACT"
            refreshRaidTabs(nil)
        end
    )
    tabRoster.frame:SetScript(
        "OnMouseDown",
        function()
            if Model:plan().ready == true and Model:plan().valid == true then
                raidTab = "ROSTER"
                refreshRaidTabs(nil)
            end
        end
    )
    local function refreshStatus(self)
        local p = Model:progress()
        local ____p_phase_39 = p.phase
        if ____p_phase_39 == nil then
            ____p_phase_39 = "IDLE"
        end
        local phase = tostring(____p_phase_39)
        local phaseColor = colorForPhase(nil, phase)
        Native:setTextureColor(phaseDot, phaseColor)
        phaseText:SetText(Model:isTravelRetry() and "Ready to enter activity" or Model:phaseLabel(phase))
        phaseText:SetTextColor(phaseColor[1], phaseColor[2], phaseColor[3], 1)
        local ____phaseDetail_SetText_41 = phaseDetail.SetText
        local ____p_detail_40 = p.detail
        if ____p_detail_40 == nil then
            ____p_detail_40 = ""
        end
        ____phaseDetail_SetText_41(
            phaseDetail,
            tostring(____p_detail_40)
        )
        local humanCount = #Model:humans()
        local ____table_size_42 = Model:config().size
        if ____table_size_42 == nil then
            ____table_size_42 = 5
        end
        local target = __TS__Number(____table_size_42)
        local ____temp_46
        if Model:plan().ready == true then
            local ____opt_43 = Model:plan().summary
            if ____opt_43 ~= nil then
                ____opt_43 = ____opt_43.total
            end
            local ____opt_43_45 = ____opt_43
            if ____opt_43_45 == nil then
                ____opt_43_45 = #Model:planMembers()
            end
            ____temp_46 = __TS__Number(____opt_43_45)
        else
            ____temp_46 = humanCount
        end
        local total = ____temp_46
        rosterCount:SetText((tostring(total) .. " / ") .. tostring(target))
        if Model:plan().ready == true then
            local ____sourceText_SetText_55 = sourceText.SetText
            local ____temp_50 = ((tostring(humanCount) .. " human") .. (humanCount == 1 and "" or "s")) .. "  ·  "
            local ____opt_47 = Model:plan().summary
            if ____opt_47 ~= nil then
                ____opt_47 = ____opt_47.guild
            end
            local ____opt_47_49 = ____opt_47
            if ____opt_47_49 == nil then
                ____opt_47_49 = 0
            end
            local ____temp_54 = (____temp_50 .. tostring(____opt_47_49)) .. " guild  ·  "
            local ____opt_51 = Model:plan().summary
            if ____opt_51 ~= nil then
                ____opt_51 = ____opt_51.world
            end
            local ____opt_51_53 = ____opt_51
            if ____opt_51_53 == nil then
                ____opt_51_53 = 0
            end
            ____sourceText_SetText_55(
                sourceText,
                (____temp_54 .. tostring(____opt_51_53)) .. " fallback"
            )
        else
            sourceText:SetText(((((tostring(humanCount) .. " human") .. (humanCount == 1 and "" or "s")) .. "  ·  ") .. tostring(math.max(0, target - humanCount))) .. " bot slots")
        end
        local ____self_57 = statusRoleChips.TANK.label
        local ____self_57_SetText_58 = ____self_57.SetText
        local ____table_tanks_56 = Model:config().tanks
        if ____table_tanks_56 == nil then
            ____table_tanks_56 = 0
        end
        ____self_57_SetText_58(
            ____self_57,
            tostring(____table_tanks_56) .. " T"
        )
        local ____self_60 = statusRoleChips.HEALER.label
        local ____self_60_SetText_61 = ____self_60.SetText
        local ____table_healers_59 = Model:config().healers
        if ____table_healers_59 == nil then
            ____table_healers_59 = 0
        end
        ____self_60_SetText_61(
            ____self_60,
            tostring(____table_healers_59) .. " H"
        )
        local ____self_63 = statusRoleChips.DPS.label
        local ____self_63_SetText_64 = ____self_63.SetText
        local ____table_dps_62 = Model:config().dps
        if ____table_dps_62 == nil then
            ____table_dps_62 = 0
        end
        ____self_63_SetText_64(
            ____self_63,
            tostring(____table_dps_62) .. " D"
        )
        local ratio = 0
        local ____p_total_65 = p.total
        if ____p_total_65 == nil then
            ____p_total_65 = 0
        end
        if __TS__Number(____p_total_65) > 0 then
            local ____p_current_66 = p.current
            if ____p_current_66 == nil then
                ____p_current_66 = 0
            end
            ratio = math.min(
                1,
                __TS__Number(____p_current_66) / __TS__Number(p.total)
            )
        elseif phase == "READY" or phase == "DONE" then
            ratio = 1
        end
        progressFill:SetWidth(math.max(1, 282 * ratio))
        Native:setTextureColor(progressFill, phaseColor)
        local ____progressText_SetText_73 = progressText.SetText
        local ____temp_72
        if phase == "PREPARING" or phase == "ASSEMBLING" or phase == "READY" or phase == "DONE" then
            local ____p_current_67 = p.current
            if ____p_current_67 == nil then
                ____p_current_67 = 0
            end
            local ____temp_69 = tostring(____p_current_67) .. " / "
            local ____p_total_68 = p.total
            if ____p_total_68 == nil then
                ____p_total_68 = 0
            end
            local ____temp_71 = (____temp_69 .. tostring(____p_total_68)) .. "  ·  "
            local ____p_detail_70 = p.detail
            if ____p_detail_70 == nil then
                ____p_detail_70 = ""
            end
            ____temp_72 = ____temp_71 .. tostring(____p_detail_70)
        else
            ____temp_72 = ""
        end
        ____progressText_SetText_73(progressText, ____temp_72)
        local ____coverageText_SetText_76 = coverageText.SetText
        local ____opt_74 = Model:plan().summary
        if ____opt_74 ~= nil then
            ____opt_74 = ____opt_74.utility
        end
        ____coverageText_SetText_76(
            coverageText,
            ____opt_74 ~= nil and Model:coverageDisplay() or "Build a roster to inspect utility coverage."
        )
        local seen = {}
        local iconIndex = 0
        for ____, member in ipairs(Model:planMembers()) do
            local cls = tostring(member.class or "")
            if cls ~= "" and cls ~= "UNKNOWN" and seen[cls] ~= true and iconIndex < #classIcons then
                seen[cls] = true
                Native:setClassIcon(classIcons[iconIndex + 1], cls)
                classIcons[iconIndex + 1]:Show()
                iconIndex = iconIndex + 1
            end
        end
        do
            local i = iconIndex
            while i < #classIcons do
                classIcons[i + 1]:Hide()
                i = i + 1
            end
        end
        local warnings = Model:planWarnings()
        do
            local i = 0
            while i < #warningRows do
                local text
                if i == 0 and phase == "ERROR" then
                    text = "Adjust the highlighted requirement, then Build & Prepare again."
                elseif phase == "ERROR" then
                    text = warnings[i]
                else
                    text = warnings[i + 1]
                end
                if text == nil and i == 0 then
                    if phase == "READY" then
                        text = Model:isTravelRetry() and "Clear the travel blocker, then enter the activity." or "Review the prepared roster, then assemble."
                    elseif phase == "PREPARING" then
                        text = "Composer is provisioning and validating the selected bots."
                    elseif not Model:humanReady() then
                        text = "Choose a legal role for every real player."
                    else
                        local ____temp_79 = Model:config().mode == "RAID"
                        if ____temp_79 then
                            local ____temp_78 = Model:roleTargetTotal()
                            local ____table_size_77 = Model:config().size
                            if ____table_size_77 == nil then
                                ____table_size_77 = 25
                            end
                            ____temp_79 = ____temp_78 ~= __TS__Number(____table_size_77)
                        end
                        if ____temp_79 then
                            local ____table_size_80 = Model:config().size
                            if ____table_size_80 == nil then
                                ____table_size_80 = 25
                            end
                            text = ("Role counts must total " .. tostring(____table_size_80)) .. " before preparing."
                        else
                            text = "Build & Prepare when the composition looks right."
                        end
                    end
                end
                warningRows[i + 1]:SetText(tostring(text or ""))
                i = i + 1
            end
        end
        local ____buildButton_setEnabled_85 = buildButton.setEnabled
        local ____temp_84 = Model:humanReady() and not Model:isBusy()
        if ____temp_84 then
            local ____temp_83 = Model:config().mode ~= "RAID"
            if not ____temp_83 then
                local ____temp_82 = Model:roleTargetTotal()
                local ____table_size_81 = Model:config().size
                if ____table_size_81 == nil then
                    ____table_size_81 = 25
                end
                ____temp_83 = ____temp_82 == __TS__Number(____table_size_81)
            end
            ____temp_84 = ____temp_83
        end
        ____buildButton_setEnabled_85(buildButton, ____temp_84)
        assembleButton:setEnabled(Model:plan().ready == true and Model:plan().valid == true and phase == "READY")
        assembleButton:setText(Model:isTravelRetry() and "Enter Activity" or (Model:config().mode == "RAID" and "Assemble Raid" or "Assemble Party"))
        assembleButton:setSelected(Model:plan().ready == true and Model:plan().valid == true and phase == "READY")
    end
    local function refresh(self)
        if not frame:IsShown() then
            return
        end
        local raid = Model:config().mode == "RAID"
        navDungeon:setSelected(not raid)
        navRaid:setSelected(raid)
        backendText:SetText(GC.backendSeen == true and "Backend connected" or "Checking backend")
        Native:setTextureColor(backendDot, GC.backendSeen == true and theme.colors.success or theme.colors.muted)
        refreshActivity(nil)
        refreshHumanPanel(nil)
        compositionTitle:SetText(raid and "RAID COMPOSITION" or "FIVE-PLAYER PARTY")
        compositionHint:SetText(raid and "Start simple with role counts. Add exact class/spec builds only where you care." or "Each bot slot can stay Auto or use one exact class/spec build.")
        if raid then
            dungeonView:Hide()
            raidView:Show()
            refreshQuickRaid(nil)
            refreshExactRaid(nil)
            refreshRoster(nil)
            refreshRaidTabs(nil)
        else
            raidView:Hide()
            dungeonView:Show()
            refreshDungeon(nil)
        end
        refreshStatus(nil)
    end
    local function applyScale(self)
        local width = UIParent:GetWidth() or 1920
        local height = UIParent:GetHeight() or 1080
        local available = math.min((width - 24) / 1520, (height - 24) / 900)
        local maxScale = width >= 3000 and 1.22 or (width >= 2400 and 1.16 or 1.1)
        frame:SetScale(math.max(
            0.66,
            math.min(maxScale, available)
        ))
    end
    local dashboard
    dashboard = {
        frame = frame,
        show = function()
            ChoiceUI:closeChoicePopup()
            applyScale(nil)
            frame:Show()
            refresh(nil)
            Model:requestAnchors()
            Model:requestStatus()
        end,
        hide = function()
            ChoiceUI:closeChoicePopup()
            frame:Hide()
        end,
        toggle = function()
            if frame:IsShown() then
                dashboard:hide()
            else
                dashboard:show()
            end
        end,
        refresh = function() return refresh(nil) end,
        applyScale = function() return applyScale(nil) end
    }
    GC.Toggle = function() return dashboard:toggle() end
    GC:RegisterCallback(
        "CONFIG_CHANGED",
        function() return refresh(nil) end
    )
    GC:RegisterCallback(
        "PLAN_CHANGED",
        function()
            if Model:config().mode == "RAID" and Model:plan().ready == true and Model:plan().valid == true then
                raidTab = "ROSTER"
            end
            refresh(nil)
        end
    )
    GC:RegisterCallback(
        "PROGRESS_CHANGED",
        function() return refresh(nil) end
    )
    GC:RegisterCallback(
        "HUMANS_CHANGED",
        function() return refresh(nil) end
    )
    GC:RegisterCallback(
        "PROFILES_CHANGED",
        function()
            if templatesModal.frame:IsShown() then
                refreshTemplates(nil)
            end
            refresh(nil)
        end
    )
    GC:RegisterCallback(
        "STATUS",
        function(____, text)
            footerText:SetText(tostring(text or "Ready."))
            refresh(nil)
        end
    )
    GC:RegisterCallback(
        "DISPLAY_CHANGED",
        function() return applyScale(nil) end
    )
    return dashboard
end
return ____exports
 end,
["main"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____BuildSelector = require("components.BuildSelector")
local createBuildSelector = ____BuildSelector.createBuildSelector
local ____ModernDashboard = require("components.ModernDashboard")
local createModernDashboard = ____ModernDashboard.createModernDashboard
local ____WotlkBuilds = require("data.WotlkBuilds")
local getClassesForRole = ____WotlkBuilds.getClassesForRole
local getSpecsForRole = ____WotlkBuilds.getSpecsForRole
local GC = _G.GroupComposer
local dashboard = nil
local function ensureDashboard()
    if dashboard ~= nil then
        return dashboard
    end
    if _G.CreateFrame == nil or GC == nil or GC.config == nil then
        return nil
    end
    dashboard = createModernDashboard(nil)
    _G.GroupComposerModernUI.dashboard = dashboard
    return dashboard
end
_G.GroupComposerModernUI = {
    version = "0.5.0",
    dashboard = nil,
    ensureDashboard = function() return ensureDashboard() end,
    createBuildSelector = function(...) return createBuildSelector(nil, ...) end,
    createModernDashboard = function() return createModernDashboard(nil) end,
    getClassesForRole = function(role) return getClassesForRole(role) end,
    getSpecsForRole = function(classId, role) return getSpecsForRole(classId, role) end
}
if GC ~= nil then
    GC.Toggle = function()
        local ui = ensureDashboard()
        if ui ~= nil then
            ui:toggle()
        end
    end
end
return ____exports
 end,
["layout.Stack"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
function ____exports.createStack(self, parent, options)
    if options == nil then
        options = {}
    end
    local frame = CreateFrame("Frame", nil, parent)
    local direction = options.direction or "vertical"
    local gap = options.gap or 0
    local padding = options.padding or 0
    local cursor = 0
    return {
        frame = frame,
        add = function(self, child, width, height)
            child:ClearAllPoints()
            if direction == "horizontal" then
                child:SetPoint(
                    "TOPLEFT",
                    frame,
                    "TOPLEFT",
                    padding + cursor,
                    -padding
                )
                cursor = cursor + (width + gap)
            else
                child:SetPoint(
                    "TOPLEFT",
                    frame,
                    "TOPLEFT",
                    padding,
                    -(padding + cursor)
                )
                cursor = cursor + (height + gap)
            end
        end,
        reset = function(self)
            cursor = 0
        end
    }
end
return ____exports
 end,
}
local ____entry = require("main", ...)
return ____entry

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
    background = {0.012, 0.018, 0.026, 0.985},
    scrim = {0, 0, 0, 0.62},
    surface = {0.025, 0.035, 0.048, 1},
    surfaceRaised = {0.038, 0.052, 0.071, 1},
    surfaceHover = {0.055, 0.075, 0.1, 1},
    border = {0.075, 0.105, 0.145, 1},
    borderStrong = {0.145, 0.205, 0.275, 1},
    text = {0.94, 0.96, 0.99, 1},
    muted = {0.58, 0.65, 0.74, 1},
    primary = {0.2, 0.57, 0.96, 1},
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
    local label = createText(nil, frame, options.text, "GameFontHighlightSmall")
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
        frame:SetAlpha(enabled and 1 or 0.35)
        outline:setColor(selected and accent or theme.colors.border)
        setTextureColor(nil, background, selected and theme.colors.surfaceHover or theme.colors.surfaceRaised)
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
    local title = createText(nil, panel.frame, "Choose Build", "GameFontNormalLarge")
    title:SetPoint(
        "TOPLEFT",
        panel.frame,
        "TOPLEFT",
        theme.spacing.lg,
        -theme.spacing.lg
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
        -theme.spacing.xs
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
        -72
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
local createText = ____Native.createText
local setClassIcon = ____Native.setClassIcon
local ____WotlkBuilds = require("data.WotlkBuilds")
local getClass = ____WotlkBuilds.getClass
local getClassesForRole = ____WotlkBuilds.getClassesForRole
local getSpecsForRole = ____WotlkBuilds.getSpecsForRole
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
    local refresh, modal, leftPanel, rightPanel, specEmpty, summaryClassIcon, summaryIcon, summaryText, summarySub, currentRole, currentClass, currentSpec, apply, classTiles, specTiles
    function refresh(self)
        modal:setTitle(("Choose " .. roleLabel(nil, currentRole)) .. " Build")
        modal:setSubtitle(("Pick a class on the left, then a valid " .. string.lower(roleLabel(nil, currentRole))) .. " spec on the right.")
        local validClasses = getClassesForRole(currentRole)
        local classIndex = 0
        for ____, tile in ipairs(classTiles) do
            local valid = false
            for ____, classDef in ipairs(validClasses) do
                if classDef.id == tile.classDef.id then
                    valid = true
                    break
                end
            end
            if valid then
                local column = classIndex % 4
                local row = math.floor(classIndex / 4)
                tile.button.frame:ClearAllPoints()
                tile.button.frame:SetPoint(
                    "TOPLEFT",
                    leftPanel.frame,
                    "TOPLEFT",
                    theme.spacing.md + column * 92,
                    -(42 + row * 90)
                )
                tile.button:setSelected(tile.classDef.id == currentClass)
                tile.button.frame:Show()
                classIndex = classIndex + 1
            else
                tile.button.frame:Hide()
            end
        end
        local specIndex = 0
        for ____, tile in ipairs(specTiles) do
            local visible = false
            if currentClass ~= nil and tile.classId == currentClass then
                for ____, validSpec in ipairs(getSpecsForRole(currentClass, currentRole)) do
                    if validSpec.id == tile.spec.id then
                        visible = true
                        break
                    end
                end
            end
            if visible then
                local column = specIndex % 3
                local row = math.floor(specIndex / 3)
                tile.button.frame:ClearAllPoints()
                tile.button.frame:SetPoint(
                    "TOPLEFT",
                    rightPanel.frame,
                    "TOPLEFT",
                    theme.spacing.md + column * 116,
                    -(48 + row * 104)
                )
                tile.button:setSelected(tile.spec.id == currentSpec)
                tile.button.frame:Show()
                specIndex = specIndex + 1
            else
                tile.button.frame:Hide()
            end
        end
        if currentClass == nil then
            specEmpty:Show()
        else
            specEmpty:Hide()
        end
        local ____temp_0
        if currentClass == nil then
            ____temp_0 = nil
        else
            ____temp_0 = getClass(currentClass)
        end
        local selectedClass = ____temp_0
        local selectedSpec
        if currentClass ~= nil and currentSpec ~= nil then
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
        if selectedClass ~= nil and selectedSpec ~= nil then
            summaryIcon:SetTexture(selectedSpec.icon)
            summaryIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            summaryText:SetText((selectedSpec.label .. " ") .. selectedClass.label)
            summarySub:SetText(roleLabel(nil, currentRole) .. " build selected")
            apply:setEnabled(true)
        else
            summaryIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            summaryIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            summaryIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            summaryIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            summaryText:SetText(currentClass == nil and "Choose a class" or "Choose a specialization")
            summarySub:SetText(("Only legal " .. roleLabel(nil, currentRole)) .. " choices are shown.")
            apply:setEnabled(false)
        end
        local accent = roleAccent(nil, currentRole)
        leftPanel.outline:setColor(accent)
        rightPanel.outline:setColor(accent)
    end
    modal = createModal(nil, parent, 820, 500)
    leftPanel = createPanel(nil, modal.content, theme.colors.surface, theme.colors.border)
    leftPanel.frame:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        0,
        0
    )
    leftPanel.frame:SetSize(390, 330)
    rightPanel = createPanel(nil, modal.content, theme.colors.surface, theme.colors.border)
    rightPanel.frame:SetPoint(
        "TOPRIGHT",
        modal.content,
        "TOPRIGHT",
        0,
        0
    )
    rightPanel.frame:SetSize(374, 330)
    local classTitle = createText(
        nil,
        leftPanel.frame,
        "CLASS",
        "GameFontNormalSmall",
        theme.colors.muted
    )
    classTitle:SetPoint(
        "TOPLEFT",
        leftPanel.frame,
        "TOPLEFT",
        theme.spacing.md,
        -theme.spacing.md
    )
    local specTitle = createText(
        nil,
        rightPanel.frame,
        "SPECIALIZATION",
        "GameFontNormalSmall",
        theme.colors.muted
    )
    specTitle:SetPoint(
        "TOPLEFT",
        rightPanel.frame,
        "TOPLEFT",
        theme.spacing.md,
        -theme.spacing.md
    )
    specEmpty = createText(
        nil,
        rightPanel.frame,
        "Choose a class to see only the specs that can fill this role.",
        "GameFontHighlightSmall",
        theme.colors.muted
    )
    specEmpty:SetPoint(
        "TOPLEFT",
        rightPanel.frame,
        "TOPLEFT",
        theme.spacing.md,
        -54
    )
    specEmpty:SetWidth(330)
    specEmpty:SetJustifyV("TOP")
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
    summary.frame:SetHeight(78)
    summaryClassIcon = summary.frame:CreateTexture(nil, "ARTWORK")
    summaryClassIcon:SetSize(38, 38)
    summaryClassIcon:SetPoint(
        "LEFT",
        summary.frame,
        "LEFT",
        theme.spacing.md,
        0
    )
    summaryClassIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    summaryClassIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    summaryIcon = summary.frame:CreateTexture(nil, "ARTWORK")
    summaryIcon:SetSize(38, 38)
    summaryIcon:SetPoint(
        "LEFT",
        summaryClassIcon,
        "RIGHT",
        6,
        0
    )
    summaryIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    summaryIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    summaryText = createText(nil, summary.frame, "Choose a class and specialization", "GameFontNormal")
    summaryText:SetPoint(
        "LEFT",
        summaryIcon,
        "RIGHT",
        theme.spacing.md,
        8
    )
    summarySub = createText(
        nil,
        summary.frame,
        "Only legal choices for the selected role are shown.",
        "GameFontHighlightSmall",
        theme.colors.muted
    )
    summarySub:SetPoint(
        "TOPLEFT",
        summaryText,
        "BOTTOMLEFT",
        0,
        -4
    )
    currentRole = "DPS"
    local countEnabled = options.allowCount == true
    local countLabel = createText(
        nil,
        summary.frame,
        "COUNT",
        "GameFontNormalSmall",
        theme.colors.muted
    )
    countLabel:SetPoint(
        "RIGHT",
        summary.frame,
        "RIGHT",
        -204,
        13
    )
    local countStepper = createNumberStepper(
        nil,
        summary.frame,
        1,
        options.maxCount or 40,
        1
    )
    countStepper.frame:SetPoint(
        "RIGHT",
        summary.frame,
        "RIGHT",
        -170,
        -8
    )
    if options.allowCount ~= true then
        countLabel:Hide()
        countStepper.frame:Hide()
    end
    apply = createButton(
        nil,
        summary.frame,
        {
            text = "Apply Build",
            width = 136,
            height = 38,
            accent = theme.colors.primary,
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
        "RIGHT",
        summary.frame,
        "RIGHT",
        -theme.spacing.md,
        0
    )
    classTiles = {}
    specTiles = {}
    local function selectClass(self, classId)
        currentClass = classId
        currentSpec = nil
        refresh(nil)
    end
    local function selectSpec(self, specId)
        currentSpec = specId
        refresh(nil)
    end
    for ____, classDef in ipairs(getClassesForRole("DPS")) do
        local button = createButton(
            nil,
            leftPanel.frame,
            {
                text = classDef.label,
                width = 86,
                height = 82,
                accent = classColor(nil, classDef.id),
                onClick = function() return selectClass(nil, classDef.id) end
            }
        )
        local icon = button.frame:CreateTexture(nil, "ARTWORK")
        icon:SetSize(38, 38)
        icon:SetPoint(
            "TOP",
            button.frame,
            "TOP",
            0,
            -8
        )
        setClassIcon(nil, icon, classDef.id)
        button.label:ClearAllPoints()
        button.label:SetPoint(
            "BOTTOM",
            button.frame,
            "BOTTOM",
            0,
            8
        )
        button.label:SetJustifyH("CENTER")
        classTiles[#classTiles + 1] = {classDef = classDef, button = button}
    end
    for ____, classDef in ipairs(getClassesForRole("DPS")) do
        for ____, spec in ipairs(classDef.specs) do
            local button = createButton(
                nil,
                rightPanel.frame,
                {
                    text = spec.label,
                    width = 104,
                    height = 94,
                    accent = classColor(nil, classDef.id),
                    onClick = function()
                        currentClass = classDef.id
                        selectSpec(nil, spec.id)
                    end
                }
            )
            local icon = createIcon(nil, button.frame, spec.icon, 44)
            icon:SetPoint(
                "TOP",
                button.frame,
                "TOP",
                0,
                -10
            )
            button.label:ClearAllPoints()
            button.label:SetPoint(
                "BOTTOM",
                button.frame,
                "BOTTOM",
                0,
                10
            )
            button.label:SetJustifyH("CENTER")
            button.frame:Hide()
            specTiles[#specTiles + 1] = {classId = classDef.id, spec = spec, button = button}
        end
    end
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
                if not validCurrent then
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
    local refreshRows, refresh, trigger, popup, maxVisible, offset, rows
    function refreshRows(self)
        local items = options:getItems()
        local visible = math.min(maxVisible, #items)
        popup.frame:SetHeight(math.max(12, visible * 32 + 8))
        do
            local i = 0
            while i < maxVisible do
                local row = rows[i + 1]
                if row == nil then
                    row = createButton(nil, popup.frame, {text = "", width = options.width - 8, height = 28})
                    row.frame:SetPoint(
                        "TOPLEFT",
                        popup.frame,
                        "TOPLEFT",
                        4,
                        -(4 + i * 32)
                    )
                    row.label:ClearAllPoints()
                    row.label:SetPoint(
                        "LEFT",
                        row.frame,
                        "LEFT",
                        10,
                        0
                    )
                    row.label:SetPoint(
                        "RIGHT",
                        row.frame,
                        "RIGHT",
                        -8,
                        0
                    )
                    row.label:SetJustifyH("LEFT")
                    rows[i + 1] = row
                end
                local item = items[offset + i + 1]
                if item ~= nil then
                    row:setText(item.label)
                    row:setSelected(item.value == options:getValue())
                    local value = item.value
                    row.frame:SetScript(
                        "OnMouseDown",
                        function()
                            options:onChange(value)
                            closeActive(nil)
                            refresh(nil)
                        end
                    )
                    row.frame:Show()
                else
                    row.frame:Hide()
                end
                i = i + 1
            end
        end
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
    trigger = createButton(nil, parent, {text = "Select", width = options.width, height = 34})
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
        -28,
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
        -10,
        0
    )
    popup = createPanel(nil, trigger.frame, theme.colors.background, theme.colors.borderStrong)
    popup.frame:SetFrameStrata("TOOLTIP")
    popup.frame:SetWidth(options.width)
    popup.frame:EnableMouseWheel(true)
    popup.frame:Hide()
    maxVisible = options.maxVisible or 9
    offset = 0
    rows = {}
    local function open(self)
        closeActive(nil)
        offset = 0
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
    popup.frame:SetScript(
        "OnMouseWheel",
        function(____, _frame, delta)
            local items = options:getItems()
            local maxOffset = math.max(0, #items - maxVisible)
            offset = math.max(
                0,
                math.min(
                    maxOffset,
                    offset - __TS__Number(delta)
                )
            )
            refreshRows(nil)
        end
    )
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
function ____exports.remainingBotSlots(self, role)
    local counts = ____exports.humanRoleCounts(nil)
    return math.max(
        0,
        ____exports.targetForRole(nil, role) - counts[role]
    )
end
local function rawRequired(self, role)
    local result = {}
    local ____opt_10 = ____exports.config(nil).preferences
    if ____opt_10 ~= nil then
        ____opt_10 = ____opt_10[role]
    end
    local ____opt_10_12 = ____opt_10
    if ____opt_10_12 == nil then
        ____opt_10_12 = {}
    end
    local list = ____opt_10_12
    for ____, pref in __TS__Iterator(list) do
        if pref.required == true and pref.class ~= nil and pref.class ~= "ANY" and type(pref.spec) == "number" then
            result[#result + 1] = pref
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
    local ____opt_13 = cfg.preferences
    if ____opt_13 ~= nil then
        ____opt_13 = ____opt_13[role]
    end
    local ____opt_13_15 = ____opt_13
    if ____opt_13_15 == nil then
        ____opt_13_15 = {}
    end
    local existing = ____opt_13_15
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
                next[#next + 1] = {class = row.classId, spec = row.specId, required = true}
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
    local ____exports_config_result_pinned_18 = ____exports.config(nil).pinned
    if ____exports_config_result_pinned_18 == nil then
        ____exports_config_result_pinned_18 = {}
    end
    for ____, pin in ipairs(____exports_config_result_pinned_18) do
        result[#result + 1] = pin
    end
    return result
end
function ____exports.planWarnings(self)
    local result = {}
    local ____exports_plan_result_warnings_19 = ____exports.plan(nil).warnings
    if ____exports_plan_result_warnings_19 == nil then
        ____exports_plan_result_warnings_19 = {}
    end
    for ____, warning in ipairs(____exports_plan_result_warnings_19) do
        result[#result + 1] = tostring(warning)
    end
    return result
end
function ____exports.dungeonItems(self)
    local result = {}
    local ____D_DUNGEONS_20 = D.DUNGEONS
    if ____D_DUNGEONS_20 == nil then
        ____D_DUNGEONS_20 = {}
    end
    for ____, dungeon in __TS__Iterator(____D_DUNGEONS_20) do
        result[#result + 1] = {value = dungeon.id, label = dungeon.label}
    end
    return result
end
function ____exports.difficultyItems(self)
    local result = {}
    local ____D_DUNGEON_DIFFICULTIES_21 = D.DUNGEON_DIFFICULTIES
    if ____D_DUNGEON_DIFFICULTIES_21 == nil then
        ____D_DUNGEON_DIFFICULTIES_21 = {}
    end
    for ____, difficulty in __TS__Iterator(____D_DUNGEON_DIFFICULTIES_21) do
        result[#result + 1] = {value = difficulty.id, label = difficulty.label}
    end
    return result
end
function ____exports.raidItems(self)
    local result = {}
    local ____D_RAIDS_22 = D.RAIDS
    if ____D_RAIDS_22 == nil then
        ____D_RAIDS_22 = {}
    end
    for ____, raid in __TS__Iterator(____D_RAIDS_22) do
        result[#result + 1] = {
            value = raid.id,
            label = (tostring(raid.era) .. "  ·  ") .. tostring(raid.label)
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
    local ____opt_result_25
    if raid ~= nil then
        ____opt_result_25 = raid.heroic
    end
    if ____opt_result_25 == true then
        result[#result + 1] = {value = "heroic", label = "Heroic"}
    end
    return result
end
function ____exports.selectedActivityLabel(self)
    local cfg = ____exports.config(nil)
    if cfg.mode == "RAID" then
        local raid = raidById(nil, cfg.activity)
        local ____opt_result_28
        if raid ~= nil then
            ____opt_result_28 = raid.label
        end
        local ____opt_result_28_29 = ____opt_result_28
        if ____opt_result_28_29 == nil then
            ____opt_result_28_29 = "Raid"
        end
        return ____opt_result_28_29
    end
    local dungeon = dungeonById(nil, cfg.activity)
    local ____opt_result_32
    if dungeon ~= nil then
        ____opt_result_32 = dungeon.label
    end
    local ____opt_result_32_33 = ____opt_result_32
    if ____opt_result_32_33 == nil then
        ____opt_result_32_33 = "Dungeon"
    end
    return ____opt_result_32_33
end
function ____exports.supportedRaidSizes(self)
    local raid = raidById(
        nil,
        ____exports.config(nil).activity
    )
    local result = {}
    local ____opt_result_36
    if raid ~= nil then
        ____opt_result_36 = raid.sizes
    end
    local ____opt_result_36_37 = ____opt_result_36
    if ____opt_result_36_37 == nil then
        ____opt_result_36_37 = {}
    end
    for ____, size in __TS__Iterator(____opt_result_36_37) do
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
function ____exports.addPin(self, name, role, required)
    GC:AddPinnedMember(name, role, required)
end
function ____exports.removePin(self, index)
    GC:RemovePinnedMember(index)
end
function ____exports.planMembers(self)
    local ____exports_plan_result_members_38 = ____exports.plan(nil).members
    if ____exports_plan_result_members_38 == nil then
        ____exports_plan_result_members_38 = {}
    end
    return ____exports_plan_result_members_38
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
    local ____exports_progress_result_phase_39 = ____exports.progress(nil).phase
    if ____exports_progress_result_phase_39 == nil then
        ____exports_progress_result_phase_39 = "IDLE"
    end
    local phase = tostring(____exports_progress_result_phase_39)
    return phase == "BUILDING" or phase == "PREPARING" or phase == "ASSEMBLING" or phase == "TRAVEL"
end
function ____exports.isTravelRetry(self)
    local p = ____exports.progress(nil)
    local ____temp_41 = p.phase == "READY"
    if ____temp_41 then
        local ____p_detail_40 = p.detail
        if ____p_detail_40 == nil then
            ____p_detail_40 = ""
        end
        ____temp_41 = (string.find(
            tostring(____p_detail_40),
            "Enter Activity",
            nil,
            true
        ) or 0) - 1 >= 0
    end
    return ____temp_41
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
function ____exports.createScrollList(self, parent, width, height)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:SetSize(width, height)
    scroll:EnableMouseWheel(true)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(width)
    content:SetHeight(height)
    scroll:SetScrollChild(content)
    scroll:SetScript(
        "OnMouseWheel",
        function(____, _frame, delta)
            local next = scroll:GetVerticalScroll() - __TS__Number(delta) * 38
            scroll:SetVerticalScroll(math.max(
                0,
                math.min(
                    scroll:GetVerticalScrollRange(),
                    next
                )
            ))
        end
    )
    return {
        frame = scroll,
        content = content,
        setContentHeight = function(self, value)
            content:SetHeight(math.max(height, value))
            scroll:SetVerticalScroll(math.min(
                scroll:GetVerticalScroll(),
                scroll:GetVerticalScrollRange()
            ))
        end,
        reset = function(self)
            scroll:SetVerticalScroll(0)
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
    local clearDynamicRows, refreshTemplates, refreshPeople, roleOrder, templatesModal, builtinScroll, customScroll, builtinRows, customRows, humanScroll, humanRowsModal, pinRole, pinRoleButtons, pinToggle, pinScroll, pinRows
    function clearDynamicRows(self, rows)
        for ____, row in ipairs(rows) do
            row:Hide()
        end
    end
    function refreshTemplates(self)
        clearDynamicRows(nil, builtinRows)
        clearDynamicRows(nil, customRows)
        local builtins = Model:listBuiltinProfiles()
        do
            local i = 0
            while i < #builtins do
                local row = builtinRows[i + 1]
                if row == nil then
                    local panel = Native:createPanel(builtinScroll.content, theme.colors.background, theme.colors.border)
                    panel.frame:SetSize(382, 40)
                    local name = Native:createText(panel.frame, "", "GameFontHighlightSmall")
                    name:SetPoint(
                        "LEFT",
                        panel.frame,
                        "LEFT",
                        10,
                        0
                    )
                    name:SetWidth(235)
                    local load = ButtonUI:createButton(panel.frame, {text = "Load", width = 82, height = 28, accent = theme.colors.primary})
                    load.frame:SetPoint(
                        "RIGHT",
                        panel.frame,
                        "RIGHT",
                        -6,
                        0
                    )
                    panel.frame._name = name
                    panel.frame._load = load
                    row = panel.frame
                    builtinRows[i + 1] = row
                end
                row:ClearAllPoints()
                row:SetPoint(
                    "TOPLEFT",
                    builtinScroll.content,
                    "TOPLEFT",
                    0,
                    -(i * 46)
                )
                row._name:SetText(builtins[i + 1])
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
        builtinScroll:setContentHeight(math.max(410, #builtins * 46))
        local customs = Model:listCustomProfiles()
        do
            local i = 0
            while i < #customs do
                local row = customRows[i + 1]
                if row == nil then
                    local panel = Native:createPanel(customScroll.content, theme.colors.background, theme.colors.border)
                    panel.frame:SetSize(382, 40)
                    local name = Native:createText(panel.frame, "", "GameFontHighlightSmall")
                    name:SetPoint(
                        "LEFT",
                        panel.frame,
                        "LEFT",
                        10,
                        0
                    )
                    name:SetWidth(190)
                    local load = ButtonUI:createButton(panel.frame, {text = "Load", width = 68, height = 28, accent = theme.colors.primary})
                    load.frame:SetPoint(
                        "RIGHT",
                        panel.frame,
                        "RIGHT",
                        -74,
                        0
                    )
                    local remove = ButtonUI:createButton(panel.frame, {text = "Delete", width = 62, height = 28, accent = theme.colors.error})
                    remove.frame:SetPoint(
                        "RIGHT",
                        panel.frame,
                        "RIGHT",
                        -6,
                        0
                    )
                    panel.frame._name = name
                    panel.frame._load = load
                    panel.frame._remove = remove
                    row = panel.frame
                    customRows[i + 1] = row
                end
                row:ClearAllPoints()
                row:SetPoint(
                    "TOPLEFT",
                    customScroll.content,
                    "TOPLEFT",
                    0,
                    -(i * 46)
                )
                row._name:SetText(customs[i + 1])
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
        customScroll:setContentHeight(math.max(410, #customs * 46))
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
                    local panel = Native:createPanel(humanScroll.content, theme.colors.background, theme.colors.border)
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
                local ____opt_11 = Model:config().humanRoles
                if ____opt_11 ~= nil then
                    ____opt_11 = ____opt_11[human.name]
                end
                local selected = ____opt_11
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
                    local panel = Native:createPanel(pinScroll.content, theme.colors.background, theme.colors.border)
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
    frame:SetSize(1480, 880)
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
    header.frame:SetHeight(68)
    local mark = Native:createPanel(header.frame, theme.colors.surfaceRaised, theme.colors.primary)
    mark.frame:SetSize(40, 40)
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
        72,
        -14
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
        -250,
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
        -18,
        0
    )
    local sidebar = Native:createPanel(frame, theme.colors.surface, theme.colors.border)
    sidebar.frame:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        1,
        -69
    )
    sidebar.frame:SetPoint(
        "BOTTOMLEFT",
        frame,
        "BOTTOMLEFT",
        1,
        36
    )
    sidebar.frame:SetWidth(176)
    local navTitle = Native:createText(sidebar.frame, "PLAN", "GameFontNormalSmall", theme.colors.muted)
    navTitle:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        16,
        -20
    )
    local navDungeon = ButtonUI:createButton(
        sidebar.frame,
        {
            text = "Dungeon",
            width = 144,
            height = 42,
            accent = theme.colors.primary,
            onClick = function() return Model:setMode("DUNGEON") end
        }
    )
    navDungeon.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        16,
        -48
    )
    local navRaid = ButtonUI:createButton(
        sidebar.frame,
        {
            text = "Raid",
            width = 144,
            height = 42,
            accent = theme.colors.warning,
            onClick = function() return Model:setMode("RAID") end
        }
    )
    navRaid.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        16,
        -98
    )
    local manageTitle = Native:createText(sidebar.frame, "MANAGE", "GameFontNormalSmall", theme.colors.muted)
    manageTitle:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        16,
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
            width = 144,
            height = 38,
            onClick = function() return showTemplates(nil) end
        }
    )
    navTemplates.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        16,
        -190
    )
    local navPeople = ButtonUI:createButton(
        sidebar.frame,
        {
            text = "Humans & Pins",
            width = 144,
            height = 38,
            onClick = function() return showPeople(nil) end
        }
    )
    navPeople.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        16,
        -234
    )
    local navOptions = ButtonUI:createButton(
        sidebar.frame,
        {
            text = "Options",
            width = 144,
            height = 38,
            onClick = function() return showOptions(nil) end
        }
    )
    navOptions.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        16,
        -278
    )
    local sideHint = Native:createText(sidebar.frame, "Humans stay locked.\nExact builds only affect bot slots.", "GameFontHighlightSmall", theme.colors.muted)
    sideHint:SetPoint(
        "BOTTOMLEFT",
        sidebar.frame,
        "BOTTOMLEFT",
        16,
        18
    )
    sideHint:SetWidth(144)
    sideHint:SetJustifyV("TOP")
    local center = CreateFrame("Frame", nil, frame)
    center:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        194,
        -84
    )
    center:SetSize(928, 744)
    local status = Native:createPanel(frame, theme.colors.surface, theme.colors.borderStrong)
    status.frame:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        1138,
        -84
    )
    status.frame:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        -16,
        52
    )
    local footer = Native:createPanel(frame, theme.colors.surface, theme.colors.border)
    footer.frame:SetPoint(
        "BOTTOMLEFT",
        frame,
        "BOTTOMLEFT",
        194,
        12
    )
    footer.frame:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        -16,
        12
    )
    footer.frame:SetHeight(28)
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
    activity.frame:SetHeight(96)
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
        -5
    )
    local activitySub = Native:createText(activity.frame, "", "GameFontHighlightSmall", theme.colors.muted)
    activitySub:SetPoint(
        "TOPLEFT",
        activityName,
        "BOTTOMLEFT",
        0,
        -4
    )
    local activitySelect = ChoiceUI:createChoiceSelect(
        activity.frame,
        {
            width = 310,
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
        380,
        -18
    )
    local difficultySelect = ChoiceUI:createChoiceSelect(
        activity.frame,
        {
            width = 180,
            maxVisible = 7,
            getItems = function() return Model:config().mode == "RAID" and Model:raidDifficultyItems() or Model:difficultyItems() end,
            getValue = function() return Model:config().difficulty end,
            onChange = function(____, value) return Model:setDifficulty(tostring(value)) end
        }
    )
    difficultySelect.frame:SetPoint(
        "LEFT",
        activitySelect.frame,
        "RIGHT",
        10,
        0
    )
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
        -108
    )
    humanPanel.frame:SetPoint(
        "TOPRIGHT",
        center,
        "TOPRIGHT",
        0,
        -108
    )
    humanPanel.frame:SetHeight(104)
    local humanTitle = Native:createText(humanPanel.frame, "YOUR PARTY", "GameFontNormalSmall", theme.colors.muted)
    humanTitle:SetPoint(
        "TOPLEFT",
        humanPanel.frame,
        "TOPLEFT",
        16,
        -12
    )
    local humanIcon = humanPanel.frame:CreateTexture(nil, "ARTWORK")
    humanIcon:SetSize(38, 38)
    humanIcon:SetPoint(
        "BOTTOMLEFT",
        humanPanel.frame,
        "BOTTOMLEFT",
        16,
        12
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
    local humanSub = Native:createText(humanPanel.frame, "Real players are locked anchors.", "GameFontHighlightSmall", theme.colors.muted)
    humanSub:SetPoint(
        "TOPLEFT",
        humanName,
        "BOTTOMLEFT",
        0,
        -5
    )
    local humanRoleButtons = {
        TANK = ButtonUI:createButton(humanPanel.frame, {text = "Tank", width = 96, height = 36, accent = theme.colors.tank}),
        HEALER = ButtonUI:createButton(humanPanel.frame, {text = "Healer", width = 96, height = 36, accent = theme.colors.healer}),
        DPS = ButtonUI:createButton(humanPanel.frame, {text = "DPS", width = 96, height = 36, accent = theme.colors.dps})
    }
    humanRoleButtons.TANK.frame:SetPoint(
        "RIGHT",
        humanPanel.frame,
        "RIGHT",
        -224,
        -12
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
    local composition = Native:createPanel(center, theme.colors.surface, theme.colors.border)
    composition.frame:SetPoint(
        "TOPLEFT",
        center,
        "TOPLEFT",
        0,
        -224
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
        16,
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
        14,
        -58
    )
    dungeonView:SetPoint(
        "BOTTOMRIGHT",
        composition.frame,
        "BOTTOMRIGHT",
        -14,
        14
    )
    local dungeonRows = {}
    do
        local i = 0
        while i < 5 do
            local row = Native:createPanel(dungeonView, theme.colors.background, theme.colors.border)
            row.frame:SetHeight(78)
            row.frame:SetPoint(
                "TOPLEFT",
                dungeonView,
                "TOPLEFT",
                0,
                -(i * 84)
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
            classIcon:SetSize(38, 38)
            classIcon:SetPoint(
                "LEFT",
                row.frame,
                "LEFT",
                178,
                0
            )
            classIcon:Hide()
            local specIcon = row.frame:CreateTexture(nil, "ARTWORK")
            specIcon:SetSize(30, 30)
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
                264,
                -20
            )
            name:SetWidth(270)
            local sub = Native:createText(row.frame, "Composer chooses a suitable build", "GameFontHighlightSmall", theme.colors.muted)
            sub:SetPoint(
                "TOPLEFT",
                name,
                "BOTTOMLEFT",
                0,
                -4
            )
            sub:SetWidth(330)
            local choose = ButtonUI:createButton(row.frame, {text = "Choose build", width = 130, height = 34, accent = theme.colors.primary})
            choose.frame:SetPoint(
                "RIGHT",
                row.frame,
                "RIGHT",
                -84,
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
        14,
        -52
    )
    raidView:SetPoint(
        "BOTTOMRIGHT",
        composition.frame,
        "BOTTOMRIGHT",
        -14,
        14
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
    local tabExact = ButtonUI:createButton(raidView, {text = "Exact Builds", width = 140, height = 32, accent = theme.colors.warning})
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
            local card = Native:createPanel(
                quickView,
                theme.colors.background,
                Model:roleAccent(role)
            )
            card.frame:SetSize(282, 178)
            card.frame:SetPoint(
                "TOPLEFT",
                quickView,
                "TOPLEFT",
                i * 294,
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
                -70
            )
            local botSlots = Native:createText(card.frame, "0 bot slots after humans", "GameFontHighlightSmall", theme.colors.muted)
            botSlots:SetPoint(
                "TOPLEFT",
                count,
                "BOTTOMLEFT",
                0,
                -7
            )
            local minus
            local plus
            if role ~= "DPS" then
                minus = ButtonUI:createButton(card.frame, {text = "-", width = 38, height = 32})
                plus = ButtonUI:createButton(
                    card.frame,
                    {
                        text = "+",
                        width = 38,
                        height = 32,
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
            else
                local derived = Native:createText(card.frame, "Auto remainder", "GameFontHighlightSmall", theme.colors.muted)
                derived:SetPoint(
                    "BOTTOMRIGHT",
                    card.frame,
                    "BOTTOMRIGHT",
                    -14,
                    20
                )
            end
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
    local function adjustRole(self, role, delta)
        if role == "DPS" then
            return
        end
        local cfg = Model:config()
        local key = role == "TANK" and "tanks" or "healers"
        local ____cfg_key_9 = cfg[key]
        if ____cfg_key_9 == nil then
            ____cfg_key_9 = 0
        end
        local next = math.max(
            0,
            __TS__Number(____cfg_key_9) + delta
        )
        local ____cfg_dps_10 = cfg.dps
        if ____cfg_dps_10 == nil then
            ____cfg_dps_10 = 0
        end
        local nextDps = __TS__Number(____cfg_dps_10) - delta
        if nextDps < 0 then
            return
        end
        cfg[key] = next
        cfg.dps = nextDps
        Model:touch("Role composition changed")
    end
    quickCards.TANK.minus.frame:SetScript(
        "OnMouseDown",
        function() return adjustRole(nil, "TANK", -1) end
    )
    quickCards.TANK.plus.frame:SetScript(
        "OnMouseDown",
        function() return adjustRole(nil, "TANK", 1) end
    )
    quickCards.HEALER.minus.frame:SetScript(
        "OnMouseDown",
        function() return adjustRole(nil, "HEALER", -1) end
    )
    quickCards.HEALER.plus.frame:SetScript(
        "OnMouseDown",
        function() return adjustRole(nil, "HEALER", 1) end
    )
    local exactColumns = {}
    do
        local i = 0
        while i < #roleOrder do
            local role = roleOrder[i + 1]
            local panel = Native:createPanel(
                exactView,
                theme.colors.background,
                Model:roleAccent(role)
            )
            panel.frame:SetPoint(
                "TOPLEFT",
                exactView,
                "TOPLEFT",
                i * 294,
                -8
            )
            panel.frame:SetSize(282, 410)
            local icon = Native:createIcon(panel.frame, D.ROLE_ICON[role], 28)
            icon:SetPoint(
                "TOPLEFT",
                panel.frame,
                "TOPLEFT",
                12,
                -12
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
                9,
                5
            )
            local count = Native:createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted)
            count:SetPoint(
                "LEFT",
                icon,
                "RIGHT",
                9,
                -12
            )
            local add = ButtonUI:createButton(
                panel.frame,
                {
                    text = "+ Add build",
                    width = 112,
                    height = 30,
                    accent = Model:roleAccent(role)
                }
            )
            add.frame:SetPoint(
                "TOPRIGHT",
                panel.frame,
                "TOPRIGHT",
                -10,
                -11
            )
            local scroll = ScrollUI:createScrollList(panel.frame, 258, 330)
            scroll.frame:SetPoint(
                "TOPLEFT",
                panel.frame,
                "TOPLEFT",
                12,
                -66
            )
            exactColumns[role] = {
                panel = panel,
                count = count,
                add = add,
                scroll = scroll,
                rows = {}
            }
            i = i + 1
        end
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
                    row:SetHeight(32)
                    row:SetPoint(
                        "TOPLEFT",
                        card.frame,
                        "TOPLEFT",
                        8,
                        -(36 + r * 35)
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
                    name:SetWidth(112)
                    local spec = Native:createText(row, "", "GameFontHighlightSmall", theme.colors.muted)
                    spec:SetPoint(
                        "LEFT",
                        row,
                        "LEFT",
                        38,
                        -8
                    )
                    spec:SetWidth(125)
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
    local statusTitle = Native:createText(status.frame, "COMPOSITION & STATUS", "GameFontNormal")
    statusTitle:SetPoint(
        "TOPLEFT",
        status.frame,
        "TOPLEFT",
        16,
        -16
    )
    local phaseDot = Native:createSolid(status.frame, theme.colors.primary, "ARTWORK")
    phaseDot:SetSize(10, 10)
    phaseDot:SetPoint(
        "TOPLEFT",
        status.frame,
        "TOPLEFT",
        18,
        -54
    )
    local phaseText = Native:createText(status.frame, "Configure roster", "GameFontNormalLarge")
    phaseText:SetPoint(
        "LEFT",
        phaseDot,
        "RIGHT",
        10,
        4
    )
    local phaseDetail = Native:createText(status.frame, "", "GameFontHighlightSmall", theme.colors.muted)
    phaseDetail:SetPoint(
        "TOPLEFT",
        phaseText,
        "BOTTOMLEFT",
        0,
        -4
    )
    phaseDetail:SetWidth(266)
    phaseDetail:SetJustifyV("TOP")
    local rosterCount = Native:createText(status.frame, "1 / 5", "GameFontNormalHuge")
    rosterCount:SetPoint(
        "TOPLEFT",
        status.frame,
        "TOPLEFT",
        16,
        -116
    )
    local sourceText = Native:createText(status.frame, "1 human  ·  4 bot slots", "GameFontHighlightSmall", theme.colors.muted)
    sourceText:SetPoint(
        "TOPLEFT",
        rosterCount,
        "BOTTOMLEFT",
        0,
        -6
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
            chip.frame:SetSize(88, 32)
            chip.frame:SetPoint(
                "TOPLEFT",
                status.frame,
                "TOPLEFT",
                16 + i * 96,
                -174
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
        -222
    )
    progressBg.frame:SetSize(286, 12)
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
        -244
    )
    progressText:SetWidth(286)
    local coverageTitle = Native:createText(status.frame, "COVERAGE", "GameFontNormalSmall", theme.colors.muted)
    coverageTitle:SetPoint(
        "TOPLEFT",
        status.frame,
        "TOPLEFT",
        16,
        -286
    )
    local coverageText = Native:createText(status.frame, "Build a roster to inspect coverage.", "GameFontHighlightSmall", theme.colors.muted)
    coverageText:SetPoint(
        "TOPLEFT",
        status.frame,
        "TOPLEFT",
        16,
        -308
    )
    coverageText:SetWidth(286)
    coverageText:SetJustifyV("TOP")
    local classIcons = {}
    do
        local i = 0
        while i < 10 do
            local icon = status.frame:CreateTexture(nil, "ARTWORK")
            icon:SetSize(20, 20)
            icon:SetPoint(
                "TOPLEFT",
                status.frame,
                "TOPLEFT",
                16 + i * 25,
                -356
            )
            icon:Hide()
            classIcons[#classIcons + 1] = icon
            i = i + 1
        end
    end
    local warningsTitle = Native:createText(status.frame, "NEXT STEP", "GameFontNormalSmall", theme.colors.warning)
    warningsTitle:SetPoint(
        "TOPLEFT",
        status.frame,
        "TOPLEFT",
        16,
        -396
    )
    local warningRows = {}
    do
        local i = 0
        while i < 3 do
            local row = Native:createText(status.frame, "", "GameFontHighlightSmall", i == 0 and theme.colors.warning or theme.colors.muted)
            row:SetPoint(
                "TOPLEFT",
                status.frame,
                "TOPLEFT",
                16,
                -(420 + i * 42)
            )
            row:SetWidth(286)
            row:SetJustifyV("TOP")
            warningRows[#warningRows + 1] = row
            i = i + 1
        end
    end
    local buildButton = ButtonUI:createButton(
        status.frame,
        {
            text = "Build & Prepare",
            width = 286,
            height = 40,
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
            width = 210,
            height = 38,
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
            height = 38,
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
    templatesModal = ModalUI:createModal(frame, 880, 620)
    templatesModal:setTitle("Templates")
    templatesModal:setSubtitle("Built-in starting points and your saved compositions.")
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
    local templateSave = ButtonUI:createButton(
        templatesModal.content,
        {
            text = "Save Current",
            width = 120,
            height = 34,
            accent = theme.colors.primary,
            onClick = function()
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
    local builtinTitle = Native:createText(templatesModal.content, "BUILT-IN", "GameFontNormalSmall", theme.colors.muted)
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
        420,
        -82
    )
    builtinScroll = ScrollUI:createScrollList(templatesModal.content, 390, 410)
    builtinScroll.frame:SetPoint(
        "TOPLEFT",
        templatesModal.content,
        "TOPLEFT",
        0,
        -108
    )
    customScroll = ScrollUI:createScrollList(templatesModal.content, 390, 410)
    customScroll.frame:SetPoint(
        "TOPLEFT",
        templatesModal.content,
        "TOPLEFT",
        420,
        -108
    )
    builtinRows = {}
    customRows = {}
    showTemplates = function()
        ChoiceUI:closeChoicePopup()
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
    local optionsModal = ModalUI:createModal(frame, 700, 560)
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
            local row = Native:createPanel(optionsModal.content, theme.colors.background, theme.colors.border)
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
                    local ____opt_13 = Model:config().options
                    if ____opt_13 ~= nil then
                        ____opt_13 = ____opt_13[def.key]
                    end
                    return ____opt_13 == true
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
    showOptions = function()
        ChoiceUI:closeChoicePopup()
        for ____, toggle in ipairs(optionToggles) do
            toggle:refresh()
        end
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
        activitySelect:refresh()
        difficultySelect:refresh()
        local sizes = Model:supportedRaidSizes()
        local sizeIndex = 0
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
                    380 + sizeIndex * 58,
                    -58
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
        local ____opt_15 = Model:config().humanRoles
        if ____opt_15 ~= nil then
            ____opt_15 = ____opt_15[primary.name]
        end
        local selected = ____opt_15
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
                    local __continue158
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
                            __continue158 = true
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
                            local ____self_19 = widgets.sub
                            local ____self_19_SetText_20 = ____self_19.SetText
                            local ____temp_18 = tostring(prepared.spec or Model:classLabel(tostring(prepared.class))) .. "  ·  "
                            local ____prepared_source_17 = prepared.source
                            if ____prepared_source_17 == nil then
                                ____prepared_source_17 = "Bot"
                            end
                            ____self_19_SetText_20(
                                ____self_19,
                                ____temp_18 .. tostring(____prepared_source_17)
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
                                local ____buildSelector_open_22 = buildSelector.open
                                local ____temp_21
                                if exact == nil then
                                    ____temp_21 = nil
                                else
                                    ____temp_21 = {role = roleCopy, classId = exact.classId, specId = exact.specId, count = 1}
                                end
                                ____buildSelector_open_22(buildSelector, roleCopy, ____temp_21, false)
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
                        __continue158 = true
                    until true
                    if not __continue158 then
                        break
                    end
                end
                i = i + 1
            end
        end
    end
    local function refreshQuickRaid(self)
        for ____, role in ipairs(roleOrder) do
            quickCards[role].count:SetText(tostring(Model:targetForRole(role)))
            quickCards[role].botSlots:SetText(tostring(Model:remainingBotSlots(role)) .. " bot slots after humans")
        end
    end
    local function refreshExactRaid(self)
        for ____, role in ipairs(roleOrder) do
            local column = exactColumns[role]
            local rows = Model:requiredBuilds(role)
            column.count:SetText(((tostring(Model:exactCount(role)) .. " exact  ·  ") .. tostring(math.max(
                0,
                Model:remainingBotSlots(role) - Model:exactCount(role)
            ))) .. " Auto")
            column.add:setEnabled(Model:exactCount(role) < Model:remainingBotSlots(role))
            local roleCopy = role
            column.add.frame:SetScript(
                "OnMouseDown",
                function()
                    if Model:exactCount(roleCopy) >= Model:remainingBotSlots(roleCopy) then
                        return
                    end
                    selectorContext = {mode = "RAID_ADD", role = roleCopy, index = -1}
                    buildSelector:open(roleCopy, {role = roleCopy, count = 1}, true)
                end
            )
            for ____, old in __TS__Iterator(column.rows) do
                old.frame:Hide()
            end
            do
                local i = 0
                while i < #rows do
                    local build = rows[i + 1]
                    local widgets = column.rows[i + 1]
                    if widgets == nil then
                        local panel = Native:createPanel(column.scroll.content, theme.colors.surfaceRaised, theme.colors.border)
                        panel.frame:SetSize(250, 52)
                        local classIcon = panel.frame:CreateTexture(nil, "ARTWORK")
                        classIcon:SetSize(30, 30)
                        classIcon:SetPoint(
                            "LEFT",
                            panel.frame,
                            "LEFT",
                            8,
                            0
                        )
                        local specIcon = panel.frame:CreateTexture(nil, "ARTWORK")
                        specIcon:SetSize(24, 24)
                        specIcon:SetPoint(
                            "LEFT",
                            classIcon,
                            "RIGHT",
                            6,
                            0
                        )
                        local name = Native:createText(panel.frame, "", "GameFontHighlightSmall")
                        name:SetPoint(
                            "LEFT",
                            panel.frame,
                            "LEFT",
                            76,
                            7
                        )
                        name:SetWidth(112)
                        local count = Native:createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted)
                        count:SetPoint(
                            "LEFT",
                            panel.frame,
                            "LEFT",
                            76,
                            -10
                        )
                        local edit = ButtonUI:createButton(panel.frame, {text = "Edit", width = 46, height = 26, accent = theme.colors.primary})
                        edit.frame:SetPoint(
                            "RIGHT",
                            panel.frame,
                            "RIGHT",
                            -54,
                            0
                        )
                        local remove = ButtonUI:createButton(panel.frame, {text = "X", width = 40, height = 26, accent = theme.colors.error})
                        remove.frame:SetPoint(
                            "RIGHT",
                            panel.frame,
                            "RIGHT",
                            -8,
                            0
                        )
                        widgets = {
                            panel = panel,
                            classIcon = classIcon,
                            specIcon = specIcon,
                            name = name,
                            count = count,
                            edit = edit,
                            remove = remove
                        }
                        column.rows[i + 1] = widgets
                    end
                    widgets.panel.frame:ClearAllPoints()
                    widgets.panel.frame:SetPoint(
                        "TOPLEFT",
                        column.scroll.content,
                        "TOPLEFT",
                        0,
                        -(i * 58)
                    )
                    Native:setClassIcon(widgets.classIcon, build.classId)
                    widgets.specIcon:SetTexture(Model:getSpecIcon(build.classId, build.specId))
                    widgets.specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    widgets.name:SetText((Model:getSpecLabel(build.classId, build.specId) .. " ") .. Model:classLabel(build.classId))
                    widgets.count:SetText("×" .. tostring(build.count))
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
            column.scroll:setContentHeight(math.max(330, #rows * 58))
        end
    end
    local function refreshRoster(self)
        local cfg = Model:config()
        local ____cfg_size_23 = cfg.size
        if ____cfg_size_23 == nil then
            ____cfg_size_23 = 5
        end
        local totalGroups = math.max(
            1,
            math.ceil(__TS__Number(____cfg_size_23) / 5)
        )
        local wideFive = totalGroups == 5
        local columns = wideFive and 5 or (totalGroups >= 8 and 4 or math.min(4, totalGroups))
        local cardWidth = wideFive and 168 or math.floor((880 - (columns - 1) * 10) / columns)
        local cardHeight = totalGroups >= 8 and 202 or 220
        do
            local g = 0
            while g < #groupCards do
                do
                    local __continue185
                    repeat
                        local widgets = groupCards[g + 1]
                        if g >= totalGroups then
                            widgets.card.frame:Hide()
                            __continue185 = true
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
                                    local ____self_25 = rowWidgets.spec
                                    local ____self_25_SetText_26 = ____self_25.SetText
                                    local ____member_spec_24 = member.spec
                                    if ____member_spec_24 == nil then
                                        ____member_spec_24 = Model:classLabel(tostring(member.class))
                                    end
                                    ____self_25_SetText_26(
                                        ____self_25,
                                        tostring(____member_spec_24)
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
                        __continue185 = true
                    until true
                    if not __continue185 then
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
        local ____p_phase_27 = p.phase
        if ____p_phase_27 == nil then
            ____p_phase_27 = "IDLE"
        end
        local phase = tostring(____p_phase_27)
        local phaseColor = colorForPhase(nil, phase)
        Native:setTextureColor(phaseDot, phaseColor)
        phaseText:SetText(Model:isTravelRetry() and "Ready to enter activity" or Model:phaseLabel(phase))
        phaseText:SetTextColor(phaseColor[1], phaseColor[2], phaseColor[3], 1)
        local ____phaseDetail_SetText_29 = phaseDetail.SetText
        local ____p_detail_28 = p.detail
        if ____p_detail_28 == nil then
            ____p_detail_28 = ""
        end
        ____phaseDetail_SetText_29(
            phaseDetail,
            tostring(____p_detail_28)
        )
        local humanCount = #Model:humans()
        local ____table_size_30 = Model:config().size
        if ____table_size_30 == nil then
            ____table_size_30 = 5
        end
        local target = __TS__Number(____table_size_30)
        local ____temp_34
        if Model:plan().ready == true then
            local ____opt_31 = Model:plan().summary
            if ____opt_31 ~= nil then
                ____opt_31 = ____opt_31.total
            end
            local ____opt_31_33 = ____opt_31
            if ____opt_31_33 == nil then
                ____opt_31_33 = #Model:planMembers()
            end
            ____temp_34 = __TS__Number(____opt_31_33)
        else
            ____temp_34 = humanCount
        end
        local total = ____temp_34
        rosterCount:SetText((tostring(total) .. " / ") .. tostring(target))
        if Model:plan().ready == true then
            local ____sourceText_SetText_43 = sourceText.SetText
            local ____temp_38 = ((tostring(humanCount) .. " human") .. (humanCount == 1 and "" or "s")) .. "  ·  "
            local ____opt_35 = Model:plan().summary
            if ____opt_35 ~= nil then
                ____opt_35 = ____opt_35.guild
            end
            local ____opt_35_37 = ____opt_35
            if ____opt_35_37 == nil then
                ____opt_35_37 = 0
            end
            local ____temp_42 = (____temp_38 .. tostring(____opt_35_37)) .. " guild  ·  "
            local ____opt_39 = Model:plan().summary
            if ____opt_39 ~= nil then
                ____opt_39 = ____opt_39.world
            end
            local ____opt_39_41 = ____opt_39
            if ____opt_39_41 == nil then
                ____opt_39_41 = 0
            end
            ____sourceText_SetText_43(
                sourceText,
                (____temp_42 .. tostring(____opt_39_41)) .. " fallback"
            )
        else
            sourceText:SetText(((((tostring(humanCount) .. " human") .. (humanCount == 1 and "" or "s")) .. "  ·  ") .. tostring(math.max(0, target - humanCount))) .. " bot slots")
        end
        local ____self_45 = statusRoleChips.TANK.label
        local ____self_45_SetText_46 = ____self_45.SetText
        local ____table_tanks_44 = Model:config().tanks
        if ____table_tanks_44 == nil then
            ____table_tanks_44 = 0
        end
        ____self_45_SetText_46(
            ____self_45,
            tostring(____table_tanks_44) .. " T"
        )
        local ____self_48 = statusRoleChips.HEALER.label
        local ____self_48_SetText_49 = ____self_48.SetText
        local ____table_healers_47 = Model:config().healers
        if ____table_healers_47 == nil then
            ____table_healers_47 = 0
        end
        ____self_48_SetText_49(
            ____self_48,
            tostring(____table_healers_47) .. " H"
        )
        local ____self_51 = statusRoleChips.DPS.label
        local ____self_51_SetText_52 = ____self_51.SetText
        local ____table_dps_50 = Model:config().dps
        if ____table_dps_50 == nil then
            ____table_dps_50 = 0
        end
        ____self_51_SetText_52(
            ____self_51,
            tostring(____table_dps_50) .. " D"
        )
        local ratio = 0
        local ____p_total_53 = p.total
        if ____p_total_53 == nil then
            ____p_total_53 = 0
        end
        if __TS__Number(____p_total_53) > 0 then
            local ____p_current_54 = p.current
            if ____p_current_54 == nil then
                ____p_current_54 = 0
            end
            ratio = math.min(
                1,
                __TS__Number(____p_current_54) / __TS__Number(p.total)
            )
        elseif phase == "READY" or phase == "DONE" then
            ratio = 1
        end
        progressFill:SetWidth(math.max(1, 282 * ratio))
        Native:setTextureColor(progressFill, phaseColor)
        local ____progressText_SetText_61 = progressText.SetText
        local ____temp_60
        if phase == "PREPARING" or phase == "ASSEMBLING" or phase == "READY" or phase == "DONE" then
            local ____p_current_55 = p.current
            if ____p_current_55 == nil then
                ____p_current_55 = 0
            end
            local ____temp_57 = tostring(____p_current_55) .. " / "
            local ____p_total_56 = p.total
            if ____p_total_56 == nil then
                ____p_total_56 = 0
            end
            local ____temp_59 = (____temp_57 .. tostring(____p_total_56)) .. "  ·  "
            local ____p_detail_58 = p.detail
            if ____p_detail_58 == nil then
                ____p_detail_58 = ""
            end
            ____temp_60 = ____temp_59 .. tostring(____p_detail_58)
        else
            ____temp_60 = ""
        end
        ____progressText_SetText_61(progressText, ____temp_60)
        local ____coverageText_SetText_69 = coverageText.SetText
        local ____temp_68
        local ____opt_62 = Model:plan().summary
        if ____opt_62 ~= nil then
            ____opt_62 = ____opt_62.utility
        end
        if ____opt_62 ~= nil then
            local ____temp_65 = tostring(Model:plan().summary.utility) .. "\nRanged DPS: "
            local ____table_summary_ranged_64 = Model:plan().summary.ranged
            if ____table_summary_ranged_64 == nil then
                ____table_summary_ranged_64 = 0
            end
            local ____temp_67 = (____temp_65 .. tostring(____table_summary_ranged_64)) .. "   Melee DPS: "
            local ____table_summary_melee_66 = Model:plan().summary.melee
            if ____table_summary_melee_66 == nil then
                ____table_summary_melee_66 = 0
            end
            ____temp_68 = ____temp_67 .. tostring(____table_summary_melee_66)
        else
            ____temp_68 = "Build a roster to inspect utility coverage."
        end
        ____coverageText_SetText_69(coverageText, ____temp_68)
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
                local text = warnings[i + 1]
                if text == nil and i == 0 then
                    if phase == "READY" then
                        text = Model:isTravelRetry() and "Clear the travel blocker, then enter the activity." or "Prepared roster is ready for review."
                    elseif phase == "PREPARING" then
                        text = "Bots are being prepared in the background."
                    elseif not Model:humanReady() then
                        text = "Choose a legal role for every real player."
                    else
                        text = "Build & Prepare when the composition looks right."
                    end
                end
                warningRows[i + 1]:SetText(tostring(text or ""))
                i = i + 1
            end
        end
        buildButton:setEnabled(Model:humanReady() and not Model:isBusy())
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
        local scale = math.min((width - 24) / 1480, (height - 24) / 880)
        frame:SetScale(math.max(
            0.68,
            math.min(1.1, scale)
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
    version = "0.2.1",
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

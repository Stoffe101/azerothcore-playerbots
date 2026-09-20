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
    dps = {0.91, 0.31, 0.3, 1},
    chrome = {0.52, 0.36, 0.14, 1},
    chromeBright = {0.93, 0.68, 0.24, 1},
    surfaceDeep = {0.01, 0.018, 0.03, 1},
    surfaceBlue = {0.018, 0.055, 0.095, 1},
    highlight = {0.42, 0.75, 1, 1},
    shadow = {0, 0, 0, 0.72}
}}
return ____exports
 end,
["core.Native"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
____exports.CLASS_ICON_ATLAS = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
local ROLE_ICON_TEXTURES = {TANK = "Interface\\Icons\\Ability_Warrior_DefensiveStance", HEALER = "Interface\\Icons\\Spell_Holy_HolyBolt", DPS = "Interface\\Icons\\Ability_DualWield"}
function ____exports.setTextureColor(self, texture, color)
    texture:SetTexture(color[1], color[2], color[3], color[4])
end
function ____exports.withAlpha(self, color, alpha)
    return {color[1], color[2], color[3], alpha}
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
function ____exports.createFramedIcon(self, parent, path, size, borderColor)
    if borderColor == nil then
        borderColor = theme.colors.borderStrong
    end
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(size, size)
    local bg = ____exports.createSolid(nil, frame, theme.colors.surfaceDeep)
    bg:SetAllPoints(frame)
    local outline = ____exports.createOutline(nil, frame, borderColor)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        3,
        -3
    )
    icon:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        -3,
        3
    )
    icon:SetTexture(path)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    return {frame = frame, icon = icon, outline = outline}
end
function ____exports.createChrome(self, frame, accent, ornate)
    if accent == nil then
        accent = theme.colors.chrome
    end
    if ornate == nil then
        ornate = false
    end
    ____exports.createOutline(nil, frame, accent)
    if not ornate then
        return
    end
    local corner = 12
    local thickness = 2
    local pieces = {
        {
            "TOPLEFT",
            2,
            -2,
            corner,
            thickness
        },
        {
            "TOPLEFT",
            2,
            -2,
            thickness,
            corner
        },
        {
            "TOPRIGHT",
            -2,
            -2,
            corner,
            thickness
        },
        {
            "TOPRIGHT",
            -2,
            -2,
            thickness,
            corner
        },
        {
            "BOTTOMLEFT",
            2,
            2,
            corner,
            thickness
        },
        {
            "BOTTOMLEFT",
            2,
            2,
            thickness,
            corner
        },
        {
            "BOTTOMRIGHT",
            -2,
            2,
            corner,
            thickness
        },
        {
            "BOTTOMRIGHT",
            -2,
            2,
            thickness,
            corner
        }
    }
    do
        local i = 0
        while i < #pieces do
            local item = pieces[i + 1]
            local piece = ____exports.createSolid(nil, frame, i % 2 == 0 and theme.colors.chromeBright or accent, "OVERLAY")
            piece:SetSize(item[4], item[5])
            piece:SetPoint(
                item[1],
                frame,
                item[1],
                item[2],
                item[3]
            )
            i = i + 1
        end
    end
end
function ____exports.setRoleIcon(self, texture, role)
    texture:SetTexture(ROLE_ICON_TEXTURES[role] or ROLE_ICON_TEXTURES.DPS)
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
end
function ____exports.createFramedRoleIcon(self, parent, role, size, borderColor)
    if borderColor == nil then
        borderColor = theme.colors.borderStrong
    end
    local framed = ____exports.createFramedIcon(
        nil,
        parent,
        ROLE_ICON_TEXTURES[role] or ROLE_ICON_TEXTURES.DPS,
        size,
        borderColor
    )
    ____exports.setRoleIcon(nil, framed.icon, role)
    return framed
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
local withAlpha = ____Native.withAlpha
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
function ____exports.createButton(self, parent, options)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetSize(options.width, options.height)
    frame:EnableMouse(true)
    local accent = options.accent or theme.colors.primary
    local background = createSolid(nil, frame, options.emphasis == true and theme.colors.surfaceBlue or (options.flat == true and theme.colors.surface or theme.colors.surfaceRaised))
    background:SetAllPoints(frame)
    local outline = createOutline(nil, frame, options.emphasis == true and accent or (options.flat == true and theme.colors.surface or theme.colors.border))
    local selectedWash = createSolid(
        nil,
        frame,
        withAlpha(nil, accent, 0.1),
        "ARTWORK"
    )
    selectedWash:SetAllPoints(frame)
    selectedWash:Hide()
    local label = createText(nil, frame, options.text, options.height >= 34 and "GameFontHighlight" or "GameFontHighlightSmall")
    local icon
    if options.icon ~= nil then
        icon = frame:CreateTexture(nil, "ARTWORK")
        local iconSize = options.iconSize or math.min(22, options.height - 12)
        icon:SetSize(iconSize, iconSize)
        icon:SetPoint(
            "LEFT",
            frame,
            "LEFT",
            10,
            0
        )
        icon:SetTexture(options.icon)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        label:SetPoint(
            "LEFT",
            icon,
            "RIGHT",
            8,
            0
        )
        label:SetPoint(
            "RIGHT",
            frame,
            "RIGHT",
            -8,
            0
        )
        label:SetJustifyH("LEFT")
    else
        label:SetPoint(
            "CENTER",
            frame,
            "CENTER",
            0,
            0
        )
        label:SetJustifyH("CENTER")
    end
    local selected = false
    local enabled = true
    local hovered = false
    local function render(self)
        frame:SetAlpha(enabled and 1 or 0.38)
        if selected then
            setTextureColor(nil, background, theme.colors.surfaceBlue)
            outline:setColor(accent)
            selectedWash:Show()
        else
            selectedWash:Hide()
            setTextureColor(nil, background, hovered and enabled and theme.colors.surfaceHover or (options.emphasis == true and theme.colors.surfaceBlue or (options.flat == true and theme.colors.surface or theme.colors.surfaceRaised)))
            outline:setColor(options.emphasis == true and accent or (hovered and enabled and theme.colors.borderStrong or (options.flat == true and theme.colors.surface or theme.colors.border)))
        end
        local color = selected and accent or theme.colors.text
        label:SetTextColor(color[1], color[2], color[3], enabled and 1 or 0.72)
    end
    frame:SetScript(
        "OnEnter",
        function()
            hovered = true
            render(nil)
        end
    )
    frame:SetScript(
        "OnLeave",
        function()
            hovered = false
            render(nil)
        end
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
        icon = icon,
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
local createFramedIcon = ____Native.createFramedIcon
local createPanel = ____Native.createPanel
local createSolid = ____Native.createSolid
local createText = ____Native.createText
local withAlpha = ____Native.withAlpha
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
    local move, wheel, bindWheel, refreshRail, positionRowLabel, refreshRows, refresh, trigger, triggerIcon, popup, maxVisible, rowHeight, railWidth, offset, rows, rail, up, down, thumb
    function move(self, delta)
        local items = options:getItems()
        local maxOffset = math.max(0, #items - maxVisible)
        offset = math.max(
            0,
            math.min(maxOffset, offset + delta)
        )
        refreshRows(nil)
    end
    function wheel(_frame, delta)
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
        if maxOffset <= 0 then
            rail:Hide()
            return
        end
        rail:Show()
        up:setEnabled(offset > 0)
        down:setEnabled(offset < maxOffset)
        local popupHeight = popup.frame:GetHeight()
        local trackHeight = math.max(30, popupHeight - 42)
        local thumbHeight = math.max(
            20,
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
            -(3 + travel * ratio)
        )
    end
    function positionRowLabel(self, row, hasIcon)
        row.button.label:ClearAllPoints()
        row.button.label:SetPoint(
            "TOPLEFT",
            row.button.frame,
            "TOPLEFT",
            hasIcon and 48 or 10,
            -7
        )
        row.button.label:SetPoint(
            "RIGHT",
            row.button.frame,
            "RIGHT",
            -8,
            7
        )
        row.button.label:SetJustifyH("LEFT")
        row.detail:ClearAllPoints()
        row.detail:SetPoint(
            "TOPLEFT",
            row.button.frame,
            "TOPLEFT",
            hasIcon and 48 or 10,
            -26
        )
        row.detail:SetPoint(
            "RIGHT",
            row.button.frame,
            "RIGHT",
            -8,
            0
        )
        row.detail:SetJustifyH("LEFT")
    end
    function refreshRows(self)
        local items = options:getItems()
        local visible = math.min(maxVisible, #items)
        popup.frame:SetHeight(math.max(12, visible * rowHeight + 4))
        do
            local i = 0
            while i < maxVisible do
                local row = rows[i + 1]
                if row == nil then
                    local button = createButton(nil, popup.frame, {
                        text = "",
                        width = options.width - railWidth - 6,
                        height = rowHeight - 2,
                        accent = theme.colors.primary,
                        flat = true
                    })
                    button.frame:SetPoint(
                        "TOPLEFT",
                        popup.frame,
                        "TOPLEFT",
                        2,
                        -(2 + i * rowHeight)
                    )
                    local iconFrame = createFramedIcon(
                        nil,
                        button.frame,
                        "Interface\\Icons\\INV_Misc_QuestionMark",
                        32,
                        theme.colors.borderStrong
                    )
                    iconFrame.frame:SetPoint(
                        "LEFT",
                        button.frame,
                        "LEFT",
                        8,
                        0
                    )
                    iconFrame.frame:Hide()
                    local detail = createText(
                        nil,
                        button.frame,
                        "",
                        "GameFontHighlightSmall",
                        theme.colors.muted
                    )
                    bindWheel(nil, button.frame)
                    row = {button = button, detail = detail, iconFrame = iconFrame.frame, icon = iconFrame.icon}
                    rows[i + 1] = row
                end
                local item = items[offset + i + 1]
                if item ~= nil then
                    local hasIcon = item.icon ~= nil and item.icon ~= ""
                    row.button:setText(item.label)
                    row.detail:SetText(item.detail or "")
                    row.button:setSelected(item.value == options:getValue())
                    positionRowLabel(nil, row, hasIcon)
                    if hasIcon then
                        row.icon:SetTexture(tostring(item.icon))
                        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                        row.iconFrame:Show()
                    else
                        row.iconFrame:Hide()
                    end
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
        local selectedItem
        for ____, item in ipairs(options:getItems()) do
            if item.value == value then
                selectedItem = item
                break
            end
        end
        trigger:setText(selectedItem and selectedItem.label or "Select")
        local hasIcon = (selectedItem and selectedItem.icon) ~= nil and selectedItem.icon ~= ""
        trigger.label:ClearAllPoints()
        trigger.label:SetPoint(
            "LEFT",
            trigger.frame,
            "LEFT",
            hasIcon and 42 or 12,
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
        if hasIcon then
            triggerIcon.icon:SetTexture(tostring(selectedItem and selectedItem.icon))
            triggerIcon.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            triggerIcon.frame:Show()
        else
            triggerIcon.frame:Hide()
        end
        refreshRows(nil)
    end
    trigger = createButton(nil, parent, {text = "Select", width = options.width, height = 38, accent = theme.colors.primary})
    triggerIcon = createFramedIcon(
        nil,
        trigger.frame,
        "Interface\\Icons\\INV_Misc_QuestionMark",
        26,
        theme.colors.borderStrong
    )
    triggerIcon.frame:SetPoint(
        "LEFT",
        trigger.frame,
        "LEFT",
        8,
        0
    )
    triggerIcon.frame:Hide()
    local arrow = createText(
        nil,
        trigger.frame,
        "v",
        "GameFontHighlightSmall",
        theme.colors.primary
    )
    arrow:SetPoint(
        "RIGHT",
        trigger.frame,
        "RIGHT",
        -12,
        0
    )
    arrow:SetJustifyH("CENTER")
    popup = createPanel(nil, trigger.frame, theme.colors.background, theme.colors.borderStrong)
    popup.frame:SetFrameStrata("TOOLTIP")
    popup.frame:SetWidth(options.width)
    popup.frame:EnableMouseWheel(true)
    popup.frame:Hide()
    maxVisible = options.maxVisible or 8
    rowHeight = 48
    railWidth = 14
    offset = 0
    rows = {}
    rail = CreateFrame("Frame", nil, popup.frame)
    rail:SetPoint(
        "TOPRIGHT",
        popup.frame,
        "TOPRIGHT",
        -2,
        -2
    )
    rail:SetPoint(
        "BOTTOMRIGHT",
        popup.frame,
        "BOTTOMRIGHT",
        -2,
        2
    )
    rail:SetWidth(railWidth)
    local railBg = createSolid(
        nil,
        rail,
        withAlpha(nil, theme.colors.surfaceDeep, 0.78)
    )
    railBg:SetAllPoints(rail)
    up = createButton(
        nil,
        rail,
        {
            text = "^",
            width = railWidth,
            height = 18,
            accent = theme.colors.primary,
            flat = true,
            onClick = function() return move(nil, -1) end
        }
    )
    up.frame:SetPoint(
        "TOP",
        rail,
        "TOP",
        0,
        0
    )
    down = createButton(
        nil,
        rail,
        {
            text = "v",
            width = railWidth,
            height = 18,
            accent = theme.colors.primary,
            flat = true,
            onClick = function() return move(nil, 1) end
        }
    )
    down.frame:SetPoint(
        "BOTTOM",
        rail,
        "BOTTOM",
        0,
        0
    )
    local track = createSolid(nil, rail, theme.colors.borderStrong, "ARTWORK")
    track:SetPoint(
        "TOP",
        up.frame,
        "BOTTOM",
        0,
        -3
    )
    track:SetPoint(
        "BOTTOM",
        down.frame,
        "TOP",
        0,
        3
    )
    track:SetWidth(2)
    thumb = createSolid(nil, rail, theme.colors.primary, "OVERLAY")
    thumb:SetWidth(5)
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
            -3
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
    bindWheel(nil, rail)
    bindWheel(nil, up.frame)
    bindWheel(nil, down.frame)
    refresh(nil)
    return {
        frame = trigger.frame,
        refresh = function() return refresh(nil) end,
        close = function()
            if activePopup == popup.frame then
                closeActive(nil)
            else
                popup.frame:Hide()
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

local function __TS__ArraySort(self, compareFn)
    if compareFn ~= nil then
        table.sort(
            self,
            function(a, b) return compareFn(nil, a, b) < 0 end
        )
    else
        table.sort(self)
    end
    return self
end
-- End of Lua Library inline imports
local ____exports = {}
local GC
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
function ____exports.activityMeta(self, id, mode)
    local ____GC_activityMeta_33 = GC.activityMeta
    if ____GC_activityMeta_33 == nil then
        ____GC_activityMeta_33 = {}
    end
    local byMode = ____GC_activityMeta_33
    local ____byMode_mode_34 = byMode[mode]
    if ____byMode_mode_34 == nil then
        ____byMode_mode_34 = {}
    end
    local entries = ____byMode_mode_34
    local raw = entries[id]
    if raw == nil then
        return nil
    end
    local ____raw_id_35 = raw.id
    if ____raw_id_35 == nil then
        ____raw_id_35 = id
    end
    local ____tostring_result_43 = tostring(____raw_id_35)
    local ____raw_label_36 = raw.label
    if ____raw_label_36 == nil then
        ____raw_label_36 = id
    end
    local ____tostring_result_44 = tostring(____raw_label_36)
    local ____raw_era_37 = raw.era
    if ____raw_era_37 == nil then
        ____raw_era_37 = "Vanilla"
    end
    local ____tostring_result_45 = tostring(____raw_era_37)
    local ____raw_minLevel_38 = raw.minLevel
    if ____raw_minLevel_38 == nil then
        ____raw_minLevel_38 = 1
    end
    local ____TS__Number_result_46 = __TS__Number(____raw_minLevel_38)
    local ____raw_minProgression_39 = raw.minProgression
    if ____raw_minProgression_39 == nil then
        ____raw_minProgression_39 = 0
    end
    local ____TS__Number_result_47 = __TS__Number(____raw_minProgression_39)
    local ____raw_size_40 = raw.size
    if ____raw_size_40 == nil then
        ____raw_size_40 = mode == "RAID" and 10 or 5
    end
    local ____TS__Number_result_48 = __TS__Number(____raw_size_40)
    local ____raw_support_41 = raw.support
    if ____raw_support_41 == nil then
        ____raw_support_41 = "Unknown"
    end
    local ____tostring_result_49 = tostring(____raw_support_41)
    local ____raw_map_42 = raw.map
    if ____raw_map_42 == nil then
        ____raw_map_42 = 0
    end
    return {
        id = ____tostring_result_43,
        label = ____tostring_result_44,
        era = ____tostring_result_45,
        minLevel = ____TS__Number_result_46,
        minProgression = ____TS__Number_result_47,
        size = ____TS__Number_result_48,
        support = ____tostring_result_49,
        map = __TS__Number(____raw_map_42)
    }
end
____exports.ANY_SPEC_ID = -1
GC = _G.GroupComposer
local D = _G.GroupComposerData
local DataFns = _G.GroupComposerData
local P = _G.GroupComposerProfiles
local ProfileFns = _G.GroupComposerProfiles
local ACTIVITY_ICONS = {
    random = "Interface\\Icons\\INV_Misc_Dice_02",
    utgarde_keep = "Interface\\Icons\\INV_Misc_Bone_10",
    nexus = "Interface\\Icons\\Spell_Arcane_PortalDalaran",
    azjol_nerub = "Interface\\Icons\\Ability_Hunter_Pet_Spider",
    ahnkahet = "Interface\\Icons\\Spell_Shadow_Twilight",
    drak_tharon = "Interface\\Icons\\INV_Misc_Head_Troll_01",
    violet_hold = "Interface\\Icons\\Spell_Arcane_PortalDalaran",
    gundrak = "Interface\\Icons\\INV_Misc_Head_Troll_01",
    halls_of_stone = "Interface\\Icons\\INV_Stone_14",
    halls_of_lightning = "Interface\\Icons\\Spell_Nature_Lightning",
    oculus = "Interface\\Icons\\INV_Misc_Head_Dragon_Blue",
    culling = "Interface\\Icons\\Spell_Holy_Excorcism_02",
    utgarde_pinnacle = "Interface\\Icons\\INV_Misc_Bone_10",
    trial_champion = "Interface\\Icons\\INV_Sword_04",
    forge_souls = "Interface\\Icons\\Spell_Shadow_SoulLeech_3",
    pit_saron = "Interface\\Icons\\INV_Pick_02",
    halls_reflection = "Interface\\Icons\\Spell_Deathknight_FrostPresence",
    naxxramas = "Interface\\Icons\\Spell_Shadow_AnimateDead",
    obsidian_sanctum = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
    eye_of_eternity = "Interface\\Icons\\INV_Misc_Head_Dragon_Blue",
    ulduar = "Interface\\Icons\\INV_Gizmo_02",
    trial_crusader = "Interface\\Icons\\INV_Misc_Head_Nerubian_01",
    onyxia = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
    vault_archavon = "Interface\\Icons\\INV_Elemental_Primal_Earth",
    icecrown = "Interface\\Icons\\Spell_Deathknight_FrostPresence",
    ruby_sanctum = "Interface\\Icons\\INV_Misc_Head_Dragon_Red",
    karazhan = "Interface\\Icons\\Spell_Arcane_PortalDalaran",
    zulaman = "Interface\\Icons\\INV_Misc_Head_Troll_01",
    gruul = "Interface\\Icons\\Ability_Warrior_Charge",
    magtheridon = "Interface\\Icons\\Spell_Shadow_SummonFelGuard",
    serpentshrine = "Interface\\Icons\\Spell_Frost_SummonWaterElemental_2",
    tempest_keep = "Interface\\Icons\\Spell_Arcane_PortalDalaran",
    hyjal = "Interface\\Icons\\Spell_Nature_NatureGuardian",
    black_temple = "Interface\\Icons\\Spell_Shadow_Metamorphosis",
    sunwell = "Interface\\Icons\\Spell_Holy_SummonLightwell",
    zul_gurub = "Interface\\Icons\\INV_Misc_Head_Troll_01",
    aq20 = "Interface\\Icons\\INV_Misc_Head_Qiraji_01",
    molten_core = "Interface\\Icons\\Spell_Fire_FlameBolt",
    blackwing_lair = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
    aq40 = "Interface\\Icons\\INV_Misc_Head_Qiraji_01"
}
local DEFAULT_DUNGEON_ICON = "Interface\\Icons\\Spell_Arcane_PortalDalaran"
local DEFAULT_RAID_ICON = "Interface\\Icons\\Achievement_Boss_LichKing"
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
    local ____local = DataFns.GetDungeonById(id)
    if ____local ~= nil then
        return ____local
    end
    return ____exports.activityMeta(nil, id, "DUNGEON")
end
local function raidById(self, id)
    local ____local = DataFns.GetRaidById(id)
    if ____local ~= nil then
        return ____local
    end
    return ____exports.activityMeta(nil, id, "RAID")
end
function ____exports.realm(self)
    local ____GC_realm_26 = GC.realm
    if ____GC_realm_26 == nil then
        ____GC_realm_26 = {}
    end
    local raw = ____GC_realm_26
    local ____raw_era_27 = raw.era
    if ____raw_era_27 == nil then
        ____raw_era_27 = "Vanilla"
    end
    local ____tostring_result_31 = tostring(____raw_era_27)
    local ____raw_levelCap_28 = raw.levelCap
    if ____raw_levelCap_28 == nil then
        ____raw_levelCap_28 = 60
    end
    local ____TS__Number_result_32 = __TS__Number(____raw_levelCap_28)
    local ____raw_progression_29 = raw.progression
    if ____raw_progression_29 == nil then
        ____raw_progression_29 = GC.activityProgression
    end
    local ____raw_progression_29_30 = ____raw_progression_29
    if ____raw_progression_29_30 == nil then
        ____raw_progression_29_30 = 0
    end
    return {
        era = ____tostring_result_31,
        levelCap = ____TS__Number_result_32,
        progression = __TS__Number(____raw_progression_29_30)
    }
end
function ____exports.activityMetaList(self, mode)
    local result = {}
    local ____GC_activityMeta_50 = GC.activityMeta
    if ____GC_activityMeta_50 == nil then
        ____GC_activityMeta_50 = {}
    end
    local byMode = ____GC_activityMeta_50
    local ____byMode_mode_51 = byMode[mode]
    if ____byMode_mode_51 == nil then
        ____byMode_mode_51 = {}
    end
    local entries = ____byMode_mode_51
    for id in pairs(entries) do
        local meta = ____exports.activityMeta(
            nil,
            tostring(id),
            mode
        )
        if meta ~= nil then
            result[#result + 1] = meta
        end
    end
    __TS__ArraySort(
        result,
        function(____, a, b)
            local eraOrder = {Vanilla = 0, TBC = 1, WotLK = 2}
            local ae = eraOrder[a.era] or 9
            local be = eraOrder[b.era] or 9
            if ae ~= be then
                return ae - be
            end
            if a.minLevel ~= b.minLevel then
                return a.minLevel - b.minLevel
            end
            return a.label < b.label and -1 or (a.label > b.label and 1 or 0)
        end
    )
    return result
end
function ____exports.journey(self)
    local ____GC_journey_52 = GC.journey
    if ____GC_journey_52 == nil then
        ____GC_journey_52 = {}
    end
    local raw = ____GC_journey_52
    local ____temp_59 = raw.ready == true
    local ____raw_raids_53 = raw.raids
    if ____raw_raids_53 == nil then
        ____raw_raids_53 = {}
    end
    local ____raw_recommendations_54 = raw.recommendations
    if ____raw_recommendations_54 == nil then
        ____raw_recommendations_54 = {}
    end
    local ____raw_era_55 = raw.era
    if ____raw_era_55 == nil then
        ____raw_era_55 = ____exports.realm(nil).era
    end
    local ____tostring_result_60 = tostring(____raw_era_55)
    local ____raw_stage_56 = raw.stage
    if ____raw_stage_56 == nil then
        ____raw_stage_56 = ____exports.realm(nil).progression
    end
    local ____TS__Number_result_61 = __TS__Number(____raw_stage_56)
    local ____raw_level_57 = raw.level
    if ____raw_level_57 == nil then
        ____raw_level_57 = 1
    end
    local ____TS__Number_result_62 = __TS__Number(____raw_level_57)
    local ____raw_guildId_58 = raw.guildId
    if ____raw_guildId_58 == nil then
        ____raw_guildId_58 = 0
    end
    return {
        ready = ____temp_59,
        raids = ____raw_raids_53,
        recommendations = ____raw_recommendations_54,
        era = ____tostring_result_60,
        stage = ____TS__Number_result_61,
        level = ____TS__Number_result_62,
        guildId = __TS__Number(____raw_guildId_58)
    }
end
function ____exports.unlockDetails(self)
    local ____GC_unlockDetails_63 = GC.unlockDetails
    if ____GC_unlockDetails_63 == nil then
        ____GC_unlockDetails_63 = {}
    end
    local raw = ____GC_unlockDetails_63
    local ____temp_68 = raw.ready == true
    local ____temp_69 = raw.mode == "RAID" and "RAID" or "DUNGEON"
    local ____raw_id_64 = raw.id
    if ____raw_id_64 == nil then
        ____raw_id_64 = ""
    end
    local ____tostring_result_70 = tostring(____raw_id_64)
    local ____raw_label_65 = raw.label
    if ____raw_label_65 == nil then
        ____raw_label_65 = ""
    end
    local ____tostring_result_71 = tostring(____raw_label_65)
    local ____temp_72 = raw.available == true
    local ____raw_summary_66 = raw.summary
    if ____raw_summary_66 == nil then
        ____raw_summary_66 = ""
    end
    local ____tostring_result_73 = tostring(____raw_summary_66)
    local ____raw_requirements_67 = raw.requirements
    if ____raw_requirements_67 == nil then
        ____raw_requirements_67 = {}
    end
    return {
        ready = ____temp_68,
        mode = ____temp_69,
        id = ____tostring_result_70,
        label = ____tostring_result_71,
        available = ____temp_72,
        summary = ____tostring_result_73,
        requirements = ____raw_requirements_67
    }
end
function ____exports.catalogDiagnostics(self)
    local ____GC_catalogDiagnostics_74 = GC.catalogDiagnostics
    if ____GC_catalogDiagnostics_74 == nil then
        ____GC_catalogDiagnostics_74 = {}
    end
    local raw = ____GC_catalogDiagnostics_74
    local ____temp_79 = raw.ready == true
    local ____raw_entries_75 = raw.entries
    if ____raw_entries_75 == nil then
        ____raw_entries_75 = {}
    end
    local ____raw_pass_76 = raw.pass
    if ____raw_pass_76 == nil then
        ____raw_pass_76 = 0
    end
    local ____TS__Number_result_80 = __TS__Number(____raw_pass_76)
    local ____raw_warn_77 = raw.warn
    if ____raw_warn_77 == nil then
        ____raw_warn_77 = 0
    end
    local ____TS__Number_result_81 = __TS__Number(____raw_warn_77)
    local ____raw_fail_78 = raw.fail
    if ____raw_fail_78 == nil then
        ____raw_fail_78 = 0
    end
    return {
        ready = ____temp_79,
        entries = ____raw_entries_75,
        pass = ____TS__Number_result_80,
        warn = ____TS__Number_result_81,
        fail = __TS__Number(____raw_fail_78)
    }
end
function ____exports.pinnedMembers(self)
    local result = {}
    local ____exports_config_result_pinned_82 = ____exports.config(nil).pinned
    if ____exports_config_result_pinned_82 == nil then
        ____exports_config_result_pinned_82 = {}
    end
    for ____, pin in ipairs(____exports_config_result_pinned_82) do
        result[#result + 1] = pin
    end
    return result
end
function ____exports.planWarnings(self)
    local result = {}
    local ____exports_plan_result_warnings_83 = ____exports.plan(nil).warnings
    if ____exports_plan_result_warnings_83 == nil then
        ____exports_plan_result_warnings_83 = {}
    end
    for ____, warning in ipairs(____exports_plan_result_warnings_83) do
        result[#result + 1] = tostring(warning)
    end
    return result
end
function ____exports.coverageDisplay(self)
    local ____exports_plan_result_summary_84 = ____exports.plan(nil).summary
    if ____exports_plan_result_summary_84 == nil then
        ____exports_plan_result_summary_84 = {}
    end
    local summary = ____exports_plan_result_summary_84
    local ____summary_utility_85 = summary.utility
    if ____summary_utility_85 == nil then
        ____summary_utility_85 = ""
    end
    local raw = tostring(____summary_utility_85)
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
    local ____temp_87 = (utility .. "\n") .. "Ranged DPS  "
    local ____summary_ranged_86 = summary.ranged
    if ____summary_ranged_86 == nil then
        ____summary_ranged_86 = 0
    end
    local ____temp_89 = (____temp_87 .. tostring(____summary_ranged_86)) .. "     Melee DPS  "
    local ____summary_melee_88 = summary.melee
    if ____summary_melee_88 == nil then
        ____summary_melee_88 = 0
    end
    return ____temp_89 .. tostring(____summary_melee_88)
end
function ____exports.dungeonItems(self)
    local result = {}
    local ____D_DUNGEONS_91 = D.DUNGEONS
    if ____D_DUNGEONS_91 == nil then
        ____D_DUNGEONS_91 = {}
    end
    for ____, dungeon in __TS__Iterator(____D_DUNGEONS_91) do
        local ____dungeon_minLevel_90 = dungeon.minLevel
        if ____dungeon_minLevel_90 == nil then
            ____dungeon_minLevel_90 = 68
        end
        local min = __TS__Number(____dungeon_minLevel_90)
        result[#result + 1] = {
            value = dungeon.id,
            label = dungeon.label,
            detail = dungeon.id == "random" and ("WotLK random · Normal Lv " .. tostring(min)) .. "+ · Heroic Lv 80" or ("Normal Lv " .. tostring(min)) .. "+ · Heroic Lv 80",
            icon = ACTIVITY_ICONS[tostring(dungeon.id)] or DEFAULT_DUNGEON_ICON
        }
    end
    return result
end
function ____exports.difficultyItems(self)
    local currentEra = ____exports.realm(nil).era
    local result = {{value = "normal", label = "Normal"}}
    if currentEra == "Vanilla" then
        return result
    end
    result[#result + 1] = {value = "heroic", label = "Heroic"}
    if currentEra == "WotLK" then
        result[#result + 1] = {value = "alpha", label = "Titan Rune Alpha"}
        result[#result + 1] = {value = "beta", label = "Titan Rune Beta"}
        result[#result + 1] = {value = "gamma", label = "Titan Rune Gamma"}
    end
    return result
end
function ____exports.raidItems(self)
    local result = {}
    local ____D_RAIDS_97 = D.RAIDS
    if ____D_RAIDS_97 == nil then
        ____D_RAIDS_97 = {}
    end
    for ____, raid in __TS__Iterator(____D_RAIDS_97) do
        local sizes = ""
        local firstSize = true
        local ____raid_sizes_92 = raid.sizes
        if ____raid_sizes_92 == nil then
            ____raid_sizes_92 = {}
        end
        for ____, size in __TS__Iterator(____raid_sizes_92) do
            if not firstSize then
                sizes = sizes .. "/"
            end
            sizes = sizes .. tostring(size)
            firstSize = false
        end
        local ____raid_id_95 = raid.id
        local ____temp_96 = (tostring(raid.era) .. "  ·  ") .. tostring(raid.label)
        local ____temp_94 = sizes .. " player · Level "
        local ____raid_requiredLevel_93 = raid.requiredLevel
        if ____raid_requiredLevel_93 == nil then
            ____raid_requiredLevel_93 = 80
        end
        result[#result + 1] = {
            value = ____raid_id_95,
            label = ____temp_96,
            detail = (____temp_94 .. tostring(____raid_requiredLevel_93)) .. "+",
            icon = ACTIVITY_ICONS[tostring(raid.id)] or DEFAULT_RAID_ICON
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
    local ____opt_result_100
    if raid ~= nil then
        ____opt_result_100 = raid.heroic
    end
    if ____opt_result_100 == true then
        result[#result + 1] = {value = "heroic", label = "Heroic"}
    end
    return result
end
function ____exports.selectedActivityLabel(self)
    local cfg = ____exports.config(nil)
    local mode = cfg.mode == "RAID" and "RAID" or "DUNGEON"
    local ____exports_activityMeta_102 = ____exports.activityMeta
    local ____cfg_activity_101 = cfg.activity
    if ____cfg_activity_101 == nil then
        ____cfg_activity_101 = ""
    end
    local meta = ____exports_activityMeta_102(
        nil,
        tostring(____cfg_activity_101),
        mode
    )
    if meta ~= nil then
        return meta.label
    end
    if cfg.mode == "RAID" then
        local raid = raidById(nil, cfg.activity)
        local ____opt_result_105
        if raid ~= nil then
            ____opt_result_105 = raid.label
        end
        local ____opt_result_105_106 = ____opt_result_105
        if ____opt_result_105_106 == nil then
            ____opt_result_105_106 = "Raid"
        end
        return ____opt_result_105_106
    end
    local dungeon = dungeonById(nil, cfg.activity)
    local ____opt_result_109
    if dungeon ~= nil then
        ____opt_result_109 = dungeon.label
    end
    local ____opt_result_109_110 = ____opt_result_109
    if ____opt_result_109_110 == nil then
        ____opt_result_109_110 = "Dungeon"
    end
    return ____opt_result_109_110
end
function ____exports.activityIconFor(self, id, mode)
    return ACTIVITY_ICONS[tostring(id)] or (mode == "RAID" and DEFAULT_RAID_ICON or DEFAULT_DUNGEON_ICON)
end
function ____exports.selectedActivityIcon(self)
    local cfg = ____exports.config(nil)
    local ____exports_activityIconFor_112 = ____exports.activityIconFor
    local ____cfg_activity_111 = cfg.activity
    if ____cfg_activity_111 == nil then
        ____cfg_activity_111 = ""
    end
    return ____exports_activityIconFor_112(
        nil,
        tostring(____cfg_activity_111),
        cfg.mode == "RAID" and "RAID" or "DUNGEON"
    )
end
function ____exports.requiredActivityLevel(self)
    local cfg = ____exports.config(nil)
    local mode = cfg.mode == "RAID" and "RAID" or "DUNGEON"
    local ____exports_activityMeta_114 = ____exports.activityMeta
    local ____cfg_activity_113 = cfg.activity
    if ____cfg_activity_113 == nil then
        ____cfg_activity_113 = ""
    end
    local meta = ____exports_activityMeta_114(
        nil,
        tostring(____cfg_activity_113),
        mode
    )
    if meta ~= nil then
        if mode == "DUNGEON" and cfg.difficulty ~= "normal" then
            return math.max(meta.minLevel, meta.era == "WotLK" and 80 or 70)
        end
        return meta.minLevel
    end
    if cfg.mode == "RAID" then
        local raid = raidById(nil, cfg.activity)
        local ____opt_result_117
        if raid ~= nil then
            ____opt_result_117 = raid.requiredLevel
        end
        local ____opt_result_117_118 = ____opt_result_117
        if ____opt_result_117_118 == nil then
            ____opt_result_117_118 = ____exports.realm(nil).levelCap
        end
        return __TS__Number(____opt_result_117_118)
    end
    local dungeon = dungeonById(nil, cfg.activity)
    local ____opt_result_121
    if dungeon ~= nil then
        ____opt_result_121 = dungeon.minLevel
    end
    local ____opt_result_121_122 = ____opt_result_121
    if ____opt_result_121_122 == nil then
        ____opt_result_121_122 = 1
    end
    return __TS__Number(____opt_result_121_122)
end
function ____exports.activityEligibilityText(self)
    local level = ____exports.requiredActivityLevel(nil)
    local ____opt_123 = ____exports.config(nil).options
    if ____opt_123 ~= nil then
        ____opt_123 = ____opt_123.minimumItemLevel
    end
    local ____opt_123_125 = ____opt_123
    if ____opt_123_125 == nil then
        ____opt_123_125 = 0
    end
    local floor = __TS__Number(____opt_123_125)
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
    local ____opt_result_128
    if raid ~= nil then
        ____opt_result_128 = raid.sizes
    end
    local ____opt_result_128_129 = ____opt_result_128
    if ____opt_result_128_129 == nil then
        ____opt_result_128_129 = {}
    end
    for ____, size in __TS__Iterator(____opt_result_128_129) do
        result[#result + 1] = __TS__Number(size)
    end
    return result
end
function ____exports.requestActivities(self, mode, difficulty, size)
    local selectedMode = mode or (____exports.config(nil).mode == "RAID" and "RAID" or "DUNGEON")
    GC:RequestActivities(selectedMode, difficulty, size)
end
function ____exports.requestUnlockDetails(self, id, mode)
    local cfg = ____exports.config(nil)
    GC:RequestUnlockDetails(mode, id, cfg.difficulty, cfg.size)
end
function ____exports.requestJourney(self)
    GC:RequestJourney()
end
function ____exports.requestCatalogDiagnostics(self)
    GC:RequestCatalogDiagnostics()
end
function ____exports.activityEligibility(self, id, mode)
    local selectedMode = mode or (____exports.config(nil).mode == "RAID" and "RAID" or "DUNGEON")
    local ____GC_activityEligibilityReady_130 = GC.activityEligibilityReady
    if ____GC_activityEligibilityReady_130 == nil then
        ____GC_activityEligibilityReady_130 = {}
    end
    local readyByMode = ____GC_activityEligibilityReady_130
    local ____GC_activityEligibility_131 = GC.activityEligibility
    if ____GC_activityEligibility_131 == nil then
        ____GC_activityEligibility_131 = {}
    end
    local eligibilityByMode = ____GC_activityEligibility_131
    local ____eligibilityByMode_selectedMode_132 = eligibilityByMode[selectedMode]
    if ____eligibilityByMode_selectedMode_132 == nil then
        ____eligibilityByMode_selectedMode_132 = {}
    end
    local entries = ____eligibilityByMode_selectedMode_132
    local entry = entries[id]
    if readyByMode[selectedMode] ~= true or entry == nil then
        return {known = false, eligible = false, reason = "Checking access..."}
    end
    local ____temp_134 = entry.eligible == true
    local ____entry_reason_133 = entry.reason
    if ____entry_reason_133 == nil then
        ____entry_reason_133 = entry.eligible == true and "Available" or "Locked"
    end
    return {
        known = true,
        eligible = ____temp_134,
        reason = tostring(____entry_reason_133)
    }
end
function ____exports.selectedActivityEligibility(self)
    local cfg = ____exports.config(nil)
    local ____exports_activityEligibility_136 = ____exports.activityEligibility
    local ____cfg_activity_135 = cfg.activity
    if ____cfg_activity_135 == nil then
        ____cfg_activity_135 = ""
    end
    return ____exports_activityEligibility_136(
        nil,
        tostring(____cfg_activity_135),
        cfg.mode == "RAID" and "RAID" or "DUNGEON"
    )
end
function ____exports.setMode(self, mode)
    GC:SetMode(mode)
    ____exports.requestActivities(nil, mode)
end
function ____exports.setDungeonActivity(self, id)
    GC:SetDungeonActivity(id)
end
function ____exports.setRaidActivity(self, id)
    GC:SetRaidActivity(id)
end
function ____exports.setRaidSize(self, size)
    GC:SetRaidSize(size)
    ____exports.requestActivities(nil, "RAID")
end
function ____exports.setDifficulty(self, id)
    ____exports.config(nil).difficulty = id
    ____exports.touch(nil, "Difficulty changed")
    ____exports.requestActivities(
        nil,
        ____exports.config(nil).mode == "RAID" and "RAID" or "DUNGEON"
    )
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
function ____exports.teleportToInstance(self)
    GC:TeleportToInstance()
end
function ____exports.leaveInstance(self)
    GC:LeaveInstance()
end
function ____exports.disbandComposerGroup(self)
    GC:DisbandComposerGroup()
end
function ____exports.rebuildOrRepair(self)
    GC:FindRoster()
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
    ____exports.requestActivities(
        nil,
        ____exports.config(nil).mode == "RAID" and "RAID" or "DUNGEON"
    )
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
function ____exports.listCustomProfiles(self, mode)
    return ProfileFns.ListCustom(mode) or ({})
end
function ____exports.profileDescription(self, name)
    return ProfileFns.Describe(name) or ""
end
function ____exports.profileMeta(self, name)
    return ProfileFns.Get(name)
end
function ____exports.isFavorite(self, mode, id)
    return ProfileFns.IsFavorite(mode, id) == true
end
function ____exports.toggleFavorite(self, mode, id)
    local value = ProfileFns.ToggleFavorite(mode, id) == true
    GC:Fire("ACTIVITY_HISTORY_CHANGED")
    return value
end
function ____exports.recentActivityIds(self, mode, limit)
    if limit == nil then
        limit = 6
    end
    local out = {}
    for ____, entry in ipairs(ProfileFns.ListRecent(mode, limit) or ({})) do
        if entry ~= nil and entry.id ~= nil then
            out[#out + 1] = tostring(entry.id)
        end
    end
    return out
end
function ____exports.addPin(self, name, role, required)
    GC:AddPinnedMember(name, role, required)
end
function ____exports.removePin(self, index)
    GC:RemovePinnedMember(index)
end
function ____exports.planMembers(self)
    local ____exports_plan_result_members_137 = ____exports.plan(nil).members
    if ____exports_plan_result_members_137 == nil then
        ____exports_plan_result_members_137 = {}
    end
    return ____exports_plan_result_members_137
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
        return "Ready for review"
    end
    if phase == "ASSEMBLING" then
        return "Assembling"
    end
    if phase == "ASSEMBLED" then
        return "Group assembled"
    end
    if phase == "TRAVEL" then
        return "Teleporting to instance"
    end
    if phase == "DONE" then
        return "Group ready"
    end
    if phase == "ERROR" then
        return "Needs attention"
    end
    return "Ready to configure"
end
function ____exports.isBusy(self)
    local ____exports_progress_result_phase_138 = ____exports.progress(nil).phase
    if ____exports_progress_result_phase_138 == nil then
        ____exports_progress_result_phase_138 = "IDLE"
    end
    local phase = tostring(____exports_progress_result_phase_138)
    return phase == "BUILDING" or phase == "PREPARING" or phase == "ASSEMBLING" or phase == "TRAVEL"
end
function ____exports.isAssembled(self)
    local ____exports_progress_result_phase_139 = ____exports.progress(nil).phase
    if ____exports_progress_result_phase_139 == nil then
        ____exports_progress_result_phase_139 = ""
    end
    local phase = tostring(____exports_progress_result_phase_139)
    return phase == "ASSEMBLED" or phase == "DONE"
end
function ____exports.hasFixedActivityDestination(self)
    local cfg = ____exports.config(nil)
    return not (cfg.mode == "DUNGEON" and cfg.activity == "random")
end
return ____exports
 end,
["widgets.Modal"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____Native = require("core.Native")
local createFramedIcon = ____Native.createFramedIcon
local createPanel = ____Native.createPanel
local createSolid = ____Native.createSolid
local createText = ____Native.createText
local setRoleIcon = ____Native.setRoleIcon
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
    local panel = createPanel(nil, parent, theme.colors.background, theme.colors.chrome)
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
        2,
        -2
    )
    headerBg:SetPoint(
        "TOPRIGHT",
        panel.frame,
        "TOPRIGHT",
        -2,
        -2
    )
    headerBg:SetHeight(64)
    local headerDivider = createSolid(nil, panel.frame, theme.colors.borderStrong, "ARTWORK")
    headerDivider:SetPoint(
        "TOPLEFT",
        panel.frame,
        "TOPLEFT",
        2,
        -66
    )
    headerDivider:SetPoint(
        "TOPRIGHT",
        panel.frame,
        "TOPRIGHT",
        -2,
        -66
    )
    headerDivider:SetHeight(1)
    local headerIcon = createFramedIcon(
        nil,
        panel.frame,
        "Interface\\Icons\\INV_Misc_QuestionMark",
        44,
        theme.colors.borderStrong
    )
    headerIcon.frame:SetPoint(
        "TOPLEFT",
        panel.frame,
        "TOPLEFT",
        16,
        -11
    )
    headerIcon.frame:Hide()
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
    subtitle:SetWidth(width - 150)
    local close = createButton(
        nil,
        panel.frame,
        {
            text = "X",
            width = 34,
            height = 34,
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
        -78
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
    local function resetTitleAnchor(self, withIcon)
        title:ClearAllPoints()
        title:SetPoint(
            "TOPLEFT",
            panel.frame,
            "TOPLEFT",
            withIcon and 72 or theme.spacing.lg,
            -12
        )
    end
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
        end,
        setHeaderIcon = function(self, path)
            if path == nil or path == "" then
                headerIcon.frame:Hide()
                resetTitleAnchor(nil, false)
                return
            end
            headerIcon.icon:SetTexture(path)
            headerIcon.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            headerIcon.frame:Show()
            resetTitleAnchor(nil, true)
        end,
        setHeaderRole = function(self, role)
            if role == nil or role == "" then
                headerIcon.frame:Hide()
                resetTitleAnchor(nil, false)
                return
            end
            setRoleIcon(nil, headerIcon.icon, role)
            headerIcon.frame:Show()
            resetTitleAnchor(nil, true)
        end
    }
end
return ____exports
 end,
["widgets.Stepper"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____Native = require("core.Native")
local createPanel = ____Native.createPanel
local createText = ____Native.createText
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
local ____Button = require("widgets.Button")
local createButton = ____Button.createButton
function ____exports.createNumberStepper(self, parent, initialMin, initialMax, initial, onChange)
    local update, min, max, value, minus, valueText, plus
    function update(self, next, notify)
        if notify == nil then
            notify = true
        end
        value = math.max(
            min,
            math.min(max, next)
        )
        valueText:SetText(tostring(value))
        minus:setEnabled(value > min)
        plus:setEnabled(value < max)
        if notify and onChange ~= nil then
            onChange(nil, value)
        end
    end
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(118, 36)
    min = initialMin
    max = initialMax
    value = initial
    minus = createButton(
        nil,
        frame,
        {
            text = "-",
            width = 32,
            height = 36,
            accent = theme.colors.primary,
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
    local center = createPanel(nil, frame, theme.colors.surfaceDeep, theme.colors.borderStrong)
    center.frame:SetPoint(
        "LEFT",
        minus.frame,
        "RIGHT",
        4,
        0
    )
    center.frame:SetSize(42, 36)
    valueText = createText(
        nil,
        center.frame,
        tostring(value),
        "GameFontNormalLarge",
        theme.colors.text
    )
    valueText:SetPoint(
        "CENTER",
        center.frame,
        "CENTER",
        0,
        0
    )
    valueText:SetJustifyH("CENTER")
    plus = createButton(
        nil,
        frame,
        {
            text = "+",
            width = 32,
            height = 36,
            accent = theme.colors.primary,
            onClick = function() return update(nil, value + 1) end
        }
    )
    plus.frame:SetPoint(
        "LEFT",
        center.frame,
        "RIGHT",
        4,
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
local createFramedIcon = ____Native.createFramedIcon
local createFramedRoleIcon = ____Native.createFramedRoleIcon
local createIcon = ____Native.createIcon
local createPanel = ____Native.createPanel
local createSolid = ____Native.createSolid
local createText = ____Native.createText
local setClassIcon = ____Native.setClassIcon
local setRoleIcon = ____Native.setRoleIcon
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
local function specSummary(self, classId, role)
    local labels = {}
    for ____, spec in ipairs(getSpecsForRole(classId, role)) do
        labels[#labels + 1] = spec.label
    end
    return table.concat(labels, "  ·  ")
end
local function classRoleSummary(self, classId, role)
    if role == "TANK" then
        return "Tank"
    end
    if role == "HEALER" then
        return "Healer"
    end
    if classId == "HUNTER" or classId == "MAGE" or classId == "WARLOCK" or classId == "PRIEST" then
        return "Ranged DPS"
    end
    if classId == "SHAMAN" or classId == "DRUID" then
        return "Melee / Ranged"
    end
    return "Melee DPS"
end
local SELECTOR_CLASS_ORDER = {
    "DEATHKNIGHT",
    "WARRIOR",
    "PALADIN",
    "HUNTER",
    "ROGUE",
    "SHAMAN",
    "MAGE",
    "WARLOCK",
    "DRUID",
    "PRIEST"
}
local function selectorClassesForRole(self, role, compatible)
    local valid = compatible or getClassesForRole(role)
    local result = {}
    for ____, classId in ipairs(SELECTOR_CLASS_ORDER) do
        for ____, classDef in ipairs(valid) do
            if classDef.id == classId then
                result[#result + 1] = classDef
                break
            end
        end
    end
    return result
end
local function createRadioMarker(self, parent)
    local marker = parent:CreateTexture(nil, "OVERLAY")
    marker:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    marker:SetSize(22, 22)
    marker:SetPoint(
        "BOTTOMRIGHT",
        parent,
        "BOTTOMRIGHT",
        -8,
        7
    )
    marker:SetVertexColor(theme.colors.primary[1], theme.colors.primary[2], theme.colors.primary[3], 1)
    marker:Hide()
    return marker
end
local function setRadioSelected(self, marker, selected)
    if selected then
        marker:Show()
    else
        marker:Hide()
    end
end
function ____exports.createBuildSelector(self, parent, options)
    local refresh, modal, currentRole, currentClass, currentSpec, classSection, classStepBadge, classStep, classHint, classTiles, specSection, specStepBadge, specStep, specHint, anySpecButton, anySpecMarker, specTiles, summaryClassBadge, summaryClassText, summarySpecBadge, summarySpecText, summaryRoleBadge, summaryRoleText, apply
    function refresh(self)
        local accent = roleAccent(nil, currentRole)
        modal:setTitle(("Add " .. roleLabel(nil, currentRole)) .. " Build")
        modal:setSubtitle("Reserve only the class/spec you care about. Every unreserved slot stays Auto.")
        modal:setHeaderRole(currentRole)
        classSection.outline:setColor(theme.colors.borderStrong)
        specSection.outline:setColor(theme.colors.borderStrong)
        classStepBadge.outline:setColor(accent)
        specStepBadge.outline:setColor(accent)
        classStep:SetTextColor(accent[1], accent[2], accent[3], 1)
        specStep:SetTextColor(accent[1], accent[2], accent[3], 1)
        classHint:SetText(("Select a class that can fulfill the " .. roleLabel(nil, currentRole)) .. " role.")
        setRoleIcon(nil, summaryRoleBadge.icon, currentRole)
        summaryRoleBadge.outline:setColor(accent)
        summaryRoleText:SetText(roleLabel(nil, currentRole))
        summaryRoleText:SetTextColor(accent[1], accent[2], accent[3], 1)
        local validClasses = selectorClassesForRole(
            nil,
            currentRole,
            getClassesForRole(currentRole)
        )
        local columns = math.min(
            5,
            math.max(1, #validClasses)
        )
        local classRows = math.max(
            1,
            math.ceil(#validClasses / columns)
        )
        local classHeight = classRows > 1 and 258 or 164
        local specHeight = currentClass == nil and 68 or 176
        classSection.frame:SetHeight(classHeight)
        specSection.frame:SetHeight(specHeight)
        modal.frame:SetHeight(classHeight + specHeight + 222)
        local tileWidth = 174
        local gap = 10
        local totalWidth = columns * tileWidth + (columns - 1) * gap
        local startX = math.floor((1008 - totalWidth) / 2)
        local classIndex = 0
        for ____, tile in ipairs(classTiles) do
            do
                local __continue41
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
                        __continue41 = true
                        break
                    end
                    local column = classIndex % columns
                    local row = math.floor(classIndex / columns)
                    tile.button.frame:ClearAllPoints()
                    tile.button.frame:SetPoint(
                        "TOPLEFT",
                        classSection.frame,
                        "TOPLEFT",
                        startX + column * (tileWidth + gap),
                        -(62 + row * 94)
                    )
                    tile.sub:SetText(classRoleSummary(nil, tile.classDef.id, currentRole))
                    tile.specs:SetText(specSummary(nil, tile.classDef.id, currentRole))
                    tile.button:setSelected(tile.classDef.id == currentClass)
                    tile.button.frame:Show()
                    classIndex = classIndex + 1
                    __continue41 = true
                until true
                if not __continue41 then
                    break
                end
            end
        end
        if currentClass == nil then
            anySpecButton.frame:Hide()
            for ____, tile in ipairs(specTiles) do
                tile.button.frame:Hide()
            end
            specHint:SetText("Select a class above to unlock specializations.")
        else
            local selectedClass = getClass(currentClass)
            specHint:SetText(("Pick an exact " .. (selectedClass and selectedClass.label or "class")) .. " specialization, or leave the spec flexible.")
            local visibleSpecs = getSpecsForRole(currentClass, currentRole)
            local totalCards = #visibleSpecs + 1
            local cardWidth = 208
            local cardGap = 12
            local cardsWidth = totalCards * cardWidth + (totalCards - 1) * cardGap
            local specStartX = math.floor((1008 - cardsWidth) / 2)
            local specIndex = 0
            for ____, tile in ipairs(specTiles) do
                local visible = false
                if tile.classId == currentClass then
                    for ____, validSpec in ipairs(visibleSpecs) do
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
                        specStartX + specIndex * (cardWidth + cardGap),
                        -70
                    )
                    tile.sub:SetText(tile.classLabel)
                    local selected = tile.spec.id == currentSpec
                    tile.button:setSelected(selected)
                    setRadioSelected(nil, tile.marker, selected)
                    tile.button.frame:Show()
                    specIndex = specIndex + 1
                else
                    tile.button.frame:Hide()
                end
            end
            anySpecButton.frame:ClearAllPoints()
            anySpecButton.frame:SetPoint(
                "TOPLEFT",
                specSection.frame,
                "TOPLEFT",
                specStartX + specIndex * (cardWidth + cardGap),
                -70
            )
            local anySelected = currentSpec == ANY_SPEC_ID
            anySpecButton:setSelected(anySelected)
            setRadioSelected(nil, anySpecMarker, anySelected)
            anySpecButton.frame:Show()
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
            setClassIcon(nil, summaryClassBadge.icon, selectedClass.id)
            summaryClassBadge.outline:setColor(classColor(nil, selectedClass.id))
            summaryClassText:SetText(selectedClass.label)
        else
            summaryClassBadge.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            summaryClassBadge.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            summaryClassBadge.outline:setColor(theme.colors.borderStrong)
            summaryClassText:SetText("Choose class")
        end
        if selectedClass ~= nil and currentSpec == ANY_SPEC_ID then
            summarySpecBadge.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            summarySpecBadge.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            summarySpecBadge.outline:setColor(theme.colors.primary)
            summarySpecText:SetText("Any valid spec")
            apply:setEnabled(true)
        elseif selectedClass ~= nil and selectedSpec ~= nil then
            summarySpecBadge.icon:SetTexture(selectedSpec.icon)
            summarySpecBadge.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            summarySpecBadge.outline:setColor(theme.colors.primary)
            summarySpecText:SetText(selectedSpec.label)
            apply:setEnabled(true)
        else
            summarySpecBadge.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            summarySpecBadge.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            summarySpecBadge.outline:setColor(theme.colors.borderStrong)
            summarySpecText:SetText("Choose spec")
            apply:setEnabled(false)
        end
    end
    modal = createModal(nil, parent, 1040, 680)
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
    classSection.frame:SetHeight(258)
    classStepBadge = createPanel(nil, classSection.frame, theme.colors.surfaceBlue, theme.colors.primary)
    classStepBadge.frame:SetSize(32, 32)
    classStepBadge.frame:SetPoint(
        "TOPLEFT",
        classSection.frame,
        "TOPLEFT",
        14,
        -12
    )
    classStep = createText(
        nil,
        classStepBadge.frame,
        "1",
        "GameFontNormalLarge",
        theme.colors.primary
    )
    classStep:SetPoint(
        "CENTER",
        classStepBadge.frame,
        "CENTER",
        0,
        0
    )
    classStep:SetWidth(24)
    classStep:SetJustifyH("CENTER")
    local classTitle = createText(nil, classSection.frame, "Choose a class", "GameFontNormalLarge")
    classTitle:SetPoint(
        "TOPLEFT",
        classSection.frame,
        "TOPLEFT",
        58,
        -12
    )
    classHint = createText(
        nil,
        classSection.frame,
        "Select a class that can fulfill this role.",
        "GameFontHighlightSmall",
        theme.colors.muted
    )
    classHint:SetPoint(
        "TOPLEFT",
        classTitle,
        "BOTTOMLEFT",
        0,
        -3
    )
    classTiles = {}
    for ____, classDef in ipairs(selectorClassesForRole(nil, "DPS")) do
        local button = createButton(
            nil,
            classSection.frame,
            {
                text = classDef.label,
                width = 174,
                height = 86,
                accent = classColor(nil, classDef.id)
            }
        )
        local accent = createSolid(
            nil,
            button.frame,
            classColor(nil, classDef.id),
            "ARTWORK"
        )
        accent:SetHeight(3)
        accent:SetPoint(
            "TOPLEFT",
            button.frame,
            "TOPLEFT",
            0,
            0
        )
        accent:SetPoint(
            "TOPRIGHT",
            button.frame,
            "TOPRIGHT",
            0,
            0
        )
        local iconFrame = createFramedIcon(
            nil,
            button.frame,
            "Interface\\Icons\\INV_Misc_QuestionMark",
            42,
            classColor(nil, classDef.id)
        )
        iconFrame.frame:SetPoint(
            "LEFT",
            button.frame,
            "LEFT",
            10,
            0
        )
        local icon = iconFrame.icon
        setClassIcon(nil, icon, classDef.id)
        button.label:ClearAllPoints()
        button.label:SetPoint(
            "TOPLEFT",
            button.frame,
            "TOPLEFT",
            62,
            -15
        )
        button.label:SetPoint(
            "RIGHT",
            button.frame,
            "RIGHT",
            -8,
            10
        )
        button.label:SetJustifyH("LEFT")
        local sub = createText(
            nil,
            button.frame,
            "",
            "GameFontHighlightSmall",
            theme.colors.muted
        )
        sub:SetPoint(
            "TOPLEFT",
            button.frame,
            "TOPLEFT",
            62,
            -36
        )
        sub:SetWidth(104)
        local specs = createText(
            nil,
            button.frame,
            "",
            "GameFontHighlightSmall",
            theme.colors.muted
        )
        specs:SetPoint(
            "TOPLEFT",
            button.frame,
            "TOPLEFT",
            62,
            -54
        )
        specs:SetWidth(104)
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
        classTiles[#classTiles + 1] = {
            classDef = classDef,
            button = button,
            icon = icon,
            sub = sub,
            specs = specs
        }
    end
    specSection = createPanel(nil, modal.content, theme.colors.surface, theme.colors.border)
    specSection.frame:SetPoint(
        "TOPLEFT",
        classSection.frame,
        "BOTTOMLEFT",
        0,
        -12
    )
    specSection.frame:SetPoint(
        "TOPRIGHT",
        classSection.frame,
        "BOTTOMRIGHT",
        0,
        -12
    )
    specSection.frame:SetHeight(176)
    specStepBadge = createPanel(nil, specSection.frame, theme.colors.surfaceBlue, theme.colors.primary)
    specStepBadge.frame:SetSize(32, 32)
    specStepBadge.frame:SetPoint(
        "TOPLEFT",
        specSection.frame,
        "TOPLEFT",
        14,
        -12
    )
    specStep = createText(
        nil,
        specStepBadge.frame,
        "2",
        "GameFontNormalLarge",
        theme.colors.primary
    )
    specStep:SetPoint(
        "CENTER",
        specStepBadge.frame,
        "CENTER",
        0,
        0
    )
    specStep:SetWidth(24)
    specStep:SetJustifyH("CENTER")
    local specTitle = createText(nil, specSection.frame, "Choose a specialization", "GameFontNormalLarge")
    specTitle:SetPoint(
        "TOPLEFT",
        specSection.frame,
        "TOPLEFT",
        58,
        -12
    )
    specHint = createText(
        nil,
        specSection.frame,
        "Select a class above to unlock specializations.",
        "GameFontHighlightSmall",
        theme.colors.muted
    )
    specHint:SetPoint(
        "TOPLEFT",
        specTitle,
        "BOTTOMLEFT",
        0,
        -3
    )
    anySpecButton = createButton(
        nil,
        specSection.frame,
        {
            text = "Any valid spec",
            width = 208,
            height = 76,
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
    local anySpecIcon = createIcon(nil, anySpecButton.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 40)
    anySpecIcon:SetPoint(
        "LEFT",
        anySpecButton.frame,
        "LEFT",
        10,
        0
    )
    anySpecButton.label:ClearAllPoints()
    anySpecButton.label:SetPoint(
        "TOPLEFT",
        anySpecButton.frame,
        "TOPLEFT",
        60,
        -17
    )
    anySpecButton.label:SetPoint(
        "RIGHT",
        anySpecButton.frame,
        "RIGHT",
        -8,
        8
    )
    anySpecButton.label:SetJustifyH("LEFT")
    local anySpecSub = createText(
        nil,
        anySpecButton.frame,
        "Composer chooses",
        "GameFontHighlightSmall",
        theme.colors.muted
    )
    anySpecSub:SetPoint(
        "TOPLEFT",
        anySpecButton.frame,
        "TOPLEFT",
        60,
        -40
    )
    anySpecSub:SetWidth(130)
    anySpecMarker = createRadioMarker(nil, anySpecButton.frame)
    anySpecButton.frame:Hide()
    specTiles = {}
    for ____, classDef in ipairs(selectorClassesForRole(nil, "DPS")) do
        for ____, spec in ipairs(classDef.specs) do
            local button = createButton(nil, specSection.frame, {text = spec.label, width = 208, height = 76, accent = theme.colors.primary})
            local icon = createIcon(nil, button.frame, spec.icon, 40)
            icon:SetPoint(
                "LEFT",
                button.frame,
                "LEFT",
                10,
                0
            )
            button.label:ClearAllPoints()
            button.label:SetPoint(
                "TOPLEFT",
                button.frame,
                "TOPLEFT",
                60,
                -17
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
                classDef.label,
                "GameFontHighlightSmall",
                theme.colors.muted
            )
            sub:SetPoint(
                "TOPLEFT",
                button.frame,
                "TOPLEFT",
                60,
                -40
            )
            sub:SetWidth(130)
            local marker = createRadioMarker(nil, button.frame)
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
                sub = sub,
                marker = marker
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
        "BUILD SUMMARY",
        "GameFontNormalSmall",
        theme.colors.muted
    )
    selectedLabel:SetPoint(
        "TOPLEFT",
        summary.frame,
        "TOPLEFT",
        12,
        -8
    )
    summaryClassBadge = createFramedIcon(
        nil,
        summary.frame,
        "Interface\\Icons\\INV_Misc_QuestionMark",
        40,
        theme.colors.borderStrong
    )
    summaryClassBadge.frame:SetPoint(
        "BOTTOMLEFT",
        summary.frame,
        "BOTTOMLEFT",
        12,
        12
    )
    summaryClassText = createText(nil, summary.frame, "Choose class", "GameFontNormal")
    summaryClassText:SetPoint(
        "TOPLEFT",
        summary.frame,
        "TOPLEFT",
        62,
        -43
    )
    summaryClassText:SetWidth(108)
    local summaryClassSub = createText(
        nil,
        summary.frame,
        "Class",
        "GameFontHighlightSmall",
        theme.colors.muted
    )
    summaryClassSub:SetPoint(
        "TOPLEFT",
        summaryClassText,
        "BOTTOMLEFT",
        0,
        -3
    )
    summarySpecBadge = createFramedIcon(
        nil,
        summary.frame,
        "Interface\\Icons\\INV_Misc_QuestionMark",
        40,
        theme.colors.borderStrong
    )
    summarySpecBadge.frame:SetPoint(
        "BOTTOMLEFT",
        summary.frame,
        "BOTTOMLEFT",
        184,
        12
    )
    summarySpecText = createText(nil, summary.frame, "Choose spec", "GameFontNormal")
    summarySpecText:SetPoint(
        "TOPLEFT",
        summary.frame,
        "TOPLEFT",
        234,
        -43
    )
    summarySpecText:SetWidth(116)
    local summarySpecSub = createText(
        nil,
        summary.frame,
        "Specialization",
        "GameFontHighlightSmall",
        theme.colors.muted
    )
    summarySpecSub:SetPoint(
        "TOPLEFT",
        summarySpecText,
        "BOTTOMLEFT",
        0,
        -3
    )
    summaryRoleBadge = createFramedRoleIcon(
        nil,
        summary.frame,
        "DPS",
        40,
        theme.colors.dps
    )
    summaryRoleBadge.frame:SetPoint(
        "BOTTOMLEFT",
        summary.frame,
        "BOTTOMLEFT",
        370,
        12
    )
    summaryRoleText = createText(nil, summary.frame, "DPS", "GameFontNormal")
    summaryRoleText:SetPoint(
        "TOPLEFT",
        summary.frame,
        "TOPLEFT",
        420,
        -43
    )
    summaryRoleText:SetWidth(78)
    local summaryRoleSub = createText(
        nil,
        summary.frame,
        "Role",
        "GameFontHighlightSmall",
        theme.colors.muted
    )
    summaryRoleSub:SetPoint(
        "TOPLEFT",
        summaryRoleText,
        "BOTTOMLEFT",
        0,
        -3
    )
    local countLabel = createText(
        nil,
        summary.frame,
        "COUNT",
        "GameFontNormalSmall",
        theme.colors.muted
    )
    countLabel:SetPoint(
        "TOPLEFT",
        summary.frame,
        "TOPLEFT",
        518,
        -36
    )
    local countStepper = createNumberStepper(
        nil,
        summary.frame,
        1,
        options.maxCount or 40,
        1
    )
    countStepper.frame:SetPoint(
        "LEFT",
        summary.frame,
        "LEFT",
        566,
        -8
    )
    apply = createButton(
        nil,
        summary.frame,
        {
            text = "Use this build",
            width = 176,
            height = 42,
            emphasis = true,
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
        "BOTTOMRIGHT",
        summary.frame,
        "BOTTOMRIGHT",
        -12,
        12
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
local createSolid = ____Native.createSolid
local withAlpha = ____Native.withAlpha
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
            rail:Hide()
            return
        end
        rail:Show()
        offset = clamp(nil, offset)
        scroll:SetVerticalScroll(offset)
        local trackHeight = math.max(28, height - 42)
        local thumbHeight = math.max(
            22,
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
            -(3 + travel * ratio)
        )
        up:setEnabled(offset > 0)
        down:setEnabled(offset < range)
    end
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(width, height)
    frame:EnableMouseWheel(true)
    local railWidth = 14
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
        -railWidth - 2,
        0
    )
    scroll:SetSize(
        math.max(1, width - railWidth - 2),
        height
    )
    scroll:EnableMouseWheel(true)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(math.max(1, width - railWidth - 2))
    content:SetHeight(height)
    content:EnableMouseWheel(true)
    scroll:SetScrollChild(content)
    rail = CreateFrame("Frame", nil, frame)
    rail:SetPoint(
        "TOPRIGHT",
        frame,
        "TOPRIGHT",
        0,
        0
    )
    rail:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        0,
        0
    )
    rail:SetWidth(railWidth)
    rail:EnableMouseWheel(true)
    local railBg = createSolid(
        nil,
        rail,
        withAlpha(nil, theme.colors.surfaceDeep, 0.72)
    )
    railBg:SetAllPoints(rail)
    contentHeight = height
    offset = 0
    local function scrollBy(self, delta)
        offset = clamp(nil, offset + delta)
        scroll:SetVerticalScroll(offset)
        refreshRail(nil)
    end
    local function wheel(_target, delta)
        scrollBy(
            nil,
            __TS__Number(delta) > 0 and -64 or 64
        )
    end
    local function bindWheel(self, target)
        target:EnableMouseWheel(true)
        target:SetScript("OnMouseWheel", wheel)
    end
    up = createButton(
        nil,
        rail,
        {
            text = "^",
            width = railWidth,
            height = 18,
            accent = theme.colors.primary,
            onClick = function() return scrollBy(nil, -64) end
        }
    )
    up.frame:SetPoint(
        "TOP",
        rail,
        "TOP",
        0,
        0
    )
    down = createButton(
        nil,
        rail,
        {
            text = "v",
            width = railWidth,
            height = 18,
            accent = theme.colors.primary,
            onClick = function() return scrollBy(nil, 64) end
        }
    )
    down.frame:SetPoint(
        "BOTTOM",
        rail,
        "BOTTOM",
        0,
        0
    )
    local track = createSolid(nil, rail, theme.colors.borderStrong, "ARTWORK")
    track:SetPoint(
        "TOP",
        up.frame,
        "BOTTOM",
        0,
        -3
    )
    track:SetPoint(
        "BOTTOM",
        down.frame,
        "TOP",
        0,
        3
    )
    track:SetWidth(2)
    thumb = createSolid(nil, rail, theme.colors.primary, "OVERLAY")
    thumb:SetWidth(5)
    thumb:SetHeight(24)
    bindWheel(nil, frame)
    bindWheel(nil, scroll)
    bindWheel(nil, content)
    bindWheel(nil, rail)
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
["components.UnlockRequirementsModal"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local Model = require("model.ComposerModel")
local Native = require("core.Native")
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
local ModalUI = require("widgets.Modal")
local ScrollUI = require("widgets.ScrollList")
function ____exports.createUnlockRequirementsModal(self, parent)
    local modal = ModalUI:createModal(parent, 760, 620)
    modal:setHeaderIcon("Interface\\Icons\\INV_Misc_Key_04")
    modal:setTitle("Unlock Requirements")
    modal:setSubtitle("Exact server-side requirements for this activity.")
    local stateText = Native:createText(modal.content, "Checking requirements...", "GameFontNormal", theme.colors.warning)
    stateText:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        8,
        -4
    )
    stateText:SetWidth(650)
    local summary = Native:createText(modal.content, "", "GameFontHighlightSmall", theme.colors.muted)
    summary:SetPoint(
        "TOPLEFT",
        stateText,
        "BOTTOMLEFT",
        0,
        -6
    )
    summary:SetWidth(650)
    summary:SetHeight(42)
    summary:SetJustifyV("TOP")
    local scroll = ScrollUI:createScrollList(modal.content, 684, 430)
    scroll.frame:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        0,
        -88
    )
    local rows = {}
    local empty = Native:createText(scroll.content, "Waiting for the server...", "GameFontHighlight", theme.colors.muted)
    empty:SetPoint(
        "TOPLEFT",
        scroll.content,
        "TOPLEFT",
        20,
        -26
    )
    empty:SetWidth(640)
    empty:SetJustifyH("CENTER")
    local function refresh(self)
        local details = Model:unlockDetails()
        local color = details.available and theme.colors.success or theme.colors.warning
        stateText:SetText(details.ready and (details.available and "UNLOCKED · All requirements satisfied" or "LOCKED · Requirements remain") or "Checking requirements...")
        stateText:SetTextColor(color[1], color[2], color[3], 1)
        summary:SetText(details.summary)
        for ____, row in ipairs(rows) do
            row.panel.frame:Hide()
        end
        local requirements = details.requirements
        if #requirements == 0 then
            empty:Show()
        else
            empty:Hide()
        end
        do
            local i = 0
            while i < #requirements do
                local row = rows[i + 1]
                if row == nil then
                    local panel = Native:createPanel(scroll.content, theme.colors.surfaceRaised, theme.colors.border)
                    panel.frame:SetSize(650, 82)
                    local icon = Native:createText(panel.frame, "", "GameFontNormalLarge")
                    icon:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        14,
                        -13
                    )
                    icon:SetWidth(30)
                    local title = Native:createText(panel.frame, "", "GameFontNormal")
                    title:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        52,
                        -11
                    )
                    title:SetWidth(390)
                    local ____type = Native:createText(panel.frame, "", "GameFontNormalSmall", theme.colors.muted)
                    ____type:SetPoint(
                        "TOPRIGHT",
                        panel.frame,
                        "TOPRIGHT",
                        -14,
                        -13
                    )
                    ____type:SetWidth(150)
                    ____type:SetJustifyH("RIGHT")
                    local detail = Native:createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted)
                    detail:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        52,
                        -37
                    )
                    detail:SetWidth(570)
                    detail:SetHeight(34)
                    detail:SetJustifyV("TOP")
                    scroll:bindWheel(panel.frame)
                    row = {
                        panel = panel,
                        icon = icon,
                        title = title,
                        type = ____type,
                        detail = detail
                    }
                    rows[i + 1] = row
                end
                local req = requirements[i + 1]
                local pass = req.status == "PASS"
                local accent = pass and theme.colors.success or theme.colors.warning
                row.panel.frame:ClearAllPoints()
                row.panel.frame:SetPoint(
                    "TOPLEFT",
                    scroll.content,
                    "TOPLEFT",
                    0,
                    -(i * 90)
                )
                row.icon:SetText(pass and "✓" or "!")
                row.icon:SetTextColor(accent[1], accent[2], accent[3], 1)
                row.title:SetText(req.title)
                row.type:SetText((req.type .. " · ") .. req.status)
                row.type:SetTextColor(accent[1], accent[2], accent[3], 1)
                row.detail:SetText(req.detail)
                row.panel.frame:Show()
                i = i + 1
            end
        end
        scroll:setContentHeight(math.max(430, #requirements * 90))
    end
    Model:composer():RegisterCallback(
        "UNLOCK_DETAILS_CHANGED",
        function()
            if modal.frame:IsShown() then
                refresh(nil)
            end
        end
    )
    return {open = function(____, id, label, mode)
        modal:setTitle(label)
        modal:setSubtitle("Exact unlock path · " .. (mode == "RAID" and "Raid" or "Dungeon"))
        scroll:scrollToTop()
        modal:show()
        Model:requestUnlockDetails(id, mode)
        refresh(nil)
    end}
end
return ____exports
 end,
["components.ActivityBrowser"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__ArraySort(self, compareFn)
    if compareFn ~= nil then
        table.sort(
            self,
            function(a, b) return compareFn(nil, a, b) < 0 end
        )
    else
        table.sort(self)
    end
    return self
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
local Model = require("model.ComposerModel")
local Native = require("core.Native")
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
local ButtonUI = require("widgets.Button")
local ModalUI = require("widgets.Modal")
local ScrollUI = require("widgets.ScrollList")
local UnlockRequirementsUI = require("components.UnlockRequirementsModal")
function ____exports.createActivityBrowser(self, parent)
    local D = Model:data()
    local modal = ModalUI:createModal(parent, 960, 650)
    modal:setHeaderIcon("Interface\\Icons\\INV_Misc_Map_01")
    local unlockModal = UnlockRequirementsUI:createUnlockRequirementsModal(parent)
    local filterButtons = {}
    do
        local i = 0
        while i < 5 do
            local button = ButtonUI:createButton(modal.content, {
                text = "",
                width = 132,
                height = 34,
                accent = theme.colors.primary,
                flat = true
            })
            button.frame:SetPoint(
                "TOPLEFT",
                modal.content,
                "TOPLEFT",
                i * 140,
                0
            )
            filterButtons[#filterButtons + 1] = button
            i = i + 1
        end
    end
    local scroll = ScrollUI:createScrollList(modal.content, 884, 470)
    scroll.frame:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        0,
        -48
    )
    local cards = {}
    local empty = Native:createText(scroll.content, "No activities match this filter.", "GameFontHighlight", theme.colors.muted)
    empty:SetPoint(
        "TOPLEFT",
        scroll.content,
        "TOPLEFT",
        20,
        -30
    )
    empty:SetWidth(820)
    empty:SetJustifyH("CENTER")
    empty:Hide()
    local filter = "Vanilla"
    local function mode(self)
        return Model:config().mode == "RAID" and "RAID" or "DUNGEON"
    end
    local function currentEra(self)
        return Model:realm().era
    end
    local function difficultyDetail(self, era, minLevel)
        if era == "Vanilla" then
            return ("Normal · Level " .. tostring(minLevel)) .. "+"
        end
        if era == "TBC" then
            return ("Normal / Heroic · Level " .. tostring(minLevel)) .. "+"
        end
        return ("Normal / Heroic / Titan Rune · Level " .. tostring(minLevel)) .. "+"
    end
    local function entries(self)
        local out = {}
        local selectedMode = mode(nil)
        local serverEntries = Model:activityMetaList(selectedMode)
        if #serverEntries > 0 then
            local recentOrder = {}
            if filter == "RECENT" then
                local recent = Model:recentActivityIds(selectedMode, 8)
                do
                    local i = 0
                    while i < #recent do
                        recentOrder[recent[i + 1]] = i + 1
                        i = i + 1
                    end
                end
            end
            for ____, entry in ipairs(serverEntries) do
                do
                    local __continue15
                    repeat
                        if filter == "FAVORITES" and not Model:isFavorite(selectedMode, entry.id) then
                            __continue15 = true
                            break
                        end
                        if filter == "RECENT" and recentOrder[entry.id] == nil then
                            __continue15 = true
                            break
                        end
                        if filter ~= "FAVORITES" and filter ~= "RECENT" and entry.era ~= filter then
                            __continue15 = true
                            break
                        end
                        out[#out + 1] = {
                            id = entry.id,
                            label = entry.label,
                            detail = mode(nil) == "RAID" and ((tostring(entry.size) .. " player · Level ") .. tostring(entry.minLevel)) .. "+" or difficultyDetail(nil, entry.era, entry.minLevel),
                            icon = Model:activityIconFor(
                                entry.id,
                                mode(nil)
                            ),
                            era = entry.era,
                            minLevel = entry.minLevel,
                            support = entry.support
                        }
                        __continue15 = true
                    until true
                    if not __continue15 then
                        break
                    end
                end
            end
            if filter == "RECENT" then
                __TS__ArraySort(
                    out,
                    function(____, left, right) return (recentOrder[left.id] or 999) - (recentOrder[right.id] or 999) end
                )
            end
            return out
        end
        if mode(nil) == "DUNGEON" then
            local ____D_DUNGEONS_3 = D.DUNGEONS
            if ____D_DUNGEONS_3 == nil then
                ____D_DUNGEONS_3 = {}
            end
            for ____, dungeon in __TS__Iterator(____D_DUNGEONS_3) do
                do
                    local __continue23
                    repeat
                        local ____temp_1
                        if dungeon.id == "random" then
                            ____temp_1 = currentEra(nil)
                        else
                            local ____dungeon_era_0 = dungeon.era
                            if ____dungeon_era_0 == nil then
                                ____dungeon_era_0 = "WotLK"
                            end
                            ____temp_1 = tostring(____dungeon_era_0)
                        end
                        local era = ____temp_1
                        if era ~= filter then
                            __continue23 = true
                            break
                        end
                        local ____dungeon_minLevel_2 = dungeon.minLevel
                        if ____dungeon_minLevel_2 == nil then
                            ____dungeon_minLevel_2 = 1
                        end
                        local minLevel = __TS__Number(____dungeon_minLevel_2)
                        out[#out + 1] = {
                            id = tostring(dungeon.id),
                            label = tostring(dungeon.label),
                            detail = difficultyDetail(nil, era, minLevel),
                            icon = Model:activityIconFor(
                                tostring(dungeon.id),
                                "DUNGEON"
                            ),
                            era = era,
                            minLevel = minLevel,
                            support = "Checking support"
                        }
                        __continue23 = true
                    until true
                    if not __continue23 then
                        break
                    end
                end
            end
        else
            local ____D_RAIDS_14 = D.RAIDS
            if ____D_RAIDS_14 == nil then
                ____D_RAIDS_14 = {}
            end
            for ____, raid in __TS__Iterator(____D_RAIDS_14) do
                do
                    local __continue27
                    repeat
                        local ____raid_era_4 = raid.era
                        if ____raid_era_4 == nil then
                            ____raid_era_4 = "WotLK"
                        end
                        local era = tostring(____raid_era_4)
                        if era ~= filter then
                            __continue27 = true
                            break
                        end
                        local sizes = {}
                        local ____raid_sizes_5 = raid.sizes
                        if ____raid_sizes_5 == nil then
                            ____raid_sizes_5 = {}
                        end
                        for ____, size in __TS__Iterator(____raid_sizes_5) do
                            sizes[#sizes + 1] = tostring(size)
                        end
                        local ____tostring_result_9 = tostring(raid.id)
                        local ____tostring_result_10 = tostring(raid.label)
                        local ____temp_7 = table.concat(sizes, "/") .. " player · Level "
                        local ____raid_requiredLevel_6 = raid.requiredLevel
                        if ____raid_requiredLevel_6 == nil then
                            ____raid_requiredLevel_6 = 80
                        end
                        local ____temp_11 = (____temp_7 .. tostring(____raid_requiredLevel_6)) .. "+"
                        local ____temp_12 = Model:activityIconFor(
                            tostring(raid.id),
                            "RAID"
                        )
                        local ____era_13 = era
                        local ____raid_requiredLevel_8 = raid.requiredLevel
                        if ____raid_requiredLevel_8 == nil then
                            ____raid_requiredLevel_8 = 80
                        end
                        out[#out + 1] = {
                            id = ____tostring_result_9,
                            label = ____tostring_result_10,
                            detail = ____temp_11,
                            icon = ____temp_12,
                            era = ____era_13,
                            minLevel = __TS__Number(____raid_requiredLevel_8),
                            support = "Checking support"
                        }
                        __continue27 = true
                    until true
                    if not __continue27 then
                        break
                    end
                end
            end
        end
        return out
    end
    local function tabLabels(self)
        return {
            {key = "Vanilla", label = "Vanilla"},
            {key = "TBC", label = "TBC"},
            {key = "WotLK", label = "WotLK"},
            {key = "FAVORITES", label = "★ Favorites"},
            {key = "RECENT", label = "Recent"}
        }
    end
    local function refresh(self)
        local tabs = tabLabels(nil)
        do
            local i = 0
            while i < #filterButtons do
                local tab = tabs[i + 1]
                local button = filterButtons[i + 1]
                button:setText(tab.label)
                button:setSelected(filter == tab.key)
                local key = tab.key
                button.frame:SetScript(
                    "OnMouseDown",
                    function()
                        filter = key
                        scroll:scrollToTop()
                        refresh(nil)
                    end
                )
                button.frame:Show()
                i = i + 1
            end
        end
        for ____, card in ipairs(cards) do
            card.button.frame:Hide()
        end
        local items = entries(nil)
        if #items == 0 then
            empty:Show()
        else
            empty:Hide()
        end
        do
            local i = 0
            while i < #items do
                local card = cards[i + 1]
                if card == nil then
                    local button = ButtonUI:createButton(scroll.content, {
                        text = "",
                        width = 426,
                        height = 78,
                        accent = theme.colors.primary,
                        flat = true
                    })
                    local iconBadge = Native:createFramedIcon(button.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 42, theme.colors.borderStrong)
                    iconBadge.frame:SetPoint(
                        "LEFT",
                        button.frame,
                        "LEFT",
                        12,
                        0
                    )
                    local title = Native:createText(button.frame, "", "GameFontNormal")
                    title:SetPoint(
                        "TOPLEFT",
                        button.frame,
                        "TOPLEFT",
                        66,
                        -12
                    )
                    title:SetWidth(328)
                    local detail = Native:createText(button.frame, "", "GameFontHighlightSmall", theme.colors.muted)
                    detail:SetPoint(
                        "TOPLEFT",
                        button.frame,
                        "TOPLEFT",
                        66,
                        -35
                    )
                    detail:SetWidth(328)
                    local tag = Native:createText(button.frame, "", "GameFontNormalSmall", theme.colors.primary)
                    tag:SetPoint(
                        "TOPLEFT",
                        button.frame,
                        "TOPLEFT",
                        66,
                        -55
                    )
                    tag:SetWidth(260)
                    local favorite = ButtonUI:createButton(button.frame, {
                        text = "☆",
                        width = 34,
                        height = 30,
                        accent = theme.colors.warning,
                        flat = true
                    })
                    favorite.frame:SetPoint(
                        "TOPRIGHT",
                        button.frame,
                        "TOPRIGHT",
                        -7,
                        -7
                    )
                    scroll:bindWheel(button.frame)
                    scroll:bindWheel(favorite.frame)
                    card = {
                        button = button,
                        favorite = favorite,
                        iconBadge = iconBadge,
                        title = title,
                        detail = detail,
                        tag = tag
                    }
                    cards[i + 1] = card
                end
                local item = items[i + 1]
                local column = i % 2
                local row = math.floor(i / 2)
                card.button.frame:ClearAllPoints()
                card.button.frame:SetPoint(
                    "TOPLEFT",
                    scroll.content,
                    "TOPLEFT",
                    column * 436,
                    -(row * 86)
                )
                local access = Model:activityEligibility(
                    item.id,
                    mode(nil)
                )
                local selected = tostring(Model:config().activity) == item.id
                card.button:setSelected(selected)
                card.button:setEnabled(access.known and access.eligible)
                card.iconBadge.icon:SetTexture(item.icon)
                card.iconBadge.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                card.iconBadge.outline:setColor(not access.known and theme.colors.borderStrong or (access.eligible and (selected and theme.colors.primary or theme.colors.success) or theme.colors.warning))
                card.title:SetText(item.label)
                card.detail:SetText(access.known and not access.eligible and access.reason or item.detail)
                if not access.known then
                    card.tag:SetText("CHECKING ACCESS")
                    card.tag:SetTextColor(theme.colors.muted[1], theme.colors.muted[2], theme.colors.muted[3], 1)
                elseif not access.eligible then
                    card.tag:SetText("LOCKED")
                    card.tag:SetTextColor(theme.colors.warning[1], theme.colors.warning[2], theme.colors.warning[3], 1)
                else
                    local suffix = item.id == "random" and " · RANDOM" or ""
                    card.tag:SetText((((string.upper(tostring(item.era)) .. " · AVAILABLE") .. suffix) .. " · ") .. string.upper(item.support))
                    card.tag:SetTextColor(theme.colors.success[1], theme.colors.success[2], theme.colors.success[3], 1)
                end
                local id = item.id
                local selectedMode = mode(nil)
                card.favorite:setText(Model:isFavorite(selectedMode, id) and "★" or "☆")
                card.favorite.frame:SetScript(
                    "OnMouseDown",
                    function()
                        Model:toggleFavorite(selectedMode, id)
                        refresh(nil)
                    end
                )
                card.button.frame:SetScript(
                    "OnMouseDown",
                    function()
                        local latest = Model:activityEligibility(
                            id,
                            mode(nil)
                        )
                        if not latest.known then
                            Model:fireStatus(latest.reason)
                            return
                        end
                        if not latest.eligible then
                            unlockModal:open(id, item.label, selectedMode)
                            return
                        end
                        if mode(nil) == "RAID" then
                            Model:setRaidActivity(id)
                        else
                            Model:setDungeonActivity(id)
                        end
                        modal:hide()
                    end
                )
                card.button.frame:Show()
                i = i + 1
            end
        end
        scroll:setContentHeight(math.max(
            470,
            math.ceil(#items / 2) * 86
        ))
    end
    Model:composer():RegisterCallback(
        "ACTIVITIES_CHANGED",
        function()
            if modal.frame:IsShown() then
                refresh(nil)
            end
        end
    )
    Model:composer():RegisterCallback(
        "ACTIVITY_HISTORY_CHANGED",
        function()
            if modal.frame:IsShown() then
                refresh(nil)
            end
        end
    )
    local function open(self)
        Model:requestActivities(mode(nil))
        filter = currentEra(nil)
        if mode(nil) == "RAID" then
            modal:setTitle("Choose Raid")
            modal:setSubtitle("Vanilla, TBC and WotLK live in one era-aware progression browser. Click a locked raid to see its exact unlock path.")
            modal:setHeaderIcon("Interface\\Icons\\Achievement_Boss_LichKing")
        else
            modal:setTitle("Choose Dungeon")
            modal:setSubtitle("Only the live era's difficulty rules apply. Click a locked dungeon to see its exact quest/key/progression requirements.")
            modal:setHeaderIcon("Interface\\Icons\\Spell_Arcane_PortalDalaran")
        end
        scroll:scrollToTop()
        refresh(nil)
        modal:show()
    end
    return {
        frame = modal.frame,
        open = open,
        hide = function() return modal:hide() end
    }
end
return ____exports
 end,
["widgets.TextInput"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____Native = require("core.Native")
local createPanel = ____Native.createPanel
local createSolid = ____Native.createSolid
local withAlpha = ____Native.withAlpha
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
function ____exports.createTextInput(self, parent, width, height)
    if height == nil then
        height = 36
    end
    local panel = createPanel(nil, parent, theme.colors.surfaceDeep, theme.colors.borderStrong)
    panel.frame:SetSize(width, height)
    local focusGlow = createSolid(
        nil,
        panel.frame,
        withAlpha(nil, theme.colors.primary, 0.1),
        "ARTWORK"
    )
    focusGlow:SetAllPoints(panel.frame)
    focusGlow:Hide()
    local edit = CreateFrame("EditBox", nil, panel.frame)
    edit:SetPoint(
        "TOPLEFT",
        panel.frame,
        "TOPLEFT",
        1,
        -1
    )
    edit:SetPoint(
        "BOTTOMRIGHT",
        panel.frame,
        "BOTTOMRIGHT",
        -1,
        1
    )
    edit:SetAutoFocus(false)
    edit:SetFontObject(GameFontHighlightSmall)
    edit:SetTextColor(theme.colors.text[1], theme.colors.text[2], theme.colors.text[3], 1)
    edit:SetTextInsets(10, 10, 0, 0)
    edit:SetScript(
        "OnEditFocusGained",
        function()
            panel.outline:setColor(theme.colors.primary)
            focusGlow:Show()
        end
    )
    edit:SetScript(
        "OnEditFocusLost",
        function()
            panel.outline:setColor(theme.colors.borderStrong)
            focusGlow:Hide()
        end
    )
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
["components.TemplateBrowser"] = function(...) 
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
local Model = require("model.ComposerModel")
local Native = require("core.Native")
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
local ButtonUI = require("widgets.Button")
local ModalUI = require("widgets.Modal")
local ScrollUI = require("widgets.ScrollList")
local InputUI = require("widgets.TextInput")
function ____exports.createTemplateBrowser(self, parent)
    local templateEra, namesForTab, refresh, D, modal, tab, tabDefs, tabs, scroll, cards, empty
    function templateEra(self, name)
        local profile = Model:profileMeta(name)
        local ____temp_0
        if profile ~= nil then
            ____temp_0 = D:GetRaidById(profile.activity)
        else
            ____temp_0 = nil
        end
        local raid = ____temp_0
        local ____opt_result_3
        if raid ~= nil then
            ____opt_result_3 = raid.era
        end
        local ____opt_result_3_4 = ____opt_result_3
        if ____opt_result_3_4 == nil then
            ____opt_result_3_4 = ""
        end
        return tostring(____opt_result_3_4)
    end
    function namesForTab(self)
        local mode = Model:config().mode == "RAID" and "RAID" or "DUNGEON"
        if mode == "DUNGEON" then
            return Model:listCustomProfiles("DUNGEON")
        end
        if tab == "CUSTOM" then
            return Model:listCustomProfiles("RAID")
        end
        local out = {}
        for ____, name in ipairs(Model:listBuiltinProfiles()) do
            if templateEra(nil, name) == tab then
                out[#out + 1] = name
            end
        end
        return out
    end
    function refresh(self)
        local dungeonMode = Model:config().mode == "DUNGEON"
        do
            local i = 0
            while i < #tabs do
                tabs[i + 1]:setSelected(tabDefs[i + 1].key == tab)
                if dungeonMode and tabDefs[i + 1].key ~= "CUSTOM" then
                    tabs[i + 1].frame:Hide()
                else
                    tabs[i + 1].frame:Show()
                end
                i = i + 1
            end
        end
        if dungeonMode then
            tabs[4].frame:ClearAllPoints()
            tabs[4].frame:SetPoint(
                "TOPLEFT",
                modal.content,
                "TOPLEFT",
                0,
                -82
            )
        end
        for ____, card in ipairs(cards) do
            card.panel.frame:Hide()
        end
        local names = namesForTab(nil)
        if #names == 0 then
            empty:SetText(tab == "CUSTOM" and "No custom templates yet. Configure a raid, name it above, then Save Current." or "No built-in templates are available for this expansion.")
            empty:Show()
        else
            empty:Hide()
        end
        do
            local i = 0
            while i < #names do
                local card = cards[i + 1]
                if card == nil then
                    local panel = Native:createPanel(scroll.content, theme.colors.surfaceRaised, theme.colors.border)
                    panel.frame:SetSize(426, 84)
                    local accent = Native:createSolid(panel.frame, theme.colors.primary, "ARTWORK")
                    accent:SetWidth(3)
                    accent:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        0,
                        0
                    )
                    accent:SetPoint(
                        "BOTTOMLEFT",
                        panel.frame,
                        "BOTTOMLEFT",
                        0,
                        0
                    )
                    local iconBadge = Native:createFramedIcon(panel.frame, "Interface\\Icons\\Achievement_Boss_LichKing", 40, theme.colors.primary)
                    iconBadge.frame:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        12,
                        -12
                    )
                    local name = Native:createText(panel.frame, "", "GameFontNormal")
                    name:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        64,
                        -10
                    )
                    name:SetWidth(262)
                    local tag = Native:createText(panel.frame, "", "GameFontNormalSmall", theme.colors.primary)
                    tag:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        64,
                        -31
                    )
                    tag:SetWidth(250)
                    local info = Native:createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted)
                    info:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        64,
                        -52
                    )
                    info:SetWidth(270)
                    local load = ButtonUI:createButton(panel.frame, {text = "Load", width = 64, height = 28, accent = theme.colors.primary})
                    local remove = ButtonUI:createButton(panel.frame, {text = "Delete", width = 62, height = 28, accent = theme.colors.error})
                    scroll:bindWheel(panel.frame)
                    scroll:bindWheel(load.frame)
                    scroll:bindWheel(remove.frame)
                    card = {
                        panel = panel,
                        accent = accent,
                        iconBadge = iconBadge,
                        name = name,
                        tag = tag,
                        info = info,
                        load = load,
                        remove = remove
                    }
                    cards[i + 1] = card
                end
                local profileName = names[i + 1]
                local profile = Model:profileMeta(profileName)
                local ____opt_result_7
                if profile ~= nil then
                    ____opt_result_7 = profile.builtin
                end
                local builtin = ____opt_result_7 == true
                local ____opt_result_10
                if profile ~= nil then
                    ____opt_result_10 = profile.mode
                end
                local profileMode = ____opt_result_10 == "DUNGEON" and "DUNGEON" or "RAID"
                local accent = builtin and theme.colors.primary or theme.colors.warning
                local column = i % 2
                local row = math.floor(i / 2)
                card.panel.frame:ClearAllPoints()
                card.panel.frame:SetPoint(
                    "TOPLEFT",
                    scroll.content,
                    "TOPLEFT",
                    column * 436,
                    -(row * 92)
                )
                Native:setTextureColor(card.accent, accent)
                card.iconBadge.outline:setColor(accent)
                local ____self_17 = card.iconBadge.icon
                local ____self_17_SetTexture_18 = ____self_17.SetTexture
                local ____Model_15 = Model
                local ____Model_activityIconFor_16 = Model.activityIconFor
                local ____opt_result_13
                if profile ~= nil then
                    ____opt_result_13 = profile.activity
                end
                local ____opt_result_13_14 = ____opt_result_13
                if ____opt_result_13_14 == nil then
                    ____opt_result_13_14 = ""
                end
                ____self_17_SetTexture_18(
                    ____self_17,
                    ____Model_activityIconFor_16(
                        ____Model_15,
                        tostring(____opt_result_13_14),
                        profileMode
                    )
                )
                card.iconBadge.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                local ____opt_result_21
                if profile ~= nil then
                    ____opt_result_21 = profile.activity
                end
                local ____opt_result_21_22 = ____opt_result_21
                if ____opt_result_21_22 == nil then
                    ____opt_result_21_22 = ""
                end
                local activityId = tostring(____opt_result_21_22)
                local access = Model:activityEligibility(activityId, profileMode)
                card.name:SetText(profileName)
                if not access.known then
                    card.tag:SetText("CHECKING ACCESS")
                    card.tag:SetTextColor(theme.colors.muted[1], theme.colors.muted[2], theme.colors.muted[3], 1)
                    card.info:SetText(Model:profileDescription(profileName))
                elseif not access.eligible then
                    card.tag:SetText("LOCKED")
                    card.tag:SetTextColor(theme.colors.warning[1], theme.colors.warning[2], theme.colors.warning[3], 1)
                    card.info:SetText(access.reason)
                else
                    card.tag:SetText(builtin and string.upper(tostring(templateEra(nil, profileName))) .. " · BUILT-IN · AVAILABLE" or "CUSTOM · AVAILABLE")
                    card.tag:SetTextColor(theme.colors.success[1], theme.colors.success[2], theme.colors.success[3], 1)
                    card.info:SetText(Model:profileDescription(profileName))
                end
                card.load:setEnabled(access.known and access.eligible)
                card.load.frame:ClearAllPoints()
                card.remove.frame:ClearAllPoints()
                if builtin then
                    card.remove.frame:Hide()
                    card.load.frame:SetPoint(
                        "RIGHT",
                        card.panel.frame,
                        "RIGHT",
                        -10,
                        0
                    )
                else
                    card.load.frame:SetPoint(
                        "TOPRIGHT",
                        card.panel.frame,
                        "TOPRIGHT",
                        -78,
                        -10
                    )
                    card.remove.frame:SetPoint(
                        "TOPRIGHT",
                        card.panel.frame,
                        "TOPRIGHT",
                        -10,
                        -10
                    )
                    card.remove.frame:SetScript(
                        "OnMouseDown",
                        function()
                            Model:deleteProfile(profileName)
                            refresh(nil)
                        end
                    )
                    card.remove.frame:Show()
                end
                card.load.frame:SetScript(
                    "OnMouseDown",
                    function()
                        local ____Model_27 = Model
                        local ____Model_activityEligibility_28 = Model.activityEligibility
                        local ____opt_result_25
                        if profile ~= nil then
                            ____opt_result_25 = profile.activity
                        end
                        local ____opt_result_25_26 = ____opt_result_25
                        if ____opt_result_25_26 == nil then
                            ____opt_result_25_26 = ""
                        end
                        local latest = ____Model_activityEligibility_28(
                            ____Model_27,
                            tostring(____opt_result_25_26),
                            profileMode
                        )
                        if not latest.known or not latest.eligible then
                            Model:fireStatus(latest.reason)
                            return
                        end
                        Model:loadProfile(profileName)
                        modal:hide()
                    end
                )
                card.panel.frame:Show()
                i = i + 1
            end
        end
        scroll:setContentHeight(math.max(
            420,
            math.ceil(#names / 2) * 92
        ))
    end
    D = Model:data()
    modal = ModalUI:createModal(parent, 960, 650)
    modal:setTitle("Templates")
    modal:setSubtitle("Save reusable raid rosters or five-player dungeon parties.")
    modal:setHeaderIcon("Interface\\Icons\\INV_Scroll_03")
    local saveLabel = Native:createText(modal.content, "SAVE CURRENT GROUP", "GameFontNormalSmall", theme.colors.muted)
    saveLabel:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        0,
        0
    )
    local nameInput = InputUI:createTextInput(modal.content, 300, 34)
    nameInput.frame:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        0,
        -24
    )
    tab = "WotLK"
    tabDefs = {{key = "WotLK", label = "WotLK", width = 116}, {key = "TBC", label = "TBC", width = 104}, {key = "Vanilla", label = "Vanilla", width = 116}, {key = "CUSTOM", label = "My Templates", width = 150}}
    tabs = {}
    local x = 0
    for ____, def in ipairs(tabDefs) do
        local button = ButtonUI:createButton(modal.content, {
            text = def.label,
            width = def.width,
            height = 34,
            accent = def.key == "CUSTOM" and theme.colors.warning or theme.colors.primary,
            flat = true
        })
        button.frame:SetPoint(
            "TOPLEFT",
            modal.content,
            "TOPLEFT",
            x,
            -82
        )
        local key = def.key
        button.frame:SetScript(
            "OnMouseDown",
            function()
                tab = key
                scroll:scrollToTop()
                refresh(nil)
            end
        )
        tabs[#tabs + 1] = button
        x = x + (def.width + 8)
    end
    scroll = ScrollUI:createScrollList(modal.content, 884, 420)
    scroll.frame:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        0,
        -126
    )
    cards = {}
    empty = Native:createText(scroll.content, "", "GameFontHighlight", theme.colors.muted)
    empty:SetPoint(
        "TOPLEFT",
        scroll.content,
        "TOPLEFT",
        24,
        -28
    )
    empty:SetWidth(800)
    empty:SetJustifyH("CENTER")
    empty:Hide()
    local save = ButtonUI:createButton(
        modal.content,
        {
            text = "Save Current",
            width = 124,
            height = 36,
            accent = theme.colors.primary,
            emphasis = true,
            onClick = function()
                local name = nameInput:getText()
                if name == "" then
                    return
                end
                Model:saveProfile(name)
                nameInput:clear()
                tab = "CUSTOM"
                scroll:scrollToTop()
                refresh(nil)
            end
        }
    )
    save.frame:SetPoint(
        "LEFT",
        nameInput.frame,
        "RIGHT",
        8,
        0
    )
    Model:composer():RegisterCallback(
        "ACTIVITIES_CHANGED",
        function(____, mode)
            if mode == "RAID" and modal.frame:IsShown() then
                refresh(nil)
            end
        end
    )
    local function open(self)
        local dungeonMode = Model:config().mode == "DUNGEON"
        if dungeonMode then
            modal:setTitle("Dungeon Party Templates")
            modal:setSubtitle("Save your five-player role, class/spec, human and pinned-bot preferences for quick reuse.")
            saveLabel:SetText("SAVE CURRENT PARTY")
            tab = "CUSTOM"
            Model:requestActivities("DUNGEON")
        else
            modal:setTitle("Raid Templates")
            modal:setSubtitle("Browse built-in coverage templates by expansion or load your own saved raid.")
            saveLabel:SetText("SAVE CURRENT RAID")
            local ____Model_30 = Model
            local ____Model_requestActivities_31 = Model.requestActivities
            local ____table_size_29 = Model:config().size
            if ____table_size_29 == nil then
                ____table_size_29 = 25
            end
            ____Model_requestActivities_31(
                ____Model_30,
                "RAID",
                "normal",
                __TS__Number(____table_size_29)
            )
            local raid = D:GetRaidById(Model:config().activity)
            local ____opt_result_34
            if raid ~= nil then
                ____opt_result_34 = raid.era
            end
            local ____opt_result_34_35 = ____opt_result_34
            if ____opt_result_34_35 == nil then
                ____opt_result_34_35 = "WotLK"
            end
            local era = tostring(____opt_result_34_35)
            tab = era == "TBC" and "TBC" or (era == "Vanilla" and "Vanilla" or "WotLK")
        end
        save:setEnabled(true)
        scroll:scrollToTop()
        refresh(nil)
        modal:show()
    end
    return {
        frame = modal.frame,
        open = open,
        hide = function() return modal:hide() end
    }
end
return ____exports
 end,
["components.RaidHistoryModal"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local Native = require("core.Native")
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
local ModalUI = require("widgets.Modal")
function ____exports.createRaidHistoryModal(self, parent)
    local modal = ModalUI:createModal(parent, 720, 520)
    modal:setHeaderIcon("Interface\\Icons\\INV_Misc_Book_09")
    modal:setTitle("Raid History")
    modal:setSubtitle("Personal progress, guild history and current lockout.")
    local status = Native:createText(modal.content, "", "GameFontNormal", theme.colors.primary)
    status:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        8,
        -8
    )
    status:SetWidth(630)
    local personalTitle = Native:createText(modal.content, "YOUR HISTORY", "GameFontNormalSmall", theme.colors.muted)
    personalTitle:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        8,
        -58
    )
    local personal = Native:createText(modal.content, "", "GameFontHighlight", theme.colors.text)
    personal:SetPoint(
        "TOPLEFT",
        personalTitle,
        "BOTTOMLEFT",
        0,
        -8
    )
    personal:SetWidth(630)
    local guildTitle = Native:createText(modal.content, "GUILD HISTORY", "GameFontNormalSmall", theme.colors.muted)
    guildTitle:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        8,
        -126
    )
    local guild = Native:createText(modal.content, "", "GameFontHighlight", theme.colors.text)
    guild:SetPoint(
        "TOPLEFT",
        guildTitle,
        "BOTTOMLEFT",
        0,
        -8
    )
    guild:SetWidth(630)
    local rosterTitle = Native:createText(modal.content, "FIRST RECORDED GUILD-CLEAR ROSTER", "GameFontNormalSmall", theme.colors.warning)
    rosterTitle:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        8,
        -202
    )
    local roster = Native:createText(modal.content, "", "GameFontHighlight", theme.colors.text)
    roster:SetPoint(
        "TOPLEFT",
        rosterTitle,
        "BOTTOMLEFT",
        0,
        -8
    )
    roster:SetWidth(630)
    roster:SetHeight(74)
    roster:SetJustifyV("TOP")
    local lockoutTitle = Native:createText(modal.content, "CURRENT LOCKOUT", "GameFontNormalSmall", theme.colors.muted)
    lockoutTitle:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        8,
        -306
    )
    local lockout = Native:createText(modal.content, "", "GameFontHighlight", theme.colors.text)
    lockout:SetPoint(
        "TOPLEFT",
        lockoutTitle,
        "BOTTOMLEFT",
        0,
        -8
    )
    lockout:SetWidth(630)
    local accessTitle = Native:createText(modal.content, "ACCESS / SUPPORT", "GameFontNormalSmall", theme.colors.muted)
    accessTitle:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        8,
        -374
    )
    local access = Native:createText(modal.content, "", "GameFontHighlightSmall", theme.colors.muted)
    access:SetPoint(
        "TOPLEFT",
        accessTitle,
        "BOTTOMLEFT",
        0,
        -8
    )
    access:SetWidth(630)
    access:SetHeight(58)
    access:SetJustifyV("TOP")
    return {open = function(____, raid)
        modal:setTitle(raid.label)
        modal:setSubtitle(raid.era .. " · Raid history")
        if raid.playerClearCount > 0 then
            personal:SetText(("Clears: " .. tostring(raid.playerClearCount)) .. (raid.playerFirstClear ~= "" and " · First recorded clear: " .. raid.playerFirstClear or ""))
        elseif raid.playerComplete then
            personal:SetText("Completed through progression state; no detailed kill event is recorded yet.")
        else
            personal:SetText("No recorded clear yet.")
        end
        if raid.guildClearCount > 0 then
            guild:SetText(("Guild clears: " .. tostring(raid.guildClearCount)) .. (raid.guildFirstClear ~= "" and " · First recorded clear: " .. raid.guildFirstClear or ""))
        else
            guild:SetText("No recorded guild clear yet.")
        end
        roster:SetText(raid.guildFirstRoster ~= "" and raid.guildFirstRoster or "No first-clear roster is recorded yet. Historical bounty-only clears cannot reconstruct participants.")
        if raid.lockoutActive then
            lockout:SetText((((("Instance #" .. tostring(raid.lockoutInstanceId)) .. " · ") .. tostring(raid.lockoutEncounters)) .. " completed encounter(s)") .. (raid.lockoutExtended and " · Extended" or ""))
        else
            lockout:SetText("No active saved raid instance.")
        end
        access:SetText(((((raid.available and "Available" or "Locked") .. " · ") .. raid.support) .. "\n") .. raid.reason)
        modal:show()
    end}
end
return ____exports
 end,
["components.ProgressionPage"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local Model = require("model.ComposerModel")
local Native = require("core.Native")
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
local ButtonUI = require("widgets.Button")
local ScrollUI = require("widgets.ScrollList")
local RaidHistoryUI = require("components.RaidHistoryModal")
local function eraAccent(self, era)
    if era == "Vanilla" then
        return theme.colors.warning
    end
    if era == "TBC" then
        return theme.colors.success
    end
    return theme.colors.primary
end
function ____exports.createProgressionPage(self, parent)
    local root = Native:createPanel(parent, theme.colors.background, theme.colors.borderStrong)
    root.frame:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        200,
        -88
    )
    root.frame:SetPoint(
        "BOTTOMRIGHT",
        parent,
        "BOTTOMRIGHT",
        -16,
        16
    )
    root.frame:Hide()
    local raidHistory = RaidHistoryUI:createRaidHistoryModal(parent)
    local eyebrow = Native:createText(root.frame, "YOUR JOURNEY", "GameFontNormalSmall", theme.colors.muted)
    eyebrow:SetPoint(
        "TOPLEFT",
        root.frame,
        "TOPLEFT",
        22,
        -18
    )
    local title = Native:createText(root.frame, "Expansion Progression", "GameFontNormalLarge")
    title:SetPoint(
        "TOPLEFT",
        eyebrow,
        "BOTTOMLEFT",
        0,
        -8
    )
    local subtitle = Native:createText(root.frame, "See what you have cleared, what your guild has cleared, and exactly what still blocks the next activity.", "GameFontHighlightSmall", theme.colors.muted)
    subtitle:SetPoint(
        "TOPLEFT",
        title,
        "BOTTOMLEFT",
        0,
        -6
    )
    subtitle:SetWidth(1040)
    local summary = Native:createPanel(root.frame, theme.colors.surface, theme.colors.border)
    summary.frame:SetPoint(
        "TOPLEFT",
        root.frame,
        "TOPLEFT",
        22,
        -92
    )
    summary.frame:SetPoint(
        "TOPRIGHT",
        root.frame,
        "TOPRIGHT",
        -22,
        -92
    )
    summary.frame:SetHeight(92)
    local eraText = Native:createText(summary.frame, "VANILLA", "GameFontNormalLarge", theme.colors.warning)
    eraText:SetPoint(
        "TOPLEFT",
        summary.frame,
        "TOPLEFT",
        18,
        -15
    )
    local stageText = Native:createText(summary.frame, "Progression stage 0", "GameFontHighlight", theme.colors.text)
    stageText:SetPoint(
        "TOPLEFT",
        eraText,
        "BOTTOMLEFT",
        0,
        -5
    )
    local levelText = Native:createText(summary.frame, "Level 1 / 60", "GameFontHighlightSmall", theme.colors.muted)
    levelText:SetPoint(
        "TOPLEFT",
        stageText,
        "BOTTOMLEFT",
        0,
        -4
    )
    local gateText = Native:createText(summary.frame, "", "GameFontHighlight", theme.colors.muted)
    gateText:SetPoint(
        "TOPRIGHT",
        summary.frame,
        "TOPRIGHT",
        -18,
        -18
    )
    gateText:SetWidth(660)
    gateText:SetJustifyH("RIGHT")
    local tabs = {}
    local eras = {"Vanilla", "TBC", "WotLK"}
    do
        local i = 0
        while i < #eras do
            local era = eras[i + 1]
            local button = ButtonUI:createButton(
                root.frame,
                {
                    text = era,
                    width = 130,
                    height = 34,
                    accent = eraAccent(nil, era),
                    flat = true
                }
            )
            button.frame:SetPoint(
                "TOPLEFT",
                root.frame,
                "TOPLEFT",
                22 + i * 138,
                -202
            )
            tabs[era] = button
            i = i + 1
        end
    end
    local scroll = ScrollUI:createScrollList(root.frame, 1260, 548)
    scroll.frame:SetPoint(
        "TOPLEFT",
        root.frame,
        "TOPLEFT",
        22,
        -248
    )
    local cards = {}
    local empty = Native:createText(scroll.content, "No raids are tracked for this era.", "GameFontHighlight", theme.colors.muted)
    empty:SetPoint(
        "TOPLEFT",
        scroll.content,
        "TOPLEFT",
        24,
        -28
    )
    empty:SetWidth(1180)
    empty:SetJustifyH("CENTER")
    empty:Hide()
    local selectedEra = "Vanilla"
    local function refresh(self)
        local journey = Model:journey()
        local realm = Model:realm()
        local accent = eraAccent(nil, journey.era)
        eraText:SetText(string.upper(tostring(journey.era)))
        eraText:SetTextColor(accent[1], accent[2], accent[3], 1)
        stageText:SetText("Progression stage " .. tostring(journey.stage))
        levelText:SetText((("Level " .. tostring(journey.level)) .. " / ") .. tostring(realm.levelCap))
        if journey.era == "Vanilla" then
            gateText:SetText("Next expansion: The Burning Crusade\nRelease it manually in Azeroth Control when your Vanilla journey is complete.")
        elseif journey.era == "TBC" then
            gateText:SetText("Next expansion: Wrath of the Lich King\nRelease it manually in Azeroth Control when your TBC journey is complete.")
        else
            gateText:SetText("Current expansion: Wrath of the Lich King\nThis is the final supported realm era.")
        end
        for ____, era in ipairs(eras) do
            tabs[era]:setSelected(selectedEra == era)
        end
        for ____, card in ipairs(cards) do
            card.panel.frame:Hide()
        end
        local rows = {}
        for ____, raid in ipairs(journey.raids) do
            if raid.era == selectedEra then
                rows[#rows + 1] = raid
            end
        end
        if #rows == 0 then
            empty:Show()
        else
            empty:Hide()
        end
        do
            local i = 0
            while i < #rows do
                local card = cards[i + 1]
                if card == nil then
                    local panel = Native:createPanel(scroll.content, theme.colors.surfaceRaised, theme.colors.border)
                    panel.frame:SetSize(606, 108)
                    local iconBadge = Native:createFramedIcon(panel.frame, "Interface\\Icons\\Achievement_Boss_LichKing", 48, theme.colors.borderStrong)
                    iconBadge.frame:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        14,
                        -15
                    )
                    local cardTitle = Native:createText(panel.frame, "", "GameFontNormal")
                    cardTitle:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        76,
                        -13
                    )
                    cardTitle:SetWidth(340)
                    local status = Native:createText(panel.frame, "", "GameFontNormalSmall")
                    status:SetPoint(
                        "TOPRIGHT",
                        panel.frame,
                        "TOPRIGHT",
                        -14,
                        -15
                    )
                    status:SetWidth(150)
                    status:SetJustifyH("RIGHT")
                    local detail = Native:createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted)
                    detail:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        76,
                        -38
                    )
                    detail:SetWidth(500)
                    local player = Native:createText(panel.frame, "", "GameFontNormalSmall", theme.colors.muted)
                    player:SetPoint(
                        "BOTTOMLEFT",
                        panel.frame,
                        "BOTTOMLEFT",
                        76,
                        15
                    )
                    local guild = Native:createText(panel.frame, "", "GameFontNormalSmall", theme.colors.muted)
                    guild:SetPoint(
                        "LEFT",
                        player,
                        "RIGHT",
                        22,
                        0
                    )
                    scroll:bindWheel(panel.frame)
                    panel.frame:EnableMouse(true)
                    card = {
                        panel = panel,
                        iconBadge = iconBadge,
                        title = cardTitle,
                        status = status,
                        detail = detail,
                        player = player,
                        guild = guild
                    }
                    cards[i + 1] = card
                end
                local raid = rows[i + 1]
                local column = i % 2
                local row = math.floor(i / 2)
                card.panel.frame:ClearAllPoints()
                card.panel.frame:SetPoint(
                    "TOPLEFT",
                    scroll.content,
                    "TOPLEFT",
                    column * 620,
                    -(row * 116)
                )
                card.iconBadge.icon:SetTexture(Model:activityIconFor(raid.id, "RAID"))
                card.iconBadge.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                local cardAccent = raid.playerComplete and theme.colors.success or (raid.available and theme.colors.primary or theme.colors.warning)
                card.iconBadge.outline:setColor(cardAccent)
                card.title:SetText(raid.label)
                if raid.playerComplete then
                    card.status:SetText("CLEARED")
                    card.status:SetTextColor(theme.colors.success[1], theme.colors.success[2], theme.colors.success[3], 1)
                elseif raid.available then
                    card.status:SetText("AVAILABLE")
                    card.status:SetTextColor(theme.colors.primary[1], theme.colors.primary[2], theme.colors.primary[3], 1)
                else
                    card.status:SetText("LOCKED")
                    card.status:SetTextColor(theme.colors.warning[1], theme.colors.warning[2], theme.colors.warning[3], 1)
                end
                local lockoutText = raid.lockoutActive and ((((" · ACTIVE LOCKOUT #" .. tostring(raid.lockoutInstanceId)) .. " · ") .. tostring(raid.lockoutEncounters)) .. " encounter(s)") .. (raid.lockoutExtended and " · EXTENDED" or "") or ""
                card.detail:SetText((raid.reason .. lockoutText) .. " · click for history")
                local playerHistory = raid.playerClearCount > 0 and ("You: Cleared ×" .. tostring(raid.playerClearCount)) .. (raid.playerFirstClear ~= "" and " · first " .. raid.playerFirstClear or "") or (raid.playerComplete and "You: Cleared ✓" or "You: Not cleared")
                card.player:SetText(playerHistory)
                card.player:SetTextColor(raid.playerComplete and theme.colors.success[1] or theme.colors.muted[1], raid.playerComplete and theme.colors.success[2] or theme.colors.muted[2], raid.playerComplete and theme.colors.success[3] or theme.colors.muted[3], 1)
                local guildHistory = raid.guildClearCount > 0 and ("Guild: Cleared ×" .. tostring(raid.guildClearCount)) .. (raid.guildFirstClear ~= "" and " · first " .. raid.guildFirstClear or "") or (raid.guildComplete and "Guild: Cleared ✓" or "Guild: Not recorded")
                card.guild:SetText(guildHistory)
                card.guild:SetTextColor(raid.guildComplete and theme.colors.success[1] or theme.colors.muted[1], raid.guildComplete and theme.colors.success[2] or theme.colors.muted[2], raid.guildComplete and theme.colors.success[3] or theme.colors.muted[3], 1)
                local raidCopy = raid
                card.panel.frame:SetScript(
                    "OnMouseDown",
                    function() return raidHistory:open(raidCopy) end
                )
                card.panel.frame:Show()
                i = i + 1
            end
        end
        scroll:setContentHeight(math.max(
            548,
            math.ceil(#rows / 2) * 116
        ))
    end
    for ____, era in ipairs(eras) do
        local value = era
        tabs[era].frame:SetScript(
            "OnMouseDown",
            function()
                selectedEra = value
                scroll:scrollToTop()
                refresh(nil)
            end
        )
    end
    Model:composer():RegisterCallback(
        "JOURNEY_CHANGED",
        function()
            if root.frame:IsShown() then
                refresh(nil)
            end
        end
    )
    Model:composer():RegisterCallback(
        "REALM_CHANGED",
        function()
            if root.frame:IsShown() then
                refresh(nil)
            end
        end
    )
    local function show(self)
        selectedEra = Model:realm().era
        root.frame:Show()
        scroll:scrollToTop()
        refresh(nil)
        Model:requestJourney()
    end
    return {
        frame = root.frame,
        show = show,
        hide = function() return root.frame:Hide() end,
        refresh = refresh
    }
end
return ____exports
 end,
["components.RecommendationsPage"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local Model = require("model.ComposerModel")
local Native = require("core.Native")
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
local ButtonUI = require("widgets.Button")
local ScrollUI = require("widgets.ScrollList")
function ____exports.createRecommendationsPage(self, parent, onConfigure)
    local root = Native:createPanel(parent, theme.colors.background, theme.colors.borderStrong)
    root.frame:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        200,
        -88
    )
    root.frame:SetPoint(
        "BOTTOMRIGHT",
        parent,
        "BOTTOMRIGHT",
        -16,
        16
    )
    root.frame:Hide()
    local eyebrow = Native:createText(root.frame, "WHAT SHOULD WE DO?", "GameFontNormalSmall", theme.colors.muted)
    eyebrow:SetPoint(
        "TOPLEFT",
        root.frame,
        "TOPLEFT",
        22,
        -18
    )
    local title = Native:createText(root.frame, "Recommended Activities", "GameFontNormalLarge")
    title:SetPoint(
        "TOPLEFT",
        eyebrow,
        "BOTTOMLEFT",
        0,
        -8
    )
    local subtitle = Native:createText(root.frame, "Suggestions come from the live realm era, your level, progression gates and activities you have not cleared yet.", "GameFontHighlightSmall", theme.colors.muted)
    subtitle:SetPoint(
        "TOPLEFT",
        title,
        "BOTTOMLEFT",
        0,
        -6
    )
    subtitle:SetWidth(1080)
    local realmText = Native:createText(root.frame, "", "GameFontHighlight", theme.colors.primary)
    realmText:SetPoint(
        "TOPRIGHT",
        root.frame,
        "TOPRIGHT",
        -24,
        -28
    )
    realmText:SetWidth(300)
    realmText:SetJustifyH("RIGHT")
    local scroll = ScrollUI:createScrollList(root.frame, 1260, 690)
    scroll.frame:SetPoint(
        "TOPLEFT",
        root.frame,
        "TOPLEFT",
        22,
        -104
    )
    local cards = {}
    local empty = Native:createText(scroll.content, "No recommendations are available yet. Refresh after your progression changes.", "GameFontHighlight", theme.colors.muted)
    empty:SetPoint(
        "TOPLEFT",
        scroll.content,
        "TOPLEFT",
        24,
        -30
    )
    empty:SetWidth(1180)
    empty:SetJustifyH("CENTER")
    empty:Hide()
    local function refresh(self)
        local journey = Model:journey()
        realmText:SetText((string.upper(tostring(journey.era)) .. " · STAGE ") .. tostring(journey.stage))
        for ____, card in ipairs(cards) do
            card.panel.frame:Hide()
        end
        local rows = journey.recommendations
        if #rows == 0 then
            empty:Show()
        else
            empty:Hide()
        end
        do
            local i = 0
            while i < #rows do
                local card = cards[i + 1]
                if card == nil then
                    local panel = Native:createPanel(scroll.content, theme.colors.surfaceRaised, theme.colors.border)
                    panel.frame:SetSize(1228, 112)
                    local iconBadge = Native:createFramedIcon(panel.frame, "Interface\\Icons\\INV_Misc_Map_01", 50, theme.colors.primary)
                    iconBadge.frame:SetPoint(
                        "LEFT",
                        panel.frame,
                        "LEFT",
                        16,
                        0
                    )
                    local cardTitle = Native:createText(panel.frame, "", "GameFontNormal")
                    cardTitle:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        82,
                        -16
                    )
                    cardTitle:SetWidth(520)
                    local meta = Native:createText(panel.frame, "", "GameFontNormalSmall", theme.colors.primary)
                    meta:SetPoint(
                        "TOPLEFT",
                        cardTitle,
                        "BOTTOMLEFT",
                        0,
                        -5
                    )
                    meta:SetWidth(520)
                    local reason = Native:createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted)
                    reason:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        620,
                        -18
                    )
                    reason:SetWidth(410)
                    reason:SetHeight(36)
                    reason:SetJustifyV("TOP")
                    local readiness = Native:createText(panel.frame, "", "GameFontNormalSmall", theme.colors.primary)
                    readiness:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        620,
                        -67
                    )
                    readiness:SetWidth(410)
                    local use = ButtonUI:createButton(panel.frame, {
                        text = "Configure",
                        width = 150,
                        height = 38,
                        accent = theme.colors.success,
                        emphasis = true
                    })
                    use.frame:SetPoint(
                        "RIGHT",
                        panel.frame,
                        "RIGHT",
                        -16,
                        0
                    )
                    scroll:bindWheel(panel.frame)
                    scroll:bindWheel(use.frame)
                    card = {
                        panel = panel,
                        iconBadge = iconBadge,
                        title = cardTitle,
                        meta = meta,
                        reason = reason,
                        readiness = readiness,
                        use = use
                    }
                    cards[i + 1] = card
                end
                local item = rows[i + 1]
                card.panel.frame:ClearAllPoints()
                card.panel.frame:SetPoint(
                    "TOPLEFT",
                    scroll.content,
                    "TOPLEFT",
                    0,
                    -(i * 120)
                )
                card.iconBadge.icon:SetTexture(Model:activityIconFor(item.id, item.mode))
                card.iconBadge.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                card.title:SetText(item.label)
                local availability = item.available and "AVAILABLE" or "LOCKED"
                local readiness = item.available and (item.feasible and ((("GROUP READY · " .. tostring(item.guildBots)) .. " guild bot(s) selected · ") .. tostring(item.guildCandidates)) .. " guild candidate(s)" or "ROSTER NEEDS WORK") or "NEXT UNLOCK"
                card.meta:SetText((((item.era .. " · ") .. (item.mode == "RAID" and "Raid" or "Dungeon")) .. " · ") .. availability)
                card.reason:SetText(item.reason)
                card.readiness:SetText(readiness .. (item.readiness ~= "" and " · " .. item.readiness or ""))
                local accent = not item.available and theme.colors.warning or (item.feasible and theme.colors.success or theme.colors.error)
                card.readiness:SetTextColor(accent[1], accent[2], accent[3], 1)
                card.iconBadge.outline:setColor(accent)
                card.use:setEnabled(item.available)
                card.use:setText(item.available and "Configure" or "Locked")
                local id = item.id
                local mode = item.mode
                card.use.frame:SetScript(
                    "OnMouseDown",
                    function()
                        if not item.available then
                            return
                        end
                        Model:setMode(mode)
                        if mode == "RAID" then
                            Model:setRaidActivity(id)
                        else
                            Model:setDungeonActivity(id)
                        end
                        onConfigure(nil)
                    end
                )
                card.panel.frame:Show()
                i = i + 1
            end
        end
        scroll:setContentHeight(math.max(690, #rows * 120))
    end
    Model:composer():RegisterCallback(
        "JOURNEY_CHANGED",
        function()
            if root.frame:IsShown() then
                refresh(nil)
            end
        end
    )
    local function show(self)
        root.frame:Show()
        scroll:scrollToTop()
        refresh(nil)
        Model:requestJourney()
    end
    return {
        frame = root.frame,
        show = show,
        hide = function() return root.frame:Hide() end,
        refresh = refresh
    }
end
return ____exports
 end,
["components.MemberDetailsModal"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local Model = require("model.ComposerModel")
local Native = require("core.Native")
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
local ModalUI = require("widgets.Modal")
local function sourceLabel(self, source)
    if source == "HUMAN" then
        return "Real player anchor"
    end
    if source == "GUILD" then
        return "Guild companion"
    end
    if source == "RESERVE" then
        return "Composer reserve"
    end
    if source == "ROSTER" then
        return "Managed Composer capacity"
    end
    return "World bot"
end
function ____exports.createMemberDetailsModal(self, parent)
    local modal = ModalUI:createModal(parent, 680, 410)
    modal:setHeaderIcon("Interface\\Icons\\INV_Misc_Note_05")
    modal:setTitle("Why this member?")
    modal:setSubtitle("Group Composer selection rationale.")
    local summary = Native:createText(modal.content, "", "GameFontNormal", theme.colors.primary)
    summary:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        8,
        -6
    )
    summary:SetWidth(600)
    local source = Native:createText(modal.content, "", "GameFontHighlightSmall", theme.colors.muted)
    source:SetPoint(
        "TOPLEFT",
        summary,
        "BOTTOMLEFT",
        0,
        -7
    )
    source:SetWidth(600)
    local whyTitle = Native:createText(modal.content, "WHY COMPOSER CHOSE THIS MEMBER", "GameFontNormalSmall", theme.colors.warning)
    whyTitle:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        8,
        -82
    )
    local why = Native:createText(modal.content, "", "GameFontHighlight", theme.colors.text)
    why:SetPoint(
        "TOPLEFT",
        whyTitle,
        "BOTTOMLEFT",
        0,
        -10
    )
    why:SetWidth(610)
    why:SetHeight(190)
    why:SetJustifyV("TOP")
    local hint = Native:createText(modal.content, "This explanation comes from the server-reviewed roster snapshot. Rebuilding may choose a different bot if availability, guild state, level band or utility coverage changes.", "GameFontHighlightSmall", theme.colors.muted)
    hint:SetPoint(
        "BOTTOMLEFT",
        modal.content,
        "BOTTOMLEFT",
        8,
        8
    )
    hint:SetWidth(610)
    hint:SetJustifyV("BOTTOM")
    return {open = function(____, member)
        local role = Model:roleLabel(member.role)
        local level = tostring(member.level or "?")
        local spec = tostring(member.spec or Model:classLabel(tostring(member.class)))
        modal:setTitle(member.human and "Why is this player anchored?" or "Why this bot?")
        modal:setSubtitle(tostring(member.name))
        summary:SetText((((("Level " .. level) .. "  ·  ") .. spec) .. "  ·  ") .. role)
        source:SetText(((sourceLabel(
            nil,
            tostring(member.source or "WORLD")
        ) .. (member.pinned and "  ·  PINNED" or "")) .. (member.locked and "  ·  ALREADY GROUPED" or "")) .. (member.needsPreparation and "  ·  PREPARATION NEEDED" or ""))
        why:SetText(tostring(member.why or "Composer selected this member because it matched the reviewed roster requirements."))
        modal:show()
    end}
end
return ____exports
 end,
["components.GroupActionsModal"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local Model = require("model.ComposerModel")
local Native = require("core.Native")
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
local ButtonUI = require("widgets.Button")
local ModalUI = require("widgets.Modal")
function ____exports.createGroupActionsModal(self, parent)
    local modal = ModalUI:createModal(parent, 650, 430)
    modal:setHeaderIcon("Interface\\Icons\\INV_Misc_GroupLooking")
    modal:setTitle("Assembled Group Actions")
    modal:setSubtitle("Keep the current composition useful after assembly and instance travel.")
    local intro = Native:createText(modal.content, "Rebuild/Repair keeps the current configuration and treats valid live members as sticky anchors.", "GameFontHighlight", theme.colors.muted)
    intro:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        8,
        -6
    )
    intro:SetWidth(570)
    intro:SetHeight(46)
    intro:SetJustifyV("TOP")
    local rebuild = ButtonUI:createButton(
        modal.content,
        {
            text = "Rebuild / Repair Roster",
            width = 260,
            height = 44,
            accent = theme.colors.primary,
            emphasis = true,
            onClick = function()
                modal:hide()
                Model:rebuildOrRepair()
            end
        }
    )
    rebuild.frame:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        8,
        -72
    )
    local rebuildHint = Native:createText(modal.content, "Re-run Build & Prepare. Existing valid group members stay; missing slots are filled again.", "GameFontHighlightSmall", theme.colors.muted)
    rebuildHint:SetPoint(
        "TOPLEFT",
        rebuild.frame,
        "BOTTOMLEFT",
        0,
        -7
    )
    rebuildHint:SetWidth(560)
    local leave = ButtonUI:createButton(
        modal.content,
        {
            text = "Leave Instance Together",
            width = 260,
            height = 44,
            accent = theme.colors.success,
            onClick = function()
                modal:hide()
                Model:leaveInstance()
            end
        }
    )
    leave.frame:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        8,
        -160
    )
    local leaveHint = Native:createText(modal.content, "Use AzerothCore's canonical instance exit. The reviewed group remains assembled for re-entry.", "GameFontHighlightSmall", theme.colors.muted)
    leaveHint:SetPoint(
        "TOPLEFT",
        leave.frame,
        "BOTTOMLEFT",
        0,
        -7
    )
    leaveHint:SetWidth(560)
    local disband = ButtonUI:createButton(modal.content, {text = "Disband Composer Group", width = 260, height = 44, accent = theme.colors.error})
    disband.frame:SetPoint(
        "TOPLEFT",
        modal.content,
        "TOPLEFT",
        8,
        -248
    )
    local disbandHint = Native:createText(modal.content, "Only the real leader can do this. Composer refuses if an unreviewed player has joined the live group.", "GameFontHighlightSmall", theme.colors.muted)
    disbandHint:SetPoint(
        "TOPLEFT",
        disband.frame,
        "BOTTOMLEFT",
        0,
        -7
    )
    disbandHint:SetWidth(560)
    local confirm = ModalUI:createModal(parent, 560, 270)
    confirm:setHeaderIcon("Interface\\Icons\\Ability_Rogue_FeignDeath")
    confirm:setTitle("Disband Composer group?")
    confirm:setSubtitle("This removes the reviewed live party/raid. Your saved configuration remains.")
    local confirmText = Native:createText(confirm.content, "Composer only disbands if you are the real leader and the live group exactly matches the reviewed roster. Unreviewed players are protected.", "GameFontHighlight", theme.colors.muted)
    confirmText:SetPoint(
        "TOPLEFT",
        confirm.content,
        "TOPLEFT",
        8,
        -8
    )
    confirmText:SetWidth(490)
    confirmText:SetJustifyH("CENTER")
    confirmText:SetJustifyV("TOP")
    local cancel = ButtonUI:createButton(
        confirm.content,
        {
            text = "Cancel",
            width = 120,
            height = 36,
            onClick = function() return confirm:hide() end
        }
    )
    cancel.frame:SetPoint(
        "BOTTOMLEFT",
        confirm.content,
        "BOTTOMLEFT",
        112,
        0
    )
    local go = ButtonUI:createButton(
        confirm.content,
        {
            text = "Disband",
            width = 140,
            height = 38,
            accent = theme.colors.error,
            emphasis = true,
            onClick = function()
                confirm:hide()
                Model:disbandComposerGroup()
            end
        }
    )
    go.frame:SetPoint(
        "BOTTOMRIGHT",
        confirm.content,
        "BOTTOMRIGHT",
        -112,
        0
    )
    disband.frame:SetScript(
        "OnMouseDown",
        function()
            modal:hide()
            confirm:show()
        end
    )
    return {open = function()
        if not Model:isAssembled() then
            Model:fireStatus("Assemble the reviewed roster before using group lifecycle actions.")
            return
        end
        modal:show()
    end}
end
return ____exports
 end,
["components.ActivityDiagnosticsPage"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local Model = require("model.ComposerModel")
local Native = require("core.Native")
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
local ButtonUI = require("widgets.Button")
local ScrollUI = require("widgets.ScrollList")
local function statusAccent(self, status)
    if status == "FAIL" then
        return theme.colors.error
    end
    if status == "WARN" then
        return theme.colors.warning
    end
    return theme.colors.success
end
function ____exports.createActivityDiagnosticsPage(self, parent)
    local root = Native:createPanel(parent, theme.colors.background, theme.colors.borderStrong)
    root.frame:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        200,
        -88
    )
    root.frame:SetPoint(
        "BOTTOMRIGHT",
        parent,
        "BOTTOMRIGHT",
        -16,
        16
    )
    root.frame:Hide()
    local eyebrow = Native:createText(root.frame, "DEVELOPMENT HEALTH", "GameFontNormalSmall", theme.colors.muted)
    eyebrow:SetPoint(
        "TOPLEFT",
        root.frame,
        "TOPLEFT",
        22,
        -18
    )
    local title = Native:createText(root.frame, "Activity Diagnostics", "GameFontNormalLarge")
    title:SetPoint(
        "TOPLEFT",
        eyebrow,
        "BOTTOMLEFT",
        0,
        -8
    )
    local subtitle = Native:createText(root.frame, "Validate every Group Composer dungeon and raid against the server catalog, maps, entrance triggers, raid contracts and clear-history metadata.", "GameFontHighlightSmall", theme.colors.muted)
    subtitle:SetPoint(
        "TOPLEFT",
        title,
        "BOTTOMLEFT",
        0,
        -6
    )
    subtitle:SetWidth(980)
    local refreshButton = ButtonUI:createButton(
        root.frame,
        {
            text = "Run Validation",
            width = 160,
            height = 36,
            accent = theme.colors.primary,
            emphasis = true,
            onClick = function() return Model:requestCatalogDiagnostics() end
        }
    )
    refreshButton.frame:SetPoint(
        "TOPRIGHT",
        root.frame,
        "TOPRIGHT",
        -22,
        -28
    )
    local summary = Native:createPanel(root.frame, theme.colors.surface, theme.colors.border)
    summary.frame:SetPoint(
        "TOPLEFT",
        root.frame,
        "TOPLEFT",
        22,
        -96
    )
    summary.frame:SetPoint(
        "TOPRIGHT",
        root.frame,
        "TOPRIGHT",
        -22,
        -96
    )
    summary.frame:SetHeight(70)
    local passText = Native:createText(summary.frame, "PASS 0", "GameFontNormal", theme.colors.success)
    passText:SetPoint(
        "LEFT",
        summary.frame,
        "LEFT",
        20,
        0
    )
    local warnText = Native:createText(summary.frame, "WARN 0", "GameFontNormal", theme.colors.warning)
    warnText:SetPoint(
        "LEFT",
        passText,
        "RIGHT",
        42,
        0
    )
    local failText = Native:createText(summary.frame, "FAIL 0", "GameFontNormal", theme.colors.error)
    failText:SetPoint(
        "LEFT",
        warnText,
        "RIGHT",
        42,
        0
    )
    local summaryText = Native:createText(summary.frame, "Not validated yet", "GameFontHighlightSmall", theme.colors.muted)
    summaryText:SetPoint(
        "RIGHT",
        summary.frame,
        "RIGHT",
        -20,
        0
    )
    summaryText:SetWidth(620)
    summaryText:SetJustifyH("RIGHT")
    local filterDefs = {{key = "PROBLEMS", label = "Problems"}, {key = "ALL", label = "All"}, {key = "PASS", label = "Passed"}}
    local filterButtons = {}
    local filter = "PROBLEMS"
    do
        local i = 0
        while i < #filterDefs do
            local def = filterDefs[i + 1]
            local button = ButtonUI:createButton(root.frame, {text = def.label, width = 118, height = 32, flat = true})
            button.frame:SetPoint(
                "TOPLEFT",
                root.frame,
                "TOPLEFT",
                22 + i * 126,
                -180
            )
            filterButtons[#filterButtons + 1] = button
            i = i + 1
        end
    end
    local scroll = ScrollUI:createScrollList(root.frame, 1260, 570)
    scroll.frame:SetPoint(
        "TOPLEFT",
        root.frame,
        "TOPLEFT",
        22,
        -222
    )
    local cards = {}
    local empty = Native:createText(scroll.content, "No entries match this filter.", "GameFontHighlight", theme.colors.muted)
    empty:SetPoint(
        "TOPLEFT",
        scroll.content,
        "TOPLEFT",
        20,
        -28
    )
    empty:SetWidth(1180)
    empty:SetJustifyH("CENTER")
    empty:Hide()
    local function filteredEntries(self)
        local entries = Model:catalogDiagnostics().entries
        local out = {}
        for ____, entry in ipairs(entries) do
            do
                local __continue10
                repeat
                    if filter == "PASS" and entry.status ~= "PASS" then
                        __continue10 = true
                        break
                    end
                    if filter == "PROBLEMS" and entry.status == "PASS" then
                        __continue10 = true
                        break
                    end
                    out[#out + 1] = entry
                    __continue10 = true
                until true
                if not __continue10 then
                    break
                end
            end
        end
        return out
    end
    local function refresh(self)
        local state = Model:catalogDiagnostics()
        passText:SetText("PASS " .. tostring(state.pass))
        warnText:SetText("WARN " .. tostring(state.warn))
        failText:SetText("FAIL " .. tostring(state.fail))
        summaryText:SetText(state.ready and (state.fail > 0 and "Structural failures found. Fix these before trusting every listed activity." or (state.warn > 0 and "No structural failures. Warnings identify experimental/partial support." or "Every catalog entry passed structural validation.")) or "Validation has not completed yet.")
        do
            local i = 0
            while i < #filterButtons do
                filterButtons[i + 1]:setSelected(filterDefs[i + 1].key == filter)
                i = i + 1
            end
        end
        for ____, card in ipairs(cards) do
            card.panel.frame:Hide()
        end
        local rows = filteredEntries(nil)
        if #rows == 0 then
            empty:Show()
        else
            empty:Hide()
        end
        do
            local i = 0
            while i < #rows do
                local card = cards[i + 1]
                if card == nil then
                    local panel = Native:createPanel(scroll.content, theme.colors.surfaceRaised, theme.colors.border)
                    panel.frame:SetSize(606, 102)
                    local iconBadge = Native:createFramedIcon(panel.frame, "Interface\\Icons\\INV_Misc_Map_01", 44, theme.colors.borderStrong)
                    iconBadge.frame:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        14,
                        -15
                    )
                    local cardTitle = Native:createText(panel.frame, "", "GameFontNormal")
                    cardTitle:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        70,
                        -12
                    )
                    cardTitle:SetWidth(330)
                    local status = Native:createText(panel.frame, "", "GameFontNormalSmall")
                    status:SetPoint(
                        "TOPRIGHT",
                        panel.frame,
                        "TOPRIGHT",
                        -14,
                        -14
                    )
                    status:SetWidth(90)
                    status:SetJustifyH("RIGHT")
                    local meta = Native:createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted)
                    meta:SetPoint(
                        "TOPLEFT",
                        cardTitle,
                        "BOTTOMLEFT",
                        0,
                        -4
                    )
                    meta:SetWidth(420)
                    local detail = Native:createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted)
                    detail:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        14,
                        -64
                    )
                    detail:SetWidth(572)
                    detail:SetHeight(30)
                    detail:SetJustifyV("TOP")
                    scroll:bindWheel(panel.frame)
                    card = {
                        panel = panel,
                        iconBadge = iconBadge,
                        title = cardTitle,
                        status = status,
                        meta = meta,
                        detail = detail
                    }
                    cards[i + 1] = card
                end
                local entry = rows[i + 1]
                local column = i % 2
                local row = math.floor(i / 2)
                local accent = statusAccent(nil, entry.status)
                card.panel.frame:ClearAllPoints()
                card.panel.frame:SetPoint(
                    "TOPLEFT",
                    scroll.content,
                    "TOPLEFT",
                    column * 620,
                    -(row * 110)
                )
                card.iconBadge.icon:SetTexture(Model:activityIconFor(entry.id, entry.mode))
                card.iconBadge.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                card.iconBadge.outline:setColor(accent)
                card.title:SetText(entry.label)
                card.status:SetText(entry.status)
                card.status:SetTextColor(accent[1], accent[2], accent[3], 1)
                card.meta:SetText((((entry.era .. " · ") .. (entry.mode == "RAID" and "Raid" or "Dungeon")) .. " · ") .. entry.id)
                card.detail:SetText(entry.detail)
                card.panel.frame:Show()
                i = i + 1
            end
        end
        scroll:setContentHeight(math.max(
            570,
            math.ceil(#rows / 2) * 110
        ))
    end
    do
        local i = 0
        while i < #filterDefs do
            local def = filterDefs[i + 1]
            filterButtons[i + 1].frame:SetScript(
                "OnMouseDown",
                function()
                    filter = def.key
                    scroll:scrollToTop()
                    refresh(nil)
                end
            )
            i = i + 1
        end
    end
    Model:composer():RegisterCallback(
        "CATALOG_DIAGNOSTICS_CHANGED",
        function()
            if root.frame:IsShown() then
                refresh(nil)
            end
        end
    )
    return {
        frame = root.frame,
        show = function()
            root.frame:Show()
            scroll:scrollToTop()
            refresh(nil)
            Model:requestCatalogDiagnostics()
        end,
        hide = function() return root.frame:Hide() end,
        refresh = refresh
    }
end
return ____exports
 end,
["widgets.Toggle"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____Native = require("core.Native")
local createOutline = ____Native.createOutline
local createSolid = ____Native.createSolid
local createText = ____Native.createText
local setTextureColor = ____Native.setTextureColor
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
function ____exports.createToggle(self, parent, label, getValue, setValue)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(30)
    frame:EnableMouse(true)
    local box = CreateFrame("Frame", nil, frame)
    box:SetSize(22, 22)
    box:SetPoint(
        "LEFT",
        frame,
        "LEFT",
        0,
        0
    )
    local boxBg = createSolid(nil, box, theme.colors.surfaceDeep)
    boxBg:SetAllPoints(box)
    local boxOutline = createOutline(nil, box, theme.colors.borderStrong)
    local check = box:CreateTexture(nil, "OVERLAY")
    check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    check:SetPoint(
        "TOPLEFT",
        box,
        "TOPLEFT",
        -3,
        3
    )
    check:SetPoint(
        "BOTTOMRIGHT",
        box,
        "BOTTOMRIGHT",
        3,
        -3
    )
    check:SetVertexColor(theme.colors.success[1], theme.colors.success[2], theme.colors.success[3], 1)
    local text = createText(nil, frame, label, "GameFontHighlightSmall")
    text:SetPoint(
        "LEFT",
        box,
        "RIGHT",
        10,
        0
    )
    local function refresh(self)
        local enabled = getValue(nil)
        if enabled then
            check:Show()
            setTextureColor(nil, boxBg, theme.colors.surfaceBlue)
            boxOutline:setColor(theme.colors.success)
            text:SetTextColor(theme.colors.text[1], theme.colors.text[2], theme.colors.text[3], 1)
        else
            check:Hide()
            setTextureColor(nil, boxBg, theme.colors.surfaceDeep)
            boxOutline:setColor(theme.colors.borderStrong)
            text:SetTextColor(theme.colors.muted[1], theme.colors.muted[2], theme.colors.muted[3], 1)
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
-- End of Lua Library inline imports
local ____exports = {}
local BuildSelectorUI = require("components.BuildSelector")
local ActivityBrowserUI = require("components.ActivityBrowser")
local TemplateBrowserUI = require("components.TemplateBrowser")
local ProgressionPageUI = require("components.ProgressionPage")
local RecommendationsPageUI = require("components.RecommendationsPage")
local MemberDetailsUI = require("components.MemberDetailsModal")
local GroupActionsUI = require("components.GroupActionsModal")
local ActivityDiagnosticsUI = require("components.ActivityDiagnosticsPage")
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
local ICON_DUNGEON = "Interface\\Icons\\Spell_Arcane_PortalDalaran"
local ICON_RAID = "Interface\\Icons\\Achievement_Boss_LichKing"
local ICON_TEMPLATES = "Interface\\Icons\\INV_Scroll_03"
local ICON_PEOPLE = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02"
local ICON_OPTIONS = "Interface\\Icons\\INV_Gizmo_02"
local ICON_COVERAGE = "Interface\\Icons\\INV_Misc_Map_01"
local function colorForPhase(self, phase)
    if phase == "READY" or phase == "ASSEMBLED" or phase == "DONE" then
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
local function roleDescription(self, role)
    if role == "TANK" then
        return "Durable heroes who hold threat and keep danger away from the raid."
    end
    if role == "HEALER" then
        return "Keep the raid alive with healing, dispels and support."
    end
    return "Deal damage while Composer preserves the raid's class and utility needs."
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
                local __continue16
                repeat
                    local human = anchors[h + 1]
                    local ____opt_6 = Model:config().humanRoles
                    if ____opt_6 ~= nil then
                        ____opt_6 = ____opt_6[human.name]
                    end
                    local role = ____opt_6
                    if role == nil then
                        __continue16 = true
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
                    __continue16 = true
                until true
                if not __continue16 then
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
                local __continue26
                repeat
                    local role = sequence[i + 1]
                    local human = assigned[i + 1]
                    if human ~= nil then
                        result[#result + 1] = {role = role, human = human}
                        __continue26 = true
                        break
                    end
                    counters[role] = counters[role] + 1
                    local botIndex = counters[role]
                    local exact = flat[role][botIndex]
                    local prepared = preparedByRole[role][preparedIndex[role] + 1]
                    preparedIndex[role] = preparedIndex[role] + 1
                    result[#result + 1] = {role = role, botIndex = botIndex, exact = exact, prepared = prepared}
                    __continue26 = true
                until true
                if not __continue26 then
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
        return ((tostring(cfg.size) .. " player  ·  ") .. (cfg.difficulty == "heroic" and "Heroic" or "Normal")) .. "  ·  Teleport after assembly"
    end
    local mode = cfg.difficulty == "alpha" and "Titan Rune Alpha" or (cfg.difficulty == "beta" and "Titan Rune Beta" or (cfg.difficulty == "gamma" and "Titan Rune Gamma" or (cfg.difficulty == "heroic" and "Heroic" or "Normal")))
    return (mode .. "  ·  5 player  ·  ") .. (cfg.activity == "random" and "Dungeon Finder chooses destination" or "Teleport when ready")
end
function ____exports.createModernDashboard(self)
    local clearDynamicRows, refreshPeople, refreshActivity, refreshHumanPanel, refreshDungeon, refreshQuickRaid, refreshExactRaid, refreshRoster, refreshRaidTabs, refreshStatus, refresh, frame, memberDetails, backendGlow, backendDot, backendText, realmBadge, activePage, navDungeon, navRaid, navProgression, navRecommended, navDiagnostics, statusNotice, activity, activityBadge, activityName, activitySub, activityEligibility, activityFieldLabel, activityBrowse, difficultySelect, raidSizeLabel, raidSizeButtons, humanBadge, humanIcon, humanName, humanSub, humanRoleButtons, compositionTitle, compositionHint, selectorContext, buildSelector, dungeonView, dungeonRows, raidView, raidTab, tabQuick, tabExact, tabRoster, quickView, exactView, rosterView, quickCards, roleOrder, quickSummary, quickTotal, quickCheck, quickCheckIcon, quickCheckBang, quickStatusTitle, quickStatusDetail, exactScroll, exactSections, groupCards, phaseCard, phaseAccent, phaseGlow, phaseDot, phaseText, phaseDetail, rosterCount, sourceText, statusRoleChips, progressFill, progressText, coverageChips, coverageDamageText, nextCard, nextBadge, nextBang, warningsTitle, nextDetail, buildButton, teleportButton, assembleButton, resetButton, groupActionsButton, humanScroll, humanRowsModal, humanEmpty, pinRole, pinRoleButtons, pinToggle, pinScroll, pinRows, pinEmpty, progressionPage, diagnosticsPage, recommendationsPage
    function clearDynamicRows(self, rows)
        for ____, row in ipairs(rows) do
            row:Hide()
            row:ClearAllPoints()
        end
    end
    function refreshPeople(self)
        clearDynamicRows(nil, humanRowsModal)
        local list = Model:humans()
        if #list == 0 then
            humanEmpty:Show()
        else
            humanEmpty:Hide()
        end
        do
            local i = 0
            while i < #list do
                local human = list[i + 1]
                local row = humanRowsModal[i + 1]
                if row == nil then
                    local panel = Native:createPanel(humanScroll.content, theme.colors.surfaceRaised, theme.colors.border)
                    panel.frame:SetSize(412, 64)
                    local classBadge = Native:createFramedIcon(panel.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 34, theme.colors.borderStrong)
                    classBadge.frame:SetPoint(
                        "LEFT",
                        panel.frame,
                        "LEFT",
                        8,
                        0
                    )
                    local icon = classBadge.icon
                    local name = Native:createText(panel.frame, "", "GameFontHighlightSmall")
                    name:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        52,
                        -11
                    )
                    name:SetWidth(150)
                    local identity = Native:createText(panel.frame, "REAL PLAYER", "GameFontNormalSmall", theme.colors.primary)
                    identity:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        52,
                        -33
                    )
                    identity:SetWidth(150)
                    local buttons = {
                        TANK = ButtonUI:createButton(panel.frame, {text = "Tank", width = 62, height = 26, accent = theme.colors.tank}),
                        HEALER = ButtonUI:createButton(panel.frame, {text = "Healer", width = 62, height = 26, accent = theme.colors.healer}),
                        DPS = ButtonUI:createButton(panel.frame, {text = "DPS", width = 62, height = 26, accent = theme.colors.dps})
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
                        -5,
                        0
                    )
                    buttons.TANK.frame:SetPoint(
                        "RIGHT",
                        buttons.HEALER.frame,
                        "LEFT",
                        -5,
                        0
                    )
                    panel.frame._classBadge = classBadge
                    panel.frame._icon = icon
                    panel.frame._name = name
                    panel.frame._identity = identity
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
                    -(i * 70)
                )
                Native:setClassIcon(
                    row._icon,
                    tostring(human.class)
                )
                row._classBadge.outline:setColor(Native:classColor(tostring(human.class)))
                row._name:SetText((human.isPlayer and "YOU  ·  " or "") .. human.name)
                row._identity:SetText(Model:classLabel(tostring(human.class)) .. "  ·  REAL PLAYER")
                local ____opt_13 = Model:config().humanRoles
                if ____opt_13 ~= nil then
                    ____opt_13 = ____opt_13[human.name]
                end
                local selected = ____opt_13
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
        humanScroll:setContentHeight(math.max(430, #list * 70))
        for ____, role in ipairs(roleOrder) do
            pinRoleButtons[role]:setSelected(pinRole == role)
        end
        pinToggle:refresh()
        clearDynamicRows(nil, pinRows)
        local pins = Model:pinnedMembers()
        if #pins == 0 then
            pinEmpty:Show()
        else
            pinEmpty:Hide()
        end
        do
            local i = 0
            while i < #pins do
                local pin = pins[i + 1]
                local row = pinRows[i + 1]
                if row == nil then
                    local panel = Native:createPanel(pinScroll.content, theme.colors.surfaceRaised, theme.colors.border)
                    panel.frame:SetSize(412, 50)
                    local roleBadge = Native:createFramedRoleIcon(panel.frame, "DPS", 32, theme.colors.dps)
                    roleBadge.frame:SetPoint(
                        "LEFT",
                        panel.frame,
                        "LEFT",
                        8,
                        0
                    )
                    local name = Native:createText(panel.frame, "", "GameFontHighlightSmall")
                    name:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        50,
                        -9
                    )
                    name:SetWidth(220)
                    local info = Native:createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted)
                    info:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        50,
                        -29
                    )
                    info:SetWidth(220)
                    local remove = ButtonUI:createButton(panel.frame, {text = "Remove", width = 70, height = 28, accent = theme.colors.error})
                    remove.frame:SetPoint(
                        "RIGHT",
                        panel.frame,
                        "RIGHT",
                        -8,
                        0
                    )
                    panel.frame._roleBadge = roleBadge
                    panel.frame._roleIcon = roleBadge.icon
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
                    -(i * 56)
                )
                local pinAccent = Model:roleAccent(pin.role)
                Native:setRoleIcon(row._roleIcon, pin.role)
                row._roleBadge.outline:setColor(pinAccent)
                row._name:SetText(tostring(pin.name))
                row._info:SetText((Model:roleLabel(pin.role) .. "  ·  ") .. (pin.required and "REQUIRED" or "Preferred companion"))
                row._info:SetTextColor(pin.required and theme.colors.warning[1] or theme.colors.muted[1], pin.required and theme.colors.warning[2] or theme.colors.muted[2], pin.required and theme.colors.warning[3] or theme.colors.muted[3], 1)
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
        pinScroll:setContentHeight(math.max(270, #pins * 56))
    end
    function refreshActivity(self)
        local cfg = Model:config()
        activityName:SetText(Model:selectedActivityLabel())
        activitySub:SetText(activitySubtitle(nil))
        activityEligibility:SetText("ELIGIBILITY  ·  " .. Model:activityEligibilityText())
        activityBadge.icon:SetTexture(Model:selectedActivityIcon())
        activityBadge.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        activityFieldLabel:SetText(Model:config().mode == "RAID" and "RAID" or "DUNGEON")
        activityBrowse:setText(Model:config().mode == "RAID" and "Browse Raids" or "Browse Dungeons")
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
    function refreshHumanPanel(self)
        local list = Model:humans()
        local primary = #list > 0 and list[1] or nil
        if primary == nil then
            humanName:SetText("Waiting for player...")
            humanSub:SetText("Composer is refreshing human anchors.")
            humanBadge.frame:Hide()
            for ____, role in ipairs(roleOrder) do
                humanRoleButtons[role]:setEnabled(false)
            end
            return
        end
        humanBadge.frame:Show()
        Native:setClassIcon(
            humanIcon,
            tostring(primary.class)
        )
        humanBadge.outline:setColor(Native:classColor(tostring(primary.class)))
        humanName:SetText((primary.isPlayer and "YOU  ·  " or "") .. primary.name)
        humanSub:SetText(((("Level " .. tostring(primary.level or "?")) .. " ") .. Model:classLabel(tostring(primary.class))) .. (#list > 1 and (("  ·  +" .. tostring(#list - 1)) .. " more human anchor") .. (#list > 2 and "s" or "") or ""))
        local ____opt_26 = Model:config().humanRoles
        if ____opt_26 ~= nil then
            ____opt_26 = ____opt_26[primary.name]
        end
        local selected = ____opt_26
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
    function refreshDungeon(self)
        local slots = buildDungeonModel(nil)
        do
            local i = 0
            while i < #dungeonRows do
                do
                    local __continue162
                    repeat
                        local widgets = dungeonRows[i + 1]
                        local slot = slots[i + 1]
                        widgets.row.frame:EnableMouse(false)
                        widgets.row.frame:SetScript(
                            "OnMouseDown",
                            function()
                            end
                        )
                        local accent = Model:roleAccent(slot.role)
                        Native:setTextureColor(widgets.accent, accent)
                        widgets.row.outline:setColor(theme.colors.borderStrong)
                        Native:setRoleIcon(widgets.roleIcon, slot.role)
                        widgets.roleText:SetText(Model:roleLabel(slot.role))
                        widgets.roleText:SetTextColor(accent[1], accent[2], accent[3], 1)
                        widgets.slotText:SetText(slot.human ~= nil and "Human anchor" or "Bot slot " .. tostring(slot.botIndex or 1))
                        if slot.human ~= nil then
                            Native:setClassIcon(
                                widgets.classIcon,
                                tostring(slot.human.class)
                            )
                            widgets.classBadge.frame:Show()
                            widgets.classBadge.outline:setColor(Native:classColor(tostring(slot.human.class)))
                            widgets.specBadge.frame:Hide()
                            widgets.name:SetText((slot.human.isPlayer and "YOU  ·  " or "") .. tostring(slot.human.name))
                            local ____self_29 = widgets.sub
                            local ____self_29_SetText_30 = ____self_29.SetText
                            local ____slot_human_level_28 = slot.human.level
                            if ____slot_human_level_28 == nil then
                                ____slot_human_level_28 = "?"
                            end
                            ____self_29_SetText_30(
                                ____self_29,
                                (("Level " .. tostring(____slot_human_level_28)) .. " ") .. Model:classLabel(tostring(slot.human.class))
                            )
                            widgets.choose.frame:Hide()
                            widgets.auto.frame:Hide()
                            widgets.humanAnchor.frame:Show()
                            __continue162 = true
                            break
                        end
                        local exact = slot.exact
                        local prepared = slot.prepared
                        if prepared ~= nil and Model:plan().ready == true then
                            Native:setClassIcon(
                                widgets.classIcon,
                                tostring(prepared.class)
                            )
                            widgets.classBadge.frame:Show()
                            widgets.classBadge.outline:setColor(Native:classColor(tostring(prepared.class)))
                            local specId = specIdFromLabel(
                                nil,
                                tostring(prepared.class),
                                tostring(prepared.spec)
                            )
                            if specId ~= nil then
                                widgets.specIcon:SetTexture(Model:getSpecIcon(prepared.class, specId))
                                widgets.specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                                widgets.specBadge.frame:Show()
                            else
                                widgets.specBadge.frame:Hide()
                            end
                            widgets.name:SetText(tostring(prepared.name))
                            local ____self_34 = widgets.sub
                            local ____self_34_SetText_35 = ____self_34.SetText
                            local ____prepared_level_31 = prepared.level
                            if ____prepared_level_31 == nil then
                                ____prepared_level_31 = "?"
                            end
                            local ____temp_33 = ((("Lv " .. tostring(____prepared_level_31)) .. "  ·  ") .. tostring(prepared.spec or Model:classLabel(tostring(prepared.class)))) .. "  ·  "
                            local ____prepared_source_32 = prepared.source
                            if ____prepared_source_32 == nil then
                                ____prepared_source_32 = "Bot"
                            end
                            ____self_34_SetText_35(
                                ____self_34,
                                (____temp_33 .. tostring(____prepared_source_32)) .. "  ·  click for why"
                            )
                            local preparedCopy = prepared
                            widgets.row.frame:EnableMouse(true)
                            widgets.row.frame:SetScript(
                                "OnMouseDown",
                                function() return memberDetails:open(preparedCopy) end
                            )
                        elseif exact ~= nil then
                            Native:setClassIcon(widgets.classIcon, exact.classId)
                            widgets.classBadge.frame:Show()
                            widgets.classBadge.outline:setColor(Native:classColor(exact.classId))
                            widgets.specIcon:SetTexture(Model:getSpecIcon(exact.classId, exact.specId))
                            widgets.specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                            widgets.specBadge.frame:Show()
                            widgets.name:SetText((Model:getSpecLabel(exact.classId, exact.specId) .. " ") .. Model:classLabel(exact.classId))
                            widgets.sub:SetText("Exact build  ·  Composer will preserve this requirement")
                        else
                            widgets.classBadge.frame:Hide()
                            widgets.specBadge.frame:Hide()
                            widgets.name:SetText("Auto-fill bot")
                            widgets.sub:SetText(("Composer chooses a suitable " .. string.lower(Model:roleLabel(slot.role))) .. " build")
                        end
                        local roleCopy = slot.role
                        local botIndex = slot.botIndex or 1
                        widgets.humanAnchor.frame:Hide()
                        widgets.choose:setText(exact ~= nil and "Change build" or "Choose build")
                        widgets.choose.frame:SetScript(
                            "OnMouseDown",
                            function()
                                selectorContext = {mode = "DUNGEON", role = roleCopy, index = botIndex}
                                local ____buildSelector_open_37 = buildSelector.open
                                local ____temp_36
                                if exact == nil then
                                    ____temp_36 = nil
                                else
                                    ____temp_36 = {role = roleCopy, classId = exact.classId, specId = exact.specId, count = 1}
                                end
                                ____buildSelector_open_37(buildSelector, roleCopy, ____temp_36, false)
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
                        if exact ~= nil then
                            widgets.auto.frame:Show()
                        else
                            widgets.auto.frame:Hide()
                        end
                        __continue162 = true
                    until true
                    if not __continue162 then
                        break
                    end
                end
                i = i + 1
            end
        end
    end
    function refreshQuickRaid(self)
        local ____table_size_38 = Model:config().size
        if ____table_size_38 == nil then
            ____table_size_38 = 25
        end
        local size = __TS__Number(____table_size_38)
        local total = Model:roleTargetTotal()
        for ____, role in ipairs(roleOrder) do
            local target = Model:targetForRole(role)
            quickCards[role].count:SetText(tostring(target))
            quickCards[role].botSlots:SetText(((tostring(Model:remainingBotSlots(role)) .. " bot slots after humans\n(out of ") .. tostring(target)) .. ")")
            quickCards[role].minus:setEnabled(target > 0)
            quickCards[role].plus:setEnabled(target < size)
        end
        quickTotal:SetText((tostring(total) .. " / ") .. tostring(size))
        local valid = total == size
        local color = valid and theme.colors.success or theme.colors.warning
        quickTotal:SetTextColor(color[1], color[2], color[3], 1)
        quickSummary.outline:setColor(valid and theme.colors.borderStrong or theme.colors.warning)
        quickCheck.outline:setColor(color)
        if valid then
            quickCheckIcon:Show()
            quickCheckBang:Hide()
            quickStatusTitle:SetText("Raid composition is complete!")
            quickStatusTitle:SetTextColor(theme.colors.success[1], theme.colors.success[2], theme.colors.success[3], 1)
            quickStatusDetail:SetText(((((((("This setup will create a " .. tostring(size)) .. "-player raid with ") .. tostring(Model:targetForRole("TANK"))) .. " tanks, ") .. tostring(Model:targetForRole("HEALER"))) .. " healers, and ") .. tostring(Model:targetForRole("DPS"))) .. " DPS.")
        else
            quickCheckIcon:Hide()
            quickCheckBang:Show()
            quickStatusTitle:SetText("Role counts need attention")
            quickStatusTitle:SetTextColor(theme.colors.warning[1], theme.colors.warning[2], theme.colors.warning[3], 1)
            quickStatusDetail:SetText(("Adjust Tank, Healer and DPS until the total matches " .. tostring(size)) .. ".")
        end
    end
    function refreshExactRaid(self)
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
            for ____, key in ipairs(section.rowKeys) do
                local pooled = section.rowsByKey[key]
                if pooled ~= nil then
                    pooled.panel.frame:Hide()
                    pooled.panel.frame:ClearAllPoints()
                end
            end
            local sectionHeight = #rows == 0 and 88 or 66 + #rows * 58
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
                    local rowKey = (((role .. ":") .. tostring(build.classId)) .. ":") .. tostring(build.specId)
                    local widgets = section.rowsByKey[rowKey]
                    if widgets == nil then
                        local panel = Native:createPanel(section.panel.frame, theme.colors.surfaceRaised, theme.colors.border)
                        panel.frame:SetSize(870, 52)
                        local classBadge = Native:createFramedIcon(panel.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 34, theme.colors.borderStrong)
                        classBadge.frame:SetPoint(
                            "LEFT",
                            panel.frame,
                            "LEFT",
                            10,
                            0
                        )
                        local classIcon = classBadge.icon
                        local specBadge = Native:createFramedIcon(panel.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 34, theme.colors.borderStrong)
                        specBadge.frame:SetPoint(
                            "LEFT",
                            classBadge.frame,
                            "RIGHT",
                            6,
                            0
                        )
                        local specIcon = specBadge.icon
                        local name = Native:createText(panel.frame, "", "GameFontNormal")
                        name:SetPoint(
                            "TOPLEFT",
                            panel.frame,
                            "TOPLEFT",
                            94,
                            -8
                        )
                        name:SetWidth(500)
                        local info = Native:createText(
                            panel.frame,
                            Model:roleLabel(role) .. "  ·  Reserved build",
                            "GameFontHighlightSmall",
                            theme.colors.muted
                        )
                        info:SetPoint(
                            "TOPLEFT",
                            panel.frame,
                            "TOPLEFT",
                            94,
                            -29
                        )
                        info:SetWidth(440)
                        local countPill = Native:createPanel(
                            panel.frame,
                            theme.colors.surfaceDeep,
                            Model:roleAccent(role)
                        )
                        countPill.frame:SetSize(52, 26)
                        countPill.frame:SetPoint(
                            "RIGHT",
                            panel.frame,
                            "RIGHT",
                            -120,
                            0
                        )
                        local count = Native:createText(
                            countPill.frame,
                            "",
                            "GameFontHighlightSmall",
                            Model:roleAccent(role)
                        )
                        count:SetPoint(
                            "CENTER",
                            countPill.frame,
                            "CENTER",
                            0,
                            0
                        )
                        count:SetWidth(46)
                        count:SetJustifyH("CENTER")
                        local edit = ButtonUI:createButton(panel.frame, {text = "Edit", width = 62, height = 28, accent = theme.colors.primary})
                        edit.frame:SetPoint(
                            "RIGHT",
                            panel.frame,
                            "RIGHT",
                            -48,
                            0
                        )
                        local remove = ButtonUI:createButton(panel.frame, {text = "X", width = 34, height = 28, accent = theme.colors.error})
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
                            classBadge = classBadge,
                            classIcon = classIcon,
                            specBadge = specBadge,
                            specIcon = specIcon,
                            name = name,
                            info = info,
                            countPill = countPill,
                            count = count,
                            edit = edit,
                            remove = remove
                        }
                        section.rowsByKey[rowKey] = widgets
                        local ____section_rowKeys_39 = section.rowKeys
                        ____section_rowKeys_39[#____section_rowKeys_39 + 1] = rowKey
                    end
                    widgets.panel.frame:ClearAllPoints()
                    widgets.panel.frame:SetPoint(
                        "TOPLEFT",
                        section.panel.frame,
                        "TOPLEFT",
                        18,
                        -(58 + i * 58)
                    )
                    Native:setClassIcon(widgets.classIcon, build.classId)
                    widgets.classBadge.outline:setColor(Native:classColor(build.classId))
                    widgets.specBadge.outline:setColor(theme.colors.primary)
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
                        function()
                            widgets.panel.frame:Hide()
                            widgets.panel.frame:ClearAllPoints()
                            Model:removeRequiredBuild(roleCopy, indexCopy)
                        end
                    )
                    widgets.panel.frame:Show()
                    i = i + 1
                end
            end
            cursor = cursor + (sectionHeight + 12)
        end
        exactScroll:setContentHeight(math.max(418, cursor))
    end
    function refreshRoster(self)
        local cfg = Model:config()
        local ____cfg_size_40 = cfg.size
        if ____cfg_size_40 == nil then
            ____cfg_size_40 = 5
        end
        local totalGroups = math.max(
            1,
            math.ceil(__TS__Number(____cfg_size_40) / 5)
        )
        local columns = totalGroups <= 3 and totalGroups or (totalGroups <= 5 and 3 or 4)
        local cardWidth = math.floor((934 - (columns - 1) * 10) / columns)
        local cardHeight = 214
        do
            local g = 0
            while g < #groupCards do
                do
                    local __continue198
                    repeat
                        local widgets = groupCards[g + 1]
                        if g >= totalGroups then
                            widgets.card.frame:Hide()
                            __continue198 = true
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
                            -(6 + row * (cardHeight + 10))
                        )
                        widgets.card.frame:SetSize(cardWidth, cardHeight)
                        widgets.groupTitle:SetText("GROUP " .. tostring(g + 1))
                        local members = {}
                        for ____, member in ipairs(Model:planMembers()) do
                            if __TS__Number(member.subgroup) == g + 1 then
                                members[#members + 1] = member
                            end
                        end
                        widgets.groupCount:SetText(tostring(#members) .. " / 5")
                        widgets.groupCount:SetTextColor(#members == 5 and theme.colors.success[1] or theme.colors.primary[1], #members == 5 and theme.colors.success[2] or theme.colors.primary[2], #members == 5 and theme.colors.success[3] or theme.colors.primary[3], 1)
                        do
                            local r = 0
                            while r < 5 do
                                local rowWidgets = widgets.rows[r + 1]
                                local member = members[r + 1]
                                local textWidth = math.max(82, cardWidth - 80)
                                rowWidgets.name:SetWidth(textWidth)
                                rowWidgets.spec:SetWidth(textWidth)
                                if member == nil then
                                    rowWidgets.row:EnableMouse(false)
                                    rowWidgets.row:SetScript(
                                        "OnMouseDown",
                                        function()
                                        end
                                    )
                                    rowWidgets.iconBadge.frame:Hide()
                                    rowWidgets.roleIcon:Hide()
                                    rowWidgets.name:SetText("Empty slot")
                                    rowWidgets.name:SetTextColor(theme.colors.muted[1], theme.colors.muted[2], theme.colors.muted[3], 0.72)
                                    rowWidgets.spec:SetText("")
                                    Native:setTextureColor(rowWidgets.roleBar, theme.colors.borderStrong)
                                    Native:setTextureColor(
                                        rowWidgets.rowBg,
                                        Native:withAlpha(theme.colors.surfaceRaised, 0.32)
                                    )
                                else
                                    local role = member.role
                                    local accent = Model:roleAccent(role)
                                    Native:setClassIcon(
                                        rowWidgets.icon,
                                        tostring(member.class)
                                    )
                                    rowWidgets.iconBadge.outline:setColor(Native:classColor(tostring(member.class)))
                                    rowWidgets.iconBadge.frame:Show()
                                    Native:setRoleIcon(rowWidgets.roleIcon, role)
                                    rowWidgets.roleIcon:Show()
                                    local identity = member.isPlayer and "YOU  ·  " or (member.pinned and "PINNED  ·  " or "")
                                    rowWidgets.name:SetText(identity .. tostring(member.name))
                                    rowWidgets.name:SetTextColor(theme.colors.text[1], theme.colors.text[2], theme.colors.text[3], 1)
                                    local ____self_44 = rowWidgets.spec
                                    local ____self_44_SetText_45 = ____self_44.SetText
                                    local ____member_level_41 = member.level
                                    if ____member_level_41 == nil then
                                        ____member_level_41 = "?"
                                    end
                                    local ____temp_43 = ("Lv " .. tostring(____member_level_41)) .. "  ·  "
                                    local ____member_spec_42 = member.spec
                                    if ____member_spec_42 == nil then
                                        ____member_spec_42 = Model:classLabel(tostring(member.class))
                                    end
                                    ____self_44_SetText_45(
                                        ____self_44,
                                        (____temp_43 .. tostring(____member_spec_42)) .. "  ·  click for why"
                                    )
                                    local memberCopy = member
                                    rowWidgets.row:EnableMouse(true)
                                    rowWidgets.row:SetScript(
                                        "OnMouseDown",
                                        function() return memberDetails:open(memberCopy) end
                                    )
                                    rowWidgets.spec:SetTextColor(theme.colors.muted[1], theme.colors.muted[2], theme.colors.muted[3], 1)
                                    Native:setTextureColor(rowWidgets.roleBar, accent)
                                    Native:setTextureColor(
                                        rowWidgets.rowBg,
                                        Native:withAlpha(accent, member.isPlayer and 0.1 or 0.045)
                                    )
                                end
                                r = r + 1
                            end
                        end
                        widgets.card.frame:Show()
                        __continue198 = true
                    until true
                    if not __continue198 then
                        break
                    end
                end
                g = g + 1
            end
        end
    end
    function refreshRaidTabs(self)
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
    function refreshStatus(self)
        local p = Model:progress()
        local ____p_phase_46 = p.phase
        if ____p_phase_46 == nil then
            ____p_phase_46 = "IDLE"
        end
        local phase = tostring(____p_phase_46)
        local phaseColor = colorForPhase(nil, phase)
        Native:setTextureColor(phaseDot, phaseColor)
        Native:setTextureColor(phaseAccent, phaseColor)
        Native:setTextureColor(
            phaseGlow,
            Native:withAlpha(phaseColor, 0.16)
        )
        phaseCard.outline:setColor(phase == "ERROR" and theme.colors.error or theme.colors.borderStrong)
        phaseText:SetText(Model:phaseLabel(phase))
        phaseText:SetTextColor(phaseColor[1], phaseColor[2], phaseColor[3], 1)
        if phase == "IDLE" then
            phaseDetail:SetText(Model:config().mode == "RAID" and "Add specific builds or keep Auto to prepare your raid." or "Choose exact builds or keep Auto to prepare your group.")
        elseif (phase == "ASSEMBLED" or phase == "TRAVEL") and statusNotice ~= "" then
            phaseDetail:SetText(statusNotice)
        else
            local ____phaseDetail_SetText_48 = phaseDetail.SetText
            local ____p_detail_47 = p.detail
            if ____p_detail_47 == nil then
                ____p_detail_47 = ""
            end
            ____phaseDetail_SetText_48(
                phaseDetail,
                tostring(____p_detail_47)
            )
        end
        local humanCount = #Model:humans()
        local ____table_size_49 = Model:config().size
        if ____table_size_49 == nil then
            ____table_size_49 = 5
        end
        local target = __TS__Number(____table_size_49)
        local composed = Model:config().mode == "RAID" and Model:roleTargetTotal() or humanCount
        local ____temp_53
        if Model:plan().ready == true then
            local ____opt_50 = Model:plan().summary
            if ____opt_50 ~= nil then
                ____opt_50 = ____opt_50.total
            end
            local ____opt_50_52 = ____opt_50
            if ____opt_50_52 == nil then
                ____opt_50_52 = #Model:planMembers()
            end
            ____temp_53 = __TS__Number(____opt_50_52)
        else
            ____temp_53 = composed
        end
        local total = ____temp_53
        rosterCount:SetText((tostring(total) .. " / ") .. tostring(target))
        if Model:plan().ready == true then
            local ____sourceText_SetText_62 = sourceText.SetText
            local ____temp_57 = ((tostring(humanCount) .. " human") .. (humanCount == 1 and "" or "s")) .. "  ·  "
            local ____opt_54 = Model:plan().summary
            if ____opt_54 ~= nil then
                ____opt_54 = ____opt_54.guild
            end
            local ____opt_54_56 = ____opt_54
            if ____opt_54_56 == nil then
                ____opt_54_56 = 0
            end
            local ____temp_61 = (____temp_57 .. tostring(____opt_54_56)) .. " guild  ·  "
            local ____opt_58 = Model:plan().summary
            if ____opt_58 ~= nil then
                ____opt_58 = ____opt_58.world
            end
            local ____opt_58_60 = ____opt_58
            if ____opt_58_60 == nil then
                ____opt_58_60 = 0
            end
            ____sourceText_SetText_62(
                sourceText,
                (____temp_61 .. tostring(____opt_58_60)) .. " fallback"
            )
        else
            sourceText:SetText(((((tostring(humanCount) .. " human") .. (humanCount == 1 and "" or "s")) .. "  ·  ") .. tostring(math.max(0, target - humanCount))) .. " bot slots")
        end
        local ____self_64 = statusRoleChips.TANK.label
        local ____self_64_SetText_65 = ____self_64.SetText
        local ____table_tanks_63 = Model:config().tanks
        if ____table_tanks_63 == nil then
            ____table_tanks_63 = 0
        end
        ____self_64_SetText_65(
            ____self_64,
            tostring(____table_tanks_63) .. " TANK"
        )
        local ____self_67 = statusRoleChips.HEALER.label
        local ____self_67_SetText_68 = ____self_67.SetText
        local ____table_healers_66 = Model:config().healers
        if ____table_healers_66 == nil then
            ____table_healers_66 = 0
        end
        ____self_67_SetText_68(
            ____self_67,
            tostring(____table_healers_66) .. " HEALER"
        )
        local ____self_70 = statusRoleChips.DPS.label
        local ____self_70_SetText_71 = ____self_70.SetText
        local ____table_dps_69 = Model:config().dps
        if ____table_dps_69 == nil then
            ____table_dps_69 = 0
        end
        ____self_70_SetText_71(
            ____self_70,
            tostring(____table_dps_69) .. " DPS"
        )
        local ratio = 0
        local ____p_total_72 = p.total
        if ____p_total_72 == nil then
            ____p_total_72 = 0
        end
        if __TS__Number(____p_total_72) > 0 then
            local ____p_current_73 = p.current
            if ____p_current_73 == nil then
                ____p_current_73 = 0
            end
            ratio = math.min(
                1,
                __TS__Number(____p_current_73) / __TS__Number(p.total)
            )
        elseif phase == "READY" or phase == "ASSEMBLED" or phase == "DONE" then
            ratio = 1
        elseif phase == "IDLE" and target > 0 then
            ratio = math.min(1, total / target)
        end
        progressFill:SetWidth(math.max(1, 266 * ratio))
        Native:setTextureColor(progressFill, phaseColor)
        local ____progressText_SetText_80 = progressText.SetText
        local ____temp_79
        if phase == "PREPARING" or phase == "ASSEMBLING" or phase == "READY" or phase == "ASSEMBLED" or phase == "TRAVEL" or phase == "DONE" then
            local ____p_current_74 = p.current
            if ____p_current_74 == nil then
                ____p_current_74 = 0
            end
            local ____temp_76 = tostring(____p_current_74) .. " / "
            local ____p_total_75 = p.total
            if ____p_total_75 == nil then
                ____p_total_75 = 0
            end
            local ____temp_78 = (____temp_76 .. tostring(____p_total_75)) .. "  ·  "
            local ____p_detail_77 = p.detail
            if ____p_detail_77 == nil then
                ____p_detail_77 = ""
            end
            ____temp_79 = ____temp_78 .. tostring(____p_detail_77)
        else
            ____temp_79 = ""
        end
        ____progressText_SetText_80(progressText, ____temp_79)
        local ____opt_81 = Model:plan().summary
        if ____opt_81 ~= nil then
            ____opt_81 = ____opt_81.utility
        end
        local ____opt_81_83 = ____opt_81
        if ____opt_81_83 == nil then
            ____opt_81_83 = ""
        end
        local utilityRaw = tostring(____opt_81_83)
        local ____opt_84 = Model:plan().summary
        if ____opt_84 ~= nil then
            ____opt_84 = ____opt_84.utility
        end
        local hasPreparedCoverage = ____opt_84 ~= nil
        do
            local i = 0
            while i < #coverageChips do
                local widgets = coverageChips[i + 1]
                local covered = hasPreparedCoverage and (string.find(
                    utilityRaw,
                    tostring(widgets.token),
                    nil,
                    true
                ) or 0) - 1 >= 0
                widgets.panel:setBackground(covered and theme.colors.surfaceBlue or theme.colors.surfaceDeep)
                widgets.panel.outline:setColor(covered and theme.colors.success or theme.colors.border)
                if covered then
                    widgets.check:Show()
                else
                    widgets.check:Hide()
                end
                widgets.label:SetTextColor(covered and theme.colors.text[1] or theme.colors.muted[1], covered and theme.colors.text[2] or theme.colors.muted[2], covered and theme.colors.text[3] or theme.colors.muted[3], covered and 1 or 0.82)
                i = i + 1
            end
        end
        local ____coverageDamageText_SetText_94 = coverageDamageText.SetText
        local ____hasPreparedCoverage_93
        if hasPreparedCoverage then
            local ____opt_86 = Model:plan().summary
            if ____opt_86 ~= nil then
                ____opt_86 = ____opt_86.ranged
            end
            local ____opt_86_88 = ____opt_86
            if ____opt_86_88 == nil then
                ____opt_86_88 = 0
            end
            local ____temp_92 = ("Ranged DPS  " .. tostring(____opt_86_88)) .. "   ·   Melee DPS  "
            local ____opt_89 = Model:plan().summary
            if ____opt_89 ~= nil then
                ____opt_89 = ____opt_89.melee
            end
            local ____opt_89_91 = ____opt_89
            if ____opt_89_91 == nil then
                ____opt_89_91 = 0
            end
            ____hasPreparedCoverage_93 = ____temp_92 .. tostring(____opt_89_91)
        else
            ____hasPreparedCoverage_93 = "Prepare a roster to inspect utility."
        end
        ____coverageDamageText_SetText_94(coverageDamageText, ____hasPreparedCoverage_93)
        local warnings = Model:planWarnings()
        local selectedAccess = Model:selectedActivityEligibility()
        local nextText = ""
        if not selectedAccess.known then
            nextText = "Checking whether this character can enter the selected activity..."
        elseif not selectedAccess.eligible then
            nextText = "Selected activity is locked.\n" .. selectedAccess.reason
        elseif phase == "ERROR" then
            nextText = "Adjust the highlighted requirement, then Build & Prepare again."
        elseif not Model:humanReady() then
            nextText = "Choose a legal role for every real player."
        else
            local ____temp_97 = Model:config().mode == "RAID"
            if ____temp_97 then
                local ____temp_96 = Model:roleTargetTotal()
                local ____table_size_95 = Model:config().size
                if ____table_size_95 == nil then
                    ____table_size_95 = 25
                end
                ____temp_97 = ____temp_96 ~= __TS__Number(____table_size_95)
            end
            if ____temp_97 then
                local ____table_size_98 = Model:config().size
                if ____table_size_98 == nil then
                    ____table_size_98 = 25
                end
                nextText = ("Role counts must total " .. tostring(____table_size_98)) .. " before preparing."
            elseif phase == "DONE" and Model:isAssembled() then
                nextText = "Group is assembled and the latest lifecycle action completed. Use Group Actions to repair, leave the instance together, or disband safely."
            elseif phase == "ASSEMBLED" then
                nextText = Model:hasFixedActivityDestination() and "Group assembled. Press Teleport to Instance when everyone is ready." or "Group assembled. Dungeon Finder can choose the destination."
            elseif phase == "READY" then
                nextText = "Prepared roster is ready for review. Assemble when it looks right."
            elseif phase == "PREPARING" then
                nextText = "Composer is provisioning and validating the selected bots."
            else
                nextText = "Build & Prepare when the composition looks right."
            end
        end
        if #warnings > 0 then
            nextText = nextText .. "\n" .. tostring(warnings[1])
        end
        if phase == "IDLE" and statusNotice ~= "" then
            nextText = nextText .. "\n" .. statusNotice
        end
        local nextColor = phase == "ERROR" and theme.colors.error or ((phase == "READY" or phase == "ASSEMBLED") and theme.colors.success or theme.colors.warning)
        nextCard.outline:setColor((phase == "ERROR" or phase == "READY") and nextColor or theme.colors.border)
        nextBadge.outline:setColor(nextColor)
        nextBang:SetText((phase == "READY" or phase == "ASSEMBLED") and ">" or "!")
        nextBang:SetTextColor(nextColor[1], nextColor[2], nextColor[3], 1)
        warningsTitle:SetText(phase == "ERROR" and "ACTION REQUIRED" or (phase == "PREPARING" and "PREPARING" or "NEXT STEP"))
        warningsTitle:SetTextColor(nextColor[1], nextColor[2], nextColor[3], 1)
        nextDetail:SetTextColor(nextColor[1], nextColor[2], nextColor[3], 1)
        nextDetail:SetText(nextText)
        local assembled = Model:isAssembled()
        local activityAvailable = selectedAccess.known and selectedAccess.eligible
        local canTeleport = phase == "ASSEMBLED" and activityAvailable and Model:hasFixedActivityDestination()
        local ____buildButton_setEnabled_103 = buildButton.setEnabled
        local ____temp_102 = activityAvailable and Model:humanReady() and not Model:isBusy() and not assembled
        if ____temp_102 then
            local ____temp_101 = Model:config().mode ~= "RAID"
            if not ____temp_101 then
                local ____temp_100 = Model:roleTargetTotal()
                local ____table_size_99 = Model:config().size
                if ____table_size_99 == nil then
                    ____table_size_99 = 25
                end
                ____temp_101 = ____temp_100 == __TS__Number(____table_size_99)
            end
            ____temp_102 = ____temp_101
        end
        ____buildButton_setEnabled_103(buildButton, ____temp_102)
        if assembled then
            buildButton.frame:Hide()
        else
            buildButton.frame:Show()
        end
        teleportButton:setEnabled(canTeleport)
        if canTeleport then
            teleportButton.frame:Show()
        else
            teleportButton.frame:Hide()
        end
        assembleButton:setEnabled(Model:plan().ready == true and Model:plan().valid == true and phase == "READY")
        assembleButton:setText(Model:config().mode == "RAID" and "Assemble Raid" or "Assemble Party")
        assembleButton:setSelected(Model:plan().ready == true and Model:plan().valid == true and phase == "READY")
        if assembled then
            assembleButton.frame:Hide()
            resetButton.frame:Hide()
            groupActionsButton.frame:Show()
        else
            assembleButton.frame:Show()
            resetButton.frame:Show()
            groupActionsButton.frame:Hide()
        end
    end
    function refresh(self)
        if not frame:IsShown() then
            return
        end
        local raid = Model:config().mode == "RAID"
        navDungeon:setSelected(activePage == "COMPOSER" and not raid)
        navRaid:setSelected(activePage == "COMPOSER" and raid)
        navProgression:setSelected(activePage == "PROGRESSION")
        navRecommended:setSelected(activePage == "RECOMMENDED")
        navDiagnostics:setSelected(activePage == "DIAGNOSTICS")
        local realm = Model:realm()
        realmBadge:SetText((string.upper(tostring(realm.era)) .. " · CAP ") .. tostring(realm.levelCap))
        local realmColor = realm.era == "Vanilla" and theme.colors.warning or (realm.era == "TBC" and theme.colors.success or theme.colors.primary)
        realmBadge:SetTextColor(realmColor[1], realmColor[2], realmColor[3], 1)
        backendText:SetText(GC.backendSeen == true and "Backend connected" or "Checking backend")
        Native:setTextureColor(backendDot, GC.backendSeen == true and theme.colors.success or theme.colors.muted)
        if GC.backendSeen == true then
            backendGlow:Show()
        else
            backendGlow:Hide()
        end
        if activePage ~= "COMPOSER" then
            if activePage == "PROGRESSION" then
                progressionPage:refresh()
            elseif activePage == "DIAGNOSTICS" then
                diagnosticsPage:refresh()
            else
                recommendationsPage:refresh()
            end
            return
        end
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
    frame = CreateFrame("Frame", "GroupComposerModernFrame", UIParent)
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
        function() return frame:StartMoving() end
    )
    frame:SetScript(
        "OnDragStop",
        function() return frame:StopMovingOrSizing() end
    )
    frame:Hide()
    memberDetails = MemberDetailsUI:createMemberDetailsModal(frame)
    local groupActions = GroupActionsUI:createGroupActionsModal(frame)
    local root = Native:createSolid(frame, theme.colors.background)
    root:SetAllPoints(frame)
    Native:createChrome(frame, theme.colors.chrome, true)
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
    header.frame:SetHeight(72)
    local headerAccent = Native:createSolid(header.frame, theme.colors.primary, "OVERLAY")
    headerAccent:SetPoint(
        "TOPLEFT",
        header.frame,
        "TOPLEFT",
        0,
        0
    )
    headerAccent:SetPoint(
        "TOPRIGHT",
        header.frame,
        "TOPRIGHT",
        0,
        0
    )
    headerAccent:SetHeight(2)
    local mark = Native:createPanel(header.frame, theme.colors.surfaceBlue, theme.colors.primary)
    mark.frame:SetSize(48, 48)
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
        82,
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
    backendGlow = Native:createSolid(
        header.frame,
        Native:withAlpha(theme.colors.success, 0.18),
        "ARTWORK"
    )
    backendGlow:SetSize(18, 18)
    backendGlow:SetPoint(
        "RIGHT",
        header.frame,
        "RIGHT",
        -326,
        0
    )
    backendGlow:Hide()
    backendDot = Native:createSolid(header.frame, theme.colors.muted, "OVERLAY")
    backendDot:SetSize(8, 8)
    backendDot:SetPoint(
        "RIGHT",
        header.frame,
        "RIGHT",
        -331,
        0
    )
    backendText = Native:createText(header.frame, "Checking backend", "GameFontHighlightSmall", theme.colors.muted)
    backendText:SetPoint(
        "LEFT",
        backendDot,
        "RIGHT",
        8,
        0
    )
    backendText:SetWidth(160)
    backendText:SetJustifyH("LEFT")
    realmBadge = Native:createText(header.frame, "VANILLA · CAP 60", "GameFontNormalSmall", theme.colors.warning)
    realmBadge:SetPoint(
        "RIGHT",
        backendGlow,
        "LEFT",
        -24,
        0
    )
    realmBadge:SetWidth(190)
    realmBadge:SetJustifyH("RIGHT")
    local close = ButtonUI:createButton(
        header.frame,
        {
            text = "Close   X",
            width = 108,
            height = 34,
            accent = theme.colors.error,
            emphasis = true,
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
        -73
    )
    sidebar.frame:SetPoint(
        "BOTTOMLEFT",
        frame,
        "BOTTOMLEFT",
        1,
        16
    )
    sidebar.frame:SetWidth(184)
    local navTitle = Native:createText(sidebar.frame, "COMPOSE", "GameFontNormalSmall", theme.colors.muted)
    navTitle:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -20
    )
    activePage = "COMPOSER"
    local function showComposerWorkspace(____, mode)
    end
    local function showProgressionPage()
    end
    local function showRecommendationsPage()
    end
    local function showDiagnosticsPage()
    end
    navDungeon = ButtonUI:createButton(
        sidebar.frame,
        {
            text = "Dungeon",
            width = 152,
            height = 46,
            accent = theme.colors.primary,
            icon = ICON_DUNGEON,
            iconSize = 24,
            flat = true,
            onClick = function() return showComposerWorkspace(nil, "DUNGEON") end
        }
    )
    navDungeon.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -48
    )
    navDungeon.label:SetJustifyH("LEFT")
    navRaid = ButtonUI:createButton(
        sidebar.frame,
        {
            text = "Raid",
            width = 152,
            height = 46,
            accent = theme.colors.warning,
            icon = ICON_RAID,
            iconSize = 24,
            flat = true,
            onClick = function() return showComposerWorkspace(nil, "RAID") end
        }
    )
    navRaid.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -102
    )
    navRaid.label:SetJustifyH("LEFT")
    local sidebarDivider = Native:createSolid(sidebar.frame, theme.colors.borderStrong, "ARTWORK")
    sidebarDivider:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -160
    )
    sidebarDivider:SetPoint(
        "TOPRIGHT",
        sidebar.frame,
        "TOPRIGHT",
        -14,
        -160
    )
    sidebarDivider:SetHeight(1)
    local journeyTitle = Native:createText(sidebar.frame, "JOURNEY", "GameFontNormalSmall", theme.colors.muted)
    journeyTitle:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -174
    )
    navProgression = ButtonUI:createButton(
        sidebar.frame,
        {
            text = "Progression",
            width = 152,
            height = 42,
            icon = "Interface\\Icons\\Achievement_Quests_Completed_08",
            iconSize = 22,
            flat = true,
            onClick = function() return showProgressionPage(nil) end
        }
    )
    navProgression.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -198
    )
    navProgression.label:SetJustifyH("LEFT")
    navRecommended = ButtonUI:createButton(
        sidebar.frame,
        {
            text = "Recommended",
            width = 152,
            height = 42,
            icon = "Interface\\Icons\\INV_Misc_Map_01",
            iconSize = 22,
            flat = true,
            onClick = function() return showRecommendationsPage(nil) end
        }
    )
    navRecommended.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -248
    )
    navRecommended.label:SetJustifyH("LEFT")
    local toolsDivider = Native:createSolid(sidebar.frame, theme.colors.borderStrong, "ARTWORK")
    toolsDivider:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -304
    )
    toolsDivider:SetPoint(
        "TOPRIGHT",
        sidebar.frame,
        "TOPRIGHT",
        -14,
        -304
    )
    toolsDivider:SetHeight(1)
    local manageTitle = Native:createText(sidebar.frame, "TOOLS", "GameFontNormalSmall", theme.colors.muted)
    manageTitle:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -318
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
            width = 152,
            height = 42,
            icon = ICON_TEMPLATES,
            iconSize = 22,
            flat = true,
            onClick = function() return showTemplates(nil) end
        }
    )
    navTemplates.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -342
    )
    navTemplates.label:SetJustifyH("LEFT")
    local navPeople = ButtonUI:createButton(
        sidebar.frame,
        {
            text = "Humans & Pins",
            width = 152,
            height = 42,
            icon = ICON_PEOPLE,
            iconSize = 22,
            flat = true,
            onClick = function() return showPeople(nil) end
        }
    )
    navPeople.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -392
    )
    navPeople.label:SetJustifyH("LEFT")
    local navOptions = ButtonUI:createButton(
        sidebar.frame,
        {
            text = "Options",
            width = 152,
            height = 42,
            icon = ICON_OPTIONS,
            iconSize = 22,
            flat = true,
            onClick = function() return showOptions(nil) end
        }
    )
    navOptions.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -442
    )
    navOptions.label:SetJustifyH("LEFT")
    navDiagnostics = ButtonUI:createButton(
        sidebar.frame,
        {
            text = "Diagnostics",
            width = 152,
            height = 42,
            icon = "Interface\\Icons\\INV_Gizmo_02",
            iconSize = 22,
            flat = true,
            onClick = function() return showDiagnosticsPage(nil) end
        }
    )
    navDiagnostics.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -492
    )
    navDiagnostics.label:SetJustifyH("LEFT")
    local sideHint = Native:createText(sidebar.frame, "Humans stay locked.\nSpecific builds reserve bot slots; everything else stays Auto.", "GameFontHighlightSmall", theme.colors.muted)
    sideHint:SetPoint(
        "BOTTOMLEFT",
        sidebar.frame,
        "BOTTOMLEFT",
        16,
        42
    )
    sideHint:SetWidth(152)
    sideHint:SetJustifyV("TOP")
    local ____Native_11 = Native
    local ____Native_createText_12 = Native.createText
    local ____sidebar_frame_10 = sidebar.frame
    local ____D_VERSION_9 = D.VERSION
    if ____D_VERSION_9 == nil then
        ____D_VERSION_9 = "0.10.0"
    end
    local versionText = ____Native_createText_12(
        ____Native_11,
        ____sidebar_frame_10,
        "v" .. tostring(____D_VERSION_9),
        "GameFontHighlightSmall",
        theme.colors.muted
    )
    versionText:SetPoint(
        "BOTTOMLEFT",
        sidebar.frame,
        "BOTTOMLEFT",
        16,
        12
    )
    local center = CreateFrame("Frame", nil, frame)
    center:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        200,
        -88
    )
    center:SetSize(970, 800)
    local status = Native:createPanel(frame, theme.colors.surface, theme.colors.borderStrong)
    status.frame:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        1186,
        -88
    )
    status.frame:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        -16,
        16
    )
    local activityBrowser = ActivityBrowserUI:createActivityBrowser(frame)
    local templatesBrowser = TemplateBrowserUI:createTemplateBrowser(frame)
    statusNotice = ""
    activity = Native:createPanel(center, theme.colors.surface, theme.colors.borderStrong)
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
    activity.frame:SetHeight(124)
    local activityTop = Native:createSolid(
        activity.frame,
        Native:withAlpha(theme.colors.primary, 0.65),
        "ARTWORK"
    )
    activityTop:SetPoint(
        "TOPLEFT",
        activity.frame,
        "TOPLEFT",
        0,
        0
    )
    activityTop:SetPoint(
        "TOPRIGHT",
        activity.frame,
        "TOPRIGHT",
        0,
        0
    )
    activityTop:SetHeight(2)
    local activityEyebrow = Native:createText(activity.frame, "ACTIVITY", "GameFontNormalSmall", theme.colors.muted)
    activityEyebrow:SetPoint(
        "TOPLEFT",
        activity.frame,
        "TOPLEFT",
        16,
        -12
    )
    activityBadge = Native:createFramedIcon(activity.frame, ICON_DUNGEON, 64, theme.colors.borderStrong)
    activityBadge.frame:SetPoint(
        "TOPLEFT",
        activity.frame,
        "TOPLEFT",
        16,
        -38
    )
    activityName = Native:createText(activity.frame, "Dungeon", "GameFontNormalLarge")
    activityName:SetPoint(
        "TOPLEFT",
        activity.frame,
        "TOPLEFT",
        96,
        -38
    )
    activityName:SetWidth(218)
    activitySub = Native:createText(activity.frame, "", "GameFontHighlightSmall", theme.colors.muted)
    activitySub:SetPoint(
        "TOPLEFT",
        activityName,
        "BOTTOMLEFT",
        0,
        -5
    )
    activitySub:SetWidth(218)
    activityEligibility = Native:createText(activity.frame, "", "GameFontHighlightSmall", theme.colors.success)
    activityEligibility:SetPoint(
        "TOPLEFT",
        activitySub,
        "BOTTOMLEFT",
        0,
        -7
    )
    activityEligibility:SetWidth(218)
    activityFieldLabel = Native:createText(activity.frame, "DUNGEON", "GameFontNormalSmall", theme.colors.muted)
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
    activityBrowse = ButtonUI:createButton(
        activity.frame,
        {
            text = "Browse Dungeons",
            width = 344,
            height = 38,
            accent = theme.colors.primary,
            icon = ICON_COVERAGE,
            iconSize = 22,
            onClick = function() return activityBrowser:open() end
        }
    )
    activityBrowse.frame:SetPoint(
        "TOPLEFT",
        activity.frame,
        "TOPLEFT",
        330,
        -36
    )
    difficultySelect = ChoiceUI:createChoiceSelect(
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
    raidSizeLabel = Native:createText(activity.frame, "RAID SIZE", "GameFontNormalSmall", theme.colors.muted)
    raidSizeLabel:SetPoint(
        "TOPLEFT",
        activity.frame,
        "TOPLEFT",
        702,
        -78
    )
    raidSizeLabel:Hide()
    raidSizeButtons = {}
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
        -136
    )
    humanPanel.frame:SetPoint(
        "TOPRIGHT",
        center,
        "TOPRIGHT",
        0,
        -136
    )
    humanPanel.frame:SetHeight(78)
    local humanTop = Native:createSolid(
        humanPanel.frame,
        Native:withAlpha(theme.colors.primary, 0.4),
        "ARTWORK"
    )
    humanTop:SetPoint(
        "TOPLEFT",
        humanPanel.frame,
        "TOPLEFT",
        0,
        0
    )
    humanTop:SetPoint(
        "TOPRIGHT",
        humanPanel.frame,
        "TOPRIGHT",
        0,
        0
    )
    humanTop:SetHeight(2)
    local humanTitle = Native:createText(humanPanel.frame, "YOUR PARTY", "GameFontNormalSmall", theme.colors.muted)
    humanTitle:SetPoint(
        "TOPLEFT",
        humanPanel.frame,
        "TOPLEFT",
        16,
        -12
    )
    humanBadge = Native:createFramedIcon(humanPanel.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 42, theme.colors.borderStrong)
    humanBadge.frame:SetPoint(
        "BOTTOMLEFT",
        humanPanel.frame,
        "BOTTOMLEFT",
        14,
        8
    )
    humanIcon = humanBadge.icon
    Native:setClassIcon(humanIcon, "WARRIOR")
    humanName = Native:createText(humanPanel.frame, "Choose your role", "GameFontNormal")
    humanName:SetPoint(
        "TOPLEFT",
        humanBadge.frame,
        "TOPRIGHT",
        10,
        -1
    )
    humanName:SetWidth(360)
    humanSub = Native:createText(humanPanel.frame, "Real players are locked anchors.", "GameFontHighlightSmall", theme.colors.muted)
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
    humanRoleButtons = {
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
        local icon = button.frame:CreateTexture(nil, "ARTWORK")
        icon:SetSize(18, 18)
        icon:SetPoint(
            "LEFT",
            button.frame,
            "LEFT",
            10,
            0
        )
        Native:setRoleIcon(icon, role)
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
        -226
    )
    composition.frame:SetPoint(
        "BOTTOMRIGHT",
        center,
        "BOTTOMRIGHT",
        0,
        0
    )
    local compositionTop = Native:createSolid(
        composition.frame,
        Native:withAlpha(theme.colors.primary, 0.34),
        "ARTWORK"
    )
    compositionTop:SetPoint(
        "TOPLEFT",
        composition.frame,
        "TOPLEFT",
        0,
        0
    )
    compositionTop:SetPoint(
        "TOPRIGHT",
        composition.frame,
        "TOPRIGHT",
        0,
        0
    )
    compositionTop:SetHeight(2)
    compositionTitle = Native:createText(composition.frame, "PARTY COMPOSITION", "GameFontNormal")
    compositionTitle:SetPoint(
        "TOPLEFT",
        composition.frame,
        "TOPLEFT",
        18,
        -14
    )
    compositionHint = Native:createText(composition.frame, "Auto-fill what you do not care about. Choose exact builds only where you do.", "GameFontHighlightSmall", theme.colors.muted)
    compositionHint:SetPoint(
        "TOPLEFT",
        compositionTitle,
        "BOTTOMLEFT",
        0,
        -4
    )
    selectorContext = {mode = "DUNGEON", role = "DPS", index = 0}
    buildSelector = BuildSelectorUI:createBuildSelector(
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
    dungeonView = CreateFrame("Frame", nil, composition.frame)
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
    dungeonRows = {}
    do
        local i = 0
        while i < 5 do
            local row = Native:createPanel(dungeonView, theme.colors.surfaceRaised, theme.colors.border)
            row.frame:SetHeight(64)
            row.frame:SetPoint(
                "TOPLEFT",
                dungeonView,
                "TOPLEFT",
                0,
                -(i * 70)
            )
            row.frame:SetPoint(
                "RIGHT",
                dungeonView,
                "RIGHT",
                0,
                0
            )
            local accent = Native:createSolid(row.frame, theme.colors.dps, "ARTWORK")
            accent:SetWidth(3)
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
            local roleBadge = Native:createFramedRoleIcon(row.frame, "DPS", 38, theme.colors.borderStrong)
            roleBadge.frame:SetPoint(
                "LEFT",
                row.frame,
                "LEFT",
                12,
                0
            )
            local roleIcon = roleBadge.icon
            local roleText = Native:createText(row.frame, "DPS", "GameFontNormal")
            roleText:SetPoint(
                "LEFT",
                roleBadge.frame,
                "RIGHT",
                10,
                7
            )
            local slotText = Native:createText(row.frame, "Slot", "GameFontHighlightSmall", theme.colors.muted)
            slotText:SetPoint(
                "LEFT",
                roleBadge.frame,
                "RIGHT",
                10,
                -9
            )
            local classBadge = Native:createFramedIcon(row.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 38, theme.colors.borderStrong)
            classBadge.frame:SetPoint(
                "LEFT",
                row.frame,
                "LEFT",
                158,
                0
            )
            classBadge.frame:Hide()
            local classIcon = classBadge.icon
            local specBadge = Native:createFramedIcon(row.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 34, theme.colors.borderStrong)
            specBadge.frame:SetPoint(
                "LEFT",
                classBadge.frame,
                "RIGHT",
                7,
                0
            )
            specBadge.frame:Hide()
            local specIcon = specBadge.icon
            local name = Native:createText(row.frame, "Auto-fill bot", "GameFontNormal")
            name:SetPoint(
                "TOPLEFT",
                row.frame,
                "TOPLEFT",
                244,
                -12
            )
            name:SetWidth(430)
            local sub = Native:createText(row.frame, "Composer chooses a suitable build", "GameFontHighlightSmall", theme.colors.muted)
            sub:SetPoint(
                "TOPLEFT",
                name,
                "BOTTOMLEFT",
                0,
                -4
            )
            sub:SetWidth(430)
            local choose = ButtonUI:createButton(row.frame, {text = "Choose build", width = 126, height = 34, accent = theme.colors.primary})
            choose.frame:SetPoint(
                "RIGHT",
                row.frame,
                "RIGHT",
                -12,
                0
            )
            local auto = ButtonUI:createButton(row.frame, {text = "Use Auto", width = 78, height = 34})
            auto.frame:SetPoint(
                "RIGHT",
                choose.frame,
                "LEFT",
                -8,
                0
            )
            auto.frame:Hide()
            local humanAnchor = ButtonUI:createButton(row.frame, {text = "Human anchor", width = 126, height = 34, accent = theme.colors.borderStrong})
            humanAnchor.frame:SetPoint(
                "RIGHT",
                row.frame,
                "RIGHT",
                -12,
                0
            )
            humanAnchor:setEnabled(false)
            humanAnchor.frame:Hide()
            dungeonRows[#dungeonRows + 1] = {
                row = row,
                accent = accent,
                roleIcon = roleIcon,
                roleText = roleText,
                slotText = slotText,
                classBadge = classBadge,
                classIcon = classIcon,
                specBadge = specBadge,
                specIcon = specIcon,
                name = name,
                sub = sub,
                choose = choose,
                auto = auto,
                humanAnchor = humanAnchor
            }
            i = i + 1
        end
    end
    raidView = CreateFrame("Frame", nil, composition.frame)
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
    raidTab = "QUICK"
    tabQuick = ButtonUI:createButton(raidView, {
        text = "Quick Composition",
        width = 164,
        height = 36,
        accent = theme.colors.primary,
        flat = true
    })
    tabQuick.frame:SetPoint(
        "TOPLEFT",
        raidView,
        "TOPLEFT",
        0,
        0
    )
    tabExact = ButtonUI:createButton(raidView, {
        text = "Specific Builds",
        width = 150,
        height = 36,
        accent = theme.colors.primary,
        flat = true
    })
    tabExact.frame:SetPoint(
        "LEFT",
        tabQuick.frame,
        "RIGHT",
        4,
        0
    )
    tabRoster = ButtonUI:createButton(raidView, {
        text = "Prepared Roster",
        width = 150,
        height = 36,
        accent = theme.colors.primary,
        flat = true
    })
    tabRoster.frame:SetPoint(
        "LEFT",
        tabExact.frame,
        "RIGHT",
        4,
        0
    )
    local tabUnderline = Native:createSolid(raidView, theme.colors.border, "ARTWORK")
    tabUnderline:SetPoint(
        "TOPLEFT",
        raidView,
        "TOPLEFT",
        0,
        -39
    )
    tabUnderline:SetPoint(
        "TOPRIGHT",
        raidView,
        "TOPRIGHT",
        0,
        -39
    )
    tabUnderline:SetHeight(1)
    local resetRoles = ButtonUI:createButton(
        raidView,
        {
            text = "Reset roles",
            width = 100,
            height = 32,
            flat = true,
            onClick = function() return Model:resetRoleTargets() end
        }
    )
    resetRoles.frame:SetPoint(
        "TOPRIGHT",
        raidView,
        "TOPRIGHT",
        0,
        -2
    )
    quickView = CreateFrame("Frame", nil, raidView)
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
    exactView = CreateFrame("Frame", nil, raidView)
    exactView:SetAllPoints(quickView)
    exactView:Hide()
    rosterView = CreateFrame("Frame", nil, raidView)
    rosterView:SetAllPoints(quickView)
    rosterView:Hide()
    quickCards = {}
    roleOrder = {"TANK", "HEALER", "DPS"}
    do
        local i = 0
        while i < #roleOrder do
            local role = roleOrder[i + 1]
            local accent = Model:roleAccent(role)
            local card = Native:createPanel(quickView, theme.colors.surfaceDeep, theme.colors.border)
            card.frame:SetSize(300, 214)
            card.frame:SetPoint(
                "TOPLEFT",
                quickView,
                "TOPLEFT",
                i * 312,
                -10
            )
            local roleStrip = Native:createSolid(card.frame, accent, "ARTWORK")
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
            local roleTint = Native:createSolid(
                card.frame,
                Native:withAlpha(accent, 0.045),
                "BACKGROUND"
            )
            roleTint:SetAllPoints(card.frame)
            local roleBadge = Native:createFramedRoleIcon(card.frame, role, 48, accent)
            roleBadge.frame:SetPoint(
                "TOPLEFT",
                card.frame,
                "TOPLEFT",
                18,
                -18
            )
            local label = Native:createText(
                card.frame,
                string.upper(Model:roleLabel(role)),
                "GameFontNormalLarge",
                accent
            )
            label:SetPoint(
                "TOPLEFT",
                card.frame,
                "TOPLEFT",
                80,
                -20
            )
            local kicker = Native:createText(card.frame, "RAID ROLE", "GameFontNormalSmall", theme.colors.muted)
            kicker:SetPoint(
                "TOPLEFT",
                card.frame,
                "TOPLEFT",
                80,
                -45
            )
            local minus = ButtonUI:createButton(card.frame, {text = "−", width = 40, height = 38, accent = accent})
            minus.frame:SetPoint(
                "TOPLEFT",
                card.frame,
                "TOPLEFT",
                24,
                -82
            )
            local countPanel = Native:createPanel(card.frame, theme.colors.background, accent)
            countPanel.frame:SetPoint(
                "TOPLEFT",
                card.frame,
                "TOPLEFT",
                70,
                -82
            )
            countPanel.frame:SetSize(160, 38)
            local count = Native:createText(countPanel.frame, "0", "GameFontNormalHuge", theme.colors.text)
            count:SetPoint(
                "CENTER",
                countPanel.frame,
                "CENTER",
                0,
                0
            )
            count:SetWidth(148)
            count:SetJustifyH("CENTER")
            local plus = ButtonUI:createButton(card.frame, {text = "+", width = 40, height = 38, accent = accent})
            plus.frame:SetPoint(
                "TOPRIGHT",
                card.frame,
                "TOPRIGHT",
                -24,
                -82
            )
            local botSlots = Native:createText(card.frame, "0 bot slots after humans", "GameFontHighlightSmall", accent)
            botSlots:SetPoint(
                "TOP",
                card.frame,
                "TOP",
                0,
                -132
            )
            botSlots:SetWidth(260)
            botSlots:SetJustifyH("CENTER")
            botSlots:SetJustifyV("TOP")
            local divider = Native:createSolid(card.frame, theme.colors.border, "ARTWORK")
            divider:SetPoint(
                "BOTTOMLEFT",
                card.frame,
                "BOTTOMLEFT",
                18,
                48
            )
            divider:SetPoint(
                "BOTTOMRIGHT",
                card.frame,
                "BOTTOMRIGHT",
                -18,
                48
            )
            divider:SetHeight(1)
            local roleHelp = Native:createText(
                card.frame,
                roleDescription(nil, role),
                "GameFontHighlightSmall",
                theme.colors.muted
            )
            roleHelp:SetPoint(
                "BOTTOMLEFT",
                card.frame,
                "BOTTOMLEFT",
                20,
                12
            )
            roleHelp:SetWidth(260)
            roleHelp:SetHeight(30)
            roleHelp:SetJustifyH("CENTER")
            roleHelp:SetJustifyV("TOP")
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
    quickSummary = Native:createPanel(quickView, theme.colors.background, theme.colors.border)
    quickSummary.frame:SetPoint(
        "TOPLEFT",
        quickView,
        "TOPLEFT",
        0,
        -236
    )
    quickSummary.frame:SetPoint(
        "TOPRIGHT",
        quickView,
        "TOPRIGHT",
        0,
        -236
    )
    quickSummary.frame:SetHeight(88)
    local quickTotalLabel = Native:createText(quickSummary.frame, "TOTAL RAID SIZE", "GameFontNormalSmall", theme.colors.muted)
    quickTotalLabel:SetPoint(
        "TOPLEFT",
        quickSummary.frame,
        "TOPLEFT",
        18,
        -13
    )
    quickTotal = Native:createText(quickSummary.frame, "25 / 25", "GameFontNormalHuge")
    quickTotal:SetPoint(
        "TOPLEFT",
        quickSummary.frame,
        "TOPLEFT",
        18,
        -36
    )
    local quickDivider = Native:createSolid(quickSummary.frame, theme.colors.borderStrong, "ARTWORK")
    quickDivider:SetPoint(
        "TOPLEFT",
        quickSummary.frame,
        "TOPLEFT",
        190,
        -12
    )
    quickDivider:SetHeight(64)
    quickDivider:SetWidth(1)
    quickCheck = Native:createPanel(quickSummary.frame, theme.colors.surfaceDeep, theme.colors.success)
    quickCheck.frame:SetSize(32, 32)
    quickCheck.frame:SetPoint(
        "LEFT",
        quickSummary.frame,
        "LEFT",
        216,
        0
    )
    quickCheckIcon = quickCheck.frame:CreateTexture(nil, "ARTWORK")
    quickCheckIcon:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    quickCheckIcon:SetAllPoints(quickCheck.frame)
    quickCheckBang = Native:createText(quickCheck.frame, "!", "GameFontNormalLarge", theme.colors.warning)
    quickCheckBang:SetPoint(
        "CENTER",
        quickCheck.frame,
        "CENTER",
        0,
        0
    )
    quickCheckBang:SetJustifyH("CENTER")
    quickCheckBang:Hide()
    quickStatusTitle = Native:createText(quickSummary.frame, "Raid composition is complete!", "GameFontNormal", theme.colors.success)
    quickStatusTitle:SetPoint(
        "TOPLEFT",
        quickSummary.frame,
        "TOPLEFT",
        264,
        -20
    )
    quickStatusTitle:SetWidth(380)
    quickStatusDetail = Native:createText(quickSummary.frame, "This setup will create the selected raid size with your chosen role balance.", "GameFontHighlightSmall", theme.colors.muted)
    quickStatusDetail:SetPoint(
        "TOPLEFT",
        quickStatusTitle,
        "BOTTOMLEFT",
        0,
        -5
    )
    quickStatusDetail:SetWidth(600)
    quickStatusDetail:SetHeight(34)
    quickStatusDetail:SetJustifyV("TOP")
    exactScroll = ScrollUI:createScrollList(exactView, 936, 418)
    exactScroll.frame:SetPoint(
        "TOPLEFT",
        exactView,
        "TOPLEFT",
        0,
        -4
    )
    exactSections = {}
    for ____, role in ipairs(roleOrder) do
        local accent = Model:roleAccent(role)
        local panel = Native:createPanel(exactScroll.content, theme.colors.surfaceDeep, theme.colors.border)
        panel.frame:SetWidth(906)
        local roleStrip = Native:createSolid(panel.frame, accent, "ARTWORK")
        roleStrip:SetHeight(3)
        roleStrip:SetPoint(
            "TOPLEFT",
            panel.frame,
            "TOPLEFT",
            0,
            0
        )
        roleStrip:SetPoint(
            "TOPRIGHT",
            panel.frame,
            "TOPRIGHT",
            0,
            0
        )
        local roleTint = Native:createSolid(
            panel.frame,
            Native:withAlpha(accent, 0.035),
            "BACKGROUND"
        )
        roleTint:SetAllPoints(panel.frame)
        local roleBadge = Native:createFramedRoleIcon(panel.frame, role, 36, accent)
        roleBadge.frame:SetPoint(
            "TOPLEFT",
            panel.frame,
            "TOPLEFT",
            12,
            -10
        )
        local label = Native:createText(
            panel.frame,
            string.upper(Model:roleLabel(role)),
            "GameFontNormal",
            accent
        )
        label:SetPoint(
            "TOPLEFT",
            panel.frame,
            "TOPLEFT",
            60,
            -12
        )
        local count = Native:createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted)
        count:SetPoint(
            "TOPLEFT",
            panel.frame,
            "TOPLEFT",
            60,
            -32
        )
        count:SetWidth(430)
        local add = ButtonUI:createButton(panel.frame, {text = "+ Add specific build", width = 154, height = 30, accent = accent})
        add.frame:SetPoint(
            "TOPRIGHT",
            panel.frame,
            "TOPRIGHT",
            -12,
            -12
        )
        local empty = Native:createText(
            panel.frame,
            ("No reserved builds. Every remaining " .. string.lower(Model:roleLabel(role))) .. " slot stays Auto.",
            "GameFontHighlightSmall",
            theme.colors.muted
        )
        empty:SetPoint(
            "TOPLEFT",
            panel.frame,
            "TOPLEFT",
            18,
            -58
        )
        empty:SetWidth(820)
        empty:SetJustifyV("TOP")
        exactScroll:bindWheel(panel.frame)
        exactScroll:bindWheel(add.frame)
        exactSections[role] = {
            panel = panel,
            count = count,
            add = add,
            empty = empty,
            rowsByKey = {},
            rowKeys = {}
        }
    end
    groupCards = {}
    do
        local g = 0
        while g < 8 do
            local card = Native:createPanel(rosterView, theme.colors.surfaceDeep, theme.colors.border)
            local headerAccent = Native:createSolid(
                card.frame,
                Native:withAlpha(theme.colors.primary, 0.72),
                "ARTWORK"
            )
            headerAccent:SetPoint(
                "TOPLEFT",
                card.frame,
                "TOPLEFT",
                0,
                0
            )
            headerAccent:SetPoint(
                "TOPRIGHT",
                card.frame,
                "TOPRIGHT",
                0,
                0
            )
            headerAccent:SetHeight(2)
            local groupTitle = Native:createText(
                card.frame,
                "GROUP " .. tostring(g + 1),
                "GameFontNormalSmall",
                theme.colors.text
            )
            groupTitle:SetPoint(
                "TOPLEFT",
                card.frame,
                "TOPLEFT",
                10,
                -10
            )
            local groupHint = Native:createText(card.frame, "SUBGROUP", "GameFontHighlightSmall", theme.colors.muted)
            groupHint:SetPoint(
                "TOPLEFT",
                card.frame,
                "TOPLEFT",
                10,
                -27
            )
            local groupCount = Native:createText(card.frame, "0 / 5", "GameFontHighlightSmall", theme.colors.primary)
            groupCount:SetPoint(
                "TOPRIGHT",
                card.frame,
                "TOPRIGHT",
                -10,
                -12
            )
            groupCount:SetWidth(54)
            groupCount:SetJustifyH("RIGHT")
            local headerRule = Native:createSolid(card.frame, theme.colors.border, "ARTWORK")
            headerRule:SetPoint(
                "TOPLEFT",
                card.frame,
                "TOPLEFT",
                10,
                -45
            )
            headerRule:SetPoint(
                "TOPRIGHT",
                card.frame,
                "TOPRIGHT",
                -10,
                -45
            )
            headerRule:SetHeight(1)
            local rows = {}
            do
                local r = 0
                while r < 5 do
                    local row = CreateFrame("Frame", nil, card.frame)
                    row:SetHeight(30)
                    row:SetPoint(
                        "TOPLEFT",
                        card.frame,
                        "TOPLEFT",
                        8,
                        -(50 + r * 31)
                    )
                    row:SetPoint(
                        "RIGHT",
                        card.frame,
                        "RIGHT",
                        -8,
                        0
                    )
                    local rowBg = Native:createSolid(
                        row,
                        Native:withAlpha(theme.colors.surfaceRaised, 0.58),
                        "BACKGROUND"
                    )
                    rowBg:SetAllPoints(row)
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
                    local iconBadge = Native:createFramedIcon(row, "Interface\\Icons\\INV_Misc_QuestionMark", 26, theme.colors.border)
                    iconBadge.frame:SetPoint(
                        "LEFT",
                        row,
                        "LEFT",
                        7,
                        0
                    )
                    local icon = iconBadge.icon
                    iconBadge.frame:Hide()
                    local name = Native:createText(row, "Empty slot", "GameFontHighlightSmall", theme.colors.muted)
                    name:SetPoint(
                        "TOPLEFT",
                        row,
                        "TOPLEFT",
                        40,
                        -4
                    )
                    name:SetWidth(146)
                    local spec = Native:createText(row, "", "GameFontHighlightSmall", theme.colors.muted)
                    spec:SetPoint(
                        "TOPLEFT",
                        row,
                        "TOPLEFT",
                        40,
                        -18
                    )
                    spec:SetWidth(156)
                    local roleIcon = row:CreateTexture(nil, "ARTWORK")
                    roleIcon:SetSize(15, 15)
                    roleIcon:SetPoint(
                        "RIGHT",
                        row,
                        "RIGHT",
                        -7,
                        0
                    )
                    Native:setRoleIcon(roleIcon, "DPS")
                    roleIcon:SetAlpha(0.85)
                    rows[#rows + 1] = {
                        row = row,
                        rowBg = rowBg,
                        roleBar = roleBar,
                        iconBadge = iconBadge,
                        icon = icon,
                        name = name,
                        spec = spec,
                        roleIcon = roleIcon
                    }
                    r = r + 1
                end
            end
            card.frame:Hide()
            groupCards[#groupCards + 1] = {
                card = card,
                headerAccent = headerAccent,
                groupTitle = groupTitle,
                groupHint = groupHint,
                groupCount = groupCount,
                rows = rows
            }
            g = g + 1
        end
    end
    local statusTitle = Native:createText(status.frame, "ROSTER STATUS", "GameFontNormalSmall", theme.colors.muted)
    statusTitle:SetPoint(
        "TOPLEFT",
        status.frame,
        "TOPLEFT",
        16,
        -16
    )
    phaseCard = Native:createPanel(status.frame, theme.colors.surfaceBlue, theme.colors.borderStrong)
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
    phaseCard.frame:SetHeight(92)
    phaseAccent = Native:createSolid(phaseCard.frame, theme.colors.primary, "ARTWORK")
    phaseAccent:SetWidth(3)
    phaseAccent:SetPoint(
        "TOPLEFT",
        phaseCard.frame,
        "TOPLEFT",
        0,
        0
    )
    phaseAccent:SetPoint(
        "BOTTOMLEFT",
        phaseCard.frame,
        "BOTTOMLEFT",
        0,
        0
    )
    phaseGlow = Native:createSolid(
        phaseCard.frame,
        Native:withAlpha(theme.colors.primary, 0.14),
        "ARTWORK"
    )
    phaseGlow:SetSize(18, 18)
    phaseGlow:SetPoint(
        "TOPLEFT",
        phaseCard.frame,
        "TOPLEFT",
        11,
        -12
    )
    phaseDot = Native:createSolid(phaseCard.frame, theme.colors.primary, "OVERLAY")
    phaseDot:SetSize(8, 8)
    phaseDot:SetPoint(
        "TOPLEFT",
        phaseCard.frame,
        "TOPLEFT",
        16,
        -17
    )
    phaseText = Native:createText(phaseCard.frame, "Configure roster", "GameFontNormal")
    phaseText:SetPoint(
        "LEFT",
        phaseDot,
        "RIGHT",
        10,
        2
    )
    phaseText:SetWidth(220)
    phaseDetail = Native:createText(phaseCard.frame, "", "GameFontHighlightSmall", theme.colors.muted)
    phaseDetail:SetPoint(
        "TOPLEFT",
        phaseText,
        "BOTTOMLEFT",
        0,
        -4
    )
    phaseDetail:SetWidth(230)
    phaseDetail:SetJustifyV("TOP")
    rosterCount = Native:createText(status.frame, "1 / 5", "GameFontNormalHuge")
    rosterCount:SetPoint(
        "TOPLEFT",
        status.frame,
        "TOPLEFT",
        16,
        -146
    )
    sourceText = Native:createText(status.frame, "1 human  ·  4 bot slots", "GameFontHighlightSmall", theme.colors.muted)
    sourceText:SetPoint(
        "TOPLEFT",
        rosterCount,
        "BOTTOMLEFT",
        0,
        -4
    )
    sourceText:SetWidth(270)
    statusRoleChips = {}
    do
        local i = 0
        while i < #roleOrder do
            local role = roleOrder[i + 1]
            local chip = Native:createPanel(
                status.frame,
                theme.colors.surfaceDeep,
                Model:roleAccent(role)
            )
            chip.frame:SetSize(84, 32)
            chip.frame:SetPoint(
                "TOPLEFT",
                status.frame,
                "TOPLEFT",
                16 + i * 90,
                -201
            )
            local icon = chip.frame:CreateTexture(nil, "ARTWORK")
            icon:SetSize(16, 16)
            icon:SetPoint(
                "LEFT",
                chip.frame,
                "LEFT",
                7,
                0
            )
            Native:setRoleIcon(icon, role)
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
                5,
                0
            )
            label:SetWidth(54)
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
        -245
    )
    progressBg.frame:SetSize(270, 12)
    progressFill = Native:createSolid(progressBg.frame, theme.colors.primary, "ARTWORK")
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
    progressText = Native:createText(status.frame, "", "GameFontHighlightSmall", theme.colors.muted)
    progressText:SetPoint(
        "TOPLEFT",
        status.frame,
        "TOPLEFT",
        16,
        -264
    )
    progressText:SetWidth(270)
    progressText:SetHeight(32)
    progressText:SetJustifyV("TOP")
    local coverageCard = Native:createPanel(status.frame, theme.colors.background, theme.colors.border)
    coverageCard.frame:SetPoint(
        "TOPLEFT",
        status.frame,
        "TOPLEFT",
        16,
        -307
    )
    coverageCard.frame:SetPoint(
        "TOPRIGHT",
        status.frame,
        "TOPRIGHT",
        -16,
        -307
    )
    coverageCard.frame:SetHeight(196)
    local coverageGlyph = Native:createPanel(coverageCard.frame, theme.colors.surfaceDeep, theme.colors.borderStrong)
    coverageGlyph.frame:SetSize(30, 30)
    coverageGlyph.frame:SetPoint(
        "TOPLEFT",
        coverageCard.frame,
        "TOPLEFT",
        12,
        -11
    )
    do
        local i = 0
        while i < 3 do
            local bar = Native:createSolid(coverageGlyph.frame, theme.colors.text, "ARTWORK")
            bar:SetWidth(4)
            bar:SetHeight(7 + i * 5)
            bar:SetPoint(
                "BOTTOMLEFT",
                coverageGlyph.frame,
                "BOTTOMLEFT",
                6 + i * 7,
                5
            )
            i = i + 1
        end
    end
    local coverageTitle = Native:createText(coverageCard.frame, "UTILITY COVERAGE", "GameFontNormalSmall", theme.colors.muted)
    coverageTitle:SetPoint(
        "LEFT",
        coverageGlyph.frame,
        "RIGHT",
        9,
        0
    )
    local coverageDefs = {
        {token = "interrupt", label = "Interrupt"},
        {token = "dispel", label = "Dispel"},
        {token = "buffs", label = "Raid Buffs"},
        {token = "heroism", label = "Heroism"},
        {token = "battle-rez", label = "Battle Res"},
        {token = "cc", label = "CC"},
        {token = "threat", label = "Threat"}
    }
    coverageChips = {}
    do
        local i = 0
        while i < #coverageDefs do
            local column = i % 2
            local row = math.floor(i / 2)
            local chip = Native:createPanel(coverageCard.frame, theme.colors.surfaceDeep, theme.colors.border)
            chip.frame:SetSize(122, 24)
            chip.frame:SetPoint(
                "TOPLEFT",
                coverageCard.frame,
                "TOPLEFT",
                12 + column * 126,
                -(50 + row * 29)
            )
            local check = chip.frame:CreateTexture(nil, "ARTWORK")
            check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
            check:SetSize(14, 14)
            check:SetPoint(
                "LEFT",
                chip.frame,
                "LEFT",
                5,
                0
            )
            check:Hide()
            local label = Native:createText(chip.frame, coverageDefs[i + 1].label, "GameFontHighlightSmall", theme.colors.muted)
            label:SetPoint(
                "LEFT",
                chip.frame,
                "LEFT",
                22,
                0
            )
            label:SetWidth(94)
            coverageChips[#coverageChips + 1] = {panel = chip, check = check, label = label, token = coverageDefs[i + 1].token}
            i = i + 1
        end
    end
    coverageDamageText = Native:createText(coverageCard.frame, "Prepare a roster to inspect utility.", "GameFontHighlightSmall", theme.colors.muted)
    coverageDamageText:SetPoint(
        "BOTTOMLEFT",
        coverageCard.frame,
        "BOTTOMLEFT",
        12,
        9
    )
    coverageDamageText:SetWidth(246)
    nextCard = Native:createPanel(status.frame, theme.colors.background, theme.colors.border)
    nextCard.frame:SetPoint(
        "TOPLEFT",
        status.frame,
        "TOPLEFT",
        16,
        -519
    )
    nextCard.frame:SetPoint(
        "TOPRIGHT",
        status.frame,
        "TOPRIGHT",
        -16,
        -477
    )
    nextCard.frame:SetHeight(116)
    nextBadge = Native:createPanel(nextCard.frame, theme.colors.surfaceDeep, theme.colors.warning)
    nextBadge.frame:SetSize(28, 28)
    nextBadge.frame:SetPoint(
        "TOPLEFT",
        nextCard.frame,
        "TOPLEFT",
        12,
        -12
    )
    nextBang = Native:createText(nextBadge.frame, "!", "GameFontNormal", theme.colors.warning)
    nextBang:SetPoint(
        "CENTER",
        nextBadge.frame,
        "CENTER",
        0,
        0
    )
    nextBang:SetJustifyH("CENTER")
    warningsTitle = Native:createText(nextCard.frame, "NEXT STEP", "GameFontNormalSmall", theme.colors.warning)
    warningsTitle:SetPoint(
        "LEFT",
        nextBadge.frame,
        "RIGHT",
        9,
        0
    )
    nextDetail = Native:createText(nextCard.frame, "", "GameFontHighlightSmall", theme.colors.warning)
    nextDetail:SetPoint(
        "TOPLEFT",
        nextCard.frame,
        "TOPLEFT",
        12,
        -48
    )
    nextDetail:SetWidth(246)
    nextDetail:SetHeight(58)
    nextDetail:SetJustifyV("TOP")
    buildButton = ButtonUI:createButton(
        status.frame,
        {
            text = "Build & Prepare",
            width = 270,
            height = 52,
            accent = theme.colors.primary,
            emphasis = true,
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
    local function showTeleportConfirm()
    end
    teleportButton = ButtonUI:createButton(
        status.frame,
        {
            text = "Teleport to Instance",
            width = 270,
            height = 52,
            accent = theme.colors.primary,
            emphasis = true,
            onClick = function() return showTeleportConfirm(nil) end
        }
    )
    teleportButton.frame:SetPoint(
        "BOTTOMLEFT",
        status.frame,
        "BOTTOMLEFT",
        16,
        66
    )
    teleportButton.frame:Hide()
    assembleButton = ButtonUI:createButton(
        status.frame,
        {
            text = "Assemble",
            width = 194,
            height = 46,
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
    resetButton = ButtonUI:createButton(
        status.frame,
        {
            text = "Reset",
            width = 68,
            height = 46,
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
    groupActionsButton = ButtonUI:createButton(
        status.frame,
        {
            text = "Group Actions",
            width = 270,
            height = 46,
            accent = theme.colors.warning,
            onClick = function() return groupActions:open() end
        }
    )
    groupActionsButton.frame:SetPoint(
        "BOTTOMLEFT",
        status.frame,
        "BOTTOMLEFT",
        16,
        18
    )
    groupActionsButton.frame:Hide()
    showTemplates = function()
        ChoiceUI:closeChoicePopup()
        templatesBrowser:open()
    end
    local peopleModal = ModalUI:createModal(frame, 980, 620)
    peopleModal:setTitle("Humans & Pins")
    peopleModal:setSubtitle("Humans are locked anchors. Pins reserve named companions without making active group members disposable.")
    peopleModal:setHeaderIcon(ICON_PEOPLE)
    local peopleHumanTitle = Native:createText(peopleModal.content, "HUMAN ANCHORS", "GameFontNormalSmall", theme.colors.muted)
    peopleHumanTitle:SetPoint(
        "TOPLEFT",
        peopleModal.content,
        "TOPLEFT",
        0,
        0
    )
    humanScroll = ScrollUI:createScrollList(peopleModal.content, 442, 430)
    humanScroll.frame:SetPoint(
        "TOPLEFT",
        peopleModal.content,
        "TOPLEFT",
        0,
        -26
    )
    humanRowsModal = {}
    humanEmpty = Native:createText(humanScroll.content, "No human anchors detected.", "GameFontHighlight", theme.colors.muted)
    humanEmpty:SetPoint(
        "TOPLEFT",
        humanScroll.content,
        "TOPLEFT",
        18,
        -24
    )
    humanEmpty:SetWidth(360)
    humanEmpty:SetJustifyH("CENTER")
    humanEmpty:Hide()
    local pinPane = CreateFrame("Frame", nil, peopleModal.content)
    pinPane:SetPoint(
        "TOPRIGHT",
        peopleModal.content,
        "TOPRIGHT",
        0,
        0
    )
    pinPane:SetSize(442, 456)
    local pinTitle = Native:createText(pinPane, "PIN COMPANION", "GameFontNormalSmall", theme.colors.muted)
    pinTitle:SetPoint(
        "TOPLEFT",
        pinPane,
        "TOPLEFT",
        0,
        0
    )
    local pinBuilder = Native:createPanel(pinPane, theme.colors.surfaceRaised, theme.colors.border)
    pinBuilder.frame:SetPoint(
        "TOPLEFT",
        pinPane,
        "TOPLEFT",
        0,
        -26
    )
    pinBuilder.frame:SetPoint(
        "TOPRIGHT",
        pinPane,
        "TOPRIGHT",
        0,
        -26
    )
    pinBuilder.frame:SetHeight(118)
    local pinInput = InputUI:createTextInput(pinBuilder.frame, 250, 34)
    pinInput.frame:SetPoint(
        "TOPLEFT",
        pinBuilder.frame,
        "TOPLEFT",
        12,
        -12
    )
    pinRole = "DPS"
    local pinRequired = false
    pinRoleButtons = {
        TANK = ButtonUI:createButton(pinBuilder.frame, {text = "Tank", width = 66, height = 28, accent = theme.colors.tank}),
        HEALER = ButtonUI:createButton(pinBuilder.frame, {text = "Healer", width = 66, height = 28, accent = theme.colors.healer}),
        DPS = ButtonUI:createButton(pinBuilder.frame, {text = "DPS", width = 66, height = 28, accent = theme.colors.dps})
    }
    pinRoleButtons.TANK.frame:SetPoint(
        "TOPLEFT",
        pinBuilder.frame,
        "TOPLEFT",
        12,
        -58
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
        pinBuilder.frame,
        "Required",
        function() return pinRequired end,
        function(____, value)
            pinRequired = value
        end
    )
    pinToggle.frame:SetPoint(
        "TOPLEFT",
        pinBuilder.frame,
        "TOPLEFT",
        230,
        -57
    )
    pinToggle.frame:SetWidth(92)
    local addPinButton = ButtonUI:createButton(
        pinBuilder.frame,
        {
            text = "Pin Member",
            width = 112,
            height = 34,
            accent = theme.colors.primary,
            emphasis = true,
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
        pinBuilder.frame,
        "TOPRIGHT",
        -12,
        -12
    )
    local pinListTitle = Native:createText(pinPane, "PINNED MEMBERS", "GameFontNormalSmall", theme.colors.muted)
    pinListTitle:SetPoint(
        "TOPLEFT",
        pinPane,
        "TOPLEFT",
        0,
        -160
    )
    pinScroll = ScrollUI:createScrollList(pinPane, 442, 270)
    pinScroll.frame:SetPoint(
        "TOPLEFT",
        pinPane,
        "TOPLEFT",
        0,
        -186
    )
    pinRows = {}
    pinEmpty = Native:createText(pinScroll.content, "No companions pinned. Add a name above when you want Composer to keep someone in mind.", "GameFontHighlightSmall", theme.colors.muted)
    pinEmpty:SetPoint(
        "TOPLEFT",
        pinScroll.content,
        "TOPLEFT",
        24,
        -26
    )
    pinEmpty:SetWidth(350)
    pinEmpty:SetJustifyH("CENTER")
    pinEmpty:SetJustifyV("TOP")
    pinEmpty:Hide()
    showPeople = function()
        ChoiceUI:closeChoicePopup()
        refreshPeople(nil)
        peopleModal:show()
    end
    local optionsModal = ModalUI:createModal(frame, 820, 650)
    optionsModal:setHeaderIcon(ICON_OPTIONS)
    optionsModal:setTitle("Composition Options")
    optionsModal:setSubtitle("Tune candidate selection without turning the common path into a settings dashboard.")
    local optionDefs = {
        {label = "Prefer guild bots", key = "preferGuild", hint = "Soft preference for suitable guild companions. It does not ban other valid candidates."},
        {label = "Allow world fallback", key = "fillWorld", hint = "Hard pool boundary. Off means Composer will not fill open slots from outside the guild."},
        {label = "Balance classes", key = "balanceClasses", hint = "Avoid heavily lopsided class coverage when Auto is filling slots."},
        {label = "Balance utility", key = "balanceUtility", hint = "Prefer broader raid and dungeon utility coverage."},
        {label = "Balance melee / ranged", key = "balanceRange", hint = "Avoid extreme melee or ranged skew where possible."},
        {label = "Avoid duplicate classes", key = "avoidDuplicateClasses", hint = "Stricter diversity preference. Exact builds still take priority."},
        {label = "Queue random dungeon after assembly", key = "queueAfterAssemble", hint = "Only applies when Random Dungeon is the selected activity."}
    }
    local optionToggles = {}
    local candidateTitle = Native:createText(optionsModal.content, "CANDIDATE POOL", "GameFontNormalSmall", theme.colors.primary)
    candidateTitle:SetPoint(
        "TOPLEFT",
        optionsModal.content,
        "TOPLEFT",
        0,
        0
    )
    local compositionOptionsTitle = Native:createText(optionsModal.content, "COMPOSITION", "GameFontNormalSmall", theme.colors.primary)
    compositionOptionsTitle:SetPoint(
        "TOPLEFT",
        optionsModal.content,
        "TOPLEFT",
        0,
        -136
    )
    local activityOptionsTitle = Native:createText(optionsModal.content, "ACTIVITY", "GameFontNormalSmall", theme.colors.primary)
    activityOptionsTitle:SetPoint(
        "TOPLEFT",
        optionsModal.content,
        "TOPLEFT",
        0,
        -376
    )
    local eligibilityTitle = Native:createText(optionsModal.content, "ELIGIBILITY", "GameFontNormalSmall", theme.colors.primary)
    eligibilityTitle:SetPoint(
        "TOPLEFT",
        optionsModal.content,
        "TOPLEFT",
        0,
        -462
    )
    local optionY = {
        -24,
        -76,
        -160,
        -212,
        -264,
        -316,
        -400
    }
    do
        local i = 0
        while i < #optionDefs do
            local def = optionDefs[i + 1]
            local row = CreateFrame("Frame", nil, optionsModal.content)
            row:SetPoint(
                "TOPLEFT",
                optionsModal.content,
                "TOPLEFT",
                0,
                optionY[i + 1]
            )
            row:SetPoint(
                "TOPRIGHT",
                optionsModal.content,
                "TOPRIGHT",
                0,
                optionY[i + 1]
            )
            row:SetHeight(48)
            local toggle = ToggleUI:createToggle(
                row,
                def.label,
                function()
                    local ____opt_15 = Model:config().options
                    if ____opt_15 ~= nil then
                        ____opt_15 = ____opt_15[def.key]
                    end
                    return ____opt_15 == true
                end,
                function(____, value)
                    Model:config().options[def.key] = value
                    Model:touch("Composition option changed")
                end
            )
            toggle.frame:SetPoint(
                "TOPLEFT",
                row,
                "TOPLEFT",
                0,
                -2
            )
            toggle.frame:SetWidth(720)
            local hint = Native:createText(row, def.hint, "GameFontHighlightSmall", theme.colors.muted)
            hint:SetPoint(
                "TOPLEFT",
                row,
                "TOPLEFT",
                32,
                -27
            )
            hint:SetWidth(700)
            hint:SetJustifyV("TOP")
            local divider = Native:createSolid(row, theme.colors.border, "ARTWORK")
            divider:SetPoint(
                "BOTTOMLEFT",
                row,
                "BOTTOMLEFT",
                0,
                0
            )
            divider:SetPoint(
                "BOTTOMRIGHT",
                row,
                "BOTTOMRIGHT",
                0,
                0
            )
            divider:SetHeight(1)
            optionToggles[#optionToggles + 1] = toggle
            i = i + 1
        end
    end
    local gearRow = CreateFrame("Frame", nil, optionsModal.content)
    gearRow:SetPoint(
        "TOPLEFT",
        optionsModal.content,
        "TOPLEFT",
        0,
        -486
    )
    gearRow:SetPoint(
        "TOPRIGHT",
        optionsModal.content,
        "TOPRIGHT",
        0,
        -486
    )
    gearRow:SetHeight(66)
    local gearDivider = Native:createSolid(gearRow, theme.colors.border, "ARTWORK")
    gearDivider:SetPoint(
        "TOPLEFT",
        gearRow,
        "TOPLEFT",
        0,
        0
    )
    gearDivider:SetPoint(
        "TOPRIGHT",
        gearRow,
        "TOPRIGHT",
        0,
        0
    )
    gearDivider:SetHeight(1)
    local gearIcon = Native:createFramedIcon(gearRow, "Interface\\Icons\\INV_Chest_Plate04", 34, theme.colors.primary)
    gearIcon.frame:SetPoint(
        "LEFT",
        gearRow,
        "LEFT",
        0,
        -4
    )
    local gearTitle = Native:createText(gearRow, "Minimum item level", "GameFontNormal")
    gearTitle:SetPoint(
        "TOPLEFT",
        gearRow,
        "TOPLEFT",
        46,
        -12
    )
    local gearHint = Native:createText(gearRow, "0 disables the floor. Persistent guild/world candidates below this value are rejected.", "GameFontHighlightSmall", theme.colors.muted)
    gearHint:SetPoint(
        "TOPLEFT",
        gearRow,
        "TOPLEFT",
        46,
        -35
    )
    gearHint:SetWidth(520)
    local ____StepperUI_20 = StepperUI
    local ____StepperUI_createNumberStepper_21 = StepperUI.createNumberStepper
    local ____opt_17 = Model:config().options
    if ____opt_17 ~= nil then
        ____opt_17 = ____opt_17.minimumItemLevel
    end
    local ____opt_17_19 = ____opt_17
    if ____opt_17_19 == nil then
        ____opt_17_19 = 0
    end
    local gearStepper = ____StepperUI_createNumberStepper_21(
        ____StepperUI_20,
        gearRow,
        0,
        300,
        __TS__Number(____opt_17_19),
        function(____, value) return Model:setMinimumItemLevel(value) end
    )
    gearStepper.frame:SetPoint(
        "RIGHT",
        gearRow,
        "RIGHT",
        0,
        -4
    )
    showOptions = function()
        ChoiceUI:closeChoicePopup()
        for ____, toggle in ipairs(optionToggles) do
            toggle:refresh()
        end
        local ____gearStepper_setValue_25 = gearStepper.setValue
        local ____opt_22 = Model:config().options
        if ____opt_22 ~= nil then
            ____opt_22 = ____opt_22.minimumItemLevel
        end
        local ____opt_22_24 = ____opt_22
        if ____opt_22_24 == nil then
            ____opt_22_24 = 0
        end
        ____gearStepper_setValue_25(
            gearStepper,
            __TS__Number(____opt_22_24),
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
    local function confirmAction()
        return Model:assemble()
    end
    local confirmGo = ButtonUI:createButton(
        confirmModal.content,
        {
            text = "Assemble",
            width = 140,
            height = 38,
            accent = theme.colors.success,
            emphasis = true,
            onClick = function()
                confirmModal:hide()
                confirmAction(nil)
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
        local cfg = Model:config()
        local activity = Model:selectedActivityLabel()
        confirmAction = function() return Model:assemble() end
        confirmModal:setHeaderIcon(Model:selectedActivityIcon())
        confirmModal:setTitle(cfg.mode == "RAID" and "Assemble prepared raid?" or "Assemble prepared party?")
        confirmModal:setSubtitle("Composer will commit the reviewed roster. Travel remains a separate action.")
        confirmText:SetText(cfg.mode == "DUNGEON" and cfg.activity == "random" and "Prepared Playerbots attach directly. Real players keep normal group semantics. Dungeon Finder chooses the destination." or ("Prepared Playerbots attach directly. After assembly, use Teleport to Instance when everyone is ready for " .. activity) .. ".")
        confirmGo:setText("Assemble")
        confirmModal:show()
    end
    showTeleportConfirm = function()
        if not Model:isAssembled() or not Model:hasFixedActivityDestination() then
            Model:fireStatus("Assemble the complete group before teleporting to a named instance.")
            return
        end
        local activity = Model:selectedActivityLabel()
        confirmAction = function() return Model:teleportToInstance() end
        confirmModal:setHeaderIcon(Model:selectedActivityIcon())
        confirmModal:setTitle("Teleport to instance?")
        confirmModal:setSubtitle("This is a separate confirmation after assembly.")
        confirmText:SetText(("Teleport the complete assembled group into " .. activity) .. ". Composer will validate level, quest/access, lockout and instance state before moving anyone.")
        confirmGo:setText("Teleport")
        confirmModal:show()
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
    progressionPage = ProgressionPageUI:createProgressionPage(frame)
    diagnosticsPage = ActivityDiagnosticsUI:createActivityDiagnosticsPage(frame)
    recommendationsPage = RecommendationsPageUI:createRecommendationsPage(
        frame,
        function()
            activePage = "COMPOSER"
            progressionPage:hide()
            recommendationsPage:hide()
            diagnosticsPage:hide()
            refresh(nil)
            Model:requestActivities(Model:config().mode == "RAID" and "RAID" or "DUNGEON")
        end
    )
    showComposerWorkspace = function(____, mode)
        activePage = "COMPOSER"
        progressionPage:hide()
        recommendationsPage:hide()
        diagnosticsPage:hide()
        if mode ~= nil then
            Model:setMode(mode)
        end
        refresh(nil)
        Model:requestActivities(Model:config().mode == "RAID" and "RAID" or "DUNGEON")
    end
    showProgressionPage = function()
        activePage = "PROGRESSION"
        recommendationsPage:hide()
        diagnosticsPage:hide()
        progressionPage:show()
        refresh(nil)
    end
    showRecommendationsPage = function()
        activePage = "RECOMMENDED"
        progressionPage:hide()
        diagnosticsPage:hide()
        recommendationsPage:show()
        refresh(nil)
    end
    showDiagnosticsPage = function()
        activePage = "DIAGNOSTICS"
        progressionPage:hide()
        recommendationsPage:hide()
        diagnosticsPage:show()
        refresh(nil)
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
            Model:requestActivities(Model:config().mode == "RAID" and "RAID" or "DUNGEON")
            Model:requestJourney()
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
        function()
            statusNotice = ""
            refresh(nil)
        end
    )
    GC:RegisterCallback(
        "PLAN_CHANGED",
        function()
            statusNotice = ""
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
        "ACTIVITIES_CHANGED",
        function() return refresh(nil) end
    )
    GC:RegisterCallback(
        "REALM_CHANGED",
        function()
            difficultySelect:refresh()
            refresh(nil)
        end
    )
    GC:RegisterCallback(
        "JOURNEY_CHANGED",
        function() return refresh(nil) end
    )
    GC:RegisterCallback(
        "PROFILES_CHANGED",
        function() return refresh(nil) end
    )
    GC:RegisterCallback(
        "STATUS",
        function(____, text)
            statusNotice = tostring(text or "")
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
    version = "0.7.1",
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

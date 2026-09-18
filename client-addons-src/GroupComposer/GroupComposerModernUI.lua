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
____exports.ROLE_ICON_ATLAS = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES"
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
    local topSheen = ____exports.createSolid(
        nil,
        frame,
        ____exports.withAlpha(nil, theme.colors.highlight, 0.075),
        "ARTWORK"
    )
    topSheen:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        1,
        -1
    )
    topSheen:SetPoint(
        "TOPRIGHT",
        frame,
        "TOPRIGHT",
        -1,
        -1
    )
    topSheen:SetHeight(1)
    local bottomShade = ____exports.createSolid(
        nil,
        frame,
        ____exports.withAlpha(nil, theme.colors.shadow, 0.56),
        "ARTWORK"
    )
    bottomShade:SetPoint(
        "BOTTOMLEFT",
        frame,
        "BOTTOMLEFT",
        1,
        1
    )
    bottomShade:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        -1,
        1
    )
    bottomShade:SetHeight(1)
    return {
        frame = frame,
        background = background,
        outline = outline,
        topSheen = topSheen,
        bottomShade = bottomShade,
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
    local inner = ____exports.createSolid(
        nil,
        frame,
        ____exports.withAlpha(nil, theme.colors.highlight, 0.08),
        "ARTWORK"
    )
    inner:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        2,
        -2
    )
    inner:SetPoint(
        "TOPRIGHT",
        frame,
        "TOPRIGHT",
        -2,
        -2
    )
    inner:SetHeight(1)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        4,
        -4
    )
    icon:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        -4,
        4
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
    local outer = ____exports.createOutline(nil, frame, accent)
    local innerTop = ____exports.createSolid(
        nil,
        frame,
        ____exports.withAlpha(nil, theme.colors.highlight, 0.28),
        "BORDER"
    )
    innerTop:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        4,
        -4
    )
    innerTop:SetPoint(
        "TOPRIGHT",
        frame,
        "TOPRIGHT",
        -4,
        -4
    )
    innerTop:SetHeight(1)
    local innerBottom = ____exports.createSolid(
        nil,
        frame,
        ____exports.withAlpha(nil, theme.colors.borderStrong, 0.72),
        "BORDER"
    )
    innerBottom:SetPoint(
        "BOTTOMLEFT",
        frame,
        "BOTTOMLEFT",
        4,
        4
    )
    innerBottom:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        -4,
        4
    )
    innerBottom:SetHeight(1)
    local corner = 12
    local thickness = 2
    local points = {
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
        while i < #points do
            local item = points[i + 1]
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
    if ornate then
        local cornerPath = "Interface\\DialogFrame\\UI-DialogBox-Gold-Corner"
        local topLeft = frame:CreateTexture(nil, "OVERLAY")
        topLeft:SetTexture(cornerPath)
        topLeft:SetSize(26, 26)
        topLeft:SetPoint(
            "TOPLEFT",
            frame,
            "TOPLEFT",
            -3,
            3
        )
        topLeft:SetTexCoord(0, 1, 0, 1)
        local topRight = frame:CreateTexture(nil, "OVERLAY")
        topRight:SetTexture(cornerPath)
        topRight:SetSize(26, 26)
        topRight:SetPoint(
            "TOPRIGHT",
            frame,
            "TOPRIGHT",
            3,
            3
        )
        topRight:SetTexCoord(1, 0, 0, 1)
        local bottomLeft = frame:CreateTexture(nil, "OVERLAY")
        bottomLeft:SetTexture(cornerPath)
        bottomLeft:SetSize(26, 26)
        bottomLeft:SetPoint(
            "BOTTOMLEFT",
            frame,
            "BOTTOMLEFT",
            -3,
            -3
        )
        bottomLeft:SetTexCoord(0, 1, 1, 0)
        local bottomRight = frame:CreateTexture(nil, "OVERLAY")
        bottomRight:SetTexture(cornerPath)
        bottomRight:SetSize(26, 26)
        bottomRight:SetPoint(
            "BOTTOMRIGHT",
            frame,
            "BOTTOMRIGHT",
            3,
            -3
        )
        bottomRight:SetTexCoord(1, 0, 1, 0)
    end
    if #outer.textures == 0 then
        return
    end
end
function ____exports.setRoleIcon(self, texture, role)
    texture:SetTexture(____exports.ROLE_ICON_ATLAS)
    if role == "TANK" then
        texture:SetTexCoord(0, 0.296875, 0.34375, 0.640625)
    elseif role == "HEALER" then
        texture:SetTexCoord(0.3125, 0.609375, 0.015625, 0.3125)
    else
        texture:SetTexCoord(0.3125, 0.609375, 0.34375, 0.640625)
    end
end
function ____exports.createFramedRoleIcon(self, parent, role, size, borderColor)
    if borderColor == nil then
        borderColor = theme.colors.borderStrong
    end
    local framed = ____exports.createFramedIcon(
        nil,
        parent,
        ____exports.ROLE_ICON_ATLAS,
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
    local background = createSolid(nil, frame, options.emphasis == true and theme.colors.surfaceBlue or theme.colors.surfaceRaised)
    background:SetAllPoints(frame)
    local topTint = createSolid(
        nil,
        frame,
        withAlpha(nil, accent, options.emphasis == true and 0.22 or 0.075),
        "ARTWORK"
    )
    topTint:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        1,
        -1
    )
    topTint:SetPoint(
        "TOPRIGHT",
        frame,
        "TOPRIGHT",
        -1,
        -1
    )
    topTint:SetHeight(math.max(
        2,
        math.floor(options.height * 0.46)
    ))
    local bottomShade = createSolid(
        nil,
        frame,
        withAlpha(nil, theme.colors.shadow, 0.48),
        "ARTWORK"
    )
    bottomShade:SetPoint(
        "BOTTOMLEFT",
        frame,
        "BOTTOMLEFT",
        1,
        1
    )
    bottomShade:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        -1,
        1
    )
    bottomShade:SetHeight(math.max(
        1,
        math.floor(options.height * 0.24)
    ))
    local outline = createOutline(nil, frame, options.emphasis == true and accent or theme.colors.border)
    local activeEdge = createSolid(nil, frame, accent, "OVERLAY")
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
    local activeTop = createSolid(
        nil,
        frame,
        withAlpha(nil, accent, 0.88),
        "OVERLAY"
    )
    activeTop:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        1,
        -1
    )
    activeTop:SetPoint(
        "TOPRIGHT",
        frame,
        "TOPRIGHT",
        -1,
        -1
    )
    activeTop:SetHeight(1)
    activeTop:Hide()
    local innerFrame = CreateFrame("Frame", nil, frame)
    innerFrame:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        3,
        -3
    )
    innerFrame:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        -3,
        3
    )
    local innerOutline = createOutline(
        nil,
        innerFrame,
        withAlpha(nil, accent, 0.62)
    )
    innerFrame:Hide()
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
    local function render(self)
        frame:SetAlpha(enabled and 1 or 0.42)
        local emphasized = options.emphasis == true
        outline:setColor((selected or emphasized) and accent or theme.colors.border)
        setTextureColor(nil, background, (selected or emphasized) and theme.colors.surfaceBlue or theme.colors.surfaceRaised)
        setTextureColor(
            nil,
            topTint,
            withAlpha(nil, accent, selected and 0.28 or (emphasized and 0.22 or 0.075))
        )
        if selected then
            activeEdge:Show()
            activeTop:Show()
        else
            activeEdge:Hide()
            activeTop:Hide()
        end
        if selected or emphasized then
            innerOutline:setColor(withAlpha(nil, accent, selected and 0.95 or 0.68))
            innerFrame:Show()
        else
            innerFrame:Hide()
        end
        local color = selected and accent or theme.colors.text
        label:SetTextColor(color[1], color[2], color[3], 1)
    end
    frame:SetScript(
        "OnEnter",
        function()
            if enabled and not selected then
                setTextureColor(nil, background, theme.colors.surfaceHover)
                setTextureColor(
                    nil,
                    topTint,
                    withAlpha(nil, accent, 0.16)
                )
                outline:setColor(options.emphasis == true and accent or theme.colors.borderStrong)
                innerOutline:setColor(withAlpha(nil, accent, 0.58))
                innerFrame:Show()
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
local createChrome = ____Native.createChrome
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
    local move, wheel, bindWheel, refreshRail, positionRowLabel, refreshRows, refresh, trigger, triggerIcon, popup, maxVisible, rowHeight, railWidth, offset, rows, rail, up, down, thumb, thumbCore
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
        thumbCore:SetHeight(math.max(12, thumbHeight - 4))
        thumbCore:ClearAllPoints()
        thumbCore:SetPoint(
            "CENTER",
            thumb,
            "CENTER",
            0,
            0
        )
        thumb:Show()
        thumbCore:Show()
    end
    function positionRowLabel(self, row, hasIcon)
        row.button.label:ClearAllPoints()
        row.button.label:SetPoint(
            "TOPLEFT",
            row.button.frame,
            "TOPLEFT",
            hasIcon and 50 or 10,
            -8
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
            hasIcon and 50 or 10,
            -29
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
        popup.frame:SetHeight(math.max(16, visible * rowHeight + 8))
        do
            local i = 0
            while i < maxVisible do
                local row = rows[i + 1]
                if row == nil then
                    local button = createButton(nil, popup.frame, {text = "", width = options.width - railWidth - 12, height = rowHeight - 4, accent = theme.colors.primary})
                    button.frame:SetPoint(
                        "TOPLEFT",
                        popup.frame,
                        "TOPLEFT",
                        4,
                        -(4 + i * rowHeight)
                    )
                    local iconFrame = createFramedIcon(
                        nil,
                        button.frame,
                        "Interface\\Icons\\INV_Misc_QuestionMark",
                        34,
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
            hasIcon and 44 or 12,
            0
        )
        trigger.label:SetPoint(
            "RIGHT",
            trigger.frame,
            "RIGHT",
            -42,
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
    trigger = createButton(nil, parent, {text = "Select", width = options.width, height = 40, accent = theme.colors.primary})
    triggerIcon = createFramedIcon(
        nil,
        trigger.frame,
        "Interface\\Icons\\INV_Misc_QuestionMark",
        28,
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
    local arrowBox = createPanel(nil, trigger.frame, theme.colors.surfaceDeep, theme.colors.border)
    arrowBox.frame:SetSize(28, 28)
    arrowBox.frame:SetPoint(
        "RIGHT",
        trigger.frame,
        "RIGHT",
        -6,
        0
    )
    local arrow = createText(
        nil,
        arrowBox.frame,
        "v",
        "GameFontHighlightSmall",
        theme.colors.primary
    )
    arrow:SetPoint(
        "CENTER",
        arrowBox.frame,
        "CENTER",
        0,
        0
    )
    arrow:SetJustifyH("CENTER")
    popup = createPanel(nil, trigger.frame, theme.colors.background, theme.colors.borderStrong)
    popup.frame:SetFrameStrata("TOOLTIP")
    popup.frame:SetWidth(options.width)
    popup.frame:EnableMouseWheel(true)
    createChrome(nil, popup.frame, theme.colors.borderStrong)
    popup.frame:Hide()
    maxVisible = options.maxVisible or 8
    rowHeight = 54
    railWidth = 26
    offset = 0
    rows = {}
    rail = createPanel(nil, popup.frame, theme.colors.surfaceDeep, theme.colors.border)
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
            accent = theme.colors.primary,
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
            accent = theme.colors.primary,
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
    track:SetWidth(3)
    local trackGlow = createSolid(
        nil,
        rail.frame,
        withAlpha(nil, theme.colors.primary, 0.12),
        "ARTWORK"
    )
    trackGlow:SetPoint(
        "TOP",
        up.frame,
        "BOTTOM",
        0,
        -4
    )
    trackGlow:SetPoint(
        "BOTTOM",
        down.frame,
        "TOP",
        0,
        4
    )
    trackGlow:SetWidth(7)
    thumb = createSolid(nil, rail.frame, theme.colors.primary, "OVERLAY")
    thumb:SetWidth(7)
    thumb:SetHeight(22)
    thumbCore = createSolid(nil, rail.frame, theme.colors.highlight, "OVERLAY")
    thumbCore:SetWidth(3)
    thumbCore:SetHeight(18)
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
            -5
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
            detail = dungeon.id == "random" and ("WotLK random · Normal Lv " .. tostring(min)) .. "+ · Heroic Lv 80" or ("Normal Lv " .. tostring(min)) .. "+ · Heroic Lv 80",
            icon = ACTIVITY_ICONS[tostring(dungeon.id)] or DEFAULT_DUNGEON_ICON
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
            detail = (____temp_39 .. tostring(____raid_requiredLevel_38)) .. "+",
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
function ____exports.selectedActivityIcon(self)
    local cfg = ____exports.config(nil)
    local ____cfg_activity_54 = cfg.activity
    if ____cfg_activity_54 == nil then
        ____cfg_activity_54 = ""
    end
    local key = tostring(____cfg_activity_54)
    return ACTIVITY_ICONS[key] or (cfg.mode == "RAID" and DEFAULT_RAID_ICON or DEFAULT_DUNGEON_ICON)
end
function ____exports.requiredActivityLevel(self)
    local cfg = ____exports.config(nil)
    if cfg.mode == "RAID" then
        local raid = raidById(nil, cfg.activity)
        local ____opt_result_57
        if raid ~= nil then
            ____opt_result_57 = raid.requiredLevel
        end
        local ____opt_result_57_58 = ____opt_result_57
        if ____opt_result_57_58 == nil then
            ____opt_result_57_58 = 80
        end
        return __TS__Number(____opt_result_57_58)
    end
    if cfg.difficulty ~= "normal" then
        return 80
    end
    local dungeon = dungeonById(nil, cfg.activity)
    local ____opt_result_61
    if dungeon ~= nil then
        ____opt_result_61 = dungeon.minLevel
    end
    local ____opt_result_61_62 = ____opt_result_61
    if ____opt_result_61_62 == nil then
        ____opt_result_61_62 = 68
    end
    return __TS__Number(____opt_result_61_62)
end
function ____exports.activityEligibilityText(self)
    local level = ____exports.requiredActivityLevel(nil)
    local ____opt_63 = ____exports.config(nil).options
    if ____opt_63 ~= nil then
        ____opt_63 = ____opt_63.minimumItemLevel
    end
    local ____opt_63_65 = ____opt_63
    if ____opt_63_65 == nil then
        ____opt_63_65 = 0
    end
    local floor = __TS__Number(____opt_63_65)
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
    local ____opt_result_68
    if raid ~= nil then
        ____opt_result_68 = raid.sizes
    end
    local ____opt_result_68_69 = ____opt_result_68
    if ____opt_result_68_69 == nil then
        ____opt_result_68_69 = {}
    end
    for ____, size in __TS__Iterator(____opt_result_68_69) do
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
    local ____exports_plan_result_members_70 = ____exports.plan(nil).members
    if ____exports_plan_result_members_70 == nil then
        ____exports_plan_result_members_70 = {}
    end
    return ____exports_plan_result_members_70
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
    return "Ready to configure"
end
function ____exports.isBusy(self)
    local ____exports_progress_result_phase_71 = ____exports.progress(nil).phase
    if ____exports_progress_result_phase_71 == nil then
        ____exports_progress_result_phase_71 = "IDLE"
    end
    local phase = tostring(____exports_progress_result_phase_71)
    return phase == "BUILDING" or phase == "PREPARING" or phase == "ASSEMBLING" or phase == "TRAVEL"
end
function ____exports.isTravelRetry(self)
    local p = ____exports.progress(nil)
    local ____temp_73 = p.phase == "READY"
    if ____temp_73 then
        local ____p_detail_72 = p.detail
        if ____p_detail_72 == nil then
            ____p_detail_72 = ""
        end
        ____temp_73 = (string.find(
            tostring(____p_detail_72),
            "Enter Activity",
            nil,
            true
        ) or 0) - 1 >= 0
    end
    return ____temp_73
end
return ____exports
 end,
["widgets.Modal"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____Native = require("core.Native")
local createChrome = ____Native.createChrome
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
    createChrome(nil, panel.frame, theme.colors.chrome, true)
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
        3,
        -3
    )
    headerBg:SetPoint(
        "TOPRIGHT",
        panel.frame,
        "TOPRIGHT",
        -3,
        -3
    )
    headerBg:SetHeight(66)
    local headerTint = createSolid(nil, panel.frame, {0.02, 0.09, 0.15, 0.72}, "ARTWORK")
    headerTint:SetPoint(
        "TOPLEFT",
        panel.frame,
        "TOPLEFT",
        4,
        -4
    )
    headerTint:SetPoint(
        "TOPRIGHT",
        panel.frame,
        "TOPRIGHT",
        -4,
        -4
    )
    headerTint:SetHeight(34)
    local headerAccent = createSolid(nil, panel.frame, theme.colors.primary, "ARTWORK")
    headerAccent:SetPoint(
        "TOPLEFT",
        panel.frame,
        "TOPLEFT",
        4,
        -4
    )
    headerAccent:SetPoint(
        "TOPRIGHT",
        panel.frame,
        "TOPRIGHT",
        -4,
        -4
    )
    headerAccent:SetHeight(2)
    local headerIcon = createFramedIcon(
        nil,
        panel.frame,
        "Interface\\Icons\\INV_Misc_QuestionMark",
        46,
        theme.colors.chrome
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
    subtitle:SetWidth(width - 130)
    local close = createButton(
        nil,
        panel.frame,
        {
            text = "X",
            width = 34,
            height = 34,
            accent = theme.colors.error,
            emphasis = true,
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
        -80
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
        end,
        setHeaderIcon = function(self, path)
            if path == nil or path == "" then
                headerIcon.frame:Hide()
                title:ClearAllPoints()
                title:SetPoint(
                    "TOPLEFT",
                    panel.frame,
                    "TOPLEFT",
                    theme.spacing.lg,
                    -12
                )
                return
            end
            headerIcon.icon:SetTexture(path)
            headerIcon.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            headerIcon.frame:Show()
            title:ClearAllPoints()
            title:SetPoint(
                "TOPLEFT",
                panel.frame,
                "TOPLEFT",
                74,
                -12
            )
        end,
        setHeaderRole = function(self, role)
            if role == nil or role == "" then
                headerIcon.frame:Hide()
                title:ClearAllPoints()
                title:SetPoint(
                    "TOPLEFT",
                    panel.frame,
                    "TOPLEFT",
                    theme.spacing.lg,
                    -12
                )
                return
            end
            setRoleIcon(nil, headerIcon.icon, role)
            headerIcon.frame:Show()
            title:ClearAllPoints()
            title:SetPoint(
                "TOPLEFT",
                panel.frame,
                "TOPLEFT",
                74,
                -12
            )
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
    local update, min, max, value, valueText, plus, minus
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
    frame:SetSize(110, 42)
    min = initialMin
    max = initialMax
    value = initial
    local center = createPanel(nil, frame, theme.colors.surfaceDeep, theme.colors.borderStrong)
    center.frame:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        0,
        0
    )
    center.frame:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        -30,
        0
    )
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
            text = "^",
            width = 26,
            height = 19,
            accent = theme.colors.primary,
            onClick = function() return update(nil, value + 1) end
        }
    )
    plus.frame:SetPoint(
        "TOPRIGHT",
        frame,
        "TOPRIGHT",
        0,
        0
    )
    minus = createButton(
        nil,
        frame,
        {
            text = "v",
            width = 26,
            height = 19,
            accent = theme.colors.primary,
            onClick = function() return update(nil, value - 1) end
        }
    )
    minus.frame:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
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
        return "Melee / Ranged DPS"
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
    marker:SetTexture("Interface\\Buttons\\UI-RadioButton")
    marker:SetSize(22, 22)
    marker:SetPoint(
        "BOTTOM",
        parent,
        "BOTTOM",
        0,
        8
    )
    return marker
end
local function setRadioSelected(self, marker, selected)
    marker:SetTexCoord(selected and 0.25 or 0, selected and 0.5 or 0.25, 0, 1)
    if selected then
        marker:SetVertexColor(theme.colors.primary[1], theme.colors.primary[2], theme.colors.primary[3], 1)
    else
        marker:SetVertexColor(theme.colors.muted[1], theme.colors.muted[2], theme.colors.muted[3], 0.9)
    end
end
function ____exports.createBuildSelector(self, parent, options)
    local refresh, modal, currentRole, currentClass, currentSpec, classSection, classStep, classStepGlow, classStepText, classHint, classTiles, specSection, specStep, specStepGlow, specStepText, specHint, emptySpec, anySpecButton, anySpecMarker, specTiles, summaryClassBadge, summaryClassText, summarySpecBadge, summarySpecText, summaryRoleBadge, summaryRoleText, apply
    function refresh(self)
        local accent = roleAccent(nil, currentRole)
        modal:setTitle(("Add " .. roleLabel(nil, currentRole)) .. " Build")
        modal:setSubtitle(("Choose a class and specialization for this " .. roleLabel(nil, currentRole)) .. " build. Unspecified slots stay Auto-filled.")
        modal:setHeaderRole(currentRole)
        classSection.outline:setColor(accent)
        specSection.outline:setColor(accent)
        classStep.outline:setColor(accent)
        specStep.outline:setColor(accent)
        classStepText:SetTextColor(accent[1], accent[2], accent[3], 1)
        specStepText:SetTextColor(accent[1], accent[2], accent[3], 1)
        classStepGlow:SetVertexColor(accent[1], accent[2], accent[3], 0.65)
        specStepGlow:SetVertexColor(accent[1], accent[2], accent[3], 0.65)
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
                    local column = classIndex % 5
                    local row = math.floor(classIndex / 5)
                    tile.button.frame:ClearAllPoints()
                    tile.button.frame:SetPoint(
                        "TOPLEFT",
                        classSection.frame,
                        "TOPLEFT",
                        14 + column * 202,
                        -(72 + row * 122)
                    )
                    tile.sub:SetText(classRoleSummary(nil, tile.classDef.id, currentRole))
                    tile.specs:SetText(specSummary(nil, tile.classDef.id, currentRole))
                    local selected = tile.classDef.id == currentClass
                    tile.button:setSelected(selected)
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
            specHint:SetText("Pick a class first.")
            emptySpec:Show()
        else
            local selectedClass = getClass(currentClass)
            specHint:SetText(("Select a specialization for your " .. (selectedClass and selectedClass.label or "selected class")) .. " build.")
            emptySpec:Hide()
            local specIndex = 0
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
                        14 + specIndex * 248,
                        -78
                    )
                    tile.sub:SetText(classRoleSummary(nil, tile.classId, currentRole))
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
                14 + specIndex * 248,
                -78
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
    modal = createModal(nil, parent, 1080, 790)
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
    classSection.frame:SetHeight(326)
    classStep = createPanel(nil, classSection.frame, theme.colors.surfaceRaised, theme.colors.borderStrong)
    classStep.frame:SetSize(34, 34)
    classStep.frame:SetPoint(
        "TOPLEFT",
        classSection.frame,
        "TOPLEFT",
        14,
        -14
    )
    classStepGlow = classStep.frame:CreateTexture(nil, "OVERLAY")
    classStepGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    classStepGlow:SetSize(54, 54)
    classStepGlow:SetPoint(
        "CENTER",
        classStep.frame,
        "CENTER",
        0,
        0
    )
    classStepGlow:SetVertexColor(theme.colors.primary[1], theme.colors.primary[2], theme.colors.primary[3], 0.65)
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
    local classTitle = createText(nil, classSection.frame, "CHOOSE A CLASS", "GameFontNormalLarge")
    classTitle:SetPoint(
        "TOPLEFT",
        classSection.frame,
        "TOPLEFT",
        60,
        -13
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
        -4
    )
    classTiles = {}
    for ____, classDef in ipairs(selectorClassesForRole(nil, "DPS")) do
        local button = createButton(nil, classSection.frame, {text = classDef.label, width = 190, height = 116, accent = theme.colors.primary})
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
        local iconFrame = createPanel(
            nil,
            button.frame,
            theme.colors.surfaceDeep,
            classColor(nil, classDef.id)
        )
        iconFrame.frame:SetSize(46, 46)
        iconFrame.frame:SetPoint(
            "TOP",
            button.frame,
            "TOP",
            0,
            -11
        )
        local icon = iconFrame.frame:CreateTexture(nil, "ARTWORK")
        icon:SetPoint(
            "TOPLEFT",
            iconFrame.frame,
            "TOPLEFT",
            3,
            -3
        )
        icon:SetPoint(
            "BOTTOMRIGHT",
            iconFrame.frame,
            "BOTTOMRIGHT",
            -3,
            3
        )
        setClassIcon(nil, icon, classDef.id)
        button.label:ClearAllPoints()
        button.label:SetPoint(
            "TOP",
            button.frame,
            "TOP",
            0,
            -65
        )
        button.label:SetWidth(174)
        button.label:SetJustifyH("CENTER")
        local sub = createText(
            nil,
            button.frame,
            "",
            "GameFontHighlightSmall",
            theme.colors.muted
        )
        sub:SetPoint(
            "TOP",
            button.frame,
            "TOP",
            0,
            -84
        )
        sub:SetWidth(174)
        sub:SetJustifyH("CENTER")
        local specs = createText(
            nil,
            button.frame,
            "",
            "GameFontHighlightSmall",
            theme.colors.muted
        )
        specs:SetPoint(
            "TOP",
            button.frame,
            "TOP",
            0,
            -101
        )
        specs:SetWidth(174)
        specs:SetJustifyH("CENTER")
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
        modal.content,
        "TOPLEFT",
        0,
        -340
    )
    specSection.frame:SetPoint(
        "TOPRIGHT",
        modal.content,
        "TOPRIGHT",
        0,
        -340
    )
    specSection.frame:SetHeight(220)
    specStep = createPanel(nil, specSection.frame, theme.colors.surfaceRaised, theme.colors.borderStrong)
    specStep.frame:SetSize(34, 34)
    specStep.frame:SetPoint(
        "TOPLEFT",
        specSection.frame,
        "TOPLEFT",
        14,
        -14
    )
    specStepGlow = specStep.frame:CreateTexture(nil, "OVERLAY")
    specStepGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    specStepGlow:SetSize(54, 54)
    specStepGlow:SetPoint(
        "CENTER",
        specStep.frame,
        "CENTER",
        0,
        0
    )
    specStepGlow:SetVertexColor(theme.colors.primary[1], theme.colors.primary[2], theme.colors.primary[3], 0.65)
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
    local specTitle = createText(nil, specSection.frame, "CHOOSE A SPECIALIZATION", "GameFontNormalLarge")
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
            width = 236,
            height = 104,
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
    local anySpecIcon = createIcon(nil, anySpecButton.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 46)
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
        70,
        -20
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
        "Let Composer choose for me",
        "GameFontHighlightSmall",
        theme.colors.muted
    )
    anySpecSub:SetPoint(
        "TOPLEFT",
        anySpecButton.frame,
        "TOPLEFT",
        70,
        -49
    )
    anySpecSub:SetWidth(136)
    anySpecSub:SetJustifyV("TOP")
    anySpecMarker = createRadioMarker(nil, anySpecButton.frame)
    setRadioSelected(nil, anySpecMarker, false)
    anySpecButton.frame:Hide()
    specTiles = {}
    for ____, classDef in ipairs(selectorClassesForRole(nil, "DPS")) do
        for ____, spec in ipairs(classDef.specs) do
            local button = createButton(nil, specSection.frame, {text = spec.label, width = 236, height = 104, accent = theme.colors.primary})
            local icon = createIcon(nil, button.frame, spec.icon, 46)
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
                70,
                -20
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
                70,
                -49
            )
            sub:SetWidth(136)
            local marker = createRadioMarker(nil, button.frame)
            setRadioSelected(nil, marker, false)
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
    summary.frame:SetHeight(118)
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
        14,
        -10
    )
    summaryClassBadge = createFramedIcon(
        nil,
        summary.frame,
        "Interface\\Icons\\INV_Misc_QuestionMark",
        46,
        theme.colors.borderStrong
    )
    summaryClassBadge.frame:SetPoint(
        "BOTTOMLEFT",
        summary.frame,
        "BOTTOMLEFT",
        14,
        12
    )
    summaryClassText = createText(nil, summary.frame, "Choose class", "GameFontNormal")
    summaryClassText:SetPoint(
        "TOPLEFT",
        summary.frame,
        "TOPLEFT",
        70,
        -48
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
        -4
    )
    summarySpecBadge = createFramedIcon(
        nil,
        summary.frame,
        "Interface\\Icons\\INV_Misc_QuestionMark",
        46,
        theme.colors.borderStrong
    )
    summarySpecBadge.frame:SetPoint(
        "BOTTOMLEFT",
        summary.frame,
        "BOTTOMLEFT",
        190,
        12
    )
    summarySpecText = createText(nil, summary.frame, "Choose spec", "GameFontNormal")
    summarySpecText:SetPoint(
        "TOPLEFT",
        summary.frame,
        "TOPLEFT",
        246,
        -48
    )
    summarySpecText:SetWidth(112)
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
        -4
    )
    summaryRoleBadge = createFramedRoleIcon(
        nil,
        summary.frame,
        "DPS",
        46,
        theme.colors.dps
    )
    summaryRoleBadge.frame:SetPoint(
        "BOTTOMLEFT",
        summary.frame,
        "BOTTOMLEFT",
        372,
        12
    )
    summaryRoleText = createText(nil, summary.frame, "DPS", "GameFontNormal")
    summaryRoleText:SetPoint(
        "TOPLEFT",
        summary.frame,
        "TOPLEFT",
        428,
        -48
    )
    summaryRoleText:SetWidth(86)
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
        -4
    )
    local summaryDivider = createSolid(nil, summary.frame, theme.colors.borderStrong, "ARTWORK")
    summaryDivider:SetPoint(
        "TOPLEFT",
        summary.frame,
        "TOPLEFT",
        536,
        -36
    )
    summaryDivider:SetHeight(62)
    summaryDivider:SetWidth(1)
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
        560,
        -48
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
        618,
        -10
    )
    apply = createButton(
        nil,
        summary.frame,
        {
            text = "Use this build",
            width = 184,
            height = 48,
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
local createPanel = ____Native.createPanel
local createSolid = ____Native.createSolid
local withAlpha = ____Native.withAlpha
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
local ____Button = require("widgets.Button")
local createButton = ____Button.createButton
function ____exports.createScrollList(self, parent, width, height)
    local maxOffset, clamp, refreshRail, scroll, rail, contentHeight, offset, up, down, thumb, thumbCore
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
        local trackHeight = math.max(28, height - 52)
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
        thumbCore:SetHeight(math.max(14, thumbHeight - 4))
        thumbCore:ClearAllPoints()
        thumbCore:SetPoint(
            "CENTER",
            thumb,
            "CENTER",
            0,
            0
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
        -22,
        0
    )
    scroll:SetSize(
        math.max(1, width - 22),
        height
    )
    scroll:EnableMouseWheel(true)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(math.max(1, width - 22))
    content:SetHeight(height)
    content:EnableMouseWheel(true)
    scroll:SetScrollChild(content)
    rail = createPanel(nil, frame, theme.colors.surfaceDeep, theme.colors.border)
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
    rail.frame:SetWidth(18)
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
            width = 18,
            height = 22,
            accent = theme.colors.primary,
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
            width = 18,
            height = 22,
            accent = theme.colors.primary,
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
    local trackGlow = createSolid(
        nil,
        rail.frame,
        withAlpha(nil, theme.colors.primary, 0.11),
        "ARTWORK"
    )
    trackGlow:SetPoint(
        "TOP",
        up.frame,
        "BOTTOM",
        0,
        -4
    )
    trackGlow:SetPoint(
        "BOTTOM",
        down.frame,
        "TOP",
        0,
        4
    )
    trackGlow:SetWidth(7)
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
    thumb:SetWidth(8)
    thumb:SetHeight(24)
    thumbCore = createSolid(nil, rail.frame, theme.colors.highlight, "OVERLAY")
    thumbCore:SetWidth(3)
    thumbCore:SetHeight(20)
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
["widgets.Toggle"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____Native = require("core.Native")
local createPanel = ____Native.createPanel
local createSolid = ____Native.createSolid
local createText = ____Native.createText
local withAlpha = ____Native.withAlpha
local ____Theme = require("theme.Theme")
local theme = ____Theme.theme
function ____exports.createToggle(self, parent, label, getValue, setValue)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(32)
    frame:EnableMouse(true)
    local track = createPanel(nil, frame, theme.colors.surfaceDeep, theme.colors.borderStrong)
    track.frame:SetSize(42, 22)
    track.frame:SetPoint(
        "LEFT",
        frame,
        "LEFT",
        0,
        0
    )
    local trackGlow = createSolid(
        nil,
        track.frame,
        withAlpha(nil, theme.colors.success, 0.12),
        "ARTWORK"
    )
    trackGlow:SetAllPoints(track.frame)
    trackGlow:Hide()
    local knob = createPanel(nil, track.frame, theme.colors.muted, theme.colors.borderStrong)
    knob.frame:SetSize(16, 16)
    knob.frame:SetPoint(
        "LEFT",
        track.frame,
        "LEFT",
        3,
        0
    )
    local text = createText(nil, frame, label, "GameFontHighlightSmall")
    text:SetPoint(
        "LEFT",
        track.frame,
        "RIGHT",
        10,
        0
    )
    local function refresh(self)
        local enabled = getValue(nil)
        knob.frame:ClearAllPoints()
        if enabled then
            knob.frame:SetPoint(
                "RIGHT",
                track.frame,
                "RIGHT",
                -3,
                0
            )
            knob:setBackground(theme.colors.success)
            knob.outline:setColor(theme.colors.success)
            track.outline:setColor(theme.colors.success)
            trackGlow:Show()
            text:SetTextColor(theme.colors.text[1], theme.colors.text[2], theme.colors.text[3], 1)
        else
            knob.frame:SetPoint(
                "LEFT",
                track.frame,
                "LEFT",
                3,
                0
            )
            knob:setBackground(theme.colors.muted)
            knob.outline:setColor(theme.colors.borderStrong)
            track.outline:setColor(theme.colors.borderStrong)
            trackGlow:Hide()
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
local ICON_DUNGEON = "Interface\\Icons\\Spell_Arcane_PortalDalaran"
local ICON_RAID = "Interface\\Icons\\Achievement_Boss_LichKing"
local ICON_TEMPLATES = "Interface\\Icons\\INV_Scroll_03"
local ICON_PEOPLE = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02"
local ICON_OPTIONS = "Interface\\Icons\\INV_Gizmo_02"
local ICON_COVERAGE = "Interface\\Icons\\INV_Misc_Map_01"
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
        return ((tostring(cfg.size) .. " player  ·  ") .. (cfg.difficulty == "heroic" and "Heroic" or "Normal")) .. "  ·  Auto-enter after assembly"
    end
    local mode = cfg.difficulty == "alpha" and "Titan Rune Alpha" or (cfg.difficulty == "beta" and "Titan Rune Beta" or (cfg.difficulty == "gamma" and "Titan Rune Gamma" or (cfg.difficulty == "heroic" and "Heroic" or "Normal")))
    return (mode .. "  ·  5 player  ·  ") .. (cfg.activity == "random" and "Dungeon Finder chooses destination" or "Auto-enter after assembly")
end
function ____exports.createModernDashboard(self)
    local clearDynamicRows, refreshTemplates, refreshPeople, roleOrder, templatesModal, templateSave, builtinScroll, customScroll, builtinRows, customRows, builtinEmpty, customEmpty, humanScroll, humanRowsModal, humanEmpty, pinRole, pinRoleButtons, pinToggle, pinScroll, pinRows, pinEmpty
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
        if #builtins == 0 then
            builtinEmpty:Show()
        else
            builtinEmpty:Hide()
        end
        do
            local i = 0
            while i < #builtins do
                local row = builtinRows[i + 1]
                if row == nil then
                    local panel = Native:createPanel(builtinScroll.content, theme.colors.surfaceRaised, theme.colors.border)
                    panel.frame:SetSize(438, 76)
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
                    local iconBadge = Native:createFramedIcon(panel.frame, ICON_RAID, 42, theme.colors.primary)
                    iconBadge.frame:SetPoint(
                        "LEFT",
                        panel.frame,
                        "LEFT",
                        10,
                        0
                    )
                    local name = Native:createText(panel.frame, "", "GameFontHighlight")
                    name:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        62,
                        -10
                    )
                    name:SetWidth(258)
                    local builtinTag = Native:createText(panel.frame, "BUILT-IN", "GameFontNormalSmall", theme.colors.primary)
                    builtinTag:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        62,
                        -31
                    )
                    local info = Native:createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted)
                    info:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        122,
                        -31
                    )
                    info:SetWidth(200)
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
        if #customs == 0 then
            customEmpty:Show()
        else
            customEmpty:Hide()
        end
        do
            local i = 0
            while i < #customs do
                local row = customRows[i + 1]
                if row == nil then
                    local panel = Native:createPanel(customScroll.content, theme.colors.surfaceRaised, theme.colors.border)
                    panel.frame:SetSize(438, 76)
                    local accent = Native:createSolid(panel.frame, theme.colors.warning, "ARTWORK")
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
                    local iconBadge = Native:createFramedIcon(panel.frame, ICON_TEMPLATES, 42, theme.colors.warning)
                    iconBadge.frame:SetPoint(
                        "LEFT",
                        panel.frame,
                        "LEFT",
                        10,
                        0
                    )
                    local name = Native:createText(panel.frame, "", "GameFontHighlight")
                    name:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        62,
                        -10
                    )
                    name:SetWidth(190)
                    local customTag = Native:createText(panel.frame, "CUSTOM", "GameFontNormalSmall", theme.colors.warning)
                    customTag:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        62,
                        -31
                    )
                    local info = Native:createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted)
                    info:SetPoint(
                        "TOPLEFT",
                        panel.frame,
                        "TOPLEFT",
                        115,
                        -31
                    )
                    info:SetWidth(142)
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
                    panel.frame:SetSize(892, 50)
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
                        "LEFT",
                        panel.frame,
                        "LEFT",
                        52,
                        7
                    )
                    name:SetWidth(250)
                    local identity = Native:createText(panel.frame, "REAL PLAYER", "GameFontNormalSmall", theme.colors.primary)
                    identity:SetPoint(
                        "LEFT",
                        panel.frame,
                        "LEFT",
                        52,
                        -10
                    )
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
                    panel.frame._classBadge = classBadge
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
                    -(i * 56)
                )
                Native:setClassIcon(
                    row._icon,
                    tostring(human.class)
                )
                row._classBadge.outline:setColor(Native:classColor(tostring(human.class)))
                row._name:SetText((((human.isPlayer and "YOU  ·  " or "") .. human.name) .. "  ·  ") .. Model:classLabel(tostring(human.class)))
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
        humanScroll:setContentHeight(math.max(210, #list * 56))
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
                    panel.frame:SetSize(892, 48)
                    local roleBadge = Native:createFramedRoleIcon(panel.frame, "DPS", 34, theme.colors.dps)
                    roleBadge.frame:SetPoint(
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
                        52,
                        7
                    )
                    name:SetWidth(250)
                    local info = Native:createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted)
                    info:SetPoint(
                        "LEFT",
                        panel.frame,
                        "LEFT",
                        52,
                        -10
                    )
                    info:SetWidth(330)
                    local remove = ButtonUI:createButton(panel.frame, {text = "Remove", width = 78, height = 28, accent = theme.colors.error})
                    remove.frame:SetPoint(
                        "RIGHT",
                        panel.frame,
                        "RIGHT",
                        -6,
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
                    -(i * 54)
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
        pinScroll:setContentHeight(math.max(190, #pins * 54))
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
    Native:createChrome(mark.frame, theme.colors.primary)
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
    local backendGlow = Native:createSolid(
        header.frame,
        Native:withAlpha(theme.colors.success, 0.18),
        "ARTWORK"
    )
    backendGlow:SetSize(18, 18)
    backendGlow:SetPoint(
        "RIGHT",
        header.frame,
        "RIGHT",
        -233,
        0
    )
    backendGlow:Hide()
    local backendDot = Native:createSolid(header.frame, theme.colors.muted, "OVERLAY")
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
        34
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
    local navDungeon = ButtonUI:createButton(
        sidebar.frame,
        {
            text = "Dungeon",
            width = 152,
            height = 46,
            accent = theme.colors.primary,
            icon = ICON_DUNGEON,
            iconSize = 24,
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
    navDungeon.label:SetJustifyH("LEFT")
    local navRaid = ButtonUI:createButton(
        sidebar.frame,
        {
            text = "Raid",
            width = 152,
            height = 46,
            accent = theme.colors.warning,
            icon = ICON_RAID,
            iconSize = 24,
            onClick = function() return Model:setMode("RAID") end
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
    local manageTitle = Native:createText(sidebar.frame, "TOOLS", "GameFontNormalSmall", theme.colors.muted)
    manageTitle:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -174
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
            onClick = function() return showTemplates(nil) end
        }
    )
    navTemplates.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -198
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
            onClick = function() return showPeople(nil) end
        }
    )
    navPeople.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -248
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
            onClick = function() return showOptions(nil) end
        }
    )
    navOptions.frame:SetPoint(
        "TOPLEFT",
        sidebar.frame,
        "TOPLEFT",
        14,
        -298
    )
    navOptions.label:SetJustifyH("LEFT")
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
    center:SetSize(970, 768)
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
        48
    )
    local footer = Native:createPanel(frame, theme.colors.surface, theme.colors.border)
    footer.frame:SetPoint(
        "BOTTOMLEFT",
        frame,
        "BOTTOMLEFT",
        200,
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
    local activityBadge = Native:createFramedIcon(activity.frame, ICON_DUNGEON, 64, theme.colors.borderStrong)
    activityBadge.frame:SetPoint(
        "TOPLEFT",
        activity.frame,
        "TOPLEFT",
        16,
        -38
    )
    local activityName = Native:createText(activity.frame, "Dungeon", "GameFontNormalLarge")
    activityName:SetPoint(
        "TOPLEFT",
        activity.frame,
        "TOPLEFT",
        96,
        -38
    )
    activityName:SetWidth(218)
    local activitySub = Native:createText(activity.frame, "", "GameFontHighlightSmall", theme.colors.muted)
    activitySub:SetPoint(
        "TOPLEFT",
        activityName,
        "BOTTOMLEFT",
        0,
        -5
    )
    activitySub:SetWidth(218)
    local activityEligibility = Native:createText(activity.frame, "", "GameFontHighlightSmall", theme.colors.success)
    activityEligibility:SetPoint(
        "TOPLEFT",
        activitySub,
        "BOTTOMLEFT",
        0,
        -7
    )
    activityEligibility:SetWidth(218)
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
        Native:withAlpha(theme.colors.chromeBright, 0.38),
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
    humanTop:SetHeight(1)
    local humanTitle = Native:createText(humanPanel.frame, "YOUR PARTY", "GameFontNormalSmall", theme.colors.muted)
    humanTitle:SetPoint(
        "TOPLEFT",
        humanPanel.frame,
        "TOPLEFT",
        16,
        -12
    )
    local humanBadge = Native:createFramedIcon(humanPanel.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 42, theme.colors.borderStrong)
    humanBadge.frame:SetPoint(
        "BOTTOMLEFT",
        humanPanel.frame,
        "BOTTOMLEFT",
        14,
        8
    )
    local humanIcon = humanBadge.icon
    Native:setClassIcon(humanIcon, "WARRIOR")
    local humanName = Native:createText(humanPanel.frame, "Choose your role", "GameFontNormal")
    humanName:SetPoint(
        "TOPLEFT",
        humanBadge.frame,
        "TOPRIGHT",
        10,
        -1
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
            row.frame:SetHeight(76)
            row.frame:SetPoint(
                "TOPLEFT",
                dungeonView,
                "TOPLEFT",
                0,
                -(i * 82)
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
            local roleBadge = Native:createFramedRoleIcon(row.frame, "DPS", 44, theme.colors.borderStrong)
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
                8
            )
            local slotText = Native:createText(row.frame, "Slot", "GameFontHighlightSmall", theme.colors.muted)
            slotText:SetPoint(
                "LEFT",
                roleBadge.frame,
                "RIGHT",
                10,
                -10
            )
            local classBadge = Native:createFramedIcon(row.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 46, theme.colors.borderStrong)
            classBadge.frame:SetPoint(
                "LEFT",
                row.frame,
                "LEFT",
                170,
                0
            )
            classBadge.frame:Hide()
            local classIcon = classBadge.icon
            local specBadge = Native:createFramedIcon(row.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 40, theme.colors.borderStrong)
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
                270,
                -18
            )
            name:SetWidth(350)
            local sub = Native:createText(row.frame, "Composer chooses a suitable build", "GameFontHighlightSmall", theme.colors.muted)
            sub:SetPoint(
                "TOPLEFT",
                name,
                "BOTTOMLEFT",
                0,
                -5
            )
            sub:SetWidth(390)
            local choose = ButtonUI:createButton(row.frame, {text = "Choose build", width = 136, height = 38, accent = theme.colors.primary})
            choose.frame:SetPoint(
                "RIGHT",
                row.frame,
                "RIGHT",
                -82,
                0
            )
            local auto = ButtonUI:createButton(row.frame, {text = "Auto", width = 68, height = 38})
            auto.frame:SetPoint(
                "RIGHT",
                row.frame,
                "RIGHT",
                -12,
                0
            )
            local humanAnchor = ButtonUI:createButton(row.frame, {text = "Human anchor", width = 136, height = 38, accent = theme.colors.borderStrong})
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
    local tabQuick = ButtonUI:createButton(raidView, {text = "Quick Composition", width = 164, height = 38, accent = theme.colors.warning})
    tabQuick.frame:SetPoint(
        "TOPLEFT",
        raidView,
        "TOPLEFT",
        0,
        0
    )
    local tabExact = ButtonUI:createButton(raidView, {text = "Specific Builds", width = 150, height = 38, accent = theme.colors.warning})
    tabExact.frame:SetPoint(
        "LEFT",
        tabQuick.frame,
        "RIGHT",
        8,
        0
    )
    local tabRoster = ButtonUI:createButton(raidView, {text = "Prepared Roster", width = 150, height = 38, accent = theme.colors.success})
    tabRoster.frame:SetPoint(
        "LEFT",
        tabExact.frame,
        "RIGHT",
        8,
        0
    )
    local resetRoles = ButtonUI:createButton(
        raidView,
        {
            text = "Reset roles",
            width = 100,
            height = 34,
            onClick = function() return Model:resetRoleTargets() end
        }
    )
    resetRoles.frame:SetPoint(
        "TOPRIGHT",
        raidView,
        "TOPRIGHT",
        0,
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
            local card = Native:createPanel(quickView, theme.colors.surfaceDeep, theme.colors.borderStrong)
            card.frame:SetSize(300, 226)
            local roleStrip = Native:createSolid(
                card.frame,
                Model:roleAccent(role),
                "ARTWORK"
            )
            roleStrip:SetHeight(4)
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
                Native:withAlpha(
                    Model:roleAccent(role),
                    0.055
                ),
                "BACKGROUND"
            )
            roleTint:SetAllPoints(card.frame)
            card.frame:SetPoint(
                "TOPLEFT",
                quickView,
                "TOPLEFT",
                i * 312,
                -12
            )
            local roleBadge = Native:createFramedRoleIcon(
                card.frame,
                role,
                54,
                Model:roleAccent(role)
            )
            roleBadge.frame:SetPoint(
                "TOP",
                card.frame,
                "TOP",
                -46,
                -16
            )
            local label = Native:createText(
                card.frame,
                string.upper(Model:roleLabel(role)),
                "GameFontNormalLarge",
                Model:roleAccent(role)
            )
            label:SetPoint(
                "LEFT",
                roleBadge.frame,
                "RIGHT",
                12,
                0
            )
            local minus = ButtonUI:createButton(
                card.frame,
                {
                    text = "-",
                    width = 42,
                    height = 40,
                    accent = Model:roleAccent(role)
                }
            )
            minus.frame:SetPoint(
                "TOPLEFT",
                card.frame,
                "TOPLEFT",
                32,
                -88
            )
            local countPanel = Native:createPanel(card.frame, theme.colors.background, theme.colors.borderStrong)
            countPanel.frame:SetPoint(
                "TOPLEFT",
                card.frame,
                "TOPLEFT",
                86,
                -88
            )
            countPanel.frame:SetSize(128, 40)
            local count = Native:createText(countPanel.frame, "0", "GameFontNormalHuge")
            count:SetPoint(
                "CENTER",
                countPanel.frame,
                "CENTER",
                0,
                0
            )
            count:SetWidth(100)
            count:SetJustifyH("CENTER")
            local plus = ButtonUI:createButton(
                card.frame,
                {
                    text = "+",
                    width = 42,
                    height = 40,
                    accent = Model:roleAccent(role)
                }
            )
            plus.frame:SetPoint(
                "TOPRIGHT",
                card.frame,
                "TOPRIGHT",
                -32,
                -88
            )
            local botSlots = Native:createText(card.frame, "0 bot slots after humans", "GameFontHighlightSmall", theme.colors.muted)
            botSlots:SetPoint(
                "TOP",
                card.frame,
                "TOP",
                0,
                -140
            )
            botSlots:SetWidth(260)
            botSlots:SetJustifyH("CENTER")
            botSlots:SetJustifyV("TOP")
            local roleHelp = Native:createText(
                card.frame,
                roleDescription(nil, role),
                "GameFontHighlightSmall",
                theme.colors.muted
            )
            roleHelp:SetPoint(
                "BOTTOM",
                card.frame,
                "BOTTOM",
                0,
                17
            )
            roleHelp:SetWidth(250)
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
    local quickSummary = Native:createPanel(quickView, theme.colors.background, theme.colors.borderStrong)
    quickSummary.frame:SetPoint(
        "TOPLEFT",
        quickView,
        "TOPLEFT",
        0,
        -252
    )
    quickSummary.frame:SetPoint(
        "TOPRIGHT",
        quickView,
        "TOPRIGHT",
        0,
        -252
    )
    quickSummary.frame:SetHeight(92)
    local quickTotalLabel = Native:createText(quickSummary.frame, "TOTAL RAID SIZE", "GameFontNormalSmall", theme.colors.muted)
    quickTotalLabel:SetPoint(
        "TOPLEFT",
        quickSummary.frame,
        "TOPLEFT",
        18,
        -14
    )
    local quickTotal = Native:createText(quickSummary.frame, "25 / 25", "GameFontNormalHuge")
    quickTotal:SetPoint(
        "TOPLEFT",
        quickSummary.frame,
        "TOPLEFT",
        18,
        -38
    )
    local quickDivider = Native:createSolid(quickSummary.frame, theme.colors.borderStrong, "ARTWORK")
    quickDivider:SetPoint(
        "TOPLEFT",
        quickSummary.frame,
        "TOPLEFT",
        205,
        -12
    )
    quickDivider:SetHeight(68)
    quickDivider:SetWidth(1)
    local quickCheck = Native:createPanel(quickSummary.frame, theme.colors.surfaceDeep, theme.colors.success)
    quickCheck.frame:SetSize(34, 34)
    quickCheck.frame:SetPoint(
        "LEFT",
        quickSummary.frame,
        "LEFT",
        232,
        0
    )
    local quickCheckIcon = quickCheck.frame:CreateTexture(nil, "ARTWORK")
    quickCheckIcon:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    quickCheckIcon:SetAllPoints(quickCheck.frame)
    local quickCheckBang = Native:createText(quickCheck.frame, "!", "GameFontNormalLarge", theme.colors.warning)
    quickCheckBang:SetPoint(
        "CENTER",
        quickCheck.frame,
        "CENTER",
        0,
        0
    )
    quickCheckBang:SetJustifyH("CENTER")
    quickCheckBang:Hide()
    local quickStatusTitle = Native:createText(quickSummary.frame, "Raid composition is complete!", "GameFontNormal", theme.colors.success)
    quickStatusTitle:SetPoint(
        "TOPLEFT",
        quickSummary.frame,
        "TOPLEFT",
        280,
        -24
    )
    quickStatusTitle:SetWidth(360)
    local quickStatusDetail = Native:createText(quickSummary.frame, "This setup will create the selected raid size with your chosen role balance.", "GameFontHighlightSmall", theme.colors.muted)
    quickStatusDetail:SetPoint(
        "TOPLEFT",
        quickStatusTitle,
        "BOTTOMLEFT",
        0,
        -6
    )
    quickStatusDetail:SetWidth(410)
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
        roleStrip:SetHeight(4)
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
            Native:withAlpha(
                Model:roleAccent(role),
                0.045
            ),
            "BACKGROUND"
        )
        roleTint:SetAllPoints(panel.frame)
        local roleBadge = Native:createFramedRoleIcon(
            panel.frame,
            role,
            42,
            Model:roleAccent(role)
        )
        roleBadge.frame:SetPoint(
            "TOPLEFT",
            panel.frame,
            "TOPLEFT",
            14,
            -12
        )
        local icon = roleBadge.icon
        local label = Native:createText(
            panel.frame,
            string.upper(Model:roleLabel(role)),
            "GameFontNormal",
            Model:roleAccent(role)
        )
        label:SetPoint(
            "LEFT",
            roleBadge.frame,
            "RIGHT",
            10,
            5
        )
        local count = Native:createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted)
        count:SetPoint(
            "LEFT",
            roleBadge.frame,
            "RIGHT",
            10,
            -12
        )
        count:SetWidth(430)
        local add = ButtonUI:createButton(
            panel.frame,
            {
                text = "+ Add specific build",
                width = 168,
                height = 34,
                accent = Model:roleAccent(role),
                emphasis = true
            }
        )
        add.frame:SetPoint(
            "TOPRIGHT",
            panel.frame,
            "TOPRIGHT",
            -12,
            -14
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
                    local iconBadge = Native:createFramedIcon(row, "Interface\\Icons\\INV_Misc_QuestionMark", 26, theme.colors.border)
                    iconBadge.frame:SetPoint(
                        "LEFT",
                        row,
                        "LEFT",
                        6,
                        0
                    )
                    local icon = iconBadge.icon
                    iconBadge.frame:Hide()
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
                        iconBadge = iconBadge,
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
    local statusTitle = Native:createText(status.frame, "ROSTER STATUS", "GameFontNormalSmall", theme.colors.muted)
    statusTitle:SetPoint(
        "TOPLEFT",
        status.frame,
        "TOPLEFT",
        16,
        -16
    )
    local phaseCard = Native:createPanel(status.frame, theme.colors.surfaceBlue, theme.colors.borderStrong)
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
    phaseCard.frame:SetHeight(96)
    local phaseAccent = Native:createSolid(phaseCard.frame, theme.colors.primary, "ARTWORK")
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
    local phaseGlow = Native:createSolid(
        phaseCard.frame,
        Native:withAlpha(theme.colors.primary, 0.16),
        "ARTWORK"
    )
    phaseGlow:SetSize(18, 18)
    phaseGlow:SetPoint(
        "TOPLEFT",
        phaseCard.frame,
        "TOPLEFT",
        10,
        -11
    )
    local phaseDot = Native:createSolid(phaseCard.frame, theme.colors.primary, "OVERLAY")
    phaseDot:SetSize(9, 9)
    phaseDot:SetPoint(
        "TOPLEFT",
        phaseCard.frame,
        "TOPLEFT",
        14,
        -15
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
        -152
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
            chip.frame:SetSize(86, 34)
            chip.frame:SetPoint(
                "TOPLEFT",
                status.frame,
                "TOPLEFT",
                16 + i * 90,
                -210
            )
            local icon = chip.frame:CreateTexture(nil, "ARTWORK")
            icon:SetSize(17, 17)
            icon:SetPoint(
                "LEFT",
                chip.frame,
                "LEFT",
                6,
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
        -254
    )
    progressBg.frame:SetSize(270, 14)
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
        -274
    )
    progressText:SetWidth(270)
    local coverageCard = Native:createPanel(status.frame, theme.colors.background, theme.colors.border)
    coverageCard.frame:SetPoint(
        "TOPLEFT",
        status.frame,
        "TOPLEFT",
        16,
        -312
    )
    coverageCard.frame:SetPoint(
        "TOPRIGHT",
        status.frame,
        "TOPRIGHT",
        -16,
        -312
    )
    coverageCard.frame:SetHeight(120)
    local coverageGlyph = Native:createPanel(coverageCard.frame, theme.colors.surfaceDeep, theme.colors.borderStrong)
    coverageGlyph.frame:SetSize(32, 32)
    coverageGlyph.frame:SetPoint(
        "TOPLEFT",
        coverageCard.frame,
        "TOPLEFT",
        12,
        -12
    )
    do
        local i = 0
        while i < 3 do
            local bar = Native:createSolid(coverageGlyph.frame, theme.colors.text, "ARTWORK")
            bar:SetWidth(5)
            bar:SetHeight(8 + i * 6)
            bar:SetPoint(
                "BOTTOMLEFT",
                coverageGlyph.frame,
                "BOTTOMLEFT",
                6 + i * 8,
                5
            )
            i = i + 1
        end
    end
    local coverageTitle = Native:createText(coverageCard.frame, "COVERAGE", "GameFontNormalSmall", theme.colors.muted)
    coverageTitle:SetPoint(
        "LEFT",
        coverageGlyph.frame,
        "RIGHT",
        9,
        0
    )
    local coverageText = Native:createText(coverageCard.frame, "Build a roster to inspect coverage.", "GameFontHighlightSmall", theme.colors.muted)
    coverageText:SetPoint(
        "TOPLEFT",
        coverageCard.frame,
        "TOPLEFT",
        12,
        -52
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
        -448
    )
    nextCard.frame:SetPoint(
        "TOPRIGHT",
        status.frame,
        "TOPRIGHT",
        -16,
        -448
    )
    nextCard.frame:SetHeight(126)
    local nextBadge = Native:createPanel(nextCard.frame, theme.colors.surfaceDeep, theme.colors.warning)
    nextBadge.frame:SetSize(28, 28)
    nextBadge.frame:SetPoint(
        "TOPLEFT",
        nextCard.frame,
        "TOPLEFT",
        12,
        -12
    )
    local nextBang = Native:createText(nextBadge.frame, "!", "GameFontNormal", theme.colors.warning)
    nextBang:SetPoint(
        "CENTER",
        nextBadge.frame,
        "CENTER",
        0,
        0
    )
    nextBang:SetJustifyH("CENTER")
    local warningsTitle = Native:createText(nextCard.frame, "NEXT STEP", "GameFontNormalSmall", theme.colors.warning)
    warningsTitle:SetPoint(
        "LEFT",
        nextBadge.frame,
        "RIGHT",
        9,
        0
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
                -(50 + i * 24)
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
    local assembleButton = ButtonUI:createButton(
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
    local resetButton = ButtonUI:createButton(
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
    templatesModal = ModalUI:createModal(frame, 1020, 720)
    templatesModal:setTitle("Raid Templates")
    templatesModal:setSubtitle("Coverage-first raid cores reserve key buffs; every unlisted slot stays Auto-filled.")
    templatesModal:setHeaderIcon(ICON_TEMPLATES)
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
            width = 124,
            height = 36,
            accent = theme.colors.primary,
            emphasis = true,
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
    builtinEmpty = Native:createText(builtinScroll.content, "Built-in raid compositions will appear here.", "GameFontHighlight", theme.colors.muted)
    builtinEmpty:SetPoint(
        "TOPLEFT",
        builtinScroll.content,
        "TOPLEFT",
        18,
        -22
    )
    builtinEmpty:SetWidth(360)
    builtinEmpty:SetJustifyH("CENTER")
    builtinEmpty:Hide()
    customEmpty = Native:createText(customScroll.content, "No custom templates yet. Configure a raid, name it above, then Save Current.", "GameFontHighlight", theme.colors.muted)
    customEmpty:SetPoint(
        "TOPLEFT",
        customScroll.content,
        "TOPLEFT",
        22,
        -22
    )
    customEmpty:SetWidth(350)
    customEmpty:SetJustifyH("CENTER")
    customEmpty:SetJustifyV("TOP")
    customEmpty:Hide()
    showTemplates = function()
        ChoiceUI:closeChoicePopup()
        builtinScroll:scrollToTop()
        customScroll:scrollToTop()
        refreshTemplates(nil)
        templatesModal:show()
    end
    local peopleModal = ModalUI:createModal(frame, 980, 700)
    peopleModal:setTitle("Humans & Pins")
    peopleModal:setSubtitle("Real players stay locked. Pins request named companions without turning humans into disposable roster slots.")
    peopleModal:setHeaderIcon(ICON_PEOPLE)
    local peopleHumanTitle = Native:createText(peopleModal.content, "HUMAN ANCHORS", "GameFontNormalSmall", theme.colors.muted)
    peopleHumanTitle:SetPoint(
        "TOPLEFT",
        peopleModal.content,
        "TOPLEFT",
        0,
        0
    )
    humanScroll = ScrollUI:createScrollList(peopleModal.content, 900, 210)
    humanScroll.frame:SetPoint(
        "TOPLEFT",
        peopleModal.content,
        "TOPLEFT",
        0,
        -26
    )
    humanRowsModal = {}
    humanEmpty = Native:createText(humanScroll.content, "No additional human anchors detected.", "GameFontHighlight", theme.colors.muted)
    humanEmpty:SetPoint(
        "TOPLEFT",
        humanScroll.content,
        "TOPLEFT",
        18,
        -20
    )
    humanEmpty:SetWidth(820)
    humanEmpty:SetJustifyH("CENTER")
    humanEmpty:Hide()
    local pinBuilder = Native:createPanel(peopleModal.content, theme.colors.surfaceRaised, theme.colors.border)
    pinBuilder.frame:SetPoint(
        "TOPLEFT",
        peopleModal.content,
        "TOPLEFT",
        0,
        -242
    )
    pinBuilder.frame:SetPoint(
        "TOPRIGHT",
        peopleModal.content,
        "TOPRIGHT",
        0,
        -242
    )
    pinBuilder.frame:SetHeight(82)
    local pinTitle = Native:createText(peopleModal.content, "PIN COMPANION", "GameFontNormalSmall", theme.colors.muted)
    pinTitle:SetPoint(
        "TOPLEFT",
        peopleModal.content,
        "TOPLEFT",
        12,
        -250
    )
    local pinInput = InputUI:createTextInput(peopleModal.content, 230, 34)
    pinInput.frame:SetPoint(
        "TOPLEFT",
        peopleModal.content,
        "TOPLEFT",
        12,
        -278
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
            width = 116,
            height = 36,
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
        peopleModal.content,
        "TOPRIGHT",
        -12,
        -278
    )
    local pinListTitle = Native:createText(peopleModal.content, "PINNED MEMBERS", "GameFontNormalSmall", theme.colors.muted)
    pinListTitle:SetPoint(
        "TOPLEFT",
        peopleModal.content,
        "TOPLEFT",
        0,
        -338
    )
    pinScroll = ScrollUI:createScrollList(peopleModal.content, 900, 190)
    pinScroll.frame:SetPoint(
        "TOPLEFT",
        peopleModal.content,
        "TOPLEFT",
        0,
        -364
    )
    pinRows = {}
    pinEmpty = Native:createText(pinScroll.content, "No companions pinned. Add a name above to keep a familiar bot in mind.", "GameFontHighlight", theme.colors.muted)
    pinEmpty:SetPoint(
        "TOPLEFT",
        pinScroll.content,
        "TOPLEFT",
        18,
        -20
    )
    pinEmpty:SetWidth(820)
    pinEmpty:SetJustifyH("CENTER")
    pinEmpty:Hide()
    showPeople = function()
        ChoiceUI:closeChoicePopup()
        refreshPeople(nil)
        peopleModal:show()
    end
    local optionsModal = ModalUI:createModal(frame, 900, 650)
    optionsModal:setHeaderIcon(ICON_OPTIONS)
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
            local column = i % 2
            local rowIndex = math.floor(i / 2)
            local row = Native:createPanel(optionsModal.content, theme.colors.surfaceRaised, theme.colors.border)
            row.frame:SetPoint(
                "TOPLEFT",
                optionsModal.content,
                "TOPLEFT",
                column * 430,
                -(rowIndex * 84)
            )
            row.frame:SetSize(414, 72)
            local optionAccent = Native:createSolid(
                row.frame,
                Native:withAlpha(theme.colors.primary, 0.42),
                "ARTWORK"
            )
            optionAccent:SetPoint(
                "TOPLEFT",
                row.frame,
                "TOPLEFT",
                0,
                0
            )
            optionAccent:SetPoint(
                "TOPRIGHT",
                row.frame,
                "TOPRIGHT",
                0,
                0
            )
            optionAccent:SetHeight(2)
            local toggle = ToggleUI:createToggle(
                row.frame,
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
                row.frame,
                "TOPLEFT",
                12,
                -8
            )
            toggle.frame:SetWidth(360)
            local hint = Native:createText(row.frame, def.hint, "GameFontHighlightSmall", theme.colors.muted)
            hint:SetPoint(
                "TOPLEFT",
                row.frame,
                "TOPLEFT",
                42,
                -37
            )
            hint:SetWidth(350)
            hint:SetJustifyV("TOP")
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
        -348
    )
    gearRow.frame:SetPoint(
        "TOPRIGHT",
        optionsModal.content,
        "TOPRIGHT",
        0,
        -348
    )
    gearRow.frame:SetHeight(72)
    local gearIcon = Native:createFramedIcon(gearRow.frame, "Interface\\Icons\\INV_Chest_Plate04", 40, theme.colors.primary)
    gearIcon.frame:SetPoint(
        "LEFT",
        gearRow.frame,
        "LEFT",
        12,
        0
    )
    local gearTitle = Native:createText(gearRow.frame, "Minimum item level", "GameFontNormal")
    gearTitle:SetPoint(
        "TOPLEFT",
        gearRow.frame,
        "TOPLEFT",
        64,
        -12
    )
    local gearHint = Native:createText(gearRow.frame, "0 disables the floor. Guild/world bots below the configured value are rejected.", "GameFontHighlightSmall", theme.colors.muted)
    gearHint:SetPoint(
        "TOPLEFT",
        gearRow.frame,
        "TOPLEFT",
        64,
        -39
    )
    gearHint:SetWidth(560)
    local ____StepperUI_21 = StepperUI
    local ____StepperUI_createNumberStepper_22 = StepperUI.createNumberStepper
    local ____gearRow_frame_20 = gearRow.frame
    local ____opt_17 = Model:config().options
    if ____opt_17 ~= nil then
        ____opt_17 = ____opt_17.minimumItemLevel
    end
    local ____opt_17_19 = ____opt_17
    if ____opt_17_19 == nil then
        ____opt_17_19 = 0
    end
    local gearStepper = ____StepperUI_createNumberStepper_22(
        ____StepperUI_21,
        ____gearRow_frame_20,
        0,
        300,
        __TS__Number(____opt_17_19),
        function(____, value) return Model:setMinimumItemLevel(value) end
    )
    gearStepper.frame:SetPoint(
        "RIGHT",
        gearRow.frame,
        "RIGHT",
        -14,
        0
    )
    showOptions = function()
        ChoiceUI:closeChoicePopup()
        for ____, toggle in ipairs(optionToggles) do
            toggle:refresh()
        end
        local ____gearStepper_setValue_26 = gearStepper.setValue
        local ____opt_23 = Model:config().options
        if ____opt_23 ~= nil then
            ____opt_23 = ____opt_23.minimumItemLevel
        end
        local ____opt_23_25 = ____opt_23
        if ____opt_23_25 == nil then
            ____opt_23_25 = 0
        end
        ____gearStepper_setValue_26(
            gearStepper,
            __TS__Number(____opt_23_25),
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
            height = 38,
            accent = theme.colors.success,
            emphasis = true,
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
        confirmModal:setHeaderIcon(Model:selectedActivityIcon())
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
        activityBadge.icon:SetTexture(Model:selectedActivityIcon())
        activityBadge.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
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
        local ____opt_27 = Model:config().humanRoles
        if ____opt_27 ~= nil then
            ____opt_27 = ____opt_27[primary.name]
        end
        local selected = ____opt_27
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
                    local __continue173
                    repeat
                        local widgets = dungeonRows[i + 1]
                        local slot = slots[i + 1]
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
                            local ____self_30 = widgets.sub
                            local ____self_30_SetText_31 = ____self_30.SetText
                            local ____slot_human_level_29 = slot.human.level
                            if ____slot_human_level_29 == nil then
                                ____slot_human_level_29 = "?"
                            end
                            ____self_30_SetText_31(
                                ____self_30,
                                (("Level " .. tostring(____slot_human_level_29)) .. " ") .. Model:classLabel(tostring(slot.human.class))
                            )
                            widgets.choose.frame:Hide()
                            widgets.auto.frame:Hide()
                            widgets.humanAnchor.frame:Show()
                            __continue173 = true
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
                            local ____self_35 = widgets.sub
                            local ____self_35_SetText_36 = ____self_35.SetText
                            local ____prepared_level_32 = prepared.level
                            if ____prepared_level_32 == nil then
                                ____prepared_level_32 = "?"
                            end
                            local ____temp_34 = ((("Lv " .. tostring(____prepared_level_32)) .. "  ·  ") .. tostring(prepared.spec or Model:classLabel(tostring(prepared.class)))) .. "  ·  "
                            local ____prepared_source_33 = prepared.source
                            if ____prepared_source_33 == nil then
                                ____prepared_source_33 = "Bot"
                            end
                            ____self_35_SetText_36(
                                ____self_35,
                                ____temp_34 .. tostring(____prepared_source_33)
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
                                local ____buildSelector_open_38 = buildSelector.open
                                local ____temp_37
                                if exact == nil then
                                    ____temp_37 = nil
                                else
                                    ____temp_37 = {role = roleCopy, classId = exact.classId, specId = exact.specId, count = 1}
                                end
                                ____buildSelector_open_38(buildSelector, roleCopy, ____temp_37, false)
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
                        __continue173 = true
                    until true
                    if not __continue173 then
                        break
                    end
                end
                i = i + 1
            end
        end
    end
    local function refreshQuickRaid(self)
        local ____table_size_39 = Model:config().size
        if ____table_size_39 == nil then
            ____table_size_39 = 25
        end
        local size = __TS__Number(____table_size_39)
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
            local sectionHeight = #rows == 0 and 112 or 76 + #rows * 64
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
                        panel.frame:SetSize(870, 56)
                        local classBadge = Native:createFramedIcon(panel.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 38, theme.colors.borderStrong)
                        classBadge.frame:SetPoint(
                            "LEFT",
                            panel.frame,
                            "LEFT",
                            10,
                            0
                        )
                        local classIcon = classBadge.icon
                        local specBadge = Native:createFramedIcon(panel.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 38, theme.colors.borderStrong)
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
                            104,
                            -10
                        )
                        name:SetWidth(500)
                        local count = Native:createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted)
                        count:SetPoint(
                            "TOPLEFT",
                            name,
                            "BOTTOMLEFT",
                            0,
                            -4
                        )
                        local edit = ButtonUI:createButton(panel.frame, {text = "Edit", width = 74, height = 30, accent = theme.colors.primary})
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
                            classBadge = classBadge,
                            classIcon = classIcon,
                            specBadge = specBadge,
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
                        -(66 + i * 64)
                    )
                    Native:setClassIcon(widgets.classIcon, build.classId)
                    widgets.classBadge.outline:setColor(Native:classColor(build.classId))
                    widgets.specBadge.outline:setColor(theme.colors.primary)
                    widgets.specIcon:SetTexture(Model:getSpecIcon(build.classId, build.specId))
                    widgets.specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    widgets.name:SetText((Model:getSpecLabel(build.classId, build.specId) .. " ") .. Model:classLabel(build.classId))
                    widgets.count:SetText("× " .. tostring(build.count))
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
        local cardHeight = 190
        do
            local g = 0
            while g < #groupCards do
                do
                    local __continue204
                    repeat
                        local widgets = groupCards[g + 1]
                        if g >= totalGroups then
                            widgets.card.frame:Hide()
                            __continue204 = true
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
                                    rowWidgets.iconBadge.frame:Hide()
                                    rowWidgets.name:SetText("Empty")
                                    rowWidgets.name:SetTextColor(theme.colors.muted[1], theme.colors.muted[2], theme.colors.muted[3], 1)
                                    rowWidgets.spec:SetText("")
                                    Native:setTextureColor(rowWidgets.roleBar, theme.colors.borderStrong)
                                else
                                    Native:setClassIcon(
                                        rowWidgets.icon,
                                        tostring(member.class)
                                    )
                                    rowWidgets.iconBadge.outline:setColor(Native:classColor(tostring(member.class)))
                                    rowWidgets.iconBadge.frame:Show()
                                    rowWidgets.name:SetText((member.isPlayer and "YOU  ·  " or "") .. tostring(member.name))
                                    rowWidgets.name:SetTextColor(theme.colors.text[1], theme.colors.text[2], theme.colors.text[3], 1)
                                    local ____self_44 = rowWidgets.spec
                                    local ____self_44_SetText_45 = ____self_44.SetText
                                    local ____member_level_41 = member.level
                                    if ____member_level_41 == nil then
                                        ____member_level_41 = "?"
                                    end
                                    local ____temp_43 = ("Lv " .. tostring(____member_level_41)) .. " · "
                                    local ____member_spec_42 = member.spec
                                    if ____member_spec_42 == nil then
                                        ____member_spec_42 = Model:classLabel(tostring(member.class))
                                    end
                                    ____self_44_SetText_45(
                                        ____self_44,
                                        ____temp_43 .. tostring(____member_spec_42)
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
                        __continue204 = true
                    until true
                    if not __continue204 then
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
        phaseText:SetText(Model:isTravelRetry() and "Ready to enter activity" or Model:phaseLabel(phase))
        phaseText:SetTextColor(phaseColor[1], phaseColor[2], phaseColor[3], 1)
        if phase == "IDLE" then
            phaseDetail:SetText(Model:config().mode == "RAID" and "Add specific builds or keep Auto to prepare your raid." or "Choose exact builds or keep Auto to prepare your group.")
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
        elseif phase == "READY" or phase == "DONE" then
            ratio = 1
        elseif phase == "IDLE" and target > 0 then
            ratio = math.min(1, total / target)
        end
        progressFill:SetWidth(math.max(1, 266 * ratio))
        Native:setTextureColor(progressFill, phaseColor)
        local ____progressText_SetText_80 = progressText.SetText
        local ____temp_79
        if phase == "PREPARING" or phase == "ASSEMBLING" or phase == "READY" or phase == "DONE" then
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
        local ____coverageText_SetText_83 = coverageText.SetText
        local ____opt_81 = Model:plan().summary
        if ____opt_81 ~= nil then
            ____opt_81 = ____opt_81.utility
        end
        ____coverageText_SetText_83(
            coverageText,
            ____opt_81 ~= nil and Model:coverageDisplay() or "Build a roster to inspect utility coverage."
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
                        text = Model:isTravelRetry() and "Clear the travel blocker, then enter the activity." or "Prepared roster is ready for review. Assemble when it looks right."
                    elseif phase == "PREPARING" then
                        text = "Composer is provisioning and validating the selected bots."
                    elseif not Model:humanReady() then
                        text = "Choose a legal role for every real player."
                    else
                        local ____temp_86 = Model:config().mode == "RAID"
                        if ____temp_86 then
                            local ____temp_85 = Model:roleTargetTotal()
                            local ____table_size_84 = Model:config().size
                            if ____table_size_84 == nil then
                                ____table_size_84 = 25
                            end
                            ____temp_86 = ____temp_85 ~= __TS__Number(____table_size_84)
                        end
                        if ____temp_86 then
                            local ____table_size_87 = Model:config().size
                            if ____table_size_87 == nil then
                                ____table_size_87 = 25
                            end
                            text = ("Role counts must total " .. tostring(____table_size_87)) .. " before preparing."
                        else
                            text = "Build & Prepare when the composition looks right."
                        end
                    end
                end
                warningRows[i + 1]:SetText(tostring(text or ""))
                i = i + 1
            end
        end
        local ____buildButton_setEnabled_92 = buildButton.setEnabled
        local ____temp_91 = Model:humanReady() and not Model:isBusy()
        if ____temp_91 then
            local ____temp_90 = Model:config().mode ~= "RAID"
            if not ____temp_90 then
                local ____temp_89 = Model:roleTargetTotal()
                local ____table_size_88 = Model:config().size
                if ____table_size_88 == nil then
                    ____table_size_88 = 25
                end
                ____temp_90 = ____temp_89 == __TS__Number(____table_size_88)
            end
            ____temp_91 = ____temp_90
        end
        ____buildButton_setEnabled_92(buildButton, ____temp_91)
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
        if GC.backendSeen == true then
            backendGlow:Show()
        else
            backendGlow:Hide()
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
    version = "0.7.0",
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

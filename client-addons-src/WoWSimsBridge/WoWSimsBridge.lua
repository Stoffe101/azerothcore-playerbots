local ADDON_NAME = ...
WoWSimsBridgeDB = WoWSimsBridgeDB or {}
local DB = WoWSimsBridgeDB

local Bridge = {}
WoWSimsBridge = Bridge

local JSON_NULL = {}
local SLOT_ORDER = {
    INVSLOT_HEAD, INVSLOT_NECK, INVSLOT_SHOULDER, INVSLOT_BACK, INVSLOT_CHEST,
    INVSLOT_WRIST, INVSLOT_HAND, INVSLOT_WAIST, INVSLOT_LEGS, INVSLOT_FEET,
    INVSLOT_FINGER1, INVSLOT_FINGER2, INVSLOT_TRINKET1, INVSLOT_TRINKET2,
    INVSLOT_MAINHAND, INVSLOT_OFFHAND, INVSLOT_RANGED
}

local ERA_URLS = {
    VANILLA = "https://www.wowsims.com/classic/",
    TBC = "https://www.wowsims.com/tbc/",
    WOTLK = "https://www.wowsims.com/wotlk/",
}

local SPEC_NAMES = {
    WARRIOR = { "arms", "fury", "protection" },
    PALADIN = { "holy", "protection", "retribution" },
    HUNTER = { "beast_mastery", "marksman", "survival" },
    ROGUE = { "assassination", "combat", "subtlety" },
    PRIEST = { "discipline", "holy", "shadow" },
    DEATHKNIGHT = { "blood", "frost", "unholy" },
    SHAMAN = { "elemental", "enhancement", "restoration" },
    MAGE = { "arcane", "fire", "frost" },
    WARLOCK = { "affliction", "demonology", "destruction" },
    DRUID = { "balance", "feral", "restoration" },
}

local function Msg(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cff67b7ffWoWSims Bridge:|r " .. tostring(text))
end

local function EscapeJson(text)
    text = tostring(text or "")
    text = text:gsub("\\", "\\\\")
    text = text:gsub('"', '\\"')
    text = text:gsub("\b", "\\b")
    text = text:gsub("\f", "\\f")
    text = text:gsub("\n", "\\n")
    text = text:gsub("\r", "\\r")
    text = text:gsub("\t", "\\t")
    return text
end

local function IsArray(value)
    local max, count = 0, 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
            return false, 0
        end
        if key > max then max = key end
        count = count + 1
    end
    return max == count, max
end

local function EncodeJson(value)
    if value == JSON_NULL then return "null" end
    local kind = type(value)
    if kind == "nil" then return "null" end
    if kind == "boolean" then return value and "true" or "false" end
    if kind == "number" then
        if value ~= value or value == math.huge or value == -math.huge then return "null" end
        return tostring(value)
    end
    if kind == "string" then return '"' .. EscapeJson(value) .. '"' end
    if kind ~= "table" then return '"' .. EscapeJson(tostring(value)) .. '"' end

    local array, max = IsArray(value)
    local out = {}
    if array then
        for i = 1, max do
            out[#out + 1] = EncodeJson(value[i])
        end
        return "[" .. table.concat(out, ",") .. "]"
    end

    local keys = {}
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, key in ipairs(keys) do
        out[#out + 1] = '"' .. EscapeJson(key) .. '":' .. EncodeJson(value[key])
    end
    return "{" .. table.concat(out, ",") .. "}"
end

local function SplitColon(text)
    local out = {}
    for part in string.gmatch((text or "") .. ":", "([^:]*):") do
        out[#out + 1] = part
    end
    return out
end

local function CurrentEra()
    if GroupComposer and GroupComposer.backendSeen and GroupComposer.realm and GroupComposer.realm.era then
        local era = string.upper(tostring(GroupComposer.realm.era))
        if ERA_URLS[era] then return era, "server" end
    end
    local level = UnitLevel("player") or 1
    if level > 70 then return "WOTLK", "level fallback" end
    if level > 60 then return "TBC", "level fallback" end
    return "VANILLA", "level fallback"
end

local function TalentTree()
    local bestTab, bestPoints, bestName = 1, -1, ""
    for tab = 1, 3 do
        local name, _, points = GetTalentTabInfo(tab)
        points = points or 0
        if points > bestPoints then
            bestTab, bestPoints, bestName = tab, points, name or ""
        end
    end
    return bestTab, bestName, bestPoints
end

local function TalentString()
    local tabs = {}
    for tab = 1, GetNumTalentTabs() do
        local values = {}
        for index = 1, GetNumTalents(tab) do
            local _, _, _, _, rank = GetTalentInfo(tab, index)
            values[#values + 1] = tostring(rank or 0)
        end
        tabs[#tabs + 1] = table.concat(values)
    end
    return table.concat(tabs, "-")
end

local function SpecInfo()
    local _, classToken = UnitClass("player")
    local tab, treeName = TalentTree()
    local spec = SPEC_NAMES[classToken] and SPEC_NAMES[classToken][tab] or string.lower(treeName or "unknown")
    if classToken == "DEATHKNIGHT" then
        -- Role-specific tank detection belongs to the simulation preset layer; export the talent tree here.
        spec = spec or "deathknight"
    end
    return classToken, tab, spec, treeName
end

local function ItemSpecFromLink(link, era)
    if not link then return nil end
    local payload = string.match(link, "item:([^|]+)")
    if not payload then return nil end
    local fields = SplitColon(payload)
    local id = tonumber(fields[1])
    if not id or id <= 0 then return nil end

    local item = {
        id = id,
        enchant = tonumber(fields[2]) or 0,
    }

    if era == "TBC" or era == "WOTLK" then
        item.gems = {
            tonumber(fields[3]) or 0,
            tonumber(fields[4]) or 0,
            tonumber(fields[5]) or 0,
            tonumber(fields[6]) or 0,
        }
    end
    if era == "VANILLA" or era == "TBC" then
        item.random_suffix = tonumber(fields[7]) or 0
    end
    return item
end

local function EquippedGear(era)
    local items = {}
    for index, slot in ipairs(SLOT_ORDER) do
        items[index] = ItemSpecFromLink(GetInventoryItemLink("player", slot), era) or JSON_NULL
    end
    return { items = items }
end

local PROFESSION_SPELLS = {
    { 2259, "Alchemy" }, { 2018, "Blacksmithing" }, { 7411, "Enchanting" },
    { 4036, "Engineering" }, { 2366, "Herbalism" }, { 45357, "Inscription" },
    { 25229, "Jewelcrafting" }, { 2108, "Leatherworking" }, { 2575, "Mining" },
    { 8613, "Skinning" }, { 3908, "Tailoring" },
}

local function Professions()
    local localized = {}
    for _, entry in ipairs(PROFESSION_SPELLS) do
        local name = GetSpellInfo(entry[1])
        if name then localized[name] = entry[2] end
    end

    local result = {}
    if not GetNumSkillLines or not GetSkillLineInfo then return result end
    for i = 1, GetNumSkillLines() do
        local name, isHeader, _, rank = GetSkillLineInfo(i)
        if not isHeader and localized[name] then
            result[#result + 1] = { name = localized[name], level = rank or 0 }
        end
    end
    return result
end

local function Glyphs()
    local result = { prime = {}, major = {}, minor = {} }
    if not GetNumGlyphSockets or not GetGlyphSocketInfo then return result end
    for socket = 1, GetNumGlyphSockets() do
        local enabled, glyphType, glyphSpellID = GetGlyphSocketInfo(socket)
        if enabled and glyphSpellID then
            local bucket = glyphType == 1 and result.major or result.minor
            bucket[#bucket + 1] = { spellID = glyphSpellID }
        end
    end
    return result
end

local function BagItems(era)
    local items = {}
    for bag = 0, NUM_BAG_SLOTS do
        local slots = GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local link = GetContainerItemLink(bag, slot)
            local _, _, _, _, _, itemType, _, _, equipLoc = GetItemInfo(link or "")
            if link and equipLoc and equipLoc ~= "" and itemType ~= "Quest" then
                local item = ItemSpecFromLink(link, era)
                if item then items[#items + 1] = item end
            end
        end
    end
    return { items = items }
end

function Bridge.GetEra()
    return CurrentEra()
end

function Bridge.GetSimUrl()
    local era = CurrentEra()
    return ERA_URLS[era], era
end

function Bridge.GetSpec()
    return SpecInfo()
end

function Bridge.BuildCharacterTable()
    local era = CurrentEra()
    local classToken, _, spec = SpecInfo()
    local _, raceEnglish = UnitRace("player")
    if raceEnglish == "Scourge" then raceEnglish = "Undead" end
    local name = UnitName("player") or ""
    local realm = GetRealmName() or ""
    local character = {
        version = "v3.2.4",
        unit = "player",
        id = UnitGUID("player") or "",
        name = name,
        realm = realm,
        race = raceEnglish or "",
        class = string.lower(classToken or ""),
        level = UnitLevel("player") or 1,
        talents = TalentString(),
        professions = Professions(),
        spec = spec or "",
        gear = EquippedGear(era),
        glyphs = era == "WOTLK" and Glyphs() or {},
    }
    return character
end

function Bridge.BuildCharacterExport()
    return EncodeJson(Bridge.BuildCharacterTable())
end

function Bridge.BuildBagExport()
    local era = CurrentEra()
    return EncodeJson(BagItems(era))
end

function Bridge.Describe()
    local era, source = CurrentEra()
    local classToken, _, spec, treeName = SpecInfo()
    return era, source, classToken or "UNKNOWN", spec or "unknown", treeName or ""
end

local frame, outputBox, urlBox, summaryText, statusText

local function SetOutput(text, status)
    if not outputBox then return end
    outputBox:SetText(text or "")
    outputBox:HighlightText()
    outputBox:SetFocus()
    if statusText then statusText:SetText(status or "Ready to copy with Ctrl+C") end
end

local function RefreshSummary()
    if not frame then return end
    local url, era = Bridge.GetSimUrl()
    local _, source, classToken, spec, treeName = Bridge.Describe()
    summaryText:SetText(
        "|cffffffff" .. era .. "|r  |cff9ecbff" .. classToken .. " / " .. spec .. "|r" ..
        "\nDetected talent tree: " .. treeName .. "  |cff888888(" .. source .. ")|r"
    )
    urlBox:SetText(url)
end

local function CreateUI()
    if frame then return end
    frame = CreateFrame("Frame", "WoWSimsBridge335Frame", UIParent)
    frame:SetWidth(500)
    frame:SetHeight(390)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.03, 0.04, 0.06, 0.98)
    frame:SetBackdropBorderColor(0.35, 0.45, 0.60, 1)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:Hide()

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 18, -16)
    title:SetText("WoWSims Bridge")

    summaryText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    summaryText:SetPoint("TOPLEFT", 20, -46)
    summaryText:SetWidth(455)
    summaryText:SetJustifyH("LEFT")

    local urlLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    urlLabel:SetPoint("TOPLEFT", 20, -92)
    urlLabel:SetText("Correct simulator for current realm era")

    urlBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    urlBox:SetPoint("TOPLEFT", 20, -108)
    urlBox:SetWidth(455)
    urlBox:SetHeight(20)
    urlBox:SetAutoFocus(false)

    local charButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    charButton:SetPoint("TOPLEFT", 20, -140)
    charButton:SetWidth(145)
    charButton:SetHeight(22)
    charButton:SetText("Export Character")
    charButton:SetScript("OnClick", function()
        SetOutput(Bridge.BuildCharacterExport(), "Character export ready. Paste into WoWSims > Import > Addon.")
    end)

    local bagsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    bagsButton:SetPoint("LEFT", charButton, "RIGHT", 8, 0)
    bagsButton:SetWidth(145)
    bagsButton:SetHeight(22)
    bagsButton:SetText("Export Bag Items")
    bagsButton:SetScript("OnClick", function()
        SetOutput(Bridge.BuildBagExport(), "Bag export ready for WoWSims batch/top-gear import.")
    end)

    local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refreshButton:SetPoint("LEFT", bagsButton, "RIGHT", 8, 0)
    refreshButton:SetWidth(145)
    refreshButton:SetHeight(22)
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", RefreshSummary)

    local outputLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    outputLabel:SetPoint("TOPLEFT", 20, -176)
    outputLabel:SetText("WoWSims import data")

    local scroll = CreateFrame("ScrollFrame", "WoWSimsBridge335Scroll", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 20, -194)
    scroll:SetPoint("BOTTOMRIGHT", -38, 42)

    outputBox = CreateFrame("EditBox", "WoWSimsBridge335Output", scroll)
    outputBox:SetMultiLine(true)
    outputBox:SetAutoFocus(false)
    outputBox:SetFontObject(ChatFontNormal)
    outputBox:SetWidth(425)
    outputBox:SetTextInsets(4, 4, 4, 4)
    outputBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    outputBox:SetScript("OnTextChanged", function(self)
        local height = math.max(140, self:GetNumLetters() / 2.2)
        self:SetHeight(height)
        scroll:UpdateScrollChildRect()
    end)
    scroll:SetScrollChild(outputBox)

    statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    statusText:SetPoint("BOTTOMLEFT", 20, 17)
    statusText:SetPoint("BOTTOMRIGHT", -20, 17)
    statusText:SetJustifyH("LEFT")
    statusText:SetText("WoWSims is the simulation authority; static scores do not decide upgrades.")
end

function Bridge.Open(mode)
    CreateUI()
    RefreshSummary()
    frame:Show()
    if mode == "bags" then
        SetOutput(Bridge.BuildBagExport(), "Bag export ready for WoWSims batch/top-gear import.")
    elseif mode == "character" or mode == "export" then
        SetOutput(Bridge.BuildCharacterExport(), "Character export ready. Paste into WoWSims > Import > Addon.")
    end
end

function Bridge.Toggle()
    CreateUI()
    if frame:IsShown() then frame:Hide() else Bridge.Open() end
end

SLASH_WOWSIMSBRIDGE1 = "/wsim"
SLASH_WOWSIMSBRIDGE2 = "/wowsims"
SlashCmdList.WOWSIMSBRIDGE = function(msg)
    msg = string.lower((msg or ""):gsub("^%s+", ""):gsub("%s+$", ""))
    if msg == "export" or msg == "character" then
        Bridge.Open("character")
    elseif msg == "bags" then
        Bridge.Open("bags")
    else
        Bridge.Toggle()
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
    DB.version = 1
    local era = CurrentEra()
    Msg("ready for " .. era .. ". /wsim opens the exporter.")
end)

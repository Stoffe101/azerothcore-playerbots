local addonName = ...

AzerothAdminPanelDB = AzerothAdminPanelDB or {}
local DB = AzerothAdminPanelDB
DB.point = DB.point or { "CENTER", "UIParent", "CENTER", 0, 0 }

local function Send(command)
    if not command or command == "" then return end
    SendChatMessage(".ap " .. command, "SAY")
end

local function MakeButton(parent, text, width, height, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetWidth(width or 90)
    b:SetHeight(height or 22)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

local function MakeEdit(parent, width, value)
    local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    e:SetWidth(width or 80)
    e:SetHeight(20)
    e:SetAutoFocus(false)
    e:SetText(value or "")
    e:SetJustifyH("CENTER")
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    return e
end

local frame = CreateFrame("Frame", "AzerothAdminPanelFrame", UIParent)
frame:SetWidth(470)
frame:SetHeight(575)
frame:SetFrameStrata("DIALOG")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetClampedToScreen(true)
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
frame:SetPoint(unpack(DB.point))
frame:Hide()

frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, rel, rp, x, y = self:GetPoint(1)
    DB.point = { p, rel and rel:GetName() or "UIParent", rp, x, y }
end)

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -18)
title:SetText("Azeroth Admin Panel")

local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
subtitle:SetPoint("TOP", title, "BOTTOM", 0, -5)
subtitle:SetText("GM-only controls • changes save automatically")

local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -7, -7)

local status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
status:SetPoint("TOPLEFT", 24, -58)
status:SetPoint("TOPRIGHT", -24, -58)
status:SetJustifyH("LEFT")
status:SetText("Press Refresh to read the live server settings.")

local refresh = MakeButton(frame, "Refresh", 74, 22, function() Send("status") end)
refresh:SetPoint("TOPRIGHT", -25, -82)

local function Header(text, y)
    local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", 24, y)
    fs:SetText(text)
    return fs
end

local function RateRow(label, y, command)
    local l = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    l:SetPoint("TOPLEFT", 34, y)
    l:SetWidth(78)
    l:SetJustifyH("LEFT")
    l:SetText(label)

    local edit = MakeEdit(frame, 58, "1")
    edit:SetPoint("LEFT", l, "RIGHT", 5, 0)

    local apply = MakeButton(frame, "Apply", 58, 22, function()
        local value = edit:GetText()
        Send(command .. " " .. value)
    end)
    apply:SetPoint("LEFT", edit, "RIGHT", 8, 0)

    local last
    for _, mult in ipairs({1, 2, 3, 5, 10}) do
        local b = MakeButton(frame, tostring(mult) .. "x", 42, 22, function()
            edit:SetText(tostring(mult))
            Send(command .. " " .. mult)
        end)
        if not last then
            b:SetPoint("LEFT", apply, "RIGHT", 8, 0)
        else
            b:SetPoint("LEFT", last, "RIGHT", 3, 0)
        end
        last = b
    end
    return edit
end

Header("Server multipliers", -92)
local xpEdit = RateRow("XP", -122, "xp")
local repEdit = RateRow("Reputation", -151, "rep")
local goldEdit = RateRow("Gold", -180, "gold")
local resetRates = MakeButton(frame, "Reset all to 1x", 126, 22, function() Send("reset") end)
resetRates:SetPoint("TOPLEFT", 34, -207)

Header("New-character start", -242)
local tbc = MakeButton(frame, "TBC Adventure (60)", 165, 24, function()
    Send("starter tbc")
end)
tbc:SetPoint("TOPLEFT", 34, -270)

local raid = MakeButton(frame, "WotLK Raid Ready (80)", 185, 24, function()
    Send("starter raidready")
end)
raid:SetPoint("LEFT", tbc, "RIGHT", 10, 0)

local boost = MakeButton(frame, "Make THIS character raid ready", 260, 25, function()
    Send("raidready")
end)
boost:SetPoint("TOPLEFT", 34, -301)

local note = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
note:SetPoint("LEFT", boost, "RIGHT", 9, 0)
note:SetWidth(130)
note:SetJustifyH("LEFT")
note:SetText("Lv80 • stage 13 • Dalaran • raid starter gear")

Header("Teleport", -340)
local teleports = {
    {"Dark Portal", "darkportal"}, {"Shattrath", "shattrath"}, {"Dalaran", "dalaran"},
    {"Stormwind", "stormwind"}, {"Ironforge", "ironforge"}, {"Orgrimmar", "orgrimmar"},
    {"Thunder Bluff", "thunderbluff"}, {"Argent Tourney", "argent"},
}
for i, data in ipairs(teleports) do
    local col = (i - 1) % 4
    local row = math.floor((i - 1) / 4)
    local b = MakeButton(frame, data[1], 99, 23, function() Send("tp " .. data[2]) end)
    b:SetPoint("TOPLEFT", 28 + col * 108, -367 - row * 28)
end

local playerLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
playerLabel:SetPoint("TOPLEFT", 32, -430)
playerLabel:SetText("Online player:")
local playerEdit = MakeEdit(frame, 126, "")
playerEdit:SetPoint("LEFT", playerLabel, "RIGHT", 8, 0)
local gotoBtn = MakeButton(frame, "Go to", 65, 22, function()
    if playerEdit:GetText() ~= "" then Send("goto " .. playerEdit:GetText()) end
end)
gotoBtn:SetPoint("LEFT", playerEdit, "RIGHT", 8, 0)
local summonBtn = MakeButton(frame, "Summon", 70, 22, function()
    if playerEdit:GetText() ~= "" then Send("summon " .. playerEdit:GetText()) end
end)
summonBtn:SetPoint("LEFT", gotoBtn, "RIGHT", 5, 0)

Header("Saved teleport spots", -462)
local savedEdit = MakeEdit(frame, 125, "home")
savedEdit:SetPoint("TOPLEFT", 34, -488)
local saveBtn = MakeButton(frame, "Save here", 82, 22, function()
    if savedEdit:GetText() ~= "" then Send("save " .. savedEdit:GetText()) end
end)
saveBtn:SetPoint("LEFT", savedEdit, "RIGHT", 8, 0)
local goSaved = MakeButton(frame, "Go saved", 82, 22, function()
    if savedEdit:GetText() ~= "" then Send("gosaved " .. savedEdit:GetText()) end
end)
goSaved:SetPoint("LEFT", saveBtn, "RIGHT", 5, 0)
local listSaved = MakeButton(frame, "List", 58, 22, function() Send("saved") end)
listSaved:SetPoint("LEFT", goSaved, "RIGHT", 5, 0)

local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
hint:SetPoint("BOTTOMLEFT", 24, 18)
hint:SetPoint("BOTTOMRIGHT", -24, 18)
hint:SetJustifyH("LEFT")
hint:SetText("Tip: /ap toggles this panel. Server commands also work as .ap <command>.")

local event = CreateFrame("Frame")
event:RegisterEvent("CHAT_MSG_SYSTEM")
event:RegisterEvent("PLAYER_LOGIN")
event:SetScript("OnEvent", function(self, evt, msg)
    if evt == "PLAYER_LOGIN" then
        if IsGMClient and not IsGMClient() then
            return
        end
        return
    end

    if type(msg) ~= "string" or not string.find(msg, "%[AdminPanel%]") then return end
    status:SetText(msg)

    local xp, rep, gold, starter = string.match(msg, "STATUS xp=([%d%.]+) rep=([%d%.]+) gold=([%d%.]+) starter=(%S+)")
    if xp then
        xpEdit:SetText(xp)
        repEdit:SetText(rep)
        goldEdit:SetText(gold)
    end
end)

local mini = CreateFrame("Button", "AzerothAdminPanelMinimapButton", Minimap)
mini:SetWidth(30)
mini:SetHeight(30)
mini:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -4, -4)
mini:SetFrameStrata("MEDIUM")
mini:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
mini:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
local miniText = mini:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
miniText:SetPoint("CENTER", 0, 1)
miniText:SetText("AP")
mini:SetScript("OnClick", function()
    if frame:IsShown() then frame:Hide() else frame:Show(); Send("status") end
end)
mini:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Azeroth Admin Panel")
    GameTooltip:AddLine("GM server controls", 1, 1, 1)
    GameTooltip:Show()
end)
mini:SetScript("OnLeave", function() GameTooltip:Hide() end)

SLASH_AZEROTHADMIN1 = "/ap"
SLASH_AZEROTHADMIN2 = "/adminpanel"
SlashCmdList["AZEROTHADMIN"] = function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        Send("status")
    end
end

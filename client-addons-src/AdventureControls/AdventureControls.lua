-- AdventureControls: lightweight WotLK 3.3.5a switchboard for the server-side
-- .playstyle command family. The addon contains no progression logic itself.

local function Run(cmd)
    local eb = DEFAULT_CHAT_FRAME.editBox
    eb:SetText(cmd)
    ChatEdit_SendText(eb, 0)
end

local menuFrame = CreateFrame("Frame", "AdventureControlsMenuFrame", UIParent, "UIDropDownMenuTemplate")

local function RateMenu(kind)
    local values = {
        { 0,   "0x / Off" },
        { 100, "1.0x" },
        { 150, "1.5x" },
        { 200, "2.0x" },
        { 300, "3.0x" },
        { 500, "5.0x" },
        { 1000,"10.0x" },
    }
    local out = {}
    for _, entry in ipairs(values) do
        local pct, label = entry[1], entry[2]
        out[#out + 1] = {
            text = label,
            notCheckable = true,
            func = function() Run(".playstyle " .. kind .. " " .. pct) end,
        }
    end
    return out
end

local PROGRESSION = {
    { 8,  "TBC start: Karazhan / Gruul / Magtheridon" },
    { 9,  "Unlock SSC / Tempest Keep tier" },
    { 10, "Unlock Hyjal / Black Temple tier" },
    { 12, "Unlock Sunwell tier" },
    { 13, "Wrath start: Naxx / EoE / Obsidian Sanctum" },
    { 14, "Unlock Ulduar tier" },
    { 15, "Unlock Trial of the Crusader tier" },
    { 16, "Unlock Icecrown Citadel tier" },
    { 17, "Unlock Ruby Sanctum tier" },
    { 18, "Final WotLK progression stage" },
}

StaticPopupDialogs["ADVENTURE_CONTROLS_FINISH_ALL"] = {
    text = "Complete the objectives for every active quest?\n\nThe quests are NOT auto-turned-in, so rewards and follow-up chains still happen normally.",
    button1 = "Complete objectives",
    button2 = "Cancel",
    OnAccept = function() Run(".playstyle quest finishall") end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ADVENTURE_CONTROLS_PROGRESS"] = {
    text = "Advance your Individual Progression to stage %s?\n\nThis unlocks content through the server's normal progression system. It does not complete every ordinary quest.",
    button1 = "Advance",
    button2 = "Cancel",
    OnAccept = function(self, data)
        if data then Run(".playstyle progress advance " .. data) end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local progressionMenu = {}
for _, entry in ipairs(PROGRESSION) do
    local stage, label = entry[1], entry[2]
    progressionMenu[#progressionMenu + 1] = {
        text = label,
        notCheckable = true,
        func = function()
            StaticPopup_Show("ADVENTURE_CONTROLS_PROGRESS", tostring(stage), nil, stage)
        end,
    }
end
progressionMenu[#progressionMenu + 1] = {
    text = "Show all progression stages in chat",
    notCheckable = true,
    func = function() Run(".playstyle progress list") end,
}

local menu = {
    { text = "Adventure Controls", isTitle = true, notCheckable = true },
    { text = "Show current settings", notCheckable = true, func = function() Run(".playstyle status") end },
    { text = "Rate presets", notCheckable = true, hasArrow = true, menuList = {
        { text = "Normal (1x / 1x / 1x)", notCheckable = true, func = function() Run(".playstyle preset normal") end },
        { text = "Boosted (1.5x / 1.5x / 1.5x)", notCheckable = true, func = function() Run(".playstyle preset boosted") end },
        { text = "Fast (2x / 2x / 2x)", notCheckable = true, func = function() Run(".playstyle preset fast") end },
        { text = "Turbo (3x XP / 2.5x gold / 3x rep)", notCheckable = true, func = function() Run(".playstyle preset turbo") end },
        { text = "Insane (5x / 5x / 5x)", notCheckable = true, func = function() Run(".playstyle preset insane") end },
    } },
    { text = "XP multiplier", notCheckable = true, hasArrow = true, menuList = RateMenu("xp") },
    { text = "Gold multiplier", notCheckable = true, hasArrow = true, menuList = RateMenu("gold") },
    { text = "Reputation multiplier", notCheckable = true, hasArrow = true, menuList = RateMenu("rep") },
    { text = "Quest helpers", notCheckable = true, hasArrow = true, menuList = {
        { text = "Finish ALL active quest objectives...", notCheckable = true, func = function() StaticPopup_Show("ADVENTURE_CONTROLS_FINISH_ALL") end },
        { text = "Finish one quest: use .playstyle quest finish <id>", notCheckable = true, disabled = true },
    } },
    { text = "Advance story / progression", notCheckable = true, hasArrow = true, menuList = progressionMenu },
}

local RADIUS = 80
local btn = CreateFrame("Button", "AdventureControlsMinimapButton", Minimap)
btn:SetWidth(31); btn:SetHeight(31)
btn:SetFrameStrata("MEDIUM")
btn:SetFrameLevel(8)
btn:RegisterForClicks("LeftButtonUp")
btn:RegisterForDrag("LeftButton")

local icon = btn:CreateTexture(nil, "BACKGROUND")
icon:SetWidth(20); icon:SetHeight(20)
icon:SetPoint("CENTER", 0, 0)
icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")

local border = btn:CreateTexture(nil, "OVERLAY")
border:SetWidth(53); border:SetHeight(53)
border:SetPoint("TOPLEFT")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local function UpdatePos()
    local angle = math.rad(AdventureControlsDB.pos or 245)
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", RADIUS * math.cos(angle), RADIUS * math.sin(angle))
end

btn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local scale = Minimap:GetEffectiveScale()
        local px, py = GetCursorPosition()
        px, py = px / scale, py / scale
        AdventureControlsDB.pos = math.deg(math.atan2(py - my, px - mx))
        UpdatePos()
    end)
end)
btn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

btn:SetScript("OnClick", function()
    EasyMenu(menu, menuFrame, "cursor", 0, 0, "MENU")
end)

btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Adventure Controls")
    GameTooltip:AddLine("XP, gold, rep, quest and progression switches.", 1, 1, 1)
    GameTooltip:AddLine("Rates are personal multipliers on top of realm rates.", 0.75, 0.75, 0.75)
    GameTooltip:Show()
end)
btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

SLASH_ADVENTURECONTROLS1 = "/adventurecontrols"
SLASH_ADVENTURECONTROLS2 = "/acontrol"
SlashCmdList["ADVENTURECONTROLS"] = function()
    EasyMenu(menu, menuFrame, "cursor", 0, 0, "MENU")
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
    if name ~= "AdventureControls" then return end
    AdventureControlsDB = AdventureControlsDB or {}
    UpdatePos()
    self:UnregisterEvent("ADDON_LOADED")
end)

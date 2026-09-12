-- AdventureControls: lightweight WotLK 3.3.5a switchboard for the server-side
-- .playstyle / .catchup command families. The addon contains no progression logic itself.

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

local RAID_SHORTCUTS = {
    { "kara",    "Karazhan / Gruul / Magtheridon" },
    { "ssc",     "Serpentshrine Cavern / Tempest Keep" },
    { "hyjal",   "Hyjal Summit / Black Temple" },
    { "za",      "Zul'Aman" },
    { "sunwell", "Sunwell Plateau" },
    { "naxx",    "Naxxramas / EoE / Obsidian Sanctum" },
    { "ulduar",  "Ulduar" },
    { "toc",     "Trial of the Crusader" },
    { "icc",     "Icecrown Citadel" },
    { "rs",      "Ruby Sanctum" },
}

local PROGRESSION = {
    { 8,  "TBC start" },
    { 9,  "TBC stage 9" },
    { 10, "TBC stage 10" },
    { 12, "TBC final tier" },
    { 13, "Wrath start" },
    { 14, "Wrath stage 14" },
    { 15, "Wrath stage 15" },
    { 16, "Wrath stage 16" },
    { 17, "Wrath stage 17" },
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

StaticPopupDialogs["ADVENTURE_CONTROLS_RAID"] = {
    text = "Skip forward and unlock %s?\n\nThis advances the server's raid/content progression only. It does not fake-complete every normal quest.",
    button1 = "Unlock raid tier",
    button2 = "Cancel",
    OnAccept = function(self, data)
        if data then Run(".playstyle raid unlock " .. data) end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ADVENTURE_CONTROLS_CATCHUP"] = {
    text = "Unlock %s and apply its one-time catch-up gear package?\n\nThe server uses your CURRENT spec and upgrades your EQUIPPED gear toward an entry-ready target below the raid's own loot. Better pieces are kept, but weaker equipped pieces may be replaced. Enchants and gems are not granted.",
    button1 = "Unlock + gear",
    button2 = "Cancel",
    OnAccept = function(self, data)
        if data then Run(".catchup raid " .. data) end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ADVENTURE_CONTROLS_NEXT_RAID"] = {
    text = "Skip forward to the next main raid tier?\n\nThis is forward-only and uses the server's normal Individual Progression system.",
    button1 = "Skip to next tier",
    button2 = "Cancel",
    OnAccept = function() Run(".playstyle raid next") end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ADVENTURE_CONTROLS_NEXT_CATCHUP"] = {
    text = "Skip to the next main raid tier AND apply its one-time catch-up gear package?\n\nYou must already be the expansion's raid level (70 in TBC, 80 in Wrath). The pass uses your current spec and may replace weaker equipped pieces.",
    button1 = "Skip + gear",
    button2 = "Cancel",
    OnAccept = function() Run(".catchup next") end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local raidMenu = {
    {
        text = "Skip to NEXT raid tier",
        notCheckable = true,
        hasArrow = true,
        menuList = {
            { text = "Unlock only...", notCheckable = true, func = function() StaticPopup_Show("ADVENTURE_CONTROLS_NEXT_RAID") end },
            { text = "Unlock + catch-up gear...", notCheckable = true, func = function() StaticPopup_Show("ADVENTURE_CONTROLS_NEXT_CATCHUP") end },
        },
    },
}

local function RaidActions(alias, label)
    return {
        {
            text = "Unlock only...",
            notCheckable = true,
            func = function() StaticPopup_Show("ADVENTURE_CONTROLS_RAID", label, nil, alias) end,
        },
        {
            text = "Unlock + catch-up gear...",
            notCheckable = true,
            func = function() StaticPopup_Show("ADVENTURE_CONTROLS_CATCHUP", label, nil, alias) end,
        },
    }
end

for _, entry in ipairs(RAID_SHORTCUTS) do
    local alias, label = entry[1], entry[2]
    raidMenu[#raidMenu + 1] = {
        text = label,
        notCheckable = true,
        hasArrow = true,
        menuList = RaidActions(alias, label),
    }
end

raidMenu[#raidMenu + 1] = {
    text = "Show raid unlock status in chat",
    notCheckable = true,
    func = function() Run(".playstyle raid list") end,
}
raidMenu[#raidMenu + 1] = {
    text = "Show catch-up claims in chat",
    notCheckable = true,
    func = function() Run(".catchup status") end,
}

local progressionMenu = {}
for _, entry in ipairs(PROGRESSION) do
    local stage, label = entry[1], entry[2]
    progressionMenu[#progressionMenu + 1] = {
        text = label .. " (stage " .. stage .. ")",
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
    { text = "Raid progression / skip forward", notCheckable = true, hasArrow = true, menuList = raidMenu },
    { text = "Advanced progression stages", notCheckable = true, hasArrow = true, menuList = progressionMenu },
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
    GameTooltip:AddLine("XP, gold, rep, quests, raid skips and catch-up gear.", 1, 1, 1)
    GameTooltip:AddLine("Catch-up gear is spec-aware and one-time per raid tier.", 0.75, 0.75, 0.75)
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

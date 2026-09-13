-- Azeroth Control: profession helper loaded after AdminPanel.lua.
-- The server owns profession discovery/caps so this works regardless of client locale and emits
-- one authoritative command instead of fourteen locale-dependent .setskill guesses.

local frame = AzerothAdminPanelFrame
if not frame then return end

local function Run(command)
    if not command or command == "" then return end
    local eb = DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox
    if not eb then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff29b8f0[Azeroth Control]|r Chat command box is not ready yet.")
        end
        return
    end
    eb:SetText(command)
    ChatEdit_SendText(eb, 0)
end

local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
button:SetWidth(124)
button:SetHeight(25)
button:SetText("Max Professions")
button:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -138, -24)
button:SetScript("OnClick", function() Run(".ap maxprofessions") end)
button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("Max learned professions", 1, 1, 1)
    GameTooltip:AddLine("Sets professions and secondary skills you already know to 450/450. Does not learn new professions or recipes.", 0.78, 0.82, 0.90, true)
    GameTooltip:Show()
end)
button:SetScript("OnLeave", function() GameTooltip:Hide() end)

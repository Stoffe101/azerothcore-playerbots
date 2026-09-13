-- Azeroth Control: lightweight profession helper loaded after AdminPanel.lua.
-- Kept separate so the core panel can stay stable while this convenience control evolves.

local frame = AzerothAdminPanelFrame
if not frame then return end

-- SkillLine IDs from WoW 3.3.5a. We only act on lines the character ALREADY knows, so this
-- never grants extra primary-profession slots or silently teaches a profession they did not pick.
local professionSkillIds = {
    ["Alchemy"] = 171,
    ["Blacksmithing"] = 164,
    ["Enchanting"] = 333,
    ["Engineering"] = 202,
    ["Herbalism"] = 182,
    ["Jewelcrafting"] = 755,
    ["Leatherworking"] = 165,
    ["Mining"] = 186,
    ["Skinning"] = 393,
    ["Tailoring"] = 197,
    ["Inscription"] = 773,
    ["Cooking"] = 185,
    ["First Aid"] = 129,
    ["Fishing"] = 356,
}

local function MaxKnownProfessions()
    local found = 0
    for i = 1, GetNumSkillLines() do
        local name, isHeader = GetSkillLineInfo(i)
        local skillId = name and professionSkillIds[name]
        if skillId and not isHeader then
            -- AzerothCore's .setskill keeps the existing skill line and only changes its value/max.
            -- This makes the learned profession 450/450 without learning every recipe.
            SendChatMessage(".setskill " .. skillId .. " 450 450", "SAY")
            found = found + 1
        end
    end

    if DEFAULT_CHAT_FRAME then
        if found > 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cff29b8f0[Azeroth Control]|r Maxed " .. found .. " learned profession/secondary skill line(s) to 450/450.")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff29b8f0[Azeroth Control]|r No learned profession skill lines were found.")
        end
    end
end

local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
button:SetWidth(124)
button:SetHeight(25)
button:SetText("Max Professions")
button:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -138, -24)
button:SetScript("OnClick", MaxKnownProfessions)
button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("Max learned professions", 1, 1, 1)
    GameTooltip:AddLine("Sets professions and secondary skills you already know to 450/450. Does not learn new professions or every recipe.", 0.78, 0.82, 0.90, true)
    GameTooltip:Show()
end)
button:SetScript("OnLeave", function() GameTooltip:Hide() end)

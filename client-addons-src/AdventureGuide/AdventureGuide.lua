-- AdventureGuide for WoW 3.3.5a.
-- The server remains authoritative. This addon presents .guide data and invokes existing
-- server/group-director actions without owning progression, unlock or combat decisions.

local AG = {}
local ROWS_PER_PAGE = 13
local TRAVEL_ROWS_PER_PAGE = 18

local finderRows = {}
local compatRows = {}
local roadmap = { level = "?", progression = "?", itemlevel = "?", now = "", next = "" }
local mode = "finder"
local page = 1
local travelPage = 1
local selected = nil
local activeStream = nil

local OUTLAND = {
    ramparts=true, bloodfurnace=true, shatteredhalls=true, slavepens=true, underbog=true,
    steamvault=true, manatombs=true, auchenai=true, sethekk=true, shadowlab=true,
    oldhillsbrad=true, blackmorass=true, mechanar=true, botanica=true, arcatraz=true,
    magisters=true, karazhan=true, gruul=true, magtheridon=true, ssc=true,
    tempestkeep=true, hyjal=true, blacktemple=true, zulaman=true, sunwell=true,
}

local NORTHREND = {
    utgardekeep=true, nexus=true, azjol=true, ahnkahet=true, draktharon=true,
    violethold=true, gundrak=true, hallsofstone=true, hallsoflightning=true,
    oculus=true, utgardepinnacle=true, culling=true, trial=true, forgeofsouls=true,
    pitofsaron=true, hallsofreflection=true, naxxramas=true, obsidiansanctum=true,
    eyeofeternity=true, onyxia=true, vault=true, ulduar=true, toc=true, icc=true,
    rubysanctum=true,
}

local function Run(cmd)
    if not cmd or cmd == "" then return end
    local eb = DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox
    if not eb then
        DEFAULT_CHAT_FRAME:AddMessage("Adventure Guide: chat edit box is not ready yet. Try again in a moment.")
        return
    end
    eb:SetText(cmd)
    ChatEdit_SendText(eb, 0)
end

local function Split(text)
    local out = {}
    for part in string.gmatch((text or "") .. "|", "(.-)|") do
        out[#out + 1] = part
    end
    return out
end

local function StatusColor(status)
    if status == "Guild Ready" then return 0.20, 0.95, 0.35 end
    if status == "Playable / experimental" then return 1.00, 0.78, 0.15 end
    return 1.00, 0.25, 0.25
end

local function ReadinessColor(readiness)
    if readiness == "RECOMMENDED" then return 0.20, 1.00, 0.45 end
    if readiness == "READY" then return 1.00, 0.82, 0.25 end
    if readiness == "GEAR LOW" then return 1.00, 0.35, 0.20 end
    return 0.62, 0.62, 0.62
end

local function ReadinessLabel(readiness)
    if readiness == "RECOMMENDED" then return "Recommended" end
    if readiness == "READY" then return "Ready" end
    if readiness == "GEAR LOW" then return "Gear low" end
    return "Locked"
end

local function MakeButton(parent, text, width, height)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetWidth(width)
    b:SetHeight(height)
    b:SetText(text)
    return b
end

local frame = CreateFrame("Frame", "AdventureGuideFrame", UIParent)
frame:SetWidth(790)
frame:SetHeight(560)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetBackdrop({
    bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
    tile=true, tileSize=32, edgeSize=32,
    insets={left=11,right=12,top=12,bottom=11},
})
frame:Hide()

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 24, -19)
title:SetText("Adventure Guide")

local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
subtitle:SetText("Recommendations use level, progression and advisory gear bands. Encounter support stays server-validated.")

local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -6, -6)

local tabs = {}
local content = CreateFrame("Frame", nil, frame)
content:SetPoint("TOPLEFT", 20, -76)
content:SetPoint("BOTTOMRIGHT", -20, 56)

local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
header:SetPoint("TOPLEFT", 4, -3)
header:SetText("Loading...")

local rows = {}
for i = 1, ROWS_PER_PAGE do
    local row = CreateFrame("Button", nil, content)
    row:SetWidth(720)
    row:SetHeight(27)
    row:SetPoint("TOPLEFT", 4, -25 - (i - 1) * 29)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.name:SetPoint("LEFT", 7, 0)
    row.name:SetWidth(285)
    row.name:SetJustifyH("LEFT")

    row.kind = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.kind:SetPoint("LEFT", 300, 0)
    row.kind:SetWidth(75)
    row.kind:SetJustifyH("LEFT")

    row.group = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.group:SetPoint("LEFT", 385, 0)
    row.group:SetWidth(75)
    row.group:SetJustifyH("LEFT")

    row.state = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.state:SetPoint("LEFT", 465, 0)
    row.state:SetWidth(130)
    row.state:SetJustifyH("LEFT")

    row.support = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.support:SetPoint("LEFT", 600, 0)
    row.support:SetWidth(115)
    row.support:SetJustifyH("LEFT")

    row:SetScript("OnClick", function(self)
        selected = self.data
        AG.UpdateDetails()
    end)
    rows[i] = row
end

local prev = MakeButton(content, "<", 32, 22)
prev:SetPoint("BOTTOMLEFT", 5, 5)
prev:SetScript("OnClick", function()
    if page > 1 then
        page = page - 1
        AG.Refresh()
    end
end)

local nextBtn = MakeButton(content, ">", 32, 22)
nextBtn:SetPoint("LEFT", prev, "RIGHT", 5, 0)
nextBtn:SetScript("OnClick", function()
    local data = mode == "compat" and compatRows or finderRows
    local maxPage = math.max(1, math.ceil(#data / ROWS_PER_PAGE))
    if page < maxPage then
        page = page + 1
        AG.Refresh()
    end
end)

local pageText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
pageText:SetPoint("LEFT", nextBtn, "RIGHT", 8, 0)

local detail = CreateFrame("Frame", nil, content)
detail:SetWidth(720)
detail:SetHeight(64)
detail:SetPoint("BOTTOMLEFT", 4, 34)
detail:SetBackdrop({
    bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
    tile=true, tileSize=16, edgeSize=12,
    insets={left=3,right=3,top=3,bottom=3},
})
detail:SetBackdropColor(0.05, 0.05, 0.05, 0.85)

local detailText = detail:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
detailText:SetPoint("TOPLEFT", 8, -7)
detailText:SetWidth(500)
detailText:SetJustifyH("LEFT")
detailText:SetJustifyV("TOP")

local formBtn = MakeButton(detail, "Form Group", 100, 24)
formBtn:SetPoint("TOPRIGHT", -112, -8)
local travelBtn = MakeButton(detail, "Travel", 100, 24)
travelBtn:SetPoint("TOPRIGHT", -7, -8)
local refreshBtn = MakeButton(detail, "Refresh", 100, 24)
refreshBtn:SetPoint("TOPRIGHT", -7, -34)

local roadmapFrame = CreateFrame("Frame", nil, content)
roadmapFrame:SetAllPoints(content)
roadmapFrame:Hide()

local roadmapTitle = roadmapFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
roadmapTitle:SetPoint("TOPLEFT", 12, -30)
roadmapTitle:SetText("Your Progression Roadmap")

local roadmapMeta = roadmapFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
roadmapMeta:SetPoint("TOPLEFT", roadmapTitle, "BOTTOMLEFT", 0, -18)

local nowTitle = roadmapFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
nowTitle:SetPoint("TOPLEFT", roadmapMeta, "BOTTOMLEFT", 0, -28)
nowTitle:SetText("Do now")

local nowText = roadmapFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
nowText:SetPoint("TOPLEFT", nowTitle, "BOTTOMLEFT", 0, -8)
nowText:SetWidth(680)
nowText:SetJustifyH("LEFT")

local nextTitle = roadmapFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
nextTitle:SetPoint("TOPLEFT", nowText, "BOTTOMLEFT", 0, -35)
nextTitle:SetText("Up next")

local nextText = roadmapFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
nextText:SetPoint("TOPLEFT", nextTitle, "BOTTOMLEFT", 0, -8)
nextText:SetWidth(680)
nextText:SetJustifyH("LEFT")

local roadRefresh = MakeButton(roadmapFrame, "Refresh roadmap", 130, 24)
roadRefresh:SetPoint("BOTTOMLEFT", 12, 12)
roadRefresh:SetScript("OnClick", function() Run(".guide roadmap") end)

local travelFrame = CreateFrame("Frame", nil, content)
travelFrame:SetAllPoints(content)
travelFrame:Hide()

local travelTitle = travelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
travelTitle:SetPoint("TOPLEFT", 10, -20)
travelTitle:SetText("Adventure Teleport Map")

local travelHelp = travelFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
travelHelp:SetPoint("TOPLEFT", travelTitle, "BOTTOMLEFT", 0, -4)
travelHelp:SetText("Only unlocked Guild Ready destinations are clickable. Travel remains server-validated.")

local outlandTitle = travelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
outlandTitle:SetPoint("TOPLEFT", 40, -74)
outlandTitle:SetText("OUTLAND / TBC")

local northTitle = travelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
northTitle:SetPoint("TOPLEFT", 400, -74)
northTitle:SetText("NORTHREND / WOTLK")

local travelButtons = {}
local travelPrev = MakeButton(travelFrame, "<", 32, 22)
travelPrev:SetPoint("BOTTOMLEFT", 22, 3)
local travelNext = MakeButton(travelFrame, ">", 32, 22)
travelNext:SetPoint("LEFT", travelPrev, "RIGHT", 5, 0)
local travelPageText = travelFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
travelPageText:SetPoint("LEFT", travelNext, "RIGHT", 8, 0)

local function ReadyTravelRows(source)
    local outland = {}
    local northrend = {}
    for _, entry in ipairs(source) do
        if entry.unlocked == "UNLOCKED" and entry.status == "Guild Ready" then
            if OUTLAND[entry.alias] then
                outland[#outland + 1] = entry
            elseif NORTHREND[entry.alias] then
                northrend[#northrend + 1] = entry
            end
        end
    end
    return outland, northrend
end

local function BuildTravelBoard()
    for _, b in ipairs(travelButtons) do b:Hide() end
    travelButtons = {}

    local outland, northrend = ReadyTravelRows(finderRows)
    local maxRows = math.max(#outland, #northrend)
    local maxPage = math.max(1, math.ceil(maxRows / TRAVEL_ROWS_PER_PAGE))
    if travelPage > maxPage then travelPage = maxPage end
    if travelPage < 1 then travelPage = 1 end

    local first = (travelPage - 1) * TRAVEL_ROWS_PER_PAGE + 1
    local last = first + TRAVEL_ROWS_PER_PAGE - 1

    local function AddColumn(entries, x)
        local rowIndex = 0
        for i = first, math.min(last, #entries) do
            local entry = entries[i]
            local b = MakeButton(travelFrame, entry.name, 305, 19)
            b:SetPoint("TOPLEFT", x, -96 - rowIndex * 20)
            b:SetScript("OnClick", function() Run(".guide go " .. entry.alias) end)
            travelButtons[#travelButtons + 1] = b
            rowIndex = rowIndex + 1
        end
    end

    AddColumn(outland, 26)
    AddColumn(northrend, 382)

    travelPageText:SetText(travelPage .. " / " .. maxPage)
    if travelPage > 1 then travelPrev:Enable() else travelPrev:Disable() end
    if travelPage < maxPage then travelNext:Enable() else travelNext:Disable() end
end

travelPrev:SetScript("OnClick", function()
    if travelPage > 1 then
        travelPage = travelPage - 1
        BuildTravelBoard()
    end
end)

travelNext:SetScript("OnClick", function()
    local outland, northrend = ReadyTravelRows(finderRows)
    local maxPage = math.max(1, math.ceil(math.max(#outland, #northrend) / TRAVEL_ROWS_PER_PAGE))
    if travelPage < maxPage then
        travelPage = travelPage + 1
        BuildTravelBoard()
    end
end)

local function CurrentRows()
    if mode == "compat" then return compatRows end
    return finderRows
end

function AG.UpdateDetails()
    if not selected then
        detailText:SetText("Select an activity to see its support note, gear guidance and actions.")
        formBtn:Disable()
        travelBtn:Disable()
        return
    end

    local readiness = selected.readiness or (selected.unlocked == "UNLOCKED" and "READY" or "LOCKED")
    local gearText = ""
    local target = tonumber(selected.targetIlvl or "0") or 0
    if target > 0 then
        gearText = "  •  Gear " .. (selected.itemLevel or "?") .. " / " .. target .. " ilvl"
    end
    detailText:SetText(selected.name .. "  •  " .. ReadinessLabel(readiness) .. gearText .. "\n" .. selected.note)
    local ready = selected.unlocked == "UNLOCKED" and selected.status == "Guild Ready"
    if ready then
        formBtn:Enable()
        travelBtn:Enable()
    else
        formBtn:Disable()
        travelBtn:Disable()
    end

    if selected.kind == "Raid" then
        formBtn:SetText("Prepare Raid")
    else
        formBtn:SetText("Form Group")
    end
end

formBtn:SetScript("OnClick", function()
    if not selected then return end
    if selected.kind == "Raid" then
        Run(".guide prepare " .. selected.alias)
    elseif IsInGuild() then
        SendChatMessage("anyone up for " .. selected.name .. "?", "GUILD")
    else
        DEFAULT_CHAT_FRAME:AddMessage("Adventure Guide: join/create your AI guild first; dungeon formation uses the Guild Director.")
    end
end)

travelBtn:SetScript("OnClick", function()
    if selected then Run(".guide go " .. selected.alias) end
end)

refreshBtn:SetScript("OnClick", function()
    if mode == "compat" then
        Run(".guide compat all")
    else
        Run(".guide finder all")
    end
end)

function AG.Refresh()
    local isRoad = mode == "roadmap"
    local isTravel = mode == "travel"

    roadmapFrame:SetShown(isRoad)
    travelFrame:SetShown(isTravel)
    header:SetShown(not isRoad and not isTravel)
    detail:SetShown(not isRoad and not isTravel)
    prev:SetShown(not isRoad and not isTravel)
    nextBtn:SetShown(not isRoad and not isTravel)
    pageText:SetShown(not isRoad and not isTravel)
    for _, row in ipairs(rows) do row:SetShown(not isRoad and not isTravel) end

    if isRoad then
        roadmapMeta:SetText("Level " .. roadmap.level .. "  •  Progression stage " .. roadmap.progression .. "  •  Equipped ilvl " .. roadmap.itemlevel)
        nowText:SetText(roadmap.now ~= "" and roadmap.now or "Loading...")
        nextText:SetText(roadmap.next ~= "" and roadmap.next or "Loading...")
        return
    end

    if isTravel then
        BuildTravelBoard()
        return
    end

    local data = CurrentRows()
    if mode == "compat" then
        header:SetText("Compatibility: encounter support green/yellow/red; player readiness is separate")
    else
        header:SetText("Recommended = sweet spot • Ready = unlocked • Gear low = advisory warning • Locked = future")
    end

    local maxPage = math.max(1, math.ceil(#data / ROWS_PER_PAGE))
    if page > maxPage then page = maxPage end
    if page < 1 then page = 1 end
    pageText:SetText(page .. " / " .. maxPage)

    if page > 1 then prev:Enable() else prev:Disable() end
    if page < maxPage then nextBtn:Enable() else nextBtn:Disable() end

    for i = 1, ROWS_PER_PAGE do
        local idx = (page - 1) * ROWS_PER_PAGE + i
        local entry = data[idx]
        local row = rows[i]
        if entry then
            row.data = entry
            row:Show()
            row.name:SetText(entry.name)
            row.kind:SetText(entry.kind)
            row.group:SetText(entry.size .. "-player")
            local readiness = entry.readiness or (entry.unlocked == "UNLOCKED" and "READY" or "LOCKED")
            local sr, sg, sb = ReadinessColor(readiness)
            row.state:SetTextColor(sr, sg, sb)
            row.state:SetText(ReadinessLabel(readiness))
            local r, g, b = StatusColor(entry.status)
            row.support:SetTextColor(r, g, b)
            row.support:SetText(entry.status)
        else
            row.data = nil
            row:Hide()
        end
    end

    AG.UpdateDetails()
end

local function RequestCurrent()
    if mode == "finder" then
        Run(".guide finder all")
    elseif mode == "compat" then
        Run(".guide compat all")
    elseif mode == "roadmap" then
        Run(".guide roadmap")
    elseif mode == "travel" then
        -- The travel board is sourced from the same authoritative Finder payload.
        Run(".guide finder all")
    end
end

local function SetTab(which)
    if which ~= "finder" and which ~= "travel" and which ~= "compat" and which ~= "roadmap" then
        which = "finder"
    end

    mode = which
    page = 1
    travelPage = 1
    selected = nil

    for key, button in pairs(tabs) do
        if key == which then PanelTemplates_SelectTab(button) else PanelTemplates_DeselectTab(button) end
    end

    AG.Refresh()
    RequestCurrent()
end

local tabDefs = {
    {"finder", "Finder"},
    {"travel", "Travel Map"},
    {"compat", "Compatibility"},
    {"roadmap", "Roadmap"},
}

for i, def in ipairs(tabDefs) do
    local key = def[1]
    local b = CreateFrame("Button", "AdventureGuideTab" .. i, frame, "CharacterFrameTabButtonTemplate")
    b:SetID(i)
    b:SetText(def[2])
    b:SetWidth(120)
    if i == 1 then
        b:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 18, 3)
    else
        b:SetPoint("LEFT", tabs[tabDefs[i - 1][1]], "RIGHT", -14, 0)
    end
    b:SetScript("OnClick", function() SetTab(key) end)
    tabs[key] = b
end
PanelTemplates_SetNumTabs(frame, #tabDefs)

local function ParseAG(msg)
    local payload = string.match(msg or "", "^%[AG%]%s*(.*)$")
    if not payload then return false end

    local p = Split(payload)
    if p[1] == "BEGIN" then
        if p[2] == "FINDER" then
            activeStream = "finder"
            finderRows = {}
        elseif p[2] == "COMPAT" then
            activeStream = "compat"
            compatRows = {}
        else
            activeStream = nil
        end
        return true
    end

    if p[1] == "END" then
        local finished = p[2] == "FINDER" and "finder" or (p[2] == "COMPAT" and "compat" or activeStream)
        activeStream = nil
        selected = nil
        page = 1
        if mode == finished or (mode == "travel" and finished == "finder") then
            AG.Refresh()
        end
        return true
    end

    if p[1] == "ROADMAP" then
        if p[2] == "LEVEL" then
            roadmap.level = p[3] or "?"
        elseif p[2] == "PROGRESSION" then
            roadmap.progression = p[3] or "?"
        elseif p[2] == "ITEMLEVEL" then
            roadmap.itemlevel = p[3] or "?"
        elseif p[2] == "NOW" then
            roadmap.now = p[3] or ""
        elseif p[2] == "NEXT" then
            roadmap.next = p[3] or ""
        end
        if mode == "roadmap" then AG.Refresh() end
        return true
    end

    if #p >= 8 and (activeStream == "finder" or activeStream == "compat") then
        local entry = {
            alias=p[1], name=p[2], kind=p[3], status=p[4],
            level=p[5], size=p[6], unlocked=p[7], note=p[8],
            readiness=p[9] or (p[7] == "UNLOCKED" and "READY" or "LOCKED"),
            itemLevel=p[10] or "?", targetIlvl=p[11] or "0",
        }
        if activeStream == "compat" then
            compatRows[#compatRows + 1] = entry
        else
            finderRows[#finderRows + 1] = entry
        end
        return true
    end

    return true
end

-- Parse transport exactly once via the event dispatcher. The chat-frame filter below only hides
-- machine lines. Parsing from the filter is unsafe because WoW can invoke a filter once per chat
-- frame, which duplicated Finder rows on clients with multiple system-message destinations.
local events = CreateFrame("Frame")
events:RegisterEvent("CHAT_MSG_SYSTEM")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, arg1)
    if event == "CHAT_MSG_SYSTEM" then
        ParseAG(arg1 or "")
    elseif event == "PLAYER_LOGIN" then
        AdventureGuideDB = AdventureGuideDB or {}
    end
end)

if ChatFrame_AddMessageEventFilter then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(self, event, msg, ...)
        if string.find(msg or "", "^%[AG%]") then
            return true
        end
        return false, msg, ...
    end)
end

local RADIUS = 80
local mini = CreateFrame("Button", "AdventureGuideMinimapButton", Minimap)
mini:SetWidth(31)
mini:SetHeight(31)
mini:SetFrameStrata("MEDIUM")
mini:SetFrameLevel(8)
mini:RegisterForClicks("LeftButtonUp")
mini:RegisterForDrag("LeftButton")

local icon = mini:CreateTexture(nil, "BACKGROUND")
icon:SetWidth(20)
icon:SetHeight(20)
icon:SetPoint("CENTER")
icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")

local border = mini:CreateTexture(nil, "OVERLAY")
border:SetWidth(53)
border:SetHeight(53)
border:SetPoint("TOPLEFT")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local function UpdateMini()
    AdventureGuideDB = AdventureGuideDB or {}
    local angle = math.rad(AdventureGuideDB.pos or 285)
    mini:ClearAllPoints()
    mini:SetPoint("CENTER", Minimap, "CENTER", RADIUS * math.cos(angle), RADIUS * math.sin(angle))
end

mini:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local scale = Minimap:GetEffectiveScale()
        local px, py = GetCursorPosition()
        px, py = px / scale, py / scale
        AdventureGuideDB = AdventureGuideDB or {}
        AdventureGuideDB.pos = math.deg(math.atan2(py - my, px - mx))
        UpdateMini()
    end)
end)

mini:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)

mini:SetScript("OnClick", function()
    if frame:IsShown() then frame:Hide() else frame:Show() end
end)

mini:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Adventure Guide")
    GameTooltip:AddLine("Finder, compatibility, roadmap and travel.", 1, 1, 1)
    GameTooltip:Show()
end)
mini:SetScript("OnLeave", function() GameTooltip:Hide() end)

SLASH_ADVENTUREGUIDE1 = "/adventureguide"
SLASH_ADVENTUREGUIDE2 = "/aguide"
SlashCmdList["ADVENTUREGUIDE"] = function()
    if frame:IsShown() then frame:Hide() else frame:Show() end
end

frame:SetScript("OnShow", function()
    UpdateMini()
    SetTab(mode or "finder")
end)

UpdateMini()
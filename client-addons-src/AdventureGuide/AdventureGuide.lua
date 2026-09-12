-- AdventureGuide for original WotLK 3.3.5a (Interface 30300).
-- The server owns all support/unlock/travel truth. This addon is presentation only.

local AG = {}
local ROWS_PER_PAGE = 12
local finderRows, compatRows = {}, {}
local roadmap = { level="?", progression="?", now="", next="" }
local mode, page, selected = "finder", 1, nil
local loggedIn = false

local OUTLAND = {
    ramparts=true,bloodfurnace=true,shatteredhalls=true,slavepens=true,underbog=true,
    steamvault=true,manatombs=true,auchenai=true,sethekk=true,shadowlab=true,
    oldhillsbrad=true,blackmorass=true,mechanar=true,botanica=true,arcatraz=true,
    magisters=true,karazhan=true,gruul=true,magtheridon=true,ssc=true,tempestkeep=true,
    hyjal=true,blacktemple=true,zulaman=true,sunwell=true,
}

local function ShowIf(widget, show)
    if show then widget:Show() else widget:Hide() end
end

local function Run(cmd)
    if not loggedIn or not DEFAULT_CHAT_FRAME or not DEFAULT_CHAT_FRAME.editBox then return end
    local eb = DEFAULT_CHAT_FRAME.editBox
    eb:SetText(cmd)
    ChatEdit_SendText(eb, 0)
end

local function Split(text)
    local out = {}
    for part in string.gmatch(text .. "|", "(.-)|") do out[#out+1] = part end
    return out
end

local function StatusColor(status)
    if status == "Guild Ready" then return 0.20,0.95,0.35 end
    if status == "Playable / experimental" then return 1.00,0.78,0.15 end
    return 1.00,0.25,0.25
end

local function MakeButton(parent, text, width, height)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetWidth(width); b:SetHeight(height); b:SetText(text)
    return b
end

local frame = CreateFrame("Frame", "AdventureGuideFrame", UIParent)
frame:SetWidth(790); frame:SetHeight(560); frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG"); frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
frame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=11,right=12,top=12,bottom=11}})
frame:Hide()

local title = frame:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
title:SetPoint("TOPLEFT",24,-19); title:SetText("Adventure Guide")
local subtitle = frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-4)
subtitle:SetText("Finder only offers Guild Ready content. Experimental content stays clearly marked.")
local close = CreateFrame("Button",nil,frame,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-6,-6)

local content = CreateFrame("Frame",nil,frame)
content:SetPoint("TOPLEFT",20,-76); content:SetPoint("BOTTOMRIGHT",-20,56)
local header = content:CreateFontString(nil,"OVERLAY","GameFontNormal")
header:SetPoint("TOPLEFT",4,-3); header:SetText("Loading...")

local rows = {}
for i=1,ROWS_PER_PAGE do
    local row = CreateFrame("Button",nil,content)
    row:SetWidth(720); row:SetHeight(27); row:SetPoint("TOPLEFT",4,-25-(i-1)*29)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
    row.name=row:CreateFontString(nil,"OVERLAY","GameFontHighlight"); row.name:SetPoint("LEFT",7,0); row.name:SetWidth(285); row.name:SetJustifyH("LEFT")
    row.kind=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.kind:SetPoint("LEFT",300,0); row.kind:SetWidth(75); row.kind:SetJustifyH("LEFT")
    row.group=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.group:SetPoint("LEFT",385,0); row.group:SetWidth(75); row.group:SetJustifyH("LEFT")
    row.state=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.state:SetPoint("LEFT",465,0); row.state:SetWidth(130); row.state:SetJustifyH("LEFT")
    row.support=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.support:SetPoint("LEFT",600,0); row.support:SetWidth(115); row.support:SetJustifyH("LEFT")
    row:SetScript("OnClick",function(self) selected=self.data; AG.UpdateDetails() end)
    rows[i]=row
end

local prev=MakeButton(content,"<",32,22); prev:SetPoint("BOTTOMLEFT",5,5)
local nextBtn=MakeButton(content,">",32,22); nextBtn:SetPoint("LEFT",prev,"RIGHT",5,0)
local pageText=content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); pageText:SetPoint("LEFT",nextBtn,"RIGHT",8,0)
prev:SetScript("OnClick",function() if page>1 then page=page-1; AG.Refresh() end end)
nextBtn:SetScript("OnClick",function() page=page+1; AG.Refresh() end)

local detail=CreateFrame("Frame",nil,content); detail:SetWidth(720); detail:SetHeight(64); detail:SetPoint("BOTTOMLEFT",4,34)
detail:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
detail:SetBackdropColor(0.05,0.05,0.05,0.85)
local detailText=detail:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); detailText:SetPoint("TOPLEFT",8,-7); detailText:SetWidth(500); detailText:SetJustifyH("LEFT"); detailText:SetJustifyV("TOP")
local formBtn=MakeButton(detail,"Form Group",100,24); formBtn:SetPoint("TOPRIGHT",-112,-8)
local travelBtn=MakeButton(detail,"Travel",100,24); travelBtn:SetPoint("TOPRIGHT",-7,-8)
local refreshBtn=MakeButton(detail,"Refresh",100,24); refreshBtn:SetPoint("TOPRIGHT",-7,-34)

local roadmapFrame=CreateFrame("Frame",nil,content); roadmapFrame:SetAllPoints(content); roadmapFrame:Hide()
local roadmapTitle=roadmapFrame:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); roadmapTitle:SetPoint("TOPLEFT",12,-30); roadmapTitle:SetText("Your Progression Roadmap")
local roadmapMeta=roadmapFrame:CreateFontString(nil,"OVERLAY","GameFontHighlight"); roadmapMeta:SetPoint("TOPLEFT",roadmapTitle,"BOTTOMLEFT",0,-18)
local nowTitle=roadmapFrame:CreateFontString(nil,"OVERLAY","GameFontNormal"); nowTitle:SetPoint("TOPLEFT",roadmapMeta,"BOTTOMLEFT",0,-28); nowTitle:SetText("Do now")
local nowText=roadmapFrame:CreateFontString(nil,"OVERLAY","GameFontHighlight"); nowText:SetPoint("TOPLEFT",nowTitle,"BOTTOMLEFT",0,-8); nowText:SetWidth(680); nowText:SetJustifyH("LEFT")
local nextTitle=roadmapFrame:CreateFontString(nil,"OVERLAY","GameFontNormal"); nextTitle:SetPoint("TOPLEFT",nowText,"BOTTOMLEFT",0,-35); nextTitle:SetText("Up next")
local nextText=roadmapFrame:CreateFontString(nil,"OVERLAY","GameFontHighlight"); nextText:SetPoint("TOPLEFT",nextTitle,"BOTTOMLEFT",0,-8); nextText:SetWidth(680); nextText:SetJustifyH("LEFT")
local roadRefresh=MakeButton(roadmapFrame,"Refresh roadmap",130,24); roadRefresh:SetPoint("BOTTOMLEFT",12,12); roadRefresh:SetScript("OnClick",function() Run(".guide roadmap") end)

local travelFrame=CreateFrame("Frame",nil,content); travelFrame:SetAllPoints(content); travelFrame:Hide()
local travelTitle=travelFrame:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); travelTitle:SetPoint("TOPLEFT",10,-25); travelTitle:SetText("Adventure Teleport Map")
local travelHelp=travelFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); travelHelp:SetPoint("TOPLEFT",travelTitle,"BOTTOMLEFT",0,-5); travelHelp:SetText("Only Guild Ready + unlocked activities are clickable. The server revalidates every travel request.")
local outlandTitle=travelFrame:CreateFontString(nil,"OVERLAY","GameFontNormal"); outlandTitle:SetPoint("TOPLEFT",40,-85); outlandTitle:SetText("OUTLAND / TBC")
local northTitle=travelFrame:CreateFontString(nil,"OVERLAY","GameFontNormal"); northTitle:SetPoint("TOPLEFT",400,-85); northTitle:SetText("NORTHREND / WOTLK")
local travelButtons={}

local function CurrentRows() if mode=="compat" then return compatRows end return finderRows end

local function BuildTravelBoard()
    for _,b in ipairs(travelButtons) do b:Hide() end
    travelButtons={}
    local leftY,rightY=-112,-112
    for _,entry in ipairs(finderRows) do
        if entry.unlocked=="UNLOCKED" and entry.status=="Guild Ready" then
            local left=OUTLAND[entry.alias]
            local b=MakeButton(travelFrame,entry.name,305,22)
            if left then b:SetPoint("TOPLEFT",26,leftY); leftY=leftY-25 else b:SetPoint("TOPLEFT",382,rightY); rightY=rightY-25 end
            b:SetScript("OnClick",function() Run(".guide go "..entry.alias) end)
            travelButtons[#travelButtons+1]=b
        end
    end
end

function AG.UpdateDetails()
    if not selected then detailText:SetText("Select an activity to see its support note and actions."); formBtn:Disable(); travelBtn:Disable(); return end
    detailText:SetText(selected.name.."\n"..selected.note)
    if selected.unlocked=="UNLOCKED" and selected.status=="Guild Ready" then formBtn:Enable(); travelBtn:Enable() else formBtn:Disable(); travelBtn:Disable() end
    if selected.kind=="Raid" then formBtn:SetText("Prepare Raid") else formBtn:SetText("Form Group") end
end

formBtn:SetScript("OnClick",function()
    if not selected then return end
    if selected.kind=="Raid" then Run(".guide prepare "..selected.alias)
    elseif IsInGuild() then SendChatMessage("anyone up for "..selected.name.."?","GUILD")
    else DEFAULT_CHAT_FRAME:AddMessage("Adventure Guide: dungeon formation uses your AI guild, so join/create it first.") end
end)
travelBtn:SetScript("OnClick",function() if selected then Run(".guide go "..selected.alias) end end)
refreshBtn:SetScript("OnClick",function() if mode=="compat" then Run(".guide compat all") else Run(".guide finder all") end end)

function AG.Refresh()
    local isRoad=mode=="roadmap"
    local isTravel=mode=="travel"
    ShowIf(roadmapFrame,isRoad); ShowIf(travelFrame,isTravel)
    local listVisible=not isRoad and not isTravel
    ShowIf(header,listVisible); ShowIf(detail,listVisible); ShowIf(prev,listVisible); ShowIf(nextBtn,listVisible); ShowIf(pageText,listVisible)
    for _,row in ipairs(rows) do ShowIf(row,listVisible and row.data~=nil) end

    if isRoad then
        roadmapMeta:SetText("Level "..roadmap.level.."  -  Progression stage "..roadmap.progression)
        nowText:SetText(roadmap.now~="" and roadmap.now or "Loading...")
        nextText:SetText(roadmap.next~="" and roadmap.next or "Loading...")
        return
    end
    if isTravel then BuildTravelBoard(); return end

    local data=CurrentRows()
    header:SetText(mode=="compat" and "Compatibility: green = ready, yellow = experimental, red = not ready" or "Supported Finder: Guild Ready dungeons and raids only")
    local maxPage=math.max(1,math.ceil(#data/ROWS_PER_PAGE)); if page>maxPage then page=maxPage end
    pageText:SetText(page.." / "..maxPage)
    for i=1,ROWS_PER_PAGE do
        local entry=data[(page-1)*ROWS_PER_PAGE+i]; local row=rows[i]
        if entry then
            row.data=entry; row:Show(); row.name:SetText(entry.name); row.kind:SetText(entry.kind); row.group:SetText(entry.size.."-player"); row.state:SetText(entry.unlocked=="UNLOCKED" and "Unlocked" or "Locked")
            local r,g,b=StatusColor(entry.status); row.support:SetTextColor(r,g,b); row.support:SetText(entry.status)
        else row.data=nil; row:Hide() end
    end
    AG.UpdateDetails()
end

local tabs={}
local function SetTab(which)
    mode=which; page=1; selected=nil
    for key,button in pairs(tabs) do if key==which then PanelTemplates_SelectTab(button) else PanelTemplates_DeselectTab(button) end end
    if loggedIn then
        if which=="finder" or which=="travel" then Run(".guide finder all") elseif which=="compat" then Run(".guide compat all") elseif which=="roadmap" then Run(".guide roadmap") end
    end
    AG.Refresh()
end

local tabDefs={{"finder","Finder"},{"travel","Travel Map"},{"compat","Compatibility"},{"roadmap","Roadmap"}}
for i,def in ipairs(tabDefs) do
    local b=CreateFrame("Button","AdventureGuideTab"..i,frame,"CharacterFrameTabButtonTemplate"); b:SetID(i); b:SetText(def[2]); b:SetWidth(120)
    if i==1 then b:SetPoint("TOPLEFT",frame,"BOTTOMLEFT",18,3) else b:SetPoint("LEFT",tabs[tabDefs[i-1][1]],"RIGHT",-14,0) end
    b:SetScript("OnClick",function() SetTab(def[1]) end); tabs[def[1]]=b
end
PanelTemplates_SetNumTabs(frame,#tabDefs)

local function ParseAG(msg)
    local payload=string.match(msg or "","^%[AG%]%s*(.*)$"); if not payload then return false end
    local p=Split(payload)
    if p[1]=="BEGIN" then if p[2]=="FINDER" then finderRows={} elseif p[2]=="COMPAT" then compatRows={} end; return true end
    if p[1]=="END" then selected=nil; page=1; AG.Refresh(); return true end
    if p[1]=="ROADMAP" then
        if p[2]=="LEVEL" then roadmap.level=p[3] or "?" elseif p[2]=="PROGRESSION" then roadmap.progression=p[3] or "?" elseif p[2]=="NOW" then roadmap.now=p[3] or "" elseif p[2]=="NEXT" then roadmap.next=p[3] or "" end
        if mode=="roadmap" then AG.Refresh() end; return true
    end
    if #p>=8 then
        local entry={alias=p[1],name=p[2],kind=p[3],status=p[4],level=p[5],size=p[6],unlocked=p[7],note=p[8]}
        -- The response stream tells us which collection is currently being populated through mode.
        -- Finder/Travel requests populate finderRows; Compatibility requests populate compatRows.
        if mode=="compat" then compatRows[#compatRows+1]=entry else finderRows[#finderRows+1]=entry end
        return true
    end
    return true
end

local events=CreateFrame("Frame")
events:RegisterEvent("CHAT_MSG_SYSTEM"); events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent",function(self,event,arg1)
    if event=="CHAT_MSG_SYSTEM" then ParseAG(arg1)
    elseif event=="PLAYER_LOGIN" then loggedIn=true; AdventureGuideDB=AdventureGuideDB or {}; if frame:IsShown() then SetTab(mode) end end
end)

-- CHAT_MSG_SYSTEM is parsed exactly once by the event frame above. This filter only hides the
-- machine-readable transport lines so multiple chat frames cannot duplicate our data rows.
if ChatFrame_AddMessageEventFilter then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM",function(self,event,msg,...)
        if string.find(msg or "","^%[AG%]") then return true end
        return false,msg,...
    end)
end

local RADIUS=80
local mini=CreateFrame("Button","AdventureGuideMinimapButton",Minimap)
mini:SetWidth(31); mini:SetHeight(31); mini:SetFrameStrata("MEDIUM"); mini:SetFrameLevel(8); mini:RegisterForClicks("LeftButtonUp"); mini:RegisterForDrag("LeftButton")
local icon=mini:CreateTexture(nil,"BACKGROUND"); icon:SetWidth(20); icon:SetHeight(20); icon:SetPoint("CENTER"); icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
local border=mini:CreateTexture(nil,"OVERLAY"); border:SetWidth(53); border:SetHeight(53); border:SetPoint("TOPLEFT"); border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
local function UpdateMini()
    local angle=math.rad((AdventureGuideDB and AdventureGuideDB.pos) or 285); mini:ClearAllPoints(); mini:SetPoint("CENTER",Minimap,"CENTER",RADIUS*math.cos(angle),RADIUS*math.sin(angle))
end
mini:SetScript("OnDragStart",function(self) self:SetScript("OnUpdate",function() local mx,my=Minimap:GetCenter(); local scale=Minimap:GetEffectiveScale(); local px,py=GetCursorPosition(); px,py=px/scale,py/scale; AdventureGuideDB=AdventureGuideDB or {}; AdventureGuideDB.pos=math.deg(math.atan2(py-my,px-mx)); UpdateMini() end) end)
mini:SetScript("OnDragStop",function(self) self:SetScript("OnUpdate",nil) end)
mini:SetScript("OnClick",function() if frame:IsShown() then frame:Hide() else frame:Show() end end)
mini:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_LEFT"); GameTooltip:AddLine("Adventure Guide"); GameTooltip:AddLine("Finder, compatibility, roadmap and travel.",1,1,1); GameTooltip:Show() end)
mini:SetScript("OnLeave",function() GameTooltip:Hide() end)

SLASH_ADVENTUREGUIDE1="/adventureguide"; SLASH_ADVENTUREGUIDE2="/aguide"
SlashCmdList["ADVENTUREGUIDE"]=function() if frame:IsShown() then frame:Hide() else frame:Show() end end
frame:SetScript("OnShow",function() SetTab(mode); UpdateMini() end)
UpdateMini()

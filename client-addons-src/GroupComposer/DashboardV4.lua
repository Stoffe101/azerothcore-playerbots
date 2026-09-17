local GC = GroupComposer
local D = GroupComposerData
local P = GroupComposerProfiles

GC.DashboardV4 = GC.DashboardV4 or {}
local U = GC.DashboardV4

local C = {
    bg = {0.012, 0.017, 0.025, 0.99}, chrome = {0.020, 0.029, 0.041, 1},
    sidebar = {0.025, 0.037, 0.052, 1}, card = {0.035, 0.050, 0.070, 1},
    card2 = {0.048, 0.066, 0.090, 1}, hover = {0.070, 0.095, 0.128, 1},
    line = {0.12, 0.18, 0.25, 1}, lineStrong = {0.22, 0.34, 0.46, 1},
    text = {0.94, 0.97, 1, 1}, muted = {0.63, 0.70, 0.79, 1}, dim = {0.39, 0.46, 0.56, 1},
    blue = {0.18, 0.62, 1, 1}, green = {0.18, 0.88, 0.46, 1}, red = {0.96, 0.28, 0.32, 1},
    gold = {1, 0.70, 0.16, 1}, orange = {1, 0.47, 0.16, 1}, purple = {0.67, 0.45, 1, 1},
    tankSoft = {0.035, 0.13, 0.22, 1}, healSoft = {0.035, 0.16, 0.09, 1}, dpsSoft = {0.18, 0.035, 0.045, 1},
}
local ROLE_COLOR = { TANK = C.blue, HEALER = C.green, DPS = C.red }
local ROLE_SOFT = { TANK = C.tankSoft, HEALER = C.healSoft, DPS = C.dpsSoft }
local ROLE_ORDER = {"TANK", "HEALER", "DPS"}

local SPEC_ICON = {
    WARRIOR = {"Interface\\Icons\\Ability_Warrior_SavageBlow", "Interface\\Icons\\Ability_Warrior_InnerRage", "Interface\\Icons\\Ability_Warrior_DefensiveStance"},
    PALADIN = {"Interface\\Icons\\Spell_Holy_HolyBolt", "Interface\\Icons\\Spell_Holy_DevotionAura", "Interface\\Icons\\Spell_Holy_AuraOfLight"},
    HUNTER = {"Interface\\Icons\\Ability_Hunter_BeastCall", "Interface\\Icons\\Ability_Marksmanship", "Interface\\Icons\\Ability_Hunter_SwiftStrike"},
    ROGUE = {"Interface\\Icons\\Ability_Rogue_Eviscerate", "Interface\\Icons\\Ability_BackStab", "Interface\\Icons\\Ability_Stealth"},
    PRIEST = {"Interface\\Icons\\Spell_Holy_PowerWordShield", "Interface\\Icons\\Spell_Holy_GuardianSpirit", "Interface\\Icons\\Spell_Shadow_ShadowWordPain"},
    DEATHKNIGHT = {"Interface\\Icons\\Spell_Deathknight_BloodPresence", "Interface\\Icons\\Spell_Deathknight_FrostPresence", "Interface\\Icons\\Spell_Deathknight_UnholyPresence"},
    SHAMAN = {"Interface\\Icons\\Spell_Nature_Lightning", "Interface\\Icons\\Spell_Nature_LightningShield", "Interface\\Icons\\Spell_Nature_HealingWaveGreater"},
    MAGE = {"Interface\\Icons\\Spell_Holy_MagicalSentry", "Interface\\Icons\\Spell_Fire_FireBolt02", "Interface\\Icons\\Spell_Frost_FrostBolt02"},
    WARLOCK = {"Interface\\Icons\\Spell_Shadow_DeathCoil", "Interface\\Icons\\Spell_Shadow_Metamorphosis", "Interface\\Icons\\Spell_Fire_Immolation"},
    DRUID = {"Interface\\Icons\\Spell_Nature_StarFall", "Interface\\Icons\\Ability_Druid_CatForm", "Interface\\Icons\\Spell_Nature_HealingTouch"},
}
local RAID_ART = {
    icecrown = "Interface\\Icons\\Achievement_Zone_IceCrown_01", ulduar = "Interface\\Icons\\Achievement_Raid_UlduarRaid_Misc_01",
    naxxramas = "Interface\\Icons\\Achievement_Dungeon_Naxxramas_Normal", trial_crusader = "Interface\\Icons\\Achievement_Reputation_ArgentChampion",
    ruby_sanctum = "Interface\\Icons\\Achievement_Boss_Halion", obsidian_sanctum = "Interface\\Icons\\Achievement_Boss_Sartharion_01",
    eye_of_eternity = "Interface\\Icons\\Achievement_Boss_Malygos_01", onyxia = "Interface\\Icons\\Achievement_Boss_Onyxia",
    black_temple = "Interface\\Icons\\Achievement_Boss_Illidan", sunwell = "Interface\\Icons\\Achievement_Boss_KilJaedan",
    karazhan = "Interface\\Icons\\Achievement_Boss_PrinceMalchezaar_02", molten_core = "Interface\\Icons\\Achievement_Boss_Ragnaros",
    blackwing_lair = "Interface\\Icons\\Achievement_Boss_Nefarion", aq40 = "Interface\\Icons\\Achievement_Boss_CThun",
}
local DUNGEON_ART = {
    random = "Interface\\Icons\\Achievement_Dungeon_GloryoftheHERO", utgarde_keep = "Interface\\Icons\\Achievement_Dungeon_UtgardeKeep_Normal",
    nexus = "Interface\\Icons\\Achievement_Dungeon_Nexus70_Normal", gundrak = "Interface\\Icons\\Achievement_Dungeon_Gundrak_Normal",
    halls_of_lightning = "Interface\\Icons\\Achievement_Dungeon_Ulduar77_Normal", halls_of_stone = "Interface\\Icons\\Achievement_Dungeon_Ulduar80_Normal",
    oculus = "Interface\\Icons\\Achievement_Dungeon_Oculus_Normal", trial_champion = "Interface\\Icons\\Achievement_Dungeon_ArgentTournament_Normal",
    forge_souls = "Interface\\Icons\\Achievement_Dungeon_FOS_Normal", pit_saron = "Interface\\Icons\\Achievement_Dungeon_PitOfSaron_Normal",
    halls_reflection = "Interface\\Icons\\Achievement_Dungeon_HallsOfReflection_Normal",
}
local ENCOUNTER_READY = { obsidian_sanctum=true, eye_of_eternity=true, onyxia=true, icecrown=true, ruby_sanctum=true, gruul=true, magtheridon=true }

local function Solid(parent, color, layer)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetTexture(color[1], color[2], color[3], color[4] or 1)
    return t
end
local function Text(parent, value, template, color)
    local f = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    f:SetText(value or "")
    local c = color or C.text; f:SetTextColor(c[1],c[2],c[3],c[4] or 1)
    f:SetJustifyH("LEFT"); f:SetJustifyV("MIDDLE")
    return f
end
local function Outline(parent, color)
    local c = color or C.line
    local out = {}
    out[1] = Solid(parent,c,"BORDER"); out[1]:SetPoint("TOPLEFT"); out[1]:SetPoint("TOPRIGHT"); out[1]:SetHeight(1)
    out[2] = Solid(parent,c,"BORDER"); out[2]:SetPoint("BOTTOMLEFT"); out[2]:SetPoint("BOTTOMRIGHT"); out[2]:SetHeight(1)
    out[3] = Solid(parent,c,"BORDER"); out[3]:SetPoint("TOPLEFT"); out[3]:SetPoint("BOTTOMLEFT"); out[3]:SetWidth(1)
    out[4] = Solid(parent,c,"BORDER"); out[4]:SetPoint("TOPRIGHT"); out[4]:SetPoint("BOTTOMRIGHT"); out[4]:SetWidth(1)
    return out
end
local function SetBorder(frame, color)
    if not frame or not frame.border then return end
    for _, t in ipairs(frame.border) do t:SetTexture(color[1],color[2],color[3],color[4] or 1) end
end
local function Panel(parent, color, border)
    local f = CreateFrame("Frame", nil, parent)
    f.bg = Solid(f,color or C.card); f.bg:SetAllPoints(f)
    f.border = Outline(f,border or C.line)
    return f
end
local function AddTooltip(frame, title, body)
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        GameTooltip:SetText(title or "Group Composer",1,0.82,0.35)
        if body and body ~= "" then GameTooltip:AddLine(body,0.82,0.86,0.92,true) end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
local function Button(parent, label, w, h, callback)
    local b = Panel(parent,C.card2,C.lineStrong); b:SetWidth(w or 120); b:SetHeight(h or 32); b:EnableMouse(true); b.enabled=true
    b.label = Text(b,label or "Button","GameFontHighlight",C.text); b.label:SetPoint("CENTER")
    b:SetScript("OnMouseDown",function(self) if self.enabled and callback then callback() end end)
    b:SetScript("OnEnter",function(self) if self.enabled then self.bg:SetTexture(C.hover[1],C.hover[2],C.hover[3],1) end end)
    b:SetScript("OnLeave",function(self) self.bg:SetTexture(C.card2[1],C.card2[2],C.card2[3],1) end)
    function b:SetEnabledState(on) self.enabled=on and true or false; self:SetAlpha(self.enabled and 1 or 0.35) end
    function b:SetAccent(color,on)
        SetBorder(self,on and color or C.lineStrong)
        self.label:SetTextColor((on and color or C.text)[1],(on and color or C.text)[2],(on and color or C.text)[3],1)
    end
    return b
end
local function Icon(parent,path,size)
    local t=parent:CreateTexture(nil,"ARTWORK"); t:SetTexture(path); t:SetWidth(size or 26); t:SetHeight(size or 26); t:SetTexCoord(0.08,0.92,0.08,0.92); return t
end
local function RoleIcon(parent,role,size) return Icon(parent,D.ROLE_ICON[role] or D.ROLE_ICON.DPS,size) end
local function ClassIcon(parent,class,size)
    local t=parent:CreateTexture(nil,"ARTWORK"); t:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"); t:SetWidth(size or 26); t:SetHeight(size or 26)
    local c=CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]; if c then t:SetTexCoord(c[1],c[2],c[3],c[4]) else t:SetTexCoord(0,1,0,1) end; return t
end
local function SetClassIcon(t,class)
    t:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"); local c=CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    if c then t:SetTexCoord(c[1],c[2],c[3],c[4]) else t:SetTexCoord(0,1,0,1) end
end
local function ClassColor(class)
    local c=RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]; if c then return {c.r,c.g,c.b,1} end; return C.text
end
local function SpecIconPath(class,spec)
    spec=tonumber(spec); return SPEC_ICON[class] and spec and SPEC_ICON[class][spec+1] or nil
end
local function StatusTexture(parent,size)
    local t=parent:CreateTexture(nil,"ARTWORK"); t:SetWidth(size or 18); t:SetHeight(size or 18); return t
end
local function SetStatusTexture(t,kind)
    if kind=="READY" or kind=="DONE" then t:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    elseif kind=="ERROR" then t:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
    elseif kind=="PREPARING" or kind=="BUILDING" or kind=="ASSEMBLING" then t:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
    else t:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") end
end

local activeMenu
local function CloseMenu() if activeMenu then activeMenu:Hide(); activeMenu=nil end end
local function Selector(parent,w,getItems,getValue,setValue,maxVisible)
    local b=Button(parent,"Select",w or 180,30); b.label:ClearAllPoints(); b.label:SetPoint("LEFT",10,0); b.label:SetPoint("RIGHT",-25,0); b.label:SetJustifyH("LEFT")
    b.arrow=Text(b,"v","GameFontHighlightSmall",C.muted); b.arrow:SetPoint("RIGHT",-9,0)
    local menu=Panel(b,C.bg,C.blue); menu:SetFrameStrata("TOOLTIP"); menu:SetWidth(w or 180); menu:Hide(); menu.rows={}; menu.offset=1; menu.maxVisible=maxVisible or 8
    local function refreshRows()
        local items=getItems and getItems() or {}; local count=math.min(#items,menu.maxVisible)
        for i=1,menu.maxVisible do
            local row=menu.rows[i]
            if not row then
                row=Button(menu,"",(w or 180)-8,24); row.label:ClearAllPoints(); row.label:SetPoint("LEFT",8,0); row.label:SetPoint("RIGHT",-5,0); row.label:SetJustifyH("LEFT"); menu.rows[i]=row
            end
            local idx=menu.offset+i-1; local item=items[idx]
            if item then
                row:ClearAllPoints(); row:SetPoint("TOPLEFT",4,-4-(i-1)*26); row.label:SetText(item.label); row:Show()
                row:SetScript("OnMouseDown",function() if setValue then setValue(item.value) end; CloseMenu(); b:Refresh() end)
            else row:Hide() end
        end
        menu:SetHeight(math.max(34,count*26+8))
    end
    menu:EnableMouseWheel(true); menu:SetScript("OnMouseWheel",function(_,delta)
        local items=getItems and getItems() or {}; local max=math.max(1,#items-menu.maxVisible+1); menu.offset=math.max(1,math.min(max,menu.offset-delta)); refreshRows()
    end)
    function b:Refresh()
        local value=getValue and getValue(); local label="Select"
        for _,item in ipairs(getItems and getItems() or {}) do if item.value==value then label=item.label break end end
        self.label:SetText(label)
    end
    function b:Open()
        CloseMenu(); menu.offset=1; refreshRows(); menu:ClearAllPoints(); menu:SetPoint("TOPLEFT",b,"BOTTOMLEFT",0,-3); menu:Show(); activeMenu=menu
    end
    b:SetScript("OnMouseDown",function() if menu:IsShown() then CloseMenu() else b:Open() end end); b:Refresh(); return b
end
local function Toggle(parent,label,getter,setter)
    local f=CreateFrame("Frame",nil,parent); f:SetHeight(26); f:EnableMouse(true)
    local box=Panel(f,C.bg,C.lineStrong); box:SetWidth(18); box:SetHeight(18); box:SetPoint("LEFT")
    local check=box:CreateTexture(nil,"ARTWORK"); check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check"); check:SetAllPoints(box)
    local txt=Text(f,label,"GameFontHighlightSmall",C.text); txt:SetPoint("LEFT",box,"RIGHT",7,0)
    function f:Refresh() local on=getter() and true or false; if on then check:Show(); SetBorder(box,C.green) else check:Hide(); SetBorder(box,C.lineStrong) end end
    f:SetScript("OnMouseDown",function() setter(not getter()); f:Refresh() end); f:Refresh(); return f
end

local function ClassCanRole(class,role) return D.CLASS_ROLE[role] and D.CLASS_ROLE[role][class] and true or false end
local function ClassesForRole(role,any)
    local out={}; if any then out[#out+1]={value="ANY",label="Auto - any class"} end
    for _,c in ipairs(D.CLASS_ORDER) do if ClassCanRole(c,role) then out[#out+1]={value=c,label=D.CLASS_LABEL[c]} end end; return out
end
local function SpecsForRole(class,role,any)
    local out={}; if any then out[#out+1]={value="ANY",label="Auto - any spec"} end
    if class=="ANY" then return out end
    for _,s in ipairs(D.SPECS[class] or {}) do if s.role==role or (role=="TANK" and s.canTank) then out[#out+1]={value=s.id,label=s.label} end end; return out
end
local function PlayerSpec()
    local name,index,pts="Current build",nil,-1
    for i=1,3 do local ok,n,_,p=pcall(GetTalentTabInfo,i); if ok and n and (tonumber(p) or 0)>pts then name,index,pts=n,i-1,tonumber(p) or 0 end end
    return name,index
end
local function Humans() return GC:ScanHumans() or {} end
local function HumanCounts()
    local out={TANK=0,HEALER=0,DPS=0}
    for _,h in ipairs(Humans()) do local r=GC:GetConfig().humanRoles[h.name]; if out[r] then out[r]=out[r]+1 end end; return out
end
local function HumanReady()
    for _,h in ipairs(Humans()) do if not GC:GetConfig().humanRoles[h.name] then return false end end; return #Humans()>0
end
local function Remaining(role)
    local c=GC:GetConfig(); local n=role=="TANK" and c.tanks or role=="HEALER" and c.healers or c.dps; local hc=HumanCounts(); return math.max(0,(tonumber(n) or 0)-(hc[role] or 0))
end
local function Required(role)
    local out={}; for _,p in ipairs(GC:GetConfig().preferences[role] or {}) do if p.required then out[#out+1]={class=p.class or "ANY",spec=p.spec==nil and "ANY" or p.spec} end end; return out
end
local function WriteRequired(role,rows)
    local out={}; for _,r in ipairs(rows or {}) do if r.class and r.class~="ANY" then out[#out+1]={class=r.class,spec=r.spec==nil and "ANY" or r.spec,required=true} end end
    GC:GetConfig().preferences[role]=out; GC:Touch("Exact composition changed")
end
local function Aggregated(role)
    local map,order={},{}; for _,p in ipairs(Required(role)) do local k=tostring(p.class)..":"..tostring(p.spec); if not map[k] then map[k]={class=p.class,spec=p.spec,count=0}; order[#order+1]=k end; map[k].count=map[k].count+1 end
    local out={}; for _,k in ipairs(order) do out[#out+1]=map[k] end; return out
end
local function WriteAggregated(role,rows)
    local out={}; for _,r in ipairs(rows or {}) do for i=1,math.max(1,tonumber(r.count) or 1) do out[#out+1]={class=r.class,spec=r.spec} end end; WriteRequired(role,out)
end

local frame=CreateFrame("Frame","GroupComposerDashboardV4Frame",UIParent); U.frame=frame; frame:SetWidth(1500); frame:SetHeight(900); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG"); frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton"); frame:SetClampedToScreen(true); frame:Hide()
local root=Solid(frame,C.bg); root:SetAllPoints(frame); frame.border=Outline(frame,C.lineStrong); frame:SetScript("OnDragStart",frame.StartMoving); frame:SetScript("OnDragStop",frame.StopMovingOrSizing)
UISpecialFrames=UISpecialFrames or {}; table.insert(UISpecialFrames,"GroupComposerDashboardV4Frame")

local header=Panel(frame,C.chrome,C.line); header:SetPoint("TOPLEFT",1,-1); header:SetPoint("TOPRIGHT",-1,-1); header:SetHeight(72)
local logo=Icon(header,"Interface\\Icons\\Achievement_Boss_LichKing",46); logo:SetPoint("LEFT",18,0)
local title=Text(header,"GROUP COMPOSER","GameFontNormalLarge",C.text); title:SetPoint("TOPLEFT",76,-13)
local subtitle=Text(header,"Build the team. Composer prepares the bots. You play your character.","GameFontHighlightSmall",C.muted); subtitle:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-5)
local backendDot=Solid(header,C.dim,"ARTWORK"); backendDot:SetWidth(8); backendDot:SetHeight(8); backendDot:SetPoint("RIGHT",-222,0)
local backend=Text(header,"Backend checking","GameFontHighlightSmall",C.muted); backend:SetPoint("LEFT",backendDot,"RIGHT",7,0)
local close=Button(header,"Close  X",112,32,function() CloseMenu(); frame:Hide() end); close:SetPoint("RIGHT",-18,0); close:SetAccent(C.red,true)

local side=Panel(frame,C.sidebar,C.line); side:SetPoint("TOPLEFT",1,-73); side:SetPoint("BOTTOMLEFT",1,1); side:SetWidth(190)
local sideTitle=Text(side,"GROUP COMPOSER","GameFontNormal",C.text); sideTitle:SetPoint("TOPLEFT",18,-20)
local sideSub=Text(side,"Party and raid planner","GameFontHighlightSmall",C.muted); sideSub:SetPoint("TOPLEFT",sideTitle,"BOTTOMLEFT",0,-3)
local navDungeon=Button(side,"Dungeon",158,42,function() GC:SetMode("DUNGEON") end); navDungeon:SetPoint("TOPLEFT",16,-76)
local navRaid=Button(side,"Raid",158,42,function() GC:SetMode("RAID") end); navRaid:SetPoint("TOPLEFT",16,-126)
local navTemplates=Button(side,"Templates",158,42,function() U:ShowTemplates() end); navTemplates:SetPoint("TOPLEFT",16,-188)
local navPeople=Button(side,"Humans & Pins",158,42,function() U:ShowPeople() end); navPeople:SetPoint("TOPLEFT",16,-238)
local helpIcon=Icon(side,"Interface\\Icons\\INV_Misc_QuestionMark",22); helpIcon:SetPoint("BOTTOMLEFT",18,20); AddTooltip(helpIcon,"How Composer works","Choose a legal role for every real player. Build & Prepare selects, reserves and prepares bots without changing your live group. Assemble commits the reviewed roster. Humans are never silently removed or respecced.")
local helpText=Text(side,"How it works","GameFontHighlightSmall",C.muted); helpText:SetPoint("LEFT",helpIcon,"RIGHT",7,0)

local body=CreateFrame("Frame",nil,frame); body:SetPoint("TOPLEFT",206,-88); body:SetPoint("BOTTOMRIGHT",-16,42)
local footer=Panel(frame,C.chrome,C.line); footer:SetPoint("BOTTOMLEFT",206,10); footer:SetPoint("BOTTOMRIGHT",-16,10); footer:SetHeight(25)
local footerText=Text(footer,"Ready.","GameFontHighlightSmall",C.muted); footerText:SetPoint("LEFT",10,0); footerText:SetPoint("RIGHT",-10,0)

local activity=Panel(body,C.card,C.lineStrong); activity:SetPoint("TOPLEFT",0,0); activity:SetPoint("TOPRIGHT",0,0); activity:SetHeight(104)
local activityArt=Panel(activity,C.bg,C.lineStrong); activityArt:SetPoint("LEFT",14,0); activityArt:SetWidth(72); activityArt:SetHeight(72)
local activityIcon=Icon(activityArt,"Interface\\Icons\\Achievement_Dungeon_GloryoftheHERO",62); activityIcon:SetPoint("CENTER")
local activityTitle=Text(activity,"Dungeon Group","GameFontNormalLarge",C.text); activityTitle:SetPoint("TOPLEFT",102,-18)
local activitySub=Text(activity,"Choose an activity and difficulty.","GameFontHighlightSmall",C.muted); activitySub:SetPoint("TOPLEFT",activityTitle,"BOTTOMLEFT",0,-4)
local selectorA,selectorB
local badge=Panel(activity,C.card2,C.lineStrong); badge:SetWidth(190); badge:SetHeight(34); badge:SetPoint("RIGHT",-16,0)
local badgeIcon=StatusTexture(badge,20); badgeIcon:SetPoint("LEFT",8,0); local badgeText=Text(badge,"Supported","GameFontHighlightSmall",C.green); badgeText:SetPoint("LEFT",badgeIcon,"RIGHT",7,0)

local function DungeonItems() local out={}; for _,d in ipairs(D.DUNGEONS) do out[#out+1]={value=d.id,label=d.label} end; return out end
local function DifficultyItems() local out={}; for _,d in ipairs(D.DUNGEON_DIFFICULTIES) do out[#out+1]={value=d.id,label=d.label} end; return out end
local function RaidItems() local out={}; for _,r in ipairs(D.RAIDS) do out[#out+1]={value=r.id,label=r.era.." - "..r.label} end; return out end
local function RaidDiffItems() local r=D.GetRaidById(GC:GetConfig().activity); local out={{value="normal",label="Normal"}}; if r and r.heroic then out[#out+1]={value="heroic",label="Heroic"} end; return out end
selectorA=Selector(activity,315,function() return GC:GetConfig().mode=="RAID" and RaidItems() or DungeonItems() end,function() return GC:GetConfig().activity end,function(v) if GC:GetConfig().mode=="RAID" then GC:SetRaidActivity(v) else GC:SetDungeonActivity(v) end end,8); selectorA:SetPoint("TOPLEFT",102,-58)
selectorB=Selector(activity,190,function() return GC:GetConfig().mode=="RAID" and RaidDiffItems() or DifficultyItems() end,function() return GC:GetConfig().difficulty end,function(v) GC:GetConfig().difficulty=v; GC:Touch("Difficulty changed") end,7); selectorB:SetPoint("LEFT",selectorA,"RIGHT",10,0)

local anchors=Panel(body,C.card,C.line); anchors:SetPoint("TOPLEFT",0,-116); anchors:SetWidth(936); anchors:SetHeight(112)
local anchTitle=Text(anchors,"YOUR PARTY","GameFontNormal",C.text); anchTitle:SetPoint("TOPLEFT",14,-11)
local anchHint=Text(anchors,"Real players are locked anchors. Choose only a role your class can actually play.","GameFontHighlightSmall",C.muted); anchHint:SetPoint("TOPLEFT",anchTitle,"BOTTOMLEFT",0,-3)
local humanRows={}
local function RefreshHumans()
    local humans=Humans(); for _,r in ipairs(humanRows) do r:Hide() end
    for i,h in ipairs(humans) do
        if i>3 then break end
        local row=humanRows[i]
        if not row then
            row=Panel(anchors,C.bg,C.line); row:SetHeight(48); row:SetWidth(286)
            row.icon=ClassIcon(row,"WARRIOR",32); row.icon:SetPoint("LEFT",8,0)
            row.name=Text(row,"","GameFontNormal",C.text); row.name:SetPoint("TOPLEFT",48,-7); row.name:SetWidth(105)
            row.spec=Text(row,"","GameFontHighlightSmall",C.muted); row.spec:SetPoint("TOPLEFT",48,-26); row.spec:SetWidth(105)
            row.roles={}; local x=0; for _,role in ipairs(ROLE_ORDER) do local rb=Button(row,string.sub(D.ROLE_LABEL[role],1,1),30,28); rb:SetPoint("RIGHT",-7-x,0); rb.role=role; row.roles[role]=rb; x=x+34 end
            humanRows[i]=row
        end
        row:ClearAllPoints(); row:SetPoint("TOPLEFT",14+(i-1)*300,-53); row.human=h; SetClassIcon(row.icon,h.class)
        row.name:SetText((h.isPlayer and "YOU - " or "")..tostring(h.name)); local cc=ClassColor(h.class); row.name:SetTextColor(cc[1],cc[2],cc[3],1)
        local spec=h.isPlayer and PlayerSpec() or (D.CLASS_LABEL[h.class] or h.class); row.spec:SetText(tostring(spec))
        local selected=GC:GetConfig().humanRoles[h.name]
        for _,role in ipairs(ROLE_ORDER) do local rb=row.roles[role]; local allowed=ClassCanRole(h.class,role); rb:SetEnabledState(allowed); rb:SetAccent(ROLE_COLOR[role],selected==role); rb:SetScript("OnMouseDown",function() if allowed then GC:SetHumanRole(h.name,role) end end); AddTooltip(rb,D.ROLE_LABEL[role],allowed and "Lock this real player to this role." or "This class cannot perform this role in WotLK.") end
        row:Show()
    end
end

local command=Panel(body,C.card,C.lineStrong); command:SetPoint("TOPRIGHT",0,-116); command:SetWidth(320); command:SetHeight(652)
local cmdTitle=Text(command,"COMPOSER STATUS","GameFontNormal",C.text); cmdTitle:SetPoint("TOPLEFT",16,-14)
local phaseIcon=StatusTexture(command,28); phaseIcon:SetPoint("TOPLEFT",16,-45)
local phaseTitle=Text(command,"Configure roster","GameFontNormalLarge",C.gold); phaseTitle:SetPoint("LEFT",phaseIcon,"RIGHT",10,4)
local phaseDetail=Text(command,"Choose your role and build a roster.","GameFontHighlightSmall",C.muted); phaseDetail:SetPoint("TOPLEFT",phaseTitle,"BOTTOMLEFT",0,-3); phaseDetail:SetWidth(244); phaseDetail:SetJustifyV("TOP")
local count=Text(command,"1 / 5","GameFontNormalLarge",C.text); count:SetPoint("TOPLEFT",16,-103)
local countSub=Text(command,"1 human - 4 bots needed","GameFontHighlightSmall",C.muted); countSub:SetPoint("TOPLEFT",16,-128)
local progBG=Panel(command,C.bg,C.line); progBG:SetPoint("TOPLEFT",16,-158); progBG:SetWidth(288); progBG:SetHeight(14)
local progFill=Solid(progBG,C.blue,"ARTWORK"); progFill:SetPoint("TOPLEFT",2,-2); progFill:SetPoint("BOTTOMLEFT",2,2); progFill:SetWidth(1)
local progressText=Text(command,"","GameFontHighlightSmall",C.muted); progressText:SetPoint("TOPLEFT",16,-179)
local divider=Solid(command,C.line,"ARTWORK"); divider:SetPoint("TOPLEFT",16,-206); divider:SetWidth(288); divider:SetHeight(1)
local coverageTitle=Text(command,"COVERAGE","GameFontNormalSmall",C.muted); coverageTitle:SetPoint("TOPLEFT",16,-220)
local coverageText=Text(command,"Build a preview to inspect utility coverage.","GameFontHighlightSmall",C.muted); coverageText:SetPoint("TOPLEFT",16,-244); coverageText:SetWidth(288); coverageText:SetJustifyV("TOP")
local warnTitle=Text(command,"WARNINGS / NEXT STEP","GameFontNormalSmall",C.gold); warnTitle:SetPoint("TOPLEFT",16,-326)
local warnRows={}; for i=1,3 do local t=Text(command,"","GameFontHighlightSmall",i==1 and C.gold or C.muted); t:SetPoint("TOPLEFT",16,-350-(i-1)*38); t:SetWidth(288); t:SetJustifyV("TOP"); warnRows[i]=t end
local buildBtn=Button(command,"Build & Prepare",138,38,function() GC:FindRoster() end); buildBtn:SetPoint("BOTTOMLEFT",16,18); buildBtn:SetAccent(C.blue,true)
local assembleBtn=Button(command,"Assemble",138,38,function() U:ShowAssembleConfirm() end); assembleBtn:SetPoint("BOTTOMRIGHT",-16,18); assembleBtn:SetAccent(C.gold,true)

local content=Panel(body,C.card,C.line); content:SetPoint("TOPLEFT",0,-240); content:SetWidth(936); content:SetHeight(528)
local contentTitle=Text(content,"PARTY COMPOSITION","GameFontNormal",C.text); contentTitle:SetPoint("TOPLEFT",14,-12)
local contentHint=Text(content,"Auto slots require no work. Pick a class/spec only where you care.","GameFontHighlightSmall",C.muted); contentHint:SetPoint("TOPLEFT",contentTitle,"BOTTOMLEFT",0,-3)

local dungeonView=CreateFrame("Frame",nil,content); dungeonView:SetPoint("TOPLEFT",12,-50); dungeonView:SetPoint("BOTTOMRIGHT",-12,12)
local dungeonSlotRows={}
local function DungeonRoleSequence() return {"TANK","HEALER","DPS","DPS","DPS"} end
local function DungeonModel()
    local sequence=DungeonRoleSequence(); local humans=Humans(); local used={}; local assigned={}
    for _,h in ipairs(humans) do
        local role=GC:GetConfig().humanRoles[h.name]
        if role then for i,r in ipairs(sequence) do if r==role and not used[i] then assigned[i]=h; used[i]=true; break end end end
    end
    local roleIndex={TANK=0,HEALER=0,DPS=0}; local req={TANK=Required("TANK"),HEALER=Required("HEALER"),DPS=Required("DPS")}
    local out={}
    for i,role in ipairs(sequence) do
        local x={role=role,human=assigned[i]}; if not x.human then roleIndex[role]=roleIndex[role]+1; x.botIndex=roleIndex[role]; x.pref=req[role][x.botIndex] end; out[i]=x
    end
    return out
end
local function SetDungeonPref(role,index,class,spec)
    local rows=Required(role); rows[index]={class=class,spec=spec}
    local clean={}; for _,r in ipairs(rows) do if r and r.class and r.class~="ANY" then clean[#clean+1]=r end end; WriteRequired(role,clean)
end
for i=1,5 do
    local row=Panel(dungeonView,C.bg,C.line); row:SetHeight(70); row:SetPoint("TOPLEFT",0,-(i-1)*78); row:SetPoint("RIGHT",0,0)
    row.roleBox=Panel(row,C.card2,C.lineStrong); row.roleBox:SetWidth(108); row.roleBox:SetPoint("TOPLEFT",0,0); row.roleBox:SetPoint("BOTTOMLEFT",0,0)
    row.roleIcon=RoleIcon(row.roleBox,"DPS",30); row.roleIcon:SetPoint("TOPLEFT",10,-10); row.role=Text(row.roleBox,"DPS","GameFontNormal",C.red); row.role:SetPoint("LEFT",row.roleIcon,"RIGHT",8,4); row.slot=Text(row.roleBox,"Slot 1","GameFontHighlightSmall",C.muted); row.slot:SetPoint("LEFT",row.roleIcon,"RIGHT",8,-12)
    row.memberIcon=ClassIcon(row,"WARRIOR",38); row.memberIcon:SetPoint("LEFT",126,0); row.name=Text(row,"Auto-fill bot","GameFontNormal",C.text); row.name:SetPoint("TOPLEFT",176,-13); row.name:SetWidth(180); row.sub=Text(row,"Composer chooses a suitable build","GameFontHighlightSmall",C.muted); row.sub:SetPoint("TOPLEFT",176,-35); row.sub:SetWidth(230)
    row.classDD=Selector(row,180,function() return ClassesForRole(row.model and row.model.role or "DPS",true) end,function() return row.model and row.model.pref and row.model.pref.class or "ANY" end,function(v) local m=row.model;if not m or m.human then return end; local specs=SpecsForRole(v,m.role,true); SetDungeonPref(m.role,m.botIndex,v,specs[1] and specs[1].value or "ANY") end,8); row.classDD:SetPoint("RIGHT",-210,0)
    row.specDD=Selector(row,195,function() local m=row.model; local cls=m and m.pref and m.pref.class or "ANY"; return SpecsForRole(cls,m and m.role or "DPS",true) end,function() return row.model and row.model.pref and row.model.pref.spec or "ANY" end,function(v) local m=row.model;if m and not m.human then SetDungeonPref(m.role,m.botIndex,m.pref and m.pref.class or "ANY",v) end end,6); row.specDD:SetPoint("RIGHT",-5,0)
    dungeonSlotRows[i]=row
end
local function RefreshDungeonSlots()
    for i,m in ipairs(DungeonModel()) do
        local row=dungeonSlotRows[i]; row.model=m; row.role:SetText(D.ROLE_LABEL[m.role]); local rc=ROLE_COLOR[m.role]; row.role:SetTextColor(rc[1],rc[2],rc[3],1); row.roleIcon:SetTexture(D.ROLE_ICON[m.role]); SetBorder(row.roleBox,rc); row.slot:SetText(m.human and "Human" or "Bot slot")
        if m.human then SetClassIcon(row.memberIcon,m.human.class); row.name:SetText((m.human.isPlayer and "YOU - " or "")..m.human.name); local cc=ClassColor(m.human.class); row.name:SetTextColor(cc[1],cc[2],cc[3],1); row.sub:SetText("Locked "..D.ROLE_LABEL[m.role].." - current build preserved"); row.classDD:Hide(); row.specDD:Hide()
        else local p=m.pref; if p and p.class and p.class~="ANY" then SetClassIcon(row.memberIcon,p.class); local cc=ClassColor(p.class); row.name:SetTextColor(cc[1],cc[2],cc[3],1); local spec=D.GetSpec(p.class,p.spec); row.name:SetText((spec and spec.label or "Any").." "..D.CLASS_LABEL[p.class]); row.sub:SetText("Exact build - Composer will prepare if needed") else row.memberIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); row.memberIcon:SetTexCoord(0.08,0.92,0.08,0.92); row.name:SetText("Auto-fill bot"); row.name:SetTextColor(C.text[1],C.text[2],C.text[3],1); row.sub:SetText("Composer chooses the best available build") end; row.classDD:Show(); row.specDD:Show(); row.classDD:Refresh(); row.specDD:Refresh() end
    end
end

local raidView=CreateFrame("Frame",nil,content); raidView:SetAllPoints(dungeonView); raidView:Hide(); U.raidExact=false
local modeQuick=Button(raidView,"Quick Composition",150,30,function() U.raidExact=false; U:Refresh() end); modeQuick:SetPoint("TOPLEFT",0,0)
local modeExact=Button(raidView,"Exact Builds",130,30,function() U.raidExact=true; U:Refresh() end); modeExact:SetPoint("LEFT",modeQuick,"RIGHT",8,0)
local quick=CreateFrame("Frame",nil,raidView); quick:SetPoint("TOPLEFT",0,-44); quick:SetPoint("BOTTOMRIGHT",0,0)
local roleCards={}
for i,role in ipairs(ROLE_ORDER) do
    local card=Panel(quick,ROLE_SOFT[role],ROLE_COLOR[role]); card:SetWidth(286); card:SetHeight(145); card:SetPoint("TOPLEFT",(i-1)*300,0)
    local ri=RoleIcon(card,role,42); ri:SetPoint("TOPLEFT",14,-14); local rt=Text(card,D.ROLE_LABEL[role],"GameFontNormalLarge",ROLE_COLOR[role]); rt:SetPoint("LEFT",ri,"RIGHT",10,6)
    card.count=Text(card,"0","GameFontNormalHuge",C.text); card.count:SetPoint("TOPRIGHT",-18,-18); card.need=Text(card,"0 bots after humans","GameFontHighlightSmall",C.muted); card.need:SetPoint("TOPLEFT",14,-74)
    if role~="DPS" then card.minus=Button(card,"-",30,28); card.minus:SetPoint("BOTTOMLEFT",14,12); card.plus=Button(card,"+",30,28); card.plus:SetPoint("LEFT",card.minus,"RIGHT",6,0) end
    roleCards[role]=card
end
local quickHelp=Panel(quick,C.bg,C.line); quickHelp:SetPoint("TOPLEFT",0,-160); quickHelp:SetWidth(886); quickHelp:SetHeight(100)
local qIcon=Icon(quickHelp,"Interface\\Icons\\INV_Misc_Map_01",42); qIcon:SetPoint("LEFT",14,0); local qTitle=Text(quickHelp,"Automatic roster filling","GameFontNormal",C.text); qTitle:SetPoint("TOPLEFT",70,-18); local qText=Text(quickHelp,"Set the role totals you want. Composer fills unspecified slots with suitable builds, then balances utility and melee/ranged coverage.","GameFontHighlightSmall",C.muted); qText:SetPoint("TOPLEFT",70,-43); qText:SetWidth(790); qText:SetJustifyV("TOP")

local exact=CreateFrame("Frame",nil,raidView); exact:SetPoint("TOPLEFT",0,-44); exact:SetPoint("BOTTOMRIGHT",0,0); exact:Hide(); local exactCols={}
for i,role in ipairs(ROLE_ORDER) do
    local col=Panel(exact,C.bg,ROLE_COLOR[role]); col:SetWidth(286); col:SetHeight(330); col:SetPoint("TOPLEFT",(i-1)*300,0); col.rows={}
    local ri=RoleIcon(col,role,32); ri:SetPoint("TOPLEFT",12,-10); local tt=Text(col,D.ROLE_LABEL[role].." BUILDS","GameFontNormal",ROLE_COLOR[role]); tt:SetPoint("LEFT",ri,"RIGHT",8,5); col.cap=Text(col,"","GameFontHighlightSmall",C.muted); col.cap:SetPoint("LEFT",ri,"RIGHT",8,-12)
    col.add=Button(col,"Add Build",86,26); col.add:SetPoint("TOPRIGHT",-10,-12)
    exactCols[role]=col
end
local function RefreshExact()
    for _,role in ipairs(ROLE_ORDER) do
        local col=exactCols[role]; local rows=Aggregated(role); local total=0; for _,r in ipairs(rows) do total=total+(r.count or 1) end; local cap=Remaining(role); col.cap:SetText(total.." exact / "..cap.." bot slots")
        for _,r in ipairs(col.rows) do r:Hide() end
        for i,data in ipairs(rows) do
            if i>6 then break end
            local r=col.rows[i]
            if not r then
                r=Panel(col,C.card2,C.line); r:SetWidth(266); r:SetHeight(38); r.class=Text(r,"","GameFontNormal",C.text); r.class:SetPoint("TOPLEFT",8,-7); r.class:SetWidth(135); r.spec=Text(r,"","GameFontHighlightSmall",C.muted); r.spec:SetPoint("TOPLEFT",8,-23); r.spec:SetWidth(135); r.count=Text(r,"","GameFontNormal",C.text); r.count:SetPoint("RIGHT",-67,0); r.minus=Button(r,"-",24,24); r.minus:SetPoint("RIGHT",-36,0); r.plus=Button(r,"+",24,24); r.plus:SetPoint("RIGHT",-8,0); col.rows[i]=r
            end
            r:ClearAllPoints(); r:SetPoint("TOPLEFT",10,-52-(i-1)*43); r.data=data; local spec=D.GetSpec(data.class,data.spec); r.class:SetText(D.CLASS_LABEL[data.class] or data.class); local cc=ClassColor(data.class); r.class:SetTextColor(cc[1],cc[2],cc[3],1); r.spec:SetText(spec and spec.label or "Any spec"); r.count:SetText("x"..tostring(data.count or 1)); r:Show()
            r.minus:SetScript("OnMouseDown",function() local now=Aggregated(role); if now[i] then now[i].count=(now[i].count or 1)-1; if now[i].count<=0 then table.remove(now,i) end; WriteAggregated(role,now) end end)
            r.plus:SetScript("OnMouseDown",function() local now=Aggregated(role); local n=0; for _,x in ipairs(now) do n=n+(x.count or 1) end; if now[i] and n<Remaining(role) then now[i].count=(now[i].count or 1)+1; WriteAggregated(role,now) end end)
        end
        col.add:SetEnabledState(total<cap); col.add:SetScript("OnMouseDown",function() local rowsNow=Aggregated(role); local classes=ClassesForRole(role,false); local cls=classes[1] and classes[1].value; local specs=SpecsForRole(cls,role,false); if cls and #rowsNow<cap then rowsNow[#rowsNow+1]={class=cls,spec=specs[1] and specs[1].value or "ANY",count=1}; WriteAggregated(role,rowsNow) end end)
    end
end

local raidGroups=Panel(body,C.card,C.line); raidGroups:SetPoint("TOPLEFT",0,-780); raidGroups:SetWidth(936); raidGroups:SetHeight(1); raidGroups:Hide()
local groupCards={}
local function EnsureGroupCard(g)
    if groupCards[g] then return groupCards[g] end
    local card=Panel(body,C.card,C.lineStrong); card:SetWidth(174); card:SetHeight(206); card.rows={}; local gt=Text(card,"GROUP "..g,"GameFontNormalSmall",C.text); gt:SetPoint("TOPLEFT",10,-9); card.count=Text(card,"0/5","GameFontHighlightSmall",C.muted); card.count:SetPoint("TOPRIGHT",-10,-9)
    for i=1,5 do local r=Panel(card,C.bg,C.line); r:SetWidth(154); r:SetHeight(30); r:SetPoint("TOPLEFT",10,-32-(i-1)*33); r.role=RoleIcon(r,"DPS",20); r.role:SetPoint("LEFT",4,0); r.class=ClassIcon(r,"WARRIOR",20); r.class:SetPoint("LEFT",r.role,"RIGHT",3,0); r.name=Text(r,"Empty","GameFontHighlightSmall",C.dim); r.name:SetPoint("TOPLEFT",52,-4); r.name:SetWidth(96); r.build=Text(r,"","GameFontHighlightSmall",C.dim); r.build:SetPoint("TOPLEFT",52,-17); r.build:SetWidth(96); card.rows[i]=r end
    groupCards[g]=card; return card
end
local function RefreshGroups()
    for _,card in ipairs(groupCards) do card:Hide() end
    if GC:GetConfig().mode~="RAID" or not GC.plan.ready then return end
    local groups=math.min(8,math.ceil((GC:GetConfig().size or 25)/5)); local indexes={}
    for g=1,groups do local card=EnsureGroupCard(g); local cols=GC:GetConfig().size==40 and 4 or math.min(5,groups); local row=math.floor((g-1)/cols); local col=(g-1)%cols; local w=GC:GetConfig().size==40 and 216 or 174; card:SetWidth(w); card:ClearAllPoints(); card:SetPoint("TOPLEFT",body, "TOPLEFT", col*(w+12), -568-row*218); card:Show(); for _,r in ipairs(card.rows) do r.name:SetText("Empty"); r.name:SetTextColor(C.dim[1],C.dim[2],C.dim[3],1); r.build:SetText("") end end
    for _,m in ipairs(GC.plan.members or {}) do local g=tonumber(m.subgroup) or 1; indexes[g]=(indexes[g] or 0)+1; local i=indexes[g]; local card=groupCards[g]; local r=card and card.rows[i]; if r then r.role:SetTexture(D.ROLE_ICON[m.role] or D.ROLE_ICON.DPS); SetClassIcon(r.class,m.class); r.name:SetText((m.human and "YOU - " or "")..m.name); local cc=ClassColor(m.class); r.name:SetTextColor(cc[1],cc[2],cc[3],1); r.build:SetText((m.spec or "Any")..(m.needsPreparation and " - PREP" or "")); r.build:SetTextColor((m.needsPreparation and C.gold or C.muted)[1],(m.needsPreparation and C.gold or C.muted)[2],(m.needsPreparation and C.gold or C.muted)[3],1) end end
    for g=1,groups do local card=groupCards[g]; card.count:SetText(tostring(indexes[g] or 0).."/5") end
end

-- Options strip
local opts=Panel(body,C.card,C.line); opts:SetPoint("TOPLEFT",0,-780); opts:SetWidth(936); opts:SetHeight(48)
local tGuild=Toggle(opts,"Prefer guild",function() return GC:GetConfig().options.preferGuild end,function(v) GC:GetConfig().options.preferGuild=v; GC:Touch("Option changed") end); tGuild:SetPoint("LEFT",14,0); tGuild:SetWidth(170)
local tWorld=Toggle(opts,"World / reserve fallback",function() return GC:GetConfig().options.fillWorld end,function(v) GC:GetConfig().options.fillWorld=v; GC:Touch("Option changed") end); tWorld:SetPoint("LEFT",205,0); tWorld:SetWidth(195)
local tUtil=Toggle(opts,"Balance utility",function() return GC:GetConfig().options.balanceUtility end,function(v) GC:GetConfig().options.balanceUtility=v; GC:Touch("Option changed") end); tUtil:SetPoint("LEFT",425,0); tUtil:SetWidth(160)
local tRange=Toggle(opts,"Balance melee / ranged",function() return GC:GetConfig().options.balanceRange end,function(v) GC:GetConfig().options.balanceRange=v; GC:Touch("Option changed") end); tRange:SetPoint("LEFT",610,0); tRange:SetWidth(210)

-- Template browser
local templates=Panel(frame,C.bg,C.lineStrong); templates:SetWidth(920); templates:SetHeight(650); templates:SetPoint("CENTER"); templates:SetFrameStrata("FULLSCREEN_DIALOG"); templates:Hide(); U.templates=templates
local tpTitle=Text(templates,"TEMPLATES","GameFontNormalLarge",C.text); tpTitle:SetPoint("TOPLEFT",20,-18); local tpSub=Text(templates,"Built-in starting points and your saved compositions.","GameFontHighlightSmall",C.muted); tpSub:SetPoint("TOPLEFT",tpTitle,"BOTTOMLEFT",0,-4); local tpClose=Button(templates,"Close  X",100,30,function() templates:Hide() end); tpClose:SetPoint("TOPRIGHT",-16,-15); tpClose:SetAccent(C.red,true)
local tpBuilt=Button(templates,"Built-in",110,30,function() U.templateTab="BUILTIN"; U:RefreshTemplates() end); tpBuilt:SetPoint("TOPLEFT",20,-68); local tpMine=Button(templates,"My Templates",120,30,function() U.templateTab="CUSTOM"; U:RefreshTemplates() end); tpMine:SetPoint("LEFT",tpBuilt,"RIGHT",8,0); U.templateTab="BUILTIN"
local tpScroll=CreateFrame("ScrollFrame",nil,templates); tpScroll:SetPoint("TOPLEFT",20,-110); tpScroll:SetPoint("BOTTOMRIGHT",-20,72); tpScroll:EnableMouseWheel(true); local tpChild=CreateFrame("Frame",nil,tpScroll); tpChild:SetWidth(860); tpChild:SetHeight(450); tpScroll:SetScrollChild(tpChild); tpScroll:SetScript("OnMouseWheel",function(self,d) self:SetVerticalScroll(math.max(0,math.min(self:GetVerticalScrollRange(),self:GetVerticalScroll()-d*45))) end); local tpRows={}
local tpName=CreateFrame("EditBox",nil,templates,"InputBoxTemplate"); tpName:SetWidth(260); tpName:SetHeight(28); tpName:SetAutoFocus(false); tpName:SetPoint("BOTTOMLEFT",20,20); local tpSave=Button(templates,"Save Current",120,30,function() local n=tpName:GetText(); if n and n~="" and GC:SaveProfile(n) then tpName:SetText(""); U.templateTab="CUSTOM"; U:RefreshTemplates() end end); tpSave:SetPoint("LEFT",tpName,"RIGHT",12,0)
function U:RefreshTemplates()
    local names=U.templateTab=="CUSTOM" and P.ListCustom() or P.ListBuiltins(); tpBuilt:SetAccent(C.blue,U.templateTab=="BUILTIN"); tpMine:SetAccent(C.blue,U.templateTab=="CUSTOM")
    for _,r in ipairs(tpRows) do r:Hide() end
    for i,name in ipairs(names) do local r=tpRows[i]; if not r then r=Panel(tpChild,C.card,C.line); r:SetWidth(850); r:SetHeight(54); r.name=Text(r,"","GameFontNormal",C.text); r.name:SetPoint("TOPLEFT",12,-9); r.info=Text(r,"","GameFontHighlightSmall",C.muted); r.info:SetPoint("TOPLEFT",12,-29); r.load=Button(r,"Load",74,28); r.load:SetPoint("RIGHT",-10,0); tpRows[i]=r end; r:ClearAllPoints(); r:SetPoint("TOPLEFT",0,-(i-1)*60); r.name:SetText(name); local p=P.Get(name); r.info:SetText(p and ((p.mode=="RAID" and tostring(p.size).." player raid" or "5 player dungeon").." - "..tostring(p.tanks).."T / "..tostring(p.healers).."H / "..tostring(p.dps).."D") or ""); r.load:SetScript("OnMouseDown",function() GC:LoadProfile(name); templates:Hide() end); r:Show() end; tpChild:SetHeight(math.max(450,#names*60+10))
end
function U:ShowTemplates() CloseMenu(); U:RefreshTemplates(); templates:Show() end

-- Humans and pins modal
local people=Panel(frame,C.bg,C.lineStrong); people:SetWidth(960); people:SetHeight(650); people:SetPoint("CENTER"); people:SetFrameStrata("FULLSCREEN_DIALOG"); people:Hide(); U.people=people
local ppTitle=Text(people,"HUMANS & FAMILIAR COMPANIONS","GameFontNormalLarge",C.text); ppTitle:SetPoint("TOPLEFT",20,-18); local ppSub=Text(people,"Humans are immutable. Pin persistent guild companions only when you want a familiar character.","GameFontHighlightSmall",C.muted); ppSub:SetPoint("TOPLEFT",ppTitle,"BOTTOMLEFT",0,-4); local ppClose=Button(people,"Close  X",100,30,function() people:Hide() end); ppClose:SetPoint("TOPRIGHT",-16,-15); ppClose:SetAccent(C.red,true)
local ppHum=Panel(people,C.card,C.line); ppHum:SetPoint("TOPLEFT",20,-72); ppHum:SetWidth(920); ppHum:SetHeight(230); local ppHT=Text(ppHum,"REAL PLAYERS","GameFontNormal",C.text); ppHT:SetPoint("TOPLEFT",14,-12); local ppHumanRows={}
local ppPins=Panel(people,C.card,C.line); ppPins:SetPoint("TOPLEFT",20,-316); ppPins:SetWidth(920); ppPins:SetHeight(305); local ppPT=Text(ppPins,"PINNED GUILD COMPANIONS","GameFontNormal",C.text); ppPT:SetPoint("TOPLEFT",14,-12); local pinName=CreateFrame("EditBox",nil,ppPins,"InputBoxTemplate"); pinName:SetWidth(220); pinName:SetHeight(28); pinName:SetAutoFocus(false); pinName:SetPoint("TOPLEFT",14,-43); local pinRole="DPS"; local pinRoleDD=Selector(ppPins,130,function() return {{value="TANK",label="Tank"},{value="HEALER",label="Healer"},{value="DPS",label="DPS"}} end,function() return pinRole end,function(v) pinRole=v end,3); pinRoleDD:SetPoint("LEFT",pinName,"RIGHT",8,0); local pinReq=false; local pinReqT=Toggle(ppPins,"Required",function() return pinReq end,function(v) pinReq=v end); pinReqT:SetPoint("LEFT",pinRoleDD,"RIGHT",12,0); pinReqT:SetWidth(100); local pinAdd=Button(ppPins,"Pin Member",110,30,function() local n=pinName:GetText(); if n and n~="" then GC:AddPinnedMember(n,pinRole,pinReq); pinName:SetText(""); U:RefreshPeople() end end); pinAdd:SetPoint("TOPRIGHT",-14,-42); pinAdd:SetAccent(C.blue,true); local ppPinRows={}
function U:RefreshPeople()
    for _,r in ipairs(ppHumanRows) do r:Hide() end; local hs=Humans(); for i,h in ipairs(hs) do if i>5 then break end; local r=ppHumanRows[i]; if not r then r=Panel(ppHum,C.bg,C.line); r:SetWidth(890); r:SetHeight(32); r.icon=ClassIcon(r,"WARRIOR",22); r.icon:SetPoint("LEFT",7,0); r.name=Text(r,"","GameFontNormal",C.text); r.name:SetPoint("LEFT",36,0); r.name:SetWidth(180); r.roles={}; local off=0; for _,role in ipairs(ROLE_ORDER) do local b=Button(r,D.ROLE_LABEL[role],72,24); b:SetPoint("RIGHT",-7-off,0); r.roles[role]=b; off=off+78 end; ppHumanRows[i]=r end; r:ClearAllPoints(); r:SetPoint("TOPLEFT",14,-42-(i-1)*36); SetClassIcon(r.icon,h.class); r.name:SetText((h.isPlayer and "YOU - " or "")..h.name); local sel=GC:GetConfig().humanRoles[h.name]; for _,role in ipairs(ROLE_ORDER) do local b=r.roles[role]; local allowed=ClassCanRole(h.class,role); b:SetEnabledState(allowed); b:SetAccent(ROLE_COLOR[role],sel==role); b:SetScript("OnMouseDown",function() if allowed then GC:SetHumanRole(h.name,role); U:RefreshPeople() end end) end; r:Show() end
    for _,r in ipairs(ppPinRows) do r:Hide() end; for i,p in ipairs(GC:GetConfig().pinned or {}) do if i>5 then break end; local r=ppPinRows[i]; if not r then r=Panel(ppPins,C.bg,C.line); r:SetWidth(890); r:SetHeight(32); r.name=Text(r,"","GameFontNormal",C.text); r.name:SetPoint("LEFT",8,0); r.name:SetWidth(220); r.info=Text(r,"","GameFontHighlightSmall",C.muted); r.info:SetPoint("LEFT",240,0); r.remove=Button(r,"Remove",78,24); r.remove:SetPoint("RIGHT",-7,0); r.remove:SetAccent(C.red,true); ppPinRows[i]=r end; r:ClearAllPoints(); r:SetPoint("TOPLEFT",14,-84-(i-1)*36); r.name:SetText(p.name); r.info:SetText((D.ROLE_LABEL[p.role] or p.role).." - "..(p.required and "Required" or "Preferred")); r.remove:SetScript("OnMouseDown",function() GC:RemovePinnedMember(i); U:RefreshPeople() end); r:Show() end; pinReqT:Refresh(); pinRoleDD:Refresh()
end
function U:ShowPeople() CloseMenu(); U:RefreshPeople(); people:Show() end

-- In-dashboard confirmation, never a Blizzard popup.
local shade=CreateFrame("Frame",nil,frame); shade:SetAllPoints(frame); shade:SetFrameLevel(frame:GetFrameLevel()+30); local shadeTex=Solid(shade,{0,0,0,0.72}); shadeTex:SetAllPoints(shade); shade:Hide(); local confirm=Panel(shade,C.chrome,C.gold); confirm:SetWidth(540); confirm:SetHeight(250); confirm:SetPoint("CENTER"); local cIcon=Icon(confirm,"Interface\\Icons\\INV_Misc_GroupLooking",54); cIcon:SetPoint("TOP",0,-24); local cTitle=Text(confirm,"ASSEMBLE PREPARED ROSTER?","GameFontNormalLarge",C.text); cTitle:SetPoint("TOP",cIcon,"BOTTOM",0,-12); local cText=Text(confirm,"All selected bots are prepared. This now applies the reviewed roster to your live group. Playerbots attach directly; real players receive a normal invite.","GameFontHighlight",C.muted); cText:SetPoint("TOPLEFT",34,-116); cText:SetWidth(472); cText:SetJustifyH("CENTER"); cText:SetJustifyV("TOP"); local cCancel=Button(confirm,"Cancel",120,34,function() shade:Hide() end); cCancel:SetPoint("BOTTOMLEFT",130,20); local cGo=Button(confirm,"Assemble",120,34,function() shade:Hide(); GC:Assemble() end); cGo:SetPoint("BOTTOMRIGHT",-130,20); cGo:SetAccent(C.gold,true)
function U:ShowAssembleConfirm() if not GC.progress or GC.progress.phase~="READY" then GC:Fire("STATUS","Build & Prepare must finish first."); return end; shade:Show() end

local function AdjustRole(role,delta)
    local c=GC:GetConfig(); if role=="DPS" then return end; local key=role=="TANK" and "tanks" or "healers"; local next=math.max(0,(c[key] or 0)+delta); local dps=(c.dps or 0)-delta; if dps<0 then return end; c[key]=next; c.dps=dps; GC:Touch("Role composition changed")
end
roleCards.TANK.minus:SetScript("OnMouseDown",function() AdjustRole("TANK",-1) end); roleCards.TANK.plus:SetScript("OnMouseDown",function() AdjustRole("TANK",1) end); roleCards.HEALER.minus:SetScript("OnMouseDown",function() AdjustRole("HEALER",-1) end); roleCards.HEALER.plus:SetScript("OnMouseDown",function() AdjustRole("HEALER",1) end)

local function RefreshActivity()
    local c=GC:GetConfig(); selectorA:Refresh(); selectorB:Refresh()
    if c.mode=="RAID" then local r=D.GetRaidById(c.activity); activityTitle:SetText(r and r.label or "Raid Setup"); activitySub:SetText((r and r.era or "Raid").." - "..tostring(c.size).." player - "..(c.difficulty=="heroic" and "Heroic" or "Normal")); activityIcon:SetTexture(RAID_ART[c.activity] or "Interface\\Icons\\Achievement_Boss_LichKing"); if ENCOUNTER_READY[c.activity] then SetStatusTexture(badgeIcon,"READY"); badgeText:SetText("Encounter AI certified"); badgeText:SetTextColor(C.green[1],C.green[2],C.green[3],1) else SetStatusTexture(badgeIcon,"BUILDING"); badgeText:SetText("Roster planner only"); badgeText:SetTextColor(C.gold[1],C.gold[2],C.gold[3],1) end
    else local d=D.GetDungeonById(c.activity); activityTitle:SetText(d and d.label or "Dungeon Group"); activitySub:SetText((c.difficulty=="alpha" and "Titan Rune Alpha" or c.difficulty=="beta" and "Titan Rune Beta" or c.difficulty=="gamma" and "Titan Rune Gamma" or c.difficulty=="heroic" and "Heroic" or "Normal").." - 5 player"); activityIcon:SetTexture(DUNGEON_ART[c.activity] or DUNGEON_ART.random); SetStatusTexture(badgeIcon,"READY"); badgeText:SetText("Dungeon Clear supported"); badgeText:SetTextColor(C.green[1],C.green[2],C.green[3],1) end
end
local function RefreshCommand()
    local p=GC.progress or {phase="IDLE",current=0,total=0,detail=""}; local phase=p.phase or "IDLE"; SetStatusTexture(phaseIcon,phase)
    local titles={IDLE="Configure roster",BUILDING="Selecting roster",PREPARING="Preparing bots",READY="Ready to assemble",ASSEMBLING="Assembling group",DONE="Group ready",ERROR="Needs attention"}; phaseTitle:SetText(titles[phase] or phase); local pc=phase=="READY" or phase=="DONE" and C.green or phase=="ERROR" and C.red or phase=="PREPARING" or phase=="ASSEMBLING" and C.gold or C.blue; phaseTitle:SetTextColor(pc[1],pc[2],pc[3],1); phaseDetail:SetText(p.detail or "")
    local humans=#Humans(); local total=GC.plan.ready and (tonumber(GC.plan.summary.total) or #GC.plan.members) or humans; local target=tonumber(GC:GetConfig().size) or 5; count:SetText(tostring(total).." / "..target); countSub:SetText(tostring(humans).." human"..(humans==1 and "" or "s").." - "..math.max(0,target-humans).." bot slots")
    local ratio=(p.total and p.total>0) and math.min(1,p.current/p.total) or (phase=="READY" or phase=="DONE") and 1 or 0; progFill:SetWidth(math.max(1,284*ratio)); local showProgress=phase=="PREPARING" or phase=="ASSEMBLING" or phase=="READY" or phase=="DONE"; progressText:SetText(showProgress and (tostring(p.current or 0).." / "..tostring(p.total or 0).." - "..(p.detail or "")) or "")
    coverageText:SetText(GC.plan.summary and ((GC.plan.summary.utility or "No utility snapshot yet").."\nRanged DPS: "..tostring(GC.plan.summary.ranged or 0).."   Melee DPS: "..tostring(GC.plan.summary.melee or 0)) or "Build a preview to inspect utility coverage.")
    local warnings=GC.plan.warnings or {}; for i=1,3 do warnRows[i]:SetText(warnings[i] or (i==1 and (phase=="READY" and "Prepared roster is ready for review." or phase=="PREPARING" and "Bots are being prepared in the background." or "Choose your role, then Build & Prepare.") or "")) end
    buildBtn:SetEnabledState(HumanReady() and phase~="PREPARING" and phase~="ASSEMBLING"); assembleBtn:SetEnabledState(GC.plan.ready and GC.plan.valid and phase=="READY")
end
local function RefreshRaidQuick()
    local c=GC:GetConfig(); roleCards.TANK.count:SetText(tostring(c.tanks)); roleCards.HEALER.count:SetText(tostring(c.healers)); roleCards.DPS.count:SetText(tostring(c.dps)); for _,role in ipairs(ROLE_ORDER) do roleCards[role].need:SetText(tostring(Remaining(role)).." bot slots after humans") end
end
local function LayoutForMode()
    local raid=GC:GetConfig().mode=="RAID"; if raid then raidView:Show(); dungeonView:Hide(); contentTitle:SetText("RAID COMPOSITION"); contentHint:SetText(U.raidExact and "Exact rows are hard class/spec requirements. Everything else remains Auto." or "Start simple. Composer fills around your humans and balances the unspecified slots."); quick:SetShown(not U.raidExact); exact:SetShown(U.raidExact); modeQuick:SetAccent(C.blue,not U.raidExact); modeExact:SetAccent(C.gold,U.raidExact); opts:ClearAllPoints(); opts:SetPoint("TOPLEFT",0,-780); opts:SetWidth(936); content:SetHeight(320); command:SetHeight(652) else raidView:Hide(); dungeonView:Show(); contentTitle:SetText("FIVE-PLAYER PARTY"); contentHint:SetText("Your human slot is locked. Auto-fill the rest or choose exact bot builds."); content:SetHeight(528) end
end
function U:Refresh()
    if not frame:IsShown() then return end
    local mode=GC:GetConfig().mode; local connected=GC.backendSeen; backend:SetText(connected and "Backend connected" or "Backend checking"); backendDot:SetTexture((connected and C.green or C.dim)[1],(connected and C.green or C.dim)[2],(connected and C.green or C.dim)[3],1); navDungeon:SetAccent(C.blue,mode=="DUNGEON"); navRaid:SetAccent(C.gold,mode=="RAID"); RefreshActivity(); RefreshHumans(); LayoutForMode(); if mode=="DUNGEON" then RefreshDungeonSlots() else RefreshRaidQuick(); RefreshExact() end; tGuild:Refresh(); tWorld:Refresh(); tUtil:Refresh(); tRange:Refresh(); RefreshCommand(); RefreshGroups()
end
function U:ApplyScale() local w,h=UIParent:GetWidth() or 1920,UIParent:GetHeight() or 1080; local s=math.min((w-24)/1500,(h-24)/900); frame:SetScale(math.max(0.68,math.min(1.10,s))) end
function U:Show() CloseMenu(); U:ApplyScale(); frame:Show(); U:Refresh(); GC:RequestAnchors(); GC:RequestStatus() end
function U:Toggle() if frame:IsShown() then frame:Hide(); CloseMenu() else U:Show() end end
GC.Toggle=function() U:Toggle() end

GC:RegisterCallback("CONFIG_CHANGED",function() U:Refresh() end)
GC:RegisterCallback("PLAN_CHANGED",function() U:Refresh() end)
GC:RegisterCallback("PROGRESS_CHANGED",function() U:Refresh() end)
GC:RegisterCallback("HUMANS_CHANGED",function() U:Refresh() end)
GC:RegisterCallback("PROFILES_CHANGED",function() if templates:IsShown() then U:RefreshTemplates() end end)
GC:RegisterCallback("STATUS",function(t) footerText:SetText(tostring(t or "Ready.")); U:Refresh() end)
GC:RegisterCallback("DISPLAY_CHANGED",function() U:ApplyScale() end)
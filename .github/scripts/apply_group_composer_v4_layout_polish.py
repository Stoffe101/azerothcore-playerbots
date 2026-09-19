from pathlib import Path

path = Path('client-addons-src/GroupComposer/DashboardV4.lua')
text = path.read_text(encoding='utf-8')

marker = '''selectorB=Selector(activity,190,function() return GC:GetConfig().mode=="RAID" and RaidDiffItems() or DifficultyItems() end,function() return GC:GetConfig().difficulty end,function(v) GC:GetConfig().difficulty=v; GC:Touch("Difficulty changed") end,7); selectorB:SetPoint("LEFT",selectorA,"RIGHT",10,0)
'''
insert = marker + '''local raidSizeLabel=Text(activity,"RAID SIZE","GameFontNormalSmall",C.muted); raidSizeLabel:SetPoint("TOPLEFT",650,-17)
local raidSizeButtons={}
for i,size in ipairs({10,20,25,40}) do
    local sizeCopy=size
    local b=Button(activity,tostring(size).."-man",72,30,function() GC:SetRaidSize(sizeCopy) end)
    b:SetPoint("TOPLEFT",642+(i-1)*78,-55); raidSizeButtons[size]=b
end
'''
if marker not in text: raise SystemExit('raid size insertion marker drifted')
text = text.replace(marker, insert, 1)

# Replace the old free body-positioned group cards with a bounded scroll viewport.
start = text.index('local raidGroups=Panel(body,C.card,C.line);')
end = text.index('\n-- Options strip', start)
new = '''local groupScroll=CreateFrame("ScrollFrame",nil,body); groupScroll:SetPoint("TOPLEFT",0,-568); groupScroll:SetWidth(936); groupScroll:SetHeight(160); groupScroll:EnableMouseWheel(true); groupScroll:Hide()
local groupChild=CreateFrame("Frame",nil,groupScroll); groupChild:SetWidth(936); groupChild:SetHeight(160); groupScroll:SetScrollChild(groupChild)
groupScroll:SetScript("OnMouseWheel",function(self,d) self:SetVerticalScroll(math.max(0,math.min(self:GetVerticalScrollRange(),self:GetVerticalScroll()-d*55))) end)
local groupCards={}
local function EnsureGroupCard(g)
    if groupCards[g] then return groupCards[g] end
    local card=Panel(groupChild,C.card,C.lineStrong); card:SetWidth(174); card:SetHeight(158); card.rows={}
    local gt=Text(card,"GROUP "..g,"GameFontNormalSmall",C.text); gt:SetPoint("TOPLEFT",8,-7)
    card.count=Text(card,"0/5","GameFontHighlightSmall",C.muted); card.count:SetPoint("TOPRIGHT",-8,-7)
    for i=1,5 do
        local r=Panel(card,C.bg,C.line); r:SetHeight(23); r:SetPoint("TOPLEFT",7,-28-(i-1)*25); r:SetPoint("RIGHT",-7,0)
        r.role=RoleIcon(r,"DPS",15); r.role:SetPoint("LEFT",3,0)
        r.class=ClassIcon(r,"WARRIOR",15); r.class:SetPoint("LEFT",r.role,"RIGHT",2,0)
        r.name=Text(r,"Empty","GameFontHighlightSmall",C.dim); r.name:SetPoint("LEFT",39,0); r.name:SetWidth(72)
        r.build=Text(r,"","GameFontHighlightSmall",C.dim); r.build:SetPoint("RIGHT",-3,0); r.build:SetWidth(55); r.build:SetJustifyH("RIGHT")
        card.rows[i]=r
    end
    groupCards[g]=card; return card
end
local function RefreshGroups()
    for _,card in ipairs(groupCards) do card:Hide() end
    if GC:GetConfig().mode~="RAID" or not GC.plan.ready then groupScroll:Hide(); return end
    groupScroll:Show(); groupScroll:SetVerticalScroll(0)
    local groups=math.min(8,math.ceil((GC:GetConfig().size or 25)/5)); local indexes={}; local cols=GC:GetConfig().size==40 and 4 or math.min(5,groups); local cardW=GC:GetConfig().size==40 and 216 or 174; local cardH=158
    local rows=math.ceil(groups/cols); groupChild:SetHeight(math.max(160,rows*166))
    for g=1,groups do
        local card=EnsureGroupCard(g); local rr=math.floor((g-1)/cols); local cc=(g-1)%cols
        card:SetWidth(cardW); card:ClearAllPoints(); card:SetPoint("TOPLEFT",cc*(cardW+12),-rr*166); card:Show()
        for _,r in ipairs(card.rows) do r.name:SetText("Empty"); r.name:SetTextColor(C.dim[1],C.dim[2],C.dim[3],1); r.build:SetText("") end
    end
    for _,m in ipairs(GC.plan.members or {}) do
        local g=tonumber(m.subgroup) or 1; indexes[g]=(indexes[g] or 0)+1; local i=indexes[g]; local card=groupCards[g]; local r=card and card.rows[i]
        if r then
            r.role:SetTexture(D.ROLE_ICON[m.role] or D.ROLE_ICON.DPS); SetClassIcon(r.class,m.class)
            r.name:SetText((m.human and "YOU " or "")..m.name); local cc=ClassColor(m.class); r.name:SetTextColor(cc[1],cc[2],cc[3],1)
            local build=m.spec or "Any"; if m.needsPreparation then build="Prep" end; r.build:SetText(build); local bc=m.needsPreparation and C.gold or C.muted; r.build:SetTextColor(bc[1],bc[2],bc[3],1)
        end
    end
    for g=1,groups do local card=groupCards[g]; card.count:SetText(tostring(indexes[g] or 0).."/5") end
end
'''
text = text[:start] + new + text[end:]

text = text.replace('local opts=Panel(body,C.card,C.line); opts:SetPoint("TOPLEFT",0,-780); opts:SetWidth(936); opts:SetHeight(48)', 'local opts=Panel(body,C.card,C.line); opts:SetPoint("TOPLEFT",0,-740); opts:SetWidth(936); opts:SetHeight(38)', 1)
text = text.replace('content:SetHeight(320); command:SetHeight(652)', 'content:SetHeight(316); command:SetHeight(652); groupScroll:Show()', 1)
text = text.replace('content:SetHeight(528)', 'content:SetHeight(456); groupScroll:Hide()', 1)
text = text.replace('opts:ClearAllPoints(); opts:SetPoint("TOPLEFT",0,-780); opts:SetWidth(936);', 'opts:ClearAllPoints(); opts:SetPoint("TOPLEFT",0,-740); opts:SetWidth(936);', 1)

# Exact columns fit the bounded composition area. Five unique build families remain visible without overlap.
text = text.replace('col:SetWidth(286); col:SetHeight(330)', 'col:SetWidth(286); col:SetHeight(250)', 1)
text = text.replace('if i>6 then break end', 'if i>5 then break end', 1)
text = text.replace('r:SetHeight(38)', 'r:SetHeight(34)', 1)
text = text.replace('-52-(i-1)*43', '-48-(i-1)*38', 1)

# Raid-size controls exist only in Raid mode and clearly show supported/selected states.
old = '''    if c.mode=="RAID" then local r=D.GetRaidById(c.activity); activityTitle:SetText(r and r.label or "Raid Setup"); activitySub:SetText((r and r.era or "Raid").." - "..tostring(c.size).." player - "..(c.difficulty=="heroic" and "Heroic" or "Normal")); activityIcon:SetTexture(RAID_ART[c.activity] or "Interface\\\\Icons\\\\Achievement_Boss_LichKing"); if ENCOUNTER_READY[c.activity] then'''
new = '''    if c.mode=="RAID" then
        raidSizeLabel:Show(); local selectedRaid=D.GetRaidById(c.activity)
        for size,b in pairs(raidSizeButtons) do local supported=false; if selectedRaid then for _,s in ipairs(selectedRaid.sizes or {}) do if s==size then supported=true end end end; b:Show(); b:SetEnabledState(supported); b:SetAccent(C.gold,supported and c.size==size) end
        local r=selectedRaid; activityTitle:SetText(r and r.label or "Raid Setup"); activitySub:SetText((r and r.era or "Raid").." - "..tostring(c.size).." player - "..(c.difficulty=="heroic" and "Heroic" or "Normal")); activityIcon:SetTexture(RAID_ART[c.activity] or "Interface\\\\Icons\\\\Achievement_Boss_LichKing"); if ENCOUNTER_READY[c.activity] then'''
if old not in text: raise SystemExit('RefreshActivity raid marker drifted')
text = text.replace(old,new,1)
old = '''    else local d=D.GetDungeonById(c.activity); activityTitle:SetText(d and d.label or "Dungeon Group");'''
new = '''    else
        raidSizeLabel:Hide(); for _,b in pairs(raidSizeButtons) do b:Hide() end
        local d=D.GetDungeonById(c.activity); activityTitle:SetText(d and d.label or "Dungeon Group");'''
if old not in text: raise SystemExit('RefreshActivity dungeon marker drifted')
text=text.replace(old,new,1)

path.write_text(text,encoding='utf-8')
print('Dashboard V4 layout polish applied')
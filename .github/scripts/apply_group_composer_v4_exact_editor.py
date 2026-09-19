from pathlib import Path

path = Path('client-addons-src/GroupComposer/DashboardV4.lua')
text = path.read_text(encoding='utf-8')
if 'function U:OpenBuildEditor' in text:
    print('Group Composer V4 exact build editor already applied')
    raise SystemExit(0)

marker = '''local function RefreshExact()\n'''
if marker not in text:
    raise SystemExit('exact editor insertion marker drifted')
editor = r'''local buildEditor=Panel(frame,C.chrome,C.blue); buildEditor:SetFrameStrata("TOOLTIP"); buildEditor:SetWidth(430); buildEditor:SetHeight(270); buildEditor:SetPoint("CENTER"); buildEditor:Hide()
local buildEditorIcon=RoleIcon(buildEditor,"DPS",38); buildEditorIcon:SetPoint("TOPLEFT",18,-18)
local buildEditorTitle=Text(buildEditor,"EDIT BUILD","GameFontNormalLarge",C.text); buildEditorTitle:SetPoint("TOPLEFT",70,-18)
local buildEditorHint=Text(buildEditor,"Choose the exact bot build and how many roster slots should require it.","GameFontHighlightSmall",C.muted); buildEditorHint:SetPoint("TOPLEFT",70,-43); buildEditorHint:SetWidth(332)
local buildClassLabel=Text(buildEditor,"CLASS","GameFontNormalSmall",C.muted); buildClassLabel:SetPoint("TOPLEFT",18,-86)
local buildSpecLabel=Text(buildEditor,"SPECIALIZATION","GameFontNormalSmall",C.muted); buildSpecLabel:SetPoint("TOPLEFT",220,-86)
local buildClassDD,buildSpecDD
buildClassDD=Selector(buildEditor,184,function()
    local e=U.buildEdit; return ClassesForRole(e and e.role or "DPS",false)
end,function() return U.buildEdit and U.buildEdit.class or nil end,function(v)
    if not U.buildEdit then return end
    U.buildEdit.class=v
    local specs=SpecsForRole(v,U.buildEdit.role,false); U.buildEdit.spec=specs[1] and specs[1].value or "ANY"
    buildClassDD:Refresh(); buildSpecDD:Refresh()
end,8); buildClassDD:SetPoint("TOPLEFT",18,-106)
buildSpecDD=Selector(buildEditor,192,function()
    local e=U.buildEdit; return SpecsForRole(e and e.class or "",e and e.role or "DPS",false)
end,function() return U.buildEdit and U.buildEdit.spec or nil end,function(v)
    if U.buildEdit then U.buildEdit.spec=v; buildSpecDD:Refresh() end
end,6); buildSpecDD:SetPoint("TOPLEFT",220,-106)
local buildCountLabel=Text(buildEditor,"COUNT","GameFontNormalSmall",C.muted); buildCountLabel:SetPoint("TOPLEFT",18,-154)
local buildMinus=Button(buildEditor,"-",34,30); buildMinus:SetPoint("TOPLEFT",18,-174)
local buildCount=Text(buildEditor,"1","GameFontNormalLarge",C.text); buildCount:SetPoint("LEFT",buildMinus,"RIGHT",18,0); buildCount:SetWidth(34); buildCount:SetJustifyH("CENTER")
local buildPlus=Button(buildEditor,"+",34,30); buildPlus:SetPoint("LEFT",buildCount,"RIGHT",18,0)
local buildCapacity=Text(buildEditor,"","GameFontHighlightSmall",C.muted); buildCapacity:SetPoint("LEFT",buildPlus,"RIGHT",14,0); buildCapacity:SetWidth(220)
local buildCancel=Button(buildEditor,"Cancel",92,32,function() CloseMenu(); buildEditor:Hide() end); buildCancel:SetPoint("BOTTOMRIGHT",-18,16)
local buildSave=Button(buildEditor,"Save Build",110,32); buildSave:SetPoint("RIGHT",buildCancel,"LEFT",-8,0); buildSave:SetAccent(C.green,true)
local buildRemove=Button(buildEditor,"Remove",92,32); buildRemove:SetPoint("BOTTOMLEFT",18,16); buildRemove:SetAccent(C.red,true)

local function RefreshBuildEditor()
    local e=U.buildEdit; if not e then return end
    buildEditorIcon:SetTexture(D.ROLE_ICON[e.role] or D.ROLE_ICON.DPS)
    local rc=ROLE_COLOR[e.role] or C.blue; SetBorder(buildEditor,rc)
    buildEditorTitle:SetText((e.index and "EDIT " or "ADD ")..string.upper(D.ROLE_LABEL[e.role] or e.role).." BUILD")
    buildCount:SetText(tostring(e.count or 1)); buildCapacity:SetText("Up to "..tostring(e.capacity or 0).." exact bot slot(s) for this role")
    buildRemove:SetEnabledState(e.index~=nil); buildClassDD:Refresh(); buildSpecDD:Refresh()
end

function U:OpenBuildEditor(role,index)
    local rows=Aggregated(role); local current=index and rows[index] or nil
    local classes=ClassesForRole(role,false); local class=current and current.class or (classes[1] and classes[1].value)
    local specs=SpecsForRole(class,role,false); local spec=current and current.spec or (specs[1] and specs[1].value or "ANY")
    U.buildEdit={role=role,index=index,class=class,spec=spec,count=current and current.count or 1,capacity=Remaining(role)}
    CloseMenu(); RefreshBuildEditor(); buildEditor:Show()
end

buildMinus:SetScript("OnMouseDown",function()
    if not U.buildEdit then return end
    U.buildEdit.count=math.max(1,(tonumber(U.buildEdit.count) or 1)-1); RefreshBuildEditor()
end)
buildPlus:SetScript("OnMouseDown",function()
    if not U.buildEdit then return end
    local e=U.buildEdit; local rows=Aggregated(e.role); local used=0
    for i,r in ipairs(rows) do if i~=e.index then used=used+(tonumber(r.count) or 1) end end
    e.count=math.min(math.max(1,e.capacity-used),(tonumber(e.count) or 1)+1); RefreshBuildEditor()
end)
buildSave:SetScript("OnMouseDown",function()
    local e=U.buildEdit; if not e or not e.class or not e.spec then return end
    local rows=Aggregated(e.role); local used=0
    for i,r in ipairs(rows) do if i~=e.index then used=used+(tonumber(r.count) or 1) end end
    local room=math.max(0,e.capacity-used)
    if room<1 then GC:Fire("STATUS","No bot slots remain for another exact "..D.ROLE_LABEL[e.role].." build."); return end
    local value={class=e.class,spec=e.spec,count=math.min(room,math.max(1,tonumber(e.count) or 1))}
    if e.index then rows[e.index]=value else rows[#rows+1]=value end
    WriteAggregated(e.role,rows); buildEditor:Hide()
end)
buildRemove:SetScript("OnMouseDown",function()
    local e=U.buildEdit; if not e or not e.index then return end
    local rows=Aggregated(e.role); if rows[e.index] then table.remove(rows,e.index); WriteAggregated(e.role,rows) end; buildEditor:Hide()
end)

'''
text = text.replace(marker, editor + marker, 1)

old = '''                r=Panel(col,C.card2,C.line); r:SetWidth(266); r:SetHeight(34); r.class=Text(r,"","GameFontNormal",C.text); r.class:SetPoint("TOPLEFT",8,-7); r.class:SetWidth(135); r.spec=Text(r,"","GameFontHighlightSmall",C.muted); r.spec:SetPoint("TOPLEFT",8,-23); r.spec:SetWidth(135); r.count=Text(r,"","GameFontNormal",C.text); r.count:SetPoint("RIGHT",-67,0); r.minus=Button(r,"-",24,24); r.minus:SetPoint("RIGHT",-36,0); r.plus=Button(r,"+",24,24); r.plus:SetPoint("RIGHT",-8,0); col.rows[i]=r\n'''
new = '''                r=Panel(col,C.card2,C.line); r:SetWidth(266); r:SetHeight(34); r.class=Text(r,"","GameFontNormal",C.text); r.class:SetPoint("TOPLEFT",8,-7); r.class:SetWidth(130); r.spec=Text(r,"","GameFontHighlightSmall",C.muted); r.spec:SetPoint("TOPLEFT",8,-23); r.spec:SetWidth(130); r.count=Text(r,"","GameFontNormal",C.text); r.count:SetPoint("RIGHT",-66,0); r.edit=Button(r,"Edit",50,24); r.edit:SetPoint("RIGHT",-8,0); col.rows[i]=r\n'''
if old not in text:
    raise SystemExit('exact row control marker drifted')
text = text.replace(old, new, 1)

old = '''            r.minus:SetScript("OnMouseDown",function() local now=Aggregated(roleKey); if now[i] then now[i].count=(now[i].count or 1)-1; if now[i].count<=0 then table.remove(now,i) end; WriteAggregated(roleKey,now) end end)\n            r.plus:SetScript("OnMouseDown",function() local now=Aggregated(roleKey); local n=0; for _,x in ipairs(now) do n=n+(x.count or 1) end; if now[i] and n<Remaining(roleKey) then now[i].count=(now[i].count or 1)+1; WriteAggregated(roleKey,now) end end)\n'''
new = '''            local editIndex=i; r.edit:SetScript("OnMouseDown",function() U:OpenBuildEditor(roleKey,editIndex) end)\n'''
if old not in text:
    raise SystemExit('exact row callbacks marker drifted')
text = text.replace(old, new, 1)

old = '''        col.add:SetEnabledState(total<cap); col.add:SetScript("OnMouseDown",function() local rowsNow=Aggregated(roleKey); local classes=ClassesForRole(roleKey,false); local cls=classes[1] and classes[1].value; local specs=SpecsForRole(cls,roleKey,false); if cls and #rowsNow<cap then rowsNow[#rowsNow+1]={class=cls,spec=specs[1] and specs[1].value or "ANY",count=1}; WriteAggregated(roleKey,rowsNow) end end)\n'''
new = '''        col.add:SetEnabledState(total<cap); col.add:SetScript("OnMouseDown",function() if total<cap then U:OpenBuildEditor(roleKey,nil) end end)\n'''
if old not in text:
    raise SystemExit('exact add callback marker drifted')
text = text.replace(old, new, 1)

path.write_text(text, encoding='utf-8')
print('Group Composer V4 exact build editor applied')

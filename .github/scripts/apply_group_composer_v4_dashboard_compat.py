from pathlib import Path

path = Path('client-addons-src/GroupComposer/DashboardV4.lua')
text = path.read_text(encoding='utf-8')

text = text.replace('GameFontNormalHuge', 'GameFontNormalLarge')
text = text.replace('Icon(confirm,"Interface\\\\Icons\\\\INV_Misc_GroupLooking",54)', 'Icon(confirm,"Interface\\\\Icons\\\\Achievement_General_StayClassy",54)')

old = '''                row:SetScript("OnMouseDown",function() if setValue then setValue(item.value) end; CloseMenu(); b:Refresh() end)
'''
new = '''                local valueCopy = item.value
                row:SetScript("OnMouseDown",function() if setValue then setValue(valueCopy) end; CloseMenu(); b:Refresh() end)
'''
if old not in text: raise SystemExit('selector closure marker drifted')
text = text.replace(old, new, 1)

old = '''    local raid=GC:GetConfig().mode=="RAID"; if raid then raidView:Show(); dungeonView:Hide(); contentTitle:SetText("RAID COMPOSITION"); contentHint:SetText(U.raidExact and "Exact rows are hard class/spec requirements. Everything else remains Auto." or "Start simple. Composer fills around your humans and balances the unspecified slots."); quick:SetShown(not U.raidExact); exact:SetShown(U.raidExact); modeQuick:SetAccent(C.blue,not U.raidExact); modeExact:SetAccent(C.gold,U.raidExact); opts:ClearAllPoints(); opts:SetPoint("TOPLEFT",0,-780); opts:SetWidth(936); content:SetHeight(320); command:SetHeight(652) else raidView:Hide(); dungeonView:Show(); contentTitle:SetText("FIVE-PLAYER PARTY"); contentHint:SetText("Your human slot is locked. Auto-fill the rest or choose exact bot builds."); content:SetHeight(528) end
'''
new = '''    local raid=GC:GetConfig().mode=="RAID"
    if raid then
        raidView:Show(); dungeonView:Hide(); contentTitle:SetText("RAID COMPOSITION")
        contentHint:SetText(U.raidExact and "Exact rows are hard class/spec requirements. Everything else remains Auto." or "Start simple. Composer fills around your humans and balances the unspecified slots.")
        if U.raidExact then quick:Hide(); exact:Show() else quick:Show(); exact:Hide() end
        modeQuick:SetAccent(C.blue,not U.raidExact); modeExact:SetAccent(C.gold,U.raidExact)
        opts:ClearAllPoints(); opts:SetPoint("TOPLEFT",0,-780); opts:SetWidth(936); content:SetHeight(320); command:SetHeight(652)
    else
        raidView:Hide(); dungeonView:Show(); contentTitle:SetText("FIVE-PLAYER PARTY")
        contentHint:SetText("Your human slot is locked. Auto-fill the rest or choose exact bot builds."); content:SetHeight(528)
    end
'''
if old not in text: raise SystemExit('SetShown/layout marker drifted')
text = text.replace(old, new, 1)

old = '''    local p=GC.progress or {phase="IDLE",current=0,total=0,detail=""}; local phase=p.phase or "IDLE"; SetStatusTexture(phaseIcon,phase)
    local titles={IDLE="Configure roster",BUILDING="Selecting roster",PREPARING="Preparing bots",READY="Ready to assemble",ASSEMBLING="Assembling group",DONE="Group ready",ERROR="Needs attention"}; phaseTitle:SetText(titles[phase] or phase); local pc=phase=="READY" or phase=="DONE" and C.green or phase=="ERROR" and C.red or phase=="PREPARING" or phase=="ASSEMBLING" and C.gold or C.blue; phaseTitle:SetTextColor(pc[1],pc[2],pc[3],1); phaseDetail:SetText(p.detail or "")
'''
new = '''    local p=GC.progress or {phase="IDLE",current=0,total=0,detail=""}; local phase=p.phase or "IDLE"; SetStatusTexture(phaseIcon,phase)
    local titles={IDLE="Configure roster",BUILDING="Selecting roster",PREPARING="Preparing bots",READY="Ready to assemble",ASSEMBLING="Assembling group",DONE="Group ready",ERROR="Needs attention"}; phaseTitle:SetText(titles[phase] or phase)
    local pc=C.blue
    if phase=="READY" or phase=="DONE" then pc=C.green elseif phase=="ERROR" then pc=C.red elseif phase=="PREPARING" or phase=="ASSEMBLING" then pc=C.gold end
    phaseTitle:SetTextColor(pc[1],pc[2],pc[3],1); phaseDetail:SetText(p.detail or "")
'''
if old not in text: raise SystemExit('phase color marker drifted')
text = text.replace(old, new, 1)

# Capture Lua 5.1 loop variables used by callbacks.
text = text.replace('''    for _,role in ipairs(ROLE_ORDER) do
        local col=exactCols[role]; local rows=Aggregated(role); local total=0;''','''    for _,role in ipairs(ROLE_ORDER) do
        local roleKey=role
        local col=exactCols[roleKey]; local rows=Aggregated(roleKey); local total=0;''',1)
text = text.replace('local cap=Remaining(role); col.cap:SetText', 'local cap=Remaining(roleKey); col.cap:SetText', 1)
text = text.replace('local now=Aggregated(role); if now[i]', 'local now=Aggregated(roleKey); if now[i]', 1)
text = text.replace('WriteAggregated(role,now) end end)', 'WriteAggregated(roleKey,now) end end)', 1)
text = text.replace('local now=Aggregated(role); local n=0;', 'local now=Aggregated(roleKey); local n=0;', 1)
text = text.replace('if now[i] and n<Remaining(role) then', 'if now[i] and n<Remaining(roleKey) then', 1)
text = text.replace('WriteAggregated(role,now) end end)', 'WriteAggregated(roleKey,now) end end)', 1)
text = text.replace('local rowsNow=Aggregated(role); local classes=ClassesForRole(role,false);', 'local rowsNow=Aggregated(roleKey); local classes=ClassesForRole(roleKey,false);', 1)
text = text.replace('local specs=SpecsForRole(cls,role,false);', 'local specs=SpecsForRole(cls,roleKey,false);', 1)
text = text.replace('WriteAggregated(role,rowsNow) end end)', 'WriteAggregated(roleKey,rowsNow) end end)', 1)

text = text.replace('''    for i,name in ipairs(names) do local r=tpRows[i];''','''    for i,name in ipairs(names) do local nameCopy=name; local r=tpRows[i];''',1)
text = text.replace('GC:LoadProfile(name); templates:Hide()', 'GC:LoadProfile(nameCopy); templates:Hide()', 1)

# Human role callbacks in the modal need stable copies under Lua 5.1.
old = '''for _,role in ipairs(ROLE_ORDER) do local b=r.roles[role]; local allowed=ClassCanRole(h.class,role); b:SetEnabledState(allowed); b:SetAccent(ROLE_COLOR[role],sel==role); b:SetScript("OnMouseDown",function() if allowed then GC:SetHumanRole(h.name,role); U:RefreshPeople() end end) end; r:Show() end
'''
new = '''local humanName=h.name; local humanClass=h.class
        for _,role in ipairs(ROLE_ORDER) do local roleKey=role; local b=r.roles[roleKey]; local allowed=ClassCanRole(humanClass,roleKey); b:SetEnabledState(allowed); b:SetAccent(ROLE_COLOR[roleKey],sel==roleKey); b:SetScript("OnMouseDown",function() if allowed then GC:SetHumanRole(humanName,roleKey); U:RefreshPeople() end end) end; r:Show() end
'''
if old not in text: raise SystemExit('people human closure marker drifted')
text = text.replace(old, new, 1)
text = text.replace('r.remove:SetScript("OnMouseDown",function() GC:RemovePinnedMember(i); U:RefreshPeople() end)', 'local pinIndex=i; r.remove:SetScript("OnMouseDown",function() GC:RemovePinnedMember(pinIndex); U:RefreshPeople() end)', 1)

# Main human card callbacks also need stable values.
old = '''            for _,role in ipairs(ROLE_ORDER) do local rb=row.roles[role]; local allowed=ClassCanRole(h.class,role); rb:SetEnabledState(allowed); rb:SetAccent(ROLE_COLOR[role],selected==role); rb:SetScript("OnMouseDown",function() if allowed then GC:SetHumanRole(h.name,role) end end); AddTooltip(rb,D.ROLE_LABEL[role],allowed and "Lock this real player to this role." or "This class cannot perform this role in WotLK.") end
'''
new = '''            local humanName=h.name; local humanClass=h.class
            for _,role in ipairs(ROLE_ORDER) do local roleKey=role; local rb=row.roles[roleKey]; local allowed=ClassCanRole(humanClass,roleKey); rb:SetEnabledState(allowed); rb:SetAccent(ROLE_COLOR[roleKey],selected==roleKey); rb:SetScript("OnMouseDown",function() if allowed then GC:SetHumanRole(humanName,roleKey) end end); AddTooltip(rb,D.ROLE_LABEL[roleKey],allowed and "Lock this real player to this role." or "This class cannot perform this role in WotLK.") end
'''
if old not in text: raise SystemExit('main human closure marker drifted')
text = text.replace(old, new, 1)

# Fixed group rows use a shorter font-safe status label and never free-flow text.
text = text.replace('(m.spec or "Any")..(m.needsPreparation and " - PREP" or "")', '(m.spec or "Any")..(m.needsPreparation and " / prep" or "")')

# Hard reject post-Wrath APIs that caused earlier V3 client failures.
if 'SetShown(' in text:
    raise SystemExit('Dashboard V4 still contains SetShown, unavailable on the 3.3.5 client')

path.write_text(text, encoding='utf-8')
print('Dashboard V4 Wrath compatibility fixes applied')
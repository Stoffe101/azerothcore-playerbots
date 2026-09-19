from pathlib import Path

cmd = Path('modules/mod-raid-roster/src/GroupComposerCommand.cpp')
c = cmd.read_text(encoding='utf-8')
old = '''                    else\n                    {\n                        SendProgress(master, "ERROR", uint32(plan.members.size()), uint32(plan.members.size()), travelError);\n                        SendProtocol(master, "ERROR", travelError);\n                    }\n'''
new = '''                    else\n                    {\n                        // The roster itself is already committed and valid. Surface the travel\n                        // blocker as an error/warning first, then return the plan to READY so the\n                        // user can clear a temporary blocker (combat, teleport state, etc.) and\n                        // retry entry without rebuilding or replacing a perfectly good roster.\n                        SendProtocol(master, "ERROR", travelError);\n                        SendProgress(master, "READY", uint32(plan.members.size()), uint32(plan.members.size()),\n                            "Group is assembled. Clear the travel blocker and press Enter Activity to retry.");\n                    }\n'''
if old in c:
    c = c.replace(old, new, 1)
elif 'press Enter Activity to retry' not in c:
    raise SystemExit('travel retry server marker drifted')
cmd.write_text(c, encoding='utf-8')

# Dynamic confirmation + visible automatic travel behavior in Dashboard V4.
dash = Path('client-addons-src/GroupComposer/DashboardV4.lua')
d = dash.read_text(encoding='utf-8')
old = '''local cText=Text(confirm,"All selected bots are prepared. This now applies the reviewed roster to your live group. Playerbots attach directly; real players receive a normal invite.","GameFontHighlight",C.muted); cText:SetPoint("TOPLEFT",34,-116); cText:SetWidth(472); cText:SetJustifyH("CENTER"); cText:SetJustifyV("TOP"); local cCancel=Button(confirm,"Cancel",120,34,function() shade:Hide() end); cCancel:SetPoint("BOTTOMLEFT",130,20); local cGo=Button(confirm,"Assemble",120,34,function() shade:Hide(); GC:Assemble() end); cGo:SetPoint("BOTTOMRIGHT",-130,20); cGo:SetAccent(C.gold,true)\nfunction U:ShowAssembleConfirm() if not GC.progress or GC.progress.phase~="READY" then GC:Fire("STATUS","Build & Prepare must finish first."); return end; shade:Show() end\n'''
new = '''local cText=Text(confirm,"All selected bots are prepared.","GameFontHighlight",C.muted); cText:SetPoint("TOPLEFT",34,-116); cText:SetWidth(472); cText:SetJustifyH("CENTER"); cText:SetJustifyV("TOP"); local cCancel=Button(confirm,"Cancel",120,34,function() shade:Hide() end); cCancel:SetPoint("BOTTOMLEFT",130,20); local cGo=Button(confirm,"Assemble",120,34,function() shade:Hide(); GC:Assemble() end); cGo:SetPoint("BOTTOMRIGHT",-130,20); cGo:SetAccent(C.gold,true)\nfunction U:ShowAssembleConfirm()\n    if not GC.progress or GC.progress.phase~="READY" then GC:Fire("STATUS","Build & Prepare must finish first."); return end\n    local c=GC:GetConfig(); local retry=string.find(GC.progress.detail or "","Enter Activity",1,true)~=nil\n    local activity=c.mode=="RAID" and D.GetRaidById(c.activity) or D.GetDungeonById(c.activity); local label=activity and activity.label or "the selected activity"\n    if retry then\n        cTitle:SetText("ENTER SELECTED ACTIVITY?"); cGo:SetText("Enter Activity")\n        cText:SetText("The reviewed roster is already assembled. This retries automatic travel for the complete group into "..label..". No roster rebuild is performed.")\n    elseif c.mode=="DUNGEON" and c.activity=="random" then\n        cTitle:SetText("ASSEMBLE PREPARED ROSTER?"); cGo:SetText("Assemble")\n        cText:SetText("This applies the reviewed roster to your live party. Playerbots attach directly; real players receive a normal invite. Dungeon Finder chooses the destination after assembly.")\n    else\n        cTitle:SetText("ASSEMBLE & ENTER?"); cGo:SetText("Assemble")\n        cText:SetText("This applies the reviewed roster to your live group, then automatically moves the complete group into "..label.." after validation.")\n    end\n    shade:Show()\nend\n'''
if old in d:
    d = d.replace(old, new, 1)
elif 'ENTER SELECTED ACTIVITY?' not in d:
    raise SystemExit('dynamic assemble confirmation marker drifted')

# Make automatic travel discoverable before the user commits anything.
old = '''        local r=selectedRaid; activityTitle:SetText(r and r.label or "Raid Setup"); activitySub:SetText((r and r.era or "Raid").." - "..tostring(c.size).." player - "..(c.difficulty=="heroic" and "Heroic" or "Normal")); activityIcon:SetTexture(RAID_ART[c.activity] or "Interface\\\\Icons\\\\Achievement_Boss_LichKing"); if ENCOUNTER_READY[c.activity] then'''
new = '''        local r=selectedRaid; activityTitle:SetText(r and r.label or "Raid Setup"); activitySub:SetText((r and r.era or "Raid").." - "..tostring(c.size).." player - "..(c.difficulty=="heroic" and "Heroic" or "Normal").." | Auto travel after Assemble"); activityIcon:SetTexture(RAID_ART[c.activity] or "Interface\\\\Icons\\\\Achievement_Boss_LichKing"); if ENCOUNTER_READY[c.activity] then'''
if old in d:
    d = d.replace(old, new, 1)
elif 'player - "..(c.difficulty=="heroic" and "Heroic" or "Normal").." | Auto travel after Assemble"' not in d:
    raise SystemExit('raid auto-travel subtitle marker drifted')

old = '''        local d=D.GetDungeonById(c.activity); activityTitle:SetText(d and d.label or "Dungeon Group"); activitySub:SetText((c.difficulty=="alpha" and "Titan Rune Alpha" or c.difficulty=="beta" and "Titan Rune Beta" or c.difficulty=="gamma" and "Titan Rune Gamma" or c.difficulty=="heroic" and "Heroic" or "Normal").." - 5 player"); activityIcon:SetTexture(DUNGEON_ART[c.activity] or DUNGEON_ART.random); SetStatusTexture(badgeIcon,"READY"); badgeText:SetText("Dungeon Clear supported"); badgeText:SetTextColor(C.green[1],C.green[2],C.green[3],1) end\n'''
new = '''        local d=D.GetDungeonById(c.activity); activityTitle:SetText(d and d.label or "Dungeon Group"); local travelHint=c.activity=="random" and " | Dungeon Finder selects destination" or " | Auto travel after Assemble"; activitySub:SetText((c.difficulty=="alpha" and "Titan Rune Alpha" or c.difficulty=="beta" and "Titan Rune Beta" or c.difficulty=="gamma" and "Titan Rune Gamma" or c.difficulty=="heroic" and "Heroic" or "Normal").." - 5 player"..travelHint); activityIcon:SetTexture(DUNGEON_ART[c.activity] or DUNGEON_ART.random); SetStatusTexture(badgeIcon,"READY"); badgeText:SetText("Dungeon Clear supported"); badgeText:SetTextColor(C.green[1],C.green[2],C.green[3],1) end\n'''
if old in d:
    d = d.replace(old, new, 1)
elif 'Dungeon Finder selects destination' not in d:
    raise SystemExit('dungeon auto-travel subtitle marker drifted')

# READY after a travel-only failure becomes a visibly different commit action.
old = '''    buildBtn:SetEnabledState(HumanReady() and phase~="PREPARING" and phase~="ASSEMBLING"); assembleBtn:SetEnabledState(GC.plan.ready and GC.plan.valid and phase=="READY")\n'''
new = '''    local travelRetry=phase=="READY" and string.find(p.detail or "","Enter Activity",1,true)~=nil\n    assembleBtn:SetText(travelRetry and "Enter Activity" or "Assemble")\n    if travelRetry then phaseTitle:SetText("Ready to enter activity") end\n    buildBtn:SetEnabledState(HumanReady() and phase~="PREPARING" and phase~="ASSEMBLING" and phase~="TRAVEL"); assembleBtn:SetEnabledState(GC.plan.ready and GC.plan.valid and phase=="READY")\n'''
if old in d:
    d = d.replace(old, new, 1)
elif 'Ready to enter activity' not in d:
    raise SystemExit('travel retry action marker drifted')

dash.write_text(d, encoding='utf-8')

# Extend source contracts so a future refactor cannot turn a temporary travel block into a forced
# roster rebuild or hide automatic travel from the client.
test = Path('client-addons-src/GroupComposer/tests/test_server_contract.py')
s = test.read_text(encoding='utf-8')
contract = r'''

# A travel-only failure happens after the exact roster is already live. It must preserve that valid
# plan and return the UI to READY after surfacing the blocker, so combat/teleport-state failures are
# retryable without rebuilding 5/25/40 members.
travel_update = section(SERVER, "if (ApplyArrangement(master, plan, arrangementError))", "else if (plan.assembleElapsed > 45000)")
assert 'SendProtocol(master, "ERROR", travelError);' in travel_update
assert 'SendProgress(master, "READY"' in travel_update
assert travel_update.index('SendProtocol(master, "ERROR", travelError);') < travel_update.index('SendProgress(master, "READY"'), (
    "Travel blocker must be recorded before the valid assembled roster returns to READY"
)
assert 'press Enter Activity to retry' in travel_update
assert 'Ready to enter activity' in DASHBOARD and 'ENTER SELECTED ACTIVITY?' in DASHBOARD
assert 'Auto travel after Assemble' in DASHBOARD and 'Dungeon Finder selects destination' in DASHBOARD
'''
if '# A travel-only failure happens after the exact roster is already live.' not in s:
    s += contract
test.write_text(s, encoding='utf-8')

print('Group Composer V4 travel retry UX applied')

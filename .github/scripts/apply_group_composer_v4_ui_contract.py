from pathlib import Path

path=Path('client-addons-src/GroupComposer/tests/test_server_contract.py')
text=path.read_text(encoding='utf-8')

text=text.replace('POLISH = (ROOT / "client-addons-src/GroupComposer/Polish.lua").read_text(encoding="utf-8")\nUI = (ROOT / "client-addons-src/GroupComposer/UI.lua").read_text(encoding="utf-8")\nADVANCED = (ROOT / "client-addons-src/GroupComposer/Advanced.lua").read_text(encoding="utf-8")\n', 'RUNTIME = (ROOT / "client-addons-src/GroupComposer/RuntimeGuards.lua").read_text(encoding="utf-8")\nTOC = (ROOT / "client-addons-src/GroupComposer/GroupComposer.toc").read_text(encoding="utf-8")\n',1)
text=text.replace('DASHBOARD = (ROOT / "client-addons-src/GroupComposer/DashboardV3.lua").read_text(encoding="utf-8")', 'DASHBOARD = (ROOT / "client-addons-src/GroupComposer/DashboardV4.lua").read_text(encoding="utf-8")',1)

start=text.index('# Client safety contracts.')
end=text.index('\n# Safety invariants.',start)
new='''# Client safety and architecture contracts. Dashboard V4 owns presentation while RuntimeGuards owns
# protocol-only safety. No unloaded legacy UI file may be required for live behavior.
assert 'DashboardV4.lua' in TOC and 'DashboardV3.lua' not in TOC, "The live addon must load only Dashboard V4"
assert '## Version: 0.5.0' in TOC and '## X-UI-Shell: DashboardV4' in TOC
assert 'if GC.pendingCommand == "status" then GC.pendingCommand = nil end' in RUNTIME, (
    "Passive status synchronization can leave the composer permanently action-locked"
)
assert 'GROUPCOMPOSER_CONFIRM_ASSEMBLY' not in RUNTIME and 'StaticPopup_Show' not in RUNTIME, (
    "V4 must not use the legacy Blizzard assembly popup"
)
assert 'function U:ShowAssembleConfirm()' in DASHBOARD and 'GC:Assemble()' in DASHBOARD, (
    "Dashboard V4 lost its in-window assembly confirmation boundary"
)
assert 'SetShown(' not in DASHBOARD, "Dashboard V4 uses a post-Wrath frame API"
assert 'UI-CheckBox-Check' in DASHBOARD, "V4 status/toggles should use real textures instead of unsupported Unicode glyphs"
assert 'maxVisible' in DASHBOARD and 'EnableMouseWheel(true)' in DASHBOARD, (
    "V4 selectors/templates must remain bounded and scrollable"
)
assert 'Build & Prepare' in DASHBOARD and 'PROGRESS_CHANGED' in DASHBOARD, (
    "V4 must expose preparation as a visible first-class phase"
)
'''
text=text[:start]+new+text[end:]

text=text.replace("assert 'local function RemainingBotSlots(role)' in DASHBOARD\nassert 'RemainingBotSlots(\"TANK\")' in DASHBOARD and 'RemainingBotSlots(\"HEALER\")' in DASHBOARD\n", "assert 'local function Remaining(role)' in DASHBOARD\nassert 'Remaining(\"TANK\")' in DASHBOARD or 'Remaining(role)' in DASHBOARD\n",1)
text=text.replace("assert 'ipairs({10, 20, 25, 40})' in DASHBOARD, \"Dashboard no longer exposes all supported raid-size families\"", "assert 'ipairs({10,20,25,40})' in DASHBOARD, \"Dashboard no longer exposes all supported raid-size families\"",1)
text=text.replace("assert 'for _, r in ipairs(D.RAIDS or {}) do' in DASHBOARD, \"Dashboard hard-filters the full raid planner catalog\"", "assert 'for _,r in ipairs(D.RAIDS)' in DASHBOARD, \"Dashboard hard-filters the full raid planner catalog\"",1)
text=text.replace("assert 'ROSTER ONLY' in DASHBOARD and 'encounter AI not certified' in DASHBOARD, (\n    \"Planner-only raids must remain visibly distinct from certified encounter automation\"\n)", "assert 'Roster planner only' in DASHBOARD and 'Encounter AI certified' in DASHBOARD, (\n    \"Planner-only raids must remain visibly distinct from certified encounter automation\"\n)",1)
text=text.replace("assert 'local READY_RAIDS = {' not in DASHBOARD, \"Legacy hard-coded raid whitelist still restricts Group Composer\"", "assert 'local READY_RAIDS = {' not in DASHBOARD, \"Legacy hard-coded raid whitelist still restricts Group Composer\"",1)

path.write_text(text,encoding='utf-8')
print('Dashboard V4 UI contract updated')
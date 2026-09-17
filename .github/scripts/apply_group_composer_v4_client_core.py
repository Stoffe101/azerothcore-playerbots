from pathlib import Path

core = Path('client-addons-src/GroupComposer/Core.lua')
text = core.read_text(encoding='utf-8')
text = text.replace(
    'GC.plan = { members = {}, warnings = {}, valid = false, ready = false, summary = {} }\nGC.callbacks = {}',
    'GC.plan = { members = {}, warnings = {}, valid = false, ready = false, summary = {} }\nGC.progress = { phase = "IDLE", current = 0, total = 0, detail = "Configure a roster to begin." }\nGC.callbacks = {}',
    1,
)
old = '''function GC:ResetPlan(reason)
    GC.plan = {
        members = {}, warnings = {}, valid = false, ready = false,
        summary = {}, reason = reason,
    }
    GC:Fire("PLAN_CHANGED", GC.plan)
end
'''
new = '''function GC:SetProgress(phase, current, total, detail)
    GC.progress = {
        phase = phase or "IDLE",
        current = tonumber(current) or 0,
        total = tonumber(total) or 0,
        detail = detail or "",
    }
    GC:Fire("PROGRESS_CHANGED", GC.progress)
end

function GC:AddWarningOnce(value)
    value = tostring(value or "Unknown warning")
    for _, existing in ipairs(GC.plan.warnings or {}) do
        if existing == value then return end
    end
    GC.plan.warnings[#GC.plan.warnings + 1] = value
end

function GC:ResetPlan(reason)
    GC.plan = {
        members = {}, warnings = {}, valid = false, ready = false,
        summary = {}, reason = reason,
    }
    GC:SetProgress("IDLE", 0, 0, reason or "Configure a roster to begin.")
    GC:Fire("PLAN_CHANGED", GC.plan)
end
'''
if old not in text: raise SystemExit('ResetPlan block drifted')
text = text.replace(old, new, 1)
text = text.replace('GC:Fire("STATUS", "Building roster preview...")', 'GC:SetProgress("BUILDING", 0, 0, "Selecting a valid roster...")\n    GC:Fire("STATUS", "Building and preparing roster...")', 1)
old = '''function GC:Assemble()
    if not GC.plan.ready or not GC.plan.valid then GC:Fire("STATUS", "Find and validate a roster before assembling it."); return false end
    GC:SendServer("assemble", "Assembling roster...")
    return true
end
'''
new = '''function GC:Assemble()
    if not GC.plan.ready or not GC.plan.valid then GC:Fire("STATUS", "Build and validate a roster before assembling it."); return false end
    if not GC.progress or GC.progress.phase ~= "READY" then
        GC:Fire("STATUS", "Selected bots are still being prepared. Assemble unlocks automatically when they are ready.")
        return false
    end
    GC:SetProgress("ASSEMBLING", 1, tonumber(GC.plan.summary.total) or #GC.plan.members, "Committing prepared roster to the live group...")
    GC:SendServer("assemble", "Assembling prepared roster...")
    return true
end
'''
if old not in text: raise SystemExit('Assemble block drifted')
text = text.replace(old, new, 1)
text = text.replace('''    if kind == "RESET" then
        GC:ResetPlan("Server reset")
''','''    if kind == "RESET" then
        GC:ResetPlan("Server reset")
''',1)
# Insert PROGRESS handling before STATUS.
old = '''    elseif kind == "STATUS" then
        GC:Fire("STATUS", fields[2] or "Server ready")
'''
new = '''    elseif kind == "PROGRESS" then
        local phase = fields[2] or "IDLE"
        local current = ParseNumber(fields[3], 0)
        local total = ParseNumber(fields[4], 0)
        local detail = fields[5] or ""
        GC:SetProgress(phase, current, total, detail)
        if phase == "READY" and GC.pendingCommand == "find" then GC.pendingCommand = nil end
        if phase == "ERROR" then GC.pendingCommand = nil end
    elseif kind == "STATUS" then
        GC:Fire("STATUS", fields[2] or "Server ready")
'''
if old not in text: raise SystemExit('STATUS protocol marker drifted')
text = text.replace(old, new, 1)
text = text.replace('GC.plan.warnings[#GC.plan.warnings + 1] = fields[2] or "Unknown warning"', 'GC:AddWarningOnce(fields[2] or "Unknown warning")', 1)
text = text.replace('''        GC.pendingCommand = nil
        GC:Fire("STATUS", GC.plan.valid and "Roster ready for review." or "Roster needs attention.")
''','''        if not GC.plan.valid then GC.pendingCommand = nil end
        GC:Fire("STATUS", GC.plan.valid and "Roster selected. Preparing selected bots..." or "Roster needs attention.")
''',1)
text = text.replace('''        GC.pendingCommand = nil
        GC:Fire("STATUS", fields[2] or "Done.")
''','''        GC.pendingCommand = nil
        if completed == "assemble" then
            GC:SetProgress("DONE", tonumber(GC.plan.summary.total) or #GC.plan.members, tonumber(GC.plan.summary.total) or #GC.plan.members, fields[2] or "Roster ready.")
        end
        GC:Fire("STATUS", fields[2] or "Done.")
''',1)
text = text.replace('''        GC.plan.warnings[#GC.plan.warnings + 1] = fields[2] or "Server error"
''','''        GC:AddWarningOnce(fields[2] or "Server error")
        GC:SetProgress("ERROR", GC.progress and GC.progress.current or 0, GC.progress and GC.progress.total or 0, fields[2] or "Server error")
''',1)
text = text.replace('''    if kind == "RESET" or kind == "READY" or kind == "ERROR" then
        GC:Fire("PLAN_CHANGED", GC.plan)
    end
''','''    if kind == "RESET" or kind == "READY" or kind == "ERROR" then
        GC:Fire("PLAN_CHANGED", GC.plan)
    end
''',1)
core.write_text(text, encoding='utf-8')

runtime = Path('client-addons-src/GroupComposer/RuntimeGuards.lua')
r = runtime.read_text(encoding='utf-8')
marker = '-- Assemble is the destructive boundary:'
pos = r.find(marker)
if pos < 0: raise SystemExit('RuntimeGuards assemble popup marker drifted')
r = r[:pos] + '''-- Dashboard V4 owns the visible confirmation inside the Composer window. Keep the guarded
-- GC.Assemble function itself untouched here so internal server progress/retry state can never
-- reopen a Blizzard StaticPopup or force the user through repeated confirmations.\n'''
runtime.write_text(r, encoding='utf-8')

data = Path('client-addons-src/GroupComposer/Data.lua')
d = data.read_text(encoding='utf-8')
if 'D.VERSION = "0.4.1"' not in d: raise SystemExit('Data version drifted')
data.write_text(d.replace('D.VERSION = "0.4.1"', 'D.VERSION = "0.5.0"', 1), encoding='utf-8')

print('Group Composer V4 client protocol patch applied')
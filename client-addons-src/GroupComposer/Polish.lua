local GC = GroupComposer
local D = GroupComposerData
local UI = GC.UI

-- Small compatibility/polish layer loaded after the main UI. This keeps safety rules out of the
-- larger rendering/protocol files while preserving profiles written by earlier addon versions.
D.VERSION = "0.3.0"
GC.version = D.VERSION

local function ForcePlayerAnchor()
    local config = GC:GetConfig()
    config.options = config.options or {}
    config.options.keepMe = true

    if UI and UI.optionWidgets and UI.optionWidgets.keepMe then
        local cb = UI.optionWidgets.keepMe
        cb:SetChecked(true)
        cb:Disable()
        cb:SetScript("OnClick", nil)
        if cb.label then
            cb.label:SetText("Your character is always included")
            cb.label:SetTextColor(0.62, 0.68, 0.78, 1)
        end
    end
end

-- The composing player is always a locked human anchor server-side. Keep the legacy wire bit true,
-- but do not expose a switch whose OFF state can never be honored safely.
local originalBeginPayload = GC.BeginPayload
function GC:BeginPayload()
    ForcePlayerAnchor()
    return originalBeginPayload(self)
end

GC:RegisterCallback("CONFIG_CHANGED", function()
    ForcePlayerAnchor()
end)

-- Capture auto-detected humans separately from manual role overrides so subgroup placements survive
-- Save -> Normalize -> Load even when the server inferred that human's role correctly.
local originalCaptureStableArrangement = GC.CaptureStableArrangement
function GC:CaptureStableArrangement()
    originalCaptureStableArrangement(self)
    if not GC.plan or not GC.plan.ready then return end

    local humans, seen = {}, {}
    for _, member in ipairs(GC.plan.members or {}) do
        if member.human and member.name then
            local clean = GC.CleanCharacterName(member.name)
            local key = clean and string.lower(clean) or nil
            if clean and key and not seen[key] then
                seen[key] = true
                humans[#humans + 1] = clean
            end
        end
    end
    GC:GetConfig().stableHumans = humans
end

-- A single outstanding server action owns pendingCommand. Rapid overlapping Find/Move/Assemble
-- clicks used to overwrite that value and could attach a DONE/ERROR message to the wrong action.
local function GuardAction(name)
    local original = GC[name]
    if type(original) ~= "function" then return end
    GC[name] = function(self, ...)
        if GC.pendingCommand then
            GC:Fire("STATUS", "Group Composer is still processing " .. tostring(GC.pendingCommand) .. ".")
            return false
        end
        return original(self, ...)
    end
end

for _, name in ipairs({
    "FindRoster", "Assemble", "AutoArrange", "MoveMember", "QueueDungeon",
    "ClearServerPlan", "RequestStatus", "RequestDiagnostics",
}) do
    GuardAction(name)
end

ForcePlayerAnchor()

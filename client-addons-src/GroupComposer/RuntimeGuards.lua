local GC = GroupComposer

-- Runtime-only behavior shared by the Dashboard V3 client and the server protocol. Keep this file
-- free of legacy UI-frame references so changing visual shells cannot silently remove safety or
-- queue semantics again.

-- Preserve automatically detected humans as stable profile identities. Core already persists the
-- subgroup arrangement itself; stableHumans lets profile normalization keep those placements even
-- when a human uses the inferred role and therefore has no manual humanRoles entry.
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

-- Titan Rune is layered on stock Heroic RDF rather than represented by a normal 3.3.5 difficulty
-- id. Route Alpha/Beta/Gamma through the authoritative server bridge, which validates the reviewed
-- five-player snapshot, persists the real leader's selected protocol and queues only supported maps.
local originalQueueDungeon = GC.QueueDungeon
local TITAN_MODE = { alpha = true, beta = true, gamma = true }
local ROLE_TOKEN = { TANK = "T", HEALER = "H", DPS = "D" }

function GC:QueueDungeon()
    local config = GC:GetConfig()
    if not TITAN_MODE[config.difficulty] then
        return originalQueueDungeon(self)
    end
    if config.mode ~= "DUNGEON" then
        GC:Fire("STATUS", "Titan Rune handoff is only available in Dungeon mode.")
        return false
    end
    if not GC.plan or not GC.plan.ready or not GC.plan.valid or #(GC.plan.members or {}) ~= 5 then
        GC:Fire("STATUS", "Find and assemble a valid five-player roster before queueing Titan Rune.")
        return false
    end

    local encoded = {}
    for _, member in ipairs(GC.plan.members) do
        local name = GC.CleanCharacterName(member.name)
        local role = ROLE_TOKEN[member.role]
        if not name or not role then
            GC:Fire("STATUS", "The reviewed roster contains an invalid name or role. Find Roster again.")
            return false
        end
        encoded[#encoded + 1] = name .. ":" .. role
    end

    GC.pendingCommand = "queue"
    SendChatMessage(".gctitan queue " .. config.difficulty .. " " .. tostring(config.activity or "random") .. " " .. table.concat(encoded, ","), "SAY")
    GC:Fire("STATUS", "Selecting Titan Rune protocol and handing the reviewed party to Dungeon Finder...")
    return true
end

-- One outstanding mutating/synchronizing action owns pendingCommand. This prevents rapid clicks from
-- assigning a DONE/ERROR response to the wrong operation while a 25/40-player snapshot is in flight.
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

-- Status is passive synchronization. A fresh login with no plan receives STATUS rather than
-- READY/DONE, so it must release its action lock explicitly.
GC:RegisterCallback("STATUS", function()
    if GC.pendingCommand == "status" then GC.pendingCommand = nil end
end)

-- Assemble is the destructive boundary: it can prune unselected bots, prepare selected bots and
-- send invitations. Require a deliberate confirmation after the preview has been reviewed.
local confirmedAssemble = GC.Assemble
StaticPopupDialogs = StaticPopupDialogs or {}
StaticPopupDialogs["GROUPCOMPOSER_CONFIRM_ASSEMBLY"] = {
    text = "Assemble this %d-player roster?\n\nThis applies the reviewed composition to your live group. Unselected bots may be removed and selected players/bots invited. Real players are never silently removed.",
    button1 = "Assemble Roster",
    button2 = CANCEL,
    OnAccept = function()
        confirmedAssemble(GC)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function GC:Assemble()
    if GC.pendingCommand then
        GC:Fire("STATUS", "Group Composer is still processing " .. tostring(GC.pendingCommand) .. ".")
        return false
    end
    if not GC.plan or not GC.plan.ready or not GC.plan.valid then
        GC:Fire("STATUS", "Find and validate a roster before assembling it.")
        return false
    end
    StaticPopup_Show("GROUPCOMPOSER_CONFIRM_ASSEMBLY", tonumber(GC:GetConfig().size) or #(GC.plan.members or {}))
    return true
end

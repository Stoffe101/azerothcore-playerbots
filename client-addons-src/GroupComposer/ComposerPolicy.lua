local GC = GroupComposer
local D = GroupComposerData
local P = GroupComposerProfiles

GC.Policy = GC.Policy or {}
local Policy = GC.Policy

local function ClassCanRole(classToken, role)
    return classToken and role and D.CLASS_ROLE[role] and D.CLASS_ROLE[role][classToken] and true or false
end
Policy.ClassCanRole = ClassCanRole

local function HumanClass(name)
    if not name then return nil end
    local key = string.lower(name)
    for _, anchor in ipairs(GC.anchors or {}) do
        if anchor.name and string.lower(anchor.name) == key then return anchor.class end
    end
    local playerName = UnitName("player")
    if playerName and string.lower(playerName) == key then
        local _, classToken = UnitClass("player")
        return classToken
    end
    return nil
end

local function HumanRoleCounts(config)
    local counts = { TANK = 0, HEALER = 0, DPS = 0 }
    local seen = {}
    for _, human in ipairs(GC:ScanHumans() or {}) do
        local key = human.name and string.lower(human.name) or nil
        local role = human.name and config.humanRoles and config.humanRoles[human.name] or nil
        if key and role and counts[role] ~= nil and not seen[key] then
            seen[key] = true
            counts[role] = counts[role] + 1
        end
    end
    for _, human in ipairs(config.extraHumans or {}) do
        local key = human.name and string.lower(human.name) or nil
        local role = human.role
        if key and role and counts[role] ~= nil and not seen[key] then
            seen[key] = true
            counts[role] = counts[role] + 1
        end
    end
    return counts
end

-- Exact class/spec rows describe BOT slots. Human anchors already consume role slots, so trim any
-- stale exact requirements that no longer fit when the player changes their own role. This keeps
-- the UI from asking for a second tank in a 1-tank dungeon just because the human chose Tank.
function Policy:TrimExactPreferences()
    local config = GC:GetConfig()
    local humans = HumanRoleCounts(config)
    local targets = { TANK = tonumber(config.tanks) or 0, HEALER = tonumber(config.healers) or 0, DPS = tonumber(config.dps) or 0 }
    for _, role in ipairs(D.ROLE_ORDER or {"TANK", "HEALER", "DPS"}) do
        local remaining = math.max(0, (targets[role] or 0) - (humans[role] or 0))
        local keptRequired = 0
        local out = {}
        for _, pref in ipairs(config.preferences[role] or {}) do
            if not pref.required then
                out[#out + 1] = pref
            elseif keptRequired < remaining then
                keptRequired = keptRequired + 1
                out[#out + 1] = pref
            end
        end
        config.preferences[role] = out
    end
end

function Policy:HumanRoleProblems()
    local config = GC:GetConfig()
    local humans = GC:ScanHumans()
    local problems = {}
    for _, human in ipairs(humans or {}) do
        local role = config.humanRoles and config.humanRoles[human.name] or nil
        if not role then
            problems[#problems + 1] = (human.isPlayer and "Choose your role before finding a roster." or ("Choose a role for " .. tostring(human.name) .. "."))
        elseif not ClassCanRole(human.class, role) then
            problems[#problems + 1] = tostring(human.name) .. " cannot fill " .. tostring(D.ROLE_LABEL[role] or role) .. " with " .. tostring(D.CLASS_LABEL[human.class] or human.class) .. "."
        end
    end
    return problems
end

local BaseTouch = GC.Touch
function GC:Touch(reason)
    Policy:TrimExactPreferences()
    return BaseTouch(self, reason)
end

local BaseSetHumanRole = GC.SetHumanRole
function GC:SetHumanRole(name, role)
    if role and role ~= "AUTO" then
        local classToken = HumanClass(name)
        if classToken and not ClassCanRole(classToken, role) then
            GC:Fire("STATUS", (D.CLASS_LABEL[classToken] or classToken) .. " cannot fill the " .. (D.ROLE_LABEL[role] or role) .. " role.")
            return false
        end
    end
    local ok = BaseSetHumanRole(self, name, role)
    if ok then Policy:TrimExactPreferences() end
    return ok
end

local BaseValidateConfig = GC.ValidateConfig
function GC:ValidateConfig()
    Policy:TrimExactPreferences()
    local valid, problems = BaseValidateConfig(self)
    problems = problems or {}
    local humanProblems = Policy:HumanRoleProblems()
    for _, text in ipairs(humanProblems) do problems[#problems + 1] = text end
    return valid and #humanProblems == 0, problems
end

-- A template may remember a raid composition, but it must never silently decide a live human's
-- role. Preserve the roles explicitly chosen in this play session whenever a profile/reset/mode
-- replaces the rest of the configuration.
local BaseSetConfig = GC.SetConfig
function GC:SetConfig(config, sourceName)
    local current = GC.config
    local liveRoles = {}
    if current and current.humanRoles then
        for name, role in pairs(current.humanRoles) do liveRoles[name] = role end
    end
    local incoming = P.DeepCopy(config or {})
    incoming.humanRoles = liveRoles
    BaseSetConfig(self, incoming, sourceName)
    Policy:TrimExactPreferences()
end

-- Server assembly keeps joined members and releases only unjoined reserve leases on timeout.
-- Retry that safe operation automatically so a slow 25/40-player login wave does not leave a
-- half-built raid requiring repeated manual clicks.
local BaseAssemble = GC.Assemble
local retry = { attempt = 0, max = 2, delay = 1.5, pending = false, elapsed = 0, armed = false }
local retryFrame = CreateFrame("Frame")
retryFrame:Hide()
retryFrame:SetScript("OnUpdate", function(self, elapsed)
    if not retry.pending then self:Hide(); return end
    retry.elapsed = retry.elapsed + elapsed
    if retry.elapsed < retry.delay then return end
    retry.pending = false
    retry.elapsed = 0
    self:Hide()
    if not GC.plan or not GC.plan.ready or not GC.plan.valid then return end
    retry.attempt = retry.attempt + 1
    GC:Fire("STATUS", "Completing missing roster members automatically (retry " .. retry.attempt .. "/" .. retry.max .. ")...")
    BaseAssemble(GC)
end)

function Policy:ResetAssemblyRetry()
    retry.attempt, retry.pending, retry.elapsed, retry.armed = 0, false, 0, false
    retryFrame:Hide()
end

function GC:Assemble()
    Policy:ResetAssemblyRetry()
    retry.armed = true
    return BaseAssemble(self)
end

local BaseFindRoster = GC.FindRoster
function GC:FindRoster()
    Policy:ResetAssemblyRetry()
    return BaseFindRoster(self)
end

GC:RegisterCallback("PLAYER_READY", function()
    -- Role selection belongs to the live character/session, not to a saved profile. Require an
    -- explicit choice after login/reload so a DK can never unexpectedly inherit Tank from a
    -- previous template simply because Blood was detected.
    local config = GC:GetConfig()
    config.humanRoles = {}
    Policy:TrimExactPreferences()
    GC:Fire("CONFIG_CHANGED", config)
end)

GC:RegisterCallback("STATUS", function(text)
    text = tostring(text or "")
    if string.find(text, "Roster assembled", 1, true) then
        Policy:ResetAssemblyRetry()
        return
    end
    if retry.armed and string.find(text, "Assembly timed out", 1, true) and retry.attempt < retry.max then
        retry.pending = true
        retry.elapsed = 0
        retryFrame:Show()
    elseif string.find(text, "Assembly timed out", 1, true) and retry.attempt >= retry.max then
        retry.armed = false
    end
end)

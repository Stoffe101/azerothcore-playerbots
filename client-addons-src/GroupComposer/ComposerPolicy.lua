local GC = GroupComposer
local D = GroupComposerData

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

local BaseSetHumanRole = GC.SetHumanRole
function GC:SetHumanRole(name, role)
    if role and role ~= "AUTO" then
        local classToken = HumanClass(name)
        if classToken and not ClassCanRole(classToken, role) then
            GC:Fire("STATUS", (D.CLASS_LABEL[classToken] or classToken) .. " cannot fill the " .. (D.ROLE_LABEL[role] or role) .. " role.")
            return false
        end
    end
    return BaseSetHumanRole(self, name, role)
end

local BaseValidateConfig = GC.ValidateConfig
function GC:ValidateConfig()
    local valid, problems = BaseValidateConfig(self)
    problems = problems or {}
    local humanProblems = Policy:HumanRoleProblems()
    for _, text in ipairs(humanProblems) do problems[#problems + 1] = text end
    return valid and #humanProblems == 0, problems
end

-- Human role is a player decision, not a profile side effect. Keep explicit choices when
-- switching between Dungeon and Raid so the UI never silently reassigns a real player.
local BaseSetMode = GC.SetMode
function GC:SetMode(mode)
    local before = GC:GetConfig()
    local savedRoles = {}
    for name, role in pairs(before.humanRoles or {}) do savedRoles[name] = role end
    BaseSetMode(self, mode)
    local after = GC:GetConfig()
    for name, role in pairs(savedRoles) do after.humanRoles[name] = role end
    GC:Fire("CONFIG_CHANGED", after)
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

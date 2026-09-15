GroupComposer = GroupComposer or {}
local GC = GroupComposer
local D = GroupComposerData
local P = GroupComposerProfiles

GC.version = D.VERSION
GC.db = nil
GC.config = nil
GC.plan = { members = {}, warnings = {}, valid = false, ready = false, summary = {} }
GC.callbacks = {}
GC.backendSeen = false
GC.pendingCommand = nil

local function Split(text, delim)
    local out = {}
    if text == nil then return out end
    text = tostring(text)
    delim = delim or "|"
    if delim == "" then return { text } end

    local start = 1
    while true do
        local pos = string.find(text, delim, start, true)
        if not pos then
            out[#out + 1] = string.sub(text, start)
            break
        end
        out[#out + 1] = string.sub(text, start, pos - 1)
        start = pos + string.len(delim)
    end
    return out
end

local function Bool01(v) return v and "1" or "0" end

function GC:RegisterCallback(event, fn)
    if type(fn) ~= "function" then return end
    GC.callbacks[event] = GC.callbacks[event] or {}
    table.insert(GC.callbacks[event], fn)
end

function GC:Fire(event, ...)
    local bucket = GC.callbacks[event]
    if not bucket then return end
    for _, fn in ipairs(bucket) do
        local ok, err = pcall(fn, ...)
        if not ok and DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff5555Group Composer callback error:|r " .. tostring(err))
        end
    end
end

function GC:ResetPlan(reason)
    GC.plan = {
        members = {},
        warnings = {},
        valid = false,
        ready = false,
        summary = {},
        reason = reason,
    }
    GC:Fire("PLAN_CHANGED", GC.plan)
end

function GC:GetConfig()
    if not GC.config then
        GC.config = P.New((GC.db and GC.db.lastMode) or "DUNGEON")
    end
    return GC.config
end

function GC:SetConfig(config, sourceName)
    GC.config = P.Normalize(config)
    GC.db.lastMode = GC.config.mode
    GC.db.lastProfile = sourceName
    GC:ResetPlan("Configuration changed")
    GC:Fire("CONFIG_CHANGED", GC.config, sourceName)
end

function GC:SetMode(mode)
    mode = mode == "RAID" and "RAID" or "DUNGEON"
    local current = GC:GetConfig()
    if current.mode == mode then return end
    GC:SetConfig(P.New(mode), nil)
end

function GC:SetRaidSize(size)
    local c = GC:GetConfig()
    size = tonumber(size) or 25
    if size ~= 10 and size ~= 20 and size ~= 25 and size ~= 40 then size = 25 end
    c.size = size
    local t, h, d = D.DefaultRolesForSize(size)
    c.tanks, c.healers, c.dps = t, h, d
    GC:ResetPlan("Raid size changed")
    GC:Fire("CONFIG_CHANGED", c)
end

function GC:SetDungeonActivity(id)
    local c = GC:GetConfig()
    c.mode = "DUNGEON"
    c.activity = id or "random"
    c.size = 5
    c.tanks, c.healers, c.dps = 1, 1, 3
    GC:ResetPlan("Dungeon changed")
    GC:Fire("CONFIG_CHANGED", c)
end

function GC:SetRaidActivity(id)
    local c = GC:GetConfig()
    local raid = D.GetRaidById(id)
    if not raid then return end
    c.mode = "RAID"
    c.activity = raid.id
    local supported = false
    for _, n in ipairs(raid.sizes) do if n == c.size then supported = true end end
    if not supported then c.size = raid.sizes[1] end
    if not raid.heroic and c.difficulty == "heroic" then c.difficulty = "normal" end
    local t, h, d = D.DefaultRolesForSize(c.size)
    c.tanks, c.healers, c.dps = t, h, d
    GC:ResetPlan("Raid changed")
    GC:Fire("CONFIG_CHANGED", c)
end

function GC:ValidateConfig()
    local c = GC:GetConfig()
    local problems = {}
    local total = (tonumber(c.tanks) or 0) + (tonumber(c.healers) or 0) + (tonumber(c.dps) or 0)
    if total ~= c.size then
        problems[#problems + 1] = "Role totals must equal group size (currently " .. total .. "/" .. c.size .. ")."
    end
    if c.tanks < 0 or c.healers < 0 or c.dps < 0 then
        problems[#problems + 1] = "Role counts cannot be negative."
    end
    if c.mode == "DUNGEON" and c.size ~= 5 then
        problems[#problems + 1] = "Dungeon mode currently requires a 5-player target."
    end
    if c.mode == "RAID" then
        local raid = D.GetRaidById(c.activity)
        if not raid then
            problems[#problems + 1] = "Select a valid raid."
        else
            local validSize = false
            for _, n in ipairs(raid.sizes) do if n == c.size then validSize = true end end
            if not validSize then problems[#problems + 1] = raid.label .. " does not support " .. c.size .. " players." end
            if c.difficulty == "heroic" and not raid.heroic then
                problems[#problems + 1] = raid.label .. " does not use a Heroic raid difficulty in this preset list."
            end
        end
    end
    return #problems == 0, problems
end

local function SendRawServer(command)
    if not command or command == "" then return end
    SendChatMessage(".groupcomposer " .. command, "SAY")
end

function GC:BeginPayload()
    local c = GC:GetConfig()
    return table.concat({
        string.lower(c.mode),
        tostring(c.activity or "none"),
        tostring(c.difficulty or "normal"),
        tostring(c.size or 5),
        tostring(c.tanks or 0),
        tostring(c.healers or 0),
        tostring(c.dps or 0),
        Bool01(c.options.preferGuild),
        Bool01(c.options.fillWorld),
        Bool01(c.options.keepMe),
        Bool01(c.options.balanceClasses),
        Bool01(c.options.avoidDuplicateClasses),
        tostring(c.options.minimumItemLevel or 0),
    }, " ")
end

function GC:SendServer(command)
    if not command or command == "" then return end
    GC.pendingCommand = command
    SendRawServer(command)
    GC:Fire("STATUS", "Waiting for server...")
end

function GC:FindRoster()
    local valid, problems = GC:ValidateConfig()
    if not valid then
        GC:ResetPlan("Configuration invalid")
        for _, text in ipairs(problems) do table.insert(GC.plan.warnings, text) end
        GC:Fire("PLAN_CHANGED", GC.plan)
        return false
    end

    GC:ResetPlan("Searching")
    GC.pendingCommand = "find"
    GC:Fire("STATUS", "Building roster preview...")

    -- Keep each command comfortably under the 3.3.5 chat-message limit. The server stores
    -- this temporary draft per player until the final `find` command validates it.
    SendRawServer("begin " .. GC:BeginPayload())
    local c = GC:GetConfig()
    for _, role in ipairs({ "TANK", "HEALER", "DPS" }) do
        for _, pref in ipairs(c.preferences[role] or {}) do
            local classToken = pref.class or "ANY"
            local spec = pref.spec == nil and "ANY" or tostring(pref.spec)
            local strength = pref.required and "R" or "P"
            SendRawServer("pref " .. role .. " " .. classToken .. " " .. spec .. " " .. strength)
        end
    end
    SendRawServer("find")
    return true
end

function GC:Assemble()
    if not GC.plan.ready or not GC.plan.valid then
        GC:Fire("STATUS", "Find and validate a roster before assembling it.")
        return false
    end
    GC:SendServer("assemble")
    return true
end

function GC:AutoArrange()
    if not GC.plan.ready then
        GC:Fire("STATUS", "Find a roster first.")
        return false
    end
    GC:SendServer("arrange")
    return true
end

function GC:ClearServerPlan()
    GC:SendServer("clear")
    GC:ResetPlan("Cleared")
end

function GC:RequestStatus()
    GC:SendServer("status")
end

local function ParseNumber(text, fallback)
    local n = tonumber(text)
    if n == nil then return fallback end
    return n
end

function GC:HandleProtocolMessage(message)
    if type(message) ~= "string" or string.sub(message, 1, 5) ~= "[GC]|" then return false end
    GC.backendSeen = true
    local body = string.sub(message, 6)
    local fields = Split(body, "|")
    local kind = fields[1] or ""

    if kind == "RESET" then
        GC:ResetPlan("Server reset")
    elseif kind == "STATUS" then
        GC:Fire("STATUS", fields[2] or "Server ready")
    elseif kind == "META" then
        GC.plan.summary.mode = fields[2]
        GC.plan.summary.activity = fields[3]
        GC.plan.summary.difficulty = fields[4]
        GC.plan.summary.size = ParseNumber(fields[5], 0)
        GC.plan.summary.tanks = ParseNumber(fields[6], 0)
        GC.plan.summary.healers = ParseNumber(fields[7], 0)
        GC.plan.summary.dps = ParseNumber(fields[8], 0)
    elseif kind == "MEMBER" then
        GC.plan.members[#GC.plan.members + 1] = {
            subgroup = ParseNumber(fields[2], 0),
            name = fields[3] or "?",
            role = fields[4] or "DPS",
            class = fields[5] or "UNKNOWN",
            spec = fields[6] or "",
            source = fields[7] or "WORLD",
            human = fields[8] == "1",
            locked = fields[9] == "1",
        }
    elseif kind == "WARN" then
        GC.plan.warnings[#GC.plan.warnings + 1] = fields[2] or "Unknown warning"
    elseif kind == "READY" then
        GC.plan.valid = fields[2] == "1"
        GC.plan.ready = true
        GC.plan.summary.guild = ParseNumber(fields[3], 0)
        GC.plan.summary.world = ParseNumber(fields[4], 0)
        GC.plan.summary.humans = ParseNumber(fields[5], 0)
        GC.plan.summary.total = ParseNumber(fields[6], #GC.plan.members)
        GC.pendingCommand = nil
        GC:Fire("STATUS", GC.plan.valid and "Roster ready for review." or "Roster needs attention.")
    elseif kind == "DONE" then
        GC.pendingCommand = nil
        GC:Fire("STATUS", fields[2] or "Done.")
    elseif kind == "ERROR" then
        GC.pendingCommand = nil
        GC.plan.valid = false
        GC.plan.ready = true
        GC.plan.warnings[#GC.plan.warnings + 1] = fields[2] or "Server error"
        GC:Fire("STATUS", fields[2] or "Server error")
    end

    GC:Fire("PLAN_CHANGED", GC.plan)
    return true
end

local function SystemFilter(_, _, message, ...)
    if GC:HandleProtocolMessage(message) then return true end
    return false, message, ...
end

function GC:ScanHumans()
    local humans = {}
    local function Add(unit, subgroup)
        if not UnitExists(unit) then return end
        local name = UnitName(unit)
        local _, classToken = UnitClass(unit)
        if not name then return end
        humans[#humans + 1] = {
            name = name,
            class = classToken or "UNKNOWN",
            subgroup = subgroup or 1,
            isPlayer = UnitIsUnit(unit, "player") and true or false,
        }
    end

    local raidCount = GetNumRaidMembers and GetNumRaidMembers() or 0
    if raidCount and raidCount > 0 then
        for i = 1, raidCount do
            local name, _, subgroup, _, _, classToken, _, online = GetRaidRosterInfo(i)
            if name and online ~= false then
                humans[#humans + 1] = {
                    name = name,
                    class = classToken or "UNKNOWN",
                    subgroup = subgroup or 1,
                    isPlayer = name == UnitName("player"),
                }
            end
        end
    else
        Add("player", 1)
        local partyCount = GetNumPartyMembers and GetNumPartyMembers() or 0
        for i = 1, partyCount do Add("party" .. i, 1) end
    end
    return humans
end

function GC:SaveProfile(name)
    local ok, err = P.Save(name, GC:GetConfig())
    if ok then
        GC.db.lastProfile = name
        GC:Fire("PROFILES_CHANGED")
        GC:Fire("STATUS", "Saved profile: " .. name)
    else
        GC:Fire("STATUS", err)
    end
    return ok, err
end

function GC:LoadProfile(name)
    local p = P.Get(name)
    if not p then
        GC:Fire("STATUS", "Profile not found: " .. tostring(name))
        return false
    end
    GC:SetConfig(p, name)
    GC:Fire("STATUS", "Loaded profile: " .. name)
    return true
end

function GC:DeleteProfile(name)
    local ok, err = P.Delete(name)
    if ok then
        GC:Fire("PROFILES_CHANGED")
        GC:Fire("STATUS", "Deleted profile: " .. name)
    else
        GC:Fire("STATUS", err)
    end
    return ok, err
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "GroupComposer" then
        GC.db = P.InitializeDB()
        local start = GC.db.lastProfile and P.Get(GC.db.lastProfile) or nil
        GC.config = start or P.New(GC.db.lastMode)
        if ChatFrame_AddMessageEventFilter then
            ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", SystemFilter)
        end
        GC:Fire("CONFIG_CHANGED", GC.config, GC.db.lastProfile)
    elseif event == "PLAYER_LOGIN" then
        GC:Fire("PLAYER_READY")
    elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        GC:Fire("HUMANS_CHANGED", GC:ScanHumans())
    end
end)

SLASH_GROUPCOMPOSER1 = "/gc"
SLASH_GROUPCOMPOSER2 = "/groupcomposer"
SlashCmdList.GROUPCOMPOSER = function(msg)
    msg = string.lower(msg or "")
    if msg == "status" then
        GC:RequestStatus()
    elseif msg == "reset" then
        GC:SetConfig(P.New(GC:GetConfig().mode), nil)
    elseif GC.Toggle then
        GC:Toggle()
    end
end

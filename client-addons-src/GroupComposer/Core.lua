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
GC.dragMember = nil

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
local function CleanCharacterName(value)
    if type(value) ~= "string" then return nil end
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    value = string.gsub(value, "[^%a%-']", "")
    if value == "" then return nil end
    return value
end
GC.CleanCharacterName = CleanCharacterName

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

function GC:Touch(reason)
    GC:ResetPlan(reason or "Configuration changed")
    GC:Fire("CONFIG_CHANGED", GC:GetConfig())
end

function GC:SetConfig(config, sourceName)
    GC.config = P.Normalize(config)
    if GC.db then
        GC.db.lastMode = GC.config.mode
        GC.db.lastProfile = sourceName
    end
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
    local t, h, d = D.DefaultRolesForActivity("RAID", c.activity, size)
    c.tanks, c.healers, c.dps = t, h, d
    GC:Touch("Raid size changed")
end

function GC:SetDungeonActivity(id)
    local c = GC:GetConfig()
    c.mode = "DUNGEON"
    c.activity = id or "random"
    c.size = 5
    c.tanks, c.healers, c.dps = 1, 1, 3
    GC:Touch("Dungeon changed")
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
    local t, h, d = D.DefaultRolesForActivity("RAID", c.activity, c.size)
    c.tanks, c.healers, c.dps = t, h, d
    GC:Touch("Raid changed")
end

function GC:SetHumanRole(name, role)
    name = CleanCharacterName(name)
    if not name then return false end
    local c = GC:GetConfig()
    if role == nil or role == "AUTO" then
        c.humanRoles[name] = nil
    elseif role == "TANK" or role == "HEALER" or role == "DPS" then
        c.humanRoles[name] = role
    else
        return false
    end
    GC:Touch("Human role changed")
    return true
end

function GC:AddExtraHuman(name, role)
    name = CleanCharacterName(name)
    if not name or (role ~= "TANK" and role ~= "HEALER" and role ~= "DPS") then return false end
    local c, key = GC:GetConfig(), string.lower(name)
    for _, entry in ipairs(c.extraHumans) do
        if string.lower(entry.name) == key then
            entry.role = role
            GC:Touch("Human invite changed")
            return true
        end
    end
    c.extraHumans[#c.extraHumans + 1] = { name = name, role = role }
    GC:Touch("Human invite added")
    return true
end

function GC:RemoveExtraHuman(index)
    local c = GC:GetConfig()
    if type(index) ~= "number" or not c.extraHumans[index] then return false end
    table.remove(c.extraHumans, index)
    GC:Touch("Human invite removed")
    return true
end

function GC:AddPinnedMember(name, role, required)
    name = CleanCharacterName(name)
    if not name or (role ~= "TANK" and role ~= "HEALER" and role ~= "DPS") then return false end
    local c, key = GC:GetConfig(), string.lower(name)
    for _, entry in ipairs(c.pinned) do
        if string.lower(entry.name) == key then
            entry.role, entry.required = role, required and true or false
            GC:Touch("Pinned member changed")
            return true
        end
    end
    c.pinned[#c.pinned + 1] = { name = name, role = role, required = required and true or false }
    GC:Touch("Pinned member added")
    return true
end

function GC:RemovePinnedMember(index)
    local c = GC:GetConfig()
    if type(index) ~= "number" or not c.pinned[index] then return false end
    table.remove(c.pinned, index)
    GC:Touch("Pinned member removed")
    return true
end

function GC:SetArrangementPreference(name, subgroup)
    name = CleanCharacterName(name)
    subgroup = tonumber(subgroup)
    if not name then return false end
    local c = GC:GetConfig()
    if not subgroup or subgroup < 1 or subgroup > 8 then
        c.arrangement[name] = nil
    else
        c.arrangement[name] = math.floor(subgroup)
    end
    return true
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
        problems[#problems + 1] = "Dungeon mode requires a 5-player target."
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
                problems[#problems + 1] = raid.label .. " does not use a separate Heroic raid difficulty on this server preset."
            end
        end
    end
    if #c.extraHumans + 1 > c.size then
        problems[#problems + 1] = "Too many manually added humans for this group size."
    end
    if #c.pinned > c.size then
        problems[#problems + 1] = "Too many pinned members for this group size."
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
        Bool01(c.options.balanceUtility),
        Bool01(c.options.balanceRange),
        Bool01(c.options.avoidDuplicateClasses),
        tostring(c.options.minimumItemLevel or 0),
    }, " ")
end

function GC:SendServer(command, status)
    if not command or command == "" then return end
    GC.pendingCommand = command
    SendRawServer(command)
    GC:Fire("STATUS", status or "Waiting for server...")
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

    -- Keep every command comfortably below the 3.3.5 chat-message limit. The server keeps
    -- this temporary draft per player until the final `find` validates it.
    SendRawServer("begin " .. GC:BeginPayload())
    local c = GC:GetConfig()
    for _, role in ipairs(D.ROLE_ORDER) do
        for _, pref in ipairs(c.preferences[role] or {}) do
            local classToken = pref.class or "ANY"
            local spec = pref.spec == nil and "ANY" or tostring(pref.spec)
            local strength = pref.required and "R" or "P"
            SendRawServer("pref " .. role .. " " .. classToken .. " " .. spec .. " " .. strength)
        end
    end
    for name, role in pairs(c.humanRoles or {}) do
        SendRawServer("humanrole " .. name .. " " .. role)
    end
    for _, entry in ipairs(c.extraHumans or {}) do
        SendRawServer("human " .. entry.name .. " " .. entry.role)
    end
    for _, entry in ipairs(c.pinned or {}) do
        SendRawServer("pin " .. entry.name .. " " .. entry.role .. " " .. (entry.required and "R" or "P"))
    end
    for name, subgroup in pairs(c.arrangement or {}) do
        SendRawServer("arrangepref " .. name .. " " .. tostring(subgroup))
    end
    SendRawServer("find")
    return true
end

function GC:Assemble()
    if not GC.plan.ready or not GC.plan.valid then
        GC:Fire("STATUS", "Find and validate a roster before assembling it.")
        return false
    end
    GC:SendServer("assemble", "Assembling roster...")
    return true
end

function GC:AutoArrange()
    if not GC.plan.ready then
        GC:Fire("STATUS", "Find a roster first.")
        return false
    end
    GC:SendServer("arrange", "Auto-arranging subgroups...")
    return true
end

function GC:MoveMember(name, subgroup)
    name = CleanCharacterName(name)
    subgroup = tonumber(subgroup)
    if not GC.plan.ready or not name or not subgroup or subgroup < 1 or subgroup > 8 then return false end
    GC:SendServer("move " .. name .. " " .. tostring(math.floor(subgroup)), "Moving " .. name .. "...")
    return true
end

function GC:QueueDungeon()
    local c = GC:GetConfig()
    if c.mode ~= "DUNGEON" then
        GC:Fire("STATUS", "Dungeon Finder handoff is only available in Dungeon mode.")
        return false
    end
    if not GC.plan.ready or not GC.plan.valid then
        GC:Fire("STATUS", "Find and assemble a valid dungeon party first.")
        return false
    end
    GC:SendServer("queue", "Handing the party to Dungeon Finder...")
    return true
end

function GC:ClearServerPlan()
    GC:SendServer("clear")
    GC:ResetPlan("Cleared")
end

function GC:RequestStatus()
    GC:SendServer("status")
end

function GC:RequestDiagnostics()
    GC:SendServer("diagnostics", "Refreshing diagnostics...")
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
            pinned = fields[10] == "1",
        }
    elseif kind == "COVERAGE" then
        GC.plan.summary.ranged = ParseNumber(fields[2], 0)
        GC.plan.summary.melee = ParseNumber(fields[3], 0)
        GC.plan.summary.utility = fields[4] or ""
    elseif kind == "DIAG" then
        GC.plan.summary.diagnostics = fields[2] or ""
        GC:Fire("DIAGNOSTICS", GC.plan.summary.diagnostics)
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
            role = GC:GetConfig().humanRoles[name] or "AUTO",
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
                    role = GC:GetConfig().humanRoles[name] or "AUTO",
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

local function IsStableProfileMember(config, member)
    if not member or not member.name then return false end
    if member.human then return true end
    local key = string.lower(member.name)
    for _, pin in ipairs(config.pinned or {}) do
        if string.lower(pin.name) == key then return true end
    end
    return false
end

function GC:CaptureStableArrangement()
    local c = GC:GetConfig()
    local arrangement = {}
    if GC.plan and GC.plan.ready then
        for _, member in ipairs(GC.plan.members or {}) do
            if IsStableProfileMember(c, member) and member.subgroup and member.subgroup >= 1 and member.subgroup <= 8 then
                arrangement[member.name] = member.subgroup
            end
        end
    end
    c.arrangement = arrangement
end

function GC:SaveProfile(name)
    GC:CaptureStableArrangement()
    local ok, err = P.Save(name, GC:GetConfig())
    if ok then
        GC.db.lastProfile = P.CleanName(name)
        GC:Fire("PROFILES_CHANGED")
        GC:Fire("STATUS", "Saved profile: " .. tostring(GC.db.lastProfile))
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
eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
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
    elseif event == "DISPLAY_SIZE_CHANGED" then
        GC:Fire("DISPLAY_CHANGED")
    end
end)

SLASH_GROUPCOMPOSER1 = "/gc"
SLASH_GROUPCOMPOSER2 = "/groupcomposer"
SlashCmdList.GROUPCOMPOSER = function(msg)
    msg = string.lower(msg or "")
    if msg == "status" then
        GC:RequestStatus()
    elseif msg == "diag" or msg == "diagnostics" then
        GC:RequestDiagnostics()
    elseif msg == "reset" then
        GC:SetConfig(P.New(GC:GetConfig().mode), nil)
    elseif GC.Toggle then
        GC:Toggle()
    end
end

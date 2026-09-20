GroupComposer = GroupComposer or {}
local GC = GroupComposer
local D = GroupComposerData
local P = GroupComposerProfiles

GC.version = D.VERSION
GC.db = nil
GC.config = nil
GC.plan = { members = {}, warnings = {}, valid = false, ready = false, summary = {} }
GC.progress = { phase = "IDLE", current = 0, total = 0, detail = "Configure a roster to begin." }
GC.callbacks = {}
GC.backendSeen = false
GC.pendingCommand = nil
GC.dragMember = nil
GC.anchors = {}
GC.anchorsReady = false
GC.activityEligibility = { DUNGEON = {}, RAID = {} }
GC.activityEligibilityReady = { DUNGEON = false, RAID = false }
GC.activityMeta = { DUNGEON = {}, RAID = {} }
GC.activityProgression = 0
GC.realm = { era = "Vanilla", levelCap = 60, progression = 0 }
GC.journey = { ready = false, raids = {}, recommendations = {}, era = "Vanilla", stage = 0, level = 1, guildId = 0 }
GC.catalogDiagnostics = { ready = false, entries = {}, pass = 0, warn = 0, fail = 0 }
GC.unlockDetails = { ready = false, mode = "DUNGEON", id = "", label = "", available = false, summary = "", requirements = {} }

local function Split(text, delim)
    local out = {}
    if text == nil then return out end
    text = tostring(text)
    delim = delim or "|"
    if delim == "" then return { text } end
    local start = 1
    while true do
        local pos = string.find(text, delim, start, true)
        if not pos then out[#out + 1] = string.sub(text, start); break end
        out[#out + 1] = string.sub(text, start, pos - 1)
        start = pos + string.len(delim)
    end
    return out
end

local function Bool01(value) return value and "1" or "0" end
local function ParseNumber(value, fallback)
    local number = tonumber(value)
    if number == nil then return fallback end
    return number
end

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

function GC:SetProgress(phase, current, total, detail)
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

function GC:GetConfig()
    if not GC.config then GC.config = P.New((GC.db and GC.db.lastMode) or "DUNGEON") end
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
    if GC:GetConfig().mode == mode then return end
    GC:SetConfig(P.New(mode), nil)
end

function GC:SetRaidSize(size)
    local config = GC:GetConfig()
    size = tonumber(size) or 25
    if size ~= 10 and size ~= 20 and size ~= 25 and size ~= 40 then size = 25 end
    config.size = size
    config.tanks, config.healers, config.dps = D.DefaultRolesForActivity("RAID", config.activity, size)
    GC:Touch("Raid size changed")
end

function GC:SetDungeonActivity(id)
    local config = GC:GetConfig()
    config.mode, config.activity, config.size = "DUNGEON", id or "random", 5
    config.tanks, config.healers, config.dps = 1, 1, 3
    GC:Touch("Dungeon changed")
end

function GC:SetRaidActivity(id)
    local config = GC:GetConfig()
    local raid = D.GetRaidById(id)
    if not raid then return end
    config.mode, config.activity = "RAID", raid.id
    local supported = false
    for _, value in ipairs(raid.sizes) do if value == config.size then supported = true end end
    if not supported then config.size = raid.sizes[1] end
    if not raid.heroic and config.difficulty == "heroic" then config.difficulty = "normal" end
    config.tanks, config.healers, config.dps = D.DefaultRolesForActivity("RAID", config.activity, config.size)
    GC:Touch("Raid changed")
end

function GC:SetHumanRole(name, role)
    name = CleanCharacterName(name)
    if not name then return false end
    local config = GC:GetConfig()
    if role == nil or role == "AUTO" then
        config.humanRoles[name] = nil
    elseif role == "TANK" or role == "HEALER" or role == "DPS" then
        config.humanRoles[name] = role
    else
        return false
    end
    GC:Touch("Human role changed")
    return true
end

function GC:AddExtraHuman(name, role)
    name = CleanCharacterName(name)
    if not name or (role ~= "TANK" and role ~= "HEALER" and role ~= "DPS") then return false end
    local config, key = GC:GetConfig(), string.lower(name)
    for _, entry in ipairs(config.extraHumans) do
        if string.lower(entry.name) == key then
            entry.role = role
            GC:Touch("Human invite changed")
            return true
        end
    end
    config.extraHumans[#config.extraHumans + 1] = { name = name, role = role }
    GC:Touch("Human invite added")
    return true
end

function GC:RemoveExtraHuman(index)
    local config = GC:GetConfig()
    if type(index) ~= "number" or not config.extraHumans[index] then return false end
    table.remove(config.extraHumans, index)
    GC:Touch("Human invite removed")
    return true
end

function GC:AddPinnedMember(name, role, required)
    name = CleanCharacterName(name)
    if not name or (role ~= "TANK" and role ~= "HEALER" and role ~= "DPS") then return false end
    local config, key = GC:GetConfig(), string.lower(name)
    for _, entry in ipairs(config.pinned) do
        if string.lower(entry.name) == key then
            entry.role, entry.required = role, required and true or false
            GC:Touch("Pinned member changed")
            return true
        end
    end
    config.pinned[#config.pinned + 1] = { name = name, role = role, required = required and true or false }
    GC:Touch("Pinned member added")
    return true
end

function GC:RemovePinnedMember(index)
    local config = GC:GetConfig()
    if type(index) ~= "number" or not config.pinned[index] then return false end
    table.remove(config.pinned, index)
    GC:Touch("Pinned member removed")
    return true
end

function GC:SetArrangementPreference(name, subgroup)
    name = CleanCharacterName(name)
    subgroup = tonumber(subgroup)
    if not name then return false end
    local config = GC:GetConfig()
    if not subgroup or subgroup < 1 or subgroup > 8 then config.arrangement[name] = nil
    else config.arrangement[name] = math.floor(subgroup) end
    return true
end

function GC:ValidateConfig()
    local config = GC:GetConfig()
    local problems = {}
    local total = (tonumber(config.tanks) or 0) + (tonumber(config.healers) or 0) + (tonumber(config.dps) or 0)
    if total ~= config.size then problems[#problems + 1] = "Role totals must equal group size (currently " .. total .. "/" .. config.size .. ")." end
    if config.tanks < 0 or config.healers < 0 or config.dps < 0 then problems[#problems + 1] = "Role counts cannot be negative." end
    if config.mode == "DUNGEON" and config.size ~= 5 then problems[#problems + 1] = "Dungeon mode requires a 5-player target." end
    if config.mode == "RAID" then
        local raid = D.GetRaidById(config.activity)
        if not raid then
            problems[#problems + 1] = "Select a valid raid."
        else
            local validSize = false
            for _, value in ipairs(raid.sizes) do if value == config.size then validSize = true end end
            if not validSize then problems[#problems + 1] = raid.label .. " does not support " .. config.size .. " players." end
            if config.difficulty == "heroic" and not raid.heroic then problems[#problems + 1] = raid.label .. " does not expose a separate Heroic raid difficulty." end
        end
    end
    if #config.extraHumans + 1 > config.size then problems[#problems + 1] = "Too many manually added humans for this group size." end
    if #config.pinned > config.size then problems[#problems + 1] = "Too many pinned members for this group size." end
    return #problems == 0, problems
end

local function SendRawServer(command)
    if command and command ~= "" then SendChatMessage(".groupcomposer " .. command, "SAY") end
end

function GC:BeginPayload()
    local config = GC:GetConfig()
    return table.concat({
        string.lower(config.mode), tostring(config.activity or "none"), tostring(config.difficulty or "normal"),
        tostring(config.size or 5), tostring(config.tanks or 0), tostring(config.healers or 0), tostring(config.dps or 0),
        Bool01(config.options.preferGuild), Bool01(config.options.fillWorld), Bool01(config.options.keepMe),
        Bool01(config.options.balanceClasses), Bool01(config.options.balanceUtility), Bool01(config.options.balanceRange),
        Bool01(config.options.avoidDuplicateClasses), tostring(config.options.minimumItemLevel or 0),
    }, " ")
end

function GC:SendServer(command, status)
    if not command or command == "" then return end
    GC.pendingCommand = command
    SendRawServer(command)
    GC:Fire("STATUS", status or "Waiting for server...")
end

function GC:RequestAnchors()
    GC.anchorsReady = false
    SendRawServer("anchors")
end

function GC:RequestActivities(mode, difficulty, size)
    local config = GC:GetConfig()
    mode = mode == "RAID" and "RAID" or "DUNGEON"
    difficulty = tostring(difficulty or config.difficulty or "normal")
    if mode == "RAID" and difficulty ~= "heroic" then difficulty = "normal" end
    if mode == "DUNGEON" and difficulty ~= "heroic" and difficulty ~= "alpha" and difficulty ~= "beta" and difficulty ~= "gamma" then
        difficulty = "normal"
    end
    size = tonumber(size) or (mode == "RAID" and tonumber(config.size) or 5) or 5
    GC.activityEligibility[mode] = {}
    GC.activityEligibilityReady[mode] = false
    GC:Fire("ACTIVITIES_CHANGED", mode)
    SendRawServer("activities " .. string.lower(mode) .. " " .. difficulty .. " " .. tostring(math.floor(size)))
end

function GC:RequestUnlockDetails(mode, activity, difficulty, size)
    local config = GC:GetConfig()
    mode = mode == "RAID" and "RAID" or "DUNGEON"
    difficulty = tostring(difficulty or config.difficulty or "normal")
    size = tonumber(size) or (mode == "RAID" and tonumber(config.size) or 5) or 5
    GC.unlockDetails = { ready = false, mode = mode, id = activity or "", label = "", available = false, summary = "", requirements = {} }
    GC:Fire("UNLOCK_DETAILS_CHANGED", GC.unlockDetails)
    SendRawServer("requirements " .. string.lower(mode) .. " " .. tostring(activity or "") .. " " .. difficulty .. " " .. tostring(math.floor(size)))
end

function GC:RequestJourney()
    GC.journey.ready = false
    GC.journey.raids = {}
    GC.journey.recommendations = {}
    GC:Fire("JOURNEY_CHANGED", GC.journey)
    SendRawServer("journey")
end

function GC:FindRoster()
    local valid, problems = GC:ValidateConfig()
    if not valid then
        GC:ResetPlan("Configuration invalid")
        for _, text in ipairs(problems) do table.insert(GC.plan.warnings, text) end
        GC:Fire("PLAN_CHANGED", GC.plan)
        return false
    end

    P.MarkRecent(GC:GetConfig().mode, GC:GetConfig().activity)
    GC:Fire("ACTIVITY_HISTORY_CHANGED")
    GC:ResetPlan("Searching")
    GC.pendingCommand = "find"
    GC:SetProgress("BUILDING", 0, 0, "Selecting a valid roster...")
    GC:Fire("STATUS", "Building and preparing roster...")
    SendRawServer("begin " .. GC:BeginPayload())
    local config = GC:GetConfig()
    for _, role in ipairs(D.ROLE_ORDER) do
        for _, pref in ipairs(config.preferences[role] or {}) do
            SendRawServer("pref " .. role .. " " .. (pref.class or "ANY") .. " " .. (pref.spec == nil and "ANY" or tostring(pref.spec)) .. " " .. (pref.required and "R" or "P"))
        end
    end
    for name, role in pairs(config.humanRoles or {}) do SendRawServer("humanrole " .. name .. " " .. role) end
    for _, entry in ipairs(config.extraHumans or {}) do SendRawServer("human " .. entry.name .. " " .. entry.role) end
    for _, entry in ipairs(config.pinned or {}) do SendRawServer("pin " .. entry.name .. " " .. entry.role .. " " .. (entry.required and "R" or "P")) end
    for name, subgroup in pairs(config.arrangement or {}) do SendRawServer("arrangepref " .. name .. " " .. tostring(subgroup)) end
    SendRawServer("find")
    return true
end

function GC:Assemble()
    if not GC.plan.ready or not GC.plan.valid then GC:Fire("STATUS", "Build and validate a roster before assembling it."); return false end
    if not GC.progress or GC.progress.phase ~= "READY" then
        GC:Fire("STATUS", "Selected bots are still being prepared. Assemble unlocks when they are ready.")
        return false
    end
    GC:SetProgress("ASSEMBLING", 1, tonumber(GC.plan.summary.total) or #GC.plan.members, "Committing prepared roster to the live group...")
    GC:SendServer("assemble", "Assembling prepared roster...")
    return true
end

function GC:TeleportToInstance()
    local config = GC:GetConfig()
    if config.mode == "DUNGEON" and config.activity == "random" then
        GC:Fire("STATUS", "Random Dungeon has no fixed entrance. Use Dungeon Finder after assembly.")
        return false
    end
    if not GC.plan.ready or not GC.plan.valid or not GC.progress or GC.progress.phase ~= "ASSEMBLED" then
        GC:Fire("STATUS", "Assemble the reviewed group before teleporting to the instance.")
        return false
    end
    GC:SetProgress("TRAVEL", tonumber(GC.plan.summary.total) or #GC.plan.members, tonumber(GC.plan.summary.total) or #GC.plan.members,
        "Confirming instance access...")
    GC:SendServer("teleport", "Teleporting group to instance...")
    return true
end

function GC:LeaveInstance()
    if not GC.plan.ready or not GC.plan.valid then
        GC:Fire("STATUS", "Build and assemble a valid roster first.")
        return false
    end
    GC:SendServer("leave", "Leaving the instance with the reviewed group...")
    return true
end

function GC:DisbandComposerGroup()
    if not GC.plan.ready or not GC.plan.valid then
        GC:Fire("STATUS", "There is no active Composer roster to disband.")
        return false
    end
    GC:SendServer("disband", "Disbanding the Composer group...")
    return true
end

function GC:AutoArrange()
    if not GC.plan.ready then GC:Fire("STATUS", "Find a roster first."); return false end
    GC:SendServer("arrange", "Auto-arranging subgroups...")
    return true
end

function GC:MoveMember(name, subgroup)
    name, subgroup = CleanCharacterName(name), tonumber(subgroup)
    if not GC.plan.ready or not name or not subgroup or subgroup < 1 or subgroup > 8 then return false end
    GC:SendServer("move " .. name .. " " .. tostring(math.floor(subgroup)), "Moving " .. name .. "...")
    return true
end

function GC:QueueDungeon()
    local config = GC:GetConfig()
    if config.mode ~= "DUNGEON" then GC:Fire("STATUS", "Dungeon Finder handoff is only available in Dungeon mode."); return false end
    if not GC.plan.ready or not GC.plan.valid then GC:Fire("STATUS", "Find and assemble a valid dungeon party first."); return false end
    GC:SendServer("queue", "Handing the party to Dungeon Finder...")
    return true
end

function GC:ClearServerPlan()
    GC:SendServer("clear")
    GC:ResetPlan("Cleared")
end
function GC:RequestStatus() GC:SendServer("status") end
function GC:RequestDiagnostics() GC:SendServer("diagnostics", "Refreshing diagnostics...") end
function GC:RequestCatalogDiagnostics()
    GC.catalogDiagnostics = { ready = false, entries = {}, pass = 0, warn = 0, fail = 0 }
    GC:Fire("CATALOG_DIAGNOSTICS_CHANGED", GC.catalogDiagnostics)
    GC:SendServer("catalogdiag", "Validating activity catalog...")
end

function GC:HandleProtocolMessage(message)
    if type(message) ~= "string" or string.sub(message, 1, 5) ~= "[GC]|" then return false end
    GC.backendSeen = true
    local fields = Split(string.sub(message, 6), "|")
    local kind = fields[1] or ""

    if kind == "RESET" then
        GC:ResetPlan("Server reset")
    elseif kind == "ANCHORRESET" then
        GC.anchors, GC.anchorsReady = {}, false
    elseif kind == "ANCHOR" then
        GC.anchors[#GC.anchors + 1] = {
            name = fields[2] or "?", class = fields[3] or "UNKNOWN", role = fields[4] or "AUTO",
            online = fields[5] == "1", subgroup = ParseNumber(fields[6], 1), isPlayer = fields[7] == "1",
            level = ParseNumber(fields[8], 1),
        }
    elseif kind == "ANCHORDONE" then
        GC.anchorsReady = true
        GC:Fire("HUMANS_CHANGED", GC:ScanHumans())
    elseif kind == "ACTIVITYRESET" then
        local mode = fields[2] == "RAID" and "RAID" or "DUNGEON"
        GC.activityEligibility[mode] = {}
        GC.activityMeta[mode] = {}
        GC.activityEligibilityReady[mode] = false
        GC:Fire("ACTIVITIES_CHANGED", mode)
    elseif kind == "REALM" then
        GC.realm = {
            era = fields[2] or "Vanilla",
            levelCap = ParseNumber(fields[3], 60),
            progression = ParseNumber(fields[4], 0),
        }
        GC.activityProgression = GC.realm.progression
        GC:Fire("REALM_CHANGED", GC.realm)
    elseif kind == "ACTIVITY" then
        local mode = fields[2] == "RAID" and "RAID" or "DUNGEON"
        local id = fields[3] or ""
        if id ~= "" then
            GC.activityEligibility[mode][id] = {
                eligible = fields[4] == "1",
                reason = fields[5] or "",
            }
            GC.activityMeta[mode][id] = {
                id = id,
                label = fields[6] or id,
                era = fields[7] or GC.realm.era or "Vanilla",
                minLevel = ParseNumber(fields[8], 1),
                minProgression = ParseNumber(fields[9], 0),
                size = ParseNumber(fields[10], mode == "RAID" and 10 or 5),
                support = fields[11] or "Unknown",
                map = ParseNumber(fields[12], 0),
            }
        end
    elseif kind == "ACTIVITYDONE" then
        local mode = fields[2] == "RAID" and "RAID" or "DUNGEON"
        GC.activityEligibilityReady[mode] = true
        GC.activityProgression = ParseNumber(fields[3], GC.activityProgression or 0)
        GC.realm.progression = GC.activityProgression
        GC:Fire("ACTIVITIES_CHANGED", mode)
    elseif kind == "UNLOCKRESET" then
        GC.unlockDetails = {
            ready = false,
            mode = fields[2] == "RAID" and "RAID" or "DUNGEON",
            id = fields[3] or "",
            label = fields[4] or "",
            available = false,
            summary = "",
            requirements = {},
        }
        GC:Fire("UNLOCK_DETAILS_CHANGED", GC.unlockDetails)
    elseif kind == "UNLOCKSTATE" then
        GC.unlockDetails.available = fields[2] == "1"
        GC.unlockDetails.summary = fields[3] or ""
    elseif kind == "UNLOCKREQ" then
        GC.unlockDetails.requirements[#GC.unlockDetails.requirements + 1] = {
            type = fields[2] or "OTHER",
            status = fields[3] == "PASS" and "PASS" or "MISSING",
            title = fields[4] or "",
            detail = fields[5] or "",
        }
    elseif kind == "UNLOCKDONE" then
        GC.unlockDetails.ready = true
        GC:Fire("UNLOCK_DETAILS_CHANGED", GC.unlockDetails)
    elseif kind == "JOURNEYRESET" then
        GC.journey = {
            ready = false, raids = {}, recommendations = {},
            era = GC.realm.era or "Vanilla", stage = GC.activityProgression or 0, level = UnitLevel("player") or 1, guildId = 0,
        }
        GC:Fire("JOURNEY_CHANGED", GC.journey)
    elseif kind == "JOURNEYSTATE" then
        GC.journey.era = fields[2] or "Vanilla"
        GC.journey.stage = ParseNumber(fields[3], 0)
        GC.journey.level = ParseNumber(fields[4], UnitLevel("player") or 1)
        GC.journey.guildId = ParseNumber(fields[5], 0)
        GC.realm.era = GC.journey.era
        GC.realm.progression = GC.journey.stage
    elseif kind == "JOURNEYRAID" then
        GC.journey.raids[#GC.journey.raids + 1] = {
            id = fields[2] or "",
            label = fields[3] or "",
            era = fields[4] or "Vanilla",
            requiredProgression = ParseNumber(fields[5], 0),
            available = fields[6] == "1",
            playerComplete = fields[7] == "1",
            guildComplete = fields[8] == "1",
            support = fields[9] or "Unknown",
            reason = fields[10] or "",
            playerClearCount = ParseNumber(fields[11], 0),
            playerFirstClear = fields[12] or "",
            guildClearCount = ParseNumber(fields[13], 0),
            guildFirstClear = fields[14] or "",
            lockoutActive = fields[15] == "1",
            lockoutInstanceId = ParseNumber(fields[16], 0),
            lockoutEncounters = ParseNumber(fields[17], 0),
            lockoutExtended = fields[18] == "1",
            guildFirstRoster = fields[19] or "",
            playerFirstFormat = fields[20] or "",
            playerFirstGroupSize = ParseNumber(fields[21], 0),
            guildFirstFormat = fields[22] or "",
            guildFirstGroupSize = ParseNumber(fields[23], 0),
            guildRecentClears = {},
        }
    elseif kind == "JOURNEYRAIDRECENT" then
        local activityId = fields[2] or ""
        for _, raid in ipairs(GC.journey.raids) do
            if raid.id == activityId then
                raid.guildRecentClears[#raid.guildRecentClears + 1] = fields[3] or ""
                break
            end
        end
    elseif kind == "RECOMMEND" then
        GC.journey.recommendations[#GC.journey.recommendations + 1] = {
            id = fields[2] or "",
            mode = fields[3] == "RAID" and "RAID" or "DUNGEON",
            label = fields[4] or "",
            era = fields[5] or "Vanilla",
            reason = fields[6] or "",
            available = fields[7] == "1",
            feasible = fields[8] == "1",
            guildBots = ParseNumber(fields[9], 0),
            selectedBots = ParseNumber(fields[10], 0),
            guildCandidates = ParseNumber(fields[11], 0),
            humans = ParseNumber(fields[12], 0),
            humanNames = fields[13] or "",
            playerItemLevel = ParseNumber(fields[14], 0),
            recommendedFloor = ParseNumber(fields[15], 0),
            recommendedTarget = ParseNumber(fields[16], 0),
            gearReady = fields[17] ~= "0",
            readiness = fields[18] or "",
        }
    elseif kind == "JOURNEYDONE" then
        GC.journey.ready = true
        GC:Fire("JOURNEY_CHANGED", GC.journey)
    elseif kind == "PROGRESS" then
        local phase = fields[2] or "IDLE"
        local current = ParseNumber(fields[3], 0)
        local total = ParseNumber(fields[4], 0)
        local detail = fields[5] or ""
        GC:SetProgress(phase, current, total, detail)
        if phase == "READY" and GC.pendingCommand == "find" then GC.pendingCommand = nil end
        if phase == "ASSEMBLED" and GC.pendingCommand == "assemble" then
            GC.pendingCommand = nil
            if GC:GetConfig().mode == "DUNGEON" and GC:GetConfig().activity == "random" and GC:GetConfig().options.queueAfterAssemble then
                GC:QueueDungeon()
            end
        end
        if phase == "ASSEMBLED" and GC.pendingCommand == "teleport" then GC.pendingCommand = nil end
        if phase == "ERROR" then GC.pendingCommand = nil end
    elseif kind == "STATUS" then
        GC:Fire("STATUS", fields[2] or "Server ready")
    elseif kind == "META" then
        GC.plan.summary.mode = fields[2]; GC.plan.summary.activity = fields[3]; GC.plan.summary.difficulty = fields[4]
        GC.plan.summary.size = ParseNumber(fields[5], 0); GC.plan.summary.tanks = ParseNumber(fields[6], 0)
        GC.plan.summary.healers = ParseNumber(fields[7], 0); GC.plan.summary.dps = ParseNumber(fields[8], 0)
        GC.plan.summary.requiredLevel = ParseNumber(fields[9], 0)
    elseif kind == "MEMBER" then
        GC.plan.members[#GC.plan.members + 1] = {
            subgroup = ParseNumber(fields[2], 0), name = fields[3] or "?", role = fields[4] or "DPS",
            class = fields[5] or "UNKNOWN", spec = fields[6] or "", source = fields[7] or "WORLD",
            human = fields[8] == "1", locked = fields[9] == "1", pinned = fields[10] == "1",
            needsPreparation = fields[11] == "1", reserve = fields[12] == "1", isPlayer = fields[13] == "1",
            level = ParseNumber(fields[14], 0),
            why = fields[15] or "",
        }
    elseif kind == "COVERAGE" then
        GC.plan.summary.ranged = ParseNumber(fields[2], 0); GC.plan.summary.melee = ParseNumber(fields[3], 0); GC.plan.summary.utility = fields[4] or ""
        GC.plan.summary.utilityCounts = nil
        GC.plan.summary.raidBuffs = {}
    elseif kind == "COVERAGECOUNTS" then
        GC.plan.summary.utilityCounts = {
            interrupt = ParseNumber(fields[2], 0),
            dispel = ParseNumber(fields[3], 0),
            buffs = ParseNumber(fields[4], 0),
            heroism = ParseNumber(fields[5], 0),
            battleRez = ParseNumber(fields[6], 0),
            cc = ParseNumber(fields[7], 0),
            threat = ParseNumber(fields[8], 0),
        }
    elseif kind == "RAIDBUFF" then
        GC.plan.summary.raidBuffs = GC.plan.summary.raidBuffs or {}
        GC.plan.summary.raidBuffs[#GC.plan.summary.raidBuffs + 1] = {
            token = fields[2] or "",
            label = fields[3] or "",
            count = ParseNumber(fields[4], 0),
            providers = fields[5] or "",
        }
    elseif kind == "DIAG" then
        GC.plan.summary.diagnostics = fields[2] or ""
        GC.pendingCommand = nil
        GC:Fire("DIAGNOSTICS", GC.plan.summary.diagnostics)
    elseif kind == "CATDIAGRESET" then
        GC.catalogDiagnostics = { ready = false, entries = {}, pass = 0, warn = 0, fail = 0 }
        GC:Fire("CATALOG_DIAGNOSTICS_CHANGED", GC.catalogDiagnostics)
    elseif kind == "CATDIAG" then
        GC.catalogDiagnostics.entries[#GC.catalogDiagnostics.entries + 1] = {
            id = fields[2] or "",
            label = fields[3] or "",
            era = fields[4] or "Vanilla",
            mode = fields[5] == "RAID" and "RAID" or "DUNGEON",
            status = fields[6] or "WARN",
            detail = fields[7] or "",
        }
    elseif kind == "CATDIAGDONE" then
        GC.catalogDiagnostics.pass = ParseNumber(fields[2], 0)
        GC.catalogDiagnostics.warn = ParseNumber(fields[3], 0)
        GC.catalogDiagnostics.fail = ParseNumber(fields[4], 0)
        GC.catalogDiagnostics.ready = true
        GC.pendingCommand = nil
        GC:Fire("CATALOG_DIAGNOSTICS_CHANGED", GC.catalogDiagnostics)
    elseif kind == "WARN" then
        GC:AddWarningOnce(fields[2] or "Unknown warning")
    elseif kind == "READY" then
        GC.plan.valid = fields[2] == "1"; GC.plan.ready = true
        GC.plan.summary.guild = ParseNumber(fields[3], 0); GC.plan.summary.world = ParseNumber(fields[4], 0)
        GC.plan.summary.humans = ParseNumber(fields[5], 0); GC.plan.summary.total = ParseNumber(fields[6], #GC.plan.members)
        if not GC.plan.valid then GC.pendingCommand = nil end
        GC:Fire("STATUS", GC.plan.valid and "Roster selected. Preparing selected bots..." or "Roster needs attention.")
    elseif kind == "DONE" then
        local completed = GC.pendingCommand
        GC.pendingCommand = nil
        if completed == "teleport" then
            GC:SetProgress("DONE", tonumber(GC.plan.summary.total) or #GC.plan.members, tonumber(GC.plan.summary.total) or #GC.plan.members, fields[2] or "Entered selected instance.")
        end
        GC:Fire("STATUS", fields[2] or "Done.")
    elseif kind == "ERROR" then
        local failedCommand = GC.pendingCommand
        local hadValidPlan = GC.plan.ready and GC.plan.valid
        GC.pendingCommand = nil
        GC:AddWarningOnce(fields[2] or "Server error")
        GC:SetProgress("ERROR", GC.progress and GC.progress.current or 0, GC.progress and GC.progress.total or 0, fields[2] or "Server error")
        -- An action failure (queue, move, diagnostics, assembly timeout) does not make the
        -- previously validated composition structurally invalid. Only a failed Find/build does.
        if failedCommand == "find" or not hadValidPlan then
            GC.plan.valid = false
            GC.plan.ready = true
        end
        GC:Fire("STATUS", fields[2] or "Server error")
    end

    -- META/MEMBER/COVERAGE/WARN form one multipart server snapshot. Rendering after every
    -- member makes a 25/40-player preview rebuild its roster frames dozens of times and causes
    -- visible hitching plus unnecessary hidden-frame churn on the 3.3.5a client. RESET clears
    -- the previous preview immediately; READY publishes the complete new snapshot once.
    if kind == "RESET" or kind == "READY" or kind == "ERROR" then
        GC:Fire("PLAN_CHANGED", GC.plan)
    end
    return true
end

local function SystemFilter(_, _, message, ...)
    if GC:HandleProtocolMessage(message) then return true end
    return false, message, ...
end

function GC:ScanHumans()
    if GC.anchorsReady then
        local out = {}
        local config = GC:GetConfig()
        for _, anchor in ipairs(GC.anchors) do
            out[#out + 1] = {
                name = anchor.name, class = anchor.class, subgroup = anchor.subgroup,
                isPlayer = anchor.isPlayer, online = anchor.online, level = anchor.level,
                role = config.humanRoles[anchor.name] or anchor.role or "AUTO",
            }
        end
        return out
    end

    -- Short client-side fallback while the authoritative server query is in flight. The backend
    -- replaces this immediately and is the only layer that distinguishes real humans from Playerbots.
    local name = UnitName("player")
    local _, classToken = UnitClass("player")
    if not name then return {} end
    return { {
        name = name, class = classToken or "UNKNOWN", subgroup = 1, isPlayer = true, online = true,
        level = UnitLevel("player") or 1, role = GC:GetConfig().humanRoles[name] or "AUTO",
    } }
end

local function IsStableProfileMember(config, member)
    if not member or not member.name then return false end
    if member.human then return true end
    local key = string.lower(member.name)
    for _, pin in ipairs(config.pinned or {}) do if string.lower(pin.name) == key then return true end end
    return false
end

function GC:CaptureStableArrangement()
    -- If the user edits/saves a loaded profile before searching, keep its saved layout intact.
    -- Only replace arrangement data with a fresh snapshot once a real server plan exists.
    if not GC.plan or not GC.plan.ready then return end
    local config, arrangement = GC:GetConfig(), {}
    for _, member in ipairs(GC.plan.members or {}) do
        if IsStableProfileMember(config, member) and member.subgroup and member.subgroup >= 1 and member.subgroup <= 8 then
            arrangement[member.name] = member.subgroup
        end
    end
    config.arrangement = arrangement
end

function GC:SaveProfile(name)
    GC:CaptureStableArrangement()
    local ok, err = P.Save(name, GC:GetConfig())
    if ok then
        GC.db.lastProfile = P.CleanName(name); GC:Fire("PROFILES_CHANGED"); GC:Fire("STATUS", "Saved profile: " .. tostring(GC.db.lastProfile))
    else GC:Fire("STATUS", err) end
    return ok, err
end

function GC:LoadProfile(name)
    local profile = P.Get(name)
    if not profile then GC:Fire("STATUS", "Profile not found: " .. tostring(name)); return false end
    GC:SetConfig(profile, name); GC:Fire("STATUS", "Loaded profile: " .. name); return true
end

function GC:DeleteProfile(name)
    local ok, err = P.Delete(name)
    if ok then GC:Fire("PROFILES_CHANGED"); GC:Fire("STATUS", "Deleted profile: " .. name) else GC:Fire("STATUS", err) end
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
        GC.config = (GC.db.lastProfile and P.Get(GC.db.lastProfile)) or P.New(GC.db.lastMode)
        if ChatFrame_AddMessageEventFilter then ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", SystemFilter) end
        GC:Fire("CONFIG_CHANGED", GC.config, GC.db.lastProfile)
    elseif event == "PLAYER_LOGIN" then
        GC:Fire("PLAYER_READY")
        GC:RequestAnchors()
        GC:RequestActivities(GC:GetConfig().mode)
        GC:RequestJourney()
    elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        GC:RequestAnchors()
    elseif event == "DISPLAY_SIZE_CHANGED" then
        GC:Fire("DISPLAY_CHANGED")
    end
end)

SLASH_GROUPCOMPOSER1 = "/gc"
SLASH_GROUPCOMPOSER2 = "/groupcomposer"
SlashCmdList.GROUPCOMPOSER = function(msg)
    msg = string.lower(msg or "")
    if msg == "status" then GC:RequestStatus()
    elseif msg == "diag" or msg == "diagnostics" then GC:RequestDiagnostics()
    elseif msg == "anchors" then GC:RequestAnchors()
    elseif msg == "reset" then GC:SetConfig(P.New(GC:GetConfig().mode), nil)
    elseif msg == "debug" then
        local shell = (_G.GroupComposerModernUI and _G.GroupComposerModernUI.version) or "NOT_LOADED"
        local cfg = GC.config and "ready" or "nil"
        local toggle = GC.Toggle and "ready" or "nil"
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff58a6ffGroup Composer|r debug: shell=" .. shell .. " config=" .. cfg .. " toggle=" .. toggle)
        end
    elseif GC.Toggle then
        GC:Toggle()
    elseif DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff5555Group Composer UI shell did not load.|r Run |cffffff00/gc debug|r.")
    end
end
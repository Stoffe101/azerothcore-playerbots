GroupComposerProfiles = GroupComposerProfiles or {}
local P = GroupComposerProfiles
local D = GroupComposerData

local function DeepCopy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k, v in pairs(value) do copy[DeepCopy(k)] = DeepCopy(v) end
    return copy
end
P.DeepCopy = DeepCopy

local function DefaultsFor(mode, size)
    local tanks, healers, dps = D.DefaultRolesForSize(size or (mode == "DUNGEON" and 5 or 25))
    return {
        mode = mode or "DUNGEON",
        activity = mode == "RAID" and "icecrown" or "random",
        difficulty = mode == "RAID" and "normal" or "heroic",
        size = size or (mode == "DUNGEON" and 5 or 25),
        tanks = tanks,
        healers = healers,
        dps = dps,
        options = {
            preferGuild = true,
            fillWorld = true,
            keepMe = true,
            balanceClasses = true,
            avoidDuplicateClasses = false,
            minimumItemLevel = 0,
        },
        preferences = {
            TANK = {},
            HEALER = {},
            DPS = {},
        },
        pinned = {},
        arrangement = {},
    }
end
P.DefaultsFor = DefaultsFor

function P.Normalize(profile)
    local p = DeepCopy(profile or {})
    local mode = p.mode == "RAID" and "RAID" or "DUNGEON"
    local size = tonumber(p.size) or (mode == "RAID" and 25 or 5)
    local base = DefaultsFor(mode, size)

    for k, v in pairs(base) do
        if p[k] == nil then p[k] = DeepCopy(v) end
    end
    for k, v in pairs(base.options) do
        if p.options[k] == nil then p.options[k] = v end
    end
    for _, role in ipairs({ "TANK", "HEALER", "DPS" }) do
        if type(p.preferences[role]) ~= "table" then p.preferences[role] = {} end
    end

    p.size = math.max(1, math.min(40, tonumber(p.size) or size))
    p.tanks = math.max(0, tonumber(p.tanks) or 0)
    p.healers = math.max(0, tonumber(p.healers) or 0)
    p.dps = math.max(0, tonumber(p.dps) or 0)
    p.options.minimumItemLevel = math.max(0, tonumber(p.options.minimumItemLevel) or 0)
    return p
end

function P.InitializeDB()
    GroupComposerDB = GroupComposerDB or {}
    local db = GroupComposerDB
    db.version = db.version or 1
    db.profiles = db.profiles or {}
    db.window = db.window or {}
    db.window.point = db.window.point or { "CENTER", "UIParent", "CENTER", 0, 0 }
    db.window.userScale = tonumber(db.window.userScale) or 1.0
    db.window.autoScale = db.window.autoScale ~= false
    db.lastProfile = db.lastProfile or nil
    db.lastMode = db.lastMode == "RAID" and "RAID" or "DUNGEON"
    return db
end

function P.ListBuiltins()
    local out = {}
    for _, profile in ipairs(D.BUILTIN_PROFILES) do
        out[#out + 1] = profile.name
    end
    table.sort(out)
    return out
end

function P.ListCustom()
    local out = {}
    local db = P.InitializeDB()
    for name in pairs(db.profiles) do out[#out + 1] = name end
    table.sort(out)
    return out
end

function P.GetBuiltin(name)
    for _, profile in ipairs(D.BUILTIN_PROFILES) do
        if profile.name == name then
            local p = P.Normalize(profile)
            p.name = profile.name
            p.builtin = true
            return p
        end
    end
end

function P.Get(name)
    if not name or name == "" then return nil end
    local builtin = P.GetBuiltin(name)
    if builtin then return builtin end
    local db = P.InitializeDB()
    if not db.profiles[name] then return nil end
    local p = P.Normalize(db.profiles[name])
    p.name = name
    p.builtin = false
    return p
end

function P.Save(name, profile)
    if not name or name == "" then return false, "Profile name cannot be empty." end
    if P.GetBuiltin(name) then return false, "Built-in profiles cannot be overwritten. Use a different name." end
    local db = P.InitializeDB()
    local p = P.Normalize(profile)
    p.name = nil
    p.builtin = nil
    db.profiles[name] = p
    db.lastProfile = name
    return true
end

function P.Delete(name)
    local db = P.InitializeDB()
    if not name or not db.profiles[name] then return false, "Only custom profiles can be deleted." end
    db.profiles[name] = nil
    if db.lastProfile == name then db.lastProfile = nil end
    return true
end

function P.New(mode)
    return P.Normalize(DefaultsFor(mode or "DUNGEON", mode == "RAID" and 25 or 5))
end

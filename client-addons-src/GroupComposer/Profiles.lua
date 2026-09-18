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

local function CleanName(value)
    if type(value) ~= "string" then return nil end
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    value = string.gsub(value, "[|\r\n]", "")
    if value == "" then return nil end
    return value
end
P.CleanName = CleanName

local function DefaultsFor(mode, size)
    mode = mode == "RAID" and "RAID" or "DUNGEON"
    size = tonumber(size) or (mode == "DUNGEON" and 5 or 25)
    local tanks, healers, dps = D.DefaultRolesForSize(size)
    return {
        mode = mode,
        activity = mode == "RAID" and "icecrown" or "random",
        difficulty = mode == "RAID" and "normal" or "heroic",
        size = size,
        tanks = tanks,
        healers = healers,
        dps = dps,
        options = {
            preferGuild = true,
            fillWorld = true,
            keepMe = true,
            balanceClasses = true,
            balanceUtility = true,
            balanceRange = true,
            avoidDuplicateClasses = false,
            minimumItemLevel = 0,
            queueAfterAssemble = false,
        },
        preferences = { TANK = {}, HEALER = {}, DPS = {} },
        humanRoles = {},
        extraHumans = {},
        pinned = {},
        stableHumans = {},
        arrangement = {},
    }
end
P.DefaultsFor = DefaultsFor

local function NormalizePreferences(p)
    p.preferences = type(p.preferences) == "table" and p.preferences or {}
    for _, role in ipairs({ "TANK", "HEALER", "DPS" }) do
        local src = type(p.preferences[role]) == "table" and p.preferences[role] or {}
        local out = {}
        for _, pref in ipairs(src) do
            if type(pref) == "table" and #out < 12 then
                out[#out + 1] = {
                    class = pref.class or "ANY",
                    spec = pref.spec == nil and "ANY" or pref.spec,
                    required = pref.required and true or false,
                }
            end
        end
        p.preferences[role] = out
    end
end

local function NormalizeHumanRoles(p)
    local out = {}
    if type(p.humanRoles) == "table" then
        for name, role in pairs(p.humanRoles) do
            local clean = CleanName(name)
            if clean and (role == "TANK" or role == "HEALER" or role == "DPS") then out[clean] = role end
        end
    end
    p.humanRoles = out
end

local function NormalizeExtraHumans(p)
    local out, seen = {}, {}
    if type(p.extraHumans) == "table" then
        for _, entry in ipairs(p.extraHumans) do
            if type(entry) == "table" then
                local name = CleanName(entry.name)
                local role = entry.role
                local key = name and string.lower(name) or nil
                if name and key and not seen[key] and (role == "TANK" or role == "HEALER" or role == "DPS") then
                    seen[key] = true
                    out[#out + 1] = { name = name, role = role }
                end
            end
        end
    end
    p.extraHumans = out
end

local function NormalizePins(p)
    local out, seen = {}, {}
    if type(p.pinned) == "table" then
        for _, entry in ipairs(p.pinned) do
            if type(entry) == "table" then
                local name = CleanName(entry.name)
                local role = entry.role
                local key = name and string.lower(name) or nil
                if name and key and not seen[key] and (role == "TANK" or role == "HEALER" or role == "DPS") then
                    seen[key] = true
                    out[#out + 1] = { name = name, role = role, required = entry.required and true or false }
                end
            end
        end
    end
    p.pinned = out
end

local function NormalizeStableHumans(p)
    local out, seen = {}, {}
    if type(p.stableHumans) == "table" then
        for _, value in ipairs(p.stableHumans) do
            local name = type(value) == "table" and CleanName(value.name) or CleanName(value)
            local key = name and string.lower(name) or nil
            if name and key and not seen[key] and #out < 40 then
                seen[key] = true
                out[#out + 1] = name
            end
        end
    end
    p.stableHumans = out
end

local function StableNameSet(p)
    local stable = {}
    for name in pairs(p.humanRoles or {}) do stable[string.lower(name)] = true end
    for _, name in ipairs(p.stableHumans or {}) do stable[string.lower(name)] = true end
    for _, entry in ipairs(p.extraHumans or {}) do stable[string.lower(entry.name)] = true end
    for _, entry in ipairs(p.pinned or {}) do stable[string.lower(entry.name)] = true end
    return stable
end

local function NormalizeArrangement(p)
    local out = {}
    local stable = StableNameSet(p)
    if type(p.arrangement) == "table" then
        for name, subgroup in pairs(p.arrangement) do
            local clean = CleanName(name)
            local group = tonumber(subgroup)
            if clean and group and group >= 1 and group <= 8 and stable[string.lower(clean)] then
                out[clean] = math.floor(group)
            end
        end
    end
    p.arrangement = out
end

function P.Normalize(profile)
    local p = DeepCopy(profile or {})
    local mode = p.mode == "RAID" and "RAID" or "DUNGEON"
    local size = tonumber(p.size) or (mode == "RAID" and 25 or 5)
    local base = DefaultsFor(mode, size)

    for k, v in pairs(base) do if p[k] == nil then p[k] = DeepCopy(v) end end
    p.options = type(p.options) == "table" and p.options or {}
    for k, v in pairs(base.options) do if p.options[k] == nil then p.options[k] = v end end

    p.mode = mode
    p.size = math.max(1, math.min(40, math.floor(tonumber(p.size) or size)))
    p.tanks = math.max(0, math.floor(tonumber(p.tanks) or 0))
    p.healers = math.max(0, math.floor(tonumber(p.healers) or 0))
    p.dps = math.max(0, math.floor(tonumber(p.dps) or 0))
    p.options.minimumItemLevel = math.max(0, math.min(1000, math.floor(tonumber(p.options.minimumItemLevel) or 0)))
    p.options.keepMe = true

    NormalizePreferences(p)
    NormalizeHumanRoles(p)
    NormalizeExtraHumans(p)
    NormalizePins(p)
    NormalizeStableHumans(p)
    NormalizeArrangement(p)
    return p
end

function P.InitializeDB()
    GroupComposerDB = GroupComposerDB or {}
    local db = GroupComposerDB
    local oldVersion = tonumber(db.version) or 0
    db.version = 3
    db.profiles = type(db.profiles) == "table" and db.profiles or {}
    db.window = type(db.window) == "table" and db.window or {}
    db.window.point = db.window.point or { "CENTER", "UIParent", "CENTER", 0, 0 }
    db.window.userScale = tonumber(db.window.userScale) or 1.0
    db.window.autoScale = db.window.autoScale ~= false
    db.window.advancedPoint = db.window.advancedPoint or { "CENTER", "UIParent", "CENTER", 0, 0 }
    db.window.advancedTab = db.window.advancedTab or "PEOPLE"
    db.lastProfile = db.lastProfile or nil
    db.lastMode = db.lastMode == "RAID" and "RAID" or "DUNGEON"

    if oldVersion < 3 then
        for name, profile in pairs(db.profiles) do db.profiles[name] = P.Normalize(profile) end
    end
    return db
end

function P.ListBuiltins()
    local out = {}
    for _, profile in ipairs(D.BUILTIN_PROFILES) do out[#out + 1] = profile.name end
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

function P.Describe(name)
    local profile = P.Get and P.Get(name) or nil
    if not profile then
        for _, builtin in ipairs(D.BUILTIN_PROFILES or {}) do
            if builtin.name == name then profile = P.Normalize(builtin); break end
        end
    end
    if not profile then return "" end

    local exact = 0
    for _, role in ipairs({ "TANK", "HEALER", "DPS" }) do
        for _, pref in ipairs((profile.preferences and profile.preferences[role]) or {}) do
            if pref.required then exact = exact + 1 end
        end
    end

    local prefix = tostring(profile.size or "?") .. "-player · " ..
        tostring(profile.tanks or 0) .. "T / " .. tostring(profile.healers or 0) .. "H / " .. tostring(profile.dps or 0) .. "D"
    local detail = profile.description or (exact > 0 and (tostring(exact) .. " reserved builds + Auto remainder") or "Role targets + Auto fill")
    return prefix .. " · " .. detail
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
    name = CleanName(name)
    if not name then return false, "Profile name cannot be empty." end
    if string.len(name) > 40 then return false, "Profile names are limited to 40 characters." end
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
    mode = mode == "RAID" and "RAID" or "DUNGEON"
    return P.Normalize(DefaultsFor(mode, mode == "RAID" and 25 or 5))
end

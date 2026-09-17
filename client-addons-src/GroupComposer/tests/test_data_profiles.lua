-- Pure Lua 5.1 tests for Group Composer's data/profile layer.
-- No WoW client API is required, so CI can catch schema/syntax regressions cheaply.

dofile("client-addons-src/GroupComposer/Data.lua")
dofile("client-addons-src/GroupComposer/Profiles.lua")

local D = GroupComposerData
local P = GroupComposerProfiles

local function eq(actual, expected, label)
    if actual ~= expected then error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2) end
end

local function truth(value, label)
    if not value then error(label or "expected truthy value", 2) end
end

local tocFile = assert(io.open("client-addons-src/GroupComposer/GroupComposer.toc", "r"))
local toc = tocFile:read("*a")
tocFile:close()
local tocVersion = string.match(toc, "## Version:%s*([^\r\n]+)")
eq(D.VERSION, tocVersion, "runtime/package version")

eq(#D.CLASS_ORDER, 10, "WotLK class count")
truth(not D.CLASS_ID.MONK, "Monk must not exist")
truth(not D.CLASS_ID.DEMONHUNTER, "Demon Hunter must not exist")
truth(not D.CLASS_ID.EVOKER, "Evoker must not exist")

for _, size in ipairs({ 5, 10, 20, 25, 40 }) do
    local tanks, healers, dps = D.DefaultRolesForSize(size)
    eq(tanks + healers + dps, size, "role total for size " .. size)
end
local t25, h25, d25 = D.DefaultRolesForSize(25)
eq(t25, 2, "25-player tanks")
eq(h25, 6, "25-player healers")
eq(d25, 17, "25-player dps")

truth(D.GetRaidById("icecrown").heroic, "ICC heroic")
truth(D.GetRaidById("trial_crusader").heroic, "ToC heroic")
truth(D.GetRaidById("ruby_sanctum").heroic, "RS heroic")
truth(not D.GetRaidById("ulduar").heroic, "Ulduar separate heroic must remain false")
truth(not D.GetRaidById("naxxramas").heroic, "Naxx separate heroic must remain false")

local names = {}
for _, profile in ipairs(D.BUILTIN_PROFILES) do
    truth(profile.name and profile.name ~= "", "built-in profile name")
    truth(not names[profile.name], "duplicate built-in profile name: " .. profile.name)
    names[profile.name] = true
    eq(profile.tanks + profile.healers + profile.dps, profile.size, "profile total: " .. profile.name)
    if profile.mode == "RAID" then
        local raid = D.GetRaidById(profile.activity)
        truth(raid, "unknown raid in profile: " .. profile.name)
        local supported = false
        for _, size in ipairs(raid.sizes) do if size == profile.size then supported = true end end
        truth(supported, "unsupported raid size in profile: " .. profile.name)
        if profile.difficulty == "heroic" then truth(raid.heroic, "invalid heroic profile: " .. profile.name) end
    else
        truth(D.GetDungeonById(profile.activity), "unknown dungeon in profile: " .. profile.name)
        eq(profile.size, 5, "dungeon profile size")
    end
end

local migrated = P.Normalize({
    mode = "RAID", activity = "icecrown", difficulty = "normal", size = 25,
    tanks = 2, healers = 6, dps = 17,
    options = { preferGuild = false, keepMe = false },
    preferences = { TANK = {}, HEALER = {}, DPS = {} },
})
eq(migrated.options.preferGuild, false, "explicit option preserved")
eq(migrated.options.balanceUtility, true, "new utility option default")
eq(migrated.options.balanceRange, true, "new range option default")
eq(migrated.options.keepMe, true, "local player is immutable")
truth(type(migrated.humanRoles) == "table", "humanRoles default")
truth(type(migrated.extraHumans) == "table", "extraHumans default")
truth(type(migrated.pinned) == "table", "pinned default")
truth(type(migrated.stableHumans) == "table", "stableHumans default")
truth(type(migrated.arrangement) == "table", "arrangement default")

local normalized = P.Normalize({
    mode = "RAID", activity = "icecrown", difficulty = "normal", size = 10,
    tanks = 2, healers = 2, dps = 6,
    humanRoles = { Stoffe = "TANK" },
    stableHumans = { "FriendWithoutOverride" },
    pinned = { { name = "Stonewall", role = "TANK", required = true } },
    arrangement = { Stoffe = 1, FriendWithoutOverride = 1, Stonewall = 2, Disposablebot = 2 },
})
eq(normalized.arrangement.Stoffe, 1, "human override arrangement")
eq(normalized.arrangement.FriendWithoutOverride, 1, "auto human arrangement")
eq(normalized.arrangement.Stonewall, 2, "pin arrangement")
truth(normalized.arrangement.Disposablebot == nil, "transient bot arrangement must be discarded")
eq(#normalized.stableHumans, 1, "stable human count")
eq(normalized.stableHumans[1], "FriendWithoutOverride", "stable human name")

local deduped = P.Normalize({
    mode = "DUNGEON", activity = "random", difficulty = "heroic", size = 5,
    tanks = 1, healers = 1, dps = 3,
    stableHumans = { "Alice", "alice", "Bob" },
    arrangement = { Alice = 1, Bob = 9 },
})
eq(#deduped.stableHumans, 2, "stable human dedupe")
eq(deduped.arrangement.Alice, 1, "valid subgroup retained")
truth(deduped.arrangement.Bob == nil, "invalid subgroup discarded")

print("Group Composer data/profile tests passed")

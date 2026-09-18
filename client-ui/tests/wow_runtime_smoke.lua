local bundle = assert(arg[1], "expected generated bundle path")

local callbacks = {}
local function noop() end

local Region = {}
Region.__index = Region
function Region:SetSize(w, h) self.w, self.h = w, h end
function Region:SetWidth(w) self.w = w end
function Region:SetHeight(h) self.h = h end
function Region:GetWidth() return self.w or 1920 end
function Region:GetHeight() return self.h or 1080 end
function Region:SetPoint(...) self.point = {...} end
function Region:ClearAllPoints() self.point = nil end
function Region:SetAllPoints(...) end
function Region:SetAlpha(a) self.alpha = a end
function Region:SetScale(s) self.scale = s end
function Region:Show() self.shown = true end
function Region:Hide() self.shown = false end
function Region:IsShown() return self.shown == true end
function Region:SetTexture(...) self.texture = {...} end
function Region:SetTexCoord(...) self.tex = {...} end
function Region:SetVertexColor(...) self.vertex = {...} end
function Region:SetText(v) self.text = tostring(v or "") end
function Region:GetText() return self.text or "" end
function Region:SetTextColor(...) self.textColor = {...} end
function Region:SetJustifyH(v) self.justifyH = v end
function Region:SetJustifyV(v) self.justifyV = v end
function Region:SetAutoFocus(v) self.autofocus = v end
function Region:SetTextInsets(...) self.insets = {...} end
function Region:ClearFocus() end
function Region:HighlightText(...) end
function Region:EnableMouse(v) self.mouse = v end
function Region:EnableMouseWheel(v) self.wheel = v end
function Region:SetFrameStrata(v) self.strata = v end
function Region:SetFrameLevel(v) self.level = v end
function Region:GetFrameLevel() return self.level or 1 end
function Region:SetMovable(v) self.movable = v end
function Region:SetClampedToScreen(v) self.clamped = v end
function Region:RegisterForDrag(...) end
function Region:StartMoving() end
function Region:StopMovingOrSizing() end
function Region:SetScrollChild(child) self.scrollChild = child end
function Region:GetVerticalScroll() return self.scroll or 0 end
function Region:GetVerticalScrollRange()
    local child = self.scrollChild
    if not child then return 0 end
    return math.max(0, (child.h or 0) - (self.h or 0))
end
function Region:SetVerticalScroll(v) self.scroll = v end
function Region:SetScript(name, fn) self.scripts = self.scripts or {}; self.scripts[name] = fn end
function Region:CreateTexture()
    local r = setmetatable({shown = true}, Region)
    return r
end
function Region:CreateFontString()
    local r = setmetatable({shown = true, text = ""}, Region)
    return r
end

function CreateFrame(frameType)
    return setmetatable({type = frameType, shown = true, scripts = {}, w = 0, h = 0, text = ""}, Region)
end

UIParent = CreateFrame("Frame")
UIParent.w, UIParent.h = 1920, 1080
UISpecialFrames = {}

CLASS_ICON_TCOORDS = {
    WARRIOR = {0, 0.25, 0, 0.25},
    PALADIN = {0.25, 0.5, 0, 0.25},
    HUNTER = {0.5, 0.75, 0, 0.25},
    ROGUE = {0.75, 1, 0, 0.25},
    PRIEST = {0, 0.25, 0.25, 0.5},
    DEATHKNIGHT = {0.25, 0.5, 0.25, 0.5},
    SHAMAN = {0.5, 0.75, 0.25, 0.5},
    MAGE = {0.75, 1, 0.25, 0.5},
    WARLOCK = {0, 0.25, 0.5, 0.75},
    DRUID = {0.25, 0.5, 0.5, 0.75},
}

RAID_CLASS_COLORS = {}

local cfg = {
    mode = "DUNGEON",
    activity = "random",
    difficulty = "heroic",
    size = 5,
    tanks = 1,
    healers = 1,
    dps = 3,
    humanRoles = {},
    extraHumans = {},
    pinned = {},
    preferences = { TANK = {}, HEALER = {}, DPS = {} },
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
}

local human = {
    name = "RuntimeTest",
    class = "DEATHKNIGHT",
    subgroup = 1,
    isPlayer = true,
    online = true,
    role = "AUTO",
}

GroupComposerData = {
    ROLE_ICON = {
        TANK = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
        HEALER = "Interface\\Icons\\Spell_Holy_GreaterHeal",
        DPS = "Interface\\Icons\\Ability_DualWield",
    },
    CLASS_ROLE = {
        TANK = { WARRIOR=true, PALADIN=true, DEATHKNIGHT=true, DRUID=true },
        HEALER = { PALADIN=true, PRIEST=true, SHAMAN=true, DRUID=true },
        DPS = { WARRIOR=true, PALADIN=true, HUNTER=true, ROGUE=true, PRIEST=true, DEATHKNIGHT=true, SHAMAN=true, MAGE=true, WARLOCK=true, DRUID=true },
    },
    DUNGEONS = {
        { id = "random", label = "Random Dungeon" },
        { id = "nexus", label = "The Nexus" },
    },
    DUNGEON_DIFFICULTIES = {
        { id = "normal", label = "Normal" },
        { id = "heroic", label = "Heroic" },
        { id = "alpha", label = "Titan Rune Alpha" },
    },
    RAIDS = {
        { id = "icecrown", label = "Icecrown Citadel", era = "WotLK", sizes = {10,25}, heroic = true },
        { id = "molten_core", label = "Molten Core", era = "Classic", sizes = {40}, heroic = false },
    },
}
function GroupComposerData.GetDungeonById(id)
    for _, d in ipairs(GroupComposerData.DUNGEONS) do if d.id == id then return d end end
end
function GroupComposerData.GetRaidById(id)
    for _, r in ipairs(GroupComposerData.RAIDS) do if r.id == id then return r end end
end

GroupComposerProfiles = {}
function GroupComposerProfiles.ListBuiltins() return {"Dungeon - Standard", "ICC 25 - Standard"} end
function GroupComposerProfiles.ListCustom() return {"My Raid"} end

GroupComposer = {
    backendSeen = true,
    config = nil,
    plan = { members = {}, warnings = {}, valid = false, ready = false, summary = {} },
    progress = { phase = "IDLE", current = 0, total = 0, detail = "Configure a roster to begin." },
}

function GroupComposer:GetConfig() return self.config end
function GroupComposer:ScanHumans() return {human} end
function GroupComposer:Touch(reason)
    self.plan = { members = {}, warnings = {}, valid = false, ready = false, summary = {}, reason = reason }
    self.progress = { phase = "IDLE", current = 0, total = 0, detail = reason or "" }
end
function GroupComposer:SetMode(mode)
    cfg.mode = mode
    if mode == "RAID" then
        cfg.activity, cfg.size, cfg.tanks, cfg.healers, cfg.dps = "icecrown", 25, 2, 6, 17
    else
        cfg.activity, cfg.size, cfg.tanks, cfg.healers, cfg.dps = "random", 5, 1, 1, 3
    end
end
function GroupComposer:SetDungeonActivity(id) cfg.activity = id end
function GroupComposer:SetRaidActivity(id) cfg.activity = id end
function GroupComposer:SetRaidSize(size) cfg.size = size end
function GroupComposer:SetHumanRole(name, role) cfg.humanRoles[name] = role end
function GroupComposer:FindRoster() end
function GroupComposer:Assemble() end
function GroupComposer:RequestAnchors() end
function GroupComposer:RequestStatus() end
function GroupComposer:ClearServerPlan() self:Touch("Cleared") end
function GroupComposer:LoadProfile() end
function GroupComposer:SaveProfile() end
function GroupComposer:DeleteProfile() end
function GroupComposer:AddPinnedMember(name, role, required)
    table.insert(cfg.pinned, {name=name, role=role, required=required})
end
function GroupComposer:RemovePinnedMember(index) table.remove(cfg.pinned, index) end
function GroupComposer:RegisterCallback(event, fn)
    callbacks[event] = callbacks[event] or {}
    table.insert(callbacks[event], fn)
end
function GroupComposer:Fire(event, ...)
    for _, fn in ipairs(callbacks[event] or {}) do fn(...) end
end

dofile(bundle)

assert(type(GroupComposerModernUI) == "table", "modern UI API missing")
assert(GroupComposerModernUI.dashboard == nil, "dashboard must defer creation until Core initializes config")
assert(type(GroupComposer.Toggle) == "function", "lazy /gc toggle was not installed")

-- Reproduce the real Core.lua order: config becomes available only after every TOC file
-- has loaded. The slash command then calls GC:Toggle(), which lazily creates the dashboard.
GroupComposer.config = cfg
GroupComposer:Fire("CONFIG_CHANGED", cfg)
assert(GroupComposerModernUI.dashboard == nil, "dashboard should remain lazy until /gc is invoked")

GroupComposer:Toggle()
assert(type(GroupComposerModernUI.dashboard) == "table", "modern dashboard did not initialize from lazy /gc toggle")
assert(GroupComposerModernUI.dashboard.frame:IsShown(), "lazy /gc toggle did not show the dashboard")
assert(GroupComposerModernUI.dashboard.frame:IsShown(), "dashboard should be visible after show")

cfg.humanRoles.RuntimeTest = "DPS"
GroupComposer:Fire("CONFIG_CHANGED", cfg)

cfg.mode = "RAID"
cfg.activity = "icecrown"
cfg.size = 25
cfg.tanks, cfg.healers, cfg.dps = 2, 6, 17
GroupComposer.plan = {
    valid = true,
    ready = true,
    warnings = {},
    summary = { total = 25, guild = 20, world = 4, utility = "Coverage ready", ranged = 9, melee = 8 },
    members = {
        { subgroup=1, name="RuntimeTest", role="DPS", class="DEATHKNIGHT", spec="Unholy", source="HUMAN", human=true, isPlayer=true },
        { subgroup=1, name="Tankbot", role="TANK", class="PALADIN", spec="Protection", source="GUILD", human=false, isPlayer=false },
        { subgroup=1, name="Healbot", role="HEALER", class="PRIEST", spec="Holy", source="GUILD", human=false, isPlayer=false },
    },
}
GroupComposer.progress = { phase = "READY", current = 24, total = 24, detail = "Prepared roster is ready." }
GroupComposer:Fire("PLAN_CHANGED", GroupComposer.plan)
GroupComposer:Fire("PROGRESS_CHANGED", GroupComposer.progress)

GroupComposerModernUI.dashboard.refresh()
GroupComposerModernUI.dashboard.hide()
assert(not GroupComposerModernUI.dashboard.frame:IsShown(), "dashboard should hide cleanly")

print("Group Composer WoW runtime smoke test passed")

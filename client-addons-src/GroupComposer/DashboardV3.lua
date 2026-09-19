local GC = GroupComposer
local D = GroupComposerData
local P = GroupComposerProfiles

GC.DashboardV3 = GC.DashboardV3 or {}
local U = GC.DashboardV3

local C = {
    bg = {0.018, 0.024, 0.034, 0.995}, chrome = {0.025, 0.033, 0.047, 1},
    sidebar = {0.028, 0.040, 0.055, 1}, panel = {0.040, 0.053, 0.071, 1},
    panel2 = {0.052, 0.069, 0.092, 1}, panel3 = {0.068, 0.088, 0.116, 1},
    line = {0.16, 0.22, 0.30, 1}, lineSoft = {0.11, 0.16, 0.22, 1},
    blue = {0.20, 0.60, 1.00, 1}, blueSoft = {0.07, 0.19, 0.31, 1},
    green = {0.20, 0.86, 0.45, 1}, greenSoft = {0.05, 0.22, 0.12, 1},
    red = {0.98, 0.29, 0.34, 1}, redSoft = {0.25, 0.055, 0.07, 1},
    gold = {1.00, 0.71, 0.20, 1}, goldSoft = {0.24, 0.16, 0.04, 1},
    text = {0.94, 0.97, 1.00, 1}, muted = {0.66, 0.73, 0.82, 1},
    dim = {0.43, 0.50, 0.60, 1}, black = {0, 0, 0, 1},
}
local ROLE_COLOR = { TANK = C.blue, HEALER = C.green, DPS = C.red }
local ROLE_SHORT = { TANK = "T", HEALER = "H", DPS = "D" }
local ENCOUNTER_READY_RAIDS = {
    obsidian_sanctum = true, eye_of_eternity = true, onyxia = true,
    icecrown = true, ruby_sanctum = true, gruul = true, magtheridon = true,
}
local function EncounterReadyRaid(id)
    return id and ENCOUNTER_READY_RAIDS[id] and true or false
end

local SPEC_ICON = {
    WARRIOR = {"Interface\\Icons\\Ability_Warrior_SavageBlow", "Interface\\Icons\\Ability_Warrior_InnerRage", "Interface\\Icons\\Ability_Warrior_DefensiveStance"},
    PALADIN = {"Interface\\Icons\\Spell_Holy_HolyBolt", "Interface\\Icons\\Spell_Holy_DevotionAura", "Interface\\Icons\\Spell_Holy_AuraOfLight"},
    HUNTER = {"Interface\\Icons\\Ability_Hunter_BeastCall", "Interface\\Icons\\Ability_Marksmanship", "Interface\\Icons\\Ability_Hunter_SwiftStrike"},
    ROGUE = {"Interface\\Icons\\Ability_Rogue_Eviscerate", "Interface\\Icons\\Ability_BackStab", "Interface\\Icons\\Ability_Stealth"},
    PRIEST = {"Interface\\Icons\\Spell_Holy_PowerWordShield", "Interface\\Icons\\Spell_Holy_GuardianSpirit", "Interface\\Icons\\Spell_Shadow_ShadowWordPain"},
    DEATHKNIGHT = {"Interface\\Icons\\Spell_Deathknight_BloodPresence", "Interface\\Icons\\Spell_Deathknight_FrostPresence", "Interface\\Icons\\Spell_Deathknight_UnholyPresence"},
    SHAMAN = {"Interface\\Icons\\Spell_Nature_Lightning", "Interface\\Icons\\Spell_Nature_LightningShield", "Interface\\Icons\\Spell_Nature_HealingWaveGreater"},
    MAGE = {"Interface\\Icons\\Spell_Holy_MagicalSentry", "Interface\\Icons\\Spell_Fire_FireBolt02", "Interface\\Icons\\Spell_Frost_FrostBolt02"},
    WARLOCK = {"Interface\\Icons\\Spell_Shadow_DeathCoil", "Interface\\Icons\\Spell_Shadow_Metamorphosis", "Interface\\Icons\\Spell_Fire_Immolation"},
    DRUID = {"Interface\\Icons\\Spell_Nature_StarFall", "Interface\\Icons\\Ability_Druid_CatForm", "Interface\\Icons\\Spell_Nature_HealingTouch"},
}

local function Solid(parent, color, layer, alpha)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetTexture(color[1], color[2], color[3], alpha or color[4] or 1)
    return t
end

local function Text(parent, value, template, color)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    fs:SetText(value or "")
    local c = color or C.text
    fs:SetTextColor(c[1], c[2], c[3], c[4] or 1)
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("MIDDLE")
    return fs
end

local function Outline(parent, color)
    local top = Solid(parent, color or C.line, "BORDER"); top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(1)
    local bottom = Solid(parent, color or C.line, "BORDER"); bottom:SetPoint("BOTTOMLEFT"); bottom:SetPoint("BOTTOMRIGHT"); bottom:SetHeight(1)
    local left = Solid(parent, color or C.line, "BORDER"); left:SetPoint("TOPLEFT"); left:SetPoint("BOTTOMLEFT"); left:SetWidth(1)
    local right = Solid(parent, color or C.line, "BORDER"); right:SetPoint("TOPRIGHT"); right:SetPoint("BOTTOMRIGHT"); right:SetWidth(1)
    return {top, bottom, left, right}
end

local function Panel(parent, color, border)
    local f = CreateFrame("Frame", nil, parent)
    local bg = Solid(f, color or C.panel); bg:SetAllPoints(f); f.bg = bg
    f.border = Outline(f, border or C.lineSoft)
    return f
end

local function SetBorder(frame, color)
    if not frame.border then return end
    for _, tex in ipairs(frame.border) do tex:SetTexture(color[1], color[2], color[3], color[4] or 1) end
end

local function Button(parent, label, width, height, fn)
    local b = Panel(parent, C.panel2, C.line)
    b:SetWidth(width or 110); b:SetHeight(height or 30)
    b:EnableMouse(true)
    b.label = Text(b, label or "Button", "GameFontHighlight", C.text); b.label:SetPoint("CENTER")
    b.enabled = true
    b:SetScript("OnMouseDown", function(self) if self.enabled and fn then fn() end end)
    b:SetScript("OnEnter", function(self) if self.enabled then self.bg:SetTexture(C.panel3[1], C.panel3[2], C.panel3[3], 1) end end)
    b:SetScript("OnLeave", function(self) self.bg:SetTexture(C.panel2[1], C.panel2[2], C.panel2[3], 1) end)
    function b:SetEnabledState(on)
        self.enabled = on and true or false
        self:SetAlpha(self.enabled and 1 or 0.38)
    end
    function b:SetAccent(color, active)
        SetBorder(self, active and color or C.line)
        if active then
            self.bg:SetTexture(color[1] * 0.18, color[2] * 0.18, color[3] * 0.18, 1)
            self.label:SetTextColor(color[1], color[2], color[3], 1)
        else
            self.bg:SetTexture(C.panel2[1], C.panel2[2], C.panel2[3], 1)
            self.label:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
        end
    end
    return b
end

local function RoleBadge(parent, role, size)
    local color = ROLE_COLOR[role] or C.muted
    local f = Panel(parent, role == "TANK" and C.blueSoft or role == "HEALER" and C.greenSoft or C.redSoft, color)
    size = size or 30; f:SetWidth(size); f:SetHeight(size)
    local icon = f:CreateTexture(nil, "ARTWORK"); icon:SetAllPoints(f); icon:SetTexture(D.ROLE_ICON[role]); icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.icon = icon
    return f
end

local function ClassIcon(parent, classToken, size)
    local t = parent:CreateTexture(nil, "ARTWORK")
    size = size or 28; t:SetWidth(size); t:SetHeight(size)
    t:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
    local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classToken]
    if coords then t:SetTexCoord(coords[1], coords[2], coords[3], coords[4]) else t:SetTexCoord(0, 1, 0, 1) end
    return t
end

local function ClassColor(classToken)
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
    if c then return {c.r, c.g, c.b, 1} end
    return C.text
end

local function ClassCanRole(classToken, role)
    return classToken and role and D.CLASS_ROLE[role] and D.CLASS_ROLE[role][classToken] and true or false
end

local function PlayerSpec()
    local bestName, bestIndex, bestPoints = "Current build", nil, -1
    if not GetTalentTabInfo then return bestName, bestIndex end
    for i = 1, 3 do
        local ok, name, _, points = pcall(GetTalentTabInfo, i)
        if ok and name then
            points = tonumber(points) or 0
            if points > bestPoints then bestName, bestIndex, bestPoints = name, i - 1, points end
        end
    end
    return bestName, bestIndex
end

local function SpecsForRole(classToken, role, includeAny)
    local out = {}
    if includeAny then out[#out + 1] = {value = "ANY", label = "Any supported spec"} end
    for _, spec in ipairs(D.SPECS[classToken] or {}) do
        if spec.role == role or (role == "TANK" and spec.canTank) then out[#out + 1] = {value = spec.id, label = spec.label} end
    end
    return out
end

local function ClassesForRole(role, includeAny)
    local out = {}
    if includeAny then out[#out + 1] = {value = "ANY", label = "Any class"} end
    for _, token in ipairs(D.CLASS_ORDER) do
        if ClassCanRole(token, role) then out[#out + 1] = {value = token, label = D.CLASS_LABEL[token]} end
    end
    return out
end

local activeMenu
local function CloseMenu()
    if activeMenu then activeMenu:Hide(); activeMenu = nil end
end

local function Selector(parent, width, getItems, getValue, setValue)
    local b = Button(parent, "Select", width or 180, 30)
    b.label:ClearAllPoints(); b.label:SetPoint("LEFT", 10, 0); b.label:SetPoint("RIGHT", -24, 0); b.label:SetJustifyH("LEFT")
    b.arrow = Text(b, "v", "GameFontHighlightSmall", C.muted); b.arrow:SetPoint("RIGHT", -9, 0)
    local menu = Panel(b, C.bg, C.blue)
    menu:SetFrameStrata("TOOLTIP"); menu:SetWidth(width or 180); menu:Hide(); menu.rows = {}
    function b:Refresh()
        local value = getValue and getValue() or nil
        local label = "Select"
        for _, item in ipairs(getItems and getItems() or {}) do if item.value == value then label = item.label break end end
        self.label:SetText(label)
    end
    function b:Open()
        CloseMenu()
        local items = getItems and getItems() or {}
        for _, row in ipairs(menu.rows) do row:Hide() end
        local rowH = 25
        for i, item in ipairs(items) do
            local row = menu.rows[i]
            if not row then
                row = Button(menu, "", (width or 180) - 8, 23)
                row.label:ClearAllPoints(); row.label:SetPoint("LEFT", 8, 0); row.label:SetPoint("RIGHT", -6, 0); row.label:SetJustifyH("LEFT")
                menu.rows[i] = row
            end
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 4, -4 - ((i - 1) * rowH))
            row.label:SetText(item.label)
            local valueCopy = item.value
            row:SetScript("OnMouseDown", function()
                if setValue then setValue(valueCopy) end
                CloseMenu(); b:Refresh()
            end)
            row:Show()
        end
        menu:SetHeight(math.max(32, #items * rowH + 8)); menu:ClearAllPoints(); menu:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, -3)
        menu:Show(); activeMenu = menu
    end
    b:SetScript("OnMouseDown", function() if menu:IsShown() then CloseMenu() else b:Open() end end)
    b:Refresh()
    return b
end

local function Toggle(parent, label, getter, setter)
    local row = CreateFrame("Frame", nil, parent); row:SetHeight(28); row:EnableMouse(true)
    local box = Panel(row, C.bg, C.line); box:SetWidth(18); box:SetHeight(18); box:SetPoint("LEFT")
    local mark = Text(box, "✓", "GameFontNormal", C.green); mark:SetPoint("CENTER", 0, 1)
    local text = Text(row, label, "GameFontHighlightSmall", C.text); text:SetPoint("LEFT", box, "RIGHT", 8, 0)
    row.box, row.mark, row.text = box, mark, text
    function row:Refresh()
        local on = getter() and true or false
        if on then mark:Show(); SetBorder(box, C.green) else mark:Hide(); SetBorder(box, C.line) end
    end
    row:SetScript("OnMouseDown", function() setter(not getter()); row:Refresh() end)
    row:Refresh(); return row
end

local function SectionTitle(parent, title, subtitle, x, y)
    local a = Text(parent, title, "GameFontNormalLarge", C.text); a:SetPoint("TOPLEFT", x or 0, y or 0)
    if subtitle then
        local b = Text(parent, subtitle, "GameFontHighlightSmall", C.muted); b:SetPoint("TOPLEFT", a, "BOTTOMLEFT", 0, -3)
        return a, b
    end
    return a
end

local function HumanRows()
    return GC:ScanHumans() or {}
end

local function HumanRoleProblems()
    if GC.Policy and GC.Policy.HumanRoleProblems then return GC.Policy:HumanRoleProblems() end
    return {}
end

local function RemainingBotSlots(role)
    local config = GC:GetConfig()
    local target = role == "TANK" and (tonumber(config.tanks) or 0)
        or role == "HEALER" and (tonumber(config.healers) or 0)
        or (tonumber(config.dps) or 0)
    local humans = GC.Policy and GC.Policy.HumanRoleCounts and GC.Policy.HumanRoleCounts(config) or {}
    return math.max(0, target - (tonumber(humans[role]) or 0))
end

local function ExpandedRequired(role)
    local out = {}
    for _, pref in ipairs(GC:GetConfig().preferences[role] or {}) do
        if pref.required then out[#out + 1] = {class = pref.class or "ANY", spec = pref.spec == nil and "ANY" or pref.spec} end
    end
    return out
end

local function WriteRequired(role, slots)
    local list = {}
    for _, slot in ipairs(slots or {}) do
        if slot.class and slot.class ~= "ANY" then
            list[#list + 1] = {class = slot.class, spec = slot.spec == nil and "ANY" or slot.spec, required = true}
        end
    end
    GC:GetConfig().preferences[role] = list
    GC:Touch("Exact composition changed")
end

local function AggregatedRequired(role)
    local order, map = {}, {}
    for _, p in ipairs(ExpandedRequired(role)) do
        local key = tostring(p.class) .. ":" .. tostring(p.spec)
        if not map[key] then
            map[key] = {class = p.class, spec = p.spec, count = 0}; order[#order + 1] = key
        end
        map[key].count = map[key].count + 1
    end
    local out = {}; for _, key in ipairs(order) do out[#out + 1] = map[key] end
    return out
end

local function WriteAggregated(role, rows)
    local expanded = {}
    for _, row in ipairs(rows or {}) do
        local count = math.max(1, math.floor(tonumber(row.count) or 1))
        for i = 1, count do expanded[#expanded + 1] = {class = row.class, spec = row.spec} end
    end
    WriteRequired(role, expanded)
end

local frame = CreateFrame("Frame", "GroupComposerDashboardV3Frame", UIParent)
U.frame = frame
frame:SetWidth(1500); frame:SetHeight(900); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG")
frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton"); frame:SetClampedToScreen(true); frame:Hide()
local rootBg = Solid(frame, C.bg); rootBg:SetAllPoints(frame); frame.border = Outline(frame, C.line)
frame:SetScript("OnDragStart", frame.StartMoving); frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
UISpecialFrames = UISpecialFrames or {}; local inSpecial = false
for _, name in ipairs(UISpecialFrames) do if name == "GroupComposerDashboardV3Frame" then inSpecial = true end end
if not inSpecial then table.insert(UISpecialFrames, "GroupComposerDashboardV3Frame") end

local header = Panel(frame, C.chrome, C.lineSoft); header:SetPoint("TOPLEFT", 1, -1); header:SetPoint("TOPRIGHT", -1, -1); header:SetHeight(68)
local logo = header:CreateTexture(nil, "ARTWORK"); logo:SetTexture("Interface\\Icons\\Achievement_General_StayClassy"); logo:SetWidth(42); logo:SetHeight(42); logo:SetPoint("LEFT", 18, 0)
local title = Text(header, "GROUP COMPOSER", "GameFontNormalLarge", C.text); title:SetPoint("TOPLEFT", 72, -11)
local subtitle = Text(header, "Design the roster. Composer prepares the bots. You just play your character.", "GameFontHighlightSmall", C.muted); subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
local backend = Text(header, "Backend: checking", "GameFontHighlightSmall", C.dim); backend:SetPoint("RIGHT", -166, 0)
local close = Button(header, "Close  X", 118, 32, function() CloseMenu(); frame:Hide() end); close:SetPoint("RIGHT", -18, 0); close:SetAccent(C.red, true)

local sidebar = Panel(frame, C.sidebar, C.lineSoft); sidebar:SetPoint("TOPLEFT", 1, -69); sidebar:SetPoint("BOTTOMLEFT", 1, 1); sidebar:SetWidth(190)
local navTitle = Text(sidebar, "GROUP COMPOSER", "GameFontNormal", C.text); navTitle:SetPoint("TOPLEFT", 18, -22)
local navSub = Text(sidebar, "Party & raid planner", "GameFontHighlightSmall", C.muted); navSub:SetPoint("TOPLEFT", navTitle, "BOTTOMLEFT", 0, -3)
local navDungeon, navRaid, navRoster
navDungeon = Button(sidebar, "Dungeon", 158, 40, function() GC:SetMode("DUNGEON") end); navDungeon:SetPoint("TOPLEFT", 16, -76)
navRaid = Button(sidebar, "Raid", 158, 40, function() GC:SetMode("RAID") end); navRaid:SetPoint("TOPLEFT", 16, -124)
navRoster = Button(sidebar, "Humans & Pins", 158, 40, function() U:ShowRosterEditor() end); navRoster:SetPoint("TOPLEFT", 16, -184)
local profileTitle = Text(sidebar, "TEMPLATES", "GameFontNormalSmall", C.muted); profileTitle:SetPoint("TOPLEFT", 18, -252)
local profileDD
local function ProfileItems()
    local out = {}
    for _, name in ipairs(P.ListBuiltins()) do out[#out + 1] = {value = name, label = name} end
    for _, name in ipairs(P.ListCustom()) do out[#out + 1] = {value = name, label = name} end
    if #out == 0 then out[1] = {value = "", label = "No templates"} end
    return out
end
profileDD = Selector(sidebar, 158, ProfileItems, function() return GC.db and GC.db.lastProfile or "" end, function(value) if value and value ~= "" then GC:LoadProfile(value) end end)
profileDD:SetPoint("TOPLEFT", 8, -274)
local saveTemplate = Button(sidebar, "Save Template", 158, 32, function() if StaticPopup_Show then StaticPopup_Show("GROUPCOMPOSER_SAVE_PROFILE") end end); saveTemplate:SetPoint("TOPLEFT", 16, -316)
local newTemplate = Button(sidebar, "Reset Current", 158, 32, function() GC:SetConfig(P.New(GC:GetConfig().mode), nil) end); newTemplate:SetPoint("TOPLEFT", 16, -354)
local sidebarHelp = Text(sidebar, "Humans are never respec'd.\nBot builds can be prepared to\nmatch the roster you request.", "GameFontHighlightSmall", C.muted); sidebarHelp:SetPoint("BOTTOMLEFT", 18, 24); sidebarHelp:SetWidth(155)

local body = CreateFrame("Frame", nil, frame); body:SetPoint("TOPLEFT", 206, -84); body:SetPoint("BOTTOMRIGHT", -16, 48)
local statusBar = Panel(frame, C.chrome, C.lineSoft); statusBar:SetPoint("BOTTOMLEFT", 206, 12); statusBar:SetPoint("BOTTOMRIGHT", -16, 12); statusBar:SetHeight(28)
local statusText = Text(statusBar, "Ready.", "GameFontHighlightSmall", C.muted); statusText:SetPoint("LEFT", 10, 0); statusText:SetPoint("RIGHT", -10, 0)
U.statusText = statusText

local dungeonPage = CreateFrame("Frame", nil, body); dungeonPage:SetAllPoints(body)
local raidPage = CreateFrame("Frame", nil, body); raidPage:SetAllPoints(body)

local function HumanCard(parent, x, y, width, height)
    local card = Panel(parent, C.panel, C.lineSoft); card:SetPoint("TOPLEFT", x, y); card:SetWidth(width); card:SetHeight(height)
    local titleText = Text(card, "YOUR PARTY ANCHORS", "GameFontNormal", C.text); titleText:SetPoint("TOPLEFT", 16, -12)
    local hint = Text(card, "Real players are locked. Choose a role each human can actually play; Composer fills around you.", "GameFontHighlightSmall", C.muted); hint:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -3); hint:SetWidth(width - 32)
    card.rows = {}
    function card:Refresh()
        local humans = HumanRows()
        for _, row in ipairs(self.rows) do row:Hide() end
        for i, human in ipairs(humans) do
            if i > 4 then break end
            local row = self.rows[i]
            if not row then
                row = Panel(self, C.bg, C.lineSoft); row:SetHeight(42); row:SetPoint("LEFT", 16, 0); row:SetPoint("RIGHT", -16, 0)
                row.icon = ClassIcon(row, "WARRIOR", 28); row.icon:SetPoint("LEFT", 8, 0)
                row.name = Text(row, "", "GameFontNormal", C.text); row.name:SetPoint("LEFT", 44, 8); row.name:SetWidth(150)
                row.build = Text(row, "", "GameFontHighlightSmall", C.muted); row.build:SetPoint("LEFT", 44, -9); row.build:SetWidth(260)
                row.prompt = Text(row, "Choose role", "GameFontNormalSmall", C.gold); row.prompt:SetPoint("RIGHT", -220, 0)
                row.roleButtons = {}
                for j, role in ipairs({"TANK", "HEALER", "DPS"}) do
                    local rb = Button(row, D.ROLE_LABEL[role], 66, 26)
                    rb:SetPoint("RIGHT", -8 - ((3 - j) * 72), 0); rb.role = role; row.roleButtons[role] = rb
                end
                self.rows[i] = row
            end
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 16, -52 - ((i - 1) * 47)); row:SetPoint("RIGHT", -16, 0)
            row.human = human
            row.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
            local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[human.class]
            if coords then row.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4]) end
            local isYou = human.isPlayer and true or false
            row.name:SetText((isYou and "YOU  •  " or "") .. tostring(human.name or "Unknown"))
            local cc = ClassColor(human.class); row.name:SetTextColor(cc[1], cc[2], cc[3], 1)
            local specName = "Current build preserved"
            if isYou then specName = PlayerSpec() end
            row.build:SetText((D.CLASS_LABEL[human.class] or human.class or "Unknown") .. "  •  " .. tostring(specName))
            local selected = GC:GetConfig().humanRoles[human.name]
            if selected then row.prompt:SetText("Locked as " .. (D.ROLE_LABEL[selected] or selected)); row.prompt:SetTextColor(C.green[1], C.green[2], C.green[3], 1)
            else row.prompt:SetText("Choose role"); row.prompt:SetTextColor(C.gold[1], C.gold[2], C.gold[3], 1) end
            for _, role in ipairs({"TANK", "HEALER", "DPS"}) do
                local rb = row.roleButtons[role]
                local allowed = ClassCanRole(human.class, role)
                rb:SetEnabledState(allowed)
                rb:SetAccent(ROLE_COLOR[role], selected == role)
                rb:SetScript("OnMouseDown", function()
                    if allowed then GC:SetHumanRole(human.name, role); card:Refresh() end
                end)
            end
            row:Show()
        end
        local visibleRows = math.max(1, math.floor((height - 50) / 47))
        for i, row in ipairs(self.rows) do if i > visibleRows then row:Hide() end end
        if #humans > visibleRows then
            if not self.more then self.more = Text(self, "+ " .. tostring(#humans - visibleRows) .. " more human(s)  •  Manage in Humans & Pins", "GameFontHighlightSmall", C.blue); self.more:SetPoint("BOTTOMLEFT", 18, 10) end
            self.more:SetText("+ " .. tostring(#humans - visibleRows) .. " more human(s)  •  Manage in Humans & Pins"); self.more:Show()
        elseif self.more then self.more:Hide() end
        if #humans == 0 then
            if not self.empty then self.empty = Text(self, "Waiting for human roster anchors from the server...", "GameFontHighlight", C.gold); self.empty:SetPoint("TOPLEFT", 18, -64) end
            self.empty:Show()
        elseif self.empty then self.empty:Hide() end
    end
    return card
end

SectionTitle(dungeonPage, "Dungeon Group Setup", "Pick a dungeon, choose your role, then define as much or as little of the 5-player composition as you want.", 0, 0)
local dungeonSetup = Panel(dungeonPage, C.panel, C.lineSoft); dungeonSetup:SetPoint("TOPLEFT", 0, -48); dungeonSetup:SetWidth(840); dungeonSetup:SetHeight(110)
local dDungeonLabel = Text(dungeonSetup, "DUNGEON", "GameFontNormalSmall", C.muted); dDungeonLabel:SetPoint("TOPLEFT", 18, -15)
local function DungeonItems()
    local out = {}; for _, d in ipairs(D.DUNGEONS) do out[#out + 1] = {value = d.id, label = d.label} end; return out
end
local dungeonDD = Selector(dungeonSetup, 335, DungeonItems, function() return GC:GetConfig().activity end, function(value) GC:SetDungeonActivity(value) end); dungeonDD:SetPoint("TOPLEFT", 10, -36)
local dDiffLabel = Text(dungeonSetup, "DIFFICULTY", "GameFontNormalSmall", C.muted); dDiffLabel:SetPoint("TOPLEFT", 390, -15)
local function DungeonDiffItems()
    local out = {}; for _, d in ipairs(D.DUNGEON_DIFFICULTIES) do out[#out + 1] = {value = d.id, label = d.label} end; return out
end
local dungeonDiff = Selector(dungeonSetup, 230, DungeonDiffItems, function() return GC:GetConfig().difficulty end, function(value) GC:GetConfig().difficulty = value; GC:Touch("Dungeon difficulty changed") end); dungeonDiff:SetPoint("TOPLEFT", 382, -36)
local support = Text(dungeonSetup, "✓ Dungeon Clear supported", "GameFontNormal", C.green); support:SetPoint("TOPLEFT", 640, -47)

local dHuman = HumanCard(dungeonPage, 0, -168, 840, 105)

local dSlots = Panel(dungeonPage, C.panel, C.lineSoft); dSlots:SetPoint("TOPLEFT", 0, -283); dSlots:SetWidth(840); dSlots:SetHeight(292)
local dSlotsTitle = Text(dSlots, "DUNGEON COMPOSITION", "GameFontNormal", C.text); dSlotsTitle:SetPoint("TOPLEFT", 16, -13)
local dSlotsHint = Text(dSlots, "Select exact class/specs where you care. Leave a slot on Any and Composer will choose a suitable bot.", "GameFontHighlightSmall", C.muted); dSlotsHint:SetPoint("TOPLEFT", dSlotsTitle, "BOTTOMLEFT", 0, -3)

local dRolePanels = {}
local function BuildDungeonRole(role, x, width, target)
    local color = ROLE_COLOR[role]
    local p = Panel(dSlots, C.bg, color); p:SetPoint("TOPLEFT", x, -58); p:SetWidth(width); p:SetHeight(216)
    local badge = RoleBadge(p, role, 34); badge:SetPoint("TOPLEFT", 12, -12)
    local titleText = Text(p, D.ROLE_LABEL[role], "GameFontNormalLarge", color); titleText:SetPoint("LEFT", badge, "RIGHT", 9, 6)
    local sub = Text(p, tostring(target) .. (target == 1 and " slot" or " slots"), "GameFontHighlightSmall", C.muted); sub:SetPoint("LEFT", badge, "RIGHT", 9, -11)
    p.rows = {}
    for i = 1, target do
        local row = CreateFrame("Frame", nil, p); row:SetHeight(42); row:SetPoint("TOPLEFT", 12, -57 - ((i - 1) * 48)); row:SetPoint("RIGHT", -12, 0)
        local slotLabel = Text(row, (role == "DPS" and "DPS " or D.ROLE_LABEL[role] .. " ") .. i, "GameFontHighlightSmall", C.muted); slotLabel:SetPoint("TOPLEFT", 0, 0)
        row.class = "ANY"; row.spec = "ANY"
        row.classDD = Selector(row, math.floor(width * 0.46), function() return ClassesForRole(role, true) end, function() return row.class end, function(value)
            row.class = value; row.spec = "ANY"; row.specDD:Refresh(); U:WriteDungeonSlots(role)
        end); row.classDD:SetPoint("BOTTOMLEFT", -8, -19)
        row.specDD = Selector(row, math.floor(width * 0.43), function()
            if row.class == "ANY" then return {{value = "ANY", label = "Any spec"}} end
            return SpecsForRole(row.class, role, true)
        end, function() return row.spec end, function(value) row.spec = value; U:WriteDungeonSlots(role) end); row.specDD:SetPoint("LEFT", row.classDD, "RIGHT", -8, 0)
        p.rows[i] = row
    end
    function p:Refresh()
        local slots = ExpandedRequired(role)
        local remaining = RemainingBotSlots(role)
        sub:SetText(tostring(remaining) .. (remaining == 1 and " bot slot" or " bot slots"))
        for i, row in ipairs(self.rows) do
            local s = i <= remaining and slots[i] or nil
            row.class = s and s.class or "ANY"; row.spec = s and s.spec or "ANY"
            row.classDD:Refresh(); row.specDD:Refresh()
            if i <= remaining then row:Show() else row:Hide() end
        end
    end
    dRolePanels[role] = p
    return p
end
BuildDungeonRole("TANK", 14, 250, 1); BuildDungeonRole("HEALER", 294, 250, 1); BuildDungeonRole("DPS", 574, 250, 3)
function U:WriteDungeonSlots(role)
    local out, remaining = {}, RemainingBotSlots(role)
    for i, row in ipairs(dRolePanels[role].rows) do
        if i <= remaining then out[#out + 1] = {class = row.class, spec = row.spec} end
    end
    WriteRequired(role, out)
end

local dOptions = Panel(dungeonPage, C.panel, C.lineSoft); dOptions:SetPoint("TOPLEFT", 0, -585); dOptions:SetWidth(840); dOptions:SetHeight(86)
local dOptTitle = Text(dOptions, "ADVANCED OPTIONS", "GameFontNormal", C.text); dOptTitle:SetPoint("TOPLEFT", 16, -11)
local dGuild = Toggle(dOptions, "Prefer guild members", function() return GC:GetConfig().options.preferGuild end, function(v) GC:GetConfig().options.preferGuild = v; GC:Touch("Option changed") end); dGuild:SetPoint("TOPLEFT", 18, -39); dGuild:SetWidth(220)
local dWorld = Toggle(dOptions, "Use world/reserve bots", function() return GC:GetConfig().options.fillWorld end, function(v) GC:GetConfig().options.fillWorld = v; GC:Touch("Option changed") end); dWorld:SetPoint("TOPLEFT", 255, -39); dWorld:SetWidth(220)
local dBalance = Toggle(dOptions, "Balance useful utility", function() return GC:GetConfig().options.balanceUtility end, function(v) GC:GetConfig().options.balanceUtility = v; GC:Touch("Option changed") end); dBalance:SetPoint("TOPLEFT", 492, -39); dBalance:SetWidth(220)

local dSummary = Panel(dungeonPage, C.panel, C.lineSoft); dSummary:SetPoint("TOPRIGHT", 0, -48); dSummary:SetWidth(405); dSummary:SetHeight(623)
local dSumTitle = Text(dSummary, "COMPOSITION SUMMARY", "GameFontNormalLarge", C.text); dSumTitle:SetPoint("TOPLEFT", 18, -16)
local dState = Text(dSummary, "CHOOSE YOUR ROLE", "GameFontNormalSmall", C.gold); dState:SetPoint("TOPRIGHT", -18, -19)
local dCount = Text(dSummary, "0 / 5", "GameFontNormalLarge", C.text); dCount:SetPoint("TOPLEFT", 18, -50)
local dRoleCount = Text(dSummary, "Tank 1  •  Healer 1  •  DPS 3", "GameFontHighlightSmall", C.muted); dRoleCount:SetPoint("TOPLEFT", dCount, "BOTTOMLEFT", 0, -4)
local dWarnTitle = Text(dSummary, "WARNINGS & NEXT STEP", "GameFontNormal", C.gold); dWarnTitle:SetPoint("TOPLEFT", 18, -102)
local dWarnings = Text(dSummary, "Choose your role above, then build a preview.", "GameFontHighlightSmall", C.muted); dWarnings:SetPoint("TOPLEFT", 18, -127); dWarnings:SetWidth(365); dWarnings:SetHeight(70); dWarnings:SetJustifyV("TOP")
local dRosterTitle = Text(dSummary, "PARTY PREVIEW", "GameFontNormal", C.text); dRosterTitle:SetPoint("TOPLEFT", 18, -206)
local dRosterRows = {}
for i = 1, 5 do
    local row = Panel(dSummary, C.bg, C.lineSoft); row:SetPoint("TOPLEFT", 18, -232 - ((i - 1) * 58)); row:SetWidth(369); row:SetHeight(50)
    row.badge = RoleBadge(row, "DPS", 30); row.badge:SetPoint("LEFT", 8, 0)
    row.icon = ClassIcon(row, "WARRIOR", 28); row.icon:SetPoint("LEFT", 46, 0)
    row.name = Text(row, "Empty slot", "GameFontNormal", C.dim); row.name:SetPoint("TOPLEFT", 82, -8); row.name:SetWidth(175)
    row.build = Text(row, "", "GameFontHighlightSmall", C.muted); row.build:SetPoint("TOPLEFT", 82, -27); row.build:SetWidth(210)
    row.source = Text(row, "", "GameFontNormalSmall", C.blue); row.source:SetPoint("RIGHT", -10, 0)
    dRosterRows[i] = row
end
local dFind = Button(dSummary, "Build Preview", 160, 38, function() GC:FindRoster() end); dFind:SetPoint("BOTTOMLEFT", 18, 16); dFind:SetAccent(C.blue, true)
local dAssemble = Button(dSummary, "Assemble Party", 176, 38, function() GC:Assemble() end); dAssemble:SetPoint("BOTTOMRIGHT", -18, 16); dAssemble:SetAccent(C.green, true)

SectionTitle(raidPage, "Raid Setup", "Build the exact class/spec composition you want, then Composer prepares and assembles it.", 0, 0)
local raidSetup = Panel(raidPage, C.panel, C.lineSoft); raidSetup:SetPoint("TOPLEFT", 0, -48); raidSetup:SetPoint("TOPRIGHT", 0, -48); raidSetup:SetHeight(112)
local sizeTitle = Text(raidSetup, "RAID SIZE", "GameFontNormalSmall", C.muted); sizeTitle:SetPoint("TOPLEFT", 16, -13)
local sizeButtons = {}
for i, size in ipairs({10, 20, 25, 40}) do
    local b = Button(raidSetup, tostring(size) .. "-man", 72, 34, function() GC:SetRaidSize(size) end); b:SetPoint("TOPLEFT", 16 + ((i - 1) * 78), -35); b.sizeValue = size; sizeButtons[#sizeButtons + 1] = b
end
local raidTitle = Text(raidSetup, "RAID", "GameFontNormalSmall", C.muted); raidTitle:SetPoint("TOPLEFT", 335, -13)
local function RaidItems()
    local out = {}
    for _, r in ipairs(D.RAIDS or {}) do
        local status = EncounterReadyRaid(r.id) and "BOT-READY" or "ROSTER ONLY"
        out[#out + 1] = {value = r.id, label = r.era .. "  •  " .. r.label .. "  •  " .. status}
    end
    return out
end
local raidDD = Selector(raidSetup, 360, RaidItems, function() return GC:GetConfig().activity end, function(value) GC:SetRaidActivity(value) end); raidDD:SetPoint("TOPLEFT", 327, -35)
local raidDiffTitle = Text(raidSetup, "DIFFICULTY", "GameFontNormalSmall", C.muted); raidDiffTitle:SetPoint("TOPLEFT", 725, -13)
local function RaidDiffItems()
    local raid = D.GetRaidById(GC:GetConfig().activity); local out = {{value = "normal", label = "Normal"}}
    if raid and raid.heroic then out[#out + 1] = {value = "heroic", label = "Heroic"} end
    return out
end
local raidDiff = Selector(raidSetup, 160, RaidDiffItems, function() return GC:GetConfig().difficulty end, function(value) GC:GetConfig().difficulty = value; GC:Touch("Raid difficulty changed") end); raidDiff:SetPoint("TOPLEFT", 717, -35)
local raidReady = Text(raidSetup, "", "GameFontNormal", C.green); raidReady:SetPoint("TOPRIGHT", -20, -47)

local rHuman = HumanCard(raidPage, 0, -170, 1000, 105)
local raidStatus = Panel(raidPage, C.panel, C.lineSoft); raidStatus:SetPoint("TOPRIGHT", 0, -170); raidStatus:SetWidth(245); raidStatus:SetHeight(105)
local rsTitle = Text(raidStatus, "ROSTER STATUS", "GameFontNormalSmall", C.muted); rsTitle:SetPoint("TOPLEFT", 14, -13)
local rsCount = Text(raidStatus, "0 / 25", "GameFontNormalLarge", C.text); rsCount:SetPoint("TOPLEFT", 14, -37)
local rsRoles = Text(raidStatus, "2 Tank • 6 Heal • 17 DPS", "GameFontHighlightSmall", C.muted); rsRoles:SetPoint("TOPLEFT", 14, -65)
local rsState = Text(raidStatus, "Choose your role", "GameFontNormalSmall", C.gold); rsState:SetPoint("BOTTOMLEFT", 14, 12)

local exact = Panel(raidPage, C.panel, C.lineSoft); exact:SetPoint("TOPLEFT", 0, -285); exact:SetPoint("TOPRIGHT", 0, -285); exact:SetHeight(282)
local exTitle = Text(exact, "EXACT COMPOSITION", "GameFontNormal", C.text); exTitle:SetPoint("TOPLEFT", 16, -12)
local exHint = Text(exact, "Exact rows are bot slots only; human anchors already consume their roles. Unspecified bot slots are auto-filled.", "GameFontHighlightSmall", C.muted); exHint:SetPoint("TOPLEFT", exTitle, "BOTTOMLEFT", 0, -3)
local exactColumns = {}
local function BuildExactColumn(role, x, width)
    local color = ROLE_COLOR[role]
    local col = Panel(exact, C.bg, color); col:SetPoint("TOPLEFT", x, -54); col:SetWidth(width); col:SetHeight(212)
    local badge = RoleBadge(col, role, 32); badge:SetPoint("TOPLEFT", 12, -10)
    local titleText = Text(col, D.ROLE_LABEL[role] .. "S", "GameFontNormal", color); titleText:SetPoint("LEFT", badge, "RIGHT", 8, 5)
    local cap = Text(col, "", "GameFontHighlightSmall", C.muted); cap:SetPoint("LEFT", badge, "RIGHT", 8, -11); col.cap = cap
    local add = Button(col, "+ Add Build", 90, 25); add:SetPoint("TOPRIGHT", -10, -13); col.add = add
    local scroll = CreateFrame("ScrollFrame", nil, col); scroll:SetPoint("TOPLEFT", 8, -50); scroll:SetPoint("BOTTOMRIGHT", -8, 8); scroll:EnableMouseWheel(true)
    local child = CreateFrame("Frame", nil, scroll); child:SetWidth(width - 24); child:SetHeight(150); scroll:SetScrollChild(child); col.scroll, col.child = scroll, child; col.rows = {}
    scroll:SetScript("OnMouseWheel", function(self, delta) local v = self:GetVerticalScroll(); local r = self:GetVerticalScrollRange(); self:SetVerticalScroll(math.max(0, math.min(r, v - delta * 28))) end)
    function col:Refresh()
        local rows = AggregatedRequired(role)
        local target = RemainingBotSlots(role)
        local exactCount = 0; for _, r in ipairs(rows) do exactCount = exactCount + r.count end
        self.cap:SetText(exactCount .. " exact / " .. target .. " bot slots")
        self.add:SetEnabledState(exactCount < target)
        for _, ui in ipairs(self.rows) do ui:Hide() end
        for i, data in ipairs(rows) do
            local ui = self.rows[i]
            if not ui then
                ui = Panel(child, C.panel2, C.lineSoft); ui:SetHeight(31); ui:SetWidth(width - 28)
                ui.classDD = Selector(ui, 96, function() return ClassesForRole(role, false) end, function() return ui.data and ui.data.class end, function(value)
                    local rowsNow = AggregatedRequired(role); local idx = ui.index
                    if not idx or not rowsNow[idx] then return end
                    rowsNow[idx].class = value
                    local specs = SpecsForRole(value, role, false); rowsNow[idx].spec = specs[1] and specs[1].value or "ANY"
                    WriteAggregated(role, rowsNow)
                end); ui.classDD:SetPoint("LEFT", -8, 0)
                ui.specDD = Selector(ui, 118, function() return ui.data and SpecsForRole(ui.data.class, role, false) or {} end, function() return ui.data and ui.data.spec end, function(value)
                    local rowsNow = AggregatedRequired(role); local idx = ui.index
                    if idx and rowsNow[idx] then rowsNow[idx].spec = value; WriteAggregated(role, rowsNow) end
                end); ui.specDD:SetPoint("LEFT", ui.classDD, "RIGHT", -10, 0)
                ui.minus = Button(ui, "-", 24, 24); ui.minus:SetPoint("LEFT", ui.specDD, "RIGHT", -5, 0)
                ui.count = Text(ui, "1", "GameFontNormal", C.text); ui.count:SetWidth(24); ui.count:SetJustifyH("CENTER"); ui.count:SetPoint("LEFT", ui.minus, "RIGHT", 1, 0)
                ui.plus = Button(ui, "+", 24, 24); ui.plus:SetPoint("LEFT", ui.count, "RIGHT", 1, 0)
                ui.remove = Button(ui, "x", 24, 24); ui.remove:SetPoint("RIGHT", -3, 0); ui.remove:SetAccent(C.red, true)
                self.rows[i] = ui
            end
            ui.data, ui.index = data, i; ui:ClearAllPoints(); ui:SetPoint("TOPLEFT", 0, -((i - 1) * 34)); ui.count:SetText(tostring(data.count))
            ui.classDD:Refresh(); ui.specDD:Refresh()
            ui.minus:SetScript("OnMouseDown", function() local rowsNow = AggregatedRequired(role); local idx = ui.index; if idx and rowsNow[idx] then rowsNow[idx].count = math.max(1, rowsNow[idx].count - 1); WriteAggregated(role, rowsNow) end end)
            ui.plus:SetScript("OnMouseDown", function()
                local rowsNow = AggregatedRequired(role); local targetNow = RemainingBotSlots(role)
                local total = 0; for _, r in ipairs(rowsNow) do total = total + r.count end
                local idx = ui.index; if idx and rowsNow[idx] and total < targetNow then rowsNow[idx].count = rowsNow[idx].count + 1; WriteAggregated(role, rowsNow) else GC:Fire("STATUS", "That role already has " .. tostring(targetNow) .. " exact slot(s).") end
            end)
            ui.remove:SetScript("OnMouseDown", function() local rowsNow = AggregatedRequired(role); local idx = ui.index; if idx and rowsNow[idx] then table.remove(rowsNow, idx); WriteAggregated(role, rowsNow) end end)
            ui:Show()
        end
        child:SetHeight(math.max(145, #rows * 34 + 4))
        self.add:SetScript("OnMouseDown", function()
            local rowsNow = AggregatedRequired(role); local targetNow = RemainingBotSlots(role)
            local total = 0; for _, r in ipairs(rowsNow) do total = total + r.count end
            if total >= targetNow then GC:Fire("STATUS", "All " .. tostring(targetNow) .. " " .. string.lower(D.ROLE_LABEL[role]) .. " slot(s) are already exact."); return end
            local classes = ClassesForRole(role, false); local cls = classes[1] and classes[1].value
            local specs = cls and SpecsForRole(cls, role, false) or {}; local spec = specs[1] and specs[1].value or "ANY"
            rowsNow[#rowsNow + 1] = {class = cls, spec = spec, count = 1}; WriteAggregated(role, rowsNow)
        end)
    end
    exactColumns[role] = col; return col
end
BuildExactColumn("TANK", 14, 390); BuildExactColumn("HEALER", 420, 390); BuildExactColumn("DPS", 826, 390)

local rOptions = Panel(raidPage, C.panel, C.lineSoft); rOptions:SetPoint("TOPLEFT", 0, -577); rOptions:SetPoint("TOPRIGHT", 0, -577); rOptions:SetHeight(56)
local rGuild = Toggle(rOptions, "Prefer guild members", function() return GC:GetConfig().options.preferGuild end, function(v) GC:GetConfig().options.preferGuild = v; GC:Touch("Option changed") end); rGuild:SetPoint("LEFT", 16, 0); rGuild:SetWidth(210)
local rWorld = Toggle(rOptions, "Use world/reserve bots", function() return GC:GetConfig().options.fillWorld end, function(v) GC:GetConfig().options.fillWorld = v; GC:Touch("Option changed") end); rWorld:SetPoint("LEFT", 250, 0); rWorld:SetWidth(210)
local rUtility = Toggle(rOptions, "Balance raid utility", function() return GC:GetConfig().options.balanceUtility end, function(v) GC:GetConfig().options.balanceUtility = v; GC:Touch("Option changed") end); rUtility:SetPoint("LEFT", 490, 0); rUtility:SetWidth(190)
local rRange = Toggle(rOptions, "Balance melee / ranged", function() return GC:GetConfig().options.balanceRange end, function(v) GC:GetConfig().options.balanceRange = v; GC:Touch("Option changed") end); rRange:SetPoint("LEFT", 705, 0); rRange:SetWidth(205)
local rPreview = Button(rOptions, "Build Raid Preview", 150, 34, function() GC:FindRoster() end); rPreview:SetPoint("RIGHT", -170, 0); rPreview:SetAccent(C.blue, true)
local rAssemble = Button(rOptions, "Assemble Raid", 150, 34, function() GC:Assemble() end); rAssemble:SetPoint("RIGHT", -10, 0); rAssemble:SetAccent(C.gold, true)

local groups = Panel(raidPage, C.panel, C.lineSoft); groups:SetPoint("TOPLEFT", 0, -643); groups:SetPoint("TOPRIGHT", 0, -643); groups:SetHeight(162)
local groupsTitle = Text(groups, "RAID GROUP LAYOUT", "GameFontNormal", C.text); groupsTitle:SetPoint("TOPLEFT", 14, -10)
local groupsHint = Text(groups, "Preview only until Assemble. Human anchors are never removed or respec'd.", "GameFontHighlightSmall", C.muted); groupsHint:SetPoint("TOPLEFT", groupsTitle, "BOTTOMLEFT", 0, -2)
local groupCards = {}
for g = 1, 8 do
    local card = Panel(groups, C.bg, C.lineSoft); card:SetWidth(145); card:SetHeight(112); card:SetPoint("TOPLEFT", 14 + ((g - 1) * 151), -42)
    local gt = Text(card, "Group " .. g, "GameFontNormalSmall", C.text); gt:SetPoint("TOPLEFT", 7, -6)
    card.rows = {}
    for i = 1, 5 do
        local row = Text(card, "Empty slot", "GameFontHighlightSmall", C.dim); row:SetPoint("TOPLEFT", 7, -23 - ((i - 1) * 17)); row:SetWidth(132); card.rows[i] = row
    end
    groupCards[g] = card
end

local editorFrame = CreateFrame("Frame", "GroupComposerRosterEditorV3Frame", UIParent)
U.editorFrame = editorFrame
editorFrame:SetWidth(980); editorFrame:SetHeight(650); editorFrame:SetPoint("CENTER"); editorFrame:SetFrameStrata("FULLSCREEN_DIALOG"); editorFrame:EnableMouse(true); editorFrame:Hide()
local eBg = Solid(editorFrame, C.bg); eBg:SetAllPoints(editorFrame); editorFrame.border = Outline(editorFrame, C.line)
UISpecialFrames = UISpecialFrames or {}; local editorSpecial = false
for _, name in ipairs(UISpecialFrames) do if name == "GroupComposerRosterEditorV3Frame" then editorSpecial = true end end
if not editorSpecial then table.insert(UISpecialFrames, "GroupComposerRosterEditorV3Frame") end
local eHeader = Panel(editorFrame, C.chrome, C.lineSoft); eHeader:SetPoint("TOPLEFT", 1, -1); eHeader:SetPoint("TOPRIGHT", -1, -1); eHeader:SetHeight(64)
local eTitle = Text(eHeader, "HUMANS & FAMILIAR COMPANIONS", "GameFontNormalLarge", C.text); eTitle:SetPoint("TOPLEFT", 18, -12)
local eSub = Text(eHeader, "Real players are immutable anchors. Pins are familiar bots you prefer or require.", "GameFontHighlightSmall", C.muted); eSub:SetPoint("TOPLEFT", eTitle, "BOTTOMLEFT", 0, -3)
local eClose = Button(eHeader, "Close  X", 105, 30, function() editorFrame:Hide(); CloseMenu() end); eClose:SetPoint("RIGHT", -15, 0); eClose:SetAccent(C.red, true)
local eHuman = HumanCard(editorFrame, 18, -82, 944, 245)
local pinPanel = Panel(editorFrame, C.panel, C.lineSoft); pinPanel:SetPoint("TOPLEFT", 18, -342); pinPanel:SetWidth(944); pinPanel:SetHeight(280)
local pinTitle = Text(pinPanel, "PERSISTENT GUILD COMPANIONS", "GameFontNormal", C.text); pinTitle:SetPoint("TOPLEFT", 16, -13)
local pinHint = Text(pinPanel, "Pin a familiar bot by name. Preferred = use when available. Required = this exact character must be present.", "GameFontHighlightSmall", C.muted); pinHint:SetPoint("TOPLEFT", pinTitle, "BOTTOMLEFT", 0, -3)
local pinName = CreateFrame("EditBox", nil, pinPanel, "InputBoxTemplate"); pinName:SetWidth(230); pinName:SetHeight(28); pinName:SetAutoFocus(false); pinName:SetPoint("TOPLEFT", 18, -61)
local pinRole = "DPS"
local pinRoleDD = Selector(pinPanel, 145, function() return {{value="TANK",label="Tank"},{value="HEALER",label="Healer"},{value="DPS",label="DPS"}} end, function() return pinRole end, function(v) pinRole = v end); pinRoleDD:SetPoint("LEFT", pinName, "RIGHT", 8, 1)
local pinRequired = false
local reqToggle = Toggle(pinPanel, "Required character", function() return pinRequired end, function(v) pinRequired = v end); reqToggle:SetPoint("LEFT", pinRoleDD, "RIGHT", 12, 1); reqToggle:SetWidth(160)
local pinAdd = Button(pinPanel, "Pin Member", 120, 30, function()
    local name = pinName:GetText(); if name and name ~= "" then GC:AddPinnedMember(name, pinRole, pinRequired); pinName:SetText(""); U:RefreshRosterEditor() end
end); pinAdd:SetPoint("TOPRIGHT", -18, -59); pinAdd:SetAccent(C.blue, true)
local pinRows = {}

function U:RefreshRosterEditor()
    eHuman:Refresh(); local pins = GC:GetConfig().pinned or {}
    for _, row in ipairs(pinRows) do row:Hide() end
    for i, pin in ipairs(pins) do
        local row = pinRows[i]
        if not row then
            row = Panel(pinPanel, C.bg, C.lineSoft); row:SetWidth(908); row:SetHeight(34)
            row.name = Text(row, "", "GameFontNormal", C.text); row.name:SetPoint("LEFT", 10, 0); row.name:SetWidth(210)
            row.role = Text(row, "", "GameFontHighlight", C.muted); row.role:SetPoint("LEFT", 230, 0); row.role:SetWidth(120)
            row.strength = Text(row, "", "GameFontHighlightSmall", C.gold); row.strength:SetPoint("LEFT", 360, 0); row.strength:SetWidth(140)
            row.remove = Button(row, "Remove", 80, 24); row.remove:SetPoint("RIGHT", -6, 0); row.remove:SetAccent(C.red, true)
            pinRows[i] = row
        end
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 18, -102 - ((i - 1) * 38)); row.name:SetText(pin.name); row.role:SetText(D.ROLE_LABEL[pin.role] or pin.role); row.strength:SetText(pin.required and "Required" or "Preferred")
        row.remove:SetScript("OnMouseDown", function() GC:RemovePinnedMember(i); U:RefreshRosterEditor() end); row:Show()
    end
    reqToggle:Refresh(); pinRoleDD:Refresh()
end
function U:ShowRosterEditor() CloseMenu(); U:RefreshRosterEditor(); editorFrame:Show() end

local function UpdateClassIcon(texture, classToken)
    texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
    local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classToken]
    if coords then texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4]) else texture:SetTexCoord(0, 1, 0, 1) end
end

local function HumanReady()
    return #HumanRoleProblems() == 0
end

local function WarningText(plan)
    local humanProblems = HumanRoleProblems()
    if #humanProblems > 0 then return table.concat(humanProblems, "\n"), C.gold end
    if plan and plan.warnings and #plan.warnings > 0 then
        local out = {}; for i = 1, math.min(3, #plan.warnings) do out[#out + 1] = "• " .. plan.warnings[i] end
        if #plan.warnings > 3 then out[#out + 1] = "+ " .. (#plan.warnings - 3) .. " more" end
        return table.concat(out, "\n"), C.gold
    end
    if plan and plan.ready and plan.valid then return "✓ Composition validated. Review the members, then assemble.", C.green end
    return "Choose your human role, configure the roster, then build a preview.", C.muted
end

local function RefreshDungeon()
    local plan = GC.plan or {members={},warnings={}}
    dungeonDD:Refresh(); dungeonDiff:Refresh(); dHuman:Refresh(); dGuild:Refresh(); dWorld:Refresh(); dBalance:Refresh()
    for _, panel in pairs(dRolePanels) do panel:Refresh() end
    local problems = HumanRoleProblems(); local ready = #problems == 0
    dFind:SetEnabledState(ready)
    dAssemble:SetEnabledState(plan.ready and plan.valid)
    dCount:SetText(tostring(plan.summary and plan.summary.total or #(plan.members or {})) .. " / 5")
    dRoleCount:SetText("Bots needed: " .. RemainingBotSlots("TANK") .. " T  •  " .. RemainingBotSlots("HEALER") .. " H  •  " .. RemainingBotSlots("DPS") .. " D")
    if not ready then dState:SetText("CHOOSE YOUR ROLE"); dState:SetTextColor(C.gold[1],C.gold[2],C.gold[3],1)
    elseif plan.ready and plan.valid then dState:SetText("READY"); dState:SetTextColor(C.green[1],C.green[2],C.green[3],1)
    else dState:SetText("BUILD PREVIEW"); dState:SetTextColor(C.blue[1],C.blue[2],C.blue[3],1) end
    local warning, color = WarningText(plan); dWarnings:SetText(warning); dWarnings:SetTextColor(color[1],color[2],color[3],1)
    for i = 1, 5 do
        local row, member = dRosterRows[i], plan.members and plan.members[i]
        if member then
            row:Show(); UpdateClassIcon(row.icon, member.class); row.name:SetText(member.name or "?")
            local cc = ClassColor(member.class); row.name:SetTextColor(cc[1],cc[2],cc[3],1)
            row.build:SetText((member.spec or "Any") .. " " .. (D.CLASS_LABEL[member.class] or member.class or "") .. "  •  " .. (D.ROLE_LABEL[member.role] or member.role or ""))
            local source = member.human and "HUMAN" or member.reserve and "RESERVE" or member.source == "GUILD" and "GUILD" or member.source == "ROSTER" and "ROSTER" or "WORLD"
            if not member.human then source = source .. (member.needsPreparation and " PREP" or " READY") end
            row.source:SetText(source)
            local rc = ROLE_COLOR[member.role] or C.muted; local soft = member.role=="TANK" and C.blueSoft or member.role=="HEALER" and C.greenSoft or C.redSoft
            SetBorder(row.badge, rc); row.badge.bg:SetTexture(soft[1], soft[2], soft[3], 1); if row.badge.icon then row.badge.icon:SetTexture(D.ROLE_ICON[member.role] or D.ROLE_ICON.DPS) end
        else
            row.name:SetText("Empty slot"); row.name:SetTextColor(C.dim[1],C.dim[2],C.dim[3],1); row.build:SetText(""); row.source:SetText("")
        end
    end
end

local function RefreshGroups()
    local c, plan = GC:GetConfig(), GC.plan or {members={}}
    local groupCount = math.min(8, math.ceil((tonumber(c.size) or 25) / 5))
    for g, card in ipairs(groupCards) do
        if g <= groupCount then card:Show() else card:Hide() end
        for _, row in ipairs(card.rows) do row:SetText("Empty slot"); row:SetTextColor(C.dim[1],C.dim[2],C.dim[3],1) end
    end
    local indexes = {}
    for _, m in ipairs(plan.members or {}) do
        local g = tonumber(m.subgroup) or 1; indexes[g] = (indexes[g] or 0) + 1; local i = indexes[g]
        if groupCards[g] and groupCards[g].rows[i] then
            local rc = ROLE_COLOR[m.role] or C.text
            local build = tostring(m.spec or "") .. " " .. tostring(D.CLASS_LABEL[m.class] or m.class or "")
            local prefix = m.human and "YOU " or (ROLE_SHORT[m.role] or "D") .. " "
            groupCards[g].rows[i]:SetText(prefix .. build); groupCards[g].rows[i]:SetTextColor(rc[1],rc[2],rc[3],1)
        end
    end
end

local function RefreshRaid()
    local c, plan = GC:GetConfig(), GC.plan or {members={},warnings={}}
    raidDD:Refresh(); raidDiff:Refresh(); rHuman:Refresh(); rGuild:Refresh(); rWorld:Refresh(); rUtility:Refresh(); rRange:Refresh()
    for _, col in pairs(exactColumns) do col:Refresh() end
    local selectedRaid = D.GetRaidById(c.activity)
    for _, b in ipairs(sizeButtons) do
        local supported = false; if selectedRaid then for _, s in ipairs(selectedRaid.sizes or {}) do if s == b.sizeValue then supported = true end end end
        b:SetEnabledState(supported); b:SetAccent(C.gold, supported and c.size == b.sizeValue)
    end
    if EncounterReadyRaid(c.activity) then
        raidReady:SetText("✓ Encounter AI certified")
        raidReady:SetTextColor(C.green[1], C.green[2], C.green[3], 1)
    else
        raidReady:SetText("Roster planner • encounter AI not certified")
        raidReady:SetTextColor(C.gold[1], C.gold[2], C.gold[3], 1)
    end
    local ready = HumanReady(); rPreview:SetEnabledState(ready); rAssemble:SetEnabledState(plan.ready and plan.valid)
    rsCount:SetText(tostring(plan.summary and plan.summary.total or #(plan.members or {})) .. " / " .. tostring(c.size))
    rsRoles:SetText("Bots: " .. RemainingBotSlots("TANK") .. " T  •  " .. RemainingBotSlots("HEALER") .. " H  •  " .. RemainingBotSlots("DPS") .. " D")
    if not ready then rsState:SetText("Choose human role"); rsState:SetTextColor(C.gold[1],C.gold[2],C.gold[3],1)
    elseif plan.ready and plan.valid then rsState:SetText("Roster ready"); rsState:SetTextColor(C.green[1],C.green[2],C.green[3],1)
    else rsState:SetText("Build a preview"); rsState:SetTextColor(C.blue[1],C.blue[2],C.blue[3],1) end
    RefreshGroups()
end

function U:ApplyScale()
    local w, h = UIParent:GetWidth() or 1920, UIParent:GetHeight() or 1080
    local scale = math.min((w - 24) / 1500, (h - 32) / 900); scale = math.max(0.66, math.min(1.12, scale)); frame:SetScale(scale)
end

function U:Refresh()
    if not frame:IsShown() then return end
    local mode = GC:GetConfig().mode
    backend:SetText(GC.backendSeen and "Backend: connected" or "Backend: checking")
    local bc = GC.backendSeen and C.green or C.dim; backend:SetTextColor(bc[1], bc[2], bc[3], 1)
    if mode == "RAID" then dungeonPage:Hide(); raidPage:Show(); navRaid:SetAccent(C.gold, true); navDungeon:SetAccent(C.blue, false); RefreshRaid()
    else raidPage:Hide(); dungeonPage:Show(); navDungeon:SetAccent(C.blue, true); navRaid:SetAccent(C.gold, false); RefreshDungeon() end
    profileDD:Refresh()
    if editorFrame:IsShown() then U:RefreshRosterEditor() end
end

function U:Show()
    if GC.Dashboard and GC.Dashboard.frame then GC.Dashboard.frame:Hide() end
    if GC.ModernUI and GC.ModernUI.frame then GC.ModernUI.frame:Hide() end
    if GC.UI and GC.UI.frame then GC.UI.frame:Hide() end
    CloseMenu(); U:ApplyScale(); frame:Show(); U:Refresh(); GC:RequestAnchors(); GC:RequestStatus()
end
function U:Toggle() if frame:IsShown() then frame:Hide(); CloseMenu() else U:Show() end end

GC.Toggle = function() U:Toggle() end
GC:RegisterCallback("CONFIG_CHANGED", function() U:Refresh() end)
GC:RegisterCallback("PLAN_CHANGED", function() U:Refresh() end)
GC:RegisterCallback("HUMANS_CHANGED", function() U:Refresh() end)
GC:RegisterCallback("PROFILES_CHANGED", function() if frame:IsShown() then profileDD:Refresh() end end)
GC:RegisterCallback("STATUS", function(text) statusText:SetText(tostring(text or "Ready.")); U:Refresh() end)
GC:RegisterCallback("DISPLAY_CHANGED", function() U:ApplyScale() end)

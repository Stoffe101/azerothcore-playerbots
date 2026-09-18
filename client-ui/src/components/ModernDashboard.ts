import type { BuildSelection } from "./BuildSelector";
import * as BuildSelectorUI from "./BuildSelector";
import * as Native from "../core/Native";
import type { ClassId, Role } from "../data/WotlkBuilds";
import * as Builds from "../data/WotlkBuilds";
import * as Model from "../model/ComposerModel";
import { theme } from "../theme/Theme";
import type { UIButton } from "../widgets/Button";
import * as ButtonUI from "../widgets/Button";
import * as ChoiceUI from "../widgets/ChoiceSelect";
import * as ModalUI from "../widgets/Modal";
import * as ScrollUI from "../widgets/ScrollList";
import * as InputUI from "../widgets/TextInput";
import * as ToggleUI from "../widgets/Toggle";

const GC: any = Model.composer();
const D: any = Model.data();
const P: any = Model.profiles();

type RaidTab = "QUICK" | "EXACT" | "ROSTER";

interface SelectorContext {
    mode: "DUNGEON" | "RAID_ADD" | "RAID_EDIT";
    role: Role;
    index: number;
}

interface Dashboard {
    readonly frame: WoWFrame;
    show: () => void;
    hide: () => void;
    toggle: () => void;
    refresh: () => void;
    applyScale: () => void;
}

interface DungeonSlot {
    role: Role;
    human?: any;
    botIndex?: number;
    exact?: { classId: ClassId; specId: number };
    prepared?: any;
}

function colorForPhase(phase: string) {
    if (phase === "READY" || phase === "DONE") return theme.colors.success;
    if (phase === "ERROR") return theme.colors.error;
    if (phase === "PREPARING" || phase === "BUILDING" || phase === "ASSEMBLING" || phase === "TRAVEL") return theme.colors.warning;
    return theme.colors.primary;
}

function classCanRole(classToken: string, role: Role): boolean {
    return D.CLASS_ROLE?.[role]?.[classToken] === true;
}

function humanCounts(): Record<Role, number> {
    const out: Record<Role, number> = { TANK: 0, HEALER: 0, DPS: 0 };
    const roles = Model.config().humanRoles ?? {};
    for (const human of Model.humans()) {
        const role = roles[human.name] as Role | undefined;
        if (role !== undefined) out[role] += 1;
    }
    return out;
}

function buildDungeonModel(): DungeonSlot[] {
    const sequence: Role[] = ["TANK", "HEALER", "DPS", "DPS", "DPS"];
    const anchors = Model.humans();
    const usedHumans: boolean[] = [];
    const assigned: Array<any | undefined> = [];

    for (let h = 0; h < anchors.length; h += 1) {
        const human = anchors[h];
        const role = Model.config().humanRoles?.[human.name] as Role | undefined;
        if (role === undefined) continue;
        for (let i = 0; i < sequence.length; i += 1) {
            if (sequence[i] === role && assigned[i] === undefined) {
                assigned[i] = human;
                usedHumans[h] = true;
                break;
            }
        }
    }

    const flat: Record<Role, Array<{ classId: ClassId; specId: number }>> = {
        TANK: Model.requiredFlat("TANK"),
        HEALER: Model.requiredFlat("HEALER"),
        DPS: Model.requiredFlat("DPS"),
    };
    const counters: Record<Role, number> = { TANK: 0, HEALER: 0, DPS: 0 };

    const preparedByRole: Record<Role, any[]> = { TANK: [], HEALER: [], DPS: [] };
    if (Model.plan().ready === true) {
        for (const member of Model.planMembers()) {
            if (member.human !== true && preparedByRole[member.role] !== undefined) preparedByRole[member.role].push(member);
        }
    }

    const preparedIndex: Record<Role, number> = { TANK: 0, HEALER: 0, DPS: 0 };
    const result: DungeonSlot[] = [];

    for (let i = 0; i < sequence.length; i += 1) {
        const role = sequence[i];
        const human = assigned[i];
        if (human !== undefined) {
            result.push({ role, human });
            continue;
        }

        counters[role] += 1;
        const botIndex = counters[role];
        const exact = flat[role][botIndex - 1];
        const prepared = preparedByRole[role][preparedIndex[role]];
        preparedIndex[role] += 1;
        result.push({ role, botIndex, exact, prepared });
    }

    return result;
}

function specIdFromLabel(classId: string, label: string): number | undefined {
    const classDef = Builds.getClass(classId as ClassId);
    if (classDef === undefined) return undefined;
    for (const spec of classDef.specs) if (spec.label === label) return spec.id;
    return undefined;
}

function activitySubtitle(): string {
    const cfg = Model.config();
    if (cfg.mode === "RAID") {
        return String(cfg.size) + " player  ·  " + (cfg.difficulty === "heroic" ? "Heroic" : "Normal") + "  ·  Auto-enter after assembly";
    }
    const mode =
        cfg.difficulty === "alpha" ? "Titan Rune Alpha" :
        cfg.difficulty === "beta" ? "Titan Rune Beta" :
        cfg.difficulty === "gamma" ? "Titan Rune Gamma" :
        cfg.difficulty === "heroic" ? "Heroic" : "Normal";
    return mode + "  ·  5 player  ·  " + (cfg.activity === "random" ? "Dungeon Finder chooses destination" : "Auto-enter after assembly");
}

export function createModernDashboard(): Dashboard {
    const frame = CreateFrame("Frame", "GroupComposerModernFrame", UIParent);
    frame.SetSize(1480, 880);
    frame.SetPoint("CENTER", UIParent, "CENTER", 0, 0);
    frame.SetFrameStrata("DIALOG");
    frame.SetMovable(true);
    frame.SetClampedToScreen(true);
    frame.EnableMouse(true);
    frame.RegisterForDrag("LeftButton");
    frame.SetScript("OnDragStart", (self) => self.StartMoving());
    frame.SetScript("OnDragStop", (self) => self.StopMovingOrSizing());
    frame.Hide();

    const root = Native.createSolid(frame, theme.colors.background);
    root.SetAllPoints(frame);
    const rootOutline = Native.createPanel(frame, theme.colors.background, theme.colors.borderStrong);
    rootOutline.frame.SetAllPoints(frame);

    const header = Native.createPanel(frame, theme.colors.surface, theme.colors.border);
    header.frame.SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1);
    header.frame.SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1);
    header.frame.SetHeight(68);

    const mark = Native.createPanel(header.frame, theme.colors.surfaceRaised, theme.colors.primary);
    mark.frame.SetSize(40, 40);
    mark.frame.SetPoint("LEFT", header.frame, "LEFT", 18, 0);
    const markText = Native.createText(mark.frame, "GC", "GameFontNormalLarge", theme.colors.primary);
    markText.SetPoint("CENTER", mark.frame, "CENTER", 0, 0);
    markText.SetJustifyH("CENTER");

    const title = Native.createText(header.frame, "GROUP COMPOSER", "GameFontNormalLarge");
    title.SetPoint("TOPLEFT", header.frame, "TOPLEFT", 72, -14);
    const subtitle = Native.createText(header.frame, "Build the team you want, then let Composer prepare it.", "GameFontHighlightSmall", theme.colors.muted);
    subtitle.SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4);

    const backendDot = Native.createSolid(header.frame, theme.colors.muted, "ARTWORK");
    backendDot.SetSize(8, 8);
    backendDot.SetPoint("RIGHT", header.frame, "RIGHT", -250, 0);
    const backendText = Native.createText(header.frame, "Checking backend", "GameFontHighlightSmall", theme.colors.muted);
    backendText.SetPoint("LEFT", backendDot, "RIGHT", 8, 0);

    const close = ButtonUI.createButton(header.frame, { text: "Close", width: 100, height: 32, accent: theme.colors.error, onClick: () => frame.Hide() });
    close.frame.SetPoint("RIGHT", header.frame, "RIGHT", -18, 0);

    const sidebar = Native.createPanel(frame, theme.colors.surface, theme.colors.border);
    sidebar.frame.SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -69);
    sidebar.frame.SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 36);
    sidebar.frame.SetWidth(176);

    const navTitle = Native.createText(sidebar.frame, "PLAN", "GameFontNormalSmall", theme.colors.muted);
    navTitle.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 16, -20);

    const navDungeon = ButtonUI.createButton(sidebar.frame, { text: "Dungeon", width: 144, height: 42, accent: theme.colors.primary, onClick: () => Model.setMode("DUNGEON") });
    navDungeon.frame.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 16, -48);
    const navRaid = ButtonUI.createButton(sidebar.frame, { text: "Raid", width: 144, height: 42, accent: theme.colors.warning, onClick: () => Model.setMode("RAID") });
    navRaid.frame.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 16, -98);

    const manageTitle = Native.createText(sidebar.frame, "MANAGE", "GameFontNormalSmall", theme.colors.muted);
    manageTitle.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 16, -164);

    let showTemplates = () => {};
    let showPeople = () => {};
    let showOptions = () => {};

    const navTemplates = ButtonUI.createButton(sidebar.frame, { text: "Templates", width: 144, height: 38, onClick: () => showTemplates() });
    navTemplates.frame.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 16, -190);
    const navPeople = ButtonUI.createButton(sidebar.frame, { text: "Humans & Pins", width: 144, height: 38, onClick: () => showPeople() });
    navPeople.frame.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 16, -234);
    const navOptions = ButtonUI.createButton(sidebar.frame, { text: "Options", width: 144, height: 38, onClick: () => showOptions() });
    navOptions.frame.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 16, -278);

    const sideHint = Native.createText(sidebar.frame, "Humans stay locked.\nExact builds only affect bot slots.", "GameFontHighlightSmall", theme.colors.muted);
    sideHint.SetPoint("BOTTOMLEFT", sidebar.frame, "BOTTOMLEFT", 16, 18);
    sideHint.SetWidth(144);
    sideHint.SetJustifyV("TOP");

    const center = CreateFrame("Frame", undefined, frame);
    center.SetPoint("TOPLEFT", frame, "TOPLEFT", 194, -84);
    center.SetSize(928, 744);

    const status = Native.createPanel(frame, theme.colors.surface, theme.colors.borderStrong);
    status.frame.SetPoint("TOPLEFT", frame, "TOPLEFT", 1138, -84);
    status.frame.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 52);

    const footer = Native.createPanel(frame, theme.colors.surface, theme.colors.border);
    footer.frame.SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 194, 12);
    footer.frame.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 12);
    footer.frame.SetHeight(28);
    const footerText = Native.createText(footer.frame, "Ready.", "GameFontHighlightSmall", theme.colors.muted);
    footerText.SetPoint("LEFT", footer.frame, "LEFT", 10, 0);
    footerText.SetPoint("RIGHT", footer.frame, "RIGHT", -10, 0);

    // Activity ---------------------------------------------------------------
    const activity = Native.createPanel(center, theme.colors.surface, theme.colors.borderStrong);
    activity.frame.SetPoint("TOPLEFT", center, "TOPLEFT", 0, 0);
    activity.frame.SetPoint("TOPRIGHT", center, "TOPRIGHT", 0, 0);
    activity.frame.SetHeight(96);

    const activityEyebrow = Native.createText(activity.frame, "ACTIVITY", "GameFontNormalSmall", theme.colors.muted);
    activityEyebrow.SetPoint("TOPLEFT", activity.frame, "TOPLEFT", 16, -12);
    const activityName = Native.createText(activity.frame, "Dungeon", "GameFontNormalLarge");
    activityName.SetPoint("TOPLEFT", activityEyebrow, "BOTTOMLEFT", 0, -5);
    const activitySub = Native.createText(activity.frame, "", "GameFontHighlightSmall", theme.colors.muted);
    activitySub.SetPoint("TOPLEFT", activityName, "BOTTOMLEFT", 0, -4);

    const activitySelect = ChoiceUI.createChoiceSelect(activity.frame, {
        width: 310,
        maxVisible: 10,
        getItems: () => Model.config().mode === "RAID" ? Model.raidItems() : Model.dungeonItems(),
        getValue: () => Model.config().activity,
        onChange: (value) => {
            if (Model.config().mode === "RAID") Model.setRaidActivity(String(value));
            else Model.setDungeonActivity(String(value));
        },
    });
    activitySelect.frame.SetPoint("TOPLEFT", activity.frame, "TOPLEFT", 380, -18);

    const difficultySelect = ChoiceUI.createChoiceSelect(activity.frame, {
        width: 180,
        maxVisible: 7,
        getItems: () => Model.config().mode === "RAID" ? Model.raidDifficultyItems() : Model.difficultyItems(),
        getValue: () => Model.config().difficulty,
        onChange: (value) => Model.setDifficulty(String(value)),
    });
    difficultySelect.frame.SetPoint("LEFT", activitySelect.frame, "RIGHT", 10, 0);

    const raidSizeButtons: Record<number, UIButton> = {};
    for (const size of [10, 20, 25, 40]) {
        const copy = size;
        raidSizeButtons[size] = ButtonUI.createButton(activity.frame, {
            text: String(size),
            width: 52,
            height: 30,
            accent: theme.colors.warning,
            onClick: () => Model.setRaidSize(copy),
        });
    }

    // Human anchor -----------------------------------------------------------
    const humanPanel = Native.createPanel(center, theme.colors.surface, theme.colors.border);
    humanPanel.frame.SetPoint("TOPLEFT", center, "TOPLEFT", 0, -108);
    humanPanel.frame.SetPoint("TOPRIGHT", center, "TOPRIGHT", 0, -108);
    humanPanel.frame.SetHeight(104);

    const humanTitle = Native.createText(humanPanel.frame, "YOUR PARTY", "GameFontNormalSmall", theme.colors.muted);
    humanTitle.SetPoint("TOPLEFT", humanPanel.frame, "TOPLEFT", 16, -12);

    const humanIcon = humanPanel.frame.CreateTexture(undefined, "ARTWORK");
    humanIcon.SetSize(38, 38);
    humanIcon.SetPoint("BOTTOMLEFT", humanPanel.frame, "BOTTOMLEFT", 16, 12);
    Native.setClassIcon(humanIcon, "WARRIOR");

    const humanName = Native.createText(humanPanel.frame, "Choose your role", "GameFontNormal");
    humanName.SetPoint("TOPLEFT", humanIcon, "TOPRIGHT", 10, 0);
    const humanSub = Native.createText(humanPanel.frame, "Real players are locked anchors.", "GameFontHighlightSmall", theme.colors.muted);
    humanSub.SetPoint("TOPLEFT", humanName, "BOTTOMLEFT", 0, -5);

    const humanRoleButtons: Record<Role, UIButton> = {
        TANK: ButtonUI.createButton(humanPanel.frame, { text: "Tank", width: 96, height: 36, accent: theme.colors.tank }),
        HEALER: ButtonUI.createButton(humanPanel.frame, { text: "Healer", width: 96, height: 36, accent: theme.colors.healer }),
        DPS: ButtonUI.createButton(humanPanel.frame, { text: "DPS", width: 96, height: 36, accent: theme.colors.dps }),
    };
    humanRoleButtons.TANK.frame.SetPoint("RIGHT", humanPanel.frame, "RIGHT", -224, -12);
    humanRoleButtons.HEALER.frame.SetPoint("LEFT", humanRoleButtons.TANK.frame, "RIGHT", 8, 0);
    humanRoleButtons.DPS.frame.SetPoint("LEFT", humanRoleButtons.HEALER.frame, "RIGHT", 8, 0);


    // Composition shell ------------------------------------------------------
    const composition = Native.createPanel(center, theme.colors.surface, theme.colors.border);
    composition.frame.SetPoint("TOPLEFT", center, "TOPLEFT", 0, -224);
    composition.frame.SetPoint("BOTTOMRIGHT", center, "BOTTOMRIGHT", 0, 0);

    const compositionTitle = Native.createText(composition.frame, "PARTY COMPOSITION", "GameFontNormal");
    compositionTitle.SetPoint("TOPLEFT", composition.frame, "TOPLEFT", 16, -14);
    const compositionHint = Native.createText(composition.frame, "Auto-fill what you do not care about. Choose exact builds only where you do.", "GameFontHighlightSmall", theme.colors.muted);
    compositionHint.SetPoint("TOPLEFT", compositionTitle, "BOTTOMLEFT", 0, -4);

    // Shared build selector --------------------------------------------------
    let selectorContext: SelectorContext = { mode: "DUNGEON", role: "DPS", index: 0 };

    const buildSelector = BuildSelectorUI.createBuildSelector(frame, {
        allowCount: true,
        maxCount: 40,
        onApply: (selection: BuildSelection) => {
            if (selectorContext.mode === "DUNGEON") {
                Model.setDungeonExact(selectorContext.role, selectorContext.index, selection.classId, selection.specId);
            } else if (selectorContext.mode === "RAID_ADD") {
                Model.addRequiredBuild(selectorContext.role, selection.classId, selection.specId, selection.count);
            } else {
                Model.replaceRequiredBuild(selectorContext.role, selectorContext.index, selection.classId, selection.specId, selection.count);
            }
        },
    });

    // Dungeon slots ----------------------------------------------------------
    const dungeonView = CreateFrame("Frame", undefined, composition.frame);
    dungeonView.SetPoint("TOPLEFT", composition.frame, "TOPLEFT", 14, -58);
    dungeonView.SetPoint("BOTTOMRIGHT", composition.frame, "BOTTOMRIGHT", -14, 14);

    const dungeonRows: any[] = [];
    for (let i = 0; i < 5; i += 1) {
        const row = Native.createPanel(dungeonView, theme.colors.background, theme.colors.border);
        row.frame.SetHeight(78);
        row.frame.SetPoint("TOPLEFT", dungeonView, "TOPLEFT", 0, -(i * 84));
        row.frame.SetPoint("RIGHT", dungeonView, "RIGHT", 0, 0);

        const accent = Native.createSolid(row.frame, theme.colors.dps, "ARTWORK");
        accent.SetWidth(4);
        accent.SetPoint("TOPLEFT", row.frame, "TOPLEFT", 0, 0);
        accent.SetPoint("BOTTOMLEFT", row.frame, "BOTTOMLEFT", 0, 0);

        const roleIcon = row.frame.CreateTexture(undefined, "ARTWORK");
        roleIcon.SetSize(28, 28);
        roleIcon.SetPoint("LEFT", row.frame, "LEFT", 16, 0);

        const roleText = Native.createText(row.frame, "DPS", "GameFontNormal");
        roleText.SetPoint("LEFT", roleIcon, "RIGHT", 10, 8);
        const slotText = Native.createText(row.frame, "Slot", "GameFontHighlightSmall", theme.colors.muted);
        slotText.SetPoint("LEFT", roleIcon, "RIGHT", 10, -10);

        const classIcon = row.frame.CreateTexture(undefined, "ARTWORK");
        classIcon.SetSize(38, 38);
        classIcon.SetPoint("LEFT", row.frame, "LEFT", 178, 0);
        classIcon.Hide();

        const specIcon = row.frame.CreateTexture(undefined, "ARTWORK");
        specIcon.SetSize(30, 30);
        specIcon.SetPoint("LEFT", classIcon, "RIGHT", 8, 0);
        specIcon.Hide();

        const name = Native.createText(row.frame, "Auto-fill bot", "GameFontNormal");
        name.SetPoint("TOPLEFT", row.frame, "TOPLEFT", 264, -20);
        name.SetWidth(270);
        const sub = Native.createText(row.frame, "Composer chooses a suitable build", "GameFontHighlightSmall", theme.colors.muted);
        sub.SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4);
        sub.SetWidth(330);

        const choose = ButtonUI.createButton(row.frame, { text: "Choose build", width: 130, height: 34, accent: theme.colors.primary });
        choose.frame.SetPoint("RIGHT", row.frame, "RIGHT", -84, 0);
        const auto = ButtonUI.createButton(row.frame, { text: "Auto", width: 66, height: 34 });
        auto.frame.SetPoint("RIGHT", row.frame, "RIGHT", -12, 0);

        dungeonRows.push({ row, accent, roleIcon, roleText, slotText, classIcon, specIcon, name, sub, choose, auto });
    }

    // Raid views -------------------------------------------------------------
    const raidView = CreateFrame("Frame", undefined, composition.frame);
    raidView.SetPoint("TOPLEFT", composition.frame, "TOPLEFT", 14, -52);
    raidView.SetPoint("BOTTOMRIGHT", composition.frame, "BOTTOMRIGHT", -14, 14);
    raidView.Hide();

    let raidTab: RaidTab = "QUICK";
    const tabQuick = ButtonUI.createButton(raidView, { text: "Quick Composition", width: 164, height: 32, accent: theme.colors.primary });
    tabQuick.frame.SetPoint("TOPLEFT", raidView, "TOPLEFT", 0, 0);
    const tabExact = ButtonUI.createButton(raidView, { text: "Exact Builds", width: 140, height: 32, accent: theme.colors.warning });
    tabExact.frame.SetPoint("LEFT", tabQuick.frame, "RIGHT", 8, 0);
    const tabRoster = ButtonUI.createButton(raidView, { text: "Prepared Roster", width: 150, height: 32, accent: theme.colors.success });
    tabRoster.frame.SetPoint("LEFT", tabExact.frame, "RIGHT", 8, 0);

    const quickView = CreateFrame("Frame", undefined, raidView);
    quickView.SetPoint("TOPLEFT", raidView, "TOPLEFT", 0, -46);
    quickView.SetPoint("BOTTOMRIGHT", raidView, "BOTTOMRIGHT", 0, 0);

    const exactView = CreateFrame("Frame", undefined, raidView);
    exactView.SetAllPoints(quickView);
    exactView.Hide();

    const rosterView = CreateFrame("Frame", undefined, raidView);
    rosterView.SetAllPoints(quickView);
    rosterView.Hide();

    const quickCards: Record<Role, any> = {} as Record<Role, any>;
    const roleOrder: Role[] = ["TANK", "HEALER", "DPS"];
    for (let i = 0; i < roleOrder.length; i += 1) {
        const role = roleOrder[i];
        const card = Native.createPanel(quickView, theme.colors.background, Model.roleAccent(role));
        card.frame.SetSize(282, 178);
        card.frame.SetPoint("TOPLEFT", quickView, "TOPLEFT", i * 294, -12);

        const icon = Native.createIcon(card.frame, D.ROLE_ICON[role], 34);
        icon.SetPoint("TOPLEFT", card.frame, "TOPLEFT", 14, -14);
        const label = Native.createText(card.frame, Model.roleLabel(role).toUpperCase(), "GameFontNormal", Model.roleAccent(role));
        label.SetPoint("LEFT", icon, "RIGHT", 10, 5);
        const note = Native.createText(card.frame, "Raid-wide role target", "GameFontHighlightSmall", theme.colors.muted);
        note.SetPoint("LEFT", icon, "RIGHT", 10, -12);

        const count = Native.createText(card.frame, "0", "GameFontNormalHuge");
        count.SetPoint("TOPLEFT", card.frame, "TOPLEFT", 18, -70);
        const botSlots = Native.createText(card.frame, "0 bot slots after humans", "GameFontHighlightSmall", theme.colors.muted);
        botSlots.SetPoint("TOPLEFT", count, "BOTTOMLEFT", 0, -7);

        let minus: UIButton | undefined;
        let plus: UIButton | undefined;
        if (role !== "DPS") {
            minus = ButtonUI.createButton(card.frame, { text: "-", width: 38, height: 32 });
            plus = ButtonUI.createButton(card.frame, { text: "+", width: 38, height: 32, accent: Model.roleAccent(role) });
            minus.frame.SetPoint("BOTTOMRIGHT", card.frame, "BOTTOMRIGHT", -58, 12);
            plus.frame.SetPoint("BOTTOMRIGHT", card.frame, "BOTTOMRIGHT", -12, 12);
        } else {
            const derived = Native.createText(card.frame, "Auto remainder", "GameFontHighlightSmall", theme.colors.muted);
            derived.SetPoint("BOTTOMRIGHT", card.frame, "BOTTOMRIGHT", -14, 20);
        }

        quickCards[role] = { card, count, botSlots, minus, plus };
    }

    function adjustRole(role: Role, delta: number): void {
        if (role === "DPS") return;
        const cfg = Model.config();
        const key = role === "TANK" ? "tanks" : "healers";
        const next = Math.max(0, Number(cfg[key] ?? 0) + delta);
        const nextDps = Number(cfg.dps ?? 0) - delta;
        if (nextDps < 0) return;
        cfg[key] = next;
        cfg.dps = nextDps;
        Model.touch("Role composition changed");
    }

    quickCards.TANK.minus.frame.SetScript("OnMouseDown", () => adjustRole("TANK", -1));
    quickCards.TANK.plus.frame.SetScript("OnMouseDown", () => adjustRole("TANK", 1));
    quickCards.HEALER.minus.frame.SetScript("OnMouseDown", () => adjustRole("HEALER", -1));
    quickCards.HEALER.plus.frame.SetScript("OnMouseDown", () => adjustRole("HEALER", 1));

    const exactColumns: Record<Role, any> = {} as Record<Role, any>;
    for (let i = 0; i < roleOrder.length; i += 1) {
        const role = roleOrder[i];
        const panel = Native.createPanel(exactView, theme.colors.background, Model.roleAccent(role));
        panel.frame.SetPoint("TOPLEFT", exactView, "TOPLEFT", i * 294, -8);
        panel.frame.SetSize(282, 410);

        const icon = Native.createIcon(panel.frame, D.ROLE_ICON[role], 28);
        icon.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 12, -12);
        const label = Native.createText(panel.frame, Model.roleLabel(role).toUpperCase(), "GameFontNormal", Model.roleAccent(role));
        label.SetPoint("LEFT", icon, "RIGHT", 9, 5);
        const count = Native.createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted);
        count.SetPoint("LEFT", icon, "RIGHT", 9, -12);

        const add = ButtonUI.createButton(panel.frame, { text: "+ Add build", width: 112, height: 30, accent: Model.roleAccent(role) });
        add.frame.SetPoint("TOPRIGHT", panel.frame, "TOPRIGHT", -10, -11);

        const scroll = ScrollUI.createScrollList(panel.frame, 258, 330);
        scroll.frame.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 12, -66);

        exactColumns[role] = { panel, count, add, scroll, rows: [] as any[] };
    }

    const groupCards: any[] = [];
    for (let g = 0; g < 8; g += 1) {
        const card = Native.createPanel(rosterView, theme.colors.background, theme.colors.border);
        const groupTitle = Native.createText(card.frame, "GROUP " + String(g + 1), "GameFontNormalSmall", theme.colors.muted);
        groupTitle.SetPoint("TOPLEFT", card.frame, "TOPLEFT", 10, -10);
        const rows: any[] = [];
        for (let r = 0; r < 5; r += 1) {
            const row = CreateFrame("Frame", undefined, card.frame);
            row.SetHeight(32);
            row.SetPoint("TOPLEFT", card.frame, "TOPLEFT", 8, -(36 + r * 35));
            row.SetPoint("RIGHT", card.frame, "RIGHT", -8, 0);

            const roleBar = Native.createSolid(row, theme.colors.dps, "ARTWORK");
            roleBar.SetWidth(3);
            roleBar.SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0);
            roleBar.SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0);

            const icon = row.CreateTexture(undefined, "ARTWORK");
            icon.SetSize(22, 22);
            icon.SetPoint("LEFT", row, "LEFT", 8, 0);
            icon.Hide();

            const name = Native.createText(row, "Empty", "GameFontHighlightSmall", theme.colors.muted);
            name.SetPoint("LEFT", row, "LEFT", 38, 7);
            name.SetWidth(112);
            const spec = Native.createText(row, "", "GameFontHighlightSmall", theme.colors.muted);
            spec.SetPoint("LEFT", row, "LEFT", 38, -8);
            spec.SetWidth(125);

            rows.push({ row, roleBar, icon, name, spec });
        }
        card.frame.Hide();
        groupCards.push({ card, groupTitle, rows });
    }

    // Status ----------------------------------------------------------------
    const statusTitle = Native.createText(status.frame, "COMPOSITION & STATUS", "GameFontNormal");
    statusTitle.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -16);

    const phaseDot = Native.createSolid(status.frame, theme.colors.primary, "ARTWORK");
    phaseDot.SetSize(10, 10);
    phaseDot.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 18, -54);
    const phaseText = Native.createText(status.frame, "Configure roster", "GameFontNormalLarge");
    phaseText.SetPoint("LEFT", phaseDot, "RIGHT", 10, 4);
    const phaseDetail = Native.createText(status.frame, "", "GameFontHighlightSmall", theme.colors.muted);
    phaseDetail.SetPoint("TOPLEFT", phaseText, "BOTTOMLEFT", 0, -4);
    phaseDetail.SetWidth(266);
    phaseDetail.SetJustifyV("TOP");

    const rosterCount = Native.createText(status.frame, "1 / 5", "GameFontNormalHuge");
    rosterCount.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -116);
    const sourceText = Native.createText(status.frame, "1 human  ·  4 bot slots", "GameFontHighlightSmall", theme.colors.muted);
    sourceText.SetPoint("TOPLEFT", rosterCount, "BOTTOMLEFT", 0, -6);

    const statusRoleChips: Record<Role, any> = {} as Record<Role, any>;
    for (let i = 0; i < roleOrder.length; i += 1) {
        const role = roleOrder[i];
        const chip = Native.createPanel(status.frame, theme.colors.background, Model.roleAccent(role));
        chip.frame.SetSize(88, 32);
        chip.frame.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16 + i * 96, -174);
        const icon = Native.createIcon(chip.frame, D.ROLE_ICON[role], 17);
        icon.SetPoint("LEFT", chip.frame, "LEFT", 7, 0);
        const label = Native.createText(chip.frame, "", "GameFontHighlightSmall", Model.roleAccent(role));
        label.SetPoint("LEFT", icon, "RIGHT", 6, 0);
        statusRoleChips[role] = { chip, label };
    }

    const progressBg = Native.createPanel(status.frame, theme.colors.background, theme.colors.border);
    progressBg.frame.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -222);
    progressBg.frame.SetSize(286, 12);
    const progressFill = Native.createSolid(progressBg.frame, theme.colors.primary, "ARTWORK");
    progressFill.SetPoint("TOPLEFT", progressBg.frame, "TOPLEFT", 2, -2);
    progressFill.SetPoint("BOTTOMLEFT", progressBg.frame, "BOTTOMLEFT", 2, 2);
    progressFill.SetWidth(1);
    const progressText = Native.createText(status.frame, "", "GameFontHighlightSmall", theme.colors.muted);
    progressText.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -244);
    progressText.SetWidth(286);

    const coverageTitle = Native.createText(status.frame, "COVERAGE", "GameFontNormalSmall", theme.colors.muted);
    coverageTitle.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -286);
    const coverageText = Native.createText(status.frame, "Build a roster to inspect coverage.", "GameFontHighlightSmall", theme.colors.muted);
    coverageText.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -308);
    coverageText.SetWidth(286);
    coverageText.SetJustifyV("TOP");

    const classIcons: WoWTexture[] = [];
    for (let i = 0; i < 10; i += 1) {
        const icon = status.frame.CreateTexture(undefined, "ARTWORK");
        icon.SetSize(20, 20);
        icon.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16 + i * 25, -356);
        icon.Hide();
        classIcons.push(icon);
    }

    const warningsTitle = Native.createText(status.frame, "NEXT STEP", "GameFontNormalSmall", theme.colors.warning);
    warningsTitle.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -396);
    const warningRows: WoWFontString[] = [];
    for (let i = 0; i < 3; i += 1) {
        const row = Native.createText(status.frame, "", "GameFontHighlightSmall", i === 0 ? theme.colors.warning : theme.colors.muted);
        row.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -(420 + i * 42));
        row.SetWidth(286);
        row.SetJustifyV("TOP");
        warningRows.push(row);
    }

    const buildButton = ButtonUI.createButton(status.frame, { text: "Build & Prepare", width: 286, height: 40, accent: theme.colors.primary, onClick: () => Model.buildAndPrepare() });
    buildButton.frame.SetPoint("BOTTOMLEFT", status.frame, "BOTTOMLEFT", 16, 66);

    let showAssembleConfirm = () => {};
    const assembleButton = ButtonUI.createButton(status.frame, { text: "Assemble", width: 210, height: 38, accent: theme.colors.success, onClick: () => showAssembleConfirm() });
    assembleButton.frame.SetPoint("BOTTOMLEFT", status.frame, "BOTTOMLEFT", 16, 18);
    const resetButton = ButtonUI.createButton(status.frame, { text: "Reset", width: 68, height: 38, accent: theme.colors.error, onClick: () => Model.clearPlan() });
    resetButton.frame.SetPoint("LEFT", assembleButton.frame, "RIGHT", 8, 0);

    // Templates modal --------------------------------------------------------
    const templatesModal = ModalUI.createModal(frame, 880, 620);
    templatesModal.setTitle("Templates");
    templatesModal.setSubtitle("Built-in starting points and your saved compositions.");

    const templateSaveLabel = Native.createText(templatesModal.content, "SAVE CURRENT", "GameFontNormalSmall", theme.colors.muted);
    templateSaveLabel.SetPoint("TOPLEFT", templatesModal.content, "TOPLEFT", 0, 0);
    const templateName = InputUI.createTextInput(templatesModal.content, 300, 34);
    templateName.frame.SetPoint("TOPLEFT", templatesModal.content, "TOPLEFT", 0, -24);
    const templateSave = ButtonUI.createButton(templatesModal.content, {
        text: "Save Current",
        width: 120,
        height: 34,
        accent: theme.colors.primary,
        onClick: () => {
            const name = templateName.getText();
            if (name !== "") {
                Model.saveProfile(name);
                templateName.clear();
                refreshTemplates();
            }
        },
    });
    templateSave.frame.SetPoint("LEFT", templateName.frame, "RIGHT", 8, 0);

    const builtinTitle = Native.createText(templatesModal.content, "BUILT-IN", "GameFontNormalSmall", theme.colors.muted);
    builtinTitle.SetPoint("TOPLEFT", templatesModal.content, "TOPLEFT", 0, -82);
    const customTitle = Native.createText(templatesModal.content, "MY TEMPLATES", "GameFontNormalSmall", theme.colors.muted);
    customTitle.SetPoint("TOPLEFT", templatesModal.content, "TOPLEFT", 420, -82);

    const builtinScroll = ScrollUI.createScrollList(templatesModal.content, 390, 410);
    builtinScroll.frame.SetPoint("TOPLEFT", templatesModal.content, "TOPLEFT", 0, -108);
    const customScroll = ScrollUI.createScrollList(templatesModal.content, 390, 410);
    customScroll.frame.SetPoint("TOPLEFT", templatesModal.content, "TOPLEFT", 420, -108);
    const builtinRows: WoWFrame[] = [];
    const customRows: WoWFrame[] = [];

    function clearDynamicRows(rows: WoWFrame[]): void {
        for (const row of rows) row.Hide();
    }

    function refreshTemplates(): void {
        clearDynamicRows(builtinRows);
        clearDynamicRows(customRows);

        const builtins = Model.listBuiltinProfiles();
        for (let i = 0; i < builtins.length; i += 1) {
            let row = builtinRows[i];
            if (row === undefined) {
                const panel = Native.createPanel(builtinScroll.content, theme.colors.background, theme.colors.border);
                panel.frame.SetSize(382, 40);
                const name = Native.createText(panel.frame, "", "GameFontHighlightSmall");
                name.SetPoint("LEFT", panel.frame, "LEFT", 10, 0);
                name.SetWidth(235);
                const load = ButtonUI.createButton(panel.frame, { text: "Load", width: 82, height: 28, accent: theme.colors.primary });
                load.frame.SetPoint("RIGHT", panel.frame, "RIGHT", -6, 0);
                (panel.frame as any)._name = name;
                (panel.frame as any)._load = load;
                row = panel.frame;
                builtinRows[i] = row;
            }
            row.ClearAllPoints();
            row.SetPoint("TOPLEFT", builtinScroll.content, "TOPLEFT", 0, -(i * 46));
            (row as any)._name.SetText(builtins[i]);
            const profileName = builtins[i];
            (row as any)._load.frame.SetScript("OnMouseDown", () => {
                Model.loadProfile(profileName);
                templatesModal.hide();
            });
            row.Show();
        }
        builtinScroll.setContentHeight(Math.max(410, builtins.length * 46));

        const customs = Model.listCustomProfiles();
        for (let i = 0; i < customs.length; i += 1) {
            let row = customRows[i];
            if (row === undefined) {
                const panel = Native.createPanel(customScroll.content, theme.colors.background, theme.colors.border);
                panel.frame.SetSize(382, 40);
                const name = Native.createText(panel.frame, "", "GameFontHighlightSmall");
                name.SetPoint("LEFT", panel.frame, "LEFT", 10, 0);
                name.SetWidth(190);
                const load = ButtonUI.createButton(panel.frame, { text: "Load", width: 68, height: 28, accent: theme.colors.primary });
                load.frame.SetPoint("RIGHT", panel.frame, "RIGHT", -74, 0);
                const remove = ButtonUI.createButton(panel.frame, { text: "Delete", width: 62, height: 28, accent: theme.colors.error });
                remove.frame.SetPoint("RIGHT", panel.frame, "RIGHT", -6, 0);
                (panel.frame as any)._name = name;
                (panel.frame as any)._load = load;
                (panel.frame as any)._remove = remove;
                row = panel.frame;
                customRows[i] = row;
            }
            row.ClearAllPoints();
            row.SetPoint("TOPLEFT", customScroll.content, "TOPLEFT", 0, -(i * 46));
            (row as any)._name.SetText(customs[i]);
            const profileName = customs[i];
            (row as any)._load.frame.SetScript("OnMouseDown", () => {
                Model.loadProfile(profileName);
                templatesModal.hide();
            });
            (row as any)._remove.frame.SetScript("OnMouseDown", () => {
                Model.deleteProfile(profileName);
                refreshTemplates();
            });
            row.Show();
        }
        customScroll.setContentHeight(Math.max(410, customs.length * 46));
    }

    showTemplates = () => {
        ChoiceUI.closeChoicePopup();
        refreshTemplates();
        templatesModal.show();
    };

    // Humans & Pins modal ----------------------------------------------------
    const peopleModal = ModalUI.createModal(frame, 900, 650);
    peopleModal.setTitle("Humans & Pins");
    peopleModal.setSubtitle("Real players stay locked. Pins request named companions without turning humans into disposable roster slots.");

    const peopleHumanTitle = Native.createText(peopleModal.content, "HUMAN ANCHORS", "GameFontNormalSmall", theme.colors.muted);
    peopleHumanTitle.SetPoint("TOPLEFT", peopleModal.content, "TOPLEFT", 0, 0);
    const humanScroll = ScrollUI.createScrollList(peopleModal.content, 820, 220);
    humanScroll.frame.SetPoint("TOPLEFT", peopleModal.content, "TOPLEFT", 0, -26);
    const humanRowsModal: WoWFrame[] = [];

    const pinTitle = Native.createText(peopleModal.content, "PIN COMPANION", "GameFontNormalSmall", theme.colors.muted);
    pinTitle.SetPoint("TOPLEFT", peopleModal.content, "TOPLEFT", 0, -266);
    const pinInput = InputUI.createTextInput(peopleModal.content, 230, 34);
    pinInput.frame.SetPoint("TOPLEFT", peopleModal.content, "TOPLEFT", 0, -292);

    let pinRole: Role = "DPS";
    let pinRequired = false;
    const pinRoleButtons: Record<Role, UIButton> = {
        TANK: ButtonUI.createButton(peopleModal.content, { text: "Tank", width: 78, height: 34, accent: theme.colors.tank }),
        HEALER: ButtonUI.createButton(peopleModal.content, { text: "Healer", width: 78, height: 34, accent: theme.colors.healer }),
        DPS: ButtonUI.createButton(peopleModal.content, { text: "DPS", width: 78, height: 34, accent: theme.colors.dps }),
    };
    pinRoleButtons.TANK.frame.SetPoint("LEFT", pinInput.frame, "RIGHT", 8, 0);
    pinRoleButtons.HEALER.frame.SetPoint("LEFT", pinRoleButtons.TANK.frame, "RIGHT", 6, 0);
    pinRoleButtons.DPS.frame.SetPoint("LEFT", pinRoleButtons.HEALER.frame, "RIGHT", 6, 0);
    for (const role of roleOrder) {
        const roleCopy = role;
        pinRoleButtons[role].frame.SetScript("OnMouseDown", () => {
            pinRole = roleCopy;
            refreshPeople();
        });
    }

    const pinToggle = ToggleUI.createToggle(
        peopleModal.content,
        "Required",
        () => pinRequired,
        (value) => { pinRequired = value; },
    );
    pinToggle.frame.SetPoint("LEFT", pinRoleButtons.DPS.frame, "RIGHT", 12, 0);
    pinToggle.frame.SetWidth(98);

    const addPinButton = ButtonUI.createButton(peopleModal.content, {
        text: "Pin Member",
        width: 110,
        height: 34,
        accent: theme.colors.primary,
        onClick: () => {
            const name = pinInput.getText();
            if (name !== "") {
                Model.addPin(name, pinRole, pinRequired);
                pinInput.clear();
                refreshPeople();
            }
        },
    });
    addPinButton.frame.SetPoint("TOPRIGHT", peopleModal.content, "TOPRIGHT", 0, -292);

    const pinListTitle = Native.createText(peopleModal.content, "PINNED MEMBERS", "GameFontNormalSmall", theme.colors.muted);
    pinListTitle.SetPoint("TOPLEFT", peopleModal.content, "TOPLEFT", 0, -344);
    const pinScroll = ScrollUI.createScrollList(peopleModal.content, 820, 170);
    pinScroll.frame.SetPoint("TOPLEFT", peopleModal.content, "TOPLEFT", 0, -370);
    const pinRows: WoWFrame[] = [];

    function refreshPeople(): void {
        clearDynamicRows(humanRowsModal);
        const list = Model.humans();

        for (let i = 0; i < list.length; i += 1) {
            const human = list[i];
            let row = humanRowsModal[i];
            if (row === undefined) {
                const panel = Native.createPanel(humanScroll.content, theme.colors.background, theme.colors.border);
                panel.frame.SetSize(812, 42);
                const icon = panel.frame.CreateTexture(undefined, "ARTWORK");
                icon.SetSize(26, 26);
                icon.SetPoint("LEFT", panel.frame, "LEFT", 8, 0);
                const name = Native.createText(panel.frame, "", "GameFontHighlightSmall");
                name.SetPoint("LEFT", panel.frame, "LEFT", 44, 0);
                name.SetWidth(250);
                const buttons: Record<Role, UIButton> = {
                    TANK: ButtonUI.createButton(panel.frame, { text: "Tank", width: 78, height: 28, accent: theme.colors.tank }),
                    HEALER: ButtonUI.createButton(panel.frame, { text: "Healer", width: 78, height: 28, accent: theme.colors.healer }),
                    DPS: ButtonUI.createButton(panel.frame, { text: "DPS", width: 78, height: 28, accent: theme.colors.dps }),
                };
                buttons.DPS.frame.SetPoint("RIGHT", panel.frame, "RIGHT", -8, 0);
                buttons.HEALER.frame.SetPoint("RIGHT", buttons.DPS.frame, "LEFT", -6, 0);
                buttons.TANK.frame.SetPoint("RIGHT", buttons.HEALER.frame, "LEFT", -6, 0);
                (panel.frame as any)._icon = icon;
                (panel.frame as any)._name = name;
                (panel.frame as any)._buttons = buttons;
                row = panel.frame;
                humanRowsModal[i] = row;
            }

            row.ClearAllPoints();
            row.SetPoint("TOPLEFT", humanScroll.content, "TOPLEFT", 0, -(i * 48));
            Native.setClassIcon((row as any)._icon, String(human.class));
            (row as any)._name.SetText((human.isPlayer ? "YOU  ·  " : "") + human.name + "  ·  " + Model.classLabel(String(human.class)));
            const selected = Model.config().humanRoles?.[human.name] as Role | undefined;

            for (const role of roleOrder) {
                const button = (row as any)._buttons[role] as UIButton;
                const allowed = classCanRole(String(human.class), role);
                button.setEnabled(allowed);
                button.setSelected(selected === role);
                const humanNameCopy = human.name;
                const roleCopy = role;
                button.frame.SetScript("OnMouseDown", () => {
                    if (allowed) {
                        Model.setHumanRole(humanNameCopy, roleCopy);
                        refreshPeople();
                    }
                });
            }
            row.Show();
        }
        humanScroll.setContentHeight(Math.max(220, list.length * 48));

        for (const role of roleOrder) pinRoleButtons[role].setSelected(pinRole === role);
        pinToggle.refresh();

        clearDynamicRows(pinRows);
        const pins = Model.pinnedMembers();
        for (let i = 0; i < pins.length; i += 1) {
            const pin = pins[i];
            let row = pinRows[i];
            if (row === undefined) {
                const panel = Native.createPanel(pinScroll.content, theme.colors.background, theme.colors.border);
                panel.frame.SetSize(812, 40);
                const name = Native.createText(panel.frame, "", "GameFontHighlightSmall");
                name.SetPoint("LEFT", panel.frame, "LEFT", 10, 0);
                name.SetWidth(260);
                const info = Native.createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted);
                info.SetPoint("LEFT", panel.frame, "LEFT", 280, 0);
                const remove = ButtonUI.createButton(panel.frame, { text: "Remove", width: 78, height: 28, accent: theme.colors.error });
                remove.frame.SetPoint("RIGHT", panel.frame, "RIGHT", -6, 0);
                (panel.frame as any)._name = name;
                (panel.frame as any)._info = info;
                (panel.frame as any)._remove = remove;
                row = panel.frame;
                pinRows[i] = row;
            }
            row.ClearAllPoints();
            row.SetPoint("TOPLEFT", pinScroll.content, "TOPLEFT", 0, -(i * 46));
            (row as any)._name.SetText(String(pin.name));
            (row as any)._info.SetText(Model.roleLabel(pin.role as Role) + "  ·  " + (pin.required ? "Required" : "Preferred"));
            const indexCopy = i + 1;
            (row as any)._remove.frame.SetScript("OnMouseDown", () => {
                Model.removePin(indexCopy);
                refreshPeople();
            });
            row.Show();
        }
        pinScroll.setContentHeight(Math.max(170, pins.length * 46));
    }

    showPeople = () => {
        ChoiceUI.closeChoicePopup();
        refreshPeople();
        peopleModal.show();
    };

    // Options modal ----------------------------------------------------------
    const optionsModal = ModalUI.createModal(frame, 700, 560);
    optionsModal.setTitle("Composition Options");
    optionsModal.setSubtitle("Keep the common path simple. These controls tune how Composer fills unspecified slots.");

    const optionDefs: Array<{ label: string; key: string; hint: string }> = [
        { label: "Prefer guild bots", key: "preferGuild", hint: "Use familiar guild companions first when suitable." },
        { label: "Allow world fallback", key: "fillWorld", hint: "Fill remaining slots from the world/reserve pool." },
        { label: "Balance classes", key: "balanceClasses", hint: "Avoid lopsided class coverage when Auto is used." },
        { label: "Balance utility", key: "balanceUtility", hint: "Prefer a healthier mix of raid/dungeon utility." },
        { label: "Balance melee / ranged", key: "balanceRange", hint: "Avoid extreme melee/ranged skew when possible." },
        { label: "Avoid duplicate classes", key: "avoidDuplicateClasses", hint: "Stricter diversity preference. Exact builds still win." },
        { label: "Queue random dungeon after assembly", key: "queueAfterAssemble", hint: "Only applies to Random Dungeon." },
    ];
    const optionToggles: any[] = [];

    for (let i = 0; i < optionDefs.length; i += 1) {
        const def = optionDefs[i];
        const row = Native.createPanel(optionsModal.content, theme.colors.background, theme.colors.border);
        row.frame.SetPoint("TOPLEFT", optionsModal.content, "TOPLEFT", 0, -(i * 62));
        row.frame.SetPoint("RIGHT", optionsModal.content, "RIGHT", 0, 0);
        row.frame.SetHeight(52);

        const toggle = ToggleUI.createToggle(
            row.frame,
            def.label,
            () => Model.config().options?.[def.key] === true,
            (value) => {
                Model.config().options[def.key] = value;
                Model.touch("Composition option changed");
            },
        );
        toggle.frame.SetPoint("TOPLEFT", row.frame, "TOPLEFT", 12, -5);
        toggle.frame.SetWidth(280);

        const hint = Native.createText(row.frame, def.hint, "GameFontHighlightSmall", theme.colors.muted);
        hint.SetPoint("TOPLEFT", row.frame, "TOPLEFT", 42, -31);
        hint.SetWidth(580);
        optionToggles.push(toggle);
    }

    showOptions = () => {
        ChoiceUI.closeChoicePopup();
        for (const toggle of optionToggles) toggle.refresh();
        optionsModal.show();
    };

    // Assemble confirmation --------------------------------------------------
    const confirmModal = ModalUI.createModal(frame, 560, 270);
    const confirmText = Native.createText(confirmModal.content, "", "GameFontHighlight", theme.colors.muted);
    confirmText.SetPoint("TOPLEFT", confirmModal.content, "TOPLEFT", 8, -8);
    confirmText.SetWidth(490);
    confirmText.SetJustifyH("CENTER");
    confirmText.SetJustifyV("TOP");

    const confirmCancel = ButtonUI.createButton(confirmModal.content, { text: "Cancel", width: 120, height: 36, onClick: () => confirmModal.hide() });
    confirmCancel.frame.SetPoint("BOTTOMLEFT", confirmModal.content, "BOTTOMLEFT", 112, 0);
    const confirmGo = ButtonUI.createButton(confirmModal.content, {
        text: "Assemble",
        width: 120,
        height: 36,
        accent: theme.colors.success,
        onClick: () => {
            confirmModal.hide();
            Model.assemble();
        },
    });
    confirmGo.frame.SetPoint("BOTTOMRIGHT", confirmModal.content, "BOTTOMRIGHT", -112, 0);

    showAssembleConfirm = () => {
        const p = Model.progress();
        if (p.phase !== "READY") {
            Model.fireStatus("Build & Prepare must finish first.");
            return;
        }
        const retry = Model.isTravelRetry();
        const cfg = Model.config();
        const activity = Model.selectedActivityLabel();

        if (retry) {
            confirmModal.setTitle("Enter selected activity?");
            confirmModal.setSubtitle("The reviewed roster is already assembled.");
            confirmText.SetText("Retry automatic entry for the complete group into " + activity + ". The roster will not be rebuilt.");
            confirmGo.setText("Enter Activity");
        } else if (cfg.mode === "DUNGEON" && cfg.activity === "random") {
            confirmModal.setTitle("Assemble prepared party?");
            confirmModal.setSubtitle("Composer will commit the reviewed roster.");
            confirmText.SetText("Prepared Playerbots attach directly. Real players keep normal group semantics. Dungeon Finder chooses the destination.");
            confirmGo.setText("Assemble");
        } else {
            confirmModal.setTitle("Assemble & enter?");
            confirmModal.setSubtitle("Composer will commit the reviewed roster.");
            confirmText.SetText("After validation, the complete group will automatically enter " + activity + ".");
            confirmGo.setText("Assemble");
        }
        confirmModal.show();
    };

    // Refresh helpers --------------------------------------------------------
    function refreshActivity(): void {
        const cfg = Model.config();
        activityName.SetText(Model.selectedActivityLabel());
        activitySub.SetText(activitySubtitle());
        activitySelect.refresh();
        difficultySelect.refresh();

        const sizes = Model.supportedRaidSizes();
        let sizeIndex = 0;
        for (const size of [10, 20, 25, 40]) {
            const button = raidSizeButtons[size];
            let supported = false;
            for (const allowed of sizes) if (allowed === size) { supported = true; break; }

            if (cfg.mode === "RAID" && supported) {
                button.frame.ClearAllPoints();
                button.frame.SetPoint("TOPLEFT", activity.frame, "TOPLEFT", 380 + sizeIndex * 58, -58);
                button.setSelected(Number(cfg.size) === size);
                button.setEnabled(true);
                button.frame.Show();
                sizeIndex += 1;
            } else {
                button.frame.Hide();
            }
        }
    }

    function refreshHumanPanel(): void {
        const list = Model.humans();
        const primary = list.length > 0 ? list[0] : undefined;
        if (primary === undefined) {
            humanName.SetText("Waiting for player...");
            humanSub.SetText("Composer is refreshing human anchors.");
            humanIcon.Hide();
            for (const role of roleOrder) humanRoleButtons[role].setEnabled(false);
            return;
        }

        humanIcon.Show();
        Native.setClassIcon(humanIcon, String(primary.class));
        humanName.SetText((primary.isPlayer ? "YOU  ·  " : "") + primary.name);
        humanSub.SetText(Model.classLabel(String(primary.class)) + (list.length > 1 ? "  ·  +" + String(list.length - 1) + " more human anchor" + (list.length > 2 ? "s" : "") : ""));

        const selected = Model.config().humanRoles?.[primary.name] as Role | undefined;
        for (const role of roleOrder) {
            const allowed = classCanRole(String(primary.class), role);
            humanRoleButtons[role].setEnabled(allowed);
            humanRoleButtons[role].setSelected(selected === role);
            const roleCopy = role;
            const nameCopy = primary.name;
            humanRoleButtons[role].frame.SetScript("OnMouseDown", () => {
                if (allowed) Model.setHumanRole(nameCopy, roleCopy);
            });
        }
    }

    function refreshDungeon(): void {
        const slots = buildDungeonModel();
        for (let i = 0; i < dungeonRows.length; i += 1) {
            const widgets = dungeonRows[i];
            const slot = slots[i];
            const accent = Model.roleAccent(slot.role);
            Native.setTextureColor(widgets.accent, accent);
            widgets.row.outline.setColor(theme.colors.borderStrong);
            widgets.roleIcon.SetTexture(D.ROLE_ICON[slot.role]);
            widgets.roleIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            widgets.roleText.SetText(Model.roleLabel(slot.role));
            widgets.roleText.SetTextColor(accent[0], accent[1], accent[2], 1);
            widgets.slotText.SetText(slot.human !== undefined ? "Human anchor" : "Bot slot " + String(slot.botIndex ?? 1));

            if (slot.human !== undefined) {
                Native.setClassIcon(widgets.classIcon, String(slot.human.class));
                widgets.classIcon.Show();
                widgets.specIcon.Hide();
                widgets.name.SetText((slot.human.isPlayer ? "YOU  ·  " : "") + slot.human.name);
                widgets.sub.SetText(Model.classLabel(String(slot.human.class)) + "  ·  Locked " + Model.roleLabel(slot.role));
                widgets.choose.frame.Hide();
                widgets.auto.frame.Hide();
                continue;
            }

            const exact = slot.exact;
            const prepared = slot.prepared;
            if (prepared !== undefined && Model.plan().ready === true) {
                Native.setClassIcon(widgets.classIcon, String(prepared.class));
                widgets.classIcon.Show();
                const specId = specIdFromLabel(String(prepared.class), String(prepared.spec));
                if (specId !== undefined) {
                    widgets.specIcon.SetTexture(Model.getSpecIcon(prepared.class as ClassId, specId));
                    widgets.specIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
                    widgets.specIcon.Show();
                } else widgets.specIcon.Hide();

                widgets.name.SetText(String(prepared.name));
                widgets.sub.SetText(String(prepared.spec || Model.classLabel(String(prepared.class))) + "  ·  " + String(prepared.source ?? "Bot"));
            } else if (exact !== undefined) {
                Native.setClassIcon(widgets.classIcon, exact.classId);
                widgets.classIcon.Show();
                widgets.specIcon.SetTexture(Model.getSpecIcon(exact.classId, exact.specId));
                widgets.specIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
                widgets.specIcon.Show();
                widgets.name.SetText(Model.getSpecLabel(exact.classId, exact.specId) + " " + Model.classLabel(exact.classId));
                widgets.sub.SetText("Exact build  ·  Composer will preserve this requirement");
            } else {
                widgets.classIcon.Hide();
                widgets.specIcon.Hide();
                widgets.name.SetText("Auto-fill bot");
                widgets.sub.SetText("Composer chooses a suitable " + Model.roleLabel(slot.role).toLowerCase() + " build");
            }

            const roleCopy = slot.role;
            const botIndex = slot.botIndex ?? 1;
            widgets.choose.setText(exact !== undefined ? "Change build" : "Choose build");
            widgets.choose.frame.SetScript("OnMouseDown", () => {
                selectorContext = { mode: "DUNGEON", role: roleCopy, index: botIndex };
                buildSelector.open(roleCopy, exact === undefined ? undefined : {
                    role: roleCopy,
                    classId: exact.classId,
                    specId: exact.specId,
                    count: 1,
                }, false);
            });
            widgets.choose.frame.Show();

            widgets.auto.setEnabled(exact !== undefined);
            widgets.auto.frame.SetScript("OnMouseDown", () => {
                if (exact !== undefined) Model.clearDungeonExact(roleCopy, botIndex);
            });
            widgets.auto.frame.Show();
        }
    }

    function refreshQuickRaid(): void {
        for (const role of roleOrder) {
            quickCards[role].count.SetText(String(Model.targetForRole(role)));
            quickCards[role].botSlots.SetText(String(Model.remainingBotSlots(role)) + " bot slots after humans");
        }
    }

    function refreshExactRaid(): void {
        for (const role of roleOrder) {
            const column = exactColumns[role];
            const rows = Model.requiredBuilds(role);
            column.count.SetText(String(Model.exactCount(role)) + " exact  ·  " + String(Math.max(0, Model.remainingBotSlots(role) - Model.exactCount(role))) + " Auto");
            column.add.setEnabled(Model.exactCount(role) < Model.remainingBotSlots(role));
            const roleCopy = role;
            column.add.frame.SetScript("OnMouseDown", () => {
                if (Model.exactCount(roleCopy) >= Model.remainingBotSlots(roleCopy)) return;
                selectorContext = { mode: "RAID_ADD", role: roleCopy, index: -1 };
                buildSelector.open(roleCopy, { role: roleCopy, count: 1 }, true);
            });

            for (const old of column.rows) old.frame.Hide();

            for (let i = 0; i < rows.length; i += 1) {
                const build = rows[i];
                let widgets = column.rows[i + 1];
                if (widgets === undefined) {
                    const panel = Native.createPanel(column.scroll.content, theme.colors.surfaceRaised, theme.colors.border);
                    panel.frame.SetSize(250, 52);
                    const classIcon = panel.frame.CreateTexture(undefined, "ARTWORK");
                    classIcon.SetSize(30, 30);
                    classIcon.SetPoint("LEFT", panel.frame, "LEFT", 8, 0);
                    const specIcon = panel.frame.CreateTexture(undefined, "ARTWORK");
                    specIcon.SetSize(24, 24);
                    specIcon.SetPoint("LEFT", classIcon, "RIGHT", 6, 0);
                    const name = Native.createText(panel.frame, "", "GameFontHighlightSmall");
                    name.SetPoint("LEFT", panel.frame, "LEFT", 76, 7);
                    name.SetWidth(112);
                    const count = Native.createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted);
                    count.SetPoint("LEFT", panel.frame, "LEFT", 76, -10);
                    const edit = ButtonUI.createButton(panel.frame, { text: "Edit", width: 46, height: 26, accent: theme.colors.primary });
                    edit.frame.SetPoint("RIGHT", panel.frame, "RIGHT", -54, 0);
                    const remove = ButtonUI.createButton(panel.frame, { text: "X", width: 40, height: 26, accent: theme.colors.error });
                    remove.frame.SetPoint("RIGHT", panel.frame, "RIGHT", -8, 0);
                    widgets = { panel, classIcon, specIcon, name, count, edit, remove };
                    column.rows[i + 1] = widgets;
                }

                widgets.panel.frame.ClearAllPoints();
                widgets.panel.frame.SetPoint("TOPLEFT", column.scroll.content, "TOPLEFT", 0, -(i * 58));
                Native.setClassIcon(widgets.classIcon, build.classId);
                widgets.specIcon.SetTexture(Model.getSpecIcon(build.classId, build.specId));
                widgets.specIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
                widgets.name.SetText(Model.getSpecLabel(build.classId, build.specId) + " " + Model.classLabel(build.classId));
                widgets.count.SetText("×" + String(build.count));

                const indexCopy = i;
                widgets.edit.frame.SetScript("OnMouseDown", () => {
                    selectorContext = { mode: "RAID_EDIT", role: roleCopy, index: indexCopy };
                    buildSelector.open(roleCopy, {
                        role: roleCopy,
                        classId: build.classId,
                        specId: build.specId,
                        count: build.count,
                    }, true);
                });
                widgets.remove.frame.SetScript("OnMouseDown", () => Model.removeRequiredBuild(roleCopy, indexCopy));
                widgets.panel.frame.Show();
            }

            column.scroll.setContentHeight(Math.max(330, rows.length * 58));
        }
    }

    function refreshRoster(): void {
        const cfg = Model.config();
        const totalGroups = Math.max(1, Math.ceil(Number(cfg.size ?? 5) / 5));
        const wideFive = totalGroups === 5;
        const columns = wideFive ? 5 : totalGroups >= 8 ? 4 : Math.min(4, totalGroups);
        const cardWidth = wideFive ? 168 : Math.floor((880 - (columns - 1) * 10) / columns);
        const cardHeight = totalGroups >= 8 ? 202 : 220;

        for (let g = 0; g < groupCards.length; g += 1) {
            const widgets = groupCards[g];
            if (g >= totalGroups) {
                widgets.card.frame.Hide();
                continue;
            }

            const column = g % columns;
            const row = Math.floor(g / columns);
            widgets.card.frame.ClearAllPoints();
            widgets.card.frame.SetPoint("TOPLEFT", rosterView, "TOPLEFT", column * (cardWidth + 10), -(8 + row * (cardHeight + 10)));
            widgets.card.frame.SetSize(cardWidth, cardHeight);
            widgets.groupTitle.SetText("GROUP " + String(g + 1));

            const members: any[] = [];
            for (const member of Model.planMembers()) if (Number(member.subgroup) === g + 1) members.push(member);

            for (let r = 0; r < 5; r += 1) {
                const rowWidgets = widgets.rows[r + 1];
                const member = members[r];
                if (member === undefined) {
                    rowWidgets.icon.Hide();
                    rowWidgets.name.SetText("Empty");
                    rowWidgets.name.SetTextColor(theme.colors.muted[0], theme.colors.muted[1], theme.colors.muted[2], 1);
                    rowWidgets.spec.SetText("");
                    Native.setTextureColor(rowWidgets.roleBar, theme.colors.borderStrong);
                } else {
                    Native.setClassIcon(rowWidgets.icon, String(member.class));
                    rowWidgets.icon.Show();
                    rowWidgets.name.SetText((member.isPlayer ? "YOU  ·  " : "") + String(member.name));
                    rowWidgets.name.SetTextColor(theme.colors.text[0], theme.colors.text[1], theme.colors.text[2], 1);
                    rowWidgets.spec.SetText(String(member.spec ?? Model.classLabel(String(member.class))));
                    Native.setTextureColor(rowWidgets.roleBar, Model.roleAccent(member.role as Role));
                }
            }
            widgets.card.frame.Show();
        }
    }

    function refreshRaidTabs(): void {
        const ready = Model.plan().ready === true && Model.plan().valid === true;
        tabQuick.setSelected(raidTab === "QUICK");
        tabExact.setSelected(raidTab === "EXACT");
        tabRoster.setSelected(raidTab === "ROSTER");
        tabRoster.setEnabled(ready);

        if (raidTab === "EXACT") {
            quickView.Hide();
            exactView.Show();
            rosterView.Hide();
        } else if (raidTab === "ROSTER" && ready) {
            quickView.Hide();
            exactView.Hide();
            rosterView.Show();
        } else {
            raidTab = "QUICK";
            quickView.Show();
            exactView.Hide();
            rosterView.Hide();
            tabQuick.setSelected(true);
            tabRoster.setSelected(false);
        }
    }

    tabQuick.frame.SetScript("OnMouseDown", () => { raidTab = "QUICK"; refreshRaidTabs(); });
    tabExact.frame.SetScript("OnMouseDown", () => { raidTab = "EXACT"; refreshRaidTabs(); });
    tabRoster.frame.SetScript("OnMouseDown", () => {
        if (Model.plan().ready === true && Model.plan().valid === true) {
            raidTab = "ROSTER";
            refreshRaidTabs();
        }
    });

    function refreshStatus(): void {
        const p = Model.progress();
        const phase = String(p.phase ?? "IDLE");
        const phaseColor = colorForPhase(phase);
        Native.setTextureColor(phaseDot, phaseColor);
        phaseText.SetText(Model.isTravelRetry() ? "Ready to enter activity" : Model.phaseLabel(phase));
        phaseText.SetTextColor(phaseColor[0], phaseColor[1], phaseColor[2], 1);
        phaseDetail.SetText(String(p.detail ?? ""));

        const humanCount = Model.humans().length;
        const target = Number(Model.config().size ?? 5);
        const total = Model.plan().ready === true ? Number(Model.plan().summary?.total ?? Model.planMembers().length) : humanCount;
        rosterCount.SetText(String(total) + " / " + String(target));

        if (Model.plan().ready === true) {
            sourceText.SetText(
                String(humanCount) + " human" + (humanCount === 1 ? "" : "s") +
                "  ·  " + String(Model.plan().summary?.guild ?? 0) + " guild  ·  " +
                String(Model.plan().summary?.world ?? 0) + " fallback"
            );
        } else {
            sourceText.SetText(String(humanCount) + " human" + (humanCount === 1 ? "" : "s") + "  ·  " + String(Math.max(0, target - humanCount)) + " bot slots");
        }

        statusRoleChips.TANK.label.SetText(String(Model.config().tanks ?? 0) + " T");
        statusRoleChips.HEALER.label.SetText(String(Model.config().healers ?? 0) + " H");
        statusRoleChips.DPS.label.SetText(String(Model.config().dps ?? 0) + " D");

        let ratio = 0;
        if (Number(p.total ?? 0) > 0) ratio = Math.min(1, Number(p.current ?? 0) / Number(p.total));
        else if (phase === "READY" || phase === "DONE") ratio = 1;
        progressFill.SetWidth(Math.max(1, 282 * ratio));
        Native.setTextureColor(progressFill, phaseColor);
        progressText.SetText(
            phase === "PREPARING" || phase === "ASSEMBLING" || phase === "READY" || phase === "DONE"
                ? String(p.current ?? 0) + " / " + String(p.total ?? 0) + "  ·  " + String(p.detail ?? "")
                : ""
        );

        coverageText.SetText(
            Model.plan().summary?.utility !== undefined
                ? String(Model.plan().summary.utility) + "\nRanged DPS: " + String(Model.plan().summary.ranged ?? 0) + "   Melee DPS: " + String(Model.plan().summary.melee ?? 0)
                : "Build a roster to inspect utility coverage."
        );

        const seen: Record<string, boolean> = {};
        let iconIndex = 0;
        for (const member of Model.planMembers()) {
            const cls = String(member.class ?? "");
            if (cls !== "" && cls !== "UNKNOWN" && seen[cls] !== true && iconIndex < classIcons.length) {
                seen[cls] = true;
                Native.setClassIcon(classIcons[iconIndex], cls);
                classIcons[iconIndex].Show();
                iconIndex += 1;
            }
        }
        for (let i = iconIndex; i < classIcons.length; i += 1) classIcons[i].Hide();

        const warnings = Model.planWarnings();
        for (let i = 0; i < warningRows.length; i += 1) {
            let text = warnings[i];
            if (text === undefined && i === 0) {
                if (phase === "READY") text = Model.isTravelRetry() ? "Clear the travel blocker, then enter the activity." : "Prepared roster is ready for review.";
                else if (phase === "PREPARING") text = "Bots are being prepared in the background.";
                else if (!Model.humanReady()) text = "Choose a legal role for every real player.";
                else text = "Build & Prepare when the composition looks right.";
            }
            warningRows[i].SetText(String(text ?? ""));
        }

        buildButton.setEnabled(Model.humanReady() && !Model.isBusy());
        assembleButton.setEnabled(Model.plan().ready === true && Model.plan().valid === true && phase === "READY");
        assembleButton.setText(Model.isTravelRetry() ? "Enter Activity" : (Model.config().mode === "RAID" ? "Assemble Raid" : "Assemble Party"));
        assembleButton.setSelected(Model.plan().ready === true && Model.plan().valid === true && phase === "READY");
    }

    function refresh(): void {
        if (!frame.IsShown()) return;

        const raid = Model.config().mode === "RAID";
        navDungeon.setSelected(!raid);
        navRaid.setSelected(raid);
        backendText.SetText(GC.backendSeen === true ? "Backend connected" : "Checking backend");
        Native.setTextureColor(backendDot, GC.backendSeen === true ? theme.colors.success : theme.colors.muted);

        refreshActivity();
        refreshHumanPanel();

        compositionTitle.SetText(raid ? "RAID COMPOSITION" : "FIVE-PLAYER PARTY");
        compositionHint.SetText(
            raid
                ? "Start simple with role counts. Add exact class/spec builds only where you care."
                : "Each bot slot can stay Auto or use one exact class/spec build."
        );

        if (raid) {
            dungeonView.Hide();
            raidView.Show();
            refreshQuickRaid();
            refreshExactRaid();
            refreshRoster();
            refreshRaidTabs();
        } else {
            raidView.Hide();
            dungeonView.Show();
            refreshDungeon();
        }

        refreshStatus();
    }

    function applyScale(): void {
        const width = UIParent.GetWidth() || 1920;
        const height = UIParent.GetHeight() || 1080;
        const scale = Math.min((width - 24) / 1480, (height - 24) / 880);
        frame.SetScale(Math.max(0.68, Math.min(1.10, scale)));
    }

    const dashboard: Dashboard = {
        frame,
        show: () => {
            ChoiceUI.closeChoicePopup();
            applyScale();
            frame.Show();
            refresh();
            Model.requestAnchors();
            Model.requestStatus();
        },
        hide: () => {
            ChoiceUI.closeChoicePopup();
            frame.Hide();
        },
        toggle: () => {
            if (frame.IsShown()) dashboard.hide();
            else dashboard.show();
        },
        refresh: () => refresh(),
        applyScale: () => applyScale(),
    };

    GC.Toggle = () => dashboard.toggle();

    GC.RegisterCallback("CONFIG_CHANGED", () => refresh());
    GC.RegisterCallback("PLAN_CHANGED", () => {
        if (Model.config().mode === "RAID" && Model.plan().ready === true && Model.plan().valid === true) raidTab = "ROSTER";
        refresh();
    });
    GC.RegisterCallback("PROGRESS_CHANGED", () => refresh());
    GC.RegisterCallback("HUMANS_CHANGED", () => refresh());
    GC.RegisterCallback("PROFILES_CHANGED", () => {
        if (templatesModal.frame.IsShown()) refreshTemplates();
        refresh();
    });
    GC.RegisterCallback("STATUS", (text: string) => {
        footerText.SetText(String(text ?? "Ready."));
        refresh();
    });
    GC.RegisterCallback("DISPLAY_CHANGED", () => applyScale());

    return dashboard;
}

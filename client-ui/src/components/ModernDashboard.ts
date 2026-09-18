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
import * as StepperUI from "../widgets/Stepper";

const GC: any = Model.composer();
const D: any = Model.data();
const P: any = Model.profiles();

const ICON_DUNGEON = "Interface\\Icons\\Spell_Arcane_PortalDalaran";
const ICON_RAID = "Interface\\Icons\\Achievement_Boss_LichKing";
const ICON_TEMPLATES = "Interface\\Icons\\INV_Scroll_03";
const ICON_PEOPLE = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02";
const ICON_OPTIONS = "Interface\\Icons\\INV_Gizmo_02";
const ICON_COVERAGE = "Interface\\Icons\\INV_Misc_Map_01";

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
    frame.SetSize(1520, 900);
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
    Native.createChrome(frame);

    const header = Native.createPanel(frame, theme.colors.surface, theme.colors.border);
    header.frame.SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1);
    header.frame.SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1);
    header.frame.SetHeight(64);
    const headerAccent = Native.createSolid(header.frame, theme.colors.primary, "OVERLAY");
    headerAccent.SetPoint("TOPLEFT", header.frame, "TOPLEFT", 0, 0);
    headerAccent.SetPoint("TOPRIGHT", header.frame, "TOPRIGHT", 0, 0);
    headerAccent.SetHeight(2);

    const mark = Native.createPanel(header.frame, theme.colors.surfaceBlue, theme.colors.primary);
    mark.frame.SetSize(40, 40);
    Native.createChrome(mark.frame, theme.colors.primary);
    mark.frame.SetPoint("LEFT", header.frame, "LEFT", 18, 0);
    const markText = Native.createText(mark.frame, "GC", "GameFontNormalLarge", theme.colors.primary);
    markText.SetPoint("CENTER", mark.frame, "CENTER", 0, 0);
    markText.SetJustifyH("CENTER");

    const title = Native.createText(header.frame, "GROUP COMPOSER", "GameFontNormalLarge");
    title.SetPoint("TOPLEFT", header.frame, "TOPLEFT", 70, -12);
    const subtitle = Native.createText(header.frame, "Build the team you want, then let Composer prepare it.", "GameFontHighlightSmall", theme.colors.muted);
    subtitle.SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4);

    const backendDot = Native.createSolid(header.frame, theme.colors.muted, "ARTWORK");
    backendDot.SetSize(8, 8);
    backendDot.SetPoint("RIGHT", header.frame, "RIGHT", -238, 0);
    const backendText = Native.createText(header.frame, "Checking backend", "GameFontHighlightSmall", theme.colors.muted);
    backendText.SetPoint("LEFT", backendDot, "RIGHT", 8, 0);

    const close = ButtonUI.createButton(header.frame, { text: "Close", width: 100, height: 32, accent: theme.colors.error, onClick: () => frame.Hide() });
    close.frame.SetPoint("RIGHT", header.frame, "RIGHT", -16, 0);

    const sidebar = Native.createPanel(frame, theme.colors.surface, theme.colors.border);
    sidebar.frame.SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -65);
    sidebar.frame.SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 34);
    sidebar.frame.SetWidth(168);

    const navTitle = Native.createText(sidebar.frame, "COMPOSE", "GameFontNormalSmall", theme.colors.muted);
    navTitle.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 14, -20);

    const navDungeon = ButtonUI.createButton(sidebar.frame, {
        text: "Dungeon", width: 136, height: 46, accent: theme.colors.primary, icon: ICON_DUNGEON, iconSize: 24,
        onClick: () => Model.setMode("DUNGEON"),
    });
    navDungeon.frame.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 14, -48);
    navDungeon.label.SetJustifyH("LEFT");
    const navRaid = ButtonUI.createButton(sidebar.frame, {
        text: "Raid", width: 136, height: 46, accent: theme.colors.warning, icon: ICON_RAID, iconSize: 24,
        onClick: () => Model.setMode("RAID"),
    });
    navRaid.frame.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 14, -102);
    navRaid.label.SetJustifyH("LEFT");

    const manageTitle = Native.createText(sidebar.frame, "TOOLS", "GameFontNormalSmall", theme.colors.muted);
    manageTitle.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 14, -170);

    let showTemplates = () => {};
    let showPeople = () => {};
    let showOptions = () => {};

    const navTemplates = ButtonUI.createButton(sidebar.frame, { text: "Templates", width: 136, height: 42, icon: ICON_TEMPLATES, iconSize: 22, onClick: () => showTemplates() });
    navTemplates.frame.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 14, -198);
    navTemplates.label.SetJustifyH("LEFT");
    const navPeople = ButtonUI.createButton(sidebar.frame, { text: "Humans & Pins", width: 136, height: 42, icon: ICON_PEOPLE, iconSize: 22, onClick: () => showPeople() });
    navPeople.frame.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 14, -248);
    navPeople.label.SetJustifyH("LEFT");
    const navOptions = ButtonUI.createButton(sidebar.frame, { text: "Options", width: 136, height: 42, icon: ICON_OPTIONS, iconSize: 22, onClick: () => showOptions() });
    navOptions.frame.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 14, -298);
    navOptions.label.SetJustifyH("LEFT");

    const sideHint = Native.createText(sidebar.frame, "Humans stay locked.\nSpecific builds reserve bot slots; everything else stays Auto.", "GameFontHighlightSmall", theme.colors.muted);
    sideHint.SetPoint("BOTTOMLEFT", sidebar.frame, "BOTTOMLEFT", 16, 18);
    sideHint.SetWidth(136);
    sideHint.SetJustifyV("TOP");

    const center = CreateFrame("Frame", undefined, frame);
    center.SetPoint("TOPLEFT", frame, "TOPLEFT", 184, -80);
    center.SetSize(986, 776);

    const status = Native.createPanel(frame, theme.colors.surface, theme.colors.borderStrong);
    status.frame.SetPoint("TOPLEFT", frame, "TOPLEFT", 1186, -80);
    status.frame.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 48);

    const footer = Native.createPanel(frame, theme.colors.surface, theme.colors.border);
    footer.frame.SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 184, 10);
    footer.frame.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 10);
    footer.frame.SetHeight(26);
    const footerText = Native.createText(footer.frame, "Ready.", "GameFontHighlightSmall", theme.colors.muted);
    footerText.SetPoint("LEFT", footer.frame, "LEFT", 10, 0);
    footerText.SetPoint("RIGHT", footer.frame, "RIGHT", -10, 0);

    // Activity ---------------------------------------------------------------
    const activity = Native.createPanel(center, theme.colors.surface, theme.colors.borderStrong);
    activity.frame.SetPoint("TOPLEFT", center, "TOPLEFT", 0, 0);
    activity.frame.SetPoint("TOPRIGHT", center, "TOPRIGHT", 0, 0);
    activity.frame.SetHeight(116);

    const activityEyebrow = Native.createText(activity.frame, "ACTIVITY", "GameFontNormalSmall", theme.colors.muted);
    activityEyebrow.SetPoint("TOPLEFT", activity.frame, "TOPLEFT", 16, -12);

    const activityBadge = Native.createFramedIcon(activity.frame, ICON_DUNGEON, 58, theme.colors.borderStrong);
    activityBadge.frame.SetPoint("TOPLEFT", activity.frame, "TOPLEFT", 16, -38);

    const activityName = Native.createText(activity.frame, "Dungeon", "GameFontNormalLarge");
    activityName.SetPoint("TOPLEFT", activity.frame, "TOPLEFT", 88, -38);
    activityName.SetWidth(226);
    const activitySub = Native.createText(activity.frame, "", "GameFontHighlightSmall", theme.colors.muted);
    activitySub.SetPoint("TOPLEFT", activityName, "BOTTOMLEFT", 0, -5);
    activitySub.SetWidth(226);
    const activityEligibility = Native.createText(activity.frame, "", "GameFontHighlightSmall", theme.colors.success);
    activityEligibility.SetPoint("TOPLEFT", activitySub, "BOTTOMLEFT", 0, -7);
    activityEligibility.SetWidth(226);

    const activityFieldLabel = Native.createText(activity.frame, "DUNGEON", "GameFontNormalSmall", theme.colors.muted);
    activityFieldLabel.SetPoint("TOPLEFT", activity.frame, "TOPLEFT", 330, -12);
    const difficultyFieldLabel = Native.createText(activity.frame, "DIFFICULTY", "GameFontNormalSmall", theme.colors.muted);
    difficultyFieldLabel.SetPoint("TOPLEFT", activity.frame, "TOPLEFT", 702, -12);

    const activitySelect = ChoiceUI.createChoiceSelect(activity.frame, {
        width: 344,
        maxVisible: 10,
        getItems: () => Model.config().mode === "RAID" ? Model.raidItems() : Model.dungeonItems(),
        getValue: () => Model.config().activity,
        onChange: (value) => {
            if (Model.config().mode === "RAID") Model.setRaidActivity(String(value));
            else Model.setDungeonActivity(String(value));
        },
    });
    activitySelect.frame.SetPoint("TOPLEFT", activity.frame, "TOPLEFT", 330, -36);

    const difficultySelect = ChoiceUI.createChoiceSelect(activity.frame, {
        width: 170,
        maxVisible: 7,
        getItems: () => Model.config().mode === "RAID" ? Model.raidDifficultyItems() : Model.difficultyItems(),
        getValue: () => Model.config().difficulty,
        onChange: (value) => Model.setDifficulty(String(value)),
    });
    difficultySelect.frame.SetPoint("TOPLEFT", activity.frame, "TOPLEFT", 702, -36);

    const raidSizeLabel = Native.createText(activity.frame, "RAID SIZE", "GameFontNormalSmall", theme.colors.muted);
    raidSizeLabel.SetPoint("TOPLEFT", activity.frame, "TOPLEFT", 702, -78);
    raidSizeLabel.Hide();

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
    humanPanel.frame.SetPoint("TOPLEFT", center, "TOPLEFT", 0, -128);
    humanPanel.frame.SetPoint("TOPRIGHT", center, "TOPRIGHT", 0, -128);
    humanPanel.frame.SetHeight(78);

    const humanTitle = Native.createText(humanPanel.frame, "YOUR PARTY", "GameFontNormalSmall", theme.colors.muted);
    humanTitle.SetPoint("TOPLEFT", humanPanel.frame, "TOPLEFT", 16, -12);

    const humanIcon = humanPanel.frame.CreateTexture(undefined, "ARTWORK");
    humanIcon.SetSize(34, 34);
    humanIcon.SetPoint("BOTTOMLEFT", humanPanel.frame, "BOTTOMLEFT", 16, 9);
    Native.setClassIcon(humanIcon, "WARRIOR");

    const humanName = Native.createText(humanPanel.frame, "Choose your role", "GameFontNormal");
    humanName.SetPoint("TOPLEFT", humanIcon, "TOPRIGHT", 10, 0);
    humanName.SetWidth(360);
    const humanSub = Native.createText(humanPanel.frame, "Real players are locked anchors.", "GameFontHighlightSmall", theme.colors.muted);
    humanSub.SetPoint("TOPLEFT", humanName, "BOTTOMLEFT", 0, -5);
    humanSub.SetWidth(430);

    const yourRoleLabel = Native.createText(humanPanel.frame, "YOUR ROLE", "GameFontNormalSmall", theme.colors.muted);
    yourRoleLabel.SetPoint("TOPRIGHT", humanPanel.frame, "TOPRIGHT", -16, -12);

    const humanRoleButtons: Record<Role, UIButton> = {
        TANK: ButtonUI.createButton(humanPanel.frame, { text: "Tank", width: 96, height: 36, accent: theme.colors.tank }),
        HEALER: ButtonUI.createButton(humanPanel.frame, { text: "Healer", width: 96, height: 36, accent: theme.colors.healer }),
        DPS: ButtonUI.createButton(humanPanel.frame, { text: "DPS", width: 96, height: 36, accent: theme.colors.dps }),
    };
    humanRoleButtons.TANK.frame.SetPoint("TOPRIGHT", humanPanel.frame, "TOPRIGHT", -224, -34);
    humanRoleButtons.HEALER.frame.SetPoint("LEFT", humanRoleButtons.TANK.frame, "RIGHT", 8, 0);
    humanRoleButtons.DPS.frame.SetPoint("LEFT", humanRoleButtons.HEALER.frame, "RIGHT", 8, 0);

    for (const role of ["TANK", "HEALER", "DPS"] as Role[]) {
        const button = humanRoleButtons[role];
        const icon = Native.createIcon(button.frame, D.ROLE_ICON[role], 18);
        icon.SetPoint("LEFT", button.frame, "LEFT", 10, 0);
        button.label.ClearAllPoints();
        button.label.SetPoint("LEFT", button.frame, "LEFT", 34, 0);
        button.label.SetJustifyH("LEFT");
    }


    // Composition shell ------------------------------------------------------
    const composition = Native.createPanel(center, theme.colors.surface, theme.colors.border);
    composition.frame.SetPoint("TOPLEFT", center, "TOPLEFT", 0, -218);
    composition.frame.SetPoint("BOTTOMRIGHT", center, "BOTTOMRIGHT", 0, 0);

    const compositionTitle = Native.createText(composition.frame, "PARTY COMPOSITION", "GameFontNormal");
    compositionTitle.SetPoint("TOPLEFT", composition.frame, "TOPLEFT", 18, -14);
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
    dungeonView.SetPoint("TOPLEFT", composition.frame, "TOPLEFT", 16, -62);
    dungeonView.SetPoint("BOTTOMRIGHT", composition.frame, "BOTTOMRIGHT", -16, 16);

    const dungeonRows: any[] = [];
    for (let i = 0; i < 5; i += 1) {
        const row = Native.createPanel(dungeonView, theme.colors.surfaceRaised, theme.colors.border);
        row.frame.SetHeight(66);
        row.frame.SetPoint("TOPLEFT", dungeonView, "TOPLEFT", 0, -(i * 72));
        row.frame.SetPoint("RIGHT", dungeonView, "RIGHT", 0, 0);

        const accent = Native.createSolid(row.frame, theme.colors.dps, "ARTWORK");
        accent.SetWidth(4);
        accent.SetPoint("TOPLEFT", row.frame, "TOPLEFT", 0, 0);
        accent.SetPoint("BOTTOMLEFT", row.frame, "BOTTOMLEFT", 0, 0);

        const roleBadge = Native.createFramedIcon(row.frame, D.ROLE_ICON.DPS, 38, theme.colors.borderStrong);
        roleBadge.frame.SetPoint("LEFT", row.frame, "LEFT", 12, 0);
        const roleIcon = roleBadge.icon;

        const roleText = Native.createText(row.frame, "DPS", "GameFontNormal");
        roleText.SetPoint("LEFT", roleBadge.frame, "RIGHT", 10, 8);
        const slotText = Native.createText(row.frame, "Slot", "GameFontHighlightSmall", theme.colors.muted);
        slotText.SetPoint("LEFT", roleBadge.frame, "RIGHT", 10, -10);

        const classIcon = row.frame.CreateTexture(undefined, "ARTWORK");
        classIcon.SetSize(36, 36);
        classIcon.SetPoint("LEFT", row.frame, "LEFT", 174, 0);
        classIcon.Hide();

        const specIcon = row.frame.CreateTexture(undefined, "ARTWORK");
        specIcon.SetSize(28, 28);
        specIcon.SetPoint("LEFT", classIcon, "RIGHT", 8, 0);
        specIcon.Hide();

        const name = Native.createText(row.frame, "Auto-fill bot", "GameFontNormal");
        name.SetPoint("TOPLEFT", row.frame, "TOPLEFT", 252, -15);
        name.SetWidth(350);
        const sub = Native.createText(row.frame, "Composer chooses a suitable build", "GameFontHighlightSmall", theme.colors.muted);
        sub.SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4);
        sub.SetWidth(390);

        const choose = ButtonUI.createButton(row.frame, { text: "Choose build", width: 130, height: 34, accent: theme.colors.primary });
        choose.frame.SetPoint("RIGHT", row.frame, "RIGHT", -82, 0);
        const auto = ButtonUI.createButton(row.frame, { text: "Auto", width: 66, height: 34 });
        auto.frame.SetPoint("RIGHT", row.frame, "RIGHT", -12, 0);

        dungeonRows.push({ row, accent, roleIcon, roleText, slotText, classIcon, specIcon, name, sub, choose, auto });
    }

    // Raid views -------------------------------------------------------------
    const raidView = CreateFrame("Frame", undefined, composition.frame);
    raidView.SetPoint("TOPLEFT", composition.frame, "TOPLEFT", 16, -56);
    raidView.SetPoint("BOTTOMRIGHT", composition.frame, "BOTTOMRIGHT", -16, 16);
    raidView.Hide();

    let raidTab: RaidTab = "QUICK";
    const tabQuick = ButtonUI.createButton(raidView, { text: "Quick Composition", width: 164, height: 34, accent: theme.colors.primary });
    tabQuick.frame.SetPoint("TOPLEFT", raidView, "TOPLEFT", 0, 0);
    const tabExact = ButtonUI.createButton(raidView, { text: "Specific Builds", width: 150, height: 34, accent: theme.colors.warning });
    tabExact.frame.SetPoint("LEFT", tabQuick.frame, "RIGHT", 8, 0);
    const tabRoster = ButtonUI.createButton(raidView, { text: "Prepared Roster", width: 150, height: 34, accent: theme.colors.success });
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
        const card = Native.createPanel(quickView, theme.colors.surfaceDeep, theme.colors.borderStrong);
        card.frame.SetSize(300, 170);
        const roleStrip = Native.createSolid(card.frame, Model.roleAccent(role), "ARTWORK");
        roleStrip.SetHeight(4);
        roleStrip.SetPoint("TOPLEFT", card.frame, "TOPLEFT", 0, 0);
        roleStrip.SetPoint("TOPRIGHT", card.frame, "TOPRIGHT", 0, 0);
        const roleTint = Native.createSolid(card.frame, Native.withAlpha(Model.roleAccent(role), 0.055), "BACKGROUND");
        roleTint.SetAllPoints(card.frame);
        card.frame.SetPoint("TOPLEFT", quickView, "TOPLEFT", i * 312, -12);

        const roleBadge = Native.createFramedIcon(card.frame, D.ROLE_ICON[role], 48, Model.roleAccent(role));
        roleBadge.frame.SetPoint("TOP", card.frame, "TOP", -44, -16);
        const label = Native.createText(card.frame, Model.roleLabel(role).toUpperCase(), "GameFontNormalLarge", Model.roleAccent(role));
        label.SetPoint("LEFT", roleBadge.frame, "RIGHT", 12, 0);

        const minus = ButtonUI.createButton(card.frame, { text: "-", width: 42, height: 38, accent: Model.roleAccent(role) });
        minus.frame.SetPoint("TOPLEFT", card.frame, "TOPLEFT", 44, -78);
        const count = Native.createText(card.frame, "0", "GameFontNormalHuge");
        count.SetPoint("CENTER", card.frame, "CENTER", 0, -9);
        count.SetWidth(80);
        count.SetJustifyH("CENTER");
        const plus = ButtonUI.createButton(card.frame, { text: "+", width: 42, height: 38, accent: Model.roleAccent(role) });
        plus.frame.SetPoint("TOPRIGHT", card.frame, "TOPRIGHT", -44, -78);

        const botSlots = Native.createText(card.frame, "0 bot slots after humans", "GameFontHighlightSmall", theme.colors.muted);
        botSlots.SetPoint("BOTTOM", card.frame, "BOTTOM", 0, 17);
        botSlots.SetWidth(260);
        botSlots.SetJustifyH("CENTER");

        const roleCopy = role;
        minus.frame.SetScript("OnMouseDown", () => Model.setRoleTarget(roleCopy, Model.targetForRole(roleCopy) - 1));
        plus.frame.SetScript("OnMouseDown", () => Model.setRoleTarget(roleCopy, Model.targetForRole(roleCopy) + 1));

        quickCards[role] = { card, count, botSlots, minus, plus };
    }

    const quickSummary = Native.createPanel(quickView, theme.colors.background, theme.colors.border);
    quickSummary.frame.SetPoint("TOPLEFT", quickView, "TOPLEFT", 0, -198);
    quickSummary.frame.SetPoint("TOPRIGHT", quickView, "TOPRIGHT", 0, -198);
    quickSummary.frame.SetHeight(84);

    const quickTotalLabel = Native.createText(quickSummary.frame, "ROLE TOTAL", "GameFontNormalSmall", theme.colors.muted);
    quickTotalLabel.SetPoint("TOPLEFT", quickSummary.frame, "TOPLEFT", 14, -12);
    const quickTotal = Native.createText(quickSummary.frame, "25 / 25", "GameFontNormalLarge");
    quickTotal.SetPoint("TOPLEFT", quickSummary.frame, "TOPLEFT", 14, -34);
    const quickCheck = Native.createPanel(quickSummary.frame, theme.colors.surfaceBlue, theme.colors.success);
    quickCheck.frame.SetSize(28, 28);
    quickCheck.frame.SetPoint("LEFT", quickSummary.frame, "LEFT", 116, 0);
    const quickCheckText = Native.createText(quickCheck.frame, "✓", "GameFontNormal", theme.colors.success);
    quickCheckText.SetPoint("CENTER", quickCheck.frame, "CENTER", 0, 0);
    quickCheckText.SetJustifyH("CENTER");

    const quickHelp = Native.createText(
        quickSummary.frame,
        "All role counts are editable. Specific Builds reserve only the class/spec slots you care about.",
        "GameFontHighlightSmall",
        theme.colors.muted,
    );
    quickHelp.SetPoint("TOPLEFT", quickSummary.frame, "TOPLEFT", 156, -27);
    quickHelp.SetWidth(520);
    quickHelp.SetJustifyV("TOP");

    const resetRoles = ButtonUI.createButton(quickSummary.frame, {
        text: "Reset Standard",
        width: 132,
        height: 34,
        onClick: () => Model.resetRoleTargets(),
    });
    resetRoles.frame.SetPoint("RIGHT", quickSummary.frame, "RIGHT", -14, 0);

    // One full-width, vertically scrollable surface replaces the three cramped fixed columns.
    const exactScroll = ScrollUI.createScrollList(exactView, 936, 386);
    exactScroll.frame.SetPoint("TOPLEFT", exactView, "TOPLEFT", 0, -4);

    const exactSections: Record<Role, any> = {} as Record<Role, any>;
    for (const role of roleOrder) {
        const panel = Native.createPanel(exactScroll.content, theme.colors.background, theme.colors.border);
        panel.frame.SetWidth(906);

        const roleStrip = Native.createSolid(panel.frame, Model.roleAccent(role), "ARTWORK");
        roleStrip.SetHeight(4);
        roleStrip.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 0, 0);
        roleStrip.SetPoint("TOPRIGHT", panel.frame, "TOPRIGHT", 0, 0);
        const roleTint = Native.createSolid(panel.frame, Native.withAlpha(Model.roleAccent(role), 0.045), "BACKGROUND");
        roleTint.SetAllPoints(panel.frame);

        const roleBadge = Native.createFramedIcon(panel.frame, D.ROLE_ICON[role], 38, Model.roleAccent(role));
        roleBadge.frame.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 14, -12);
        const icon = roleBadge.icon;
        const label = Native.createText(panel.frame, Model.roleLabel(role).toUpperCase(), "GameFontNormal", Model.roleAccent(role));
        label.SetPoint("LEFT", roleBadge.frame, "RIGHT", 10, 5);
        const count = Native.createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted);
        count.SetPoint("LEFT", roleBadge.frame, "RIGHT", 10, -12);
        count.SetWidth(430);

        const add = ButtonUI.createButton(panel.frame, {
            text: "+ Add specific build",
            width: 168,
            height: 34,
            accent: Model.roleAccent(role),
            emphasis: true,
        });
        add.frame.SetPoint("TOPRIGHT", panel.frame, "TOPRIGHT", -12, -14);

        const empty = Native.createText(
            panel.frame,
            "No reserved builds. Composer will Auto-fill every remaining " + Model.roleLabel(role).toLowerCase() + " slot.",
            "GameFontHighlightSmall",
            theme.colors.muted,
        );
        empty.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 18, -68);
        empty.SetWidth(810);
        empty.SetJustifyV("TOP");

        exactScroll.bindWheel(panel.frame);
        exactScroll.bindWheel(add.frame);
        exactSections[role] = { panel, count, add, empty, rows: [] as any[] };
    }

    const groupCards: any[] = [];
    for (let g = 0; g < 8; g += 1) {
        const card = Native.createPanel(rosterView, theme.colors.background, theme.colors.border);
        const groupTitle = Native.createText(card.frame, "GROUP " + String(g + 1), "GameFontNormalSmall", theme.colors.muted);
        groupTitle.SetPoint("TOPLEFT", card.frame, "TOPLEFT", 10, -10);
        const rows: any[] = [];
        for (let r = 0; r < 5; r += 1) {
            const row = CreateFrame("Frame", undefined, card.frame);
            row.SetHeight(28);
            row.SetPoint("TOPLEFT", card.frame, "TOPLEFT", 8, -(34 + r * 30));
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
            name.SetWidth(154);
            const spec = Native.createText(row, "", "GameFontHighlightSmall", theme.colors.muted);
            spec.SetPoint("LEFT", row, "LEFT", 38, -8);
            spec.SetWidth(168);

            rows.push({ row, roleBar, icon, name, spec });
        }
        card.frame.Hide();
        groupCards.push({ card, groupTitle, rows });
    }

    // Status ----------------------------------------------------------------
    const statusTitle = Native.createText(status.frame, "ROSTER STATUS", "GameFontNormalSmall", theme.colors.muted);
    statusTitle.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -16);

    const phaseCard = Native.createPanel(status.frame, theme.colors.surfaceRaised, theme.colors.border);
    phaseCard.frame.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -40);
    phaseCard.frame.SetPoint("TOPRIGHT", status.frame, "TOPRIGHT", -16, -40);
    phaseCard.frame.SetHeight(84);

    const phaseDot = Native.createSolid(phaseCard.frame, theme.colors.primary, "ARTWORK");
    phaseDot.SetSize(9, 9);
    phaseDot.SetPoint("TOPLEFT", phaseCard.frame, "TOPLEFT", 12, -16);
    const phaseText = Native.createText(phaseCard.frame, "Configure roster", "GameFontNormal");
    phaseText.SetPoint("LEFT", phaseDot, "RIGHT", 10, 3);
    const phaseDetail = Native.createText(phaseCard.frame, "", "GameFontHighlightSmall", theme.colors.muted);
    phaseDetail.SetPoint("TOPLEFT", phaseText, "BOTTOMLEFT", 0, -4);
    phaseDetail.SetWidth(240);
    phaseDetail.SetJustifyV("TOP");

    const rosterCount = Native.createText(status.frame, "1 / 5", "GameFontNormalHuge");
    rosterCount.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -140);
    const sourceText = Native.createText(status.frame, "1 human  ·  4 bot slots", "GameFontHighlightSmall", theme.colors.muted);
    sourceText.SetPoint("TOPLEFT", rosterCount, "BOTTOMLEFT", 0, -5);

    const statusRoleChips: Record<Role, any> = {} as Record<Role, any>;
    for (let i = 0; i < roleOrder.length; i += 1) {
        const role = roleOrder[i];
        const chip = Native.createPanel(status.frame, theme.colors.background, Model.roleAccent(role));
        chip.frame.SetSize(84, 32);
        chip.frame.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16 + i * 92, -198);
        const icon = Native.createIcon(chip.frame, D.ROLE_ICON[role], 17);
        icon.SetPoint("LEFT", chip.frame, "LEFT", 7, 0);
        const label = Native.createText(chip.frame, "", "GameFontHighlightSmall", Model.roleAccent(role));
        label.SetPoint("LEFT", icon, "RIGHT", 6, 0);
        statusRoleChips[role] = { chip, label };
    }

    const progressBg = Native.createPanel(status.frame, theme.colors.background, theme.colors.border);
    progressBg.frame.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -242);
    progressBg.frame.SetSize(270, 10);
    const progressFill = Native.createSolid(progressBg.frame, theme.colors.primary, "ARTWORK");
    progressFill.SetPoint("TOPLEFT", progressBg.frame, "TOPLEFT", 2, -2);
    progressFill.SetPoint("BOTTOMLEFT", progressBg.frame, "BOTTOMLEFT", 2, 2);
    progressFill.SetWidth(1);
    const progressText = Native.createText(status.frame, "", "GameFontHighlightSmall", theme.colors.muted);
    progressText.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -260);
    progressText.SetWidth(270);

    const coverageCard = Native.createPanel(status.frame, theme.colors.background, theme.colors.border);
    coverageCard.frame.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -298);
    coverageCard.frame.SetPoint("TOPRIGHT", status.frame, "TOPRIGHT", -16, -286);
    coverageCard.frame.SetHeight(120);

    const coverageIcon = Native.createFramedIcon(coverageCard.frame, ICON_COVERAGE, 30, theme.colors.borderStrong);
    coverageIcon.frame.SetPoint("TOPLEFT", coverageCard.frame, "TOPLEFT", 12, -12);
    const coverageTitle = Native.createText(coverageCard.frame, "COVERAGE", "GameFontNormalSmall", theme.colors.muted);
    coverageTitle.SetPoint("LEFT", coverageIcon.frame, "RIGHT", 9, 0);
    const coverageText = Native.createText(coverageCard.frame, "Build a roster to inspect coverage.", "GameFontHighlightSmall", theme.colors.muted);
    coverageText.SetPoint("TOPLEFT", coverageCard.frame, "TOPLEFT", 12, -52);
    coverageText.SetWidth(246);
    coverageText.SetJustifyV("TOP");

    const classIcons: WoWTexture[] = [];
    for (let i = 0; i < 10; i += 1) {
        const icon = coverageCard.frame.CreateTexture(undefined, "ARTWORK");
        icon.SetSize(20, 20);
        icon.SetPoint("BOTTOMLEFT", coverageCard.frame, "BOTTOMLEFT", 12 + i * 25, 10);
        icon.Hide();
        classIcons.push(icon);
    }

    const nextCard = Native.createPanel(status.frame, theme.colors.background, theme.colors.border);
    nextCard.frame.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -434);
    nextCard.frame.SetPoint("TOPRIGHT", status.frame, "TOPRIGHT", -16, -414);
    nextCard.frame.SetHeight(126);

    const nextBadge = Native.createPanel(nextCard.frame, theme.colors.surfaceDeep, theme.colors.warning);
    nextBadge.frame.SetSize(28, 28);
    nextBadge.frame.SetPoint("TOPLEFT", nextCard.frame, "TOPLEFT", 12, -12);
    const nextBang = Native.createText(nextBadge.frame, "!", "GameFontNormal", theme.colors.warning);
    nextBang.SetPoint("CENTER", nextBadge.frame, "CENTER", 0, 0);
    nextBang.SetJustifyH("CENTER");
    const warningsTitle = Native.createText(nextCard.frame, "NEXT STEP", "GameFontNormalSmall", theme.colors.warning);
    warningsTitle.SetPoint("LEFT", nextBadge.frame, "RIGHT", 9, 0);
    const warningRows: WoWFontString[] = [];
    for (let i = 0; i < 3; i += 1) {
        const row = Native.createText(nextCard.frame, "", "GameFontHighlightSmall", i === 0 ? theme.colors.warning : theme.colors.muted);
        row.SetPoint("TOPLEFT", nextCard.frame, "TOPLEFT", 12, -(50 + i * 24));
        row.SetWidth(246);
        row.SetJustifyV("TOP");
        warningRows.push(row);
    }

    const buildButton = ButtonUI.createButton(status.frame, {
        text: "Build & Prepare", width: 270, height: 46, accent: theme.colors.primary, emphasis: true,
        onClick: () => Model.buildAndPrepare(),
    });
    buildButton.frame.SetPoint("BOTTOMLEFT", status.frame, "BOTTOMLEFT", 16, 66);

    let showAssembleConfirm = () => {};
    const assembleButton = ButtonUI.createButton(status.frame, { text: "Assemble", width: 194, height: 42, accent: theme.colors.success, onClick: () => showAssembleConfirm() });
    assembleButton.frame.SetPoint("BOTTOMLEFT", status.frame, "BOTTOMLEFT", 16, 18);
    const resetButton = ButtonUI.createButton(status.frame, { text: "Reset", width: 68, height: 42, accent: theme.colors.error, onClick: () => Model.clearPlan() });
    resetButton.frame.SetPoint("LEFT", assembleButton.frame, "RIGHT", 8, 0);

    // Templates modal --------------------------------------------------------
    const templatesModal = ModalUI.createModal(frame, 1020, 720);
    templatesModal.setTitle("Raid Templates");
    templatesModal.setSubtitle("Coverage-first raid cores reserve key buffs; every unlisted slot stays Auto-filled.");
    templatesModal.setHeaderIcon(ICON_TEMPLATES);

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
            if (Model.config().mode !== "RAID") {
                Model.fireStatus("Templates are raid-only. Configure dungeon bot slots directly.");
                return;
            }
            const name = templateName.getText();
            if (name !== "") {
                Model.saveProfile(name);
                templateName.clear();
                refreshTemplates();
            }
        },
    });
    templateSave.frame.SetPoint("LEFT", templateName.frame, "RIGHT", 8, 0);

    const builtinTitle = Native.createText(templatesModal.content, "BUILT-IN RAID COMPS", "GameFontNormalSmall", theme.colors.muted);
    builtinTitle.SetPoint("TOPLEFT", templatesModal.content, "TOPLEFT", 0, -82);
    const customTitle = Native.createText(templatesModal.content, "MY TEMPLATES", "GameFontNormalSmall", theme.colors.muted);
    customTitle.SetPoint("TOPLEFT", templatesModal.content, "TOPLEFT", 472, -82);

    const builtinScroll = ScrollUI.createScrollList(templatesModal.content, 448, 460);
    builtinScroll.frame.SetPoint("TOPLEFT", templatesModal.content, "TOPLEFT", 0, -110);
    const customScroll = ScrollUI.createScrollList(templatesModal.content, 448, 460);
    customScroll.frame.SetPoint("TOPLEFT", templatesModal.content, "TOPLEFT", 472, -110);

    const builtinRows: WoWFrame[] = [];
    const customRows: WoWFrame[] = [];

    function clearDynamicRows(rows: WoWFrame[]): void {
        for (const row of rows) row.Hide();
    }

    function refreshTemplates(): void {
        clearDynamicRows(builtinRows);
        clearDynamicRows(customRows);
        templateSave.setEnabled(Model.config().mode === "RAID");

        const builtins = Model.listBuiltinProfiles();
        for (let i = 0; i < builtins.length; i += 1) {
            let row = builtinRows[i];
            if (row === undefined) {
                const panel = Native.createPanel(builtinScroll.content, theme.colors.surfaceRaised, theme.colors.border);
                panel.frame.SetSize(438, 76);
                const accent = Native.createSolid(panel.frame, theme.colors.primary, "ARTWORK");
                accent.SetWidth(3);
                accent.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 0, 0);
                accent.SetPoint("BOTTOMLEFT", panel.frame, "BOTTOMLEFT", 0, 0);
                const name = Native.createText(panel.frame, "", "GameFontHighlight");
                name.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 10, -10);
                name.SetWidth(310);
                const info = Native.createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted);
                info.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 10, -38);
                info.SetWidth(318);
                const load = ButtonUI.createButton(panel.frame, { text: "Load", width: 82, height: 32, accent: theme.colors.primary });
                load.frame.SetPoint("RIGHT", panel.frame, "RIGHT", -8, 0);
                (panel.frame as any)._name = name;
                (panel.frame as any)._info = info;
                (panel.frame as any)._load = load;
                builtinScroll.bindWheel(panel.frame);
                builtinScroll.bindWheel(load.frame);
                row = panel.frame;
                builtinRows[i] = row;
            }
            row.ClearAllPoints();
            row.SetPoint("TOPLEFT", builtinScroll.content, "TOPLEFT", 0, -(i * 84));
            (row as any)._name.SetText(builtins[i]);
            (row as any)._info.SetText(Model.profileDescription(builtins[i]));
            const profileName = builtins[i];
            (row as any)._load.frame.SetScript("OnMouseDown", () => {
                Model.loadProfile(profileName);
                templatesModal.hide();
            });
            row.Show();
        }
        builtinScroll.setContentHeight(Math.max(460, builtins.length * 84));

        const customs = Model.listCustomProfiles();
        for (let i = 0; i < customs.length; i += 1) {
            let row = customRows[i];
            if (row === undefined) {
                const panel = Native.createPanel(customScroll.content, theme.colors.surfaceRaised, theme.colors.border);
                panel.frame.SetSize(438, 76);
                const accent = Native.createSolid(panel.frame, theme.colors.warning, "ARTWORK");
                accent.SetWidth(3);
                accent.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 0, 0);
                accent.SetPoint("BOTTOMLEFT", panel.frame, "BOTTOMLEFT", 0, 0);
                const name = Native.createText(panel.frame, "", "GameFontHighlight");
                name.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 10, -10);
                name.SetWidth(250);
                const info = Native.createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted);
                info.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 10, -34);
                info.SetWidth(270);
                const load = ButtonUI.createButton(panel.frame, { text: "Load", width: 68, height: 30, accent: theme.colors.primary });
                load.frame.SetPoint("RIGHT", panel.frame, "RIGHT", -78, 0);
                const remove = ButtonUI.createButton(panel.frame, { text: "Delete", width: 66, height: 30, accent: theme.colors.error });
                remove.frame.SetPoint("RIGHT", panel.frame, "RIGHT", -8, 0);
                (panel.frame as any)._name = name;
                (panel.frame as any)._info = info;
                (panel.frame as any)._load = load;
                (panel.frame as any)._remove = remove;
                customScroll.bindWheel(panel.frame);
                customScroll.bindWheel(load.frame);
                customScroll.bindWheel(remove.frame);
                row = panel.frame;
                customRows[i] = row;
            }
            row.ClearAllPoints();
            row.SetPoint("TOPLEFT", customScroll.content, "TOPLEFT", 0, -(i * 84));
            (row as any)._name.SetText(customs[i]);
            (row as any)._info.SetText(Model.profileDescription(customs[i]));
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
        customScroll.setContentHeight(Math.max(460, customs.length * 84));
    }

    showTemplates = () => {
        ChoiceUI.closeChoicePopup();
        builtinScroll.scrollToTop();
        customScroll.scrollToTop();
        refreshTemplates();
        templatesModal.show();
    };

    // Humans & Pins modal ----------------------------------------------------
    const peopleModal = ModalUI.createModal(frame, 980, 700);
    peopleModal.setTitle("Humans & Pins");
    peopleModal.setSubtitle("Real players stay locked. Pins request named companions without turning humans into disposable roster slots.");
    peopleModal.setHeaderIcon(ICON_PEOPLE);

    const peopleHumanTitle = Native.createText(peopleModal.content, "HUMAN ANCHORS", "GameFontNormalSmall", theme.colors.muted);
    peopleHumanTitle.SetPoint("TOPLEFT", peopleModal.content, "TOPLEFT", 0, 0);
    const humanScroll = ScrollUI.createScrollList(peopleModal.content, 900, 210);
    humanScroll.frame.SetPoint("TOPLEFT", peopleModal.content, "TOPLEFT", 0, -26);
    const humanRowsModal: WoWFrame[] = [];

    const pinBuilder = Native.createPanel(peopleModal.content, theme.colors.surfaceRaised, theme.colors.border);
    pinBuilder.frame.SetPoint("TOPLEFT", peopleModal.content, "TOPLEFT", 0, -242);
    pinBuilder.frame.SetPoint("TOPRIGHT", peopleModal.content, "TOPRIGHT", 0, -242);
    pinBuilder.frame.SetHeight(82);

    const pinTitle = Native.createText(peopleModal.content, "PIN COMPANION", "GameFontNormalSmall", theme.colors.muted);
    pinTitle.SetPoint("TOPLEFT", peopleModal.content, "TOPLEFT", 12, -250);
    const pinInput = InputUI.createTextInput(peopleModal.content, 230, 34);
    pinInput.frame.SetPoint("TOPLEFT", peopleModal.content, "TOPLEFT", 12, -278);

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
    addPinButton.frame.SetPoint("TOPRIGHT", peopleModal.content, "TOPRIGHT", -12, -278);

    const pinListTitle = Native.createText(peopleModal.content, "PINNED MEMBERS", "GameFontNormalSmall", theme.colors.muted);
    pinListTitle.SetPoint("TOPLEFT", peopleModal.content, "TOPLEFT", 0, -338);
    const pinScroll = ScrollUI.createScrollList(peopleModal.content, 900, 190);
    pinScroll.frame.SetPoint("TOPLEFT", peopleModal.content, "TOPLEFT", 0, -364);
    const pinRows: WoWFrame[] = [];

    function refreshPeople(): void {
        clearDynamicRows(humanRowsModal);
        const list = Model.humans();

        for (let i = 0; i < list.length; i += 1) {
            const human = list[i];
            let row = humanRowsModal[i];
            if (row === undefined) {
                const panel = Native.createPanel(humanScroll.content, theme.colors.surfaceRaised, theme.colors.border);
                panel.frame.SetSize(892, 46);
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
                humanScroll.bindWheel(panel.frame);
                for (const wheelRole of roleOrder) humanScroll.bindWheel(buttons[wheelRole].frame);
                row = panel.frame;
                humanRowsModal[i] = row;
            }

            row.ClearAllPoints();
            row.SetPoint("TOPLEFT", humanScroll.content, "TOPLEFT", 0, -(i * 52));
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
        humanScroll.setContentHeight(Math.max(210, list.length * 52));

        for (const role of roleOrder) pinRoleButtons[role].setSelected(pinRole === role);
        pinToggle.refresh();

        clearDynamicRows(pinRows);
        const pins = Model.pinnedMembers();
        for (let i = 0; i < pins.length; i += 1) {
            const pin = pins[i];
            let row = pinRows[i];
            if (row === undefined) {
                const panel = Native.createPanel(pinScroll.content, theme.colors.surfaceRaised, theme.colors.border);
                panel.frame.SetSize(892, 44);
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
                pinScroll.bindWheel(panel.frame);
                pinScroll.bindWheel(remove.frame);
                row = panel.frame;
                pinRows[i] = row;
            }
            row.ClearAllPoints();
            row.SetPoint("TOPLEFT", pinScroll.content, "TOPLEFT", 0, -(i * 50));
            (row as any)._name.SetText(String(pin.name));
            (row as any)._info.SetText(Model.roleLabel(pin.role as Role) + "  ·  " + (pin.required ? "Required" : "Preferred"));
            const indexCopy = i + 1;
            (row as any)._remove.frame.SetScript("OnMouseDown", () => {
                Model.removePin(indexCopy);
                refreshPeople();
            });
            row.Show();
        }
        pinScroll.setContentHeight(Math.max(190, pins.length * 50));
    }

    showPeople = () => {
        ChoiceUI.closeChoicePopup();
        refreshPeople();
        peopleModal.show();
    };

    // Options modal ----------------------------------------------------------
    const optionsModal = ModalUI.createModal(frame, 900, 650);
    optionsModal.setHeaderIcon(ICON_OPTIONS);
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
        const column = i % 2;
        const rowIndex = Math.floor(i / 2);
        const row = Native.createPanel(optionsModal.content, theme.colors.surfaceRaised, theme.colors.border);
        row.frame.SetPoint("TOPLEFT", optionsModal.content, "TOPLEFT", column * 430, -(rowIndex * 84));
        row.frame.SetSize(414, 72);

        const toggle = ToggleUI.createToggle(
            row.frame,
            def.label,
            () => Model.config().options?.[def.key] === true,
            (value) => {
                Model.config().options[def.key] = value;
                Model.touch("Composition option changed");
            },
        );
        toggle.frame.SetPoint("TOPLEFT", row.frame, "TOPLEFT", 12, -8);
        toggle.frame.SetWidth(360);

        const hint = Native.createText(row.frame, def.hint, "GameFontHighlightSmall", theme.colors.muted);
        hint.SetPoint("TOPLEFT", row.frame, "TOPLEFT", 42, -37);
        hint.SetWidth(350);
        hint.SetJustifyV("TOP");
        optionToggles.push(toggle);
    }

    const gearRow = Native.createPanel(optionsModal.content, theme.colors.surfaceRaised, theme.colors.borderStrong);
    gearRow.frame.SetPoint("TOPLEFT", optionsModal.content, "TOPLEFT", 0, -348);
    gearRow.frame.SetPoint("TOPRIGHT", optionsModal.content, "TOPRIGHT", 0, -348);
    gearRow.frame.SetHeight(72);

    const gearTitle = Native.createText(gearRow.frame, "Minimum item level", "GameFontNormal");
    gearTitle.SetPoint("TOPLEFT", gearRow.frame, "TOPLEFT", 14, -12);
    const gearHint = Native.createText(gearRow.frame, "0 disables the floor. Guild/world bots below the configured value are rejected.", "GameFontHighlightSmall", theme.colors.muted);
    gearHint.SetPoint("TOPLEFT", gearRow.frame, "TOPLEFT", 14, -39);
    gearHint.SetWidth(620);

    const gearStepper = StepperUI.createNumberStepper(
        gearRow.frame,
        0,
        300,
        Number(Model.config().options?.minimumItemLevel ?? 0),
        (value) => Model.setMinimumItemLevel(value),
    );
    gearStepper.frame.SetPoint("RIGHT", gearRow.frame, "RIGHT", -14, 0);

    showOptions = () => {
        ChoiceUI.closeChoicePopup();
        for (const toggle of optionToggles) toggle.refresh();
        gearStepper.setValue(Number(Model.config().options?.minimumItemLevel ?? 0), false);
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
        activityEligibility.SetText("ELIGIBILITY  ·  " + Model.activityEligibilityText());
        activityBadge.icon.SetTexture(Model.config().mode === "RAID" ? ICON_RAID : ICON_DUNGEON);
        activityBadge.icon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
        activityFieldLabel.SetText(Model.config().mode === "RAID" ? "RAID" : "DUNGEON");
        activitySelect.refresh();
        difficultySelect.refresh();

        const sizes = Model.supportedRaidSizes();
        let sizeIndex = 0;
        if (cfg.mode === "RAID") raidSizeLabel.Show();
        else raidSizeLabel.Hide();

        for (const size of [10, 20, 25, 40]) {
            const button = raidSizeButtons[size];
            let supported = false;
            for (const allowed of sizes) if (allowed === size) { supported = true; break; }

            if (cfg.mode === "RAID" && supported) {
                button.frame.ClearAllPoints();
                button.frame.SetPoint("TOPLEFT", activity.frame, "TOPLEFT", 680 + sizeIndex * 58, -92);
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
                widgets.sub.SetText(
                    "Lv " + String(prepared.level ?? "?") + "  ·  " +
                    String(prepared.spec || Model.classLabel(String(prepared.class))) + "  ·  " + String(prepared.source ?? "Bot")
                );
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
        const size = Number(Model.config().size ?? 25);
        const total = Model.roleTargetTotal();
        for (const role of roleOrder) {
            const target = Model.targetForRole(role);
            quickCards[role].count.SetText(String(target));
            quickCards[role].botSlots.SetText(String(Model.remainingBotSlots(role)) + " bot slots after humans");
            quickCards[role].minus.setEnabled(target > 0);
            quickCards[role].plus.setEnabled(target < size);
        }

        quickTotal.SetText(String(total) + " / " + String(size));
        const valid = total === size;
        const color = valid ? theme.colors.success : theme.colors.warning;
        quickTotal.SetTextColor(color[0], color[1], color[2], 1);
        quickSummary.outline.setColor(valid ? theme.colors.border : theme.colors.warning);
    }

    function refreshExactRaid(): void {
        let cursor = 0;

        for (const role of roleOrder) {
            const section = exactSections[role];
            const rows = Model.requiredBuilds(role);
            const reserved = Model.exactCount(role);
            const auto = Math.max(0, Model.remainingBotSlots(role) - reserved);

            section.count.SetText(String(reserved) + " reserved · " + String(auto) + " Auto");
            section.add.setEnabled(reserved < Model.remainingBotSlots(role));

            const roleCopy = role;
            section.add.frame.SetScript("OnMouseDown", () => {
                if (Model.exactCount(roleCopy) >= Model.remainingBotSlots(roleCopy)) return;
                selectorContext = { mode: "RAID_ADD", role: roleCopy, index: -1 };
                buildSelector.open(roleCopy, { role: roleCopy, count: 1 }, true);
            });

            for (const old of section.rows) old.panel.frame.Hide();

            const sectionHeight = rows.length === 0 ? 106 : 70 + rows.length * 60;
            section.panel.frame.ClearAllPoints();
            section.panel.frame.SetPoint("TOPLEFT", exactScroll.content, "TOPLEFT", 0, -cursor);
            section.panel.frame.SetSize(906, sectionHeight);

            if (rows.length === 0) section.empty.Show();
            else section.empty.Hide();

            for (let i = 0; i < rows.length; i += 1) {
                const build = rows[i];
                let widgets = section.rows[i];
                if (widgets === undefined) {
                    const panel = Native.createPanel(section.panel.frame, theme.colors.surfaceRaised, theme.colors.border);
                    panel.frame.SetSize(870, 52);

                    const classBadge = Native.createFramedIcon(panel.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 38, theme.colors.borderStrong);
                    classBadge.frame.SetPoint("LEFT", panel.frame, "LEFT", 10, 0);
                    const classIcon = classBadge.icon;

                    const specBadge = Native.createFramedIcon(panel.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 38, theme.colors.borderStrong);
                    specBadge.frame.SetPoint("LEFT", classBadge.frame, "RIGHT", 6, 0);
                    const specIcon = specBadge.icon;

                    const name = Native.createText(panel.frame, "", "GameFontNormal");
                    name.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 104, -10);
                    name.SetWidth(500);

                    const count = Native.createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted);
                    count.SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4);

                    const edit = ButtonUI.createButton(panel.frame, { text: "Edit", width: 74, height: 30, accent: theme.colors.primary });
                    edit.frame.SetPoint("RIGHT", panel.frame, "RIGHT", -54, 0);

                    const remove = ButtonUI.createButton(panel.frame, { text: "X", width: 40, height: 30, accent: theme.colors.error });
                    remove.frame.SetPoint("RIGHT", panel.frame, "RIGHT", -8, 0);

                    exactScroll.bindWheel(panel.frame);
                    exactScroll.bindWheel(edit.frame);
                    exactScroll.bindWheel(remove.frame);
                    widgets = { panel, classIcon, specIcon, name, count, edit, remove };
                    section.rows[i] = widgets;
                }

                widgets.panel.frame.ClearAllPoints();
                widgets.panel.frame.SetPoint("TOPLEFT", section.panel.frame, "TOPLEFT", 18, -(62 + i * 60));
                Native.setClassIcon(widgets.classIcon, build.classId);
                widgets.specIcon.SetTexture(Model.getSpecIcon(build.classId, build.specId));
                widgets.specIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
                widgets.name.SetText(Model.getSpecLabel(build.classId, build.specId) + " " + Model.classLabel(build.classId));
                widgets.count.SetText("Reserved ×" + String(build.count) + " · remaining role slots stay Auto");

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

            cursor += sectionHeight + 12;
        }

        exactScroll.setContentHeight(Math.max(386, cursor));
    }

    function refreshRoster(): void {
        const cfg = Model.config();
        const totalGroups = Math.max(1, Math.ceil(Number(cfg.size ?? 5) / 5));
        const columns = totalGroups <= 3 ? totalGroups : (totalGroups <= 5 ? 3 : 4);
        const cardWidth = Math.floor((934 - (columns - 1) * 10) / columns);
        const cardHeight = 190;

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
                    rowWidgets.spec.SetText("Lv " + String(member.level ?? "?") + " · " + String(member.spec ?? Model.classLabel(String(member.class))));
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
                ? Model.coverageDisplay()
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
            let text: string | undefined;
            if (i === 0 && phase === "ERROR") {
                text = "Adjust the highlighted requirement, then Build & Prepare again.";
            } else if (phase === "ERROR") {
                text = warnings[i - 1];
            } else {
                text = warnings[i];
            }

            if (text === undefined && i === 0) {
                if (phase === "READY") text = Model.isTravelRetry() ? "Clear the travel blocker, then enter the activity." : "Prepared roster is ready for review. Assemble when it looks right.";
                else if (phase === "PREPARING") text = "Composer is provisioning and validating the selected bots.";
                else if (!Model.humanReady()) text = "Choose a legal role for every real player.";
                else if (Model.config().mode === "RAID" && Model.roleTargetTotal() !== Number(Model.config().size ?? 25)) {
                    text = "Role counts must total " + String(Model.config().size ?? 25) + " before preparing.";
                } else text = "Build & Prepare when the composition looks right.";
            }
            warningRows[i].SetText(String(text ?? ""));
        }

        buildButton.setEnabled(Model.humanReady() && !Model.isBusy() && (Model.config().mode !== "RAID" || Model.roleTargetTotal() === Number(Model.config().size ?? 25)));
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
        const available = Math.min((width - 24) / 1520, (height - 24) / 900);
        const maxScale = width >= 3000 ? 1.22 : (width >= 2400 ? 1.16 : 1.10);
        frame.SetScale(Math.max(0.66, Math.min(maxScale, available)));
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

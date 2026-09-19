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

function roleDescription(role: Role): string {
    if (role === "TANK") return "Durable heroes who hold threat and keep danger away from the raid.";
    if (role === "HEALER") return "Keep the raid alive with healing, dispels and support.";
    return "Deal damage while Composer preserves the raid's class and utility needs.";
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
    // Capture the frame instead of consuming callback args. This avoids TypeScriptToLua's
    // implicit-self calling convention and matches WoW 3.3.5's SetScript ABI exactly.
    frame.SetScript("OnDragStart", () => frame.StartMoving());
    frame.SetScript("OnDragStop", () => frame.StopMovingOrSizing());
    frame.Hide();

    const root = Native.createSolid(frame, theme.colors.background);
    root.SetAllPoints(frame);
    Native.createChrome(frame, theme.colors.chrome, true);

    const header = Native.createPanel(frame, theme.colors.surface, theme.colors.border);
    header.frame.SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1);
    header.frame.SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1);
    header.frame.SetHeight(72);
    const headerAccent = Native.createSolid(header.frame, theme.colors.primary, "OVERLAY");
    headerAccent.SetPoint("TOPLEFT", header.frame, "TOPLEFT", 0, 0);
    headerAccent.SetPoint("TOPRIGHT", header.frame, "TOPRIGHT", 0, 0);
    headerAccent.SetHeight(2);

    const mark = Native.createPanel(header.frame, theme.colors.surfaceBlue, theme.colors.primary);
    mark.frame.SetSize(48, 48);
    mark.frame.SetPoint("LEFT", header.frame, "LEFT", 18, 0);
    const markText = Native.createText(mark.frame, "GC", "GameFontNormalLarge", theme.colors.primary);
    markText.SetPoint("CENTER", mark.frame, "CENTER", 0, 0);
    markText.SetJustifyH("CENTER");

    const title = Native.createText(header.frame, "GROUP COMPOSER", "GameFontNormalLarge");
    title.SetPoint("TOPLEFT", header.frame, "TOPLEFT", 82, -14);
    const subtitle = Native.createText(header.frame, "Build the team you want, then let Composer prepare it.", "GameFontHighlightSmall", theme.colors.muted);
    subtitle.SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4);

    const backendGlow = Native.createSolid(header.frame, Native.withAlpha(theme.colors.success, 0.18), "ARTWORK");
    backendGlow.SetSize(18, 18);
    backendGlow.SetPoint("RIGHT", header.frame, "RIGHT", -233, 0);
    backendGlow.Hide();
    const backendDot = Native.createSolid(header.frame, theme.colors.muted, "OVERLAY");
    backendDot.SetSize(8, 8);
    backendDot.SetPoint("RIGHT", header.frame, "RIGHT", -238, 0);
    const backendText = Native.createText(header.frame, "Checking backend", "GameFontHighlightSmall", theme.colors.muted);
    backendText.SetPoint("LEFT", backendDot, "RIGHT", 8, 0);

    const close = ButtonUI.createButton(header.frame, {
        text: "Close   X", width: 108, height: 34, accent: theme.colors.error, emphasis: true,
        onClick: () => frame.Hide(),
    });
    close.frame.SetPoint("RIGHT", header.frame, "RIGHT", -16, 0);

    const sidebar = Native.createPanel(frame, theme.colors.surface, theme.colors.border);
    sidebar.frame.SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -73);
    sidebar.frame.SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 16);
    sidebar.frame.SetWidth(184);

    const navTitle = Native.createText(sidebar.frame, "COMPOSE", "GameFontNormalSmall", theme.colors.muted);
    navTitle.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 14, -20);

    const navDungeon = ButtonUI.createButton(sidebar.frame, {
        text: "Dungeon", width: 152, height: 46, accent: theme.colors.primary, icon: ICON_DUNGEON, iconSize: 24, flat: true,
        onClick: () => Model.setMode("DUNGEON"),
    });
    navDungeon.frame.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 14, -48);
    navDungeon.label.SetJustifyH("LEFT");
    const navRaid = ButtonUI.createButton(sidebar.frame, {
        text: "Raid", width: 152, height: 46, accent: theme.colors.warning, icon: ICON_RAID, iconSize: 24, flat: true,
        onClick: () => Model.setMode("RAID"),
    });
    navRaid.frame.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 14, -102);
    navRaid.label.SetJustifyH("LEFT");

    const sidebarDivider = Native.createSolid(sidebar.frame, theme.colors.borderStrong, "ARTWORK");
    sidebarDivider.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 14, -160);
    sidebarDivider.SetPoint("TOPRIGHT", sidebar.frame, "TOPRIGHT", -14, -160);
    sidebarDivider.SetHeight(1);

    const manageTitle = Native.createText(sidebar.frame, "TOOLS", "GameFontNormalSmall", theme.colors.muted);
    manageTitle.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 14, -174);

    let showTemplates = () => {};
    let showPeople = () => {};
    let showOptions = () => {};

    const navTemplates = ButtonUI.createButton(sidebar.frame, { text: "Templates", width: 152, height: 42, icon: ICON_TEMPLATES, iconSize: 22, flat: true, onClick: () => showTemplates() });
    navTemplates.frame.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 14, -198);
    navTemplates.label.SetJustifyH("LEFT");
    const navPeople = ButtonUI.createButton(sidebar.frame, { text: "Humans & Pins", width: 152, height: 42, icon: ICON_PEOPLE, iconSize: 22, flat: true, onClick: () => showPeople() });
    navPeople.frame.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 14, -248);
    navPeople.label.SetJustifyH("LEFT");
    const navOptions = ButtonUI.createButton(sidebar.frame, { text: "Options", width: 152, height: 42, icon: ICON_OPTIONS, iconSize: 22, flat: true, onClick: () => showOptions() });
    navOptions.frame.SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", 14, -298);
    navOptions.label.SetJustifyH("LEFT");

    const sideHint = Native.createText(sidebar.frame, "Humans stay locked.\nSpecific builds reserve bot slots; everything else stays Auto.", "GameFontHighlightSmall", theme.colors.muted);
    sideHint.SetPoint("BOTTOMLEFT", sidebar.frame, "BOTTOMLEFT", 16, 42);
    sideHint.SetWidth(152);
    sideHint.SetJustifyV("TOP");
    const versionText = Native.createText(sidebar.frame, "v" + String(D.VERSION ?? "0.10.0"), "GameFontHighlightSmall", theme.colors.muted);
    versionText.SetPoint("BOTTOMLEFT", sidebar.frame, "BOTTOMLEFT", 16, 12);

    const center = CreateFrame("Frame", undefined, frame);
    center.SetPoint("TOPLEFT", frame, "TOPLEFT", 200, -88);
    center.SetSize(970, 800);

    const status = Native.createPanel(frame, theme.colors.surface, theme.colors.borderStrong);
    status.frame.SetPoint("TOPLEFT", frame, "TOPLEFT", 1186, -88);
    status.frame.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 16);

    let statusNotice = "";

    // Activity ---------------------------------------------------------------
    const activity = Native.createPanel(center, theme.colors.surface, theme.colors.borderStrong);
    activity.frame.SetPoint("TOPLEFT", center, "TOPLEFT", 0, 0);
    activity.frame.SetPoint("TOPRIGHT", center, "TOPRIGHT", 0, 0);
    activity.frame.SetHeight(124);
    const activityTop = Native.createSolid(activity.frame, Native.withAlpha(theme.colors.primary, 0.65), "ARTWORK");
    activityTop.SetPoint("TOPLEFT", activity.frame, "TOPLEFT", 0, 0);
    activityTop.SetPoint("TOPRIGHT", activity.frame, "TOPRIGHT", 0, 0);
    activityTop.SetHeight(2);

    const activityEyebrow = Native.createText(activity.frame, "ACTIVITY", "GameFontNormalSmall", theme.colors.muted);
    activityEyebrow.SetPoint("TOPLEFT", activity.frame, "TOPLEFT", 16, -12);

    const activityBadge = Native.createFramedIcon(activity.frame, ICON_DUNGEON, 64, theme.colors.borderStrong);
    activityBadge.frame.SetPoint("TOPLEFT", activity.frame, "TOPLEFT", 16, -38);

    const activityName = Native.createText(activity.frame, "Dungeon", "GameFontNormalLarge");
    activityName.SetPoint("TOPLEFT", activity.frame, "TOPLEFT", 96, -38);
    activityName.SetWidth(218);
    const activitySub = Native.createText(activity.frame, "", "GameFontHighlightSmall", theme.colors.muted);
    activitySub.SetPoint("TOPLEFT", activityName, "BOTTOMLEFT", 0, -5);
    activitySub.SetWidth(218);
    const activityEligibility = Native.createText(activity.frame, "", "GameFontHighlightSmall", theme.colors.success);
    activityEligibility.SetPoint("TOPLEFT", activitySub, "BOTTOMLEFT", 0, -7);
    activityEligibility.SetWidth(218);

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
    humanPanel.frame.SetPoint("TOPLEFT", center, "TOPLEFT", 0, -136);
    humanPanel.frame.SetPoint("TOPRIGHT", center, "TOPRIGHT", 0, -136);
    humanPanel.frame.SetHeight(78);
    const humanTop = Native.createSolid(humanPanel.frame, Native.withAlpha(theme.colors.primary, 0.40), "ARTWORK");
    humanTop.SetPoint("TOPLEFT", humanPanel.frame, "TOPLEFT", 0, 0);
    humanTop.SetPoint("TOPRIGHT", humanPanel.frame, "TOPRIGHT", 0, 0);
    humanTop.SetHeight(2);

    const humanTitle = Native.createText(humanPanel.frame, "YOUR PARTY", "GameFontNormalSmall", theme.colors.muted);
    humanTitle.SetPoint("TOPLEFT", humanPanel.frame, "TOPLEFT", 16, -12);

    const humanBadge = Native.createFramedIcon(humanPanel.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 42, theme.colors.borderStrong);
    humanBadge.frame.SetPoint("BOTTOMLEFT", humanPanel.frame, "BOTTOMLEFT", 14, 8);
    const humanIcon = humanBadge.icon;
    Native.setClassIcon(humanIcon, "WARRIOR");

    const humanName = Native.createText(humanPanel.frame, "Choose your role", "GameFontNormal");
    humanName.SetPoint("TOPLEFT", humanBadge.frame, "TOPRIGHT", 10, -1);
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
        const icon = button.frame.CreateTexture(undefined, "ARTWORK");
        icon.SetSize(18, 18);
        icon.SetPoint("LEFT", button.frame, "LEFT", 10, 0);
        Native.setRoleIcon(icon, role);
        button.label.ClearAllPoints();
        button.label.SetPoint("LEFT", button.frame, "LEFT", 34, 0);
        button.label.SetJustifyH("LEFT");
    }


    // Composition shell ------------------------------------------------------
    const composition = Native.createPanel(center, theme.colors.surface, theme.colors.border);
    composition.frame.SetPoint("TOPLEFT", center, "TOPLEFT", 0, -226);
    composition.frame.SetPoint("BOTTOMRIGHT", center, "BOTTOMRIGHT", 0, 0);
    const compositionTop = Native.createSolid(composition.frame, Native.withAlpha(theme.colors.primary, 0.34), "ARTWORK");
    compositionTop.SetPoint("TOPLEFT", composition.frame, "TOPLEFT", 0, 0);
    compositionTop.SetPoint("TOPRIGHT", composition.frame, "TOPRIGHT", 0, 0);
    compositionTop.SetHeight(2);

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
        row.frame.SetHeight(64);
        row.frame.SetPoint("TOPLEFT", dungeonView, "TOPLEFT", 0, -(i * 70));
        row.frame.SetPoint("RIGHT", dungeonView, "RIGHT", 0, 0);

        const accent = Native.createSolid(row.frame, theme.colors.dps, "ARTWORK");
        accent.SetWidth(3);
        accent.SetPoint("TOPLEFT", row.frame, "TOPLEFT", 0, 0);
        accent.SetPoint("BOTTOMLEFT", row.frame, "BOTTOMLEFT", 0, 0);

        const roleBadge = Native.createFramedRoleIcon(row.frame, "DPS", 38, theme.colors.borderStrong);
        roleBadge.frame.SetPoint("LEFT", row.frame, "LEFT", 12, 0);
        const roleIcon = roleBadge.icon;

        const roleText = Native.createText(row.frame, "DPS", "GameFontNormal");
        roleText.SetPoint("LEFT", roleBadge.frame, "RIGHT", 10, 7);
        const slotText = Native.createText(row.frame, "Slot", "GameFontHighlightSmall", theme.colors.muted);
        slotText.SetPoint("LEFT", roleBadge.frame, "RIGHT", 10, -9);

        const classBadge = Native.createFramedIcon(row.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 38, theme.colors.borderStrong);
        classBadge.frame.SetPoint("LEFT", row.frame, "LEFT", 158, 0);
        classBadge.frame.Hide();
        const classIcon = classBadge.icon;

        const specBadge = Native.createFramedIcon(row.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 34, theme.colors.borderStrong);
        specBadge.frame.SetPoint("LEFT", classBadge.frame, "RIGHT", 7, 0);
        specBadge.frame.Hide();
        const specIcon = specBadge.icon;

        const name = Native.createText(row.frame, "Auto-fill bot", "GameFontNormal");
        name.SetPoint("TOPLEFT", row.frame, "TOPLEFT", 244, -12);
        name.SetWidth(430);
        const sub = Native.createText(row.frame, "Composer chooses a suitable build", "GameFontHighlightSmall", theme.colors.muted);
        sub.SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4);
        sub.SetWidth(430);

        const choose = ButtonUI.createButton(row.frame, { text: "Choose build", width: 126, height: 34, accent: theme.colors.primary });
        choose.frame.SetPoint("RIGHT", row.frame, "RIGHT", -12, 0);
        const auto = ButtonUI.createButton(row.frame, { text: "Use Auto", width: 78, height: 34 });
        auto.frame.SetPoint("RIGHT", choose.frame, "LEFT", -8, 0);
        auto.frame.Hide();

        const humanAnchor = ButtonUI.createButton(row.frame, {
            text: "Human anchor",
            width: 126,
            height: 34,
            accent: theme.colors.borderStrong,
        });
        humanAnchor.frame.SetPoint("RIGHT", row.frame, "RIGHT", -12, 0);
        humanAnchor.setEnabled(false);
        humanAnchor.frame.Hide();

        dungeonRows.push({
            row, accent, roleIcon, roleText, slotText, classBadge, classIcon, specBadge, specIcon,
            name, sub, choose, auto, humanAnchor,
        });
    }

    // Raid views -------------------------------------------------------------
    const raidView = CreateFrame("Frame", undefined, composition.frame);
    raidView.SetPoint("TOPLEFT", composition.frame, "TOPLEFT", 16, -56);
    raidView.SetPoint("BOTTOMRIGHT", composition.frame, "BOTTOMRIGHT", -16, 16);
    raidView.Hide();

    let raidTab: RaidTab = "QUICK";
    const tabQuick = ButtonUI.createButton(raidView, { text: "Quick Composition", width: 164, height: 38, accent: theme.colors.warning });
    tabQuick.frame.SetPoint("TOPLEFT", raidView, "TOPLEFT", 0, 0);
    const tabExact = ButtonUI.createButton(raidView, { text: "Specific Builds", width: 150, height: 38, accent: theme.colors.warning });
    tabExact.frame.SetPoint("LEFT", tabQuick.frame, "RIGHT", 8, 0);
    const tabRoster = ButtonUI.createButton(raidView, { text: "Prepared Roster", width: 150, height: 38, accent: theme.colors.success });
    tabRoster.frame.SetPoint("LEFT", tabExact.frame, "RIGHT", 8, 0);
    const resetRoles = ButtonUI.createButton(raidView, {
        text: "Reset roles",
        width: 100,
        height: 34,
        onClick: () => Model.resetRoleTargets(),
    });
    resetRoles.frame.SetPoint("TOPRIGHT", raidView, "TOPRIGHT", 0, 0);

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
        const accent = Model.roleAccent(role);
        const card = Native.createPanel(quickView, theme.colors.surfaceDeep, theme.colors.border);
        card.frame.SetSize(300, 214);
        card.frame.SetPoint("TOPLEFT", quickView, "TOPLEFT", i * 312, -10);

        const roleStrip = Native.createSolid(card.frame, accent, "ARTWORK");
        roleStrip.SetHeight(3);
        roleStrip.SetPoint("TOPLEFT", card.frame, "TOPLEFT", 0, 0);
        roleStrip.SetPoint("TOPRIGHT", card.frame, "TOPRIGHT", 0, 0);
        const roleTint = Native.createSolid(card.frame, Native.withAlpha(accent, 0.045), "BACKGROUND");
        roleTint.SetAllPoints(card.frame);

        const roleBadge = Native.createFramedRoleIcon(card.frame, role, 48, accent);
        roleBadge.frame.SetPoint("TOPLEFT", card.frame, "TOPLEFT", 18, -18);
        const label = Native.createText(card.frame, Model.roleLabel(role).toUpperCase(), "GameFontNormalLarge", accent);
        label.SetPoint("TOPLEFT", card.frame, "TOPLEFT", 80, -20);
        const kicker = Native.createText(card.frame, "RAID ROLE", "GameFontNormalSmall", theme.colors.muted);
        kicker.SetPoint("TOPLEFT", card.frame, "TOPLEFT", 80, -45);

        const minus = ButtonUI.createButton(card.frame, { text: "−", width: 40, height: 38, accent });
        minus.frame.SetPoint("TOPLEFT", card.frame, "TOPLEFT", 24, -82);
        const countPanel = Native.createPanel(card.frame, theme.colors.background, accent);
        countPanel.frame.SetPoint("TOPLEFT", card.frame, "TOPLEFT", 70, -82);
        countPanel.frame.SetSize(160, 38);
        const count = Native.createText(countPanel.frame, "0", "GameFontNormalHuge", theme.colors.text);
        count.SetPoint("CENTER", countPanel.frame, "CENTER", 0, 0);
        count.SetWidth(148);
        count.SetJustifyH("CENTER");
        const plus = ButtonUI.createButton(card.frame, { text: "+", width: 40, height: 38, accent });
        plus.frame.SetPoint("TOPRIGHT", card.frame, "TOPRIGHT", -24, -82);

        const botSlots = Native.createText(card.frame, "0 bot slots after humans", "GameFontHighlightSmall", accent);
        botSlots.SetPoint("TOP", card.frame, "TOP", 0, -132);
        botSlots.SetWidth(260);
        botSlots.SetJustifyH("CENTER");
        botSlots.SetJustifyV("TOP");

        const divider = Native.createSolid(card.frame, theme.colors.border, "ARTWORK");
        divider.SetPoint("BOTTOMLEFT", card.frame, "BOTTOMLEFT", 18, 48);
        divider.SetPoint("BOTTOMRIGHT", card.frame, "BOTTOMRIGHT", -18, 48);
        divider.SetHeight(1);

        const roleHelp = Native.createText(card.frame, roleDescription(role), "GameFontHighlightSmall", theme.colors.muted);
        roleHelp.SetPoint("BOTTOMLEFT", card.frame, "BOTTOMLEFT", 20, 12);
        roleHelp.SetWidth(260);
        roleHelp.SetHeight(30);
        roleHelp.SetJustifyH("CENTER");
        roleHelp.SetJustifyV("TOP");

        const roleCopy = role;
        minus.frame.SetScript("OnMouseDown", () => Model.setRoleTarget(roleCopy, Model.targetForRole(roleCopy) - 1));
        plus.frame.SetScript("OnMouseDown", () => Model.setRoleTarget(roleCopy, Model.targetForRole(roleCopy) + 1));

        quickCards[role] = { card, count, botSlots, minus, plus };
    }

    const quickSummary = Native.createPanel(quickView, theme.colors.background, theme.colors.border);
    quickSummary.frame.SetPoint("TOPLEFT", quickView, "TOPLEFT", 0, -236);
    quickSummary.frame.SetPoint("TOPRIGHT", quickView, "TOPRIGHT", 0, -236);
    quickSummary.frame.SetHeight(88);

    const quickTotalLabel = Native.createText(quickSummary.frame, "TOTAL RAID SIZE", "GameFontNormalSmall", theme.colors.muted);
    quickTotalLabel.SetPoint("TOPLEFT", quickSummary.frame, "TOPLEFT", 18, -13);
    const quickTotal = Native.createText(quickSummary.frame, "25 / 25", "GameFontNormalHuge");
    quickTotal.SetPoint("TOPLEFT", quickSummary.frame, "TOPLEFT", 18, -36);

    const quickDivider = Native.createSolid(quickSummary.frame, theme.colors.borderStrong, "ARTWORK");
    quickDivider.SetPoint("TOPLEFT", quickSummary.frame, "TOPLEFT", 190, -12);
    quickDivider.SetHeight(64);
    quickDivider.SetWidth(1);

    const quickCheck = Native.createPanel(quickSummary.frame, theme.colors.surfaceDeep, theme.colors.success);
    quickCheck.frame.SetSize(32, 32);
    quickCheck.frame.SetPoint("LEFT", quickSummary.frame, "LEFT", 216, 0);
    const quickCheckIcon = quickCheck.frame.CreateTexture(undefined, "ARTWORK");
    quickCheckIcon.SetTexture("Interface\\Buttons\\UI-CheckBox-Check");
    quickCheckIcon.SetAllPoints(quickCheck.frame);
    const quickCheckBang = Native.createText(quickCheck.frame, "!", "GameFontNormalLarge", theme.colors.warning);
    quickCheckBang.SetPoint("CENTER", quickCheck.frame, "CENTER", 0, 0);
    quickCheckBang.SetJustifyH("CENTER");
    quickCheckBang.Hide();

    const quickStatusTitle = Native.createText(quickSummary.frame, "Raid composition is complete!", "GameFontNormal", theme.colors.success);
    quickStatusTitle.SetPoint("TOPLEFT", quickSummary.frame, "TOPLEFT", 264, -20);
    quickStatusTitle.SetWidth(380);
    const quickStatusDetail = Native.createText(
        quickSummary.frame,
        "This setup will create the selected raid size with your chosen role balance.",
        "GameFontHighlightSmall",
        theme.colors.muted,
    );
    quickStatusDetail.SetPoint("TOPLEFT", quickStatusTitle, "BOTTOMLEFT", 0, -5);
    quickStatusDetail.SetWidth(600);
    quickStatusDetail.SetHeight(34);
    quickStatusDetail.SetJustifyV("TOP");

    // One full-width, vertically scrollable surface replaces the three cramped fixed columns.
    const exactScroll = ScrollUI.createScrollList(exactView, 936, 418);
    exactScroll.frame.SetPoint("TOPLEFT", exactView, "TOPLEFT", 0, -4);

    const exactSections: Record<Role, any> = {} as Record<Role, any>;
    for (const role of roleOrder) {
        const accent = Model.roleAccent(role);
        const panel = Native.createPanel(exactScroll.content, theme.colors.surfaceDeep, theme.colors.border);
        panel.frame.SetWidth(906);

        const roleStrip = Native.createSolid(panel.frame, accent, "ARTWORK");
        roleStrip.SetHeight(3);
        roleStrip.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 0, 0);
        roleStrip.SetPoint("TOPRIGHT", panel.frame, "TOPRIGHT", 0, 0);
        const roleTint = Native.createSolid(panel.frame, Native.withAlpha(accent, 0.035), "BACKGROUND");
        roleTint.SetAllPoints(panel.frame);

        const roleBadge = Native.createFramedRoleIcon(panel.frame, role, 36, accent);
        roleBadge.frame.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 12, -10);
        const label = Native.createText(panel.frame, Model.roleLabel(role).toUpperCase(), "GameFontNormal", accent);
        label.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 60, -12);
        const count = Native.createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted);
        count.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 60, -32);
        count.SetWidth(430);

        const add = ButtonUI.createButton(panel.frame, {
            text: "+ Add specific build",
            width: 154,
            height: 30,
            accent,
        });
        add.frame.SetPoint("TOPRIGHT", panel.frame, "TOPRIGHT", -12, -12);

        const empty = Native.createText(
            panel.frame,
            "No reserved builds. Every remaining " + Model.roleLabel(role).toLowerCase() + " slot stays Auto.",
            "GameFontHighlightSmall",
            theme.colors.muted,
        );
        empty.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 18, -58);
        empty.SetWidth(820);
        empty.SetJustifyV("TOP");

        exactScroll.bindWheel(panel.frame);
        exactScroll.bindWheel(add.frame);
        exactSections[role] = { panel, count, add, empty, rowsByKey: {} as Record<string, any>, rowKeys: [] as string[] };
    }

    const groupCards: any[] = [];
    for (let g = 0; g < 8; g += 1) {
        const card = Native.createPanel(rosterView, theme.colors.surfaceDeep, theme.colors.border);
        const headerAccent = Native.createSolid(card.frame, Native.withAlpha(theme.colors.primary, 0.72), "ARTWORK");
        headerAccent.SetPoint("TOPLEFT", card.frame, "TOPLEFT", 0, 0);
        headerAccent.SetPoint("TOPRIGHT", card.frame, "TOPRIGHT", 0, 0);
        headerAccent.SetHeight(2);

        const groupTitle = Native.createText(card.frame, "GROUP " + String(g + 1), "GameFontNormalSmall", theme.colors.text);
        groupTitle.SetPoint("TOPLEFT", card.frame, "TOPLEFT", 10, -10);
        const groupHint = Native.createText(card.frame, "SUBGROUP", "GameFontHighlightSmall", theme.colors.muted);
        groupHint.SetPoint("TOPLEFT", card.frame, "TOPLEFT", 10, -27);
        const groupCount = Native.createText(card.frame, "0 / 5", "GameFontHighlightSmall", theme.colors.primary);
        groupCount.SetPoint("TOPRIGHT", card.frame, "TOPRIGHT", -10, -12);
        groupCount.SetWidth(54);
        groupCount.SetJustifyH("RIGHT");

        const headerRule = Native.createSolid(card.frame, theme.colors.border, "ARTWORK");
        headerRule.SetPoint("TOPLEFT", card.frame, "TOPLEFT", 10, -45);
        headerRule.SetPoint("TOPRIGHT", card.frame, "TOPRIGHT", -10, -45);
        headerRule.SetHeight(1);

        const rows: any[] = [];
        for (let r = 0; r < 5; r += 1) {
            const row = CreateFrame("Frame", undefined, card.frame);
            row.SetHeight(30);
            row.SetPoint("TOPLEFT", card.frame, "TOPLEFT", 8, -(50 + r * 31));
            row.SetPoint("RIGHT", card.frame, "RIGHT", -8, 0);

            const rowBg = Native.createSolid(row, Native.withAlpha(theme.colors.surfaceRaised, 0.58), "BACKGROUND");
            rowBg.SetAllPoints(row);

            const roleBar = Native.createSolid(row, theme.colors.dps, "ARTWORK");
            roleBar.SetWidth(3);
            roleBar.SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0);
            roleBar.SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0);

            const iconBadge = Native.createFramedIcon(row, "Interface\\Icons\\INV_Misc_QuestionMark", 26, theme.colors.border);
            iconBadge.frame.SetPoint("LEFT", row, "LEFT", 7, 0);
            const icon = iconBadge.icon;
            iconBadge.frame.Hide();

            const name = Native.createText(row, "Empty slot", "GameFontHighlightSmall", theme.colors.muted);
            name.SetPoint("TOPLEFT", row, "TOPLEFT", 40, -4);
            name.SetWidth(146);
            const spec = Native.createText(row, "", "GameFontHighlightSmall", theme.colors.muted);
            spec.SetPoint("TOPLEFT", row, "TOPLEFT", 40, -18);
            spec.SetWidth(156);

            const roleIcon = row.CreateTexture(undefined, "ARTWORK");
            roleIcon.SetSize(15, 15);
            roleIcon.SetPoint("RIGHT", row, "RIGHT", -7, 0);
            Native.setRoleIcon(roleIcon, "DPS");
            roleIcon.SetAlpha(0.85);

            rows.push({ row, rowBg, roleBar, iconBadge, icon, name, spec, roleIcon });
        }
        card.frame.Hide();
        groupCards.push({ card, headerAccent, groupTitle, groupHint, groupCount, rows });
    }

    // Status ----------------------------------------------------------------
    const statusTitle = Native.createText(status.frame, "ROSTER STATUS", "GameFontNormalSmall", theme.colors.muted);
    statusTitle.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -16);

    const phaseCard = Native.createPanel(status.frame, theme.colors.surfaceBlue, theme.colors.borderStrong);
    phaseCard.frame.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -40);
    phaseCard.frame.SetPoint("TOPRIGHT", status.frame, "TOPRIGHT", -16, -40);
    phaseCard.frame.SetHeight(92);

    const phaseAccent = Native.createSolid(phaseCard.frame, theme.colors.primary, "ARTWORK");
    phaseAccent.SetWidth(3);
    phaseAccent.SetPoint("TOPLEFT", phaseCard.frame, "TOPLEFT", 0, 0);
    phaseAccent.SetPoint("BOTTOMLEFT", phaseCard.frame, "BOTTOMLEFT", 0, 0);
    const phaseGlow = Native.createSolid(phaseCard.frame, Native.withAlpha(theme.colors.primary, 0.14), "ARTWORK");
    phaseGlow.SetSize(18, 18);
    phaseGlow.SetPoint("TOPLEFT", phaseCard.frame, "TOPLEFT", 11, -12);
    const phaseDot = Native.createSolid(phaseCard.frame, theme.colors.primary, "OVERLAY");
    phaseDot.SetSize(8, 8);
    phaseDot.SetPoint("TOPLEFT", phaseCard.frame, "TOPLEFT", 16, -17);
    const phaseText = Native.createText(phaseCard.frame, "Configure roster", "GameFontNormal");
    phaseText.SetPoint("LEFT", phaseDot, "RIGHT", 10, 2);
    phaseText.SetWidth(220);
    const phaseDetail = Native.createText(phaseCard.frame, "", "GameFontHighlightSmall", theme.colors.muted);
    phaseDetail.SetPoint("TOPLEFT", phaseText, "BOTTOMLEFT", 0, -4);
    phaseDetail.SetWidth(230);
    phaseDetail.SetJustifyV("TOP");

    const rosterCount = Native.createText(status.frame, "1 / 5", "GameFontNormalHuge");
    rosterCount.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -146);
    const sourceText = Native.createText(status.frame, "1 human  ·  4 bot slots", "GameFontHighlightSmall", theme.colors.muted);
    sourceText.SetPoint("TOPLEFT", rosterCount, "BOTTOMLEFT", 0, -4);
    sourceText.SetWidth(270);

    const statusRoleChips: Record<Role, any> = {} as Record<Role, any>;
    for (let i = 0; i < roleOrder.length; i += 1) {
        const role = roleOrder[i];
        const chip = Native.createPanel(status.frame, theme.colors.surfaceDeep, Model.roleAccent(role));
        chip.frame.SetSize(84, 32);
        chip.frame.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16 + i * 90, -201);
        const icon = chip.frame.CreateTexture(undefined, "ARTWORK");
        icon.SetSize(16, 16);
        icon.SetPoint("LEFT", chip.frame, "LEFT", 7, 0);
        Native.setRoleIcon(icon, role);
        const label = Native.createText(chip.frame, "", "GameFontHighlightSmall", Model.roleAccent(role));
        label.SetPoint("LEFT", icon, "RIGHT", 5, 0);
        label.SetWidth(54);
        statusRoleChips[role] = { chip, label };
    }

    const progressBg = Native.createPanel(status.frame, theme.colors.background, theme.colors.border);
    progressBg.frame.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -245);
    progressBg.frame.SetSize(270, 12);
    const progressFill = Native.createSolid(progressBg.frame, theme.colors.primary, "ARTWORK");
    progressFill.SetPoint("TOPLEFT", progressBg.frame, "TOPLEFT", 2, -2);
    progressFill.SetPoint("BOTTOMLEFT", progressBg.frame, "BOTTOMLEFT", 2, 2);
    progressFill.SetWidth(1);
    const progressText = Native.createText(status.frame, "", "GameFontHighlightSmall", theme.colors.muted);
    progressText.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -264);
    progressText.SetWidth(270);
    progressText.SetHeight(32);
    progressText.SetJustifyV("TOP");

    const coverageCard = Native.createPanel(status.frame, theme.colors.background, theme.colors.border);
    coverageCard.frame.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -307);
    coverageCard.frame.SetPoint("TOPRIGHT", status.frame, "TOPRIGHT", -16, -307);
    coverageCard.frame.SetHeight(154);

    const coverageGlyph = Native.createPanel(coverageCard.frame, theme.colors.surfaceDeep, theme.colors.borderStrong);
    coverageGlyph.frame.SetSize(30, 30);
    coverageGlyph.frame.SetPoint("TOPLEFT", coverageCard.frame, "TOPLEFT", 12, -11);
    for (let i = 0; i < 3; i += 1) {
        const bar = Native.createSolid(coverageGlyph.frame, theme.colors.text, "ARTWORK");
        bar.SetWidth(4);
        bar.SetHeight(7 + i * 5);
        bar.SetPoint("BOTTOMLEFT", coverageGlyph.frame, "BOTTOMLEFT", 6 + i * 7, 5);
    }
    const coverageTitle = Native.createText(coverageCard.frame, "UTILITY COVERAGE", "GameFontNormalSmall", theme.colors.muted);
    coverageTitle.SetPoint("LEFT", coverageGlyph.frame, "RIGHT", 9, 0);

    const coverageDefs: Array<{ token: string; label: string }> = [
        { token: "interrupt", label: "Interrupt" },
        { token: "dispel", label: "Dispel" },
        { token: "buffs", label: "Raid Buffs" },
        { token: "heroism", label: "Heroism" },
        { token: "battle-rez", label: "Battle Rez" },
        { token: "cc", label: "CC" },
        { token: "threat", label: "Threat" },
    ];
    const coverageChips: any[] = [];
    for (let i = 0; i < coverageDefs.length; i += 1) {
        const column = i % 3;
        const row = Math.floor(i / 3);
        const chip = Native.createPanel(coverageCard.frame, theme.colors.surfaceDeep, theme.colors.border);
        chip.frame.SetSize(78, 24);
        chip.frame.SetPoint("TOPLEFT", coverageCard.frame, "TOPLEFT", 12 + column * 82, -(50 + row * 29));
        const check = chip.frame.CreateTexture(undefined, "ARTWORK");
        check.SetTexture("Interface\\Buttons\\UI-CheckBox-Check");
        check.SetSize(14, 14);
        check.SetPoint("LEFT", chip.frame, "LEFT", 5, 0);
        check.Hide();
        const label = Native.createText(chip.frame, coverageDefs[i].label, "GameFontHighlightSmall", theme.colors.muted);
        label.SetPoint("LEFT", chip.frame, "LEFT", 22, 0);
        label.SetWidth(53);
        coverageChips.push({ panel: chip, check, label, token: coverageDefs[i].token });
    }

    const coverageDamageText = Native.createText(coverageCard.frame, "Prepare a roster to inspect utility.", "GameFontHighlightSmall", theme.colors.muted);
    coverageDamageText.SetPoint("BOTTOMLEFT", coverageCard.frame, "BOTTOMLEFT", 12, 9);
    coverageDamageText.SetWidth(246);

    const nextCard = Native.createPanel(status.frame, theme.colors.background, theme.colors.border);
    nextCard.frame.SetPoint("TOPLEFT", status.frame, "TOPLEFT", 16, -477);
    nextCard.frame.SetPoint("TOPRIGHT", status.frame, "TOPRIGHT", -16, -477);
    nextCard.frame.SetHeight(116);

    const nextBadge = Native.createPanel(nextCard.frame, theme.colors.surfaceDeep, theme.colors.warning);
    nextBadge.frame.SetSize(28, 28);
    nextBadge.frame.SetPoint("TOPLEFT", nextCard.frame, "TOPLEFT", 12, -12);
    const nextBang = Native.createText(nextBadge.frame, "!", "GameFontNormal", theme.colors.warning);
    nextBang.SetPoint("CENTER", nextBadge.frame, "CENTER", 0, 0);
    nextBang.SetJustifyH("CENTER");
    const warningsTitle = Native.createText(nextCard.frame, "NEXT STEP", "GameFontNormalSmall", theme.colors.warning);
    warningsTitle.SetPoint("LEFT", nextBadge.frame, "RIGHT", 9, 0);
    const nextDetail = Native.createText(nextCard.frame, "", "GameFontHighlightSmall", theme.colors.warning);
    nextDetail.SetPoint("TOPLEFT", nextCard.frame, "TOPLEFT", 12, -48);
    nextDetail.SetWidth(246);
    nextDetail.SetHeight(58);
    nextDetail.SetJustifyV("TOP");

    const buildButton = ButtonUI.createButton(status.frame, {
        text: "Build & Prepare", width: 270, height: 52, accent: theme.colors.primary, emphasis: true,
        onClick: () => Model.buildAndPrepare(),
    });
    buildButton.frame.SetPoint("BOTTOMLEFT", status.frame, "BOTTOMLEFT", 16, 66);

    let showAssembleConfirm = () => {};
    const assembleButton = ButtonUI.createButton(status.frame, { text: "Assemble", width: 194, height: 46, accent: theme.colors.success, onClick: () => showAssembleConfirm() });
    assembleButton.frame.SetPoint("BOTTOMLEFT", status.frame, "BOTTOMLEFT", 16, 18);
    const resetButton = ButtonUI.createButton(status.frame, { text: "Reset", width: 68, height: 46, accent: theme.colors.error, onClick: () => Model.clearPlan() });
    resetButton.frame.SetPoint("LEFT", assembleButton.frame, "RIGHT", 8, 0);

    // Templates modal --------------------------------------------------------
    const templatesModal = ModalUI.createModal(frame, 960, 650);
    templatesModal.setTitle("Raid Templates");
    templatesModal.setSubtitle("Start from a proven raid core or save your own. Unlisted slots remain Auto-filled.");
    templatesModal.setHeaderIcon(ICON_TEMPLATES);

    const templateSaveLabel = Native.createText(templatesModal.content, "SAVE CURRENT RAID", "GameFontNormalSmall", theme.colors.muted);
    templateSaveLabel.SetPoint("TOPLEFT", templatesModal.content, "TOPLEFT", 0, 0);
    const templateName = InputUI.createTextInput(templatesModal.content, 300, 34);
    templateName.frame.SetPoint("TOPLEFT", templatesModal.content, "TOPLEFT", 0, -24);
    const templateSave = ButtonUI.createButton(templatesModal.content, {
        text: "Save Current",
        width: 124,
        height: 36,
        accent: theme.colors.primary,
        emphasis: true,
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

    let templateTab: "BUILTIN" | "CUSTOM" = "BUILTIN";
    const templateBuiltinTab = ButtonUI.createButton(templatesModal.content, { text: "Built-in", width: 138, height: 34, accent: theme.colors.primary });
    templateBuiltinTab.frame.SetPoint("TOPLEFT", templatesModal.content, "TOPLEFT", 0, -82);
    const templateCustomTab = ButtonUI.createButton(templatesModal.content, { text: "My Templates", width: 150, height: 34, accent: theme.colors.warning });
    templateCustomTab.frame.SetPoint("LEFT", templateBuiltinTab.frame, "RIGHT", 8, 0);

    const templateScroll = ScrollUI.createScrollList(templatesModal.content, 884, 420);
    templateScroll.frame.SetPoint("TOPLEFT", templatesModal.content, "TOPLEFT", 0, -126);
    const templateRows: WoWFrame[] = [];
    const templateEmpty = Native.createText(
        templateScroll.content,
        "",
        "GameFontHighlight",
        theme.colors.muted,
    );
    templateEmpty.SetPoint("TOPLEFT", templateScroll.content, "TOPLEFT", 24, -28);
    templateEmpty.SetWidth(800);
    templateEmpty.SetJustifyH("CENTER");
    templateEmpty.SetJustifyV("TOP");
    templateEmpty.Hide();

    function clearDynamicRows(rows: WoWFrame[]): void {
        for (const row of rows) row.Hide();
    }

    function refreshTemplates(): void {
        clearDynamicRows(templateRows);
        templateSave.setEnabled(Model.config().mode === "RAID");
        templateBuiltinTab.setSelected(templateTab === "BUILTIN");
        templateCustomTab.setSelected(templateTab === "CUSTOM");

        const names = templateTab === "BUILTIN" ? Model.listBuiltinProfiles() : Model.listCustomProfiles();
        if (names.length === 0) {
            templateEmpty.SetText(
                templateTab === "BUILTIN"
                    ? "No built-in raid compositions are available."
                    : "No custom templates yet. Configure a raid, name it above, then Save Current."
            );
            templateEmpty.Show();
        } else templateEmpty.Hide();

        for (let i = 0; i < names.length; i += 1) {
            let row = templateRows[i];
            if (row === undefined) {
                const panel = Native.createPanel(templateScroll.content, theme.colors.surfaceRaised, theme.colors.border);
                panel.frame.SetSize(854, 70);
                const accent = Native.createSolid(panel.frame, theme.colors.primary, "ARTWORK");
                accent.SetWidth(3);
                accent.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 0, 0);
                accent.SetPoint("BOTTOMLEFT", panel.frame, "BOTTOMLEFT", 0, 0);
                const iconBadge = Native.createFramedIcon(panel.frame, ICON_RAID, 40, theme.colors.primary);
                iconBadge.frame.SetPoint("LEFT", panel.frame, "LEFT", 12, 0);
                const name = Native.createText(panel.frame, "", "GameFontHighlight");
                name.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 64, -10);
                name.SetWidth(500);
                const tag = Native.createText(panel.frame, "", "GameFontNormalSmall", theme.colors.primary);
                tag.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 64, -33);
                tag.SetWidth(80);
                const info = Native.createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted);
                info.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 142, -33);
                info.SetWidth(470);
                const load = ButtonUI.createButton(panel.frame, { text: "Load", width: 72, height: 30, accent: theme.colors.primary });
                const remove = ButtonUI.createButton(panel.frame, { text: "Delete", width: 70, height: 30, accent: theme.colors.error });
                (panel.frame as any)._accent = accent;
                (panel.frame as any)._iconBadge = iconBadge;
                (panel.frame as any)._name = name;
                (panel.frame as any)._tag = tag;
                (panel.frame as any)._info = info;
                (panel.frame as any)._load = load;
                (panel.frame as any)._remove = remove;
                templateScroll.bindWheel(panel.frame);
                templateScroll.bindWheel(load.frame);
                templateScroll.bindWheel(remove.frame);
                row = panel.frame;
                templateRows[i] = row;
            }

            row.ClearAllPoints();
            row.SetPoint("TOPLEFT", templateScroll.content, "TOPLEFT", 0, -(i * 78));
            const profileName = names[i];
            const builtin = templateTab === "BUILTIN";
            const rowAccent = builtin ? theme.colors.primary : theme.colors.warning;
            Native.setTextureColor((row as any)._accent, rowAccent);
            (row as any)._iconBadge.outline.setColor(rowAccent);
            (row as any)._iconBadge.icon.SetTexture(builtin ? ICON_RAID : ICON_TEMPLATES);
            (row as any)._iconBadge.icon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            (row as any)._name.SetText(profileName);
            (row as any)._tag.SetText(builtin ? "BUILT-IN" : "CUSTOM");
            (row as any)._tag.SetTextColor(rowAccent[0], rowAccent[1], rowAccent[2], 1);
            (row as any)._info.SetText(Model.profileDescription(profileName));

            const load = (row as any)._load as UIButton;
            const remove = (row as any)._remove as UIButton;
            load.frame.ClearAllPoints();
            remove.frame.ClearAllPoints();
            if (builtin) {
                remove.frame.Hide();
                load.frame.SetPoint("RIGHT", row, "RIGHT", -10, 0);
            } else {
                load.frame.SetPoint("RIGHT", row, "RIGHT", -88, 0);
                remove.frame.SetPoint("RIGHT", row, "RIGHT", -10, 0);
                remove.frame.SetScript("OnMouseDown", () => {
                    Model.deleteProfile(profileName);
                    refreshTemplates();
                });
                remove.frame.Show();
            }
            load.frame.SetScript("OnMouseDown", () => {
                Model.loadProfile(profileName);
                templatesModal.hide();
            });
            row.Show();
        }
        templateScroll.setContentHeight(Math.max(420, names.length * 78));
    }

    templateBuiltinTab.frame.SetScript("OnMouseDown", () => {
        templateTab = "BUILTIN";
        templateScroll.scrollToTop();
        refreshTemplates();
    });
    templateCustomTab.frame.SetScript("OnMouseDown", () => {
        templateTab = "CUSTOM";
        templateScroll.scrollToTop();
        refreshTemplates();
    });

    showTemplates = () => {
        ChoiceUI.closeChoicePopup();
        templateScroll.scrollToTop();
        refreshTemplates();
        templatesModal.show();
    };

    // Humans & Pins modal ----------------------------------------------------
    const peopleModal = ModalUI.createModal(frame, 980, 620);
    peopleModal.setTitle("Humans & Pins");
    peopleModal.setSubtitle("Humans are locked anchors. Pins reserve named companions without making active group members disposable.");
    peopleModal.setHeaderIcon(ICON_PEOPLE);

    const peopleHumanTitle = Native.createText(peopleModal.content, "HUMAN ANCHORS", "GameFontNormalSmall", theme.colors.muted);
    peopleHumanTitle.SetPoint("TOPLEFT", peopleModal.content, "TOPLEFT", 0, 0);
    const humanScroll = ScrollUI.createScrollList(peopleModal.content, 442, 430);
    humanScroll.frame.SetPoint("TOPLEFT", peopleModal.content, "TOPLEFT", 0, -26);
    const humanRowsModal: WoWFrame[] = [];
    const humanEmpty = Native.createText(
        humanScroll.content,
        "No human anchors detected.",
        "GameFontHighlight",
        theme.colors.muted,
    );
    humanEmpty.SetPoint("TOPLEFT", humanScroll.content, "TOPLEFT", 18, -24);
    humanEmpty.SetWidth(360);
    humanEmpty.SetJustifyH("CENTER");
    humanEmpty.Hide();

    const pinPane = CreateFrame("Frame", undefined, peopleModal.content);
    pinPane.SetPoint("TOPRIGHT", peopleModal.content, "TOPRIGHT", 0, 0);
    pinPane.SetSize(442, 456);

    const pinTitle = Native.createText(pinPane, "PIN COMPANION", "GameFontNormalSmall", theme.colors.muted);
    pinTitle.SetPoint("TOPLEFT", pinPane, "TOPLEFT", 0, 0);
    const pinBuilder = Native.createPanel(pinPane, theme.colors.surfaceRaised, theme.colors.border);
    pinBuilder.frame.SetPoint("TOPLEFT", pinPane, "TOPLEFT", 0, -26);
    pinBuilder.frame.SetPoint("TOPRIGHT", pinPane, "TOPRIGHT", 0, -26);
    pinBuilder.frame.SetHeight(118);

    const pinInput = InputUI.createTextInput(pinBuilder.frame, 250, 34);
    pinInput.frame.SetPoint("TOPLEFT", pinBuilder.frame, "TOPLEFT", 12, -12);

    let pinRole: Role = "DPS";
    let pinRequired = false;
    const pinRoleButtons: Record<Role, UIButton> = {
        TANK: ButtonUI.createButton(pinBuilder.frame, { text: "Tank", width: 66, height: 28, accent: theme.colors.tank }),
        HEALER: ButtonUI.createButton(pinBuilder.frame, { text: "Healer", width: 66, height: 28, accent: theme.colors.healer }),
        DPS: ButtonUI.createButton(pinBuilder.frame, { text: "DPS", width: 66, height: 28, accent: theme.colors.dps }),
    };
    pinRoleButtons.TANK.frame.SetPoint("TOPLEFT", pinBuilder.frame, "TOPLEFT", 12, -58);
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
        pinBuilder.frame,
        "Required",
        () => pinRequired,
        (value) => { pinRequired = value; },
    );
    pinToggle.frame.SetPoint("TOPLEFT", pinBuilder.frame, "TOPLEFT", 230, -57);
    pinToggle.frame.SetWidth(92);

    const addPinButton = ButtonUI.createButton(pinBuilder.frame, {
        text: "Pin Member",
        width: 112,
        height: 34,
        accent: theme.colors.primary,
        emphasis: true,
        onClick: () => {
            const name = pinInput.getText();
            if (name !== "") {
                Model.addPin(name, pinRole, pinRequired);
                pinInput.clear();
                refreshPeople();
            }
        },
    });
    addPinButton.frame.SetPoint("TOPRIGHT", pinBuilder.frame, "TOPRIGHT", -12, -12);

    const pinListTitle = Native.createText(pinPane, "PINNED MEMBERS", "GameFontNormalSmall", theme.colors.muted);
    pinListTitle.SetPoint("TOPLEFT", pinPane, "TOPLEFT", 0, -160);
    const pinScroll = ScrollUI.createScrollList(pinPane, 442, 270);
    pinScroll.frame.SetPoint("TOPLEFT", pinPane, "TOPLEFT", 0, -186);
    const pinRows: WoWFrame[] = [];
    const pinEmpty = Native.createText(
        pinScroll.content,
        "No companions pinned. Add a name above when you want Composer to keep someone in mind.",
        "GameFontHighlightSmall",
        theme.colors.muted,
    );
    pinEmpty.SetPoint("TOPLEFT", pinScroll.content, "TOPLEFT", 24, -26);
    pinEmpty.SetWidth(350);
    pinEmpty.SetJustifyH("CENTER");
    pinEmpty.SetJustifyV("TOP");
    pinEmpty.Hide();

    function refreshPeople(): void {
        clearDynamicRows(humanRowsModal);
        const list = Model.humans();
        if (list.length === 0) humanEmpty.Show();
        else humanEmpty.Hide();

        for (let i = 0; i < list.length; i += 1) {
            const human = list[i];
            let row = humanRowsModal[i];
            if (row === undefined) {
                const panel = Native.createPanel(humanScroll.content, theme.colors.surfaceRaised, theme.colors.border);
                panel.frame.SetSize(412, 64);
                const classBadge = Native.createFramedIcon(panel.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 34, theme.colors.borderStrong);
                classBadge.frame.SetPoint("LEFT", panel.frame, "LEFT", 8, 0);
                const icon = classBadge.icon;
                const name = Native.createText(panel.frame, "", "GameFontHighlightSmall");
                name.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 52, -11);
                name.SetWidth(150);
                const identity = Native.createText(panel.frame, "REAL PLAYER", "GameFontNormalSmall", theme.colors.primary);
                identity.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 52, -33);
                identity.SetWidth(150);
                const buttons: Record<Role, UIButton> = {
                    TANK: ButtonUI.createButton(panel.frame, { text: "Tank", width: 62, height: 26, accent: theme.colors.tank }),
                    HEALER: ButtonUI.createButton(panel.frame, { text: "Healer", width: 62, height: 26, accent: theme.colors.healer }),
                    DPS: ButtonUI.createButton(panel.frame, { text: "DPS", width: 62, height: 26, accent: theme.colors.dps }),
                };
                buttons.DPS.frame.SetPoint("RIGHT", panel.frame, "RIGHT", -8, 0);
                buttons.HEALER.frame.SetPoint("RIGHT", buttons.DPS.frame, "LEFT", -5, 0);
                buttons.TANK.frame.SetPoint("RIGHT", buttons.HEALER.frame, "LEFT", -5, 0);
                (panel.frame as any)._classBadge = classBadge;
                (panel.frame as any)._icon = icon;
                (panel.frame as any)._name = name;
                (panel.frame as any)._identity = identity;
                (panel.frame as any)._buttons = buttons;
                humanScroll.bindWheel(panel.frame);
                for (const wheelRole of roleOrder) humanScroll.bindWheel(buttons[wheelRole].frame);
                row = panel.frame;
                humanRowsModal[i] = row;
            }

            row.ClearAllPoints();
            row.SetPoint("TOPLEFT", humanScroll.content, "TOPLEFT", 0, -(i * 70));
            Native.setClassIcon((row as any)._icon, String(human.class));
            (row as any)._classBadge.outline.setColor(Native.classColor(String(human.class)));
            (row as any)._name.SetText((human.isPlayer ? "YOU  ·  " : "") + human.name);
            (row as any)._identity.SetText(Model.classLabel(String(human.class)) + "  ·  REAL PLAYER");
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
        humanScroll.setContentHeight(Math.max(430, list.length * 70));

        for (const role of roleOrder) pinRoleButtons[role].setSelected(pinRole === role);
        pinToggle.refresh();

        clearDynamicRows(pinRows);
        const pins = Model.pinnedMembers();
        if (pins.length === 0) pinEmpty.Show();
        else pinEmpty.Hide();
        for (let i = 0; i < pins.length; i += 1) {
            const pin = pins[i];
            let row = pinRows[i];
            if (row === undefined) {
                const panel = Native.createPanel(pinScroll.content, theme.colors.surfaceRaised, theme.colors.border);
                panel.frame.SetSize(412, 50);
                const roleBadge = Native.createFramedRoleIcon(panel.frame, "DPS", 32, theme.colors.dps);
                roleBadge.frame.SetPoint("LEFT", panel.frame, "LEFT", 8, 0);
                const name = Native.createText(panel.frame, "", "GameFontHighlightSmall");
                name.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 50, -9);
                name.SetWidth(220);
                const info = Native.createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted);
                info.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 50, -29);
                info.SetWidth(220);
                const remove = ButtonUI.createButton(panel.frame, { text: "Remove", width: 70, height: 28, accent: theme.colors.error });
                remove.frame.SetPoint("RIGHT", panel.frame, "RIGHT", -8, 0);
                (panel.frame as any)._roleBadge = roleBadge;
                (panel.frame as any)._roleIcon = roleBadge.icon;
                (panel.frame as any)._name = name;
                (panel.frame as any)._info = info;
                (panel.frame as any)._remove = remove;
                pinScroll.bindWheel(panel.frame);
                pinScroll.bindWheel(remove.frame);
                row = panel.frame;
                pinRows[i] = row;
            }
            row.ClearAllPoints();
            row.SetPoint("TOPLEFT", pinScroll.content, "TOPLEFT", 0, -(i * 56));
            const pinAccent = Model.roleAccent(pin.role as Role);
            Native.setRoleIcon((row as any)._roleIcon, pin.role);
            (row as any)._roleBadge.outline.setColor(pinAccent);
            (row as any)._name.SetText(String(pin.name));
            (row as any)._info.SetText(Model.roleLabel(pin.role as Role) + "  ·  " + (pin.required ? "REQUIRED" : "Preferred companion"));
            (row as any)._info.SetTextColor(
                pin.required ? theme.colors.warning[0] : theme.colors.muted[0],
                pin.required ? theme.colors.warning[1] : theme.colors.muted[1],
                pin.required ? theme.colors.warning[2] : theme.colors.muted[2],
                1
            );
            const indexCopy = i + 1;
            (row as any)._remove.frame.SetScript("OnMouseDown", () => {
                Model.removePin(indexCopy);
                refreshPeople();
            });
            row.Show();
        }
        pinScroll.setContentHeight(Math.max(270, pins.length * 56));
    }

    showPeople = () => {
        ChoiceUI.closeChoicePopup();
        refreshPeople();
        peopleModal.show();
    };

    // Options modal ----------------------------------------------------------
    const optionsModal = ModalUI.createModal(frame, 820, 650);
    optionsModal.setHeaderIcon(ICON_OPTIONS);
    optionsModal.setTitle("Composition Options");
    optionsModal.setSubtitle("Tune candidate selection without turning the common path into a settings dashboard.");

    const optionDefs: Array<{ label: string; key: string; hint: string }> = [
        { label: "Prefer guild bots", key: "preferGuild", hint: "Soft preference for suitable guild companions. It does not ban other valid candidates." },
        { label: "Allow world fallback", key: "fillWorld", hint: "Hard pool boundary. Off means Composer will not fill open slots from outside the guild." },
        { label: "Balance classes", key: "balanceClasses", hint: "Avoid heavily lopsided class coverage when Auto is filling slots." },
        { label: "Balance utility", key: "balanceUtility", hint: "Prefer broader raid and dungeon utility coverage." },
        { label: "Balance melee / ranged", key: "balanceRange", hint: "Avoid extreme melee or ranged skew where possible." },
        { label: "Avoid duplicate classes", key: "avoidDuplicateClasses", hint: "Stricter diversity preference. Exact builds still take priority." },
        { label: "Queue random dungeon after assembly", key: "queueAfterAssemble", hint: "Only applies when Random Dungeon is the selected activity." },
    ];
    const optionToggles: any[] = [];

    const candidateTitle = Native.createText(optionsModal.content, "CANDIDATE POOL", "GameFontNormalSmall", theme.colors.primary);
    candidateTitle.SetPoint("TOPLEFT", optionsModal.content, "TOPLEFT", 0, 0);
    const compositionOptionsTitle = Native.createText(optionsModal.content, "COMPOSITION", "GameFontNormalSmall", theme.colors.primary);
    compositionOptionsTitle.SetPoint("TOPLEFT", optionsModal.content, "TOPLEFT", 0, -136);
    const activityOptionsTitle = Native.createText(optionsModal.content, "ACTIVITY", "GameFontNormalSmall", theme.colors.primary);
    activityOptionsTitle.SetPoint("TOPLEFT", optionsModal.content, "TOPLEFT", 0, -376);
    const eligibilityTitle = Native.createText(optionsModal.content, "ELIGIBILITY", "GameFontNormalSmall", theme.colors.primary);
    eligibilityTitle.SetPoint("TOPLEFT", optionsModal.content, "TOPLEFT", 0, -462);

    const optionY = [-24, -76, -160, -212, -264, -316, -400];
    for (let i = 0; i < optionDefs.length; i += 1) {
        const def = optionDefs[i];
        const row = CreateFrame("Frame", undefined, optionsModal.content);
        row.SetPoint("TOPLEFT", optionsModal.content, "TOPLEFT", 0, optionY[i]);
        row.SetPoint("TOPRIGHT", optionsModal.content, "TOPRIGHT", 0, optionY[i]);
        row.SetHeight(48);

        const toggle = ToggleUI.createToggle(
            row,
            def.label,
            () => Model.config().options?.[def.key] === true,
            (value) => {
                Model.config().options[def.key] = value;
                Model.touch("Composition option changed");
            },
        );
        toggle.frame.SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2);
        toggle.frame.SetWidth(720);

        const hint = Native.createText(row, def.hint, "GameFontHighlightSmall", theme.colors.muted);
        hint.SetPoint("TOPLEFT", row, "TOPLEFT", 32, -27);
        hint.SetWidth(700);
        hint.SetJustifyV("TOP");

        const divider = Native.createSolid(row, theme.colors.border, "ARTWORK");
        divider.SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0);
        divider.SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0);
        divider.SetHeight(1);
        optionToggles.push(toggle);
    }

    const gearRow = CreateFrame("Frame", undefined, optionsModal.content);
    gearRow.SetPoint("TOPLEFT", optionsModal.content, "TOPLEFT", 0, -486);
    gearRow.SetPoint("TOPRIGHT", optionsModal.content, "TOPRIGHT", 0, -486);
    gearRow.SetHeight(66);
    const gearDivider = Native.createSolid(gearRow, theme.colors.border, "ARTWORK");
    gearDivider.SetPoint("TOPLEFT", gearRow, "TOPLEFT", 0, 0);
    gearDivider.SetPoint("TOPRIGHT", gearRow, "TOPRIGHT", 0, 0);
    gearDivider.SetHeight(1);

    const gearIcon = Native.createFramedIcon(gearRow, "Interface\\Icons\\INV_Chest_Plate04", 34, theme.colors.primary);
    gearIcon.frame.SetPoint("LEFT", gearRow, "LEFT", 0, -4);
    const gearTitle = Native.createText(gearRow, "Minimum item level", "GameFontNormal");
    gearTitle.SetPoint("TOPLEFT", gearRow, "TOPLEFT", 46, -12);
    const gearHint = Native.createText(gearRow, "0 disables the floor. Persistent guild/world candidates below this value are rejected.", "GameFontHighlightSmall", theme.colors.muted);
    gearHint.SetPoint("TOPLEFT", gearRow, "TOPLEFT", 46, -35);
    gearHint.SetWidth(520);

    const gearStepper = StepperUI.createNumberStepper(
        gearRow,
        0,
        300,
        Number(Model.config().options?.minimumItemLevel ?? 0),
        (value) => Model.setMinimumItemLevel(value),
    );
    gearStepper.frame.SetPoint("RIGHT", gearRow, "RIGHT", 0, -4);

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
        height: 38,
        accent: theme.colors.success,
        emphasis: true,
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

        confirmModal.setHeaderIcon(Model.selectedActivityIcon());

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
        activityBadge.icon.SetTexture(Model.selectedActivityIcon());
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
            humanBadge.frame.Hide();
            for (const role of roleOrder) humanRoleButtons[role].setEnabled(false);
            return;
        }

        humanBadge.frame.Show();
        Native.setClassIcon(humanIcon, String(primary.class));
        humanBadge.outline.setColor(Native.classColor(String(primary.class)));
        humanName.SetText((primary.isPlayer ? "YOU  ·  " : "") + primary.name);
        humanSub.SetText(
            "Level " + String(primary.level ?? "?") + " " + Model.classLabel(String(primary.class)) +
            (list.length > 1 ? "  ·  +" + String(list.length - 1) + " more human anchor" + (list.length > 2 ? "s" : "") : "")
        );

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
            Native.setRoleIcon(widgets.roleIcon, slot.role);
            widgets.roleText.SetText(Model.roleLabel(slot.role));
            widgets.roleText.SetTextColor(accent[0], accent[1], accent[2], 1);
            widgets.slotText.SetText(slot.human !== undefined ? "Human anchor" : "Bot slot " + String(slot.botIndex ?? 1));

            if (slot.human !== undefined) {
                Native.setClassIcon(widgets.classIcon, String(slot.human.class));
                widgets.classBadge.frame.Show();
                widgets.classBadge.outline.setColor(Native.classColor(String(slot.human.class)));
                widgets.specBadge.frame.Hide();
                widgets.name.SetText((slot.human.isPlayer ? "YOU  ·  " : "") + slot.human.name);
                widgets.sub.SetText(
                    "Level " + String(slot.human.level ?? "?") + " " + Model.classLabel(String(slot.human.class))
                );
                widgets.choose.frame.Hide();
                widgets.auto.frame.Hide();
                widgets.humanAnchor.frame.Show();
                continue;
            }

            const exact = slot.exact;
            const prepared = slot.prepared;
            if (prepared !== undefined && Model.plan().ready === true) {
                Native.setClassIcon(widgets.classIcon, String(prepared.class));
                widgets.classBadge.frame.Show();
                widgets.classBadge.outline.setColor(Native.classColor(String(prepared.class)));
                const specId = specIdFromLabel(String(prepared.class), String(prepared.spec));
                if (specId !== undefined) {
                    widgets.specIcon.SetTexture(Model.getSpecIcon(prepared.class as ClassId, specId));
                    widgets.specIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
                    widgets.specBadge.frame.Show();
                } else widgets.specBadge.frame.Hide();

                widgets.name.SetText(String(prepared.name));
                widgets.sub.SetText(
                    "Lv " + String(prepared.level ?? "?") + "  ·  " +
                    String(prepared.spec || Model.classLabel(String(prepared.class))) + "  ·  " + String(prepared.source ?? "Bot")
                );
            } else if (exact !== undefined) {
                Native.setClassIcon(widgets.classIcon, exact.classId);
                widgets.classBadge.frame.Show();
                widgets.classBadge.outline.setColor(Native.classColor(exact.classId));
                widgets.specIcon.SetTexture(Model.getSpecIcon(exact.classId, exact.specId));
                widgets.specIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
                widgets.specBadge.frame.Show();
                widgets.name.SetText(Model.getSpecLabel(exact.classId, exact.specId) + " " + Model.classLabel(exact.classId));
                widgets.sub.SetText("Exact build  ·  Composer will preserve this requirement");
            } else {
                widgets.classBadge.frame.Hide();
                widgets.specBadge.frame.Hide();
                widgets.name.SetText("Auto-fill bot");
                widgets.sub.SetText("Composer chooses a suitable " + Model.roleLabel(slot.role).toLowerCase() + " build");
            }

            const roleCopy = slot.role;
            const botIndex = slot.botIndex ?? 1;
            widgets.humanAnchor.frame.Hide();
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
            if (exact !== undefined) widgets.auto.frame.Show();
            else widgets.auto.frame.Hide();
        }
    }

    function refreshQuickRaid(): void {
        const size = Number(Model.config().size ?? 25);
        const total = Model.roleTargetTotal();
        for (const role of roleOrder) {
            const target = Model.targetForRole(role);
            quickCards[role].count.SetText(String(target));
            quickCards[role].botSlots.SetText(
                String(Model.remainingBotSlots(role)) + " bot slots after humans\n(out of " + String(target) + ")"
            );
            quickCards[role].minus.setEnabled(target > 0);
            quickCards[role].plus.setEnabled(target < size);
        }

        quickTotal.SetText(String(total) + " / " + String(size));
        const valid = total === size;
        const color = valid ? theme.colors.success : theme.colors.warning;
        quickTotal.SetTextColor(color[0], color[1], color[2], 1);
        quickSummary.outline.setColor(valid ? theme.colors.borderStrong : theme.colors.warning);
        quickCheck.outline.setColor(color);
        if (valid) {
            quickCheckIcon.Show();
            quickCheckBang.Hide();
            quickStatusTitle.SetText("Raid composition is complete!");
            quickStatusTitle.SetTextColor(theme.colors.success[0], theme.colors.success[1], theme.colors.success[2], 1);
            quickStatusDetail.SetText(
                "This setup will create a " + String(size) + "-player raid with " +
                String(Model.targetForRole("TANK")) + " tanks, " +
                String(Model.targetForRole("HEALER")) + " healers, and " +
                String(Model.targetForRole("DPS")) + " DPS."
            );
        } else {
            quickCheckIcon.Hide();
            quickCheckBang.Show();
            quickStatusTitle.SetText("Role counts need attention");
            quickStatusTitle.SetTextColor(theme.colors.warning[0], theme.colors.warning[1], theme.colors.warning[2], 1);
            quickStatusDetail.SetText("Adjust Tank, Healer and DPS until the total matches " + String(size) + ".");
        }
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

            // WoW frames are not clipped to parent bounds. Reconcile every pooled row explicitly
            // so deleting an aggregated exact build can never leave a ghost painted below the section.
            for (const key of section.rowKeys as string[]) {
                const pooled = section.rowsByKey[key];
                if (pooled !== undefined) {
                    pooled.panel.frame.Hide();
                    pooled.panel.frame.ClearAllPoints();
                }
            }

            const sectionHeight = rows.length === 0 ? 88 : 66 + rows.length * 58;
            section.panel.frame.ClearAllPoints();
            section.panel.frame.SetPoint("TOPLEFT", exactScroll.content, "TOPLEFT", 0, -cursor);
            section.panel.frame.SetSize(906, sectionHeight);

            if (rows.length === 0) section.empty.Show();
            else section.empty.Hide();

            for (let i = 0; i < rows.length; i += 1) {
                const build = rows[i];
                const rowKey = role + ":" + String(build.classId) + ":" + String(build.specId);
                let widgets = section.rowsByKey[rowKey];
                if (widgets === undefined) {
                    const panel = Native.createPanel(section.panel.frame, theme.colors.surfaceRaised, theme.colors.border);
                    panel.frame.SetSize(870, 52);

                    const classBadge = Native.createFramedIcon(panel.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 34, theme.colors.borderStrong);
                    classBadge.frame.SetPoint("LEFT", panel.frame, "LEFT", 10, 0);
                    const classIcon = classBadge.icon;

                    const specBadge = Native.createFramedIcon(panel.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 34, theme.colors.borderStrong);
                    specBadge.frame.SetPoint("LEFT", classBadge.frame, "RIGHT", 6, 0);
                    const specIcon = specBadge.icon;

                    const name = Native.createText(panel.frame, "", "GameFontNormal");
                    name.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 94, -8);
                    name.SetWidth(500);
                    const info = Native.createText(panel.frame, Model.roleLabel(role) + "  ·  Reserved build", "GameFontHighlightSmall", theme.colors.muted);
                    info.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 94, -29);
                    info.SetWidth(440);

                    const countPill = Native.createPanel(panel.frame, theme.colors.surfaceDeep, Model.roleAccent(role));
                    countPill.frame.SetSize(52, 26);
                    countPill.frame.SetPoint("RIGHT", panel.frame, "RIGHT", -120, 0);
                    const count = Native.createText(countPill.frame, "", "GameFontHighlightSmall", Model.roleAccent(role));
                    count.SetPoint("CENTER", countPill.frame, "CENTER", 0, 0);
                    count.SetWidth(46);
                    count.SetJustifyH("CENTER");

                    const edit = ButtonUI.createButton(panel.frame, { text: "Edit", width: 62, height: 28, accent: theme.colors.primary });
                    edit.frame.SetPoint("RIGHT", panel.frame, "RIGHT", -48, 0);

                    const remove = ButtonUI.createButton(panel.frame, { text: "X", width: 34, height: 28, accent: theme.colors.error });
                    remove.frame.SetPoint("RIGHT", panel.frame, "RIGHT", -8, 0);

                    exactScroll.bindWheel(panel.frame);
                    exactScroll.bindWheel(edit.frame);
                    exactScroll.bindWheel(remove.frame);
                    widgets = { panel, classBadge, classIcon, specBadge, specIcon, name, info, countPill, count, edit, remove };
                    section.rowsByKey[rowKey] = widgets;
                    (section.rowKeys as string[]).push(rowKey);
                }

                widgets.panel.frame.ClearAllPoints();
                widgets.panel.frame.SetPoint("TOPLEFT", section.panel.frame, "TOPLEFT", 18, -(58 + i * 58));
                Native.setClassIcon(widgets.classIcon, build.classId);
                widgets.classBadge.outline.setColor(Native.classColor(build.classId));
                widgets.specBadge.outline.setColor(theme.colors.primary);
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
                widgets.remove.frame.SetScript("OnMouseDown", () => {
                    widgets.panel.frame.Hide();
                    widgets.panel.frame.ClearAllPoints();
                    Model.removeRequiredBuild(roleCopy, indexCopy);
                });
                widgets.panel.frame.Show();
            }

            cursor += sectionHeight + 12;
        }

        exactScroll.setContentHeight(Math.max(418, cursor));
    }

    function refreshRoster(): void {
        const cfg = Model.config();
        const totalGroups = Math.max(1, Math.ceil(Number(cfg.size ?? 5) / 5));
        const columns = totalGroups <= 3 ? totalGroups : (totalGroups <= 5 ? 3 : 4);
        const cardWidth = Math.floor((934 - (columns - 1) * 10) / columns);
        const cardHeight = 214;

        for (let g = 0; g < groupCards.length; g += 1) {
            const widgets = groupCards[g];
            if (g >= totalGroups) {
                widgets.card.frame.Hide();
                continue;
            }

            const column = g % columns;
            const row = Math.floor(g / columns);
            widgets.card.frame.ClearAllPoints();
            widgets.card.frame.SetPoint("TOPLEFT", rosterView, "TOPLEFT", column * (cardWidth + 10), -(6 + row * (cardHeight + 10)));
            widgets.card.frame.SetSize(cardWidth, cardHeight);
            widgets.groupTitle.SetText("GROUP " + String(g + 1));

            const members: any[] = [];
            for (const member of Model.planMembers()) if (Number(member.subgroup) === g + 1) members.push(member);
            widgets.groupCount.SetText(String(members.length) + " / 5");
            widgets.groupCount.SetTextColor(
                members.length === 5 ? theme.colors.success[0] : theme.colors.primary[0],
                members.length === 5 ? theme.colors.success[1] : theme.colors.primary[1],
                members.length === 5 ? theme.colors.success[2] : theme.colors.primary[2],
                1
            );

            for (let r = 0; r < 5; r += 1) {
                const rowWidgets = widgets.rows[r];
                const member = members[r];
                const textWidth = Math.max(82, cardWidth - 80);
                rowWidgets.name.SetWidth(textWidth);
                rowWidgets.spec.SetWidth(textWidth);

                if (member === undefined) {
                    rowWidgets.iconBadge.frame.Hide();
                    rowWidgets.roleIcon.Hide();
                    rowWidgets.name.SetText("Empty slot");
                    rowWidgets.name.SetTextColor(theme.colors.muted[0], theme.colors.muted[1], theme.colors.muted[2], 0.72);
                    rowWidgets.spec.SetText("");
                    Native.setTextureColor(rowWidgets.roleBar, theme.colors.borderStrong);
                    Native.setTextureColor(rowWidgets.rowBg, Native.withAlpha(theme.colors.surfaceRaised, 0.32));
                } else {
                    const role = member.role as Role;
                    const accent = Model.roleAccent(role);
                    Native.setClassIcon(rowWidgets.icon, String(member.class));
                    rowWidgets.iconBadge.outline.setColor(Native.classColor(String(member.class)));
                    rowWidgets.iconBadge.frame.Show();
                    Native.setRoleIcon(rowWidgets.roleIcon, role);
                    rowWidgets.roleIcon.Show();

                    const identity = member.isPlayer ? "YOU  ·  " : (member.pinned ? "PINNED  ·  " : "");
                    rowWidgets.name.SetText(identity + String(member.name));
                    rowWidgets.name.SetTextColor(theme.colors.text[0], theme.colors.text[1], theme.colors.text[2], 1);

                    const source = member.isPlayer
                        ? "Human"
                        : (member.pinned ? "Pinned" : (String(member.source ?? "") !== "" ? String(member.source) : "Prepared bot"));
                    rowWidgets.spec.SetText(String(member.spec ?? Model.classLabel(String(member.class))) + "  ·  " + source);
                    rowWidgets.spec.SetTextColor(theme.colors.muted[0], theme.colors.muted[1], theme.colors.muted[2], 1);
                    Native.setTextureColor(rowWidgets.roleBar, accent);
                    Native.setTextureColor(rowWidgets.rowBg, Native.withAlpha(accent, member.isPlayer ? 0.10 : 0.045));
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
        Native.setTextureColor(phaseAccent, phaseColor);
        Native.setTextureColor(phaseGlow, Native.withAlpha(phaseColor, 0.16));
        phaseCard.outline.setColor(phase === "ERROR" ? theme.colors.error : theme.colors.borderStrong);
        phaseText.SetText(Model.isTravelRetry() ? "Ready to enter activity" : Model.phaseLabel(phase));
        phaseText.SetTextColor(phaseColor[0], phaseColor[1], phaseColor[2], 1);
        if (phase === "IDLE") {
            phaseDetail.SetText(
                Model.config().mode === "RAID"
                    ? "Add specific builds or keep Auto to prepare your raid."
                    : "Choose exact builds or keep Auto to prepare your group."
            );
        } else if (Model.isTravelRetry() && statusNotice !== "") {
            phaseDetail.SetText(statusNotice);
        } else phaseDetail.SetText(String(p.detail ?? ""));

        const humanCount = Model.humans().length;
        const target = Number(Model.config().size ?? 5);
        const composed = Model.config().mode === "RAID" ? Model.roleTargetTotal() : humanCount;
        const total = Model.plan().ready === true
            ? Number(Model.plan().summary?.total ?? Model.planMembers().length)
            : composed;
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

        statusRoleChips.TANK.label.SetText(String(Model.config().tanks ?? 0) + " TANK");
        statusRoleChips.HEALER.label.SetText(String(Model.config().healers ?? 0) + " HEALER");
        statusRoleChips.DPS.label.SetText(String(Model.config().dps ?? 0) + " DPS");

        let ratio = 0;
        if (Number(p.total ?? 0) > 0) ratio = Math.min(1, Number(p.current ?? 0) / Number(p.total));
        else if (phase === "READY" || phase === "DONE") ratio = 1;
        else if (phase === "IDLE" && target > 0) ratio = Math.min(1, total / target);
        progressFill.SetWidth(Math.max(1, 266 * ratio));
        Native.setTextureColor(progressFill, phaseColor);
        progressText.SetText(
            phase === "PREPARING" || phase === "ASSEMBLING" || phase === "READY" || phase === "DONE"
                ? String(p.current ?? 0) + " / " + String(p.total ?? 0) + "  ·  " + String(p.detail ?? "")
                : ""
        );

        const utilityRaw = String(Model.plan().summary?.utility ?? "");
        const hasPreparedCoverage = Model.plan().summary?.utility !== undefined;
        for (let i = 0; i < coverageChips.length; i += 1) {
            const widgets = coverageChips[i];
            const covered = hasPreparedCoverage && utilityRaw.indexOf(String(widgets.token)) >= 0;
            widgets.panel.setBackground(covered ? theme.colors.surfaceBlue : theme.colors.surfaceDeep);
            widgets.panel.outline.setColor(covered ? theme.colors.success : theme.colors.border);
            if (covered) widgets.check.Show();
            else widgets.check.Hide();
            widgets.label.SetTextColor(
                covered ? theme.colors.text[0] : theme.colors.muted[0],
                covered ? theme.colors.text[1] : theme.colors.muted[1],
                covered ? theme.colors.text[2] : theme.colors.muted[2],
                covered ? 1 : 0.82
            );
        }
        coverageDamageText.SetText(
            hasPreparedCoverage
                ? "Ranged DPS  " + String(Model.plan().summary?.ranged ?? 0) + "   ·   Melee DPS  " + String(Model.plan().summary?.melee ?? 0)
                : "Prepare a roster to inspect utility."
        );

        const warnings = Model.planWarnings();
        let nextText = "";
        if (phase === "ERROR") {
            nextText = "Adjust the highlighted requirement, then Build & Prepare again.";
        } else if (!Model.humanReady()) {
            nextText = "Choose a legal role for every real player.";
        } else if (Model.config().mode === "RAID" && Model.roleTargetTotal() !== Number(Model.config().size ?? 25)) {
            nextText = "Role counts must total " + String(Model.config().size ?? 25) + " before preparing.";
        } else if (phase === "READY") {
            nextText = Model.isTravelRetry()
                ? "Clear the travel blocker, then enter the activity."
                : "Prepared roster is ready for review. Assemble when it looks right.";
        } else if (phase === "PREPARING") {
            nextText = "Composer is provisioning and validating the selected bots.";
        } else {
            nextText = "Build & Prepare when the composition looks right.";
        }
        if (warnings.length > 0) nextText += "\n" + String(warnings[0]);
        if (phase === "IDLE" && statusNotice !== "") nextText += "\n" + statusNotice;
        nextDetail.SetText(nextText);

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
        if (GC.backendSeen === true) backendGlow.Show();
        else backendGlow.Hide();

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

    GC.RegisterCallback("CONFIG_CHANGED", () => { statusNotice = ""; refresh(); });
    GC.RegisterCallback("PLAN_CHANGED", () => {
        statusNotice = "";
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
        statusNotice = String(text ?? "");
        refresh();
    });
    GC.RegisterCallback("DISPLAY_CHANGED", () => applyScale());

    return dashboard;
}

import { classColor, createFramedIcon, createFramedRoleIcon, createIcon, createPanel, createSolid, createText, setClassIcon, setRoleIcon } from "../core/Native";
import { ClassDefinition, ClassId, getClass, getClassesForRole, getSpecsForRole, Role, SpecDefinition } from "../data/WotlkBuilds";
import { ANY_SPEC_ID } from "../model/ComposerModel";
import { theme } from "../theme/Theme";
import { createButton, UIButton } from "../widgets/Button";
import { createModal } from "../widgets/Modal";
import { createNumberStepper } from "../widgets/Stepper";

export interface BuildSelection { role: Role; classId: ClassId; specId: number; count: number; }
export interface BuildSelectorOptions { allowCount?: boolean; maxCount?: number; onApply(selection: BuildSelection): void; }
export interface BuildSelector { readonly frame: WoWFrame; open(role: Role, initial?: Partial<BuildSelection>, showCount?: boolean): void; close(): void; }
interface ClassTile { readonly classDef: ClassDefinition; readonly button: UIButton; readonly icon: WoWTexture; readonly sub: WoWFontString; readonly specs: WoWFontString; }
interface SpecTile { readonly classId: ClassId; readonly classLabel: string; readonly spec: SpecDefinition; readonly button: UIButton; readonly icon: WoWTexture; readonly sub: WoWFontString; readonly marker: WoWTexture; }

function roleLabel(role: Role): string { if (role === "TANK") return "Tank"; if (role === "HEALER") return "Healer"; return "DPS"; }
function roleAccent(role: Role) { if (role === "TANK") return theme.colors.tank; if (role === "HEALER") return theme.colors.healer; return theme.colors.dps; }
function specSummary(classId: ClassId, role: Role): string {
    const labels: string[] = [];
    for (const spec of getSpecsForRole(classId, role)) labels.push(spec.label);
    return labels.join("  ·  ");
}
function classRoleSummary(classId: ClassId, role: Role): string {
    if (role === "TANK") return "Tank";
    if (role === "HEALER") return "Healer";
    if (classId === "HUNTER" || classId === "MAGE" || classId === "WARLOCK" || classId === "PRIEST") return "Ranged DPS";
    if (classId === "SHAMAN" || classId === "DRUID") return "Melee / Ranged";
    return "Melee DPS";
}
const SELECTOR_CLASS_ORDER: readonly ClassId[] = ["DEATHKNIGHT", "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "SHAMAN", "MAGE", "WARLOCK", "DRUID", "PRIEST"];
function selectorClassesForRole(role: Role, compatible?: ClassDefinition[]): ClassDefinition[] {
    const valid = compatible ?? getClassesForRole(role);
    const result: ClassDefinition[] = [];
    for (const classId of SELECTOR_CLASS_ORDER) for (const classDef of valid) if (classDef.id === classId) { result.push(classDef); break; }
    return result;
}
function createRadioMarker(parent: WoWFrame): WoWTexture {
    const marker = parent.CreateTexture(undefined, "OVERLAY");
    marker.SetTexture("Interface\\Buttons\\UI-CheckBox-Check");
    marker.SetSize(22, 22);
    marker.SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 7);
    marker.SetVertexColor(theme.colors.primary[0], theme.colors.primary[1], theme.colors.primary[2], 1);
    marker.Hide();
    return marker;
}
function setRadioSelected(marker: WoWTexture, selected: boolean): void { if (selected) marker.Show(); else marker.Hide(); }

export function createBuildSelector(parent: WoWFrame, options: BuildSelectorOptions): BuildSelector {
    const modal = createModal(parent, 1040, 680);
    let currentRole: Role = "DPS";
    let currentClass: ClassId | undefined;
    let currentSpec: number | undefined;
    let countEnabled = options.allowCount === true;

    const classSection = createPanel(modal.content, theme.colors.surface, theme.colors.border);
    classSection.frame.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 0, 0);
    classSection.frame.SetPoint("TOPRIGHT", modal.content, "TOPRIGHT", 0, 0);
    classSection.frame.SetHeight(258);
    const classStep = createText(classSection.frame, "01", "GameFontNormalLarge", theme.colors.primary);
    classStep.SetPoint("TOPLEFT", classSection.frame, "TOPLEFT", 14, -14);
    const classTitle = createText(classSection.frame, "Choose a class", "GameFontNormalLarge");
    classTitle.SetPoint("TOPLEFT", classSection.frame, "TOPLEFT", 52, -12);
    const classHint = createText(classSection.frame, "Select a class that can fulfill this role.", "GameFontHighlightSmall", theme.colors.muted);
    classHint.SetPoint("TOPLEFT", classTitle, "BOTTOMLEFT", 0, -3);

    const classTiles: ClassTile[] = [];
    for (const classDef of selectorClassesForRole("DPS")) {
        const button = createButton(classSection.frame, { text: classDef.label, width: 174, height: 86, accent: classColor(classDef.id) });
        const accent = createSolid(button.frame, classColor(classDef.id), "ARTWORK");
        accent.SetHeight(3); accent.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 0, 0); accent.SetPoint("TOPRIGHT", button.frame, "TOPRIGHT", 0, 0);
        const iconFrame = createFramedIcon(button.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 42, classColor(classDef.id));
        iconFrame.frame.SetPoint("LEFT", button.frame, "LEFT", 10, 0);
        const icon = iconFrame.icon; setClassIcon(icon, classDef.id);
        button.label.ClearAllPoints(); button.label.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 62, -15); button.label.SetPoint("RIGHT", button.frame, "RIGHT", -8, 10); button.label.SetJustifyH("LEFT");
        const sub = createText(button.frame, "", "GameFontHighlightSmall", theme.colors.muted); sub.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 62, -36); sub.SetWidth(104);
        const specs = createText(button.frame, "", "GameFontHighlightSmall", theme.colors.muted); specs.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 62, -54); specs.SetWidth(104);
        button.frame.SetScript("OnMouseDown", () => { if (currentClass !== classDef.id) currentSpec = undefined; currentClass = classDef.id; refresh(); });
        classTiles.push({ classDef, button, icon, sub, specs });
    }

    const specSection = createPanel(modal.content, theme.colors.surface, theme.colors.border);
    specSection.frame.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 0, -270);
    specSection.frame.SetPoint("TOPRIGHT", modal.content, "TOPRIGHT", 0, -270);
    specSection.frame.SetHeight(176);
    const specStep = createText(specSection.frame, "02", "GameFontNormalLarge", theme.colors.primary); specStep.SetPoint("TOPLEFT", specSection.frame, "TOPLEFT", 14, -14);
    const specTitle = createText(specSection.frame, "Choose a specialization", "GameFontNormalLarge"); specTitle.SetPoint("TOPLEFT", specSection.frame, "TOPLEFT", 52, -12);
    const specHint = createText(specSection.frame, "Pick a class first.", "GameFontHighlightSmall", theme.colors.muted); specHint.SetPoint("TOPLEFT", specTitle, "BOTTOMLEFT", 0, -3);
    const emptySpec = createText(specSection.frame, "Choose a class above and its valid specializations will appear here.", "GameFontHighlight", theme.colors.muted);
    emptySpec.SetPoint("CENTER", specSection.frame, "CENTER", 0, -22); emptySpec.SetWidth(620); emptySpec.SetJustifyH("CENTER");

    const anySpecButton = createButton(specSection.frame, { text: "Any valid spec", width: 208, height: 76, accent: theme.colors.primary, onClick: () => { if (currentClass === undefined) return; currentSpec = ANY_SPEC_ID; refresh(); } });
    const anySpecIcon = createIcon(anySpecButton.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 40); anySpecIcon.SetPoint("LEFT", anySpecButton.frame, "LEFT", 10, 0);
    anySpecButton.label.ClearAllPoints(); anySpecButton.label.SetPoint("TOPLEFT", anySpecButton.frame, "TOPLEFT", 60, -17); anySpecButton.label.SetPoint("RIGHT", anySpecButton.frame, "RIGHT", -8, 8); anySpecButton.label.SetJustifyH("LEFT");
    const anySpecSub = createText(anySpecButton.frame, "Composer chooses", "GameFontHighlightSmall", theme.colors.muted); anySpecSub.SetPoint("TOPLEFT", anySpecButton.frame, "TOPLEFT", 60, -40); anySpecSub.SetWidth(130);
    const anySpecMarker = createRadioMarker(anySpecButton.frame); anySpecButton.frame.Hide();

    const specTiles: SpecTile[] = [];
    for (const classDef of selectorClassesForRole("DPS")) {
        for (const spec of classDef.specs) {
            const button = createButton(specSection.frame, { text: spec.label, width: 208, height: 76, accent: theme.colors.primary });
            const icon = createIcon(button.frame, spec.icon, 40); icon.SetPoint("LEFT", button.frame, "LEFT", 10, 0);
            button.label.ClearAllPoints(); button.label.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 60, -17); button.label.SetPoint("RIGHT", button.frame, "RIGHT", -8, 8); button.label.SetJustifyH("LEFT");
            const sub = createText(button.frame, classDef.label, "GameFontHighlightSmall", theme.colors.muted); sub.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 60, -40); sub.SetWidth(130);
            const marker = createRadioMarker(button.frame);
            button.frame.SetScript("OnMouseDown", () => { currentClass = classDef.id; currentSpec = spec.id; refresh(); });
            button.frame.Hide();
            specTiles.push({ classId: classDef.id, classLabel: classDef.label, spec, button, icon, sub, marker });
        }
    }

    const summary = createPanel(modal.content, theme.colors.surfaceRaised, theme.colors.borderStrong);
    summary.frame.SetPoint("BOTTOMLEFT", modal.content, "BOTTOMLEFT", 0, 0); summary.frame.SetPoint("BOTTOMRIGHT", modal.content, "BOTTOMRIGHT", 0, 0); summary.frame.SetHeight(104);
    const selectedLabel = createText(summary.frame, "BUILD SUMMARY", "GameFontNormalSmall", theme.colors.muted); selectedLabel.SetPoint("TOPLEFT", summary.frame, "TOPLEFT", 12, -8);

    const summaryClassBadge = createFramedIcon(summary.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 40, theme.colors.borderStrong); summaryClassBadge.frame.SetPoint("BOTTOMLEFT", summary.frame, "BOTTOMLEFT", 12, 12);
    const summaryClassText = createText(summary.frame, "Choose class", "GameFontNormal"); summaryClassText.SetPoint("TOPLEFT", summary.frame, "TOPLEFT", 62, -43); summaryClassText.SetWidth(108);
    const summaryClassSub = createText(summary.frame, "Class", "GameFontHighlightSmall", theme.colors.muted); summaryClassSub.SetPoint("TOPLEFT", summaryClassText, "BOTTOMLEFT", 0, -3);

    const summarySpecBadge = createFramedIcon(summary.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 40, theme.colors.borderStrong); summarySpecBadge.frame.SetPoint("BOTTOMLEFT", summary.frame, "BOTTOMLEFT", 184, 12);
    const summarySpecText = createText(summary.frame, "Choose spec", "GameFontNormal"); summarySpecText.SetPoint("TOPLEFT", summary.frame, "TOPLEFT", 234, -43); summarySpecText.SetWidth(116);
    const summarySpecSub = createText(summary.frame, "Specialization", "GameFontHighlightSmall", theme.colors.muted); summarySpecSub.SetPoint("TOPLEFT", summarySpecText, "BOTTOMLEFT", 0, -3);

    const summaryRoleBadge = createFramedRoleIcon(summary.frame, "DPS", 40, theme.colors.dps); summaryRoleBadge.frame.SetPoint("BOTTOMLEFT", summary.frame, "BOTTOMLEFT", 370, 12);
    const summaryRoleText = createText(summary.frame, "DPS", "GameFontNormal"); summaryRoleText.SetPoint("TOPLEFT", summary.frame, "TOPLEFT", 420, -43); summaryRoleText.SetWidth(78);
    const summaryRoleSub = createText(summary.frame, "Role", "GameFontHighlightSmall", theme.colors.muted); summaryRoleSub.SetPoint("TOPLEFT", summaryRoleText, "BOTTOMLEFT", 0, -3);

    const countLabel = createText(summary.frame, "COUNT", "GameFontNormalSmall", theme.colors.muted); countLabel.SetPoint("TOPLEFT", summary.frame, "TOPLEFT", 518, -36);
    const countStepper = createNumberStepper(summary.frame, 1, options.maxCount ?? 40, 1); countStepper.frame.SetPoint("LEFT", summary.frame, "LEFT", 566, -8);

    const apply = createButton(summary.frame, { text: "Use this build", width: 176, height: 42, emphasis: true, accent: theme.colors.primary,
        onClick: () => {
            if (currentClass === undefined || currentSpec === undefined) return;
            options.onApply({ role: currentRole, classId: currentClass, specId: currentSpec, count: countEnabled ? countStepper.getValue() : 1 });
            modal.hide();
        },
    });
    apply.frame.SetPoint("BOTTOMRIGHT", summary.frame, "BOTTOMRIGHT", -12, 12);

    function refresh(): void {
        const accent = roleAccent(currentRole);
        modal.setTitle("Add " + roleLabel(currentRole) + " Build");
        modal.setSubtitle("Reserve only the class/spec you care about. Every unreserved slot stays Auto.");
        modal.setHeaderRole(currentRole);
        classSection.outline.setColor(theme.colors.borderStrong); specSection.outline.setColor(theme.colors.borderStrong);
        classStep.SetTextColor(accent[0], accent[1], accent[2], 1); specStep.SetTextColor(accent[0], accent[1], accent[2], 1);
        classHint.SetText("Select a class that can fulfill the " + roleLabel(currentRole) + " role.");
        setRoleIcon(summaryRoleBadge.icon, currentRole); summaryRoleBadge.outline.setColor(accent); summaryRoleText.SetText(roleLabel(currentRole)); summaryRoleText.SetTextColor(accent[0], accent[1], accent[2], 1);

        const validClasses = selectorClassesForRole(currentRole, getClassesForRole(currentRole));
        const columns = Math.min(5, Math.max(1, validClasses.length));
        const tileWidth = 174;
        const gap = 10;
        const totalWidth = columns * tileWidth + (columns - 1) * gap;
        const startX = Math.floor((1008 - totalWidth) / 2);
        let classIndex = 0;
        for (const tile of classTiles) {
            let valid = false;
            for (const classDef of validClasses) if (classDef.id === tile.classDef.id) { valid = true; break; }
            if (!valid) { tile.button.frame.Hide(); continue; }
            const column = classIndex % columns;
            const row = Math.floor(classIndex / columns);
            tile.button.frame.ClearAllPoints();
            tile.button.frame.SetPoint("TOPLEFT", classSection.frame, "TOPLEFT", startX + column * (tileWidth + gap), -(62 + row * 94));
            tile.sub.SetText(classRoleSummary(tile.classDef.id, currentRole));
            tile.specs.SetText(specSummary(tile.classDef.id, currentRole));
            tile.button.setSelected(tile.classDef.id === currentClass);
            tile.button.frame.Show();
            classIndex += 1;
        }

        if (currentClass === undefined) {
            anySpecButton.frame.Hide();
            for (const tile of specTiles) tile.button.frame.Hide();
            specHint.SetText("Pick a class first.");
            emptySpec.Show();
        } else {
            const selectedClass = getClass(currentClass);
            specHint.SetText("Pick an exact " + (selectedClass?.label ?? "class") + " specialization, or leave the spec flexible.");
            emptySpec.Hide();
            const visibleSpecs = getSpecsForRole(currentClass, currentRole);
            const totalCards = visibleSpecs.length + 1;
            const cardWidth = 208;
            const cardGap = 12;
            const cardsWidth = totalCards * cardWidth + (totalCards - 1) * cardGap;
            const specStartX = Math.floor((1008 - cardsWidth) / 2);
            let specIndex = 0;
            for (const tile of specTiles) {
                let visible = false;
                if (tile.classId === currentClass) for (const validSpec of visibleSpecs) if (validSpec.id === tile.spec.id) { visible = true; break; }
                if (visible) {
                    tile.button.frame.ClearAllPoints();
                    tile.button.frame.SetPoint("TOPLEFT", specSection.frame, "TOPLEFT", specStartX + specIndex * (cardWidth + cardGap), -70);
                    tile.sub.SetText(tile.classLabel);
                    const selected = tile.spec.id === currentSpec;
                    tile.button.setSelected(selected); setRadioSelected(tile.marker, selected); tile.button.frame.Show(); specIndex += 1;
                } else tile.button.frame.Hide();
            }
            anySpecButton.frame.ClearAllPoints();
            anySpecButton.frame.SetPoint("TOPLEFT", specSection.frame, "TOPLEFT", specStartX + specIndex * (cardWidth + cardGap), -70);
            const anySelected = currentSpec === ANY_SPEC_ID;
            anySpecButton.setSelected(anySelected); setRadioSelected(anySpecMarker, anySelected); anySpecButton.frame.Show();
        }

        const selectedClass = currentClass === undefined ? undefined : getClass(currentClass);
        let selectedSpec: SpecDefinition | undefined;
        if (currentClass !== undefined && currentSpec !== undefined && currentSpec !== ANY_SPEC_ID) {
            for (const spec of getSpecsForRole(currentClass, currentRole)) if (spec.id === currentSpec) { selectedSpec = spec; break; }
        }

        if (selectedClass !== undefined) {
            setClassIcon(summaryClassBadge.icon, selectedClass.id); summaryClassBadge.outline.setColor(classColor(selectedClass.id)); summaryClassText.SetText(selectedClass.label);
        } else {
            summaryClassBadge.icon.SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); summaryClassBadge.icon.SetTexCoord(0.08, 0.92, 0.08, 0.92); summaryClassBadge.outline.setColor(theme.colors.borderStrong); summaryClassText.SetText("Choose class");
        }

        if (selectedClass !== undefined && currentSpec === ANY_SPEC_ID) {
            summarySpecBadge.icon.SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); summarySpecBadge.icon.SetTexCoord(0.08, 0.92, 0.08, 0.92); summarySpecBadge.outline.setColor(theme.colors.primary); summarySpecText.SetText("Any valid spec"); apply.setEnabled(true);
        } else if (selectedClass !== undefined && selectedSpec !== undefined) {
            summarySpecBadge.icon.SetTexture(selectedSpec.icon); summarySpecBadge.icon.SetTexCoord(0.08, 0.92, 0.08, 0.92); summarySpecBadge.outline.setColor(theme.colors.primary); summarySpecText.SetText(selectedSpec.label); apply.setEnabled(true);
        } else {
            summarySpecBadge.icon.SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); summarySpecBadge.icon.SetTexCoord(0.08, 0.92, 0.08, 0.92); summarySpecBadge.outline.setColor(theme.colors.borderStrong); summarySpecText.SetText("Choose spec"); apply.setEnabled(false);
        }
    }

    return {
        frame: modal.frame,
        open(role: Role, initial?: Partial<BuildSelection>, showCount = true): void {
            currentRole = role; currentClass = initial?.classId; currentSpec = initial?.specId; countEnabled = options.allowCount === true && showCount;
            if (countEnabled) { countLabel.Show(); countStepper.frame.Show(); } else { countLabel.Hide(); countStepper.frame.Hide(); }
            countStepper.setValue(initial?.count ?? 1);
            if (currentClass !== undefined) {
                let validCurrent = false;
                for (const spec of getSpecsForRole(currentClass, currentRole)) if (spec.id === currentSpec) { validCurrent = true; break; }
                if (!validCurrent && currentSpec !== ANY_SPEC_ID) currentSpec = undefined;
            }
            refresh(); modal.show();
        },
        close(): void { modal.hide(); },
    };
}

import { classColor, createFramedIcon, createFramedRoleIcon, createIcon, createPanel, createSolid, createText, setClassIcon, setRoleIcon } from "../core/Native";
import { ClassDefinition, ClassId, getClass, getClassesForRole, getSpecsForRole, Role, SpecDefinition } from "../data/WotlkBuilds";
import { ANY_SPEC_ID } from "../model/ComposerModel";
import { theme } from "../theme/Theme";
import { createButton, UIButton } from "../widgets/Button";
import { createModal } from "../widgets/Modal";
import { createNumberStepper } from "../widgets/Stepper";

export interface BuildSelection {
    role: Role;
    classId: ClassId;
    specId: number;
    count: number;
}

export interface BuildSelectorOptions {
    allowCount?: boolean;
    maxCount?: number;
    onApply(selection: BuildSelection): void;
}

export interface BuildSelector {
    readonly frame: WoWFrame;
    open(role: Role, initial?: Partial<BuildSelection>, showCount?: boolean): void;
    close(): void;
}

interface ClassTile {
    readonly classDef: ClassDefinition;
    readonly button: UIButton;
    readonly icon: WoWTexture;
    readonly sub: WoWFontString;
    readonly specs: WoWFontString;
}

interface SpecTile {
    readonly classId: ClassId;
    readonly classLabel: string;
    readonly spec: SpecDefinition;
    readonly button: UIButton;
    readonly icon: WoWTexture;
    readonly sub: WoWFontString;
    readonly marker: WoWTexture;
}

function roleLabel(role: Role): string {
    if (role === "TANK") return "Tank";
    if (role === "HEALER") return "Healer";
    return "DPS";
}

function roleAccent(role: Role) {
    if (role === "TANK") return theme.colors.tank;
    if (role === "HEALER") return theme.colors.healer;
    return theme.colors.dps;
}

function specSummary(classId: ClassId, role: Role): string {
    const labels: string[] = [];
    for (const spec of getSpecsForRole(classId, role)) labels.push(spec.label);
    return labels.join("  ·  ");
}

function classRoleSummary(classId: ClassId, role: Role): string {
    if (role === "TANK") return "Tank";
    if (role === "HEALER") return "Healer";
    if (classId === "HUNTER" || classId === "MAGE" || classId === "WARLOCK" || classId === "PRIEST") return "Ranged DPS";
    if (classId === "SHAMAN" || classId === "DRUID") return "Melee / Ranged DPS";
    return "Melee DPS";
}

const SELECTOR_CLASS_ORDER: readonly ClassId[] = [
    "DEATHKNIGHT", "WARRIOR", "PALADIN", "HUNTER", "ROGUE",
    "SHAMAN", "MAGE", "WARLOCK", "DRUID", "PRIEST",
];

function selectorClassesForRole(role: Role, compatible?: ClassDefinition[]): ClassDefinition[] {
    const valid = compatible ?? getClassesForRole(role);
    const result: ClassDefinition[] = [];
    for (const classId of SELECTOR_CLASS_ORDER) {
        for (const classDef of valid) {
            if (classDef.id === classId) {
                result.push(classDef);
                break;
            }
        }
    }
    return result;
}

function createRadioMarker(parent: WoWFrame): WoWTexture {
    const marker = parent.CreateTexture(undefined, "OVERLAY");
    marker.SetTexture("Interface\\Buttons\\UI-RadioButton");
    marker.SetSize(22, 22);
    marker.SetPoint("BOTTOM", parent, "BOTTOM", 0, 8);
    return marker;
}

function setRadioSelected(marker: WoWTexture, selected: boolean): void {
    marker.SetTexCoord(selected ? 0.25 : 0, selected ? 0.5 : 0.25, 0, 1);
    if (selected) marker.SetVertexColor(theme.colors.primary[0], theme.colors.primary[1], theme.colors.primary[2], 1);
    else marker.SetVertexColor(theme.colors.muted[0], theme.colors.muted[1], theme.colors.muted[2], 0.9);
}

export function createBuildSelector(parent: WoWFrame, options: BuildSelectorOptions): BuildSelector {
    const modal = createModal(parent, 1080, 790);

    let currentRole: Role = "DPS";
    let currentClass: ClassId | undefined;
    let currentSpec: number | undefined;
    let countEnabled = options.allowCount === true;

    // Step 1: class ----------------------------------------------------------
    const classSection = createPanel(modal.content, theme.colors.surface, theme.colors.border);
    classSection.frame.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 0, 0);
    classSection.frame.SetPoint("TOPRIGHT", modal.content, "TOPRIGHT", 0, 0);
    classSection.frame.SetHeight(326);

    const classStep = createPanel(classSection.frame, theme.colors.surfaceRaised, theme.colors.borderStrong);
    classStep.frame.SetSize(34, 34);
    classStep.frame.SetPoint("TOPLEFT", classSection.frame, "TOPLEFT", 14, -14);
    const classStepGlow = classStep.frame.CreateTexture(undefined, "OVERLAY");
    classStepGlow.SetTexture("Interface\\Buttons\\UI-ActionButton-Border");
    classStepGlow.SetSize(54, 54);
    classStepGlow.SetPoint("CENTER", classStep.frame, "CENTER", 0, 0);
    classStepGlow.SetVertexColor(theme.colors.primary[0], theme.colors.primary[1], theme.colors.primary[2], 0.65);
    const classStepText = createText(classStep.frame, "1", "GameFontNormal", theme.colors.primary);
    classStepText.SetPoint("CENTER", classStep.frame, "CENTER", 0, 0);

    const classTitle = createText(classSection.frame, "CHOOSE A CLASS", "GameFontNormalLarge");
    classTitle.SetPoint("TOPLEFT", classSection.frame, "TOPLEFT", 60, -13);
    const classHint = createText(classSection.frame, "Select a class that can fulfill this role.", "GameFontHighlightSmall", theme.colors.muted);
    classHint.SetPoint("TOPLEFT", classTitle, "BOTTOMLEFT", 0, -4);

    const classTiles: ClassTile[] = [];
    for (const classDef of selectorClassesForRole("DPS")) {
        const button = createButton(classSection.frame, {
            text: classDef.label,
            width: 190,
            height: 116,
            accent: theme.colors.primary,
        });
        const accent = createSolid(button.frame, classColor(classDef.id), "ARTWORK");
        accent.SetHeight(3);
        accent.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 0, 0);
        accent.SetPoint("TOPRIGHT", button.frame, "TOPRIGHT", 0, 0);

        const iconFrame = createPanel(button.frame, theme.colors.surfaceDeep, classColor(classDef.id));
        iconFrame.frame.SetSize(46, 46);
        iconFrame.frame.SetPoint("TOP", button.frame, "TOP", 0, -11);
        const icon = iconFrame.frame.CreateTexture(undefined, "ARTWORK");
        icon.SetPoint("TOPLEFT", iconFrame.frame, "TOPLEFT", 3, -3);
        icon.SetPoint("BOTTOMRIGHT", iconFrame.frame, "BOTTOMRIGHT", -3, 3);
        setClassIcon(icon, classDef.id);

        button.label.ClearAllPoints();
        button.label.SetPoint("TOP", button.frame, "TOP", 0, -65);
        button.label.SetWidth(174);
        button.label.SetJustifyH("CENTER");

        const sub = createText(button.frame, "", "GameFontHighlightSmall", theme.colors.muted);
        sub.SetPoint("TOP", button.frame, "TOP", 0, -84);
        sub.SetWidth(174);
        sub.SetJustifyH("CENTER");

        const specs = createText(button.frame, "", "GameFontHighlightSmall", theme.colors.muted);
        specs.SetPoint("TOP", button.frame, "TOP", 0, -101);
        specs.SetWidth(174);
        specs.SetJustifyH("CENTER");

        button.frame.SetScript("OnMouseDown", () => {
            if (currentClass !== classDef.id) currentSpec = undefined;
            currentClass = classDef.id;
            refresh();
        });

        classTiles.push({ classDef, button, icon, sub, specs });
    }

    // Step 2: specialization -------------------------------------------------
    const specSection = createPanel(modal.content, theme.colors.surface, theme.colors.border);
    specSection.frame.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 0, -340);
    specSection.frame.SetPoint("TOPRIGHT", modal.content, "TOPRIGHT", 0, -340);
    specSection.frame.SetHeight(220);

    const specStep = createPanel(specSection.frame, theme.colors.surfaceRaised, theme.colors.borderStrong);
    specStep.frame.SetSize(34, 34);
    specStep.frame.SetPoint("TOPLEFT", specSection.frame, "TOPLEFT", 14, -14);
    const specStepGlow = specStep.frame.CreateTexture(undefined, "OVERLAY");
    specStepGlow.SetTexture("Interface\\Buttons\\UI-ActionButton-Border");
    specStepGlow.SetSize(54, 54);
    specStepGlow.SetPoint("CENTER", specStep.frame, "CENTER", 0, 0);
    specStepGlow.SetVertexColor(theme.colors.primary[0], theme.colors.primary[1], theme.colors.primary[2], 0.65);
    const specStepText = createText(specStep.frame, "2", "GameFontNormal", theme.colors.primary);
    specStepText.SetPoint("CENTER", specStep.frame, "CENTER", 0, 0);

    const specTitle = createText(specSection.frame, "CHOOSE A SPECIALIZATION", "GameFontNormalLarge");
    specTitle.SetPoint("TOPLEFT", specSection.frame, "TOPLEFT", 60, -13);
    const specHint = createText(specSection.frame, "Pick a class first.", "GameFontHighlightSmall", theme.colors.muted);
    specHint.SetPoint("TOPLEFT", specTitle, "BOTTOMLEFT", 0, -4);

    const emptySpec = createText(
        specSection.frame,
        "Select a class above to see the exact specializations that can fill this role.",
        "GameFontHighlight",
        theme.colors.muted,
    );
    emptySpec.SetPoint("CENTER", specSection.frame, "CENTER", 0, -28);
    emptySpec.SetWidth(700);
    emptySpec.SetJustifyH("CENTER");

    const anySpecButton = createButton(specSection.frame, {
        text: "Any valid spec",
        width: 236,
        height: 104,
        accent: theme.colors.primary,
        onClick: () => {
            if (currentClass === undefined) return;
            currentSpec = ANY_SPEC_ID;
            refresh();
        },
    });
    const anySpecIcon = createIcon(anySpecButton.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 46);
    anySpecIcon.SetPoint("LEFT", anySpecButton.frame, "LEFT", 14, 0);
    anySpecButton.label.ClearAllPoints();
    anySpecButton.label.SetPoint("TOPLEFT", anySpecButton.frame, "TOPLEFT", 70, -20);
    anySpecButton.label.SetPoint("RIGHT", anySpecButton.frame, "RIGHT", -10, 10);
    anySpecButton.label.SetJustifyH("LEFT");
    const anySpecSub = createText(anySpecButton.frame, "Let Composer choose for me", "GameFontHighlightSmall", theme.colors.muted);
    anySpecSub.SetPoint("TOPLEFT", anySpecButton.frame, "TOPLEFT", 70, -49);
    anySpecSub.SetWidth(136);
    anySpecSub.SetJustifyV("TOP");
    const anySpecMarker = createRadioMarker(anySpecButton.frame);
    setRadioSelected(anySpecMarker, false);
    anySpecButton.frame.Hide();

    const specTiles: SpecTile[] = [];
    for (const classDef of selectorClassesForRole("DPS")) {
        for (const spec of classDef.specs) {
            const button = createButton(specSection.frame, {
                text: spec.label,
                width: 236,
                height: 104,
                accent: theme.colors.primary,
            });
            const icon = createIcon(button.frame, spec.icon, 46);
            icon.SetPoint("LEFT", button.frame, "LEFT", 14, 0);
            button.label.ClearAllPoints();
            button.label.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 70, -20);
            button.label.SetPoint("RIGHT", button.frame, "RIGHT", -10, 10);
            button.label.SetJustifyH("LEFT");
            const sub = createText(button.frame, classDef.label, "GameFontHighlightSmall", theme.colors.muted);
            sub.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 70, -49);
            sub.SetWidth(136);

            const marker = createRadioMarker(button.frame);
            setRadioSelected(marker, false);

            button.frame.SetScript("OnMouseDown", () => {
                currentClass = classDef.id;
                currentSpec = spec.id;
                refresh();
            });
            button.frame.Hide();
            specTiles.push({ classId: classDef.id, classLabel: classDef.label, spec, button, icon, sub, marker });
        }
    }

    // Selection bar ----------------------------------------------------------
    const summary = createPanel(modal.content, theme.colors.surfaceRaised, theme.colors.borderStrong);
    summary.frame.SetPoint("BOTTOMLEFT", modal.content, "BOTTOMLEFT", 0, 0);
    summary.frame.SetPoint("BOTTOMRIGHT", modal.content, "BOTTOMRIGHT", 0, 0);
    summary.frame.SetHeight(118);

    const selectedLabel = createText(summary.frame, "BUILD SUMMARY", "GameFontNormalSmall", theme.colors.muted);
    selectedLabel.SetPoint("TOPLEFT", summary.frame, "TOPLEFT", 14, -10);

    const summaryClassBadge = createFramedIcon(summary.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 46, theme.colors.borderStrong);
    summaryClassBadge.frame.SetPoint("BOTTOMLEFT", summary.frame, "BOTTOMLEFT", 14, 12);
    const summaryClassText = createText(summary.frame, "Choose class", "GameFontNormal");
    summaryClassText.SetPoint("TOPLEFT", summary.frame, "TOPLEFT", 70, -48);
    summaryClassText.SetWidth(108);
    const summaryClassSub = createText(summary.frame, "Class", "GameFontHighlightSmall", theme.colors.muted);
    summaryClassSub.SetPoint("TOPLEFT", summaryClassText, "BOTTOMLEFT", 0, -4);

    const summarySpecBadge = createFramedIcon(summary.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 46, theme.colors.borderStrong);
    summarySpecBadge.frame.SetPoint("BOTTOMLEFT", summary.frame, "BOTTOMLEFT", 190, 12);
    const summarySpecText = createText(summary.frame, "Choose spec", "GameFontNormal");
    summarySpecText.SetPoint("TOPLEFT", summary.frame, "TOPLEFT", 246, -48);
    summarySpecText.SetWidth(112);
    const summarySpecSub = createText(summary.frame, "Specialization", "GameFontHighlightSmall", theme.colors.muted);
    summarySpecSub.SetPoint("TOPLEFT", summarySpecText, "BOTTOMLEFT", 0, -4);

    const summaryRoleBadge = createFramedRoleIcon(summary.frame, "DPS", 46, theme.colors.dps);
    summaryRoleBadge.frame.SetPoint("BOTTOMLEFT", summary.frame, "BOTTOMLEFT", 372, 12);
    const summaryRoleText = createText(summary.frame, "DPS", "GameFontNormal");
    summaryRoleText.SetPoint("TOPLEFT", summary.frame, "TOPLEFT", 428, -48);
    summaryRoleText.SetWidth(86);
    const summaryRoleSub = createText(summary.frame, "Role", "GameFontHighlightSmall", theme.colors.muted);
    summaryRoleSub.SetPoint("TOPLEFT", summaryRoleText, "BOTTOMLEFT", 0, -4);

    const summaryDivider = createSolid(summary.frame, theme.colors.borderStrong, "ARTWORK");
    summaryDivider.SetPoint("TOPLEFT", summary.frame, "TOPLEFT", 536, -36);
    summaryDivider.SetHeight(62);
    summaryDivider.SetWidth(1);

    const countLabel = createText(summary.frame, "COUNT", "GameFontNormalSmall", theme.colors.muted);
    countLabel.SetPoint("TOPLEFT", summary.frame, "TOPLEFT", 560, -48);
    const countStepper = createNumberStepper(summary.frame, 1, options.maxCount ?? 40, 1);
    countStepper.frame.SetPoint("LEFT", summary.frame, "LEFT", 618, -10);

    const apply = createButton(summary.frame, {
        text: "Use this build",
        width: 184,
        height: 48,
        emphasis: true,
        accent: theme.colors.primary,
        onClick: () => {
            if (currentClass === undefined || currentSpec === undefined) return;
            options.onApply({
                role: currentRole,
                classId: currentClass,
                specId: currentSpec,
                count: countEnabled ? countStepper.getValue() : 1,
            });
            modal.hide();
        },
    });
    apply.frame.SetPoint("BOTTOMRIGHT", summary.frame, "BOTTOMRIGHT", -12, 12);

    function refresh(): void {
        const accent = roleAccent(currentRole);
        modal.setTitle("Add " + roleLabel(currentRole) + " Build");
        modal.setSubtitle("Choose a class and specialization for this " + roleLabel(currentRole) + " build. Unspecified slots stay Auto-filled.");
        modal.setHeaderRole(currentRole);

        classSection.outline.setColor(accent);
        specSection.outline.setColor(accent);
        classStep.outline.setColor(accent);
        specStep.outline.setColor(accent);
        classStepText.SetTextColor(accent[0], accent[1], accent[2], 1);
        specStepText.SetTextColor(accent[0], accent[1], accent[2], 1);
        classStepGlow.SetVertexColor(accent[0], accent[1], accent[2], 0.65);
        specStepGlow.SetVertexColor(accent[0], accent[1], accent[2], 0.65);
        classHint.SetText("Select a class that can fulfill the " + roleLabel(currentRole) + " role.");
        setRoleIcon(summaryRoleBadge.icon, currentRole);
        summaryRoleBadge.outline.setColor(accent);
        summaryRoleText.SetText(roleLabel(currentRole));
        summaryRoleText.SetTextColor(accent[0], accent[1], accent[2], 1);

        const validClasses = selectorClassesForRole(currentRole, getClassesForRole(currentRole));
        let classIndex = 0;
        for (const tile of classTiles) {
            let valid = false;
            for (const classDef of validClasses) {
                if (classDef.id === tile.classDef.id) {
                    valid = true;
                    break;
                }
            }
            if (!valid) {
                tile.button.frame.Hide();
                continue;
            }

            const column = classIndex % 5;
            const row = Math.floor(classIndex / 5);
            tile.button.frame.ClearAllPoints();
            tile.button.frame.SetPoint("TOPLEFT", classSection.frame, "TOPLEFT", 14 + column * 202, -(72 + row * 122));
            tile.sub.SetText(classRoleSummary(tile.classDef.id, currentRole));
            tile.specs.SetText(specSummary(tile.classDef.id, currentRole));
            const selected = tile.classDef.id === currentClass;
            tile.button.setSelected(selected);
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
            specHint.SetText("Select a specialization for your " + (selectedClass?.label ?? "selected class") + " build.");
            emptySpec.Hide();

            let specIndex = 0;
            for (const tile of specTiles) {
                let visible = false;
                if (tile.classId === currentClass) {
                    for (const validSpec of getSpecsForRole(currentClass, currentRole)) {
                        if (validSpec.id === tile.spec.id) {
                            visible = true;
                            break;
                        }
                    }
                }

                if (visible) {
                    tile.button.frame.ClearAllPoints();
                    tile.button.frame.SetPoint("TOPLEFT", specSection.frame, "TOPLEFT", 14 + specIndex * 248, -78);
                    tile.sub.SetText(classRoleSummary(tile.classId, currentRole));
                    const selected = tile.spec.id === currentSpec;
                    tile.button.setSelected(selected);
                    setRadioSelected(tile.marker, selected);
                    tile.button.frame.Show();
                    specIndex += 1;
                } else tile.button.frame.Hide();
            }

            anySpecButton.frame.ClearAllPoints();
            anySpecButton.frame.SetPoint("TOPLEFT", specSection.frame, "TOPLEFT", 14 + specIndex * 248, -78);
            const anySelected = currentSpec === ANY_SPEC_ID;
            anySpecButton.setSelected(anySelected);
            setRadioSelected(anySpecMarker, anySelected);
            anySpecButton.frame.Show();
        }

        const selectedClass = currentClass === undefined ? undefined : getClass(currentClass);
        let selectedSpec: SpecDefinition | undefined;
        if (currentClass !== undefined && currentSpec !== undefined && currentSpec !== ANY_SPEC_ID) {
            for (const spec of getSpecsForRole(currentClass, currentRole)) {
                if (spec.id === currentSpec) {
                    selectedSpec = spec;
                    break;
                }
            }
        }

        if (selectedClass !== undefined) {
            setClassIcon(summaryClassBadge.icon, selectedClass.id);
            summaryClassBadge.outline.setColor(classColor(selectedClass.id));
            summaryClassText.SetText(selectedClass.label);
        } else {
            summaryClassBadge.icon.SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
            summaryClassBadge.icon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            summaryClassBadge.outline.setColor(theme.colors.borderStrong);
            summaryClassText.SetText("Choose class");
        }

        if (selectedClass !== undefined && currentSpec === ANY_SPEC_ID) {
            summarySpecBadge.icon.SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
            summarySpecBadge.icon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            summarySpecBadge.outline.setColor(theme.colors.primary);
            summarySpecText.SetText("Any valid spec");
            apply.setEnabled(true);
        } else if (selectedClass !== undefined && selectedSpec !== undefined) {
            summarySpecBadge.icon.SetTexture(selectedSpec.icon);
            summarySpecBadge.icon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            summarySpecBadge.outline.setColor(theme.colors.primary);
            summarySpecText.SetText(selectedSpec.label);
            apply.setEnabled(true);
        } else {
            summarySpecBadge.icon.SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
            summarySpecBadge.icon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            summarySpecBadge.outline.setColor(theme.colors.borderStrong);
            summarySpecText.SetText("Choose spec");
            apply.setEnabled(false);
        }
    }

    return {
        frame: modal.frame,
        open(role: Role, initial?: Partial<BuildSelection>, showCount = true): void {
            currentRole = role;
            currentClass = initial?.classId;
            currentSpec = initial?.specId;
            countEnabled = options.allowCount === true && showCount;

            if (countEnabled) {
                countLabel.Show();
                countStepper.frame.Show();
            } else {
                countLabel.Hide();
                countStepper.frame.Hide();
            }
            countStepper.setValue(initial?.count ?? 1);

            if (currentClass !== undefined) {
                let validCurrent = false;
                for (const spec of getSpecsForRole(currentClass, currentRole)) {
                    if (spec.id === currentSpec) {
                        validCurrent = true;
                        break;
                    }
                }
                if (!validCurrent && currentSpec !== ANY_SPEC_ID) currentSpec = undefined;
            }

            refresh();
            modal.show();
        },
        close(): void { modal.hide(); },
    };
}

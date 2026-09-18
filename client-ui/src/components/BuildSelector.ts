import { classColor, createIcon, createPanel, createSolid, createText, setClassIcon } from "../core/Native";
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
}

interface SpecTile {
    readonly classId: ClassId;
    readonly classLabel: string;
    readonly spec: SpecDefinition;
    readonly button: UIButton;
    readonly icon: WoWTexture;
    readonly sub: WoWFontString;
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

export function createBuildSelector(parent: WoWFrame, options: BuildSelectorOptions): BuildSelector {
    const modal = createModal(parent, 1000, 680);

    let currentRole: Role = "DPS";
    let currentClass: ClassId | undefined;
    let currentSpec: number | undefined;
    let countEnabled = options.allowCount === true;

    // Step 1: class ----------------------------------------------------------
    const classSection = createPanel(modal.content, theme.colors.surface, theme.colors.border);
    classSection.frame.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 0, 0);
    classSection.frame.SetPoint("TOPRIGHT", modal.content, "TOPRIGHT", 0, 0);
    classSection.frame.SetHeight(212);

    const classStep = createPanel(classSection.frame, theme.colors.surfaceRaised, theme.colors.borderStrong);
    classStep.frame.SetSize(34, 34);
    classStep.frame.SetPoint("TOPLEFT", classSection.frame, "TOPLEFT", 14, -14);
    const classStepText = createText(classStep.frame, "1", "GameFontNormal", theme.colors.primary);
    classStepText.SetPoint("CENTER", classStep.frame, "CENTER", 0, 0);

    const classTitle = createText(classSection.frame, "Choose a class", "GameFontNormalLarge");
    classTitle.SetPoint("TOPLEFT", classSection.frame, "TOPLEFT", 60, -13);
    const classHint = createText(classSection.frame, "Only classes that can perform the selected role are shown.", "GameFontHighlightSmall", theme.colors.muted);
    classHint.SetPoint("TOPLEFT", classTitle, "BOTTOMLEFT", 0, -4);

    const classTiles: ClassTile[] = [];
    for (const classDef of getClassesForRole("DPS")) {
        const button = createButton(classSection.frame, {
            text: classDef.label,
            width: 170,
            height: 62,
            accent: classColor(classDef.id),
        });
        const accent = createSolid(button.frame, classColor(classDef.id), "ARTWORK");
        accent.SetWidth(3);
        accent.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 0, 0);
        accent.SetPoint("BOTTOMLEFT", button.frame, "BOTTOMLEFT", 0, 0);

        const icon = button.frame.CreateTexture(undefined, "ARTWORK");
        icon.SetSize(36, 36);
        icon.SetPoint("LEFT", button.frame, "LEFT", 12, 0);
        setClassIcon(icon, classDef.id);

        button.label.ClearAllPoints();
        button.label.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 58, -12);
        button.label.SetPoint("RIGHT", button.frame, "RIGHT", -8, 8);
        button.label.SetJustifyH("LEFT");

        const sub = createText(button.frame, "Available", "GameFontHighlightSmall", theme.colors.muted);
        sub.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 58, -34);
        sub.SetWidth(100);

        button.frame.SetScript("OnMouseDown", () => {
            if (currentClass !== classDef.id) currentSpec = undefined;
            currentClass = classDef.id;
            refresh();
        });

        classTiles.push({ classDef, button, icon, sub });
    }

    // Step 2: specialization -------------------------------------------------
    const specSection = createPanel(modal.content, theme.colors.surface, theme.colors.border);
    specSection.frame.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 0, -226);
    specSection.frame.SetPoint("TOPRIGHT", modal.content, "TOPRIGHT", 0, -226);
    specSection.frame.SetHeight(224);

    const specStep = createPanel(specSection.frame, theme.colors.surfaceRaised, theme.colors.borderStrong);
    specStep.frame.SetSize(34, 34);
    specStep.frame.SetPoint("TOPLEFT", specSection.frame, "TOPLEFT", 14, -14);
    const specStepText = createText(specStep.frame, "2", "GameFontNormal", theme.colors.primary);
    specStepText.SetPoint("CENTER", specStep.frame, "CENTER", 0, 0);

    const specTitle = createText(specSection.frame, "Choose a specialization", "GameFontNormalLarge");
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
        width: 214,
        height: 86,
        accent: theme.colors.primary,
        onClick: () => {
            if (currentClass === undefined) return;
            currentSpec = ANY_SPEC_ID;
            refresh();
        },
    });
    const anySpecIcon = createIcon(anySpecButton.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 38);
    anySpecIcon.SetPoint("LEFT", anySpecButton.frame, "LEFT", 14, 0);
    anySpecButton.label.ClearAllPoints();
    anySpecButton.label.SetPoint("TOPLEFT", anySpecButton.frame, "TOPLEFT", 64, -18);
    anySpecButton.label.SetPoint("RIGHT", anySpecButton.frame, "RIGHT", -10, 10);
    anySpecButton.label.SetJustifyH("LEFT");
    const anySpecSub = createText(anySpecButton.frame, "Lock class, let Composer pick spec", "GameFontHighlightSmall", theme.colors.muted);
    anySpecSub.SetPoint("TOPLEFT", anySpecButton.frame, "TOPLEFT", 64, -45);
    anySpecSub.SetWidth(136);
    anySpecSub.SetJustifyV("TOP");
    anySpecButton.frame.Hide();

    const specTiles: SpecTile[] = [];
    for (const classDef of getClassesForRole("DPS")) {
        for (const spec of classDef.specs) {
            const button = createButton(specSection.frame, {
                text: spec.label,
                width: 214,
                height: 86,
                accent: classColor(classDef.id),
            });
            const icon = createIcon(button.frame, spec.icon, 40);
            icon.SetPoint("LEFT", button.frame, "LEFT", 14, 0);
            button.label.ClearAllPoints();
            button.label.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 66, -18);
            button.label.SetPoint("RIGHT", button.frame, "RIGHT", -10, 10);
            button.label.SetJustifyH("LEFT");
            const sub = createText(button.frame, classDef.label, "GameFontHighlightSmall", theme.colors.muted);
            sub.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 66, -45);
            sub.SetWidth(136);

            button.frame.SetScript("OnMouseDown", () => {
                currentClass = classDef.id;
                currentSpec = spec.id;
                refresh();
            });
            button.frame.Hide();
            specTiles.push({ classId: classDef.id, classLabel: classDef.label, spec, button, icon, sub });
        }
    }

    // Selection bar ----------------------------------------------------------
    const summary = createPanel(modal.content, theme.colors.surfaceRaised, theme.colors.borderStrong);
    summary.frame.SetPoint("BOTTOMLEFT", modal.content, "BOTTOMLEFT", 0, 0);
    summary.frame.SetPoint("BOTTOMRIGHT", modal.content, "BOTTOMRIGHT", 0, 0);
    summary.frame.SetHeight(104);

    const selectedLabel = createText(summary.frame, "SELECTION", "GameFontNormalSmall", theme.colors.muted);
    selectedLabel.SetPoint("TOPLEFT", summary.frame, "TOPLEFT", 14, -12);

    const summaryClassIcon = summary.frame.CreateTexture(undefined, "ARTWORK");
    summaryClassIcon.SetSize(42, 42);
    summaryClassIcon.SetPoint("BOTTOMLEFT", summary.frame, "BOTTOMLEFT", 14, 13);
    summaryClassIcon.SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
    summaryClassIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);

    const summarySpecIcon = summary.frame.CreateTexture(undefined, "ARTWORK");
    summarySpecIcon.SetSize(42, 42);
    summarySpecIcon.SetPoint("LEFT", summaryClassIcon, "RIGHT", 7, 0);
    summarySpecIcon.SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
    summarySpecIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);

    const summaryText = createText(summary.frame, "Choose a class", "GameFontNormal");
    summaryText.SetPoint("LEFT", summarySpecIcon, "RIGHT", 12, 8);
    summaryText.SetWidth(390);
    const summarySub = createText(summary.frame, "Then choose an exact spec or leave the spec flexible.", "GameFontHighlightSmall", theme.colors.muted);
    summarySub.SetPoint("TOPLEFT", summaryText, "BOTTOMLEFT", 0, -5);
    summarySub.SetWidth(390);

    const countLabel = createText(summary.frame, "HOW MANY", "GameFontNormalSmall", theme.colors.muted);
    countLabel.SetPoint("TOPRIGHT", summary.frame, "TOPRIGHT", -204, -14);
    const countStepper = createNumberStepper(summary.frame, 1, options.maxCount ?? 40, 1);
    countStepper.frame.SetPoint("BOTTOMRIGHT", summary.frame, "BOTTOMRIGHT", -164, 13);

    const apply = createButton(summary.frame, {
        text: "Use this build",
        width: 148,
        height: 42,
        accent: theme.colors.success,
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
    apply.frame.SetPoint("BOTTOMRIGHT", summary.frame, "BOTTOMRIGHT", -12, 13);

    function refresh(): void {
        const accent = roleAccent(currentRole);
        modal.setTitle("Add " + roleLabel(currentRole) + " Build");
        modal.setSubtitle("Reserve only what matters. Unspecified slots remain Auto-filled.");

        classSection.outline.setColor(accent);
        specSection.outline.setColor(accent);
        classStep.outline.setColor(accent);
        specStep.outline.setColor(accent);
        classStepText.SetTextColor(accent[0], accent[1], accent[2], 1);
        specStepText.SetTextColor(accent[0], accent[1], accent[2], 1);

        const validClasses = getClassesForRole(currentRole);
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
            tile.button.frame.SetPoint("TOPLEFT", classSection.frame, "TOPLEFT", 14 + column * 184, -(72 + row * 70));
            tile.sub.SetText(roleLabel(currentRole) + " capable");
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
            specHint.SetText((selectedClass?.label ?? "Selected class") + " options for " + roleLabel(currentRole) + ".");
            emptySpec.Hide();

            anySpecButton.frame.ClearAllPoints();
            anySpecButton.frame.SetPoint("TOPLEFT", specSection.frame, "TOPLEFT", 14, -74);
            anySpecButton.setSelected(currentSpec === ANY_SPEC_ID);
            anySpecButton.frame.Show();

            let specIndex = 1;
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
                    tile.button.frame.SetPoint("TOPLEFT", specSection.frame, "TOPLEFT", 14 + specIndex * 226, -74);
                    tile.sub.SetText(tile.classLabel + " · " + roleLabel(currentRole));
                    tile.button.setSelected(tile.spec.id === currentSpec);
                    tile.button.frame.Show();
                    specIndex += 1;
                } else tile.button.frame.Hide();
            }
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

        if (selectedClass !== undefined) setClassIcon(summaryClassIcon, selectedClass.id);
        else {
            summaryClassIcon.SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
            summaryClassIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
        }

        if (selectedClass !== undefined && currentSpec === ANY_SPEC_ID) {
            summarySpecIcon.SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
            summarySpecIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            summaryText.SetText(selectedClass.label + " · Any valid specialization");
            summarySub.SetText("Composer may use any " + roleLabel(currentRole).toLowerCase() + " spec from this class.");
            apply.setEnabled(true);
        } else if (selectedClass !== undefined && selectedSpec !== undefined) {
            summarySpecIcon.SetTexture(selectedSpec.icon);
            summarySpecIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            summaryText.SetText(selectedSpec.label + " " + selectedClass.label);
            summarySub.SetText(roleLabel(currentRole) + " · exact specialization reserved");
            apply.setEnabled(true);
        } else {
            summarySpecIcon.SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
            summarySpecIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            summaryText.SetText(currentClass === undefined ? "Choose a class" : "Choose a specialization");
            summarySub.SetText(currentClass === undefined
                ? "Start with one of the role-compatible classes above."
                : "Pick an exact spec, or choose Any valid spec for a flexible class lock.");
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

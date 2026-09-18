import { classColor, createIcon, createPanel, createText, setClassIcon } from "../core/Native";
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
    const modal = createModal(parent, 960, 590);

    const leftPanel = createPanel(modal.content, theme.colors.surface, theme.colors.border);
    leftPanel.frame.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 0, 0);
    leftPanel.frame.SetSize(438, 382);

    const rightPanel = createPanel(modal.content, theme.colors.surface, theme.colors.border);
    rightPanel.frame.SetPoint("TOPRIGHT", modal.content, "TOPRIGHT", 0, 0);
    rightPanel.frame.SetSize(438, 382);

    const classTitle = createText(leftPanel.frame, "CHOOSE CLASS", "GameFontNormalSmall", theme.colors.muted);
    classTitle.SetPoint("TOPLEFT", leftPanel.frame, "TOPLEFT", 14, -14);
    const classHint = createText(leftPanel.frame, "Only classes that can fill this role are shown.", "GameFontHighlightSmall", theme.colors.muted);
    classHint.SetPoint("TOPLEFT", classTitle, "BOTTOMLEFT", 0, -5);

    const specTitle = createText(rightPanel.frame, "CHOOSE SPECIALIZATION", "GameFontNormalSmall", theme.colors.muted);
    specTitle.SetPoint("TOPLEFT", rightPanel.frame, "TOPLEFT", 14, -14);
    const specHint = createText(rightPanel.frame, "Select a class first.", "GameFontHighlightSmall", theme.colors.muted);
    specHint.SetPoint("TOPLEFT", specTitle, "BOTTOMLEFT", 0, -5);

    const emptySpec = createText(
        rightPanel.frame,
        "Choose a class on the left. This panel will then show only specializations valid for the selected role.",
        "GameFontHighlight",
        theme.colors.muted,
    );
    emptySpec.SetPoint("TOPLEFT", rightPanel.frame, "TOPLEFT", 18, -78);
    emptySpec.SetWidth(390);
    emptySpec.SetJustifyV("TOP");

    const summary = createPanel(modal.content, theme.colors.surfaceRaised, theme.colors.border);
    summary.frame.SetPoint("BOTTOMLEFT", modal.content, "BOTTOMLEFT", 0, 0);
    summary.frame.SetPoint("BOTTOMRIGHT", modal.content, "BOTTOMRIGHT", 0, 0);
    summary.frame.SetHeight(94);

    const selectedLabel = createText(summary.frame, "SELECTED BUILD", "GameFontNormalSmall", theme.colors.muted);
    selectedLabel.SetPoint("TOPLEFT", summary.frame, "TOPLEFT", 14, -12);

    const summaryClassIcon = summary.frame.CreateTexture(undefined, "ARTWORK");
    summaryClassIcon.SetSize(40, 40);
    summaryClassIcon.SetPoint("BOTTOMLEFT", summary.frame, "BOTTOMLEFT", 14, 12);
    summaryClassIcon.SetTexture("Interface\Icons\INV_Misc_QuestionMark");
    summaryClassIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);

    const summarySpecIcon = summary.frame.CreateTexture(undefined, "ARTWORK");
    summarySpecIcon.SetSize(40, 40);
    summarySpecIcon.SetPoint("LEFT", summaryClassIcon, "RIGHT", 6, 0);
    summarySpecIcon.SetTexture("Interface\Icons\INV_Misc_QuestionMark");
    summarySpecIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);

    const summaryText = createText(summary.frame, "Choose a class and specialization", "GameFontNormal");
    summaryText.SetPoint("LEFT", summarySpecIcon, "RIGHT", 12, 8);
    summaryText.SetWidth(330);
    const summarySub = createText(summary.frame, "Role-filtered choices only.", "GameFontHighlightSmall", theme.colors.muted);
    summarySub.SetPoint("TOPLEFT", summaryText, "BOTTOMLEFT", 0, -5);
    summarySub.SetWidth(330);

    let currentRole: Role = "DPS";
    let currentClass: ClassId | undefined;
    let currentSpec: number | undefined;
    let countEnabled = options.allowCount === true;

    const countLabel = createText(summary.frame, "COUNT", "GameFontNormalSmall", theme.colors.muted);
    countLabel.SetPoint("TOPRIGHT", summary.frame, "TOPRIGHT", -194, -14);
    const countStepper = createNumberStepper(summary.frame, 1, options.maxCount ?? 40, 1);
    countStepper.frame.SetPoint("BOTTOMRIGHT", summary.frame, "BOTTOMRIGHT", -154, 12);

    const apply = createButton(summary.frame, {
        text: "Apply Build",
        width: 136,
        height: 40,
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

    const classTiles: ClassTile[] = [];
    const specTiles: SpecTile[] = [];

    const anySpecButton = createButton(rightPanel.frame, {
        text: "Any valid specialization",
        width: 398,
        height: 58,
        accent: theme.colors.primary,
        onClick: () => {
            if (currentClass === undefined) return;
            currentSpec = ANY_SPEC_ID;
            refresh();
        },
    });
    const anySpecIcon = createIcon(anySpecButton.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 34);
    anySpecIcon.SetPoint("LEFT", anySpecButton.frame, "LEFT", 12, 0);
    anySpecButton.label.ClearAllPoints();
    anySpecButton.label.SetPoint("LEFT", anySpecButton.frame, "LEFT", 58, 7);
    anySpecButton.label.SetPoint("RIGHT", anySpecButton.frame, "RIGHT", -12, 7);
    anySpecButton.label.SetJustifyH("LEFT");
    const anySpecSub = createText(anySpecButton.frame, "Lock this class and let Composer choose a suitable valid spec.", "GameFontHighlightSmall", theme.colors.muted);
    anySpecSub.SetPoint("LEFT", anySpecButton.frame, "LEFT", 58, -11);
    anySpecSub.SetWidth(320);
    anySpecButton.frame.Hide();

    function selectClass(classId: ClassId): void {
        if (currentClass !== classId) currentSpec = undefined;
        currentClass = classId;
        refresh();
    }

    function selectSpec(specId: number): void {
        currentSpec = specId;
        refresh();
    }

    // DPS contains every WotLK class that can ever appear in Composer, so this produces one reusable pool.
    for (const classDef of getClassesForRole("DPS")) {
        const button = createButton(leftPanel.frame, {
            text: classDef.label,
            width: 194,
            height: 52,
            accent: classColor(classDef.id),
            onClick: () => selectClass(classDef.id),
        });

        const icon = button.frame.CreateTexture(undefined, "ARTWORK");
        icon.SetSize(32, 32);
        icon.SetPoint("LEFT", button.frame, "LEFT", 10, 0);
        setClassIcon(icon, classDef.id);

        button.label.ClearAllPoints();
        button.label.SetPoint("LEFT", button.frame, "LEFT", 52, 0);
        button.label.SetPoint("RIGHT", button.frame, "RIGHT", -10, 0);
        button.label.SetJustifyH("LEFT");

        classTiles.push({ classDef, button, icon });
    }

    for (const classDef of getClassesForRole("DPS")) {
        for (const spec of classDef.specs) {
            const button = createButton(rightPanel.frame, {
                text: spec.label,
                width: 398,
                height: 58,
                accent: classColor(classDef.id),
                onClick: () => {
                    currentClass = classDef.id;
                    selectSpec(spec.id);
                },
            });

            const icon = createIcon(button.frame, spec.icon, 34);
            icon.SetPoint("LEFT", button.frame, "LEFT", 12, 0);

            button.label.ClearAllPoints();
            button.label.SetPoint("LEFT", button.frame, "LEFT", 58, 7);
            button.label.SetPoint("RIGHT", button.frame, "RIGHT", -12, 7);
            button.label.SetJustifyH("LEFT");

            const sub = createText(button.frame, classDef.label, "GameFontHighlightSmall", theme.colors.muted);
            sub.SetPoint("LEFT", button.frame, "LEFT", 58, -11);
            sub.SetWidth(300);

            button.frame.Hide();
            specTiles.push({ classId: classDef.id, classLabel: classDef.label, spec, button, icon, sub });
        }
    }

    function refresh(): void {
        const accent = roleAccent(currentRole);
        modal.setTitle("Choose " + roleLabel(currentRole) + " Build");
        modal.setSubtitle("Reserve only what you care about. Unspecified slots remain Auto-filled.");

        leftPanel.outline.setColor(accent);
        rightPanel.outline.setColor(accent);

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

            if (valid) {
                const column = classIndex % 2;
                const row = Math.floor(classIndex / 2);
                tile.button.frame.ClearAllPoints();
                tile.button.frame.SetPoint("TOPLEFT", leftPanel.frame, "TOPLEFT", 14 + column * 204, -(64 + row * 58));
                tile.button.setSelected(tile.classDef.id === currentClass);
                tile.button.frame.Show();
                classIndex += 1;
            } else {
                tile.button.frame.Hide();
            }
        }

        let specIndex = 0;
        if (currentClass !== undefined) {
            anySpecButton.frame.ClearAllPoints();
            anySpecButton.frame.SetPoint("TOPLEFT", rightPanel.frame, "TOPLEFT", 18, -64);
            anySpecButton.setSelected(currentSpec === ANY_SPEC_ID);
            anySpecButton.frame.Show();
            specIndex = 1;
        } else {
            anySpecButton.frame.Hide();
        }

        for (const tile of specTiles) {
            let visible = false;
            if (currentClass !== undefined && tile.classId === currentClass) {
                for (const validSpec of getSpecsForRole(currentClass, currentRole)) {
                    if (validSpec.id === tile.spec.id) {
                        visible = true;
                        break;
                    }
                }
            }

            if (visible) {
                tile.button.frame.ClearAllPoints();
                tile.button.frame.SetPoint("TOPLEFT", rightPanel.frame, "TOPLEFT", 18, -(64 + specIndex * 66));
                tile.sub.SetText(tile.classLabel + "  ·  " + roleLabel(currentRole));
                tile.button.setSelected(tile.spec.id === currentSpec);
                tile.button.frame.Show();
                specIndex += 1;
            } else {
                tile.button.frame.Hide();
            }
        }

        if (currentClass === undefined) {
            specHint.SetText("Select a class first.");
            emptySpec.Show();
        } else {
            const selectedClass = getClass(currentClass);
            specHint.SetText(selectedClass === undefined ? "Choose a specialization." : selectedClass.label + " specializations valid for " + roleLabel(currentRole) + ".");
            emptySpec.Hide();
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
            setClassIcon(summaryClassIcon, selectedClass.id);
        } else {
            summaryClassIcon.SetTexture("Interface\Icons\INV_Misc_QuestionMark");
            summaryClassIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
        }

        if (selectedClass !== undefined && currentSpec === ANY_SPEC_ID) {
            summarySpecIcon.SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
            summarySpecIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            summaryText.SetText(selectedClass.label + " · Any valid spec");
            summarySub.SetText("Class locked; Composer auto-selects a suitable " + roleLabel(currentRole).toLowerCase() + " spec.");
            apply.setEnabled(true);
        } else if (selectedClass !== undefined && selectedSpec !== undefined) {
            summarySpecIcon.SetTexture(selectedSpec.icon);
            summarySpecIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            summaryText.SetText(selectedSpec.label + " " + selectedClass.label);
            summarySub.SetText(roleLabel(currentRole) + " build selected");
            apply.setEnabled(true);
        } else {
            summarySpecIcon.SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
            summarySpecIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            summaryText.SetText(currentClass === undefined ? "Choose a class" : "Choose a specialization");
            summarySub.SetText("Pick an exact spec, or use Any valid specialization to lock only the class.");
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
        close(): void {
            modal.hide();
        },
    };
}

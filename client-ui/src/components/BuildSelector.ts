import { classColor, createIcon, createPanel, createText, setClassIcon } from "../core/Native";
import { ClassDefinition, ClassId, getClass, getClassesForRole, getSpecsForRole, Role, SpecDefinition } from "../data/WotlkBuilds";
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

interface ClassTile { readonly classDef: ClassDefinition; readonly button: UIButton; }
interface SpecTile { readonly classId: ClassId; readonly spec: SpecDefinition; readonly button: UIButton; }

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
    const modal = createModal(parent, 820, 500);

    const leftPanel = createPanel(modal.content, theme.colors.surface, theme.colors.border);
    leftPanel.frame.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 0, 0);
    leftPanel.frame.SetSize(390, 330);

    const rightPanel = createPanel(modal.content, theme.colors.surface, theme.colors.border);
    rightPanel.frame.SetPoint("TOPRIGHT", modal.content, "TOPRIGHT", 0, 0);
    rightPanel.frame.SetSize(374, 330);

    const classTitle = createText(leftPanel.frame, "CLASS", "GameFontNormalSmall", theme.colors.muted);
    classTitle.SetPoint("TOPLEFT", leftPanel.frame, "TOPLEFT", theme.spacing.md, -theme.spacing.md);
    const specTitle = createText(rightPanel.frame, "SPECIALIZATION", "GameFontNormalSmall", theme.colors.muted);
    specTitle.SetPoint("TOPLEFT", rightPanel.frame, "TOPLEFT", theme.spacing.md, -theme.spacing.md);
    const specEmpty = createText(
        rightPanel.frame,
        "Choose a class to see only the specs that can fill this role.",
        "GameFontHighlightSmall",
        theme.colors.muted,
    );
    specEmpty.SetPoint("TOPLEFT", rightPanel.frame, "TOPLEFT", theme.spacing.md, -54);
    specEmpty.SetWidth(330);
    specEmpty.SetJustifyV("TOP");

    const summary = createPanel(modal.content, theme.colors.surfaceRaised, theme.colors.borderStrong);
    summary.frame.SetPoint("BOTTOMLEFT", modal.content, "BOTTOMLEFT", 0, 0);
    summary.frame.SetPoint("BOTTOMRIGHT", modal.content, "BOTTOMRIGHT", 0, 0);
    summary.frame.SetHeight(78);

    const summaryClassIcon = summary.frame.CreateTexture(undefined, "ARTWORK");
    summaryClassIcon.SetSize(38, 38);
    summaryClassIcon.SetPoint("LEFT", summary.frame, "LEFT", theme.spacing.md, 0);
    summaryClassIcon.SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
    summaryClassIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);

    const summaryIcon = summary.frame.CreateTexture(undefined, "ARTWORK");
    summaryIcon.SetSize(38, 38);
    summaryIcon.SetPoint("LEFT", summaryClassIcon, "RIGHT", 6, 0);
    summaryIcon.SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
    summaryIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);

    const summaryText = createText(summary.frame, "Choose a class and specialization", "GameFontNormal");
    summaryText.SetPoint("LEFT", summaryIcon, "RIGHT", theme.spacing.md, 8);
    const summarySub = createText(summary.frame, "Only legal choices for the selected role are shown.", "GameFontHighlightSmall", theme.colors.muted);
    summarySub.SetPoint("TOPLEFT", summaryText, "BOTTOMLEFT", 0, -4);

    let currentRole: Role = "DPS";
    let currentClass: ClassId | undefined;
    let currentSpec: number | undefined;
    let countEnabled = options.allowCount === true;

    const countLabel = createText(summary.frame, "COUNT", "GameFontNormalSmall", theme.colors.muted);
    countLabel.SetPoint("RIGHT", summary.frame, "RIGHT", -204, 13);
    const countStepper = createNumberStepper(summary.frame, 1, options.maxCount ?? 40, 1);
    countStepper.frame.SetPoint("RIGHT", summary.frame, "RIGHT", -170, -8);
    if (options.allowCount !== true) {
        countLabel.Hide();
        countStepper.frame.Hide();
    }

    const apply = createButton(summary.frame, {
        text: "Apply Build", width: 136, height: 38, accent: theme.colors.primary,
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
    apply.frame.SetPoint("RIGHT", summary.frame, "RIGHT", -theme.spacing.md, 0);

    const classTiles: ClassTile[] = [];
    const specTiles: SpecTile[] = [];

    function selectClass(classId: ClassId): void {
        currentClass = classId;
        currentSpec = undefined;
        refresh();
    }

    function selectSpec(specId: number): void {
        currentSpec = specId;
        refresh();
    }

    for (const classDef of getClassesForRole("DPS")) {
        const button = createButton(leftPanel.frame, {
            text: classDef.label, width: 86, height: 82,
            accent: classColor(classDef.id),
            onClick: () => selectClass(classDef.id),
        });
        const icon = button.frame.CreateTexture(undefined, "ARTWORK");
        icon.SetSize(38, 38);
        icon.SetPoint("TOP", button.frame, "TOP", 0, -8);
        setClassIcon(icon, classDef.id);
        button.label.ClearAllPoints();
        button.label.SetPoint("BOTTOM", button.frame, "BOTTOM", 0, 8);
        button.label.SetJustifyH("CENTER");
        classTiles.push({ classDef, button });
    }

    for (const classDef of getClassesForRole("DPS")) {
        for (const spec of classDef.specs) {
            const button = createButton(rightPanel.frame, {
                text: spec.label, width: 104, height: 94,
                accent: classColor(classDef.id),
                onClick: () => { currentClass = classDef.id; selectSpec(spec.id); },
            });
            const icon = createIcon(button.frame, spec.icon, 44);
            icon.SetPoint("TOP", button.frame, "TOP", 0, -10);
            button.label.ClearAllPoints();
            button.label.SetPoint("BOTTOM", button.frame, "BOTTOM", 0, 10);
            button.label.SetJustifyH("CENTER");
            button.frame.Hide();
            specTiles.push({ classId: classDef.id, spec, button });
        }
    }

    function refresh(): void {
        modal.setTitle("Choose " + roleLabel(currentRole) + " Build");
        modal.setSubtitle("Pick a class on the left, then a valid " + roleLabel(currentRole).toLowerCase() + " spec on the right.");

        const validClasses = getClassesForRole(currentRole);
        let classIndex = 0;
        for (const tile of classTiles) {
            let valid = false;
            for (const classDef of validClasses) if (classDef.id === tile.classDef.id) { valid = true; break; }
            if (valid) {
                const column = classIndex % 4;
                const row = Math.floor(classIndex / 4);
                tile.button.frame.ClearAllPoints();
                tile.button.frame.SetPoint("TOPLEFT", leftPanel.frame, "TOPLEFT", theme.spacing.md + column * 92, -(42 + row * 90));
                tile.button.setSelected(tile.classDef.id === currentClass);
                tile.button.frame.Show();
                classIndex += 1;
            } else tile.button.frame.Hide();
        }

        let specIndex = 0;
        for (const tile of specTiles) {
            let visible = false;
            if (currentClass !== undefined && tile.classId === currentClass) {
                for (const validSpec of getSpecsForRole(currentClass, currentRole)) {
                    if (validSpec.id === tile.spec.id) { visible = true; break; }
                }
            }
            if (visible) {
                const column = specIndex % 3;
                const row = Math.floor(specIndex / 3);
                tile.button.frame.ClearAllPoints();
                tile.button.frame.SetPoint("TOPLEFT", rightPanel.frame, "TOPLEFT", theme.spacing.md + column * 116, -(48 + row * 104));
                tile.button.setSelected(tile.spec.id === currentSpec);
                tile.button.frame.Show();
                specIndex += 1;
            } else tile.button.frame.Hide();
        }

        if (currentClass === undefined) specEmpty.Show();
        else specEmpty.Hide();

        const selectedClass = currentClass === undefined ? undefined : getClass(currentClass);
        let selectedSpec: SpecDefinition | undefined;
        if (currentClass !== undefined && currentSpec !== undefined) {
            for (const spec of getSpecsForRole(currentClass, currentRole)) {
                if (spec.id === currentSpec) { selectedSpec = spec; break; }
            }
        }

        if (selectedClass !== undefined) {
            setClassIcon(summaryClassIcon, selectedClass.id);
        } else {
            summaryClassIcon.SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
            summaryClassIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
        }

        if (selectedClass !== undefined && selectedSpec !== undefined) {
            summaryIcon.SetTexture(selectedSpec.icon);
            summaryIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            summaryText.SetText(selectedSpec.label + " " + selectedClass.label);
            summarySub.SetText(roleLabel(currentRole) + " build selected");
            apply.setEnabled(true);
        } else {
            summaryIcon.SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
            summaryIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            summaryIcon.SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
            summaryIcon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            summaryText.SetText(currentClass === undefined ? "Choose a class" : "Choose a specialization");
            summarySub.SetText("Only legal " + roleLabel(currentRole) + " choices are shown.");
            apply.setEnabled(false);
        }

        const accent = roleAccent(currentRole);
        leftPanel.outline.setColor(accent);
        rightPanel.outline.setColor(accent);
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
                    if (spec.id === currentSpec) { validCurrent = true; break; }
                }
                if (!validCurrent) currentSpec = undefined;
            }

            refresh();
            modal.show();
        },
        close(): void { modal.hide(); },
    };
}

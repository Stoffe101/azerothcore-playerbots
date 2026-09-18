import { createPanel, createText } from "../core/Native";
import { theme } from "../theme/Theme";
import { createButton } from "./Button";

export interface NumberStepper {
    readonly frame: WoWFrame;
    getValue(): number;
    setValue(value: number, notify?: boolean): void;
    setBounds(min: number, max: number): void;
}

export function createNumberStepper(
    parent: WoWFrame,
    initialMin: number,
    initialMax: number,
    initial: number,
    onChange?: (value: number) => void,
): NumberStepper {
    const frame = CreateFrame("Frame", undefined, parent);
    frame.SetSize(110, 42);
    let min = initialMin;
    let max = initialMax;
    let value = initial;

    const center = createPanel(frame, theme.colors.surfaceDeep, theme.colors.borderStrong);
    center.frame.SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
    center.frame.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 0);

    const valueText = createText(center.frame, String(value), "GameFontNormalLarge", theme.colors.text);
    valueText.SetPoint("CENTER", center.frame, "CENTER", 0, 0);
    valueText.SetJustifyH("CENTER");

    const plus = createButton(frame, {
        text: "^",
        width: 26,
        height: 19,
        accent: theme.colors.primary,
        onClick: () => update(value + 1),
    });
    plus.frame.SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0);

    const minus = createButton(frame, {
        text: "v",
        width: 26,
        height: 19,
        accent: theme.colors.primary,
        onClick: () => update(value - 1),
    });
    minus.frame.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0);

    function update(next: number, notify = true): void {
        value = Math.max(min, Math.min(max, next));
        valueText.SetText(String(value));
        minus.setEnabled(value > min);
        plus.setEnabled(value < max);
        if (notify && onChange !== undefined) onChange(value);
    }

    update(initial, false);

    return {
        frame,
        getValue(): number { return value; },
        setValue(next: number, notify = false): void { update(next, notify); },
        setBounds(nextMin: number, nextMax: number): void {
            min = nextMin;
            max = Math.max(nextMin, nextMax);
            update(value, false);
        },
    };
}

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
    frame.SetSize(118, 36);
    let min = initialMin;
    let max = initialMax;
    let value = initial;

    const minus = createButton(frame, { text: "-", width: 32, height: 36, accent: theme.colors.primary, onClick: () => update(value - 1) });
    minus.frame.SetPoint("LEFT", frame, "LEFT", 0, 0);

    const center = createPanel(frame, theme.colors.surfaceDeep, theme.colors.borderStrong);
    center.frame.SetPoint("LEFT", minus.frame, "RIGHT", 4, 0);
    center.frame.SetSize(42, 36);
    const valueText = createText(center.frame, String(value), "GameFontNormalLarge", theme.colors.text);
    valueText.SetPoint("CENTER", center.frame, "CENTER", 0, 0);
    valueText.SetJustifyH("CENTER");

    const plus = createButton(frame, { text: "+", width: 32, height: 36, accent: theme.colors.primary, onClick: () => update(value + 1) });
    plus.frame.SetPoint("LEFT", center.frame, "RIGHT", 4, 0);

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
        setBounds(nextMin: number, nextMax: number): void { min = nextMin; max = Math.max(nextMin, nextMax); update(value, false); },
    };
}

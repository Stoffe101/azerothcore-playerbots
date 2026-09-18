import { createText } from "../core/Native";
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
    frame.SetSize(126, theme.control.md);
    let min = initialMin;
    let max = initialMax;
    let value = initial;

    const valueText = createText(frame, String(value), "GameFontNormal");
    valueText.SetPoint("CENTER", frame, "CENTER", 0, 0);
    valueText.SetJustifyH("CENTER");

    function update(next: number, notify = true): void {
        value = Math.max(min, Math.min(max, next));
        valueText.SetText(String(value));
        if (notify && onChange !== undefined) onChange(value);
    }

    const minus = createButton(frame, {
        text: "-",
        width: theme.control.md,
        height: theme.control.md,
        onClick: () => update(value - 1),
    });
    minus.frame.SetPoint("LEFT", frame, "LEFT", 0, 0);

    const plus = createButton(frame, {
        text: "+",
        width: theme.control.md,
        height: theme.control.md,
        onClick: () => update(value + 1),
    });
    plus.frame.SetPoint("RIGHT", frame, "RIGHT", 0, 0);

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

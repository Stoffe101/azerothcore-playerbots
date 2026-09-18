import { createText } from "../core/Native";
import { theme } from "../theme/Theme";
import { createButton } from "./Button";

export interface NumberStepper {
    readonly frame: WoWFrame;
    getValue(): number;
    setValue(value: number): void;
}

export function createNumberStepper(parent: WoWFrame, min: number, max: number, initial: number): NumberStepper {
    const frame = CreateFrame("Frame", undefined, parent);
    frame.SetSize(126, theme.control.md);
    let value = initial;

    const valueText = createText(frame, String(value), "GameFontNormal");
    valueText.SetPoint("CENTER", frame, "CENTER", 0, 0);
    valueText.SetJustifyH("CENTER");

    function update(next: number): void {
        value = Math.max(min, Math.min(max, next));
        valueText.SetText(String(value));
    }

    const minus = createButton(frame, { text: "-", width: theme.control.md, height: theme.control.md, onClick: () => update(value - 1) });
    minus.frame.SetPoint("LEFT", frame, "LEFT", 0, 0);
    const plus = createButton(frame, { text: "+", width: theme.control.md, height: theme.control.md, onClick: () => update(value + 1) });
    plus.frame.SetPoint("RIGHT", frame, "RIGHT", 0, 0);

    return {
        frame,
        getValue(): number { return value; },
        setValue(next: number): void { update(next); },
    };
}

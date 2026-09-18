import { createPanel, createText } from "../core/Native";
import { theme } from "../theme/Theme";

export interface ToggleControl {
    readonly frame: WoWFrame;
    refresh(): void;
}

export function createToggle(
    parent: WoWFrame,
    label: string,
    getValue: () => boolean,
    setValue: (value: boolean) => void,
): ToggleControl {
    const frame = CreateFrame("Frame", undefined, parent);
    frame.SetHeight(30);
    frame.EnableMouse(true);

    const box = createPanel(frame, theme.colors.background, theme.colors.borderStrong);
    box.frame.SetSize(20, 20);
    box.frame.SetPoint("LEFT", frame, "LEFT", 0, 0);

    const check = box.frame.CreateTexture(undefined, "ARTWORK");
    check.SetTexture("Interface\\Buttons\\UI-CheckBox-Check");
    check.SetAllPoints(box.frame);

    const text = createText(frame, label, "GameFontHighlightSmall");
    text.SetPoint("LEFT", box.frame, "RIGHT", 9, 0);

    function refresh(): void {
        if (getValue()) {
            check.Show();
            box.outline.setColor(theme.colors.success);
        } else {
            check.Hide();
            box.outline.setColor(theme.colors.borderStrong);
        }
    }

    frame.SetScript("OnMouseDown", () => {
        setValue(!getValue());
        refresh();
    });

    refresh();
    return { frame, refresh };
}

import { createOutline, createSolid, createText, setTextureColor } from "../core/Native";
import { theme } from "../theme/Theme";

export interface ToggleControl {
    readonly frame: WoWFrame;
    refresh: () => void;
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

    const box = CreateFrame("Frame", undefined, frame);
    box.SetSize(22, 22);
    box.SetPoint("LEFT", frame, "LEFT", 0, 0);
    const boxBg = createSolid(box, theme.colors.surfaceDeep);
    boxBg.SetAllPoints(box);
    const boxOutline = createOutline(box, theme.colors.borderStrong);

    const check = box.CreateTexture(undefined, "OVERLAY");
    check.SetTexture("Interface\\Buttons\\UI-CheckBox-Check");
    check.SetPoint("TOPLEFT", box, "TOPLEFT", -3, 3);
    check.SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", 3, -3);
    check.SetVertexColor(theme.colors.success[0], theme.colors.success[1], theme.colors.success[2], 1);

    const text = createText(frame, label, "GameFontHighlightSmall");
    text.SetPoint("LEFT", box, "RIGHT", 10, 0);

    function refresh(): void {
        const enabled = getValue();
        if (enabled) {
            check.Show();
            setTextureColor(boxBg, theme.colors.surfaceBlue);
            boxOutline.setColor(theme.colors.success);
            text.SetTextColor(theme.colors.text[0], theme.colors.text[1], theme.colors.text[2], 1);
        } else {
            check.Hide();
            setTextureColor(boxBg, theme.colors.surfaceDeep);
            boxOutline.setColor(theme.colors.borderStrong);
            text.SetTextColor(theme.colors.muted[0], theme.colors.muted[1], theme.colors.muted[2], 1);
        }
    }

    frame.SetScript("OnMouseDown", () => { setValue(!getValue()); refresh(); });
    refresh();
    return { frame, refresh: () => refresh() };
}

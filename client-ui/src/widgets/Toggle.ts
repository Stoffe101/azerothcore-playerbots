import { createPanel, createSolid, createText, withAlpha } from "../core/Native";
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
    frame.SetHeight(32);
    frame.EnableMouse(true);

    const track = createPanel(frame, theme.colors.surfaceDeep, theme.colors.borderStrong);
    track.frame.SetSize(42, 22);
    track.frame.SetPoint("LEFT", frame, "LEFT", 0, 0);

    const trackGlow = createSolid(track.frame, withAlpha(theme.colors.success, 0.12), "ARTWORK");
    trackGlow.SetAllPoints(track.frame);
    trackGlow.Hide();

    const knob = createPanel(track.frame, theme.colors.muted, theme.colors.borderStrong);
    knob.frame.SetSize(16, 16);
    knob.frame.SetPoint("LEFT", track.frame, "LEFT", 3, 0);

    const text = createText(frame, label, "GameFontHighlightSmall");
    text.SetPoint("LEFT", track.frame, "RIGHT", 10, 0);

    function refresh(): void {
        const enabled = getValue();
        knob.frame.ClearAllPoints();
        if (enabled) {
            knob.frame.SetPoint("RIGHT", track.frame, "RIGHT", -3, 0);
            knob.setBackground(theme.colors.success);
            knob.outline.setColor(theme.colors.success);
            track.outline.setColor(theme.colors.success);
            trackGlow.Show();
            text.SetTextColor(theme.colors.text[0], theme.colors.text[1], theme.colors.text[2], 1);
        } else {
            knob.frame.SetPoint("LEFT", track.frame, "LEFT", 3, 0);
            knob.setBackground(theme.colors.muted);
            knob.outline.setColor(theme.colors.borderStrong);
            track.outline.setColor(theme.colors.borderStrong);
            trackGlow.Hide();
            text.SetTextColor(theme.colors.muted[0], theme.colors.muted[1], theme.colors.muted[2], 1);
        }
    }

    frame.SetScript("OnMouseDown", () => {
        setValue(!getValue());
        refresh();
    });

    refresh();
    return { frame, refresh: () => refresh() };
}

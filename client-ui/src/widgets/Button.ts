import { createOutline, createSolid, createText, setTextureColor, withAlpha } from "../core/Native";
import { Color, theme } from "../theme/Theme";

export interface ButtonOptions {
    text: string;
    width: number;
    height: number;
    onClick?: () => void;
    accent?: Color;
    icon?: string;
    iconSize?: number;
    emphasis?: boolean;
}

export interface UIButton {
    readonly frame: WoWFrame;
    readonly label: WoWFontString;
    readonly icon?: WoWTexture;
    setSelected(selected: boolean): void;
    setEnabled(enabled: boolean): void;
    setText(text: string): void;
}

export function createButton(parent: WoWFrame, options: ButtonOptions): UIButton {
    const frame = CreateFrame("Button", undefined, parent);
    frame.SetSize(options.width, options.height);
    frame.EnableMouse(true);

    const accent = options.accent ?? theme.colors.primary;
    const background = createSolid(frame, options.emphasis === true ? theme.colors.surfaceBlue : theme.colors.surfaceRaised);
    background.SetAllPoints(frame);
    const outline = createOutline(frame, options.emphasis === true ? accent : theme.colors.border);

    const selectedWash = createSolid(frame, withAlpha(accent, 0.10), "ARTWORK");
    selectedWash.SetAllPoints(frame);
    selectedWash.Hide();

    const label = createText(frame, options.text, options.height >= 34 ? "GameFontHighlight" : "GameFontHighlightSmall");
    let icon: WoWTexture | undefined;
    if (options.icon !== undefined) {
        icon = frame.CreateTexture(undefined, "ARTWORK");
        const iconSize = options.iconSize ?? Math.min(22, options.height - 12);
        icon.SetSize(iconSize, iconSize);
        icon.SetPoint("LEFT", frame, "LEFT", 10, 0);
        icon.SetTexture(options.icon);
        icon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
        label.SetPoint("LEFT", icon, "RIGHT", 8, 0);
        label.SetPoint("RIGHT", frame, "RIGHT", -8, 0);
        label.SetJustifyH("LEFT");
    } else {
        label.SetPoint("CENTER", frame, "CENTER", 0, 0);
        label.SetJustifyH("CENTER");
    }

    let selected = false;
    let enabled = true;
    let hovered = false;

    function render(): void {
        frame.SetAlpha(enabled ? 1 : 0.38);
        if (selected) {
            setTextureColor(background, theme.colors.surfaceBlue);
            outline.setColor(accent);
            selectedWash.Show();
        } else {
            selectedWash.Hide();
            setTextureColor(background, hovered && enabled ? theme.colors.surfaceHover : (options.emphasis === true ? theme.colors.surfaceBlue : theme.colors.surfaceRaised));
            outline.setColor(options.emphasis === true ? accent : (hovered && enabled ? theme.colors.borderStrong : theme.colors.border));
        }
        const color = selected ? accent : theme.colors.text;
        label.SetTextColor(color[0], color[1], color[2], enabled ? 1 : 0.72);
    }

    frame.SetScript("OnEnter", () => { hovered = true; render(); });
    frame.SetScript("OnLeave", () => { hovered = false; render(); });
    frame.SetScript("OnMouseDown", () => {
        if (enabled && options.onClick !== undefined) options.onClick();
    });

    render();
    return {
        frame,
        label,
        icon,
        setSelected(value: boolean): void { selected = value; render(); },
        setEnabled(value: boolean): void { enabled = value; render(); },
        setText(value: string): void { label.SetText(value); },
    };
}

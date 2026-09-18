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
    const topTint = createSolid(frame, withAlpha(accent, options.emphasis === true ? 0.22 : 0.075), "ARTWORK");
    topTint.SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1);
    topTint.SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1);
    topTint.SetHeight(Math.max(2, Math.floor(options.height * 0.46)));
    const bottomShade = createSolid(frame, withAlpha(theme.colors.shadow, 0.48), "ARTWORK");
    bottomShade.SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1);
    bottomShade.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1);
    bottomShade.SetHeight(Math.max(1, Math.floor(options.height * 0.24)));

    const outline = createOutline(frame, options.emphasis === true ? accent : theme.colors.border);
    const activeEdge = createSolid(frame, accent, "OVERLAY");
    activeEdge.SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
    activeEdge.SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0);
    activeEdge.SetWidth(3);
    activeEdge.Hide();

    const activeTop = createSolid(frame, withAlpha(accent, 0.88), "OVERLAY");
    activeTop.SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1);
    activeTop.SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1);
    activeTop.SetHeight(1);
    activeTop.Hide();

    const innerFrame = CreateFrame("Frame", undefined, frame);
    innerFrame.SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3);
    innerFrame.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3);
    const innerOutline = createOutline(innerFrame, withAlpha(accent, 0.62));
    innerFrame.Hide();

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

    function render(): void {
        frame.SetAlpha(enabled ? 1 : 0.42);
        const emphasized = options.emphasis === true;
        outline.setColor(selected || emphasized ? accent : theme.colors.border);
        setTextureColor(background, selected || emphasized ? theme.colors.surfaceBlue : theme.colors.surfaceRaised);
        setTextureColor(topTint, withAlpha(accent, selected ? 0.28 : (emphasized ? 0.22 : 0.075)));
        if (selected) {
            activeEdge.Show();
            activeTop.Show();
        } else {
            activeEdge.Hide();
            activeTop.Hide();
        }
        if (selected || emphasized) {
            innerOutline.setColor(withAlpha(accent, selected ? 0.95 : 0.68));
            innerFrame.Show();
        } else innerFrame.Hide();
        const color = selected ? accent : theme.colors.text;
        label.SetTextColor(color[0], color[1], color[2], 1);
    }

    frame.SetScript("OnEnter", () => {
        if (enabled && !selected) {
            setTextureColor(background, theme.colors.surfaceHover);
            setTextureColor(topTint, withAlpha(accent, 0.16));
            outline.setColor(options.emphasis === true ? accent : theme.colors.borderStrong);
            innerOutline.setColor(withAlpha(accent, 0.58));
            innerFrame.Show();
        }
    });
    frame.SetScript("OnLeave", () => render());
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

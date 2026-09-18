import { createOutline, createSolid, createText, setTextureColor } from "../core/Native";
import { Color, theme } from "../theme/Theme";

export interface ButtonOptions {
    text: string;
    width: number;
    height: number;
    onClick?: () => void;
    accent?: Color;
}

export interface UIButton {
    readonly frame: WoWFrame;
    readonly label: WoWFontString;
    setSelected(selected: boolean): void;
    setEnabled(enabled: boolean): void;
    setText(text: string): void;
}

export function createButton(parent: WoWFrame, options: ButtonOptions): UIButton {
    const frame = CreateFrame("Button", undefined, parent);
    frame.SetSize(options.width, options.height);
    frame.EnableMouse(true);

    const background = createSolid(frame, theme.colors.surfaceRaised);
    background.SetAllPoints(frame);
    const outline = createOutline(frame, theme.colors.border);
    const label = createText(frame, options.text, options.height >= 34 ? "GameFontHighlight" : "GameFontHighlightSmall");
    label.SetPoint("CENTER", frame, "CENTER", 0, 0);
    label.SetJustifyH("CENTER");

    let selected = false;
    let enabled = true;
    const accent = options.accent ?? theme.colors.primary;

    function render(): void {
        frame.SetAlpha(enabled ? 1 : 0.48);
        outline.setColor(selected ? accent : theme.colors.border);
        setTextureColor(background, selected ? theme.colors.surfaceHover : theme.colors.surfaceRaised);
        const color = selected ? accent : theme.colors.text;
        label.SetTextColor(color[0], color[1], color[2], 1);
    }

    frame.SetScript("OnEnter", () => {
        if (enabled && !selected) {
            setTextureColor(background, theme.colors.surfaceHover);
            outline.setColor(theme.colors.borderStrong);
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
        setSelected(value: boolean): void { selected = value; render(); },
        setEnabled(value: boolean): void { enabled = value; render(); },
        setText(value: string): void { label.SetText(value); },
    };
}

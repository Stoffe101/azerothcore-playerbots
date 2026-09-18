import { createPanel, createText } from "../core/Native";
import { theme } from "../theme/Theme";
import { createButton } from "./Button";

export interface Modal {
    readonly frame: WoWFrame;
    readonly content: WoWFrame;
    show(): void;
    hide(): void;
    setTitle(title: string): void;
    setSubtitle(subtitle: string): void;
}

export function createModal(parent: WoWFrame, width: number, height: number): Modal {
    const panel = createPanel(parent, theme.colors.background, theme.colors.borderStrong);
    panel.frame.SetSize(width, height);
    panel.frame.SetPoint("CENTER", parent, "CENTER", 0, 0);
    panel.frame.SetFrameStrata("DIALOG");

    const title = createText(panel.frame, "Choose Build", "GameFontNormalLarge");
    title.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", theme.spacing.lg, -theme.spacing.lg);
    const subtitle = createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted);
    subtitle.SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -theme.spacing.xs);

    const close = createButton(panel.frame, {
        text: "X", width: 30, height: 30, accent: theme.colors.error,
        onClick: () => panel.frame.Hide(),
    });
    close.frame.SetPoint("TOPRIGHT", panel.frame, "TOPRIGHT", -theme.spacing.md, -theme.spacing.md);

    const content = CreateFrame("Frame", undefined, panel.frame);
    content.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", theme.spacing.lg, -72);
    content.SetPoint("BOTTOMRIGHT", panel.frame, "BOTTOMRIGHT", -theme.spacing.lg, theme.spacing.lg);
    panel.frame.Hide();

    return {
        frame: panel.frame,
        content,
        show(): void { panel.frame.Show(); },
        hide(): void { panel.frame.Hide(); },
        setTitle(value: string): void { title.SetText(value); },
        setSubtitle(value: string): void { subtitle.SetText(value); },
    };
}

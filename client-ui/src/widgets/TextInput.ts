import { createPanel, createSolid, withAlpha } from "../core/Native";
import { theme } from "../theme/Theme";

export interface TextInput {
    readonly frame: WoWFrame;
    readonly editBox: WoWEditBox;
    getText(): string;
    setText(value: string): void;
    clear(): void;
}

export function createTextInput(parent: WoWFrame, width: number, height = 36): TextInput {
    const panel = createPanel(parent, theme.colors.surfaceDeep, theme.colors.borderStrong);
    panel.frame.SetSize(width, height);

    const focusGlow = createSolid(panel.frame, withAlpha(theme.colors.primary, 0.10), "ARTWORK");
    focusGlow.SetAllPoints(panel.frame);
    focusGlow.Hide();

    const edit = CreateFrame("EditBox", undefined, panel.frame);
    edit.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 1, -1);
    edit.SetPoint("BOTTOMRIGHT", panel.frame, "BOTTOMRIGHT", -1, 1);
    edit.SetAutoFocus(false);
    edit.SetFontObject(GameFontHighlightSmall);
    edit.SetTextColor(theme.colors.text[0], theme.colors.text[1], theme.colors.text[2], 1);
    edit.SetTextInsets(10, 10, 0, 0);
    edit.SetScript("OnEditFocusGained", () => {
        panel.outline.setColor(theme.colors.primary);
        focusGlow.Show();
    });
    edit.SetScript("OnEditFocusLost", () => {
        panel.outline.setColor(theme.colors.borderStrong);
        focusGlow.Hide();
    });

    return {
        frame: panel.frame,
        editBox: edit,
        getText(): string { return edit.GetText() ?? ""; },
        setText(value: string): void { edit.SetText(value); },
        clear(): void { edit.SetText(""); edit.ClearFocus(); },
    };
}

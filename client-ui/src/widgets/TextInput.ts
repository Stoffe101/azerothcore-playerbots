import { createPanel } from "../core/Native";
import { theme } from "../theme/Theme";

export interface TextInput {
    readonly frame: WoWFrame;
    readonly editBox: WoWEditBox;
    getText(): string;
    setText(value: string): void;
    clear(): void;
}

export function createTextInput(parent: WoWFrame, width: number, height = 34): TextInput {
    const panel = createPanel(parent, theme.colors.background, theme.colors.borderStrong);
    panel.frame.SetSize(width, height);

    const edit = CreateFrame("EditBox", undefined, panel.frame);
    edit.SetAllPoints(panel.frame);
    edit.SetAutoFocus(false);
    edit.SetTextInsets(10, 10, 0, 0);

    return {
        frame: panel.frame,
        editBox: edit,
        getText(): string { return edit.GetText() ?? ""; },
        setText(value: string): void { edit.SetText(value); },
        clear(): void { edit.SetText(""); edit.ClearFocus(); },
    };
}

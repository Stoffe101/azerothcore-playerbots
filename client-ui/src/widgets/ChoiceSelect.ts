import { createIcon, createPanel, createText } from "../core/Native";
import { theme } from "../theme/Theme";
import { createButton, UIButton } from "./Button";

export interface ChoiceItem {
    value: string | number;
    label: string;
    icon?: string;
}

export interface ChoiceSelect {
    readonly frame: WoWFrame;
    refresh: () => void;
    close: () => void;
}

export interface ChoiceSelectOptions {
    width: number;
    maxVisible?: number;
    getItems(): ChoiceItem[];
    getValue(): string | number;
    onChange(value: string | number): void;
}

let activePopup: WoWFrame | undefined;

function closeActive(): void {
    if (activePopup !== undefined) {
        activePopup.Hide();
        activePopup = undefined;
    }
}

export function closeChoicePopup(): void {
    closeActive();
}

export function createChoiceSelect(parent: WoWFrame, options: ChoiceSelectOptions): ChoiceSelect {
    const trigger = createButton(parent, { text: "Select", width: options.width, height: 34 });
    trigger.label.ClearAllPoints();
    trigger.label.SetPoint("LEFT", trigger.frame, "LEFT", 12, 0);
    trigger.label.SetPoint("RIGHT", trigger.frame, "RIGHT", -28, 0);
    trigger.label.SetJustifyH("LEFT");

    const arrow = createText(trigger.frame, "v", "GameFontHighlightSmall", theme.colors.muted);
    arrow.SetPoint("RIGHT", trigger.frame, "RIGHT", -10, 0);

    const popup = createPanel(trigger.frame, theme.colors.background, theme.colors.borderStrong);
    popup.frame.SetFrameStrata("TOOLTIP");
    popup.frame.SetWidth(options.width);
    popup.frame.EnableMouseWheel(true);
    popup.frame.Hide();

    const maxVisible = options.maxVisible ?? 9;
    let offset = 0;
    const rows: UIButton[] = [];

    const scrollHint = createText(popup.frame, "Mouse wheel for more", "GameFontHighlightSmall", theme.colors.muted);
    scrollHint.SetPoint("BOTTOMLEFT", popup.frame, "BOTTOMLEFT", 10, 6);
    scrollHint.Hide();

    function refreshRows(): void {
        const items = options.getItems();
        const visible = Math.min(maxVisible, items.length);
        const hasMore = items.length > maxVisible;
        popup.frame.SetHeight(Math.max(12, visible * 32 + 8 + (hasMore ? 22 : 0)));
        if (hasMore) scrollHint.Show();
        else scrollHint.Hide();

        for (let i = 0; i < maxVisible; i += 1) {
            let row = rows[i];
            if (row === undefined) {
                row = createButton(popup.frame, { text: "", width: options.width - 8, height: 28 });
                row.frame.SetPoint("TOPLEFT", popup.frame, "TOPLEFT", 4, -(4 + i * 32));
                row.label.ClearAllPoints();
                row.label.SetPoint("LEFT", row.frame, "LEFT", 10, 0);
                row.label.SetPoint("RIGHT", row.frame, "RIGHT", -8, 0);
                row.label.SetJustifyH("LEFT");
                rows[i] = row;
            }

            const item = items[offset + i];
            if (item !== undefined) {
                row.setText(item.label);
                row.setSelected(item.value === options.getValue());
                const value = item.value;
                row.frame.SetScript("OnMouseDown", () => {
                    options.onChange(value);
                    closeActive();
                    refresh();
                });
                row.frame.Show();
            } else {
                row.frame.Hide();
            }
        }
    }

    function refresh(): void {
        const value = options.getValue();
        let label = "Select";
        for (const item of options.getItems()) {
            if (item.value === value) {
                label = item.label;
                break;
            }
        }
        trigger.setText(label);
        refreshRows();
    }

    function open(): void {
        closeActive();
        offset = 0;
        refreshRows();
        popup.frame.ClearAllPoints();
        popup.frame.SetPoint("TOPLEFT", trigger.frame, "BOTTOMLEFT", 0, -4);
        popup.frame.Show();
        activePopup = popup.frame;
    }

    trigger.frame.SetScript("OnMouseDown", () => {
        if (popup.frame.IsShown()) closeActive();
        else open();
    });

    popup.frame.SetScript("OnMouseWheel", (_frame, delta) => {
        const items = options.getItems();
        const maxOffset = Math.max(0, items.length - maxVisible);
        offset = Math.max(0, Math.min(maxOffset, offset - Number(delta)));
        refreshRows();
    });

    refresh();

    return {
        frame: trigger.frame,
        refresh: () => refresh(),
        close: (): void => {
            if (popup.frame.IsShown()) closeActive();
        },
    };
}

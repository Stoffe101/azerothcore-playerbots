import { createPanel, createSolid, createText } from "../core/Native";
import { theme } from "../theme/Theme";
import { createButton, UIButton } from "./Button";

export interface ChoiceItem {
    value: string | number;
    label: string;
    detail?: string;
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

interface ChoiceRow {
    button: UIButton;
    detail: WoWFontString;
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
    const trigger = createButton(parent, { text: "Select", width: options.width, height: 36 });
    trigger.label.ClearAllPoints();
    trigger.label.SetPoint("LEFT", trigger.frame, "LEFT", 12, 0);
    trigger.label.SetPoint("RIGHT", trigger.frame, "RIGHT", -32, 0);
    trigger.label.SetJustifyH("LEFT");

    const arrow = createText(trigger.frame, "v", "GameFontHighlightSmall", theme.colors.muted);
    arrow.SetPoint("RIGHT", trigger.frame, "RIGHT", -11, 0);

    const popup = createPanel(trigger.frame, theme.colors.background, theme.colors.borderStrong);
    popup.frame.SetFrameStrata("TOOLTIP");
    popup.frame.SetWidth(options.width);
    popup.frame.EnableMouseWheel(true);
    popup.frame.Hide();

    const maxVisible = options.maxVisible ?? 8;
    const rowHeight = 48;
    const railWidth = 24;
    let offset = 0;
    const rows: ChoiceRow[] = [];

    const rail = createPanel(popup.frame, theme.colors.surface, theme.colors.border);
    rail.frame.SetPoint("TOPRIGHT", popup.frame, "TOPRIGHT", -4, -4);
    rail.frame.SetPoint("BOTTOMRIGHT", popup.frame, "BOTTOMRIGHT", -4, 4);
    rail.frame.SetWidth(railWidth);

    function move(delta: number): void {
        const items = options.getItems();
        const maxOffset = Math.max(0, items.length - maxVisible);
        offset = Math.max(0, Math.min(maxOffset, offset + delta));
        refreshRows();
    }

    const up = createButton(rail.frame, { text: "^", width: 20, height: 22, onClick: () => move(-1) });
    up.frame.SetPoint("TOP", rail.frame, "TOP", 0, -2);
    const down = createButton(rail.frame, { text: "v", width: 20, height: 22, onClick: () => move(1) });
    down.frame.SetPoint("BOTTOM", rail.frame, "BOTTOM", 0, 2);

    const track = createSolid(rail.frame, theme.colors.borderStrong, "ARTWORK");
    track.SetPoint("TOP", up.frame, "BOTTOM", 0, -4);
    track.SetPoint("BOTTOM", down.frame, "TOP", 0, 4);
    track.SetWidth(4);

    const thumb = createSolid(rail.frame, theme.colors.primary, "OVERLAY");
    thumb.SetWidth(6);
    thumb.SetHeight(22);

    function refreshRail(): void {
        const items = options.getItems();
        const maxOffset = Math.max(0, items.length - maxVisible);
        const canScroll = maxOffset > 0;
        up.setEnabled(canScroll && offset > 0);
        down.setEnabled(canScroll && offset < maxOffset);

        if (!canScroll) {
            rail.frame.Hide();
            return;
        }
        rail.frame.Show();

        const popupHeight = popup.frame.GetHeight ? popup.frame.GetHeight() : (maxVisible * rowHeight + 8);
        const trackHeight = Math.max(36, popupHeight - 58);
        const thumbHeight = Math.max(22, Math.floor(trackHeight * Math.min(1, maxVisible / items.length)));
        const travel = Math.max(0, trackHeight - thumbHeight);
        const ratio = maxOffset > 0 ? offset / maxOffset : 0;
        thumb.SetHeight(thumbHeight);
        thumb.ClearAllPoints();
        thumb.SetPoint("TOP", up.frame, "BOTTOM", 0, -(4 + travel * ratio));
        thumb.Show();
    }

    function refreshRows(): void {
        const items = options.getItems();
        const visible = Math.min(maxVisible, items.length);
        popup.frame.SetHeight(Math.max(16, visible * rowHeight + 8));

        for (let i = 0; i < maxVisible; i += 1) {
            let row = rows[i];
            if (row === undefined) {
                const button = createButton(popup.frame, {
                    text: "",
                    width: options.width - railWidth - 12,
                    height: rowHeight - 4,
                });
                button.frame.SetPoint("TOPLEFT", popup.frame, "TOPLEFT", 4, -(4 + i * rowHeight));
                button.label.ClearAllPoints();
                button.label.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 10, -7);
                button.label.SetPoint("RIGHT", button.frame, "RIGHT", -8, 7);
                button.label.SetJustifyH("LEFT");

                const detail = createText(button.frame, "", "GameFontHighlightSmall", theme.colors.muted);
                detail.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 10, -25);
                detail.SetPoint("RIGHT", button.frame, "RIGHT", -8, 0);
                detail.SetJustifyH("LEFT");
                row = { button, detail };
                rows[i] = row;
            }

            const item = items[offset + i];
            if (item !== undefined) {
                row.button.setText(item.label);
                row.detail.SetText(item.detail ?? "");
                row.button.setSelected(item.value === options.getValue());
                const value = item.value;
                row.button.frame.SetScript("OnMouseDown", () => {
                    options.onChange(value);
                    closeActive();
                    refresh();
                });
                row.button.frame.Show();
            } else {
                row.button.frame.Hide();
            }
        }
        refreshRail();
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
        const items = options.getItems();
        const selected = options.getValue();
        let selectedIndex = 0;
        for (let i = 0; i < items.length; i += 1) {
            if (items[i].value === selected) {
                selectedIndex = i;
                break;
            }
        }
        const maxOffset = Math.max(0, items.length - maxVisible);
        offset = Math.max(0, Math.min(maxOffset, selectedIndex - Math.floor(maxVisible / 2)));
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
        move(Number(delta) > 0 ? -1 : 1);
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

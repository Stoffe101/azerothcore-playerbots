import { createChrome, createFramedIcon, createPanel, createSolid, createText, withAlpha } from "../core/Native";
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
    iconFrame: WoWFrame;
    icon: WoWTexture;
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
    const trigger = createButton(parent, { text: "Select", width: options.width, height: 40, accent: theme.colors.primary });
    const triggerIcon = createFramedIcon(trigger.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 28, theme.colors.borderStrong);
    triggerIcon.frame.SetPoint("LEFT", trigger.frame, "LEFT", 8, 0);
    triggerIcon.frame.Hide();

    const arrowBox = createPanel(trigger.frame, theme.colors.surfaceDeep, theme.colors.border);
    arrowBox.frame.SetSize(28, 28);
    arrowBox.frame.SetPoint("RIGHT", trigger.frame, "RIGHT", -6, 0);
    const arrow = createText(arrowBox.frame, "v", "GameFontHighlightSmall", theme.colors.primary);
    arrow.SetPoint("CENTER", arrowBox.frame, "CENTER", 0, 0);
    arrow.SetJustifyH("CENTER");

    const popup = createPanel(trigger.frame, theme.colors.background, theme.colors.borderStrong);
    popup.frame.SetFrameStrata("TOOLTIP");
    popup.frame.SetWidth(options.width);
    popup.frame.EnableMouseWheel(true);
    createChrome(popup.frame, theme.colors.borderStrong);
    popup.frame.Hide();

    const maxVisible = options.maxVisible ?? 8;
    const rowHeight = 54;
    const railWidth = 26;
    let offset = 0;
    const rows: ChoiceRow[] = [];

    const rail = createPanel(popup.frame, theme.colors.surfaceDeep, theme.colors.border);
    rail.frame.SetPoint("TOPRIGHT", popup.frame, "TOPRIGHT", -4, -4);
    rail.frame.SetPoint("BOTTOMRIGHT", popup.frame, "BOTTOMRIGHT", -4, 4);
    rail.frame.SetWidth(railWidth);

    function move(delta: number): void {
        const items = options.getItems();
        const maxOffset = Math.max(0, items.length - maxVisible);
        offset = Math.max(0, Math.min(maxOffset, offset + delta));
        refreshRows();
    }

    function wheel(_frame: WoWFrame, delta: number): void {
        move(Number(delta) > 0 ? -1 : 1);
    }

    function bindWheel(target: WoWFrame): void {
        target.EnableMouseWheel(true);
        target.SetScript("OnMouseWheel", wheel);
    }

    const up = createButton(rail.frame, { text: "^", width: 20, height: 22, accent: theme.colors.primary, onClick: () => move(-1) });
    up.frame.SetPoint("TOP", rail.frame, "TOP", 0, -2);
    const down = createButton(rail.frame, { text: "v", width: 20, height: 22, accent: theme.colors.primary, onClick: () => move(1) });
    down.frame.SetPoint("BOTTOM", rail.frame, "BOTTOM", 0, 2);

    const track = createSolid(rail.frame, theme.colors.borderStrong, "ARTWORK");
    track.SetPoint("TOP", up.frame, "BOTTOM", 0, -4);
    track.SetPoint("BOTTOM", down.frame, "TOP", 0, 4);
    track.SetWidth(3);

    const trackGlow = createSolid(rail.frame, withAlpha(theme.colors.primary, 0.12), "ARTWORK");
    trackGlow.SetPoint("TOP", up.frame, "BOTTOM", 0, -4);
    trackGlow.SetPoint("BOTTOM", down.frame, "TOP", 0, 4);
    trackGlow.SetWidth(7);

    const thumb = createSolid(rail.frame, theme.colors.primary, "OVERLAY");
    thumb.SetWidth(7);
    thumb.SetHeight(22);
    const thumbCore = createSolid(rail.frame, theme.colors.highlight, "OVERLAY");
    thumbCore.SetWidth(3);
    thumbCore.SetHeight(18);

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

        const popupHeight = popup.frame.GetHeight();
        const trackHeight = Math.max(36, popupHeight - 58);
        const thumbHeight = Math.max(22, Math.floor(trackHeight * Math.min(1, maxVisible / items.length)));
        const travel = Math.max(0, trackHeight - thumbHeight);
        const ratio = maxOffset > 0 ? offset / maxOffset : 0;
        thumb.SetHeight(thumbHeight);
        thumb.ClearAllPoints();
        thumb.SetPoint("TOP", up.frame, "BOTTOM", 0, -(4 + travel * ratio));
        thumbCore.SetHeight(Math.max(12, thumbHeight - 4));
        thumbCore.ClearAllPoints();
        thumbCore.SetPoint("CENTER", thumb, "CENTER", 0, 0);
        thumb.Show();
        thumbCore.Show();
    }

    function positionRowLabel(row: ChoiceRow, hasIcon: boolean): void {
        row.button.label.ClearAllPoints();
        row.button.label.SetPoint("TOPLEFT", row.button.frame, "TOPLEFT", hasIcon ? 50 : 10, -8);
        row.button.label.SetPoint("RIGHT", row.button.frame, "RIGHT", -8, 7);
        row.button.label.SetJustifyH("LEFT");
        row.detail.ClearAllPoints();
        row.detail.SetPoint("TOPLEFT", row.button.frame, "TOPLEFT", hasIcon ? 50 : 10, -29);
        row.detail.SetPoint("RIGHT", row.button.frame, "RIGHT", -8, 0);
        row.detail.SetJustifyH("LEFT");
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
                    accent: theme.colors.primary,
                });
                button.frame.SetPoint("TOPLEFT", popup.frame, "TOPLEFT", 4, -(4 + i * rowHeight));

                const iconFrame = createFramedIcon(button.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 34, theme.colors.borderStrong);
                iconFrame.frame.SetPoint("LEFT", button.frame, "LEFT", 8, 0);
                iconFrame.frame.Hide();

                const detail = createText(button.frame, "", "GameFontHighlightSmall", theme.colors.muted);
                bindWheel(button.frame);
                row = { button, detail, iconFrame: iconFrame.frame, icon: iconFrame.icon };
                rows[i] = row;
            }

            const item = items[offset + i];
            if (item !== undefined) {
                const hasIcon = item.icon !== undefined && item.icon !== "";
                row.button.setText(item.label);
                row.detail.SetText(item.detail ?? "");
                row.button.setSelected(item.value === options.getValue());
                positionRowLabel(row, hasIcon);
                if (hasIcon) {
                    row.icon.SetTexture(String(item.icon));
                    row.icon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
                    row.iconFrame.Show();
                } else row.iconFrame.Hide();

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
        let selectedItem: ChoiceItem | undefined;
        for (const item of options.getItems()) {
            if (item.value === value) {
                selectedItem = item;
                break;
            }
        }

        trigger.setText(selectedItem?.label ?? "Select");
        const hasIcon = selectedItem?.icon !== undefined && selectedItem.icon !== "";
        trigger.label.ClearAllPoints();
        trigger.label.SetPoint("LEFT", trigger.frame, "LEFT", hasIcon ? 44 : 12, 0);
        trigger.label.SetPoint("RIGHT", trigger.frame, "RIGHT", -42, 0);
        trigger.label.SetJustifyH("LEFT");
        if (hasIcon) {
            triggerIcon.icon.SetTexture(String(selectedItem?.icon));
            triggerIcon.icon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            triggerIcon.frame.Show();
        } else triggerIcon.frame.Hide();

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
        popup.frame.SetPoint("TOPLEFT", trigger.frame, "BOTTOMLEFT", 0, -5);
        popup.frame.Show();
        activePopup = popup.frame;
    }

    trigger.frame.SetScript("OnMouseDown", () => {
        if (popup.frame.IsShown()) closeActive();
        else open();
    });

    bindWheel(popup.frame);
    bindWheel(rail.frame);
    bindWheel(up.frame);
    bindWheel(down.frame);

    refresh();

    return {
        frame: trigger.frame,
        refresh: () => refresh(),
        close: (): void => {
            if (popup.frame.IsShown()) closeActive();
        },
    };
}

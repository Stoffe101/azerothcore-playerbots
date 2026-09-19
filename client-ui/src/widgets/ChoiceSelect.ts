import { createFramedIcon, createPanel, createSolid, createText, withAlpha } from "../core/Native";
import { theme } from "../theme/Theme";
import { createButton, UIButton } from "./Button";

export interface ChoiceItem { value: string | number; label: string; detail?: string; icon?: string; }
export interface ChoiceSelect { readonly frame: WoWFrame; refresh: () => void; close: () => void; }
export interface ChoiceSelectOptions {
    width: number;
    maxVisible?: number;
    getItems(): ChoiceItem[];
    getValue(): string | number;
    onChange(value: string | number): void;
}
interface ChoiceRow { button: UIButton; detail: WoWFontString; iconFrame: WoWFrame; icon: WoWTexture; }

let activePopup: WoWFrame | undefined;
function closeActive(): void { if (activePopup !== undefined) { activePopup.Hide(); activePopup = undefined; } }
export function closeChoicePopup(): void { closeActive(); }

export function createChoiceSelect(parent: WoWFrame, options: ChoiceSelectOptions): ChoiceSelect {
    const trigger = createButton(parent, { text: "Select", width: options.width, height: 38, accent: theme.colors.primary });
    const triggerIcon = createFramedIcon(trigger.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 26, theme.colors.borderStrong);
    triggerIcon.frame.SetPoint("LEFT", trigger.frame, "LEFT", 8, 0);
    triggerIcon.frame.Hide();
    const arrow = createText(trigger.frame, "v", "GameFontHighlightSmall", theme.colors.primary);
    arrow.SetPoint("RIGHT", trigger.frame, "RIGHT", -12, 0);
    arrow.SetJustifyH("CENTER");

    const popup = createPanel(trigger.frame, theme.colors.background, theme.colors.borderStrong);
    popup.frame.SetFrameStrata("TOOLTIP");
    popup.frame.SetWidth(options.width);
    popup.frame.EnableMouseWheel(true);
    popup.frame.Hide();

    const maxVisible = options.maxVisible ?? 8;
    const rowHeight = 48;
    const railWidth = 14;
    let offset = 0;
    const rows: ChoiceRow[] = [];

    const rail = CreateFrame("Frame", undefined, popup.frame);
    rail.SetPoint("TOPRIGHT", popup.frame, "TOPRIGHT", -2, -2);
    rail.SetPoint("BOTTOMRIGHT", popup.frame, "BOTTOMRIGHT", -2, 2);
    rail.SetWidth(railWidth);
    const railBg = createSolid(rail, withAlpha(theme.colors.surfaceDeep, 0.78));
    railBg.SetAllPoints(rail);

    function move(delta: number): void {
        const items = options.getItems();
        const maxOffset = Math.max(0, items.length - maxVisible);
        offset = Math.max(0, Math.min(maxOffset, offset + delta));
        refreshRows();
    }
    function wheel(this: void, _frame: WoWFrame, delta: number): void { move(Number(delta) > 0 ? -1 : 1); }
    function bindWheel(target: WoWFrame): void { target.EnableMouseWheel(true); target.SetScript("OnMouseWheel", wheel); }

    const up = createButton(rail, { text: "^", width: railWidth, height: 18, accent: theme.colors.primary, flat: true, onClick: () => move(-1) });
    up.frame.SetPoint("TOP", rail, "TOP", 0, 0);
    const down = createButton(rail, { text: "v", width: railWidth, height: 18, accent: theme.colors.primary, flat: true, onClick: () => move(1) });
    down.frame.SetPoint("BOTTOM", rail, "BOTTOM", 0, 0);
    const track = createSolid(rail, theme.colors.borderStrong, "ARTWORK");
    track.SetPoint("TOP", up.frame, "BOTTOM", 0, -3);
    track.SetPoint("BOTTOM", down.frame, "TOP", 0, 3);
    track.SetWidth(2);
    const thumb = createSolid(rail, theme.colors.primary, "OVERLAY");
    thumb.SetWidth(5); thumb.SetHeight(22);

    function refreshRail(): void {
        const items = options.getItems();
        const maxOffset = Math.max(0, items.length - maxVisible);
        if (maxOffset <= 0) { rail.Hide(); return; }
        rail.Show();
        up.setEnabled(offset > 0);
        down.setEnabled(offset < maxOffset);
        const popupHeight = popup.frame.GetHeight();
        const trackHeight = Math.max(30, popupHeight - 42);
        const thumbHeight = Math.max(20, Math.floor(trackHeight * Math.min(1, maxVisible / items.length)));
        const travel = Math.max(0, trackHeight - thumbHeight);
        const ratio = maxOffset > 0 ? offset / maxOffset : 0;
        thumb.SetHeight(thumbHeight);
        thumb.ClearAllPoints();
        thumb.SetPoint("TOP", up.frame, "BOTTOM", 0, -(3 + travel * ratio));
    }

    function positionRowLabel(row: ChoiceRow, hasIcon: boolean): void {
        row.button.label.ClearAllPoints();
        row.button.label.SetPoint("TOPLEFT", row.button.frame, "TOPLEFT", hasIcon ? 48 : 10, -7);
        row.button.label.SetPoint("RIGHT", row.button.frame, "RIGHT", -8, 7);
        row.button.label.SetJustifyH("LEFT");
        row.detail.ClearAllPoints();
        row.detail.SetPoint("TOPLEFT", row.button.frame, "TOPLEFT", hasIcon ? 48 : 10, -26);
        row.detail.SetPoint("RIGHT", row.button.frame, "RIGHT", -8, 0);
        row.detail.SetJustifyH("LEFT");
    }

    function refreshRows(): void {
        const items = options.getItems();
        const visible = Math.min(maxVisible, items.length);
        popup.frame.SetHeight(Math.max(12, visible * rowHeight + 4));
        for (let i = 0; i < maxVisible; i += 1) {
            let row = rows[i];
            if (row === undefined) {
                const button = createButton(popup.frame, { text: "", width: options.width - railWidth - 6, height: rowHeight - 2, accent: theme.colors.primary, flat: true });
                button.frame.SetPoint("TOPLEFT", popup.frame, "TOPLEFT", 2, -(2 + i * rowHeight));
                const iconFrame = createFramedIcon(button.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 32, theme.colors.borderStrong);
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
                row.button.frame.SetScript("OnMouseDown", () => { options.onChange(value); closeActive(); refresh(); });
                row.button.frame.Show();
            } else row.button.frame.Hide();
        }
        refreshRail();
    }

    function refresh(): void {
        const value = options.getValue();
        let selectedItem: ChoiceItem | undefined;
        for (const item of options.getItems()) if (item.value === value) { selectedItem = item; break; }

        trigger.setText(selectedItem?.label ?? "Select");
        const hasIcon = selectedItem?.icon !== undefined && selectedItem.icon !== "";
        trigger.label.ClearAllPoints();
        trigger.label.SetPoint("LEFT", trigger.frame, "LEFT", hasIcon ? 42 : 12, 0);
        trigger.label.SetPoint("RIGHT", trigger.frame, "RIGHT", -32, 0);
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
        for (let i = 0; i < items.length; i += 1) if (items[i].value === selected) { selectedIndex = i; break; }
        const maxOffset = Math.max(0, items.length - maxVisible);
        offset = Math.max(0, Math.min(maxOffset, selectedIndex - Math.floor(maxVisible / 2)));
        refreshRows();
        popup.frame.ClearAllPoints();
        popup.frame.SetPoint("TOPLEFT", trigger.frame, "BOTTOMLEFT", 0, -3);
        popup.frame.Show();
        activePopup = popup.frame;
    }

    trigger.frame.SetScript("OnMouseDown", () => { if (popup.frame.IsShown()) closeActive(); else open(); });
    bindWheel(popup.frame); bindWheel(rail); bindWheel(up.frame); bindWheel(down.frame);
    refresh();

    return {
        frame: trigger.frame,
        refresh: () => refresh(),
        close: () => { if (activePopup === popup.frame) closeActive(); else popup.frame.Hide(); },
    };
}

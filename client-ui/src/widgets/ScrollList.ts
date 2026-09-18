import { createSolid, withAlpha } from "../core/Native";
import { theme } from "../theme/Theme";
import { createButton } from "./Button";

export interface ScrollList {
    readonly frame: WoWFrame;
    readonly content: WoWFrame;
    setContentHeight(height: number): void;
    scrollBy(delta: number): void;
    scrollToTop(): void;
    scrollToBottom(): void;
    bindWheel(target: WoWFrame): void;
    reset(): void;
}

export function createScrollList(parent: WoWFrame, width: number, height: number): ScrollList {
    const frame = CreateFrame("Frame", undefined, parent);
    frame.SetSize(width, height);
    frame.EnableMouseWheel(true);

    const railWidth = 14;
    const scroll = CreateFrame("ScrollFrame", undefined, frame);
    scroll.SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
    scroll.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -railWidth - 2, 0);
    scroll.SetSize(Math.max(1, width - railWidth - 2), height);
    scroll.EnableMouseWheel(true);

    const content = CreateFrame("Frame", undefined, scroll);
    content.SetWidth(Math.max(1, width - railWidth - 2));
    content.SetHeight(height);
    content.EnableMouseWheel(true);
    scroll.SetScrollChild(content);

    const rail = CreateFrame("Frame", undefined, frame);
    rail.SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0);
    rail.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0);
    rail.SetWidth(railWidth);
    rail.EnableMouseWheel(true);
    const railBg = createSolid(rail, withAlpha(theme.colors.surfaceDeep, 0.72));
    railBg.SetAllPoints(rail);

    let contentHeight = height;
    let offset = 0;
    function maxOffset(): number { return Math.max(0, contentHeight - height); }
    function clamp(value: number): number { return Math.max(0, Math.min(maxOffset(), value)); }
    function scrollBy(delta: number): void {
        offset = clamp(offset + delta);
        scroll.SetVerticalScroll(offset);
        refreshRail();
    }
    function wheel(this: void, _target: WoWFrame, delta: number): void { scrollBy(Number(delta) > 0 ? -64 : 64); }
    function bindWheel(target: WoWFrame): void {
        target.EnableMouseWheel(true);
        target.SetScript("OnMouseWheel", wheel);
    }

    const up = createButton(rail, { text: "^", width: railWidth, height: 18, accent: theme.colors.primary, onClick: () => scrollBy(-64) });
    up.frame.SetPoint("TOP", rail, "TOP", 0, 0);
    const down = createButton(rail, { text: "v", width: railWidth, height: 18, accent: theme.colors.primary, onClick: () => scrollBy(64) });
    down.frame.SetPoint("BOTTOM", rail, "BOTTOM", 0, 0);

    const track = createSolid(rail, theme.colors.borderStrong, "ARTWORK");
    track.SetPoint("TOP", up.frame, "BOTTOM", 0, -3);
    track.SetPoint("BOTTOM", down.frame, "TOP", 0, 3);
    track.SetWidth(2);
    const thumb = createSolid(rail, theme.colors.primary, "OVERLAY");
    thumb.SetWidth(5);
    thumb.SetHeight(24);

    function refreshRail(): void {
        const range = maxOffset();
        if (range <= 0) {
            offset = 0;
            scroll.SetVerticalScroll(0);
            rail.Hide();
            return;
        }
        rail.Show();
        offset = clamp(offset);
        scroll.SetVerticalScroll(offset);
        const trackHeight = Math.max(28, height - 42);
        const thumbHeight = Math.max(22, Math.floor(trackHeight * Math.min(1, height / contentHeight)));
        const travel = Math.max(0, trackHeight - thumbHeight);
        const ratio = range > 0 ? offset / range : 0;
        thumb.SetHeight(thumbHeight);
        thumb.ClearAllPoints();
        thumb.SetPoint("TOP", up.frame, "BOTTOM", 0, -(3 + travel * ratio));
        up.setEnabled(offset > 0);
        down.setEnabled(offset < range);
    }

    bindWheel(frame); bindWheel(scroll); bindWheel(content); bindWheel(rail); bindWheel(up.frame); bindWheel(down.frame);

    return {
        frame,
        content,
        setContentHeight(value: number): void {
            contentHeight = Math.max(height, value);
            content.SetHeight(contentHeight);
            offset = clamp(offset);
            scroll.SetVerticalScroll(offset);
            refreshRail();
        },
        scrollBy: (delta: number): void => scrollBy(delta),
        scrollToTop(): void { offset = 0; scroll.SetVerticalScroll(0); refreshRail(); },
        scrollToBottom(): void { offset = maxOffset(); scroll.SetVerticalScroll(offset); refreshRail(); },
        bindWheel: (target: WoWFrame): void => bindWheel(target),
        reset(): void { offset = 0; scroll.SetVerticalScroll(0); refreshRail(); },
    };
}

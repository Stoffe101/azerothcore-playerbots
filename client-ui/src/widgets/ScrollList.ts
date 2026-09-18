import { createPanel, createSolid, withAlpha } from "../core/Native";
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

    const scroll = CreateFrame("ScrollFrame", undefined, frame);
    scroll.SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
    scroll.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 0);
    scroll.SetSize(Math.max(1, width - 22), height);
    scroll.EnableMouseWheel(true);

    const content = CreateFrame("Frame", undefined, scroll);
    content.SetWidth(Math.max(1, width - 22));
    content.SetHeight(height);
    content.EnableMouseWheel(true);
    scroll.SetScrollChild(content);

    const rail = createPanel(frame, theme.colors.surfaceDeep, theme.colors.border);
    rail.frame.SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0);
    rail.frame.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0);
    rail.frame.SetWidth(18);
    rail.frame.EnableMouseWheel(true);

    let contentHeight = height;
    let offset = 0;

    function maxOffset(): number {
        return Math.max(0, contentHeight - height);
    }

    function clamp(value: number): number {
        return Math.max(0, Math.min(maxOffset(), value));
    }

    function scrollBy(delta: number): void {
        offset = clamp(offset + delta);
        scroll.SetVerticalScroll(offset);
        refreshRail();
    }

    function wheel(_target: WoWFrame, delta: number): void {
        scrollBy(Number(delta) > 0 ? -72 : 72);
    }

    function bindWheel(target: WoWFrame): void {
        target.EnableMouseWheel(true);
        target.SetScript("OnMouseWheel", wheel);
    }

    const up = createButton(rail.frame, { text: "^", width: 18, height: 22, accent: theme.colors.primary, onClick: () => scrollBy(-72) });
    up.frame.SetPoint("TOP", rail.frame, "TOP", 0, 0);
    const down = createButton(rail.frame, { text: "v", width: 18, height: 22, accent: theme.colors.primary, onClick: () => scrollBy(72) });
    down.frame.SetPoint("BOTTOM", rail.frame, "BOTTOM", 0, 0);

    const trackGlow = createSolid(rail.frame, withAlpha(theme.colors.primary, 0.11), "ARTWORK");
    trackGlow.SetPoint("TOP", up.frame, "BOTTOM", 0, -4);
    trackGlow.SetPoint("BOTTOM", down.frame, "TOP", 0, 4);
    trackGlow.SetWidth(7);

    const track = createSolid(rail.frame, theme.colors.borderStrong, "ARTWORK");
    track.SetPoint("TOP", up.frame, "BOTTOM", 0, -4);
    track.SetPoint("BOTTOM", down.frame, "TOP", 0, 4);
    track.SetWidth(3);

    const thumb = createSolid(rail.frame, theme.colors.primary, "OVERLAY");
    thumb.SetWidth(8);
    thumb.SetHeight(24);
    const thumbCore = createSolid(rail.frame, theme.colors.highlight, "OVERLAY");
    thumbCore.SetWidth(3);
    thumbCore.SetHeight(20);

    function refreshRail(): void {
        const range = maxOffset();
        if (range <= 0) {
            offset = 0;
            scroll.SetVerticalScroll(0);
            rail.frame.Hide();
            return;
        }

        rail.frame.Show();
        offset = clamp(offset);
        scroll.SetVerticalScroll(offset);

        const trackHeight = Math.max(28, height - 52);
        const thumbHeight = Math.max(24, Math.floor(trackHeight * Math.min(1, height / contentHeight)));
        const travel = Math.max(0, trackHeight - thumbHeight);
        const ratio = range > 0 ? offset / range : 0;

        thumb.SetHeight(thumbHeight);
        thumb.ClearAllPoints();
        thumb.SetPoint("TOP", up.frame, "BOTTOM", 0, -(4 + travel * ratio));
        thumbCore.SetHeight(Math.max(14, thumbHeight - 4));
        thumbCore.ClearAllPoints();
        thumbCore.SetPoint("CENTER", thumb, "CENTER", 0, 0);
        up.setEnabled(offset > 0);
        down.setEnabled(offset < range);
    }

    bindWheel(frame);
    bindWheel(scroll);
    bindWheel(content);
    bindWheel(rail.frame);
    bindWheel(up.frame);
    bindWheel(down.frame);

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
        scrollToTop(): void {
            offset = 0;
            scroll.SetVerticalScroll(0);
            refreshRail();
        },
        scrollToBottom(): void {
            offset = maxOffset();
            scroll.SetVerticalScroll(offset);
            refreshRail();
        },
        bindWheel: (target: WoWFrame): void => bindWheel(target),
        reset(): void {
            offset = 0;
            scroll.SetVerticalScroll(0);
            refreshRail();
        },
    };
}

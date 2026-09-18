import { createPanel, createSolid } from "../core/Native";
import { theme } from "../theme/Theme";
import { createButton } from "./Button";

export interface ScrollList {
    readonly frame: WoWFrame;
    readonly content: WoWFrame;
    setContentHeight(height: number): void;
    scrollBy(delta: number): void;
    scrollToTop(): void;
    scrollToBottom(): void;
    reset(): void;
}

export function createScrollList(parent: WoWFrame, width: number, height: number): ScrollList {
    const frame = CreateFrame("Frame", undefined, parent);
    frame.SetSize(width, height);
    frame.EnableMouseWheel(true);

    const scroll = CreateFrame("ScrollFrame", undefined, frame);
    scroll.SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
    scroll.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 0);
    scroll.EnableMouseWheel(true);

    const content = CreateFrame("Frame", undefined, scroll);
    content.SetWidth(Math.max(1, width - 20));
    content.SetHeight(height);
    scroll.SetScrollChild(content);

    const rail = createPanel(frame, theme.colors.background, theme.colors.border);
    rail.frame.SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0);
    rail.frame.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0);
    rail.frame.SetWidth(16);

    function clamp(value: number): number {
        return Math.max(0, Math.min(scroll.GetVerticalScrollRange(), value));
    }

    function refreshRail(): void {
        const range = scroll.GetVerticalScrollRange();
        if (range <= 0) {
            rail.frame.Hide();
            return;
        }
        rail.frame.Show();
        const current = clamp(scroll.GetVerticalScroll());
        const trackHeight = Math.max(28, height - 48);
        const contentHeight = height + range;
        const thumbHeight = Math.max(24, Math.floor(trackHeight * Math.min(1, height / contentHeight)));
        const travel = Math.max(0, trackHeight - thumbHeight);
        const ratio = range > 0 ? current / range : 0;

        thumb.SetHeight(thumbHeight);
        thumb.ClearAllPoints();
        thumb.SetPoint("TOP", up.frame, "BOTTOM", 0, -(4 + travel * ratio));
        up.setEnabled(current > 0);
        down.setEnabled(current < range);
    }

    function scrollBy(delta: number): void {
        scroll.SetVerticalScroll(clamp(scroll.GetVerticalScroll() + delta));
        refreshRail();
    }

    const up = createButton(rail.frame, { text: "^", width: 16, height: 20, onClick: () => scrollBy(-92) });
    up.frame.SetPoint("TOP", rail.frame, "TOP", 0, 0);
    const down = createButton(rail.frame, { text: "v", width: 16, height: 20, onClick: () => scrollBy(92) });
    down.frame.SetPoint("BOTTOM", rail.frame, "BOTTOM", 0, 0);

    const track = createSolid(rail.frame, theme.colors.borderStrong, "ARTWORK");
    track.SetPoint("TOP", up.frame, "BOTTOM", 0, -4);
    track.SetPoint("BOTTOM", down.frame, "TOP", 0, 4);
    track.SetWidth(3);

    const thumb = createSolid(rail.frame, theme.colors.primary, "OVERLAY");
    thumb.SetWidth(7);
    thumb.SetHeight(24);

    function wheel(_frame: WoWFrame, delta: number): void {
        scrollBy(Number(delta) > 0 ? -92 : 92);
    }
    frame.SetScript("OnMouseWheel", wheel);
    scroll.SetScript("OnMouseWheel", wheel);

    return {
        frame,
        content,
        setContentHeight(value: number): void {
            content.SetHeight(Math.max(height, value));
            scroll.SetVerticalScroll(clamp(scroll.GetVerticalScroll()));
            refreshRail();
        },
        scrollBy: (delta: number): void => scrollBy(delta),
        scrollToTop(): void {
            scroll.SetVerticalScroll(0);
            refreshRail();
        },
        scrollToBottom(): void {
            scroll.SetVerticalScroll(scroll.GetVerticalScrollRange());
            refreshRail();
        },
        reset(): void {
            scroll.SetVerticalScroll(0);
            refreshRail();
        },
    };
}

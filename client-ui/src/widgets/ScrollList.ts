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
    const scroll = CreateFrame("ScrollFrame", undefined, parent);
    scroll.SetSize(width, height);
    scroll.EnableMouseWheel(true);

    const content = CreateFrame("Frame", undefined, scroll);
    content.SetWidth(width);
    content.SetHeight(height);
    scroll.SetScrollChild(content);

    function clamp(value: number): number {
        return Math.max(0, Math.min(scroll.GetVerticalScrollRange(), value));
    }

    function scrollBy(delta: number): void {
        scroll.SetVerticalScroll(clamp(scroll.GetVerticalScroll() + delta));
    }

    scroll.SetScript("OnMouseWheel", (_frame, delta) => {
        // WotLK reports positive delta for wheel-up and negative for wheel-down.
        // Use a fixed step so odd mouse drivers / high-resolution wheels cannot jump past content.
        const direction = Number(delta) > 0 ? -1 : 1;
        scrollBy(direction * 76);
    });

    return {
        frame: scroll,
        content,
        setContentHeight(value: number): void {
            content.SetHeight(Math.max(height, value));
            scroll.SetVerticalScroll(clamp(scroll.GetVerticalScroll()));
        },
        scrollBy: (delta: number): void => scrollBy(delta),
        scrollToTop(): void { scroll.SetVerticalScroll(0); },
        scrollToBottom(): void { scroll.SetVerticalScroll(scroll.GetVerticalScrollRange()); },
        reset(): void { scroll.SetVerticalScroll(0); },
    };
}

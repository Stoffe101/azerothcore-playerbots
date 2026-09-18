export interface ScrollList {
    readonly frame: WoWFrame;
    readonly content: WoWFrame;
    setContentHeight(height: number): void;
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

    scroll.SetScript("OnMouseWheel", (_frame, delta) => {
        const next = scroll.GetVerticalScroll() - Number(delta) * 38;
        scroll.SetVerticalScroll(Math.max(0, Math.min(scroll.GetVerticalScrollRange(), next)));
    });

    return {
        frame: scroll,
        content,
        setContentHeight(value: number): void {
            content.SetHeight(Math.max(height, value));
            scroll.SetVerticalScroll(Math.min(scroll.GetVerticalScroll(), scroll.GetVerticalScrollRange()));
        },
        reset(): void { scroll.SetVerticalScroll(0); },
    };
}

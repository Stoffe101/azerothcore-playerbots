export type StackDirection = "horizontal" | "vertical";

export interface StackOptions {
    direction?: StackDirection;
    gap?: number;
    padding?: number;
}

export interface Stack {
    readonly frame: WoWFrame;
    add(child: WoWRegion, width: number, height: number): void;
    reset(): void;
}

export function createStack(parent: WoWFrame, options: StackOptions = {}): Stack {
    const frame = CreateFrame("Frame", undefined, parent);
    const direction = options.direction ?? "vertical";
    const gap = options.gap ?? 0;
    const padding = options.padding ?? 0;
    let cursor = 0;

    return {
        frame,
        add(child: WoWRegion, width: number, height: number): void {
            child.ClearAllPoints();
            if (direction === "horizontal") {
                child.SetPoint("TOPLEFT", frame, "TOPLEFT", padding + cursor, -padding);
                cursor += width + gap;
            } else {
                child.SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -(padding + cursor));
                cursor += height + gap;
            }
        },
        reset(): void { cursor = 0; },
    };
}

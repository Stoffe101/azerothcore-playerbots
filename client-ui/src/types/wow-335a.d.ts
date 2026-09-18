type WoWFramePoint =
    | "TOP" | "RIGHT" | "BOTTOM" | "LEFT"
    | "TOPRIGHT" | "TOPLEFT" | "BOTTOMLEFT" | "BOTTOMRIGHT" | "CENTER";

type WoWDrawLayer = "BACKGROUND" | "BORDER" | "ARTWORK" | "OVERLAY" | "HIGHLIGHT";
type WoWFrameStrata = "BACKGROUND" | "LOW" | "MEDIUM" | "HIGH" | "DIALOG" | "FULLSCREEN" | "FULLSCREEN_DIALOG" | "TOOLTIP";

interface WoWRegion {
    ClearAllPoints(this: WoWRegion): void;
    Hide(this: WoWRegion): void;
    Show(this: WoWRegion): void;
    IsShown(this: WoWRegion): boolean;
    SetAlpha(this: WoWRegion, alpha: number): void;
    SetAllPoints(this: WoWRegion, relativeTo?: WoWRegion): void;
    SetHeight(this: WoWRegion, height: number): void;
    SetWidth(this: WoWRegion, width: number): void;
    SetSize(this: WoWRegion, width: number, height: number): void;
    GetWidth(this: WoWRegion): number;
    GetHeight(this: WoWRegion): number;
    SetScale(this: WoWRegion, scale: number): void;
    SetPoint(this: WoWRegion, point: WoWFramePoint): void;
    SetPoint(this: WoWRegion, point: WoWFramePoint, x: number, y: number): void;
    SetPoint(this: WoWRegion, point: WoWFramePoint, relativeTo: WoWRegion, relativePoint: WoWFramePoint, x: number, y: number): void;
}

interface WoWTexture extends WoWRegion {
    SetTexture(this: WoWTexture, path: string | number): void;
    SetTexture(this: WoWTexture, red: number, green: number, blue: number, alpha?: number): void;
    SetTexCoord(this: WoWTexture, left: number, right: number, top: number, bottom: number): void;
    SetVertexColor(this: WoWTexture, red: number, green: number, blue: number, alpha?: number): void;
}

interface WoWFontString extends WoWRegion {
    SetText(this: WoWFontString, text: string): void;
    GetText(this: WoWFontString): string | undefined;
    SetTextColor(this: WoWFontString, red: number, green: number, blue: number, alpha?: number): void;
    SetJustifyH(this: WoWFontString, value: "LEFT" | "CENTER" | "RIGHT"): void;
    SetJustifyV(this: WoWFontString, value: "TOP" | "MIDDLE" | "BOTTOM"): void;
}

interface WoWFrame extends WoWRegion {
    CreateTexture(this: WoWFrame, name?: string, layer?: WoWDrawLayer): WoWTexture;
    CreateFontString(this: WoWFrame, name?: string, layer?: WoWDrawLayer, template?: string): WoWFontString;
    EnableMouse(this: WoWFrame, enabled: boolean): void;
    EnableMouseWheel(this: WoWFrame, enabled: boolean): void;
    SetFrameStrata(this: WoWFrame, strata: WoWFrameStrata): void;
    SetFrameLevel(this: WoWFrame, level: number): void;
    GetFrameLevel(this: WoWFrame): number;
    SetMovable(this: WoWFrame, enabled: boolean): void;
    SetClampedToScreen(this: WoWFrame, enabled: boolean): void;
    RegisterForDrag(this: WoWFrame, button: string): void;
    StartMoving(this: WoWFrame): void;
    StopMovingOrSizing(this: WoWFrame): void;
    SetScrollChild(this: WoWFrame, child: WoWFrame): void;
    GetVerticalScroll(this: WoWFrame): number;
    GetVerticalScrollRange(this: WoWFrame): number;
    SetVerticalScroll(this: WoWFrame, value: number): void;
    SetScript(this: WoWFrame, event: string, handler?: (frame: WoWFrame, ...args: any[]) => void): void;
}

interface WoWEditBox extends WoWFrame {
    SetAutoFocus(this: WoWEditBox, enabled: boolean): void;
    SetText(this: WoWEditBox, value: string): void;
    GetText(this: WoWEditBox): string;
    HighlightText(this: WoWEditBox, start?: number, finish?: number): void;
    ClearFocus(this: WoWEditBox): void;
    SetTextInsets(this: WoWEditBox, left: number, right: number, top: number, bottom: number): void;
}

declare function CreateFrame(this: void, frameType: "EditBox", name?: string, parent?: WoWFrame, template?: string): WoWEditBox;
declare function CreateFrame(this: void, frameType: string, name?: string, parent?: WoWFrame, template?: string): WoWFrame;
declare const UIParent: WoWFrame;
declare const CLASS_ICON_TCOORDS: Record<string, number[]>;
declare const RAID_CLASS_COLORS: Record<string, { r: number; g: number; b: number }>;
declare const UISpecialFrames: string[] | undefined;
declare const _G: Record<string, any>;

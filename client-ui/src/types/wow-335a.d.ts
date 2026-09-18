/** @noSelfInFile */

type WoWFramePoint =
    | "TOP" | "RIGHT" | "BOTTOM" | "LEFT"
    | "TOPRIGHT" | "TOPLEFT" | "BOTTOMLEFT" | "BOTTOMRIGHT" | "CENTER";

type WoWDrawLayer = "BACKGROUND" | "BORDER" | "ARTWORK" | "OVERLAY" | "HIGHLIGHT";
type WoWFrameStrata = "BACKGROUND" | "LOW" | "MEDIUM" | "HIGH" | "DIALOG" | "FULLSCREEN" | "FULLSCREEN_DIALOG" | "TOOLTIP";

interface WoWRegion {
    ClearAllPoints(): void;
    Hide(): void;
    Show(): void;
    IsShown(): boolean;
    SetAlpha(alpha: number): void;
    SetAllPoints(relativeTo?: WoWRegion): void;
    SetHeight(height: number): void;
    SetWidth(width: number): void;
    SetSize(width: number, height: number): void;
    SetPoint(point: WoWFramePoint): void;
    SetPoint(point: WoWFramePoint, x: number, y: number): void;
    SetPoint(point: WoWFramePoint, relativeTo: WoWRegion, relativePoint: WoWFramePoint, x: number, y: number): void;
}

interface WoWTexture extends WoWRegion {
    SetTexture(path: string | number): void;
    SetTexture(red: number, green: number, blue: number, alpha?: number): void;
    SetTexCoord(left: number, right: number, top: number, bottom: number): void;
    SetVertexColor(red: number, green: number, blue: number, alpha?: number): void;
}

interface WoWFontString extends WoWRegion {
    SetText(text: string): void;
    SetTextColor(red: number, green: number, blue: number, alpha?: number): void;
    SetJustifyH(value: "LEFT" | "CENTER" | "RIGHT"): void;
    SetJustifyV(value: "TOP" | "MIDDLE" | "BOTTOM"): void;
}

interface WoWFrame extends WoWRegion {
    CreateTexture(name?: string, layer?: WoWDrawLayer): WoWTexture;
    CreateFontString(name?: string, layer?: WoWDrawLayer, template?: string): WoWFontString;
    EnableMouse(enabled: boolean): void;
    EnableMouseWheel(enabled: boolean): void;
    SetFrameStrata(strata: WoWFrameStrata): void;
    SetFrameLevel(level: number): void;
    GetFrameLevel(): number;
    SetScript(event: string, handler?: (frame: WoWFrame, ...args: any[]) => void): void;
}

declare function CreateFrame(frameType: string, name?: string, parent?: WoWFrame, template?: string): WoWFrame;
declare const UIParent: WoWFrame;
declare const CLASS_ICON_TCOORDS: Record<string, number[]>;
declare const RAID_CLASS_COLORS: Record<string, { r: number; g: number; b: number }>;
declare const _G: Record<string, any>;

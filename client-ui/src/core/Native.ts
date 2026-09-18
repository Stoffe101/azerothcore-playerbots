import { Color, theme } from "../theme/Theme";

export const CLASS_ICON_ATLAS = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes";

export function setTextureColor(texture: WoWTexture, color: Color): void {
    texture.SetTexture(color[0], color[1], color[2], color[3]);
}

export function createSolid(parent: WoWFrame, color: Color, layer: WoWDrawLayer = "BACKGROUND"): WoWTexture {
    const texture = parent.CreateTexture(undefined, layer);
    setTextureColor(texture, color);
    return texture;
}

export function createText(
    parent: WoWFrame,
    value: string,
    template = "GameFontHighlightSmall",
    color: Color = theme.colors.text,
): WoWFontString {
    const text = parent.CreateFontString(undefined, "OVERLAY", template);
    text.SetText(value);
    text.SetTextColor(color[0], color[1], color[2], color[3]);
    text.SetJustifyH("LEFT");
    text.SetJustifyV("MIDDLE");
    return text;
}

export interface Outline {
    readonly textures: WoWTexture[];
    setColor(color: Color): void;
}

export function createOutline(frame: WoWFrame, initial: Color = theme.colors.border): Outline {
    const top = createSolid(frame, initial, "BORDER");
    const bottom = createSolid(frame, initial, "BORDER");
    const left = createSolid(frame, initial, "BORDER");
    const right = createSolid(frame, initial, "BORDER");

    top.SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
    top.SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0);
    top.SetHeight(1);
    bottom.SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0);
    bottom.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0);
    bottom.SetHeight(1);
    left.SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
    left.SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0);
    left.SetWidth(1);
    right.SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0);
    right.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0);
    right.SetWidth(1);

    const textures = [top, bottom, left, right];
    return {
        textures,
        setColor(color: Color): void {
            for (const texture of textures) setTextureColor(texture, color);
        },
    };
}

export interface Panel {
    readonly frame: WoWFrame;
    readonly background: WoWTexture;
    readonly outline: Outline;
    setBackground(color: Color): void;
}

export function createPanel(
    parent: WoWFrame,
    backgroundColor: Color = theme.colors.surface,
    borderColor: Color = theme.colors.border,
): Panel {
    const frame = CreateFrame("Frame", undefined, parent);
    const background = createSolid(frame, backgroundColor);
    background.SetAllPoints(frame);
    const outline = createOutline(frame, borderColor);
    return {
        frame,
        background,
        outline,
        setBackground(color: Color): void { setTextureColor(background, color); },
    };
}

export function createIcon(parent: WoWFrame, path: string, size: number): WoWTexture {
    const icon = parent.CreateTexture(undefined, "ARTWORK");
    icon.SetTexture(path);
    icon.SetSize(size, size);
    icon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
    return icon;
}

export function setClassIcon(texture: WoWTexture, classToken: string): void {
    texture.SetTexture(CLASS_ICON_ATLAS);
    const coords = CLASS_ICON_TCOORDS[classToken];
    if (coords !== undefined && coords.length >= 4) texture.SetTexCoord(coords[0], coords[1], coords[2], coords[3]);
    else texture.SetTexCoord(0, 1, 0, 1);
}

export function classColor(classToken: string): Color {
    const color = RAID_CLASS_COLORS[classToken];
    if (color !== undefined) return [color.r, color.g, color.b, 1] as Color;
    return theme.colors.primary;
}

import { Color, theme } from "../theme/Theme";

export const CLASS_ICON_ATLAS = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes";

const ROLE_ICON_TEXTURES: Record<string, string> = {
    TANK: "Interface\\Icons\\Ability_Warrior_DefensiveStance",
    HEALER: "Interface\\Icons\\Spell_Holy_HolyBolt",
    DPS: "Interface\\Icons\\Ability_DualWield",
};

export function setTextureColor(texture: WoWTexture, color: Color): void {
    texture.SetTexture(color[0], color[1], color[2], color[3]);
}

export function withAlpha(color: Color, alpha: number): Color {
    return [color[0], color[1], color[2], alpha] as Color;
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

export interface FramedIcon {
    readonly frame: WoWFrame;
    readonly icon: WoWTexture;
    readonly outline: Outline;
}

export function createFramedIcon(
    parent: WoWFrame,
    path: string,
    size: number,
    borderColor: Color = theme.colors.borderStrong,
): FramedIcon {
    const frame = CreateFrame("Frame", undefined, parent);
    frame.SetSize(size, size);
    const bg = createSolid(frame, theme.colors.surfaceDeep);
    bg.SetAllPoints(frame);
    const outline = createOutline(frame, borderColor);

    const icon = frame.CreateTexture(undefined, "ARTWORK");
    icon.SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3);
    icon.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3);
    icon.SetTexture(path);
    icon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
    return { frame, icon, outline };
}

export function createChrome(frame: WoWFrame, accent: Color = theme.colors.chrome, ornate = false): void {
    createOutline(frame, accent);
    if (!ornate) return;

    const corner = 12;
    const thickness = 2;
    const pieces: Array<[WoWFramePoint, number, number, number, number]> = [
        ["TOPLEFT", 2, -2, corner, thickness],
        ["TOPLEFT", 2, -2, thickness, corner],
        ["TOPRIGHT", -2, -2, corner, thickness],
        ["TOPRIGHT", -2, -2, thickness, corner],
        ["BOTTOMLEFT", 2, 2, corner, thickness],
        ["BOTTOMLEFT", 2, 2, thickness, corner],
        ["BOTTOMRIGHT", -2, 2, corner, thickness],
        ["BOTTOMRIGHT", -2, 2, thickness, corner],
    ];
    for (let i = 0; i < pieces.length; i += 1) {
        const item = pieces[i];
        const piece = createSolid(frame, i % 2 === 0 ? theme.colors.chromeBright : accent, "OVERLAY");
        piece.SetSize(item[3], item[4]);
        piece.SetPoint(item[0], frame, item[0], item[1], item[2]);
    }
}

export function setRoleIcon(texture: WoWTexture, role: string): void {
    texture.SetTexture(ROLE_ICON_TEXTURES[role] ?? ROLE_ICON_TEXTURES.DPS);
    texture.SetTexCoord(0.08, 0.92, 0.08, 0.92);
}

export function createFramedRoleIcon(
    parent: WoWFrame,
    role: string,
    size: number,
    borderColor: Color = theme.colors.borderStrong,
): FramedIcon {
    const framed = createFramedIcon(parent, ROLE_ICON_TEXTURES[role] ?? ROLE_ICON_TEXTURES.DPS, size, borderColor);
    setRoleIcon(framed.icon, role);
    return framed;
}

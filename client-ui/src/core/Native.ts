import { Color, theme } from "../theme/Theme";

export const CLASS_ICON_ATLAS = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes";
export const ROLE_ICON_ATLAS = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES";

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
    readonly topSheen: WoWTexture;
    readonly bottomShade: WoWTexture;
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

    // Cheap native-frame bevel: a cool highlight on top and a dark shadow on the bottom.
    // This stays entirely within 3.3.5 texture primitives while giving panels the same depth
    // language as the visual target.
    const topSheen = createSolid(frame, withAlpha(theme.colors.highlight, 0.075), "ARTWORK");
    topSheen.SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1);
    topSheen.SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1);
    topSheen.SetHeight(1);
    const bottomShade = createSolid(frame, withAlpha(theme.colors.shadow, 0.56), "ARTWORK");
    bottomShade.SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1);
    bottomShade.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1);
    bottomShade.SetHeight(1);

    return {
        frame,
        background,
        outline,
        topSheen,
        bottomShade,
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

    const inner = createSolid(frame, withAlpha(theme.colors.highlight, 0.08), "ARTWORK");
    inner.SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2);
    inner.SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2);
    inner.SetHeight(1);

    const icon = frame.CreateTexture(undefined, "ARTWORK");
    icon.SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4);
    icon.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4);
    icon.SetTexture(path);
    icon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
    return { frame, icon, outline };
}

export function createChrome(frame: WoWFrame, accent: Color = theme.colors.chrome): void {
    // Double-line gold/blue chrome with L-shaped corners. No custom art files required.
    const outer = createOutline(frame, accent);
    const innerTop = createSolid(frame, withAlpha(theme.colors.highlight, 0.28), "BORDER");
    innerTop.SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4);
    innerTop.SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4);
    innerTop.SetHeight(1);
    const innerBottom = createSolid(frame, withAlpha(theme.colors.borderStrong, 0.72), "BORDER");
    innerBottom.SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 4, 4);
    innerBottom.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4);
    innerBottom.SetHeight(1);

    const corner = 12;
    const thickness = 2;
    const points: Array<[WoWFramePoint, number, number, number, number]> = [
        ["TOPLEFT", 2, -2, corner, thickness],
        ["TOPLEFT", 2, -2, thickness, corner],
        ["TOPRIGHT", -2, -2, corner, thickness],
        ["TOPRIGHT", -2, -2, thickness, corner],
        ["BOTTOMLEFT", 2, 2, corner, thickness],
        ["BOTTOMLEFT", 2, 2, thickness, corner],
        ["BOTTOMRIGHT", -2, 2, corner, thickness],
        ["BOTTOMRIGHT", -2, 2, thickness, corner],
    ];
    for (let i = 0; i < points.length; i += 1) {
        const item = points[i];
        const piece = createSolid(frame, i % 2 === 0 ? theme.colors.chromeBright : accent, "OVERLAY");
        piece.SetSize(item[3], item[4]);
        piece.SetPoint(item[0], frame, item[0], item[1], item[2]);
    }

    // Reuse Blizzard's own Wrath-era gold dialog ornament. Mirroring one native
    // corner texture keeps the shell ornate without shipping custom art.
    const cornerPath = "Interface\\DialogFrame\\UI-DialogBox-Gold-Corner";
    const topLeft = frame.CreateTexture(undefined, "OVERLAY");
    topLeft.SetTexture(cornerPath);
    topLeft.SetSize(26, 26);
    topLeft.SetPoint("TOPLEFT", frame, "TOPLEFT", -3, 3);
    topLeft.SetTexCoord(0, 1, 0, 1);

    const topRight = frame.CreateTexture(undefined, "OVERLAY");
    topRight.SetTexture(cornerPath);
    topRight.SetSize(26, 26);
    topRight.SetPoint("TOPRIGHT", frame, "TOPRIGHT", 3, 3);
    topRight.SetTexCoord(1, 0, 0, 1);

    const bottomLeft = frame.CreateTexture(undefined, "OVERLAY");
    bottomLeft.SetTexture(cornerPath);
    bottomLeft.SetSize(26, 26);
    bottomLeft.SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -3, -3);
    bottomLeft.SetTexCoord(0, 1, 1, 0);

    const bottomRight = frame.CreateTexture(undefined, "OVERLAY");
    bottomRight.SetTexture(cornerPath);
    bottomRight.SetSize(26, 26);
    bottomRight.SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 3, -3);
    bottomRight.SetTexCoord(1, 0, 1, 0);

    // Keep the outer outline referenced so TypeScriptToLua does not optimize the call away.
    if (outer.textures.length === 0) return;
}


export function setRoleIcon(texture: WoWTexture, role: string): void {
    texture.SetTexture(ROLE_ICON_ATLAS);
    if (role === "TANK") {
        texture.SetTexCoord(0, 0.296875, 0.34375, 0.640625);
    } else if (role === "HEALER") {
        texture.SetTexCoord(0.3125, 0.609375, 0.015625, 0.3125);
    } else {
        texture.SetTexCoord(0.3125, 0.609375, 0.34375, 0.640625);
    }
}

export function createFramedRoleIcon(
    parent: WoWFrame,
    role: string,
    size: number,
    borderColor: Color = theme.colors.borderStrong,
): FramedIcon {
    const framed = createFramedIcon(parent, ROLE_ICON_ATLAS, size, borderColor);
    setRoleIcon(framed.icon, role);
    return framed;
}

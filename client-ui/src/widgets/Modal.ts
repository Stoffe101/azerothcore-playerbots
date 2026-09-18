import { createChrome, createFramedIcon, createPanel, createSolid, createText, setRoleIcon } from "../core/Native";
import { theme } from "../theme/Theme";
import { createButton } from "./Button";

export interface Modal {
    readonly frame: WoWFrame;
    readonly content: WoWFrame;
    show(): void;
    hide(): void;
    setTitle(title: string): void;
    setSubtitle(subtitle: string): void;
    setHeaderIcon(path?: string): void;
    setHeaderRole(role?: string): void;
}

export function createModal(parent: WoWFrame, width: number, height: number): Modal {
    const scrim = CreateFrame("Frame", undefined, parent);
    scrim.SetAllPoints(parent);
    scrim.SetFrameStrata("DIALOG");
    scrim.SetFrameLevel(parent.GetFrameLevel() + 20);
    scrim.EnableMouse(true);
    const scrimTexture = createSolid(scrim, theme.colors.scrim);
    scrimTexture.SetAllPoints(scrim);

    const panel = createPanel(parent, theme.colors.background, theme.colors.borderStrong);
    panel.frame.SetSize(width, height);
    panel.frame.SetPoint("CENTER", parent, "CENTER", 0, 0);
    panel.frame.SetFrameStrata("DIALOG");
    panel.frame.SetFrameLevel(scrim.GetFrameLevel() + 1);
    createChrome(panel.frame);

    function hideModal(): void {
        panel.frame.Hide();
        scrim.Hide();
    }

    function showModal(): void {
        scrim.Show();
        panel.frame.Show();
    }

    scrim.SetScript("OnMouseDown", () => hideModal());

    const headerBg = createSolid(panel.frame, theme.colors.surface, "BACKGROUND");
    headerBg.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 3, -3);
    headerBg.SetPoint("TOPRIGHT", panel.frame, "TOPRIGHT", -3, -3);
    headerBg.SetHeight(66);
    const headerTint = createSolid(panel.frame, [0.02, 0.09, 0.15, 0.72], "ARTWORK");
    headerTint.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 4, -4);
    headerTint.SetPoint("TOPRIGHT", panel.frame, "TOPRIGHT", -4, -4);
    headerTint.SetHeight(34);
    const headerAccent = createSolid(panel.frame, theme.colors.primary, "ARTWORK");
    headerAccent.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 4, -4);
    headerAccent.SetPoint("TOPRIGHT", panel.frame, "TOPRIGHT", -4, -4);
    headerAccent.SetHeight(2);

    const headerIcon = createFramedIcon(panel.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 46, theme.colors.chrome);
    headerIcon.frame.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 16, -11);
    headerIcon.frame.Hide();

    const title = createText(panel.frame, "Choose Build", "GameFontNormalLarge");
    title.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", theme.spacing.lg, -12);
    const subtitle = createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted);
    subtitle.SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3);
    subtitle.SetWidth(width - 130);

    const close = createButton(panel.frame, {
        text: "X",
        width: 34,
        height: 34,
        accent: theme.colors.error,
        emphasis: true,
        onClick: () => hideModal(),
    });
    close.frame.SetPoint("TOPRIGHT", panel.frame, "TOPRIGHT", -theme.spacing.md, -theme.spacing.md);

    const content = CreateFrame("Frame", undefined, panel.frame);
    content.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", theme.spacing.lg, -80);
    content.SetPoint("BOTTOMRIGHT", panel.frame, "BOTTOMRIGHT", -theme.spacing.lg, theme.spacing.lg);

    panel.frame.Hide();
    scrim.Hide();

    return {
        frame: panel.frame,
        content,
        show(): void { showModal(); },
        hide(): void { hideModal(); },
        setTitle(value: string): void { title.SetText(value); },
        setSubtitle(value: string): void { subtitle.SetText(value); },
        setHeaderIcon(path?: string): void {
            if (path === undefined || path === "") {
                headerIcon.frame.Hide();
                title.ClearAllPoints();
                title.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", theme.spacing.lg, -12);
                return;
            }
            headerIcon.icon.SetTexture(path);
            headerIcon.icon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            headerIcon.frame.Show();
            title.ClearAllPoints();
            title.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 74, -12);
        },
        setHeaderRole(role?: string): void {
            if (role === undefined || role === "") {
                headerIcon.frame.Hide();
                title.ClearAllPoints();
                title.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", theme.spacing.lg, -12);
                return;
            }
            setRoleIcon(headerIcon.icon, role);
            headerIcon.frame.Show();
            title.ClearAllPoints();
            title.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 74, -12);
        },
    };
}

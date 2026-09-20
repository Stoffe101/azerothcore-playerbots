import * as Model from "../model/ComposerModel";
import * as Native from "../core/Native";
import { theme } from "../theme/Theme";
import * as ButtonUI from "../widgets/Button";
import * as ScrollUI from "../widgets/ScrollList";

interface RecommendationCard {
    panel: any;
    iconBadge: any;
    title: WoWFontString;
    meta: WoWFontString;
    reason: WoWFontString;
    readiness: WoWFontString;
    use: any;
}

export interface RecommendationsPage {
    readonly frame: WoWFrame;
    show(): void;
    hide(): void;
    refresh(): void;
}

export function createRecommendationsPage(parent: WoWFrame, onConfigure: () => void): RecommendationsPage {
    const root = Native.createPanel(parent, theme.colors.background, theme.colors.borderStrong);
    root.frame.SetPoint("TOPLEFT", parent, "TOPLEFT", 200, -88);
    root.frame.SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -16, 16);
    root.frame.Hide();

    const eyebrow = Native.createText(root.frame, "WHAT SHOULD WE DO?", "GameFontNormalSmall", theme.colors.muted);
    eyebrow.SetPoint("TOPLEFT", root.frame, "TOPLEFT", 22, -18);
    const title = Native.createText(root.frame, "Recommended Activities", "GameFontNormalLarge");
    title.SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -8);
    const subtitle = Native.createText(root.frame,
        "Suggestions come from the live realm era, your level, progression gates and activities you have not cleared yet.",
        "GameFontHighlightSmall", theme.colors.muted);
    subtitle.SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6);
    subtitle.SetWidth(1080);

    const realmText = Native.createText(root.frame, "", "GameFontHighlight", theme.colors.primary);
    realmText.SetPoint("TOPRIGHT", root.frame, "TOPRIGHT", -24, -28);
    realmText.SetWidth(300);
    realmText.SetJustifyH("RIGHT");

    const scroll = ScrollUI.createScrollList(root.frame, 1260, 690);
    scroll.frame.SetPoint("TOPLEFT", root.frame, "TOPLEFT", 22, -104);
    const cards: RecommendationCard[] = [];
    const empty = Native.createText(scroll.content, "No recommendations are available yet. Refresh after your progression changes.", "GameFontHighlight", theme.colors.muted);
    empty.SetPoint("TOPLEFT", scroll.content, "TOPLEFT", 24, -30);
    empty.SetWidth(1180);
    empty.SetJustifyH("CENTER");
    empty.Hide();

    function refresh(): void {
        const journey = Model.journey();
        realmText.SetText(String(journey.era).toUpperCase() + " · STAGE " + String(journey.stage));
        for (const card of cards) card.panel.frame.Hide();

        const rows = journey.recommendations;
        if (rows.length === 0) empty.Show(); else empty.Hide();

        for (let i = 0; i < rows.length; i += 1) {
            let card = cards[i];
            if (card === undefined) {
                const panel = Native.createPanel(scroll.content, theme.colors.surfaceRaised, theme.colors.border);
                panel.frame.SetSize(1228, 112);
                const iconBadge = Native.createFramedIcon(panel.frame, "Interface\\Icons\\INV_Misc_Map_01", 50, theme.colors.primary);
                iconBadge.frame.SetPoint("LEFT", panel.frame, "LEFT", 16, 0);
                const cardTitle = Native.createText(panel.frame, "", "GameFontNormal");
                cardTitle.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 82, -16);
                cardTitle.SetWidth(520);
                const meta = Native.createText(panel.frame, "", "GameFontNormalSmall", theme.colors.primary);
                meta.SetPoint("TOPLEFT", cardTitle, "BOTTOMLEFT", 0, -5);
                meta.SetWidth(520);
                const reason = Native.createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted);
                reason.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 620, -18);
                reason.SetWidth(410);
                reason.SetHeight(36);
                reason.SetJustifyV("TOP");
                const readiness = Native.createText(panel.frame, "", "GameFontNormalSmall", theme.colors.primary);
                readiness.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 620, -67);
                readiness.SetWidth(410);
                const use = ButtonUI.createButton(panel.frame, {
                    text: "Configure", width: 150, height: 38, accent: theme.colors.success, emphasis: true,
                });
                use.frame.SetPoint("RIGHT", panel.frame, "RIGHT", -16, 0);
                scroll.bindWheel(panel.frame);
                scroll.bindWheel(use.frame);
                card = { panel, iconBadge, title: cardTitle, meta, reason, readiness, use };
                cards[i] = card;
            }

            const item = rows[i];
            card.panel.frame.ClearAllPoints();
            card.panel.frame.SetPoint("TOPLEFT", scroll.content, "TOPLEFT", 0, -(i * 120));
            card.iconBadge.icon.SetTexture(Model.activityIconFor(item.id, item.mode));
            card.iconBadge.icon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            card.title.SetText(item.label);
            const availability = item.available ? "AVAILABLE" : "LOCKED";
            const readiness = item.available
                ? (item.feasible
                    ? "GROUP READY · " + String(item.humans) + " human(s) · " + String(item.selectedBots) + " bot(s) · " + String(item.guildBots) + " guild bot(s)"
                    : "ROSTER NEEDS WORK")
                : "NEXT UNLOCK";
            const gear = item.recommendedFloor > 0
                ? (item.gearReady
                    ? " · GEAR READY " + String(item.playerItemLevel) + "/" + String(item.recommendedFloor) +
                        (item.recommendedTarget > 0 ? " (target " + String(item.recommendedTarget) + ")" : "")
                    : " · GEAR LOW " + String(item.playerItemLevel) + "/" + String(item.recommendedFloor))
                : "";
            card.meta.SetText(item.era + " · " + (item.mode === "RAID" ? "Raid" : "Dungeon") + " · " + availability);
            const humanLine = item.humanNames !== "" ? " · Anchored: " + item.humanNames : "";
            card.reason.SetText(item.reason + humanLine);
            card.readiness.SetText(readiness + gear + (item.readiness !== "" ? " · " + item.readiness : ""));
            const accent = !item.available
                ? theme.colors.warning
                : (!item.gearReady ? theme.colors.warning : (item.feasible ? theme.colors.success : theme.colors.error));
            card.readiness.SetTextColor(accent[0], accent[1], accent[2], 1);
            card.iconBadge.outline.setColor(accent);
            card.use.setEnabled(item.available);
            card.use.setText(item.available ? "Configure" : "Locked");
            const id = item.id;
            const mode = item.mode;
            card.use.frame.SetScript("OnMouseDown", () => {
                if (!item.available) return;
                Model.setMode(mode);
                if (mode === "RAID") Model.setRaidActivity(id);
                else Model.setDungeonActivity(id);
                onConfigure();
            });
            card.panel.frame.Show();
        }

        scroll.setContentHeight(Math.max(690, rows.length * 120));
    }

    Model.composer().RegisterCallback("JOURNEY_CHANGED", () => {
        if (root.frame.IsShown()) refresh();
    });

    function show(): void {
        root.frame.Show();
        scroll.scrollToTop();
        refresh();
        Model.requestJourney();
    }

    return { frame: root.frame, show, hide: () => root.frame.Hide(), refresh };
}

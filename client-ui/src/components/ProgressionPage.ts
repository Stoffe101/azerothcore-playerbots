import * as Model from "../model/ComposerModel";
import * as Native from "../core/Native";
import { theme } from "../theme/Theme";
import * as ButtonUI from "../widgets/Button";
import type { UIButton } from "../widgets/Button";
import * as ScrollUI from "../widgets/ScrollList";
import * as RaidHistoryUI from "./RaidHistoryModal";

interface RaidCard {
    panel: any;
    iconBadge: any;
    title: WoWFontString;
    status: WoWFontString;
    detail: WoWFontString;
    player: WoWFontString;
    guild: WoWFontString;
}

export interface ProgressionPage {
    readonly frame: WoWFrame;
    show(): void;
    hide(): void;
    refresh(): void;
}

function eraAccent(era: string) {
    if (era === "Vanilla") return theme.colors.warning;
    if (era === "TBC") return theme.colors.success;
    return theme.colors.primary;
}

export function createProgressionPage(parent: WoWFrame): ProgressionPage {
    const root = Native.createPanel(parent, theme.colors.background, theme.colors.borderStrong);
    root.frame.SetPoint("TOPLEFT", parent, "TOPLEFT", 200, -88);
    root.frame.SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -16, 16);
    root.frame.Hide();
    const raidHistory = RaidHistoryUI.createRaidHistoryModal(parent);

    const eyebrow = Native.createText(root.frame, "YOUR JOURNEY", "GameFontNormalSmall", theme.colors.muted);
    eyebrow.SetPoint("TOPLEFT", root.frame, "TOPLEFT", 22, -18);
    const title = Native.createText(root.frame, "Expansion Progression", "GameFontNormalLarge");
    title.SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -8);
    const subtitle = Native.createText(root.frame,
        "See what you have cleared, what your guild has cleared, and exactly what still blocks the next activity.",
        "GameFontHighlightSmall", theme.colors.muted);
    subtitle.SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6);
    subtitle.SetWidth(1040);

    const summary = Native.createPanel(root.frame, theme.colors.surface, theme.colors.border);
    summary.frame.SetPoint("TOPLEFT", root.frame, "TOPLEFT", 22, -92);
    summary.frame.SetPoint("TOPRIGHT", root.frame, "TOPRIGHT", -22, -92);
    summary.frame.SetHeight(92);

    const eraText = Native.createText(summary.frame, "VANILLA", "GameFontNormalLarge", theme.colors.warning);
    eraText.SetPoint("TOPLEFT", summary.frame, "TOPLEFT", 18, -15);
    const stageText = Native.createText(summary.frame, "Progression stage 0", "GameFontHighlight", theme.colors.text);
    stageText.SetPoint("TOPLEFT", eraText, "BOTTOMLEFT", 0, -5);
    const levelText = Native.createText(summary.frame, "Level 1 / 60", "GameFontHighlightSmall", theme.colors.muted);
    levelText.SetPoint("TOPLEFT", stageText, "BOTTOMLEFT", 0, -4);

    const gateText = Native.createText(summary.frame, "", "GameFontHighlight", theme.colors.muted);
    gateText.SetPoint("TOPRIGHT", summary.frame, "TOPRIGHT", -18, -18);
    gateText.SetWidth(660);
    gateText.SetJustifyH("RIGHT");

    const tabs: Record<string, UIButton> = {};
    const eras = ["Vanilla", "TBC", "WotLK"];
    for (let i = 0; i < eras.length; i += 1) {
        const era = eras[i];
        const button = ButtonUI.createButton(root.frame, {
            text: era, width: 130, height: 34, accent: eraAccent(era), flat: true,
        });
        button.frame.SetPoint("TOPLEFT", root.frame, "TOPLEFT", 22 + i * 138, -202);
        tabs[era] = button;
    }

    const scroll = ScrollUI.createScrollList(root.frame, 1260, 548);
    scroll.frame.SetPoint("TOPLEFT", root.frame, "TOPLEFT", 22, -248);
    const cards: RaidCard[] = [];
    const empty = Native.createText(scroll.content, "No raids are tracked for this era.", "GameFontHighlight", theme.colors.muted);
    empty.SetPoint("TOPLEFT", scroll.content, "TOPLEFT", 24, -28);
    empty.SetWidth(1180);
    empty.SetJustifyH("CENTER");
    empty.Hide();

    let selectedEra = "Vanilla";

    function refresh(): void {
        const journey = Model.journey();
        const realm = Model.realm();
        const accent = eraAccent(journey.era);
        eraText.SetText(String(journey.era).toUpperCase());
        eraText.SetTextColor(accent[0], accent[1], accent[2], 1);
        stageText.SetText("Progression stage " + String(journey.stage));
        levelText.SetText("Level " + String(journey.level) + " / " + String(realm.levelCap));

        if (journey.era === "Vanilla")
            gateText.SetText("Next expansion: The Burning Crusade\nRelease it manually in Azeroth Control when your Vanilla journey is complete.");
        else if (journey.era === "TBC")
            gateText.SetText("Next expansion: Wrath of the Lich King\nRelease it manually in Azeroth Control when your TBC journey is complete.");
        else
            gateText.SetText("Current expansion: Wrath of the Lich King\nThis is the final supported realm era.");

        for (const era of eras) tabs[era].setSelected(selectedEra === era);
        for (const card of cards) card.panel.frame.Hide();

        const rows = [];
        for (const raid of journey.raids) if (raid.era === selectedEra) rows.push(raid);
        if (rows.length === 0) empty.Show(); else empty.Hide();

        for (let i = 0; i < rows.length; i += 1) {
            let card = cards[i];
            if (card === undefined) {
                const panel = Native.createPanel(scroll.content, theme.colors.surfaceRaised, theme.colors.border);
                panel.frame.SetSize(606, 108);
                const iconBadge = Native.createFramedIcon(panel.frame, "Interface\\Icons\\Achievement_Boss_LichKing", 48, theme.colors.borderStrong);
                iconBadge.frame.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 14, -15);
                const cardTitle = Native.createText(panel.frame, "", "GameFontNormal");
                cardTitle.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 76, -13);
                cardTitle.SetWidth(340);
                const status = Native.createText(panel.frame, "", "GameFontNormalSmall");
                status.SetPoint("TOPRIGHT", panel.frame, "TOPRIGHT", -14, -15);
                status.SetWidth(150);
                status.SetJustifyH("RIGHT");
                const detail = Native.createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted);
                detail.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 76, -38);
                detail.SetWidth(500);
                const player = Native.createText(panel.frame, "", "GameFontNormalSmall", theme.colors.muted);
                player.SetPoint("BOTTOMLEFT", panel.frame, "BOTTOMLEFT", 76, 15);
                const guild = Native.createText(panel.frame, "", "GameFontNormalSmall", theme.colors.muted);
                guild.SetPoint("LEFT", player, "RIGHT", 22, 0);
                scroll.bindWheel(panel.frame);
                panel.frame.EnableMouse(true);
                card = { panel, iconBadge, title: cardTitle, status, detail, player, guild };
                cards[i] = card;
            }

            const raid = rows[i];
            const column = i % 2;
            const row = Math.floor(i / 2);
            card.panel.frame.ClearAllPoints();
            card.panel.frame.SetPoint("TOPLEFT", scroll.content, "TOPLEFT", column * 620, -(row * 116));
            card.iconBadge.icon.SetTexture(Model.activityIconFor(raid.id, "RAID"));
            card.iconBadge.icon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            const cardAccent = raid.playerComplete ? theme.colors.success : (raid.available ? theme.colors.primary : theme.colors.warning);
            card.iconBadge.outline.setColor(cardAccent);
            card.title.SetText(raid.label);

            if (raid.playerComplete) {
                card.status.SetText("CLEARED");
                card.status.SetTextColor(theme.colors.success[0], theme.colors.success[1], theme.colors.success[2], 1);
            } else if (raid.available) {
                card.status.SetText("AVAILABLE");
                card.status.SetTextColor(theme.colors.primary[0], theme.colors.primary[1], theme.colors.primary[2], 1);
            } else {
                card.status.SetText("LOCKED");
                card.status.SetTextColor(theme.colors.warning[0], theme.colors.warning[1], theme.colors.warning[2], 1);
            }

            const lockoutText = raid.lockoutActive
                ? " · ACTIVE LOCKOUT #" + String(raid.lockoutInstanceId) +
                    " · " + String(raid.lockoutEncounters) + " encounter(s)" +
                    (raid.lockoutExtended ? " · EXTENDED" : "")
                : "";
            card.detail.SetText(raid.reason + lockoutText + " · click for history");
            const playerHistory = raid.playerClearCount > 0
                ? "You: Cleared ×" + String(raid.playerClearCount) +
                    (raid.playerFirstClear !== "" ? " · first " + raid.playerFirstClear : "")
                : (raid.playerComplete ? "You: Cleared ✓" : "You: Not cleared");
            card.player.SetText(playerHistory);
            card.player.SetTextColor(
                raid.playerComplete ? theme.colors.success[0] : theme.colors.muted[0],
                raid.playerComplete ? theme.colors.success[1] : theme.colors.muted[1],
                raid.playerComplete ? theme.colors.success[2] : theme.colors.muted[2], 1);
            const guildHistory = raid.guildClearCount > 0
                ? "Guild: Cleared ×" + String(raid.guildClearCount) +
                    (raid.guildFirstClear !== "" ? " · first " + raid.guildFirstClear : "")
                : (raid.guildComplete ? "Guild: Cleared ✓" : "Guild: Not recorded");
            card.guild.SetText(guildHistory);
            card.guild.SetTextColor(
                raid.guildComplete ? theme.colors.success[0] : theme.colors.muted[0],
                raid.guildComplete ? theme.colors.success[1] : theme.colors.muted[1],
                raid.guildComplete ? theme.colors.success[2] : theme.colors.muted[2], 1);
            const raidCopy = raid as Model.JourneyRaid;
            card.panel.frame.SetScript("OnMouseDown", () => raidHistory.open(raidCopy));
            card.panel.frame.Show();
        }

        scroll.setContentHeight(Math.max(548, Math.ceil(rows.length / 2) * 116));
    }

    for (const era of eras) {
        const value = era;
        tabs[era].frame.SetScript("OnMouseDown", () => {
            selectedEra = value;
            scroll.scrollToTop();
            refresh();
        });
    }

    Model.composer().RegisterCallback("JOURNEY_CHANGED", () => {
        if (root.frame.IsShown()) refresh();
    });
    Model.composer().RegisterCallback("REALM_CHANGED", () => {
        if (root.frame.IsShown()) refresh();
    });

    function show(): void {
        selectedEra = Model.relevantEraForPlayer("RAID");
        root.frame.Show();
        scroll.scrollToTop();
        refresh();
        Model.requestJourney();
    }

    return { frame: root.frame, show, hide: () => root.frame.Hide(), refresh };
}

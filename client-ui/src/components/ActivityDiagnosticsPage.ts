import * as Model from "../model/ComposerModel";
import * as Native from "../core/Native";
import { theme } from "../theme/Theme";
import * as ButtonUI from "../widgets/Button";
import * as ScrollUI from "../widgets/ScrollList";

interface DiagnosticCard {
    panel: any;
    iconBadge: any;
    title: WoWFontString;
    status: WoWFontString;
    meta: WoWFontString;
    detail: WoWFontString;
}

export interface ActivityDiagnosticsPage {
    readonly frame: WoWFrame;
    show(): void;
    hide(): void;
    refresh(): void;
}

type Filter = "PROBLEMS" | "ALL" | "PASS";

function statusAccent(status: string) {
    if (status === "FAIL") return theme.colors.error;
    if (status === "WARN") return theme.colors.warning;
    return theme.colors.success;
}

export function createActivityDiagnosticsPage(parent: WoWFrame): ActivityDiagnosticsPage {
    const root = Native.createPanel(parent, theme.colors.background, theme.colors.borderStrong);
    root.frame.SetPoint("TOPLEFT", parent, "TOPLEFT", 200, -88);
    root.frame.SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -16, 16);
    root.frame.Hide();

    const eyebrow = Native.createText(root.frame, "DEVELOPMENT HEALTH", "GameFontNormalSmall", theme.colors.muted);
    eyebrow.SetPoint("TOPLEFT", root.frame, "TOPLEFT", 22, -18);
    const title = Native.createText(root.frame, "Activity Diagnostics", "GameFontNormalLarge");
    title.SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -8);
    const subtitle = Native.createText(root.frame,
        "PASS = structurally valid. WARN = structurally valid but Playerbots support is experimental/partial. FAIL = broken catalog, map or contract metadata.",
        "GameFontHighlightSmall", theme.colors.muted);
    subtitle.SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6);
    subtitle.SetWidth(980);

    const refreshButton = ButtonUI.createButton(root.frame, {
        text: "Run Validation", width: 160, height: 36, accent: theme.colors.primary, emphasis: true,
        onClick: () => Model.requestCatalogDiagnostics(),
    });
    refreshButton.frame.SetPoint("TOPRIGHT", root.frame, "TOPRIGHT", -22, -28);

    const summary = Native.createPanel(root.frame, theme.colors.surface, theme.colors.border);
    summary.frame.SetPoint("TOPLEFT", root.frame, "TOPLEFT", 22, -96);
    summary.frame.SetPoint("TOPRIGHT", root.frame, "TOPRIGHT", -22, -96);
    summary.frame.SetHeight(70);

    const passText = Native.createText(summary.frame, "PASS 0", "GameFontNormal", theme.colors.success);
    passText.SetPoint("LEFT", summary.frame, "LEFT", 20, 0);
    const warnText = Native.createText(summary.frame, "WARN 0", "GameFontNormal", theme.colors.warning);
    warnText.SetPoint("LEFT", passText, "RIGHT", 42, 0);
    const failText = Native.createText(summary.frame, "FAIL 0", "GameFontNormal", theme.colors.error);
    failText.SetPoint("LEFT", warnText, "RIGHT", 42, 0);
    const summaryText = Native.createText(summary.frame, "Not validated yet", "GameFontHighlightSmall", theme.colors.muted);
    summaryText.SetPoint("RIGHT", summary.frame, "RIGHT", -20, 0);
    summaryText.SetWidth(620);
    summaryText.SetJustifyH("RIGHT");

    const filterDefs: Array<{ key: Filter; label: string }> = [
        { key: "PROBLEMS", label: "Needs Review" },
        { key: "ALL", label: "All" },
        { key: "PASS", label: "Passed" },
    ];
    const filterButtons: any[] = [];
    let filter: Filter = "PROBLEMS";
    for (let i = 0; i < filterDefs.length; i += 1) {
        const def = filterDefs[i];
        const button = ButtonUI.createButton(root.frame, { text: def.label, width: 118, height: 32, flat: true });
        button.frame.SetPoint("TOPLEFT", root.frame, "TOPLEFT", 22 + i * 126, -180);
        filterButtons.push(button);
    }

    const scroll = ScrollUI.createScrollList(root.frame, 1260, 570);
    scroll.frame.SetPoint("TOPLEFT", root.frame, "TOPLEFT", 22, -222);
    const cards: DiagnosticCard[] = [];
    const empty = Native.createText(scroll.content, "No entries match this filter.", "GameFontHighlight", theme.colors.muted);
    empty.SetPoint("TOPLEFT", scroll.content, "TOPLEFT", 20, -28);
    empty.SetWidth(1180);
    empty.SetJustifyH("CENTER");
    empty.Hide();

    function filteredEntries(): Model.CatalogDiagnosticEntry[] {
        const entries = Model.catalogDiagnostics().entries;
        const out: Model.CatalogDiagnosticEntry[] = [];
        for (const entry of entries) {
            if (filter === "PASS" && entry.status !== "PASS") continue;
            if (filter === "PROBLEMS" && entry.status === "PASS") continue;
            out.push(entry);
        }
        return out;
    }

    function refresh(): void {
        const state = Model.catalogDiagnostics();
        passText.SetText("PASS " + String(state.pass));
        warnText.SetText("WARN " + String(state.warn));
        failText.SetText("FAIL " + String(state.fail));
        summaryText.SetText(
            state.ready
                ? (state.fail > 0
                    ? "Structural failures found. Fix these before trusting every listed activity."
                    : (state.warn > 0
                        ? "Catalog structure is healthy. WARN entries are playable/experimental AI support, not broken activities."
                        : "Every catalog entry passed structural validation."))
                : "Validation has not completed yet."
        );

        for (let i = 0; i < filterButtons.length; i += 1)
            filterButtons[i].setSelected(filterDefs[i].key === filter);

        for (const card of cards) card.panel.frame.Hide();
        const rows = filteredEntries();
        if (rows.length === 0) empty.Show(); else empty.Hide();

        for (let i = 0; i < rows.length; i += 1) {
            let card = cards[i];
            if (card === undefined) {
                const panel = Native.createPanel(scroll.content, theme.colors.surfaceRaised, theme.colors.border);
                panel.frame.SetSize(606, 102);
                const iconBadge = Native.createFramedIcon(panel.frame, "Interface\\Icons\\INV_Misc_Map_01", 44, theme.colors.borderStrong);
                iconBadge.frame.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 14, -15);
                const cardTitle = Native.createText(panel.frame, "", "GameFontNormal");
                cardTitle.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 70, -12);
                cardTitle.SetWidth(330);
                const status = Native.createText(panel.frame, "", "GameFontNormalSmall");
                status.SetPoint("TOPRIGHT", panel.frame, "TOPRIGHT", -14, -14);
                status.SetWidth(90);
                status.SetJustifyH("RIGHT");
                const meta = Native.createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted);
                meta.SetPoint("TOPLEFT", cardTitle, "BOTTOMLEFT", 0, -4);
                meta.SetWidth(420);
                const detail = Native.createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted);
                detail.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 14, -64);
                detail.SetWidth(572);
                detail.SetHeight(30);
                detail.SetJustifyV("TOP");
                scroll.bindWheel(panel.frame);
                card = { panel, iconBadge, title: cardTitle, status, meta, detail };
                cards[i] = card;
            }

            const entry = rows[i];
            const column = i % 2;
            const row = Math.floor(i / 2);
            const accent = statusAccent(entry.status);
            card.panel.frame.ClearAllPoints();
            card.panel.frame.SetPoint("TOPLEFT", scroll.content, "TOPLEFT", column * 620, -(row * 110));
            card.iconBadge.icon.SetTexture(Model.activityIconFor(entry.id, entry.mode));
            card.iconBadge.icon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            card.iconBadge.outline.setColor(accent);
            card.title.SetText(entry.label);
            card.status.SetText(entry.status);
            card.status.SetTextColor(accent[0], accent[1], accent[2], 1);
            card.meta.SetText(entry.era + " · " + (entry.mode === "RAID" ? "Raid" : "Dungeon") + " · " + entry.id);
            card.detail.SetText(entry.detail);
            card.panel.frame.Show();
        }

        scroll.setContentHeight(Math.max(570, Math.ceil(rows.length / 2) * 110));
    }

    for (let i = 0; i < filterDefs.length; i += 1) {
        const def = filterDefs[i];
        filterButtons[i].frame.SetScript("OnMouseDown", () => {
            filter = def.key;
            scroll.scrollToTop();
            refresh();
        });
    }

    Model.composer().RegisterCallback("CATALOG_DIAGNOSTICS_CHANGED", () => {
        if (root.frame.IsShown()) refresh();
    });

    return {
        frame: root.frame,
        show: () => {
            root.frame.Show();
            scroll.scrollToTop();
            refresh();
            Model.requestCatalogDiagnostics();
        },
        hide: () => root.frame.Hide(),
        refresh,
    };
}

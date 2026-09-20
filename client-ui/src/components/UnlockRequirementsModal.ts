import * as Model from "../model/ComposerModel";
import * as Native from "../core/Native";
import { theme } from "../theme/Theme";
import * as ModalUI from "../widgets/Modal";
import * as ScrollUI from "../widgets/ScrollList";

interface RequirementRow {
    panel: any;
    icon: WoWFontString;
    title: WoWFontString;
    type: WoWFontString;
    detail: WoWFontString;
}

export interface UnlockRequirementsModal {
    open(id: string, label: string, mode: "DUNGEON" | "RAID"): void;
}

export function createUnlockRequirementsModal(parent: WoWFrame): UnlockRequirementsModal {
    const modal = ModalUI.createModal(parent, 760, 620);
    modal.setHeaderIcon("Interface\\Icons\\INV_Misc_Key_04");
    modal.setTitle("Unlock Requirements");
    modal.setSubtitle("Exact server-side requirements for this activity.");

    const stateText = Native.createText(modal.content, "Checking requirements...", "GameFontNormal", theme.colors.warning);
    stateText.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 8, -4);
    stateText.SetWidth(650);

    const summary = Native.createText(modal.content, "", "GameFontHighlightSmall", theme.colors.muted);
    summary.SetPoint("TOPLEFT", stateText, "BOTTOMLEFT", 0, -6);
    summary.SetWidth(650);
    summary.SetHeight(42);
    summary.SetJustifyV("TOP");

    const scroll = ScrollUI.createScrollList(modal.content, 684, 430);
    scroll.frame.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 0, -88);
    const rows: RequirementRow[] = [];
    const empty = Native.createText(scroll.content, "Waiting for the server...", "GameFontHighlight", theme.colors.muted);
    empty.SetPoint("TOPLEFT", scroll.content, "TOPLEFT", 20, -26);
    empty.SetWidth(640);
    empty.SetJustifyH("CENTER");

    function refresh(): void {
        const details = Model.unlockDetails();
        const color = details.available ? theme.colors.success : theme.colors.warning;
        stateText.SetText(details.ready
            ? (details.available ? "UNLOCKED · All requirements satisfied" : "LOCKED · Requirements remain")
            : "Checking requirements...");
        stateText.SetTextColor(color[0], color[1], color[2], 1);
        summary.SetText(details.summary);

        for (const row of rows) row.panel.frame.Hide();
        const requirements = details.requirements;
        if (requirements.length === 0) empty.Show(); else empty.Hide();

        for (let i = 0; i < requirements.length; i += 1) {
            let row = rows[i];
            if (row === undefined) {
                const panel = Native.createPanel(scroll.content, theme.colors.surfaceRaised, theme.colors.border);
                panel.frame.SetSize(650, 82);
                const icon = Native.createText(panel.frame, "", "GameFontNormalLarge");
                icon.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 14, -13);
                icon.SetWidth(30);
                const title = Native.createText(panel.frame, "", "GameFontNormal");
                title.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 52, -11);
                title.SetWidth(390);
                const type = Native.createText(panel.frame, "", "GameFontNormalSmall", theme.colors.muted);
                type.SetPoint("TOPRIGHT", panel.frame, "TOPRIGHT", -14, -13);
                type.SetWidth(150);
                type.SetJustifyH("RIGHT");
                const detail = Native.createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted);
                detail.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 52, -37);
                detail.SetWidth(570);
                detail.SetHeight(34);
                detail.SetJustifyV("TOP");
                scroll.bindWheel(panel.frame);
                row = { panel, icon, title, type, detail };
                rows[i] = row;
            }

            const req = requirements[i];
            const pass = req.status === "PASS";
            const accent = pass ? theme.colors.success : theme.colors.warning;
            row.panel.frame.ClearAllPoints();
            row.panel.frame.SetPoint("TOPLEFT", scroll.content, "TOPLEFT", 0, -(i * 90));
            row.icon.SetText(pass ? "✓" : "!");
            row.icon.SetTextColor(accent[0], accent[1], accent[2], 1);
            row.title.SetText(req.title);
            row.type.SetText(req.type + " · " + req.status);
            row.type.SetTextColor(accent[0], accent[1], accent[2], 1);
            row.detail.SetText(req.detail);
            row.panel.frame.Show();
        }

        scroll.setContentHeight(Math.max(430, requirements.length * 90));
    }

    Model.composer().RegisterCallback("UNLOCK_DETAILS_CHANGED", () => {
        if (modal.frame.IsShown()) refresh();
    });

    return {
        open: (id: string, label: string, mode: "DUNGEON" | "RAID") => {
            modal.setTitle(label);
            modal.setSubtitle("Exact unlock path · " + (mode === "RAID" ? "Raid" : "Dungeon"));
            scroll.scrollToTop();
            modal.show();
            Model.requestUnlockDetails(id, mode);
            refresh();
        },
    };
}

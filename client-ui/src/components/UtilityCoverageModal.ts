import * as Model from "../model/ComposerModel";
import * as Native from "../core/Native";
import { theme } from "../theme/Theme";
import * as ModalUI from "../widgets/Modal";

export interface UtilityCoverageModal {
    readonly frame: WoWFrame;
    open(): void;
    hide(): void;
}

interface BuffWidgets {
    title: WoWFontString;
    detail: WoWFontString;
}

export function createUtilityCoverageModal(parent: WoWFrame): UtilityCoverageModal {
    const modal = ModalUI.createModal(parent, 900, 620);
    modal.setHeaderIcon("Interface\\Icons\\INV_Misc_Map_01");
    modal.setTitle("Utility Coverage Details");
    modal.setSubtitle("Exact provider counts for the prepared roster, plus the major raid buff families Composer can and cannot supply.");

    const utilityTitle = Native.createText(modal.content, "UTILITY PROVIDERS", "GameFontNormalSmall", theme.colors.primary);
    utilityTitle.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 0, 0);

    const utilityText = Native.createText(modal.content, "", "GameFontHighlight", theme.colors.text);
    utilityText.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 0, -30);
    utilityText.SetWidth(330);
    utilityText.SetHeight(300);
    utilityText.SetJustifyH("LEFT");
    utilityText.SetJustifyV("TOP");

    const buffTitle = Native.createText(modal.content, "MAJOR RAID BUFFS", "GameFontNormalSmall", theme.colors.primary);
    buffTitle.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 370, 0);

    const buffSummary = Native.createText(modal.content, "", "GameFontHighlightSmall", theme.colors.muted);
    buffSummary.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 370, -28);
    buffSummary.SetWidth(470);

    const buffRows: BuffWidgets[] = [];
    for (let i = 0; i < 7; i += 1) {
        const title = Native.createText(modal.content, "", "GameFontNormal", theme.colors.muted);
        title.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 370, -(62 + i * 60));
        title.SetWidth(470);

        const detail = Native.createText(modal.content, "", "GameFontHighlightSmall", theme.colors.muted);
        detail.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 386, -(84 + i * 60));
        detail.SetWidth(454);

        buffRows.push({ title, detail });
    }

    const note = Native.createText(
        modal.content,
        "Counts are roster members capable of supplying that utility. Major raid buffs are baseline/class-capability families; talent-only auras and encounter debuffs are intentionally not guessed.",
        "GameFontHighlightSmall",
        theme.colors.muted,
    );
    note.SetPoint("BOTTOMLEFT", modal.content, "BOTTOMLEFT", 0, 0);
    note.SetWidth(830);
    note.SetJustifyV("BOTTOM");

    function refresh(): void {
        const summary = Model.plan().summary ?? {};
        const counts = summary.utilityCounts;
        const buffs = summary.raidBuffs ?? [];

        if (counts === undefined) {
            utilityText.SetText("Build & Prepare a roster first. Composer will then count every selected member's utility capabilities.");
            buffSummary.SetText("No prepared roster yet.");
            for (const row of buffRows) {
                row.title.SetText("");
                row.detail.SetText("");
            }
            return;
        }

        utilityText.SetText(
            "Interrupts: " + String(counts.interrupt ?? 0) + "\n" +
            "Dispels / cleanses: " + String(counts.dispel ?? 0) + "\n" +
            "Raid-buff-capable members: " + String(counts.buffs ?? 0) + "\n" +
            "Heroism / Bloodlust: " + String(counts.heroism ?? 0) + "\n" +
            "Battle resurrection: " + String(counts.battleRez ?? 0) + "\n" +
            "Crowd control: " + String(counts.cc ?? 0) + "\n" +
            "Threat support: " + String(counts.threat ?? 0) + "\n\n" +
            "Ranged DPS: " + String(summary.ranged ?? 0) + "\n" +
            "Melee DPS: " + String(summary.melee ?? 0)
        );

        let present = 0;
        for (const buff of buffs) if (Number(buff.count ?? 0) > 0) present += 1;
        buffSummary.SetText("Major raid buff families present: " + String(present) + " / " + String(buffs.length));

        for (let i = 0; i < buffRows.length; i += 1) {
            const row = buffRows[i];
            const buff = buffs[i];
            if (buff === undefined) {
                row.title.SetText("");
                row.detail.SetText("");
                continue;
            }

            const count = Number(buff.count ?? 0);
            const available = count > 0;
            row.title.SetText(
                (available ? "PRESENT  " : "MISSING  ") +
                String(buff.label ?? buff.token ?? "Unknown buff") +
                "  x" + String(count)
            );
            row.title.SetTextColor(
                available ? theme.colors.success[0] : theme.colors.warning[0],
                available ? theme.colors.success[1] : theme.colors.warning[1],
                available ? theme.colors.success[2] : theme.colors.warning[2],
                1
            );
            row.detail.SetText(
                available
                    ? "Providers: " + String(buff.providers ?? "Unknown")
                    : "No selected roster member supplies this buff family."
            );
        }
    }

    function open(): void {
        refresh();
        modal.show();
    }

    return { frame: modal.frame, open, hide: () => modal.hide() };
}

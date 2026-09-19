import * as Model from "../model/ComposerModel";
import * as Native from "../core/Native";
import { theme } from "../theme/Theme";
import * as ButtonUI from "../widgets/Button";
import type { UIButton } from "../widgets/Button";
import * as ModalUI from "../widgets/Modal";
import * as ScrollUI from "../widgets/ScrollList";

interface BrowserEntry {
    id: string;
    label: string;
    detail: string;
    icon: string;
    era?: string;
    minLevel?: number;
}

interface BrowserCard {
    button: UIButton;
    iconBadge: any;
    title: WoWFontString;
    detail: WoWFontString;
    tag: WoWFontString;
}

export interface ActivityBrowser {
    readonly frame: WoWFrame;
    open(): void;
    hide(): void;
}

export function createActivityBrowser(parent: WoWFrame): ActivityBrowser {
    const D: any = Model.data();
    const modal = ModalUI.createModal(parent, 960, 650);
    modal.setHeaderIcon("Interface\\Icons\\INV_Misc_Map_01");

    const filterButtons: UIButton[] = [];
    for (let i = 0; i < 3; i += 1) {
        const button = ButtonUI.createButton(modal.content, {
            text: "", width: 132, height: 34, accent: theme.colors.primary, flat: true,
        });
        button.frame.SetPoint("TOPLEFT", modal.content, "TOPLEFT", i * 140, 0);
        filterButtons.push(button);
    }

    const scroll = ScrollUI.createScrollList(modal.content, 884, 470);
    scroll.frame.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 0, -48);
    const cards: BrowserCard[] = [];
    const empty = Native.createText(scroll.content, "No activities match this filter.", "GameFontHighlight", theme.colors.muted);
    empty.SetPoint("TOPLEFT", scroll.content, "TOPLEFT", 20, -30);
    empty.SetWidth(820);
    empty.SetJustifyH("CENTER");
    empty.Hide();

    let filter = "ALL";

    function mode(): "DUNGEON" | "RAID" {
        return Model.config().mode === "RAID" ? "RAID" : "DUNGEON";
    }

    function currentEra(): string {
        const raid = D.GetRaidById(Model.config().activity);
        return String(raid?.era ?? "WotLK");
    }

    function entries(): BrowserEntry[] {
        const out: BrowserEntry[] = [];
        if (mode() === "DUNGEON") {
            for (const dungeon of D.DUNGEONS ?? []) {
                const minLevel = Number(dungeon.minLevel ?? 68);
                const endgame = dungeon.id === "random" || minLevel >= 80;
                if (filter === "LEVELING" && endgame) continue;
                if (filter === "ENDGAME" && !endgame) continue;
                out.push({
                    id: String(dungeon.id),
                    label: String(dungeon.label),
                    detail: dungeon.id === "random"
                        ? "WotLK random · Normal Lv " + String(minLevel) + "+ · Heroic Lv 80"
                        : "Normal Lv " + String(minLevel) + "+ · Heroic Lv 80",
                    icon: Model.activityIconFor(String(dungeon.id), "DUNGEON"),
                    minLevel,
                });
            }
        } else {
            for (const raid of D.RAIDS ?? []) {
                if (filter !== "ALL" && String(raid.era) !== filter) continue;
                const sizes: string[] = [];
                for (const size of raid.sizes ?? []) sizes.push(String(size));
                out.push({
                    id: String(raid.id),
                    label: String(raid.label),
                    detail: sizes.join("/") + " player · Level " + String(raid.requiredLevel ?? 80) + "+" +
                        (raid.heroic === true ? " · Heroic available" : ""),
                    icon: Model.activityIconFor(String(raid.id), "RAID"),
                    era: String(raid.era),
                });
            }
        }
        return out;
    }

    function tabLabels(): Array<{ key: string; label: string }> {
        if (mode() === "RAID") {
            return [
                { key: "WotLK", label: "WotLK" },
                { key: "TBC", label: "TBC" },
                { key: "Classic", label: "Classic" },
            ];
        }
        return [
            { key: "ALL", label: "All" },
            { key: "LEVELING", label: "Leveling" },
            { key: "ENDGAME", label: "Level 80" },
        ];
    }

    function refresh(): void {
        const tabs = tabLabels();
        for (let i = 0; i < filterButtons.length; i += 1) {
            const tab = tabs[i];
            const button = filterButtons[i];
            button.setText(tab.label);
            button.setSelected(filter === tab.key);
            const key = tab.key;
            button.frame.SetScript("OnMouseDown", () => {
                filter = key;
                scroll.scrollToTop();
                refresh();
            });
            button.frame.Show();
        }

        for (const card of cards) card.button.frame.Hide();
        const items = entries();
        if (items.length === 0) empty.Show(); else empty.Hide();

        for (let i = 0; i < items.length; i += 1) {
            let card = cards[i];
            if (card === undefined) {
                const button = ButtonUI.createButton(scroll.content, {
                    text: "", width: 426, height: 78, accent: theme.colors.primary, flat: true,
                });
                const iconBadge = Native.createFramedIcon(button.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 42, theme.colors.borderStrong);
                iconBadge.frame.SetPoint("LEFT", button.frame, "LEFT", 12, 0);
                const title = Native.createText(button.frame, "", "GameFontNormal");
                title.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 66, -12); title.SetWidth(328);
                const detail = Native.createText(button.frame, "", "GameFontHighlightSmall", theme.colors.muted);
                detail.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 66, -35); detail.SetWidth(328);
                const tag = Native.createText(button.frame, "", "GameFontNormalSmall", theme.colors.primary);
                tag.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 66, -55); tag.SetWidth(328);
                scroll.bindWheel(button.frame);
                card = { button, iconBadge, title, detail, tag };
                cards[i] = card;
            }

            const item = items[i];
            const column = i % 2;
            const row = Math.floor(i / 2);
            card.button.frame.ClearAllPoints();
            card.button.frame.SetPoint("TOPLEFT", scroll.content, "TOPLEFT", column * 436, -(row * 86));
            card.button.setSelected(String(Model.config().activity) === item.id);
            card.iconBadge.icon.SetTexture(item.icon);
            card.iconBadge.icon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            card.iconBadge.outline.setColor(String(Model.config().activity) === item.id ? theme.colors.primary : theme.colors.borderStrong);
            card.title.SetText(item.label);
            card.detail.SetText(item.detail);
            card.tag.SetText(mode() === "RAID" ? String(item.era ?? "").toUpperCase() :
                (item.id === "random" ? "DUNGEON FINDER" : (Number(item.minLevel ?? 80) >= 80 ? "ENDGAME" : "LEVELING")));
            const id = item.id;
            card.button.frame.SetScript("OnMouseDown", () => {
                if (mode() === "RAID") Model.setRaidActivity(id); else Model.setDungeonActivity(id);
                modal.hide();
            });
            card.button.frame.Show();
        }
        scroll.setContentHeight(Math.max(470, Math.ceil(items.length / 2) * 86));
    }

    function open(): void {
        if (mode() === "RAID") {
            filter = currentEra();
            modal.setTitle("Choose Raid");
            modal.setSubtitle("Browse by expansion instead of hunting through one long list.");
            modal.setHeaderIcon("Interface\\Icons\\Achievement_Boss_LichKing");
        } else {
            filter = "ALL";
            modal.setTitle("Choose Dungeon");
            modal.setSubtitle("Browse all Wrath dungeons, or jump straight to leveling or level-80 activities.");
            modal.setHeaderIcon("Interface\\Icons\\Spell_Arcane_PortalDalaran");
        }
        scroll.scrollToTop(); refresh(); modal.show();
    }

    return { frame: modal.frame, open, hide: () => modal.hide() };
}

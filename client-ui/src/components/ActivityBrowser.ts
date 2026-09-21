import * as Model from "../model/ComposerModel";
import * as Native from "../core/Native";
import { theme } from "../theme/Theme";
import * as ButtonUI from "../widgets/Button";
import type { UIButton } from "../widgets/Button";
import * as ModalUI from "../widgets/Modal";
import * as ScrollUI from "../widgets/ScrollList";
import * as UnlockRequirementsUI from "./UnlockRequirementsModal";

interface BrowserEntry {
    id: string;
    label: string;
    detail: string;
    icon: string;
    era: string;
    minLevel: number;
    support: string;
}

interface BrowserCard {
    button: UIButton;
    favorite: UIButton;
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
    const unlockModal = UnlockRequirementsUI.createUnlockRequirementsModal(modal.frame);

    const filterButtons: UIButton[] = [];
    for (let i = 0; i < 5; i += 1) {
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

    let filter = "Vanilla";

    function mode(): "DUNGEON" | "RAID" {
        return Model.config().mode === "RAID" ? "RAID" : "DUNGEON";
    }

    function currentEra(): string {
        return Model.realm().era;
    }

    function difficultyDetail(era: string, minLevel: number): string {
        if (era === "Vanilla") return "Normal · Level " + String(minLevel) + "+";
        if (era === "TBC") return "Normal / Heroic · Level " + String(minLevel) + "+";
        return "Normal / Heroic / Titan Rune · Level " + String(minLevel) + "+";
    }

    function entries(): BrowserEntry[] {
        const out: BrowserEntry[] = [];
        const selectedMode = mode();
        const serverEntries = Model.activityMetaList(selectedMode);
        if (serverEntries.length > 0) {
            let recentOrder: Record<string, number> = {};
            if (filter === "RECENT") {
                const recent = Model.recentActivityIds(selectedMode, 8);
                for (let i = 0; i < recent.length; i += 1) recentOrder[recent[i]] = i + 1;
            }
            for (const entry of serverEntries) {
                if (filter === "FAVORITES" && !Model.isFavorite(selectedMode, entry.id)) continue;
                if (filter === "RECENT" && recentOrder[entry.id] === undefined) continue;
                if (filter !== "FAVORITES" && filter !== "RECENT" && entry.era !== filter) continue;
                out.push({
                    id: entry.id,
                    label: entry.label,
                    detail: mode() === "RAID"
                        ? String(entry.size) + " player · Level " + String(entry.minLevel) + "+"
                        : difficultyDetail(entry.era, entry.minLevel),
                    icon: Model.activityIconFor(entry.id, mode()),
                    era: entry.era,
                    minLevel: entry.minLevel,
                    support: entry.support,
                });
            }
            if (filter === "RECENT") {
                out.sort((left, right) => (recentOrder[left.id] ?? 999) - (recentOrder[right.id] ?? 999));
            }
            return out;
        }

        // Short fallback while the authoritative server catalog is in flight.
        if (mode() === "DUNGEON") {
            for (const dungeon of D.DUNGEONS ?? []) {
                const era = dungeon.id === "random" ? currentEra() : String(dungeon.era ?? "WotLK");
                if (era !== filter) continue;
                const minLevel = Number(dungeon.minLevel ?? 1);
                out.push({
                    id: String(dungeon.id), label: String(dungeon.label),
                    detail: difficultyDetail(era, minLevel),
                    icon: Model.activityIconFor(String(dungeon.id), "DUNGEON"),
                    era, minLevel, support: "Checking support",
                });
            }
        } else {
            for (const raid of D.RAIDS ?? []) {
                const era = String(raid.era ?? "WotLK");
                if (era !== filter) continue;
                const sizes: string[] = [];
                for (const size of raid.sizes ?? []) sizes.push(String(size));
                out.push({
                    id: String(raid.id), label: String(raid.label),
                    detail: sizes.join("/") + " player · Level " + String(raid.requiredLevel ?? 80) + "+",
                    icon: Model.activityIconFor(String(raid.id), "RAID"),
                    era, minLevel: Number(raid.requiredLevel ?? 80), support: "Checking support",
                });
            }
        }
        return out;
    }

    function tabLabels(): Array<{ key: string; label: string }> {
        return [
            { key: "Vanilla", label: "Vanilla" },
            { key: "TBC", label: "TBC" },
            { key: "WotLK", label: "WotLK" },
            { key: "FAVORITES", label: "Favorites" },
            { key: "RECENT", label: "Recent" },
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
                    text: "", width: 426, height: 88, accent: theme.colors.primary, flat: true,
                });
                const iconBadge = Native.createFramedIcon(button.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 42, theme.colors.borderStrong);
                iconBadge.frame.SetPoint("LEFT", button.frame, "LEFT", 12, 0);
                const title = Native.createText(button.frame, "", "GameFontNormal");
                title.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 66, -11); title.SetWidth(278); title.SetHeight(18);
                const detail = Native.createText(button.frame, "", "GameFontHighlightSmall", theme.colors.muted);
                detail.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 66, -34); detail.SetWidth(300); detail.SetHeight(16);
                const tag = Native.createText(button.frame, "", "GameFontNormalSmall", theme.colors.primary);
                tag.SetPoint("TOPLEFT", button.frame, "TOPLEFT", 66, -54); tag.SetWidth(340); tag.SetHeight(28); tag.SetJustifyV("TOP");
                const favorite = ButtonUI.createButton(button.frame, {
                    text: "Fav", width: 44, height: 30, accent: theme.colors.warning, flat: true,
                });
                favorite.frame.SetPoint("TOPRIGHT", button.frame, "TOPRIGHT", -7, -7);
                scroll.bindWheel(button.frame);
                scroll.bindWheel(favorite.frame);
                card = { button, favorite, iconBadge, title, detail, tag };
                cards[i] = card;
            }

            const item = items[i];
            const column = i % 2;
            const row = Math.floor(i / 2);
            card.button.frame.ClearAllPoints();
            card.button.frame.SetPoint("TOPLEFT", scroll.content, "TOPLEFT", column * 436, -(row * 96));
            const access = Model.activityEligibility(item.id, mode());
            const selected = String(Model.config().activity) === item.id;
            card.button.setSelected(selected);
            card.button.setEnabled(true);
            card.iconBadge.icon.SetTexture(item.icon);
            card.iconBadge.icon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            card.iconBadge.outline.setColor(
                !access.known ? theme.colors.borderStrong :
                access.eligible ? (selected ? theme.colors.primary : theme.colors.success) : theme.colors.warning
            );
            card.title.SetText(item.label);
            card.detail.SetText(access.known && !access.eligible ? access.reason : item.detail);
            if (!access.known) {
                card.tag.SetText("CHECKING ACCESS");
                card.tag.SetTextColor(theme.colors.muted[0], theme.colors.muted[1], theme.colors.muted[2], 1);
            } else if (!access.eligible) {
                card.tag.SetText("LOCKED");
                card.tag.SetTextColor(theme.colors.warning[0], theme.colors.warning[1], theme.colors.warning[2], 1);
            } else {
                const suffix = item.id === "random" ? " · RANDOM" : "";
                card.tag.SetText(String(item.era).toUpperCase() + " · AVAILABLE" + suffix + " · " + item.support.toUpperCase());
                card.tag.SetTextColor(theme.colors.success[0], theme.colors.success[1], theme.colors.success[2], 1);
            }
            const id = item.id;
            const selectedMode = mode();
            const favoriteSelected = Model.isFavorite(selectedMode, id);
            card.favorite.setText("Fav");
            card.favorite.setSelected(favoriteSelected);
            card.favorite.frame.SetScript("OnMouseDown", () => {
                Model.toggleFavorite(selectedMode, id);
                refresh();
            });
            card.button.frame.SetScript("OnMouseDown", () => {
                const latest = Model.activityEligibility(id, mode());
                if (!latest.known) {
                    Model.fireStatus(latest.reason);
                    return;
                }
                if (!latest.eligible) {
                    unlockModal.open(id, item.label, selectedMode);
                    return;
                }
                if (mode() === "RAID") Model.setRaidActivity(id); else Model.setDungeonActivity(id);
                modal.hide();
            });
            card.button.frame.Show();
        }
        scroll.setContentHeight(Math.max(470, Math.ceil(items.length / 2) * 96));
    }

    Model.composer().RegisterCallback("ACTIVITIES_CHANGED", () => {
        if (modal.frame.IsShown()) refresh();
    });
    Model.composer().RegisterCallback("ACTIVITY_HISTORY_CHANGED", () => {
        if (modal.frame.IsShown()) refresh();
    });

    function open(): void {
        Model.requestActivities(mode());
        filter = Model.relevantEraForPlayer(mode());
        if (mode() === "RAID") {
            modal.setTitle("Choose Raid");
            modal.setSubtitle("Vanilla, TBC and WotLK live in one era-aware progression browser. Click a locked raid to see its exact unlock path.");
            modal.setHeaderIcon("Interface\\Icons\\Achievement_Boss_LichKing");
        } else {
            modal.setTitle("Choose Dungeon");
            modal.setSubtitle("Only the live era's difficulty rules apply. Click a locked dungeon to see its exact quest/key/progression requirements.");
            modal.setHeaderIcon("Interface\\Icons\\Spell_Arcane_PortalDalaran");
        }
        scroll.scrollToTop(); refresh(); modal.show();
    }

    return { frame: modal.frame, open, hide: () => modal.hide() };
}

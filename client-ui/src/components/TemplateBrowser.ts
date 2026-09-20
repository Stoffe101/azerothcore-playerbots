import * as Model from "../model/ComposerModel";
import * as Native from "../core/Native";
import { theme } from "../theme/Theme";
import * as ButtonUI from "../widgets/Button";
import type { UIButton } from "../widgets/Button";
import * as ModalUI from "../widgets/Modal";
import * as ScrollUI from "../widgets/ScrollList";
import * as InputUI from "../widgets/TextInput";

type TemplateTab = "WotLK" | "TBC" | "Vanilla" | "CUSTOM";

interface TemplateCard {
    panel: any;
    accent: WoWTexture;
    iconBadge: any;
    name: WoWFontString;
    tag: WoWFontString;
    info: WoWFontString;
    load: UIButton;
    remove: UIButton;
}

export interface TemplateBrowser {
    readonly frame: WoWFrame;
    open(): void;
    hide(): void;
}

export function createTemplateBrowser(parent: WoWFrame): TemplateBrowser {
    const D: any = Model.data();
    const modal = ModalUI.createModal(parent, 960, 650);
    modal.setTitle("Templates");
    modal.setSubtitle("Save reusable raid rosters or five-player dungeon parties.");
    modal.setHeaderIcon("Interface\\Icons\\INV_Scroll_03");

    const saveLabel = Native.createText(modal.content, "SAVE CURRENT GROUP", "GameFontNormalSmall", theme.colors.muted);
    saveLabel.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 0, 0);
    const nameInput = InputUI.createTextInput(modal.content, 300, 34);
    nameInput.frame.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 0, -24);

    let tab: TemplateTab = "WotLK";
    const tabDefs: Array<{ key: TemplateTab; label: string; width: number }> = [
        { key: "WotLK", label: "WotLK", width: 116 },
        { key: "TBC", label: "TBC", width: 104 },
        { key: "Vanilla", label: "Vanilla", width: 116 },
        { key: "CUSTOM", label: "My Templates", width: 150 },
    ];
    const tabs: UIButton[] = [];
    let x = 0;
    for (const def of tabDefs) {
        const button = ButtonUI.createButton(modal.content, {
            text: def.label, width: def.width, height: 34,
            accent: def.key === "CUSTOM" ? theme.colors.warning : theme.colors.primary, flat: true,
        });
        button.frame.SetPoint("TOPLEFT", modal.content, "TOPLEFT", x, -82);
        const key = def.key;
        button.frame.SetScript("OnMouseDown", () => { tab = key; scroll.scrollToTop(); refresh(); });
        tabs.push(button); x += def.width + 8;
    }

    const scroll = ScrollUI.createScrollList(modal.content, 884, 420);
    scroll.frame.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 0, -126);
    const cards: TemplateCard[] = [];
    const empty = Native.createText(scroll.content, "", "GameFontHighlight", theme.colors.muted);
    empty.SetPoint("TOPLEFT", scroll.content, "TOPLEFT", 24, -28);
    empty.SetWidth(800); empty.SetJustifyH("CENTER"); empty.Hide();

    function templateEra(name: string): string {
        const profile = Model.profileMeta(name);
        const raid = profile !== undefined ? D.GetRaidById(profile.activity) : undefined;
        return String(raid?.era ?? "");
    }

    function namesForTab(): string[] {
        const mode = Model.config().mode === "RAID" ? "RAID" : "DUNGEON";
        if (mode === "DUNGEON") return Model.listCustomProfiles("DUNGEON");
        if (tab === "CUSTOM") return Model.listCustomProfiles("RAID");
        const out: string[] = [];
        for (const name of Model.listBuiltinProfiles()) if (templateEra(name) === tab) out.push(name);
        return out;
    }

    function refresh(): void {
        const dungeonMode = Model.config().mode === "DUNGEON";
        let tabX = 0;
        for (let i = 0; i < tabs.length; i += 1) {
            tabs[i].frame.ClearAllPoints();
            tabs[i].frame.SetPoint("TOPLEFT", modal.content, "TOPLEFT", tabX, -82);
            tabX += tabDefs[i].width + 8;
            tabs[i].setSelected(tabDefs[i].key === tab);
            if (dungeonMode && tabDefs[i].key !== "CUSTOM") tabs[i].frame.Hide();
            else tabs[i].frame.Show();
        }
        if (dungeonMode) {
            tabs[3].frame.ClearAllPoints();
            tabs[3].frame.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 0, -82);
        }
        for (const card of cards) card.panel.frame.Hide();
        const names = namesForTab();
        if (names.length === 0) {
            empty.SetText(tab === "CUSTOM"
                ? "No custom templates yet. Configure a raid, name it above, then Save Current."
                : "No built-in templates are available for this expansion.");
            empty.Show();
        } else empty.Hide();

        for (let i = 0; i < names.length; i += 1) {
            let card = cards[i];
            if (card === undefined) {
                const panel = Native.createPanel(scroll.content, theme.colors.surfaceRaised, theme.colors.border);
                panel.frame.SetSize(426, 84);
                const accent = Native.createSolid(panel.frame, theme.colors.primary, "ARTWORK");
                accent.SetWidth(3); accent.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 0, 0); accent.SetPoint("BOTTOMLEFT", panel.frame, "BOTTOMLEFT", 0, 0);
                const iconBadge = Native.createFramedIcon(panel.frame, "Interface\\Icons\\Achievement_Boss_LichKing", 40, theme.colors.primary);
                iconBadge.frame.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 12, -12);
                const name = Native.createText(panel.frame, "", "GameFontNormal");
                name.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 64, -10); name.SetWidth(262);
                const tag = Native.createText(panel.frame, "", "GameFontNormalSmall", theme.colors.primary);
                tag.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 64, -31); tag.SetWidth(250);
                const info = Native.createText(panel.frame, "", "GameFontHighlightSmall", theme.colors.muted);
                info.SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 64, -52); info.SetWidth(270);
                const load = ButtonUI.createButton(panel.frame, { text: "Load", width: 64, height: 28, accent: theme.colors.primary });
                const remove = ButtonUI.createButton(panel.frame, { text: "Delete", width: 62, height: 28, accent: theme.colors.error });
                scroll.bindWheel(panel.frame); scroll.bindWheel(load.frame); scroll.bindWheel(remove.frame);
                card = { panel, accent, iconBadge, name, tag, info, load, remove };
                cards[i] = card;
            }

            const profileName = names[i];
            const profile = Model.profileMeta(profileName);
            const builtin = profile?.builtin === true;
            const profileMode: "DUNGEON" | "RAID" = profile?.mode === "DUNGEON" ? "DUNGEON" : "RAID";
            const accent = builtin ? theme.colors.primary : theme.colors.warning;
            const column = i % 2;
            const row = Math.floor(i / 2);
            card.panel.frame.ClearAllPoints();
            card.panel.frame.SetPoint("TOPLEFT", scroll.content, "TOPLEFT", column * 436, -(row * 92));
            Native.setTextureColor(card.accent, accent);
            card.iconBadge.outline.setColor(accent);
            card.iconBadge.icon.SetTexture(Model.activityIconFor(String(profile?.activity ?? ""), profileMode));
            card.iconBadge.icon.SetTexCoord(0.08, 0.92, 0.08, 0.92);
            const activityId = String(profile?.activity ?? "");
            const access = Model.activityEligibility(activityId, profileMode);
            card.name.SetText(profileName);
            if (!access.known) {
                card.tag.SetText("CHECKING ACCESS");
                card.tag.SetTextColor(theme.colors.muted[0], theme.colors.muted[1], theme.colors.muted[2], 1);
                card.info.SetText(Model.profileDescription(profileName));
            } else if (!access.eligible) {
                card.tag.SetText("LOCKED");
                card.tag.SetTextColor(theme.colors.warning[0], theme.colors.warning[1], theme.colors.warning[2], 1);
                card.info.SetText(access.reason);
            } else {
                card.tag.SetText(builtin ? String(templateEra(profileName)).toUpperCase() + " · BUILT-IN · AVAILABLE" : "CUSTOM · AVAILABLE");
                card.tag.SetTextColor(theme.colors.success[0], theme.colors.success[1], theme.colors.success[2], 1);
                card.info.SetText(Model.profileDescription(profileName));
            }
            card.load.setEnabled(access.known && access.eligible);

            card.load.frame.ClearAllPoints(); card.remove.frame.ClearAllPoints();
            if (builtin) {
                card.remove.frame.Hide(); card.load.frame.SetPoint("RIGHT", card.panel.frame, "RIGHT", -10, 0);
            } else {
                card.load.frame.SetPoint("TOPRIGHT", card.panel.frame, "TOPRIGHT", -78, -10);
                card.remove.frame.SetPoint("TOPRIGHT", card.panel.frame, "TOPRIGHT", -10, -10);
                card.remove.frame.SetScript("OnMouseDown", () => { Model.deleteProfile(profileName); refresh(); });
                card.remove.frame.Show();
            }
            card.load.frame.SetScript("OnMouseDown", () => {
                const latest = Model.activityEligibility(String(profile?.activity ?? ""), profileMode);
                if (!latest.known || !latest.eligible) {
                    Model.fireStatus(latest.reason);
                    return;
                }
                Model.loadProfile(profileName);
                modal.hide();
            });
            card.panel.frame.Show();
        }
        scroll.setContentHeight(Math.max(420, Math.ceil(names.length / 2) * 92));
    }

    const save = ButtonUI.createButton(modal.content, {
        text: "Save Current", width: 124, height: 36, accent: theme.colors.primary, emphasis: true,
        onClick: () => {
            const name = nameInput.getText();
            if (name === "") return;
            Model.saveProfile(name); nameInput.clear(); tab = "CUSTOM"; scroll.scrollToTop(); refresh();
        },
    });
    save.frame.SetPoint("LEFT", nameInput.frame, "RIGHT", 8, 0);

    Model.composer().RegisterCallback("ACTIVITIES_CHANGED", (mode: string) => {
        if (mode === "RAID" && modal.frame.IsShown()) refresh();
    });

    function open(): void {
        const dungeonMode = Model.config().mode === "DUNGEON";
        if (dungeonMode) {
            modal.setTitle("Dungeon Party Templates");
            modal.setSubtitle("Save your five-player role, class/spec, human and pinned-bot preferences for quick reuse.");
            saveLabel.SetText("SAVE CURRENT PARTY");
            tab = "CUSTOM";
            Model.requestActivities("DUNGEON");
        } else {
            modal.setTitle("Raid Templates");
            modal.setSubtitle("Browse built-in coverage templates by expansion or load your own saved raid.");
            saveLabel.SetText("SAVE CURRENT RAID");
            Model.requestActivities("RAID", "normal", Number(Model.config().size ?? 25));
            const raid = D.GetRaidById(Model.config().activity);
            const era = String(raid?.era ?? "WotLK");
            tab = era === "TBC" ? "TBC" : (era === "Vanilla" ? "Vanilla" : "WotLK");
        }
        save.setEnabled(true);
        scroll.scrollToTop(); refresh(); modal.show();
    }

    return { frame: modal.frame, open, hide: () => modal.hide() };
}

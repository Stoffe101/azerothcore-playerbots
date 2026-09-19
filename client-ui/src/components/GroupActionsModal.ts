import * as Model from "../model/ComposerModel";
import * as Native from "../core/Native";
import { theme } from "../theme/Theme";
import * as ButtonUI from "../widgets/Button";
import * as ModalUI from "../widgets/Modal";

export interface GroupActionsModal {
    open(): void;
}

export function createGroupActionsModal(parent: WoWFrame): GroupActionsModal {
    const modal = ModalUI.createModal(parent, 650, 430);
    modal.setHeaderIcon("Interface\\Icons\\INV_Misc_GroupLooking");
    modal.setTitle("Assembled Group Actions");
    modal.setSubtitle("Keep the current composition useful after assembly and instance travel.");

    const intro = Native.createText(
        modal.content,
        "Rebuild/Repair keeps the current configuration and treats valid live members as sticky anchors.",
        "GameFontHighlight",
        theme.colors.muted,
    );
    intro.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 8, -6);
    intro.SetWidth(570);
    intro.SetHeight(46);
    intro.SetJustifyV("TOP");

    const rebuild = ButtonUI.createButton(modal.content, {
        text: "Rebuild / Repair Roster", width: 260, height: 44, accent: theme.colors.primary, emphasis: true,
        onClick: () => {
            modal.hide();
            Model.rebuildOrRepair();
        },
    });
    rebuild.frame.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 8, -72);
    const rebuildHint = Native.createText(
        modal.content,
        "Re-run Build & Prepare. Existing valid group members stay; missing slots are filled again.",
        "GameFontHighlightSmall",
        theme.colors.muted,
    );
    rebuildHint.SetPoint("TOPLEFT", rebuild.frame, "BOTTOMLEFT", 0, -7);
    rebuildHint.SetWidth(560);

    const leave = ButtonUI.createButton(modal.content, {
        text: "Leave Instance Together", width: 260, height: 44, accent: theme.colors.success,
        onClick: () => {
            modal.hide();
            Model.leaveInstance();
        },
    });
    leave.frame.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 8, -160);
    const leaveHint = Native.createText(
        modal.content,
        "Use AzerothCore's canonical instance exit. The reviewed group remains assembled for re-entry.",
        "GameFontHighlightSmall",
        theme.colors.muted,
    );
    leaveHint.SetPoint("TOPLEFT", leave.frame, "BOTTOMLEFT", 0, -7);
    leaveHint.SetWidth(560);

    const disband = ButtonUI.createButton(modal.content, {
        text: "Disband Composer Group", width: 260, height: 44, accent: theme.colors.error,
    });
    disband.frame.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 8, -248);
    const disbandHint = Native.createText(
        modal.content,
        "Only the real leader can do this. Composer refuses if an unreviewed player has joined the live group.",
        "GameFontHighlightSmall",
        theme.colors.muted,
    );
    disbandHint.SetPoint("TOPLEFT", disband.frame, "BOTTOMLEFT", 0, -7);
    disbandHint.SetWidth(560);

    const confirm = ModalUI.createModal(parent, 560, 270);
    confirm.setHeaderIcon("Interface\\Icons\\Ability_Rogue_FeignDeath");
    confirm.setTitle("Disband Composer group?");
    confirm.setSubtitle("This removes the reviewed live party/raid. Your saved configuration remains.");
    const confirmText = Native.createText(
        confirm.content,
        "Composer only disbands if you are the real leader and the live group exactly matches the reviewed roster. Unreviewed players are protected.",
        "GameFontHighlight",
        theme.colors.muted,
    );
    confirmText.SetPoint("TOPLEFT", confirm.content, "TOPLEFT", 8, -8);
    confirmText.SetWidth(490);
    confirmText.SetJustifyH("CENTER");
    confirmText.SetJustifyV("TOP");

    const cancel = ButtonUI.createButton(confirm.content, {
        text: "Cancel", width: 120, height: 36, onClick: () => confirm.hide(),
    });
    cancel.frame.SetPoint("BOTTOMLEFT", confirm.content, "BOTTOMLEFT", 112, 0);

    const go = ButtonUI.createButton(confirm.content, {
        text: "Disband", width: 140, height: 38, accent: theme.colors.error, emphasis: true,
        onClick: () => {
            confirm.hide();
            Model.disbandComposerGroup();
        },
    });
    go.frame.SetPoint("BOTTOMRIGHT", confirm.content, "BOTTOMRIGHT", -112, 0);

    disband.frame.SetScript("OnMouseDown", () => {
        modal.hide();
        confirm.show();
    });

    return {
        open: () => {
            if (!Model.isAssembled()) {
                Model.fireStatus("Assemble the reviewed roster before using group lifecycle actions.");
                return;
            }
            modal.show();
        },
    };
}

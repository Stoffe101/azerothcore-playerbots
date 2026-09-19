import * as Model from "../model/ComposerModel";
import * as Native from "../core/Native";
import { theme } from "../theme/Theme";
import * as ModalUI from "../widgets/Modal";

export interface MemberDetailsModal {
    open(member: Model.PlanMember): void;
}

function sourceLabel(source: string): string {
    if (source === "HUMAN") return "Real player anchor";
    if (source === "GUILD") return "Guild companion";
    if (source === "RESERVE") return "Composer reserve";
    if (source === "ROSTER") return "Managed Composer capacity";
    return "World bot";
}

export function createMemberDetailsModal(parent: WoWFrame): MemberDetailsModal {
    const modal = ModalUI.createModal(parent, 680, 410);
    modal.setHeaderIcon("Interface\\Icons\\INV_Misc_Note_05");
    modal.setTitle("Why this member?");
    modal.setSubtitle("Group Composer selection rationale.");

    const summary = Native.createText(modal.content, "", "GameFontNormal", theme.colors.primary);
    summary.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 8, -6);
    summary.SetWidth(600);

    const source = Native.createText(modal.content, "", "GameFontHighlightSmall", theme.colors.muted);
    source.SetPoint("TOPLEFT", summary, "BOTTOMLEFT", 0, -7);
    source.SetWidth(600);

    const whyTitle = Native.createText(modal.content, "WHY COMPOSER CHOSE THIS MEMBER", "GameFontNormalSmall", theme.colors.warning);
    whyTitle.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 8, -82);

    const why = Native.createText(modal.content, "", "GameFontHighlight", theme.colors.text);
    why.SetPoint("TOPLEFT", whyTitle, "BOTTOMLEFT", 0, -10);
    why.SetWidth(610);
    why.SetHeight(190);
    why.SetJustifyV("TOP");

    const hint = Native.createText(
        modal.content,
        "This explanation comes from the server-reviewed roster snapshot. Rebuilding may choose a different bot if availability, guild state, level band or utility coverage changes.",
        "GameFontHighlightSmall",
        theme.colors.muted,
    );
    hint.SetPoint("BOTTOMLEFT", modal.content, "BOTTOMLEFT", 8, 8);
    hint.SetWidth(610);
    hint.SetJustifyV("BOTTOM");

    return {
        open: (member: Model.PlanMember) => {
            const role = Model.roleLabel(member.role);
            const level = String(member.level ?? "?");
            const spec = String(member.spec ?? Model.classLabel(String(member.class)));
            modal.setTitle(member.human ? "Why is this player anchored?" : "Why this bot?");
            modal.setSubtitle(String(member.name));
            summary.SetText("Level " + level + "  ·  " + spec + "  ·  " + role);
            source.SetText(
                sourceLabel(String(member.source ?? "WORLD")) +
                (member.pinned ? "  ·  PINNED" : "") +
                (member.locked ? "  ·  ALREADY GROUPED" : "") +
                (member.needsPreparation ? "  ·  PREPARATION NEEDED" : "")
            );
            why.SetText(String(member.why ?? "Composer selected this member because it matched the reviewed roster requirements."));
            modal.show();
        },
    };
}

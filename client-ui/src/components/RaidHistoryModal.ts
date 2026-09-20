import * as Model from "../model/ComposerModel";
import * as Native from "../core/Native";
import { theme } from "../theme/Theme";
import * as ModalUI from "../widgets/Modal";

export interface RaidHistoryModal {
    open(raid: Model.JourneyRaid): void;
}

export function createRaidHistoryModal(parent: WoWFrame): RaidHistoryModal {
    const modal = ModalUI.createModal(parent, 720, 520);
    modal.setHeaderIcon("Interface\\Icons\\INV_Misc_Book_09");
    modal.setTitle("Raid History");
    modal.setSubtitle("Personal progress, guild history and current lockout.");

    const status = Native.createText(modal.content, "", "GameFontNormal", theme.colors.primary);
    status.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 8, -8);
    status.SetWidth(630);

    const personalTitle = Native.createText(modal.content, "YOUR HISTORY", "GameFontNormalSmall", theme.colors.muted);
    personalTitle.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 8, -58);
    const personal = Native.createText(modal.content, "", "GameFontHighlight", theme.colors.text);
    personal.SetPoint("TOPLEFT", personalTitle, "BOTTOMLEFT", 0, -8);
    personal.SetWidth(630);

    const guildTitle = Native.createText(modal.content, "GUILD HISTORY", "GameFontNormalSmall", theme.colors.muted);
    guildTitle.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 8, -126);
    const guild = Native.createText(modal.content, "", "GameFontHighlight", theme.colors.text);
    guild.SetPoint("TOPLEFT", guildTitle, "BOTTOMLEFT", 0, -8);
    guild.SetWidth(630);

    const rosterTitle = Native.createText(modal.content, "FIRST RECORDED GUILD-CLEAR ROSTER", "GameFontNormalSmall", theme.colors.warning);
    rosterTitle.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 8, -202);
    const roster = Native.createText(modal.content, "", "GameFontHighlight", theme.colors.text);
    roster.SetPoint("TOPLEFT", rosterTitle, "BOTTOMLEFT", 0, -8);
    roster.SetWidth(630);
    roster.SetHeight(74);
    roster.SetJustifyV("TOP");

    const lockoutTitle = Native.createText(modal.content, "CURRENT LOCKOUT", "GameFontNormalSmall", theme.colors.muted);
    lockoutTitle.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 8, -306);
    const lockout = Native.createText(modal.content, "", "GameFontHighlight", theme.colors.text);
    lockout.SetPoint("TOPLEFT", lockoutTitle, "BOTTOMLEFT", 0, -8);
    lockout.SetWidth(630);

    const accessTitle = Native.createText(modal.content, "ACCESS / SUPPORT", "GameFontNormalSmall", theme.colors.muted);
    accessTitle.SetPoint("TOPLEFT", modal.content, "TOPLEFT", 8, -374);
    const access = Native.createText(modal.content, "", "GameFontHighlightSmall", theme.colors.muted);
    access.SetPoint("TOPLEFT", accessTitle, "BOTTOMLEFT", 0, -8);
    access.SetWidth(630);
    access.SetHeight(58);
    access.SetJustifyV("TOP");

    return {
        open: (raid: Model.JourneyRaid) => {
            modal.setTitle(raid.label);
            modal.setSubtitle(raid.era + " · Raid history");

            if (raid.playerClearCount > 0) {
                personal.SetText(
                    "Clears: " + String(raid.playerClearCount) +
                    (raid.playerFirstClear !== "" ? " · First recorded clear: " + raid.playerFirstClear : "") +
                    (raid.playerFirstFormat !== "" ? " · " + raid.playerFirstFormat : "") +
                    (raid.playerFirstGroupSize > 0 ? " · " + String(raid.playerFirstGroupSize) + " recorded participant(s)" : "")
                );
            } else if (raid.playerComplete) {
                personal.SetText("Completed through progression state; no detailed kill event is recorded yet.");
            } else {
                personal.SetText("No recorded clear yet.");
            }

            if (raid.guildClearCount > 0) {
                guild.SetText(
                    "Guild clears: " + String(raid.guildClearCount) +
                    (raid.guildFirstClear !== "" ? " · First recorded clear: " + raid.guildFirstClear : "") +
                    (raid.guildFirstFormat !== "" ? " · " + raid.guildFirstFormat : "") +
                    (raid.guildFirstGroupSize > 0 ? " · " + String(raid.guildFirstGroupSize) + " recorded participant(s)" : "")
                );
            } else {
                guild.SetText("No recorded guild clear yet.");
            }

            roster.SetText(
                raid.guildFirstRoster !== ""
                    ? raid.guildFirstRoster
                    : "No first-clear roster is recorded yet. Historical bounty-only clears cannot reconstruct participants."
            );

            if (raid.lockoutActive) {
                lockout.SetText(
                    "Instance #" + String(raid.lockoutInstanceId) +
                    " · " + String(raid.lockoutEncounters) + " completed encounter(s)" +
                    (raid.lockoutExtended ? " · Extended" : "")
                );
            } else {
                lockout.SetText("No active saved raid instance.");
            }

            access.SetText(
                (raid.available ? "Available" : "Locked") + " · " + raid.support + "\n" + raid.reason
            );
            modal.show();
        },
    };
}

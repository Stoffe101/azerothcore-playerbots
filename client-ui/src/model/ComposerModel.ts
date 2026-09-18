import { ClassId, getClass, getSpecsForRole, Role } from "../data/WotlkBuilds";
import { ChoiceItem } from "../widgets/ChoiceSelect";

export interface HumanAnchor {
    name: string;
    class: ClassId | string;
    role?: Role;
    subgroup?: number;
    isPlayer?: boolean;
    online?: boolean;
    level?: number;
}

export const ANY_SPEC_ID = -1;

export interface RequiredBuild {
    classId: ClassId;
    specId: number;
    count: number;
}

export interface PlanMember {
    subgroup: number;
    name: string;
    role: Role;
    class: ClassId | string;
    spec: string;
    source: string;
    human: boolean;
    locked: boolean;
    pinned: boolean;
    needsPreparation: boolean;
    reserve: boolean;
    isPlayer: boolean;
    level?: number;
}

const GC: any = _G.GroupComposer;

/** @noSelf */
interface DataFunctions {
    GetDungeonById(id: string): any;
    GetRaidById(id: string): any;
}

/** @noSelf */
interface ProfileFunctions {
    ListBuiltins(): string[];
    ListCustom(): string[];
    Describe(name: string): string;
}

const D: any = _G.GroupComposerData;
const DataFns: DataFunctions = _G.GroupComposerData as DataFunctions;
const P: any = _G.GroupComposerProfiles;
const ProfileFns: ProfileFunctions = _G.GroupComposerProfiles as ProfileFunctions;

const ACTIVITY_ICONS: Record<string, string> = {
    random: "Interface\\Icons\\INV_Misc_Dice_02",
    utgarde_keep: "Interface\\Icons\\INV_Misc_Bone_10",
    nexus: "Interface\\Icons\\Spell_Arcane_PortalDalaran",
    azjol_nerub: "Interface\\Icons\\Ability_Hunter_Pet_Spider",
    ahnkahet: "Interface\\Icons\\Spell_Shadow_Twilight",
    drak_tharon: "Interface\\Icons\\INV_Misc_Head_Troll_01",
    violet_hold: "Interface\\Icons\\Spell_Arcane_PortalDalaran",
    gundrak: "Interface\\Icons\\INV_Misc_Head_Troll_01",
    halls_of_stone: "Interface\\Icons\\INV_Stone_14",
    halls_of_lightning: "Interface\\Icons\\Spell_Nature_Lightning",
    oculus: "Interface\\Icons\\INV_Misc_Head_Dragon_Blue",
    culling: "Interface\\Icons\\Spell_Holy_Excorcism_02",
    utgarde_pinnacle: "Interface\\Icons\\INV_Misc_Bone_10",
    trial_champion: "Interface\\Icons\\INV_Sword_04",
    forge_souls: "Interface\\Icons\\Spell_Shadow_SoulLeech_3",
    pit_saron: "Interface\\Icons\\INV_Pick_02",
    halls_reflection: "Interface\\Icons\\Spell_Deathknight_FrostPresence",

    naxxramas: "Interface\\Icons\\Spell_Shadow_AnimateDead",
    obsidian_sanctum: "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
    eye_of_eternity: "Interface\\Icons\\INV_Misc_Head_Dragon_Blue",
    ulduar: "Interface\\Icons\\INV_Gizmo_02",
    trial_crusader: "Interface\\Icons\\INV_Misc_Head_Nerubian_01",
    onyxia: "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
    vault_archavon: "Interface\\Icons\\INV_Elemental_Primal_Earth",
    icecrown: "Interface\\Icons\\Spell_Deathknight_FrostPresence",
    ruby_sanctum: "Interface\\Icons\\INV_Misc_Head_Dragon_Red",

    karazhan: "Interface\\Icons\\Spell_Arcane_PortalDalaran",
    zulaman: "Interface\\Icons\\INV_Misc_Head_Troll_01",
    gruul: "Interface\\Icons\\Ability_Warrior_Charge",
    magtheridon: "Interface\\Icons\\Spell_Shadow_SummonFelGuard",
    serpentshrine: "Interface\\Icons\\Spell_Frost_SummonWaterElemental_2",
    tempest_keep: "Interface\\Icons\\Spell_Arcane_PortalDalaran",
    hyjal: "Interface\\Icons\\Spell_Nature_NatureGuardian",
    black_temple: "Interface\\Icons\\Spell_Shadow_Metamorphosis",
    sunwell: "Interface\\Icons\\Spell_Holy_SummonLightwell",

    zul_gurub: "Interface\\Icons\\INV_Misc_Head_Troll_01",
    aq20: "Interface\\Icons\\INV_Misc_Head_Qiraji_01",
    molten_core: "Interface\\Icons\\Spell_Fire_FlameBolt",
    blackwing_lair: "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
    aq40: "Interface\\Icons\\INV_Misc_Head_Qiraji_01",
};

const DEFAULT_DUNGEON_ICON = "Interface\\Icons\\Spell_Arcane_PortalDalaran";
const DEFAULT_RAID_ICON = "Interface\\Icons\\Achievement_Boss_LichKing";

export function composer(): any { return GC; }
export function data(): any { return D; }
export function profiles(): any { return P; }
export function config(): any { return GC.GetConfig(); }
export function plan(): any { return GC.plan ?? { members: [], warnings: [], summary: {}, valid: false, ready: false }; }
export function progress(): any { return GC.progress ?? { phase: "IDLE", current: 0, total: 0, detail: "" }; }

export function touch(reason: string): void { GC.Touch(reason); }
export function fireStatus(text: string): void { GC.Fire("STATUS", text); }

export function humans(): HumanAnchor[] {
    return (GC.ScanHumans() ?? []) as HumanAnchor[];
}

export function humanReady(): boolean {
    const list = humans();
    if (list.length === 0) return false;
    const roles = config().humanRoles ?? {};
    for (const human of list) if (roles[human.name] === undefined) return false;
    return true;
}

export function humanRoleCounts(): Record<Role, number> {
    const result: Record<Role, number> = { TANK: 0, HEALER: 0, DPS: 0 };
    const roles = config().humanRoles ?? {};
    const seen: Record<string, boolean> = {};

    for (const human of humans()) {
        const key = String(human.name ?? "").toLowerCase();
        const role = roles[human.name] as Role | undefined;
        if (key !== "" && role !== undefined && seen[key] !== true) {
            seen[key] = true;
            result[role] += 1;
        }
    }

    for (const extra of config().extraHumans ?? []) {
        const key = String(extra.name ?? "").toLowerCase();
        const role = extra.role as Role | undefined;
        if (key !== "" && role !== undefined && seen[key] !== true) {
            seen[key] = true;
            result[role] += 1;
        }
    }
    return result;
}

export function targetForRole(role: Role): number {
    const cfg = config();
    if (role === "TANK") return Number(cfg.tanks ?? 0);
    if (role === "HEALER") return Number(cfg.healers ?? 0);
    return Number(cfg.dps ?? 0);
}

export function roleTargetTotal(): number {
    const cfg = config();
    return Number(cfg.tanks ?? 0) + Number(cfg.healers ?? 0) + Number(cfg.dps ?? 0);
}

export function setRoleTarget(role: Role, value: number): void {
    const cfg = config();
    const next = Math.max(0, Math.min(Number(cfg.size ?? 40), Math.floor(value)));
    if (role === "TANK") cfg.tanks = next;
    else if (role === "HEALER") cfg.healers = next;
    else cfg.dps = next;
    touch("Role composition changed");
}

export function resetRoleTargets(): void {
    const cfg = config();
    const size = Number(cfg.size ?? 25);
    if (size === 10) {
        cfg.tanks = 2; cfg.healers = 2; cfg.dps = 6;
    } else if (size === 20) {
        cfg.tanks = 3; cfg.healers = 5; cfg.dps = 12;
    } else if (size === 40) {
        cfg.tanks = 5; cfg.healers = 10; cfg.dps = 25;
    } else if (size === 5) {
        cfg.tanks = 1; cfg.healers = 1; cfg.dps = 3;
    } else {
        cfg.tanks = 2; cfg.healers = 6; cfg.dps = Math.max(0, size - 8);
    }
    touch("Role composition reset");
}

export function remainingBotSlots(role: Role): number {
    const counts = humanRoleCounts();
    return Math.max(0, targetForRole(role) - counts[role]);
}

function rawRequired(role: Role): any[] {
    const result: any[] = [];
    const list = config().preferences?.[role] ?? [];
    for (const pref of list) {
        if (pref.required === true && pref.class !== undefined && pref.class !== "ANY") {
            if (typeof pref.spec === "number") result.push(pref);
            else if (String(pref.spec ?? "").toUpperCase() === "ANY") {
                result.push({ class: pref.class, spec: ANY_SPEC_ID, required: true });
            }
        }
    }
    return result;
}

export function requiredBuilds(role: Role): RequiredBuild[] {
    const result: RequiredBuild[] = [];
    for (const pref of rawRequired(role)) {
        const classId = pref.class as ClassId;
        const specId = Number(pref.spec);
        let existing: RequiredBuild | undefined;
        for (const row of result) {
            if (row.classId === classId && row.specId === specId) {
                existing = row;
                break;
            }
        }
        if (existing !== undefined) existing.count += 1;
        else result.push({ classId, specId, count: 1 });
    }
    return result;
}

export function requiredFlat(role: Role): Array<{ classId: ClassId; specId: number }> {
    const result: Array<{ classId: ClassId; specId: number }> = [];
    for (const build of requiredBuilds(role)) {
        for (let i = 0; i < build.count; i += 1) result.push({ classId: build.classId, specId: build.specId });
    }
    return result;
}

export function exactCount(role: Role): number {
    let total = 0;
    for (const row of requiredBuilds(role)) total += row.count;
    return total;
}

export function writeRequiredBuilds(role: Role, rows: RequiredBuild[], reason = "Exact composition changed"): void {
    const cfg = config();
    const existing = cfg.preferences?.[role] ?? [];
    const next: any[] = [];

    for (const pref of existing) {
        if (pref.required !== true) next.push(pref);
    }

    const max = remainingBotSlots(role);
    let written = 0;
    for (const row of rows) {
        const count = Math.max(0, Math.min(row.count, max - written));
        for (let i = 0; i < count; i += 1) {
            next.push({ class: row.classId, spec: row.specId === ANY_SPEC_ID ? "ANY" : row.specId, required: true });
            written += 1;
        }
        if (written >= max) break;
    }

    cfg.preferences[role] = next;
    touch(reason);
}

export function addRequiredBuild(role: Role, classId: ClassId, specId: number, count: number): void {
    const rows = requiredBuilds(role);
    const available = Math.max(0, remainingBotSlots(role) - exactCount(role));
    const add = Math.max(0, Math.min(count, available));
    if (add <= 0) {
        fireStatus("Every " + roleLabel(role).toLowerCase() + " bot slot already has an exact build.");
        return;
    }

    let existing: RequiredBuild | undefined;
    for (const row of rows) {
        if (row.classId === classId && row.specId === specId) {
            existing = row;
            break;
        }
    }
    if (existing !== undefined) existing.count += add;
    else rows.push({ classId, specId, count: add });
    writeRequiredBuilds(role, rows);
}

export function replaceRequiredBuild(role: Role, index: number, classId: ClassId, specId: number, count: number): void {
    const rows = requiredBuilds(role);
    const old = rows[index];
    if (old === undefined) return;

    let usedWithout = 0;
    for (let i = 0; i < rows.length; i += 1) if (i !== index) usedWithout += rows[i].count;
    const allowed = Math.max(1, remainingBotSlots(role) - usedWithout);
    rows[index] = { classId, specId, count: Math.max(1, Math.min(count, allowed)) };
    writeRequiredBuilds(role, rows);
}

export function removeRequiredBuild(role: Role, index: number): void {
    const rows = requiredBuilds(role);
    if (rows[index] === undefined) return;
    rows.splice(index, 1);
    writeRequiredBuilds(role, rows);
}

export function setDungeonExact(role: Role, botIndex: number, classId: ClassId, specId: number): void {
    const flat = requiredFlat(role);
    const target = Math.max(0, botIndex - 1);
    if (target < flat.length) flat[target] = { classId, specId };
    else flat.push({ classId, specId });

    const rows: RequiredBuild[] = [];
    for (const item of flat) {
        let existing: RequiredBuild | undefined;
        for (const row of rows) {
            if (row.classId === item.classId && row.specId === item.specId) { existing = row; break; }
        }
        if (existing !== undefined) existing.count += 1;
        else rows.push({ classId: item.classId, specId: item.specId, count: 1 });
    }
    writeRequiredBuilds(role, rows, "Dungeon build changed");
}

export function clearDungeonExact(role: Role, botIndex: number): void {
    const flat = requiredFlat(role);
    const target = Math.max(0, botIndex - 1);
    if (target >= flat.length) return;
    flat.splice(target, 1);

    const rows: RequiredBuild[] = [];
    for (const item of flat) {
        let existing: RequiredBuild | undefined;
        for (const row of rows) {
            if (row.classId === item.classId && row.specId === item.specId) { existing = row; break; }
        }
        if (existing !== undefined) existing.count += 1;
        else rows.push({ classId: item.classId, specId: item.specId, count: 1 });
    }
    writeRequiredBuilds(role, rows, "Dungeon build cleared");
}

export function getSpecLabel(classId: ClassId, specId: number): string {
    if (specId === ANY_SPEC_ID) return "Any valid spec";
    const specs = getSpecsForRole(classId, "TANK")
        .concat(getSpecsForRole(classId, "HEALER"))
        .concat(getSpecsForRole(classId, "DPS"));
    for (const spec of specs) if (spec.id === specId) return spec.label;
    return "Unknown";
}

export function getSpecIcon(classId: ClassId, specId: number): string {
    if (specId === ANY_SPEC_ID) return "Interface\\Icons\\INV_Misc_QuestionMark";
    const classDef = getClass(classId);
    if (classDef !== undefined) {
        for (const spec of classDef.specs) if (spec.id === specId) return spec.icon;
    }
    return "Interface\\Icons\\INV_Misc_QuestionMark";
}

export function classLabel(classId: ClassId | string): string {
    const classDef = getClass(classId as ClassId);
    return classDef?.label ?? String(classId);
}

export function roleLabel(role: Role): string {
    if (role === "TANK") return "Tank";
    if (role === "HEALER") return "Healer";
    return "DPS";
}

function dungeonById(id: string): any {
    return DataFns.GetDungeonById(id);
}

function raidById(id: string): any {
    return DataFns.GetRaidById(id);
}

export function pinnedMembers(): any[] {
    const result: any[] = [];
    for (const pin of (config().pinned ?? []) as any[]) result.push(pin);
    return result;
}

export function planWarnings(): string[] {
    const result: string[] = [];
    for (const warning of (plan().warnings ?? []) as any[]) result.push(String(warning));
    return result;
}

export function coverageDisplay(): string {
    const summary = plan().summary ?? {};
    const raw = String(summary.utility ?? "");
    const labels: string[] = [];
    if (raw.indexOf("interrupt") >= 0) labels.push("Interrupts");
    if (raw.indexOf("dispel") >= 0) labels.push("Dispels");
    if (raw.indexOf("buffs") >= 0) labels.push("Raid buffs");
    if (raw.indexOf("heroism") >= 0) labels.push("Heroism");
    if (raw.indexOf("battle-rez") >= 0) labels.push("Battle rez");
    if (raw.indexOf("cc") >= 0) labels.push("Crowd control");
    if (raw.indexOf("threat") >= 0) labels.push("Threat support");

    let utility = "";
    for (let i = 0; i < labels.length; i += 1) {
        if (i > 0) utility += "  ·  ";
        utility += labels[i];
    }
    if (utility === "") utility = "No utility coverage yet";

    return utility + "\n" +
        "Ranged DPS  " + String(summary.ranged ?? 0) +
        "     Melee DPS  " + String(summary.melee ?? 0);
}

export function dungeonItems(): ChoiceItem[] {
    const result: ChoiceItem[] = [];
    for (const dungeon of D.DUNGEONS ?? []) {
        const min = Number(dungeon.minLevel ?? 68);
        result.push({
            value: dungeon.id,
            label: dungeon.label,
            detail: dungeon.id === "random"
                ? "WotLK random · Normal Lv " + String(min) + "+ · Heroic Lv 80"
                : "Normal Lv " + String(min) + "+ · Heroic Lv 80",
            icon: ACTIVITY_ICONS[String(dungeon.id)] ?? DEFAULT_DUNGEON_ICON,
        });
    }
    return result;
}

export function difficultyItems(): ChoiceItem[] {
    const result: ChoiceItem[] = [];
    for (const difficulty of D.DUNGEON_DIFFICULTIES ?? []) result.push({ value: difficulty.id, label: difficulty.label });
    return result;
}

export function raidItems(): ChoiceItem[] {
    const result: ChoiceItem[] = [];
    for (const raid of D.RAIDS ?? []) {
        let sizes = "";
        let firstSize = true;
        for (const size of raid.sizes ?? []) {
            if (!firstSize) sizes += "/";
            sizes += String(size);
            firstSize = false;
        }
        result.push({
            value: raid.id,
            label: raid.era + "  ·  " + raid.label,
            detail: sizes + " player · Level " + String(raid.requiredLevel ?? 80) + "+",
            icon: ACTIVITY_ICONS[String(raid.id)] ?? DEFAULT_RAID_ICON,
        });
    }
    return result;
}

export function raidDifficultyItems(): ChoiceItem[] {
    const result: ChoiceItem[] = [{ value: "normal", label: "Normal" }];
    const raid = raidById(config().activity);
    if (raid?.heroic === true) result.push({ value: "heroic", label: "Heroic" });
    return result;
}

export function selectedActivityLabel(): string {
    const cfg = config();
    if (cfg.mode === "RAID") {
        const raid = raidById(cfg.activity);
        return raid?.label ?? "Raid";
    }
    const dungeon = dungeonById(cfg.activity);
    return dungeon?.label ?? "Dungeon";
}

export function selectedActivityIcon(): string {
    const cfg = config();
    const key = String(cfg.activity ?? "");
    return ACTIVITY_ICONS[key] ?? (cfg.mode === "RAID" ? DEFAULT_RAID_ICON : DEFAULT_DUNGEON_ICON);
}

export function requiredActivityLevel(): number {
    const cfg = config();
    if (cfg.mode === "RAID") {
        const raid = raidById(cfg.activity);
        return Number(raid?.requiredLevel ?? 80);
    }
    if (cfg.difficulty !== "normal") return 80;
    const dungeon = dungeonById(cfg.activity);
    return Number(dungeon?.minLevel ?? 68);
}

export function activityEligibilityText(): string {
    const level = requiredActivityLevel();
    const floor = Number(config().options?.minimumItemLevel ?? 0);
    return "Level " + String(level) + "+ required · Item level floor " + (floor > 0 ? String(floor) : "Off");
}

export function setMinimumItemLevel(value: number): void {
    const next = Math.max(0, Math.min(1000, Math.floor(value)));
    config().options.minimumItemLevel = next;
    touch("Minimum item level changed");
}

export function supportedRaidSizes(): number[] {
    const raid = raidById(config().activity);
    const result: number[] = [];
    for (const size of raid?.sizes ?? []) result.push(Number(size));
    return result;
}

export function setMode(mode: "DUNGEON" | "RAID"): void { GC.SetMode(mode); }
export function setDungeonActivity(id: string): void { GC.SetDungeonActivity(id); }
export function setRaidActivity(id: string): void { GC.SetRaidActivity(id); }
export function setRaidSize(size: number): void { GC.SetRaidSize(size); }
export function setDifficulty(id: string): void {
    config().difficulty = id;
    touch("Difficulty changed");
}
export function setHumanRole(name: string, role: Role): void { GC.SetHumanRole(name, role); }
export function buildAndPrepare(): void { GC.FindRoster(); }
export function assemble(): void { GC.Assemble(); }
export function requestAnchors(): void { GC.RequestAnchors(); }
export function requestStatus(): void { GC.RequestStatus(); }
export function clearPlan(): void { GC.ClearServerPlan(); }
export function loadProfile(name: string): void { GC.LoadProfile(name); }
export function saveProfile(name: string): void { GC.SaveProfile(name); }
export function deleteProfile(name: string): void { GC.DeleteProfile(name); }
export function listBuiltinProfiles(): string[] { return ProfileFns.ListBuiltins() ?? []; }
export function listCustomProfiles(): string[] { return ProfileFns.ListCustom() ?? []; }
export function profileDescription(name: string): string { return ProfileFns.Describe(name) ?? ""; }
export function addPin(name: string, role: Role, required: boolean): void { GC.AddPinnedMember(name, role, required); }
export function removePin(index: number): void { GC.RemovePinnedMember(index); }

export function planMembers(): PlanMember[] { return (plan().members ?? []) as PlanMember[]; }

export function roleAccent(role: Role): readonly [number, number, number, number] {
    if (role === "TANK") return [0.20, 0.58, 0.98, 1];
    if (role === "HEALER") return [0.18, 0.78, 0.42, 1];
    return [0.91, 0.31, 0.30, 1];
}

export function phaseLabel(phase: string): string {
    if (phase === "BUILDING") return "Selecting roster";
    if (phase === "PREPARING") return "Preparing bots";
    if (phase === "READY") return "Ready";
    if (phase === "ASSEMBLING") return "Assembling";
    if (phase === "TRAVEL") return "Entering activity";
    if (phase === "DONE") return "Group ready";
    if (phase === "ERROR") return "Needs attention";
    return "Ready to configure";
}

export function isBusy(): boolean {
    const phase = String(progress().phase ?? "IDLE");
    return phase === "BUILDING" || phase === "PREPARING" || phase === "ASSEMBLING" || phase === "TRAVEL";
}

export function isTravelRetry(): boolean {
    const p = progress();
    return p.phase === "READY" && String(p.detail ?? "").indexOf("Enter Activity") >= 0;
}

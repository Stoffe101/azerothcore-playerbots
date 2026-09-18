import { ClassId, getClass, getSpecsForRole, Role } from "../data/WotlkBuilds";
import { ChoiceItem } from "../widgets/ChoiceSelect";

export interface HumanAnchor {
    name: string;
    class: ClassId | string;
    role?: Role;
    subgroup?: number;
    isPlayer?: boolean;
    online?: boolean;
}

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
}

const GC: any = _G.GroupComposer;
const D: any = _G.GroupComposerData;
const P: any = _G.GroupComposerProfiles;

export function composer(): any { return GC; }
export function data(): any { return D; }
export function profiles(): any { return P; }
export function config(): any { return GC.GetConfig(GC); }
export function plan(): any { return GC.plan ?? { members: [], warnings: [], summary: {}, valid: false, ready: false }; }
export function progress(): any { return GC.progress ?? { phase: "IDLE", current: 0, total: 0, detail: "" }; }

export function touch(reason: string): void { GC.Touch(GC, reason); }
export function fireStatus(text: string): void { GC.Fire(GC, "STATUS", text); }

export function humans(): HumanAnchor[] {
    return (GC.ScanHumans(GC) ?? []) as HumanAnchor[];
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

export function remainingBotSlots(role: Role): number {
    const counts = humanRoleCounts();
    return Math.max(0, targetForRole(role) - counts[role]);
}

function rawRequired(role: Role): any[] {
    const result: any[] = [];
    const list = config().preferences?.[role] ?? [];
    for (const pref of list) {
        if (pref.required === true && pref.class !== undefined && pref.class !== "ANY" && typeof pref.spec === "number") {
            result.push(pref);
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
            next.push({ class: row.classId, spec: row.specId, required: true });
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
    const specs = getSpecsForRole(classId, "TANK")
        .concat(getSpecsForRole(classId, "HEALER"))
        .concat(getSpecsForRole(classId, "DPS"));
    for (const spec of specs) if (spec.id === specId) return spec.label;
    return "Unknown";
}

export function getSpecIcon(classId: ClassId, specId: number): string {
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

export function dungeonItems(): ChoiceItem[] {
    const result: ChoiceItem[] = [];
    for (const dungeon of D.DUNGEONS ?? []) result.push({ value: dungeon.id, label: dungeon.label });
    return result;
}

export function difficultyItems(): ChoiceItem[] {
    const result: ChoiceItem[] = [];
    for (const difficulty of D.DUNGEON_DIFFICULTIES ?? []) result.push({ value: difficulty.id, label: difficulty.label });
    return result;
}

export function raidItems(): ChoiceItem[] {
    const result: ChoiceItem[] = [];
    for (const raid of D.RAIDS ?? []) result.push({ value: raid.id, label: raid.era + "  ·  " + raid.label });
    return result;
}

export function raidDifficultyItems(): ChoiceItem[] {
    const result: ChoiceItem[] = [{ value: "normal", label: "Normal" }];
    const raid = D.GetRaidById(config().activity);
    if (raid?.heroic === true) result.push({ value: "heroic", label: "Heroic" });
    return result;
}

export function selectedActivityLabel(): string {
    const cfg = config();
    if (cfg.mode === "RAID") {
        const raid = D.GetRaidById(cfg.activity);
        return raid?.label ?? "Raid";
    }
    const dungeon = D.GetDungeonById(cfg.activity);
    return dungeon?.label ?? "Dungeon";
}

export function supportedRaidSizes(): number[] {
    const raid = D.GetRaidById(config().activity);
    const result: number[] = [];
    for (const size of raid?.sizes ?? []) result.push(Number(size));
    return result;
}

export function setMode(mode: "DUNGEON" | "RAID"): void { GC.SetMode(GC, mode); }
export function setDungeonActivity(id: string): void { GC.SetDungeonActivity(GC, id); }
export function setRaidActivity(id: string): void { GC.SetRaidActivity(GC, id); }
export function setRaidSize(size: number): void { GC.SetRaidSize(GC, size); }
export function setDifficulty(id: string): void {
    config().difficulty = id;
    touch("Difficulty changed");
}
export function setHumanRole(name: string, role: Role): void { GC.SetHumanRole(GC, name, role); }
export function buildAndPrepare(): void { GC.FindRoster(GC); }
export function assemble(): void { GC.Assemble(GC); }
export function requestAnchors(): void { GC.RequestAnchors(GC); }
export function requestStatus(): void { GC.RequestStatus(GC); }
export function clearPlan(): void { GC.ClearServerPlan(GC); }
export function loadProfile(name: string): void { GC.LoadProfile(GC, name); }
export function saveProfile(name: string): void { GC.SaveProfile(GC, name); }
export function deleteProfile(name: string): void { GC.DeleteProfile(GC, name); }
export function listBuiltinProfiles(): string[] { return P.ListBuiltins() ?? []; }
export function listCustomProfiles(): string[] { return P.ListCustom() ?? []; }
export function addPin(name: string, role: Role, required: boolean): void { GC.AddPinnedMember(GC, name, role, required); }
export function removePin(index: number): void { GC.RemovePinnedMember(GC, index); }

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
    return "Configure roster";
}

export function isBusy(): boolean {
    const phase = String(progress().phase ?? "IDLE");
    return phase === "BUILDING" || phase === "PREPARING" || phase === "ASSEMBLING" || phase === "TRAVEL";
}

export function isTravelRetry(): boolean {
    const p = progress();
    return p.phase === "READY" && String(p.detail ?? "").indexOf("Enter Activity") >= 0;
}

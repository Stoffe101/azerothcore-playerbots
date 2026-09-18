export type Role = "TANK" | "HEALER" | "DPS";
export type ClassId =
    | "WARRIOR" | "PALADIN" | "HUNTER" | "ROGUE" | "PRIEST"
    | "DEATHKNIGHT" | "SHAMAN" | "MAGE" | "WARLOCK" | "DRUID";

export interface SpecDefinition {
    readonly id: number;
    readonly label: string;
    readonly icon: string;
    readonly roles: readonly Role[];
}

export interface ClassDefinition {
    readonly id: ClassId;
    readonly label: string;
    readonly specs: readonly SpecDefinition[];
}

export const CLASS_ORDER: readonly ClassDefinition[] = [
    { id: "WARRIOR", label: "Warrior", specs: [
        { id: 0, label: "Arms", icon: "Interface\\Icons\\Ability_Warrior_SavageBlow", roles: ["DPS"] },
        { id: 1, label: "Fury", icon: "Interface\\Icons\\Ability_Warrior_InnerRage", roles: ["DPS"] },
        { id: 2, label: "Protection", icon: "Interface\\Icons\\Ability_Warrior_DefensiveStance", roles: ["TANK"] },
    ]},
    { id: "PALADIN", label: "Paladin", specs: [
        { id: 0, label: "Holy", icon: "Interface\\Icons\\Spell_Holy_HolyBolt", roles: ["HEALER"] },
        { id: 1, label: "Protection", icon: "Interface\\Icons\\Spell_Holy_DevotionAura", roles: ["TANK"] },
        { id: 2, label: "Retribution", icon: "Interface\\Icons\\Spell_Holy_AuraOfLight", roles: ["DPS"] },
    ]},
    { id: "HUNTER", label: "Hunter", specs: [
        { id: 0, label: "Beast Mastery", icon: "Interface\\Icons\\Ability_Hunter_BeastCall", roles: ["DPS"] },
        { id: 1, label: "Marksmanship", icon: "Interface\\Icons\\Ability_Marksmanship", roles: ["DPS"] },
        { id: 2, label: "Survival", icon: "Interface\\Icons\\Ability_Hunter_SwiftStrike", roles: ["DPS"] },
    ]},
    { id: "ROGUE", label: "Rogue", specs: [
        { id: 0, label: "Assassination", icon: "Interface\\Icons\\Ability_Rogue_Eviscerate", roles: ["DPS"] },
        { id: 1, label: "Combat", icon: "Interface\\Icons\\Ability_BackStab", roles: ["DPS"] },
        { id: 2, label: "Subtlety", icon: "Interface\\Icons\\Ability_Stealth", roles: ["DPS"] },
    ]},
    { id: "PRIEST", label: "Priest", specs: [
        { id: 0, label: "Discipline", icon: "Interface\\Icons\\Spell_Holy_PowerWordShield", roles: ["HEALER"] },
        { id: 1, label: "Holy", icon: "Interface\\Icons\\Spell_Holy_GuardianSpirit", roles: ["HEALER"] },
        { id: 2, label: "Shadow", icon: "Interface\\Icons\\Spell_Shadow_ShadowWordPain", roles: ["DPS"] },
    ]},
    { id: "DEATHKNIGHT", label: "Death Knight", specs: [
        { id: 0, label: "Blood", icon: "Interface\\Icons\\Spell_Deathknight_BloodPresence", roles: ["TANK"] },
        { id: 1, label: "Frost", icon: "Interface\\Icons\\Spell_Deathknight_FrostPresence", roles: ["DPS"] },
        { id: 2, label: "Unholy", icon: "Interface\\Icons\\Spell_Deathknight_UnholyPresence", roles: ["DPS"] },
    ]},
    { id: "SHAMAN", label: "Shaman", specs: [
        { id: 0, label: "Elemental", icon: "Interface\\Icons\\Spell_Nature_Lightning", roles: ["DPS"] },
        { id: 1, label: "Enhancement", icon: "Interface\\Icons\\Spell_Nature_LightningShield", roles: ["DPS"] },
        { id: 2, label: "Restoration", icon: "Interface\\Icons\\Spell_Nature_HealingWaveGreater", roles: ["HEALER"] },
    ]},
    { id: "MAGE", label: "Mage", specs: [
        { id: 0, label: "Arcane", icon: "Interface\\Icons\\Spell_Holy_MagicalSentry", roles: ["DPS"] },
        { id: 1, label: "Fire", icon: "Interface\\Icons\\Spell_Fire_FireBolt02", roles: ["DPS"] },
        { id: 2, label: "Frost", icon: "Interface\\Icons\\Spell_Frost_FrostBolt02", roles: ["DPS"] },
    ]},
    { id: "WARLOCK", label: "Warlock", specs: [
        { id: 0, label: "Affliction", icon: "Interface\\Icons\\Spell_Shadow_DeathCoil", roles: ["DPS"] },
        { id: 1, label: "Demonology", icon: "Interface\\Icons\\Spell_Shadow_Metamorphosis", roles: ["DPS"] },
        { id: 2, label: "Destruction", icon: "Interface\\Icons\\Spell_Fire_Immolation", roles: ["DPS"] },
    ]},
    { id: "DRUID", label: "Druid", specs: [
        { id: 0, label: "Balance", icon: "Interface\\Icons\\Spell_Nature_StarFall", roles: ["DPS"] },
        { id: 1, label: "Feral", icon: "Interface\\Icons\\Ability_Druid_CatForm", roles: ["TANK", "DPS"] },
        { id: 2, label: "Restoration", icon: "Interface\\Icons\\Spell_Nature_HealingTouch", roles: ["HEALER"] },
    ]},
];

export function specSupportsRole(spec: SpecDefinition, role: Role): boolean {
    for (const supported of spec.roles) if (supported === role) return true;
    return false;
}

export function getClassesForRole(role: Role): ClassDefinition[] {
    const result: ClassDefinition[] = [];
    for (const classDef of CLASS_ORDER) {
        for (const spec of classDef.specs) {
            if (specSupportsRole(spec, role)) {
                result.push(classDef);
                break;
            }
        }
    }
    return result;
}

export function getSpecsForRole(classId: ClassId, role: Role): SpecDefinition[] {
    const result: SpecDefinition[] = [];
    for (const classDef of CLASS_ORDER) {
        if (classDef.id !== classId) continue;
        for (const spec of classDef.specs) if (specSupportsRole(spec, role)) result.push(spec);
        break;
    }
    return result;
}

export function getClass(classId: ClassId): ClassDefinition | undefined {
    for (const classDef of CLASS_ORDER) if (classDef.id === classId) return classDef;
    return undefined;
}

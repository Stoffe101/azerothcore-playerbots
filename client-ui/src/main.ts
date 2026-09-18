/** @noSelfInFile */

import { createBuildSelector } from "./components/BuildSelector";
import { createModernDashboard } from "./components/ModernDashboard";
import { getClassesForRole, getSpecsForRole } from "./data/WotlkBuilds";

const GC: any = _G.GroupComposer;
let dashboard: any = undefined;

function ensureDashboard(): any {
    if (dashboard !== undefined) return dashboard;
    if (_G.CreateFrame === undefined || GC === undefined || GC.config === undefined) return undefined;

    dashboard = createModernDashboard();
    _G.GroupComposerModernUI.dashboard = dashboard;
    return dashboard;
}

_G.GroupComposerModernUI = {
    version: "0.2.1",
    dashboard: undefined,
    ensureDashboard: () => ensureDashboard(),
    createBuildSelector: (...args: Parameters<typeof createBuildSelector>) => createBuildSelector(...args),
    createModernDashboard: () => createModernDashboard(),
    getClassesForRole: (role: Parameters<typeof getClassesForRole>[0]) => getClassesForRole(role),
    getSpecsForRole: (
        classId: Parameters<typeof getSpecsForRole>[0],
        role: Parameters<typeof getSpecsForRole>[1],
    ) => getSpecsForRole(classId, role),
};

// Core.lua registers /gc before this generated file is loaded. Install a lazy toggle now,
// then construct the heavy dashboard only after ADDON_LOADED has initialized GC.config.
if (GC !== undefined) {
    GC.Toggle = () => {
        const ui = ensureDashboard();
        if (ui !== undefined) ui.toggle();
    };

    GC.RegisterCallback(GC, "CONFIG_CHANGED", () => {
        const ui = ensureDashboard();
        if (ui !== undefined && ui.frame.IsShown()) ui.refresh();
    });
}

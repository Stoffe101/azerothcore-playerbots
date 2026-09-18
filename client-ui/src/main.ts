/** @noSelfInFile */

import { createBuildSelector } from "./components/BuildSelector";
import { createModernDashboard } from "./components/ModernDashboard";
import { getClassesForRole, getSpecsForRole } from "./data/WotlkBuilds";

const dashboard = _G.CreateFrame !== undefined ? createModernDashboard() : undefined;

_G.GroupComposerModernUI = {
    version: "0.2.0",
    dashboard,
    createBuildSelector: (...args: Parameters<typeof createBuildSelector>) => createBuildSelector(...args),
    createModernDashboard: () => createModernDashboard(),
    getClassesForRole: (role: Parameters<typeof getClassesForRole>[0]) => getClassesForRole(role),
    getSpecsForRole: (
        classId: Parameters<typeof getSpecsForRole>[0],
        role: Parameters<typeof getSpecsForRole>[1],
    ) => getSpecsForRole(classId, role),
};

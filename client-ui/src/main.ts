import { createBuildSelector } from "./components/BuildSelector";
import { createModernDashboard } from "./components/ModernDashboard";
import { getClassesForRole, getSpecsForRole } from "./data/WotlkBuilds";

const dashboard = _G.CreateFrame !== undefined ? createModernDashboard() : undefined;

_G.GroupComposerModernUI = {
    version: "0.2.0",
    dashboard,
    createBuildSelector,
    createModernDashboard,
    getClassesForRole,
    getSpecsForRole,
};

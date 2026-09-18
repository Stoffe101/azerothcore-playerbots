local bundle = assert(arg[1], "expected generated bundle path")
dofile(bundle)

assert(type(GroupComposerModernUI) == "table", "modern UI API was not exported")
assert(GroupComposerModernUI.version == "0.4.0", "unexpected modern UI API version")

local tanks = GroupComposerModernUI.getClassesForRole("TANK")
local healers = GroupComposerModernUI.getClassesForRole("HEALER")
local dps = GroupComposerModernUI.getClassesForRole("DPS")
print("selector counts", #tanks, #healers, #dps)
assert(#tanks == 4, "tank class filter must expose exactly four project-supported tank classes")
assert(#healers == 4, "healer class filter must expose exactly four healer classes")
assert(#dps == 10, "DPS class filter must expose all ten project-supported classes")

local priestHeals = GroupComposerModernUI.getSpecsForRole("PRIEST", "HEALER")
assert(#priestHeals == 2, "Priest healer filter must expose Discipline + Holy only")
assert(priestHeals[1].label == "Discipline")
assert(priestHeals[2].label == "Holy")

local mageTank = GroupComposerModernUI.getSpecsForRole("MAGE", "TANK")
assert(#mageTank == 0, "Mage must not expose a tank spec")

local druidTank = GroupComposerModernUI.getSpecsForRole("DRUID", "TANK")
local druidDps = GroupComposerModernUI.getSpecsForRole("DRUID", "DPS")
assert(#druidTank == 1 and druidTank[1].label == "Feral", "Druid tank filter must expose Feral")
assert(#druidDps == 2, "Druid DPS filter must expose Balance + Feral")

print("Group Composer modern UI smoke test passed")

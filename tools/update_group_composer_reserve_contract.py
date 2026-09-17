from pathlib import Path

p = Path('client-addons-src/GroupComposer/tests/test_server_contract.py')
s = p.read_text(encoding='utf-8')

old = '''assert "if (!member.managed)" in validation, (\n    "Managed RaidRoster bots must remain exempt from live role/spec checks because Assemble reconciles them"\n)'''
new = '''assert "if (!member.managed && !member.needsPreparation && !member.reserve)" in validation, (\n    "Only already-correct ordinary live bots should be hard-revalidated before preparation"\n)\nassert "bool reserve = false;" in TYPES and "bool needsPreparation = false;" in TYPES, (\n    "Reserve/preparation state must remain explicit instead of overloading the legacy managed flag"\n)'''
if s.count(old) != 1:
    raise SystemExit('validation contract anchor changed')
s = s.replace(old, new, 1)

old = '''assert "projected.managed = true;" in retask, (\n    "Retasked world/guild bots are not routed through assembly-time spec/strategy synchronization"\n)'''
new = '''assert "projected.needsPreparation = true;" in retask, (\n    "Retasked world/guild bots are not routed through assembly-time build preparation"\n)'''
if s.count(old) != 1:
    raise SystemExit('retask contract anchor changed')
s = s.replace(old, new, 1)

# Multi-user reserve contract. Keep this in the existing source-level contract suite so it runs in
# the ordinary Group Composer CI job without adding another workflow surface.
append = '''\n# Shared Composer reserve semantics: population target stays authoritative while up to two full\n# 40-bot sessions can lease protected online slots from the same world population.\nRESERVE_H = (ROOT / "modules/mod-raid-roster/src/GroupComposerReserve.h").read_text(encoding="utf-8")\nRESERVE_CPP = (ROOT / "modules/mod-raid-roster/src/GroupComposerReserve.cpp").read_text(encoding="utf-8")\nRESERVE_PATCH = (ROOT / "patches/0034-playerbot-group-composer-reserve.patch").read_text(encoding="utf-8")\nassert "GLOBAL_LIMIT = 80" in RESERVE_H, "Global Composer reserve must remain 80 bot slots"\nassert "PER_OWNER_LIMIT = 40" in RESERVE_H, "One player must not consume more than a full 40-bot roster"\nassert "Reserve::AcquirePlan(master, plan, reserveError)" in SERVER, "Assemble no longer leases Composer capacity before destructive work"\nassert "reserve = true" in PLANNER, "Offline RNDbot class bodies are no longer exposed to the Composer reserve"\nassert "ActivateGroupComposerBot" in RESERVE_PATCH and "ReleaseGroupComposerBot" in RESERVE_PATCH, (\n    "Playerbot population integration lost Composer activation/release hooks"\n)\nassert "IsGroupComposerReserved(guid)" in RESERVE_PATCH, (\n    "Composer-owned bots are no longer protected from ordinary population removal"\n)\n'''
if 'GLOBAL_LIMIT = 80' not in s:
    s += append

p.write_text(s, encoding='utf-8')
print('reserve contract test updated')

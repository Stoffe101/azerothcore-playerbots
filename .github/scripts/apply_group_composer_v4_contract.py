from pathlib import Path

path = Path('client-addons-src/GroupComposer/tests/test_server_contract.py')
text = path.read_text(encoding='utf-8')

old = '''try_invite = section(SERVER, "void TryInviteMissing(", "uint8 LfgRole(")
assert "BotHasOtherGameClientMaster(master, bot)" in try_invite, (
    "Asynchronous invite retries can still pull a bot away from another active player"
)
'''
new = '''attach = section(SERVER, "void TryAttachMissing(", "uint8 LfgRole(")
assert "BotHasOtherGameClientMaster(master, bot)" in attach, (
    "Direct Composer attachment can still pull a bot away from another active player"
)
assert "group->AddMember(bot)" in attach, (
    "Prepared Playerbots must be attached through AzerothCore group membership instead of the chatty invite handshake"
)
assert "InviteHuman(master, player)" in attach, (
    "Real humans must keep the normal player-facing invitation path"
)
assert "InviteToGroupAction" not in SERVER, (
    "V4 must not regress Playerbots to the slow invite/accept handshake"
)
'''
if old not in text:
    raise SystemExit('old TryInviteMissing contract block drifted')
text = text.replace(old, new, 1)

old = '''assemble = section(SERVER, "bool GroupComposerCommand::HandleAssemble", "bool GroupComposerCommand::HandleQueue")
assert "member.reserve" in assemble, "Reserve identity is not carried into assembly-time preparation"
'''
new = '''prepare = section(SERVER, "bool PreparePlan(Player* master, Plan& plan", "bool EnsureComposerGroup(")
assert "Reserve::AcquirePlan(master, plan" in prepare, "Build & Prepare no longer reserves selected bot capacity"
assert "s_pendingSync[member.guid.GetCounter()]" in prepare, "Offline prepared bots are no longer tracked through login synchronization"
assert "bool preparing = false;" in TYPES and "bool prepared = false;" in TYPES, (
    "Plan lost the explicit V4 preparation state"
)
assert 'PSendSysMessage("[GC]|PROGRESS|' in SERVER, "Server no longer publishes granular V4 progress"
assemble = section(SERVER, "bool GroupComposerCommand::HandleAssemble", "bool GroupComposerCommand::HandleQueue")
assert "!plan.prepared || plan.preparing || OwnerHasPendingSync(owner)" in assemble, (
    "Assemble can commit before Build & Prepare is complete"
)
assert "PruneUnselectedBots(master, plan)" in assemble, "Destructive commit boundary disappeared"
'''
if old not in text:
    raise SystemExit('old assembly preparation contract block drifted')
text = text.replace(old, new, 1)

text = text.replace(
    '# and refuse to keep/invite a selected bot if ownership changes during the asynchronous assemble step.',
    '# and refuse to attach a selected bot if ownership changes during the asynchronous commit step.',
    1,
)
text = text.replace(
    '# Shared Composer reserve semantics: population target stays authoritative while up to two full',
    '# Shared Composer reserve semantics: population target stays authoritative while up to two full',
    1,
)

# V4 acquires capacity during Build & Prepare, then revalidates the same lease at the explicit commit.
old = 'assert "Reserve::AcquirePlan(master, plan, reserveError)" in SERVER, "Assemble no longer leases Composer capacity before destructive work"'
new = '''assert SERVER.count("Reserve::AcquirePlan(master, plan") >= 2, (
    "Composer must reserve at preview preparation and revalidate the lease at Assemble"
)'''
if old not in text:
    raise SystemExit('reserve acquisition contract drifted')
text = text.replace(old, new, 1)

path.write_text(text, encoding='utf-8')
print('Group Composer V4 source contract updated')
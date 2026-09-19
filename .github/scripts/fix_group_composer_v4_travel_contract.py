from pathlib import Path

path = Path('client-addons-src/GroupComposer/tests/test_server_contract.py')
text = path.read_text(encoding='utf-8')
old = 'dungeon_server = section(SERVER, "uint32 DungeonMapId(", "bool IsBotGuid(")'
new = 'dungeon_server = section(SERVER, "uint32 DungeonMapId(", "uint32 RaidMapId(")'
if old in text:
    text = text.replace(old, new, 1)
elif new not in text:
    raise SystemExit('dungeon map contract boundary marker drifted')

# The travel stage appends the raid-map assertions themselves. This boundary fix just prevents the
# pre-existing dungeon parser from swallowing the new RaidMapId table as if it were RDF metadata.
path.write_text(text, encoding='utf-8')
print('Group Composer dungeon/raid map contract boundary fixed')

#!/usr/bin/env python3
"""Source-level integration checks for the runtime-hardening contracts."""

from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[2]
CORE = ROOT / "azerothcore-wotlk"


def read(path: Path) -> str:
    if not path.is_file():
        raise AssertionError(f"missing assembled source: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        raise AssertionError(f"missing {label}: {needle}")


admin = read(ROOT / "modules/mod-admin-panel/src/AdminPanel.cpp")
gameplay = read(ROOT / "modules/mod-admin-panel/src/AdminPanelGameplay.cpp")
panel = read(ROOT / "client-addons-src/AdminPanel/AdminPanel.lua")
factory = read(CORE / "modules/mod-playerbots/src/Bot/Factory/RandomPlayerbotFactory.cpp")
manager = read(CORE / "modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp")
shaman_actions = read(CORE / "modules/mod-playerbots/src/Ai/Class/Shaman/ShamanActions.cpp")
shaman_triggers = read(CORE / "modules/mod-playerbots/src/Ai/Class/Shaman/ShamanTriggers.cpp")
storage = read(CORE / "src/server/game/Entities/Player/PlayerStorage.cpp")
era = read(CORE / "modules/mod-era-talents/src/EraTalents.cpp")
era_pin = read(CORE / "modules/mod-era-talents/src/EraTalentPin.cpp")
era_comms = read(CORE / "modules/mod-era-talents/src/EraTalentsComms.cpp")
client_comms = read(CORE / "modules/mod-era-talents/client-addon/EraTalents/Comms.lua")
client_ui = read(CORE / "modules/mod-era-talents/client-addon/EraTalents/TalentUI.lua")
lfg = read(CORE / "src/server/game/DungeonFinding/LFGMgr.cpp")
starter_store = read(ROOT / "modules/mod-raid-roster/src/AdventureProgressionStore.cpp")
guild_services = read(ROOT / "modules/mod-playerbot-chatter/src/PBAIGuildServices.cpp")

require(panel, "ipairs({ 500, 750, 1000, 1500 })", "large-population preset list")
for target in (500, 750, 1000, 1500):
    require(panel, 'targetValue .. " Bots"', f"shared {target}-bot preset path")
require(gameplay, "constexpr uint32 MAX_BOT_TARGET = 1500u", "1500 target ceiling")
require(gameplay, "sPlayerbotAIConfig.minRandomBots = target", "single live target path")
require(gameplay, "sPlayerbotAIConfig.maxRandomBots = target", "single live target path")
fast_preset = admin[admin.index('else if (preset == "fast")'):admin.index('else if (preset == "raid")')]
require(fast_preset, "ApplyGoldRate(1.0f)", "1x fast-preset gold")
require(fast_preset, 'SaveSetting(GOLD_RATE_KEY, "1")', "persisted 1x fast-preset gold")

require(factory, "sPlayerbotAIConfig.randomBotAccounts.clear()", "duplicate account-list prevention")
require(factory, "ProvisionRandomBotCapacityStep", "bounded capacity provisioning")
require(factory, "CharacterDatabase.QueueSize()", "capacity DB backpressure")
require(manager, "ScaleDownRandomBots", "bounded population downscale")
require(manager, "WORLD_UPDATE_LOGIN_BACKPRESSURE_MS", "world-update login backpressure")
require(manager, "IsProtectedFromPopulationRemoval", "protected-bot downscale guard")
require(manager, "PlayerbotGuildMgr::instance().IsRealGuild", "persistent guild protection")
require(manager, "sLFGMgr->GetState", "LFG population protection")
require(manager, "IsInRandomAccountList", "human-account exclusion")
require(shaman_actions, "bot->removeActionButton(actionButtonId)", "stale generated totem cleanup")
require(shaman_actions, "!bot->HasSpell(button->GetAction())", "stale generated spell validation")
require(shaman_triggers, "!bot->HasSpell(button->GetAction())", "stale totem cleanup trigger")

hook = storage.index("OnPlayerBeforeLoadActionButtons")
actions = storage.index("_LoadActions", hook)
assert hook < actions, "custom spells must restore before action validation"
require(era_pin, "void OnPlayerBeforeLoadActionButtons", "pre-action Era lifecycle hook")
require(era_pin, "if (!sEraTalentsConfig->Enabled() || IsBot(p))", "human-only early Era restore")
require(era, "HumanActionSlotsForSpell", "rank-up slot capture")
require(era, "ReplaceActionBarSpell", "rank-up slot replacement")

require(era_comms, '"ERATAL\\tDELTA "', "incremental talent response")
require(client_comms, "BeginSyncHandshake", "initial sync retry handshake")
require(client_comms, "pendingTalent", "duplicate talent-click guard")
require(client_comms, "ET.RequestSync()", "desync fallback")
require(client_ui, "RefreshTalentChange", "incremental talent repaint")

require(lfg, "Human LFG request accepted", "human LFG diagnostics")
require(lfg, "Human LFG teleport rejected", "human LFG failure diagnostics")
require(starter_store, "CharacterDatabase.CommitTransaction(trans)", "async starter persistence")
require(guild_services, "CharacterDatabase.AsyncCommitTransaction(transaction)", "prepared-save async transaction")
require(guild_services, "HasPendingTransaction", "guild transaction serialization")

custom_sources = list((ROOT / "modules").rglob("*.cpp")) + list((ROOT / "modules").rglob("*.h"))
for source in custom_sources:
    text = read(source)
    offset = 0
    while True:
        direct = text.find("DirectCommitTransaction", offset)
        if direct < 0:
            break
        begin = text.rfind("BeginTransaction", 0, direct)
        transaction = text[begin:direct] if begin >= 0 else ""
        if re.search(r"(?:SaveToDB|SaveInventoryAndGoldToDB|SaveGoldToDB)\s*\(\s*trans", transaction):
            raise AssertionError(f"prepared save reaches a synchronous transaction in {source.relative_to(ROOT)}")
        offset = direct + 1

for source in list((ROOT / "modules").rglob("*.cpp")) + list((ROOT / "modules").rglob("*.sql")):
    collapsed = re.sub(r"\s+", " ", read(source)).upper()
    if re.search(r"SELECT DISTINCT .{0,500} ORDER BY", collapsed):
        raise AssertionError(f"review DISTINCT/ORDER BY query in {source.relative_to(ROOT)}")

print("PASS: runtime-hardening source contracts")

#include "RaidRosterStore.h"
#include "RaidRosterGuild.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "ObjectAccessor.h"
#include "ObjectGuid.h"
#include "Player.h"
#include "QueryResult.h"

namespace
{
void SyncConnectedOwnerGuild(uint32 ownerGuid)
{
    Player* owner = ObjectAccessor::FindConnectedPlayer(
        ObjectGuid::Create<HighGuid::Player>(static_cast<ObjectGuid::LowType>(ownerGuid)));
    if (!owner || !owner->GetGuildId())
        return;

    RaidRosterGuild::SyncRosterToOwnerGuild(owner, RaidRosterStore::Load(ownerGuid));
}
}

namespace RaidRosterStore
{
    bool Exists(uint32 ownerGuid)
    {
        QueryResult r = CharacterDatabase.Query(
            "SELECT 1 FROM mod_raid_roster WHERE owner_guid = {} LIMIT 1", ownerGuid);
        return r != nullptr;
    }

    std::vector<RaidRosterRow> Load(uint32 ownerGuid)
    {
        std::vector<RaidRosterRow> rows;
        QueryResult r = CharacterDatabase.Query(
            "SELECT bot_guid, class, role, spec_tab, slot_index, band FROM mod_raid_roster "
            "WHERE owner_guid = {} ORDER BY slot_index", ownerGuid);
        if (!r) return rows;
        do {
            Field* f = r->Fetch();
            RaidRosterRow row;
            row.botGuid = f[0].Get<uint32>();
            row.cls     = f[1].Get<uint8>();
            row.role    = f[2].Get<uint8>();
            row.specTab = f[3].Get<uint8>();
            row.slot    = f[4].Get<uint8>();
            row.band    = f[5].Get<uint8>();
            rows.push_back(row);
        } while (r->NextRow());
        return rows;
    }

    static void AppendInserts(CharacterDatabaseTransaction& trans, uint32 ownerGuid,
                              std::vector<RaidRosterRow> const& rows)
    {
        for (RaidRosterRow const& row : rows)
            trans->Append("INSERT INTO mod_raid_roster "
                "(owner_guid, bot_guid, class, role, spec_tab, slot_index, band) "
                "VALUES ({}, {}, {}, {}, {}, {}, {})",
                ownerGuid, row.botGuid, row.cls, row.role, row.specTab, row.slot, row.band);
    }

    void Replace(uint32 ownerGuid, std::vector<RaidRosterRow> const& rows)
    {
        CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
        trans->Append("DELETE FROM mod_raid_roster WHERE owner_guid = {}", ownerGuid);
        AppendInserts(trans, ownerGuid, rows);
        CharacterDatabase.CommitTransaction(trans);

        // A roster created while its owner is already in a guild should become that guild's
        // actual membership immediately, not merely a private list of controllable bots.
        SyncConnectedOwnerGuild(ownerGuid);
    }

    void Append(uint32 ownerGuid, std::vector<RaidRosterRow> const& rows)
    {
        if (rows.empty()) return;
        CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
        AppendInserts(trans, ownerGuid, rows);
        CharacterDatabase.CommitTransaction(trans);

        // Top-ups inherit the same real-guild membership contract as the original roster.
        SyncConnectedOwnerGuild(ownerGuid);
    }

    void UpdateBands(uint32 ownerGuid, std::vector<std::pair<uint8, uint8>> const& slotBands)
    {
        if (slotBands.empty()) return;
        CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
        for (auto const& [slot, band] : slotBands)
            trans->Append("UPDATE mod_raid_roster SET band = {} WHERE owner_guid = {} AND slot_index = {}",
                band, ownerGuid, slot);
        CharacterDatabase.CommitTransaction(trans);
    }

    void Clear(uint32 ownerGuid)
    {
        CharacterDatabase.Execute("DELETE FROM mod_raid_roster WHERE owner_guid = {}", ownerGuid);
    }

    std::unordered_set<uint32> AllPinnedBots()
    {
        std::unordered_set<uint32> out;
        QueryResult r = CharacterDatabase.Query("SELECT bot_guid FROM mod_raid_roster");
        if (!r) return out;
        do { out.insert(r->Fetch()[0].Get<uint32>()); } while (r->NextRow());
        return out;
    }
}

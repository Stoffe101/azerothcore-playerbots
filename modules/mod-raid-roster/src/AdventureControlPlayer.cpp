#include "AdventureControlStore.h"

#include "Player.h"
#include "Playerbots.h"
#include "ScriptMgr.h"

#include <algorithm>
#include <cstdint>
#include <limits>

namespace
{
uint32 ScaleUnsigned(uint32 amount, uint16 percent)
{
    uint64 scaled = static_cast<uint64>(amount) * static_cast<uint64>(percent) / 100u;
    return static_cast<uint32>(std::min<uint64>(scaled, std::numeric_limits<uint32>::max()));
}

int32 ScalePositiveSigned(int32 amount, uint16 percent)
{
    if (amount <= 0)
        return amount;

    int64 scaled = static_cast<int64>(amount) * static_cast<int64>(percent) / 100;
    return static_cast<int32>(std::min<int64>(scaled, std::numeric_limits<int32>::max()));
}

class AdventureControlPlayerScript : public PlayerScript
{
public:
    AdventureControlPlayerScript() : PlayerScript("AdventureControlPlayerScript") { }

    void OnPlayerLogin(Player* player) override
    {
        if (!player || !IsRealPlayer(player))
            return;
        AdventureControlStore::Load(player->GetGUID().GetCounter());
    }

    void OnPlayerLogout(Player* player) override
    {
        if (!player || !IsRealPlayer(player))
            return;
        AdventureControlStore::Forget(player->GetGUID().GetCounter());
    }

    void OnPlayerGiveXP(Player* player, uint32& amount, Unit* /*victim*/, uint8 /*xpSource*/) override
    {
        if (!player || !IsRealPlayer(player))
            return;
        AdventureControlRates rates = AdventureControlStore::Get(player->GetGUID().GetCounter());
        amount = ScaleUnsigned(amount, rates.xpPercent);
    }

    void OnPlayerMoneyChanged(Player* player, int32& amount) override
    {
        if (!player || !IsRealPlayer(player) || amount <= 0)
            return;
        AdventureControlRates rates = AdventureControlStore::Get(player->GetGUID().GetCounter());
        amount = ScalePositiveSigned(amount, rates.goldPercent);
    }

    void OnPlayerGiveReputation(Player* player, int32 /*factionID*/, float& amount, ReputationSource /*repSource*/) override
    {
        if (!player || !IsRealPlayer(player) || amount <= 0.0f)
            return;
        AdventureControlRates rates = AdventureControlStore::Get(player->GetGUID().GetCounter());
        amount *= static_cast<float>(rates.repPercent) / 100.0f;
    }
};
}

void AddAdventureControlPlayerScripts()
{
    new AdventureControlPlayerScript();
}

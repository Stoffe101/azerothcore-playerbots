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

    // OnPlayerMoneyChanged also sees transfers and mailbox withdrawals, so applying a generic gold
    // multiplier there would mint money from transfers. Personal gold remains source-safe at 1.0x.

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

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

    // There is intentionally no OnPlayerMoneyChanged multiplier. That hook sees every positive
    // balance change, including taking gold from mail and receiving transfers, so applying a
    // personal rate there creates currency from transfers. Gold stays source-safe at 1.0x until
    // we add reward-source-specific hooks (creature money, quests, etc.).

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

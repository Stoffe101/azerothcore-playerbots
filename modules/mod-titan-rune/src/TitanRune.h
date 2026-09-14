#ifndef MOD_TITAN_RUNE_H
#define MOD_TITAN_RUNE_H

#include "Define.h"
#include "ObjectGuid.h"

#include <cstdint>
#include <string>
#include <vector>

class Creature;
class Player;
class Unit;
class Map;

namespace TitanRune
{
    enum class Protocol : uint8
    {
        None  = 0,
        Alpha = 1,
        Beta  = 2,
        Gamma = 3,
    };

    enum class Family : uint8
    {
        None      = 0,
        Frost     = 1,
        Shadow    = 2,
        Blood     = 3,
        Arcane    = 4,
        Plague    = 5,
        Titan     = 6,
        Gladiator = 7,
    };

    enum CustomEntries : uint32
    {
        NPC_PROTOCOL_DEVICE       = 900100,
        NPC_GAMMA_WARDEN          = 900101,
        NPC_BLOOD_CAULDRON        = 900102,
        NPC_ARCANE_MIRROR_CASTER  = 900103,
        NPC_ARCANE_MIRROR_MELEE   = 900104,
        NPC_ARCANE_MIRROR_HEALER  = 900105,
        NPC_PLAGUE_ZOMBIE_HORROR  = 900106,
        NPC_TITAN_TENTACLE        = 900107,
        NPC_SIDEREAL_VENDOR       = 900110,
        NPC_SCOURGESTONE_VENDOR_A = 900111,
        NPC_SCOURGESTONE_VENDOR_H = 900112,

        ITEM_SIDEREAL_ESSENCE     = 900001,
        ITEM_DEFILERS_SCOURGESTONE= 900002,
        ITEM_HOLY_HAND_GRENADE    = 900003,
    };

    enum class GammaBuff : uint8
    {
        None            = 0,
        ShatterArmor    = 1,
        RallyingCry     = 2,
        ConfessorsWrath = 3,
        ShieldOfThorns  = 4,
    };

    struct VendorItem
    {
        uint32 itemId;
        uint32 cost;
    };

    bool IsSupportedMap(uint32 mapId);
    bool SupportsAlpha(uint32 mapId);
    Family GetFamily(uint32 mapId);
    char const* FamilyName(Family family);
    char const* ProtocolName(Protocol protocol);

    Protocol GetProtocol(Map const* map);
    Protocol GetProtocol(Unit const* unit);
    bool Activate(Player* player, Protocol protocol);
    void OnPlayerEnter(Player* player);
    void OnCreatureUpdate(Creature* creature, uint32 diff);
    void OnCreatureRemove(Creature* creature);
    void OnUnitDamage(Unit* attacker, Unit* victim, uint32& damage);
    void OnMeleeDamage(Unit* target, Unit* attacker, uint32& damage);
    void OnHeal(Unit* healer, Unit* receiver, uint32& gain);
    void OnPlayerUpdate(Player* player, uint32 diff);
    void OnUnitDeath(Unit* unit, Unit* killer);
    void OnStartup();
    void OnShutdown();

    void SetGammaBuff(Player* player, GammaBuff buff);
    GammaBuff GetGammaBuff(Player const* player);
    void GrantBloodBrew(Player* player);
    bool UseGrenade(Player* player);

    std::vector<VendorItem> const& SiderealVendorItems();
    std::vector<VendorItem> const& ScourgestoneAllianceItems();
    std::vector<VendorItem> const& ScourgestoneHordeItems();
    bool BuyVendorItem(Player* player, uint32 currencyItem, VendorItem const& offer);

    // Utility for gossip/status displays.
    std::string Status(Player const* player);
}

#endif

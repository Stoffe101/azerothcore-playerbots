#ifndef MOD_RAID_ROSTER_GROUP_COMPOSER_TYPES_H
#define MOD_RAID_ROSTER_GROUP_COMPOSER_TYPES_H

#include "ObjectGuid.h"
#include "Optional.h"

#include <cstdint>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace GroupComposer
{
constexpr uint8 ROLE_TANK = 0;
constexpr uint8 ROLE_HEALER = 1;
constexpr uint8 ROLE_DPS = 2;
constexpr uint8 ANY_SPEC = 0xFF;

enum Utility : uint32
{
    UTILITY_INTERRUPT   = 1u << 0,
    UTILITY_DISPEL      = 1u << 1,
    UTILITY_RAID_BUFF   = 1u << 2,
    UTILITY_HEROISM     = 1u << 3,
    UTILITY_BATTLE_REZ  = 1u << 4,
    UTILITY_CC          = 1u << 5,
    UTILITY_THREAT      = 1u << 6,
};

struct Preference
{
    uint8 role = ROLE_DPS;
    uint8 cls = 0;          // 0 = any class
    uint8 spec = ANY_SPEC;  // talent tab, or ANY_SPEC
    bool required = false;
};

struct AddedHuman
{
    std::string name;
    uint8 role = ROLE_DPS;
};

struct Pin
{
    std::string name;
    uint8 role = ROLE_DPS;
    bool required = false;
};

struct Config
{
    std::string mode = "dungeon";
    std::string activity = "random";
    std::string difficulty = "heroic";
    uint8 size = 5;
    uint8 tanks = 1;
    uint8 healers = 1;
    uint8 dps = 3;

    bool preferGuild = true;
    bool fillWorld = true;
    bool keepMe = true;
    bool balanceClasses = true;
    bool balanceUtility = true;
    bool balanceRange = true;
    bool avoidDuplicates = false;
    uint16 minimumItemLevel = 0;

    std::vector<Preference> preferences;
    std::unordered_map<std::string, uint8> humanRoles;
    std::vector<AddedHuman> extraHumans;
    std::vector<Pin> pins;
    std::unordered_map<std::string, uint8> arrangement;
};

struct Candidate
{
    ObjectGuid guid;
    std::string name;
    uint8 cls = 0;
    uint8 role = ROLE_DPS;
    uint8 spec = ANY_SPEC;

    bool guild = false;
    bool online = false;
    bool managed = false;
    bool alreadyGrouped = false;
    float itemLevel = 0.0f;

    uint32 utilityMask = 0;
    bool rangedDps = false;
};

struct Member
{
    ObjectGuid guid;
    std::string name;
    uint8 cls = 0;
    uint8 role = ROLE_DPS;
    uint8 spec = ANY_SPEC;
    uint8 subgroup = 1;

    bool human = false;
    bool locked = false;
    bool guild = false;
    bool managed = false;
    bool pinned = false;
    bool online = true;

    uint32 utilityMask = 0;
    bool rangedDps = false;
};

struct Coverage
{
    uint32 utilityMask = 0;
    uint8 rangedDps = 0;
    uint8 meleeDps = 0;
};

struct Plan
{
    Config config;
    std::vector<Member> members;
    std::vector<std::string> warnings;
    Coverage coverage;

    uint32 guildCandidates = 0;
    uint32 worldCandidates = 0;
    uint32 managedCandidates = 0;

    // Human invitations are intentionally one-shot for each explicit Assemble attempt. If a real
    // player declines, the composer waits and eventually reports a timeout instead of re-inviting
    // them every world update tick. A fresh Assemble click clears this set and is the explicit retry.
    std::unordered_set<uint32> humanInvitesSent;

    bool valid = false;
    bool assembling = false;
    uint32 assembleElapsed = 0;
};
}

#endif
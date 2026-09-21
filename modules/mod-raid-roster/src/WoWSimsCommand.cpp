#include "WoWSimsCommand.h"

#include "EraPolicy.h"
#include "Player.h"
#include "RBAC.h"
#include "WoWSimsService.h"

using namespace Acore::ChatCommands;

ChatCommandTable WoWSimsCommand::GetCommands() const
{
    static ChatCommandTable sub =
    {
        { "snapshot", HandleSnapshot, SEC_PLAYER, Console::No },
        { "bags", HandleBags, SEC_PLAYER, Console::No },
        { "request", HandleRequest, SEC_PLAYER, Console::No },
        { "validate", HandleValidate, SEC_PLAYER, Console::No },
    };
    static ChatCommandTable root = { { "wowsims", sub } };
    return root;
}

bool WoWSimsCommand::HandleSnapshot(ChatHandler* handler)
{
    Player* player = handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!player)
    {
        if (handler)
            handler->SendSysMessage("Run .wowsims snapshot in-world as a player.");
        return true;
    }

    std::string const snapshot = WoWSimsService::BuildCharacterSnapshot(player);
    handler->PSendSysMessage(
        "[WoWSims] authoritative snapshot built: {} bytes, era={}, level={}, class={}, dominantTree={}.",
        uint32(snapshot.size()),
        EraPolicy::Token(EraPolicy::CurrentRealmEra()),
        uint32(player->GetLevel()),
        uint32(player->getClass()),
        uint32(player->GetMostPointsTalentTree()));
    return true;
}


bool WoWSimsCommand::HandleBags(ChatHandler* handler)
{
    Player* player = handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!player)
    {
        if (handler)
            handler->SendSysMessage("Run .wowsims bags in-world as a player.");
        return true;
    }

    std::string summary;
    std::string error;
    if (!WoWSimsService::BuildBagCandidateManifest(player, summary, error))
    {
        handler->PSendSysMessage("[WoWSims] bag candidate build failed: {}", error);
        return true;
    }

    handler->PSendSysMessage("[WoWSims] authoritative bag candidates built (not simulated): {}", summary);
    return true;
}


bool WoWSimsCommand::HandleRequest(ChatHandler* handler)
{
    Player* player = handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!player)
    {
        if (handler)
            handler->SendSysMessage("Run .wowsims request in-world as a player.");
        return true;
    }

    std::string summary;
    std::string error;
    if (!WoWSimsService::BuildBaselineRequest(player, summary, error))
    {
        handler->PSendSysMessage("[WoWSims] request build failed: {}", error);
        return true;
    }

    handler->PSendSysMessage("[WoWSims] baseline request built (not simulated): {}", summary);
    return true;
}

bool WoWSimsCommand::HandleValidate(ChatHandler* handler)
{
    Player* player = handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!player)
    {
        if (handler)
            handler->SendSysMessage("Run .wowsims validate in-world as a player.");
        return true;
    }

    std::string summary;
    std::string error;
    if (!WoWSimsService::ValidateCharacterSnapshot(player, summary, error))
    {
        handler->PSendSysMessage("[WoWSims] validation failed: {}", error);
        return true;
    }

    handler->PSendSysMessage("[WoWSims] snapshot accepted: {}", summary);
    return true;
}

#include "PBChatterObserver.h"
#include "PBChatterConfig.h"
#include "PBChatterClassifier.h"
#include "PBChatterContext.h"
#include "PBChatterMemory.h"
#include "PBChatterQueue.h"
#include "PBChatterLore.h"
#include "PBChatterAmbient.h"
#include "PBChatterAmbientPrompt.h"
#include "PBAIGuildServices.h"
#include "PBAIGuildStore.h"
#include "Player.h"
#include "Group.h"
#include "Guild.h"
#include "Channel.h"
#include "SharedDefines.h"
#include "StringFormat.h"

namespace
{
    char const* FamiliarityLabel(uint16 value)
    {
        if (value < 5) return "barely acquainted";
        if (value < 20) return "acquainted";
        if (value < 60) return "familiar";
        return "long-time familiar";
    }

    char const* AffinityLabel(int16 value)
    {
        if (value <= -50) return "strained";
        if (value >= 50) return "warm";
        return "neutral";
    }

    char const* TrustLabel(uint16 value)
    {
        if (value < 10) return "untested";
        if (value < 40) return "some trust";
        return "trusted";
    }

    std::string BuildPrompt(Player* bot, Player* sender, std::string const& msg)
    {
        uint32 botGuid = bot->GetGUID().GetCounter();
        uint32 senderGuid = sender->GetGUID().GetCounter();

        std::string p = PBChatterContext::BuildIdentity(bot);
        p += "\n\nCurrent grounded state: " + PBChatterContext::BuildSnapshot(bot);

        PBAIGuildStore::Relationship relationship = PBAIGuildStore::GetRelationship(botGuid, 0, senderGuid);
        if (relationship.exists)
        {
            p += Acore::StringFormat(
                "\nYour persisted relationship with {} is {}, {}, and {} ({} shared run{} recorded). "
                "Treat this as a tone hint only; never pretend greater closeness or invent events.",
                sender->GetName(),
                FamiliarityLabel(relationship.familiarity),
                AffinityLabel(relationship.affinity),
                TrustLabel(relationship.trust),
                relationship.sharedRuns,
                relationship.sharedRuns == 1 ? "" : "s");
        }

        auto grounded = PBAIGuildStore::GetMemoriesRelatedTo(botGuid, 0, senderGuid, 3);
        if (!grounded.empty())
        {
            p += Acore::StringFormat("\nActual gameplay memories specifically involving {}:", sender->GetName());
            for (PBAIGuildStore::Memory const& memory : grounded)
                p += " [" + memory.summary + "]";
            p += " You may mention these naturally when relevant, but add no unstated details.";
        }

        auto recent = PBChatterMemory::Recent(botGuid, senderGuid);
        if (!recent.empty())
        {
            p += Acore::StringFormat(
                "\n\nYou and {} have talked before. This is your memory of those earlier "
                "chats (oldest first). Stay consistent and never claim it is the first time you met:",
                sender->GetName());
            for (auto const& ex : recent)
                p += Acore::StringFormat("\n{}: {}\nYou: {}", sender->GetName(), ex.first, ex.second);
        }

        p += Acore::StringFormat("\n\n{} just said to you: \"{}\"\nReply briefly, like a normal player chatting back{}.",
                                 sender->GetName(), msg,
                                 (recent.empty() && grounded.empty()) ? "" : ", using only the grounded history above when relevant");
        p += PBChatterAmbientPrompt::StyleExamples(2);
        return p;
    }

    void TouchDirectRelationship(Player* bot, Player* sender)
    {
        if (!bot || !sender)
            return;
        PBAIGuildStore::TouchRelationship(
            bot->GetGUID().GetCounter(), 0, sender->GetGUID().GetCounter(), 1, 0, 0, false);
    }

    void Enqueue(Player* bot, Player* sender, PBChatChannel channel, std::string const& msg)
    {
        PBChatJob job;
        job.botGuid       = bot->GetGUID().GetCounter();
        job.playerGuid    = sender->GetGUID().GetCounter();
        job.playerName    = sender->GetName();
        job.channel       = channel;
        job.systemPrompt  = g_PBChatSystemPrompt;
        job.prompt        = BuildPrompt(bot, sender, msg);
        job.playerMessage = msg;
        TouchDirectRelationship(bot, sender);
        PBChatterQueue::Submit(std::move(job));
    }

    void EnqueueLore(Player* bot, Player* sender, std::string const& msg)
    {
        PBChatJob job;
        job.botGuid       = bot->GetGUID().GetCounter();
        job.playerGuid    = sender->GetGUID().GetCounter();
        job.playerName    = sender->GetName();
        job.channel       = PBChatChannel::Whisper;
        job.systemPrompt  = g_PBChatSystemPrompt;
        job.prompt        = BuildPrompt(bot, sender, msg);
        job.playerMessage = msg;
        job.lore          = true;
        job.lorePayload   = PBChatterLore::BuildPayload(bot, sender, msg);
        TouchDirectRelationship(bot, sender);
        PBChatterQueue::Submit(std::move(job));
    }

    bool Eligible(Player* sender, uint32 lang, std::string const& msg)
    {
        return g_PBChatEnable
            && lang != LANG_ADDON
            && PBChatterClassifier::IsRealPlayerSender(sender)
            && !PBChatterClassifier::IsCommand(msg);
    }

    constexpr uint32 GENERAL_CHANNEL_ID = 1;

    bool BufferEligible(Player* sender, uint32 lang)
    {
        return g_PBChatEnable && g_PBChatAmbientEnable
            && lang != LANG_ADDON
            && PBChatterClassifier::IsRealPlayerSender(sender);
    }
}

bool PBChatterObserver::OnPlayerCanUseChat(Player* player, uint32 type, uint32 lang, std::string& msg)
{
    if (Eligible(player, lang, msg) && (type == CHAT_MSG_SAY || type == CHAT_MSG_YELL))
        for (Player* bot : PBChatterClassifier::ResolveSayTargets(player, msg))
            Enqueue(bot, player, PBChatChannel::Say, msg);
    return true;
}

bool PBChatterObserver::OnPlayerCanUseChat(Player* player, uint32 /*type*/, uint32 lang, std::string& msg, Player* receiver)
{
    if (Eligible(player, lang, msg))
        if (Player* bot = PBChatterClassifier::ResolveWhisperTarget(receiver))
        {
            if (g_PBChatLoreEnable && PBChatterClassifier::IsLikelyQuestion(msg))
                EnqueueLore(bot, player, msg);
            else
                Enqueue(bot, player, PBChatChannel::Whisper, msg);
        }
    return true;
}

bool PBChatterObserver::OnPlayerCanUseChat(Player* player, uint32 type, uint32 lang, std::string& msg, Group* group)
{
    if (Eligible(player, lang, msg))
    {
        bool isRaid = (type == CHAT_MSG_RAID || type == CHAT_MSG_RAID_LEADER || type == CHAT_MSG_RAID_WARNING);
        PBChatChannel ch = isRaid ? PBChatChannel::Raid : PBChatChannel::Party;
        for (Player* bot : PBChatterClassifier::ResolveGroupTargets(player, group, msg))
            Enqueue(bot, player, ch, msg);
    }
    if (group && BufferEligible(player, lang))
        PBChatterAmbient::OnPlayerLine(AMB_GROUP, group->GetGUID().GetRawValue(),
                                       player->GetGUID().GetCounter(), player->GetName(), msg);
    return true;
}

bool PBChatterObserver::OnPlayerCanUseChat(Player* player, uint32 /*type*/, uint32 lang, std::string& msg, Guild* guild)
{
    if (guild && lang != LANG_ADDON && PBChatterClassifier::IsRealPlayerSender(player) &&
        PBAIGuildServices::HandleGuildMessage(player, guild, msg))
        return true;

    if (guild && Eligible(player, lang, msg))
        for (Player* bot : PBChatterClassifier::ResolveGuildTargets(player, guild, msg))
            Enqueue(bot, player, PBChatChannel::Guild, msg);

    if (guild && BufferEligible(player, lang))
        PBChatterAmbient::OnPlayerLine(AMB_GUILD, guild->GetId(),
                                       player->GetGUID().GetCounter(), player->GetName(), msg);
    return true;
}

bool PBChatterObserver::OnPlayerCanUseChat(Player* player, uint32 /*type*/, uint32 lang, std::string& msg, Channel* channel)
{
    if (channel && channel->GetChannelId() == GENERAL_CHANNEL_ID)
    {
        if (Eligible(player, lang, msg))
            for (Player* bot : PBChatterClassifier::ResolveGeneralTargets(player, msg))
                Enqueue(bot, player, PBChatChannel::General, msg);

        if (BufferEligible(player, lang))
            PBChatterAmbient::OnPlayerLine(AMB_ZONE, player->GetZoneId(),
                                           player->GetGUID().GetCounter(), player->GetName(), msg);
    }
    return true;
}

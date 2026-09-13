-- Fresh AdventureStart characters change progression era during their first server login.
-- EraTalents sends its normal HELLO as soon as PLAYER_ENTERING_WORLD fires, which can race
-- that server-side bootstrap and leave the addon showing the pre-transition tree/state until
-- /reload sends another HELLO. Ask once more after the server's 2-second era-transition poll
-- has had time to settle. This is intentionally client-only: no talent logic lives here.

local RESYNC_DELAY_SECONDS = 3.0
local frame = CreateFrame("Frame")

local function ScheduleResync()
    local elapsedTotal = 0

    frame:SetScript("OnUpdate", function(self, elapsed)
        elapsedTotal = elapsedTotal + (elapsed or 0)
        if elapsedTotal < RESYNC_DELAY_SECONDS then
            return
        end

        self:SetScript("OnUpdate", nil)

        if EraTalents and EraTalents.RequestSync then
            EraTalents.RequestSync()
        end
    end)
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        ScheduleResync()
    end
end)

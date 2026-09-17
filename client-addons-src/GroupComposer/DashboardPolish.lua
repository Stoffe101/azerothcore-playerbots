local GC = GroupComposer
local U = GC.Dashboard
if not U or not U.frame then return end

-- The raid mockup reserves a full lower band for eight 5-player subgroup cards. Give the
-- dashboard enough logical height for both subgroup rows, then scale the whole shell to the
-- user's actual resolution instead of clipping the bottom into the footer.
U.frame:SetHeight(920)

function U:ApplyScale()
    local w, h = UIParent:GetWidth() or 1920, UIParent:GetHeight() or 1080
    local scale = math.min((w - 30) / 1320, (h - 40) / 920)
    scale = math.max(0.68, math.min(1.15, scale))
    U.frame:SetScale(scale)
end

local originalShow = U.Show
function U:Show()
    -- ModernUI.lua remains loaded as a compatibility layer for old profiles/widgets, but the
    -- dashboard is the public /gc shell. Never leave both windows stacked on top of each other.
    if GC.UI and GC.UI.frame and GC.UI.frame ~= U.frame then GC.UI.frame:Hide() end
    originalShow(self)
end

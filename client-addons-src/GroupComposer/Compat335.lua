local GC = GroupComposer or {}
GroupComposer = GC

-- WoW 3.3.5a's UIDropDownMenu implementation assumes dropdown frames have a
-- global name and concatenates frame:GetName() with child suffixes. Modern
-- addon code often creates UIDropDownMenuTemplate frames anonymously, which
-- crashes the 3.3.5a FrameXML in UIDropDownMenu_SetWidth.
--
-- Group Composer creates several dropdowns at load time and dynamically later
-- (preferences / people editor). Keep a tiny compatibility wrapper for the
-- session that only names anonymous UIDropDownMenuTemplate frames whose parent
-- belongs to Group Composer. Other addons and ordinary frames are untouched.

if not GC._CreateFrame335Original then
    GC._CreateFrame335Original = CreateFrame
    GC._CreateFrame335DropdownSerial = 0

    local function IsGroupComposerParent(parent)
        local current = parent
        local depth = 0
        while current and depth < 20 do
            local name = current.GetName and current:GetName()
            if type(name) == "string" and string.sub(name, 1, 13) == "GroupComposer" then
                return true
            end
            current = current.GetParent and current:GetParent() or nil
            depth = depth + 1
        end
        return false
    end

    CreateFrame = function(frameType, name, parent, template, ...)
        if name == nil
            and frameType == "Frame"
            and type(template) == "string"
            and string.find(template, "UIDropDownMenuTemplate", 1, true)
            and IsGroupComposerParent(parent)
        then
            GC._CreateFrame335DropdownSerial = GC._CreateFrame335DropdownSerial + 1
            name = "GroupComposerDropDown335_" .. GC._CreateFrame335DropdownSerial
        end

        return GC._CreateFrame335Original(frameType, name, parent, template, ...)
    end
end

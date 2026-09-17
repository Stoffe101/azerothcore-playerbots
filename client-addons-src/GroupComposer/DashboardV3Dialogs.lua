local GC = GroupComposer

StaticPopupDialogs = StaticPopupDialogs or {}
StaticPopupDialogs["GROUPCOMPOSER_SAVE_PROFILE"] = {
    text = "Save Group Composer template as:",
    button1 = "Save",
    button2 = "Cancel",
    hasEditBox = true,
    maxLetters = 40,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self)
        if self.editBox then
            self.editBox:SetText("")
            self.editBox:SetFocus()
        end
    end,
    OnAccept = function(self)
        local name = self.editBox and self.editBox:GetText() or ""
        local ok = GC:SaveProfile(name)
        if not ok and self.editBox then self.editBox:SetFocus() end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local name = self:GetText() or ""
        if GC:SaveProfile(name) then parent:Hide() end
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
}

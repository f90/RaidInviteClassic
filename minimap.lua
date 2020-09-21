function RIC:OnEnableMinimap()
	local iconDataBroker = LibStub("LibDataBroker-1.1"):NewDataObject("RICMinimapIcon", {
		type = "data source",
		text = "Raid Invite Classic",
		label = "Raid Invite Classic",
		icon = "Interface\\AddOns\\RaidInviteClassic\\img\\minimap",
		OnClick = function()
			if RIC_MainFrame:IsVisible() then
				RIC_MainFrame:Hide()
			else
				RIC_MainFrame:Show()
			end
		end,
	    OnTooltipShow = function(tooltip)
			tooltip:SetText("|cFFFF7D0A Raid Invite Classic")
			tooltip:Show()
		end,
	})
	self.minimapIcon = LibStub("LibDBIcon-1.0")
	self.minimapIcon:Register("Raid Invite Classic", iconDataBroker, RIC.db.profile)
	self.minimapIcon:Show("Raid Invite Classic")
	RIC_MinimapButton_Update()
end

function RIC_MinimapButton_Update()
	if RIC.db.profile.hide then
		RIC.minimapIcon:Hide("Raid Invite Classic")
	else
		RIC.minimapIcon:Show("Raid Invite Classic")
	end
end
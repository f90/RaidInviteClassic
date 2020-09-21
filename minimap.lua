function RIC:OnEnableMinimap()
	local iconDataBroker = LibStub("LibDataBroker-1.1"):NewDataObject("RICMinimapIcon", {
		type = "data source",
		text = "Raid Invite Classic",
		label = "Raid Invite Classic",
		icon = "Interface\\AddOns\\RaidInviteClassic\\img\\minimap",
		OnClick = function(self, button, down) RIC_MinimapButton_Clicked(self, button) end,
	    OnTooltipShow = function(tooltip)
			tooltip:SetText("|cFFFF7D0ARaid Invite Classic|r\n" ..
					"|cFFFFFFFFRoster:|r " .. RIC.db.realm.CurrentRoster .. "\n" ..
					"\n" ..
					"|cFFAAAAFFLeft click|r Toggle main window\n" ..
					"|cFFAAAAFFRight click|r Switch roster\n" ..
					"|cFFAAAAFFShift-Left click|r Start/stop invite phase\n" ..
					"|cFFAAAAFFShift-Right click|r Open settings\n" ..
					"|cFFAAAAFFCtrl-Left click|r Arrange raid groups\n"
			)
			tooltip:Show()
		end,
	})
	self.minimapIcon = LibStub("LibDBIcon-1.0")
	self.minimapIcon:Register("Raid Invite Classic", iconDataBroker, RIC.db.profile)
	self.minimapIcon:Show("Raid Invite Classic")
	RIC_MinimapButton_Update()

	RIC.minimapIconPopup = CreateContextPopup(function() print("UPDATE") end)
end

function RIC_MinimapButton_Update()
	if RIC.db.profile.hide then
		RIC.minimapIcon:Hide("Raid Invite Classic")
	else
		RIC.minimapIcon:Show("Raid Invite Classic")
	end
end

function RIC_MinimapButton_Clicked(self,button)
	if button == "LeftButton" then
		if not IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown() then
			-- Left click: Toggle window
			if RIC_MainFrame:IsVisible() then
				RIC_MainFrame:Hide()
			else
				RIC_MainFrame:Show()
			end
		elseif IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown() then
			-- Shift Left click: Start/stop invite phase
			RIC_Roster_Browser.toggleInvitePhase()
		elseif not IsShiftKeyDown() and IsControlKeyDown() and not IsAltKeyDown() then
			-- Ctrl-Left click: Arrange raid groups
			RIC_Group_Manager.rearrangeRaid("MinimapButton")
		end
	elseif button == "RightButton" then
		if not IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown() then
			-- Right click: Quick-switch rosters
			RIC_PopupMinimap(self)
		elseif IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown() then
			InterfaceOptionsFrame_OpenToCategory(RIC.optionsFrame)
			InterfaceOptionsFrame_OpenToCategory(RIC.optionsFrame)
		end
	end
end

function RIC_PopupMinimap(frame)
	if not RIC.minimapIconPopup:Wipe(frame:GetName()) then
		return
	end
	RIC.minimapIconPopup:AddItem("Select roster:",true)
	RIC.minimapIconPopup:AddItem("",true)

	for rosterName, _ in pairsByKeys(RIC.db.realm.RosterList) do
		RIC.minimapIconPopup:AddItem(rosterName,(rosterName == RIC.db.realm.CurrentRoster), RIC_QuickSwitchRoster, rosterName)
	end

	RIC.minimapIconPopup:AddItem("",true)
	RIC.minimapIconPopup:AddItem("Cancel",false)
	RIC.minimapIconPopup:Show(frame,0,0)
end

function RIC_QuickSwitchRoster(rosterName)
	RIC_Roster_Manager.setRoster(rosterName)
end
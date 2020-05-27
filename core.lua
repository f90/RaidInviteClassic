-- Author      : Daniel Stoller

SLASH_RIC1 = "/ric"
SLASH_RIC2 = "/raidinviteclassic"
SlashCmdList["RIC"] = function(msg)
	local cmd, arg = string.split(" ", msg, 2)
	cmd = cmd:lower()
	if cmd == "" then -- Toggle visibility
		if RIC_MainFrame:IsShown() then
			RIC_MainFrame:Hide()
		else
			RIC_MainFrame:Show()
		end
	elseif cmd == "show" then
		RIC_MainFrame:Show()
	elseif cmd == "hide" then
		RIC_MainFrame:Hide()
	elseif cmd == "reset" then
		RIC_MainFrame:SetPoint("CENTER", "UIParent", "CENTER", 0, 0)
		RIC_MainFrame:SetScale(1)
		RIC_MainFrameScale = 1
		RIC_ScaleInputThing:SetNumber(1)
		RIC_MainFrame:Hide()
		RIC_MainFrame:Show()
	else
		print("|cFFFF0000Raid Invite Classic|r:")
		print("prefix: /ric")
		print(" - show - shows the main frame")
		print(" - hide - hide the main frame")
		print(" - reset - resets the scale / position of the main frame")
	end
end

function RIC_EventHandler(self, event, ...)
	if event == "ADDON_LOADED" then
		local addonName, other = ...
		if addonName == "RaidInviteClassic" then
			-- Set checkboxes according to config
			for ci=1, 10 do
				 _G["RIC_ShowRank"..ci]:SetChecked(RIC_displayRanks[ci])
			end
			_G["RIC_ShowOfflineBox"]:SetChecked(RIC_ShowOffline)
			_G["RIC_CodeWordEditBox"]:SetText(RIC_CodeWordString)
			_G["RIC_OnlyGuildMembersBox"]:SetChecked(RIC_GuildWhispersOnly)
			_G["RIC_CodewordOnlyDuringInviteBox"]:SetChecked(RIC_CodewordOnlyDuringInvite)
			_G["RIC_CodewordOnlyInGroupBox"]:SetChecked(RIC_CodewordOnlyInGroup)
			_G["RIC_CodeWordNotifyStartBox"]:SetChecked(RIC_CodeWordNotifyStart)
			_G["RIC_CodeWordNotifyEndBox"]:SetChecked(RIC_CodeWordNotifyEnd)
			_G["RIC_OnlyRosterMembersBox"]:SetChecked(RIC_RosterWhispersOnly)

			_G["RIC_NotifyInvitePhaseStartBox"]:SetChecked(RIC_NotifyInvitePhaseStart)
			_G["RIC_NotifyInvitePhaseEndBox"]:SetChecked(RIC_NotifyInvitePhaseEnd)
			_G["RIC_AutoSetMasterLooterBox"]:SetChecked(RIC_MasterLooter)
			_G["RIC_ScaleInputThing"]:SetNumber(RIC_MainFrameScale)

			_G["RIC_DurabilityThresholdInput"]:SetNumber(RIC_Durability_Threshold)
			_G["RIC_DurabilityCheckBox"]:SetChecked(RIC_Durability_Warning)

			-- Set roster visibility checkboxes to show all by default
			_G["RIC_ReadyBox"]:SetChecked(true)
			_G["RIC_ExtraBox"]:SetChecked(true)
			_G["RIC_NotInvitedBox"]:SetChecked(true)
			_G["RIC_InvitePendingBox"]:SetChecked(true)
			_G["RIC_InviteFailedBox"]:SetChecked(true)
			_G["RIC_MissingBox"]:SetChecked(true)
			_G["RIC_OtherBox"]:SetChecked(true)

			RIC_MainFrame:SetScale(RIC_MainFrameScale)
			RIC_Codewords_Handler.updateCodeWords()

			-- Minimap
			RIC_ShowMinimapIconConfig:SetChecked(RIC_MinimapShow)
			if RIC_MinimapShow then
				RIC_Mod_MinimapButton_Reposition()
			else
				RIC_Mod_MinimapButton:Hide()
			end

			-- Update table views
			RIC_Guild_Browser.buildGuildList()
			RIC_Roster_Browser.buildRosterRaidList()
		end
	elseif event == "GUILD_ROSTER_UPDATE" then
		-- Update list views
		RIC_Guild_Browser.buildGuildList()
		RIC_Roster_Browser.buildRosterRaidList()
	elseif event == "CHAT_MSG_WHISPER" then
		local msg, author, theRest = ...
		if author ~= nil then -- For some reason this can be nil sometimes?
			RIC_Roster_Browser.inviteWhisper(removeServerFromName(author), msg) -- Remove server tag from name
		else
			print("WARNING: Author name of some message could not be parsed - you might have missed an invite whisper!")
		end
	elseif event == "CHAT_MSG_SYSTEM" then
		local msg = ...
		RIC_Roster_Browser.processSystemMessage(msg)
		RIC_Guild_Browser.updateListing()
	elseif event == "PARTY_LEADER_CHANGED" then
		-- Check if we have lead now. If not, we either gave it away or were not lead before either, so definitely stop any current invite phase
		if (IsInGroup() or IsInRaid()) and (not UnitIsGroupLeader("player")) then
			RIC_Roster_Browser.endInvitePhase()
		end
	end
end

function RICMainFrame_OnLoad()
	-- Add event listeners
	RIC_MainFrame:SetScript("OnEvent", RIC_EventHandler)
	RIC_MainFrame:RegisterEvent("ADDON_LOADED")
	RIC_MainFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
	RIC_MainFrame:RegisterEvent("CHAT_MSG_SYSTEM") -- To understand invite results
	RIC_MainFrame:RegisterEvent("CHAT_MSG_WHISPER") -- To get codeword invites
	RIC_MainFrame:RegisterEvent("PARTY_LEADER_CHANGED") -- To stop invite phase if we give away group/raid lead

	-- Regularly call internal update function
	C_Timer.NewTicker(RIC_UpdateInterval, RIC_OnUpdate)

	-- Create roster list
	local entry = CreateFrame("Button", "$parentEntry1", RIC_RosterFrame, "RIC_RosterEntry") -- Creates the first entry
	entry:SetID(1) -- Sets its id
	entry:SetPoint("TOPLEFT", 4, -28) --Sets its anchor
	entry:Show()
	for ci = 2, 20 do --Loops through to create more rows
		local entry = CreateFrame("Button", "$parentEntry"..ci, RIC_RosterFrame, "RIC_RosterEntry")
		entry:SetID(ci)
		entry:SetPoint("TOP", "$parentEntry"..(ci-1), "BOTTOM") -- sets the anchor to the row above
		entry:Show()
	end

	-- Create guild member list
	local entry = CreateFrame("Button", "$parentEntry1", RIC_GuildMemberFrame, "RIC_GuildEntry") -- Creates the first entry
	entry:SetID(1) -- Sets its id
	entry:SetPoint("TOPLEFT", 4, -28) --Sets its anchor
	entry:Show()
	for ci = 2, 20 do --Loops through to create more rows
		local entry = CreateFrame("Button", "$parentEntry"..ci, RIC_GuildMemberFrame, "RIC_GuildEntry")
		entry:SetID(ci)
		entry:SetPoint("TOP", "$parentEntry"..(ci-1), "BOTTOM") -- sets the anchor to the row above
		entry:Show()
	end

	-- Set text fields
	_G["RIC_CodewordOnlyInGroupBoxText"]:SetText("Only accept when in group")
	_G["RIC_CodewordOnlyDuringInviteBoxText"]:SetText("Only accept during invite phase")
	_G["RIC_CodeWordNotifyStartBoxText"]:SetText("Send guild message at start")
	_G["RIC_CodeWordNotifyEndBoxText"]:SetText("Send guild message at end")
	_G["RIC_OnlyGuildMembersBoxText"]:SetText("Only accept whispers from guild")
	_G["RIC_OnlyRosterMembersBoxText"]:SetText("Only accept whispers from roster")
	_G["RIC_ShowOfflineBoxText"]:SetText("Show Offline")

	-- Create player entry popup
	StaticPopupDialogs["ROSTER_PLAYER_ENTRY"] = {
		text = "Name of the character you want to add to the roster:",
		button1 = "OK",
		button2 = "Cancel",
		timeout = 0,
		hasEditBox = true,
		whileDead = true,
		hideOnEscape = true, -- this doesnt work for some reason?
		enterClicksFirstButton = true, -- this doesnt work for some reason?
		--preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
		OnShow = function (self, data)
    		self.editBox:SetScript("OnEscapePressed", function(self)
				StaticPopup_Hide("ROSTER_PLAYER_ENTRY")
			end)
			self.editBox:SetScript("OnEnterPressed", function(self)
				local text = self:GetText()
				StaticPopup_Hide("ROSTER_PLAYER_ENTRY")
				RIC_Roster_Browser.addNameToRoster(text)
			end)
		end,
		OnAccept = function(self, data, data2)
			local text = self.editBox:GetText()
			RIC_Roster_Browser.addNameToRoster(text)
		end,
	}
end

function RICMainFrame_OnShow()
	RIC_Guild_Browser.setVisibleRanks()
	RIC_Guild_Browser.buildGuildList()
end

function RIC_selectTab(mahID)
 -- Handle tab changes
end

-- Main update function being called every few seconds - update roster and guild lists and the invite status
function RIC_OnUpdate()
	-- Trigger durability checks for all raid members and send warnings if they have joined the raid
	RIC_Durability_Manager.checkDurabilities()

	-- Handle roster invites
	RIC_Roster_Browser.sendInvites()

	-- Update guild and roster views
	RIC_Roster_Browser.buildRosterRaidList()
	RIC_Guild_Browser.buildGuildList()
end

function RIC_Mod_MinimapButton_Reposition()
	RIC_Mod_MinimapButton:SetPoint("TOPLEFT","Minimap","TOPLEFT",52-(80*cos(RIC_MinimapPos)),(80*sin(RIC_MinimapPos))-52)
end

-- Only while the button is dragged this is called every frame
function RIC_Mod_MinimapButton_DraggingFrame_OnUpdate()

	local xpos,ypos = GetCursorPosition()
	local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom()

	xpos = xmin-xpos/UIParent:GetScale()+70 -- get coordinates as differences from the center of the minimap
	ypos = ypos/UIParent:GetScale()-ymin-70

	RIC_MinimapPos = math.deg(math.atan2(ypos,xpos)) -- save the degrees we are relative to the minimap center
	RIC_Mod_MinimapButton_Reposition() -- move the button
end

-- Put your code that you want on a minimap button click here.  arg1="LeftButton", "RightButton", etc
function RIC_Mod_MinimapButton_OnClick(button)
	if button == "LeftButton" then -- Toggle main frame visibility
		if RIC_MainFrame:IsShown() then
			RIC_MainFrame:Hide()
		else
			RIC_MainFrame:Show()
		end
	end
end

function RIC_Mod_MinimapButton_OnEnter(self)
	if (self.dragging) then
		return
	end
	GameTooltip:SetOwner(self or UIParent, "ANCHOR_LEFT")
	GameTooltip:SetText("Raid Invite Classic")
end

function RIC_setScale()
	if RIC_ScaleInputThing:GetNumber() == 0 then
		RIC_ScaleInputThing:SetNumber(1)
		RIC_MainFrameScale = 1
	elseif RIC_ScaleInputThing:GetNumber() < .4 then
		RIC_ScaleInputThing:SetNumber(.4)
		RIC_MainFrameScale = .4
	elseif RIC_ScaleInputThing:GetNumber() > 2 then
		RIC_MainFrameScale = 2
		RIC_ScaleInputThing:SetNumber(2)
	else
		RIC_MainFrameScale = RIC_ScaleInputThing:GetNumber()
	end

	RIC_MainFrame:SetScale(RIC_MainFrameScale)
	RIC_MainFrame:Hide()
	RIC_MainFrame:Show()
end

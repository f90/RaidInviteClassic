-- Author      : Daniel Stoller

RIC = LibStub("AceAddon-3.0"):NewAddon("Raid Invite Classic", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceHook-3.0", "AceSerializer-3.0")
L = LibStub("AceLocale-3.0"):GetLocale("Raid Invite Classic")
local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local DEFAULT_FONT = LSM.MediaTable.font[LSM:GetDefault('font')]

function RIC:OnInitialize()
    -- Called when the addon is loaded
	local options, defaults = getOptions()
	self.db = LibStub("AceDB-3.0"):New("RICDB", defaults, true) -- Create database with default config entries
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db) -- Add profile managment section to options table
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Raid Invite Classic", options) -- Create config menu
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Raid Invite Classic") -- Add config menu to Blizzard options

	-- Add console command listener
	self:RegisterChatCommand("ric", "processConsoleCommand")
	self:RegisterChatCommand("raidinviteclassic", "processConsoleCommand")
end

function RIC:processConsoleCommand(cmd)
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
		RIC.db.profile.MainFrameScale = 1
		RIC_setScale()
		-- Reset minimap position
		RIC.db.profile.MinimapPos = 0
		RIC_MinimapButton_Update()
	elseif cmd == "version" then
		RIC:Print("Version: " .. RIC_Version)
	elseif cmd == "config" then
		InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
		InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
	else
		RIC:Print("") -- Print just our addon name first
		print("prefix: /ric - shows/hides main frame")
		print(" - show - shows the main frame")
		print(" - hide - hide the main frame")
		print(" - config - opens the configuration menu")
		print(" - reset - resets interface elements and minimap icon")
		print(" - version - shows the addon version")
	end
end

function RIC:OnEnable() -- Called when the addon is enabled
	-- Add event listeners
	self:RegisterEvent("GUILD_ROSTER_UPDATE")
	self:RegisterEvent("CHAT_MSG_SYSTEM") -- To understand invite results
	self:RegisterEvent("CHAT_MSG_WHISPER") -- To get codeword invites
	self:RegisterEvent("PARTY_LEADER_CHANGED") -- To stop invite phase if we give away group/raid lead
	self:RegisterEvent("PLAYER_LOGOUT") -- To properly end invite phase (with announcement) when player logs out/exits/reloads UI since invite phase is reset

	self:RegisterEvent("GROUP_ROSTER_UPDATE", function() RIC_Group_Manager.OnRosterUpdate() end)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", function() RIC_Group_Manager.CheckArrangable(true) end)
	self:RegisterEvent("PLAYER_REGEN_ENABLED", function() RIC_Group_Manager.CheckArrangable(false) end)
	self:RegisterComm("ricroster")

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
	_G["RIC_CodewordNotifyStartBoxText"]:SetText("Send guild message at start")
	_G["RIC_CodewordNotifyEndBoxText"]:SetText("Send guild message at end")
	_G["RIC_OnlyGuildMembersBoxText"]:SetText("Only accept whispers from guild")
	_G["RIC_OnlyRosterMembersBoxText"]:SetText("Only accept whispers from roster")
	_G["RIC_CodewordHideBoxText"]:SetText("Hide whispers equalling a codeword")
	_G["RIC_ShowOfflineBoxText"]:SetText("Show Offline")

	-- Create player entry popup
	StaticPopupDialogs["ROSTER_PLAYER_ENTRY"] = {
		text = "Name of the character you want to add to the roster:",
		button1 = "OK",
		button2 = "Cancel",
		timeout = 0,
		hasEditBox = true,
		whileDead = true,
		hideOnEscape = true,
		enterClicksFirstButton = true,
		preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
		OnShow = function (self, data)
			-- Set edit box scripts to hide popup on escape/enter, and to process name on enter
    		self.editBox:SetScript("OnEscapePressed", function(self)
				if self.autoCompleteEscaped ~= true then -- Hide on escape, if we did not escape to cancel the autocomplete window
					StaticPopup_Hide("ROSTER_PLAYER_ENTRY")
				end
			end)
			self.editBox:SetScript("OnEnterPressed", function(self)
				if self.autoCompleted ~= true then -- Add player on enter, if enter was not meant for confirming autocomplete suggestion
					local text = self:GetText()
					StaticPopup_Hide("ROSTER_PLAYER_ENTRY")
					RIC_Roster_Browser.addNameToRoster(text)
				end
			end)

			-- Setup autocomplete suggestions for the player entry edit box
			local guildMembers = RIC_Guild_Manager.getGuildMembers()
			local nameLookup = {}
			for name,v in pairs(guildMembers) do -- Add guild members
				nameLookup[name] = true
			end
			for name,v in pairs(RIC_ReceivedWhisperAuthors) do -- Add people who whispered us during this session
				nameLookup[name] = true
			end
			 -- Go through all names and filter them, and put them into the final list
			local names = {}
			for name,v in pairs(nameLookup) do
				if RIC.db.realm.RosterList[name] == nil then -- Only add as suggestion if not on roster list yet
					table.insert(names, name)
				end
			end
			SetupAutoComplete(self.editBox, names, 10);
		end,
		OnAccept = function(self, data, data2)
			local text = self.editBox:GetText()
			RIC_Roster_Browser.addNameToRoster(text)
		end,
	}

	-- Set up chat filters
	RIC_Chat_Manager.setupFilter()

	-- Set checkboxes according to config
	for i, val in ipairs(RIC.db.profile.DisplayRanks) do
		 _G["RIC_ShowRank"..i]:SetChecked(val)
	end
	_G["RIC_ShowOfflineBox"]:SetChecked(RIC.db.profile.ShowOffline)
	_G["RIC_CodeWordEditBox"]:SetText(RIC.db.profile.CodewordString)
	_G["RIC_OnlyGuildMembersBox"]:SetChecked(RIC.db.profile.GuildWhispersOnly)
	_G["RIC_CodewordOnlyDuringInviteBox"]:SetChecked(RIC.db.profile.CodewordOnlyDuringInvite)
	_G["RIC_CodewordOnlyInGroupBox"]:SetChecked(RIC.db.profile.CodewordOnlyInGroup)
	_G["RIC_CodewordNotifyStartBox"]:SetChecked(RIC.db.profile.CodewordNotifyStart)
	_G["RIC_CodewordNotifyEndBox"]:SetChecked(RIC.db.profile.CodewordNotifyEnd)
	_G["RIC_OnlyRosterMembersBox"]:SetChecked(RIC.db.profile.RosterWhispersOnly)
	_G["RIC_CodewordHideBox"]:SetChecked(RIC.db.profile.CodewordHide)

	-- Set roster visibility checkboxes to show all by default
	_G["RIC_ReadyBox"]:SetChecked(true)
	_G["RIC_ExtraBox"]:SetChecked(true)
	_G["RIC_NotInvitedBox"]:SetChecked(true)
	_G["RIC_InvitePendingBox"]:SetChecked(true)
	_G["RIC_InviteFailedBox"]:SetChecked(true)
	_G["RIC_MissingBox"]:SetChecked(true)
	_G["RIC_OtherBox"]:SetChecked(true)

	RIC_MainFrame:SetScale(RIC.db.profile.MainFrameScale)
	RIC_Codewords_Handler.updateCodeWords()

	RIC_MinimapButton_Update()

	-- Update table views
	RIC_Guild_Browser.buildGuildList()
	RIC_Roster_Browser.buildRosterRaidList()

	-- CREATE GROUP ASSIGNMENT FUNCTIONALITY!

	self.groups = AceGUI:Create("Window")
	self.groups:Hide()
	self.groups:EnableResize(false)
	self.groups:SetTitle("Group assignments")
	self.groups:SetLayout("Flow")
	_G["GroupFrame"] = self.groups.frame
	table.insert(UISpecialFrames, "GroupFrame")
	self:HookScript(self.groups.frame, "OnShow", function() RIC_Group_Manager.draw() end)

	self.playerBank = AceGUI:Create("InlineGroup")
	self.playerBank:SetWidth(200)
	self.playerBank:SetTitle("Unassigned roster players")
	self.playerBank:SetLayout("Fill")
	self.playerBank.scroll = AceGUI:Create("ScrollFrame")
	self.playerBank.scroll:SetLayout("Flow")
	self.playerBank.scroll.playerLabels = {}
	self.playerBank:AddChild(self.playerBank.scroll)

	-- Raid overview, group-wise
	self.raidView = AceGUI:Create("InlineGroup")
	self.raidView:SetWidth(200)
	self.raidView:SetTitle("Raid overview")
	self.raidView:SetLayout("Fill")

	-- Init player labels
	self.raidPlayerLabels = {}
	local raidGroups = {}
	for row = 1, 8 do
		local raidGroup = AceGUI:Create("InlineGroup")
		raidGroup:SetWidth(160)
		raidGroup:SetTitle("Group " .. row)
		raidGroup.titletext:SetJustifyH("CENTER")
		self.raidPlayerLabels[row] = {}
		for col = 1, 5 do
			self.raidPlayerLabels[row][col] = AceGUI:Create("InteractiveLabel")
			local label = self.raidPlayerLabels[row][col]
			label:SetFont(DEFAULT_FONT, 12)
			label:SetJustifyH("CENTER")
			label.row = row
			label.col = col
			label:SetWidth(161)
			label:SetHeight(20)
			label:SetText("Empty")
			label.label:SetTextColor(0.35, 0.35, 0.35)
			RIC_Group_Manager.assignLabelFunctionality(label)
			raidGroup:AddChild(label)
		end
		AceGUI:RegisterLayout("RaidGroupLayout" .. row, function()
			for col = 1, 5 do
				local label = self.raidPlayerLabels[row][col]
				label:ClearAllPoints()
				label:SetPoint("TOPLEFT", raidGroup.frame, "TOPLEFT", 0, -1 * ((col - 1) * label.frame:GetHeight() + raidGroup.titletext:GetHeight() + 5 * (col - 1) + 4))
			end
			raidGroup:SetHeight(self.raidPlayerLabels[row][1].frame:GetHeight() * 5 + raidGroup.titletext:GetHeight() + 34)
		end)
		raidGroup:SetLayout("RaidGroupLayout" .. row)
		raidGroup:DoLayout()

		self.playerBank:AddChild(raidGroup)
		table.insert(raidGroups, raidGroup)
	end

	self.unassignAll = AceGUI:Create("Button")
	self.unassignAll:SetText("Unassign all players")
	self.unassignAll.textColor = {}
	self.unassignAll.textColor.r = r
	self.unassignAll.textColor.g = g
	self.unassignAll.textColor.b = b
	self.unassignAll:SetCallback("OnClick", function() RIC_Group_Manager.unassignAll() end)

	self.rearrangeRaid = AceGUI:Create("Button")
	self.rearrangeRaid:SetText("REARRANGE RAID")
	self.rearrangeRaid.textColor = {}
	self.rearrangeRaid.textColor.r = r
	self.rearrangeRaid.textColor.g = g
	self.rearrangeRaid.textColor.b = b
	self.rearrangeRaid:SetCallback("OnClick", function() RIC_Group_Manager.RearrangeRaid() end)

	AceGUI:RegisterLayout("MainLayout", function()
		self.playerBank:SetPoint("TOPLEFT", self.groups.frame, "TOPLEFT", 10, -28)
		self.playerBank:SetHeight(raidGroups[1].frame:GetHeight() * 4)

		self.groups:SetWidth(544)
		self.groups:SetHeight(520)
		raidGroups[1]:SetPoint("TOPLEFT", self.playerBank.frame, "TOPRIGHT", 2, 0)
		raidGroups[2]:SetPoint("TOPLEFT", raidGroups[1].frame, "TOPRIGHT", 2, 0)
		raidGroups[3]:SetPoint("TOPLEFT", raidGroups[1].frame, "BOTTOMLEFT", 0, 0)
		raidGroups[4]:SetPoint("TOPLEFT", raidGroups[3].frame, "TOPRIGHT", 2, 0)
		raidGroups[5]:SetPoint("TOPLEFT", raidGroups[3].frame, "BOTTOMLEFT", 0, 0)
		raidGroups[6]:SetPoint("TOPLEFT", raidGroups[5].frame, "TOPRIGHT", 2, 0)
		raidGroups[7]:SetPoint("TOPLEFT", raidGroups[5].frame, "BOTTOMLEFT", 0, 0)
		raidGroups[8]:SetPoint("TOPLEFT", raidGroups[7].frame, "TOPRIGHT", 2, 0)

		self.unassignAll:SetPoint("TOPLEFT", self.playerBank.frame, "BOTTOMLEFT", 0, -7)
		self.unassignAll:SetWidth(self.playerBank.frame:GetWidth())

		self.rearrangeRaid:SetPoint("TOPLEFT", raidGroups[7].frame, "BOTTOMLEFT", 0, -7)
		self.rearrangeRaid:SetWidth(raidGroups[7].frame:GetWidth() * 2 + 2)
	end)

	self.groups:AddChild(self.playerBank)
	self.groups:AddChild(self.rearrangeRaid)
	self.groups:AddChild(self.unassignAll)

	self.groups:SetLayout("MainLayout")
	self.groups:DoLayout()

	RIC_Group_Manager.OnRosterUpdate()
end

function RIC:OnDisable()
    -- Called when the addon is disabled
end

function RIC:GUILD_ROSTER_UPDATE()
	-- Update list views
	RIC_Guild_Browser.buildGuildList()
	RIC_Roster_Browser.buildRosterRaidList()
end

function RIC:CHAT_MSG_WHISPER(event, msg, author, ...)
	if author ~= nil then -- For some reason this can be nil sometimes?
		RIC_Roster_Browser.inviteWhisper(removeServerFromName(author), msg) -- Remove server tag from name
	else
		RIC:Print(L["Whisper_Author_Unknown"])
	end
end

function RIC:CHAT_MSG_SYSTEM(event, msg)
	RIC_Roster_Browser.processSystemMessage(msg)
	RIC_Guild_Browser.updateListing()
end

function RIC:PARTY_LEADER_CHANGED()
	if (IsInGroup() or IsInRaid()) then
		if not UnitIsGroupLeader("player") then -- Check if we have lead now. If not, we either gave it away or were not lead before either, so definitely stop any current invite phase
			RIC_Roster_Browser.endInvitePhase()
		end
	else
		-- We are not in a group/raid at all - definitely stop invite phase in that case!
		RIC_Roster_Browser.endInvitePhase()
	end
end

function RIC:PLAYER_LOGOUT()
	-- We are exiting/logging out/reloading UI.
	-- In all of these cases, the invite phase cannot continue since player is offline and/or our internal addon variables are reset
	-- Therefore, end invite phase now, so people are properly notified that invite phase is stopped
	-- TODO SendChatMessage does not seem to work here anymore (no guild message can be seen), on logout or exit. Reloadui works?
	RIC_Roster_Browser.endInvitePhase()
end

function RICMainFrame_OnShow()
	RIC_Guild_Browser.setVisibleRanks()
	RIC_Guild_Browser.buildGuildList()
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

	-- Update player tooltip every few seconds while hovering over player entry in roster
	RIC_Roster_Browser.setPlayerTooltip()
end

function RIC_setScale()
	RIC_MainFrame:SetScale(RIC.db.profile.MainFrameScale)
	RIC_MainFrame:Hide()
	RIC_MainFrame:Show()
end
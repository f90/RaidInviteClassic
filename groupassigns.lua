local addonName, RIC = ...
local AceGUI = LibStub("AceGUI-3.0")
local LD = LibStub("LibDeflate")
local LSM = LibStub("LibSharedMedia-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local DEFAULT_FONT = LSM.MediaTable.font[LSM:GetDefault('font')]

local actorButton = nil
local inProgress = false
local inCombat = false
local isDraggingLabel = false
local shouldUpdatePlayerBank = false

function RIC:OnEnableGroupview()
	-- Add event listeners
	self:RegisterEvent("GROUP_ROSTER_UPDATE", function() RIC._Group_Manager.updateArrangeBox() end)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", function() RIC._Group_Manager.onEnterCombat() end)
	self:RegisterEvent("PLAYER_REGEN_ENABLED", function() RIC._Group_Manager.onExitCombat() end)

	-- CREATE GROUP ASSIGNMENT FUNCTIONALITY!
	self.groups = AceGUI:Create("Window")
	self.groups:Hide()
	self.groups:EnableResize(false)
	self.groups:SetTitle("Group assignments")
	self.groups:SetLayout("Flow")
	local groupFrameName = addonName.."GroupFrame"
	_G[groupFrameName] = self.groups.frame
	table.insert(UISpecialFrames, groupFrameName)
	self:HookScript(self.groups.frame, "OnShow", function() RIC._Group_Manager.draw() end)
	self:HookScript(self.groups.frame, "OnHide", function() _G["RIC_OpenGroupWindow"]:SetText("View groups") end)

	self.playerBank = AceGUI:Create("InlineGroup")
	self.playerBank:SetWidth(200)
	self.playerBank:SetTitle("Unassigned roster players")
	self.playerBank:SetLayout("Fill")
	self.playerBank.scroll = AceGUI:Create("ScrollFrame")
	self.playerBank.scroll:SetLayout("Flow")
	self.playerBank.scroll.playerLabels = {}
	self.playerBank.scroll.playerStatusLabels = {}
	self.playerBank:AddChild(self.playerBank.scroll)

	-- Raid overview, group-wise
	self.raidView = AceGUI:Create("InlineGroup")
	self.raidView:SetWidth(200)
	self.raidView:SetTitle("Raid overview")
	self.raidView:SetLayout("Fill")

	-- Init player labels
	self.raidPlayerLabels = {}
	self.raidPlayerStatusLabels = {}
	local raidGroups = {}
	for row = 1, 8 do
		local raidGroup = AceGUI:Create("InlineGroup")
		raidGroup:SetWidth(160)
		raidGroup:SetTitle("Group " .. row)
		raidGroup.titletext:SetJustifyH("CENTER")
		self.raidPlayerLabels[row] = {}
		self.raidPlayerStatusLabels[row] = {}
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
			RIC._Group_Manager.assignGroupLabelFunctionality(label)
			raidGroup:AddChild(label)

			local statusLabel = AceGUI:Create("Label")
			statusLabel:SetWidth(20)
			statusLabel:SetHeight(20)
			statusLabel:SetImage("Interface\\AddOns\\RaidInviteClassic\\img\\empty")
			statusLabel:SetImageSize(18,18)
			statusLabel:SetJustifyH("CENTER")
			statusLabel:SetJustifyV("CENTER")
			raidGroup:AddChild(statusLabel)
			self.raidPlayerStatusLabels[row][col] = statusLabel
		end
		AceGUI:RegisterLayout("RaidGroupLayout" .. row, function()
			for col = 1, 5 do
				local label = self.raidPlayerLabels[row][col]
				label:ClearAllPoints()
				local dist = -1 * ((col - 1) * label.frame:GetHeight() + raidGroup.titletext:GetHeight() + 5 * (col - 1) + 4)
				label:SetPoint("TOPLEFT", raidGroup.frame, "TOPLEFT", 0, dist)
				self.raidPlayerStatusLabels[row][col]:ClearAllPoints()
				self.raidPlayerStatusLabels[row][col]:SetPoint("TOPLEFT", raidGroup.frame, "TOPLEFT", 140, dist+1)
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
	self.unassignAll:SetCallback("OnClick", function() RIC._Group_Manager.unassignAll() end)

	self.rearrangeRaid = AceGUI:Create("Button")
	self.rearrangeRaid:SetText(RIC.db.profile.Lp["Group_Assign_Rearrange"])
	self.rearrangeRaid:SetCallback("OnClick", function() RIC._Group_Manager.rearrangeRaid() end)

	AceGUI:RegisterLayout("GroupLayout", function()
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

	self.groups:SetLayout("GroupLayout")
	self.groups:DoLayout()

	RIC._Group_Manager.updateArrangeBox()
end

function RIC._Group_Manager.toggle()
	if RIC.groups:IsShown() == true then
		RIC.groups:Hide()
		_G["RIC_OpenGroupWindow"]:SetText("View groups")
	else
		RIC.groups:Show()
		RIC._Group_Manager.draw(true)
		_G["RIC_OpenGroupWindow"]:SetText("Hide groups")
	end
end

local groupNames = {}
function RIC._Group_Manager.flattenGroups()
	wipe(groupNames)
	for name, position in pairs(RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster]) do
		if position > 0 then
			local row = math.ceil(position/5)
			if groupNames[row] == nil then
				groupNames[row] = {}
			end
			groupNames[row][position - (row-1)*5] = name
		end
	end
	for row=1,8 do
		if groupNames[row] ~= nil then
			local col = 1
			for _, name in RIC.pairsByKeys(groupNames[row]) do
				RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster][name] = (row-1)*5 + col
				col = col + 1
			end
		end
	end
	RIC._Group_Manager.drawGroupLabels()
	-- No need to check arrangability here since player raid and roster did not change on its own, and is not affected by flattening
end

function RIC._Group_Manager.MovedToPlayerBank(label)
	RIC._Group_Manager.setGroupPosition(label.name, 0)
	RIC._Group_Manager.draw(true)
end

function RIC._Group_Manager.SetLabel(label, statusLabel, name)
	if name then
		-- Set label
		label.name = name
		label:SetText(RIC.displayName(name))
		local playerInfo = RIC._Roster_Browser.getPlayerInfo(name)
		local classColor
		if playerInfo ~= nil then
			statusLabel:SetImage(RIC.getStatusSymbolImagePath(playerInfo.status))
			classColor = RIC.getClassColor(playerInfo.classFileName, "RGB")
		else
			statusLabel:SetImage("Interface\\AddOns\\RaidInviteClassic\\img\\question_mark")
			classColor = RIC.getClassColor("UNKNOWN_CLASS", "RGB")
		end
		label.label:SetTextColor(classColor.r, classColor.g, classColor.b)
		label.frame:EnableMouse(true)
		label.frame:SetMovable(true)
	else
		-- Clear label
		label.name = nil
		label:SetText("Empty")
		label.label:SetTextColor(0.35, 0.35, 0.35)
		label.frame:EnableMouse(false)
		label.frame:SetMovable(false)
		statusLabel:SetImage("Interface\\AddOns\\RaidInviteClassic\\img\\empty")
	end
end

function RIC._Group_Manager.assignGroupLabelFunctionality(label)
	local anchorPoint, parentFrame, relativeTo, ptX, ptY
	label.frame:RegisterForDrag("LeftButton")
	label.frame:SetScript("OnDragStart", function(self)
		anchorPoint, parentFrame, relativeTo, ptX, ptY = self:GetPoint()
		self:SetFrameStrata("TOOLTIP")
		self:StartMoving()
	end)
	label.frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		self:SetFrameStrata("FULLSCREEN_DIALOG")
		if MouseIsOver(RIC.playerBank.frame) then
			RIC._Group_Manager.MovedToPlayerBank(label)
		else
			local putToGroup = function()
				for iRow = 1, 8 do
					if label.row ~= iRow then
						for iCol = 1, 5 do
							if MouseIsOver(RIC.raidPlayerLabels[iRow][iCol].frame) then
								RIC._Group_Manager.setGroupPosition(label.name, (iRow-1)*5 + iCol)
								return
							end
						end
					end
				end
			end
			putToGroup()
		end
		label:ClearAllPoints()
		label:SetPoint(anchorPoint, parentFrame, relativeTo, ptX, ptY)
	end)
	label:SetCallback("OnClick", function(self, _, button)
		if button == "RightButton" then
			RIC._Group_Manager.MovedToPlayerBank(self)
		end
	end)
end

function RIC._Group_Manager.draw(rosterChanged)
	RIC._Group_Manager.showPlayerBank()
	RIC._Group_Manager.flattenGroups()
	if rosterChanged then
		RIC._Group_Manager.updateArrangeBox()
	end
end

-- Set player name to a certain raid position, possibly swapping positions with already existing player on this position
function RIC._Group_Manager.setGroupPosition(name, position)
	-- Position is zero => Simply put player on bank, no replacement
	if position == 0 then
		RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster][name] = 0
	else
		-- Put this character on a certain spot in the raid. Check whether this spot was filled. In that case, swap!
		for currName, currPos in pairs(RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster]) do
			if currPos == position then
				-- Set position of old person to the one that will be freed now
				RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster][currName] = RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster][name]
				break
			end
		end
		RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster][name] = position
	end
	RIC._Group_Manager.draw(true) -- Redraw UI and flatten groups, since roster changed
end

function RIC._Group_Manager.drawGroupLabels()
	local filledPositions = RIC.reverseMap(RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster])
	for row = 1, 8 do
		for col = 1, 5 do
			RIC._Group_Manager.SetLabel(RIC.raidPlayerLabels[row][col], RIC.raidPlayerStatusLabels[row][col], filledPositions[(row-1)*5 + col])
		end
	end
end


function RIC._Group_Manager.showPlayerBank()
	if isDraggingLabel then
		shouldUpdatePlayerBank = true
		return
	end

	local index = 0
	for name, val in RIC.pairsByKeys(RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster]) do
		if val == 0 then
			index = index + 1
			local playerLabel
			local statusLabel
			if RIC.playerBank.scroll.playerLabels[index] then
				playerLabel = RIC.playerBank.scroll.playerLabels[index]
				playerLabel.frame:EnableMouse(true)
				statusLabel = RIC.playerBank.scroll.playerStatusLabels[index]
			else
				playerLabel = AceGUI:Create("InteractiveLabel")
				playerLabel:SetFont(DEFAULT_FONT, 12)
				playerLabel:SetHighlight("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
				playerLabel:SetWidth(140)
				playerLabel:SetHeight(12)

				statusLabel = AceGUI:Create("Label")
				statusLabel:SetWidth(12)
				statusLabel:SetHeight(12)
				statusLabel:SetImage("Interface\\AddOns\\RaidInviteClassic\\img\\checkmark")

				local anchorPoint, parentFrame, relativeTo, ptX, ptY
				playerLabel.frame:EnableMouse(true)
				playerLabel.frame:SetMovable(true)
				playerLabel.frame:RegisterForDrag("LeftButton")
				playerLabel.frame:SetScript("OnDragStart", function(self)
					isDraggingLabel = true
					anchorPoint, parentFrame, relativeTo, ptX, ptY = self:GetPoint()
					self:SetParent(RIC.groups.frame)
					self:SetFrameStrata("TOOLTIP")
					self:StartMoving()
				end)

				playerLabel.frame:SetScript("OnDragStop", function(self)
					self:StopMovingOrSizing()
					local putToGroup = function()
						for row = 1, 8 do
							for col = 1, 5 do
								local label = RIC.raidPlayerLabels[row][col]
								if MouseIsOver(label.frame) then
									-- Found raid position where this label was moved to - setting new position!
									RIC._Group_Manager.setGroupPosition(playerLabel.name, (row-1)*5 + col)
									RIC._Group_Manager.showPlayerBank()
									return true
								end
							end
						end
						return false
					end

					self:SetParent(parentFrame)
					playerLabel:ClearAllPoints()
					playerLabel:SetPoint(anchorPoint, parentFrame, relativeTo, ptX, ptY)
					playerLabel.frame:SetFrameStrata("TOOLTIP")
					isDraggingLabel = false

					if putToGroup() or shouldUpdatePlayerBank then
						shouldUpdatePlayerBank = false
						RIC._Group_Manager.showPlayerBank()
					end
				end)

				playerLabel:SetCallback("OnClick", function(self, _, button)
					if button == "RightButton" then
						RIC._Roster_Browser.remove(self.name)
						-- Update data and view
						RIC._Roster_Browser.buildRosterRaidList()
						-- Redraw group view to reflect change
						RIC._Group_Manager.draw(true)
					end
				end)

				RIC.playerBank.scroll:AddChild(playerLabel)
				RIC.playerBank.scroll:AddChild(statusLabel)
				table.insert(RIC.playerBank.scroll.playerLabels, playerLabel)
				table.insert(RIC.playerBank.scroll.playerStatusLabels, statusLabel)
			end

			-- Set player label
			RIC._Group_Manager.SetLabel(playerLabel, statusLabel, name)
		end
	end

	while index < #RIC.playerBank.scroll.playerLabels do
		index = index + 1
		RIC.playerBank.scroll.playerLabels[index].name = nil
		RIC.playerBank.scroll.playerLabels[index]:SetText(nil)
		RIC.playerBank.scroll.playerLabels[index].frame:EnableMouse(false)

		RIC.playerBank.scroll.playerStatusLabels[index]:SetImage(nil)
	end

	-- RIC.playerBank.scroll:SetScroll(newlyAddedNameIndex / (#playerTableNames - 1) * 1000) -- TODO possibly set scroll pos
	RIC.playerBank.scroll:DoLayout()
end

function RIC._Group_Manager.unassignAll()
	for name, _ in pairs(RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster]) do
		RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster][name] = 0
	end
	RIC._Group_Manager.draw(true)
end

function RIC._Group_Manager.sortGroup(simulate)
	-- Get current raid setup info
	local raidIndexToGroup = {} -- Maps index to group number (if this slot is used)
	local nameToRaidIndex = {} -- Maps name to raid index
	local groupSizes = { 0, 0, 0, 0, 0, 0, 0, 0} -- Count number of players in each group
	for i = 1, 40 do
		local name, _, subgroup = GetRaidRosterInfo(i) -- TODO Maybe switch to getRaidMembers
		if name ~= nil then
			name = RIC.addServerToName(name)
			nameToRaidIndex[name] = i
			raidIndexToGroup[i] = subgroup
			groupSizes[subgroup] = groupSizes[subgroup] + 1
		end
	end

	-- For desired raid setup, get mapping from raid index in sorted group to raid index of that person in current group
	local missingPlayers = ""
	local posToRaidIndex = {}
	for currName, targetPos in pairs(RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster]) do
		if (targetPos > 0) then -- This player appears in the group setup
			local currPos = nameToRaidIndex[currName]
			if currPos then -- If this player is in the raid...
				posToRaidIndex[targetPos] = currPos
			else
				missingPlayers = missingPlayers .. currName .. ", " -- Player is not in the raid!
			end
		end
	end
	if (not simulate) and (string.utf8len(missingPlayers) > 0) then
		RIC:Print("WARNING: Players " .. missingPlayers .. " can not be assigned to their raid group since they are not in the raid!")
	end

	-- Check which raid index position needs to be moved to which group
	local idToTargetGroup = {}
	for group = 1, 8 do
		for j = 1, 5 do
			local index = (group - 1) * 5 + j
			if (posToRaidIndex[index] ~= nil) then
				idToTargetGroup[posToRaidIndex[index]] = group
			end
		end
	end

	-- Iterate through raid positions, put people into these positions one after the other
	for targetGroup = 1, 8 do
		for j = 1, 5 do
			local targetPos = (targetGroup - 1) * 5 + j -- Target position in the arranged raid to set now (1 to 40)
			local currentIndex = posToRaidIndex[targetPos] -- Look up raid index of player that should be at the target position
			if(currentIndex ~= nil) then -- If the person from the group setup is actually in the raid...
				local currentGroup = raidIndexToGroup[currentIndex]
				if (currentGroup == targetGroup) then
					-- Player is already in the correct group - nothing to do!
				elseif(groupSizes[targetGroup] < 5) then
					if simulate then -- If we are checking whether raid is arranged, do nothing and report back
						return false
					end
					-- Target group has free slots - just put player there directly
					SetRaidSubgroup(currentIndex, targetGroup)

					raidIndexToGroup[currentIndex] = targetGroup

					-- Update group sizes
					groupSizes[currentGroup] = groupSizes[currentGroup] - 1
					groupSizes[targetGroup] = groupSizes[targetGroup] + 1
				else
					-- Target group full - someone must be there that is NOT in the group setup,
					-- or in the group setup but in the wrong group, and thus is blocking the spot
					if simulate then -- If we are checking whether raid is arranged, do nothing and report back
						return false
					end

					local swapped = false
					for otherId = 1, 40 do
						if(raidIndexToGroup[otherId] == targetGroup and idToTargetGroup[otherId] ~= targetGroup) then
							-- Swap groups
							swapped = true
							SwapRaidSubgroup(otherId, currentIndex)

							-- Update data structures
							raidIndexToGroup[otherId] = raidIndexToGroup[currentIndex]
							raidIndexToGroup[currentIndex] = targetGroup
							break
						end
					end
					assert(swapped) -- It must be possible to swap the desired player into the group since there has to be at least one player that doesn't belong in that group
				end
			end
		end
	end

	-- End sorting process
	if (not simulate) then
		RIC._Group_Manager.flattenGroups()
	end

	return true
end

function RIC._Group_Manager.onEnterCombat()
	inCombat = true
	RIC._Group_Manager.updateArrangeBox()
end

function RIC._Group_Manager.onExitCombat()
	inCombat = false
	RIC._Group_Manager.updateArrangeBox()
end

-- Checks whether we can currently rearrange the raid, and if not, why. Returns the reason as a status message
function RIC._Group_Manager.getArrangeStatus()
	if not IsInRaid() then
		return "Group_Assign_Not_In_Raid"
	end

	if RIC._Group_Manager.sortGroup(true) then
		-- Our roster is already arranged as desired!
		return "Group_Assign_Is_Arranged"
	end

	if not RIC.IsRaidAssistant() then
		return "Group_Assign_No_Rights"
	end

	if (InCombatLockdown() == true) or inCombat then
		return "Group_Assign_In_Combat"
	end

	if inProgress then
		return "Group_Assign_In_Progress"
	end

	return "Group_Assign_Is_Not_Arranged"
end

-- Check whether raid is arrangable and set arrange box text accordingly.
function RIC._Group_Manager.updateArrangeBox()
	local status = RIC._Group_Manager.getArrangeStatus()
	RIC.rearrangeRaid:SetText(RIC.db.profile.Lp[status])
	if status == "Group_Assign_Is_Not_Arranged" then
		-- Rearranging is possible, otherwise status would give the reason why it's not possible
		RIC.rearrangeRaid:SetDisabled(false)
		RIC.rearrangeRaid.frame:EnableMouse(true)
		RIC.rearrangeRaid.text:SetTextColor(1.0, 1.0, 1.0)
	else
		RIC.rearrangeRaid:SetDisabled(true)
		RIC.rearrangeRaid.frame:EnableMouse(false)
		RIC.rearrangeRaid.text:SetTextColor(0.35, 0.35, 0.35)
	end
end

function RIC._Group_Manager.rearrangeRaid(actor)
	actorButton = actor
	local status = RIC._Group_Manager.getArrangeStatus()
	if status == "Group_Assign_Is_Not_Arranged" then -- Check to see whether we can start
		-- Start rearranging!
		inProgress = true
		RIC._Group_Manager.updateArrangeBox()
		if actor == "MinimapButton" then -- Textual feedback in case we use minimap
			RIC:Print(RIC.db.profile.Lp["Group_Assign_In_Progress"])
		end
		RIC._Group_Manager.sortGroup(false)
		-- Output results after a delay (wait for WoW to switch players and update the group info)
		C_Timer.After(0.5, RIC._Group_Manager.finishRearrangeRaid)
	else
		RIC._Group_Manager.rearrangeRaidResponse()
	end
end

function RIC._Group_Manager.finishRearrangeRaid()
	-- Triggered some extra time after actually swapping players, to stop the rearrangement phase and output results
	inProgress = false
	RIC._Group_Manager.rearrangeRaidResponse()
end

function RIC._Group_Manager.rearrangeRaidResponse()
	-- Output results/status after user made OR requested a rearrangement of groups
	if actorButton == "MinimapButton" then
		-- Give console feedback since we cant see arrange box when using minimap
		RIC:Print(RIC.db.profile.Lp[RIC._Group_Manager.getArrangeStatus()])
	end
	RIC._Group_Manager.updateArrangeBox()
end
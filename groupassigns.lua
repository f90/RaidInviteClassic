local AceGUI = LibStub("AceGUI-3.0")
local LD = LibStub("LibDeflate")
local LSM = LibStub("LibSharedMedia-3.0")
local DEFAULT_FONT = LSM.MediaTable.font[LSM:GetDefault('font')]

local inSwap = false
local remoteInSwap = false
local remoteSender = nil
local moveCounter = 0

local isDraggingLabel = false
local shouldUpdatePlayerBank = false

function RIC:OnEnableGroupview()
	-- Add event listeners
	self:RegisterEvent("GROUP_ROSTER_UPDATE", function() RIC_Group_Manager.OnRosterUpdate() end)
	--self:RegisterEvent("PLAYER_REGEN_DISABLED", function() RIC_Group_Manager.updateArrangeBox(true) end)
	--self:RegisterEvent("PLAYER_REGEN_ENABLED", function() RIC_Group_Manager.updateArrangeBox(false) end)

	-- CREATE GROUP ASSIGNMENT FUNCTIONALITY!
	self.groups = AceGUI:Create("Window")
	self.groups:Hide()
	self.groups:EnableResize(false)
	self.groups:SetTitle("Group assignments")
	self.groups:SetLayout("Flow")
	_G["GroupFrame"] = self.groups.frame
	table.insert(UISpecialFrames, "GroupFrame")
	self:HookScript(self.groups.frame, "OnShow", function() RIC_Group_Manager.draw() end)
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
			RIC_Group_Manager.assignGroupLabelFunctionality(label)
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
	self.rearrangeRaid:SetCallback("OnClick", function() RIC_Group_Manager.rearrangeRaid() end)

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

	RIC_Group_Manager.OnRosterUpdate()
end

function RIC_Group_Manager.toggle()
	if RIC.groups:IsShown() == true then
		RIC.groups:Hide()
		_G["RIC_OpenGroupWindow"]:SetText("View groups")
	else
		RIC.groups:Show()
		RIC_Group_Manager.draw(true)
		_G["RIC_OpenGroupWindow"]:SetText("Hide groups")
	end
end

function RIC_Group_Manager.flattenGroups()
	local groupNames = {}
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
			for _, name in pairsByKeys(groupNames[row]) do
				RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster][name] = (row-1)*5 + col
				col = col + 1
			end
		end
	end
	RIC_Group_Manager.drawGroupLabels()
	-- No need to check arrangability here since player raid and roster did not change on its own, and is not affected by flattening
end

function RIC_Group_Manager.MovedToPlayerBank(label)
	RIC_Group_Manager.setGroupPosition(label.name, 0)
	RIC_Group_Manager.draw(true)
end

function RIC_Group_Manager.SetLabel(label, statusLabel, name)
	if name then
		-- Set label
		label.name = name
		label:SetText(name)
		local playerInfo = RIC_Roster_Browser.getPlayerInfo(name)
		local classColor
		if playerInfo ~= nil then
			statusLabel:SetImage(getStatusSymbolImagePath(playerInfo.status))
			classColor = getClassColor(playerInfo.classFileName, "RGB")
		else
			statusLabel:SetImage("Interface\\AddOns\\RaidInviteClassic\\img\\question_mark")
			classColor = getClassColor("UNKNOWN_CLASS", "RGB")
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

function RIC_Group_Manager.assignGroupLabelFunctionality(label)
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
			RIC_Group_Manager.MovedToPlayerBank(label)
		else
			local putToGroup = function()
				for iRow = 1, 8 do
					if label.row ~= iRow then
						for iCol = 1, 5 do
							if MouseIsOver(RIC.raidPlayerLabels[iRow][iCol].frame) then
								RIC_Group_Manager.setGroupPosition(label.name, (iRow-1)*5 + iCol)
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
			RIC_Group_Manager.MovedToPlayerBank(self)
		end
	end)
end

function RIC_Group_Manager.draw(rosterChanged)
	RIC_Group_Manager.showPlayerBank()
	RIC_Group_Manager.flattenGroups()
	if rosterChanged then
		RIC_Group_Manager.updateArrangeBox()
	end
end

-- Set player name to a certain raid position, possibly swapping positions with already existing player on this position
function RIC_Group_Manager.setGroupPosition(name, position)
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
	RIC_Group_Manager.draw(true) -- Redraw UI and flatten groups, since roster changed
end

function RIC_Group_Manager.drawGroupLabels()
	local filledPositions = reverseMap(RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster])
	for row = 1, 8 do
		for col = 1, 5 do
			RIC_Group_Manager.SetLabel(RIC.raidPlayerLabels[row][col], RIC.raidPlayerStatusLabels[row][col], filledPositions[(row-1)*5 + col])
		end
	end
end


function RIC_Group_Manager.showPlayerBank()
	if isDraggingLabel then
		shouldUpdatePlayerBank = true
		return
	end

	local index = 0
	for name, val in pairsByKeys(RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster]) do
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
									RIC_Group_Manager.setGroupPosition(playerLabel.name, (row-1)*5 + col)
									RIC_Group_Manager.showPlayerBank()
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
						RIC_Group_Manager.showPlayerBank()
					end
				end)

				playerLabel:SetCallback("OnClick", function(self, _, button)
					if button == "RightButton" then
						RIC_Roster_Browser.remove(self.name)
						-- Update data and view
						RIC_Roster_Browser.buildRosterRaidList()
						-- Redraw group view to reflect change
						RIC_Group_Manager.draw(true)
					end
				end)

				RIC.playerBank.scroll:AddChild(playerLabel)
				RIC.playerBank.scroll:AddChild(statusLabel)
				table.insert(RIC.playerBank.scroll.playerLabels, playerLabel)
				table.insert(RIC.playerBank.scroll.playerStatusLabels, statusLabel)
			end

			-- Set player label
			RIC_Group_Manager.SetLabel(playerLabel, statusLabel, name)
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

function RIC_Group_Manager.unassignAll()
	for name, _ in pairs(RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster]) do
		RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster][name] = 0
	end
	RIC_Group_Manager.draw(true)
end

-- Checks for potential player swaps by comparing current to desired group setup.
-- Returns true if a swap was found and attempted, false otherwise
function RIC_Group_Manager.getMove()
	local raidPlayers = getRaidMembers()
	-- Go through roster list and check which people are in the raid but not in the right group
	for name, targetPosition in pairs(RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster]) do
		if raidPlayers[name] ~= nil then -- If player is not in raid, we ignore that player
			local currGroup = raidPlayers[name].subgroup
			local targetGroup = math.ceil(targetPosition/5)
			if (targetPosition > 0) and (currGroup ~= targetGroup) then -- Only do something if the player is not in the desired group AND not in the list of unassigned players
				-- Check target group for players
				local targetGroupPlayersPrio = {}
				local targetGroupSize = 0
				for otherName, otherData in pairs(raidPlayers) do
					if otherData["subgroup"] == targetGroup then -- Potential swap partner?
						local otherTargetPosition = RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster][otherName]
						targetGroupSize = targetGroupSize + 1
						if otherTargetPosition ~= nil then
							-- Swap candidate is also on the roster
							local otherTargetGroup = math.ceil(otherTargetPosition/5)
							if otherTargetGroup == currGroup then -- If this person needs to go into the group that we want to move the other player out of, perfect match - priority 1
								table.insert(targetGroupPlayersPrio, {1, otherData})
							elseif otherTargetGroup ~= targetGroup then -- If this person needs to go into another group, but not the ones we swap someone out of, priority 2
								table.insert(targetGroupPlayersPrio, {3, otherData})
							end -- If swap candidate is already in his correct group, dont swap them!
						else
							-- Swap candidate is not on the roster - we dont care where to put them, but also dont want to move them around unnecessarily
							table.insert(targetGroupPlayersPrio,{4, otherData})
						end
					end
				end
				-- We have the priority for all swap candidates, now choose the best action
				table.sort(targetGroupPlayersPrio, function(a,b) return a[1] < b[1] end)
				if #targetGroupPlayersPrio > 0 and targetGroupPlayersPrio[1][1] == 1 then
					--print("PRIO 1: Swapping " .. name .. " with " .. targetGroupPlayersPrio[1][2]["name"])
					return {cmd = "SWAP", from=raidPlayers[name]["index"], to=targetGroupPlayersPrio[1][2]["index"]}
				elseif targetGroupSize < 5 then -- Empty space in target group!
					--print("PRIO 2: Putting " .. name .. " into empty slot in group " .. tostring(targetGroup))
					return {cmd = "SET", from=raidPlayers[name]["index"], targetGroup, to=targetGroup}
				elseif #targetGroupPlayersPrio > 0 and targetGroupPlayersPrio[1][1] == 3 then
					--print("PRIO 3: Swapping " .. name .. " with " .. targetGroupPlayersPrio[1][2]["name"])
					return {cmd = "SWAP", from=raidPlayers[name]["index"], to=targetGroupPlayersPrio[1][2]["index"]}
				elseif #targetGroupPlayersPrio > 0 and targetGroupPlayersPrio[1][1] == 4 then
					--print("PRIO 4: Swapping " .. name .. " with non-roster player " .. targetGroupPlayersPrio[1][2]["name"])
					return {cmd = "SWAP", from=raidPlayers[name]["index"], to=targetGroupPlayersPrio[1][2]["index"]}
				end
			end
		end
	end
	--print("NO SWAP FOUND")
	return nil
end

function RIC_Group_Manager.move(action)
	if action.cmd == "SWAP" then
		SwapRaidSubgroup(action.from, action.to)
	elseif action.cmd == "SET" then
		SetRaidSubgroup(action.from, action.to)
	else
		RIC:Print("ERROR: Move not detected")
	end
	moveCounter = moveCounter + 1
end

function RIC_Group_Manager.startSwap()
	inSwap = true
	moveCounter = 0
	RIC_Group_Manager.sendInProgress()
	RIC_Group_Manager.setUnarrangable("REARRANGING...")
	local action = RIC_Group_Manager.getMove()
	if action == nil then -- No swap needed
		-- Group setup was already correct and we didn't find any swap candidate - stop! In other case, OnRosterUpdate will trigger
		RIC_Group_Manager.StopSwap()
	else
		RIC_Group_Manager.move(action)
	end
end

function RIC_Group_Manager.StopSwap()
	inSwap = false
	moveCounter = 0
	RIC_Group_Manager.sendEndProgress()
	RIC_Group_Manager.flattenGroups()
	RIC_Group_Manager.updateArrangeBox()
end

function RIC_Group_Manager.OnRosterUpdate()
	if remoteInSwap then -- Don't do anything if a remote swap is in progress
		if inSwap then
			RIC:Print("|cFFFF0000ERROR: Our group swap was interrupted by a remote swap. Stopping...|r")
			inSwap = false
			moveCounter = 0
		end
		return
	end

	RIC_Group_Manager.updateArrangeBox()

	if inSwap then
		-- Stop after too many swaps
		if moveCounter > 40 then
			RIC:Print("|cFFFF0000ERROR: Something went wrong, we are still stuck rearranging after 40 swaps. Terminating...|r")
			RIC_Group_Manager.StopSwap()
			return
		end

		-- Check if we can continue swapping
		local errorMessage = RIC_Group_Manager.checkArrangable()
		if errorMessage and errorMessage ~= "REARRANGING..." then -- Stop if we have some problem, except if the "problem" is that we are currently swapping
			RIC_Group_Manager.StopSwap()
			return
		end

		-- Try next swap. If we dont have any swap candidates anymore, stop!
		local action = RIC_Group_Manager.getMove()
		if action == nil then
			RIC_Group_Manager.StopSwap()
		else
			RIC_Group_Manager.move(action)
		end
	end
end

function RIC_Group_Manager.checkArrangable()
	local errorMessage = nil
	if not IsInRaid() then
		errorMessage = "CANNOT REARRANGE - NOT IN A RAID GROUP"
		RIC_Group_Manager.setUnarrangable(errorMessage)
		return errorMessage
	end

	if RIC_Group_Manager.getMove() == nil then
		-- Our roster is already arranged as desired!
		errorMessage = "RAID IS ARRANGED"
		RIC_Group_Manager.setUnarrangable(errorMessage)
		return errorMessage
	end

	if not IsRaidAssistant() then
		errorMessage = "CANNOT REARRANGE - NOT A RAID LEADER OR ASSISTANT"
		RIC_Group_Manager.setUnarrangable(errorMessage)
		return errorMessage
	end

	if InCombatLockdown() then
		errorMessage = "CANNOT REARRANGE - IN COMBAT"
		RIC_Group_Manager.setUnarrangable(errorMessage)
		return errorMessage
	end

	if inSwap then
		errorMessage = "REARRANGING..."
		RIC_Group_Manager.setUnarrangable(errorMessage)
		return errorMessage
	end

	if remoteInSwap then
		errorMessage = "REARRANGEMENT IN PROGRESS BY " .. remoteSender
		RIC_Group_Manager.setUnarrangable(errorMessage)
		return errorMessage
	end

	return errorMessage
end

function RIC_Group_Manager.updateArrangeBox()
	local msg = RIC_Group_Manager.checkArrangable()
	if msg ~= nil then
		RIC_Group_Manager.setUnarrangable(msg)
	else
		RIC_Group_Manager.setArrangable()
	end
end

function RIC_Group_Manager.setArrangable()
	RIC.rearrangeRaid:SetText("REARRANGE RAID")
	RIC.rearrangeRaid:SetDisabled(false)
	RIC.rearrangeRaid.frame:EnableMouse(true)
	RIC.rearrangeRaid.text:SetTextColor(1.0, 1.0, 1.0)
end

function RIC_Group_Manager.setUnarrangable(text)
	RIC.rearrangeRaid:SetText(text)
	RIC.rearrangeRaid:SetDisabled(true)
	RIC.rearrangeRaid.frame:EnableMouse(false)
	RIC.rearrangeRaid.text:SetTextColor(0.35, 0.35, 0.35)
end

function RIC_Group_Manager.rearrangeRaid()
	local errorMessage = RIC_Group_Manager.checkArrangable()
	if errorMessage == nil then -- Check to see whether we can start
		RIC_Group_Manager.startSwap()
	else
		RIC_Group_Manager.setUnarrangable(errorMessage)
	end
end

function RIC_Group_Manager.sendInProgress()
	local message = {
		key = "SWAP_IN_PROGRESS",
	}
	SendComm(message,"RAID")
end

function RIC_Group_Manager.sendEndProgress()
	local message = {
		key = "SWAP_END",
	}
	SendComm(message,"RAID")
end

function RIC_Group_Manager.receiveInProgress(sender)
	remoteInSwap = true
	remoteSender = sender
	RIC_Group_Manager.setUnarrangable("REARRANGEMENT IN PROGRESS BY " .. sender)
end

function RIC_Group_Manager.receiveEndProgress()
	remoteInSwap = false
	RIC_Group_Manager.updateArrangeBox()
end
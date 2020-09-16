local AceGUI = LibStub("AceGUI-3.0")
local LD = LibStub("LibDeflate")
local LSM = LibStub("LibSharedMedia-3.0")
local DEFAULT_FONT = LSM.MediaTable.font[LSM:GetDefault('font')]

local shouldPrint = false
local inSwap = false
local remoteInSwap = false
local swapCounter = 0

local isDraggingLabel = false
local shouldUpdatePlayerBank = false

function RIC_Group_Manager.flattenGroups()
	local groupNames = {}
	for name, position in pairs(RIC.db.realm.RosterList) do
		if position > 0 then
			local row = math.ceil(position/5)
			if groupNames[row] == nil then
				groupNames[row] = {}
			end
			table.insert(groupNames[row], name)
		end
	end
	for row=1,8 do
		if groupNames[row] ~= nil then
			for col, name in ipairs(groupNames[row]) do
				RIC.db.realm.RosterList[name] = (row-1)*5 + col
			end
		end
	end
	RIC_Group_Manager.drawAllLabels()
	RIC_Group_Manager.CheckArrangable()
end

function RIC_Group_Manager.MovedToPlayerBank(label)
	RIC_Group_Manager.setGroupPosition(label.name, 0)
	RIC_Group_Manager.flattenGroups()
	RIC_Group_Manager.showPlayerBank()
end

function RIC_Group_Manager.SetLabel(label, name)
	if name then
		-- Set label
		label.name = name
		label:SetText(name)
		-- label:SetImage("Interface\\AddOns\\RaidInviteClassic\\img\\checkmark") -- TODO put invite status image onto labels
		local playerInfo = RIC_Roster_Browser.getPlayerInfo(name)
		label.label:SetTextColor(playerInfo.classColor.r, playerInfo.classColor.g, playerInfo.classColor.b)
		label.frame:EnableMouse(true)
		label.frame:SetMovable(true)
	else
		-- Clear label
		label.name = nil
		label:SetText("Empty")
		label.label:SetTextColor(0.35, 0.35, 0.35)
		label.frame:EnableMouse(false)
		label.frame:SetMovable(false)
	end
end

function RIC_Group_Manager.assignLabelFunctionality(label)
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
		local x, y = GetXY()
		local left, top, width, height = RIC.playerBank.frame:GetRect()
		if x >= left and x <= left + width and y >= top and y <= y + height then
			RIC_Group_Manager.MovedToPlayerBank(label)
		else
			local putToGroup = function()
				for iRow = 1, 8 do
					if label.row ~= iRow then
						for iCol = 1, 5 do
							local cLeft, cTop, cWidth, cHeight = RIC.raidPlayerLabels[iRow][iCol].frame:GetRect()
							if x >= cLeft and x <= cLeft + cWidth and y >= cTop and y <= cTop + cHeight then
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

function RIC_Group_Manager.draw()
	RIC_Group_Manager.showPlayerBank()
	RIC_Group_Manager.flattenGroups()
end

-- Set player name to a certain raid position, possibly swapping positions with already existing player on this position
function RIC_Group_Manager.setGroupPosition(name, position)
	-- Position is zero => Simply put player on bank, no replacement
	if position == 0 then
		RIC.db.realm.RosterList[name] = 0
	else
		-- Put this character on a certain spot in the raid. Check whether this spot was filled. In that case, swap!
		for currName, currPos in pairs(RIC.db.realm.RosterList) do
			if currPos == position then
				-- Set position of old person to the one that will be freed now
				RIC.db.realm.RosterList[currName] = RIC.db.realm.RosterList[name]
				break
			end
		end
		RIC.db.realm.RosterList[name] = position
	end
	-- Finally, compress groups
	RIC_Group_Manager.flattenGroups()
end

function RIC_Group_Manager.drawAllLabels()
	local filledPositions = reverseMap(RIC.db.realm.RosterList)
	for row = 1, 8 do
		for col = 1, 5 do
			RIC_Group_Manager.SetLabel(RIC.raidPlayerLabels[row][col], filledPositions[(row-1)*5 + col])
		end
	end
end


function RIC_Group_Manager.showPlayerBank()
	if isDraggingLabel then
		shouldUpdatePlayerBank = true
		return
	end

	local index = 0
	for name, val in pairs(RIC.db.realm.RosterList) do
		print(name, val)
		if val == 0 then
			index = index + 1
			local playerLabel
			if RIC.playerBank.scroll.playerLabels[index] then
				playerLabel = RIC.playerBank.scroll.playerLabels[index]
				playerLabel.frame:EnableMouse(true)
			else
				playerLabel = AceGUI:Create("InteractiveLabel")
				playerLabel:SetFont(DEFAULT_FONT, 12)
				playerLabel:SetHighlight("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
				playerLabel:SetFullWidth(true)

				local anchorPoint, parentFrame, relativeTo, ptX, ptY
				playerLabel.frame:EnableMouse(true)
				playerLabel.frame:SetMovable(true)
				playerLabel.frame:RegisterForDrag("LeftButton")
				playerLabel.frame:SetScript("OnDragStart", function(self)
					isDraggingLabel = true
					for row = 1, 8 do
						for col = 1, 5 do
							local label = RIC.raidPlayerLabels[row][col]
							local left, top, width, height = label.frame:GetRect()
							label.savedRect = {}
							label.savedRect.left = left
							label.savedRect.top = top
							label.savedRect.width = width
							label.savedRect.height = height
						end
					end
					anchorPoint, parentFrame, relativeTo, ptX, ptY = self:GetPoint()
					self:SetParent(UIParent)
					self:SetFrameStrata("TOOLTIP")
					self:StartMoving()
				end)

				playerLabel.frame:SetScript("OnDragStop", function(self)
					self:StopMovingOrSizing()
					local x, y = GetXY()
					local putToGroup = function()
						for row = 1, 8 do
							for col = 1, 5 do
								local label = RIC.raidPlayerLabels[row][col]
								if x >= label.savedRect.left and x <= label.savedRect.left + label.savedRect.width and y >= label.savedRect.top and y <= label.savedRect.top + label.savedRect.height then
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

				RIC.playerBank.scroll:AddChild(playerLabel)
				table.insert(RIC.playerBank.scroll.playerLabels, playerLabel)
			end

			playerLabel.name = name
			playerLabel:SetText(name)
			local classColor = RIC_Roster_Browser.getPlayerInfo(name).classColor
			playerLabel.label:SetTextColor(classColor.r, classColor.g, classColor.b)
		end
	end

	print(#RIC.playerBank.scroll.playerLabels)
	while index < #RIC.playerBank.scroll.playerLabels do
		index = index + 1
		RIC.playerBank.scroll.playerLabels[index].name = nil
		RIC.playerBank.scroll.playerLabels[index]:SetText(nil)
		RIC.playerBank.scroll.playerLabels[index].frame:EnableMouse(false)
	end

	-- RIC.playerBank.scroll:SetScroll(newlyAddedNameIndex / (#playerTableNames - 1) * 1000) -- TODO possibly set scroll pos
	RIC.playerBank.scroll:DoLayout()
end

function RIC_Group_Manager.unassignAll()
	for name, _ in pairs(RIC.db.realm.RosterList) do
		RIC.db.realm.RosterList[name] = 0
	end
	RIC_Group_Manager.draw()
end

function RIC_Group_Manager.DoSwap()
	if swapCounter > 40 then
		print("|cFFFF0000ERROR: Something went wrong, we are still stuck rearranging after 40 swaps. Terminating...|r")
		RIC_Group_Manager.StopSwap()
		return
	end

	local errorMessage = RIC_Group_Manager.CheckArrangable()
	if errorMessage then
		print("|cFFFF0000ERROR: " .. errorMessage .. "|r")
		RIC_Group_Manager.StopSwap()
		return
	end

	RIC_Group_Manager.SetUnarrangable("REARRANGING...")
	RIC_Group_Manager.SendInProgress()

	local raidPlayers = getRaidMembers()
	-- Go through roster list and check which people are in the raid but not in the right group
	for name, targetPosition in pairs(RIC.db.realm.RosterList) do
		if raidPlayers[name] ~= nil then -- If player is not in raid, we ignore that player
			local currGroup = raidPlayers[name].subgroup
			local targetGroup = math.ceil(targetPosition/5)
			if (targetPosition > 0) and (currGroup ~= targetGroup) then -- Only do something if the player is not in the desired group AND not in the list of unassigned players
				-- Check target group for players
				local targetGroupPlayersPrio = {}
				local targetGroupSize = 0
				for otherName, otherData in pairs(raidPlayers) do
					if otherData["subgroup"] == targetGroup then -- Potential swap partner?
						local otherTargetPosition = RIC.db.realm.RosterList[otherName]
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
					print("PRIO 1: Swapping " .. name .. " with " .. targetGroupPlayersPrio[1][2]["name"])
					SwapRaidSubgroup(raidPlayers[name]["index"], targetGroupPlayersPrio[1][2]["index"])
					swapCounter = swapCounter + 1
					return
				elseif targetGroupSize < 5 then -- Empty space in target group!
					print("PRIO 2: Putting " .. name .. " into empty slot in group " .. tostring(targetGroup))
					SetRaidSubgroup(raidPlayers[name]["index"], targetGroup)
					swapCounter = swapCounter + 1
					return
				elseif #targetGroupPlayersPrio > 0 and targetGroupPlayersPrio[1][1] == 3 then
					print("PRIO 3: Swapping " .. name .. " with " .. targetGroupPlayersPrio[1][2]["name"])
					swapCounter = swapCounter + 1
					return
				elseif #targetGroupPlayersPrio > 0 and targetGroupPlayersPrio[1][1] == 4 then
					print("PRIO 4: Swapping " .. name .. " with non-roster player " .. targetGroupPlayersPrio[1][2]["name"])
					swapCounter = swapCounter + 1
					return
				end
			end
		end
	end
	-- No action was possible anymore! STOP!
	RIC_Group_Manager.StopSwap()
end

function RIC_Group_Manager.StopSwap()
	inSwap = false
	swapCounter = 0
	RIC_Group_Manager.SendEndProgress()
	RIC_Group_Manager.flattenGroups()
	if shouldPrint then
		print("DONE!")
		shouldPrint = false
	end
end

function RIC_Group_Manager.OnRosterUpdate()
	if remoteInSwap then
		return
	end

	if inSwap then
		RIC_Group_Manager.DoSwap()
	else
		RIC_Group_Manager.CheckArrangable()
	end
end

function RIC_Group_Manager.CheckArrangable(enteredCombat)
	local rearrangeRaidText = "REARRANGE RAID"
	local errorMessage
	if not IsInRaid() then
		errorMessage = "CANNOT REARRANGE - NOT IN A RAID GROUP"
		RIC_Group_Manager.SetUnarrangable(errorMessage)
		return errorMessage
	end

	if not IsRaidAssistant() then
		errorMessage = "CANNOT REARRANGE - NOT A RAID LEADER OR ASSISTANT"
		RIC_Group_Manager.SetUnarrangable(errorMessage)
		return errorMessage
	end

	if enteredCombat or InCombatLockdown() then
		errorMessage = "CANNOT REARRANGE - IN COMBAT"
		RIC_Group_Manager.SetUnarrangable(errorMessage)
		return errorMessage
	end

	RIC.rearrangeRaid:SetText(rearrangeRaidText)
	RIC.rearrangeRaid:SetDisabled(false)
	RIC.rearrangeRaid.frame:EnableMouse(true)
	RIC.rearrangeRaid.text:SetTextColor(1.0, 1.0, 1.0)
end

function RIC_Group_Manager.SetUnarrangable(text)
	RIC.rearrangeRaid:SetText(text)
	RIC.rearrangeRaid:SetDisabled(true)
	RIC.rearrangeRaid.frame:EnableMouse(false)
	RIC.rearrangeRaid.text:SetTextColor(0.35, 0.35, 0.35)
end

function RIC_Group_Manager.RearrangeRaid()
	inSwap = true
	swapCounter = 0
	RIC_Group_Manager.DoSwap()
end

function RIC_Group_Manager.SendInProgress()
	local message = {
		key = "SWAP_IN_PROGRESS",
	}
	RIC_Group_Manager.SendComm(message)
end

function RIC_Group_Manager.SendEndProgress()
	local message = {
		key = "SWAP_END",
	}
	RIC_Group_Manager.SendComm(message)
end

function RIC_Group_Manager.SendComm(message)
	local messageSerialized = LD:EncodeForWoWAddonChannel(LD:CompressDeflate(RIC:Serialize(message)))
	RIC:SendCommMessage("ricroster", messageSerialized, "RAID")
end

function RIC:OnCommReceived(prefix, message, distribution, sender)
	if prefix ~= "ricroster" or sender == UnitName("player") or not message then
		return
	end

	local decoded = LD:DecodeForWoWAddonChannel(message)
	if not decoded then
		print("Could not decode addon message. Sender needs to update to the latest version of cleangroupassigns!")
		return
	end
	local decompressed = LD:DecompressDeflate(decoded)
	if not decompressed then
		print("Failed to decompress addon message. Sender needs to update to the latest version of cleangroupassigns!")
		return
	end

	local didDeserialize, message = RIC:Deserialize(decompressed)
	if not didDeserialize then
		print("Failed to deserialize sync: " .. message)
		return
	end

	local key = message["key"]
	if not key then
		print("Failed to parse deserialized comm.")
		return
	end

	if key == "SWAP_IN_PROGRESS" then
		remoteInSwap = true
		RIC_Group_Manager.SetUnarrangable("REARRANGEMENT IN PROGRESS BY " .. sender)
		return
	end

	if key == "SWAP_END" then
		remoteInSwap = false
		RIC_Group_Manager.CheckArrangable()
		return
	end
end
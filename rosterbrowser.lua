local sortMethod = "asc"
local currSortIndex = 1
local rosterOffset = 0

local rosterRaidList = {} -- Table view of raid + roster list
local selectedList = {}

-- Invite handling
local invitePhaseActive = false
local inviteStatusList = {}
local inviteTimeList = {}

function RIC_Roster_Browser.buildRosterRaidList()
	-- Get current guild info
	-- Checks guild member list for people who JUST came online.
	-- In that case, set their invite status to NOT_INVITED since they cannot have a pending invitation,
	-- and a failed invitation earlier (e.g. because they were offline) does not matter anymore.
	-- This leads to faster invites for people who come online

	local guildMembers = RIC_Guild_Manager.getGuildMembers()
	for name,data in pairs(guildMembers) do
		if data["justCameOnline"] == true then
			-- This player just came online - reset their invite status!
			inviteStatusList[name] = RIC_InviteStatus["NOT_INVITED"]
			inviteTimeList[name] = nil -- Doesn't matter when we last invited that person since they just logged in
			RIC_Guild_Manager.resetCameOnlineFlag(name)
		end
	end

	-- Go through all raid members, add them to overall list if they are not in roster list
	rosterRaidList = {}
	local inRaid = {}
	local raidMembers = getRaidMembers()
	for name, data in pairs(raidMembers) do
		-- Check guild rank of raid member (if in guild?)
		local guildRank = "<Not in Guild>"
		local guildRankIndex = 0
		if guildMembers[name] ~= nil then
			guildRank = guildMembers[name]["rank"]
			guildRankIndex = guildMembers[name]["rankIndex"]
		end

		inRaid[name] = 1

		-- filter based on view selection
		local status = getStatusSymbol(true, (RIC_RosterList[name] ~= nil), data["online"], inviteStatusList[name])
		if RIC_Roster_Browser.showStatusSymbol(status) then
			table.insert(rosterRaidList, {
				name,
				getClassColor(data["classFileName"]),
				guildRank,
				guildRankIndex,
				status
			})
		end
	end

	-- Add all people on RIC_RosterList to the overall list, if they are not in raid. If possible, check their data in guild
	for name,present in pairs(RIC_RosterList) do
		if inRaid[name] == nil then -- Only process people NOT in raid right now
			if guildMembers[name] == nil then -- Person is not in guild
				local status = getStatusSymbol(false, true, -1, inviteStatusList[name]) -- We dont know online status of non-raid non-guild members
				if RIC_Roster_Browser.showStatusSymbol(status) then -- Check if this status should be shown
					table.insert(rosterRaidList, {
						name,
						getClassColor("UNKNOWN_CLASS"),
						"<Not in Guild>",
						0, -- Rank 0 for non-guildies
						status
					})
				end
			else
				local status = getStatusSymbol(false, true, guildMembers[name]["online"], inviteStatusList[name])
				if RIC_Roster_Browser.showStatusSymbol(status) then -- Check if this status should be shown
					table.insert(rosterRaidList, {
						name,
						guildMembers[name]["color"],
						guildMembers[name]["rank"],
						guildMembers[name]["rankIndex"],
						status
					})
				end
			end
		end
	end

	-- Clear selection from people who are not shown in rosterRaidList
	local newSelectedList = {}
	for i=1,#rosterRaidList do
		if selectedList[rosterRaidList[i][1]] ~= nil then
			assert(selectedList[rosterRaidList[i][1]] == 1)
			newSelectedList[rosterRaidList[i][1]] = 1
		end
	end
	selectedList = newSelectedList

	-- Show current roster size as text
	_G["RIC_RosterNumberText"]:SetText("In Roster: " .. hashLength(RIC_RosterList))

	-- Set up sliders
	if #rosterRaidList > 20 then
		local newVal = #rosterRaidList-20
		_G["RIC_RosterSliderContainer"]:Show()
		_G["RIC_RosterSlider"]:SetValueStep(1)
		if rosterOffset > newVal then
			rosterOffset = newVal
		else
			rosterOffset = math.floor(_G["RIC_RosterSlider"]:GetValue())
		end
		_G["RIC_RosterSlider"]:SetMinMaxValues(0, newVal)
		_G["RIC_RosterSlider"]:SetValue(_G["RIC_RosterSlider"]:GetValue())
	else
		rosterOffset = 0
		_G["RIC_RosterSliderContainer"]:Hide()
		_G["RIC_RosterSlider"]:SetValue(rosterOffset)
	end

	-- Sort according to current sorting index
	RIC_Roster_Browser.sortTable(currSortIndex)

	-- Display entries
	RIC_Roster_Browser.updateListing()
end

-- Function: updateListing
-- Purpose: Displays the data for the scrolling table
function RIC_Roster_Browser.updateListing()
	for ci = 1, 20 do
		local row = rosterRaidList[ci+rosterOffset]
		if row then
			_G["RIC_RosterFrameEntry"..ci.."Name"]:SetText(row[2] .. row[1])
			_G["RIC_RosterFrameEntry"..ci.."Rank"]:SetText(row[3])
			_G["RIC_RosterFrameEntry"..ci]:Show()
			local theName = row[1]
			if selectedList[theName] and selectedList[theName] == 1 then
				_G["RIC_RosterFrameEntry"..ci.."Check"]:Show()
			else
				_G["RIC_RosterFrameEntry"..ci.."Check"]:Hide()
			end

			if row[5] == RIC_Status["READY"] then
				_G["RIC_RosterFrameEntry"..ci.."Status"]:SetTexture("Interface\\AddOns\\RaidInviteClassic\\img\\checkmark")
			elseif row[5] == RIC_Status["EXTRA"] then
				_G["RIC_RosterFrameEntry"..ci.."Status"]:SetTexture("Interface\\AddOns\\RaidInviteClassic\\img\\plus")
			elseif row[5] == RIC_Status["NOT_INVITED"] then
				_G["RIC_RosterFrameEntry"..ci.."Status"]:SetTexture("Interface\\AddOns\\RaidInviteClassic\\img\\dash")
			elseif row[5] == RIC_Status["INVITE_PENDING"] then
				_G["RIC_RosterFrameEntry"..ci.."Status"]:SetTexture("Interface\\AddOns\\RaidInviteClassic\\img\\dots")
			elseif row[5] == RIC_Status["INVITE_FAILED"] then
				_G["RIC_RosterFrameEntry"..ci.."Status"]:SetTexture("Interface\\AddOns\\RaidInviteClassic\\img\\red_cross")
			elseif row[5] == RIC_Status["MISSING"] then
				_G["RIC_RosterFrameEntry"..ci.."Status"]:SetTexture("Interface\\AddOns\\RaidInviteClassic\\img\\lightning")
			elseif row[5] == RIC_Status["OTHER"] then
				_G["RIC_RosterFrameEntry"..ci.."Status"]:SetTexture("Interface\\AddOns\\RaidInviteClassic\\img\\question_mark")
			else
				_G["RIC_RosterFrameEntry"..ci.."Status"]:SetTexture("Interface\\AddOns\\RaidInviteClassic\\img\\question_mark")
				printRIC("ERROR: Could not find a status symbol for " .. theName)
			end

		else
			_G["RIC_RosterFrameEntry"..ci]:Hide()
		end
	end
end

function RIC_Roster_Browser.showStatusSymbol(status)
	-- Check if the given status should currently be shown in the roster browser
	if status == RIC_Status["READY"] then
		return _G["RIC_ReadyBox"]:GetChecked()
	elseif status == RIC_Status["EXTRA"] then
		return _G["RIC_ExtraBox"]:GetChecked()
	elseif status == RIC_Status["NOT_INVITED"] then
		return _G["RIC_NotInvitedBox"]:GetChecked()
	elseif status == RIC_Status["INVITE_PENDING"] then
		return _G["RIC_InvitePendingBox"]:GetChecked()
	elseif status == RIC_Status["INVITE_FAILED"] then
		return _G["RIC_InviteFailedBox"]:GetChecked()
	elseif status == RIC_Status["MISSING"] then
		return _G["RIC_MissingBox"]:GetChecked()
	elseif status == RIC_Status["OTHER"] then
		return _G["RIC_OtherBox"]:GetChecked()
	end
end

function RIC_Roster_Browser.generateRosterList()
	-- Generates a list of names based on current roster list
	local rosterString = ""
	for name, present in pairs(RIC_RosterList) do
		rosterString = rosterString .. name .. "\n"
	end
	return rosterString
end

function RIC_Roster_Browser.importRoster(rosterString)
	-- Use newlines, colons or comma to separate characters
	local swapString = gsub(rosterString, ";", "\n")
	swapString = gsub(swapString, ",", "\n")
	local parsedList = { strsplit("\n", swapString) }

	-- Parse names one by one, add to temp list
	local newList = {}
	for i=1,#parsedList do
		local name = trim_name(parsedList[i])
		if string.utf8len(name) > 2 then -- Char names in WoW need to be at least 3 chars long
			newList[name] = 1
		end
	end

	-- If we have a non-empty list, we parsed successfully: Overwrite current roster list
	if hashLength(newList) > 0 then
		RIC_RosterList = newList
	end

	-- Update roster view
	RIC_Roster_Browser.buildRosterRaidList()
end

function RIC_Roster_Browser.updateOffset(val)
	-- Activates when slider is dragged, gives continuous value -> change to integer
	rosterOffset = math.floor(val)
	RIC_Roster_Browser.updateListing()
end

function RIC_Roster_Browser.clearSelection()
	selectedList = {}
	RIC_Roster_Browser.updateListing()
end

function RIC_Roster_Browser.selectAll()
	selectedList = {}
	for ci=1, #rosterRaidList do
		selectedList[rosterRaidList[ci][1]] = 1
	end
	RIC_Roster_Browser.updateListing()
end

function RIC_Roster_Browser.selectRow(rowNum)
	local theRow = rosterRaidList[rowNum+rosterOffset]
	if theRow then
		local theName = theRow[1]
		if theName then
			if selectedList[theName] ~= nil then
				selectedList[theName] = nil
			else
				selectedList[theName] = 1
			end
		end
	end

	RIC_Roster_Browser.updateListing()
end

function RIC_Roster_Browser.sliderButtonPushed(dir)
	local currValue = math.floor(_G["RIC_RosterSlider"]:GetValue())
	if (dir == 1) and currValue > 0 then
		newVal = currValue-3
		if newVal < 0 then
			newVal = 0
		end
		_G["RIC_RosterSlider"]:SetValue(newVal)
	elseif (dir == 2) and (currValue < (#rosterRaidList-20)) then
		newVal = currValue+3
		if newVal > (#rosterRaidList-20) then
			newVal = (#rosterRaidList-20)
		end
		_G["RIC_RosterSlider"]:SetValue(newVal)
	end
end

function RIC_Roster_Browser.quickScroll(self, delta)
	local currValue = math.floor(_G["RIC_RosterSlider"]:GetValue())
	if (delta > 0) and currValue > 0 then
		newVal = currValue-1
		if newVal < 0 then
			newVal = 0
		end
		_G["RIC_RosterSlider"]:SetValue(newVal)
	elseif (delta < 0) and (currValue < (#rosterRaidList-20)) then
		newVal = currValue+1
		if newVal > (#rosterRaidList-20) then
			newVal = (#rosterRaidList-20)
		end
		_G["RIC_RosterSlider"]:SetValue(newVal)
	end
end

function RIC_Roster_Browser.sendInvites()
	if invitePhaseActive then
		local raidMembers = getRaidMembers()
		local guildMembers = RIC_Guild_Manager.getGuildMembers() -- Retrieve this so invite function can check if people are online

		-- Go through roster list, invite players not yet in raid, update invite status
		for name,present in pairs(RIC_RosterList) do
			-- Check if already in raid group
			if raidMembers[name] == nil then
				-- If not in raid group, check if we already invited that person or not
				if (inviteStatusList[name] == nil) or (inviteStatusList[name] == RIC_InviteStatus["NOT_INVITED"]) then
					-- Not invited before. Could have been in group and then left though, so check last invite date in case its there
					if (inviteTimeList[name] == nil) or ((time() - inviteTimeList[name]) > RIC_InviteInterval) then
						RIC_Roster_Browser.invite(name, false, guildMembers)
					end
				elseif inviteStatusList[name] == RIC_InviteStatus["INVITE_PENDING"] then
					-- Check for how long invite was pending, if its too long set to failed
					if (time() - inviteTimeList[name]) > 61 then -- After 60s, invite expires when not accepted or declined, so invite failed
						inviteStatusList[name] = RIC_InviteStatus["INVITE_FAILED"]
					end
				elseif inviteStatusList[name] == RIC_InviteStatus["INVITE_FAILED"] then
					-- Check last invite time, if longer than invite frequency, try inviting again!
					if (inviteTimeList[name] == nil) or ((time() - inviteTimeList[name]) > RIC_InviteInterval) then
						RIC_Roster_Browser.invite(name, false, guildMembers)
					end
				end
			end
		end
	end
end

-- Process an invite request whisper from one particular person
function RIC_Roster_Browser.inviteWhisper(author, msg)
	-- Check if message is an invite request, otherwise ignore
	if (not RIC_Codewords_Handler.containsCodeword(msg)) then
		return
	end

	-- Event if message has sth like "invite" in it, probably unrelated message if we are currently completely alone (e.g. "invite person X to the guild please")
	-- => Ignore request if we are alone. Also prevents people from pushing you into a group when you dont want to
	if ((not IsInGroup()) and (not IsInRaid())) and RIC_CodewordOnlyInGroup then
		printRIC("A codeword whisper by " .. author .. " was ignored because you were alone.")
		PlaySound(846)
		return
	end

	-- Check if we are currently allowing invite requests
	if RIC_CodewordOnlyDuringInvite and (not invitePhaseActive) then
		SendChatMessageRIC("Invite by codeword only possible during invite phase!", "WHISPER", nil, author)
		return
	end

	-- Check if author is in rosterList, otherwise deny request (send whisper back to person)
	if RIC_RosterWhispersOnly and (RIC_RosterList[author] == nil) then
		SendChatMessageRIC("You are not in the roster - did you forget to register for the raid in advance?", "WHISPER", nil, author)
		return
	end

	-- Check if person is guild member
	local guildMembers = RIC_Guild_Manager.getGuildMembers()
	if RIC_GuildWhispersOnly then
		if guildMembers[author] == nil then
			SendChatMessageRIC("You are not a guild member. Only guild members are invited automatically.", "WHISPER", nil, author)
			return
		end
	end

	-- So far, all conditions met - try to invite person
	RIC_Roster_Browser.invite(author, true, guildMembers)
end

-- Invites one particular person
function RIC_Roster_Browser.invite(person, reactive, guildMembers)
	-- Check if person is the character you are playing right now
	if person == UnitName("player") then
		return
	end

	-- Check if person already in raid
	local raidMembers = getRaidMembers()
	if raidMembers[person] ~= nil then
		if reactive then -- If we invite based on whisper, tell player he cant join
			SendChatMessageRIC("You can't be invited to the raid - you are already in it!", "WHISPER", nil, person)
		end
		return
	end

	-- Check if raid full
	if hashLength(raidMembers) >= MAX_RAID_MEMBERS then
		if reactive then
			-- React to whisper that the raid is full, but dont change any invite status
			SendChatMessageRIC("Raid already full - if you reserved a spot by registering for the raid in advance, contact the raid leader", "WHISPER", nil, author)
		else
			-- Our invite failed because the raid was full - dont try again for now
			inviteStatusList[person] = RIC_InviteStatus["INVITE_FAILED"]
			inviteTimeList[person] = time()
		end
		return
	end

	-- Check if this is a guild member but offline - in this case we don't even need to try an invite, since this clogs up the chat with invite error messages :)
	if not reactive then -- If reacting to invite request, the player is definitely online!
		guildMembers = guildMembers or getGuildMembers() -- Retrieve guild member list if not given to us as argument
		if (guildMembers[person] ~= nil) and (guildMembers[person]["online"] ~= 1) then
			-- Invite for this person will fail because they are offline - dont invite, instead record invite attempt time and set to failed invite status
			inviteStatusList[person] = RIC_InviteStatus["INVITE_FAILED"]
			inviteTimeList[person] = time()
			return
		end
	end

	-- Check if we have assist or lead in raid so we can actually invite someone (or we are alone at the moment)
	if (hashLength(raidMembers)==0) or (UnitIsGroupAssistant("player") or UnitIsGroupLeader("player")) then
		-- Either this is a reactive invite, so it's fine. It cannot be an active invite unless the raid leader does it, so thats also fine.
		-- Now check if we are still in group/alone (not RAID) and have to delay some invitations because too many are pending!
		local num_possible_invites_in_group = 5 - hashLength(raidMembers)
		if hashLength(raidMembers) == 0 then
			num_possible_invites_in_group = 4 -- If we didnt open a group, raidMembers is empty. But only 4 invites possible (us excluded)
		end
		-- If we are in raid - invite. If not, check if we have some slots in group leftover to invite people into
		if IsInRaid() or ((num_possible_invites_in_group - countFrequency(inviteStatusList, RIC_InviteStatus["INVITE_PENDING"])) > 0) then
			InviteUnit(person)
			inviteStatusList[person] = RIC_InviteStatus["INVITE_PENDING"]
			inviteTimeList[person] = time()
		else
			-- Only reason we did not invite this person now is because our group doesnt allow more invites right now
			-- Try in a few secs again, so pretend we never tried to invite in the first place
			inviteStatusList[person] = RIC_InviteStatus["NOT_INVITED"]
			inviteTimeList[person] = nil
		end
	else
		-- If we react to whisper, tell the person we cant invite them
		if reactive then
			SendChatMessageRIC("I cannot invite you since I don't have assist rights. ", "WHISPER", nil, person)
		end
	end
end

function RIC_Roster_Browser.processSystemMessage(msg)
	if string.find(msg, string.gsub(ERR_ALREADY_IN_GROUP_S, "%%s", "(%%S+)")) then -- This person is already in a group
		local playerName = string.match(msg, string.gsub(ERR_ALREADY_IN_GROUP_S, "%%s", "(%%S+)"))
		-- Set invite status
		inviteStatusList[playerName] = RIC_InviteStatus["INVITE_FAILED"]
		inviteTimeList[playerName] = time() -- We sent the invite just now, so save current time as last time we attempted invite
		if invitePhaseActive then -- Only notify if we are in the invite phase
			SendChatMessageRIC("WARNING: You could not be invited to the raid that starts now since you are already in a group. Please leave it!", "WHISPER", nil, playerName)
		end
	elseif string.find(msg, string.gsub(ERR_JOINED_GROUP_S, "%%s", "%%S+")) then -- Player joined group
		local playerName = string.match(msg, string.gsub(ERR_JOINED_GROUP_S, "%%s", "(%%S+)"))
		RIC_Durability_Manager.setPlayerWarning(playerName) -- Set this player to be flagged for durability check soon
		if invitePhaseActive then
			-- Convert to raid group if group exists and has at least two members
			local raidMembers = getRaidMembers()
			if hashLength(raidMembers) >= 2 then
				ConvertToRaid()

				-- Set master looter
				if RIC_MasterLooter then
					SetLootMethod("master", UnitName("player"))
				end
			end
		end

		-- Remove invite status
		inviteStatusList[playerName] = nil
	elseif string.find(msg, string.gsub(ERR_RAID_MEMBER_ADDED_S, "%%s", "%%S+")) then -- Player joined raid group
		local playerName = string.match(msg, string.gsub(ERR_RAID_MEMBER_ADDED_S, "%%s", "(%%S+)"))
		RIC_Durability_Manager.setPlayerWarning(playerName) -- Set this player to be flagged for durability check soon

		-- Remove invite status
		inviteStatusList[playerName] = nil
	elseif string.find(msg, string.gsub(ERR_LEFT_GROUP_S, "%%s", "%%S+")) then -- Player left group
		local playerName = string.match(msg, string.gsub(ERR_LEFT_GROUP_S, "%%s", "(%%S+)"))
		-- Set invite status
		inviteStatusList[playerName] = RIC_InviteStatus["NOT_INVITED"]
		inviteTimeList[playerName] = time() -- Act as if we just tried to invite him, to prevent from instant re-invite
	elseif string.find(msg, string.gsub(ERR_RAID_MEMBER_REMOVED_S, "%%s", "%%S+")) then -- Player left raid group
		local playerName = string.match(msg, string.gsub(ERR_RAID_MEMBER_REMOVED_S, "%%s", "(%%S+)"))
		-- Set invite status
		inviteStatusList[playerName] = RIC_InviteStatus["NOT_INVITED"]
		inviteTimeList[playerName] = time() -- Act as if we just tried to invite him, to prevent from instant re-invite
	elseif string.find(msg, string.gsub(ERR_INVITE_PLAYER_S, "%%s", "%%S+")) then -- sent Valid Invitation
		local playerName = string.match(msg, string.gsub(ERR_INVITE_PLAYER_S, "%%s", "(%%S+)"))
		-- Set invite status
		inviteStatusList[playerName] = RIC_InviteStatus["INVITE_PENDING"]
		-- dont need to do anything else - we assume its valid except if we get an error. time was already set when we triggered the invite
	elseif string.find(msg, string.gsub(ERR_BAD_PLAYER_NAME_S, "%%s", "%%S+")) then -- Player was not online
		local playerName = string.match(msg, string.gsub(ERR_BAD_PLAYER_NAME_S, "%%s", "(%%S+)"))
		-- Set invite status
		inviteStatusList[playerName] = RIC_InviteStatus["INVITE_FAILED"]
	elseif string.find(msg, string.gsub(ERR_DECLINE_GROUP_S, "%%s", "%%S+")) then -- Player declined invitation
		local playerName = string.match(msg, string.gsub(ERR_DECLINE_GROUP_S, "%%s", "(%%S+)"))
		-- Set invite status
		inviteStatusList[playerName] = RIC_InviteStatus["INVITE_FAILED"]
	elseif string.find(msg, ERR_LEFT_GROUP_YOU) or string.find(msg, ERR_RAID_YOU_LEFT) then -- You left group/raid - reset state
		inviteStatusList = {}
		inviteTimeList = {}
		RIC_Roster_Browser.endInvitePhase()
	end

	-- Update roster table
	RIC_Roster_Browser.buildRosterRaidList()
end

function RIC_Roster_Browser.toggleInvitePhase()
	if invitePhaseActive then
		RIC_Roster_Browser:endInvitePhase()
	else
		RIC_Roster_Browser:startInvitePhase()
	end
end

function RIC_Roster_Browser.startInvitePhase()
	local raidMembers = getRaidMembers()
	if not invitePhaseActive then -- Check if invite phase was disabled before, otherwise do nothing
		if ((hashLength(raidMembers)==0) or UnitIsGroupLeader("player")) then -- CHeck that we are alone or a raid/group leader
			-- Reset variables that remember who was invited/declined invite etc
			inviteStatusList = {}

			-- Change text of button
			_G["RIC_SendMassInvites".."Text"]:SetText("Stop invites")

			-- Notify via guild message
			if RIC_NotifyInvitePhaseStart then
				SendChatMessageRIC("INVITING NOW - If you are registered for the raid, please leave your groups now and standby!" ,"GUILD" ,nil ,nil)
			end

			-- Notify codewords via guild
			RIC_Codewords_Handler.startInvitePhase()

			-- Check gear durability of our own character - since we otherwise only check people joining our group/raid
			if RIC_Durability_Warning then
				RIC_Durability_Manager.setPlayerWarning(GetUnitName("player", false))
			end

			invitePhaseActive = true
		else
			-- We cannot activate invite phase because we are already in a group, but not leading it - give error message
			message("You can only start the invite phase when alone or as a group or raid leader!")
		end
	end
end

function RIC_Roster_Browser.endInvitePhase()
	if invitePhaseActive then
		-- Change text of button
		_G["RIC_SendMassInvites".."Text"]:SetText("Start invites")

		-- Notify via guild message
		if RIC_NotifyInvitePhaseEnd then
			SendChatMessageRIC("Invite phase for raid ended!" ,"GUILD", nil ,nil)
		end

		-- Notify codewords via guild
		RIC_Codewords_Handler.endInvitePhase()

		invitePhaseActive = false
	end
end

function RIC_Roster_Browser.SystemFilter(chatFrame, event, message)
	return true
end

-- Adds people selected in roster browser (raid members) to roster, or if none selected, opens pop up menu to accept a typed player name
function RIC_Roster_Browser.addSelectedToRoster()
	if hashLength(selectedList) == 0 then -- Nothing selected - open up dialog window to enter custom name
		-- Show player entry popup window
		StaticPopup_Show("ROSTER_PLAYER_ENTRY")
	else -- Add selected people to roster. Some might already be in the roster, but that's fine
		for name,present in pairs(selectedList) do
			RIC_RosterList[name] = 1
		end
	end

	-- Remove selection
	selectedList = {}

	-- Update list
	RIC_Roster_Browser.buildRosterRaidList()
end

function RIC_Roster_Browser.addNameToRoster(name)
	-- If name is empty, do nothing
	local trimmed_name = trim_name(name)
	if string.utf8len(trimmed_name) > 2 then -- Char names must have at least 3 characters in WoW
		-- Add to roster list
		RIC_RosterList[trimmed_name] = 1
		-- Update list
		RIC_Roster_Browser.buildRosterRaidList()
	end
end

-- Remove people from roster selected in roster browser
function RIC_Roster_Browser.removeFromRoster()
	if hashLength(selectedList) > 0 then
		for name,present in pairs(selectedList) do
			RIC_RosterList[name] = nil

			-- Remove invite status info
			inviteStatusList[name] = nil
			inviteTimeList[name] = nil
		end
	end

	-- Reset selection
	selectedList = {}

	-- Update data and view
	RIC_Roster_Browser.buildRosterRaidList()
end

-- Add people that were selected in guild browser (if any)
function RIC_Roster_Browser.addFromGuildBrowser(name)
	-- Check if name is already in roster
	if RIC_RosterList[name] == nil then
		-- Add to roster
		RIC_RosterList[name] = 1
	end
end

function RIC_Roster_Browser.sortClicked(id)
	-- Update how we should be sorting
	if currSortIndex == id then -- if we're already sorting this one
		if sortMethod == "asc" then -- then switch the order
			sortMethod = "desc"
		else
			sortMethod = "asc"
		end
	elseif id then -- if we got a valid id
		currSortIndex = id -- then initialize our sort index
		sortMethod = "asc" -- and the order we're sorting in
	end

	-- Sort Table
	RIC_Roster_Browser.sortTable(currSortIndex)

	-- Update listing
	RIC_Roster_Browser.updateListing()
end

-- Function: sortTable
-- Input: Column Header to sort by
-- Purpose: Sorts the guild member listing table
--		so that it's easily viewable
function RIC_Roster_Browser.sortTable(id)
	if (id == 1) then -- Char Name sorting (alphabetically)
		table.sort(rosterRaidList, function(v1, v2)
			if sortMethod == "desc" then
				return v1 and v1[1] > v2[1]
			else
				return v1 and v1[1] < v2[1]
			end
		end)
	elseif (id == 2) then -- Guild Rank sorting (numerically)
		table.sort(rosterRaidList, function(v1, v2)
			if sortMethod == "desc" then
				return v1 and v1[4] > v2[4]
			else
				return v1 and v1[4] < v2[4]
			end
		end)
	elseif (id == 3) then -- Selected sorting
		table.sort(rosterRaidList, function(v1, v2)
				if v1 == nil then return false end
				if v2 == nil then return true end
				if sortMethod == "asc" then
					return ((selectedList[v1[1]] ~= nil) and (selectedList[v2[1]] == nil))
				else
					return ((selectedList[v2[1]] ~= nil) and (selectedList[v1[1]] == nil))
				end
		end)
	elseif (id == 4) then -- Status sorting
				table.sort(rosterRaidList, function(v1, v2)
			if sortMethod == "desc" then
				return v1 and v1[5] > v2[5]
			else
				return v1 and v1[5] < v2[5]
			end
		end)
	end
end
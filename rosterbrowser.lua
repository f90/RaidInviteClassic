local addonName, RIC = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local sortMethod = "asc"
local currSortIndex = 1
local rosterOffset = 0

local rosterRaidList = {} -- Raid+roster list
local inRaid = {} -- currently in raid
local rosterRaidListVisible = {} -- Subset of rosterRaidList people that we actually want to show in the table atm
local selectedList = {}

-- Invite handling
local invitePhaseActive = false
local invitePhaseStartTime = nil
local inviteStatusList = {}
local inviteStatusInfoList = {}
local inviteTimeList = {}

-- Tooltip handling
local classFreq = {}
local tooltipRow = nil
local tooltipActive = false

function RIC._Roster_Browser.buildRosterRaidList()
	-- Get current guild info
	-- Checks guild member list for people who JUST came online.
	-- In that case, set their invite status to NOT_INVITED since they cannot have a pending invitation,
	-- and a failed invitation earlier (e.g. because they were offline) does not matter anymore.
	-- This leads to faster invites for people who come online

	local guildMembers = RIC._Guild_Manager.getGuildMembers()
	for name,data in pairs(guildMembers) do
		if data["justCameOnline"] == true then
			-- This player just came online - reset their invite status!
			inviteStatusList[name] = RIC.InviteStatus["NOT_INVITED"]
			inviteStatusInfoList[name] = {time(), RIC.db.profile.Lp["Guild_Member_Came_Online"]}
			inviteTimeList[name] = nil -- Doesn't matter when we last invited that person since they just logged in
			RIC._Guild_Manager.resetCameOnlineFlag(name)
		end
		if data["justWentOffline"] == true then
			-- This player just went offline - update status information
			inviteStatusInfoList[name] = {time(), RIC.db.profile.Lp["Guild_Member_Went_Offline"]}
			RIC._Guild_Manager.resetWentOfflineFlag(name)
		end
	end

	-- Go through all raid members, add them to overall list if they are not in roster list
	wipe(rosterRaidList)
	wipe(inRaid)
	local raidMembers = RIC.getRaidMembers()
	for name, data in pairs(raidMembers) do
		-- Check guild rank of raid member (if in guild?)
		local guildRank = "<Not in Guild>"
		local guildRankIndex = 0
		if guildMembers[name] ~= nil then
			guildRank = guildMembers[name]["rank"]
			guildRankIndex = guildMembers[name]["rankIndex"]
		end

		inRaid[name] = 1

		table.insert(rosterRaidList, {
			name=name,
			classFileName=data["classFileName"],
			class=data["class"],
			guildRank=guildRank,
			guildRankIndex=guildRankIndex,
			status=RIC.getStatusSymbol(true, (RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster][name] ~= nil), data["online"], inviteStatusList[name])
		})
	end

	-- Add all people on RosterList to the overall list, if they are not in raid. If possible, check their data in guild
	for name,_ in pairs(RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster]) do
		if inRaid[name] == nil then -- Only process people NOT in raid right now
			if guildMembers[name] == nil then -- Person is not in guild
				-- Check if we remember the classFileName from our database of chars!
				local clsFilename = "UNKNOWN_CLASS"
				local class = "Unknown"
				local clsIndex = RIC.db.realm.KnownPlayerClasses[name]
				if clsIndex ~= nil then -- Found player in database - set class info
					clsFilename = RIC.indexToClassFilename(clsIndex)
					class = RIC.indexToClassname(clsIndex)
				end

				table.insert(rosterRaidList, {
					name=name,
					classFileName=clsFilename,
					class=class,
					guildRank="<Not in Guild>",
					guildRankIndex=0, -- Rank 0 for non-guildies
					status=RIC.getStatusSymbol(false, true, nil, inviteStatusList[name]) -- We dont know online status of non-raid non-guild members
				})
			else -- Person IS in guild
				table.insert(rosterRaidList, {
					name=name,
					classFileName=guildMembers[name]["classFileName"],
					class=guildMembers[name]["class"],
					guildRank=guildMembers[name]["rank"],
					guildRankIndex=guildMembers[name]["rankIndex"],
					status=RIC.getStatusSymbol(false, true, guildMembers[name]["online"], inviteStatusList[name])
				})
			end
		end
	end

	-- Subset of rosterRaidList that we actually want to display (status filters)
	wipe(rosterRaidListVisible)
	for _, data in ipairs(rosterRaidList) do
		if RIC._Roster_Browser.showStatusSymbol(data.status) == true then
			table.insert(rosterRaidListVisible, data)
		end
	end

	-- Clear selection from people who are not shown in rosterRaidListVisible
	for name, selected in pairs(selectedList) do
		local found = false
		for _, val in pairs(rosterRaidListVisible) do
			if name == val.name then
				found = true
				break
			end
		end
		if not found then
			selectedList[name] = nil
		end
	end

	-- Show current roster size as text
	_G["RIC_RosterNumberText"]:SetText("Roster: " .. RIC.tabLength(RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster]))

	-- Sort according to current sorting index
	RIC._Roster_Browser.sortTable(rosterRaidListVisible, currSortIndex)

	-- Display entries
	RIC._Roster_Browser.drawTable()
end

-- Function: drawTable
-- Purpose: Displays the data for the scrolling table
function RIC._Roster_Browser.drawTable()
	-- Set up table sliders
	if #rosterRaidListVisible > 20 then
		local newVal = #rosterRaidListVisible-20
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

	for ci = 1, 20 do
		local row = rosterRaidListVisible[ci+rosterOffset]
		if row then
			_G["RIC_RosterFrameEntry"..ci.."Name"]:SetText(RIC.getClassColor(row.classFileName) .. RIC.displayName(row.name))
			_G["RIC_RosterFrameEntry"..ci.."Rank"]:SetText(row.guildRank)
			_G["RIC_RosterFrameEntry"..ci]:Show()
			if selectedList[row.name] and selectedList[row.name] == 1 then
				_G["RIC_RosterFrameEntry"..ci.."Check"]:Show()
			else
				_G["RIC_RosterFrameEntry"..ci.."Check"]:Hide()
			end

			local texturePath = RIC.getStatusSymbolImagePath(row.status)
			if texturePath ~= nil then
				_G["RIC_RosterFrameEntry"..ci.."Status"]:SetTexture(texturePath)
			else
				_G["RIC_RosterFrameEntry"..ci.."Status"]:SetTexture("Interface\\AddOns\\RaidInviteClassic\\img\\question_mark")
				RIC:Print("ERROR: Could not find a status symbol for " .. row.name)
			end

		else
			_G["RIC_RosterFrameEntry"..ci]:Hide()
		end
	end

	-- Enable/disable remove button based on selection
	_G["RIC_RemoveFromRoster"]:SetEnabled(RIC.tabLength(selectedList) > 0)
end

function RIC._Roster_Browser.showStatusSymbol(status)
	-- Check if the given status should currently be shown in the roster browser
	if status == RIC.Status["READY"] then
		return _G["RIC_ReadyBox"]:GetChecked()
	elseif status == RIC.Status["EXTRA"] then
		return _G["RIC_ExtraBox"]:GetChecked()
	elseif status == RIC.Status["NOT_INVITED"] then
		return _G["RIC_NotInvitedBox"]:GetChecked()
	elseif status == RIC.Status["INVITE_PENDING"] then
		return _G["RIC_InvitePendingBox"]:GetChecked()
	elseif status == RIC.Status["INVITE_FAILED"] then
		return _G["RIC_InviteFailedBox"]:GetChecked()
	elseif status == RIC.Status["MISSING"] then
		return _G["RIC_MissingBox"]:GetChecked()
	elseif status == RIC.Status["OTHER"] then
		return _G["RIC_OtherBox"]:GetChecked()
	end
end

function RIC._Roster_Browser.updateOffset(val)
	-- Activates when slider is dragged, gives continuous value -> change to integer
	rosterOffset = math.floor(val)
	RIC._Roster_Browser.drawTable()
end

function RIC._Roster_Browser.clearSelection()
	wipe(selectedList)
	RIC._Roster_Browser.drawTable()
end

function RIC._Roster_Browser.selectAll()
	wipe(selectedList)
	for _, val in ipairs(rosterRaidListVisible) do
		selectedList[val.name] = 1
	end
	RIC._Roster_Browser.drawTable()
end

function RIC._Roster_Browser.selectRow(rowNum)
	local theRow = rosterRaidListVisible[rowNum+rosterOffset]
	if theRow then
		local theName = theRow.name
		if theName then
			if selectedList[theName] ~= nil then
				selectedList[theName] = nil
			else
				selectedList[theName] = 1
			end
		end
	end

	RIC._Roster_Browser.drawTable()
end

function RIC._Roster_Browser.sliderButtonPushed(dir)
	local currValue = math.floor(_G["RIC_RosterSlider"]:GetValue())
	local newVal
	if (dir == 1) and currValue > 0 then
		newVal = currValue-3
		if newVal < 0 then
			newVal = 0
		end
		_G["RIC_RosterSlider"]:SetValue(newVal)
	elseif (dir == 2) and (currValue < (#rosterRaidListVisible-20)) then
		newVal = currValue+3
		if newVal > (#rosterRaidListVisible-20) then
			newVal = (#rosterRaidListVisible-20)
		end
		_G["RIC_RosterSlider"]:SetValue(newVal)
	end
end

function RIC._Roster_Browser.quickScroll(self, delta)
	local currValue = math.floor(_G["RIC_RosterSlider"]:GetValue())
	local newVal
	if (delta > 0) and currValue > 0 then
		newVal = currValue-1
		if newVal < 0 then
			newVal = 0
		end
		_G["RIC_RosterSlider"]:SetValue(newVal)
	elseif (delta < 0) and (currValue < (#rosterRaidListVisible-20)) then
		newVal = currValue+1
		if newVal > (#rosterRaidListVisible-20) then
			newVal = (#rosterRaidListVisible-20)
		end
		_G["RIC_RosterSlider"]:SetValue(newVal)
	end
end

function RIC._Roster_Browser.sendInvites()
	if invitePhaseActive and (time() - invitePhaseStartTime > RIC.db.profile.InviteDelay) then
		local raidMembers = RIC.getRaidMembers()
		local guildMembers = RIC._Guild_Manager.getGuildMembers() -- Retrieve this so invite function can check if people are online

		-- Go through roster list, invite players not yet in raid, update invite status
		for name, groupPos in pairs(RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster]) do
			-- Check if already in raid group
			if raidMembers[name] == nil then
				local status = inviteStatusList[name]
				-- If not in raid group, check if we already invited that person or not
				if status == nil or status == RIC.InviteStatus["NOT_INVITED"] or status == RIC.InviteStatus["INVITE_FAILED"] then
					-- Not invited before, or person left the group, or last invite failed
					-- -> Check if its time to reinvite based on InviteInterval and whether we invite ungrouped players
					local inviteCheck = (inviteTimeList[name] == nil) -- Definitely invite if not invited before
					inviteCheck = inviteCheck or (RIC.db.profile.InviteIntervalActive and ((time() - inviteTimeList[name]) > RIC.db.profile.InviteInterval)) -- Invite if last invite was too long ago
					inviteCheck = inviteCheck and (RIC.db.profile.InviteUngrouped or (groupPos > 0)) -- If we don't invite ungrouped players, definitely don't invite those
					if inviteCheck then
						-- Person was never invited, or last invite was too long ago - invite!
						RIC._Roster_Browser.invite(name, false, guildMembers)
					end
				elseif status == RIC.InviteStatus["INVITE_PENDING"] then
					-- Check for how long invite was pending, if its too long set to failed
					if (time() - inviteTimeList[name]) > 61 then -- After 60s, invite expires when not accepted or declined, so invite failed
						inviteStatusList[name] = RIC.InviteStatus["INVITE_FAILED"]
						inviteStatusInfoList[name] = {time(), RIC.db.profile.Lp["Invite_Failed_Expired"]}
					end
				end
			end
		end
	end
end

-- Check whether author of invite whisper has the sufficient rights for us to invite them, otherwise give out errors
function RIC._Roster_Browser.checkInviteWhisperRights(author)
	local guildMembers = RIC._Guild_Manager.getGuildMembers()
	-- If player is on whitelist, skip ALL permission checks
	if RIC.db.realm.Whitelist[author] == true then
		return true
	end

	-- Event if message has sth like "invite" in it, probably unrelated message if we are currently completely alone (e.g. "invite person X to the guild please")
	-- => Ignore request if we are alone. Also prevents people from pushing you into a group when you dont want to
	if ((not IsInGroup()) and (not IsInRaid())) and
			((not invitePhaseActive) and RIC.db.profile.CodewordOnlyInGroup) then
		RIC:Print("A codeword whisper by " .. author .. " was ignored because you were alone.")
		PlaySound(846)
		return false
	end

	-- Check if we are currently allowing invite requests
	if RIC.db.profile.CodewordOnlyDuringInvite and (not invitePhaseActive) then
		RIC.SendChatMessage(RIC.db.profile.Lp["Codewords_Invite_Phase"], "WHISPER", nil, author)
		return false
	end

	-- Check if author is NOT on blacklist, otherwise deny request
	if RIC.db.realm.Blacklist[author] == true then
		RIC:Print("A codeword whisper by " .. author .. " was ignored because they are on your blacklist.")
		PlaySound(846)
		return false
	end

	-- Check if author is in rosterList
	if RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster][author] == nil then
		if RIC.db.profile.RosterWhispersOnly then
			-- Author is not in roster and we want to only invite roster players -> deny request
			RIC.SendChatMessage(RIC.db.profile.Lp["Codewords_Not_In_Roster"], "WHISPER", nil, author)
			return false
		end
	else
		-- Author is in roster - accept and do not do any FURTHER permission checks such as guild membership!
		return true
	end

	-- ONLY NON-ROSTER, NON-WHITELISTED PLAYERS ARE CHECKED WITH THE CODE BELOW FOR FURTHER REQUIREMENTS

	-- Check if person is guild member
	if RIC.db.profile.GuildWhispersOnly and (guildMembers[author] == nil) then
		RIC.SendChatMessage(RIC.db.profile.Lp["Codewords_Not_In_Guild"], "WHISPER", nil, author)
		return false
	end

	-- No requirement was violated nor any blanket allow was triggered -> by default send out invite
	return true
end

-- Process an invite request whisper from one particular person
function RIC._Roster_Browser.processInviteWhisper(author, msg)
	-- Check if message is an invite request, otherwise ignore
	if (not RIC._Codewords_Handler.isInviteWhisper(msg)) then
		return
	end

	if RIC._Roster_Browser.checkInviteWhisperRights(author) then
		-- So far, all conditions met - try to invite person
		RIC._Roster_Browser.invite(author, true, guildMembers)
	end
end

-- Invites one particular person
function RIC._Roster_Browser.invite(person, reactive, guildMembers)
	-- Check if person is the character you are playing right now
	if person == RIC.getUnitFullName("player") then
		return
	end

	-- Check if person already in raid
	local raidMembers = RIC.getRaidMembers()
	if raidMembers[person] ~= nil then
		if reactive then -- If we invite based on whisper, tell player he is already in the raid!
			RIC.SendChatMessage(RIC.db.profile.Lp["Codewords_Already_In_Raid"], "WHISPER", nil, person)
		end
		return
	end

	-- Check if raid full
	if RIC.tabLength(raidMembers) >= MAX_RAID_MEMBERS then
		if reactive then
			-- React to whisper that the raid is full, but dont change any invite status
			RIC.SendChatMessage(RIC.db.profile.Lp["Codewords_Raid_Full"], "WHISPER", nil, person)
			inviteStatusInfoList[person] = {time(), RIC.db.profile.Lp["Invite_Whisper_Failed_Raid_Full"]}
		else
			-- Our invite failed because the raid was full - dont try again for now
			inviteStatusList[person] = RIC.InviteStatus["INVITE_FAILED"]
			inviteStatusInfoList[person] = {time(), RIC.db.profile.Lp["Invite_Failed_Raid_Full"]}
			inviteTimeList[person] = time()
		end
		return
	end

	-- Check if this is a guild member but offline - in this case we don't even need to try an invite, since this clogs up the chat with invite error messages :)
	if not reactive then -- If reacting to invite request, the player is definitely online!
		guildMembers = guildMembers or RIC._Guild_Manager.getGuildMembers() -- Retrieve guild member list if not given to us as argument
		if (guildMembers[person] ~= nil) and (not guildMembers[person]["online"]) then
			-- Invite for this person will fail because they are offline - dont invite, instead record invite attempt time and set to failed invite status
			inviteStatusList[person] = RIC.InviteStatus["INVITE_FAILED"]
			inviteStatusInfoList[person] = {time(), RIC.db.profile.Lp["Invite_Skipped_Not_Online"]}
			inviteTimeList[person] = time()
			return
		end
	end

	-- Check if we have assist or lead in raid so we can actually invite someone (or we are alone at the moment)
	if (RIC.tabLength(raidMembers)==0) or (UnitIsGroupAssistant("player") or UnitIsGroupLeader("player")) then
		-- Either this is a reactive invite, so it's fine. It cannot be an active invite unless the raid leader does it, so thats also fine.
		-- Now check if we are still in group/alone (not RAID) and have to delay some invitations because too many are pending!
		local num_possible_invites_in_group = 5 - RIC.tabLength(raidMembers)
		if RIC.tabLength(raidMembers) == 0 then
			num_possible_invites_in_group = 4 -- If we didnt open a group, raidMembers is empty. But only 4 invites possible (us excluded)
		end
		-- If we are in raid - invite. If not, check if we have some slots in group leftover to invite people into
		if IsInRaid() or ((num_possible_invites_in_group - RIC.countFrequency(inviteStatusList, RIC.InviteStatus["INVITE_PENDING"])) > 0) then
			InviteUnit(person)
			inviteStatusList[person] = RIC.InviteStatus["INVITE_PENDING"]
			inviteStatusInfoList[person] = {time(), RIC.db.profile.Lp["Invite_Pending"]}
			inviteTimeList[person] = time()
		else
			-- Only reason we did not invite this person now is because our group doesnt allow more invites right now
			-- Try in a few secs again, so pretend we never tried to invite in the first place
			inviteStatusList[person] = RIC.InviteStatus["NOT_INVITED"]
			inviteStatusInfoList[person] = {time(), RIC.db.profile.Lp["Not_Invited_Converting_Raid"]}
			inviteTimeList[person] = nil
		end
	else
		-- If we react to whisper, tell the person we cant invite them
		if reactive then
			RIC.SendChatMessage(RIC.db.profile.Lp["Codewords_Invite_Rights"], "WHISPER", nil, person)
		end
	end
end

function RIC._Roster_Browser.parseNameFromSystemMessage(msg, systemEvent)
	-- Assuming the chat message stems from the system and therefore has a standard wording,
	-- try to extract the character name involved. If parsing fails since this message does not fit a system one, return nil
	local playerName = string.find(msg, string.gsub(systemEvent, "%%s", "(%%S+)"))
	if playerName then
		-- Parse and process player name
		playerName = string.match(msg, string.gsub(systemEvent, "%%s", "(%%S+)"))
		playerName = RIC.addServerToName(playerName)
	end
	return playerName
end

function RIC._Roster_Browser.processSystemMessage(msg)
	if RIC._Roster_Browser.parseNameFromSystemMessage(msg, ERR_ALREADY_IN_GROUP_S) then -- This person is already in a group
		local playerName = RIC._Roster_Browser.parseNameFromSystemMessage(msg, ERR_ALREADY_IN_GROUP_S)
		-- Check if player is already in raid. In that case, we accidentally tried to invite that player MANUALLY -> Ignore this message
		local raidMembers = RIC.getRaidMembers()
		if raidMembers[playerName] == nil then
			-- Set invite status
			inviteStatusList[playerName] = RIC.InviteStatus["INVITE_FAILED"]
			inviteStatusInfoList[playerName] = {time(), RIC.db.profile.Lp["Invite_Failed_Already_In_Group"]}
			inviteTimeList[playerName] = time() -- We sent the invite just now, so save current time as last time we attempted invite
			if invitePhaseActive then -- Only notify if we are in the invite phase
				RIC.SendChatMessage(RIC.db.profile.Lp["Already_In_Group"], "WHISPER", nil, playerName)
			end
		end
	elseif RIC._Roster_Browser.parseNameFromSystemMessage(msg, ERR_JOINED_GROUP_S) then -- Player joined group
		local playerName = RIC._Roster_Browser.parseNameFromSystemMessage(msg, ERR_JOINED_GROUP_S)
		RIC._Durability_Manager.setPlayerWarning(playerName) -- Set this player to be flagged for durability check soon
		if invitePhaseActive then
			-- Convert to raid group if group exists and has at least two members
			local raidMembers = RIC.getRaidMembers()
			if RIC.tabLength(raidMembers) >= 2 then
				ConvertToRaid()

				-- Set master looter
				if RIC.db.profile.MasterLooter then
					-- For some reason, SetLootMethod wants to have just the character name (e.g. Tim), not the server name (Tim-Patchwerk), so remove server name from full name
					SetLootMethod("master", RIC.removeServerFromName(RIC.getUnitFullName("player")))
				end
			end
		end

		-- Update invite status
		inviteStatusList[playerName] = nil
		inviteStatusInfoList[playerName] = {time(), RIC.db.profile.Lp["Player_Joined"]}
	elseif RIC._Roster_Browser.parseNameFromSystemMessage(msg, ERR_RAID_MEMBER_ADDED_S) then -- Player joined raid group
		local playerName = RIC._Roster_Browser.parseNameFromSystemMessage(msg, ERR_RAID_MEMBER_ADDED_S)
		RIC._Durability_Manager.setPlayerWarning(playerName) -- Set this player to be flagged for durability check soon

		-- Update invite status
		inviteStatusList[playerName] = nil
		inviteStatusInfoList[playerName] = {time(), RIC.db.profile.Lp["Player_Joined"]}
	elseif RIC._Roster_Browser.parseNameFromSystemMessage(msg, ERR_LEFT_GROUP_S) then -- Player left group
		local playerName = RIC._Roster_Browser.parseNameFromSystemMessage(msg, ERR_LEFT_GROUP_S)
		-- Set invite status
		inviteStatusList[playerName] = RIC.InviteStatus["NOT_INVITED"]
		inviteStatusInfoList[playerName] = {time(), RIC.db.profile.Lp["Player_Left"]}
		inviteTimeList[playerName] = time() -- Act as if we just tried to invite him, to prevent from instant re-invite
	elseif RIC._Roster_Browser.parseNameFromSystemMessage(msg, ERR_RAID_MEMBER_REMOVED_S) then -- Player left raid group
		local playerName = RIC._Roster_Browser.parseNameFromSystemMessage(msg, ERR_RAID_MEMBER_REMOVED_S)
		-- Set invite status
		inviteStatusList[playerName] = RIC.InviteStatus["NOT_INVITED"]
		inviteStatusInfoList[playerName] = {time(), RIC.db.profile.Lp["Player_Left"]}
		inviteTimeList[playerName] = time() -- Act as if we just tried to invite him, to prevent from instant re-invite
	elseif RIC._Roster_Browser.parseNameFromSystemMessage(msg, ERR_INVITE_PLAYER_S) then -- sent Valid Invitation
		local playerName = RIC._Roster_Browser.parseNameFromSystemMessage(msg, ERR_INVITE_PLAYER_S)
		-- Set invite status
		inviteStatusList[playerName] = RIC.InviteStatus["INVITE_PENDING"]
		inviteStatusInfoList[playerName] = {time(), RIC.db.profile.Lp["Invite_Pending"]}
		-- dont need to do anything else - we assume its valid except if we get an error. time was already set when we triggered the invite
	elseif RIC._Roster_Browser.parseNameFromSystemMessage(msg, ERR_BAD_PLAYER_NAME_S) then -- Player was not online
		local playerName = RIC._Roster_Browser.parseNameFromSystemMessage(msg, ERR_BAD_PLAYER_NAME_S)
		-- Set invite status
		inviteStatusList[playerName] = RIC.InviteStatus["INVITE_FAILED"]
		inviteStatusInfoList[playerName] = {time(), RIC.db.profile.Lp["Invite_Failed_Not_Online"]}
	elseif RIC._Roster_Browser.parseNameFromSystemMessage(msg, ERR_DECLINE_GROUP_S) then -- Player declined invitation
		local playerName = RIC._Roster_Browser.parseNameFromSystemMessage(msg, ERR_DECLINE_GROUP_S)
		inviteStatusList[playerName] = RIC.InviteStatus["INVITE_FAILED"]
		-- Check the invite time. If its about 60s ago, we assume the invite expired, otherwise it was declined
		if inviteTimeList[playerName] and (time() - inviteTimeList[playerName] >= 59) then
			inviteStatusInfoList[playerName] = {time(), RIC.db.profile.Lp["Invite_Failed_Expired"]}
		else
			inviteStatusInfoList[playerName] = {time(), RIC.db.profile.Lp["Invite_Failed_Declined"]}
		end
	elseif string.find(msg, ERR_LEFT_GROUP_YOU) or string.find(msg, ERR_RAID_YOU_LEFT) then -- You left group/raid - reset state
		wipe(inviteStatusList)
		wipe(inviteStatusInfoList)
		wipe(inviteTimeList)
		RIC._Roster_Browser.endInvitePhase()
	end

	-- Update roster table
	RIC._Roster_Browser.buildRosterRaidList()
end

function RIC._Roster_Browser.isInvitePhaseActive()
	return invitePhaseActive
end

function RIC._Roster_Browser.toggleInvitePhase()
	if invitePhaseActive then
		RIC._Roster_Browser:endInvitePhase()
	else
		RIC._Roster_Browser:startInvitePhase()
	end
end

function RIC._Roster_Browser.startInvitePhase()
	local raidMembers = RIC.getRaidMembers()
	if not invitePhaseActive then -- Check if invite phase was disabled before, otherwise do nothing
		if ((RIC.tabLength(raidMembers)==0) or UnitIsGroupLeader("player")) then -- CHeck that we are alone or a raid/group leader
			-- START INVITE PHASE

			-- Reset variables that remember who was invited/declined invite and when
			wipe(inviteStatusList)
			wipe(inviteTimeList)

			invitePhaseActive = true
			invitePhaseStartTime = time()

			-- Change text of button
			_G["RIC_SendMassInvites".."Text"]:SetText("Stop invites")

			-- Change minimap icon
			RIC.minimapIcon:IconCallback(nil, addonName, "icon", "Interface\\AddOns\\RaidInviteClassic\\img\\minimap_dots")

			-- Notify via guild message
			if RIC.db.profile.NotifyInvitePhaseStart then
				RIC.SendChatMessage(RIC.db.profile.Lp["Invite_Start"] ,"GUILD" ,nil ,nil)
			end

			-- Notify codewords via guild
			RIC._Codewords_Handler.startInvitePhase()

			-- Check gear durability of our own character - since we otherwise only check people joining our group/raid
			RIC._Durability_Manager.setPlayerWarning(RIC.getUnitFullName("player"))
		else
			-- We cannot activate invite phase because we are already in a group, but not leading it - give error message
			message("You can only start the invite phase when alone or as a group or raid leader!")
		end
	end
end

function RIC._Roster_Browser.endInvitePhase()
	if invitePhaseActive then
		-- Change text of button
		_G["RIC_SendMassInvites".."Text"]:SetText("Start invites")

		-- Change minimap icon
		RIC.minimapIcon:IconCallback(nil, addonName, "icon", "Interface\\AddOns\\RaidInviteClassic\\img\\minimap")

		-- Notify via guild message
		if RIC.db.profile.NotifyInvitePhaseEnd then
			RIC.SendChatMessage(RIC.db.profile.Lp["Invite_End"] ,"GUILD", nil ,nil)
		end

		-- Notify codewords via guild
		RIC._Codewords_Handler.endInvitePhase()

		invitePhaseActive = false
	end
end

function RIC._Roster_Browser.showPlayerTooltip(rowElement, rowNum)
	GameTooltip:SetOwner(rowElement, "ANCHOR_RIGHT")
	local theRow = rosterRaidListVisible[rowNum+rosterOffset]
	if theRow then
		local theName = theRow.name
		if theName then
			tooltipRow = rowNum
			tooltipActive = true
		end
	end
	RIC._Roster_Browser.setPlayerTooltip()
end

function RIC._Roster_Browser.setPlayerTooltip()
	if not tooltipActive then
		return
	end

	local theRow = rosterRaidListVisible[tooltipRow+rosterOffset]
	if theRow then
		local theName = theRow.name
		if theName then
			-- Get online status of player
			local online = "Unknown"
			local raidMembers = RIC.getRaidMembers()
			if raidMembers[theName] ~= nil then
				if raidMembers[theName]["online"] then
					online = "Yes"
				else
					online = "No"
				end
			else
				local guildMembers = RIC._Guild_Manager.getGuildMembers()
				if guildMembers[theName] ~= nil then
					if guildMembers[theName]["online"] then
						online = "Yes"
					else
						online = "No"
					end
				end
			end

			-- Get last event related to player
			local details = inviteStatusInfoList[theName]

			-- Set tooltip
			GameTooltip:ClearLines()
			GameTooltip:AddLine(theName)
			GameTooltip:AddLine("|cFFFFFFFFOnline:|r " .. online)
			if details ~= nil then
				GameTooltip:AddLine("|cFFFFFFFFStatus:|r " .. details[2] .. " (" .. date("%H:%M:%S", details[1]) .. ")") -- Show time and detail of last event
			end
			-- If there was a previous invite attempt, but player still not in raid, show when we plan to try inviting the next time
			if invitePhaseActive and
					RIC.db.profile.InviteIntervalActive and
					inviteTimeList[theName] ~= nil and
					raidMembers[theName] == nil then
				GameTooltip:AddLine("|cFFFFFFFFNext invite attempt in:|r " ..  inviteTimeList[theName]+RIC.db.profile.InviteInterval-time() .. " seconds (" ..
						date("%H:%M:%S", inviteTimeList[theName]+RIC.db.profile.InviteInterval) .. ")")
			end
			GameTooltip:Show()
		end
	end
end

function RIC._Roster_Browser.hidePlayerTooltip(rowNum)
	local theRow = rosterRaidListVisible[rowNum+rosterOffset]
	if theRow then
		local theName = theRow.name
		if theName then
			tooltipRow = nil
			tooltipActive = false
			GameTooltip:Hide()
		end
	end
end

function RIC._Roster_Browser.countClassFrequencies(includeAll)
	wipe(classFreq)
	for i, data in ipairs(rosterRaidList) do
		if (includeAll == true) or (RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster][data.name] ~= nil) then
			if classFreq[data.classFileName] ~= nil then
				classFreq[data.classFileName].freq = classFreq[data.classFileName].freq + 1
			else
				classFreq[data.classFileName] = {freq=1, class=data.class}
			end

			end
		end
	return classFreq
end

function RIC._Roster_Browser.showRosterTooltip()
	-- Set tooltip
	GameTooltip:SetOwner(_G["RIC_RosterDisplay"], "ANCHOR_RIGHT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine("|cFFFFFFFFRoster:|r " .. RIC.db.realm.CurrentRoster)
	-- Show how many of each class we have on roster
	local classFrequencies = RIC._Roster_Browser.countClassFrequencies(false)
	for classFileName, data in RIC.pairsByKeys(classFrequencies) do
		GameTooltip:AddLine(RIC.getClassColor(classFileName) .. data.class .. "|r: " .. tostring(data.freq))
	end
	GameTooltip:Show()
end

function RIC._Roster_Browser.hideRosterTooltip()
	GameTooltip:Hide()
end

function RIC._Roster_Browser.SystemFilter(chatFrame, event, message)
	return true
end

-- Adds people selected in roster browser (raid members) to roster, or if none selected, opens pop up menu to accept a typed player name
function RIC._Roster_Browser.addSelectedToRoster()
	if RIC.tabLength(selectedList) == 0 then -- Nothing selected - open up dialog window to enter custom name
		-- Show player entry popup window
		StaticPopup_Show("ROSTER_PLAYER_ENTRY")
	else -- Add selected people to roster. Some might already be in the roster, but that's fine
		for name,_ in pairs(selectedList) do
			RIC._Roster_Browser.addNameToRoster(name, false)
		end
	end

	-- Remove selection
	wipe(selectedList)

	-- Update list
	RIC._Roster_Browser.buildRosterRaidList()

	-- Redraw group view to reflect change
	RIC._Group_Manager.draw(true)
end

function RIC._Roster_Browser.addNameToRoster(name, update_view)
	-- General function to add a character to the current roster

	-- Preprocess name and check if it's valid format
	local trimmed_name, _ = RIC.normAndCheckName(name)
	if trimmed_name then -- Only non-nil if name is valid
		-- Add to roster list in case this char is not already in it
		if RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster][trimmed_name] == nil then
			RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster][trimmed_name] = 0

			if update_view then -- Optionally update UI if this was requested by the caller
				-- Update list
				RIC._Roster_Browser.buildRosterRaidList()
				-- Redraw group view to reflect change
				RIC._Group_Manager.draw(true)
			end
		end
	end
end

-- Remove person from roster -- WARNING: Does not update any GUI afterwards!
function RIC._Roster_Browser.remove(name)
	RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster][name] = nil

	-- Remove invite status info
	inviteStatusList[name] = nil
	inviteTimeList[name] = nil
end

-- Remove people from roster selected in roster browser
function RIC._Roster_Browser.removeFromRoster()
	if RIC.tabLength(selectedList) > 0 then
		for name,_ in pairs(selectedList) do
			RIC._Roster_Browser.remove(name)
		end
	end

	-- Reset selection
	wipe(selectedList)

	-- Update data and view
	RIC._Roster_Browser.buildRosterRaidList()

	-- Redraw group view to reflect change
	RIC._Group_Manager.draw(true)
end

-- Can be called by other modules to ask for a players class and invite status information
function RIC._Roster_Browser.getPlayerInfo(name)
	for _, data in ipairs(rosterRaidList) do
		if data.name == name then
			return data
		end
	end
	RIC:Print("WARNING: Could not find " .. name .. " in roster raid list!")
	return nil -- Player not found in table, return nothing
end

function RIC._Roster_Browser.sortClicked(id)
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

	-- Sort Tables
	RIC._Roster_Browser.sortTable(rosterRaidList, currSortIndex)
	RIC._Roster_Browser.sortTable(rosterRaidListVisible, currSortIndex)

	-- Update listing
	RIC._Roster_Browser.drawTable()
end

-- Function: sortTable
-- Input: Column Header to sort by
-- Purpose: Sorts the guild member listing table
--		so that it's easily viewable
local name_sorter = function(v1, v2)
	if sortMethod == "desc" then
		return v1 and v1.name > v2.name
	else
		return v1 and v1.name < v2.name
	end
end
local rank_sorter = function(v1, v2)
	if sortMethod == "desc" then
		return v1 and v1.guildRankIndex > v2.guildRankIndex
	else
		return v1 and v1.guildRankIndex < v2.guildRankIndex
	end
end
local selection_sorter = function(v1, v2)
	if v1 == nil then return false end
	if v2 == nil then return true end
	if sortMethod == "asc" then
		return ((selectedList[v1.name] ~= nil) and (selectedList[v2.name] == nil))
	else
		return ((selectedList[v2.name] ~= nil) and (selectedList[v1.name] == nil))
	end
end
local status_sorter = function(v1, v2)
	if sortMethod == "desc" then
		return v1 and v1.status > v2.status
	else
		return v1 and v1.status < v2.status
	end
end
function RIC._Roster_Browser.sortTable(t, id)
	if (id == 1) then -- Char Name sorting (alphabetically)
		table.sort(t, name_sorter)
	elseif (id == 2) then -- Guild Rank sorting (numerically)
		table.sort(t, rank_sorter)
	elseif (id == 3) then -- Selected sorting
		table.sort(t, selection_sorter)
	elseif (id == 4) then -- Status sorting
				table.sort(t, status_sorter)
	end
end
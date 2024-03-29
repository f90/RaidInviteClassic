local addonName, RIC = ...
-- Durability is requested/transmitted when opening the list.
-- This module is a display wrapper for LibDurability.

local LD = LibStub("LibDurability")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local durability = {}
local lastRequest = nil
local playerNeedsCheck = {} -- Set to a certain timestamp if a player needs a durability check/warning at this point

do
	local function processPlayerDurability(percent, broken, name)
		-- Saves durability info received from a player
		-- percent: Number indicating current durability percentage
		-- broken: How many items are completely broken
		-- name: Character name - SOMETIMES has servername attached to it, sometimes not (-> unnormalized)

		-- Normalize name - ALWAYS have "char-server" format.
		local normName, changed = RIC.normAndCheckName(name)
		if changed then -- If name was invalid (e.g. special characters or too short), don't save durability
			-- RIC:Print("WARNING: Received durability info from player " .. " but player name is invalid (would be changed to " .. normName .. ") - Ignoring this info!")
			return
		end

		-- Save durability info in durability table
		durability[normName] = {
			percent=percent,
			broken=broken,
			time=time()
		}
	end
	LD:Register(RIC._Durability_Manager, processPlayerDurability)
end

function RIC._Durability_Manager.checkDurabilities()
	local raidMembers = RIC.getRaidMembers()-- Get current list of raid members
	-- Go through all players that joined and might still need a warning
	for player,_ in pairs(playerNeedsCheck) do
		if raidMembers[player] ~= nil then -- Check if player is in raid. If not - doesn't need warning anymore!
			-- Player is in raid - warn player if necessary
			if (time() - playerNeedsCheck[player]) < 300 then -- Check whether the request to check durability is still new enough
				RIC._Durability_Manager.checkPlayer(player)
			else
				-- Durability request failed after multiple attempts. Give up now. Possible reasons:
				-- a) Player doesnt have addon installed (or DBM or similar that sends gear info)
				-- b) Gear info could not be fetched for some other reason other than a)
				-- c) Player was offline throughout gear check duration
				-- d) We are not in raid and leading it
				-- Give warning message if the reason is a) or b) or c)
				playerNeedsCheck[player] = nil
				if IsInRaid() and UnitIsGroupLeader("player") then -- We ARE the raid leader - so something special must have gone wrong!
					RIC:Print("WARNING: Durability could not be checked for " .. player .. ". Player is offline, doesnt have RIC/DBM installed, or a different LibDurability version.")
				end
			end
		else
			-- Player not in raid - doesnt need warning or durability info anymore - EXCEPT if its ourselves at the start of building the group, then we dont count as "in the raid"
			if player ~= RIC.getUnitFullName("player") then
				playerNeedsCheck[player] = nil
				durability[player] = nil
			end
		end
	end

	 -- Get new durability values for next time
	if lastRequest == nil or time() - lastRequest >= 30 then -- Avoid spamming addon comms with durability check requests constantly
		LD:RequestDurability()
		lastRequest = time()
	end
end

function RIC._Durability_Manager.setPlayerWarning(player)
	-- Normalize name and error out if it's invalid
	local name, changed = RIC.normAndCheckName(player)
	if changed then
		RIC:Print("ERROR: Requested player check for " .. player " but name is invalid (would be changed to " .. name .. ") - Ignoring request!")
		return
	end

	if RIC.db.profile.Durability_Warning and
			((not RIC.db.profile.Durability_Invite_Phase) or RIC._Roster_Browser.isInvitePhaseActive()) then -- Only initiate checks if that is activated in the options
		playerNeedsCheck[name] = time()
	end
end

-- Checks a player for current durability. If it can be retrieved and is too low, warn them (if they were not warned before)
function RIC._Durability_Manager.checkPlayer(player)
	-- Only raid leader is allowed to send durability warnings, so postpone if we are not raid leader
	if (not IsInRaid()) or (not UnitIsGroupLeader("player")) then -- TODO maybe also check durability if just in a group not raid?
		return
	end

	-- If we dont have durability info - cannot fulfil check request - just cancel
	if durability[player] == nil then
		return
	end

	-- If durability info is too outdated - cannot fulfil check request - just cancel
	if (time() - durability[player]["time"]) > 60 then
		return
	end

	-- Check if durability is high enough so we can clear the need-to-warn flag
	if durability[player]["percent"] > RIC.db.profile.Durability_Threshold then
		playerNeedsCheck[player] = nil -- Clear up durability check request time
		return
	end

	-- All conditions met - warn the player now!
	local warningText =  RIC.db.profile.Lp["Gear_Durability_Warning_1"] .. " " .. durability[player]["percent"] .. RIC.db.profile.Lp["Gear_Durability_Warning_2"]
	if player == RIC.getUnitFullName("player") then
		-- We forgot to repair ourselves!
		if UnitAffectingCombat("player") then -- Only show popup when not in combat
			RIC:Print(warningText)
		else
			message(warningText)
		end
	else
		-- This is someone else than us - send a message
		 RIC.SendChatMessage(warningText, "WHISPER", nil, player)
	end
	playerNeedsCheck[player] = nil -- Clear up durability check request time
end
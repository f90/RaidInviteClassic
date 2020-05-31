-- Durability is requested/transmitted when opening the list.
-- This module is a display wrapper for LibDurability.

local LD = LibStub("LibDurability")
local durability = {}
local playersNeedWarning = {} -- Set to a certain timestamp if a player needs a durability check/warning at this point

do
	local function processPlayerDurability(percent, broken, player)
		durability[player] = {
			percent=percent,
			broken=broken,
			time=time()
		}
	end
	LD:Register(RIC_Durability_Manager, processPlayerDurability)
end

function RIC_Durability_Manager.checkDurabilities()
	local raidMembers = getRaidMembers()-- Get current list of raid members
	-- Go through all players that joined and might still need a warning
	for player,_ in pairs(playersNeedWarning) do
		if raidMembers[player] ~= nil then -- Check if player is in raid. If not - doesn't need warning anymore!
			-- Player is in raid - warn player if necessary
			if (time() - playersNeedWarning[player]) < 300 then -- Check whether the request to check durability is still new enough
				RIC_Durability_Manager.warnPlayer(player)
			else
				-- Durability request failed after multiple attempts. Give up now. Possible reasons:
				-- a) Player doesnt have addon installed (or DBM or similar that sends gear info)
				-- b) Gear info could not be fetched for some other reason other than a)
				-- c) Player was offline throughout gear check duration
				-- d) We are not in raid and leading it
				-- Give warning message if the reason is a) or b) or c)
				playersNeedWarning[player] = nil
				if IsInRaid() and UnitIsGroupLeader("player") then -- We ARE the raid leader - so something special must have gone wrong!
					printRIC("WARNING: Durability could not be checked for " .. player .. ". Player is offline or doesnt have RIC/DBM installed?")
				end
			end
		else
			-- Player not in raid - doesnt need warning or durability info anymore - EXCEPT if its ourselves at the start of building the group, then we dont count as "in the raid"
			if player ~= GetUnitName("player", false) then
				playersNeedWarning[player] = nil
				durability[player] = nil
			end
		end
	end

	LD:RequestDurability() -- Get new durability values for next time
end

function RIC_Durability_Manager.setPlayerWarning(player)
	if RIC_Durability_Warning then -- Only initiate checks if that is activated in the options
		playersNeedWarning[player] = time()
	end
end

function RIC_Durability_Manager.setDurabilityThreshold(input)
	local num = tonumber(input)
	if (num ~= nil) and (num >= 0) and (num <= 100) then
		RIC_Durability_Threshold = num
	end
end

-- Checks a player for current durability. If it can be retrieved and is too low, warn them (if they were not warned before)
function RIC_Durability_Manager.warnPlayer(player)
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

	-- Check if durability is low
	if durability[player]["percent"] > RIC_Durability_Threshold then
		playersNeedWarning[player] = nil -- Clear up durability check request time
		return
	end

	-- All conditions met - warn the player now!
	local warningText =  "WARNING: Your gear is at " .. durability[player]["percent"] .. "% durability. Please repair it!"
	if player == GetUnitName("player", false) then
		-- We forgot to repair ourselves!
		if UnitAffectingCombat("player") then -- Only show popup when not in combat
			printRIC(warningText)
		else
			message(warningText)
		end
	else
		-- This is someone else than us - send a message
		 SendChatMessageRIC(warningText, "WHISPER", nil, player)
	end
	playersNeedWarning[player] = nil -- Clear up durability check request time
end
local addonName, RIC = ...
local LD = LibStub("LibDeflate")
local response = {}

function RIC.SendComm(message, channel)
	local messageSerialized = LD:EncodeForWoWAddonChannel(LD:CompressDeflate(RIC:Serialize(message)))
	if channel == nil then
		RIC:SendCommMessage("ricroster", messageSerialized, "RAID")
		RIC:SendCommMessage("ricroster", messageSerialized, "GUILD")
	else
		RIC:SendCommMessage("ricroster", messageSerialized, channel)
	end
end

function RIC:OnCommReceived(prefix, message, distribution, sender)
	if prefix ~= "ricroster" or sender == RIC.getUnitFullName("player") or not message then
		return
	end

	local decoded = LD:DecodeForWoWAddonChannel(message)
	if not decoded then
		RIC:Print("Could not decode addon message. Sender needs to update to the latest version of cleangroupassigns!")
		return
	end
	local decompressed = LD:DecompressDeflate(decoded)
	if not decompressed then
		RIC:Print("Failed to decompress addon message. Sender needs to update to the latest version of cleangroupassigns!")
		return
	end

	local didDeserialize, message = RIC:Deserialize(decompressed)
	if not didDeserialize then
		RIC:Print("Failed to deserialize sync: " .. message)
		return
	end

	local key = message["key"]
	if not key then
		RIC:Print("Failed to parse deserialized comm.")
		return
	end

	if key == "SWAP_IN_PROGRESS" then
		RIC._Group_Manager.receiveInProgress(sender)
		return
	end

	if key == "SWAP_END" then
		RIC._Group_Manager.receiveEndProgress()
		return
	end

	if key == "ASK_ROSTERS" then
		response["key"] = "ROSTERS"
		response["asker"] = sender
		response["value"] = RIC.db.realm.RosterList
		RIC.SendComm(response, distribution)
		return
	end

	if key == "ROSTERS" and message["asker"] == RIC.getUnitFullName("player") and message["value"] then
		RIC._Roster_Manager.addReceivedRosters(message["value"], sender)
		return
	end

	if key == "OVERWRITE_ROSTERS" and message["value"] then
		RIC._Roster_Manager.setReceivedRosters(message["value"], sender) -- TODO maybe ask recipient if he wants to get this update and discard his own data
	end
end
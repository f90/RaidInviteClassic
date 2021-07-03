local addonName, RIC = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- For converting whitelist and blacklist textboxes into player tables
function RIC._Codewords_Handler.buildPlayerList(playerListString)
	local newPlayerList = {}
	if playerListString == nil then
		RIC.print("WARNING: Got fed an invalid player list string - resetting player black/white list!")
		return newPlayerList
	end
	-- Use newlines, colons, comma or space to separate characters
	for playerName in playerListString:gmatch("[^;, \n]+") do
		local p = RIC.trim_char_name(RIC.addServerToName(playerName))
		local char_name, _ = RIC.split_char_name(p)
		if string.utf8len(char_name) > 1 then
			-- Add player
			newPlayerList[p] = true
		end
	end

	return newPlayerList
end

-- For converting whitelist and blacklist player tables into textbox strings
function RIC._Codewords_Handler.getPlayerListString(playerList)
	local playerListString = ""
	if playerList == nil then
		return playerListString
	end

	for playerName, _ in RIC.pairsByKeys(playerList) do
		playerListString = playerListString .. playerName .. "\n"
	end
	return playerListString
end

local newCodewords = {}
function RIC._Codewords_Handler.buildCodeWords(newCodewordString)
	if newCodewordString == nil then
		return newCodewords
	end
	wipe(newCodewords)
	-- Go through codewords, trim them and put into codeword table
	for codeword in newCodewordString:gmatch("[^%s%c%p]+") do
		local c = string.utf8lower(codeword) -- Put to lower case so people realise upper/lower case doesnt matter
		-- Check if line is empty, and addon tag does not contain our codeword to avoid accidental triggers by other addon users
		if (string.utf8len(c) > 0) and (string.find(string.utf8lower(RIC._ChatString), c, 1, true) == nil) then
			-- Add codeword!
			table.insert(newCodewords, c)
		end
	end

	return newCodewords
end

function RIC._Codewords_Handler.getCodeWordsString(codewords)
	local s = ""
	for i, c in ipairs(codewords) do
		s = s .. c
		if i < #codewords then
			s = s .. "\n"
		end
	end
	return s
end

function RIC._Codewords_Handler.startInvitePhase()
	-- Notify guild now, if this is activated in the options
	if RIC.db.profile.CodewordNotifyStart then
		if #RIC.db.profile.Codewords == 0 then
			RIC:Print(RIC.db.profile.Lp["Codewords_Not_Set"])
		else
			local theMsg = RIC.db.profile.Lp["Whisper_Me"]
			for ci=1, (#RIC.db.profile.Codewords - 1) do
				if (ci == 1) then
					theMsg = theMsg .. " \"" .. RIC.db.profile.Codewords[ci] .. "\""
				else
					theMsg = theMsg .. ", " .. "\"" .. RIC.db.profile.Codewords[ci] .. "\""
				end
			end
			if (#RIC.db.profile.Codewords) >= 2 then
				theMsg = theMsg .. " " .. RIC.db.profile.Lp["Or"] .. " \"" .. RIC.db.profile.Codewords[#RIC.db.profile.Codewords] .. "\""
			else
				theMsg = theMsg ..  " \"" .. RIC.db.profile.Codewords[1] .. "\""
			end

			theMsg = theMsg .. " " .. RIC.db.profile.Lp["For_An_Invite"]
			RIC.SendChatMessage(theMsg ,"GUILD" ,nil ,nil)
		end
	end
end

function RIC._Codewords_Handler.endInvitePhase()
	if RIC.db.profile.CodewordNotifyEnd then
		RIC.SendChatMessage(RIC.db.profile.Lp["Codewords_End"] ,"GUILD" ,nil ,nil)
	end
end

function RIC._Codewords_Handler.isInviteWhisper(msg)
	-- Checks if this message counts as an invite whisper (return true) or not, depending on settings checking if message equals OR contains a codeword
	if RIC.db.profile.CodewordExactMatch then
		return RIC._Codewords_Handler.equalsCodeword(msg)
	else
		return RIC._Codewords_Handler.containsCodeword(msg)
	end
end

function RIC._Codewords_Handler.containsCodeword(msg)
	-- In case our addon is sending a message to us, ignore it!
	if string.find(msg, RIC._ChatString, 1, true) ~= nil then
		return false
	end
	-- Go through codewords, check for each if its in the message
	for _, codeword in ipairs(RIC.db.profile.Codewords) do
		if string.find(string.utf8upper(msg), string.utf8upper(codeword), 1, true) then
			return true
		end
	end
	return false
end

function RIC._Codewords_Handler.equalsCodeword(msg)
	local numCodeWords = #RIC.db.profile.Codewords
	for ci=1, numCodeWords do
		if string.utf8upper(msg) == string.utf8upper(RIC.db.profile.Codewords[ci]) then
			return true
		end
	end
	return false
end
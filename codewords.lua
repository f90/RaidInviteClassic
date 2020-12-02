-- For converting whitelist and blacklist textboxes into player tables
function RIC_Codewords_Handler.buildPlayerList(blacklistString)
	local newPlayerList = {}
	if blacklistString == nil then
		return newPlayerList
	end

	-- Use newlines, colons, comma or space to separate characters
	local parsedList = gsub(blacklistString, ";", "\n")
	parsedList = gsub(parsedList, ",", "\n")
	parsedList = gsub(parsedList, " ", "\n")
	parsedList = { strsplit("\n", parsedList) }

	for _, playerName in ipairs(parsedList) do
		local p = trim_special_chars(playerName)
		if string.utf8len(p) > 1 then
			-- Add player
			newPlayerList[p] = true
		end
	end
	return newPlayerList
end

-- For converting whitelist and blacklist player tables into textbox strings
function RIC_Codewords_Handler.getPlayerListString(playerList)
	local playerListString = ""
	if playerList == nil then
		return playerListString
	end

	for playerName, _ in pairsByKeys(playerList) do
		playerListString = playerListString .. playerName .. "\n"
	end
	return playerListString
end

function RIC_Codewords_Handler.buildCodeWords(newCodewordString)
	local newCodewords = {}
	if newCodewordString == nil then
		return newCodewords
	end

	local codewords = { strsplit("\n", newCodewordString) }

	-- Go through codewords, trim them and put into codeword table
	for _, codeword in ipairs(codewords) do
		local c = trim_special_chars(codeword) -- Trim codewords - no empty spaces no special chars
		c = string.utf8lower(c) -- Put to lower case so people realise upper/lower case doesnt matter
		-- Check if line is empty, and addon tag does not contain our codeword to avoid accidental triggers by other addon users
		if (string.utf8len(c) > 0) and (string.find(string.utf8lower(RIC_ChatString), c, 1, true) == nil) then
			-- Add codeword!
			table.insert(newCodewords, c)
		end
	end

	return newCodewords
end

function RIC_Codewords_Handler.getCodeWordsString(codewords)
	local s = ""
	for i, c in ipairs(codewords) do
		s = s .. c
		if i < #codewords then
			s = s .. "\n"
		end
	end
	return s
end

function RIC_Codewords_Handler.startInvitePhase()
	-- Notify guild now, if this is activated in the options
	if RIC.db.profile.CodewordNotifyStart then
		if #RIC.db.profile.Codewords == 0 then
			RIC:Print(L["Codewords_Not_Set"])
		else
			local theMsg = L["Whisper_Me"]
			for ci=1, (#RIC.db.profile.Codewords - 1) do
				if (ci == 1) then
					theMsg = theMsg .. " \"" .. RIC.db.profile.Codewords[ci] .. "\""
				else
					theMsg = theMsg .. ", " .. "\"" .. RIC.db.profile.Codewords[ci] .. "\""
				end
			end
			if (#RIC.db.profile.Codewords) >= 2 then
				theMsg = theMsg .. " " .. L["Or"] .. " \"" .. RIC.db.profile.Codewords[#RIC.db.profile.Codewords] .. "\""
			else
				theMsg = theMsg ..  " \"" .. RIC.db.profile.Codewords[1] .. "\""
			end

			theMsg = theMsg .. " " .. L["For_An_Invite"]
			SendChatMessageRIC(theMsg ,"GUILD" ,nil ,nil)
		end
	end
end

function RIC_Codewords_Handler.endInvitePhase()
	if RIC.db.profile.CodewordNotifyEnd then
		SendChatMessageRIC(L["Codewords_End"] ,"GUILD" ,nil ,nil)
	end
end

function RIC_Codewords_Handler.containsCodeword(msg)
	-- In case our addon is sending a message to us, ignore it!
	if string.find(msg, RIC_ChatString, 1, true) ~= nil then
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

function RIC_Codewords_Handler.equalsCodeword(msg)
	local numCodeWords = #RIC.db.profile.Codewords
	for ci=1, numCodeWords do
		if string.utf8upper(msg) == string.utf8upper(RIC.db.profile.Codewords[ci]) then
			return true
		end
	end
	return false
end
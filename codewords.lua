function RIC_Codewords_Handler.updateCodeWords()
	RIC_CodeWords = {}
	local codewords = { strsplit("\n", RIC.db.profile.CodewordString) }

	-- Go through codewords, trim them and put into codeword table
	for i=1,#codewords do
		local c = trim_special_chars(codewords[i]) -- Trim codewords - no empty spaces no special chars
		c = string.utf8lower(c) -- Put to lower case so people realise upper/lower case doesnt matter
		-- Check if line is empty, and addon tag does not contain our codeword to avoid accidental triggers by other addon users
		if (string.utf8len(c) > 0) and (string.find(string.utf8lower(RIC_ChatString), c) == nil) then
			-- Add codeword!
			table.insert(RIC_CodeWords, c)
		end
	end

	-- Update codeword string and editbox according to cleaned-up codewords
	local s = ""
	for i=1,#RIC_CodeWords do
		s = s .. RIC_CodeWords[i]
		if i < #RIC_CodeWords then
			s = s .. "\n"
		end
	end
	RIC.db.profile.CodewordString = s
	_G["RIC_CodeWordEditBox"]:SetText(RIC.db.profile.CodewordString)
end

function RIC_Codewords_Handler.startInvitePhase()
	RIC_Codewords_Handler.updateCodeWords() -- Parse codewords from text box

	-- Notify guild now, if this is activated in the options
	if RIC.db.profile.CodewordNotifyStart then
		if #RIC_CodeWords == 0 then
			RIC:Print(L["Codewords_Not_Set"])
		else
			local theMsg = L["Whisper_Me"]
			for ci=1, (#RIC_CodeWords - 1) do
				if (ci == 1) then
					theMsg = theMsg .. " \"" .. RIC_CodeWords[ci] .. "\""
				else
					theMsg = theMsg .. ", " .. "\"" .. RIC_CodeWords[ci] .. "\""
				end
			end
			if (#RIC_CodeWords) >= 2 then
				theMsg = theMsg .. " " .. L["Or"] .. " \"" .. RIC_CodeWords[#RIC_CodeWords] .. "\""
			else
				theMsg = theMsg ..  " \"" .. RIC_CodeWords[1] .. "\""
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
	if string.find(msg, RIC_ChatString) ~= nil then
		return false
	end
	-- Go through codewords, check for each if its in the message
	local numCodeWords = #RIC_CodeWords
	for ci=1, numCodeWords do
		if string.find(string.utf8upper(msg), string.utf8upper(RIC_CodeWords[ci])) then
			return true
		end
	end
	return false
end

function RIC_Codewords_Handler.equalsCodeword(msg)
	local numCodeWords = #RIC_CodeWords
	for ci=1, numCodeWords do
		if string.utf8upper(msg) == string.utf8upper(RIC_CodeWords[ci]) then
			return true
		end
	end
	return false
end
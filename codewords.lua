function RIC_Codewords_Handler.updateCodeWords()
	RIC_CodeWords = {}
	local codewords = { strsplit("\n", RIC_CodeWordString) }

	-- Go through codewords, trim them and put into codeword table
	for i=1,#codewords do
		local c = trim_special_chars(codewords[i]) -- Trim codewords - no empty spaces no special chars
		c = string.utf8lower(c) -- Put to lower case so people realise upper/lower case doesnt matter
		if string.utf8len(c) > 0 then -- Check if line is empty
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
	RIC_CodeWordString = s
	_G["RIC_CodeWordEditBox"]:SetText(RIC_CodeWordString)
end

function RIC_Codewords_Handler.startInvitePhase()
	RIC_Codewords_Handler.updateCodeWords() -- Parse codewords from text box

	-- Notify guild now, if this is activated in the options
	if RIC_CodewordNotifyStart then
		if #RIC_CodeWords == 0 then
			printRIC("WARNING: You haven't set any codewords that could be announced to the guild now!")
		else
			local theMsg = "Raid invites started! Whisper me \""
			for ci=1, (#RIC_CodeWords - 1) do
				if (ci == 1) then
					theMsg = theMsg .. "\"" .. RIC_CodeWords[ci] .. "\""
				else
					theMsg = theMsg .. ", " .. "\"" .. RIC_CodeWords[ci] .. "\""
				end
			end
			if (#RIC_CodeWords) > 2 then
				theMsg = theMsg .. ", or \"" .. RIC_CodeWords[#RIC_CodeWords] .. "\""
			elseif (#RIC_CodeWords) == 2 then
				theMsg = theMsg .. " or \"" .. RIC_CodeWords[2] .. "\""
			else
				theMsg = theMsg ..  RIC_CodeWords[1]
			end

			theMsg = theMsg .. "\" for an invite!"
			SendChatMessageRIC(theMsg ,"GUILD" ,nil ,nil)
		end
	end
end

function RIC_Codewords_Handler.endInvitePhase()
	if RIC_CodewordNotifyEnd then
		SendChatMessageRIC("Invite by codeword stopped!" ,"GUILD" ,nil ,nil)
	end
end

function RIC_Codewords_Handler.containsCodeword(msg)
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
function RIC_Codewords_Handler.updateCodeWords()
	local swapString = gsub(RIC_CodeWordString, "\n", "\186")
	RIC_CodeWords = { strsplit("\186", swapString) }
end

function RIC_Codewords_Handler.startInvitePhase()
	RIC_Codewords_Handler.updateCodeWords() -- Parse codewords from text box

	-- Notify guild now, if this is activated in the options
	if RIC_CodeWordNotifyStart then
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
			SendChatMessage(theMsg ,"GUILD" ,nil ,nil)
		end
	end
end

function RIC_Codewords_Handler.endInvitePhase()
	if RIC_CodeWordNotifyEnd then
		SendChatMessage("Invite by codeword stopped!" ,"GUILD" ,nil ,nil)
	end
end

function RIC_Codewords_Handler.checkFilters(msg)
	msg = string.upper(msg)
	local numCodeWords = #RIC_CodeWords
	for ci=1, numCodeWords do
		if string.find(msg, string.upper(RIC_CodeWords[ci])) then
			return true
		end
	end
	return false
end
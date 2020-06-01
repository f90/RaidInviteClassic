local function hideInviteWhispers(self, event, msg, author, ...)
    if RIC_CodewordHide then
        return RIC_Codewords_Handler.equalsCodeword(msg) -- If our message exactly constains the codeword and nothing else, hide it!
    else
        return false -- Always show messages if we are not hiding codewords
    end
end

function RIC_Chat_Manager.setupFilter()
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", hideInviteWhispers)
end
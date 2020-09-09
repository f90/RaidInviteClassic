RIC_ReceivedWhisperAuthors = {}

-- Hides incoming invite whispers, if they ONLY contain a codeword
local function hideInviteWhispers(self, event, msg, author, ...)
    if RIC.db.profile.CodewordHide then
        return RIC_Codewords_Handler.equalsCodeword(msg) -- If incoming message exactly contains the codeword and nothing else, hide it!
    end
    return false -- Always show messages if we are not hiding codewords
end

local function recordWhisperAuthor(self, event, msg, author, ...)
    RIC_ReceivedWhisperAuthors[author] = true
end

-- Hides outgoing whispers made by this addon to other users
local function hideRICWhispers(self, event, msg, recipient, ...)
    if RIC.db.profile.HideOutgoingWhispers then
        if msg:find(RIC_ChatString,1,true) then -- Search for the RIC string exactly, (no regex search)
            return true
        end
    end
    return false -- Show everything else
end

function RIC_Chat_Manager.setupFilter()
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", hideInviteWhispers)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", recordWhisperAuthor)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", hideRICWhispers)
end
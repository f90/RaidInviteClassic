local addonName, RIC = ...
RIC._receivedWhisperAuthors = {}

-- Hides incoming invite whispers, if they ONLY contain a codeword
local function hideInviteWhispers(self, event, msg, author, ...)
    if RIC.db.profile.CodewordHide then
        return RIC._Codewords_Handler.equalsCodeword(msg) -- If incoming message exactly contains the codeword and nothing else, hide it!
    end
    return false -- Always show messages if we are not hiding codewords
end

local function recordWhisperAuthor(self, event, msg, author, ...)
    RIC._receivedWhisperAuthors[author] = true
end

-- Hides outgoing whispers made by this addon to other users
local function hideRICWhispers(self, event, msg, recipient, ...)
    if RIC.db.profile.HideOutgoingWhispers then
        if msg:find(RIC._ChatString,1,true) then -- Search for the RIC string exactly, (no regex search)
            return true
        end
    end
    return false -- Show everything else
end

function RIC._RIC_Chat_Manager.setupFilter()
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", hideInviteWhispers)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", recordWhisperAuthor)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", hideRICWhispers)
end
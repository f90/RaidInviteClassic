-- Author      : Daniel Stoller

RIC_Version = "0.6.1"

-- MODULES
RIC_Guild_Browser = {}
RIC_Roster_Browser = {}
RIC_Codewords_Handler = {}
RIC_Guild_Manager = {}
RIC_Durability_Manager = {}
RIC_Chat_Manager = {}

-- SETTINGS
RIC_displayRanks = {true, true, true, true, true, true, true, true, true, true}
RIC_UpdateInterval = 1.5
RIC_InviteInterval = 120.0

RIC_CodeWordString = "Invite"
RIC_CodeWords = {}

RIC_ShowOffline = true
RIC_CodewordOnlyDuringInvite = true
RIC_CodewordOnlyInGroup = true
RIC_CodewordNotifyStart = true
RIC_CodewordNotifyEnd = false
RIC_CodewordHide = true

RIC_GuildWhispersOnly = false
RIC_RosterWhispersOnly = false

RIC_Durability_Warning = true
RIC_Durability_Threshold = 80

RIC_MinimapPos = 0 -- default position of the minimap icon in degrees
RIC_MinimapShow = true
RIC_NotifyInvitePhaseStart = true
RIC_NotifyInvitePhaseEnd = false
RIC_MasterLooter = false
RIC_HideOutgoingWhispers = false
RIC_MainFrameScale = 1

RIC_ChatString = "[RIC]:"

-- RIC guild messages and whisper notifications. Set to nil to disable
RIC_MSG_Codewords_End = "Invite by codeword stopped!"
RIC_MSG_Codewords_Invite_Phase = "Invite by codeword only possible during invite phase!"
RIC_MSG_Codewords_Not_In_Roster = "You are not in the roster - did you forget to register for the raid in advance?"
RIC_MSG_Codewords_Not_In_Guild = "You are not a guild member. Only guild members are invited automatically."
RIC_MSG_Codewords_Already_In_Raid = "You can't be invited to the raid - you are already in it!"
RIC_MSG_Codewords_Raid_Full = "Raid already full - if you reserved a spot by registering for the raid in advance, contact the raid leader"
RIC_MSG_Codewords_Invite_Rights = "I cannot invite you since I don't have assist rights."
RIC_MSG_Already_In_Group = "WARNING: You could not be invited to the raid that starts now since you are already in a group. Please leave it!"
RIC_MSG_Invite_Start = "INVITING NOW - If you are registered for the raid, please leave your groups now and standby!"
RIC_MSG_Invite_End = "Invite phase for raid ended!"
RIC_MSG_Codewords_Not_Set = "WARNING: You haven't set any codewords that could be announced to the guild now!"
RIC_MSG_Whisper_Author_Unknown = "WARNING: Author of some incoming whisper could not be parsed - check if you missed an invite whisper!"

-- ROSTER LIST
RIC_RosterList = {}
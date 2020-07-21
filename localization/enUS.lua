local L = LibStub("AceLocale-3.0"):NewLocale("Raid Invite Classic", "enUS", true)

-- RIC guild messages and whisper notifications
L["Codewords_End"] = "Invite by codeword stopped!"
L["Codewords_Invite_Phase"] = "Invite by codeword only possible during invite phase!"
L["Codewords_Not_In_Roster"] = "You are not in the roster - did you forget to register for the raid in advance?"
L["Codewords_Not_In_Guild"] = "You are not a guild member. Only guild members are invited automatically."
L["Codewords_Already_In_Raid"] = "You can't be invited to the raid - you are already in it!"
L["Codewords_Raid_Full"] = "Raid already full - if you reserved a spot by registering for the raid in advance, contact the raid leader."
L["Codewords_Invite_Rights"] = "I cannot invite you since I don't have invite rights."
L["Already_In_Group"] = "WARNING: You could not be invited to the raid that starts now since you are already in a group. Please leave it!"
L["Invite_Start"] = "INVITING NOW - If you are registered for the raid, please leave your groups now and standby!"
L["Invite_End"] = "Invite phase for raid ended!"
L["Codewords_Not_Set"] = "WARNING: You haven't set any codewords that could be announced to the guild now!"
L["Whisper_Author_Unknown"] = "WARNING: Author of some incoming whisper could not be parsed - check if you missed an invite whisper!"

-- Codeword announcement
L["Whisper_Me"] = "Whisper me"
L["Or"] = "or"
L["For_An_Invite"] = "for an invite!"

-- Player status tooltips
L["Guild_Member_Came_Online"] = "Guild member came online"
L["Guild_Member_Went_Offline"] = "Guild member went offline"
L["Invite_Failed_Expired"] = "Invite was not accepted in time and expired"
L["Invite_Failed_Raid_Full"] = "Invite could not be sent because raid was full"
L["Invite_Failed_Already_In_Group"] = "Invite failed because player was already in a group"
L["Invite_Skipped_Not_Online"] = "Invite was not sent because player was offline"
L["Invite_Pending"] = "Invite was sent out and is pending"
L["Not_Invited_Converting_Raid"] = "Invite was postponed since we were still converting the group to a raid"
L["Player_Joined"] = "Player joined the raid"
L["Player_Left"] = "Player left the raid"
L["Invite_Failed_Not_Online"] = "Invite failed because player was offline"
L["Invite_Failed_Declined"] = "Invite failed because player declined it"
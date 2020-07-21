local L = LibStub("AceLocale-3.0"):NewLocale("Raid Invite Classic", "ruRU")

-- RIC guild messages and whisper notifications
L["Codewords_End"] = "Приглашение по кодовому слову остановлено!"
L["Codewords_Invite_Phase"] = "Приглашение по кодовому слову возможно только на этапе приглашения!"
L["Codewords_Not_In_Roster"] = "Вас нет в реестре - вы забыли зарегистрироваться на рейд заранее?"
L["Codewords_Not_In_Guild"] = "Ты не член Гильдии. Только члены гильдии приглашаются автоматически."
L["Codewords_Already_In_Raid"] = "Вас нельзя приглашать на рейд - вы уже в нем участвуете!"
L["Codewords_Raid_Full"] = "Рейд уже заполнен - если вы зарезервировали место, зарегистрировавшись на рейд заранее, свяжитесь с лидером рейда"
L["Codewords_Invite_Rights"] = "Я не могу пригласить вас, так как у меня нет прав на помощь."
L["Already_In_Group"] = "Предупреждение: вы не можете быть приглашены на рейд, который начинается сейчас, так как вы уже находитесь в группе. Пожалуйста, покиньте ее!"
L["Invite_Start"] = "Приглашение сейчас - если вы зарегистрированы для участия в рейде, пожалуйста, оставьте свои группы сейчас и ждите!"
L["Invite_End"] = "Фаза приглашения для рейда закончилась!"
L["Codewords_Not_Set"] = "Предупреждение: вы не установили никаких кодовых слов, которые могли бы быть объявлены гильдии сейчас!"
L["Whisper_Author_Unknown"] = "Предупреждение: автор некоторого входящего шепота не может быть проанализирован - проверьте, не пропустили ли вы приглашающий шепот!"

-- Codeword announcement
L["Whisper_Me"] = "Шепни мне"
L["Or"] = "или"
L["For_An_Invite"] = "для приглашения!"

-- Player status tooltips --TODO translate
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
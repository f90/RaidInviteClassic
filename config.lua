local addonName, RIC = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

function RIC.getOptions()
    -- OPTIONS
	local options = {
		name = addonName,
		handler = RIC,
		type = 'group',
		args = {
			general = {
				name = "General",
				type = "group",
				args = {
					invitebreak = {
						name = "Invites",
						type = "header",
						order = 0,
					},

					sendinvites = {
						name = "Send invites",
						desc = "Activate to send out invites during the invite phase. If deactivated, players MUST be manually invited or invite themselves using a whisper keyword!",
						type = "toggle",
						order = 5,
						width = "full",
						set = function(info, val)
							RIC.db.profile.SendInvites = val;
							if val == false then
								RIC.db.profile.InviteIntervalActive = false
							end
						end,
						get = function(info)
							return RIC.db.profile.SendInvites
						end
					},

					inviteintervalactive = {
						name = "Periodic invites:",
						desc = "Activate to send out invites regularly during the invite phase, to all people still missing after starting the invite phase. If deactivated, invites are only sent out once for each player",
						type = "toggle",
						order = 10,
						set = function(info, val)
							RIC.db.profile.InviteIntervalActive = val;
						end,
						get = function(info)
							return RIC.db.profile.InviteIntervalActive
						end,
						disabled = function()
							return (not RIC.db.profile.SendInvites)
						end,
					},

					inviteinterval = {
						name = "Invite interval (seconds)",
						desc = "How often invites are sent out to those not in the raid yet. Lower times means people wait less for an invite, but they will get a lot of invite requests and possibly warnings.",
						type = "range",
						order = 11,
						min = 70.0,
						max = 1500,
						set = function(info, val)
							RIC.db.profile.InviteInterval = val;
						end,
						get = function(info)
							return RIC.db.profile.InviteInterval
						end,
						disabled = function()
							return not (RIC.db.profile.InviteIntervalActive and RIC.db.profile.SendInvites)
						end,
					},

					invitedelay = {
						name = "Delay initial invites:",
						desc = "Amount of seconds to wait after starting invite phase before initial invites are sent out (set to 0 to disable delay). Can be useful for your raiders to leave their groups once they see the invite announcement in guild chat",
						type = "range",
						width = "full",
						order = 13,
						min = 0.0,
						max = 20,
						step = 1,
						set = function(info, val)
							RIC.db.profile.InviteDelay = val;
						end,
						get = function(info)
							return RIC.db.profile.InviteDelay
						end,
						disabled = function()
							return not (RIC.db.profile.SendInvites and RIC.db.profile.SendInvites)
						end,
					},

					inviteungrouped = {
						name = "Invite ungrouped",
						desc = "Disable to prevent sending any invites to people on the roster list that are NOT assigned to any group (viewed as bench players)",
						type = "toggle",
						order = 20,
						set = function(info, val)
							RIC.db.profile.InviteUngrouped = val;
						end,
						get = function(info)
							return RIC.db.profile.InviteUngrouped
						end,
						disabled = function()
							return (not RIC.db.profile.SendInvites)
						end,
					},


					otherbreak = {
						name = "Other settings",
						type = "header",
						order = 30,
					},

					masterlooter = {
						name = "Set to master looter",
						desc = "Set raid to master looter when starting the invite phase",
						type = "toggle",
						order = 35,
						set = function(info, val)
							RIC.db.profile.MasterLooter = val;
						end,
						get = function(info)
							return RIC.db.profile.MasterLooter
						end
					},
				}
			},

			gui = {
				name = "GUI",
				type = "group",
				args = {
					showcharrealms = {
						name = "Show player realms",
						desc = "Show realm names for all characters displayed in the addon, e.g. display 'Tim-Patchwerk' instead of just 'Tim'",
						type = "toggle",
						set = function(info, val)
							RIC.db.profile.ShowCharRealms = val;
						end,
						get = function(info)
							return RIC.db.profile.ShowCharRealms
						end
					},

					minimapshow = {
						name = "Hide minimap icon",
						desc = "Tick to hide minimap icon",
						type = "toggle",
						set = function(info, val)
							RIC.db.profile.hide = val
							RIC.MinimapButton_Update()
						end,
						get = function(info)
							return RIC.db.profile.hide
						end
					},

					mainframescale = {
						name = "Overall scale",
						desc = "Scales the size of the addon frame",
						type = "range",
						min = 0.4,
						max = 2.0,
						set = function(info, val)
							RIC.db.profile.MainFrameScale = val
							RIC.setScale()
						end,
						get = function(info)
							return RIC.db.profile.MainFrameScale
						end
					},
				}
			},

			notifications = {
				name = "Notifications",
				type = "group",
				args = {
					notifyinvitephasestart = {
						name = "Announce start of invite phase:",
						desc = "Announces start of invite phase to guild",
						type = "toggle",
						width = "full",
						order = 0,
						set = function(info, val)
							RIC.db.profile.NotifyInvitePhaseStart = val;
						end,
						get = function(info)
							return RIC.db.profile.NotifyInvitePhaseStart
						end
					},

					notifyinvitephasestartmsg = {
						name = "Message:",
						desc = "Message sent to the guild when invite phase starts",
						type = "input",
						width = "full",
						multiline = 0,
						order = 1,
						set = function(info, val)
							RIC.db.profile.Lp["Invite_Start"] = val
						end,
						get = function(info)
							return RIC.db.profile.Lp["Invite_Start"]
						end,
						disabled = function()
							return (not RIC.db.profile.NotifyInvitePhaseStart)
						end,
					},

					 notifyinvitephaseend = {
						name = "Announce end of invite phase:",
						desc = "Announces end of invite phase to guild",
						type = "toggle",
						width = "full",
						order = 5,
						set = function(info, val)
							RIC.db.profile.NotifyInvitePhaseEnd = val;
						end,
						get = function(info)
							return RIC.db.profile.NotifyInvitePhaseEnd
						end
					},

					notifyinvitephaseendmsg = {
						name = "Message:",
						desc = "Message sent to the guild when invite phase ends",
						type = "input",
						width = "full",

						multiline = 0,
						order = 6,
						set = function(info, val)
							RIC.db.profile.Lp["Invite_End"] = val
						end,
						get = function(info)
							return RIC.db.profile.Lp["Invite_End"]
						end,
						disabled = function()
							return (not RIC.db.profile.NotifyInvitePhaseEnd)
						end,
					},

					hidenotifications = {
						name = "Hide ALL outgoing notifications",
						desc = "Hides ALL whispers sent by this addon to other players that notify them about various issues (invite failures etc.). " ..
						"This prevents addon whispers to other people from spamming your chat window, " ..
						"but might make you miss problems with your raiders (e.g. person still in another group), so use with care",
						type = "toggle",
						order = 20,
						set = function(info, val)
							RIC.db.profile.HideOutgoingWhispers = val;
						end,
						get = function(info)
							return RIC.db.profile.HideOutgoingWhispers
						end
					},
				}
			},

			playerchecks = {
				name = "Player checks",
				type = "group",
				args = {
					durabilitytoggle = {
						name = "Durability warning",
						desc = "Enable this to check the gear durability of players joining the raid, to send them a message if their equipment is broken",
						type = "toggle",
						order = 0,
						set = function(info, val)
							RIC.db.profile.Durability_Warning = val;
						end,
						get = function(info)
							return RIC.db.profile.Durability_Warning
						end
					},

					durabilitythreshold = {
						name = "Durability threshold (%)",
						desc = "Warn the player when the average gear durability is below this amount (%)",
						type = "range",
						order = 1,
						disabled = function()
							return (not RIC.db.profile.Durability_Warning)
						end,
						min = 1.0,
						max = 99.0,
						set = function(info, val)
							RIC.db.profile.Durability_Threshold = val;
						end,
						get = function(info)
							return RIC.db.profile.Durability_Threshold
						end
					},

					durabilityinvitephase = {
						name = "Only during invite phase",
						desc = "Only check gear durability of players that join when invite phase is active",
						type = "toggle",
						order = 2,
						disabled = function()
							return (not RIC.db.profile.Durability_Warning)
						end,
						set = function(info, val)
							RIC.db.profile.Durability_Invite_Phase = val;
						end,
						get = function(info)
							return RIC.db.profile.Durability_Invite_Phase
						end
					},
				}
			},

			codewords = {
				name = "Codewords",
				type = "group",
				args = {
					codewordlist = {
						name = "List of codewords",
						desc = "Enter the codewords (one per line) that people can whisper you to get themselves invited to the raid. It is enough for one codeword to be contained in the whisper message to get an invite.",
						type = "input",
						width = "full",
						multiline = 6,
						order = 1,
						set = function(info, val)
							RIC.db.profile.Codewords = RIC._Codewords_Handler.buildCodeWords(val)
						end,
						get = function(info)
							return RIC._Codewords_Handler.getCodeWordsString(RIC.db.profile.Codewords)
						end
					},

					restrictions = {
						name = "Restrictions",
						type = "group",
						args = {
							whitelist = {
								name = "Whitelist players",
								desc = "List names (one player per line) of characters whose codeword whispers should always be accepted (meaning all permission checks such as being on the roster or in the guild are skipped)",
								type = "input",
								width = "full",
								multiline = 6,
								order = 1,
								set = function(info, val)
									RIC.db.realm.Whitelist = RIC._Codewords_Handler.buildPlayerList(val)
								end,
								get = function(info)
									return RIC._Codewords_Handler.getPlayerListString(RIC.db.realm.Whitelist)
								end
							},

							blacklist = {
								name = "Blacklist players",
								desc = "List names (one player per line) of characters whose codeword whispers should always be ignored (except if they are also on the whitelist)",
								type = "input",
								width = "full",
								multiline = 6,
								order = 2,
								set = function(info, val)
									RIC.db.realm.Blacklist = RIC._Codewords_Handler.buildPlayerList(val)
								end,
								get = function(info)
									return RIC._Codewords_Handler.getPlayerListString(RIC.db.realm.Blacklist)
								end
							},

							onlyingroup = {
								name = "Only in group",
								desc = "Only accept codewords when you are already in group. When active, people can not force you to start a new group by whispering you, instead the request is ignored silently.",
								type = "toggle",
								order = 5,
								set = function(info, val)
									RIC.db.profile.CodewordOnlyInGroup = val;
								end,
								get = function(info)
									return RIC.db.profile.CodewordOnlyInGroup
								end
							},

							onlyduringinvite = {
								name = "Only during invite phase",
								desc = "Only accept codewords when you are currently in the invite phase",
								type = "toggle",
								order = 6,
								set = function(info, val)
									RIC.db.profile.CodewordOnlyDuringInvite = val;
									if (val == false) then
										RIC.db.profile.CodewordNotifyEnd = false
									end
								end,
								get = function(info)
									return RIC.db.profile.CodewordOnlyDuringInvite
								end
							},

							onlyfromguild = {
								name = "Only for guild members",
								desc = "Only accept codewords from guild members",
								type = "toggle",
								order = 7,
								set = function(info, val)
									RIC.db.profile.GuildWhispersOnly = val;
								end,
								get = function(info)
									return RIC.db.profile.GuildWhispersOnly
								end
							},

							onlyfromroster = {
								name = "Only for roster players",
								desc = "Only accept codewords from people on the current roster",
								type = "toggle",
								order = 8,
								set = function(info, val)
									RIC.db.profile.RosterWhispersOnly = val;
								end,
								get = function(info)
									return RIC.db.profile.RosterWhispersOnly
								end
							},
						}
					},

					sendguildmessagestart = {
						name = "Notify guild at invite start",
						desc = "Send a guild message containing the usable codewords when starting the invite phase",
						type = "toggle",
						order = 4,
						set = function(info, val)
							RIC.db.profile.CodewordNotifyStart = val;
						end,
						get = function(info)
							return RIC.db.profile.CodewordNotifyStart
						end
					},

					sendguildmessageend = {
						name = "Notify guild at invite end",
						desc = "When stopping the invite phase, inform the guild that codewords are not longer accepted anymore.",
						type = "toggle",
						order = 5,
						disabled = function()
							return (not RIC.db.profile.CodewordOnlyDuringInvite)
						end,
						set = function(info, val)
							RIC.db.profile.CodewordNotifyEnd = val;
						end,
						get = function(info)
							return RIC.db.profile.CodewordNotifyEnd
						end
					},

					invitewhispercheck = {
						name = "Exact match",
						desc = "Toggle this on if you only want to invite people that whisper you EXACTLY one of the codewords (ignoring upper/lowercase). When this is off, the whisper message only needs to CONTAIN one of the codewords.",
						type = "toggle",
						order = 7,
						set = function(info, val)
							RIC.db.profile.CodewordExactMatch = val;
						end,
						get = function(info)
							return RIC.db.profile.CodewordExactMatch
						end
					},

					hidecodewordwhispers = {
						name = "Hide codeword whispers",
						desc = "Hide incoming whispers from your chat that contain NOTHING but a codeword. When activated, the addon still processes these whispers normally, they are just hidden from your view.",
						type = "toggle",
						order = 8,
						set = function(info, val)
							RIC.db.profile.CodewordHide = val;
						end,
						get = function(info)
							return RIC.db.profile.CodewordHide
						end
					},
				}
			}
		},
	}

    -- DATABASE DEFAULT CONFIG VALUES
    local defaults = {
        profile =  {
            GuildWhispersOnly = false,
            RosterWhispersOnly = false,

            Durability_Warning = true,
            Durability_Threshold = 80,
			Durability_Invite_Phase = false,

            minimapPos = 0, -- default position of the minimap icon in degrees
            hide = false, -- Minimap hide
			MainFrameScale = 1,

            NotifyInvitePhaseStart = true,
            NotifyInvitePhaseEnd = false,

            MasterLooter = false,
            HideOutgoingWhispers = false,

			Codewords = {"invite"},
			CodewordExactMatch = false,
			CodewordOnlyDuringInvite = true,
			CodewordOnlyInGroup = true,
			CodewordNotifyStart = true,
			CodewordNotifyEnd = false,
			CodewordHide = true,

			ShowOffline = true,
			DisplayRanks = {true, true, true, true, true, true, true, true, true, true},

			SendInvites = true,
			InviteIntervalActive = true,
			InviteInterval = 120.0,
			InviteDelay = 2.0,
			InviteUngrouped = true,
			ShowCharRealms = false,

			Lp = L -- Load standard localised strings into profile so user can customise messages
        },

		realm = {
			RosterList = {["Default Roster"] = {}},
			CurrentRoster = "Default Roster",
			KnownPlayerClasses = {},
			Blacklist={},
			Whitelist={}
		}
    }

    return options, defaults
end
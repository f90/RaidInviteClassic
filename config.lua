function getOptions()
    -- OPTIONS
	local options = {
		name = "Raid Invite Classic",
		handler = RIC,
		type = 'group',
		args = {
			general = {
				name = "General",
				type = "group",
				args = {
					inviteinterval = {
						name = "Invite interval (seconds)",
						desc = "How often invites are sent out to those not in the raid yet. Lower times means people wait less for an invite, but they will get a lot of invite requests and possibly warnings.",
						type = "range",
						min = 70.0,
						max = 1500,
						set = function(info, val)
							RIC.db.profile.InviteInterval = val;
						end,
						get = function(info)
							return RIC.db.profile.InviteInterval
						end
					},

					masterlooter = {
						name = "Enable master looter",
						desc = "Set raid to master looter when starting the invite phase",
						type = "toggle",
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
					minimapshow = {
						name = "Minimap icon",
						desc = "Enable / disable minimap icon",
						type = "toggle",
						set = function(info, val)
							RIC.db.profile.MinimapShow = val
							RIC_MinimapButton_Update()
						end,
						get = function(info)
							return RIC.db.profile.MinimapShow
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
							RIC_setScale()
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
						name = "Announce start of invite phase",
						desc = "Announces start of invite phase to guild",
						type = "toggle",
						order = 0,
						set = function(info, val)
							RIC.db.profile.NotifyInvitePhaseStart = val;
						end,
						get = function(info)
							return RIC.db.profile.NotifyInvitePhaseStart
						end
					},

					 notifyinvitephaseend = {
						name = "Announce end of invite phase",
						desc = "Announces end of invite phase to guild",
						type = "toggle",
						order = 1,
						set = function(info, val)
							RIC.db.profile.NotifyInvitePhaseEnd = val;
						end,
						get = function(info)
							return RIC.db.profile.NotifyInvitePhaseEnd
						end
					},

					hidenotifications = {
						name = "Hide ALL outgoing notifications",
						desc = "Hides ALL whispers sent by this addon to other players to notify them about various issues (invite failures etc.)",
						type = "toggle",
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
					durability = {
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

            MinimapPos = 0, -- default position of the minimap icon in degrees
            MinimapShow = true,
			MainFrameScale = 1,

            NotifyInvitePhaseStart = true,
            NotifyInvitePhaseEnd = false,

            MasterLooter = false,
            HideOutgoingWhispers = false,

			CodewordString = "invite",
			CodewordOnlyDuringInvite = true,
			CodewordOnlyInGroup = true,
			CodewordNotifyStart = true,
			CodewordNotifyEnd = false,
			CodewordHide = true,

			ShowOffline = true,
			DisplayRanks = {true, true, true, true, true, true, true, true, true, true},

			InviteInterval = 120.0
        },

		realm = {
			RosterList = {}
		}
    }

    return options, defaults
end
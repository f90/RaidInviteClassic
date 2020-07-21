local guildMembersLoginTime = {} -- Track when guild members log in
local guildMemberCameOnline = {} -- Set to true when a guild member came online, set back to nil as soon as we reset the invite state as a reaction to this
local guildMemberWentOffline = {} -- Set to true when a guild member just went offline, set back to nil as soon as we update status information as a reaction to this

function RIC_Guild_Manager.getGuildMembers()
    GuildRoster()
    local numMembers = GetNumGuildMembers(true)
    local output = {}
    for ci=1, numMembers do
        local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName = GetGuildRosterInfo(ci)

        if name ~= nil then -- When zoning, GetGuildRosterInfo sometimes returns nil for player names, then ignore this player!
            -- 1 if online, 0 if offline
            local online_val = 0
            if online then
                online_val = 1
            end

            -- name contains "name-servername" but GetRaidRosterInfo does not give us server info. Since this is a classic addon, simply remove server name here and deal ONLY with char names
            name = removeServerFromName(name)

            -- Update last-login/logoff time and set justCameOnline-flag
            if online_val == 1 then
                if guildMembersLoginTime[name] == nil then
                    -- No entry found but player is online => Player has come online now!
                    guildMembersLoginTime[name] = time()
                    guildMemberCameOnline[name] = true
                end
            else -- Player offline
                -- Was online before? => Just went offline => Set flag
                if guildMembersLoginTime[name] ~= nil then
                    guildMemberWentOffline[name] = true
                end
                guildMembersLoginTime[name] = nil -- Player offline - return nil as login time
                guildMemberCameOnline[name] = nil
            end

            output[name] = {
                rank=rank,
                rankIndex=rankIndex+1, -- Free up index 0 for non-guildies here
                level=level,
                class=class,
                zone=zone,
                note=note,
                officernote=officernote,
                online=online_val, -- 1 if online, 0 if offline
                status=status,
                cameOnlineAt=guildMembersLoginTime[name], -- nil if offline, otherwise shows time when they came online
                justCameOnline=guildMemberCameOnline[name], -- true if this player has JUST come online AND invite status was not reset yet, otherwise nil
                classFileName=classFileName,
                color=getClassColor(classFileName)
            }
        end
    end
    return output
end

function RIC_Guild_Manager.resetCameOnlineFlag(name)
    -- Called by roster browser when resetting invite status of a player because they came online
    guildMemberCameOnline[name] = nil
end

function RIC_Guild_Manager.resetWentOfflineFlag(name)
    -- Called by roster browser when updating status information because a player went offline
    guildMemberWentOffline[name] = nil
end
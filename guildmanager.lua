local addonName, RIC = ...
local guildMembersLoginTime = {} -- Track when guild members log in
local guildMemberCameOnline = {} -- Set to true when a guild member came online, set back to nil as soon as we reset the invite state as a reaction to this
local guildMemberWentOffline = {} -- Set to true when a guild member just went offline, set back to nil as soon as we update status information as a reaction to this

local output = {}
function RIC._Guild_Manager.getGuildMembers()
    local in_guild = IsInGuild()
    if not in_guild then return output end
    local numMembers = GetNumGuildMembers(true)
    if ( in_guild and numMembers == 0 ) then
        GuildRoster()
        return output
    end
    local prev_roster_count = RIC.table_count(output)
    if numMembers ~= prev_roster_count then
        wipe(output)
    end
    for ci=1, numMembers do
        local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName = GetGuildRosterInfo(ci)

        if name ~= nil then -- When zoning, GetGuildRosterInfo sometimes returns nil for player names, then ignore this player!
            -- Convert online status to boolean
            local online_val = false
            if (online == 1) or (online == true) then
                online_val = true
            end

            -- name contains "name-servername" but GetRaidRosterInfo does not give us server info. Since this is a classic addon, simply remove server name here and deal ONLY with char names
            name = RIC.removeServerFromName(name)

            -- Update last-login/logoff time and set justCameOnline-flag
            if online_val then
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
                online=online_val, -- true or false
                status=status,
                cameOnlineAt=guildMembersLoginTime[name], -- nil if offline, otherwise shows time when they came online
                justCameOnline=guildMemberCameOnline[name], -- true if this player has JUST come online AND invite status was not reset yet, otherwise nil
                classFileName=classFileName,
            }

            -- Save detected class in database
            RIC.db.realm.KnownPlayerClasses[name] = RIC.classFilenameToIndex(classFileName)
        end
    end
    return output
end

function RIC._Guild_Manager.resetCameOnlineFlag(name)
    -- Called by roster browser when resetting invite status of a player because they came online
    guildMemberCameOnline[name] = nil
end

function RIC._Guild_Manager.resetWentOfflineFlag(name)
    -- Called by roster browser when updating status information because a player went offline
    guildMemberWentOffline[name] = nil
end
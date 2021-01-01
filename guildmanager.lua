local addonName, RIC = ...
local guildMembersLoginTime = {} -- Track when guild members log in
local guildMemberCameOnline = {} -- Set to true when a guild member came online, set back to nil as soon as we reset the invite state as a reaction to this
local guildMemberWentOffline = {} -- Set to true when a guild member just went offline, set back to nil as soon as we update status information as a reaction to this

local updateGuildList = false
local guildList = {}
function RIC._Guild_Manager.getGuildMembers()
    local in_guild = IsInGuild()
    if not in_guild then return guildList
    end
    local numMembers = GetNumGuildMembers()
    if (in_guild and numMembers == 0 ) then -- Only request guild data if we are in guild, but appear to not have any guild members to look through
        GuildRoster()
        return guildList
    end

    if updateGuildList then -- If guild members have potentially changed, build guild member info table again from scratch. Otherwise reuse old table to avoid table garbage that needs to be collected all the time
        wipe(guildList)
        updateGuildList = false
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

            -- Write info about player into guildList. Reuse existing player table if possible, to avoid excessive garbage collection
            if guildList[name] == nil then
                guildList[name] = {}
            end
            guildList[name]["rank"] = rank
            guildList[name]["rankIndex"] = rankIndex + 1 -- Free up index 0 for non-guildies here
            guildList[name]["level"] = level
            guildList[name]["class"] = class
            guildList[name]["zone"] = zone
            guildList[name]["note"] = note
            guildList[name]["officernote"] = officernote
            guildList[name]["online"] = online_val -- true or false
            guildList[name]["status"] = status
            guildList[name]["cameOnlineAt"] = guildMembersLoginTime[name] -- nil if offline, otherwise shows time when they came online
            guildList[name]["justCameOnline"] = guildMemberCameOnline[name] -- true if this player has JUST come online AND invite status was not reset yet, otherwise nil
            guildList[name]["classFileName"] = classFileName

            -- Save detected class in database
            RIC.db.realm.KnownPlayerClasses[name] = RIC.classFilenameToIndex(classFileName)
        end
    end
    return guildList
end

function RIC._Guild_Manager.wipeGuildList()
    -- Guild members might have changed - set dirty flag so that next time we will completely rebuild the guild table
    updateGuildList = true
end

function RIC._Guild_Manager.resetCameOnlineFlag(name)
    -- Called by roster browser when resetting invite status of a player because they came online
    guildMemberCameOnline[name] = nil
end

function RIC._Guild_Manager.resetWentOfflineFlag(name)
    -- Called by roster browser when updating status information because a player went offline
    guildMemberWentOffline[name] = nil
end
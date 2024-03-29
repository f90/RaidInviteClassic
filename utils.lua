local addonName, RIC = ...
-- Class list lookup table (classFilename -> Localised Name) - Make sure to call this exactly ONCE before its needed!
local classFilenameToIndexTable, classIndexToFilenameTable = {}, {}
local function buildClassLists()
    if RIC.tabLength(classFilenameToIndexTable) > 0 then return end
    for i=1,100 do -- TODO GetNumClasses function does not exist in this Classic API version yet?
        local classInfo = C_CreatureInfo.GetClassInfo(i)
        if classInfo ~= nil then
            classFilenameToIndexTable[classInfo.classFile] = {className=classInfo.className, id=classInfo.classID}
            classIndexToFilenameTable[classInfo.classID] = {className=classInfo.className, classFilename=classInfo.classFile}
        end
    end
end

--Based on that: Symbols
RIC.Status = {
    READY=1,
    EXTRA=2,
    NOT_INVITED=3,
    INVITE_PENDING=4,
    INVITE_FAILED=5,
    MISSING=6,
    OTHER=7
}

RIC.InviteStatus = {
    NOT_INVITED=1,
    INVITE_PENDING=2,
    INVITE_FAILED=3
}

function RIC.normAndCheckName(name)
    -- Takes a character name and normalizes it to be in the "charname-servername" format
    -- Also checks whether the name is of valid format and tries to correct it if it isn't
    -- E.g. "Tim" becomes "Tim-Patchwerk", if the current server is Patchwerk, "Tim-Lucifron" would stay the same.
    -- Returns: Tuple: (Potentially corrected) name of format "charname-servername",
    -- bool to indicate whether name needed to be changed to become valid.
    -- Returns (nil,nil) if charname could not be determined

    -- Add server name, if it's not there yet
    local p = RIC.addServerToName(name)
    if p == nil then
        return nil, nil -- Name was nil to begin with - return nil
    end

    -- Split "char-server" name into char and server names. Both parts must exist by now!
    local orig_char_name, orig_server_name = RIC.split_char_name(p)
    if (orig_char_name == nil) or (orig_server_name == nil) then
        return nil, nil
    end
    -- Removes whitespace and special characters from char+realm names. Realm names must be normalized beforehand!
    local char_name = orig_char_name:gsub("[%c%p%s]", "")
    local server_name = orig_server_name:gsub("[%c%p%s]", "")

    -- Check length of char name
    if (string.utf8len(char_name) <= 1) or (string.utf8len(char_name) >= 13) then
        return nil, nil
    end

    -- Put first letter of char name to upper, rest to lower case
    -- WARNING: Note that string method :upper and :lower remove accented characters that do not have upper/lower case!
    -- Instead, use Blizzard API which seems to handle this by leaving those chars alone
    -- Also make sure to use utf8-aware strsub function
    char_name = strupper(string.utf8sub(char_name, 1, 1)) .. strlower(string.utf8sub(char_name, 2))

    -- Check whether we made changes to the original name
    local changed = (char_name ~= orig_char_name) or (server_name ~= orig_server_name)

    return char_name .. "-" .. server_name, changed
end

function RIC.split_char_name(name)
    if name == nil then -- Empty name - return empty name and server
        return nil, nil
    end
    local dashPosStart, dashPosEnd = string.find(name, "-", 1, true)
    if dashPosStart ~= nil then -- Check if name has a dash and therefore a realm name in it
        return strsub(name, 1, dashPosStart-1), strsub(name, dashPosStart+1)
    else
        return name, nil
    end
end

function RIC.getStatusSymbol(in_raid, in_roster, online, invite_status)
    --Checkmark - In Raid + In Roster
    --Plus symbol - In Raid + Not In Roster
    --Neutral symbol - Not in Raid + Online + In Roster + NOT_INVITED
    --Dots symbol - Not in Raid + Online/Unknown + In Roster + INVITE_PENDING
    --Cross symbol - Not in Raid + Online/Unknown + In Roster + INVITE_FAILED
    --Red lightning symbol - Not in Raid + Offline + In Roster
    --Question mark symbol - Everything else

    if in_raid and in_roster then
        return RIC.Status["READY"]
    elseif in_raid and (not in_roster) then
        return RIC.Status["EXTRA"]
    elseif (not in_raid) and (online==true) and in_roster and ((invite_status==RIC.InviteStatus["NOT_INVITED"]) or (invite_status == nil)) then
        return RIC.Status["NOT_INVITED"]
    elseif (not in_raid) and ((online==true) or (online==nil)) and in_roster and (invite_status==RIC.InviteStatus["INVITE_PENDING"]) then
        return RIC.Status["INVITE_PENDING"]
    elseif (not in_raid) and ((online==true) or (online==nil)) and in_roster and (invite_status==RIC.InviteStatus["INVITE_FAILED"]) then
        return RIC.Status["INVITE_FAILED"]
    elseif (not in_raid) and (online==false) and in_roster then
        return RIC.Status["MISSING"]
    else
        return RIC.Status["OTHER"]
    end
end

function RIC.getStatusSymbolImagePath(status)
    if status == RIC.Status["READY"] then
        return "Interface\\AddOns\\RaidInviteClassic\\img\\checkmark"
    elseif status == RIC.Status["EXTRA"] then
        return "Interface\\AddOns\\RaidInviteClassic\\img\\plus"
    elseif status == RIC.Status["NOT_INVITED"] then
        return "Interface\\AddOns\\RaidInviteClassic\\img\\dash"
    elseif status == RIC.Status["INVITE_PENDING"] then
        return "Interface\\AddOns\\RaidInviteClassic\\img\\dots"
    elseif status == RIC.Status["INVITE_FAILED"] then
        return "Interface\\AddOns\\RaidInviteClassic\\img\\red_cross"
    elseif status == RIC.Status["MISSING"] then
        return "Interface\\AddOns\\RaidInviteClassic\\img\\lightning"
    elseif status == RIC.Status["OTHER"] then
        return "Interface\\AddOns\\RaidInviteClassic\\img\\question_mark"
    else
        return nil
    end
end

RIC.RIC_ColorTable = {
	["DEATH KNIGHT"] = "C41F36",
	["DRUID"] = "FF7D0A",
	["HUNTER"] = "ABD473",
	["MAGE"] = "69CCF0",
	["PALADIN"] = "F58CBA",
	["PRIEST"] = "FFFFFF",
	["ROGUE"] = "FFF569",
	["SHAMAN"] = "2459FF",
	["WARLOCK"] = "9482C9",
	["WARRIOR"] = "C79C6E",
}

local function getClassColorHex(classFilename)
    local hex = "DA5151" -- Red-grey for unknown class
    if RIC.RIC_ColorTable[classFilename] then
        hex = RIC.RIC_ColorTable[classFilename]
    end
    return hex
end

function RIC.getClassColor(classFilename, format)
    if format == "RGB" then
        local hex = getClassColorHex(classFilename)
        return {r = tonumber("0x"..hex:sub(1,2)) / 255,
                g = tonumber("0x"..hex:sub(3,4)) / 255,
                b = tonumber("0x"..hex:sub(5,6)) / 255}
    else -- Hex string to colorise text by default
        return "|cFF" .. getClassColorHex(classFilename)
    end
end

function RIC.classFilenameToIndex(classFilename)
    buildClassLists()
    return classFilenameToIndexTable[classFilename]["id"]
end

function RIC.indexToClassFilename(index)
    buildClassLists()
    return classIndexToFilenameTable[index]["classFilename"]
end

function RIC.indexToClassname(index)
    buildClassLists()
    return classIndexToFilenameTable[index]["className"]
end

function RIC.getSortedTableKeys(t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    return a
end

function RIC.pairsByKeys(t, f)
    local a = RIC.getSortedTableKeys(t, f)
    local i = 0
    local iter = function()
		i = i + 1
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
	end
	return iter
end

function RIC.IsRaidAssistant(player)
	if not player then
		player = "player"
	end
	return UnitIsGroupLeader(player) == true or UnitIsGroupAssistant(player) == true
end

function RIC.SendChatMessage(msg, chatType, language, channel)
    if msg ~= nil and string.utf8len(msg) > 0 then -- Check if message is non-nil and not empty (disabled in settings)
        -- If we dont have a guild, just dont try sending messages to guild chat
        if chatType == "GUILD" and not IsInGuild() then
            return
        end

        SendChatMessage(RIC._ChatString .. " " .. msg, chatType, language, channel)
    end
end

function RIC.getUnitFullName(unit)
    -- Wraper for UnitFullName, ensuring output is ALWAYS (name-normalizedrealm). Only works properly for player chars!
    local name, realm = UnitFullName(unit)
    if not realm then
        -- For some reason we didn't get the realm name, so try to fetch it ourselves and append it to char name
        return RIC.addServerToName(name)
    else
        return name .. "-" .. realm
    end
end

function RIC.removeServerFromName(name)
    -- Removes server names from full names, e.g. "Tim-Patchwerk" -> "Tim"
    local dashPosStart, dashPosEnd = string.find(name, "-", 1, true)
    if dashPosStart ~= nil then -- Check if name has a dash in it
        return strsub(name, 1, dashPosStart-1)
    else
        return name -- No dash found - we have to assume there was no server name and this is already the correct  character name
    end
end

local charToRealm = {}
function RIC.addServerToName(name)
    if name == nil then -- Empty name - return empty name
        return nil
    end
    -- Adds server name to character names in case they are not there, e.g. "Tim" -> "Tim-Patchwerk"
    local char_name, server_name = RIC.split_char_name(name)
    if server_name then -- Non-nil server_name -> Valid format
        charToRealm[char_name] = server_name
        return name
    else
        local realm = GetNormalizedRealmName()
        if realm == nil then
            -- During zonein/zoneout, GetNormalizedRealmName can return nil sometimes (bug)
            -- As workaround, guess realm based on what realm this character was on before
            -- TODO This is imperfect: two players with same name cannot be distinguished.
            -- This should correct itself on the next update cycle though since we constantly update the raid list
            if charToRealm[char_name] then
                return char_name .. "-" .. charToRealm[char_name]
            else
                return char_name
            end
        else
            charToRealm[char_name] = realm
           return char_name .. "-" .. realm -- No dash found - assume this player is on our current realm
        end
    end
end

function RIC.displayName(name)
    -- Displays a character name with or without server name appended, depending on the current configuration
    if  RIC.db.profile.ShowCharRealms then
        return name -- We internally work with "char-realm" representation, so nothing to do here
    else
        return (RIC.split_char_name(name)) -- Only take first element of (char_name, server_name) tuple
    end
end

function RIC.countFrequency(list, value)
    local n = 0
    for k,v in pairs(list) do
        if v == value then
            n = n+1
        end
    end
    return n
end

local raidMemberList = {}
function RIC.getRaidMembers()
    wipe(raidMemberList)
    for ci=1, MAX_RAID_MEMBERS do
        local name, rank, subgroup, level, class, classFileName, zone, online, isDead, role, isML = GetRaidRosterInfo(ci)
        if name ~= nil then
            -- Set online to boolean variable
            if (online == 1) or (online == true) then
                online = true
            else
                online = false
            end

            -- Add server name to char name in case we don't get it from the group
            name = RIC.addServerToName(name)

            -- Add player
            raidMemberList[name] = {
            name=name,
            rank=rank,
            level=level,
            class=class,
            zone=zone,
            online=online,
            classFileName=classFileName,
            subgroup=subgroup,
            index=ci, --TODO how is this output behaving for half-empty groups?
            }

            -- Save detected class in database
            RIC.db.realm.KnownPlayerClasses[name] = RIC.classFilenameToIndex(classFileName)
        end
    end
    return raidMemberList
end

function RIC.rtrim(s)
  local n = #s
  while n > 0 and s:find("^%s", n) do n = n - 1 end
  return s:sub(1, n)
end

function RIC.reverseMap(assocTable)
    local reversed = {}
	for key, val in pairs(assocTable) do
		reversed[val] = key
	end
    return reversed
end

function RIC.tabLength(assocTable)
    if assocTable == nil then
        return 0
    end

    if type(assocTable) ~= "table" then
        return 0
    end

    local n = 0
    for k,v in pairs(assocTable) do
        n = n+1
    end
    return n
end
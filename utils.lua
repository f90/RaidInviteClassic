local addonName, RIC = ...
-- Class list lookup table (classFilename -> Localised Name) - Make sure to call this exactly ONCE before its needed!
local classFilenameToIndexTable, classIndexToFilenameTable, output, reversed = {}, {}, {}, {}
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

function RIC.trim_special_chars(char_name)
    return char_name:gsub("[%c%p%s]", "")
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

function RIC.charLength(str)
	local b = string.byte(str, 1)
	if b then
		if b >= 194 and b < 224 then
			return 2
		elseif b >= 224 and b < 240 then
			return 3
		elseif b >= 240 and b < 245 then
			return 4
		end
	end
	return 1
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
        SendChatMessage(RIC._ChatString .. " " .. msg, chatType, language, channel)
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

function RIC.countFrequency(list, value)
    local n = 0
    for k,v in pairs(list) do
        if v == value then
            n = n+1
        end
    end
    return n
end

function RIC.getRaidMembers()
    wipe(output)
    for ci=1, MAX_RAID_MEMBERS do
        local name, rank, subgroup, level, class, classFileName, zone, online, isDead, role, isML = GetRaidRosterInfo(ci)
        -- Set online to boolean variable
        if (online == 1) or (online == true) then
            online = true
        else
            online = false
        end

        if name ~= nil then
            -- Add player
            output[name] = {
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
    return output
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
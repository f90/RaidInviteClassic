
--Based on that: Symbols
RIC_Status = {
    READY=1,
    EXTRA=2,
    NOT_INVITED=3,
    INVITE_PENDING=4,
    INVITE_FAILED=5,
    MISSING=6,
    OTHER=7
}

RIC_InviteStatus = {
    NOT_INVITED=1,
    INVITE_PENDING=2,
    INVITE_FAILED=3
}

function trim_name(char_name)
    return char_name:gsub("[%c%p%s]", "")
end

function getStatusSymbol(in_raid, in_roster, online, invite_status)
    --Checkmark - In Raid + In Roster
    --Plus symbol - In Raid + Not In Roster
    --Neutral symbol - Not in Raid + Online + In Roster + NOT_INVITED
    --Dots symbol - Not in Raid + Online + In Roster + INVITE_PENDING
    --Cross symbol - Not in Raid + Online + In Roster + INVITE_FAILED
    --Red lightning symbol - Not in Raid + Offline + In Roster
    --Question mark symbol - Everything else

    if in_raid and in_roster then
        return RIC_Status["READY"]
    elseif in_raid and (not in_roster) then
        return RIC_Status["EXTRA"]
    elseif (not in_raid) and (online==1) and in_roster and ((invite_status==RIC_InviteStatus["NOT_INVITED"]) or (invite_status == nil)) then
        return RIC_Status["NOT_INVITED"]
    elseif (not in_raid) and (online==1) and in_roster and (invite_status==RIC_InviteStatus["INVITE_PENDING"]) then
        return RIC_Status["INVITE_PENDING"]
    elseif (not in_raid) and (online==1) and in_roster and (invite_status==RIC_InviteStatus["INVITE_FAILED"]) then
        return RIC_Status["INVITE_FAILED"]
    elseif (not in_raid) and (online==0) and in_roster then
        return RIC_Status["MISSING"]
    else
        return RIC_Status["OTHER"]
    end
end

RIC_ColorTable = {
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

function getClassColor(classFilename)
    local color = "|cffffffff"
    if RIC_ColorTable[classFilename] then
        color = "|cFF" .. RIC_ColorTable[classFilename]
    end
    return color
end

function printRIC(text)
    print("|cFFFF0000Raid Invite Classic|r: " .. text)
end

function removeServerFromName(name)
    -- Removes server names from full names, e.g. "Tim-Patchwerk" -> "Tim"
    local dashPosStart, dashPosEnd = string.find(name, "-")
    if dashPosStart ~= nil then -- Check if name has a dash in it
        return strsub(name, 1, dashPosStart-1)
    else
        return name -- No dash found - we have to assume there was no server name and this is already the correct  character name
    end
end

function countFrequency(list, value)
    n = 0
    for k,v in pairs(list) do
        if v == value then
            n = n+1
        end
    end
    return n
end

function getRaidMembers()
    local output = {}
    for ci=1, MAX_RAID_MEMBERS do
        local name, rank, subgroup, level, class, classFileName, zone, online, isDead, role, isML = GetRaidRosterInfo(ci)
        if online == nil then
            online = 0 -- 0 if offline, 1 if online
        end

        if name ~= nil then
            output[name] = {
            rank=rank,
            level=level,
            class=class,
            zone=zone,
            online=online,
            classFileName=classFileName,
            color=getClassColor(classFileName)
            }
        end
    end
    return output
end

function hashLength(assocTable)
    local n = 0
    if assocTable == nil then
        return 0
    end

    for k,v in pairs(assocTable) do
        n = n+1
    end
    return n
end
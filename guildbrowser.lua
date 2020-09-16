local sortMethod = "asc"
local currSortIndex = 1
local guildList = {}
local guildOffset = 0
local selectedList = {}
local totalGuildNumber = 0
local totalNumber = 0

function RIC_Guild_Browser.setVisibleRanks()
	local numRanks = GuildControlGetNumRanks()
	for i, val in ipairs(RIC.db.profile.DisplayRanks) do
		if i <= numRanks then
			_G["RIC_ShowRank"..i]:Show()
			_G["RIC_ShowRank"..i.."Text"]:SetText(GuildControlGetRankName(i))
			_G["RIC_ShowRank"..i]:SetChecked(val)
		else
			_G["RIC_ShowRank"..i]:Hide()
		end
	end
end

function RIC_Guild_Browser.updateOffset(val)
	-- Activates when slider is dragged, gives continuous value -> change to integer
	guildOffset = math.floor(val)
	RIC_Guild_Browser.updateListing()
end

-- Function: buildGuildList
-- Purpose: Builds data for listing guild members
function RIC_Guild_Browser.buildGuildList()
	totalGuildNumber = 0
	totalNumber = 0
	guildList = {}

	local guildMembers = RIC_Guild_Manager.getGuildMembers()

	for name, data in pairs(guildMembers) do
		if RIC.db.profile.ShowOffline or data["online"] then
			if RIC.db.profile.DisplayRanks[data["rankIndex"]] then
				totalGuildNumber = totalGuildNumber+1
				table.insert(guildList, {
							 name,
							 data["rank"],
							 data["rankIndex"],
							 data["classFileName"],
							 data["online"]
						})
			end
		end
	end

	-- Clear selection from people who are not shown
	local newSelectedList = {}
	for _, val in ipairs(guildList) do
		if selectedList[val[1]] ~= nil then
			newSelectedList[val[1]] = 1
		end
	end
	selectedList = newSelectedList

	-- Set up sliders
	if totalGuildNumber > 20 then
		local newVal = totalGuildNumber-20
		_G["RIC_GuildSliderContainer"]:Show()
		_G["RIC_GuildSlider"]:SetValueStep(1)
		if guildOffset > newVal then
			guildOffset = newVal
		else
			guildOffset = math.floor(_G["RIC_GuildSlider"]:GetValue())
		end
		_G["RIC_GuildSlider"]:SetMinMaxValues(0, newVal)
		_G["RIC_GuildSlider"]:SetValue(_G["RIC_GuildSlider"]:GetValue())
	else
		guildOffset = 0
		_G["RIC_GuildSliderContainer"]:Hide()
		_G["RIC_GuildSlider"]:SetValue(guildOffset)
	end

	RIC_Guild_Browser.sortTable(currSortIndex)
	RIC_Guild_Browser.updateListing()
end

-- Function: updateListing
-- Purpose: Displays the data for the faux
--		scrolling table.
function RIC_Guild_Browser.updateListing()
	for ci = 1, 20 do
		local theRow = guildList[ci+guildOffset]
		if theRow then
			_G["RIC_GuildMemberFrameEntry"..ci.."Name"]:SetText(getClassColor(theRow[4]) .. theRow[1])
			if theRow[5] then
				_G["RIC_GuildMemberFrameEntry"..ci.."Rank"]:SetText(theRow[2])
			else
				_G["RIC_GuildMemberFrameEntry"..ci.."Rank"]:SetText(GRAY_FONT_COLOR_CODE .. theRow[2])
			end
			_G["RIC_GuildMemberFrameEntry"..ci]:Show()
			local theName = theRow[1]
			if selectedList[theName] ~= nil then
				_G["RIC_GuildMemberFrameEntry"..ci.."Check"]:Show()
			else
				_G["RIC_GuildMemberFrameEntry"..ci.."Check"]:Hide()
			end

		else
			_G["RIC_GuildMemberFrameEntry"..ci]:Hide()
		end
	end
end

function RIC_Guild_Browser.addSelectedToRoster()
	-- Fetch names of selected people and add to roster
	for _, val in ipairs(guildList) do
		if selectedList[val[1]] ~= nil then
			RIC_Roster_Browser.addFromGuildBrowser(val[1])
		end
	end
	-- Reset selection --TODO maybe dont show people at all in guild list that are already in roster
	RIC_Guild_Browser.clearSelection()
	-- Rebuild rosterRaidList
	RIC_Roster_Browser.buildRosterRaidList()
end

function RIC_Guild_Browser.clearSelection()
	selectedList = {}
	RIC_Guild_Browser.updateListing()
end

function RIC_Guild_Browser.selectAll()
	selectedList = {}
	local guildMembers = RIC_Guild_Manager.getGuildMembers()
	for name, data in pairs(guildMembers) do
		if RIC.db.profile.ShowOffline or data["online"] then
			if RIC.db.profile.DisplayRanks[data["rankIndex"]] then
				selectedList[name] = 1
			end
		end
	end
	RIC_Guild_Browser.updateListing()
end

function RIC_Guild_Browser.selectRow(rowNum)
	local theRow = guildList[rowNum+guildOffset]
	if theRow then
		local theName = theRow[1]
		if theName then
			if selectedList[theName] ~= nil then
				selectedList[theName] = nil
			else
				selectedList[theName] = 1
			end
		end
	end

	RIC_Guild_Browser.updateListing()
end


function RIC_Guild_Browser.rankBoxToggle(numID)
	local toggleCheck = _G["RIC_ShowRank"..numID]:GetChecked()
	RIC.db.profile.DisplayRanks[numID] = toggleCheck
	RIC_Guild_Browser.buildGuildList()
end

function RIC_Guild_Browser.offlineBoxToggle()
	local toggleCheck = _G["RIC_ShowOfflineBox"]:GetChecked()
	RIC.db.profile.ShowOffline = toggleCheck
	RIC_Guild_Browser.buildGuildList()
end

function RIC_Guild_Browser.sliderButtonPushed(dir)
	local currValue = math.floor(_G["RIC_GuildSlider"]:GetValue())
	if (dir == 1) and currValue > 0 then
		newVal = currValue-3
		if newVal < 0 then
			newVal = 0
		end
		_G["RIC_GuildSlider"]:SetValue(newVal)
	elseif (dir == 2) and (currValue < (totalGuildNumber-20)) then
		newVal = currValue+3
		if newVal > (totalGuildNumber-20) then
			newVal = (totalGuildNumber-20)
		end
		_G["RIC_GuildSlider"]:SetValue(newVal)
	end
end

function RIC_Guild_Browser.quickScroll(self, delta)
	local currValue = math.floor(_G["RIC_GuildSlider"]:GetValue())
	if (delta > 0) and currValue > 0 then
		newVal = currValue-1
		if newVal < 0 then
			newVal = 0
		end
		_G["RIC_GuildSlider"]:SetValue(newVal)
	elseif (delta < 0) and (currValue < (totalGuildNumber-20)) then
		newVal = currValue+1
		if newVal > (totalGuildNumber-20) then
			newVal = (totalGuildNumber-20)
		end
		_G["RIC_GuildSlider"]:SetValue(newVal)
	end
end

function RIC_Guild_Browser.SystemFilter(chatFrame, event, message)
	return true
end

function RIC_Guild_Browser.sortClicked(id)
	-- Update how we should be sorting
	if currSortIndex == id then -- if we're already sorting this one
		if sortMethod == "asc" then -- then switch the order
			sortMethod = "desc"
		else
			sortMethod = "asc"
		end
	elseif id then -- if we got a valid id
		currSortIndex = id -- then initialize our sort index
		sortMethod = "asc" -- and the order we're sorting in
	end

	-- Sort Table
	RIC_Guild_Browser.sortTable(currSortIndex)

	-- Update listing
	RIC_Guild_Browser.updateListing()
end

-- Function: sortTable
-- Input: Column Header to sort by
-- Purpose: Sorts the guild member listing table
--		so that it's easily viewable
function RIC_Guild_Browser.sortTable(id)
	if (id == 1) then -- Char Name sorting (alphabetically)
		table.sort(guildList, function(v1, v2)
			if sortMethod == "desc" then
				return v1 and v1[1] > v2[1]
			else
				return v1 and v1[1] < v2[1]
			end
		end)
	elseif (id == 2) then -- Guild Rank sorting (numerically)
		table.sort(guildList, function(v1, v2)
			if sortMethod == "desc" then
				return v1 and v1[3] > v2[3]
			else
				return v1 and v1[3] < v2[3]
			end
		end)
	elseif (id == 3) then -- Selected sorting
		table.sort(guildList, function(v1, v2)
			if v1 == nil then return false end
			if v2 == nil then return true end
			if sortMethod == "asc" then
				return ((selectedList[v1[1]] ~= nil) and (selectedList[v2[1]] == nil))
			else
				return ((selectedList[v2[1]] ~= nil) and (selectedList[v1[1]] == nil))
			end
		end)
	end
end
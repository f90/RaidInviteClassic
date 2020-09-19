local AceGUI = LibStub("AceGUI-3.0")
local LD = LibStub("LibDeflate")
local LSM = LibStub("LibSharedMedia-3.0")
local DEFAULT_FONT = LSM.MediaTable.font[LSM:GetDefault('font')]

local selectedRoster

-- Creates relevant GUI elements for the roster management window
function RIC:OnEnableRosterManagerView()
	selectedRoster = RIC.db.realm.CurrentRoster

	self.rosters = AceGUI:Create("Window")
	self.rosters:Hide()
	self.rosters:EnableResize(false)
	self.rosters:SetWidth(450)
	self.rosters:SetHeight(270)
	self.rosters:SetTitle("Manage rosters")
	self.rosters:SetLayout("Flow")
	--_G["GroupFrame"] = self.groups.frame -- TODO needed?
	--table.insert(UISpecialFrames, "GroupFrame")
	self:HookScript(self.rosters.frame, "OnShow", function() RIC_Roster_Manager.draw() end)

	local rosterList = AceGUI:Create("InlineGroup")
	rosterList:SetWidth(200)
	rosterList:SetHeight(200)
	rosterList:SetTitle("Select roster")
	rosterList:SetLayout("Fill")
	rosterList.scroll = AceGUI:Create("ScrollFrame")
	rosterList.scroll:SetLayout("Flow")
	rosterList.scroll.rosters = {}
	rosterList:AddChild(rosterList.scroll)
	self.rosters.rosterList = rosterList
	self.rosters:AddChild(self.rosters.rosterList)

	-- Roster controls
	self.rosters.rosterControls = AceGUI:Create("InlineGroup")
	self.rosters.rosterControls:SetWidth(220)
	self.rosters.rosterControls:SetHeight(350)
	self.rosters.rosterControls:SetTitle("Roster controls")
	self.rosters.rosterControls:SetLayout("List")
	self.rosters:AddChild(self.rosters.rosterControls)

	self.rosters.rosterControls.add = AceGUI:Create("Button")
	self.rosters.rosterControls.add:SetText("Add roster")
	self.rosters.rosterControls.add:SetCallback("OnClick", function() StaticPopup_Show("NEW_ROSTER_ENTRY") end)
	self.rosters.rosterControls:AddChild(self.rosters.rosterControls.add)

	self.rosters.rosterControls.rename = AceGUI:Create("Button")
	self.rosters.rosterControls.rename:SetText("Rename selected roster")
	self.rosters.rosterControls.rename:SetCallback("OnClick", function() StaticPopup_Show("RENAME_ROSTER_ENTRY") end)
	self.rosters.rosterControls:AddChild(self.rosters.rosterControls.rename)

	self.rosters.rosterControls.copy = AceGUI:Create("Button")
	self.rosters.rosterControls.copy:SetText("Copy selected roster")
	self.rosters.rosterControls.copy:SetCallback("OnClick", function() RIC_Roster_Manager.copy() end)
	self.rosters.rosterControls:AddChild(self.rosters.rosterControls.copy)

	self.rosters.rosterControls.delete = AceGUI:Create("Button")
	self.rosters.rosterControls.delete:SetText("Delete selected roster")
	self.rosters.rosterControls.delete:SetCallback("OnClick", function() RIC_Roster_Manager.delete() end)
	self.rosters.rosterControls:AddChild(self.rosters.rosterControls.delete)

	self.rosters.rosterControls.fetch = AceGUI:Create("Button")
	self.rosters.rosterControls.fetch:SetText("Fetch rosters")
	self.rosters.rosterControls.fetch:SetCallback("OnClick", function() RIC_Roster_Manager.requestRosters() end)
	self.rosters.rosterControls:AddChild(self.rosters.rosterControls.fetch)

	self.rosters.rosterControls.send = AceGUI:Create("Button")
	self.rosters.rosterControls.send:SetText("Send rosters")
	self.rosters.rosterControls.send:SetCallback("OnClick", function() StaticPopup_Show("SEND_ROSTERS_WARNING") end)
	self.rosters.rosterControls:AddChild(self.rosters.rosterControls.send)

	self.rosters.confirm = AceGUI:Create("Button")
	self.rosters.confirm:SetText("Use selected roster")
	self.rosters.confirm:SetCallback("OnClick", function() RIC_Roster_Manager.confirm() end)
	self.rosters.rosterList:AddChild(self.rosters.confirm)

	AceGUI:RegisterLayout("RostersLayout", function()
		self.rosters.rosterControls:SetPoint("TOPLEFT", self.rosters.rosterList.frame, "TOPRIGHT", 10, 0)
		self.rosters.confirm:SetPoint("BOTTOMLEFT", self.rosters.rosterList.frame, "BOTTOMRIGHT", 20, 5)
	end)
	self.rosters:SetLayout("RostersLayout")
	self.rosters:DoLayout()

	self.rosters.rosterList.labels = {}

	-- Add new roster popup entry
	StaticPopupDialogs["NEW_ROSTER_ENTRY"] = {
		text = "Name of new roster:",
		button1 = "OK",
		button2 = "Cancel",
		timeout = 0,
		hasEditBox = true,
		whileDead = true,
		hideOnEscape = true,
		enterClicksFirstButton = true,
		preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
		OnShow = function (self, data)
			-- Set edit box scripts to hide popup on escape/enter, and to process name on enter
    		self.editBox:SetScript("OnEscapePressed", function(self)
				StaticPopup_Hide("NEW_ROSTER_ENTRY")
			end)
			self.editBox:SetScript("OnEnterPressed", function(self)
				local text = self:GetText()
				StaticPopup_Hide("NEW_ROSTER_ENTRY")
				RIC_Roster_Manager.add(text)
			end)
		end,
		OnAccept = function(self, data, data2)
			local text = self.editBox:GetText()
			RIC_Roster_Manager.add(text)
		end,
	}

	-- Rename roster popup entry
	StaticPopupDialogs["RENAME_ROSTER_ENTRY"] = {
		text = "Rename selected roster to:",
		button1 = "OK",
		button2 = "Cancel",
		timeout = 0,
		hasEditBox = true,
		whileDead = true,
		hideOnEscape = true,
		enterClicksFirstButton = true,
		preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
		OnShow = function (self, data)
			-- Set edit box scripts to hide popup on escape/enter, and to process name on enter
    		self.editBox:SetScript("OnEscapePressed", function(self)
				StaticPopup_Hide("RENAME_ROSTER_ENTRY")
			end)
			self.editBox:SetScript("OnEnterPressed", function(self)
				local text = self:GetText()
				StaticPopup_Hide("RENAME_ROSTER_ENTRY")
				RIC_Roster_Manager.rename(text)
			end)
		end,
		OnAccept = function(self, data, data2)
			local text = self.editBox:GetText()
			RIC_Roster_Manager.rename(text)
		end,
	}

		-- Rename roster popup entry
	StaticPopupDialogs["SEND_ROSTERS_WARNING"] = {
		text = "This will overwrite ALL roster lists of ALL recipients! Do you want to continue?",
		button1 = "OK",
		button2 = "Cancel",
		timeout = 0,
		hasEditBox = false,
		whileDead = true,
		hideOnEscape = true,
		enterClicksFirstButton = true,
		preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
		OnAccept = function(self, data, data2)
			RIC_Roster_Manager.send()
		end,
	}
end

function RIC_Roster_Manager.draw()
	-- Show all available rosters
	local rosterNum = 1
	for rosterName, _ in pairs(RIC.db.realm.RosterList) do
		local label
		if rosterNum <= #RIC.rosters.rosterList.labels then
			-- Fetch already existing label
			label = RIC.rosters.rosterList.labels[rosterNum]
		else
			-- Create new label for the first time
			label = AceGUI:Create("InteractiveLabel")
			label:SetFont(DEFAULT_FONT, 12)
			label:SetJustifyH("CENTER")
			label:SetHighlight("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
			label:SetWidth(161)
			label:SetHeight(20)

			label:SetCallback("OnClick", function(self, _, button)
				if button == "LeftButton" then
					RIC_Roster_Manager.select(self)
				end
			end)

			-- Add new label
			RIC.rosters.rosterList.scroll:AddChild(label)
			table.insert(RIC.rosters.rosterList.labels, label)
		end

		-- Update label
		label.rosterName = rosterName
		if rosterName == selectedRoster then
			label:SetText(">> " .. rosterName .. " <<")
			label:SetColor(1.0, 1.0, 0.0)
		else
			label:SetText(rosterName)
			label:SetColor(1.0, 1.0, 1.0)
		end
		rosterNum = rosterNum + 1
	end
	-- Delete extra labels
	while rosterNum <= #RIC.rosters.rosterList.labels do
		RIC.rosters.rosterList.labels[rosterNum].name = nil
		RIC.rosters.rosterList.labels[rosterNum]:SetText(nil)
		rosterNum = rosterNum + 1
	end
end

function RIC_Roster_Manager.select(label)
	selectedRoster = label.rosterName
	RIC_Roster_Manager.draw()
end

function RIC_Roster_Manager.add(rosterName)
	if RIC.db.realm.RosterList[rosterName] ~= nil then
		message("A roster named " .. rosterName .. " already exists!")
		return false
	else
		RIC.db.realm.RosterList[rosterName] = {}
		RIC_Roster_Manager.draw()
		return true
	end
end

function RIC_Roster_Manager.rename(newRosterName)
	-- Add new roster with new name
	local success = RIC_Roster_Manager.copy(newRosterName)
	if success == true then
		-- Copy succeeded => We can safely delete current roster
		RIC_Roster_Manager.delete() -- Delete selected roster
		selectedRoster = newRosterName -- Select roster under new name
		RIC_Roster_Manager.draw() -- Redraw
	end
end

function RIC_Roster_Manager.copy(newRosterName)
	local rosterCopy = {}
	for key, val in pairs(RIC.db.realm.RosterList[selectedRoster]) do
		rosterCopy[key] = val
	end
	if newRosterName == nil then -- Normal copy button creates a copy with default name
		newRosterName = selectedRoster .. " - Copy"
	end

	-- Only copy if we are not overwriting existing roster
	if RIC.db.realm.RosterList[newRosterName] ~= nil then
		message("A roster named " .. newRosterName .. " already exists!")
		return false -- Indicate that we failed copying and nothing changed
	else
		RIC.db.realm.RosterList[newRosterName] = rosterCopy
		RIC_Roster_Manager.draw()
		return true -- Success!
	end
end

function RIC_Roster_Manager.delete()
	-- Make sure we always have at least ONE roster to work with!
	if hashLength(RIC.db.realm.RosterList) > 1 then
		RIC.db.realm.RosterList[selectedRoster] = nil
		for rosterName, rosterData in pairs(RIC.db.realm.RosterList) do
			if selectedRoster == RIC.db.realm.CurrentRoster then -- If this was the roster we are currently using, switch to another one
				RIC.db.realm.CurrentRoster = rosterName
			end
			selectedRoster = rosterName
			break
		end
		RIC_Roster_Manager.draw()
	else
		message("There needs to be at least one roster.")
	end
end

function RIC_Roster_Manager.confirm()
	RIC.db.realm.CurrentRoster = selectedRoster
	RIC.rosters:Hide()

	-- Update views
	RIC_Roster_Browser.buildRosterRaidList()
	RIC_Group_Manager.draw(true)
end

function RIC_Roster_Manager.toggle()
	if RIC.rosters:IsShown() == true then
		RIC.rosters:Hide()
	else
		RIC.rosters:Show()
		RIC_Roster_Manager.draw()
	end
end

function RIC_Roster_Manager.requestRosters()
	local message = {
		key = "ASK_ROSTERS",
	}
	SendComm(message)
end

function RIC_Roster_Manager.addReceivedRosters(rosterLists)
	-- Build union of current roster lists and received ones, overwriting our local lists in case of duplicate names
	for rosterName, rosterList in pairs(rosterLists) do
		RIC.db.realm.RosterList[rosterName] = rosterList
	end
	RIC_Roster_Manager.draw()
	RIC_Roster_Browser.buildRosterRaidList()
	RIC_Group_Manager.draw(true)
end

function RIC_Roster_Manager.isValidRosterList(rosterLists)
	if rosterLists == nil or hashLength(rosterLists) == 0 then
		return false
	end
	for k,v in pairs(rosterLists) do
		if v == nil then
			return false
		end
	end
	-- TODO Potentially more checks here (content of entries etc)
	return true
end

function RIC_Roster_Manager.setReceivedRosters(rosterLists)
	-- Make sure the new list is a valid roster list, otherwise don't accept list
	if not RIC_Roster_Manager.isValidRosterList(rosterLists) then
		return
	end

	-- Our current roster name might not be available anymore - in this case, switch current roster to an existing one!
	local newRosterName = getSortedTableKeys(rosterLists)[1]
	if rosterLists[RIC.db.realm.CurrentRoster] == nil then
		RIC.db.realm.CurrentRoster = newRosterName
	end
	if rosterLists[selectedRoster] == nil then
		selectedRoster = newRosterName
	end

	-- Overwrite our own roster lists with the received ones
	RIC.db.realm.RosterList = rosterLists

	RIC_Roster_Manager.draw()
	RIC_Roster_Browser.buildRosterRaidList()
	RIC_Group_Manager.draw(true)
end

function RIC_Roster_Manager.send()
	local msg = {
		key = "OVERWRITE_ROSTERS",
		sender = UnitName("player"),
		value = RIC.db.realm.RosterList,
	}
	SendComm(msg)
end
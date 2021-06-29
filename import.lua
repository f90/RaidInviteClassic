local addonName, RIC = ...
local AceGUI = LibStub("AceGUI-3.0")
local LD = LibStub("LibDeflate")
local LSM = LibStub("LibSharedMedia-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local DEFAULT_FONT = LSM.MediaTable.font[LSM:GetDefault('font')]
local newList = {}

function RIC:OnEnableImportView()
	self.import = AceGUI:Create("Window")
	self.import:Hide()
	self.import:EnableResize(false)
	self.import:SetTitle("Import roster list")
	self.import:SetLayout("Flow")
	--self:HookScript(self.import.frame, "OnShow", function() RIC._Group_Manager.draw() end)
	--self:HookScript(self.import.frame, "OnHide", function() _G["RIC_OpenGroupWindow"]:SetText("View groups") end)
	self.import:SetWidth(250)
	self.import:SetHeight(380)

	self.import.container = AceGUI:Create("SimpleGroup")
	self.import.container:SetFullWidth(true)
	self.import.container:SetFullHeight(true)
	self.import.container:SetLayout("Fill") -- important!
	self.import:AddChild(self.import.container)

	self.import.scroll = AceGUI:Create("ScrollFrame")
	self.import.scroll:SetLayout("Flow")
	self.import.container:AddChild(self.import.scroll)

	self.import.editbox = AceGUI:Create("MultiLineEditBox")
	self.import.editbox:SetLabel("Roster List")
	self.import.editbox:SetCallback("OnEnterPressed", RIC._Import_Manager.confirmRoster)
	self.import.editbox:SetNumLines(20)
	self.import.scroll:AddChild(self.import.editbox)
end

function RIC._Import_Manager.toggle()
    if RIC.import:IsShown() == true then
		RIC.import:Hide()
	else
		RIC.import:Show()
		RIC.import.editbox:SetText(RIC._Import_Manager.generateRosterList())
		RIC.import.editbox:HighlightText()
		RIC.import.editbox:SetFocus()
	end
end

function RIC._Import_Manager.confirmRoster()
	RIC._Import_Manager.importRoster(RIC.import.editbox:GetText())

	-- Update views
	RIC._Roster_Browser.buildRosterRaidList()
	RIC._Group_Manager.draw(true)
	RIC.import.editbox:SetText(RIC._Import_Manager.generateRosterList())
	RIC.import:Hide()
end

function RIC._Import_Manager.importRoster(rosterString)
	-- Use newlines, colons, comma or space to separate characters
	local swapString = gsub(rosterString, ";", "\n")
	swapString = gsub(swapString, ",", "\n")
	swapString = gsub(swapString, " ", "\n")
	local parsedList = { strsplit("\n", swapString) }

	-- Determine whether list is unordered (ONE separator in beginning) or not
	local useGroupPositions = true
	if (#parsedList > 1) -- We immediately encounter ONE separator - this means group positions are NOT used at all!
			and (string.utf8len(RIC.trim_char_name(parsedList[1])) == 0)
			and (string.utf8len(RIC.trim_char_name(parsedList[2])) > 0) then
				useGroupPositions = false
	end
	-- Parse names one by one, add to temp list
	wipe(newList)
	local skippedNames = ""
	local fixedNames = ""
	for i, val in ipairs(parsedList) do
		-- Clean up name input
		local orig_char_name, _ = RIC.split_char_name(val)
		local name = RIC.trim_char_name(RIC.addServerToName(val))
		local char_name, _ = RIC.split_char_name(name)

		if char_name ~= orig_char_name then
			-- We removed special chars from the input in hopes of fixing the char name - notify user!
			fixedNames = fixedNames .. orig_char_name .. " -> " .. char_name .. "\n"
		end
		if string.utf8len(char_name) > 1 and string.utf8len(char_name) < 13 then -- Char names in WoW need to be between 2 and 12 (inclusive) chars long
			if i <= 40 and useGroupPositions then -- Use group positions for first 40 raiders?
				if not newList[name] then -- If we encounter a duplicate, don't reset the first position we found
					newList[name] = i
				end
			else
				newList[name] = 0
			end
		else
			if string.utf8len(char_name) > 0 then -- Add to list of skipped names if they are faulty and are non empty
				skippedNames = skippedNames .. val .. "\n"
			end
		end
	end

	-- If we skipped some names because they were faulty, show warning message on import
	local warningMsg = ""
	if string.utf8len(skippedNames) > 0 then
		warningMsg = warningMsg .. L["Roster_Import_Name_Skip_Warning"] .. "\n" .. skippedNames
	end
	if string.utf8len(fixedNames) > 0 then
		warningMsg = warningMsg .. L["Roster_Import_Name_Fix_Warning"] .. "\n" .. fixedNames
	end
	if string.utf8len(warningMsg) > 0 then
		message(warningMsg)
	end

	-- If we have a non-empty list, we parsed successfully: Overwrite current roster list
	if RIC.tabLength(newList) > 0 then
		RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster] = RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster] or {}
		wipe(RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster])
		for k,v in pairs(newList) do
			RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster][k] = v
		end
	end
end

-- Generates a list of names based on current roster list
function RIC._Import_Manager.generateRosterList()
	-- Determine whether ANY players are assigned to a specific group/position
	local positionToName = RIC.reverseMap(RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster])
	local rosterString = ""
	local useGroupPositions = false
	for position=1,40 do
		if positionToName[position] ~= nil then
			rosterString = rosterString .. positionToName[position] .. "\n"
			useGroupPositions = true
		else
			rosterString = rosterString .. "\n"
		end
	end

	if useGroupPositions then
		-- We already have the list except for the unassigned players
		for name, position in pairs(RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster]) do
			if position == 0 then
				rosterString = rosterString .. name .. "\n"
			end
		end
	else
		-- Don't use group positions at all - in this case, put single separator in the beginning, then normal dump
		if RIC.tabLength(RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster]) > 0 then
			rosterString = "\n"
			for name, _ in pairs(RIC.db.realm.RosterList[RIC.db.realm.CurrentRoster]) do
				rosterString = rosterString .. name .. "\n"
			end
		else
			rosterString = ""
		end
	end

	-- Cut off extra separator symbols at the end since they are redundant
	rosterString = RIC.rtrim(rosterString)

	return rosterString
end
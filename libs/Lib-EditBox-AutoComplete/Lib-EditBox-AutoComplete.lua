local LIBRARY_NAME = "AceGUI-3.0-EditBox-AutoComplete";
local VERSION = 1;
local AceGUI;
local maximumButtonCount = 5;

if LibStub then
	AceGUI = LibStub("AceGUI-3.0")
	if AceGUI then
		local lib = LibStub:NewLibrary(LIBRARY_NAME,VERSION)
		if not lib then return end

		AceGUI:RegisterWidgetType ("EditBox-AutoComplete", function()
			local e = AceGUI:Create("EditBox")
			SetupAutoComplete(e.editbox)
			e.SetValueList = function(self,valueList)
				self.editbox.valueList = valueList
			end
			e.SetButtonCount = function(self,buttonCount)
				self.editbox.buttonCount = buttonCount
			end
			e.AddHighlightedText = function(self,addHighlightedText)
				self.editbox.addHighlightedText = addHighlightedText
			end

			return e 
		end, VERSION)
	end
end

function SetupAutoComplete(editbox, valueList, maxButtonCount)
	editbox.old_OnEnterPressed = editbox.old_OnEnterPressed or editbox:GetScript("OnEnterPressed")
	editbox.old_OnTextChanged = editbox.old_OnTextChanged or editbox:GetScript("OnTextChanged")
	editbox.old_OnEscapePressed = editbox.old_OnEscapePressed or editbox:GetScript("OnEscapePressed") -- ADDED to ensure proper closing of window on escape press

	editbox:SetScript("OnTabPressed", EditBoxAutoComplete_OnTabPressed)
	editbox:SetScript("OnEnterPressed", function(editbox)
		editbox.autoCompleted = EditBoxAutoComplete_OnEnterPressed(editbox) -- ADDED so original OnEnterPressed script can switch behaviour depending on whether an auto complete was performed
		return editbox.old_OnEnterPressed(editbox)
	end)
	editbox:SetScript("OnTextChanged", function(editbox, changedByUser)
		EditBoxAutoComplete_OnTextChanged(editbox,changedByUser)
		return editbox.old_OnTextChanged(editbox)
	end)
	editbox:SetScript("OnChar", EditBoxAutoComplete_OnChar)
	editbox:SetScript("OnEditFocusLost", function(editbox)
		EditBoxAutoComplete_HideIfAttachedTo(editbox)
		EditBox_ClearHighlight(editbox)
	end)
	editbox:SetScript("OnEscapePressed", function(editbox)
		if not EditBoxAutoComplete_OnEscapePressed(editbox) then
			if AceGUI then
				AceGUI:ClearFocus(editbox.obj)
			else
				editbox:ClearFocus()
			end
			editbox.autoCompleteEscaped = false
		else
			editbox.autoCompleteEscaped = true
		end
		editbox.old_OnEscapePressed(editbox) -- ADDED to ensure proper closing of window on escape press
	end)

	editbox.valueList = valueList or {}
	editbox.buttonCount = maxButtonCount or 10;
	editbox.addHighlightedText = true
end

local function GetAutoCompleteButton(index)
	local buttonName = "EditBoxAutoCompleteButton"..index;
	if not _G[buttonName] then
		local btn = CreateFrame("Button",buttonName,EditBoxAutoCompleteBox,"EditBoxAutoCompleteButtonTemplate")
		btn:SetPoint("TOPLEFT",GetAutoCompleteButton(index-1),"BOTTOMLEFT",0,0)
		_G[buttonName] = btn		
		EditBoxAutoCompleteBox.existingButtonCount = max(index, EditBoxAutoCompleteBox.existingButtonCount or 1)
	end
	return _G[buttonName];
end
	

	
local function GetEditBoxAutoCompleteResults(text,valueList)
	local results = {}
	local resultsCount = 1
	
	pcall(function() 
		for i,value in ipairs(valueList) do
			pcall(function() 
				if string.find(value:lower(),text:lower()) == 1 then
					results[resultsCount] = value;
					resultsCount = resultsCount + 1
				end
			end)		
		end
	end)		
	
	return results;
end

function EditBoxAutoComplete_OnLoad(self)
	-- Add backdrop
	if BackdropTemplateMixin then -- For WoW >9.0 version
		self.background = CreateFrame("Frame", nil, self, "BackdropTemplate")
		self.background:SetAllPoints()
		backdropInfo = {
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 11, right = 12, top = 12, bottom = 9, },
		}
		self.background:SetBackdrop(backdropInfo)
		self.background:SetFrameLevel(self:GetFrameLevel())
	else -- WoW <9.0 version
		self:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
		self:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b);
	end
	AutoCompleteInstructions:SetText("|cffbbbbbb"..PRESS_TAB.."|r");
end

function EditBoxAutoComplete_Update(parent, text, cursorPosition)
	local self = EditBoxAutoCompleteBox;
	local attachPoint;
	if ( not text or text == "" ) then
		EditBoxAutoComplete_HideIfAttachedTo(parent);
		return;
	end
	if ( cursorPosition <= strlen(text) ) then
		self:SetParent(parent);
		if(self.parent ~= parent) then
			EditBoxAutoComplete_SetSelectedIndex(self, 0);
			self.parentArrows = parent:GetAltArrowKeyMode();
		end
		parent:SetAltArrowKeyMode(false);
		local height = GetAutoCompleteButton(1):GetHeight() * maximumButtonCount
		if ( parent:GetBottom() - height <= (AUTOCOMPLETE_DEFAULT_Y_OFFSET + 10) ) then	--10 is a magic number from the offset of AutoCompleteButton1.
			attachPoint = "ABOVE";
		else
			attachPoint = "BELOW";
		end
		if ( (self.parent ~= parent) or (self.attachPoint ~= attachPoint) ) then
			if ( attachPoint == "ABOVE" ) then
				self:ClearAllPoints();
				self:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", parent.autoCompleteXOffset or 0, parent.autoCompleteYOffset or -AUTOCOMPLETE_DEFAULT_Y_OFFSET);
			elseif ( attachPoint == "BELOW" ) then
				self:ClearAllPoints();
				self:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", parent.autoCompleteXOffset or 0, parent.autoCompleteYOffset or AUTOCOMPLETE_DEFAULT_Y_OFFSET);
			end
			self.attachPoint = attachPoint;
		end
		
		self.parent = parent;
		local possibilities = GetEditBoxAutoCompleteResults(text,parent.valueList);
		if (not possibilities) then
			possibilities = {};
		end
		EditBoxAutoComplete_UpdateResults(self, possibilities);
	else
		EditBoxAutoComplete_HideIfAttachedTo(parent);
	end
end

function EditBoxAutoComplete_HideIfAttachedTo(parent)
	local self = EditBoxAutoCompleteBox;
	if ( self.parent == parent ) then
		if( self.parentArrows ) then
			parent:SetAltArrowKeyMode(self.parentArrows);
			self.parentArrows = nil;
		end
		self.parent = nil;
		self:Hide();
	end
end

function EditBoxAutoComplete_SetSelectedIndex(self, index)
	self.selectedIndex = index;
	for i=1, maximumButtonCount do
		GetAutoCompleteButton(i):UnlockHighlight();
	end
	if ( index ~= 0 ) then
		GetAutoCompleteButton(index):LockHighlight();
	end
end

function EditBoxAutoComplete_GetSelectedIndex(self)
	return self.selectedIndex;
end

function EditBoxAutoComplete_GetNumResults(self)
	return self.numResults;
end

function EditBoxAutoComplete_UpdateResults(self, results)
	local totalReturns = #results;
	local numReturns = min(totalReturns, maximumButtonCount);
	local maxWidth = 150;
	for i=1, numReturns do
		local button = GetAutoCompleteButton(i)
		button.name = Ambiguate(results[i], "none");
		button:SetText(results[i]);
		maxWidth = max(maxWidth, button:GetFontString():GetWidth()+30);
		button:Enable();
		button:Show();
	end
	
	for i = numReturns+1, EditBoxAutoCompleteBox.existingButtonCount do
		GetAutoCompleteButton(i):Hide();
	end
	
	if ( numReturns > 0 ) then
		maxWidth = max(maxWidth, AutoCompleteInstructions:GetStringWidth()+30);
		self:SetHeight(numReturns*AutoCompleteButton1:GetHeight()+35);
		self:SetWidth(maxWidth);
		self:Show();
		EditBoxAutoComplete_SetSelectedIndex(self, 1);
	else
		self:Hide();
	end
		
	if ( totalReturns > maximumButtonCount )  then
		local button = GetAutoCompleteButton(maximumButtonCount);
		button:SetText(CONTINUED);
		button:Disable();
		self.numResults = numReturns - 1;
	else 
		self.numResults = numReturns;
	end
end

function EditBoxAutoComplete_IncrementSelection(editBox, up)
	local autoComplete = EditBoxAutoCompleteBox;
	if ( autoComplete:IsShown() and autoComplete.parent == editBox ) then
		local selectedIndex = EditBoxAutoComplete_GetSelectedIndex(autoComplete);
		local numReturns = EditBoxAutoComplete_GetNumResults(autoComplete);
		if ( up ) then
			local nextNum = mod(selectedIndex - 1, numReturns);
			if ( nextNum <= 0 ) then
				nextNum = numReturns;
			end
			EditBoxAutoComplete_SetSelectedIndex(autoComplete, nextNum);
		else
			local nextNum = mod(selectedIndex + 1, numReturns);
			if ( nextNum == 0 ) then
				nextNum = numReturns;
			end
			EditBoxAutoComplete_SetSelectedIndex(autoComplete, nextNum)
		end
		return true;
	end
	return false;
end

function EditBoxAutoComplete_OnTabPressed(editBox)
	return EditBoxAutoComplete_IncrementSelection(editBox, IsShiftKeyDown())
end

function EditBoxAutoComplete_OnArrowPressed(self, key)
	if ( key == "UP" ) then
		return EditBoxAutoComplete_IncrementSelection(self, true);
	elseif ( key == "DOWN" ) then
		return EditBoxAutoComplete_IncrementSelection(self, false);
	end
end

function EditBoxAutoComplete_OnEnterPressed(self)
	local autoComplete = EditBoxAutoCompleteBox;
	if ( autoComplete:IsShown() and (autoComplete.parent == self) and (EditBoxAutoComplete_GetSelectedIndex(autoComplete) ~= 0) ) then
		EditBoxAutoCompleteButton_OnClick(GetAutoCompleteButton(EditBoxAutoComplete_GetSelectedIndex(autoComplete)));
		return true;
	end
	return false;
end

function EditBoxAutoComplete_OnTextChanged(self, userInput)

	maximumButtonCount = self.buttonCount;
    if ( userInput ) then
        EditBoxAutoComplete_Update(self, self:GetText(), self:GetUTF8CursorPosition());
    end
    if(self:GetText() == "") then
        EditBoxAutoComplete_HideIfAttachedTo(self);
    end
end

function EditBoxAutoComplete_AddHighlightedText(editBox, text)
	local editBoxText = editBox:GetText();
	local utf8Position = editBox:GetUTF8CursorPosition();
	local possibilities = GetEditBoxAutoCompleteResults(text);
	
	if ( possibilities and possibilities[1] ) then
		--We're going to be setting the text programatically which will clear the userInput flag on the editBox. So we want to manually update the dropdown before we change the text.
		EditBoxAutoComplete_Update(editBox, editBoxText, utf8Position);
		local newText = string.gsub(editBoxText, AUTOCOMPLETE_SIMPLE_REGEX,
							string.format(AUTOCOMPLETE_SIMPLE_FORMAT_REGEX, possibilities[1],
								string.match(editBoxText, AUTOCOMPLETE_SIMPLE_REGEX)),
								1)
		editBox:SetText(newText);
		editBox:HighlightText(strlen(editBoxText), strlen(newText));	--This won't work if there is more after the name, but we aren't enabling this for normal chat (yet). Please fix me when we do.
		editBox:SetCursorPosition(strlen(editBoxText));
	end
end

function EditBoxAutoComplete_OnChar(self)
	if (self.addHighlightedText and self:GetUTF8CursorPosition() == strlenutf8(self:GetText())) then
		EditBoxAutoComplete_AddHighlightedText(self, self:GetText());
	end
end

function EditBoxAutoComplete_OnEditFocusLost(self)
	EditBoxAutoComplete_HideIfAttachedTo(self);
end

function EditBoxAutoComplete_OnEscapePressed(self)
	local autoComplete = EditBoxAutoCompleteBox;
	if ( autoComplete:IsShown() and autoComplete.parent == self ) then
		EditBoxAutoComplete_HideIfAttachedTo(self);
		return true;
	end
	return false;
end	

function EditBoxAutoCompleteButton_OnClick(self)
	local autoComplete = self:GetParent();
	local editBox = autoComplete.parent;
	local editBoxText = editBox:GetText();
	local newText;
	
	if (editBox.command) then
		newText = editBox.command.." "..self.name;
	else
		newText = string.gsub(editBoxText, AUTOCOMPLETE_SIMPLE_REGEX,
			string.format(AUTOCOMPLETE_SIMPLE_FORMAT_REGEX, self.name,
				string.match(editBoxText, AUTOCOMPLETE_SIMPLE_REGEX)),
				1);
	end
	
	editBox:SetText(newText);
	--When we change the text, we move to the end, so we'll be consistent and move to the end if we don't change it as well.
	editBox:SetCursorPosition(strlen(newText));
	autoComplete:Hide();
end
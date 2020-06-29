function RIC_MinimapButton_Update()
	if RIC.db.profile.MinimapShow then
		_G["RIC_MinimapButton"]:Show()
		RIC_MinimapButton_Reposition()
	else
		_G["RIC_MinimapButton"]:Hide()
	end
end

function RIC_MinimapButton_Reposition()
	local minimapShapes = {
		["ROUND"] = {true, true, true, true},
		["SQUARE"] = {false, false, false, false},
		["CORNER-TOPLEFT"] = {false, false, false, true},
		["CORNER-TOPRIGHT"] = {false, false, true, false},
		["CORNER-BOTTOMLEFT"] = {false, true, false, false},
		["CORNER-BOTTOMRIGHT"] = {true, false, false, false},
		["SIDE-LEFT"] = {false, true, false, true},
		["SIDE-RIGHT"] = {true, false, true, false},
		["SIDE-TOP"] = {false, false, true, true},
		["SIDE-BOTTOM"] = {true, true, false, false},
		["TRICORNER-TOPLEFT"] = {false, true, true, true},
		["TRICORNER-TOPRIGHT"] = {true, false, true, true},
		["TRICORNER-BOTTOMLEFT"] = {true, true, false, true},
		["TRICORNER-BOTTOMRIGHT"] = {true, true, true, false},
	}

	local angle = math.rad(RIC.db.profile.MinimapPos)
	local x, y, q = math.cos(angle), math.sin(angle), 1
	if x < 0 then q = q + 1 end
	if y > 0 then q = q + 2 end
	local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
	local quadTable = minimapShapes[minimapShape]
	local w = (Minimap:GetWidth() / 2)
	local h = (Minimap:GetHeight() / 2)
	if quadTable[q] then
		x, y = x*w, y*h
	else
		local diagRadiusW = math.sqrt(2*(w)^2)-10
		local diagRadiusH = math.sqrt(2*(h)^2)-10
		x = math.max(-w, math.min(x*diagRadiusW, w))
		y = math.max(-h, math.min(y*diagRadiusH, h))
	end
	x = (x * (-1)) -- Inverse x axis movement

	RIC_MinimapButton:SetPoint("CENTER","Minimap","CENTER",x,y)
end

-- Only while the button is dragged this is called every frame
function RIC_MinimapButton_DraggingFrame_OnUpdate()

	local xpos,ypos = GetCursorPosition()
	local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom()

	xpos = xmin-xpos/UIParent:GetScale()+70 -- get coordinates as differences from the center of the minimap
	ypos = ypos/UIParent:GetScale()-ymin-70

	RIC.db.profile.MinimapPos = math.deg(math.atan2(ypos,xpos)) -- save the degrees we are relative to the minimap center
	RIC_MinimapButton_Reposition() -- move the button
end

-- Put your code that you want on a minimap button click here.  arg1="LeftButton", "RightButton", etc
function RIC_MinimapButton_OnClick(button)
	if button == "LeftButton" then -- Toggle main frame visibility
		if RIC_MainFrame:IsShown() then
			RIC_MainFrame:Hide()
		else
			RIC_MainFrame:Show()
		end
	end
end

function RIC_MinimapButton_OnEnter(self)
	if (self.dragging) then
		return
	end
	GameTooltip:SetOwner(self or UIParent, "ANCHOR_LEFT")
	GameTooltip:SetText("Raid Invite Classic")
end
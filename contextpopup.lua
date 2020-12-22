local addonName, RIC = ...
-- POPUP MENU CODE BELOW
local PopupDepth
local function PopupClick(self, arg1, arg2, checked)
	if type(self.value)=="table" then
		self.value[arg1]=not self.value[arg1]
		self.checked=self.value[arg1]
		if arg2 then
			arg2(self.value,arg1,checked)
		end

	elseif type(self.value)=="function" then
		self.value(arg1,arg2)
	end
end

local function PopupAddItem(self,text,disabled,value,arg1,arg2)
	local c=self._Frame._GPIPRIVAT_Items.count+1
	self._Frame._GPIPRIVAT_Items.count=c

	if not self._Frame._GPIPRIVAT_Items[c] then
		self._Frame._GPIPRIVAT_Items[c]={}
	end
	local t=self._Frame._GPIPRIVAT_Items[c]
	t.text=text or ""
	t.disabled=disabled or false
	t.value=value
	t.arg1=arg1
	t.arg2=arg2
	t.MenuDepth=PopupDepth
end

local function PopupAddSubMenu(self,text,value)
	if text~=nil and text~="" then
		PopupAddItem(self,text,"MENU",value)
		PopupDepth=value
	else
		PopupDepth=nil
	end
end

local PopupLastWipeName
local function PopupWipe(self,WipeName)
	self._Frame._GPIPRIVAT_Items.count=0
	PopupDepth=nil
	if UIDROPDOWNMENU_OPEN_MENU == self._Frame then
		ToggleDropDownMenu(nil, nil, self._Frame, self._where, self._x, self._y)
		if WipeName == PopupLastWipeName then
			return false
		end
	end
	PopupLastWipeName=WipeName
	return true
end

local function PopupCreate(frame, level, menuList)
	if level==nil then return end
	local info = UIDropDownMenu_CreateInfo()

	for i=1,frame._GPIPRIVAT_Items.count do
		local val=frame._GPIPRIVAT_Items[i]
		if val.MenuDepth==menuList then
			if val.disabled=="MENU" then
				info.text=val.text
				info.notCheckable = true
				info.disabled=false
				info.value=nil
				info.arg1=nil
				info.arg2=nil
				info.func=nil
				info.hasArrow=true
				info.menuList=val.value
				--info.isNotRadio=true
			else
				info.text=val.text
				if type(val.value)=="table" then
					info.checked=val.value[val.arg1] or false
					info.notCheckable = false
				else
					info.notCheckable = true
				end
				info.disabled=(val.disabled==true or val.text=="" )
				info.keepShownOnClick=(val.disabled=="keep")
				info.value=val.value
				info.arg1=val.arg1
				if type(val.value)=="table" then
					info.arg2=frame._GPIPRIVAT_TableCallback
				elseif type(val.value)=="function" then
					info.arg2=val.arg2
				end
				info.func=PopupClick
				info.hasArrow=false
				info.menuList=nil
				--info.isNotRadio=true
			end
			UIDropDownMenu_AddButton(info,level)
		end
	end
end

local function PopupShow(self,where,x,y)
	where=where or "cursor"
	if UIDROPDOWNMENU_OPEN_MENU ~= self._Frame then
		UIDropDownMenu_Initialize(self._Frame, PopupCreate, "MENU")
	end
	ToggleDropDownMenu(nil, nil, self._Frame, where, x,y)
	self._where=where
	self._x=x
	self._y=y
end

function CreateContextPopup(TableCallback)
	local popup={}
	popup._Frame=CreateFrame("Frame", nil, UIParent, "UIDropDownMenuTemplate")
	popup._Frame._GPIPRIVAT_TableCallback=TableCallback
	popup._Frame._GPIPRIVAT_Items={}
	popup._Frame._GPIPRIVAT_Items.count=0
	popup.AddItem=PopupAddItem
	popup.SubMenu=PopupAddSubMenu
	popup.Show=PopupShow
	popup.Wipe=PopupWipe
	return popup
end
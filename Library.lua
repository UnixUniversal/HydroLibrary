--[[
	Credits:
		 Upbolt - UI Design [stolen from Hydroxide with changes]
		 unix - Library Development
]]

-- Shortcuts to get main function from arrays
local math_random = math.random
local utf8_char = utf8.char
local table_concat = table.concat
local table_insert = table.insert
local coroutine_resume = coroutine.resume
local coroutine_create = coroutine.create

-- Main variables
local Public = {
	GuiOptions = {
		--Opened = false;
		SelectColor = Color3.fromRGB(63, 63, 63);
		UnSelectColor = Color3.fromRGB(20, 20, 20);
		ImageSelectColor = Color3.fromRGB(235, 235, 235);
		ImageUnSelectColor = Color3.fromRGB(127, 127, 127);
		BorderColor = Color3.fromRGB(225, 0, 0);
	};
	FileSystem = false;
	Util = {}
}
local Private = {
	MainFolder = 'HydroLib';
	GuiBuilder = {};
	GuisTree = {};
	Parent = nil;
	RenderStepBind = {};
	connections = {};
	DebugWarningEnabled = false;
	ExamplesUI = {}
}

--- Function for a random string
--- @param l number
local function randomstring(l)
	local t = ""
	for i = 1,l or math_random(15,30) do
		t ..= utf8_char(math_random(1,5000_0))
	end
	return t
end

--- Create a new Co-Routine for function with any arguments
--- @param func any
local function newRoutine(func, ...)
	return coroutine_resume(coroutine_create(func),...)
end

local Debugs = {
	Output = function(...)
		return newRoutine(function(...)
			return warn(...)
		end,...)
	end;
	Console = function(...)
		return newRoutine(function(...)
			return rconsoleprint(table_concat({...},'  ')..'\n')
		end,...)
	end
}

--- Called if happened error while loading Library
--- @param Message string
local function onErrorWarning(Message)
	return function(Options)
		if Private.DebugWarningEnabled then
			Debugs[Options.debugType](Message)
		end
		return false
	end
end

-- If script is loaded
if getgenv().Library2Loaded == true then
	return onErrorWarning('Library/Script already loaded.')
end
getgenv().Library2Loaded = true

local GetService = game.GetService
--- Custom function to contain and get Services
--- @param Index string
local Services = setmetatable({}, {__index = function(Self, Index)
	local NewService = GetService(game, Index)
	if NewService then
		Self[Index] = NewService
	end
	return NewService
end})

local getobjects = function(a)
	local Objects = {}
	if a then
		local b = Services.InsertService:LoadLocalAsset(a)
		if b then
			table.insert(Objects, b)
		end
	end
	return Objects
end

-- Setting up reserved variables
Private.HydroGui = getobjects("rbxassetid://12116595129")[1]
Private.Parent = Services.CoreGui
Private.RenderStepBind = {
	Drag = randomstring()
}

Private.__load_time = tick()

-- Player variables
local LocalPlayer = Services.Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local _instance = Instance.new
local Instance = getmetatable(newproxy(true))
--- Custom function to create Instance
--- @param ClassName string
--- @param Parent Instance | nil
--- @param Properties table | nil
--- @param RandomName boolean | nil
setmetatable(Instance,{
	__call = function(self, ClassName, Parent, Properties, RandomName)
		RandomName = RandomName == nil
		local _part = _instance(ClassName)
		for i,v in pairs(Properties or {}) do
			_part[i] = v
		end
		if RandomName then
			_part.Name = randomstring()
		end
		if Parent ~= nil then
			_part.Parent = Parent
		end
		return _part
	end;
	__metatable = {}
})

-- File system initalize
if makefolder and readfile and isfolder and isfile then
	Public.FileSystem = setmetatable({},{
		__index = function(self,index)
			return self[index] or nil
		end;
		__newindex = function(self,index,value)
			self[index] = value
			writefile(Private.MainFolder..'/settings.json',Services.HttpService:JSONEncode(self))
		end
	})
	if not isfolder(Private.MainFolder) then
		makefolder(Private.MainFolder)
	end
else
	return onErrorWarning('Current Exploit doesn\'t support Hydro File System.')
end

local constants = {
	opened = UDim2.new(0.5, -325, 0.5, -175);
	closed = UDim2.new(0.5, -325, 0, -400);
	reveal = UDim2.new(0.5, -15, 0, 20);
	conceal = UDim2.new(0.5, -15, 0, -75);
	toggleEnabled = UDim2.new(0.45, 0, 0, 0);
	toggleDisabled = UDim2.new(0, 0, 0, 0)
}

--- Sets status
--- @param status string
local function setStatus(status)
	Private.GuisTree['Status'].Text = '• Status: '..(status or '')
end

--- Creating a Main Frame on screen
--- @param Name string
--- @param Logo string
function Private.GuiBuilder:Main(Name,Logo)
	local _Gui = Private.HydroGui:Clone()
	local _Base = _Gui.Base
	local _Drag = _Base.Drag

	for i,v in pairs(_Gui.Examples:GetChildren()) do
		Private.ExamplesUI[v.Name] = v
	end

	Private.GuisTree['Gui'] = _Gui
	Private.GuisTree['Base'] = _Base
	Private.GuisTree['Drag'] = _Drag
	Private.GuisTree['Prompts'] = _Base.Prompts
	Private.GuisTree['ContextMenus'] = _Gui.ContextMenus
	Private.GuisTree['Body'] = _Base.Body
	Private.GuisTree['Tabs'] = _Base.Tabs
	Private.GuisTree['Status'] = _Base.Status

	_Gui.Open.MouseButton1Click:Connect(function()
		_Base:TweenPosition(constants.opened, "Out", "Quad", .15)
		_Gui.Open:TweenPosition(constants.conceal, "Out", "Quad", .15)
	end)
	_Drag.Collapse.MouseButton1Click:Connect(function()
		_Base:TweenPosition(constants.closed, "Out", "Quad", .15)
		_Gui.Open:TweenPosition(constants.reveal, "Out", "Quad", .15)
	end)

	local dragging, dragStart, startPos
	Private.GuisTree['Drag'].InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local dragEnded

			dragging = true
			dragStart = input.Position
			startPos = _Base.Position

			dragEnded = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					dragEnded:Disconnect()
				end
			end)
		end
	end)
	table_insert(Private.connections,Services.UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
			local delta = input.Position - dragStart
			_Base.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end))

	_Base.Border.ImageColor3 = Public.GuiOptions.BorderColor
	_Drag.Icon.Image = Logo or ''
	_Drag.Icon.Icon.Image = Logo or ''
	_Drag.Title.Text = Name..' - '..Public.Version
	_Gui.Open.ImageColor3 = Public.GuiOptions.BorderColor
	_Gui.Open.Icon.Image = Logo or ''
	if getHui then
		_Gui.Parent = getHui()
	else
		if syn then
			syn.protect_gui(_Gui)
		end
		_Gui.Parent = Private.Parent
	end
	return _Base
end

local LastPage, LastTab
--- Switching pages
--- @param Tab Instance
--- @param Page Instance
local function getPage(Tab, Page)
	if LastPage ~= nil then
		LastPage.Visible = false
		Services.TweenService:Create(LastTab,TweenInfo.new(.25),{ImageColor3 = Public.GuiOptions.UnSelectColor}):Play()
		Services.TweenService:Create(LastTab.Icon,TweenInfo.new(.25),{ImageColor3 = Public.GuiOptions.ImageUnSelectColor}):Play()
	end
	if LastPage == Page then
		LastPage = nil
		LastTab = nil
		setStatus('Chillin')
	else
		Tab.ImageColor3 = Public.GuiOptions.SelectColor
		Tab.Icon.ImageColor3 = Public.GuiOptions.ImageSelectColor
		LastPage = Page
		LastTab = Tab
		LastPage.Visible = true
		setStatus(LastPage.Name)
	end
end

local TabsIndex = 0
--- Creating a tab
--- @param Image string
--- @param Page Instance
function Private.GuiBuilder:Tab(Image,Page)
	local _Tab = Private.ExamplesUI.Tab:Clone()
	_Tab.Icon.Image = Image or ''
	_Tab.LayoutOrder = TabsIndex

	_Tab.MouseButton1Click:Connect(function()
		getPage(_Tab, Page)
	end)
	_Tab.MouseEnter:Connect(function()
		if LastPage ~= Page then
			Services.TweenService:Create(_Tab,TweenInfo.new(.25),{ImageColor3 = Public.GuiOptions.SelectColor}):Play()
			Services.TweenService:Create(_Tab.Icon,TweenInfo.new(.25),{ImageColor3 = Public.GuiOptions.ImageSelectColor}):Play()
		end
	end)
	_Tab.MouseLeave:Connect(function()
		if LastPage ~= Page then
			Services.TweenService:Create(_Tab,TweenInfo.new(.25),{ImageColor3 = Public.GuiOptions.UnSelectColor}):Play()
			Services.TweenService:Create(_Tab.Icon,TweenInfo.new(.25),{ImageColor3 = Public.GuiOptions.ImageUnSelectColor}):Play()
		end
	end)

	_Tab.Parent = Private.GuisTree['Tabs'].Container
	TabsIndex += 1
	return _Tab
end

--- Creating a Page
--- @param Name string
function Private.GuiBuilder:Page(Name)
	local _Page = Private.ExamplesUI.Page:Clone()
	_Page.Name = Name
	_Page.Parent = Private.GuisTree['Body'].Pages
	local PageBuilder = {}
	PageBuilder.Instance = _Page
	--- Creating a section
	--- @param Options table { Name = string, DefaultOpened = boolean, SectionPosition = number, Callback = any|nil }
	function PageBuilder:Section(Options)
		local isOpened = (Options.DefaultOpened == true) or false
		local _Section = Private.ExamplesUI.SectionMenu:Clone()
		local SectionMenu = _Section.Section
		local MenuOpenedIcon = SectionMenu.MenuOpened
		if isOpened == true then
			MenuOpenedIcon.Rotation = -65
		end
		SectionMenu.Label.Text = Options.Name or ''
		local SectionSizeY = 29
		SectionMenu.Button.MouseButton1Click:Connect(function()
			isOpened = not isOpened
			Services.TweenService:Create(MenuOpenedIcon,TweenInfo.new(.25),{Rotation = (isOpened == true and -65) or 65}):Play()
			Services.TweenService:Create(_Section,TweenInfo.new(.25),{Size = UDim2.new(0,240,0,(isOpened == true and SectionSizeY) or 29)}):Play()
			if Options.Callback ~= nil then
				Options.Callback(Options,isOpened)
			end
		end)
		_Section.Border.ChildAdded:Connect(function(a)
			if a:IsA('ImageLabel') then
				SectionSizeY += a.Size.Y.Offset + 2
				if isOpened == true then
					_Section.Size = UDim2.new(0,240,0,SectionSizeY)
				end
			end
		end)
		if Options.SectionPosition == 1 then
			_Section.Parent = _Page.SubSection
		elseif Options.SectionPosition == 2 then
			_Section.Parent = _Page.SubSection2
		end
		local SectionBuilder = {}
		SectionBuilder.Instance = _Section
		SectionBuilder.Page = _Page
		local LocalIndex = 0
		--- Creating a LabelText
		--- @param Options table { Name: string }
		function SectionBuilder:Label(Options)
			local _Label = Private.ExamplesUI.Label:Clone()
			_Label.Text.Text = Options.Name or ''
			_Label.LayoutOrder = LocalIndex
			_Label.Parent = _Section.Border
			LocalIndex += 1
			return _Label
		end
		--- Creating a Toggle Button
		--- @param Options table { Name: string, Default: boolean, Callback: any|nil }
		function SectionBuilder:Toggle(Options)
			local isEnabled = (Options.Default == true) or false
			local _Toggle = Private.ExamplesUI.Toggle:Clone()
			local _BackFrame = _Toggle.BackFrame
			local _Button = _BackFrame.Button
			if isEnabled == true then
				_Button.Position = constants.toggleEnabled
				_BackFrame.BackgroundColor3 = Color3.fromRGB(106, 172, 55)
			end
			_Toggle.Label.Text = Options.Name or ''
			_Toggle.LayoutOrder = LocalIndex
			_Button.MouseButton1Click:Connect(function()
				isEnabled = not isEnabled
				_Button:TweenPosition((isEnabled == true and constants.toggleEnabled) or constants.toggleDisabled, "Out", "Quad", .15)
				Services.TweenService:Create(_BackFrame,TweenInfo.new(.15),{BackgroundColor3 = (isEnabled == true and Color3.fromRGB(106, 172, 55)) or Color3.fromRGB(65, 65, 65)}):Play()
				if Options.Callback ~= nil then
					Options.Callback(Options,isEnabled)
				end
			end)
			_Toggle.Parent = _Section.Border
			LocalIndex += 1
			return _Toggle
		end
		--- Creating a Button
		--- @param Options table { Name: string, Callback: any|nil }
		function SectionBuilder:Button(Options)
			local _Button = Private.ExamplesUI.Button:Clone()
			local _RealButton = _Button.Button
			_RealButton.Text = Options.Name or ''
			_Button.LayoutOrder = LocalIndex
			_RealButton.MouseEnter:Connect(function()
				Services.TweenService:Create(_RealButton,TweenInfo.new(.25),{BackgroundColor3 = Color3.fromRGB(86, 86, 86)}):Play()
			end)
			_RealButton.MouseLeave:Connect(function()
				Services.TweenService:Create(_RealButton,TweenInfo.new(.25),{BackgroundColor3 = Color3.fromRGB(65, 65, 65)}):Play()
			end)
			_RealButton.MouseButton1Click:Connect(function()
				if Options.Callback ~= nil then
					Options.Callback(Options)
				end
			end)
			_Button.Parent = _Section.Border
			LocalIndex += 1
			return _Button
		end
		return SectionBuilder
	end
	return PageBuilder
end

--- Runs Library
--- @param Options table
function Private.Run(Options)
	Private.RunOptions = Options
	Private.Run = nil
	
	Public.GuiBuilder = Private.GuiBuilder
	Public.randomstring = randomstring
	Public.Instance = Instance
	Public.Services = Services
	Public.Player = LocalPlayer
	Public.Mouse = Mouse
	Public.Malicious = Private
	Public.Util.newRoutine = newRoutine
	Public.Version = Options.Version
	if Options.debugWarning == true then
		Private.DebugWarningEnabled = true
		Public.DebugWarning = Debugs[Options.debugType] or function()end
	end
	return Public
end

--- Unloads Library & Script
function Private.Unload()
	for i,v in pairs(Private.connections) do
		pcall(function()
			v:Disconnect()
		end)
	end
	for i,v in pairs(Private.RenderStepBind) do
		pcall(function()
			Services.RunService:UnbindFromRenderStep(v)
		end)
	end
	pcall(function()
		Private.GuisTree.Gui:Destroy()
	end)
	getgenv().Library2Loaded = false
	if Private.DebugWarningEnabled then
		Public.DebugWarning('Script have been successfully unloaded.')
	end
	script:Destroy()
end

Private.__load_time = tick()-Private.__load_time

return Private.Run

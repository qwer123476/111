local Library = {}

local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
local uisSuccess, userInputService = pcall(function() return game:GetService("UserInputService") end)

if not success or not uisSuccess or not coreGui or not userInputService then
	warn("실행기 문제: 현재 익스큐터가 필요한 서비스를 지원하지 않거나 보안 제한이 걸려 있습니다.")
	return nil
end

local player = game:GetService("Players").LocalPlayer

local function makeDraggable(guiObject)
	local dragging, dragInput, dragStart, startPosition
	guiObject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPosition = guiObject.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	guiObject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	userInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			guiObject.Position = UDim2.new(
				startPosition.X.Scale, startPosition.X.Offset + delta.X, 
				startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
			)
		end
	end)
end

function Library:CreateWindow(config)
	config = config or {}
	local titleText = config.Name or "Custom Hub"
	local creditText = config.Credit or "By 놀랐으"

	local toggleKey = Enum.KeyCode.K
	local isBinding = false
	local BindBtn = nil

	local oldGui = coreGui:FindFirstChild("WinTeleportsGui")
	if oldGui then 
		local delSuccess = pcall(function() oldGui:Destroy() end)
		if not delSuccess then
			warn("실행기 문제: 기존 GUI 개체를 삭제할 수 없습니다. 권한 부족일 수 있습니다.")
		end
	end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "WinTeleportsGui"
	
	local parentSuccess = pcall(function() ScreenGui.Parent = coreGui end)
	if not parentSuccess then
		warn("실행기 문제: CoreGui에 UI를 삽입할 권한이 없습니다. 다른 익스큐터를 사용해 보세요.")
		return nil
	end
	ScreenGui.ResetOnSpawn = false

	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, 550, 0, 400)
	MainFrame.Position = UDim2.new(0.5, -275, 0.5, -200)
	MainFrame.BackgroundColor3 = Color3.fromRGB(80, 45, 25)
	MainFrame.BackgroundTransparency = 0.25
	MainFrame.Active = true
	MainFrame.Visible = true
	MainFrame.Parent = ScreenGui
	makeDraggable(MainFrame)

	local MainFrameStroke = Instance.new("UIStroke")
	MainFrameStroke.Thickness = 2
	MainFrameStroke.Color = Color3.fromRGB(255, 133, 112)
	MainFrameStroke.Parent = MainFrame

	local ToggleMainBtn = Instance.new("TextButton")
	ToggleMainBtn.Name = "ToggleMainBtn"
	ToggleMainBtn.Size = UDim2.new(0, 100, 0, 40)
	ToggleMainBtn.Position = UDim2.new(0, 20, 0.5, -20)
	ToggleMainBtn.BackgroundColor3 = Color3.fromRGB(255, 166, 114)
	ToggleMainBtn.Text = "Open/Close"
	ToggleMainBtn.TextColor3 = Color3.fromRGB(50, 25, 15)
	ToggleMainBtn.Font = Enum.Font.SourceSansBold
	ToggleMainBtn.TextSize = 14
	ToggleMainBtn.Parent = ScreenGui
	makeDraggable(ToggleMainBtn)
	ToggleMainBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

	userInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if isBinding then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				toggleKey = input.KeyCode
				isBinding = false
				if BindBtn then BindBtn.Text = toggleKey.Name end
			end
		else
			if input.KeyCode == toggleKey then
				MainFrame.Visible = not MainFrame.Visible
			end
		end
	end)

	local Topbar = Instance.new("Frame")
	Topbar.Size = UDim2.new(1, 0, 0, 40)
	Topbar.BackgroundColor3 = Color3.fromRGB(100, 55, 30)
	Topbar.BackgroundTransparency = 0.25
	Topbar.BorderSizePixel = 0
	Topbar.Parent = MainFrame

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -40, 1, 0)
	Title.Position = UDim2.new(0, 15, 0, 0)
	Title.Text = titleText
	Title.TextColor3 = Color3.fromRGB(255, 252, 245)
	Title.TextSize = 18
	Title.Font = Enum.Font.SourceSansBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.BackgroundTransparency = 1
	Title.Parent = Topbar

	local CreditLabel = Instance.new("TextLabel")
	CreditLabel.Size = UDim2.new(0, 100, 0, 20)
	CreditLabel.Position = UDim2.new(1, -110, 1, -25)
	CreditLabel.BackgroundColor3 = Color3.fromRGB(50, 25, 15)
	CreditLabel.BackgroundTransparency = 0.4
	CreditLabel.Text = creditText
	CreditLabel.TextColor3 = Color3.fromRGB(255, 220, 180)
	CreditLabel.Font = Enum.Font.SourceSansItalic
	CreditLabel.TextSize = 13
	CreditLabel.ZIndex = 50
	CreditLabel.Parent = MainFrame

	local TabContainer = Instance.new("Frame")
	TabContainer.Position = UDim2.new(0, 10, 0, 50)
	TabContainer.Size = UDim2.new(0, 130, 1, -60)
	TabContainer.BackgroundTransparency = 1
	TabContainer.Parent = MainFrame

	local TabLayout = Instance.new("UIListLayout")
	TabLayout.Padding = UDim.new(0, 5)
	TabLayout.Parent = TabContainer

	local ContentContainer = Instance.new("Frame")
	ContentContainer.Position = UDim2.new(0, 150, 0, 50)
	ContentContainer.Size = UDim2.new(1, -160, 1, -60)
	ContentContainer.BackgroundTransparency = 1
	ContentContainer.Parent = MainFrame

	local SettingScroll = Instance.new("ScrollingFrame")
	SettingScroll.Size = UDim2.new(1, 0, 1, 0)
	SettingScroll.BackgroundTransparency = 1
	SettingScroll.BorderSizePixel = 0
	SettingScroll.ScrollBarThickness = 4
	SettingScroll.Visible = false
	SettingScroll.Parent = ContentContainer

	local SettingList = Instance.new("UIListLayout")
	SettingList.Padding = UDim.new(0, 6)
	SettingList.Parent = SettingScroll
	SettingList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		SettingScroll.CanvasSize = UDim2.new(0, 0, 0, SettingList.AbsoluteContentSize.Y + 10)
	end)

	local SettingTabBtn = Instance.new("TextButton")
	SettingTabBtn.Size = UDim2.new(1, 0, 0, 35)
	SettingTabBtn.BackgroundColor3 = Color3.fromRGB(95, 55, 30)
	SettingTabBtn.Text = "⚙️ㆍSettings"
	SettingTabBtn.TextColor3 = Color3.fromRGB(255, 248, 230)
	SettingTabBtn.Font = Enum.Font.SourceSansBold
	SettingTabBtn.TextSize = 14
	SettingTabBtn.Parent = TabContainer

	local BindFrame = Instance.new("Frame")
	BindFrame.Size = UDim2.new(1, -10, 0, 42)
	BindFrame.BackgroundColor3 = Color3.fromRGB(85, 50, 32)
	BindFrame.Parent = SettingScroll

	local BindLabel = Instance.new("TextLabel")
	BindLabel.Size = UDim2.new(0.5, 0, 1, 0)
	BindLabel.Position = UDim2.new(0, 12, 0, 0)
	BindLabel.Text = "⌨️ㆍUI 열기/닫기 키"
	BindLabel.TextColor3 = Color3.fromRGB(255, 252, 245)
	BindLabel.Font = Enum.Font.SourceSansBold
	BindLabel.TextSize = 14
	BindLabel.TextXAlignment = Enum.TextXAlignment.Left
	BindLabel.BackgroundTransparency = 1
	BindLabel.Parent = BindFrame

	BindBtn = Instance.new("TextButton")
	BindBtn.Size = UDim2.new(0, 90, 0, 26)
	BindBtn.Position = UDim2.new(1, -100, 0.5, -13)
	BindBtn.BackgroundColor3 = Color3.fromRGB(60, 35, 20)
	BindBtn.Text = "K"
	BindBtn.Font = Enum.Font.SourceSansBold
	BindBtn.TextColor3 = Color3.fromRGB(255, 180, 90)
	BindBtn.TextSize = 13
	BindBtn.Parent = BindFrame
	BindBtn.MouseButton1Click:Connect(function()
		isBinding = true
		BindBtn.Text = "..."
	end)

	local SetFrame = Instance.new("Frame")
	SetFrame.Size = UDim2.new(1, -10, 0, 50)
	SetFrame.BackgroundColor3 = Color3.fromRGB(85, 50, 32)
	SetFrame.Parent = SettingScroll

	local SetLabel = Instance.new("TextLabel")
	SetLabel.Size = UDim2.new(0.4, 0, 1, 0)
	SetLabel.Position = UDim2.new(0, 12, 0, 0)
	SetLabel.Text = "🧊ㆍ투명도 조절 (0.25)"
	SetLabel.TextColor3 = Color3.fromRGB(255, 252, 245)
	SetLabel.Font = Enum.Font.SourceSans
	SetLabel.TextSize = 14
	SetLabel.TextXAlignment = Enum.TextXAlignment.Left
	SetLabel.BackgroundTransparency = 1
	SetLabel.Parent = SetFrame

	local SetTrack = Instance.new("Frame")
	SetTrack.Size = UDim2.new(0.5, 0, 0, 6)
	SetTrack.Position = UDim2.new(0.45, 0, 0.5, -3)
	SetTrack.BackgroundColor3 = Color3.fromRGB(60, 35, 20)
	SetTrack.BorderSizePixel = 0
	SetTrack.Parent = SetFrame

	local SetSliderBtn = Instance.new("TextButton")
	SetSliderBtn.Size = UDim2.new(0, 16, 0, 20)
	SetSliderBtn.Position = UDim2.new(0.25, -8, 0.5, -10)
	SetSliderBtn.BackgroundColor3 = Color3.fromRGB(255, 166, 114)
	SetSliderBtn.Text = ""
	SetSliderBtn.Parent = SetTrack

	local setDragging = false
	SetSliderBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then setDragging = true end
	end)
	userInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then setDragging = false end
	end)
	userInputService.InputChanged:Connect(function(input)
		if setDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local pct = math.clamp((input.Position.X - SetTrack.AbsolutePosition.X) / SetTrack.AbsoluteSize.X, 0, 1)
			SetSliderBtn.Position = UDim2.new(pct, -8, 0.5, -10)
			SetLabel.Text = "🧊ㆍ투명도 조절 (" .. string.format("%.2f", pct) .. ")"
			MainFrame.BackgroundTransparency = pct
			Topbar.BackgroundTransparency = pct
		end
	end)

	local tabs = {}
	table.insert(tabs, {Scroll = SettingScroll, Btn = SettingTabBtn})

	SettingTabBtn.MouseButton1Click:Connect(function()
		for _, t in pairs(tabs) do
			t.Scroll.Visible = false
			t.Btn.BackgroundColor3 = Color3.fromRGB(95, 55, 30)
		end
		SettingScroll.Visible = true
		SettingTabBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 90)
	end)

	local WindowMethods = {}
	function WindowMethods:CreateTab(tabName)
		local ScrollFrame = Instance.new("ScrollingFrame")
		ScrollFrame.Size = UDim2.new(1, 0, 1, 0)
		ScrollFrame.BackgroundTransparency = 1
		ScrollFrame.BorderSizePixel = 0
		ScrollFrame.ScrollBarThickness = 4
		ScrollFrame.Visible = false
		ScrollFrame.Parent = ContentContainer

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Padding = UDim.new(0, 6)
		ListLayout.Parent = ScrollFrame
		ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
		end)

		local TabBtn = Instance.new("TextButton")
		TabBtn.Size = UDim2.new(1, 0, 0, 35)
		TabBtn.BackgroundColor3 = Color3.fromRGB(95, 55, 35)
		TabBtn.Text = tabName
		TabBtn.TextColor3 = Color3.fromRGB(255, 248, 230)
		TabBtn.Font = Enum.Font.SourceSansBold
		TabBtn.TextSize = 14
		TabBtn.Parent = TabContainer

		TabBtn.MouseButton1Click:Connect(function()
			for _, t in pairs(tabs) do
				t.Scroll.Visible = false
				t.Btn.BackgroundColor3 = Color3.fromRGB(95, 55, 35)
			end
			ScrollFrame.Visible = true
			TabBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 90)
		end)

		table.insert(tabs, {Scroll = ScrollFrame, Btn = TabBtn})
		
		if #tabs == 2 then
			SettingScroll.Visible = false
			ScrollFrame.Visible = true
			TabBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 90)
		end

		local TabMethods = {}

		function TabMethods:CreateButton(text, callback)
			local Btn = Instance.new("TextButton")
			Btn.Size = UDim2.new(1, -10, 0, 38)
			Btn.BackgroundColor3 = Color3.fromRGB(85, 50, 32)
			Btn.Text = text
			Btn.TextColor3 = Color3.fromRGB(255, 252, 245)
			Btn.Font = Enum.Font.SourceSans
			Btn.TextSize = 15
			Btn.Parent = ScrollFrame
			Btn.MouseButton1Click:Connect(callback)
		end

		function TabMethods:CreateToggle(text, callback)
			local Frame = Instance.new("Frame")
			Frame.Size = UDim2.new(1, -10, 0, 38)
			Frame.BackgroundColor3 = Color3.fromRGB(85, 50, 32)
			Frame.Parent = ScrollFrame

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(1, -60, 1, 0)
			Label.Position = UDim2.new(0, 12, 0, 0)
			Label.Text = text
			Label.TextColor3 = Color3.fromRGB(255, 252, 245)
			Label.Font = Enum.Font.SourceSans
			Label.TextSize = 15
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.BackgroundTransparency = 1
			Label.Parent = Frame

			local ToggleIndicator = Instance.new("TextButton")
			ToggleIndicator.Size = UDim2.new(0, 45, 0, 24)
			ToggleIndicator.Position = UDim2.new(1, -55, 0.5, -12)
			ToggleIndicator.BackgroundColor3 = Color3.fromRGB(110, 70, 55)
			ToggleIndicator.Text = "OFF"
			ToggleIndicator.Font = Enum.Font.SourceSansBold
			ToggleIndicator.TextSize = 12
			ToggleIndicator.TextColor3 = Color3.fromRGB(255, 252, 245)
			ToggleIndicator.Parent = Frame

			local enabled = false
			ToggleIndicator.MouseButton1Click:Connect(function()
				enabled = not enabled
				if enabled then
					ToggleIndicator.BackgroundColor3 = Color3.fromRGB(255, 170, 80)
					ToggleIndicator.Text = "ON"
				else
					ToggleIndicator.BackgroundColor3 = Color3.fromRGB(110, 70, 55)
					ToggleIndicator.Text = "OFF"
				end
				callback(enabled)
			end)
		end

		function TabMethods:CreateSlider(text, min, max, default, callback)
			local Frame = Instance.new("Frame")
			Frame.Size = UDim2.new(1, -10, 0, 50)
			Frame.BackgroundColor3 = Color3.fromRGB(85, 50, 32)
			Frame.Parent = ScrollFrame

			local initPct = math.clamp((default - min) / (max - min), 0, 1)

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(0.4, 0, 1, 0)
			Label.Position = UDim2.new(0, 12, 0, 0)
			Label.Text = text .. " (" .. tostring(default) .. ")"
			Label.TextColor3 = Color3.fromRGB(255, 252, 245)
			Label.Font = Enum.Font.SourceSans
			Label.TextSize = 14
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.BackgroundTransparency = 1
			Label.Parent = Frame

			local SliderTrack = Instance.new("Frame")
			SliderTrack.Size = UDim2.new(0.5, 0, 0, 6)
			SliderTrack.Position = UDim2.new(0.45, 0, 0.5, -3)
			SliderTrack.BackgroundColor3 = Color3.fromRGB(60, 35, 20)
			SliderTrack.BorderSizePixel = 0
			SliderTrack.Parent = Frame

			local SliderButton = Instance.new("TextButton")
			SliderButton.Size = UDim2.new(0, 16, 0, 20)
			SliderButton.Position = UDim2.new(initPct, -8, 0.5, -10)
			SliderButton.BackgroundColor3 = Color3.fromRGB(255, 166, 114)
			SliderButton.Text = ""
			SliderButton.Parent = SliderTrack

			local dragging = false
			SliderButton.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
			end)
			userInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
			end)
			userInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local percentage = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
					SliderButton.Position = UDim2.new(percentage, -8, 0.5, -10)
					
					local actualValue = math.floor(min + (percentage * (max - min)) + 0.5)
					Label.Text = text .. " (" .. tostring(actualValue) .. ")"
					callback(actualValue)
				end
			end)
		end

		function TabMethods:CreateTextBox(text, placeholder, callback)
			local Frame = Instance.new("Frame")
			Frame.Size = UDim2.new(1, -10, 0, 45)
			Frame.BackgroundColor3 = Color3.fromRGB(85, 50, 32)
			Frame.Parent = ScrollFrame

			local Box = Instance.new("TextBox")
			Box.Size = UDim2.new(0.5, 0, 0, 28)
			Box.Position = UDim2.new(0.45, 0, 0.5, -14)
			Box.BackgroundColor3 = Color3.fromRGB(50, 28, 16)
			Box.TextColor3 = Color3.fromRGB(255, 255, 255)
			Box.PlaceholderText = placeholder
			Box.Text = ""
			Box.Font = Enum.Font.SourceSans
			Box.TextSize = 14
			Box.ClearTextOnFocus = false
			Box.Parent = Frame

			Box:GetPropertyChangedSignal("Text"):Connect(function() callback(Box.Text) end)
		end

		return TabMethods
	end

	return WindowMethods
end

return Library

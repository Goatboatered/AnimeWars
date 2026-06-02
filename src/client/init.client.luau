local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("GachaRemotes")
local summonResult = remotes:WaitForChild("SummonResult")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SummonHubUI"
screenGui.Parent = playerGui

local messageLabel = Instance.new("TextLabel")
messageLabel.Size = UDim2.fromOffset(380, 80)
messageLabel.Position = UDim2.fromScale(0.5, 0.05)
messageLabel.BackgroundTransparency = 0.4
messageLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
messageLabel.BorderSizePixel = 0
messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
messageLabel.TextStrokeTransparency = 0.5
messageLabel.TextScaled = true
messageLabel.Font = Enum.Font.GothamMedium
messageLabel.Text = "Use the button to summon a Unit!"
messageLabel.Parent = screenGui
messageLabel.Visible = false

local summonButton = Instance.new("TextButton")
summonButton.Name = "SummonButton"
summonButton.Size = UDim2.fromOffset(56, 56)
summonButton.Position = UDim2.new(0, 16, 0.5, -64)
summonButton.AnchorPoint = Vector2.new(0, 0)
summonButton.BackgroundColor3 = Color3.fromRGB(45, 110, 220)
summonButton.BorderSizePixel = 0
summonButton.TextColor3 = Color3.fromRGB(255, 255, 255)
summonButton.Font = Enum.Font.GothamBold
summonButton.TextScaled = true
summonButton.Text = "S"
summonButton.Parent = screenGui

local unitMenuButton = Instance.new("TextButton")
unitMenuButton.Name = "UnitMenuButton"
unitMenuButton.Size = UDim2.fromOffset(56, 56)
unitMenuButton.Position = UDim2.new(0, 16, 0.5, 8)
unitMenuButton.AnchorPoint = Vector2.new(0, 0)
unitMenuButton.BackgroundColor3 = Color3.fromRGB(76, 196, 132)
unitMenuButton.BorderSizePixel = 0
unitMenuButton.TextColor3 = Color3.fromRGB(255, 255, 255)
unitMenuButton.Font = Enum.Font.GothamBold
unitMenuButton.TextScaled = true
unitMenuButton.Text = "U"
unitMenuButton.Parent = screenGui

local mailButton = Instance.new("TextButton")
mailButton.Name = "MailButton"
mailButton.Size = UDim2.fromOffset(56, 56)
mailButton.Position = UDim2.new(0, 16, 0.5, 72)
mailButton.AnchorPoint = Vector2.new(0, 0)
mailButton.BackgroundColor3 = Color3.fromRGB(210, 150, 40)
mailButton.BorderSizePixel = 0
mailButton.TextColor3 = Color3.fromRGB(255, 255, 255)
mailButton.Font = Enum.Font.GothamBold
mailButton.TextScaled = true
mailButton.Text = "M"
mailButton.Parent = screenGui

local playButton = Instance.new("TextButton")
playButton.Name = "PlayButton"
playButton.Size = UDim2.fromOffset(320, 64)
playButton.Position = UDim2.new(0.5, 0, 1, -96)
playButton.AnchorPoint = Vector2.new(0.5, 1)
playButton.BackgroundColor3 = Color3.fromRGB(255, 191, 64)
playButton.BorderSizePixel = 0
playButton.TextColor3 = Color3.fromRGB(25, 25, 35)
playButton.Font = Enum.Font.GothamBlack
playButton.TextScaled = true
playButton.Text = "PLAY"
playButton.Parent = screenGui

local playCorner = Instance.new("UICorner")
playCorner.CornerRadius = UDim.new(0, 18)
playCorner.Parent = playButton

local playStroke = Instance.new("UIStroke")
playStroke.Color = Color3.fromRGB(255, 255, 255)
playStroke.Thickness = 2
playStroke.Transparency = 0.15
playStroke.Parent = playButton

local function showMessage(text)
	messageLabel.Text = text
	messageLabel.Visible = true
	delay(4, function()
		if messageLabel and messageLabel.Parent then
			messageLabel.Visible = false
		end
	end)
end

local summonRequest = remotes:WaitForChild("SummonRequest")

local function performSummon()
	summonButton.Active = false
	summonButton.Text = "Summoning..."

	local success, result = pcall(function()
		return summonRequest:InvokeServer()
	end)

	if success and result then
		showMessage("Unit summoned: " .. result.DisplayName)
	else
		showMessage("Summon failed. Try again.")
	end

	summonButton.Text = "S"
	summonButton.Active = true
end

summonButton.MouseButton1Click:Connect(performSummon)

local modeMenu = Instance.new("Frame")
modeMenu.Name = "ModeMenu"
modeMenu.Size = UDim2.fromOffset(340, 260)
modeMenu.Position = UDim2.new(0.5, -170, 1, -320)
modeMenu.AnchorPoint = Vector2.new(0.5, 1)
modeMenu.BackgroundColor3 = Color3.fromRGB(17, 19, 28)
modeMenu.BorderSizePixel = 0
modeMenu.Visible = false
modeMenu.Parent = screenGui

local modeCorner = Instance.new("UICorner")
modeCorner.CornerRadius = UDim.new(0, 18)
modeCorner.Parent = modeMenu

local modeStroke = Instance.new("UIStroke")
modeStroke.Color = Color3.fromRGB(95, 121, 255)
modeStroke.Thickness = 2
modeStroke.Transparency = 0.15
modeStroke.Parent = modeMenu

local modeTitle = Instance.new("TextLabel")
modeTitle.Size = UDim2.new(1, -24, 0, 36)
modeTitle.Position = UDim2.fromOffset(12, 10)
modeTitle.BackgroundTransparency = 1
modeTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
modeTitle.Font = Enum.Font.GothamBold
modeTitle.TextScaled = true
modeTitle.Text = "Choose a Mode"
modeTitle.TextXAlignment = Enum.TextXAlignment.Left
modeTitle.Parent = modeMenu

local modeList = Instance.new("UIListLayout")
modeList.Padding = UDim.new(0, 10)
modeList.SortOrder = Enum.SortOrder.LayoutOrder
modeList.Parent = modeMenu
modeList.HorizontalAlignment = Enum.HorizontalAlignment.Center
modeList.VerticalAlignment = Enum.VerticalAlignment.Top

local areaMenu = Instance.new("Frame")
areaMenu.Name = "AreaMenu"
areaMenu.Size = UDim2.fromOffset(340, 280)
areaMenu.Position = UDim2.new(0.5, -170, 1, -172)
areaMenu.AnchorPoint = Vector2.new(0.5, 1)
areaMenu.BackgroundColor3 = Color3.fromRGB(17, 19, 28)
areaMenu.BorderSizePixel = 0
areaMenu.Visible = false
areaMenu.Parent = screenGui

local areaCorner = Instance.new("UICorner")
areaCorner.CornerRadius = UDim.new(0, 18)
areaCorner.Parent = areaMenu

local areaStroke = Instance.new("UIStroke")
areaStroke.Color = Color3.fromRGB(95, 121, 255)
areaStroke.Thickness = 2
areaStroke.Transparency = 0.15
areaStroke.Parent = areaMenu

local areaTitle = Instance.new("TextLabel")
areaTitle.Size = UDim2.new(1, -24, 0, 36)
areaTitle.Position = UDim2.fromOffset(12, 8)
areaTitle.BackgroundTransparency = 1
areaTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
areaTitle.Font = Enum.Font.GothamBold
areaTitle.TextScaled = true
areaTitle.Text = "Choose an Area"
areaTitle.TextXAlignment = Enum.TextXAlignment.Left
areaTitle.Parent = areaMenu

local areaScroll = Instance.new("ScrollingFrame")
areaScroll.Name = "AreaScroll"
areaScroll.Size = UDim2.new(1, -12, 1, -100)
areaScroll.Position = UDim2.fromOffset(6, 50)
areaScroll.BackgroundTransparency = 1
areaScroll.BorderSizePixel = 0
areaScroll.ScrollBarThickness = 6
areaScroll.CanvasSize = UDim2.fromOffset(0, 0)
areaScroll.Parent = areaMenu

local areaList = Instance.new("UIListLayout")
areaList.Padding = UDim.new(0, 6)
areaList.SortOrder = Enum.SortOrder.LayoutOrder
areaList.Parent = areaScroll
areaList.HorizontalAlignment = Enum.HorizontalAlignment.Center
areaList.VerticalAlignment = Enum.VerticalAlignment.Top

local selectedArea = ""

local stageMenu = Instance.new("Frame")
stageMenu.Name = "StageMenu"
stageMenu.Size = UDim2.fromOffset(340, 280)
stageMenu.Position = UDim2.new(0.5, -170, 1, -172)
stageMenu.AnchorPoint = Vector2.new(0.5, 1)
stageMenu.BackgroundColor3 = Color3.fromRGB(17, 19, 28)
stageMenu.BorderSizePixel = 0
stageMenu.Visible = false
stageMenu.Parent = screenGui

local stageCorner = Instance.new("UICorner")
stageCorner.CornerRadius = UDim.new(0, 18)
stageCorner.Parent = stageMenu

local stageStroke = Instance.new("UIStroke")
stageStroke.Color = Color3.fromRGB(95, 121, 255)
stageStroke.Thickness = 2
stageStroke.Transparency = 0.15
stageStroke.Parent = stageMenu

local stageTitle = Instance.new("TextLabel")
stageTitle.Size = UDim2.new(1, -24, 0, 36)
stageTitle.Position = UDim2.fromOffset(12, 8)
stageTitle.BackgroundTransparency = 1
stageTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
stageTitle.Font = Enum.Font.GothamBold
stageTitle.TextScaled = true
stageTitle.Text = "Choose a Stage"
stageTitle.TextXAlignment = Enum.TextXAlignment.Left
stageTitle.Parent = stageMenu

local stageScroll = Instance.new("ScrollingFrame")
stageScroll.Name = "StageScroll"
stageScroll.Size = UDim2.new(1, -12, 1, -100)
stageScroll.Position = UDim2.fromOffset(6, 50)
stageScroll.BackgroundTransparency = 1
stageScroll.BorderSizePixel = 0
stageScroll.ScrollBarThickness = 6
stageScroll.CanvasSize = UDim2.fromOffset(0, 0)
stageScroll.Parent = stageMenu

local stageList = Instance.new("UIListLayout")
stageList.Padding = UDim.new(0, 6)
stageList.SortOrder = Enum.SortOrder.LayoutOrder
stageList.Parent = stageScroll
stageList.HorizontalAlignment = Enum.HorizontalAlignment.Center
stageList.VerticalAlignment = Enum.VerticalAlignment.Top

local function createModeButton(text, onClick)
	local button = Instance.new("TextButton")
	button.Name = text .. "Button"
	button.Size = UDim2.new(1, -24, 0, 44)
	button.BackgroundColor3 = Color3.fromRGB(39, 47, 66)
	button.BorderSizePixel = 0
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamMedium
	button.TextScaled = true
	button.Text = text
	button.Parent = modeMenu

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 12)
	buttonCorner.Parent = button

	button.MouseButton1Click:Connect(function()
		if onClick then
			onClick()
		else
			modeMenu.Visible = false
			showMessage(text .. " mode selected")
		end
	end)

	return button
end

createModeButton("Campaign", function()
	modeMenu.Visible = false
	areaMenu.Visible = true
	showMessage("Campaign selected")
end)
createModeButton("Dungeons", function()
	modeMenu.Visible = false
	showMessage("Dungeons mode selected")
end)
createModeButton("Rifts", function()
	modeMenu.Visible = false
	showMessage("Rifts mode selected")
end)
createModeButton("PvP", function()
	modeMenu.Visible = false
	showMessage("PvP mode selected")
end)

local function createAreaButton(text)
	local button = Instance.new("TextButton")
	button.Name = text .. "Button"
	button.Size = UDim2.new(1, -24, 0, 40)
	button.BackgroundColor3 = Color3.fromRGB(39, 47, 66)
	button.BorderSizePixel = 0
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamMedium
	button.TextScaled = true
	button.Text = text
	button.Parent = areaScroll

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 10)
	buttonCorner.Parent = button

	button.MouseButton1Click:Connect(function()
		areaMenu.Visible = false
		selectedArea = text
		stageTitle.Text = text .. " — Stages"
		stageMenu.Visible = true
	end)

	return button
end

for i = 1, 8 do
	createAreaButton("Area " .. i)
end

areaScroll.CanvasSize = UDim2.fromOffset(0, 8 * 40 + 7 * 6)

local backToModes = Instance.new("TextButton")
backToModes.Name = "BackButton"
backToModes.Size = UDim2.new(1, -24, 0, 36)
backToModes.Position = UDim2.new(0, 12, 1, -44)
backToModes.BackgroundColor3 = Color3.fromRGB(55, 65, 85)
backToModes.BorderSizePixel = 0
backToModes.TextColor3 = Color3.fromRGB(190, 200, 220)
backToModes.Font = Enum.Font.GothamMedium
backToModes.TextScaled = true
backToModes.Text = "← Back"
backToModes.Parent = areaMenu

local backCorner = Instance.new("UICorner")
backCorner.CornerRadius = UDim.new(0, 10)
backCorner.Parent = backToModes

backToModes.MouseButton1Click:Connect(function()
	areaMenu.Visible = false
	modeMenu.Visible = true
end)

local function createStageButton(text)
	local button = Instance.new("TextButton")
	button.Name = text .. "Button"
	button.Size = UDim2.new(1, -24, 0, 40)
	button.BackgroundColor3 = Color3.fromRGB(39, 47, 66)
	button.BorderSizePixel = 0
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamMedium
	button.TextScaled = true
	button.Text = text
	button.Parent = stageScroll

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 10)
	buttonCorner.Parent = button

	button.MouseButton1Click:Connect(function()
		stageMenu.Visible = false
		showMessage(selectedArea .. " · " .. text .. " selected")
	end)

	return button
end

for i = 1, 7 do
	createStageButton("Stage " .. i)
end

stageScroll.CanvasSize = UDim2.fromOffset(0, 7 * 40 + 6 * 6)

local stageBackButton = Instance.new("TextButton")
stageBackButton.Name = "StageBackButton"
stageBackButton.Size = UDim2.new(1, -24, 0, 36)
stageBackButton.Position = UDim2.new(0, 12, 1, -44)
stageBackButton.BackgroundColor3 = Color3.fromRGB(55, 65, 85)
stageBackButton.BorderSizePixel = 0
stageBackButton.TextColor3 = Color3.fromRGB(190, 200, 220)
stageBackButton.Font = Enum.Font.GothamMedium
stageBackButton.TextScaled = true
stageBackButton.Text = "← Back"
stageBackButton.Parent = stageMenu

local stageBackCorner = Instance.new("UICorner")
stageBackCorner.CornerRadius = UDim.new(0, 10)
stageBackCorner.Parent = stageBackButton

stageBackButton.MouseButton1Click:Connect(function()
	stageMenu.Visible = false
	areaMenu.Visible = true
end)

playButton.MouseButton1Click:Connect(function()
	modeMenu.Visible = not modeMenu.Visible
	areaMenu.Visible = false
	stageMenu.Visible = false
end)

local unitRequest = remotes:WaitForChild("GetUnits")
local unitsUpdated = remotes:WaitForChild("UnitsUpdated")

local overlay = Instance.new("Frame")
overlay.Name = "UnitOverlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.Position = UDim2.fromScale(0, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.65
overlay.Active = true
overlay.Visible = false
overlay.Parent = screenGui

local unitPanel = Instance.new("Frame")
unitPanel.Name = "UnitPanel"
unitPanel.Size = UDim2.fromOffset(520, 520)
unitPanel.Position = UDim2.new(0.5, -260, 0.5, -260)
unitPanel.AnchorPoint = Vector2.new(0, 0)
unitPanel.BackgroundColor3 = Color3.fromRGB(21, 21, 29)
unitPanel.BorderSizePixel = 0
unitPanel.Visible = false
unitPanel.Parent = overlay

local headerFrame = Instance.new("Frame")
headerFrame.Name = "HeaderFrame"
headerFrame.Size = UDim2.fromOffset(520, 64)
headerFrame.Position = UDim2.fromOffset(0, 0)
headerFrame.BackgroundColor3 = Color3.fromRGB(33, 33, 44)
headerFrame.BorderSizePixel = 0
headerFrame.Parent = unitPanel

local panelTitle = Instance.new("TextLabel")
panelTitle.Size = UDim2.fromScale(0.55, 1)
panelTitle.Position = UDim2.fromOffset(16, 0)
panelTitle.BackgroundTransparency = 1
panelTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
panelTitle.Font = Enum.Font.GothamBold
panelTitle.TextScaled = true
panelTitle.Text = "Units"
panelTitle.TextXAlignment = Enum.TextXAlignment.Left
panelTitle.Parent = headerFrame

local countLabel = Instance.new("TextLabel")
countLabel.Name = "CountLabel"
countLabel.Size = UDim2.fromScale(0.30, 1)
countLabel.Position = UDim2.fromScale(0.56, 0)
countLabel.BackgroundTransparency = 1
countLabel.TextColor3 = Color3.fromRGB(193, 225, 255)
countLabel.Font = Enum.Font.Gotham
countLabel.TextScaled = true
countLabel.Text = ""
countLabel.TextXAlignment = Enum.TextXAlignment.Right
countLabel.Parent = headerFrame

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.fromOffset(56, 56)
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -12, 0.5, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(183, 62, 62)
closeButton.BorderSizePixel = 0
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextScaled = true
closeButton.Text = "X"
closeButton.Parent = headerFrame

local unitList = Instance.new("ScrollingFrame")
unitList.Name = "UnitList"
unitList.Size = UDim2.fromOffset(500, 420)
unitList.Position = UDim2.fromOffset(10, 80)
unitList.BackgroundTransparency = 1
unitList.BorderSizePixel = 0
unitList.CanvasSize = UDim2.fromOffset(0, 0)
unitList.ScrollBarThickness = 10
unitList.Parent = unitPanel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = unitList

local noUnitsLabel = Instance.new("TextLabel")
noUnitsLabel.Size = UDim2.new(1, 0, 0, 30)
noUnitsLabel.Position = UDim2.fromOffset(10, 100)
noUnitsLabel.BackgroundTransparency = 1
noUnitsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
noUnitsLabel.Font = Enum.Font.Gotham
noUnitsLabel.TextScaled = true
noUnitsLabel.Text = "No units yet."
noUnitsLabel.TextXAlignment = Enum.TextXAlignment.Left
noUnitsLabel.Parent = unitPanel
noUnitsLabel.Visible = false

local function clearUnitList()
	for _, child in ipairs(unitList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function populateUnitList(units)
	clearUnitList()
	countLabel.Text = string.format("Units %d/%d", #units, 50)

	if #units == 0 then
		noUnitsLabel.Visible = true
		unitList.CanvasSize = UDim2.fromOffset(0, 0)
		return
	end

	noUnitsLabel.Visible = false
	for _, unit in ipairs(units) do
		local row = Instance.new("Frame")
		row.Size = UDim2.fromOffset(500, 90)
		row.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
		row.BorderSizePixel = 0
		row.Parent = unitList

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.fromScale(0.6, 0.45)
		nameLabel.Position = UDim2.fromOffset(16, 12)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextScaled = true
		nameLabel.Text = unit.DisplayName
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		local typeLabel = Instance.new("TextLabel")
		typeLabel.Size = UDim2.fromScale(0.25, 0.28)
		typeLabel.Position = UDim2.fromOffset(16, 48)
		typeLabel.BackgroundTransparency = 1
		typeLabel.TextColor3 = Color3.fromRGB(150, 210, 255)
		typeLabel.Font = Enum.Font.Gotham
		typeLabel.TextScaled = true
		typeLabel.Text = unit.Type
		typeLabel.TextXAlignment = Enum.TextXAlignment.Left
		typeLabel.Parent = row

		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Size = UDim2.fromScale(0.2, 0.28)
		rarityLabel.Position = UDim2.fromOffset(340, 12)
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.TextColor3 = Color3.fromRGB(170, 210, 255)
		rarityLabel.Font = Enum.Font.GothamBold
		rarityLabel.TextScaled = true
		rarityLabel.Text = unit.Rarity
		rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
		rarityLabel.Parent = row

		local statsLabel = Instance.new("TextLabel")
		statsLabel.Size = UDim2.fromScale(0.65, 0.28)
		statsLabel.Position = UDim2.fromOffset(145, 48)
		statsLabel.BackgroundTransparency = 1
		statsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		statsLabel.Font = Enum.Font.Gotham
		statsLabel.TextScaled = true
		statsLabel.Text = string.format("%d★  ATK %d  DEF %d", unit.Stars, unit.Attack, unit.Defense)
		statsLabel.TextXAlignment = Enum.TextXAlignment.Left
		statsLabel.Parent = row
	end

	unitList.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 16)
end

local function openUnitMenu()
	local success, units = pcall(function()
		return unitRequest:InvokeServer()
	end)

	if success and units then
		populateUnitList(units)
		overlay.Visible = true
		unitPanel.Visible = true
	else
		showMessage("Could not load unit list.")
	end
end

unitMenuButton.MouseButton1Click:Connect(openUnitMenu)
closeButton.MouseButton1Click:Connect(function()
	overlay.Visible = false
	unitPanel.Visible = false
end)

overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		overlay.Visible = false
		unitPanel.Visible = false
	end
end)

unitsUpdated.OnClientEvent:Connect(function(units)
	if unitPanel.Visible then
		populateUnitList(units)
	end
end)

summonResult.OnClientEvent:Connect(function(result)
	if result then
		showMessage("Unit summoned: " .. result.DisplayName)
	end
end)

local mailOverlay = Instance.new("Frame")
mailOverlay.Name = "MailOverlay"
mailOverlay.Size = UDim2.fromScale(1, 1)
mailOverlay.Position = UDim2.fromScale(0, 0)
mailOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mailOverlay.BackgroundTransparency = 0.65
mailOverlay.Active = true
mailOverlay.Visible = false
mailOverlay.Parent = screenGui

local mailPanel = Instance.new("Frame")
mailPanel.Name = "MailPanel"
mailPanel.Size = UDim2.fromOffset(460, 340)
mailPanel.Position = UDim2.new(0.5, -230, 0.5, -170)
mailPanel.BackgroundColor3 = Color3.fromRGB(21, 21, 29)
mailPanel.BorderSizePixel = 0
mailPanel.Visible = true
mailPanel.Parent = mailOverlay

local mailPanelCorner = Instance.new("UICorner")
mailPanelCorner.CornerRadius = UDim.new(0, 12)
mailPanelCorner.Parent = mailPanel

local mailHeader = Instance.new("Frame")
mailHeader.Name = "MailHeader"
mailHeader.Size = UDim2.fromOffset(460, 64)
mailHeader.BackgroundColor3 = Color3.fromRGB(33, 33, 44)
mailHeader.BorderSizePixel = 0
mailHeader.Parent = mailPanel

local mailHeaderCorner = Instance.new("UICorner")
mailHeaderCorner.CornerRadius = UDim.new(0, 12)
mailHeaderCorner.Parent = mailHeader

local mailPanelTitle = Instance.new("TextLabel")
mailPanelTitle.Size = UDim2.fromScale(0.7, 1)
mailPanelTitle.Position = UDim2.fromOffset(16, 0)
mailPanelTitle.BackgroundTransparency = 1
mailPanelTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
mailPanelTitle.Font = Enum.Font.GothamBold
mailPanelTitle.TextScaled = true
mailPanelTitle.Text = "Mail"
mailPanelTitle.TextXAlignment = Enum.TextXAlignment.Left
mailPanelTitle.Parent = mailHeader

local mailCloseButton = Instance.new("TextButton")
mailCloseButton.Name = "MailCloseButton"
mailCloseButton.Size = UDim2.fromOffset(56, 56)
mailCloseButton.AnchorPoint = Vector2.new(1, 0.5)
mailCloseButton.Position = UDim2.new(1, -12, 0.5, 0)
mailCloseButton.BackgroundColor3 = Color3.fromRGB(183, 62, 62)
mailCloseButton.BorderSizePixel = 0
mailCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
mailCloseButton.Font = Enum.Font.GothamBold
mailCloseButton.TextScaled = true
mailCloseButton.Text = "X"
mailCloseButton.Parent = mailHeader

local starterCard = Instance.new("Frame")
starterCard.Name = "StarterCard"
starterCard.Size = UDim2.fromOffset(440, 246)
starterCard.Position = UDim2.fromOffset(10, 74)
starterCard.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
starterCard.BorderSizePixel = 0
starterCard.Parent = mailPanel

local starterCardCorner = Instance.new("UICorner")
starterCardCorner.CornerRadius = UDim.new(0, 10)
starterCardCorner.Parent = starterCard

local starterCardTitle = Instance.new("TextLabel")
starterCardTitle.Size = UDim2.new(1, -16, 0, 30)
starterCardTitle.Position = UDim2.fromOffset(12, 12)
starterCardTitle.BackgroundTransparency = 1
starterCardTitle.TextColor3 = Color3.fromRGB(255, 215, 80)
starterCardTitle.Font = Enum.Font.GothamBold
starterCardTitle.TextScaled = true
starterCardTitle.Text = "Starter Pack"
starterCardTitle.TextXAlignment = Enum.TextXAlignment.Left
starterCardTitle.Parent = starterCard

local starterCardDesc = Instance.new("TextLabel")
starterCardDesc.Size = UDim2.new(1, -16, 0, 22)
starterCardDesc.Position = UDim2.fromOffset(12, 46)
starterCardDesc.BackgroundTransparency = 1
starterCardDesc.TextColor3 = Color3.fromRGB(170, 170, 170)
starterCardDesc.Font = Enum.Font.Gotham
starterCardDesc.TextScaled = true
starterCardDesc.Text = "Welcome to Anime Wars! Claim your starter units."
starterCardDesc.TextXAlignment = Enum.TextXAlignment.Left
starterCardDesc.Parent = starterCard

local starterUnitPreviews = {
	{text = "★★★  Water Fairy",    color = Color3.fromRGB(100, 180, 255)},
	{text = "★★    Fire Hound",    color = Color3.fromRGB(255, 120,  60)},
	{text = "★★    Wind Vagabond", color = Color3.fromRGB(100, 220, 140)},
}

for i, preview in ipairs(starterUnitPreviews) do
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -16, 0, 26)
	label.Position = UDim2.fromOffset(12, 74 + (i - 1) * 30)
	label.BackgroundTransparency = 1
	label.TextColor3 = preview.color
	label.Font = Enum.Font.GothamMedium
	label.TextScaled = true
	label.Text = preview.text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = starterCard
end

local claimButton = Instance.new("TextButton")
claimButton.Name = "ClaimButton"
claimButton.Size = UDim2.fromOffset(120, 40)
claimButton.Position = UDim2.new(1, -132, 1, -52)
claimButton.BackgroundColor3 = Color3.fromRGB(76, 196, 132)
claimButton.BorderSizePixel = 0
claimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
claimButton.Font = Enum.Font.GothamBold
claimButton.TextScaled = true
claimButton.Text = "Claim"
claimButton.Parent = starterCard

local claimButtonCorner = Instance.new("UICorner")
claimButtonCorner.CornerRadius = UDim.new(0, 10)
claimButtonCorner.Parent = claimButton

local function setClaimedState()
	claimButton.Text = "Claimed"
	claimButton.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
	claimButton.Active = false
end

local function openMailPanel()
	mailOverlay.Visible = true

	local mailStatusRemote = remotes:WaitForChild("MailStatus", 10)
	if not mailStatusRemote then
		claimButton.Text = "Claim"
		claimButton.BackgroundColor3 = Color3.fromRGB(76, 196, 132)
		claimButton.Active = true
		return
	end

	local success, status = pcall(function()
		return mailStatusRemote:InvokeServer()
	end)

	if success and status and status.starterPackClaimed then
		setClaimedState()
	else
		claimButton.Text = "Claim"
		claimButton.BackgroundColor3 = Color3.fromRGB(76, 196, 132)
		claimButton.Active = true
	end
end

mailButton.MouseButton1Click:Connect(openMailPanel)

mailCloseButton.MouseButton1Click:Connect(function()
	mailOverlay.Visible = false
end)

mailOverlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		mailOverlay.Visible = false
	end
end)

claimButton.MouseButton1Click:Connect(function()
	if not claimButton.Active then return end

	claimButton.Active = false
	claimButton.Text = "..."

	local claimRemote = remotes:WaitForChild("ClaimStarterPack", 10)
	local success, claimed = pcall(function()
		return claimRemote and claimRemote:InvokeServer()
	end)

	if success and claimed then
		setClaimedState()
		showMessage("Starter Pack claimed! Check your units.")
	else
		claimButton.Text = "Claim"
		claimButton.Active = true
		showMessage("Could not claim. Try again.")
	end
end)

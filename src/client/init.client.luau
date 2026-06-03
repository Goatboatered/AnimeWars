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

local openBattlePrep -- forward declaration

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
		openBattlePrep(selectedArea, text)
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

local unitDetailPanel = Instance.new("Frame")
unitDetailPanel.Name = "UnitDetailPanel"
unitDetailPanel.Size = UDim2.fromOffset(520, 300)
unitDetailPanel.Position = UDim2.new(0.5, -260, 0.5, -150)
unitDetailPanel.BackgroundColor3 = Color3.fromRGB(21, 21, 29)
unitDetailPanel.BorderSizePixel = 0
unitDetailPanel.Visible = false
unitDetailPanel.Parent = overlay

local detailPanelCorner = Instance.new("UICorner")
detailPanelCorner.CornerRadius = UDim.new(0, 12)
detailPanelCorner.Parent = unitDetailPanel

local detailHeader = Instance.new("Frame")
detailHeader.Size = UDim2.fromOffset(520, 64)
detailHeader.BackgroundColor3 = Color3.fromRGB(33, 33, 44)
detailHeader.BorderSizePixel = 0
detailHeader.Parent = unitDetailPanel

local detailHeaderCorner = Instance.new("UICorner")
detailHeaderCorner.CornerRadius = UDim.new(0, 12)
detailHeaderCorner.Parent = detailHeader

local detailNameLabel = Instance.new("TextLabel")
detailNameLabel.Size = UDim2.fromScale(0.72, 1)
detailNameLabel.Position = UDim2.fromOffset(16, 0)
detailNameLabel.BackgroundTransparency = 1
detailNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
detailNameLabel.Font = Enum.Font.GothamBold
detailNameLabel.TextScaled = true
detailNameLabel.Text = ""
detailNameLabel.TextXAlignment = Enum.TextXAlignment.Left
detailNameLabel.Parent = detailHeader

local detailRarityLabel = Instance.new("TextLabel")
detailRarityLabel.Size = UDim2.fromScale(0.25, 0.5)
detailRarityLabel.Position = UDim2.new(0.73, 0, 0.25, 0)
detailRarityLabel.BackgroundTransparency = 1
detailRarityLabel.TextColor3 = Color3.fromRGB(170, 210, 255)
detailRarityLabel.Font = Enum.Font.GothamBold
detailRarityLabel.TextScaled = true
detailRarityLabel.Text = ""
detailRarityLabel.TextXAlignment = Enum.TextXAlignment.Left
detailRarityLabel.Parent = detailHeader

local detailStarsLabel = Instance.new("TextLabel")
detailStarsLabel.Size = UDim2.fromOffset(488, 32)
detailStarsLabel.Position = UDim2.fromOffset(16, 80)
detailStarsLabel.BackgroundTransparency = 1
detailStarsLabel.TextColor3 = Color3.fromRGB(255, 215, 80)
detailStarsLabel.Font = Enum.Font.GothamBold
detailStarsLabel.TextScaled = true
detailStarsLabel.Text = ""
detailStarsLabel.TextXAlignment = Enum.TextXAlignment.Left
detailStarsLabel.Parent = unitDetailPanel

local detailInfoLabel = Instance.new("TextLabel")
detailInfoLabel.Size = UDim2.fromOffset(488, 28)
detailInfoLabel.Position = UDim2.fromOffset(16, 120)
detailInfoLabel.BackgroundTransparency = 1
detailInfoLabel.TextColor3 = Color3.fromRGB(150, 210, 255)
detailInfoLabel.Font = Enum.Font.Gotham
detailInfoLabel.TextScaled = true
detailInfoLabel.Text = ""
detailInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
detailInfoLabel.Parent = unitDetailPanel

local detailStatsLabel = Instance.new("TextLabel")
detailStatsLabel.Size = UDim2.fromOffset(488, 28)
detailStatsLabel.Position = UDim2.fromOffset(16, 156)
detailStatsLabel.BackgroundTransparency = 1
detailStatsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
detailStatsLabel.Font = Enum.Font.Gotham
detailStatsLabel.TextScaled = true
detailStatsLabel.Text = ""
detailStatsLabel.TextXAlignment = Enum.TextXAlignment.Left
detailStatsLabel.Parent = unitDetailPanel

local function makeDetailButton(text, xPos, color)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(150, 50)
	btn.Position = UDim2.fromOffset(xPos, 210)
	btn.BackgroundColor3 = color
	btn.BorderSizePixel = 0
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.Text = text
	btn.Parent = unitDetailPanel
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = btn
	return btn
end

local displayButton = makeDetailButton("Display", 17,  Color3.fromRGB(60, 130, 220))
local deleteButton  = makeDetailButton("Delete",  184, Color3.fromRGB(183, 62, 62))
local backButton    = makeDetailButton("← Back",  351, Color3.fromRGB(55, 65, 85))

local selectedUnit = nil
local displayedUnits = {}
local openUnitMenu -- forward declaration

local function openUnitDetail(unit)
	selectedUnit = unit
	detailNameLabel.Text  = unit.DisplayName
	detailRarityLabel.Text = unit.Rarity
	detailStarsLabel.Text  = string.rep("★", unit.Stars) .. string.rep("☆", math.max(0, 5 - unit.Stars))
	detailInfoLabel.Text   = unit.Type .. "  ·  " .. unit.Rarity
	detailStatsLabel.Text  = string.format("ATK %d   DEF %d", unit.Attack, unit.Defense)
	if displayedUnits[unit.Id] then
		displayButton.Text = "Undisplay"
		displayButton.BackgroundColor3 = Color3.fromRGB(100, 80, 160)
	else
		displayButton.Text = "Display"
		displayButton.BackgroundColor3 = Color3.fromRGB(60, 130, 220)
	end
	unitPanel.Visible = false
	unitDetailPanel.Visible = true
end

backButton.MouseButton1Click:Connect(function()
	unitDetailPanel.Visible = false
	unitPanel.Visible = true
end)

-- Delete confirmation dialog
local confirmFrame = Instance.new("Frame")
confirmFrame.Name = "ConfirmFrame"
confirmFrame.Size = UDim2.fromScale(1, 1)
confirmFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
confirmFrame.BackgroundTransparency = 0.55
confirmFrame.Active = true
confirmFrame.Visible = false
confirmFrame.Parent = screenGui

local confirmPanel = Instance.new("Frame")
confirmPanel.Size = UDim2.fromOffset(420, 190)
confirmPanel.Position = UDim2.new(0.5, -210, 0.5, -95)
confirmPanel.BackgroundColor3 = Color3.fromRGB(21, 21, 29)
confirmPanel.BorderSizePixel = 0
confirmPanel.Parent = confirmFrame

local confirmPanelCorner = Instance.new("UICorner")
confirmPanelCorner.CornerRadius = UDim.new(0, 12)
confirmPanelCorner.Parent = confirmPanel

local confirmText = Instance.new("TextLabel")
confirmText.Size = UDim2.new(1, -32, 0, 80)
confirmText.Position = UDim2.fromOffset(16, 16)
confirmText.BackgroundTransparency = 1
confirmText.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmText.Font = Enum.Font.GothamMedium
confirmText.TextScaled = true
confirmText.TextWrapped = true
confirmText.Text = "Are you sure you want to delete this unit?"
confirmText.Parent = confirmPanel

local confirmNoBtn = Instance.new("TextButton")
confirmNoBtn.Size = UDim2.fromOffset(180, 52)
confirmNoBtn.Position = UDim2.fromOffset(16, 118)
confirmNoBtn.BackgroundColor3 = Color3.fromRGB(55, 65, 85)
confirmNoBtn.BorderSizePixel = 0
confirmNoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmNoBtn.Font = Enum.Font.GothamBold
confirmNoBtn.TextScaled = true
confirmNoBtn.Text = "NO"
confirmNoBtn.Parent = confirmPanel

local confirmNoBtnCorner = Instance.new("UICorner")
confirmNoBtnCorner.CornerRadius = UDim.new(0, 10)
confirmNoBtnCorner.Parent = confirmNoBtn

local confirmDeleteBtn = Instance.new("TextButton")
confirmDeleteBtn.Size = UDim2.fromOffset(180, 52)
confirmDeleteBtn.Position = UDim2.fromOffset(224, 118)
confirmDeleteBtn.BackgroundColor3 = Color3.fromRGB(183, 62, 62)
confirmDeleteBtn.BorderSizePixel = 0
confirmDeleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmDeleteBtn.Font = Enum.Font.GothamBold
confirmDeleteBtn.TextScaled = true
confirmDeleteBtn.Text = "Delete"
confirmDeleteBtn.Parent = confirmPanel

local confirmDeleteBtnCorner = Instance.new("UICorner")
confirmDeleteBtnCorner.CornerRadius = UDim.new(0, 10)
confirmDeleteBtnCorner.Parent = confirmDeleteBtn

displayButton.MouseButton1Click:Connect(function()
	if not selectedUnit then return end
	if displayButton.Text == "Undisplay" then
		local undisplayRemote = remotes:FindFirstChild("UndisplayUnit")
		if undisplayRemote then
			undisplayRemote:FireServer(selectedUnit.Id)
		end
		displayedUnits[selectedUnit.Id] = nil
		displayButton.Text = "Display"
		displayButton.BackgroundColor3 = Color3.fromRGB(60, 130, 220)
	else
		local displayUnitRemote = remotes:FindFirstChild("DisplayUnit")
		if displayUnitRemote then
			displayUnitRemote:FireServer(selectedUnit.Type, selectedUnit.DisplayName, selectedUnit.Id)
		end
		displayedUnits[selectedUnit.Id] = true
		displayButton.Text = "Undisplay"
		displayButton.BackgroundColor3 = Color3.fromRGB(100, 80, 160)
	end
end)

deleteButton.MouseButton1Click:Connect(function()
	confirmFrame.Visible = true
end)

confirmNoBtn.MouseButton1Click:Connect(function()
	confirmFrame.Visible = false
end)

confirmDeleteBtn.MouseButton1Click:Connect(function()
	if not selectedUnit then return end
	confirmFrame.Visible = false
	unitDetailPanel.Visible = false

	if displayedUnits[selectedUnit.Id] then
		local undisplayRemote = remotes:FindFirstChild("UndisplayUnit")
		if undisplayRemote then
			undisplayRemote:FireServer(selectedUnit.Id)
		end
		displayedUnits[selectedUnit.Id] = nil
	end

	local deleteRemote = remotes:WaitForChild("DeleteUnit", 5)
	if deleteRemote then
		pcall(function()
			deleteRemote:InvokeServer(selectedUnit.Id)
		end)
	end

	selectedUnit = nil
	openUnitMenu()
end)

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

		local rowButton = Instance.new("TextButton")
		rowButton.Size = UDim2.fromScale(1, 1)
		rowButton.BackgroundTransparency = 1
		rowButton.Text = ""
		rowButton.ZIndex = 2
		rowButton.Parent = row
		rowButton.MouseButton1Click:Connect(function()
			openUnitDetail(unit)
		end)
	end

	unitList.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 16)
end

openUnitMenu = function()
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

-- ================================================
-- BATTLE PREP SCREEN
-- ================================================

local BATTLE_COLORS = {
	Water = Color3.fromRGB(50, 100, 200),
	Fire  = Color3.fromRGB(200, 55, 35),
	Wind  = Color3.fromRGB(185, 160, 30),
}
local BATTLE_DEFAULT_COLOR = Color3.fromRGB(75, 55, 110)

local battlePrepScreen = Instance.new("Frame")
battlePrepScreen.Name = "BattlePrepScreen"
battlePrepScreen.Size = UDim2.fromScale(1, 1)
battlePrepScreen.BackgroundColor3 = Color3.fromRGB(14, 16, 26)
battlePrepScreen.BorderSizePixel = 0
battlePrepScreen.Visible = false
battlePrepScreen.Parent = screenGui

-- Header
local bpHeader = Instance.new("Frame")
bpHeader.Size = UDim2.new(1, 0, 0, 52)
bpHeader.BackgroundColor3 = Color3.fromRGB(20, 23, 36)
bpHeader.BorderSizePixel = 0
bpHeader.Parent = battlePrepScreen

local bpBackBtn = Instance.new("TextButton")
bpBackBtn.Size = UDim2.fromOffset(90, 38)
bpBackBtn.Position = UDim2.new(0, 8, 0.5, -19)
bpBackBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 65)
bpBackBtn.BorderSizePixel = 0
bpBackBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
bpBackBtn.Font = Enum.Font.GothamBold
bpBackBtn.TextScaled = true
bpBackBtn.Text = "← Back"
bpBackBtn.Parent = bpHeader

local bpBackCorner = Instance.new("UICorner")
bpBackCorner.CornerRadius = UDim.new(0, 8)
bpBackCorner.Parent = bpBackBtn

local bpTitle = Instance.new("TextLabel")
bpTitle.Size = UDim2.new(1, -116, 1, 0)
bpTitle.Position = UDim2.fromOffset(106, 0)
bpTitle.BackgroundTransparency = 1
bpTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
bpTitle.Font = Enum.Font.GothamBold
bpTitle.TextScaled = true
bpTitle.Text = "Battle Preparation"
bpTitle.TextXAlignment = Enum.TextXAlignment.Left
bpTitle.Parent = bpHeader

bpBackBtn.MouseButton1Click:Connect(function()
	battlePrepScreen.Visible = false
	stageMenu.Visible = true
end)

-- Battle area
local bpBattleArea = Instance.new("Frame")
bpBattleArea.Size = UDim2.new(1, 0, 0, 260)
bpBattleArea.Position = UDim2.fromOffset(0, 52)
bpBattleArea.BackgroundColor3 = Color3.fromRGB(18, 21, 33)
bpBattleArea.BorderSizePixel = 0
bpBattleArea.Parent = battlePrepScreen

-- Player slots (2x2 grid, left)
local bpPlayerSection = Instance.new("Frame")
bpPlayerSection.Size = UDim2.fromOffset(216, 216)
bpPlayerSection.Position = UDim2.new(0.08, 0, 0.5, -108)
bpPlayerSection.BackgroundTransparency = 1
bpPlayerSection.Parent = bpBattleArea

local battleSlots = {}
local slotGridPos = {
	UDim2.fromOffset(0,   0),
	UDim2.fromOffset(112, 0),
	UDim2.fromOffset(0,   112),
	UDim2.fromOffset(112, 112),
}

for i = 1, 4 do
	local sf = Instance.new("Frame")
	sf.Size = UDim2.fromOffset(104, 104)
	sf.Position = slotGridPos[i]
	sf.BackgroundColor3 = Color3.fromRGB(28, 32, 48)
	sf.BorderSizePixel = 0
	sf.Parent = bpPlayerSection

	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 10)
	sc.Parent = sf

	local ss = Instance.new("UIStroke")
	ss.Color = Color3.fromRGB(55, 75, 120)
	ss.Thickness = 2
	ss.Parent = sf

	local sl = Instance.new("TextLabel")
	sl.Size = UDim2.fromScale(1, 1)
	sl.BackgroundTransparency = 1
	sl.TextColor3 = Color3.fromRGB(70, 90, 130)
	sl.Font = Enum.Font.GothamBold
	sl.TextScaled = true
	sl.Text = "+"
	sl.TextWrapped = true
	sl.Parent = sf

	battleSlots[i] = { unit = nil, frame = sf, label = sl, stroke = ss }
end

-- VS label
local bpVS = Instance.new("TextLabel")
bpVS.Size = UDim2.fromOffset(70, 50)
bpVS.Position = UDim2.new(0.5, -35, 0.5, -25)
bpVS.BackgroundTransparency = 1
bpVS.TextColor3 = Color3.fromRGB(255, 255, 255)
bpVS.Font = Enum.Font.GothamBlack
bpVS.TextScaled = true
bpVS.Text = "VS"
bpVS.Parent = bpBattleArea

-- Enemy slot (right, blank for now)
local bpEnemySlot = Instance.new("Frame")
bpEnemySlot.Size = UDim2.fromOffset(120, 120)
bpEnemySlot.Position = UDim2.new(0.78, -60, 0.5, -60)
bpEnemySlot.BackgroundColor3 = Color3.fromRGB(35, 18, 18)
bpEnemySlot.BorderSizePixel = 0
bpEnemySlot.Parent = bpBattleArea

local bpEnemyCorner = Instance.new("UICorner")
bpEnemyCorner.CornerRadius = UDim.new(0, 10)
bpEnemyCorner.Parent = bpEnemySlot

local bpEnemyStroke = Instance.new("UIStroke")
bpEnemyStroke.Color = Color3.fromRGB(140, 50, 50)
bpEnemyStroke.Thickness = 2
bpEnemyStroke.Parent = bpEnemySlot

local bpEnemyLabel = Instance.new("TextLabel")
bpEnemyLabel.Size = UDim2.fromScale(1, 1)
bpEnemyLabel.BackgroundTransparency = 1
bpEnemyLabel.TextColor3 = Color3.fromRGB(140, 70, 70)
bpEnemyLabel.Font = Enum.Font.GothamBold
bpEnemyLabel.TextScaled = true
bpEnemyLabel.Text = "?"
bpEnemyLabel.Parent = bpEnemySlot

local bpBeginBtn = Instance.new("TextButton")
bpBeginBtn.Size = UDim2.fromOffset(120, 40)
bpBeginBtn.Position = UDim2.new(0.78, -60, 0, 200)
bpBeginBtn.BackgroundColor3 = Color3.fromRGB(38, 40, 55)
bpBeginBtn.BorderSizePixel = 0
bpBeginBtn.TextColor3 = Color3.fromRGB(75, 80, 105)
bpBeginBtn.Font = Enum.Font.GothamBlack
bpBeginBtn.TextScaled = true
bpBeginBtn.Text = "Begin"
bpBeginBtn.Active = false
bpBeginBtn.Parent = bpBattleArea

local bpBeginCorner = Instance.new("UICorner")
bpBeginCorner.CornerRadius = UDim.new(0, 10)
bpBeginCorner.Parent = bpBeginBtn

-- Unit scroll bar (bottom, above buttons)
local bpUnitBarBg = Instance.new("Frame")
bpUnitBarBg.Size = UDim2.new(1, 0, 0, 148)
bpUnitBarBg.Position = UDim2.new(0, 0, 1, -212)
bpUnitBarBg.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
bpUnitBarBg.BorderSizePixel = 0
bpUnitBarBg.Parent = battlePrepScreen

local bpUnitScroll = Instance.new("ScrollingFrame")
bpUnitScroll.Size = UDim2.new(1, -8, 1, -10)
bpUnitScroll.Position = UDim2.fromOffset(4, 5)
bpUnitScroll.BackgroundTransparency = 1
bpUnitScroll.BorderSizePixel = 0
bpUnitScroll.ScrollBarThickness = 4
bpUnitScroll.ScrollingDirection = Enum.ScrollingDirection.X
bpUnitScroll.CanvasSize = UDim2.fromOffset(0, 0)
bpUnitScroll.Parent = bpUnitBarBg

local bpScrollLayout = Instance.new("UIListLayout")
bpScrollLayout.Padding = UDim.new(0, 6)
bpScrollLayout.FillDirection = Enum.FillDirection.Horizontal
bpScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
bpScrollLayout.VerticalAlignment = Enum.VerticalAlignment.Center
bpScrollLayout.Parent = bpUnitScroll

-- Bottom buttons
local bpButtonBar = Instance.new("Frame")
bpButtonBar.Size = UDim2.new(1, 0, 0, 64)
bpButtonBar.Position = UDim2.new(0, 0, 1, -64)
bpButtonBar.BackgroundColor3 = Color3.fromRGB(14, 16, 26)
bpButtonBar.BorderSizePixel = 0
bpButtonBar.Parent = battlePrepScreen

local bpStartBtn = Instance.new("TextButton")
bpStartBtn.Size = UDim2.fromOffset(200, 48)
bpStartBtn.Position = UDim2.new(0.5, 8, 0.5, -24)
bpStartBtn.BackgroundColor3 = Color3.fromRGB(255, 191, 64)
bpStartBtn.BorderSizePixel = 0
bpStartBtn.TextColor3 = Color3.fromRGB(20, 20, 30)
bpStartBtn.Font = Enum.Font.GothamBlack
bpStartBtn.TextScaled = true
bpStartBtn.Text = "Start Battle"
bpStartBtn.Parent = bpButtonBar

local bpStartCorner = Instance.new("UICorner")
bpStartCorner.CornerRadius = UDim.new(0, 12)
bpStartCorner.Parent = bpStartBtn

local bpCancelBtn = Instance.new("TextButton")
bpCancelBtn.Size = UDim2.fromOffset(120, 48)
bpCancelBtn.Position = UDim2.new(0.5, -136, 0.5, -24)
bpCancelBtn.BackgroundColor3 = Color3.fromRGB(55, 35, 35)
bpCancelBtn.BorderSizePixel = 0
bpCancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
bpCancelBtn.Font = Enum.Font.GothamBold
bpCancelBtn.TextScaled = true
bpCancelBtn.Text = "Cancel"
bpCancelBtn.Parent = bpButtonBar

local bpCancelCorner = Instance.new("UICorner")
bpCancelCorner.CornerRadius = UDim.new(0, 12)
bpCancelCorner.Parent = bpCancelBtn

-- State
local selectedBattleUnit = nil
local selectedBattleCard = nil

local function updateBeginBtn()
	local hasUnit = false
	for i = 1, 4 do
		if battleSlots[i].unit then
			hasUnit = true
			break
		end
	end
	if hasUnit then
		bpBeginBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
		bpBeginBtn.TextColor3 = Color3.fromRGB(15, 20, 25)
		bpBeginBtn.Active = true
	else
		bpBeginBtn.BackgroundColor3 = Color3.fromRGB(38, 40, 55)
		bpBeginBtn.TextColor3 = Color3.fromRGB(75, 80, 105)
		bpBeginBtn.Active = false
	end
end

local function clearBattleSlot(i)
	local s = battleSlots[i]
	if s.unit then
		local uid = s.unit.Id
		for _, ch in ipairs(bpUnitScroll:GetChildren()) do
			if ch:IsA("Frame") and ch:GetAttribute("UnitId") == uid then
				ch:SetAttribute("InSlot", false)
				ch.BackgroundTransparency = 0
			end
		end
		s.unit = nil
	end
	s.frame.BackgroundColor3 = Color3.fromRGB(28, 32, 48)
	s.label.Text = "+"
	s.label.TextColor3 = Color3.fromRGB(70, 90, 130)
	s.stroke.Color = Color3.fromRGB(55, 75, 120)
	updateBeginBtn()
end

-- Slot buttons
for i = 1, 4 do
	local slotBtn = Instance.new("TextButton")
	slotBtn.Size = UDim2.fromScale(1, 1)
	slotBtn.BackgroundTransparency = 1
	slotBtn.Text = ""
	slotBtn.ZIndex = 2
	slotBtn.Parent = battleSlots[i].frame

	slotBtn.MouseButton1Click:Connect(function()
		local s = battleSlots[i]
		if s.unit then
			clearBattleSlot(i)
		elseif selectedBattleUnit then
			s.unit = selectedBattleUnit
			s.frame.BackgroundColor3 = BATTLE_COLORS[selectedBattleUnit.Type] or BATTLE_DEFAULT_COLOR
			s.label.Text = selectedBattleUnit.DisplayName
			s.label.TextColor3 = Color3.fromRGB(255, 255, 255)
			s.stroke.Color = Color3.fromRGB(180, 200, 255)
			if selectedBattleCard then
				selectedBattleCard:SetAttribute("InSlot", true)
				selectedBattleCard.BackgroundTransparency = 0.6
				local stroke = selectedBattleCard:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Thickness = 0
				end
			end
			selectedBattleUnit = nil
			selectedBattleCard = nil
			updateBeginBtn()
		end
	end)
end

local function populateBpUnits(units)
	for _, ch in ipairs(bpUnitScroll:GetChildren()) do
		if ch:IsA("Frame") then ch:Destroy() end
	end
	selectedBattleUnit = nil
	selectedBattleCard = nil

	for _, unit in ipairs(units) do
		local card = Instance.new("Frame")
		card.Size = UDim2.fromOffset(118, 130)
		card.BackgroundColor3 = BATTLE_COLORS[unit.Type] or BATTLE_DEFAULT_COLOR
		card.BorderSizePixel = 0
		card:SetAttribute("UnitId", unit.Id)
		card:SetAttribute("InSlot", false)
		card.Parent = bpUnitScroll

		local cc = Instance.new("UICorner")
		cc.CornerRadius = UDim.new(0, 8)
		cc.Parent = card

		local cs = Instance.new("UIStroke")
		cs.Color = Color3.fromRGB(255, 255, 255)
		cs.Thickness = 0
		cs.Parent = card

		local starsLbl = Instance.new("TextLabel")
		starsLbl.Size = UDim2.new(1, -6, 0, 22)
		starsLbl.Position = UDim2.fromOffset(3, 5)
		starsLbl.BackgroundTransparency = 1
		starsLbl.TextColor3 = Color3.fromRGB(255, 215, 80)
		starsLbl.Font = Enum.Font.GothamBold
		starsLbl.TextScaled = true
		starsLbl.Text = string.rep("★", unit.Stars)
		starsLbl.Parent = card

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, -8, 0, 64)
		nameLbl.Position = UDim2.new(0, 4, 0.5, -32)
		nameLbl.BackgroundTransparency = 1
		nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextScaled = true
		nameLbl.TextWrapped = true
		nameLbl.Text = unit.DisplayName
		nameLbl.Parent = card

		local cardBtn = Instance.new("TextButton")
		cardBtn.Size = UDim2.fromScale(1, 1)
		cardBtn.BackgroundTransparency = 1
		cardBtn.Text = ""
		cardBtn.ZIndex = 2
		cardBtn.Parent = card

		cardBtn.MouseButton1Click:Connect(function()
			if card:GetAttribute("InSlot") then return end
			if selectedBattleCard == card then
				cs.Thickness = 0
				selectedBattleUnit = nil
				selectedBattleCard = nil
			else
				if selectedBattleCard then
					local prev = selectedBattleCard:FindFirstChildOfClass("UIStroke")
					if prev then
						prev.Thickness = 0
					end
				end
				selectedBattleCard = card
				selectedBattleUnit = unit
				cs.Thickness = 3
			end
		end)
	end

	-- Empty filler boxes up to 50 total
	for _ = 1, math.max(0, 50 - #units) do
		local empty = Instance.new("Frame")
		empty.Size = UDim2.fromOffset(118, 130)
		empty.BackgroundColor3 = Color3.fromRGB(24, 26, 40)
		empty.BorderSizePixel = 0
		empty.Parent = bpUnitScroll
		local ec = Instance.new("UICorner")
		ec.CornerRadius = UDim.new(0, 8)
		ec.Parent = empty
		local es = Instance.new("UIStroke")
		es.Color = Color3.fromRGB(38, 42, 62)
		es.Thickness = 1
		es.Parent = empty
	end

	bpUnitScroll.CanvasSize = UDim2.fromOffset(bpScrollLayout.AbsoluteContentSize.X + 12, 0)
end

openBattlePrep = function(areaName, stageName)
	bpTitle.Text = areaName .. "  —  " .. stageName
	for i = 1, 4 do
		clearBattleSlot(i)
	end
	battlePrepScreen.Visible = true
	local ok, units = pcall(function()
		return unitRequest:InvokeServer()
	end)
	populateBpUnits(ok and units or {})
end

bpBeginBtn.MouseButton1Click:Connect(function()
	if not bpBeginBtn.Active then return end
	showMessage("Battle starting! (coming soon)")
	battlePrepScreen.Visible = false
end)

bpCancelBtn.MouseButton1Click:Connect(function()
	battlePrepScreen.Visible = false
	stageMenu.Visible = true
end)

bpStartBtn.MouseButton1Click:Connect(function()
	showMessage("Battle starting! (coming soon)")
	battlePrepScreen.Visible = false
end)

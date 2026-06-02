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
playButton.MouseButton1Click:Connect(function()
	-- Placeholder for future play logic; do nothing for now.
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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("GachaRemotes")
local shared = ReplicatedStorage:WaitForChild("Shared")
local UnitManager = require(shared:WaitForChild("UnitManager"))
local getUnits = remotes:WaitForChild("GetUnits")
local unitsUpdated = remotes:WaitForChild("UnitsUpdated")
local displayUnitRemote = remotes:WaitForChild("DisplayUnit", 10)
local undisplayUnitRemote = remotes:WaitForChild("UndisplayUnit", 10)

local COLORS = {
	bg = Color3.fromRGB(34, 25, 18),
	header = Color3.fromRGB(216, 158, 77),
	panel = Color3.fromRGB(54, 32, 20),
	panelDark = Color3.fromRGB(31, 24, 22),
	gold = Color3.fromRGB(255, 229, 104),
	text = Color3.fromRGB(246, 232, 198),
	muted = Color3.fromRGB(211, 175, 122),
}

local TYPE_COLORS = {
	Water = Color3.fromRGB(40, 120, 220),
	Fire = Color3.fromRGB(210, 55, 40),
	Wind = Color3.fromRGB(240, 210, 50),
	Light = Color3.fromRGB(240, 240, 240),
	Dark = Color3.fromRGB(130, 60, 200),
	Neutral = Color3.fromRGB(120, 120, 130),
}

local NOOB_YELLOW = Color3.fromRGB(245, 205, 48)
local NOOB_GREEN = Color3.fromRGB(75, 151, 75)
local ANIM_IDLE = "rbxassetid://507766666"
local DEFAULT_PREVIEW_ROTATION = math.pi

local function addStroke(frame, radius, color, thickness, transparency)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = color or COLORS.gold
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0.25
	stroke.Parent = frame
	return stroke
end

local function label(parent, text, pos, size, color, font, textSize)
	local lbl = Instance.new("TextLabel")
	lbl.Size = size
	lbl.Position = pos
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = color or COLORS.text
	lbl.Font = font or Enum.Font.GothamMedium
	lbl.TextSize = textSize or 18
	lbl.TextScaled = false
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Top
	lbl.Parent = parent
	return lbl
end

local gui = Instance.new("ScreenGui")
gui.Name = "UnitViewerUI"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.DisplayOrder = 20
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = COLORS.bg
root.BorderSizePixel = 0
root.Parent = gui

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 64)
header.BackgroundColor3 = COLORS.header
header.BorderSizePixel = 0
header.Parent = root

local title = label(header, "Units", UDim2.new(0.5, -210, 0, 0), UDim2.fromOffset(420, 64), Color3.fromRGB(63, 36, 20), Enum.Font.GothamBlack, 30)
title.TextXAlignment = Enum.TextXAlignment.Center

local countLabel = label(header, "", UDim2.new(0.5, 110, 0, 0), UDim2.fromOffset(150, 64), Color3.fromRGB(88, 50, 28), Enum.Font.GothamBold, 18)

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(52, 52)
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -12, 0.5, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(105, 61, 37)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 232, 178)
closeButton.Font = Enum.Font.GothamBlack
closeButton.TextSize = 30
closeButton.Parent = header
addStroke(closeButton, 6, Color3.fromRGB(255, 225, 151), 2, 0.25)

local visualArea = Instance.new("Frame")
visualArea.Size = UDim2.new(0.46, -36, 1, -188)
visualArea.Position = UDim2.fromOffset(28, 78)
visualArea.BackgroundTransparency = 1
visualArea.Parent = root

local viewport = Instance.new("ViewportFrame")
viewport.Size = UDim2.new(1, 0, 1, -104)
viewport.BackgroundTransparency = 1
viewport.BorderSizePixel = 0
viewport.Ambient = Color3.fromRGB(175, 165, 145)
viewport.LightColor = Color3.fromRGB(255, 236, 190)
viewport.LightDirection = Vector3.new(-1, -1, -0.5)
viewport.Parent = visualArea

local world = Instance.new("WorldModel")
world.Parent = viewport

local camera = Instance.new("Camera")
camera.FieldOfView = 30
camera.CFrame = CFrame.new(0, 3, 14) * CFrame.Angles(math.rad(-4), 0, 0)
camera.Parent = viewport
viewport.CurrentCamera = camera

local nameLabel = label(visualArea, "", UDim2.new(0, 8, 1, -98), UDim2.new(1, -16, 0, 42), COLORS.gold, Enum.Font.GothamBlack, 30)
nameLabel.TextXAlignment = Enum.TextXAlignment.Center
local subLabel = label(visualArea, "", UDim2.new(0, 8, 1, -56), UDim2.new(1, -16, 0, 28), COLORS.muted, Enum.Font.GothamBold, 18)
subLabel.TextXAlignment = Enum.TextXAlignment.Center

local displayButton = Instance.new("TextButton")
displayButton.Size = UDim2.fromOffset(150, 46)
displayButton.Position = UDim2.fromOffset(8, 12)
displayButton.BackgroundColor3 = Color3.fromRGB(56, 106, 173)
displayButton.BorderSizePixel = 0
displayButton.Text = "Display"
displayButton.TextColor3 = Color3.fromRGB(255, 239, 197)
displayButton.Font = Enum.Font.GothamBlack
displayButton.TextSize = 18
displayButton.Parent = visualArea
addStroke(displayButton, 7, Color3.fromRGB(255, 231, 164), 1, 0.45)

local tabs = Instance.new("Frame")
tabs.Size = UDim2.fromOffset(146, 260)
tabs.Position = UDim2.new(0.48, -72, 0.5, -150)
tabs.BackgroundTransparency = 1
tabs.Parent = root

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 12)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabs

local content = Instance.new("Frame")
content.Size = UDim2.new(0.48, -42, 1, -220)
content.Position = UDim2.new(0.52, 12, 0, 116)
content.BackgroundColor3 = COLORS.panel
content.BorderSizePixel = 0
content.Parent = root
addStroke(content, 8, Color3.fromRGB(184, 129, 62), 2, 0.1)

local contentTitle = label(content, "Info", UDim2.fromOffset(16, 14), UDim2.new(1, -32, 0, 42), Color3.fromRGB(255, 231, 152), Enum.Font.GothamBlack, 28)

local body = Instance.new("Frame")
body.Size = UDim2.new(1, -32, 1, -78)
body.Position = UDim2.fromOffset(16, 64)
body.BackgroundColor3 = COLORS.panelDark
body.BorderSizePixel = 0
body.Parent = content
addStroke(body, 6, Color3.fromRGB(111, 74, 43), 1, 0.35)

local inventoryBar = Instance.new("Frame")
inventoryBar.Size = UDim2.new(1, 0, 0, 120)
inventoryBar.Position = UDim2.new(0, 0, 1, -120)
inventoryBar.BackgroundColor3 = Color3.fromRGB(38, 24, 15)
inventoryBar.BorderSizePixel = 0
inventoryBar.Parent = root

local inventory = Instance.new("ScrollingFrame")
inventory.Size = UDim2.new(1, -32, 1, -16)
inventory.Position = UDim2.fromOffset(16, 8)
inventory.BackgroundTransparency = 1
inventory.BorderSizePixel = 0
inventory.CanvasSize = UDim2.fromOffset(0, 0)
inventory.ScrollBarThickness = 6
inventory.ScrollingDirection = Enum.ScrollingDirection.X
inventory.Parent = inventoryBar

local invLayout = Instance.new("UIListLayout")
invLayout.Padding = UDim.new(0, 8)
invLayout.FillDirection = Enum.FillDirection.Horizontal
invLayout.VerticalAlignment = Enum.VerticalAlignment.Center
invLayout.SortOrder = Enum.SortOrder.LayoutOrder
invLayout.Parent = inventory

local selectedUnit = nil
local selectedTab = "Info"
local currentUnits = {}
local tabButtons = {}
local previewModel = nil
local rotation = 0
local dragging = false
local lastX = 0
local displayedUnits = {}

local function pct(v)
	return string.format("%.0f%%", (v or 0) * 100)
end

local function xpNeededFor(level)
	if UnitManager.XPToNextLevel then
		return UnitManager.XPToNextLevel(level)
	end
	return math.floor(250 * level * level)
end

local function displayKey(unitOrId)
	local id = typeof(unitOrId) == "table" and unitOrId.Id or unitOrId
	return id and tostring(id) or nil
end

local function displayedCount()
	local count = 0
	for _ in pairs(displayedUnits) do
		count += 1
	end
	return count
end

local function updateDisplayButton()
	if selectedUnit and displayedUnits[displayKey(selectedUnit)] then
		displayButton.Text = "Undisplay"
		displayButton.BackgroundColor3 = Color3.fromRGB(109, 86, 164)
	else
		displayButton.Text = "Display"
		displayButton.BackgroundColor3 = Color3.fromRGB(56, 106, 173)
	end
end

local function clearBody()
	for _, child in ipairs(body:GetChildren()) do
		if not child:IsA("UICorner") and not child:IsA("UIStroke") then
			child:Destroy()
		end
	end
end

local function framePreviewCamera()
	if not previewModel then return end

	local boxCFrame, boxSize = previewModel:GetBoundingBox()
	local center = boxCFrame.Position
	local maxSize = math.max(boxSize.X, boxSize.Y, boxSize.Z)
	local distance = math.max(9, maxSize * 2.45)
	local target = center + Vector3.new(0, boxSize.Y * 0.06, 0)
	local cameraPosition = target + Vector3.new(0, boxSize.Y * 0.08, distance)
	camera.CFrame = CFrame.lookAt(cameraPosition, target)
end

local function buildPreview(unit)
	if previewModel then
		previewModel:Destroy()
	end

	local tint = TYPE_COLORS[unit.Type] or TYPE_COLORS.Neutral

	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = NOOB_YELLOW
	desc.TorsoColor = tint
	desc.LeftArmColor = NOOB_YELLOW
	desc.RightArmColor = NOOB_YELLOW
	desc.LeftLegColor = NOOB_GREEN
	desc.RightLegColor = NOOB_GREEN

	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		model = Instance.new("Model")
		model.Name = "PreviewFallback"

		local function part(name, size, cf, color, material, shape)
			local p = Instance.new("Part")
			p.Name = name
			p.Size = size
			p.CFrame = cf
			p.Color = color
			p.Material = material or Enum.Material.SmoothPlastic
			p.Shape = shape or Enum.PartType.Block
			p.Anchored = true
			p.CanCollide = false
			p.Parent = model
			return p
		end

		part("Body", Vector3.new(1.5, 2.2, 0.8), CFrame.new(0, 1.7, 0), tint)
		part("Head", Vector3.new(1.05, 1.05, 1.05), CFrame.new(0, 3.55, 0), NOOB_YELLOW, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		part("LeftArm", Vector3.new(0.42, 1.6, 0.42), CFrame.new(-1.05, 1.8, 0), NOOB_YELLOW)
		part("RightArm", Vector3.new(0.42, 1.6, 0.42), CFrame.new(1.05, 1.8, 0), NOOB_YELLOW)
		part("LeftLeg", Vector3.new(0.5, 1.65, 0.5), CFrame.new(-0.42, 0.25, 0), NOOB_GREEN)
		part("RightLeg", Vector3.new(0.5, 1.65, 0.5), CFrame.new(0.42, 0.25, 0), NOOB_GREEN)
		local rootPart = part("Root", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 1.45, 0), Color3.new(1, 1, 1))
		rootPart.Transparency = 1
		model.PrimaryPart = rootPart
	else
		model.Name = unit.DisplayName or "PreviewUnit"
		local rootPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
		if rootPart then
			model.PrimaryPart = rootPart
		end
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
			elseif descendant:IsA("Script") or descendant:IsA("LocalScript") then
				descendant:Destroy()
			end
		end
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			local animator = humanoid:FindFirstChildOfClass("Animator")
			if not animator then
				animator = Instance.new("Animator")
				animator.Parent = humanoid
			end

			local idleAnimation = Instance.new("Animation")
			idleAnimation.AnimationId = ANIM_IDLE
			local idleTrack = animator:LoadAnimation(idleAnimation)
			idleTrack.Looped = true
			idleTrack:Play()
		end
	end

	model.Parent = world
	previewModel = model
	rotation = DEFAULT_PREVIEW_ROTATION
	model:PivotTo(CFrame.Angles(0, rotation, 0))
	framePreviewCamera()
end

local function updatePreview()
	if previewModel and previewModel.PrimaryPart then
		previewModel:PivotTo(CFrame.Angles(0, rotation, 0))
		framePreviewCamera()
	end
end

local function renderInfo(unit)
	clearBody()
	local maxLevel = UnitManager.MAX_LEVEL or 40
	local level = unit.Level or 1
	local xp = unit.XP or 0
	local needed = xpNeededFor(level)
	local isMaxLevel = level >= maxLevel or needed == math.huge
	local xpRatio = isMaxLevel and 1 or math.clamp(xp / needed, 0, 1)
	local stats = {
		{"Level", tostring(level) .. " / " .. tostring(maxLevel)},
		{"HP", tostring(unit.HP or 0)},
		{"ATK", tostring(unit.Attack or 0)},
		{"DEF", tostring(unit.Defense or 0)},
		{"SPD", tostring(unit.Speed or 0)},
		{"Crit Rate", pct(unit.CritChance)},
		{"Crit Dmg", pct((unit.CritDamage or 1.5) - 1)},
		{"Resistance", pct(unit.Resistance)},
		{"Accuracy", pct(unit.Accuracy)},
	}
	for i, stat in ipairs(stats) do
		local y = 16 + (i - 1) * 31
		label(body, stat[1], UDim2.fromOffset(18, y), UDim2.fromOffset(160, 26), Color3.fromRGB(255, 232, 152), Enum.Font.GothamBold, 18)
		local value = label(body, stat[2], UDim2.new(1, -178, 0, y), UDim2.fromOffset(142, 26), COLORS.text, Enum.Font.GothamMedium, 18)
		value.TextXAlignment = Enum.TextXAlignment.Right
	end

	local xpTitle = label(body, "EXP", UDim2.new(0, 18, 1, -74), UDim2.fromOffset(70, 22), Color3.fromRGB(255, 232, 152), Enum.Font.GothamBold, 18)
	xpTitle.TextYAlignment = Enum.TextYAlignment.Center

	local xpText = isMaxLevel and "MAX" or string.format("%d / %d  (%d%%)", xp, needed, math.floor(xpRatio * 100 + 0.5))
	local xpValue = label(body, xpText, UDim2.new(1, -250, 1, -74), UDim2.fromOffset(220, 22), COLORS.text, Enum.Font.GothamBold, 16)
	xpValue.TextXAlignment = Enum.TextXAlignment.Right
	xpValue.TextYAlignment = Enum.TextYAlignment.Center

	local xpBg = Instance.new("Frame")
	xpBg.Size = UDim2.new(1, -36, 0, 18)
	xpBg.Position = UDim2.new(0, 18, 1, -42)
	xpBg.BackgroundColor3 = Color3.fromRGB(20, 13, 10)
	xpBg.BorderSizePixel = 0
	xpBg.Parent = body
	addStroke(xpBg, 5, Color3.fromRGB(112, 76, 43), 1, 0.45)

	local xpFill = Instance.new("Frame")
	xpFill.Size = UDim2.fromScale(xpRatio, 1)
	xpFill.BackgroundColor3 = Color3.fromRGB(84, 195, 116)
	xpFill.BorderSizePixel = 0
	xpFill.Parent = xpBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 5)
	fillCorner.Parent = xpFill
end

local function renderSkills(unit)
	clearBody()
	local skills = unit.Abilities or {}
	if #skills == 0 then
		label(body, "No skills found for this unit.", UDim2.fromOffset(18, 18), UDim2.new(1, -36, 0, 32), COLORS.muted, Enum.Font.GothamBold, 18)
		return
	end
	for i, skill in ipairs(skills) do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, -28, 0, 108)
		card.Position = UDim2.fromOffset(14, 14 + (i - 1) * 118)
		card.BackgroundColor3 = Color3.fromRGB(219, 177, 103)
		card.BorderSizePixel = 0
		card.Parent = body
		addStroke(card, 7, Color3.fromRGB(253, 222, 143), 1, 0.35)
		label(card, skill.Name or "Skill", UDim2.fromOffset(12, 9), UDim2.new(1, -24, 0, 26), Color3.fromRGB(64, 38, 20), Enum.Font.GothamBlack, 20)
		label(card, skill.Description or "No description.", UDim2.fromOffset(12, 40), UDim2.new(1, -24, 0, 58), Color3.fromRGB(58, 34, 20), Enum.Font.GothamMedium, 15)
	end
end

local function renderComingSoon(name)
	clearBody()
	label(body, name, UDim2.fromOffset(18, 34), UDim2.new(1, -36, 0, 34), Color3.fromRGB(255, 232, 152), Enum.Font.GothamBlack, 24)
	local coming = label(body, "Coming soon", UDim2.fromOffset(18, 82), UDim2.new(1, -36, 0, 46), COLORS.text, Enum.Font.GothamBold, 28)
	coming.TextXAlignment = Enum.TextXAlignment.Center
end

local function refreshTabs()
	for name, button in pairs(tabButtons) do
		local active = selectedTab == name
		button.BackgroundColor3 = active and Color3.fromRGB(188, 137, 37) or Color3.fromRGB(91, 62, 45)
		button.TextColor3 = active and Color3.fromRGB(255, 247, 181) or Color3.fromRGB(181, 151, 122)
	end
end

local function renderTab()
	if not selectedUnit then return end
	contentTitle.Text = selectedTab
	refreshTabs()
	if selectedTab == "Info" then
		renderInfo(selectedUnit)
	elseif selectedTab == "Skill" then
		renderSkills(selectedUnit)
	elseif selectedTab == "Awaken" then
		renderComingSoon("Awaken")
	elseif selectedTab == "Rune" then
		renderComingSoon("Rune")
	end
end

local function makeTab(name, order)
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(146, 56)
	button.BackgroundColor3 = Color3.fromRGB(91, 62, 45)
	button.BorderSizePixel = 0
	button.Text = name
	button.TextColor3 = COLORS.text
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 21
	button.LayoutOrder = order
	button.Parent = tabs
	addStroke(button, 7, Color3.fromRGB(53, 26, 15), 2, 0.2)
	button.MouseButton1Click:Connect(function()
		selectedTab = name
		renderTab()
	end)
	tabButtons[name] = button
end

makeTab("Info", 1)
makeTab("Skill", 2)
makeTab("Awaken", 3)
makeTab("Rune", 4)

local function selectUnit(unit)
	selectedUnit = unit
	nameLabel.Text = unit.DisplayName or "Unit"
	subLabel.Text = string.format("Lv.%d  %s  %s  %s", unit.Level or 1, unit.Type or "Neutral", unit.Rarity or "Common", string.rep("*", unit.Stars or 1))
	buildPreview(unit)
	updateDisplayButton()
	renderTab()
end

local function populateInventory(units)
	currentUnits = units or {}
	for _, child in ipairs(inventory:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	countLabel.Text = string.format("%d/50", #currentUnits)

	for _, unit in ipairs(currentUnits) do
		local card = Instance.new("Frame")
		card.Size = UDim2.fromOffset(92, 92)
		card.BackgroundColor3 = TYPE_COLORS[unit.Type] or TYPE_COLORS.Neutral
		card.BorderSizePixel = 0
		card.Parent = inventory
		addStroke(card, 7, Color3.fromRGB(247, 210, 108), selectedUnit and selectedUnit.Id == unit.Id and 3 or 1, 0.12)
		label(card, string.rep("*", unit.Stars or 1), UDim2.fromOffset(6, 5), UDim2.new(1, -12, 0, 18), Color3.fromRGB(255, 230, 67), Enum.Font.GothamBlack, 14)
		local initial = label(card, string.sub(unit.DisplayName or "U", 1, 1), UDim2.fromOffset(10, 22), UDim2.new(1, -20, 0, 36), Color3.new(1, 1, 1), Enum.Font.GothamBlack, 30)
		initial.TextXAlignment = Enum.TextXAlignment.Center
		label(card, unit.DisplayName or "Unit", UDim2.fromOffset(6, 62), UDim2.new(1, -38, 0, 24), Color3.fromRGB(255, 239, 207), Enum.Font.GothamBold, 11)
		local lvl = label(card, tostring(unit.Level or 1), UDim2.new(1, -34, 1, -24), UDim2.fromOffset(28, 18), Color3.new(1, 1, 1), Enum.Font.GothamBlack, 14)
		lvl.TextXAlignment = Enum.TextXAlignment.Right

		local click = Instance.new("TextButton")
		click.Size = UDim2.fromScale(1, 1)
		click.BackgroundTransparency = 1
		click.Text = ""
		click.Parent = card
		click.MouseButton1Click:Connect(function()
			selectUnit(unit)
			populateInventory(currentUnits)
		end)
	end

	inventory.CanvasSize = UDim2.fromOffset(invLayout.AbsoluteContentSize.X + 16, 0)
	if not selectedUnit and currentUnits[1] then
		selectUnit(currentUnits[1])
	end
end

local function hideLegacyUnitPanel()
	local hubGui = playerGui:FindFirstChild("SummonHubUI")
	if hubGui then
		local oldOverlay = hubGui:FindFirstChild("UnitOverlay")
		if oldOverlay then
			oldOverlay.Visible = false
		end
	end
end

local function open()
	hideLegacyUnitPanel()

	local ok, units = pcall(function()
		return getUnits:InvokeServer()
	end)
	if ok then
		gui.Enabled = true
		if selectedUnit then
			local fresh = nil
			for _, unit in ipairs(units) do
				if unit.Id == selectedUnit.Id then
					fresh = unit
					break
				end
			end
			selectedUnit = fresh
		end
		populateInventory(units)
	end
end

local function hookUnitsButton()
	local hubGui = playerGui:WaitForChild("SummonHubUI", 20)
	if not hubGui then return end
	local actions = hubGui:WaitForChild("PrimaryActions", 20)
	if not actions then return end
	local unitsButton = actions:WaitForChild("UnitMenuButton", 20)
	if not unitsButton or not unitsButton:IsA("TextButton") then return end
	unitsButton.MouseButton1Click:Connect(function()
		task.defer(open)
	end)
end

closeButton.MouseButton1Click:Connect(function()
	gui.Enabled = false
	hideLegacyUnitPanel()
end)

displayButton.MouseButton1Click:Connect(function()
	if not selectedUnit then return end
	local key = displayKey(selectedUnit)
	if not key then return end

	if displayedUnits[key] then
		if undisplayUnitRemote then
			undisplayUnitRemote:FireServer(selectedUnit.Id)
		end
		displayedUnits[key] = nil
	else
		if displayedCount() >= 3 then
			displayButton.Text = "Max 3"
			task.delay(1, updateDisplayButton)
			return
		end
		if displayUnitRemote then
			displayUnitRemote:FireServer(selectedUnit.Type, selectedUnit.DisplayName, selectedUnit.Id)
		end
		displayedUnits[key] = true
	end

	updateDisplayButton()
end)

viewport.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		lastX = input.Position.X
	end
end)

viewport.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then return end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
	rotation += (input.Position.X - lastX) * 0.012
	lastX = input.Position.X
	updatePreview()
end)

unitsUpdated.OnClientEvent:Connect(function(units)
	if gui.Enabled then
		populateInventory(units)
	end
end)

task.spawn(hookUnitsButton)

local HUB_PLACE_ID = 122635524593151

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local RunService        = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera    = workspace.CurrentCamera

-- Wait for remotes
local remotes       = ReplicatedStorage:WaitForChild("CombatRemotes", 15)
local SendUnitData  = remotes:WaitForChild("SendUnitData",  10)
local BattleState   = remotes:WaitForChild("BattleState",   10)
local PlayerAction  = remotes:WaitForChild("PlayerAction",  10)
local BattleEnd     = remotes:WaitForChild("BattleEnd",     10)
local ModelsSpawned = remotes:WaitForChild("ModelsSpawned", 10)

-- Teleport data — falls back to test units when opened directly in Studio
local tpData = TeleportService:GetLocalPlayerTeleportData()
if not tpData or not tpData.selectedUnits or #tpData.selectedUnits == 0 then
	tpData = {
		areaNum = 1, difficulty = "normal", stage = 1,
		selectedUnits = {
			{
				CharacterName = "Water Fairy", DisplayName = "Water Fairy",
				Type = "Water", HP = 1815, Attack = 107, Defense = 136,
				Speed = 103, CritChance = 0.15, CritDamage = 1.5,
				Resistance = 0.15, Accuracy = 0,
				Abilities = {
					{ Name = "Aqua Hurricane", Type = "Active", Cooldown = 0,
					  Description = "Attacks 3×, 20% Freeze. 120% ATK×3." },
					{ Name = "Purify", Type = "Active", Cooldown = 3,
					  Description = "Remove debuffs from ally and heal." },
				},
			},
			{
				CharacterName = "Fire Hellhound", DisplayName = "Fire Hellhound",
				Type = "Fire", HP = 1725, Attack = 227, Defense = 112,
				Speed = 115, CritChance = 0.15, CritDamage = 1.5,
				Resistance = 0.15, Accuracy = 0,
				Abilities = {
					{ Name = "Bite", Type = "Active", Cooldown = 0,
					  Description = "Bite enemy, heal 30% of damage. 360% ATK." },
					{ Name = "Double Attack", Type = "Active", Cooldown = 3,
					  Description = "Bite 2×. 370% ATK×2." },
				},
			},
		},
	}
end

local SW_AREAS = {
	"Garen Forest","Mt. Siz","Kabir Ruins","Mt. White Ragon",
	"Telain Forest","Hydeni Ruins","Tamor Desert","Vrofagus Ruins",
	"Faimon Volcano","Aiden Forest","Ferun Castle","Mt. Runar","Charuka Remains",
}

if RunService:IsStudio() then
	-- ── Studio level picker ────────────────────────────────────────────
	local sg = Instance.new("ScreenGui")
	sg.Name = "StudioLevelPicker"; sg.ResetOnSpawn = false; sg.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromOffset(320, 220)
	panel.Position = UDim2.new(0.5, -160, 0.5, -110)
	panel.BackgroundColor3 = Color3.fromRGB(17, 19, 28)
	panel.BorderSizePixel = 0; panel.Parent = sg
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 36); title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255); title.Font = Enum.Font.GothamBold
	title.TextScaled = true; title.Text = "Studio Level Picker"; title.Parent = panel

	local function makeRow(labelText, yPos)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromOffset(90, 30); lbl.Position = UDim2.fromOffset(10, yPos)
		lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.fromRGB(160, 170, 200)
		lbl.Font = Enum.Font.GothamMedium; lbl.TextScaled = true
		lbl.Text = labelText; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = panel

		local valLbl = Instance.new("TextLabel")
		valLbl.Size = UDim2.fromOffset(110, 30); valLbl.Position = UDim2.fromOffset(100, yPos)
		valLbl.BackgroundTransparency = 1; valLbl.TextColor3 = Color3.fromRGB(255, 220, 80)
		valLbl.Font = Enum.Font.GothamBold; valLbl.TextScaled = true
		valLbl.Text = ""; valLbl.Parent = panel

		local function makeArrow(text, xPos, onClick)
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.fromOffset(26, 26); btn.Position = UDim2.fromOffset(xPos, yPos + 2)
			btn.BackgroundColor3 = Color3.fromRGB(40, 48, 70); btn.BorderSizePixel = 0
			btn.TextColor3 = Color3.fromRGB(255,255,255); btn.Font = Enum.Font.GothamBold
			btn.TextScaled = true; btn.Text = text; btn.Parent = panel
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
			btn.MouseButton1Click:Connect(onClick)
		end

		return valLbl, makeArrow
	end

	local areaIdx = 1; local diff = "Normal"; local stageIdx = 1
	local areaVal, makeAreaArrow = makeRow("Area:", 44)
	local diffVal                = Instance.new("TextLabel")
	local stageVal, makeStageArrow = makeRow("Stage:", 110)

	-- Difficulty row
	local diffLbl = Instance.new("TextLabel")
	diffLbl.Size = UDim2.fromOffset(90, 30); diffLbl.Position = UDim2.fromOffset(10, 77)
	diffLbl.BackgroundTransparency = 1; diffLbl.TextColor3 = Color3.fromRGB(160,170,200)
	diffLbl.Font = Enum.Font.GothamMedium; diffLbl.TextScaled = true
	diffLbl.Text = "Diff:"; diffLbl.TextXAlignment = Enum.TextXAlignment.Left; diffLbl.Parent = panel
	diffVal.Size = UDim2.fromOffset(90, 26); diffVal.Position = UDim2.fromOffset(100, 79)
	diffVal.BackgroundTransparency = 1; diffVal.TextColor3 = Color3.fromRGB(255,220,80)
	diffVal.Font = Enum.Font.GothamBold; diffVal.TextScaled = true
	diffVal.Text = ""; diffVal.Parent = panel

	local DIFFS = {"Normal","Hard","Hell"}
	local diffIdx = 1
	local function cycleDiff(delta)
		diffIdx = ((diffIdx - 1 + delta) % 3) + 1
		diff = DIFFS[diffIdx]
		diffVal.Text = diff
	end

	local function refresh()
		areaVal.Text  = areaIdx .. ". " .. (SW_AREAS[areaIdx] or "?")
		diffVal.Text  = diff
		stageVal.Text = "Stage " .. stageIdx
	end

	makeAreaArrow("◀", 214, function() areaIdx = math.max(1, areaIdx-1); refresh() end)
	makeAreaArrow("▶", 244, function() areaIdx = math.min(13, areaIdx+1); refresh() end)
	makeStageArrow("◀", 214, function() stageIdx = math.max(1, stageIdx-1); refresh() end)
	makeStageArrow("▶", 244, function() stageIdx = math.min(7, stageIdx+1); refresh() end)

	-- Manual diff arrows
	local dPrev = Instance.new("TextButton")
	dPrev.Size = UDim2.fromOffset(26,26); dPrev.Position = UDim2.fromOffset(214, 79)
	dPrev.BackgroundColor3 = Color3.fromRGB(40,48,70); dPrev.BorderSizePixel = 0
	dPrev.TextColor3 = Color3.fromRGB(255,255,255); dPrev.Font = Enum.Font.GothamBold
	dPrev.TextScaled = true; dPrev.Text = "◀"; dPrev.Parent = panel
	Instance.new("UICorner", dPrev).CornerRadius = UDim.new(0,6)
	dPrev.MouseButton1Click:Connect(function() cycleDiff(-1); refresh() end)
	local dNext = Instance.new("TextButton")
	dNext.Size = UDim2.fromOffset(26,26); dNext.Position = UDim2.fromOffset(244, 79)
	dNext.BackgroundColor3 = Color3.fromRGB(40,48,70); dNext.BorderSizePixel = 0
	dNext.TextColor3 = Color3.fromRGB(255,255,255); dNext.Font = Enum.Font.GothamBold
	dNext.TextScaled = true; dNext.Text = "▶"; dNext.Parent = panel
	Instance.new("UICorner", dNext).CornerRadius = UDim.new(0,6)
	dNext.MouseButton1Click:Connect(function() cycleDiff(1); refresh() end)

	local startBtn = Instance.new("TextButton")
	startBtn.Size = UDim2.fromOffset(280, 46); startBtn.Position = UDim2.fromOffset(20, 156)
	startBtn.BackgroundColor3 = Color3.fromRGB(255,191,64); startBtn.BorderSizePixel = 0
	startBtn.TextColor3 = Color3.fromRGB(20,20,30); startBtn.Font = Enum.Font.GothamBlack
	startBtn.TextScaled = true; startBtn.Text = "Start Battle"; startBtn.Parent = panel
	Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0,12)

	refresh()

	startBtn.MouseButton1Click:Connect(function()
		sg:Destroy()
		local areaInfo = { num = areaIdx, difficulty = diff:lower(), stage = stageIdx }
		SendUnitData:FireServer(tpData.selectedUnits, areaInfo)
	end)
else
	-- Normal game: auto-fire with teleport data
	task.delay(1, function()
		local areaInfo = { num = tpData.areaNum or 1, difficulty = tpData.difficulty or "normal", stage = tpData.stage or 1 }
		SendUnitData:FireServer(tpData.selectedUnits, areaInfo)
	end)
end

local pendingXPRewards = nil

-- ─── CAMERA ───────────────────────────────────────────────────────────
camera.CameraType = Enum.CameraType.Scriptable
local CAMERA_CF   = CFrame.new(Vector3.new(-15, 20, 26), Vector3.new(1, 1, -4))

RunService.RenderStepped:Connect(function()
	camera.CFrame = CAMERA_CF
end)

-- ─── SCREEN GUI ───────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "CombatGui"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

-- ─── BATTLE LOG ───────────────────────────────────────────────────────
local logBg = Instance.new("Frame")
logBg.Size             = UDim2.new(0.38, 0, 0, 100)
logBg.Position         = UDim2.new(0, 8, 1, -108)
logBg.BackgroundColor3 = Color3.fromRGB(8, 10, 18)
logBg.BackgroundTransparency = 0.25
logBg.BorderSizePixel  = 0
logBg.Parent           = screenGui
Instance.new("UICorner", logBg).CornerRadius = UDim.new(0, 8)

local logLabel = Instance.new("TextLabel")
logLabel.Size               = UDim2.new(1, -12, 1, -8)
logLabel.Position           = UDim2.fromOffset(6, 4)
logLabel.BackgroundTransparency = 1
logLabel.TextColor3         = Color3.fromRGB(210, 220, 235)
logLabel.Font               = Enum.Font.Gotham
logLabel.TextSize           = 13
logLabel.TextXAlignment     = Enum.TextXAlignment.Left
logLabel.TextYAlignment     = Enum.TextYAlignment.Bottom
logLabel.TextWrapped        = true
logLabel.Text               = ""
logLabel.Parent             = logBg

-- ─── TURN LABEL ───────────────────────────────────────────────────────
local turnBg = Instance.new("Frame")
turnBg.Size             = UDim2.fromOffset(300, 36)
turnBg.Position         = UDim2.new(0.5, -150, 0, 8)
turnBg.BackgroundColor3 = Color3.fromRGB(14, 16, 26)
turnBg.BackgroundTransparency = 0.2
turnBg.BorderSizePixel  = 0
turnBg.Parent           = screenGui
Instance.new("UICorner", turnBg).CornerRadius = UDim.new(0, 8)

local turnLabel = Instance.new("TextLabel")
turnLabel.Size              = UDim2.fromScale(1, 1)
turnLabel.BackgroundTransparency = 1
turnLabel.TextColor3        = Color3.fromRGB(255, 215, 80)
turnLabel.Font              = Enum.Font.GothamBold
turnLabel.TextScaled        = true
turnLabel.Text              = ""
turnLabel.Parent            = turnBg

-- ─── ABILITY BAR ──────────────────────────────────────────────────────
local abilityBar = Instance.new("Frame")
abilityBar.Size             = UDim2.new(1, 0, 0, 72)
abilityBar.Position         = UDim2.new(0, 0, 1, -72)
abilityBar.BackgroundColor3 = Color3.fromRGB(10, 12, 22)
abilityBar.BackgroundTransparency = 0.15
abilityBar.BorderSizePixel  = 0
abilityBar.Visible          = false
abilityBar.Parent           = screenGui

local abilityLayout = Instance.new("UIListLayout")
abilityLayout.FillDirection       = Enum.FillDirection.Horizontal
abilityLayout.Padding             = UDim.new(0, 10)
abilityLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
abilityLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
abilityLayout.Parent              = abilityBar

local abilityButtons = {}
local selectedEnemyId = { nil }

local function clearAbilityButtons()
	for _, b in ipairs(abilityButtons) do b:Destroy() end
	table.clear(abilityButtons)
end

local function buildAbilityButtons(unit)
	clearAbilityButtons()
	local cds = unit.CooldownsRemaining or {}

	for i, ab in ipairs(unit.Abilities or {}) do
		local cd  = cds[i] or 0
		local btn = Instance.new("TextButton")
		btn.Size             = UDim2.fromOffset(190, 52)
		btn.BackgroundColor3 = cd > 0
			and Color3.fromRGB(42, 44, 58) or Color3.fromRGB(45, 105, 185)
		btn.BorderSizePixel  = 0
		btn.TextColor3       = cd > 0
			and Color3.fromRGB(80, 80, 100) or Color3.fromRGB(255, 255, 255)
		btn.Font             = Enum.Font.GothamBold
		btn.TextScaled       = true
		btn.Text             = cd > 0 and (ab.Name .. "  CD:" .. cd) or ab.Name
		btn.Active           = cd <= 0
		btn.Parent           = abilityBar
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

		if cd <= 0 then
			btn.MouseButton1Click:Connect(function()
				local tid = selectedEnemyId[1]
				if not tid then return end
				PlayerAction:FireServer({ abilityIndex = i, targetId = tid })
				abilityBar.Visible = false
				clearAbilityButtons()
			end)
		end
		table.insert(abilityButtons, btn)
	end

	-- Basic attack
	local basic = Instance.new("TextButton")
	basic.Size             = UDim2.fromOffset(150, 52)
	basic.BackgroundColor3 = Color3.fromRGB(75, 50, 115)
	basic.BorderSizePixel  = 0
	basic.TextColor3       = Color3.fromRGB(255, 255, 255)
	basic.Font             = Enum.Font.GothamBold
	basic.TextScaled       = true
	basic.Text             = "Basic Attack"
	basic.Parent           = abilityBar
	Instance.new("UICorner", basic).CornerRadius = UDim.new(0, 8)

	basic.MouseButton1Click:Connect(function()
		local tid = selectedEnemyId[1]
		if not tid then return end
		PlayerAction:FireServer({ abilityIndex = 0, targetId = tid })
		abilityBar.Visible = false
		clearAbilityButtons()
	end)
	table.insert(abilityButtons, basic)
end

-- ─── TYPE MATCHUP ─────────────────────────────────────────────────────
local TYPE_BEATS = {
	Fire  = { Wind  = true },
	Water = { Fire  = true },
	Wind  = { Water = true },
	Light = { Dark  = true },
	Dark  = { Light = true },
}

local MATCHUP_COLOR = {
	good    = Color3.fromRGB(80,  220,  90),   -- green  – attacker has advantage
	neutral = Color3.fromRGB(255, 200,  40),   -- yellow – no advantage either way
	bad     = Color3.fromRGB(230,  65,  65),   -- red    – defender has advantage
}

local function getMatchupKey(attackerType, defenderType)
	if TYPE_BEATS[attackerType] and TYPE_BEATS[attackerType][defenderType] then
		return "good"
	elseif TYPE_BEATS[defenderType] and TYPE_BEATS[defenderType][attackerType] then
		return "bad"
	end
	return "neutral"
end

-- ─── ARROW BILLBOARDS ─────────────────────────────────────────────────
local arrowBills         = {}   -- enemyId → BillboardGui
local arrowLabels        = {}   -- enemyId → TextLabel (the ▼)
local arrowMatchupColors = {}   -- enemyId → Color3 (set each player turn)
local arrowT             = 0
local arrowsActive       = false

RunService.Heartbeat:Connect(function(dt)
	if not arrowsActive then return end
	arrowT = arrowT + dt
	local offset = math.sin(arrowT * 4) * 0.45
	for _, bill in pairs(arrowBills) do
		bill.StudsOffset = Vector3.new(0, 7.5 + offset, 0)
	end
end)

local function setArrowsVisible(visible)
	arrowsActive = visible
	for _, bill in pairs(arrowBills) do
		bill.Enabled = visible
	end
end

local function updateArrowColors(activeType, enemyUnits)
	table.clear(arrowMatchupColors)
	for _, e in ipairs(enemyUnits) do
		arrowMatchupColors[e.Id] = MATCHUP_COLOR[getMatchupKey(activeType, e.Type)]
	end
	for id, lbl in pairs(arrowLabels) do
		lbl.TextColor3 = arrowMatchupColors[id] or MATCHUP_COLOR.neutral
	end
end

local function highlightArrow(enemyId)
	for id, lbl in pairs(arrowLabels) do
		local base = arrowMatchupColors[id] or MATCHUP_COLOR.neutral
		if id == enemyId then
			lbl.TextColor3             = base
			lbl.TextStrokeTransparency = 0.2
		else
			lbl.TextColor3             = Color3.new(base.R * 0.55, base.G * 0.55, base.B * 0.55)
			lbl.TextStrokeTransparency = 1
		end
	end
end

-- ─── ATTACH TO ENEMY MODELS ───────────────────────────────────────────
ModelsSpawned.OnClientEvent:Connect(function()
	local arenaFolder  = workspace:WaitForChild("CombatArena", 10)
	if not arenaFolder then return end
	local eFolder = arenaFolder:WaitForChild("EnemyUnits", 10)
	if not eFolder then return end

	for _, model in ipairs(eFolder:GetChildren()) do
		local unitId = model:GetAttribute("UnitId")
		if not unitId then continue end

		local body = model:FindFirstChild("Torso")
		if not body then continue end

		-- Arrow billboard
		local bill = Instance.new("BillboardGui")
		bill.Size        = UDim2.fromOffset(32, 42)
		bill.StudsOffset = Vector3.new(0, 7.5, 0)
		bill.AlwaysOnTop = false
		bill.MaxDistance = 100
		bill.Enabled     = false
		bill.Parent      = body

		local arrow = Instance.new("TextLabel")
		arrow.Size               = UDim2.fromScale(1, 1)
		arrow.BackgroundTransparency = 1
		arrow.TextColor3         = Color3.fromRGB(255, 185, 30)
		arrow.Font               = Enum.Font.GothamBlack
		arrow.TextScaled         = true
		arrow.Text               = "▼"
		arrow.TextStrokeTransparency = 1
		arrow.Parent             = bill

		arrowBills[unitId]  = bill
		arrowLabels[unitId] = arrow

		-- ClickDetector → select this enemy as target
		local cd = body:FindFirstChildOfClass("ClickDetector")
		if cd then
			cd.MouseClick:Connect(function()
				selectedEnemyId[1] = unitId
				highlightArrow(unitId)
			end)
		end
	end
end)

-- ─── BATTLE STATE ─────────────────────────────────────────────────────
BattleState.OnClientEvent:Connect(function(state)
	logLabel.Text = table.concat(state.log, "\n")

	if state.phase == "player_action" then
		local activeUnit
		for _, u in ipairs(state.playerUnits) do
			if u.Id == state.activeTurnId then activeUnit = u; break end
		end
		if activeUnit then
			turnLabel.Text = "Your turn: " .. activeUnit.Name
			clearAbilityButtons()
			buildAbilityButtons(activeUnit)
			setArrowsVisible(true)
			abilityBar.Visible = true

			updateArrowColors(activeUnit.Type, state.enemyUnits)

			-- Auto-select the first alive enemy so buttons fire immediately
			selectedEnemyId[1] = nil
			for _, e in ipairs(state.enemyUnits) do
				if e.HP > 0 then
					selectedEnemyId[1] = e.Id
					highlightArrow(e.Id)
					break
				end
			end
		end
	elseif state.phase == "enemy_action" then
		turnLabel.Text = "Enemy is acting..."
		setArrowsVisible(false)
		abilityBar.Visible = false
		clearAbilityButtons()
	elseif state.phase == "victory" or state.phase == "defeat" then
		setArrowsVisible(false)
		abilityBar.Visible = false
		clearAbilityButtons()
	else
		setArrowsVisible(false)
		abilityBar.Visible = false
	end
end)

-- ─── BATTLE END ───────────────────────────────────────────────────────
local endOverlay = Instance.new("Frame")
endOverlay.Size             = UDim2.fromScale(1, 1)
endOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
endOverlay.BackgroundTransparency = 0.45
endOverlay.Visible          = false
endOverlay.ZIndex           = 50
endOverlay.Parent           = screenGui

local endPanel = Instance.new("Frame")
endPanel.Size             = UDim2.fromOffset(420, 200)
endPanel.Position         = UDim2.new(0.5, -210, 0.5, -100)
endPanel.BackgroundColor3 = Color3.fromRGB(16, 18, 30)
endPanel.BorderSizePixel  = 0
endPanel.ZIndex           = 51
endPanel.Parent           = endOverlay
Instance.new("UICorner", endPanel).CornerRadius = UDim.new(0, 14)

local endTitle = Instance.new("TextLabel")
endTitle.Size               = UDim2.new(1, -20, 0, 80)
endTitle.Position           = UDim2.fromOffset(10, 16)
endTitle.BackgroundTransparency = 1
endTitle.TextColor3         = Color3.fromRGB(255, 255, 255)
endTitle.Font               = Enum.Font.GothamBlack
endTitle.TextScaled         = true
endTitle.ZIndex             = 51
endTitle.Parent             = endPanel

local returnBtn = Instance.new("TextButton")
returnBtn.Size             = UDim2.fromOffset(220, 52)
returnBtn.Position         = UDim2.new(0.5, -110, 1, -68)
returnBtn.BackgroundColor3 = Color3.fromRGB(255, 191, 64)
returnBtn.BorderSizePixel  = 0
returnBtn.TextColor3       = Color3.fromRGB(18, 18, 28)
returnBtn.Font             = Enum.Font.GothamBlack
returnBtn.TextScaled       = true
returnBtn.Text             = "Return to Hub"
returnBtn.ZIndex           = 51
returnBtn.Parent           = endPanel
Instance.new("UICorner", returnBtn).CornerRadius = UDim.new(0, 10)

returnBtn.MouseButton1Click:Connect(function()
	returnBtn.Active = false
	returnBtn.Text   = "Returning..."
	if HUB_PLACE_ID ~= 0 then
		local opts = Instance.new("TeleportOptions")
		opts:SetTeleportData({ xpRewards = pendingXPRewards })
		TeleportService:Teleport(HUB_PLACE_ID, player, opts)
	end
end)

BattleEnd.OnClientEvent:Connect(function(result)
	setArrowsVisible(false)
	abilityBar.Visible = false
	endOverlay.Visible = true
	if result.victory then
		endTitle.TextColor3 = Color3.fromRGB(255, 215, 80)
		if result.xp and result.unitIds and #result.unitIds > 0 then
			local xpEach = math.floor(result.xp / #result.unitIds)
			pendingXPRewards = {}
			for _, uid in ipairs(result.unitIds) do
				pendingXPRewards[tostring(uid)] = xpEach
			end
			endTitle.Text = "Victory!\n+" .. result.xp .. " XP"
		else
			endTitle.Text = "Victory!"
		end
	else
		pendingXPRewards   = nil
		endTitle.Text       = "Defeated"
		endTitle.TextColor3 = Color3.fromRGB(220, 80, 80)
	end
end)

print("[CombatClient] Ready")

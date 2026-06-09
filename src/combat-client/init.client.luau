local HUB_PLACE_ID = 122635524593151

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local RunService        = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera    = workspace.CurrentCamera

-- ─── REMOTES ──────────────────────────────────────────────────────────
local remotes        = ReplicatedStorage:WaitForChild("CombatRemotes", 15)
local SendUnitData   = remotes:WaitForChild("SendUnitData",   10)
local BattleState    = remotes:WaitForChild("BattleState",    10)
local PlayerAction   = remotes:WaitForChild("PlayerAction",   10)
local BattleEnd      = remotes:WaitForChild("BattleEnd",      10)
local ModelsSpawned  = remotes:WaitForChild("ModelsSpawned",  10)
local SetAutoMode    = remotes:WaitForChild("SetAutoMode",    10)
local SetBattleSpeed = remotes:WaitForChild("SetBattleSpeed", 10)

-- ─── TELEPORT DATA ────────────────────────────────────────────────────
local tpData = TeleportService:GetLocalPlayerTeleportData()
local hasTeleportBattleData = type(tpData) == "table"
	and type(tpData.selectedUnits) == "table"
	and #tpData.selectedUnits > 0
if not hasTeleportBattleData then
	tpData = {
		areaNum = 1, difficulty = "normal", stage = 1,
		selectedUnits = {
			{
				Id = 1,
				CharacterName = "Water Fairy", DisplayName = "Water Fairy",
				Type = "Water", HP = 1815, Attack = 107, Defense = 136,
				Speed = 103, CritChance = 0.15, CritDamage = 1.5,
				Resistance = 0.15, Accuracy = 0,
				Abilities = {
					{ Name = "Aqua Hurricane", Type = "Active", Cooldown = 0, TargetType = "EnemySingle",
					  Multiplier = 1.2, Hits = 3, AoE = false, Heals = false, SelfHeal = false, LifeSteal = false },
					{ Name = "Purify", Type = "Active", Cooldown = 3, TargetType = "AllySingle",
					  Multiplier = 4, ScalesWith = "ATK", Hits = 1, AoE = false, Heals = true, SelfHeal = false, LifeSteal = false },
				},
			},
			{
				Id = 2,
				CharacterName = "Fire Hellhound", DisplayName = "Fire Hellhound",
				Type = "Fire", HP = 1725, Attack = 227, Defense = 112,
				Speed = 115, CritChance = 0.15, CritDamage = 1.5,
				Resistance = 0.15, Accuracy = 0,
				Abilities = {
					{ Name = "Bite", Type = "Active", Cooldown = 0, TargetType = "EnemySingle",
					  Multiplier = 3.6, Hits = 1, AoE = false, Heals = false, SelfHeal = false, LifeSteal = true },
					{ Name = "Double Attack", Type = "Active", Cooldown = 3, TargetType = "EnemySingle",
					  Multiplier = 3.7, Hits = 2, AoE = false, Heals = false, SelfHeal = false, LifeSteal = false },
				},
			},
		},
	}
end

local lastAreaInfo = nil  -- saved each time a battle starts, used by Replay in Studio
local setSetupSummary

local SW_AREAS = {
	"Garen Forest","Mt. Siz","Kabir Ruins","Mt. White Ragon",
	"Telain Forest","Hydeni Ruins","Tamor Desert","Vrofagus Ruins",
	"Faimon Volcano","Aiden Forest","Ferun Castle","Mt. Runar","Charuka Remains",
}

local function showStudioLevelPicker()
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

	local diffLbl = Instance.new("TextLabel")
	diffLbl.Size = UDim2.fromOffset(90, 30); diffLbl.Position = UDim2.fromOffset(10, 77)
	diffLbl.BackgroundTransparency = 1; diffLbl.TextColor3 = Color3.fromRGB(160,170,200)
	diffLbl.Font = Enum.Font.GothamMedium; diffLbl.TextScaled = true
	diffLbl.Text = "Diff:"; diffLbl.TextXAlignment = Enum.TextXAlignment.Left; diffLbl.Parent = panel
	diffVal.Size = UDim2.fromOffset(90, 26); diffVal.Position = UDim2.fromOffset(100, 79)
	diffVal.BackgroundTransparency = 1; diffVal.TextColor3 = Color3.fromRGB(255,220,80)
	diffVal.Font = Enum.Font.GothamBold; diffVal.TextScaled = true
	diffVal.Text = ""; diffVal.Parent = panel

	local DIFFS = {"Normal","Hard","Hell"}; local diffIdx = 1
	local function cycleDiff(delta)
		diffIdx = ((diffIdx - 1 + delta) % 3) + 1
		diff = DIFFS[diffIdx]; diffVal.Text = diff
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
		lastAreaInfo = { num = areaIdx, difficulty = diff:lower(), stage = stageIdx }
		if setSetupSummary then
			setSetupSummary("Studio fallback test setup", lastAreaInfo)
		end
		SendUnitData:FireServer(tpData.selectedUnits, lastAreaInfo)
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

local setupPanel = Instance.new("Frame")
setupPanel.Name = "LoadedSetupPanel"
setupPanel.Size = UDim2.fromOffset(360, 104)
setupPanel.Position = UDim2.fromOffset(8, 48)
setupPanel.BackgroundColor3 = hasTeleportBattleData and Color3.fromRGB(12, 30, 22) or Color3.fromRGB(42, 27, 16)
setupPanel.BackgroundTransparency = 0.08
setupPanel.BorderSizePixel = 0
setupPanel.Parent = screenGui
Instance.new("UICorner", setupPanel).CornerRadius = UDim.new(0, 8)

local setupLabel = Instance.new("TextLabel")
setupLabel.Size = UDim2.new(1, -16, 1, -12)
setupLabel.Position = UDim2.fromOffset(8, 6)
setupLabel.BackgroundTransparency = 1
setupLabel.TextColor3 = Color3.fromRGB(235, 245, 235)
setupLabel.Font = Enum.Font.GothamMedium
setupLabel.TextSize = 13
setupLabel.TextXAlignment = Enum.TextXAlignment.Left
setupLabel.TextYAlignment = Enum.TextYAlignment.Top
setupLabel.TextWrapped = true
setupLabel.Parent = setupPanel

local function formatLoadedUnits(units)
	local names = {}
	for i, unit in ipairs(units or {}) do
		names[i] = unit.DisplayName or unit.CharacterName or unit.Name or ("Unit " .. i)
	end
	return table.concat(names, ", ")
end

setSetupSummary = function(sourceLabel, areaInfo)
	local areaName = SW_AREAS[areaInfo.num or 1] or ("Area " .. tostring(areaInfo.num or 1))
	setupLabel.Text = string.format(
		"%s\n%s | %s | Stage %s\nUnits: %s",
		sourceLabel,
		areaName,
		tostring(areaInfo.difficulty or "normal"),
		tostring(areaInfo.stage or 1),
		formatLoadedUnits(tpData.selectedUnits)
	)
end

local function beginCombatFromTeleportData()
	lastAreaInfo = {
		num = tpData.areaNum or 1,
		difficulty = tpData.difficulty or "normal",
		stage = tpData.stage or 1,
	}
	setSetupSummary(hasTeleportBattleData and "Loaded from hub teleport data" or "Studio fallback test setup", lastAreaInfo)
	SendUnitData:FireServer(tpData.selectedUnits, lastAreaInfo)
end

if RunService:IsStudio() and not hasTeleportBattleData then
	setSetupSummary("Studio fallback test setup", { num = 1, difficulty = "normal", stage = 1 })
	showStudioLevelPicker()
else
	task.delay(1, beginCombatFromTeleportData)
end

-- ─── BATTLE LOG ───────────────────────────────────────────────────────
local logBg = Instance.new("Frame")
logBg.Size             = UDim2.new(0.38, 0, 0, 100)
logBg.Position         = UDim2.new(0, 8, 1, -108)
logBg.BackgroundColor3 = Color3.fromRGB(8, 10, 18)
logBg.BackgroundTransparency = 0.25
logBg.BorderSizePixel  = 0; logBg.Parent = screenGui
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
logLabel.Text               = ""; logLabel.Parent = logBg

-- ─── TURN LABEL ───────────────────────────────────────────────────────
local turnBg = Instance.new("Frame")
turnBg.Size             = UDim2.fromOffset(300, 36)
turnBg.Position         = UDim2.new(0.5, -150, 0, 8)
turnBg.BackgroundColor3 = Color3.fromRGB(14, 16, 26)
turnBg.BackgroundTransparency = 0.2
turnBg.BorderSizePixel  = 0; turnBg.Parent = screenGui
Instance.new("UICorner", turnBg).CornerRadius = UDim.new(0, 8)

local turnLabel = Instance.new("TextLabel")
turnLabel.Size              = UDim2.fromScale(1, 1)
turnLabel.BackgroundTransparency = 1
turnLabel.TextColor3        = Color3.fromRGB(255, 215, 80)
turnLabel.Font              = Enum.Font.GothamBold
turnLabel.TextScaled        = true
turnLabel.Text              = ""; turnLabel.Parent = turnBg

-- ─── TYPE MATCHUP ─────────────────────────────────────────────────────
local TYPE_BEATS = {
	Fire  = { Wind  = true },
	Water = { Fire  = true },
	Wind  = { Water = true },
	Light = { Dark  = true },
	Dark  = { Light = true },
}
local MATCHUP_COLOR = {
	good    = Color3.fromRGB(80,  220,  90),
	neutral = Color3.fromRGB(255, 200,  40),
	bad     = Color3.fromRGB(230,  65,  65),
}
local function getMatchupKey(a, d)
	if TYPE_BEATS[a] and TYPE_BEATS[a][d] then return "good" end
	if TYPE_BEATS[d] and TYPE_BEATS[d][a] then return "bad"  end
	return "neutral"
end

-- ─── TARGETING STATE ──────────────────────────────────────────────────
local pendingAbilityIdx = nil   -- selected skill slot (nil = nothing selected)
local pendingTargetType = nil   -- "EnemySingle"|"EnemyAll"|"AllySingle"|"AllyAll"|"Self"
local cachedPlayerUnits = {}    -- latest player unit list from BattleState
local cachedEnemyUnits  = {}    -- latest enemy unit list from BattleState
local cachedActingUnit  = nil   -- unit currently taking its turn
local autoEnabled       = false -- mirrors server autoMode
local currentSpeed      = 1     -- 1 / 2 / 3
local cancelBtn         = nil   -- forward ref; assigned in buildAbilityButtons

-- ─── ARROW BILLBOARD SYSTEM ───────────────────────────────────────────
local arrowBills         = {}   -- enemyId → BillboardGui  (red/yellow arrows)
local arrowLabels        = {}   -- enemyId → TextLabel
local arrowMatchupColors = {}
local arrowT             = 0
local arrowsActive       = false

local allyArrowBills     = {}   -- unitId → BillboardGui   (green arrows)
local allyArrowLabels    = {}   -- unitId → TextLabel
local allyArrowT         = 0
local allyArrowsActive   = false

RunService.Heartbeat:Connect(function(dt)
	arrowT = arrowT + dt; allyArrowT = allyArrowT + dt
	if arrowsActive then
		local off = math.sin(arrowT * 4) * 0.45
		for _, b in pairs(arrowBills) do b.StudsOffset = Vector3.new(0, 7.5 + off, 0) end
	end
	if allyArrowsActive then
		local off = math.sin(allyArrowT * 4) * 0.45
		for _, b in pairs(allyArrowBills) do b.StudsOffset = Vector3.new(0, 7.5 + off, 0) end
	end
end)

local function setEnemyArrowsVisible(v)
	arrowsActive = v
	if v then
		local alive = {}
		for _, e in ipairs(cachedEnemyUnits) do
			if e.HP > 0 then
				alive[e.Id] = true
			end
		end
		for id, b in pairs(arrowBills) do
			b.Enabled = alive[id] == true
		end
	else
		for _, b in pairs(arrowBills) do
			b.Enabled = false
		end
	end
end
local function setAllyArrowsVisible(v)
	allyArrowsActive = v
	for _, b in pairs(allyArrowBills) do
		b.Enabled = v
	end
end
local function setArrowsVisible(v)
	setEnemyArrowsVisible(v)
	setAllyArrowsVisible(v)
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

local function highlightEnemyArrow(enemyId)
	for id, lbl in pairs(arrowLabels) do
		local base = arrowMatchupColors[id] or MATCHUP_COLOR.neutral
		if id == enemyId then
			lbl.TextColor3 = base
			lbl.TextStrokeTransparency = 0.2
		else
			lbl.TextColor3 = Color3.new(base.R * 0.5, base.G * 0.5, base.B * 0.5)
			lbl.TextStrokeTransparency = 1
		end
	end
end

local function highlightAllyArrow(allyId)
	for id, lbl in pairs(allyArrowLabels) do
		if id == allyId then
			lbl.TextColor3 = Color3.fromRGB(80, 240, 100)
			lbl.TextStrokeTransparency = 0.2
		else
			lbl.TextColor3 = Color3.fromRGB(25, 90, 35)
			lbl.TextStrokeTransparency = 1
		end
	end
end

-- ─── ABILITY BAR ──────────────────────────────────────────────────────
local abilityBar = Instance.new("Frame")
abilityBar.Size             = UDim2.new(1, 0, 0, 76)
abilityBar.Position         = UDim2.new(0, 0, 1, -76)
abilityBar.BackgroundColor3 = Color3.fromRGB(10, 12, 22)
abilityBar.BackgroundTransparency = 0.15
abilityBar.BorderSizePixel  = 0
abilityBar.Visible          = false
abilityBar.Parent           = screenGui

local abilityLayout = Instance.new("UIListLayout")
abilityLayout.FillDirection       = Enum.FillDirection.Horizontal
abilityLayout.Padding             = UDim.new(0, 8)
abilityLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
abilityLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
abilityLayout.Parent              = abilityBar

local abilityButtons = {}

local function clearAbilityButtons()
	for _, b in ipairs(abilityButtons) do b:Destroy() end
	table.clear(abilityButtons)
	cancelBtn = nil
end

-- ─── SELECTION HELPERS ────────────────────────────────────────────────
local function cancelSelection()
	pendingAbilityIdx = nil; pendingTargetType = nil
	setEnemyArrowsVisible(false); setAllyArrowsVisible(false)
	if cancelBtn and cancelBtn.Parent then cancelBtn.Visible = false end
end

local function firePlayerAction(abilityIdx, targetId)
	print("[CombatClient] firePlayerAction: abilityIdx=", abilityIdx, "targetId=", targetId, "pendingAbilityIdx was=", pendingAbilityIdx)
	PlayerAction:FireServer({ abilityIndex = abilityIdx, targetId = targetId })
	abilityBar.Visible = false
	clearAbilityButtons()
	cancelSelection()
end

local TARGET_LABELS = {
	EnemySingle = "→ Enemy",
	EnemyAll    = "→ All Enemies",
	AllySingle  = "→ Ally",
	AllyAll     = "→ All Allies",
	Self        = "→ Self",
	Passive     = "(Passive)",
}
local BTN_COLORS = {
	EnemySingle = Color3.fromRGB(45, 105, 185),
	EnemyAll    = Color3.fromRGB(160, 50, 45),
	AllySingle  = Color3.fromRGB(35, 125, 60),
	AllyAll     = Color3.fromRGB(25, 100, 50),
	Self        = Color3.fromRGB(100, 55, 165),
}

local function enterSelectingMode(abilityIdx, targetType)
	-- Reset any previous selection so switching abilities always works
	cancelSelection()
	pendingAbilityIdx = abilityIdx
	pendingTargetType = targetType

	-- AoE / no-pick skills: resolve target automatically and fire
	if targetType == "EnemyAll" then
		for _, e in ipairs(cachedEnemyUnits) do
			if e.HP > 0 then firePlayerAction(abilityIdx, e.Id); return end
		end; return
	end
	if targetType == "AllyAll" then
		for _, u in ipairs(cachedPlayerUnits) do
			if u.HP > 0 then firePlayerAction(abilityIdx, u.Id); return end
		end; return
	end
	if targetType == "Self" then
		if cachedActingUnit then firePlayerAction(abilityIdx, cachedActingUnit.Id) end
		return
	end

	-- Single-target: show arrows and wait for click
	if targetType == "EnemySingle" then
		setAllyArrowsVisible(false); setEnemyArrowsVisible(true)
		for _, e in ipairs(cachedEnemyUnits) do
			if e.HP > 0 then highlightEnemyArrow(e.Id); break end
		end
	elseif targetType == "AllySingle" then
		setEnemyArrowsVisible(false); setAllyArrowsVisible(true)
		local lf, lid = 2, nil
		for _, u in ipairs(cachedPlayerUnits) do
			if u.HP > 0 then
				local f = u.HP / u.MaxHP
				if f < lf then lf = f; lid = u.Id end
			end
		end
		if lid then highlightAllyArrow(lid) end
	end
	if cancelBtn and cancelBtn.Parent then cancelBtn.Visible = true end
end

local function buildAbilityButtons(unit)
	clearAbilityButtons()
	local cds = unit.CooldownsRemaining or {}

	-- DEBUG: log what CD data the client actually sees
	local cdParts = {}
	for k, v in pairs(cds) do
		table.insert(cdParts, tostring(k) .. "(" .. type(k) .. ")=" .. tostring(v))
	end
	print("[CombatClient] buildAbilityButtons:", unit.Name, "CDs: {", table.concat(cdParts, ", "), "}")

	for i, ab in ipairs(unit.Abilities or {}) do
		if ab.Type == "Passive" then continue end
		local cd   = cds[i] or cds[tostring(i)] or 0
		local tt   = ab.TargetType or "EnemySingle"
		local onCD = cd > 0

		local btn = Instance.new("TextButton")
		btn.Size             = UDim2.fromOffset(180, 58)
		btn.BackgroundColor3 = onCD and Color3.fromRGB(35, 38, 50)
		                            or (BTN_COLORS[tt] or Color3.fromRGB(45, 105, 185))
		btn.BorderSizePixel  = 0
		btn.TextColor3       = onCD and Color3.fromRGB(70, 70, 90)
		                            or Color3.fromRGB(255, 255, 255)
		btn.Font             = Enum.Font.GothamBold
		btn.TextScaled       = false; btn.TextSize = 13
		btn.Text             = (onCD and (ab.Name .. "  CD:" .. cd) or ab.Name)
		                       .. "\n" .. (TARGET_LABELS[tt] or tt)
		btn.Active           = not onCD; btn.Parent = abilityBar
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

		if not onCD then
			local ci, ct = i, tt
			btn.MouseButton1Click:Connect(function()
				print("[CombatClient] ability btn clicked: i=", ci)
				enterSelectingMode(ci, ct)
			end)
		end
		table.insert(abilityButtons, btn)
	end


	-- Cancel button (hidden until a skill is pending)
	cancelBtn = Instance.new("TextButton")
	cancelBtn.Size             = UDim2.fromOffset(90, 58)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(110, 30, 30)
	cancelBtn.BorderSizePixel  = 0
	cancelBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
	cancelBtn.Font             = Enum.Font.GothamBold
	cancelBtn.TextScaled       = true
	cancelBtn.Text             = "Cancel"
	cancelBtn.Visible          = false; cancelBtn.Parent = abilityBar
	Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 8)
	cancelBtn.MouseButton1Click:Connect(cancelSelection)
	table.insert(abilityButtons, cancelBtn)
end

-- ─── SPEED + AUTO PANEL (top-right) ───────────────────────────────────
local ctrlPanel = Instance.new("Frame")
ctrlPanel.Size             = UDim2.fromOffset(254, 36)
ctrlPanel.Position         = UDim2.new(1, -262, 0, 8)
ctrlPanel.BackgroundColor3 = Color3.fromRGB(14, 16, 26)
ctrlPanel.BackgroundTransparency = 0.2
ctrlPanel.BorderSizePixel  = 0; ctrlPanel.Parent = screenGui
Instance.new("UICorner", ctrlPanel).CornerRadius = UDim.new(0, 8)
local ctrlLayout = Instance.new("UIListLayout")
ctrlLayout.FillDirection       = Enum.FillDirection.Horizontal
ctrlLayout.Padding             = UDim.new(0, 4)
ctrlLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
ctrlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ctrlLayout.Parent = ctrlPanel

local function makeCtrlBtn(text, w, col)
	local b = Instance.new("TextButton")
	b.Size             = UDim2.fromOffset(w, 28)
	b.BackgroundColor3 = col
	b.BorderSizePixel  = 0
	b.TextColor3       = Color3.fromRGB(255, 255, 255)
	b.Font             = Enum.Font.GothamBold
	b.TextScaled       = true; b.Text = text; b.Parent = ctrlPanel
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	return b
end

local speedBtns  = {}
local SPEEDS     = { 1, 2, 3 }
local function refreshSpeedBtns()
	for i, btn in ipairs(speedBtns) do
		btn.BackgroundColor3 = SPEEDS[i] == currentSpeed
			and Color3.fromRGB(80, 160, 255)
			or  Color3.fromRGB(35, 40, 60)
	end
end
for _, sp in ipairs(SPEEDS) do
	local btn = makeCtrlBtn(sp .. "x", 50, Color3.fromRGB(35, 40, 60))
	local cs  = sp
	btn.MouseButton1Click:Connect(function()
		currentSpeed = cs; refreshSpeedBtns()
		SetBattleSpeed:FireServer(cs)
	end)
	table.insert(speedBtns, btn)
end
refreshSpeedBtns()

local autoBtn
local function refreshAutoBtn()
	if not autoBtn then return end
	autoBtn.BackgroundColor3 = autoEnabled
		and Color3.fromRGB(45, 190, 85)
		or  Color3.fromRGB(35, 40, 60)
	autoBtn.Text = autoEnabled and "AUTO ON" or "AUTO"
end
autoBtn = makeCtrlBtn("AUTO", 76, Color3.fromRGB(35, 40, 60))
autoBtn.MouseButton1Click:Connect(function()
	autoEnabled = not autoEnabled
	refreshAutoBtn()
	SetAutoMode:FireServer(autoEnabled)
	if autoEnabled then
		-- Close ability bar immediately if auto is now on
		abilityBar.Visible = false
		clearAbilityButtons(); cancelSelection()
	end
end)
refreshAutoBtn()

-- ─── MODELS SPAWNED ───────────────────────────────────────────────────
ModelsSpawned.OnClientEvent:Connect(function()
	local arenaFolder = workspace:WaitForChild("CombatArena", 10)
	if not arenaFolder then return end

	table.clear(arrowBills); table.clear(arrowLabels); table.clear(arrowMatchupColors)
	table.clear(allyArrowBills); table.clear(allyArrowLabels)

	-- ── Enemy arrows (red/yellow per matchup) ──
	local eFolder = arenaFolder:WaitForChild("EnemyUnits", 10)
	if eFolder then
		for _, model in ipairs(eFolder:GetChildren()) do
			local uid = model:GetAttribute("UnitId")
			if not uid then continue end
			local body = model:FindFirstChild("Torso")
			if not body then continue end

			local bill = Instance.new("BillboardGui")
			bill.Size = UDim2.fromOffset(32, 42); bill.StudsOffset = Vector3.new(0, 7.5, 0)
			bill.AlwaysOnTop = false; bill.MaxDistance = 100
			bill.Enabled = false; bill.Parent = body

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.fromScale(1,1); lbl.BackgroundTransparency = 1
			lbl.TextColor3 = Color3.fromRGB(255, 185, 30); lbl.Font = Enum.Font.GothamBlack
			lbl.TextScaled = true; lbl.Text = "▼"
			lbl.TextStrokeTransparency = 1; lbl.Parent = bill

			arrowBills[uid] = bill; arrowLabels[uid] = lbl

			local cd = body:FindFirstChildOfClass("ClickDetector")
			if cd then
				cd.MouseClick:Connect(function()
					if pendingAbilityIdx ~= nil and pendingTargetType == "EnemySingle" then
						highlightEnemyArrow(uid)
						firePlayerAction(pendingAbilityIdx, uid)
					end
				end)
			end
		end
	end

	-- ── Ally arrows (green) ──
	local pFolder = arenaFolder:WaitForChild("PlayerUnits", 10)
	if pFolder then
		for _, model in ipairs(pFolder:GetChildren()) do
			local uid = model:GetAttribute("UnitId")
			if not uid then continue end
			local body = model:FindFirstChild("Torso")
			if not body then continue end

			local bill = Instance.new("BillboardGui")
			bill.Size = UDim2.fromOffset(32, 42); bill.StudsOffset = Vector3.new(0, 7.5, 0)
			bill.AlwaysOnTop = false; bill.MaxDistance = 100
			bill.Enabled = false; bill.Parent = body

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.fromScale(1,1); lbl.BackgroundTransparency = 1
			lbl.TextColor3 = Color3.fromRGB(80, 240, 100); lbl.Font = Enum.Font.GothamBlack
			lbl.TextScaled = true; lbl.Text = "▼"
			lbl.TextStrokeTransparency = 1; lbl.Parent = bill

			allyArrowBills[uid] = bill; allyArrowLabels[uid] = lbl

			local cd = body:FindFirstChildOfClass("ClickDetector")
			if cd then
				cd.MouseClick:Connect(function()
					if pendingAbilityIdx ~= nil and pendingTargetType == "AllySingle" then
						highlightAllyArrow(uid)
						firePlayerAction(pendingAbilityIdx, uid)
					end
				end)
			end
		end
	end
end)

-- ─── BATTLE STATE ─────────────────────────────────────────────────────
BattleState.OnClientEvent:Connect(function(state)
	logLabel.Text = table.concat(state.log, "\n")

	cachedPlayerUnits = state.playerUnits or {}
	cachedEnemyUnits  = state.enemyUnits  or {}

	if state.autoMode ~= nil then
		autoEnabled = state.autoMode; refreshAutoBtn()
	end

	local phase = state.phase

	if phase == "player_action" then
		local activeUnit
		for _, u in ipairs(cachedPlayerUnits) do
			if u.Id == state.activeTurnId then activeUnit = u; break end
		end
		if activeUnit then
			cachedActingUnit = activeUnit
			turnLabel.Text   = "Your turn: " .. activeUnit.Name
			cancelSelection(); clearAbilityButtons()
			buildAbilityButtons(activeUnit)
			setEnemyArrowsVisible(true)
			setAllyArrowsVisible(false)
			abilityBar.Visible = true
			print("[CombatClient] abilityBar shown for", activeUnit.Name)
			updateArrowColors(activeUnit.Type, cachedEnemyUnits)
			for _, e in ipairs(cachedEnemyUnits) do
				if e.HP > 0 then highlightEnemyArrow(e.Id); break end
			end
		end
	elseif phase == "auto_action" then
		local actName = ""
		for _, u in ipairs(cachedPlayerUnits) do
			if u.Id == state.activeTurnId then actName = u.Name; break end
		end
		turnLabel.Text = "Auto: " .. actName
		setArrowsVisible(false); abilityBar.Visible = false
		clearAbilityButtons(); cancelSelection()
	elseif phase == "enemy_action" then
		turnLabel.Text = "Enemy is acting..."
		setArrowsVisible(false); abilityBar.Visible = false
		clearAbilityButtons(); cancelSelection()
	elseif phase == "victory" or phase == "defeat" then
		setArrowsVisible(false); abilityBar.Visible = false
		clearAbilityButtons(); cancelSelection()
	else
		setArrowsVisible(false); abilityBar.Visible = false
	end
end)

-- ─── BATTLE END ───────────────────────────────────────────────────────
local endOverlay = Instance.new("Frame")
endOverlay.Size             = UDim2.fromScale(1, 1)
endOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
endOverlay.BackgroundTransparency = 0.45
endOverlay.Visible          = false; endOverlay.ZIndex = 50
endOverlay.Parent           = screenGui

local endPanel = Instance.new("Frame")
endPanel.Size             = UDim2.fromOffset(420, 220)
endPanel.Position         = UDim2.new(0.5, -210, 0.5, -110)
endPanel.BackgroundColor3 = Color3.fromRGB(16, 18, 30)
endPanel.BorderSizePixel  = 0; endPanel.ZIndex = 51
endPanel.Parent           = endOverlay
Instance.new("UICorner", endPanel).CornerRadius = UDim.new(0, 14)

local endTitle = Instance.new("TextLabel")
endTitle.Size               = UDim2.new(1, -20, 0, 80)
endTitle.Position           = UDim2.fromOffset(10, 16)
endTitle.BackgroundTransparency = 1
endTitle.TextColor3         = Color3.fromRGB(255, 255, 255)
endTitle.Font               = Enum.Font.GothamBlack
endTitle.TextScaled         = true; endTitle.ZIndex = 51
endTitle.Parent             = endPanel

local replayBtn = Instance.new("TextButton")
replayBtn.Size             = UDim2.fromOffset(195, 52)
replayBtn.Position         = UDim2.new(0, 10, 1, -68)
replayBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
replayBtn.BorderSizePixel  = 0
replayBtn.TextColor3       = Color3.fromRGB(18, 18, 28)
replayBtn.Font             = Enum.Font.GothamBlack
replayBtn.TextScaled       = true
replayBtn.Text             = "Replay"
replayBtn.ZIndex           = 51
replayBtn.Parent           = endPanel
Instance.new("UICorner", replayBtn).CornerRadius = UDim.new(0, 10)
replayBtn.MouseButton1Click:Connect(function()
	replayBtn.Active = false
	replayBtn.Text   = "Loading..."
	if RunService:IsStudio() then
		endOverlay.Visible = false
		setArrowsVisible(false)
		abilityBar.Visible = false
		clearAbilityButtons()
		cancelSelection()
		if lastAreaInfo then
			SendUnitData:FireServer(tpData.selectedUnits, lastAreaInfo)
		end
		replayBtn.Active = true
		replayBtn.Text   = "Replay"
		return
	end
	if HUB_PLACE_ID ~= 0 then
		local unitIds = {}
		for _, u in ipairs(tpData.selectedUnits or {}) do
			if u.Id then
				table.insert(unitIds, u.Id)
			end
		end
		local opts = Instance.new("TeleportOptions")
		opts:SetTeleportData({
			xpRewards  = pendingXPRewards,
			replayData = {
				unitIds    = unitIds,
				areaNum    = tpData.areaNum,
				difficulty = tpData.difficulty,
				stage      = tpData.stage,
			},
		})
		TeleportService:Teleport(HUB_PLACE_ID, player, opts)
	end
end)

local levelSelectBtn = Instance.new("TextButton")
levelSelectBtn.Size             = UDim2.fromOffset(195, 52)
levelSelectBtn.Position         = UDim2.new(0, 215, 1, -68)
levelSelectBtn.BackgroundColor3 = Color3.fromRGB(255, 191, 64)
levelSelectBtn.BorderSizePixel  = 0
levelSelectBtn.TextColor3       = Color3.fromRGB(18, 18, 28)
levelSelectBtn.Font             = Enum.Font.GothamBlack
levelSelectBtn.TextScaled       = true
levelSelectBtn.Text             = "Level Select"
levelSelectBtn.ZIndex           = 51
levelSelectBtn.Parent           = endPanel
Instance.new("UICorner", levelSelectBtn).CornerRadius = UDim.new(0, 10)
levelSelectBtn.MouseButton1Click:Connect(function()
	levelSelectBtn.Active = false
	levelSelectBtn.Text   = "Returning..."
	if RunService:IsStudio() then
		endOverlay.Visible = false
		showStudioLevelPicker()
	elseif HUB_PLACE_ID ~= 0 then
		local opts = Instance.new("TeleportOptions")
		opts:SetTeleportData({ xpRewards = pendingXPRewards })
		TeleportService:Teleport(HUB_PLACE_ID, player, opts)
	end
end)

BattleEnd.OnClientEvent:Connect(function(result)
	setArrowsVisible(false)
	abilityBar.Visible = false
	clearAbilityButtons()
	cancelSelection()
	replayBtn.Active = true
	replayBtn.Text   = "Replay"
	levelSelectBtn.Active = true
	levelSelectBtn.Text   = "Level Select"
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
		pendingXPRewards = nil
		endTitle.Text     = "Defeated"
		endTitle.TextColor3 = Color3.fromRGB(220, 80, 80)
	end
end)

print("[CombatClient] Ready")

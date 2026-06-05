local HUB_PLACE_ID = 122635524593151

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")

local Shared        = ReplicatedStorage:WaitForChild("Shared")
local CombatShared  = ReplicatedStorage:WaitForChild("CombatShared")
local CombatLibrary = require(Shared:WaitForChild("CombatLibrary"))
local EnemyPool     = require(CombatShared:WaitForChild("EnemyPool"))

-- ─── REMOTES ──────────────────────────────────────────────────────────
local remotes = Instance.new("Folder")
remotes.Name   = "CombatRemotes"
remotes.Parent = ReplicatedStorage

local function makeEvent(name)
	local e = Instance.new("RemoteEvent")
	e.Name = name; e.Parent = remotes; return e
end

local SendUnitData  = makeEvent("SendUnitData")
local BattleState   = makeEvent("BattleState")
local PlayerAction  = makeEvent("PlayerAction")
local BattleEnd     = makeEvent("BattleEnd")
local ModelsSpawned = makeEvent("ModelsSpawned")

-- ─── CONSTANTS ────────────────────────────────────────────────────────
local PLAYER_SLOTS = {
	Vector3.new(-7,  0, 11),
	Vector3.new(-2,  0, 13),
	Vector3.new(3,   0, 11),
	Vector3.new(7,   0, 13),
}
local ENEMY_SLOTS = {
	Vector3.new(-5,  0, -10),
	Vector3.new(0,   0, -12),
	Vector3.new(5,   0, -10),
	Vector3.new(-2,  0, -14),
}


local activeBattles = {}
local arenaFolder   = nil

-- ─── ARENA ────────────────────────────────────────────────────────────
local function part(parent, name, size, pos, color, mat, anchored, collide)
	local p = Instance.new("Part")
	p.Name        = name
	p.Size        = size
	p.Position    = pos
	p.Color       = color
	p.Material    = mat or Enum.Material.SmoothPlastic
	p.Anchored    = anchored ~= false
	p.CanCollide  = collide == true
	p.CastShadow  = false
	p.Parent      = parent
	return p
end

local function buildArea1()
	-- Remove default Roblox baseplate/spawn so the arena is visible
	local bp = Workspace:FindFirstChild("Baseplate")
	if bp then bp:Destroy() end
	local sp = Workspace:FindFirstChild("SpawnLocation")
	if sp then sp:Destroy() end

	if arenaFolder then arenaFolder:Destroy() end
	arenaFolder = Instance.new("Folder")
	arenaFolder.Name = "CombatArena"

	local pFolder = Instance.new("Folder")
	pFolder.Name = "PlayerUnits"; pFolder.Parent = arenaFolder

	local eFolder = Instance.new("Folder")
	eFolder.Name = "EnemyUnits"; eFolder.Parent = arenaFolder

	-- Ground
	local ground = part(arenaFolder, "Ground",
		Vector3.new(72, 1, 58), Vector3.new(0, -0.5, 0),
		Color3.fromRGB(108, 130, 65), Enum.Material.Grass, true, true)

	-- Player-side lighter patch
	part(arenaFolder, "PlayerPatch",
		Vector3.new(34, 0.3, 18), Vector3.new(-1, 0.15, 12),
		Color3.fromRGB(128, 156, 76), Enum.Material.Grass)

	-- Background treeline
	local trees = {
		{-22,-26},{-14,-27},{-6,-28},{2,-28},{10,-27},{18,-26},{24,-24},
		{-25,-18},{22,-18},
	}
	for _, td in ipairs(trees) do
		local x, z  = td[1], td[2]
		local h     = 11 + math.random(0, 4)

		-- trunk (cylinder laid on its side is the Roblox default for cylinders)
		local trunk = Instance.new("Part")
		trunk.Shape    = Enum.PartType.Cylinder
		trunk.Size     = Vector3.new(h, 1.4, 1.4)
		trunk.CFrame   = CFrame.new(x, h * 0.5, z) * CFrame.Angles(0, 0, math.pi * 0.5)
		trunk.Color    = Color3.fromRGB(100, 68, 30)
		trunk.Material = Enum.Material.Wood
		trunk.Anchored = true; trunk.CanCollide = false; trunk.CastShadow = false
		trunk.Parent   = arenaFolder

		local leaves = Instance.new("Part")
		leaves.Shape   = Enum.PartType.Ball
		leaves.Size    = Vector3.new(9, 9, 9)
		leaves.Position = Vector3.new(x, h + 4, z)
		leaves.Color   = Color3.fromRGB(62 + math.random(0,18), 108 + math.random(0,14), 34)
		leaves.Material = Enum.Material.Grass
		leaves.Anchored = true; leaves.CanCollide = false; leaves.CastShadow = false
		leaves.Parent  = arenaFolder
	end

	-- Scattered rocks
	local rocks = { {10,4},{-11,2},{13,-5},{-9,-6},{6,-7},{-3,7} }
	for _, rd in ipairs(rocks) do
		local r = part(arenaFolder, "Rock",
			Vector3.new(1.4 + math.random(), 1 + math.random() * 0.5, 1.4 + math.random()),
			Vector3.new(rd[1], 0.4, rd[2]),
			Color3.fromRGB(118, 118, 124), Enum.Material.Rock)
		local rc = Instance.new("UICorner"); rc.Parent = r  -- ignored on Parts, harmless
		_ = rc
	end

	-- Thin dividing line (subtle, decorative)
	part(arenaFolder, "Divider",
		Vector3.new(40, 0.2, 0.5), Vector3.new(0, 0.2, 0),
		Color3.fromRGB(90, 110, 55), Enum.Material.Grass)

	arenaFolder.Parent = Workspace
end

-- ─── HP BAR BILLBOARD ─────────────────────────────────────────────────
local function addHPBar(primaryPart, studOffset)
	local bill = Instance.new("BillboardGui")
	bill.Name         = "HPBill"
	bill.Size         = UDim2.fromOffset(88, 11)
	bill.StudsOffset  = Vector3.new(0, studOffset, 0)
	bill.AlwaysOnTop  = false
	bill.MaxDistance  = 100
	bill.Parent       = primaryPart

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1,1)
	bg.BackgroundColor3 = Color3.fromRGB(30,8,8)
	bg.BorderSizePixel  = 0
	bg.Parent = bill
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 3)

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.fromScale(1,1)
	bar.BackgroundColor3 = Color3.fromRGB(80, 200, 90)
	bar.BorderSizePixel  = 0
	bar.Parent = bg
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 3)

	return bar
end

-- ─── HUMANOID MODEL BUILDER (same style as hub followers) ─────────────
local HS   = 0.5  -- humanoid scale
local SKIN_COL    = Color3.fromRGB(255, 220, 185)
local PANTS_PLAYER = Color3.fromRGB(30,  50, 110)
local PANTS_ENEMY  = Color3.fromRGB(70,  25,  25)

local SHIRT_COLORS = {
	Water   = Color3.fromRGB(40,  120, 220),
	Fire    = Color3.fromRGB(210,  55,  40),
	Wind    = Color3.fromRGB(100, 190,  70),
	Light   = Color3.fromRGB(240, 220,  80),
	Dark    = Color3.fromRGB(130,  60, 200),
	Neutral = Color3.fromRGB(120, 120, 130),
}
local MANE_COLORS2 = {
	Fire = Color3.fromRGB(255, 140, 20),
	Wind = Color3.fromRGB(160, 255, 80),
}

local function hPart(model, name, size, color, canCollide)
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.Color = color
	p.CanCollide = canCollide == true; p.CastShadow = false; p.Parent = model
	return p
end

local function hMotor(parent, name, p0, p1, c0, c1)
	local m = Instance.new("Motor6D")
	m.Name = name; m.Part0 = p0; m.Part1 = p1; m.C0 = c0; m.C1 = c1; m.Parent = parent
end

local function buildHumanoid(pos, facingYRot, shirtCol, pantsCol, headCol, modelName)
	local spawnCF = CFrame.new(pos + Vector3.new(0, 2, 0)) * CFrame.Angles(0, facingYRot, 0)
	local model = Instance.new("Model")
	model.Name = modelName or "CombatUnit"

	local hrp = hPart(model, "HumanoidRootPart", Vector3.new(2*HS, 2*HS, HS), Color3.new(1,1,1), false)
	hrp.Transparency = 1; hrp.Anchored = true; hrp.CFrame = spawnCF
	model.PrimaryPart = hrp

	local hum = Instance.new("Humanoid")
	hum.WalkSpeed = 0; hum.JumpPower = 0; hum.HipHeight = 0.1
	hum.MaxHealth = math.huge; hum.Health = math.huge; hum.Parent = model

	local torso    = hPart(model, "Torso",     Vector3.new(2*HS, 2*HS, HS), shirtCol, true)
	local head     = hPart(model, "Head",      Vector3.new(2*HS, HS,   HS), headCol,  false)
	local leftArm  = hPart(model, "Left Arm",  Vector3.new(HS,  2*HS, HS), SKIN_COL, false)
	local rightArm = hPart(model, "Right Arm", Vector3.new(HS,  2*HS, HS), SKIN_COL, false)
	local leftLeg  = hPart(model, "Left Leg",  Vector3.new(HS,  2*HS, HS), pantsCol, true)
	local rightLeg = hPart(model, "Right Leg", Vector3.new(HS,  2*HS, HS), pantsCol, true)

	hMotor(hrp,   "RootJoint",      hrp,   torso,    CFrame.new(0,-HS,0,-1,0,0,0,0,1,0,1,0),    CFrame.new(0,-HS,0,-1,0,0,0,0,1,0,1,0))
	hMotor(torso, "Neck",           torso, head,     CFrame.new(0,HS,0,-1,0,0,0,0,1,0,1,0),     CFrame.new(0,-0.5*HS,0,-1,0,0,0,0,1,0,1,0))
	hMotor(torso, "Right Shoulder", torso, rightArm, CFrame.new(HS,0.5*HS,0,0,0,1,0,1,0,-1,0,0),  CFrame.new(-0.5*HS,0.5*HS,0,0,0,1,0,1,0,-1,0,0))
	hMotor(torso, "Left Shoulder",  torso, leftArm,  CFrame.new(-HS,0.5*HS,0,0,0,-1,0,1,0,1,0,0), CFrame.new(0.5*HS,0.5*HS,0,0,0,-1,0,1,0,1,0,0))
	hMotor(torso, "Right Hip",      torso, rightLeg, CFrame.new(HS,-HS,0,0,0,1,0,1,0,-1,0,0),     CFrame.new(0.5*HS,HS,0,0,0,1,0,1,0,-1,0,0))
	hMotor(torso, "Left Hip",       torso, leftLeg,  CFrame.new(-HS,-HS,0,0,0,-1,0,1,0,1,0,0),    CFrame.new(-0.5*HS,HS,0,0,0,-1,0,1,0,1,0,0))

	return model, torso, head
end

-- ─── MODEL SPAWNERS ────────────────────────────────────────────────────
local function spawnPlayerModel(unit, pos)
	local shirt = SHIRT_COLORS[unit.Type] or Color3.fromRGB(120, 120, 130)
	local model, torso = buildHumanoid(pos, 0, shirt, PANTS_PLAYER, SKIN_COL, unit.Name)
	model:SetAttribute("UnitId", unit.Id)
	model:SetAttribute("IsEnemy", false)
	model.Parent = arenaFolder:FindFirstChild("PlayerUnits")
	local bar = addHPBar(torso, 2)
	return model, bar
end

local function spawnEnemyModel(unit, pos)
	local shirt    = SHIRT_COLORS[unit.Type] or Color3.fromRGB(120, 120, 130)
	local maneCol  = MANE_COLORS2[unit.Type] or Color3.fromRGB(200, 180, 50)
	-- enemies get a neon glowing head for the mane effect
	local model, torso, head = buildHumanoid(pos, math.pi, shirt, PANTS_ENEMY, maneCol, unit.Name)
	head.Material = Enum.Material.Neon

	model:SetAttribute("UnitId", unit.Id)
	model:SetAttribute("IsEnemy", true)

	-- ClickDetector on torso for targeting
	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = 200; cd.Parent = torso

	model.Parent = arenaFolder:FindFirstChild("EnemyUnits")
	local bar = addHPBar(torso, 2)
	return model, bar
end

-- ─── BATTLE HELPERS ───────────────────────────────────────────────────
local function allDead(units)
	for _, u in ipairs(units) do
		if u.HP > 0 then return false end
	end
	return true
end

local function addLog(battle, msg)
	table.insert(battle.log, msg)
	if #battle.log > 12 then table.remove(battle.log, 1) end
end

local function updateHPBars(battle)
	for _, u in ipairs(battle.playerUnits) do
		if u.hpBar then
			local pct = math.clamp(u.HP / u.MaxHP, 0, 1)
			u.hpBar.Size = UDim2.fromScale(pct, 1)
			u.hpBar.BackgroundColor3 = pct > 0.5
				and Color3.fromRGB(80, 200, 90)
				or (pct > 0.25 and Color3.fromRGB(230, 180, 40) or Color3.fromRGB(210, 60, 60))
		end
	end
	for _, u in ipairs(battle.enemyUnits) do
		if u.hpBar then
			local pct = math.clamp(u.HP / u.MaxHP, 0, 1)
			u.hpBar.Size = UDim2.fromScale(pct, 1)
			u.hpBar.BackgroundColor3 = pct > 0.5
				and Color3.fromRGB(80, 200, 90)
				or (pct > 0.25 and Color3.fromRGB(230, 180, 40) or Color3.fromRGB(210, 60, 60))
			if u.HP <= 0 and u.model then
				for _, p in ipairs(u.model:GetDescendants()) do
					if p:IsA("BasePart") then p.Transparency = 0.75 end
				end
			end
		end
	end
	for _, u in ipairs(battle.playerUnits) do
		if u.HP <= 0 and u.model then
			for _, p in ipairs(u.model:GetDescendants()) do
				if p:IsA("BasePart") then p.Transparency = 0.75 end
			end
		end
	end
end

local function snapshot(battle)
	local pSnap, eSnap = {}, {}
	for _, u in ipairs(battle.playerUnits) do
		table.insert(pSnap, {
			Id = u.Id, Name = u.Name, Type = u.Type,
			HP = u.HP, MaxHP = u.MaxHP,
			Abilities = u.Abilities, CooldownsRemaining = u.CooldownsRemaining,
		})
	end
	for _, u in ipairs(battle.enemyUnits) do
		table.insert(eSnap, { Id = u.Id, Name = u.Name, Type = u.Type, HP = u.HP, MaxHP = u.MaxHP })
	end
	updateHPBars(battle)
	BattleState:FireClient(battle.player, {
		playerUnits  = pSnap,
		enemyUnits   = eSnap,
		activeTurnId = battle.activeTurnId,
		log          = battle.log,
		phase        = battle.phase,
	})
end

local function tickCooldowns(unit)
	for k, v in pairs(unit.CooldownsRemaining) do
		if v > 0 then unit.CooldownsRemaining[k] = v - 1 end
	end
end

local function applyAction(battle, actor, action)
	local ability   = actor.Abilities and actor.Abilities[action.abilityIndex]
	local targetList = actor.IsEnemy and battle.playerUnits or battle.enemyUnits

	local target
	for _, u in ipairs(targetList) do
		if u.Id == action.targetId and u.HP > 0 then target = u; break end
	end
	if not target then
		for _, u in ipairs(targetList) do
			if u.HP > 0 then target = u; break end
		end
	end
	if not target then return end

	if ability and ability.Cooldown and ability.Cooldown > 0 then
		actor.CooldownsRemaining[action.abilityIndex] = ability.Cooldown
	end

	local abilityName = ability and ability.Name or "Basic Attack"

	if ability then
		if ability.Name == "Aqua Hurricane" then
			local total = 0
			for _ = 1, 3 do
				local dmg = CombatLibrary.CalculateDamageFromStats(actor, target)
				total = total + math.floor(dmg * 1.2)
			end
			target.HP = math.max(0, target.HP - total)
			addLog(battle, actor.Name .. " → Aqua Hurricane on " .. target.Name .. " (" .. total .. " dmg)")
			return
		elseif ability.Name == "Purify" then
			addLog(battle, actor.Name .. " uses Purify (ally heals — coming soon)")
			return
		elseif ability.Name == "Bite" then
			local dmg = math.floor(CombatLibrary.CalculateDamageFromStats(actor, target) * 3.6)
			target.HP = math.max(0, target.HP - dmg)
			addLog(battle, actor.Name .. " → Bite on " .. target.Name .. " (" .. dmg .. " dmg)")
			return
		elseif ability.Name == "Double Attack" then
			local total = 0
			for _ = 1, 2 do
				total = total + math.floor(CombatLibrary.CalculateDamageFromStats(actor, target) * 3.7)
			end
			target.HP = math.max(0, target.HP - total)
			addLog(battle, actor.Name .. " → Double Attack on " .. target.Name .. " (" .. total .. " dmg)")
			return
		elseif ability.Name == "Slash Rocks" then
			local bonus = math.floor(actor.MaxHP * 0.18)
			local base  = CombatLibrary.CalculateDamageFromStats(actor, target)
			local dmg   = math.floor(base + bonus)
			target.HP   = math.max(0, target.HP - dmg)
			addLog(battle, actor.Name .. " → Slash Rocks on " .. target.Name .. " (" .. dmg .. " dmg)")
			return
		elseif ability.Name == "Slash Waves" then
			local total = 0
			for _ = 1, 2 do
				local bonus = math.floor(actor.MaxHP * 0.12)
				total = total + math.floor(CombatLibrary.CalculateDamageFromStats(actor, target) + bonus)
			end
			target.HP = math.max(0, target.HP - total)
			addLog(battle, actor.Name .. " → Slash Waves on " .. target.Name .. " (" .. total .. " dmg)")
			return
		elseif ability.Name == "Dash" then
			local dmg = math.floor(CombatLibrary.CalculateDamageFromStats(actor, target) * 3.5)
			target.HP = math.max(0, target.HP - dmg)
			addLog(battle, actor.Name .. " → Dash on " .. target.Name .. " (" .. dmg .. " dmg)")
			return
		end
	end

	-- Fallback: basic attack
	local dmg, ht = CombatLibrary.CalculateDamageFromStats(actor, target)
	target.HP = math.max(0, target.HP - dmg)
	addLog(battle, actor.Name .. " → " .. abilityName .. " on " .. target.Name .. " (" .. dmg .. ", " .. ht .. ")")
end

local function enemyAI(battle, enemy)
	local target
	for _, u in ipairs(battle.playerUnits) do
		if u.HP > 0 then target = u; break end
	end
	if not target then return end
	if enemy.Abilities and #enemy.Abilities > 0 then
		applyAction(battle, enemy, { abilityIndex = 1, targetId = target.Id })
	else
		local dmg, ht = CombatLibrary.CalculateDamageFromStats(enemy, target)
		target.HP = math.max(0, target.HP - dmg)
		addLog(battle, enemy.Name .. " attacks " .. target.Name .. " (" .. dmg .. ", " .. ht .. ")")
	end
end

-- ─── BATTLE LOOP ──────────────────────────────────────────────────────
local function runBattle(player, battle)
	addLog(battle, "DBG: " .. #battle.playerUnits .. " player units, " .. #battle.enemyUnits .. " enemies")
	for i, u in ipairs(battle.playerUnits) do
		addLog(battle, "  P" .. i .. ": " .. u.Name .. " HP=" .. tostring(u.HP))
	end
	task.wait(0.8)
	addLog(battle, "⚔ Battle begins!")
	snapshot(battle)

	while true do
		if allDead(battle.enemyUnits) then
			battle.phase = "victory"
			addLog(battle, "🏆 Victory!")
			snapshot(battle)
			task.wait(2)
			BattleEnd:FireClient(player, { victory = true })
			break
		end
		if allDead(battle.playerUnits) then
			battle.phase = "defeat"
			addLog(battle, "💀 DEFEAT v3 — " .. #battle.playerUnits .. " player units")
			snapshot(battle)
			task.wait(2)
			BattleEnd:FireClient(player, { victory = false })
			break
		end

		local order = {}
		for _, u in ipairs(battle.playerUnits) do if u.HP > 0 then table.insert(order, u) end end
		for _, u in ipairs(battle.enemyUnits)  do if u.HP > 0 then table.insert(order, u) end end
		table.sort(order, function(a, b) return a.Speed > b.Speed end)

		for _, unit in ipairs(order) do
			if unit.HP <= 0 then continue end
			battle.activeTurnId = unit.Id
			tickCooldowns(unit)

			if not unit.IsEnemy then
				battle.phase            = "player_action"
				battle.waitingForAction = true
				battle.pendingAction    = nil
				snapshot(battle)

				local elapsed = 0
				while battle.waitingForAction and elapsed < 30 do
					task.wait(0.1); elapsed += 0.1
				end

				if battle.pendingAction then
					applyAction(battle, unit, battle.pendingAction)
				else
					local firstEnemy
					for _, e in ipairs(battle.enemyUnits) do
						if e.HP > 0 then firstEnemy = e; break end
					end
					if firstEnemy then
						local dmg, ht = CombatLibrary.CalculateDamageFromStats(unit, firstEnemy)
						firstEnemy.HP = math.max(0, firstEnemy.HP - dmg)
						addLog(battle, unit.Name .. " auto-attacks " .. firstEnemy.Name .. " (" .. dmg .. ", " .. ht .. ")")
					end
				end
				battle.waitingForAction = false
				battle.phase = "resolving"
				snapshot(battle)
				task.wait(0.6)
			else
				battle.phase = "enemy_action"
				snapshot(battle)
				task.wait(1.2)
				enemyAI(battle, unit)
				battle.phase = "resolving"
				snapshot(battle)
				task.wait(0.6)
			end

			if allDead(battle.enemyUnits) or allDead(battle.playerUnits) then break end
		end
	end

	activeBattles[player.UserId] = nil
end

-- ─── UNIT FACTORY HELPERS ─────────────────────────────────────────────
local function makePlayerUnit(data, slot)
	return {
		Id = "p"..slot, IsEnemy = false,
		Name = data.DisplayName or data.CharacterName or "Unit",
		Type = data.Type or "Neutral",
		MaxHP = data.HP or 100, HP = data.HP or 100,
		Attack = data.Attack or 10, Defense = data.Defense or 10,
		Speed = data.Speed or 50, CritChance = data.CritChance or 0.05,
		CritDamage = data.CritDamage or 1.5, Resistance = data.Resistance or 0,
		Accuracy = data.Accuracy or 0, Abilities = data.Abilities or {},
		CooldownsRemaining = {}, model = nil, hpBar = nil,
	}
end

local function makeEnemyUnit(data, slot)
	return {
		Id = "e"..slot, IsEnemy = true,
		Name = data.Name, Type = data.Type or "Neutral",
		MaxHP = data.HP, HP = data.HP,
		Attack = data.Attack, Defense = data.Defense,
		Speed = data.Speed, CritChance = data.CritChance or 0.05,
		CritDamage = data.CritDamage or 1.5, Resistance = data.Resistance or 0,
		Accuracy = data.Accuracy or 0, Abilities = data.Abilities or {},
		CooldownsRemaining = {}, model = nil, hpBar = nil,
	}
end

-- ─── REMOTE HANDLERS ──────────────────────────────────────────────────
local STUDIO_TEST_UNITS = {
	{ CharacterName = "Water Fairy", DisplayName = "Water Fairy", Type = "Water",
	  HP = 1815, Attack = 107, Defense = 136, Speed = 103,
	  CritChance = 0.15, CritDamage = 1.5, Resistance = 0.15, Accuracy = 0,
	  Abilities = {
		{ Name = "Aqua Hurricane", Type = "Active", Cooldown = 0, Description = "Attacks 3x. 120% ATK x3." },
		{ Name = "Purify",         Type = "Active", Cooldown = 3, Description = "Remove debuffs and heal ally." },
	  } },
	{ CharacterName = "Fire Hellhound", DisplayName = "Fire Hellhound", Type = "Fire",
	  HP = 1725, Attack = 227, Defense = 112, Speed = 115,
	  CritChance = 0.15, CritDamage = 1.5, Resistance = 0.15, Accuracy = 0,
	  Abilities = {
		{ Name = "Bite",          Type = "Active", Cooldown = 0, Description = "Bite, heal 30% of damage. 360% ATK." },
		{ Name = "Double Attack", Type = "Active", Cooldown = 3, Description = "Bite 2x. 370% ATK x2." },
	  } },
}

local function startBattle(player, unitList, areaId)
	if activeBattles[player.UserId] then return end

	-- In Studio always override with known-good test data
	if RunService:IsStudio() then
		unitList = STUDIO_TEST_UNITS
		areaId   = "area1"
	end

	if not unitList or #unitList == 0 then return end
	print("[startBattle]", player.Name, #unitList, "units, area:", areaId)

	local area = EnemyPool[areaId] or EnemyPool.area1
	local playerUnits, enemyUnits = {}, {}

	for i, u in ipairs(unitList) do
		table.insert(playerUnits, makePlayerUnit(u, i))
	end
	for i, e in ipairs(area.enemies) do
		table.insert(enemyUnits, makeEnemyUnit(e, i))
	end

	for i, u in ipairs(playerUnits) do
		local pos = PLAYER_SLOTS[i] or PLAYER_SLOTS[1]
		local model, bar = spawnPlayerModel(u, pos)
		u.model = model
		u.hpBar = bar
	end
	for i, u in ipairs(enemyUnits) do
		local pos = ENEMY_SLOTS[i] or ENEMY_SLOTS[1]
		local model, bar = spawnEnemyModel(u, pos)
		u.model = model
		u.hpBar = bar
	end

	ModelsSpawned:FireClient(player)

	local battle = {
		player = player, playerUnits = playerUnits, enemyUnits = enemyUnits,
		activeTurnId = nil, log = {}, phase = "starting",
		waitingForAction = false, pendingAction = nil,
	}
	activeBattles[player.UserId] = battle
	task.spawn(runBattle, player, battle)
end

SendUnitData.OnServerEvent:Connect(function(player, unitList, areaId)
	startBattle(player, unitList, areaId)
end)

-- In Studio, auto-start battle — handle both players already in and ones joining later
if RunService:IsStudio() then
	local function autoStart(player)
		task.delay(2, function()
			startBattle(player, STUDIO_TEST_UNITS, "area1")
		end)
	end
	Players.PlayerAdded:Connect(autoStart)
	for _, p in ipairs(Players:GetPlayers()) do
		autoStart(p)
	end
end

PlayerAction.OnServerEvent:Connect(function(player, action)
	local battle = activeBattles[player.UserId]
	if not battle or not battle.waitingForAction then return end
	battle.pendingAction    = action
	battle.waitingForAction = false
end)

Players.PlayerRemoving:Connect(function(player)
	activeBattles[player.UserId] = nil
end)

buildArea1()
print("[CombatServer] Area 1 arena ready")

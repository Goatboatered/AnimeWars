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
local CharacterPool = require(Shared:WaitForChild("CharacterPool"))

-- Cache of CharacterName → full ability list from CharacterPool
local cpAbilityCache = {}
local function getCharacterAbilities(charName)
	if not charName or charName == "" then return nil end
	if cpAbilityCache[charName] then return cpAbilityCache[charName] end
	for _, entry in ipairs(CharacterPool.GetPool("normal")) do
		if entry.Name == charName then
			cpAbilityCache[charName] = entry.Abilities or {}
			return cpAbilityCache[charName]
		end
	end
	return nil
end

-- ─── REMOTES ──────────────────────────────────────────────────────────
local remotes = Instance.new("Folder")
remotes.Name   = "CombatRemotes"
remotes.Parent = ReplicatedStorage

local function makeEvent(name)
	local e = Instance.new("RemoteEvent")
	e.Name = name; e.Parent = remotes; return e
end

local SendUnitData   = makeEvent("SendUnitData")
local BattleState    = makeEvent("BattleState")
local PlayerAction   = makeEvent("PlayerAction")
local BattleEnd      = makeEvent("BattleEnd")
local ModelsSpawned  = makeEvent("ModelsSpawned")
local SetAutoMode    = makeEvent("SetAutoMode")
local SetBattleSpeed = makeEvent("SetBattleSpeed")

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

	part(arenaFolder, "Ground",
		Vector3.new(72, 1, 58), Vector3.new(0, -0.5, 0),
		Color3.fromRGB(160, 160, 160), Enum.Material.SmoothPlastic, true, true)

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

-- ─── NPC MODEL BUILDER ───────────────────────────────────────────────
local NOOB_YELLOW = Color3.fromRGB(245, 205,  48)
local NOOB_GREEN  = Color3.fromRGB( 75, 151,  75)

local SHIRT_COLORS = {
	Water   = Color3.fromRGB( 40, 120, 220),
	Fire    = Color3.fromRGB(210,  55,  40),
	Wind    = Color3.fromRGB(240, 210,  50),
	Light   = Color3.fromRGB(240, 240, 240),
	Dark    = Color3.fromRGB(130,  60, 200),
	Neutral = Color3.fromRGB(120, 120, 130),
}

local function buildHumanoid(pos, facingYRot, shirtCol, modelName)
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor     = NOOB_YELLOW
	desc.TorsoColor    = shirtCol
	desc.LeftArmColor  = NOOB_YELLOW
	desc.RightArmColor = NOOB_YELLOW
	desc.LeftLegColor  = NOOB_GREEN
	desc.RightLegColor = NOOB_GREEN

	local ok, model = pcall(Players.CreateHumanoidModelFromDescription, Players, desc, Enum.HumanoidRigType.R6)
	if not ok or not model then
		warn("[CombatServer] buildHumanoid failed:", model)
		return nil, nil
	end

	model.Name = modelName or "CombatUnit"

	local hrp = model.PrimaryPart
	if hrp then
		hrp.Anchored = true
		hrp.CFrame = CFrame.new(pos.X, 4.5, pos.Z) * CFrame.Angles(0, facingYRot, 0)
	end

	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = 0
		hum.JumpPower = 0
		hum.MaxHealth = math.huge
		hum.Health    = math.huge
	end

	local torso = model:FindFirstChild("Torso")
	return model, torso
end

-- ─── MODEL SPAWNERS ────────────────────────────────────────────────────
local function spawnPlayerModel(unit, pos)
	local shirt = SHIRT_COLORS[unit.Type] or Color3.fromRGB(120, 120, 130)
	local model, torso = buildHumanoid(pos, 0, shirt, unit.Name)
	if not model or not torso then return nil, nil end

	model:SetAttribute("UnitId", unit.Id)
	model:SetAttribute("IsEnemy", false)

	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = 200
	cd.Parent = torso

	model.Parent = arenaFolder:FindFirstChild("PlayerUnits")
	local bar = addHPBar(torso, 3)
	return model, bar
end

local function spawnEnemyModel(unit, pos)
	local shirt = SHIRT_COLORS[unit.Type] or Color3.fromRGB(120, 120, 130)
	local model, torso = buildHumanoid(pos, math.pi, shirt, unit.Name)
	if not model or not torso then return nil, nil end

	model:SetAttribute("UnitId", unit.Id)
	model:SetAttribute("IsEnemy", true)

	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = 200
	cd.Parent = torso

	model.Parent = arenaFolder:FindFirstChild("EnemyUnits")
	local bar = addHPBar(torso, 3)
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

-- Speed-aware wait: divides delay by battle.speed (1/2/3×)
local function bwait(battle, t)
	task.wait(t / math.max(1, battle.speed or 1))
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
		autoMode     = battle.autoMode,
		speed        = battle.speed,
	})
end

local function tickCooldowns(unit)
	for k, v in pairs(unit.CooldownsRemaining) do
		if v > 0 then unit.CooldownsRemaining[k] = v - 1 end
	end
end

-- ─── APPLY ACTION ─────────────────────────────────────────────────────
local function applyAction(battle, actor, action)
	local ability    = actor.Abilities and actor.Abilities[action.abilityIndex]
	local targetSide = actor.IsEnemy and battle.playerUnits or battle.enemyUnits
	local allySide   = actor.IsEnemy and battle.enemyUnits  or battle.playerUnits

	-- Resolve primary enemy/ally target by Id, then first alive fallback
	local primaryTarget
	for _, u in ipairs(targetSide) do
		if u.Id == action.targetId and u.HP > 0 then primaryTarget = u; break end
	end
	if not primaryTarget then
		for _, u in ipairs(targetSide) do
			if u.HP > 0 then primaryTarget = u; break end
		end
	end

	-- Ally target (for AllySingle skills sent from client)
	local allyTarget
	for _, u in ipairs(allySide) do
		if u.Id == action.targetId and u.HP > 0 then allyTarget = u; break end
	end

	-- Set cooldown
	if ability and (ability.Cooldown or 0) > 0 then
		actor.CooldownsRemaining[action.abilityIndex] = ability.Cooldown
	end

	local abilityName = ability and ability.Name or "Basic Attack"

	-- Passives skip — fall through to basic attack
	if ability and ability.Type == "Passive" then
		ability = nil
	end

	-- Self-heal (non-damage self-recovery, e.g. Crouch)
	if ability and ability.SelfHeal then
		local mult    = ability.Multiplier or 0
		local healAmt = mult > 0 and math.floor(actor.MaxHP * math.min(mult, 1.0)) or math.floor(actor.MaxHP * 0.25)
		actor.HP = math.min(actor.MaxHP, actor.HP + healAmt)
		addLog(battle, actor.Name .. " → " .. abilityName .. " recovers (+" .. healAmt .. " HP)")
		return
	end

	-- Pure ally heal
	if ability and ability.Heals then
		local mult   = ability.Multiplier or 0
		local scales = ability.ScalesWith or "ATK"

		local function healUnit(u)
			local healAmt
			if mult > 0 then
				if scales == "HP" then
					healAmt = math.floor(u.MaxHP * math.min(mult, 1.0))
				else
					healAmt = math.floor(actor.Attack * mult)
				end
			else
				healAmt = math.floor(u.MaxHP * 0.25)
			end
			local before = u.HP
			u.HP = math.min(u.MaxHP, u.HP + healAmt)
			return u.HP - before
		end

		if ability.AoE then
			local total = 0
			for _, u in ipairs(allySide) do
				if u.HP > 0 then
					total += healUnit(u)
				end
			end
			addLog(battle, actor.Name .. " → " .. abilityName .. " heals all allies (+" .. total .. " HP total)")
		else
			-- Use explicitly targeted ally, or find lowest HP fraction
			local healTarget = allyTarget
			if not healTarget then
				local lowestFrac = 2
				for _, u in ipairs(allySide) do
					if u.HP > 0 then
						local frac = u.HP / u.MaxHP
						if frac < lowestFrac then
							lowestFrac = frac
							healTarget = u
						end
					end
				end
			end
			if healTarget then
				local healAmt = healUnit(healTarget)
				addLog(battle, actor.Name .. " → " .. abilityName .. " heals " .. healTarget.Name .. " (+" .. healAmt .. " HP)")
			else
				addLog(battle, actor.Name .. " → " .. abilityName .. " (no ally to heal)")
			end
		end
		return
	end

	-- Damage ability (or basic attack when ability is nil)
	if not primaryTarget then return end

	local multiplier = (ability and ability.Multiplier) or 3.5
	if multiplier <= 0 then multiplier = 3.5 end
	local hits       = math.max(1, (ability and ability.Hits) or 1)
	local isAoE      = ability and ability.AoE
	local scalesWith = (ability and ability.ScalesWith) or "ATK"
	local lifeSteal  = ability and ability.LifeSteal

	local targets = {}
	if isAoE then
		for _, u in ipairs(targetSide) do
			if u.HP > 0 then table.insert(targets, u) end
		end
	else
		table.insert(targets, primaryTarget)
	end

	if #targets == 0 then return end

	local totalDmg = 0
	local lastHt   = "Normal"

	for _ = 1, hits do
		for _, t in ipairs(targets) do
			if t.HP <= 0 then continue end
			local dmg, ht
			if scalesWith == "HP" then
				local ratio = 1000 / (1000 + (t.Defense or 0))
				dmg = math.floor(actor.MaxHP * multiplier * ratio)
				ht  = "Normal"
			elseif scalesWith == "DEF" then
				local ratio = 1000 / (1000 + (t.Defense or 0))
				dmg = math.floor(actor.Defense * multiplier * ratio)
				ht  = "Normal"
			else
				local raw, rawHt = CombatLibrary.CalculateDamageFromStats(actor, t)
				dmg = math.floor(raw * multiplier)
				ht  = rawHt
			end
			t.HP      = math.max(0, t.HP - dmg)
			totalDmg += dmg
			lastHt    = ht
		end
	end

	if isAoE then
		addLog(battle, actor.Name .. " → " .. abilityName .. " AoE (" .. totalDmg .. " dmg)")
	elseif hits > 1 then
		addLog(battle, actor.Name .. " → " .. abilityName .. " x" .. hits .. " on " .. primaryTarget.Name .. " (" .. totalDmg .. " dmg)")
	else
		addLog(battle, actor.Name .. " → " .. abilityName .. " on " .. primaryTarget.Name .. " (" .. totalDmg .. ", " .. tostring(lastHt) .. ")")
	end

	if lifeSteal and totalDmg > 0 and not actor.IsEnemy then
		local heal = math.floor(totalDmg * 0.3)
		actor.HP   = math.min(actor.MaxHP, actor.HP + heal)
		addLog(battle, actor.Name .. " lifesteals +" .. heal .. " HP")
	end
end

-- ─── ENEMY AI ─────────────────────────────────────────────────────────
-- Which element types does each attacker type have advantage against?
local ELEMENT_ADVANTAGE = {
	Water = { Fire = true },
	Fire  = { Wind = true },
	Wind  = { Water = true },
	Light = { Dark = true },
	Dark  = { Light = true },
}

local function pickLowestHP(list)
	local best = list[1]
	local bestFrac = best.HP / best.MaxHP
	for _, u in ipairs(list) do
		local f = u.HP / u.MaxHP
		if f < bestFrac then
				bestFrac = f
				best = u
			end
	end
	return best
end

local function enemyAI(battle, enemy)
	local targets = {}
	for _, u in ipairs(battle.playerUnits) do
		if u.HP > 0 then table.insert(targets, u) end
	end
	if #targets == 0 then return end

	-- Prefer targets the enemy has elemental advantage against
	local adv = ELEMENT_ADVANTAGE[enemy.Type] or {}
	local advantaged, others = {}, {}
	for _, u in ipairs(targets) do
		if adv[u.Type] then
			table.insert(advantaged, u)
		else
			table.insert(others, u)
		end
	end

	local target = #advantaged > 0 and pickLowestHP(advantaged) or pickLowestHP(others)

	local bestIdx = nil
	if enemy.Abilities then
		for i = #enemy.Abilities, 1, -1 do
			local ab = enemy.Abilities[i]
			if ab and ab.Type ~= "Passive" then
				local cd = enemy.CooldownsRemaining[i] or 0
				if cd <= 0 then bestIdx = i; break end
			end
		end
		if not bestIdx then
			for i = 1, #enemy.Abilities do
				if enemy.Abilities[i] and enemy.Abilities[i].Type ~= "Passive" then
					bestIdx = i; break
				end
			end
		end
	end

	if bestIdx then
		applyAction(battle, enemy, { abilityIndex = bestIdx, targetId = target.Id })
	else
		local dmg, ht = CombatLibrary.CalculateDamageFromStats(enemy, target)
		target.HP = math.max(0, target.HP - dmg)
		addLog(battle, enemy.Name .. " attacks " .. target.Name .. " (" .. dmg .. ", " .. tostring(ht) .. ")")
	end
end

-- ─── AUTO PLAYER AI ───────────────────────────────────────────────────
local function autoPlayerAI(battle, unit)
	local abilities = unit.Abilities or {}
	local cds       = unit.CooldownsRemaining or {}

	local enemies, allies = {}, {}
	for _, u in ipairs(battle.enemyUnits) do if u.HP > 0 then table.insert(enemies, u) end end
	for _, u in ipairs(battle.playerUnits) do if u.HP > 0 then table.insert(allies, u) end end
	if #enemies == 0 then return nil end

	-- Target: lowest HP% enemy
	local targetEnemy = enemies[1]
	for _, u in ipairs(enemies) do
		if (u.HP / u.MaxHP) < (targetEnemy.HP / targetEnemy.MaxHP) then targetEnemy = u end
	end

	-- Lowest HP% ally
	local lowestAlly, lowestFrac = allies[1], 2
	for _, u in ipairs(allies) do
		local f = u.HP / u.MaxHP
		if f < lowestFrac then
			lowestFrac = f
			lowestAlly = u
		end
	end

	-- Score every off-cooldown non-passive ability and pick the best
	local bestIdx, bestScore = nil, -1
	for i, ab in ipairs(abilities) do
		if ab.Type == "Passive" then continue end
		if (cds[i] or 0) > 0 then continue end

		local score = 0

		if ab.Heals or ab.SelfHeal then
			-- Only heal when someone has lost at least 15% HP so heals are meaningful
			local missingHP = 1 - lowestFrac
			if missingHP > 0.15 then
				score = missingHP * 100
				if ab.AoE then
					score = score * 1.5
				end
				if lowestFrac < 0.4 then
					score = score + 100
				end
			end
		else
			-- Damage ability: score = effective total damage
			local eff = (ab.Multiplier or 3.5) * math.max(1, ab.Hits or 1)
			score = eff * 10
			if ab.AoE and #enemies >= 2 then
				score = score * #enemies
			end
		end

		if score > bestScore then
			bestScore = score
			bestIdx = i
		end
	end

	if not bestIdx then return nil end

	local ab = abilities[bestIdx]
	local targetId
	if ab.SelfHeal then
		targetId = unit.Id
	elseif ab.Heals then
		targetId = (lowestAlly and lowestAlly.Id) or unit.Id
	else
		targetId = targetEnemy.Id
	end

	return { abilityIndex = bestIdx, targetId = targetId }
end

-- ─── UNIT FACTORIES ───────────────────────────────────────────────────
local function makePlayerUnit(data, slot)
	local lv   = data.Level or 1
	local base = data.DisplayName or data.CharacterName or "Unit"
	-- UnitManager strips Heals/SelfHeal/LifeSteal/TargetType/Multiplier/Hits when cloning.
	-- Always pull authoritative ability data from CharacterPool so combat behavior is correct.
	local charName = data.CharacterName or data.DisplayName or ""
	local abilities = getCharacterAbilities(charName) or data.Abilities or {}
	return {
		Id     = "p"..slot, IsEnemy = false,
		Name   = "Lv." .. lv .. " " .. base,
		Type   = data.Type or "Neutral",
		MaxHP  = data.HP or 100, HP = data.HP or 100,
		Attack = data.Attack or 10, Defense = data.Defense or 10,
		Speed  = data.Speed or 50, CritChance = data.CritChance or 0.05,
		CritDamage = data.CritDamage or 1.5, Resistance = data.Resistance or 0,
		Accuracy = data.Accuracy or 0, Abilities = abilities,
		CooldownsRemaining = {}, model = nil, hpBar = nil,
	}
end

local function makeEnemyUnit(data, slot)
	local lv = data.Level or 1
	return {
		Id     = "e"..slot, IsEnemy = true,
		Name   = "Lv." .. lv .. " " .. data.Name,
		Type   = data.Type or "Neutral",
		MaxHP  = data.HP, HP = data.HP,
		Attack = data.Attack, Defense = data.Defense,
		Speed  = data.Speed, CritChance = data.CritChance or 0.05,
		CritDamage = data.CritDamage or 1.5, Resistance = data.Resistance or 0,
		Accuracy = data.Accuracy or 0, Abilities = data.Abilities or {},
		CooldownsRemaining = {}, model = nil, hpBar = nil,
	}
end

-- ─── WAVE SPAWNER ─────────────────────────────────────────────────────
local function spawnNextWave(battle)
	local eFolder = arenaFolder and arenaFolder:FindFirstChild("EnemyUnits")
	if eFolder then
		for _, child in ipairs(eFolder:GetChildren()) do
			child:Destroy()
		end
	end

	battle.currentWaveIndex += 1
	local waveData = battle.allWaves[battle.currentWaveIndex]
	local enemies  = waveData and waveData.enemies or {}

	battle.enemyUnits = {}
	for i, e in ipairs(enemies) do
		local unit = makeEnemyUnit(e, i)
		local pos  = ENEMY_SLOTS[i] or ENEMY_SLOTS[1]
		local model, bar = spawnEnemyModel(unit, pos)
		unit.model = model
		unit.hpBar  = bar
		table.insert(battle.enemyUnits, unit)
	end

	addLog(battle, "⚡ Wave " .. battle.currentWaveIndex .. " of " .. #battle.allWaves .. "!")
	ModelsSpawned:FireClient(battle.player)
end

-- ─── BATTLE LOOP ──────────────────────────────────────────────────────
local function runBattle(player, battle)
	addLog(battle, "DBG: " .. #battle.playerUnits .. " player units, " .. #battle.enemyUnits .. " enemies")
	for i, u in ipairs(battle.playerUnits) do
		addLog(battle, "  P" .. i .. ": " .. u.Name .. " HP=" .. tostring(u.HP))
	end
	bwait(battle, 0.8)
	addLog(battle, "⚔ Battle begins! (" .. #battle.allWaves .. " wave" .. (#battle.allWaves == 1 and "" or "s") .. ")")
	snapshot(battle)

	while true do
		if allDead(battle.enemyUnits) then
			if battle.currentWaveIndex < #battle.allWaves then
				battle.phase = "wave_transition"
				addLog(battle, "✓ Wave cleared!")
				snapshot(battle)
				bwait(battle, 1.2)
				spawnNextWave(battle)
				battle.phase = "resolving"
				snapshot(battle)
				bwait(battle, 0.5)
				continue
			end
			battle.phase = "victory"
			addLog(battle, "🏆 Victory!")
			snapshot(battle)
			bwait(battle, 2)
			local pIds = {}
			for _, u in ipairs(battle.playerUnits) do table.insert(pIds, u.Id) end
			BattleEnd:FireClient(player, { victory = true, xp = battle.stageXP, unitIds = pIds })
			break
		end
		if allDead(battle.playerUnits) then
			battle.phase = "defeat"
			addLog(battle, "💀 DEFEAT")
			snapshot(battle)
			bwait(battle, 2)
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
				if battle.autoMode then
					-- Auto: AI picks action for player unit
					battle.phase = "auto_action"
					snapshot(battle)
					bwait(battle, 0.8)
					local action = autoPlayerAI(battle, unit)
					if action then
						applyAction(battle, unit, action)
					end
				else
					-- Manual: wait for player input
					battle.phase            = "player_action"
					battle.waitingForAction = true
					battle.pendingAction    = nil
					snapshot(battle)

					local elapsed = 0
					while battle.waitingForAction and elapsed < 30 do
						task.wait(0.05); elapsed += 0.05
					end

					if battle.pendingAction then
						applyAction(battle, unit, battle.pendingAction)
					else
						-- Timeout: use slot 1 ability (always CD=0) against first alive enemy
						local firstEnemy
						for _, e in ipairs(battle.enemyUnits) do
							if e.HP > 0 then firstEnemy = e; break end
						end
						if firstEnemy then
							local fallbackIdx = 1
							for i, ab in ipairs(unit.Abilities or {}) do
								if ab.Type ~= "Passive" and not ab.Heals and not ab.SelfHeal then
									fallbackIdx = i
									break
								end
							end
							applyAction(battle, unit, { abilityIndex = fallbackIdx, targetId = firstEnemy.Id })
						end
					end
				end
				battle.waitingForAction = false
				battle.phase = "resolving"
				snapshot(battle)
				bwait(battle, 0.5)
			else
				battle.phase = "enemy_action"
				snapshot(battle)
				bwait(battle, 1.0)
				enemyAI(battle, unit)
				battle.phase = "resolving"
				snapshot(battle)
				bwait(battle, 0.5)
			end

			if allDead(battle.enemyUnits) or allDead(battle.playerUnits) then break end
		end
	end

	activeBattles[player.UserId] = nil
end

-- ─── REMOTE HANDLERS ──────────────────────────────────────────────────
local STUDIO_TEST_UNITS = {
	{ CharacterName = "Water Fairy", DisplayName = "Water Fairy", Type = "Water", Level = 30,
	  HP = 1815, Attack = 107, Defense = 136, Speed = 103,
	  CritChance = 0.15, CritDamage = 1.5, Resistance = 0.15, Accuracy = 0,
	  Abilities = {
		{ Name = "Aqua Hurricane", Type = "Active", Cooldown = 0, Multiplier = 1.2, Hits = 3,
		  AoE = false, Heals = false, SelfHeal = false, LifeSteal = false, TargetType = "EnemySingle" },
		{ Name = "Purify", Type = "Active", Cooldown = 3, Multiplier = 4, ScalesWith = "ATK",
		  Hits = 1, AoE = false, Heals = true, SelfHeal = false, LifeSteal = false, TargetType = "AllySingle" },
	  } },
	{ CharacterName = "Fire Hellhound", DisplayName = "Fire Hellhound", Type = "Fire", Level = 30,
	  HP = 1725, Attack = 227, Defense = 112, Speed = 115,
	  CritChance = 0.15, CritDamage = 1.5, Resistance = 0.15, Accuracy = 0,
	  Abilities = {
		{ Name = "Bite", Type = "Active", Cooldown = 0, Multiplier = 3.6, Hits = 1,
		  AoE = false, Heals = false, SelfHeal = false, LifeSteal = true, TargetType = "EnemySingle" },
		{ Name = "Double Attack", Type = "Active", Cooldown = 3, Multiplier = 3.7, Hits = 2,
		  AoE = false, Heals = false, SelfHeal = false, LifeSteal = false, TargetType = "EnemySingle" },
	  } },
}

local function startBattle(player, unitList, areaInfo)
	if activeBattles[player.UserId] then return end

	-- Clear leftover models from any previous run
	if arenaFolder then
		local pf = arenaFolder:FindFirstChild("PlayerUnits")
		local ef = arenaFolder:FindFirstChild("EnemyUnits")
		if pf then
			for _, c in ipairs(pf:GetChildren()) do
				c:Destroy()
			end
		end
		if ef then
			for _, c in ipairs(ef:GetChildren()) do
				c:Destroy()
			end
		end
	end

	if RunService:IsStudio() and (not unitList or #unitList == 0) then
		unitList = STUDIO_TEST_UNITS
	end

	if not unitList or #unitList == 0 then return end
	areaInfo = areaInfo or {}
	print("[startBattle]", player.Name, #unitList, "units, area:", areaInfo.num, areaInfo.difficulty, areaInfo.stage)

	local stageData = EnemyPool.GetStage(areaInfo.num or 1, areaInfo.difficulty or "normal", areaInfo.stage or 1)
	local area = stageData or EnemyPool.area1
	local stageXP  = area.xp or 0
	local allWaves = area.waves or {}

	if #allWaves == 0 and area.enemies then
		allWaves = { { enemies = area.enemies } }
	end

	local playerUnits, enemyUnits = {}, {}

	for i, u in ipairs(unitList) do
		table.insert(playerUnits, makePlayerUnit(u, i))
	end

	local firstWaveEnemies = allWaves[1] and allWaves[1].enemies or {}
	for i, e in ipairs(firstWaveEnemies) do
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
		allWaves = allWaves, currentWaveIndex = 1,
		activeTurnId = nil, log = {}, phase = "starting",
		waitingForAction = false, pendingAction = nil,
		stageXP = stageXP,
		autoMode = false, speed = 1,
	}
	activeBattles[player.UserId] = battle
	task.spawn(function()
		local ok, err = pcall(runBattle, player, battle)
		if not ok then
			warn("[CombatServer] runBattle crashed:", err)
			if activeBattles[player.UserId] then
				BattleEnd:FireClient(player, { victory = false })
				activeBattles[player.UserId] = nil
			end
		end
	end)
end

SendUnitData.OnServerEvent:Connect(function(player, unitList, areaInfo)
	startBattle(player, unitList, areaInfo)
end)

PlayerAction.OnServerEvent:Connect(function(player, action)
	local battle = activeBattles[player.UserId]
	if not battle or not battle.waitingForAction then
		print("[PlayerAction] REJECT: not waiting (waitingForAction=", battle and battle.waitingForAction, ")")
		return
	end
	if not action or action.abilityIndex == nil then
		print("[PlayerAction] REJECT: nil action")
		return
	end

	-- Find acting unit
	local actingUnit
	for _, u in ipairs(battle.playerUnits) do
		if u.Id == battle.activeTurnId then actingUnit = u; break end
	end
	if not actingUnit then
		print("[PlayerAction] REJECT: no actingUnit for activeTurnId=", battle.activeTurnId)
		return
	end

	-- Validate cooldown
	if action.abilityIndex > 0 then
		local ab = actingUnit.Abilities[action.abilityIndex]
		if not ab then
			print("[PlayerAction] REJECT: no ability at index", action.abilityIndex, "for", actingUnit.Name)
			return
		end
		local cd = actingUnit.CooldownsRemaining[action.abilityIndex] or 0
		if cd > 0 then
			print("[PlayerAction] REJECT: ability", ab.Name, "on cooldown", cd)
			return
		end

		-- Validate and auto-correct target based on TargetType
		local tt = ab.TargetType or "EnemySingle"
		if tt == "EnemySingle" then
			local found = false
			for _, u in ipairs(battle.enemyUnits) do
				if u.Id == action.targetId and u.HP > 0 then
					found = true
					break
				end
			end
			if not found then
				-- target is dead or invalid — reroute to first alive enemy
				for _, u in ipairs(battle.enemyUnits) do
					if u.HP > 0 then
						action.targetId = u.Id
						found = true
						break
					end
				end
				if not found then return end
			end
		elseif tt == "AllySingle" then
			local found = false
			for _, u in ipairs(battle.playerUnits) do
				if u.Id == action.targetId and u.HP > 0 then
					found = true
					break
				end
			end
			if not found then
				-- target is dead or invalid — reroute to first alive ally
				for _, u in ipairs(battle.playerUnits) do
					if u.HP > 0 then
						action.targetId = u.Id
						found = true
						break
					end
				end
				if not found then return end
			end
		end
		-- EnemyAll / AllyAll / Self / Passive: no target validation needed
	end

	print("[PlayerAction] ACCEPTED: unit=", actingUnit.Name, "abilityIdx=", action.abilityIndex, "targetId=", action.targetId)
	battle.pendingAction    = action
	battle.waitingForAction = false
end)

SetAutoMode.OnServerEvent:Connect(function(player, enabled)
	local battle = activeBattles[player.UserId]
	if not battle then return end
	battle.autoMode = enabled == true
	-- If toggling auto ON while waiting for action, immediately unblock
	if battle.autoMode and battle.waitingForAction then
		battle.waitingForAction = false
	end
end)

SetBattleSpeed.OnServerEvent:Connect(function(player, speed)
	local battle = activeBattles[player.UserId]
	if not battle then return end
	battle.speed = math.clamp(speed, 1, 3)
end)

Players.PlayerRemoving:Connect(function(player)
	activeBattles[player.UserId] = nil
end)

buildArea1()
print("[CombatServer] Area 1 arena ready")

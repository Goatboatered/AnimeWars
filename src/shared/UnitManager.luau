local UnitManager = {}
local playerUnits = {}

local MAX_LEVEL_FOR_STARS = {[1]=15,[2]=20,[3]=25,[4]=30,[5]=35,[6]=40}

local XP_TABLES = {
	[1] = {460,516,579,650,728,818,918,1029,1155,1296,1455,1631,1831,2054},
	[2] = {552,619,695,779,875,981,1102,1235,1386,1555,1745,1958,2197,2465,2765,3103,3481,3906,4423},
	[3] = {662,743,834,936,1049,1178,1321,1483,1663,1866,2094,2350,2636,2957,3319,3723,4178,4687,5307,6009,6802,7703,8720,9962},
	[4] = {796,892,1002,1124,1261,1415,1587,1781,1998,2243,2515,2823,3167,3553,3987,4473,5019,5631,6376,7219,8172,9254,10476,11969,13673,15619,17844,20386,23495},
	[5] = {952,1068,1199,1344,1509,1693,1899,2131,2392,2682,3010,3378,3789,4252,4770,5352,6006,6738,7628,8638,9779,11072,12535,14321,16360,18690,21350,24392,28113,32404,37348,43048,49617,57188},
	[6] = {1150,1290,1447,1624,1823,2044,2294,2574,2888,3240,3635,4079,4576,5135,5762,6464,7252,8138,9214,10431,11811,13371,15140,17296,19758,22572,25786,29458,33954,39134,45107,51990,59924,69068,76085,83816,92332,101712,112046},
}

local function xpToNextLevel(stars, level)
	local cap = MAX_LEVEL_FOR_STARS[stars] or 40
	if level >= cap then return math.huge end
	local tbl = XP_TABLES[stars] or XP_TABLES[6]
	return tbl[level] or math.huge
end

-- HP/ATK/DEF scale linearly from ~15.4% of base at level 1 to 100% at max level (SW formula).
-- Speed, CritChance, CritDamage, Resistance, Accuracy do not scale.
local STAT_MIN_RATIO = {[1]=0.154,[2]=0.154,[3]=0.154,[4]=0.154,[5]=0.154,[6]=0.154}

local function statAtLevel(base, level, cap, stars)
	if cap <= 1 then return base end
	local minRatio = STAT_MIN_RATIO[stars or 5] or 0.154
	local t = (level - 1) / (cap - 1)
	return math.floor(base * (minRatio + (1 - minRatio) * t))
end

-- EXP a material monster of that star grade grants (at level 1 vs max level, linear interpolation).
local POWERUP_EXP = {
	[1] = {min = 800,   max = 1210},
	[2] = {min = 1760,  max = 3086},
	[3] = {min = 3200,  max = 6204},
	[4] = {min = 6724,  max = 13851},
	[5] = {min = 16000, max = 43708},
	[6] = {min = 44001, max = 139356},
}

local function getMaterialExp(stars, level)
	local entry = POWERUP_EXP[stars]
	if not entry then return 0 end
	local cap = MAX_LEVEL_FOR_STARS[stars] or 40
	if cap <= 1 then return entry.max end
	local t = (level - 1) / (cap - 1)
	return math.floor(entry.min + (entry.max - entry.min) * t)
end

UnitManager.MAX_LEVEL           = 40
UnitManager.MAX_LEVEL_FOR_STARS = MAX_LEVEL_FOR_STARS
UnitManager.XPToNextLevel       = xpToNextLevel
UnitManager.StatAtLevel         = statAtLevel
UnitManager.GetMaterialExp      = getMaterialExp

local UNIT_ABILITIES = {
	["Fire Maned Boar"] = {
		{
			Name = "Dash",
			Type = "Active",
			Cooldown = 0,
			Description = "Attacks one enemy with a 15% chance to Stun for 1 turn.\nMultiplier: 350% ATK.",
		},
	},
	["Wind Maned Boar"] = {
		{
			Name = "Dash",
			Type = "Active",
			Cooldown = 0,
			Description = "Attacks one enemy with a 15% chance to Stun for 1 turn.\nMultiplier: 350% ATK.",
		},
	},
	["Wind Vagabond"] = {
		{
			Name = "Slash Rocks",
			Type = "Active",
			Cooldown = 0,
			Description = "Swings a giant sword to deal damage.\n40% chance to decrease Defense for 2 turns.\nMultiplier: ATK + 18% Max HP.",
		},
		{
			Name = "Slash Waves",
			Type = "Active",
			Cooldown = 4,
			Description = "Attacks the enemy 2 times.\nEach hit has a 50% chance to decrease Attack Power for 2 turns.\nMultiplier: ATK + 12% Max HP × 2.\nCooldown: 4 turns.",
		},
	},
	["Fire Hellhound"] = {
		{
			Name = "Bite",
			Type = "Active",
			Cooldown = 0,
			Description = "Bites the enemy and heals himself for 30% of the damage dealt.\nMultiplier: 360% ATK.",
		},
		{
			Name = "Double Attack",
			Type = "Active",
			Cooldown = 3,
			Description = "Bites the enemy 2 times to deal big damage.\nMultiplier: 370% ATK × 2.\nCooldown: 3 turns.",
		},
	},
	["Water Fairy"] = {
		{
			Name = "Aqua Hurricane",
			Type = "Active",
			Cooldown = 0,
			Description = "Attacks the enemy 3 times.\nEach hit has a 20% chance to Freeze for 1 turn.\nDamage Multiplier: 120% ATK × 3.",
		},
		{
			Name = "Purify",
			Type = "Active",
			Cooldown = 3,
			Description = "Removes harmful effects from an ally and heals them.\nHealing scales with the Water Fairy's ATK.\nCooldown: 3 turns.",
		},
	},
}

local function cloneUnit(unit)
	local abilitiesCopy = {}
	for i, ab in ipairs(unit.Abilities or {}) do
		abilitiesCopy[i] = { Name = ab.Name, Type = ab.Type, Cooldown = ab.Cooldown, Description = ab.Description }
	end
	return {
		Id = unit.Id,
		SourceId = unit.SourceId,
		CharacterName = unit.CharacterName,
		Type = unit.Type,
		Rarity = unit.Rarity,
		Stars = unit.Stars,
		BaseHP      = unit.BaseHP,
		BaseAttack  = unit.BaseAttack,
		BaseDefense = unit.BaseDefense,
		Attack = unit.Attack,
		Defense = unit.Defense,
		CritChance = unit.CritChance,
		CritDamage = unit.CritDamage,
		DisplayName = unit.DisplayName,
		AwakenLevel = unit.AwakenLevel or 0,
		AwakenBonus = unit.AwakenBonus or "",
		Level = unit.Level or 1,
		XP    = unit.XP    or 0,
		HP = unit.HP or 0,
		Speed = unit.Speed or 0,
		Resistance = unit.Resistance or 0,
		Accuracy = unit.Accuracy or 0,
		Abilities = abilitiesCopy,
	}
end

function UnitManager.InitializePlayer(player)
	if not player then
		return
	end

	playerUnits[player.UserId] = playerUnits[player.UserId] or {}
end

function UnitManager.ClearPlayer(player)
	if not player then
		return
	end

	playerUnits[player.UserId] = nil
end

function UnitManager.SetUnits(player, units)
	if not player or not player.UserId then
		return
	end

	playerUnits[player.UserId] = {}
	if type(units) ~= "table" then
		return
	end

	for _, unitData in ipairs(units) do
		if type(unitData) == "table" then
			UnitManager.AddUnit(player, unitData)
		end
	end
end

function UnitManager.AddUnit(player, unitData)
	if not player or not player.UserId then
		return nil
	end

	local units = playerUnits[player.UserId]
	if not units then
		units = {}
		playerUnits[player.UserId] = units
	end

	local charName = unitData.CharacterName or unitData.Name or "Unknown"
	local stars = unitData.Stars or 1
	local level = unitData.Level or 1
	local cap   = MAX_LEVEL_FOR_STARS[stars] or 40
	local baseHP  = unitData.BaseHP      or unitData.HP     or 0
	local baseAtk = unitData.BaseAttack  or unitData.Attack or 0
	local baseDef = unitData.BaseDefense or unitData.Defense or 0
	local entry = {
		Id = #units + 1,
		SourceId = unitData.SourceId,
		CharacterName = charName,
		Type = unitData.Type or "Neutral",
		Rarity = unitData.Rarity or "Common",
		Stars = stars,
		BaseHP      = baseHP,
		BaseAttack  = baseAtk,
		BaseDefense = baseDef,
		HP      = statAtLevel(baseHP,  level, cap, stars),
		Attack  = statAtLevel(baseAtk, level, cap, stars),
		Defense = statAtLevel(baseDef, level, cap, stars),
		CritChance = unitData.CritChance or 0,
		CritDamage = unitData.CritDamage or 1.5,
		DisplayName = unitData.DisplayName or unitData.CharacterName or unitData.Name or "Unknown",
		AwakenLevel = unitData.AwakenLevel or 0,
		AwakenBonus = unitData.AwakenBonus or "",
		Level = level,
		XP    = unitData.XP    or 0,
		Speed = unitData.Speed or 0,
		Resistance = unitData.Resistance or 0,
		Accuracy = unitData.Accuracy or 0,
		Abilities = unitData.Abilities or UNIT_ABILITIES[charName] or {},
	}

	table.insert(units, entry)
	return entry
end

function UnitManager.AddXP(player, unitId, xpAmount)
	local units = playerUnits[player.UserId]
	if not units then
		return false, 0
	end
	local unit
	for _, u in ipairs(units) do
		if u.Id == unitId then
			unit = u
			break
		end
	end
	if not unit then
		return false, 0
	end
	local cap = MAX_LEVEL_FOR_STARS[unit.Stars or 1] or 40
	if (unit.Level or 1) >= cap then
		return false, 0
	end
	unit.XP = (unit.XP or 0) + xpAmount
	local levelsGained = 0
	while (unit.Level or 1) < cap do
		local needed = xpToNextLevel(unit.Stars or 1, unit.Level or 1)
		if unit.XP >= needed then
			unit.XP    -= needed
			unit.Level  = (unit.Level or 1) + 1
			levelsGained += 1
		else
			break
		end
	end
	if (unit.Level or 1) >= cap then
		unit.XP = 0
	end
	if levelsGained > 0 then
		local stars = unit.Stars or 5
		unit.HP      = statAtLevel(unit.BaseHP      or 0, unit.Level, cap, stars)
		unit.Attack  = statAtLevel(unit.BaseAttack  or 0, unit.Level, cap, stars)
		unit.Defense = statAtLevel(unit.BaseDefense or 0, unit.Level, cap, stars)
	end
	return levelsGained > 0, levelsGained
end

function UnitManager.PowerUp(player, targetId, materialIds)
	local units = playerUnits[player.UserId]
	if not units then return false, "No units" end

	local target
	for _, u in ipairs(units) do
		if u.Id == targetId then
			target = u
			break
		end
	end
	if not target then return false, "Target not found" end

	local cap = MAX_LEVEL_FOR_STARS[target.Stars or 1] or 40
	if (target.Level or 1) >= cap then return false, "Target is max level" end
	if #materialIds > 5 then return false, "Too many materials" end
	if #materialIds == 0 then return false, "No materials selected" end

	local materials = {}
	local usedIds = {}
	for _, mid in ipairs(materialIds) do
		if mid == targetId then return false, "Cannot use target as material" end
		if usedIds[mid] then return false, "Duplicate material" end
		usedIds[mid] = true
		local found = false
		for _, u in ipairs(units) do
			if u.Id == mid then
				table.insert(materials, u)
				found = true
				break
			end
		end
		if not found then return false, "Material not found" end
	end

	local totalExp = 0
	for _, mat in ipairs(materials) do
		totalExp += getMaterialExp(mat.Stars or 1, mat.Level or 1)
	end

	local lucky = math.random() < 0.20
	if lucky then
		totalExp = math.floor(totalExp * 1.5)
	end

	target.XP = (target.XP or 0) + totalExp
	local levelsGained = 0
	while (target.Level or 1) < cap do
		local needed = xpToNextLevel(target.Stars or 1, target.Level or 1)
		if target.XP >= needed then
			target.XP -= needed
			target.Level = (target.Level or 1) + 1
			levelsGained += 1
		else
			break
		end
	end
	if (target.Level or 1) >= cap then
		target.XP = 0
	end
	if levelsGained > 0 then
		local stars = target.Stars or 5
		target.HP      = statAtLevel(target.BaseHP      or 0, target.Level, cap, stars)
		target.Attack  = statAtLevel(target.BaseAttack  or 0, target.Level, cap, stars)
		target.Defense = statAtLevel(target.BaseDefense or 0, target.Level, cap, stars)
	end

	-- Remove materials and re-index remaining units
	local removeSet = {}
	for _, mat in ipairs(materials) do
		removeSet[mat.Id] = true
	end
	local newUnits = {}
	local nextId = 1
	for _, u in ipairs(units) do
		if not removeSet[u.Id] then
			u.Id = nextId
			nextId += 1
			table.insert(newUnits, u)
		end
	end
	playerUnits[player.UserId] = newUnits

	return true, {
		gainedExp    = totalExp,
		lucky        = lucky,
		levelsGained = levelsGained,
		newLevel     = target.Level,
		stars        = target.Stars,
	}
end

function UnitManager.RemoveUnit(player, unitId)
	if not player or not player.UserId then return false end
	local units = playerUnits[player.UserId]
	if not units then return false end
	for i, unit in ipairs(units) do
		if unit.Id == unitId then
			table.remove(units, i)
			for j = i, #units do
				units[j].Id = j
			end
			return true
		end
	end
	return false
end

function UnitManager.GetUnits(player)
	if not player or not player.UserId then
		return {}
	end

	local units = playerUnits[player.UserId] or {}
	local copy = {}
	for index, unit in ipairs(units) do
		copy[index] = cloneUnit(unit)
	end
	return copy
end

return UnitManager

local UnitManager = {}
local playerUnits = {}

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
		CharacterName = unit.CharacterName,
		Type = unit.Type,
		Rarity = unit.Rarity,
		Stars = unit.Stars,
		Attack = unit.Attack,
		Defense = unit.Defense,
		CritChance = unit.CritChance,
		CritDamage = unit.CritDamage,
		DisplayName = unit.DisplayName,
		Level = unit.Level or 1,
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
	local entry = {
		Id = #units + 1,
		CharacterName = charName,
		Type = unitData.Type or "Neutral",
		Rarity = unitData.Rarity or "Common",
		Stars = unitData.Stars or 1,
		Attack = unitData.Attack or 0,
		Defense = unitData.Defense or 0,
		CritChance = unitData.CritChance or 0,
		CritDamage = unitData.CritDamage or 1.5,
		DisplayName = unitData.DisplayName or unitData.CharacterName or unitData.Name or "Unknown",
		Level = unitData.Level or 1,
		HP = unitData.HP or 0,
		Speed = unitData.Speed or 0,
		Resistance = unitData.Resistance or 0,
		Accuracy = unitData.Accuracy or 0,
		Abilities = UNIT_ABILITIES[charName] or {},
	}

	table.insert(units, entry)
	return entry
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

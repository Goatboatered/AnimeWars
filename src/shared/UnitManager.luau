local UnitManager = {}
local playerUnits = {}

local function cloneUnit(unit)
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

	local entry = {
		Id = #units + 1,
		CharacterName = unitData.CharacterName or unitData.Name or "Unknown",
		Type = unitData.Type or "Neutral",
		Rarity = unitData.Rarity or "Common",
		Stars = unitData.Stars or 1,
		Attack = unitData.Attack or 0,
		Defense = unitData.Defense or 0,
		CritChance = unitData.CritChance or 0,
		CritDamage = unitData.CritDamage or 1.5,
		DisplayName = unitData.DisplayName or unitData.CharacterName or unitData.Name or "Unknown",
	}

	table.insert(units, entry)
	return entry
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

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterPool = require(ReplicatedStorage.Shared:WaitForChild("CharacterPool"))

local GachaLibrary = {}
local random = Random.new()

local advantageChart = {
	Fire = { Wind = true },
	Water = { Fire = true },
	Wind = { Water = true },
	Light = { Dark = true },
	Dark = { Light = true },
}

function GachaLibrary.HasElementAdvantage(attackerType, defenderType)
	if attackerType == defenderType then
		return false
	end

	local attackerRow = advantageChart[attackerType]
	return attackerRow and attackerRow[defenderType] or false
end

function GachaLibrary.GetTypeHitModifiers(attackerType, defenderType)
	if GachaLibrary.HasElementAdvantage(attackerType, defenderType) then
		return { critRateBonus = 0.15, crushingChance = 0.15, glancingChance = 0 }
	elseif GachaLibrary.HasElementAdvantage(defenderType, attackerType) then
		return { critRateBonus = -0.15, crushingChance = 0, glancingChance = 0.50 }
	end
	return { critRateBonus = 0, crushingChance = 0, glancingChance = 0 }
end

function GachaLibrary.CalculateDamage(
	baseDamage,
	attackerType,
	defenderType,
	critChance,
	critDamageMultiplier,
	defenseMultiplier
)
	critChance = critChance or 0
	critDamageMultiplier = critDamageMultiplier or 1.5
	defenseMultiplier = defenseMultiplier or 1

	local modifiers       = GachaLibrary.GetTypeHitModifiers(attackerType, defenderType)
	local totalCritChance = math.clamp(critChance + modifiers.critRateBonus, 0, 1)
	local damage          = baseDamage * defenseMultiplier
	local hitType         = "Normal"

	-- SW hit order: Glancing → Crit → Crushing → Normal
	-- Each is an independent roll so they are truly mutually exclusive
	if modifiers.glancingChance > 0 and random:NextNumber() < modifiers.glancingChance then
		hitType = "Glancing"
		damage *= 0.7
	elseif random:NextNumber() < totalCritChance then
		hitType = "Critical"
		damage *= critDamageMultiplier
	elseif modifiers.crushingChance > 0 and random:NextNumber() < modifiers.crushingChance then
		hitType = "Crushing"
		damage *= 1.3
	end

	return damage, hitType
end

function GachaLibrary.PickFromPool(poolName)
	local pool = CharacterPool.GetPool(poolName)
	local totalWeight = 0

	for _, entry in ipairs(pool) do
		totalWeight += entry.Weight
	end

	local roll = random:NextNumber() * totalWeight
	local cumulative = 0

	for _, entry in ipairs(pool) do
		cumulative += entry.Weight
		if roll <= cumulative then
			return entry
		end
	end

	return pool[#pool]
end

function GachaLibrary.FormatResult(entry)
	local element = entry.Type or "Neutral"
	return string.format("%s [%s] (%s, %d★)", entry.Name, element, entry.Rarity, entry.Stars)
end

return GachaLibrary

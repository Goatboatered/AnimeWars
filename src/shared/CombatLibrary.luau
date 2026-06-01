local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GachaLibrary = require(ReplicatedStorage.Shared:WaitForChild("GachaLibrary"))

local CombatLibrary = {}

local function clamp(value, minValue, maxValue)
	if value < minValue then
		return minValue
	elseif value > maxValue then
		return maxValue
	end
	return value
end

local function calculateDefenseMultiplier(attackerAttack, defenderDefense)
	local raw = defenderDefense / (attackerAttack + defenderDefense + 20)
	return clamp(1 - raw, 0.2, 1)
end

function CombatLibrary.CalculateDamageFromStats(attacker, defender)
	if not attacker or not defender then
		return 0, "None", { Reason = "Missing attacker or defender" }
	end

	local baseDamage = attacker.Attack or 10
	local defenseMultiplier = calculateDefenseMultiplier(baseDamage, defender.Defense or 0)
	local critChance = attacker.CritChance or 0
	local critDamageMultiplier = attacker.CritDamage or 1.5

	local damage, hitType = GachaLibrary.CalculateDamage(
		baseDamage,
		attacker.Type,
		defender.Type,
		critChance,
		critDamageMultiplier,
		defenseMultiplier
	)
	local advantage = GachaLibrary.HasElementAdvantage(attacker.Type, defender.Type)

	local details = {
		Attacker = attacker.Name or "Unknown",
		Defender = defender.Name or "Unknown",
		AttackerType = attacker.Type or "Neutral",
		DefenderType = defender.Type or "Neutral",
		BaseDamage = baseDamage,
		DefenseMultiplier = defenseMultiplier,
		CritChance = critChance,
		CritDamageMultiplier = critDamageMultiplier,
		ElementalAdvantage = advantage,
	}

	return damage, hitType, details
end

return CombatLibrary

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GachaLibrary = require(ReplicatedStorage.Shared:WaitForChild("GachaLibrary"))

local CombatLibrary = {}

local DEF_CONSTANT = 1000

local function calculateDefenseMultiplier(defenderDefense)
	-- SW-standard: higher DEF asymptotically reduces damage toward 0
	-- DEF 500 → 67% through, DEF 1000 → 50%, DEF 2000 → 33%
	return DEF_CONSTANT / (DEF_CONSTANT + defenderDefense)
end

function CombatLibrary.CalculateDamageFromStats(attacker, defender)
	if not attacker or not defender then
		return 0, "None", { Reason = "Missing attacker or defender" }
	end

	local baseDamage = attacker.Attack or 10
	local defenseMultiplier = calculateDefenseMultiplier(defender.Defense or 0)
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

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GachaLibrary = require(Shared:WaitForChild("GachaLibrary"))
local CombatLibrary = require(Shared:WaitForChild("CombatLibrary"))

local remoteFolder = ReplicatedStorage:FindFirstChild("GachaRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "GachaRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local summonRequest = remoteFolder:FindFirstChild("SummonRequest")
if not summonRequest then
	summonRequest = Instance.new("RemoteFunction")
	summonRequest.Name = "SummonRequest"
	summonRequest.Parent = remoteFolder
end

local attackRequest = remoteFolder:FindFirstChild("AttackRequest")
if not attackRequest then
	attackRequest = Instance.new("RemoteFunction")
	attackRequest.Name = "AttackRequest"
	attackRequest.Parent = remoteFolder
end

function summonRequest.OnServerInvoke(_player)
	local result = GachaLibrary.PickFromPool("normal")
	return {
		CharacterName = result.Name,
		Type = result.Type,
		Rarity = result.Rarity,
		Stars = result.Stars,
		Attack = result.Attack,
		Defense = result.Defense,
		CritChance = result.CritChance,
		CritDamage = result.CritDamage,
		DisplayName = GachaLibrary.FormatResult(result),
	}
end

function attackRequest.OnServerInvoke(_player, attackerData, defenderData)
	local damage, hitType, details = CombatLibrary.CalculateDamageFromStats(attackerData, defenderData)
	return {
		Damage = damage,
		HitType = hitType,
		Details = details,
	}
end

print("Gacha and combat server ready")

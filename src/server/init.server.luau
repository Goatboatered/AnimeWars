local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GachaLibrary = require(Shared:WaitForChild("GachaLibrary"))
local CombatLibrary = require(Shared:WaitForChild("CombatLibrary"))
local UnitManager = require(Shared:WaitForChild("UnitManager"))
local FollowerManager = require(script.Parent:WaitForChild("FollowerManager"))

-- Ensure the engine runs the server-side modules that create shared remotes
require(script:WaitForChild("UnitManager"))
require(script:WaitForChild("HubServer"))

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

local unitsUpdated = remoteFolder:FindFirstChild("UnitsUpdated")
if not unitsUpdated then
	unitsUpdated = Instance.new("RemoteEvent")
	unitsUpdated.Name = "UnitsUpdated"
	unitsUpdated.Parent = remoteFolder
end

local attackRequest = remoteFolder:FindFirstChild("AttackRequest")
if not attackRequest then
	attackRequest = Instance.new("RemoteFunction")
	attackRequest.Name = "AttackRequest"
	attackRequest.Parent = remoteFolder
end

function summonRequest.OnServerInvoke(_player)
	local result = GachaLibrary.PickFromPool("normal")
	local payload = {
		SourceId = result.SourceId,
		CharacterName = result.Name,
		Type = result.Type,
		Rarity = result.Rarity,
		Stars = result.Stars,
		AwakenLevel = result.AwakenLevel or 0,
		AwakenBonus = result.AwakenBonus or "",
		Attack = result.Attack,
		Defense = result.Defense,
		CritChance = result.CritChance,
		CritDamage = result.CritDamage,
		Abilities = result.Abilities or {},
		DisplayName = GachaLibrary.FormatResult(result),
	}

	UnitManager.AddUnit(_player, payload)
	FollowerManager.ClearFollowers(_player)
	unitsUpdated:FireClient(_player, UnitManager.GetUnits(_player))
	return payload
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

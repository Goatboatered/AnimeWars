local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GachaLibrary = require(Shared:WaitForChild("GachaLibrary"))
local UnitManager = require(Shared:WaitForChild("UnitManager"))
local FollowerManager = require(script.Parent:WaitForChild("FollowerManager"))

local remoteFolder = ReplicatedStorage:FindFirstChild("GachaRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "GachaRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local function ensureRemote(name, className)
	local obj = remoteFolder:FindFirstChild(name)
	if not obj then
		obj = Instance.new(className)
		obj.Name = name
		obj.Parent = remoteFolder
	end
	return obj
end

local summonRequest = ensureRemote("SummonRequest", "RemoteFunction")
local getUnits = ensureRemote("GetUnits", "RemoteFunction")
local summonResult = ensureRemote("SummonResult", "RemoteEvent")
local unitsUpdated = ensureRemote("UnitsUpdated", "RemoteEvent")
local attackRequest = ensureRemote("AttackRequest", "RemoteFunction")

function summonRequest.OnServerInvoke(player)
	if not player then
		return nil
	end

	local result = GachaLibrary.PickFromPool("normal")
	local payload = {
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

	UnitManager.AddUnit(player, payload)
	unitsUpdated:FireClient(player, UnitManager.GetUnits(player))
	FollowerManager.SpawnFollower(player)
	return payload
end

function getUnits.OnServerInvoke(player)
	if not player then
		return {}
	end
	return UnitManager.GetUnits(player)
end

function attackRequest.OnServerInvoke(player, attackerData, defenderData)
	local CombatLibrary = require(Shared:WaitForChild("CombatLibrary"))
	local damage, hitType, details = CombatLibrary.CalculateDamageFromStats(attackerData, defenderData)
	return {
		Damage = damage,
		HitType = hitType,
		Details = details,
	}
end

print("RemoteSetup: GachaRemotes initialized")

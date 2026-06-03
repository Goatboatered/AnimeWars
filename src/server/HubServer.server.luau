local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GachaLibrary = require(Shared:WaitForChild("GachaLibrary"))
local UnitManager = require(Shared:WaitForChild("UnitManager"))
local FollowerManager = require(script.Parent:WaitForChild("FollowerManager"))

local StarterPackStore = nil
pcall(function()
	StarterPackStore = DataStoreService:GetDataStore("StarterClaim_v1")
end)
local claimedPacks = {}

local STARTER_UNITS = {
	{ Name = "Water Fairy",   DisplayName = "Water Fairy",   Type = "Water", Rarity = "Rare",   Stars = 3, HP = 1815, Attack = 107, Defense = 136, Speed = 103, CritChance = 0.15, CritDamage = 1.5, Resistance = 0.15, Accuracy = 0.0 },
	{ Name = "Fire Hellhound", DisplayName = "Fire Hellhound", Type = "Fire",  Rarity = "Common", Stars = 2, HP = 1725, Attack = 227, Defense = 112, Speed = 115, CritChance = 0.15, CritDamage = 1.5, Resistance = 0.15, Accuracy = 0.0 },
	{ Name = "Wind Vagabond", DisplayName = "Wind Vagabond", Type = "Wind",  Rarity = "Common", Stars = 2, HP = 1905, Attack = 117, Defense = 134, Speed = 97, CritChance = 0.15, CritDamage = 1.5, Resistance = 0.15, Accuracy = 0.0 },
}

local remoteFolder = ReplicatedStorage:FindFirstChild("GachaRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "GachaRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local summonResult = remoteFolder:FindFirstChild("SummonResult")
if not summonResult then
	summonResult = Instance.new("RemoteEvent")
	summonResult.Name = "SummonResult"
	summonResult.Parent = remoteFolder
end

local summonRequest = remoteFolder:FindFirstChild("SummonRequest")
if not summonRequest then
	summonRequest = Instance.new("RemoteFunction")
	summonRequest.Name = "SummonRequest"
	summonRequest.Parent = remoteFolder
end

local getUnits = remoteFolder:FindFirstChild("GetUnits")
if not getUnits then
	getUnits = Instance.new("RemoteFunction")
	getUnits.Name = "GetUnits"
	getUnits.Parent = remoteFolder
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

local mailStatus = remoteFolder:FindFirstChild("MailStatus")
if not mailStatus then
	mailStatus = Instance.new("RemoteFunction")
	mailStatus.Name = "MailStatus"
	mailStatus.Parent = remoteFolder
end

local claimStarterPack = remoteFolder:FindFirstChild("ClaimStarterPack")
if not claimStarterPack then
	claimStarterPack = Instance.new("RemoteFunction")
	claimStarterPack.Name = "ClaimStarterPack"
	claimStarterPack.Parent = remoteFolder
end

local deleteUnit = remoteFolder:FindFirstChild("DeleteUnit")
if not deleteUnit then
	deleteUnit = Instance.new("RemoteFunction")
	deleteUnit.Name = "DeleteUnit"
	deleteUnit.Parent = remoteFolder
end

local displayUnit = remoteFolder:FindFirstChild("DisplayUnit")
if not displayUnit then
	displayUnit = Instance.new("RemoteEvent")
	displayUnit.Name = "DisplayUnit"
	displayUnit.Parent = remoteFolder
end

displayUnit.OnServerEvent:Connect(function(player, unitType, displayName, unitId)
	FollowerManager.SpawnFollower(player, unitType, displayName, unitId)
end)

local undisplayUnit = remoteFolder:FindFirstChild("UndisplayUnit")
if not undisplayUnit then
	undisplayUnit = Instance.new("RemoteEvent")
	undisplayUnit.Name = "UndisplayUnit"
	undisplayUnit.Parent = remoteFolder
end

undisplayUnit.OnServerEvent:Connect(function(player, unitId)
	FollowerManager.RemoveFollower(player, unitId)
end)

Players.PlayerAdded:Connect(function(player)
	UnitManager.InitializePlayer(player)
	local success, claimed = pcall(function()
		return StarterPackStore:GetAsync("starterClaim_" .. player.UserId)
	end)
	claimedPacks[player.UserId] = success and claimed == true
end)

Players.PlayerRemoving:Connect(function(player)
	UnitManager.ClearPlayer(player)
	claimedPacks[player.UserId] = nil
end)

for _, player in Players:GetPlayers() do
	UnitManager.InitializePlayer(player)
	local success, claimed = pcall(function()
		return StarterPackStore:GetAsync("starterClaim_" .. player.UserId)
	end)
	claimedPacks[player.UserId] = success and claimed == true
end

function mailStatus.OnServerInvoke(player)
	return { starterPackClaimed = claimedPacks[player.UserId] == true }
end

function claimStarterPack.OnServerInvoke(player)
	if claimedPacks[player.UserId] == true then
		return false
	end

	for _, unitData in ipairs(STARTER_UNITS) do
		UnitManager.AddUnit(player, unitData)
	end

	claimedPacks[player.UserId] = true
	pcall(function()
		StarterPackStore:SetAsync("starterClaim_" .. player.UserId, true)
	end)

	unitsUpdated:FireClient(player, UnitManager.GetUnits(player))
	return true
end

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

function deleteUnit.OnServerInvoke(player, unitId)
	local removed = UnitManager.RemoveUnit(player, unitId)
	if removed then
		unitsUpdated:FireClient(player, UnitManager.GetUnits(player))
	end
	return removed
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

local function createFountain()
	local hub = Workspace:FindFirstChild("SummoningHub")
	if not hub then
		hub = Instance.new("Model")
		hub.Name = "SummoningHub"
		hub.Parent = Workspace
	end

	local ground = hub:FindFirstChild("HubGround")
	if not ground then
		ground = Instance.new("Part")
		ground.Name = "HubGround"
		ground.Anchored = true
		ground.CanCollide = true
		ground.Size = Vector3.new(120, 2, 120)
		ground.Position = Vector3.new(0, 1, 0)
		ground.Material = Enum.Material.Slate
		ground.Color = Color3.fromRGB(40, 40, 60)
		ground.Parent = hub
	end

	local floor = hub:FindFirstChild("HubFloor")
	if not floor then
		floor = Instance.new("Part")
		floor.Name = "HubFloor"
		floor.Anchored = true
		floor.CanCollide = true
		floor.Size = Vector3.new(108, 1, 108)
		floor.Position = Vector3.new(0, 2.5, 0)
		floor.Material = Enum.Material.Brick
		floor.Color = Color3.fromRGB(75, 75, 95)
		floor.TopSurface = Enum.SurfaceType.Smooth
		floor.BottomSurface = Enum.SurfaceType.Smooth
		floor.Parent = hub
	end

	local function makePillar(name, position)
		local pillar = hub:FindFirstChild(name)
		if not pillar then
			pillar = Instance.new("Part")
			pillar.Name = name
			pillar.Anchored = true
			pillar.CanCollide = true
			pillar.Size = Vector3.new(4, 24, 4)
			pillar.Position = position
			pillar.Material = Enum.Material.Concrete
			pillar.Color = Color3.fromRGB(90, 90, 120)
			pillar.Parent = hub

			local cap = Instance.new("Part")
			cap.Name = name .. "Cap"
			cap.Anchored = true
			cap.CanCollide = false
			cap.Size = Vector3.new(5, 2, 5)
			cap.Position = position + Vector3.new(0, 13, 0)
			cap.Material = Enum.Material.Neon
			cap.Color = Color3.fromRGB(100, 180, 255)
			cap.Parent = hub

			local light = Instance.new("PointLight")
			light.Brightness = 2.5
			light.Range = 18
			light.Color = Color3.fromRGB(140, 210, 255)
			light.Parent = cap
		end
	end

	makePillar("PillarNorth", Vector3.new(0, 14, -30))
	makePillar("PillarSouth", Vector3.new(0, 14, 30))
	makePillar("PillarEast", Vector3.new(30, 14, 0))
	makePillar("PillarWest", Vector3.new(-30, 14, 0))

	local fountainBase = hub:FindFirstChild("FountainBase")
	if not fountainBase then
		fountainBase = Instance.new("Part")
		fountainBase.Name = "FountainBase"
		fountainBase.Anchored = true
		fountainBase.CanCollide = true
		fountainBase.Size = Vector3.new(30, 1, 30)
		fountainBase.Position = Vector3.new(0, 3, 0)
		fountainBase.Material = Enum.Material.Slate
		fountainBase.Color = Color3.fromRGB(55, 60, 90)
		fountainBase.Parent = hub
	end

	local fountainRing = hub:FindFirstChild("FountainRing")
	if not fountainRing then
		fountainRing = Instance.new("Part")
		fountainRing.Name = "FountainRing"
		fountainRing.Anchored = true
		fountainRing.CanCollide = true
		fountainRing.Size = Vector3.new(22, 2, 22)
		fountainRing.Position = Vector3.new(0, 5.5, 0)
		fountainRing.Material = Enum.Material.Neon
		fountainRing.Color = Color3.fromRGB(100, 170, 255)
		fountainRing.Shape = Enum.PartType.Cylinder
		fountainRing.Orientation = Vector3.new(0, 0, 90)
		fountainRing.Parent = hub
	end

	local core = hub:FindFirstChild("FountainCore")
	if not core then
		core = Instance.new("Part")
		core.Name = "FountainCore"
		core.Anchored = true
		core.CanCollide = false
		core.Size = Vector3.new(8, 8, 8)
		core.Position = Vector3.new(0, 9.5, 0)
		core.Material = Enum.Material.Neon
		core.Color = Color3.fromRGB(150, 220, 255)
		core.Shape = Enum.PartType.Ball
		core.Parent = hub
	end

	local light = core:FindFirstChildOfClass("PointLight")
	if not light then
		light = Instance.new("PointLight")
		light.Brightness = 5
		light.Range = 24
		light.Color = Color3.fromRGB(190, 235, 255)
		light.Parent = core
	end

	local prompt = core:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Summon"
		prompt.ObjectText = "Summoning Fountain"
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = core
	end

	local billboard = core:FindFirstChild("FountainLabel")
	if not billboard then
		billboard = Instance.new("BillboardGui")
		billboard.Name = "FountainLabel"
		billboard.Size = UDim2.fromOffset(240, 48)
		billboard.AlwaysOnTop = true
		billboard.StudsOffset = Vector3.new(0, 5.5, 0)
		billboard.Parent = core

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextStrokeTransparency = 0.4
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Text = "Summoning Fountain"
		label.Parent = billboard
	end

	prompt.Triggered:Connect(function(player)
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
		summonResult:FireClient(player, payload)
		print(player.Name .. " summoned " .. payload.DisplayName)
	end)
end

createFountain()
print("Summoning hub created")

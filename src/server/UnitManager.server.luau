local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UnitManager = require(Shared:WaitForChild("UnitManager"))

local remoteFolder = ReplicatedStorage:FindFirstChild("GachaRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "GachaRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local unitRequest = remoteFolder:FindFirstChild("GetUnits")
if not unitRequest then
	unitRequest = Instance.new("RemoteFunction")
	unitRequest.Name = "GetUnits"
	unitRequest.Parent = remoteFolder
end

local unitUpdated = remoteFolder:FindFirstChild("UnitsUpdated")
if not unitUpdated then
	unitUpdated = Instance.new("RemoteEvent")
	unitUpdated.Name = "UnitsUpdated"
	unitUpdated.Parent = remoteFolder
end

Players.PlayerAdded:Connect(function(player)
	UnitManager.InitializePlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	UnitManager.ClearPlayer(player)
end)

function unitRequest.OnServerInvoke(player)
	return UnitManager.GetUnits(player)
end

local function broadcastUpdate(player)
	if player and player:IsDescendantOf(game) then
		unitUpdated:FireClient(player, UnitManager.GetUnits(player))
	end
end

return {
	BroadcastUpdate = broadcastUpdate,
}

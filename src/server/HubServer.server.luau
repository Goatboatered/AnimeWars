-- !! FILL THIS IN after creating places in Roblox Studio !!
local COMBAT_PLACE_ID = 116576186647526

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GachaLibrary  = require(Shared:WaitForChild("GachaLibrary"))
local CharacterPool = require(Shared:WaitForChild("CharacterPool"))
local UnitManager   = require(Shared:WaitForChild("UnitManager"))
local FollowerManager = require(script.Parent:WaitForChild("FollowerManager"))
local CurrencyManager = require(script.Parent:WaitForChild("CurrencyManager"))

-- Mana Stones awarded per level gained (by star grade), matching SW economy scaling
local MANA_PER_LEVEL = {[1]=100,[2]=250,[3]=500,[4]=1000,[5]=2000,[6]=5000}

local StarterPackStore = nil
pcall(function()
	StarterPackStore = DataStoreService:GetDataStore("StarterClaim_v1")
end)
local UnitInventoryStore = nil
pcall(function()
	UnitInventoryStore = DataStoreService:GetDataStore("UnitInventory_v1")
end)
local CurrencyStore = nil
pcall(function()
	CurrencyStore = DataStoreService:GetDataStore("Currency_v1")
end)

local claimedPacks        = {}
local loadedUnitData      = {}
local loadedCurrencyData  = {}

local STARTER_UNITS = {
	{ Name = "Water Fairy",    DisplayName = "Water Fairy",    Type = "Water", Rarity = "Rare",   Stars = 3, HP = 1815, Attack = 107, Defense = 136, Speed = 103, CritChance = 0.15, CritDamage = 1.5, Resistance = 0.15, Accuracy = 0.0 },
	{ Name = "Fire Hellhound", DisplayName = "Fire Hellhound", Type = "Fire",  Rarity = "Common", Stars = 2, HP = 1725, Attack = 227, Defense = 112, Speed = 115, CritChance = 0.15, CritDamage = 1.5, Resistance = 0.15, Accuracy = 0.0 },
	{ Name = "Wind Vagabond",  DisplayName = "Wind Vagabond",  Type = "Wind",  Rarity = "Common", Stars = 2, HP = 1905, Attack = 117, Defense = 134, Speed = 97,  CritChance = 0.15, CritDamage = 1.5, Resistance = 0.15, Accuracy = 0.0 },
}


local NEW_PLAYER_MANASTONES   = 1500
local NEW_PLAYER_CRYSTALS     = 10
local STARTER_PACK_MANASTONES = 3000
local STARTER_PACK_CRYSTALS   = 30

-- ─── UNIT PERSISTENCE ─────────────────────────────────────────────────

-- Repairs units saved before HP/Speed were in CharacterPool.
-- Primary lookup is by SourceId; fallback is by CharacterName+Type+AwakenLevel
-- for old saves that predate SourceId tracking.
local poolBySourceId = nil
local poolByNameKey  = nil

local function buildRepairLookups()
	poolBySourceId = {}
	poolByNameKey  = {}
	for _, entry in ipairs(CharacterPool.GetPool("normal")) do
		if entry.SourceId then
			poolBySourceId[entry.SourceId] = entry
		end
		if entry.Name then
			local key = entry.Name .. "|" .. (entry.Type or "") .. "|" .. tostring(entry.AwakenLevel or 0)
			poolByNameKey[key] = poolByNameKey[key] or entry
		end
	end
end

local function repairUnitData(units)
	if type(units) ~= "table" then return units end
	if not poolBySourceId then
		buildRepairLookups()
	end
	for _, unit in ipairs(units) do
		if type(unit) ~= "table" then
			continue
		end
		local source = unit.SourceId and poolBySourceId[unit.SourceId]
		if not source then
			local key = (unit.CharacterName or "") .. "|" .. (unit.Type or "") .. "|" .. tostring(unit.AwakenLevel or 0)
			source = poolByNameKey[key]
		end
		if not source then continue end
		if (unit.HP == nil or unit.HP == 0) and (source.HP or 0) > 0 then
			unit.HP     = source.HP
			unit.BaseHP = nil
		end
		if (unit.Speed == nil or unit.Speed == 0) and (source.Speed or 0) > 0 then
			unit.Speed = source.Speed
		end
	end
	return units
end

local function unitStoreKey(player)
	return "units_" .. player.UserId
end

local function loadUnitData(player)
	UnitManager.InitializePlayer(player)

	if not UnitInventoryStore then
		loadedUnitData[player.UserId] = false
		warn("[HubServer] UnitInventoryStore unavailable; units will not persist for", player.Name)
		return
	end

	local success, data = pcall(function()
		return UnitInventoryStore:GetAsync(unitStoreKey(player))
	end)

	if not success then
		loadedUnitData[player.UserId] = false
		warn("[HubServer] Failed to load units for", player.Name, data)
		return
	end

	if type(data) == "table" and type(data.units) == "table" then
		UnitManager.SetUnits(player, repairUnitData(data.units))
	elseif type(data) == "table" then
		UnitManager.SetUnits(player, repairUnitData(data))
	end

	loadedUnitData[player.UserId] = true
	print("[HubServer] Loaded", #UnitManager.GetUnits(player), "unit(s) for", player.Name)
end

local function saveUnitData(player, reason)
	if not player or not player.UserId then return false end
	if not UnitInventoryStore then return false end
	if loadedUnitData[player.UserId] ~= true then
		warn("[HubServer] Skipped unit save because inventory was not loaded for", player.Name, reason or "")
		return false
	end

	local payload = {
		version   = 1,
		updatedAt = os.time(),
		units     = UnitManager.GetUnits(player),
	}

	local success, err = pcall(function()
		UnitInventoryStore:SetAsync(unitStoreKey(player), payload)
	end)

	if not success then
		warn("[HubServer] Failed to save units for", player.Name, reason or "", err)
		return false
	end

	print("[HubServer] Saved", #payload.units, "unit(s) for", player.Name, reason or "")
	return true
end

local function canMutateUnits(player)
	if UnitInventoryStore and loadedUnitData[player.UserId] ~= true then
		warn("[HubServer] Unit mutation rejected because inventory was not loaded for", player.Name)
		return false
	end
	return true
end

-- ─── CURRENCY PERSISTENCE ─────────────────────────────────────────────

local function loadCurrencyData(player)
	CurrencyManager.InitializePlayer(player)

	if not CurrencyStore then
		loadedCurrencyData[player.UserId] = false
		warn("[HubServer] CurrencyStore unavailable; currencies will not persist for", player.Name)
		return
	end

	local success, data = pcall(function()
		return CurrencyStore:GetAsync("currency_" .. player.UserId)
	end)

	if not success then
		loadedCurrencyData[player.UserId] = false
		warn("[HubServer] Failed to load currencies for", player.Name, data)
		return
	end

	if type(data) == "table" then
		CurrencyManager.SetCurrencies(player, data)
	else
		-- New player: grant starting currencies
		CurrencyManager.SetCurrencies(player, { manastones = NEW_PLAYER_MANASTONES, crystals = NEW_PLAYER_CRYSTALS })
	end

	loadedCurrencyData[player.UserId] = true
	local curr = CurrencyManager.GetCurrencies(player)
	print("[HubServer] Loaded currencies for", player.Name, "— MS:", curr.manastones, "CRY:", curr.crystals)
end

local function saveCurrencyData(player, reason)
	if not player or not player.UserId then return false end
	if not CurrencyStore then return false end
	if loadedCurrencyData[player.UserId] ~= true then
		warn("[HubServer] Skipped currency save because data was not loaded for", player.Name, reason or "")
		return false
	end

	local payload = CurrencyManager.GetCurrencies(player)

	local success, err = pcall(function()
		CurrencyStore:SetAsync("currency_" .. player.UserId, payload)
	end)

	if not success then
		warn("[HubServer] Failed to save currencies for", player.Name, reason or "", err)
		return false
	end

	return true
end

-- ─── REMOTES ──────────────────────────────────────────────────────────

local remoteFolder = ReplicatedStorage:FindFirstChild("GachaRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "GachaRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local function ensureEvent(name)
	local r = remoteFolder:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = remoteFolder
	end
	return r
end

local function ensureFunction(name)
	local r = remoteFolder:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteFunction")
		r.Name = name
		r.Parent = remoteFolder
	end
	return r
end

ensureEvent("SummonResult") -- client listens to this; kept so WaitForChild doesn't hang
local powerUp           = ensureFunction("PowerUp")
local summonRequest     = ensureFunction("SummonRequest")
local getUnits          = ensureFunction("GetUnits")
local unitsUpdated      = ensureEvent("UnitsUpdated")
local attackRequest     = ensureFunction("AttackRequest")
local mailStatus        = ensureFunction("MailStatus")
local claimStarterPack  = ensureFunction("ClaimStarterPack")
local deleteUnit        = ensureFunction("DeleteUnit")
local beginBattle       = ensureEvent("BeginBattle")
local beginBattleResult = ensureEvent("BeginBattleResult")
local getCurrencies     = ensureFunction("GetCurrencies")
local currenciesUpdated = ensureEvent("CurrenciesUpdated")
local displayUnit       = ensureEvent("DisplayUnit")
local undisplayUnit     = ensureEvent("UndisplayUnit")

displayUnit.OnServerEvent:Connect(function(player, unitType, displayName, unitId)
	FollowerManager.SpawnFollower(player, unitType, displayName, unitId)
end)

undisplayUnit.OnServerEvent:Connect(function(player, unitId)
	FollowerManager.RemoveFollower(player, unitId)
end)

-- ─── PLAYER LIFECYCLE ─────────────────────────────────────────────────

Players.PlayerAdded:Connect(function(player)
	loadUnitData(player)
	loadCurrencyData(player)
	local success, claimed = pcall(function()
		return StarterPackStore:GetAsync("starterClaim_" .. player.UserId)
	end)
	claimedPacks[player.UserId] = success and claimed == true
end)

Players.PlayerRemoving:Connect(function(player)
	saveUnitData(player, "player leaving")
	saveCurrencyData(player, "player leaving")
	UnitManager.ClearPlayer(player)
	CurrencyManager.ClearPlayer(player)
	claimedPacks[player.UserId]       = nil
	loadedUnitData[player.UserId]     = nil
	loadedCurrencyData[player.UserId] = nil
end)

for _, player in Players:GetPlayers() do
	loadUnitData(player)
	loadCurrencyData(player)
	local success, claimed = pcall(function()
		return StarterPackStore:GetAsync("starterClaim_" .. player.UserId)
	end)
	claimedPacks[player.UserId] = success and claimed == true
end

-- ─── REMOTE HANDLERS ──────────────────────────────────────────────────

function mailStatus.OnServerInvoke(player)
	return { starterPackClaimed = claimedPacks[player.UserId] == true }
end

function claimStarterPack.OnServerInvoke(player)
	if claimedPacks[player.UserId] == true then return false end
	if not canMutateUnits(player) then return false end

	local beforeUnits = UnitManager.GetUnits(player)
	for _, unitData in ipairs(STARTER_UNITS) do
		UnitManager.AddUnit(player, unitData)
	end
	if UnitInventoryStore and not saveUnitData(player, "starter pack claimed") then
		UnitManager.SetUnits(player, beforeUnits)
		return false
	end

	claimedPacks[player.UserId] = true
	pcall(function()
		StarterPackStore:SetAsync("starterClaim_" .. player.UserId, true)
	end)

	if loadedCurrencyData[player.UserId] == true then
		CurrencyManager.AddCurrency(player, "manastones", STARTER_PACK_MANASTONES)
		CurrencyManager.AddCurrency(player, "crystals",   STARTER_PACK_CRYSTALS)
		saveCurrencyData(player, "starter pack")
		currenciesUpdated:FireClient(player, CurrencyManager.GetCurrencies(player))
	end

	unitsUpdated:FireClient(player, UnitManager.GetUnits(player))
	return true
end

-- Shared summon logic used by both SummonRequest and the fountain ProximityPrompt.
local function doSummon(player)
	if not canMutateUnits(player) then
		return nil, "Server error. Try again."
	end
	local result = GachaLibrary.PickFromPool("normal")
	local payload = {
		SourceId      = result.SourceId,
		CharacterName = result.Name,
		Type          = result.Type,
		Rarity        = result.Rarity,
		Stars         = result.Stars,
		AwakenLevel   = result.AwakenLevel or 0,
		AwakenBonus   = result.AwakenBonus or "",
		Attack        = result.Attack,
		Defense       = result.Defense,
		HP            = result.HP or 0,
		Speed         = result.Speed or 0,
		CritChance    = result.CritChance,
		CritDamage    = result.CritDamage,
		Resistance    = result.Resistance or 0,
		Accuracy      = result.Accuracy or 0,
		Abilities     = result.Abilities or {},
		DisplayName   = GachaLibrary.FormatResult(result),
	}

	local beforeUnits = UnitManager.GetUnits(player)
	UnitManager.AddUnit(player, payload)
	if UnitInventoryStore and not saveUnitData(player, "summon") then
		UnitManager.SetUnits(player, beforeUnits)
		return nil, "Save failed. Try again."
	end

	saveCurrencyData(player, "summon")
	FollowerManager.ClearFollowers(player)
	unitsUpdated:FireClient(player, UnitManager.GetUnits(player))
	currenciesUpdated:FireClient(player, CurrencyManager.GetCurrencies(player))
	return payload, nil
end

function summonRequest.OnServerInvoke(player)
	if not player then return nil end
	local payload, err = doSummon(player)
	if err then return { error = err } end
	return payload
end

function getUnits.OnServerInvoke(player)
	if not player then return {} end
	return UnitManager.GetUnits(player)
end

function getCurrencies.OnServerInvoke(player)
	if not player then return { manastones = 0, crystals = 0 } end
	return CurrencyManager.GetCurrencies(player)
end

function deleteUnit.OnServerInvoke(player, unitId)
	if not canMutateUnits(player) then return false end

	local beforeUnits = UnitManager.GetUnits(player)
	local removed = UnitManager.RemoveUnit(player, unitId)
	if removed then
		if UnitInventoryStore and not saveUnitData(player, "delete unit") then
			UnitManager.SetUnits(player, beforeUnits)
			return false
		end
		unitsUpdated:FireClient(player, UnitManager.GetUnits(player))
	end
	return removed
end

function powerUp.OnServerInvoke(player, targetId, materialIds)
	if type(targetId) ~= "number" then return false, "Invalid target" end
	if type(materialIds) ~= "table" then return false, "Invalid materials" end
	if not canMutateUnits(player) then return false, "Cannot mutate units" end

	local beforeUnits = UnitManager.GetUnits(player)
	local success, result = UnitManager.PowerUp(player, targetId, materialIds)
	if not success then return false, result end

	if UnitInventoryStore and not saveUnitData(player, "power up") then
		UnitManager.SetUnits(player, beforeUnits)
		return false, "Save failed"
	end
	unitsUpdated:FireClient(player, UnitManager.GetUnits(player))

	if result.levelsGained and result.levelsGained > 0 and loadedCurrencyData[player.UserId] == true then
		local msReward = result.levelsGained * (MANA_PER_LEVEL[result.stars or 1] or 100)
		CurrencyManager.AddCurrency(player, "manastones", msReward)
		saveCurrencyData(player, "power up")
		currenciesUpdated:FireClient(player, CurrencyManager.GetCurrencies(player))
	end

	return true, result
end

function attackRequest.OnServerInvoke(_player, attackerData, defenderData)
	local CombatLibrary = require(Shared:WaitForChild("CombatLibrary"))
	local damage, hitType, details = CombatLibrary.CalculateDamageFromStats(attackerData, defenderData)
	return { Damage = damage, HitType = hitType, Details = details }
end

beginBattle.OnServerEvent:Connect(function(player, selectedUnitIds, areaNum, difficulty, stageNum)
	if type(selectedUnitIds) ~= "table" or #selectedUnitIds == 0 then
		warn("[HubServer] BeginBattle rejected: no selected units for", player.Name)
		beginBattleResult:FireClient(player, false, "Select at least one unit first.")
		return
	end

	if COMBAT_PLACE_ID == 0 then
		warn("[HubServer] COMBAT_PLACE_ID not set — cannot teleport")
		beginBattleResult:FireClient(player, false, "Combat place ID is not set.")
		return
	end

	local allUnits = UnitManager.GetUnits(player)
	local selectedUnits = {}
	for _, id in ipairs(selectedUnitIds) do
		for _, unit in ipairs(allUnits) do
			if unit.Id == id then
				table.insert(selectedUnits, unit)
				break
			end
		end
	end
	if #selectedUnits == 0 then
		warn("[HubServer] BeginBattle rejected: selected unit IDs did not match inventory for", player.Name)
		beginBattleResult:FireClient(player, false, "Selected units were not found in your inventory.")
		return
	end

	local unitNames = {}
	for i, unit in ipairs(selectedUnits) do
		unitNames[i] = tostring(unit.DisplayName or unit.CharacterName or unit.Name or unit.Id)
	end
	print("[HubServer] BeginBattle:", player.Name, "area", areaNum or 1, "difficulty", difficulty or "normal", "stage", stageNum or 1, "units", table.concat(unitNames, ", "))

	local ok, result = pcall(function()
		local code = TeleportService:ReserveServer(COMBAT_PLACE_ID)
		local opts = Instance.new("TeleportOptions")
		opts.ReservedServerAccessCode = code
		opts:SetTeleportData({
			selectedUnits = selectedUnits,
			areaNum       = areaNum    or 1,
			difficulty    = difficulty or "normal",
			stage         = stageNum   or 1,
		})
		TeleportService:TeleportAsync(COMBAT_PLACE_ID, { player }, opts)
	end)

	if not ok then
		warn("[HubServer] Teleport failed:", result)
		beginBattleResult:FireClient(player, false, "Teleport failed: " .. tostring(result))
	end
end)

local applyRewards = ensureEvent("ApplyBattleRewards")

-- manastoneReward is optional; combat server can pass it to grant Mana Stones on victory.
applyRewards.OnServerEvent:Connect(function(player, xpRewards, manastoneReward)
	if type(xpRewards) ~= "table" then return end
	if not canMutateUnits(player) then return end

	local beforeUnits = UnitManager.GetUnits(player)
	local allUnits = UnitManager.GetUnits(player)
	local levelUpMS = 0
	for _, unit in ipairs(allUnits) do
		local xp = xpRewards[tostring(unit.Id)]
		if xp and xp > 0 then
			local _, levelsGained = UnitManager.AddXP(player, unit.Id, xp)
			if levelsGained and levelsGained > 0 then
				levelUpMS += levelsGained * (MANA_PER_LEVEL[unit.Stars or 1] or 100)
			end
		end
	end
	if UnitInventoryStore and not saveUnitData(player, "battle rewards") then
		UnitManager.SetUnits(player, beforeUnits)
	end
	unitsUpdated:FireClient(player, UnitManager.GetUnits(player))

	local totalMS = levelUpMS + (type(manastoneReward) == "number" and math.max(0, manastoneReward) or 0)
	if totalMS > 0 and loadedCurrencyData[player.UserId] == true then
		CurrencyManager.AddCurrency(player, "manastones", totalMS)
		saveCurrencyData(player, "battle rewards")
		currenciesUpdated:FireClient(player, CurrencyManager.GetCurrencies(player))
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		saveUnitData(player, "server closing")
		saveCurrencyData(player, "server closing")
	end
end)

-- ─── HUB WORLD ───────────────────────────────────────────────────────

local function createFountain()
	-- Wipe all old geometry saved in the place file (runs before any players join)
	for _, child in ipairs(Workspace:GetChildren()) do
		if not child:IsA("Terrain") and not child:IsA("Camera") then
			child:Destroy()
		end
	end

	local ground = Instance.new("Part")
	ground.Name = "HubGround"
	ground.Anchored = true
	ground.CanCollide = true
	ground.Size = Vector3.new(512, 4, 512)
	ground.Position = Vector3.new(0, 0, 0)
	ground.Material = Enum.Material.Grass
	ground.Color = Color3.fromRGB(106, 127, 63)
	ground.TopSurface = Enum.SurfaceType.Smooth
	ground.BottomSurface = Enum.SurfaceType.Smooth
	ground.Parent = Workspace
end

createFountain()
print("Hub created")

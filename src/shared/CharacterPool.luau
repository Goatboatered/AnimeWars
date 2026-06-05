-- Auto-generated — do not edit by hand.
local CharacterPool = {}

local function buildPool()
	local pool = {}
	local CharacterPool_FireA = require(script.Parent:WaitForChild("CharacterPool_FireA"))
	local CharacterPool_FireB1 = require(script.Parent:WaitForChild("CharacterPool_FireB1"))
	local CharacterPool_FireB2 = require(script.Parent:WaitForChild("CharacterPool_FireB2"))
	local CharacterPool_WaterA = require(script.Parent:WaitForChild("CharacterPool_WaterA"))
	local CharacterPool_WaterB1 = require(script.Parent:WaitForChild("CharacterPool_WaterB1"))
	local CharacterPool_WaterB2 = require(script.Parent:WaitForChild("CharacterPool_WaterB2"))
	local CharacterPool_WindA = require(script.Parent:WaitForChild("CharacterPool_WindA"))
	local CharacterPool_WindB1 = require(script.Parent:WaitForChild("CharacterPool_WindB1"))
	local CharacterPool_WindB2 = require(script.Parent:WaitForChild("CharacterPool_WindB2"))
	local CharacterPool_LightA = require(script.Parent:WaitForChild("CharacterPool_LightA"))
	local CharacterPool_LightB1 = require(script.Parent:WaitForChild("CharacterPool_LightB1"))
	local CharacterPool_LightB2 = require(script.Parent:WaitForChild("CharacterPool_LightB2"))
	local CharacterPool_DarkA = require(script.Parent:WaitForChild("CharacterPool_DarkA"))
	local CharacterPool_DarkB1 = require(script.Parent:WaitForChild("CharacterPool_DarkB1"))
	local CharacterPool_DarkB2 = require(script.Parent:WaitForChild("CharacterPool_DarkB2"))
	for _, v in ipairs(CharacterPool_FireA.entries) do table.insert(pool, v) end
	for _, v in ipairs(CharacterPool_FireB1.entries) do table.insert(pool, v) end
	for _, v in ipairs(CharacterPool_FireB2.entries) do table.insert(pool, v) end
	for _, v in ipairs(CharacterPool_WaterA.entries) do table.insert(pool, v) end
	for _, v in ipairs(CharacterPool_WaterB1.entries) do table.insert(pool, v) end
	for _, v in ipairs(CharacterPool_WaterB2.entries) do table.insert(pool, v) end
	for _, v in ipairs(CharacterPool_WindA.entries) do table.insert(pool, v) end
	for _, v in ipairs(CharacterPool_WindB1.entries) do table.insert(pool, v) end
	for _, v in ipairs(CharacterPool_WindB2.entries) do table.insert(pool, v) end
	for _, v in ipairs(CharacterPool_LightA.entries) do table.insert(pool, v) end
	for _, v in ipairs(CharacterPool_LightB1.entries) do table.insert(pool, v) end
	for _, v in ipairs(CharacterPool_LightB2.entries) do table.insert(pool, v) end
	for _, v in ipairs(CharacterPool_DarkA.entries) do table.insert(pool, v) end
	for _, v in ipairs(CharacterPool_DarkB1.entries) do table.insert(pool, v) end
	for _, v in ipairs(CharacterPool_DarkB2.entries) do table.insert(pool, v) end
	return pool
end

local poolCache = nil

CharacterPool.pools = setmetatable({}, {
	__index = function(_, key)
		if key == "normal" then
			if not poolCache then poolCache = buildPool() end
			return poolCache
		end
		return {}
	end,
})

function CharacterPool.GetPool(poolName)
	return CharacterPool.pools[poolName] or {}
end

return CharacterPool
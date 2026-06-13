local CurrencyManager = {}
local playerCurrencies = {}

function CurrencyManager.InitializePlayer(player)
	if not playerCurrencies[player.UserId] then
		playerCurrencies[player.UserId] = { manastones = 0, crystals = 0 }
	end
end

function CurrencyManager.GetCurrencies(player)
	return playerCurrencies[player.UserId] or { manastones = 0, crystals = 0 }
end

function CurrencyManager.SetCurrencies(player, data)
	playerCurrencies[player.UserId] = {
		manastones = math.max(0, math.floor(tonumber(data.manastones) or 0)),
		crystals   = math.max(0, math.floor(tonumber(data.crystals)   or 0)),
	}
end

function CurrencyManager.AddCurrency(player, currency, amount)
	local curr = playerCurrencies[player.UserId]
	if not curr then return false end
	curr[currency] = math.max(0, (curr[currency] or 0) + math.floor(amount))
	return true
end

-- Returns false if the player can't afford it; deducts and returns true if they can.
function CurrencyManager.SpendCurrency(player, currency, amount)
	local curr = playerCurrencies[player.UserId]
	if not curr then return false end
	if (curr[currency] or 0) < amount then return false end
	curr[currency] = curr[currency] - math.floor(amount)
	return true
end

function CurrencyManager.ClearPlayer(player)
	playerCurrencies[player.UserId] = nil
end

return CurrencyManager

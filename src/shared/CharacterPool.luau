local CharacterPool = {}

CharacterPool.pools = {
	normal = {
		{
			Name = "Flame Ronin",
			Type = "Fire",
			Rarity = "Rare",
			Stars = 3,
			Weight = 60,
			Attack = 120,
			Defense = 80,
			CritChance = 0.12,
			CritDamage = 1.75,
		},
		{
			Name = "Aqua Sorcerer",
			Type = "Water",
			Rarity = "Rare",
			Stars = 3,
			Weight = 60,
			Attack = 110,
			Defense = 85,
			CritChance = 0.10,
			CritDamage = 1.7,
		},
		{
			Name = "Wind Duelist",
			Type = "Wind",
			Rarity = "Epic",
			Stars = 4,
			Weight = 25,
			Attack = 115,
			Defense = 75,
			CritChance = 0.14,
			CritDamage = 1.8,
		},
		{
			Name = "Thunder Valkyrie",
			Type = "Light",
			Rarity = "Legendary",
			Stars = 5,
			Weight = 10,
			Attack = 140,
			Defense = 90,
			CritChance = 0.18,
			CritDamage = 2.0,
		},
		{
			Name = "Shadow Samurai",
			Type = "Dark",
			Rarity = "Legendary",
			Stars = 5,
			Weight = 5,
			Attack = 145,
			Defense = 80,
			CritChance = 0.16,
			CritDamage = 2.0,
		},
	},
}

function CharacterPool.GetPool(poolName)
	return CharacterPool.pools[poolName] or CharacterPool.pools.normal
end

return CharacterPool

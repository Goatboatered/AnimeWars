/**
 * Fetches all obtainable SW monsters + skills from SWARFARM and writes:
 *   src/shared/CharacterPool_Fire.luau
 *   src/shared/CharacterPool_Water.luau
 *   src/shared/CharacterPool_Wind.luau
 *   src/shared/CharacterPool_Light.luau
 *   src/shared/CharacterPool_Dark.luau
 *   src/shared/CharacterPool.luau  (thin merger)
 *
 * Run: node tools/fetch-swarfarm.mjs
 */

import fs from "fs";
import path from "path";

const MONSTERS_URL = "https://swarfarm.com/api/v2/monsters/";
const SKILLS_URL   = "https://swarfarm.com/api/v2/skills/";
const SHARED_DIR   = path.resolve("src/shared");

const RARITY = { 1: "Common", 2: "Common", 3: "Rare", 4: "Epic", 5: "Legendary" };
const WEIGHT  = { 1: 200, 2: 160, 3: 80, 4: 25, 5: 8 };
const ELEMENTS = ["Fire", "Water", "Wind", "Light", "Dark"];

// ── Fetch ─────────────────────────────────────────────────────────────────────

async function fetchAll(baseUrl, label) {
	let url = `${baseUrl}?limit=100`;
	const results = [];
	let page = 0;
	while (url) {
		page++;
		process.stdout.write(`\r  ${label}: page ${page}...`);
		const res = await fetch(url);
		if (!res.ok) throw new Error(`HTTP ${res.status} on ${url}`);
		const data = await res.json();
		results.push(...data.results);
		url = data.next;
	}
	console.log(`\r  ${label}: ${results.length} records.        `);
	return results;
}

// ── Conversion ────────────────────────────────────────────────────────────────

function parseFormula(formula) {
	if (!formula || formula.trim() === "") return { multiplier: 0, scalesWith: "ATK" };
	const m = formula.match(/([\d.]+)\s*\*\s*\{(\w+)\}/);
	if (m) {
		const raw = m[2]; // ATK, HP, DEF, SPD, TARGET_HP_MAX, …
		let stat = "ATK";
		if (raw.includes("HP"))  stat = "HP";
		else if (raw === "DEF")  stat = "DEF";
		else if (raw === "SPD")  stat = "SPD";
		return { multiplier: parseFloat(m[1]), scalesWith: stat };
	}
	return { multiplier: 3.5, scalesWith: "ATK" };
}

// Effect IDs from swarfarm.com/api/v2/skill-effects/
// 35=Heal (ally)
// 45=Self-Heal, 73=Vampire — caster heals themselves
const HEAL_IDS      = new Set([35]);
const SELFHEAL_IDS  = new Set([45, 73]);

function convertSkill(s) {
	if (!s) return null;
	const { multiplier, scalesWith } = parseFormula(s.multiplier_formula);
	const effects = s.effects || [];
	// hits=0 → no damage (pure heal/buff); hits>=1 → deals damage
	const isDmg  = (s.hits || 0) >= 1;
	const heals  = !isDmg && effects.some(e => HEAL_IDS.has(e.effect?.id) && !e.self_effect);
	const selfHeal  = !isDmg && effects.some(e => SELFHEAL_IDS.has(e.effect?.id));
	const lifeSteal = isDmg  && effects.some(e => SELFHEAL_IDS.has(e.effect?.id));
	const passive = !!s.passive;
	const aoe     = !!s.aoe;

	// Derive targeting type from ability function
	let targetType = "EnemySingle";
	if (passive)           targetType = "Passive";
	else if (selfHeal)     targetType = "Self";
	else if (heals && aoe) targetType = "AllyAll";
	else if (heals)        targetType = "AllySingle";
	else if (aoe)          targetType = "EnemyAll";

	return {
		Name:        s.name,
		Description: s.description || "",
		Cooldown:    s.cooltime || 0,
		Type:        passive ? "Passive" : "Active",
		Multiplier:  multiplier,
		ScalesWith:  scalesWith,
		Hits:        s.hits || 1,
		AoE:         aoe,
		Heals:       heals,
		SelfHeal:    selfHeal,
		LifeSteal:   lifeSteal,
		TargetType:  targetType,
	};
}

function convertMonster(m, skillMap) {
	if (!m.obtainable)                           return null;
	if (!ELEMENTS.includes(m.element))           return null;
	const stars = m.natural_stars;
	if (!RARITY[stars])                          return null;

	const hp  = m.max_lvl_hp      || m.base_hp      || 0;
	const atk = m.max_lvl_attack  || m.base_attack  || 0;
	const def = m.max_lvl_defense || m.base_defense || 0;

	return {
		SourceId:   m.id,
		Name:       m.name,
		Type:       m.element,
		Rarity:     RARITY[stars],
		Stars:      stars,
		BaseStars:   m.base_stars || stars,
		AwakenLevel: m.awaken_level || 0,
		AwakensFrom: m.awakens_from || 0,
		AwakensTo:   m.awakens_to || 0,
		AwakenBonus: m.awaken_bonus || "",
		Weight:     WEIGHT[stars] || 10,
		HP:         Math.round(hp),
		Attack:     Math.round(atk),
		Defense:    Math.round(def),
		Speed:      m.speed || 100,
		CritChance: +((m.crit_rate   || 15) / 100).toFixed(4),
		CritDamage: +(1 + (m.crit_damage || 50) / 100).toFixed(4),
		Resistance: +((m.resistance  || 15) / 100).toFixed(4),
		Accuracy:   +((m.accuracy    ||  0) / 100).toFixed(4),
		Abilities:  (m.skills || []).map(id => convertSkill(skillMap.get(id))).filter(Boolean),
	};
}

// ── Luau serialisation ────────────────────────────────────────────────────────

function luauStr(s) {
	return '"' + s
		.replace(/\\/g, "\\\\")
		.replace(/"/g,  '\\"')
		.replace(/\n/g, "\\n")
		.replace(/\r/g, "")
		+ '"';
}

function serializeMonster(m) {
	const lines = ["\t\t{"];
	lines.push(`\t\t\tSourceId = ${m.SourceId},`);
	lines.push(`\t\t\tName = ${luauStr(m.Name)},`);
	lines.push(`\t\t\tType = ${luauStr(m.Type)},`);
	lines.push(`\t\t\tRarity = ${luauStr(m.Rarity)},`);
	lines.push(`\t\t\tStars = ${m.Stars},`);
	lines.push(`\t\t\tBaseStars = ${m.BaseStars},`);
	lines.push(`\t\t\tAwakenLevel = ${m.AwakenLevel},`);
	lines.push(`\t\t\tAwakensFrom = ${m.AwakensFrom},`);
	lines.push(`\t\t\tAwakensTo = ${m.AwakensTo},`);
	lines.push(`\t\t\tAwakenBonus = ${luauStr(m.AwakenBonus)},`);
	lines.push(`\t\t\tWeight = ${m.Weight},`);
	lines.push(`\t\t\tHP = ${m.HP},`);
	lines.push(`\t\t\tAttack = ${m.Attack},`);
	lines.push(`\t\t\tDefense = ${m.Defense},`);
	lines.push(`\t\t\tSpeed = ${m.Speed},`);
	lines.push(`\t\t\tCritChance = ${m.CritChance},`);
	lines.push(`\t\t\tCritDamage = ${m.CritDamage},`);
	lines.push(`\t\t\tResistance = ${m.Resistance},`);
	lines.push(`\t\t\tAccuracy = ${m.Accuracy},`);
	if (m.Abilities.length > 0) {
		lines.push("\t\t\tAbilities = {");
		for (const a of m.Abilities) {
			lines.push("				{");
			lines.push(`					Name = ${luauStr(a.Name)},`);
			lines.push(`					Description = ${luauStr(a.Description)},`);
			lines.push(`					Cooldown = ${a.Cooldown},`);
			lines.push(`					Type = ${luauStr(a.Type)},`);
			lines.push(`					Multiplier = ${a.Multiplier},`);
			lines.push(`					ScalesWith = ${luauStr(a.ScalesWith)},`);
			lines.push(`					Hits = ${a.Hits},`);
			lines.push(`					AoE = ${a.AoE},`);
			lines.push(`					Heals = ${a.Heals},`);
			lines.push(`					SelfHeal = ${a.SelfHeal},`);
			lines.push(`					LifeSteal = ${a.LifeSteal},`);
			lines.push(`					TargetType = ${luauStr(a.TargetType)},`);
			lines.push("				},");
		}
		lines.push("\t\t\t},");
	}
	lines.push("\t\t},");
	return lines.join("\n");
}

// Split element's monsters: 1-3★ (A), 4★ (B1), 5★ (B2)
function writeElementChunks(element, monsters) {
	const chunks = [
		{ suffix: "A",  list: monsters.filter(m => m.Stars <= 3) },
		{ suffix: "B1", list: monsters.filter(m => m.Stars === 4) },
		{ suffix: "B2", list: monsters.filter(m => m.Stars >= 5) },
	];
	const moduleNames = [];
	for (const { suffix, list } of chunks) {
		if (list.length === 0) continue;
		const modName = `CharacterPool_${element}${suffix}`;
		const outPath = path.join(SHARED_DIR, `${modName}.luau`);
		const body = list.map(serializeMonster).join("\n");
		const fileContent = [
			`-- Auto-generated -- do not edit by hand.`,
			`local M = {}`,
			`M.entries = {`,
			body,
			`}`,
			`return M`,
		].join("\n");
		fs.writeFileSync(outPath, fileContent, "utf8");
		const kb = Math.round(fs.statSync(outPath).size / 1024);
		console.log(`  ${modName}.luau -- ${list.length} monsters, ${kb} KB`);
		moduleNames.push(modName);
	}
	return moduleNames;
}

function writeMerger(moduleNames) {
	const outPath = path.join(SHARED_DIR, "CharacterPool.luau");
	const requires = moduleNames.map(n =>
		`\tlocal ${n} = require(script.Parent:WaitForChild("${n}"))`
	).join("\n");
	const merges = moduleNames.map(n =>
		`\tfor _, v in ipairs(${n}.entries) do table.insert(pool, v) end`
	).join("\n");

	const content = [
		"-- Auto-generated — do not edit by hand.",
		"local CharacterPool = {}",
		"",
		"local function buildPool()",
		"\tlocal pool = {}",
		requires,
		merges,
		"\treturn pool",
		"end",
		"",
		"local poolCache = nil",
		"",
		"CharacterPool.pools = setmetatable({}, {",
		"\t__index = function(_, key)",
		"\t\tif key == \"normal\" then",
		"\t\t\tif not poolCache then poolCache = buildPool() end",
		"\t\t\treturn poolCache",
		"\t\tend",
		"\t\treturn {}",
		"\tend,",
		"})",
		"",
		"function CharacterPool.GetPool(poolName)",
		"\treturn CharacterPool.pools[poolName] or {}",
		"end",
		"",
		"return CharacterPool",
	].join("\n");

	fs.writeFileSync(outPath, content, "utf8");
	console.log(`  CharacterPool.luau — merger (${moduleNames.length} sub-modules)`);
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
	console.log("Fetching from SWARFARM (monsters + skills in parallel)...");
	const [rawMonsters, rawSkills] = await Promise.all([
		fetchAll(MONSTERS_URL, "Monsters"),
		fetchAll(SKILLS_URL,   "Skills  "),
	]);

	const skillMap = new Map(rawSkills.map(s => [s.id, s]));

	const monsters = rawMonsters.map(m => convertMonster(m, skillMap)).filter(Boolean);
	const awakenedCount = monsters.filter(m => m.AwakenLevel > 0).length;
	console.log(`\nKept ${monsters.length} summonable monsters (${awakenedCount} awakened forms).\n`);

	// Group by element
	const byElement = {};
	for (const el of ELEMENTS) byElement[el] = [];
	for (const m of monsters)  byElement[m.Type].push(m);

	console.log("Writing element files:");
	const allModuleNames = [];
	for (const el of ELEMENTS) {
		const names = writeElementChunks(el, byElement[el]);
		allModuleNames.push(...names);
	}
	writeMerger(allModuleNames);

	console.log("\nDone.");
}

main().catch(err => { console.error(err); process.exit(1); });

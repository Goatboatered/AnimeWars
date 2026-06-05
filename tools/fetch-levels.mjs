/**
 * Fetches SW campaign dungeon/level data from SWARFARM and writes:
 *   src/combat-shared/EnemyPool_Area1.luau … EnemyPool_Area13.luau
 *   src/combat-shared/EnemyPool.luau  (merger with GetStage + XP tables)
 *
 * Run: node tools/fetch-levels.mjs
 */

import fs from "fs";
import path from "path";

const DUNGEONS_URL = "https://swarfarm.com/api/v2/dungeons/";
const LEVELS_URL   = "https://swarfarm.com/api/v2/levels/";
const MONSTERS_URL = "https://swarfarm.com/api/v2/monsters/";
const SKILLS_URL   = "https://swarfarm.com/api/v2/skills/";
const OUT_DIR      = path.resolve("src/combat-shared");

// XP per stage (from SW wiki — API returns null)
const XP_TABLES = [
	{ normal:[320,800,803,1127,1130,1132,812],      hard:[2280,2292,2304,2312,2327,2342,2058], hell:[4800,4800,4800,4800,4800,4800,4200] },
	{ normal:[1144,1148,1153,1159,1169,1176,842],   hard:[2376,2384,2384,2404,2432,2432,2172], hell:[4800,4800,4800,4800,4800,4800,4200] },
	{ normal:[1530,1548,1566,1593,1605,1617,1454],  hard:[2781,2835,2835,2889,2889,2907,2616], hell:[5400,5400,5400,5400,5400,5400,4800] },
	{ normal:[1819,1828,1849,1858,1879,1891,1894],  hard:[3288,3308,3330,3332,3348,3372,3378], hell:[8400,8400,8400,8400,8400,8400,8400] },
	{ normal:[2090,2111,2123,2144,2156,2177,2183],  hard:[3729,3729,3729,3778,3808,3808,3792], hell:[6600,6600,6600,6600,6600,6600,6600] },
	{ normal:[2408,2420,2436,2460,2463,2472,2288],  hard:[4224,4224,4224,4288,4296,4320,3944], hell:[7200,7200,7200,7200,7200,7200,6600] },
	{ normal:[2520,2548,2568,2580,2596,2616,2636],  hard:[4392,4392,4392,4412,4440,4476,4464], hell:[7200,7200,7200,7200,7200,7200,7200] },
	{ normal:[2664,2684,2696,2712,2736,2756,2764],  hard:[4572,4572,4572,4572,4616,4652,4665], hell:[7200,7200,7200,7200,7200,7200,7200] },
	{ normal:[3024,3040,3040,3080,3100,3120,2196],  hard:[5104,5132,5132,5160,5160,5160,3644], hell:[10920,10920,10920,10920,10920,10920,5400] },
	{ normal:[3194,3216,3216,3264,3284,3304,2860],  hard:[5312,5348,5348,5384,5384,5384,4652], hell:[11020,11100,11100,11180,11180,11180,9572] },
	{ normal:[3404,3424,3548,3576,3588,3600,3036],  hard:[5872,5900,5900,5952,5972,5972,5040], hell:[8560,8584,8584,8632,8652,8672,7260] },
	{ normal:[3548,3548,3576,3620,3680,3692,2592],  hard:[5900,5900,5952,6040,6084,6096,4256], hell:[8584,8584,8652,8716,8780,8800,6120] },
	{ normal:[3548,3588,3620,3712,3800,3824,2700],  hard:[5900,5972,6020,6116,6212,6240,4392], hell:[8584,8652,8696,8816,8932,8972,6296] },
];

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

// ── Skill helpers ─────────────────────────────────────────────────────────────

function parseFormula(formula) {
	if (!formula || formula.trim() === "") return { multiplier: 0, scalesWith: "ATK" };
	const m = formula.match(/([\d.]+)\s*\*\s*\{(\w+)\}/);
	if (m) {
		const raw = m[2];
		let stat = "ATK";
		if (raw.includes("HP"))  stat = "HP";
		else if (raw === "DEF")  stat = "DEF";
		else if (raw === "SPD")  stat = "SPD";
		return { multiplier: parseFloat(m[1]), scalesWith: stat };
	}
	return { multiplier: 3.5, scalesWith: "ATK" };
}

// Effect IDs from swarfarm.com/api/v2/skill-effects/
// 35=Heal (ally), 36=Revive — true ally heals
// 45=Self-Heal, 73=Vampire — caster heals themselves (lifesteal)
const HEAL_IDS     = new Set([35]);
const LIFESTEAL_IDS = new Set([45, 73]);

function convertSkill(s) {
	if (!s) return null;
	const { multiplier, scalesWith } = parseFormula(s.multiplier_formula);
	const effects = s.effects || [];
	return {
		Name:       s.name,
		Cooldown:   s.cooltime || 0,
		Type:       s.passive ? "Passive" : "Active",
		Multiplier: multiplier,
		ScalesWith: scalesWith,
		Hits:       s.hits || 1,
		AoE:        !!s.aoe,
		// hits=0 means no damage (pure heal/utility); hits>=1 means it attacks
		Heals:      (s.hits || 0) === 0 && effects.some(e => HEAL_IDS.has(e.effect?.id) && !e.self_effect),
		LifeSteal:  effects.some(e => LIFESTEAL_IDS.has(e.effect?.id)),
	};
}

// ── Luau helpers ─────────────────────────────────────────────────────────────

function luauStr(s) {
	return '"' + String(s).replace(/\\/g,"\\\\").replace(/"/g,'\\"').replace(/\n/g,"\\n").replace(/\r/g,"") + '"';
}

// ── Area file writer ──────────────────────────────────────────────────────────

function serializeEnemy(e) {
	const lines = [
		"\t\t\t\t\t\t{",
		`\t\t\t\t\t\t\tName = ${luauStr(e.Name)},`,
		`\t\t\t\t\t\t\tType = ${luauStr(e.Type)},`,
		`\t\t\t\t\t\t\tStars = ${e.Stars},`,
		`\t\t\t\t\t\t\tLevel = ${e.Level},`,
		`\t\t\t\t\t\t\tHP = ${e.HP},`,
		`\t\t\t\t\t\t\tAttack = ${e.Attack},`,
		`\t\t\t\t\t\t\tDefense = ${e.Defense},`,
		`\t\t\t\t\t\t\tSpeed = ${e.Speed},`,
		`\t\t\t\t\t\t\tCritChance = ${e.CritChance},`,
		`\t\t\t\t\t\t\tCritDamage = 1.5,`,
		`\t\t\t\t\t\t\tResistance = ${e.Resistance},`,
		`\t\t\t\t\t\t\tAccuracy = ${e.Accuracy},`,
	];

	// Compact abilities: skip passives, only emit non-default fields inline
	const activeAbilities = (e.Abilities || []).filter(a => a.Type !== "Passive");
	if (activeAbilities.length > 0) {
		lines.push("\t\t\t\t\t\t\tAbilities = {");
		for (const a of activeAbilities) {
			const parts = [
				`Name = ${luauStr(a.Name)}`,
				`Cooldown = ${a.Cooldown}`,
				`Multiplier = ${a.Multiplier}`,
			];
			if (a.ScalesWith !== "ATK") parts.push(`ScalesWith = ${luauStr(a.ScalesWith)}`);
			if (a.Hits > 1)             parts.push(`Hits = ${a.Hits}`);
			if (a.AoE)                  parts.push(`AoE = true`);
			if (a.Heals)                parts.push(`Heals = true`);
			if (a.LifeSteal)            parts.push(`LifeSteal = true`);
			lines.push(`\t\t\t\t\t\t\t\t{ ${parts.join(", ")} },`);
		}
		lines.push("\t\t\t\t\t\t\t},");
	}

	lines.push("\t\t\t\t\t\t},");
	return lines.join("\n");
}

function writeAreaFile(areaNum, dungeonName, stages) {
	const outPath = path.join(OUT_DIR, `EnemyPool_Area${areaNum}.luau`);
	const lines = [
		`-- Auto-generated — ${dungeonName}. Do not edit by hand.`,
		"local M = {}",
		"M.stages = {",
	];

	for (const diff of ["normal", "hard", "hell"]) {
		lines.push(`\t${diff} = {`);
		for (let floor = 1; floor <= 7; floor++) {
			const stage = stages[diff][floor];
			if (!stage || !stage.waves || stage.waves.length === 0) {
				lines.push(`\t\t[${floor}] = { waves = {} },`);
				continue;
			}
			lines.push(`\t\t[${floor}] = {`);
			lines.push(`\t\t\twaves = {`);
			for (const wave of stage.waves) {
				lines.push(`\t\t\t\t{`);
				lines.push(`\t\t\t\t\tenemies = {`);
				for (const e of wave) {
					lines.push(serializeEnemy(e));
				}
				lines.push(`\t\t\t\t\t},`);
				lines.push(`\t\t\t\t},`);
			}
			lines.push(`\t\t\t},`);
			lines.push(`\t\t},`);
		}
		lines.push("\t},");
	}

	lines.push("}");
	lines.push("return M");

	fs.writeFileSync(outPath, lines.join("\n"), "utf8");
	const kb = Math.round(fs.statSync(outPath).size / 1024);
	const totalWaves = Object.values(stages).flatMap(d => Object.values(d)).reduce((n, s) => n + (s.waves?.length || 0), 0);
	console.log(`  EnemyPool_Area${areaNum}.luau — ${dungeonName} — ${totalWaves} waves, ${kb} KB`);
}

// ── Merger writer ─────────────────────────────────────────────────────────────

function writeMerger(scenarioDungeons) {
	const outPath = path.join(OUT_DIR, "EnemyPool.luau");
	const names = scenarioDungeons.map(d => luauStr(d.name));

	const requireLines = scenarioDungeons.map((_, i) =>
		`\trequire(script.Parent:WaitForChild("EnemyPool_Area${i + 1}"))`
	).join(",\n");

	const xpLines = XP_TABLES.map((t, i) =>
		`\t[${i + 1}] = { normal={${t.normal.join(",")}}, hard={${t.hard.join(",")}}, hell={${t.hell.join(",")}} },`
	).join("\n");

	const content = [
		"-- Auto-generated by tools/fetch-levels.mjs — do not edit by hand.",
		"local M = {}",
		"",
		"local AREA_NAMES = {",
		"\t" + names.join(",\n\t"),
		"}",
		"",
		"local XP = {",
		xpLines,
		"}",
		"",
		"local AREAS = {",
		requireLines,
		"}",
		"",
		"function M.GetStage(areaNum, difficulty, stageNum)",
		"\tlocal idx = tonumber(areaNum) or 1",
		'\tlocal diff = tostring(difficulty or "normal"):lower()',
		"\tlocal si   = math.clamp(tonumber(stageNum) or 1, 1, 7)",
		"\tlocal pool = AREAS[idx]",
		"\tif not pool then return nil end",
		"\tlocal diffStages = pool.stages[diff]",
		"\tif not diffStages then return nil end",
		"\tlocal stage = diffStages[si]",
		"\treturn {",
		"\t\tname  = AREA_NAMES[idx] or \"Unknown\",",
		"\t\txp    = XP[idx] and XP[idx][diff] and XP[idx][diff][si] or 0,",
		"\t\twaves = stage and stage.waves or {},",
		"\t}",
		"end",
		"",
		"-- Backward compat (used by Studio auto-start fallback)",
		"M.area1 = M.GetStage(1, \"normal\", 1)",
		"",
		"return M",
	].join("\n");

	fs.writeFileSync(outPath, content, "utf8");
	console.log(`  EnemyPool.luau — merger for ${scenarioDungeons.length} areas`);
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
	console.log("Fetching from SWARFARM (dungeons + levels + monsters + skills in parallel)...");
	const [rawDungeons, rawLevels, rawMonsters, rawSkills] = await Promise.all([
		fetchAll(DUNGEONS_URL, "Dungeons"),
		fetchAll(LEVELS_URL,   "Levels  "),
		fetchAll(MONSTERS_URL, "Monsters"),
		fetchAll(SKILLS_URL,   "Skills  "),
	]);

	const skillMap = new Map(rawSkills.map(s => [s.id, s]));

	// Monster ID → {name, element, skills}
	const monsterMap = new Map(rawMonsters.map(m => [m.id, {
		name:    m.name,
		element: m.element,
		skills:  (m.skills || []).map(id => convertSkill(skillMap.get(id))).filter(Boolean),
	}]));

	// Scenario dungeons only, first 13, sorted by id
	const scenarioDungeons = rawDungeons
		.filter(d => d.category === "Scenario")
		.sort((a, b) => a.id - b.id)
		.slice(0, 13);

	console.log(`\nFound ${scenarioDungeons.length} scenario dungeons:`);
	scenarioDungeons.forEach((d, i) => console.log(`  ${i + 1}. ${d.name} (id=${d.id})`));

	// Build level lookup: dungeon_id → floor → difficulty → level
	const dungeonIds = new Set(scenarioDungeons.map(d => d.id));
	const levelLookup = {};
	for (const level of rawLevels) {
		if (!dungeonIds.has(level.dungeon)) continue;
		const did = level.dungeon;
		const diff = level.difficulty.toLowerCase();
		const floor = level.floor;
		if (!levelLookup[did]) levelLookup[did] = {};
		if (!levelLookup[did][diff]) levelLookup[did][diff] = {};
		levelLookup[did][diff][floor] = level;
	}

	console.log("\nWriting area files:");
	for (let i = 0; i < scenarioDungeons.length; i++) {
		const dungeon = scenarioDungeons[i];
		const areaNum = i + 1;
		const lookup  = levelLookup[dungeon.id] || {};

		const stages = { normal: {}, hard: {}, hell: {} };

		for (const diff of ["normal", "hard", "hell"]) {
			for (let floor = 1; floor <= 7; floor++) {
				const level = lookup[diff] && lookup[diff][floor];
				if (!level || !level.waves) { stages[diff][floor] = { waves: [] }; continue; }

				const waves = level.waves
					.slice(0, 3)
					.map(w => (w.enemies || [])
						.slice(0, 4)
						.map(enemy => {
							const mon = monsterMap.get(enemy.monster) || { name: "Unknown", element: "Wind", skills: [] };
							return {
								Name:       mon.name,
								Type:       mon.element,
								Stars:      enemy.stars || 1,
								Level:      enemy.level || 1,
								HP:         enemy.hp,
								Attack:     enemy.attack,
								Defense:    enemy.defense,
								Speed:      enemy.speed,
								CritChance: +((15 + (enemy.crit_bonus || 0)) / 100).toFixed(4),
								Resistance: +((enemy.resist || 15) / 100).toFixed(4),
								Accuracy:   +((enemy.accuracy_bonus || 0) / 100).toFixed(4),
								Abilities:  mon.skills,
							};
						})
					)
					.filter(w => w.length > 0);

				stages[diff][floor] = { waves };
			}
		}

		writeAreaFile(areaNum, dungeon.name, stages);
	}

	writeMerger(scenarioDungeons);
	console.log("\nDone.");
}

main().catch(err => { console.error(err); process.exit(1); });

--!strict
-- Registry: looks up class, weapon, Shinigami, enemy, map, match rule and action definitions by id. Everything is validated once
-- at load, so a typo fails loudly in Studio instead of silently in a match.

local Definitions = script.Parent

local Registry = {}

Registry.DefaultClass = "Gustave"
Registry.DefaultRule = "Standard" -- the rule a match uses until its admission record names one (A1)
Registry.SkillSlots = 2

local classes: { [string]: any } = {}
local shinigami: { [string]: any } = {}
local enemies: { [string]: any } = {}
local maps: { [string]: any } = {}
local rules: { [string]: any } = {}
local ruleOrder: { any } = {}

local ENEMY_TIERS = { Fodder = true, Heavy = true, Elite = true, Boss = true }
local weapons: { [string]: any } = {}
local actions: { [string]: any } = {}

local function addActions(source: string, list: { [string]: any })
	for id, action in list do
		assert(actions[id] == nil, `{source}: action {id} defined twice`)
		assert(action.Duration, `{source}: action {id} has no Duration`)
		assert(action.Anim, `{source}: action {id} has no Anim`)
		assert(not action.Hit or not action.Hit.To or action.Hit.To <= action.Duration, `{source}: action {id} hits after it ends`)
		assert(not action.Beam or (action.Hit and action.Beam.To <= action.Duration), `{source}: beam {id} needs Hit and must end in time`)
		assert(not action.Projectile or (action.Projectile.Hit and action.Projectile.At < action.Duration), `{source}: projectile {id} invalid`)
		assert(not action.Charges or (action.Recharge and action.UnlockLevel), `{source}: skill {id} needs Recharge and UnlockLevel`)
		assert(not action.Next or list[action.Next], `{source}: action {id} chains to missing {action.Next}`)
		assert(not action.Charge or (list[action.Charge.Into] and list[action.Charge.Into].Hold and action.Button), `{source}: action {id} charges into a missing hold`)
		assert(not action.Charge or not action.Hit or action.Charge.At < action.Hit.From, `{source}: action {id} must charge before it hits`)
		assert(not action.Hold or (list[action.Hold.Release] and action.Button and action.Hold.Min < action.Duration), `{source}: hold {id} invalid`)
		actions[id] = action
	end
end

for _, module in Definitions.Classes:GetChildren() do
	local def = require(module) :: any
	assert(def.Id == module.Name, `class module {module.Name} has Id {def.Id}`)
	classes[def.Id] = def
end
addActions("Common", (require(Definitions.Common) :: any).Actions)
for _, module in Definitions.Weapons:GetChildren() do
	local def = require(module) :: any
	weapons[module.Name] = def
	addActions(module.Name, def.Actions)
	assert(not def.Light or actions[def.Light], `weapon {module.Name}: Light {def.Light} doesn't exist`)
	assert(not def.Burst or actions[def.Burst], `weapon {module.Name}: Burst {def.Burst} doesn't exist`)
	assert(not def.Strong or actions[def.Strong], `weapon {module.Name}: Strong {def.Strong} doesn't exist`)
end
for _, module in Definitions.Skills:GetChildren() do
	addActions(`Skills.{module.Name}`, (require(module) :: any).Actions)
end
for _, module in Definitions.Shinigami:GetChildren() do
	local def = require(module) :: any
	assert(def.Id == module.Name, `shinigami module {module.Name} has Id {def.Id}`)
	addActions(`Shinigami.{module.Name}`, def.Actions)
	for _, attackId in def.Attacks do
		assert(actions[attackId] and actions[attackId].Hit, `shinigami {def.Id}: attack {attackId} missing or has no Hit`)
	end
	assert(def.BaseHealth and def.Reach and def.AttackInterval and def.ResummonCooldown, `shinigami {def.Id}: missing tuning`)
	assert(not def.Skill or (actions[def.Skill.Action] and def.Skill.UnlockLevel and def.Skill.Cooldown), `shinigami {def.Id}: skill invalid`)
	assert(not def.Weapon or weapons[def.Weapon], `shinigami {def.Id}: weapon {def.Weapon} doesn't exist`)
	assert(def.Look and def.Look.Body and def.Look.Eyes and def.Look.Aura, `shinigami {def.Id}: Look needs Body, Eyes and Aura`)
	shinigami[def.Id] = def
end
-- Enemies are grouped in one folder per map (Enemies/<Map>/<Id>); ids are unique across every map.
local enemyModules: { ModuleScript } = {}
for _, mapFolder in Definitions.Enemies:GetChildren() do
	for _, module in mapFolder:GetChildren() do
		if module:IsA("ModuleScript") then
			table.insert(enemyModules, module)
		end
	end
end
for _, module in enemyModules do
	local def = require(module) :: any
	assert(enemies[def.Id or ""] == nil, `enemy {def.Id} is defined twice`)
	assert(def.Id == module.Name, `enemy module {module.Name} has Id {def.Id}`)
	assert(ENEMY_TIERS[def.Tier], `enemy {def.Id}: unknown Tier {def.Tier}`)
	addActions(`Enemies.{module.Name}`, def.Actions)
	assert(#def.Attacks > 0, `enemy {def.Id}: no attacks`)
	for _, attack in def.Attacks do
		assert(actions[attack.Action] and actions[attack.Action].Hit, `enemy {def.Id}: attack {attack.Action} missing or has no Hit`)
		assert(attack.Range and attack.Weight, `enemy {def.Id}: attack {attack.Action} needs Range and Weight`)
	end
	for _, key in { "BaseHealth", "WalkSpeed", "ChaseSpeed", "AggroRange", "LeashRange", "AlertTime", "AttackInterval", "Telegraph", "Xp", "Score", "Respawn" } do
		assert(type(def[key]) == "number", `enemy {def.Id}: {key} must be a number`)
	end
	assert(def.LeashRange > def.AggroRange, `enemy {def.Id}: LeashRange must exceed AggroRange`)
	enemies[def.Id] = def
end
for _, module in Definitions.Maps:GetChildren() do
	local def = require(module) :: any
	assert(def.Id == module.Name, `map module {module.Name} has Id {def.Id}`)
	assert(type(def.PlaceId) == "number", `map {def.Id}: PlaceId must be a number`)
	for zoneId, zone in def.Zones do
		assert(zone.DisplayName, `map {def.Id}: zone {zoneId} has no DisplayName`)
		for _, entry in zone.Enemies or {} do
			assert(enemies[entry.Id] and entry.Weight and entry.Weight > 0, `map {def.Id}, zone {zoneId}: bad roster entry {entry.Id}`)
		end
	end
	maps[def.Id] = def
end
-- Match rules: RuleDefaults overlaid with each rule file. Nested tables merge key by key; lists replace whole.
local function isList(t: any): boolean
	return type(t) == "table" and #t > 0
end
local function overlay(base: any, changes: any): any
	local result = table.clone(base)
	for key, value in changes do
		if type(value) == "table" and type(base[key]) == "table" and not isList(value) then
			result[key] = overlay(base[key], value)
		else
			result[key] = value
		end
	end
	return result
end
local function freeze(t: any): any
	for _, value in t do
		if type(value) == "table" and not table.isfrozen(value) then
			freeze(value)
		end
	end
	return table.freeze(t)
end
local ALLIANCE_MODES = { Standard = true, None = true, Bound = true }
local ruleDefaults = require(Definitions.RuleDefaults) :: any
for _, module in Definitions.Rules:GetChildren() do
	local rule = overlay(ruleDefaults, require(module) :: any)
	local id = rule.Id
	assert(id == module.Name, `rule module {module.Name} has Id {id}`)
	assert(type(rule.DisplayName) == "string" and type(rule.Order) == "number", `rule {id}: needs DisplayName and Order`)
	assert(ALLIANCE_MODES[rule.Alliances], `rule {id}: unknown Alliances "{rule.Alliances}"`)
	assert(#rule.Phases >= 1, `rule {id}: no phases`)
	for i, phase in rule.Phases do
		assert(type(phase.Duration) == "number" and phase.Duration > 0, `rule {id}: phase {i} needs a Duration`)
	end
	local last = 0
	for _, phase in rule.CullAfter do
		assert(phase > last and phase <= #rule.Phases, `rule {id}: CullAfter must rise and name existing phases`)
		last = phase
	end
	assert(rule.Finalists >= 1, `rule {id}: Finalists must be at least 1`)
	assert(rule.Ritual.ActivateAt > 0 and rule.Ritual.ActivateAt < 1, `rule {id}: Ritual.ActivateAt must be inside the phase`)
	assert(rule.Final.Lives >= 1 and rule.Final.SuddenDeath.Lives >= 1, `rule {id}: final lives must be at least 1`)
	assert(#rule.Rewards.Placement >= 1 and rule.Rewards.Cap > 0, `rule {id}: rewards incomplete`)
	rules[id] = freeze(rule)
	table.insert(ruleOrder, rules[id])
end
table.sort(ruleOrder, function(a, b)
	return a.Order < b.Order
end)
assert(rules[Registry.DefaultRule], `the default rule {Registry.DefaultRule} must exist`)

for id, class in classes do
	for slot, skillId in class.Skills or {} do
		assert(actions[skillId] and actions[skillId].Charges, `class {id}: skill slot {slot} ({skillId}) isn't a skill`)
	end
	assert(weapons[class.Melee] and weapons[class.Melee].Light, `class {id}: melee weapon {class.Melee} invalid`)
	assert(not class.Ranged or (weapons[class.Ranged] and weapons[class.Ranged].Burst), `class {id}: ranged weapon {class.Ranged} invalid`)
end
assert(classes[Registry.DefaultClass], `default class {Registry.DefaultClass} doesn't exist`)

function Registry.Class(id: string?): any
	return classes[id or Registry.DefaultClass] or classes[Registry.DefaultClass]
end

function Registry.Weapon(id: string): any
	return weapons[id]
end

-- An enemy definition, or nil for an unknown id.
function Registry.Enemy(id: string?): any
	return if id then enemies[id] else nil
end

-- A map definition by id, or nil.
function Registry.Map(id: string?): any
	return if id then maps[id] else nil
end

-- The map definition of a place (by PlaceId), or nil (the Manor has none).
function Registry.MapForPlace(placeId: number): any
	for _, map in maps do
		if map.PlaceId == placeId then
			return map
		end
	end
	return nil
end

-- A match rule by id (RuleDefaults merged in, frozen), or nil.
function Registry.Rule(id: string?): any
	return if id then rules[id] else nil
end

-- The rule a match plays when none is named (Registry.DefaultRule).
function Registry.DefaultRuleDef(): any
	return rules[Registry.DefaultRule]
end

-- Every match rule in display order.
function Registry.Rules(): { any }
	return ruleOrder
end

function Registry.Shinigami(id: string?): any
	return if id then shinigami[id] else nil
end

function Registry.Action(id: string): any
	return actions[id]
end

-- Every action by id (read-only).
function Registry.AllActions(): { [string]: any }
	return actions
end

return Registry

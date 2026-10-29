--!strict
-- Registry: looks up class, weapon and action definitions by id. Everything is validated once at load, so a typo
-- fails loudly in Studio instead of silently in a match.

local Definitions = script.Parent

local Registry = {}

Registry.DefaultClass = "Gustave"
Registry.SkillSlots = 2

local classes: { [string]: any } = {}
local shinigami: { [string]: any } = {}
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
	shinigami[def.Id] = def
end
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

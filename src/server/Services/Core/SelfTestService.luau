--!strict
-- SelfTestService (Studio only): the server half of the regression self-test (client half: SelfTestController).
-- It builds a test pad far above the map (a floor, a combat zone and a passive target dummy) so every place runs the
-- same checks whatever its world looks like, puts the player on it, queues scripted hits and spawns test enemies on
-- request (all cleared by the next TestPad / TestPadClear). Clients
-- call these through the Studio-only DebugCommand remote (the player goes first); the MCP bridge can too.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ScriptContext = game:GetService("ScriptContext")

local Shared = ReplicatedStorage.Shared
local Registry = require(Shared.Definitions.Registry)
local EntityState = require(Shared.Simulation.EntityState)
local CombatSim = require(Shared.Simulation.CombatSim)
local Combat = require(Shared.Config.Combat)
local Parts = require(Shared.Util.Parts)
local Zones = require(Shared.Util.Zones)
local DebugService = require(script.Parent.DebugService)
local EntityService = require(script.Parent.EntityService)
local NpcService = require(script.Parent.NpcService)
local ProgressionService = require(script.Parent.ProgressionService)
local NpcActor = require(script.Parent.Parent.Parent.Npc.NpcActor)

local A = EntityState.Attr
local ENEMY_SPAWN_TAG = NpcService.SpawnTag

local PAD_NAME = "BL_TestPad"
local PAD_CENTER = CFrame.new(0, 3000, 0) -- far above any map
local PAD_SIZE = Vector3.new(300, 4, 300)
local STAND_HEIGHT = 3 -- root height above the floor
local DUMMY_DISTANCE = 8 -- studs in front of the player: in saber reach after the lunge
local DUMMY_HEALTH = 1e6 -- never dies during a run; tests read the HP it loses
local DEFAULT_HIT = "Saber.Light1"

-- Which character attribute starts a TestHitAfter countdown.
local TRIGGERS: { [string]: string } = {
	Dodge = A.DodgeStart,
	Guard = A.GuardStart,
}

local SelfTestService = {}

local returnTo: { [Player]: CFrame } = {}

local function floorTop(): number
	return PAD_CENTER.Position.Y + PAD_SIZE.Y / 2
end

local function buildPad(): Folder
	local pad = Instance.new("Folder")
	pad.Name = PAD_NAME
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Anchored = true
	floor.Size = PAD_SIZE
	floor.CFrame = PAD_CENTER
	floor.Material = Enum.Material.Slate
	floor.Parent = pad
	local zone = Instance.new("Part") -- the Manor only allows combat inside zones
	zone.Name = "CombatZone"
	zone.Anchored, zone.CanCollide, zone.CanQuery, zone.CanTouch = true, false, false, false
	zone.Transparency = 1
	zone.Size = Vector3.new(PAD_SIZE.X, 80, PAD_SIZE.Z)
	zone.CFrame = PAD_CENTER * CFrame.new(0, 40, 0)
	CollectionService:AddTag(zone, Zones.Tag)
	zone.Parent = pad
	pad.Parent = workspace
	return pad
end

local function standAt(offset: Vector3): Vector3
	return Vector3.new(PAD_CENTER.X, floorTop() + STAND_HEIGHT, PAD_CENTER.Z) + offset
end

-- The pad's dummy, rebuilt at full health with no stagger, `distance` studs in front of the player's spot (default
-- DUMMY_DISTANCE). Nil if the place has no dummy template.
local function freshDummy(pad: Instance, facing: Vector3, distance: number?): Model?
	local template = Shared.Assets:FindFirstChild("TrainingDummy") :: Model?
	local old = pad:FindFirstChild("Dummy")
	if old then
		old:Destroy()
	end
	if not template then
		return nil
	end
	local position = standAt(Vector3.new(0, 0, -(distance or DUMMY_DISTANCE)))
	return EntityService.MakeEntity(template, "Dummy", CFrame.lookAt(position, facing), DUMMY_HEALTH, pad)
end

local function padDummy(): Model?
	local pad = workspace:FindFirstChild(PAD_NAME)
	local dummy = pad and pad:FindFirstChild("Dummy")
	if dummy then
		return dummy :: Model
	end
	local yard = workspace:FindFirstChild("TrainingDummies")
	return yard and yard:FindFirstChildWhichIsA("Model")
end

local function characterOf(who: any): (Player, Model, BasePart)
	local player = assert(DebugService.ResolvePlayer(who), "no such player")
	local character = assert(player.Character, "player has no character")
	local root = assert(Parts.Root(character), "character has no root")
	return player, character, root
end

local testEnemies: { Model } = {}

local function clearTestEnemies()
	for _, model in testEnemies do
		NpcService.Despawn(model)
	end
	table.clear(testEnemies)
	local pad = workspace:FindFirstChild(PAD_NAME)
	for _, child in if pad then pad:GetChildren() else {} do
		if CollectionService:HasTag(child, ENEMY_SPAWN_TAG) then
			child:Destroy()
		end
	end
end

-- Puts the player on the pad facing a fresh dummy, at full HP, with no test enemies. Returns the dummy's name.
local function testPad(who: any): string?
	local player, character, root = characterOf(who)
	clearTestEnemies()
	local pad = workspace:FindFirstChild(PAD_NAME) or buildPad()
	local spot = standAt(Vector3.zero)
	if not returnTo[player] then
		returnTo[player] = root.CFrame
	end
	player:RequestStreamAroundAsync(spot)
	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = CFrame.lookAt(spot, spot + Vector3.new(0, 0, -1))
	-- a push still running holds the body to the way it faced before (Simulation/Knock): end it, so this facing stands
	-- (a reset straight after a hit left the next case's attacker 60-80° aside: 2026-10-31)
	character:SetAttribute(A.KnockUntil, 0)
	ProgressionService.Reset(player) -- level 1, so damage checks read the definitions' numbers
	character:SetAttribute(A.HP, EntityState.Number(character, A.HPMax, 0))
	local dummy = freshDummy(pad, spot)
	return dummy and dummy.Name
end

-- Queues a hit from the pad dummy on the player `delay` seconds after the trigger: "Now", or the start of the
-- player's next "Dodge" / "Guard". `actionId` picks the hit (default: the saber's first light hit).
local function testHitAfter(who: any, trigger: string, delay: number, actionId: string?): boolean
	local _, character = characterOf(who)
	local attacker = assert(padDummy(), "no dummy to attack with")
	local hit = Registry.Action(actionId or DEFAULT_HIT).Hit
	local attribute = TRIGGERS[trigger]
	assert(attribute or trigger == "Now", `unknown trigger "{trigger}"`)
	task.spawn(function()
		if attribute then
			repeat
				character:GetAttributeChangedSignal(attribute):Wait()
			until EntityState.Number(character, attribute, -1) >= 0
		end
		task.wait(delay)
		CombatSim.Queue({ Attacker = attacker, Target = character, Hit = hit })
	end)
	return true
end

-- Queues a light hit from the pad dummy on the player that drains `drain` stamina if the player guards it: the
-- ward's cracks and a guard break, through the real guard path (the dummy is level 1, so power is the hit's Damage).
local function testGuardHit(who: any, drain: number): boolean
	local _, character = characterOf(who)
	local attacker = assert(padDummy(), "no dummy to attack with")
	local damage = 10
	local hit = { Damage = damage, Stagger = 0, Reaction = "None", GuardDrain = drain / (damage * Combat.Guard.StaminaPerDamage) }
	CombatSim.Queue({ Attacker = attacker, Target = character, Hit = hit })
	return true
end

-- The combat entity called `name`, or nil.
local function entityNamed(name: string): Model?
	for _, model in CollectionService:GetTagged(EntityState.Tag) do
		if model:IsA("Model") and model.Name == name then
			return model
		end
	end
	return nil
end

-- Staggers the pad dummy, or the entity called `name` (a test enemy): a hit from the player that fills its stagger
-- meter and deals no damage, so it can be bitten (the bite's checks and its review).
local function testStagger(who: any, name: string?): boolean
	local _, character = characterOf(who)
	local target = assert(if name then entityNamed(name) else padDummy(), "nothing to stagger")
	local fill = { Damage = 0, Stagger = Combat.StaggerMax, Reaction = "None" }
	CombatSim.Queue({ Attacker = character, Target = target, Hit = fill })
	return true
end

-- Takes `amount` HP from the player (inside the next simulation step), so a heal can be measured.
local function testWound(who: any, amount: number): boolean
	local _, character = characterOf(who)
	CombatSim.QueueLoss(character, amount)
	return true
end

-- Spawns an enemy `distance` studs in front of the player on the pad, facing them. Returns its name.
local function testEnemy(who: any, enemyId: string, distance: number): string?
	local _, _, root = characterOf(who)
	local spot = (root.CFrame * CFrame.new(0, 0, -distance)).Position
	local model = NpcService.SpawnAt(enemyId, CFrame.lookAt(spot, root.Position))
	if model then
		model.Name = `{model.Name}_Test{#testEnemies + 1}`
		table.insert(testEnemies, model)
	end
	return model and model.Name
end

-- Puts an enemy spawn marker on the pad `distance` studs behind the dummy, refilling after `respawn` seconds.
local function testEnemySpawn(_who: any, enemyId: string, distance: number, respawn: number): boolean
	local pad = assert(workspace:FindFirstChild(PAD_NAME), "no test pad")
	local marker = Instance.new("Part")
	marker.Name = "TestEnemySpawn"
	marker.Anchored = true
	marker.Size = Vector3.new(2, 1, 2)
	marker.Position = standAt(Vector3.new(0, -STAND_HEIGHT + 0.5, -distance))
	marker:SetAttribute("Enemy", enemyId)
	marker:SetAttribute("Respawn", respawn)
	marker:SetAttribute("Radius", 0)
	marker.Parent = pad
	CollectionService:AddTag(marker, ENEMY_SPAWN_TAG)
	return true
end

-- Sets every enemy's HP to 0 (they die with no killer).
local function testKillEnemies(): number
	local count = 0
	local folder = workspace:FindFirstChild(NpcService.FolderName)
	for _, model in if folder then folder:GetChildren() else {} do
		if model:IsA("Model") and EntityState.Number(model, A.HP, 0) > 0 then
			model:SetAttribute(A.HP, 0)
			count += 1
		end
	end
	return count
end

-- The last player death EntityService reported (TestLastDeath).
local lastDeath: { Victim: string, Killer: number?, Shares: { [number]: number } }? = nil

-- A killing blow on the player from the pad dummy, fighting for `side` (a participant id), so the death's credit can
-- be checked: the dummy takes that side for the hit.
local function testLethalHit(who: any, side: number): boolean
	local _, character = characterOf(who)
	local attacker = assert(padDummy(), "no dummy to attack with")
	attacker:SetAttribute(A.OwnerId, side)
	local lethal = { Damage = EntityState.Number(character, A.HP, 0) + 1000, Stagger = 0, Reaction = "None" }
	CombatSim.Queue({ Attacker = attacker, Target = character, Hit = lethal })
	return true
end

-- Removes the pad and puts the player back where they were.
local function testPadClear(who: any): boolean
	local player, _, root = characterOf(who)
	clearTestEnemies()
	local pad = workspace:FindFirstChild(PAD_NAME)
	if pad then
		pad:Destroy()
	end
	local back = returnTo[player]
	returnTo[player] = nil
	if back and EntityState.Number(root.Parent :: Model, A.HP, 0) > 0 then
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = back
	end
	return true
end

function SelfTestService.Init()
	if not RunService:IsStudio() then
		return
	end
	DebugService.Register("TestPad", testPad)
	-- Stands a fresh pad dummy `distance` studs in front of the pad spot (ranged checks: spread).
	DebugService.Register("TestDummyAt", function(_who: any, distance: any)
		local pad = workspace:FindFirstChild(PAD_NAME)
		local dummy = pad and freshDummy(pad, standAt(Vector3.zero), tonumber(distance))
		return dummy and dummy.Name
	end)
	DebugService.Register("TestHitAfter", testHitAfter)
	DebugService.Register("TestStagger", testStagger)
	DebugService.Register("TestWound", testWound)
	DebugService.Register("TestGuardHit", testGuardHit)
	DebugService.Register("TestPadClear", testPadClear)
	DebugService.Register("TestEnemy", testEnemy)
	DebugService.Register("TestEnemySpawn", testEnemySpawn)
	DebugService.Register("TestKillEnemies", testKillEnemies)
	DebugService.Register("TestLethalHit", testLethalHit)
	DebugService.Register("TestLastDeath", function()
		if not lastDeath then
			return nil
		end
		return lastDeath.Victim, lastDeath.Killer, if lastDeath.Killer then lastDeath.Shares[lastDeath.Killer] else nil
	end)
	-- Older name for the i-frame test helper (CLAUDE.md).
	DebugService.Register("HitAfterNextDodge", function(who: any, delay: number)
		return testHitAfter(who, "Dodge", delay)
	end)
end

function SelfTestService.Start()
	if not RunService:IsStudio() then
		return
	end
	-- Script errors on the server since the self-test began (TestErrorsClear / TestErrors): a run fails on any.
	local errors: { string } = {}
	ScriptContext.Error:Connect(function(message: string, _trace: string, origin: Instance?)
		if origin and origin:IsDescendantOf(game) then -- the game's own scripts, not Studio plugins
			table.insert(errors, `{message} ({origin:GetFullName()})`)
		end
	end)
	DebugService.Register("TestErrorsClear", function()
		table.clear(errors)
		return true
	end)
	DebugService.Register("TestErrors", function()
		return table.clone(errors)
	end)
	EntityService.PlayerDied:Connect(function(player: Player, killer: number?, shares: { [number]: number })
		lastDeath = { Victim = player.Name, Killer = killer, Shares = shares }
	end)
	-- The pad dummy never acts, but its body is driven like any NPC's, so hits push it (knockback).
	RunService.Heartbeat:Connect(function()
		local pad = workspace:FindFirstChild(PAD_NAME)
		local dummy = pad and pad:FindFirstChild("Dummy")
		if dummy and dummy:IsA("Model") then
			NpcActor.Update(dummy, time())
		end
	end)
end

return SelfTestService

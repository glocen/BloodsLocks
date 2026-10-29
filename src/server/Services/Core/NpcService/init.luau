--!strict
-- NpcService: hostile NPCs (enemies). Spawns them from the world, runs their brains (EnemyBrain), credits kills and
-- refills spawns.
--   World contract: a part tagged BL_EnemySpawn with an Enemy attribute (an enemy id) or a Zone attribute (a
--   weighted pick from that zone's roster in the place's map definition), optional Count (default 1), Radius (scatter,
--   default Config.Npc.SpawnRadius) and Respawn (seconds, overrides the enemy's). Spawn parts are invisible markers.
--   Brains think Config.Npc.BrainRate times a second, and only when a player is within SleepDistance.
--   Kill credit: every hit on an enemy adds to its attacker's damage share (a Shinigami's counts for its master);
--   Died fires (model, def, killer player?, shares by player) once it reaches 0 HP. The body fades out; its spawn
--   slot refills Respawn seconds later, once no player is within RespawnClearRadius.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config.Npc)
local Registry = require(Shared.Definitions.Registry)
local EntityState = require(Shared.Simulation.EntityState)
local CombatSim = require(Shared.Simulation.CombatSim)
local Parts = require(Shared.Util.Parts)
local Signal = require(Shared.Util.Signal)
local Log = require(Shared.Util.Log)
local WorldTags = require(Shared.World.Tags)
local DebugService = require(script.Parent.DebugService)
local EntityService = require(script.Parent.EntityService)
local EnemyBrain = require(script.EnemyBrain)

local A = EntityState.Attr
local num = EntityState.Number

local SPAWN_TAG = WorldTags.EnemySpawn.Tag
local FOLDER_NAME = "BL_Enemies"
local TEMPLATE_NAME = "TrainingDummy" -- placeholder rig for every enemy until modelled ones land in Assets.Enemies
local GROUND_PROBE = 50 -- studs a spawn looks down for ground

type Slot = { Spawn: BasePart, DefId: string?, Enemy: Model?, RespawnAt: number? }
type Enemy = {
	Model: Model,
	Def: any,
	Brain: EnemyBrain.Brain,
	Slot: Slot?,
	Shares: { [Player]: number },
	Killer: Player?,
	Dead: boolean,
}

local NpcService = {}

NpcService.SpawnTag = SPAWN_TAG
NpcService.FolderName = FOLDER_NAME

-- Fires (model, def, killer: Player?, shares: { [Player]: number }) when an enemy dies.
NpcService.Died = Signal.new() :: Signal.Signal<Model, any, Player?, { [Player]: number }>

local enemies: { [Model]: Enemy } = {}
local slots: { Slot } = {}
local folder: Folder
local map = Registry.MapForPlace(game.PlaceId)
local random = Random.new()
local kills = 0
local lastKill: { Enemy: string, Killer: string? }? = nil

-- The player a model fights for: the player whose character it is, or the master of a Shinigami.
local function playerOf(model: Model): Player?
	local player = Players:GetPlayerFromCharacter(model)
	if player then
		return player
	end
	local owner = model:GetAttribute(A.OwnerId)
	return if type(owner) == "number" and owner ~= EntityState.HostileSide then Players:GetPlayerByUserId(owner) else nil
end

local function nearestPlayerDistance(position: Vector3): number
	local nearest = math.huge
	for _, player in Players:GetPlayers() do
		local root = Parts.Root(player.Character)
		if root then
			nearest = math.min(nearest, (root.Position - position).Magnitude)
		end
	end
	return nearest
end

-- A weighted roster pick for a zone of this place's map.
local function rosterPick(zoneId: string): string?
	local zone = map and map.Zones[zoneId]
	if not zone then
		return nil
	end
	local total = 0
	for _, entry in zone.Enemies do
		total += entry.Weight
	end
	local roll = random:NextNumber(0, total)
	for _, entry in zone.Enemies do
		roll -= entry.Weight
		if roll <= 0 then
			return entry.Id
		end
	end
	return nil
end

-- A standing spot on the ground near a spawn part.
local function spotNear(spawn: BasePart): CFrame
	local radius = num(spawn, "Radius", Config.SpawnRadius)
	local angle = random:NextNumber(0, 2 * math.pi)
	local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * random:NextNumber(0, radius)
	local from = spawn.Position + offset + Vector3.new(0, 3, 0)
	local hit = workspace:Raycast(from, Vector3.new(0, -GROUND_PROBE, 0))
	local ground = if hit then hit.Position else spawn.Position + offset
	return CFrame.new(ground + Vector3.new(0, 3, 0)) * CFrame.Angles(0, random:NextNumber(0, 2 * math.pi), 0)
end

-- Creates an enemy at `cframe`. Returns its model, or nil for an unknown id / missing template.
function NpcService.SpawnAt(enemyId: string, cframe: CFrame, slot: Slot?): Model?
	local def = Registry.Enemy(enemyId)
	local template = Shared.Assets:FindFirstChild(TEMPLATE_NAME) :: Model?
	if not def or not template then
		Log.Warn("NpcService", `can't spawn "{enemyId}" (unknown enemy or missing template)`)
		return nil
	end
	local model = EntityService.MakeEntity(template, def.DisplayName, cframe, def.BaseHealth, folder, def.Tint, def.Scale)
	local humanoid = Parts.Humanoid(model) :: Humanoid
	humanoid.WalkSpeed = def.WalkSpeed
	model:SetAttribute(A.OwnerId, EntityState.HostileSide) -- one side: enemies never hurt each other
	enemies[model] = {
		Model = model,
		Def = def,
		Brain = EnemyBrain.new(model, def, cframe),
		Slot = slot,
		Shares = {},
		Killer = nil,
		Dead = false,
	}
	if slot then
		slot.Enemy, slot.RespawnAt = model, nil
	end
	return model
end

-- Removes an enemy at once (no death, no credit, no respawn).
function NpcService.Despawn(model: Model)
	local enemy = enemies[model]
	if enemy then
		enemy.Brain:Destroy()
		enemies[model] = nil
		if enemy.Slot and enemy.Slot.Enemy == model then
			enemy.Slot.Enemy = nil
		end
	end
	model:Destroy()
end

local function fade(model: Model)
	local info = TweenInfo.new(Config.CorpseFade)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 then
			TweenService:Create(d, info, { Transparency = 1 }):Play()
		elseif d:IsA("Decal") then
			TweenService:Create(d, info, { Transparency = 1 }):Play()
		end
	end
	task.delay(Config.CorpseFade, function()
		model:Destroy()
	end)
end

local function die(enemy: Enemy, now: number)
	enemy.Dead = true
	enemy.Brain:Destroy()
	local model = enemy.Model
	CollectionService:RemoveTag(model, EntityState.Tag) -- no longer a target
	local humanoid = Parts.Humanoid(model)
	if humanoid then
		humanoid.Health = 0 -- lock-on lets go of it
		humanoid:Move(Vector3.zero)
	end
	kills += 1
	lastKill = { Enemy = enemy.Def.Id, Killer = enemy.Killer and enemy.Killer.Name }
	NpcService.Died:Fire(model, enemy.Def, enemy.Killer, enemy.Shares)
	local slot = enemy.Slot
	if slot then
		slot.Enemy = nil
		slot.RespawnAt = now + num(slot.Spawn, "Respawn", enemy.Def.Respawn)
	end
	enemies[model] = nil
	fade(model)
end

local function onDamaged(target: Model, attacker: Model, amount: number, hpLeft: number)
	local enemy = enemies[target]
	if not enemy or enemy.Dead then
		return
	end
	local player = playerOf(attacker)
	if player then
		enemy.Shares[player] = (enemy.Shares[player] or 0) + amount
		if hpLeft <= 0 then
			enemy.Killer = player
		end
	end
end

local function fillSlot(slot: Slot)
	local id = slot.DefId or rosterPick(slot.Spawn:GetAttribute("Zone") :: string)
	if id then
		NpcService.SpawnAt(id, spotNear(slot.Spawn), slot)
	end
end

local function addSpawn(spawn: Instance)
	if not spawn:IsA("BasePart") then
		return
	end
	spawn.Transparency, spawn.CanCollide, spawn.CanQuery, spawn.CanTouch = 1, false, false, false
	local enemyId = spawn:GetAttribute("Enemy") :: string?
	if enemyId and not Registry.Enemy(enemyId) then
		Log.Warn("NpcService", `{spawn:GetFullName()}: unknown Enemy "{enemyId}"`)
		return
	end
	for _ = 1, math.max(1, math.floor(num(spawn, "Count", 1))) do
		local slot: Slot = { Spawn = spawn, DefId = enemyId }
		table.insert(slots, slot)
		fillSlot(slot)
	end
	-- removing a spawn marker removes its enemies and its slots
	spawn.Destroying:Connect(function()
		for i = #slots, 1, -1 do
			local slot = slots[i]
			if slot.Spawn == spawn then
				if slot.Enemy then
					NpcService.Despawn(slot.Enemy)
				end
				table.remove(slots, i)
			end
		end
	end)
end

local function refill(now: number)
	for _, slot in slots do
		if not slot.Enemy and slot.RespawnAt and now >= slot.RespawnAt and slot.Spawn.Parent then
			if nearestPlayerDistance(slot.Spawn.Position) >= Config.RespawnClearRadius then
				fillSlot(slot)
			end
		end
	end
end

function NpcService.Init()
	folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = workspace
	DebugService.Register("SpawnEnemy", function(who: any, enemyId: string, distance: number?)
		local player = assert(DebugService.ResolvePlayer(who), "no such player")
		local root = assert(Parts.Root(player.Character), "no character")
		local spot = root.CFrame * CFrame.new(0, 0, -(distance or 15))
		local model = NpcService.SpawnAt(enemyId, CFrame.lookAt(spot.Position, root.Position))
		return model and model.Name
	end)
	DebugService.Register("Enemies", function()
		local list = {}
		for model, enemy in enemies do
			table.insert(list, `{model.Name} hp {num(model, A.HP, 0)}/{num(model, A.HPMax, 0)} target {enemy.Brain.Target and enemy.Brain.Target.Name or "-"}`)
		end
		return list, kills, lastKill
	end)
end

function NpcService.Start()
	CombatSim.Damaged:Connect(onDamaged)
	CollectionService:GetInstanceAddedSignal(SPAWN_TAG):Connect(addSpawn)
	for _, spawn in CollectionService:GetTagged(SPAWN_TAG) do
		addSpawn(spawn)
	end

	local thinkEvery = 1 / Config.BrainRate
	local sinceThink, sinceRefill = 0, 0
	RunService.Heartbeat:Connect(function(dt)
		local now = time()
		sinceThink += dt
		sinceRefill += dt
		local think = sinceThink >= thinkEvery
		if think then
			sinceThink = 0
		end
		for model, enemy in enemies do
			if not model.Parent then
				NpcService.Despawn(model)
			elseif num(model, A.HP, 0) <= 0 then
				die(enemy, now)
			else
				CombatSim.StepStagger(model, now, dt)
				local root = Parts.Root(model)
				if think and root and nearestPlayerDistance(root.Position) <= Config.SleepDistance then
					enemy.Brain:Step(now)
				end
			end
		end
		if sinceRefill >= 1 then
			sinceRefill = 0
			refill(now)
		end
	end)
end

return NpcService

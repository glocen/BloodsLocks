--!strict
-- EnemyBrain: a hostile NPC's decisions (definitions: Definitions.Enemies). Body control is NpcActor.
--   Idle at home → notices the nearest enemy of its side in AggroRange with line of sight → Alert (turns and pauses
--   AlertTime: fair warning) → Chase at ChaseSpeed → Attack: picks a weighted attack whose Range covers the distance,
--   flashes for Telegraph seconds, then swings → back to chasing after AttackInterval (±20%).
--   At most Config.Npc.MaxAttackersPerTarget enemies swing at one target; the rest wait just out of reach.
--   A target that leaves LeashRange of home (or is out of sight longer than TargetMemory) is dropped; the enemy walks
--   home and heals to full after LeashHealDelay.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config.Npc)
local Parts = require(Shared.Util.Parts)
local Raycast = require(Shared.Util.Raycast)
local EntityState = require(Shared.Simulation.EntityState)
local CombatSim = require(Shared.Simulation.CombatSim)
local NpcActor = require(ServerScriptService.Server.Npc.NpcActor)

local A = EntityState.Attr
local num = EntityState.Number

local EYE_HEIGHT = Vector3.new(0, 1.5, 0)
local WAIT_MARGIN = 5 -- studs beyond its reach an enemy waits at while others have the target

export type Brain = {
	Model: Model,
	Def: any,
	Home: CFrame,
	Target: Model?,
	TargetSeenAt: number,
	AlertUntil: number,
	NextAttack: number,
	Winding: boolean,
	Engaged: boolean, -- winding up or swinging: counts toward the target's attacker limit
	HomeSince: number?,
	Step: (self: Brain, now: number) -> (),
	Destroy: (self: Brain) -> (),
}

local EnemyBrain = {}
EnemyBrain.__index = EnemyBrain

local active: { [Brain]: true } = {}
local random = Random.new()

function EnemyBrain.new(model: Model, def: any, home: CFrame): Brain
	local self = (setmetatable({
		Model = model,
		Def = def,
		Home = home,
		Target = nil,
		TargetSeenAt = 0,
		AlertUntil = 0,
		NextAttack = 0,
		Winding = false,
		Engaged = false,
		HomeSince = nil,
	}, EnemyBrain) :: any) :: Brain
	active[self] = true
	return self
end

function EnemyBrain.Destroy(self: Brain)
	active[self] = nil
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- Enemies already winding up or swinging at `target`.
local function attackersOn(target: Model): number
	local count = 0
	for brain in active do
		if brain.Target == target and brain.Engaged then
			count += 1
		end
	end
	return count
end

local function canSee(model: Model, from: Vector3, target: Model, to: Vector3): boolean
	local hit = workspace:Raycast(from, to - from, Raycast.Exclude({ model, target }, true))
	return hit == nil
end

local function alive(target: Model?): boolean
	return target ~= nil and target.Parent ~= nil and num(target, A.HP, 0) > 0 and CollectionService:HasTag(target, EntityState.Tag)
end

-- Players and their Shinigami (anything that fights for a player) that this enemy may hit.
local function isPrey(model: Model, candidate: Model): boolean
	return CombatSim.Side(candidate) ~= nil and CombatSim.CanDamage(model, candidate)
end

local function pickTarget(self: Brain, root: BasePart, now: number): Model?
	local def, home = self.Def, self.Home.Position
	local eye = root.Position + EYE_HEIGHT
	local current = self.Target
	if alive(current) then
		local currentRoot = Parts.Root(current) :: BasePart
		local inLeash = (currentRoot.Position - home).Magnitude <= def.LeashRange
		if inLeash and (currentRoot.Position - root.Position).Magnitude <= def.AggroRange and canSee(self.Model, eye, current :: Model, currentRoot.Position) then
			self.TargetSeenAt = now
		end
		if inLeash and now - self.TargetSeenAt <= Config.TargetMemory then
			return current
		end
	end
	local best, bestDistance = nil, def.AggroRange
	for _, candidate in CollectionService:GetTagged(EntityState.Tag) do
		if candidate:IsA("Model") and candidate ~= self.Model and alive(candidate) and isPrey(self.Model, candidate) then
			local candidateRoot = Parts.Root(candidate)
			if candidateRoot then
				local distance = (candidateRoot.Position - root.Position).Magnitude
				if distance < bestDistance and (candidateRoot.Position - home).Magnitude <= def.LeashRange and canSee(self.Model, eye, candidate, candidateRoot.Position) then
					best, bestDistance = candidate, distance
				end
			end
		end
	end
	if best then
		self.TargetSeenAt = now
	end
	return best
end

-- A weighted pick among the attacks whose Range reaches `distance`, or nil.
local function chooseAttack(def: any, distance: number): any
	local total = 0
	for _, attack in def.Attacks do
		if attack.Range >= distance then
			total += attack.Weight
		end
	end
	if total <= 0 then
		return nil
	end
	local roll = random:NextNumber(0, total)
	for _, attack in def.Attacks do
		if attack.Range >= distance then
			roll -= attack.Weight
			if roll <= 0 then
				return attack
			end
		end
	end
	return nil
end

local function shortestReach(def: any): number
	local reach = math.huge
	for _, attack in def.Attacks do
		reach = math.min(reach, attack.Range)
	end
	return reach
end

local function goHome(self: Brain, root: BasePart, humanoid: Humanoid, now: number)
	local model = self.Model
	if flat(self.Home.Position - root.Position).Magnitude > Config.HomeRadius then
		self.HomeSince = nil
		NpcActor.Approach(humanoid, self.Home.Position, self.Def.WalkSpeed)
		return
	end
	NpcActor.Hold(humanoid)
	self.HomeSince = self.HomeSince or now
	if now - (self.HomeSince :: number) >= Config.LeashHealDelay and num(model, A.HP, 0) < num(model, A.HPMax, 0) then
		model:SetAttribute(A.HP, num(model, A.HPMax, 0))
		model:SetAttribute(A.Stagger, 0)
	end
end

function EnemyBrain.Step(self: Brain, now: number)
	local model, def = self.Model, self.Def
	local root, humanoid = Parts.Root(model), Parts.Humanoid(model)
	if not root or not humanoid then
		return
	end
	if NpcActor.Update(model, now) then
		return
	end
	if not self.Winding then
		self.Engaged = false
	end
	if self.Winding or not NpcActor.CanAct(model, now) then
		NpcActor.Hold(humanoid)
		return
	end

	local target = pickTarget(self, root, now)
	if target ~= self.Target then
		self.Target = target
		if target then
			self.AlertUntil = now + def.AlertTime
		end
	end
	if not target then
		goHome(self, root, humanoid, now)
		return
	end
	self.HomeSince = nil

	local targetRoot = Parts.Root(target) :: BasePart
	local offset = flat(targetRoot.Position - root.Position)
	local distance = offset.Magnitude
	if now < self.AlertUntil then
		NpcActor.Hold(humanoid)
		NpcActor.Face(model, offset)
		return
	end

	local attack = chooseAttack(def, distance)
	local queued = attackersOn(target) >= Config.MaxAttackersPerTarget
	if attack and not queued and now >= self.NextAttack then
		self.Winding, self.Engaged = true, true
		self.NextAttack = now + def.AttackInterval * random:NextNumber(0.8, 1.2)
		NpcActor.Hold(humanoid)
		NpcActor.Face(model, offset)
		NpcActor.Telegraph(model, Config.Telegraph.Attack, def.Telegraph)
		task.delay(def.Telegraph, function()
			self.Winding = false
			local liveRoot = Parts.Root(target)
			if NpcActor.CanAct(model, time()) and alive(target) and liveRoot then
				NpcActor.Begin(model, attack.Action, liveRoot.Position - root.Position, time())
			else
				self.Engaged = false
			end
		end)
		return
	end

	local reach = shortestReach(def)
	if queued and distance <= reach + WAIT_MARGIN then
		NpcActor.Hold(humanoid) -- others have it; wait just out of reach
		NpcActor.Face(model, offset)
	elseif distance > reach * 0.9 then
		local stand = if queued then reach + WAIT_MARGIN else reach * 0.7
		NpcActor.Approach(humanoid, targetRoot.Position - offset.Unit * stand, def.ChaseSpeed)
	else
		NpcActor.Hold(humanoid)
		NpcActor.Face(model, offset)
	end
end

return EnemyBrain

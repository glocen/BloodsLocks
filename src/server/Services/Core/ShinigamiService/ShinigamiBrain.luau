--!strict
-- ShinigamiBrain: a Shinigami's behaviour. It follows its master (Config.Npc.FollowOffset: out of the camera's
-- way); it engages any enemy fighting its master (the master hit it, it hit the master, or it hit the Shinigami
-- recently) within AggroRange; it walks into Reach and attacks through the normal action pipeline (so hits,
-- guards, parries and staggers all apply), alternating its attacks, and uses its special skill when it's ready.
-- It teleports back if left far behind. Body control: NpcActor.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage.Shared
local NpcConfig = require(Shared.Config.Npc)
local Parts = require(Shared.Util.Parts)
local EntityState = require(Shared.Simulation.EntityState)
local CombatSim = require(Shared.Simulation.CombatSim)
local PlaceRole = require(Shared.Util.PlaceRole)
local NpcActor = require(ServerScriptService.Server.Npc.NpcActor)

local A = EntityState.Attr
local ALL_UNLOCKED = PlaceRole.IsManor -- training ground: everything unlocked
local num = EntityState.Number

local COMBAT_MEMORY = 6 -- seconds a fight counts as ongoing after the last exchange
local LEASH = 70 -- teleport back beyond this distance from the master

export type Brain = {
	Model: Model,
	Owner: Player,
	Def: any,
	NextAttack: number,
	SkillReadyAt: number,
	Winding: boolean,
	AttackIndex: number,
	Step: (self: Brain, now: number) -> (),
}

local ShinigamiBrain = {}
ShinigamiBrain.__index = ShinigamiBrain

function ShinigamiBrain.new(model: Model, owner: Player, def: any): Brain
	return (setmetatable({ Model = model, Owner = owner, Def = def, NextAttack = 0, AttackIndex = 0, SkillReadyAt = 0, Winding = false }, ShinigamiBrain) :: any) :: Brain
end

-- Its spot next to the master.
function ShinigamiBrain.FollowSpot(ownerRoot: BasePart): CFrame
	return ownerRoot.CFrame * CFrame.new(NpcConfig.FollowOffset)
end

-- Horizontal offset (keeps its length; Vector.Flat returns a unit direction).
local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function recentlyHitBy(victim: Model, attackerName: string, now: number): boolean
	local fx = EntityState.Fx(victim)
	return fx:GetAttribute(A.LastHitBy) == attackerName and now - num(fx, A.LastHitAt, -10) <= COMBAT_MEMORY
end

-- The nearest living enemy that is in a fight with the master or with this Shinigami.
local function pickTarget(self: Brain, ownerRoot: BasePart, now: number): Model?
	local master = self.Owner.Character
	local best, bestDistance = nil, self.Def.AggroRange
	for _, candidate in CollectionService:GetTagged(EntityState.Tag) do
		if candidate:IsA("Model") and candidate ~= self.Model and candidate ~= master and CombatSim.CanDamage(self.Model, candidate) and num(candidate, A.HP, 0) > 0 then
			local root = Parts.Root(candidate)
			local engaged = (master ~= nil and (recentlyHitBy(candidate, master.Name, now) or recentlyHitBy(master, candidate.Name, now)))
				or recentlyHitBy(self.Model, candidate.Name, now) -- it hit me
				or recentlyHitBy(candidate, self.Model.Name, now) -- I'm already fighting it
			if root and engaged then
				local distance = (root.Position - ownerRoot.Position).Magnitude
				if distance < bestDistance then
					best, bestDistance = candidate, distance
				end
			end
		end
	end
	return best
end

function ShinigamiBrain.Step(self: Brain, now: number)
	local model = self.Model
	local root = Parts.Root(model)
	local humanoid = Parts.Humanoid(model)
	local ownerRoot = Parts.Root(self.Owner.Character)
	if not root or not humanoid or not ownerRoot then
		return
	end
	if NpcActor.Update(model, now) or self.Winding or not NpcActor.CanAct(model, now) then
		NpcActor.Hold(humanoid)
		return
	end

	if (root.Position - ownerRoot.Position).Magnitude > LEASH then
		model:PivotTo(ShinigamiBrain.FollowSpot(ownerRoot))
		return
	end

	local target = pickTarget(self, ownerRoot, now)
	local targetRoot = target and Parts.Root(target)
	if target and targetRoot then
		local offset = flat(targetRoot.Position - root.Position)
		local distance = offset.Magnitude
		local skill = self.Def.Skill
		local skillReady = skill and now >= self.SkillReadyAt and (ALL_UNLOCKED or num(model, A.Level, 1) >= skill.UnlockLevel)
		if skillReady and distance >= skill.MinRange and distance <= skill.MaxRange then
			self.SkillReadyAt = now + skill.Cooldown
			self.Winding = true
			NpcActor.Hold(humanoid)
			NpcActor.Face(model, offset)
			NpcActor.Telegraph(model, NpcConfig.Telegraph.Skill, skill.Telegraph)
			task.delay(skill.Telegraph, function()
				self.Winding = false
				local liveTarget = Parts.Root(target)
				if NpcActor.CanAct(model, time()) and liveTarget then
					NpcActor.Begin(model, skill.Action, liveTarget.Position - root.Position, time())
				end
			end)
			return
		end
		if distance > self.Def.Reach then
			NpcActor.Approach(humanoid, targetRoot.Position - offset.Unit * (self.Def.Reach * 0.6), self.Def.WalkSpeed)
		elseif now >= self.NextAttack then
			self.NextAttack = now + self.Def.AttackInterval
			self.AttackIndex = self.AttackIndex % #self.Def.Attacks + 1
			NpcActor.Hold(humanoid)
			NpcActor.Begin(model, self.Def.Attacks[self.AttackIndex], offset, now)
		else
			NpcActor.Hold(humanoid)
			NpcActor.Face(model, offset)
		end
		return
	end

	-- follow: keep to its spot beside the master
	local spot = ShinigamiBrain.FollowSpot(ownerRoot).Position
	if flat(spot - root.Position).Magnitude > self.Def.FollowDistance * 0.5 and (ownerRoot.Position - root.Position).Magnitude > self.Def.FollowDistance * 0.6 then
		NpcActor.Approach(humanoid, spot, self.Def.WalkSpeed)
	else
		NpcActor.Hold(humanoid)
	end
end

return ShinigamiBrain

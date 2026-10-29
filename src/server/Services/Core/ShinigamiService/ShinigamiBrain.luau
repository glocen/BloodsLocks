--!strict
-- ShinigamiBrain: a Shinigami's behaviour. It follows its master; it engages any enemy fighting its master (the
-- master hit it, it hit the master, or it hit the Shinigami recently) within AggroRange; it walks into Reach and
-- attacks through the normal action pipeline (so hits, guards, parries and staggers all apply), alternating its
-- attacks. It never acts while stunned, and teleports back if left far behind.

local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Parts = require(Shared.Util.Parts)
local EntityState = require(Shared.Simulation.EntityState)
local CombatSim = require(Shared.Simulation.CombatSim)

local A = EntityState.Attr
local ALL_UNLOCKED = workspace:GetAttribute("PlaceRole") == "Castle" -- training ground: everything unlocked
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

	-- finish the current attack (driving its lunge, since NPCs don't run ActionSim)
	local _, action, startedAt = EntityState.CurrentAction(model)
	if action then
		local elapsed = now - startedAt
		if elapsed >= action.Duration then
			model:SetAttribute(A.ActionId, "")
		else
			humanoid:Move(Vector3.zero)
			local lunge = action.Lunge
			if lunge and elapsed >= lunge.From and elapsed < lunge.To then
				local facing = model:GetAttribute(A.ActionFacing) :: Vector3
				local v = root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity = Vector3.new(facing.X * lunge.Speed, v.Y, facing.Z * lunge.Speed)
			end
			return
		end
	end
	if self.Winding then
		humanoid:Move(Vector3.zero)
		return
	end
	if EntityState.IsStunned(model, now) then
		humanoid:Move(Vector3.zero)
		return
	end

	if (root.Position - ownerRoot.Position).Magnitude > LEASH then
		model:PivotTo(ownerRoot.CFrame * CFrame.new(4, 0, 3))
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
			humanoid:Move(Vector3.zero)
			model:PivotTo(CFrame.lookAt(root.Position, root.Position + offset.Unit))
			-- telegraph: a flash of red before the draw-cut, so it can be read and dodged
			local flash = Instance.new("Highlight")
			flash.FillColor = Color3.fromRGB(176, 22, 44)
			flash.FillTransparency = 0.25
			flash.OutlineColor = Color3.fromRGB(255, 120, 120)
			flash.Parent = model
			TweenService:Create(flash, TweenInfo.new(skill.Telegraph), { FillTransparency = 1 }):Play()
			task.delay(skill.Telegraph, function()
				flash:Destroy()
				self.Winding = false
				local liveTarget = Parts.Root(target)
				if not model.Parent or not liveTarget or EntityState.IsStunned(model, time()) then
					return
				end
				local aim = flat(liveTarget.Position - root.Position)
				local facing = if aim.Magnitude > 0.1 then aim.Unit else offset.Unit
				model:PivotTo(CFrame.lookAt(root.Position, root.Position + facing))
				model:SetAttribute(A.ActionFacing, facing)
				model:SetAttribute(A.ActionId, skill.Action)
				model:SetAttribute(A.ActionStart, time())
			end)
			return
		end
		if distance > self.Def.Reach then
			humanoid:MoveTo(targetRoot.Position - offset.Unit * (self.Def.Reach * 0.6))
		elseif now >= self.NextAttack then
			self.NextAttack = now + self.Def.AttackInterval
			self.AttackIndex = self.AttackIndex % #self.Def.Attacks + 1
			local facing = offset.Unit
			humanoid:Move(Vector3.zero)
			model:PivotTo(CFrame.lookAt(root.Position, root.Position + facing))
			model:SetAttribute(A.ActionFacing, facing)
			model:SetAttribute(A.ActionId, self.Def.Attacks[self.AttackIndex])
			model:SetAttribute(A.ActionStart, now)
		else
			humanoid:Move(Vector3.zero)
			model:PivotTo(CFrame.lookAt(root.Position, root.Position + offset.Unit))
		end
		return
	end

	-- follow: keep a spot behind and to the right of the master
	local spot = (ownerRoot.CFrame * CFrame.new(4, 0, 4)).Position
	if flat(spot - root.Position).Magnitude > self.Def.FollowDistance * 0.5 and (ownerRoot.Position - root.Position).Magnitude > self.Def.FollowDistance * 0.6 then
		humanoid:MoveTo(spot)
	else
		humanoid:Move(Vector3.zero)
	end
end

return ShinigamiBrain

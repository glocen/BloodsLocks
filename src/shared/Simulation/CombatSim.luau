--!strict
-- CombatSim: the server's damage pipeline. CombatService queues hits detected outside the simulation
-- (MuchachoHitbox for melee, raycasts for bullets); ServerStep applies them inside the server's simulation step
-- so HP, stagger, guard and hitstun change on the shared timeline. Order of checks per hit:
--   allegiance -> i-frames (evaded) -> howl window (melee attacker staggered) -> bite (staggered targets only,
--   heals the biter) -> guard from the front (perfect guard = parry; else chip damage + stamina drain, guard
--   break at 0) -> damage, stagger meter, hitstun or stagger, knockback.
-- Feedback events go on the Humanoid (EntityState.Fx) for CombatFxController.

local Players = game:GetService("Players")

local Shared = script.Parent.Parent
local Config = require(Shared.Config.Combat)
local Parts = require(Shared.Util.Parts)
local Vector = require(Shared.Util.Vector)
local EntityState = require(script.Parent.EntityState)
local Stamina = require(script.Parent.Stamina)
local ActionSim = require(script.Parent.ActionSim)
local Zones = require(Shared.Util.Zones)
local PlaceRole = require(Shared.Util.PlaceRole)
local Signal = require(Shared.Util.Signal)
local Leveling = require(script.Parent.Leveling)
local Knock = require(script.Parent.Knock)

local A = EntityState.Attr
local num = EntityState.Number

export type HitRequest = {
	Attacker: Model,
	Target: Model,
	Hit: any, -- the action's Hit table
}

local CombatSim = {}

-- Server: fires (target, attacker, amount, hpLeft) whenever a hit takes HP, inside the simulation step. Handlers
-- must be quick bookkeeping (kill credit, damage shares); anything heavier defers itself.
CombatSim.Damaged = Signal.new() :: Signal.Signal<Model, Model, number, number>

local queue: { HitRequest } = {}
local losses: { { Target: Model, Amount: number } } = {}

-- Server: the match's say over who can be hurt right now (MatchService: no damage to entrants between phases,
-- spawn protection). Nil = everyone can be hurt.
local guard: ((target: Model, now: number) -> boolean)? = nil

local function loseHp(target: Model, attacker: Model?, amount: number)
	local left = math.max(0, num(target, A.HP, 0) - amount)
	target:SetAttribute(A.HP, left)
	if attacker then
		CombatSim.Damaged:Fire(target, attacker, amount, left)
	end
end

function CombatSim.Queue(request: HitRequest)
	table.insert(queue, request)
end

-- Server: HP lost to no one (sudden death's drain), applied inside the next simulation step like any hit.
function CombatSim.QueueLoss(target: Model, amount: number)
	table.insert(losses, { Target = target, Amount = amount })
end

-- Server: `protected(target, now)` returning true makes `target` take no damage (MatchService sets it).
function CombatSim.SetGuard(protected: ((target: Model, now: number) -> boolean)?)
	guard = protected
end

-- The UserId a model fights for: its player, or the owner of a companion. nil for neutral NPCs.
function CombatSim.Side(model: Model): number?
	local player = Players:GetPlayerFromCharacter(model)
	if player then
		return player.UserId
	end
	local owner = model:GetAttribute(A.OwnerId)
	return if type(owner) == "number" then owner else nil
end

-- Allegiance: nobody hits themselves or their own side (a player and their Shinigami). In the Manor combat only
-- happens inside the training yard (Zones); there, players' sides fight each other when PvPInManor is on.
function CombatSim.CanDamage(attacker: Model, target: Model): boolean
	if attacker == target then
		return false
	end
	local a, b = CombatSim.Side(attacker), CombatSim.Side(target)
	if a and b and a == b then
		return false
	end
	if not Zones.ModelInCombat(target) or not Zones.ModelInCombat(attacker) then
		return false -- the Manor outside its training yard is a safe zone
	end
	return not (a and b and PlaceRole.IsManor and not Config.PvPInManor)
end

-- Cancels what the model was doing and puts it into hitstun, or into a stagger.
local function interrupt(model: Model, now: number, hitstun: number, stagger: number?)
	ActionSim.Cancel(model)
	model:SetAttribute(A.GuardStart, -1)
	if stagger then
		model:SetAttribute(A.Stagger, 0)
		model:SetAttribute(A.StaggerUntil, now + stagger)
	elseif hitstun > 0 then
		model:SetAttribute(A.HitstunUntil, now + hitstun)
	end
end

-- Horizontal direction from one model to another, or nil if either is missing or they overlap.
local function toward(from: Model, to: Model): Vector3?
	local a, b = Parts.Root(from), Parts.Root(to)
	if not a or not b then
		return nil
	end
	local direction = Vector.Flat(b.Position - a.Position)
	return if direction ~= Vector3.zero then direction else nil
end

local function facesAttacker(target: Model, attacker: Model): boolean
	local root = Parts.Root(target)
	local direction = toward(target, attacker)
	return root ~= nil and (direction == nil or root.CFrame.LookVector:Dot(direction) > Config.Guard.ArcDot)
end

local function damage(request: HitRequest, now: number, amount: number)
	local target, attacker, hit = request.Target, request.Attacker, request.Hit
	local fx = EntityState.Fx(target)
	loseHp(target, attacker, amount)
	fx:SetAttribute(A.LastHitDamage, amount)
	fx:SetAttribute(A.LastHitBy, attacker.Name)
	fx:SetAttribute(A.LastHitRanged, hit.Ranged == true)
	fx:SetAttribute(A.LastHitAt, now) -- last: clients read the others when this one changes

	local reaction = hit.Reaction or "Flinch"
	local stagger = num(target, A.Stagger, 0) + hit.Stagger
	if stagger >= Config.StaggerMax then
		interrupt(target, now, 0, Config.StaggerDuration)
	else
		target:SetAttribute(A.Stagger, stagger)
		local hitstun = Config.Hitstun[reaction] or 0
		if hitstun > 0 then
			interrupt(target, now, hitstun, nil)
		end
	end

	Knock.Apply(target, attacker, Knock.Distance(hit), now)
end

local function apply(request: HitRequest, now: number)
	local target, attacker, hit = request.Target, request.Attacker, request.Hit
	local hp = num(target, A.HP, 0)
	if hp <= 0 or not target.Parent or not CombatSim.CanDamage(attacker, target) or (guard and guard(target, now)) then
		return
	end
	local fx = EntityState.Fx(target)
	-- the attacker's in-match level adds damage (Leveling); rounded so HP stays whole
	local power = math.floor(hit.Damage * Leveling.DamageMultiplier(num(attacker, A.Level, 1)) + 0.5)

	if EntityState.IsInvincible(target, now) then
		fx:SetAttribute(A.LastEvadedAt, now)
		return
	end

	-- Howl: a melee hit landing in the window staggers the attacker instead.
	local _, targetAction, targetStart = EntityState.CurrentAction(target)
	if targetAction and targetAction.Window and not hit.Ranged then
		local elapsed = now - targetStart
		if elapsed >= targetAction.Window.From and elapsed < targetAction.Window.To then
			interrupt(attacker, now, 0, Config.Howl.StaggerDuration)
			fx:SetAttribute(A.LastHowlAt, now)
			return
		end
	end

	-- Bite: only staggered targets. Ends the stagger and heals the biter.
	if hit.Bite then
		if now >= num(target, A.StaggerUntil, 0) then
			return
		end
		target:SetAttribute(A.StaggerUntil, now)
		damage(request, now, power)
		local maxHealth = num(attacker, A.HPMax, 0)
		local heal = math.floor(maxHealth * (hit.Heal or 0))
		attacker:SetAttribute(A.HP, math.min(maxHealth, num(attacker, A.HP, 0) + heal))
		local attackerFx = EntityState.Fx(attacker)
		attackerFx:SetAttribute(A.LastBiteHeal, heal)
		attackerFx:SetAttribute(A.LastBiteAt, now)
		return
	end

	-- Guard from the front.
	local guardStart = num(target, A.GuardStart, -1)
	if guardStart >= 0 and facesAttacker(target, attacker) then
		if now - guardStart <= Config.Guard.PerfectWindow and not hit.Ranged then
			interrupt(attacker, now, Config.Hitstun.Parried, nil)
			fx:SetAttribute(A.LastParryAt, now)
			return
		end
		Stamina.Drain(target, power * Config.Guard.StaminaPerDamage * (hit.GuardDrain or 1), now)
		loseHp(target, attacker, power * Config.Guard.ChipDamage)
		Knock.Apply(target, attacker, Knock.Distance(hit) * Config.Knock.BlockedScale, now)
		fx:SetAttribute(A.LastBlockAt, now)
		if num(target, A.Stamina, 0) <= 0 then
			interrupt(target, now, Config.Guard.BreakStun, nil)
			fx:SetAttribute(A.GuardBrokenAt, now)
		end
		return
	end

	damage(request, now, power)
end

-- Server only, called at the start of each simulation step. Hits from attackers that were already dead (or gone)
-- when the step began are dropped; attackers alive at the start all land, so two hits in the same step trade.
function CombatSim.ServerStep(now: number)
	if #losses > 0 then
		local pending = losses
		losses = {}
		for _, loss in pending do
			if loss.Target.Parent and num(loss.Target, A.HP, 0) > 0 then
				loseHp(loss.Target, nil, loss.Amount)
			end
		end
	end
	if #queue == 0 then
		return
	end
	local pending = queue
	queue = {}
	local aliveAtStart: { [Model]: boolean } = {}
	for _, request in pending do
		local attacker = request.Attacker
		if aliveAtStart[attacker] == nil then
			aliveAtStart[attacker] = attacker.Parent ~= nil and num(attacker, A.HP, 0) > 0
		end
	end
	for _, request in pending do
		if aliveAtStart[request.Attacker] then
			apply(request, now)
		end
	end
end

-- Stagger meter drain, for any entity (players in the simulation, NPCs by their owner).
function CombatSim.StepStagger(model: Model, now: number, dt: number)
	local stagger = num(model, A.Stagger, 0)
	if stagger > 0 and now - num(EntityState.Fx(model), A.LastHitAt, 0) >= Config.StaggerDecayDelay then
		model:SetAttribute(A.Stagger, math.max(0, stagger - Config.StaggerDecayPerSecond * dt))
	end
end

return CombatSim

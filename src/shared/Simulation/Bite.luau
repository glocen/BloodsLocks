--!strict
-- Bite: the hold a bite on a staggered target turns into (owner, 2026-10-31: "it gotta be a bit long, both characters
-- can't move, i-frames for both, and the one who bites recovers HP"). Server only, inside the simulation step:
-- CombatSim calls it. The timeline is the hold action's Seize table (Definitions/Common, Common.BiteHold).
--   Seize: the bite lands on a staggered body. The biter's action becomes the hold, facing the victim; the victim is
--     stunned until the release, turned to face the biter and pulled to the hold's distance (a push its own movement
--     step holds, Knock, re-aimed every step so it lands exactly). Both get i-frames. While held, the two bodies don't
--     collide (their animated heads and torsos would shove them apart): CombatService sees to that from Pairs.
--   Step: the drain's pulses move HP from the victim (never below 1) to the biter; at the release the rest of the
--     damage lands as a full hit that throws the victim back and knocks it down. A hold that breaks (a body dies or
--     leaves, the two end up apart, the victim becomes protected, the biter's hold is cancelled) ends at once, frees
--     both and deals nothing more.
-- Clients read it from the Humanoids (EntityState.Fx): the victim's BittenAt and BittenUntil; the biter's LastBiteAt,
-- BiteVictim, LastBiteHeal and BiteReleaseAt.

local Shared = script.Parent.Parent
local Registry = require(Shared.Definitions.Registry)
local Parts = require(Shared.Util.Parts)
local Vector = require(Shared.Util.Vector)
local EntityState = require(script.Parent.EntityState)
local ActionSim = require(script.Parent.ActionSim)

local A = EntityState.Attr
local num = EntityState.Number

-- What the hold needs from the damage pipeline (CombatSim passes its own).
export type Hooks = {
	Hurt: (target: Model, attacker: Model, amount: number) -> (), -- HP lost with no hit feedback (the pulses)
	-- a full hit dealing `amount`, reported to clients as `shown` (the whole bite)
	Strike: (attacker: Model, target: Model, hit: any, now: number, amount: number, shown: number) -> (),
	Protected: (target: Model, now: number) -> boolean, -- the match says it can't be hurt right now
}

type Hold = {
	Biter: Model,
	Victim: Model,
	Start: number,
	Damage: number, -- the whole bite
	Drain: number, -- the part the pulses take
	Heal: number, -- what the pulses give
	Pulses: number, -- pulses done
	Drained: number,
	Given: number, -- heal handed out so far
	Healed: number, -- of that, what took (the biter's max HP caps it)
}

local Bite = {}

Bite.HoldAction = "Common.BiteHold"
local HOLD = Registry.Action(Bite.HoldAction)
Bite.Timeline = HOLD.Seize
local T = Bite.Timeline
local PULL_TOP_SPEED = 30 -- studs/s: the pull's push never goes faster, however late it is

local byBiter: { [Model]: Hold } = {}
local byVictim: { [Model]: Hold } = {}

-- The victim's push toward the hold's distance, re-aimed from the gap left; stopped once the pull's time is up.
local function pull(hold: Hold, now: number)
	local victim = hold.Victim
	local left = hold.Start + T.Pull - now
	local a, b = Parts.Root(hold.Biter), Parts.Root(victim)
	if left <= 0 or not a or not b then
		if num(victim, A.KnockUntil, 0) > now then
			victim:SetAttribute(A.KnockUntil, now)
		end
		return
	end
	local apart = b.Position - a.Position
	local flat = Vector3.new(apart.X, 0, apart.Z)
	if flat.Magnitude < 1e-3 then
		return
	end
	local gap = flat.Magnitude - T.Distance
	local speed = math.clamp(gap / left, -PULL_TOP_SPEED, PULL_TOP_SPEED)
	victim:SetAttribute(A.Knock, -flat.Unit * speed)
	victim:SetAttribute(A.KnockUntil, now + left)
end

-- Whole points of `total` that the first `done` of `count` equal pulses have moved; the last one lands on the total.
function Bite.Share(total: number, done: number, count: number): number
	return math.floor(total * done / count)
end

-- Whether `model` is in a hold, as the biter or the victim.
function Bite.Holds(model: Model): boolean
	return byBiter[model] ~= nil or byVictim[model] ~= nil
end

-- The holds now: biter -> victim (server). CombatService keeps each pair from colliding while it lasts, outside the
-- simulation (its callbacks may not destroy instances).
function Bite.Pairs(): { [Model]: Model }
	local pairs = {}
	for biter, hold in byBiter do
		pairs[biter] = hold.Victim
	end
	return pairs
end

-- The bite's hit on `victim` (after CombatSim's allegiance, protection and i-frame checks). Takes hold only of a
-- staggered body, and only when neither body is in a hold already. `power` is the bite's damage after the biter's
-- level. True when it took hold.
function Bite.Seize(biter: Model, victim: Model, hit: any, power: number, now: number): boolean
	if Bite.Holds(biter) or Bite.Holds(victim) or now >= num(victim, A.StaggerUntil, 0) then
		return false
	end
	local biterRoot, victimRoot = Parts.Root(biter), Parts.Root(victim)
	if not biterRoot or not victimRoot then
		return false
	end
	local toward = Vector.Flat(victimRoot.Position - biterRoot.Position)
	if toward == Vector3.zero then
		toward = Vector.Flat(biterRoot.CFrame.LookVector)
	end

	-- the biter: its action becomes the hold; invulnerable until it can act again
	ActionSim.Begin(biter, Bite.HoldAction, now, toward)
	biter:SetAttribute(A.KnockUntil, 0)
	biter:SetAttribute(A.IFrameFrom, now)
	biter:SetAttribute(A.IFrameTo, now + HOLD.DodgeCancelFrom)

	-- the victim: its stagger is spent; held (stunned) and invulnerable until the release, facing the biter
	ActionSim.Cancel(victim)
	victim:SetAttribute(A.GuardStart, -1)
	victim:SetAttribute(A.Stagger, 0)
	victim:SetAttribute(A.StaggerUntil, now)
	victim:SetAttribute(A.HitstunUntil, now + T.Release)
	victim:SetAttribute(A.IFrameFrom, now)
	victim:SetAttribute(A.IFrameTo, now + T.Release)
	victim:SetAttribute(A.ActionFacing, -toward)
	local here = victimRoot.Position
	victimRoot.CFrame = CFrame.lookAt(here, here - toward)
	-- pulled to the hold's distance: a short push along the line between them (a negative gap pushes it back)
	local apart = here - biterRoot.Position
	local gap = Vector3.new(apart.X, 0, apart.Z).Magnitude - T.Distance
	victim:SetAttribute(A.Knock, -toward * (gap / T.Pull))
	victim:SetAttribute(A.KnockUntil, if math.abs(gap) > 0.05 then now + T.Pull else 0)

	local hold: Hold = {
		Biter = biter,
		Victim = victim,
		Start = now,
		Damage = power,
		Drain = math.floor(power * T.DrainShare),
		Heal = math.floor(num(biter, A.HPMax, 0) * (hit.Heal or 0)),
		Pulses = 0,
		Drained = 0,
		Given = 0,
		Healed = 0,
	}
	byBiter[biter], byVictim[victim] = hold, hold

	local victimFx, biterFx = EntityState.Fx(victim), EntityState.Fx(biter)
	victimFx:SetAttribute(A.BittenUntil, now + T.Release)
	victimFx:SetAttribute(A.BittenAt, now)
	biterFx:SetAttribute(A.LastBiteHeal, 0)
	biterFx:SetAttribute(A.BiteVictim, victim.Name)
	biterFx:SetAttribute(A.LastBiteAt, now) -- last: clients read the others when this one changes
	return true
end

-- One pulse of the drain: the victim's share (it keeps at least 1 HP), and the biter's heal (up to its max HP).
local function pulse(hold: Hold, hooks: Hooks)
	hold.Pulses += 1
	local biter, victim = hold.Biter, hold.Victim
	local drain = math.min(Bite.Share(hold.Drain, hold.Pulses, T.Pulses) - hold.Drained, num(victim, A.HP, 0) - 1)
	if drain > 0 then
		hooks.Hurt(victim, biter, drain)
		hold.Drained += drain
	end
	local give = Bite.Share(hold.Heal, hold.Pulses, T.Pulses) - hold.Given
	hold.Given += give
	local hp = num(biter, A.HP, 0)
	local healed = math.clamp(num(biter, A.HPMax, 0) - hp, 0, give)
	if healed > 0 then
		biter:SetAttribute(A.HP, hp + healed)
		hold.Healed += healed
	end
end

local function broken(hold: Hold, now: number, hooks: Hooks): boolean
	local biter, victim = hold.Biter, hold.Victim
	if not biter.Parent or not victim.Parent or num(biter, A.HP, 0) <= 0 or num(victim, A.HP, 0) <= 0 then
		return true
	end
	if biter:GetAttribute(A.ActionId) ~= Bite.HoldAction or num(biter, A.ActionStart, 0) ~= hold.Start then
		return true -- the biter's hold was cancelled (a respawn, a reset)
	end
	local a, b = Parts.Root(biter), Parts.Root(victim)
	return not a or not b or (a.Position - b.Position).Magnitude > T.BreakDistance or hooks.Protected(victim, now)
end

-- Ends a hold. A broken one frees both bodies at once; a released one leaves the victim to its knockdown and the
-- biter to its recovery.
local function close(hold: Hold, now: number, released: boolean)
	local biter, victim = hold.Biter, hold.Victim
	byBiter[biter], byVictim[victim] = nil, nil
	if not released then
		victim:SetAttribute(A.HitstunUntil, math.min(num(victim, A.HitstunUntil, 0), now))
		victim:SetAttribute(A.IFrameTo, math.min(num(victim, A.IFrameTo, 0), now))
		biter:SetAttribute(A.IFrameTo, math.min(num(biter, A.IFrameTo, 0), now))
		if biter:GetAttribute(A.ActionId) == Bite.HoldAction then
			ActionSim.Cancel(biter)
		end
	end
	local victimFx, biterFx = EntityState.Fx(victim), EntityState.Fx(biter)
	victimFx:SetAttribute(A.BittenUntil, math.min(num(victimFx, A.BittenUntil, 0), now))
	biterFx:SetAttribute(A.LastBiteHeal, hold.Healed)
	biterFx:SetAttribute(A.BiteReleaseAt, now) -- last: clients read the heal when this one changes
end

-- Every hold's pulses and release, or its end when it breaks. Once per server simulation step, after the hits.
function Bite.Step(now: number, hooks: Hooks)
	local ended: { { Hold: Hold, Released: boolean } } = {}
	for _, hold in byBiter do
		if broken(hold, now, hooks) then
			table.insert(ended, { Hold = hold, Released = false })
			continue
		end
		pull(hold, now)
		local elapsed = now - hold.Start
		while hold.Pulses < T.Pulses and elapsed >= T.FirstPulse + hold.Pulses * T.PulseEvery do
			pulse(hold, hooks)
		end
		if elapsed >= T.Release then
			local rest = hold.Damage - hold.Drained
			local throw = { Damage = rest, Stagger = 0, Reaction = "Knockdown", Knockback = T.Throw, KnockTurn = T.ThrowTurn }
			hooks.Strike(hold.Biter, hold.Victim, throw, now, rest, hold.Damage)
			table.insert(ended, { Hold = hold, Released = true })
		end
	end
	for _, entry in ended do
		close(entry.Hold, now, entry.Released)
	end
end

return Bite

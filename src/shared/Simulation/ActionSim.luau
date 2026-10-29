--!strict
-- ActionSim: everything a character does besides moving, inside the simulation:
--   melee chains (light on Attack, strong on Strong; buffering, chaining, lunge, tracking then commit), charging
--   (hold Strong into a charge stance, release for a charged blow), guard (hold) with perfect-guard timing,
--   howl (strong while guarding), bite, the burst gun (ammo, auto-reload, aim), class skills (charges that
--   recharge, unlocked by level; all unlocked in the Manor), an input buffer near the end of every action, and
--   hitstun/stagger lockout.
-- Hit detection and damage are server-only (CombatService + CombatSim); this module only drives the actor.

local Shared = script.Parent.Parent
local Config = require(Shared.Config.Combat)
local Registry = require(Shared.Definitions.Registry)
local Vector = require(Shared.Util.Vector)
local EntityState = require(script.Parent.EntityState)
local Stamina = require(script.Parent.Stamina)
local Input = require(script.Parent.Input)
local Zones = require(Shared.Util.Zones)
local PlaceRole = require(Shared.Util.PlaceRole)

local A = EntityState.Attr

export type Context = {
	Now: number,
	Busy: boolean, -- dodging or dashing
	Charging: boolean,
	MoveDirection: Vector3, -- flat
	Input: Input.Snapshot,
}

export type Result = {
	Stunned: boolean,
	Acting: boolean,
	Guarding: boolean,
	CanDodge: boolean,
	WalkSpeed: number?,
	Lunge: Vector3?, -- horizontal velocity to apply
	Facing: Vector3?, -- direction to hold the character to
}

local IDLE: Result = { Stunned = false, Acting = false, Guarding = false, CanDodge = true }

-- The Manor is a training ground, so every skill is unlocked there.
local ALL_SKILLS_UNLOCKED = PlaceRole.IsManor

local ActionSim = {}

-- Ends the current action without touching the input buffer (natural end of an action).
local function finish(character: Model)
	EntityState.Set(character, A.ActionId, "")
	EntityState.Set(character, A.ActionBuffered, false)
end

-- Cancels the current action and the input buffer (dodge/jump cancel, getting hit).
function ActionSim.Cancel(character: Model)
	finish(character)
	EntityState.Set(character, A.Queued, "")
end

-- Fills the magazine and every skill's charges for the character's class (on spawn).
function ActionSim.ResetLoadout(character: Model)
	local class = Registry.Class(character:GetAttribute(A.ClassId))
	local gun = class.Ranged and Registry.Weapon(class.Ranged)
	character:SetAttribute(A.Ammo, if gun then gun.Magazine else 0)
	character:SetAttribute(A.ReloadUntil, 0)
	for slot, skillId in class.Skills or {} do
		local attributes = EntityState.SkillSlots[slot]
		character:SetAttribute(attributes.Charges, Registry.Action(skillId).Charges)
		character:SetAttribute(attributes.RechargeAt, 0)
	end
end

-- Whether a skill can be used at the character's current level.
function ActionSim.SkillUnlocked(character: Model, skill: any): boolean
	return ALL_SKILLS_UNLOCKED or EntityState.Number(character, A.Level, 1) >= skill.UnlockLevel
end

-- Brings back one charge per Recharge seconds for every skill below its maximum.
local function recharge(character: Model, class: any, now: number)
	for slot, skillId in class.Skills or {} do
		local skill = Registry.Action(skillId)
		local attributes = EntityState.SkillSlots[slot]
		local charges = EntityState.Number(character, attributes.Charges, 0)
		if charges < skill.Charges and now >= EntityState.Number(character, attributes.RechargeAt, 0) then
			charges += 1
			character:SetAttribute(attributes.Charges, charges)
			if charges < skill.Charges then
				character:SetAttribute(attributes.RechargeAt, now + skill.Recharge)
			end
		end
	end
end

local function start(character: Model, id: string, now: number, facing: Vector3): Result
	local action = Registry.Action(id)
	character:SetAttribute(A.ActionId, id)
	character:SetAttribute(A.ActionStart, now)
	character:SetAttribute(A.ActionBuffered, false)
	character:SetAttribute(A.ActionFacing, facing)
	character:SetAttribute(A.EvadeFreeFrom, now + action.DodgeCancelFrom)
	return {
		Stunned = false,
		Acting = true,
		Guarding = false,
		CanDodge = false,
		WalkSpeed = action.WalkSpeed or Config.ActionWalkSpeed,
		Facing = facing,
	}
end

-- Fires the class's gun if a burst fits in the magazine; otherwise starts a reload.
local function fire(character: Model, gun: any, now: number, aim: Vector3): Result?
	local burst = Registry.Action(gun.Burst)
	local shots = #burst.Shots
	local ammo = EntityState.Number(character, A.Ammo, 0)
	if ammo < shots then
		character:SetAttribute(A.ReloadUntil, now + gun.Reload)
		return nil
	end
	character:SetAttribute(A.Aim, aim)
	character:SetAttribute(A.Ammo, ammo - shots)
	if ammo - shots < shots then
		character:SetAttribute(A.ReloadUntil, now + burst.Duration + gun.Reload)
	end
	return start(character, gun.Burst, now, Vector.Flat(aim))
end

-- Uses the skill in a slot if it's unlocked and has a charge.
local function useSkill(character: Model, class: any, slot: number, now: number, aim: Vector3): Result?
	local skillId = class.Skills and class.Skills[slot]
	local skill = skillId and Registry.Action(skillId)
	if not skill or not ActionSim.SkillUnlocked(character, skill) then
		return nil
	end
	local attributes = EntityState.SkillSlots[slot]
	local charges = EntityState.Number(character, attributes.Charges, 0)
	if charges <= 0 then
		return nil
	end
	if charges >= skill.Charges then
		character:SetAttribute(attributes.RechargeAt, now + skill.Recharge) -- the first missing charge starts recharging
	end
	character:SetAttribute(attributes.Charges, charges - 1)
	character:SetAttribute(A.Aim, aim)
	return start(character, skillId, now, Vector.Flat(aim))
end

-- Actions that fire along the aim (guns, projectiles, beams) keep updating it while tracking.
local function aims(action: any): boolean
	return action.Shots ~= nil or action.Beam ~= nil or action.Projectile ~= nil
end

function ActionSim.Step(character: Model, look: Vector3, ctx: Context): Result
	local now, input = ctx.Now, ctx.Input
	local pressed = input.Pressed
	local class = Registry.Class(character:GetAttribute(A.ClassId))
	local gun = class.Ranged and Registry.Weapon(class.Ranged)

	-- Reload finishes on its own.
	recharge(character, class, now)
	local reloadUntil = EntityState.Number(character, A.ReloadUntil, 0)
	if reloadUntil > 0 and now >= reloadUntil and gun then
		character:SetAttribute(A.Ammo, gun.Magazine)
		character:SetAttribute(A.ReloadUntil, 0)
		reloadUntil = 0
	end

	if EntityState.IsStunned(character, now) then
		ActionSim.Cancel(character)
		EntityState.Set(character, A.GuardStart, -1)
		return { Stunned = true, Acting = false, Guarding = false, CanDodge = false, WalkSpeed = 0 }
	end

	local id, action, startedAt = EntityState.CurrentAction(character)
	local elapsed = now - startedAt
	-- Direction a new action commits to: lock-on target, else where you're moving, else where you face.
	local aim = input.Face or (if ctx.MoveDirection ~= Vector3.zero then ctx.MoveDirection else look)

	-- Howl = guard + strong. A strong press while guarding is never a strong attack: it howls from a cancel window
	-- (or does nothing mid-swing), and a strong attack that just started becomes a howl if guard follows in time.
	local howlPress = pressed.Strong and input.Down.Guard
	if action and input.Down.Guard and not ctx.Busy then
		local fresh = action.Button == "Strong" and not action.Hold and elapsed <= Config.Howl.InputGrace
		if (howlPress and elapsed >= action.DodgeCancelFrom) or fresh then
			if Stamina.TrySpend(character, Config.Howl.StaminaCost, now) then
				ActionSim.Cancel(character)
				character:SetAttribute(A.GuardStart, -1)
				return start(character, "Common.Howl", now, aim)
			end
		end
	end

	-- Charge stance: releasing the button (after the minimum) or holding to the end lets the blow go.
	if action and action.Hold and elapsed >= action.Hold.Min and (elapsed >= action.Duration or not input.Down[action.Button]) then
		return start(character, action.Hold.Release, now, aim)
	end
	if action and elapsed >= action.Duration then
		finish(character)
		id, action = "", nil
	end

	local free = not ctx.Busy and not ctx.Charging

	-- Outside a combat zone (the Manor beyond its training yard) nothing combat-related starts.
	if not action and not Zones.ModelInCombat(character) then
		EntityState.Set(character, A.GuardStart, -1)
		EntityState.Set(character, A.Queued, "")
		return IDLE
	end

	-- Guard: hold to block. Strong while guarding = howl.
	if input.Down.Guard and not action and free then
		if EntityState.Number(character, A.GuardStart, -1) < 0 then
			character:SetAttribute(A.GuardStart, now)
		end
		if pressed.Strong and Stamina.TrySpend(character, Config.Howl.StaminaCost, now) then
			character:SetAttribute(A.GuardStart, -1)
			return start(character, "Common.Howl", now, aim)
		end
		return { Stunned = false, Acting = false, Guarding = true, CanDodge = true, WalkSpeed = Config.Guard.WalkSpeed, Facing = input.Face }
	end
	EntityState.Set(character, A.GuardStart, -1)

	-- Input buffer: a press near the end of the current action fires when it ends.
	local bite, ranged, attack, strong = pressed.Bite, pressed.Ranged, pressed.Attack, pressed.Strong and not howlPress
	local skill1, skill2 = pressed.Skill1, pressed.Skill2
	local button = action and (action.Button or "Attack")
	local chains = action and action.Next ~= nil
	if action and elapsed >= action.Duration - Config.InputBuffer then
		local kind = if bite then "Bite"
			elseif skill1 then "Skill1"
			elseif skill2 then "Skill2"
			elseif ranged then "Ranged"
			elseif attack and not (chains and button == "Attack") then "Attack"
			elseif strong and not (chains and button == "Strong") then "Strong"
			else nil
		if kind then
			character:SetAttribute(A.Queued, kind)
		end
	elseif not action then
		local queued = character:GetAttribute(A.Queued)
		if queued ~= "" then
			character:SetAttribute(A.Queued, "")
			bite = bite or queued == "Bite"
			ranged = ranged or queued == "Ranged"
			attack = attack or queued == "Attack"
			strong = strong or queued == "Strong"
			skill1 = skill1 or queued == "Skill1"
			skill2 = skill2 or queued == "Skill2"
		end
	end

	if not action then
		if not free then
			return IDLE
		end
		if bite then
			return start(character, "Common.Bite", now, aim)
		elseif skill1 or skill2 then
			return useSkill(character, class, if skill1 then 1 else 2, now, input.Aim or aim) or IDLE
		elseif ranged and gun and reloadUntil == 0 then
			return fire(character, gun, now, input.Aim or aim) or IDLE
		elseif attack then
			return start(character, Registry.Weapon(class.Melee).Light, now, aim)
		elseif strong and Registry.Weapon(class.Melee).Strong then
			return start(character, Registry.Weapon(class.Melee).Strong, now, aim)
		end
		return IDLE
	end

	-- Chain: a press of the action's button during it queues the next hit, which starts once ChainFrom is reached.
	-- A press also marks the button as let go and pressed again, so it no longer counts as a charge hold.
	if pressed[button] and not (button == "Strong" and howlPress) then
		character:SetAttribute(A.ActionBuffered, true)
	end
	local charge = action.Charge
	if charge and elapsed >= charge.At and elapsed < action.Hit.From and input.Down[button] and not character:GetAttribute(A.ActionBuffered) then
		return start(character, charge.Into, now, aim)
	end
	if action.Next and elapsed >= action.ChainFrom and character:GetAttribute(A.ActionBuffered) then
		return start(character, action.Next, now, aim)
	end

	local facing = character:GetAttribute(A.ActionFacing) :: Vector3
	if elapsed < action.TrackUntil then
		if aims(action) and input.Aim then
			character:SetAttribute(A.Aim, input.Aim)
			facing = Vector.Flat(input.Aim)
		else
			facing = aim
		end
		if facing ~= Vector3.zero then
			EntityState.Set(character, A.ActionFacing, facing)
		end
	end

	local lunge = action.Lunge
	return {
		Stunned = false,
		Acting = true,
		Guarding = false,
		CanDodge = elapsed >= action.DodgeCancelFrom,
		WalkSpeed = action.WalkSpeed or Config.ActionWalkSpeed,
		Lunge = if lunge and elapsed >= lunge.From and elapsed < lunge.To then facing * lunge.Speed else nil,
		Facing = facing,
	}
end

return ActionSim

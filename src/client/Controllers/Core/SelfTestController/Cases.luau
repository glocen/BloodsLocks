--!strict
-- Cases: the self-test's checks, in run order. Each starts from a fresh test pad (SelfTestController's Reset: on the
-- pad, facing the dummy, idle, full stamina). Expected numbers come from Config and the definitions, never from
-- literals, so retuning a value doesn't break a check; tolerances cover simulation-step and network timing.
-- Not covered yet: sprint (its input has no Scriptable binding), bite, howl, the charged attack, Light Beam.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Movement = require(Shared.Config.Movement)
local StaminaConfig = require(Shared.Config.Stamina)
local Combat = require(Shared.Config.Combat)
local Registry = require(Shared.Definitions.Registry)
local EntityState = require(Shared.Simulation.EntityState)

local A = EntityState.Attr
local class = Registry.Class(Registry.DefaultClass)
local saber = Registry.Weapon(class.Melee)
local gun = Registry.Weapon(class.Ranged)
local LIGHT1 = Registry.Action(saber.Light).Hit.Damage

-- Polls `condition` until it holds or `timeout` passes; returns whether it held.
local function waitFor(condition: () -> boolean, timeout: number): boolean
	local deadline = os.clock() + timeout
	while not condition() do
		if os.clock() > deadline then
			return false
		end
		task.wait()
	end
	return true
end

-- Highest the root rises during `seconds` after `act` runs.
local function peakRise(t: any, act: () -> (), seconds: number): number
	local root = t.Root()
	local start = root.Position.Y
	local peak = start
	task.spawn(act)
	local deadline = os.clock() + seconds
	while os.clock() < deadline do
		peak = math.max(peak, root.Position.Y)
		task.wait()
	end
	return peak - start
end

local function jumpHeight(velocity: number): number
	return velocity * velocity / (2 * workspace.Gravity)
end

-- Total damage of the light chain: Light, then each Next.
local function lightChainDamage(): (number, number)
	local total, hits, id = 0, 0, saber.Light
	while id do
		local action = Registry.Action(id)
		total += action.Hit.Damage
		hits += 1
		id = action.Next
	end
	return total, hits
end

return {
	{
		Name = "Tap jump",
		Run = function(t)
			local rise = peakRise(t, function()
				t.Press("Jump")
			end, 0.9)
			t.Near("height", rise, jumpHeight(Movement.JumpVelocity), 0.4)
		end,
	},
	{
		Name = "High jump",
		Run = function(t)
			local rise = peakRise(t, function()
				t.Press("Jump", Movement.HighJump.FullCharge + 0.1)
			end, 2)
			t.Near("full-charge height", rise, jumpHeight(Movement.HighJump.MaxVelocity), 1)
		end,
	},
	{
		Name = "Air jumps",
		Run = function(t)
			for _ = 1, Movement.MaxJumps do
				t.Press("Jump")
				t.Wait(0.12)
			end
			t.Check("all jumps used", t.Num(A.JumpsUsed) == Movement.MaxJumps, `jU = {t.Num(A.JumpsUsed)}`)
			local spent = StaminaConfig.Max - t.Num(A.Stamina)
			t.Near("stamina spent on air jumps", spent, (Movement.MaxJumps - 1) * Movement.AirJumpStaminaCost, 2)
			t.Press("Jump")
			t.Wait(0.1)
			t.Check("one more jump is refused", t.Num(A.JumpsUsed) == Movement.MaxJumps)
		end,
	},
	{
		Name = "Dodge",
		Run = function(t)
			local root = t.Root()
			local start = root.Position
			t.Press("Dodge")
			t.Wait(0.1)
			t.Near("stamina cost", StaminaConfig.Max - t.Num(A.Stamina), Movement.Dodge.StaminaCost, 1)
			t.Near("i-frame window", t.Num(A.IFrameTo) - t.Num(A.IFrameFrom), Movement.Dodge.IFrameTo - Movement.Dodge.IFrameFrom, 0.01)
			t.Wait(Movement.Dodge.Duration + 0.2)
			local moved = (root.Position - start) * Vector3.new(1, 0, 1)
			t.Check("backstep distance", moved.Magnitude > 8 and moved.Magnitude < 18, `{string.format("%.1f", moved.Magnitude)} studs`)
		end,
	},
	{
		Name = "Stamina regen",
		Run = function(t)
			t.Press("Dodge")
			t.Wait(0.05)
			local after = t.Num(A.Stamina)
			t.Wait(StaminaConfig.RegenDelay + 0.3)
			local regained = t.Num(A.Stamina) - after
			t.Near("regen over 0.3 s past the delay", regained, StaminaConfig.RegenPerSecond * 0.3, 7)
		end,
	},
	{
		Name = "Light chain",
		Run = function(t)
			t.Lock()
			local before = t.DummyHp()
			local total, hits = lightChainDamage()
			for _ = 1, hits do
				t.Press("Attack")
				t.Wait(0.3)
			end
			t.Wait(1)
			t.Near("damage of the full chain", before - t.DummyHp(), total, 0)
		end,
	},
	{
		Name = "Strong attack",
		Run = function(t)
			t.Lock()
			local before = t.DummyHp()
			t.Press("Strong")
			t.Wait(1)
			t.Near("damage", before - t.DummyHp(), Registry.Action(saber.Strong).Hit.Damage, 0)
		end,
	},
	{
		Name = "Blood Blade",
		Run = function(t)
			t.Lock()
			local skill = Registry.Action(class.Skills[1])
			local slot = EntityState.SkillSlots[1]
			local before = t.DummyHp()
			t.Check("starts with full charges", t.Num(slot.Charges) == skill.Charges, `{t.Num(slot.Charges)}`)
			t.Press("Skill1")
			t.Wait(0.15)
			t.Check("spends one charge", t.Num(slot.Charges) == skill.Charges - 1, `{t.Num(slot.Charges)}`)
			t.Wait(1)
			t.Near("projectile damage", before - t.DummyHp(), skill.Projectile.Hit.Damage, 0)
		end,
	},
	{
		Name = "SMG burst",
		Run = function(t)
			t.Lock()
			local burst = Registry.Action(gun.Burst)
			local before = t.DummyHp()
			t.Press("Ranged")
			t.Wait(burst.Duration + 0.4)
			t.Check("spends one burst of ammo", t.Num(A.Ammo) == gun.Magazine - #burst.Shots, `ammo {t.Num(A.Ammo)}`)
			t.Near("damage of every shot", before - t.DummyHp(), #burst.Shots * burst.Hit.Damage, 0)
		end,
	},
	{
		Name = "Dodge i-frames",
		Run = function(t)
			local hp = t.Num(A.HP)
			local evadedBefore = EntityState.Number(t.Fx(), A.LastEvadedAt, -10)
			t.Server("TestHitAfter", "Dodge", (Movement.Dodge.IFrameFrom + Movement.Dodge.IFrameTo) / 2)
			t.Press("Dodge")
			local evaded = waitFor(function()
				return EntityState.Number(t.Fx(), A.LastEvadedAt, -10) ~= evadedBefore
			end, 2)
			t.Check("a hit inside the window is evaded", evaded)
			t.Check("and does no damage", t.Num(A.HP) == hp, `hp {t.Num(A.HP)} / {hp}`)
		end,
	},
	{
		Name = "Hit after i-frames",
		Run = function(t)
			local hp = t.Num(A.HP)
			t.Server("TestHitAfter", "Dodge", Movement.Dodge.Duration + 0.1)
			t.Press("Dodge")
			waitFor(function()
				return t.Num(A.HP) ~= hp
			end, 2)
			t.Near("a hit after the window lands", hp - t.Num(A.HP), LIGHT1, 0)
		end,
	},
	{
		Name = "Guard",
		Run = function(t)
			local hp, stamina = t.Num(A.HP), t.Num(A.Stamina)
			t.Server("TestHitAfter", "Guard", Combat.Guard.PerfectWindow + 0.15)
			t.Hold("Guard", true)
			waitFor(function()
				return t.Num(A.HP) ~= hp
			end, 2)
			t.Near("chip damage", hp - t.Num(A.HP), LIGHT1 * Combat.Guard.ChipDamage, 0.01)
			t.Near("stamina drain", stamina - t.Num(A.Stamina), LIGHT1 * Combat.Guard.StaminaPerDamage, 1)
			t.Hold("Guard", false)
		end,
	},
	{
		Name = "Parry",
		Run = function(t)
			local dummy = t.Dummy()
			local hp = t.Num(A.HP)
			local parriedBefore = EntityState.Number(t.Fx(), A.LastParryAt, -10)
			t.Server("TestHitAfter", "Guard", Combat.Guard.PerfectWindow / 3)
			t.Hold("Guard", true)
			local parried = waitFor(function()
				return EntityState.Number(t.Fx(), A.LastParryAt, -10) ~= parriedBefore
			end, 2)
			t.Hold("Guard", false)
			t.Check("a hit right after raising guard is parried", parried)
			t.Check("and does no damage", t.Num(A.HP) == hp)
			t.Check("the attacker is stunned", dummy ~= nil and EntityState.Number(dummy, A.HitstunUntil, 0) > 0)
		end,
	},
}

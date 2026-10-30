--!strict
-- Cases: the self-test's checks, in run order. Each starts from a fresh test pad (SelfTestController's Reset: on the
-- pad, facing the dummy, idle, full stamina), except Stay cases, which check the screen as it is: "UI lint" runs
-- first, on whatever is open, so `Invoke("UI lint")` with a menu up lints that menu. Expected numbers come from
-- Config and the definitions, never from literals, so retuning a value doesn't break a check; tolerances cover
-- simulation-step and network timing.
-- Not covered yet: sprint (its input has no Scriptable binding), bite, howl, the charged attack, Light Beam, enemy
-- leashing and the two-attackers limit. "Player kill credit" kills the player, so it stays last.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Movement = require(Shared.Config.Movement)
local StaminaConfig = require(Shared.Config.Stamina)
local Combat = require(Shared.Config.Combat)
local Registry = require(Shared.Definitions.Registry)
local EntityState = require(Shared.Simulation.EntityState)
local PlayerState = require(Shared.Simulation.PlayerState)
local Leveling = require(Shared.Simulation.Leveling)
local Players = game:GetService("Players")
local WorldTags = require(Shared.World.Tags)
local Markers = require(Shared.World.Markers)
local UiLint = require(script.Parent.UiLint)
local PlateController = require(script.Parent.Parent.PlateController)
local PactSiteController = require(script.Parent.Parent.PactSiteController)
local Budget = require(script.Parent.Parent.Parent.Parent.Util.Budget)
local Sfx = require(script.Parent.Parent.Parent.Parent.Audio.Sfx)

local A = EntityState.Attr
local P = PlayerState.Attr

local function playerNum(attribute: string): number
	local value = Players.LocalPlayer:GetAttribute(attribute)
	return if type(value) == "number" then value else 0
end
local TEST_ENEMY = "Wretch"
local SPREAD_RANGE = 30 -- studs: the SMG spread check's distance
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
		Name = "UI lint",
		Stay = true,
		Run = function(t)
			local report = UiLint.Run()
			t.Check("shadows match their labels", #report.Shadow == 0, UiLint.Detail(report.Shadow, report.Checked))
			t.Check("text fits its box", #report.Fit == 0, UiLint.Detail(report.Fit, report.Checked))
			t.Check("rendered text at least its minimum", #report.Size == 0, UiLint.Detail(report.Size, report.Checked))
			t.Check("text inside the screen", #report.Screen == 0, UiLint.Detail(report.Screen, report.Checked))
			t.Check("no placeholder text", #report.Placeholder == 0, UiLint.Detail(report.Placeholder, report.Checked))
		end,
	},
	{
		Name = "Pact sites",
		Stay = true,
		Run = function(t)
			-- every pact circle is dressed: its Shinigami waits there (with no plate: it isn't a combatant) unless your
			-- pact is with it, and only while it waits does the circle offer a pact
			local sites = PactSiteController.Snapshot()
			local plates = PlateController.Snapshot()
			local circles, dressed = 0, 0
			for _, marker in Markers.All(WorldTags.PactCircle.Tag) do
				local def = Registry.Shinigami(marker:GetAttribute("Shinigami"))
				local site = sites[marker]
				if def then
					circles += 1
				end
				if def and site then
					dressed += 1
					local waits = Players.LocalPlayer:GetAttribute(P.ShinigamiId) ~= def.Id
					t.Check(`{def.Id} waits at its circle unless it's with you`, (site.Figure ~= nil) == waits, if site.Figure then "waiting" else "not there")
					t.Check(`the {def.Id} circle offers a pact only while it waits`, site.Offers == waits)
					t.Check(`the waiting {def.Id} has no plate`, site.Figure == nil or plates[site.Figure :: Model] == nil)
				end
			end
			t.Check("every pact circle is dressed", dressed == circles, `{dressed} of {circles}`)
		end,
	},
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
			-- held well past a full charge: input delay can shorten the hold the server sees, and extra holding can't
			-- raise the jump past MaxVelocity
			local rise = peakRise(t, function()
				t.Press("Jump", Movement.HighJump.FullCharge + 0.3)
			end, 2.4)
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
		Name = "Air jump height",
		Run = function(t)
			-- from the top of a tap jump, one air jump rises its own full height (launch sets the vertical speed)
			local root = t.Root()
			t.Press("Jump")
			t.Check("reached the apex", waitFor(function()
				return root.AssemblyLinearVelocity.Y <= 0 and t.Num(A.JumpsUsed) == 1
			end, 1.5))
			local rise = peakRise(t, function()
				t.Press("Jump")
			end, 0.9)
			t.Near("air jump rise", rise, jumpHeight(Movement.AirJumpVelocity), 0.8)
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
		Name = "M1 knockback",
		Run = function(t)
			-- a light hit pushes the dummy straight back by its Knockback (docs/combat-rework.md, C1.2)
			local hit = Registry.Action(saber.Light).Hit
			local dummy = t.Dummy() :: Model
			local root = dummy:FindFirstChild("HumanoidRootPart") :: BasePart
			t.Lock()
			local before = root.Position
			local function moved(): number
				return Vector3.new(root.Position.X - before.X, 0, root.Position.Z - before.Z).Magnitude
			end
			t.Press("Attack")
			-- input delay varies between sessions: wait for the push to start, then for it to run its course
			t.Check("the hit pushes the dummy", waitFor(function()
				return moved() > 0.2
			end, 2))
			t.Wait(Combat.Knock.Time + 0.3)
			t.Near("by its Knockback distance", moved(), hit.Knockback, hit.Knockback * 0.3)
		end,
	},
	{
		Name = "Plates",
		Run = function(t)
			local dummy = t.Dummy() :: Model
			local shown = waitFor(function()
				local plate = PlateController.Snapshot()[dummy]
				return plate ~= nil and plate.Shown
			end, 1.5)
			t.Check("a target in front of you gets a plate", shown)
			local lint = UiLint.Run() -- an unnamed plate before any hit: no name line, no total, no stray text
			t.Check("the plate shows no placeholder text", #lint.Placeholder == 0, UiLint.Detail(lint.Placeholder, lint.Checked))
			t.Lock()
			local before = t.DummyHp()
			t.Press("Attack")
			t.Check("the hit lands", waitFor(function()
				return t.DummyHp() < before
			end, 1.5))
			t.Wait(0.2)
			local plate = PlateController.Snapshot()[dummy]
			t.Near("its running total is the damage you dealt", plate and plate.Total or 0, before - t.DummyHp(), 0)
			t.Near("its HP bar follows the HP", plate and plate.Hp or 0, t.DummyHp() / EntityState.Number(dummy, A.HPMax, 1), 0.01)
			local numbers = 0
			local world = Players.LocalPlayer.PlayerGui:FindFirstChild("BL_World")
			for _, label in if world then world:GetChildren() else {} do
				if label:IsA("TextLabel") and label.Name == "Pop" and tonumber(label.Text) then
					numbers += 1
				end
			end
			t.Check("hits pop no damage numbers (the plate shows them)", numbers == 0, `{numbers}`)
		end,
	},
	{
		Name = "Frame budget",
		Run = function(t)
			-- the per-frame updaters (Util/Budget) average under their limits; plates are up on the pad by now
			t.Wait(1)
			local report = Budget.Report()
			local measured = 0
			for name, limit in Budget.Limits do
				local average = report[name]
				if average then
					measured += 1
					t.Check(`{name} under {limit} ms a frame`, average <= limit, string.format("%.3f ms", average))
				end
			end
			t.Check("something was measured", measured > 0, `{measured} updaters`)
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
			t.Near("up close every round lands", before - t.DummyHp(), #burst.Shots * burst.Hit.Damage, 0)
		end,
	},
	{
		Name = "SMG spread",
		Run = function(t)
			-- the burst blooms: at range some rounds miss, but a burst still lands (docs/combat-rework.md)
			local burst = Registry.Action(gun.Burst)
			local bursts = math.min(5, math.floor(gun.Magazine / #burst.Shots))
			t.Server("TestDummyAt", SPREAD_RANGE)
			t.Wait(0.3)
			t.Lock()
			local before = t.DummyHp()
			for _ = 1, bursts do
				t.Press("Ranged")
				t.Wait(burst.Duration + 0.15)
			end
			t.Wait(0.4)
			local landed = math.floor((before - t.DummyHp()) / burst.Hit.Damage + 0.5)
			local fired = bursts * #burst.Shots
			t.Check(`at {SPREAD_RANGE} studs some rounds miss`, landed < fired, `{landed} of {fired} landed`)
			t.Check("but the bursts still land", landed >= fired * 0.25, `{landed} of {fired} landed`)
		end,
	},
	{
		Name = "Sounds",
		Run = function(t)
			-- every cue is a region of the combat sound sheet, and Sfx plays exactly that region (or nothing at all
			-- until the owner uploads the sheet)
			local sounds, sheet = Registry.Sounds(), Registry.SoundSheet()
			local missing = {}
			for name in sounds.Cues do
				local region = sheet.Regions[name]
				if not region or region.To <= region.From then
					table.insert(missing, name)
				end
			end
			t.Check("every cue has a region on the sheet", #missing == 0, table.concat(missing, ", "))
			local root = t.Root()
			Sfx.Play("GunShot", root)
			local sound = root:FindFirstChild("GunShot")
			if sheet.Id == "" then
				t.Check("silent until the sheet is uploaded", sound == nil)
				return
			end
			local region = sheet.Regions.GunShot
			local playing = sound ~= nil and sound:IsA("Sound") and (sound :: Sound).Playing
			local range = if playing then (sound :: Sound).PlaybackRegion else NumberRange.new(0)
			t.Check("a cue plays its own region of the sheet", playing and math.abs(range.Min - region.From) < 1e-3
				and math.abs(range.Max - region.To) < 1e-3, `{range.Min}-{range.Max}`)
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
	{
		Name = "Enemy aggro",
		Run = function(t)
			local def = Registry.Enemy(TEST_ENEMY)
			local hp = t.Num(A.HP)
			local name = t.Server("TestEnemy", TEST_ENEMY, def.AggroRange * 0.6)
			local enemy = t.Enemy(name)
			t.Check("spawns", enemy ~= nil, name)
			local hit = waitFor(function()
				return t.Num(A.HP) < hp
			end, 8)
			t.Check("notices, chases and lands an attack", hit)
			t.Check("the hit came from it", t.Fx():GetAttribute(A.LastHitBy) == name, tostring(t.Fx():GetAttribute(A.LastHitBy)))
			local attackDamage = {}
			for _, attack in def.Attacks do
				attackDamage[Registry.Action(attack.Action).Hit.Damage] = true
			end
			t.Check("for one of its attacks' damage", attackDamage[hp - t.Num(A.HP)] == true, `lost {hp - t.Num(A.HP)}`)
			local noticed = enemy and EntityState.Fx(enemy):GetAttribute(A.AlertTarget)
			t.Check("it flagged noticing you (the glint)", noticed == t.Character().Name, tostring(noticed))
		end,
	},
	{
		Name = "Enemy kill credit",
		Run = function(t)
			local name = t.Server("TestEnemy", TEST_ENEMY, 7)
			local enemy = t.Enemy(name)
			t.Lock(enemy)
			local dead = waitFor(function()
				t.Press("Attack")
				t.Wait(0.25)
				return enemy == nil or EntityState.Number(enemy, A.HP, 0) <= 0
			end, 12)
			t.Check("dies to the player's attacks", dead)
			t.Wait(0.3)
			local _, _, lastKill = t.Server("Enemies")
			t.Check("credits the player", lastKill ~= nil and lastKill.Killer == t.Character().Name and lastKill.Enemy == TEST_ENEMY,
				if lastKill then `{lastKill.Enemy} by {tostring(lastKill.Killer)}` else "no kill recorded")
			t.Check("can't be locked once dead", (function()
				t.Wait(0.2)
				local humanoid = enemy and enemy:FindFirstChildOfClass("Humanoid")
				return humanoid == nil or humanoid.Health <= 0
			end)())
		end,
	},
	{
		Name = "Level up",
		Run = function(t)
			t.Check("starts at level 1", t.Num(A.Level) == 1, `lvl {t.Num(A.Level)}`)
			local hp, base = t.Num(A.HP), class.BaseHealth
			t.Server("GiveXp", Leveling.XpToNext(1))
			local up = waitFor(function()
				return t.Num(A.Level) == 2
			end, 2)
			t.Check("enough XP reaches level 2 on the character", up)
			t.Near("max HP grows", t.Num(A.HPMax), Leveling.MaxHealth(base, 2), 0)
			t.Near("and the gain is added to HP", t.Num(A.HP) - hp, Leveling.MaxHealth(base, 2) - Leveling.MaxHealth(base, 1), 0)
			t.Near("max stamina grows", t.Num(A.StaminaMax), Leveling.MaxStamina(2), 0)
			t.Lock()
			local before = t.DummyHp()
			t.Press("Strong")
			t.Wait(1)
			local strong = Registry.Action(saber.Strong).Hit.Damage
			t.Near("hits harder", before - t.DummyHp(), math.floor(strong * Leveling.DamageMultiplier(2) + 0.5), 0)
		end,
	},
	{
		Name = "Kill rewards",
		Run = function(t)
			local def = Registry.Enemy(TEST_ENEMY)
			local xp, score = playerNum(P.Xp), playerNum(P.Score)
			local enemy = t.Enemy(t.Server("TestEnemy", TEST_ENEMY, 7))
			t.Lock(enemy)
			waitFor(function()
				t.Press("Attack")
				t.Wait(0.25)
				return enemy == nil or EntityState.Number(enemy, A.HP, 0) <= 0
			end, 12)
			t.Wait(0.4)
			t.Near("the kill's XP", playerNum(P.Xp) - xp, def.Xp, 0)
			t.Near("and its Renown", playerNum(P.Score) - score, def.Score, 0)
		end,
	},
	{
		Name = "Enemy no friendly fire",
		Run = function(t)
			local a = t.Enemy(t.Server("TestEnemy", TEST_ENEMY, 6))
			local b = t.Enemy(t.Server("TestEnemy", TEST_ENEMY, 7))
			local hp = t.Num(A.HP)
			local attacked = waitFor(function()
				return t.Num(A.HP) < hp
			end, 8)
			t.Wait(2) -- more swings, side by side
			t.Check("they attack the player", attacked)
			local full = function(enemy: Model?): boolean
				return enemy ~= nil and EntityState.Number(enemy, A.HP, 0) == EntityState.Number(enemy, A.HPMax, -1)
			end
			t.Check("and never hurt each other", full(a) and full(b),
				`{a and EntityState.Number(a, A.HP, 0)} / {b and EntityState.Number(b, A.HP, 0)}`)
		end,
	},
	{
		Name = "Enemy respawn",
		Run = function(t)
			local respawn = 1
			t.Server("TestEnemySpawn", TEST_ENEMY, 120, respawn) -- beyond the clear radius, beyond aggro
			-- only enemies up on the test pad (the place's own world enemies are far below)
			local function count(): number
				local n = 0
				local folder = workspace:FindFirstChild("BL_Enemies")
				for _, enemy in if folder then folder:GetChildren() else {} do
					local root = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
					if root and math.abs(root.Position.Y - t.Root().Position.Y) < 50 and EntityState.Number(enemy, A.HP, 0) > 0 then
						n += 1
					end
				end
				return n
			end
			t.Check("the spawn fills", waitFor(function()
				return count() == 1
			end, 3))
			t.Server("TestKillEnemies")
			t.Check("it dies", waitFor(function()
				return count() == 0
			end, 3))
			t.Check("and the slot refills once the area is clear", waitFor(function()
				return count() == 1
			end, respawn + 4))
		end,
	},
	{
		Name = "Player kill credit",
		Run = function(t)
			local side = -7 -- an AI hunter's participant id: whoever the attacker fights for gets the credit
			local before = t.Character()
			local hp = t.Num(A.HP)
			t.Server("TestLethalHit", side)
			local died = waitFor(function()
				local humanoid = before:FindFirstChildOfClass("Humanoid")
				return humanoid == nil or humanoid.Health <= 0
			end, 3)
			t.Check("a killing blow kills the player", died)
			t.Wait(0.2)
			local victim, killer, share = t.Server("TestLastDeath")
			t.Check("the death is reported once, for this player", victim == Players.LocalPlayer.Name, tostring(victim))
			t.Check("credited to the attacker's side", killer == side, tostring(killer))
			t.Check("with that side's damage share", type(share) == "number" and share >= hp, tostring(share))
			t.Check("a new body comes back", waitFor(function()
				local character = Players.LocalPlayer.Character
				return character ~= nil and character ~= before and character:GetAttribute(A.Ready) == true
			end, Players.RespawnTime + 6))
		end,
	},
}

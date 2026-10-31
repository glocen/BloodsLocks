--!strict
-- Cases: the self-test's checks, in run order. Each starts from a fresh test pad (SelfTestController's Reset: on the
-- pad, facing the dummy, idle, full stamina), except Stay cases, which check the screen as it is: "UI lint" runs
-- first, on whatever is open, so `Invoke("UI lint")` with a menu up lints that menu. Expected numbers come from
-- Config and the definitions, never from literals, so retuning a value doesn't break a check; tolerances cover
-- simulation-step and network timing.
-- Not covered yet: sprint (its input has no Scriptable binding), howl, the charged attack, Light Beam, enemy leashing
-- and the two-attackers limit. "Player kill credit" kills the player, so it stays last.

local ContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage.Shared
local Movement = require(Shared.Config.Movement)
local StaminaConfig = require(Shared.Config.Stamina)
local Combat = require(Shared.Config.Combat)
local Registry = require(Shared.Definitions.Registry)
local EntityState = require(Shared.Simulation.EntityState)
local PlayerState = require(Shared.Simulation.PlayerState)
local Leveling = require(Shared.Simulation.Leveling)
local Bite = require(Shared.Simulation.Bite)
local Parts = require(Shared.Util.Parts)
local Animations = require(Shared.Config.Animations)
local CameraConfig = require(Shared.Config.Camera)
local Players = game:GetService("Players")
local WorldTags = require(Shared.World.Tags)
local Markers = require(Shared.World.Markers)
local UiLint = require(script.Parent.UiLint)
local PlateController = require(script.Parent.Parent.PlateController)
local PactSiteController = require(script.Parent.Parent.PactSiteController)
local Budget = require(script.Parent.Parent.Parent.Parent.Util.Budget)
local Sfx = require(script.Parent.Parent.Parent.Parent.Audio.Sfx)
local Kit = require(script.Parent.Parent.Parent.Parent.Vfx.Kit)
local Ward = require(script.Parent.Parent.Parent.Parent.Vfx.Ward)
local Theme = require(script.Parent.Parent.Parent.Parent.UI.Theme)
local Layers = require(script.Parent.Parent.Parent.Parent.UI.Core.Layers)
local Focus = require(script.Parent.Parent.Parent.Parent.UI.Core.Focus)

local A = EntityState.Attr
local P = PlayerState.Attr

local function playerNum(attribute: string): number
	local value = Players.LocalPlayer:GetAttribute(attribute)
	return if type(value) == "number" then value else 0
end
local TEST_ENEMY = "Wretch"
local SPREAD_RANGE = 30 -- studs: the SMG spread check's distance
local BITE_RANGE = 3 -- studs: where the bite check stands its dummy
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
		Name = "Own hit feedback",
		Run = function(t)
			-- your own character's combat results arrive without change signals; their effects still play
			-- (CombatFxController.listen): a hit on you flashes your body
			local flashed = false
			local watch = t.Character().DescendantAdded:Connect(function(added)
				if added:IsA("Highlight") then
					flashed = true
				end
			end)
			t.Server("TestHitAfter", "Now", 0)
			t.Check("a hit on you flashes your body", waitFor(function()
				return flashed
			end, 1.5))
			watch:Disconnect()
		end,
	},
	{
		Name = "Stagger kneel",
		Run = function(t)
			-- a staggered body drops to one knee until the stagger ends (Config.Animations.Staggered, played by
			-- AnimationSim from its StaggeredAt)
			t.Server("TestDummyAt", BITE_RANGE)
			t.Wait(0.3)
			local dummy = assert(t.Dummy(), "no dummy")
			local animator = (dummy:FindFirstChildOfClass("Humanoid") :: Humanoid):FindFirstChildOfClass("Animator") :: Animator
			local function kneeling(): boolean
				for _, track in animator:GetPlayingAnimationTracks() do
					if track.Animation and track.Animation.AnimationId == Animations.Default.Staggered then
						return true
					end
				end
				return false
			end
			t.Server("TestStagger")
			t.Check("a staggered body kneels", waitFor(kneeling, 1))
			t.Wait(Combat.StaggerDuration + 0.5)
			t.Check("and rises when the stagger ends", not kneeling())
		end,
	},
	{
		Name = "Bite whiff",
		Run = function(t)
			-- only a staggered body can be bitten: anything else the bite misses
			local fx = t.Fx(t.Character())
			local before = fx:GetAttribute(A.LastBiteAt)
			t.Server("TestDummyAt", BITE_RANGE)
			t.Wait(0.3)
			t.Lock()
			t.Press("Bite")
			t.Wait(1)
			t.Check("a dummy that isn't staggered isn't seized", fx:GetAttribute(A.LastBiteAt) == before
				and EntityState.CurrentAction(t.Character()) ~= Bite.HoldAction)
		end,
	},
	{
		Name = "Bite hold",
		Run = function(t)
			-- owner, 2026-10-31: "a bit long, both can't move, i-frames for both, the one who bites recovers HP"
			-- (Simulation/Bite). The gust is dark smoke and wind, never blood (AGENTS.md rule 4).
			local timeline = Bite.Timeline
			local bite = Registry.Action("Common.Bite").Hit
			local character, fx = t.Character(), t.Fx(t.Character())
			t.Server("TestDummyAt", BITE_RANGE) -- the bite reaches only a few studs (its lunge and short hitbox)
			t.Wait(0.3)
			t.Server("TestWound", 300) -- room for the heal
			t.Lock()
			t.Server("TestStagger")
			t.Wait(0.15)
			local dummy = assert(t.Dummy(), "no dummy")
			local dummyFx = t.Fx(dummy)
			local hpBefore, dummyBefore = t.Num(A.HP), t.DummyHp()
			local seizedBefore, evadedBefore = fx:GetAttribute(A.LastBiteAt), fx:GetAttribute(A.LastEvadedAt)
			local releasedBefore = fx:GetAttribute(A.BiteReleaseAt)
			local bittenBefore = dummyFx:GetAttribute(A.BittenAt)
			t.Press("Bite")
			t.Check("a staggered dummy is seized", waitFor(function()
				return fx:GetAttribute(A.LastBiteAt) ~= seizedBefore
			end, 1.5))
			local seizedAt = os.clock()
			local function at(seconds: number)
				t.Wait(math.max(0, seconds - (os.clock() - seizedAt)))
			end
			t.Check("the bite becomes the hold", EntityState.CurrentAction(character) == Bite.HoldAction)
			t.Check("the dummy is held", dummyFx:GetAttribute(A.BittenAt) ~= bittenBefore)
			-- the smoke ribbons of the bite's wind (Vfx/BiteWind), each timed on the hold's own clock
			local _, _, holdStart = EntityState.CurrentAction(character)
			local ribbons: { number } = {}
			local watch = workspace.DescendantAdded:Connect(function(added)
				if added:IsA("Trail") and added.Texture == Kit.Textures.SmokeRibbon then
					table.insert(ribbons, time() - holdStart)
				end
			end)

			at(timeline.Fangs + 0.3)
			t.Check("your camera narrows through the hold", workspace.CurrentCamera.FieldOfView < CameraConfig.BaseFov - 3,
				`FOV {string.format("%.1f", workspace.CurrentCamera.FieldOfView)}`)
			at(timeline.Pull + 0.25) -- the pull has settled (already, by now)
			local mine, theirs = t.Root().Position, (Parts.Root(dummy) :: BasePart).Position
			local apart = Vector3.new(mine.X - theirs.X, 0, mine.Z - theirs.Z).Magnitude
			t.Near("pulled to the hold's distance", apart, timeline.Distance, 0.3)
			local launched, dodged = t.Num(A.LaunchAt), t.Num(A.DodgeStart)
			t.Press("Jump")
			t.Press("Dodge")
			t.Wait(0.2)
			t.Check("Jump and Dodge do nothing while held", t.Num(A.LaunchAt) == launched and t.Num(A.DodgeStart) == dodged)
			local hpHit = t.Num(A.HP)
			t.Server("TestHitAfter", "Now", 0)
			t.Server("TestStagger") -- a hit on the held dummy
			t.Wait(0.3)
			t.Check("hits on you do nothing", t.Num(A.HP) >= hpHit, `{hpHit} -> {t.Num(A.HP)}`)
			t.Check("hits on the dummy do nothing", EntityState.Number(dummy, A.StaggerUntil, 0) <= time())
			t.Check("no \"Evaded\" over a held body", fx:GetAttribute(A.LastEvadedAt) == evadedBefore)

			at(timeline.Release - 0.1)
			local held = (t.Root().Position - mine).Magnitude < 0.4
				and ((Parts.Root(dummy) :: BasePart).Position - theirs).Magnitude < 0.4
			t.Check("both bodies stay put through the drain", held)

			at(timeline.Release + 0.35)
			watch:Disconnect()
			local heal = math.floor(t.Num(A.HPMax) * bite.Heal)
			t.Near("you drink back the heal", t.Num(A.HP) - hpBefore, heal, 0)
			t.Check("the release is marked, with what you drank", fx:GetAttribute(A.BiteReleaseAt) ~= releasedBefore
				and fx:GetAttribute(A.LastBiteHeal) == heal, `heal {tostring(fx:GetAttribute(A.LastBiteHeal))}`)
			t.Near("the dummy loses exactly the bite", dummyBefore - t.DummyHp(), math.floor(bite.Damage * Leveling.DamageMultiplier(1) + 0.5), 0)
			local function between(from: number, to: number): number
				local count = 0
				for _, at in ribbons do
					count += if at >= from and at < to then 1 else 0
				end
				return count
			end
			t.Check("the drain's smoke circles from the fangs", between(timeline.Fangs - 0.2, timeline.Fangs + 0.3) > 0)
			t.Check("the release's gust sweeps out (its smoke ribbons)", between(timeline.Release - 0.2, timeline.Release + 0.4) > 0,
				`{between(timeline.Release - 0.2, timeline.Release + 0.4)} ribbons`)
			local thrown = (Parts.Root(dummy) :: BasePart).Position - theirs
			t.Check("the release throws the dummy back", Vector3.new(thrown.X, 0, thrown.Z).Magnitude > timeline.Throw * 0.5,
				`{string.format("%.1f", thrown.Magnitude)} studs`)

			t.Check("the hold ends after its recovery", waitFor(function()
				return EntityState.CurrentAction(character) ~= Bite.HoldAction
			end, 1))
			local free = t.Num(A.DodgeStart)
			t.Press("Dodge")
			t.Wait(0.15)
			t.Check("and you move again", t.Num(A.DodgeStart) ~= free)
			t.Wait(0.6)
			t.Check("and your camera opens again", workspace.CurrentCamera.FieldOfView > CameraConfig.BaseFov - 1.5,
				`FOV {string.format("%.1f", workspace.CurrentCamera.FieldOfView)}`)
		end,
	},
	{
		Name = "Bite hold on an enemy",
		Run = function(t)
			-- a held enemy stands still and can't attack until it's thrown
			local timeline = Bite.Timeline
			local fx = t.Fx(t.Character())
			local name = t.Server("TestEnemy", TEST_ENEMY, BITE_RANGE)
			local enemy = assert(t.Enemy(name), "no test enemy")
			t.Server("TestStagger", name)
			t.Lock(enemy)
			t.Wait(0.1)
			local before = fx:GetAttribute(A.LastBiteAt)
			t.Press("Bite")
			t.Check("a staggered enemy is seized", waitFor(function()
				return fx:GetAttribute(A.LastBiteAt) ~= before
			end, 1.5))
			t.Wait(timeline.Pull + 0.25)
			local root = Parts.Root(enemy) :: BasePart
			local spot = root.Position
			local acted = false
			local deadline = os.clock() + timeline.Release - timeline.Pull - 0.45
			while os.clock() < deadline do
				acted = acted or EntityState.CurrentAction(enemy) ~= ""
				task.wait()
			end
			t.Check("it stays put", (root.Position - spot).Magnitude < 0.4, `{string.format("%.2f", (root.Position - spot).Magnitude)} studs`)
			t.Check("and never attacks while held", not acted)
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
			-- every cue's library sound still loads (one taken down or made private goes silent), and Sfx plays exactly
			-- the cue's slice
			local sounds = Registry.Sounds()
			local probes = {}
			for _, cue in sounds.Cues do
				local probe = Instance.new("Sound")
				probe.SoundId = cue.Id
				table.insert(probes, probe)
			end
			local failed = {}
			ContentProvider:PreloadAsync(probes, function(id: string, status: Enum.AssetFetchStatus)
				if status ~= Enum.AssetFetchStatus.Success then
					table.insert(failed, id)
				end
			end)
			for _, probe in probes do
				probe:Destroy()
			end
			t.Check(`every cue's sound loads ({#probes})`, #failed == 0, table.concat(failed, ", "))
			local root = t.Root()
			local function played(cueName: string): Sound?
				local sound = root:FindFirstChild(cueName)
				return if sound and sound:IsA("Sound") and sound.Playing then sound else nil
			end
			local gun = sounds.Cues.GunShot
			Sfx.Play("GunShot", root)
			local own = played("GunShot")
			local range = if own then own.PlaybackRegion else NumberRange.new(0)
			t.Check("a cue plays its own slice", own ~= nil and own.SoundId == gun.Id and math.abs(range.Min - gun.From) < 1e-3
				and math.abs(range.Max - gun.To) < 1e-3, `{range.Min}-{range.Max}`)
			if own then
				own:Destroy()
			end
			-- the audition panel's swap: the swapped slice plays, levelled by its measured loudness (6 dB quieter
			-- plays at twice the volume), and the cue's own sound comes back when the swap is cleared
			local swap = { Id = "rbxassetid://9119749145", From = 0.05, To = 0.4, Level = -20 } -- a licensed sword swish
			local function swapVolume(level: number): (number?, NumberRange?)
				Sfx.Audition("GunShot", { Id = swap.Id, From = swap.From, To = swap.To, Level = level })
				Sfx.Play("GunShot", root)
				local sound = played("GunShot")
				local volume, slice = if sound then sound.Volume else nil, if sound then sound.PlaybackRegion else nil
				if sound then
					t.Check("a swap plays the swapped sound", sound.SoundId == swap.Id, sound.SoundId)
					sound:Destroy()
				end
				return volume, slice
			end
			local quiet, slice = swapVolume(swap.Level)
			local loud = swapVolume(swap.Level + 6)
			t.Check("a swap plays its own slice", slice ~= nil and math.abs(slice.Min - swap.From) < 1e-3
				and math.abs(slice.Max - swap.To) < 1e-3)
			t.Check("slices are levelled by loudness", quiet ~= nil and loud ~= nil and math.abs(quiet / loud - 10 ^ (6 / 20)) < 0.02,
				`{quiet} vs {loud}`)
			Sfx.Audition("GunShot", nil)
			Sfx.Play("GunShot", root)
			local back = played("GunShot")
			t.Check("clearing the swap restores the cue", back ~= nil and back.SoundId == gun.Id)
			if back then
				back:Destroy()
			end
		end,
	},
	{
		Name = "Audition panel",
		Run = function(t)
			-- the Studio sound audition (AuditionController): it lists every open shortlist, Play previews a candidate
			-- and swaps it in, Pick records it, and closing gives the input back
			local shortlists = Registry.Audition()
			local bridge = ReplicatedStorage:FindFirstChild("BL_Audition") :: BindableFunction?
			if next(shortlists) == nil then
				t.Check("no open shortlists, no panel", bridge == nil)
				return
			end
			t.Check("the panel's bridge exists", bridge ~= nil)
			if not bridge then
				return
			end
			bridge:Invoke("Open")
			local panel = Layers.Get("Menus"):FindFirstChild("BL_Audition", true)
			local unlisted = {}
			for cue in shortlists do
				if not (panel and panel:FindFirstChild(cue, true)) then
					table.insert(unlisted, cue)
				end
			end
			t.Check("every open shortlist is listed", panel ~= nil and #unlisted == 0, table.concat(unlisted, ", "))
			t.Check("it owns the input while open", Focus.Current() == "Audition", Focus.Current())
			local cue = next(shortlists) :: string
			local first = shortlists[cue].Candidates[1]
			bridge:Invoke("Play", cue, 1)
			local preview = SoundService:FindFirstChild("BL_SfxPreview") :: Sound?
			t.Check("Play previews the candidate", preview ~= nil and preview.SoundId == first.Id and preview.Playing)
			bridge:Invoke("Pick", cue, 1)
			local picks = HttpService:JSONDecode(bridge:Invoke("Picks"))
			t.Check("Pick records the choice", picks[cue] ~= nil and picks[cue].Id == first.Id)
			bridge:Invoke("Reset")
			t.Check("closing gives the input back", Focus.Current() ~= "Audition", Focus.Current())
			t.Check("Reset forgets the picks", next(HttpService:JSONDecode(bridge:Invoke("Picks"))) == nil)
			if preview then
				preview:Destroy()
			end
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
			-- the block's push leaves the guard facing its attacker, so the next hit is blocked too (a push used to turn
			-- the body aside: found 2026-10-31)
			t.Wait(Combat.Knock.Time + 0.1)
			local blockedBefore = EntityState.Number(t.Fx(), A.LastBlockAt, -10)
			local hpBefore = t.Num(A.HP)
			t.Server("TestHitAfter", "Now", 0)
			local again = waitFor(function()
				return EntityState.Number(t.Fx(), A.LastBlockAt, -10) ~= blockedBefore
			end, 2)
			t.Check("a second hit after the block's push is blocked too", again and hpBefore - t.Num(A.HP) < LIGHT1 * 0.5)
			t.Hold("Guard", false)
		end,
	},
	{
		Name = "Ward",
		Run = function(t)
			-- the guard's glass buckler (Vfx/Ward): it rises with the guard ahead of the body and follows it, lowering
			-- takes it away, a block flashes it hot and a parry white-gold, it cracks as the guard's stamina runs low,
			-- and a guard break shatters it into glass shards, leaving nothing behind
			local me = t.Root().Parent :: Model
			local fx = t.Fx()
			local function raised(): Model?
				local found: Model? = nil
				waitFor(function()
					found = Ward.Shown(me)
					return found ~= nil
				end, 1)
				return found
			end
			t.Hold("Guard", true)
			local ward = raised()
			t.Check("raising the guard raises the ward", ward ~= nil)
			if not ward then
				t.Hold("Guard", false)
				return
			end
			local lens = ward:FindFirstChild("Lens") :: MeshPart
			t.Wait(0.25)
			local offset = t.Root().CFrame:PointToObjectSpace(lens.Position)
			t.Check("it stands ahead of the chest, on the off-hand side", offset.Z < -0.6 and offset.X < -0.3 and offset.Y > 0.2,
				tostring(offset))
			t.Check("at its full size", math.abs(lens.Size.X - 1.9) < 0.05, lens.Size.X)
			t.Hold("Guard", false)
			t.Check("lowering the guard takes it away", waitFor(function()
				return Ward.Shown(me) == nil
			end, 0.5))
			-- a parry: a hit landing just after the guard rises flashes the glass white-gold
			local parriedBefore = EntityState.Number(fx, A.LastParryAt, -10)
			t.Server("TestHitAfter", "Guard", Combat.Guard.PerfectWindow / 3)
			t.Hold("Guard", true)
			ward = raised()
			local parried = waitFor(function()
				return EntityState.Number(fx, A.LastParryAt, -10) ~= parriedBefore
			end, 2)
			t.Wait(0.03)
			t.Check("a parry flashes it white-gold", parried and lens.Color.G > Theme.Vfx.WardGlass.G + 0.3, tostring(lens.Color))
			-- a block flashes it hot
			t.Wait(0.4)
			local blockedBefore = EntityState.Number(fx, A.LastBlockAt, -10)
			t.Server("TestHitAfter", "Now", 0)
			local blocked = waitFor(function()
				return EntityState.Number(fx, A.LastBlockAt, -10) ~= blockedBefore
			end, 2)
			t.Wait(0.03)
			t.Check("a block flashes it hot", blocked and lens.Color.R > Theme.Vfx.WardGlass.R + 0.2, tostring(lens.Color))
			-- cracks with the guard's stamina
			local cracks = lens:FindFirstChild("CracksBack") :: Decal
			t.Wait(0.3)
			t.Check("whole, it shows no cracks", cracks.Transparency > 0.99, cracks.Transparency)
			local most = t.Num(A.StaminaMax)
			t.Server("TestGuardHit", t.Num(A.Stamina) - most * 0.2)
			waitFor(function()
				return t.Num(A.Stamina) <= most * 0.25
			end, 2)
			t.Wait(0.1)
			t.Check("low on stamina, it cracks", cracks.Transparency < 0.4, cracks.Transparency)
			-- a guard break shatters it
			local brokenBefore = EntityState.Number(fx, A.GuardBrokenAt, -10)
			t.Server("TestGuardHit", most)
			local broken = waitFor(function()
				return EntityState.Number(fx, A.GuardBrokenAt, -10) ~= brokenBefore
			end, 2)
			t.Wait(0.05)
			local shards = false
			for _, child in workspace:GetChildren() do
				for _, emitter in child:GetDescendants() do
					if emitter:IsA("ParticleEmitter") and emitter.Texture == Kit.Textures.GlassShard then
						shards = true
					end
				end
			end
			t.Check("a guard break shatters it", broken and Ward.Shown(me) == nil)
			t.Check("into glass shards", shards)
			t.Hold("Guard", false)
			local home = workspace:FindFirstChild("BL_Wards")
			t.Check("and leaves nothing behind", home == nil or #home:GetChildren() == 0)
		end,
	},
	{
		Name = "Parry",
		Run = function(t)
			local dummy = t.Dummy()
			local hp, stamina = t.Num(A.HP), t.Num(A.Stamina)
			local parriedBefore = EntityState.Number(t.Fx(), A.LastParryAt, -10)
			t.Server("TestHitAfter", "Guard", Combat.Guard.PerfectWindow / 3)
			t.Hold("Guard", true)
			local parried = waitFor(function()
				return EntityState.Number(t.Fx(), A.LastParryAt, -10) ~= parriedBefore
			end, 2)
			t.Hold("Guard", false)
			t.Check("a hit right after raising guard is parried", parried)
			t.Check("and does no damage", t.Num(A.HP) == hp)
			t.Check("and costs no stamina (owner, 2026-10-31)", t.Num(A.Stamina) >= stamina, `{stamina} -> {t.Num(A.Stamina)}`)
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

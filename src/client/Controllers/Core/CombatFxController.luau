--!strict
-- CombatFxController: combat feedback for every entity, read from the events CombatSim and the enemy brains write on
-- each entity's Humanoid (EntityState.Fx): hit flashes, call-outs (Evaded, Blocked, PARRY, Guard broken, HOWL, bite
-- heals, STAGGERED) for what's near you, the glint of an enemy noticing you, camera shakes for you, a bite's smoke and
-- wind through its hold (Vfx/BiteWind), gunshots (Vfx/Gunshot: muzzle, tracer, impact), skill projectiles, channeled
-- beams and charge telegraphs, and their sounds
-- (Audio/Sfx, cues named in Definitions/Sounds). Damage itself reads on the plates (PlateController: HP bars and the
-- running total of what you dealt), so hits pop no numbers.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local EntityState = require(Shared.Simulation.EntityState)
local Net = require(Shared.Net)
local Registry = require(Shared.Definitions.Registry)
local Sfx = require(script.Parent.Parent.Parent.Audio.Sfx)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local FloatingText = require(UI.Components.FloatingText)
local Flash = require(UI.Components.Flash)
local Vfx = script.Parent.Parent.Parent.Vfx
local Gunshot = require(Vfx.Gunshot)
local Hitstop = require(Vfx.Hitstop)
local SlashTrail = require(Vfx.SlashTrail)
local BiteWind = require(Vfx.BiteWind)
local Projectile = require(Vfx.Projectile)
local BloodBlade = require(Vfx.BloodBlade)
local LightBeam = require(Vfx.LightBeam)
local BloodCharge = require(Vfx.BloodCharge)
local FireNova = require(Vfx.FireNova)
local Parts = require(Shared.Util.Parts)
local Combat = require(Shared.Config.Combat)
local Bite = require(Shared.Simulation.Bite)
local Muzzle = require(Shared.Util.Muzzle)
local Raycast = require(Shared.Util.Raycast)
local CameraController = require(script.Parent.CameraController)
local LockOnController = require(script.Parent.LockOnController)

local A = EntityState.Attr
local num = EntityState.Number

local HEAVY_HIT = 80
local HEAL_COLOR = Theme.Colors.Heal
local CALLOUT_RANGE = 35 -- studs: call-outs show for what's this close to you (or your lock)
local BEAM_FADE = 0.12 -- seconds a beam's held sound takes to fade as it ends

local SOUNDS = Registry.Sounds()

local CombatFxController = {}

local projectiles: { [number]: Projectile.Projectile } = {}
local projectileSounds: { [number]: any } = {} -- each flying projectile's cues (Sounds.Projectiles), for its impact
local beams: { [Model]: LightBeam.Ray } = {}
local beamSounds: { [Model]: { Cues: any, Loop: Sound? } } = {}

-- The combat entity called `name` (hit events record the attacker's name), or nil.
local function entityNamed(name: any): Model?
	if type(name) ~= "string" or name == "" then
		return nil
	end
	for _, model in CollectionService:GetTagged(EntityState.Tag) do
		if model:IsA("Model") and model.Name == name then
			return model
		end
	end
	return nil
end

-- A swing's whoosh, started so it peaks as the action's hit window opens.
local function playSwing(model: Model, id: string, action: any, startedAt: number)
	local cues = SOUNDS.Actions[id]
	local root = Parts.Root(model)
	if cues and cues.Swing and action and action.Hit and root then
		local lead = action.Hit.From - (Sfx.Peak(cues.Swing) or 0)
		Sfx.Play(cues.Swing, root, lead - (time() - startedAt))
	end
end

-- A landed melee hit: the attacker's own hit cue (else the plain body hit) and a hitstop on both. What the body shows
-- is its red flash (Flash.Pulse, for every hit). No blood effects, ever (AGENTS.md rule 4: Roblox ToS). (Rounds,
-- projectiles and beams play their impacts where they land.)
local function meleeHit(model: Model, fx: Instance)
	local root = Parts.Root(model)
	if fx:GetAttribute(A.LastHitRanged) == true or not root then
		return
	end
	local attacker = entityNamed(fx:GetAttribute(A.LastHitBy))
	local cues = if attacker then SOUNDS.Actions[(EntityState.CurrentAction(attacker))] else nil
	Sfx.Play((cues and cues.Hit) or SOUNDS.Feedback.BodyHit, root)
	local heavy = num(fx, A.LastHitDamage, 0) >= Combat.Hitstop.HeavyDamage
	Hitstop.Play(if attacker then { model, attacker } else { model }, if heavy then Combat.Hitstop.Heavy else Combat.Hitstop.Light)
end

-- A reload's sound, from the moment it starts (after a burst it starts as the burst ends).
local function playReload(model: Model)
	local reloadUntil = num(model, A.ReloadUntil, 0)
	local gunId = Registry.Class(model:GetAttribute(A.ClassId)).Ranged
	local cues = gunId and SOUNDS.Weapons[gunId]
	local root = Parts.Root(model)
	if reloadUntil > 0 and cues and cues.Reload and root then
		Sfx.Play(cues.Reload, root, reloadUntil - Registry.Weapon(gunId).Reload - time())
	end
end

-- A channeled beam's sound: the charge as it starts, the held loop once it fires, the end as it stops.
local function updateBeamSound(model: Model, id: string, root: BasePart, firing: boolean)
	local state = beamSounds[model]
	if not state then
		local cues = SOUNDS.Actions[id]
		if not cues then
			return
		end
		state = { Cues = cues, Loop = nil }
		beamSounds[model] = state
		if cues.Charge then
			Sfx.Play(cues.Charge, root)
		end
	end
	assert(state)
	if firing and not state.Loop and state.Cues.Loop then
		state.Loop = Sfx.Loop(state.Cues.Loop, root)
	end
end

local function endBeamSound(model: Model)
	local state = beamSounds[model]
	if not state then
		return
	end
	beamSounds[model] = nil
	Sfx.Stop(state.Loop, BEAM_FADE)
	local root = Parts.Root(model)
	if state.Cues.End and root then
		Sfx.Play(state.Cues.End, root)
	end
end

local PROJECTILE_LOOKS: { [string]: Projectile.Look } = {
	BloodBlade = BloodBlade,
}

-- One-shot effects by the name in an action's Fx, played when the action starts.
local ACTION_FX: { [string]: { Play: (Model) -> () } } = {
	FireNova = FireNova,
}

-- Charge telegraphs by the name in an action's Hold.Fx.
local CHARGE_LOOKS: { [string]: any } = {
	BloodCharge = BloodCharge,
}
local charges: { [Model]: { Look: any, Visual: any, Release: string } } = {}

-- Draws the telegraph of every entity in a charge stance. Leaving the stance flares if the charged blow went out,
-- and just drains away if it was abandoned.
local function updateCharges()
	local now = time()
	local active: { [Model]: boolean } = {}
	for _, model in CollectionService:GetTagged(EntityState.Tag) do
		local _, action, startedAt = EntityState.CurrentAction(model)
		local hold = action and action.Hold
		local look = hold and CHARGE_LOOKS[hold.Fx]
		if look then
			active[model] = true
			local record = charges[model]
			if not record then
				record = { Look = look, Visual = look.Spawn(model), Release = hold.Release }
				charges[model] = record
			end
			local elapsed = now - startedAt
			look.Update(record.Visual, math.clamp(elapsed / action.Duration, 0, 1), elapsed >= hold.Min, os.clock())
		end
	end
	for model, record in charges do
		if not active[model] then
			local id = EntityState.CurrentAction(model)
			record.Look.Release(record.Visual, id == record.Release)
			charges[model] = nil
		end
	end
end

-- Draws the beam of every entity channeling one, from its shared muzzle to what it hits: the charge during
-- the wind-up, then the beam itself.
local function updateBeams()
	local now = time()
	local active: { [Model]: boolean } = {}
	for _, model in CollectionService:GetTagged(EntityState.Tag) do
		local id, action, startedAt = EntityState.CurrentAction(model)
		local root = Parts.Root(model)
		local beam = action and action.Beam
		local elapsed = now - startedAt
		if beam and root and elapsed < beam.To then
			active[model] = true
			local origin, direction = Muzzle.Get(root, model:GetAttribute(A.Aim))
			local hit = workspace:Raycast(origin, direction * beam.Range, Raycast.Exclude({ model }, true))
			local ray = beams[model] or LightBeam.new()
			beams[model] = ray
			local target = if hit then hit.Position else origin + direction * beam.Range
			LightBeam.Update(ray, origin, target, math.clamp(elapsed / beam.From, 0, 1), elapsed >= beam.From, os.clock())
			updateBeamSound(model, id, root, elapsed >= beam.From)
		end
	end
	for model, ray in beams do
		if not active[model] then
			LightBeam.Destroy(ray)
			beams[model] = nil
			endBeamSound(model)
		end
	end
end

local player = Players.LocalPlayer

local function isMe(model: Model?): boolean
	return model ~= nil and model == player.Character
end

-- A bite's beat (Vfx/BiteWind) on top of its smoke and wind: the victim's red flash at the fangs (the hit feedback, never
-- blood), and for the two bodies' own players the camera: a kick at the seize and the fangs, a low rumble through the
-- drain that heaves with each pulse, a hard shake at the release.
local function biteBeat(hold: BiteWind.Hold, beat: string)
	local mine = isMe(hold.Biter) or isMe(hold.Victim)
	local cue = (SOUNDS.Actions[Bite.HoldAction] or {})[beat] -- the release's sound is the hold's Hit (meleeHit)
	local root = Parts.Root(hold.Victim) or Parts.Root(hold.Biter)
	if cue and root then
		Sfx.Play(cue, root)
	end
	if beat == "Seize" and mine then
		CameraController.Shake(0.8, 14, 0.2)
	elseif beat == "Fangs" then
		if hold.Victim then
			Flash.Pulse(hold.Victim, Theme.Colors.Health)
		end
		if mine then
			CameraController.Shake(1.6, 12, 0.35)
			CameraController.Rumble(true)
		end
	elseif beat == "Pulse" and mine then
		CameraController.Shake(0.45, 9, 0.15)
	elseif beat == "Release" and mine then
		CameraController.Rumble(false)
		CameraController.Shake(2.4, 10, 0.5)
	end
end

local bites: { [Model]: BiteWind.Hold } = {}

-- Drives the smoke and wind of every bite being held, from each hold's own clock; a hold that ends (released or broken)
-- stops its drain.
local function updateBites()
	local now = time()
	local active: { [Model]: boolean } = {}
	for _, model in CollectionService:GetTagged(EntityState.Tag) do
		local id, _, startedAt = EntityState.CurrentAction(model)
		if id == Bite.HoldAction and model:IsA("Model") then
			active[model] = true
			local hold = bites[model]
			if not hold then
				hold = BiteWind.Begin(model, entityNamed(EntityState.Fx(model):GetAttribute(A.BiteVictim)), now - startedAt)
				bites[model] = hold
			end
			for _, beat in BiteWind.Update(hold, now - startedAt) do
				biteBeat(hold, beat)
			end
		end
	end
	for model, hold in bites do
		if not active[model] then
			BiteWind.Finish(hold)
			bites[model] = nil
			if isMe(hold.Biter) or isMe(hold.Victim) then
				CameraController.Rumble(false)
			end
		end
	end
end

-- Call-outs only for what concerns you: yourself, your lock, or anything within CALLOUT_RANGE.
local function near(model: Model): boolean
	if isMe(model) or model == LockOnController.GetTarget() then
		return true
	end
	local mine, theirs = Parts.Root(player.Character), Parts.Root(model)
	return mine ~= nil and theirs ~= nil and (mine.Position - theirs.Position).Magnitude <= CALLOUT_RANGE
end

-- On your own character, the server's combat results (hits, blocks, bites, stagger...) update its attributes without
-- firing their change signals (Server Authority: this client simulates that character itself; tested 2026-10-31).
-- So every handler is a watch that runs once per new value, whichever notices it first: the change signal, or the
-- per-frame check of your own character (pollOwn).
type Watch = { Instance: Instance, Attribute: string, Last: any, Handler: () -> () }
local watches: { [Model]: { Watch } } = setmetatable({}, { __mode = "k" }) :: any

local function fire(entry: Watch)
	local value = entry.Instance:GetAttribute(entry.Attribute)
	if value ~= entry.Last then
		entry.Last = value
		entry.Handler()
	end
end

local function listen(model: Model, instance: Instance, attribute: string, handler: () -> ())
	local entry: Watch = { Instance = instance, Attribute = attribute, Last = instance:GetAttribute(attribute), Handler = handler }
	local list = watches[model] or {}
	watches[model] = list
	table.insert(list, entry)
	instance:GetAttributeChangedSignal(attribute):Connect(function()
		fire(entry)
	end)
end

local function pollOwn()
	local list = player.Character and watches[player.Character]
	if list then
		for _, entry in list do
			fire(entry)
		end
	end
end

local function watch(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local fx = EntityState.Fx(model)
	listen(model, model, A.ActionStart, function()
		local id, action, startedAt = EntityState.CurrentAction(model)
		local look = action and action.Fx and ACTION_FX[action.Fx]
		if look then
			look.Play(model)
		end
		playSwing(model, id, action, startedAt)
		SlashTrail.Play(model, id, action, startedAt)
	end)
	listen(model, model, A.ReloadUntil, function()
		playReload(model)
	end)
	local function on(name: string, handler: () -> ())
		listen(model, fx, A[name], handler)
	end

	on("LastHitAt", function()
		local damage = num(fx, A.LastHitDamage, 0)
		Flash.Pulse(model, Theme.Colors.Health)
		meleeHit(model, fx)
		if isMe(model) then
			CameraController.Shake(2.2, 12, 0.3)
		elseif fx:GetAttribute(A.LastHitBy) == (player.Character and player.Character.Name) then
			CameraController.Shake(if damage >= HEAVY_HIT then 1.6 else 0.6, 14, 0.15)
		end
	end)
	on("LastEvadedAt", function()
		if near(model) then
			FloatingText.Pop(model, "Evaded", Theme.Colors.Accent)
		end
	end)
	on("LastBlockAt", function()
		local root = Parts.Root(model)
		if root then
			Sfx.Play(SOUNDS.Feedback.Block, root)
		end
		if near(model) then
			FloatingText.Pop(model, "Blocked", Theme.Colors.TextMuted)
		end
		if isMe(model) then
			CameraController.Shake(0.8, 16, 0.12)
		end
	end)
	on("LastParryAt", function()
		Flash.Pulse(model, Theme.Colors.Accent)
		local root = Parts.Root(model)
		if root then
			Sfx.Play(SOUNDS.Feedback.Parry, root)
		end
		if near(model) then
			FloatingText.Pop(model, "PARRY", Theme.Colors.Accent, true)
		end
		if isMe(model) then
			CameraController.Shake(1.4, 18, 0.2)
		end
	end)
	on("LastHowlAt", function()
		if near(model) then
			FloatingText.Pop(model, "HOWL", Theme.Colors.Warm, true)
		end
		if isMe(model) then
			CameraController.Shake(1.8, 8, 0.35)
		end
	end)
	on("GuardBrokenAt", function()
		if near(model) then
			FloatingText.Pop(model, "Guard broken", Theme.Colors.Health, true)
		end
	end)
	on("BiteReleaseAt", function() -- a bite's hold ended: what it drank shows once
		local healed = num(fx, A.LastBiteHeal, 0)
		if healed > 0 and near(model) then
			FloatingText.Pop(model, `+{healed}`, HEAL_COLOR, true)
		end
	end)
	on("AlertAt", function()
		if player.Character and fx:GetAttribute(A.AlertTarget) == player.Character.Name then
			FloatingText.Glint(model)
		end
	end)
	-- A stagger starts when StaggerUntil jumps well past the last hit/howl (simulation times). A bite ending
	-- the stagger sets it back to the hit time, which doesn't count.
	listen(model, model, A.StaggerUntil, function()
		local latest = math.max(num(fx, A.LastHitAt, 0), num(fx, A.LastHowlAt, 0))
		if num(model, A.StaggerUntil, 0) > latest + 0.5 and near(model) then
			FloatingText.Pop(model, "STAGGERED", Theme.Colors.Warm, true)
		end
	end)
end

function CombatFxController.Start()
	for _, model in CollectionService:GetTagged(EntityState.Tag) do
		watch(model)
	end
	CollectionService:GetInstanceAddedSignal(EntityState.Tag):Connect(watch)
	Sfx.Preload()
	Net.Client.On("ShotFx", function(shooter: Model?, origin: Vector3, hitPosition: Vector3, normal: Vector3?, hitBody: boolean?)
		local impact = if hitBody then SOUNDS.Feedback.BodyHit elseif normal then SOUNDS.Feedback.SurfaceHit else nil
		local muzzle = Gunshot.Play(shooter, origin, hitPosition, normal, hitBody, function()
			if impact then
				Sfx.Play(impact, hitPosition)
			end
		end)
		local cues = if shooter then SOUNDS.Actions[(EntityState.CurrentAction(shooter))] else nil
		if cues and cues.Shot then
			Sfx.Play(cues.Shot, muzzle)
		end
	end)
	Net.Client.On("ProjectileFx", function(id: number, visual: string, origin: Vector3, direction: Vector3, speed: number, range: number)
		projectiles[id] = Projectile.new(PROJECTILE_LOOKS[visual] or BloodBlade, origin, direction, speed, range)
		local cues = SOUNDS.Projectiles[visual]
		projectileSounds[id] = cues
		if cues and cues.Cast then
			Sfx.Play(cues.Cast, origin)
		end
	end)
	Net.Client.On("ProjectileEnd", function(id: number, position: Vector3)
		local projectile = projectiles[id]
		if projectile then
			Projectile.Finish(projectile, position)
			projectiles[id] = nil
		end
		local cues = projectileSounds[id]
		projectileSounds[id] = nil
		if cues and cues.Impact then
			Sfx.Play(cues.Impact, position)
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		for id, projectile in projectiles do
			if not Projectile.Step(projectile, dt) then
				projectiles[id] = nil
				projectileSounds[id] = nil -- flew out of range: no impact to hear
			end
		end
		updateBeams()
		updateCharges()
		updateBites()
		pollOwn()
	end)
end

return CombatFxController

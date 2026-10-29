--!strict
-- CombatFxController: combat feedback for every entity, read from the events CombatSim writes on each entity's
-- Humanoid (EntityState.Fx): damage numbers and flashes, Evaded, Blocked, PARRY, Guard broken, HOWL, bite heals,
-- STAGGERED, camera shakes for you, gun tracers, skill projectiles, channeled beams and charge telegraphs.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local EntityState = require(Shared.Simulation.EntityState)
local Net = require(Shared.Net)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local FloatingText = require(UI.Components.FloatingText)
local Flash = require(UI.Components.Flash)
local Tracer = require(UI.Components.Tracer)
local Vfx = script.Parent.Parent.Parent.Vfx
local Projectile = require(Vfx.Projectile)
local BloodBlade = require(Vfx.BloodBlade)
local LightBeam = require(Vfx.LightBeam)
local BloodCharge = require(Vfx.BloodCharge)
local FireNova = require(Vfx.FireNova)
local Parts = require(Shared.Util.Parts)
local Muzzle = require(Shared.Util.Muzzle)
local Raycast = require(Shared.Util.Raycast)
local CameraController = require(script.Parent.CameraController)

local A = EntityState.Attr
local num = EntityState.Number

local HEAVY_HIT = 80
local HEAL_COLOR = Theme.Colors.Heal

local CombatFxController = {}

local projectiles: { [number]: Projectile.Projectile } = {}
local beams: { [Model]: LightBeam.Ray } = {}

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
		local _, action, startedAt = EntityState.CurrentAction(model)
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
		end
	end
	for model, ray in beams do
		if not active[model] then
			LightBeam.Destroy(ray)
			beams[model] = nil
		end
	end
end

local player = Players.LocalPlayer

local function isMe(model: Model): boolean
	return model == player.Character
end

local function watch(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local fx = EntityState.Fx(model)
	model:GetAttributeChangedSignal(A.ActionStart):Connect(function()
		local _, action = EntityState.CurrentAction(model)
		local look = action and action.Fx and ACTION_FX[action.Fx]
		if look then
			look.Play(model)
		end
	end)
	local function on(name: string, handler: () -> ())
		fx:GetAttributeChangedSignal(A[name]):Connect(handler)
	end

	on("LastHitAt", function()
		local damage = num(fx, A.LastHitDamage, 0)
		Flash.Pulse(model, Theme.Colors.Health)
		FloatingText.Pop(model, tostring(math.floor(damage)), Theme.Colors.Text, damage >= HEAVY_HIT)
		if isMe(model) then
			CameraController.Shake(2.2, 12, 0.3)
		elseif fx:GetAttribute(A.LastHitBy) == (player.Character and player.Character.Name) then
			CameraController.Shake(if damage >= HEAVY_HIT then 1.6 else 0.6, 14, 0.15)
		end
	end)
	on("LastEvadedAt", function()
		FloatingText.Pop(model, "Evaded", Theme.Colors.Accent)
	end)
	on("LastBlockAt", function()
		FloatingText.Pop(model, "Blocked", Theme.Colors.TextMuted)
		if isMe(model) then
			CameraController.Shake(0.8, 16, 0.12)
		end
	end)
	on("LastParryAt", function()
		Flash.Pulse(model, Theme.Colors.Accent)
		FloatingText.Pop(model, "PARRY", Theme.Colors.Accent, true)
		if isMe(model) then
			CameraController.Shake(1.4, 18, 0.2)
		end
	end)
	on("LastHowlAt", function()
		FloatingText.Pop(model, "HOWL", Theme.Colors.Warm, true)
		if isMe(model) then
			CameraController.Shake(1.8, 8, 0.35)
		end
	end)
	on("GuardBrokenAt", function()
		FloatingText.Pop(model, "Guard broken", Theme.Colors.Health, true)
	end)
	on("LastBiteAt", function()
		FloatingText.Pop(model, `+{num(fx, A.LastBiteHeal, 0)}`, HEAL_COLOR, true)
		if isMe(model) then
			CameraController.Shake(2, 10, 0.3)
		end
	end)
	-- A stagger starts when StaggerUntil jumps well past the last hit/howl (simulation times). A bite ending
	-- the stagger sets it back to the hit time, which doesn't count.
	model:GetAttributeChangedSignal(A.StaggerUntil):Connect(function()
		local latest = math.max(num(fx, A.LastHitAt, 0), num(fx, A.LastHowlAt, 0))
		if num(model, A.StaggerUntil, 0) > latest + 0.5 then
			FloatingText.Pop(model, "STAGGERED", Theme.Colors.Warm, true)
		end
	end)
end

function CombatFxController.Start()
	for _, model in CollectionService:GetTagged(EntityState.Tag) do
		watch(model)
	end
	CollectionService:GetInstanceAddedSignal(EntityState.Tag):Connect(watch)
	Net.Client.On("ShotFx", function(_shooter: Model, origin: Vector3, hitPosition: Vector3)
		Tracer.Draw(origin, hitPosition, Theme.Colors.Warm)
	end)
	Net.Client.On("ProjectileFx", function(id: number, visual: string, origin: Vector3, direction: Vector3, speed: number, range: number)
		projectiles[id] = Projectile.new(PROJECTILE_LOOKS[visual] or BloodBlade, origin, direction, speed, range)
	end)
	Net.Client.On("ProjectileEnd", function(id: number, position: Vector3)
		local projectile = projectiles[id]
		if projectile then
			Projectile.Finish(projectile, position)
			projectiles[id] = nil
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		for id, projectile in projectiles do
			if not Projectile.Step(projectile, dt) then
				projectiles[id] = nil
			end
		end
		updateBeams()
		updateCharges()
	end)
end

return CombatFxController

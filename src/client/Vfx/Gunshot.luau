--!strict
-- Gunshot: one round's effect (docs/combat-rework.md, C1.1), from our rendered sprites (tools/blender/vfx_sprites.py).
--   Muzzle: a star flash (a random one of four) with a short flame cone along the barrel, a light for a few frames,
--           and a wisp of gun smoke that drifts and lingers.
--   Tracer: a short pale streak flying from the muzzle to where the round stopped, at TRACER_SPEED; the impact shows
--           when it lands.
--   Surface: hot sparks thrown off along the surface's facing, falling; dust the colour of the surface; a brief light.
--   Body: a dark, wet mist plume thrown back toward the shooter and up (blood-red to near-black, alpha-blended, never
--         glowing), with a few hot red streaks as its edge: a hit, never a wound (no gore).
--   Miss: only the tracer.
-- Play(shooter, origin, hitPosition, normal?, hitBody?, onImpact?): the muzzle is the shooter's held gun (its Muzzle
-- attachment) when it has one, else `origin`, where the server's ray left. Returns that muzzle position; onImpact
-- runs when the round lands (sounds use it to stay in step with the picture).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Parent.UI.Theme)
local Equipment = require(ReplicatedStorage.Shared.Simulation.Equipment)
local Raycast = require(ReplicatedStorage.Shared.Util.Raycast)

local T = Kit.Textures
local V = Theme.Vfx

local TRACER_SPEED = 700 -- studs a second
local TRACER_LENGTH = 3.5
local TRACER_WIDTH = 0.07
local CONE_LENGTH = 0.9
local FLASH_TIME = 0.05
local SURFACE_PROBE = 0.25 -- how far the dust probe starts off the surface
local DUST_TINT = 0.5 -- how far dust leans toward the surface's own colour
local BODY_LIFT = 0.8 -- how much a body hit's spray rises (added to the way back toward the shooter)
local SMOKE_LIGHT = 0.5 -- smoke and dust half lit by the scene: fully lit, they turn to black blots at night
local HANDS = { "Left", "Right" }

local Gunshot = {}

local function muzzleOf(shooter: Model?): Attachment?
	if not shooter then
		return nil
	end
	for _, hand in HANDS do
		local held = Equipment.Held(shooter, hand)
		local muzzle = held and held:FindFirstChild("Muzzle", true)
		if muzzle and muzzle:IsA("Attachment") then
			return muzzle
		end
	end
	return nil
end

local function point(anchor: BasePart, position: Vector3): Attachment
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = anchor
	return attachment
end

-- A camera-facing beam between two moving points; `step(alpha)` places them, then it's removed.
local function beam(texture: string, color: Color3, width0: number, width1: number, duration: number, place: (Attachment, Attachment, number) -> ())
	local anchor = Kit.Anchor(CFrame.identity)
	local a0, a1 = point(anchor, Vector3.zero), point(anchor, Vector3.zero)
	local b = Instance.new("Beam")
	b.Attachment0, b.Attachment1 = a0, a1
	b.Texture = texture
	b.TextureMode = Enum.TextureMode.Stretch
	b.Color = ColorSequence.new(color)
	b.LightEmission, b.LightInfluence = 1, 0
	b.FaceCamera = true
	b.Segments = 1
	b.Width0, b.Width1 = width0, width1
	b.Transparency = NumberSequence.new(0)
	place(a0, a1, 0)
	b.Parent = anchor
	Kit.Tween(duration, function(alpha)
		place(a0, a1, alpha)
	end, function()
		anchor:Destroy()
	end)
end

local function muzzleEffect(muzzle: Vector3, direction: Vector3)
	Kit.Burst(CFrame.lookAt(muzzle, muzzle + direction), {
		{ -- the flash, facing the camera
			Count = 1,
			Texture = T.MuzzleFlash,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid2x2,
			FlipbookMode = Enum.ParticleFlipbookMode.Random,
			LightEmission = 1,
			Brightness = 2,
			Size = Kit.Seq({ { 0, 0.9 }, { 1, 0.6 } }),
			Lifetime = NumberRange.new(FLASH_TIME),
			Rotation = NumberRange.new(0, 360),
			ZOffset = 0.3,
		},
		{ -- a wisp of gun smoke drifting off along the shot, rising
			Count = 1,
			Texture = T.SmokePuff,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
			FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
			Color = ColorSequence.new(V.GunSmoke),
			LightInfluence = SMOKE_LIGHT,
			Transparency = Kit.Seq({ { 0, 0.55 }, { 1, 1 } }),
			Size = Kit.Seq({ { 0, 0.35 }, { 1, 1.3 } }),
			Lifetime = NumberRange.new(0.7, 1),
			Speed = NumberRange.new(1.5, 2.5),
			EmissionDirection = Enum.NormalId.Front,
			SpreadAngle = Vector2.new(15, 15),
			Acceleration = Vector3.new(0, 1.2, 0),
			Drag = 3,
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-30, 30),
		},
	})
	local tip = muzzle + direction * CONE_LENGTH
	beam(T.MuzzleCone, Color3.new(1, 1, 1), 0.45, 0.12, FLASH_TIME, function(a0, a1)
		a0.WorldPosition, a1.WorldPosition = muzzle, tip
	end)
	Kit.Flash(muzzle, V.FireCore, 3, 9, 0.06)
end

-- The streak flies from `from` to `to`; `arrive` runs when its head gets there (the impact shows then, not before).
local function tracer(from: Vector3, to: Vector3, arrive: () -> ())
	local path = to - from
	local distance = path.Magnitude
	if distance < 0.5 then
		arrive()
		return
	end
	local unit = path / distance
	local travel = distance + TRACER_LENGTH -- the head arrives, then the tail catches up
	local arrived = false
	beam(T.TracerStreak, V.Tracer, TRACER_WIDTH, TRACER_WIDTH, travel / TRACER_SPEED, function(tail, head, alpha)
		local reached = alpha * travel
		head.WorldPosition = from + unit * math.min(reached, distance)
		tail.WorldPosition = from + unit * math.clamp(reached - TRACER_LENGTH, 0, distance)
		if not arrived and reached >= distance then
			arrived = true
			arrive()
		end
	end)
end

-- The colour a round would kick up from the surface at `position` (dust blended toward that surface's colour).
local function dustColor(position: Vector3, normal: Vector3): Color3
	local hit = workspace:Raycast(position + normal * SURFACE_PROBE, -normal * SURFACE_PROBE * 2, Raycast.Exclude({}, true))
	return if hit then V.Dust:Lerp(hit.Instance.Color, DUST_TINT) else V.Dust
end

local function surfaceHit(position: Vector3, normal: Vector3)
	Kit.Burst(CFrame.lookAt(position, position + normal), {
		{ -- hot sparks thrown off the surface, falling
			Count = 8,
			Texture = T.Spark,
			Orientation = Enum.ParticleOrientation.VelocityParallel,
			Color = Kit.Colors({ { 0, V.FireCore }, { 0.5, V.Fire }, { 1, V.FireDeep } }),
			LightEmission = 1,
			Brightness = 2,
			Size = Kit.Seq({ { 0, 0.26 }, { 1, 0.08 } }),
			Lifetime = NumberRange.new(0.12, 0.28),
			Speed = NumberRange.new(14, 26),
			EmissionDirection = Enum.NormalId.Front,
			SpreadAngle = Vector2.new(55, 55),
			Acceleration = Vector3.new(0, -70, 0),
			Drag = 2,
		},
		{ -- dust the colour of what was hit
			Count = 2,
			Texture = T.SmokePuff,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
			FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
			Color = ColorSequence.new(dustColor(position, normal)),
			LightInfluence = SMOKE_LIGHT,
			Transparency = Kit.Seq({ { 0, 0.5 }, { 1, 1 } }),
			Size = Kit.Seq({ { 0, 0.5 }, { 1, 1.6 } }),
			Lifetime = NumberRange.new(0.45, 0.7),
			Speed = NumberRange.new(2, 4),
			EmissionDirection = Enum.NormalId.Front,
			SpreadAngle = Vector2.new(30, 30),
			Drag = 5,
			Rotation = NumberRange.new(0, 360),
		},
	})
	Kit.Flash(position + normal * 0.3, V.Fire, 1.4, 5, 0.06)
end

local function bodyHit(position: Vector3, direction: Vector3)
	-- thrown back out of the wound side and upward, so the shooter sees it (along the shot, the body hides it)
	local spray = (-direction + Vector3.yAxis * BODY_LIFT).Unit
	Kit.Burst(CFrame.lookAt(position, position + spray), {
		{ -- a dark, wet mist plume (alpha-blended: darkness can't come from glow)
			Count = 2,
			Texture = T.MistBurst,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
			FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
			Orientation = Enum.ParticleOrientation.VelocityParallel,
			Color = Kit.Colors({ { 0, V.Blood }, { 0.25, V.BloodWet }, { 0.6, V.BloodDeep }, { 1, V.BloodDark } }),
			Transparency = Kit.Seq({ { 0, 0 }, { 0.6, 0.3 }, { 1, 1 } }),
			Size = Kit.Seq({ { 0, 1.6 }, { 1, 2.8 } }),
			Lifetime = NumberRange.new(0.35, 0.5),
			Speed = NumberRange.new(1.5, 3),
			EmissionDirection = Enum.NormalId.Front,
			SpreadAngle = Vector2.new(35, 35),
			Drag = 4,
			ZOffset = 0.5,
		},
		{ -- a few red streaks
			Count = 6,
			Texture = T.Spark,
			Orientation = Enum.ParticleOrientation.VelocityParallel,
			Color = Kit.Colors(V.BloodCore, V.Blood),
			LightEmission = 0.4,
			Size = Kit.Seq({ { 0, 0.45 }, { 1, 0.2 } }),
			Lifetime = NumberRange.new(0.12, 0.22),
			Speed = NumberRange.new(10, 18),
			EmissionDirection = Enum.NormalId.Front,
			SpreadAngle = Vector2.new(50, 50),
			Acceleration = Vector3.new(0, -50, 0),
			ZOffset = 0.5,
		},
		{ -- dark mist settling behind
			Count = 1,
			Texture = T.SmokePuff,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
			FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
			Color = ColorSequence.new(V.BloodDark),
			Transparency = Kit.Seq({ { 0, 0.5 }, { 1, 1 } }),
			Size = Kit.Seq({ { 0, 0.8 }, { 1, 1.6 } }),
			Lifetime = NumberRange.new(0.5, 0.6),
			Speed = NumberRange.new(0.5, 1),
			Drag = 3,
			Rotation = NumberRange.new(0, 360),
		},
	})
end

function Gunshot.Play(
	shooter: Model?,
	origin: Vector3,
	hitPosition: Vector3,
	normal: Vector3?,
	hitBody: boolean?,
	onImpact: (() -> ())?
): Vector3
	local muzzle = muzzleOf(shooter)
	local from = if muzzle then muzzle.WorldPosition else origin
	local path = hitPosition - from
	local direction = if path.Magnitude > 1e-3 then path.Unit else Vector3.zAxis
	muzzleEffect(from, direction)
	tracer(from, hitPosition, function()
		if hitBody then
			bodyHit(hitPosition, direction)
		elseif normal then
			surfaceHit(hitPosition, normal)
		end
		if onImpact then
			onImpact()
		end
	end)
	return from
end

return Gunshot

--!strict
-- Gunshot: one round's effect (docs/combat-rework.md, C1.1, "The burst, rebuilt from the reference"), from our drawn
-- and rendered textures (Vfx/Textures).
--   Ray:     the round's whole path, from the muzzle to where it stopped, shown at once: a white-hot core, an orange-gold
--            body bright nearly edge to edge (RayBand) and energy strands running along it. It fades from the gun's end
--            first, its tail running out toward the target, over RAY_TIME; a burst's rounds overlap into several rays.
--   Muzzle:  an orange-white bloom that swallows the hand, the star flash (a random one of four), a side flame along the
--            barrel, a few hot sparks thrown forward, a light for a few frames, and a wisp of gun smoke that lingers.
--   Casing:  a brass casing ejected up and to the gun's right, spinning: a small real part that falls, bounces and goes.
--   Surface: a small bloom where the ray ends, hot sparks thrown off along the surface's facing, falling; dust the
--            colour of the surface; a brief light.
--   Body:    nothing here: the struck body flashes red with a white outline (UI/Components/Flash, from the hit event).
--            No blood effects, ever (AGENTS.md rule 4: Roblox ToS).
--   Miss:    the ray alone, out to the weapon's range.
-- Play(shooter, origin, hitPosition, normal?, hitBody?, onImpact?): the muzzle is the shooter's held gun (its Muzzle
-- attachment) when it has one, else `origin`, where the server's ray left. Returns that muzzle position; onImpact runs
-- as the round lands (sounds use it), which is at once: the ray is the whole path.

local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Parent.UI.Theme)
local Equipment = require(ReplicatedStorage.Shared.Simulation.Equipment)
local Raycast = require(ReplicatedStorage.Shared.Util.Raycast)

local T = Kit.Textures
local V = Theme.Vfx

local RAY_TIME = 0.18 -- seconds a ray takes to fade (the reference's last 4-5 frames at 30 fps)
local CORE_SHARE = 0.55 -- the white core is gone this far into the fade
local TAIL_RUN = 0.85 -- how far toward the target the ray's gun end runs as it fades (a share of the path)
local RAY = { -- widths at the muzzle and at the far end (studs), brightness: finger-thick from behind the shooter
	Core = { 0.12, 0.1, 3 },
	Glow = { 0.5, 0.42, 2 }, -- RayBand: bright across most of its width
	Strands = { 0.4, 0.34, 1.6 },
}
local STRAND_LENGTH, STRAND_SPEED = 3, 6 -- studs one strand tile covers along the ray, how fast they run (tiles/s)
local CONE_LENGTH = 1.4
local FLASH_TIME = 0.06
local BLOOM_TIME = 0.07
local MUZZLE_LIGHT = { Brightness = 3.5, Range = 9 } -- lights the shooter and close walls, not a pool on the floor
local CASING = {
	Size = Vector3.new(0.24, 0.09, 0.09), -- a cylinder along its X
	Port = CFrame.new(0.1, 0.05, 1.0), -- from the muzzle: back along the barrel to just behind the crystal, on the right
	Right = NumberRange.new(7, 10), -- studs/s out to the gun's right
	Up = NumberRange.new(6, 9),
	Back = NumberRange.new(0, 1.5),
	Spin = 25, -- radians/s at most, about each axis
	Life = 1.6,
}
local SURFACE_PROBE = 0.25 -- how far the dust probe starts off the surface
local DUST_TINT = 0.5 -- how far dust leans toward the surface's own colour
local SMOKE_LIGHT = 0.5 -- smoke and dust half lit by the scene: fully lit, they turn to black blots at night
local HANDS = { "Left", "Right" }

local Gunshot = {}

local random = Random.new()

-- A textured Beam draws as a solid band until its texture loads (VFX rules): load the ray's textures before any shot.
task.spawn(function()
	local probes = {}
	for _, texture in { T.TracerStreak, T.RayBand, T.BeamEnergy, T.MuzzleCone } do
		local decal = Instance.new("Decal")
		decal.Texture = texture
		table.insert(probes, decal)
	end
	ContentProvider:PreloadAsync(probes)
	for _, decal in probes do
		decal:Destroy()
	end
end)

local function muzzleOf(shooter: Model?): Attachment?
	if not shooter then
		return nil
	end
	for _, hand in HANDS do
		local muzzle = Equipment.Point(Equipment.Held(shooter, hand), Equipment.Points.Muzzle)
		if muzzle then
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

local function newBeam(a0: Attachment, a1: Attachment, texture: string, color: ColorSequence, widths: { number }): Beam
	local b = Instance.new("Beam")
	b.Attachment0, b.Attachment1 = a0, a1
	b.Texture = texture
	b.Color = color
	b.LightEmission, b.LightInfluence = 1, 0
	b.Brightness = widths[3] or 1
	b.FaceCamera = true
	b.Segments = 1
	b.Width0, b.Width1 = widths[1], widths[2]
	b.Transparency = NumberSequence.new(0)
	b.Parent = a0.Parent
	return b
end

-- The round's path, all at once, fading from the gun's end.
local function ray(from: Vector3, to: Vector3)
	local path = to - from
	if path.Magnitude < 0.5 then
		return
	end
	local anchor = Kit.Anchor(CFrame.identity)
	local tail, head = point(anchor, from), point(anchor, to)
	local core = newBeam(tail, head, T.TracerStreak, ColorSequence.new(V.RadianceCore), RAY.Core)
	core.TextureMode = Enum.TextureMode.Stretch
	local glow = newBeam(tail, head, T.RayBand, Kit.Colors(V.Radiance, V.RadianceDeep), RAY.Glow)
	glow.TextureMode = Enum.TextureMode.Stretch
	local strands = newBeam(tail, head, T.BeamEnergy, Kit.Colors(V.RadianceCore, V.Radiance), RAY.Strands)
	strands.TextureMode = Enum.TextureMode.Wrap
	strands.TextureLength = STRAND_LENGTH
	strands.TextureSpeed = STRAND_SPEED
	Kit.Tween(RAY_TIME, function(alpha)
		tail.WorldPosition = from + path * (TAIL_RUN * alpha ^ 1.5)
		local fade = 1 - alpha ^ 2 -- holds near full width, then drops at the end
		local coreFade = math.max(0, 1 - alpha / CORE_SHARE)
		core.Width0, core.Width1 = RAY.Core[1] * coreFade, RAY.Core[2] * coreFade
		glow.Width0, glow.Width1 = RAY.Glow[1] * fade, RAY.Glow[2] * (0.4 + 0.6 * fade)
		strands.Width0, strands.Width1 = RAY.Strands[1] * fade, RAY.Strands[2] * fade
		local transparency = NumberSequence.new(alpha ^ 1.6)
		glow.Transparency, strands.Transparency = transparency, transparency
	end, function()
		anchor:Destroy()
	end)
end

local function muzzleEffect(muzzle: Vector3, direction: Vector3)
	Kit.Burst(CFrame.lookAt(muzzle, muzzle + direction), {
		{ -- the bloom that swallows the hand
			Count = 1,
			Texture = T.SoftGlow,
			LightEmission = 1,
			Brightness = 2,
			Color = Kit.Colors(V.FireCore, V.Radiance),
			Size = Kit.Seq({ { 0, 2.6 }, { 1, 1.6 } }),
			Transparency = Kit.Seq({ { 0, 0.05 }, { 1, 1 } }),
			Lifetime = NumberRange.new(BLOOM_TIME),
			ZOffset = 0.2,
		},
		{ -- the star flash, facing the camera
			Count = 1,
			Texture = T.MuzzleFlash,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid2x2,
			FlipbookMode = Enum.ParticleFlipbookMode.Random,
			LightEmission = 1,
			Brightness = 2.5,
			Size = Kit.Seq({ { 0, 1.6 }, { 1, 1.1 } }),
			Lifetime = NumberRange.new(FLASH_TIME),
			Rotation = NumberRange.new(0, 360),
			ZOffset = 0.3,
		},
		{ -- hot sparks thrown forward with the round
			Count = 4,
			Texture = T.Spark,
			Orientation = Enum.ParticleOrientation.VelocityParallel,
			Color = Kit.Colors(V.FireCore, V.Fire),
			LightEmission = 1,
			Brightness = 2,
			Size = Kit.Seq({ { 0, 0.22 }, { 1, 0.05 } }),
			Lifetime = NumberRange.new(0.08, 0.16),
			Speed = NumberRange.new(22, 36),
			EmissionDirection = Enum.NormalId.Front,
			SpreadAngle = Vector2.new(22, 22),
			Drag = 4,
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
	-- the side flame along the barrel
	local anchor = Kit.Anchor(CFrame.identity)
	local base, tip = point(anchor, muzzle), point(anchor, muzzle + direction * CONE_LENGTH)
	local cone = newBeam(base, tip, T.MuzzleCone, ColorSequence.new(Color3.new(1, 1, 1)), { 0.6, 0.15, 1.5 })
	cone.TextureMode = Enum.TextureMode.Stretch
	Debris:AddItem(anchor, FLASH_TIME / Kit.TimeScale)
	Kit.Flash(muzzle, V.FireCore, MUZZLE_LIGHT.Brightness, MUZZLE_LIGHT.Range, BLOOM_TIME)
end

-- A spent casing thrown out of the gun's right side, spinning, left to fall and bounce.
local function casing(muzzle: Attachment)
	local gun = muzzle.WorldCFrame
	local part = Instance.new("Part")
	part.Name = "BL_Casing"
	part.Shape = Enum.PartType.Cylinder
	part.Size = CASING.Size
	part.Material = Enum.Material.Metal
	part.Color = V.Brass
	part.CanQuery, part.CanTouch, part.CastShadow = false, false, false
	part.CFrame = gun * CASING.Port * CFrame.Angles(0, math.rad(90), 0) -- lying across the barrel
	part.AssemblyLinearVelocity = gun.RightVector * random:NextNumber(CASING.Right.Min, CASING.Right.Max)
		+ gun.UpVector * random:NextNumber(CASING.Up.Min, CASING.Up.Max)
		- gun.LookVector * random:NextNumber(CASING.Back.Min, CASING.Back.Max)
	part.AssemblyAngularVelocity = Vector3.new(random:NextNumber(-1, 1), random:NextNumber(-1, 1), random:NextNumber(-1, 1))
		* CASING.Spin
	part.Parent = workspace
	Debris:AddItem(part, CASING.Life)
end

-- The colour a round would kick up from the surface at `position` (dust blended toward that surface's colour).
local function dustColor(position: Vector3, normal: Vector3): Color3
	local hit = workspace:Raycast(position + normal * SURFACE_PROBE, -normal * SURFACE_PROBE * 2, Raycast.Exclude({}, true))
	return if hit then V.Dust:Lerp(hit.Instance.Color, DUST_TINT) else V.Dust
end

local function surfaceHit(position: Vector3, normal: Vector3)
	Kit.Burst(CFrame.lookAt(position, position + normal), {
		{ -- a small bloom where the ray ends
			Count = 1,
			Texture = T.SoftGlow,
			LightEmission = 1,
			Brightness = 2,
			Color = Kit.Colors(V.FireCore, V.Radiance),
			Size = Kit.Seq({ { 0, 1.4 }, { 1, 0.8 } }),
			Transparency = Kit.Seq({ { 0, 0.1 }, { 1, 1 } }),
			Lifetime = NumberRange.new(BLOOM_TIME),
			ZOffset = 0.3,
		},
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
	if muzzle then
		casing(muzzle)
	end
	ray(from, hitPosition)
	if normal and not hitBody then
		surfaceHit(hitPosition, normal)
	end
	if onImpact then
		onImpact()
	end
	return from
end

return Gunshot

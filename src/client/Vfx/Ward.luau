--!strict
-- Ward: the guard's crimson glass buckler (C1.6, docs/combat-rework.md). Every guarding entity gets one, pooled: the
-- form (Shared.Assets.Vfx.Ward: a glass lens and its hot rim, from tools/blender/ward.py) dressed here with our
-- rose-window tracery and crack Decals, a breathing glow, embers off the rim and a crimson light. CombatFxController
-- drives it:
--   Set(model, raised): raise (grows 0.4 → 1.06 → 1 in 0.12 s, the rim flashing white-gold) or lower (shrinks and fades
--             in 0.08 s);
--   Strength(model, share): the guard's stamina share: cracks fade in below half, full at a tenth; under a fifth the
--             ward flickers;
--   Block(model): the glass flashes hot, a ripple runs out, gold arcs whirl round it, sparks spray off its face;
--   Parry(model): a white-gold starburst, a bright ring snapping out, more arcs and sparks, a white-gold flash;
--   Break(model): the ward cracks through and shatters: glass shards, a crimson-to-black puff, a crimson flash;
--   Update(): places every shown ward ahead of its body's chest on the off-hand side, and frees the wards of entities
--             that are gone (call it every frame).
-- Glass, light, smoke and sparks only: no gore (AGENTS.md rule 4).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Parent.UI.Theme)
local Parts = require(ReplicatedStorage.Shared.Util.Parts)

local T = Kit.Textures
local V = Theme.Vfx

-- From the root: the off-hand side, shoulder height, ahead of the chest, turned a little outward (as a buckler is).
local OFFSET = CFrame.new(-1.3, 0.9, -1.0) * CFrame.Angles(0, math.rad(10), 0) -- clear of the head from behind
local RAISE_TIME, LOWER_TIME = 0.12, 0.08
local RAISE_FROM, OVERSHOOT, OVERSHOOT_AT = 0.4, 1.06, 0.7 -- the raise's scale: from, peak, and where it peaks
local LOWER_TO = 0.6
local GLASS_TRANSPARENCY = 0.3
local TRACERY_FRONT, TRACERY_BACK = 0.12, 0.3 -- the tracery's transparency: dimmer from behind (the glass is between)
local CRACKS_FROM, CRACKS_FULL = 0.5, 0.1 -- stamina shares: cracks start to show / show fully
local FLICKER_UNDER = 0.2
local LIGHT = { Brightness = 0.5, Range = 4 } -- on the arm and face, never a red pool on the floor
local GLOW_SIZE = 2.6 -- studs: the breathing glow round the lens
local EMBER_ANGLES = { 150, 90, 30 } -- degrees round the rim the embers rise from (its upper half)
local BLOCK_FLASH, PARRY_FLASH = 0.16, 0.22 -- seconds the glass takes to cool after a block / a parry
local BLOCK_BOOST, PARRY_BOOST = 1.6, 2.5 -- extra light the ward gives off as it flashes
-- Lights that flash and fade (brightness, range, seconds): kept small, so the floor never pools with light.
local PARRY_LIGHT = { Brightness = 2.5, Range = 10, Time = 0.25 }
local BREAK_LIGHT = { Brightness = 2, Range = 7, Time = 0.3 }

type Ward = {
	Model: Model,
	Lens: MeshPart,
	Rim: MeshPart,
	LensSize: Vector3,
	RimSize: Vector3,
	Tracery: { { Decal: Decal, Base: number } },
	Cracks: { Decal },
	Emitters: { ParticleEmitter },
	Light: PointLight,
	Raised: boolean,
	Scale: number,
	Fade: number, -- 1 shown, 0 gone
	Boost: number, -- extra light from a block or parry
	Token: number, -- bumped by every raise, lower and break, so an older tween stops
}

local Ward = {}

local wards: { [Model]: Ward } = {}
local strengths: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any
local folder: Folder? = nil

local function home(): Folder
	if not folder or not folder.Parent then
		local made = Instance.new("Folder")
		made.Name = "BL_Wards"
		made.Parent = workspace
		folder = made
	end
	return folder :: Folder
end

local function decal(lens: MeshPart, name: string, texture: string, face: Enum.NormalId, color: Color3, transparency: number): Decal
	local made = Instance.new("Decal")
	made.Name = name
	made.Texture = texture
	made.Face = face
	made.Color3 = color
	made.Transparency = transparency
	made.Parent = lens
	return made
end

local function build(): Ward
	local model = (ReplicatedStorage.Shared.Assets.Vfx :: any).Ward:Clone() :: Model
	local lens = model:FindFirstChild("Lens") :: MeshPart
	local rim = model:FindFirstChild("Rim") :: MeshPart
	local centre = lens:FindFirstChild("Centre") :: Attachment
	local emitters = {}
	table.insert(emitters, Kit.Emitter(centre, { -- a soft glow breathing round the lens, in its plane
		Texture = T.SoftGlow,
		Rate = 5,
		Lifetime = NumberRange.new(0.6, 0.8),
		LockedToPart = true,
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection = Enum.NormalId.Front,
		Speed = NumberRange.new(0.01),
		Size = Kit.Seq(GLOW_SIZE),
		Transparency = Kit.Seq({ { 0, 1 }, { 0.4, 0.72 }, { 1, 1 } }),
		LightEmission = 1,
		Color = ColorSequence.new(V.WardRim),
		ZOffset = -0.3,
	}))
	for _, degrees in EMBER_ANGLES do
		local rimPoint = Instance.new("Attachment")
		rimPoint.Name = "Embers"
		local angle = math.rad(degrees)
		rimPoint.Position = Vector3.new(math.cos(angle), math.sin(angle), 0) * (lens.Size.X / 2)
		rimPoint.Parent = lens
		table.insert(emitters, Kit.Emitter(rimPoint, {
			Texture = T.SoftGlow,
			Rate = 1.6,
			Lifetime = NumberRange.new(0.6, 1.1),
			Speed = NumberRange.new(0.4, 1.2),
			SpreadAngle = Vector2.new(40, 40),
			EmissionDirection = Enum.NormalId.Top,
			Acceleration = Vector3.new(0, 1.5, 0),
			Drag = 1,
			Size = Kit.Seq({ { 0, 0.14 }, { 1, 0.04 } }),
			Transparency = Kit.Seq({ { 0, 0.1 }, { 1, 1 } }),
			LightEmission = 1,
			Color = ColorSequence.new(V.WardEmber),
		}))
	end
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Shadows = V.WardLight, LIGHT.Range, false
	light.Parent = lens
	return {
		Model = model,
		Lens = lens,
		Rim = rim,
		LensSize = lens.Size,
		RimSize = rim.Size,
		Tracery = {
			{ Decal = decal(lens, "TraceryFront", T.WardTracery, Enum.NormalId.Front, V.WardLine, TRACERY_FRONT), Base = TRACERY_FRONT },
			{ Decal = decal(lens, "TraceryBack", T.WardTracery, Enum.NormalId.Back, V.WardLine, TRACERY_BACK), Base = TRACERY_BACK },
		},
		Cracks = {
			decal(lens, "CracksFront", T.WardCracks, Enum.NormalId.Front, V.WardCrack, 1),
			decal(lens, "CracksBack", T.WardCracks, Enum.NormalId.Back, V.WardCrack, 1),
		},
		Emitters = emitters,
		Light = light,
		Raised = false,
		Scale = RAISE_FROM,
		Fade = 0,
		Boost = 0,
		Token = 0,
	}
end

local function crackShare(model: Model): number
	local share = strengths[model] or 1
	return math.clamp((CRACKS_FROM - share) / (CRACKS_FROM - CRACKS_FULL), 0, 1)
end

-- Writes the ward's scale, fade, cracks and light: every frame while it shows.
local function apply(model: Model, ward: Ward)
	local s = math.max(ward.Scale, 0.01)
	ward.Lens.Size = ward.LensSize * s
	ward.Rim.Size = ward.RimSize * s
	local flicker = 1
	if (strengths[model] or 1) < FLICKER_UNDER then -- about to break: the light stutters
		flicker = 0.55 + 0.45 * math.clamp(0.5 + math.noise(os.clock() * 17, ward.Lens.Size.X), 0, 1)
	end
	local fade = ward.Fade
	ward.Lens.Transparency = 1 - (1 - GLASS_TRANSPARENCY) * fade
	ward.Rim.Transparency = 1 - fade * flicker
	for _, tracery in ward.Tracery do
		tracery.Decal.Transparency = 1 - (1 - tracery.Base) * fade
	end
	local cracks = crackShare(model) * fade
	for _, crack in ward.Cracks do
		crack.Transparency = 1 - cracks
	end
	ward.Light.Brightness = (LIGHT.Brightness + ward.Boost) * fade * flicker
end

local function setEmitting(ward: Ward, on: boolean)
	for _, emitter in ward.Emitters do
		emitter.Enabled = on
	end
	ward.Light.Enabled = on
end

local function hide(ward: Ward)
	ward.Raised = false
	ward.Token += 1
	ward.Fade = 0
	setEmitting(ward, false)
	ward.Model.Parent = nil
end

-- Raises or lowers this entity's ward.
function Ward.Set(model: Model, raised: boolean)
	local ward = wards[model]
	if raised then
		if not ward then
			ward = build()
			wards[model] = ward
		end
		local raising = ward :: Ward
		if raising.Raised then
			return
		end
		raising.Raised = true
		raising.Token += 1
		local token = raising.Token
		raising.Model.Parent = home()
		local root = Parts.Root(model)
		if root then
			raising.Model:PivotTo(root.CFrame * OFFSET)
		end
		setEmitting(raising, true)
		Kit.Tween(RAISE_TIME, function(alpha)
			if raising.Token ~= token then
				return
			end
			raising.Scale = if alpha < OVERSHOOT_AT
				then RAISE_FROM + (OVERSHOOT - RAISE_FROM) * math.sin(alpha / OVERSHOOT_AT * math.pi / 2)
				else OVERSHOOT + (1 - OVERSHOOT) * (alpha - OVERSHOOT_AT) / (1 - OVERSHOOT_AT)
			raising.Fade = math.min(1, alpha * 2.5)
			raising.Rim.Color = V.RadianceCore:Lerp(V.WardRim, alpha) -- the rim flashes, then settles to its glow
		end)
	elseif ward and ward.Raised then
		ward.Raised = false
		ward.Token += 1
		local token = ward.Token
		local from = ward.Scale
		Kit.Tween(LOWER_TIME, function(alpha)
			if ward.Token ~= token then
				return
			end
			ward.Scale = from + (LOWER_TO - from) * alpha
			ward.Fade = 1 - alpha
		end, function()
			if ward.Token == token then
				hide(ward)
			end
		end)
	end
end

-- The guard's stamina share (0..1): its cracks and its flicker.
function Ward.Strength(model: Model, share: number)
	strengths[model] = math.clamp(share, 0, 1)
end

-- The glass flashing hot and cooling back, with a burst of extra light.
local function flash(ward: Ward, lens: Color3, rim: Color3, boost: number, duration: number)
	Kit.Tween(duration, function(alpha)
		if not ward.Raised then
			return
		end
		ward.Lens.Color = lens:Lerp(V.WardGlass, alpha)
		ward.Rim.Color = rim:Lerp(V.WardRim, alpha)
		ward.Boost = boost * (1 - alpha) ^ 2
	end)
end

-- Gold arcs whirling round the ward in its plane: half turning one way, half the other.
local function arcs(count: number, size: { number }, colors: ColorSequence): { Kit.Spec }
	local function spin(from: number, to: number): Kit.Spec
		return {
			Texture = T.CrescentArc,
			Count = math.ceil(count / 2),
			Lifetime = NumberRange.new(0.16, 0.22),
			Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
			EmissionDirection = Enum.NormalId.Front,
			Speed = NumberRange.new(0.01),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(from, to),
			Size = Kit.Seq({ { 0, size[1], size[1] * 0.3 }, { 1, size[2], size[2] * 0.3 } }),
			Transparency = Kit.Seq({ { 0, 0 }, { 0.6, 0.2 }, { 1, 1 } }),
			LightEmission = 1,
			Color = colors,
			ZOffset = 0.5,
		}
	end
	return { spin(500, 900), spin(-900, -500) }
end

local function ring(size: { number }, life: number, color: Color3): Kit.Spec
	return {
		Texture = T.WindRing,
		Count = 1,
		Lifetime = NumberRange.new(life),
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection = Enum.NormalId.Front,
		Speed = NumberRange.new(0.01),
		Size = Kit.Seq({ { 0, size[1] }, { 1, size[2] } }),
		Transparency = Kit.Seq({ { 0, 0.15 }, { 1, 1 } }),
		LightEmission = 1,
		Color = ColorSequence.new(color),
		ZOffset = 0.4,
	}
end

local function sparks(count: number): Kit.Spec
	return {
		Texture = T.Spark,
		Count = count,
		Lifetime = NumberRange.new(0.18, 0.32),
		Speed = NumberRange.new(16, 30),
		SpreadAngle = Vector2.new(40, 40),
		EmissionDirection = Enum.NormalId.Front,
		Acceleration = Vector3.new(0, -60, 0),
		Drag = 3,
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		Size = Kit.Seq({ { 0, 0.35 }, { 1, 0 } }),
		LightEmission = 1,
		Color = Kit.Colors(V.RadianceCore, V.Radiance),
	}
end

local function shown(model: Model): Ward?
	local ward = wards[model]
	return if ward and ward.Raised and ward.Model.Parent then ward else nil
end

-- A hit stopped by the ward.
function Ward.Block(model: Model)
	local ward = shown(model)
	if not ward then
		return
	end
	flash(ward, V.WardHot, V.RadianceCore, BLOCK_BOOST, BLOCK_FLASH)
	local specs = arcs(5, { 1.4, 2.8 }, Kit.Colors(V.Radiance, V.RadianceDeep)) -- gold; white-gold is the parry's
	table.insert(specs, ring({ 0.4, 2.6 }, 0.2, V.Radiance))
	table.insert(specs, sparks(14))
	Kit.Burst(ward.Lens.CFrame, specs)
end

-- A perfect guard: the hit turned aside.
function Ward.Parry(model: Model)
	local ward = shown(model)
	if not ward then
		return
	end
	flash(ward, V.RadianceCore, V.RadianceCore, PARRY_BOOST, PARRY_FLASH)
	local specs = arcs(8, { 2, 3.6 }, Kit.Colors(V.RadianceCore, V.RadianceCore))
	table.insert(specs, ring({ 0.5, 4.2 }, 0.24, V.RadianceCore))
	table.insert(specs, sparks(24))
	table.insert(specs, { -- the starburst
		Texture = T.Glint,
		Count = 1,
		Lifetime = NumberRange.new(0.2),
		Rotation = NumberRange.new(0, 90),
		Size = Kit.Seq({ { 0, 0.5 }, { 0.25, 3.6 }, { 1, 0 } }),
		LightEmission = 1,
		Color = ColorSequence.new(V.RadianceCore),
		ZOffset = 1,
	})
	Kit.Burst(ward.Lens.CFrame, specs)
	Kit.Flash(ward.Lens.Position, V.RadianceCore, PARRY_LIGHT.Brightness, PARRY_LIGHT.Range, PARRY_LIGHT.Time)
end

-- The guard broken: the ward shatters and is gone.
function Ward.Break(model: Model)
	local ward = wards[model]
	if not (ward and ward.Model.Parent) then
		return
	end
	local at = ward.Lens.CFrame
	hide(ward)
	Kit.Burst(at, {
		{ -- shards of its glass, tumbling and falling
			Texture = T.GlassShard,
			Count = 18,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid2x2,
			FlipbookMode = Enum.ParticleFlipbookMode.Loop,
			FlipbookFramerate = NumberRange.new(0),
			FlipbookStartRandom = true, -- each shard keeps one of the four shapes
			Lifetime = NumberRange.new(0.6, 0.9),
			Speed = NumberRange.new(8, 20),
			SpreadAngle = Vector2.new(70, 70),
			EmissionDirection = Enum.NormalId.Front,
			Acceleration = Vector3.new(0, -70, 0),
			Drag = 1,
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-720, 720),
			Size = Kit.Seq({ { 0, 0.45, 0.2 }, { 1, 0.3, 0.1 } }),
			Transparency = Kit.Seq({ { 0, 0 }, { 0.75, 0.15 }, { 1, 1 } }),
			LightEmission = 0.35,
			Color = ColorSequence.new(V.WardShard),
		},
		{ -- a puff going from crimson to black
			Texture = T.SmokePuff,
			Count = 3,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
			FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
			Lifetime = NumberRange.new(0.5, 0.7),
			Speed = NumberRange.new(1.5, 4),
			SpreadAngle = Vector2.new(60, 60),
			EmissionDirection = Enum.NormalId.Front,
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-40, 40),
			Size = Kit.Seq({ { 0, 1.2 }, { 1, 2.8 } }),
			Transparency = Kit.Seq({ { 0, 0.25 }, { 1, 1 } }),
			Color = Kit.Colors(V.BloodDeep, V.SmokeDark),
		},
		sparks(10),
	})
	Kit.Flash(at.Position, V.WardHot, BREAK_LIGHT.Brightness, BREAK_LIGHT.Range, BREAK_LIGHT.Time)
end

-- Places every shown ward and frees the wards of entities that are gone. Every frame.
function Ward.Update()
	for model, ward in wards do
		if not model.Parent then
			ward.Model:Destroy()
			wards[model] = nil
			continue
		end
		if ward.Model.Parent then
			local root = Parts.Root(model)
			if root then
				ward.Model:PivotTo(root.CFrame * OFFSET)
			end
			apply(model, ward)
		end
	end
end

-- This entity's ward while it shows, else nil (tests).
function Ward.Shown(model: Model): Model?
	local ward = wards[model]
	return if ward and ward.Model.Parent then ward.Model else nil
end

return Ward

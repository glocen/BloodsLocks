--!strict
-- LightBeam: a channeled beam of radiance. Charge: motes converge on the muzzle while a glow swells. Fire: a hot
-- core inside wider gold bands (our drawn soft band, Kit.Textures.BeamCore), two layers of drawn energy strands
-- scrolling opposite ways (BeamEnergy), motes drifting off the length, a glinting muzzle flare and a burning
-- impact point. Release: the beam collapses to a
-- thread and vanishes while particles die out.

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Parent.UI.Theme)

local T = Kit.Textures
local P = Theme.Vfx

export type Ray = {
	From: BasePart,
	To: BasePart,
	Span: BasePart,
	Muzzle: Attachment,
	Charge: { ParticleEmitter },
	Firing: { Instance },
	MuzzleGlow: ParticleEmitter,
	Beams: { { Beam: Beam, Width: number } },
	Lights: { PointLight },
	Fired: boolean,
}

local LightBeam = {}

local function beam(a0: Attachment, a1: Attachment, width: number, spec: Kit.Spec): Beam
	local b = Instance.new("Beam")
	b.Attachment0, b.Attachment1 = a0, a1
	b.Width0, b.Width1 = width, width
	b.FaceCamera = true
	b.LightInfluence = 0
	b.LightEmission = 1
	b.Segments = 1
	b.Enabled = false
	for key, value in spec do
		(b :: any)[key] = value
	end
	b.Parent = a0.Parent
	return b
end

local function light(parent: Instance, color: Color3, brightness: number, range: number): PointLight
	local l = Instance.new("PointLight")
	l.Color, l.Brightness, l.Range, l.Shadows = color, brightness, range, false
	l.Parent = parent
	return l
end

function LightBeam.new(): Ray
	local from = Kit.Anchor(CFrame.new(), Vector3.one * 3)
	local to = Kit.Anchor(CFrame.new(), Vector3.one * 1.5)
	local span = Kit.Anchor(CFrame.new(), Vector3.one)
	local muzzle = Instance.new("Attachment")
	muzzle.Parent = from
	local a0 = Instance.new("Attachment")
	a0.Parent = from
	local a1 = Instance.new("Attachment")
	a1.Parent = to
	local impact = Instance.new("Attachment")
	impact.Parent = to

	-- Charge: motes drawn inward from a sphere around the muzzle.
	local charge = {
		Kit.Emitter(from, {
			Shape = Enum.ParticleEmitterShape.Sphere,
			ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
			Texture = T.SoftGlow,
			Color = Kit.Colors(P.Radiance, P.RadianceCore),
			Size = Kit.Seq({ { 0, 0 }, { 0.3, 0.28 }, { 1, 0.1 } }),
			Lifetime = NumberRange.new(0.22, 0.3),
			Rate = 90,
			Speed = NumberRange.new(5, 7),
			LightEmission = 1,
		}),
		Kit.Emitter(from, {
			Shape = Enum.ParticleEmitterShape.Sphere,
			ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
			Texture = T.WindStreak,
			Orientation = Enum.ParticleOrientation.VelocityParallel,
			Color = Kit.Colors(P.RadianceDeep, P.Radiance),
			Size = Kit.Seq({ { 0, 0 }, { 0.4, 0.6 }, { 1, 0.2 } }),
			Transparency = Kit.Seq(0.3, 1),
			Lifetime = NumberRange.new(0.2, 0.28),
			Rate = 30,
			Speed = NumberRange.new(6, 8),
			LightEmission = 1,
		}),
	}
	local muzzleGlow = Kit.Emitter(muzzle, {
		Texture = T.SoftGlow,
		Color = Kit.Colors(P.Radiance),
		Size = Kit.Seq(1),
		Transparency = Kit.Seq(0.15, 1),
		Lifetime = NumberRange.new(0.12),
		Rate = 40,
		LockedToPart = true,
		LightEmission = 1,
	})

	-- Fire layers: {width, color, transparency, texture?, texture length, scroll speed}.
	local layers = {}
	for _, spec in {
		{ 3.2, P.RadianceDeep, 0.7, T.BeamCore, 8, 0 },
		{ 1.5, P.Radiance, 0.3, T.BeamCore, 6, 0 },
		{ 0.55, P.RadianceCore, 0, T.BeamCore, 4, 0 },
		{ 2.6, P.RadianceDeep, 0.45, T.BeamEnergy, 14, -4 },
		{ 1.8, P.Radiance, 0.3, T.BeamEnergy, 10, 6 },
	} do
		table.insert(layers, {
			Width = spec[1],
			Beam = beam(a0, a1, spec[1], {
				Color = Kit.Colors(spec[2]),
				Transparency = Kit.Seq(spec[3]),
				Texture = spec[4] or "",
				TextureMode = Enum.TextureMode.Wrap,
				TextureLength = spec[5] or 1,
				TextureSpeed = spec[6] or 0,
			}),
		})
	end
	local firing: { Instance } = {
		Kit.Emitter(span, {
			Texture = T.SoftGlow,
			Color = Kit.Colors(P.RadianceCore, P.Radiance),
			Size = Kit.Seq({ { 0, 0.22 }, { 1, 0 } }),
			Lifetime = NumberRange.new(0.4, 0.7),
			Rate = 0,
			Speed = NumberRange.new(1, 3),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, 4, 0),
			LightEmission = 1,
			Enabled = false,
		}),
		Kit.Emitter(muzzle, {
			Texture = T.Glint,
			Color = Kit.Colors(P.RadianceCore),
			Size = Kit.Seq(3.2),
			Transparency = Kit.Seq(0.1, 1),
			Lifetime = NumberRange.new(0.12),
			Rate = 14,
			Rotation = NumberRange.new(0, 360),
			LockedToPart = true,
			LightEmission = 1,
			Enabled = false,
		}),
		Kit.Emitter(impact, {
			Texture = T.SoftGlow,
			Color = Kit.Colors(P.Radiance),
			Size = Kit.Seq(3, 4),
			Transparency = Kit.Seq(0.35, 1),
			Lifetime = NumberRange.new(0.12),
			Rate = 40,
			LockedToPart = true,
			LightEmission = 1,
			Enabled = false,
		}),
		Kit.Emitter(impact, {
			Texture = T.Glint,
			Color = Kit.Colors(P.RadianceCore),
			Size = Kit.Seq(4.5),
			Transparency = Kit.Seq(0.1, 1),
			Lifetime = NumberRange.new(0.12),
			Rate = 14,
			Rotation = NumberRange.new(0, 360),
			LightEmission = 1,
			Enabled = false,
		}),
		Kit.Emitter(impact, {
			Texture = T.SoftGlow,
			Color = Kit.Colors(P.RadianceCore, P.RadianceDeep),
			Size = Kit.Seq(0.26, 0),
			Lifetime = NumberRange.new(0.25, 0.5),
			Rate = 90,
			Speed = NumberRange.new(12, 26),
			SpreadAngle = Vector2.new(70, 70),
			EmissionDirection = Enum.NormalId.Front,
			Acceleration = Vector3.new(0, -60, 0),
			Drag = 2,
			LightEmission = 1,
			Enabled = false,
		}),
		Kit.Emitter(impact, {
			Texture = T.SmokePuff,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
			FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
			Color = Kit.Colors(P.Radiance, P.RadianceDeep),
			Size = Kit.Seq(2, 4.5),
			Transparency = Kit.Seq({ { 0, 1 }, { 0.2, 0.6 }, { 1, 1 } }),
			Lifetime = NumberRange.new(0.4, 0.6),
			Rate = 18,
			Speed = NumberRange.new(2, 4),
			SpreadAngle = Vector2.new(180, 180),
			Rotation = NumberRange.new(0, 360),
			Acceleration = Vector3.new(0, 6, 0),
			LightEmission = 0.6,
			Enabled = false,
		}),
	}
	local lights = { light(from, P.Radiance, 0, 16), light(to, P.Radiance, 0, 20), light(span, P.RadianceDeep, 0, 24) }
	return {
		From = from,
		To = to,
		Span = span,
		Muzzle = muzzle,
		Charge = charge,
		Firing = firing,
		MuzzleGlow = muzzleGlow,
		Beams = layers,
		Lights = lights,
		Fired = false,
	}
end

local function fire(ray: Ray)
	ray.Fired = true
	for _, emitter in ray.Charge do
		emitter.Enabled = false
	end
	for _, item in ray.Firing do
		(item :: any).Enabled = true
	end
	for _, layer in ray.Beams do
		layer.Beam.Enabled = true
	end
	Kit.Burst(ray.Muzzle.WorldCFrame, {
		{ Count = 1, Texture = T.SoftGlow, Color = Kit.Colors(P.RadianceCore), Size = Kit.Seq(2, 9), Transparency = Kit.Seq(0, 1),
			Lifetime = NumberRange.new(0.22), LightEmission = 1 },
		{ Count = 24, Texture = T.SoftGlow, Color = Kit.Colors(P.RadianceCore, P.Radiance), Size = Kit.Seq(0.25, 0),
			Lifetime = NumberRange.new(0.2, 0.4), Speed = NumberRange.new(16, 30), SpreadAngle = Vector2.new(180, 180), Drag = 5, LightEmission = 1 },
	})
end

-- charge: 0 → 1 over the wind-up; firing once the beam is live. clock drives the shimmer.
function LightBeam.Update(ray: Ray, from: Vector3, to: Vector3, charge: number, firing: boolean, clock: number)
	local direction = to - from
	local length = math.max(direction.Magnitude, 0.1)
	local look = CFrame.lookAt(from, if length > 0.1 then to else from + Vector3.zAxis)
	ray.From.CFrame = look
	ray.To.CFrame = CFrame.lookAt(to, from)
	ray.Span.Size = Vector3.new(0.6, 0.6, length)
	ray.Span.CFrame = look * CFrame.new(0, 0, -length / 2)

	local pulse = 1 + 0.08 * math.sin(clock * 38) + 0.05 * math.sin(clock * 91)
	if firing then
		if not ray.Fired then
			fire(ray)
		end
		for _, layer in ray.Beams do
			local w = layer.Width * pulse
			layer.Beam.Width0, layer.Beam.Width1 = w * 0.75, w
		end
		ray.MuzzleGlow.Size = Kit.Seq(3.2 * pulse)
		ray.Lights[1].Brightness = 4
		ray.Lights[2].Brightness = 5 * pulse
		ray.Lights[3].Brightness = 1.5
		ray.Firing[1].Rate = length * 3
	else
		ray.MuzzleGlow.Size = Kit.Seq(0.6 + 2.2 * charge * pulse)
		ray.Lights[1].Brightness = 3 * charge
	end
end

function LightBeam.Destroy(ray: Ray)
	for _, emitter in ray.Charge do
		emitter.Enabled = false
	end
	for _, item in ray.Firing do
		(item :: any).Enabled = false
	end
	ray.MuzzleGlow.Enabled = false
	Kit.Tween(0.14, function(alpha)
		local squeeze = (1 - alpha) ^ 2
		for _, layer in ray.Beams do
			layer.Beam.Width0, layer.Beam.Width1 = layer.Width * 0.75 * squeeze, layer.Width * squeeze
		end
		for _, l in ray.Lights do
			l.Brightness *= 0.8
		end
	end, function()
		for _, part in { ray.From, ray.To, ray.Span } do
			Kit.Release(part, 0.8)
		end
	end)
	if ray.Fired then
		Kit.Flash(ray.To.Position, P.Radiance, 4, 18, 0.3)
	end
end

return LightBeam

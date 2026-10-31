--!strict
-- BloodCharge: the tell for a charging melee blow, readable by the attacker and their opponent. While charging,
-- crimson sparks are drawn in from the air around the body, a crimson glow builds along the blade, and a dark red
-- mist gathers at the feet, all growing with the charge (no gore: AGENTS.md rule 4). When the blow is armed (it can be released), a sharp glint on the blade
-- tip. On release, a crimson flare off the blade; abandoned (dodged out), it just drains away.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Parent.UI.Theme)
local Equipment = require(ReplicatedStorage.Shared.Simulation.Equipment)

local T = Kit.Textures
local P = Theme.Vfx

local WEAPON = "BL_Weapon"
-- Blade glow bands, back to front: {width at full charge, color, transparency}.
local BANDS = {
	{ 0.8, P.BloodDeep, 0.75 },
	{ 0.4, P.Blood, 0.45 },
	{ 0.14, P.BloodCore, 0.1 },
}

export type Visual = {
	Model: Model,
	Blade: BasePart?,
	Base: Attachment?,
	Tip: Attachment?,
	Body: BasePart,
	Bands: { { Beam: Beam, Width: number } },
	Gather: ParticleEmitter,
	Embers: ParticleEmitter,
	Mist: ParticleEmitter,
	Light: PointLight,
	Armed: boolean,
}

local BloodCharge = {}

local function attachment(parent: Instance, position: Vector3): Attachment
	local a = Instance.new("Attachment")
	a.Position = position
	a.Parent = parent
	return a
end

function BloodCharge.Spawn(model: Model): Visual
	local weapon = model:FindFirstChild(WEAPON)
	local blade = weapon and weapon:FindFirstChild("Blade") :: BasePart?
	local bands, base, tip = {}, nil, nil
	if blade then
		-- the glow runs between the blade's own base and tip points, or its ends on a model without them
		local from = Equipment.Point(weapon :: Model, Equipment.Points.BladeBase)
		local to = Equipment.Point(weapon :: Model, Equipment.Points.BladeTip)
		local half = blade.Size.Y / 2
		base = attachment(blade, if from then blade.CFrame:PointToObjectSpace(from.WorldPosition) else Vector3.new(0, -half, 0))
		tip = attachment(blade, if to then blade.CFrame:PointToObjectSpace(to.WorldPosition) else Vector3.new(0, half, 0))
		for _, band in BANDS do
			local beam = Instance.new("Beam")
			beam.Attachment0, beam.Attachment1 = base, tip
			beam.FaceCamera = true
			beam.LightEmission = 1
			beam.LightInfluence = 0
			beam.Segments = 1
			beam.Color = Kit.Colors(band[2])
			beam.Transparency = Kit.Seq(band[3])
			beam.Width0, beam.Width1 = 0, 0
			beam.Parent = blade
			table.insert(bands, { Beam = beam, Width = band[1] })
		end
	end

	-- An invisible shell around the body: sparks are pulled in from its surface.
	local body = Kit.Anchor(CFrame.new(), Vector3.one * 7)
	local center = attachment(body, Vector3.new(0, -2.6, 0))
	local gather = Kit.Emitter(body, {
		Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		Texture = T.Spark,
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		Color = Kit.Colors(P.BloodDeep, P.Blood),
		Size = Kit.Seq({ { 0, 0 }, { 0.3, 0.5 }, { 1, 0.15 } }),
		Transparency = Kit.Seq({ { 0, 1 }, { 0.2, 0.1 }, { 1, 0.4 } }),
		Lifetime = NumberRange.new(0.3, 0.38),
		Speed = NumberRange.new(9, 11),
		LightEmission = 0.4,
	})
	local embers = Kit.Emitter(body, {
		Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		Texture = T.SoftGlow,
		Color = Kit.Colors(P.BloodCore),
		Size = Kit.Seq({ { 0, 0 }, { 0.3, 0.22 }, { 1, 0.05 } }),
		Lifetime = NumberRange.new(0.3, 0.38),
		Speed = NumberRange.new(9, 11),
		LightEmission = 1,
	})
	local mist = Kit.Emitter(center, {
		Texture = T.SmokePuff,
		FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
		FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		Color = Kit.Colors(P.Blood, P.BloodDark),
		Size = Kit.Seq(3, 6),
		Transparency = Kit.Seq({ { 0, 1 }, { 0.2, 0.3 }, { 1, 1 } }),
		Lifetime = NumberRange.new(0.6, 0.9),
		Speed = NumberRange.new(2, 4),
		SpreadAngle = Vector2.new(180, 10),
		EmissionDirection = Enum.NormalId.Top,
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-30, 30),
		Acceleration = Vector3.new(0, 2, 0),
		Drag = 2,
		LightEmission = 0.25,
		ZOffset = -1,
	})
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range, light.Shadows = P.Blood, 0, 9, false
	light.Parent = blade or body

	return {
		Model = model,
		Blade = blade,
		Base = base,
		Tip = tip,
		Body = body,
		Bands = bands,
		Gather = gather,
		Embers = embers,
		Mist = mist,
		Light = light,
		Armed = false,
	}
end

-- progress: 0 → 1 over the whole stance; armed once the blow can be released.
function BloodCharge.Update(visual: Visual, progress: number, armed: boolean, clock: number)
	local root = visual.Model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		visual.Body.CFrame = root.CFrame
	end
	local flicker = 1 + 0.1 * math.sin(clock * 47) + 0.06 * math.sin(clock * 113)
	local build = 0.35 + 0.65 * progress
	for _, band in visual.Bands do
		local w = band.Width * build * flicker
		band.Beam.Width0, band.Beam.Width1 = w * 0.6, w
	end
	visual.Gather.Rate = 60 + 60 * progress
	visual.Embers.Rate = 30 + 50 * progress
	visual.Mist.Rate = 12 + 20 * progress
	visual.Light.Brightness = (0.4 + progress) * flicker

	if armed and not visual.Armed then
		visual.Armed = true
		local at = if visual.Tip then visual.Tip.WorldPosition elseif root then root.Position else visual.Body.Position
		Kit.Burst(CFrame.new(at), {
			{ Count = 1, Texture = T.Glint,
				Color = Kit.Colors(P.BloodCore), Size = Kit.Seq({ { 0, 1 }, { 0.3, 5 }, { 1, 0 } }), Lifetime = NumberRange.new(0.22),
				Rotation = NumberRange.new(0, 45), LightEmission = 1, ZOffset = 2 },
			{ Count = 1, Texture = T.SoftGlow, Color = Kit.Colors(P.Blood), Size = Kit.Seq(1, 6), Transparency = Kit.Seq(0.2, 1),
				Lifetime = NumberRange.new(0.25), LightEmission = 1, ZOffset = 1 },
			{ Count = 14, Texture = T.SoftGlow, Color = Kit.Colors(P.BloodCore, P.Blood), Size = Kit.Seq(0.22, 0),
				Lifetime = NumberRange.new(0.18, 0.3), Speed = NumberRange.new(10, 20), SpreadAngle = Vector2.new(180, 180),
				Drag = 6, LightEmission = 1 },
		})
		Kit.Flash(at, P.BloodCore, 6, 16, 0.25)
	end
end

-- fired: the charged blow went out (flare off the blade); otherwise the charge was abandoned.
function BloodCharge.Release(visual: Visual, fired: boolean)
	if fired and visual.Tip then
		local root = visual.Model:FindFirstChild("HumanoidRootPart") :: BasePart?
		local forward = if root then root.CFrame.LookVector else Vector3.zAxis
		local at = visual.Tip.WorldPosition
		Kit.Burst(CFrame.lookAt(at, at + forward), {
			{ Count = 1, Texture = T.CrescentArc,
				Color = Kit.Colors(P.BloodCore, P.Blood), Size = Kit.Seq(8), Lifetime = NumberRange.new(0.2),
				Rotation = NumberRange.new(-30, 30), LightEmission = 0.8 },
			{ Count = 14, Texture = T.Spark, Orientation = Enum.ParticleOrientation.VelocityParallel,
				Color = Kit.Colors(P.BloodCore, P.Blood), Size = Kit.Seq(0.4, 0.1), Lifetime = NumberRange.new(0.15, 0.3),
				Speed = NumberRange.new(10, 22), SpreadAngle = Vector2.new(45, 45), EmissionDirection = Enum.NormalId.Front,
				Drag = 5, LightEmission = 0.6 },
		})
		Kit.Flash(at, P.Blood, 5, 18, 0.3)
	end
	for _, band in visual.Bands do
		band.Beam:Destroy()
	end
	for _, a in { visual.Base, visual.Tip } do
		a:Destroy()
	end
	visual.Light:Destroy()
	Kit.Release(visual.Body, 1)
end

return BloodCharge

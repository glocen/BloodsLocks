--!strict
-- BloodBlade: the Sable Stroke (its player-facing name; owner, 2026-10-31: "black like black ink"; the red crescent it
-- replaces is in docs/combat-rework.md, C1.3), a stroke of black ink flung from the hand, flying away from the
-- caster. A beam, not a picture: one curved Beam along a 120° arc, heavy where the stroke leaves the hand and
-- tapering to a dry tail, the middle bowed forward, rolled like a thrown diagonal slash (two half-beams showed a kink
-- where they met). It faces the camera, so from behind it reads as a whole stroke and from the side as a thick line.
-- Its ink (Kit.Textures.InkStroke) is bristled and glossy with moonlit edges, so it holds on a night sky. In flight it
-- unfurls, then thins; ink wisps shed from it and dissolve in the air behind, and its tail breaks into dry streaks.
-- Cast: a twist of ink at the hand and a pale flick. Impact: the stroke splays and fades into curling ink and a cold
-- ring of light. Ink and smoke only, never liquid: no drops, spatter or pools (AGENTS.md rule 4).

local ContentProvider = game:GetService("ContentProvider")

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Parent.UI.Theme)

local T = Kit.Textures
local V = Theme.Vfx

-- The stroke's arc, in the plane facing the way it flies: 12 studs tip to tip.
local RADIUS = 6.9
local HALF_SPAN = math.rad(60) -- the arc runs 60° either side of its middle
local BOW = 1.2 -- studs the middle leads the tips by
local ROLL = math.rad(35) -- off upright: a thrown diagonal slash
local WIDTH = 2.4 -- studs at its heavy start, tapering to a point at the tail
local SEGMENTS = 40
local UNFURL = { From = 0.4, Time = 0.08 } -- its width at the cast (a share), and how fast it opens
local THIN = { By = 0.45, Time = 0.7 } -- the share of its width it loses as it flies, and over how long
local DISSOLVE = 0.16 -- seconds the stroke takes to splay and fade where it breaks
local SPLAY = 0.4 -- how much wider it spreads as it does
local WISP_SPOTS = { -50, -25, 0, 25, 50 } -- degrees along the arc its wisps shed from
local FLASH = { Brightness = 1.2, Range = 6, Time = 0.18 } -- the cold light where it breaks: short of the floor
-- Its fade along its length: the heavy start nearly solid, the tail running out.
local FADE = { { 0, 0.1 }, { 0.15, 0 }, { 0.75, 0 }, { 1, 1 } }

export type Visual = {
	Root: BasePart,
	Stroke: Beam,
	Scale: number, -- the stroke's width now, a share of its full width
	Broken: boolean,
}

local BloodBlade = {}

-- A textured Beam draws as a solid band until its texture loads (VFX rules): load the ink before the first cast.
task.spawn(function()
	local probe = Instance.new("Decal")
	probe.Texture = T.InkStroke
	ContentProvider:PreloadAsync({ probe })
	probe:Destroy()
end)

-- A point on the stroke's arc in its plane (X across, Y up before the roll, -Z the way it flies; the middle at 0).
local function point(angle: number): Vector3
	return Vector3.new(RADIUS * math.sin(angle), RADIUS * (math.cos(angle) - 0.75), -BOW * (1 - (angle / HALF_SPAN) ^ 2))
end

-- An attachment on the arc whose X axis runs along it: a Beam's curve leaves and enters along its attachments' X.
local function anchorAt(root: BasePart, angle: number): Attachment
	local at = point(angle)
	local along = (point(angle + 1e-3) - point(angle - 1e-3)).Unit
	local anchor = Instance.new("Attachment")
	anchor.CFrame = CFrame.fromMatrix(at, along, Vector3.zAxis:Cross(along).Unit)
	anchor.Parent = root
	return anchor
end

-- Its fade, `toward` of the way to gone.
local function fade(toward: number): NumberSequence
	local points = {}
	for _, key in FADE do
		table.insert(points, NumberSequenceKeypoint.new(key[1], key[2] + (1 - key[2]) * toward))
	end
	return NumberSequence.new(points)
end

-- The stroke: one curved Beam of ink from its start to its tail.
local function stroke(root: BasePart, from: Attachment, to: Attachment): Beam
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = from, to
	local handle = 4 / 3 * math.tan(HALF_SPAN / 2) * RADIUS -- a cubic's handles for the whole circular arc
	beam.CurveSize0, beam.CurveSize1 = handle, handle
	beam.Segments = SEGMENTS
	beam.FaceCamera = true
	beam.Texture = T.InkStroke
	beam.TextureMode = Enum.TextureMode.Stretch
	beam.Color = ColorSequence.new(V.InkTint)
	beam.Transparency = fade(0)
	beam.LightEmission = 0 -- blended, not added: the black shows
	beam.LightInfluence = 0 -- unlit: the same at dusk as at night
	beam.Parent = root
	return beam
end

-- Its width for a share of the full width: the heavy start, tapering to a point.
local function setScale(visual: Visual, scale: number)
	visual.Scale = scale
	visual.Stroke.Width0, visual.Stroke.Width1 = WIDTH * scale, 0
end

-- The dry bristles of its tail: a frayed streak off a point of the stroke.
local function streak(root: BasePart, at: Vector3, width: number)
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position, a1.Position = at - Vector3.xAxis * width / 2, at + Vector3.xAxis * width / 2
	a0.Parent, a1.Parent = root, root
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Texture = T.SmokeRibbon
	trail.Color = ColorSequence.new(V.Ink)
	trail.Transparency = Kit.Seq({ { 0, 0.2 }, { 1, 1 } })
	trail.WidthScale = Kit.Seq(1, 0)
	trail.Lifetime = 0.25
	trail.LightEmission = 0
	trail.LightInfluence = 0
	trail.FaceCamera = true
	trail.Parent = root
end

function BloodBlade.Spawn(cframe: CFrame): Visual
	local root = Kit.Anchor(cframe)
	local visual: Visual = {
		Root = root,
		Stroke = stroke(root, anchorAt(root, -HALF_SPAN), anchorAt(root, HALF_SPAN)),
		Scale = UNFURL.From,
		Broken = false,
	}
	setScale(visual, UNFURL.From)
	-- ink shedding off it, left hanging in the air behind to dissolve
	for _, degrees in WISP_SPOTS do
		local spot = Instance.new("Attachment")
		spot.Position = point(math.rad(degrees))
		spot.Parent = root
		Kit.Emitter(spot, {
			Texture = T.EnergyWisp,
			Color = Kit.Colors(V.Ink),
			Size = Kit.Seq(0.8, 2.2),
			Transparency = Kit.Seq({ { 0, 1 }, { 0.2, 0.35 }, { 1, 1 } }),
			Lifetime = NumberRange.new(0.45, 0.75),
			Rate = 14,
			Speed = NumberRange.new(0.5, 1.5),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, 2, 0), -- drifting up a little, like ink in water
			Drag = 2,
			Rotation = NumberRange.new(-180, 180),
			RotSpeed = NumberRange.new(-40, 40),
			LightEmission = 0,
			ZOffset = -0.5,
		})
	end
	streak(root, point(HALF_SPAN * 0.9), 0.4)
	streak(root, point(0), 0.6)
	BloodBlade.Move(visual, cframe)
	BloodBlade.Cast(cframe)
	-- it unfurls, then thins as it flies
	Kit.Tween(THIN.Time, function(alpha)
		if visual.Broken then
			return
		end
		local t = alpha * THIN.Time
		setScale(visual, if t < UNFURL.Time
			then UNFURL.From + (1 - UNFURL.From) * math.sin(t / UNFURL.Time * math.pi / 2)
			else 1 - THIN.By * (t - UNFURL.Time) / (THIN.Time - UNFURL.Time))
	end)
	return visual
end

function BloodBlade.Move(visual: Visual, cframe: CFrame)
	visual.Root.CFrame = cframe * CFrame.Angles(0, 0, ROLL)
end

-- A twist of ink at the hand and a pale flick, as the stroke leaves it.
function BloodBlade.Cast(cframe: CFrame)
	Kit.Burst(cframe, {
		{ Count = 6, Texture = T.EnergyWisp, Color = Kit.Colors(V.Ink), Size = Kit.Seq(0.6, 1.8),
			Transparency = Kit.Seq({ { 0, 0.3 }, { 1, 1 } }), Lifetime = NumberRange.new(0.25, 0.4),
			Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(35, 35), EmissionDirection = Enum.NormalId.Front,
			Drag = 4, Rotation = NumberRange.new(-180, 180), RotSpeed = NumberRange.new(-120, 120), LightEmission = 0 },
		{ Count = 1, Texture = T.WindRing, Color = ColorSequence.new(V.InkMoon),
			Size = Kit.Seq({ { 0, 0.4 }, { 1, 3 } }), Transparency = Kit.Seq({ { 0, 0.3 }, { 1, 1 } }),
			Lifetime = NumberRange.new(0.12), Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
			EmissionDirection = Enum.NormalId.Front, Speed = NumberRange.new(0.01), LightEmission = 1 },
	})
end

-- Where it breaks: the stroke splays and fades while its ink curls away, a cold ring of light snapping out.
function BloodBlade.Impact(visual: Visual, position: Vector3, direction: Vector3)
	visual.Broken = true
	local from = visual.Scale
	Kit.Tween(DISSOLVE, function(alpha)
		setScale(visual, from * (1 + SPLAY * alpha))
		visual.Stroke.Transparency = fade(alpha)
	end, function()
		Kit.Release(visual.Root, 0.9) -- the wisps and streaks left in the air finish
	end)
	Kit.Burst(CFrame.lookAt(position, position - direction), {
		{ Count = 14, Texture = T.EnergyWisp, Color = Kit.Colors(V.Ink), Size = Kit.Seq(1, 3),
			Transparency = Kit.Seq({ { 0, 0.2 }, { 1, 1 } }), Lifetime = NumberRange.new(0.6, 0.9),
			Speed = NumberRange.new(4, 10), SpreadAngle = Vector2.new(70, 70), EmissionDirection = Enum.NormalId.Front,
			Acceleration = Vector3.new(0, 4, 0), Drag = 4, Rotation = NumberRange.new(-180, 180),
			RotSpeed = NumberRange.new(-90, 90), LightEmission = 0 },
		{ Count = 5, Texture = T.SmokePuff, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
			FlipbookMode = Enum.ParticleFlipbookMode.OneShot, Color = Kit.Colors(V.Ink), Size = Kit.Seq(2, 5),
			Transparency = Kit.Seq({ { 0, 0.35 }, { 1, 1 } }), Lifetime = NumberRange.new(0.6, 0.9),
			Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(180, 180), Drag = 4,
			Rotation = NumberRange.new(0, 360), LightEmission = 0, ZOffset = -1 },
		{ Count = 1, Texture = T.WindRing, Color = ColorSequence.new(V.InkMoon), Size = Kit.Seq({ { 0, 0.6 }, { 1, 6 } }),
			Transparency = Kit.Seq({ { 0, 0.1 }, { 1, 1 } }), Lifetime = NumberRange.new(0.14), LightEmission = 1,
			ZOffset = 1 },
	})
	Kit.Flash(position, V.InkMoon, FLASH.Brightness, FLASH.Range, FLASH.Time)
end

return BloodBlade

--!strict
-- BloodHit: what a hit on a body shows, from our rendered sprites (tools/blender/vfx_sprites.py): a dark, wet mist
-- plume (blood-red to near-black, alpha-blended so it reads dark, never glowing), a few hot red streaks as its edge,
-- and darker mist settling. Stylized: no wound, no gore. Used by rounds (Gunshot) and blades (CombatFxController).
-- Play(position, spray, scale): `spray` is the way the plume is thrown; scale 1 is a round's, blades hit bigger.

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Parent.UI.Theme)

local T = Kit.Textures
local V = Theme.Vfx

local BloodHit = {}

local function scaled(points: { { number } }, scale: number): NumberSequence
	local keys = {}
	for _, point in points do
		table.insert(keys, { point[1], point[2] * scale })
	end
	return Kit.Seq(keys)
end

function BloodHit.Play(position: Vector3, spray: Vector3, scale: number)
	local direction = if spray.Magnitude > 1e-3 then spray.Unit else Vector3.yAxis
	Kit.Burst(CFrame.lookAt(position, position + direction), {
		{ -- the plume (alpha-blended: darkness can't come from glow)
			Count = 2,
			Texture = T.MistBurst,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
			FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
			Orientation = Enum.ParticleOrientation.VelocityParallel,
			Color = Kit.Colors({ { 0, V.Blood }, { 0.25, V.BloodWet }, { 0.6, V.BloodDeep }, { 1, V.BloodDark } }),
			Transparency = Kit.Seq({ { 0, 0 }, { 0.6, 0.3 }, { 1, 1 } }),
			Size = scaled({ { 0, 1.6 }, { 1, 2.8 } }, scale),
			Lifetime = NumberRange.new(0.35, 0.5),
			Speed = NumberRange.new(1.5 * scale, 3 * scale),
			EmissionDirection = Enum.NormalId.Front,
			SpreadAngle = Vector2.new(35, 35),
			Drag = 4,
			ZOffset = 0.5,
		},
		{ -- its hot edge: a few red streaks
			Count = math.round(6 * scale),
			Texture = T.Spark,
			Orientation = Enum.ParticleOrientation.VelocityParallel,
			Color = Kit.Colors(V.BloodCore, V.Blood),
			LightEmission = 0.4,
			Size = scaled({ { 0, 0.45 }, { 1, 0.2 } }, math.sqrt(scale)),
			Lifetime = NumberRange.new(0.12, 0.22),
			Speed = NumberRange.new(10 * scale, 18 * scale),
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
			Size = scaled({ { 0, 0.8 }, { 1, 1.6 } }, scale),
			Lifetime = NumberRange.new(0.5, 0.6),
			Speed = NumberRange.new(0.5, 1),
			Drag = 3,
			Rotation = NumberRange.new(0, 360),
		},
	})
end

return BloodHit

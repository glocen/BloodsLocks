--!strict
-- Arrival: a hunter appears in the city. A shallow ring of dark-red mist breathes out from their feet and settles,
-- with a short low glow (0.6 s reveal; the brief's spawn effect). Mist and light only: no gore. Play(model) at the
-- model's feet; the effect cleans itself up.

local Theme = require(script.Parent.Parent.UI.Theme)
local Kit = require(script.Parent.Kit)

local T = Kit.Textures
local V = Theme.Vfx

local Arrival = {}

function Arrival.Play(model: Model)
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local feet = root.Position - Vector3.new(0, 2.8, 0)
	Kit.Burst(CFrame.new(feet), {
		{ -- the ring: mist rolling outward along the ground
			Count = 26,
			Texture = T.SmokePuff,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
			FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
			Color = Kit.Colors({ { 0, V.BloodWet }, { 1, V.SmokeDark } }),
			Transparency = Kit.Seq({ { 0, 1 }, { 0.15, 0.35 }, { 1, 1 } }),
			Size = Kit.Seq({ { 0, 1.6 }, { 1, 4.2 } }),
			Lifetime = NumberRange.new(0.6, 0.9),
			Speed = NumberRange.new(9, 13),
			SpreadAngle = Vector2.new(0, 180),
			EmissionDirection = Enum.NormalId.Front,
			Shape = Enum.ParticleEmitterShape.Disc,
			ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
			Drag = 6,
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-40, 40),
			LightEmission = 0.1,
		},
		{ -- a soft column that lifts and fades: the body taking shape
			Count = 10,
			Texture = T.EnergyWisp,
			Color = Kit.Colors(V.BloodDeep, V.Smoke),
			Transparency = Kit.Seq({ { 0, 1 }, { 0.3, 0.55 }, { 1, 1 } }),
			Size = Kit.Seq({ { 0, 2.5 }, { 1, 4 } }),
			Lifetime = NumberRange.new(0.5, 0.7),
			Speed = NumberRange.new(4, 6),
			SpreadAngle = Vector2.new(12, 12),
			EmissionDirection = Enum.NormalId.Top,
			LightEmission = 0.25,
		},
	}, Vector3.new(4, 0.2, 4))
	Kit.Flash(feet + Vector3.new(0, 1.5, 0), V.Blood, 2.2, 12, 0.6)
end

return Arrival

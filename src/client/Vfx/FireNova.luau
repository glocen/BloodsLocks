--!strict
-- FireNova: a ring of fire bursting out from a caster (Kurogane's Gōka). Layers: a ground flash, a wall of flame
-- racing outward on an expanding ring, rising embers and smoke, and a hot light that fades. Delay matches the hit.

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Parent.UI.Theme)

local T = Kit.Textures
local P = Theme.Vfx
local FIRE = P.Fire
local FIRE_DEEP = P.FireDeep
local FIRE_CORE = P.FireCore

local RADIUS = 10
local DELAY = 0.22 -- when the blade hits the ground (the action's Hit.From)
local RING_POINTS = 24

local FireNova = {}

function FireNova.Play(model: Model)
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	task.delay(DELAY, function()
		local ground = root.Position - Vector3.new(0, 2.6, 0)
		-- ground flash
		Kit.Burst(CFrame.new(ground) * CFrame.Angles(math.rad(90), 0, 0), {
			{ Count = 2, Texture = T.Glow, Color = Kit.Colors(FIRE_CORE, FIRE), Size = Kit.Seq(6, RADIUS * 2.6), Transparency = Kit.Seq(0, 1),
				Lifetime = NumberRange.new(0.35), LightEmission = 1, Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
				Speed = NumberRange.new(0.01), EmissionDirection = Enum.NormalId.Top },
		})
		-- flame wall racing outward
		for i = 1, RING_POINTS do
			local angle = (i / RING_POINTS) * math.pi * 2
			local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
			Kit.Burst(CFrame.lookAt(ground + dir * 1.5, ground + dir * 3), {
				-- the wave racing out
				{ Count = 6, Texture = T.Fire, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
					Color = Kit.Colors({ { 0, FIRE_CORE }, { 0.35, FIRE }, { 1, FIRE_DEEP } }), Size = Kit.Seq({ { 0, 3 }, { 0.4, 7.5 }, { 1, 4 } }),
					Transparency = Kit.Seq({ { 0, 0 }, { 0.75, 0.15 }, { 1, 1 } }), Lifetime = NumberRange.new(0.5, 0.75),
					Speed = NumberRange.new(RADIUS * 1.7, RADIUS * 2.2), SpreadAngle = Vector2.new(10, 6), EmissionDirection = Enum.NormalId.Front,
					Drag = 4, Acceleration = Vector3.new(0, 14, 0), Rotation = NumberRange.new(0, 360), LightEmission = 1 },
			})
			-- a standing wall of flame where the wave stops
			Kit.Burst(CFrame.new(ground + dir * RADIUS), {
				{ Count = 4, Texture = T.Fire, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
					Color = Kit.Colors({ { 0, FIRE_CORE }, { 0.4, FIRE }, { 1, FIRE_DEEP } }), Size = Kit.Seq({ { 0, 2 }, { 0.3, 6 }, { 1, 2.5 } }),
					Transparency = Kit.Seq({ { 0, 1 }, { 0.15, 0.05 }, { 0.8, 0.3 }, { 1, 1 } }), Lifetime = NumberRange.new(0.8, 1.2),
					Speed = NumberRange.new(6, 12), SpreadAngle = Vector2.new(12, 12), EmissionDirection = Enum.NormalId.Top,
					Drag = 2, Rotation = NumberRange.new(0, 360), LightEmission = 1 },
			})
		end
		-- embers and smoke
		Kit.Burst(CFrame.new(ground + Vector3.new(0, 1, 0)), {
			{ Count = 40, Texture = T.Dot, Color = Kit.Colors(FIRE_CORE, FIRE), Size = Kit.Seq(0.3, 0),
				Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(10, 26), SpreadAngle = Vector2.new(80, 80),
				EmissionDirection = Enum.NormalId.Top, Acceleration = Vector3.new(0, 6, 0), Drag = 2, LightEmission = 1 },
			{ Count = 10, Texture = T.Smoke, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
				Color = Kit.Colors(P.Smoke, P.SmokeDark), Size = Kit.Seq(4, 9),
				Transparency = Kit.Seq({ { 0, 0.5 }, { 1, 1 } }), Lifetime = NumberRange.new(0.9, 1.4), Speed = NumberRange.new(4, 10),
				SpreadAngle = Vector2.new(70, 70), EmissionDirection = Enum.NormalId.Top, Rotation = NumberRange.new(0, 360), Drag = 2, ZOffset = -1 },
		})
		Kit.Flash(ground + Vector3.new(0, 2, 0), FIRE, 10, 34, 0.9)
	end)
end

return FireNova

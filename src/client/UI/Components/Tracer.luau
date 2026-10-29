--!strict
-- Tracer: a thin bright streak along a bullet's path that fades almost instantly.

local TweenService = game:GetService("TweenService")

local DURATION = 0.09

local Tracer = {}

function Tracer.Draw(origin: Vector3, hitPosition: Vector3, color: Color3)
	local length = (hitPosition - origin).Magnitude
	if length < 0.1 then
		return
	end
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.CastShadow = false
	beam.Material = Enum.Material.Neon
	beam.Color = color
	beam.Size = Vector3.new(0.06, 0.06, length)
	beam.CFrame = CFrame.lookAt((origin + hitPosition) / 2, hitPosition)
	beam.Parent = workspace
	TweenService:Create(beam, TweenInfo.new(DURATION), { Transparency = 1, Size = Vector3.new(0.02, 0.02, length) }):Play()
	task.delay(DURATION + 0.01, function()
		beam:Destroy()
	end)
end

return Tracer

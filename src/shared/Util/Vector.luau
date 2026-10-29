--!strict
-- Vector: small direction helpers shared by simulation and presentation code.

local Vector = {}

-- Horizontal unit vector (Y removed), or zero when there's no horizontal component.
function Vector.Flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return if f.Magnitude > 1e-3 then f.Unit else Vector3.zero
end

-- Turns flat direction `from` toward flat direction `to` by at most `maxStep` radians.
function Vector.TurnToward(from: Vector3, to: Vector3, maxStep: number): Vector3
	local angle = math.atan2(from:Cross(to).Y, from:Dot(to))
	return CFrame.Angles(0, math.clamp(angle, -maxStep, maxStep), 0):VectorToWorldSpace(from)
end

-- Interpolates between two angles (radians) along the shortest path.
function Vector.LerpAngle(a: number, b: number, alpha: number): number
	local diff = (b - a + math.pi) % (2 * math.pi) - math.pi
	return a + diff * alpha
end

-- Exponential smoothing factor for frame-rate independent easing.
function Vector.Smooth(sharpness: number, dt: number): number
	return 1 - math.exp(-sharpness * dt)
end

return Vector

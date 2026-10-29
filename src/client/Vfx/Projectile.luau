--!strict
-- Projectile: client-side flight of a skill projectile. Flies straight from origin along the direction at the
-- server's speed until Finish (the server's ProjectileEnd) or its range runs out. Its look comes from a visual
-- module with Spawn(cframe), Move(visual, cframe) and Impact(visual, position, direction).

export type Look = {
	Spawn: (CFrame) -> any,
	Move: (any, CFrame) -> (),
	Impact: (any, Vector3, Vector3) -> (),
}

export type Projectile = {
	Look: Look,
	Visual: any,
	Origin: Vector3,
	Direction: Vector3,
	Speed: number,
	Range: number,
	Age: number,
	Done: boolean,
}

local Projectile = {}

function Projectile.new(look: Look, origin: Vector3, direction: Vector3, speed: number, range: number): Projectile
	return {
		Look = look,
		Visual = look.Spawn(CFrame.lookAt(origin, origin + direction)),
		Origin = origin,
		Direction = direction,
		Speed = speed,
		Range = range,
		Age = 0,
		Done = false,
	}
end

-- Advances the flight; returns false once it's finished.
function Projectile.Step(projectile: Projectile, dt: number): boolean
	if projectile.Done then
		return false
	end
	projectile.Age += dt
	local traveled = math.min(projectile.Age * projectile.Speed, projectile.Range)
	local position = projectile.Origin + projectile.Direction * traveled
	if traveled >= projectile.Range then
		Projectile.Finish(projectile, position)
		return false
	end
	projectile.Look.Move(projectile.Visual, CFrame.lookAt(position, position + projectile.Direction))
	return true
end

function Projectile.Finish(projectile: Projectile, position: Vector3)
	if projectile.Done then
		return
	end
	projectile.Done = true
	projectile.Look.Impact(projectile.Visual, position, projectile.Direction)
end

return Projectile

--!strict
-- Projectiles: server-simulated projectiles (Blood Blade, ...). A projectile action spawns one projectile At
-- seconds in, flying straight along the shooter's aim; each Heartbeat it sphere-casts the distance it covered,
-- hitting the first entity or stopping at solid geometry. Clients draw it from ProjectileFx/ProjectileEnd.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Parts = require(Shared.Util.Parts)
local Hitscan = require(Shared.Util.Hitscan)
local EntityState = require(Shared.Simulation.EntityState)
local Muzzle = require(Shared.Util.Muzzle)

type OnHit = (attacker: Model, target: Model, hit: any) -> ()
type Flying = {
	Id: number,
	Shooter: Model,
	Position: Vector3,
	Direction: Vector3,
	Remaining: number,
	Spec: any, -- the action's Projectile table
	OnHit: OnHit,
}

local Projectiles = {}

local spawned: { [Model]: number } = {} -- action start time each shooter last spawned for
local flying: { Flying } = {}
local nextId = 0

-- Spawns the action's projectile once, when its time comes.
function Projectiles.Update(model: Model, action: any, startedAt: number, now: number, onHit: OnHit)
	local spec = action.Projectile
	if spawned[model] == startedAt or now - startedAt < spec.At then
		return
	end
	local root = Parts.Root(model)
	if not root then
		return
	end
	spawned[model] = startedAt
	nextId += 1
	local origin, direction = Muzzle.Get(root, model:GetAttribute(EntityState.Attr.Aim))
	table.insert(flying, {
		Id = nextId,
		Shooter = model,
		Position = origin,
		Direction = direction,
		Remaining = spec.Range,
		Spec = spec,
		OnHit = onHit,
	})
	Net.Server.FireAll("ProjectileFx", nextId, spec.Visual, origin, direction, spec.Speed, spec.Range)
end

-- Moves every projectile; call once per Heartbeat.
function Projectiles.Step(dt: number)
	for i = #flying, 1, -1 do
		local projectile = flying[i]
		local distance = math.min(projectile.Spec.Speed * dt, projectile.Remaining)
		local result = Hitscan.Cast(projectile.Position, projectile.Direction, distance, projectile.Spec.Radius, { projectile.Shooter }, EntityState.Tag)
		projectile.Position = result.Position
		projectile.Remaining -= distance
		if result.Entity then
			projectile.OnHit(projectile.Shooter, result.Entity, projectile.Spec.Hit)
		end
		if result.Blocked or projectile.Remaining <= 0 then
			table.remove(flying, i)
			Net.Server.FireAll("ProjectileEnd", projectile.Id, projectile.Position)
		end
	end
end

function Projectiles.Forget(model: Model)
	spawned[model] = nil
end

return Projectiles

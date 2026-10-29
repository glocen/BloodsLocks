--!strict
-- Hitscan: casts along a direction and reports the first combat entity hit, passing through parts you can walk
-- through (decor, VFX). Used for bullets, beam ticks and projectile steps. Server-side.

local CollectionService = game:GetService("CollectionService")

local Raycast = require(script.Parent.Raycast)

local MAX_PASS_THROUGH = 6

export type Result = {
	Position: Vector3,
	Entity: Model?, -- the entity hit, if any
	Blocked: boolean, -- stopped by solid geometry or an entity
}

local Hitscan = {}

local function entityOf(part: BasePart, tag: string): Model?
	local model = part:FindFirstAncestorOfClass("Model")
	while model and not CollectionService:HasTag(model, tag) do
		model = model:FindFirstAncestorOfClass("Model")
	end
	return model
end

-- Casts from `origin` along `direction` (unit) for `distance` studs. `radius` > 0 makes it a sphere cast.
function Hitscan.Cast(origin: Vector3, direction: Vector3, distance: number, radius: number, ignore: { Instance }, tag: string): Result
	local ignoreList = table.clone(ignore)
	local from, remaining = origin, distance
	for _ = 1, MAX_PASS_THROUGH do
		local params = Raycast.Exclude(ignoreList)
		local result = if radius > 0
			then workspace:Spherecast(from, radius, direction * remaining, params)
			else workspace:Raycast(from, direction * remaining, params)
		if not result then
			break
		end
		local entity = entityOf(result.Instance, tag)
		if entity then
			return { Position = result.Position, Entity = entity, Blocked = true }
		elseif result.Instance.CanCollide then
			return { Position = result.Position, Entity = nil, Blocked = true }
		end
		table.insert(ignoreList, result.Instance)
		local traveled = (result.Position - from).Magnitude
		remaining -= traveled
		from = result.Position
		if remaining <= 0 then
			break
		end
	end
	return { Position = origin + direction * distance, Entity = nil, Blocked = false }
end

return Hitscan

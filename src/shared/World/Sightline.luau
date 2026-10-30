--!strict
-- Sightline: which way a spot opens up. From a point at chest height it looks out in DIRECTIONS directions and
-- returns the one with the longest clear view (and that length), so a hunter placed there faces open ground instead
-- of a wall. Spawning uses it for every BL_Spawn; WorldService reports spawns whose best view is short.

local Sightline = {}

local DIRECTIONS = 16
local REACH = 80 -- studs looked out
local CHEST = 4 -- studs above the floor

-- The most open flat direction from `floor` (a floor point) and how far it sees, up to REACH.
function Sightline.Best(floor: Vector3, exclude: { Instance }?): (Vector3, number)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclude or {}
	local origin = floor + Vector3.new(0, CHEST, 0)
	local best, bestReach = Vector3.new(0, 0, -1), -1
	for i = 0, DIRECTIONS - 1 do
		local angle = i / DIRECTIONS * 2 * math.pi
		local direction = Vector3.new(math.sin(angle), 0, -math.cos(angle))
		local hit = workspace:Raycast(origin, direction * REACH, params)
		local reach = if hit then hit.Distance else REACH
		if reach > bestReach then
			best, bestReach = direction, reach
		end
	end
	return best, bestReach
end

return Sightline

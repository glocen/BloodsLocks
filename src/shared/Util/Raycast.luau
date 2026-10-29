--!strict
-- Raycast: parameter builders. Solid casts ignore parts you can walk through (decor, VFX, fog), so those never
-- block sight, aim or the camera.

local Raycast = {}

function Raycast.Exclude(ignore: { Instance }, solid: boolean?): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.RespectCanCollide = solid == true
	return params
end

function Raycast.ExcludeOverlap(ignore: { Instance }): OverlapParams
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	return params
end

return Raycast

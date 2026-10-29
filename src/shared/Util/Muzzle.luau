--!strict
-- Muzzle: where ranged attacks leave from and which way they point, given a root part and an aim direction.
-- Shared so server hit detection and client visuals (beams, projectiles) agree.

local HEIGHT = 1.2
local FORWARD = 1.2

local Muzzle = {}

function Muzzle.Get(root: BasePart, aim: any): (Vector3, Vector3)
	local direction = if typeof(aim) == "Vector3" and aim.Magnitude > 0.5 then aim.Unit else root.CFrame.LookVector
	local forward = Vector3.new(direction.X, 0, direction.Z)
	forward = if forward.Magnitude > 1e-3 then forward.Unit else root.CFrame.LookVector
	return root.Position + Vector3.new(0, HEIGHT, 0) + forward * FORWARD, direction
end

return Muzzle

--!strict
-- Facing: which way the character points, inside the simulation. While locked on it turns toward the target
-- (at the lock turn rate); actions and pushes then hold their own direction (`held`). Roblox's ControlModule resets
-- AutoRotate every step, so it's turned off whenever a direction is held and the root CFrame is set directly.

local Shared = script.Parent.Parent
local Config = require(Shared.Config.Movement)
local Vector = require(Shared.Util.Vector)

local Facing = {}

function Facing.Step(humanoid: Humanoid, root: BasePart, lockDirection: Vector3?, held: Vector3?, dodging: boolean, dt: number)
	local holding = held ~= nil and held ~= Vector3.zero and not dodging
	if (lockDirection or holding) and not dodging then
		if humanoid.AutoRotate then
			humanoid.AutoRotate = false
		end
		local look = Vector.Flat(root.CFrame.LookVector)
		if lockDirection and not holding and look ~= Vector3.zero then
			local turned = Vector.TurnToward(look, lockDirection, math.rad(Config.LockTurnRate) * dt)
			root.CFrame = CFrame.lookAt(root.Position, root.Position + turned)
		end
	elseif not humanoid.AutoRotate then
		humanoid.AutoRotate = true
	end
	if holding then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + held :: Vector3)
	end
end

return Facing

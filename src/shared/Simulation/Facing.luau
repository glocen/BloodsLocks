--!strict
-- Facing: which way the character points, inside the simulation. While locked on it turns toward the target
-- (at the lock turn rate); actions then commit to their own direction. Roblox's ControlModule resets
-- AutoRotate every step, so the root CFrame is set directly instead of relying on AutoRotate staying off.

local Shared = script.Parent.Parent
local Config = require(Shared.Config.Movement)
local Vector = require(Shared.Util.Vector)

local Facing = {}

function Facing.Step(humanoid: Humanoid, root: BasePart, lockDirection: Vector3?, actionFacing: Vector3?, dodging: boolean, dt: number)
	if lockDirection and not dodging then
		if humanoid.AutoRotate then
			humanoid.AutoRotate = false
		end
		local look = Vector.Flat(root.CFrame.LookVector)
		if look ~= Vector3.zero then
			local turned = Vector.TurnToward(look, lockDirection, math.rad(Config.LockTurnRate) * dt)
			root.CFrame = CFrame.lookAt(root.Position, root.Position + turned)
		end
	elseif not humanoid.AutoRotate then
		humanoid.AutoRotate = true
	end
	if actionFacing and actionFacing ~= Vector3.zero and not dodging then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + actionFacing)
	end
end

return Facing

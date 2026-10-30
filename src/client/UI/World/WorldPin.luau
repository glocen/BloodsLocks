--!strict
-- WorldPin: places screen-layer UI over a point in the world. The World layer ignores the GUI inset (its origin is the
-- viewport's) and scales with the Layers, so a viewport point becomes an authored offset by dividing by the scale.

local Layers = require(script.Parent.Parent.Core.Layers)

local WorldPin = {}

-- The authored position of world `point` in the World layer and its depth from the camera, or nil when it's behind
-- the camera or more than `margin` pixels off screen.
function WorldPin.Project(point: Vector3, margin: number?): (UDim2?, number)
	local camera = workspace.CurrentCamera
	local screen = camera:WorldToViewportPoint(point)
	local viewport = camera.ViewportSize
	local edge = margin or 0
	if screen.Z <= 0 or screen.X < -edge or screen.Y < -edge or screen.X > viewport.X + edge or screen.Y > viewport.Y + edge then
		return nil, screen.Z
	end
	local scale = Layers.Scale()
	return UDim2.fromOffset(screen.X / scale, screen.Y / scale), screen.Z
end

return WorldPin

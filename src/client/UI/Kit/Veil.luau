--!strict
-- Veil: the soft darkening a full-screen menu lays over the world so its text reads while the world stays the picture:
-- ink fading in from the left (behind the panels) and from the top and bottom edges (behind the ribbon and the hints).
-- Veil.Menu(parent) adds the standard pair; Veil.Side(parent, rotation, keypoints) one gradient of your own.

local Theme = require(script.Parent.Parent.Theme)

local Veil = {}

function Veil.Side(parent: Instance, rotation: number, keypoints: { NumberSequenceKeypoint }): Frame
	local frame = Instance.new("Frame")
	frame.Name = "Veil"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Theme.Palette.Ink
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = rotation
	gradient.Transparency = NumberSequence.new(keypoints)
	gradient.Parent = frame
	return frame
end

-- The Blood Table's veils: the left third (behind the panels) and the top and bottom edges.
function Veil.Menu(parent: Instance)
	Veil.Side(parent, 0, { NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.36, 0.8), NumberSequenceKeypoint.new(0.6, 1), NumberSequenceKeypoint.new(1, 1) })
	Veil.Side(parent, 90, { NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(0.16, 1), NumberSequenceKeypoint.new(0.82, 1), NumberSequenceKeypoint.new(1, 0.4) })
end

return Veil

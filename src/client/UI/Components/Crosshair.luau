--!strict
-- Crosshair: the center aiming dot.

local Theme = require(script.Parent.Parent.Theme)

local Crosshair = {}

function Crosshair.new(parent: Instance): Frame
	local dot = Instance.new("Frame")
	dot.Name = "Crosshair"
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.Size = UDim2.fromOffset(Theme.CrosshairSize, Theme.CrosshairSize)
	dot.BackgroundColor3 = Theme.Colors.Text
	dot.BorderSizePixel = 0
	dot.Parent = parent
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(1, 0)
	round.Parent = dot
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colors.Background
	stroke.Thickness = 1
	stroke.Parent = dot
	return dot
end

return Crosshair

--!strict
-- Ornament: the small gothic marks the whole UI shares: a diamond, a hairline with diamond terminals, and a gold
-- hairline frame around any GuiObject. Built from frames (crisp at any scale), coloured by Theme.

local Theme = require(script.Parent.Parent.Theme)

local Ornament = {}

local function frame(parent: Instance, props: { [string]: any }): Frame
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = Theme.Colors.Hairline
	for k, v in props do
		(f :: any)[k] = v
	end
	f.Parent = parent
	return f
end

-- A diamond of the given size centred at position.
function Ornament.Diamond(parent: Instance, size: number, position: UDim2, color: Color3?): Frame
	return frame(parent, {
		Name = "Diamond",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = UDim2.fromOffset(size, size),
		Rotation = 45,
		BackgroundColor3 = color or Theme.Colors.Hairline,
	})
end

-- A horizontal hairline spanning width (scale 0..1 of the parent) with a diamond at each end.
function Ornament.Rule(parent: Instance, y: UDim, width: number?, color: Color3?): Frame
	local rule = frame(parent, {
		Name = "Rule",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(UDim.new(0.5, 0), y),
		Size = UDim2.new(width or 1, -12, 0, Theme.Stroke.Hairline),
		BackgroundColor3 = color or Theme.Colors.Hairline,
		BackgroundTransparency = Theme.Transparency.Hairline,
	})
	Ornament.Diamond(rule, 5, UDim2.fromScale(0, 0.5), color)
	Ornament.Diamond(rule, 5, UDim2.fromScale(1, 0.5), color)
	return rule
end

-- A gold hairline border on a GuiObject, with small diamonds at the corners.
function Ornament.Frame(target: GuiObject, color: Color3?, corners: boolean?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = color or Theme.Colors.Hairline
	stroke.Thickness = Theme.Stroke.Hairline
	stroke.Transparency = Theme.Transparency.Hairline
	stroke.Parent = target
	if corners ~= false then
		for _, c in { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) } do
			Ornament.Diamond(target, 5, UDim2.fromScale(c.X, c.Y), color).ZIndex = target.ZIndex + 2
		end
	end
	return stroke
end

return Ornament

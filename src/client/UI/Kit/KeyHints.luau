--!strict
-- KeyHints: the bottom-right prompt row ("[Esc] Back   [Enter] Begin"). Set(list) replaces the hints.

local Theme = require(script.Parent.Parent.Theme)
local Text = require(script.Parent.Text)

local KeyHints = {}

export type Hints = { Frame: Frame, Set: (self: Hints, list: { { string } }) -> () }

local Class = {}
Class.__index = Class

function KeyHints.new(parent: Instance): Hints
	local frame = Instance.new("Frame")
	frame.Name = "KeyHints"
	frame.AnchorPoint = Vector2.new(1, 1)
	frame.Position = UDim2.new(1, -40, 1, -30)
	frame.Size = UDim2.fromOffset(700, 28)
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 22)
	layout.Parent = frame
	return (setmetatable({ Frame = frame }, Class) :: any) :: Hints
end

function Class.Set(self: any, list: { { string } })
	for _, child in self.Frame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for order, pair in list do
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.AutomaticSize = Enum.AutomaticSize.X
		row.Size = UDim2.fromOffset(0, 28)
		row.LayoutOrder = order
		row.Parent = self.Frame
		local inner = Instance.new("UIListLayout")
		inner.FillDirection = Enum.FillDirection.Horizontal
		inner.VerticalAlignment = Enum.VerticalAlignment.Center
		inner.Padding = UDim.new(0, 8)
		inner.Parent = row
		local key = Instance.new("TextLabel")
		key.AutomaticSize = Enum.AutomaticSize.X
		key.Size = UDim2.fromOffset(24, 22)
		key.BackgroundColor3 = Theme.Palette.Bone
		key.BackgroundTransparency = 0.1
		key.BorderSizePixel = 0
		key.FontFace = Theme.Fonts.BodyBold
		key.TextSize = 14
		key.TextColor3 = Theme.Palette.Ink
		key.Text = pair[1]
		key.Parent = row
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 6), UDim.new(0, 6)
		pad.Parent = key
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(0, 3)
		round.Parent = key
		local label = Instance.new("TextLabel")
		label.AutomaticSize = Enum.AutomaticSize.X
		label.Size = UDim2.fromOffset(0, 22)
		label.BackgroundTransparency = 1
		label.FontFace = Theme.Fonts.Body
		label.TextSize = 17
		label.TextColor3 = Theme.Colors.Text
		label.Text = pair[2]
		label.Parent = row
	end
end

return KeyHints

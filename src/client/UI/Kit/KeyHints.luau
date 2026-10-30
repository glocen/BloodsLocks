--!strict
-- KeyHints: the bottom-right prompt row ("(Enter) Seek a Hunt   (Q E) Change tab"). Each key is a hairline glyph,
-- round for one character and a pill for words, then its action in serif. Set(list) replaces the hints.

local Theme = require(script.Parent.Parent.Theme)
local Text = require(script.Parent.Text)

local M = Theme.Menu

local KeyHints = {}

export type Hints = { Frame: Frame, Set: (self: Hints, list: { { string } }) -> () }

local Class = {}
Class.__index = Class

function KeyHints.new(parent: Instance): Hints
	local frame = Instance.new("Frame")
	frame.Name = "KeyHints"
	frame.AnchorPoint = Vector2.new(1, 1)
	frame.Position = UDim2.new(1, -M.Margin, 1, -40)
	frame.Size = UDim2.fromOffset(1100, M.HintGlyph)
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 30)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame
	return (setmetatable({ Frame = frame }, Class) :: any) :: Hints
end

-- A key glyph: a hairline circle for one character, a pill for a word. Also used inside buttons.
function KeyHints.Glyph(parent: Instance, key: string, order: number?): TextLabel
	local single = #key == 1
	local box = Instance.new("TextLabel")
	box.Name = "Key" .. (order or 1)
	box.LayoutOrder = order or 1
	box.AutomaticSize = if single then Enum.AutomaticSize.None else Enum.AutomaticSize.X
	box.Size = UDim2.fromOffset(M.HintGlyph, M.HintGlyph)
	box.BackgroundColor3 = Theme.Palette.Ink
	box.BackgroundTransparency = 0.35
	box.BorderSizePixel = 0
	box.FontFace = Theme.Fonts.Body
	box.TextSize = M.HintTextSize - 3
	box.TextColor3 = Theme.Colors.Text
	box.Text = key
	box.Parent = parent
	Text.Legible(box)
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = box
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Theme.Colors.Text
	stroke.Transparency = 0.3
	stroke.Thickness = Theme.Stroke.Hairline
	stroke.Parent = box
	if not single then
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 12), UDim.new(0, 12)
		pad.Parent = box
	end
	return box
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
		row.Size = UDim2.fromOffset(0, M.HintGlyph)
		row.LayoutOrder = order
		row.Parent = self.Frame
		local inner = Instance.new("UIListLayout")
		inner.FillDirection = Enum.FillDirection.Horizontal
		inner.VerticalAlignment = Enum.VerticalAlignment.Center
		inner.SortOrder = Enum.SortOrder.LayoutOrder
		inner.Padding = UDim.new(0, 10)
		inner.Parent = row
		for i, key in string.split(pair[1], " ") do
			KeyHints.Glyph(row, key, i)
		end
		-- a plain label: Text.new's shadow is a sibling, which a list layout would place as its own item
		local label = Instance.new("TextLabel")
		label.Name = "Action"
		label.AutomaticSize = Enum.AutomaticSize.X
		label.Size = UDim2.fromOffset(0, M.HintGlyph)
		label.BackgroundTransparency = 1
		label.FontFace = Theme.Fonts.Body
		label.TextSize = M.HintTextSize
		label.TextColor3 = Theme.Colors.Text
		label.TextStrokeColor3 = Theme.Colors.Background
		label.TextStrokeTransparency = 0.6
		label.Text = pair[2]
		label.LayoutOrder = 10
		label.Parent = row
		Text.Legible(label)
	end
end

return KeyHints

--!strict
-- PromptCard (HUD layer, bottom centre): our look for world interactions (ProximityPrompts with Style Custom; the
-- Blood Table, pact circles, later chests and lanterns). The object's name in small gold capitals, then the key glyph
-- and the action on a dark ribbon. A hold fills a ring around the key; a triggered prompt flashes the ring gold.
-- Show / Hide fade it; SetHold(0..1) drives the ring.

local Theme = require(script.Parent.Parent.Theme)
local Motion = require(script.Parent.Parent.Core.Motion)
local Text = require(script.Parent.Parent.Kit.Text)
local KeyHints = require(script.Parent.Parent.Kit.KeyHints)
local RingMeter = require(script.Parent.Parent.Kit.RingMeter)

export type PromptCard = {
	Frame: CanvasGroup,
	Show: (self: PromptCard, object: string, action: string, key: string, holds: boolean) -> (),
	Hide: (self: PromptCard) -> (),
	SetHold: (self: PromptCard, progress: number) -> (),
	Confirm: (self: PromptCard) -> (),
}

local WIDTH, HEIGHT = 520, 80
local Y = 0.8 -- of the screen's height: under the posture gauge
local RING = 46

local PromptCard = {}
PromptCard.__index = PromptCard

function PromptCard.new(parent: Instance): PromptCard
	-- a small CanvasGroup only for the fade (allowed for isolated, short-lived elements)
	local frame = Instance.new("CanvasGroup")
	frame.Name = "Prompt"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, Y)
	frame.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	frame.BackgroundTransparency = 1
	frame.GroupTransparency = 1
	frame.Visible = false
	frame.Parent = parent
	local ribbon = Instance.new("Frame") -- behind both lines, fading out at the ends
	ribbon.Name = "Ribbon"
	ribbon.Size = UDim2.fromScale(1, 1)
	ribbon.BackgroundColor3 = Theme.Palette.Ink
	ribbon.BorderSizePixel = 0
	ribbon.Parent = frame
	local fade = Instance.new("UIGradient")
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.22, 0.18),
		NumberSequenceKeypoint.new(0.78, 0.18),
		NumberSequenceKeypoint.new(1, 1),
	})
	fade.Parent = ribbon
	local object = Text.new(frame, "Caption", {
		Name = "Object",
		Position = UDim2.fromOffset(0, 6),
		Size = UDim2.new(1, 0, 0, 20),
		TextColor3 = Theme.Colors.Hairline,
		ZIndex = 3,
	})
	-- the key and the action, centred together on the ribbon
	local row = Instance.new("Frame")
	row.Name = "Row"
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = UDim2.new(0.5, 0, 1, -28)
	row.AutomaticSize = Enum.AutomaticSize.X
	row.Size = UDim2.fromOffset(0, RING)
	row.BackgroundTransparency = 1
	row.ZIndex = 3
	row.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 12)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row
	local keyBox = Instance.new("Frame")
	keyBox.Name = "Key"
	keyBox.LayoutOrder = 1
	keyBox.Size = UDim2.fromOffset(RING, RING)
	keyBox.BackgroundTransparency = 1
	keyBox.Parent = row
	local glyph = KeyHints.Glyph(keyBox, "G")
	glyph.AnchorPoint = Vector2.new(0.5, 0.5)
	glyph.Position = UDim2.fromScale(0.5, 0.5)
	local ring = RingMeter.new(keyBox, RING, UDim2.fromScale(0.5, 0.5), Theme.Colors.Hairline)
	ring:Set(0)
	-- a plain label: Text.new's shadow is a sibling, which the list layout would place as its own item
	local action = Instance.new("TextLabel")
	action.Name = "Action"
	action.LayoutOrder = 2
	action.AutomaticSize = Enum.AutomaticSize.X
	action.Size = UDim2.fromOffset(0, RING)
	action.BackgroundTransparency = 1
	action.FontFace = Theme.Fonts.Body
	action.TextSize = Theme.TextSize.Label + 2
	action.TextColor3 = Theme.Colors.Text
	action.Parent = row
	Text.Legible(action)
	return (setmetatable({
		Frame = frame,
		_object = object,
		_glyph = glyph,
		_ring = ring,
		_action = action,
		_serial = 0,
	}, PromptCard) :: any) :: PromptCard
end

function PromptCard.Show(self: any, object: string, action: string, key: string, holds: boolean)
	self._serial += 1
	self._object.Text = string.upper(object)
	self._action.Text = action
	self._glyph.Text = key
	self._ring.Frame.Visible = holds
	self._ring:Set(0, Theme.Colors.Hairline)
	self.Frame.Visible = true
	Motion.To(self.Frame, { GroupTransparency = 0 }, "Fast")
end

function PromptCard.Hide(self: any)
	self._serial += 1
	local serial = self._serial
	Motion.To(self.Frame, { GroupTransparency = 1 }, "Base").Completed:Connect(function()
		if self._serial == serial then
			self.Frame.Visible = false
		end
	end)
end

function PromptCard.SetHold(self: any, progress: number)
	self._ring:Set(progress)
end

-- The prompt fired: the ring flashes full and gold for a moment.
function PromptCard.Confirm(self: any)
	self._ring.Frame.Visible = true
	self._ring:Set(1, Theme.Colors.Focus)
end

return PromptCard

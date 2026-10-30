--!strict
-- ModeCard: a hunt's painted card (the map's art, Theme.Images.HuntCard) with its place name as a gold caption and the
-- mode as a title over a darkened foot, in a gold hairline frame. The Hunt tab and the Antechamber both show it.
-- Set(caption, title) changes the words.

local Theme = require(script.Parent.Parent.Theme)
local Ornament = require(script.Parent.Ornament)
local Text = require(script.Parent.Text)

export type ModeCard = { Frame: ImageLabel, Set: (self: ModeCard, caption: string, title: string) -> () }

local M = Theme.Menu
local INSET = 20 -- text inset from the card's left edge

local ModeCard = {}
ModeCard.__index = ModeCard

function ModeCard.new(parent: Instance, position: UDim2?): ModeCard
	local card = Instance.new("ImageLabel")
	card.Name = "ModeCard"
	card.Position = position or UDim2.new()
	card.Size = UDim2.fromOffset(M.CardWidth, M.CardHeight)
	card.Image = Theme.Images.HuntCard
	card.ScaleType = Enum.ScaleType.Crop
	card.BackgroundColor3 = Theme.Palette.Ink
	card.BorderSizePixel = 0
	card.Parent = parent
	local foot = Instance.new("Frame") -- darkens the bottom so the title reads
	foot.Size = UDim2.fromScale(1, 1)
	foot.BackgroundColor3 = Theme.Palette.Ink
	foot.BorderSizePixel = 0
	foot.Parent = card
	local footFade = Instance.new("UIGradient")
	footFade.Rotation = 90
	footFade.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.42, 1), NumberSequenceKeypoint.new(0.62, 0.15), NumberSequenceKeypoint.new(1, 0.02) })
	footFade.Parent = foot
	Ornament.Frame(card)
	local caption = Text.new(card, "Caption", {
		Name = "Caption",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Bottom, -- room to grow upward when small screens enlarge it
		TextSize = 16,
		Position = UDim2.new(0, INSET, 1, -78),
		Size = UDim2.fromOffset(M.CardWidth - 2 * INSET, 26),
		TextColor3 = Theme.Colors.Hairline,
		ZIndex = 3,
	})
	local title = Text.new(card, "Title", {
		Name = "Mode",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, INSET, 1, -50),
		Size = UDim2.fromOffset(M.CardWidth - 2 * INSET, 38),
		TextSize = 32,
		ZIndex = 3,
	})
	return (setmetatable({ Frame = card, _caption = caption, _title = title }, ModeCard) :: any) :: ModeCard
end

function ModeCard.Set(self: any, caption: string, title: string)
	self._caption.Text = string.upper(caption)
	self._title.Text = title
end

return ModeCard

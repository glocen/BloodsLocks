--!strict
-- Clock (match HUD, top right; Duskbloods S): the phase dial. An engraved medallion with a ring that fills as the
-- current state runs out, a gold diamond where a ritual site opens (phases with Ritual, at Ritual.ActivateAt) and a
-- red diamond at the end; a roman numeral for the phase; one short state line on a dark ribbon underneath. The last
-- 10 seconds of any deadline turn the ring blood red.

local Theme = require(script.Parent.Parent.Theme)
local RingMeter = require(script.Parent.Parent.Kit.RingMeter)
local Ornament = require(script.Parent.Parent.Kit.Ornament)
local Text = require(script.Parent.Parent.Kit.Text)

export type View = {
	Numeral: string,
	Line: string,
	Progress: number, -- 0..1 of the current state's time used
	Urgent: boolean, -- the last seconds
	Ritual: number?, -- 0..1 where the ritual site opens, for phases that have one
}

export type Clock = { Frame: Frame, Update: (self: Clock, view: View?) -> () }

local SIZE = 112
local RING = 92
local MARGIN = Vector2.new(36, 26)
local LINE_WIDTH = 260
local URGENT_COLOR = Theme.Colors.Danger

local Clock = {}
Clock.__index = Clock

local function onRing(fraction: number): UDim2
	local angle = fraction * 2 * math.pi
	local r = RING / 2
	return UDim2.new(0.5, math.sin(angle) * r, 0.5, -math.cos(angle) * r)
end

function Clock.new(parent: Instance): Clock
	local frame = Instance.new("Frame")
	frame.Name = "Clock"
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Position = UDim2.new(1, -MARGIN.X, 0, MARGIN.Y)
	frame.Size = UDim2.fromOffset(LINE_WIDTH, SIZE + 40)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = parent

	local dial = Instance.new("Frame")
	dial.Name = "Dial"
	dial.AnchorPoint = Vector2.new(0.5, 0)
	dial.Position = UDim2.fromScale(0.5, 0)
	dial.Size = UDim2.fromOffset(SIZE, SIZE)
	dial.BackgroundColor3 = Theme.Palette.Ink
	dial.BackgroundTransparency = 0.2
	dial.BorderSizePixel = 0
	dial.Parent = frame
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = dial
	local bezel = Instance.new("ImageLabel")
	bezel.Name = "Bezel"
	bezel.BackgroundTransparency = 1
	bezel.Image = Theme.Images.Medallion
	bezel.ImageColor3 = Theme.Palette.GoldDim
	bezel.AnchorPoint = Vector2.new(0.5, 0.5)
	bezel.Position = UDim2.fromScale(0.5, 0.5)
	bezel.Size = UDim2.fromScale(1.06, 1.06)
	bezel.ZIndex = 4
	bezel.Parent = dial
	local ring = RingMeter.new(dial, RING, UDim2.fromScale(0.5, 0.5), Theme.Colors.Text)
	ring.Frame.ZIndex = 3
	local ritual = Ornament.Diamond(dial, 9, onRing(0.4), Theme.Colors.Focus)
	ritual.ZIndex = 6
	local finish = Ornament.Diamond(dial, 9, onRing(0), Theme.Colors.Danger)
	finish.ZIndex = 6
	local numeral = Text.new(dial, "Title", {
		Name = "Numeral",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.8, 0.5),
		TextSize = 30,
		ZIndex = 7,
	})

	-- the state line, on a dark ribbon so it reads over a bright sky
	local ribbon = Instance.new("Frame")
	ribbon.Name = "Ribbon"
	ribbon.AnchorPoint = Vector2.new(0.5, 0)
	ribbon.Position = UDim2.new(0.5, 0, 0, SIZE + 8)
	ribbon.Size = UDim2.fromOffset(LINE_WIDTH, 28)
	ribbon.BackgroundColor3 = Theme.Palette.Ink
	ribbon.BorderSizePixel = 0
	ribbon.Parent = frame
	local fade = Instance.new("UIGradient")
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.35),
		NumberSequenceKeypoint.new(0.8, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	fade.Parent = ribbon
	local line = Text.new(ribbon, "Body", {
		Name = "Line",
		Size = UDim2.fromScale(1, 1),
		TextSize = 18,
		ZIndex = 3,
	})
	return (setmetatable({ Frame = frame, _ring = ring, _ritual = ritual, _numeral = numeral, _line = line }, Clock) :: any) :: Clock
end

function Clock.Update(self: any, view: View?)
	self.Frame.Visible = view ~= nil
	if not view then
		return
	end
	self._numeral.Text = view.Numeral
	self._line.Text = view.Line
	self._line.TextColor3 = if view.Urgent then URGENT_COLOR else Theme.Colors.Text
	self._ring:Set(view.Progress, if view.Urgent then URGENT_COLOR else Theme.Colors.Text)
	self._ritual.Visible = view.Ritual ~= nil
	if view.Ritual then
		self._ritual.Position = onRing(view.Ritual)
	end
end

return Clock

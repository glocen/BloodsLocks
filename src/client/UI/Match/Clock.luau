--!strict
-- Clock (match HUD, top right; Duskbloods S): the phase dial (Kit.Dial). Its ring fills as the current state runs
-- out, with a gold diamond where a ritual site opens (phases with Ritual, at Ritual.ActivateAt) and a red one at the
-- end; a roman numeral for the phase; one short state line on a dark ribbon underneath, and the region you're in
-- under that. The last 10 seconds of any deadline turn the ring blood red.

local Theme = require(script.Parent.Parent.Theme)
local Dial = require(script.Parent.Parent.Kit.Dial)
local Text = require(script.Parent.Parent.Kit.Text)

export type View = {
	Numeral: string,
	Line: string,
	Area: string?, -- the region you're in, under the line
	Progress: number, -- 0..1 of the current state's time used
	Urgent: boolean, -- the last seconds
	Ritual: number?, -- 0..1 where the ritual site opens, for phases that have one
}

export type Clock = { Frame: Frame, Update: (self: Clock, view: View?) -> () }

local SIZE = 112
local MARGIN = Vector2.new(36, 26)
local LINE_WIDTH = 260
local URGENT_COLOR = Theme.Colors.Danger

local Clock = {}
Clock.__index = Clock

function Clock.new(parent: Instance): Clock
	local frame = Instance.new("Frame")
	frame.Name = "Clock"
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Position = UDim2.new(1, -MARGIN.X, 0, MARGIN.Y)
	frame.Size = UDim2.fromOffset(LINE_WIDTH, SIZE + 64)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = parent

	local dial = Dial.new(frame, SIZE, UDim2.fromScale(0.5, 0))
	dial:Marker("End", 0, Theme.Colors.Danger)

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
	local area = Text.new(frame, "Caption", {
		Name = "Area",
		Position = UDim2.fromOffset(0, SIZE + 40),
		Size = UDim2.new(1, 0, 0, 20),
		TextColor3 = Theme.Colors.Hairline,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	return (setmetatable({ Frame = frame, _dial = dial, _line = line, _area = area }, Clock) :: any) :: Clock
end

function Clock.Update(self: any, view: View?)
	self.Frame.Visible = view ~= nil
	if not view then
		return
	end
	self._dial:SetText(view.Numeral)
	self._line.Text = view.Line
	self._line.TextColor3 = if view.Urgent then URGENT_COLOR else Theme.Colors.Text
	self._dial:Set(view.Progress, if view.Urgent then URGENT_COLOR else Theme.Colors.Text)
	self._dial:Marker("Ritual", view.Ritual, Theme.Colors.Focus)
	self._area.Text = if view.Area then string.upper(view.Area) else ""
end

return Clock

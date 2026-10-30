--!strict
-- Dial: the engraved medallion gauge the clock and the intermission share. A dark disc in a bronze bezel (our
-- Medallion drawing), a ring that fills clockwise with the time used, a word or number in the middle, and optional
-- diamond markers on the ring (a gold one where a ritual site opens, a red one at the end).

local Theme = require(script.Parent.Parent.Theme)
local RingMeter = require(script.Parent.RingMeter)
local Ornament = require(script.Parent.Ornament)
local Text = require(script.Parent.Text)

export type Dial = {
	Frame: Frame,
	Set: (self: Dial, progress: number, color: Color3?) -> (),
	SetText: (self: Dial, text: string) -> (),
	Marker: (self: Dial, name: string, fraction: number?, color: Color3?) -> (),
}

local Dial = {}
Dial.__index = Dial

function Dial.new(parent: Instance, size: number, position: UDim2, textSize: number?): Dial
	local frame = Instance.new("Frame")
	frame.Name = "Dial"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = position
	frame.Size = UDim2.fromOffset(size, size)
	frame.BackgroundColor3 = Theme.Palette.Ink
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = frame
	local bezel = Instance.new("ImageLabel")
	bezel.Name = "Bezel"
	bezel.BackgroundTransparency = 1
	bezel.Image = Theme.Images.Medallion
	bezel.ImageColor3 = Theme.Palette.GoldDim
	bezel.AnchorPoint = Vector2.new(0.5, 0.5)
	bezel.Position = UDim2.fromScale(0.5, 0.5)
	bezel.Size = UDim2.fromScale(1.06, 1.06)
	bezel.ZIndex = 4
	bezel.Parent = frame
	local ringSize = math.floor(size * 0.82)
	local ring = RingMeter.new(frame, ringSize, UDim2.fromScale(0.5, 0.5), Theme.Colors.Text)
	ring.Frame.ZIndex = 3
	local label = Text.new(frame, "Title", {
		Name = "Middle",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.8, 0.5),
		TextSize = textSize or 30,
		ZIndex = 7,
	})
	return (setmetatable({ Frame = frame, _ring = ring, _label = label, _ringSize = ringSize, _markers = {} }, Dial) :: any) :: Dial
end

function Dial.Set(self: any, progress: number, color: Color3?)
	self._ring:Set(progress, color)
end

function Dial.SetText(self: any, text: string)
	self._label.Text = text
end

-- A diamond on the ring at `fraction` (0..1 clockwise from the top); nil hides it.
function Dial.Marker(self: any, name: string, fraction: number?, color: Color3?)
	local marker = self._markers[name]
	if not marker then
		marker = Ornament.Diamond(self.Frame, 9, UDim2.fromScale(0.5, 0.5), color)
		marker.ZIndex = 6
		self._markers[name] = marker
	end
	marker.Visible = fraction ~= nil
	if fraction then
		local angle = fraction * 2 * math.pi
		local r = self._ringSize / 2
		marker.Position = UDim2.new(0.5, math.sin(angle) * r, 0.5, -math.cos(angle) * r)
		if color then
			marker.BackgroundColor3 = color
		end
	end
end

return Dial

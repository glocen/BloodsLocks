--!strict
-- RingMeter: a circular gauge (the Duskbloods skill ring): a dim full track and a bright arc that fills clockwise
-- from the top. Made from our ring image in two clipped halves whose hard-edged gradients rotate with progress.

local Theme = require(script.Parent.Parent.Theme)

export type RingMeter = {
	Frame: Frame,
	Set: (self: RingMeter, progress: number, color: Color3?) -> (),
	_halves: { { Image: ImageLabel, Gradient: UIGradient } },
}

local RingMeter = {}
RingMeter.__index = RingMeter

local HARD = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(0.501, 1),
	NumberSequenceKeypoint.new(1, 1),
})

local function ringImage(parent: Instance, color: Color3, transparency: number): ImageLabel
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Image = Theme.Images.Ring
	image.ImageColor3 = color
	image.ImageTransparency = transparency
	image.Size = UDim2.fromScale(1, 1)
	image.Parent = parent
	return image
end

-- size in authored pixels; the meter is centred on position.
function RingMeter.new(parent: Instance, size: number, position: UDim2, color: Color3): RingMeter
	local frame = Instance.new("Frame")
	frame.Name = "RingMeter"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = position
	frame.Size = UDim2.fromOffset(size, size)
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	ringImage(frame, Theme.Colors.Background, 0.35) -- track
	local halves = {}
	for side = 0, 1 do -- 0 = right half (first 50%), 1 = left half
		local clip = Instance.new("Frame")
		clip.Name = if side == 0 then "Right" else "Left"
		clip.BackgroundTransparency = 1
		clip.ClipsDescendants = true
		clip.Size = UDim2.fromScale(0.5, 1)
		clip.Position = UDim2.fromScale(if side == 0 then 0.5 else 0, 0)
		clip.Parent = frame
		local image = ringImage(clip, color, 0)
		image.Size = UDim2.fromScale(2, 1)
		image.Position = UDim2.fromScale(if side == 0 then -1 else 0, 0)
		local gradient = Instance.new("UIGradient")
		gradient.Transparency = HARD
		gradient.Parent = image
		table.insert(halves, { Image = image, Gradient = gradient })
	end
	local meter = (setmetatable({ Frame = frame, _halves = halves }, RingMeter) :: any) :: RingMeter
	meter:Set(1, color)
	return meter
end

-- progress 0..1, clockwise from the top.
function RingMeter.Set(self: RingMeter, progress: number, color: Color3?)
	local p = math.clamp(progress, 0, 1)
	self._halves[1].Gradient.Rotation = math.min(p, 0.5) * 360
	self._halves[2].Gradient.Rotation = 180 + math.clamp(p - 0.5, 0, 0.5) * 360
	self._halves[2].Image.Visible = p > 0.5
	if color then
		for _, half in self._halves do
			half.Image.ImageColor3 = color
		end
	end
end

return RingMeter

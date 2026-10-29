--!strict
-- Gauge: a thin HUD bar in the Duskbloods manner: no heavy frame, a dark track with a faint gold hairline, a fill
-- shaded dark → bright, a bright edge at the fill's end, and a pale "lag" chip that drains after a loss so damage
-- reads at a glance. Set(fraction, dt) eases both.

local Theme = require(script.Parent.Parent.Theme)

export type Options = {
	Width: number,
	Height: number,
	Color: Color3,
	ColorDark: Color3,
	Position: UDim2,
	AnchorPoint: Vector2?,
	Lag: boolean?, -- show the damage chip (HP)
}
export type Gauge = {
	Frame: Frame,
	Fill: Frame,
	Set: (self: Gauge, fraction: number, dt: number) -> (),
	_shown: number,
	_lag: number,
	_lagFrame: Frame?,
	_lagHoldUntil: number,
}

local FILL_SHARPNESS = 16
local LAG_HOLD = 0.45 -- seconds the chip waits before draining
local LAG_SPEED = 0.9 -- fraction per second

local Gauge = {}
Gauge.__index = Gauge

local function bar(parent: Instance, name: string, color: Color3, transparency: number, z: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = color
	f.BackgroundTransparency = transparency
	f.BorderSizePixel = 0
	f.ZIndex = z
	f.Parent = parent
	return f
end

function Gauge.new(parent: Instance, options: Options): Gauge
	local frame = Instance.new("Frame")
	frame.Name = "Gauge"
	frame.AnchorPoint = options.AnchorPoint or Vector2.zero
	frame.Position = options.Position
	frame.Size = UDim2.fromOffset(options.Width, options.Height)
	frame.BackgroundColor3 = Theme.Colors.Background
	frame.BackgroundTransparency = 0.35
	frame.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colors.Stroke
	stroke.Transparency = 0.45
	stroke.Thickness = Theme.Stroke.Hairline
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame

	local lagFrame = if options.Lag then bar(frame, "Lag", Theme.Colors.HealthLag, 0.45, 2) else nil
	local fill = bar(frame, "Fill", Color3.new(1, 1, 1), 0, 3)
	local shade = Instance.new("UIGradient")
	shade.Color = ColorSequence.new(options.ColorDark, options.Color)
	shade.Parent = fill
	local sheen = Instance.new("Frame")
	sheen.Name = "Sheen"
	sheen.Size = UDim2.new(1, 0, 0.4, 0)
	sheen.BackgroundColor3 = Color3.new(1, 1, 1)
	sheen.BackgroundTransparency = 0.88
	sheen.BorderSizePixel = 0
	sheen.ZIndex = 4
	sheen.Parent = fill

	frame.Parent = parent
	return (setmetatable({ Frame = frame, Fill = fill, _shown = 1, _lag = 1, _lagFrame = lagFrame, _lagHoldUntil = 0 }, Gauge) :: any) :: Gauge
end

function Gauge.Set(self: Gauge, fraction: number, dt: number)
	local target = math.clamp(fraction, 0, 1)
	local now = os.clock()
	if target < self._shown - 0.001 then
		self._lagHoldUntil = now + LAG_HOLD
	end
	self._shown += (target - self._shown) * math.min(1, dt * FILL_SHARPNESS)
	self.Fill.Size = UDim2.fromScale(self._shown, 1)
	local lagFrame = self._lagFrame
	if lagFrame then
		if self._lag < self._shown then
			self._lag = self._shown
		elseif now >= self._lagHoldUntil then
			self._lag = math.max(self._shown, self._lag - LAG_SPEED * dt)
		end
		lagFrame.Size = UDim2.fromScale(self._lag, 1)
	end
end

return Gauge

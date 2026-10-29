--!strict
-- PostureGauge (centre of the screen, under the character; Duskbloods' stagger gauge): your posture. Hits fill it
-- outward from the centre in ember orange; full means you're staggered and open to a bite. It drains on its own.
-- Always shown, dimmed while empty.

local Theme = require(script.Parent.Parent.Theme)
local Motion = require(script.Parent.Parent.Core.Motion)

export type Gauge = { Frame: CanvasGroup, Update: (self: Gauge, fraction: number, dt: number) -> () }

local WIDTH, HEIGHT = 320, 6
local IDLE_TRANSPARENCY = 0.55

local StaggerGauge = {}
StaggerGauge.__index = StaggerGauge

function StaggerGauge.new(parent: Instance): Gauge
	local group = Instance.new("CanvasGroup")
	group.Name = "PostureGauge"
	group.AnchorPoint = Vector2.new(0.5, 0.5)
	group.Position = UDim2.fromScale(0.5, 0.7)
	group.Size = UDim2.fromOffset(WIDTH + 20, HEIGHT + 16)
	group.BackgroundTransparency = 1
	group.GroupTransparency = IDLE_TRANSPARENCY
	group.Parent = parent

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.AnchorPoint = Vector2.new(0.5, 0.5)
	track.Position = UDim2.fromScale(0.5, 0.5)
	track.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	track.BackgroundColor3 = Theme.Colors.Background
	track.BackgroundTransparency = 0.25
	track.BorderSizePixel = 0
	track.Parent = group
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colors.Stroke
	stroke.Transparency = 0.3
	stroke.Parent = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.AnchorPoint = Vector2.new(0.5, 0.5)
	fill.Position = UDim2.fromScale(0.5, 0.5)
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	fill.BorderSizePixel = 0
	fill.Parent = track
	local shade = Instance.new("UIGradient")
	shade.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.Colors.PostureDark),
		ColorSequenceKeypoint.new(0.5, Theme.Colors.Posture),
		ColorSequenceKeypoint.new(1, Theme.Colors.PostureDark),
	})
	shade.Parent = fill

	-- gold centre mark and end notches
	local pip = Instance.new("Frame")
	pip.Name = "Centre"
	pip.AnchorPoint = Vector2.new(0.5, 0.5)
	pip.Position = UDim2.fromScale(0.5, 0.5)
	pip.Size = UDim2.fromOffset(8, 8)
	pip.Rotation = 45
	pip.BackgroundColor3 = Theme.Colors.Hairline
	pip.BorderSizePixel = 0
	pip.Parent = group
	for _, x in { 0, 1 } do
		local notch = Instance.new("Frame")
		notch.AnchorPoint = Vector2.new(0.5, 0.5)
		notch.Position = UDim2.new(x, if x == 0 then 10 else -10, 0.5, 0)
		notch.Size = UDim2.fromOffset(2, HEIGHT + 8)
		notch.BackgroundColor3 = Theme.Colors.Hairline
		notch.BackgroundTransparency = 0.3
		notch.BorderSizePixel = 0
		notch.Parent = group
	end

	return (setmetatable({ Frame = group, _fill = fill, _shown = 0, _active = false }, StaggerGauge) :: any) :: Gauge
end

function StaggerGauge.Update(self: any, fraction: number, dt: number)
	local target = math.clamp(fraction, 0, 1)
	self._shown += (target - self._shown) * math.min(1, dt * 12)
	self._fill.Size = UDim2.fromScale(self._shown, 1)
	local active = target > 0.005
	if active ~= self._active then
		self._active = active
		Motion.To(self.Frame, { GroupTransparency = if active then 0 else IDLE_TRANSPARENCY }, if active then "Fast" else "Slow")
	end
end

return StaggerGauge

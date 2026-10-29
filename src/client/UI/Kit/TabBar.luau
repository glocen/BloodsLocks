--!strict
-- TabBar: the Duskbloods-style top tab strip: small serif labels separated by thin vertical dividers, the active
-- tab a pale plate with dark text, Q/E hints at the ends. Calls onSelect(index) on click.

local Theme = require(script.Parent.Parent.Theme)
local Motion = require(script.Parent.Parent.Core.Motion)
local Text = require(script.Parent.Text)

export type TabBar = { Frame: Frame, Select: (self: TabBar, index: number) -> () }

local TAB_W, HEIGHT = 196, 34

local TabBar = {}
TabBar.__index = TabBar

function TabBar.new(parent: Instance, labels: { string }, onSelect: (number) -> ()): TabBar
	local frame = Instance.new("Frame")
	frame.Name = "TabBar"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, 22)
	frame.Size = UDim2.fromOffset(TAB_W * #labels + 80, HEIGHT)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	-- a faint dark band behind the strip
	local band = Instance.new("Frame")
	band.Size = UDim2.fromScale(1, 1)
	band.BackgroundColor3 = Theme.Palette.Ink
	band.BackgroundTransparency = 0.35
	band.BorderSizePixel = 0
	band.Parent = frame
	local fade = Instance.new("UIGradient")
	fade.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.08, 0), NumberSequenceKeypoint.new(0.92, 0), NumberSequenceKeypoint.new(1, 1) })
	fade.Parent = band

	for i, key in { "Q", "E" } do
		Text.new(frame, "Caption", {
			Text = key,
			Position = UDim2.new(if i == 1 then 0 else 1, if i == 1 then 8 else -32, 0, 0),
			Size = UDim2.fromOffset(24, HEIGHT),
			TextColor3 = Theme.Colors.TextMuted,
		})
	end

	local tabs = {}
	for i, label in labels do
		local x = 40 + (i - 1) * TAB_W
		local plate = Instance.new("TextButton")
		plate.Name = label
		plate.AutoButtonColor = false
		plate.Text = ""
		plate.Position = UDim2.fromOffset(x + 6, 3)
		plate.Size = UDim2.fromOffset(TAB_W - 12, HEIGHT - 6)
		plate.BackgroundColor3 = Theme.Palette.Bone
		plate.BackgroundTransparency = 1
		plate.BorderSizePixel = 0
		plate.ZIndex = 2
		plate.Parent = frame
		local text = Text.new(plate, "Body", {
			Text = label,
			Size = UDim2.fromScale(1, 1),
			TextSize = 17,
			TextColor3 = Theme.Colors.TextMuted,
			ZIndex = 4,
		})
		if i > 1 then
			local divider = Instance.new("Frame")
			divider.Position = UDim2.fromOffset(x, 8)
			divider.Size = UDim2.fromOffset(1, HEIGHT - 16)
			divider.BackgroundColor3 = Theme.Colors.Stroke
			divider.BackgroundTransparency = 0.3
			divider.BorderSizePixel = 0
			divider.Parent = frame
		end
		plate.MouseEnter:Connect(function()
			if plate.BackgroundTransparency > 0.5 then
				Motion.To(text, { TextColor3 = Theme.Colors.Text }, "Fast")
			end
		end)
		plate.MouseLeave:Connect(function()
			if plate.BackgroundTransparency > 0.5 then
				Motion.To(text, { TextColor3 = Theme.Colors.TextMuted }, "Fast")
			end
		end)
		plate.Activated:Connect(function()
			onSelect(i)
		end)
		tabs[i] = { Plate = plate, Text = text }
	end
	return (setmetatable({ Frame = frame, _tabs = tabs }, TabBar) :: any) :: TabBar
end

function TabBar.Select(self: any, index: number)
	for i, tab in self._tabs do
		local active = i == index
		Motion.To(tab.Plate, { BackgroundTransparency = if active then 0.08 else 1 }, "Fast")
		Motion.To(tab.Text, { TextColor3 = if active then Theme.Palette.Ink else Theme.Colors.TextMuted }, "Fast")
	end
end

return TabBar

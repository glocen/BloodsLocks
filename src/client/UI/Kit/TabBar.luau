--!strict
-- TabBar: the Blood Table's top ribbon (Kit.Ribbon) with equal tabs split by thin dividers and key glyphs for the
-- previous/next keys at the ends. The active tab is a muted mauve plate under a gold filigree (a 9-sliced drawing:
-- sword-guard crosses and lozenges at its ends) that reaches a little past both sides. Calls onSelect(index) on click.

local Theme = require(script.Parent.Parent.Theme)
local Motion = require(script.Parent.Parent.Core.Motion)
local Text = require(script.Parent.Text)
local Ribbon = require(script.Parent.Ribbon)

export type TabBar = { Frame: GuiObject, Select: (self: TabBar, index: number) -> () }

local M = Theme.Menu
local END_W = 72 -- room for the key glyph at each end
local FLOURISH_SLICE = Rect.new(72, 0, 440, 48) -- the filigree image's stretchable middle
local FLOURISH_HEIGHT = 40
local FLOURISH_OVERHANG = 10 -- pixels the filigree reaches past each side of the tab

local TabBar = {}
TabBar.__index = TabBar

local function keyGlyph(parent: Instance, key: string, xScale: number, xOffset: number)
	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.new(xScale, xOffset, 0.5, 0)
	box.Size = UDim2.fromOffset(30, 30)
	box.BackgroundColor3 = Theme.Palette.Ink
	box.BackgroundTransparency = 0.55
	box.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = box
	local stroke = Instance.new("UIStroke")
	stroke.Color = M.TabText
	stroke.Transparency = 0.4
	stroke.Thickness = Theme.Stroke.Hairline
	stroke.Parent = box
	Text.new(box, "Body", { Text = key, Size = UDim2.fromScale(1, 1), TextSize = 19, TextColor3 = M.TabText })
end

function TabBar.new(parent: Instance, labels: { string }, onSelect: (number) -> ()): TabBar
	local frame = Ribbon.new(parent, "TabBar")
	keyGlyph(frame, "Q", 0, END_W / 2)
	keyGlyph(frame, "E", 1, -END_W / 2)

	local strip = Instance.new("Frame")
	strip.Name = "Tabs"
	strip.Position = UDim2.fromOffset(END_W, 0)
	strip.Size = UDim2.new(1, -2 * END_W, 1, 0)
	strip.BackgroundTransparency = 1
	strip.Parent = frame

	local tabs = {}
	local count = #labels
	for i, label in labels do
		local tab = Instance.new("TextButton")
		tab.Name = label
		tab.AutoButtonColor = false
		tab.Text = ""
		tab.Position = UDim2.fromScale((i - 1) / count, 0)
		tab.Size = UDim2.fromScale(1 / count, 1)
		tab.BackgroundColor3 = M.RibbonActive
		tab.BackgroundTransparency = 1
		tab.BorderSizePixel = 0
		tab.Parent = strip
		local plate = Instance.new("UIGradient")
		plate.Rotation = 90
		plate.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 0.4) })
		plate.Parent = tab
		local filigree = Instance.new("ImageLabel")
		filigree.Name = "Filigree"
		filigree.AnchorPoint = Vector2.new(0.5, 0.5)
		filigree.Position = UDim2.new(0.5, 0, 0, 5) -- just inside the top edge, clear of the ribbon's hairline
		filigree.Size = UDim2.new(1, 2 * FLOURISH_OVERHANG, 0, FLOURISH_HEIGHT)
		filigree.BackgroundTransparency = 1
		filigree.Image = Theme.Images.TabFlourish
		filigree.ScaleType = Enum.ScaleType.Slice
		filigree.SliceCenter = FLOURISH_SLICE
		filigree.SliceScale = FLOURISH_HEIGHT / 48
		filigree.ImageTransparency = 1
		filigree.ZIndex = 5
		filigree.Parent = tab
		local text = Text.new(tab, "Body", {
			Text = label,
			Size = UDim2.fromScale(1, 1),
			TextSize = M.TabTextSize,
			TextColor3 = M.TabText,
			TextTransparency = 0.25,
			ZIndex = 4,
		})
		if i > 1 then
			Ribbon.Divider(tab, {
				Position = UDim2.new(0, 0, 0.24, 0),
				Size = UDim2.new(0, Theme.Stroke.Hairline, 0.52, 0),
				BackgroundColor3 = M.TabText,
				BackgroundTransparency = 0.7,
			})
		end
		tab.MouseEnter:Connect(function()
			if tab.BackgroundTransparency > 0.5 then
				Motion.To(text, { TextTransparency = 0 }, "Fast")
			end
		end)
		tab.MouseLeave:Connect(function()
			if tab.BackgroundTransparency > 0.5 then
				Motion.To(text, { TextTransparency = 0.25 }, "Fast")
			end
		end)
		tab.Activated:Connect(function()
			onSelect(i)
		end)
		tabs[i] = { Tab = tab, Text = text, Filigree = filigree }
	end

	local self = setmetatable({ Frame = frame, _tabs = tabs }, TabBar)
	return (self :: any) :: TabBar
end

function TabBar.Select(self: any, index: number)
	for i, t in self._tabs do
		local on = i == index
		Motion.To(t.Tab, { BackgroundTransparency = if on then 0 else 1 }, "Base")
		Motion.To(t.Text, { TextTransparency = if on then 0 else 0.25 }, "Base")
		Motion.To(t.Filigree, { ImageTransparency = if on then 0 else 1 }, "Base")
	end
end

return TabBar

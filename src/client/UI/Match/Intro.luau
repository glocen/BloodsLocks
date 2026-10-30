--!strict
-- Intro (full screen, Transition layer): out of black, "THE DUSK HUNT", the world's name and the rule, then the field
-- of hunters revealed one by one (name, class, an AI mark). Play(view) shows it; Hide() fades it away.

local Theme = require(script.Parent.Parent.Theme)
local Motion = require(script.Parent.Parent.Core.Motion)
local Ornament = require(script.Parent.Parent.Kit.Ornament)
local Text = require(script.Parent.Parent.Kit.Text)

export type Entry = { Name: string, Class: string, Ai: boolean, You: boolean? }
export type View = { World: string, Rule: string, Field: { Entry } }
export type Intro = { Frame: Frame, Play: (self: Intro, view: View) -> (), Hide: (self: Intro) -> () }

local COLUMNS, ROWS = 2, 4
local CELL = Vector2.new(360, 64)
local REVEAL = 0.22 -- seconds between hunters

local Intro = {}
Intro.__index = Intro

function Intro.new(parent: Instance): Intro
	local frame = Instance.new("Frame")
	frame.Name = "Intro"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Theme.Palette.Ink
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = parent
	local center = Instance.new("Frame")
	center.Name = "Center"
	center.AnchorPoint = Vector2.new(0.5, 0.5)
	center.Position = UDim2.fromScale(0.5, 0.5)
	center.Size = UDim2.fromOffset(CELL.X * COLUMNS + 40, 420)
	center.BackgroundTransparency = 1
	center.Parent = frame
	local title = Text.new(center, "Display", {
		Name = "Title",
		Text = "THE DUSK HUNT",
		Size = UDim2.new(1, 0, 0, 64),
		TextSize = 60,
	})
	local world = Text.new(center, "Title", {
		Name = "World",
		Position = UDim2.fromOffset(0, 70),
		Size = UDim2.new(1, 0, 0, 34),
		TextColor3 = Theme.Colors.Hairline,
	})
	local rule = Ornament.Rule(center, UDim.new(0, 122), 0.5)
	local cells = {}
	for i = 1, COLUMNS * ROWS do
		local column, row = (i - 1) % COLUMNS, math.floor((i - 1) / COLUMNS)
		local cell = Instance.new("Frame")
		cell.Name = `Hunter{i}`
		cell.Position = UDim2.fromOffset(20 + column * CELL.X, 150 + row * CELL.Y)
		cell.Size = UDim2.fromOffset(CELL.X - 20, CELL.Y - 10)
		cell.BackgroundTransparency = 1
		cell.Parent = center
		local name = Text.new(cell, "Label", {
			Name = "Name",
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 26),
			TextSize = 22,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextTransparency = 1,
		})
		local class = Text.new(cell, "Body", {
			Name = "Class",
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(0, 26),
			Size = UDim2.new(1, 0, 0, 22),
			TextColor3 = Theme.Colors.TextMuted,
			TextTransparency = 1,
		})
		cells[i] = { Name = name, Class = class }
	end
	return (setmetatable({ Frame = frame, _title = title, _world = world, _rule = rule, _cells = cells, _serial = 0 }, Intro) :: any) :: Intro
end

function Intro.Play(self: any, view: View)
	self._serial += 1
	local serial = self._serial
	self._world.Text = `{view.World} · {view.Rule}`
	for _, cell in self._cells do
		cell.Name.Text, cell.Class.Text = "", ""
		Motion.Set(cell.Name, { TextTransparency = 1 })
		Motion.Set(cell.Class, { TextTransparency = 1 })
	end
	self.Frame.Visible = true
	Motion.To(self.Frame, { BackgroundTransparency = 0 }, "Slow")
	task.spawn(function()
		task.wait(0.6)
		for i, entry in view.Field do
			local cell = self._cells[i]
			if not cell or self._serial ~= serial then
				return
			end
			cell.Name.Text = entry.Name
			cell.Name.TextColor3 = if entry.You then Theme.Colors.Focus else Theme.Colors.Text
			cell.Class.Text = if entry.Ai then `{entry.Class} · AI hunter` else entry.Class
			Motion.To(cell.Name, { TextTransparency = 0 }, "Slow")
			Motion.To(cell.Class, { TextTransparency = 0 }, "Slow")
			task.wait(REVEAL)
		end
	end)
end

function Intro.Hide(self: any)
	self._serial += 1
	if not self.Frame.Visible then
		return
	end
	local serial = self._serial
	for _, cell in self._cells do
		Motion.To(cell.Name, { TextTransparency = 1 }, "Base")
		Motion.To(cell.Class, { TextTransparency = 1 }, "Base")
	end
	Motion.To(self.Frame, { BackgroundTransparency = 1 }, "Slow").Completed:Connect(function()
		if self._serial == serial then
			self.Frame.Visible = false
		end
	end)
end

return Intro

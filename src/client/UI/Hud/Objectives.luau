--!strict
-- Objectives (HUD, left, under the Shinigami card): the hunt's short checklist (Definitions/Objectives). Each line is
-- a small hairline box, gold when done, then the line; a live detail ("rank 4 · the top 6 go on") follows in grey.
-- A soft dark band from the screen edge sits under the lines so they read over a lit façade. Set(nil) hides it;
-- lines fade in when the stage changes.

local Theme = require(script.Parent.Parent.Theme)
local Motion = require(script.Parent.Parent.Core.Motion)
local Text = require(script.Parent.Parent.Kit.Text)
local Veil = require(script.Parent.Parent.Kit.Veil)

export type Line = { Text: string, Detail: string?, Done: boolean }
export type Objectives = { Frame: Frame, Set: (self: Objectives, lines: { Line }?) -> () }

local POSITION = Vector2.new(40, 158) -- under the Shinigami card (Hud/ShinigamiCard at 40, 104, 40 tall)
local WIDTH = 460
local ROW = 28
local BOX = 11
local MAX_LINES = 4
local PAD = 12 -- the band's room above and below the lines
local FADE = 140 -- px past the lines' full width over which the band fades out
local BAND_WIDTH = POSITION.X + WIDTH + FADE
local BAND = { -- dense under the whole line (details included), fading only past it
	NumberSequenceKeypoint.new(0, Theme.Transparency.Scrim),
	NumberSequenceKeypoint.new((POSITION.X + WIDTH) / BAND_WIDTH, Theme.Transparency.Scrim + 0.1),
	NumberSequenceKeypoint.new(1, 1),
}

local Objectives = {}
Objectives.__index = Objectives

function Objectives.new(parent: Instance): Objectives
	local frame = Instance.new("Frame")
	frame.Name = "Objectives"
	frame.Position = UDim2.fromOffset(POSITION.X, POSITION.Y)
	frame.Size = UDim2.fromOffset(WIDTH, ROW * MAX_LINES)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = parent
	local band = Veil.Side(frame, 0, BAND) -- from the screen edge, under everything in the frame
	band.Name = "Band"
	band.Position = UDim2.fromOffset(-POSITION.X, -PAD / 2)
	band.ZIndex = 0
	local rows = {}
	for i = 1, MAX_LINES do
		local y = (i - 1) * ROW
		local box = Instance.new("Frame")
		box.Name = `Box{i}`
		box.AnchorPoint = Vector2.new(0.5, 0.5)
		box.Position = UDim2.fromOffset(BOX / 2 + 2, y + ROW / 2)
		box.Size = UDim2.fromOffset(BOX, BOX)
		box.Rotation = 45
		box.BackgroundColor3 = Theme.Colors.Focus
		box.BackgroundTransparency = 1
		box.BorderSizePixel = 0
		box.Parent = frame
		local edge = Instance.new("UIStroke")
		edge.Color = Theme.Colors.Hairline
		edge.Transparency = 0.2
		edge.Thickness = Theme.Stroke.Hairline
		edge.Parent = box
		local label = Text.new(frame, "Body", {
			Name = `Line{i}`,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			RichText = true,
			Position = UDim2.fromOffset(BOX + 14, y),
			Size = UDim2.new(1, -(BOX + 14), 0, ROW),
		})
		rows[i] = { Box = box, Label = label }
	end
	return (setmetatable({ Frame = frame, _band = band, _rows = rows, _key = "" }, Objectives) :: any) :: Objectives
end

function Objectives.Set(self: any, lines: { Line }?)
	self.Frame.Visible = lines ~= nil and #lines > 0
	if not lines then
		self._key = ""
		return
	end
	self._band.Size = UDim2.fromOffset(BAND_WIDTH, math.min(#lines, MAX_LINES) * ROW + PAD)
	local key = ""
	for _, line in lines do
		key ..= line.Text .. "|"
	end
	local fresh = key ~= self._key -- a new stage: fade the lines in
	self._key = key
	for i, row in self._rows do
		local line = lines[i]
		row.Box.Visible, row.Label.Visible = line ~= nil, line ~= nil
		if line then
			row.Label.Text = if line.Detail then `{line.Text}  <font transparency="0.45">{line.Detail}</font>` else line.Text
			row.Label.TextColor3 = if line.Done then Theme.Colors.TextMuted else Theme.Colors.Text
			row.Box.BackgroundTransparency = if line.Done then 0 else 1
			if fresh then
				row.Label.TextTransparency = 1
				Motion.To(row.Label, { TextTransparency = 0 }, "Slow")
			end
		end
	end
end

return Objectives

--!strict
-- Subtitle (Overlay layer, bottom centre): a line someone speaks, the way Duskbloods prints its Kin's words: white
-- serif under a soft shadow, no box, fading in, held long enough to read, fading out. A new line replaces the one
-- showing. Say(line) shows it.

local Theme = require(script.Parent.Parent.Theme)
local Motion = require(script.Parent.Parent.Core.Motion)
local Text = require(script.Parent.Parent.Kit.Text)

export type Subtitle = { Frame: TextLabel, Say: (self: Subtitle, line: string) -> () }

local BOTTOM = 150 -- px above the bottom edge: clear of the skill dock and the key hints
local WIDTH = 1100
local TEXT_SIZE = 28
local HOLD = { Base = 1.6, PerChar = 0.045 } -- seconds a line stays: enough to read it

local Subtitle = {}
Subtitle.__index = Subtitle

function Subtitle.new(parent: Instance): Subtitle
	local label = Text.new(parent, "Body", {
		Name = "Subtitle",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -BOTTOM),
		Size = UDim2.fromOffset(WIDTH, TEXT_SIZE * 2 + 8),
		TextSize = TEXT_SIZE,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		TextTransparency = 1,
		Visible = false,
	})
	return (setmetatable({ Frame = label, _serial = 0 }, Subtitle) :: any) :: Subtitle
end

function Subtitle.Say(self: any, line: string)
	self._serial += 1
	local serial = self._serial
	local label: TextLabel = self.Frame
	label.Text = line
	label.Visible = true
	Motion.To(label, { TextTransparency = 0 }, "Base")
	task.delay(HOLD.Base + HOLD.PerChar * #line, function()
		if self._serial ~= serial then
			return -- a newer line took its place
		end
		Motion.To(label, { TextTransparency = 1 }, "Slow")
		task.delay(Theme.Motion.Slow, function()
			if self._serial == serial then
				label.Visible = false
			end
		end)
	end)
end

return Subtitle

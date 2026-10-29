--!strict
-- Placeholder: a tab whose system isn't built yet: a centred title, an ornamental rule and one line on what's coming.

local Theme = require(script.Parent.Parent.Theme)
local Text = require(script.Parent.Parent.Kit.Text)
local Ornament = require(script.Parent.Parent.Kit.Ornament)

local Placeholder = {}
Placeholder.__index = Placeholder

export type Screen = { Frame: Frame, Begin: (self: Screen) -> (), Hints: { { string } } }

function Placeholder.new(parent: Instance, title: string, line: string): Screen
	local frame = Instance.new("Frame")
	frame.Name = title
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.45)
	frame.Size = UDim2.fromOffset(700, 140)
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	Text.new(frame, "Display", { Text = title, Size = UDim2.new(1, 0, 0, 56) })
	Ornament.Rule(frame, UDim.new(0, 70), 0.5)
	Text.new(frame, "Body", {
		Text = line,
		Position = UDim2.fromOffset(0, 86),
		Size = UDim2.new(1, 0, 0, 40),
		TextWrapped = true,
		TextColor3 = Theme.Colors.TextMuted,
		TextSize = 20,
	})
	return (setmetatable({ Frame = frame, Hints = { { "Q E", "Change tab" }, { "Backspace", "Leave the table" } } }, Placeholder) :: any) :: Screen
end

function Placeholder.Begin(_self: any) end

return Placeholder

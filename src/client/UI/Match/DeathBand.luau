--!strict
-- DeathBand (Overlay layer): the moment you fall. A dark band across the middle of the screen with the words in the
-- display face (Duskbloods' "You Are Defeated"; ours says "You fell"), over the world, which stays visible above and
-- below it. Show() fades it in; Hide() fades it out.

local Theme = require(script.Parent.Parent.Theme)
local Motion = require(script.Parent.Parent.Core.Motion)
local Text = require(script.Parent.Parent.Kit.Text)

export type DeathBand = { Frame: Frame, Show: (self: DeathBand, words: string) -> (), Hide: (self: DeathBand) -> () }

local HEIGHT = 150
local Y = 0.44 -- of the screen's height

local DeathBand = {}
DeathBand.__index = DeathBand

function DeathBand.new(parent: Instance): DeathBand
	local frame = Instance.new("Frame")
	frame.Name = "DeathBand"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, Y)
	frame.Size = UDim2.new(1, 0, 0, HEIGHT)
	frame.BackgroundColor3 = Theme.Palette.Ink
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = parent
	local soften = Instance.new("UIGradient") -- dark in the middle, fading to nothing at the top and bottom edges
	soften.Rotation = 90
	soften.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.28, 0.25),
		NumberSequenceKeypoint.new(0.72, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	soften.Parent = frame
	local words = Text.new(frame, "Display", {
		Name = "Words",
		Size = UDim2.fromScale(1, 1),
		TextSize = 60,
		TextColor3 = Theme.Colors.Text,
		TextTransparency = 1,
		ZIndex = 3,
	})
	return (setmetatable({ Frame = frame, _words = words, _serial = 0 }, DeathBand) :: any) :: DeathBand
end

function DeathBand.Show(self: any, words: string)
	self._serial += 1
	self._words.Text = words
	self.Frame.Visible = true
	Motion.To(self.Frame, { BackgroundTransparency = 0 }, "Slow")
	Motion.To(self._words, { TextTransparency = 0 }, "Slow")
end

function DeathBand.Hide(self: any)
	self._serial += 1
	local serial = self._serial
	Motion.To(self._words, { TextTransparency = 1 }, "Base")
	Motion.To(self.Frame, { BackgroundTransparency = 1 }, "Base").Completed:Connect(function()
		if self._serial == serial then
			self.Frame.Visible = false
		end
	end)
end

return DeathBand

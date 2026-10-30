--!strict
-- Banner (top centre): a title on a dark ribbon between gold rules, for arrivals ("Phase II") and places ("The
-- Cloister"). Fades in 0.35 s, holds, fades out 0.5 s; a newer banner replaces the current one.

local Theme = require(script.Parent.Parent.Theme)
local Motion = require(script.Parent.Parent.Core.Motion)
local Ornament = require(script.Parent.Parent.Kit.Ornament)
local Text = require(script.Parent.Parent.Kit.Text)

export type Banner = { Frame: CanvasGroup, Show: (self: Banner, title: string, subtitle: string?, hold: number?) -> () }

local TOP = 150 -- below the clock's height and Roblox's top bar; above the fight
local WIDTH, HEIGHT = 620, 84
local HOLD = 2

local Banner = {}
Banner.__index = Banner

function Banner.new(parent: Instance): Banner
	-- a small CanvasGroup only for the fade (the UI standard allows it for isolated, short-lived elements)
	local frame = Instance.new("CanvasGroup")
	frame.Name = "Banner"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, TOP)
	frame.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	frame.BackgroundTransparency = 1
	frame.GroupTransparency = 1
	frame.Visible = false
	frame.Parent = parent
	local ribbon = Instance.new("Frame")
	ribbon.Size = UDim2.fromScale(1, 1)
	ribbon.BackgroundColor3 = Theme.Palette.Ink
	ribbon.BorderSizePixel = 0
	ribbon.Parent = frame
	local fade = Instance.new("UIGradient")
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.18, 0.3),
		NumberSequenceKeypoint.new(0.82, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	fade.Parent = ribbon
	Ornament.Rule(frame, UDim.new(0, 2), 0.7)
	Ornament.Rule(frame, UDim.new(1, -2), 0.7)
	local title = Text.new(frame, "Title", {
		Name = "Title",
		Position = UDim2.fromOffset(0, 10),
		Size = UDim2.new(1, 0, 0, 38),
		TextSize = 34,
		ZIndex = 3,
	})
	local subtitle = Text.new(frame, "Body", {
		Name = "Subtitle",
		Position = UDim2.fromOffset(0, 50),
		Size = UDim2.new(1, 0, 0, 22),
		TextColor3 = Theme.Colors.Hairline,
		ZIndex = 3,
	})
	return (setmetatable({ Frame = frame, _title = title, _subtitle = subtitle, _serial = 0 }, Banner) :: any) :: Banner
end

function Banner.Show(self: any, title: string, subtitle: string?, hold: number?)
	self._serial += 1
	local serial = self._serial
	self._title.Text = string.upper(title)
	self._subtitle.Text = subtitle or ""
	self.Frame.Visible = true
	Motion.To(self.Frame, { GroupTransparency = 0 }, "Slow")
	task.delay(Theme.Motion.Slow + (hold or HOLD), function()
		if self._serial ~= serial then
			return
		end
		local out = Motion.To(self.Frame, { GroupTransparency = 1 }, "Slow")
		out.Completed:Wait()
		if self._serial == serial then
			self.Frame.Visible = false
		end
	end)
end

return Banner

--!strict
-- Antechamber (Menus layer, full screen): what a hunter sees while the match gathers (Waiting, Countdown), in the
-- Blood Table's language around your staged hunter (UI.Core.Stage), like Duskbloods' "Connecting" screen.
--   Top: the ribbon with the room's name between two diamonds.
--   Left: the hunt's card (map, mode); the status band (what's happening, the rules, and the count or the countdown,
--   which pulses red through the last seconds); a note (joins closed, who takes empty seats); the roster: every
--   arrived hunter with their class, then the open seats, dim.
--   Right: a tip that changes every TIP_EVERY seconds (Definitions.Tips: real rule numbers).
-- The controller owns opening and closing (Focus, Stage) and feeds Update(view) every frame.

local Theme = require(script.Parent.Parent.Theme)
local Motion = require(script.Parent.Parent.Core.Motion)
local Ornament = require(script.Parent.Parent.Kit.Ornament)
local Text = require(script.Parent.Parent.Kit.Text)
local Ribbon = require(script.Parent.Parent.Kit.Ribbon)
local ModeCard = require(script.Parent.Parent.Kit.ModeCard)
local Panel = require(script.Parent.Parent.Kit.Panel)
local Veil = require(script.Parent.Parent.Kit.Veil)
local KeyHints = require(script.Parent.Parent.Kit.KeyHints)

export type Entry = { Name: string, Class: string, Ai: boolean }
export type View = {
	Map: string,
	Mode: string,
	Rule: string, -- "Standard rules · alliances allowed"
	Status: string, -- "Gathering hunters", "The hunt begins", "Joins are closed"
	Counter: string, -- "1 / 8" while gathering, "0:24" counting down
	Urgent: boolean, -- the last seconds
	Note: string,
	Roster: { Entry },
	Seats: number,
	StepOutKey: string?, -- the key that steps out into the room, once it's dressed (nil: not available)
}
export type Antechamber = {
	Frame: Frame,
	Update: (self: Antechamber, view: View) -> (),
	SetTips: (self: Antechamber, tips: { string }) -> (),
}

local M = Theme.Menu
local LEFT = M.Margin
local TOP = M.Top + M.TabHeight + 40 -- below the ribbon
local WIDTH = M.CardWidth
local GAP = Theme.Space.L - 4
local PAD = 22 -- text inset inside bands and panels
local BAND = 78 -- the status band's height
local NOTE = 46
local ROW = 34
local HEAD = 46 -- the roster's heading
local MAX_SEATS = 8
local TIP_WIDTH = 540
local TIP_TOP = 340
local TIP_EVERY = 8 -- seconds per tip
local PULSE = 1.2 -- the counter's scale at each of the last seconds

local Antechamber = {}
Antechamber.__index = Antechamber

local function band(parent: Instance, position: UDim2, size: UDim2): Frame
	local frame = Instance.new("Frame")
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = M.Panel
	frame.BackgroundTransparency = 0.18
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local shade = Instance.new("UIGradient")
	shade.Rotation = 90
	shade.Color = ColorSequence.new(Color3.new(1, 1, 1), Theme.PanelShade)
	shade.Parent = frame
	Ornament.Frame(frame, Theme.Colors.Stroke, false)
	return frame
end

function Antechamber.new(parent: Instance): Antechamber
	local frame = Instance.new("Frame")
	frame.Name = "Antechamber"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = parent
	Veil.Menu(frame)
	-- the right side darkens too, behind the tip
	Veil.Side(frame, 180, { NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(0.32, 0.85), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 1) })

	-- the ribbon
	local ribbon = Ribbon.new(frame, "Ribbon")
	Text.new(ribbon, "Body", {
		Name = "Title",
		Text = "The Antechamber",
		Size = UDim2.fromScale(1, 1),
		TextSize = M.TabTextSize,
		TextColor3 = M.TabText,
		ZIndex = 4,
	})
	for _, side in { -1, 1 } do
		Ornament.Diamond(ribbon, 6, UDim2.new(0.5, side * 128, 0.5, 0)).ZIndex = 4
	end

	-- left: the card, the status band, the note, the roster
	local card = ModeCard.new(frame, UDim2.fromOffset(LEFT, TOP))
	local bandY = TOP + M.CardHeight + GAP
	local status = band(frame, UDim2.fromOffset(LEFT, bandY), UDim2.fromOffset(WIDTH, BAND))
	status.Name = "Status"
	local state = Text.new(status, "Label", {
		Name = "State",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(PAD, 12),
		Size = UDim2.new(1, -(PAD * 2 + 150), 0, 28),
		TextSize = 22,
		ZIndex = 3,
	})
	local rule = Text.new(status, "Body", {
		Name = "Rule",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(PAD, 44),
		Size = UDim2.new(1, -(PAD * 2 + 150), 0, 24),
		TextColor3 = Theme.Colors.TextMuted,
		ZIndex = 3,
	})
	local counter = Text.new(status, "Numeric", {
		Name = "Counter",
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -PAD, 0.5, 0),
		Size = UDim2.fromOffset(150, 52),
		TextSize = 40,
		ZIndex = 3,
	})
	local pulse = Instance.new("UIScale")
	pulse.Parent = counter
	local noteY = bandY + BAND + 10
	local note = Text.new(frame, "Body", {
		Name = "Note",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Position = UDim2.fromOffset(LEFT + 4, noteY),
		Size = UDim2.fromOffset(WIDTH - 8, NOTE),
		TextColor3 = Theme.Colors.TextMuted,
	})
	local rosterY = noteY + NOTE + 14
	local roster = Panel.new(frame, {
		Size = UDim2.fromOffset(WIDTH, HEAD + ROW * MAX_SEATS + 14),
		Position = UDim2.fromOffset(LEFT, rosterY),
		Soft = true,
	})
	roster.Name = "Roster"
	Text.new(roster, "Caption", {
		Name = "Heading",
		Text = "HUNTERS",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(PAD, 14),
		Size = UDim2.new(0.5, -PAD, 0, 20),
		TextColor3 = Theme.Colors.Hairline,
	})
	local arrived = Text.new(roster, "Caption", {
		Name = "Arrived",
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(0.5, 0, 0, 14),
		Size = UDim2.new(0.5, -PAD, 0, 20),
		TextColor3 = Theme.Colors.TextMuted,
	})
	Ornament.Rule(roster, UDim.new(0, HEAD - 6), 0.92)
	local rows = {}
	for i = 1, MAX_SEATS do
		local y = HEAD + (i - 1) * ROW
		local name = Text.new(roster, "Body", {
			Name = `Hunter{i}`,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.fromOffset(PAD, y),
			Size = UDim2.new(0.62, -PAD, 0, ROW - 4),
			TextSize = 20,
		})
		local class = Text.new(roster, "Body", {
			Name = `Class{i}`,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.new(0.62, 0, 0, y),
			Size = UDim2.new(0.38, -PAD, 0, ROW - 4),
			TextColor3 = Theme.Colors.TextMuted,
		})
		rows[i] = { Name = name, Class = class }
	end

	-- right: the tip
	local tipBox = Instance.new("Frame")
	tipBox.Name = "Tip"
	tipBox.AnchorPoint = Vector2.new(1, 0)
	tipBox.Position = UDim2.new(1, -M.Margin, 0, TIP_TOP)
	tipBox.Size = UDim2.fromOffset(TIP_WIDTH, 230)
	tipBox.BackgroundTransparency = 1
	tipBox.Parent = frame
	Text.new(tipBox, "Caption", {
		Name = "Heading",
		Text = "BEFORE THE HUNT",
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 20),
		TextColor3 = Theme.Colors.Hairline,
	})
	Ornament.Rule(tipBox, UDim.new(0, 30), 1)
	local tip = Text.new(tipBox, "Body", {
		Name = "Text",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(1, 0, 0, 180),
		TextSize = 22,
	})

	-- bottom-left: stepping out into the room (bottom-right belongs to the hold-Backspace hint)
	local hints = KeyHints.new(frame)
	hints.Frame.AnchorPoint = Vector2.new(0, 1)
	hints.Frame.Position = UDim2.new(0, M.Margin, 1, -40)
	hints.Frame:FindFirstChildOfClass("UIListLayout").HorizontalAlignment = Enum.HorizontalAlignment.Left

	local self = setmetatable({
		Frame = frame,
		_hints = hints,
		_stepOutKey = nil,
		_card = card,
		_state = state,
		_rule = rule,
		_counter = counter,
		_pulse = pulse,
		_note = note,
		_arrived = arrived,
		_rows = rows,
		_tip = tip,
		_tips = {},
		_tipIndex = 0,
		_lastCounter = "",
	}, Antechamber)

	-- the tip changes every TIP_EVERY seconds while the screen is up, with a soft cross-fade
	task.spawn(function()
		while true do
			task.wait(TIP_EVERY)
			if frame.Visible and #self._tips > 1 then
				Motion.To(tip, { TextTransparency = 1 }, "Slow").Completed:Wait()
				self:_nextTip()
				Motion.To(tip, { TextTransparency = 0 }, "Slow")
			end
		end
	end)
	return (self :: any) :: Antechamber
end

function Antechamber._nextTip(self: any)
	if #self._tips == 0 then
		return
	end
	self._tipIndex = self._tipIndex % #self._tips + 1
	self._tip.Text = self._tips[self._tipIndex]
end

function Antechamber.SetTips(self: any, tips: { string })
	self._tips = tips
	self._tipIndex = math.random(math.max(#tips, 1)) - 1
	self:_nextTip()
end

function Antechamber.Update(self: any, view: View)
	self._card:Set(view.Map, view.Mode)
	self._state.Text = view.Status
	self._rule.Text = view.Rule
	self._note.Text = view.Note
	self._counter.TextColor3 = if view.Urgent then Theme.Colors.Danger else Theme.Colors.Text
	if view.Counter ~= self._lastCounter then
		self._lastCounter = view.Counter
		self._counter.Text = view.Counter
		if view.Urgent then
			self._pulse.Scale = PULSE
			Motion.To(self._pulse, { Scale = 1 }, "Slow")
		end
	end
	if view.StepOutKey ~= self._stepOutKey then
		self._stepOutKey = view.StepOutKey
		self._hints:Set(if view.StepOutKey then { { view.StepOutKey, "Step out into the room" } } else {})
	end
	self._arrived.Text = `{#view.Roster} / {view.Seats} ARRIVED`
	for i, row in self._rows do
		local entry = view.Roster[i]
		local seat = i <= view.Seats
		row.Name.Visible, row.Class.Visible = seat, seat
		row.Name.Text = if entry then entry.Name else "Open seat" -- the note says AI hunters take them
		row.Name.TextColor3 = if entry then Theme.Colors.Text else Theme.Colors.TextMuted
		row.Name.TextTransparency = if entry then 0 else 0.45
		row.Class.Text = if entry then (if entry.Ai then `{entry.Class} · AI` else entry.Class) else ""
	end
end

return Antechamber

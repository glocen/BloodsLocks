--!strict
-- Intermission (Menus layer, full screen): between phases, after a death, and on demand (map browse), in Duskbloods'
-- intermission layout with our art. A dark backdrop with a low wine glow (no world behind it); the standings top left
-- (Standings); the match's road top centre (PhaseStrip); the time left top right (a Dial with the seconds, its
-- caption beside it); the district in the middle (MapView); the region you point at, or chose, on the right
-- (RegionInfo); at the bottom the instruction, what happens without a choice, and the keys.
-- Modes: "Choose" (where to begin the next phase), "Rise" (where to come back after a death), "Browse" (look only).
-- The controller owns opening and closing (Focus) and feeds Update(view); choices come back through Chose().

local Theme = require(script.Parent.Parent.Theme)
local Text = require(script.Parent.Parent.Kit.Text)
local KeyHints = require(script.Parent.Parent.Kit.KeyHints)
local Dial = require(script.Parent.Parent.Kit.Dial)
local Standings = require(script.Parent.Standings)
local PhaseStrip = require(script.Parent.PhaseStrip)
local MapView = require(script.Parent.MapView)
local RegionInfo = require(script.Parent.RegionInfo)

export type Mode = "Choose" | "Rise" | "Browse"
export type View = {
	Mode: Mode,
	Seconds: number?, -- the dial's number (nil hides the dial)
	Progress: number, -- 0..1 of the time used
	TimerCaption: string,
	Standings: Standings.View,
	Strip: { PhaseStrip.Node },
	Chosen: string?,
	You: Vector3?,
	Regions: { [string]: RegionInfo.View }, -- what the right panel says about each region
	Empty: string, -- the right panel with nothing pointed at
	Instruction: string,
	Fallback: string,
	Hints: { { string } },
}
export type Intermission = {
	Frame: Frame,
	Build: (self: Intermission, regions: { MapView.Region }, relief: Model?) -> (),
	Update: (self: Intermission, view: View) -> (),
	Chose: (self: Intermission, handler: (string) -> ()) -> (),
}

local M = Theme.Menu
local MAP_SIZE = 740
local DIAL = 120
local URGENT = 5 -- seconds: the dial turns red

local Intermission = {}
Intermission.__index = Intermission

function Intermission.new(parent: Instance): Intermission
	local frame = Instance.new("Frame")
	frame.Name = "Intermission"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Theme.Palette.Ink
	frame.BackgroundTransparency = 0
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = parent
	local glow = Instance.new("ImageLabel") -- a low wine glow behind the map
	glow.Name = "Glow"
	glow.BackgroundTransparency = 1
	glow.Image = Theme.Images.SoftGlow
	glow.ImageColor3 = Theme.Palette.BloodDeep
	glow.ImageTransparency = 0.35
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.5)
	glow.Size = UDim2.fromOffset(1500, 1500)
	glow.Parent = frame

	local standings = Standings.new(frame, UDim2.fromOffset(M.Margin, M.Top))
	local strip = PhaseStrip.new(frame, UDim2.new(0.5, 0, 0, M.Top))
	local dial = Dial.new(frame, DIAL, UDim2.new(1, -(M.Margin + DIAL / 2), 0, M.Top - 10), 40)
	dial:Marker("End", 0, Theme.Colors.Danger)
	local timerCaption = Text.new(frame, "Caption", {
		Name = "TimerCaption",
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -(M.Margin + DIAL + 16), 0, M.Top + DIAL / 2 - 20),
		Size = UDim2.fromOffset(320, 20),
		TextColor3 = Theme.Colors.Hairline,
	})
	local map = MapView.new(frame, UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(MAP_SIZE, MAP_SIZE))
	local info = RegionInfo.new(frame, UDim2.new(1, -M.Margin, 0, M.Top + DIAL + 60))

	local instruction = Text.new(frame, "Title", {
		Name = "Instruction",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -112),
		Size = UDim2.fromOffset(900, 36),
		TextSize = 30,
	})
	local fallback = Text.new(frame, "Body", {
		Name = "Fallback",
		TextWrapped = true,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -82),
		Size = UDim2.fromOffset(900, 26),
		TextColor3 = Theme.Colors.TextMuted,
	})
	local hints = KeyHints.new(frame)
	hints.Frame.AnchorPoint = Vector2.new(0.5, 1)
	hints.Frame.Position = UDim2.new(0.5, 0, 1, -32)
	hints.Frame:FindFirstChildOfClass("UIListLayout").HorizontalAlignment = Enum.HorizontalAlignment.Center

	return (setmetatable({
		Frame = frame,
		_standings = standings,
		_strip = strip,
		_dial = dial,
		_timerCaption = timerCaption,
		_map = map,
		_info = info,
		_instruction = instruction,
		_fallback = fallback,
		_hints = hints,
		_hintKey = "",
	}, Intermission) :: any) :: Intermission
end

function Intermission.Build(self: any, regions: { MapView.Region }, relief: Model?)
	self._map:Build(regions, relief)
end

function Intermission.Update(self: any, view: View)
	self._standings:Set(view.Standings)
	self._strip:Set(view.Strip)
	self._dial.Frame.Visible = view.Seconds ~= nil
	self._timerCaption.Visible = view.Seconds ~= nil
	if view.Seconds then
		local urgent = view.Seconds <= URGENT
		self._dial:SetText(tostring(math.max(0, math.ceil(view.Seconds))))
		self._dial:Set(view.Progress, if urgent then Theme.Colors.Danger else Theme.Colors.Text)
		self._timerCaption.Text = string.upper(view.TimerCaption)
	end
	self._map:SetInteractive(view.Mode ~= "Browse")
	self._map:SetChosen(view.Chosen)
	self._map:SetYou(view.You)
	local pointed = self._map:Hovered() or view.Chosen
	local detail = pointed and view.Regions[pointed]
	self._info:Set(detail or { Lines = {}, Empty = view.Empty })
	self._instruction.Text = view.Instruction
	self._fallback.Text = view.Fallback
	local key = ""
	for _, pair in view.Hints do
		key ..= pair[1] .. pair[2]
	end
	if key ~= self._hintKey then
		self._hintKey = key
		self._hints:Set(view.Hints)
	end
end

function Intermission.Chose(self: any, handler: (string) -> ())
	self._map:Chose(handler)
end

return Intermission

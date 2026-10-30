--!strict
-- Lobby (Antechamber panel, left): while waiting and counting down. The map and rule, one status line ("Waiting for
-- hunters 1 / 1" or "The hunt begins in 0:12"; "Joins are closed" once locked), how the empty seats will be filled
-- (AI hunters, D11), then the roster of arrived hunters with their class.

local Theme = require(script.Parent.Parent.Theme)
local Ornament = require(script.Parent.Parent.Kit.Ornament)
local Text = require(script.Parent.Parent.Kit.Text)

export type Entry = { Name: string, Class: string, Ai: boolean }
export type View = { Map: string, Rule: string, Status: string, Note: string, Roster: { Entry } }
export type Lobby = { Frame: Frame, Update: (self: Lobby, view: View?) -> () }

local M = Theme.Menu
local WIDTH = 440
local ROW = 30
local MAX_ROWS = 8

local Lobby = {}
Lobby.__index = Lobby

function Lobby.new(parent: Instance): Lobby
	local frame = Instance.new("Frame")
	frame.Name = "Lobby"
	frame.Position = UDim2.fromOffset(M.Margin, 200)
	frame.Size = UDim2.fromOffset(WIDTH, 170 + ROW * MAX_ROWS)
	frame.BackgroundColor3 = Theme.Colors.Panel
	frame.BackgroundTransparency = Theme.Transparency.PanelSoft
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = parent
	local shade = Instance.new("UIGradient")
	shade.Rotation = 90
	shade.Color = ColorSequence.new(Color3.new(1, 1, 1), Theme.PanelShade)
	shade.Parent = frame
	Ornament.Frame(frame)
	local pad = 22
	local map = Text.new(frame, "Caption", {
		Name = "Map",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(pad, 16),
		Size = UDim2.new(1, -pad * 2, 0, 18),
		TextColor3 = Theme.Colors.Hairline,
	})
	local title = Text.new(frame, "Title", {
		Name = "Title",
		Text = "The Antechamber",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(pad, 36),
		Size = UDim2.new(1, -pad * 2, 0, 34),
	})
	local status = Text.new(frame, "Label", {
		Name = "Status",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(pad, 80),
		Size = UDim2.new(1, -pad * 2, 0, 24),
	})
	local note = Text.new(frame, "Body", {
		Name = "Note",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Position = UDim2.fromOffset(pad, 108),
		Size = UDim2.new(1, -pad * 2, 0, 40),
		TextColor3 = Theme.Colors.TextMuted,
	})
	Ornament.Rule(frame, UDim.new(0, 156), 0.9)
	local rows = {}
	for i = 1, MAX_ROWS do
		local name = Text.new(frame, "Body", {
			Name = `Hunter{i}`,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(pad, 166 + (i - 1) * ROW),
			Size = UDim2.new(0.6, -pad, 0, ROW - 4),
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		local class = Text.new(frame, "Body", {
			Name = `Class{i}`,
			TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.new(0.6, 0, 0, 166 + (i - 1) * ROW),
			Size = UDim2.new(0.4, -pad, 0, ROW - 4),
			TextColor3 = Theme.Colors.TextMuted,
		})
		rows[i] = { Name = name, Class = class }
	end
	return (setmetatable({ Frame = frame, _map = map, _title = title, _status = status, _note = note, _rows = rows }, Lobby) :: any) :: Lobby
end

function Lobby.Update(self: any, view: View?)
	self.Frame.Visible = view ~= nil
	if not view then
		return
	end
	self._map.Text = string.upper(`{view.Map} · {view.Rule}`)
	self._status.Text = view.Status
	self._note.Text = view.Note
	for i, row in self._rows do
		local entry = view.Roster[i]
		row.Name.Text = if entry then entry.Name else ""
		row.Class.Text = if entry then (if entry.Ai then `{entry.Class} · AI` else entry.Class) else ""
	end
	-- the panel fits the roster
	self.Frame.Size = UDim2.fromOffset(WIDTH, 172 + ROW * math.clamp(#view.Roster, 1, MAX_ROWS))
end

return Lobby

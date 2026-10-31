--!strict
-- Audition (Studio only): the sound audition panel. The cues run down the left, each with a gold diamond once picked.
-- The selected cue's brief and shortlist fill the right: one row per candidate, with its title, its creator (one of
-- Roblox's licensed libraries or a community upload) and its length, a Play button and a Pick button. Built from the UI
-- kit; Controllers/Core/AuditionController plays the sounds and keeps the picks.

local UI = script.Parent.Parent
local Theme = require(UI.Theme)
local Panel = require(UI.Kit.Panel)
local Text = require(UI.Kit.Text)
local Button = require(UI.Kit.Button)

local SIZE = Vector2.new(1440, 900)
local TOP = 84 -- under the panel's title
local CUE_X, CUE_W, CUE_H, CUE_GAP = 28, 330, 38, 3
local LIST_X = 390
local LIST_W = SIZE.X - LIST_X - 28
local ROW_H, ROW_GAP = 66, 6
local ROWS_Y = 186
local ACTION_W, ACTION_H = 130, 44
local FOOTER_Y = 780
local HELP = "PLAY: hear it here. It also becomes this sound in the game, so hide the panel (F2) and try it in a fight. "
	.. "PICK: your choice for this cue. Every sound is levelled to the same loudness."

export type Candidate = { Title: string, Creator: string, Licensed: boolean, From: number, To: number }
export type Entry = { Cue: string, Label: string, Brief: string, Candidates: { Candidate } }
export type Handlers = { Play: (cue: string, index: number) -> (), Pick: (cue: string, index: number) -> () }
export type Screen = {
	Root: Frame,
	SetPicked: (self: Screen, cue: string, index: number) -> (),
	SetVisible: (self: Screen, visible: boolean) -> (),
	Destroy: (self: Screen) -> (),
}

local Audition = {}

local function diamond(parent: Instance, position: UDim2): Frame
	local mark = Instance.new("Frame")
	mark.Name = "Picked"
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Position = position
	mark.Size = UDim2.fromOffset(9, 9)
	mark.Rotation = 45
	mark.BackgroundColor3 = Theme.Colors.Hairline
	mark.BorderSizePixel = 0
	mark.Visible = false
	mark.Parent = parent
	return mark
end

function Audition.new(parent: Instance, entries: { Entry }, handlers: Handlers): Screen
	local root = Panel.new(parent, {
		Size = UDim2.fromOffset(SIZE.X, SIZE.Y),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Title = "Sound audition",
	})
	root.Name = "BL_Audition"

	local picked: { [string]: number } = {}
	local cueRows: { [string]: { Marker: Frame, Diamond: Frame } } = {}
	local selected: string? = nil

	local heading = Text.new(root, "Title", {
		Name = "Cue",
		Position = UDim2.fromOffset(LIST_X, TOP),
		Size = UDim2.fromOffset(LIST_W, 36),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local brief = Text.new(root, "Body", {
		Name = "Brief",
		Position = UDim2.fromOffset(LIST_X, TOP + 42),
		Size = UDim2.fromOffset(LIST_W, 48),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		TextColor3 = Theme.Colors.TextMuted,
	})
	Text.new(root, "Caption", {
		Name = "Help",
		Text = HELP,
		Position = UDim2.fromOffset(LIST_X, FOOTER_Y),
		Size = UDim2.fromOffset(LIST_W, 84),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		TextColor3 = Theme.Colors.TextMuted,
	})
	local list = Instance.new("Frame")
	list.Name = "Candidates"
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromOffset(LIST_X, ROWS_Y)
	list.Size = UDim2.fromOffset(LIST_W, FOOTER_Y - ROWS_Y - 12)
	list.Parent = root

	local function show(cue: string)
		selected = cue
		for name, row in cueRows do
			row.Marker.Visible = name == cue
		end
		local entry: Entry? = nil
		for _, e in entries do
			if e.Cue == cue then
				entry = e
			end
		end
		assert(entry, `Audition: no shortlist for {cue}`)
		heading.Text = entry.Label
		brief.Text = entry.Brief
		list:ClearAllChildren()
		for index, candidate in entry.Candidates do
			local row = Instance.new("Frame")
			row.Name = `Candidate{index}`
			row.Position = UDim2.fromOffset(0, (index - 1) * (ROW_H + ROW_GAP))
			row.Size = UDim2.fromOffset(LIST_W, ROW_H)
			row.BackgroundColor3 = Theme.Colors.PanelSoft
			row.BackgroundTransparency = Theme.Transparency.PanelSoft
			row.BorderSizePixel = 0
			row.Parent = list
			local stroke = Instance.new("UIStroke")
			stroke.Color = Theme.Colors.Hairline
			stroke.Transparency = if picked[cue] == index then 0 else 1
			stroke.Parent = row
			local textWidth = LIST_W - 2 * ACTION_W - 3 * Theme.Space.L
			Text.new(row, "Label", {
				Name = "Title",
				Text = `{index}. {candidate.Title}`,
				Position = UDim2.fromOffset(Theme.Space.M, 8),
				Size = UDim2.fromOffset(textWidth, 26),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})
			local origin = if candidate.Licensed then "licensed library" else "community upload"
			Text.new(row, "Caption", {
				Name = "Meta",
				Text = string.format("%s (%s) · %.2f s", candidate.Creator, origin, candidate.To - candidate.From),
				Position = UDim2.fromOffset(Theme.Space.M, 38),
				Size = UDim2.fromOffset(textWidth, 20),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextColor3 = Theme.Colors.TextMuted,
			})
			Button.new(row, {
				Text = "Play",
				Variant = "Secondary",
				Size = UDim2.fromOffset(ACTION_W, ACTION_H),
				Position = UDim2.fromOffset(LIST_W - 2 * ACTION_W - Theme.Space.L - Theme.Space.M, (ROW_H - ACTION_H) / 2),
				OnClick = function()
					handlers.Play(cue, index)
				end,
			})
			local pick = Button.new(row, {
				Text = if picked[cue] == index then "Picked" else "Pick",
				Variant = "Secondary",
				Size = UDim2.fromOffset(ACTION_W, ACTION_H),
				Position = UDim2.fromOffset(LIST_W - ACTION_W - Theme.Space.M, (ROW_H - ACTION_H) / 2),
				OnClick = function()
					handlers.Pick(cue, index)
				end,
			})
			pick.Instance.Name = "Pick"
		end
	end

	for index, entry in entries do
		local y = TOP + (index - 1) * (CUE_H + CUE_GAP)
		local marker = Instance.new("Frame")
		marker.Name = `{entry.Cue}Marker`
		marker.Position = UDim2.fromOffset(CUE_X - 10, y + 5)
		marker.Size = UDim2.fromOffset(4, CUE_H - 10)
		marker.BackgroundColor3 = Theme.Colors.Focus
		marker.BorderSizePixel = 0
		marker.Visible = false
		marker.Parent = root
		local button = Button.new(root, {
			Text = entry.Label,
			Variant = "Ghost",
			Size = UDim2.fromOffset(CUE_W, CUE_H),
			Position = UDim2.fromOffset(CUE_X, y),
			OnClick = function()
				show(entry.Cue)
			end,
		})
		button.Instance.Name = entry.Cue
		button.Instance.TextXAlignment = Enum.TextXAlignment.Left
		button.Instance.TextTruncate = Enum.TextTruncate.AtEnd
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, Theme.Space.S)
		padding.PaddingRight = UDim.new(0, Theme.Space.L)
		padding.Parent = button.Instance
		cueRows[entry.Cue] = { Marker = marker, Diamond = diamond(button.Instance, UDim2.new(1, Theme.Space.S, 0.5, 0)) }
	end

	local screen = { Root = root }

	function screen.SetPicked(_self: Screen, cue: string, index: number)
		picked[cue] = index
		cueRows[cue].Diamond.Visible = true
		if selected == cue then
			show(cue)
		end
	end

	function screen.SetVisible(_self: Screen, visible: boolean)
		root.Visible = visible
	end

	function screen.Destroy(_self: Screen)
		root:Destroy()
	end

	if entries[1] then
		show(entries[1].Cue)
	end
	return (screen :: any) :: Screen
end

return Audition

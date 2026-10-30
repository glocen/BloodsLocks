--!strict
-- Standings (intermission, top left): you first (your name over a gold rule beside your Renown in the medallion),
-- then every hunter still in the running by rank: rank, name (an "AI" mark for AI hunters), Renown in a small ring.
-- Your row is gold. When the phase ahead ends in a cull, the list opens a gap after the last rank that goes on and a
-- red line runs through it into how many that is.

local Theme = require(script.Parent.Parent.Theme)
local Ornament = require(script.Parent.Parent.Kit.Ornament)
local Text = require(script.Parent.Parent.Kit.Text)

export type Row = { Rank: number, Name: string, Score: number, You: boolean, Ai: boolean }
export type View = { Name: string, Score: number, Rows: { Row }, Cut: number? }
export type Standings = { Frame: Frame, Set: (self: Standings, view: View) -> () }

local WIDTH = 440
local MEDAL = 64
local HEAD = 92 -- your line, before the list
local ROW = 34
local MAX_ROWS = 8
local SCORE = 30 -- the ring around each score
local CUT_GAP = 16 -- the cut line's own room between the last rank that goes on and the next
local CUT_LABEL = 170 -- the cut's words, at the right end of its line

local Standings = {}
Standings.__index = Standings

local function ring(parent: Instance, size: number, color: Color3): ImageLabel
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Image = Theme.Images.Ring
	image.ImageColor3 = color
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Size = UDim2.fromOffset(size, size)
	image.Parent = parent
	return image
end

function Standings.new(parent: Instance, position: UDim2): Standings
	local frame = Instance.new("Frame")
	frame.Name = "Standings"
	frame.Position = position
	frame.Size = UDim2.fromOffset(WIDTH, HEAD + ROW * MAX_ROWS + CUT_GAP + 20)
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	-- you: the medallion with your Renown, your name beside it
	local medal = Instance.new("ImageLabel")
	medal.Name = "Medallion"
	medal.BackgroundColor3 = Theme.Palette.BloodDeep
	medal.Image = Theme.Images.Medallion
	medal.ImageColor3 = Theme.Colors.Hairline
	medal.Size = UDim2.fromOffset(MEDAL, MEDAL)
	medal.Parent = frame
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = medal
	local renown = Text.new(medal, "Numeric", {
		Name = "Renown",
		Size = UDim2.fromScale(1, 1),
		TextSize = 26,
		ZIndex = 3,
	})
	local name = Text.new(frame, "Title", {
		Name = "You",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(MEDAL + 16, 4),
		Size = UDim2.new(1, -(MEDAL + 16), 0, 34),
		TextSize = 28,
	})
	Text.new(frame, "Caption", {
		Name = "Caption",
		Text = "RENOWN",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(MEDAL + 16, 40),
		Size = UDim2.fromOffset(200, 18),
		TextColor3 = Theme.Colors.Hairline,
	})
	Ornament.Rule(frame, UDim.new(0, HEAD - 14), 1)
	local rows = {}
	for i = 1, MAX_ROWS do
		local y = HEAD + (i - 1) * ROW
		local rank = Text.new(frame, "Numeric", {
			Name = `Rank{i}`,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(4, y),
			Size = UDim2.fromOffset(30, ROW - 4),
			TextColor3 = Theme.Colors.TextMuted,
		})
		local who = Text.new(frame, "Body", {
			Name = `Name{i}`,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			RichText = true,
			Position = UDim2.fromOffset(38, y),
			Size = UDim2.new(1, -(38 + SCORE + 16), 0, ROW - 4),
			TextSize = 20,
		})
		local scoreRing = ring(frame, SCORE, Theme.Colors.Stroke)
		scoreRing.Position = UDim2.new(1, -SCORE / 2 - 2, 0, y + (ROW - 4) / 2)
		local score = Text.new(scoreRing, "Numeric", {
			Name = "Score",
			Size = UDim2.fromScale(1, 1),
			TextSize = 16,
			ZIndex = 3,
		})
		rows[i] = { Rank = rank, Name = who, Ring = scoreRing, Score = score }
	end
	local cut = Instance.new("Frame")
	cut.Name = "Cut"
	cut.Size = UDim2.new(1, 0, 0, CUT_GAP)
	cut.BackgroundTransparency = 1
	cut.Visible = false
	cut.Parent = frame
	local line = Instance.new("Frame")
	line.Name = "Line"
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.Position = UDim2.fromScale(0, 0.5)
	line.Size = UDim2.new(1, -(CUT_LABEL + 8), 0, 1)
	line.BackgroundColor3 = Theme.Colors.Danger
	line.BorderSizePixel = 0
	line.Parent = cut
	local cutLabel = Text.new(cut, "Caption", {
		Name = "CutLabel",
		TextXAlignment = Enum.TextXAlignment.Left,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(CUT_LABEL, 18),
		TextColor3 = Theme.Colors.Danger,
	})
	return (setmetatable({ Frame = frame, _renown = renown, _name = name, _rows = rows, _cut = cut, _cutLabel = cutLabel }, Standings) :: any) :: Standings
end

function Standings.Set(self: any, view: View)
	self._name.Text = view.Name
	self._renown.Text = tostring(view.Score)
	local cut = view.Cut
	local cutShown = cut ~= nil and cut < #view.Rows and cut <= #self._rows
	for i, row in self._rows do
		local y = HEAD + (i - 1) * ROW + (if cutShown and i > (cut :: number) then CUT_GAP else 0)
		row.Rank.Position = UDim2.fromOffset(4, y)
		row.Name.Position = UDim2.fromOffset(38, y)
		row.Ring.Position = UDim2.new(1, -SCORE / 2 - 2, 0, y + (ROW - 4) / 2)
		local entry = view.Rows[i]
		local shown = entry ~= nil
		row.Rank.Visible, row.Name.Visible, row.Ring.Visible = shown, shown, shown
		if entry then
			row.Rank.Text = tostring(entry.Rank)
			row.Name.Text = if entry.Ai then `{entry.Name}  <font transparency="0.5">AI</font>` else entry.Name
			row.Name.TextColor3 = if entry.You then Theme.Colors.Focus else Theme.Colors.Text
			row.Score.Text = tostring(entry.Score)
			row.Ring.ImageColor3 = if entry.You then Theme.Colors.Focus else Theme.Colors.Stroke
		end
	end
	self._cut.Visible = cutShown
	if cutShown then
		self._cut.Position = UDim2.fromOffset(0, HEAD + (cut :: number) * ROW - 2) -- centred in the gap
		self._cutLabel.Text = `THE TOP {cut} GO ON`
	end
end

return Standings

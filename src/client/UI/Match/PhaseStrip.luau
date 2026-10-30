--!strict
-- PhaseStrip (intermission, top centre): the match's road. One ring per phase with its numeral, then the final's
-- blood moon, joined by a hairline. Under each, how many hunters enter it (from the rule's culls: 8 · 8 · 6 · 3 for a
-- full field), so the cuts read before they happen. Phases behind you dim; the one coming lights in gold.

local Theme = require(script.Parent.Parent.Theme)
local Text = require(script.Parent.Parent.Kit.Text)

export type Node = { Label: string, Count: number?, State: "Past" | "Next" | "Later", Final: boolean? }
export type PhaseStrip = { Frame: Frame, Set: (self: PhaseStrip, nodes: { Node }) -> () }

local NODE = 44 -- ring size
local STEP = 128 -- centre to centre
local MAX_NODES = 6

local PhaseStrip = {}
PhaseStrip.__index = PhaseStrip

function PhaseStrip.new(parent: Instance, position: UDim2): PhaseStrip
	local frame = Instance.new("Frame")
	frame.Name = "PhaseStrip"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = position
	frame.Size = UDim2.fromOffset(STEP * (MAX_NODES - 1) + NODE, NODE + 34)
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	local line = Instance.new("Frame")
	line.Name = "Road"
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Position = UDim2.new(0.5, 0, 0, NODE / 2)
	line.BackgroundColor3 = Theme.Colors.Hairline
	line.BackgroundTransparency = 0.55
	line.BorderSizePixel = 0
	line.Parent = frame
	local nodes = {}
	for i = 1, MAX_NODES do
		local ring = Instance.new("ImageLabel")
		ring.Name = `Node{i}`
		ring.AnchorPoint = Vector2.new(0.5, 0)
		ring.Size = UDim2.fromOffset(NODE, NODE)
		ring.BackgroundColor3 = Theme.Palette.Ink
		ring.BackgroundTransparency = 0.1
		ring.Image = Theme.Images.Ring
		ring.ZIndex = 2
		ring.Parent = frame
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(0.5, 0)
		round.Parent = ring
		local label = Text.new(ring, "Title", {
			Name = "Numeral",
			Size = UDim2.fromScale(1, 1),
			TextSize = 22,
			ZIndex = 3,
		})
		local count = Text.new(frame, "Numeric", {
			Name = `Count{i}`,
			AnchorPoint = Vector2.new(0.5, 0),
			Size = UDim2.fromOffset(60, 22),
			TextSize = 18,
			TextColor3 = Theme.Colors.TextMuted,
		})
		nodes[i] = { Ring = ring, Label = label, Count = count }
	end
	return (setmetatable({ Frame = frame, _line = line, _nodes = nodes }, PhaseStrip) :: any) :: PhaseStrip
end

function PhaseStrip.Set(self: any, list: { Node })
	local n = math.min(#list, MAX_NODES)
	local width = STEP * (n - 1)
	self._line.Size = UDim2.fromOffset(width, Theme.Stroke.Hairline)
	for i, node in self._nodes do
		local data = list[i]
		local shown = data ~= nil and i <= n
		node.Ring.Visible, node.Count.Visible = shown, shown
		if data and shown then
			local x = -width / 2 + STEP * (i - 1)
			node.Ring.Position = UDim2.new(0.5, x, 0, 0)
			node.Count.Position = UDim2.new(0.5, x, 0, NODE + 8)
			node.Label.Text = data.Label
			node.Count.Text = if data.Count then tostring(data.Count) else ""
			local lit = data.State == "Next"
			local past = data.State == "Past"
			node.Ring.ImageColor3 = if data.Final then Theme.Colors.Danger elseif lit then Theme.Colors.Focus else Theme.Colors.Stroke
			node.Ring.ImageTransparency = if past then 0.6 else 0
			node.Ring.BackgroundColor3 = if data.Final then Theme.Palette.BloodDeep else Theme.Palette.Ink
			node.Label.TextColor3 = if lit then Theme.Colors.Focus else Theme.Colors.Text
			node.Label.TextTransparency = if past then 0.55 else 0
			node.Count.TextColor3 = if lit then Theme.Colors.Text else Theme.Colors.TextMuted
		end
	end
end

return PhaseStrip

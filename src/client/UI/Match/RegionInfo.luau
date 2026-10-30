--!strict
-- RegionInfo (intermission, right): the region under your cursor, or the one you chose. Its name and district, a
-- line about it (the map definition's Blurb), what's there with the map's own marks (pact circle, ritual site, enemy
-- packs, heavies), and how many hunters chose it out of the room it has ("Full" says what that means). With nothing
-- hovered or chosen it asks you to pick.

local Theme = require(script.Parent.Parent.Theme)
local Ornament = require(script.Parent.Parent.Kit.Ornament)
local Text = require(script.Parent.Parent.Kit.Text)

export type Line = { Kind: string, Text: string }
export type View = {
	Name: string?, -- nil: nothing to show yet
	District: string?,
	Blurb: string?,
	Lines: { Line },
	Hunters: string?, -- "2 of 3 places taken", "Full"
	Full: boolean?,
	Empty: string, -- what to say when nothing is hovered or chosen
}
export type RegionInfo = { Frame: Frame, Set: (self: RegionInfo, view: View) -> () }

local MAP = Theme.Map
local WIDTH = 440
local LINE = 30
local MAX_LINES = 6

local RegionInfo = {}
RegionInfo.__index = RegionInfo

function RegionInfo.new(parent: Instance, position: UDim2): RegionInfo
	local frame = Instance.new("Frame")
	frame.Name = "RegionInfo"
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Position = position
	frame.Size = UDim2.fromOffset(WIDTH, 420)
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	local district = Text.new(frame, "Caption", {
		Name = "District",
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 20),
		TextColor3 = Theme.Colors.Hairline,
	})
	local name = Text.new(frame, "Title", {
		Name = "Name",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(0, 22),
		Size = UDim2.new(1, 0, 0, 38),
		TextSize = 34,
	})
	Ornament.Rule(frame, UDim.new(0, 70), 1)
	local blurb = Text.new(frame, "Body", {
		Name = "Blurb",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Position = UDim2.fromOffset(0, 84),
		Size = UDim2.new(1, 0, 0, 76),
		TextColor3 = Theme.Colors.TextMuted,
	})
	local lines = {}
	for i = 1, MAX_LINES do
		local y = 170 + (i - 1) * LINE
		local markHolder = Instance.new("Frame")
		markHolder.Name = `Mark{i}`
		markHolder.BackgroundTransparency = 1
		markHolder.Position = UDim2.fromOffset(0, y)
		markHolder.Size = UDim2.fromOffset(20, LINE - 6)
		markHolder.Parent = frame
		local diamond = Ornament.Diamond(markHolder, 10, UDim2.fromScale(0.5, 0.5))
		local text = Text.new(frame, "Body", {
			Name = `Line{i}`,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.fromOffset(28, y),
			Size = UDim2.new(1, -28, 0, LINE - 6),
		})
		lines[i] = { Holder = markHolder, Mark = diamond, Text = text }
	end
	local hunters = Text.new(frame, "Label", {
		Name = "Hunters",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(0, 170 + MAX_LINES * LINE + 10),
		Size = UDim2.new(1, 0, 0, 26),
	})
	return (setmetatable({ Frame = frame, _district = district, _name = name, _blurb = blurb, _lines = lines, _hunters = hunters }, RegionInfo) :: any) :: RegionInfo
end

function RegionInfo.Set(self: any, view: View)
	local has = view.Name ~= nil
	self._district.Text = if has and view.District then string.upper(view.District) else ""
	self._name.Text = view.Name or ""
	self._blurb.Text = if has then view.Blurb or "" else view.Empty
	for i, line in self._lines do
		local data = if has then view.Lines[i] else nil
		line.Holder.Visible, line.Text.Visible = data ~= nil, data ~= nil
		if data then
			line.Text.Text = data.Text
			line.Mark.BackgroundColor3 = (MAP.Marks :: any)[data.Kind] or Theme.Colors.Text
			line.Mark.Rotation = if data.Kind == "Fodder" then 0 else 45 -- packs are dots on the map, the rest diamonds
		end
	end
	self._hunters.Text = if has then view.Hunters or "" else ""
	self._hunters.TextColor3 = if view.Full then Theme.Colors.Danger else Theme.Colors.Text
end

return RegionInfo

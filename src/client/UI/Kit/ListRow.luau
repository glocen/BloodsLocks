--!strict
-- ListRow: a menu list entry: text on a dark translucent row, a thin gold bar on the left and a brighter row when
-- selected or hovered, an optional muted sub-label on the right. onActivate on click.

local Theme = require(script.Parent.Parent.Theme)
local Motion = require(script.Parent.Parent.Core.Motion)
local Text = require(script.Parent.Text)

export type Row = { Button: TextButton, SetSelected: (self: Row, selected: boolean) -> (), SetSub: (self: Row, text: string) -> () }

local ListRow = {}
ListRow.__index = ListRow

function ListRow.new(parent: Instance, label: string, onActivate: () -> (), width: number?): Row
	local button = Instance.new("TextButton")
	button.Name = label
	button.AutoButtonColor = false
	button.Text = ""
	button.Size = UDim2.fromOffset(width or 380, 40)
	button.BackgroundColor3 = Theme.Palette.Ink
	button.BackgroundTransparency = 0.45
	button.BorderSizePixel = 0
	button.Parent = parent
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.new(0, 2, 1, 0)
	bar.BackgroundColor3 = Theme.Colors.Hairline
	bar.BackgroundTransparency = 1
	bar.BorderSizePixel = 0
	bar.Parent = button
	local text = Text.new(button, "Body", {
		Text = label,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(1, -36, 1, 0),
		TextSize = 19,
		TextColor3 = Theme.Colors.TextMuted,
		ZIndex = 3,
	})
	local sub = Text.new(button, "Caption", {
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(1, -36, 1, 0),
		TextColor3 = Theme.Colors.TextMuted,
		ZIndex = 3,
	})
	local self = setmetatable({ Button = button, _bar = bar, _text = text, _sub = sub, _selected = false }, ListRow)
	local function refresh(hover: boolean)
		local lit = self._selected or hover
		Motion.To(button, { BackgroundTransparency = if self._selected then 0.12 elseif hover then 0.3 else 0.45 }, "Fast")
		Motion.To(bar, { BackgroundTransparency = if self._selected then 0 else 1 }, "Fast")
		Motion.To(text, { TextColor3 = if lit then Theme.Colors.Text else Theme.Colors.TextMuted }, "Fast")
	end
	self._refresh = refresh
	button.MouseEnter:Connect(function() refresh(true) end)
	button.MouseLeave:Connect(function() refresh(false) end)
	button.Activated:Connect(onActivate)
	return (self :: any) :: Row
end

function ListRow.SetSelected(self: any, selected: boolean)
	self._selected = selected
	self._refresh(false)
end

function ListRow.SetSub(self: any, text: string)
	self._sub.Text = text
end

return ListRow

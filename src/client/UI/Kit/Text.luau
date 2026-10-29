--!strict
-- Text: themed labels. Text.new(parent, style, props) where style picks font + size from Theme:
--   "Display" (titles), "Title", "Label" (bold UI labels), "Body", "Caption", "Numeric".

local Theme = require(script.Parent.Parent.Theme)

export type Style = "Display" | "Title" | "Label" | "Body" | "Caption" | "Numeric"

local STYLES: { [string]: { Font: Font, Size: number } } = {
	Display = { Font = Theme.Fonts.Display, Size = Theme.TextSize.Display },
	Title = { Font = Theme.Fonts.Display, Size = Theme.TextSize.Title },
	Label = { Font = Theme.Fonts.BodyBold, Size = Theme.TextSize.Label },
	Body = { Font = Theme.Fonts.Body, Size = Theme.TextSize.Body },
	Caption = { Font = Theme.Fonts.BodyBold, Size = Theme.TextSize.Caption },
	Numeric = { Font = Theme.Fonts.Numeric, Size = Theme.TextSize.Label },
}

local Text = {}

function Text.new(parent: Instance, style: Style, props: { [string]: any }?): TextLabel
	local s = STYLES[style]
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.FontFace = s.Font
	label.TextSize = s.Size
	label.TextColor3 = Theme.Colors.Text
	label.TextStrokeTransparency = 1
	label.Size = UDim2.fromOffset(200, s.Size + 4)
	for k, v in props or {} do
		(label :: any)[k] = v
	end
	-- Soft drop shadow: a dark copy one step down-right, drawn behind the label as its sibling (children always
	-- draw over parents), following its text, look, placement and visibility.
	local shadow = Instance.new("TextLabel")
	shadow.Name = label.Name .. "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.TextColor3 = Theme.Colors.Background
	local function sync()
		shadow.Text = label.Text
		shadow.RichText = label.RichText
		shadow.FontFace = label.FontFace
		shadow.TextSize = label.TextSize
		shadow.TextXAlignment = label.TextXAlignment
		shadow.TextYAlignment = label.TextYAlignment
		shadow.TextTransparency = 0.3 + 0.7 * label.TextTransparency
		shadow.AnchorPoint = label.AnchorPoint
		shadow.Size = label.Size
		shadow.Position = label.Position + UDim2.fromOffset(1, 2)
		shadow.Visible = label.Visible
		shadow.ZIndex = label.ZIndex - 1
	end
	for _, prop in { "Text", "RichText", "FontFace", "TextSize", "TextXAlignment", "TextYAlignment", "TextTransparency", "AnchorPoint", "Size", "Position", "Visible", "ZIndex" } do
		label:GetPropertyChangedSignal(prop):Connect(sync)
	end
	label.AncestryChanged:Connect(function()
		shadow.Parent = label.Parent
	end)
	label.Destroying:Connect(function()
		shadow:Destroy()
	end)
	sync()
	label.ZIndex = math.max(label.ZIndex, 2)
	shadow.Parent = parent
	label.Parent = parent
	return label
end

return Text

--!strict
-- Text: themed labels. Text.new(parent, style, props) where style picks font + size from Theme:
--   "Display" (titles), "Title", "Label" (bold UI labels), "Body", "Caption", "Numeric".
-- Legible: every label keeps its rendered size at Theme.TextSize.MinRendered (captions MinCaption) whatever the
-- window: when the UI scale drops, the authored size rises to compensate (UI standard section 2).

local Theme = require(script.Parent.Parent.Theme)
local Layers = require(script.Parent.Parent.Core.Layers)

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

-- Label properties its shadow copies (the UI lint checks the same list). Position is mirrored with the shadow's offset.
Text.ShadowMirrors = table.freeze({
	"Text", "RichText", "FontFace", "TextSize", "TextScaled", "TextWrapped", "TextTruncate", "LineHeight",
	"MaxVisibleGraphemes", "TextXAlignment", "TextYAlignment", "TextTransparency", "AnchorPoint", "AutomaticSize",
	"Size", "Position", "Rotation", "Visible", "ZIndex",
})

local legible: { [TextLabel]: { Authored: number, Minimum: number } } = setmetatable({}, { __mode = "k" }) :: any
local shadows: { [TextLabel]: TextLabel } = setmetatable({}, { __mode = "k" }) :: any

local function fit(label: TextLabel, entry: { Authored: number, Minimum: number }, scale: number)
	label.TextSize = Theme.LegibleSize(entry.Authored, entry.Minimum, scale)
end

-- Keeps `label` at least `minimum` rendered pixels tall at any UI scale (its current TextSize is the authored one).
function Text.Legible(label: TextLabel, minimum: number?)
	local entry = { Authored = label.TextSize, Minimum = minimum or Theme.TextSize.MinRendered }
	legible[label] = entry
	fit(label, entry, Layers.Scale())
end

-- The rendered size `label` keeps (see Legible), or nil when it isn't managed. The UI lint reads it.
function Text.Minimum(label: TextLabel): number?
	local entry = legible[label]
	return entry and entry.Minimum
end

-- The drop shadow Text.new made for `label`, if any (for the UI lint).
function Text.ShadowOf(label: TextLabel): TextLabel?
	return shadows[label]
end

Layers.ScaleChanged:Connect(function(scale: number)
	for label, entry in legible do
		if label.Parent then
			fit(label, entry, scale)
		end
	end
end)

function Text.new(parent: Instance, style: Style, props: { [string]: any }?): TextLabel
	local s = STYLES[style]
	local label = Instance.new("TextLabel")
	label.Text = "" -- never Roblox's "Label": a label nobody filled in shows nothing
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
	-- draw over parents). It follows everything that shapes the text (wrapping, truncation, line height, typewriter
	-- reveal, auto-size), so it always lies exactly under it, plus placement and visibility.
	local shadow = Instance.new("TextLabel")
	shadow.Name = label.Name .. "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.TextColor3 = Theme.Colors.Background
	local function sync()
		shadow.Text = label.Text
		shadow.RichText = label.RichText
		shadow.FontFace = label.FontFace
		shadow.TextSize = label.TextSize
		shadow.TextScaled = label.TextScaled
		shadow.TextWrapped = label.TextWrapped
		shadow.TextTruncate = label.TextTruncate
		shadow.LineHeight = label.LineHeight
		shadow.MaxVisibleGraphemes = label.MaxVisibleGraphemes
		shadow.TextXAlignment = label.TextXAlignment
		shadow.TextYAlignment = label.TextYAlignment
		shadow.TextTransparency = 0.3 + 0.7 * label.TextTransparency
		shadow.AnchorPoint = label.AnchorPoint
		shadow.AutomaticSize = label.AutomaticSize
		shadow.Size = label.Size
		shadow.Position = label.Position + UDim2.fromOffset(1, 2)
		shadow.Rotation = label.Rotation
		shadow.Visible = label.Visible
		shadow.ZIndex = label.ZIndex - 1
	end
	for _, prop in Text.ShadowMirrors do
		label:GetPropertyChangedSignal(prop):Connect(sync)
	end
	label.AncestryChanged:Connect(function()
		shadow.Parent = label.Parent
	end)
	label.Destroying:Connect(function()
		shadow:Destroy()
	end)
	sync()
	shadows[label] = shadow
	label.ZIndex = math.max(label.ZIndex, 2)
	shadow.Parent = parent
	label.Parent = parent
	Text.Legible(label, if style == "Caption" then Theme.TextSize.MinCaption else Theme.TextSize.MinRendered)
	return label
end

return Text

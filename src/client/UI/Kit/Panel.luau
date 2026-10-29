--!strict
-- Panel: the base surface of menus and HUD groups: translucent velvet with a soft top-to-bottom shade, a gold
-- hairline frame with corner diamonds, and an optional title over an ornamental rule.

local Theme = require(script.Parent.Parent.Theme)
local Ornament = require(script.Parent.Ornament)
local Text = require(script.Parent.Text)

local Panel = {}

export type Options = {
	Size: UDim2,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Title: string?,
	Soft: boolean?, -- lighter, for HUD groups
}

function Panel.new(parent: Instance, options: Options): Frame
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = options.Size
	panel.Position = options.Position or UDim2.new()
	panel.AnchorPoint = options.AnchorPoint or Vector2.zero
	panel.BackgroundColor3 = if options.Soft then Theme.Colors.PanelSoft else Theme.Colors.Panel
	panel.BackgroundTransparency = if options.Soft then Theme.Transparency.PanelSoft else Theme.Transparency.Panel
	panel.BorderSizePixel = 0
	local shade = Instance.new("UIGradient")
	shade.Rotation = 90
	shade.Color = ColorSequence.new(Color3.new(1, 1, 1), Theme.PanelShade)
	shade.Parent = panel
	Ornament.Frame(panel)
	if options.Title then
		local pad = Theme.Space.L
		Text.new(panel, "Title", {
			Name = "Title",
			Text = options.Title,
			Position = UDim2.fromOffset(0, pad),
			Size = UDim2.new(1, 0, 0, Theme.TextSize.Title + 4),
		})
		Ornament.Rule(panel, UDim.new(0, pad + Theme.TextSize.Title + Theme.Space.S), 0.8)
	end
	panel.Parent = parent
	return panel
end

return Panel

--!strict
-- Ribbon: the Blood Table's top band, shared by every full-screen menu: brushed wine-brown paint (our drawn texture,
-- tinted and tiled) between a bright gold hairline above and a dim one below. Ribbon.new returns the band; callers
-- put tabs or a title on it.

local Theme = require(script.Parent.Parent.Theme)

local M = Theme.Menu
local TILE = Vector2.new(512, 64) -- the ribbon texture's size

local Ribbon = {}

local function line(parent: Instance, props: { [string]: any }): Frame
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = Theme.Colors.Hairline
	for k, v in props do
		(f :: any)[k] = v
	end
	f.Parent = parent
	return f
end

-- A full-width band at the menu's top margin (Theme.Menu.Top, TabHeight tall, Margin from each side).
function Ribbon.new(parent: Instance, name: string): ImageLabel
	local band = Instance.new("ImageLabel")
	band.Name = name
	band.Position = UDim2.fromOffset(M.Margin, M.Top)
	band.Size = UDim2.new(1, -2 * M.Margin, 0, M.TabHeight)
	band.BackgroundColor3 = Theme.Palette.Ink
	band.BackgroundTransparency = 0.1
	band.BorderSizePixel = 0
	band.Image = Theme.Images.Ribbon
	band.ImageColor3 = M.RibbonTint
	band.ScaleType = Enum.ScaleType.Tile
	band.TileSize = UDim2.fromOffset(TILE.X, TILE.Y)
	band.Parent = parent
	local shade = Instance.new("UIGradient")
	shade.Rotation = 90
	shade.Color = ColorSequence.new(Color3.new(1, 1, 1), M.RibbonShade)
	shade.Parent = band
	line(band, { Name = "Top", Size = UDim2.new(1, 0, 0, Theme.Stroke.Hairline), BackgroundTransparency = 0.15 })
	line(band, {
		Name = "Bottom",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, Theme.Stroke.Hairline),
		BackgroundTransparency = 0.55,
	})
	return band
end

-- A thin divider line on the band (between tabs, or around a title).
function Ribbon.Divider(band: Instance, props: { [string]: any }): Frame
	return line(band, props)
end

return Ribbon

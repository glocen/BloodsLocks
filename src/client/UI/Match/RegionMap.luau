--!strict
-- RegionMap (full screen, Menus layer): choose where to begin the next phase, or where to rise after a death.
--   Right: the district from above, a live copy of the world (MatchState.Relief) in a ViewportFrame, lit like a model
--   on a table; each region a tinted shape with its name, key and state. Hover lights a region; a click or its number
--   key chooses it (gold, with "Chosen": never colour alone).
--   Left: the heading for the mode, the deadline, what happens without a choice, and the standings with the cut line.
-- The controller owns opening/closing (Focus) and sends the choice; this module only draws and reports clicks.

local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.Theme)
local Motion = require(script.Parent.Parent.Core.Motion)
local Ornament = require(script.Parent.Parent.Kit.Ornament)
local Text = require(script.Parent.Parent.Kit.Text)
local KeyHints = require(script.Parent.Parent.Kit.KeyHints)

export type Box = { Min: Vector3, Max: Vector3 }
export type Region = { Id: string, Name: string, Boxes: { Box } }
export type Standing = { Name: string, Score: number, You: boolean }
export type View = {
	Heading: string,
	Subheading: string,
	Timer: string,
	Fallback: string,
	Chosen: string?,
	Standings: { Standing },
	Cut: number?, -- how many pass; a line is drawn after that rank
}
export type RegionMap = {
	Frame: Frame,
	Build: (self: RegionMap, regions: { Region }, relief: Model?) -> (),
	Update: (self: RegionMap, view: View) -> (),
	Chose: (self: RegionMap, handler: (regionId: string) -> ()) -> (),
}

local M = Theme.Menu
local LEFT_WIDTH = 440
local MAP_MARGIN = 72
local CAMERA_FOV = 20
local OVERLAY_Y = 150 -- region shapes float above the tallest roofs
local MAX_STANDINGS = 8
-- Regions tile the district, so they read by their outlines; the fill only marks hover and the choice.
local TINT = {
	Idle = { Fill = Theme.Palette.Velvet, FillAlpha = 0.92, Line = Theme.Colors.Hairline, LineAlpha = 0.45 },
	Hover = { Fill = Theme.Colors.Text, FillAlpha = 0.75, Line = Theme.Colors.Text, LineAlpha = 0 },
	Chosen = { Fill = Theme.Colors.Focus, FillAlpha = 0.6, Line = Theme.Colors.Focus, LineAlpha = 0 },
}
local OUTLINE = 1.2 -- studs

local RegionMap = {}
RegionMap.__index = RegionMap

function RegionMap.new(parent: Instance): RegionMap
	local frame = Instance.new("Frame")
	frame.Name = "RegionMap"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Theme.Palette.Ink
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = parent

	-- left column: heading, deadline, fallback, standings
	local left = Instance.new("Frame")
	left.Name = "Left"
	left.Position = UDim2.fromOffset(M.Margin, M.Top + 20)
	left.Size = UDim2.new(0, LEFT_WIDTH, 1, -(M.Top + 120))
	left.BackgroundTransparency = 1
	left.Parent = frame
	local heading = Text.new(left, "Display", {
		Name = "Heading",
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 52),
		TextSize = 44,
	})
	local subheading = Text.new(left, "Body", {
		Name = "Subheading",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(0, 56),
		Size = UDim2.new(1, 0, 0, 24),
		TextColor3 = Theme.Colors.Hairline,
	})
	local timer = Text.new(left, "Display", {
		Name = "Timer",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(0, 92),
		Size = UDim2.new(1, 0, 0, 56),
		TextSize = 52,
		FontFace = Theme.Fonts.Numeric,
	})
	local fallback = Text.new(left, "Body", {
		Name = "Fallback",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Position = UDim2.fromOffset(0, 154),
		Size = UDim2.new(1, 0, 0, 48),
		TextColor3 = Theme.Colors.TextMuted,
	})
	Ornament.Rule(left, UDim.new(0, 216), 1)
	local standingsTitle = Text.new(left, "Caption", {
		Name = "StandingsTitle",
		Text = "STANDINGS",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(0, 230),
		Size = UDim2.new(1, 0, 0, 18),
		TextColor3 = Theme.Colors.Hairline,
	})
	local rows = {}
	for i = 1, MAX_STANDINGS do
		local y = 256 + (i - 1) * 32
		local rank = Text.new(left, "Numeric", {
			Name = `Rank{i}`,
			Text = tostring(i),
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(0, y),
			Size = UDim2.fromOffset(34, 28),
			TextColor3 = Theme.Colors.TextMuted,
		})
		local name = Text.new(left, "Body", {
			Name = `Name{i}`,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.fromOffset(38, y),
			Size = UDim2.new(1, -120, 0, 28),
		})
		local score = Text.new(left, "Numeric", {
			Name = `Score{i}`,
			TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.new(1, -80, 0, y),
			Size = UDim2.fromOffset(80, 28),
		})
		rows[i] = { Rank = rank, Name = name, Score = score, Y = y }
	end
	local cut = Instance.new("Frame")
	cut.Name = "Cut"
	cut.Size = UDim2.new(1, 0, 0, 1)
	cut.BackgroundColor3 = Theme.Colors.Danger
	cut.BorderSizePixel = 0
	cut.Visible = false
	cut.Parent = left
	-- in the margin left of the column, so it never covers a name or a score
	local cutLabel = Text.new(cut, "Caption", {
		Name = "CutLabel",
		Text = "CUT",
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(0, -8, 0.5, 0),
		Size = UDim2.fromOffset(50, 18),
		TextColor3 = Theme.Colors.Danger,
	})

	-- the map: square, as tall as the screen allows, right of the column
	local holder = Instance.new("Frame")
	holder.Name = "MapHolder"
	holder.AnchorPoint = Vector2.new(1, 0.5)
	holder.Position = UDim2.new(1, -M.Margin, 0.5, 10)
	holder.Size = UDim2.new(1, -(M.Margin * 2 + LEFT_WIDTH + 40), 1, -(MAP_MARGIN * 2 + 40))
	holder.BackgroundTransparency = 1
	holder.Parent = frame
	local square = Instance.new("UIAspectRatioConstraint")
	square.AspectRatio = 1
	square.Parent = holder
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Relief"
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.BackgroundColor3 = Theme.Palette.InkSoft
	viewport.BackgroundTransparency = 0
	viewport.BorderSizePixel = 0
	viewport.Ambient = Color3.fromRGB(120, 104, 132)
	viewport.LightColor = Color3.fromRGB(255, 222, 190)
	viewport.LightDirection = Vector3.new(-0.45, -1, -0.3)
	viewport.Parent = holder
	Ornament.Frame(viewport)
	local labels = Instance.new("Frame")
	labels.Name = "Labels"
	labels.Size = UDim2.fromScale(1, 1)
	labels.BackgroundTransparency = 1
	labels.ZIndex = 5
	labels.Parent = holder

	-- the map's keys sit under the standings (bottom right belongs to the persistent "hold Backspace" hint)
	local hints = KeyHints.new(frame)
	hints.Frame.AnchorPoint = Vector2.new(0, 1)
	hints.Frame.Position = UDim2.new(0, M.Margin, 1, -40)
	hints.Frame.Size = UDim2.fromOffset(LEFT_WIDTH + 200, M.HintGlyph)
	hints.Frame:FindFirstChildOfClass("UIListLayout").HorizontalAlignment = Enum.HorizontalAlignment.Left
	hints:Set({ { "Click", "Choose a region" }, { "1 2 3 4", "By number" } })

	local self = setmetatable({
		Frame = frame,
		_heading = heading,
		_subheading = subheading,
		_timer = timer,
		_fallback = fallback,
		_standingsTitle = standingsTitle,
		_rows = rows,
		_cut = cut,
		_cutLabel = cutLabel,
		_holder = holder,
		_viewport = viewport,
		_labels = labels,
		_regions = {},
		_shapes = {},
		_plates = {},
		_hover = nil,
		_chosen = nil,
		_handlers = {},
		_center = Vector3.zero,
		_half = 1,
	}, RegionMap)

	local function regionAt(screen: Vector2): string?
		local origin, size = holder.AbsolutePosition, holder.AbsoluteSize
		if size.X <= 0 then
			return nil
		end
		local fx, fy = (screen.X - origin.X) / size.X, (screen.Y - origin.Y) / size.Y
		if fx < 0 or fx > 1 or fy < 0 or fy > 1 then
			return nil
		end
		local x = self._center.X + (fx - 0.5) * 2 * self._half
		local z = self._center.Z + (fy - 0.5) * 2 * self._half
		for _, region in self._regions do
			for _, box in region.Boxes do
				if x >= box.Min.X and x <= box.Max.X and z >= box.Min.Z and z <= box.Max.Z then
					return region.Id
				end
			end
		end
		return nil
	end
	UserInputService.InputChanged:Connect(function(input)
		if frame.Visible and input.UserInputType == Enum.UserInputType.MouseMovement then
			local id = regionAt(Vector2.new(input.Position.X, input.Position.Y))
			if id ~= self._hover then
				self._hover = id
				self:_paint()
			end
		end
	end)
	UserInputService.InputBegan:Connect(function(input)
		if not frame.Visible or UserInputService:GetFocusedTextBox() then
			return
		end
		local id: string? = nil
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			id = regionAt(Vector2.new(input.Position.X, input.Position.Y))
		else
			local number = ({ [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4 })[input.KeyCode]
			local region = number and self._regions[number]
			id = region and region.Id
		end
		if id then
			for _, handler in self._handlers do
				handler(id)
			end
		end
	end)
	return (self :: any) :: RegionMap
end

-- Builds the relief and region shapes once (regions in display order: their number keys follow it).
function RegionMap.Build(self: any, regions: { Region }, relief: Model?)
	self._regions = regions
	local viewport: ViewportFrame = self._viewport
	viewport:ClearAllChildren()
	self._labels:ClearAllChildren()
	self._shapes, self._plates = {}, {}
	local lo, hi = Vector3.new(math.huge, 0, math.huge), Vector3.new(-math.huge, 0, -math.huge)
	for _, region in regions do
		for _, box in region.Boxes do
			lo, hi = lo:Min(box.Min), hi:Max(box.Max)
		end
	end
	self._center = Vector3.new((lo.X + hi.X) / 2, 0, (lo.Z + hi.Z) / 2)
	self._half = math.max(hi.X - lo.X, hi.Z - lo.Z) / 2 * 1.04
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	if relief then
		relief:Clone().Parent = world
	end
	local camera = Instance.new("Camera")
	camera.FieldOfView = CAMERA_FOV
	local height = self._half / math.tan(math.rad(CAMERA_FOV / 2))
	camera.CFrame = CFrame.new(self._center + Vector3.new(0, height, 0)) * CFrame.Angles(-math.pi / 2, 0, 0)
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	local function flat(x1: number, x2: number, z1: number, z2: number, y: number): Part
		local part = Instance.new("Part")
		part.Anchored = true
		part.Size = Vector3.new(x2 - x1, 0.2, z2 - z1)
		part.CFrame = CFrame.new((x1 + x2) / 2, y, (z1 + z2) / 2)
		part.Material = Enum.Material.SmoothPlastic
		part.Parent = world
		return part
	end
	for index, region in regions do
		local fills, lines = {}, {}
		for _, box in region.Boxes do
			local x1, x2, z1, z2 = box.Min.X + 1.5, box.Max.X - 1.5, box.Min.Z + 1.5, box.Max.Z - 1.5
			table.insert(fills, flat(x1, x2, z1, z2, OVERLAY_Y))
			table.insert(lines, flat(x1, x2, z1, z1 + OUTLINE, OVERLAY_Y + 0.2))
			table.insert(lines, flat(x1, x2, z2 - OUTLINE, z2, OVERLAY_Y + 0.2))
			table.insert(lines, flat(x1, x1 + OUTLINE, z1, z2, OVERLAY_Y + 0.2))
			table.insert(lines, flat(x2 - OUTLINE, x2, z1, z2, OVERLAY_Y + 0.2))
		end
		self._shapes[region.Id] = { Fills = fills, Lines = lines }
		-- the name plate at the region's largest box
		local biggest = region.Boxes[1]
		for _, box in region.Boxes do
			if (box.Max.X - box.Min.X) * (box.Max.Z - box.Min.Z) > (biggest.Max.X - biggest.Min.X) * (biggest.Max.Z - biggest.Min.Z) then
				biggest = box
			end
		end
		local cx, cz = (biggest.Min.X + biggest.Max.X) / 2, (biggest.Min.Z + biggest.Max.Z) / 2
		local plate = Instance.new("Frame")
		plate.Name = region.Id
		plate.AnchorPoint = Vector2.new(0.5, 0.5)
		plate.Position = UDim2.fromScale(0.5 + (cx - self._center.X) / (2 * self._half), 0.5 + (cz - self._center.Z) / (2 * self._half))
		plate.Size = UDim2.fromOffset(240, 64)
		plate.BackgroundTransparency = 1
		plate.ZIndex = 5
		plate.Parent = self._labels
		local key = KeyHints.Glyph(plate, tostring(index))
		key.AnchorPoint = Vector2.new(0.5, 0)
		key.Position = UDim2.new(0.5, 0, 0, -6)
		key.ZIndex = 6
		local name = Text.new(plate, "Label", {
			Name = "Name",
			Text = region.Name,
			Position = UDim2.fromOffset(0, 30),
			Size = UDim2.new(1, 0, 0, 24),
			TextSize = 22,
			ZIndex = 6,
		})
		local state = Text.new(plate, "Caption", {
			Name = "State",
			Text = "",
			Position = UDim2.fromOffset(0, 54),
			Size = UDim2.new(1, 0, 0, 16),
			TextColor3 = Theme.Colors.Focus,
			ZIndex = 6,
		})
		self._plates[region.Id] = { Name = name, State = state }
	end
	self:_paint()
end

function RegionMap._paint(self: any)
	for id, shape in self._shapes do
		local look = if id == self._chosen then TINT.Chosen elseif id == self._hover then TINT.Hover else TINT.Idle
		for _, fill in shape.Fills do
			Motion.To(fill, { Color = look.Fill, Transparency = look.FillAlpha }, "Fast")
		end
		for _, line in shape.Lines do
			Motion.To(line, { Color = look.Line, Transparency = look.LineAlpha }, "Fast")
		end
		local plate = self._plates[id]
		plate.State.Text = if id == self._chosen then "◆ CHOSEN" else "" -- the name stays bone: gold on gold won't read
	end
end

function RegionMap.Update(self: any, view: View)
	self._heading.Text = view.Heading
	self._subheading.Text = view.Subheading
	self._timer.Text = view.Timer
	self._fallback.Text = view.Fallback
	if view.Chosen ~= self._chosen then
		self._chosen = view.Chosen
		self:_paint()
	end
	for i, row in self._rows do
		local entry = view.Standings[i]
		row.Rank.Visible, row.Name.Visible, row.Score.Visible = entry ~= nil, entry ~= nil, entry ~= nil
		if entry then
			row.Name.Text = entry.Name
			row.Score.Text = tostring(entry.Score)
			row.Name.TextColor3 = if entry.You then Theme.Colors.Focus else Theme.Colors.Text
		end
	end
	local cutAt = view.Cut
	self._cut.Visible = cutAt ~= nil and cutAt < #view.Standings and cutAt <= #self._rows
	if self._cut.Visible then
		self._cut.Position = UDim2.fromOffset(0, self._rows[cutAt :: number].Y + 30)
	end
end

-- Calls `handler(regionId)` when a region is clicked or its number pressed.
function RegionMap.Chose(self: any, handler: (string) -> ())
	table.insert(self._handlers, handler)
end

return RegionMap

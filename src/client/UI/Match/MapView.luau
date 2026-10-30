--!strict
-- MapView (intermission, centre): the district from above. A live copy of the world (MatchState.Relief) in a
-- ViewportFrame, recoloured by height like an engraved survey (Theme.Map.Bands), its edges fading into the backdrop;
-- each region a fine gold ring around its volumes with its number key and name; marks for what's inside
-- (Theme.Map.Marks: pact circles, ritual sites, enemy packs, heavies); a gold star where you are, or where you fell.
-- Hover lights a region (a warm glow, a brighter ring); the chosen one keeps it in gold, with "Chosen" under its name
-- and one pulse. A click or a number key reports the region (only while choosing). The map is framed to hold every
-- ring, so none runs off it into the text around.

local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.Theme)
local Motion = require(script.Parent.Parent.Core.Motion)
local Ornament = require(script.Parent.Parent.Kit.Ornament)
local Text = require(script.Parent.Parent.Kit.Text)
local KeyHints = require(script.Parent.Parent.Kit.KeyHints)
local Veil = require(script.Parent.Parent.Kit.Veil)

export type Box = { Min: Vector3, Max: Vector3 }
export type Feature = { Kind: string, Position: Vector3, Label: string, Count: number }
export type Region = { Id: string, Name: string, Boxes: { Box }, Features: { Feature } }
export type MapView = {
	Frame: Frame,
	Build: (self: MapView, regions: { Region }, relief: Model?) -> (),
	SetChosen: (self: MapView, id: string?) -> (),
	SetYou: (self: MapView, position: Vector3?) -> (),
	SetInteractive: (self: MapView, choosing: boolean) -> (),
	Hovered: (self: MapView) -> string?,
	Chose: (self: MapView, handler: (string) -> ()) -> (),
}

local MAP = Theme.Map
local CAMERA_FOV = 20
local LIFT = 400 -- the relief camera's height above the tallest roofs isn't critical with a narrow FOV
local RING_FIT = 0.92 -- a region's ring: this × half the wider side of its volumes
local MARGIN = 1.04 -- the map's room around its outermost ring
local MARK_SIZE = { Pact = 12, Ritual = 15, Fodder = 8, Heavy = 12, You = 30 }
local EDGE = MAP.EdgeFade
local EDGES = { -- the relief's fading sides: the gradient's opaque end faces the edge (fractions of the relief)
	{ Rotation = 0, At = Vector2.zero, Size = Vector2.new(EDGE, 1) },
	{ Rotation = 180, At = Vector2.new(1 - EDGE, 0), Size = Vector2.new(EDGE, 1) },
	{ Rotation = 90, At = Vector2.zero, Size = Vector2.new(1, EDGE) },
	{ Rotation = 270, At = Vector2.new(0, 1 - EDGE), Size = Vector2.new(1, EDGE) },
}
local EDGE_FADE = { NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.65), NumberSequenceKeypoint.new(1, 1) }
local NUMBER_KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six }
local STRIP = { SurfaceAppearance = true, Texture = true, Decal = true }

local MapView = {}
MapView.__index = MapView

function MapView.new(parent: Instance, position: UDim2, size: UDim2): MapView
	local holder = Instance.new("Frame")
	holder.Name = "Map"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = position
	holder.Size = size
	holder.BackgroundTransparency = 1
	holder.Parent = parent
	local square = Instance.new("UIAspectRatioConstraint")
	square.AspectRatio = 1
	square.Parent = holder
	local viewport = Instance.new("ViewportFrame") -- no background: the relief floats on the screen's own dark
	viewport.Name = "Relief"
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.BackgroundTransparency = 1
	viewport.BorderSizePixel = 0
	viewport.Ambient = MAP.Ambient
	viewport.LightColor = MAP.Light
	viewport.LightDirection = Vector3.new(-0.45, -1, -0.3)
	viewport.Parent = holder
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundTransparency = 1
	overlay.ZIndex = 5
	overlay.Parent = holder

	local self = setmetatable({
		Frame = holder,
		_viewport = viewport,
		_overlay = overlay,
		_regions = {},
		_circles = {},
		_plates = {},
		_you = nil,
		_hover = nil,
		_chosen = nil,
		_choosing = false,
		_handlers = {},
		_center = Vector3.zero,
		_half = 1,
	}, MapView)

	-- the region under a screen point: the nearest ring that contains it
	local function regionAt(screen: Vector2): string?
		local origin, extent = holder.AbsolutePosition, holder.AbsoluteSize
		if extent.X <= 0 then
			return nil
		end
		local fx, fy = (screen.X - origin.X) / extent.X, (screen.Y - origin.Y) / extent.Y
		local best, bestDistance = nil, math.huge
		for id, circle in self._circles do
			local d = math.sqrt((fx - circle.X) ^ 2 + (fy - circle.Y) ^ 2)
			if d <= circle.R and d < bestDistance then
				best, bestDistance = id, d
			end
		end
		return best
	end
	UserInputService.InputChanged:Connect(function(input)
		if holder.Visible and input.UserInputType == Enum.UserInputType.MouseMovement then
			local id = regionAt(Vector2.new(input.Position.X, input.Position.Y))
			if id ~= self._hover then
				self._hover = id
				self:_paint()
			end
		end
	end)
	UserInputService.InputBegan:Connect(function(input)
		if not holder.Visible or not self._choosing or UserInputService:GetFocusedTextBox() then
			return
		end
		local id: string? = nil
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			id = regionAt(Vector2.new(input.Position.X, input.Position.Y))
		else
			local number = table.find(NUMBER_KEYS, input.KeyCode)
			local region = number and self._regions[number]
			id = region and region.Id
		end
		if id then
			for _, handler in self._handlers do
				handler(id)
			end
		end
	end)
	return (self :: any) :: MapView
end

-- Where a world point lands on the map (0..1 across and down).
function MapView._at(self: any, position: Vector3): Vector2
	return Vector2.new(0.5 + (position.X - self._center.X) / (2 * self._half), 0.5 + (position.Z - self._center.Z) / (2 * self._half))
end

local function mark(parent: Instance, kind: string, at: Vector2): GuiObject
	local size = MARK_SIZE[kind] or 10
	local color = (MAP.Marks :: any)[kind] or Theme.Colors.Text
	if kind == "Fodder" then
		local dot = Instance.new("Frame")
		dot.Name = kind
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.fromScale(at.X, at.Y)
		dot.Size = UDim2.fromOffset(size, size)
		dot.BackgroundColor3 = color
		dot.BorderSizePixel = 0
		dot.ZIndex = 6
		dot.Parent = parent
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(0.5, 0)
		round.Parent = dot
		return dot
	end
	local diamond = Ornament.Diamond(parent, size, UDim2.fromScale(at.X, at.Y), color)
	diamond.Name = kind
	diamond.ZIndex = 6
	local edge = Instance.new("UIStroke")
	edge.Color = Theme.Colors.Background
	edge.Transparency = 0.2
	edge.Parent = diamond
	return diamond
end

-- A ring of constant width: a stroke, not an image, so a big region doesn't get a heavy one.
local function ring(parent: Instance, name: string, at: Vector2, radius: number): (Frame, UIStroke)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(at.X, at.Y)
	frame.Size = UDim2.fromScale(radius * 2, radius * 2)
	frame.BackgroundTransparency = 1
	frame.ZIndex = 5
	frame.Parent = parent
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = MAP.Region
	stroke.Thickness = MAP.Ring.Thickness
	stroke.Transparency = MAP.Ring.Idle
	stroke.Parent = frame
	return frame, stroke
end

-- How far a part reaches from its centre along each world axis (its rotation included).
local function reach(part: BasePart): Vector3
	local m, h = part.CFrame, part.Size / 2
	local x, y, z = m.XVector, m.YVector, m.ZVector
	return Vector3.new(
		math.abs(x.X) * h.X + math.abs(y.X) * h.Y + math.abs(z.X) * h.Z,
		math.abs(x.Y) * h.X + math.abs(y.Y) * h.Y + math.abs(z.Y) * h.Z,
		math.abs(x.Z) * h.X + math.abs(y.Z) * h.Y + math.abs(z.Z) * h.Z
	)
end

-- The relief's outline fades into the backdrop: an ink gradient along each side (min, max: map fractions, top left
-- and bottom right), over the relief and under the rings.
local function fadeEdges(parent: Instance, min: Vector2, max: Vector2)
	local edges = Instance.new("Frame")
	edges.Name = "Edges"
	edges.BackgroundTransparency = 1
	edges.Position = UDim2.fromScale(min.X, min.Y)
	edges.Size = UDim2.fromScale(max.X - min.X, max.Y - min.Y)
	edges.ZIndex = 3
	edges.Parent = parent
	for _, side in EDGES do
		local veil = Veil.Side(edges, side.Rotation, EDGE_FADE)
		veil.Position = UDim2.fromScale(side.At.X, side.At.Y)
		veil.Size = UDim2.fromScale(side.Size.X, side.Size.Y)
	end
end

function MapView.Build(self: any, regions: { Region }, relief: Model?)
	self._regions = regions
	local viewport: ViewportFrame = self._viewport
	viewport:ClearAllChildren()
	self._overlay:ClearAllChildren()
	self._circles, self._plates = {}, {}
	local oldEdges = self.Frame:FindFirstChild("Edges")
	if oldEdges then
		oldEdges:Destroy()
	end
	-- each region's ring in world units (centred on its volumes), and a frame that holds every ring and volume
	local shapes: { [number]: { Center: Vector3, Radius: number } } = {}
	local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for index, region in regions do
		if #region.Boxes == 0 then
			continue
		end
		local rlo, rhi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
		for _, box in region.Boxes do
			rlo, rhi = rlo:Min(box.Min), rhi:Max(box.Max)
		end
		local center = (rlo + rhi) / 2
		local radius = math.max(rhi.X - rlo.X, rhi.Z - rlo.Z) / 2 * RING_FIT
		shapes[index] = { Center = center, Radius = radius }
		local span = Vector3.new(radius, 0, radius)
		lo, hi = lo:Min(rlo):Min(center - span), hi:Max(rhi):Max(center + span)
	end
	if lo.X == math.huge then
		return
	end
	self._center = Vector3.new((lo.X + hi.X) / 2, 0, (lo.Z + hi.Z) / 2)
	self._half = math.max(hi.X - lo.X, hi.Z - lo.Z) / 2 * MARGIN

	-- the relief, recoloured by height, its outline fading into the backdrop
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	if relief then
		local copy = relief:Clone()
		local bottom, top = math.huge, -math.huge
		local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
		local parts: { { Part: BasePart, Top: number } } = {}
		for _, part in copy:GetDescendants() do
			if STRIP[part.ClassName] then
				part:Destroy()
			elseif part:IsA("BasePart") then
				local extent = reach(part)
				local y = part.Position.Y + extent.Y
				bottom, top = math.min(bottom, y), math.max(top, y)
				minX, maxX = math.min(minX, part.Position.X - extent.X), math.max(maxX, part.Position.X + extent.X)
				minZ, maxZ = math.min(minZ, part.Position.Z - extent.Z), math.max(maxZ, part.Position.Z + extent.Z)
				table.insert(parts, { Part = part, Top = y })
			end
		end
		for _, entry in parts do
			local part = entry.Part
			local t = (entry.Top - bottom) / math.max(1, top - bottom)
			part.Color = MAP.Bands[math.clamp(math.floor(t * #MAP.Bands) + 1, 1, #MAP.Bands)]
			part.Material = Enum.Material.SmoothPlastic
			part.Reflectance = 0
			if part:IsA("MeshPart") then
				part.TextureID = ""
			end
		end
		copy.Parent = world
		if #parts > 0 then
			local a, b = self:_at(Vector3.new(minX, 0, minZ)), self:_at(Vector3.new(maxX, 0, maxZ))
			fadeEdges(self.Frame, Vector2.new(math.clamp(a.X, 0, 1), math.clamp(a.Y, 0, 1)), Vector2.new(math.clamp(b.X, 0, 1), math.clamp(b.Y, 0, 1)))
		end
	end
	-- straight down from high enough to clear the roofs, with the field of view that frames the map exactly
	local camera = Instance.new("Camera")
	local height = math.max(self._half / math.tan(math.rad(CAMERA_FOV / 2)), hi.Y + LIFT)
	camera.FieldOfView = math.deg(2 * math.atan(self._half / height))
	camera.CFrame = CFrame.new(self._center + Vector3.new(0, height, 0)) * CFrame.Angles(-math.pi / 2, 0, 0)
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	-- the regions: a fine gold ring each, its marks, its plate
	for index, region in regions do
		local shape = shapes[index]
		if not shape then
			continue
		end
		local center = self:_at(shape.Center)
		local radius = shape.Radius / (2 * self._half)
		local fill = Instance.new("ImageLabel")
		fill.Name = region.Id .. "Fill"
		fill.BackgroundTransparency = 1
		fill.Image = Theme.Images.SoftGlow
		fill.ImageColor3 = MAP.Region
		fill.ImageTransparency = 1
		fill.AnchorPoint = Vector2.new(0.5, 0.5)
		fill.Position = UDim2.fromScale(center.X, center.Y)
		fill.Size = UDim2.fromScale(radius * 2.3, radius * 2.3)
		fill.ZIndex = 5
		fill.Parent = self._overlay
		local _, stroke = ring(self._overlay, region.Id .. "Ring", center, radius)
		self._circles[region.Id] = { X = center.X, Y = center.Y, R = radius, Fill = fill, Stroke = stroke }
		for _, feature in region.Features do
			mark(self._overlay, feature.Kind, self:_at(feature.Position))
		end
		local plate = Instance.new("Frame")
		plate.Name = region.Id .. "Plate"
		plate.AnchorPoint = Vector2.new(0.5, 0.5)
		plate.Position = UDim2.fromScale(center.X, center.Y)
		plate.Size = UDim2.fromOffset(240, 70)
		plate.BackgroundTransparency = 1
		plate.ZIndex = 7
		plate.Parent = self._overlay
		local key = KeyHints.Glyph(plate, tostring(index))
		key.AnchorPoint = Vector2.new(0.5, 0)
		key.Position = UDim2.new(0.5, 0, 0, -4)
		key.ZIndex = 8
		local name = Text.new(plate, "Label", {
			Name = "Name",
			Text = region.Name,
			Position = UDim2.fromOffset(0, 32),
			Size = UDim2.new(1, 0, 0, 24),
			TextSize = 22,
			ZIndex = 8,
		})
		local state = Text.new(plate, "Caption", {
			Name = "State",
			Text = "",
			Position = UDim2.fromOffset(0, 56),
			Size = UDim2.new(1, 0, 0, 16),
			TextColor3 = Theme.Colors.Focus,
			ZIndex = 8,
		})
		self._plates[region.Id] = { Name = name, State = state }
	end
	-- you
	local you = Instance.new("ImageLabel")
	you.Name = "You"
	you.BackgroundTransparency = 1
	you.Image = Theme.Images.Glint
	you.ImageColor3 = MAP.Marks.You
	you.AnchorPoint = Vector2.new(0.5, 0.5)
	you.Size = UDim2.fromOffset(MARK_SIZE.You, MARK_SIZE.You)
	you.Visible = false
	you.ZIndex = 9
	you.Parent = self._overlay
	Text.new(you, "Caption", {
		Name = "Label",
		Text = "YOU",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, -4),
		Size = UDim2.fromOffset(60, 16),
		TextColor3 = MAP.Marks.You,
		ZIndex = 9,
	})
	self._you = you
	self:_paint()
end

function MapView._paint(self: any)
	for id, circle in self._circles do
		local chosen, hover = id == self._chosen, id == self._hover
		Motion.To(circle.Fill, { ImageTransparency = if chosen then MAP.Fill.Chosen elseif hover then MAP.Fill.Hover else 1 }, "Fast")
		Motion.To(circle.Stroke, {
			Transparency = if chosen or hover then MAP.Ring.Lit else MAP.Ring.Idle,
			Thickness = if chosen then MAP.Ring.Chosen else MAP.Ring.Thickness,
			Color = if chosen then Theme.Colors.Focus elseif hover then Theme.Colors.Text else MAP.Region,
		}, "Fast")
		local plate = self._plates[id]
		if plate then
			plate.State.Text = if chosen then "◆ CHOSEN" else ""
		end
	end
end

-- One gold ring swells out of the region just chosen and fades.
function MapView._pulse(self: any, circle: any)
	local frame, stroke = ring(self._overlay, "Pulse", Vector2.new(circle.X, circle.Y), circle.R)
	stroke.Color, stroke.Thickness, stroke.Transparency = Theme.Colors.Focus, MAP.Ring.Chosen, MAP.Ring.Lit
	Motion.To(frame, { Size = UDim2.fromScale(circle.R * 2 * MAP.Pulse, circle.R * 2 * MAP.Pulse) }, "Slow")
	Motion.To(stroke, { Transparency = 1 }, "Slow")
	task.delay(Theme.Motion.Slow, frame.Destroy, frame)
end

function MapView.SetChosen(self: any, id: string?)
	if id ~= self._chosen then
		self._chosen = id
		self:_paint()
		local circle = id and self._circles[id]
		if circle then
			self:_pulse(circle)
		end
	end
end

function MapView.SetYou(self: any, position: Vector3?)
	local you = self._you
	if not you then
		return
	end
	you.Visible = position ~= nil
	if position then
		local at = self:_at(position)
		you.Position = UDim2.fromScale(math.clamp(at.X, 0, 1), math.clamp(at.Y, 0, 1))
	end
end

function MapView.SetInteractive(self: any, choosing: boolean)
	self._choosing = choosing
end

function MapView.Hovered(self: any): string?
	return self._hover
end

function MapView.Chose(self: any, handler: (string) -> ())
	table.insert(self._handlers, handler)
end

return MapView

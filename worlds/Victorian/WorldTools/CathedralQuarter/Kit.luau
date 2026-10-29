--!strict
-- Kit: the blockout's building blocks, so the Layout reads as architecture (boxes, walls with openings, flights,
-- roofs, markers, lamps) instead of part properties. Everything is axis-aligned and given by min/max studs.
--   Roles pick the neutral blockout value (Palette): walkable surfaces read differently from walls and roofs.
--   Flights: an invisible wedge carries the collision (no lips, no steps to catch on) under visible 0.5-stud steps.
--   Subtract: 2D rectangle subtraction, for the street slab's stair wells and for door/window openings in walls.
-- Edit-time tool for the Victorian place (ServerStorage.WorldTools.CathedralQuarter); never shipped to clients.

local CollectionService = game:GetService("CollectionService")

local Kit = {}

-- Neutral blockout values (dusk-tuned greys). Walkable = a touch warmer so routes read; landmark = lighter.
Kit.Palette = {
	Ground = { Color3.fromRGB(96, 92, 98), Enum.Material.SmoothPlastic }, -- light enough to read the floor at dusk
	Walk = { Color3.fromRGB(112, 106, 100), Enum.Material.SmoothPlastic },
	Stair = { Color3.fromRGB(126, 116, 104), Enum.Material.SmoothPlastic },
	Wall = { Color3.fromRGB(104, 102, 112), Enum.Material.SmoothPlastic },
	Building = { Color3.fromRGB(92, 90, 100), Enum.Material.SmoothPlastic },
	Roof = { Color3.fromRGB(46, 46, 56), Enum.Material.SmoothPlastic },
	Landmark = { Color3.fromRGB(136, 134, 144), Enum.Material.SmoothPlastic },
	Crypt = { Color3.fromRGB(62, 60, 66), Enum.Material.SmoothPlastic },
	Rail = { Color3.fromRGB(58, 56, 62), Enum.Material.SmoothPlastic },
	Iron = { Color3.fromRGB(28, 26, 30), Enum.Material.SmoothPlastic },
	Boundary = { Color3.fromRGB(40, 38, 46), Enum.Material.SmoothPlastic },
	Window = { Color3.fromRGB(255, 170, 96), Enum.Material.Neon },
	Lamp = { Color3.fromRGB(255, 196, 128), Enum.Material.Neon },
}

export type Rect = { number } -- { a1, a2, b1, b2 } with a1 < a2, b1 < b2

-- `rect` minus every hole, as non-overlapping rectangles (guillotine cuts).
function Kit.Subtract(rect: Rect, holes: { Rect }): { Rect }
	local pieces: { Rect } = { rect }
	for _, h in holes do
		local nextPieces: { Rect } = {}
		for _, r in pieces do
			local a1, a2, b1, b2 = r[1], r[2], r[3], r[4]
			if h[2] <= a1 or h[1] >= a2 or h[4] <= b1 or h[3] >= b2 then
				table.insert(nextPieces, r)
				continue
			end
			if h[1] > a1 then
				table.insert(nextPieces, { a1, h[1], b1, b2 })
			end
			if h[2] < a2 then
				table.insert(nextPieces, { h[2], a2, b1, b2 })
			end
			local m1, m2 = math.max(a1, h[1]), math.min(a2, h[2])
			if h[3] > b1 then
				table.insert(nextPieces, { m1, m2, b1, h[3] })
			end
			if h[4] < b2 then
				table.insert(nextPieces, { m1, m2, h[4], b2 })
			end
		end
		pieces = nextPieces
	end
	return pieces
end

export type Builder = typeof(setmetatable({} :: { Parent: Instance, Count: { number } }, {} :: any))

local Builder = {}
Builder.__index = Builder

function Kit.Builder(parent: Instance, count: { number }?): any
	return setmetatable({ Parent = parent, Count = count or { 0 } }, Builder)
end

-- A child builder that puts its parts in a named folder.
function Builder:Group(name: string): any
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = self.Parent
	return Kit.Builder(folder, self.Count)
end

local function style(part: BasePart, role: string)
	local look = Kit.Palette[role] or Kit.Palette.Wall
	part.Color, part.Material = look[1], look[2]
	part.Anchored = true
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
end

-- A box from min/max corners.
function Builder:Box(name: string, x1: number, x2: number, y1: number, y2: number, z1: number, z2: number, role: string): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(x2 - x1, y2 - y1, z2 - z1)
	part.CFrame = CFrame.new((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2)
	style(part, role)
	part.Parent = self.Parent
	self.Count[1] += 1
	return part
end

-- A floor slab (top at `top`, `thickness` deep) over a rectangle with rectangular holes cut out.
function Builder:Slab(name: string, x1: number, x2: number, z1: number, z2: number, top: number, thickness: number, role: string, holes: { Rect }?)
	for i, r in Kit.Subtract({ x1, x2, z1, z2 }, holes or {}) do
		self:Box(`{name}{i}`, r[1], r[2], top - thickness, top, r[3], r[4], role)
	end
end

-- A wall along X (fixed z1..z2) or along Z (fixed x1..x2), from y1 to y2, with openings { a1, a2, yBottom, yTop }
-- measured along the wall's length.
function Builder:Wall(name: string, axis: "X" | "Z", t1: number, t2: number, a1: number, a2: number, y1: number, y2: number, role: string, openings: { Rect }?)
	for i, r in Kit.Subtract({ a1, a2, y1, y2 }, openings or {}) do
		if axis == "X" then
			self:Box(`{name}{i}`, r[1], r[2], r[3], r[4], t1, t2, role)
		else
			self:Box(`{name}{i}`, t1, t2, r[3], r[4], r[1], r[2], role)
		end
	end
end

-- Four walls around a rectangle (outer faces at x1..x2, z1..z2), `thick` deep, with openings per side.
function Builder:Room(name: string, x1: number, x2: number, z1: number, z2: number, y1: number, y2: number, thick: number, role: string, openings: { N: { Rect }?, S: { Rect }?, W: { Rect }?, E: { Rect }? }?)
	local o = openings or {}
	self:Wall(`{name}N`, "X", z1, z1 + thick, x1, x2, y1, y2, role, o.N)
	self:Wall(`{name}S`, "X", z2 - thick, z2, x1, x2, y1, y2, role, o.S)
	self:Wall(`{name}W`, "Z", x1, x1 + thick, z1 + thick, z2 - thick, y1, y2, role, o.W)
	self:Wall(`{name}E`, "Z", x2 - thick, x2, z1 + thick, z2 - thick, y1, y2, role, o.E)
end

local DIRECTIONS = {
	N = Vector3.new(0, 0, -1),
	S = Vector3.new(0, 0, 1),
	E = Vector3.new(1, 0, 0),
	W = Vector3.new(-1, 0, 0),
}

-- A flight of stairs filling the rectangle, climbing toward `dir` from y1 to y2, with visible 0.5-stud steps.
--   Default: solid down to y1 (an invisible wedge carries the collision; nothing walks underneath).
--   hung = true: single treads over a sloped plank, so the underside follows the slope (for flights that pass over
--   another walkable surface: the clearance stays the same along the whole run).
function Builder:Flight(name: string, x1: number, x2: number, z1: number, z2: number, y1: number, y2: number, dir: "N" | "S" | "E" | "W", hung: boolean?)
	local d = DIRECTIONS[dir]
	local alongX = dir == "E" or dir == "W"
	local run = if alongX then x2 - x1 else z2 - z1
	local width = if alongX then z2 - z1 else x2 - x1
	local rise = y2 - y1
	local center = Vector3.new((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2)
	if hung then
		local slope = (d * run + Vector3.new(0, rise, 0)).Unit
		local normal = slope:Cross(d:Cross(Vector3.yAxis)).Unit
		if normal.Y < 0 then
			normal = -normal
		end
		local plank = Instance.new("Part")
		plank.Name = `{name}Plank`
		plank.Size = Vector3.new(width, 1, math.sqrt(run * run + rise * rise))
		local middle = center - normal * 0.5
		plank.CFrame = CFrame.lookAt(middle, middle + slope)
		style(plank, "Stair")
		plank.Parent = self.Parent
		self.Count[1] += 1
	else
		local wedge = Instance.new("WedgePart")
		wedge.Name = `{name}Ramp`
		wedge.Size = Vector3.new(width, rise, run)
		wedge.CFrame = CFrame.lookAt(center, center - d) -- a wedge rises toward its local +Z
		wedge.Transparency = 1
		style(wedge, "Stair")
		wedge.Parent = self.Parent
		self.Count[1] += 1
	end
	local steps = math.max(1, math.floor(rise / 0.5 + 0.5))
	local tread = run / steps
	for i = 1, steps do
		local h = y1 + rise * i / steps
		-- the step's footprint: from tread (i - 1) to the far end, stacked under one another as a solid staircase
		-- (hung: only its own tread)
		local from = (i - 1) * tread
		local to = if hung then i * tread else run
		local a1, a2
		if dir == "N" then
			a1, a2 = z2 - to, z2 - from
		elseif dir == "S" then
			a1, a2 = z1 + from, z1 + to
		elseif dir == "E" then
			a1, a2 = x1 + from, x1 + to
		else
			a1, a2 = x2 - to, x2 - from
		end
		local step
		if alongX then
			step = self:Box(`{name}Step{i}`, a1, a2, h - rise / steps, h, z1, z2, "Stair")
		else
			step = self:Box(`{name}Step{i}`, x1, x2, h - rise / steps, h, a1, a2, "Stair")
		end
		step.CanCollide = false
	end
end

-- A gable roof over a rectangle: eave at `eave`, ridge `height` above it, ridge running along `axis`.
function Builder:Gable(name: string, x1: number, x2: number, z1: number, z2: number, eave: number, height: number, axis: "X" | "Z", role: string?)
	local look = role or "Roof"
	if axis == "Z" then
		local half = (x2 - x1) / 2
		local cz = (z1 + z2) / 2
		for side, sign in { W = -1, E = 1 } do
			local wedge = Instance.new("WedgePart")
			wedge.Name = `{name}{side}`
			wedge.Size = Vector3.new(z2 - z1, height, half)
			local cx = (x1 + x2) / 2 + sign * half / 2
			-- rises toward the ridge (the middle): local +Z points at the centre line
			wedge.CFrame = CFrame.lookAt(Vector3.new(cx, eave + height / 2, cz), Vector3.new(cx, eave + height / 2, cz) + Vector3.new(sign, 0, 0))
			style(wedge, look)
			wedge.Parent = self.Parent
			self.Count[1] += 1
		end
	else
		local half = (z2 - z1) / 2
		local cx = (x1 + x2) / 2
		for side, sign in { N = -1, S = 1 } do
			local wedge = Instance.new("WedgePart")
			wedge.Name = `{name}{side}`
			wedge.Size = Vector3.new(x2 - x1, height, half)
			local cz = (z1 + z2) / 2 + sign * half / 2
			wedge.CFrame = CFrame.lookAt(Vector3.new(cx, eave + height / 2, cz), Vector3.new(cx, eave + height / 2, cz) + Vector3.new(0, 0, sign))
			style(wedge, look)
			wedge.Parent = self.Parent
			self.Count[1] += 1
		end
	end
end

-- A building block: solid body up to `eave` with a gable along its long side (or flat when ridge is 0).
function Builder:Block(name: string, x1: number, x2: number, z1: number, z2: number, eave: number, ridge: number, role: string?)
	self:Box(`{name}Body`, x1, x2, 0, eave, z1, z2, role or "Building")
	if ridge > 0 then
		self:Gable(`{name}Roof`, x1, x2, z1, z2, eave, ridge, if (x2 - x1) >= (z2 - z1) then "X" else "Z")
	end
end

-- A low parapet/railing along a line (blocks falling, not sight).
function Builder:Rail(name: string, x1: number, x2: number, z1: number, z2: number, base: number)
	local part = self:Box(name, x1, x2, base, base + 3.5, z1, z2, "Rail")
	return part
end

-- An invisible, anchored, non-colliding marker carrying a gameplay tag and attributes (Shared.World.Tags).
function Builder:Marker(name: string, tag: string?, attributes: { [string]: any }, x: number, y: number, z: number, size: Vector3?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size or Vector3.new(2, 1, 2)
	part.CFrame = CFrame.new(x, y + part.Size.Y / 2, z)
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
	part.Transparency = 1
	for key, value in attributes do
		part:SetAttribute(key, value)
	end
	if tag then
		CollectionService:AddTag(part, tag)
	end
	part.Parent = self.Parent
	self.Count[1] += 1
	return part
end

-- A volume marker from min/max corners (regions, arenas, ritual sites).
function Builder:Volume(name: string, tag: string, attributes: { [string]: any }, x1: number, x2: number, y1: number, y2: number, z1: number, z2: number): Part
	local part = self:Marker(name, tag, attributes, (x1 + x2) / 2, y1, (z1 + z2) / 2, Vector3.new(x2 - x1, y2 - y1, z2 - z1))
	return part
end

export type LampSpec = { Color: Color3, Brightness: number, Range: number, Shadows: boolean? }

-- A street lamp: post, lantern head (warm neon) and a point light.
function Builder:Lamp(name: string, x: number, y: number, z: number, spec: LampSpec)
	self:Box(`{name}Post`, x - 0.4, x + 0.4, y, y + 11, z - 0.4, z + 0.4, "Iron")
	local head = self:Box(`{name}Head`, x - 0.8, x + 0.8, y + 11, y + 12.6, z - 0.8, z + 0.8, "Lamp")
	head.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range, light.Shadows = spec.Color, spec.Brightness, spec.Range, spec.Shadows == true
	light.Parent = head
end

-- A light with no visible fixture yet (spill from an opening, a window glow, a candle cluster).
function Builder:Glow(name: string, x: number, y: number, z: number, kind: "Point" | "Spot", spec: LampSpec, face: Enum.NormalId?): Part
	local holder = self:Box(name, x - 0.5, x + 0.5, y - 0.5, y + 0.5, z - 0.5, z + 0.5, "Lamp")
	holder.Transparency, holder.CanCollide, holder.CanQuery, holder.CastShadow = 1, false, false, false
	local light: Light = if kind == "Spot" then Instance.new("SpotLight") else Instance.new("PointLight")
	light.Color, light.Brightness, light.Shadows = spec.Color, spec.Brightness, spec.Shadows == true
	;(light :: any).Range = spec.Range
	if kind == "Spot" then
		local spot = light :: SpotLight
		spot.Face = face or Enum.NormalId.Bottom
		spot.Angle = if spec.Range >= 50 then 100 else 70 -- long throws (clerestory) spread wider
	end
	light.Parent = holder
	return holder
end

-- A warm lit window pane on a wall face (occupation, not decoration: sparse).
function Builder:Window(name: string, x1: number, x2: number, y1: number, y2: number, z1: number, z2: number)
	local pane = self:Box(name, x1, x2, y1, y2, z1, z2, "Window")
	pane.CanCollide = false
	pane.CastShadow = false
end

return Kit

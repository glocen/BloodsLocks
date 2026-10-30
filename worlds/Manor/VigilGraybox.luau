--!strict
-- VigilGraybox: builds the castle hub "The Vigil" as a graybox (real layout and scale, blocking shapes, mood
-- lighting) from the layout numbers below. Edit-time tool: run Build() from the command bar or MCP; it replaces
-- workspace.Vigil. Design: docs/engineering-plan.md section 11a. North = -Z.

local VigilGraybox = {}

local ORIGIN = CFrame.new(0, 0, -1000)

local HALL_R = 40 -- inradius of the octagonal hall
local HALL_H = 45
local WALL_T = 2.5
local DOOR_W, DOOR_H = 14, 20
local GREAT_DOOR_W, GREAT_DOOR_H = 16, 26
local WING_LEN, WING_W, WING_H = 50, 24, 38
local YARD_X, YARD_FAR = 72, 172 -- yard half-width and far edge (studs north of the hall centre)
local YARD_WALL_H = 14

local C = {
	Stone = Color3.fromRGB(64, 58, 66),
	StoneDark = Color3.fromRGB(42, 37, 45),
	Floor = Color3.fromRGB(58, 48, 52),
	Cobble = Color3.fromRGB(70, 64, 66),
	Sand = Color3.fromRGB(120, 100, 82),
	Wood = Color3.fromRGB(60, 40, 32),
	Iron = Color3.fromRGB(30, 28, 32),
	Blood = Color3.fromRGB(150, 10, 30),
	Candle = Color3.fromRGB(255, 150, 70),
	Moon = Color3.fromRGB(120, 150, 255),
	Gold = Color3.fromRGB(255, 196, 90),
	Fire = Color3.fromRGB(255, 120, 40),
	Placeholder = Color3.fromRGB(150, 150, 160),
}

local root: Folder

local function folder(name: string, parent: Instance?): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent or root
	return f
end

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, material: Enum.Material, color: Color3, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = ORIGIN * cframe
	p.Material = material
	p.Color = color
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end

local function light(parent: Instance, kind: string, color: Color3, brightness: number, range: number, props: { [string]: any }?): Light
	local l = Instance.new(kind) :: any
	l.Color, l.Brightness, l.Range = color, brightness, range
	l.Shadows = false
	for k, v in props or {} do
		l[k] = v
	end
	l.Parent = parent
	return l
end

-- A wall segment centred at cframe (local X = along the wall), optionally with a doorway in the middle.
local function wall(parent: Instance, name: string, length: number, height: number, cframe: CFrame, door: Vector2?)
	if not door then
		part(parent, name, Vector3.new(length, height, WALL_T), cframe * CFrame.new(0, height / 2, 0), Enum.Material.Slate, C.Stone)
		return
	end
	local side = (length - door.X) / 2
	for _, s in { -1, 1 } do
		part(parent, name, Vector3.new(side, height, WALL_T), cframe * CFrame.new(s * (door.X / 2 + side / 2), height / 2, 0), Enum.Material.Slate, C.Stone)
	end
	part(parent, name .. "Lintel", Vector3.new(door.X, height - door.Y, WALL_T), cframe * CFrame.new(0, door.Y + (height - door.Y) / 2, 0), Enum.Material.Slate, C.Stone)
end

-- A placeholder figure (statue, mannequin, keeper) at R6 scale.
local function figure(parent: Instance, name: string, cframe: CFrame, scale: number, color: Color3)
	local f = Instance.new("Model")
	f.Name = name
	part(f, "Body", Vector3.new(2, 2, 1) * scale, cframe * CFrame.new(0, 3 * scale, 0), Enum.Material.SmoothPlastic, color)
	part(f, "Legs", Vector3.new(2, 2, 1) * scale, cframe * CFrame.new(0, 1 * scale, 0), Enum.Material.SmoothPlastic, color)
	part(f, "Head", Vector3.new(1.2, 1.2, 1.2) * scale, cframe * CFrame.new(0, 4.6 * scale, 0), Enum.Material.SmoothPlastic, color)
	f.Parent = parent
end

local function brazier(parent: Instance, position: Vector3)
	part(parent, "BrazierBowl", Vector3.new(2.4, 3, 3), CFrame.new(position + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Metal, C.Iron, Enum.PartType.Cylinder)
	local fire = part(parent, "BrazierFire", Vector3.new(1.8, 1.4, 1.8), CFrame.new(position + Vector3.new(0, 3.6, 0)), Enum.Material.Neon, C.Fire, Enum.PartType.Ball)
	fire.CanCollide = false
	light(fire, "PointLight", C.Fire, 1.6, 22)
end

local function buildGround()
	local g = folder("Ground")
	part(g, "Yard", Vector3.new(YARD_X * 2 + 60, 2, YARD_FAR + 90), CFrame.new(0, -1, -(YARD_FAR - 90) / 2), Enum.Material.Cobblestone, C.Cobble)
end

local function buildHall()
	local h = folder("GreatHall")
	local side = 2 * HALL_R * math.tan(math.rad(22.5))
	for k = 0, 7 do
		local a = math.rad(k * 45) -- k=0 south (+Z), 2 east, 4 north, 6 west
		local normal = CFrame.Angles(0, a, 0)
		local door = if k == 0 or k == 2 or k == 6 then Vector2.new(DOOR_W, DOOR_H) elseif k == 4 then Vector2.new(GREAT_DOOR_W, GREAT_DOOR_H) else nil
		wall(h, "Wall" .. k, side + 0.4, HALL_H, normal * CFrame.new(0, 0, HALL_R + WALL_T / 2), door)
		-- floor and vault sectors (the vault leaves an oculus open in the middle)
		part(h, "Floor" .. k, Vector3.new(side, 1, HALL_R), normal * CFrame.new(0, -0.5, HALL_R / 2), Enum.Material.Slate, C.Floor)
		part(h, "Vault" .. k, Vector3.new(side + 0.4, 2, HALL_R - 8), normal * CFrame.new(0, HALL_H + 1, 8 + (HALL_R - 8) / 2), Enum.Material.Slate, C.StoneDark)
		-- upper gallery
		part(h, "Gallery" .. k, Vector3.new(side, 1, 6), normal * CFrame.new(0, 18, HALL_R - 3), Enum.Material.WoodPlanks, C.Wood)
	end
	-- Blood Table: octagonal plinth (cylinder in the graybox), relief, candle ring, iron crown above.
	local t = folder("BloodTable", h)
	part(t, "Plinth", Vector3.new(3.5, 16, 16), CFrame.new(0, 1.75, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Basalt, C.StoneDark, Enum.PartType.Cylinder)
	local relief = part(t, "Relief", Vector3.new(0.3, 13, 13), CFrame.new(0, 3.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Neon, C.Blood, Enum.PartType.Cylinder)
	relief.Transparency = 0.35
	light(relief, "PointLight", C.Blood, 1.2, 14)
	for i = 0, 11 do
		local a = math.rad(i * 30)
		local candle = part(t, "Candle", Vector3.new(0.5, 1.4, 0.5), CFrame.new(math.sin(a) * 9.5, 4.2, math.cos(a) * 9.5), Enum.Material.Neon, C.Candle)
		candle.CanCollide = false
	end
	local crown = folder("CandleCrown", h)
	for i = 0, 7 do
		local a = math.rad(i * 45)
		local c = part(crown, "Crown", Vector3.new(4, 0.6, 0.6), CFrame.new(math.sin(a) * 9, 30, math.cos(a) * 9) * CFrame.Angles(0, a + math.rad(90), 0), Enum.Material.Metal, C.Iron)
		c.CanCollide = false
		light(c, "PointLight", C.Candle, 0.7, 40) -- low on purpose: pools of light, dark corners
	end
	-- Moon shafts through the high lancets (northwest and northeast walls, aimed at the floor).
	for _, k in { 1, 3, 5, 7 } do
		local a = math.rad(k * 45)
		local window = part(h, "MoonLancet", Vector3.new(4, 14, 0.4), CFrame.Angles(0, a, 0) * CFrame.new(0, 32, HALL_R - 0.4), Enum.Material.Neon, C.Moon)
		window.Transparency = 0.75
		window.CanCollide = false
		local holder = part(h, "MoonShaft", Vector3.one * 0.2, CFrame.Angles(0, a, 0) * CFrame.new(0, 32, HALL_R - 1.5) * CFrame.Angles(math.rad(-45), 0, 0), Enum.Material.SmoothPlastic, C.Moon)
		holder.Transparency, holder.CanCollide, holder.CanQuery = 1, false, false
		light(holder, "SpotLight", C.Moon, 4, 60, { Angle = 45, Face = Enum.NormalId.Front })
		-- a sconce under each lancet for warm fill at eye level
		local sconce = part(h, "Sconce", Vector3.new(0.8, 1.2, 0.8), CFrame.Angles(0, a, 0) * CFrame.new(0, 10, HALL_R - 1), Enum.Material.Neon, C.Candle)
		sconce.CanCollide = false
		light(sconce, "PointLight", C.Candle, 1.1, 22)
	end
	-- Spawn porch outside the south door.
	local porch = folder("SpawnPorch", h)
	part(porch, "Roof", Vector3.new(24, 1.5, 16), CFrame.new(0, 18, HALL_R + 10), Enum.Material.Slate, C.StoneDark)
	for _, x in { -10, 10 } do
		part(porch, "Pillar", Vector3.new(2, 18, 2), CFrame.new(x, 9, HALL_R + 16), Enum.Material.Slate, C.Stone)
	end
	part(porch, "Steps", Vector3.new(24, 1, 16), CFrame.new(0, -0.5, HALL_R + 10), Enum.Material.Slate, C.Floor)
end

local function buildWing(name: string, dir: number, keyColor: Color3)
	local w = folder(name)
	local x0 = dir * (HALL_R + WALL_T)
	local cx = x0 + dir * WING_LEN / 2
	part(w, "Floor", Vector3.new(WING_LEN, 1, WING_W), CFrame.new(cx, -0.5, 0), Enum.Material.Slate, C.Floor)
	part(w, "Roof", Vector3.new(WING_LEN, 2, WING_W + WALL_T * 2), CFrame.new(cx, WING_H + 1, 0), Enum.Material.Slate, C.StoneDark)
	for _, z in { -1, 1 } do
		wall(w, "SideWall", WING_LEN, WING_H, CFrame.new(cx, 0, z * (WING_W / 2 + WALL_T / 2)))
	end
	wall(w, "EndWall", WING_W + WALL_T * 2, WING_H, CFrame.new(x0 + dir * (WING_LEN + WALL_T / 2), 0, 0) * CFrame.Angles(0, math.rad(90), 0))
	return w, cx
end

local function buildWings()
	-- West: Hall of Oaths (class statues, cold moonlight, dark mirror at the end).
	local west, wx = buildWing("HallOfOaths", -1, C.Moon)
	for i, z in { -8, 8 } do
		for j = 0, 1 do
			local x = wx + 12 - j * 18
			part(west, "Plinth", Vector3.new(5, 2, 5), CFrame.new(x, 1, z), Enum.Material.Marble, C.StoneDark)
			figure(west, "ClassStatue", CFrame.new(x, 2, z) * CFrame.Angles(0, math.rad(if z < 0 then 0 else 180), 0), 1.6, C.Placeholder)
		end
	end
	local mirror = part(west, "DarkMirror", Vector3.new(0.4, 14, 8), CFrame.new(wx - WING_LEN / 2 + 1, 8, 0), Enum.Material.Glass, Color3.fromRGB(20, 18, 28))
	mirror.Reflectance = 0.4
	for _, x in { wx + 10, wx - 12 } do
		local window = part(west, "MoonWindow", Vector3.new(6, 10, 0.4), CFrame.new(x, 22, -WING_W / 2 + 0.3), Enum.Material.Neon, C.Moon)
		window.Transparency = 0.75
		window.CanCollide = false
		local holder = part(west, "MoonShaft", Vector3.one * 0.2, CFrame.new(x, 22, -WING_W / 2 + 1.5) * CFrame.Angles(math.rad(45), 0, 0), Enum.Material.SmoothPlastic, C.Moon)
		holder.Transparency, holder.CanCollide, holder.CanQuery = 1, false, false
		light(holder, "SpotLight", C.Moon, 3.5, 40, { Angle = 55, Face = Enum.NormalId.Back })
		local fill = part(west, "Fill", Vector3.one * 0.2, CFrame.new(x, 16, 0), Enum.Material.SmoothPlastic, C.Moon)
		fill.Transparency, fill.CanCollide, fill.CanQuery = 1, false, false
		light(fill, "PointLight", Color3.fromRGB(150, 165, 220), 0.8, 26)
	end
	-- each statue gets a cold key light from above
	for _, z in { -8, 8 } do
		for j = 0, 1 do
			local key = part(west, "StatueKey", Vector3.one * 0.2, CFrame.new(wx + 12 - j * 18, 16, z), Enum.Material.SmoothPlastic, C.Moon)
			key.Transparency, key.CanCollide, key.CanQuery = 1, false, false
			light(key, "SpotLight", Color3.fromRGB(170, 190, 255), 3, 18, { Angle = 35, Face = Enum.NormalId.Bottom })
		end
	end
	-- East: Atelier (mannequins, Bloodgem counter with a keeper, warm lamps).
	local east, ex = buildWing("Atelier", 1, C.Candle)
	for i = 0, 3 do
		local x = ex - 16 + i * 10
		figure(east, "Mannequin", CFrame.new(x, 0, 8) * CFrame.Angles(0, math.rad(180), 0), 1, C.Placeholder)
	end
	part(east, "Counter", Vector3.new(4, 4, 14), CFrame.new(ex + 14, 2, -4), Enum.Material.WoodPlanks, C.Wood)
	figure(east, "Keeper", CFrame.new(ex + 18, 0, -4) * CFrame.Angles(0, math.rad(90), 0), 1, Color3.fromRGB(90, 70, 60))
	for _, x in { ex - 14, ex, ex + 14 } do
		local lamp = part(east, "Lamp", Vector3.new(1.2, 1.6, 1.2), CFrame.new(x, 20, 0), Enum.Material.Neon, C.Candle)
		lamp.CanCollide = false
		light(lamp, "PointLight", C.Candle, 1.8, 28)
	end
end

local function buildYard()
	local y = folder("Yard")
	local south = -(HALL_R * math.tan(math.rad(22.5)) + 2) -- just north of the wings
	local len = YARD_FAR + south
	-- perimeter walls
	for _, s in { -1, 1 } do
		wall(y, "SideWall", len, YARD_WALL_H, CFrame.new(s * (YARD_X + WALL_T / 2), 0, (south - YARD_FAR) / 2) * CFrame.Angles(0, math.rad(90), 0))
		local inner = HALL_R - 2
		wall(y, "SouthWall", YARD_X - inner, YARD_WALL_H, CFrame.new(s * (inner + (YARD_X - inner) / 2), 0, south - WALL_T / 2))
	end
	wall(y, "NorthWall", YARD_X * 2 + WALL_T * 2, YARD_WALL_H, CFrame.new(0, 0, -YARD_FAR - WALL_T / 2), Vector2.new(18, 12))

	-- Movement course (northwest): steps up to ledges at 8, 16, 24 studs and a dash gap.
	local course = folder("MovementCourse", y)
	local ledges = {
		{ Vector3.new(10, 8, 10), Vector3.new(-58, 4, -62) },
		{ Vector3.new(10, 16, 10), Vector3.new(-58, 8, -78) },
		{ Vector3.new(12, 24, 12), Vector3.new(-56, 12, -96) }, -- ruined tower top (charged jump)
		{ Vector3.new(8, 16, 8), Vector3.new(-30, 8, -96) }, -- across the dash gap (18 studs)
	}
	for i, l in ledges do
		part(course, "Ledge" .. i, l[1], CFrame.new(l[2]), Enum.Material.Slate, C.Stone)
	end
	for i = 1, 6 do
		part(course, "Step", Vector3.new(6, i * 1.3, 3), CFrame.new(-44, i * 0.65, -58 - i * 3), Enum.Material.Slate, C.Stone)
	end

	-- Duel ring (centre) and dummy line (west).
	part(y, "DuelRing", Vector3.new(0.4, 30, 30), CFrame.new(0, 0.2, -108) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Sand, C.Sand, Enum.PartType.Cylinder)
	for i = 0, 3 do
		part(y, "DummyPost", Vector3.new(3, 0.4, 3), CFrame.new(-58 + i * 9, 0.2, -146), Enum.Material.WoodPlanks, C.Wood)
	end

	-- Ruined arches (east): two broken arches.
	local ruins = folder("RuinedArches", y)
	for i, z in { -60, -76 } do
		part(ruins, "Pier", Vector3.new(3, 16, 3), CFrame.new(42, 8, z), Enum.Material.Slate, C.Stone)
		part(ruins, "Pier", Vector3.new(3, 10 + i * 3, 3), CFrame.new(58, (10 + i * 3) / 2, z), Enum.Material.Slate, C.Stone)
		part(ruins, "Lintel", Vector3.new(12, 2.5, 3), CFrame.new(46, 17, z) * CFrame.Angles(0, 0, math.rad(-8)), Enum.Material.Slate, C.Stone)
	end

	-- Shinigami pact circle (northeast): sigil and gold pillar of light. Tagged BL_PactCircle for ShinigamiService.
	local kin = folder("ShinigamiCircle", y)
	local sigil = part(kin, "Sigil", Vector3.new(0.3, 18, 18), CFrame.new(46, 0.15, -140) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Neon, C.Gold, Enum.PartType.Cylinder)
	sigil.Transparency = 0.55
	sigil:SetAttribute("Shinigami", "Kurogane")
	game:GetService("CollectionService"):AddTag(sigil, "BL_PactCircle")
	local pillar = part(kin, "LightPillar", Vector3.new(70, 6, 6), CFrame.new(46, 35, -140) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Neon, C.Gold, Enum.PartType.Cylinder)
	pillar.Transparency = 0.82
	pillar.CanCollide = false
	pillar.CastShadow = false
	light(sigil, "PointLight", C.Gold, 2.2, 26)

	-- The training zone: the only place in the hub where combat is allowed (Shared.Util.Zones).
	local zone = part(y, "TrainingZone", Vector3.new(YARD_X * 2, 120, YARD_FAR + south), CFrame.new(0, 50, (south - YARD_FAR) / 2), Enum.Material.SmoothPlastic, C.Stone)
	zone.Transparency, zone.CanCollide, zone.CanQuery, zone.CanTouch, zone.CastShadow = 1, false, false, false, false
	game:GetService("CollectionService"):AddTag(zone, "BL_CombatZone")

	-- Braziers along the walls.
	for _, p in { Vector3.new(-66, 0, -30), Vector3.new(66, 0, -30), Vector3.new(-66, 0, -125), Vector3.new(66, 0, -110), Vector3.new(-20, 0, -165), Vector3.new(20, 0, -165) } do
		brazier(y, p)
	end
end

local function buildBellTower()
	local b = folder("BellTower")
	local z = -YARD_FAR - 26
	part(b, "Shaft", Vector3.new(16, 70, 16), CFrame.new(0, 35, z), Enum.Material.Slate, C.Stone)
	for _, c in { Vector3.new(-6.5, 0, -6.5), Vector3.new(6.5, 0, -6.5), Vector3.new(-6.5, 0, 6.5), Vector3.new(6.5, 0, 6.5) } do
		part(b, "BelfryPost", Vector3.new(3, 14, 3), CFrame.new(c + Vector3.new(0, 77, z)), Enum.Material.Slate, C.Stone)
	end
	part(b, "Bell", Vector3.new(5, 6, 5), CFrame.new(0, 78, z), Enum.Material.Metal, Color3.fromRGB(120, 92, 50))
	part(b, "Spire", Vector3.new(18, 4, 18), CFrame.new(0, 86, z), Enum.Material.Slate, C.StoneDark)
	part(b, "SpireTop", Vector3.new(8, 14, 8), CFrame.new(0, 95, z), Enum.Material.Slate, C.StoneDark)
	local lamp = part(b, "BelfryLight", Vector3.new(1, 1, 1), CFrame.new(0, 74, z), Enum.Material.Neon, C.Candle)
	lamp.CanCollide = false
	light(lamp, "PointLight", C.Candle, 2, 30)
end

-- Spots other systems use: spawn and training dummies (moved here from the old yard).
function VigilGraybox.Spots(): { [string]: CFrame }
	return require(script.Parent.VigilEstateLayout).Spots()
end

function VigilGraybox.Build(): Folder
	local old = workspace:FindFirstChild("Vigil")
	if old then
		old:Destroy()
	end
	root = Instance.new("Folder")
	root.Name = "Vigil"
	buildGround()
	buildHall()
	buildWings()
	buildYard()
	buildBellTower()
	-- Prototype bay; art acceptance pending. Masters live outside regenerated root.
	require(script.Parent.VigilBay).Apply(root)
	-- North threshold composition; owner artistic review pending.
	require(script.Parent.VigilNorthThreshold).Apply(root)
	-- Owner-directed two-storey manor: timber, red wool, accessible gallery.
	require(script.Parent.VigilManor).Apply(root)
	-- Larger estate layout; R6 furniture and training heights remain functional.
	require(script.Parent.VigilEstateLayout).Apply(root)
	-- Art lighting and oak finish are reapplied after all layout geometry.
	require(script.Parent.VigilAtmosphere).Apply(root)
	-- Custom melted-wax details are fitted after architectural scaling.
	require(script.Parent.VigilCandles).Apply(root)
	-- Imported exterior is fitted after the scaled playable interior.
	require(script.Parent.VigilExterior).Apply(root)
	require(script.Parent.VigilLayeredWindows).Apply(root)
	require(script.Parent.VigilComposition).Apply(root)
	require(script.Parent.VigilSurfaceArt).Apply(root)
	require(script.Parent.VigilEstateLandscape).Apply(root)
	require(script.Parent.VigilFoundation).Apply(root)
	require(script.Parent.VigilExteriorLighting).Apply(root)
	root.Parent = workspace
	return root
end

return VigilGraybox

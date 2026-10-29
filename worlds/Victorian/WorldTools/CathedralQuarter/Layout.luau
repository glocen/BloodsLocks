--!strict
-- Layout: the Cathedral Quarter blockout, section by section, in studs (north = -Z; Y = finished walking surface).
-- Design and departures from ChatGPT's spec: worlds/Victorian/CathedralQuarter/w1-blockout.md. Gameplay markers use
-- the world contract (Shared.World.Tags); region and enemy ids come from the definitions.
-- Levels: crypt -18 · street 0 · nave 8 · gallery/terraces 24 · roofs and crossing 36.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tags = require(ReplicatedStorage.Shared.World.Tags)

local Layout = {}

-- lamps make pools, not washes (a range of 24 lit whole facades)
local WARM = { Color = Color3.fromRGB(255, 176, 104), Brightness = 1.2, Range = 16 }
local WARM_SHADOW = { Color = Color3.fromRGB(255, 176, 104), Brightness = 1.6, Range = 20, Shadows = true }
local CANDLE = { Color = Color3.fromRGB(255, 150, 80), Brightness = 0.9, Range = 16 }
local SPILL = { Color = Color3.fromRGB(190, 200, 232), Brightness = 1.4, Range = 30 }
-- the crypt must show its floor edges and the next exit (spec section 9; Duskbloods testers: lower areas too dark)
local CRYPT_FILL = { Color = Color3.fromRGB(130, 140, 180), Brightness = 1.3, Range = 28 }
local SCONCE = { Color = Color3.fromRGB(255, 150, 80), Brightness = 1.2, Range = 18 }
local PACT = { Color = Color3.fromRGB(232, 200, 120), Brightness = 1.2, Range = 18 }

-- Envelope and stair wells cut into the street slab.
local L1_WELL = { -144, -130, 2, 56 }
local L2_WELL = { 106, 120, -40, 14 }

-- 1 · Street slab, perimeter, socket gates -------------------------------------------------------------------------

function Layout.Ground(b: any)
	b:Slab("Street", -240, 240, -260, 240, 0, 2, "Ground", { L1_WELL, L2_WELL })
	-- perimeter wall: above any jump from any roof (36 + 46); becomes skyline in the art pass
	b:Wall("PerimN", "X", -264, -260, -244, 244, 0, 100, "Boundary", { { -12, 12, 0, 20 } })
	b:Wall("PerimS", "X", 240, 244, -244, 244, 0, 100, "Boundary")
	b:Wall("PerimW", "Z", -244, -240, -260, 240, 0, 100, "Boundary", { { 52, 80, 0, 20 } })
	b:Wall("PerimE", "Z", 240, 244, -260, 240, 0, 100, "Boundary", { { 40, 68, 0, 20 } })
	-- expansion sockets, closed by iron gates for now (spec section 8)
	b:Box("GateNorth", -12, 12, 0, 20, -262, -261, "Iron")
	b:Box("GateWest", -242, -241, 0, 20, 52, 80, "Iron")
	b:Box("GateEast", 241, 242, 0, 20, 40, 68, "Iron")
end

-- 2 · Massing: terraces, courts, service blocks ---------------------------------------------------------------------

-- A ring of buildings around a court with passages (gaps) through it.
local function courtBlock(b: any, name: string, outer: { number }, court: { number }, gaps: { { number } }, eave: number, ridge: number)
	local Kit = require(script.Parent.Kit)
	local holes = table.clone(gaps)
	table.insert(holes, court)
	for i, r in Kit.Subtract(outer, holes) do
		b:Block(`{name}{i}`, r[1], r[2], r[3], r[4], eave, ridge)
	end
end

function Layout.Massing(b: any)
	courtBlock(b, "ChapterHouses", { -226, -142, -244, -160 }, { -206, -162, -224, -180 }, { { -162, -142, -211, -193 }, { -193, -175, -180, -160 } }, 30, 14)
	courtBlock(b, "BellWorks", { 142, 226, -244, -150 }, { 162, 206, -224, -170 }, { { 142, 162, -206, -188 }, { 175, 193, -170, -150 } }, 34, 14)
	courtBlock(b, "WestTerrace", { -226, -170, -40, 50 }, { -204, -178, -12, 28 }, { { -178, -170, 2, 20 }, { -200, -182, 28, 50 } }, 26, 12)
	courtBlock(b, "SouthWestTerraces", { -226, -170, 140, 214 }, { -208, -180, 160, 200 }, { { -180, -170, 172, 190 }, { -203, -185, 140, 160 } }, 26, 12)
	courtBlock(b, "ServiceRow", { 156, 226, 140, 214 }, { 170, 206, 160, 200 }, { { 156, 170, 170, 188 }, { 176, 194, 140, 160 } }, 24, 10)
	courtBlock(b, "EastTerrace", { 172, 226, -60, 40 }, { 180, 210, -34, 6 }, { { 172, 180, -24, -6 }, { 186, 204, 6, 40 } }, 26, 12)
	b:Block("NorthWest", -110, -30, -244, -204, 26, 12)
	b:Block("NorthEast", 30, 110, -244, -204, 26, 12)
	b:Block("SouthTerracesW", -132, -14, 154, 214, 26, 12)
	b:Block("SouthTerracesE", 14, 140, 158, 222, 28, 12)
	-- the shrine (O4): an open-fronted ossuary threshold, open to the east
	b:Box("ShrineBack", -146, -142, 0, 20, -140, -104, "Wall")
	b:Box("ShrineNorth", -142, -110, 0, 20, -140, -136, "Wall")
	b:Box("ShrineSouth", -142, -110, 0, 20, -108, -104, "Wall")
	b:Box("ShrineRoof", -146, -110, 20, 22, -140, -104, "Roof")
	-- lit windows: sparse, where people live (spec: small amber windows imply occupation)
	for i, w in {
		{ -100, 154, "S" }, { -48, 154, "S" }, { 40, 158, "S" }, { 104, 158, "S" },
		{ -170, 70, "E" }, { -170, 186, "E" }, { 156, 120, "W" }, { 172, -40, "W" }, { -142, -190, "E" },
	} do
		local x, z, face = w[1], w[2], w[3]
		if face == "S" then
			b:Window(`Window{i}`, x - 2, x + 2, 9, 14, z - 0.2, z + 0.2)
		else
			b:Window(`Window{i}`, x - 0.2, x + 0.2, 9, 14, z - 2, z + 2)
		end
	end
end

-- 3 · The cathedral, its west bell tower and east chapel -------------------------------------------------------------

function Layout.Cathedral(b: any)
	-- plinth: the nave floor at +8, front stair down to the street
	b:Box("Plinth", -68, 68, -2, 8, -176, -32, "Landmark")
	local door = { -54, -40, 8, 40 } -- vestibule door (8..22) and gallery door G1/G2 (24..40), split by the +24 floors
	b:Wall("WallW", "Z", -68, -64, -176, -36, 8, 56, "Landmark", { door })
	b:Wall("WallE", "Z", 64, 68, -176, -36, 8, 56, "Landmark", { door })
	b:Wall("WallN", "X", -176, -172, -64, 64, 8, 56, "Landmark")
	b:Wall("Front", "X", -36, -32, -68, 68, 8, 56, "Landmark", { { -12, 12, 8, 40 }, { -40, -30, 8, 24 }, { 30, 40, 8, 24 } })
	b:Gable("Roof", -68, 68, -176, -32, 56, 48, "Z")
	b:Gable("FrontGable", -68, 68, -36, -32, 56, 48, "Z", "Landmark")
	b:Gable("BackGable", -68, 68, -176, -172, 56, 48, "Z", "Landmark")
	b:Box("Apse", -30, 30, 0, 60, -186, -176, "Landmark")
	b:Gable("ApseRoof", -30, 30, -186, -176, 60, 20, "X")
	for _, z in { -150, -134, -118, -102, -86, -70 } do
		b:Box(`PierW{z}`, -50, -46, 8, 56, z - 2, z + 2, "Landmark")
		b:Box(`PierE{z}`, 46, 50, 8, 56, z - 2, z + 2, "Landmark")
	end
	-- gallery at +24: west and east ledges, back bridge, front landings (G1/G2 open onto them)
	b:Slab("GalleryW", -64, -52, -170, -56, 24, 2, "Walk")
	b:Slab("GalleryE", 52, 64, -170, -56, 24, 2, "Walk")
	b:Slab("GalleryBack", -52, 52, -170, -158, 24, 2, "Walk")
	b:Slab("GalleryLandingW", -64, -46, -56, -36, 24, 2, "Walk")
	b:Slab("GalleryLandingE", 46, 64, -56, -36, 24, 2, "Walk")
	b:Rail("GalleryRailW", -52, -51, -158, -56, 24)
	b:Rail("GalleryRailE", 51, 52, -158, -56, 24)
	b:Rail("GalleryRailBack", -52, 52, -158, -157, 24)
	b:Rail("GalleryRailLW", -46, -45, -56, -36, 24)
	b:Rail("GalleryRailLE", 45, 46, -56, -36, 24)
	b:Rail("GalleryRailLWN", -52, -46, -57, -56, 24)
	b:Rail("GalleryRailLEN", 46, 52, -57, -56, 24)
	-- thresholds through the wall thickness (G1, G2 at +24)
	b:Slab("ThresholdG1", -68, -64, -54, -40, 24, 2, "Walk")
	b:Slab("ThresholdG2", 64, 68, -54, -40, 24, 2, "Walk")
	-- front stair: 16 risers of 0.5 up to the portal; cheek walls apart from the walkable collision
	b:Flight("FrontStair", -56, 56, -32, -16, 0, 8, "N")
	b:Box("StairCheekW", -60, -56, 0, 9, -32, -16, "Landmark")
	b:Box("StairCheekE", 56, 60, 0, 9, -32, -16, "Landmark")

	-- west bell tower: base = west vestibule (+8), floor +24 (G1 house), shaft to the belfry, spire
	b:Box("TowerBase", -91, -68, -2, 8, -55, -35, "Landmark")
	b:Wall("TowerW", "Z", -94, -91, -58, -32, 0, 100, "Landmark", { { -54, -36, 8, 22 } })
	b:Wall("TowerN", "X", -58, -55, -94, -68, 0, 100, "Landmark", { { -91, -73, 24, 40 } })
	b:Wall("TowerS", "X", -35, -32, -94, -68, 0, 100, "Landmark", { { -84, -72, 24, 40 } })
	b:Slab("TowerFloor24", -91, -68, -55, -35, 24, 2, "Walk")
	b:Box("ThresholdTowerW", -94, -91, -2, 8, -54, -36, "Landmark")
	b:Slab("ThresholdTowerN", -91, -73, -58, -55, 24, 2, "Walk")
	b:Gable("SpireX", -94, -68, -58, -32, 100, 48, "X")
	b:Gable("SpireZ", -94, -68, -58, -32, 100, 48, "Z")
	-- west vestibule ramp down to the west lane (8 over 24, 18 wide)
	b:Flight("RampWest", -118, -94, -54, -36, 0, 8, "E")

	-- east chapel: east vestibule (+8), flat roof at +24 (G2 landing)
	b:Box("ChapelFloor", 68, 94, -2, 8, -74, -34, "Landmark")
	b:Wall("ChapelN", "X", -76, -74, 68, 96, 0, 22, "Landmark")
	b:Wall("ChapelS", "X", -34, -32, 68, 96, 0, 22, "Landmark")
	b:Wall("ChapelE", "Z", 94, 96, -74, -34, 0, 22, "Landmark", { { -62, -44, 8, 22 } })
	b:Box("ThresholdChapelE", 94, 96, -2, 8, -62, -44, "Landmark")
	b:Slab("ChapelRoof", 68, 96, -76, -32, 24, 2, "Walk")
	b:Rail("ChapelRailE", 95, 96, -64, -32, 24)
	b:Rail("ChapelRailN", 68, 96, -76, -75, 24)
	b:Rail("ChapelRailS", 78, 96, -33, -32, 24)
	b:Flight("RampEast", 96, 120, -62, -44, 0, 8, "W")

	-- light: the usable entrance is the warmest place; candles along the aisles; the altar; cool clerestory moonlight
	-- on the fighting floor (without it the D/E encounter sat in black)
	b:Glow("PortalLight", 0, 20, -42, "Point", { Color = Color3.fromRGB(255, 170, 96), Brightness = 1.5, Range = 24, Shadows = true })
	for _, z in { -88, -128 } do
		b:Glow(`Clerestory{z}`, 0, 50, z, "Spot", { Color = Color3.fromRGB(150, 160, 220), Brightness = 1.1, Range = 60 }, Enum.NormalId.Bottom)
	end
	for _, z in { -140, -110, -80 } do
		b:Glow(`CandleW{z}`, -57, 11, z, "Point", CANDLE)
		b:Glow(`CandleE{z}`, 57, 11, z, "Point", CANDLE)
	end
	b:Glow("Altar", 0, 13, -166, "Point", { Color = Color3.fromRGB(255, 150, 80), Brightness = 1.3, Range = 28 })
end

-- 4 · Cloister, U1 and the S7 roof ---------------------------------------------------------------------------------

function Layout.Cloister(b: any)
	-- arcade ranges 12 wide around a 36×46 court; roofs at +24 make a walkable ring
	b:Wall("CloisterN", "X", 18, 20, -128, -68, 0, 22, "Wall", { { -107, -89, 0, 18 } })
	b:Wall("CloisterS", "X", 86, 88, -128, -68, 0, 22, "Wall")
	b:Wall("CloisterW", "Z", -128, -126, 20, 86, 0, 22, "Wall", { { 62, 80, 0, 18 } })
	b:Wall("CloisterE", "Z", -70, -68, 20, 86, 0, 22, "Wall", { { 58, 76, 0, 18 } })
	for _, x in { -116, -104, -92, -80 } do
		b:Box(`ArcadeN{x}`, x - 1, x + 1, 0, 22, 29, 31, "Wall")
		b:Box(`ArcadeS{x}`, x - 1, x + 1, 0, 22, 75, 77, "Wall")
	end
	for _, z in { 42, 53, 64 } do
		b:Box(`ArcadeW{z}`, -117, -115, 0, 22, z - 1, z + 1, "Wall")
		b:Box(`ArcadeE{z}`, -81, -79, 0, 22, z - 1, z + 1, "Wall")
	end
	b:Slab("CloisterRoofN", -128, -68, 18, 30, 24, 2, "Walk")
	b:Slab("CloisterRoofS", -128, -68, 76, 88, 24, 2, "Walk")
	b:Slab("CloisterRoofW", -128, -116, 30, 76, 24, 2, "Walk")
	b:Slab("CloisterRoofE", -80, -68, 30, 76, 24, 2, "Walk")
	b:Rail("RoofRailInN", -116, -80, 30, 31, 24)
	b:Rail("RoofRailInS", -116, -80, 75, 76, 24)
	b:Rail("RoofRailInW", -117, -116, 31, 75, 24)
	b:Rail("RoofRailInE", -80, -79, 31, 75, 24)
	b:Rail("RoofRailOutN1", -128, -84, 18, 19, 24)
	b:Rail("RoofRailOutN2", -72, -68, 18, 19, 24)
	b:Rail("RoofRailOutS", -128, -78, 87, 88, 24)
	b:Rail("RoofRailOutW", -128, -127, 19, 87, 24)
	b:Rail("RoofRailOutE", -69, -68, 19, 87, 24)
	for i, p in { { -122, 24 }, { -74, 24 }, { -122, 82 }, { -74, 82 } } do
		b:Glow(`CloisterLight{i}`, p[1], 14, p[2], "Point", CANDLE)
	end

	-- U1: along the cloister's south side, 0 → 12 → 24, onto the roof ring
	b:Flight("U1a", -144, -120, 94, 106, 0, 12, "E")
	b:Box("U1Landing12", -120, -102, 0, 12, 94, 106, "Walk")
	b:Box("U1bBase", -102, -78, 0, 12, 94, 106, "Building")
	b:Flight("U1b", -102, -78, 94, 106, 12, 24, "E")
	b:Slab("U1Landing24", -78, -60, 88, 106, 24, 2, "Walk")
	b:Rail("U1RailE", -61, -60, 88, 106, 24)
	b:Rail("U1RailS", -68, -60, 105, 106, 24)
	for _, p in { { -77, 105 }, { -61, 89 }, { -61, 105 } } do
		b:Box("U1Pier", p[1] - 1, p[1] + 1, 0, 22, p[2] - 1, p[2] + 1, "Wall")
	end

	-- S7: the west roof court (+36) on its house, a flight down to +24 joining U1's landing
	b:Box("S7House", -150, -110, 0, 34, 112, 136, "Building")
	b:Slab("S7Roof", -150, -110, 112, 136, 36, 2, "Walk")
	b:Box("S7Headhouse", -150, -138, 36, 50, 124, 136, "Building")
	b:Gable("S7HeadRoof", -150, -138, 124, 136, 50, 6, "X")
	b:Rail("S7RailW", -150, -149, 112, 124, 36)
	b:Rail("S7RailN", -150, -110, 112, 113, 36)
	b:Rail("S7RailS", -138, -110, 135, 136, 36)
	b:Box("S7FlightBase", -110, -86, 0, 24, 112, 124, "Building")
	b:Flight("S7Down", -110, -86, 112, 124, 24, 36, "W")
	b:Slab("S7Landing24", -86, -68, 106, 124, 24, 2, "Walk")
	b:Rail("S7LandingRailS", -86, -68, 123, 124, 24)
	b:Rail("S7LandingRailE", -69, -68, 106, 123, 24)
	for _, p in { { -85, 123 }, { -69, 123 } } do
		b:Box("S7Pier", p[1] - 1, p[1] + 1, 0, 22, p[2] - 1, p[2] + 1, "Wall")
	end
end

-- 5 · The upper circuit: bridge to the tower, crossing, east roofs, U2 --------------------------------------------

function Layout.Upper(b: any)
	-- west: cloister roof → Y24 bridge → landing at the tower's south door (G1 house) and the crossing's west flight
	b:Slab("BridgeW24", -84, -72, -16, 18, 24, 2, "Walk")
	b:Rail("BridgeW24RailW", -85, -84, -16, 18, 24)
	b:Rail("BridgeW24RailE", -72, -71, -16, 18, 24)
	b:Slab("TowerLanding24", -84, -60, -32, -16, 24, 2, "Walk")
	b:Rail("TowerLandingRailE", -61, -60, -32, -16, 24)
	b:Rail("TowerLandingRailW", -85, -84, -32, -16, 24)
	for _, p in { { -83, -17 }, { -73, 2 }, { -83, 2 }, { -61, -17 } } do
		b:Box("BridgePier", p[1] - 1, p[1] + 1, 0, 22, p[2] - 1, p[2] + 1, "Wall")
	end
	b:Flight("CrossingW", -72, -60, -16, 8, 24, 36, "S", true)
	-- the crossing (+36) over the plaza, on piers outside the ritual court
	b:Slab("Crossing", -72, 72, 8, 20, 36, 2, "Walk")
	b:Rail("CrossingRailS", -72, 72, 19, 20, 36)
	b:Rail("CrossingRailN", -60, 60, 8, 9, 36)
	for _, x in { -48, -24, 0, 24, 48 } do
		b:Box(`CrossingPier{x}`, x - 2, x + 2, 0, 34, 12, 16, "Wall")
	end
	b:Flight("CrossingE", 60, 72, -16, 8, 24, 36, "S", true)
	b:Slab("ChapelLanding24", 60, 78, -32, -16, 24, 2, "Walk")
	b:Rail("ChapelLandingRailE", 77, 78, -32, -16, 24)
	for _, p in { { 61, -17 }, { 77, -17 }, { 61, 7 }, { 71, 7 }, { -61, 7 }, { -71, 7 } } do
		b:Box("CrossingFlightPier", p[1] - 1, p[1] + 1, 0, 24, p[2] - 1, p[2] + 1, "Wall")
	end

	-- west range: the roof walk at +24 north of the tower (overlooks the west lane and the shrine)
	b:Box("WestRange", -94, -70, 0, 22, -136, -58, "Building")
	b:Slab("WestRangeRoof", -94, -70, -136, -58, 24, 2, "Walk")
	b:Rail("WestRangeRailW", -94, -93, -136, -58, 24)
	b:Rail("WestRangeRailN", -94, -70, -136, -135, 24)
	b:Rail("WestRangeRailE", -71, -70, -135, -58, 24)

	-- east: chapel roof (G2) → walkway → U2's +24 landing; U2 stacks 0 → 12 → 24 → 36 against the east range
	b:Box("EastRange", 68, 118, 0, 34, -140, -90, "Building")
	b:Slab("EastRangeRoof", 68, 118, -140, -90, 36, 2, "Walk")
	b:Rail("EastRangeRailN", 68, 118, -140, -139, 36)
	b:Rail("EastRangeRailS", 68, 118, -91, -90, 36)
	b:Box("S8Headhouse", 68, 82, 36, 50, -140, -126, "Building")
	b:Gable("S8HeadRoof", 68, 82, -140, -126, 50, 6, "Z")
	b:Slab("EastWalk24", 96, 120, -76, -64, 24, 2, "Walk")
	b:Rail("EastWalkRailN", 96, 120, -76, -75, 24)
	b:Rail("EastWalkRailS", 96, 120, -65, -64, 24)
	b:Flight("U2a", 120, 132, -116, -92, 0, 12, "N")
	b:Box("U2Landing12", 120, 144, 0, 12, -134, -116, "Walk")
	b:Box("U2bBase", 132, 144, 0, 12, -116, -92, "Building")
	b:Flight("U2b", 132, 144, -116, -92, 12, 24, "S")
	b:Slab("U2Landing24", 120, 144, -92, -64, 24, 2, "Walk")
	b:Rail("U2Landing24RailE", 143, 144, -92, -64, 24)
	for _, p in { { 121, -65 }, { 143, -65 }, { 121, -91 } } do
		b:Box("U2Pier", p[1] - 1, p[1] + 1, 0, 22, p[2] - 1, p[2] + 1, "Wall")
	end
	b:Flight("U2c", 120, 132, -116, -92, 24, 36, "N", true) -- over U2a: hung, so it keeps 24 clear all the way
	b:Slab("U2Landing36", 118, 132, -134, -116, 36, 2, "Walk")
	b:Rail("U2Landing36RailE", 131, 132, -134, -116, 36)
	b:Rail("U2Landing36RailN", 118, 132, -134, -133, 36)
	b:Rail("U2Landing24RailS", 120, 144, -65, -64, 24)
	-- (no separate east stair down to the bell yard: the probe found it blocking the east vestibule's way out; U2 is
	-- the east return to the street)
end

-- 6 · Crypt (-18), its two stair houses, lights ---------------------------------------------------------------------

function Layout.Crypt(b: any)
	local Kit = require(script.Parent.Kit)
	local voids = {
		L1_WELL,
		{ -144, -130, -95, 2 }, -- west corridor
		{ -130, -94, -40, 0 }, -- lower chamber (F)
		{ -144, 120, -95, -81 }, -- north corridor, under the nave
		{ -62, -26, -108, -68 }, -- crypt chamber (O3)
		{ 106, 120, -95, -40 }, -- east corridor
		L2_WELL,
	}
	b:Slab("CryptFloor", -150, 126, -114, 62, -18, 3, "Crypt")
	for i, r in Kit.Subtract({ -150, 126, -114, 62 }, voids) do
		b:Box(`CryptRock{i}`, r[1], r[2], -18, -2, r[3], r[4], "Crypt")
	end
	-- L1: two 9-rise flights and an 18-stud landing, descending north from the house door
	b:Flight("L1Upper", -144, -130, 38, 56, -9, 0, "S")
	b:Box("L1Landing", -144, -130, -18, -9, 20, 38, "Walk")
	b:Box("L1UpperBase", -144, -130, -18, -9, 38, 56, "Crypt")
	b:Flight("L1Lower", -144, -130, 2, 20, -18, -9, "S")
	b:Room("L1House", -146, -128, -4, 58, 0, 18, 2, "Wall", { S = { { -144, -130, 0, 16 } } })
	b:Box("L1HouseRoof", -146, -128, 18, 20, -4, 58, "Roof")
	-- L2: rising south out of the east corridor
	b:Flight("L2Lower", 106, 120, -40, -22, -18, -9, "S")
	b:Box("L2Landing", 106, 120, -18, -9, -22, -4, "Walk")
	b:Box("L2UpperBase", 106, 120, -18, -9, -4, 14, "Crypt")
	b:Flight("L2Upper", 106, 120, -4, 14, -9, 0, "S")
	b:Room("L2House", 104, 122, -42, 16, 0, 18, 2, "Wall", { S = { { 106, 120, 0, 16 } } })
	b:Box("L2HouseRoof", 104, 122, 18, 20, -42, 16, "Roof")
	-- light: pale spill down each stair mouth, a dim cool fill, one warm memorial niche
	b:Glow("L1Spill", -137, -1, 50, "Spot", SPILL, Enum.NormalId.Bottom)
	b:Glow("L2Spill", 113, -1, 8, "Spot", SPILL, Enum.NormalId.Bottom)
	-- cool pools about every 30 studs, warm sconces where corridors meet, a light in each chamber
	for _, x in { -120, -90, -60, -30, 0, 30, 60, 90 } do
		b:Glow(`CryptFillN{x}`, x, -5, -88, "Point", CRYPT_FILL)
	end
	for _, z in { -20, -60 } do
		b:Glow(`CryptFillW{z}`, -137, -5, z, "Point", CRYPT_FILL)
	end
	b:Glow("CryptFillE", 113, -5, -64, "Point", CRYPT_FILL)
	b:Glow("SconceWest", -131, -9, -88, "Point", SCONCE)
	b:Glow("SconceEast", 113, -9, -82, "Point", SCONCE)
	b:Glow("LowerChamber", -112, -6, -20, "Point", { Color = CRYPT_FILL.Color, Brightness = 1.2, Range = 34 })
	b:Glow("MemorialNiche", -44, -12, -106, "Point", { Color = Color3.fromRGB(255, 150, 80), Brightness = 1, Range = 18 })
end

-- 7 · Street lamps: the route is lit, each descent has a lamp (spec section 9) --------------------------------------

function Layout.Lamps(b: any)
	local lamps = {
		-- arrival avenue and the processional court
		{ -12, 0, 205 }, { 12, 0, 180 }, { -12, 0, 150 }, { 12, 0, 120 },
		{ -46, 0, 22 }, { 46, 0, 22 }, { -46, 0, 90 }, { 46, 0, 90 },
		-- west lane, north lane, east lane, bell yard
		{ -152, 0, 96 }, { -156, 0, -30 }, { -156, 0, -100 }, { -130, 0, -170 },
		{ -60, 0, -196 }, { 60, 0, -196 },
		{ 152, 0, -144 }, { 156, 0, -60 }, { 158, 0, 24 }, { 150, 0, 104 },
		{ 80, 0, 34 }, { 134, 0, 100 },
		-- descents and returns: U1 top, S7, the crossing's ends, G1 and G2 landings, U2 top, the crypt doors
		{ -62, 24, 104 }, { -112, 36, 114 }, { -64, 36, 18 }, { 64, 36, 18 },
		{ -62, 24, -30 }, { 92, 24, -36 }, { 142, 24, -66 }, { 116, 36, -118 },
		{ -134, 0, 64 }, { 124, 0, 20 },
	}
	for i, p in lamps do
		b:Lamp(`Lamp{i}`, p[1], p[2], p[3], WARM)
	end
	-- the two pools at the foot of the front stair cast shadows (the scene's key warm light)
	b:Lamp("StairLampW", -58, 0, -12, WARM_SHADOW)
	b:Lamp("StairLampE", 58, 0, -12, WARM_SHADOW)
end

-- 8 · Gameplay markers: regions (D8), spawns, enemy groups, sites --------------------------------------------------

function Layout.Markers(b: any)
	local REGION_Y1, REGION_Y2 = -48, 148
	for name, boxes in {
		LamplightersReach = { { -240, 240, 94, 240 }, { -50, 50, 14, 94 } },
		Cloister = { { -240, -50, -150, 94 } },
		BellWorks = { { 50, 240, -260, 94 } },
		ChapterClose = { { -240, 50, -260, -150 }, { -50, 50, -150, 14 } },
	} do
		for i, r in boxes do
			b:Volume(`Region{name}{i}`, Tags.Region.Tag, { Region = name }, r[1], r[2], REGION_Y1, REGION_Y2, r[3], r[4])
		end
	end

	for id, s in {
		S1 = { -194, 0, 188, "LamplightersReach" }, S2 = { 184, 0, 178, "LamplightersReach" },
		S7 = { -126, 36, 124, "LamplightersReach" }, S9 = { 64, 0, 231, "LamplightersReach" },
		S10 = { -64, 0, 227, "LamplightersReach" },
		S5 = { -191, 0, 8, "Cloister" }, S11 = { -198, 0, -120, "Cloister" },
		S12 = { -150, 0, -60, "Cloister" }, S13 = { -98, 0, 64, "Cloister" },
		S4 = { 196, 0, -208, "BellWorks" }, S6 = { 192, 0, -14, "BellWorks" },
		S8 = { 100, 36, -128, "BellWorks" }, S14 = { 196, 0, 80, "BellWorks" },
		S3 = { -196, 0, -202, "ChapterClose" }, S16 = { 0, 0, -195, "ChapterClose" },
		S17 = { -126, 0, -224, "ChapterClose" }, S18 = { -40, 0, -4, "ChapterClose" },
	} do
		b:Marker(`Spawn{id}`, Tags.Spawn.Tag, { Region = s[4] }, s[1], s[2], s[3])
	end

	-- authored enemy groups A-E (one marker per enemy, no scatter); F waits for vertical AI (N1) untagged
	for name, g in {
		A = { "Wretch", { { -104, 0, 142 }, { -92, 0, 150 }, { -80, 0, 142 } } },
		B = { "Wretch", { { 104, 0, 88 }, { 120, 0, 88 } } },
		C = { "Butcher", { { 156, 0, -20 } } },
		D = { "Wretch", { { -38, 8, -138 }, { -28, 8, -122 }, { -44, 8, -112 } } },
		E = { "Butcher", { { 32, 8, -114 } } },
		F = { "Wretch", { { -112, -18, -24 }, { -100, -18, -14 } } },
	} do
		for i, p in g[2] do
			local live = name ~= "F"
			local marker = b:Marker(`Group{name}{i}`, if live then Tags.EnemySpawn.Tag else nil, { Enemy = g[1], Count = 1, Radius = 0 }, p[1], p[2], p[3])
			if not live then
				marker:SetAttribute("Reserved", "N1 vertical AI tests")
			end
		end
	end

	-- R1: the ritual court (tagged now; RitualService arrives in R1). R2, O2-O4: reserved places, no tag yet.
	b:Volume("SiteR1", Tags.RitualSite.Tag, { Site = "ProcessionalCourt" }, -32, 32, -2, 60, 16, 80)
	for name, r in {
		SiteR2 = { -32, 32, 8, 40, -156, -92, "BossArena" },
		SiteO2 = { 103, 121, 0, 16, 39, 57, "Forge" },
		SiteO3 = { -53, -35, -18, -2, -100, -82, "Pickup" },
		SiteO4 = { -129, -111, 0, 16, -131, -113, "FlameShrine" },
	} do
		local v = b:Marker(name, nil, { Reserved = r[7] }, (r[1] + r[2]) / 2, r[3], (r[5] + r[6]) / 2, Vector3.new(r[2] - r[1], r[4] - r[3], r[6] - r[5]))
		v.Name = name
	end
	-- O1: the pact circle (live: ShinigamiService gives it its prompt)
	local circle = b:Box("PactCircle", -118, -106, 0, 0.2, 32, 44, "Lamp")
	circle.Shape = Enum.PartType.Cylinder
	circle.Size = Vector3.new(0.2, 12, 12)
	circle.CFrame = CFrame.new(-112, 0.1, 38) * CFrame.Angles(0, 0, math.rad(90))
	circle.Material, circle.Color, circle.CanCollide = Enum.Material.SmoothPlastic, Color3.fromRGB(150, 120, 64), false
	circle:SetAttribute("Shinigami", "Kurogane")
	game:GetService("CollectionService"):AddTag(circle, Tags.PactCircle.Tag)
	b:Glow("PactLight", -112, 6, 38, "Point", PACT)
end

-- 9 · Away from the district: the Antechamber (waiting room) and the final garden -----------------------------------

function Layout.Antechamber(b: any)
	b:Slab("Floor", -40, 40, 570, 630, 0, 2, "Walk")
	b:Room("Walls", -40, 40, 570, 630, 0, 24, 2, "Landmark")
	b:Box("Roof", -40, 40, 24, 26, 570, 630, "Roof")
	b:Box("ReliefTable", -10, 10, 0, 3.5, 594, 606, "Landmark")
	for i, p in { { -30, 580 }, { 30, 580 }, { -30, 620 }, { 30, 620 }, { 0, 600 } } do
		b:Glow(`Candle{i}`, p[1], 8, p[2], "Point", { Color = Color3.fromRGB(255, 150, 80), Brightness = 1.2, Range = 24 })
	end
	b:Volume("Antechamber", Tags.Antechamber.Tag, {}, -38, 38, 0, 24, 572, 628)
end

function Layout.FinalGarden(b: any)
	b:Slab("Ground", -90, 90, -990, -810, 0, 2, "Ground")
	b:Room("Walls", -90, 90, -990, -810, 0, 40, 4, "Boundary")
	b:Slab("PathX", -86, 86, -906, -894, 0.2, 0.2, "Walk")
	b:Slab("PathZ", -6, 6, -986, -814, 0.2, 0.2, "Walk")
	for i, bed in { { -80, -12, -980, -912 }, { 12, 80, -980, -912 }, { -80, -12, -888, -820 }, { 12, 80, -888, -820 } } do
		b:Box(`FlowerBed{i}`, bed[1], bed[2], 0, 1.2, bed[3], bed[4], "Walk")
	end
	b:Volume("FinalArena", Tags.FinalArena.Tag, {}, -86, 86, 0, 60, -986, -814)
	for i, p in { { -60, -900 }, { 60, -900 }, { 0, -960 }, { 0, -840 } } do
		b:Marker(`FinalSpawn{i}`, Tags.FinalSpawn.Tag, {}, p[1], 0.2, p[2])
	end
	for i, p in { { -86, -986 }, { 86, -986 }, { -86, -814 }, { 86, -814 } } do
		b:Glow(`Lamp{i}`, p[1], 12, p[2], "Point", { Color = Color3.fromRGB(190, 200, 232), Brightness = 1, Range = 40 })
	end
end

return Layout

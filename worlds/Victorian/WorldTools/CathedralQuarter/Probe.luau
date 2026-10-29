--!strict
-- Probe (edit time): walks every route of the quarter as geometry, so a gap, a lip, a wall across a path or a low
-- ceiling is found by numbers, not by eye. A route is a polyline of floor points (X, Y = finished floor, Z); heights
-- interpolate linearly along a segment, which is exactly what a flight or ramp does. Every STEP studs:
--   floor: a downward cast (solid parts only) must find a floor within FLOOR_TOLERANCE of the expected height;
--   headroom: an upward cast must find nothing solid below CLEARANCE studs. 14 is the floor: the vestibule doors and
--   the aisles under the +24 gallery are exactly 14 (a gallery 16 above the nave with a 2-stud slab).
-- Run: require(game.ServerStorage.WorldTools.CathedralQuarter.Probe).Run() → a report string.
-- Routes follow worlds/Victorian/CathedralQuarter/w1-blockout.md (ground ring, interior, U1, crossing, U2, crypt).

local Probe = {}

local STEP = 2
local FLOOR_TOLERANCE = 1.1
local CLEARANCE = 13.9

type Route = { Name: string, Points: { { number } } }

Probe.Routes = {
	{ Name = "Ground ring", Points = {
		{ 0, 0, 214 }, { 0, 0, 145 }, { -160, 0, 145 }, { -160, 0, 90 }, { -158, 0, -140 }, { -126, 0, -190 },
		{ 0, 0, -196 }, { 126, 0, -190 }, { 160, 0, -140 }, { 160, 0, 10 }, { 140, 0, 20 }, { 100, 0, 60 },
		{ 0, 0, 60 }, { 0, 0, 145 },
	} },
	{ Name = "Interior west", Points = {
		{ 0, 0, 0 }, { 0, 0, -16 }, { 0, 8, -32 }, { 0, 8, -60 }, { -60, 8, -47 }, { -80, 8, -45 }, { -94, 8, -45 },
		{ -118, 0, -45 }, { -140, 0, -45 },
	} },
	{ Name = "Interior east", Points = {
		{ 0, 8, -60 }, { 60, 8, -50 }, { 80, 8, -53 }, { 96, 8, -53 }, { 120, 0, -53 }, { 140, 0, -53 },
	} },
	{ Name = "U1 to the gallery and G2", Points = {
		{ -150, 0, 100 }, { -144, 0, 100 }, { -120, 12, 100 }, { -102, 12, 100 }, { -78, 24, 100 }, { -70, 24, 96 },
		{ -74, 24, 80 }, { -74, 24, 24 }, { -78, 24, 14 }, { -78, 24, -24 }, { -78, 24, -45 }, { -66, 24, -47 },
		{ -55, 24, -47 }, { -58, 24, -100 }, { -58, 24, -164 }, { 58, 24, -164 }, { 58, 24, -50 }, { 66, 24, -47 },
		{ 80, 24, -47 }, { 82, 24, -70 }, { 126, 24, -70 }, { 126, 24, -92 }, { 126, 36, -116 },
		{ 126, 36, -125 }, { 100, 36, -125 },
	} },
	{ Name = "Crossing", Points = {
		{ -66, 24, -24 }, { -66, 24, -16 }, { -66, 36, 8 }, { -66, 36, 14 }, { 66, 36, 14 }, { 66, 36, 8 },
		{ 66, 24, -16 }, { 66, 24, -26 }, { 72, 24, -36 },
	} },
	{ Name = "West range walk", Points = { { -82, 24, -50 }, { -82, 24, -57 }, { -82, 24, -130 } } },
	{ Name = "U2", Points = {
		{ 126, 0, -80 }, { 126, 0, -92 }, { 126, 12, -116 }, { 126, 12, -125 }, { 138, 12, -125 }, { 138, 12, -116 },
		{ 138, 24, -92 }, { 138, 24, -66 },
	} },
	{ Name = "East vestibule to the bell yard", Points = { { 120, 0, -53 }, { 127, 0, -50 }, { 127, 0, 20 }, { 110, 0, 40 } } },
	{ Name = "S7 roof down", Points = { { -120, 36, 118 }, { -110, 36, 118 }, { -86, 24, 118 }, { -76, 24, 110 }, { -70, 24, 100 } } },
	{ Name = "Crypt", Points = {
		{ -137, 0, 64 }, { -137, 0, 56 }, { -137, -9, 38 }, { -137, -9, 20 }, { -137, -18, 2 }, { -137, -18, -88 },
		{ 113, -18, -88 }, { 113, -18, -40 }, { 113, -9, -22 }, { 113, -9, -4 }, { 113, 0, 14 }, { 113, 0, 22 },
	} },
	{ Name = "Crypt chambers", Points = { { -137, -18, -20 }, { -100, -18, -20 }, { -137, -18, -88 }, { -44, -18, -88 }, { -44, -18, -102 } } },
} :: { Route }

local function params(): RaycastParams
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Include
	local roots = {}
	for _, name in { "CathedralQuarter", "VictorianSites" } do
		local root = workspace:FindFirstChild(name)
		if root then
			table.insert(roots, root)
		end
	end
	p.FilterDescendantsInstances = roots
	p.RespectCanCollide = true -- visual steps, lamp heads and markers don't count
	return p
end

-- Checks one route; returns its failures (deduplicated runs) and how many points were sampled.
function Probe.Check(route: Route): ({ string }, number)
	local p = params()
	local failures: { string } = {}
	local samples = 0
	local lastKind = ""
	for i = 1, #route.Points - 1 do
		local a, b = route.Points[i], route.Points[i + 1]
		local from, to = Vector3.new(a[1], a[2], a[3]), Vector3.new(b[1], b[2], b[3])
		local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z).Magnitude
		local n = math.max(1, math.ceil(flat / STEP))
		for s = 0, n do
			local t = s / n
			local at = from:Lerp(to, t)
			samples += 1
			local down = workspace:Raycast(at + Vector3.new(0, 3, 0), Vector3.new(0, -6, 0), p)
			local kind = ""
			if not down then
				kind = "no floor"
			elseif math.abs(down.Position.Y - at.Y) > FLOOR_TOLERANCE then
				kind = `floor at {string.format("%.1f", down.Position.Y)} ({down.Instance.Name})`
			else
				local up = workspace:Raycast(Vector3.new(at.X, down.Position.Y + 0.2, at.Z), Vector3.new(0, CLEARANCE - 0.2, 0), p)
				if up then
					kind = `headroom {string.format("%.1f", up.Position.Y - down.Position.Y)} ({up.Instance.Name})`
				end
			end
			if kind ~= "" and kind ~= lastKind then
				table.insert(failures, `({math.floor(at.X)}, {math.floor(at.Y)}, {math.floor(at.Z)}): {kind}`)
			end
			lastKind = kind
		end
	end
	return failures, samples
end

function Probe.Run(): string
	local lines = {}
	local total, bad = 0, 0
	for _, route in Probe.Routes do
		local failures, samples = Probe.Check(route)
		total += samples
		bad += #failures
		table.insert(lines, `{if #failures == 0 then "PASS" else "FAIL"}  {route.Name} ({samples} points)`)
		for _, f in failures do
			table.insert(lines, `      {f}`)
		end
	end
	table.insert(lines, 1, `ROUTES {if bad == 0 then "PASSED" else "FAILED"}: {total} points, {bad} problem run(s)`)
	return table.concat(lines, "\n")
end

return Probe

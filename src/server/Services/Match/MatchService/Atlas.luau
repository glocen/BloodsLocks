--!strict
-- Atlas (MatchService): publishes what the match screens need to draw the map, so clients never depend on world
-- markers or parts that may not be streamed in (StreamingEnabled):
--   MatchState.Regions.<zoneId>: DisplayName, the live Chosen / Capacity of the region choice, one "Box" child per
--   BL_Region volume (Min/Max corners) and one "Feature" child per thing the map marks inside it (MatchState.Features:
--   pact circles, ritual sites, enemy groups by tier; Kind, Position, Label, Count);
--   MatchState.Relief: the map seen from above. The world's authored relief when it has one
--   (ServerStorage.WorldAssets.<MapId>MapRelief: a simplified model the art team keeps in step with the city);
--   otherwise a light copy of the visible, anchored geometry inside the region volumes. Never lights, prompts,
--   scripts or tags.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Shared
local Registry = require(Shared.Definitions.Registry)
local MatchState = require(Shared.Match.MatchState)
local WorldTags = require(Shared.World.Tags)
local Markers = require(Shared.World.Markers)
local EntityState = require(Shared.Simulation.EntityState)

local R = MatchState.Region
local F = MatchState.Features

local Atlas = {}

local MIN_SIZE = 1.5 -- smaller parts (trim, steps) add nothing seen from above
local KEEP_CLASSES = { Part = true, WedgePart = true, CornerWedgePart = true, MeshPart = true, UnionOperation = true }
local RELIEF_SUFFIX = "MapRelief" -- ServerStorage.WorldAssets.<MapId>MapRelief
local STRIP = { Script = true, LocalScript = true, ModuleScript = true, PointLight = true, SpotLight = true, SurfaceLight = true, ProximityPrompt = true, Sound = true, ParticleEmitter = true, Beam = true, Trail = true }

local map = Registry.MapForPlace(game.PlaceId)

type Box = { Min: Vector3, Max: Vector3 }

local function inside(boxes: { Box }, position: Vector3): boolean
	for _, box in boxes do
		if position.X >= box.Min.X and position.X <= box.Max.X and position.Y >= box.Min.Y and position.Y <= box.Max.Y
			and position.Z >= box.Min.Z and position.Z <= box.Max.Z then
			return true
		end
	end
	return false
end

-- What each kind of marker shows on the map: its kind, label and count, or nil to leave it off.
local function describe(tag: string, marker: Instance): (string?, string?, number?)
	if tag == WorldTags.PactCircle.Tag then
		local def = Registry.Shinigami(marker:GetAttribute("Shinigami"))
		return F.Pact, if def then def.DisplayName else nil, 1
	elseif tag == WorldTags.RitualSite.Tag then
		return F.Ritual, nil, 1
	elseif tag == WorldTags.EnemySpawn.Tag then
		local def = Registry.Enemy(marker:GetAttribute("Enemy"))
		if not def or def.Tier == "Boss" then
			return nil
		end
		local count = marker:GetAttribute("Count")
		return if def.Tier == "Fodder" then F.Fodder else F.Heavy, def.DisplayName, if type(count) == "number" then count else 1
	end
	return nil
end

local function publishFeatures(region: Instance, boxes: { Box })
	for _, tag in { WorldTags.PactCircle.Tag, WorldTags.RitualSite.Tag, WorldTags.EnemySpawn.Tag } do
		for _, marker in Markers.All(tag) do
			if marker:IsA("BasePart") and inside(boxes, marker.Position) then
				local kind, label, count = describe(tag, marker)
				if kind then
					local feature = Instance.new("Configuration")
					feature.Name = MatchState.FeatureName
					feature:SetAttribute(R.Kind, kind)
					feature:SetAttribute(R.Position, marker.Position)
					feature:SetAttribute(R.Label, label or "")
					feature:SetAttribute(R.Count, count or 1)
					feature.Parent = region
				end
			end
		end
	end
end

local function publishRegions(root: Folder): (Vector3?, Vector3?)
	local folder = Instance.new("Folder")
	folder.Name = MatchState.RegionsName
	local lo: Vector3?, hi: Vector3? = nil, nil
	local boxesOf: { [string]: { Box } } = {}
	for _, volume in Markers.All(WorldTags.Region.Tag) do
		local id = volume:GetAttribute("Region")
		local zone = map and type(id) == "string" and map.Zones[id]
		if zone and volume:IsA("BasePart") then
			local region = folder:FindFirstChild(id :: string) :: Configuration?
			if not region then
				local created = Instance.new("Configuration")
				created.Name = id :: string
				created:SetAttribute(R.DisplayName, zone.DisplayName)
				created:SetAttribute(R.Chosen, 0)
				created:SetAttribute(R.Capacity, 0)
				created.Parent = folder
				region = created
			end
			local half = volume.Size / 2
			local box = Instance.new("Configuration")
			box.Name = MatchState.BoxName
			box:SetAttribute(R.Min, volume.Position - half)
			box:SetAttribute(R.Max, volume.Position + half)
			box.Parent = region
			boxesOf[id :: string] = boxesOf[id :: string] or {}
			table.insert(boxesOf[id :: string], { Min = volume.Position - half, Max = volume.Position + half })
			lo = if lo then lo:Min(volume.Position - half) else volume.Position - half
			hi = if hi then hi:Max(volume.Position + half) else volume.Position + half
		end
	end
	for id, boxes in boxesOf do
		publishFeatures(folder:FindFirstChild(id) :: Instance, boxes)
	end
	folder.Parent = root
	return lo, hi
end

-- Empties a relief copy of everything but its shapes: no behaviour, light, sound or tags travel to clients.
local function clean(model: Instance)
	for _, child in model:GetDescendants() do
		if STRIP[child.ClassName] then
			child:Destroy()
		elseif child:IsA("BasePart") then
			child.Anchored = true
			child.CanCollide, child.CanQuery, child.CanTouch, child.CastShadow = false, false, false, false
			for _, tag in CollectionService:GetTags(child) do
				CollectionService:RemoveTag(child, tag)
			end
		end
	end
end

local function publishRelief(root: Folder, lo: Vector3, hi: Vector3)
	local assets = ServerStorage:FindFirstChild("WorldAssets")
	local authored = map and assets and assets:FindFirstChild(map.Id .. RELIEF_SUFFIX)
	local relief: Model
	if authored then
		relief = Instance.new("Model")
		for _, child in authored:GetChildren() do
			child:Clone().Parent = relief
		end
	else
		relief = Instance.new("Model")
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local skip: { Instance } = {}
		for _, entity in CollectionService:GetTagged(EntityState.Tag) do
			table.insert(skip, entity)
		end
		params.FilterDescendantsInstances = skip
		local center, size = (lo + hi) / 2, hi - lo
		for _, part in workspace:GetPartBoundsInBox(CFrame.new(center), size, params) do
			local big = part.Size.X >= MIN_SIZE or part.Size.Z >= MIN_SIZE
			if KEEP_CLASSES[part.ClassName] and part.Anchored and part.Transparency < 1 and big then
				local copy = part:Clone()
				for _, child in copy:GetChildren() do
					child:Destroy()
				end
				copy.Parent = relief
			end
		end
	end
	clean(relief)
	relief.Name = MatchState.ReliefName
	relief.Parent = root
end

-- Publishes the regions and the relief under the MatchState folder (once, at boot).
function Atlas.Publish(root: Folder)
	local lo, hi = publishRegions(root)
	if lo and hi then
		publishRelief(root, lo, hi)
	end
end

-- The live region choice: how many entrants asked for each region, and how many each takes.
function Atlas.SetChoices(root: Folder, choices: { [number]: string }, capacity: number)
	local folder = root:FindFirstChild(MatchState.RegionsName)
	if not folder then
		return
	end
	local counts: { [string]: number } = {}
	for _, region in choices do
		counts[region] = (counts[region] or 0) + 1
	end
	for _, region in folder:GetChildren() do
		region:SetAttribute(R.Chosen, counts[region.Name] or 0)
		region:SetAttribute(R.Capacity, capacity)
	end
end

return Atlas

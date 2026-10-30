--!strict
-- Atlas (MatchService): publishes what the match screens need to draw the map, so clients never depend on world
-- markers or parts that may not be streamed in (StreamingEnabled):
--   MatchState.Regions.<zoneId>: DisplayName, plus one child per BL_Region volume with Min/Max corners;
--   MatchState.Relief: a light copy of the district's visible, anchored geometry inside the region volumes (no
--   lights, prompts or scripts), which the region map shows from above. It always matches the built world.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Registry = require(Shared.Definitions.Registry)
local MatchState = require(Shared.Match.MatchState)
local WorldTags = require(Shared.World.Tags)
local Markers = require(Shared.World.Markers)
local EntityState = require(Shared.Simulation.EntityState)

local R = MatchState.Region

local Atlas = {}

local MIN_SIZE = 1.5 -- smaller parts (trim, steps) add nothing seen from above
local KEEP_CLASSES = { Part = true, WedgePart = true, CornerWedgePart = true, MeshPart = true, UnionOperation = true }

local function publishRegions(root: Folder): (Vector3?, Vector3?)
	local map = Registry.MapForPlace(game.PlaceId)
	local folder = Instance.new("Folder")
	folder.Name = MatchState.RegionsName
	local lo: Vector3?, hi: Vector3? = nil, nil
	for _, volume in Markers.All(WorldTags.Region.Tag) do
		local id = volume:GetAttribute("Region")
		local zone = map and type(id) == "string" and map.Zones[id]
		if zone and volume:IsA("BasePart") then
			local region = folder:FindFirstChild(id :: string) :: Configuration?
			if not region then
				local created = Instance.new("Configuration")
				created.Name = id :: string
				created:SetAttribute(R.DisplayName, zone.DisplayName)
				created.Parent = folder
				region = created
			end
			local half = volume.Size / 2
			local box = Instance.new("Configuration")
			box.Name = "Box"
			box:SetAttribute(R.Min, volume.Position - half)
			box:SetAttribute(R.Max, volume.Position + half)
			box.Parent = region
			lo = if lo then lo:Min(volume.Position - half) else volume.Position - half
			hi = if hi then hi:Max(volume.Position + half) else volume.Position + half
		end
	end
	folder.Parent = root
	return lo, hi
end

local function publishRelief(root: Folder, lo: Vector3, hi: Vector3)
	local relief = Instance.new("Model")
	relief.Name = MatchState.ReliefName
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
			for _, tag in CollectionService:GetTags(copy) do
				CollectionService:RemoveTag(copy, tag)
			end
			copy.CanCollide, copy.CanQuery, copy.CanTouch, copy.CastShadow = false, false, false, false
			copy.Parent = relief
		end
	end
	relief.Parent = root
end

-- Publishes the regions and the relief under the MatchState folder (once, at boot).
function Atlas.Publish(root: Folder)
	local lo, hi = publishRegions(root)
	if lo and hi then
		publishRelief(root, lo, hi)
	end
end

return Atlas

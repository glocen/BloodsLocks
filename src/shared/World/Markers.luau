--!strict
-- Markers: the live world markers for a contract tag (Shared.World.Tags). Only tagged instances inside workspace are
-- live: masters and backups kept in ServerStorage or ReplicatedStorage can carry the same tags and must never spawn
-- enemies, open combat zones or offer prompts (W1 found the Victorian place's backed-up test markers spawning enemies).

local CollectionService = game:GetService("CollectionService")

local Markers = {}

function Markers.IsLive(instance: Instance): boolean
	return instance:IsDescendantOf(workspace)
end

-- Every live instance with `tag`.
function Markers.All(tag: string): { Instance }
	local live = {}
	for _, instance in CollectionService:GetTagged(tag) do
		if Markers.IsLive(instance) then
			table.insert(live, instance)
		end
	end
	return live
end

-- Calls `handler` for every live instance with `tag`, now and as they're added.
function Markers.Each(tag: string, handler: (Instance) -> ())
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
		if Markers.IsLive(instance) then
			handler(instance)
		end
	end)
	for _, instance in Markers.All(tag) do
		handler(instance)
	end
end

return Markers

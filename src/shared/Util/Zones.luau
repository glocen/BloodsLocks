--!strict
-- Zones: where combat is allowed. In a match place everywhere is a combat zone. In the Manor hub only the
-- training yard is: parts tagged BL_CombatZone (invisible boxes) mark it, and outside them nobody can attack, use
-- skills or be hurt, and the combat HUD hides. Static geometry, so the check is the same on client and server.

local CollectionService = game:GetService("CollectionService")

local PlaceRole = require(script.Parent.PlaceRole)
local WorldTags = require(script.Parent.Parent.World.Tags)
local Markers = require(script.Parent.Parent.World.Markers)

local TAG = WorldTags.CombatZone.Tag

local Zones = {}

local function inside(part: BasePart, position: Vector3): boolean
	local localPos = part.CFrame:PointToObjectSpace(position)
	local half = part.Size / 2
	return math.abs(localPos.X) <= half.X and math.abs(localPos.Y) <= half.Y and math.abs(localPos.Z) <= half.Z
end

function Zones.CombatAllowed(position: Vector3): boolean
	if not PlaceRole.IsManor then
		return true
	end
	for _, zone in CollectionService:GetTagged(TAG) do
		if zone:IsA("BasePart") and Markers.IsLive(zone) and inside(zone, position) then
			return true
		end
	end
	return false
end

-- For a model: its root part's position (false if it has none).
function Zones.ModelInCombat(model: Model): boolean
	local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root ~= nil and Zones.CombatAllowed(root.Position)
end

Zones.Tag = TAG

return Zones

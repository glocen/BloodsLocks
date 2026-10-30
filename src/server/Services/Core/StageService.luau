--!strict
-- StageService: turns a hunter to face a direction when a full-screen menu puts them on stage (UI.Core.Stage; the Blood
-- Table turns them away from the table, so it stands behind them). Rotation only, on the spot, and only where nobody
-- fights: the Manor outside its combat zone, or a match that hasn't begun (Idle, Waiting, Countdown). When a BL_Stage
-- marker is within reach, the hunter steps onto it instead, facing the marker's way (world builders place those).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local PlaceRole = require(Shared.Util.PlaceRole)
local Zones = require(Shared.Util.Zones)
local Parts = require(Shared.Util.Parts)
local MatchState = require(Shared.Match.MatchState)
local MatchConfig = require(Shared.Config.Match)
local WorldTags = require(Shared.World.Tags)
local Markers = require(Shared.World.Markers)

local MARK_REACH = 20 -- studs: a BL_Stage marker this close takes the hunter onto it
local S = MatchState.States
local CALM: { [string]: boolean } = { [S.Idle] = true, [S.Waiting] = true, [S.Countdown] = true }

local StageService = {}

local function calm(character: Model): boolean
	if PlaceRole.IsMatch then
		local root = ReplicatedStorage:FindFirstChild(MatchState.FolderName)
		local state = root and root:GetAttribute(MatchState.Match.State)
		return state == nil or CALM[state] == true
	end
	return not Zones.ModelInCombat(character)
end

local function flat(direction: Vector3): Vector3?
	local v = Vector3.new(direction.X, 0, direction.Z)
	local length = v.Magnitude
	return if length > 0.5 and length < 1e6 then v / length else nil -- also refuses NaN
end

-- Where the hunter should stand and face: on a nearby BL_Stage marker, or where they are, turned to `facing`.
local function placement(root: BasePart, facing: Vector3): CFrame
	for _, mark in Markers.All(WorldTags.Stage.Tag) do
		if mark:IsA("BasePart") and (mark.Position - root.Position).Magnitude <= MARK_REACH then
			local at = Vector3.new(mark.Position.X, mark.Position.Y - mark.Size.Y / 2 + MatchConfig.SpawnHeight, mark.Position.Z)
			return CFrame.lookAt(at, at + (flat(mark.CFrame.LookVector) or facing))
		end
	end
	return CFrame.lookAt(root.Position, root.Position + facing)
end

function StageService.Start()
	Net.Server.On("TakeStage", function(player: Player, facing: any)
		local character = player.Character
		local root = Parts.Root(character)
		local direction = typeof(facing) == "Vector3" and flat(facing)
		if not character or not root or not direction or not calm(character) then
			return
		end
		root.AssemblyLinearVelocity = Vector3.zero
		character:PivotTo(placement(root, direction))
	end)
end

return StageService

--!strict
-- Spawning (MatchService): where bodies appear. Reads the world contract (live markers only):
--   regions: BL_Region volumes whose Region is a zone of this place's map; spawn points: BL_Spawn markers by Region;
--   the Antechamber (BL_Antechamber) for the waiting room; BL_FinalSpawn for the final.
-- A spawn keeps its distance from other living entrants (rule Revival.Separation) and from live enemies when it can.
-- Players get their character loaded and placed by the server (Server Authority: client CFrame writes are
-- overridden); AI hunters get a body (a combat entity fighting for their participant id) watched by EntityService.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local MatchConfig = require(Shared.Config.Match)
local MatchState = require(Shared.Match.MatchState)
local Registry = require(Shared.Definitions.Registry)
local EntityState = require(Shared.Simulation.EntityState)
local WorldTags = require(Shared.World.Tags)
local Markers = require(Shared.World.Markers)
local Sightline = require(Shared.World.Sightline)
local Parts = require(Shared.Util.Parts)
local Core = script.Parent.Parent.Parent.Core
local EntityService = require(Core.EntityService)
local NpcService = require(Core.NpcService)

local A = EntityState.Attr

local Spawning = {}

local HUNTER_FOLDER = MatchState.HuntersFolder
local HUNTER_TINT = Color3.fromRGB(70, 64, 86) -- placeholder look until AI hunters get real bodies
local ENEMY_CLEARANCE = 30 -- studs a spawn prefers to keep from a live enemy

local map = Registry.MapForPlace(game.PlaceId)
local random = Random.new()

-- Zone ids that have a region volume in this place, sorted.
function Spawning.Regions(): { string }
	local seen, list = {}, {}
	for _, volume in Markers.All(WorldTags.Region.Tag) do
		local id = volume:GetAttribute("Region")
		if type(id) == "string" and map and map.Zones[id] and not seen[id] then
			seen[id] = true
			table.insert(list, id)
		end
	end
	table.sort(list)
	return list
end

local function markersFor(tag: string, region: string?): { BasePart }
	local list = {}
	for _, marker in Markers.All(tag) do
		if marker:IsA("BasePart") and (region == nil or marker:GetAttribute("Region") == region) then
			table.insert(list, marker)
		end
	end
	return list
end

local function enemyNear(position: Vector3): boolean
	local folder = workspace:FindFirstChild(NpcService.FolderName)
	for _, enemy in if folder then folder:GetChildren() else {} do
		local root = enemy:IsA("Model") and Parts.Root(enemy)
		if root and (root.Position - position).Magnitude < ENEMY_CLEARANCE then
			return true
		end
	end
	return false
end

-- The way each spawn marker opens up (Sightline), worked out once: markers don't move.
local facings: { [BasePart]: Vector3 } = {}
local function facingOf(marker: BasePart): Vector3
	local facing = facings[marker]
	if not facing then
		local floor = marker.Position - Vector3.new(0, marker.Size.Y / 2, 0)
		facing = Sightline.Best(floor, { marker })
		facings[marker] = facing
	end
	return facing :: Vector3
end

-- The best marker: the farthest from `others` (good once past `separation`), avoiding live enemies. The body faces
-- the marker's most open direction, so nobody arrives staring at a wall.
local function pick(markers: { BasePart }, others: { Vector3 }, separation: number): CFrame?
	local best, bestScore = nil, -math.huge
	for _, marker in markers do
		local nearest = math.huge
		for _, other in others do
			nearest = math.min(nearest, (other - marker.Position).Magnitude)
		end
		local score = math.min(nearest, separation * 2) + (if enemyNear(marker.Position) then -1000 else 0) + random:NextNumber(0, 1)
		if score > bestScore then
			best, bestScore = marker, score
		end
	end
	if not best then
		return nil
	end
	local floor = best.Position.Y - best.Size.Y / 2
	local at = Vector3.new(best.Position.X, floor + MatchConfig.SpawnHeight, best.Position.Z)
	return CFrame.lookAt(at, at + facingOf(best))
end

function Spawning.InRegion(region: string, others: { Vector3 }, separation: number): CFrame?
	return pick(markersFor(WorldTags.Spawn.Tag, region), others, separation)
end

function Spawning.InFinal(others: { Vector3 }, separation: number): CFrame?
	return pick(markersFor(WorldTags.FinalSpawn.Tag, nil), others, separation)
end

local function inside(volume: BasePart, position: Vector3): boolean
	local offset = volume.CFrame:PointToObjectSpace(position)
	local half = volume.Size / 2
	return math.abs(offset.X) <= half.X and math.abs(offset.Y) <= half.Y and math.abs(offset.Z) <= half.Z
end

-- The region whose volume holds `position` (nil outside every region).
function Spawning.RegionAt(position: Vector3): string?
	for _, volume in Markers.All(WorldTags.Region.Tag) do
		local id = volume:GetAttribute("Region")
		if volume:IsA("BasePart") and type(id) == "string" and inside(volume, position) then
			return id
		end
	end
	return nil
end

local STAGE_SPACING = 8 -- studs between hunters lined up at the Antechamber's stage marker

-- Whether the Antechamber's art is finished (its volume carries Dressed = true): players may then step out of the
-- Antechamber screen into the room.
function Spawning.AntechamberDressed(): boolean
	local room = markersFor(WorldTags.Antechamber.Tag, nil)[1]
	return room ~= nil and room:GetAttribute("Dressed") == true
end

-- A place in the Antechamber, spread a little per arrival. With a BL_Stage marker in the room, arrivals line up beside
-- it facing its way (the Antechamber screen frames each hunter there); otherwise a grid in the near half of the room,
-- facing across it, so the screen's camera (in front of the hunter) has the room's depth instead of the near wall.
function Spawning.InAntechamber(index: number): CFrame?
	local room = markersFor(WorldTags.Antechamber.Tag, nil)[1]
	if not room then
		return nil
	end
	for _, mark in markersFor(WorldTags.Stage.Tag, nil) do
		if inside(room, mark.Position) then
			local look = Vector3.new(mark.CFrame.LookVector.X, 0, mark.CFrame.LookVector.Z).Unit
			local right = look:Cross(Vector3.yAxis)
			local side = if index % 2 == 0 then 1 else -1
			local at = Vector3.new(mark.Position.X, mark.Position.Y - mark.Size.Y / 2 + MatchConfig.SpawnHeight, mark.Position.Z)
				+ right * (math.floor(index / 2) * STAGE_SPACING * side)
			return CFrame.lookAt(at, at + look)
		end
	end
	local column, row = (index - 1) % 4, math.floor((index - 1) / 4)
	local at = (room.CFrame * CFrame.new((column - 1.5) * 8, MatchConfig.SpawnHeight - room.Size.Y / 2, (row - 0.5) * 8 - room.Size.Z / 4)).Position
	return CFrame.lookAt(at, at - room.CFrame.LookVector) -- the grid is on the room's look side: face back across it
end

-- Puts a player's body at `cframe`: moves a living character, or loads a new one there.
function Spawning.PlacePlayer(player: Player, cframe: CFrame)
	local character = player.Character
	local root = Parts.Root(character)
	if character and root and EntityState.Number(character, A.HP, 1) > 0 and (Parts.Humanoid(character) :: Humanoid).Health > 0 then
		root.AssemblyLinearVelocity = Vector3.zero
		character:PivotTo(cframe)
		return
	end
	local connection
	connection = player.CharacterAdded:Connect(function(newCharacter)
		connection:Disconnect()
		newCharacter:WaitForChild("HumanoidRootPart", 5)
		newCharacter:PivotTo(cframe)
	end)
	task.spawn(function()
		if player.Parent == Players then
			player:LoadCharacter()
		end
	end)
end

function Spawning.RemovePlayerBody(player: Player)
	local character = player.Character
	if character then
		character:Destroy()
	end
end

local function hunterFolder(): Folder
	local folder = workspace:FindFirstChild(HUNTER_FOLDER) :: Folder?
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = HUNTER_FOLDER
		folder.Parent = workspace
	end
	return folder :: Folder
end

-- An AI hunter's body for participant `id` (negative), standing at `cframe`. No judgement yet: it stands its ground.
function Spawning.MakeHunter(id: number, name: string, classId: string, cframe: CFrame, hpBonus: number): Model?
	local template = Shared.Assets:FindFirstChild("TrainingDummy") :: Model?
	if not template then
		return nil
	end
	local class = Registry.Class(classId)
	local model = EntityService.MakeEntity(template, name, cframe, math.floor(class.BaseHealth * (1 + hpBonus)), hunterFolder(), HUNTER_TINT)
	model:SetAttribute(A.OwnerId, id)
	model:SetAttribute(A.ClassId, class.Id)
	EntityService.Watch(model)
	return model
end

-- The body of AI hunter `id`, if it has one.
function Spawning.HunterBody(id: number): Model?
	for _, model in hunterFolder():GetChildren() do
		if model:IsA("Model") and model:GetAttribute(A.OwnerId) == id then
			return model
		end
	end
	return nil
end

function Spawning.RemoveHunter(id: number)
	local body = Spawning.HunterBody(id)
	if body then
		body:Destroy()
	end
end

-- Where a participant's body stands now (nil without a living body).
function Spawning.BodyPosition(id: number): Vector3?
	local body: Model? = if id < 0 then Spawning.HunterBody(id) else (Players:GetPlayerByUserId(id) and (Players:GetPlayerByUserId(id) :: Player).Character)
	local root = Parts.Root(body)
	return if root and body and EntityState.Number(body, A.HP, 0) > 0 then root.Position else nil
end

-- The participant id a combat entity belongs to as a body (a player's character or an AI hunter's body), or nil.
function Spawning.ParticipantOf(model: Model): number?
	local player = Players:GetPlayerFromCharacter(model)
	if player then
		return player.UserId
	end
	if model.Parent and model.Parent.Name == HUNTER_FOLDER then
		local owner = model:GetAttribute(A.OwnerId)
		return if type(owner) == "number" then owner else nil
	end
	return nil
end

return Spawning

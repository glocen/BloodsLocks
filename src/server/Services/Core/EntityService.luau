--!strict
-- EntityService: makes every player character a combat entity (the tag hit detection and feedback look for)
-- and turns 0 HP into a real death, since Humanoid.Health isn't simulation state.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Parts = require(Shared.Util.Parts)
local EntityState = require(Shared.Simulation.EntityState)

local EntityService = {}

local function watch(player: Player)
	local function tag(character: Model)
		CollectionService:AddTag(character, EntityState.Tag)
	end
	player.CharacterAdded:Connect(tag)
	if player.Character then
		tag(player.Character)
	end
end

function EntityService.Start()
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	RunService.Heartbeat:Connect(function()
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local humanoid = Parts.Humanoid(character)
			if character and humanoid and humanoid.Health > 0 and EntityState.Number(character, EntityState.Attr.HP, 1) <= 0 then
				humanoid.Health = 0
			end
		end
	end)
end

return EntityService

--!strict
-- InputService: gives every player the gameplay InputContext (template: ServerStorage.BLInput).
-- Server Authority needs InputContexts under the Player so client and server read the same input.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local EntityState = require(ReplicatedStorage.Shared.Simulation.EntityState)

local InputService = {}

function InputService.Start()
	local template = ServerStorage:WaitForChild("BLInput"):WaitForChild(EntityState.InputContextName)
	local function give(player: Player)
		if not player:FindFirstChild(template.Name) then
			template:Clone().Parent = player
		end
	end
	Players.PlayerAdded:Connect(give)
	for _, player in Players:GetPlayers() do
		give(player)
	end
end

return InputService

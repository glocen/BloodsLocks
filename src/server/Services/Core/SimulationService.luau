--!strict
-- SimulationService: runs the shared simulation (movement, actions, damage) on the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Runner = require(ReplicatedStorage.Shared.Simulation.Runner)

local SimulationService = {}

function SimulationService.Init()
	Runner.Initialize()
end

return SimulationService

--!strict
-- SimulationController: runs the shared simulation for the local character (client prediction).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Runner = require(ReplicatedStorage.Shared.Simulation.Runner)

local SimulationController = {}

function SimulationController.Init()
	Runner.Initialize()
end

return SimulationController

--!strict
-- ShinigamiController: the summon / dismiss key (the "Summon" input action, T) asks the server to toggle your
-- Shinigami. Pacts are made at circles in the world (ProximityPrompt, handled on the server).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local ShinigamiController = {}

function ShinigamiController.Start()
	local context = Players.LocalPlayer:WaitForChild("BLGameplay")
	local summon = context:WaitForChild("Summon") :: InputAction
	summon.Pressed:Connect(function()
		Net.Client.Fire("ShinigamiToggle")
	end)
end

return ShinigamiController

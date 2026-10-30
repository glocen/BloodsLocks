--!strict
-- The only client entry script. Everything else is a ModuleScript under Controllers.
-- When every controller has started and you have a body (or after CHARACTER_WAIT without one), it releases the
-- loading screen's "Boot" hold (ReplicatedFirst.BL_First.Passage); screens that need longer hold it themselves.

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Loader = require(Shared:WaitForChild("Util"):WaitForChild("Loader"))
local PlaceRole = require(Shared:WaitForChild("Util"):WaitForChild("PlaceRole"))
local Passage = require(ReplicatedFirst:WaitForChild("BL_First"):WaitForChild("Passage"))

local CHARACTER_WAIT = 10 -- seconds

local role = PlaceRole.Current
local controllers = script.Parent:WaitForChild("Controllers")
local _, bootErrors = Loader.Boot(`Client/{role}`, { controllers:FindFirstChild("Core"), controllers:FindFirstChild(role) })
Net.Client.Fire("ClientReady", bootErrors)

local player = Players.LocalPlayer
local deadline = os.clock() + CHARACTER_WAIT
while not player.Character and os.clock() < deadline do
	task.wait(0.1)
end
Passage.Release("Boot")

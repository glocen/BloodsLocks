--!strict
-- The only client entry script. Everything else is a ModuleScript under Controllers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Loader = require(Shared:WaitForChild("Util"):WaitForChild("Loader"))
local PlaceRole = require(Shared:WaitForChild("Util"):WaitForChild("PlaceRole"))

local role = PlaceRole.Current
local controllers = script.Parent:WaitForChild("Controllers")
local _, bootErrors = Loader.Boot(`Client/{role}`, { controllers:FindFirstChild("Core"), controllers:FindFirstChild(role) })
Net.Client.Fire("ClientReady", bootErrors)

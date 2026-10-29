--!strict
-- The only client entry script. Everything else is a ModuleScript under Controllers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Loader = require(Shared:WaitForChild("Util"):WaitForChild("Loader"))
local GameConfig = require(Shared:WaitForChild("Config"):WaitForChild("Game"))

local role = workspace:GetAttribute("PlaceRole") or GameConfig.DefaultPlaceRole
local controllers = script.Parent:WaitForChild("Controllers")
local _, bootErrors = Loader.Boot(`Client/{role}`, { controllers:FindFirstChild("Core"), controllers:FindFirstChild(role) })
Net.Client.Fire("ClientReady", bootErrors)

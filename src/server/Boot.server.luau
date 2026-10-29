--!strict
-- The only server entry script. Everything else is a ModuleScript under Services.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Loader = require(Shared.Util.Loader)
local GameConfig = require(Shared.Config.Game)

Net.Server.Setup()

local role = workspace:GetAttribute("PlaceRole") or GameConfig.DefaultPlaceRole
local services = script.Parent:WaitForChild("Services")
Loader.Boot(`Server/{role}`, { services:FindFirstChild("Core"), services:FindFirstChild(role) })

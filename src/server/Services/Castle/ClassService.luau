--!strict
-- ClassService: class choice at the Blood Table (Bloodsworn tab). Validates the pick and saves it through the
-- owner's data layer (PlayerHandlerData.SetSelectedClass). Mirrors the choice on the Player as attribute "class"
-- so the menu can show it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage.Shared
local Registry = require(Shared.Definitions.Registry)
local Net = require(Shared.Net)
local PlayerHandlerData = require(ServerScriptService.Data.PlayerHandlerData)
local DataService = require(script.Parent.Parent.Core.DataService)

local ClassService = {}

function ClassService.Start()
	DataService.ProfileReady:Connect(function(player: Player, data: any)
		player:SetAttribute("class", Registry.Class(data.SelectedClass).Id)
	end)
	Net.Server.On("SelectClass", function(player: Player, classId: any)
		if type(classId) ~= "string" then
			return
		end
		local class = Registry.Class(classId)
		if class.Id ~= classId then
			return -- unknown id (Registry falls back to the default class)
		end
		PlayerHandlerData.SetSelectedClass(player, classId)
		player:SetAttribute("class", classId)
	end)
end

return ClassService

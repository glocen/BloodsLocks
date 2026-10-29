--!strict
-- ClassService: which class each player plays. In every place it mirrors the profile's SelectedClass onto the Player
-- (PlayerState.Class), which Spawn reads to set up the character. Choosing a class happens only in the Manor
-- (locked decision 12): the Blood Table's Bloodsworn tab fires SelectClass, which is validated and saved through the
-- owner's data layer (PlayerHandlerData.SetSelectedClass).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage.Shared
local Registry = require(Shared.Definitions.Registry)
local Net = require(Shared.Net)
local PlaceRole = require(Shared.Util.PlaceRole)
local PlayerState = require(Shared.Simulation.PlayerState)
local PlayerHandlerData = require(ServerScriptService.Data.PlayerHandlerData)
local DataService = require(script.Parent.DataService)

local ClassService = {}

function ClassService.Start()
	DataService.ProfileReady:Connect(function(player: Player, data: any)
		player:SetAttribute(PlayerState.Attr.Class, Registry.Class(data.SelectedClass).Id)
	end)
	if not PlaceRole.IsManor then
		return
	end
	Net.Server.On("SelectClass", function(player: Player, classId: any)
		if type(classId) ~= "string" then
			return
		end
		local class = Registry.Class(classId)
		if class.Id ~= classId then
			return -- unknown id (Registry falls back to the default class)
		end
		PlayerHandlerData.SetSelectedClass(player, classId)
		player:SetAttribute(PlayerState.Attr.Class, classId)
	end)
end

return ClassService

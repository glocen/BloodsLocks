--!strict
-- PlayerService: player lifecycle shared by every place.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Log = require(Shared.Util.Log)

local PlayerService = {}

function PlayerService.Init()
	-- Each client fires this once, after its controllers boot, with its boot error count.
	Net.Server.On("ClientReady", function(player: Player, bootErrors: any)
		if player:GetAttribute("ClientReady") then
			return
		end
		player:SetAttribute("ClientReady", true)
		if type(bootErrors) ~= "number" then
			Log.Warn("PlayerService", `{player.Name} client ready, but sent an invalid boot report`)
		elseif bootErrors > 0 then
			Log.Warn("PlayerService", `{player.Name} client ready with {bootErrors} boot errors`)
		else
			Log.Info("PlayerService", `{player.Name} client ready`)
		end
	end)
end

return PlayerService

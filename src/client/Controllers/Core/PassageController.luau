--!strict
-- PassageController: the Passage when you leave a place. Roblox needs the teleport picture before the teleport starts,
-- so the default destination is handed over at boot (match places: the Manor), the Hunt tab hands over the chosen
-- map when you seek a hunt, and the server's Travelling(destination) refreshes it. Travelling also puts the live
-- Passage up and holds it ("Teleport") until you're gone; a failed teleport (HuntStatus done) lifts it again.

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local PlaceRole = require(Shared.Util.PlaceRole)
local GameConfig = require(Shared.Config.Game)
local Passage = require(ReplicatedFirst:WaitForChild("BL_First"):WaitForChild("Passage"))

local HOLD = "Teleport"

local PassageController = {}

function PassageController.Start()
	if PlaceRole.IsMatch then
		Passage.PrepareTeleport({ Caption = Passage.Captions.Return, Destination = GameConfig.HubName })
	end
	Net.Client.On("Travelling", function(destination: string)
		local view = {
			Caption = if PlaceRole.IsMatch then Passage.Captions.Return else Passage.Captions.Depart,
			Destination = destination,
		}
		Passage.PrepareTeleport(view)
		Passage.Hold(HOLD)
		Passage.Show(view)
	end)
	Net.Client.On("HuntStatus", function(_message: string, done: boolean?)
		if done then
			Passage.Release(HOLD)
		end
	end)
end

return PassageController

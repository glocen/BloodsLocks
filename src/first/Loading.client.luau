--!strict
-- Loading (ReplicatedFirst.BL_First): the first thing a client runs. It swaps Roblox's loading screen for the Passage
-- (carrying on from the teleport picture when we arrived by one), fills its line while our UI images preload and the
-- game loads, names the place and rotates tips once the game's data has arrived. The Passage stays up until the
-- client Boot releases "Boot" (and any screen that still holds it, like the match screens, lets go).

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Passage = require(script.Parent.Passage)
local ThemeBase = require(script.Parent.ThemeBase)

local TIP_EVERY = 6 -- seconds per tip
local IMAGES_SHARE = 0.6 -- of the line, for the image preload; the rest fills when the game has loaded

Passage.Hold("Load")
Passage.Hold("Boot")
local arriving = Passage.ArrivingView()
Passage.Show(arriving or {})
ReplicatedFirst:RemoveDefaultLoadingScreen()

task.spawn(function()
	local ids = {}
	for _, id in ThemeBase.Images do
		table.insert(ids, id)
	end
	local done = 0
	ContentProvider:PreloadAsync(ids, function()
		done += 1
		Passage.Update({ Progress = done / #ids * IMAGES_SHARE })
	end)
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end
	Passage.Update({ Progress = 1 })
	Passage.Release("Load")
end)

task.spawn(function()
	local Shared = ReplicatedStorage:WaitForChild("Shared")
	local PlaceRole = require(Shared:WaitForChild("Util"):WaitForChild("PlaceRole"))
	local Registry = require(Shared:WaitForChild("Definitions"):WaitForChild("Registry"))
	local GameConfig = require(Shared.Config.Game)
	local Tips = require(Shared.Definitions.Tips)
	if not (arriving and arriving.Destination) then
		local map = PlaceRole.IsMatch and Registry.MapForPlace(game.PlaceId)
		Passage.Update(if map
			then { Caption = Passage.Captions.Gather, Destination = map.DisplayName }
			else { Caption = Passage.Captions.Enter, Destination = GameConfig.HubName })
	end
	local tips = Tips.For(PlaceRole.Current)
	local index = math.random(#tips)
	while Passage.IsShown() do
		Passage.Update({ Tip = tips[index] })
		index = index % #tips + 1
		task.wait(TIP_EVERY)
	end
end)

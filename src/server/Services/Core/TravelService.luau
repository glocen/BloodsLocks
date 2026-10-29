--!strict
-- TravelService: moves players between the experience's places.
--   Manor: SeekHunt(mapId, ruleId) teleports the player to that map's place. For now it joins Roblox's public servers
--   of the place (they fill up to the place's max players, so friends who seek together land together); the
--   reserved-server registry with a waiting room (engineering-plan sections 3 and 6) replaces this with the match flow.
--   Match places: ReturnToManor sends the player back to the Manor.
-- Results and failures go back to the player's menu as HuntStatus(message, done). TeleportService doesn't work in
-- Studio; test travel in the published game.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local GameConfig = require(Shared.Config.Game)
local Registry = require(Shared.Definitions.Registry)
local Net = require(Shared.Net)
local PlaceRole = require(Shared.Util.PlaceRole)
local Log = require(Shared.Util.Log)

local RULES = { Standard = true, Solo = true, Bound = true }

local TravelService = {}

local travelling: { [Player]: boolean } = {}

local function status(player: Player, message: string, done: boolean?)
	Net.Server.Fire("HuntStatus", player, message, done)
end

local function send(player: Player, placeId: number, data: { [string]: any }, arriving: string)
	if travelling[player] then
		return
	end
	if RunService:IsStudio() then
		status(player, "Studio can't travel between places. Publish the game and try it there.", true)
		return
	end
	travelling[player] = true
	status(player, arriving)
	local options = Instance.new("TeleportOptions")
	options:SetTeleportData(data)
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(placeId, { player }, options)
	end)
	if not ok then
		travelling[player] = nil
		Log.Warn("TravelService", `teleport of {player.Name} to {placeId} failed: {err}`)
		status(player, "The way is barred for now. Try again in a moment.", true)
	end
end

function TravelService.Start()
	TeleportService.TeleportInitFailed:Connect(function(player: Player, result: Enum.TeleportResult, message: string)
		travelling[player] = nil
		Log.Warn("TravelService", `teleport of {player.Name} failed ({result.Name}): {message}`)
		status(player, "The way is barred for now. Try again in a moment.", true)
	end)
	Players.PlayerRemoving:Connect(function(player)
		travelling[player] = nil
	end)

	if PlaceRole.IsManor then
		Net.Server.On("SeekHunt", function(player: Player, mapId: any, ruleId: any)
			local map = Registry.Map(if type(mapId) == "string" then mapId else nil)
			if not map or not RULES[ruleId] then
				return
			end
			-- TeleportData is a hint only (it can be forged): class and loadout always come from the profile
			send(player, map.PlaceId, { Rule = ruleId }, `Setting out for {map.DisplayName}…`)
		end)
	else
		Net.Server.On("ReturnToManor", function(player: Player)
			send(player, GameConfig.Places.Manor, {}, "Returning to the Manor…")
		end)
	end
end

return TravelService

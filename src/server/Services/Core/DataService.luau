--!strict
-- DataService: the framework's door to the owner's ProfileStore system (ServerScriptService.Data).
-- It never opens a ProfileStore of its own. DataInit loads each profile into PlayerHandlerData.Profiles;
-- this service waits for it, upgrades old saves through MIGRATIONS, then fires ProfileReady.
-- Changes to saved data go through PlayerHandlerData's functions (AddBloodgems, SetSelectedClass, ...).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Log = require(ReplicatedStorage.Shared.Util.Log)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local PlayerHandlerData = require(ServerScriptService.Data.PlayerHandlerData)
local DebugService = require(script.Parent.DebugService)

-- MIGRATIONS[n] upgrades profile data from version n - 1 to n. Never change or reorder an entry once
-- it has shipped; add a new one instead. ProfileTemplate keeps DataVersion = 0 so every profile runs
-- each migration exactly once.
local MIGRATIONS: { (data: any) -> () } = {
	-- v1: baseline. profile:Reconcile() in DataInit already added the BloodsLocks fields.
	function(_data: any) end,
	-- v2: the Duelist class was renamed Gustave (owner, 2026-10-29).
	function(data: any)
		if data.SelectedClass == "Duelist" then
			data.SelectedClass = "Gustave"
		end
		for _, key in { "OwnedSkins", "EquippedSkins", "ClassStats" } do
			local map = data[key]
			if type(map) == "table" and map.Duelist ~= nil and map.Gustave == nil then
				map.Gustave, map.Duelist = map.Duelist, nil
			end
		end
	end,
}

local DataService = {}

-- Fires (player, data) once a player's profile is loaded and migrated.
DataService.ProfileReady = Signal.new() :: Signal.Signal<Player, any>

local profiles: { [Player]: any } = {}

local function migrate(player: Player, data: any)
	local from = data.DataVersion or 0
	for version = from + 1, #MIGRATIONS do
		MIGRATIONS[version](data)
		data.DataVersion = version
	end
	if data.DataVersion ~= from then
		Log.Info("DataService", `{player.Name}: data upgraded v{from} -> v{data.DataVersion}`)
	end
end

local function onPlayerAdded(player: Player)
	local profile = PlayerHandlerData.WaitForProfile(player)
	if not profile or player.Parent ~= Players then
		return
	end
	migrate(player, profile.Data)
	profiles[player] = profile
	DataService.ProfileReady:Fire(player, profile.Data)
end

-- The player's saved data, or nil while it isn't loaded. Read it freely; change it only through
-- PlayerHandlerData's functions so client notifications stay correct.
function DataService.Get(player: Player): any
	local profile = profiles[player]
	return if profile then profile.Data else nil
end

-- Yields until the player's data is ready. Returns nil if they leave first.
function DataService.Wait(player: Player): any
	if profiles[player] == nil and player.Parent == Players then
		local thread = coroutine.running()
		local ready, left
		local function wake()
			ready:Disconnect()
			left:Disconnect()
			task.spawn(thread)
		end
		ready = DataService.ProfileReady:Connect(function(who: Player)
			if who == player then
				wake()
			end
		end)
		left = player.AncestryChanged:Connect(function()
			if player.Parent ~= Players then
				wake()
			end
		end)
		coroutine.yield()
	end
	return DataService.Get(player)
end

function DataService.Init()
	local findPlayer = DebugService.ResolvePlayer
	DebugService.Register("GetData", function(name: any)
		local player = findPlayer(name)
		local data = if player then DataService.Get(player) else nil
		return if data then table.clone(data) else nil
	end)
	DebugService.Register("AddBloodgems", function(amount: any, name: any)
		local player = assert(findPlayer(name), "no such player")
		PlayerHandlerData.AddBloodgems(player, amount)
		return DataService.Get(player).Bloodgems
	end)
	DebugService.Register("RemoveBloodgems", function(amount: any, name: any)
		local player = assert(findPlayer(name), "no such player")
		local removed = PlayerHandlerData.RemoveBloodgems(player, amount)
		return removed, DataService.Get(player).Bloodgems
	end)
end

function DataService.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		profiles[player] = nil
	end)
end

return DataService

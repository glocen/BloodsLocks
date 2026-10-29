--!strict
-- ProgressionService: in-match experience and levels. A kill credited by NpcService gives the killer the enemy's Xp;
-- XP fills levels (Shared.Simulation.Leveling). Level and progress live on the Player (PlayerState.Level / Xp), so they
-- survive respawns; Spawn applies the level to the character inside the simulation. Everything starts over with each
-- match (a new server).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Leveling = require(Shared.Simulation.Leveling)
local PlayerState = require(Shared.Simulation.PlayerState)
local Signal = require(Shared.Util.Signal)
local DebugService = require(script.Parent.DebugService)
local NpcService = require(script.Parent.NpcService)

local P = PlayerState.Attr

local ProgressionService = {}

-- Fires (player, newLevel) on every level gained.
ProgressionService.LevelUp = Signal.new() :: Signal.Signal<Player, number>

local function level(player: Player): number
	local value = player:GetAttribute(P.Level)
	return if type(value) == "number" then value else 1
end

function ProgressionService.Level(player: Player): number
	return level(player)
end

-- Adds experience and levels the player up as far as it reaches.
function ProgressionService.AddXp(player: Player, amount: number)
	if amount <= 0 then
		return
	end
	local current = level(player)
	local xp = (player:GetAttribute(P.Xp) :: number? or 0) + amount
	while xp >= Leveling.XpToNext(current) do
		xp -= Leveling.XpToNext(current)
		current += 1
		player:SetAttribute(P.Level, current)
		ProgressionService.LevelUp:Fire(player, current)
	end
	player:SetAttribute(P.Xp, if current >= Leveling.MaxLevel then 0 else xp)
end

-- Back to level 1 with no XP (a new match; the self-test pad).
function ProgressionService.Reset(player: Player)
	player:SetAttribute(P.Level, 1)
	player:SetAttribute(P.Xp, 0)
end
local reset = ProgressionService.Reset

function ProgressionService.Init()
	DebugService.Register("GiveXp", function(who: any, amount: number)
		local player = assert(DebugService.ResolvePlayer(who), "no such player")
		ProgressionService.AddXp(player, amount)
		return level(player), player:GetAttribute(P.Xp)
	end)
	DebugService.Register("ResetLevel", function(who: any)
		local player = assert(DebugService.ResolvePlayer(who), "no such player")
		reset(player)
		return true
	end)
end

function ProgressionService.Start()
	Players.PlayerAdded:Connect(reset)
	for _, player in Players:GetPlayers() do
		reset(player)
	end
	NpcService.Died:Connect(function(_model: Model, def: any, killer: Player?)
		if killer then
			ProgressionService.AddXp(killer, def.Xp)
		end
	end)
end

return ProgressionService

--!strict
-- ScoreService: the match score (Config.Score; shown as "Renown"). A ledger per player: every gain is an entry
-- (source, amount, time) so standings can be audited, plus the running total on the Player (PlayerState.Score) for
-- the HUD. Ranking: higher total first; on a tie, whoever reached that total first. Starts over with each match.
-- Sources wired now: enemy kills (the enemy's Score, to the killer). Player kills, objectives and commendations join
-- with their systems.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config.Score)
local PlayerState = require(Shared.Simulation.PlayerState)
local Log = require(Shared.Util.Log)
local DebugService = require(script.Parent.DebugService)
local NpcService = require(script.Parent.NpcService)

local P = PlayerState.Attr

export type Entry = { Source: string, Amount: number, At: number, Detail: string? }
type Ledger = { Total: number, ReachedAt: number, Entries: { Entry } }

local ScoreService = {}

local ledgers: { [Player]: Ledger } = {}

local function ledger(player: Player): Ledger
	local found = ledgers[player]
	if not found then
		found = { Total = 0, ReachedAt = time(), Entries = {} }
		ledgers[player] = found
	end
	return found
end

-- Awards score from a known source. Detail is a short note for the ledger (e.g. the enemy's id).
function ScoreService.Add(player: Player, source: string, amount: number, detail: string?)
	if not Config.Sources[source] then
		Log.Warn("ScoreService", `unknown score source "{source}"`)
		return
	end
	if amount <= 0 or player.Parent ~= Players then
		return
	end
	local book = ledger(player)
	table.insert(book.Entries, { Source = source, Amount = amount, At = time(), Detail = detail })
	book.Total += amount
	book.ReachedAt = time()
	player:SetAttribute(P.Score, book.Total)
end

function ScoreService.Total(player: Player): number
	return ledger(player).Total
end

-- Players in standing order: higher total first, then whoever reached it first.
function ScoreService.Ranking(): { Player }
	local list = Players:GetPlayers()
	table.sort(list, function(a, b)
		local la, lb = ledger(a), ledger(b)
		if la.Total ~= lb.Total then
			return la.Total > lb.Total
		end
		return la.ReachedAt < lb.ReachedAt
	end)
	return list
end

-- Totals per source, for debugging and later the results screen.
function ScoreService.BySource(player: Player): { [string]: number }
	local sums = {}
	for _, entry in ledger(player).Entries do
		sums[entry.Source] = (sums[entry.Source] or 0) + entry.Amount
	end
	return sums
end

function ScoreService.Init()
	DebugService.Register("Score", function(who: any)
		local player = assert(DebugService.ResolvePlayer(who), "no such player")
		local ranking = {}
		for i, p in ScoreService.Ranking() do
			ranking[i] = `{p.Name} {ScoreService.Total(p)}`
		end
		return ScoreService.Total(player), ScoreService.BySource(player), ranking, #ledger(player).Entries
	end)
end

function ScoreService.Start()
	local function reset(player: Player)
		ledgers[player] = { Total = 0, ReachedAt = time(), Entries = {} }
		player:SetAttribute(P.Score, 0)
	end
	Players.PlayerAdded:Connect(reset)
	for _, player in Players:GetPlayers() do
		reset(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		ledgers[player] = nil
	end)
	NpcService.Died:Connect(function(_model: Model, def: any, killer: Player?)
		if killer then
			ScoreService.Add(killer, Config.Sources.EnemyKill, def.Score, def.Id)
		end
	end)
end

return ScoreService

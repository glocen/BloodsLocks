--!strict
-- ScoreService: the match score (Config.Score; shown as "Renown"). One Ledger book per participant id: a player's
-- UserId, or a negative id for a Studio bot (ParticipantService). Books outlive a player leaving, so standings,
-- culls and settlement still see them. Every gain is a ledger entry tagged with the current phase; a gain with an
-- event key pays once only, and keyed gains can be revoked (Shared.Match.Ledger has the rules and the standings).
-- A player's total is mirrored on the Player (PlayerState.Score) for the HUD; Changed fires for everyone else.
-- Sources wired now: enemy kills (the enemy's Score, to the killer). Objectives and commendations join with their
-- systems; player kills give Renown only inside ritual sites (owner decision D4), from R1.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config.Score)
local PlayerState = require(Shared.Simulation.PlayerState)
local Ledger = require(Shared.Match.Ledger)
local Signal = require(Shared.Util.Signal)
local Log = require(Shared.Util.Log)
local DebugService = require(script.Parent.DebugService)
local NpcService = require(script.Parent.NpcService)

local P = PlayerState.Attr

export type Who = Player | number

local ScoreService = {}

-- Fires (participantId, newTotal) whenever a total changes.
ScoreService.Changed = Signal.new() :: Signal.Signal<number, number>

local books: { [number]: Ledger.Book } = {}
local seq = 0
local phase = 0

local function idOf(who: Who): number
	return if type(who) == "number" then who else (who :: Player).UserId
end

local function book(id: number): Ledger.Book
	local found = books[id]
	if not found then
		found = Ledger.new()
		books[id] = found
	end
	return found
end

local function publish(id: number)
	local total = book(id).Total
	local player = if id > 0 then Players:GetPlayerByUserId(id) else nil
	if player then
		player:SetAttribute(P.Score, total)
	end
	ScoreService.Changed:Fire(id, total)
end

-- Awards score from a known source. `key` makes the award one-time (e.g. "Lantern:<id>"). True if it was paid.
function ScoreService.Add(who: Who, source: string, amount: number, detail: string?, key: string?): boolean
	if not Config.Sources[source] then
		Log.Warn("ScoreService", `unknown score source "{source}"`)
		return false
	end
	local id = idOf(who)
	seq += 1
	local paid = Ledger.Add(book(id), { Source = source, Amount = amount, Seq = seq, Phase = phase, Detail = detail, Key = key })
	if paid then
		publish(id)
	end
	return paid
end

-- Takes back a keyed award (a pledge overwritten). Returns the amount removed.
function ScoreService.Revoke(who: Who, key: string): number
	local id = idOf(who)
	local amount = Ledger.Revoke(book(id), key)
	if amount > 0 then
		publish(id)
	end
	return amount
end

function ScoreService.Total(who: Who): number
	return book(idOf(who)).Total
end

-- Totals per source, for commendations, debugging and the results screen.
function ScoreService.BySource(who: Who): { [string]: number }
	return Ledger.BySource(book(idOf(who)))
end

-- Participant ids in standing order. `ids` limits it (e.g. to eligible participants); default: every book.
function ScoreService.Ranking(ids: { number }?): { number }
	local list = ids
	if not list then
		local all = {}
		for id in books do
			table.insert(all, id)
		end
		list = all
	end
	return Ledger.Rank(books, list :: { number })
end

-- The phase new entries are tagged with (MatchService sets it; 0 before the first phase).
function ScoreService.SetPhase(index: number)
	phase = index
end

function ScoreService.Init()
	DebugService.Register("Score", function(who: any)
		local player = assert(DebugService.ResolvePlayer(who), "no such player")
		local ranking = {}
		for i, id in ScoreService.Ranking() do
			ranking[i] = `{id} {book(id).Total}`
		end
		return ScoreService.Total(player), ScoreService.BySource(player), ranking, #book(player.UserId).Entries
	end)
end

function ScoreService.Start()
	-- a player who comes back to the same match server finds their book where they left it
	local function show(player: Player)
		player:SetAttribute(P.Score, book(player.UserId).Total)
	end
	Players.PlayerAdded:Connect(show)
	for _, player in Players:GetPlayers() do
		show(player)
	end
	NpcService.Died:Connect(function(_model: Model, def: any, killer: Player?)
		if killer then
			ScoreService.Add(killer, Config.Sources.EnemyKill, def.Score, def.Id)
		end
	end)
end

return ScoreService

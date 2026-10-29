--!strict
-- ParticipantService (Match places): the match's entrants. One record per entrant, keyed by participant id: a
-- player's UserId, or a negative id for an AI hunter. A record outlives respawns (a new body is not a new entrant) and
-- the player leaving (standings, culls and settlement still need it). Records are replicated under
-- ReplicatedStorage.MatchState.Participants (Shared.Match.MatchState) for every screen.
--   Players join on arrival. AI hunters fill the empty seats up to Config.Match.Lobby.MaxPlayers (owner decision D11);
--   MatchService calls FillWithAi when the countdown ends. They have no body or judgement yet.
--   Deaths: EntityService.PlayerDied (players) and BodyDied (AI hunter bodies, which carry their id as OwnerId) count
--   the victim's death and the killer's kill (a Shinigami's kill is its master's), log it, then fire Died for
--   MatchService. Player kills pay Renown only inside ritual sites (D4), from R1.
--   Joining: open until MatchService closes it when the match begins (later arrivals aren't entrants).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local MatchConfig = require(Shared.Config.Match)
local Registry = require(Shared.Definitions.Registry)
local MatchState = require(Shared.Match.MatchState)
local PlayerState = require(Shared.Simulation.PlayerState)
local Log = require(Shared.Util.Log)
local Signal = require(Shared.Util.Signal)
local EntityState = require(Shared.Simulation.EntityState)
local Core = script.Parent.Parent.Core
local DebugService = require(Core.DebugService)
local EntityService = require(Core.EntityService)
local ScoreService = require(Core.ScoreService)

local M = MatchState.Participant

export type Participant = {
	Id: number,
	Name: string,
	Ai: boolean,
	Class: string,
	Eligible: boolean,
	Alive: boolean,
	Culled: boolean,
	Left: boolean,
	Lives: number,
	Region: string,
	Kills: number,
	Deaths: number,
	Placement: number,
	RevivalAt: number,
	JoinedAt: number,
	LeftAt: number?,
}

export type Kill = { Killer: number?, Victim: number, At: number, InRitual: boolean }

local ParticipantService = {}

ParticipantService.Priority = 50 -- its Init makes ReplicatedStorage.MatchState, which MatchService uses

-- Fires (victimId, killerId?) after a death is recorded.
ParticipantService.Died = Signal.new() :: Signal.Signal<number, number?>

local open = true
local records: { [number]: Participant } = {}
local joinOrder: { number } = {}
local kills: { Kill } = {}
local bags: { [number]: Configuration } = {}
local folder: Folder
local nextAiIndex = 1

-- Writes a record's replicated fields onto its attribute bag.
local function publish(record: Participant)
	local bag = bags[record.Id]
	if not bag then
		local created = Instance.new("Configuration")
		created.Name = tostring(record.Id)
		created.Parent = folder
		bags[record.Id] = created
		bag = created
	end
	for field, attribute in M do
		local value = if field == "Score" then ScoreService.Total(record.Id) else (record :: any)[field]
		if bag:GetAttribute(attribute) ~= value then
			bag:SetAttribute(attribute, value)
		end
	end
end

local function add(id: number, name: string, ai: boolean, class: string): Participant
	local record: Participant = {
		Id = id,
		Name = name,
		Ai = ai,
		Class = class,
		Eligible = true,
		Alive = true,
		Culled = false,
		Left = false,
		Lives = 0,
		Region = "",
		Kills = 0,
		Deaths = 0,
		Placement = 0,
		RevivalAt = 0,
		JoinedAt = time(),
		LeftAt = nil,
	}
	records[id] = record
	table.insert(joinOrder, id)
	publish(record)
	return record
end

local function classOf(player: Player): string
	return Registry.Class(player:GetAttribute(PlayerState.Attr.Class)).Id
end

local function join(player: Player)
	local record = records[player.UserId]
	if record then -- back in the same match server: the record is theirs again (L1 decides who may return)
		record.Left, record.LeftAt = false, nil
		publish(record)
		return
	end
	if not open then
		return
	end
	add(player.UserId, player.DisplayName, false, classOf(player))
	-- a new body is the same entrant alive again (MatchService takes revival over in L1)
	player.CharacterAdded:Connect(function()
		local current = records[player.UserId]
		if current and current.Eligible and not current.Alive then
			current.Alive = true
			publish(current)
		end
	end)
	player:GetAttributeChangedSignal(PlayerState.Attr.Class):Connect(function()
		local current = records[player.UserId]
		if current then
			current.Class = classOf(player)
			publish(current)
		end
	end)
end

local function leave(player: Player)
	local record = records[player.UserId]
	if record then
		record.Left, record.Eligible, record.Alive, record.LeftAt = true, false, false, time()
		publish(record)
	end
end

local function recordDeath(victimId: number, killer: number?)
	local victim = records[victimId]
	if not victim or not victim.Alive then
		return
	end
	victim.Deaths += 1
	victim.Alive = false
	publish(victim)
	local credited = if killer then records[killer] else nil
	if credited then
		credited.Kills += 1
		publish(credited)
	end
	-- InRitual comes with ritual sites (R1); until then no kill happens inside one, so none pays Renown (D4)
	table.insert(kills, { Killer = if credited then killer else nil, Victim = victim.Id, At = time(), InRitual = false })
	ParticipantService.Died:Fire(victimId, if credited then killer else nil)
end

-- Joins close when the match begins (MatchService); later arrivals aren't entrants.
function ParticipantService.Close()
	open = false
end

-- Adds one AI hunter. Returns its id, or nil when every seat is taken or the names ran out.
function ParticipantService.AddAiHunter(): number?
	local names = MatchConfig.AiHunters.Names
	if #joinOrder >= MatchConfig.Lobby.MaxPlayers or nextAiIndex > #names then
		return nil
	end
	local id = -nextAiIndex
	add(id, names[nextAiIndex], true, Registry.DefaultClass)
	nextAiIndex += 1
	return id
end

-- Fills every empty seat with AI hunters (D11). Returns how many joined.
function ParticipantService.FillWithAi(): number
	if not MatchConfig.AiHunters.Fill then
		return 0
	end
	local added = 0
	while ParticipantService.AddAiHunter() do
		added += 1
	end
	if added > 0 then
		Log.Info("Participants", `{added} AI hunter(s) fill the empty seats`)
	end
	return added
end

function ParticipantService.Get(id: number): Participant?
	return records[id]
end

-- Every entrant's id, in join order (leavers included).
function ParticipantService.All(): { number }
	return table.clone(joinOrder)
end

-- The ids that can still place: not culled, not left. In join order.
function ParticipantService.Eligible(): { number }
	local list = {}
	for _, id in joinOrder do
		if records[id].Eligible then
			table.insert(list, id)
		end
	end
	return list
end

-- Every player and AI-hunter kill so far, oldest first.
function ParticipantService.Kills(): { Kill }
	return table.clone(kills)
end

-- Writes record fields (MatchService: culls, regions, lives, placements) and replicates them.
function ParticipantService.Update(id: number, fields: { [string]: any })
	local record = assert(records[id], `no participant {id}`)
	local fieldsOf = record :: any
	for key, value in fields do
		assert(fieldsOf[key] ~= nil or key == "LeftAt", `participants have no field {key}`)
		fieldsOf[key] = value
	end
	publish(record)
end

function ParticipantService.Init()
	local root = Instance.new("Folder")
	root.Name = MatchState.FolderName
	folder = Instance.new("Folder")
	folder.Name = MatchState.ParticipantsName
	folder.Parent = root
	root.Parent = ReplicatedStorage

	DebugService.Register("Participants", function()
		local lines = {}
		for _, id in ScoreService.Ranking(joinOrder) do
			local r = records[id]
			table.insert(lines, `{id} {r.Name}{if r.Ai then " (AI)" else ""} score {ScoreService.Total(id)} k{r.Kills} d{r.Deaths}{if r.Eligible then "" else " out"}`)
		end
		return lines
	end)
	DebugService.Register("FillWithAi", function()
		return ParticipantService.FillWithAi(), #joinOrder
	end)
	DebugService.Register("AiScore", function(_who: any, id: number, amount: number, key: string?)
		assert(records[id] and records[id].Ai, "not an AI hunter")
		return ScoreService.Add(id, "Objective", amount, "debug", key)
	end)
end

function ParticipantService.Start()
	Players.PlayerAdded:Connect(join)
	for _, player in Players:GetPlayers() do
		join(player)
	end
	Players.PlayerRemoving:Connect(leave)
	EntityService.PlayerDied:Connect(function(player: Player, killer: number?)
		recordDeath(player.UserId, killer)
	end)
	EntityService.BodyDied:Connect(function(model: Model, killer: number?)
		local owner = model:GetAttribute(EntityState.Attr.OwnerId)
		if type(owner) == "number" and owner < 0 then
			recordDeath(owner, killer)
		end
	end)
	ScoreService.Changed:Connect(function(id: number)
		local record = records[id]
		if record then
			publish(record)
		end
	end)
end

return ParticipantService

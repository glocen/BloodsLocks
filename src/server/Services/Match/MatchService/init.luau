--!strict
-- MatchService (Match places): the one authoritative match lifecycle (engineering-plan section 3, whole-game brief
-- section 3). States (Shared.Match.MatchState.States), each with a server deadline in time():
--   Waiting (Antechamber, until enough players) → Countdown (cancels below the minimum; joins lock near the end;
--   AI hunters fill the empty seats when it ends, D11) → Intro → RegionChoice → Phase n → PhaseResolve (culls from
--   the rule, D1) → … → FinalSetup (lives, HP bonus from Renown, D2) → Final (two lives; sudden death at the cap;
--   simultaneous last deaths go to the higher Renown) → Results (one immutable result, Bloodgems paid once) → Return.
-- Entrants can't be hurt outside Phase and Final, nor during the spawn protection that ends when they attack.
-- Death in a phase: revive after the rule's delay in the region the entrant chose (ChooseRegion) or their last one.
-- Studio: nothing starts until BL_Debug "MatchStart" (fast lengths by default), so a plain playtest keeps the
-- self-test environment. Live match servers start in Waiting at once.
-- Clients read the state from ReplicatedStorage.MatchState (attributes in MatchState.Match).

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local MatchConfig = require(Shared.Config.Match)
local Registry = require(Shared.Definitions.Registry)
local MatchState = require(Shared.Match.MatchState)
local Culling = require(Shared.Match.Culling)
local Regions = require(Shared.Match.Regions)
local Rewards = require(Shared.Match.Rewards)
local EntityState = require(Shared.Simulation.EntityState)
local PlayerState = require(Shared.Simulation.PlayerState)
local CombatSim = require(Shared.Simulation.CombatSim)
local Net = require(Shared.Net)
local Signal = require(Shared.Util.Signal)
local Log = require(Shared.Util.Log)
local Parts = require(Shared.Util.Parts)
local Core = script.Parent.Parent.Core
local DebugService = require(Core.DebugService)
local ScoreService = require(Core.ScoreService)
local TravelService = require(Core.TravelService)
local ParticipantService = require(script.Parent.ParticipantService)
local Spawning = require(script.Spawning)
local Settlement = require(script.Settlement)
local Atlas = require(script.Atlas)

local S = MatchState.States
local M = MatchState.Match
local A = EntityState.Attr
local P = PlayerState.Attr

type Lengths = {
	Countdown: number,
	FullCountdown: number,
	MinPlayers: number,
	Intro: number,
	RegionFirst: number,
	RegionLater: number,
	Phase: (index: number) -> number,
	Resolve: number,
	FinalSetup: number,
	FinalCap: number,
	Results: number,
}

local MatchService = {}

-- Fires (state, phase) on every transition.
MatchService.StateChanged = Signal.new() :: Signal.Signal<string, number>

local root: Folder
local rule = Registry.DefaultRuleDef() -- (the reserved server's record will name the rule, A1)
local fast = false
local state = S.Idle
local phase = 0
local deadline = 0
local entrants = 0
local matchId = ""
local locked = false
local suddenDeath = false
local lastDrain = 0
local random = Random.new()
local choices: { [number]: string } = {}
local regionOf: { [number]: string } = {}
local protectedUntil: { [number]: number } = {}
local hunterBonus: { [number]: number } = {}
local pendingFinalDeaths: { number } = {}
local results: { Settlement.Line } = {}
local antechamberIndex = 0

local cachedLengths: Lengths? = nil

local function buildLengths(): Lengths
	if fast then
		local f = MatchConfig.StudioFast
		return {
			Countdown = f.Countdown,
			FullCountdown = math.min(f.Countdown, MatchConfig.Lobby.FullCountdown),
			MinPlayers = f.MinPlayers,
			Intro = f.Intro,
			RegionFirst = f.RegionChoice.First,
			RegionLater = f.RegionChoice.Later,
			Phase = function(index)
				return f.Phases[index] or f.Phases[#f.Phases]
			end,
			Resolve = f.PhaseResolve,
			FinalSetup = f.FinalSetup,
			FinalCap = f.FinalTimeCap,
			Results = f.Results,
		}
	end
	local lobby = MatchConfig.Lobby
	return {
		Countdown = lobby.Countdown,
		FullCountdown = lobby.FullCountdown,
		MinPlayers = lobby.MinPlayers,
		Intro = rule.Intro,
		RegionFirst = rule.RegionChoice.First,
		RegionLater = rule.RegionChoice.Later,
		Phase = function(index)
			return rule.Phases[index].Duration
		end,
		Resolve = rule.PhaseResolve,
		FinalSetup = rule.FinalSetup,
		FinalCap = rule.Final.TimeCap,
		Results = rule.Results,
	}
end

-- The state lengths for this match (the rule's, or the Studio fast profile's), built once per match.
local function lengths(): Lengths
	if not cachedLengths then
		cachedLengths = buildLengths()
	end
	return cachedLengths :: Lengths
end

-- The region choice so far, for the map's "2 / 3" (Atlas).
local function publishChoices()
	local live: { [number]: string } = {}
	for id, region in choices do
		local entrant = ParticipantService.Get(id)
		if entrant and entrant.Eligible then
			live[id] = region
		end
	end
	Atlas.SetChoices(root, live, Regions.Capacity(#ParticipantService.Eligible(), #Spawning.Regions()))
end

local function enter(newState: string, length: number?)
	state = newState
	deadline = if length then time() + length else 0
	if state == S.RegionChoice then
		publishChoices()
	end
	root:SetAttribute(M.State, state)
	root:SetAttribute(M.Phase, phase)
	root:SetAttribute(M.StartedAt, time())
	root:SetAttribute(M.Deadline, deadline)
	Log.Info("Match", if newState == S.Phase or newState == S.PhaseResolve or newState == S.RegionChoice then `{state} {phase}` else state)
	MatchService.StateChanged:Fire(state, phase)
end

local function record(id: number): any
	return ParticipantService.Get(id)
end

-- Positions of every other entrant's living body.
local function others(exceptId: number): { Vector3 }
	local list = {}
	for _, id in ParticipantService.All() do
		local at = if id ~= exceptId then Spawning.BodyPosition(id) else nil
		if at then
			table.insert(list, at)
		end
	end
	return list
end

-- An entrant alive at `cframe` and briefly protected, with a body there (an AI hunter only where MatchConfig.AiBodies
-- gives it one: `final` is the final arena).
local function spawnEntrant(id: number, cframe: CFrame, final: boolean)
	protectedUntil[id] = time() + rule.Revival.Protection
	ParticipantService.Update(id, { Alive = true, RevivalAt = 0, ProtectedUntil = protectedUntil[id] })
	if id < 0 then
		Spawning.RemoveHunter(id)
		local embodied = if final then MatchConfig.AiBodies.Final else MatchConfig.AiBodies.Phases
		if embodied then
			local entrant = record(id)
			Spawning.MakeHunter(id, entrant.Name, entrant.Class, cframe, hunterBonus[id] or 0)
		end
	else
		local player = Players:GetPlayerByUserId(id)
		if player then
			Spawning.PlacePlayer(player, cframe)
		end
	end
end

local function spawnInRegion(id: number, region: string)
	local cframe = Spawning.InRegion(region, others(id), rule.Revival.Separation)
	if not cframe then
		Log.Warn("Match", `no spawn point in region {region}`)
		return
	end
	regionOf[id] = region
	ParticipantService.Update(id, { Region = region })
	spawnEntrant(id, cframe, false)
end

local function removeBody(id: number)
	if id < 0 then
		Spawning.RemoveHunter(id)
	else
		local player = Players:GetPlayerByUserId(id)
		if player then
			Spawning.RemovePlayerBody(player)
		end
	end
end

-- Takes an entrant out of the running at `placement` (culled, or out of lives in the final).
local function eliminate(id: number, placement: number, culled: boolean)
	ParticipantService.Update(id, { Eligible = false, Culled = culled, Alive = false, Placement = placement, RevivalAt = 0, Lives = 0 })
	removeBody(id)
end

-- Phase flow ---------------------------------------------------------------------------------------------------

local function beginPhase()
	local ids = ParticipantService.Eligible()
	local assignment = Regions.Allocate(ids, choices, Spawning.Regions(), random)
	table.clear(choices)
	for _, id in ids do
		ParticipantService.Update(id, { Moved = assignment[id].Moved })
		spawnInRegion(id, assignment[id].Region)
	end
	ScoreService.SetPhase(phase)
	enter(S.Phase, lengths().Phase(phase))
end

local function resolvePhase()
	local before = ParticipantService.Eligible()
	local keep = Culling.KeepCount(rule, phase, entrants, #before)
	if keep < #before then
		local ranking = ScoreService.Ranking(before)
		for rank = #ranking, keep + 1, -1 do
			eliminate(ranking[rank], rank, true)
		end
	end
	enter(S.PhaseResolve, lengths().Resolve)
end

local function finish(winner: number?)
	if winner then
		ParticipantService.Update(winner, { Placement = 1 })
		root:SetAttribute(M.Winner, winner)
	end
	results = {}
	for _, id in ParticipantService.All() do
		table.insert(results, Settlement.Line(rule, record(id)))
	end
	table.sort(results, function(a, b)
		local pa, pb = if a.Placement == 0 then math.huge else a.Placement, if b.Placement == 0 then math.huge else b.Placement
		return pa < pb
	end)
	for _, line in results do
		local player = if line.Id > 0 then Players:GetPlayerByUserId(line.Id) else nil
		if player then
			Settlement.Pay(player, matchId, line)
		end
	end
	enter(S.Results, lengths().Results)
end

local function setupFinal()
	local finalists = ParticipantService.Eligible()
	if #finalists <= 1 then
		finish(finalists[1])
		return
	end
	for _, id in finalists do
		local bonus = Rewards.FinalHpBonus(rule, ScoreService.Total(id))
		ParticipantService.Update(id, { Lives = rule.Final.Lives })
		if id < 0 then
			hunterBonus[id] = bonus
		else
			local player = Players:GetPlayerByUserId(id)
			if player then
				player:SetAttribute(P.HpBonus, bonus)
			end
		end
		removeBody(id) -- a fresh body carries the bonus
	end
	for _, id in finalists do
		local cframe = Spawning.InFinal(others(id), rule.Revival.Separation)
		if cframe then
			spawnEntrant(id, cframe, true)
		end
	end
	enter(S.FinalSetup, lengths().FinalSetup)
end

-- Final deaths are settled together once per tick, so two finalists dying in the same step resolve by the rule (D2).
local function settleFinalDeaths(now: number)
	if #pendingFinalDeaths == 0 then
		return
	end
	local dying = pendingFinalDeaths
	pendingFinalDeaths = {}
	local out: { number } = {}
	for _, id in dying do
		local entrant = record(id)
		if entrant and entrant.Eligible then
			local lives = entrant.Lives - 1
			ParticipantService.Update(id, { Lives = lives })
			if lives <= 0 then
				table.insert(out, id)
			else
				ParticipantService.Update(id, { RevivalAt = now + rule.Revival.Delay })
			end
		end
	end
	if #out == 0 then
		return
	end
	local remaining = {}
	for _, id in ParticipantService.Eligible() do
		if not table.find(out, id) then
			table.insert(remaining, id)
		end
	end
	local ranked = ScoreService.Ranking(out) -- best first
	if #remaining == 0 then
		-- every finalist left fell at once: the higher Renown (then whoever reached it first) wins
		table.insert(remaining, table.remove(ranked, 1) :: number)
	end
	for i, id in ranked do
		eliminate(id, #remaining + i, false)
	end
	if #remaining == 1 then
		finish(remaining[1])
	end
end

local function revive(now: number)
	for _, id in ParticipantService.Eligible() do
		local entrant = record(id)
		if not entrant.Alive and entrant.RevivalAt > 0 and now >= entrant.RevivalAt then
			if state == S.Final then
				local cframe = Spawning.InFinal(others(id), rule.Revival.Separation)
				if cframe then
					spawnEntrant(id, cframe, true)
				end
			else
				local regions = Spawning.Regions()
				local region = choices[id] or regionOf[id] or regions[random:NextInteger(1, #regions)]
				choices[id] = nil
				spawnInRegion(id, region)
			end
		end
	end
end

local function drain(now: number)
	if now - lastDrain < 1 then
		return
	end
	lastDrain = now
	for _, id in ParticipantService.Eligible() do
		local body: Model? = if id < 0 then Spawning.HunterBody(id) else (Players:GetPlayerByUserId(id) and (Players:GetPlayerByUserId(id) :: Player).Character)
		if body and EntityState.Number(body, A.HP, 0) > 0 then
			CombatSim.QueueLoss(body, EntityState.Number(body, A.HPMax, 0) * rule.Final.SuddenDeath.DrainPerSecond)
		end
	end
end

local function beginMatch()
	ParticipantService.Close()
	ParticipantService.FillWithAi()
	entrants = #ParticipantService.All()
	matchId = if game.JobId ~= "" then game.JobId else HttpService:GenerateGUID(false)
	root:SetAttribute(M.Entrants, entrants)
	for _, player in Players:GetPlayers() do
		local id = player.UserId
		Settlement.OnLeave(player, matchId, function()
			local entrant = record(id)
			return if entrant then Settlement.Line(rule, entrant) else nil
		end)
	end
	enter(S.Intro, lengths().Intro)
end

local function tick()
	if state == S.Idle or state == S.Return then
		return
	end
	local now = time()
	local due = deadline > 0 and now >= deadline
	local l = lengths()
	if state == S.Waiting then
		local count = #Players:GetPlayers()
		if count >= l.MinPlayers then
			enter(S.Countdown, if count >= MatchConfig.Lobby.MaxPlayers then l.FullCountdown else l.Countdown)
		end
	elseif state == S.Countdown then
		if #Players:GetPlayers() < l.MinPlayers then
			locked = false
			root:SetAttribute(M.Locked, false)
			enter(S.Waiting, nil)
		elseif due then
			beginMatch()
		elseif not locked and deadline - now <= MatchConfig.Lobby.LockAt then
			locked = true -- (A1: the server delists itself here)
			root:SetAttribute(M.Locked, true)
		end
	elseif state == S.Intro then
		if due then
			phase = 1
			enter(S.RegionChoice, l.RegionFirst)
		end
	elseif state == S.RegionChoice then
		if due then
			beginPhase()
		end
	elseif state == S.Phase then
		revive(now)
		if due then
			resolvePhase()
		end
	elseif state == S.PhaseResolve then
		if due then
			if phase < #rule.Phases then
				phase += 1
				enter(S.RegionChoice, l.RegionLater)
			else
				setupFinal()
			end
		end
	elseif state == S.FinalSetup then
		if due then
			enter(S.Final, l.FinalCap)
		end
	elseif state == S.Final then
		settleFinalDeaths(now)
		if state ~= S.Final then
			return
		end
		if #ParticipantService.Eligible() <= 1 then
			finish(ParticipantService.Eligible()[1])
			return
		end
		revive(now)
		if due and not suddenDeath then
			suddenDeath = true
			root:SetAttribute(M.SuddenDeath, true)
			for _, id in ParticipantService.Eligible() do
				ParticipantService.Update(id, { Lives = math.min(record(id).Lives, rule.Final.SuddenDeath.Lives) })
			end
		end
		if suddenDeath then
			drain(now)
		end
	elseif state == S.Results then
		if due then
			enter(S.Return, nil)
			TravelService.ReturnToManor(Players:GetPlayers())
		end
	end
end

local function onDied(victim: number, _killer: number?)
	local body: Model? = if victim < 0 then Spawning.HunterBody(victim) else (Players:GetPlayerByUserId(victim) and (Players:GetPlayerByUserId(victim) :: Player).Character)
	local fell = Parts.Root(body)
	if fell then
		ParticipantService.Update(victim, { FellAt = fell.Position })
	end
	if state == S.Phase then
		ParticipantService.Update(victim, { RevivalAt = time() + rule.Revival.Delay })
		if victim < 0 then
			task.delay(1.5, function()
				local entrant = record(victim)
				if entrant and not entrant.Alive then
					Spawning.RemoveHunter(victim)
				end
			end)
		end
	elseif state == S.Final then
		table.insert(pendingFinalDeaths, victim)
	end
end

-- Spawn protection ends the moment the entrant attacks.
local function watchAttacks(player: Player, character: Model)
	character:GetAttributeChangedSignal(A.ActionStart):Connect(function()
		local _, action = EntityState.CurrentAction(character)
		if action and (action.Hit or action.Shots or action.Beam or action.Projectile) and (protectedUntil[player.UserId] or 0) > 0 then
			protectedUntil[player.UserId] = 0
			if record(player.UserId) then
				ParticipantService.Update(player.UserId, { ProtectedUntil = 0 })
			end
		end
	end)
end

local function toAntechamber(player: Player)
	antechamberIndex += 1
	local cframe = Spawning.InAntechamber(antechamberIndex)
	if cframe then
		Spawning.PlacePlayer(player, cframe)
	end
end

-- Opens the match: players gather in the Antechamber. `fastLengths`: the Studio fast profile.
function MatchService.Begin(fastLengths: boolean)
	if state ~= S.Idle then
		return
	end
	fast = fastLengths
	cachedLengths = nil
	Players.CharacterAutoLoads = false
	for _, player in Players:GetPlayers() do
		toAntechamber(player)
	end
	enter(S.Waiting, nil)
end

-- Studio: ends the current state's wait now (Waiting: starts the countdown).
function MatchService.Skip()
	if state == S.Waiting then
		enter(S.Countdown, 0)
	elseif deadline > 0 then
		deadline = time()
	end
end

function MatchService.State(): (string, number)
	return state, phase
end

function MatchService.Results(): { Settlement.Line }
	return table.clone(results)
end

function MatchService.MatchId(): string
	return matchId
end

-- Studio: kills an entrant's body now (no killer).
function MatchService.Kill(id: number): boolean
	local body: Model? = if id < 0 then Spawning.HunterBody(id) else (Players:GetPlayerByUserId(id) and (Players:GetPlayerByUserId(id) :: Player).Character)
	if not body or EntityState.Number(body, A.HP, 0) <= 0 then
		return false
	end
	CombatSim.QueueLoss(body, EntityState.Number(body, A.HPMax, 0) * 10)
	return true
end

function MatchService.Init()
	DebugService.Register("MatchStart", function(_who: any, fastLengths: any)
		MatchService.Begin(fastLengths ~= false)
		return state
	end)
	DebugService.Register("MatchSkip", function()
		MatchService.Skip()
		return state, phase
	end)
	DebugService.Register("MatchKill", function(_who: any, id: number)
		return MatchService.Kill(id)
	end)
	if RunService:IsStudio() then
		DebugService.Register("MatchSmoke", function(who: any)
			local player = assert(DebugService.ResolvePlayer(who), "no player")
			return require(script.Smoke).Run(MatchService, player)
		end)
	end
	DebugService.Register("MatchState", function()
		local lines = { `{state} phase {phase} ({math.max(0, math.floor(deadline - time()))} s left), {entrants} entrants` }
		for _, id in ScoreService.Ranking(ParticipantService.All()) do
			local e = record(id)
			table.insert(lines, `{id} {e.Name} score {ScoreService.Total(id)} lives {e.Lives} place {e.Placement} {if e.Eligible then (if e.Alive then "alive" else "dead") else "out"} {e.Region}`)
		end
		return lines
	end)
end

function MatchService.Start()
	root = ReplicatedStorage:WaitForChild(MatchState.FolderName) :: Folder
	root:SetAttribute(M.Rule, rule.Id)
	root:SetAttribute(M.State, state)
	root:SetAttribute(M.Dressed, Spawning.AntechamberDressed())
	Atlas.Publish(root)
	CombatSim.SetGuard(function(target: Model, now: number): boolean
		if state == S.Idle then
			return false
		end
		local id = Spawning.ParticipantOf(target)
		if not id then
			return false -- enemies, dummies and companions are never protected
		end
		if state ~= S.Phase and state ~= S.Final then
			return true -- no damage to entrants between phases
		end
		return now < (protectedUntil[id] or 0)
	end)
	ParticipantService.Died:Connect(onDied)
	Net.Server.On("ChooseRegion", function(player: Player, region: any)
		local entrant = record(player.UserId)
		if type(region) ~= "string" or not entrant or not entrant.Eligible or not table.find(Spawning.Regions(), region) then
			return
		end
		if state == S.RegionChoice or (state == S.Phase and not entrant.Alive) then
			choices[player.UserId] = region
			if state == S.RegionChoice then
				publishChoices()
			end
		end
	end)
	local function watch(player: Player)
		player.CharacterAdded:Connect(function(character)
			watchAttacks(player, character)
		end)
		if player.Character then
			watchAttacks(player, player.Character)
		end
		if state == S.Waiting or state == S.Countdown then
			toAntechamber(player)
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	RunService.Heartbeat:Connect(tick)
	if not RunService:IsStudio() or MatchConfig.StudioAutoStart then
		MatchService.Begin(false)
	end
end

return MatchService

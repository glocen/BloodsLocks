--!strict
-- Smoke (Studio only): runs one whole fast match, solo plus AI hunters, and checks the lifecycle's rules on the way:
-- the field fills (D11), AI hunters stay bodiless in the phases (MatchConfig.AiBodies), regions respect capacity,
-- the player's death revives, culls follow the rule (8 → 8 → 6 → 3, lowest
-- Renown out, D1), the final gives lives and the HP bonus (D2), eliminations place in order, one winner, Bloodgems are
-- paid once. Afterwards it restores the player's Test-store Bloodgems, Stats and match award. The match ends in Return,
-- so restart the playtest before playing.
-- Run during a Victorian playtest, Server context:  game.ServerStorage.BL_Debug:Invoke("MatchSmoke")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage.Shared
local Registry = require(Shared.Definitions.Registry)
local MatchConfig = require(Shared.Config.Match)
local MatchState = require(Shared.Match.MatchState)
local Regions = require(Shared.Match.Regions)
local Rewards = require(Shared.Match.Rewards)
local PlayerState = require(Shared.Simulation.PlayerState)
local PlayerHandlerData = require(ServerScriptService.Data.PlayerHandlerData)
local Core = script.Parent.Parent.Parent.Core
local ScoreService = require(Core.ScoreService)
local ParticipantService = require(script.Parent.Parent.ParticipantService)
local Spawning = require(script.Parent.Spawning)

local S = MatchState.States

local Smoke = {}

function Smoke.Run(MatchService: any, player: Player): string
	local rule = Registry.DefaultRuleDef()
	local lines: { string } = {}
	local passed, failed = 0, 0
	local function check(label: string, ok: boolean, detail: string?)
		if ok then
			passed += 1
		else
			failed += 1
		end
		table.insert(lines, `{if ok then "PASS" else "FAIL"}  {label}{if detail then ` ({detail})` else ""}`)
	end
	local function waitUntil(condition: () -> boolean, timeout: number): boolean
		local deadline = os.clock() + timeout
		while not condition() do
			if os.clock() > deadline then
				return false
			end
			task.wait(0.1)
		end
		return true
	end
	local function reach(target: string, phase: number?, timeout: number?): boolean
		return waitUntil(function()
			local state, current = MatchService.State()
			return state == target and (phase == nil or current == phase)
		end, timeout or 5)
	end
	local function skipTo(target: string, phase: number?)
		MatchService.Skip()
		check(`reaches {target}{if phase then ` {phase}` else ""}`, reach(target, phase))
	end
	local function entrant(id: number)
		return ParticipantService.Get(id) :: any
	end
	local function killAndWait(id: number): boolean
		if not waitUntil(function()
			return MatchService.Kill(id)
		end, 6) then
			return false
		end
		return waitUntil(function()
			return not entrant(id).Alive
		end, 3)
	end
	local profile = PlayerHandlerData.Profiles[player]
	assert(profile, "the player's profile isn't loaded")
	local gemsBefore = profile.Data.Bloodgems
	local statsBefore = table.clone(profile.Data.Stats)

	MatchService.Begin(true)
	check("opens in Waiting", reach(S.Waiting, nil, 1) or reach(S.Countdown, nil, 1))
	MatchService.Skip() -- straight past the countdown
	check("begins: Intro", reach(S.Intro))
	local all = ParticipantService.All()
	local ai = 0
	for _, id in all do
		if entrant(id).Ai then
			ai += 1
		end
	end
	check("AI hunters fill the field (D11)", #all == MatchConfig.Lobby.MaxPlayers and ai == MatchConfig.Lobby.MaxPlayers - 1, `{#all} entrants, {ai} AI`)

	skipTo(S.RegionChoice, 1)
	skipTo(S.Phase, 1)
	task.wait(1.5)
	local alive, load = 0, {}
	for _, id in all do
		local e = entrant(id)
		if e.Alive then
			alive += 1
		end
		load[e.Region] = (load[e.Region] or 0) + 1
	end
	local capacity = Regions.Capacity(#all, 4)
	local within = true
	for _, n in load do
		within = within and n <= capacity
	end
	check("everyone spawned alive", alive == #all, `{alive}/{#all}`)
	check("regions within capacity", within, `capacity {capacity}`)
	local standsIn = if player.Character then Spawning.RegionAt((player.Character :: Model):GetPivot().Position) else nil
	check("the player stands in their region", standsIn ~= nil and standsIn == entrant(player.UserId).Region, `{standsIn} / {entrant(player.UserId).Region}`)

	-- scores: the player leads; AI hunter -i gets 10 i
	ScoreService.Add(player, "Objective", 500, "smoke")
	for _, id in all do
		if id < 0 then
			ScoreService.Add(id, "Objective", 10 * -id, "smoke")
		end
	end
	check("AI hunters have no body in the phases", MatchConfig.AiBodies.Phases or MatchService.Kill(-1) == false)
	check("a death is recorded", killAndWait(player.UserId))
	check("and revives after the rule's delay", waitUntil(function()
		return entrant(player.UserId).Alive
	end, rule.Revival.Delay + 3))

	skipTo(S.PhaseResolve, 1)
	check("no cull after phase 1", #ParticipantService.Eligible() == 8, `{#ParticipantService.Eligible()} left`)
	skipTo(S.RegionChoice, 2)
	skipTo(S.Phase, 2)
	skipTo(S.PhaseResolve, 2)
	check("cull after phase 2: 8 → 6", #ParticipantService.Eligible() == 6)
	check("the lowest two are out, placed 8th and 7th", entrant(-1).Culled and entrant(-1).Placement == 8 and entrant(-2).Placement == 7,
		`{entrant(-1).Placement} / {entrant(-2).Placement}`)
	skipTo(S.RegionChoice, 3)
	skipTo(S.Phase, 3)
	skipTo(S.PhaseResolve, 3)
	local finalists = ParticipantService.Eligible()
	table.sort(finalists)
	check("cull after phase 3: 6 → 3", #finalists == 3 and table.find(finalists, player.UserId) ~= nil and table.find(finalists, -7) ~= nil and table.find(finalists, -6) ~= nil,
		table.concat(finalists, " "))

	MatchService.Skip()
	check("reaches FinalSetup", reach(S.FinalSetup))
	check("finalists get the rule's lives", entrant(-6).Lives == rule.Final.Lives and entrant(player.UserId).Lives == rule.Final.Lives)
	check("and the HP bonus from Renown (D2)", player:GetAttribute(PlayerState.Attr.HpBonus) == Rewards.FinalHpBonus(rule, 500), tostring(player:GetAttribute(PlayerState.Attr.HpBonus)))
	skipTo(S.Final)
	task.wait(1.5)
	check("the final is in the arena", player.Character ~= nil and (player.Character :: Model):GetPivot().Position.Z < -800)

	check("a first defeat costs a life", killAndWait(-6) and waitUntil(function()
		return entrant(-6).Lives == rule.Final.Lives - 1
	end, 2))
	check("and the finalist comes back", waitUntil(function()
		return entrant(-6).Alive
	end, rule.Revival.Delay + 3))
	killAndWait(-6)
	check("the second eliminates: 3rd place", waitUntil(function()
		return entrant(-6).Placement == 3
	end, 3), tostring(entrant(-6).Placement))
	killAndWait(-7)
	waitUntil(function()
		return entrant(-7).Alive
	end, rule.Revival.Delay + 3)
	killAndWait(-7)
	check("the last opponent out places 2nd", waitUntil(function()
		return entrant(-7).Placement == 2
	end, 3))
	check("one winner, then Results", reach(S.Results) and entrant(player.UserId).Placement == 1)

	local expected = Rewards.Bloodgems(rule, { Placement = 1, Score = 500, PlayerKills = 0 })
	check("Bloodgems paid by the formula", profile.Data.Bloodgems - gemsBefore == expected, `{profile.Data.Bloodgems - gemsBefore} / {expected}`)
	check("and only once", PlayerHandlerData.SettleMatch(player, MatchService.MatchId(), expected) == false)

	-- leave the Test store as it was
	profile.Data.Bloodgems = gemsBefore
	profile.Data.Stats = statsBefore
	for i, award in profile.Data.MatchAwards do
		if award.Id == MatchService.MatchId() then
			table.remove(profile.Data.MatchAwards, i)
			break
		end
	end
	player:SetAttribute(PlayerState.Attr.HpBonus, nil)

	table.insert(lines, 1, `MATCH SMOKE {if failed == 0 then "PASSED" else "FAILED"}: {passed} passed, {failed} failed`)
	return table.concat(lines, "\n")
end

return Smoke

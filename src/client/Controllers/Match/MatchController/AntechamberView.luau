--!strict
-- AntechamberView (MatchController): what the Antechamber screen shows (UI/Match/Antechamber) while the match
-- gathers: the hunt's card and rules, what's happening (gathering, counting down, joins closed), the count or the
-- countdown, who takes the empty seats, the roster.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local MatchConfig = require(Shared.Config.Match)
local MatchState = require(Shared.Match.MatchState)
local Snapshot = require(script.Parent.Snapshot)

local S = MatchState.States

local AntechamberView = {}

local function plural(n: number, word: string): string
	return `{n} {word}{if n == 1 then "" else "s"}`
end

function AntechamberView.Build(s: Snapshot.Snapshot, map: any, stepOutKey: string?): any
	local roster = {}
	for _, entrant in s.Field do
		table.insert(roster, { Name = entrant.Name, Class = entrant.Class, Ai = entrant.Ai })
	end
	local seats = MatchConfig.Lobby.MaxPlayers
	local empty = seats - #s.Field
	local counting = s.State == S.Countdown
	local minimum = MatchConfig.Lobby.MinPlayers
	return {
		Map = if map then map.DisplayName else "",
		Mode = MatchConfig.ModeName,
		Rule = `{s.Rule.DisplayName} rules · {s.Rule.Summary}`,
		Status = if s.Locked then "Joins are closed" elseif counting then "The hunt begins" else "Gathering hunters",
		Counter = if counting then Snapshot.Clock(s.Left) else `{#s.Field} / {seats}`,
		Urgent = counting and s.Left <= MatchConfig.Lobby.LockAt,
		Note = if not counting then `The hunt begins once {plural(minimum, "hunter")} {if minimum == 1 then "is" else "are"} here.`
			elseif empty <= 0 then "Every seat is taken."
			elseif s.Locked then `The hunt begins with these hunters. AI hunters take the {plural(empty, "empty seat")}.`
			else `{plural(empty, "seat")} still open. AI hunters take them when the hunt begins.`,
		Roster = roster,
		Seats = seats,
		StepOutKey = if s.Dressed then stepOutKey else nil,
	}
end

return AntechamberView

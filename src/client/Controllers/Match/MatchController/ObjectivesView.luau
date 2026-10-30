--!strict
-- ObjectivesView (MatchController): the checklist lines for this moment of the hunt (Definitions/Objectives), ticked
-- from state the client can see: your level and pact, and your standing against the cut at this phase's end. A line
-- that needs a world feature says where it is until it's done ("Kurogane · The Cloister").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Objectives = require(Shared.Definitions.Objectives)
local Culling = require(Shared.Match.Culling)
local MatchState = require(Shared.Match.MatchState)
local EntityState = require(Shared.Simulation.EntityState)
local PlayerState = require(Shared.Simulation.PlayerState)
local Snapshot = require(script.Parent.Snapshot)

local S = MatchState.States

local ObjectivesView = {}

-- Where the first feature of `kind` is: "<its name> · <region>", or just the region; nil when the map has none.
local function whereIs(s: Snapshot.Snapshot, kind: string): string?
	for _, region in s.Regions do
		for _, feature in region.Features do
			if feature.Kind == kind then
				return if feature.Label ~= "" then `{feature.Label} · {region.Name}` else region.Name
			end
		end
	end
	return nil
end

-- The lines to show now, or nil outside the phases and the final.
function ObjectivesView.Build(s: Snapshot.Snapshot): { any }?
	local me = s.Me
	if not me or not me.Eligible then
		return nil
	end
	local defs: { any }? = nil
	if s.State == S.Phase then
		defs = Objectives.Phases[s.Phase] or (if table.find(s.Rule.CullAfter, s.Phase) then Objectives.Culling else Objectives.Default)
	elseif s.State == S.Final or s.State == S.FinalSetup then
		defs = Objectives.Final
	end
	if not defs then
		return nil
	end
	local player = Players.LocalPlayer
	local level = if player.Character then EntityState.Number(player.Character, EntityState.Attr.Level, 1) else 1
	local ranked = Snapshot.Standing(s.Field)
	local rank = 0
	for i, entrant in ranked do
		if entrant.Id == me.Id then
			rank = i
		end
	end
	local keep = Culling.KeepCount(s.Rule, s.Phase, s.Entrants, #ranked)
	local lines = {}
	for _, def in defs do
		local where = if def.Needs then whereIs(s, def.Needs) else nil
		if def.Needs and not where then
			continue
		end
		local done, detail = false, nil
		if def.Check == "Level" then
			done = level >= def.Value
			detail = if done then nil else `level {level} of {def.Value}`
		elseif def.Check == "Pact" then
			done = player:GetAttribute(PlayerState.Attr.ShinigamiId) ~= nil
			detail = if done then nil else where
		elseif def.Check == "AboveCut" then
			done = rank > 0 and rank <= keep
			detail = `rank {rank} · the top {keep} go on`
		end
		table.insert(lines, { Text = def.Text, Detail = detail, Done = done })
	end
	return lines
end

return ObjectivesView

--!strict
-- IntermissionView (MatchController): builds what the intermission screen shows (UI/Match/Intermission) from the
-- snapshot, for its three modes:
--   Choose: before a phase, where to begin (the region choice's deadline, live "2 of 3 places taken");
--   Rise: dead in a phase, where to come back (the revival countdown, where you fell);
--   Browse: the map on demand during a phase (where you stand; no choosing).
-- Everything it says comes from the rule, the map definition and the replicated state: the entrants per phase are
-- the rule's culls, the marks are the world's markers (Atlas), the blurbs the map's.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Culling = require(Shared.Match.Culling)
local MatchState = require(Shared.Match.MatchState)
local Numerals = require(Shared.Util.Numerals)
local Snapshot = require(script.Parent.Snapshot)

local S = MatchState.States
local F = MatchState.Features

local IntermissionView = {}

export type Mode = "Choose" | "Rise" | "Browse"

-- The road: each phase with how many enter it (the rule's culls applied to this match's field), then the final.
local function strip(s: Snapshot.Snapshot, mode: Mode): { any }
	local rule = s.Rule
	local nodes = {}
	local entering = s.Entrants
	-- the phase being chosen for or played: lit; earlier ones are behind you
	local current = s.Phase
	for i = 1, #rule.Phases do
		table.insert(nodes, {
			Label = Numerals.Roman(i),
			Count = entering,
			State = if i < current then "Past" elseif i == current then "Next" else "Later",
		})
		entering = Culling.KeepCount(rule, i, s.Entrants, entering)
	end
	table.insert(nodes, { Label = "", Count = entering, State = "Later", Final = true })
	return nodes
end

local function standings(s: Snapshot.Snapshot): any
	local ranked = Snapshot.Standing(s.Field)
	local rows = {}
	for rank, entrant in ranked do
		table.insert(rows, { Rank = rank, Name = entrant.Name, Score = entrant.Score, You = s.Me ~= nil and entrant.Id == s.Me.Id, Ai = entrant.Ai })
	end
	-- the cut at the end of the phase ahead, when it has one
	local cut = if table.find(s.Rule.CullAfter, s.Phase) then Culling.KeepCount(s.Rule, s.Phase, s.Entrants, #ranked) else nil
	return {
		Name = if s.Me then s.Me.Name else "",
		Score = if s.Me then s.Me.Score else 0,
		Rows = rows,
		Cut = cut,
	}
end

-- The first phase with a ritual site, for "opens in phase II".
local function ritualPhase(rule: any): number?
	for i, phase in rule.Phases do
		if phase.Ritual then
			return i
		end
	end
	return nil
end

-- What the right panel says about each region.
local function details(s: Snapshot.Snapshot, mode: Mode, chosen: string?, map: any): { [string]: any }
	local out = {}
	local ritual = ritualPhase(s.Rule)
	for _, region in s.Regions do
		local zone = map and map.Zones[region.Id]
		local lines = {}
		local packs: { [string]: number } = {}
		for _, feature in region.Features do
			if feature.Kind == F.Pact then
				table.insert(lines, { Kind = feature.Kind, Text = `Pact circle · {feature.Label}` })
			elseif feature.Kind == F.Ritual then
				table.insert(lines, { Kind = feature.Kind, Text = if ritual then `Ritual site · opens in phase {Numerals.Roman(ritual)}` else "Ritual site" })
			else
				local key = feature.Kind .. "|" .. feature.Label
				packs[key] = (packs[key] or 0) + feature.Count
			end
		end
		for key, count in packs do
			local kind, label = string.match(key, "^(.-)|(.*)$")
			table.insert(lines, { Kind = kind, Text = if count > 1 then `{label} · {count}` else label :: string })
		end
		table.sort(lines, function(a, b)
			return a.Text < b.Text
		end)
		local hunters, full = nil, false
		if mode == "Choose" then
			full = region.Capacity > 0 and region.Chosen >= region.Capacity and region.Id ~= chosen
			hunters = if full then "Full: a choice here starts you elsewhere" else `{region.Chosen} of {region.Capacity} places taken`
		else
			local here = 0
			for _, entrant in s.Field do
				if entrant.Alive and entrant.Region == region.Id then
					here += 1
				end
			end
			hunters = `{here} hunter{if here == 1 then "" else "s"} here now`
		end
		out[region.Id] = {
			Name = region.Name,
			District = zone and zone.District,
			Blurb = zone and zone.Blurb,
			Lines = lines,
			Hunters = hunters,
			Full = full,
			Empty = "",
		}
	end
	return out
end

function IntermissionView.Build(s: Snapshot.Snapshot, mode: Mode, chosen: string?, you: Vector3?, map: any): any
	local seconds, progress, caption = nil, 0, ""
	if mode == "Choose" then
		seconds = s.Left
		progress = math.clamp((s.Now - s.StartedAt) / math.max(0.001, s.Deadline - s.StartedAt), 0, 1)
		caption = "Until the hunt resumes"
	elseif mode == "Rise" and s.Me then
		local delay = s.Rule.Revival.Delay
		seconds = math.max(0, s.Me.RevivalAt - s.Now)
		progress = 1 - math.clamp(seconds / math.max(0.001, delay), 0, 1)
		caption = "Until you rise"
	end
	local keys = {}
	for i = 1, #s.Regions do
		table.insert(keys, tostring(i))
	end
	local here = you and Snapshot.RegionAt(s.Regions, you)
	return {
		Mode = mode,
		Seconds = seconds,
		Progress = progress,
		TimerCaption = caption,
		Standings = standings(s),
		Strip = strip(s, mode),
		Chosen = if mode == "Browse" then nil else chosen,
		You = you,
		Regions = details(s, mode, chosen, map),
		Empty = if mode == "Browse" then "Point at a region to read it." else "Point at a region to read it, then choose it.",
		Instruction = if mode == "Choose" then "Choose where to begin" elseif mode == "Rise" then "Choose where to rise" else (if map then map.DisplayName else ""),
		Fallback = if mode == "Choose" then "Without a choice you start in a random region with room. A full region sends you to another."
			elseif mode == "Rise" then "Without a choice you rise in the region where you fell."
			else (if here then `You are in {here.Name}.` else "You are between regions."),
		Hints = if mode == "Browse" then { { "M", "Close the map" } } else { { "Click", "Choose" }, { table.concat(keys, " "), "By number" } },
	}
end

-- Which mode the intermission is in for this snapshot (nil: closed). `browsing`: the player opened the map.
function IntermissionView.ModeFor(s: Snapshot.Snapshot, browsing: boolean, riseReady: boolean): Mode?
	local me = s.Me
	if s.State == S.RegionChoice and me and me.Eligible then
		return "Choose"
	end
	if s.State == S.Phase and me and me.Eligible and not me.Alive and me.RevivalAt > 0 and riseReady then
		return "Rise"
	end
	if browsing and s.State == S.Phase and me and me.Alive then
		return "Browse"
	end
	return nil
end

return IntermissionView

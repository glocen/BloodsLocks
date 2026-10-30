--!strict
-- MatchState: the replicated match state clients read (the server writes it; Match places only).
--   ReplicatedStorage.MatchState            (a Folder carrying the match's attributes: Match below)
--   ReplicatedStorage.MatchState.Participants.<id>   (a Configuration per entrant, attributes below)
-- A participant id is a player's UserId, or a negative number for an AI hunter. Screens read entrants from here,
-- never from characters or world markers, which may be missing or not streamed in. Always go through Attr.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatchState = {}

MatchState.FolderName = "MatchState"
MatchState.ParticipantsName = "Participants"
MatchState.HuntersFolder = "BL_Hunters" -- workspace folder of AI hunters' bodies (each fights for its participant id)

-- The match's lifecycle, in order (MatchService). "Idle": nothing running (Studio before MatchStart).
MatchState.States = {
	Idle = "Idle",
	Waiting = "Waiting", -- in the Antechamber until enough players arrive
	Countdown = "Countdown",
	Intro = "Intro",
	RegionChoice = "RegionChoice", -- pick where to start the next phase
	Phase = "Phase", -- phases 1..n (the Phase attribute says which)
	PhaseResolve = "PhaseResolve", -- awards, standings, culls
	FinalSetup = "FinalSetup",
	Final = "Final",
	Results = "Results",
	Return = "Return",
}

-- Attributes on the MatchState folder itself.
MatchState.Match = {
	State = "State",
	Phase = "Phase", -- the current or upcoming phase index (0 before phase 1)
	Deadline = "Deadline", -- time() the current state ends (0: no deadline)
	StartedAt = "StartedAt", -- time() the current state began
	Rule = "Rule", -- Definitions/Rules id
	Entrants = "Entrants", -- seats filled when the countdown ended (players + AI hunters)
	Locked = "Locked", -- joins closed
	SuddenDeath = "SuddenDeath",
	Winner = "Winner", -- participant id, once decided
	Dressed = "Dressed", -- the Antechamber's art is finished: players may step out of its screen into the room
}

MatchState.Participant = {
	Name = "Name",
	Ai = "Ai", -- an AI hunter filling a seat (owner decision D11)
	Class = "Class",
	Eligible = "Eligible", -- can still place: not culled, not left
	Alive = "Alive",
	Culled = "Culled",
	Left = "Left",
	Lives = "Lives", -- final lives (0 before the final)
	Region = "Region", -- zone id of the current or chosen region ("" for none)
	Kills = "Kills", -- player and AI-hunter kills
	Deaths = "Deaths",
	Score = "Score", -- the Renown total
	Placement = "Placement", -- 0 until decided
	RevivalAt = "RevivalAt", -- time() a dead entrant comes back (0 when alive or out)
	FellAt = "FellAt", -- Vector3: where the body fell last (the revival map marks it)
	Moved = "Moved", -- the region asked for was full this phase: the entrant started elsewhere
	ProtectedUntil = "ProtectedUntil", -- time() spawn protection ends (0: not protected; attacking ends it early)
}

-- The map's regions for screens (Atlas): MatchState.Regions.<zoneId> (attributes below) with one "Box" child per
-- volume (Min, Max: Vector3) and one "Feature" child per thing worth marking on the map (Kind, Position, Label).
-- And MatchState.Relief: a light copy of the district's visible geometry (or the world's authored map relief).
MatchState.RegionsName = "Regions"
MatchState.ReliefName = "Relief"
MatchState.BoxName = "Box"
MatchState.FeatureName = "Feature"
MatchState.Region = {
	DisplayName = "DisplayName",
	Min = "Min",
	Max = "Max",
	Chosen = "Chosen", -- how many entrants asked for it this region choice (live)
	Capacity = "Capacity", -- how many it takes (ceil(entrants / regions) + 1)
	Kind = "Kind", -- a feature's kind (MatchState.Features)
	Position = "Position", -- a feature's place in the world
	Label = "Label", -- a feature's name ("Kurogane", "Wretch")
	Count = "Count", -- how many (an enemy group's size)
}
-- What the map marks inside regions.
MatchState.Features = { Pact = "Pact", Ritual = "Ritual", Fodder = "Fodder", Heavy = "Heavy" }

-- Client: the participants folder, or nil if this place has no match (waits up to `timeout` seconds).
function MatchState.WaitParticipants(timeout: number): Folder?
	local root = ReplicatedStorage:WaitForChild(MatchState.FolderName, timeout)
	return if root then root:WaitForChild(MatchState.ParticipantsName, timeout) :: Folder? else nil
end

return MatchState

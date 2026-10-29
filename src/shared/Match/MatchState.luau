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
	Rule = "Rule", -- Definitions/Rules id
	Entrants = "Entrants", -- seats filled when the countdown ended (players + AI hunters)
	Locked = "Locked", -- joins closed
	SuddenDeath = "SuddenDeath",
	Winner = "Winner", -- participant id, once decided
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
}

-- Client: the participants folder, or nil if this place has no match (waits up to `timeout` seconds).
function MatchState.WaitParticipants(timeout: number): Folder?
	local root = ReplicatedStorage:WaitForChild(MatchState.FolderName, timeout)
	return if root then root:WaitForChild(MatchState.ParticipantsName, timeout) :: Folder? else nil
end

return MatchState

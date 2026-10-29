--!strict
-- MatchState: the replicated match state clients read (the server writes it; Match places only).
--   ReplicatedStorage.MatchState            (a Folder: the match's own attributes come with MatchService, L1)
--   ReplicatedStorage.MatchState.Participants.<id>   (a Configuration per entrant, attributes below)
-- A participant id is a player's UserId, or a negative number for an AI hunter. Screens read entrants from here,
-- never from characters or world markers, which may be missing or not streamed in. Always go through Attr.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatchState = {}

MatchState.FolderName = "MatchState"
MatchState.ParticipantsName = "Participants"

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
}

-- Client: the participants folder, or nil if this place has no match (waits up to `timeout` seconds).
function MatchState.WaitParticipants(timeout: number): Folder?
	local root = ReplicatedStorage:WaitForChild(MatchState.FolderName, timeout)
	return if root then root:WaitForChild(MatchState.ParticipantsName, timeout) :: Folder? else nil
end

return MatchState

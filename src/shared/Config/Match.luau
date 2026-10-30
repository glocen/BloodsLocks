--!strict
-- Match settings that don't depend on the rule: the waiting room inside a reserved match server, and the Studio fast
-- profile. Phase lengths, culls, the final and rewards are per rule (Definitions/Rules, RuleDefaults). *(tune)*

return {
	Lobby = {
		MaxPlayers = 8,
		-- the countdown starts once this many are in the waiting room, and cancels below it. 1 for the proof of concept:
		-- a single real player starts a hunt and AI hunters take every other seat (owner, 2026-10-29, amending D11's 2)
		MinPlayers = 1,
		Countdown = 30, -- seconds
		FullCountdown = 10, -- the countdown shortens to this when the lobby is full
		LockAt = 5, -- seconds left when joins close and the server delists itself
	},

	-- Owner decision D11 (2026-10-29): a match starts with as few as MinPlayers real players, and AI hunters fill
	-- every seat left up to Lobby.MaxPlayers, so each match has a full field. Their movement and judgement come later;
	-- they are participants like anyone else (score, standings, culls, the final).
	AiHunters = {
		Fill = true,
		-- our own names, given out in order (ids -1, -2, ...)
		Names = {
			"Ambrose Vane", "Cordelia Ashgrove", "Silas Wren", "Margot Hollow",
			"Edmund Thorne", "Isolde Crane", "Bartholomew Pike", "Rosalind Mire",
		},
	},

	-- Studio: the match only starts on BL_Debug "MatchStart" (so a plain playtest keeps the self-test environment);
	-- live match servers start in Waiting at once.
	StudioAutoStart = false,
	SpawnHeight = 3, -- studs a body's root stands above a spawn marker (markers sit on the floor)

	-- Studio only: these lengths replace the rule's, so a whole match runs in a few minutes (with bot entrants, solo).
	StudioFast = {
		MinPlayers = 1, -- a solo playtest can run a whole match (AI hunters fill the rest)
		Countdown = 8,
		Intro = 3,
		RegionChoice = { First = 8, Later = 6 },
		Phases = { 60, 45, 45 },
		PhaseResolve = 4,
		FinalSetup = 2,
		FinalTimeCap = 60,
		Results = 6,
	},
}

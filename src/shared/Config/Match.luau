--!strict
-- Match settings that don't depend on the rule: the waiting room inside a reserved match server, and the Studio fast
-- profile. Phase lengths, culls, the final and rewards are per rule (Definitions/Rules, RuleDefaults). *(tune)*

return {
	Lobby = {
		MaxPlayers = 8,
		MinPlayers = 2, -- the countdown starts once this many are in the waiting room, and cancels below it
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

	-- Studio only: these lengths replace the rule's, so a whole match runs in a few minutes (with bot entrants, solo).
	StudioFast = {
		Countdown = 8,
		Intro = 3,
		RegionChoice = { First = 8, Later = 6 },
		Phases = { 60, 45, 45 },
		PhaseResolve = 4,
		FinalTimeCap = 60,
		Results = 6,
	},
}

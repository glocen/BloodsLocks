--!strict
-- The match score. Its player-facing name is ours ("Renown", a working name until the owner picks one; Duskbloods
-- calls theirs Virtue). The server keeps a ledger: every gain is an entry with its source, amount and time, so
-- rankings, tie-breaks (first to reach a total wins) and later culls can be audited, not just a running total.

return {
	DisplayName = "Renown",
	-- every source that can award score; ledger entries name one of these
	Sources = {
		EnemyKill = "EnemyKill", -- the enemy definition's Score value goes to the killer
		PlayerKill = "PlayerKill", -- later: ritual sites (phases 2 and 3)
		Objective = "Objective", -- later: pledges, lanterns, events
		Commendation = "Commendation", -- later: phase-end awards
	},
	PlayerKill = 30, -- later
}

--!strict
-- PlayerState: the attribute schema on the Player instance (not the character). The server writes these; clients
-- and the simulation read them. They outlive respawns: the class from the profile, the Shinigami pact for the HUD,
-- boot status. Always go through Attr.

local A = {
	Class = "class", -- class id mirrored from the profile's SelectedClass (ClassService)
	ClientReady = "ClientReady", -- the client finished booting (PlayerService)
	-- in-match progression and score (ProgressionService, ScoreService); Spawn applies Level to the character
	Level = "lv",
	Xp = "xp", -- progress inside the current level
	Score = "sc", -- Renown total
	-- the Shinigami pact (ShinigamiService), read by the HUD card
	ShinigamiId = "shId",
	ShinigamiLevel = "shLv",
	ShinigamiHp = "shHp", -- 0..1
	ShinigamiOut = "shOut", -- summoned
	ShinigamiCooldown = "shCd", -- time() the resummon cooldown ends
}

return {
	Attr = A,
}

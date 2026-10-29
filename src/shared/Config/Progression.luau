--!strict
-- In-match progression (resets every match): experience from kills fills levels; each level makes the character
-- stronger. Separate from the score (Config.Score), which decides placement. Every value is a starting point *(tune)*.

return {
	MaxLevel = 20, -- ChatGPT's footage shows level 20 late in a match (plan section 3 said 15)
	-- XP to go from level L to L + 1: XpBase + XpPerLevel * (L - 1)
	XpBase = 50,
	XpPerLevel = 30,
	-- per level above 1
	HealthPercent = 0.04, -- +4% max HP
	DamagePercent = 0.02, -- +2% damage dealt
	-- stamina per level: Config.Stamina.PerLevel
}

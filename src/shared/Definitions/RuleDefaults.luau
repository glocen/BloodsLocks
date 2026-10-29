--!strict
-- RuleDefaults: every match rule (Definitions/Rules/<Id>) starts from this table; a rule file only lists what it changes.
-- Registry merges them (nested tables merge key by key; lists are replaced whole) and validates the result.
-- Owner decisions behind these values: engineering-plan section 3 (D1-D10). Times are seconds. Every number *(tune)*.

return {
	Playable = true, -- false: listed in the Hunt tab as sealed, refused by the server
	Alliances = "Standard", -- "Standard" (petitions allowed), "None", or "Bound" (fixed duos)
	TeamSize = 1,

	Intro = 8,
	RegionChoice = { First = 20, Later = 15 },
	-- the phases before the final, in order; Ritual: a ritual site opens at Ritual.ActivateAt of the phase
	Phases = {
		{ Duration = 360, Ritual = false },
		{ Duration = 300, Ritual = true },
		{ Duration = 300, Ritual = true },
	},
	PhaseResolve = 8,
	CullAfter = { 2, 3 }, -- D1: the phases whose end culls (finalists left after the last one)
	Finalists = 3,
	Ritual = { ActivateAt = 0.4 }, -- fraction of the phase

	Revival = {
		Delay = 5,
		Protection = 3, -- seconds of spawn protection; attacking ends it early
		Separation = 60, -- studs a spawn tries to keep from other players
		TopUpHealUses = 2, -- D3: heal uses refill to this on death if below
	},

	Final = {
		Lives = 2,
		TimeCap = 240,
		HpBonusPerRenown = 0.001, -- D2: +0.1% max HP per Renown earned...
		HpBonusCap = 0.3, -- ...up to +30%
		SuddenDeath = { Lives = 1, DrainPerSecond = 0.01 }, -- D2: at TimeCap: one life each, lose 1% max HP a second
	},

	PlayerKill = { Renown = 30, RitualOnly = true }, -- D4

	-- Bloodgems at the end (plan section 3): participation + placement + floor(score / PerScore) + PerPlayerKill each,
	-- capped. D9: a participant who leaves early gets Participation only.
	Rewards = {
		Participation = 15,
		Placement = { 60, 40, 30 },
		OtherPlacement = 15,
		PerScore = 50,
		PerPlayerKill = 2,
		Cap = 150,
	},

	Results = 12,
}

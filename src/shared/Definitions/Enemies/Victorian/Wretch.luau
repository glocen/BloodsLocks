--!strict
-- Wretch: fodder. Lamplighters and night-watchmen the blood moon turned feral; they hunt in loose packs, rake with
-- broken nails and pounce from a distance. Fast to reach you, quick to die, but they hit hard (Duskbloods' mobs
-- punish carelessness). Shape of an enemy definition:
--   Tier: "Fodder" | "Heavy" | "Elite" | "Boss". Tint: placeholder body colour until the modelled version lands.
--   BaseHealth, WalkSpeed (patrol), ChaseSpeed, AggroRange (studs to notice a target), LeashRange (studs from its
--   spawn it will chase), AlertTime (seconds it turns and pauses before chasing: fair warning),
--   AttackInterval (seconds between attacks, ±20%), Telegraph (seconds of flash before each attack),
--   Attacks: { { Action, Range (studs it attacks from), Weight } }, Xp, Score (Renown), Respawn (seconds after its spawn
--   area is clear of players), CanBeSpellbound (a bite can turn it into a minion, later),
--   Actions (its own action definitions, same format as weapons).

return {
	Id = "Wretch",
	DisplayName = "Wretch",
	Tier = "Fodder",
	Tint = Color3.fromRGB(92, 78, 70),
	BaseHealth = 260,
	WalkSpeed = 8,
	ChaseSpeed = 19, -- a little faster than walking, slower than sprinting: you can always escape
	AggroRange = 45,
	LeashRange = 90,
	AlertTime = 0.6,
	AttackInterval = 1.8,
	Telegraph = 0.4,
	Attacks = {
		{ Action = "Enemy.Wretch.Rake", Range = 6, Weight = 3 },
		{ Action = "Enemy.Wretch.Pounce", Range = 12, Weight = 1 },
	},
	Xp = 25,
	Score = 5, -- Renown for the killer
	Respawn = 45,
	CanBeSpellbound = true,
	Actions = {
		["Enemy.Wretch.Rake"] = {
			Anim = "SaberLight1",
			Duration = 0.75,
			TrackUntil = 0.15,
			Hit = { From = 0.22, To = 0.34, Size = Vector3.new(6, 5, 6), Offset = CFrame.new(0, 0, -3), Damage = 70, Stagger = 12, Reaction = "Flinch" },
		},
		["Enemy.Wretch.Pounce"] = {
			Anim = "SaberLight4",
			Duration = 1.0,
			TrackUntil = 0.1,
			Lunge = { From = 0.12, To = 0.42, Speed = 30 },
			Hit = { From = 0.3, To = 0.46, Size = Vector3.new(6, 5, 7), Offset = CFrame.new(0, 0, -3.5), Damage = 95, Stagger = 20, Reaction = "Heavy" },
		},
	},
}

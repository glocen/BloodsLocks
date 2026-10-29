--!strict
-- Butcher: heavy. A slaughterhouse brute with a meat cleaver, slow and enormous. Long wind-ups you can read and
-- punish, but each blow takes a quarter of your health and staggers you. Shape: see Wretch.

return {
	Id = "Butcher",
	DisplayName = "Butcher",
	Tier = "Heavy",
	Tint = Color3.fromRGB(70, 34, 30),
	Scale = 1.35, -- bigger than a player
	BaseHealth = 1400,
	WalkSpeed = 6,
	ChaseSpeed = 13,
	AggroRange = 40,
	LeashRange = 70,
	AlertTime = 0.9,
	AttackInterval = 2.8,
	Telegraph = 0.7,
	Attacks = {
		{ Action = "Enemy.Butcher.Cleave", Range = 8, Weight = 2 },
		{ Action = "Enemy.Butcher.Overhead", Range = 7, Weight = 1 },
	},
	Xp = 60,
	Virtue = 20,
	Respawn = 90,
	CanBeSpellbound = false,
	Actions = {
		["Enemy.Butcher.Cleave"] = {
			Anim = "SaberStrong1",
			Duration = 1.3,
			TrackUntil = 0.25,
			Lunge = { From = 0.3, To = 0.5, Speed = 14 },
			Hit = { From = 0.45, To = 0.62, Size = Vector3.new(10, 6, 8), Offset = CFrame.new(0, 0, -4.5), Damage = 180, Stagger = 35, Reaction = "Heavy" },
		},
		["Enemy.Butcher.Overhead"] = {
			Anim = "SaberCharged",
			Duration = 1.7,
			TrackUntil = 0.4,
			Hit = { From = 0.75, To = 0.9, Size = Vector3.new(5, 8, 9), Offset = CFrame.new(0, 0, -4.5), Damage = 260, Stagger = 50, Reaction = "Heavy" },
		},
	},
}

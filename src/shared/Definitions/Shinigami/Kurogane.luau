--!strict
-- Kurogane ("black steel"): a melee Shinigami. A spectral swordsman bound by pact; follows its master and joins any
-- fight they're in. Tuning is a starting point. Shape of a Shinigami definition:
--   Role, BaseHealth, WalkSpeed, Reach (studs to start an attack), AttackInterval (seconds between attacks),
--   AggroRange (how far from the master it will chase), FollowDistance, ResummonCooldown (after dying),
--   Regen (fraction of max HP per second while dismissed or out of combat), Attacks (action ids, used in turn),
--   Skill (its special move: Action, UnlockLevel, Cooldown, MinRange/MaxRange to the target, Telegraph seconds),
--   Actions (its own action definitions, same format as weapons).

return {
	Id = "Kurogane",
	DisplayName = "Kurogane",
	Role = "Melee",
	BaseHealth = 600,
	WalkSpeed = 22,
	Reach = 7,
	AttackInterval = 1.4,
	AggroRange = 30,
	FollowDistance = 9,
	ResummonCooldown = 30,
	Regen = 0.02,
	Attacks = { "Shinigami.Kurogane.Slash1", "Shinigami.Kurogane.Slash2" },
	-- Gōka (hellfire): after a flash of red it drives its blade into the ground and a ring of fire bursts out,
	-- hitting every enemy around it once.
	Skill = { Action = "Shinigami.Kurogane.Goka", UnlockLevel = 3, Cooldown = 12, MinRange = 0, MaxRange = 8, Telegraph = 0.45 },
	Actions = {
		["Shinigami.Kurogane.Slash1"] = {
			Anim = "SaberLight1",
			Duration = 0.7,
			TrackUntil = 0.2,
			Hit = { From = 0.28, To = 0.38, Size = Vector3.new(7, 5, 6.5), Offset = CFrame.new(0, 0, -3.5), Damage = 40, Stagger = 12, Reaction = "Flinch" },
			ChainFrom = 0.7,
			DodgeCancelFrom = 0.7,
		},
		["Shinigami.Kurogane.Goka"] = {
			Anim = "SaberCharged",
			Fx = "FireNova", -- client effect played when the action starts (Client.Vfx)
			Duration = 1.0,
			TrackUntil = 0.05,
			Hit = { From = 0.22, To = 0.4, Size = Vector3.new(20, 8, 20), Offset = CFrame.new(0, -1, 0), Damage = 90, Stagger = 30, Reaction = "Heavy" },
			ChainFrom = 1.0,
			DodgeCancelFrom = 1.0,
		},
		["Shinigami.Kurogane.Slash2"] = {
			Anim = "SaberLight3",
			Duration = 0.8,
			TrackUntil = 0.22,
			Hit = { From = 0.32, To = 0.42, Size = Vector3.new(5, 7, 7.5), Offset = CFrame.new(0, 0, -4), Damage = 50, Stagger = 16, Reaction = "Flinch" },
			ChainFrom = 0.8,
			DodgeCancelFrom = 0.8,
		},
	},
}

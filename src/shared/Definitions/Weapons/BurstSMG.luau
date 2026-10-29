--!strict
-- Burst SMG: chip damage that builds stagger fast. Free aim at the crosshair, or at the lock-on target.
-- Hit.Ranged marks bullets: blockable, but a howl doesn't stagger a shooter.

return {
	Magazine = 24,
	Reload = 1.6, -- starts automatically when the magazine can't fit another burst
	Burst = "BurstSMG.Burst",
	Actions = {
		["BurstSMG.Burst"] = {
			Anim = "SMGBurst",
			Duration = 0.42,
			TrackUntil = 0.42, -- keeps turning with your aim for the whole burst
			Shots = { 0.04, 0.1, 0.16, 0.22 },
			Range = 110,
			Spread = 1.2, -- degrees
			Hit = { From = 0.04, To = 0.23, Damage = 14, Stagger = 5, Reaction = "None", Ranged = true },
			ChainFrom = 0.42,
			DodgeCancelFrom = 0.1,
			WalkSpeed = 10,
		},
	},
}

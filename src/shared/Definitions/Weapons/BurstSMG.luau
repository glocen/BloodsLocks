--!strict
-- Burst SMG: chip damage that builds stagger fast. Free aim at the crosshair, or at the lock-on target.
-- Hit.Ranged marks bullets: blockable, but a howl doesn't stagger a shooter.
-- Spread blooms through a burst (degrees): shot n flies somewhere in a cone of min(Base + (n - 1) * Bloom, Max), so the
-- first round goes where you aim and the later ones scatter. Up close a burst lands whole; at 30 studs about 3 of 4
-- rounds land on an R6 body, at 60 about 2 (docs/combat-rework.md).

return {
	Model = "SMG", -- Shared.Assets.Weapons: the machine pistol (tools/blender/smg.py), held in the left hand
	Hand = "Left",
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
			Spread = { Base = 0.8, Bloom = 2.2, Max = 6.5 },
			Hit = { From = 0.04, To = 0.23, Damage = 14, Stagger = 5, Reaction = "None", Ranged = true },
			ChainFrom = 0.42,
			DodgeCancelFrom = 0.1,
			WalkSpeed = 10,
		},
	},
}

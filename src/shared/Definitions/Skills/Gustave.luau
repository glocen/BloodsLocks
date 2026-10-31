--!strict
-- Gustave skills. A skill is an action with charges: using one spends a charge, and charges come back one at a
-- time every Recharge seconds. UnlockLevel gates it by in-match level (everything is unlocked in the Manor).
--   Projectile: a server-simulated projectile spawned At seconds in, along the aim.
--   Beam: a channeled ray that hits every Interval seconds between From and To, along the aim.

return {
	Actions = {
		-- Blood Blade (internal id): a stroke of black ink flung from the hand between normal attacks. Builds stagger hard.
		["Gustave.BloodBlade"] = {
			Icon = "SableStroke", -- HUD emblem (Theme.Images)
			DisplayName = "Sable Stroke", -- the owner's pick (2026-10-31, after Crimson Crescent): never the reference's name
			Anim = "BloodBlade",
			Duration = 0.5,
			TrackUntil = 0.16,
			Projectile = {
				At = 0.18,
				Speed = 110,
				Range = 80,
				Radius = 1.4,
				Visual = "BloodBlade",
				Hit = { Damage = 70, Stagger = 14, Reaction = "Flinch", Ranged = true },
			},
			DodgeCancelFrom = 0.32,
			WalkSpeed = 6,
			Charges = 2,
			Recharge = 5,
			UnlockLevel = 1,
		},
		-- Light Beam: a beam from the crystal on the weapon. Multi-hit, but you stand still while channeling.
		["Gustave.LightBeam"] = {
			Icon = "Glint",
			DisplayName = "Light Beam",
			Anim = "LightBeam",
			Duration = 1.7,
			TrackUntil = 1.55, -- you can turn (aim) while channeling, but not move
			Beam = { From = 0.35, To = 1.55, Interval = 0.12, Range = 60 },
			Hit = { Damage = 9, Stagger = 3, Reaction = "None", Ranged = true },
			DodgeCancelFrom = 1.55,
			WalkSpeed = 0,
			Charges = 1,
			Recharge = 12,
			UnlockLevel = 5,
		},
	},
}

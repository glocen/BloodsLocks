--!strict
-- Saber moveset. All times are seconds from the start of the action.
--   TrackUntil: the attacker can still turn (toward movement or the lock-on target) until this time.
--   Lunge: forward drive during the swing.
--   Hit: the active window, MuchachoHitbox box relative to the root part (-Z = forward).
--   ChainFrom: a buffered press of the action's Button (default Attack) starts Next from here.
--   DodgeCancelFrom: a dodge may cut the recovery.
--   GuardDrain: multiplies the stamina a blocked hit drains (heavy blows crush guards).
--   Charge: still holding Button at At (before the hit) switches into the Into action.
--   Hold: a charge stance. Releasing Button (no sooner than Min) or reaching Duration starts Release. Fx names the
--   client's charge telegraph (Client.Vfx).

return {
	Light = "Saber.Light1", -- first hit of the light chain
	Strong = "Saber.Strong1", -- first hit of the strong chain (hold to charge)
	Model = "Saber",
	Actions = {
		["Saber.Light1"] = {
			Anim = "SaberLight1",
			Duration = 0.5,
			TrackUntil = 0.12,
			Lunge = { From = 0.04, To = 0.16, Speed = 20 },
			Hit = { From = 0.14, To = 0.24, Size = Vector3.new(7, 5, 6.5), Offset = CFrame.new(0, 0, -3.5), Damage = 55, Stagger = 8, Reaction = "Flinch" },
			ChainFrom = 0.24,
			DodgeCancelFrom = 0.26,
			Next = "Saber.Light2",
		},
		["Saber.Light2"] = {
			Anim = "SaberLight2",
			Duration = 0.5,
			TrackUntil = 0.1,
			Lunge = { From = 0.03, To = 0.14, Speed = 18 },
			Hit = { From = 0.12, To = 0.22, Size = Vector3.new(7, 5, 6.5), Offset = CFrame.new(0, 0, -3.5), Damage = 60, Stagger = 8, Reaction = "Flinch" },
			ChainFrom = 0.22,
			DodgeCancelFrom = 0.24,
			Next = "Saber.Light3",
		},
		["Saber.Light3"] = {
			Anim = "SaberLight3",
			Duration = 0.58,
			TrackUntil = 0.12,
			Lunge = { From = 0.05, To = 0.18, Speed = 22 },
			Hit = { From = 0.16, To = 0.27, Size = Vector3.new(5, 7, 7.5), Offset = CFrame.new(0, 0, -4), Damage = 65, Stagger = 10, Reaction = "Flinch" },
			ChainFrom = 0.27,
			DodgeCancelFrom = 0.3,
			Next = "Saber.Light4",
		},
		["Saber.Light4"] = {
			Anim = "SaberLight4",
			Duration = 0.8,
			TrackUntil = 0.16,
			Lunge = { From = 0.1, To = 0.26, Speed = 30 },
			Hit = { From = 0.22, To = 0.34, Size = Vector3.new(8, 6, 8), Offset = CFrame.new(0, 0, -4), Damage = 95, Stagger = 22, Reaction = "Heavy" },
			ChainFrom = 0.8, -- the finisher doesn't chain; the next press starts a new combo after it ends
			DodgeCancelFrom = 0.42,
		},

		-- Strong: slower and heavier, built to fill stagger and crush guards. Hold to charge.
		["Saber.Strong1"] = {
			Anim = "SaberStrong1",
			Button = "Strong",
			Duration = 0.95,
			TrackUntil = 0.26,
			Lunge = { From = 0.24, To = 0.38, Speed = 26 },
			Hit = { From = 0.38, To = 0.5, Size = Vector3.new(8, 6, 8), Offset = CFrame.new(0, 0, -4), Damage = 110, Stagger = 28, Reaction = "Heavy", GuardDrain = 1.6 },
			Charge = { At = 0.3, Into = "Saber.StrongCharge" },
			ChainFrom = 0.55,
			DodgeCancelFrom = 0.6,
			Next = "Saber.Strong2",
		},
		["Saber.Strong2"] = {
			Anim = "SaberStrong2",
			Button = "Strong",
			Duration = 1.0,
			TrackUntil = 0.24,
			Lunge = { From = 0.22, To = 0.36, Speed = 28 },
			Hit = { From = 0.36, To = 0.48, Size = Vector3.new(6, 8, 8.5), Offset = CFrame.new(0, 0, -4.25), Damage = 120, Stagger = 30, Reaction = "Heavy", GuardDrain = 1.6 },
			Charge = { At = 0.3, Into = "Saber.StrongCharge" },
			ChainFrom = 1.0, -- ends the strong chain
			DodgeCancelFrom = 0.62,
		},
		["Saber.StrongCharge"] = {
			Anim = "SaberCharge",
			Button = "Strong",
			Duration = 1.1, -- held this long, the charged blow releases on its own
			TrackUntil = 1.1,
			WalkSpeed = 0,
			Hold = { Min = 0.35, Release = "Saber.Charged", Fx = "BloodCharge" },
			ChainFrom = 1.1,
			DodgeCancelFrom = 0, -- a dodge can abandon the charge
		},
		["Saber.Charged"] = {
			Anim = "SaberCharged",
			Button = "Strong",
			Duration = 1.0,
			TrackUntil = 0.08,
			Lunge = { From = 0.04, To = 0.2, Speed = 36 },
			Hit = { From = 0.14, To = 0.28, Size = Vector3.new(9, 7, 9.5), Offset = CFrame.new(0, 0, -4.75), Damage = 190, Stagger = 55, Reaction = "Heavy", GuardDrain = 2.5 },
			ChainFrom = 1.0,
			DodgeCancelFrom = 0.55,
		},
	},
}

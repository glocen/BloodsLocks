--!strict
-- Actions every class has: the howl (guard + strong) and the bite.

return {
	Actions = {
		-- Howl: deals no damage. A melee hit that lands during Window staggers the attacker instead.
		["Common.Howl"] = {
			Anim = "Howl",
			Duration = 0.6,
			TrackUntil = 0.05,
			Window = { From = 0.04, To = 0.3 },
			DodgeCancelFrom = 0.45,
			WalkSpeed = 0,
		},
		-- Bite: a short lunge. Only does anything to a staggered target: heavy damage, heals the biter,
		-- and ends the target's stagger. Against anything else it whiffs.
		["Common.Bite"] = {
			Anim = "Bite",
			Duration = 0.75,
			TrackUntil = 0.08,
			Lunge = { From = 0.02, To = 0.12, Speed = 26 },
			Hit = { From = 0.1, To = 0.22, Size = Vector3.new(4.5, 5, 4.5), Offset = CFrame.new(0, 0, -2.5), Damage = 180, Stagger = 0, Reaction = "Heavy", Bite = true, Heal = 0.12 },
			DodgeCancelFrom = 0.5,
			WalkSpeed = 0,
		},
	},
}

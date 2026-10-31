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
		-- Bite: a short lunge. Only a staggered target can be bitten: the bite seizes it into the hold below. Against
		-- anything else it whiffs. Damage is the whole bite's, Heal the share of the biter's max HP it drinks back.
		["Common.Bite"] = {
			Anim = "Bite",
			Duration = 0.75,
			TrackUntil = 0.08,
			Lunge = { From = 0.02, To = 0.12, Speed = 26 },
			Hit = { From = 0.1, To = 0.22, Size = Vector3.new(4.5, 5, 4.5), Offset = CFrame.new(0, 0, -2.5), Damage = 180, Stagger = 0, Reaction = "Heavy", Bite = true, Heal = 0.12 },
			DodgeCancelFrom = 0.5,
			WalkSpeed = 0,
		},
		-- The hold a bite turns into (Simulation/Bite; owner, 2026-10-31: "a bit long, both can't move, i-frames for
		-- both, the one who bites recovers HP"). Both bodies are locked and invulnerable while the biter drains the
		-- victim; the biter acts again at DodgeCancelFrom, when its i-frames end. Seize: the timeline, in seconds from
		-- the seize, and the hold's numbers.
		["Common.BiteHold"] = {
			Anim = "BiteHold",
			Duration = 2.75,
			TrackUntil = 0,
			DodgeCancelFrom = 2.55,
			WalkSpeed = 0,
			Seize = {
				Distance = 1.9, -- studs between the two roots while held
				Pull = 0.2, -- seconds the victim takes to be pulled to that distance
				Fangs = 0.55, -- the bite itself: the victim's flash
				FirstPulse = 0.85, -- the drain: HP flows from the victim to the biter in Pulses, PulseEvery apart
				PulseEvery = 0.3,
				Pulses = 5,
				DrainShare = 0.5, -- of the bite's damage, taken by the pulses (never below 1 HP); the rest lands at the release
				Release = 2.35, -- the biter throws the victim off: the rest of the damage, and a knockdown
				Throw = 6, -- studs the release throws the victim
				ThrowTurn = 25, -- degrees the throw turns to the biter's left, so the player's camera sees the body fly
				BreakDistance = 6, -- held bodies further apart than this (a teleport, a phase change) end the hold
				VictimClip = 3.3, -- seconds the victim's Bitten clip plays: the release plus the knockdown (Combat.Hitstun)
			},
		},
	},
}

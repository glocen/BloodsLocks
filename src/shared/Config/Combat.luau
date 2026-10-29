--!strict
-- Combat tuning shared by every class.

return {
	BaseHealth = 1000,
	StaggerMax = 100,
	StaggerDecayDelay = 2.0, -- seconds after the last hit before the stagger meter drains
	StaggerDecayPerSecond = 20,
	StaggerDuration = 2.0, -- a full meter leaves the target staggered (open to a bite) this long

	Hitstun = { None = 0, Flinch = 0.28, Heavy = 0.55, Parried = 0.9 },
	Knockback = { None = 0, Flinch = 10, Heavy = 34 }, -- studs/s pushed away from the attacker

	Guard = {
		WalkSpeed = 8,
		ArcDot = 0.2, -- attacker must be in front: dot(facing, toAttacker) above this (~156° arc)
		ChipDamage = 0.2, -- share of damage that gets through a block
		StaminaPerDamage = 0.4, -- blocked damage drains stamina; at 0 the guard breaks
		PerfectWindow = 0.15, -- raising guard this soon before a hit parries it
		BreakStun = 1.0,
	},

	Howl = {
		StaminaCost = 15,
		StaggerDuration = 1.6, -- an attacker whose melee hit lands in the howl window is staggered this long
		InputGrace = 0.1, -- R pressed this soon before guard still counts as a howl (keys rarely land on one frame)
	},

	ActionWalkSpeed = 3, -- default move speed while attacking (actions can override)
	InputBuffer = 0.25, -- a bite/shot/attack pressed this close to the end of an action fires when it ends
	PvPInManor = true, -- players can spar inside the Manor's training yard (the rest of the Manor is a safe zone)
	ShowHitboxes = true, -- Studio only: MuchachoHitbox visualizer
}

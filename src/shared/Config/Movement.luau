--!strict
-- Movement tuning (Duskbloods-style kit). Every value is a starting point to tune by feel.
-- Heights at gravity 145 (h = v² / 2g): launch 61 ≈ 12.8 studs, 56 ≈ 10.8, 70 ≈ 16.9, 108 ≈ 40.2. An ideal chain (full
-- high jump, then three air jumps at the apex) rises ≈ 72.6 studs: world builders size envelopes from that.
-- Raised 2026-10-30 (owner: jumps and air jumps felt small; was 50 / 45 / 60..85).

return {
	WalkSpeed = 18,
	SprintSpeed = 30, -- sprint is a toggle and never costs stamina
	ChargeWalkSpeed = 6, -- while crouch-charging a high jump
	SprintStopDelay = 0.25, -- standing still this long ends a sprint

	MaxJumps = 4, -- ground jump + 3 air jumps, reset on landing
	JumpVelocity = 61,
	AirJumpVelocity = 56,
	AirJumpStaminaCost = 12,
	CoyoteTime = 0.10, -- after walking off a ledge you still get the ground jump this long

	HighJump = {
		HoldThreshold = 0.15, -- hold jump longer than this on the ground to start charging
		FullCharge = 0.6, -- seconds of holding for a full charge
		MinVelocity = 70,
		MaxVelocity = 108,
	},

	AirDash = {
		PerAirtime = 1,
		Duration = 0.18,
		Speed = 72, -- gravity is paused during the dash
		StaminaCost = 20,
	},

	Dodge = {
		Duration = 0.40,
		StartSpeed = 55,
		EndSpeed = 12,
		IFrameFrom = 0.04, -- invincibility window, seconds after the dodge starts
		IFrameTo = 0.28,
		StaminaCost = 20, -- no input = backstep
	},

	LockTurnRate = 720, -- degrees per second the character turns toward a lock-on target

	FallGravityMultiplier = 1.25, -- extra gravity while falling, for snappier landings
	MaxFallSpeed = 160,
}

--!strict
-- Camera tuning: mouse-locked third person with Souls-style lock-on.

return {
	Distance = 11,
	MinDistance = 6,
	MaxDistance = 16,
	ZoomStep = 1.5,
	FocusHeight = 2.4, -- above the root part
	ShoulderOffset = 1.4, -- right of the character, keeps the crosshair off your back
	Sensitivity = 0.0045, -- radians per pixel of mouse movement
	PitchMin = math.rad(-70),
	PitchMax = math.rad(55),
	FollowSharpness = 28, -- how tightly the camera follows the character (higher = tighter)
	CollisionRadius = 0.6,

	BaseFov = 70,
	SprintFov = 78,
	DashFov = 84,
	FovSharpness = 8,

	-- The bite's camera: while you hold a bite the view eases Yaw degrees round to your right (the side the bite is on),
	-- in to Distance studs and to a narrower Fov, Ease seconds in and back out as the victim is thrown. Rumble is the
	-- drain's sustained shake: magnitude, roughness, fade in, fade out (seconds).
	Bite = { Yaw = 40, Distance = 9, Fov = 62, Ease = 0.35, Rumble = { 0.35, 3, 0.4, 0.3 } },

	LockRange = 60, -- studs; nearest valid target in front of the camera
	LockBreakRange = 80,
	LockSharpness = 12, -- how fast the camera swings to the target
	LockPitchBias = math.rad(-12), -- look slightly down at the target
	FlickThreshold = 22, -- pixels in one frame to switch targets
	SwitchCooldown = 0.3,
}

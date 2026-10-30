--!strict
-- Gustave's kit animations: sources for Animations/Author (first authored by ChatGPT in tools/animations, moved here).
-- A frame is { time, { [part] = { x, y, z, dx?, dy?, dz? } }, markers? }; a part left out holds the Idle pose. Legs is
-- the legs' weight (0 leaves them to locomotion). Action timings live in Definitions; markers name the beats for
-- effects and sound.

local IDLE = {
	Torso = { 4, 0, 0 },
	Head = { -3, 0, 0 },
	["Right Arm"] = { 16, -5, 9 },
	["Left Arm"] = { 10, 5, -9 },
	["Right Leg"] = { -4, 0, 3 },
	["Left Leg"] = { 4, 0, -3 },
}

-- The burst's duelist stance: the body blades (negative torso Y brings the gun shoulder forward), the head turns back
-- onto the target, and the raised gun arm is yawed onto the aim with Z (on a raised arm, Y only rolls it).
local AIM = { Torso = { 2, -22, 0 }, Head = { 2, 18, 0 }, ["Left Arm"] = { 91, 0, -22 }, ["Right Arm"] = { 6, -6, 14 } }

-- A round's kick: the gun arm jumps `pitch` degrees up and `back` studs back, and the shoulder gives a little.
local function kick(pitch: number, back: number)
	return { Torso = { 0, -19, 0 }, Head = { 1, 16, 0 }, ["Left Arm"] = { pitch, 0, -20, 0, 0, back }, ["Right Arm"] = AIM["Right Arm"] }
end

return {
	Character = "Gustave",
	Idle = IDLE,
	Clips = {
		Howl = {
			Frames = {
				{ 0, { Torso = { 7, 0, 0 }, Head = { 8, 0, 0 }, ["Right Arm"] = { 24, 0, 16 }, ["Left Arm"] = { 24, 0, -16 } } },
				{ 0.04, { Torso = { -7, 0, 0 }, Head = { -18, 0, 0 }, ["Right Arm"] = { -12, -8, 42 }, ["Left Arm"] = { -12, 8, -42 } }, { "HowlWindowOpen" } },
				{ 0.1, { Torso = { -12, 0, 0 }, Head = { -24, 0, 0 }, ["Right Arm"] = { -19, -12, 52 }, ["Left Arm"] = { -19, 12, -52 } } },
				{ 0.2, { Torso = { -7, 0, 0 }, Head = { -17, 0, 0 }, ["Right Arm"] = { -10, -8, 44 }, ["Left Arm"] = { -10, 8, -44 } } },
				{ 0.3, { Torso = { -4, 0, 0 }, Head = { -10, 0, 0 }, ["Right Arm"] = { -6, -4, 35 }, ["Left Arm"] = { -6, 4, -35 } }, { "HowlWindowClose" } },
				{ 0.44, { Torso = { 1, 0, 0 }, Head = { -3, 0, 0 }, ["Right Arm"] = { 8, 0, 21 }, ["Left Arm"] = { 8, 0, -21 } } },
				{ 0.6, IDLE },
			},
		},
		Bite = {
			Frames = {
				{ 0, { Torso = { 2, 12, 0 }, Head = { 0, -8, 0 }, ["Right Arm"] = { 23, -5, 15 }, ["Left Arm"] = { 48, 0, -18 } } },
				{ 0.04, { Torso = { 16, 9, 0 }, Head = { 7, -6, 0 }, ["Right Arm"] = { 38, -9, 22 }, ["Left Arm"] = { 72, 0, -19 } } },
				{ 0.1, { Torso = { 25, 6, 0, 0, -0.1, -0.12 }, Head = { 10, -4, 0 }, ["Right Arm"] = { 45, -7, 26 }, ["Left Arm"] = { 88, 0, -20 } }, { "BiteImpact" } },
				{ 0.17, { Torso = { 30, 2, 0, 0, -0.12, -0.16 }, Head = { 18, -2, 0 }, ["Right Arm"] = { 39, -10, 26 }, ["Left Arm"] = { 85, 0, -23 } } },
				{ 0.22, { Torso = { 21, -3, 0 }, Head = { 3, 3, 0 }, ["Right Arm"] = { 28, -8, 22 }, ["Left Arm"] = { 74, 3, -18 } }, { "BiteWindowClose" } },
				{ 0.36, { Torso = { 7, -8, 0 }, Head = { -12, 8, 0 }, ["Right Arm"] = { 18, 0, 18 }, ["Left Arm"] = { 50, 5, -15 } } },
				{ 0.52, { Torso = { 0, -3, 0 }, Head = { -5, 4, 0 }, ["Right Arm"] = { 13, 0, 13 }, ["Left Arm"] = { 27, 4, -12 } } },
				{ 0.75, IDLE },
			},
		},
		SMGBurst = { -- the gun arm snaps up by the first round; each kick climbs a little, with the spread's bloom
			Legs = 0,
			Frames = {
				{ 0, { Torso = { 3, -10, 0 }, Head = { -2, 8, 0 }, ["Right Arm"] = { 10, -6, 12 }, ["Left Arm"] = { 60, 0, -14 } } },
				{ 0.035, AIM },
				{ 0.04, kick(98, 0.04), { "Shot1" } },
				{ 0.075, AIM },
				{ 0.1, kick(99, 0.05), { "Shot2" } },
				{ 0.135, AIM },
				{ 0.16, kick(100, 0.06), { "Shot3" } },
				{ 0.195, AIM },
				{ 0.22, kick(102, 0.07), { "Shot4" } },
				{ 0.28, AIM },
				{ 0.35, { Torso = { 4, -8, 0 }, Head = { -3, 6, 0 }, ["Right Arm"] = { 14, -5, 10 }, ["Left Arm"] = { 45, 2, -12 } } },
				{ 0.42, IDLE },
			},
		},
		BloodBlade = {
			Legs = 0.25,
			Frames = {
				{ 0, { Torso = { 7, 13, 0 }, Head = { -3, -10, 0 }, ["Right Arm"] = { 76, -20, 26 }, ["Left Arm"] = { 24, 8, -17 } } },
				{ 0.065, { Torso = { 5, 27, -3 }, Head = { -2, -22, 0 }, ["Right Arm"] = { 137, -17, 33 }, ["Left Arm"] = { 18, 12, -28 } } },
				{ 0.12, { Torso = { 6, 25, -2 }, Head = { -2, -20, 0 }, ["Right Arm"] = { 143, -16, 30 }, ["Left Arm"] = { 18, 12, -26 } } },
				{ 0.18, { Torso = { 14, -19, 3 }, Head = { -4, 17, 0 }, ["Right Arm"] = { 77, 14, -32 }, ["Left Arm"] = { 6, -10, -35 } }, { "ProjectileRelease" } },
				{ 0.24, { Torso = { 12, -28, 2 }, Head = { -3, 23, 0 }, ["Right Arm"] = { 37, 18, -45 }, ["Left Arm"] = { 5, -12, -31 } } },
				{ 0.33, { Torso = { 8, -18, 0 }, Head = { -3, 14, 0 }, ["Right Arm"] = { 24, 8, -18 }, ["Left Arm"] = { 10, -2, -18 } } },
				{ 0.5, IDLE },
			},
		},
		LightBeam = {
			Frames = {
				{ 0, { Torso = { 5, 8, 0 }, Head = { -3, -7, 0 }, ["Right Arm"] = { 24, -4, 16 }, ["Left Arm"] = { 13, 4, -15 } } },
				{ 0.12, { Torso = { 2, 9, -2 }, Head = { -5, -8, 0 }, ["Right Arm"] = { 62, -6, 15 }, ["Left Arm"] = { 46, 8, -20 } } },
				{ 0.25, { Torso = { -3, 6, -2 }, Head = { -5, -5, 0 }, ["Right Arm"] = { 88, -3, 8 }, ["Left Arm"] = { 65, 14, -13 } } },
				{ 0.35, { Torso = { -6, 4, 0 }, Head = { -4, -3, 0 }, ["Right Arm"] = { 92, -1, 5 }, ["Left Arm"] = { 73, 16, -9 } }, { "ChannelStart" } },
				{ 0.6, { Torso = { -5, 4, 0 }, Head = { -4, -3, 0 }, ["Right Arm"] = { 91, -1, 5 }, ["Left Arm"] = { 72, 16, -9 } } },
				{ 0.9, { Torso = { -6, 4, 0 }, Head = { -4, -3, 0 }, ["Right Arm"] = { 92, -1, 5 }, ["Left Arm"] = { 73, 16, -9 } } },
				{ 1.2, { Torso = { -5, 4, 0 }, Head = { -4, -3, 0 }, ["Right Arm"] = { 91, -1, 5 }, ["Left Arm"] = { 72, 16, -9 } } },
				{ 1.55, { Torso = { -6, 4, 0 }, Head = { -4, -3, 0 }, ["Right Arm"] = { 92, -1, 5 }, ["Left Arm"] = { 73, 16, -9 } }, { "ChannelEnd" } },
				{ 1.61, { Torso = { 0, 4, 0 }, Head = { -3, -3, 0 }, ["Right Arm"] = { 57, -2, 12 }, ["Left Arm"] = { 42, 10, -14 } } },
				{ 1.7, IDLE },
			},
		},
	},
}

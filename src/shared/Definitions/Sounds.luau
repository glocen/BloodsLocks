--!strict
-- Sounds: what plays when, and how it's mixed. Every cue is a slice of a sound from Roblox's audio library (AGENTS.md
-- rule 2, "Sounds"): its Id, From and To (seconds), where it's loudest inside the slice (Peak) and its measured
-- loudness (Level), so Client.Audio.Sfx plays every cue at the same base level. tools/studio/Audio finds and measures
-- them; the owner picks each in the audition panel (Definitions/Audition). Until the owner picks a cue, it holds its
-- shortlist's top-ranked slice that is loud enough to level.
--   Cues: Volume (the mix), Pitch (each play picks a playback speed between the two, so repeats never sound
--         identical) and Range (studs at which it fades out).
--   Actions (by action id): Swing plays as the action starts, timed so the whoosh peaks as its hit window opens; Hit
--         when it lands (melee); Shot per round (guns); Charge, Loop and End while a beam charges, holds and ends; a
--         bite's hold names its beats (Seize, Fangs, Pulse).
--   Projectiles (by the projectile's Visual): Cast on release, Impact where it stops.
--   Weapons (by weapon id): Reload when a reload starts.
--   Feedback: hits on bodies and surfaces with no cue of their own, blocks, parries and guard breaks.
-- Registry checks every name and slice here at load.

return {
	Cues = {
		GunShot = { Id = "rbxassetid://109108727131456", From = 0, To = 0.39, Peak = 0.01, Level = -8.8,
			Volume = 0.9, Pitch = { 0.95, 1.05 }, Range = 160 },
		GunReload = { Id = "rbxassetid://100961202215282", From = 0, To = 0.71, Peak = 0.02, Level = -14.4,
			Volume = 0.55, Pitch = { 0.98, 1.02 }, Range = 40 },
		SurfaceHit = { Id = "rbxassetid://9120962381", From = 0, To = 0.2, Peak = 0.01, Level = -17.8,
			Volume = 0.6, Pitch = { 0.9, 1.1 }, Range = 60 },
		BodyHit = { Id = "rbxassetid://9126267607", From = 0, To = 0.36, Peak = 0, Level = -16.9,
			Volume = 0.8, Pitch = { 0.92, 1.08 }, Range = 70 },
		SaberSwing = { Id = "rbxassetid://9126013811", From = 0.09, To = 0.43, Peak = 0.08, Level = -19.1,
			Volume = 0.6, Pitch = { 0.94, 1.08 }, Range = 50 },
		SaberSwingHeavy = { Id = "rbxassetid://6241709963", From = 0, To = 0.5, Peak = 0.15, Level = -16.8,
			Volume = 0.75, Pitch = { 0.95, 1.05 }, Range = 60 },
		SaberHit = { Id = "rbxassetid://9119747138", From = 0, To = 0.35, Peak = 0.06, Level = -12.9,
			Volume = 0.85, Pitch = { 0.94, 1.06 }, Range = 70 },
		GuardBlock = { Id = "rbxassetid://9125672726", From = 0, To = 0.52, Peak = 0, Level = -14.1,
			Volume = 0.8, Pitch = { 0.95, 1.05 }, Range = 70 },
		Parry = { Id = "rbxassetid://9113133597", From = 0, To = 0.44, Peak = 0, Level = -19.3,
			Volume = 0.9, Pitch = { 0.98, 1.02 }, Range = 90 },
		GuardBreak = { Id = "rbxassetid://9114855870", From = 0.17, To = 1.03, Peak = 0.04, Level = -18.7,
			Volume = 0.9, Pitch = { 0.96, 1.04 }, Range = 90 },
		BloodBladeCast = { Id = "rbxassetid://9114446852", From = 0, To = 0.78, Peak = 0.23, Level = -20.1,
			Volume = 0.8, Pitch = { 0.96, 1.04 }, Range = 80 },
		BloodBladeImpact = { Id = "rbxassetid://9125640290", From = 0, To = 0.83, Peak = 0.07, Level = -19.1,
			Volume = 0.85, Pitch = { 0.95, 1.05 }, Range = 90 },
		LightBeamCharge = { Id = "rbxassetid://9118158113", From = 0.01, To = 0.86, Peak = 0.41, Level = -16.1,
			Volume = 0.7, Pitch = { 1, 1 }, Range = 80 },
		LightBeamLoop = { Id = "rbxassetid://123902330294565", From = 2.9, To = 5.9, Peak = 0, Level = -25.6,
			Volume = 0.6, Pitch = { 1, 1 }, Range = 90 },
		LightBeamEnd = { Id = "rbxassetid://9113166561", From = 0.77, To = 2.25, Peak = 0.14, Level = -28.9,
			Volume = 0.7, Pitch = { 1, 1 }, Range = 80 },
		BiteLunge = { Id = "rbxassetid://116381638709798", From = 0.01, To = 0.46, Peak = 0.13, Level = -16.7,
			Volume = 0.6, Pitch = { 0.95, 1.05 }, Range = 50 },
		BiteSeize = { Id = "rbxassetid://9120844413", From = 0.35, To = 0.67, Peak = 0.05, Level = -17.0,
			Volume = 0.75, Pitch = { 0.96, 1.04 }, Range = 60 },
		BiteFangs = { Id = "rbxassetid://12222140", From = 0, To = 0.26, Peak = 0.01, Level = -10.2,
			Volume = 0.85, Pitch = { 0.96, 1.04 }, Range = 70 },
		BitePulse = { Id = "rbxassetid://9113535217", From = 0, To = 0.24, Peak = 0.04, Level = -17.3,
			Volume = 0.6, Pitch = { 0.97, 1.03 }, Range = 50 },
		BiteRelease = { Id = "rbxassetid://130809356016155", From = 0.07, To = 0.73, Peak = 0.04, Level = -14.5,
			Volume = 0.9, Pitch = { 0.97, 1.03 }, Range = 90 },
	},

	Actions = {
		["Saber.Light1"] = { Swing = "SaberSwing", Hit = "SaberHit" },
		["Saber.Light2"] = { Swing = "SaberSwing", Hit = "SaberHit" },
		["Saber.Light3"] = { Swing = "SaberSwing", Hit = "SaberHit" },
		["Saber.Light4"] = { Swing = "SaberSwingHeavy", Hit = "SaberHit" }, -- the chain's finisher
		["Saber.Strong1"] = { Swing = "SaberSwingHeavy", Hit = "SaberHit" },
		["Saber.Strong2"] = { Swing = "SaberSwingHeavy", Hit = "SaberHit" },
		["Saber.Charged"] = { Swing = "SaberSwingHeavy", Hit = "SaberHit" },
		["BurstSMG.Burst"] = { Shot = "GunShot" },
		["Gustave.LightBeam"] = { Charge = "LightBeamCharge", Loop = "LightBeamLoop", End = "LightBeamEnd" },
		["Common.Bite"] = { Swing = "BiteLunge" },
		-- the hold's beats (Vfx/BiteWind: Seize, Fangs, each Pulse); its Hit is the throw at the release
		["Common.BiteHold"] = { Seize = "BiteSeize", Fangs = "BiteFangs", Pulse = "BitePulse", Hit = "BiteRelease" },
	},

	Projectiles = {
		BloodBlade = { Cast = "BloodBladeCast", Impact = "BloodBladeImpact" },
	},

	Weapons = {
		BurstSMG = { Reload = "GunReload" },
	},

	Feedback = {
		BodyHit = "BodyHit",
		SurfaceHit = "SurfaceHit",
		Block = "GuardBlock",
		Parry = "Parry",
		GuardBreak = "GuardBreak",
	},
}

--!strict
-- Sounds: what plays when, and how it's mixed. Every cue is a region of the combat sound sheet (Definitions/SoundSheet,
-- drawn by tools/audio/sound_sheet.py and uploaded once by the owner); Client.Audio.Sfx plays them in 3D.
--   Cues: Volume, Pitch (each play picks a playback speed between the two, so repeats never sound identical) and
--         Range (studs at which it fades out).
--   Actions (by action id): Swing plays as the action starts, timed so the whoosh peaks as its hit window opens; Hit
--         when it lands (melee); Shot per round (guns); Charge, Loop and End while a beam charges, holds and ends; a
--         bite's hold names its beats (Seize, Fangs, Pulse).
--   Projectiles (by the projectile's Visual): Cast on release, Impact where it stops.
--   Weapons (by weapon id): Reload when a reload starts.
--   Feedback: hits on bodies and surfaces with no cue of their own, blocks and parries.
-- Registry checks every name here at load.

return {
	Cues = {
		GunShot = { Volume = 0.9, Pitch = { 0.95, 1.05 }, Range = 160 },
		GunReload = { Volume = 0.55, Pitch = { 0.98, 1.02 }, Range = 40 },
		SurfaceHit = { Volume = 0.6, Pitch = { 0.9, 1.1 }, Range = 60 },
		BodyHit = { Volume = 0.8, Pitch = { 0.92, 1.08 }, Range = 70 },
		SaberSwing = { Volume = 0.6, Pitch = { 0.94, 1.08 }, Range = 50 },
		SaberSwingHeavy = { Volume = 0.75, Pitch = { 0.95, 1.05 }, Range = 60 },
		SaberHit = { Volume = 0.85, Pitch = { 0.94, 1.06 }, Range = 70 },
		GuardBlock = { Volume = 0.8, Pitch = { 0.95, 1.05 }, Range = 70 },
		Parry = { Volume = 0.9, Pitch = { 0.98, 1.02 }, Range = 90 },
		BloodBladeCast = { Volume = 0.8, Pitch = { 0.96, 1.04 }, Range = 80 },
		BloodBladeImpact = { Volume = 0.85, Pitch = { 0.95, 1.05 }, Range = 90 },
		LightBeamCharge = { Volume = 0.7, Pitch = { 1, 1 }, Range = 80 },
		LightBeamLoop = { Volume = 0.6, Pitch = { 1, 1 }, Range = 90 },
		LightBeamEnd = { Volume = 0.7, Pitch = { 1, 1 }, Range = 80 },
		BiteLunge = { Volume = 0.6, Pitch = { 0.95, 1.05 }, Range = 50 },
		BiteSeize = { Volume = 0.75, Pitch = { 0.96, 1.04 }, Range = 60 },
		BiteFangs = { Volume = 0.85, Pitch = { 0.96, 1.04 }, Range = 70 },
		BitePulse = { Volume = 0.6, Pitch = { 0.97, 1.03 }, Range = 50 },
		BiteRelease = { Volume = 0.9, Pitch = { 0.97, 1.03 }, Range = 90 },
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
	},
}

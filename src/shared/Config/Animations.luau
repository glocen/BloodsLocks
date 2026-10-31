--!strict
-- Animation ids. Every class uses Default unless its entry in Classes overrides an animation by name,
-- so a class with a special dodge (for example) only lists that one animation.
-- A character's class comes from its class attribute (EntityState.Attr.ClassId) (set by the class system; nil = Default only).
-- Source KeyframeSequences for the BL_* animations live in ServerStorage.RBX_ANIMSAVES.R6; the kit's are authored from
-- tools/studio/Animations (Author.Save, then Author.Publish gives the id).
-- Every id must be published ("rbxassetid://..."): under Server Authority the server plays these too and
-- can't load temporary Studio ids.

return {
	Default = {
		Sprint = "rbxassetid://74424006832763",
		ChargeCrouch = "rbxassetid://100929610582843",
		HighJumpLaunch = "rbxassetid://70418964374889",
		AirFlip = "rbxassetid://127581191914547",
		AirDash = "rbxassetid://73443210897974",
		Dodge = "rbxassetid://106266201860518",
		Backstep = "rbxassetid://82315453889963",
		Land = "rbxassetid://94312387247234",
		-- Saber (Gustave) attacks
		SaberLight1 = "rbxassetid://77313007380000",
		SaberLight2 = "rbxassetid://85434461198156",
		SaberLight3 = "rbxassetid://85462852919113",
		SaberLight4 = "rbxassetid://75826233184658",
		SaberStrong1 = "rbxassetid://116502336413724",
		SaberStrong2 = "rbxassetid://132647384021849",
		SaberCharge = "rbxassetid://138331377243744",
		SaberCharged = "rbxassetid://128599242014306",
		-- Kit: "" until published
		Howl = "rbxassetid://139673450689337", -- published 2026-10-30 (AssetService:CreateAssetAsync from Studio)
		Bite = "rbxassetid://126304518903664", -- Blender (tools/blender/bite_anim.py), published 2026-10-31
		BiteHold = "rbxassetid://126343564800671", -- the biter's hold (Simulation/Bite); Blender, 2026-10-31
		Bitten = "rbxassetid://80678333219496", -- the bite's victim, any R6 body; Blender, 2026-10-31
		Staggered = "rbxassetid://97201280138759", -- any R6 body: down on one knee while staggered; Blender, 2026-10-31
		SMGBurst = "rbxassetid://128345868550616", -- the duelist burst, published 2026-10-30
		BloodBlade = "",
		LightBeam = "rbxassetid://135123828939357", -- Gustave: published 2026-10-29
	},

	Classes = {
		-- Gustave = { Dodge = "rbxassetid://..." },
	},
}

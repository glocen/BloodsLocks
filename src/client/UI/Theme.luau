--!strict
-- Theme v2 "Vigil gothic": every colour, font, size, space, stroke, motion and layer value the UI uses. Restyle the
-- whole game here; screens never hold literals. Design notes: docs/ui-research.md section 4.
-- Palette = raw colours. Colors = what they mean (screens use these). The older flat keys (BarWidth, Corner, ...)
-- stay as aliases so existing components keep working while they're ported.
-- The raw palette, font families, images, text sizes and fit formulas live in ReplicatedFirst.BL_First.ThemeBase so
-- the loading screen can use them before the game loads; this module re-exports them.

local ThemeBase = require(game:GetService("ReplicatedFirst"):WaitForChild("BL_First"):WaitForChild("ThemeBase"))

local Palette = ThemeBase.Palette
local DISPLAY = ThemeBase.Families.Display -- Bodoni: high-contrast classical serif for titles
local BODY = ThemeBase.Families.Body -- Garamond: body text, labels, numbers

return {
	Palette = Palette,

	Colors = {
		-- surfaces
		Background = Palette.Ink,
		Panel = Palette.Velvet,
		PanelSoft = Palette.InkSoft,
		Overlay = Palette.Ink, -- with Transparency.Overlay behind modals
		-- lines
		Stroke = Palette.GoldDim,
		Hairline = Palette.Gold,
		Focus = Palette.Gold,
		-- text
		Text = Palette.Bone,
		TextMuted = Palette.Ash,
		TextOnAccent = Palette.Ink,
		-- meaning
		Health = Palette.BloodMuted,
		HealthDark = Palette.BloodMutedDeep,
		HealthLag = Color3.fromRGB(200, 140, 130), -- the chip of damage that drains after a hit
		Stamina = Palette.Moss,
		StaminaDark = Palette.MossDeep,
		Posture = Palette.Ember, -- your stagger meter
		PostureDark = Palette.EmberDeep,
		Warm = Palette.Ember, -- warm highlights: tracers, HOWL / STAGGERED callouts, lock ring
		Accent = Palette.Moon,
		Danger = Palette.Blood,
		Heal = Palette.Verdant,
		Primary = Palette.Blood,
		Disabled = Palette.Ash,
		-- effects (kept from v1)
		Blood = Color3.fromRGB(196, 18, 48),
		Radiance = Color3.fromRGB(255, 226, 160),
	},

	Transparency = {
		Panel = 0.12,
		PanelSoft = 0.35,
		Overlay = 0.35,
		Hairline = 0.25,
		Disabled = 0.55,
		Scrim = 0.3, -- the soft dark under HUD text that sits over the world (at its densest edge)
	},

	Fonts = {
		Display = Font.new(DISPLAY, Enum.FontWeight.Regular),
		DisplayBold = Font.new(DISPLAY, Enum.FontWeight.Bold),
		Body = Font.new(BODY, Enum.FontWeight.Regular),
		BodyBold = Font.new(BODY, Enum.FontWeight.Bold),
		Numeric = Font.new(BODY, Enum.FontWeight.SemiBold),
	},

	-- MinRendered / MinCaption: the smallest text may ever render on screen, after scaling (UI standard section 2)
	TextSize = ThemeBase.TextSize,

	Space = { XS = 4, S = 8, M = 12, L = 20, XL = 32, XXL = 48 },

	Radius = { None = UDim.new(0, 0), Small = UDim.new(0, 2), Medium = UDim.new(0, 4) },

	Stroke = { Hairline = 1, Thin = 1.5, Bold = 2 },

	-- Calm, weighted motion: no bounces. Durations in seconds.
	Motion = {
		Fast = 0.12,
		Base = 0.2,
		Slow = 0.35,
		Style = Enum.EasingStyle.Quart,
		Direction = Enum.EasingDirection.Out,
	},

	-- ScreenGui layers (DisplayOrder). Higher draws on top. World: labels pinned to things in the world (plates over
	-- enemies and hunters, call-outs), drawn under the HUD.
	Layers = { World = 5, HUD = 10, Menus = 20, Overlay = 30, Toasts = 40, Transition = 100 },

	-- The intermission map (UI/Match/MapView): the district seen from above, coloured by height like an engraved
	-- survey (low → high), lit warm, with gold regions and these marks for what's inside them.
	Map = {
		Bands = {
			Color3.fromRGB(38, 28, 33),
			Color3.fromRGB(74, 58, 56),
			Color3.fromRGB(118, 98, 86),
			Color3.fromRGB(166, 146, 122),
			Color3.fromRGB(190, 172, 148), -- the spires: light, but not so light a lone one reads as a mark
		},
		EdgeFade = 0.1, -- how far in from its edges the relief fades into the backdrop (of its width / height)
		Ambient = Color3.fromRGB(150, 132, 120),
		Light = Color3.fromRGB(255, 226, 196),
		Region = Palette.Gold,
		Ring = { Thickness = 1.5, Chosen = 2.5, Idle = 0.55, Lit = 0.1 }, -- region rings: widths (px), transparencies
		Fill = { Hover = 0.8, Chosen = 0.7 }, -- the warm glow inside a hovered / chosen ring (transparency)
		Pulse = 1.2, -- the chosen ring's one pulse swells to this × its size
		Marks = {
			Pact = Palette.Moon,
			Ritual = Palette.Gold,
			Fodder = Palette.Ember,
			Heavy = Palette.Blood,
			You = Palette.Gold,
		},
	},

	-- Pact circles (Controllers/Core/PactSiteController), in the layers of Duskbloods' Kin circles: from afar a soft
	-- shaft of moonlight with motes drifting in it; close up the blood sigil turning on the ground, a cold pool of light,
	-- and the Shinigami waiting in it. Studs, seconds; Spin in degrees a second.
	Pact = {
		Moonlight = Color3.fromRGB(176, 196, 240),
		Sigil = { Size = 14, Spin = 5, Transparency = 0, Brightness = 3, Flare = 7, FlareTime = 1.2 },
		Shaft = { Height = 60, Width = 16, Transparency = 0.5 }, -- a soft glow stretched from Height below the floor to Height above
		Motes = { Rate = 5, Height = 12, Radius = 5 },
		Light = { Height = 28, Angle = 36, Brightness = 2.4 },
		Bow = 14, -- degrees the waiting Shinigami's head is bowed
		Fade = 0.5, -- seconds it takes to break into mist when your pact is made
	},

	-- Plates over enemies, hunters and companions (UI/World/Plate), at the reference resolution.
	Plate = {
		Width = 120, -- fodder, hunters, companions
		WideWidth = 168, -- heavies and elites, and whatever you've locked
		HpHeight = 5,
		PostureHeight = 3,
		Gap = 2,
		NameSize = 17,
		TotalSize = 17,
		Rise = 14, -- pixels above the head's top the bars sit
	},

	-- Everything is authored at this resolution; one UIScale per layer fits it to the screen (FitScale), and labels
	-- keep a legible rendered size when it shrinks (LegibleSize).
	ReferenceResolution = ThemeBase.ReferenceResolution,
	FitScale = ThemeBase.FitScale,
	LegibleSize = ThemeBase.LegibleSize,

	-- Our own drawn UI images (tools/vfx_textures.py, tools/ui_textures.py).
	Images = ThemeBase.Images,

	-- The Blood Table menu (sizes at the reference resolution; text never under 20 so it stays crisp when scaled).
	Menu = {
		Margin = 64, -- from the screen edges
		Top = 72, -- the ribbon's top: clears Roblox's own top-bar buttons (every layer ignores the GUI inset)
		TabHeight = 58,
		TabTextSize = 26,
		HintTextSize = 22,
		HintGlyph = 32, -- key glyph height
		CardWidth = 460,
		CardHeight = 248,
		ButtonHeight = 58,
		ButtonTextSize = 24,
		RowTextSize = 21,
		StageLight = Color3.fromRGB(255, 196, 150), -- warm key light on the character while the menu is open
		CircleGlow = Color3.fromRGB(150, 20, 34),
		-- the tab ribbon: brushed wine-brown paint, the active tab a muted mauve plate under a gold filigree
		RibbonTint = Color3.fromRGB(88, 42, 44),
		RibbonShade = Color3.fromRGB(150, 140, 145), -- multiplies the bottom of the band (darker toward it)
		RibbonActive = Color3.fromRGB(104, 70, 72),
		TabText = Color3.fromRGB(236, 226, 214),
		Panel = Color3.fromRGB(46, 20, 24), -- buttons and rows under the card
	},

	Hud = {
		BarWidth = 300,
		HealthHeight = 9,
		StaminaHeight = 6,
		SkillSlotSize = 56,
		CrosshairSize = 4,
		LockMarkerSize = 14,
	},

	-- Effect palette: each skill reads its shades from here (dark → bright).
	Vfx = {
		BloodDark = Color3.fromRGB(34, 0, 6),
		BloodDeep = Color3.fromRGB(104, 0, 14),
		BloodWet = Color3.fromRGB(140, 0, 18),
		Blood = Color3.fromRGB(196, 18, 48),
		BloodCore = Color3.fromRGB(240, 52, 62),
		RadianceDeep = Color3.fromRGB(230, 90, 10),
		Radiance = Color3.fromRGB(255, 160, 50),
		RadianceCore = Color3.fromRGB(255, 232, 180),
		Fire = Color3.fromRGB(255, 120, 40),
		FireDeep = Color3.fromRGB(190, 40, 20),
		FireCore = Color3.fromRGB(255, 220, 150),
		Smoke = Color3.fromRGB(70, 40, 35),
		SmokeDark = Color3.fromRGB(25, 18, 18),
		Tracer = Color3.fromRGB(255, 234, 204), -- a round in flight: pale, warm
		GunSmoke = Color3.fromRGB(150, 146, 152),
		Dust = Color3.fromRGB(122, 112, 104), -- stone dust a round kicks up (blended toward the surface's colour)
		BladeSmear = Color3.fromRGB(236, 232, 226), -- a blade's motion smear: pale; the scene's light tints the rest
		BladeEdge = Color3.fromRGB(255, 250, 244), -- the bright line on the point's path
		WindSmoke = Color3.fromRGB(34, 30, 44), -- the bite's gust: near-black smoke, a cold violet cast
		WindSmokeDeep = Color3.fromRGB(14, 12, 20),
		Wind = Color3.fromRGB(196, 202, 218), -- its wind lines: pale, cool
		Drain = Color3.fromRGB(226, 234, 255), -- the life a bite drinks: cold white motes (magic's colour role)
		-- the ward (Vfx/Ward): dark crimson glass, a hot rim, gold-red leading; blocks and parries flash gold (rites)
		WardGlass = Color3.fromRGB(70, 5, 16),
		WardHot = Color3.fromRGB(230, 70, 54), -- the glass flashing on a block
		WardRim = Color3.fromRGB(255, 74, 48),
		WardLine = Color3.fromRGB(255, 132, 84), -- the rose-window tracery
		WardCrack = Color3.fromRGB(255, 220, 186), -- cracks catching the light
		WardLight = Color3.fromRGB(255, 58, 40), -- the light it casts on the arm and face
		WardEmber = Color3.fromRGB(255, 110, 60),
		WardShard = Color3.fromRGB(150, 14, 34), -- its shards: crimson glass, lit
	},

	-- Class portraits (Blood Table, Bloodsworn tab): ViewportFrame lighting and card shading.
	Portrait = {
		Ambient = Color3.fromRGB(150, 130, 140),
		Light = Color3.fromRGB(255, 220, 190),
		SealedAmbient = Color3.fromRGB(30, 22, 30),
		SealedLight = Color3.fromRGB(120, 40, 50),
		Silhouette = Color3.fromRGB(8, 6, 10),
		CardShade = Color3.fromRGB(70, 34, 44),
	},

	-- Panels: the vertical shade over the body (multiplies the fill colour).
	PanelShade = Color3.fromRGB(150, 140, 155),

	-- v1 aliases (port components to the structured tokens above, then remove these).
	Font = Font.new(BODY, Enum.FontWeight.Regular),
	FontBold = Font.new(BODY, Enum.FontWeight.Bold),
	Corner = UDim.new(0, 2),
	StrokeThickness = 1.5,
	BarHeight = 8,
	BarWidth = 300,
	CrosshairSize = 4,
	LockMarkerSize = 14,
	SkillSlotSize = 56,
}

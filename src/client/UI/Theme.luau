--!strict
-- Theme v2 "Vigil gothic": every colour, font, size, space, stroke, motion and layer value the UI uses. Restyle the
-- whole game here; screens never hold literals. Design notes: docs/ui-research.md section 4.
-- Palette = raw colours. Colors = what they mean (screens use these). The older flat keys (BarWidth, Corner, ...)
-- stay as aliases so existing components keep working while they're ported.

local Palette = {
	Ink = Color3.fromRGB(11, 8, 14), -- near-black violet: backgrounds
	InkSoft = Color3.fromRGB(22, 15, 27),
	Velvet = Color3.fromRGB(34, 20, 38), -- panel body
	Bone = Color3.fromRGB(232, 222, 205), -- primary text, parchment
	Ash = Color3.fromRGB(150, 138, 140), -- secondary text
	Gold = Color3.fromRGB(201, 164, 98), -- hairlines, focus, rarity
	GoldDim = Color3.fromRGB(110, 86, 52),
	Blood = Color3.fromRGB(176, 22, 44), -- danger, health, primary action
	BloodDeep = Color3.fromRGB(88, 8, 24),
	BloodMuted = Color3.fromRGB(142, 34, 40), -- HP: deep, desaturated (Duskbloods-like)
	BloodMutedDeep = Color3.fromRGB(64, 14, 20),
	Ember = Color3.fromRGB(222, 140, 60), -- stamina, warmth
	EmberDeep = Color3.fromRGB(130, 66, 22),
	Moon = Color3.fromRGB(110, 146, 220), -- info, cold side, ready
	Verdant = Color3.fromRGB(120, 196, 128), -- heals
	Moss = Color3.fromRGB(128, 178, 84), -- stamina
	MossDeep = Color3.fromRGB(46, 84, 32),
}

local function family(enum: Enum.Font): string
	return Font.fromEnum(enum).Family
end
local DISPLAY = family(Enum.Font.Bodoni) -- Accanthis: high-contrast classical serif for titles
local BODY = family(Enum.Font.Garamond) -- Garamond: body text, labels, numbers

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
	},

	Fonts = {
		Display = Font.new(DISPLAY, Enum.FontWeight.Regular),
		DisplayBold = Font.new(DISPLAY, Enum.FontWeight.Bold),
		Body = Font.new(BODY, Enum.FontWeight.Regular),
		BodyBold = Font.new(BODY, Enum.FontWeight.Bold),
		Numeric = Font.new(BODY, Enum.FontWeight.SemiBold),
	},

	TextSize = { Caption = 14, Body = 18, Label = 20, Title = 30, Display = 48 },

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

	-- ScreenGui layers (DisplayOrder). Higher draws on top.
	Layers = { HUD = 10, Menus = 20, Overlay = 30, Toasts = 40, Transition = 100 },

	-- Everything is authored at this resolution; one UIScale per layer fits it to the screen.
	ReferenceResolution = Vector2.new(1920, 1080),

	-- Our own drawn UI images (tools/vfx_textures.py).
	Images = {
		Ring = "rbxassetid://126930541164453", -- white ring, swept into radial gauges
		BloodCrescent = "rbxassetid://114481905428903", -- Blood Blade emblem
		Glint = "rbxassetid://101126423932013", -- Light Beam emblem, lock-on glint
		Medallion = "rbxassetid://130555865843448", -- engraved bezel (light grey, tint it)
		Bullet = "rbxassetid://103235686741303", -- cartridge icon
		SoftGlow = "rbxassetid://75560931237584", -- round soft glow
		-- tools/ui_textures.py
		HuntCard = "rbxassetid://115279579388284", -- the Hunt tab's mode card: Victorian skyline at blood dusk
		RitualCircle = "rbxassetid://115419381323676", -- the blood circle under the character in the Blood Table menu
		Ribbon = "rbxassetid://134502622812389", -- brushed paint grain (grey; tinted), tiles 512x64
		TabFlourish = "rbxassetid://136447657638231", -- gold filigree for the active tab, 9-slice (72 px ends, 512x48)
	},

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

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
	},

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

--!strict
-- ThemeBase (ReplicatedFirst.BL_First): the tokens that must exist before anything else loads, so the loading screen
-- (Passage) and the game's UI share one source. UI/Theme builds every semantic token on top of these; screens read
-- Theme, never this module. Holds: the raw palette, the two font families, our drawn images, the text sizes, and
-- the fit formulas (how the 1920×1080-authored UI scales to a screen, and how text stays legible when it does).

local function family(enum: Enum.Font): string
	return Font.fromEnum(enum).Family
end

local REFERENCE = Vector2.new(1920, 1080) -- everything is authored at this resolution
local MIN_SCALE, MAX_SCALE = 0.5, 1.5

local ThemeBase = {}

ThemeBase.Palette = {
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
	Ember = Color3.fromRGB(222, 140, 60), -- posture, warmth
	EmberDeep = Color3.fromRGB(130, 66, 22),
	Moon = Color3.fromRGB(110, 146, 220), -- info, cold side, ready
	Verdant = Color3.fromRGB(120, 196, 128), -- heals
	Moss = Color3.fromRGB(128, 178, 84), -- stamina
	MossDeep = Color3.fromRGB(46, 84, 32),
}

ThemeBase.Families = {
	Display = family(Enum.Font.Bodoni), -- high-contrast classical serif for titles
	Body = family(Enum.Font.Garamond), -- body text, labels, numbers
}

-- Our own drawn UI images (tools/vfx_textures.py, tools/ui_textures.py).
ThemeBase.Images = {
	Ring = "rbxassetid://126930541164453", -- white ring, swept into radial gauges
	BloodCrescent = "rbxassetid://114481905428903", -- Blood Blade emblem
	Glint = "rbxassetid://101126423932013", -- Light Beam emblem, lock-on glint
	Medallion = "rbxassetid://130555865843448", -- engraved bezel (light grey, tint it)
	Bullet = "rbxassetid://103235686741303", -- cartridge icon
	SoftGlow = "rbxassetid://75560931237584", -- round soft glow
	HuntCard = "rbxassetid://115279579388284", -- the Hunt tab's mode card: Victorian skyline at blood dusk
	RitualCircle = "rbxassetid://115419381323676", -- the blood circle under the character in the Blood Table menu
	Ribbon = "rbxassetid://134502622812389", -- brushed paint grain (grey; tinted), tiles 512x64
	TabFlourish = "rbxassetid://136447657638231", -- gold filigree for the active tab, 9-slice (72 px ends, 512x48)
}

-- MinRendered / MinCaption: the smallest text may ever render on screen, after scaling (UI standard section 2)
ThemeBase.TextSize = { Caption = 14, Body = 18, Label = 20, Title = 30, Display = 48, MinRendered = 16, MinCaption = 14 }

ThemeBase.ReferenceResolution = REFERENCE

-- The UIScale that fits the reference-authored UI to a viewport (uniform, so proportions hold on every screen).
function ThemeBase.FitScale(viewport: Vector2): number
	return math.clamp(math.min(viewport.X / REFERENCE.X, viewport.Y / REFERENCE.Y), MIN_SCALE, MAX_SCALE)
end

-- The TextSize to author so text drawn at `scale` renders at least `minimum` pixels tall.
function ThemeBase.LegibleSize(authored: number, minimum: number, scale: number): number
	return math.max(authored, math.ceil(minimum / math.max(scale, 0.01)))
end

return ThemeBase

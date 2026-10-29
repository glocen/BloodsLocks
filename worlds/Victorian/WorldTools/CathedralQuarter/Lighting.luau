--!strict
-- Lighting: the quarter's dusk (ChatGPT's spec section 9, CLAUDE.md rule 9: red/purple mood, blue and orange light).
-- The sky stays brighter than distant stone; cool, low ambient lets the small warm practicals (lamps, the portal,
-- candles) make the pools that lead the route; exposure is fixed so locations compare fairly. Keeps the place's own
-- stack (Sky, SunRays, Atmosphere, Bloom, DepthOfField) and adds one ColorCorrection. The first Apply backs up the
-- previous values to ServerStorage.WorldBackups.LightingBeforeW1 (kept on later rebuilds).

local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")

local LightingRig = {}

-- Tuned against views A and B (2026-10-29). The place's skybox has a warm horizon, so its image-based light
-- (EnvironmentDiffuseScale) is kept low: at 0.45 it tinted every wall orange. The low sun's colour is pulled cool
-- (ColorShift_Top) so stone stays cool and only the practicals are warm.
local SETTINGS: { [string]: any } = {
	ClockTime = 18.15,
	GeographicLatitude = 41,
	Brightness = 1.5,
	Ambient = Color3.fromRGB(36, 34, 54),
	OutdoorAmbient = Color3.fromRGB(100, 98, 142),
	ColorShift_Top = Color3.fromRGB(120, 140, 220),
	ColorShift_Bottom = Color3.fromRGB(30, 22, 40),
	EnvironmentDiffuseScale = 0.12,
	EnvironmentSpecularScale = 0.2,
	ExposureCompensation = 0,
	ShadowSoftness = 0.25,
}

local EFFECTS: { [string]: { [string]: any } } = {
	Atmosphere = {
		Density = 0.34, Offset = 0.12, Color = Color3.fromRGB(176, 128, 168), Decay = Color3.fromRGB(150, 70, 100),
		Glare = 0.4, Haze = 2.2,
	},
	Bloom = { Intensity = 0.5, Size = 24, Threshold = 1.4 },
	SunRays = { Intensity = 0.04, Spread = 0.6 },
	DepthOfField = { FarIntensity = 0.12, FocusDistance = 140, InFocusRadius = 120, NearIntensity = 0 },
}

local GRADE = { Name = "QuarterGrade", Brightness = 0, Contrast = 0.12, Saturation = -0.08, TintColor = Color3.fromRGB(238, 232, 248) }

local function backup()
	local root = ServerStorage:FindFirstChild("WorldBackups") or Instance.new("Folder")
	root.Name = "WorldBackups"
	root.Parent = ServerStorage
	if root:FindFirstChild("LightingBeforeW1") then
		return
	end
	local saved = Instance.new("Configuration")
	saved.Name = "LightingBeforeW1"
	for property in SETTINGS do
		saved:SetAttribute(property, (Lighting :: any)[property])
	end
	for _, child in Lighting:GetChildren() do
		local ok, copy = pcall(function()
			return child:Clone()
		end)
		if ok and copy then
			copy.Parent = saved
		end
	end
	saved.Parent = root
end

function LightingRig.Apply()
	backup()
	for property, value in SETTINGS do
		pcall(function()
			(Lighting :: any)[property] = value
		end)
	end
	for name, props in EFFECTS do
		local effect = Lighting:FindFirstChild(name)
		if effect then
			for property, value in props do
				(effect :: any)[property] = value
			end
		end
	end
	local grade = Lighting:FindFirstChild(GRADE.Name) or Instance.new("ColorCorrectionEffect")
	for property, value in GRADE do
		(grade :: any)[property] = value
	end
	grade.Parent = Lighting
end

return LightingRig

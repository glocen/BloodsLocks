--!strict
-- BloodBlade: the Crimson Crescent (its player-facing name), flying away from the caster, standing upright and facing
-- the camera like a sword wave (it reads from behind). Red with a black gradient (owner, 2026-10-31): our drawn
-- blade (Kit.Textures.CrescentShaded), a bold band, burns red along its convex edge and darkens across its thickness
-- to a crimson-black inner edge, all the way round the curve (never pure black, which vanishes against a night sky),
-- over a red rim halo and a faint black aura, on both faces of a thin plane, unlit so it reads the same in any
-- lighting. Streaks off the tips and apex fade from red to black; sparks; a mist going from crimson to black. A cast
-- flare on spawn; sparks, smoke, a faint shock shell and a light pop on impact. No gore, ever (AGENTS.md rule 4:
-- Roblox ToS): no drips, splatter or droplets, nothing that spills.

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Parent.UI.Theme)

local T = Kit.Textures
local P = Theme.Vfx

local SPAN = 10 -- tip to tip, studs
local ASPECT = 192 / 512 -- the crescent texture's height / width
local HEIGHT = SPAN * ASPECT
local ROLL = math.rad(-90) -- convex edge up → upright (tips up and down, a vertical slash)
local GLOW_SCALE = 1.24 -- the plane's size over the crescent's: room for the widest layer
-- Layers, back to front: {texture, tint, transparency, brightness, scale}.
local LAYERS = {
	{ T.CrescentHalo, P.SmokeDark, 0.4, 1, 1.22 }, -- a faint black aura: depth against a bright sky
	{ T.CrescentHalo, P.Blood, 0.05, 3, 1.12 },
	{ T.CrescentShaded, P.BloodCore, 0, 1.15, 1 }, -- drawn white into black: the tint makes it red into black
}
-- The blade lights what it passes: short enough that from chest height it never paints a red patch on the floor (at 7
-- it did, 2026-10-31).
local LIGHT = { Brightness = 1.4, Range = 4.5 }

export type Visual = { Root: BasePart, Faces: { SurfaceGui } }

local BloodBlade = {}

local function attachment(parent: Instance, position: Vector3): Attachment
	local a = Instance.new("Attachment")
	a.Position = position
	a.Parent = parent
	return a
end

local function streak(root: BasePart, position: Vector3, width: number)
	local a0 = attachment(root, position - Vector3.xAxis * width / 2)
	local a1 = attachment(root, position + Vector3.xAxis * width / 2)
	local t = Instance.new("Trail")
	t.Attachment0, t.Attachment1 = a0, a1
	t.Color = Kit.Colors(P.BloodCore, P.SmokeDark) -- red at the blade, black as it trails off
	t.Transparency = Kit.Seq({ { 0, 0.1 }, { 1, 1 } })
	t.WidthScale = Kit.Seq(1, 0)
	t.Lifetime = 0.2
	t.LightEmission = 0.2 -- mostly unlit, so its black end shows
	t.LightInfluence = 0
	t.FaceCamera = true
	t.Parent = root
end

-- One image layer on one face of the plane.
local function face(root: BasePart, normal: Enum.NormalId, layer: { any }, z: number): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Face = normal
	gui.LightInfluence = 0
	gui.Brightness = layer[4]
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(512, 512 * ASPECT * GLOW_SCALE)
	gui.ClipsDescendants = false
	gui.ZOffset = z
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Image = layer[1]
	image.ImageColor3 = layer[2]
	image.ImageTransparency = layer[3]
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromScale(0.5, 0.5)
	image.Size = UDim2.fromScale(layer[5] / GLOW_SCALE, layer[5] / GLOW_SCALE)
	image.Parent = gui
	gui.Parent = root
	return gui
end

function BloodBlade.Spawn(cframe: CFrame): Visual
	-- The plane: X across (tip to tip), Y up (convex edge), thin along Z (the travel direction).
	local root = Kit.Anchor(cframe, Vector3.new(SPAN * GLOW_SCALE, HEIGHT * GLOW_SCALE, 0.05))
	local faces = {}
	for index, layer in LAYERS do
		for _, normal in { Enum.NormalId.Back, Enum.NormalId.Front } do
			table.insert(faces, face(root, normal, layer, index))
		end
	end

	-- Texture → plane space: tips near the lower corners, apex at the top centre.
	streak(root, Vector3.new(-SPAN * 0.47, -HEIGHT * 0.22, 0), 0.3)
	streak(root, Vector3.new(SPAN * 0.47, -HEIGHT * 0.22, 0), 0.3)
	streak(root, Vector3.new(0, HEIGHT * 0.36, 0), 0.5)

	-- A mist going from crimson to black.
	Kit.Emitter(root, {
		Texture = T.SmokePuff,
		FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
		FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		Color = Kit.Colors(P.BloodDeep, P.SmokeDark),
		Size = Kit.Seq(1.6, 3.6),
		Transparency = Kit.Seq({ { 0, 1 }, { 0.15, 0.65 }, { 1, 1 } }),
		Lifetime = NumberRange.new(0.4, 0.65),
		Rate = 30,
		Speed = NumberRange.new(0.5, 1.5),
		SpreadAngle = Vector2.new(180, 180),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-40, 40),
		Drag = 3,
		LightEmission = 0.15,
		ZOffset = -1,
	})
	-- Sparks off the edge.
	Kit.Emitter(root, {
		Texture = T.SoftGlow,
		Color = Kit.Colors(P.BloodCore, P.BloodWet),
		Size = Kit.Seq(0.16, 0),
		Lifetime = NumberRange.new(0.2, 0.35),
		Rate = 40,
		Speed = NumberRange.new(6, 12),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 4,
		LightEmission = 0.5,
	})
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range, light.Shadows = P.Blood, LIGHT.Brightness, LIGHT.Range, false
	light.Parent = root

	local visual = { Root = root, Faces = faces }
	BloodBlade.Move(visual, cframe)
	BloodBlade.Cast(cframe)
	return visual
end

function BloodBlade.Move(visual: Visual, cframe: CFrame)
	visual.Root.CFrame = cframe * CFrame.Angles(0, 0, ROLL)
end

-- The flare of the blade leaving the muzzle.
function BloodBlade.Cast(cframe: CFrame)
	Kit.Burst(cframe, {
		{ Count = 1, Texture = T.CrescentArc,
			Color = Kit.Colors(P.BloodDark), Size = Kit.Seq(7.5), Transparency = Kit.Seq(0.05, 1), Lifetime = NumberRange.new(0.22),
			Rotation = NumberRange.new(-20, 20), ZOffset = -0.5 },
		{ Count = 1, Texture = T.CrescentArc,
			Color = Kit.Colors(P.BloodCore, P.BloodWet), Size = Kit.Seq(6.5), Lifetime = NumberRange.new(0.2),
			Rotation = NumberRange.new(-20, 20), LightEmission = 0.5 },
		{ Count = 12, Texture = T.Spark, Orientation = Enum.ParticleOrientation.VelocityParallel,
			Color = Kit.Colors(P.BloodCore, P.Blood), Size = Kit.Seq(0.4, 0.1), Lifetime = NumberRange.new(0.15, 0.3),
			Speed = NumberRange.new(10, 20), SpreadAngle = Vector2.new(45, 45), EmissionDirection = Enum.NormalId.Front,
			Drag = 5, LightEmission = 0.6 },
	})
	Kit.Flash(cframe.Position, P.Blood, 2.2, 8, 0.18)
end

-- Releases the blade where it stopped and bursts.
function BloodBlade.Impact(visual: Visual, position: Vector3, direction: Vector3)
	local cframe = CFrame.lookAt(position, position - direction)
	for _, gui in visual.Faces do
		gui:Destroy()
	end
	Kit.Release(visual.Root, 0.9)
	Kit.Burst(cframe, {
		{ Count = 1, Texture = T.CrescentArc,
			Color = Kit.Colors(P.BloodCore, P.BloodWet), Size = Kit.Seq(8.5), Lifetime = NumberRange.new(0.18), Rotation = NumberRange.new(-30, 30),
			LightEmission = 0.6 },
		{ Count = 20, Texture = T.Spark, Orientation = Enum.ParticleOrientation.VelocityParallel,
			Color = Kit.Colors(P.BloodCore, P.Blood), Size = Kit.Seq(0.5, 0.12), Lifetime = NumberRange.new(0.15, 0.3),
			Speed = NumberRange.new(16, 32), SpreadAngle = Vector2.new(70, 70), EmissionDirection = Enum.NormalId.Front,
			Drag = 5, LightEmission = 0.6 },
		{ Count = 20, Texture = T.SoftGlow, Color = Kit.Colors(P.BloodCore, P.BloodWet), Size = Kit.Seq(0.2, 0),
			Lifetime = NumberRange.new(0.2, 0.4), Speed = NumberRange.new(20, 40), SpreadAngle = Vector2.new(180, 180),
			Drag = 5, LightEmission = 0.6 },
		{ Count = 6, Texture = T.SmokePuff, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
			Color = Kit.Colors(P.BloodDeep, P.SmokeDark), Size = Kit.Seq(3, 7), Transparency = Kit.Seq({ { 0, 0.45 }, { 1, 1 } }),
			Lifetime = NumberRange.new(0.6, 0.9), Speed = NumberRange.new(3, 7), SpreadAngle = Vector2.new(180, 180),
			Rotation = NumberRange.new(0, 360), Drag = 4, LightEmission = 0.1, ZOffset = -1 },
	})
	local shell = Instance.new("Part")
	shell.Shape = Enum.PartType.Ball
	shell.Anchored, shell.CanCollide, shell.CanQuery, shell.CanTouch, shell.CastShadow = true, false, false, false, false
	shell.Material = Enum.Material.ForceField
	shell.Color = P.Blood
	shell.Size = Vector3.one
	shell.Position = position
	shell.Parent = workspace
	Kit.Tween(0.28, function(alpha)
		shell.Size = Vector3.one * (1 + 10 * (1 - (1 - alpha) ^ 3))
		shell.Transparency = 0.3 + 0.7 * alpha
	end, function()
		shell:Destroy()
	end)
	Kit.Flash(position, P.Blood, 3, 12, 0.3)
end

return BloodBlade

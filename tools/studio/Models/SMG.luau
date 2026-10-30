--!strict
-- Gustave's machine pistol (tools/blender/smg.py), assembled into Shared.Assets.Weapons.SMG. In Edit mode:
--   local Assembly = require(game.ServerStorage.BL_Tools.ModelAssembly:Clone())
--   local model = require(game.ServerStorage.BL_Tools.Models.SMG:Clone())(Assembly)
-- then Assembly.Serialize(model) decoded into src/shared/Assets/Weapons/SMG.rbxm. After a new smg.py run, publish the
-- meshes (Assembly.PublishMesh), upload the baked maps, update the ids and centres here, and empty build/import.
-- The crystal is the Light Beam's source: a glass shell over a glowing core, with a small light of its own (no
-- particles: the owner found sparkles off the mood). Names the game reads: Body (the PrimaryPart) with the Grip, Muzzle
-- and CrystalTip attachments; Crystal with Glow (its light).

local MESH = { Body = 116526349414004, Crystal = 125981520735452 }
-- Each mesh's centre: where its part sits (Assembly.Centre of its import, read when it was published)
local CENTRE = { Body = Vector3.new(0, 0.20089, -0.9275), Crystal = Vector3.new(0, 0.625, -0.71) }
local LOOK = { -- smg.py bake 3: Roblox-calibrated metals, padded UV islands
	ColorMap = "rbxassetid://134909209020802",
	NormalMap = "rbxassetid://135468981730422",
	RoughnessMap = "rbxassetid://110752538173658",
	MetalnessMap = "rbxassetid://97057329014535",
	EmissiveMaskContent = Content.fromUri("rbxassetid://97028928173823"), -- the garnets smoulder
	EmissiveStrength = 3,
}
local AMBER = Color3.fromRGB(255, 168, 82)
local CORE_SCALE = Vector3.new(0.5, 0.5, 0.8) -- the glowing core inside the shell (the crystal is long along Z)

-- Model-space points (the grip at the origin, forward is -Z), measured from smg.py.
local POINTS = {
	Grip = Vector3.zero,
	Muzzle = Vector3.new(0, 0.42, -2.03),
	CrystalTip = Vector3.new(0, 0.625, -0.95),
}

return function(Assembly: any): Model
	local model = Instance.new("Model")
	model.Name = "SMG"

	local body = Assembly.MeshPart(model, "Body", MESH.Body, CENTRE.Body)
	Assembly.New("SurfaceAppearance", body, LOOK)
	for name, position in POINTS do
		Assembly.Attach(body, name, position)
	end

	local crystal = Assembly.MeshPart(model, "Crystal", MESH.Crystal, CENTRE.Crystal, {
		Material = Enum.Material.Glass,
		Color = Color3.fromRGB(255, 214, 160),
		Transparency = 0.3,
		CastShadow = false,
	})
	local core = Assembly.MeshPart(model, "CrystalCore", MESH.Crystal, CENTRE.Crystal, {
		Material = Enum.Material.Neon,
		Color = AMBER,
		CastShadow = false,
	})
	core.Size = crystal.Size * CORE_SCALE
	Assembly.Weld(body, crystal)
	Assembly.Weld(body, core)

	Assembly.New("PointLight", crystal, { Name = "Glow", Color = AMBER, Brightness = 0.9, Range = 2.5, Shadows = false })

	model.PrimaryPart = body
	model.WorldPivot = CFrame.new()
	return model
end

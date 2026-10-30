--!strict
-- Gustave's sabre (tools/blender/saber.py), assembled into Shared.Assets.Weapons.Saber. In Edit mode:
--   local Assembly = require(game.ServerStorage.BL_Tools.ModelAssembly:Clone())
--   local model = require(game.ServerStorage.BL_Tools.Models.Saber:Clone())(Assembly)
-- then Assembly.Serialize(model) decoded into src/shared/Assets/Weapons/Saber.rbxm. After a new saber.py run, publish
-- the meshes (Assembly.PublishMesh), upload the baked maps, update the ids and centres here, and empty build/import.
-- Two meshes, two texture sets: the hilt (with the garnets' settings on the blade's root) and the inlaid black blade.
-- Names the game reads: Body (the PrimaryPart) with the Grip attachment; Blade (BloodCharge's glow) with BladeBase and
-- BladeTip (the slash trail's edges) and Jewel (the garnet at the blade's root, where skill flares start).

local MESH = { Body = 129487544831119, Blade = 119703721568985 }
-- Each mesh's centre: where its part sits (Assembly.Centre of its import, read when it was published)
local CENTRE = { Body = Vector3.new(0, -0.00912, -0.17074), Blade = Vector3.new(0, 2.12825, 0.08707) }
local LOOK = {
	Body = {
		ColorMap = "rbxassetid://115345506607797",
		NormalMap = "rbxassetid://72086923056910",
		RoughnessMap = "rbxassetid://101971965452950",
		MetalnessMap = "rbxassetid://135876394499853",
		EmissiveMaskContent = Content.fromUri("rbxassetid://98819299726120"), -- the garnets smoulder
		EmissiveStrength = 2,
	},
	Blade = {
		ColorMap = "rbxassetid://70508885454215",
		NormalMap = "rbxassetid://123593686747720",
		RoughnessMap = "rbxassetid://73200363888338",
		MetalnessMap = "rbxassetid://114508164977662",
	},
}

-- Model-space points (the grip at the origin, the blade along +Y, its edge toward -Z), printed by saber.py.
local POINTS = {
	Grip = Vector3.zero,
	BladeBase = Vector3.new(0, 0.9222, -0.0131),
	BladeTip = Vector3.new(0, 3.8033, 0.2777),
	Jewel = Vector3.new(0, 0.6532, -0.0031),
}

return function(Assembly: any): Model
	local model = Instance.new("Model")
	model.Name = "Saber"

	local body = Assembly.MeshPart(model, "Body", MESH.Body, CENTRE.Body)
	Assembly.New("SurfaceAppearance", body, LOOK.Body)
	Assembly.Attach(body, "Grip", POINTS.Grip)

	local blade = Assembly.MeshPart(model, "Blade", MESH.Blade, CENTRE.Blade)
	Assembly.New("SurfaceAppearance", blade, LOOK.Blade)
	for _, name in { "BladeBase", "BladeTip", "Jewel" } do
		Assembly.Attach(blade, name, POINTS[name])
	end
	Assembly.Weld(body, blade)

	model.PrimaryPart = body
	model.WorldPivot = CFrame.new()
	return model
end

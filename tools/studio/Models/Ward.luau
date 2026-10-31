--!strict
-- The ward (tools/blender/ward.py): the guard's crimson glass buckler, assembled into Shared.Assets.Vfx.Ward. In Edit
-- mode:
--   local Assembly = require(game.ServerStorage.BL_Tools.ModelAssembly:Clone())
--   local model = require(game.ServerStorage.BL_Tools.Models.Ward:Clone())(Assembly)
-- then Assembly.Serialize(model) decoded into src/shared/Assets/Vfx/Ward.rbxm. After a new ward.py run, publish the
-- meshes (Assembly.PublishMesh) and update the ids and centres here. Only the form and its materials live here:
-- Client.Vfx.Ward adds the tracery and crack Decals (ids from Vfx/Textures), the glow, embers and light, and drives it.
-- Names the game reads: Lens (the PrimaryPart) with the Centre and Face attachments, and Rim. Forward is -Z.

local MESH = { Lens = 80536993531212, Rim = 133062466600477 }
-- Each mesh's centre: where its part sits (Assembly.Centre of its import, read when it was published)
local CENTRE = { Lens = Vector3.new(0, 0, -0.0275), Rim = Vector3.zero }
local GLASS = Color3.fromRGB(70, 5, 16) -- dark crimson: the ward is darkest at its centre
local RIM = Color3.fromRGB(255, 74, 48)
local FACE = Vector3.new(0, 0, -0.125) -- the face's middle, where the dome stands furthest forward

return function(Assembly: any): Model
	local model = Instance.new("Model")
	model.Name = "Ward"
	local props = { Anchored = true, CastShadow = false }
	local lens = Assembly.MeshPart(model, "Lens", MESH.Lens, CENTRE.Lens, props)
	lens.Material = Enum.Material.Glass
	lens.Color = GLASS
	lens.Transparency = 0.3
	local rim = Assembly.MeshPart(model, "Rim", MESH.Rim, CENTRE.Rim, props)
	rim.Material = Enum.Material.Neon
	rim.Color = RIM
	Assembly.Attach(lens, "Centre", Vector3.zero)
	Assembly.Attach(lens, "Face", FACE)
	model.PrimaryPart = lens
	return model
end

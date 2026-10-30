--!strict
-- ModelAssembly: the Studio half of our art pipeline. tools/blender models and bakes; this publishes the meshes and
-- assembles game models from them. It runs in Edit mode from MCP execute_luau (plugin context), never in a game:
--   local Assembly = require(game.ServerStorage.BL_Tools.ModelAssembly:Clone()) -- a clone, so Rojo edits always load
-- Mesh data arrives through ServerStorage.BL_Import: build/import/<Name>.txt holds blcommon.export_mesh_json's JSON.
-- A published mesh keeps its vertex origin as the MeshPart's position, so exports are centred and record the centre
-- ("c"): parts are placed at Assembly.Centre(name). Slow work (publishing) runs as a named job: Assembly.Start(name, fn)
-- returns at once, Assembly.Status(name) reports "running", "done" (with the result) or the error.

local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")
local SerializationService = game:GetService("SerializationService")
local ServerStorage = game:GetService("ServerStorage")

type MeshData = { p: { number }, n: { number }, t: { number }, f: { number }, c: { number } }
type Job = { status: string, result: any }

local Assembly = {}

local FACE_BATCH = 2000 -- triangles added between yields, so Studio stays responsive
local BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function import(name: string): MeshData
	local value = ServerStorage:WaitForChild("BL_Import"):WaitForChild(name, 10)
	assert(value and value:IsA("StringValue"), `No import {name} (build/import/{name}.txt)`)
	return HttpService:JSONDecode(value.Value)
end

-- Where an import's mesh sits in model space (its bounding-box centre, the published mesh's origin).
function Assembly.Centre(name: string): Vector3
	local c = import(name).c
	return Vector3.new(c[1], c[2], c[3])
end

-- An EditableMesh from an import: centred positions, per-face normals and UVs ("f" holds 9 indices a triangle).
local function editable(data: MeshData): EditableMesh
	local mesh = AssetService:CreateEditableMesh()
	local p, n, t, f = data.p, data.n, data.t, data.f
	local vertices, normals, uvs = {}, {}, {}
	for i = 1, #p, 3 do
		table.insert(vertices, mesh:AddVertex(Vector3.new(p[i], p[i + 1], p[i + 2])))
	end
	for i = 1, #n, 3 do
		table.insert(normals, mesh:AddNormal(Vector3.new(n[i], n[i + 1], n[i + 2])))
	end
	for i = 1, #t, 2 do
		table.insert(uvs, mesh:AddUV(Vector2.new(t[i], t[i + 1])))
	end
	for i = 1, #f, 9 do
		local face = mesh:AddTriangle(vertices[f[i] + 1], vertices[f[i + 1] + 1], vertices[f[i + 2] + 1])
		mesh:SetFaceNormals(face, { normals[f[i + 3] + 1], normals[f[i + 4] + 1], normals[f[i + 5] + 1] })
		if #uvs > 0 then
			mesh:SetFaceUVs(face, { uvs[f[i + 6] + 1], uvs[f[i + 7] + 1], uvs[f[i + 8] + 1] })
		end
		if (i - 1) % (FACE_BATCH * 9) == 0 then
			task.wait()
		end
	end
	return mesh
end

-- Publishes an import as a Mesh asset owned by the place's creator; returns the asset id. Yields for seconds.
function Assembly.PublishMesh(name: string, assetName: string, description: string): number
	local result, id = AssetService:CreateAssetAsync(editable(import(name)), Enum.AssetType.Mesh, {
		Name = assetName,
		Description = description,
	})
	assert(result == Enum.CreateAssetResult.Success, `{assetName}: {result}`)
	return id
end

-- A new instance with properties, parented last.
function Assembly.New(className: string, parent: Instance, props: { [string]: any }?): Instance
	local instance = Instance.new(className)
	for key, value in props or {} do
		(instance :: any)[key] = value
	end
	instance.Parent = parent
	return instance
end

-- A MeshPart of a published mesh at a model-space position, with no physics or queries (a held or worn prop).
function Assembly.MeshPart(model: Model, name: string, meshId: number, position: Vector3, props: { [string]: any }?): MeshPart
	local part = AssetService:CreateMeshPartAsync(Content.fromAssetId(meshId), {
		CollisionFidelity = Enum.CollisionFidelity.Box,
		RenderFidelity = Enum.RenderFidelity.Precise,
	})
	part.Name = name
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.Massless = false, false, false, false, true
	part.CFrame = CFrame.new(position)
	for key, value in props or {} do
		(part :: any)[key] = value
	end
	part.Parent = model
	return part
end

-- Holds `part` to `to` where it stands now: a Weld with an explicit C0 (WeldConstraints in a cloned model don't hold
-- under Server Authority).
function Assembly.Weld(to: BasePart, part: BasePart): Weld
	local weld = Instance.new("Weld")
	weld.Part0, weld.Part1 = to, part
	weld.C0 = to.CFrame:ToObjectSpace(part.CFrame)
	weld.Parent = part
	return weld
end

-- An Attachment on `part` at a model-space position.
function Assembly.Attach(part: BasePart, name: string, position: Vector3): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.Position = part.CFrame:PointToObjectSpace(position)
	attachment.Parent = part
	return attachment
end

-- The model as .rbxm bytes in base64; decode it into src/shared/Assets/... (py -c "import base64 ...").
function Assembly.Serialize(model: Model): string
	local data = SerializationService:SerializeInstancesAsync({ model })
	local n = buffer.len(data)
	local out = table.create(math.ceil(n / 3))
	for i = 0, n - 1, 3 do
		local a = buffer.readu8(data, i)
		local b = if i + 1 < n then buffer.readu8(data, i + 1) else 0
		local c = if i + 2 < n then buffer.readu8(data, i + 2) else 0
		local v = a * 65536 + b * 256 + c
		local function char(shift: number): string
			local k = bit32.extract(v, shift, 6) + 1
			return BASE64:sub(k, k)
		end
		table.insert(out, char(18) .. char(12) .. (if i + 1 < n then char(6) else "=") .. (if i + 2 < n then char(0) else "="))
	end
	return table.concat(out)
end

-- Jobs live in _G: every require is a fresh clone, and the poll comes from a later MCP call.
local function jobs(): { [string]: Job }
	local shared = _G :: any
	shared.BL_Jobs = shared.BL_Jobs or {}
	return shared.BL_Jobs
end

function Assembly.Start(name: string, fn: () -> any)
	local job: Job = { status = "running", result = nil }
	jobs()[name] = job
	task.spawn(function()
		local ok, result = pcall(fn)
		job.status = if ok then "done" else `error: {result}`
		job.result = result
	end)
end

function Assembly.Status(name: string): (string, any)
	local job = jobs()[name]
	if not job then
		return "unknown", nil
	end
	return job.status, job.result
end

return Assembly

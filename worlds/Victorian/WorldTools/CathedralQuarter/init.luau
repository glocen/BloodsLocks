--!strict
-- CathedralQuarter (Victorian place, edit time): builds the first district's blockout from Layout into
-- workspace.CathedralQuarter and the match's other locations (Antechamber, final garden) into workspace.VictorianSites,
-- then applies the dusk Lighting. Idempotent: Build() replaces both roots. The first Build moves the place's old
-- baseplate and test enemy markers into ServerStorage.WorldBackups.PreW1 (the crypt needs the ground open).
-- Run (Studio command bar or MCP, edit mode):  require(game.ServerStorage.WorldTools.CathedralQuarter).Build()
-- Source of truth: worlds/Victorian/WorldTools/CathedralQuarter in the repo (this place is not synced by Rojo).

local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local Kit = require(script.Kit)
local Layout = require(script.Layout)
local LightingRig = require(script.Lighting)

local CathedralQuarter = {}

local ROOT = "CathedralQuarter"
local SITES = "VictorianSites"
local ARRIVAL = CFrame.lookAt(Vector3.new(0, 0.5, 222), Vector3.new(0, 0.5, 0))

-- A backup must never act as live world: its gameplay tags move into a "BackupTags" attribute.
local function disarm(root: Instance)
	for _, d in root:GetDescendants() do
		local tags = CollectionService:GetTags(d)
		if #tags > 0 then
			d:SetAttribute("BackupTags", table.concat(tags, ","))
			for _, tag in tags do
				CollectionService:RemoveTag(d, tag)
			end
		end
	end
end

local function backupOldWorld()
	local backups = ServerStorage:FindFirstChild("WorldBackups") or Instance.new("Folder")
	backups.Name = "WorldBackups"
	backups.Parent = ServerStorage
	local done = backups:FindFirstChild("PreW1")
	if done then
		disarm(done)
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "PreW1"
	for _, name in { "Baseplate", "BL_EnemySpawns" } do
		local old = workspace:FindFirstChild(name)
		if old then
			old.Parent = folder
		end
	end
	local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if spawn then
		folder:SetAttribute("SpawnLocationCFrame", spawn.CFrame)
	end
	disarm(folder)
	folder.Parent = backups
end

-- Builds one section into its own folder, then parents it (small subtrees keep Studio responsive).
local function section(parent: Instance, name: string, count: { number }, build: (any) -> ())
	local folder = Instance.new("Folder")
	folder.Name = name
	build(Kit.Builder(folder, count))
	folder.Parent = parent
	task.wait()
end

function CathedralQuarter.Build(): number
	backupOldWorld()
	for _, name in { ROOT, SITES } do
		local old = workspace:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	local count = { 0 }
	local root = Instance.new("Folder")
	root.Name = ROOT
	root.Parent = workspace
	section(root, "Ground", count, Layout.Ground)
	section(root, "Massing", count, Layout.Massing)
	section(root, "Cathedral", count, Layout.Cathedral)
	section(root, "Cloister", count, Layout.Cloister)
	section(root, "Upper", count, Layout.Upper)
	section(root, "Crypt", count, Layout.Crypt)
	section(root, "Lamps", count, Layout.Lamps)
	section(root, "Markers", count, Layout.Markers)
	local sites = Instance.new("Folder")
	sites.Name = SITES
	sites.Parent = workspace
	section(sites, "Antechamber", count, Layout.Antechamber)
	section(sites, "FinalGarden", count, Layout.FinalGarden)
	local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if spawn then
		spawn.CFrame = ARRIVAL -- until the match spawns players itself (L1)
	end
	LightingRig.Apply()
	return count[1]
end

return CathedralQuarter

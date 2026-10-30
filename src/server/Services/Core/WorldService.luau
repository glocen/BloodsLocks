--!strict
-- WorldService: checks this place's world against the world contract (Shared.World.Tags) at boot, so a typo in a
-- marker fails loudly in Studio instead of silently in a match. For every tagged part: right place role, required
-- attributes with the right types, ids that exist (enemies, zones of this place's map, Shinigami), and ground under
-- markers that need it. Tags this place's role requires but doesn't have are listed separately (with the plan slice
-- that starts needing them), since a world under construction legitimately lacks them.
-- Debug: BL_Debug:Invoke("WorldReport") returns the report as text.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Registry = require(Shared.Definitions.Registry)
local EntityState = require(Shared.Simulation.EntityState)
local WorldTags = require(Shared.World.Tags)
local Markers = require(Shared.World.Markers)
local Sightline = require(Shared.World.Sightline)
local PlaceRole = require(Shared.Util.PlaceRole)
local Raycast = require(Shared.Util.Raycast)
local Log = require(Shared.Util.Log)
local DebugService = require(script.Parent.DebugService)

local GROUND_PROBE = 60 -- studs a grounded marker looks down for a floor
local SPAWN_SIGHTLINE = 20 -- studs a spawn's most open view should reach
local MAX_LOGGED = 10 -- problems printed at boot (the report has them all)

export type Report = {
	Counts: { [string]: number },
	Problems: { string },
	Missing: { string },
}

local WorldService = {}

local map = Registry.MapForPlace(game.PlaceId)

-- Ids an attribute must name, by attribute.
local ID_CHECKS: { [string]: (string) -> boolean } = {
	Enemy = function(id)
		return Registry.Enemy(id) ~= nil
	end,
	Zone = function(id)
		return map ~= nil and map.Zones[id] ~= nil
	end,
	Region = function(id)
		return map ~= nil and map.Zones[id] ~= nil
	end,
	Shinigami = function(id)
		return Registry.Shinigami(id) ~= nil
	end,
}

local function hasRole(roles: { string }): boolean
	return table.find(roles, PlaceRole.Current) ~= nil
end

-- Every contract-tagged instance and every combat entity: ground probes look through them.
local function markerExclusions(): { Instance }
	local list: { Instance } = {}
	for _, spec in WorldTags do
		for _, instance in Markers.All(spec.Tag) do
			table.insert(list, instance)
		end
	end
	for _, entity in CollectionService:GetTagged(EntityState.Tag) do
		table.insert(list, entity)
	end
	return list
end

local function checkAttributes(instance: Instance, spec: WorldTags.Spec, problems: { string })
	local where = instance:GetFullName()
	for name, kind in spec.Attributes do
		local optional = string.sub(kind, -1) == "?"
		local wanted = if optional then string.sub(kind, 1, -2) else kind
		local value = instance:GetAttribute(name)
		if value == nil then
			if not optional then
				table.insert(problems, `{where} ({spec.Tag}): missing attribute {name}`)
			end
		elseif type(value) ~= wanted then
			table.insert(problems, `{where} ({spec.Tag}): {name} must be a {wanted}`)
		elseif ID_CHECKS[name] and not ID_CHECKS[name](value :: string) then
			table.insert(problems, `{where} ({spec.Tag}): unknown {name} "{value}"`)
		end
	end
end

-- Builds the report for the place as it is now.
function WorldService.Check(): Report
	local report: Report = { Counts = {}, Problems = {}, Missing = {} }
	local exclude = markerExclusions()
	for key, spec in WorldTags do
		local tagged = Markers.All(spec.Tag)
		local stored = #CollectionService:GetTagged(spec.Tag) - #tagged
		if stored > 0 then
			table.insert(report.Problems, `{stored} {spec.Tag} instance(s) outside workspace (masters/backups keep their tags; they're ignored)`)
		end
		report.Counts[spec.Tag] = #tagged
		if spec.RequiredIn and table.find(spec.RequiredIn, PlaceRole.Current) and #tagged == 0 then
			table.insert(report.Missing, `{spec.Tag}{if spec.Since then ` (needed from {spec.Since})` else ""}`)
		end
		for _, instance in tagged do
			local where = instance:GetFullName()
			if not instance:IsA("BasePart") then
				table.insert(report.Problems, `{where} ({spec.Tag}): must be a part`)
				continue
			end
			if not hasRole(spec.Roles) then
				table.insert(report.Problems, `{where}: {spec.Tag} isn't used in {PlaceRole.Current} places`)
			end
			checkAttributes(instance, spec, report.Problems)
			if key == "EnemySpawn" and instance:GetAttribute("Enemy") == nil and instance:GetAttribute("Zone") == nil then
				table.insert(report.Problems, `{where} ({spec.Tag}): needs an Enemy or a Zone attribute`)
			end
			if key == "Spawn" then
				-- a hunter arrives facing the spawn's most open way: it should open onto real room
				local _, reach = Sightline.Best(instance.Position - Vector3.new(0, instance.Size.Y / 2, 0), { instance })
				if reach < SPAWN_SIGHTLINE then
					table.insert(report.Problems, `{where} ({spec.Tag}): cramped, its most open view is {math.floor(reach)} studs (want {SPAWN_SIGHTLINE}+)`)
				end
			end
			if spec.Grounded then
				local hit = workspace:Raycast(instance.Position + Vector3.new(0, 1, 0), Vector3.new(0, -GROUND_PROBE, 0), Raycast.Exclude(exclude, true))
				if not hit then
					table.insert(report.Problems, `{where} ({spec.Tag}): no ground within {GROUND_PROBE} studs below`)
				end
			end
		end
	end
	table.sort(report.Problems)
	table.sort(report.Missing)
	return report
end

-- The report as readable text.
function WorldService.Format(report: Report): string
	local counts = {}
	for tag, count in report.Counts do
		if count > 0 then
			table.insert(counts, `{tag} {count}`)
		end
	end
	table.sort(counts)
	local lines = {
		`WORLD ({PlaceRole.Current}): {#report.Problems} problem(s), {#report.Missing} missing`,
		`tagged: {if #counts > 0 then table.concat(counts, ", ") else "nothing"}`,
	}
	for _, missing in report.Missing do
		table.insert(lines, `MISSING  {missing}`)
	end
	for _, problem in report.Problems do
		table.insert(lines, `PROBLEM  {problem}`)
	end
	return table.concat(lines, "\n")
end

function WorldService.Init()
	DebugService.Register("WorldReport", function()
		return WorldService.Format(WorldService.Check())
	end)
end

function WorldService.Start()
	local report = WorldService.Check()
	for i, problem in report.Problems do
		if i > MAX_LOGGED then
			Log.Warn("WorldService", `...and {#report.Problems - MAX_LOGGED} more (BL_Debug:Invoke("WorldReport"))`)
			break
		end
		Log.Warn("WorldService", problem)
	end
	local missing = if #report.Missing > 0 then `; not built yet: {table.concat(report.Missing, ", ")}` else ""
	Log.Info("WorldService", `world checked: {#report.Problems} problem(s){missing}`)
end

return WorldService

--!strict
-- Loader: boots a set of service or controller modules in two phases.
--   1. Require every ModuleScript in the given folders (sub-folders included, modules nested inside
--      other modules excluded), then call Init() on each. Init only sets up the module's own state.
--   2. Call Start() on each in its own thread. Modules may use each other from Start on.
-- The boot summary counts errors from require and Init. Start runs afterwards (and may yield), so each Start
-- failure is logged on its own line with a running count.
-- Order is deterministic: lower Priority first (default 100), then by full path.
-- Module names must be unique, because other code refers to modules by name.

local Log = require(script.Parent.Log)

export type Module = {
	Priority: number?,
	Init: ((self: any) -> ())?,
	Start: ((self: any) -> ())?,
}

type Entry = {
	Name: string,
	Path: string,
	Module: Module,
}

local Loader = {}

local function collect(folder: Instance, into: { ModuleScript })
	for _, child in folder:GetChildren() do
		if child:IsA("ModuleScript") then
			table.insert(into, child)
		elseif child:IsA("Folder") then
			collect(child, into)
		end
	end
end

-- Returns the booted modules by name and the number of errors during require and Init.
function Loader.Boot(label: string, folders: { Instance? }): ({ [string]: Module }, number)
	local scripts: { ModuleScript } = {}
	for _, folder in folders do
		if folder then
			collect(folder, scripts)
		end
	end

	local entries: { Entry } = {}
	local errors = 0
	for _, moduleScript in scripts do
		local ok, result = pcall(require, moduleScript)
		if ok and type(result) == "table" then
			table.insert(entries, { Name = moduleScript.Name, Path = moduleScript:GetFullName(), Module = result })
		else
			errors += 1
			local reason = if ok then "it must return a table" else tostring(result)
			Log.Error(label, `failed to load {moduleScript:GetFullName()}: {reason}`)
		end
	end

	table.sort(entries, function(a, b)
		local priorityA, priorityB = a.Module.Priority or 100, b.Module.Priority or 100
		if priorityA ~= priorityB then
			return priorityA < priorityB
		end
		return a.Path < b.Path
	end)

	local byName: { [string]: Module } = {}
	for _, entry in entries do
		if byName[entry.Name] then
			errors += 1
			Log.Error(label, `two modules are named "{entry.Name}"; module names must be unique`)
		end
		byName[entry.Name] = entry.Module
	end

	for _, entry in entries do
		local init = entry.Module.Init
		if init then
			local ok, err = xpcall(init, debug.traceback, entry.Module)
			if not ok then
				errors += 1
				Log.Error(label, `{entry.Name}.Init failed: {err}`)
			end
		end
	end

	local names = table.create(#entries)
	for i, entry in entries do
		names[i] = entry.Name
	end
	local list = if #names > 0 then ` ({table.concat(names, ", ")})` else ""
	Log.Info(label, `booted {#entries} modules{list} with {errors} errors in require/Init`)

	local startErrors = 0
	for _, entry in entries do
		local start = entry.Module.Start
		if start then
			task.spawn(function()
				local ok, err = xpcall(start, debug.traceback, entry.Module)
				if not ok then
					startErrors += 1
					Log.Error(label, `{entry.Name}.Start failed ({startErrors} Start failure(s) so far): {err}`)
				end
			end)
		end
	end
	return byName, errors
end

return Loader

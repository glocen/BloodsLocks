--!strict
-- Log: one prefix and format for every BloodsLocks message, so the output is easy to filter.

local PREFIX = "[BL]"

local Log = {}

local function format(scope: string, ...: any): string
	local count = select("#", ...)
	local parts = table.create(count)
	for i = 1, count do
		parts[i] = tostring((select(i, ...)))
	end
	return `{PREFIX} {scope}: {table.concat(parts, " ")}`
end

function Log.Info(scope: string, ...: any)
	print(format(scope, ...))
end

function Log.Warn(scope: string, ...: any)
	warn(format(scope, ...))
end

-- Shows as a red error in the output without stopping the caller.
function Log.Error(scope: string, ...: any)
	task.spawn(error, format(scope, ...), 0)
end

return Log

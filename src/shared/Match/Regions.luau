--!strict
-- Regions: who starts each phase where. Pure math, no state; MatchService applies it and LogicTestService tests it.
-- Plan section 3: each region holds ceil(entrants / regions) + 1; a choice for a full region moves that entrant to
-- a random region with room (the move is reported so the screen can explain it); no choice (or an unknown region)
-- gets a random region with room. Choices are honoured first come, first served (the order of `ids`).

local Regions = {}

export type Assignment = { Region: string, Moved: boolean }

function Regions.Capacity(entrants: number, regionCount: number): number
	return math.ceil(entrants / math.max(1, regionCount)) + 1
end

-- `ids` in priority order; `choices[id]` is the region asked for (or nil); `regions` the valid ids (in a fixed order).
function Regions.Allocate(ids: { number }, choices: { [number]: string? }, regions: { string }, random: Random): { [number]: Assignment }
	local capacity = Regions.Capacity(#ids, #regions)
	local load: { [string]: number } = {}
	local valid: { [string]: boolean } = {}
	for _, region in regions do
		load[region], valid[region] = 0, true
	end
	local result: { [number]: Assignment } = {}
	local unplaced: { number } = {}
	for _, id in ids do
		local wanted = choices[id]
		if wanted and valid[wanted] and load[wanted] < capacity then
			load[wanted] += 1
			result[id] = { Region = wanted, Moved = false }
		else
			table.insert(unplaced, id)
		end
	end
	for _, id in unplaced do
		local open = {}
		for _, region in regions do
			if load[region] < capacity then
				table.insert(open, region)
			end
		end
		local region = if #open > 0 then open[random:NextInteger(1, #open)] else regions[random:NextInteger(1, #regions)]
		load[region] += 1
		local wanted = choices[id]
		result[id] = { Region = region, Moved = wanted ~= nil and valid[wanted] == true }
	end
	return result
end

return Regions

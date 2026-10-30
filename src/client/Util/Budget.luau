--!strict
-- Budget: how long each per-frame updater takes. Wrap an updater with Budget.Wrap(name, fn) (or time a block with
-- Budget.Add); Budget.Report() gives each name's average milliseconds per call over the last WINDOW calls. The
-- self-test's "Frame budget" case checks them against Budget.Limits, so a slow updater fails a test instead of
-- quietly eating the frame.

local Budget = {}

local WINDOW = 120 -- calls averaged

-- Milliseconds per call an updater may average (the frame is ~16.7 ms at 60 fps; these leave room for the game).
Budget.Limits = {
	Plates = 0.6,
	Callouts = 0.2,
	Match = 1.2,
}

type Track = { Samples: { number }, Next: number }
local tracks: { [string]: Track } = {}

function Budget.Add(name: string, milliseconds: number)
	local track = tracks[name]
	if not track then
		track = { Samples = {}, Next = 1 }
		tracks[name] = track
	end
	track.Samples[track.Next] = milliseconds
	track.Next = track.Next % WINDOW + 1
end

-- The same function, timed under `name`.
function Budget.Wrap<A...>(name: string, fn: (A...) -> ()): (A...) -> ()
	return function(...: A...)
		local start = os.clock()
		fn(...)
		Budget.Add(name, (os.clock() - start) * 1000)
	end
end

-- { [name] = average ms per call } over the last WINDOW calls of each.
function Budget.Report(): { [string]: number }
	local out = {}
	for name, track in tracks do
		local sum = 0
		for _, sample in track.Samples do
			sum += sample
		end
		out[name] = sum / math.max(1, #track.Samples)
	end
	return out
end

return Budget

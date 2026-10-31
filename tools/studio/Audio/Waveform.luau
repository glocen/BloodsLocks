--!strict
-- Waveform: measures a library sound's shape, so a slice can be chosen and levelled without hearing it (Studio, Edit
-- mode, MCP execute_luau). AudioPlayer:GetWaveformAsync returns point samples, at most 8192 a call, so the sound is
-- read in short windows:
--   local Waveform = require(game.ServerStorage.BL_Tools.Audio.Waveform:Clone())
--   print(Waveform.Describe(Waveform.Measure(9119746598)))
-- A shape lists the sound's events (bursts split by quiet), each with its attack, decay and band balance, plus an
-- envelope sketch. Waveform.Level measures a slice's loudness, which Sfx uses to play every cue at the same level.

local SoundService = game:GetService("SoundService")

local RATE = 32000 -- samples a second we read at: the envelope and three bands, with little aliasing
local CHUNK = 8192 -- the most GetWaveformAsync returns in one call
local WINDOW = 0.01 -- seconds per envelope step
local FLOOR_DB = -45 -- an event is where the envelope stays above the loudest point minus this (keeps tails)
local GAP = 0.08 -- seconds of quiet that split two events
local MAX_LENGTH = 15 -- seconds read at most
local LOAD_TIMEOUT = 6
local LOW_HZ, HIGH_HZ = 250, 2500 -- the band edges: low (body, thump), mid, high (air, metal, hiss)
local SKETCH = 48 -- characters in an envelope sketch
local SKETCH_LEVELS = { { -3, "@" }, { -6, "%" }, { -10, "#" }, { -15, "*" }, { -20, "+" }, { -26, "=" }, { -32, "-" }, { -40, ":" }, { -50, "." } }

local Waveform = {}

export type Event = {
	Start: number,
	Peak: number,
	End: number,
	Level: number, -- the event's loudest point, dB below the sound's loudest (0 for the loudest event)
	Attack: number, -- seconds from its start to its peak
	Decay20: number, -- seconds from its peak to 20 dB down
	Decay40: number, -- seconds from its peak to 40 dB down (or to its end)
	Low: number, -- energy shares (0..1) of its three bands
	Mid: number,
	High: number,
}

export type Shape = {
	Id: number,
	Length: number,
	Loudest: number, -- dBFS
	Envelope: { number }, -- peak per WINDOW, linear
	Events: { Event },
}

local function db(linear: number): number
	return if linear > 1e-6 then 20 * math.log10(linear) else -120
end

-- Reads the sound's samples at RATE; nil if it doesn't load.
local function read(id: number): ({ number }?, number)
	local player = Instance.new("AudioPlayer")
	player.Name = "BL_WaveformProbe"
	player.Asset = `rbxassetid://{id}`
	player.Parent = SoundService -- GetWaveformAsync needs it in the DataModel
	local started = os.clock()
	while not player.IsReady and os.clock() - started < LOAD_TIMEOUT do
		task.wait(0.03)
	end
	local length = math.min(player.TimeLength, MAX_LENGTH)
	if not player.IsReady or length <= 0 then
		player:Destroy()
		return nil, 0
	end
	local samples: { number } = {}
	local span = CHUNK / RATE
	local from = 0
	while from < length do
		local to = math.min(from + span, length)
		local count = math.max(1, math.floor((to - from) * RATE + 0.5))
		local ok, chunk = pcall(player.GetWaveformAsync, player, NumberRange.new(from, to), count)
		if not ok then
			player:Destroy()
			return nil, 0
		end
		table.move(chunk, 1, #chunk, #samples + 1, samples)
		from = to
	end
	player:Destroy()
	return samples, length
end

local function envelope(samples: { number }): { number }
	local per = math.floor(WINDOW * RATE)
	local out = {}
	for start = 1, #samples, per do
		local peak = 0
		for i = start, math.min(start + per - 1, #samples) do
			peak = math.max(peak, math.abs(samples[i]))
		end
		table.insert(out, peak)
	end
	return out
end

-- Energy shares of the low, mid and high bands between two times (one-pole filters).
local function bands(samples: { number }, from: number, to: number): (number, number, number)
	local lowA = 1 - math.exp(-2 * math.pi * LOW_HZ / RATE)
	local highA = 1 - math.exp(-2 * math.pi * HIGH_HZ / RATE)
	local lowState, highState = 0, 0
	local low, mid, high = 0, 0, 0
	for i = math.max(1, math.floor(from * RATE) + 1), math.min(#samples, math.floor(to * RATE)) do
		local x = samples[i]
		lowState += lowA * (x - lowState)
		highState += highA * (x - highState)
		local lowPart = lowState
		local highPart = x - highState
		local midPart = x - lowPart - highPart
		low += lowPart * lowPart
		mid += midPart * midPart
		high += highPart * highPart
	end
	local total = low + mid + high
	if total <= 0 then
		return 0, 0, 0
	end
	return low / total, mid / total, high / total
end

-- The time from `peakIndex` until the envelope first falls `drop` dB under it (or to `last`).
local function decay(env: { number }, peakIndex: number, last: number, drop: number): number
	local limit = env[peakIndex] * 10 ^ (-drop / 20)
	for i = peakIndex, last do
		if env[i] < limit then
			return (i - peakIndex) * WINDOW
		end
	end
	return (last - peakIndex) * WINDOW
end

local function events(env: { number }, samples: { number }, loudest: number): { Event }
	local floor = loudest * 10 ^ (FLOOR_DB / 20)
	local gapSteps = math.ceil(GAP / WINDOW)
	local found: { Event } = {}
	local i = 1
	while i <= #env do
		if env[i] >= floor then
			local first, last, quiet = i, i, 0
			local j = i + 1
			while j <= #env and quiet < gapSteps do
				if env[j] >= floor then
					last, quiet = j, 0
				else
					quiet += 1
				end
				j += 1
			end
			local peakIndex = first
			for k = first, last do
				if env[k] > env[peakIndex] then
					peakIndex = k
				end
			end
			-- the attack starts where this event rises within 30 dB of its own peak
			local onset = first
			local rise = env[peakIndex] * 10 ^ (-30 / 20)
			for k = first, peakIndex do
				if env[k] >= rise then
					onset = k
					break
				end
			end
			local low, mid, high = bands(samples, (first - 1) * WINDOW, last * WINDOW)
			table.insert(found, {
				Start = (first - 1) * WINDOW,
				Peak = (peakIndex - 1) * WINDOW,
				End = last * WINDOW,
				Level = db(env[peakIndex]) - db(loudest),
				Attack = (peakIndex - onset) * WINDOW,
				Decay20 = decay(env, peakIndex, last, 20),
				Decay40 = decay(env, peakIndex, last, 40),
				Low = low,
				Mid = mid,
				High = high,
			})
			i = last + 1
		else
			i += 1
		end
	end
	return found
end

-- The shape of a library sound, or nil if it doesn't load.
function Waveform.Measure(id: number): Shape?
	local samples, length = read(id)
	if not samples or #samples == 0 then
		return nil
	end
	local env = envelope(samples)
	local loudest = 0
	for _, peak in env do
		loudest = math.max(loudest, peak)
	end
	if loudest <= 0 then
		return nil
	end
	return { Id = id, Length = length, Loudest = db(loudest), Envelope = env, Events = events(env, samples, loudest) }
end

-- A slice's loudness in dBFS: the RMS of its loudest 100 ms, which is what the ear compares between short sounds.
function Waveform.Level(id: number, from: number, to: number): number?
	local samples = read(id)
	if not samples then
		return nil
	end
	local per = math.floor(0.1 * RATE)
	local first = math.max(1, math.floor(from * RATE) + 1)
	local last = math.min(#samples, math.floor(to * RATE))
	local best = 0
	for start = first, math.max(first, last - per + 1), math.floor(per / 4) do
		local sum, n = 0, 0
		for i = start, math.min(start + per - 1, last) do
			sum += samples[i] * samples[i]
			n += 1
		end
		if n > 0 then
			best = math.max(best, math.sqrt(sum / n))
		end
	end
	return db(best)
end

-- The envelope between two times as a row of characters (louder = denser).
function Waveform.Sketch(shape: Shape, from: number?, to: number?): string
	local first = math.floor((from or 0) / WINDOW) + 1
	local last = math.min(#shape.Envelope, math.ceil((to or shape.Length) / WINDOW))
	local loudest = 10 ^ (shape.Loudest / 20)
	local chars = {}
	local columns = math.min(SKETCH, last - first + 1)
	for c = 1, columns do
		local a = first + math.floor((c - 1) * (last - first + 1) / columns)
		local b = first + math.floor(c * (last - first + 1) / columns) - 1
		local peak = 0
		for i = a, math.max(a, b) do
			peak = math.max(peak, shape.Envelope[i] or 0)
		end
		local level = db(peak) - db(loudest)
		local char = " "
		for _, step in SKETCH_LEVELS do
			if level >= step[1] then
				char = step[2]
				break
			end
		end
		table.insert(chars, char)
	end
	return table.concat(chars)
end

function Waveform.DescribeEvent(event: Event): string
	return string.format(
		"%.2f-%.2f peak %.2f (%+.0f dB) attack %.2f, -20 dB %.2f, -40 dB %.2f | low %d%% mid %d%% high %d%%",
		event.Start, event.End, event.Peak, event.Level, event.Attack, event.Decay20, event.Decay40,
		math.round(event.Low * 100), math.round(event.Mid * 100), math.round(event.High * 100)
	)
end

-- A few lines on a shape: length, loudness, each event (at most `limit`), and the sketch.
function Waveform.Describe(shape: Shape?, limit: number?): string
	if not shape then
		return "(didn't load)"
	end
	local lines = { string.format("%d | %.2f s | %.0f dBFS | %d event(s) [%s]", shape.Id, shape.Length, shape.Loudest,
		#shape.Events, Waveform.Sketch(shape)) }
	for index, event in shape.Events do
		if index > (limit or 4) then
			table.insert(lines, `  ... {#shape.Events - index + 1} more`)
			break
		end
		table.insert(lines, `  #{index} {Waveform.DescribeEvent(event)}`)
	end
	return table.concat(lines, "\n")
end

return Waveform

--!strict
-- Shortlist: searches Roblox's audio library for one cue's brief (Briefs), measures every find (Waveform) and ranks
-- them, so the owner auditions only the likeliest slices (Studio, Edit mode, MCP execute_luau):
--   local Shortlist = require(game.ServerStorage.BL_Tools.Audio.Shortlist:Clone())
--   print(Shortlist.Format(Shortlist.Run("SaberSwing")))
--   print(Shortlist.CueLine(9119749145, "SaberSwing")) -- a sound the owner chose: the cue line to paste
-- Each pick carries a suggested slice (From, To), where it peaks inside it, and its loudness (Level): the fields a
-- library cue takes in Definitions/Sounds. Titles that name gore, another game or franchise, or a joke never pass
-- (AGENTS.md rules 3 and 4). Licensed uploads rank a little higher (AGENTS.md rule 2, "Sounds").

local ServerStorage = game:GetService("ServerStorage")

local AUDIO = ServerStorage:WaitForChild("BL_Tools"):WaitForChild("Audio")

local function fresh(name: string): any
	return require(AUDIO:WaitForChild(name):Clone()) -- a clone, so Rojo edits always load
end

local Briefs = fresh("Briefs")
local Library = fresh("Library")
local Waveform = fresh("Waveform")

-- Title words and phrases that rule a sound out for every cue.
local GORE = { -- the ToS (rule 4)
	"blood", "bloody", "gore", "gory", "flesh", "gut", "guts", "squish", "squishy", "squelch", "splat", "splatter",
	"wet", "meat", "bone", "bones", "crunch", "crunchy", "vomit", "decapitate", "decapitation", "dismember", "stab",
	"stabbing", "kill", "death", "die", "dying", "scream", "screams", "pain", "hurt", "groan", "moan", "kiss", "fart",
	"burp", "torture", "brain", "organ",
}
-- Other games and franchises (rule 3: never their sounds). Generic words that are also titles stay allowed. Names of
-- six letters or more also rule out run-together titles ("nuclearthronekillsound").
local OTHER_WORKS = {
	"minecraft", "zelda", "mario", "sonic the hedgehog", "sega", "pokemon", "fortnite", "skyrim", "elden", "elden ring",
	"bloodborne", "duskbloods", "dark souls", "demon souls", "valorant", "overwatch", "undertale", "deltarune",
	"terraria", "csgo", "cs go", "counter strike", "call of duty", "cod", "warzone", "tf2", "team fortress", "half life",
	"star wars", "lightsaber", "light saber", "jedi", "sith", "naruto", "bleach", "anime", "dbz", "dragon ball", "goku",
	"jojo", "demon slayer", "genshin", "type soul", "deepwoken", "rogue lineage", "blox fruits", "piggy", "bedwars",
	"phantom forces", "jailbreak", "gta", "red dead", "witcher", "metal gear", "resident evil", "fnaf", "five nights",
	"among us", "hollow knight", "cuphead", "smash bros", "street fighter", "tekken", "mortal kombat", "god of war",
	"devil may cry", "dmc", "sekiro", "monster hunter", "league of legends", "dota", "pubg", "rainbow six",
	"battlefield", "titanfall", "warframe", "borderlands", "bioshock", "fallout", "nier", "final fantasy",
	"kingdom hearts", "metroid", "kirby", "splatoon", "marvel", "batman", "spiderman", "spider man", "harry potter",
	"lord of the rings", "lotr", "game of thrones", "jurassic", "transformers", "terminator", "john wick", "kill bill",
	"pirates of the caribbean", "nuclear throne", "risk of rain", "enter the gungeon", "hotline miami",
	"binding of isaac", "dead cells", "hyper light drifter", "ultrakill", "doom eternal", "stardew",
	"brawl stars", "clash royale", "clash of clans", "castle crashers", "hl2", "half life 2", "gmod", "garry",
	"l4d", "left 4 dead", "portal 2", "dark deception",
	-- their characters and named moves (rips carry them: "Yamato_power_slash", "KungLao_Energy_Blast")
	"yamato", "vergil", "kung lao", "reiko", "sub zero", "ki blast", "kamehameha", "sora", "tanjiro", "zenitsu",
	"gojo", "sukuna", "jujutsu", "jjk", "luffy", "ichigo", "getsuga", "bankai", "zanpakuto", "rasengan", "chidori",
	-- paid libraries a community upload can't have the right to share
	"es", "epidemic sound", "artlist", "boom library", "boomlibrary", "zapsplat", "soundsnap", "audiojungle", "pond5",
}
local JUNK = { -- jokes, music and voices
	"cartoon", "cartoony", "cheesy", "comic", "comedy", "funny", "silly", "meme", "troll", "earrape", "ear rape",
	"bass boosted", "remix", "song", "music", "theme", "ost", "soundtrack", "anthem", "toy", "kids", "baby", "goofy",
	"boing", "squeak", "squeaky", "slide whistle", "voice", "voices", "talking", "speech", "laugh", "laughing", "cry",
	"crying", "male", "female", "man", "woman", "girl", "boy", "grunt", "yell", "shout",
}
local RUN_TOGETHER_MIN = 6 -- letters: shorter names are too likely inside ordinary words

local LICENSED_BONUS = 0.35
local PREFER_BONUS, PREFER_MOST = 0.1, 0.3
local QUIET_DBFS, QUIET_PENALTY = -24, 0.3 -- a quiet file brings its noise floor up with it
local LOUD_EVENT_DB = -10 -- events this close to the loudest are slice candidates
local OVERLAP_DB = -20 -- another event this loud inside a slice is heard as a second sound
local PRE_ROLL, POST_ROLL = 0.01, 0.02 -- seconds kept before an event's start and after its end

local Shortlist = {}

export type Pick = {
	Cue: string,
	Id: number,
	Title: string,
	Creator: string,
	Licensed: boolean,
	Keyword: string,
	From: number,
	To: number,
	Peak: number, -- seconds into the slice where it's loudest
	Level: number?, -- the slice's loudness, dBFS (Waveform.Level)
	Score: number, -- lower fits the brief better
	Shape: string, -- the measured event, for the record
}

local function normalized(title: string): string
	local text = string.lower(title):gsub("[^%w]+", " "):gsub("%s+", " ")
	return ` {text} `
end

local function mentions(text: string, phrases: { string }): number
	local count = 0
	for _, phrase in phrases do
		if string.find(text, ` {phrase} `, 1, true) then
			count += 1
		end
	end
	return count
end

-- Whether a title (normalized) passes the gore, other-works and junk lists and a brief's own Avoid words.
local function allowed(text: string, avoid: { string }?): boolean
	if not string.find(text, "%a") then
		return false -- a title Roblox's filter replaced with ####: nothing to judge it by
	end
	if mentions(text, GORE) > 0 or mentions(text, OTHER_WORKS) > 0 or mentions(text, JUNK) > 0 then
		return false
	end
	if avoid and mentions(text, avoid) > 0 then
		return false
	end
	local squashed = text:gsub("%s+", "")
	for _, name in OTHER_WORKS do
		local letters = name:gsub("%s+", "")
		if #letters >= RUN_TOGETHER_MIN and string.find(squashed, letters, 1, true) then
			return false
		end
	end
	return true
end

-- Whether a library title may be used for this cue (the same test Run applies), for checking older shortlists.
function Shortlist.Allowed(title: string, cueName: string): boolean
	local brief = Briefs[cueName]
	return allowed(normalized(title), brief and brief.Avoid)
end

-- A title's series: the words without numbers, so "Sword Hit 1" and "Sword Hit 7" count as one.
local function series(text: string): string
	return (text:gsub("%d+", ""):gsub("%s+", " "))
end

local function outside(value: number, range: { number }): number
	local width = math.max(range[2] - range[1], 0.03)
	if value < range[1] then
		return (range[1] - value) / width
	elseif value > range[2] then
		return (value - range[2]) / width
	end
	return 0
end

local function bandsOff(event: any, target: any): number
	return math.abs(event.Low - target.Low) + math.abs(event.Mid - target.Mid) + math.abs(event.High - target.High)
end

-- Whether another loud event starts inside [from, to).
local function overlapped(shape: any, own: any, from: number, to: number): boolean
	for _, other in shape.Events do
		if other ~= own and other.Level >= OVERLAP_DB and other.Start >= from and other.Start < to then
			return true
		end
	end
	return false
end

type Slice = { From: number, To: number, Peak: number, Score: number, Event: any }

local function hitSlice(shape: any, event: any, brief: any): Slice
	local from = math.max(0, event.Start - PRE_ROLL)
	local natural = math.min(shape.Length, event.End + POST_ROLL)
	local to = math.min(natural, from + brief.Slice[2])
	local score = 0
	if natural - from < brief.Slice[1] then
		score += (brief.Slice[1] - (natural - from)) / brief.Slice[1] * 2
	end
	local kept = to - event.Peak -- how much of its decay the slice keeps
	if kept < event.Decay20 then
		score += (event.Decay20 - kept) / brief.Slice[2] * 2
	end
	score += outside(event.Attack, brief.Attack)
	score += outside(event.Decay40, brief.Tail)
	score += bandsOff(event, brief.Bands) * 1.5
	if overlapped(shape, event, from + 0.005, to) then
		score += 1
	end
	return { From = from, To = to, Peak = event.Peak - from, Score = score, Event = event }
end

local function sequenceSlice(shape: any, index: number, brief: any): Slice
	local events = shape.Events
	local first = events[index]
	local from = math.max(0, first.Start - PRE_ROLL)
	local last, count = first, 1
	for k = index + 1, #events do
		if events[k].End + POST_ROLL - from > brief.Slice[2] then
			break
		end
		last, count = events[k], count + 1
	end
	local to = math.min(shape.Length, last.End + POST_ROLL)
	local loudest = first
	for k = index, index + count - 1 do
		if events[k].Level > loudest.Level then
			loudest = events[k]
		end
	end
	local score = 0
	if to - from < brief.Slice[1] then
		score += (brief.Slice[1] - (to - from)) / brief.Slice[1] * 2
	end
	local range = brief.Events or { 1, 1 }
	if count < range[1] then
		score += (range[1] - count) * 0.6
	elseif count > range[2] then
		score += (count - range[2]) * 0.6
	end
	score += bandsOff(loudest, brief.Bands) * 1.5
	return { From = from, To = to, Peak = loudest.Peak - from, Score = score, Event = loudest }
end

-- The steadiest loud stretch for a loop: the window whose envelope varies least.
local function loopSlice(shape: any, brief: any, titled: boolean): Slice?
	local loudest = shape.Events[1]
	for _, event in shape.Events do
		if event.Level > loudest.Level then
			loudest = event
		end
	end
	if not loudest then
		return nil
	end
	if titled and shape.Length <= brief.Slice[2] * 2 then
		return { From = 0, To = shape.Length, Peak = loudest.Peak, Score = bandsOff(loudest, brief.Bands) * 1.5, Event = loudest }
	end
	local env = shape.Envelope
	local steps = math.floor(math.min(brief.Slice[2], shape.Length) / 0.01)
	if steps < math.floor(brief.Slice[1] / 0.01) then
		return nil
	end
	local top = 10 ^ (shape.Loudest / 20)
	local best: Slice? = nil
	for start = 1, #env - steps + 1, 10 do
		local sum, sumSq = 0, 0
		for i = start, start + steps - 1 do
			local level = 20 * math.log10(math.max(env[i], 1e-6) / top)
			sum += level
			sumSq += level * level
		end
		local mean = sum / steps
		local spread = math.sqrt(math.max(0, sumSq / steps - mean * mean))
		local score = spread / 6 + math.max(0, -12 - mean) / 6 + bandsOff(loudest, brief.Bands) * 1.5
		if not best or score < best.Score then
			best = { From = (start - 1) * 0.01, To = (start - 1 + steps) * 0.01, Peak = 0, Score = score, Event = loudest }
		end
	end
	return best
end

local function bestSlice(shape: any, brief: any, titled: boolean): Slice?
	if brief.Mode == "Loop" then
		return loopSlice(shape, brief, titled)
	end
	local best: Slice? = nil
	for index, event in shape.Events do
		if event.Level >= LOUD_EVENT_DB then
			local slice = if brief.Mode == "Sequence" then sequenceSlice(shape, index, brief) else hitSlice(shape, event, brief)
			if not best or slice.Score < best.Score then
				best = slice
			end
		end
	end
	return best
end

-- Library finds in the order to measure: each keyword's results in turn, so every search contributes.
local function interleaved(found: { any }): { any }
	local byKeyword: { [string]: { any } } = {}
	local order: { string } = {}
	for _, item in found do
		if not byKeyword[item.Keyword] then
			byKeyword[item.Keyword] = {}
			table.insert(order, item.Keyword)
		end
		table.insert(byKeyword[item.Keyword], item)
	end
	local out = {}
	local round = 1
	while true do
		local added = false
		for _, keyword in order do
			local item = byKeyword[keyword][round]
			if item then
				table.insert(out, item)
				added = true
			end
		end
		if not added then
			return out
		end
		round += 1
	end
end

-- Ranks the library for one cue. Options: Count (picks returned, default 8), Measure (finds measured, default 45),
-- Pages (search pages per keyword, default 2), AnyAuthor (default true).
function Shortlist.Run(cueName: string, options: { Count: number?, Measure: number?, Pages: number?, AnyAuthor: boolean? }?): { Pick }
	local brief = Briefs[cueName]
	assert(brief, `Shortlist: no brief for {cueName}`)
	local opts = options or {}
	local found = Library.Search(brief.Keywords, {
		MaxDuration = brief.MaxFile or 8,
		Pages = opts.Pages or 2,
		AnyAuthor = if opts.AnyAuthor == nil then true else opts.AnyAuthor,
	})
	local passed = {}
	for _, item in found do
		local text = normalized(item.Title)
		if allowed(text, brief.Avoid) then
			item.Text = text
			table.insert(passed, item)
		end
	end
	local ranked: { Pick } = {}
	for index, item in interleaved(passed) do
		if index > (opts.Measure or 45) then
			break
		end
		local shape = Waveform.Measure(item.Id)
		local titledLoop = string.find(item.Text, " loop ", 1, true) ~= nil
		local slice = shape and bestSlice(shape, brief, titledLoop)
		if shape and slice then
			local score = slice.Score
			if item.Licensed then
				score -= LICENSED_BONUS
			end
			score -= math.min(PREFER_MOST, mentions(item.Text, brief.Prefer or {}) * PREFER_BONUS)
			if shape.Loudest < QUIET_DBFS then
				score += QUIET_PENALTY
			end
			table.insert(ranked, {
				Cue = cueName,
				Id = item.Id,
				Title = item.Title,
				Creator = item.Creator,
				Licensed = item.Licensed,
				Keyword = item.Keyword,
				From = math.round(slice.From * 100) / 100,
				To = math.round(slice.To * 100) / 100,
				Peak = math.round(slice.Peak * 100) / 100,
				Level = nil,
				Score = math.round(score * 100) / 100,
				Shape = Waveform.DescribeEvent(slice.Event),
				Text = item.Text,
			} :: any)
		end
	end
	table.sort(ranked, function(a, b)
		return a.Score < b.Score
	end)
	-- variety: at most two of a series and three of an unlicensed creator
	local picks: { Pick } = {}
	local perSeries: { [string]: number } = {}
	local perCreator: { [string]: number } = {}
	for _, pick in ranked do
		if #picks >= (opts.Count or 8) then
			break
		end
		local key = series((pick :: any).Text)
		local seriesCount = perSeries[key] or 0
		local creatorCount = perCreator[pick.Creator] or 0
		if seriesCount < 2 and (pick.Licensed or creatorCount < 3) then
			perSeries[key] = seriesCount + 1
			perCreator[pick.Creator] = creatorCount + 1
			local level = Waveform.Level(pick.Id, pick.From, pick.To)
			pick.Level = if level then math.round(level * 10) / 10 else nil
			;(pick :: any).Text = nil
			table.insert(picks, pick)
		end
	end
	return picks
end

-- A given sound (one the owner found or uploaded) sliced for one cue by the cue's brief, as the line to paste into
-- Definitions/Sounds: `Id = ..., From = ..., To = ..., Peak = ..., Level = ...` (the cue keeps its Volume, Pitch, Range).
function Shortlist.CueLine(id: number, cueName: string): string
	local brief = Briefs[cueName]
	assert(brief, `Shortlist: no brief for {cueName}`)
	local shape = Waveform.Measure(id)
	assert(shape, `Shortlist: sound {id} didn't load`)
	local slice = bestSlice(shape, brief, false)
	assert(slice, `Shortlist: no slice of {id} fits {cueName}`)
	local from, to = math.round(slice.From * 100) / 100, math.round(slice.To * 100) / 100
	local level = Waveform.Level(id, from, to)
	return string.format('Id = "rbxassetid://%d", From = %s, To = %s, Peak = %s, Level = %.1f', id, tostring(from),
		tostring(to), tostring(math.min(math.round(slice.Peak * 100) / 100, to - from)), level or 0)
end

-- One line per pick: id, slice, peak, loudness, score, creator, title (the keyword that found it), then its shape.
function Shortlist.Format(picks: { Pick }): string
	local lines = {}
	for index, pick in picks do
		table.insert(lines, string.format("%d. %d | %.2f-%.2f pk %.2f | %s dB | s %.2f | %s%s | %s (%s)", index, pick.Id,
			pick.From, pick.To, pick.Peak, if pick.Level then string.format("%.1f", pick.Level) else "?", pick.Score,
			pick.Creator, if pick.Licensed then "" else "*", pick.Title, pick.Keyword))
		table.insert(lines, `     {pick.Shape}`)
	end
	return table.concat(lines, "\n")
end

return Shortlist

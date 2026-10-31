--!strict
-- Library: searches Roblox's audio library for sound effects (AGENTS.md rule 2, "Sounds"). It marks the licensed
-- uploads, preferred: Roblox itself and the professional libraries Roblox licensed for every experience, monetized ones
-- included (ProSoundEffects, APMOfficial). Any other author is allowed with AnyAuthor (log such a pick in
-- docs/asset-log.md: a claim can take it down). Studio, Edit mode, MCP execute_luau:
--   local Library = require(game.ServerStorage.BL_Tools.Audio.Library:Clone())
--   local found = Library.Search({ "sword hit", "metal clang", "anvil" }, { MaxDuration = 4, Pages = 3 })
--   print(Library.Format(found))
-- The owner auditions the shortlists in a playtest (Controllers/Core/AuditionController); the picks become cues in
-- Definitions/Sounds (Id, From, To).

local AssetService = game:GetService("AssetService")

local Library = {}

-- Creator id -> name: the licensed uploaders.
Library.Licensed = {
	[1] = "Roblox",
	[7462895450] = "ProSoundEffects",
	[7462718749] = "APMOfficial",
}

export type Found = { Id: number, Title: string, Creator: string, Licensed: boolean, Duration: number, Keyword: string }

-- Every sound effect matching any of `keywords` (deduplicated, in the order found): licensed uploads only, unless
-- AnyAuthor. Options: MaxDuration and MinDuration (seconds), Pages per keyword (25 results each, default 2).
function Library.Search(keywords: { string }, options: { MaxDuration: number?, MinDuration: number?, Pages: number?, AnyAuthor: boolean? }?): { Found }
	local opts = options or {}
	local seen: { [number]: boolean } = {}
	local found: { Found } = {}
	for _, keyword in keywords do
		local params = Instance.new("AudioSearchParams")
		params.SearchKeyword = keyword
		params.AudioSubType = Enum.AudioSubType.SoundEffect
		if opts.MaxDuration then
			params.MaxDuration = opts.MaxDuration
		end
		if opts.MinDuration then
			params.MinDuration = opts.MinDuration
		end
		local ok, pages = pcall(AssetService.SearchAudio, AssetService, params)
		if not ok then
			warn(`[BL] Library: "{keyword}" failed: {pages}`)
			continue
		end
		for page = 1, opts.Pages or 2 do
			for _, item in pages:GetCurrentPage() do
				local licensed = item.Creator and Library.Licensed[item.Creator.Id]
				if (licensed or opts.AnyAuthor) and not seen[item.Id] then
					seen[item.Id] = true
					local creator = licensed or (item.Creator and item.Creator.Name) or "?"
					table.insert(found, { Id = item.Id, Title = item.Title, Creator = creator, Licensed = licensed ~= nil,
						Duration = item.Duration, Keyword = keyword })
				end
			end
			if pages.IsFinished or page == (opts.Pages or 2) then
				break
			end
			local advanced = pcall(pages.AdvanceToNextPageAsync, pages)
			if not advanced then
				break
			end
			task.wait(0.2)
		end
		task.wait(0.2)
	end
	return found
end

-- One line per sound: id, length, creator, title (the keyword that found it).
function Library.Format(found: { Found }): string
	local lines = {}
	for _, f in found do
		table.insert(lines, `{f.Id} | {f.Duration}s | {f.Creator}{if f.Licensed then "" else " (unlicensed)"} | {f.Title} ({f.Keyword})`)
	end
	return table.concat(lines, "\n")
end

return Library

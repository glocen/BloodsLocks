--!strict
-- Victorian: the first match map. A map lists its zones; each zone has its own enemy roster (owner: every map has
-- its own enemies and its own zones). Zones are the match's regions too: you pick one to start each phase in.
-- World contract (Shared.World.Tags): zone volumes are parts tagged BL_Region with a Region attribute (a zone id
-- below); enemy spawns are parts tagged BL_EnemySpawn with either an Enemy attribute (an exact enemy) or a Zone
-- attribute (a weighted pick from that zone's roster), plus optional Count and Radius.
--   Shape: Id, DisplayName, PlaceId, Zones = { [zoneId] = { DisplayName, District, Blurb, Enemies = { { Id, Weight } } } }.
--   Blurb: one line the region map shows about the zone (what it is to a hunter; the art team may rewrite it).
-- The first district is ChatGPT's Cathedral Quarter (worlds/Victorian/CathedralQuarter); for the proof of concept it
-- is split into four regions (owner decision D8, 2026-10-29). Authored enemy groups name their Enemy exactly; the
-- rosters below are the fallback for Zone spawns.

local QUARTER_ROSTER = { { Id = "Wretch", Weight = 8 }, { Id = "Butcher", Weight = 1 } }

return {
	Id = "Victorian",
	DisplayName = "The Victorian Quarter",
	PlaceId = 112559855790294,
	Zones = {
		LamplightersReach = {
			DisplayName = "Lamplighters' Reach",
			District = "Cathedral Quarter",
			Blurb = "The broad southern approach, lamp-lined streets climbing to the cathedral steps.",
			Enemies = QUARTER_ROSTER,
		},
		Cloister = {
			DisplayName = "The Cloister",
			District = "Cathedral Quarter",
			Blurb = "Quiet arcades and a walled garden on the west side, with a stair to the gallery.",
			Enemies = QUARTER_ROSTER,
		},
		BellWorks = {
			DisplayName = "Bell Works",
			District = "Cathedral Quarter",
			Blurb = "Foundry yards and workshops on the east side, under the cathedral's bell tower.",
			Enemies = QUARTER_ROSTER,
		},
		ChapterClose = {
			DisplayName = "Chapter Close",
			District = "Cathedral Quarter",
			Blurb = "The cathedral's own close to the north: chapter house, crypt doors, high roofs.",
			Enemies = QUARTER_ROSTER,
		},
	},
}

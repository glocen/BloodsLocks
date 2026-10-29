--!strict
-- Victorian: the first match map. A map lists its zones; each zone has its own enemy roster (owner: every map has
-- its own enemies and its own zones). Zones are the match's regions too: you pick one to start each phase in.
-- World contract: zone volumes are parts tagged BL_Region with a Region attribute (a zone id below); enemy spawns
-- are parts tagged BL_EnemySpawn with either an Enemy attribute (an exact enemy) or a Zone attribute (a weighted
-- pick from that zone's roster), plus optional Count and Radius.
--   Shape: Id, DisplayName, PlaceId, Zones = { [zoneId] = { DisplayName, Enemies = { { Id, Weight } } } }.
-- TODO (owner, 2026-10-29): the map isn't sketched yet. Zones and their rosters get filled in once the owner and
-- ChatGPT sketch it (docs/team-notes.md to-do). Until then spawns name their Enemy directly.

return {
	Id = "Victorian",
	DisplayName = "The Victorian Quarter",
	PlaceId = 112559855790294,
	Zones = {},
}

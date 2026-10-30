--!strict
-- World contract: every CollectionService tag a place's world carries for gameplay, and the attributes each one needs.
-- World builders (ChatGPT, Claude) only stamp these; code reads tag names from here, never as literals.
-- WorldService checks the place against this list at boot and prints a report.
--   Tag: the CollectionService tag.
--   Attributes: name -> "string" | "number" | "boolean", "?" suffix when optional.
--   Marker: an invisible, anchored, non-colliding part (it must stand over ground when Grounded).
--   Volume: a part whose box is the area (combat zone, region, arena).
--   Roles: the place roles that use it (Shared.Util.PlaceRole); RequiredIn: roles where at least one must exist,
--   with Since naming the production-plan slice that starts needing it.

export type Spec = {
	Tag: string,
	Attributes: { [string]: string },
	Marker: boolean?,
	Grounded: boolean?,
	Volume: boolean?,
	Roles: { string },
	RequiredIn: { string }?,
	Since: string?,
}

local Tags: { [string]: Spec } = {
	CombatZone = { Tag = "BL_CombatZone", Attributes = {}, Volume = true, Roles = { "Manor" }, RequiredIn = { "Manor" } },
	PactCircle = { Tag = "BL_PactCircle", Attributes = { Shinigami = "string" }, Roles = { "Manor", "Match" } },
	EnemySpawn = {
		Tag = "BL_EnemySpawn",
		Attributes = { Enemy = "string?", Zone = "string?", Count = "number?", Radius = "number?", Respawn = "number?" },
		Marker = true,
		Grounded = true,
		Roles = { "Manor", "Match" },
	},
	Region = { Tag = "BL_Region", Attributes = { Region = "string" }, Volume = true, Roles = { "Match" }, RequiredIn = { "Match" }, Since = "W1" },
	Spawn = { Tag = "BL_Spawn", Attributes = { Region = "string" }, Marker = true, Grounded = true, Roles = { "Match" }, RequiredIn = { "Match" }, Since = "W1" },
	-- Dressed: the room's art is finished, so players may step out of the Antechamber screen into it
	Antechamber = { Tag = "BL_Antechamber", Attributes = { Dressed = "boolean?" }, Volume = true, Roles = { "Match" }, RequiredIn = { "Match" }, Since = "W1" },
	FinalArena = { Tag = "BL_FinalArena", Attributes = {}, Volume = true, Roles = { "Match" }, RequiredIn = { "Match" }, Since = "W1" },
	FinalSpawn = { Tag = "BL_FinalSpawn", Attributes = {}, Marker = true, Grounded = true, Roles = { "Match" }, RequiredIn = { "Match" }, Since = "W1" },
	RitualSite = { Tag = "BL_RitualSite", Attributes = { Site = "string" }, Volume = true, Roles = { "Match" }, Since = "R1" },
	BossArena = { Tag = "BL_BossArena", Attributes = { Encounter = "string" }, Volume = true, Roles = { "Match" }, Since = "B2" },
	Interactable = { Tag = "BL_Interactable", Attributes = { Kind = "string", Id = "string?" }, Roles = { "Match" }, Since = "E2" },
	-- where a hunter stands for a full-screen menu (Blood Table, Antechamber), facing the way the camera will be
	Stage = { Tag = "BL_Stage", Attributes = {}, Marker = true, Grounded = true, Roles = { "Manor", "Match" } },
}

return table.freeze(Tags)

--!strict
-- Game-wide settings.

return {
	Version = "0.1.0",
	-- Each place sets the Workspace attribute "PlaceRole" to one of these to choose which role-specific services
	-- and controllers boot (Services/<role>, Controllers/<role>). Read it through Util.PlaceRole.
	PlaceRoles = {
		Manor = "Manor", -- the hub
		Match = "Match",
	},
	DefaultPlaceRole = "Manor", -- the fallback when a place doesn't set the attribute

	-- Places in this experience (GameId 10772800943).
	Places = {
		Manor = 76593217243342, -- ROLOCK: the hub
	},
	-- Match maps (their places, zones and enemies) are definitions: Definitions/Maps. Match rules: Definitions/Rules;
	-- the waiting room and the Studio fast profile: Config.Match.
}

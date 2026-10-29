--!strict
-- Game-wide settings.

return {
	Version = "0.1.0",
	-- Each place sets the Workspace attribute "PlaceRole" ("Castle" or "Match") to choose which
	-- role-specific services and controllers boot. This is the fallback when it's missing.
	DefaultPlaceRole = "Castle",

	-- Places in this experience (GameId 10772800943).
	Places = {
		Castle = 76593217243342, -- ROLOCK: the hub (The Vigil)
	},
	-- Match maps by id; the Dusk Battle tab lists these.
	MatchMaps = {
		Victorian = { PlaceId = 112559855790294, DisplayName = "The Victorian Quarter" },
	},

	Match = {
		MaxPlayers = 8,
		MinPlayers = 2, -- the countdown starts once this many are in the waiting room
		Countdown = 30, -- seconds; the server delists itself when it locks (T-5)
		LockAt = 5,
	},
}

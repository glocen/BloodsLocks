return {
	EXP = 0,
	Level = 0,
	Inventory = {},
	Spin = 10,
	Health = 2000,
	Energy = 50,
	
	--BloodsLocks (profile:Reconcile() in DataInit adds these to old saves automatically)
	DataVersion = 0, --DataService migrations raise this; keep it 0 here so every profile runs them once
	Bloodgems = 0, --match reward currency, spent on class skins
	SelectedClass = "Gustave", --class picked at the castle altar
	SelectedAspects = {}, --[classId] = aspectId
	OwnedSkins = {}, --[classId] = {skinId, ...} (default skins are always owned)
	EquippedSkins = {}, --[classId] = skinId
	Stats = {Matches = 0, Wins = 0, Finals = 0, PlayerKills = 0, Deaths = 0, VirtueEarned = 0},
	ClassStats = {}, --[classId] = {Matches = 0, Wins = 0}
	Settings = {MouseSensitivity = 1, Keybinds = {}},
	MatchAwards = {}, --{ {Id = matchId, Amount = bloodgems}, ... } newest last; a match pays a player once (PlayerHandlerData.SettleMatch)
}
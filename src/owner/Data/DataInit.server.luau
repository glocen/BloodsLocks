local PLRS = game:GetService("Players")
local rs = game:GetService("RunService")
local sss = game:GetService("ServerScriptService")
local rss = game:GetService("ReplicatedStorage")

local RE = rss.Events:FindFirstChild("NotificationClientDataRE")
local gameRE = rss.Events:FindFirstChild("GameRE")
local profilestore = require(sss.Libraries.ProfileStore)
local DSS = game:GetService("DataStoreService")
local LBDataStore = DSS:GetOrderedDataStore("LeaderboardDataStore")

local function GetStoreName()
	return rs:IsStudio() and "Test" or "Live"
end

local template = require(sss.Data.ProfileTemplate)
local PlayerHandlerData = require(sss.Data.PlayerHandlerData)
local ProductManager = require(sss.Data.ProductManager)

local plrDS = profilestore.New(GetStoreName(), template)

local function Initialize(plr: Player, profile: typeof(plrDS:StartSessionAsync())) --trigger event when the player join and data loaded, send data to the client
	--to display locally (synchronize), add leaderstats..

	local StatsFLD = Instance.new("Folder", plr)
	StatsFLD.Name = "StatsFLD"

	local health = Instance.new("IntValue", StatsFLD)
	health.Name = "Health"
	health.Value = profile.Data.Health
	
	
	local Energy = Instance.new("IntValue", StatsFLD)
	Energy.Name = "Energy"
	Energy.Value = profile.Data.Energy
	
	local currentenergy = Instance.new("IntValue",StatsFLD)
	currentenergy.Name = "CurrentEnergy"
	currentenergy.Value = Energy.Value

	local PlayerInventoryFLD = Instance.new("Folder", plr)
	PlayerInventoryFLD.Name = "PlayerInventory"

	PlayerHandlerData.LoadWeapon(plr)

	--(2026-10-29: the Humanoid's health is no longer set from profile.Data.Health. Combat HP comes from the class
	--and lives in the character's "hp" attribute; the Humanoid only dies when that reaches 0. See EntityService.)
	--synch player data to client
	RE:FireClient(plr, "HealthEVENT", profile.Data.Health)
	RE:FireClient(plr, "EnergyEVENT", profile.Data.Energy)
end

local function OnPlayerAdded(plr: Player) --create & store profile for each player
	local profile = plrDS:StartSessionAsync("Player_" .. plr.UserId, {
		Cancel = function()
			return plr.Parent ~= PLRS
		end,
	})
	--sanity check
	if profile ~= nil then
		profile:AddUserId(plr.UserId) -- GDPR Compliance (Very Important regarding roblox data deletion policies)
		profile:Reconcile() --fill in missing data variables from template (meaning if a player joined before a new data was put in the template
		--reconcile will check & see it missing and fill in the missing variable via the template)

		--session-locking handler
		profile.OnSessionEnd:Connect(function()
			PlayerHandlerData.Profiles[plr] = nil --dont save the profile else memory leak
			plr:Kick("Data error occured")
		end)

		if plr.Parent == PLRS then
			PlayerHandlerData.Profiles[plr] = profile
			Initialize(plr, profile) --initialize the data once the player is in the game
		else
			profile:EndSession()
		end
	else
		plr:Kick("Data error occured, please rejoin.")
	end
end

--Early Joiners check

for _, plr in pairs(PLRS:GetPlayers()) do
	task.spawn(OnPlayerAdded, plr)
end

PLRS.PlayerAdded:Connect(OnPlayerAdded)

local function OnPlayerLeaving(plr: Player)
	local profile = PlayerHandlerData.Profiles[plr] --example of getting the profile in other script (since it out of scope)

	--still do a sanity check
	if not profile then
		return
	end

	profile:EndSession()
	PlayerHandlerData.Profiles[plr] = nil --again prevent memory leaks else server performance goes horrible
end

PLRS.PlayerRemoving:Connect(OnPlayerLeaving)

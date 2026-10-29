local PlayerHandlerData = {}

local PLRS = game:GetService("Players")

local rss = game:GetService("ReplicatedStorage")
local ss = game:GetService("ServerStorage")
local gameRE = rss.Events.GameRE

--DataManager that stores profiles from profilestore
PlayerHandlerData.Profiles = {}

--edit/manage

--currency
function PlayerHandlerData.AddHealth(plr: Player, amount: number)
	local profile = PlayerHandlerData.Profiles[plr]
	if not profile then
		return
	end
	
local cha = plr.Character or plr.CharacterAdded:Wait()
local hum:Humanoid = cha:FindFirstChild("Humanoid")

	profile.Data.Health += amount
	plr.StatsFLD.Health.Value = profile.Data.Health
	hum.MaxHealth = plr.StatsFLD.Health.Value
	rss.Events.NotificationClientDataRE:FireClient(plr, "AddedHealthEVENT", profile.Data.Health) --this method is known as "boiler plate code"
end
function PlayerHandlerData.AddEnergy(plr: Player, amount: number)
	local profile = PlayerHandlerData.Profiles[plr]
	if not profile then
		return
	end
	
	local cha = plr.Character or plr.CharacterAdded:Wait()
	local hum:Humanoid = cha:FindFirstChild("Humanoid")

	profile.Data.Energy += amount
	plr.StatsFLD.Energy.Value = profile.Data.Energy
	rss.Events.NotificationClientDataRE:FireClient(plr, "AddedEnergyEVENT", profile.Data.Energy)
end
function PlayerHandlerData.RemoveHealth(plr: Player, amount: number)
	local profile = PlayerHandlerData.Profiles[plr]
	if not profile then
		return
	end
	
	local cha = plr.Character or plr.CharacterAdded:Wait()
	local hum:Humanoid = cha:FindFirstChild("Humanoid")

	profile.Data.Health -= amount
	plr.Character:FindFirstChild("Humanoid").MaxHealth = profile.Data.Health
	rss.Events.NotificationClientDataRE:FireClient(plr, "RemovedHealthEVENT", profile.Data.Health)
end
function PlayerHandlerData.RemoveEnergy(plr: Player, amount: number)
	local profile = PlayerHandlerData.Profiles[plr]
	if not profile then
		return
	end
	
	local cha = plr.Character or plr.CharacterAdded:Wait()
	local hum:Humanoid = cha:FindFirstChild("Humanoid")

	profile.Data.Energy -= amount
	plr.StatsFLD.Energy.Value = profile.Data.Energy
	rss.Events.NotificationClientDataRE:FireClient(plr, "RemovedEnergyEVENT", profile.Data.Health)
end

--Weapon 
function PlayerHandlerData.AddWeapon(plr: Player, WeaponName: string)
	local profile = PlayerHandlerData.Profiles[plr]
	if not profile then
		return
	end

	local alreadyInBackpack = plr.Backpack:FindFirstChild(WeaponName)
	local alreadyInInventory = plr.PlayerInventory:FindFirstChild(WeaponName)

	if alreadyInBackpack or alreadyInInventory then
		return -- weapon already exists
	end

	local weapon = ss.WeaponsFLD:FindFirstChild(WeaponName)
	if not weapon then
		print("error")
		return
	end

	local clone = weapon:Clone()
	clone.Parent = plr.PlayerInventory

	if not table.find(profile.Data.Inventory, WeaponName) then
		table.insert(profile.Data.Inventory, WeaponName)
		print(WeaponName .. " has successfully been saved for: " .. plr.Name)
	end
end

function PlayerHandlerData.EquipWeapon(plr: Player, weaponName) --equip
	local profile = PlayerHandlerData.Profiles[plr]
	if not profile then
		return
	end

	-- Remove tools from Backpack
	for _, tool in ipairs(plr.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			tool:Destroy()
			gameRE:FireClient(plr, "UnEquipWeapon")
		end
	end
	task.wait(2)
	local weapon = plr.PlayerInventory[weaponName]
	if not weapon then
		return
	end

	local clone = weapon:Clone()
	clone.Parent = plr.Backpack
end

function PlayerHandlerData.LoadWeapon(plr: Player) --load all the weapon of the plr from it data inventory
	local profile = PlayerHandlerData.Profiles[plr]
	if not profile then
		return
	end

	for i, WeaponName in pairs(profile.Data.Inventory) do
		PlayerHandlerData.AddWeapon(plr, WeaponName)
		-- PlayerHandlerData.EquipWeapon(plr,WeaponName)
	end
end

--Character Added update
--[[
PLRS.PlayerAdded:Connect(function(plr)
	local function OnCharacterAdded(cha: Model)
		local profile = PlayerHandlerData.Profiles[plr]
		if profile then
			local currentWin = profile.Data.Win
			rss.Events.NotificationClientDataRE:FireClient(plr, "CurrentWin", currentWin)

			local currentBanana = profile.Data.Banana
			rss.Events.NotificationClientDataRE:FireClient(plr, "CurrentBanana", currentBanana)
		end
	end

	plr.CharacterAdded:Connect(OnCharacterAdded)

	--If character is already loaded
	if plr.Character then
		OnCharacterAdded(plr.Character)
	end
end)

-- update for  existing players who joined before the script loaded
for _, plr in pairs(PLRS:GetPlayers()) do
	task.spawn(function()
		local function OnCharacterAdded(cha: Model)
			local profile = PlayerHandlerData.Profiles[plr]
			if profile then
				local currentWin = profile.Data.Win
				rss.Events.NotificationClientDataRE:FireClient(plr, "CurrentWin", currentWin)

				local currentBanana = profile.Data.Banana
				rss.Events.NotificationClientDataRE:FireClient(plr, "CurrentBanana", currentBanana)
			end
		end

		plr.CharacterAdded:Connect(OnCharacterAdded)
		
		--If character is already loaded
		if plr.Character then
			OnCharacterAdded(plr.Character)
		end
	end)
end
]]

--BloodsLocks additions--

--waits until DataInit has loaded the profile (returns nil if the player leaves first)
function PlayerHandlerData.WaitForProfile(plr: Player)
	local profile = PlayerHandlerData.Profiles[plr]
	while profile == nil and plr.Parent == PLRS do
		task.wait()
		profile = PlayerHandlerData.Profiles[plr]
	end
	return profile
end

local function IsValidAmount(amount: number) --currency amounts must be whole numbers above 0
	return typeof(amount) == "number" and amount > 0 and amount % 1 == 0
end

--bloodgems (match reward currency)
function PlayerHandlerData.AddBloodgems(plr: Player, amount: number)
	local profile = PlayerHandlerData.Profiles[plr]
	if not profile then
		return
	end
	if not IsValidAmount(amount) then
		warn("AddBloodgems: invalid amount", amount, "for", plr.Name)
		return
	end

	profile.Data.Bloodgems += amount
	rss.Events.NotificationClientDataRE:FireClient(plr, "BloodgemsEVENT", profile.Data.Bloodgems)
end

function PlayerHandlerData.RemoveBloodgems(plr: Player, amount: number): boolean --false if the player can't afford it
	local profile = PlayerHandlerData.Profiles[plr]
	if not profile then
		return false
	end
	if not IsValidAmount(amount) then
		warn("RemoveBloodgems: invalid amount", amount, "for", plr.Name)
		return false
	end
	if profile.Data.Bloodgems < amount then
		return false
	end

	profile.Data.Bloodgems -= amount
	rss.Events.NotificationClientDataRE:FireClient(plr, "BloodgemsEVENT", profile.Data.Bloodgems)
	return true
end

--class (callers check classId against the class list first)
function PlayerHandlerData.SetSelectedClass(plr: Player, classId: string)
	local profile = PlayerHandlerData.Profiles[plr]
	if not profile then
		return
	end

	profile.Data.SelectedClass = classId
	rss.Events.NotificationClientDataRE:FireClient(plr, "SelectedClassEVENT", classId)
end

return PlayerHandlerData

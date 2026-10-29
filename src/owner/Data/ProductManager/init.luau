local ProductManager = {}

local MPS = game:GetService("MarketplaceService")
local PLRS = game:GetService("Players")
local rss = game:GetService("ReplicatedStorage")
local sss = game:GetService("ServerScriptService")

local PlayerHandlerData = require(sss.Data.PlayerHandlerData)
local productsfunctions = require(script.Products)
local MAX_CACHE_SIZE = 100 

--prompt dev product
function ProductManager.ProductPurchaseRequested(plr:Player,productId)
	--sanity check (on productId)
	if productsfunctions[productId] == nil then
		warn("No Product function for: ", productId, "	| Player: ",plr.Name, plr.UserId)
		return --return so that the function doesnt complete and throw an error
	end
	
	MPS:PromptProductPurchase(plr,productId)
	
end

--waits until purchaseId has been stored in the profile store before confirming ProductPurchaseDecision
local function CheckPurchaseIdAsync(profile,purchaseID,GrantProductFunction) : Enum.ProductPurchaseDecision --remember this technic
	
	--Check if profile is active
	if profile:IsActive() == true then
		
		--get cache of previous purchaseIds
		local purchaseIdCache = profile.Data.PurchaseIdCache
		if purchaseIdCache == nil then
			purchaseIdCache = {}
			profile.Data.PurchaseIdCache = purchaseIdCache
		end
		--grant the product if it havent been previously logged
		if table.find(purchaseIdCache,purchaseID) == nil then
			
			--has not been logged, grant the product
			local success,result = pcall(GrantProductFunction) --no param or function needed
			
			--If pcall failed:
			if success == false then
				warn("Failed to grant product: ", profile.Key, purchaseID, result)
			return	Enum.ProductPurchaseDecision.NotProcessedYet
			end
			
		--if pcall succeded (log purchaseId to cache): --clean useless cache to save space
		
		
		--Remove outdated purchaseIds
		while #purchaseIdCache > MAX_CACHE_SIZE do
			table.remove(purchaseIdCache,1) --will start from the oldest in the table
		end
		table.insert(purchaseIdCache,purchaseID)
		end
		
		--At this point, product has been confirmed granted
		--Verify the product has been logged in the DataStore
		
		local function IsPurchaseSaved()
			local savedCache = profile.LastSavedData.PurchaseIdCache
			return if savedCache ~= nil then table.find(savedCache,purchaseIdCache) ~= nil else false
		end
		
			--initial purchaseId saved check (need to do this since it work Async it need to be saved to the DS first)
			if IsPurchaseSaved() == true then
				return Enum.ProductPurchaseDecision.PurchaseGranted --finally granted
			end
			
			--Periodically check if the purchaseid is saved until it is OR profile's session ends
			while profile:IsActive() == true do
				
				--Get a copy of the current LastSavedData
				local LastSavedDataCopy = profile.LastSavedData
				
				--Manually save the profile
				profile:Save() --rarely do this only in very specific case and test behind since profilestore is configured to
				-- automatically reduce as many as those API call as possible (since in this situation, it is a specific case and only 1 time, do it)
				
				--wait until the profile has been saved
				if profile.LastSavedData == LastSavedDataCopy then
					profile.OnAfterSave:Wait()
				end
				
				--Check if purchaseId has been saved
				if IsPurchaseSaved() == true then
					return Enum.ProductPurchaseDecision.PurchaseGranted 
				end
				
				--Wait a period of time and try again
				if profile:IsActive() == true then
					task.wait(10)
				end
				
			end
	end
	
	return Enum.ProductPurchaseDecision.NotProcessedYet --profile not active
	
end

--MPS Callback to verify product was granted (lot of defensive sanity check to make sure there is no issue)
local function ProcessReceipt(receiptinfo) --this callback can run as many as it need even when the plr leave/rejoin
	--until it successfull
	local plr:Player = PLRS:GetPlayerByUserId(receiptinfo.PlayerId)
	
	--make sure player is in game
	if plr ~= nil then
		local profile = PlayerHandlerData.Profiles[plr]
		
		--wait for profile to exist
		while profile == nil and plr.Parent == PLRS do
			task.wait()
			profile = PlayerHandlerData.Profiles[plr]
		end
		
		--make sure profile exists
		if profile ~= nil then
			--sanity check (on productId)
			if productsfunctions[receiptinfo.ProductId] == nil then
				warn("No Product function for: ", productId, "	| Player: ",plr.Name, plr.UserId)
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
		--grant product & result
		local productpurchasedecision = CheckPurchaseIdAsync(
			profile,
			receiptinfo.PurchaseId,
			function()
				productsfunctions[receiptinfo.ProductId](receiptinfo,plr,profile) --calling product function
			end
		)
		return productpurchasedecision
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet --plr not in-game
end
	
--Connect process receipt callback
MPS.ProcessReceipt = ProcessReceipt --don't put ()

rss.Events.RequestProductBoughtRE.OnServerEvent:Connect(function(plr:Player,arg1)
	if arg1 == "Bought100BananaEvent" then
		ProductManager.ProductPurchaseRequested(plr,3282679012)
		
	elseif arg1 == "Bought250BananaEvent" then
		ProductManager.ProductPurchaseRequested(plr,3282679550)
	
	elseif arg1 == "Bought500BananaEvent" then
		ProductManager.ProductPurchaseRequested(plr,3282679551)
	end
end)

return ProductManager

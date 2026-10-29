local PlayerHandlerData = require(game.ServerScriptService.Data:FindFirstChild("PlayerHandlerData"))

return {
	--dev product id = function() (which awards the product)
	
	--Buy 100 banana dev product:
	[3282679012] = function(receiptinfo,plr,profile) --receipt info is extremely powerfull to collect data/Analyze and see if there is errors (use it later)
		PlayerHandlerData.AddBanana(plr,100)
	end,
	
	--Buy 250 banana dev product:
	[3282679550] = function(receiptinfo,plr,profile)
		PlayerHandlerData.AddBanana(plr,250)
	end,
	
	--Buy 500 banana dev product:
	[3282679551] = function(receiptinfo,plr,profile)
		PlayerHandlerData.AddBanana(plr,500)
	end,
	
	--Buy 1 revive dev product:
	[3282679552] = function(receiptinfo,plr,profile)

	end,
	
}
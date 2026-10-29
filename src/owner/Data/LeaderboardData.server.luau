local DSS = game:GetService("DataStoreService")
local LBDataStore = DSS:GetOrderedDataStore("LeaderboardDataStore")
local PLRS = game:GetService("Players")
local rss = game:GetService("ReplicatedStorage")
local sss = game:GetService("ServerScriptService")
local gameRE = rss.Events.GameRE
local NotifRE = rss.Events:FindFirstChild("NotificationClientDataRE")
local PlayerHandlerData = require(sss.Data.PlayerHandlerData)

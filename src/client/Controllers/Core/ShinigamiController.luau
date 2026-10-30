--!strict
-- ShinigamiController: your Shinigami on this client. The summon / dismiss key (the "Summon" input action, T) asks the
-- server to toggle it; pacts are made at circles in the world (a ProximityPrompt on the server, the circle dressed by
-- PactSiteController). It speaks the way Duskbloods' Kin do, in a white subtitle (UI/Hud/Subtitle): a Pact line when
-- you bind it, a Summon line when it answers your call, as it rises out of the same dark-red mist as an arriving
-- hunter (Vfx/Arrival). Its lines are data (the definition's Lines).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Registry = require(Shared.Definitions.Registry)
local PlayerState = require(Shared.Simulation.PlayerState)
local EntityState = require(Shared.Simulation.EntityState)
local Client = script.Parent.Parent.Parent
local Layers = require(Client.UI.Core.Layers)
local Subtitle = require(Client.UI.Hud.Subtitle)
local Arrival = require(Client.Vfx.Arrival)

local P = PlayerState.Attr
local A = EntityState.Attr
local FOLDER = "Shinigami" -- where the server keeps summoned bodies (ShinigamiService)
local BODY_WAIT = 1 -- seconds the summoned body may take to arrive after the word that it's out

local ShinigamiController = {}

local player = Players.LocalPlayer
local random = Random.new()
local subtitle: Subtitle.Subtitle

-- One of the Shinigami's lines for `moment` ("Pact", "Summon"), if it has any.
local function say(def: any, moment: string)
	local lines = def and def.Lines and def.Lines[moment]
	if lines and #lines > 0 then
		subtitle:Say(lines[random:NextInteger(1, #lines)])
	end
end

-- Your summoned body in the world, once it has arrived.
local function body(): Model?
	local deadline = os.clock() + BODY_WAIT
	repeat
		local folder = workspace:FindFirstChild(FOLDER)
		for _, model in if folder then folder:GetChildren() else {} do
			if model:IsA("Model") and model:GetAttribute(A.OwnerId) == player.UserId then
				return model
			end
		end
		task.wait()
	until os.clock() > deadline
	return nil
end

function ShinigamiController.Start()
	subtitle = Subtitle.new(Layers.Get("Overlay"))
	player:GetAttributeChangedSignal(P.ShinigamiId):Connect(function()
		say(Registry.Shinigami(player:GetAttribute(P.ShinigamiId)), "Pact")
	end)
	player:GetAttributeChangedSignal(P.ShinigamiOut):Connect(function()
		if player:GetAttribute(P.ShinigamiOut) ~= true then
			return
		end
		say(Registry.Shinigami(player:GetAttribute(P.ShinigamiId)), "Summon")
		local model = body()
		if model then
			Arrival.Play(model)
		end
	end)
	local context = player:WaitForChild("BLGameplay")
	local summon = context:WaitForChild("Summon") :: InputAction
	summon.Pressed:Connect(function()
		Net.Client.Fire("ShinigamiToggle")
	end)
end

return ShinigamiController

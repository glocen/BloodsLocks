--!strict
-- PromptController: draws world interactions in our style (UI/Hud/PromptCard) for every ProximityPrompt whose Style is
-- Custom (the Blood Table, pact circles; set Custom on any prompt you add). Roblox decides which prompt is shown (the
-- nearest in range, one per key); we show its object, key and action, fill the ring through a hold, and flash it on
-- trigger. Only one card: the prompt shown last wins.

local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

local UI = script.Parent.Parent.Parent.UI
local Layers = require(UI.Core.Layers)
local PromptCard = require(UI.Hud.PromptCard)

local PromptController = {}

function PromptController.Start()
	local card = PromptCard.new(Layers.Get("HUD"))
	local current: ProximityPrompt? = nil
	local holdingSince: number? = nil

	ProximityPromptService.PromptShown:Connect(function(prompt: ProximityPrompt)
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom then
			return
		end
		current, holdingSince = prompt, nil
		card:Show(prompt.ObjectText, prompt.ActionText, prompt.KeyboardKeyCode.Name, prompt.HoldDuration > 0)
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt: ProximityPrompt)
		if prompt == current then
			current, holdingSince = nil, nil
			card:Hide()
		end
	end)
	ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt: ProximityPrompt)
		if prompt == current then
			holdingSince = os.clock()
		end
	end)
	ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt: ProximityPrompt)
		if prompt == current then
			holdingSince = nil
			card:SetHold(0)
		end
	end)
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
		if prompt == current then
			holdingSince = nil
			card:Confirm()
		end
	end)
	RunService.RenderStepped:Connect(function()
		if current and holdingSince and current.HoldDuration > 0 then
			card:SetHold((os.clock() - holdingSince) / current.HoldDuration)
		end
	end)
end

return PromptController

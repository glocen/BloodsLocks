--!strict
-- ReturnController (match places): hold Backspace to go back to the Manor (TravelService). A key hint sits
-- bottom-right; holding fills it, letting go early cancels, so nobody leaves a hunt by accident. Until the match
-- flow brings a real results screen, this is the way home.

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local UI = script.Parent.Parent.Parent.UI
local Layers = require(UI.Core.Layers)
local KeyHints = require(UI.Kit.KeyHints)

local KEY = Enum.KeyCode.Backspace
local HOLD = 1.2 -- seconds

local ReturnController = {}

function ReturnController.Start()
	local hints = KeyHints.new(Layers.Get("Overlay"))
	local idle = { { "Backspace", "Hold to return to the Manor" } }
	hints:Set(idle)
	local heldSince: number? = nil
	local sent = false
	local shownDots = -1

	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == KEY and not UserInputService:GetFocusedTextBox() and not sent then
			heldSince = os.clock()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == KEY and not sent and heldSince then
			heldSince, shownDots = nil, -1
			hints:Set(idle)
		end
	end)
	RunService.RenderStepped:Connect(function()
		if not heldSince or sent then
			return
		end
		local progress = (os.clock() - heldSince) / HOLD
		if progress >= 1 then
			sent = true
			hints:Set({ { "Backspace", "Returning to the Manor…" } })
			Net.Client.Fire("ReturnToManor")
		else
			local dots = math.floor(progress * 6)
			if dots ~= shownDots then
				shownDots = dots
				hints:Set({ { "Backspace", `Hold to return to the Manor {string.rep("·", dots)}` } })
			end
		end
	end)
	Net.Client.On("HuntStatus", function(message: string, done: boolean?)
		hints:Set({ { "Backspace", message } })
		if done then
			sent = false
			task.delay(3, function()
				hints:Set(idle)
			end)
		end
	end)
end

return ReturnController

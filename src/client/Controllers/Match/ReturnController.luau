--!strict
-- ReturnController (match places): hold Backspace to leave the hunt for the Manor (TravelService). Holding fills the
-- key hint, letting go early cancels, so nobody leaves by accident. The hint (bottom-right) shows only where leaving is
-- the expected thing to do: in the Antechamber, at the results, once you're out of the hunt (culled or left), and
-- while the key is held. Holding works everywhere; in a phase, leaving costs the rewards (D9), so it isn't advertised.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local MatchState = require(Shared.Match.MatchState)
local GameConfig = require(Shared.Config.Game)
local UI = script.Parent.Parent.Parent.UI
local Layers = require(UI.Core.Layers)
local KeyHints = require(UI.Kit.KeyHints)

local KEY = Enum.KeyCode.Backspace
local HOLD = 1.2 -- seconds
local NOTICE = 4 -- seconds a travel failure stays on the hint
local S = MatchState.States
local M = MatchState.Match
local PA = MatchState.Participant
-- states where leaving is the expected thing to do, and what the hint says there
local ADVERTISED: { [string]: string } = {
	[S.Idle] = "Hold to leave the hunt",
	[S.Waiting] = "Hold to leave the hunt",
	[S.Countdown] = "Hold to leave the hunt",
	[S.Results] = `Hold to return to {GameConfig.HubName}`,
	[S.Return] = `Hold to return to {GameConfig.HubName}`,
}

local ReturnController = {}

function ReturnController.Start()
	local player = Players.LocalPlayer
	local hints = KeyHints.new(Layers.Get("Overlay"))
	local heldSince: number? = nil
	local sent = false
	local shown = ""
	local notice: string? = nil -- a travel failure, shown for NOTICE seconds wherever you are
	local noticeUntil = 0
	local function set(text: string)
		if text ~= shown then
			shown = text
			hints:Set({ { KEY.Name, text } })
		end
	end

	-- what the hint should say right now, or nil to hide it
	local function idleText(): string?
		local root = ReplicatedStorage:FindFirstChild(MatchState.FolderName)
		local state = root and root:GetAttribute(M.State)
		local advertised = state and ADVERTISED[state]
		if advertised then
			return advertised
		end
		local participants = root and root:FindFirstChild(MatchState.ParticipantsName)
		local me = participants and participants:FindFirstChild(tostring(player.UserId))
		if me and me:GetAttribute(PA.Eligible) == false then
			return `Hold to return to {GameConfig.HubName}` -- culled: nothing left to play
		end
		return nil
	end

	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == KEY and not UserInputService:GetFocusedTextBox() and not sent then
			heldSince = os.clock()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == KEY and not sent then
			heldSince = nil
		end
	end)
	RunService.RenderStepped:Connect(function()
		if sent then
			hints.Frame.Visible = true
			return
		end
		if notice and os.clock() < noticeUntil then
			set(notice)
			hints.Frame.Visible = true
			return
		end
		if heldSince then
			local progress = (os.clock() - heldSince) / HOLD
			if progress >= 1 then
				sent = true
				set(`Returning to {GameConfig.HubName}…`)
				Net.Client.Fire("ReturnToManor")
			else
				set(`{idleText() or "Hold to leave the hunt"} {string.rep("·", math.floor(progress * 6))}`)
			end
			hints.Frame.Visible = true
			return
		end
		local text = idleText()
		hints.Frame.Visible = text ~= nil
		if text then
			set(text)
		end
	end)
	Net.Client.On("HuntStatus", function(message: string, done: boolean?)
		set(message)
		if done then -- the way back failed: say why for a moment, then holding works again
			sent, heldSince = false, nil
			notice, noticeUntil = message, os.clock() + NOTICE
		end
	end)
end

return ReturnController

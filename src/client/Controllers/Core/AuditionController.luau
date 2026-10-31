--!strict
-- AuditionController (Studio only): runs the sound audition panel (UI/Dev/Audition) in a playtest, so the owner can
-- choose each cue's sound from its shortlist (Definitions/Audition). It opens by itself when the workspace attribute
-- BL_Audition is true (set it in Edit mode, then press Play); F2 hides or shows it. Play previews a candidate flat and
-- makes it the cue's sound in the game at once (Sfx.Audition), so it can be judged in a fight; Pick records the choice,
-- prints it to the Output and keeps it playing for the rest of the session. The bridge ReplicatedStorage.BL_Audition
-- (Client context) answers "Picks" (JSON), "Open", "Close", "Play" and "Pick" (cue, index: what the buttons do) and
-- "Reset" (forget every pick and swap; the self-test's cleanup).

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Registry = require(ReplicatedStorage.Shared.Definitions.Registry)
local Sfx = require(script.Parent.Parent.Parent.Audio.Sfx)
local UI = script.Parent.Parent.Parent.UI
local Focus = require(UI.Core.Focus)
local Layers = require(UI.Core.Layers)
local Audition = require(UI.Dev.Audition)

local ATTRIBUTE = "BL_Audition" -- workspace: open the panel when a playtest starts
local BRIDGE_NAME = "BL_Audition"
local TOGGLE_KEY = Enum.KeyCode.F2 -- a function key: the same on every keyboard layout

local AuditionController = {}

local screen: Audition.Screen? = nil
local releaseFocus: (() -> ())? = nil
local previewing: Sound? = nil
local picks: { [string]: number } = {}

-- The shortlists in their listed order.
local function entries(): { Audition.Entry }
	local list = {}
	for cue, shortlist in Registry.Audition() do
		table.insert(list, {
			Cue = cue,
			Label = shortlist.Label,
			Brief = shortlist.Brief,
			Candidates = shortlist.Candidates,
			Order = shortlist.Order,
		})
	end
	table.sort(list, function(a: any, b: any)
		return a.Order < b.Order
	end)
	return list :: any
end

local function candidate(cue: any, index: any): any
	local shortlist = Registry.Audition()[cue]
	return shortlist and shortlist.Candidates[index]
end

local function play(cue: string, index: number)
	local chosen = candidate(cue, index)
	if previewing then
		previewing:Stop()
	end
	previewing = Sfx.Preview(chosen)
	Sfx.Audition(cue, chosen)
end

local function pick(cue: string, index: number)
	local chosen = candidate(cue, index)
	picks[cue] = index
	Sfx.Audition(cue, chosen)
	if screen then
		screen:SetPicked(cue, index)
	end
	print(`[BL] Audition pick: {cue} = {chosen.Id} ({chosen.From}-{chosen.To}) "{chosen.Title}"`)
end

local function setOpen(open: boolean)
	if open and not screen then
		local built = Audition.new(Layers.Get("Menus"), entries(), { Play = play, Pick = pick })
		for cue, index in picks do
			built:SetPicked(cue, index)
		end
		screen = built
	end
	if screen then
		screen:SetVisible(open)
	end
	if open and not releaseFocus then
		releaseFocus = Focus.Push("Audition", { Cursor = true, Gameplay = false, Hud = true })
	elseif not open and releaseFocus then
		releaseFocus()
		releaseFocus = nil
	end
end

function AuditionController.Start()
	if not RunService:IsStudio() or next(Registry.Audition()) == nil then
		return
	end
	local bridge = Instance.new("BindableFunction")
	bridge.Name = BRIDGE_NAME
	bridge.OnInvoke = function(command: string, cue: string?, index: number?): any
		if command == "Picks" then
			local out = {}
			for cue, index in picks do
				local chosen = candidate(cue, index)
				out[cue] = { Index = index, Id = chosen.Id, From = chosen.From, To = chosen.To, Title = chosen.Title }
			end
			return HttpService:JSONEncode(out)
		elseif command == "Open" or command == "Close" then
			setOpen(command == "Open")
			return true
		elseif command == "Play" or command == "Pick" then
			local name, at = cue :: string, index :: number
			assert(candidate(name, at), `BL_Audition: no candidate {at} for {name}`)
			if command == "Play" then
				play(name, at)
			else
				pick(name, at)
			end
			return true
		elseif command == "Reset" then
			for name in Registry.Audition() do
				Sfx.Audition(name, nil)
			end
			table.clear(picks)
			if screen then
				screen:Destroy()
				screen = nil
			end
			setOpen(false)
			return true
		end
		error(`BL_Audition: unknown command {command}`)
	end
	bridge.Parent = ReplicatedStorage
	if workspace:GetAttribute(ATTRIBUTE) then
		setOpen(true)
	end
	UserInputService.InputBegan:Connect(function(input: InputObject)
		if input.KeyCode == TOGGLE_KEY and not UserInputService:GetFocusedTextBox() then
			setOpen(not (screen and screen.Root.Visible))
		end
	end)
end

return AuditionController

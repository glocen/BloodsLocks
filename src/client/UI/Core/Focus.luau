--!strict
-- Focus: who owns the player's input right now. Screens push an owner and release it; the top owner decides:
--   Cursor: the mouse is free (CameraController asks CursorFree() before locking it),
--   Gameplay: the gameplay InputContext runs (false = moves, attacks and skills are paused),
--   Hud: the combat HUD layer shows (and the World layer: plates and call-outs over the world).
-- Releasing restores whatever is below, so a death, a phase change or an interrupted screen can't leave a stuck
-- cursor or a dead context (UI standard: menus own cursor and input; closing restores prior control).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EntityState = require(ReplicatedStorage.Shared.Simulation.EntityState)
local Layers = require(script.Parent.Layers)

export type Options = { Cursor: boolean, Gameplay: boolean, Hud: boolean }
type Owner = { Name: string, Options: Options }

local Focus = {}

local CONTEXT_NAME = EntityState.InputContextName
local stack: { Owner } = {}

local function top(): Options?
	local owner = stack[#stack]
	return if owner then owner.Options else nil
end

local function apply()
	local options = top()
	local context = Players.LocalPlayer:FindFirstChild(CONTEXT_NAME) :: InputContext?
	if context then
		context.Enabled = if options then options.Gameplay else true
	end
	local hud = if options then options.Hud else true
	Layers.Get("HUD").Enabled = hud
	Layers.Get("World").Enabled = hud
end

-- Takes input for `name`; returns the function that gives it back (safe to call more than once).
function Focus.Push(name: string, options: Options): () -> ()
	local owner = { Name = name, Options = options }
	table.insert(stack, owner)
	apply()
	return function()
		local index = table.find(stack, owner)
		if index then
			table.remove(stack, index)
			apply()
		end
	end
end

-- Whether the top owner wants the mouse free (CameraController locks it otherwise).
function Focus.CursorFree(): boolean
	local options = top()
	return options ~= nil and options.Cursor
end

-- The top owner's name, or nil (debugging, tests).
function Focus.Current(): string?
	local owner = stack[#stack]
	return if owner then owner.Name else nil
end

return Focus

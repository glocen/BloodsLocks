--!strict
-- SelfTestController (Studio only): runs the regression self-test inside a playtest and reports PASS/FAIL per check.
-- The checks live in Cases; the server half (test pad, scripted hits) is SelfTestService.
-- Run it from the MCP Client context or the client command bar:
--   game.ReplicatedStorage.BL_SelfTest:Invoke()          -- every check
--   game.ReplicatedStorage.BL_SelfTest:Invoke("Dodge")   -- only checks whose name contains "Dodge"
--   game.ReplicatedStorage.BL_SelfTest:Invoke("UI lint") -- the labels on the screen that's open now (it stays put)
-- It returns the report as text. Leave the keyboard alone while it runs: real input would mix with the test's.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptContext = game:GetService("ScriptContext")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local EntityState = require(Shared.Simulation.EntityState)
local Parts = require(Shared.Util.Parts)
local LockOnController = require(script.Parent.LockOnController)
local Cases = require(script.Cases)

local BRIDGE_NAME = "BL_SelfTest"
local PAD_NAME = "BL_TestPad"
local ENEMY_FOLDER = "BL_Enemies" -- NpcService's folder (server code isn't visible to clients)
local SETTLE_TIMEOUT = 4 -- seconds to wait for the character to land, idle and refill stamina
local PRESS_TIME = 0.05

local A = EntityState.Attr
local player = Players.LocalPlayer

local SelfTestController = {}

export type Test = {
	Character: () -> Model,
	Root: () -> BasePart,
	Num: (attribute: string, default: number?) -> number,
	Fx: (model: Model?) -> Instance,
	Dummy: () -> Model?,
	DummyHp: () -> number,
	Press: (action: string, hold: number?) -> (),
	Hold: (action: string, down: boolean) -> (),
	Wait: (seconds: number) -> (),
	Server: (command: string, ...any) -> ...any,
	Reset: () -> (),
	Lock: (model: Model?) -> (), -- the dummy unless a model is given
	Enemy: (name: string) -> Model?,
	Check: (label: string, ok: boolean, detail: string?) -> (),
	Near: (label: string, actual: number, expected: number, tolerance: number) -> (),
}

local function binding(action: string): any
	local context = player:WaitForChild(EntityState.InputContextName)
	return (context :: any)[action].Script
end

local function serverCall(command: string, ...: any): ...any
	local results = table.pack(Net.Client.Invoke("DebugCommand", command, ...))
	if not results[1] then
		error(`server command {command} failed: {tostring(results[2])}`, 2)
	end
	return table.unpack(results, 2, results.n)
end

local function run(filter: string?): string
	local lines: { string } = {}
	local passed, failed = 0, 0
	local current = ""
	local function record(ok: boolean, label: string, detail: string?)
		if ok then
			passed += 1
		else
			failed += 1
		end
		table.insert(lines, `{if ok then "PASS" else "FAIL"}  {current} · {label}{if detail then " (" .. detail .. ")" else ""}`)
	end

	local t: Test
	t = {
		Character = function()
			return assert(player.Character, "no character")
		end,
		Root = function()
			return assert(Parts.Root(t.Character()), "no root")
		end,
		Num = function(attribute, default)
			return EntityState.Number(t.Character(), attribute, default or 0)
		end,
		Fx = function(model)
			return EntityState.Fx(model or t.Character())
		end,
		Dummy = function()
			local pad = workspace:FindFirstChild(PAD_NAME)
			return pad and pad:FindFirstChild("Dummy") :: Model?
		end,
		DummyHp = function()
			local dummy = t.Dummy()
			return if dummy then EntityState.Number(dummy, A.HP, 0) else 0
		end,
		Press = function(action, hold)
			local b = binding(action)
			b:Fire(true)
			task.wait(hold or PRESS_TIME)
			b:Fire(false)
		end,
		Hold = function(action, down)
			binding(action):Fire(down)
		end,
		Wait = function(seconds)
			task.wait(seconds)
		end,
		Server = serverCall,
		-- Back on the pad, facing a fresh dummy, landed, idle, unlocked, with full stamina.
		Reset = function()
			LockOnController.SetTarget(nil)
			serverCall("TestPad")
			local deadline = os.clock() + SETTLE_TIMEOUT
			repeat
				task.wait(0.1)
				local character = t.Character()
				local settled = EntityState.CurrentAction(character) == ""
					and character:GetAttribute(A.WasGrounded) == true
					and t.Num(A.Stamina) >= t.Num(A.StaminaMax, 1)
					and t.Dummy() ~= nil
			until settled or os.clock() > deadline
			task.wait(0.2)
		end,
		Lock = function(model)
			LockOnController.SetTarget(model or t.Dummy())
			task.wait(0.1)
		end,
		Enemy = function(name)
			local folder = workspace:FindFirstChild(ENEMY_FOLDER)
			return folder and folder:FindFirstChild(name) :: Model?
		end,
		Check = function(label, ok, detail)
			record(ok, label, detail)
		end,
		Near = function(label, actual, expected, tolerance)
			record(math.abs(actual - expected) <= tolerance, label, `got {string.format("%.2f", actual)}, want {string.format("%.2f", expected)} ±{tolerance}`)
		end,
	}

	local started = os.clock()
	-- Script errors anywhere during the run fail it, on both sides: a case can pass while something it doesn't look at
	-- breaks (a simulation step erroring once, 2026-10-31).
	pcall(serverCall, "TestErrorsClear")
	local clientErrors: { string } = {}
	local watch = ScriptContext.Error:Connect(function(message: string, _trace: string, origin: Instance?)
		if origin and origin:IsDescendantOf(game) then -- the game's own scripts, not Studio plugins
			table.insert(clientErrors, `{message} ({origin:GetFullName()})`)
		end
	end)
	for _, case in Cases do
		if filter == nil or string.find(case.Name, filter, 1, true) then
			current = case.Name
			local ok, err = pcall(function()
				if not case.Stay then -- Stay: the case checks the screen as it is (UI lint)
					t.Reset()
				end
				case.Run(t)
			end)
			if not ok then
				record(false, "crashed", tostring(err))
			end
		end
	end
	LockOnController.SetTarget(nil)
	pcall(serverCall, "TestPadClear")
	watch:Disconnect()
	current = "Script errors"
	local ok, serverErrors = pcall(serverCall, "TestErrors")
	local serverList = if ok and type(serverErrors) == "table" then serverErrors else {}
	record(#serverList == 0, "none on the server", serverList[1])
	record(#clientErrors == 0, "none on the client", clientErrors[1])

	table.insert(lines, 1, `SELF-TEST {if failed == 0 then "PASSED" else "FAILED"}: {passed} passed, {failed} failed ({string.format("%.1f", os.clock() - started)} s)`)
	return table.concat(lines, "\n")
end

function SelfTestController.Start()
	if not RunService:IsStudio() then
		return
	end
	local bridge = Instance.new("BindableFunction")
	bridge.Name = BRIDGE_NAME
	bridge.OnInvoke = run
	bridge.Parent = ReplicatedStorage
end

return SelfTestController

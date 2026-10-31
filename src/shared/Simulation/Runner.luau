--!strict
-- Runner: the one RunService:BindToSimulation callback. It runs on the server (every player) and on each
-- client (its own character, predicted). Order each step:
--   server: apply hits queued since the last step | client: feed Face/Aim input
--   per character: spawn setup -> input -> locomotion sense -> actions -> locomotion -> facing -> stamina ->
--   stagger drain -> animation

local RunService = game:GetService("RunService")

local Shared = script.Parent.Parent
local Vector = require(Shared.Util.Vector)
local Rigs = require(script.Parent.Rigs)
local Input = require(script.Parent.Input)
local Spawn = require(script.Parent.Spawn)
local Locomotion = require(script.Parent.Locomotion)
local ActionSim = require(script.Parent.ActionSim)
local Facing = require(script.Parent.Facing)
local Knock = require(script.Parent.Knock)
local Stamina = require(script.Parent.Stamina)
local CombatSim = require(script.Parent.CombatSim)
local AnimationSim = require(script.Parent.AnimationSim)

local Runner = {}

local function step(rig: Rigs.Rig, now: number, dt: number)
	local handles = rig.Input
	local character, humanoid, root = rig.Character, rig.Humanoid, rig.Root
	if not handles or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		return
	end
	Spawn.EnsureReady(rig.Player, character, humanoid, now)
	local input = Input.Read(handles, character)
	local sense = Locomotion.Sense(character, humanoid, now)
	local act = ActionSim.Step(character, Vector.Flat(root.CFrame.LookVector), {
		Now = now,
		Busy = sense.Busy,
		Charging = sense.Charging,
		MoveDirection = sense.MoveDirection,
		Input = input,
	})
	sense = Locomotion.Step(character, humanoid, root, sense, input, act, now, dt)
	Facing.Step(humanoid, root, input.Face, Knock.Facing(character, now) or act.Facing, sense.Dodging, dt)
	Stamina.Step(character, now, dt)
	CombatSim.StepStagger(character, now, dt)
	AnimationSim.Step(rig.Animator, character, now, sense.Grounded, sense.Moving)
end

local initialized = false

-- Call once per side: the server's SimulationService and the client's SimulationController.
function Runner.Initialize()
	if initialized then
		return
	end
	initialized = true
	Rigs.Initialize()
	local isServer = RunService:IsServer()
	RunService:BindToSimulation(function(dt: number)
		local now = time()
		if isServer then
			CombatSim.ServerStep(now)
		else
			local rig = Rigs.Local()
			if rig and rig.Input then
				Input.Feed(rig.Input)
			end
		end
		for _, rig in Rigs.All() do
			step(rig, now, dt)
		end
	end)
end

return Runner

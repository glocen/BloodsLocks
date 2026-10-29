--!strict
-- CombatService: server-side hit detection. Every Heartbeat it looks at each entity's current action and hands
-- it to Projectiles (Blood Blade, ...), Gunfire (gun shots, beam ticks) or Melee (MuchachoHitbox per Hit
-- window). Hits are queued into CombatSim, which applies them inside the next simulation step.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Registry = require(Shared.Definitions.Registry)
local EntityState = require(Shared.Simulation.EntityState)
local CombatSim = require(Shared.Simulation.CombatSim)
local DebugService = require(script.Parent.DebugService)
local Melee = require(script.Melee)
local Gunfire = require(script.Gunfire)
local Projectiles = require(script.Projectiles)

local CombatService = {}

local hitsLanded = 0

local function onHit(attacker: Model, target: Model, hit: any)
	hitsLanded += 1
	CombatSim.Queue({ Attacker = attacker, Target = target, Hit = hit })
end

local function step(dt: number)
	local now = time()
	for _, model in CollectionService:GetTagged(EntityState.Tag) do
		local id, action, startedAt = EntityState.CurrentAction(model)
		if not action then
			Melee.Stop(model)
		elseif action.Projectile then
			Projectiles.Update(model, action, startedAt, now, onHit)
		elseif action.Shots or action.Beam then
			Gunfire.Update(model, action, startedAt, now, onHit)
		elseif action.Hit then
			Melee.Update(model, id, action, startedAt, now, onHit)
		end
	end
	Projectiles.Step(dt)
end

function CombatService.Init()
	DebugService.Register("HitsLanded", function()
		return hitsLanded
	end)
	-- Test helper: once the named player's next dodge starts, a dummy's saber hit lands `delay` seconds later.
	DebugService.Register("HitAfterNextDodge", function(playerName: string, delay: number)
		local player = Players:FindFirstChild(playerName) :: Player?
		local character = player and player.Character
		local dummies = workspace:FindFirstChild("TrainingDummies")
		local attacker = dummies and dummies:FindFirstChildWhichIsA("Model")
		assert(character and attacker, "no character or dummy")
		task.spawn(function()
			character:GetAttributeChangedSignal(EntityState.Attr.DodgeStart):Wait()
			task.wait(delay)
			CombatSim.Queue({ Attacker = attacker, Target = character, Hit = Registry.Action("Saber.Light1").Hit })
		end)
		return true
	end)
end

function CombatService.Start()
	CollectionService:GetInstanceRemovedSignal(EntityState.Tag):Connect(function(model)
		if model:IsA("Model") then
			Melee.Stop(model)
			Gunfire.Forget(model)
			Projectiles.Forget(model)
		end
	end)
	RunService.Heartbeat:Connect(step)
end

return CombatService

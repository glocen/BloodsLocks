--!strict
-- Apart: keeps each pair a bite holds (Simulation/Bite) from colliding while it lasts, so their animated heads and
-- torsos don't shove the two bodies apart. Run every Heartbeat by CombatService, outside the simulation: simulation
-- callbacks may not destroy instances. A released pair keeps ignoring each other for LINGER seconds while the throw
-- parts them.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bite = require(ReplicatedStorage.Shared.Simulation.Bite)

local LINGER = 0.3

type Pair = { Victim: Model, Constraints: { NoCollisionConstraint } }

local Apart = {}

local active: { [Model]: Pair } = {}

-- No collisions between two bodies' solid parts (on R6, head and torso).
local function between(a: Model, b: Model): { NoCollisionConstraint }
	local constraints = {}
	for _, partA in a:GetChildren() do
		if partA:IsA("BasePart") and partA.CanCollide then
			for _, partB in b:GetChildren() do
				if partB:IsA("BasePart") and partB.CanCollide then
					local constraint = Instance.new("NoCollisionConstraint")
					constraint.Part0, constraint.Part1 = partA, partB
					constraint.Parent = partA
					table.insert(constraints, constraint)
				end
			end
		end
	end
	return constraints
end

local function release(pair: Pair)
	for _, constraint in pair.Constraints do
		Debris:AddItem(constraint, LINGER)
	end
end

function Apart.Update()
	local held = Bite.Pairs()
	for biter, pair in active do
		if held[biter] ~= pair.Victim then
			release(pair)
			active[biter] = nil
		end
	end
	for biter, victim in held do
		if not active[biter] then
			active[biter] = { Victim = victim, Constraints = between(biter, victim) }
		end
	end
end

return Apart

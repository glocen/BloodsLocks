--!strict
-- Knock: knockback that shows. A hit pushes its target straight away from the attacker for Config.Knock.Time seconds,
-- fast enough to cover the hit's distance; the target's own movement step holds that velocity (players in Locomotion,
-- every other entity on the server, EntityService), with WalkSpeed raised to match so Roblox's walk controller doesn't
-- brake it. Apply runs inside CombatSim (the simulation); Hold runs every step while the push lasts.

local Shared = script.Parent.Parent
local Config = require(Shared.Config.Combat)
local Parts = require(Shared.Util.Parts)
local Vector = require(Shared.Util.Vector)
local EntityState = require(script.Parent.EntityState)

local A = EntityState.Attr

local Knock = {}

-- How far a hit pushes, in studs: its own Knockback, else its reaction's default.
function Knock.Distance(hit: any): number
	return hit.Knockback or Config.Knock.ByReaction[hit.Reaction or "Flinch"] or 0
end

-- Pushes `target` `distance` studs away from `attacker`: straight away, or turned `turn` degrees to the attacker's left
-- (a bite's throw, Hit.KnockTurn).
function Knock.Apply(target: Model, attacker: Model, distance: number, now: number, turn: number?)
	local targetRoot, attackerRoot = Parts.Root(target), Parts.Root(attacker)
	if distance <= 0 or not targetRoot or not attackerRoot then
		return
	end
	local away = Vector.Flat(targetRoot.Position - attackerRoot.Position)
	if away == Vector3.zero then
		away = Vector.Flat(attackerRoot.CFrame.LookVector)
	end
	if away == Vector3.zero then
		return
	end
	if turn then
		away = CFrame.Angles(0, math.rad(turn), 0):VectorToWorldSpace(away)
	end
	target:SetAttribute(A.Knock, away * (distance / Config.Knock.Time))
	target:SetAttribute(A.KnockUntil, now + Config.Knock.Time)
end

function Knock.Active(model: Model, now: number): boolean
	return now < EntityState.Number(model, A.KnockUntil, 0)
end

-- Holds the push while it lasts. Returns its speed (0 when not pushed), the WalkSpeed the caller must keep.
function Knock.Hold(model: Model, humanoid: Humanoid, root: BasePart, now: number): number
	local velocity = model:GetAttribute(A.Knock)
	if not Knock.Active(model, now) or typeof(velocity) ~= "Vector3" or velocity.Magnitude < 1e-3 then
		return 0
	end
	humanoid:Move(velocity.Unit, false) -- steer along the push so the walk controller doesn't brake it
	local v = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(velocity.X, v.Y, velocity.Z)
	return velocity.Magnitude
end

return Knock

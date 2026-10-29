--!strict
-- Stamina: spend and regenerate (inside the simulation, on the character's attributes).

local Config = require(script.Parent.Parent.Config.Stamina)
local EntityState = require(script.Parent.EntityState)

local A = EntityState.Attr

local Stamina = {}

function Stamina.Reset(character: Model, now: number)
	character:SetAttribute(A.StaminaMax, Config.Max)
	character:SetAttribute(A.Stamina, Config.Max)
	character:SetAttribute(A.StaminaRegenAt, now)
end

-- Drains stamina (never below 0) and restarts the regen delay. Used by spends and by blocked hits.
function Stamina.Drain(character: Model, amount: number, now: number)
	local left = math.max(0, EntityState.Number(character, A.Stamina, 0) - amount)
	character:SetAttribute(A.Stamina, left)
	character:SetAttribute(A.StaminaRegenAt, now + (if left <= 0 then Config.ExhaustedRegenDelay else Config.RegenDelay))
end

-- Spends stamina for an action. Returns false (and spends nothing) if the action isn't allowed.
function Stamina.TrySpend(character: Model, cost: number, now: number): boolean
	local current = EntityState.Number(character, A.Stamina, 0)
	if current <= 0 or (Config.RequireFullCost and current < cost) then
		return false
	end
	Stamina.Drain(character, cost, now)
	return true
end

function Stamina.Step(character: Model, now: number, dt: number)
	local current = EntityState.Number(character, A.Stamina, 0)
	local max = EntityState.Number(character, A.StaminaMax, Config.Max)
	if current < max and now >= EntityState.Number(character, A.StaminaRegenAt, 0) then
		character:SetAttribute(A.Stamina, math.min(max, current + Config.RegenPerSecond * dt))
	end
end

return Stamina

--!strict
-- Stamina rules (from the Duskbloods research): sprinting, ground jumps, high jumps and all attacks are free.
-- Dodges, air dashes, air jumps and some skills cost stamina.

return {
	Max = 100,
	PerLevel = 3, -- in-match levels add max stamina
	RegenPerSecond = 50,
	RegenDelay = 0.45, -- after a spend
	ExhaustedRegenDelay = 0.9, -- after hitting 0
	-- Souls rule: any stamina left lets an action happen, and it can drain to 0.
	RequireFullCost = false,
	EvasionCancelWindow = 0.15, -- a dodge this soon after your own attack is free (wired up with combat)
}

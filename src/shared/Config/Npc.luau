--!strict
-- NPC tuning shared by every AI-driven entity (enemies, Shinigami, training dummies). Per-enemy numbers live in
-- Definitions.Enemies.

return {
	BrainRate = 10, -- brain decisions per second
	SleepDistance = 200, -- brains beyond this many studs from every player don't think
	MaxAttackersPerTarget = 2, -- the rest hold back and wait their turn (Souls group AI)
	TargetMemory = 4, -- seconds a target stays chosen once it leaves AggroRange
	HomeRadius = 4, -- an enemy back within this of its spawn is home
	LeashHealDelay = 3, -- seconds home with no target before an enemy heals to full
	RespawnClearRadius = 70, -- a spawn only refills when no player is this close
	CorpseFade = 1.2, -- seconds a dead NPC takes to fade out
	SpawnRadius = 6, -- default scatter around a spawn part

	-- Where a Shinigami keeps to, in its master's space: left and slightly ahead, never between the camera (behind,
	-- over the right shoulder) and the fight.
	FollowOffset = Vector3.new(-5, 0, -2),

	-- Flash before an attack, so it can be read and dodged.
	Telegraph = {
		Attack = Color3.fromRGB(222, 150, 64), -- warm: a normal attack is coming
		Skill = Color3.fromRGB(176, 22, 44), -- red: a special move is coming
		Outline = Color3.fromRGB(255, 120, 120),
	},
}

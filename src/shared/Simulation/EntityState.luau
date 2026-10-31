--!strict
-- EntityState: the attribute schema for every entity (players, dummies, NPCs). Under Server Authority these
-- attributes ARE the state: they roll back and resimulate with physics. Limits per instance: 64 attributes and
-- 1024 bytes in total (names count), so stored names are 2-4 letter codes. Always go through Attr.
-- Feedback events live on the Humanoid (see Fx) so they use a separate budget.

local Registry = require(script.Parent.Parent.Definitions.Registry)

local EntityState = {}

EntityState.Tag = "BL_Entity" -- CollectionService tag on every combat entity
-- The side (OwnerId) every hostile NPC fights for, so enemies never hurt each other. 0 is never a player's UserId.
EntityState.HostileSide = 0
EntityState.InputContextName = "BLGameplay"

local A = {
	Ready = "rdy",
	-- button held last step (for press/release edges, see Input)
	HeldJump = "hJ",
	HeldDodge = "hD",
	HeldSprint = "hS",
	HeldAttack = "hA",
	HeldStrong = "hR",
	HeldRanged = "hG",
	HeldBite = "hB",
	HeldSkill1 = "h1",
	HeldSkill2 = "h2",
	-- ground and jumps
	WasGrounded = "gW",
	LeftGroundAt = "gL",
	GroundLockUntil = "gK",
	JumpsUsed = "jU",
	ChargeStart = "jC",
	Charging = "jG",
	-- sprint
	Sprinting = "sp",
	StillSince = "sS",
	-- dodge and air dash
	DodgeStart = "dS",
	DodgeEnd = "dE",
	DodgeDir = "dV",
	DodgeBack = "dB",
	IFrameFrom = "iF",
	IFrameTo = "iT",
	DashEnd = "aE",
	DashDir = "aV",
	AirDashesUsed = "aU",
	-- animation events
	LaunchAt = "lA",
	LaunchKind = "lK", -- "ground", "high" or "air"
	LandAt = "lD",
	-- stamina
	Stamina = "st",
	StaminaMax = "stM",
	StaminaRegenAt = "stR",
	-- class, health, stagger
	ClassId = "cls",
	HP = "hp",
	HPMax = "hpM",
	Stagger = "sg",
	StaggerUntil = "sgU",
	HitstunUntil = "hsU",
	-- current action
	ActionId = "act", -- "" when idle
	ActionStart = "actT",
	ActionBuffered = "actB", -- next hit of a chain was pressed
	ActionFacing = "actF",
	Queued = "actQ", -- buffered action kind: "", "Attack", "Ranged", "Bite", "Skill1" or "Skill2"
	EvadeFreeFrom = "evF", -- dodges in [EvadeFreeFrom, +window] cost no stamina
	GuardStart = "gdT", -- -1 when not guarding
	Aim = "aim",
	Ammo = "amo",
	ReloadUntil = "rlU", -- 0 when not reloading
	Knock = "knV", -- the push a hit gave (velocity, studs/s), held until KnockUntil (Simulation/Knock)
	KnockUntil = "knU",
	KnockFacing = "knF", -- the way the body faced when the push began, held while it lasts
	Level = "lvl", -- in-match level (gates skills; the leveling system arrives with match rules)
	Skill1Charges = "s1C",
	Skill1RechargeAt = "s1R", -- when the next charge comes back
	Skill2Charges = "s2C",
	Skill2RechargeAt = "s2R",
	-- allegiance: the UserId of the player a companion (Shinigami) fights for
	OwnerId = "own",
	EnemyId = "eid", -- an enemy's definition id (Definitions/Enemies), for its plate
	ShinigamiId = "shi", -- a summoned Shinigami's definition id (Definitions/Shinigami), for its plate
	-- feedback: an enemy noticed a target (on the Humanoid, like the hit events below): when, and whom (model name)
	AlertAt = "alT",
	AlertTarget = "alW",
	-- feedback events (on the Humanoid)
	LastHitAt = "hitT",
	LastHitDamage = "hitD",
	LastHitBy = "hitB",
	LastHitRanged = "hitR", -- the last hit was a round, a projectile or a beam (their impacts play their own sounds)
	LastEvadedAt = "evT",
	LastBlockAt = "blkT",
	LastParryAt = "pryT",
	LastHowlAt = "hwlT",
	GuardBrokenAt = "gbT",
	LastBiteAt = "bitT", -- a bite took hold (Simulation/Bite): the seize
	LastBiteHeal = "bitH", -- what the hold healed, written when it ends
	BiteVictim = "bitV", -- whom it holds (model name)
	BiteReleaseAt = "bitE", -- the hold ended: its release, or the moment it broke
	StaggeredAt = "stgT", -- a stagger began (its body drops to a knee until StaggerUntil)
	BittenAt = "bnT", -- on the victim: seized by a bite
	BittenUntil = "bnU", -- on the victim: held until then (the release, or the moment the hold broke)
}
EntityState.Attr = A

-- Attributes per skill slot, indexed by slot number.
EntityState.SkillSlots = {
	{ Charges = A.Skill1Charges, RechargeAt = A.Skill1RechargeAt },
	{ Charges = A.Skill2Charges, RechargeAt = A.Skill2RechargeAt },
}

-- Placeholder in the defaults below, replaced with the spawn time.
local NOW = newproxy()

EntityState.Defaults = {
	Movement = {
		HeldJump = false, HeldDodge = false, HeldSprint = false,
		WasGrounded = true, LeftGroundAt = NOW, GroundLockUntil = 0, JumpsUsed = 0, ChargeStart = -1, Charging = false,
		Sprinting = false, StillSince = -1,
		DodgeStart = 0, DodgeEnd = 0, DodgeDir = Vector3.zero, DodgeBack = false, IFrameFrom = 0, IFrameTo = 0,
		DashEnd = 0, DashDir = Vector3.zero, AirDashesUsed = 0,
		LaunchAt = -10, LaunchKind = "", LandAt = -10,
	},
	Combat = {
		HeldAttack = false, HeldStrong = false, HeldRanged = false, HeldBite = false, HeldSkill1 = false, HeldSkill2 = false,
		Level = 1, Skill1Charges = 0, Skill1RechargeAt = 0, Skill2Charges = 0, Skill2RechargeAt = 0,
		Stagger = 0, StaggerUntil = 0, HitstunUntil = 0,
		ActionId = "", ActionStart = 0, ActionBuffered = false, ActionFacing = Vector3.new(0, 0, -1), Queued = "",
		EvadeFreeFrom = -10, GuardStart = -1, Aim = Vector3.new(0, 0, -1), Ammo = 0, ReloadUntil = 0,
		Knock = Vector3.zero, KnockUntil = 0, KnockFacing = Vector3.zero,
	},
	Fx = {
		LastHitAt = -10, LastHitDamage = 0, LastHitBy = "", LastHitRanged = false, LastEvadedAt = -10, LastBlockAt = -10,
		LastParryAt = -10, LastHowlAt = -10, GuardBrokenAt = -10, LastBiteAt = -10, LastBiteHeal = 0, AlertAt = -10, AlertTarget = "",
		BiteVictim = "", BiteReleaseAt = -10, StaggeredAt = -10, BittenAt = -10, BittenUntil = 0,
	},
}

-- Writes a defaults table (keys are Attr names) onto an instance.
function EntityState.Apply(instance: Instance, defaults: { [string]: any }, now: number)
	for key, value in defaults do
		instance:SetAttribute(A[key], if value == NOW then now else value)
	end
end

-- Where feedback events are written: the Humanoid, so they don't eat into the character's budget.
function EntityState.Fx(model: Model): Instance
	return model:FindFirstChildOfClass("Humanoid") or model
end

-- Combat state for any entity: players on spawn (Spawn) and dummies/NPCs when they're created.
function EntityState.InitCombat(model: Model, maxHealth: number, now: number)
	EntityState.Apply(model, EntityState.Defaults.Combat, now)
	model:SetAttribute(A.HPMax, maxHealth)
	model:SetAttribute(A.HP, maxHealth)
	EntityState.Apply(EntityState.Fx(model), EntityState.Defaults.Fx, now)
end

function EntityState.Number(instance: Instance, attribute: string, default: number): number
	local value = instance:GetAttribute(attribute)
	return if type(value) == "number" then value else default
end

-- Writes only when the value changes (unchanged writes still cost replication).
function EntityState.Set(instance: Instance, attribute: string, value: any)
	if instance:GetAttribute(attribute) ~= value then
		instance:SetAttribute(attribute, value)
	end
end

-- The entity's current action definition and when it started, or nil when idle.
function EntityState.CurrentAction(model: Model): (string, any?, number)
	local id = model:GetAttribute(A.ActionId)
	if type(id) ~= "string" or id == "" then
		return "", nil, 0
	end
	return id, Registry.Action(id), EntityState.Number(model, A.ActionStart, 0)
end

function EntityState.IsInvincible(model: Model, now: number): boolean
	return now >= EntityState.Number(model, A.IFrameFrom, 0) and now < EntityState.Number(model, A.IFrameTo, 0)
end

function EntityState.IsStunned(model: Model, now: number): boolean
	return now < EntityState.Number(model, A.HitstunUntil, 0) or now < EntityState.Number(model, A.StaggerUntil, 0)
end

-- Held in a bite (Simulation/Bite) as its victim.
function EntityState.IsHeld(model: Model, now: number): boolean
	return now < EntityState.Number(EntityState.Fx(model), A.BittenUntil, 0)
end

return EntityState

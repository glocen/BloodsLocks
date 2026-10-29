--!strict
-- Locomotion: the Duskbloods-style movement kit: sprint toggle, tap jump / hold-to-charge high jump, air jumps,
-- ground dodge (with i-frames) or backstep, air dash, extra fall gravity. Runs per character inside the
-- simulation (see Runner) in two halves around ActionSim: Sense reads the ground and dodge state, Step applies
-- movement once the action result is known. All state lives in attributes (EntityState).

local Shared = script.Parent.Parent
local Config = require(Shared.Config.Movement)
local StaminaConfig = require(Shared.Config.Stamina)
local Vector = require(Shared.Util.Vector)
local EntityState = require(script.Parent.EntityState)
local Stamina = require(script.Parent.Stamina)
local ActionSim = require(script.Parent.ActionSim)

local A = EntityState.Attr
local GRAVITY = workspace.Gravity
local set = EntityState.Set

export type Sense = {
	Grounded: boolean,
	Dodging: boolean,
	Dashing: boolean,
	Busy: boolean, -- dodging or dashing
	Charging: boolean, -- crouch-charging a high jump (last step)
	MoveDirection: Vector3, -- flat
	Moving: boolean,
	JumpsUsed: number,
	AirDashes: number,
}

local Locomotion = {}

local function launch(character: Model, humanoid: Humanoid, root: BasePart, velocityY: number, now: number, kind: string)
	character:SetAttribute(A.LaunchAt, now)
	character:SetAttribute(A.LaunchKind, kind)
	local v = root.AssemblyLinearVelocity
	humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	root.AssemblyLinearVelocity = Vector3.new(v.X, velocityY, v.Z)
	character:SetAttribute(A.GroundLockUntil, now + 0.15)
end

-- Ground contact (with landing and coyote time), dodge and dash state.
function Locomotion.Sense(character: Model, humanoid: Humanoid, now: number): Sense
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air and now >= EntityState.Number(character, A.GroundLockUntil, 0)
	local jumpsUsed = EntityState.Number(character, A.JumpsUsed, 0)
	local airDashes = EntityState.Number(character, A.AirDashesUsed, 0)
	local wasGrounded = character:GetAttribute(A.WasGrounded) == true
	if grounded then
		if not wasGrounded and now - EntityState.Number(character, A.LeftGroundAt, now) > 0.45 then
			set(character, A.LandAt, now) -- landing after real airtime
		end
		jumpsUsed, airDashes = 0, 0
	elseif wasGrounded then
		set(character, A.LeftGroundAt, now)
	end
	if not grounded and jumpsUsed == 0 and now - EntityState.Number(character, A.LeftGroundAt, now) > Config.CoyoteTime then
		jumpsUsed = 1 -- walked off a ledge: the ground jump is gone once coyote time runs out
	end
	local dodging = now < EntityState.Number(character, A.DodgeEnd, 0)
	local dashing = now < EntityState.Number(character, A.DashEnd, 0)
	local moveDirection = Vector.Flat(humanoid.MoveDirection)
	return {
		Grounded = grounded,
		Dodging = dodging,
		Dashing = dashing,
		Busy = dodging or dashing,
		Charging = character:GetAttribute(A.Charging) == true,
		MoveDirection = moveDirection,
		Moving = moveDirection ~= Vector3.zero,
		JumpsUsed = jumpsUsed,
		AirDashes = airDashes,
	}
end

-- Sprint, jumps, dodge/dash, velocity and walk speed. Returns the updated sense (after jumps and dodges).
function Locomotion.Step(character: Model, humanoid: Humanoid, root: BasePart, sense: Sense, input: any, act: ActionSim.Result, now: number, dt: number): Sense
	local grounded, dodging, dashing, busy = sense.Grounded, sense.Dodging, sense.Dashing, sense.Busy
	local jumpsUsed, airDashes = sense.JumpsUsed, sense.AirDashes
	local locked = act.Stunned or (act.Acting and not act.CanDodge)
	local look = Vector.Flat(root.CFrame.LookVector)

	-- Sprint: a toggle that ends after standing still briefly.
	local sprinting = character:GetAttribute(A.Sprinting) == true
	if input.Pressed.Sprint then
		sprinting = not sprinting
	end
	local stillSince = EntityState.Number(character, A.StillSince, -1)
	if sense.Moving then
		stillSince = -1
	elseif stillSince < 0 then
		stillSince = now
	end
	if stillSince >= 0 and now - stillSince >= Config.SprintStopDelay then
		sprinting = false
	end

	-- Jumps: tap = jump (on release), hold = charged high jump, in the air = air jump.
	local chargeStart = EntityState.Number(character, A.ChargeStart, -1)
	if input.Pressed.Jump and not busy and not locked then
		ActionSim.Cancel(character) -- jumping out of an action's recovery
		if grounded then
			chargeStart = now
		elseif jumpsUsed == 0 then
			launch(character, humanoid, root, Config.JumpVelocity, now, "ground") -- coyote time
			jumpsUsed = 1
		elseif jumpsUsed < Config.MaxJumps and Stamina.TrySpend(character, Config.AirJumpStaminaCost, now) then
			launch(character, humanoid, root, Config.AirJumpVelocity, now, "air")
			jumpsUsed += 1
		end
	end
	if chargeStart >= 0 then
		local heldFor = now - chargeStart
		if not grounded or busy or locked then
			chargeStart = -1
		elseif input.Released.Jump then
			local hj = Config.HighJump
			local high = heldFor >= hj.HoldThreshold
			local velocity = Config.JumpVelocity
			if high then
				local alpha = math.clamp((heldFor - hj.HoldThreshold) / (hj.FullCharge - hj.HoldThreshold), 0, 1)
				velocity = hj.MinVelocity + (hj.MaxVelocity - hj.MinVelocity) * alpha
			end
			launch(character, humanoid, root, velocity, now, if high then "high" else "ground")
			jumpsUsed, chargeStart, grounded = 1, -1, false
		end
	end
	local charging = chargeStart >= 0 and now - chargeStart >= Config.HighJump.HoldThreshold

	-- Dodge on the ground (no direction = backstep), air dash in the air.
	if input.Pressed.Dodge and not busy and not charging and not act.Stunned and (not act.Acting or act.CanDodge) then
		local direction = sense.MoveDirection
		-- Evasion cancel: dodging right as an action's recovery opens costs nothing.
		local evadeFrom = EntityState.Number(character, A.EvadeFreeFrom, -10)
		local free = now >= evadeFrom and now - evadeFrom <= StaminaConfig.EvasionCancelWindow
		if grounded then
			local d = Config.Dodge
			if free or Stamina.TrySpend(character, d.StaminaCost, now) then
				ActionSim.Cancel(character)
				local backstep = direction == Vector3.zero
				if backstep then
					direction = -look
				end
				set(character, A.DodgeBack, backstep)
				set(character, A.DodgeStart, now)
				set(character, A.DodgeEnd, now + d.Duration)
				set(character, A.DodgeDir, direction)
				set(character, A.IFrameFrom, now + d.IFrameFrom)
				set(character, A.IFrameTo, now + d.IFrameTo)
				chargeStart, dodging = -1, true
			end
		elseif airDashes < Config.AirDash.PerAirtime then
			if free or Stamina.TrySpend(character, Config.AirDash.StaminaCost, now) then
				ActionSim.Cancel(character)
				set(character, A.DashEnd, now + Config.AirDash.Duration)
				set(character, A.DashDir, if direction == Vector3.zero then look else direction)
				airDashes += 1
				dashing = true
			end
		end
	end

	-- Velocity
	local v = root.AssemblyLinearVelocity
	local walkSpeed: number
	if dodging then
		local d = Config.Dodge
		local t = math.clamp((now - EntityState.Number(character, A.DodgeStart, now)) / d.Duration, 0, 1)
		local speed = d.StartSpeed + (d.EndSpeed - d.StartSpeed) * t
		local direction = character:GetAttribute(A.DodgeDir) :: Vector3
		humanoid:Move(direction, false) -- steer the humanoid along the dodge so its walk controller doesn't brake it
		root.AssemblyLinearVelocity = Vector3.new(direction.X * speed, v.Y, direction.Z * speed)
		walkSpeed = speed
	else
		if dashing then
			root.AssemblyLinearVelocity = (character:GetAttribute(A.DashDir) :: Vector3) * Config.AirDash.Speed
		elseif act.Lunge then
			humanoid:Move(act.Lunge.Unit, false)
			root.AssemblyLinearVelocity = Vector3.new(act.Lunge.X, v.Y, act.Lunge.Z)
		elseif not grounded and v.Y < 0 then
			local extra = (Config.FallGravityMultiplier - 1) * GRAVITY * dt
			root.AssemblyLinearVelocity = Vector3.new(v.X, math.max(v.Y - extra, -Config.MaxFallSpeed), v.Z)
		end
		walkSpeed = act.WalkSpeed
			or (if charging then Config.ChargeWalkSpeed elseif sprinting then Config.SprintSpeed else Config.WalkSpeed)
	end
	if humanoid.WalkSpeed ~= walkSpeed then
		humanoid.WalkSpeed = walkSpeed
	end

	set(character, A.WasGrounded, grounded)
	set(character, A.JumpsUsed, jumpsUsed)
	set(character, A.AirDashesUsed, airDashes)
	set(character, A.Sprinting, sprinting)
	set(character, A.StillSince, stillSince)
	set(character, A.ChargeStart, chargeStart)
	set(character, A.Charging, charging)

	return {
		Grounded = grounded,
		Dodging = dodging,
		Dashing = dashing,
		Busy = dodging or dashing,
		Charging = charging,
		MoveDirection = sense.MoveDirection,
		Moving = sense.Moving,
		JumpsUsed = jumpsUsed,
		AirDashes = airDashes,
	}
end

return Locomotion

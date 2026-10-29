--!strict
-- Input: the gameplay InputContext, read inside the simulation.
--   Bind (outside the simulation) caches a player's InputAction instances.
--   Read (inside) returns this step's buttons with presses and releases. Each button's previous state lives in
--   an attribute, so edges survive rollback and resimulation.
--   Feed (client, inside) pushes the two script-driven actions: Face (lock-on facing) and Aim (crosshair or
--   lock-on target). Providers are registered by the client's lock-on code.

local RunService = game:GetService("RunService")

local EntityState = require(script.Parent.EntityState)

local A = EntityState.Attr

local BUTTONS = { "Jump", "Dodge", "Sprint", "Attack", "Guard", "Strong", "Ranged", "Bite", "Skill1", "Skill2" }

-- Buttons whose presses/releases matter, and the attribute that remembers their last state.
local EDGES: { [string]: string } = {
	Jump = A.HeldJump,
	Dodge = A.HeldDodge,
	Sprint = A.HeldSprint,
	Attack = A.HeldAttack,
	Strong = A.HeldStrong,
	Ranged = A.HeldRanged,
	Bite = A.HeldBite,
	Skill1 = A.HeldSkill1,
	Skill2 = A.HeldSkill2,
}

export type Handles = {
	Actions: { [string]: any },
	FaceBinding: any,
	AimBinding: any,
}

export type Snapshot = {
	Down: { [string]: boolean },
	Pressed: { [string]: boolean },
	Released: { [string]: boolean },
	Face: Vector3?, -- flat direction to face while locked on
	Aim: Vector3?, -- unit aim direction
}

local Input = {}

local facingProvider: (() -> Vector3?)? = nil
local aimProvider: (() -> Vector3?)? = nil

-- Outside the simulation: waits for and caches the context's actions.
function Input.Bind(context: Instance): Handles
	local actions = {}
	for _, name in BUTTONS do
		actions[name] = context:WaitForChild(name)
	end
	actions.Face = context:WaitForChild("Face")
	actions.Aim = context:WaitForChild("Aim")
	return {
		Actions = actions,
		FaceBinding = actions.Face:WaitForChild("Script"),
		AimBinding = actions.Aim:WaitForChild("Script"),
	}
end

-- Inside the simulation: this step's input for one character.
function Input.Read(handles: Handles, character: Model): Snapshot
	local down, pressed, released = {}, {}, {}
	for _, name in BUTTONS do
		local isDown = handles.Actions[name]:GetState() == true
		down[name] = isDown
		local attribute = EDGES[name]
		if attribute then
			local was = character:GetAttribute(attribute) == true
			pressed[name] = isDown and not was
			released[name] = was and not isDown
			if was ~= isDown then
				character:SetAttribute(attribute, isDown)
			end
		end
	end
	local face = handles.Actions.Face:GetState()
	local aim = handles.Actions.Aim:GetState()
	return {
		Down = down,
		Pressed = pressed,
		Released = released,
		Face = if typeof(face) == "Vector2" and face.Magnitude > 0.01 then Vector3.new(face.X, 0, face.Y).Unit else nil,
		Aim = if typeof(aim) == "Vector3" and aim.Magnitude > 0.5 then aim.Unit else nil,
	}
end

-- Client only: flat direction the character should face (lock-on), or nil for normal turning.
function Input.SetFacingProvider(provider: () -> Vector3?)
	assert(RunService:IsClient(), "SetFacingProvider is client-only")
	facingProvider = provider
end

-- Client only: unit aim direction (crosshair or lock-on target).
function Input.SetAimProvider(provider: () -> Vector3?)
	assert(RunService:IsClient(), "SetAimProvider is client-only")
	aimProvider = provider
end

-- Client only, inside the simulation, before the local character is stepped.
function Input.Feed(handles: Handles)
	if facingProvider then
		local direction = facingProvider()
		handles.FaceBinding:Fire(if direction then Vector2.new(direction.X, direction.Z) else Vector2.zero)
	end
	if aimProvider then
		handles.AimBinding:Fire(aimProvider() or Vector3.zero)
	end
end

return Input

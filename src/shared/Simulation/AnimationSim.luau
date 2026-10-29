--!strict
-- AnimationSim: plays animations from simulation state, inside the simulation (called by Runner), so they roll
-- back with the state they show. Tracks are never cached across steps: each step looks up the live track.
-- Each class can override any animation (Config.Animations.Classes); everything else uses Default.
-- Budget: Server Authority allows 8 playing tracks per Animator. The default Animate script uses up to 2; this
-- module plays at most 2 at once (one loop + one one-shot).

local RunService = game:GetService("RunService")

local Shared = script.Parent.Parent
local Config = require(Shared.Config.Animations)
local Registry = require(Shared.Definitions.Registry)
local EntityState = require(script.Parent.EntityState)

local A = EntityState.Attr
local num = EntityState.Number

local FADE_FAST = 0.06
local FADE_LOOP = 0.15

-- Animation instances, created once outside the simulation: sets[setName][clipName].
local sets: { [string]: { [string]: Animation } } = {}

local function build(setName: string, ids: { [string]: string })
	local set = {}
	for name, id in ids do
		if not string.find(id, "^rbxassetid://%d+$") then
			if RunService:IsServer() then
				warn(`[BL] AnimationSim: {setName}.{name} isn't published yet; it won't play`)
			end
			continue
		end
		local animation = Instance.new("Animation")
		animation.Name = name
		animation.AnimationId = id
		set[name] = animation
	end
	sets[setName] = set
end
build("Default", Config.Default)
for classId, overrides in Config.Classes do
	build(classId, overrides)
end

local AnimationSim = {}

-- Every clip name an action uses (weapons and common actions).
local ACTION_CLIPS: { string } = {}
for _, action in Registry.AllActions() do
	if not table.find(ACTION_CLIPS, action.Anim) then
		table.insert(ACTION_CLIPS, action.Anim)
	end
end

local function resolve(classId: string?, name: string): Animation?
	local classSet = if classId then sets[classId] else nil
	return (classSet and classSet[name]) or sets.Default[name]
end

local function sync(animator: Animator, animation: Animation?, wanted: boolean, startedAt: number?, now: number, fade: number)
	if not animation then
		return
	end
	local track = animator:GetTrackByAnimationId(animation.AnimationId)
	if wanted then
		if not track then
			track = animator:LoadAnimation(animation)
			track:Play(fade)
			local into = if startedAt then now - startedAt else 0
			if into > 0.03 then
				track.TimePosition = into
			end
		end
	elseif track then
		track:Stop(fade)
	end
end

-- Windows end just before each clip does, so a finished one-shot is never replayed.
function AnimationSim.Step(animator: Animator, character: Model, now: number, grounded: boolean, moving: boolean)
	local classId = character:GetAttribute(A.ClassId)
	local function play(name: string, wanted: boolean, startedAt: number?, fade: number)
		sync(animator, resolve(classId, name), wanted, startedAt, now, fade)
	end

	local launchAt, kind = num(character, A.LaunchAt, -10), character:GetAttribute(A.LaunchKind)
	local dodgeStart = num(character, A.DodgeStart, 0)
	local dodging = now < num(character, A.DodgeEnd, 0)
	local back = character:GetAttribute(A.DodgeBack) == true
	local dashEnd = num(character, A.DashEnd, 0)
	local landAt = num(character, A.LandAt, -10)
	local _, action, actionStart = EntityState.CurrentAction(character)

	play("ChargeCrouch", character:GetAttribute(A.Charging) == true, nil, FADE_LOOP)
	play("HighJumpLaunch", kind == "high" and now - launchAt < 0.46, launchAt, FADE_FAST)
	play("AirFlip", kind == "air" and now - launchAt < 0.33, launchAt, FADE_FAST)
	play("AirDash", now < dashEnd + 0.09, dashEnd - 0.18, FADE_FAST)
	play("Dodge", dodging and not back, dodgeStart, FADE_FAST)
	play("Backstep", dodging and back, dodgeStart, FADE_FAST)
	play("Land", grounded and now - landAt < 0.3, landAt, FADE_FAST)
	for _, clip in ACTION_CLIPS do
		play(clip, action ~= nil and action.Anim == clip, actionStart, FADE_FAST)
	end
	play("Sprint", character:GetAttribute(A.Sprinting) == true and moving and grounded and not dodging and action == nil, nil, FADE_LOOP)
end

return AnimationSim

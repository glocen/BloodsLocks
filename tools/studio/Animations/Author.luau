--!strict
-- Author: R6 KeyframeSequences, saved where the Animation Editor finds them (ServerStorage.RBX_ANIMSAVES.R6) and
-- published for the game. Two sources:
--   - clips animated in Blender (tools/blender/r6anim.py), baked to one pose per frame and copied to
--     build/import/Anim_<Name>.txt, which Rojo syncs to ServerStorage.BL_Import. SaveBaked turns one into BL_<Name>.
--   - body-space kits (Animations/<Kit>), the older clips not yet redone in Blender. Save turns their clips into BL_<Name>.
-- Studio, Edit mode, MCP execute_luau:
--   local Author = require(game.ServerStorage.BL_Tools.Animations.Author:Clone())
--   Author.SaveBaked("BiteHold") -- (re)writes BL_BiteHold from BL_Import.Anim_BiteHold
--   local kit = require(game.ServerStorage.BL_Tools.Animations.Gustave:Clone())
--   Author.Save(kit, { "SMGBurst" }) -- (re)writes BL_SMGBurst
--   local id = Author.Publish("Gustave", "SMGBurst") -- yields; the id goes into Shared.Config.Animations
-- Kit angles are degrees in body space, converted through the rig's own joint bases (workspace.R6). Positive X raises an
-- arm forward and leans the torso or head forward (their pitch sign is flipped here so all parts read alike). The
-- optional 4th to 6th numbers move the part, in studs.

local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

export type Pose = { number }
export type Frame = { number | { [string]: Pose } | { string }? }
export type Clip = { Legs: number?, Frames: { Frame } }
export type Kit = { Character: string, Idle: { [string]: Pose }, Clips: { [string]: Clip } }

local PARTS = { "Torso", "Head", "Right Arm", "Left Arm", "Right Leg", "Left Leg" }
local LEGS = { ["Right Leg"] = true, ["Left Leg"] = true }
local LEANS = { Torso = true, Head = true } -- pitch flips on these: their bases face the other way from an arm's

local Author = {}

local function saves(): Instance
	return ServerStorage:WaitForChild("RBX_ANIMSAVES"):WaitForChild("R6")
end

local function bases(): { [string]: CFrame }
	local result = {}
	for _, motor in workspace:WaitForChild("R6"):GetDescendants() do
		if motor:IsA("Motor6D") and motor.Part1 then
			result[motor.Part1.Name] = motor.C0.Rotation
		end
	end
	return result
end

local function sequence(kit: Kit, name: string, clip: Clip, basis: { [string]: CFrame }): KeyframeSequence
	local seq = Instance.new("KeyframeSequence")
	seq.Name = "BL_" .. name
	seq.Priority = Enum.AnimationPriority.Action2
	seq.Loop = false
	seq:SetAttribute("Character", kit.Character)
	seq:SetAttribute("Source", "tools/studio/Animations/" .. kit.Character)
	for _, frame in clip.Frames do
		local time, body, markers = frame[1] :: number, frame[2] :: { [string]: Pose }, frame[3] :: { string }?
		local keyframe = Instance.new("Keyframe")
		keyframe.Name = "Pose"
		keyframe.Time = time
		keyframe.Parent = seq
		local root = Instance.new("Pose")
		root.Name = "HumanoidRootPart"
		root.Weight = 0
		root.Parent = keyframe
		local torsoPose = Instance.new("Pose")
		for _, part in PARTS do
			local pose = if part == "Torso" then torsoPose else Instance.new("Pose")
			pose.Name = part
			pose.Parent = if part == "Torso" then root else torsoPose
			local data = body[part] or kit.Idle[part] or { 0, 0, 0 }
			local turn = CFrame.Angles(math.rad(if LEANS[part] then -data[1] else data[1]), math.rad(data[2]), math.rad(data[3]))
			local move = CFrame.new(data[4] or 0, data[5] or 0, data[6] or 0)
			local b = basis[part] or CFrame.identity
			pose.CFrame = b:Inverse() * (move * turn) * b
			pose.Weight = if LEGS[part] then (clip.Legs or 1) else 1
			pose.EasingStyle = Enum.PoseEasingStyle.CubicV2
			pose.EasingDirection = Enum.PoseEasingDirection.InOut
		end
		for _, marker in markers or {} do
			local m = Instance.new("KeyframeMarker")
			m.Name = marker
			m.Parent = keyframe
		end
	end
	return seq
end

-- Writes the named clips (all when `names` is nil) into RBX_ANIMSAVES.R6, replacing earlier versions.
function Author.Save(kit: Kit, names: { string }?): { string }
	local basis = bases()
	local folder = saves()
	local written = {}
	for name, clip in kit.Clips do
		if names == nil or table.find(names, name) then
			local old = folder:FindFirstChild("BL_" .. name)
			if old then
				old:Destroy()
			end
			sequence(kit, name, clip, basis).Parent = folder
			table.insert(written, name)
		end
	end
	return written
end

-- A clip baked in Blender (tools/blender/r6anim.py), from BL_Import.Anim_<name>: JSON with the clip's Character, its
-- Legs weight, Frames ({ T, Poses = { [part] = the Motor6D Transform's 12 CFrame components } }, one per frame, so
-- they're joined linearly) and Markers ({ T, Name }). Writes BL_<name> into RBX_ANIMSAVES.R6, replacing an earlier one.
function Author.SaveBaked(name: string): KeyframeSequence
	local source = ServerStorage:WaitForChild("BL_Import"):FindFirstChild("Anim_" .. name)
	assert(source and source:IsA("StringValue"), `BL_Import.Anim_{name} is missing: copy the baked JSON to build/import`)
	local clip = HttpService:JSONDecode(source.Value)
	local seq = Instance.new("KeyframeSequence")
	seq.Name = "BL_" .. name
	seq.Priority = Enum.AnimationPriority.Action2
	seq.Loop = false
	seq:SetAttribute("Character", clip.Character)
	seq:SetAttribute("Source", clip.Source)
	local keyframes: { Keyframe } = {}
	for _, frame in clip.Frames do
		local keyframe = Instance.new("Keyframe")
		keyframe.Name = "Pose"
		keyframe.Time = frame.T
		keyframe.Parent = seq
		table.insert(keyframes, keyframe)
		local root = Instance.new("Pose")
		root.Name = "HumanoidRootPart"
		root.Weight = 0
		root.Parent = keyframe
		local torsoPose = Instance.new("Pose")
		for _, part in PARTS do
			local pose = if part == "Torso" then torsoPose else Instance.new("Pose")
			pose.Name = part
			pose.Parent = if part == "Torso" then root else torsoPose
			pose.CFrame = CFrame.new(table.unpack(frame.Poses[part]))
			pose.Weight = if LEGS[part] then (clip.Legs or 1) else 1
			pose.EasingStyle = Enum.PoseEasingStyle.Linear
		end
	end
	for _, marker in clip.Markers or {} do
		local nearest = keyframes[1]
		for _, keyframe in keyframes do
			if math.abs(keyframe.Time - marker.T) < math.abs(nearest.Time - marker.T) then
				nearest = keyframe
			end
		end
		local m = Instance.new("KeyframeMarker")
		m.Name = marker.Name
		m.Parent = nearest
	end
	local folder = saves()
	local old = folder:FindFirstChild(seq.Name)
	if old then
		old:Destroy()
	end
	seq.Parent = folder
	return seq
end

-- Publishes a saved clip as an Animation asset; returns its id. Yields.
function Author.Publish(character: string, name: string): number
	local seq = saves():FindFirstChild("BL_" .. name)
	assert(seq and seq:IsA("KeyframeSequence"), `BL_{name} isn't saved; run Author.Save or Author.SaveBaked first`)
	local source = seq:GetAttribute("Source") or `tools/studio/Animations/{character}`
	local result, id = AssetService:CreateAssetAsync(seq:Clone(), Enum.AssetType.Animation, {
		Name = `BL_{character}_{name}`,
		Description = `BloodsLocks: {character}'s {name} ({source}).`,
	})
	assert(result == Enum.CreateAssetResult.Success, `{name}: {result}`)
	return id
end

return Author

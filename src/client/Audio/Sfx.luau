--!strict
-- Sfx (client): plays sound cues (Definitions/Sounds) as regions of the one uploaded combat sound sheet
-- (Definitions/SoundSheet), in 3D: at a point, or on a part or attachment so the sound follows it. Each play picks
-- its own pitch from the cue's range. Silent (one warning in Studio) until the sheet's upload Id is filled in.

local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Registry = require(ReplicatedStorage.Shared.Definitions.Registry)

local GROUP = "BL_Combat" -- the SoundGroup every combat cue plays through (one fader for the whole mix)
local FULL_VOLUME_WITHIN = 6 -- studs: no fall-off this close
local TAIL = 0.15 -- seconds a finished one-shot lingers before it's removed

local sounds = Registry.Sounds()
local sheet = Registry.SoundSheet()
local random = Random.new()
local group: SoundGroup? = nil
local warned = false

local Sfx = {}

local function ready(): boolean
	if sheet.Id ~= "" then
		return true
	end
	if RunService:IsStudio() and not warned then
		warned = true
		warn("[BL] Sfx: the combat sound sheet isn't uploaded yet (Definitions/SoundSheet.Id), so cues are silent")
	end
	return false
end

local function soundGroup(): SoundGroup
	if not group then
		local existing = SoundService:FindFirstChild(GROUP)
		group = if existing and existing:IsA("SoundGroup") then existing else Instance.new("SoundGroup")
		assert(group)
		group.Name = GROUP
		group.Parent = SoundService
	end
	return group :: SoundGroup
end

local function make(cueName: string, parent: Instance): (Sound, number)
	local cue = sounds.Cues[cueName]
	local region = sheet.Regions[cueName]
	assert(cue and region, `Sfx: unknown cue {cueName}`)
	local sound = Instance.new("Sound")
	sound.Name = cueName
	sound.SoundId = sheet.Id
	sound.PlaybackRegionsEnabled = true
	sound.PlaybackRegion = NumberRange.new(region.From, region.To)
	sound.Volume = cue.Volume
	sound.PlaybackSpeed = random:NextNumber(cue.Pitch[1], cue.Pitch[2])
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = FULL_VOLUME_WITHIN
	sound.RollOffMaxDistance = cue.Range
	sound.SoundGroup = soundGroup()
	sound.Parent = parent
	return sound, (region.To - region.From) / sound.PlaybackSpeed
end

-- A point emitter: an attachment on Terrain, removed after `life` seconds.
local function pointAt(position: Vector3, life: number): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Name = "BL_Sfx"
	attachment.WorldPosition = position
	attachment.Parent = workspace.Terrain
	Debris:AddItem(attachment, life)
	return attachment
end

-- Plays a cue once at a point, or on a part or attachment (it follows it), after `delay` seconds.
function Sfx.Play(cueName: string, at: Vector3 | Instance, delay: number?)
	if not ready() then
		return
	end
	local function play()
		local region = sheet.Regions[cueName]
		local life = (region.To - region.From) / sounds.Cues[cueName].Pitch[1] + TAIL
		local parent = if typeof(at) == "Vector3" then pointAt(at, life) else at
		if typeof(parent) == "Instance" and not parent:IsDescendantOf(workspace) then
			return -- what it was meant to follow is gone
		end
		local sound, length = make(cueName, parent :: Instance)
		sound:Play()
		Debris:AddItem(sound, length + TAIL)
	end
	if delay and delay > 0 then
		task.delay(delay, play)
	else
		play()
	end
end

-- Starts a looping cue on a part or attachment; stop it with Sfx.Stop. Nil while the sheet is silent.
function Sfx.Loop(cueName: string, on: Instance): Sound?
	if not ready() then
		return nil
	end
	local region = sheet.Regions[cueName]
	local sound = make(cueName, on)
	sound.Looped = true
	sound.LoopRegion = NumberRange.new(region.From, region.To)
	sound:Play()
	return sound
end

-- Fades a sound out over `fade` seconds, then removes it.
function Sfx.Stop(sound: Sound?, fade: number)
	if not sound then
		return
	end
	TweenService:Create(sound, TweenInfo.new(fade), { Volume = 0 }):Play()
	Debris:AddItem(sound, fade + 0.05)
end

-- Loads the sheet ahead of the first fight, so the first cues aren't late.
function Sfx.Preload()
	if not ready() then
		return
	end
	local probe = Instance.new("Sound")
	probe.SoundId = sheet.Id
	task.spawn(function()
		ContentProvider:PreloadAsync({ probe })
		probe:Destroy()
	end)
end

return Sfx

--!strict
-- Sfx (client): plays sound cues (Definitions/Sounds) in 3D: at a point, or on a part or attachment so the sound
-- follows it. A cue is a slice of a sound from Roblox's audio library (its Id, From and To). Each play picks its own
-- pitch from the cue's range. A slice carries its measured loudness (Level, tools/studio/Audio/Waveform), so every cue
-- plays at the same base level and its Volume is purely the mix. In Studio, the audition panel can swap a cue's sound
-- for the session (Sfx.Audition) and preview slices flat.

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
local REFERENCE_LEVEL = -14 -- dBFS: a slice measured at this loudness plays at its cue's Volume as written
local GAIN_MIN, GAIN_MAX = 0.25, 4 -- how far levelling may turn a slice down or up
local PREVIEW_VOLUME = 0.8 -- the audition panel's flat previews

-- Where a cue's sound is: its asset, the slice of it that plays (seconds), where it peaks inside the slice and how
-- loud it measured (library slices).
export type Source = { Id: string, From: number, To: number, Peak: number?, Level: number? }

local sounds = Registry.Sounds()
local random = Random.new()
local group: SoundGroup? = nil
local auditions: { [string]: Source } = {} -- Studio only: cues whose sound the audition panel swapped

local Sfx = {}

local function source(cueName: string): Source
	return auditions[cueName] or sounds.Cues[cueName]
end

-- The gain that brings a slice to the reference loudness (1 for sounds with no measurement).
local function gain(from: Source): number
	if not from.Level then
		return 1
	end
	return math.clamp(10 ^ ((REFERENCE_LEVEL - from.Level) / 20), GAIN_MIN, GAIN_MAX)
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
	assert(cue, `Sfx: unknown cue {cueName}`)
	local from = source(cueName)
	local sound = Instance.new("Sound")
	sound.Name = cueName
	sound.SoundId = from.Id
	sound.PlaybackRegionsEnabled = true
	sound.PlaybackRegion = NumberRange.new(from.From, from.To)
	sound.Volume = cue.Volume * gain(from)
	sound.PlaybackSpeed = random:NextNumber(cue.Pitch[1], cue.Pitch[2])
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = FULL_VOLUME_WITHIN
	sound.RollOffMaxDistance = cue.Range
	sound.SoundGroup = soundGroup()
	sound.Parent = parent
	return sound, (from.To - from.From) / sound.PlaybackSpeed
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
	local function play()
		local from = source(cueName)
		local life = (from.To - from.From) / sounds.Cues[cueName].Pitch[1] + TAIL
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

-- Starts a looping cue on a part or attachment; stop it with Sfx.Stop.
function Sfx.Loop(cueName: string, on: Instance): Sound
	local from = source(cueName)
	local sound = make(cueName, on)
	sound.Looped = true
	sound.LoopRegion = NumberRange.new(from.From, from.To)
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

-- Where a cue's sound is loudest, seconds into its slice (a swing's whoosh is timed by it); nil if unmeasured.
function Sfx.Peak(cueName: string): number?
	return source(cueName).Peak
end

-- Studio only: plays `from` for this cue for the rest of the session (nil restores the cue's own sound), so the
-- owner can judge a candidate in a fight (Controllers/Core/AuditionController).
function Sfx.Audition(cueName: string, from: Source?)
	assert(RunService:IsStudio(), "Sfx.Audition is a Studio tool")
	assert(sounds.Cues[cueName], `Sfx: unknown cue {cueName}`)
	auditions[cueName] = from
end

-- Plays a slice flat (not in 3D), levelled like a cue: the audition panel's previews. Returns the sound.
function Sfx.Preview(from: Source): Sound
	local sound = Instance.new("Sound")
	sound.Name = "BL_SfxPreview"
	sound.SoundId = from.Id
	sound.PlaybackRegionsEnabled = true
	sound.PlaybackRegion = NumberRange.new(from.From, from.To)
	sound.Volume = PREVIEW_VOLUME * gain(from)
	sound.SoundGroup = soundGroup()
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, from.To - from.From + TAIL)
	return sound
end

-- Loads every cue's sound ahead of the first fight, so the first cues aren't late.
function Sfx.Preload()
	local ids: { [string]: boolean } = {}
	for name in sounds.Cues do
		ids[source(name).Id] = true
	end
	local probes = {}
	for id in ids do
		local probe = Instance.new("Sound")
		probe.SoundId = id
		table.insert(probes, probe)
	end
	task.spawn(function()
		ContentProvider:PreloadAsync(probes)
		for _, probe in probes do
			probe:Destroy()
		end
	end)
end

return Sfx

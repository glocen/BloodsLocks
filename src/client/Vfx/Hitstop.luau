--!strict
-- Hitstop (client): a landed melee hit freezes the attacker's and the target's animations for a few hundredths of a
-- second (Config.Combat.Hitstop), so the blow reads as heavy. Presentation only: it pauses the local playback of the
-- tracks and never touches the simulation. A model that's already frozen isn't frozen again, so hits can't stack it.

local Hitstop = {}

local frozenUntil: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any

local function playingTracks(model: Model): { AnimationTrack }
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	return if animator then animator:GetPlayingAnimationTracks() else {}
end

-- Freezes each model's playing animations for `seconds`, then lets them run on at their own speed.
function Hitstop.Play(models: { Model }, seconds: number)
	local now = os.clock()
	for _, model in models do
		if (frozenUntil[model] or 0) > now then
			continue
		end
		frozenUntil[model] = now + seconds
		local held: { [AnimationTrack]: number } = {}
		for _, track in playingTracks(model) do
			held[track] = track.Speed
			track:AdjustSpeed(0)
		end
		task.delay(seconds, function()
			for track, speed in held do
				if track.IsPlaying then
					track:AdjustSpeed(speed)
				end
			end
		end)
	end
end

return Hitstop

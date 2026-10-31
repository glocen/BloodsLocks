--!strict
-- BiteWind: the bite's dark smoke and wind (owner, 2026-10-31: "just the animation, and a wind effect with dark smoke
-- instead of blood"), timed to the hold (Simulation/Bite). CombatFxController drives it every frame from the hold's
-- clock, so a late joiner or a hold that breaks shows right. No blood, ever (AGENTS.md rule 4). From our drawn textures
-- (tools/blender/vfx_sprites.py). Its beats, at the hold's times (Bite.Timeline):
--   Seize:   dark smoke wisps and pale wind streaks rush in to the pair, pale motes drifting in with them.
--   Fangs:   a dark puff bursts at the bite, wind streaks flick out and a cold flash lights both faces; two smoke ribbons
--            and a wind line start a slow orbit round the upper bodies that rises through the drain.
--   Pulse:   at each drain pulse, cold-white motes stream from the victim's neck into the biter and rise round it, with a
--            soft cold glow: the life it drinks.
--   Release: the orbit gives way to three smoke ribbons sweeping wide round both bodies; a ring of wind runs out along
--            the ground, dark smoke is driven outward and streaks fly off, then the smoke settles and fades.
-- A hold that breaks stops its orbit and never releases.
--   Begin(biter, victim, elapsed) -> Hold; Update(hold, elapsed) -> the beats that fired; Finish(hold).

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Parent.UI.Theme)
local Parts = require(ReplicatedStorage.Shared.Util.Parts)
local Raycast = require(ReplicatedStorage.Shared.Util.Raycast)
local Bite = require(ReplicatedStorage.Shared.Simulation.Bite)

local T = Kit.Textures
local V = Theme.Vfx
local TIMELINE = Bite.Timeline

local AHEAD = 1 -- studs in front of the biter: the pair's middle when the victim isn't known
local GROUND_PROBE = 8 -- studs below the pair's middle the ground is looked for
local FALLBACK_DROP = 3 -- studs from a root to the ground when nothing is found
local RIBBON_WIDTH, LINE_WIDTH = 1.1, 0.16 -- studs across a smoke ribbon / a wind line
local LINE_OUT, LINE_LAG = 0.35, 0.3 -- a wind line rides this far outside its ribbon, this far behind it (radians)
local PULL_RADIUS = 3.6 -- studs: where the pulled-in wisps start
local LATE = 0.3 -- seconds: a beat this far behind the clock when a hold is first seen (a late joiner) is skipped
local GUST_DIRECTIONS = 8

type Orbit = {
	Strands: number, Smoke: boolean, Time: number, Turns: number,
	Radius: { number }, Height: { number }, -- from / to: studs from the centre, studs above the ground
	LineWidth: number?, -- its wind lines' width (studs), else LINE_WIDTH
}

-- Through the drain: smoke ribbons and a wind line circling the upper bodies slowly, rising past the heads (low down,
-- dark smoke against a dark floor reads as nothing: tested 2026-10-31).
local DRAIN: Orbit = {
	Strands = 2, Smoke = true, Time = TIMELINE.Release - TIMELINE.Fangs, Turns = 1.6,
	Radius = { 1.7, 1.45 }, Height = { 2.6, 4.2 }, LineWidth = 0.24,
}
local FANGS_LIGHT = { Brightness = 2.2, Range = 9, Time = 0.25 } -- a cold flash at the bite, lighting both faces
local PULSE_LIGHT = { Brightness = 0.9, Range = 7, Time = 0.3 } -- a soft cold glow on each drain pulse
-- At the release: smoke ribbons sweeping wide at chest height.
local SWEEP: Orbit = { Strands = 3, Smoke = true, Time = 0.42, Turns = 0.95, Radius = { 1.8, 3.4 }, Height = { 2.1, 3.3 } }

export type Hold = { Biter: Model, Victim: Model?, Next: number, Stop: (() -> ())? }

-- The hold's beats in order, each at its time from the seize.
local BEATS: { { Name: string, At: number } } = { { Name = "Seize", At = 0 }, { Name = "Fangs", At = TIMELINE.Fangs } }
for pulse = 0, TIMELINE.Pulses - 1 do
	table.insert(BEATS, { Name = "Pulse", At = TIMELINE.FirstPulse + pulse * TIMELINE.PulseEvery })
end
table.insert(BEATS, { Name = "Release", At = TIMELINE.Release })

local BiteWind = {}

task.spawn(function()
	ContentProvider:PreloadAsync({ T.SmokeRibbon, T.WindLine, T.WindRing, T.WindStreak, T.SmokePuff, T.SoftGlow })
end)

local function ease(alpha: number): number
	return 1 - (1 - alpha) ^ 2
end

local function ground(from: Vector3, ignore: { Instance }): Vector3
	local hit = workspace:Raycast(from, Vector3.new(0, -GROUND_PROBE, 0), Raycast.Exclude(ignore, true))
	return if hit then hit.Position else from - Vector3.new(0, FALLBACK_DROP, 0)
end

local function attachment(parent: BasePart): Attachment
	local a = Instance.new("Attachment")
	a.Parent = parent
	return a
end

local function trail(from: Attachment, to: Attachment, props: { [string]: any }): Trail
	local t = Instance.new("Trail")
	t.Attachment0, t.Attachment1 = from, to
	t.FaceCamera = true
	t.TextureMode = Enum.TextureMode.Stretch
	t.MinLength = 0.05
	for key, value in props do
		(t :: any)[key] = value
	end
	t.Parent = from.Parent
	return t
end

-- Where the pair stands: the middle between the two bodies at chest height, and the ground under it.
local function places(hold: Hold): (Vector3, Vector3)
	local biterRoot = Parts.Root(hold.Biter)
	local victimRoot = Parts.Root(hold.Victim)
	local middle: Vector3
	if biterRoot and victimRoot then
		middle = (biterRoot.Position + victimRoot.Position) / 2
	elseif biterRoot then
		local look = biterRoot.CFrame.LookVector * Vector3.new(1, 0, 1)
		middle = biterRoot.Position + (if look.Magnitude > 1e-3 then look.Unit else Vector3.zAxis) * AHEAD
	else
		middle = Vector3.zero
	end
	local ignore: { Instance } = { hold.Biter }
	if hold.Victim then
		table.insert(ignore, hold.Victim)
	end
	return middle, ground(middle, ignore)
end

-- A point on a body: its part's position, or the fallback when it isn't there.
local function partAt(model: Model?, name: string, offset: Vector3, fallback: Vector3): Vector3
	local part = model and model:FindFirstChild(name)
	return if part and part:IsA("BasePart") then part.CFrame:PointToWorldSpace(offset) else fallback
end

-- Smoke, wind and pale motes rushing in to the pair.
local function pull(centre: Vector3)
	local inward = {
		Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
	}
	local function from(spec: Kit.Spec): Kit.Spec
		for key, value in inward do
			spec[key] = value
		end
		return spec
	end
	Kit.Burst(CFrame.new(centre), {
		from({
			Count = 10,
			Texture = T.SmokePuff,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
			FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
			Color = Kit.Colors(V.WindSmoke, V.WindSmokeDeep),
			LightInfluence = 0.6,
			Transparency = Kit.Seq({ { 0, 1 }, { 0.25, 0.35 }, { 1, 1 } }),
			Size = Kit.Seq({ { 0, 1.4 }, { 1, 0.5 } }),
			Lifetime = NumberRange.new(0.2, 0.26),
			Speed = NumberRange.new(13, 17),
			Rotation = NumberRange.new(0, 360),
		}),
		from({
			Count = 14,
			Texture = T.WindStreak,
			Orientation = Enum.ParticleOrientation.VelocityParallel,
			Color = ColorSequence.new(V.Wind),
			LightEmission = 0.4,
			LightInfluence = 0.3,
			Transparency = Kit.Seq({ { 0, 0.15 }, { 1, 1 } }),
			Size = Kit.Seq({ { 0, 1.3 }, { 1, 0.4 } }),
			Lifetime = NumberRange.new(0.14, 0.2),
			Speed = NumberRange.new(18, 24),
		}),
		from({ -- pale motes drifting in slowly
			Count = 12,
			Texture = T.SoftGlow,
			Color = ColorSequence.new(V.Wind),
			LightEmission = 0.6,
			LightInfluence = 0.2,
			Transparency = Kit.Seq({ { 0, 1 }, { 0.2, 0.2 }, { 1, 1 } }),
			Size = Kit.Seq({ { 0, 0.18 }, { 1, 0.08 } }),
			Lifetime = NumberRange.new(0.4, 0.6),
			Speed = NumberRange.new(3, 5),
			Drag = 2,
		}),
	}, Vector3.one * PULL_RADIUS * 2)
end

-- The bite itself: a tight dark puff where it lands, wind streaks flicking out from it.
local function fangs(at: Vector3)
	Kit.Burst(CFrame.new(at), {
		{
			Count = 3,
			Texture = T.SmokePuff,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
			FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
			Color = Kit.Colors(V.WindSmoke, V.WindSmokeDeep),
			LightInfluence = 0.6,
			Transparency = Kit.Seq({ { 0, 0.25 }, { 1, 1 } }),
			Size = Kit.Seq({ { 0, 0.5 }, { 1, 1.8 } }),
			Lifetime = NumberRange.new(0.35, 0.5),
			Speed = NumberRange.new(1.5, 3),
			SpreadAngle = Vector2.new(180, 180),
			Drag = 4,
			Rotation = NumberRange.new(0, 360),
		},
		{
			Count = 7,
			Texture = T.WindStreak,
			Orientation = Enum.ParticleOrientation.VelocityParallel,
			Color = ColorSequence.new(V.Wind),
			LightEmission = 0.4,
			LightInfluence = 0.3,
			Transparency = Kit.Seq({ { 0, 0.2 }, { 1, 1 } }),
			Size = Kit.Seq({ { 0, 0.9 }, { 1, 0.3 } }),
			Lifetime = NumberRange.new(0.12, 0.18),
			Speed = NumberRange.new(14, 20),
			SpreadAngle = Vector2.new(180, 180),
			Drag = 3,
		},
	})
end

-- A drain pulse: cold-white motes streaming from the victim's neck into the biter, and rising round it.
local function pulse(neck: Vector3, chest: Vector3)
	Kit.Burst(CFrame.lookAt(neck, chest), {
		{
			Count = 9,
			Texture = T.SoftGlow,
			Color = ColorSequence.new(V.Drain),
			LightEmission = 0.8,
			LightInfluence = 0.1,
			Transparency = Kit.Seq({ { 0, 0.6 }, { 0.3, 0.1 }, { 1, 1 } }),
			Size = Kit.Seq({ { 0, 0.22 }, { 1, 0.06 } }),
			Lifetime = NumberRange.new(0.3, 0.4),
			Speed = NumberRange.new(5, 7),
			EmissionDirection = Enum.NormalId.Front,
			SpreadAngle = Vector2.new(22, 22),
			Drag = 1,
		},
	})
	Kit.Burst(CFrame.new(chest), {
		{
			Count = 7,
			Texture = T.SoftGlow,
			Color = ColorSequence.new(V.Drain),
			LightEmission = 0.8,
			LightInfluence = 0.1,
			Transparency = Kit.Seq({ { 0, 1 }, { 0.25, 0.15 }, { 1, 1 } }),
			Size = Kit.Seq({ { 0, 0.16 }, { 1, 0.05 } }),
			Lifetime = NumberRange.new(0.6, 0.9),
			Speed = NumberRange.new(0.8, 1.6),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, 2.5, 0),
			Drag = 1.5,
		},
	}, Vector3.new(1.6, 1.6, 1.6))
end

-- Strands circling the pair: each a pale wind line, with a dark smoke ribbon ahead of it when `orbit.Smoke`. Returns
-- a function that ends the orbit early (its trails fade where they are).
local function circle(centre: Vector3, orbit: Orbit): () -> ()
	local anchor = Kit.Anchor(CFrame.new(centre))
	local stopped = false
	local strands = {}
	for i = 1, orbit.Strands do
		local strand = { Phase = (i - 1) / orbit.Strands * 2 * math.pi + math.random() * 0.4, Smoke = nil :: { Attachment }?, Line = {} :: { Attachment } }
		if orbit.Smoke then
			local smoke = { attachment(anchor), attachment(anchor) }
			trail(smoke[1], smoke[2], {
				Texture = T.SmokeRibbon,
				Color = Kit.Colors(V.WindSmoke, V.WindSmokeDeep),
				Transparency = Kit.Seq({ { 0, 0.15 }, { 1, 1 } }),
				WidthScale = Kit.Seq({ { 0, 1 }, { 1, 0.45 } }),
				LightEmission = 0,
				LightInfluence = 0.6,
				Lifetime = 0.42,
			})
			strand.Smoke = smoke
		end
		strand.Line = { attachment(anchor), attachment(anchor) }
		trail(strand.Line[1], strand.Line[2], {
			Texture = T.WindLine,
			Color = ColorSequence.new(V.Wind),
			Transparency = Kit.Seq({ { 0, 0.3 }, { 1, 1 } }),
			LightEmission = 0.35,
			LightInfluence = 0.3,
			Lifetime = 0.28,
		})
		table.insert(strands, strand)
	end
	local function place(pair: { Attachment }, angle: number, radius: number, height: number, width: number)
		local at = centre + Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
		pair[1].WorldPosition = at - Vector3.yAxis * width / 2
		pair[2].WorldPosition = at + Vector3.yAxis * width / 2
	end
	local function step(alpha: number)
		if stopped then
			return
		end
		local turned = ease(alpha) * orbit.Turns * 2 * math.pi
		local radius = orbit.Radius[1] + (orbit.Radius[2] - orbit.Radius[1]) * ease(alpha)
		local height = orbit.Height[1] + (orbit.Height[2] - orbit.Height[1]) * alpha
		for _, strand in strands do
			if strand.Smoke then
				place(strand.Smoke, strand.Phase + turned, radius, height, RIBBON_WIDTH)
			end
			local out = if orbit.Smoke then LINE_OUT else 0
			local lag = if orbit.Smoke then LINE_LAG else 0
			place(strand.Line, strand.Phase + turned - lag, radius + out, height + 0.3, orbit.LineWidth or LINE_WIDTH)
		end
	end
	local function stop()
		if not stopped then
			stopped = true
			Kit.Release(anchor, 0.5)
		end
	end
	step(0)
	Kit.Tween(orbit.Time, step, stop)
	return stop
end

-- The gust: a ring of wind running out along the ground, dark smoke driven outward, streaks flying off; then the
-- smoke settles low and fades.
local function gust(floor: Vector3)
	Kit.Burst(CFrame.new(floor + Vector3.yAxis * 0.15), {
		{ -- the wind ring, flat on the ground (perpendicular to its upward drift)
			Count = 1,
			Texture = T.WindRing,
			Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
			EmissionDirection = Enum.NormalId.Top,
			Speed = NumberRange.new(0.01),
			Color = ColorSequence.new(V.Wind),
			LightEmission = 0.3,
			LightInfluence = 0.4,
			Transparency = Kit.Seq({ { 0, 0.1 }, { 1, 1 } }),
			Size = Kit.Seq({ { 0, 2 }, { 1, 17 } }),
			Lifetime = NumberRange.new(0.45),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-120, -80),
		},
		{ -- a dark ring of smoke under it, a little slower
			Count = 1,
			Texture = T.WindRing,
			Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
			EmissionDirection = Enum.NormalId.Top,
			Speed = NumberRange.new(0.01),
			Color = ColorSequence.new(V.WindSmoke),
			LightInfluence = 0.6,
			Transparency = Kit.Seq({ { 0, 0.3 }, { 1, 1 } }),
			Size = Kit.Seq({ { 0, 1.5 }, { 1, 13 } }),
			Lifetime = NumberRange.new(0.6),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-90, -60),
		},
		{ -- the smoke settling low
			Count = 4,
			Texture = T.SmokePuff,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
			FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
			Color = Kit.Colors(V.WindSmoke, V.WindSmokeDeep),
			LightInfluence = 0.6,
			Transparency = Kit.Seq({ { 0, 0.55 }, { 1, 1 } }),
			Size = Kit.Seq({ { 0, 2.4 }, { 1, 4.6 } }),
			Lifetime = NumberRange.new(0.9, 1.2),
			Speed = NumberRange.new(0.5, 1.2),
			SpreadAngle = Vector2.new(180, 180),
			Drag = 2,
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-20, 20),
		},
	})
	for k = 1, GUST_DIRECTIONS do
		local angle = (k - 1) / GUST_DIRECTIONS * 2 * math.pi + math.random() * 0.4
		local out = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local from = floor + Vector3.yAxis * 0.6
		Kit.Burst(CFrame.lookAt(from, from + out), {
			{ -- smoke driven outward along the ground, rising a little as it slows
				Count = 1,
				Texture = T.SmokePuff,
				FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
				FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
				Color = Kit.Colors(V.WindSmoke, V.WindSmokeDeep),
				LightInfluence = 0.6,
				Transparency = Kit.Seq({ { 0, 0.35 }, { 1, 1 } }),
				Size = Kit.Seq({ { 0, 1.3 }, { 1, 3.2 } }),
				Lifetime = NumberRange.new(0.6, 0.9),
				Speed = NumberRange.new(10, 14),
				EmissionDirection = Enum.NormalId.Front,
				SpreadAngle = Vector2.new(12, 6),
				Acceleration = Vector3.new(0, 0.8, 0),
				Drag = 4,
				Rotation = NumberRange.new(0, 360),
			},
			{ -- a streak of wind flying off
				Count = 1,
				Texture = T.WindStreak,
				Orientation = Enum.ParticleOrientation.VelocityParallel,
				Color = ColorSequence.new(V.Wind),
				LightEmission = 0.4,
				LightInfluence = 0.3,
				Transparency = Kit.Seq({ { 0, 0.2 }, { 1, 1 } }),
				Size = Kit.Seq({ { 0, 1.7 }, { 1, 0.6 } }),
				Lifetime = NumberRange.new(0.2, 0.28),
				Speed = NumberRange.new(26, 34),
				EmissionDirection = Enum.NormalId.Front,
				SpreadAngle = Vector2.new(10, 14),
				Drag = 3,
			},
		})
	end
end

local function play(hold: Hold, beat: string)
	local middle, floor = places(hold)
	if beat == "Seize" then
		pull(middle + Vector3.yAxis * 0.5)
	elseif beat == "Fangs" then
		local bite = partAt(hold.Victim, "Head", Vector3.new(0, -0.55, 0), middle + Vector3.yAxis * 1.5)
		fangs(bite)
		Kit.Flash(bite, V.Drain, FANGS_LIGHT.Brightness, FANGS_LIGHT.Range, FANGS_LIGHT.Time)
		hold.Stop = circle(floor, DRAIN)
	elseif beat == "Pulse" then
		local neck = partAt(hold.Victim, "Head", Vector3.new(0, -0.55, 0), middle + Vector3.yAxis * 1.5)
		pulse(neck, partAt(hold.Biter, "Torso", Vector3.new(0, 0.4, 0), middle + Vector3.yAxis))
		Kit.Flash(neck, V.Drain, PULSE_LIGHT.Brightness, PULSE_LIGHT.Range, PULSE_LIGHT.Time)
	elseif beat == "Release" then
		BiteWind.Finish(hold)
		circle(floor, SWEEP)
		gust(floor)
	end
end

-- A hold seen for the first time, `elapsed` seconds after its seize: beats already well past are skipped.
function BiteWind.Begin(biter: Model, victim: Model?, elapsed: number): Hold
	local hold: Hold = { Biter = biter, Victim = victim, Next = 1, Stop = nil }
	while hold.Next <= #BEATS and BEATS[hold.Next].At < elapsed - LATE do
		hold.Next += 1
	end
	return hold
end

-- Plays every beat whose time has come; returns their names (the controller adds the flash, shakes and sounds).
function BiteWind.Update(hold: Hold, elapsed: number): { string }
	local fired = {}
	while hold.Next <= #BEATS and elapsed >= BEATS[hold.Next].At do
		local beat = BEATS[hold.Next].Name
		hold.Next += 1
		play(hold, beat)
		table.insert(fired, beat)
	end
	return fired
end

-- The hold ended (released or broken): the drain's orbit stops where it is.
function BiteWind.Finish(hold: Hold)
	if hold.Stop then
		hold.Stop()
		hold.Stop = nil
	end
end

return BiteWind

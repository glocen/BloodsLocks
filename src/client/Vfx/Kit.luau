--!strict
-- Kit: the building blocks every effect shares: particle emitters from a spec table, one-shot bursts at a
-- point, light flashes, sequences, and a graceful release that lets particles and trails die out on their own.

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Textures = require(script.Parent.Textures)

export type Spec = { [string]: any }

local Kit = {}

-- Review aid: slows every effect started after it is set (tween clocks and particle time), 1 = real time. Captures of
-- fast effects set it on their own copy of this module from the Client context; the game never changes it.
Kit.TimeScale = 1

-- Texture ids for the effect library, every one ours: built, reviewed, uploaded and recorded by tools/vfx/textures.py
-- (Vfx/Textures; its registry says what each texture is and how it's laid out). Trails run a texture's vertical axis
-- along their length (the top is the newest edge) and its horizontal axis from Attachment0 (left) to Attachment1
-- (right). Velocity-aligned particles (VelocityParallel) lead with the texture's LEFT edge: their art is drawn moving left.
Kit.Textures = {} :: { [string]: string }
for name, entry in Textures do
	Kit.Textures[name] = entry.Id
end

-- NumberSequence from a single value, two values, or a list of {time, value[, envelope]} keypoints.
function Kit.Seq(a: any, b: number?): NumberSequence
	if type(a) == "number" then
		return NumberSequence.new(a, b or a)
	end
	local points = {}
	for _, k in a do
		table.insert(points, NumberSequenceKeypoint.new(k[1], k[2], k[3] or 0))
	end
	return NumberSequence.new(points)
end

-- ColorSequence from one color, two colors, or a list of {time, color} keypoints.
function Kit.Colors(a: any, b: Color3?): ColorSequence
	if typeof(a) == "Color3" then
		return ColorSequence.new(a, b or a)
	end
	local points = {}
	for _, k in a do
		table.insert(points, ColorSequenceKeypoint.new(k[1], k[2]))
	end
	return ColorSequence.new(points)
end

-- A ParticleEmitter configured from a spec. Unknown keys error, so typos surface. `Count` is for bursts.
function Kit.Emitter(parent: Instance, spec: Spec): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 0
	emitter.LightInfluence = 0
	emitter.Speed = NumberRange.new(0)
	emitter.TimeScale = Kit.TimeScale
	for key, value in spec do
		if key ~= "Count" then
			(emitter :: any)[key] = value
		end
	end
	emitter.Parent = parent
	return emitter
end

-- An invisible anchored part to carry attachments, emitters and lights.
function Kit.Anchor(cframe: CFrame, size: Vector3?): BasePart
	local part = Instance.new("Part")
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
	part.Transparency = 1
	part.Size = size or Vector3.one * 0.2
	part.CFrame = cframe
	part.Parent = workspace
	return part
end

-- Emits each spec's Count once at the cframe, then cleans up after the longest particle could live.
function Kit.Burst(cframe: CFrame, specs: { Spec }, size: Vector3?)
	local anchor = Kit.Anchor(cframe, size)
	local attachment = Instance.new("Attachment")
	attachment.Parent = anchor
	local longest = 0
	for _, spec in specs do
		local emitter = Kit.Emitter(if spec.Shape then anchor else attachment, spec)
		emitter:Emit(spec.Count or 1)
		longest = math.max(longest, emitter.Lifetime.Max)
	end
	Debris:AddItem(anchor, longest / Kit.TimeScale + 0.1)
end

-- A light that pops to full brightness and fades out.
function Kit.Flash(position: Vector3, color: Color3, brightness: number, range: number, duration: number)
	local anchor = Kit.Anchor(CFrame.new(position))
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range, light.Shadows = color, brightness, range, false
	light.Parent = anchor
	Kit.Tween(duration, function(alpha)
		light.Brightness = brightness * (1 - alpha) ^ 2
	end, function()
		anchor:Destroy()
	end)
end

-- Runs step(alpha) every frame for `duration` seconds (alpha 0 → 1), then done(). The first frame always shows alpha
-- 0, so a flash's brightest frame is seen even at a low frame rate (at 15 fps a 0.16 s flash lasts two frames).
function Kit.Tween(duration: number, step: (number) -> (), done: (() -> ())?)
	local elapsed = 0
	local started = false
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function(dt)
		if started then
			elapsed += dt * Kit.TimeScale
		end
		started = true
		local alpha = math.min(elapsed / duration, 1)
		step(alpha)
		if alpha >= 1 then
			connection:Disconnect()
			if done then
				done()
			end
		end
	end)
end

-- Stops everything under the root from emitting and lets live particles and trails finish before destroying it.
function Kit.Release(root: Instance, linger: number)
	for _, d in root:GetDescendants() do
		if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Light") then
			(d :: any).Enabled = false
		elseif d:IsA("BasePart") then
			d.Transparency = 1
		end
	end
	if root:IsA("BasePart") then
		root.Transparency = 1
	end
	Debris:AddItem(root, linger)
end

return Kit

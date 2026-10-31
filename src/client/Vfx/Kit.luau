--!strict
-- Kit: the building blocks every effect shares: particle emitters from a spec table, one-shot bursts at a
-- point, light flashes, sequences, and a graceful release that lets particles and trails die out on their own.

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

export type Spec = { [string]: any }

local Kit = {}

-- Review aid: slows every effect started after it is set (tween clocks and particle time), 1 = real time. Captures of
-- fast effects set it on their own copy of this module from the Client context; the game never changes it.
Kit.TimeScale = 1

-- Texture ids for the effect library (harvested Creator Store art).
Kit.Textures = {
	-- Drawn for BloodsLocks (tools/vfx_textures.py)
	BloodCrescent = "rbxassetid://114481905428903", -- 512x192 wet blood moon-slash, convex edge up
	BloodGlow = "rbxassetid://127264027665322", -- halo along that crescent's outer rim (white, tint it)
	BeamCore = "rbxassetid://134206352319065", -- soft beam band; beams run a texture's vertical axis along their length
	BeamEnergy = "rbxassetid://125771507708728", -- energy strands, tileable along the beam (white)
	Glint = "rbxassetid://101126423932013", -- four-point glint (white)
	SoftGlow = "rbxassetid://75560931237584", -- round soft glow (white)
	-- Rendered for BloodsLocks in Blender (tools/blender/vfx_sprites.py)
	MuzzleFlash = "rbxassetid://124670609876463", -- four star-flash variants, Grid2x2 (coloured: use white)
	MuzzleCone = "rbxassetid://94054541399503", -- side flame for a Beam, muzzle end at the bottom (coloured)
	Spark = "rbxassetid://108622929695285", -- thin hot streak, velocity-aligned (white)
	TracerStreak = "rbxassetid://109264662547912", -- pale core in a faint glow, for a Beam (white)
	SmokePuff = "rbxassetid://140359744386400", -- lit volumetric puff, Grid4x4 one-shot (white: tint it)
	-- Trails run a texture's vertical axis along their length (the top is the newest edge) and its horizontal axis
	-- from Attachment0 (left) to Attachment1 (right). Velocity-aligned particles (VelocityParallel) lead with the
	-- texture's LEFT edge: their art is drawn moving left.
	SlashEdge = "rbxassetid://102684460045011", -- the hot hairline the point leaves, same layout (white, additive)
	BladeSmear = "rbxassetid://91511977557661", -- a blade's pale motion smear for a Trail, same layout (white: tint it)
	-- Wind (the bite's gust): white, tint it
	SmokeRibbon = "rbxassetid://74999541206773", -- a wisp of smoke for a Trail, frayed across, torn toward the tail
	WindLine = "rbxassetid://78292040209531", -- a thin speed line for a Trail, breaking into dashes toward the tail
	WindRing = "rbxassetid://139862174311558", -- a gust ring seen from above, for a flat expanding particle
	WindStreak = "rbxassetid://124748249350949", -- a gust's soft bent streak, velocity-aligned
	-- Creator Store art
	Crescent = "rbxassetid://13138038111", -- slash crescent flipbook, Grid4x4
	CrescentDark = "rbxassetid://13780268621", -- crescent arcs, Grid4x4
	Smoke = "rbxassetid://18369727963", -- smoke wisps flipbook, Grid4x4
	Dot = "rbxassetid://11197917329", -- soft dot
	Wisp = "rbxassetid://15253860988", -- wispy energy column
	Fire = "rbxassetid://16850891267", -- fire flipbook, Grid4x4
	Glow = "rbxassetid://1075864321", -- soft radial glow
}

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

-- Runs step(alpha) every frame for `duration` seconds (alpha 0 → 1), then done().
function Kit.Tween(duration: number, step: (number) -> (), done: (() -> ())?)
	local elapsed = 0
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function(dt)
		elapsed += dt * Kit.TimeScale
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

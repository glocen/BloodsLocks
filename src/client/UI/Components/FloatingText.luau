--!strict
-- FloatingText: short call-outs over a model's head (PARRY, STAGGERED, Guard broken, a bite's heal...) and the glint
-- an enemy shows when it notices you. Drawn in the World layer and projected every frame (UI/World/WorldPin), with
-- the Text kit's look (Theme font, soft shadow, no outline): a call-out rises a little and fades; the glint swells
-- and fades.

local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Parent.Theme)
local Layers = require(script.Parent.Parent.Core.Layers)
local Text = require(script.Parent.Parent.Kit.Text)
local WorldPin = require(script.Parent.Parent.World.WorldPin)
local Budget = require(script.Parent.Parent.Parent.Util.Budget)

local LIFETIME = 0.8 -- seconds
local FADE_FROM = 0.4 -- seconds before the fade starts
local RISE = 2.2 -- studs a call-out rises over its life
local ABOVE_HEAD = 1.6 -- studs
local TEXT_SIZE = { Normal = 22, Big = 30 }
local GLINT = { Size = 44, Life = 0.45, Above = 1.1 } -- the "noticed you" glint

local FloatingText = {}

type Pop = { Object: GuiObject, Part: BasePart, Born: number, Life: number, Offset: Vector3, Rise: number, Glint: boolean }

local pops: { Pop } = {}
local running = false

local function step()
	local now = os.clock()
	for i = #pops, 1, -1 do
		local pop = pops[i]
		local age = now - pop.Born
		if age >= pop.Life or not pop.Part.Parent then
			pop.Object:Destroy()
			table.remove(pops, i)
			continue
		end
		local t = age / pop.Life
		local eased = 1 - (1 - t) ^ 2
		local position = WorldPin.Project(pop.Part.Position + pop.Offset + Vector3.new(0, pop.Rise * eased, 0), 40)
		pop.Object.Visible = position ~= nil
		if position then
			pop.Object.Position = position
		end
		if pop.Glint then
			local image = pop.Object :: ImageLabel
			local size = GLINT.Size * (0.6 + 0.6 * eased)
			image.Size = UDim2.fromOffset(size, size)
			image.ImageTransparency = t ^ 2
		else
			local label = pop.Object :: TextLabel
			label.TextTransparency = math.clamp((age - FADE_FROM) / (pop.Life - FADE_FROM), 0, 1)
		end
	end
end

local function add(pop: Pop)
	table.insert(pops, pop)
	if not running then
		running = true
		RunService.RenderStepped:Connect(Budget.Wrap("Callouts", step))
	end
end

function FloatingText.Pop(model: Model, text: string, color: Color3, big: boolean?)
	local head = model:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	local size = if big then TEXT_SIZE.Big else TEXT_SIZE.Normal
	local label = Text.new(Layers.Get("World"), "Numeric", {
		Name = "Pop",
		Text = text,
		AnchorPoint = Vector2.new(0.5, 1),
		Size = UDim2.fromOffset(240, size + 8),
		TextSize = size,
		TextColor3 = color,
		Visible = false,
	})
	add({ Object = label, Part = head, Born = os.clock(), Life = LIFETIME, Offset = Vector3.new(math.random(-10, 10) / 10, ABOVE_HEAD, 0), Rise = RISE, Glint = false })
end

-- The glint over an enemy's head the moment it notices you (fair warning: it turns and pauses before it comes).
function FloatingText.Glint(model: Model)
	local head = model:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	local image = Instance.new("ImageLabel")
	image.Name = "Noticed"
	image.BackgroundTransparency = 1
	image.Image = Theme.Images.Glint
	image.ImageColor3 = Theme.Colors.Warm
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Size = UDim2.fromOffset(GLINT.Size, GLINT.Size)
	image.Visible = false
	image.Parent = Layers.Get("World")
	add({ Object = image, Part = head, Born = os.clock(), Life = GLINT.Life, Offset = Vector3.new(0, GLINT.Above, 0), Rise = 0, Glint = true })
end

return FloatingText

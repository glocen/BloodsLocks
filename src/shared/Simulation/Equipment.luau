--!strict
-- Equipment: weapon models. Tools aren't supported under Server Authority, so weapons are models welded to the
-- character's arms with plain Welds (a WeldConstraint inside a cloned model doesn't hold there). The server welds
-- them inside the simulation and they replicate to clients as normal instances; a client may weld one for a body
-- only it shows (a Shinigami waiting at its pact circle).
-- A weapon definition names its model in Shared.Assets.Weapons (Model) and its hand (Hand: "Right", the default, or
-- "Left"). The model's weld point is its "Grip" attachment (on its PrimaryPart, or its part named "Body"), seated in
-- the hand facing along the forearm; older models give a GripC0 attribute instead. Each hand holds one model.

local Shared = script.Parent.Parent
local Registry = require(Shared.Definitions.Registry)
local EntityState = require(script.Parent.EntityState)

local HELD = { Right = "BL_Weapon", Left = "BL_Sidearm" } -- the held model's name, per hand
local ARM = { Right = "Right Arm", Left = "Left Arm" }
-- The hand's frame on an R6 arm: at the palm, the weapon's forward (-Z) along the forearm (out of the fist), its up
-- toward the arm's front, so a raised arm aims it.
local HAND_FRAME = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0)
local DEFAULT_GRIP_C0 = CFrame.new(0, -1, 0)

local Equipment = {}

local function holdingPart(model: Model): BasePart?
	return model.PrimaryPart or model:FindFirstChild("Body") :: BasePart?
end

-- Welds weapon `weaponId`'s model into its hand, replacing what that hand held (a class change). Nothing happens if
-- the definition, its model or the arm is missing.
local function attach(character: Model, weaponId: string)
	local weapon = Registry.Weapon(weaponId)
	local hand = weapon.Hand or "Right"
	local held = character:FindFirstChild(HELD[hand])
	if held then
		held:Destroy()
	end
	local assets = Shared:FindFirstChild("Assets")
	local template = assets and weapon.Model and assets.Weapons:FindFirstChild(weapon.Model) :: Model?
	local arm = character:FindFirstChild(ARM[hand]) :: BasePart?
	if not template or not arm then
		return
	end
	local model = template:Clone()
	model.Name = HELD[hand]
	local part = holdingPart(model)
	if not part then
		return
	end
	local weld = Instance.new("Weld")
	weld.Part0 = arm
	weld.Part1 = part
	local grip = part:FindFirstChild("Grip")
	if grip and grip:IsA("Attachment") then
		weld.C0 = HAND_FRAME
		weld.C1 = grip.CFrame
	else
		weld.C0 = template:GetAttribute("GripC0") or DEFAULT_GRIP_C0
	end
	weld.Parent = part
	model.Parent = character
end

-- The class's melee weapon in its hand. `weaponId` overrides it (NPCs: a Shinigami's own blade).
function Equipment.AttachMelee(character: Model, weaponId: string?)
	local class = Registry.Class(character:GetAttribute(EntityState.Attr.ClassId))
	attach(character, weaponId or class.Melee)
end

-- The class's whole loadout: its melee weapon and its gun.
function Equipment.AttachLoadout(character: Model)
	local class = Registry.Class(character:GetAttribute(EntityState.Attr.ClassId))
	attach(character, class.Melee)
	if class.Ranged then
		attach(character, class.Ranged)
	end
end

-- The held model in `hand` ("Right" or "Left"), if any.
function Equipment.Held(character: Model, hand: string): Model?
	return character:FindFirstChild(HELD[hand]) :: Model?
end

return Equipment

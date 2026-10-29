--!strict
-- Equipment: weapon models. Tools aren't supported under Server Authority, so weapons are models welded to the
-- character. The server creates them inside the simulation; they replicate to clients as normal instances.

local Shared = script.Parent.Parent
local Registry = require(Shared.Definitions.Registry)
local EntityState = require(script.Parent.EntityState)

local WEAPON_NAME = "BL_Weapon"

local Equipment = {}

-- Server only: welds the class's melee weapon to the right arm (once per character).
function Equipment.AttachMelee(character: Model)
	local class = Registry.Class(character:GetAttribute(EntityState.Attr.ClassId))
	local weapon = Registry.Weapon(class.Melee)
	local assets = Shared:FindFirstChild("Assets")
	local template = assets and assets.Weapons:FindFirstChild(weapon.Model)
	local arm = character:FindFirstChild("Right Arm") :: BasePart?
	if not template or not arm or character:FindFirstChild(WEAPON_NAME) then
		return
	end
	local model = template:Clone()
	model.Name = WEAPON_NAME
	local weld = Instance.new("Weld")
	weld.Part0 = arm
	weld.Part1 = model.PrimaryPart
	weld.C0 = template:GetAttribute("GripC0") or CFrame.new(0, -1, 0)
	weld.Parent = model.PrimaryPart
	model.Parent = character
end

return Equipment

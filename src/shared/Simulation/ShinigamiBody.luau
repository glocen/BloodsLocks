--!strict
-- ShinigamiBody: what a Shinigami looks like, one look for every body it has: the companion its master summons
-- (ShinigamiService, server) and the figure waiting at its pact circle (PactSiteController, one client only).
-- A placeholder until the modelled versions land: the training rig in the definition's Look (dark steel body, lit
-- eyes, an aura outline), its blade in hand, no overhead name.

local Shared = script.Parent.Parent
local Equipment = require(script.Parent.Equipment)

local RIG = "TrainingDummy" -- Shared.Assets
local AURA_TRANSPARENCY = 0.35

local ShinigamiBody = {}

-- A new body for Shinigami `def`, not yet parented (nil if the rig template is missing).
function ShinigamiBody.Make(def: any): Model?
	local template = Shared.Assets:FindFirstChild(RIG)
	if not template then
		return nil
	end
	local model = template:Clone() :: Model
	model.Name = def.DisplayName
	local look = def.Look
	for _, d in model:GetDescendants() do
		if d:IsA("BaseScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Color = look.Body
			d.Material = Enum.Material.SmoothPlastic
		elseif d:IsA("Decal") then
			d.Color3 = look.Eyes
		end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	local aura = Instance.new("Highlight")
	aura.FillTransparency = 1
	aura.OutlineColor = look.Aura
	aura.OutlineTransparency = AURA_TRANSPARENCY
	aura.Parent = model
	if def.Weapon then
		Equipment.AttachMelee(model, def.Weapon)
	end
	return model
end

return ShinigamiBody

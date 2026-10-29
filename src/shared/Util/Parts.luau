--!strict
-- Parts: lookups on character-like models.

local Parts = {}

function Parts.Root(model: Instance?): BasePart?
	return if model then model:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
end

function Parts.Humanoid(model: Instance?): Humanoid?
	return if model then model:FindFirstChildOfClass("Humanoid") else nil
end

return Parts

--!strict
-- Move the custom shoulder tower into the approach silhouette, beside the west wing.
-- The yard bell tower and gameplay training positions are independent and unchanged.
local C={}
function C.Apply(root:Instance)
 local shell=root:FindFirstChild("ManorExterior");assert(shell,"Exterior required")
 if shell:GetAttribute("TowerCompositionRevision")==1 then return end
 for _,p in shell:GetDescendants()do
  if p:IsA("BasePart")and string.sub(p.Name,1,13)=="ShoulderTower"then
   p.CFrame=CFrame.new(-92,0,47)*p.CFrame
  end
 end
 shell:SetAttribute("TowerCompositionRevision",1)
end
return C

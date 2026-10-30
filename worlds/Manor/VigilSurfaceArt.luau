--!strict
-- Our original albedos replace high-contrast native limestone noise.
-- Diffuse-only Studio finish: authored PBR remains a separate unresolved integration task.
local S={}
local ASHLAR="rbxassetid://104387937709405"
local TRIM="rbxassetid://100977117947520"
local function stone(p:BasePart,wall:boolean)
 p.Material=Enum.Material.Concrete;p.MaterialVariant="";p.Reflectance=0
 p.Color=if wall then Color3.fromRGB(175,170,163)else Color3.fromRGB(190,185,177)
 if p:IsA("MeshPart")then p.TextureID=if wall then ASHLAR else TRIM end
end
function S.Apply(root:Instance)
 local n=0
 for _,container in {root:FindFirstChild("ManorExterior"),root:FindFirstChild("LayeredWindows")}do
  if container then for _,p in container:GetDescendants()do
   if p:IsA("MeshPart")then
    if string.find(p.Name,"_WALL")then stone(p,true);n+=1
    elseif string.find(p.Name,"_STONE")then stone(p,false);n+=1 end
   end
  end end
 end
 for _,p in root:GetDescendants()do
  if p:IsA("UnionOperation")and p.Name=="CarvedWall"then
   stone(p,true);p.UsePartColor=true
   for _,face in Enum.NormalId:GetEnumItems()do
    local name="AuthoredMasonry_"..face.Name
    local tex=p:FindFirstChild(name)
    if not tex then tex=Instance.new("Texture");tex.Name=name;tex.Parent=p end
    tex.Face=face;tex.Texture=ASHLAR;tex.StudsPerTileU=8;tex.StudsPerTileV=8
    tex.Color3=Color3.fromRGB(175,170,163)
   end
   n+=1
  elseif p:IsA("BasePart")and(p.Name=="AshlarCourse"or p.Name=="DressedPierCap")then
   p.Material=Enum.Material.Concrete;p.MaterialVariant="";p.Color=Color3.fromRGB(94,91,88);p.Reflectance=0
  end
 end
 root:SetAttribute("SurfaceArtRevision",1)
 return n
end
return S

--!strict
-- First exterior lighting composition, separate from structural import. Still pending owner art review.
local R={}
local ORIGIN=CFrame.new(0,0,-1000)
local function beam(parent:Instance,name:string,position:Vector3,target:Vector3,brightness:number,color:Color3)
 local p=Instance.new("Part");p.Name=name;p.Size=Vector3.one*.1;p.Transparency=1;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
 p.CFrame=CFrame.lookAt(ORIGIN:PointToWorldSpace(position),ORIGIN:PointToWorldSpace(target));p.Parent=parent
 local light=Instance.new("SpotLight");light.Face=Enum.NormalId.Front;light.Angle=110;light.Range=60;light.Brightness=brightness;light.Color=color;light.Shadows=false;light.Parent=p
end
function R.Apply(root:Instance)
 local l=game:GetService("Lighting")
 l.ClockTime=.5;l.Brightness=3
 l.Ambient=Color3.fromRGB(82,90,112);l.OutdoorAmbient=Color3.fromRGB(118,127,150)
 l.ExposureCompensation=.45;l.EnvironmentDiffuseScale=.55;l.EnvironmentSpecularScale=1
 local atmosphere=l:FindFirstChildOfClass("Atmosphere")
 if atmosphere then atmosphere.Density=.24;atmosphere.Offset=.05;atmosphere.Haze=1.5;atmosphere.Glare=.08;atmosphere.Color=Color3.fromRGB(128,143,168);atmosphere.Decay=Color3.fromRGB(67,74,102)end
 local cc=l:FindFirstChildOfClass("ColorCorrectionEffect")
 if cc then cc.Enabled=true;cc.Brightness=.025;cc.Contrast=.08;cc.Saturation=-.12;cc.TintColor=Color3.fromRGB(220,231,255)end
 local old=root:FindFirstChild("ExteriorLighting");if old then old:Destroy()end
 local rig=Instance.new("Model");rig.Name="ExteriorLighting";rig.Parent=root
 local blue=Color3.fromRGB(157,184,229)
 for _,s in {-1,1}do
  beam(rig,"HallMoonFill",Vector3.new(s*25,61,101),Vector3.new(s*12,42,62),2.2,blue)
  beam(rig,"WingMoonFill",Vector3.new(s*106,54,62),Vector3.new(s*106,34,21),2.0,blue)
  beam(rig,"HallRoofRim",Vector3.new(s*36,137,28),Vector3.new(s*22,101,0),2.0,blue)
  beam(rig,"WingRoofRim",Vector3.new(s*105,112,25),Vector3.new(s*105,80,0),1.5,blue)
  beam(rig,"YardFacadeFill",Vector3.new(s*105,55,-63),Vector3.new(s*105,36,-21),1.6,blue)
 end
 beam(rig,"TowerBelfryFill",Vector3.new(-63,144,-17),Vector3.new(-63,116,-55),2.1,blue)
 beam(rig,"TowerSpireRim",Vector3.new(-63,182,-18),Vector3.new(-63,159,-55),2.3,blue)
 beam(rig,"PorchWarmPool",Vector3.new(0,24,88),Vector3.new(0,9,64),1.7,Color3.fromRGB(255,189,129))
 -- Gentle warm glass remains subordinate to the roof and doorway silhouette.
 for _,p in root.ManorExterior:GetDescendants()do
  if p:IsA("MeshPart")and string.find(p.Name,"GLASS")then p.Color=Color3.fromRGB(71,52,69);p.Transparency=.3 end
 end
end
return R
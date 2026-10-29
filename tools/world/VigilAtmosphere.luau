--!strict
-- The Vigil: authored crimson/violet/blue dusk and dielectric varnished-oak surfaces.
-- Owner requested lighting now (2026-10-29). No paid assets; texture source is in tools/art.
-- Edit-time art tool. Original Lighting lives in Backups.Lighting_PreCrimsonDusk_20261029.
local A={}
local L=game:GetService("Lighting")
local MS=game:GetService("MaterialService")
local ORIGIN=CFrame.new(0,0,-1000)
local IDS={["VigilOak_Color.png"]="rbxassetid://85493035756469",["VigilSky_Bk.png"]="rbxassetid://91450155359684",["VigilOak_Roughness.png"]="rbxassetid://134381124373430",["VigilSky_Dn.png"]="rbxassetid://88179822132978",["VigilSky_Ft.png"]="rbxassetid://134292125670681",["VigilSky_Up.png"]="rbxassetid://114689579887446",["VigilSky_Lf.png"]="rbxassetid://90794807763645",["VigilOak_Normal.png"]="rbxassetid://116588618817846",["VigilSky_Rt.png"]="rbxassetid://125725990147283",["VigilOak_Metalness.png"]="rbxassetid://132416009882892",["VigilOak_JoineryRoughness.png"]="rbxassetid://106878430371514"}
local function effect(className:string,name:string):any
 local item=L:FindFirstChild(name)
 if item then assert(item.ClassName==className,"Unexpected lighting object "..name);return item end
 local obj=Instance.new(className);obj.Name=name;obj.Parent=L;return obj
end
local function variant(name:string,base:Enum.Material,rough:string):MaterialVariant
 local old=MS:FindFirstChild(name)
 local v=if old then old::MaterialVariant else Instance.new("MaterialVariant")
 v.Name=name;v.BaseMaterial=base;v.ColorMap=IDS["VigilOak_Color.png"];v.NormalMap=IDS["VigilOak_Normal.png"];v.RoughnessMap=IDS[rough];v.MetalnessMap=IDS["VigilOak_Metalness.png"];v.StudsPerTile=8;v.Parent=MS
 return v
end
local function finishWood(root:Instance):number
 local n=0
 for index,p in root:GetDescendants()do
  if p:IsA("BasePart") and (p.Material==Enum.Material.Wood or p.Material==Enum.Material.WoodPlanks) then
   local floor=p.Name=="OakBoard"or p.Name=="WingOakBoard"or p.Name=="OakTread"or p.Name=="UsableUpperGallery"
   local plank=p.Material==Enum.Material.WoodPlanks
   p.MaterialVariant=if floor then (if plank then "Vigil_VarnishedOakPlanks" else "Vigil_VarnishedOak") else (if plank then "Vigil_AgedJoineryPlanks" else "Vigil_AgedJoinery")
   p.Reflectance=0 -- Gloss comes from low roughness and environment lighting; the wood is not metal.
   if floor then
    local tint=math.clamp((p.Color.R*255-67)*.4,-5,5)
    p.Color=Color3.fromRGB(81+tint,58+tint*.6,45+tint*.4)
   end
   n+=1
  end
  if index%1000==0 then task.wait() end
 end
 return n
end
local function part(parent:Instance,name:string,size:Vector3,position:Vector3,mat:Enum.Material,color:Color3):Part
 local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.Size=size;p.CFrame=ORIGIN*CFrame.new(position);p.Material=mat;p.Color=color;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=parent;return p
end
local function lantern(parent:Instance,position:Vector3,post:boolean)
 local iron=Color3.fromRGB(31,28,37)
 if post then
  part(parent,"LampPost",Vector3.new(.25,6,.25),position-Vector3.new(0,3,0),Enum.Material.Metal,iron)
  part(parent,"LampFoot",Vector3.new(1,.3,1),position-Vector3.new(0,6,0),Enum.Material.Metal,iron)
 end
 part(parent,"LanternBase",Vector3.new(1.1,.16,1.1),position,Enum.Material.Metal,iron)
 part(parent,"LanternRoof",Vector3.new(1.3,.18,1.3),position+Vector3.new(0,1.7,0),Enum.Material.Metal,iron)
 local glass=part(parent,"AmberGlass",Vector3.new(.85,1.45,.85),position+Vector3.new(0,.8,0),Enum.Material.Glass,Color3.fromRGB(163,121,80));glass.Transparency=.65;glass.CastShadow=false
 for _,x in {-.5,.5}do for _,z in {-.5,.5}do part(parent,"LanternFrame",Vector3.new(.07,1.7,.07),position+Vector3.new(x,.85,z),Enum.Material.Metal,iron)end end
 local flame=part(parent,"LanternFlame",Vector3.new(.08,.35,.08),position+Vector3.new(0,.65,0),Enum.Material.Neon,Color3.fromRGB(255,190,116));flame.Shape=Enum.PartType.Ball;flame.CastShadow=false
 local light=Instance.new("PointLight");light.Color=Color3.fromRGB(255,181,119);light.Brightness=if post then 1.5 else 1.15;light.Range=if post then 38 else 28;light.Shadows=false;light.Parent=flame
end
function A.Apply(root:Instance?):{[string]:any}
 L.ClockTime=20.2;L.Brightness=2.6
 L.Ambient=Color3.fromRGB(66,63,82);L.OutdoorAmbient=Color3.fromRGB(82,84,108)
 L.ExposureCompensation=.28;L.EnvironmentDiffuseScale=.45;L.EnvironmentSpecularScale=1
 L.GlobalShadows=true;L.ShadowSoftness=.28;L.GeographicLatitude=18
 pcall(function()L.LightingStyle=Enum.LightingStyle.Realistic;L.PrioritizeLightingQuality=true end)
 local sky=effect("Sky","Sky")
 for _,face in {"Ft","Bk","Rt","Lf","Up","Dn"}do sky["Skybox"..face]=IDS["VigilSky_"..face..".png"]end
 sky.SunAngularSize=0;sky.MoonAngularSize=0;sky.StarCount=110;sky.CelestialBodiesShown=true
 pcall(function()sky.SkyboxOrientation=Vector3.zero end)
 local air=effect("Atmosphere","Atmosphere")
 air.Density=.28;air.Offset=.05;air.Haze=1.7;air.Glare=.12
 air.Color=Color3.fromRGB(151,157,184);air.Decay=Color3.fromRGB(87,65,100)
 local grade=effect("ColorCorrectionEffect","ColorCorrection")
 grade.Enabled=true;grade.Brightness=.035;grade.Contrast=.06;grade.Saturation=-.12;grade.TintColor=Color3.fromRGB(236,230,245)
 local bloom=effect("BloomEffect","Bloom");bloom.Enabled=true;bloom.Intensity=.22;bloom.Threshold=1.4;bloom.Size=22
 local rays=effect("SunRaysEffect","SunRays");rays.Enabled=true;rays.Intensity=.025;rays.Spread=.7
 local dof=effect("DepthOfFieldEffect","DepthOfField");dof.Enabled=true;dof.NearIntensity=0;dof.FarIntensity=.025;dof.FocusDistance=60;dof.InFocusRadius=100
 variant("Vigil_VarnishedOak",Enum.Material.Wood,"VigilOak_Roughness.png")
 variant("Vigil_VarnishedOakPlanks",Enum.Material.WoodPlanks,"VigilOak_Roughness.png")
 variant("Vigil_AgedJoinery",Enum.Material.Wood,"VigilOak_JoineryRoughness.png")
 variant("Vigil_AgedJoineryPlanks",Enum.Material.WoodPlanks,"VigilOak_JoineryRoughness.png")
 local count=0
 if root then
  count=finishWood(root)
  local old=root:FindFirstChild("ArtLighting");if old then old:Destroy()end
  local rig=Instance.new("Model");rig.Name="ArtLighting";rig.Parent=root
  local key=part(rig,"CandleCrownKey",Vector3.one*.1,Vector3.new(0,28.4,0),Enum.Material.SmoothPlastic,Color3.new());key.Transparency=1
  key.CFrame=CFrame.lookAt(ORIGIN:PointToWorldSpace(Vector3.new(0,28.4,0)),ORIGIN.Position)
  local spot=Instance.new("SpotLight");spot.Face=Enum.NormalId.Front;spot.Angle=78;spot.Range=60;spot.Brightness=3.1;spot.Color=Color3.fromRGB(255,211,177);spot.Shadows=true;spot.Parent=key
  -- Broad, low-intensity bounced light keeps both storeys legible between candle pools.
  for _,location in {Vector3.new(-34,15,0),Vector3.new(34,15,0),Vector3.new(0,48,12)} do
   local bounce=part(rig,"HallBounce",Vector3.one*.1,location,Enum.Material.SmoothPlastic,Color3.new());bounce.Transparency=1
   local fill=Instance.new("PointLight");fill.Color=Color3.fromRGB(190,184,218);fill.Range=60;fill.Brightness=.85;fill.Shadows=false;fill.Parent=bounce
  end
  for _,side in {-1,1}do lantern(rig,Vector3.new(side*51,33.8,24),false)end
  for _,z in {-110,-250}do for _,side in {-1,1}do lantern(rig,Vector3.new(side*13,6.3,z),true)end end
  for _,p in root.GreatHall:GetDescendants()do
   if p:IsA("BasePart") and p.Name=="BlueGreyGlass" then p.Color=Color3.fromRGB(89,67,107);p.Transparency=.38 end
   if p:IsA("SpotLight") and p.Parent.Name=="MoonlightFixture"then p.Color=Color3.fromRGB(154,151,207);p.Brightness=1.9 end
  end
  local pact=root.Yard:FindFirstChild("ShinigamiCircle")
  if pact and pact:FindFirstChild("LightPillar")then pact.LightPillar.Transparency=.94 end
 end
 return {woodParts=count,sky="Original crimson/violet/blue dusk",specular=L.EnvironmentSpecularScale,clock=L.ClockTime}
end
return A

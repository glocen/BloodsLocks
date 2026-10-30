--!strict
-- VigilBay: edit-time architecture master and placement for the northwest review bay.
-- Runs only when explicitly invoked by VigilGraybox; no runtime scripts or purchased assets.
local S = game:GetService("ServerStorage")
local Bay = {}
local WIDTH = 80 * math.tan(math.rad(22.5)) + 0.4
local FRAME = CFrame.new(0,0,-1000) * CFrame.Angles(0,math.rad(225),0) * CFrame.new(0,0,40)
local stone=Color3.fromRGB(77,72,79)
local trim=Color3.fromRGB(111,104,110)
local dark=Color3.fromRGB(38,34,42)
local iron=Color3.fromRGB(32,29,33)
local wood=Color3.fromRGB(59,41,34)
local function group(parent: Instance, name: string): Model
 local m=Instance.new("Model"); m.Name=name; m.Parent=parent; return m
end
local function block(m: Instance,n: string,s: Vector3,cf: CFrame,c: Color3,mat: Enum.Material,collision: boolean?): Part
 local p=Instance.new("Part"); p.Name=n;p.Anchored=true;p.Size=s;p.CFrame=cf;p.Color=c;p.Material=mat
 p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 p.CanCollide=collision==true;p.CanTouch=false;p.CanQuery=collision==true;p.Parent=m;return p
end
local function bar(m: Instance,n: string,a: Vector3,b: Vector3,w: number,d: number,c: Color3,mat: Enum.Material)
 block(m,n,Vector3.new(w,(b-a).Magnitude+0.025,d),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(math.pi/2,0,0),c,mat)
end
local function arch(m: Instance,span: number,spring: number,z: number,w: number,d: number,c: Color3)
 for _,side in {-1,1} do
  local last=Vector3.new(side*span/2,spring,z)
  for i=1,18 do
   local t=math.rad(60)*i/18
   local nextP=Vector3.new(side*(-span/2+span*math.cos(t)),spring+span*math.sin(t),z)
   bar(m,"ArchVoussoir",last,nextP,w,d,c,Enum.Material.Limestone);last=nextP
  end
 end
end
function Bay.EnsureMaster(): Model
 local assets=S:FindFirstChild("WorldAssets")
 if not assets then assets=Instance.new("Folder");assets.Name="WorldAssets";assets.Parent=S end
 local kit=assets:FindFirstChild("VigilKit")
 if not kit then kit=Instance.new("Folder");kit.Name="VigilKit";kit.Parent=assets end
 local existing=kit:FindFirstChild("NorthwestBay")
 if existing then return existing :: Model end
 local m=group(kit,"NorthwestBay")
 m:SetAttribute("Status","Owner visual review pending");m:SetAttribute("Width",WIDTH)
 local shell=group(m,"Masonry")
 block(shell,"LowerWall",Vector3.new(WIDTH,24,2.5),CFrame.new(0,12,1.25),stone,Enum.Material.Slate,true)
 for _,side in {-1,1} do
  block(shell,"WindowPier",Vector3.new((WIDTH-6)/2,16,2.5),CFrame.new(side*(WIDTH+6)/4,32,1.25),stone,Enum.Material.Slate,true)
 end
 block(shell,"UpperWall",Vector3.new(WIDTH,5,2.5),CFrame.new(0,42.5,1.25),stone,Enum.Material.Slate,true)
 for _,x in {-14.5,14.5} do
  local col=group(m,"ClusteredColumn")
  for _,spec in {{0.4,3.3,0.8},{1,2.8,0.4},{1.5,2.3,0.6},{19.2,2.6,0.5},{19.8,3.2,0.6}} do
   block(col,"DressedBaseOrCapital",Vector3.new(spec[2],spec[3],2.4),CFrame.new(x,spec[1],-0.85),trim,Enum.Material.Limestone)
  end
  for _,offset in {-0.65,0,0.65} do
   local p=block(col,"Shaft",Vector3.new(17.3,0.72,0.72),CFrame.new(x+offset,10.1,-1.25)*CFrame.Angles(0,0,math.pi/2),trim,Enum.Material.Limestone)
   p.Shape=Enum.PartType.Cylinder
  end
 end
 local arches=group(m,"PointedArcade")
 arch(arches,29,19.8,-0.8,1,1.25,trim)
 arch(arches,27.3,20.2,-1.55,0.28,0.35,dark)
 local window=group(m,"LancetReveal")
 for _,x in {-3.4,3.4} do
  block(window,"Jamb",Vector3.new(0.65,10,1.8),CFrame.new(x,29,-0.35),trim,Enum.Material.Limestone)
 end
 arch(window,6.8,34,-0.35,0.65,1.8,trim)
 arch(window,6.1,34,-1.05,0.18,0.3,dark)
 block(window,"Sill",Vector3.new(8,0.6,2.6),CFrame.new(0,23.9,-0.4),trim,Enum.Material.Limestone)
 local glass=block(window,"MoonGlass",Vector3.new(5.8,14.8,0.15),CFrame.new(0,31.5,1.9),Color3.fromRGB(80,99,141),Enum.Material.Glass)
 glass.Transparency=0.2
 for _,x in {-1.9,0,1.9} do
  block(window,"Mullion",Vector3.new(0.18,10,0.25),CFrame.new(x,29,-0.75),iron,Enum.Material.Metal)
  bar(window,"Tracery",Vector3.new(x,34,-0.75),Vector3.new(0,38.7,-0.75),0.16,0.25,iron,Enum.Material.Metal)
 end
 local gallery=group(m,"GalleryFinish")
 block(gallery,"Fascia",Vector3.new(WIDTH,1.3,0.6),CFrame.new(0,17.75,-6),wood,Enum.Material.WoodPlanks)
 for _,y in {17.1,18.5,21.8} do
  block(gallery,"Moulding",Vector3.new(WIDTH,0.22,0.8),CFrame.new(0,y,-6),iron,Enum.Material.Metal)
 end
 for i=-15,15,2.5 do
  block(gallery,"Baluster",Vector3.new(0.16,3.1,0.16),CFrame.new(i,20.1,-6),iron,Enum.Material.Metal)
 end
 for _,x in {-10,10} do
  bar(gallery,"Corbel",Vector3.new(x,14,-0.6),Vector3.new(x,17.2,-5.5),0.7,0.7,trim,Enum.Material.Limestone)
 end
 local vault=group(m,"VaultRibs")
 for _,side in {-1,1} do
  local last=Vector3.new(side*14.5,20,-1)
  for i=1,14 do
   local t=i/14
   local nextP=Vector3.new(side*14.5*(1-t),20+24*math.sin(t*math.pi/2),-1-14*t)
   bar(vault,"Rib",last,nextP,0.55,0.65,trim,Enum.Material.Limestone);last=nextP
  end
 end
 block(m,"Cornice",Vector3.new(WIDTH,0.7,1.2),CFrame.new(0,43.8,-0.25),trim,Enum.Material.Limestone)
 local floor=group(m,"FloorBorder")
 for _,x in {-15,15} do
  block(floor,"Inlay",Vector3.new(0.4,0.05,9),CFrame.new(x,0.035,-4.5),dark,Enum.Material.Basalt)
 end
 local lamp=group(m,"Sconce")
 block(lamp,"Backplate",Vector3.new(1.25,3.4,0.3),CFrame.new(-7,8.7,-0.3),iron,Enum.Material.Metal)
 bar(lamp,"Arm",Vector3.new(-7,8,-0.5),Vector3.new(-7,8.7,-2),0.22,0.22,iron,Enum.Material.Metal)
 for _,x in {-7.55,-7,-6.45} do
  local candle=block(lamp,"Wax",Vector3.new(0.24,0.9,0.24),CFrame.new(x,9.1,-2),Color3.fromRGB(186,159,121),Enum.Material.SmoothPlastic)
  local flame=block(lamp,"Flame",Vector3.new(0.09,0.25,0.09),candle.CFrame*CFrame.new(0,0.56,0),Color3.fromRGB(255,172,86),Enum.Material.Neon)
  if x==-7 then local l=Instance.new("PointLight");l.Color=flame.Color;l.Brightness=1.1;l.Range=22;l.Shadows=false;l.Parent=flame end
 end
 -- Explicit world pivot makes every cloned bay placeable from the same wall-local frame.
 m.WorldPivot=CFrame.identity
 return m
end
function Bay.Apply(root: Instance)
 local hall=root:FindFirstChild("GreatHall");assert(hall,"Missing GreatHall")
 local master=Bay.EnsureMaster()
 local old=hall:FindFirstChild("NorthwestBay");if old then old:Destroy() end
 local wall=hall:FindFirstChild("Wall5");if wall then wall:Destroy() end
 for _,p in hall:GetChildren() do
  if p:IsA("BasePart") and (p.Name=="MoonLancet" or p.Name=="Sconce") then
   local pos=FRAME:PointToObjectSpace(p.Position)
   if math.abs(pos.X)<0.1 and math.abs(pos.Z)<2 then p:Destroy() end
  end
 end
 local clone=master:Clone();clone:PivotTo(FRAME);clone.Parent=hall
end
return Bay

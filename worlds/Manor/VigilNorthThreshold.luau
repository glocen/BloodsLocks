--!strict
-- The Vigil: north threshold composition. Edit-time only; no runtime behaviour.
-- Sketch: layered 16-stud pointed opening -> outdoor yard; paired gallery ends,
-- full-height clustered piers, recessed upper lancet, iron and timber at hand scale.
-- Reference boundary: House of Night courtyard is verified; gallery001 location is unverified.
-- Keep Build/Spots, global Lighting, training positions and gameplay untouched.
local S=game:GetService("ServerStorage")
local A={}
local HALF=(80*math.tan(math.rad(22.5))+.4)/2
local HEIGHT=45
local SPRING=26-16*math.sqrt(3)/2
local FRAME=CFrame.new(0,0,-1000)*CFrame.Angles(0,math.pi,0)*CFrame.new(0,0,40)
local C={stone=Color3.fromRGB(79,83,89),trim=Color3.fromRGB(112,113,115),edge=Color3.fromRGB(131,128,121),dark=Color3.fromRGB(30,34,41),wood=Color3.fromRGB(46,35,34),iron=Color3.fromRGB(29,31,35),wax=Color3.fromRGB(182,157,116)}
local function model(parent:Instance,name:string):Model
 local m=Instance.new("Model");m.Name=name;m.Parent=parent;return m
end
local function part(parent:Instance,name:string,size:Vector3,cf:CFrame,color:Color3,material:Enum.Material,collision:boolean?):Part
 local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material;p.CanCollide=collision==true;p.CanTouch=false;p.CanQuery=collision==true;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p
end
local function beam(parent:Instance,name:string,a:Vector3,b:Vector3,width:number,depth:number,color:Color3,material:Enum.Material)
 return part(parent,name,Vector3.new(width,(b-a).Magnitude+.012,depth),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(math.pi/2,0,0),color,material,false)
end
local function cyl(parent:Instance,name:string,r:number,h:number,position:Vector3,color:Color3,material:Enum.Material)
 local p=part(parent,name,Vector3.new(h,r*2,r*2),CFrame.new(position)*CFrame.Angles(0,0,math.pi/2),color,material,false);p.Shape=Enum.PartType.Cylinder;return p
end
local function arch(parent:Instance,name:string,span:number,spring:number,z:number,width:number,depth:number,color:Color3,material:Enum.Material,steps:number?,xShift:number?)
 local n=steps or 40
 for _,s in {-1,1} do
  local last=Vector3.new((xShift or 0)+s*span/2,spring,z)
  for i=1,n do
   local t=math.pi/3*i/n
   local point=Vector3.new((xShift or 0)+s*(-span/2+span*math.cos(t)),spring+span*math.sin(t),z)
   beam(parent,name,last,point,width,depth,color,material);last=point
  end
 end
end
local function archY(x:number,span:number,spring:number):number
 return spring+math.sqrt(math.max(0,span*span-(math.abs(x)+span/2)^2))
end
local function ring(parent:Instance,name:string,c:Vector3,r:number,width:number)
 for i=0,23 do
  local a=i*math.pi/12;local b=(i+1)*math.pi/12
  beam(parent,name,c+Vector3.new(math.cos(a)*r,math.sin(a)*r,0),c+Vector3.new(math.cos(b)*r,math.sin(b)*r,0),width,.18,C.trim,Enum.Material.Limestone)
 end
end
function A.EnsureMaster():Model
 local assets=S:FindFirstChild("WorldAssets")
 if not assets then assets=Instance.new("Folder");assets.Name="WorldAssets";assets.Parent=S end
 local kit=assets:FindFirstChild("VigilKit")
 if not kit then kit=Instance.new("Folder");kit.Name="VigilKit";kit.Parent=assets end
 local old=kit:FindFirstChild("NorthThreshold")
 if old then return old::Model end
 local m=model(kit,"NorthThreshold")
 m:SetAttribute("Status","Art study: owner review pending")
 m:SetAttribute("Version",4)
 local wall=model(m,"StructuralMasonry")
 local solid=require(script.Parent.VigilStonework).Wall(wall,HALF,HEIGHT,16,26,true)
 local door=model(m,"PointedPortal")
 arch(door,"InnerRebate",16,SPRING,1.25,.68,3.4,C.dark,Enum.Material.Basalt)
 arch(door,"InnerRoll",16.5,SPRING,-.52,.42,.75,C.edge,Enum.Material.Limestone)
 arch(door,"Voussoir",17.6,SPRING,-.92,1.05,1.4,C.trim,Enum.Material.Limestone)
 arch(door,"RecessedFillet",18.9,SPRING,-1.0,.18,.35,C.dark,Enum.Material.Basalt)
 arch(door,"OuterRoll",19.45,SPRING,-1.35,.45,.7,C.edge,Enum.Material.Limestone)
 arch(door,"HoodMould",20.15,SPRING,-1.05,.4,1.2,C.trim,Enum.Material.Limestone)
 for _,s in {-1,1} do
  part(door,"Reveal",Vector3.new(.5,SPRING,2.8),CFrame.new(s*8.12,SPRING/2,.15),C.dark,Enum.Material.Basalt,true)
  for j,spec in {{8.25,.22,-.52},{8.85,.42,-.92},{9.72,.24,-1.35},{10.15,.22,-1.05}} do
   local x,r,z=spec[1],spec[2],spec[3]
   cyl(door,"JambColonnette",r,SPRING-.8,Vector3.new(s*x,SPRING/2+.1,z),C.trim,Enum.Material.Limestone)
   for _,h in {.45,SPRING-.2} do
    cyl(door,"Collar",r+.12,.25,Vector3.new(s*x,h,z),C.edge,Enum.Material.Limestone)
   end
  end
  part(door,"JambFoot",Vector3.new(3.2,.35,3.5),CFrame.new(s*9.65,.175,-.5),C.trim,Enum.Material.Limestone,true)
 end
 -- Full-height structural piers: these receive the upper wall and cornice.
 local piers=model(m,"ClusteredPiers")
 for _,s in {-1,1} do
  local x=s*14.05
  part(piers,"PierCore",Vector3.new(2.5,42,2.2),CFrame.new(x,22,-.65),C.stone,Enum.Material.Limestone,true)
  for _,q in {{0,-2.1,.55},{-.86,-1.75,.4},{.86,-1.75,.4},{-1.1,-.7,.32},{1.1,-.7,.32}} do
   cyl(piers,"Shaft",q[3],40.5,Vector3.new(x+q[1],22,q[2]),C.trim,Enum.Material.Limestone)
   cyl(piers,"ShaftFoot",q[3]+.16,.5,Vector3.new(x+q[1],1.2,q[2]),C.edge,Enum.Material.Limestone)
   cyl(piers,"CapitalAbacus",q[3]+.17,.42,Vector3.new(x+q[1],42.3,q[2]),C.edge,Enum.Material.Limestone)
  end
  for j,w in {3.8,3.5,3.15} do
   part(piers,"PlinthCourse",Vector3.new(w,.32,3.7-j*.22),CFrame.new(x,.16+(j-1)*.32,-.8),C.trim,Enum.Material.Limestone,true)
  end
  part(piers,"Capital",Vector3.new(3.8,.5,3.2),CFrame.new(x,42.8,-.85),C.trim,Enum.Material.Limestone)
 end
 local gallery=model(m,"GalleryEnds")
 for _,s in {-1,1} do
  local left=10.8;local right=HALF;local mid=(left+right)/2
  part(gallery,"Balcony",Vector3.new(right-left,1,6),CFrame.new(s*mid,18,-3),C.wood,Enum.Material.WoodPlanks,true)
  for _,yy in {17.38,17.65,18.55} do
   part(gallery,"FasciaMould",Vector3.new(right-left,.2,.45),CFrame.new(s*mid,yy,-6.15),C.trim,Enum.Material.Limestone)
  end
  for _,yy in {18.9,21.3} do
   part(gallery,"IronRail",Vector3.new(right-left,.14,.16),CFrame.new(s*mid,yy,-6),C.iron,Enum.Material.Metal)
   part(gallery,"ReturnRail",Vector3.new(.16,.14,5.7),CFrame.new(s*left,yy,-3.15),C.iron,Enum.Material.Metal)
  end
  for j=0,7 do
   local xx=left+.18+(right-left-.36)*j/7
   part(gallery,"Baluster",Vector3.new(.1,2.4,.1),CFrame.new(s*xx,20.1,-6),C.iron,Enum.Material.Metal)
   if j<7 then
    local cx=s*(xx+(right-left-.36)/14)
    arch(gallery,"RailLancet",(right-left-.36)/7,20.25,-6,.065,.09,C.iron,Enum.Material.Metal,10,cx)
   end
  end
  for j=0,5 do
   part(gallery,"ReturnBaluster",Vector3.new(.1,2.4,.1),CFrame.new(s*left,20.1,-.4-j*1.05),C.iron,Enum.Material.Metal)
  end
  for _,xx in {left+.6,right-.6} do
   beam(gallery,"StoneCorbel",Vector3.new(s*xx,14.2,-1),Vector3.new(s*xx,17.3,-5.5),.6,.7,C.trim,Enum.Material.Limestone)
  end
 end
 local window=model(m,"UpperLancet")
 for _,s in {-1,1} do
  part(window,"WindowReveal",Vector3.new(.35,5,2.5),CFrame.new(s*3.3,32.5,1.25),C.dark,Enum.Material.Basalt)
  part(window,"WindowJamb",Vector3.new(.38,5,.7),CFrame.new(s*3.6,32.5,-.35),C.trim,Enum.Material.Limestone)
 end
 arch(window,"RevealArch",6.4,35,1.1,.4,2.7,C.dark,Enum.Material.Basalt,32)
 arch(window,"WindowMould",7.2,35,-.35,.55,.7,C.trim,Enum.Material.Limestone,32)
 arch(window,"DripEdge",8.2,35,-.15,.18,.5,C.edge,Enum.Material.Limestone,32)
 part(window,"Sill",Vector3.new(8,.45,3.1),CFrame.new(0,29.9,.8),C.trim,Enum.Material.Limestone)
 -- Individual glass strips follow the pointed aperture; no rectangular neon sheet.
 for i=1,32 do
  local x=-3.2+(i-.5)*.2;local top=archY(x,6.4,35)
  local p=part(window,"BlueGreyGlass",Vector3.new(.2,top-30,.12),CFrame.new(x,(top+30)/2,1.75),Color3.fromRGB(91,108,134),Enum.Material.Glass)
  p.Transparency=.32;p.CastShadow=false
 end
 for _,x in {-1.6,0,1.6} do
  local top=archY(x,6.4,35)
  part(window,"StoneMullion",Vector3.new(.14,top-30,.24),CFrame.new(x,(top+30)/2,1.45),C.trim,Enum.Material.Limestone)
 end
 for _,y in {32.2,35.1} do part(window,"Transom",Vector3.new(6.3,.12,.24),CFrame.new(0,y,1.45),C.trim,Enum.Material.Limestone) end
 for _,x in {-1.55,1.55} do arch(window,"Tracery",3.05,35,1.44,.14,.25,C.trim,Enum.Material.Limestone,20,x) end
 local details=model(m,"StoneAndTimberDetails")
 for _,s in {-1,1} do
  -- Blind quatrefoil ornaments above the gallery. Recessed centres keep their relief readable.
  local x=s*9.3
  part(details,"RecessPanel",Vector3.new(5.2,7,.22),CFrame.new(x,35.6,-.12),C.dark,Enum.Material.Basalt)
  local last:Vector3?=nil
  for i=0,96 do
   local a=i*math.pi*2/96;local r=1.3+.34*math.cos(a*4)
   local p=Vector3.new(x+math.cos(a)*r,35.6+math.sin(a)*r,-.32)
   if last then beam(details,"QuatrefoilOutline",last,p,.16,.18,C.trim,Enum.Material.Limestone) end
   last=p
  end
  for _,y in {31.9,39.3} do part(details,"PanelTrim",Vector3.new(5.65,.2,.4),CFrame.new(x,y,-.25),C.trim,Enum.Material.Limestone) end
  -- Deep, small wood panels below the galleries, not a uniformly decorated facade.
  local px=s*12.9
  part(details,"TimberPanel",Vector3.new(6,11,.35),CFrame.new(px,6,-.3),C.wood,Enum.Material.Wood)
  for _,off in {-2.7,0,2.7} do part(details,"TimberStile",Vector3.new(.12,10.6,.18),CFrame.new(px+off,6,-.57),Color3.fromRGB(68,51,44),Enum.Material.Wood) end
  for _,y in {.7,2.2,11.3} do part(details,"TimberRail",Vector3.new(5.6,.14,.18),CFrame.new(px,y,-.58),Color3.fromRGB(68,51,44),Enum.Material.Wood) end
 end
 -- Restrained fixture groups, wax and metal read separately from their tiny flames.
 local fixtures=model(m,"CandleBrackets")
 for _,s in {-1,1} do
  local x=s*11.45
  part(fixtures,"Backplate",Vector3.new(.75,2,.18),CFrame.new(x,9.7,-1.05),C.iron,Enum.Material.Metal)
  beam(fixtures,"Arm",Vector3.new(x,9,-1.2),Vector3.new(x,9.6,-3.3),.14,.14,C.iron,Enum.Material.Metal)
  part(fixtures,"CandleTray",Vector3.new(2.2,.14,.7),CFrame.new(x,9.65,-3.3),C.iron,Enum.Material.Metal)
  for j=-1,1 do
   local y=10.15+(if j==0 then .2 else 0)
   cyl(fixtures,"Wax",.11,.8,Vector3.new(x+j*.65,y,-3.3),C.wax,Enum.Material.SmoothPlastic)
   local flame=part(fixtures,"Flame",Vector3.new(.09,.22,.09),CFrame.new(x+j*.65,y+.52,-3.3),Color3.fromRGB(255,194,112),Enum.Material.Neon)
   flame.Shape=Enum.PartType.Ball;flame.CastShadow=false
   if j==0 then
    local l=Instance.new("PointLight");l.Color=Color3.fromRGB(255,183,108);l.Brightness=.8;l.Range=16;l.Shadows=true;l.Parent=flame
   end
  end
 end
 for _,spec in {{43.5,.35,.9},{44,.45,1.5},{44.55,.5,1.8}} do part(details,"Cornice",Vector3.new(HALF*2,spec[2],spec[3]),CFrame.new(0,spec[1],-.25),C.trim,Enum.Material.Limestone) end
 for i=0,19 do
  local x=-HALF+.65+i*(HALF*2-1.3)/19
  part(details,"CorniceDentil",Vector3.new(.42,.55,.5),CFrame.new(x,43.05,-.35),C.trim,Enum.Material.Limestone)
 end
 -- Yard-facing stone returns: same portal, not an unfinished back of a facade.
 local exterior=model(m,"YardFacingStonework")
 arch(exterior,"OuterVoussoir",17.7,SPRING,3.05,1.2,1.2,C.trim,Enum.Material.Limestone)
 arch(exterior,"HoodMould",20.1,SPRING,3.3,.4,.8,C.edge,Enum.Material.Limestone)
 arch(exterior,"WindowSurround",7.3,35,2.9,.5,.8,C.trim,Enum.Material.Limestone,32)
 part(exterior,"WindowSill",Vector3.new(8,.45,1.6),CFrame.new(0,29.9,3),C.trim,Enum.Material.Limestone)
 for _,s in {-1,1} do
  cyl(exterior,"DoorShaft",.47,SPRING-.6,Vector3.new(s*8.85,SPRING/2,3.05),C.trim,Enum.Material.Limestone)
  part(exterior,"ShaftBase",Vector3.new(2,.6,1.8),CFrame.new(s*8.85,.3,3.05),C.trim,Enum.Material.Limestone,true)
  part(exterior,"WindowJamb",Vector3.new(.5,5,.8),CFrame.new(s*3.65,32.5,2.9),C.trim,Enum.Material.Limestone)
  local xx=s*14.05
  part(exterior,"ButtressBody",Vector3.new(2.6,39,2.2),CFrame.new(xx,19.5,3.6),C.stone,Enum.Material.Limestone,true)
  for j=0,2 do
   part(exterior,"ButtressOffset",Vector3.new(3.7-j*.4,.55,3.4-j*.45),CFrame.new(xx,1+j*12.5,3.5),C.trim,Enum.Material.Limestone)
  end
  part(exterior,"ButtressCap",Vector3.new(3.5,.7,3),CFrame.new(xx,39.2,3.5),C.trim,Enum.Material.Limestone)
 end
 part(exterior,"UpperCornice",Vector3.new(HALF*2,.5,1.4),CFrame.new(0,44.4,2.7),C.trim,Enum.Material.Limestone)
 -- A walkable flush threshold, not steps or a new obstacle in the route.
 part(details,"WornThreshold",Vector3.new(15.5,.12,4.4),CFrame.new(0,.06,.2),Color3.fromRGB(95,94,96),Enum.Material.Limestone,true)
 m.WorldPivot=CFrame.identity
 return m
end
function A.Apply(root:Instance)
 local h=root:FindFirstChild("GreatHall");assert(h,"Missing GreatHall")
 local old=h:FindFirstChild("NorthThreshold");if old then old:Destroy() end
 for _,p in h:GetChildren() do if p.Name=="Wall4" or p.Name=="Wall4Lintel" or p.Name=="Gallery4" then p:Destroy() end end
 local clone=A.EnsureMaster():Clone();clone.Name="NorthThreshold";clone:PivotTo(FRAME);clone.Parent=h
 return clone
end
return A

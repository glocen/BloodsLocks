--!strict
-- The Vigil manor hall: two usable storeys, timber floors, red carpets and twin stairs.
-- Edit-time only. North stays open to the outdoor training yard.
local S=game:GetService("ServerStorage")
local M={}
local R=40
local HALF=R*math.tan(math.pi/8)+.2
local C={wood=Color3.fromRGB(68,46,35),edge=Color3.fromRGB(104,71,47),darkWood=Color3.fromRGB(39,29,28),red=Color3.fromRGB(79,15,25),border=Color3.fromRGB(133,91,53),stone=Color3.fromRGB(99,101,106),iron=Color3.fromRGB(27,29,33),wax=Color3.fromRGB(185,157,115)}
local function group(p:Instance,n:string):Model local m=Instance.new("Model");m.Name=n;m.Parent=p;return m end
local function block(p:Instance,n:string,s:Vector3,cf:CFrame,c:Color3,mat:Enum.Material,collide:boolean?):Part
 local b=Instance.new("Part");b.Name=n;b.Anchored=true;b.Size=s;b.CFrame=cf;b.Color=c;b.Material=mat;b.TopSurface=Enum.SurfaceType.Smooth;b.BottomSurface=Enum.SurfaceType.Smooth;b.CanCollide=collide==true;b.CanTouch=false;b.CanQuery=collide==true;b.Parent=p;return b
end
local function bar(p:Instance,n:string,a:Vector3,b:Vector3,w:number,d:number,c:Color3,mat:Enum.Material)
 return block(p,n,Vector3.new(w,(b-a).Magnitude+.01,d),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(math.pi/2,0,0),c,mat)
end
local function arch(p:Instance,n:string,span:number,spring:number,z:number,w:number,d:number)
 for _,s in {-1,1} do
  local previous=Vector3.new(s*span/2,spring,z)
  for i=1,32 do
   local a=math.pi/3*i/32;local nextPoint=Vector3.new(s*(-span/2+span*math.cos(a)),spring+span*math.sin(a),z)
   bar(p,n,previous,nextPoint,w,d,C.stone,Enum.Material.Limestone);previous=nextPoint
  end
 end
end
local function octagon(p:Instance,n:string,r:number,h:number,y:number,mat:Enum.Material,c:Color3):BasePart
 local a=block(p,"OperandA",Vector3.new(r*2,h,r*2),CFrame.new(0,y,0),c,mat)
 local b=block(p,"OperandB",Vector3.new(r*2,h,r*2),CFrame.new(0,y,0)*CFrame.Angles(0,math.pi/4,0),c,mat)
 local result=a:IntersectAsync({b},Enum.CollisionFidelity.PreciseConvexDecomposition,Enum.RenderFidelity.Precise)::BasePart
 result.Name=n;result.Anchored=true;result.Material=mat;result.Color=c;result.CanCollide=true;result.CanTouch=false;result.CanQuery=true
 if result:IsA("PartOperation") then result.UsePartColor=true end
 result.Parent=p;a:Destroy();b:Destroy();return result
end
local function candle(p:Instance,x:number,y:number,z:number,h:number,lit:boolean)
 local wax=block(p,"WaxCandle",Vector3.new(.23,h,.23),CFrame.new(x,y+h/2,z),C.wax,Enum.Material.SmoothPlastic);wax.Shape=Enum.PartType.Cylinder;wax.Size=Vector3.new(h,.23,.23);wax.CFrame=CFrame.new(x,y+h/2,z)*CFrame.Angles(0,0,math.pi/2)
 local f=block(p,"SmallFlame",Vector3.new(.08,.21,.08),CFrame.new(x,y+h+.1,z),Color3.fromRGB(255,193,112),Enum.Material.Neon);f.Shape=Enum.PartType.Ball;f.CastShadow=false
 if lit then local l=Instance.new("PointLight");l.Color=Color3.fromRGB(255,178,103);l.Brightness=.5;l.Range=18;l.Shadows=false;l.Parent=f end
end
local function trimRunner(p:Instance,cf:CFrame,width:number,length:number)
 block(p,"CrimsonWoolRunner",Vector3.new(width,.055,length),cf,C.red,Enum.Material.Fabric)
 for _,s in {-1,1} do
  block(p,"WovenBorder",Vector3.new(.11,.013,length-.2),cf*CFrame.new(s*(width/2-.24),.034,0),C.border,Enum.Material.Fabric)
  block(p,"DarkSelvedge",Vector3.new(.07,.013,length-.1),cf*CFrame.new(s*(width/2-.08),.034,0),C.darkWood,Enum.Material.Fabric)
 end
end
function M.EnsureMaster():Model
 local kit=S.WorldAssets.VigilKit
 local existing=kit:FindFirstChild("ManorHall")
 if existing then return existing::Model end
 local master=group(kit,"ManorHall");master:SetAttribute("Status","Two-storey manor build; art review pending")
 local fresh=script.Parent.VigilStonework:Clone();fresh.Name="StoneworkColdBuild";fresh.Parent=script.Parent
 local stone=require(fresh);fresh:Destroy()
 local north=kit.NorthThreshold
 local bays=group(master,"ArchitecturalBays")
 for k=0,7 do
  if k~=4 then
   local bay=group(bays,"Bay"..k)
   local isWing=k==2 or k==6
   local isDoor=k==0 or isWing
   stone.Wall(bay,HALF,45,if isDoor then 12 else nil,if isDoor then 16 else nil,not isWing,isWing)
   for _,name in {"ClusteredPiers","StoneAndTimberDetails","CandleBrackets"} do local c=north[name]:Clone();c.Parent=bay end
   if not isWing then local c=north.UpperLancet:Clone();c.Parent=bay end
   if isDoor then
    local spring=16-12*math.sqrt(3)/2
    arch(bay,"GroundDoorRebate",12,spring,-.35,.4,.9)
    arch(bay,"GroundDoorArch",13.3,spring,-.9,.8,1.3)
    for _,s in {-1,1} do
     block(bay,"DoorJamb",Vector3.new(.75,spring,1.4),CFrame.new(s*6.65,spring/2,-.9),C.stone,Enum.Material.Limestone,true)
     block(bay,"JambBase",Vector3.new(1.2,.4,1.7),CFrame.new(s*6.65,.2,-.9),C.stone,Enum.Material.Limestone,true)
    end
   else
    local panelling=group(bay,"TimberWainscot")
    for j=-2,2 do
     local x=j*3.9
     block(panelling,"Recess",Vector3.new(3.45,10.8,.28),CFrame.new(x,6,-.3),C.darkWood,Enum.Material.Wood)
     for _,s in {-1,1} do block(panelling,"Stile",Vector3.new(.14,11,.24),CFrame.new(x+s*1.74,6,-.58),C.edge,Enum.Material.Wood) end
     for _,y in {.55,2.1,11.5} do block(panelling,"PanelRail",Vector3.new(3.6,.16,.22),CFrame.new(x,y,-.58),C.edge,Enum.Material.Wood) end
    end
    local seat=group(bay,"WindowSettle")
    block(seat,"TimberSeat",Vector3.new(13,1.7,2.7),CFrame.new(0,.85,-2.2),C.darkWood,Enum.Material.Wood,true)
    block(seat,"LeatherCushion",Vector3.new(12.7,.3,2.6),CFrame.new(0,1.85,-2.2),Color3.fromRGB(57,27,29),Enum.Material.Fabric)
    block(seat,"SeatBack",Vector3.new(13,1.6,.35),CFrame.new(0,2.5,-1),C.wood,Enum.Material.Wood)
   end
   if isWing then
    local spring=32-12*math.sqrt(3)/2
    arch(bay,"UpperDoor",12,spring,-.35,.4,.8)
    arch(bay,"UpperDoorMould",13.3,spring,-.65,.6,1)
    for _,s in {-1,1} do block(bay,"UpperJamb",Vector3.new(.6,spring-18,1),CFrame.new(s*6.65,(spring+18)/2,-.65),C.stone,Enum.Material.Limestone) end
    -- Remove the flanking blind ornaments where they would crowd the upper landing.
   end
   if not isWing then
    local holder=block(bay,"MoonlightFixture",Vector3.one*.15,CFrame.new(0,35,-2)*CFrame.Angles(math.rad(-42),0,0),C.iron,Enum.Material.Metal);holder.Transparency=1
    local l=Instance.new("SpotLight");l.Face=Enum.NormalId.Front;l.Angle=45;l.Range=52;l.Color=Color3.fromRGB(149,164,203);l.Brightness=1.6;l.Shadows=false;l.Parent=holder
   end
   bay.WorldPivot=CFrame.identity;bay:PivotTo(CFrame.Angles(0,k*math.pi/4,0)*CFrame.new(0,0,R))
  end
 end
 -- Individual floor boards, restrained deterministic colour variation and actual joints.
 local floor=group(master,"TimberGroundFloor")
 local row=0
 for z=-39,39,2 do
  row+=1;local xmax=math.min(40,40*math.sqrt(2)-math.abs(z)-.95)
  local x=-xmax;local j=0
  while x<xmax-.1 do
   j+=1;local length=math.min(8+((row+j*3)%5),xmax-x)
   if length>.08 then
    local t=((row*3+j*7)%9)-4
    block(floor,"OakBoard",Vector3.new(length-.025,.4,1.975),CFrame.new(x+length/2,-.18,z),Color3.fromRGB(67+t,46+t*.7,35+t*.5),Enum.Material.Wood,true)
   end
   x+=length
  end
 end
 local rugs=group(master,"CrimsonCarpets")
 trimRunner(rugs,CFrame.new(0,.055,0),9.5,78)
 for _,s in {-1,1} do trimRunner(rugs,CFrame.new(s*24,.055,0)*CFrame.Angles(0,math.pi/2,0),6.5,29) end
 -- A real second-storey gallery. North central section stays open over the grand portal.
 local gallery=group(master,"UpperFloor")
 local outside=octagon(gallery,"GalleryOperand",40,1,18,Enum.Material.WoodPlanks,C.wood)
 local inside=octagon(gallery,"AtriumVoid",29.5,4,18,Enum.Material.WoodPlanks,C.wood)
 local channel=block(gallery,"NorthVoid",Vector3.new(21.6,4,19),CFrame.new(0,18,-36),C.wood,Enum.Material.Wood)
 local stairCuts={inside,channel}
 for _,side in {-1,1} do table.insert(stairCuts,block(gallery,"StairwellVoid",Vector3.new(27.8,5,8.6),CFrame.new(side*21.4,18,16),C.wood,Enum.Material.Wood)) end
 local ring=outside:SubtractAsync(stairCuts,Enum.CollisionFidelity.PreciseConvexDecomposition,Enum.RenderFidelity.Precise)::BasePart
 ring.Name="UsableUpperGallery";ring.Anchored=true;ring.Material=Enum.Material.WoodPlanks;ring.Color=C.wood;ring.CanCollide=true;ring.CanQuery=true;ring.Parent=gallery;if ring:IsA("PartOperation")then ring.UsePartColor=true end
 outside:Destroy();for _,operand in stairCuts do operand:Destroy() end
 for k=0,7 do
  if k~=4 then
   local cf=CFrame.Angles(0,k*math.pi/4,0)*CFrame.new(0,0,29.6)
   local width=2*29.6*math.tan(math.pi/8)
   for _,y in {17.4,18.4} do block(gallery,"GalleryFascia",Vector3.new(width,.25,.5),cf*CFrame.new(0,y,0),C.edge,Enum.Material.Wood) end
   local n=math.floor(width/.85)
   for i=0,n do
    local x=-width/2+i*width/n
    local position=(cf*CFrame.new(x,0,0)).Position
    local stairOpening=math.abs(position.X)<35.3 and math.abs(position.X)>7.5 and position.Z>11.6 and position.Z<20.4
    if not stairOpening then
     block(gallery,"IronBaluster",Vector3.new(.1,2.65,.1),cf*CFrame.new(x,20.2,0),C.iron,Enum.Material.Metal)
     for _,y in {18.95,21.5} do block(gallery,"Handrail",Vector3.new(width/n+.02,.15,.17),cf*CFrame.new(x,y,0),C.iron,Enum.Material.Metal) end
     block(gallery,"RailingCollision",Vector3.new(width/n+.02,3,.15),cf*CFrame.new(x,20,0),C.iron,Enum.Material.Metal,true).Transparency=1
    end
   end
   -- Narrow crimson gallery carpet follows each wall away from the inner railing.
   if k~=1 and k~=7 then trimRunner(rugs,CFrame.Angles(0,k*math.pi/4,0)*CFrame.new(0,18.56,35.4)*CFrame.Angles(0,math.pi/2,0),4.4,2*35.4*math.tan(math.pi/8)-.15) end
  end
 end
 -- Two formal stair flights rise from the south half onto the gallery.
 local stairs=group(master,"TwinManorStairs")
 for _,side in {-1,1} do
  local flight=group(stairs,if side<0 then "WestStair" else "EastStair")
  for i=1,30 do
   local x=side*(8+(i-.5)*.9);local y=i*.6
   block(flight,"ClosedRiser",Vector3.new(.9,y,8),CFrame.new(x,y/2,16),C.darkWood,Enum.Material.Wood,true)
   block(flight,"OakTread",Vector3.new(.98,.12,8.1),CFrame.new(x,y+.035,16),C.edge,Enum.Material.Wood,true)
   block(flight,"CarpetTread",Vector3.new(.9,.025,3.5),CFrame.new(x,y+.111,16),C.red,Enum.Material.Fabric)
   block(flight,"CarpetRiser",Vector3.new(.026,.6,3.5),CFrame.new(side*(8+(i-1)*.9),y-.3,16),C.red,Enum.Material.Fabric)
  end
  for _,s in {-1,1} do
   local z=16+s*4.2
   bar(flight,"StairHandrail",Vector3.new(side*8,3.4,z),Vector3.new(side*35,21.4,z),.2,.25,C.edge,Enum.Material.Wood)
   for i=0,10 do
    local x=side*(8+i*2.7);local base=i*1.8
    block(flight,"TurnedBaluster",Vector3.new(.15,3.3,.15),CFrame.new(x,base+1.7,z),C.darkWood,Enum.Material.Wood)
   end
   for _,spec in {{8,0},{35,18}} do
    block(flight,"NewelPost",Vector3.new(.5,3.8,.5),CFrame.new(side*spec[1],spec[2]+1.9,z),C.darkWood,Enum.Material.Wood,true)
    local cap=block(flight,"NewelCap",Vector3.new(.65,.65,.65),CFrame.new(side*spec[1],spec[2]+3.95,z),C.edge,Enum.Material.Wood);cap.Shape=Enum.PartType.Ball
   end
  end
 end
 -- Gallery guard rails follow the stairwell edges and leave the top landing open.
 for _,side in {-1,1} do
  for _,z in {11.6,20.4} do
   block(gallery,"StairwellGuard",Vector3.new(10,3,.15),CFrame.new(side*30,20,z),C.iron,Enum.Material.Metal,true).Transparency=1
   block(gallery,"StairwellHandrail",Vector3.new(10,.2,.2),CFrame.new(side*30,21.5,z),C.edge,Enum.Material.Wood)
   for i=0,11 do block(gallery,"StairwellBaluster",Vector3.new(.1,2.8,.1),CFrame.new(side*(25+i*10/11),20.1,z),C.iron,Enum.Material.Metal) end
  end
 end
 -- Both wings gain real upper rooms connected through the gallery doors.
 local rooms=group(master,"TwoStoreyWings")
 for _,side in {-1,1} do
  for _,level in {0,18.5} do
   for z=-11,11,2 do
    for i=0,5 do
     local start=42.5+i*50/6
     block(rooms,"WingOakBoard",Vector3.new(50/6-.025,.35,1.975),CFrame.new(side*(start+25/6),level-.15,z),C.wood,Enum.Material.Wood,true)
    end
   end
   trimRunner(rooms,CFrame.new(side*67.5,level+.055,0)*CFrame.Angles(0,math.pi/2,0),6.5,47)
  end
  if side<0 then
   for j=0,3 do
    local x=-(50+j*11)
    block(rooms,"ArchiveBack",Vector3.new(9,11,.5),CFrame.new(x,24,-10.8),C.darkWood,Enum.Material.Wood,true)
    for _,y in {18.7,21.4,24.1,26.8,29.5} do block(rooms,"ArchiveShelf",Vector3.new(9,.2,2),CFrame.new(x,y,-10),C.edge,Enum.Material.Wood,true) end
    for row=0,3 do for i=0,9 do
     local h=1.4+((i+j+row)%4)*.22
     local colors={Color3.fromRGB(65,26,33),Color3.fromRGB(41,46,47),Color3.fromRGB(105,88,64)}
     block(rooms,"BoundVolume",Vector3.new(.42,h,1.1),CFrame.new(x-3.8+i*.77,18.85+row*2.7+h/2,-9.9),colors[(i+row)%3+1],Enum.Material.Fabric)
    end end
   end
   block(rooms,"ArchiveReadingTable",Vector3.new(12,1,4),CFrame.new(-76,21.2,7),C.wood,Enum.Material.Wood,true)
   for _,x in {-81,-71} do block(rooms,"TableLeg",Vector3.new(.5,2.5,.5),CFrame.new(x,19.75,7),C.darkWood,Enum.Material.Wood,true) end
   candle(rooms,-76,21.75,7,1,true)
  else
   for j=0,2 do
    local x=53+j*14
    block(rooms,"UpperWorkBench",Vector3.new(10,.6,4),CFrame.new(x,21.6,8),C.wood,Enum.Material.Wood,true)
    for _,s in {-1,1} do block(rooms,"BenchLeg",Vector3.new(.6,3,.6),CFrame.new(x+s*4.2,20,8),C.darkWood,Enum.Material.Wood,true) end
    block(rooms,"FoldedCrimsonCloth",Vector3.new(3,.16,2.3),CFrame.new(x+1.5,22,8),C.red,Enum.Material.Fabric)
    block(rooms,"CuttingBoard",Vector3.new(3,.12,2),CFrame.new(x-2,21.98,8),Color3.fromRGB(105,81,52),Enum.Material.Wood)
    candle(rooms,x-4,21.95,8,.85,true)
   end
  end
 end
 -- A manor ceiling with deep timber coffers and a central oculus.
 local ceiling=group(master,"CofferedCeiling")
 local roof=octagon(ceiling,"CeilingMass",40,.8,45.2,Enum.Material.Wood,C.darkWood)
 local oculus=octagon(ceiling,"OculusCut",5.5,5,45.2,Enum.Material.Wood,C.darkWood)
 local cut=roof:SubtractAsync({oculus},Enum.CollisionFidelity.Default,Enum.RenderFidelity.Precise)::BasePart;cut.Name="TimberCeiling";cut.Anchored=true;cut.Material=Enum.Material.Wood;cut.Color=C.darkWood;cut.Parent=ceiling;if cut:IsA("PartOperation")then cut.UsePartColor=true end
 roof:Destroy();oculus:Destroy()
 for _,x in {-28,-14,14,28} do
  local l=2*math.min(39,40*math.sqrt(2)-math.abs(x)-1)
  block(ceiling,"PrincipalBeam",Vector3.new(.8,1.25,l),CFrame.new(x,44.2,0),C.wood,Enum.Material.Wood)
  block(ceiling,"CrossBeam",Vector3.new(l,1,.7),CFrame.new(0,44.35,x),C.wood,Enum.Material.Wood)
 end
 -- Replace the neon placeholder with the same named Blood Table station, our octagonal stone map.
 local tableModel=group(master,"BloodTable")
 octagon(tableModel,"Foot",8.8,.45,.225,Enum.Material.Basalt,Color3.fromRGB(42,40,44))
 octagon(tableModel,"CarvedPlinth",8,2.2,1.55,Enum.Material.Limestone,Color3.fromRGB(69,67,72))
 octagon(tableModel,"TableTop",8.45,.35,2.825,Enum.Material.Limestone,Color3.fromRGB(101,96,94))
 octagon(tableModel,"ReliefBed",7.5,.08,3.04,Enum.Material.Basalt,Color3.fromRGB(46,44,49))
 for k=0,7 do
  local a=k*math.pi/4;local cf=CFrame.Angles(0,a,0)*CFrame.new(0,3.07,8.1)
  block(tableModel,"BronzeInlay",Vector3.new(6.6,.05,.12),cf,C.border,Enum.Material.Metal)
  local x=math.sin(a)*7.7;local z=math.cos(a)*7.7
  candle(tableModel,x,3.12,z,.65+(k%3)*.2,k%3==0)
 end
 local map=group(tableModel,"CarvedMap")
 for _,r in {{-3,-2,3.4,1.8,.2},{-1,1,4.8,2.1,-.3},{3,2,2.1,3,.4},{2,-3,2.7,1.8,.2}} do
  block(map,"ReliefLand",Vector3.new(r[3],.14,r[4]),CFrame.new(r[1],3.15,r[2])*CFrame.Angles(0,r[5],0),Color3.fromRGB(89,86,88),Enum.Material.Slate)
 end
 for i=-2,2 do local p=block(map,"RoofedLandmark",Vector3.new(.6,.5,.6),CFrame.new(i*1.2,3.45,math.sin(i)*2),C.stone,Enum.Material.Limestone);p.Shape=Enum.PartType.Block end
 local crown=group(master,"CandleCrown")
 for k=0,7 do
  local a=k*math.pi/4;local cf=CFrame.Angles(0,a,0)*CFrame.new(0,17,7)
  block(crown,"IronOctagon",Vector3.new(2*7*math.tan(math.pi/8),.25,.3),cf,C.iron,Enum.Material.Metal)
  local x=math.sin(a)*7;local z=math.cos(a)*7
  candle(crown,x,17.2,z,.9,k%2==0)
  if k%2==0 then bar(crown,"Suspension",Vector3.new(x,17,z),Vector3.new(x*.45,44,z*.45),.07,.07,C.iron,Enum.Material.Metal) end
 end
 master.WorldPivot=CFrame.identity
 return master
end
function M.Apply(root:Instance)
 local h=root:FindFirstChild("GreatHall");assert(h,"Great hall missing")
 local approvedMaster=M.EnsureMaster()
 local prior=h:FindFirstChild("ManorHall");if prior then prior:Destroy() end
 -- Preserve the north architectural study and spawn porch; replace the rejected generic shell.
 for _,p in h:GetChildren() do
  if p.Name~="NorthThreshold" and p.Name~="SpawnPorch" then p:Destroy() end
 end
 local copy=approvedMaster:Clone();copy.Name="ManorHall";copy:PivotTo(CFrame.new(0,0,-1000));copy.Parent=h
 local spawn=workspace:FindFirstChildOfClass("SpawnLocation")
 if spawn then spawn.Transparency=1;spawn.CanCollide=false;for _,d in spawn:GetDescendants() do if d:IsA("Decal") then d.Transparency=1 end end end
 return copy
end
return M

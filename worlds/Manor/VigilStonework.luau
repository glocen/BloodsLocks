--!strict
-- Edit-time native CSG for The Vigil. Cuts are assembled with overlapping solids.
local Stone={}
local function block(parent:Instance,size:Vector3,cf:CFrame):Part
 local p=Instance.new("Part");p.Anchored=true;p.Size=size;p.CFrame=cf;p.Parent=parent;return p
end
function Stone.Wall(parent:Instance,half:number,height:number,doorSpan:number?,doorHeight:number?,hasWindow:boolean,upperDoor:boolean?):BasePart
 local temp=Instance.new("Model");temp.Name="EditableCSGOperands";temp.Parent=parent
 local cuts={}
 local function aperture(span:number,spring:number,base:number)
  local a=block(temp,Vector3.new(9,span*2,span*2),CFrame.new(-span/2,spring,1.25)*CFrame.Angles(0,math.pi/2,0));a.Shape=Enum.PartType.Cylinder
  local b=a:Clone();b.CFrame=CFrame.new(span/2,spring,1.25)*CFrame.Angles(0,math.pi/2,0);b.Parent=temp
  -- Intersect operands sequentially. A list is combined by the CSG API before intersection.
  local lens=a:IntersectAsync({b},Enum.CollisionFidelity.PreciseConvexDecomposition,Enum.RenderFidelity.Precise)::BasePart;lens.Parent=temp
  local rise=span*math.sqrt(3)/2+.1
  local clip=block(temp,Vector3.new(span,rise+.2,9),CFrame.new(0,spring+rise/2-.1,1.25))
  local upper=lens:IntersectAsync({clip},Enum.CollisionFidelity.PreciseConvexDecomposition,Enum.RenderFidelity.Precise)::BasePart;upper.Parent=temp
  local lower=block(temp,Vector3.new(span,spring-base+.5,9),CFrame.new(0,(spring+base+.1)/2,1.25))
  table.insert(cuts,upper);table.insert(cuts,lower)
 end
 if doorSpan and doorHeight then aperture(doorSpan,doorHeight-doorSpan*math.sqrt(3)/2,0) end
 if hasWindow then aperture(6.4,35,30) end
 if upperDoor then aperture(12,32-12*math.sqrt(3)/2,18) end
 local base=block(temp,Vector3.new(half*2,height,2.5),CFrame.new(0,height/2,1.25))
 local result:BasePart
 if #cuts>0 then result=base:SubtractAsync(cuts,Enum.CollisionFidelity.PreciseConvexDecomposition,Enum.RenderFidelity.Precise)::BasePart else result=base:Clone() end
 result.Name="CarvedWall";result.Anchored=true;result.CanCollide=true;result.CanTouch=false;result.CanQuery=true;result.Color=Color3.fromRGB(79,83,89);result.Material=Enum.Material.Limestone
 if result:IsA("PartOperation") then result.UsePartColor=true end
 result.Parent=parent;temp:Destroy();return result
end
return Stone

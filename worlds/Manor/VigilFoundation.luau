--!strict
-- Terrain is voxel-smoothed and penetrated the level timber floor at Y=0.
-- Clear only occupied foundation cells; existing floor colliders stay authoritative.
-- Terrain backup records exact voxel corner for rollback. No legacy manor edits.
local F={}
function F.Apply(_root:Instance)
 local t=workspace.Terrain
 if t:GetAttribute("VigilFoundationRevision")==1 then return end
 local corner=Vector3int16.new(-37,-2,-267)
 local upper=Vector3int16.new(37,2,-227)
 local snap=t:CopyRegion(Region3int16.new(corner,upper));snap.Name="Terrain_PreVigilFoundation_20261029"
 snap:SetAttribute("CornerX",corner.X);snap:SetAttribute("CornerY",corner.Y);snap:SetAttribute("CornerZ",corner.Z)
 snap.Parent=game.ServerStorage.WorldTools.Backups
 local region=Region3.new(Vector3.new(-148,-8,-1068),Vector3.new(148,8,-908))
 local mat,occ=t:ReadVoxels(region,4);local changed=0
 for ix=1,#mat do
  local x=-148+(ix-.5)*4
  for iz=1,#mat[ix][1]do
   local z=-68+(iz-.5)*4
   local ax,az=math.abs(x),math.abs(z)
   local hall=ax<=64 and az<=64 and ax+az<=90
   local wing=ax>=60 and ax<=144 and az<=24
   local porch=ax<=20 and z>=60 and z<=88
   if hall or wing or porch then
    for iy=1,#mat[ix]do mat[ix][iy][iz]=Enum.Material.Air;occ[ix][iy][iz]=0;changed+=1 end
   end
  end
  if ix%20==0 then task.wait()end
 end
 t:WriteVoxels(region,4,mat,occ);t:SetAttribute("VigilFoundationRevision",1)
 return changed
end
return F

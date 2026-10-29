--!strict
-- Gustave kit animation sources. Body-space authoring converted through the actual R6 joint bases.
-- Action timings remain in Definitions; markers also support later SFX authoring.
-- Torso/head lean uses the opposite pitch sign from a hanging arm: positive X raises an arm forward but tilts an upright torso backward.
local rig=workspace.R6
local save=game.ServerStorage.RBX_ANIMSAVES.R6
local bases={}
for _,m in rig:GetDescendants() do if m:IsA("Motor6D") and m.Part1 then bases[m.Part1.Name]=m.C0.Rotation end end
local function r(x:number,y:number,z:number):CFrame return CFrame.Angles(math.rad(x),math.rad(y),math.rad(z)) end
local idle={Torso={4,0,0},Head={-3,0,0},["Right Arm"]={16,-5,9},["Left Arm"]={10,5,-9},["Right Leg"]={-4,0,3},["Left Leg"]={4,0,-3}}
local function frame(t:number,body:any,markers:any?)
 return {t=t,body=body,markers=markers}
end
local clips={
 Howl={
  frame(0,{Torso={7,0,0},Head={8,0,0},["Right Arm"]={24,0,16},["Left Arm"]={24,0,-16}}),
  frame(.04,{Torso={-7,0,0},Head={-18,0,0},["Right Arm"]={-12,-8,42},["Left Arm"]={-12,8,-42}},{"HowlWindowOpen"}),
  frame(.1,{Torso={-12,0,0},Head={-24,0,0},["Right Arm"]={-19,-12,52},["Left Arm"]={-19,12,-52}}),
  frame(.2,{Torso={-7,0,0},Head={-17,0,0},["Right Arm"]={-10,-8,44},["Left Arm"]={-10,8,-44}}),
  frame(.3,{Torso={-4,0,0},Head={-10,0,0},["Right Arm"]={-6,-4,35},["Left Arm"]={-6,4,-35}},{"HowlWindowClose"}),
  frame(.44,{Torso={1,0,0},Head={-3,0,0},["Right Arm"]={8,0,21},["Left Arm"]={8,0,-21}}),
  frame(.6,idle)
 },
 Bite={
  frame(0,{Torso={2,12,0},Head={0,-8,0},["Right Arm"]={23,-5,15},["Left Arm"]={48,0,-18}}),
  frame(.04,{Torso={16,9,0},Head={7,-6,0},["Right Arm"]={38,-9,22},["Left Arm"]={72,0,-19}}),
  frame(.1,{Torso={25,6,0,0,-.1,-.12},Head={10,-4,0},["Right Arm"]={45,-7,26},["Left Arm"]={88,0,-20}},{"BiteImpact"}),
  frame(.17,{Torso={30,2,0,0,-.12,-.16},Head={18,-2,0},["Right Arm"]={39,-10,26},["Left Arm"]={85,0,-23}}),
  frame(.22,{Torso={21,-3,0},Head={3,3,0},["Right Arm"]={28,-8,22},["Left Arm"]={74,3,-18}},{"BiteWindowClose"}),
  frame(.36,{Torso={7,-8,0},Head={-12,8,0},["Right Arm"]={18,0,18},["Left Arm"]={50,5,-15}}),
  frame(.52,{Torso={0,-3,0},Head={-5,4,0},["Right Arm"]={13,0,13},["Left Arm"]={27,4,-12}}),
  frame(.75,idle)
 },
 SMGBurst={
  frame(0,{Torso={4,-6,0},Head={-2,6,0},["Right Arm"]={14,-5,10},["Left Arm"]={65,0,-12}}),
  frame(.035,{Torso={4,-7,0},Head={-2,7,0},["Right Arm"]={14,-5,10},["Left Arm"]={88,0,-8}}),
  frame(.04,{Torso={2,-8,0},Head={-2,7,0},["Right Arm"]={14,-5,10},["Left Arm"]={98,0,-10}},{"Shot1"}),
  frame(.075,{Torso={4,-7,0},Head={-2,7,0},["Right Arm"]={14,-5,10},["Left Arm"]={89,0,-8}}),
  frame(.1,{Torso={2,-8,0},Head={-2,7,0},["Right Arm"]={14,-5,10},["Left Arm"]={98,0,-10}},{"Shot2"}),
  frame(.135,{Torso={4,-7,0},Head={-2,7,0},["Right Arm"]={14,-5,10},["Left Arm"]={89,0,-8}}),
  frame(.16,{Torso={2,-8,0},Head={-2,7,0},["Right Arm"]={14,-5,10},["Left Arm"]={98,0,-10}},{"Shot3"}),
  frame(.195,{Torso={4,-7,0},Head={-2,7,0},["Right Arm"]={14,-5,10},["Left Arm"]={89,0,-8}}),
  frame(.22,{Torso={2,-8,0},Head={-2,7,0},["Right Arm"]={14,-5,10},["Left Arm"]={98,0,-10}},{"Shot4"}),
  frame(.28,{Torso={4,-6,0},Head={-2,6,0},["Right Arm"]={14,-5,10},["Left Arm"]={86,0,-9}}),
  frame(.35,{Torso={4,-2,0},Head={-3,2,0},["Right Arm"]={16,-5,9},["Left Arm"]={43,2,-12}}),
  frame(.42,idle)
 },
 BloodBlade={
  frame(0,{Torso={7,13,0},Head={-3,-10,0},["Right Arm"]={76,-20,26},["Left Arm"]={24,8,-17}}),
  frame(.065,{Torso={5,27,-3},Head={-2,-22,0},["Right Arm"]={137,-17,33},["Left Arm"]={18,12,-28}}),
  frame(.12,{Torso={6,25,-2},Head={-2,-20,0},["Right Arm"]={143,-16,30},["Left Arm"]={18,12,-26}}),
  frame(.18,{Torso={14,-19,3},Head={-4,17,0},["Right Arm"]={77,14,-32},["Left Arm"]={6,-10,-35}},{"ProjectileRelease"}),
  frame(.24,{Torso={12,-28,2},Head={-3,23,0},["Right Arm"]={37,18,-45},["Left Arm"]={5,-12,-31}}),
  frame(.33,{Torso={8,-18,0},Head={-3,14,0},["Right Arm"]={24,8,-18},["Left Arm"]={10,-2,-18}}),
  frame(.5,idle)
 },
 LightBeam={
  frame(0,{Torso={5,8,0},Head={-3,-7,0},["Right Arm"]={24,-4,16},["Left Arm"]={13,4,-15}}),
  frame(.12,{Torso={2,9,-2},Head={-5,-8,0},["Right Arm"]={62,-6,15},["Left Arm"]={46,8,-20}}),
  frame(.25,{Torso={-3,6,-2},Head={-5,-5,0},["Right Arm"]={88,-3,8},["Left Arm"]={65,14,-13}}),
  frame(.35,{Torso={-6,4,0},Head={-4,-3,0},["Right Arm"]={92,-1,5},["Left Arm"]={73,16,-9}},{"ChannelStart"}),
  frame(.6,{Torso={-5,4,0},Head={-4,-3,0},["Right Arm"]={91,-1,5},["Left Arm"]={72,16,-9}}),
  frame(.9,{Torso={-6,4,0},Head={-4,-3,0},["Right Arm"]={92,-1,5},["Left Arm"]={73,16,-9}}),
  frame(1.2,{Torso={-5,4,0},Head={-4,-3,0},["Right Arm"]={91,-1,5},["Left Arm"]={72,16,-9}}),
  frame(1.55,{Torso={-6,4,0},Head={-4,-3,0},["Right Arm"]={92,-1,5},["Left Arm"]={73,16,-9}},{"ChannelEnd"}),
  frame(1.61,{Torso={0,4,0},Head={-3,-3,0},["Right Arm"]={57,-2,12},["Left Arm"]={42,10,-14}}),
  frame(1.7,idle)
 }
}
local result={}
for key in clips do assert(not save:FindFirstChild("BL_"..key),"Existing clip "..key) end
local staging=Instance.new("Folder")
for key,frames in clips do
 assert(not save:FindFirstChild("BL_"..key),"Existing authored clip: "..key)
 local seq=Instance.new("KeyframeSequence");seq.Name="BL_"..key;seq.Priority=Enum.AnimationPriority.Action2;seq.Loop=false
 seq:SetAttribute("Character","Gustave");seq:SetAttribute("Author","BloodsLocks / ChatGPT");seq:SetAttribute("SourceRevision",2)
 for _,f in frames do
  local k=Instance.new("Keyframe");k.Name="Pose";k.Time=f.t;k.Parent=seq
  local root=Instance.new("Pose");root.Name="HumanoidRootPart";root.Weight=0;root.Parent=k
  local torso=Instance.new("Pose");torso.Name="Torso";torso.Parent=root
  for _,name in {"Torso","Head","Right Arm","Left Arm","Right Leg","Left Leg"} do
   local pose=if name=="Torso" then torso else Instance.new("Pose")
   pose.Name=name;if name~="Torso" then pose.Parent=torso end
   local data=f.body[name] or idle[name] or {0,0,0}
   local basis=bases[name] or CFrame.identity
   pose.CFrame=basis:Inverse()*(CFrame.new(data[4] or 0,data[5] or 0,data[6] or 0)*r(if name=="Torso" or name=="Head" then -data[1] else data[1],data[2],data[3]))*basis
   pose.Weight=if key=="SMGBurst" and (name=="Right Leg" or name=="Left Leg") then 0 else if key=="BloodBlade" and (name=="Right Leg" or name=="Left Leg") then .25 else 1
   pose.EasingStyle=Enum.PoseEasingStyle.CubicV2;pose.EasingDirection=Enum.PoseEasingDirection.InOut
  end
  for _,name in f.markers or {} do local marker=Instance.new("KeyframeMarker");marker.Name=name;marker.Parent=k end
 end
 seq.Parent=staging;table.insert(result,{name=seq.Name,frames=#frames,duration=frames[#frames].t})
end
for _,seq in staging:GetChildren() do seq.Parent=save end
staging:Destroy()
return result

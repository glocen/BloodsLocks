from pathlib import Path
import numpy as np
from PIL import Image
import math, json
OUT=Path(r"C:\Users\gloce\AppData\Local\Temp\BloodLocks_Art\CrimsonDusk");OUT.mkdir(parents=True,exist_ok=True)
N=1024
def smooth(a,b,x):
 t=np.clip((x-a)/(b-a),0,1);return t*t*(3-2*t)
def h(x,y,z):
 return np.mod(np.sin(x*127.1+y*311.7+z*74.7)*43758.5453123,1)
def noise(x,y,z):
 ix=np.floor(x);iy=np.floor(y);iz=np.floor(z)
 fx=x-ix;fy=y-iy;fz=z-iz
 fx=fx*fx*(3-2*fx);fy=fy*fy*(3-2*fy);fz=fz*fz*(3-2*fz)
 val=np.zeros_like(x)
 for dx in (0,1):
  for dy in (0,1):
   for dz in (0,1):
    val+=h(ix+dx,iy+dy,iz+dz)*(fx if dx else 1-fx)*(fy if dy else 1-fy)*(fz if dz else 1-fz)
 return val
def fbm(x,y,z):
 return noise(x,y,z)*.53+noise(x*2+11,y*2+7,z*2+3)*.27+noise(x*4+3,y*4+17,z*4+13)*.135+noise(x*8+23,y*8+5,z*8+19)*.065
def save(name,rgb):
 a=np.asarray(np.clip(rgb,0,1)*255,dtype=np.uint8)
 if a.ndim==2:a=np.repeat(a[:,:,None],3,axis=2)
 Image.fromarray(a,'RGB').save(OUT/name)
# All faces sample the same continuous direction field. No painted seams between cube faces.
axis=np.linspace(-1,1,N,dtype=np.float32);U,V=np.meshgrid(axis,axis)
faces={'Ft':(U,-V,-np.ones_like(U)),'Bk':(-U,-V,np.ones_like(U)),'Rt':(np.ones_like(U),-V,U),'Lf':(-np.ones_like(U),-V,-U),'Up':(U,np.ones_like(U),V),'Dn':(U,-np.ones_like(U),-V)}
moon=np.array([.045,.37,-.928],dtype=np.float32);moon/=np.linalg.norm(moon)
east=np.cross([0,1,0],moon);east/=np.linalg.norm(east);north=np.cross(moon,east)
for name,(x,y,z) in faces.items():
 length=np.sqrt(x*x+y*y+z*z);x=x/length;y=y/length;z=z/length
 elev=np.maximum(y,0)
 horizon=np.array([.19,.075,.145]);zenith=np.array([.025,.038,.085])
 t=np.power(elev,.48)[:,:,None]
 rgb=horizon*(1-t)+zenith*t
 below=smooth(0,.8,-y)[:,:,None];rgb=rgb*(1-below)+np.array([.027,.021,.047])*below
 glow=np.power(np.maximum(0,x*.68-z*.73),20)*np.exp(-np.abs(y)*8)
 rgb+=glow[:,:,None]*np.array([.09,.012,.025])
 # A subdued, original blood moon over the north axis.
 dot=np.clip(x*moon[0]+y*moon[1]+z*moon[2],-1,1)
 angle=np.arccos(dot);radius=math.radians(5.8)
 alpha=1-smooth(radius-.002,radius+.002,angle)
 mx=(x*east[0]+y*east[1]+z*east[2])/math.sin(radius)
 my=(x*north[0]+y*north[1]+z*north[2])/math.sin(radius)
 terrain=fbm(mx*5+23,my*5+17,np.full_like(x,5))
 disc=np.sqrt(np.maximum(0,1-mx*mx-my*my))
 shade=np.clip(.30+.60*disc+.13*mx,.1,1)
 moonColor=(.54+.22*terrain)[:,:,None]*shade[:,:,None]*np.array([1,.25,.29])
 rgb=rgb*(1-alpha[:,:,None])+moonColor*alpha[:,:,None]
 halo=np.exp(-np.square(angle/(radius*1.8)))*.02
 rgb+=halo[:,:,None]*np.array([1,.11,.25])
 # Long violet cloud masses, with fine edges subordinate to their large silhouette.
 stretch=1.5+2.5*elev
 cloud=fbm(x*3.3+6,y*8.2+11,z*3.3-7)
 detail=noise(x*18+4,y*27+8,z*18-3)
 cover=smooth(.39,.69,cloud+.045*(detail-.5))*smooth(-.06,.16,y)
 edge=smooth(.34,.56,cloud)-smooth(.56,.73,cloud)
 cloudColor=np.array([.025,.021,.049])+edge[:,:,None]*np.array([.075,.028,.061])
 rgb=rgb*(1-cover[:,:,None]*.83)+cloudColor*cover[:,:,None]*.83
 save('VigilSky_'+name+'.png',rgb)
 print('SKY_FACE',name,flush=True)
# Tileable, longitudinal grain. Tint is supplied by the oak boards in Studio.
u,v=np.meshgrid(np.linspace(0,1,N,endpoint=False,dtype=np.float32),np.linspace(0,1,N,endpoint=False,dtype=np.float32))
phase=2*np.pi*(v*83+1.8*np.sin(2*np.pi*u)+.45*np.sin(2*np.pi*u*3+2*np.pi*v))
fiber=.5+.5*np.sin(phase)
broad=.5+.5*np.sin(2*np.pi*(v*7+.16*np.sin(2*np.pi*u)))
fine=.5+.5*np.sin(phase*3+.2*np.sin(2*np.pi*u*19))
luminance=.73+.14*broad+.07*fiber+.035*fine
save('VigilOak_Color.png',np.stack([luminance,luminance*.96,luminance*.89],axis=2))
roughness=.115+.075*fiber+.035*broad+.015*fine
save('VigilOak_Roughness.png',roughness)
save('VigilOak_JoineryRoughness.png',roughness+.24)
height=.0008*fiber+.00035*fine
dy,dx=np.gradient(height)
nx=-dx*N/8;ny=-dy*N/8;nz=np.ones_like(nx)
norm=np.sqrt(nx*nx+ny*ny+nz*nz)
save('VigilOak_Normal.png',np.stack([nx/norm*.5+.5,ny/norm*.5+.5,nz/norm*.5+.5],axis=2))
save('VigilOak_Metalness.png',np.zeros_like(u))
# Small labelled atlas for inspecting palette and face continuity without changing the assets.
thumb=Image.new('RGB',(N*3//2,N),(0,0,0))
for i,name in enumerate(('Lf','Ft','Rt','Bk','Up','Dn')):
 im=Image.open(OUT/('VigilSky_'+name+'.png'));im.thumbnail((N//2,N//2));thumb.paste(im,((i%3)*N//2,(i//3)*N//2))
thumb.save(OUT/'sky-contact-sheet.png')
(OUT/'manifest.json').write_text(json.dumps({'palette':'dark blue / violet cloud / restrained crimson horizon','wood_roughness_range':[float(roughness.min()),float(roughness.max())],'wood_metalness':0,'source':'Original math-authored texture fields; no external or paid assets','resolution':N},indent=2))
print('TEXTURES_READY',str(OUT),flush=True)

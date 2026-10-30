from pathlib import Path
import numpy as np
from PIL import Image
import math, json
OUT=Path(r"C:\Users\gloce\AppData\Local\Temp\BloodLocks_Art\VigilSky_02");OUT.mkdir(parents=True,exist_ok=True)
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
axis=np.linspace(-1,1,N,dtype=np.float32);U,V=np.meshgrid(axis,axis)
faces={'Ft':(U,-V,-np.ones_like(U)),'Bk':(-U,-V,np.ones_like(U)),'Rt':(np.ones_like(U),-V,U),'Lf':(-np.ones_like(U),-V,-U),'Up':(U,np.ones_like(U),V),'Dn':(U,-np.ones_like(U),-V)}
moon=np.array([-.48,.60,-.64],dtype=np.float32);moon/=np.linalg.norm(moon)
east=np.cross([0,1,0],moon);east/=np.linalg.norm(east);north=np.cross(moon,east)
for name,(x,y,z)in faces.items():
 length=np.sqrt(x*x+y*y+z*z);x=x/length;y=y/length;z=z/length
 elev=np.maximum(y,0);t=np.power(elev,.6)[:,:,None]
 rgb=np.array([.20,.255,.32])*(1-t)+np.array([.055,.075,.125])*t
 below=smooth(-.10,.65,-y)[:,:,None];rgb=rgb*(1-below)+np.array([.075,.09,.13])*below
 field=fbm(x*4+6,y*4+11,z*4-7)
 edge=fbm(x*15+9,y*15+4,z*15+13)
 cover=smooth(.44,.71,field+.045*(edge-.5))*smooth(-.15,.05,y)
 shade=np.clip(.10+.08*field,.09,.18)
 cloud=np.stack([shade*.93,shade*.94,shade*1.15],axis=2)
 rgb=rgb*(1-cover[:,:,None]*.43)+cloud*cover[:,:,None]*.43
 dot=np.clip(x*moon[0]+y*moon[1]+z*moon[2],-1,1);angle=np.arccos(dot);radius=math.radians(8.5)
 alpha=1-smooth(radius-.0015,radius+.0015,angle)
 mx=(x*east[0]+y*east[1]+z*east[2])/math.sin(radius);my=(x*north[0]+y*north[1]+z*north[2])/math.sin(radius)
 terrain=fbm(mx*5+23,my*5+17,np.full_like(x,5));disc=np.sqrt(np.maximum(0,1-mx*mx-my*my))
 shade=np.clip(.31+.56*disc+.12*mx,.12,1)
 colour=(.72+.24*terrain)[:,:,None]*shade[:,:,None]*np.array([1,.24,.32])
 halo=np.exp(-np.square(angle/(radius*1.55)))*.12
 rgb+=halo[:,:,None]*np.array([1,.06,.16]);rgb=rgb*(1-alpha[:,:,None])+colour*alpha[:,:,None]
 stars=(h(np.floor(x*1800),np.floor(y*1800),np.floor(z*1800))>.99996)*(1-cover)*smooth(.04,.3,y)*(1-alpha)
 rgb+=stars[:,:,None]*np.array([.38,.40,.45])
 save('VigilSky02_'+name+'.png',rgb);print('SKY02',name,flush=True)
thumb=Image.new('RGB',(N*3//2,N))
for i,name in enumerate(('Lf','Ft','Rt','Bk','Up','Dn')):
 im=Image.open(OUT/('VigilSky02_'+name+'.png'));im.thumbnail((N//2,N//2));thumb.paste(im,((i%3)*N//2,(i//3)*N//2))
thumb.save(OUT/'sky-contact-sheet.png')
# Original BloodLocks ashlar texture fields. No downloaded images or material libraries.
from pathlib import Path
from PIL import Image
import numpy as np, json
out=Path(r"C:\Users\gloce\AppData\Local\Temp\BloodLocks_Art\Vigil_MasonryStudy_01");out.mkdir(parents=True,exist_ok=True)
N=1024
u,v=np.meshgrid(np.arange(N)/N,np.arange(N)/N)
x=u*8;y=v*8
row=np.floor(y).astype(int);fy=y-row
rng=np.random.default_rng(1471)
cloud=(np.sin(2*np.pi*(3*u+2*v))+.55*np.sin(2*np.pi*(7*u-5*v))+.3*np.cos(2*np.pi*(17*u+11*v)))/1.85
fine=(np.sin(2*np.pi*(97*u+71*v))+.5*np.sin(2*np.pi*(173*u-149*v)))/1.5
mineral=(np.cos(2*np.pi*(31*u-23*v))+.4*np.sin(2*np.pi*(53*u+41*v)))/1.4
edge=np.zeros_like(u);stoneid=np.zeros_like(row)
for r in range(8):
 widths=np.array([1.6,2.25,1.9,2.25])
 widths=np.roll(widths,r%4);bounds=np.concatenate(([0],np.cumsum(widths)))
 xx=(x+(r%2)*.85+(r//2)*.27)%8
 index=np.minimum(np.searchsorted(bounds,xx,side='right')-1,3)
 dx=np.minimum(xx-bounds[index],bounds[index+1]-xx)
 dist=np.minimum(dx,np.minimum(fy,1-fy))
 select=row==r
 edge[select]=dist[select];stoneid[select]=r*4+index[select]
jitter=.0022*np.sin(2*np.pi*(u*53+v*37))+.0012*np.sin(2*np.pi*(u*121-v*87))
a=np.clip((edge+jitter-.006)/.013,0,1);a=a*a*(3-2*a)
tones=rng.uniform(-.045,.045,32)[stoneid]
# Tileable bicubic mineral variation with broad weathering-scale colour, restrained fine grain.
def value_noise(grid,seed):
 r=np.random.default_rng(seed).uniform(-1,1,(grid,grid)).astype(np.float32)
 tiled=np.tile(r,(3,3))
 im=Image.fromarray(tiled).resize((N*3,N*3),Image.Resampling.BICUBIC)
 return np.asarray(im)[N:N*2,N:N*2]
cloud=value_noise(5,341)*.65+value_noise(17,871)*.35
mineral=value_noise(51,192)
fine=value_noise(181,451)
stone=np.stack((.43+tones+.037*cloud+.011*mineral+.004*fine,.435+tones+.034*cloud+.010*mineral+.004*fine,.44+tones+.031*cloud+.009*mineral+.004*fine),axis=-1)
mortar=np.stack((.30+.006*cloud,.305+.006*cloud,.31+.006*cloud),axis=-1)
color=mortar*(1-a[...,None])+stone*a[...,None]
height=a*(.014+.00065*cloud+.00028*mineral+.00012*fine)
dx=(np.roll(height,-1,axis=1)-np.roll(height,1,axis=1))*N/16
dy=(np.roll(height,-1,axis=0)-np.roll(height,1,axis=0))*N/16
normal=np.stack((-dx,dy,np.ones_like(dx)),axis=-1);normal/=np.linalg.norm(normal,axis=-1)[...,None]
rough=np.clip(.84-.045*cloud-.035*mineral+.025*(1-a),.73,.94)
def save(name,img):
 if img.ndim==2:img=np.repeat(img[...,None],3,axis=-1)
 Image.fromarray(np.round(np.clip(img,0,1)*255).astype(np.uint8)).save(out/name)
save('VigilAshlar_Color.png',color)
save('VigilAshlar_Normal.png',normal*.5+.5)
save('VigilAshlar_Roughness.png',rough)
save('VigilAshlar_Metalness.png',np.zeros_like(u))
# Dressed trim: more even stone, very small pores, less joint-like relief.
trim=np.stack((.57+.008*cloud+.003*fine,.558+.007*cloud+.003*fine,.535+.006*cloud+.003*fine),axis=-1)
save('VigilTrim_Color.png',trim)
trimh=.00024*mineral+.00012*fine
dx=(np.roll(trimh,-1,axis=1)-np.roll(trimh,1,axis=1))*N/16;dy=(np.roll(trimh,-1,axis=0)-np.roll(trimh,1,axis=0))*N/16
tn=np.stack((-dx,dy,np.ones_like(dx)),axis=-1);tn/=np.linalg.norm(tn,axis=-1)[...,None]
save('VigilTrim_Normal.png',tn*.5+.5)
save('VigilTrim_Roughness.png',np.clip(.78-.025*cloud,.72,.86))
(out/'texture-manifest.json').write_text(json.dumps({'authorship':'Original numerical texture fields; no external material images','tile_studs':8,'course_height_studs':1,'resolution':N,'normal_format':'OpenGL tangent space','metalness':0,'albedo_contains_lighting':False},indent=2))
print('Original ashlar and trim maps saved',flush=True)

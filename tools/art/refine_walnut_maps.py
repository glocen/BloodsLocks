from pathlib import Path
from PIL import Image
import numpy as np
out=Path(r"C:\Users\gloce\AppData\Local\Temp\BloodLocks_Art\CrimsonDusk")
n=1024
u,v=np.meshgrid(np.arange(n)/n,np.arange(n)/n)
phase=2*np.pi*(v*191+.55*np.sin(2*np.pi*u)+.12*np.sin(6*np.pi*u+4*np.pi*v))
fiber=.5+.5*np.sin(phase)
fine=.5+.5*np.sin(2*np.pi*(v*389+.6*np.sin(14*np.pi*u)+.3*np.sin(6*np.pi*u+2*np.pi*v)))
broad=.5+.5*np.sin(2*np.pi*(v*11+.05*np.sin(2*np.pi*u)))
lum=.84+.025*broad+.018*fiber+.009*fine
rgb=np.stack((lum,lum*.97,lum*.93),axis=-1)
rough=.13+.025*fiber+.018*broad+.008*fine
h=.000025*fiber+.000008*fine
dy,dx=np.gradient(h);normal=np.stack((-dx*n/8,-dy*n/8,np.ones_like(h)),axis=-1)
normal/=np.linalg.norm(normal,axis=-1)[...,None]
def save(name,a):
 if a.ndim==2:a=np.repeat(a[...,None],3,axis=-1)
 Image.fromarray((np.clip(a,0,1)*255).astype(np.uint8)).save(out/name)
save('VigilOak_Color.png',rgb)
save('VigilOak_Normal.png',normal*.5+.5)
save('VigilOak_Roughness.png',rough)
save('VigilOak_JoineryRoughness.png',rough+.24)
save('VigilOak_Metalness.png',np.zeros_like(h))
print('Fine-grain walnut maps ready')

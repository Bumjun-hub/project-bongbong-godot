from pathlib import Path
from PIL import Image
import numpy as np,json,math
p=Path('experiments/detail-match-01/mapping.json');sets=json.loads(p.read_text());ref=np.array(Image.open('assets/character/idle/default_three_quarter_right/idle_default_three_quarter_right_01.png').convert('RGBA')).astype(float)
for s in sets:
 if s['name']=='walk':
  for i,f in enumerate(s['frames']):
   raw=np.array(Image.open(f'assets/character/walk/grok_right_calm/walk_{i+1:02}.png').convert('RGBA')).astype(float);choices=[]
   for dy in range(-8,9):
    for dx in range(-5,6):choices.append((np.mean(abs(np.roll(ref,(dy,dx),(0,1))[8:106,40:150]-raw[8:106,40:150])),dx,dy))
   err,dx,dy=min(choices);f['fit']=[95+dx,65+dy,1,1,0];f['affine']=[1,0,-dx,0,1,-dy]
   a=np.array(Image.open(f['source']).convert('RGBA'));m=(np.indices((192,192))[0]<111+dy)&(a[:,:,3]>0);sp=[]
   for y in range(192):
    xs=np.where(m[y])[0]
    for q in np.split(xs,np.where(np.diff(xs)>1)[0]+1):
     if len(q):sp.append([y,int(q[0]),int(q[-1])])
   f['head']=sp
 else:
  fit=np.array([f['fit'] for f in s['frames']]);tops=np.array([np.where(np.array(Image.open(f['source']).convert('RGBA'))[:,:,3]>128)[0].min() for f in s['frames']]);v=fit.copy();v[:,1]-=tops
  # Stabilize fitting noise, retaining the per-frame source head height.
  for col in range(5):
   weights=[.2,.6,.2] if s['name']=='run_light' else [.1,.2,.4,.2,.1]
   v[:,col]=sum(np.roll(v[:,col],k-len(weights)//2)*weight for k,weight in enumerate(weights))
  v[:,1]+=tops
  for f,q in zip(s['frames'],v):
   tx,ty,sx,sy,ang=q;c=math.cos(ang);sn=math.sin(ang);inv=np.linalg.inv(np.array([[c*sx,-sn*sy],[sn*sx,c*sy]]));f['fit']=q.tolist();f['affine']=[float(inv[0,0]),float(inv[0,1]),float(95-inv[0]@q[:2]),float(inv[1,0]),float(inv[1,1]),float(65-inv[1]@q[:2])]
p.write_text(json.dumps(sets));print('Reference-detail tracking stabilized; original motion heights retained.')

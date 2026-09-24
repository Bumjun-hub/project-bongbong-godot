from pathlib import Path
from PIL import Image
import numpy as np,json
p=Path('experiments/detail-match-01/mapping.json');sets=json.loads(p.read_text())
for s in sets:
 if s['name']!='run_bouncy':continue
 for f in s['frames']:
  a=np.array(Image.open(f['source']).convert('RGBA'));r,g,b=a[:,:,:3].astype(int).transpose(2,0,1);skin=(a[:,:,3]>0)&(r>120)&(r>g+10)&(g>b+8);padded=np.pad(skin,2);protect=np.zeros_like(skin)
  for dy in range(-2,3):
   for dx in range(-2,3):protect|=padded[2+dy:194+dy,2+dx:194+dx]
  mask=np.zeros_like(skin)
  for y,x0,x1 in f['head']:mask[y,x0:x1+1]=True
  mask&=~protect;sp=[]
  for y in range(192):
   xs=np.where(mask[y])[0]
   for q in np.split(xs,np.where(np.diff(xs)>1)[0]+1):
    if len(q):sp.append([y,int(q[0]),int(q[-1])])
  f['head']=sp
p.write_text(json.dumps(sets))

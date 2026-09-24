from pathlib import Path
from PIL import Image
import numpy as np,json,math
w=Path('experiments/detail-match-01');old=json.loads(Path('experiments/skin-match-01/mapping.json').read_text())
ref=np.array(Image.open('assets/character/idle/default_three_quarter_right/idle_default_three_quarter_right_01.png').convert('RGBA')).astype(float)
newref='assets/character/idle/soft_three_quarter_right/default/idle_01.png'
yy,xx=np.indices((192,192));rg=ref[:,:,:3];lum=rg@np.array([.299,.587,.114]);rhair=(ref[:,:,3]>128)&(yy<79)&(rg.max(2)<175)&(np.ptp(rg,axis=2)<60)
py,px=np.where(rhair & (xx%2==0)&(yy%2==0));points=np.stack([px-95,py-65],axis=1);rv=lum[py,px];rv=(rv-rv.mean())/(rv.std()+1)
def sample(a,x,y):
 x=np.clip(x,0,190.999);y=np.clip(y,0,190.999);ix=x.astype(int);iy=y.astype(int);fx=x-ix;fy=y-iy
 return a[iy,ix]*(1-fx)*(1-fy)+a[iy,ix+1]*fx*(1-fy)+a[iy+1,ix]*(1-fx)*fy+a[iy+1,ix+1]*fx*fy
def matrix(p):
 tx,ty,sx,sy,ang=p;c=math.cos(ang);s=math.sin(ang);return np.array([[c*sx,-s*sy],[s*sx,c*sy]])
def score(a,p):
 M=matrix(p);q=points@M.T+np.array(p[:2]);v=sample(a[:,:,:3]@np.array([.299,.587,.114]),q[:,0],q[:,1]);v=(v-v.mean())/(v.std()+1);alpha=sample(a[:,:,3],q[:,0],q[:,1])/255
 return float(np.mean((v-rv)**2)+2*np.mean(1-alpha))
def spans(m):
 res=[]
 for y in range(192):
  xs=np.where(m[y])[0]
  for q in np.split(xs,np.where(np.diff(xs)>1)[0]+1):
   if len(q):res.append([y,int(q[0]),int(q[-1])])
 return res
sets=[]
for s in old:
 folder='assets/character/detail_matched_motions/'+s['name'];Path(folder).mkdir(parents=True,exist_ok=True);frames=[]
 for i,f in enumerate(s['frames']):
  a=np.array(Image.open(f['output']).convert('RGBA')).astype(float);rgb=a[:,:,:3];r,g,b=rgb.transpose(2,0,1);top=int(np.where(a[:,:,3]>128)[0].min())
  if s['name']=='walk':
   # Recover the translation of the original moving IDLE head from its source.
   raw=np.array(Image.open(f'assets/character/walk/grok_right_calm/walk_{i+1:02}.png').convert('RGBA')).astype(float);candidates=[]
   for dy in range(-2,5):
    for dx in range(-3,4):
     shifted=np.roll(ref,(dy,dx),(0,1));err=np.mean(abs(shifted[10:108,40:150]-raw[10:108,40:150]));candidates.append((err,dx,dy))
   err,dx,dy=min(candidates);p=[95+dx,65+dy,1,1,0];head=(yy<111+dy)&(a[:,:,3]>0)
  else:
   hair=(a[:,:,3]>128)&(yy<top+62)&(rgb.max(2)<170)&(np.ptp(rgb,axis=2)<60);hy,hx=np.where(hair)
   p=[float((hx.min()+hx.max())/2),float(top+47),float((hx.max()-hx.min()+1)/102),1.,0.]
   for steps in [[2,2,.04,.04,.04],[1,1,.02,.02,.02],[.5,.5,.01,.01,.01]]:
    for _ in range(2):
     for axis,step in enumerate(steps):
      choices=[]
      for d in [-step,0,step]:
       q=p.copy();q[axis]+=d
       if .82<q[2]<1.25 and .82<q[3]<1.25 and abs(q[4])<.2:choices.append((score(a,q),q))
      p=min(choices,key=lambda z:z[0])[1]
   if s['name']=='run_light':head=(yy<top+96)&(a[:,:,3]>0)
   else:head=(yy<top+64)&(a[:,:,3]>0)&(rgb.max(2)<175)&(np.ptp(rgb,axis=2)<55)&(r-g<23)&(b>=g-6)
  # Keep source neck and silhouette; fit maps only reference detail into occupied pixels.
  inv=np.linalg.inv(matrix(p));aff=[inv[0,0],inv[0,1],95-inv[0]@p[:2],inv[1,0],inv[1,1],65-inv[1]@p[:2]]
  shirt=(a[:,:,3]>128)&(r>65)&(r>g*1.65)&(r>b*1.35)&(yy>top+80)
  pants=(a[:,:,3]>128)&(b>r*1.18)&(g>r*1.10)&(b>55)&(yy>top+100)
  frames.append({'source':f['output'],'output':folder+f'/frame_{i+1:02}.png','duration':f['duration'],'affine':[float(x) for x in aff],'fit':[float(x) for x in p],'head':spans(head),'materials':{'shirt':spans(shirt),'pants':spans(pants)}})
 sets.append({'name':s['name'],'resource':s['resource'],'fps':s['fps'],'output':folder,'reference':newref,'frames':frames})
 print(s['name'],'head centers range',np.min([f['fit'][:2] for f in frames],axis=0).tolist(),np.max([f['fit'][:2] for f in frames],axis=0).tolist())
(w/'mapping.json').write_text(json.dumps(sets))

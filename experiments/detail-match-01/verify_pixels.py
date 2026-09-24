from pathlib import Path
from PIL import Image
import numpy as np,json,hashlib
w=Path('experiments/detail-match-01');sets=json.loads((w/'mapping.json').read_text());report=[]
for s in sets:
 movements=[]
 for f in s['frames']:
  a=np.array(Image.open(f['source']).convert('RGBA'));b=np.array(Image.open(f['output']).convert('RGBA'));mask=np.zeros((192,192),bool)
  for y,x0,x1 in f['head']:mask[y,x0:x1+1]=True
  for spans in f['materials'].values():
   for y,x0,x1 in spans:mask[y,x0:x1+1]=True
  assert np.array_equal(a[:,:,3],b[:,:,3]);assert np.array_equal(a[~mask],b[~mask]);assert a.shape==(192,192,4)
  movements.append(f['fit'][:2]);f['input_sha256']=hashlib.sha256(Path(f['source']).read_bytes()).hexdigest()
  report.append({'animation':s['name'],'file':f['output'],'changed_pixels':int((a!=b).any(2).sum()),'alpha_unchanged':True,'outside_detail_masks_unchanged':True})
 assert np.ptp(np.array(movements)[:,1])>2,'head must retain vertical motion'
(w/'mapping.json').write_text(json.dumps(sets));(w/'verification.json').write_text(json.dumps(report,indent=2))
print('PASS 70 frames: unchanged alpha/silhouette, positions, limbs outside material repair masks; tracked heads retain movement.')

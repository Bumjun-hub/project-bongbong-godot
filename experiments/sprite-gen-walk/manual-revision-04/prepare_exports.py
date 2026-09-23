from pathlib import Path
from collections import deque
import json
import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
before = np.array(Image.open(HERE / 'revision14-walk_cycle_8.png').convert('RGBA'))
after = np.array(Image.open(HERE / 'candidate.png').convert('RGBA'))
assert before.shape == after.shape == (192,1536,4)
meta = json.loads((HERE / 'reports/candidate.json').read_text())
assert len(meta['frames']) == 8 and all(f['duration'] == 125 for f in meta['frames'])
(HERE / 'frames').mkdir(exist_ok=True)
(HERE / 'qa-frames').mkdir(exist_ok=True)
report = {'revision':15,'frames':[],'duration_ms':125,'frame_count':8}
for i,dy in enumerate([0,1,0,-1,0,1,0,-1]):
    old = before[:,i*192:(i+1)*192]
    frame = after[:,i*192:(i+1)*192]
    changes = np.any(old != frame,axis=2)
    allowed = np.zeros((192,192),bool)
    allowed[109+dy:113+dy,81:91] = True
    if i == 0: allowed[138:150,123:137] = True
    if i == 1: allowed[141:153,117:132] = True
    if i == 7: allowed[139:151,117:132] = True
    if i in [2,6]: allowed[145:153,109:121] = True
    assert not np.any(changes & ~allowed), f'Outside edit areas: frame {i+1}'
    rgb=old[:,:,:3].astype(int)
    denim=(old[:,:,3]>0)&(rgb[:,:,2]>rgb[:,:,0]+18)&(rgb[:,:,2]>rgb[:,:,1]+3)
    assert not np.any(changes & denim), f'Denim changed: frame {i+1}'
    assert np.array_equal(old[153:],frame[153:])
    assert Image.fromarray(old).getbbox()==Image.fromarray(frame).getbbox()
    remaining=set(zip(*np.where(frame[:,:,3]>0)))
    components=[]
    while remaining:
        stack=[remaining.pop()];size=0
        while stack:
            y,x=stack.pop();size+=1
            for d_y,d_x in ((-1,0),(1,0),(0,-1),(0,1)):
                p=(y+d_y,x+d_x)
                if p in remaining:remaining.remove(p);stack.append(p)
        components.append(size)
    assert len(components)==1, f'Stray pixels: {i+1}, {components}'
    assert set(np.unique(frame[:,:,3]).tolist())<={0,255}
    Image.fromarray(frame).save(HERE/'frames'/f'walk_{i+1:02}.png')
    Image.fromarray(frame).save(HERE/'qa-frames'/f'frame-{i}.png')
    report['frames'].append({'frame':i+1,'changed_pixels':int(changes.sum()),'connected_components':len(components),'denim_unchanged':True,'lower_rows_153_onward_unchanged':True,'changes_confined_to_neck_and_marked_hand':True})
(HERE/'reports/pixel-qa.json').write_text(json.dumps(report,indent=2),encoding='utf-8')

review=Image.new('RGB',(768,600),(68,68,68))
draw=ImageDraw.Draw(review)
for i,a in enumerate([before[:,:192],after[:,:192]]):
    bg=Image.new('RGBA',(192,192),(155,155,155,255))
    d=ImageDraw.Draw(bg)
    for y in range(0,192,8):
        for x in range(0,192,8):
            if (x//8+y//8)%2:d.rectangle((x,y,x+7,y+7),fill=(190,190,190,255))
    bg.alpha_composite(Image.fromarray(a))
    crop=bg.crop((44,15,140,159)).resize((384,576),Image.Resampling.NEAREST)
    review.paste(crop.convert('RGB'),(i*384,24))
    draw.text((i*384+8,6),['BEFORE','AFTER'][i],fill='white')
review.save(HERE/'reports/before-after.png')
print(json.dumps(report))

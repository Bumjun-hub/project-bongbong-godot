from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw

HERE=Path(__file__).resolve().parent
before=np.array(Image.open(HERE/'revision15-walk_cycle_8.png').convert('RGBA'))
after=np.array(Image.open(HERE/'candidate.png').convert('RGBA'))
assert before.shape==after.shape==(192,1536,4)
metadata=json.loads((HERE/'reports/candidate.json').read_text())
assert len(metadata['frames'])==8 and all(f['duration']==125 for f in metadata['frames'])
(HERE/'frames').mkdir(exist_ok=True)
(HERE/'qa-frames').mkdir(exist_ok=True)
report={'revision':16,'frames':[]}
for i,dy in enumerate([0,1,0,-1,0,1,0,-1]):
    old=before[:,i*192:(i+1)*192]
    frame=after[:,i*192:(i+1)*192]
    changed=np.any(old!=frame,axis=2)
    allowed=np.zeros((192,192),bool);allowed[111+dy:127+dy,67:89]=True
    assert not np.any(changed&~allowed)
    assert np.array_equal(frame[128:],old[128:])
    assert Image.fromarray(frame).getbbox()==Image.fromarray(old).getbbox()
    r,g,b,a=[frame[:,:,c].astype(int) for c in range(4)]
    red=(a>0)&(r>85)&(r>g+50)&(g<65)
    # The shoulder's red edge must never meet a transparent pixel directly.
    exposed=[]
    for y in range(112+dy,125+dy):
        for x in range(70,89):
            if red[y,x]:
                for dx,d_y in [(-1,0),(1,0),(0,-1),(0,1)]:
                    if a[y+d_y,x+dx]==0:exposed.append([x,y,x+dx,y+d_y])
    assert not exposed, f'Unoutlined shoulder: {i+1}, {exposed}'
    image=Image.fromarray(frame)
    image.save(HERE/'frames'/f'walk_{i+1:02}.png')
    image.save(HERE/'qa-frames'/f'frame-{i}.png')
    report['frames'].append({'frame':i+1,'changed_pixels':int(changed.sum()),'unoutlined_shoulder_edges':len(exposed),'hands_and_legs_identical':True})
(HERE/'reports/pixel-qa.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
base=Image.open(HERE.parents[2]/'assets/character/idle/default_three_quarter_right/idle_default_three_quarter_right_01.png').convert('RGBA')
compare=Image.new('RGB',(960,312),(70,70,70));draw=ImageDraw.Draw(compare)
for i,(label,sprite) in enumerate([('IDLE BASE',base),('BEFORE',Image.fromarray(before[:,:192])),('AFTER',Image.fromarray(after[:,:192]))]):
    crop=sprite.crop((72,103,112,139));bg=Image.new('RGBA',crop.size,(175,175,175,255));bg.alpha_composite(crop)
    compare.paste(bg.resize((320,288),Image.Resampling.NEAREST).convert('RGB'),(i*320,24));draw.text((i*320+8,6),label,fill='white')
compare.save(HERE/'reports/base-before-after.png')
print(json.dumps(report))

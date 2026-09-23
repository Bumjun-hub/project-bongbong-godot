"""Package native Aseprite exports without resampling runtime textures."""
from pathlib import Path
import json, shutil, re
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[3]
WORK=Path(__file__).resolve().parent
DEST=ROOT/'assets/character/run/right_three_quarter'
sheet=Image.open(WORK/'run_dash.png').convert('RGBA')
assert sheet.size==(1536,192)
metadata=json.loads((WORK/'run_dash.json').read_text())
entries=metadata['frames']
assert [f['duration'] for f in (entries.values() if isinstance(entries,dict) else entries)]==[60]*8
frames=[sheet.crop((i*192,0,(i+1)*192,192)) for i in range(8)]
contact=Image.new('RGBA',(768,384),(41,51,62,255))
preview=[]
for i,im in enumerate(frames):
    contact.alpha_composite(im,(i%4*192,i//4*192))
    ImageDraw.Draw(contact).text((i%4*192+6,i//4*192+5),str(i+1),fill='white')
    bg=Image.new('RGBA',(192,192),(41,51,62,255));bg.alpha_composite(im)
    preview.append(bg.convert('RGB').resize((384,384),Image.Resampling.NEAREST))
contact.resize((1536,768),Image.Resampling.NEAREST).save(WORK/'contact.png')
preview[0].save(WORK/'preview.gif',save_all=True,append_images=preview[1:],duration=60,loop=0,optimize=False)
preview[0].save(WORK/'slow.gif',save_all=True,append_images=preview[1:],duration=200,loop=0,optimize=False)
for src,dst in [('run_dash.aseprite','run_cycle_8.aseprite'),('run_dash.png','run_cycle_8.png'),('run_dash.gif','run_cycle_8.gif'),('preview.gif','run_cycle_8_preview.gif'),('slow.gif','run_cycle_8_slow.gif'),('contact.png','run_contact_sheet.png')]:
    shutil.copy2(WORK/src,DEST/dst)
for i,im in enumerate(frames): im.save(DEST/f'run_{i+1:02}.png')
m=json.loads((DEST/'manifest.json').read_text(encoding='utf-8'))
m.update(revision=8,status='arms_back_dash_with_leg_afterimages',fps=1000/60,frame_duration_ms=60,
    method='Native Aseprite: redraw both arms reaching back, integer row lean of the preserved playful head and torso, retain revised leg cycle, add separate translucent leg afterimage layer.',
    alpha='RGBA preserved, including deliberate low-alpha leg afterimages',
    effect={'layer':'Leg afterimages','offsets_px':[-10,-18],'max_alpha':[65,27],'scope':'previous-frame legs below y145 with upper fade'},
    cycle_duration_ms=480,total_duration_ms=480,frame_durations_ms=[60]*8,
    speed_effect='Two fading previous-pose leg afterimages, behind the opaque character')
for f in m['frames']:
    f.update(arms='both_arms_back',duration_ms=60)
    f.pop('speed_accent_pixels',None)
(DEST/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
t=ROOT/'scenes/run_frames.tres'
s=t.read_text();s=re.sub(r'"duration": [\d.]+','"duration": 1.0',s);s=re.sub(r'"speed": [\d.]+','"speed": 16.6666666667',s);t.write_text(s)
v=(ROOT/'.godot/run_work/verify_run_v7.gd').read_text().replace('[80.0, 60.0, 60.0, 80.0, 80.0, 60.0, 60.0, 80.0]','[60.0, 60.0, 60.0, 60.0, 60.0, 60.0, 60.0, 60.0]').replace('560.0','480.0').replace('RUN_V7_OK','RUN_V8_OK')
(WORK/'verify_run_v8.gd').write_text(v)
print('Packaged Run revision 8; 8 x 60ms, 480ms loop')

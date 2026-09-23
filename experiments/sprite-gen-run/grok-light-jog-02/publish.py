from pathlib import Path
import hashlib,json,re,shutil
from PIL import Image

work=Path(__file__).resolve().parent
root=work.parents[2]
source=work/"loop-full/prepared"
dest=root/"assets/character/run/light_jog_02"
dest.mkdir(parents=True,exist_ok=True)
meta=json.loads((source/"metadata.json").read_text())
n=meta["frames"]
assert n==18 and meta["fps"]==20
sheet=Image.open(source/"run_light_02.png").convert("RGBA")
assert sheet.size==(192*n,192)
template=(root/"assets/character/run/right_three_quarter/run_01.png.import").read_text()
resources=[]
for i in range(n):
    name=f"run_{i+1:02}.png"
    image=sheet.crop((192*i,0,192*(i+1),192))
    assert image.tobytes()==Image.open(source/name).convert("RGBA").tobytes()
    image.save(dest/name)
    path=f"res://assets/character/run/light_jog_02/{name}"
    cache=f"res://.godot/imported/{name}-{hashlib.md5(path.encode()).hexdigest()}.ctex"
    imp=re.sub(r'^uid=.*\n','',template,flags=re.M)
    for key,value in [('path',f'"{cache}"'),('source_file',f'"{path}"'),('dest_files',f'["{cache}"]')]:
        imp=re.sub(r'^'+key+r'=.*$',key+'='+value,imp,flags=re.M)
    (dest/(name+'.import')).write_text(imp)
    resources.append(f'[ext_resource type="Texture2D" path="{path}" id="{i+1}_run_light"]')
for name in ('run_light_02.aseprite','run_light_02.png'):
    shutil.copy2(source/name,dest/name)
shutil.copy2(source/'preview.gif',dest/'run_light_02_preview.gif')
shutil.copy2(source/'contact.png',dest/'run_light_02_contact.png')
resource=root/'scenes/run_light_frames.tres'
backup=work/'run_light_frames.before_remake.tres'
if not backup.exists(): shutil.copy2(resource,backup)
frames=',\n'.join(f'{{"duration": 1.0, "texture": ExtResource("{i+1}_run_light")}}' for i in range(n))
resource.write_text(f'[gd_resource type="SpriteFrames" load_steps={n+1} format=3]\n\n'+'\n'.join(resources)+'\n\n[resource]\nanimations = [{\n"frames": [\n'+frames+'\n],\n"loop": true,\n"name": &"run_light",\n"speed": 20.0\n}]\n')
(dest/'manifest.json').write_text(json.dumps({'name':'light jog remake','source':'experiments/sprite-gen-run/grok-light-jog-02/clip.mp4','source_frames_1_based':[50,67],'frames':n,'fps':20,'cycle_seconds':0.9,'canvas':[192,192],'foot_anchor':[95,174],'placement':meta['offset'],'source_fps':24,'omitted_frames':[],'per_frame_position_edits':False,'seam_ratio':1.2603,'method':'Grok new video -> canonical frames -> visually reviewed full alternating stride -> padding -> Aseprite'},indent=2)+'\n')
print('Published fresh Run: 18 consecutive frames, 20 fps, 0.9 seconds')

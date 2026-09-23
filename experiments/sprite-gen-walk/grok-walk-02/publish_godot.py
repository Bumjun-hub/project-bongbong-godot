"""Place canonical extracted frames on the existing Godot canvas, without resampling."""
from pathlib import Path
import json, shutil, hashlib
from PIL import Image

root=Path(__file__).resolve().parents[3]
work=Path(__file__).resolve().parent
dest=root/'assets/character/walk/grok_right_calm'
dest.mkdir(parents=True,exist_ok=True)
if (dest/'walk_cycle_24.aseprite').exists():
    raise SystemExit('The accepted Idle-matched Walk is already installed; use publish_head_match.py for that revision.')
resource=root/'scenes/walk_frames.tres'
backup=work/'walk_frames.before_grok.tres'
if not backup.exists(): shutil.copy2(resource,backup)
meta=json.loads((work/'loop/walk-right-calm.strip.json').read_text())
sheet=Image.open(work/'loop/walk-right-calm.strip.png').convert('RGBA')
assert (meta['frames'],meta['w'],meta['h'])==(24,104,158)
assert sheet.size==(2496,158)
entries=[]
for i in range(24):
    frame=sheet.crop((i*104,0,(i+1)*104,158))
    canvas=Image.new('RGBA',(192,192))
    canvas.paste(frame,(43,16))
    name=f'walk_{i+1:02}.png'
    canvas.save(dest/name)
    path=f'res://assets/character/walk/grok_right_calm/{name}'
    cache=f'res://.godot/imported/{name}-{hashlib.md5(path.encode()).hexdigest()}.ctex'
    template=(root/'assets/character/walk/right_three_quarter/walk_01.png.import').read_text()
    import re
    template=re.sub(r'^uid=.*\n','',template,flags=re.M)
    template=template.replace('process/fix_alpha_border=true','process/fix_alpha_border=false')
    template=re.sub(r'^path=.*$',f'path="{cache}"',template,flags=re.M)
    template=re.sub(r'^source_file=.*$',f'source_file="{path}"',template,flags=re.M)
    template=re.sub(r'^dest_files=.*$',f'dest_files=["{cache}"]',template,flags=re.M)
    (dest/(name+'.import')).write_text(template)
    entries.append(f'[ext_resource type="Texture2D" path="{path}" id="{i+1}_walk"]')
frames=',\n'.join('{"duration": 1.0, "texture": ExtResource("%d_walk")}'%(i+1) for i in range(24))
resource.write_text('[gd_resource type="SpriteFrames" load_steps=25 format=3]\n\n'+'\n'.join(entries)+'\n\n[resource]\nanimations = [{\n"frames": [\n'+frames+'\n],\n"loop": true,\n"name": &"walk",\n"speed": 24.0\n}]\n')
(dest/'manifest.json').write_text(json.dumps({'source':'experiments/sprite-gen-walk/grok-walk-02/loop/walk-right-calm.strip.png','frames':24,'fps':24,'cycle_seconds':1,'canvas':[192,192],'placement':[43,16],'foot_anchor':[95,174],'body_height':156,'resampled':False},indent=2)+'\n')
print('Published 24 exact extracted frames, padded to 192x192; 24 fps.')

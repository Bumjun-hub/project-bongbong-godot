"""Publish the even-cadence reviewed Aseprite light jog without resampling pixels."""
from pathlib import Path
import hashlib
import json
import re
import shutil

from PIL import Image

work = Path(__file__).resolve().parent
root = work.parents[2]
source = work / "loop-cut-21"
destination = root / "assets/character/run/light_jog_01"
destination.mkdir(parents=True, exist_ok=True)

sheet = Image.open(source / "run_light_21_smooth.png").convert("RGBA")
assert sheet.size == (192 * 21, 192)
template = (root / "assets/character/run/right_three_quarter/run_01.png.import").read_text()
resources = []
for i in range(21):
    name = f"run_{i + 1:02}.png"
    frame = sheet.crop((i * 192, 0, (i + 1) * 192, 192))
    frame.save(destination / name)
    resource_path = f"res://assets/character/run/light_jog_01/{name}"
    cache = f"res://.godot/imported/{name}-{hashlib.md5(resource_path.encode()).hexdigest()}.ctex"
    import_text = re.sub(r"^uid=.*\n", "", template, flags=re.M)
    import_text = re.sub(r"^path=.*$", f'path="{cache}"', import_text, flags=re.M)
    import_text = re.sub(r"^source_file=.*$", f'source_file="{resource_path}"', import_text, flags=re.M)
    import_text = re.sub(r"^dest_files=.*$", f'dest_files=["{cache}"]', import_text, flags=re.M)
    (destination / (name + ".import")).write_text(import_text)
    resources.append(f'[ext_resource type="Texture2D" path="{resource_path}" id="{i + 1}_run_light"]')

shutil.copy2(source / "run_light_21_smooth.aseprite", destination / "run_light_01.aseprite")
shutil.copy2(source / "run_light_21_smooth.png", destination / "run_light_01.png")
shutil.copy2(source / "run_light_21_smooth.preview.gif", destination / "run_light_01_preview.gif")
shutil.copy2(source / "run_light_21_smooth.contact.png", destination / "run_light_01_contact.png")
frames = ",\n".join(
    f'{{"duration": 1.0, "texture": ExtResource("{i + 1}_run_light")}}' for i in range(21)
)
(root / "scenes/run_light_frames.tres").write_text(
    '[gd_resource type="SpriteFrames" load_steps=22 format=3]\n\n'
    + "\n".join(resources)
    + '\n\n[resource]\nanimations = [{\n"frames": [\n'
    + frames
    + '\n],\n"loop": true,\n"name": &"run_light",\n"speed": 21.0\n}]\n'
)
(destination / "manifest.json").write_text(
    json.dumps(
        {
            "name": "light jog 01",
            "source": "experiments/sprite-gen-run/grok-light-jog-01/clip.mp4",
            "method": "sprite-gen Grok Imagine video -> video-frames -> reviewed fixed loop -> Aseprite whole-body bounce adjustment -> remove repeated holds -> smooth late bounce",
            "reviewed_source_frames_1_based": [47, 70],
            "omitted_source_frames_1_based": [52, 58, 65],
            "frames": 21,
            "fps": 21,
            "cycle_seconds": 1,
            "canvas": [192, 192],
            "foot_anchor": [95, 174],
            "whole_body_down_px_before_cadence_cut": [0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 4, 1, 0, 0, 0, 0, 0, 6, 6, 4, 0, 0, 0, 0],
            "late_whole_body_adjustment_final_frames": {"15": 3, "16": -1},
            "resampled_after_loop": False,
        },
        indent=2,
        ensure_ascii=False,
    )
    + "\n"
)
print("Published 21 light jog frames and run_light SpriteFrames at 21 fps")

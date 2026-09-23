"""Publish the reviewed eight-frame Run to the Godot asset paths."""

import json
import re
import shutil
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
WORK = Path(__file__).resolve().parent
SRC = WORK / "pose-redraw-candidate"
DST = ROOT / "assets/character/run/right_three_quarter"
DURATIONS = [80, 60, 60, 80, 80, 60, 60, 80]

for n in range(1, 9):
    shutil.copy2(SRC / f"run_{n:02}.png", DST / f"run_{n:02}.png")
shutil.copy2(SRC / "run_cycle_8_pose_redraw.aseprite", DST / "run_cycle_8.aseprite")
shutil.copy2(SRC / "run_cycle_8_pose_redraw.png", DST / "run_cycle_8.png")
shutil.copy2(SRC / "run_cycle_8_pose_redraw.gif", DST / "run_cycle_8.gif")

frames = [Image.open(DST / f"run_{n:02}.png").convert("RGBA") for n in range(1, 9)]
contact = Image.open(SRC / "contact.png").convert("RGBA")
contact.resize((1536, 768), Image.Resampling.NEAREST).save(DST / "run_contact_sheet.png")

for name, timing in (("run_cycle_8_preview.gif", DURATIONS), ("run_cycle_8_slow.gif", [200] * 8)):
    prepared = []
    for frame in frames:
        canvas = Image.new("RGBA", (192, 192), (42, 52, 63, 255))
        canvas.alpha_composite(frame)
        prepared.append(canvas.convert("RGB").resize((384, 384), Image.Resampling.NEAREST))
    prepared[0].save(DST / name, save_all=True, append_images=prepared[1:], duration=timing, loop=0, optimize=False)

manifest_path = DST / "manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
manifest.update({
    "revision": 6,
    "status": "run_new_limb_poses_and_contact_arc",
    "alpha": "RGBA retained; invisible alpha<=8 and detached old speed lines removed",
    "sampling": "Nearest-neighbor displacement of accepted Run pixels, with clean original leg-pose recomposition in frames 5 and 6",
    "method": "Recompose arm and leg motion from the accepted Run art: bend each limb through small anchored pixel displacements, replace the duplicate frame-5 leap with a contact pose and frame-6 blurred shoe with a clean recovery pose, then set the contact/flight body arc and nonuniform timing. Keep approved head, glasses, expression, shirt and palette.",
    "preview": "run_cycle_8_preview.gif",
    "frame_duration_ms": 70,
    "frame_durations_ms": DURATIONS,
    "fps": 8 / (sum(DURATIONS) / 1000),
    "total_duration_ms": sum(DURATIONS),
    "ground_reference": 174,
    "speed_effect": "Detached old speed accent strokes removed for stable outlines",
})
manifest.pop("effect", None)
manifest.pop("shoe_centers_x", None)
for index, frame in enumerate(manifest["frames"]):
    frame["duration_ms"] = DURATIONS[index]
    frame["speed_accent_pixels"] = 0
    frame.pop("face_changed_pixels", None)
manifest["frames"][4]["phase"] = "left_contact_redrawn"
manifest["frames"][5]["phase"] = "left_support_right_recovery_redrawn"
manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

resource_path = ROOT / "scenes/run_frames.tres"
resource = resource_path.read_text(encoding="utf-8")
pattern = r'(?m)^\{"duration": [0-9.]+, "texture": ExtResource\("([1-8])_run"\)\},$'
def duration_line(match):
    index = int(match.group(1)) - 1
    return '{"duration": ' + format(DURATIONS[index] / 70, '.12g') + ', "texture": ExtResource("' + match.group(1) + '_run")},'
resource, count = re.subn(pattern, duration_line, resource)
assert count == 8, f"expected 8 Run texture entries, got {count}"
resource_path.write_text(resource, encoding="utf-8")
print("published", DST)

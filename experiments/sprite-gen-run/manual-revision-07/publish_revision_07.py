"""Package the reviewed Aseprite revision for the Godot Run asset paths."""

import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[3]
WORK = Path(__file__).resolve().parent
ASSETS = ROOT / "assets/character/run/right_three_quarter"
DURATIONS = [80, 60, 60, 80, 80, 60, 60, 80]

shutil.copy2(WORK / "run_expression_legs_final.aseprite", ASSETS / "run_cycle_8.aseprite")
shutil.copy2(WORK / "run_expression_legs_candidate.png", ASSETS / "run_cycle_8.png")
shutil.copy2(WORK / "run_expression_legs_candidate.gif", ASSETS / "run_cycle_8.gif")

sheet = Image.open(ASSETS / "run_cycle_8.png").convert("RGBA")
assert sheet.size == (1536, 192)
frames = []
for index in range(8):
    frame = sheet.crop((index * 192, 0, (index + 1) * 192, 192))
    frame.save(ASSETS / f"run_{index + 1:02}.png")
    frames.append(frame)

contact = Image.new("RGBA", (768, 384), (41, 51, 62, 255))
for index, frame in enumerate(frames):
    x, y = index % 4 * 192, index // 4 * 192
    contact.alpha_composite(frame, (x, y))
    ImageDraw.Draw(contact).text((x + 7, y + 5), str(index + 1), fill=(255, 255, 255, 255))
contact.resize((1536, 768), Image.Resampling.NEAREST).save(ASSETS / "run_contact_sheet.png")

for name, durations in (("run_cycle_8_preview.gif", DURATIONS), ("run_cycle_8_slow.gif", [200] * 8)):
    prepared = []
    for frame in frames:
        background = Image.new("RGBA", (192, 192), (41, 51, 62, 255))
        background.alpha_composite(frame)
        prepared.append(background.convert("RGB").resize((384, 384), Image.Resampling.NEAREST))
    prepared[0].save(ASSETS / name, save_all=True, append_images=prepared[1:], duration=durations, loop=0, optimize=False)

manifest_path = ASSETS / "manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
manifest.update({
    "revision": 7,
    "status": "run_playful_smirk_and_leg_recheck",
    "method": "On the accepted Run, replace only lens-interior eye curves and the mouth with a compact playful smirk; preserve glasses and head silhouette. Rework frame 6 as an inward lifted recovery step, and frame 7 as a separate passing step after frame 5's landing. Keep the other poses and all timing.",
    "preview": "run_cycle_8_preview.gif",
    "expression": {
        "type": "half-curved smiling eyes and small asymmetric raised-corner smirk",
        "scope": "lens interiors and mouth only",
        "eyeglass_frames": "preserved",
        "reference": "user-requested cute, mildly mischievous Run expression",
    },
    "leg_revision": {
        "frames": [6, 7],
        "reason": "Remove the repeated frame-5/frame-7 contact shape and make frame-6 recovery distinct from the frame-1 stride",
        "source": "accepted Run pixels; nearest-neighbor Aseprite displacement and clean pose recomposition",
    },
})
manifest["frames"][5]["phase"] = "inward_lifted_recovery"
manifest["frames"][6]["phase"] = "separate_leg_passing_pose"
manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("published", ASSETS)

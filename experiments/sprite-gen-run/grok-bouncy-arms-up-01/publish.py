"""Publish the reviewed Grok loop as a separate Godot Run variant."""

from pathlib import Path
import hashlib
import json
import re
import shutil

from PIL import Image


WORK = Path(__file__).resolve().parent
ROOT = WORK.parents[2]
SOURCE = WORK / "prepared"
DEST = ROOT / "assets/character/run/bouncy_arms_up_01"
RESOURCE = ROOT / "scenes/run_bouncy_frames.tres"
FRAMES = 28


def main() -> None:
    metadata = json.loads((SOURCE / "metadata.json").read_text(encoding="utf-8"))
    assert metadata["frames"] == FRAMES and metadata["fps"] == 24
    sheet = Image.open(SOURCE / "run_bouncy_01.png").convert("RGBA")
    assert sheet.size == (192 * FRAMES, 192)
    template = (ROOT / "assets/character/run/right_three_quarter/run_01.png.import").read_text(encoding="utf-8")
    DEST.mkdir(parents=True, exist_ok=True)
    resources = []
    for index in range(FRAMES):
        name = f"run_{index + 1:02}.png"
        source = Image.open(SOURCE / name).convert("RGBA")
        assert source.size == (192, 192)
        assert source.tobytes() == sheet.crop((192 * index, 0, 192 * (index + 1), 192)).tobytes()
        shutil.copy2(SOURCE / name, DEST / name)
        path = f"res://assets/character/run/bouncy_arms_up_01/{name}"
        cache = f"res://.godot/imported/{name}-{hashlib.md5(path.encode()).hexdigest()}.ctex"
        imported = re.sub(r"^uid=.*\n", "", template, flags=re.MULTILINE)
        for key, value in (
            ("path", f'"{cache}"'),
            ("source_file", f'"{path}"'),
            ("dest_files", f'["{cache}"]'),
        ):
            imported = re.sub(r"^" + key + r"=.*$", key + "=" + value, imported, flags=re.MULTILINE)
        (DEST / (name + ".import")).write_text(imported, encoding="utf-8")
        resources.append(f'[ext_resource type="Texture2D" path="{path}" id="{index + 1}_run_bouncy"]')
    for name in ("run_bouncy_01.aseprite", "run_bouncy_01.png", "asset.json"):
        shutil.copy2(SOURCE / name, DEST / name)
    shutil.copy2(SOURCE / "preview.gif", DEST / "run_bouncy_01_preview.gif")
    shutil.copy2(SOURCE / "contact.png", DEST / "run_bouncy_01_contact.png")
    frames = ",\n".join(
        f'{{"duration": 1.0, "texture": ExtResource("{index + 1}_run_bouncy")}}'
        for index in range(FRAMES)
    )
    RESOURCE.write_text(
        f'[gd_resource type="SpriteFrames" load_steps={FRAMES + 1} format=3]\n\n'
        + "\n".join(resources)
        + '\n\n[resource]\nanimations = [{\n"frames": [\n'
        + frames
        + '\n],\n"loop": true,\n"name": &"run_bouncy",\n"speed": 24.0\n}]\n',
        encoding="utf-8",
    )
    (DEST / "manifest.json").write_text(
        json.dumps(
            {
                "name": "bouncy arms-up run",
                "base_pose": "experiments/sprite-gen-run/arms-up-pose-candidates/pose_C_big_stride.png",
                "source_video": "experiments/sprite-gen-run/grok-bouncy-arms-up-01/clip.mp4",
                "source_frames_1_based": metadata["source_frames_1_based"],
                "frames": FRAMES,
                "fps": 24,
                "cycle_seconds": FRAMES / 24,
                "canvas": [192, 192],
                "foot_anchor": [95, 174],
                "placement": metadata["placement"],
                "seam_ratio": metadata["seam_ratio"],
                "method": "Sprite gen + Grok video + canonical frame extraction + fixed reviewed loop + Aseprite",
            },
            indent=2,
        ) + "\n",
        encoding="utf-8",
    )
    print(f"published {FRAMES} frames to {DEST} and {RESOURCE}")


if __name__ == "__main__":
    main()

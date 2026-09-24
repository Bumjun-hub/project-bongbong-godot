"""Prepare the selected pose as a 192px chroma still for Sprite gen video."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
WORK = Path(__file__).resolve().parent
SOURCE = ROOT / "experiments/sprite-gen-run/arms-up-pose-candidates/pose_C_big_stride.png"
OUT = WORK / "base_green.png"
CANVAS = (192, 192)
FOOT_ANCHOR = (95, 174)
TARGET_HEIGHT = 162
KEY = (0, 255, 0, 255)


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    mask = source.getchannel("A").point(lambda alpha: 255 if alpha >= 64 else 0)
    bounds = mask.getbbox()
    if bounds is None:
        raise ValueError("selected pose has no visible character")
    cropped = source.crop(bounds)
    target_width = round(cropped.width * TARGET_HEIGHT / cropped.height)
    reduced = cropped.resize((target_width, TARGET_HEIGHT), Image.Resampling.NEAREST)
    # Keep single-pixel edges crisp before compositing onto the video key.
    reduced.putalpha(reduced.getchannel("A").point(lambda alpha: 255 if alpha >= 128 else 0))
    if target_width > 180:
        raise ValueError("pose exceeds the intended character width")
    offset = (FOOT_ANCHOR[0] - target_width // 2, FOOT_ANCHOR[1] - TARGET_HEIGHT)
    canvas = Image.new("RGBA", CANVAS, KEY)
    canvas.alpha_composite(reduced, offset)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(OUT)
    print(f"source_bounds={bounds} target_size={reduced.size} offset={offset} output={OUT}")


if __name__ == "__main__":
    main()

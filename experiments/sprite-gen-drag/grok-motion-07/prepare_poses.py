from pathlib import Path

from PIL import Image


run_dir = Path(__file__).resolve().parent
source_dir = run_dir.parent / "grok-motion-06/refined20"
for number, name in ((1, "first.png"), (20, "last.png")):
    with Image.open(source_dir / f"drag_{number:02d}.png") as original:
        sprite = original.convert("RGBA")
        background = Image.new("RGBA", sprite.size, (255, 0, 255, 255))
        background.alpha_composite(sprite)
        background.convert("RGB").save(run_dir / name)

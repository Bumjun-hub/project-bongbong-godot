"""Pad the reviewed 24-frame strip onto the existing Godot canvas."""
from pathlib import Path
import json
from PIL import Image, ImageDraw

work = Path(__file__).resolve().parent / "loop-long-47-70"
metadata = json.loads((work / "run-long.strip.json").read_text())
assert (metadata["frames"], metadata["w"], metadata["h"]) == (24, 105, 167)
strip = Image.open(work / "run-long.strip.png").convert("RGBA")
assert strip.size == (105 * 24, 167)
frames = []
for i in range(24):
    crop = strip.crop((i * 105, 0, (i + 1) * 105, 167))
    canvas = Image.new("RGBA", (192, 192))
    canvas.alpha_composite(crop, (43, 7))
    canvas.save(work / f"run_{i + 1:02}.png")
    frames.append(canvas)
contact = Image.new("RGBA", (192 * 6, 210 * 4), (37, 46, 57, 255))
draw = ImageDraw.Draw(contact)
for i, frame in enumerate(frames):
    x = i % 6 * 192
    y = i // 6 * 210
    contact.alpha_composite(frame, (x, y + 18))
    draw.text((x + 5, y + 3), str(i + 47), fill="white")
contact.save(work / "unadjusted.contact.png")
print("bounds:", [frame.getbbox() for frame in frames])

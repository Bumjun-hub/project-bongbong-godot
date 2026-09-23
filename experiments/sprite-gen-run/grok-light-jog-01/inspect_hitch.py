"""Inspect frame-to-frame changes in the published 24-frame loop."""
from pathlib import Path
import numpy as np
from PIL import Image

root = Path(__file__).resolve().parents[3] / "assets/character/run/light_jog_01"
frames = [np.asarray(Image.open(root / f"run_{i:02}.png").convert("RGBA"), dtype=np.float32) for i in range(1, 25)]
regions = {"head": (0, 105), "torso": (105, 137), "legs": (137, 192), "all": (0, 192)}

def diff(a, b, top, bottom):
    # Composite both on a neutral background before measuring visible changes.
    a = a[top:bottom]
    b = b[top:bottom]
    bg = np.array([37, 46, 57], dtype=np.float32)
    av = (a[..., :3] * a[..., 3:4] + bg * (255 - a[..., 3:4])) / 255
    bv = (b[..., :3] * b[..., 3:4] + bg * (255 - b[..., 3:4])) / 255
    return float(np.abs(av - bv).mean())

print("transition  head  torso  legs  all")
for i, frame in enumerate(frames):
    nxt = frames[(i + 1) % 24]
    values = [diff(frame, nxt, *region) for region in regions.values()]
    print(f"{i + 1:02}->{(i + 1) % 24 + 1:02} " + " ".join(f"{v:6.2f}" for v in values))

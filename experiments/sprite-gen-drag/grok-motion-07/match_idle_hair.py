"""Apply the IDLE black hair palette to the active 20-frame DRAG cycle."""

from pathlib import Path
import sys

import numpy as np
from PIL import Image


RUN_DIR = Path(__file__).resolve().parent
PROJECT = RUN_DIR.parents[2]
sys.path.insert(0, str(PROJECT / "experiments"))
from character_palette import match_idle_hair_palette


ASSETS = PROJECT / "assets/character/drag/grok_struggle_01"
for number in range(1, 21):
    path = ASSETS / f"drag_{number:02d}.png"
    original = Image.open(path).convert("RGBA")
    updated = match_idle_hair_palette(original)
    assert np.array_equal(np.asarray(original.getchannel("A")), np.asarray(updated.getchannel("A")))
    updated.save(path)
print("matched IDLE hair palette on 20 active DRAG frames")

"""Find a 20-frame full cycle that keeps the animated feet continuous."""

from itertools import combinations
from pathlib import Path

import numpy as np
from PIL import Image


run_dir = Path(__file__).resolve().parent
source_dir = run_dir / "frames/keyed"
frames = [
    np.array(Image.open(source_dir / f"frame-{number:04d}.png").convert("RGBA").resize((192, 192), Image.Resampling.NEAREST)).astype(np.int16)
    for number in range(1, 25)
]
region = (slice(115, 180), slice(75, 175))


def shoe_positions(frame):
    yy, xx = np.indices(frame.shape[:2])
    rgb = frame[:, :, :3]
    mask = (
        (yy > 135)
        & (frame[:, :, 3] > 150)
        & (rgb.min(axis=2) > 120)
        & (rgb.max(axis=2) - rgb.min(axis=2) < 80)
    )
    return np.array([xx[mask & (xx < 123)].mean(), xx[mask & (xx >= 123)].mean()])


shoes = [shoe_positions(frame) for frame in frames]
cost = {}
for i in range(24):
    for j in range(24):
        pixels = float(np.mean(np.abs(frames[i][region] - frames[j][region])))
        shoe_jump = float(np.abs(shoes[i] - shoes[j]).sum())
        cost[(i, j)] = pixels + 0.65 * shoe_jump

candidates = []
for omitted in combinations(range(2, 24), 4):
    chosen = [number for number in range(1, 25) if number not in omitted]
    if max(chosen[i + 1] - chosen[i] for i in range(19)) > 3:
        continue
    edges = [cost[(chosen[i] - 1, chosen[(i + 1) % 20] - 1)] for i in range(20)]
    candidates.append((max(edges), sum(edges), omitted, chosen, edges))

candidates.sort()
for peak, total, omitted, chosen, edges in candidates[:10]:
    print("max", round(peak, 1), "total", round(total, 1), "omit", omitted, "chosen", chosen)
    print("edges", [round(value, 1) for value in edges])

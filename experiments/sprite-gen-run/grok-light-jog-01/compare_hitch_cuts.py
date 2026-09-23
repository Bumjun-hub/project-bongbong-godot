"""Rank small frame cuts by change uniformity and loop-boundary change."""
from pathlib import Path
from itertools import combinations
import numpy as np
from PIL import Image

root = Path(__file__).resolve().parents[3] / "assets/character/run/light_jog_01"
frames = [np.asarray(Image.open(root / f"run_{i:02}.png").convert("RGBA"), dtype=np.float32) for i in range(1, 25)]
bg = np.array([37, 46, 57], dtype=np.float32)
visible = [(frame[..., :3] * frame[..., 3:4] + bg * (255 - frame[..., 3:4])) / 255 for frame in frames]
dist = np.array([[np.abs(a - b).mean() for b in visible] for a in visible])

def score(kept):
    changes = np.array([dist[kept[i], kept[(i + 1) % len(kept)]] for i in range(len(kept))])
    median = np.median(changes)
    return (
        changes.std() / changes.mean()
        + max(0, 0.70 * median - changes.min()) / median
        + max(0, changes.max() - 1.6 * median) / median,
        changes,
    )

suspects = [0, 1, 2, 5, 10, 11, 12, 13, 18, 19, 22, 23]
results = []
for count in (0, 1, 2, 3):
    for removed in combinations(suspects, count):
        kept = [i for i in range(24) if i not in removed]
        s, changes = score(kept)
        results.append((s, removed, changes.min(), changes.max(), changes[-1], np.median(changes)))
for s, removed, low, high, seam, median in sorted(results)[:20]:
    print(f"remove {[i+1 for i in removed]} score={s:.3f} min={low:.2f} max={high:.2f} seam={seam:.2f} med={median:.2f}")

"""Pose-adjust the accepted Run cels without resampling their pixel colors.

Each limb tip follows a small, smooth displacement anchored at its joint.  The
source art is sampled with nearest-neighbor pixels so hair, face, outlines, and
shading remain the approved art.  Outputs are review candidates only.
"""

from pathlib import Path
from collections import deque

import numpy as np
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "assets/character/run/right_three_quarter"
OUT = Path(__file__).resolve().parent / "pose-redraw-candidate"
OUT.mkdir(parents=True, exist_ok=True)

# Per-frame (back arm, front arm, back shoe, front shoe) displacements.
# Positive x faces the direction of travel; positive y moves toward the floor.
SHIFTS = [
    ((-3, -2), (3, -2), (-4, -2), (3, 2)),
    ((-1, 3), (4, -3), (-4, -3), (1, 3)),
    ((3, 2), (-3, 1), (-3, -2), (4, -2)),
    ((0, 0), (2, -2), (-5, 0), (5, -3)),
    ((0, 0), (-2, 2), (-3, 2), (3, -4)),
    ((0, 0), (3, 1), (-5, -2), (4, 0)),
    ((2, -2), (-2, 3), (-2, 2), (3, 2)),
    ((-4, 2), (4, -3), (-5, -3), (4, -1)),
]

# The contact/flight arc; ground remains close to the old 174px anchor.
BODY_OFFSET = [(0, 1), (1, 0), (2, -2), (2, -4), (1, 1), (1, -1), (0, 1), (0, -1)]
ARM_CENTERS = [
    ((58, 126), (130, 119)),
    ((62, 126), (130, 119)),
    ((80, 128), (119, 121)),
    ((101, 122), (113, 121)),
    ((101, 122), (113, 121)),
    ((101, 122), (113, 121)),
    ((80, 128), (119, 121)),
    ((58, 126), (130, 119)),
]
SHOE_CENTERS = [
    ((75, 159), (115, 166)),
    ((80, 154), (110, 166)),
    ((98, 165), (120, 160)),
    ((68, 149), (120, 160)),
    ((68, 149), (120, 160)),
    ((68, 148), (116, 168)),
    ((90, 169), (119, 160)),
    ((75, 159), (115, 166)),
]


def add_field(dx, dy, xx, yy, center, shift, sx, sy):
    cx, cy = center
    w = np.exp(-0.5 * (((xx - cx) / sx) ** 2 + ((yy - cy) / sy) ** 2))
    dx += shift[0] * w
    dy += shift[1] * w


def pose_warp(src, index):
    pix = np.asarray(src.convert("RGBA"), dtype=np.uint8)
    yy, xx = np.mgrid[0:192, 0:192].astype(np.float32)
    dx = np.zeros((192, 192), dtype=np.float32)
    dy = np.zeros((192, 192), dtype=np.float32)
    back_arm, front_arm, back_shoe, front_shoe = SHIFTS[index]
    ac0, ac1 = ARM_CENTERS[index]
    lc0, lc1 = SHOE_CENTERS[index]
    # Arm fields fade naturally before the shoulders and face.
    if index not in (3, 4, 5):
        add_field(dx, dy, xx, yy, ac0, back_arm, 12, 10)
    add_field(dx, dy, xx, yy, ac1, front_arm, 11, 10)
    # Shoe fields influence knees while keeping hips and shirt fixed.
    add_field(dx, dy, xx, yy, lc0, back_shoe, 17, 16)
    add_field(dx, dy, xx, yy, lc1, front_shoe, 18, 18)
    sx = np.rint(xx - dx).astype(np.int16)
    sy = np.rint(yy - dy).astype(np.int16)
    good = (sx >= 0) & (sx < 192) & (sy >= 0) & (sy < 192)
    dest = np.zeros_like(pix)
    dest[good] = pix[sy[good], sx[good]]
    dest[dest[:, :, 3] <= 8] = 0
    return Image.fromarray(dest, "RGBA")


def remove_isolated_speed_lines(frame):
    """The old effect lines are detached from the figure and flicker at new tempos."""
    a = np.asarray(frame.getchannel("A"))
    keep = np.zeros((192, 192), dtype=bool)
    seen = np.zeros((192, 192), dtype=bool)
    for y in range(192):
        for x in range(192):
            if seen[y, x] or a[y, x] < 64:
                continue
            points = []
            q = deque([(x, y)])
            seen[y, x] = True
            while q:
                px, py = q.popleft()
                points.append((px, py))
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if 0 <= nx < 192 and 0 <= ny < 192 and not seen[ny, nx] and a[ny, nx] >= 64:
                        seen[ny, nx] = True
                        q.append((nx, ny))
            if len(points) >= 100:
                for px, py in points:
                    keep[py, px] = True
    # Preserve soft outline pixels next to the retained opaque figure.
    for _ in range(2):
        keep = keep | np.roll(keep, 1, 0) | np.roll(keep, -1, 0) | np.roll(keep, 1, 1) | np.roll(keep, -1, 1)
    pix = np.asarray(frame).copy()
    pix[~keep] = 0
    return Image.fromarray(pix, "RGBA")


frames = []
for k in range(8):
    src = Image.open(SOURCE / f"run_{k + 1:02}.png")
    warped = pose_warp(src, k)
    if k in (4, 5):
        if k == 4:
            # Turn the old duplicate leap into the opposite foot's landing.
            donor_name, donor_index = "run_07.png", 6
        else:
            # The source's sixth rear shoe was a blurred streak.  A clean bent
            # recovery leg from pose 1 completes this new crossed-arm pose.
            donor_name, donor_index = "run_01.png", 0
        donor = pose_warp(Image.open(SOURCE / donor_name), donor_index)
        cleaned = Image.new("RGBA", (192, 192))
        cleaned.alpha_composite(donor.crop((0, 137, 192, 192)), (0, 137))
        cleaned.alpha_composite(warped.crop((0, 0, 192, 137)), (0, 0))
        hem = np.asarray(warped.crop((75, 132, 122, 143))).copy()
        jeans = (hem[:, :, 2].astype(int) > hem[:, :, 0].astype(int) + 20) & (hem[:, :, 2].astype(int) > hem[:, :, 1].astype(int) + 10)
        hem[jeans] = 0
        cleaned.alpha_composite(Image.fromarray(hem, "RGBA"), (75, 132))
        warped = cleaned
    canvas = Image.new("RGBA", (192, 192), (0, 0, 0, 0))
    canvas.alpha_composite(warped, BODY_OFFSET[k])
    canvas = remove_isolated_speed_lines(canvas)
    frames.append(canvas)
    canvas.save(OUT / f"run_{k + 1:02}.png")

contact = Image.new("RGBA", (4 * 192, 2 * 192), (42, 52, 63, 255))
draw = ImageDraw.Draw(contact)
for k, frame in enumerate(frames):
    x = (k % 4) * 192
    y = (k // 4) * 192
    contact.alpha_composite(frame, (x, y))
    draw.text((x + 7, y + 5), str(k + 1), fill=(255, 255, 255, 255))
contact.save(OUT / "contact.png")
frames[0].save(OUT / "preview.gif", save_all=True, append_images=frames[1:], duration=[80, 60, 60, 80, 80, 60, 60, 80], loop=0, disposal=2, transparency=0)
print(OUT)

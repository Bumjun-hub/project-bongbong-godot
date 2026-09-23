"""Preview new AI pose legs beneath the accepted hand-pixelled upper body."""
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
BASE = HERE / "pose-redraw-candidate"
SHEET = Image.open(r"C:\Users\USER\.codex\generated_images\01a0ce2f-b2c6-7de3-8e40-45d2501d66c9\exec-f05fa3c6-2874-4313-bf13-8cd634abefcf.png").convert("RGBA")
OUT = HERE / "hybrid-preview"
OUT.mkdir(exist_ok=True)


def cell(k):
    c, r = k % 4, k // 4
    box = (round(c * SHEET.width / 4), round(r * SHEET.height / 2),
           round((c + 1) * SHEET.width / 4), round((r + 1) * SHEET.height / 2))
    im = SHEET.crop(box)
    bbox = im.getchannel("A").point(lambda a: 255 if a > 32 else 0).getbbox()
    im = im.crop(bbox)
    w = round(im.width * 156 / im.height)
    im = im.resize((w, 156), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (192, 192))
    canvas.alpha_composite(im, ((192 - w) // 2, 16))
    return canvas


def new_lower(k, mirror=False):
    im = cell(k)
    lower = im.crop((48, 125, 145, 174))
    lower = lower.resize((97, 34), Image.Resampling.NEAREST)
    if mirror:
        lower = lower.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    canvas = Image.new("RGBA", (192, 192))
    canvas.alpha_composite(lower, (48, 139))
    return canvas


mapping = {1: (1, False), 2: (2, False), 5: (1, True), 6: (2, True)}
frames = []
for k in range(8):
    original = Image.open(BASE / f"run_{k + 1:02}.png").convert("RGBA")
    if k in mapping:
        leg_index, mirror = mapping[k]
        upper = original.crop((0, 0, 192, 139))
        frame = Image.new("RGBA", (192, 192))
        frame.alpha_composite(new_lower(leg_index, mirror))
        frame.alpha_composite(upper)
        # A short shirt hem conceals the seam at the joint.
        hem = original.crop((75, 133, 120, 145))
        frame.alpha_composite(hem, (75, 133))
    else:
        frame = original
    frames.append(frame)
    frame.save(OUT / f"run_{k+1:02}.png")

contact = Image.new("RGBA", (768, 384), (42, 52, 63, 255))
for k, im in enumerate(frames):
    contact.alpha_composite(im, ((k % 4) * 192, (k // 4) * 192))
contact.save(OUT / "contact.png")

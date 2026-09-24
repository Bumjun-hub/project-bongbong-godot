"""Finish the selected 20-frame Grok cycle and produce review artifacts."""

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


run_dir = Path(__file__).resolve().parent
source_dir = run_dir / "selected20"
output_dir = run_dir / "final20"
output_dir.mkdir(exist_ok=True)
arrays = []
displayed = []
for number in range(1, 21):
    frame = np.array(Image.open(source_dir / f"drag_{number:02d}.png").convert("RGBA"))
    red = frame[:, :, 0].astype(np.int16)
    green = frame[:, :, 1].astype(np.int16)
    blue = frame[:, :, 2].astype(np.int16)
    yy, xx = np.indices(red.shape)
    hand_region = (frame[:, :, 3] > 128) & (yy > 65) & (yy < 155) & ((xx < 83) | (xx > 125))
    pink = hand_region & (red > 140) & (blue > green + 25) & (blue > red * 0.5) & (red > green * 1.3)
    yellow = hand_region & (red > 150) & (green > red * 0.55) & (blue < green * 0.65)
    frame[pink, 1] = np.clip(np.maximum(green[pink], red[pink] * 0.73), 0, 255).astype(np.uint8)
    frame[pink, 2] = np.clip(np.minimum(blue[pink], frame[pink, 1] * 0.79), 0, 255).astype(np.uint8)
    frame[yellow, 2] = np.clip(green[yellow] * 0.78, 0, 255).astype(np.uint8)
    image = Image.fromarray(frame, "RGBA")
    image.save(output_dir / f"drag_{number:02d}.png")
    arrays.append(frame.astype(np.int16))

    checker = Image.new("RGB", (192, 192), "white")
    draw = ImageDraw.Draw(checker)
    for y in range(0, 192, 16):
        for x in range(0, 192, 16):
            shade = 204 if (x // 16 + y // 16) % 2 else 238
            draw.rectangle((x, y, x + 15, y + 15), fill=(shade,) * 3)
    checker.paste(image, (0, 0), image)
    displayed.append(checker)

displayed[0].save(
    run_dir / "preview_final.gif",
    save_all=True,
    append_images=displayed[1:],
    duration=40,
    loop=0,
    optimize=False,
)
contact = Image.new("RGB", (208 * 5, 208 * 4), "white")
draw = ImageDraw.Draw(contact)
for index, image in enumerate(displayed):
    x, y = index % 5 * 208, index // 5 * 208
    contact.paste(image, (x, y))
    draw.text((x + 4, y + 194), f"{index + 1:02d}", fill="black")
contact.save(run_dir / "contact_final.png")

full_changes = [float(np.mean(np.abs(arrays[i] - arrays[(i + 1) % 20]))) for i in range(20)]
leg_roi = (slice(115, 180), slice(75, 175))
leg_changes = [float(np.mean(np.abs(arrays[i][leg_roi] - arrays[(i + 1) % 20][leg_roi]))) for i in range(20)]
report = {
    "frames": 20,
    "size": [192, 192],
    "frame_duration_ms": 40,
    "loop": 0,
    "mean_full_change": float(np.mean(full_changes[:-1])),
    "seam_full_change": full_changes[-1],
    "mean_leg_change": float(np.mean(leg_changes[:-1])),
    "seam_leg_change": leg_changes[-1],
    "max_leg_change": max(leg_changes),
}
(run_dir / "final_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print(json.dumps(report, indent=2))

from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

work = Path(__file__).resolve().parent / "loop-cut-21"
sheet = Image.open(work / "run_light_21_smooth.png").convert("RGBA")
assert sheet.size == (192 * 21, 192)
frames = [sheet.crop((192 * i, 0, 192 * (i + 1), 192)) for i in range(21)]
original = Image.open(work / "run_light_21.png").convert("RGBA")
for i in range(21):
    if i not in (14, 15):
        assert frames[i].tobytes() == original.crop((192*i,0,192*(i+1),192)).tobytes()
contact = Image.new("RGBA", (192 * 7, 210 * 3), (37, 46, 57, 255))
draw = ImageDraw.Draw(contact)
for i, frame in enumerate(frames):
    x = i % 7 * 192
    y = i // 7 * 210
    contact.alpha_composite(frame, (x, y + 18))
    draw.text((x + 5, y + 3), str(i + 1), fill="white")
contact.save(work / "run_light_21_smooth.contact.png")
preview = []
for frame in frames:
    canvas = Image.new("RGBA", (192, 192), (37, 46, 57, 255))
    canvas.alpha_composite(frame)
    preview.append(canvas.convert("RGB"))
preview[0].save(
    work / "run_light_21_smooth.preview.gif",
    save_all=True,
    append_images=preview[1:],
    duration=[40 if i in (4, 8, 12, 16, 20) else 50 for i in range(1, 22)],
    loop=0,
    disposal=2,
)
def bounds(frame):
    a = np.asarray(frame.getchannel("A"))
    y, x = np.where(a >= 128)
    return int(y.min()), int(y.max())
print("late bounds:", [(i+1,bounds(frames[i])) for i in range(12,21)])

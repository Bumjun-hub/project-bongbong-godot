"""Preview the 21-frame loop with repeated poses removed, without publishing it."""
from pathlib import Path
from PIL import Image, ImageDraw

work = Path(__file__).resolve().parent
asset = work.parents[2] / "assets/character/run/light_jog_01"
out = work / "loop-cut-21"
out.mkdir(exist_ok=True)
selected = [i for i in range(1, 25) if i not in {6, 12, 19}]
frames = [Image.open(asset / f"run_{i:02}.png").convert("RGBA") for i in selected]
for j, frame in enumerate(frames, 1):
    frame.save(out / f"run_{j:02}.png")
contact = Image.new("RGBA", (192 * 7, 210 * 3), (37, 46, 57, 255))
draw = ImageDraw.Draw(contact)
for j, (number, frame) in enumerate(zip(selected, frames)):
    x = j % 7 * 192
    y = j // 7 * 210
    contact.alpha_composite(frame, (x, y + 18))
    draw.text((x + 5, y + 3), str(number), fill="white")
contact.save(out / "contact.png")
preview = []
for frame in frames:
    canvas = Image.new("RGBA", (192, 192), (37, 46, 57, 255))
    canvas.alpha_composite(frame)
    preview.append(canvas.convert("RGB"))
preview[0].save(
    out / "preview.gif",
    save_all=True,
    append_images=preview[1:],
    duration=[40 if i in (4, 8, 12, 16, 20) else 50 for i in range(1, 22)],
    loop=0,
    disposal=2,
)
print("source frames:", selected)

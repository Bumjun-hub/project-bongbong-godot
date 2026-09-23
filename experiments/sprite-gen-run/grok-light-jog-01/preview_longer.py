from pathlib import Path
from PIL import Image, ImageDraw

work = Path(__file__).resolve().parent / "loop-long-47-70"
sheet = Image.open(work / "run_light_24.png").convert("RGBA")
assert sheet.size == (192 * 24, 192)
frames = [sheet.crop((192 * i, 0, 192 * (i + 1), 192)) for i in range(24)]
contact = Image.new("RGBA", (192 * 6, 210 * 4), (37, 46, 57, 255))
draw = ImageDraw.Draw(contact)
for i, frame in enumerate(frames):
    x = i % 6 * 192
    y = i // 6 * 210
    contact.alpha_composite(frame, (x, y + 18))
    draw.text((x + 5, y + 3), str(i + 1), fill="white")
contact.save(work / "run_light_24.contact.png")
preview = []
for frame in frames:
    canvas = Image.new("RGBA", (192, 192), (37, 46, 57, 255))
    canvas.alpha_composite(frame)
    preview.append(canvas.convert("RGB"))
preview[0].save(
    work / "run_light_24.preview.gif",
    save_all=True,
    append_images=preview[1:],
    # GIF stores centiseconds; distribute four 50 ms frames to keep the full loop at 1 s.
    duration=[40, 40, 40, 40, 40, 50] * 4,
    loop=0,
    disposal=2,
)
print("bounds:", [frame.getbbox() for frame in frames])

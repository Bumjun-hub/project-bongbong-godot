from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).parent / "loop-reviewed"
sheet = Image.open(root / "run_light_01.png").convert("RGBA")
assert sheet.size == (1920, 192)
frames = [sheet.crop((192 * i, 0, 192 * (i + 1), 192)) for i in range(10)]
background = (37, 46, 57, 255)
contact = Image.new("RGBA", (192 * 5, 210 * 2), background)
draw = ImageDraw.Draw(contact)
for i, frame in enumerate(frames):
    x = (i % 5) * 192
    y = (i // 5) * 210
    contact.alpha_composite(frame, (x, y + 18))
    draw.text((x + 5, y + 3), str(i + 1), fill="white")
contact.save(root / "run_light_01.contact.png")
preview = []
for frame in frames:
    canvas = Image.new("RGBA", (192, 192), background)
    canvas.alpha_composite(frame)
    preview.append(canvas.convert("RGB"))
preview[0].save(root / "run_light_01.preview.gif", save_all=True, append_images=preview[1:], duration=[56,55]*5, loop=0, disposal=2)
print("bounds:", [frame.getbbox() for frame in frames])

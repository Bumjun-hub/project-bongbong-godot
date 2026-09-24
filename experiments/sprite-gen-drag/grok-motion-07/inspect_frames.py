from pathlib import Path

from PIL import Image, ImageDraw


run_dir = Path(__file__).resolve().parent
keyed_dir = run_dir / "frames/keyed"
paths = sorted(keyed_dir.glob("frame-*.png"))
contact = Image.new("RGB", (208 * 5, 208 * 5), "white")
draw = ImageDraw.Draw(contact)
for index, path in enumerate(paths):
    with Image.open(path) as source:
        frame = source.convert("RGBA").resize((192, 192), Image.Resampling.NEAREST)
    checker = Image.new("RGB", (192, 192), "white")
    tiles = ImageDraw.Draw(checker)
    for y in range(0, 192, 16):
        for x in range(0, 192, 16):
            shade = 204 if (x // 16 + y // 16) % 2 else 238
            tiles.rectangle((x, y, x + 15, y + 15), fill=(shade,) * 3)
    checker.paste(frame, (0, 0), frame)
    x, y = index % 5 * 208, index // 5 * 208
    contact.paste(checker, (x, y))
    draw.text((x + 4, y + 194), f"{index + 1:02d}", fill="black")
contact.save(run_dir / "contact_25.png")

from pathlib import Path
from PIL import Image, ImageDraw

work = Path(__file__).resolve().parent
source = work / "frames/keyed"
for start, end in ((25, 48), (49, 72)):
    sheet = Image.new("RGBA", (192 * 6, 208 * 4), (37, 46, 57, 255))
    draw = ImageDraw.Draw(sheet)
    for i, number in enumerate(range(start, end + 1)):
        frame = Image.open(source / f"frame-{number:04}.png").convert("RGBA")
        frame = frame.resize((192, 192), Image.Resampling.NEAREST)
        x = (i % 6) * 192
        y = (i // 6) * 208
        sheet.alpha_composite(frame, (x, y + 16))
        draw.text((x + 5, y + 2), str(number), fill="white")
    sheet.save(work / f"source-{start:02}-{end:02}.png")

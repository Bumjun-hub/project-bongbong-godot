from pathlib import Path

from PIL import Image, ImageDraw


run_dir = Path(__file__).resolve().parent
source_dir = run_dir / "frames/keyed"
output_dir = run_dir / "selected20"
output_dir.mkdir(exist_ok=True)
source_indices = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 13, 16, 17, 18, 19, 20, 21, 22, 23, 24]
assert len(set(source_indices)) == 20
displayed = []
for number, source_number in enumerate(source_indices, 1):
    with Image.open(source_dir / f"frame-{source_number:04d}.png") as source:
        frame = source.convert("RGBA").resize((192, 192), Image.Resampling.NEAREST)
    frame.save(output_dir / f"drag_{number:02d}.png")
    checker = Image.new("RGB", (192, 192), "white")
    draw = ImageDraw.Draw(checker)
    for y in range(0, 192, 16):
        for x in range(0, 192, 16):
            shade = 204 if (x // 16 + y // 16) % 2 else 238
            draw.rectangle((x, y, x + 15, y + 15), fill=(shade,) * 3)
    checker.paste(frame, (0, 0), frame)
    displayed.append(checker)

displayed[0].save(
    run_dir / "preview_20.gif",
    save_all=True,
    append_images=displayed[1:],
    duration=40,
    loop=0,
    optimize=False,
)
contact = Image.new("RGB", (208 * 5, 208 * 4), "white")
draw = ImageDraw.Draw(contact)
for index, frame in enumerate(displayed):
    x, y = index % 5 * 208, index // 5 * 208
    contact.paste(frame, (x, y))
    draw.text((x + 4, y + 194), f"{index + 1:02d} ({source_indices[index]})", fill="black")
contact.save(run_dir / "contact_20.png")
print(source_indices)

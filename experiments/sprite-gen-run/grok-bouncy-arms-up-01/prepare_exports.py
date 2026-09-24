"""Place the reviewed Sprite gen loop on the project's 192px foot anchor."""

from pathlib import Path
import json

from PIL import Image, ImageDraw


WORK = Path(__file__).resolve().parent
LOOP = WORK / "loop-selected"
OUT = WORK / "prepared"
CANVAS = (192, 192)
FOOT_ANCHOR = (95, 174)


def main() -> None:
    meta = json.loads((LOOP / "run_bouncy.strip.json").read_text(encoding="utf-8"))
    count, width, height = (int(meta[key]) for key in ("frames", "w", "h"))
    assert count == 28 and int(meta["body_h"]) == 162
    assert width <= 190 and height <= FOOT_ANCHOR[1]
    strip = Image.open(LOOP / "run_bouncy.strip.png").convert("RGBA")
    assert strip.size == (count * width, height)
    OUT.mkdir(parents=True, exist_ok=True)
    offset = (FOOT_ANCHOR[0] - width // 2, FOOT_ANCHOR[1] - height)
    frames = []
    for index in range(count):
        sprite = strip.crop((index * width, 0, (index + 1) * width, height))
        frame = Image.new("RGBA", CANVAS)
        frame.alpha_composite(sprite, offset)
        frame.save(OUT / f"run_{index + 1:02}.png")
        frames.append(frame)
    sheet = Image.new("RGBA", (CANVAS[0] * count, CANVAS[1]))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, (index * CANVAS[0], 0))
    sheet.save(OUT / "run_bouncy_01.png")
    columns = 7
    contact = Image.new("RGBA", (columns * 192, 4 * 210), (37, 46, 57, 255))
    draw = ImageDraw.Draw(contact)
    preview = []
    for index, frame in enumerate(frames):
        x, y = index % columns * 192, index // columns * 210
        contact.alpha_composite(frame, (x, y + 18))
        draw.text((x + 5, y + 3), str(index + 1), fill="white")
        background = Image.new("RGBA", CANVAS, (37, 46, 57, 255))
        background.alpha_composite(frame)
        preview.append(background.convert("RGB"))
    contact.save(OUT / "contact.png")
    ticks = [round(index * 100 / 24) for index in range(count + 1)]
    preview_durations = [10 * (ticks[index + 1] - ticks[index]) for index in range(count)]
    millisecond_ticks = [round(index * 1000 / 24) for index in range(count + 1)]
    frame_durations = [millisecond_ticks[index + 1] - millisecond_ticks[index] for index in range(count)]
    preview[0].save(
        OUT / "preview.gif",
        save_all=True,
        append_images=preview[1:],
        duration=preview_durations,
        loop=0,
        disposal=2,
    )
    (OUT / "metadata.json").write_text(
        json.dumps(
            {
                "frames": count,
                "fps": 24,
                "cycle_seconds": count / 24,
                "canvas": list(CANVAS),
                "foot_anchor": list(FOOT_ANCHOR),
                "placement": list(offset),
                "source_frames_1_based": [68, 95],
                "seam_ratio": 1.0648,
                "frame_durations_ms": frame_durations,
                "preview_durations_ms": preview_durations,
            },
            indent=2,
        ) + "\n",
        encoding="utf-8",
    )
    (OUT / "asset.json").write_text(
        json.dumps(
            {
                "kind": "sprite-gen-asset",
                "version": 1,
                "anchor": list(FOOT_ANCHOR),
                "frames": [
                    {"file": f"run_{index + 1:02}.png", "duration": frame_durations[index] / 1000}
                    for index in range(count)
                ],
            },
            indent=2,
        ) + "\n",
        encoding="utf-8",
    )
    print(f"prepared {count} frames at {OUT}; placement={offset}; durations={sum(frame_durations)}ms")


if __name__ == "__main__":
    main()

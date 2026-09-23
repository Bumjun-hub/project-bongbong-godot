"""Compare the published end of the run with its unshifted source frames."""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

work = Path(__file__).resolve().parent
asset = work.parents[2] / "assets/character/run/light_jog_01"
raw = work / "loop-long-47-70"
source_numbers = [16, 17, 18, 20, 21, 22, 23, 24]
sheet = Image.new("RGBA", (192 * 8, 212 * 2), (37, 46, 57, 255))
draw = ImageDraw.Draw(sheet)

def opaque_bounds(frame):
    alpha = np.asarray(frame.getchannel("A"))
    ys, xs = np.where(alpha >= 128)
    return (int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max()))

print("final source  top_final top_raw bottom_final bottom_raw")
for j, source_number in enumerate(source_numbers):
    final_number = j + 14
    final = Image.open(asset / f"run_{final_number:02}.png").convert("RGBA")
    original = Image.open(raw / f"run_{source_number:02}.png").convert("RGBA")
    xf, yf, xr, yr = (*opaque_bounds(final)[0:2], *opaque_bounds(original)[0:2])
    bottom_f = opaque_bounds(final)[3]
    bottom_r = opaque_bounds(original)[3]
    print(f"{final_number:02}    {source_number:02}      {yf:02}        {yr:02}       {bottom_f:03}          {bottom_r:03}")
    x = j * 192
    sheet.alpha_composite(final, (x, 18))
    sheet.alpha_composite(original, (x, 212 + 18))
    draw.text((x + 5, 2), f"final {final_number}", fill="white")
    draw.text((x + 5, 214), f"raw {source_number}", fill="white")
sheet.save(work / "late-motion-comparison.png")

"""Build the revised FALL intro and airborne loop from the user's Grok video.

The video contains a baked checkerboard, so we isolate its dark/color character
silhouette before using any frame as a transparent game asset.
"""

import json
from pathlib import Path
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parents[1]))
from character_palette import match_idle_hair_palette

RAW = ROOT / "raw"
OUT = ROOT / "candidate03"
OUT.mkdir(exist_ok=True)
SOURCES = range(3, 15)  # 0.58–1.04 s, native 24 fps: more clean poses
ARM_DONOR = ROOT.parents[2] / "assets/character/drag/grok_struggle_01/drag_05.png"
ARM_POLYGON = [
    (120, 104), (124, 100), (130, 98), (138, 98), (153, 99),
    (159, 102), (159, 116), (153, 120), (139, 119), (131, 117),
    (123, 113), (119, 110),
]
ARM_ANGLES = [-34, -33, -31, -28, -24, -18, -12, -6, 0, 6, 10, 8]
LEFT_ARM_POLYGON = [
    (44, 115), (52, 111), (66, 108), (76, 104), (86, 103),
    (90, 107), (90, 117), (84, 122), (74, 124), (60, 129),
    (50, 134), (44, 131),
]
LEFT_ARM_ERASE_DIAGONAL = [
    (73, 114), (84, 116), (84, 124), (75, 132),
    (67, 142), (48, 145), (47, 132), (59, 124),
]
LEFT_ARM_ERASE_DOWN = [
    (73, 114), (86, 117), (86, 124), (85, 132),
    (84, 139), (83, 144), (63, 145), (62, 133), (69, 125),
]


def second_arm(angle: float, shift_x: int) -> Image.Image:
    """Keep the existing shirt, cuff and hand pixels while changing arm angle."""
    donor = Image.open(ARM_DONOR).convert("RGBA")
    mask = Image.new("L", donor.size)
    ImageDraw.Draw(mask).polygon(ARM_POLYGON, fill=255)
    donor.putalpha(Image.composite(donor.getchannel("A"), Image.new("L", donor.size), mask))
    rotated = donor.rotate(angle, Image.Resampling.NEAREST, center=(121, 106))
    placed = Image.new("RGBA", donor.size)
    placed.alpha_composite(rotated, (shift_x, 0))
    return placed


def keep_left_arm_straight(base: Image.Image, donor: Image.Image, diagonal: bool, angle_deg: float = 0) -> Image.Image:
    """Replace the lowered forearm with a straight arm that can swing in air."""
    pose = base.copy()
    erase = LEFT_ARM_ERASE_DIAGONAL if diagonal else LEFT_ARM_ERASE_DOWN
    ImageDraw.Draw(pose).polygon(erase, fill=(0, 0, 0, 0))
    arm = donor.copy()
    mask = Image.new("L", donor.size)
    ImageDraw.Draw(mask).polygon(LEFT_ARM_POLYGON, fill=255)
    arm.putalpha(Image.composite(donor.getchannel("A"), Image.new("L", donor.size), mask))
    if angle_deg:
        arm = arm.rotate(angle_deg, Image.Resampling.NEAREST, center=(86, 108))
    pose.alpha_composite(arm)
    if not diagonal:
        # The lowered hand overlapped the shirt and jeans. Restore their
        # single-pixel left contour after erasing that hand.
        outline = ImageDraw.Draw(pose)
        for y in range(124, 146):
            edge = next((x for x in range(80, 100) if pose.getpixel((x, y))[3]), None)
            if edge is not None:
                outline.point((edge - 1, y), fill=(42, 36, 43, 255))
    return pose


def components(mask: np.ndarray, wanted: bool) -> list[list[tuple[int, int]]]:
    height, width = mask.shape
    seen = np.zeros_like(mask, dtype=bool)
    found = []
    for y in range(height):
        for x in range(width):
            if seen[y, x] or bool(mask[y, x]) != wanted:
                continue
            stack = [(x, y)]
            seen[y, x] = True
            component = []
            while stack:
                px, py = stack.pop()
                component.append((px, py))
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if 0 <= nx < width and 0 <= ny < height and not seen[ny, nx] and bool(mask[ny, nx]) == wanted:
                        seen[ny, nx] = True
                        stack.append((nx, ny))
            found.append(component)
    return found


def matte(rgb: np.ndarray) -> np.ndarray:
    channels = rgb.astype(np.int16)
    darkest = channels.min(axis=2)
    colour = channels.max(axis=2) - darkest
    # The two checkerboard tones are bright neutral grays. The character has
    # dark outline or real colour; white areas become enclosed silhouette holes.
    seed = (darkest < 187) | (colour > 23)
    closed = np.array(
        Image.fromarray(np.uint8(seed) * 255, "L")
        .filter(ImageFilter.MaxFilter(3))
        .filter(ImageFilter.MinFilter(3))
    ) > 0
    parts = components(closed, True)
    main = max(parts, key=len)
    mask = np.zeros_like(closed)
    for x, y in main:
        mask[y, x] = True
    # Preserve enclosed whites in eyes and shoes. All outside checker cells
    # remain transparent even when they share a colour with the character.
    for hole in components(mask, False):
        if all(0 < x < 191 and 0 < y < 191 for x, y in hole):
            for x, y in hole:
                mask[y, x] = True

    # White sneaker toes are open shapes, so the outline alone does not close
    # them as holes. Reconstruct the 32px checker pattern from clear border
    # columns and recover bright foot pixels that differ from that pattern.
    yy, xx = np.indices(mask.shape)
    outer = (xx < 35) | (xx > 160)
    tile = np.zeros((32, 32, 3), dtype=np.int16)
    for ty in range(32):
        for tx in range(32):
            samples = channels[outer & (yy % 32 == ty) & (xx % 32 == tx)]
            tile[ty, tx] = np.median(samples, axis=0)
    background = tile[yy % 32, xx % 32]
    difference = np.max(np.abs(channels - background), axis=2)
    nearby = np.array(Image.fromarray(np.uint8(mask) * 255, "L").filter(ImageFilter.MaxFilter(11))) > 0
    pale_shoe = (darkest > 242) | ((background.min(axis=2) < 225) & (darkest > 224) & (difference > 13))
    mask |= (yy >= 140) & (yy <= 180) & nearby & pale_shoe
    mask = np.array(
        Image.fromarray(np.uint8(mask) * 255, "L")
        .filter(ImageFilter.MaxFilter(3))
        .filter(ImageFilter.MinFilter(3))
    ) > 0
    main = max(components(mask, True), key=len)
    mask[:] = False
    for x, y in main:
        mask[y, x] = True
    return np.uint8(mask) * 255


def clean_video_edge(frame: Image.Image, late_leg_gap: bool = False) -> Image.Image:
    """Remove baked white video background while retaining the white sneakers."""
    pixels = np.array(frame.convert("RGBA"))
    rgb = pixels[:, :, :3].astype(np.int16)
    spread = rgb.max(axis=2) - rgb.min(axis=2)
    brightness = rgb.mean(axis=2)
    yy, xx = np.indices(pixels.shape[:2])

    if late_leg_gap:
        # The nearly straight late poses contain a pale piece of the baked
        # checkerboard between the legs, separate from the white sneakers.
        gap = (94 <= xx) & (xx <= 105) & (150 <= yy) & (yy <= 168) & (spread < 25) & (brightness > 110)
        pixels[gap] = (0, 0, 0, 0)

    solid = pixels[:, :, 3] > 0
    interior = np.array(Image.fromarray(np.uint8(solid) * 255, "L").filter(ImageFilter.MinFilter(3))) > 0
    pale_edge = solid & ~interior & (spread < 25) & (brightness > 95)
    pixels[pale_edge] = (0, 0, 0, 0)

    # The baked checkerboard sometimes reaches two or three pixels inside the
    # hair outline. Peel only pale, near-neutral pixels exposed by the previous
    # pass; stop before the glasses and white shoes.
    for _ in range(12):
        solid = pixels[:, :, 3] > 0
        interior = np.array(Image.fromarray(np.uint8(solid) * 255, "L").filter(ImageFilter.MinFilter(3))) > 0
        hair_halo = solid & ~interior & (yy < 70) & (spread < 25) & (brightness > 95)
        if not np.any(hair_halo):
            break
        pixels[hair_halo] = (0, 0, 0, 0)

    # The video also baked white/near-white background *inside* the extracted
    # silhouette. Preserve real face whites (glasses, eyes, mouth) and shoes.
    # Find each sneaker by its large white patch in the lower part of the
    # frame, then protect nearby tiny shoe details.
    white = (pixels[:, :, 3] > 0) & (rgb.min(axis=2) > 190) & (spread < 30)
    shoe_guard = np.zeros(white.shape, dtype=bool)
    for component in components(white, True):
        if len(component) < 20 or min(y for _, y in component) < 140:
            continue
        left = max(0, min(x for x, _ in component) - 4)
        right = min(192, max(x for x, _ in component) + 5)
        top = max(0, min(y for _, y in component) - 5)
        bottom = min(192, max(y for _, y in component) + 5)
        shoe_guard[top:bottom, left:right] = True
    face_guard = (75 <= xx) & (xx <= 136) & (70 <= yy) & (yy <= 121)
    pixels[white & ~shoe_guard & ~face_guard] = (0, 0, 0, 0)

    if late_leg_gap:
        # The old lowered arm leaves a pale strip behind the raised arm. It
        # overlaps the broad face-white guard, so remove it by its position
        # outside the red torso, not by another global white threshold.
        for y in range(114, 133):
            row = pixels[y, 110:121, :3].astype(np.int16)
            red_shirt = (row[:, 0] > 75) & (row[:, 0] > row[:, 1] * 1.5) & (row[:, 0] > row[:, 2] * 1.3)
            red_x = np.flatnonzero(red_shirt & (pixels[y, 110:121, 3] > 0))
            if len(red_x):
                edge = int(red_x[-1]) + 110
                pixels[y, edge + 2:124] = (0, 0, 0, 0)
                outline = pixels[y, edge + 1, :3].astype(np.int16)
                if outline.mean() > 95 and outline.max() - outline.min() < 35:
                    pixels[y, edge + 1] = (0, 0, 0, 0)

        # Two tiny light fragments sit outside the collar below the cheeks.
        neck_remnants = (
            ((83 <= xx) & (xx <= 88) & (99 <= yy) & (yy <= 104))
            | ((113 <= xx) & (xx <= 115) & (101 <= yy) & (yy <= 105))
        )
        pixels[neck_remnants & (spread < 35) & (brightness > 110)] = (0, 0, 0, 0)
    return Image.fromarray(pixels, "RGBA")


frames = []
bases = {}
raw_bases = {}
shown = []
motion_shown = []
report = []
for number, source_number in enumerate(SOURCES, 1):
    image = Image.open(RAW / f"fall_{source_number:02d}.png").convert("RGB")
    image = image.resize((192, 192), Image.Resampling.BOX)
    rgb = np.asarray(image)
    alpha = matte(rgb)
    prepared = Image.fromarray(np.dstack((rgb, alpha)), "RGBA")
    if number >= 11:
        # The video's late hold grows a stray downward third hand. Remove
        # just that appendage before drawing the consistent screen-right arm.
        ImageDraw.Draw(prepared).polygon(
            [(120, 128), (126, 129), (130, 134), (130, 142),
             (125, 144), (118, 143), (118, 134)],
            fill=(0, 0, 0, 0),
        )
    raw_bases[source_number] = prepared.copy()
    if number >= 9:
        prepared = keep_left_arm_straight(prepared, bases[10], diagonal=number <= 10)
    bases[source_number] = prepared.copy()
    # Keep pose frames at the same 192px anchor as DRAG. Gravity translates
    # the whole sprite in Godot; it is demonstrated only in the preview.
    frame = prepared.copy()
    frame.alpha_composite(second_arm(ARM_ANGLES[number - 1], -3 if number >= 7 else -1))
    frame = clean_video_edge(frame, late_leg_gap=number >= 11)
    frame = match_idle_hair_palette(frame)
    frame.save(OUT / f"fall_{number:02d}.png")
    frames.append(frame)
    demonstration_drop = [0, 1, 2, 3, 5, 8, 11, 15, 20, 26, 33, 41][number - 1]
    report.append({"frame": number, "source": source_number, "arm_angle_deg": ARM_ANGLES[number - 1], "left_arm": "straight" if number >= 9 else "source", "demo_drop_px": demonstration_drop, "bbox": frame.getbbox()})

    checker = Image.new("RGB", (192, 192), "white")
    draw = ImageDraw.Draw(checker)
    for y in range(0, 192, 16):
        for x in range(0, 192, 16):
            shade = 204 if (x // 16 + y // 16) % 2 else 238
            draw.rectangle((x, y, x + 15, y + 15), fill=(shade,) * 3)
    checker.paste(frame, (0, 0), frame)
    shown.append(checker)

    motion = Image.new("RGB", (192, 256), "white")
    motion_draw = ImageDraw.Draw(motion)
    for y in range(0, 256, 16):
        for x in range(0, 192, 16):
            shade = 204 if (x // 16 + y // 16) % 2 else 238
            motion_draw.rectangle((x, y, x + 15, y + 15), fill=(shade,) * 3)
    motion.paste(frame, (0, demonstration_drop), frame)
    motion_shown.append(motion)

motion_shown[0].save(ROOT / "fall_candidate03_motion.gif", save_all=True, append_images=motion_shown[1:], duration=40, optimize=False)
motion_shown[0].save(ROOT / "fall_candidate03_review.gif", save_all=True, append_images=motion_shown[1:], duration=80, loop=0, optimize=False)
contact = Image.new("RGB", (208 * 4, 208 * 3), "white")
draw = ImageDraw.Draw(contact)
for index, frame in enumerate(shown):
    x, y = index % 4 * 208, index // 4 * 208
    contact.paste(frame, (x, y))
    draw.text((x + 4, y + 194), f"{index + 1:02d}", fill="black")
contact.save(ROOT / "fall_candidate03_contact.png")
AIR_SOURCES = [14, 14, 13, 13, 13, 13, 14, 14]
AIR_ANGLES = [8, 12, 10, 5, 0, -3, 0, 4]
AIR_LEFT_ANGLES = [0, -6, -11, -6, 0, 6, 11, 6]
air_dir = OUT / "air_loop"
air_dir.mkdir(exist_ok=True)
air_display = []
air_frames = []
for number, (source_number, angle, left_angle) in enumerate(zip(AIR_SOURCES, AIR_ANGLES, AIR_LEFT_ANGLES), 1):
    pose = keep_left_arm_straight(raw_bases[source_number], bases[10], diagonal=False, angle_deg=left_angle)
    pose.alpha_composite(second_arm(angle, -3))
    pose = clean_video_edge(pose, late_leg_gap=True)
    pose = match_idle_hair_palette(pose)
    pose.save(air_dir / f"air_{number:02d}.png")
    air_frames.append(pose)
    checker = Image.new("RGB", (192, 192), "white")
    checker_draw = ImageDraw.Draw(checker)
    for y in range(0, 192, 16):
        for x in range(0, 192, 16):
            shade = 204 if (x // 16 + y // 16) % 2 else 238
            checker_draw.rectangle((x, y, x + 15, y + 15), fill=(shade,) * 3)
    checker.paste(pose, (0, 0), pose)
    air_display.append(checker)
air_contact = Image.new("RGB", (208 * 4, 208 * 2), "white")
air_contact_draw = ImageDraw.Draw(air_contact)
for index, frame in enumerate(air_display):
    x, y = index % 4 * 208, index // 4 * 208
    air_contact.paste(frame, (x, y))
    air_contact_draw.text((x + 4, y + 194), f"{index + 1:02d}", fill="black")
air_contact.save(ROOT / "fall_air_loop_03_contact.png")
air_display[0].save(
    ROOT / "fall_air_loop_03.gif",
    save_all=True,
    append_images=air_display[1:],
    duration=70,
    loop=0,
    optimize=False,
)
long_preview = []
long_poses = frames + air_frames * 3
for index, pose in enumerate(long_poses):
    falling = Image.new("RGB", (192, 800), "white")
    falling_draw = ImageDraw.Draw(falling)
    for y in range(0, 800, 16):
        for x in range(0, 192, 16):
            shade = 204 if (x // 16 + y // 16) % 2 else 238
            falling_draw.rectangle((x, y, x + 15, y + 15), fill=(shade,) * 3)
    seconds = index * 0.04
    drop = round(0.5 * 600.0 * seconds * seconds)
    falling.paste(pose, (0, drop), pose)
    long_preview.append(falling)
long_preview[0].save(
    ROOT / "fall_long_drop_demo_03.gif",
    save_all=True,
    append_images=long_preview[1:],
    duration=40,
    optimize=False,
)
(ROOT / "candidate03_report.json").write_text(
    json.dumps({"intro_one_shot": True, "intro_frame_duration_ms": 40, "air_loop_source_frames": AIR_SOURCES, "air_loop_arm_angles_deg": AIR_ANGLES, "air_loop_left_arm_angles_deg": AIR_LEFT_ANGLES, "air_loop_frame_duration_ms": 70, "frames": report}, indent=2),
    encoding="utf-8",
)
print("created", len(frames), "frames")

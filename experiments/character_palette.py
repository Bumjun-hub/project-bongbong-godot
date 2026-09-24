"""Pixel-palette corrections shared by the active character motions."""

from functools import lru_cache
from pathlib import Path

import numpy as np
from PIL import Image


IDLE_HAIR_REFERENCE = (
    Path(__file__).resolve().parents[1]
    / "assets/character/idle/default_three_quarter_right/idle_default_three_quarter_right_01.png"
)


@lru_cache(maxsize=1)
def _idle_hair_palette() -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    reference = np.array(Image.open(IDLE_HAIR_REFERENCE).convert("RGBA"))
    rgb = reference[:, :, :3].astype(np.int16)
    red, green, blue = rgb.transpose(2, 0, 1)
    yy, xx = np.indices(green.shape)
    hair = (
        (reference[:, :, 3] > 0)
        & (20 <= yy) & (yy < 70)
        & (50 <= xx) & (xx <= 140)
        & (rgb.max(axis=2) < 180)
        & (rgb.max(axis=2) - rgb.min(axis=2) < 45)
        & (red - green < 18)
        & (blue >= green - 4)
    )
    colors, counts = np.unique(rgb[hair].astype(np.uint8), axis=0, return_counts=True)
    luminance = 0.299 * colors[:, 0] + 0.587 * colors[:, 1] + 0.114 * colors[:, 2]
    lookup = np.empty((190, 3), dtype=np.uint8)
    for tone in range(len(lookup)):
        distance = np.abs(luminance - tone)
        near = np.flatnonzero(distance <= distance.min() + 1)
        lookup[tone] = colors[near[np.argmax(counts[near])]]
    codes = (
        (colors[:, 0].astype(np.int32) << 16)
        | (colors[:, 1].astype(np.int32) << 8)
        | colors[:, 2].astype(np.int32)
    )
    hair_luminance = 0.299 * red[hair] + 0.587 * green[hair] + 0.114 * blue[hair]
    return lookup, codes, np.sort(np.rint(hair_luminance).astype(np.uint8))


def _match_idle_hair_once(frame: Image.Image) -> Image.Image:
    pixels = np.array(frame.convert("RGBA"))
    rgb = pixels[:, :, :3].astype(np.int16)
    red, green, blue = rgb.transpose(2, 0, 1)
    yy, xx = np.indices(green.shape)

    # The upper dark, near-neutral region contains the hair and dark frames.
    # White lenses, warm skin, and the red shirt are outside this color range.
    hair = (
        (pixels[:, :, 3] > 0)
        & (yy < 103)
        & (xx >= 40)
        & (xx <= 155)
        & (rgb.max(axis=2) < 190)
        & (rgb.max(axis=2) - rgb.min(axis=2) < 45)
        & (red - green < 18)
        & (blue >= green - 4)
    )
    lookup, palette_codes, reference_tones = _idle_hair_palette()
    codes = (red.astype(np.int32) << 16) | (green.astype(np.int32) << 8) | blue.astype(np.int32)
    tone = np.clip(np.rint(0.299 * red + 0.587 * green + 0.114 * blue), 0, 189).astype(np.uint8)
    sample = hair & (20 <= yy) & (yy < 70) & (50 <= xx) & (xx <= 140)
    source_tones = tone[sample]
    if len(source_tones) == 0:
        return frame.convert("RGBA")

    # Match the actual IDLE shade distribution as well as its RGB colors.
    # A color-only lookup left DRAG and FALL visibly darker than IDLE.
    source_levels = np.percentile(source_tones, [10, 50, 90])
    target_levels = np.percentile(reference_tones, [10, 50, 90])
    already_matched = np.all(np.abs(source_levels - target_levels) <= 2) and np.all(
        np.isin(codes[hair], palette_codes)
    )
    if already_matched:
        return Image.fromarray(pixels, "RGBA")

    counts = np.bincount(source_tones, minlength=190)
    rank_middle = np.cumsum(counts) - counts / 2
    target_indices = np.clip(
        np.rint(rank_middle / len(source_tones) * (len(reference_tones) - 1)).astype(int),
        0,
        len(reference_tones) - 1,
    )
    target_tones = reference_tones[target_indices]
    pixels[:, :, :3][hair] = lookup[target_tones[tone[hair]]]
    return Image.fromarray(pixels, "RGBA")


def match_idle_hair_palette(frame: Image.Image) -> Image.Image:
    """Use IDLE's exact hair colors and shade range without changing alpha."""
    current = frame.convert("RGBA")
    for _ in range(3):
        updated = _match_idle_hair_once(current)
        if np.array_equal(np.asarray(current), np.asarray(updated)):
            return updated
        current = updated
    return current

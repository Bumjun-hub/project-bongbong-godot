# Grok Walk candidate 01

- Source: `assets/character/source/bongbong_sd17_base.png`, frontal neutral base.
- Aseprite composited the existing transparent base over green for video input.
- One 3-second Grok Imagine 1.5 video generated using `grok-login` subscription authentication.
- Canonical sprite-gen `video-set`: front / walk, 24 fps source, 73 extracted RGBA frames.
- Automatic loop: zero-based start 24, length 17, periodicity 0.5814, seam ratio 1.0675 (threshold 2.0).
- The selected loop corresponds to source PNGs 25–41 inclusive. No generation retry was performed.
- `front-walk/loop/`: full preview strip, transparent GIF/WebP, cycle PNGs.
- `front-walk/pixel-size/`: same selected interval exported through `video-loop`, standing body height 156px, height cap 192px. Strip JSON owns cell dimensions and playback timing (24 fps / about 0.708 seconds).
- `front-walk/clip.mp4`: original generated video.
- `front-walk/source-contact.png`: ordered source samples, source frame numbers shown.

## Visual review

Ordered frames spanning the entire three-second clip were inspected. The character retains the general hair/glasses/outfit design, but pixels are regenerated, not identical to the base. Feet change support and lift, while arms spread and swing more widely than a restrained walk. The resulting motion is a bouncy, playful walk candidate. The automatic seam pass is not proof of anatomically accurate foot contact. No precise same-foot stride measurement was made.

Existing Walk/Run production assets and Godot animation resources were not replaced.

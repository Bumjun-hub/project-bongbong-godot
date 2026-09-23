# Walk revision 12 — Aseprite edit

> Superseded by revision 13. Visual review found that the selected GPT lower-body pixels broke the original pixel-art texture and made shoes too chunky. The generated lower-body pixels were removed from the published Walk.

- User choice: refine the existing eight-frame Walk in Aseprite after three GPT row candidates failed to show reliable alternating foot contact.
- Source backup: `../runs/walk8-idle-gait-revision-04/references/walk-cycle-original.aseprite` (SHA-256 `6319521ECA4A1D517F29ADFB7A6A5812E9154D777670E5D477218BC026DA8362`).
- Selected lower-body reference: `../runs/walk8-idle-gait-revision-04/sprite-sheet-alpha.png`. Aseprite copied its pixels below y=146 into original frames 2, 3, 6, and 7. Frames 1, 4, 5, and 8 remain original; every frame's pixels above y=146 remain original.
- Result: `../../assets/character/walk/right_three_quarter/walk_cycle_8.aseprite`, the 1536×192 sheet, eight 192×192 PNGs, and an 8-frame preview GIF. The source retained the 125 ms frame durations and animation tag.
- Motion review: stronger toe-off and passing-foot lift in each half cycle. All frame bounds remain within x=44..145, y=17..173; soles share y=173. No hard 8→1 change was introduced because frames 8 and 1 are unchanged. Pairwise silhouette overlap and changed-pixel counts remain in the original range.
- Export checks: Aseprite re-export equals the published sheet pixel for pixel, and each runtime PNG equals its corresponding sheet cell. `reports/v2-motion.json` reports eight frames with motion; stance/stride remains unverified because no single-foot ROI/contact declaration was supplied.
- Godot runtime was not opened for this revision; `WALK_TEST.md` records the prior runtime verification separately.

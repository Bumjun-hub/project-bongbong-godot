# Walk revision 14 — base-referenced pixel polish

- Reference: approved `idle_default_three_quarter_right_01.png`. Source: revision 13, preserved as `walk-revision-13-backup.aseprite` and `source.png`.
- All eight frames use six denim shades derived from the base. Tiny isolated shade pixels and small interior shade islands were cleaned. Sneakers use five neutral shades with clearer dark edges.
- A one-pixel exterior contour was added around the lower body, capped at the existing ground row 173. Overall frame bounds remain unchanged. No image resampling or generated replacement anatomy was used.
- Rows 0–137 and all source skin-colored pixels remain identical. The revision-13 poses, including the original-pixel foot lift in frames 2 and 6, remain in use.
- `reports/legs-outlined-4x.png` displays every leg frame. `reports/base-before-after-2x.png` compares the base and first Walk frame before/after. Both were visually inspected, as was the full exported sheet at native scale.
- Pixel checks: Aseprite export matches the selected candidate; eight 192×192 frames, one connected alpha component per frame, binary lower-body alpha, original overall bounds, and shared ground row 173.
- Aseprite metadata: eight frames at 125ms each, original layer and `WALK_RIGHT_THREE_QUARTER` tag retained. Runtime is still 8FPS / 1000ms per loop. GIF preview uses 120ms per frame due to its 10ms timing unit.
- Published Aseprite was freshly exported and checked against the published sheet and all eight runtime PNGs. Details: `reports/published-qa.json`.
- Godot follow-up on 2026-09-23: reimported and rendered in Godot 4.7.2 / Windows D3D12 / Forward+. Existing Walk regression completed 5,009 checks with no failures, including all eight frames, two loops, left/right movement, Idle transitions, boundary turns and native mirrored pixel/color alignment. Right/left render captures were visually reviewed. See `reports/godot-runtime-qa.json` and `.godot/walk_test/revision14_render.log`. Game movement speed and motion poses were not changed.

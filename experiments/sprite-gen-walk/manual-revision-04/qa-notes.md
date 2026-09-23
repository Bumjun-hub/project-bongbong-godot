# Walk revision 15 — marked neck and hand cleanup

- User marked a dark protrusion behind the neck and the visible screen-right hand. Source: revision 14, preserved as `revision14-walk_cycle_8.aseprite`, PNG sheet and manifest.
- Aseprite Lua removed 21 protruding neck pixels in each frame, following the existing body bob. The neckline and necklace remain connected.
- The exposed character-left / screen-right hand in frames 1, 2, 3, 7 and 8 has a slightly narrower wrist, rounder fingertip contour, and short thumb shading. The body-hidden hand poses in frames 4–6 retain their occlusion.
- Pixel verification: changes are restricted to the two requested areas; existing denim pixels and all rows from 153 downward are unchanged. Eight full 192×192 frames retain their original overall bounds and one connected alpha component each. No partial alpha was added.
- Native Aseprite export supplies the sheet and individual PNGs. Timing remains 125ms/frame, eight frames, with the existing Walk tag. GIF preview uses 120ms/frame.
- Visually reviewed the eight upper-body crops and before/after comparison at 4×. `reports/pixel-qa.json` records per-frame checks.
- Published Aseprite was freshly exported and matched against the published sheet and all eight runtime PNGs. Godot 4.7.2 / D3D12 / Forward+ replay passed all 5,009 existing checks, including eight frames, two loops and mirrored render pixel alignment. `reports/godot-runtime-qa.json` records the result. The rendered left-facing frame was visually inspected, and a normal preview was relaunched.

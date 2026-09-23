# Walk revision 16 — shoulder outline restoration

- User clarified that the dark line belongs immediately above the shoulder, as in Idle, and reported that it disappeared during Walk. Revision 15 had removed part of that contour.
- Revision 15 Aseprite, PNG sheet and metadata were backed up before edits.
- Aseprite Lua restored the missing outline directly against the red shirt, following each frame's actual shoulder contour and body bob. Existing charcoal shoulder-edge pixels were unified to near-black. Edits are limited to the marked viewer-left upper shoulder region.
- All eight shoulder crops were visually inspected at 8×. Source checks found zero exposed red-to-transparent shoulder edges. Frames keep their previous overall bounds; rows 128 onward, including the refined hands and legs, remain identical to revision 15. Each frame is 192×192 at 125ms.
- Aseprite export supplies all eight runtime PNGs. Published files were verified against their candidate copies. GIF preview uses 120ms/frame.
- Godot 4.7.2 / D3D12 / Forward+ rendered all eight poses. Every opaque shoulder pixel, including the contour, matches its current PNG with zero mismatches. The eight rendered shoulder crops were visually inspected. See `reports/godot-render-qa.json` and `reports/godot-all-shoulders-6x.png`.

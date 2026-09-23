# Walk revision 17 — darker Idle-matched shoulder edge

- Reference: approved default Idle frame 1. Revision 16 Aseprite, sprite sheet and manifest are saved as backups in this directory.
- Idle shoulder exterior contains pure-black pixels and its adjacent shirt edge uses dark red shades. Revision 17 changes the Walk shoulder exterior to `(0,0,0)` and darkens the adjacent one-pixel shirt rim with shades sampled from Idle.
- Aseprite edited all eight frames. Reviewed the first frame beside Idle and all eight shoulders at 8×.
- Pixel check: edits stay within the viewer-left upper shoulder region. Alpha and full sprite bounds remain identical to revision 16. Rows 128 onward, including the approved hand and leg refinements, are unchanged. Timing remains eight 125ms frames.
- Runtime PNGs come from the Aseprite export. The preview GIF uses 120ms/frame because GIF timing is quantized to 10ms.
- Godot 4.7.2 / D3D12 / Forward+ rendered each of the eight Walk poses. The shoulder pixel comparison against the current PNGs passed in every frame with zero mismatches. See `reports/godot-render-qa.json` and `reports/godot-all-shoulders.png`.

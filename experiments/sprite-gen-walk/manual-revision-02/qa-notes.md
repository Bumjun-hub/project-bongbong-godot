# Walk revision 13 — pixel repair

- The user reported broken leg pixels in revision 12. All eight leg frames were inspected at 4× alongside the backed-up revision-11 source.
- Revision 12's generated lower-body pixels in frames 2, 3, 6 and 7 were removed. Revision 13 starts from the original Aseprite source and moves only selected original trailing-shoe/denim pixels upward three integer pixels in frames 2 and 6.
- `walk-revision-12-backup.aseprite` preserves the prior published version. `walk-revision-11-source.aseprite` is the clean source used for the repair.
- `reports/all-legs-4x.png` shows every repaired leg. The candidate has no new colors, one connected alpha component in every frame, and the original frame bounds. Frames 1 and 8 are untouched, so the loop seam is unchanged.
- Aseprite exported the candidate sheet. Its eight 192×192 cells were copied to runtime PNGs; published files were checked against a fresh Aseprite export.
- Godot runtime was not launched in this environment. The game movement speed remains 72 px/s and should be checked visually in Godot.

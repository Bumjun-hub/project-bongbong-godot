# Bongbong SD17 Walk — sprite-gen experiment 01

- Scope: isolated candidate only; no Godot runtime asset is installed.
- Pipeline: sprite-gen 2.5.5, component-row / gpt-rows, Codex image provider, 8 frames at 8 fps, 192 x 192 transparent extracted cells.
- Identity input: `base-source.png`, copied by `prepare` from `assets/character/source/bongbong_sd17_base.png` (front-facing SD Base).
- Direction input: `references/accepted-direction-idle.png`, copied from the existing three-quarter-right Idle frame 01; direction reference only.
- Layout input: `references/layout-guides/walk.png` from `prepare`.
- No manual Walk image was attached to generation. Existing `assets/character/walk/right_three_quarter/walk_01.png` through `walk_08.png` and `walk_cycle_8.png` were read only for the comparison below.

## Execution and provenance

`prepare --base-image <SD Base> --request <experiment walk-request.json> --cell-size 192 --safe-margin 14 --chroma-key auto` created the run. The generated prompt and guide are preserved. `gen --provider codex --prompt-file prompts/walk.txt --ref base-source.png --ref references/accepted-direction-idle.png --ref references/layout-guides/walk.png --out raw/walk.png --report reports/generation-walk.json` produced the raw row. The command then exited 1 while writing its report because `reports/` did not exist yet. That folder was created afterward; there is no official `generation-walk.json`. The raw image is complete and was visually checked. No fallback provider was requested or used. Direct `gen` was selected over `gen-set` so the accepted directional Idle could be attached in addition to the canonical Base and layout guide.

The completed raw row was processed with `extract`, `compose-atlas`, `compose-gif`, the repository's `preview_animation.py`, `inspect`, and `score` commands. These stages all exited successfully. The GIF has 8 frames, 8 fps, transparency and a repeating loop. The atlas and extracted frames are transparent.

## QA verdict: experimental, do not install as game Walk

- Structural: 8/8 frames extracted; inspect has no errors; automatic score is 94.0. The score checks structural similarity and motion presence, not left/right limb identity.
- Extraction warning: the model drew at a much finer pixel pitch than the 192 px cell contract; every native crop exceeded the physical 192 x 178 cap. Some hair pixels reach the top canvas edge (frame 4 bbox begins at y=0). Green chroma leakage was not reported.
- Body scale: extracted visible bboxes are roughly 94-95 x 175-178 px, versus 102 x 155-157 px for the existing manual Walk. The new figure is about 13% taller on the same 192 px canvas, with relatively longer legs and changed hair/shirt detail. It does not preserve the approved 1.7-head silhouette closely enough.
- Legs: poses vary and some shoes separate, but frames 1 and 5 still read as a similar screen-right leading leg. The physical left/right reversal is not unambiguous. Frames 3 and 7 are near-standing and the passing leg is partly lost behind the support leg. Foot planting is not stable enough to approve as a loop.
- Arms: there is shoulder-level movement and some arm counter-swing, but the swing is uneven. Frame 5 and 8 bring the near arm far forward while intermediate poses are much smaller; the intended opposite rhythm cannot be verified throughout.
- Face/hair: direction and glasses are broadly recognizable; hair shape, glasses/eye pixels, collar, shirt markings and shoes drift from the approved sprite. The shirt's necklace/detail is mostly omitted.
- Loop: adjacent-frame pixel change at 8->1 is comparable with internal transitions (0.248 versus 0.238-0.270 of the canvas), so there is no unusually large image jump. The gait phase and foot contact still do not read as a clean repeating walk.
- Comparison: the manual Aseprite Walk maintains the approved 192 px figure, ground row and outfit detail, and its recorded pose sequence explicitly alternates right and left contact and opposite arm swing. This generated result is useful as rough pose ideation, but not as a replacement or direct frame source.

Next experiment, if desired: use a separately identified run with a two-contact motion guide and a more suitable row/cell aspect ratio; still require human curation. Do not copy any frame into `assets/character/walk` without approval and manual motion review.

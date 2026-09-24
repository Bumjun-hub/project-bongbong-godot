# FALL candidate 03

- Current revision: `candidate03/fall_01.png` through `fall_12.png`, 192×192 transparent PNGs, 40 ms per frame. It uses 12 clean native poses sampled from the supplied Grok video at about 0.58–1.04 s. `fall_candidate03_motion.gif` previews the one-shot fall; `fall_candidate03_review.gif` and `fall_candidate03_contact.png` are for close inspection.
- The missing screen-right arm is composited in every FALL frame from the existing DRAG character art. Its angle changes across the sequence. A late stray arm from the source clip is removed so frames 11–12 still show exactly two arms.
- The screen-left arm stays straight in FALL frames 9–12. In the midair loop it swings up and down by up to 11 degrees while staying extended. Its source is the clean straight-arm pose in frame 8; the lowered-arm pixels are removed and the shirt and jeans outline is restored.
- `candidate03/air_loop/air_01.png` through `air_08.png` form an 8-frame midair loop at 70 ms per frame. `fall_air_loop_03.gif` and `fall_air_loop_03_contact.png` show it. The loop begins on the final intro pose and returns smoothly toward it.
- `fall_long_drop_demo_03.gif` shows the intro followed by three loop passes with downward motion for demonstration only. The pose PNGs stay on a common 192×192 anchor; Godot should handle gravity and floor contact.
- `candidate03_report.json` records source frame numbers, timing, bounding boxes and arm angles. `make_candidate03.py` rebuilds the current revision. The original candidate 02 remains for comparison.

## Source and use

- Source: user-supplied six-second Grok video, sampled at approximately 0.58–1.04 s for candidate 03.
- The clip's checkerboard was baked into the video. `make_candidate03.py` builds a silhouette matte and restores the white shoes against that background.
- A final cleanup makes pale checker-colored video remnants transparent while keeping white glasses, eyes, mouth details and sneakers. The hair reuses colors sampled from the active IDLE sprite so DRAG and FALL match its palette. The F1 Godot test backdrop no longer draws a 192×192 canvas box or guide lines over the character.
- The final two FALL poses and all eight airborne poses also remove the old arm's pale strip outside the screen-right torso and the small bright fragments behind the collar. These local alpha edits preserve the glasses, hair palette and sneakers.
- The pose ends before impact. LAND remains a separate motion.
- Fall distance is determined by Godot's vertical motion and floor contact. A longer fall repeats the midair loop; a short fall can interrupt the intro on contact.
- Godot test integration copies the selected 12 FALL frames and 8 air-loop frames into `assets/character/fall/grok_fall_01/` and loads them through `scenes/fall_frames.tres`. Releasing DRAG above the starting floor plays FALL, then repeats the air loop until floor contact. The character returns to Idle on contact until a separate LAND animation is authored.
- To test interactively, run the project, drag Bongbong upward and release. A high release shows the air loop; a release near the floor may finish before the loop. Press F1 to show the test backdrop and status.

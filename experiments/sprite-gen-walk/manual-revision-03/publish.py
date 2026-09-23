from pathlib import Path
import json
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
DEST = ROOT / 'assets/character/walk/right_three_quarter'
qa = json.loads((HERE / 'reports/pixel-qa.json').read_text())
assert qa['aseprite_export_matches_candidate']
assert (HERE / 'walk-revision-13-backup.aseprite').exists()
for source, destination in (
    ('walk_cycle_8_candidate.aseprite', 'walk_cycle_8.aseprite'),
    ('walk_cycle_8_candidate.png', 'walk_cycle_8.png'),
    ('walk_cycle_8_preview.gif', 'walk_cycle_8_preview.gif'),
):
    shutil.copy2(HERE / source, DEST / destination)
for i in range(1,9):
    shutil.copy2(HERE / 'frames' / f'walk_{i:02}.png', DEST / f'walk_{i:02}.png')
manifest_path = DEST / 'manifest.json'
manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
manifest['revision'] = 14
manifest['edit_reference'] = 'experiments/sprite-gen-walk/manual-revision-03; revision 13 source and backup retained.'
manifest['leg_adjustment'] = 'Revision 13 original pixel-art legs retained, including the three-pixel trailing-foot lift in frames 2 and 6. Revision 14 cleans denim shading and shoe pixels across all eight frames, with a one-pixel lower-body contour.'
manifest['pixel_polish'] = {
    'reference': 'assets/character/idle/default_three_quarter_right/idle_default_three_quarter_right_01.png',
    'denim': 'Six shades derived from the approved idle base; isolated shade speckles and small interior shade islands cleaned.',
    'shoes': 'Five neutral shades, clearer black contour and sole edge.',
    'outline': 'One pixel added around lower-body edges where transparent; ground row capped at 173.',
    'upper_body': 'Rows 0 through 137 and source skin-colored pixels are unchanged.',
    'resampling': 'None; native 192x192 pixels.'
}
manifest['motion_qa'] = 'Revision 14: all eight leg frames visually inspected at 4x and full sprites at native scale. One connected alpha component per frame, original overall bounds, common ground row 173, 125ms frame duration, and Aseprite export matches all PNG cells. Motion poses and game speed remain from revision 13; Godot runtime was not launched for revision 14.'
manifest['waist_adjustment'] = 'Revision 11 restored the curved shirt hem and closed its one-pixel notch. Revision 14 retains revision 13 upper-body pixels; only lower-body denim, shoes and contour are polished.'
manifest['preview_duration_ms'] = 120
manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Published revision 14: Aseprite, sheet, 8 frames, GIF, manifest.')

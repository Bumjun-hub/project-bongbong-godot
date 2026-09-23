from pathlib import Path
import json
import shutil

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
DEST=ROOT/'assets/character/walk/right_three_quarter'
qa=json.loads((HERE/'reports/pixel-qa.json').read_text())
assert qa['frame_count']==8 and all(f['changes_confined_to_neck_and_marked_hand'] for f in qa['frames'])
for src,dst in [('walk_cycle_8_candidate.aseprite','walk_cycle_8.aseprite'),('candidate.png','walk_cycle_8.png'),('walk_cycle_8_preview.gif','walk_cycle_8_preview.gif')]:
    shutil.copy2(HERE/src,DEST/dst)
for i in range(1,9):shutil.copy2(HERE/'frames'/f'walk_{i:02}.png',DEST/f'walk_{i:02}.png')
manifest=json.loads((HERE/'revision14-manifest.json').read_text(encoding='utf-8'))
manifest['revision']=15
manifest['edit_reference']='experiments/sprite-gen-walk/manual-revision-04; revision 14 Aseprite, sheet and metadata retained as backup.'
manifest['neck_adjustment']='Removed 21 protruding dark pixels beside the back of the neck in each of the eight frames, aligned to the existing body bob.'
manifest['hand_adjustment']='Screen-right / character-left exposed wrist and hand refined in frames 1, 2, 3, 7 and 8: slightly tapered wrist, rounded fingertips and a small thumb shadow. Hidden-hand poses retain their existing occlusion.'
manifest['pixel_polish']['applied_in_revision']=14
manifest['pixel_polish']['upper_body']='Revision 14 preserved upper-body pixels. Revision 15 changes only the marked neck protrusion and exposed screen-right hand/wrist.'
manifest['motion_qa']='Revision 15: all eight frames reviewed; edits confined to neck and the marked wrist/hand. Denim and rows 153 onward are pixel-identical to revision 14. Single connected silhouette per frame, unchanged canvas and bounds, eight frames at 125ms.'
manifest.pop('godot_runtime_qa',None)
(DEST/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Published revision 15: Aseprite, sprite sheet, eight runtime PNGs and GIF.')

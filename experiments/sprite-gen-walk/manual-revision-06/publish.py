from pathlib import Path
import json
import shutil

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
DEST=ROOT/'assets/character/walk/right_three_quarter'
qa=json.loads((HERE/'reports/pixel-qa.json').read_text())
assert len(qa['frames'])==8 and all(f['alpha_unchanged'] for f in qa['frames'])
for source,dest in [('walk_cycle_8_candidate.aseprite','walk_cycle_8.aseprite'),('candidate.png','walk_cycle_8.png'),('walk_cycle_8_preview.gif','walk_cycle_8_preview.gif')]:
    shutil.copy2(HERE/source,DEST/dest)
    assert (HERE/source).read_bytes()==(DEST/dest).read_bytes()
for i in range(1,9):
    name=f'walk_{i:02}.png'
    shutil.copy2(HERE/'frames'/name,DEST/name)
    assert (HERE/'frames'/name).read_bytes()==(DEST/name).read_bytes()
manifest=json.loads((HERE/'revision16-manifest.json').read_text(encoding='utf-8'))
manifest['revision']=17
manifest['edit_reference']='experiments/sprite-gen-walk/manual-revision-06; revision 16 source, sprite sheet and metadata retained.'
manifest['shoulder_adjustment']='The viewer-left shoulder edge follows the Walk pose in all eight frames. Revision 17 uses the base Idle pure-black outline (0,0,0) and dark red rim shades sampled from the approved Idle image so the contour reads more strongly.'
manifest['motion_qa']='Revision 17 shoulder darkening checked at 8x in every pose. Edits are confined to the viewer-left upper shoulder; alpha, frame bounds, hands, legs and rows 128 onward remain unchanged. Eight frames at 125ms.'
manifest.pop('godot_runtime_qa',None)
(DEST/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Published revision 17; Aseprite and runtime exports match candidate copies.')

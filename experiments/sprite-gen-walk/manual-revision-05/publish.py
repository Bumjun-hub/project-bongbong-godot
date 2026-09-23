from pathlib import Path
import json
import shutil

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
DEST=ROOT/'assets/character/walk/right_three_quarter'
qa=json.loads((HERE/'reports/pixel-qa.json').read_text())
assert len(qa['frames'])==8 and all(f['unoutlined_shoulder_edges']==0 for f in qa['frames'])
for source,dest in [('walk_cycle_8_candidate.aseprite','walk_cycle_8.aseprite'),('candidate.png','walk_cycle_8.png'),('walk_cycle_8_preview.gif','walk_cycle_8_preview.gif')]:
    shutil.copy2(HERE/source,DEST/dest)
    assert (HERE/source).read_bytes()==(DEST/dest).read_bytes()
for i in range(1,9):
    name=f'walk_{i:02}.png'
    shutil.copy2(HERE/'frames'/name,DEST/name)
    assert (HERE/'frames'/name).read_bytes()==(DEST/name).read_bytes()
manifest=json.loads((HERE/'revision15-manifest.json').read_text(encoding='utf-8'))
manifest['revision']=16
manifest['edit_reference']='experiments/sprite-gen-walk/manual-revision-05; revision 15 Aseprite, sheet and metadata retained.'
manifest['neck_adjustment']='Revision 16 restores the removed contour at the actual shirt shoulder edge below the former neck protrusion. A thin near-black contour follows each of the eight shoulder poses and their body bob.'
manifest['shoulder_adjustment']='Viewer-right arm positioning from prior revisions retained. Revision 16 repairs the marked viewer-left shoulder outline: no exposed red-to-transparent shoulder edges in any of the eight frames.'
manifest['motion_qa']='All eight shoulder poses inspected at 8x. Corrections confined to the viewer-left upper shoulder edge; pixels from row 128 downward match revision 15. Eight 192x192 frames at 125ms, unchanged overall bounds.'
manifest.pop('godot_runtime_qa',None)
(DEST/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Published revision 16; copied source and exports verified byte-for-byte.')

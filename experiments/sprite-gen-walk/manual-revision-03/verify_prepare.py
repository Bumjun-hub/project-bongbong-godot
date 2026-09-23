from pathlib import Path
import json
from collections import deque
import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
source = np.array(Image.open(HERE / 'source.png').convert('RGBA'))
sheet = np.array(Image.open(HERE / 'walk_cycle_8_candidate.png').convert('RGBA'))
expected = np.array(Image.open(HERE / 'candidate-outlined.png').convert('RGBA'))
assert sheet.shape == (192, 1536, 4)
assert np.array_equal(sheet, expected), 'Aseprite export mismatch'
assert np.array_equal(sheet[:138], source[:138]), 'Upper-body changes'
meta = json.loads((HERE / 'reports/aseprite-export.json').read_text())
assert len(meta['frames']) == 8
assert all(f['duration'] == 125 and f['sourceSize'] == {'w': 192, 'h': 192} for f in meta['frames'])
(HERE / 'frames').mkdir(exist_ok=True)
(HERE / 'qa-frames').mkdir(exist_ok=True)

def components(mask):
    remaining = set(zip(*np.where(mask)))
    sizes = []
    while remaining:
        seed = remaining.pop()
        queue = deque([seed])
        count = 1
        while queue:
            y, x = queue.popleft()
            for dy, dx in ((-1,0),(1,0),(0,-1),(0,1)):
                p = (y+dy,x+dx)
                if p in remaining:
                    remaining.remove(p)
                    queue.append(p)
                    count += 1
        sizes.append(count)
    return sorted(sizes, reverse=True)

report = {'revision': 14, 'aseprite_export_matches_candidate': True,
          'upper_rows_0_to_137_unchanged': True, 'frame_duration_ms': 125,
          'godot_runtime_tested': False, 'frames': []}
for i in range(8):
    frame = sheet[:, i*192:(i+1)*192]
    old = source[:, i*192:(i+1)*192]
    mask = frame[:,:,3] > 0
    yy, xx = np.where(mask)
    changed = np.any(frame != old, axis=2)
    rgb = old[:,:,:3].astype(int)
    skin = (old[:,:,3]>0) & (rgb[:,:,0]>rgb[:,:,1]+20) & (rgb[:,:,1]>rgb[:,:,2]+10)
    assert not np.any(changed & skin), f'Skin changed in frame {i+1}'
    sizes = components(mask)
    assert len(sizes) == 1, f'Stray pixels in frame {i+1}: {sizes}'
    assert yy.max() == 173, f'Ground changed in frame {i+1}'
    assert set(np.unique(frame[138:,:,3]).tolist()) <= {0,255}
    old_bbox = Image.fromarray(old).getbbox()
    bbox = Image.fromarray(frame).getbbox()
    assert bbox == old_bbox, f'Overall bounds changed: {bbox} != {old_bbox}'
    Image.fromarray(frame).save(HERE / 'frames' / f'walk_{i+1:02}.png')
    Image.fromarray(frame).save(HERE / 'qa-frames' / f'frame-{i}.png')
    report['frames'].append({'frame':i+1, 'changed_pixels':int(changed.sum()),
                             'outline_pixels_added':int(((old[:,:,3]==0)&mask).sum()),
                             'alpha_components':len(sizes), 'bbox':list(bbox),
                             'ground_row':int(yy.max()), 'skin_unchanged':True})

base = Image.open(ROOT / 'assets/character/idle/default_three_quarter_right/idle_default_three_quarter_right_01.png').convert('RGBA')
comparison = Image.new('RGB', (1152,408), (42,42,42))
draw = ImageDraw.Draw(comparison)
for i, (label, sprite) in enumerate([('BASE',base), ('BEFORE',Image.fromarray(source[:,:192])), ('AFTER',Image.fromarray(sheet[:,:192]))]):
    background = Image.new('RGBA',(192,192),(42,42,42,255))
    background.alpha_composite(sprite)
    comparison.paste(background.resize((384,384),Image.Resampling.NEAREST).convert('RGB'),(i*384,24))
    draw.text((i*384+12,6),label,fill='white')
comparison.save(HERE / 'reports/base-before-after-2x.png')
(HERE / 'reports/pixel-qa.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report))

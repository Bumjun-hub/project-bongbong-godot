"""Restore the coherent Grok walk at a slightly larger whole-body size."""
from pathlib import Path
import json
import shutil

from PIL import Image


root = Path(__file__).resolve().parents[3]
work = Path(__file__).resolve().parent
candidate = work / 'whole-body-159'
dest = root / 'assets/character/walk/grok_right_calm'
backup = work / 'before-whole-body-revert'
backup.mkdir(exist_ok=True)

names = [f'walk_{i:02}.png' for i in range(1, 25)]
names += ['walk_cycle_24.aseprite', 'walk_cycle_24.png', 'walk_cycle_24_preview.gif', 'walk_contact_sheet.png', 'manifest.json']
for name in names:
    if not (backup / name).exists():
        shutil.copy2(dest / name, backup / name)

sheet = Image.open(candidate / 'walk_cycle_24.png').convert('RGBA')
assert sheet.size == (24 * 192, 192)
for index in range(24):
    name = f'walk_{index + 1:02}.png'
    frame = Image.open(candidate / name).convert('RGBA')
    assert frame.tobytes() == sheet.crop((index * 192, 0, (index + 1) * 192, 192)).tobytes()
    shutil.copy2(candidate / name, dest / name)

for source, name in [('walk_cycle_24.aseprite', 'walk_cycle_24.aseprite'),
                     ('walk_cycle_24.png', 'walk_cycle_24.png'),
                     ('preview.gif', 'walk_cycle_24_preview.gif'),
                     ('contact.png', 'walk_contact_sheet.png')]:
    shutil.copy2(candidate / source, dest / name)

manifest = json.loads((dest / 'manifest.json').read_text())
manifest.pop('head_match', None)
manifest.pop('head_motion', None)
manifest.pop('head_reference', None)
manifest.update({
    'revision': 4,
    'source': 'experiments/sprite-gen-walk/grok-walk-02/whole-body-159/walk-right-calm.strip.png',
    'placement': [42, 13],
    'body_height': 159,
    'resampled': True,
    'whole_body_motion': 'Original Grok head, neck and body frames were scaled together by sprite-gen to 159px standing height; no head transplant or independent head offset.',
    'head_width_range_px': [101, 102],
    'native_source': 'walk_cycle_24.aseprite',
    'preview': 'walk_cycle_24_preview.gif',
})
(dest / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
print('Published original coherent whole-body Walk at 159px standing height.')

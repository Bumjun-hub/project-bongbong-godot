"""Publish the reviewed moving head while preserving the accepted Walk body."""
from pathlib import Path
import json
import shutil

from PIL import Image, ImageDraw


root = Path(__file__).resolve().parents[3]
work = Path(__file__).resolve().parent
dest = root / 'assets/character/walk/grok_right_calm'
backup = work / 'before-head-bob'
backup.mkdir(exist_ok=True)
for name in ('walk_cycle_24.aseprite', 'walk_cycle_24.png', 'walk_cycle_24_preview.gif', 'walk_contact_sheet.png', 'manifest.json'):
    if not (backup / name).exists():
        shutil.copy2(dest / name, backup / name)

sheet = Image.open(work / 'walk_head_bob_candidate.png').convert('RGBA')
assert sheet.size == (4608, 192)
contact = Image.new('RGBA', (1152, 768), (39, 47, 58, 255))
preview = []
head_tops = []
for index in range(24):
    name = f'walk_{index + 1:02}.png'
    if not (backup / name).exists():
        shutil.copy2(dest / name, backup / name)
    frame = sheet.crop((index * 192, 0, (index + 1) * 192, 192))
    original = Image.open(work / 'before-head-match' / name).convert('RGBA')
    assert frame.crop((0, 113, 192, 192)).tobytes() == original.crop((0, 113, 192, 192)).tobytes()
    hair = frame.getchannel('A').crop((0, 0, 192, 80)).point(lambda a: 255 if a >= 128 else 0).getbbox()
    assert hair and hair[2] - hair[0] == 102 and 18 <= hair[1] <= 20
    head_tops.append(hair[1])
    frame.save(dest / name)
    x, y = (index % 6) * 192, (index // 6) * 192
    contact.alpha_composite(frame, (x, y))
    ImageDraw.Draw(contact).text((x + 5, y + 5), str(index + 1), fill='white')
    bg = Image.new('RGBA', (192, 192), (39, 47, 58, 255))
    bg.alpha_composite(frame)
    preview.append(bg.convert('RGB').resize((384, 384), Image.Resampling.NEAREST))

shutil.copy2(work / 'walk_head_bob_candidate.aseprite', dest / 'walk_cycle_24.aseprite')
shutil.copy2(work / 'walk_head_bob_candidate.png', dest / 'walk_cycle_24.png')
preview[0].save(dest / 'walk_cycle_24_preview.gif', save_all=True, append_images=preview[1:], duration=[50 if (i + 1) % 6 == 0 else 40 for i in range(24)], loop=0, optimize=False)
contact.resize((2304, 1536), Image.Resampling.NEAREST).save(dest / 'walk_contact_sheet.png')
manifest = json.loads((dest / 'manifest.json').read_text())
manifest.update({
    'revision': 3,
    'head_match': 'Idle head pixels are translated with the walk, keeping the 102px head width.',
    'head_motion': {'vertical_px': [0, 1, 2], 'horizontal_px': [-1, 0, 1], 'hair_top_range': [min(head_tops), max(head_tops)]},
    'native_source': 'walk_cycle_24.aseprite',
    'preview': 'walk_cycle_24_preview.gif',
})
(dest / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
print('Published moving Idle-sized head; 24 frames, source-body preserved.')

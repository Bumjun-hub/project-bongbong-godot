"""Publish the reviewed Aseprite head match into the 24-frame Godot Walk."""
from pathlib import Path
import json
import shutil

from PIL import Image, ImageDraw


root = Path(__file__).resolve().parents[3]
work = Path(__file__).resolve().parent
dest = root / 'assets/character/walk/grok_right_calm'
backup = work / 'before-head-match'
backup.mkdir(exist_ok=True)
sheet = Image.open(work / 'walk_idle_head_candidate.png').convert('RGBA')
assert sheet.size == (24 * 192, 192)
idle = Image.open(root / 'assets/character/idle/default_three_quarter_right/idle_default_three_quarter_right_01.png').convert('RGBA')
preview = []
contact = Image.new('RGBA', (6 * 192, 4 * 192), (39, 47, 58, 255))
for index in range(24):
    name = f'walk_{index + 1:02}.png'
    path = dest / name
    if not (backup / name).exists():
        shutil.copy2(path, backup / name)
    prior = Image.open(backup / name).convert('RGBA')
    frame = sheet.crop((index * 192, 0, (index + 1) * 192, 192))
    assert frame.crop((0, 0, 192, 111)).tobytes() == idle.crop((0, 0, 192, 111)).tobytes()
    assert frame.crop((0, 111, 192, 192)).tobytes() == prior.crop((0, 111, 192, 192)).tobytes()
    frame.save(path)
    x, y = (index % 6) * 192, (index // 6) * 192
    contact.alpha_composite(frame, (x, y))
    ImageDraw.Draw(contact).text((x + 5, y + 5), str(index + 1), fill='white')
    bg = Image.new('RGBA', (192, 192), (39, 47, 58, 255))
    bg.alpha_composite(frame)
    preview.append(bg.convert('RGB').resize((384, 384), Image.Resampling.NEAREST))

shutil.copy2(work / 'walk_idle_head_candidate.aseprite', dest / 'walk_cycle_24.aseprite')
shutil.copy2(work / 'walk_idle_head_candidate.png', dest / 'walk_cycle_24.png')
preview[0].save(dest / 'walk_cycle_24_preview.gif', save_all=True, append_images=preview[1:], duration=[42] * 24, loop=0, optimize=False)
contact.resize((2304, 1536), Image.Resampling.NEAREST).save(dest / 'walk_contact_sheet.png')
manifest = json.loads((dest / 'manifest.json').read_text())
manifest.update({
    'head_match': 'The top 111 rows of each Walk frame exactly match Idle frame 1; lower rows preserve the Grok Walk.',
    'head_reference': 'assets/character/idle/default_three_quarter_right/idle_default_three_quarter_right_01.png',
    'native_source': 'walk_cycle_24.aseprite',
    'preview': 'walk_cycle_24_preview.gif',
    'revision': 2,
})
(dest / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
print('Published 24 Walk frames with exact Idle head pixels.')

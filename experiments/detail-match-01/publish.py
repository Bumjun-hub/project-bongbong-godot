from pathlib import Path
import json,re
w=Path('experiments/detail-match-01');sets=json.loads((w/'mapping.json').read_text())
for s in sets:
 p=Path(s['resource']);before=p.read_text();after=before
 for f in s['frames']:
  assert f['source'] in after;after=after.replace(f['source'],f['output'])
 (w/(p.stem+'_before.txt')).write_text(before)
 norm=lambda t:re.sub(r'(\[ext_resource[^\n]*?) uid="[^"]+"',r'\1',re.sub(r'path="[^"]+"','path=""',t))
 assert norm(before)==norm(after)
 p.write_text(re.sub(r'(\[ext_resource[^\n]*?) uid="[^"]+"',r'\1',after));(Path(s['output'])/'manifest.json').write_text(json.dumps(s,indent=2))
v=Path('experiments/skin-match-01/verify_godot.gd').read_text().replace('experiments/skin-match-01/mapping.json','experiments/detail-match-01/mapping.json');(w/'verify_godot.gd').write_text(v)
print('Three movement resources updated; all timing and animation settings retained.')

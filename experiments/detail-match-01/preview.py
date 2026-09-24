from PIL import Image,ImageDraw
from pathlib import Path
import json
w=Path('experiments/detail-match-01');sets=json.loads((w/'mapping.json').read_text());sheet=Image.new('RGB',(1536,808),(48,57,69));d=ImageDraw.Draw(sheet);ref=Image.open(sets[0]['reference']).convert('RGBA').resize((384,384),Image.Resampling.NEAREST)
for row in range(2):sheet.paste(ref,(0,row*404+20),ref);d.text((4,row*404+4),'IDLE',fill='white')
for j,s in enumerate(sets):
 for row,key in enumerate(['source','output']):
  im=Image.open(s['frames'][0][key]).convert('RGBA').resize((384,384),Image.Resampling.NEAREST);x=(j+1)*384;y=row*404;sheet.paste(im,(x,y+20),im);d.text((x+4,y+4),s['name']+(' BEFORE' if row==0 else ' AFTER'),fill='white')
 contact=Image.new('RGB',(1344,212*((len(s['frames'])+6)//7)),(48,57,69));cd=ImageDraw.Draw(contact)
 for i,f in enumerate(s['frames']):
  im=Image.open(f['output']).convert('RGBA');x=i%7*192;y=i//7*212;contact.paste(im,(x,y+20),im);cd.text((x+3,y+3),str(i+1),fill='white')
 contact.save(w/(s['name']+'_contact.png'))
sheet.save(w/'comparison.png')

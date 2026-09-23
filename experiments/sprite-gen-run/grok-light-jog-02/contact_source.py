from pathlib import Path
from PIL import Image,ImageDraw
import sys
work=Path(__file__).resolve().parent
kind=sys.argv[1] if len(sys.argv)>1 else "keyed"
paths=sorted((work/"frames"/kind).glob("*.png"))
selected=paths[::6]
contact=Image.new("RGBA",(192*6,210*((len(selected)+5)//6)),(37,46,57,255))
d=ImageDraw.Draw(contact)
for i,path in enumerate(selected):
    frame=Image.open(path).convert("RGBA").resize((192,192),Image.Resampling.NEAREST)
    x,y=i%6*192,i//6*210
    contact.alpha_composite(frame,(x,y+18))
    d.text((x+5,y+3),path.stem,fill="white")
contact.save(work/f"source-{kind}-contact.png")
print(len(paths),"source frames")

"""Pad canonical loop frames without changing individual poses or their placement."""
from pathlib import Path
import json
import sys
from PIL import Image, ImageDraw

work = Path(__file__).resolve().parent
loop = work / (sys.argv[1] if len(sys.argv)>1 else "loop")
meta = json.loads((loop / "run.strip.json").read_text())
strip = Image.open(loop / "run.strip.png").convert("RGBA")
n,w,h = meta["frames"],meta["w"],meta["h"]
assert strip.size == (n*w,h) and w <= 190 and h <= 174
out=loop / "prepared"
out.mkdir(exist_ok=True)
offset=(95-w//2,174-h)
frames=[]
for i in range(n):
    canvas=Image.new("RGBA",(192,192))
    canvas.alpha_composite(strip.crop((i*w,0,(i+1)*w,h)),offset)
    canvas.save(out/f"run_{i+1:02}.png")
    frames.append(canvas)
columns=min(6,n)
contact=Image.new("RGBA",(columns*192,((n+columns-1)//columns)*210),(37,46,57,255))
draw=ImageDraw.Draw(contact)
preview=[]
for i,frame in enumerate(frames):
    x,y=i%columns*192,i//columns*210
    contact.alpha_composite(frame,(x,y+18))
    draw.text((x+5,y+3),str(i+1),fill="white")
    canvas=Image.new("RGBA",(192,192),(37,46,57,255))
    canvas.alpha_composite(frame)
    preview.append(canvas.convert("RGB"))
contact.save(out/"contact.png")
fps=float(sys.argv[2]) if len(sys.argv)>2 else n/meta["cycle_seconds"]
seconds=n/fps
times=[round(i*seconds/n*100)*10 for i in range(n+1)]
preview[0].save(out/"preview.gif",save_all=True,append_images=preview[1:],duration=[times[i+1]-times[i] for i in range(n)],loop=0,disposal=2)
(out/"metadata.json").write_text(json.dumps({"frames":n,"fps":fps,"cycle_seconds":seconds,"source_cycle_seconds":meta["cycle_seconds"],"offset":offset,"source":str(loop)},indent=2))
print(json.dumps({"frames":n,"seconds":seconds,"offset":offset,"out":str(out)}))

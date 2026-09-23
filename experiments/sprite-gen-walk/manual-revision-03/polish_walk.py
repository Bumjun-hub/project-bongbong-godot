from pathlib import Path
from collections import Counter
import json
import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
BASE = ROOT / 'assets/character/idle/default_three_quarter_right/idle_default_three_quarter_right_01.png'
base = np.array(Image.open(BASE).convert('RGBA'))
source = np.array(Image.open(HERE / 'source.png').convert('RGBA'))

def denim_mask(a):
    c = a[:, :, :3].astype(int)
    yy = np.indices(a.shape[:2])[0]
    return (yy >= 138) & (a[:, :, 3] > 0) & (c[:, :, 2] > c[:, :, 0] + 18) & (c[:, :, 2] > c[:, :, 1] + 3)

def kmeans(p, count):
    p = p.astype(float)
    centers = p[np.argsort(p.mean(1))[np.linspace(0, len(p)-1, count).astype(int)]].copy()
    for _ in range(30):
        labels = ((p[:, None] - centers[None]) ** 2).sum(2).argmin(1)
        for k in range(count):
            if np.any(labels == k):
                centers[k] = p[labels == k].mean(0)
    return centers[np.argsort(centers.mean(1))].round().astype(np.uint8)

base_denim = base[:, :, :3][denim_mask(base)]
walk_denim = source[:, :, :3][denim_mask(source)]
palette = kmeans(base_denim, 6)
offset = (np.median(base_denim, axis=0) - np.median(walk_denim, axis=0)) * 0.85
shoe_palette = np.array([[3,3,5], [28,28,34], [100,101,113], [186,186,195], [252,252,252]], dtype=np.uint8)

def polish(frame, outline):
    out = frame.copy()
    denim = denim_mask(frame)
    labels = np.full(frame.shape[:2], -1, dtype=int)
    colors = frame[:, :, :3][denim].astype(float) + offset
    labels[denim] = ((colors[:,None] - palette[None].astype(float)) ** 2).sum(2).argmin(1)
    # Replace isolated shade speckles only when surrounded by denim.
    revised = labels.copy()
    for y, x in zip(*np.where(denim)):
        if y == 0 or x == 0 or y == 191 or x == 191:
            continue
        neighbors = labels[y-1:y+2, x-1:x+2].copy().reshape(-1)
        neighbors = np.delete(neighbors, 4)
        valid = neighbors[neighbors >= 0]
        if len(valid) >= 6 and np.count_nonzero(valid == labels[y,x]) == 0:
            value, count = Counter(valid.tolist()).most_common(1)[0]
            if count >= 3 and abs(value - labels[y,x]) <= 2:
                revised[y,x] = value
    # Small interior shade islands are texture noise at native resolution.
    visited = set()
    for y, x in zip(*np.where(denim)):
        if (y,x) in visited:
            continue
        level = revised[y,x]
        stack = [(y,x)]
        region = []
        visited.add((y,x))
        while stack:
            v,u = stack.pop()
            region.append((v,u))
            for dy,dx in ((-1,0),(1,0),(0,-1),(0,1)):
                vv,uu = v+dy,u+dx
                if 0<=vv<192 and 0<=uu<192 and denim[vv,uu] and revised[vv,uu]==level and (vv,uu) not in visited:
                    visited.add((vv,uu));stack.append((vv,uu))
        if len(region)>2:
            continue
        boundary = []
        interior = True
        for v,u in region:
            for dy,dx in ((-1,0),(1,0),(0,-1),(0,1)):
                vv,uu=v+dy,u+dx
                if not (0<=vv<192 and 0<=uu<192 and denim[vv,uu]):
                    interior=False
                elif revised[vv,uu]!=level:
                    boundary.append(int(revised[vv,uu]))
        if interior and boundary:
            value,count=Counter(boundary).most_common(1)[0]
            if count>=3 and abs(value-level)<=1:
                for v,u in region:
                    revised[v,u]=value
    out[:, :, :3][denim] = palette[revised[denim]]
    yy, xx = np.indices(frame.shape[:2])
    shoes = (yy >= 153) & (yy <= 173) & (xx >= 50) & (xx <= 143) & (frame[:,:,3] > 0) & ~denim
    pixels = frame[:, :, :3][shoes].astype(float)
    nearest = ((pixels[:,None] - shoe_palette[None].astype(float)) ** 2).sum(2).argmin(1)
    out[:, :, :3][shoes] = shoe_palette[nearest]
    if outline:
        occupied = frame[:,:,3] > 0
        legs = denim | shoes
        # One outside pixel keeps the original fabric/sole interiors intact.
        for y in range(144, 174):
            for x in range(49, 145):
                if occupied[y,x]:
                    continue
                neighbors = [(y+dy,x+dx) for dy,dx in ((-1,0),(1,0),(0,-1),(0,1))]
                touching = [(v,u) for v,u in neighbors if legs[v,u]]
                if touching:
                    color = palette[0] if all(denim[v,u] for v,u in touching) else shoe_palette[0]
                    out[y,x] = [*color,255]
        # The shared ground row must retain its current height.
        for x in range(50,144):
            if shoes[173,x]:
                out[173,x,:3] = shoe_palette[0]
    return out

for outline in (False, True):
    frames = [polish(source[:,i*192:(i+1)*192],outline) for i in range(8)]
    sheet = Image.fromarray(np.concatenate(frames,axis=1))
    name = 'outlined' if outline else 'palette'
    sheet.save(HERE / f'candidate-{name}.png')
    review = Image.new('RGB',(1600,460),(42,42,42))
    draw = ImageDraw.Draw(review)
    for i, frame in enumerate(frames):
        crop = Image.fromarray(frame).crop((46,130,146,180))
        bg = Image.new('RGBA',crop.size,(42,42,42,255));bg.alpha_composite(crop)
        review.paste(bg.resize((400,200),Image.Resampling.NEAREST).convert('RGB'),((i%4)*400,(i//4)*230+24))
        draw.text(((i%4)*400+6,(i//4)*230+4),str(i+1),fill='white')
    review.save(HERE / 'reports' / f'legs-{name}-4x.png')
(HERE / 'palette.json').write_text(json.dumps({'denim':palette.tolist(),'shoes':shoe_palette.tolist(),'color_offset':offset.tolist()},indent=2),encoding='utf-8')

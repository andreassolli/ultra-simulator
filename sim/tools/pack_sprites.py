#!/usr/bin/env python3
"""Pack FFDec sprite:png exports into cropped sprite sheets + a JSON atlas.

Usage: pack_sprites.py <ffdec-export-dir> <rects.txt> <out-dir> <zoom>

<ffdec-export-dir> holds DefineSprite_<id>_<class>/<n>.png folders.
<rects.txt>        SwfIndex output: "<id> <class> xmin ymin xmax ymax frames" (twips).
Each frame is cropped to its visible pixels; its offset is stored relative to
the sprite's registration point, in exported (zoomed) pixels.
"""
import hashlib, json, os, re, sys
from PIL import Image

src, rects_file, out, zoom = sys.argv[1], sys.argv[2], sys.argv[3], float(sys.argv[4])
os.makedirs(out, exist_ok=True)
rects = {}
for line in open(rects_file):
    p = line.split()
    if len(p) == 7:
        rects[int(p[0])] = tuple(int(v) for v in p[2:6])

SHEET_W = 4096
atlas = {}
for d in sorted(os.listdir(src)):
    m = re.match(r"DefineSprite_(\d+)_(.*)", d)
    if not m or int(m.group(1)) not in rects:
        continue
    sid, cls = int(m.group(1)), m.group(2).split(".")[-1]
    xmin, ymin = rects[sid][0] / 20 * zoom, rects[sid][1] / 20 * zoom
    files = sorted(os.listdir(os.path.join(src, d)), key=lambda f: int(f.split(".")[0]))
    crops, seen, order = [], {}, []
    for f in files:
        im = Image.open(os.path.join(src, d, f)).convert("RGBA")
        bb = im.getbbox()
        if bb is None:
            order.append(None)
            continue
        c = im.crop(bb)
        h = hashlib.md5(c.tobytes() + bytes(str(bb[:2]), "ascii")).hexdigest()
        if h not in seen:
            seen[h] = len(crops)
            crops.append((c, bb[0] + xmin, bb[1] + ymin))
        order.append(seen[h])
    # shelf packing into one or more sheets (WebP is limited to 16383 px)
    MAX_H = 8192
    sheets, pos = [[]], []
    x = y = rowh = 0
    for i, (c, ox, oy) in enumerate(crops):
        w, h = c.size
        if x + w > SHEET_W:
            x, y, rowh = 0, y + rowh, 0
        if y + h > MAX_H:
            sheets.append([])
            x = y = rowh = 0
        pos.append((len(sheets) - 1, x, y))
        sheets[-1].append(i)
        x += w
        rowh = max(rowh, h)
    names = []
    for si, members in enumerate(sheets):
        if not members:
            continue
        sw = max(pos[i][1] + crops[i][0].size[0] for i in members)
        sh = max(pos[i][2] + crops[i][0].size[1] for i in members)
        sheet = Image.new("RGBA", (sw, sh))
        for i in members:
            sheet.paste(crops[i][0], (pos[i][1], pos[i][2]))
        name = f"{cls}.webp" if len(sheets) == 1 else f"{cls}_{si}.webp"
        sheet.save(os.path.join(out, name), "WEBP", quality=80, method=4)
        names.append(name)
    atlas[cls] = {
        "id": sid, "sheets": names, "zoom": zoom, "count": len(files),
        "rects": [[p[0], p[1], p[2], c.size[0], c.size[1], round(ox, 1), round(oy, 1)]
                  for (c, ox, oy), p in zip(crops, pos)],
        "frames": order,
    }
json.dump(atlas, open(os.path.join(out, "atlas.json"), "w"), separators=(",", ":"))
print(len(atlas), "clips,", sum(os.path.getsize(os.path.join(out, f)) for f in os.listdir(out)) // 1024, "KiB")

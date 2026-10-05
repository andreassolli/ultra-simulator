// Sprite-sheet clips produced by tools/pack_sprites.py (FFDec sprite:png -> cropped WebP sheets).

const imgCache = new Map();

export function loadImage(url) {
  if (!imgCache.has(url)) {
    imgCache.set(
      url,
      new Promise((resolve, reject) => {
        const img = new Image();
        img.onload = () => resolve(img);
        img.onerror = () => reject(new Error('failed to load ' + url));
        img.src = url;
      })
    );
  }
  return imgCache.get(url);
}

export class Clip {
  constructor(dir, name, data) {
    this.dir = dir;
    this.name = name;
    this.data = data;
    this.imgs = null;
    this.loading = null;
    this.zoom = data.zoom;
    this.count = data.count;
  }

  /** Resolves once every sheet of this clip is decoded. */
  load() {
    if (!this.loading) {
      this.loading = Promise.all(this.data.sheets.map((s) => loadImage(`${this.dir}/${s}`))).then((imgs) => {
        this.imgs = imgs;
        return this;
      });
    }
    return this.loading;
  }

  get ready() {
    return this.imgs !== null;
  }

  /**
   * Draw 0-based frame `f` with the clip's registration point at (x, y).
   * `sx`/`sy` are stage pixels per exported pixel (negative sx mirrors).
   */
  draw(ctx, f, x, y, sx = 1, sy = sx) {
    if (!this.imgs || f < 0 || f >= this.data.frames.length) return;
    const ri = this.data.frames[f];
    if (ri === null || ri === undefined) return;
    const r = this.data.rects[ri];
    ctx.save();
    ctx.translate(x, y);
    ctx.scale(sx, sy);
    ctx.drawImage(this.imgs[r[0]], r[1], r[2], r[3], r[4], r[5], r[6], r[3], r[4]);
    ctx.restore();
  }
}

export async function loadAtlas(dir) {
  const res = await fetch(`${dir}/atlas.json`);
  if (!res.ok) throw new Error(`atlas ${dir}: ${res.status}`);
  const data = await res.json();
  const clips = {};
  for (const [name, d] of Object.entries(data)) clips[name] = new Clip(dir, name, d);
  return clips;
}

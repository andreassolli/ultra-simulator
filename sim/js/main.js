import { CONFIG as C } from './config.js';
import { loadAtlas, loadImage } from './sprites.js';

const canvas = document.getElementById('stage');
const ctx = canvas.getContext('2d');
const $ = (id) => document.getElementById(id);
const params = new URLSearchParams(location.search);

// ---------------------------------------------------------------- boss labels
// monster-UltraMalg.swf, sprite 273 "UltraMalg": label -> [first, last] frame (1-based)
const BOSS_ANIMS = {
  Idle: [8, 8],
  Attack1: [42, 59],
  Shadowflame: [60, 77],
  PowerUp: [78, 94],
  PowerLoop: [95, 111],
  Attack2: [112, 132],
  ChargeA: [133, 153],
  ChargeALoop: [154, 172],
  Absorption: [173, 190],
  ChargeB: [191, 208],
  ChargeBLoop: [209, 228],
  Magic: [229, 248],
  Hit: [252, 255],
  Fall: [256, 288],
  Getup: [289, 304],
  Die: [305, 379],
  Dead: [380, 385],
};

// --------------------------------------------------------------------- assets
const A = { boss: null, map: null, fx: null, bg: null };
const iconExists = new Set();

async function loadAssets() {
  const [boss, map, fx, bg, icons] = await Promise.all([
    loadAtlas('assets/boss'),
    loadAtlas('assets/map'),
    loadAtlas('assets/fx'),
    loadImage('assets/map/bg.jpg'),
    fetch('assets/icons/atlas.json').then((r) => r.json()),
  ]);
  A.boss = boss.UltraMalg;
  A.map = map;
  A.fx = fx;
  A.bg = bg;
  for (const k of Object.keys(icons)) iconExists.add(k);
  await Promise.all([A.boss.load(), map.runey2_159.load(), map.telerune1_171.load()]);
}

// ---------------------------------------------------------------- skill sets
const SLOT_KEYS = ['aa', '1', '2', '3', '4'];

function parseSkillName(name) {
  const base = name.slice(3);
  const m = base.match(/^(.*?)(aa|a[1-6]|[1-6])$/);
  if (!m || !m[1]) return { set: base, slot: null };
  const s = m[2];
  const slot = s === 'aa' ? 0 : parseInt(s.replace('a', ''), 10);
  return { set: m[1], slot: slot <= 4 ? slot : null };
}

function buildSets() {
  const sets = new Map();
  for (const name of Object.keys(A.fx)) {
    const { set, slot } = parseSkillName(name);
    if (!sets.has(set)) sets.set(set, [null, null, null, null, null]);
    if (slot !== null) sets.get(set)[slot] = name;
  }
  // keep only sets that hold at least one numbered slot
  for (const [k, v] of [...sets]) if (v.every((x) => x === null)) sets.delete(k);
  return sets;
}

// ----------------------------------------------------------------------- state
let S; // simulation state

function newState() {
  const pad = C.map.bossPad;
  return {
    time: 0, // sim seconds since engage
    over: null, // 'win' | 'lose'
    overAt: 0,
    player: {
      x: C.map.leftPad.x,
      y: C.map.leftPad.y,
      dir: 1,
      hp: C.player.hp,
      mp: C.player.mp,
      moveTo: null,
      moving: false,
      auto: true,
      pending: null,
      lunge: 0,
      gcdTs: -99,
      potTs: -99,
    },
    boss: {
      x: pad.x,
      y: pad.y,
      hp: C.boss.hp,
      anim: 'Idle',
      animT0: 0,
      animLoop: false,
      busy: false,
      seq: null,
      nextBasic: 2.0,
      basicN: 0,
      nextSpecial: C.boss.firstSpecialAt,
      specialN: 0,
      zone: '', // '', 'a', 'b', 'p'
      rune: false,
      charge: null, // {label, t0, dur}
      lastHit: -99,
    },
    slotTs: [-99, -99, -99, -99, -99],
    targetBoss: true,
    fx: [],
    floaters: [],
    telegraphs: [],
    keys: new Set(),
    log: [],
    stats: { dealt: 0, taken: 0, crits: 0, casts: 0, potions: 0, absorbs: 0, blasts: 0, healed: 0 },
  };
}

let slots = []; // current loadout: [{clip,name}|null x5]
let paused = false;
let speed = 1;
let bot = false;
let infMana = false;

// ---------------------------------------------------------------------- utils
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const fmt = (n) => Math.round(n).toLocaleString('en-US');
const rnd = (a, b) => a + Math.random() * (b - a);

function log(msg, cls = '') {
  S.log.push({ t: S.time, msg, cls });
  const el = $('log');
  const d = document.createElement('div');
  d.className = cls;
  d.textContent = `[${S.time.toFixed(1).padStart(5)}s] ${msg}`;
  el.appendChild(d);
  el.scrollTop = el.scrollHeight;
  while (el.childNodes.length > 80) el.removeChild(el.firstChild);
}

function floater(x, y, text, color, big = false) {
  S.floaters.push({ x, y, text, color, big, t: 0, life: 1.3, dx: rnd(-14, 14) });
}

function enrage() {
  const over = S.time - C.boss.enrageAt;
  return over > 0 ? 1 + 0.25 * (Math.floor(over / 30) + 1) : 1;
}

// ------------------------------------------------------------------ boss logic
function playBoss(name, loop = false) {
  const b = S.boss;
  b.anim = name;
  b.animT0 = S.time;
  b.animLoop = loop;
}

function animLen(name) {
  const [a, z] = BOSS_ANIMS[name];
  return (z - a + 1) / C.fps;
}

/** Run timed steps: [[delaySeconds, fn], ...] (delays are absolute from start). */
function startSeq(steps, onEnd) {
  const b = S.boss;
  b.busy = true;
  b.seq = { t: 0, steps: steps.map(([t, fn]) => ({ t, fn, done: false })), onEnd };
}

function setRune(on, zone) {
  S.boss.rune = on;
  S.boss.zone = on ? zone : '';
}

function inSafeBox(p) {
  const s = C.map.safeA;
  return p.x >= s.x && p.x <= s.x + s.w && p.y >= s.y && p.y <= s.y + s.h;
}

function playerInZone(zone) {
  return zone === 'a' ? inSafeBox(S.player) : !inSafeBox(S.player);
}

function hurtPlayer(dmg, why) {
  const p = S.player;
  if (S.over) return;
  dmg = Math.round(dmg * enrage());
  p.hp = Math.max(0, p.hp - dmg);
  S.stats.taken += dmg;
  floater(p.x, p.y - 120, `-${fmt(dmg)}`, '#ff5b5b');
  if (p.hp <= 0) {
    log(`${C.player.name} was defeated by ${why}`, 'bad');
    finish('lose');
  }
}

function startBasic() {
  const b = S.boss;
  const p = S.player;
  b.basicN++;
  const near = Math.abs(p.x - b.x) <= C.boss.meleeRangeX && Math.abs(p.y - b.y) <= C.boss.meleeRangeY;
  if (near && b.basicN % 3 !== 0) {
    playBoss('Attack1');
    startSeq(
      [
        [0.3, () => {
          const q = S.player;
          if (Math.abs(q.x - b.x) <= C.boss.meleeRangeX && Math.abs(q.y - b.y) <= C.boss.meleeRangeY)
            hurtPlayer(C.boss.attack1Damage, 'Attack1');
          else floater(q.x, q.y - 120, 'dodged', '#9ad');
        }],
        [animLen('Attack1'), () => {}],
      ],
      () => playBoss('Idle')
    );
  } else {
    playBoss('Shadowflame');
    const tx = clamp(p.x, C.walk.x0, C.walk.x1);
    const ty = clamp(p.y, C.walk.y0, C.walk.y1);
    const tg = { x: tx, y: ty, r: C.boss.flameRadius, t: 0, life: C.boss.flameTelegraph };
    S.telegraphs.push(tg);
    startSeq(
      [
        [C.boss.flameTelegraph, () => {
          S.telegraphs = S.telegraphs.filter((q) => q !== tg);
          const q = S.player;
          spawnBossBlast(tx, ty);
          if (Math.hypot(q.x - tx, (q.y - ty) * 1.8) <= tg.r) hurtPlayer(C.boss.flameDamage, 'Shadowflame');
          else floater(q.x, q.y - 120, 'dodged', '#9ad');
        }],
        [Math.max(animLen('Shadowflame'), C.boss.flameTelegraph), () => {}],
      ],
      () => playBoss('Idle')
    );
  }
}

function spawnBossBlast(x, y) {
  // reuse a player-set effect as a stand-in impact if loaded; otherwise plain ring
  S.floaters.push({ x, y: y - 20, text: '', color: '#f55', ring: true, t: 0, life: 0.5, big: false, dx: 0 });
}

function startSpecial() {
  const b = S.boss;
  const kind = C.boss.specialOrder[b.specialN++ % C.boss.specialOrder.length];
  const hold = C.boss.chargeHold;
  if (kind === 'A' || kind === 'B') {
    const zone = kind.toLowerCase();
    const intro = `Charge${kind}`;
    const loop = `Charge${kind}Loop`;
    const release = kind === 'A' ? 'Absorption' : 'Magic';
    const t1 = animLen(intro);
    playBoss(intro);
    setRune(true, zone);
    b.charge = { label: kind === 'A' ? 'Zone A — stand INSIDE the glowing box' : 'Zone B — stay OUTSIDE the box', t0: S.time, dur: t1 + hold };
    log(`Boss charges (zone ${kind}) — ${kind === 'A' ? 'get inside the box' : 'get outside the box'}`, 'bad');
    startSeq(
      [
        [t1, () => playBoss(loop, true)],
        [t1 + hold, () => {
          playBoss(release);
          b.charge = null;
        }],
        [t1 + hold + 0.3, () => {
          const ok = playerInZone(zone);
          S.stats.blasts++;
          if (ok) {
            S.stats.absorbs++;
            const heal = C.boss.hp * C.boss.absorbHeal;
            b.hp = Math.min(C.boss.hp, b.hp + heal);
            floater(b.x, b.y - 200, `+${fmt(heal)}`, '#6fd98a', true);
            log(`Survived zone ${kind}; boss absorbs ${fmt(heal)} HP`, 'good');
          } else {
            hurtPlayer(C.player.hp * C.boss.wrongZoneDamage * 2, `zone ${kind} blast`);
          }
          setRune(false);
        }],
        [t1 + hold + animLen(release), () => {}],
      ],
      () => playBoss('Idle')
    );
  } else {
    const t1 = animLen('PowerUp');
    playBoss('PowerUp');
    setRune(true, 'p');
    b.charge = { label: 'Power up — raid blast incoming', t0: S.time, dur: t1 + 4 };
    log('Boss powers up — brace for the raid blast', 'bad');
    startSeq(
      [
        [t1, () => playBoss('PowerLoop', true)],
        [t1 + 4, () => {
          playBoss('Attack2');
          b.charge = null;
          setRune(false); // client frame script on Attack2 frame 112 -> bossChargeSpell(false)
        }],
        [t1 + 4.4, () => {
          S.stats.blasts++;
          hurtPlayer(C.boss.raidBlastDamage, 'Attack2');
        }],
        [t1 + 4 + animLen('Attack2'), () => {}],
      ],
      () => playBoss('Idle')
    );
  }
}

function updateBoss(dt) {
  const b = S.boss;
  if (S.over === 'win') return;
  if (b.seq) {
    b.seq.t += dt;
    const seq = b.seq;
    for (const st of seq.steps) {
      if (!st.done && seq.t >= st.t) {
        st.done = true;
        st.fn();
      }
    }
    if (b.seq === seq && seq.steps.every((s) => s.done)) {
      const end = b.seq.onEnd;
      b.seq = null;
      b.busy = false;
      if (end) end();
      b.nextBasic = S.time + C.boss.basicEvery;
    }
    return;
  }
  if (S.over) return;
  if (S.time >= b.nextSpecial) {
    b.nextSpecial = S.time + C.boss.specialEvery;
    startSpecial();
  } else if (S.time >= b.nextBasic) {
    startBasic();
  } else if (S.time - b.lastHit > 4 && b.anim === 'Idle' && Math.random() < dt * 0.15) {
    b.lastHit = S.time;
    playBoss('Hit');
    startSeq([[animLen('Hit'), () => {}]], () => playBoss('Idle'));
  }
}

function bossFrame() {
  const b = S.boss;
  const [a, z] = BOSS_ANIMS[b.anim];
  const n = z - a + 1;
  let i = Math.floor((S.time - b.animT0) * C.fps);
  if (b.animLoop) i %= n;
  else i = Math.min(i, n - 1);
  return a - 1 + i;
}

// ---------------------------------------------------------------- player logic
function targetDist(slotCfg) {
  const p = S.player;
  const b = S.boss;
  const dx = Math.abs(b.x - p.x);
  const dy = Math.abs(b.y - p.y);
  if (slotCfg.range <= 301) return { ok: dx <= slotCfg.range && dy <= C.combat.vTolerance, dx, dy };
  return { ok: Math.hypot(dx, dy) <= slotCfg.range, dx, dy };
}

function skillReady(i) {
  const cfg = C.slots[i];
  if (!slots[i] && i > 0) return false;
  if (S.time - S.slotTs[i] < cfg.cd) return false;
  if (i > 0 && S.time - S.player.gcdTs < C.combat.gcd) return false;
  return infMana || S.player.mp >= cfg.mp;
}

function castSlot(i, autoWalk = true) {
  if (S.over) return false;
  const p = S.player;
  const b = S.boss;
  const cfg = C.slots[i];
  if (!skillReady(i)) return false;
  const d = targetDist(cfg);
  if (!d.ok) {
    if (autoWalk && !p.moveTo && !manualMove()) {
      // Game3 World.as: walk towards the target, then cast
      const dir = b.x >= p.x ? 1 : -1;
      const reach = Math.min(cfg.range * 0.6, d.dx);
      p.moveTo = { x: b.x - dir * reach, y: cfg.range <= 301 ? b.y : p.y };
      p.pending = i;
    }
    return false;
  }
  p.pending = null;
  p.moveTo = null;
  p.dir = b.x >= p.x ? 1 : -1;
  S.slotTs[i] = S.time;
  if (i > 0) p.gcdTs = S.time;
  // GCD also sits on the auto-attack shortly after a skill (Game: coolDownAct GCD+300)
  if (!infMana) p.mp -= cfg.mp;
  p.lunge = 0.25;
  S.stats.casts++;
  const sk = slots[i];
  if (sk) spawnSkillFx(sk);
  const crit = Math.random() < C.player.critChance;
  const dmg = Math.round(C.player.baseDamage * cfg.mult * rnd(0.88, 1.12) * (crit ? C.player.critMult : 1));
  const delay = sk ? Math.min(0.55, 0.3 + (sk.clip.count / C.fps) * 0.15) : 0.15;
  S.pendingHits = S.pendingHits || [];
  S.pendingHits.push({ at: S.time + delay, dmg, crit, name: sk ? sk.name.slice(3) : 'Attack' });
  return true;
}

function spawnSkillFx(sk) {
  if (!sk.clip.ready) {
    sk.clip.load();
    return;
  }
  const b = S.boss;
  const p = S.player;
  S.fx.push({
    clip: sk.clip,
    t0: S.time,
    x: b.x,
    y: b.y + 3,
    flip: b.x < p.x ? -1 : 1,
  });
}

function resolveHits() {
  const hits = S.pendingHits || [];
  for (const h of hits) {
    if (S.time < h.at || h.done) continue;
    h.done = true;
    const b = S.boss;
    if (S.over) continue;
    b.hp = Math.max(0, b.hp - h.dmg);
    S.stats.dealt += h.dmg;
    if (h.crit) S.stats.crits++;
    floater(b.x + rnd(-60, 60), b.y - 150 - rnd(0, 40), fmt(h.dmg) + (h.crit ? '!' : ''), h.crit ? '#ffd24a' : '#ffffff', h.crit);
    if (b.hp <= 0) {
      log(`Ultra Speaker defeated in ${fmtTime(S.time)}`, 'good');
      finish('win');
    }
  }
  S.pendingHits = hits.filter((h) => !h.done);
}

function usePotion() {
  const p = S.player;
  if (S.over || S.time - p.potTs < C.player.potion.cd) return false;
  p.potTs = S.time;
  const heal = Math.min(C.player.potion.heal, C.player.hp - p.hp);
  p.hp += heal;
  S.stats.potions++;
  S.stats.healed += heal;
  floater(p.x, p.y - 120, `+${fmt(heal)}`, '#6fd98a');
  return true;
}

function manualMove() {
  const k = S.keys;
  return k.has('a') || k.has('d') || k.has('w') || k.has('s') || k.has('arrowleft') || k.has('arrowright') || k.has('arrowup') || k.has('arrowdown');
}

function updatePlayer(dt) {
  const p = S.player;
  if (S.over) {
    p.moving = false;
    return;
  }
  p.mp = Math.min(C.player.mp, p.mp + C.player.mpRegen * dt);
  p.hp = Math.min(C.player.hp, p.hp + C.player.hp * C.player.hpRegen * dt);
  p.lunge = Math.max(0, p.lunge - dt);

  let vx = 0;
  let vy = 0;
  const k = S.keys;
  if (k.has('a') || k.has('arrowleft')) vx -= 1;
  if (k.has('d') || k.has('arrowright')) vx += 1;
  if (k.has('w') || k.has('arrowup')) vy -= 1;
  if (k.has('s') || k.has('arrowdown')) vy += 1;
  if (vx || vy) {
    p.moveTo = null;
    p.pending = null;
    const l = Math.hypot(vx, vy);
    vx /= l;
    vy /= l;
  } else if (p.moveTo) {
    const dx = p.moveTo.x - p.x;
    const dy = p.moveTo.y - p.y;
    const d = Math.hypot(dx, dy);
    if (d < 4) {
      p.moveTo = null;
    } else {
      vx = dx / d;
      vy = dy / d;
    }
  }
  p.moving = !!(vx || vy);
  if (p.moving) {
    const step = C.player.speed * dt;
    if (p.moveTo) {
      const d = Math.hypot(p.moveTo.x - p.x, p.moveTo.y - p.y);
      p.x += vx * Math.min(step, d);
      p.y += vy * Math.min(step, d);
    } else {
      p.x += vx * step;
      p.y += vy * step;
    }
    p.x = clamp(p.x, C.walk.x0, C.walk.x1);
    p.y = clamp(p.y, C.walk.y0, C.walk.y1);
    if (vx) p.dir = vx > 0 ? 1 : -1;
  }
  if (p.pending !== null && !p.moving) castSlot(p.pending, false);
  if (p.auto && S.targetBoss && !p.moving) {
    if (skillReady(0)) castSlot(0, !bot);
  }
}

// ------------------------------------------------------------------- auto-pilot
function runBot() {
  const p = S.player;
  const b = S.boss;
  if (S.over || !bot) return;
  // 1) mechanics
  let goal = null;
  const z = b.rune ? b.zone : '';
  const box = C.map.safeA;
  if (z === 'a' && !inSafeBox(p)) {
    goal = { x: clamp(p.x, box.x + 40, box.x + box.w - 40), y: clamp(p.y, box.y + 40, box.y + box.h - 40) };
  } else if (z === 'b' && inSafeBox(p)) {
    const left = p.x - box.x < box.x + box.w - p.x;
    goal = { x: left ? box.x - 45 : box.x + box.w + 45, y: clamp(p.y, C.walk.y0, C.walk.y1) };
  } else if (z === 'a' || z === 'b') {
    goal = null; // already safe: hold position
  } else {
    // 2) step out of telegraphed circles
    const tg = S.telegraphs.find((t) => Math.hypot(p.x - t.x, (p.y - t.y) * 1.8) < t.r + 30);
    if (tg) {
      const ang = Math.atan2(p.y - tg.y, p.x - tg.x) || 0;
      goal = { x: clamp(tg.x + Math.cos(ang) * (tg.r + 70), C.walk.x0, C.walk.x1), y: clamp(tg.y + Math.sin(ang) * (tg.r + 70) / 1.8, C.walk.y0, C.walk.y1) };
    } else if (!(p.moveTo && p.pending !== null)) {
      // ranged stand-off position: out of melee, inside range of the 600-range skills
      const want = { x: b.x - 330, y: b.y + 125 };
      if (Math.hypot(p.x - want.x, p.y - want.y) > 40) goal = want;
    }
  }
  if (goal) {
    p.moveTo = goal;
    p.pending = null;
  }
  if (p.hp < C.player.hp * 0.45 || (b.rune && b.zone === 'p' && p.hp < C.player.hp * 0.7)) usePotion();
  if (!manualMove() && !goal) {
    for (const i of [4, 3, 2, 1]) if (skillReady(i) && castSlot(i, false)) break;
  }
}

// --------------------------------------------------------------------- lifecycle
function finish(result) {
  if (S.over) return;
  S.over = result;
  S.overAt = S.time;
  S.telegraphs = [];
  const b = S.boss;
  if (result === 'win') {
    b.seq = null;
    b.busy = false;
    setRune(false);
    b.charge = null;
    playBoss('Die');
    S.boss.dieT = S.time;
  } else {
    b.seq = null;
    b.charge = null;
    setRune(false);
    b.busy = false;
    playBoss('Idle');
  }
}

function fmtTime(t) {
  const m = Math.floor(t / 60);
  const s = Math.floor(t % 60);
  return `${m}:${String(s).padStart(2, '0')}`;
}

function update(dtRaw) {
  const dt = Math.min(dtRaw, 0.1) * speed;
  S.time += dt;
  if (!S.over || S.over === 'win') updateBoss(dt);
  if (S.over === 'win') {
    const b = S.boss;
    if (b.anim === 'Die' && S.time - b.animT0 >= animLen('Die')) playBoss('Dead', true);
  }
  runBot();
  updatePlayer(dt);
  resolveHits();
  S.fx = S.fx.filter((f) => (S.time - f.t0) * C.fps < f.clip.count);
  S.floaters.forEach((f) => (f.t += dt));
  S.floaters = S.floaters.filter((f) => f.t < f.life);
  S.telegraphs.forEach((t) => (t.t += dt));
}

// ----------------------------------------------------------------------- render
function drawPlayer(p) {
  const t = S.time;
  const bob = p.moving ? Math.sin(t * 16) * 3 : Math.sin(t * 2.5) * 1;
  const lunge = p.lunge > 0 ? Math.sin((p.lunge / 0.25) * Math.PI) * 14 * p.dir : 0;
  const dead = S.over === 'lose';
  ctx.save();
  ctx.translate(p.x, p.y);
  ctx.fillStyle = 'rgba(0,0,0,.35)';
  ctx.beginPath();
  ctx.ellipse(0, 0, 30, 9, 0, 0, Math.PI * 2);
  ctx.fill();
  ctx.scale(p.dir, 1);
  if (dead) ctx.rotate(-Math.PI / 2.2);
  ctx.translate(lunge * p.dir, bob * -1);
  // cape
  ctx.fillStyle = '#7a1f3a';
  ctx.beginPath();
  ctx.moveTo(-10, -78);
  ctx.quadraticCurveTo(-34, -40 - Math.sin(t * 6) * 3, -18, -4);
  ctx.lineTo(-4, -8);
  ctx.closePath();
  ctx.fill();
  // legs
  const leg = p.moving ? Math.sin(t * 16) * 8 : 0;
  ctx.strokeStyle = '#2d3a55';
  ctx.lineWidth = 9;
  ctx.lineCap = 'round';
  ctx.beginPath();
  ctx.moveTo(-5, -34); ctx.lineTo(-6 + leg, -3);
  ctx.moveTo(6, -34); ctx.lineTo(7 - leg, -3);
  ctx.stroke();
  // torso
  ctx.fillStyle = '#4b6aa8';
  ctx.beginPath();
  ctx.roundRect(-14, -82, 28, 52, 8);
  ctx.fill();
  ctx.fillStyle = '#c9a24a';
  ctx.fillRect(-14, -50, 28, 5);
  // head
  ctx.fillStyle = '#f0c9a0';
  ctx.beginPath();
  ctx.arc(0, -96, 13, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = '#3b2a1c';
  ctx.beginPath();
  ctx.arc(-1, -101, 13, Math.PI, Math.PI * 2);
  ctx.fill();
  // weapon
  ctx.strokeStyle = '#d7dde8';
  ctx.lineWidth = 4;
  ctx.beginPath();
  const swing = p.lunge > 0 ? -1.2 + (1 - p.lunge / 0.25) * 2.2 : 0.2;
  ctx.moveTo(14, -58);
  ctx.lineTo(14 + Math.sin(swing) * 46, -58 - Math.cos(swing) * 46);
  ctx.stroke();
  ctx.restore();
}

function bar(x, y, w, h, frac, c1, c2, back = '#10131c') {
  ctx.fillStyle = back;
  ctx.fillRect(x, y, w, h);
  const g = ctx.createLinearGradient(0, y, 0, y + h);
  g.addColorStop(0, c1);
  g.addColorStop(1, c2);
  ctx.fillStyle = g;
  ctx.fillRect(x, y, Math.max(0, w * frac), h);
  ctx.strokeStyle = 'rgba(255,255,255,.35)';
  ctx.lineWidth = 1;
  ctx.strokeRect(x + 0.5, y + 0.5, w - 1, h - 1);
}

function text(str, x, y, { size = 12, color = '#fff', align = 'left', bold = false, stroke = true } = {}) {
  ctx.font = `${bold ? '700 ' : ''}${size}px system-ui, sans-serif`;
  ctx.textAlign = align;
  ctx.textBaseline = 'alphabetic';
  if (stroke) {
    ctx.lineWidth = 3;
    ctx.strokeStyle = 'rgba(0,0,0,.8)';
    ctx.strokeText(str, x, y);
  }
  ctx.fillStyle = color;
  ctx.fillText(str, x, y);
}

function drawHud() {
  const b = S.boss;
  const p = S.player;
  // boss target frame (top centre)
  const bw = 320;
  const bx = (C.stage.w - bw) / 2;
  ctx.fillStyle = 'rgba(8,10,18,.72)';
  ctx.beginPath();
  ctx.roundRect(bx - 8, 6, bw + 16, 58, 8);
  ctx.fill();
  text(`${C.boss.name}`, bx, 24, { size: 14, bold: true });
  text(`Lvl ${C.boss.level}`, bx + bw, 24, { size: 12, align: 'right', color: '#ffd24a' });
  const frac = b.hp / C.boss.hp;
  bar(bx, 31, bw, 16, frac, '#ff5b5b', '#a01626');
  text(`${fmt(b.hp)} / ${fmt(C.boss.hp)}  (${(frac * 100).toFixed(1)}%)`, bx + bw / 2, 44, { size: 11, align: 'center', bold: true });
  if (b.charge) {
    const f = clamp((S.time - b.charge.t0) / b.charge.dur, 0, 1);
    bar(bx, 51, bw, 8, f, '#ffb347', '#c46b00');
  }

  // player frame (top left)
  const pw = 210;
  ctx.fillStyle = 'rgba(8,10,18,.72)';
  ctx.beginPath();
  ctx.roundRect(6, 6, pw + 16, 72, 8);
  ctx.fill();
  text(`${C.player.name}`, 14, 24, { size: 14, bold: true });
  text(`Lvl ${C.player.level}`, 14 + pw, 24, { size: 12, align: 'right', color: '#ffd24a' });
  bar(14, 31, pw, 14, p.hp / C.player.hp, '#6fe08a', '#1d8a3a');
  text(`${fmt(p.hp)} / ${fmt(C.player.hp)}`, 14 + pw / 2, 42, { size: 11, align: 'center', bold: true });
  bar(14, 49, pw, 10, p.mp / C.player.mp, '#6aa7ff', '#1d4fa8');
  text(`MP ${Math.floor(infMana ? C.player.mp : p.mp)}`, 14 + pw / 2, 58, { size: 9, align: 'center' });
  const pots = Math.max(0, C.player.potion.cd - (S.time - p.potTs));
  text(`Potion ${pots > 0 ? pots.toFixed(0) + 's' : 'ready'}`, 14, 73, { size: 10, color: pots > 0 ? '#8a95ab' : '#6fd98a' });

  // clock
  text(fmtTime(S.over ? S.overAt : S.time), C.stage.w - 12, 22, { size: 14, align: 'right', bold: true });
  const en = enrage();
  if (en > 1) text(`ENRAGE ×${en.toFixed(2)}`, C.stage.w - 12, 40, { size: 12, align: 'right', color: '#ff5b5b', bold: true });

  // mechanic banner
  if (b.charge) {
    const left = Math.max(0, b.charge.dur - (S.time - b.charge.t0));
    text(`${b.charge.label}  (${left.toFixed(1)}s)`, C.stage.w / 2, 86, { size: 15, align: 'center', bold: true, color: '#ffd24a' });
    if (b.zone === 'a' || b.zone === 'b') {
      const ok = playerInZone(b.zone);
      text(ok ? 'SAFE' : 'MOVE!', C.stage.w / 2, 106, { size: 16, align: 'center', bold: true, color: ok ? '#6fd98a' : '#ff5b5b' });
    }
  }

  if (S.over) {
    ctx.fillStyle = 'rgba(0,0,0,.45)';
    ctx.fillRect(0, 170, C.stage.w, 120);
    text(S.over === 'win' ? 'VICTORY' : 'DEFEATED', C.stage.w / 2, 225, { size: 44, align: 'center', bold: true, color: S.over === 'win' ? '#6fd98a' : '#ff5b5b' });
    text(`${fmtTime(S.overAt)} · ${fmt(S.stats.dealt)} damage · press Restart`, C.stage.w / 2, 258, { size: 15, align: 'center' });
  }
}

function drawOverlays() {
  const b = S.boss;
  const m = A.map;
  const boxP = C.map.safeA;
  // rune glow on the platform while charging
  if (b.rune) {
    const pulse = 0.78 + 0.22 * Math.sin(S.time * 7);
    const r = C.map.rune1;
    ctx.save();
    ctx.globalAlpha = pulse;
    m.runey2_159.draw(ctx, 1, r.x, r.y, r.sx, r.sy);
    ctx.restore();
    if (b.zone === 'a') {
      const s = C.map.safe1;
      const i = 1 + (Math.floor(S.time * C.fps) % (m.telerune1_171.count - 1));
      ctx.save();
      ctx.globalAlpha = 0.9;
      m.telerune1_171.draw(ctx, i, s.x, s.y, s.sx, s.sy);
      ctx.restore();
    } else if (b.zone === 'b') {
      // zone B: the box stays dark; mark it as the forbidden area
      ctx.save();
      ctx.fillStyle = 'rgba(40,0,0,.28)';
      ctx.fillRect(boxP.x, boxP.y, boxP.w, boxP.h);
      ctx.setLineDash([10, 8]);
      ctx.strokeStyle = 'rgba(255,90,90,.55)';
      ctx.lineWidth = 2;
      ctx.strokeRect(boxP.x, boxP.y, boxP.w, boxP.h);
      ctx.restore();
    }
  }
}

function drawTelegraphs() {
  for (const t of S.telegraphs) {
    const f = clamp(t.t / t.life, 0, 1);
    ctx.save();
    ctx.translate(t.x, t.y);
    ctx.scale(1, 1 / 1.8);
    ctx.beginPath();
    ctx.arc(0, 0, t.r, 0, Math.PI * 2);
    ctx.fillStyle = `rgba(255,50,50,${0.12 + 0.2 * f})`;
    ctx.fill();
    ctx.lineWidth = 3;
    ctx.strokeStyle = 'rgba(255,90,90,.9)';
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(0, 0, t.r * f, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(255,60,60,.35)';
    ctx.fill();
    ctx.restore();
  }
}

function render() {
  ctx.clearRect(0, 0, C.stage.w, C.stage.h);
  ctx.drawImage(A.bg, 0, 0);
  drawOverlays();

  const b = S.boss;
  const ents = [
    { y: b.y, draw: () => {
        ctx.fillStyle = 'rgba(0,0,0,.38)';
        ctx.beginPath();
        ctx.ellipse(b.x, b.y + 4, 150, 22, 0, 0, Math.PI * 2);
        ctx.fill();
        const bob = S.over === 'win' ? 0 : Math.sin(S.time * 2.2) * 4;
        const sc = C.boss.displayScale;
        A.boss.draw(ctx, bossFrame(), b.x, b.y + bob, sc, sc);
      } },
    { y: S.player.y, draw: () => drawPlayer(S.player) },
  ].sort((a, c) => a.y - c.y);
  ents.forEach((e) => e.draw());

  drawTelegraphs();

  // spell effects (Game3 World.castSpellFX, fx "w": played at the target)
  for (const f of S.fx) {
    const fr = Math.floor((S.time - f.t0) * C.fps);
    const s = 1 / f.clip.zoom;
    f.clip.draw(ctx, fr, f.x, f.y, s * f.flip, s);
  }

  // floaters
  for (const f of S.floaters) {
    const k = f.t / f.life;
    if (f.ring) {
      ctx.save();
      ctx.globalAlpha = 1 - k;
      ctx.strokeStyle = '#ff6a3a';
      ctx.lineWidth = 6 * (1 - k);
      ctx.beginPath();
      ctx.ellipse(f.x, f.y + 20, 20 + 140 * k, (20 + 140 * k) / 1.8, 0, 0, Math.PI * 2);
      ctx.stroke();
      ctx.restore();
      continue;
    }
    ctx.save();
    ctx.globalAlpha = 1 - k * k;
    text(f.text, f.x + f.dx * k, f.y - 50 * k, { size: f.big ? 22 : 16, align: 'center', bold: true, color: f.color });
    ctx.restore();
  }

  // player overhead hp bar
  const p = S.player;
  bar(p.x - 28, p.y - 124, 56, 6, p.hp / C.player.hp, '#6fe08a', '#1d8a3a');
  text(C.player.name, p.x, p.y - 128, { size: 11, align: 'center', bold: true });
  if (S.targetBoss) {
    ctx.strokeStyle = 'rgba(255,210,74,.9)';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.ellipse(b.x, b.y + 4, 62, 14, 0, 0, Math.PI * 2);
    ctx.stroke();
  }
  // boss overhead hp bar (mirrors AQW monster nameplate)
  bar(b.x - 70, b.y + 22, 140, 7, b.hp / C.boss.hp, '#ff5b5b', '#a01626');

  drawHud();
}

// --------------------------------------------------------------------- DOM / UI
function buildSkillbar() {
  const bar = $('skillbar');
  bar.innerHTML = '';
  for (let i = 0; i < 5; i++) {
    const b = document.createElement('button');
    b.className = 'slot';
    b.dataset.i = i;
    const sk = slots[i];
    const base = sk ? sk.name.slice(3) : null;
    const icon = base && iconExists.has(base) ? `<img src="assets/icons/${base}.webp" alt="">` : `<span class="lbl">${sk ? base : i === 0 ? 'Attack' : '—'}</span>`;
    b.innerHTML = `${icon}<span class="key">${i === 0 ? '1' : i + 1}</span><span class="cd"></span><span class="cdt"></span>`;
    b.addEventListener('click', () => castSlot(i));
    b.title = (i === 0 ? 'Auto attack' : 'Skill ' + i) + (sk ? ` — ${sk.name}` : '');
    bar.appendChild(b);
  }
  const pot = document.createElement('button');
  pot.className = 'slot';
  pot.dataset.i = 'pot';
  pot.innerHTML = `<span class="cdt" style="font-size:12px">Potion</span><span class="key">6</span><span class="cd"></span><span class="cdt pt"></span>`;
  pot.addEventListener('click', usePotion);
  bar.appendChild(pot);
}

function updateSkillbar() {
  const nodes = $('skillbar').children;
  for (let i = 0; i < 5; i++) {
    const n = nodes[i];
    const cfg = C.slots[i];
    const cdLeft = Math.max(cfg.cd - (S.time - S.slotTs[i]), 0);
    const gcd = i > 0 ? Math.max(C.combat.gcd - (S.time - S.player.gcdTs), 0) : 0;
    const left = Math.max(cdLeft, gcd);
    const frac = left / (left === gcd && gcd > cdLeft ? C.combat.gcd : cfg.cd);
    n.querySelector('.cd').style.height = `${clamp(frac, 0, 1) * 100}%`;
    const t = n.querySelectorAll('.cdt');
    t[t.length - 1].textContent = left > 0.05 ? left.toFixed(left > 9.95 ? 0 : 1) : '';
    const lack = !infMana && S.player.mp < cfg.mp;
    n.classList.toggle('off', (!slots[i] && i > 0) || lack);
    n.classList.toggle('active', i === 0 && S.player.auto);
  }
  const pn = nodes[5];
  const pl = Math.max(C.player.potion.cd - (S.time - S.player.potTs), 0);
  pn.querySelector('.cd').style.height = `${(pl / C.player.potion.cd) * 100}%`;
  pn.querySelector('.pt').textContent = pl > 0.05 ? pl.toFixed(0) : '';
}

function updateStats() {
  const s = S.stats;
  const t = Math.max(S.over ? S.overAt : S.time, 0.001);
  const rows = [
    ['Time', fmtTime(t)],
    ['Damage dealt', fmt(s.dealt)],
    ['DPS', fmt(s.dealt / t)],
    ['Crits', s.crits],
    ['Damage taken', fmt(s.taken)],
    ['Zone/raid blasts', `${s.blasts}`],
    ['Absorptions survived', s.absorbs],
    ['Potions', s.potions],
  ];
  $('stats').innerHTML = rows.map(([a, b]) => `<div><span>${a}</span><b>${b}</b></div>`).join('');
}

async function setSkillSet(name) {
  const sets = window.__sets;
  const arr = sets.get(name);
  slots = arr.map((n) => (n ? { name: n, clip: A.fx[n] } : null));
  await Promise.all(slots.filter(Boolean).map((s) => s.clip.load()));
  buildSkillbar();
  buildPickers();
}

function buildPickers() {
  const host = $('slotPickers');
  host.innerHTML = '';
  const all = Object.keys(A.fx).sort((a, b) => a.localeCompare(b, undefined, { sensitivity: 'base' }));
  for (let i = 0; i < 5; i++) {
    const lab = document.createElement('label');
    lab.innerHTML = `<span>${i === 0 ? 'Atk' : 'S' + i}</span>`;
    const sel = document.createElement('select');
    sel.innerHTML = `<option value="">— none —</option>` + all.map((n) => `<option value="${n}"${slots[i] && slots[i].name === n ? ' selected' : ''}>${n.slice(3)} (${A.fx[n].count}f)</option>`).join('');
    sel.addEventListener('change', async () => {
      slots[i] = sel.value ? { name: sel.value, clip: A.fx[sel.value] } : null;
      if (slots[i]) await slots[i].clip.load();
      buildSkillbar();
    });
    lab.appendChild(sel);
    host.appendChild(lab);
  }
}

function restart() {
  const keep = S ? S.keys : new Set();
  S = newState();
  S.keys = keep;
  $('log').innerHTML = '';
  log('Engaged Ultra Speaker');
}

// ------------------------------------------------------------------------ input
function toStage(ev) {
  const r = canvas.getBoundingClientRect();
  return { x: ((ev.clientX - r.left) / r.width) * C.stage.w, y: ((ev.clientY - r.top) / r.height) * C.stage.h };
}

canvas.addEventListener('mousedown', (ev) => {
  const { x, y } = toStage(ev);
  const b = S.boss;
  if (Math.abs(x - b.x) < 150 && y > b.y - 200 && y < b.y + 40) {
    S.targetBoss = true;
    return;
  }
  const p = S.player;
  if (S.over) return;
  p.moveTo = { x: clamp(x, C.walk.x0, C.walk.x1), y: clamp(y, C.walk.y0, C.walk.y1) };
  p.pending = null;
});

const MOVE_KEYS = new Set(['w', 'a', 's', 'd', 'arrowup', 'arrowdown', 'arrowleft', 'arrowright']);
window.addEventListener('keydown', (ev) => {
  if (ev.target.tagName === 'SELECT') return;
  const k = ev.key.toLowerCase();
  if (MOVE_KEYS.has(k)) {
    S.keys.add(k);
    ev.preventDefault();
  } else if (k >= '1' && k <= '5') {
    castSlot(parseInt(k, 10) - 1);
    if (k === '1') S.targetBoss = true;
  } else if (k === '6') usePotion();
  else if (k === 'tab') {
    S.player.auto = !S.player.auto;
    ev.preventDefault();
  } else if (k === 'p') $('btnPause').click();
});
window.addEventListener('keyup', (ev) => S.keys.delete(ev.key.toLowerCase()));
window.addEventListener('blur', () => S.keys.clear());

$('btnRestart').addEventListener('click', restart);
$('btnPause').addEventListener('click', () => {
  paused = !paused;
  $('btnPause').textContent = paused ? 'Resume' : 'Pause';
});
$('selSpeed').addEventListener('change', (e) => (speed = parseFloat(e.target.value)));
$('chkBot').addEventListener('change', (e) => (bot = e.target.checked));
$('chkMana').addEventListener('change', (e) => (infMana = e.target.checked));

// ------------------------------------------------------------------------- main
let last = performance.now();
function frame(now) {
  const dt = (now - last) / 1000;
  last = now;
  if (!paused) update(dt);
  updateSkillbar();
  render();
  requestAnimationFrame(frame);
}

let statsTimer = 0;
async function main() {
  await loadAssets();
  const sets = buildSets();
  window.__sets = sets;
  const selSet = $('selSet');
  const names = [...sets.keys()].sort((a, b) => a.localeCompare(b, undefined, { sensitivity: 'base' }));
  selSet.innerHTML = names
    .map((n) => `<option value="${n}">${n} (${sets.get(n).filter(Boolean).length}/5)</option>`)
    .join('');
  const def = params.get('set') && sets.has(params.get('set')) ? params.get('set') : 'Archivist';
  selSet.value = def;
  selSet.addEventListener('change', () => setSkillSet(selSet.value));

  restart();
  await setSkillSet(def);
  if (params.get('speed')) {
    speed = parseFloat(params.get('speed'));
    $('selSpeed').value = String(speed);
  }
  if (params.get('bot')) {
    bot = true;
    $('chkBot').checked = true;
  }
  if (params.get('mana')) {
    infMana = true;
    $('chkMana').checked = true;
  }
  $('loading').style.display = 'none';
  setInterval(updateStats, 250);
  requestAnimationFrame((t) => {
    last = t;
    frame(t);
  });
  window.__sim = { get S() { return S; }, castSlot, C, restart, setBot: (v) => (bot = v), setSpeed: (v) => (speed = v) };
}

main().catch((e) => {
  $('loading').textContent = 'Failed to load: ' + e.message;
  console.error(e);
});

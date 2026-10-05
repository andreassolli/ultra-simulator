import { CONFIG as C } from './config.js';
import { loadAtlas, loadImage } from './sprites.js';
import { Fight, PATTERN, MECHANICS, ZONE_ROLES, ROLES, ROLE_NAMES, LOO } from './fight.js';

const canvas = document.getElementById('stage');
const ctx = canvas.getContext('2d');
const $ = (id) => document.getElementById(id);
const params = new URLSearchParams(location.search);

// monster-UltraMalg.swf, sprite 273 "UltraMalg": label -> [first, last] frame (1-based)
const BOSS_ANIMS = {
  Idle: [8, 8], Attack1: [42, 59], Shadowflame: [60, 77], PowerUp: [78, 94], PowerLoop: [95, 111],
  Attack2: [112, 132], ChargeA: [133, 153], ChargeALoop: [154, 172], Absorption: [173, 190],
  ChargeB: [191, 208], ChargeBLoop: [209, 228], Magic: [229, 248], Hit: [252, 255],
  Fall: [256, 288], Getup: [289, 304], Die: [305, 379], Dead: [380, 385],
};

const ROLE_COLOR = { ap: '#e8d9a0', lr: '#9b2d4f', loo: '#e0b84a', dps: '#5aa86a' };
const ROLE_SHORT = { ap: 'AP', lr: 'LR', loo: 'LoO', dps: 'DPS' };
const ROLE_OUT = { ap: { x: 880, y: 430 }, lr: { x: 850, y: 330 }, dps: { x: 100, y: 340 }, loo: { x: 110, y: 440 } };
const ZONE_IN = { x: 480, y: 420 };

const A = {};
let S;
let paused = false;
let speed = 1;
let bot = false;
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const fmt = (n) => Math.round(n).toLocaleString('en-US');
const rnd = (a, b) => a + Math.random() * (b - a);

// ------------------------------------------------------------------- assets
async function loadAssets() {
  const [boss, map, cfx, icons, bg] = await Promise.all([
    loadAtlas('assets/boss'),
    loadAtlas('assets/map'),
    loadAtlas('assets/classfx'),
    fetch('assets/icons/atlas.json').then((r) => r.json()),
    loadImage('assets/map/bg.jpg'),
  ]);
  A.boss = boss.UltraMalg;
  A.map = map;
  A.cfx = Object.values(cfx)[0];
  A.icons = new Set(Object.keys(icons));
  A.bg = bg;
  await Promise.all([A.boss.load(), map.runey2_159.load(), map.telerune1_171.load(), A.cfx.load()]);
}

// -------------------------------------------------------------------- state
function inSafeBox(p) {
  const s = C.map.safeA;
  return p.x >= s.x && p.x <= s.x + s.w && p.y >= s.y && p.y <= s.y + s.h;
}

function newState() {
  const S0 = {
    fight: null,
    player: { x: C.map.leftPad.x, y: C.map.leftPad.y, dir: 1, moveTo: null, moving: false, aaT: 0, lunge: 0 },
    npc: Object.fromEntries(['ap', 'lr', 'dps'].map((r) => [r, { x: ROLE_OUT[r].x, y: ROLE_OUT[r].y, dir: -1 }])),
    keys: new Set(),
    boss: { anim: 'Idle', t0: 0, loop: false },
    rune: false,
    zoneRole: null,
    fx: [],
    floaters: [],
    banner: null,
    shout: null,
    result: null,
    bossDmg: 0,
    playerDmg: 0,
    wipes: 0,
  };
  S0.fight = new Fight(
    { bossHp: C.fight.bossHp, partyDps: C.fight.partyDps },
    {
      boss: (name, loop = false) => {
        if (S && S.fight && S.fight.over && S.fight.over.result === 'win') return;
        S.boss = { anim: name, t0: S.fight.t / 1000, loop };
      },
      zone: (on, role) => {
        if (!S || !S.fight) return;
        S.rune = on;
        S.zoneRole = on ? role : null;
        if (on) {
          S.banner = {
            text: role === 'loo' ? `EQUAL — zone ${zoneNo(role)}: STAND INSIDE THE BOX` : `EQUAL — ${ROLE_SHORT[role]} inside; you stay OUTSIDE the box`,
            until: S.fight.t + 3400,
            color: role === 'loo' ? '#6fd98a' : '#ffd24a',
          };
        }
      },
      announce: (text) => (S.shout = { text, until: S.fight.t + 3500 }),
      floater: (role, text, kind) => addFloater(role, text, kind),
      log: (msg, cls) => log(msg, cls),
      playerInZone: () => inSafeBox(S.player),
      end: (result, reason) => onEnd(result, reason),
      mechanic: (role, ability, info) => onMechanic(role, ability, info),
      bossDamage: (d, crit, who) => {
        if (who === 'party') S.bossDmg += d;
        else S.playerDmg += d;
        if (who === 'party' && Math.random() < 0.35) bossFloater(d, crit);
      },
      fx: (kind, role) => spawnCastFx(kind, role),
    }
  );
  return S0;
}

function zoneNo(role) {
  return Object.keys(ZONE_ROLES).find((k) => ZONE_ROLES[k] === role);
}

function log(msg, cls = '') {
  const el = $('log');
  const d = document.createElement('div');
  d.className = cls;
  const t = S ? S.fight.t / 1000 : 0;
  d.textContent = `[${t.toFixed(1).padStart(5)}s] ${msg}`;
  el.appendChild(d);
  el.scrollTop = el.scrollHeight;
  while (el.childNodes.length > 120) el.removeChild(el.firstChild);
}

function roleXY(role) {
  if (role === 'loo') return S.player;
  return S.npc[role];
}

function addFloater(role, text, kind) {
  const p = role ? roleXY(role) : { x: C.stage.w / 2, y: 190 };
  const color = { dmg: '#ff6b6b', crit: '#ffb347', heal: '#6fd98a', bad: '#ff5b5b', info: '#fff' }[kind] || '#fff';
  S.floaters.push({ x: p.x + rnd(-16, 16), y: p.y - (role ? 110 : 0), text, color, t: 0, life: 1.4, big: kind === 'crit' || kind === 'bad' });
}

function bossFloater(d, crit) {
  S.floaters.push({ x: C.map.bossPad.x + rnd(-110, 110), y: C.map.bossPad.y - rnd(120, 190), text: fmt(d), color: crit ? '#ffd24a' : '#fff', t: 0, life: 1.0, big: crit, small: true });
}

function spawnCastFx(kind, role) {
  const targets = kind === 'ordinance' || kind === 'heal' ? ROLES : [role];
  for (const r of targets) {
    const p = roleXY(r);
    S.fx.push({ t0: S.fight.t / 1000, role: r, tint: kind });
    void p;
  }
}

function onMechanic(role, ability, info) {
  const f = S.fight;
  let label = '';
  if (ability === 'truth') label = 'Truth';
  else if (ability === 'listen') label = 'Listen';
  if (role && label) {
    S.banner = {
      text: role === 'loo' ? `TAUNT NOW — ${label} on YOU (6)` : `${ROLE_SHORT[role]} holds the boss — ${label}`,
      until: f.t + 2400,
      color: role === 'loo' ? '#ff5b5b' : '#ffd24a',
    };
  }
  if (ability === 'truth') {
    const n = ((info.truthN - 1) % 9) + 1;
    if (n === 5 || n === 9) {
      S.banner = { text: `QUIX NOW — Truth #${n} (5)` + (role === 'loo' ? ' + TAUNT (6)' : ''), until: f.t + 2400, color: '#ff5b5b' };
    }
  }
  if (bot) botReact(role, ability, info);
}

function onEnd(result, reason) {
  S.result = { result, reason };
  const f = S.fight;
  if (result === 'win') {
    S.boss = { anim: 'Die', t0: f.t / 1000, loop: false };
    log(`Victory — ${reason}`, 'good');
  } else {
    S.boss = { anim: 'Idle', t0: f.t / 1000, loop: false };
    log(`Defeat — ${reason}`, 'bad');
  }
  S.rune = false;
}

// ------------------------------------------------------------------- player
function skillByKey(k) {
  return C.loo.find((s) => s.key === k);
}

function moveToBoss() {
  S.player.moveTo = { x: C.map.bossPad.x - 90, y: C.map.bossPad.y + 70 };
}

function castKey(k) {
  const f = S.fight;
  if (f.over) return false;
  if (k === 1) {
    moveToBoss();
    return true;
  }
  const ok = f.cast(k);
  if (ok) S.player.lunge = 0.3;
  return ok;
}

function updatePlayer(dt) {
  const p = S.player;
  const f = S.fight;
  if (f.over) {
    p.moving = false;
    return;
  }
  let vx = 0;
  let vy = 0;
  const k = S.keys;
  if (k.has('a') || k.has('arrowleft')) vx -= 1;
  if (k.has('d') || k.has('arrowright')) vx += 1;
  if (k.has('w') || k.has('arrowup')) vy -= 1;
  if (k.has('s') || k.has('arrowdown')) vy += 1;
  if (vx || vy) {
    p.moveTo = null;
    const l = Math.hypot(vx, vy);
    vx /= l;
    vy /= l;
  } else if (p.moveTo) {
    const dx = p.moveTo.x - p.x;
    const dy = p.moveTo.y - p.y;
    const d = Math.hypot(dx, dy);
    if (d < 4) p.moveTo = null;
    else {
      vx = dx / d;
      vy = dy / d;
    }
  }
  p.moving = !!(vx || vy);
  if (p.moving) {
    const step = C.player.speed * dt;
    const lim = p.moveTo ? Math.min(step, Math.hypot(p.moveTo.x - p.x, p.moveTo.y - p.y)) : step;
    p.x = clamp(p.x + vx * lim, C.walk.x0, C.walk.x1);
    p.y = clamp(p.y + vy * lim, C.walk.y0, C.walk.y1);
    if (vx) p.dir = vx > 0 ? 1 : -1;
  }
  p.lunge = Math.max(0, p.lunge - dt);
  // skill 1: auto attack while in range and not stasis-locked
  p.aaT -= dt;
  const b = C.map.bossPad;
  const inRange = Math.abs(b.x - p.x) <= C.player.attackRangeX && Math.abs(b.y - p.y) <= C.player.attackRangeY;
  if (!p.moving && !f.stunned() && inRange && p.aaT <= 0) {
    p.aaT = C.player.autoEvery;
    p.dir = b.x >= p.x ? 1 : -1;
    p.lunge = 0.3;
    const d = Math.floor(rnd(C.player.autoDamage[0], C.player.autoDamage[1] + 1));
    f.playerHit(d, d > C.player.autoCritAbove);
    if (Math.random() < 0.5) bossFloater(d, d > C.player.autoCritAbove);
  }
}

function updateNpcs(dt) {
  for (const r of ['ap', 'lr', 'dps']) {
    const n = S.npc[r];
    const goal = S.zoneRole === r ? ZONE_IN : ROLE_OUT[r];
    const dx = goal.x - n.x;
    const dy = goal.y - n.y;
    const d = Math.hypot(dx, dy);
    if (d > 2) {
      const st = Math.min(d, 300 * dt);
      n.x += (dx / d) * st;
      n.y += (dy / d) * st;
      n.dir = dx >= 0 ? 1 : -1;
      n.moving = true;
    } else n.moving = false;
  }
}

// ---------------------------------------------------------------- auto-pilot
let botTauntAt = null; // human-like reaction delay, ms of fight time
let botQuixAt = null;

function botReact(role, ability, info) {
  const at = S.fight.t + 350;
  if (role === 'loo') botTauntAt = at;
  if (ability === 'truth') {
    const n = ((info.truthN - 1) % 9) + 1;
    if (n === 5 || n === 9) botQuixAt = at;
  }
}

function runBot() {
  const f = S.fight;
  const p = S.player;
  if (!bot || f.over) return;
  // positioning
  let goal = null;
  if (S.zoneRole) {
    const wantIn = S.zoneRole === 'loo';
    const inside = inSafeBox(p);
    if (wantIn && !inside) goal = { x: ZONE_IN.x, y: ZONE_IN.y };
    else if (!wantIn && inside) goal = { x: 120, y: 420 };
    else goal = p.moveTo || null; // hold
    if (wantIn === inside) goal = null;
  } else if (!p.moveTo && (Math.abs(C.map.bossPad.x - p.x) > C.player.attackRangeX - 40 || Math.abs(C.map.bossPad.y - p.y) > C.player.attackRangeY - 20)) {
    goal = { x: C.map.bossPad.x - 90, y: C.map.bossPad.y + 70 };
  }
  if (goal) p.moveTo = goal;
  // skills
  if (botTauntAt !== null && f.t > botTauntAt + 1400) botTauntAt = null; // too late to matter
  if (botTauntAt !== null && f.t >= botTauntAt && f.cast(6)) botTauntAt = null;
  if (botQuixAt !== null && f.t > botQuixAt + 1400) botQuixAt = null;
  if (botQuixAt !== null && f.t >= botQuixAt && f.cast(5)) botQuixAt = null;
  if (f.hp.loo < f.maxHp('loo') * 0.8 || ROLES.some((r) => f.hp[r] < f.maxHp(r) * 0.65)) f.cast(3);
  f.cast(2);
  f.cast(4);
}

// -------------------------------------------------------------------- render
function bossFrame() {
  const [a, z] = BOSS_ANIMS[S.boss.anim];
  const n = z - a + 1;
  let i = Math.floor((S.fight.t / 1000 - S.boss.t0) * C.fps);
  i = S.boss.loop ? i % n : Math.min(i, n - 1);
  return a - 1 + i;
}

function bar(x, y, w, h, frac, c1, c2) {
  ctx.fillStyle = '#10131c';
  ctx.fillRect(x, y, w, h);
  const g = ctx.createLinearGradient(0, y, 0, y + h);
  g.addColorStop(0, c1);
  g.addColorStop(1, c2);
  ctx.fillStyle = g;
  ctx.fillRect(x, y, Math.max(0, w * clamp(frac, 0, 1)), h);
  ctx.strokeStyle = 'rgba(255,255,255,.35)';
  ctx.lineWidth = 1;
  ctx.strokeRect(x + 0.5, y + 0.5, w - 1, h - 1);
}

function text(str, x, y, { size = 12, color = '#fff', align = 'left', bold = false } = {}) {
  ctx.font = `${bold ? '700 ' : ''}${size}px system-ui, sans-serif`;
  ctx.textAlign = align;
  ctx.lineWidth = 3;
  ctx.strokeStyle = 'rgba(0,0,0,.8)';
  ctx.strokeText(str, x, y);
  ctx.fillStyle = color;
  ctx.fillText(str, x, y);
}

function drawToken(role, p, moving, dead) {
  const t = S.fight.t / 1000;
  const bob = moving ? Math.sin(t * 16 + role.length) * 3 : Math.sin(t * 2.5) * 1;
  const col = ROLE_COLOR[role];
  ctx.save();
  ctx.translate(p.x, p.y);
  ctx.fillStyle = 'rgba(0,0,0,.35)';
  ctx.beginPath();
  ctx.ellipse(0, 0, 28, 8, 0, 0, Math.PI * 2);
  ctx.fill();
  ctx.scale(p.dir || 1, 1);
  if (dead) ctx.rotate(-Math.PI / 2.2);
  ctx.translate((p.lunge || 0) > 0 ? Math.sin((p.lunge / 0.3) * Math.PI) * 10 : 0, -bob);
  ctx.fillStyle = col;
  ctx.globalAlpha = 0.55;
  ctx.beginPath();
  ctx.moveTo(-10, -76);
  ctx.quadraticCurveTo(-32, -40, -16, -4);
  ctx.lineTo(-4, -8);
  ctx.closePath();
  ctx.fill();
  ctx.globalAlpha = 1;
  const leg = moving ? Math.sin(t * 16) * 8 : 0;
  ctx.strokeStyle = '#2d3a55';
  ctx.lineWidth = 9;
  ctx.lineCap = 'round';
  ctx.beginPath();
  ctx.moveTo(-5, -34); ctx.lineTo(-6 + leg, -3);
  ctx.moveTo(6, -34); ctx.lineTo(7 - leg, -3);
  ctx.stroke();
  ctx.fillStyle = col;
  ctx.beginPath();
  ctx.roundRect(-14, -80, 28, 50, 8);
  ctx.fill();
  ctx.fillStyle = 'rgba(0,0,0,.25)';
  ctx.fillRect(-14, -50, 28, 5);
  ctx.fillStyle = '#f0c9a0';
  ctx.beginPath();
  ctx.arc(0, -94, 13, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = '#3b2a1c';
  ctx.beginPath();
  ctx.arc(-1, -99, 13, Math.PI, Math.PI * 2);
  ctx.fill();
  ctx.restore();
}

function drawOverlays() {
  const m = A.map;
  if (!S.rune) return;
  const t = S.fight.t / 1000;
  const r = C.map.rune1;
  ctx.save();
  ctx.globalAlpha = 0.78 + 0.22 * Math.sin(t * 7);
  m.runey2_159.draw(ctx, 1, r.x, r.y, r.sx, r.sy);
  ctx.restore();
  const s = C.map.safe1;
  const i = 1 + (Math.floor(t * C.fps) % (m.telerune1_171.count - 1));
  ctx.save();
  ctx.globalAlpha = 0.9;
  m.telerune1_171.draw(ctx, i, s.x, s.y, s.sx, s.sy);
  ctx.restore();
}

function drawHud() {
  const f = S.fight;
  const bw = 320;
  const bx = (C.stage.w - bw) / 2 + 60;
  ctx.fillStyle = 'rgba(8,10,18,.72)';
  ctx.beginPath();
  ctx.roundRect(bx - 8, 6, bw + 16, 50, 8);
  ctx.fill();
  text(C.boss.name, bx, 24, { size: 14, bold: true });
  text(`Lvl ${C.boss.level}`, bx + bw, 24, { size: 12, align: 'right', color: '#ffd24a' });
  const frac = f.bossHp / C.fight.bossHp;
  bar(bx, 31, bw, 16, frac, '#ff5b5b', '#a01626');
  text(`${fmt(f.bossHp)}  (${(frac * 100).toFixed(1)}%)`, bx + bw / 2, 44, { size: 11, align: 'center', bold: true });

  // party frames
  const order = ['loo', 'ap', 'lr', 'dps'];
  ctx.fillStyle = 'rgba(8,10,18,.72)';
  ctx.beginPath();
  ctx.roundRect(6, 6, 218, 118, 8);
  ctx.fill();
  order.forEach((r, i) => {
    const y = 14 + i * 28;
    const hp = f.hp[r];
    const mx = f.maxHp(r);
    text(`${ROLE_SHORT[r]}${r === 'loo' ? ' (you)' : ''}`, 14, y + 8, { size: 11, bold: true, color: ROLE_COLOR[r] });
    const sm = f.somber[r];
    if (sm > 0) text(`Somber ×${sm}`, 214, y + 8, { size: 10, align: 'right', color: '#c58bff' });
    bar(14, y + 11, 200, 12, hp / mx, '#6fe08a', '#1d8a3a');
    text(`${fmt(hp)} / ${fmt(mx)}`, 114, y + 21, { size: 10, align: 'center', bold: true });
  });

  // buffs
  const chips = [];
  const now = f.t;
  const leftS = (u) => Math.max(0, (u - now) / 1000);
  if (f.currentTaunt()) chips.push([`Taunt: ${ROLE_SHORT[f.currentTaunt()]} ${leftS(f.taunt.until).toFixed(1)}s`, '#e0b84a']);
  if (now < f.ordinanceUntil) chips.push([`Ordinance ${leftS(f.ordinanceUntil).toFixed(0)}s`, '#6aa7ff']);
  if (f.hpBuff.harmony) chips.push([`Harmony ${leftS(f.harmonyUntil).toFixed(0)}s`, '#6fd98a']);
  if (now < f.axiomUntil) chips.push([`Axiom ${leftS(f.axiomUntil).toFixed(0)}s`, '#c58bff']);
  if (now < f.quixUntil) chips.push([`Quix ${leftS(f.quixUntil).toFixed(1)}s`, '#ffd24a']);
  if (f.ap.reduction) chips.push([`AP ${f.ap.reduction === 'seal' ? 'Seal' : 'Eden'}`, '#e8d9a0']);
  if (f.stunned()) chips.push([`STASIS ${leftS(f.stunUntil).toFixed(1)}s`, '#ff5b5b']);
  chips.forEach(([label, color], i) => {
    const y = 134 + i * 20;
    ctx.fillStyle = 'rgba(8,10,18,.72)';
    ctx.fillRect(6, y, 128, 17);
    ctx.fillStyle = color;
    ctx.fillRect(6, y, 4, 17);
    text(label, 16, y + 13, { size: 11 });
  });

  text(fmtTime(f.t / 1000), C.stage.w - 12, 22, { size: 14, align: 'right', bold: true });
  const nxt = PATTERN[f.rot.idx];
  text(`Next: ${nxt}`, C.stage.w - 12, 40, { size: 11, align: 'right', color: '#8a95ab' });

  if (S.banner && f.t < S.banner.until) text(S.banner.text, C.stage.w / 2 + 60, 84, { size: 16, align: 'center', bold: true, color: S.banner.color });
  if (S.shout && f.t < S.shout.until) text(`"${S.shout.text}"`, C.stage.w / 2 + 60, 106, { size: 13, align: 'center', color: '#e9e2ff' });

  if (f.over) {
    ctx.fillStyle = 'rgba(0,0,0,.5)';
    ctx.fillRect(0, 170, C.stage.w, 130);
    const win = f.over.result === 'win';
    text(win ? 'VICTORY' : 'DEFEATED', C.stage.w / 2, 225, { size: 44, align: 'center', bold: true, color: win ? '#6fd98a' : '#ff5b5b' });
    text(`${f.over.reason} · ${fmtTime(f.t / 1000)} · press Restart`, C.stage.w / 2, 262, { size: 15, align: 'center' });
  }
}

function fmtTime(t) {
  return `${Math.floor(t / 60)}:${String(Math.floor(t % 60)).padStart(2, '0')}`;
}

function render() {
  const f = S.fight;
  ctx.clearRect(0, 0, C.stage.w, C.stage.h);
  ctx.drawImage(A.bg, 0, 0);
  drawOverlays();

  const b = C.map.bossPad;
  const dead = (r) => f.hp[r] <= 0;
  const ents = [
    {
      y: b.y,
      draw: () => {
        ctx.fillStyle = 'rgba(0,0,0,.38)';
        ctx.beginPath();
        ctx.ellipse(b.x, b.y + 4, 150, 22, 0, 0, Math.PI * 2);
        ctx.fill();
        const bob = f.over && f.over.result === 'win' ? 0 : Math.sin(f.t / 1000 * 2.2) * 4;
        A.boss.draw(ctx, bossFrame(), b.x, b.y + bob, C.boss.displayScale, C.boss.displayScale);
      },
    },
    { y: S.player.y, draw: () => drawToken('loo', S.player, S.player.moving, dead('loo')) },
    ...['ap', 'lr', 'dps'].map((r) => ({ y: S.npc[r].y, draw: () => drawToken(r, S.npc[r], S.npc[r].moving, dead(r)) })),
  ].sort((a, c) => a.y - c.y);
  ents.forEach((e) => e.draw());

  // cast effects (Symbol3aaaaa_loo_757 sparkle from Assets_20260731.swf)
  const t = f.t / 1000;
  S.fx = S.fx.filter((x) => (t - x.t0) * C.fps < A.cfx.count);
  for (const x of S.fx) {
    const p = roleXY(x.role);
    const s = 1 / A.cfx.zoom;
    A.cfx.draw(ctx, Math.floor((t - x.t0) * C.fps), p.x, p.y - 50, s, s);
  }

  // name tags
  for (const r of ROLES) {
    const p = roleXY(r);
    bar(p.x - 28, p.y - 124, 56, 6, f.hp[r] / f.maxHp(r), '#6fe08a', '#1d8a3a');
    text(ROLE_SHORT[r], p.x, p.y - 128, { size: 11, align: 'center', bold: true, color: ROLE_COLOR[r] });
  }
  if (f.currentTaunt()) {
    const p = roleXY(f.currentTaunt());
    text('TAUNT', p.x, p.y - 142, { size: 10, align: 'center', bold: true, color: '#ffd24a' });
  }

  for (const fl of S.floaters) {
    const k = fl.t / fl.life;
    ctx.save();
    ctx.globalAlpha = 1 - k * k;
    text(fl.text, fl.x, fl.y - 50 * k, { size: fl.small ? (fl.big ? 18 : 14) : fl.big ? 22 : 15, align: 'center', bold: true, color: fl.color });
    ctx.restore();
  }
  drawHud();
}

// ------------------------------------------------------------------------ UI
function buildSkillbar() {
  const bar = $('skillbar');
  bar.innerHTML = '';
  for (const s of C.loo) {
    const b = document.createElement('button');
    b.className = 'slot';
    const icon = s.icon && A.icons.has(s.icon) ? `<img src="assets/icons/${s.icon}.webp" alt="">` : `<span class="lbl">${s.name}</span>`;
    b.innerHTML = `${icon}<span class="key">${s.key}</span><span class="cd"></span><span class="cdt"></span>${s.icon ? `<span class="name">${s.name}</span>` : ''}`;
    b.title = `${s.name} — ${s.tip}`;
    b.addEventListener('click', () => castKey(s.key));
    bar.appendChild(b);
  }
  if (A.icons.has(C.passiveIcon)) {
    const p = document.createElement('div');
    p.className = 'slot';
    p.style.cursor = 'default';
    p.title = 'Passive';
    p.innerHTML = `<img src="assets/icons/${C.passiveIcon}.webp" alt=""><span class="name">Passive</span>`;
    bar.appendChild(p);
  }
}

const CD_IDX = { harmony: 2, ordinance: 3, axiom: 4, quix: 5, taunt: 6 };
const CD_LEN = { 2: LOO.harmony.cd, 3: LOO.ordinance.cd, 4: LOO.axiom.cd, 5: LOO.quix.cd, 6: LOO.taunt.cd };

function updateSkillbar() {
  const f = S.fight;
  const nodes = $('skillbar').children;
  C.loo.forEach((s, i) => {
    const n = nodes[i];
    if (s.key === 1) {
      n.classList.toggle('off', f.stunned());
      return;
    }
    const left = Math.max(0, f.cd[s.key] - f.t);
    n.querySelector('.cd').style.height = `${clamp(left / Math.max(CD_LEN[s.key], 1), 0, 1) * 100}%`;
    n.querySelector('.cdt').textContent = left > 50 ? (left / 1000).toFixed(left > 9950 ? 0 : 1) : '';
    n.classList.toggle('off', f.stunned());
  });
}

function updatePanels() {
  const f = S.fight;
  const rows = [];
  for (let k = 0; k < 7; k++) {
    let idx = f.rot.idx + k;
    if (idx >= PATTERN.length) idx = 6 + ((idx - PATTERN.length) % (PATTERN.length - 6));
    const ab = PATTERN[idx];
    const mech = MECHANICS[idx];
    rows.push(`<div class="${k === 0 ? 'cur' : ''}">${ab.toUpperCase()}${mech ? ` <span style="color:var(--dim)">→ ${ROLE_SHORT[mech]} tanks</span>` : ''}</div>`);
  }
  $('rot').innerHTML = rows.join('');
  const c = f.counters;
  $('stats').innerHTML = [
    ['Seal misses', c.seal],
    ['Quix misses', c.quix],
    ['Seal not broken', c.notBroken],
    ['Harmony drops', c.harmony],
    ['Ordinance drops', c.ordinance],
    ['Axiom drops', c.axiom],
    ['Raid damage dealt', fmt(S.bossDmg)],
    ['Your damage', fmt(S.playerDmg)],
  ].map(([a, b]) => `<div><span>${a}</span><b>${b}</b></div>`).join('');
}

function restart() {
  const keys = S ? S.keys : new Set();
  S = newState();
  S.keys = keys;
  botTauntAt = botQuixAt = null;
  $('log').innerHTML = '';
  log('Engaged Ultra Speaker');
}

// --------------------------------------------------------------------- input
function toStage(ev) {
  const r = canvas.getBoundingClientRect();
  return { x: ((ev.clientX - r.left) / r.width) * C.stage.w, y: ((ev.clientY - r.top) / r.height) * C.stage.h };
}
canvas.addEventListener('mousedown', (ev) => {
  if (S.fight.over) return;
  const { x, y } = toStage(ev);
  S.player.moveTo = { x: clamp(x, C.walk.x0, C.walk.x1), y: clamp(y, C.walk.y0, C.walk.y1) };
});
const MOVE_KEYS = new Set(['w', 'a', 's', 'd', 'arrowup', 'arrowdown', 'arrowleft', 'arrowright']);
window.addEventListener('keydown', (ev) => {
  if (ev.target.tagName === 'SELECT') return;
  const k = ev.key.toLowerCase();
  if (MOVE_KEYS.has(k)) {
    S.keys.add(k);
    ev.preventDefault();
  } else if (k >= '1' && k <= '6') castKey(parseInt(k, 10));
  else if (k === 'p') $('btnPause').click();
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

// ---------------------------------------------------------------------- loop
let last = performance.now();
function frame(now) {
  const dt = Math.min((now - last) / 1000, 0.1);
  last = now;
  if (!paused) {
    const sdt = dt * speed;
    // sub-step so fast-forwarded timers stay accurate
    const steps = Math.max(1, Math.ceil(sdt / 0.05));
    for (let i = 0; i < steps; i++) {
      S.fight.step((sdt / steps) * 1000);
      runBot();
      updatePlayer(sdt / steps);
      updateNpcs(sdt / steps);
    }
    S.floaters.forEach((fl) => (fl.t += sdt));
    S.floaters = S.floaters.filter((fl) => fl.t < fl.life);
    const f = S.fight;
    if (f.over && f.over.result === 'win' && S.boss.anim === 'Die' && f.t / 1000 - S.boss.t0 >= 3.1) S.boss = { anim: 'Dead', t0: f.t / 1000, loop: true };
  }
  updateSkillbar();
  render();
  requestAnimationFrame(frame);
}

async function main() {
  await loadAssets();
  restart();
  buildSkillbar();
  if (params.get('speed')) {
    speed = parseFloat(params.get('speed'));
    $('selSpeed').value = String(speed);
  }
  if (params.get('bot')) {
    bot = true;
    $('chkBot').checked = true;
  }
  $('loading').style.display = 'none';
  setInterval(updatePanels, 250);
  requestAnimationFrame((t) => {
    last = t;
    frame(t);
  });
  window.__sim = { get S() { return S; }, castKey, C, restart };
}

main().catch((e) => {
  $('loading').textContent = 'Failed to load: ' + e.message;
  console.error(e);
});

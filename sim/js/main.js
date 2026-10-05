import { CONFIG as C } from './config.js';
import { loadAtlas, loadImage } from './sprites.js';
import { Fight, PATTERN, MECHANICS, ZONE_ROLES, ROLES, CLASS_SKILLS, SKILL_CD, LOO } from './fight.js';

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

// _assets/assets.swf mcSkel (the skeleton AvatarMC wraps), label -> [first, last] frame
const NPC_ANIMS = {
  Idle: [8, 16], Walk: [54, 68], Fight: [622, 633], Attack: [703, 722], Castgood: [911, 931],
  Cast: [932, 958], Hit: [810, 827], Knockout: [828, 849], Dead: [495, 502],
};
// the equipped player carries a rifle: RifleFight / RifleAttack instead of the melee poses
const PLAYER_ANIMS = { ...NPC_ANIMS, Fight: [1783, 1795], Attack: [679, 702] };
const CHAR_SCALE = 1; // exported at 0.65 zoom already matches the stage size

const ROLE_COLOR = { ap: '#e8d9a0', lr: '#e0507a', loo: '#e0b84a', dps: '#5aa86a' };
const ROLE_SHORT = { ap: 'AP', lr: 'LR', loo: 'LoO', dps: 'DPS' };

// Standing spots. With no zone everybody gathers in the middle around the boss; during an
// Equal zone only the named role stays in, the rest step out to the sides.
// Everybody stacks on one spot in the middle (tiny offsets only so the pile stays readable);
// when the zone belongs to someone else the rest stack up on the right, outside the box.
const MIDDLE_AT = { x: 470, y: 420 };
const RIGHT_AT = { x: 868, y: 410 };
const STACK = { ap: [-6, -2], lr: [6, -1], dps: [-2, 2], loo: [2, 0] };
const spot = (base, r) => ({ x: base.x + STACK[r][0], y: base.y + STACK[r][1] });
const MIDDLE = Object.fromEntries(['ap', 'lr', 'dps', 'loo'].map((r) => [r, spot(MIDDLE_AT, r)]));
const OUTSIDE = Object.fromEntries(['ap', 'lr', 'dps', 'loo'].map((r) => [r, spot(RIGHT_AT, r)]));
const ZONE_IN = MIDDLE_AT;

const A = {};
let S;
let playerRole = params.get('class') && C.classes[params.get('class')] ? params.get('class') : 'loo';
let paused = false;
let speed = 1;
let bot = false;
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const fmt = (n) => Math.round(n).toLocaleString('en-US');
const rnd = (a, b) => a + Math.random() * (b - a);
const classDef = () => C.classes[playerRole];

// ------------------------------------------------------------------- assets
async function loadAssets() {
  const [boss, map, cfx, chars, player, icons, bg] = await Promise.all([
    loadAtlas('assets/boss'),
    loadAtlas('assets/map'),
    loadAtlas('assets/classfx'),
    loadAtlas('assets/chars'),
    loadAtlas('assets/player'),
    fetch('assets/icons/atlas.json').then((r) => r.json()),
    loadImage('assets/map/bg.jpg'),
  ]);
  A.boss = boss.UltraMalg;
  A.map = map;
  A.cfx = Object.values(cfx)[0];
  A.char = Object.values(chars)[0];
  A.player = Object.values(player)[0];
  A.icons = new Set(Object.keys(icons));
  A.bg = bg;
  await Promise.all([A.boss.load(), map.runey2_159.load(), map.telerune1_171.load(), A.cfx.load(), A.char.load(), A.player.load()]);
  // lowest visible pixel of the idle pose relative to the sprite origin -> puts the feet on y
  const d = A.char.data;
  A.charFoot = Math.max(...d.nums.map((n, i) => (n >= 8 && n <= 16 && d.frames[i] !== null ? d.rects[d.frames[i]][6] + d.rects[d.frames[i]][4] : -1e9)));
}

// -------------------------------------------------------------------- state
function inSafeBox(p) {
  const s = C.map.safeA;
  return p.x >= s.x && p.x <= s.x + s.w && p.y >= s.y && p.y <= s.y + s.h;
}

function newState() {
  const S0 = {
    fight: null,
    chars: Object.fromEntries(
      ROLES.map((r) => [r, { x: MIDDLE[r].x, y: MIDDLE[r].y, dir: 1, moving: false, anim: 'Idle', t0: 0, hold: 0, moveTo: null, aaT: rnd(0, 1.3) }])
    ),
    boss: { anim: 'Idle', t0: 0, loop: false },
    rune: false,
    zoneRole: null,
    fx: [],
    floaters: [],
    banner: null,
    shout: null,
    bossDmg: 0,
    playerDmg: 0,
    target: true,
  };
  S0.fight = new Fight(
    { bossHp: C.fight.bossHp, partyDps: C.fight.partyDps },
    {
      boss: (name, loop = false) => {
        if (S && S.fight && S.fight.over && S.fight.over.result === 'win') return;
        if (S && S.fight) S.boss = { anim: name, t0: S.fight.t / 1000, loop };
      },
      zone: (on, role) => {
        if (!S || !S.fight) return;
        S.rune = on;
        S.zoneRole = on ? role : null;
        if (on) {
          const mine = role === playerRole;
          S.banner = {
            text: mine ? `EQUAL — zone ${zoneNo(role)}: STAND INSIDE THE BOX` : `EQUAL — ${ROLE_SHORT[role]} inside; step OUTSIDE the box`,
            until: S.fight.t + 3400,
            color: mine ? '#6fd98a' : '#ffd24a',
          };
        }
      },
      announce: (text) => S && S.fight && (S.shout = { text, until: S.fight.t + 3500 }),
      floater: (role, text, kind) => addFloater(role, text, kind),
      log: (msg, cls) => log(msg, cls),
      playerInZone: () => inSafeBox(S.chars[playerRole]),
      playerCentered: () => {
        const x = S.chars[playerRole].x;
        return x >= 166 && x <= 812;
      },
      end: (result, reason) => onEnd(result, reason),
      mechanic: (role, ability, info) => onMechanic(role, ability, info),
      bossDamage: (d, crit, who) => {
        if (who === 'party') S.bossDmg += d;
        else S.playerDmg += d;
        if (who === 'party' && Math.random() < 0.35) bossFloater(d, crit);
      },
      fx: (kind, role) => spawnCastFx(kind, role),
    },
    playerRole
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
  const t = S && S.fight ? S.fight.t / 1000 : 0;
  d.textContent = `[${t.toFixed(1).padStart(5)}s] ${msg}`;
  el.appendChild(d);
  el.scrollTop = el.scrollHeight;
  while (el.childNodes.length > 120) el.removeChild(el.firstChild);
}

function addFloater(role, text, kind) {
  if (!S) return;
  const p = role ? S.chars[role] : { x: C.stage.w / 2, y: 190 };
  const color = { dmg: '#ff6b6b', crit: '#ffb347', heal: '#6fd98a', bad: '#ff5b5b', info: '#fff' }[kind] || '#fff';
  S.floaters.push({ x: p.x + rnd(-16, 16), y: p.y - (role ? 120 : 0), text, color, t: 0, life: 1.4, big: kind === 'crit' || kind === 'bad' });
}

function bossFloater(d, crit) {
  S.floaters.push({ x: C.map.bossPad.x + rnd(-110, 110), y: C.map.bossPad.y - rnd(120, 190), text: fmt(d), color: crit ? '#ffd24a' : '#fff', t: 0, life: 1.0, big: crit, small: true });
}

function playAnim(role, name, ms) {
  const c = S.chars[role];
  c.anim = name;
  c.t0 = S.fight.t / 1000;
  c.hold = ms / 1000;
}

function spawnCastFx(kind, role) {
  const targets = kind === 'ordinance' || kind === 'heal' ? ROLES : [role];
  const t = S.fight.t / 1000;
  for (const r of targets) S.fx.push({ t0: t, role: r });
  if (!['taunt'].includes(kind)) playAnim(role, 'Cast', 700);
}

function onMechanic(role, ability, info) {
  const f = S.fight;
  const label = ability === 'truth' ? 'Truth' : ability === 'listen' ? 'Listen' : '';
  const mine = role === playerRole;
  if (role && label) {
    S.banner = {
      text: mine ? `TAUNT NOW — ${label} on YOU (6)` : `${ROLE_SHORT[role]} holds the boss — ${label}`,
      until: f.t + 2400,
      color: mine ? '#ff5b5b' : '#ffd24a',
    };
  }
  if (ability === 'truth') {
    const n = ((info.truthN - 1) % 9) + 1;
    const needSeal = (info.truthN >= 1 && info.truthN <= 3) || (info.truthN >= 5 && info.truthN <= 7);
    if (playerRole === 'loo' && (n === 5 || n === 9)) {
      S.banner = { text: `QUIX NOW — Truth #${n} (5)` + (mine ? ' + TAUNT (6)' : ''), until: f.t + 2400, color: '#ff5b5b' };
    } else if (playerRole === 'ap' && needSeal) {
      S.banner = { text: `SEAL NOW (4) — Truth #${info.truthN}` + (mine ? ' + TAUNT (6)' : ''), until: f.t + 2400, color: '#ff5b5b' };
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

// ------------------------------------------------------------------- movement
function moveToBoss() {
  S.target = true;
  S.chars[playerRole].moveTo = { x: C.map.bossPad.x - 90, y: C.map.bossPad.y + 70 };
}

function castKey(k) {
  const f = S.fight;
  if (f.over) return false;
  if (k === 1) {
    moveToBoss();
    return true;
  }
  const ok = f.cast(k);
  if (ok) S.chars[playerRole].aaT = Math.max(S.chars[playerRole].aaT, 0.4);
  return ok;
}

function stepChar(c, goal, dt, speedPx) {
  if (!goal) {
    c.moving = false;
    return;
  }
  const dx = goal.x - c.x;
  const dy = goal.y - c.y;
  const d = Math.hypot(dx, dy);
  if (d < 3) {
    c.moving = false;
    if (c.moveTo === goal) c.moveTo = null;
    return;
  }
  const st = Math.min(d, speedPx * dt);
  c.x += (dx / d) * st;
  c.y += (dy / d) * st;
  if (Math.abs(dx) > 1) c.dir = dx > 0 ? 1 : -1;
  c.moving = true;
}

function updateChars(dt) {
  const f = S.fight;
  const b = C.map.bossPad;
  for (const r of ROLES) {
    const c = S.chars[r];
    if (f.hp[r] <= 0) {
      c.moving = false;
      continue;
    }
    const isMe = r === playerRole;
    if (isMe) {
      // mouse-click movement only
      if (!f.over) stepChar(c, c.moveTo, dt, C.player.speed);
    } else {
      const goal = S.zoneRole ? (S.zoneRole === r ? ZONE_IN : OUTSIDE[r]) : MIDDLE[r];
      stepChar(c, goal, dt, 300);
    }
    // everyone swings at the boss when standing still near it
    c.aaT -= dt;
    const inRange = Math.abs(b.x - c.x) <= C.player.attackRangeX && Math.abs(b.y - c.y) <= C.player.attackRangeY;
    if (!c.moving && inRange && c.aaT <= 0 && !f.over && (!isMe || S.target)) {
      c.aaT = C.player.autoEvery;
      c.dir = b.x >= c.x ? 1 : -1;
      playAnim(r, 'Attack', 700);
      if (isMe && S.target && !f.stunned()) {
        const d = Math.floor(rnd(C.player.autoDamage[0], C.player.autoDamage[1] + 1));
        f.playerHit(d, d > C.player.autoCritAbove);
        if (Math.random() < 0.5) bossFloater(d, d > C.player.autoCritAbove);
      }
    }
  }
}

// ---------------------------------------------------------------- auto-pilot
const bq = []; // [{at, until, fn}] reactions queued with a human-like delay

function botReact(role, ability, info) {
  const f = S.fight;
  const at = f.t + 350;
  const queue = (fn) => bq.push({ at, until: at + 1400, fn });
  if (role === playerRole) queue(() => f.cast(6));
  if (ability === 'truth') {
    const n = ((info.truthN - 1) % 9) + 1;
    if (playerRole === 'loo' && (n === 5 || n === 9)) queue(() => f.cast(5));
    if (playerRole === 'ap' && ((info.truthN >= 1 && info.truthN <= 3) || (info.truthN >= 5 && info.truthN <= 7))) {
      queue(() => f.cast(4));
      bq.push({ at: f.t + 5000, until: f.t + 6500, fn: () => f.cast(5) });
    }
  }
}

function runBot() {
  const f = S.fight;
  const c = S.chars[playerRole];
  if (!bot || f.over) return;
  for (let i = bq.length - 1; i >= 0; i--) {
    const q = bq[i];
    if (f.t > q.until) bq.splice(i, 1);
    else if (f.t >= q.at && q.fn()) bq.splice(i, 1);
  }
  // positioning: follow the arena rules (the click-to-move the player would do)
  if (S.zoneRole) {
    const wantIn = S.zoneRole === playerRole;
    if (wantIn !== inSafeBox(c)) c.moveTo = wantIn ? { ...ZONE_IN } : { ...OUTSIDE[playerRole] };

  } else if (!c.moveTo && Math.hypot(c.x - MIDDLE[playerRole].x, c.y - MIDDLE[playerRole].y) > 20) {
    c.moveTo = { ...MIDDLE[playerRole] };
  }
  const low = ROLES.some((r) => f.hp[r] < f.maxHp(r) * 0.65) || (S.zoneRole === playerRole && f.hp[playerRole] < 3400);
  if (playerRole === 'loo') {
    if (low) f.cast(3);
    f.cast(2);
    f.cast(4);
  } else if (playerRole === 'ap') {
    if (low) f.cast(3);
    f.cast(2);
  } else if (playerRole === 'lr') {
    f.cast(4);
    f.cast(5);
    f.cast(3);
  }
}

// -------------------------------------------------------------------- render
function bossFrame() {
  const [a, z] = BOSS_ANIMS[S.boss.anim];
  const n = z - a + 1;
  let i = Math.floor((S.fight.t / 1000 - S.boss.t0) * C.fps);
  i = S.boss.loop ? i % n : Math.min(i, n - 1);
  return a - 1 + i;
}

function charFrame(r) {
  const c = S.chars[r];
  const t = S.fight.t / 1000;
  const dead = S.fight.hp[r] <= 0;
  let name;
  if (dead) name = 'Dead';
  else if (c.hold > 0 && t - c.t0 < c.hold) name = c.anim;
  else if (c.moving) name = 'Walk';
  else if (r === playerRole && S.target && Math.abs(C.map.bossPad.x - c.x) <= C.player.attackRangeX && Math.abs(C.map.bossPad.y - c.y) <= C.player.attackRangeY) name = 'Fight';
  else name = 'Idle';
  const anims = r === playerRole ? PLAYER_ANIMS : NPC_ANIMS;
  const [a, z] = anims[name];
  const n = z - a + 1;
  const start = name === c.anim && c.hold > 0 && t - c.t0 < c.hold ? c.t0 : 0;
  let i = Math.floor((t - start) * C.fps);
  i = name === 'Dead' ? Math.min(i, n - 1) : i % n;
  return a + i; // source frame number
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

function drawChar(r) {
  const c = S.chars[r];
  const num = charFrame(r);
  const atlas = r === playerRole ? A.player : A.char;
  const idx = atlas.data.nums.indexOf(num);
  ctx.fillStyle = 'rgba(0,0,0,.35)';
  ctx.beginPath();
  ctx.ellipse(c.x, c.y, 28, 8, 0, 0, Math.PI * 2);
  ctx.fill();
  // ring in the role colour so the identical silhouettes can be told apart
  ctx.strokeStyle = ROLE_COLOR[r];
  ctx.globalAlpha = r === playerRole ? 0.95 : 0.6;
  ctx.lineWidth = r === playerRole ? 3 : 2;
  ctx.beginPath();
  ctx.ellipse(c.x, c.y, 24, 7, 0, 0, Math.PI * 2);
  ctx.stroke();
  ctx.globalAlpha = 1;
  atlas.draw(ctx, idx, c.x, c.y - A.charFoot * CHAR_SCALE, CHAR_SCALE * c.dir, CHAR_SCALE);
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

  const order = [playerRole, ...['ap', 'lr', 'loo', 'dps'].filter((r) => r !== playerRole)];
  ctx.fillStyle = 'rgba(8,10,18,.72)';
  ctx.beginPath();
  ctx.roundRect(6, 6, 218, 118, 8);
  ctx.fill();
  order.forEach((r, i) => {
    const y = 14 + i * 28;
    text(`${ROLE_SHORT[r]}${r === playerRole ? ' (you)' : ''}`, 14, y + 8, { size: 11, bold: true, color: ROLE_COLOR[r] });
    if (f.somber[r] > 0) text(`Somber ×${f.somber[r]}`, 214, y + 8, { size: 10, align: 'right', color: '#c58bff' });
    bar(14, y + 11, 200, 12, f.hp[r] / f.maxHp(r), '#6fe08a', '#1d8a3a');
    text(`${fmt(f.hp[r])} / ${fmt(f.maxHp(r))}`, 114, y + 21, { size: 10, align: 'center', bold: true });
  });

  const chips = [];
  const now = f.t;
  const leftS = (u) => Math.max(0, (u - now) / 1000);
  if (f.currentTaunt()) chips.push([`Taunt: ${ROLE_SHORT[f.currentTaunt()]} ${leftS(f.taunt.until).toFixed(1)}s`, '#e0b84a']);
  if (now < f.ordinanceUntil) chips.push([`Ordinance ${leftS(f.ordinanceUntil).toFixed(0)}s`, '#6aa7ff']);
  if (f.hpBuff.harmony) chips.push([`Harmony ${leftS(f.harmonyUntil).toFixed(0)}s`, '#6fd98a']);
  if (now < f.axiomUntil) chips.push([`Axiom ${leftS(f.axiomUntil).toFixed(0)}s`, '#c58bff']);
  if (now < f.quixUntil) chips.push([`Quix ${leftS(f.quixUntil).toFixed(1)}s`, '#ffd24a']);
  if (f.ap.reduction) chips.push([`AP ${f.ap.reduction === 'seal' ? 'Seal' : 'Eden'}`, '#e8d9a0']);
  if (now < f.lrEmpowerUntil) chips.push([`LR Empowerment ${leftS(f.lrEmpowerUntil).toFixed(0)}s`, '#e0507a']);
  if (f.stunned()) chips.push([`STASIS ${leftS(f.stunUntil).toFixed(1)}s`, '#ff5b5b']);
  chips.forEach(([label, color], i) => {
    const y = 134 + i * 20;
    ctx.fillStyle = 'rgba(8,10,18,.72)';
    ctx.fillRect(6, y, 148, 17);
    ctx.fillStyle = color;
    ctx.fillRect(6, y, 4, 17);
    text(label, 16, y + 13, { size: 11 });
  });

  text(fmtTime(f.t / 1000), C.stage.w - 12, 22, { size: 14, align: 'right', bold: true });
  text(`Next: ${PATTERN[f.rot.idx]}`, C.stage.w - 12, 40, { size: 11, align: 'right', color: '#8a95ab' });

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
  const ents = [
    {
      y: b.y,
      draw: () => {
        ctx.fillStyle = 'rgba(0,0,0,.38)';
        ctx.beginPath();
        ctx.ellipse(b.x, b.y + 4, 150, 22, 0, 0, Math.PI * 2);
        ctx.fill();
        const bob = f.over && f.over.result === 'win' ? 0 : Math.sin((f.t / 1000) * 2.2) * 4;
        A.boss.draw(ctx, bossFrame(), b.x, b.y + bob, C.boss.displayScale, C.boss.displayScale);
      },
    },
    ...ROLES.map((r) => ({ y: S.chars[r].y, draw: () => drawChar(r) })),
  ].sort((a, c) => a.y - c.y);
  ents.forEach((e) => e.draw());

  if (S.target) {
    ctx.strokeStyle = 'rgba(255,210,74,.9)';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.ellipse(b.x, b.y + 4, 120, 20, 0, 0, Math.PI * 2);
    ctx.stroke();
  }
  const t = f.t / 1000;
  S.fx = S.fx.filter((x) => (t - x.t0) * C.fps < A.cfx.count);
  for (const x of S.fx) {
    const p = S.chars[x.role];
    const s = 1 / A.cfx.zoom;
    A.cfx.draw(ctx, Math.floor((t - x.t0) * C.fps), p.x, p.y - 50, s, s);
  }

  for (const r of ROLES) {
    const p = S.chars[r];
    bar(p.x - 28, p.y - 112, 56, 6, f.hp[r] / f.maxHp(r), '#6fe08a', '#1d8a3a');
    text(ROLE_SHORT[r], p.x, p.y - 116, { size: 11, align: 'center', bold: true, color: ROLE_COLOR[r] });
  }
  if (f.currentTaunt()) {
    const p = S.chars[f.currentTaunt()];
    text('TAUNT', p.x, p.y - 130, { size: 10, align: 'center', bold: true, color: '#ffd24a' });
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
  for (const s of classDef().skills) {
    const b = document.createElement('button');
    b.className = 'slot';
    const icon = s.icon && A.icons.has(s.icon) ? `<img src="assets/icons/${s.icon}.webp" alt="">` : `<span class="lbl">${s.name}</span>`;
    b.innerHTML = `${icon}<span class="key">${s.key}</span><span class="cd"></span><span class="cdt"></span>${s.icon && A.icons.has(s.icon) ? `<span class="name">${s.name}</span>` : ''}`;
    b.title = `${s.name} — ${s.tip}`;
    b.addEventListener('click', () => castKey(s.key));
    bar.appendChild(b);
  }
  const passive = classDef().passive;
  if (passive && A.icons.has(passive)) {
    const p = document.createElement('div');
    p.className = 'slot';
    p.style.cursor = 'default';
    p.title = 'Passive';
    p.innerHTML = `<img src="assets/icons/${passive}.webp" alt=""><span class="name">Passive</span>`;
    bar.appendChild(p);
  }
}

function updateSkillbar() {
  const f = S.fight;
  const nodes = $('skillbar').children;
  classDef().skills.forEach((s, i) => {
    const n = nodes[i];
    if (s.key === 1) {
      n.classList.toggle('off', f.stunned());
      return;
    }
    const len = SKILL_CD[CLASS_SKILLS[playerRole][s.key]] || 1;
    const left = Math.max(0, f.cd[s.key] - f.t);
    n.querySelector('.cd').style.height = `${clamp(left / len, 0, 1) * 100}%`;
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
    const mech = MECHANICS[idx];
    rows.push(`<div class="${k === 0 ? 'cur' : ''}">${PATTERN[idx].toUpperCase()}${mech ? ` <span style="color:var(--dim)">→ ${ROLE_SHORT[mech]} tanks${mech === playerRole ? ' (you!)' : ''}</span>` : ''}</div>`);
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
  S = newState();
  bq.length = 0;
  $('log').innerHTML = '';
  buildSkillbar();
  log(`Engaged Ultra Speaker as ${classDef().name}`);
}

// --------------------------------------------------------------------- input
function toStage(ev) {
  const r = canvas.getBoundingClientRect();
  return { x: ((ev.clientX - r.left) / r.width) * C.stage.w, y: ((ev.clientY - r.top) / r.height) * C.stage.h };
}
// movement is mouse only: click the ground to walk there
canvas.addEventListener('mousedown', (ev) => {
  if (S.fight.over) return;
  const { x, y } = toStage(ev);
  const bp = C.map.bossPad;
  const hit = C.boss.displayScale;
  if (Math.abs(x - bp.x) <= 190 * hit && y >= bp.y - 300 * hit && y <= bp.y + 30) {
    moveToBoss(); // click the boss: target it and walk into range
    return;
  }
  S.chars[playerRole].moveTo = { x: clamp(x, C.walk.x0, C.walk.x1), y: clamp(y, C.walk.y0, C.walk.y1) };
});
window.addEventListener('keydown', (ev) => {
  if (ev.target.tagName === 'SELECT') return;
  const k = ev.key.toLowerCase();
  if (k >= '1' && k <= '6') castKey(parseInt(k, 10));
  else if (k === 'p') $('btnPause').click();
});
$('btnRestart').addEventListener('click', restart);
$('btnPause').addEventListener('click', () => {
  paused = !paused;
  $('btnPause').textContent = paused ? 'Resume' : 'Pause';
});
$('selSpeed').addEventListener('change', (e) => (speed = parseFloat(e.target.value)));
$('chkBot').addEventListener('change', (e) => (bot = e.target.checked));
$('selClass').addEventListener('change', (e) => {
  playerRole = e.target.value;
  restart();
  updateHelp();
});

function updateHelp() {
  const h = {
    loo: '<b>Taunt (6)</b> when the banner says so; <b>Quix (5)</b> on Truth #5 and #9; <b>Ordinance (3)</b> to heal; keep <b>Harmony (2)</b> and <b>Axiom (4)</b> up. You are zone <b>4</b>.',
    ap: '<b>Seal (4)</b> before Truths #1–3 and #5–7 (the next cast needs it), then <b>Eden (5)</b> within ~5 s to break it; <b>Heal (3)</b> the party. Skills need you near the middle. You are zone <b>3</b>.',
    lr: '<b>Empowerment (4)</b> keeps your damage taken -30%; <b>Anathema (5)</b> hits the boss; <b>Taunt (6)</b> when the banner says so. You are zone <b>2</b>.',
  }[playerRole];
  $('help').innerHTML = h;
}

// ---------------------------------------------------------------------- loop
let last = performance.now();
function frame(now) {
  const dt = Math.min((now - last) / 1000, 0.1);
  last = now;
  if (!paused) {
    const sdt = dt * speed;
    const steps = Math.max(1, Math.ceil(sdt / 0.05));
    for (let i = 0; i < steps; i++) {
      S.fight.step((sdt / steps) * 1000);
      runBot();
      updateChars(sdt / steps);
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
  $('selClass').innerHTML = Object.entries(C.classes).map(([k, v]) => `<option value="${k}">${v.name}</option>`).join('');
  $('selClass').value = playerRole;
  restart();
  updateHelp();
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
  window.__sim = { get S() { return S; }, castKey, C, restart, get role() { return playerRole; } };
}

main().catch((e) => {
  $('loading').textContent = 'Failed to load: ' + e.message;
  console.error(e);
});

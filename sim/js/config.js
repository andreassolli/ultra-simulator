// Tunables for the Ultra Speaker boss simulator.
//
// What comes from the SWFs (exact):
//   - map art, BossPad / Left pad / SafeA box coordinates, rune1 + safe1 clips
//   - boss animation labels + frame numbers (monster-UltraMalg.swf)
//   - skill effect clips (sp_*) and skill icons (Assets_20260731.swf)
//   - 24 fps, GCD 1500 ms, melee vertical tolerance 30 px, cd/mp/range skill
//     fields, tgt/fx/strl cast pipeline (Game3.swf, World.as)
//
// What is NOT in any client SWF and is therefore an assumption (tune freely):
//   boss HP, boss damage, player stats, skill damage/cooldowns, mechanic timings.
//   Those live on the AQW server, the client only receives results.

export const CONFIG = {
  fps: 24,

  stage: { w: 960, h: 500 },
  // Walkable ground: below the horizon line of the background.
  walk: { x0: 24, x1: 936, y0: 240, y1: 488 },

  // From town-ultraspeaker MainTimeline, frame "Boss" (twips / 20).
  map: {
    bossPad: { x: 492.5, y: 315.7 }, // BossPad (noMove = true)
    leftPad: { x: 480.8, y: 443.5 }, // "Left" pad, where players arrive
    rune1: { x: 274.75, y: 277.75, sx: 1.0141, sy: 1.3051 },
    safe1: { x: 523.95, y: 415.75, sx: -1.2, sy: 1.2 },
    // SafeA component (sType "SafeA", tID 1, box): x/y/scale of its 22.1x20 px base clip
    safeA: { x: 180.65, y: 220.55, w: 612.7, h: 294.7 },
  },

  boss: {
    name: 'Ultra Speaker',
    level: 100,
    hp: 3_000_000,
    displayScale: 0.75, // exported sprite px -> stage px
    firstSpecialAt: 14, // s after engage
    specialEvery: 28, // s
    specialOrder: ['A', 'B', 'P'], // ChargeA / ChargeB / PowerUp->Attack2
    chargeHold: 6.0, // s the charge loop is held before it resolves
    basicEvery: 2.6, // s between basic attacks
    meleeRangeX: 230,
    meleeRangeY: 95,
    attack1Damage: 5200,
    flameDamage: 8800,
    flameRadius: 105,
    flameTelegraph: 1.1, // s
    raidBlastDamage: 17000, // Attack2 after PowerUp
    wrongZoneDamage: 1.0, // fraction of max HP (1 = lethal) if outside the lit zone
    absorbHeal: 0.01, // boss heals this fraction of max HP on a successful Absorption/Magic
    enrageAt: 480, // s; all damage x(1 + 0.25 per 30s after this)
  },

  player: {
    name: 'Hero',
    level: 100,
    hp: 32000,
    mp: 100,
    mpRegen: 5, // per s
    hpRegen: 0.01, // fraction of max HP / s (stand-in for class self-heals)
    speed: 250, // px/s  (Game: intSpeed 8-10 @ 30 fps)
    baseDamage: 4200,
    critChance: 0.15,
    critMult: 1.5,
    potion: { heal: 14000, cd: 30 },
  },

  // Game3.swf World.as constants
  combat: {
    gcd: 1.5, // GCD = 1500
    vTolerance: 30, // SC_VTOL-like: vertical tolerance for range <= 301
    autoAttackCd: 2.0,
  },

  // Per-slot template. Real values come from the server; shape matches the
  // client action fields (ref, cd, mp, range, tgt, typ).
  slots: [
    { ref: 'aa', typ: 'aa', cd: 2.0, mp: 0, range: 301, mult: 1.0 },
    { ref: 'a1', typ: 'm', cd: 4.0, mp: 12, range: 301, mult: 2.2 },
    { ref: 'a2', typ: 'm', cd: 6.0, mp: 16, range: 600, mult: 3.0 },
    { ref: 'a3', typ: 'm', cd: 9.0, mp: 22, range: 600, mult: 4.4 },
    { ref: 'a4', typ: 'm', cd: 14.0, mp: 30, range: 600, mult: 7.0 },
  ],
};

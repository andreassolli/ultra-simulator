// Tunables for the Ultra Speaker simulator.
//
// From the SWFs (exact): map art + pad / SafeA coordinates, rune1/safe1 clips,
// boss animation labels and frame numbers, Lord of Order skill icons and cast
// effect, 24 fps.
//
// From the author's web simulator (speaker.js, lordoforder.js, ...): boss
// rotation, cast times, cooldowns, damage ranges, party HP, Lord of Order skill
// numbers (see js/fight.js).
//
// Assumptions (not in any client file): boss HP / raid DPS below, the mapping of
// boss animations to abilities, and which LoO icon belongs to which skill.

export const CONFIG = {
  fps: 24,
  stage: { w: 960, h: 500 },
  walk: { x0: 24, x1: 936, y0: 240, y1: 488 },

  map: {
    bossPad: { x: 492.5, y: 315.7 },
    leftPad: { x: 480.8, y: 443.5 },
    rune1: { x: 274.75, y: 277.75, sx: 1.0141, sy: 1.3051 },
    safe1: { x: 523.95, y: 415.75, sx: -1.2, sy: 1.2 },
    // SafeA box: the area a player must stand in for "their" Equal zone
    safeA: { x: 180.65, y: 220.55, w: 612.7, h: 294.7 },
  },

  fight: {
    bossHp: 10_000_000,
    partyDps: [42000, 52000], // per hit, every 0.6-1.1 s (rest of the raid)
  },

  boss: { name: 'Ultra Speaker', level: 100, displayScale: 0.75 },

  player: {
    name: 'Lord of Order',
    speed: 250, // px/s
    autoDamage: [1800, 2299], // skill 1 / auto attack
    autoCritAbove: 2200,
    autoEvery: 1.33, // s (330 ms swing + 1000 ms delay in the web sim)
    attackRangeX: 260,
    attackRangeY: 130,
  },

  // Lord of Order skill bar. `icon` = Assets_20260731.swf symbol; the SWF has aa
  // + four numbered skills + a passive, the web sim has Harmony/Ordinance/Axiom/
  // Quix/Taunt, so the icon order below is an assumption — edit freely.
  loo: [
    { key: 1, id: 'aa', name: 'Attack', icon: 'LoOaa', tip: 'Auto attack / move to the boss' },
    { key: 2, id: 'harmony', name: 'Harmony', icon: 'LoO1', tip: 'Raises party max HP for 10 s' },
    { key: 3, id: 'ordinance', name: 'Ordinance', icon: 'LoO2', tip: 'Heals the party for 2,700 and cuts damage taken 30% for 12 s' },
    { key: 4, id: 'axiom', name: 'Axiom', icon: 'LoO3', tip: '10 s buff — keep it rolling' },
    { key: 5, id: 'quix', name: 'Quix', icon: 'LoO4', tip: 'Needed on Truth #5 and #9 of each cycle (25 s lockout)' },
    { key: 6, id: 'taunt', name: 'Taunt', icon: null, tip: 'Hold the boss for 6 s (10 s cooldown)' },
  ],
  passiveIcon: 'LoOp',
};

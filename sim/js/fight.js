// Ultra Speaker fight rules (no DOM / canvas, so it can run under node for tests).
//
// The boss rotation, cast times, cooldowns, damage ranges, taunt/seal/quix/zone
// requirements and the Lord of Order / Arch Paladin / Legion Revenant numbers are
// ported from the author's web simulator (speaker.js, lordoforder.js,
// archpaladin.js, legionrevenant.js, party-manager.js). All times are in ms.

export const PATTERN = [
  'auto', 'auto', 'auto', 'auto', 'truth', 'listen',
  'zone', // new cycle starts here (index 6)
  'truth', 'auto', 'listen', 'truth', 'auto', 'auto',
  'zone', 'listen', 'truth', 'auto', 'auto', 'truth', 'listen',
  'zone', 'truth', 'auto', 'listen', 'truth', 'auto', 'auto',
  'zone', 'listen', 'truth', 'auto', 'auto', 'truth', 'listen',
];

// pattern index -> role that must hold the boss (taunt) for that cast
export const MECHANICS = {
  4: 'lr', 5: 'loo', 7: 'ap', 9: 'loo', 10: 'loo', 14: 'lr', 15: 'lr', 18: 'loo', 19: 'loo',
  21: 'ap', 23: 'lr', 24: 'lr', 27: 'loo', 28: 'loo', 31: 'lr', 32: 'loo', 33: 'loo',
};

export const ZONE_ROLES = { 1: 'dps', 2: 'lr', 3: 'ap', 4: 'loo' };
export const ROLES = ['ap', 'lr', 'loo', 'dps'];
export const ROLE_NAMES = { ap: 'Arch Paladin', lr: 'Legion Revenant', loo: 'Lord of Order', dps: 'DPS' };

const TIMINGS = { auto: 2000, truth: 7000, listen: 12000, zone: 16000 }; // per-ability cooldown
const CAST = { auto: 1200, truth: 2000, listen: 2000, zone: 3000 };

const MAX_HP = {
  ap: { base: 3670, one: 4000, both: 4400 },
  lr: { base: 2910, one: 3090, both: 3310 },
  loo: { base: 3205, one: 3445, both: 3735 },
  dps: { base: 2810, one: 2975, both: 3170 },
};
const START_HP = { ap: 3670, lr: 2910, loo: 3205, dps: 2450 };

// Arch Paladin / Legion Revenant scripted rotations: pattern index -> skills
const AP_ROTATION = {
  1: [2, 4], 2: [2, 3], 3: [2], 4: [2], 5: [3, 2], 6: [2], 7: [4, 2], 8: [2, 3], 9: [2], 10: [4, 2],
  11: [2], 12: [2], 13: [3], 14: [3, 2], 15: [4, 2], 16: [3, 2], 17: [2], 18: [2], 19: [3, 2], 20: [4, 2],
  21: [3, 2], 22: [2], 23: [3, 2], 24: [4, 2], 25: [2, 3], 26: [2, 3], 27: [], 28: [3, 2], 29: [4, 2],
  30: [2], 31: [3, 2], 32: [2], 33: [3, 2],
};

const rnd = (a, b) => a + Math.random() * (b - a);
const irnd = (a, b) => Math.floor(rnd(a, b + 1));

export const LOO = {
  harmony: { cd: 4000, dur: 10000 },
  ordinance: { cd: 6000, dur: 12000, heal: 2700, reduction: 0.3 },
  axiom: { cd: 4000, dur: 10000 },
  quix: { cd: 4000, dur: 4000, lockout: 25000 },
  taunt: { cd: 10000, dur: 6000 },
  gcd: 400,
};

export class Fight {
  /**
   * hooks: {
   *   boss(name, loop)          play a boss animation label
   *   zone(on, role)            Equal zone telegraph on/off
   *   announce(text)            boss shout
   *   floater(role, text, kind) 'dmg' | 'crit' | 'heal' | 'info' | 'bad'
   *   log(msg, cls)
   *   playerInZone()            is the player standing inside the SafeA box?
   *   end(result, reason)
   *   fx(kind, role)            cosmetic cast effects
   * }
   */
  constructor(cfg, hooks, playerRole = 'loo') {
    this.cfg = cfg;
    this.h = hooks;
    this.playerRole = playerRole;
    this.reset();
  }

  reset() {
    this.t = 0;
    this.timers = [];
    this.over = null;
    this.bossHp = this.cfg.bossHp;
    this.hp = { ...START_HP };
    this.somber = { ap: 0, lr: 0, loo: 0, dps: 0 };
    this.armor = { ap: 0.8, lr: 0.8, loo: 0.8, dps: 0.8 };
    this.hpBuff = { harmony: false, apHeal: false };
    this.harmonyUntil = 0;
    this.apHealUntil = 0;
    this.taunt = { role: null, until: 0 };
    this.stunUntil = 0;
    this.mechanic = null;
    this.ordinanceUntil = 0;
    this.axiomUntil = 0;
    this.quixUntil = 0;
    this.quixAvailableAt = 0;
    this.cd = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0 };
    this.ap = { reduction: null, sealToken: 0, edenToken: 0 };
    this.lrEmpowerUntil = 0;
    this.lrEmpowerReady = 0;
    this.counters = { harmony: 0, ordinance: 0, axiom: 0, seal: 0, quix: 0, notBroken: 0, zones: 0, truths: 0, listens: 0, autos: 0 };
    this.rot = { idx: 0, phase: 'cool', busyUntil: 0, truthN: 1, zoneN: 1, last: {}, started: false, mech: null };
    this.zoneActive = null;
    this.partyDrainAt = 600;
    this.h.zone?.(false);
  }

  // ------------------------------------------------------------------ helpers
  after(ms, fn) {
    this.timers.push({ at: this.t + ms, fn });
  }

  get playerHp() {
    return this.hp[this.playerRole];
  }

  maxHp(role) {
    const m = MAX_HP[role];
    const n = (this.hpBuff.harmony ? 1 : 0) + (this.hpBuff.apHeal ? 1 : 0);
    return n === 2 ? m.both : n === 1 ? m.one : m.base;
  }

  setBuff(name, on) {
    if (this.hpBuff[name] === on) return;
    const old = {};
    ROLES.forEach((r) => (old[r] = this.maxHp(r)));
    this.hpBuff[name] = on;
    ROLES.forEach((r) => (this.hp[r] = Math.round((this.hp[r] / old[r]) * this.maxHp(r))));
  }

  currentTaunt() {
    return this.t < this.taunt.until ? this.taunt.role : null;
  }

  stunned() {
    return this.t < this.stunUntil;
  }

  reductionFor(role, isTruth) {
    let r = 0;
    if (this.t < this.ordinanceUntil) r = 1 - (1 - r) * (1 - LOO.ordinance.reduction);
    if (role === 'lr' && this.t < this.lrEmpowerUntil) r = 1 - (1 - r) * (1 - 0.3);
    if (isTruth) {
      if (this.ap.reduction === 'seal') r = 1 - (1 - r) * (1 - 0.9);
      else if (this.ap.reduction === 'eden') r = 1 - (1 - r) * (1 - 0.15);
    }
    return r;
  }

  hurt(role, dmg, why, kind = 'dmg') {
    if (this.over) return;
    dmg = Math.max(0, Math.round(dmg));
    this.hp[role] = Math.max(0, this.hp[role] - dmg);
    this.h.floater?.(role, `-${dmg.toLocaleString('en-US')}`, kind);
    if (this.hp[role] <= 0) this.end('lose', `${role.toUpperCase()} died (${why})`);
  }

  heal(role, amount) {
    if (this.over || this.hp[role] <= 0) return;
    const real = Math.min(this.maxHp(role) - this.hp[role], amount);
    this.hp[role] += real;
    if (real > 0) this.h.floater?.(role, `+${Math.round(real).toLocaleString('en-US')}`, 'heal');
  }

  healParty(amount, exceptPlayer = false) {
    ROLES.forEach((r) => {
      if (exceptPlayer && r === this.playerRole) return;
      this.heal(r, amount);
    });
  }

  end(result, reason) {
    if (this.over) return;
    this.over = { result, reason };
    this.h.zone?.(false);
    this.h.end?.(result, reason);
  }

  // ------------------------------------------------------------ boss abilities
  autoAttack() {
    const r = this.rot;
    r.last.auto = this.t;
    this.counters.autos++;
    this.h.boss?.('Attack1');
    const base = irnd(804, 981);
    const crit = base > 904;
    this.after(850, () => {
      ROLES.forEach((role) => {
        let dmg = base * (1 + 0.07 * this.somber[role]) * (1 - this.armor[role]) * (1 - this.reductionFor(role, false));
        this.hurt(role, Math.ceil(dmg), 'Auto attack', crit ? 'crit' : 'dmg');
        this.somber[role]++;
      });
      ROLES.forEach((role) => (this.armor[role] = Math.max(0, this.armor[role] - 0.07)));
    });
    this.after(1320, () => this.h.boss?.('Idle'));
  }

  truth(truthN) {
    const r = this.rot;
    r.last.truth = this.t;
    this.counters.truths++;
    this.h.boss?.('Shadowflame');
    this.h.announce?.('I will make you see the truth.');
    const base = irnd(1447, 1766);
    const crit = base > 1447 + 220;
    const mech = r.mech; // role that must hold the boss for this cast
    this.after(2000, () => {
      const n = ((truthN - 1) % 9) + 1;
      const need = { 2: 'seal', 3: 'seal', 4: 'seal', 5: 'quix', 6: 'seal', 7: 'seal', 8: 'seal', 9: 'quix' }[n];
      if (need === 'seal' && this.ap.reduction !== 'seal') {
        this.h.floater?.(null, 'Missed Seal', 'bad');
        this.counters.seal++;
        return;
      }
      if (need === 'quix' && this.t >= this.quixUntil) {
        this.h.floater?.(null, 'Missed Quix', 'bad');
        this.counters.quix++;
        return;
      }
      if (mech === this.playerRole && this.currentTaunt() !== mech) {
        this.end('lose', 'Missed Taunt');
        return;
      }
      if (!mech) return;
      const dmg = base * (1 - this.armor[mech]) * (1 - this.reductionFor(mech, true));
      this.hurt(mech, Math.ceil(dmg), 'Truth', crit ? 'crit' : 'dmg');
    });
    this.after(2120, () => this.h.boss?.('Idle'));
  }

  listen() {
    const r = this.rot;
    r.last.listen = this.t;
    this.counters.listens++;
    this.h.boss?.('Magic');
    this.h.announce?.('You shall listen.');
    const mech = r.mech;
    this.after(2000, () => {
      if (mech === this.playerRole && this.currentTaunt() !== mech) {
        this.end('lose', 'Missed Taunt');
        return;
      }
      if (this.currentTaunt() === this.playerRole) {
        this.stunUntil = this.t + 6000;
        this.h.log?.('Stasis — you cannot use skills 2–6 for 6s', 'bad');
      }
    });
    this.after(2280, () => this.h.boss?.('Idle'));
  }

  equal(zoneN) {
    const r = this.rot;
    r.last.zone = this.t;
    this.counters.zones++;
    const role = ZONE_ROLES[zoneN];
    this.h.announce?.('All stand equal beneath the eyes of the Eternal.');
    this.h.log?.(`Equal — zone ${zoneN}: ${role.toUpperCase()} must stand inside`, 'bad');
    this.after(100, () => {
      this.h.boss?.('ChargeA');
      this.h.zone?.(true, role);
      this.zoneActive = role;
    });
    this.after(900, () => this.h.boss?.('ChargeALoop', true));
    this.after(2600, () => this.h.boss?.('Absorption'));
    this.after(3000, () => {
      const dmg = irnd(2411, 2946);
      const inZone = this.h.playerInZone?.() ?? false;
      const shouldBeIn = role === this.playerRole;
      this.hurt(role, dmg, 'Equal zone');
      if (!shouldBeIn && inZone) {
        this.hp[this.playerRole] = 0;
        this.end('lose', 'Stood inside someone else\'s zone');
      } else if (shouldBeIn && !inZone) {
        this.end('lose', 'Missed Zone');
      } else {
        this.somber[role] = 0;
        this.armor[role] = 0.8;
        this.h.log?.(`${role.toUpperCase()} cleansed (Somber/armor reset)`, 'good');
      }
      this.zoneActive = null;
      this.h.zone?.(false);
    });
    this.after(3400, () => this.h.boss?.('Idle'));
  }

  // ------------------------------------------------------ scripted party members
  apSkill(n) {
    if (n === 3) this.apHeal();
    else if (n === 4) this.apSeal();
    else if (n === 5) this.apEden();
    // 2 = Commandment (stacking damage buff, no effect on this model)
  }

  apHeal() {
    this.after(250, () => {
      this.setBuff('apHeal', true);
      this.apHealUntil = this.t + 15000;
      this.healParty(6682);
      this.h.fx?.('heal', 'ap');
    });
  }

  apSeal() {
    const tok = ++this.ap.sealToken;
    this.after(250, () => {
      this.ap.reduction = 'seal';
      this.h.fx?.('seal', 'ap');
    });
    this.after(250 + 5500, () => {
      if (this.ap.sealToken === tok && this.ap.reduction === 'seal') this.apEden();
    });
    this.after(7250, () => {
      if (this.ap.sealToken === tok && this.ap.reduction === 'seal') {
        this.ap.reduction = null;
        this.counters.notBroken++;
      }
    });
  }

  apEden() {
    const tok = ++this.ap.edenToken;
    this.after(250, () => {
      this.ap.reduction = 'eden';
      this.h.fx?.('eden', 'ap');
    });
    this.after(25250, () => {
      if (this.ap.edenToken === tok && this.ap.reduction === 'eden') this.ap.reduction = null;
    });
  }

  scriptedParty(idx, ability) {
    (AP_ROTATION[idx] || []).forEach((s, i) => this.after(i * 500, () => this.apSkill(s)));
    // Legion Revenant: keeps Empowerment (-30% damage taken) rolling off cooldown
    this.after(750, () => {
      if (this.t >= this.lrEmpowerReady) {
        this.lrEmpowerUntil = this.t + 12250;
        this.lrEmpowerReady = this.t + 3000;
        this.h.fx?.('empower', 'lr');
      }
    });
  }

  // ----------------------------------------------------- Lord of Order (player)
  skillReady(n) {
    if (this.over) return false;
    if (this.t < this.cd[n]) return false;
    if (n >= 2 && this.stunned()) return false;
    return true;
  }

  startCd(n, ms) {
    this.cd[n] = this.t + ms;
  }

  globalCd() {
    for (let n = 2; n <= 6; n++) if (this.cd[n] - this.t < 1000) this.cd[n] = Math.max(this.cd[n], this.t + LOO.gcd);
  }

  /** 2 Harmony, 3 Ordinance, 4 Axiom, 5 Quix, 6 Taunt. Returns true if cast. */
  cast(n) {
    if (!this.skillReady(n)) return false;
    const me = this.playerRole;
    switch (n) {
      case 2:
        this.startCd(2, LOO.harmony.cd);
        this.after(250, () => {
          this.setBuff('harmony', true);
          this.harmonyUntil = this.t + LOO.harmony.dur;
          this.h.fx?.('harmony', me);
        });
        this.after(250 + LOO.harmony.dur, () => {
          if (this.t >= this.harmonyUntil) {
            this.counters.harmony++;
            this.setBuff('harmony', false);
          }
        });
        break;
      case 3:
        this.startCd(3, LOO.ordinance.cd);
        this.after(250, () => {
          this.ordinanceUntil = this.t + LOO.ordinance.dur;
          this.healParty(LOO.ordinance.heal);
          this.h.fx?.('ordinance', me);
        });
        this.after(250 + LOO.ordinance.dur, () => {
          if (this.t >= this.ordinanceUntil) this.counters.ordinance++;
        });
        break;
      case 4:
        this.startCd(4, LOO.axiom.cd);
        this.after(250, () => {
          this.axiomUntil = this.t + LOO.axiom.dur;
          this.h.fx?.('axiom', me);
        });
        this.after(250 + LOO.axiom.dur, () => {
          if (this.t >= this.axiomUntil) this.counters.axiom++;
        });
        break;
      case 5:
        this.startCd(5, LOO.quix.cd);
        this.after(250, () => {
          if (this.t < this.quixAvailableAt) {
            this.quixAvailableAt = this.t + LOO.quix.lockout; // spamming resets the lockout
            return;
          }
          this.quixAvailableAt = this.t + LOO.quix.lockout;
          this.quixUntil = this.t + LOO.quix.dur;
          this.h.fx?.('quix', me);
        });
        break;
      case 6:
        this.startCd(6, LOO.taunt.cd);
        this.taunt = { role: me, until: this.t + LOO.taunt.dur };
        this.h.fx?.('taunt', me);
        break;
      default:
        return false;
    }
    this.globalCd();
    return true;
  }

  // -------------------------------------------------------------------- engine
  handleMechanic(role) {
    if (role === this.playerRole) return;
    this.taunt = { role, until: this.t + 6000 };
  }

  fireAbility() {
    const r = this.rot;
    const ability = PATTERN[r.idx];
    r.mech = MECHANICS[r.idx] ?? null;
    if (r.mech) this.handleMechanic(r.mech);
    this.h.mechanic?.(r.mech, ability, { truthN: r.truthN, zoneN: r.zoneN });
    this.scriptedParty(r.idx, ability);
    switch (ability) {
      case 'auto':
        this.autoAttack();
        break;
      case 'truth':
        {
          const requiresSeal = (r.truthN >= 1 && r.truthN <= 3) || (r.truthN >= 5 && r.truthN <= 7);
          if (requiresSeal && this.playerRole !== 'ap') this.apSeal();
        }
        this.truth(r.truthN);
        r.truthN++;
        break;
      case 'listen':
        this.listen();
        break;
      case 'zone':
        this.equal(r.zoneN);
        r.zoneN++;
        break;
    }
    r.busyUntil = this.t + CAST[ability] + 1000;
    r.phase = 'busy';
  }

  step(dtMs) {
    if (this.over) return;
    this.t += dtMs;
    // timers
    let guard = 0;
    while (guard++ < 1000) {
      let k = -1;
      for (let i = 0; i < this.timers.length; i++) if (this.timers[i].at <= this.t && (k < 0 || this.timers[i].at < this.timers[k].at)) k = i;
      if (k < 0) break;
      const [tm] = this.timers.splice(k, 1);
      tm.fn();
      if (this.over) return;
    }
    // HP buff expiry
    if (this.hpBuff.apHeal && this.t >= this.apHealUntil) this.setBuff('apHeal', false);
    // boss rotation
    const r = this.rot;
    if (r.phase === 'cool') {
      const ability = PATTERN[r.idx];
      const start = r.last[ability] ?? 0;
      if (this.t >= start + TIMINGS[ability]) this.fireAbility();
    } else if (this.t >= r.busyUntil) {
      r.idx++;
      if (r.idx >= PATTERN.length) {
        r.idx = 6;
        r.zoneN = 1;
        r.truthN = 2;
      }
      r.phase = 'cool';
    }
    // rest of the raid drains the boss (web sim: 42-52k every 0.6-1.1 s)
    if (this.t >= this.partyDrainAt) {
      const d = irnd(this.cfg.partyDps[0], this.cfg.partyDps[1]);
      this.bossHp = Math.max(0, this.bossHp - d);
      this.h.bossDamage?.(d, d > this.cfg.partyDps[0] + (this.cfg.partyDps[1] - this.cfg.partyDps[0]) * 0.7, 'party');
      this.partyDrainAt = this.t + rnd(600, 1100);
      if (this.bossHp <= 0) this.end('win', 'Ultra Speaker defeated');
    }
  }

  playerHit(dmg, crit) {
    if (this.over) return;
    this.bossHp = Math.max(0, this.bossHp - dmg);
    this.h.bossDamage?.(dmg, crit, 'player');
    if (this.bossHp <= 0) this.end('win', 'Ultra Speaker defeated');
  }
}

package sim
{
    /**
     * Ultra Darkon fight rules (the Lord of Order's fight), from the Darkon the Conductor guide.
     *
     * Darkon: Phase 1 "Overture" 22 222 222 -> 15 555 555 HP, Phase 2 "Recitative" 15 555 555 -> 4 444 444 HP, then "Aria": he heals to
     * 20 000 000 HP and Phase 3 runs to 0. Damage on him above 122 222 is reduced (CAP). Every 30 s "The Cycle's End" adds +10 % damage
     * taken (10 stacks max).
     *
     * His attacks come one per 2.25 s slot (SLOT), in the guide's patterns (A = auto, N = nuke, E = Elegy / mouth):
     *   Intro  A A E A A N E        (once, from the start)        Loop  A A E A N E        (then forever)
     *   Swap   A A E N A E          (after each phase transition: "he changes his nuke timings")
     *   - Auto: hits all four, ignores Focus, always crits; P1 -50 % hit chance (no stack), P2 -6 % haste per auto (22 stacks),
     *           P3 -80 % healing taken. In the first 50 s of Phase 3 autos hit much harder, after that Darkon deals no damage any more.
     *   - Nuke: 90 % of the current HP of one player (the taunt holder). Always hits. P1: every nuke adds an aura that makes his autos
     *           stronger (six of them and he one-shots: the reason Phase 1 has to end before 72 s); P3: damage over time for 8 s.
     *   - Elegy (the mouth, tauntable): lands on whoever holds the taunt; nobody holding it = everybody takes it = lost (Missed Taunt).
     *           P1: a second Elegy within 8 s stuns (lost). P2: Seed Planted (8 s) removes your haste debuff, a 2nd one within 8 s = crits
     *           reversed (Grown), a 3rd = fatal. P3: Dirge of Astravia, +25 % mana costs per stack (12 s, 22 stacks).
     *   - 4:30 (270 s) "End of the World": 3 s later Curtain Call kills everybody.
     *   Phase 3 starts with Aria: Darkon is immune for 50 s (Major auras), then takes +200 % damage.
     *
     * Taunts: the Legion Revenant (played by the sim) takes the Elegies on every other mouth, the Lord of Order (you) on the others,
     * so each of you is hit once per 13.5 s. The Revenant taunts 2.75 s before its mouth lands, you have to taunt 4.2-4.8 s after the
     * Revenant's taunt (when it has 20-30 % left): the HUD cue tells you when (the window is about 1.75 s wide). Healing: the nuke
     * target is healed right after the nuke by the raid's healer. The other two characters (StoneCrusher, Chrono ShadowSlayer) are
     * played by the sim.
     * Quix (Lord of Order, skill 5): it may be used from the start, but not any more from 13 000 000 HP on (before he regains health), and
     * it has to be used once between 5 000 000 and 4 500 000 HP. Using it in between, or missing the window, loses. Anybody dying loses too.
     *
     * ANIMATIONS: which frame label of monster-UltraDarkon.swf plays for each attack is the ANIM table below (see README "Fixing
     * animations"). The raid's damage is tuned so that the fight takes about three minutes: see GEAR.
     */
    public class DarkonFight extends Fight
    {
        public static const DK_ROLES:Array = ["loo", "lr", "sc", "cs"];
        public static const DK_NAMES:Object = {loo: "Lord of Order", lr: "Legion Revenant", sc: "StoneCrusher", cs: "Chrono ShadowSlayer"};
        public static const DK_SKILLS:Object = {
            loo: {2: "harmony", 3: "ordinance", 4: "axiom", 5: "quix", 6: "taunt"}
        };
        private static const LISTED_CD:Object = {harmony: 8000, ordinance: 16000, axiom: 8000, quix: 8000, taunt: 10000};
        private static const SKILL:Object = {harmony: {mp: 20}, ordinance: {mp: 20}, axiom: {mp: 20}, quix: {mp: 30}, taunt: {mp: 0}};
        private static const START_HP:Object = {loo: 3505, lr: 2910, sc: 2810, cs: 2835};
        private static const HARMONY_HP:Number = 0.0685;

        // ---- Darkon's numbers -------------------------------------------------------------------------
        public static const HP_P1:Number = 22222222;
        public static const HP_P2:Number = 15555555;
        public static const HP_REGAIN:Number = 4444444;
        public static const HP_P3:Number = 20000000;
        public static const QUIX_STOP:Number = 13000000;      // from here on Quix may not be used
        public static const QUIX_WINDOW_HI:Number = 5000000;  // ... until Quix has to be used once between these two
        public static const QUIX_WINDOW_LO:Number = 4500000;
        private static const ENRAGE_MS:int = 72000;           // Phase 1 has to be over by then
        private static const CURTAIN_MS:int = 270000;         // 4:30: End of the World
        private static const CURTAIN_CHARGE:int = 3000;
        private static const CYCLE_MS:int = 30000;            // The Cycle's End: +10 % damage taken, 10 stacks
        private static const SLOT:int = 2250;                 // one boss attack every 2.25 s
        private static const FIRST_SLOT:int = 1000;
        private static const ELEGY_HIT_AFTER:int = 2000;      // mouth opens at its slot, lands this long after
        private static const LR_TAUNT_BEFORE:int = 2750;      // the Revenant taunts this long before its mouth lands
        private static const LOO_CUE_BEFORE:int = 5000;       // "taunt now" cue this long before the mouth you take lands
        private static const DEBUFF_MS:int = 8000;            // Elegy of Madness / Seed Planted
        private static const TAUNT_MS:int = 6000;
        private static const IMMUNE_MS:int = 50000;           // Phase 3: B/C Major auras
        private static const INTRO:String = "AAEAANE";
        private static const LOOP:String = "AAEANE";
        private static const SWAP:String = "AAENAE";
        private static const CAP:Number = 122222;
        private static const GEAR:Number = 27;
        private static const AUTO:Number = 500;               // Darkon's auto on a tank (tuned, see README)

        /**
         * ANIMATION TABLE: the frame label of monster-UltraDarkon.swf that each attack plays, and how long (ms) it is left to run before
         * going back to Idle. Change a label here if an attack shows the wrong animation (README: "Fixing animations").
         * Available labels: Idle, Attack1, Attack2, Attack3, Charge, Chargeloop, ChargeAttack, PowerUp, Die (+ Walk, Hit ...).
         */
        private static const ANIM:Object = {
            auto1: "Attack1",             // first auto of a pair
            auto2: "Attack2",             // second auto
            nuke: "Attack3",
            elegyOpen: "Charge",          // the mouth opens
            elegyHold: "Chargeloop",      // looped while the mouth stays open (frames in BOSSES.darkon.loops)
            elegyHit: "ChargeAttack",     // the Elegy lands
            transform: "PowerUp",         // Recitative / Aria / End of the World
            idle: "Idle"
        };
        private static const ANIM_MS:Object = {auto: 1900, nuke: 1900, elegyHold: 1100, elegyHit: 2400, transform: 1450}; // frames / 24 fps
        private static const HIT_AT:Object = {auto: 450, nuke: 800};  // when the damage lands after the animation starts
        private static const LIFESTEAL:Number = 300;
        private static const HEAL_BOOST:Number = 1.4;
        private static const GCD:int = 400;
        private static const AA:Object = {cd: 2000, f: 0.7, src: "APSP1", type: "phys"};

        // ---- state shared with the HUD ----------------------------------------------------------------
        public var phase:int = 1;
        public var phaseStart:Number = 0;
        public var casts:Object = {taunted: 0, missedTaunt: 0};
        public var hasteStacks:Object = {};
        public var critReversed:Object = {};
        public var elegyRun:Object = {};
        public var manaDebuffUntil:Number = 0;
        public var healDebuffUntil:Object = {};
        public var dotUntil:Object = {};
        public var quixStopped:Boolean = false;
        public var quixInWindow:Boolean = false;
        public var transforming:Boolean = false;

        private var host2:IFightHost;
        private var timers2:Array = [];
        private var playerClass:String;
        private var me:Object;
        private var elegyCount:int = 0;        // Elegies scheduled so far: even ones are the Revenant's, odd ones yours
        private var nukeCount:int = 0;         // nukes landed in the current phase (auras)
        private var cycleStacks:int = 0;       // The Cycle's End
        private var cycleAt:Number = CYCLE_MS;
        private var curtainAt:Number = -1;
        private var elegyDebuffUntil:Object = {};
        private var growUntil:Object = {};
        private var dirgeStacks:Object = {};
        private var dirgeUntil:Object = {};
        private var nextPattern:String = INTRO;
        private var npcDepravedAt:Number = 2500;
        private var cuedStop:Boolean = false;
        private var cuedWindow:Boolean = false;
        private var tickAt:Number = 1000;
        private var partyAt:Number = 600;
        private var depravedUntil:Number = 0;
        private var lrShield:Number = 0;
        private var lrShieldUntil:Number = 0;
        private var lrHotUntil:Number = 0;

        public function DarkonFight(host:IFightHost, role:String, bossHp:Number, raidDps:Array)
        {
            super(host, role, HP_P1, raidDps);
            host2 = host;
            playerClass = role;
            me = Dmg.profile(role);
            started = false;
            hp = {};
            somber = {};
            armor = {};
            for each (var r:String in DK_ROLES)
            {
                hp[r] = START_HP[r];
                somber[r] = 0;
                armor[r] = 0;
                hasteStacks[r] = 0;
                critReversed[r] = false;
                elegyRun[r] = 0;
                healDebuffUntil[r] = 0;
                dotUntil[r] = 0;
                elegyDebuffUntil[r] = 0;
                growUntil[r] = 0;
                dirgeStacks[r] = 0;
                dirgeUntil[r] = 0;
            }
        }

        // ------------------------------------------------------------------ helpers
        private static function rnd(a:Number, b:Number):Number
        {
            return a + Math.random() * (b - a);
        }

        /** `kind` marks the boss' own attacks so that the "Next:" line can find the next one */
        private function later(ms:Number, fn:Function, kind:String = ""):void
        {
            timers2.push({at: t + ms, fn: fn, kind: kind});
        }

        private function laterAt(abs:Number, fn:Function, kind:String = ""):void
        {
            timers2.push({at: abs, fn: fn, kind: kind});
        }

        private var animToken:int = 0;

        /** play a boss animation; if `backMs` > 0 he goes back to Idle after it, unless another animation started meanwhile */
        private function anim(label:String, loop:Boolean, backMs:Number = 0):void
        {
            var mine:int = ++animToken;
            host2.bossAnim(label, loop);
            if (backMs > 0)
            {
                later(backMs, function():void { if (mine == animToken && !over) { host2.bossAnim(ANIM.idle, false); } });
            }
        }

        private function alive(r:String):Boolean
        {
            return hp[r] > 0;
        }

        private function holder():String
        {
            var h:String = currentTaunt();
            return h != null && alive(h) ? h : null;
        }

        override public function startHint():String
        {
            return "Use any skill to start the fight (Legion Revenant taunts first; you taunt when the cue says so)";
        }

        override public function maxHp(role:String):int
        {
            return Math.round(START_HP[role] * (1 + (t < harmonyUntil ? HARMONY_HP : 0)));
        }

        override public function stunned():Boolean
        {
            return false;
        }

        override public function skillName(n:int):String
        {
            var c:Object = DK_SKILLS[playerClass];
            return c && c[n] ? c[n] : null;
        }

        override public function skillCost(name:String):Number
        {
            var base:Number = SKILL[name] ? SKILL[name].mp : 0;
            return name != "taunt" ? base * (1 + 0.25 * dirgeNow(playerRole)) : base;
        }

        private function dirgeNow(r:String):int
        {
            return t < dirgeUntil[r] ? dirgeStacks[r] : 0;
        }

        override public function skillCdMs(name:String):Number
        {
            return name == "taunt" ? LISTED_CD[name] : Dmg.cooldown(LISTED_CD[name], haste());
        }

        private function haste():Number
        {
            return me.haste - 6 * hasteStacks[playerRole];
        }

        override public function swingEvery():Number
        {
            return Dmg.cooldown(AA.cd, haste()) / 1000;
        }

        override public function nextLabel():String
        {
            if (!started)
            {
                return "Waiting for your first skill";
            }
            var best:Object = null;
            for each (var tm:Object in timers2)
            {
                if ((tm.kind == "auto" || tm.kind == "nuke" || tm.kind == "elegy") && (best == null || tm.at < best.at))
                {
                    best = tm;
                }
            }
            var label:String = "";
            if (transforming)
            {
                label = "Darkon regains his health";
            }
            else if (best != null)
            {
                var names:Object = {auto: "Auto attack", nuke: "Nuke", elegy: "Elegy (mouth)"};
                label = names[best.kind] + " in " + Math.max(0, Math.ceil((best.at - t) / 1000)) + " s";
            }
            else
            {
                label = "Next attack soon";
            }
            if (phase < 3 && bossHp > QUIX_STOP && bossHp < QUIX_STOP + 2500000)
            {
                label += " | last Quix";
            }
            else if (phase == 2 && bossHp <= QUIX_STOP && bossHp > QUIX_WINDOW_HI)
            {
                label += " | no Quix";
            }
            else if (phase == 2 && bossHp <= QUIX_WINDOW_HI && !quixInWindow)
            {
                label += " | QUIX NOW";
            }
            return label;
        }

        private function finish(result:String, reason:String):void
        {
            if (over)
            {
                return;
            }
            over = {result: result, reason: reason};
            host2.ended(result, reason);
        }

        private function hit(role:String, dmg:Number, why:String):void
        {
            if (over || !alive(role))
            {
                return;
            }
            dmg = Math.max(0, Math.round(dmg));
            if (role == "lr" && t < lrShieldUntil && lrShield > 0)
            {
                var soaked:Number = Math.min(dmg, lrShield);
                lrShield -= soaked;
                dmg -= soaked;
            }
            hp[role] = Math.max(0, hp[role] - dmg);
            host2.floater(role, "-" + Fight.fmt(dmg), "dmg");
            if (hp[role] <= 0)
            {
                host2.log(DK_NAMES[role] + " died (" + why + ")", "bad");
                finish("lose", DK_NAMES[role] + " died (" + why + ")");
            }
        }

        private function restore(role:String, amount:Number, shown:Boolean):void
        {
            if (over || !alive(role))
            {
                return;
            }
            if (t < healDebuffUntil[role])
            {
                amount *= 0.2; // Phase 3: -80 % healing
            }
            var real:Number = Math.min(maxHp(role) - hp[role], amount);
            hp[role] += real;
            if (real > 0 && shown)
            {
                host2.floater(role, "+" + Fight.fmt(real), "heal");
            }
        }

        private function healAll(amount:Number, shown:Boolean):void
        {
            for each (var r:String in DK_ROLES)
            {
                restore(r, amount, shown && r == playerRole);
            }
        }

        private function buffMax(until:Number):void
        {
            var old:Object = {};
            var r:String;
            for each (r in DK_ROLES)
            {
                old[r] = maxHp(r);
            }
            harmonyUntil = until;
            for each (r in DK_ROLES)
            {
                hp[r] = Math.round(hp[r] / old[r] * maxHp(r));
            }
        }

        // ----------------------------------------------------------------- damage to Darkon
        private function dmgBoss(dmg:Number, crit:Boolean, who:String):void
        {
            if (over || transforming)
            {
                return;
            }
            var d:int = int(Dmg.taken(dmg * takenMult() * (t < depravedUntil ? 1.3 : 1), 1, CAP));
            if (who == "player" && crit && critReversed[playerRole])
            {
                // the Elegies were taunted twice in a row: the player's crits heal Darkon
                bossHp = Math.min(bossMaxHp, bossHp + d);
                host2.floater(null, "Crit heals Darkon", "bad");
                return;
            }
            if (d <= 0)
            {
                return;
            }
            bossHp = Math.max(0, bossHp - d);
            host2.bossDamage(d, crit, who);
            checkThresholds();
        }

        /** what multiplies the raid's damage: The Cycle's End (+10 % per stack), Phase 3's Major auras (immune for 50 s, then +200 %) */
        private function takenMult():Number
        {
            var m:Number = 1 + 0.1 * cycleStacks;
            if (phase == 3)
            {
                m *= (t - phaseStart < IMMUNE_MS) ? 0 : 3;
            }
            return m;
        }

        private function checkThresholds():void
        {
            if (over)
            {
                return;
            }
            if (bossHp <= 0)
            {
                finish("win", "Ultra Darkon defeated");
                return;
            }
            if (phase == 1 && bossHp <= HP_P2 && !transforming)
            {
                transitionTo(2);
            }
            if (phase == 2 && !transforming)
            {
                if (bossHp < QUIX_STOP && !cuedStop)
                {
                    cuedStop = true;
                }
                if (bossHp < QUIX_WINDOW_LO && !quixInWindow)
                {
                    finish("lose", "Quix was not used between 5 000 000 and 4 500 000 HP");
                    return;
                }
                if (bossHp <= HP_REGAIN)
                {
                    transitionTo(3);
                }
            }
        }

        /** Recitative (Phase 2) at 70 % and Aria (Phase 3) at 20 %: what he had queued is cancelled, the Swap pattern starts */
        private function transitionTo(next:int):void
        {
            transforming = true;
            var keep:Array = [];
            for each (var tm:Object in timers2)
            {
                if (tm.kind == "")
                {
                    keep.push(tm);
                }
            }
            timers2 = keep;
            anim(ANIM.transform, false, ANIM_MS.transform);
            var r:String;
            if (next == 2)
            {
                host2.announce("Prepare for the next act!");
                host2.log("Phase 2 (Recitative): every auto takes 6 % haste (22 stacks); taunting the mouth removes it, but not twice in a row", "bad");
                for each (r in DK_ROLES)
                {
                    elegyDebuffUntil[r] = 0; // the Overture auras are removed
                }
            }
            else
            {
                host2.announce("No\u2026 It can't end like this\u2026");
                host2.log("Phase 3 (Aria): Darkon heals to 20 000 000 HP and is immune for 50 s; the mouth now raises your mana costs", "bad");
                var from:Number = bossHp;
                later(1000, function():void { bossHp = from + (HP_P3 - from) * 0.4; });
                later(2000, function():void { bossHp = from + (HP_P3 - from) * 0.8; });
            }
            nukeCount = 0;
            later(3000, function():void {
                if (next == 3)
                {
                    bossMaxHp = HP_P3;
                    bossHp = HP_P3;
                    for each (var q:String in DK_ROLES) // Aria: devastating physical damage to everybody (ignores Focus)
                    {
                        hit(q, 0.5 * maxHp(q), "Aria");
                    }
                    if (over)
                    {
                        return;
                    }
                }
                phase = next;
                phaseStart = t;
                transforming = false;
                for each (var r2:String in DK_ROLES)
                {
                    hasteStacks[r2] = 0;
                    growUntil[r2] = 0;
                    critReversed[r2] = false;
                }
                nextPattern = SWAP;
                scheduleRun(t + 1500);
            });
        }

        // ------------------------------------------------------------------ the pattern
        /** one run of a pattern (A auto, N nuke, E Elegy); the next run is scheduled when this one is over */
        private function scheduleRun(start:Number):void
        {
            var pat:String = nextPattern;
            nextPattern = (phase == 1) ? LOOP : SWAP;
            for (var i:int = 0; i < pat.length; i++)
            {
                var kind:String = pat.charAt(i);
                var at:Number = start + i * SLOT;
                if (kind == "A")
                {
                    laterAt(at, auto, "auto");
                }
                else if (kind == "N")
                {
                    laterAt(at, nuke, "nuke");
                }
                else
                {
                    scheduleElegy(at);
                }
            }
            var end:Number = start + pat.length * SLOT;
            laterAt(end - 100, function():void {
                if (!transforming && !over)
                {
                    scheduleRun(end);
                }
            }, "seq");
        }

        /** the Elegy at `at`; the Revenant takes the even ones and you the odd ones, the taunts are scheduled to match */
        private function scheduleElegy(at:Number):void
        {
            var hitAt:Number = at + ELEGY_HIT_AFTER;
            var mine:Boolean = elegyCount % 2 == 1;
            elegyCount++;
            laterAt(at, elegyOpen, "elegy");
            laterAt(hitAt, elegyLand, "x");
            if (mine)
            {
                laterAt(hitAt - LOO_CUE_BEFORE, function():void { host2.mechanic("loo", "taunt", 0, 0); }, "tn");
            }
            else
            {
                laterAt(hitAt - LR_TAUNT_BEFORE, function():void { if (alive("lr")) { doSkill("taunt", "lr", false); } }, "tn");
            }
        }

        private var autoSwing:int = 0;

        /** how hard his autos hit: P1 each nuke aura adds to it, P2 the Recitative and Child of the Empress, P3 C Major for 50 s (then 0) */
        private function autoPower():Number
        {
            if (phase == 1)
            {
                return 1 + 0.12 * nukeCount;
            }
            if (phase == 2)
            {
                return 1.3 + 0.04 * Math.min(22, nukeCount);
            }
            return (t - phaseStart < IMMUNE_MS) ? 1.35 : 0;
        }

        private function takenBy(r:String, base:Number):Number
        {
            return base * (Dmg.takenMul(Dmg.profile(r), false) / 0.55) * (r == playerRole ? 1 : 0.6);
        }

        private function missedTaunt(what:String):void
        {
            casts.missedTaunt++;
            host2.floater(playerClass, "Missed Taunt", "bad");
            finish("lose", "Missed Taunt (" + what + ": nobody held Darkon, so everybody was hit)");
        }

        /** autos hit all four players and ignore Focus */
        private function auto():void
        {
            if (transforming)
            {
                return;
            }
            anim((autoSwing++ % 2 == 0) ? ANIM.auto1 : ANIM.auto2, false, ANIM_MS.auto);
            later(HIT_AT.auto, function():void {
                var power:Number = autoPower();
                for each (var r:String in DK_ROLES)
                {
                    if (power > 0)
                    {
                        hit(r, takenBy(r, AUTO * rnd(0.9, 1.1) * power), "Darkon's auto attack");
                    }
                    if (over)
                    {
                        return;
                    }
                    if (phase == 2)
                    {
                        hasteStacks[r] = Math.min(22, hasteStacks[r] + 1); // Realm of the Arcana: -6 % haste per auto
                    }
                    if (phase == 3)
                    {
                        healDebuffUntil[r] = t + 8000; // Requiem for the Wicked: -80 % healing
                    }
                }
            });
        }

        /** 90 % of the current HP of the player who holds the taunt (any player if nobody does) */
        private function nuke():void
        {
            if (transforming)
            {
                return;
            }
            anim(ANIM.nuke, false, ANIM_MS.nuke);
            later(HIT_AT.nuke, function():void {
                var h:String = holder();
                if (h == null)
                {
                    var live:Array = [];
                    for each (var q:String in DK_ROLES)
                    {
                        if (alive(q))
                        {
                            live.push(q);
                        }
                    }
                    h = live[int(Math.random() * live.length)];
                }
                nukeCount++;
                var victim:String = h;
                hit(victim, 0.9 * hp[victim], "Darkon's nuke");
                if (over)
                {
                    return;
                }
                if (phase == 3)
                {
                    dotUntil[victim] = t + 8000; // The Last Symphony
                }
                // the raid's healer follows the auto counting: the nuked player is healed right after (not reduced by Phase 3's debuff)
                later(1000, function():void {
                    if (alive(victim))
                    {
                        var real:Number = Math.min(maxHp(victim) - hp[victim], 0.45 * maxHp(victim));
                        hp[victim] += real;
                        if (victim == playerRole && real > 0)
                        {
                            host2.floater(victim, "+" + Fight.fmt(real), "heal");
                        }
                    }
                });
            });
        }

        private function elegyOpen():void
        {
            if (transforming)
            {
                return;
            }
            host2.log("Darkon opens his mouth: Elegy (taunt it, it lands in 2 s)", "");
            anim(ANIM.elegyOpen, false);
            var mine:int = animToken;
            later(ANIM_MS.elegyHold, function():void { if (mine == animToken) { anim(ANIM.elegyHold, true); } });
        }

        private function elegyLand():void
        {
            if (transforming || over)
            {
                return;
            }
            anim(ANIM.elegyHit, false, ANIM_MS.elegyHit);
            var h:String = holder();
            if (h == null)
            {
                missedTaunt("Elegy");
                return;
            }
            casts.taunted++;
            var again:Boolean = t < elegyDebuffUntil[h];  // the same character twice within 8 s
            var third:Boolean = t < growUntil[h] && again;
            hit(h, takenBy(h, AUTO * (phase == 1 ? 1.9 : (phase == 2 ? 2.3 : (t - phaseStart < IMMUNE_MS ? 2.7 : 0.8)))), "Elegy");
            if (over)
            {
                return;
            }
            if (phase == 1)
            {
                if (again)
                {
                    host2.log(DK_NAMES[h] + " was hit by two Elegies: Captive Audience, stunned", "bad");
                    finish("lose", DK_NAMES[h] + " was hit by two Elegies within 8 s and got stunned (take them in turn)");
                    return;
                }
                elegyDebuffUntil[h] = t + DEBUFF_MS;
            }
            else if (phase == 2)
            {
                hasteStacks[h] = 0; // Seed Planted removes the haste debuff
                if (third)
                {
                    host2.log(DK_NAMES[h] + " was harvested: three Elegies in a row", "bad");
                    finish("lose", DK_NAMES[h] + " taunted three Elegies in a row (Harvested)");
                    return;
                }
                if (again)
                {
                    growUntil[h] = t + DEBUFF_MS;
                    critReversed[h] = true; // Grown: crits reversed
                    host2.log(DK_NAMES[h] + " has Grown: crits are reversed (they heal Darkon) - stop taunting", "bad");
                    later(DEBUFF_MS, function():void { critReversed[h] = t < growUntil[h]; });
                }
                elegyDebuffUntil[h] = t + DEBUFF_MS;
            }
            else
            {
                dirgeStacks[h] = Math.min(22, dirgeNow(h) + 1); // Dirge of Astravia: +25 % mana costs per stack, 12 s
                dirgeUntil[h] = t + 12000;
            }
        }

        // ------------------------------------------------------- the player's skills
        override public function skillReady(n:int):Boolean
        {
            return !over && t >= cd[n];
        }

        override public function swing():Object
        {
            var c:Boolean = Dmg.rollCrit(me);
            var d:Number = Dmg.hit(me, AA.f, AA.src, AA.type, c, hp[playerRole], GEAR) * rnd(0.95, 1.05);
            mana = Math.min(100, mana + Dmg.manaFor(d, c, me.hp));
            return {dmg: d, crit: c};
        }

        override public function playerHit(dmg:Number, isCrit:Boolean):void
        {
            dmgBoss(dmg, isCrit, "player");
        }

        override public function cast(n:int):Boolean
        {
            var name:String = skillName(n);
            if (name == null || !skillReady(n))
            {
                return false;
            }
            var cost:Number = skillCost(name);
            if (mana < cost)
            {
                host2.floater(playerRole, "Not enough mana", "bad");
                return false;
            }
            mana -= cost;
            if (!started)
            {
                started = true;
                phaseStart = 0;
                host2.announce("The curtain rises on our final performance.");
                scheduleRun(FIRST_SLOT);
            }
            cd[n] = t + skillCdMs(name);
            if (name == "quix")
            {
                if (phase < 3 && bossHp < QUIX_STOP && bossHp > QUIX_WINDOW_HI)
                {
                    host2.log("Quix used below 13 000 000 HP", "bad");
                    finish("lose", "Quix was used after 13 000 000 HP (not until 5 000 000)");
                    return true;
                }
                if (phase == 2 && bossHp <= QUIX_WINDOW_HI && bossHp >= QUIX_WINDOW_LO)
                {
                    quixInWindow = true;
                    host2.log("Quix in the 5 000 000 - 4 500 000 window", "good");
                }
            }
            doSkill(name, playerClass, true);
            for (var k:int = 2; k <= 6; k++)
            {
                if (cd[k] - t < 1000)
                {
                    cd[k] = Math.max(cd[k], t + GCD);
                }
            }
            return true;
        }

        private function healingOrdinance(actor:String):Number
        {
            return Dmg.heal(me, 0.5, "SP2", true, 0) * GEAR / 6 * HEAL_BOOST;
        }

        private function doSkill(name:String, actor:String, manual:Boolean):void
        {
            host2.castFx(name, actor);
            switch (name)
            {
                case "taunt":
                    tauntRole = actor;
                    tauntUntil = t + TAUNT_MS;
                    break;
                case "depraved":
                    depravedUntil = t + 12000;
                    lrShield = 0.3 * Dmg.profile("lr").sp * Dmg.WEAPON_BOOST;
                    lrShieldUntil = t + 12000;
                    lrHotUntil = t + 12000;
                    break;
                case "harmony":
                    buffMax(t + 10000);
                    break;
                case "ordinance":
                    ordinanceUntil = t + 25000;
                    healAll(healingOrdinance(actor), manual);
                    break;
                case "axiom":
                    axiomUntil = t + 10000;
                    break;
                case "quix":
                    quixUntil = t + 4000;
                    break;
            }
        }

        override public function activeBuffs():Array
        {
            var list:Array = [];
            var frac:Function = function(until:Number, total:Number):Number { return Math.max(0, Math.min(1, (until - t) / total)); };
            var left:Function = function(until:Number):String { return String(Math.ceil((until - t) / 1000)); };
            if (currentTaunt() != null)
            {
                list.push({name: "focus", count: "", frac: frac(tauntUntil, TAUNT_MS)});
            }
            if (t < quixUntil)
            {
                list.push({name: "quix", count: left(quixUntil), frac: frac(quixUntil, 4000)});
            }
            if (hasteStacks[playerRole] > 0)
            {
                list.push({name: "somber", count: String(hasteStacks[playerRole]), frac: -1}); // -6 % haste per stack
            }
            if (t < depravedUntil)
            {
                list.push({name: "depraved", count: left(depravedUntil), frac: frac(depravedUntil, 12000)});
            }
            if (t < harmonyUntil)
            {
                list.push({name: "harmony", count: left(harmonyUntil), frac: frac(harmonyUntil, 10000)});
            }
            if (t < ordinanceUntil)
            {
                list.push({name: "ordinance", count: left(ordinanceUntil), frac: frac(ordinanceUntil, 25000)});
            }
            if (t < axiomUntil)
            {
                list.push({name: "axiom", count: left(axiomUntil), frac: frac(axiomUntil, 10000)});
            }
            return list;
        }

        // ------------------------------------------------------ the sim's own characters
        private function npcPlay():void
        {
            // (the Revenant's taunts and your taunt cues are scheduled with the Elegies: see scheduleElegy)
            if (alive("lr") && t >= npcDepravedAt)
            {
                npcDepravedAt = t + 6000;
                doSkill("depraved", "lr", false);
            }
            // the player's cues for Quix
            if (phase < 3 && !cuedStop && bossHp < QUIX_STOP + 1500000)
            {
                cuedStop = true;
                host2.mechanic("loo", "quixstop", 0, 0);
            }
            if (phase == 2 && !cuedWindow && bossHp < QUIX_WINDOW_HI + 700000)
            {
                cuedWindow = true;
                host2.mechanic("loo", "quixnow", 0, 0);
            }
        }

        // ------------------------------------------------------------ engine
        override public function step(dtMs:Number):void
        {
            if (over || !started)
            {
                return;
            }
            t += dtMs;
            mana = Math.min(100, mana + Dmg.MANA_REGEN * dtMs / 1000);
            var guard:int = 0;
            while (guard++ < 1000)
            {
                var k:int = -1;
                for (var i:int = 0; i < timers2.length; i++)
                {
                    if (timers2[i].at <= t && (k < 0 || timers2[i].at < timers2[k].at))
                    {
                        k = i;
                    }
                }
                if (k < 0)
                {
                    break;
                }
                var tm:Object = timers2.splice(k, 1)[0];
                tm.fn();
                if (over)
                {
                    return;
                }
            }
            if (phase == 1 && t >= ENRAGE_MS)
            {
                host2.log("Darkon's song reaches its end: he one-shots everybody", "bad");
                finish("lose", "Phase 1 took longer than 72 s: Darkon one-shots everybody");
                return;
            }
            if (t >= cycleAt)
            {
                cycleAt += CYCLE_MS;
                cycleStacks = Math.min(10, cycleStacks + 1);
                host2.announce("Darkon's defenses decrease as The Fool leaves his body.");
                host2.log("The Cycle's End: Darkon takes +" + (10 * cycleStacks) + " % damage", "");
            }
            if (curtainAt < 0 && t >= CURTAIN_MS)
            {
                curtainAt = t + CURTAIN_CHARGE;
                host2.announce("The time has come for the curtain to rise upon a new dawn. May you finally rest.");
                anim(ANIM.transform, false);
            }
            if (curtainAt >= 0 && t >= curtainAt)
            {
                host2.log("Curtain Call: 100 000 337 true damage to everybody", "bad");
                finish("lose", "Curtain Call: the fight took longer than 4:30");
                return;
            }
            npcPlay();
            if (t >= tickAt)
            {
                tickAt += 1000;
                for each (var q:String in DK_ROLES)
                {
                    restore(q, LIFESTEAL, false);
                    if (q == "lr" && t < lrHotUntil)
                    {
                        restore(q, 0.1 * maxHp("lr"), false);
                    }
                    if (t < dotUntil[q])
                    {
                        hit(q, takenBy(q, AUTO * 0.25), "damage over time");
                        if (over)
                        {
                            return;
                        }
                    }
                }
            }
            // the sim's characters hit on their own (each hit capped)
            if (t >= partyAt && !transforming)
            {
                var tick:Number = rnd(600, 1100);
                var d:Number = 0;
                for each (var w:String in DK_ROLES)
                {
                    if (w != playerRole && alive(w))
                    {
                        var pw:Object = Dmg.profile(w);
                        var caster:Boolean = pw.sp > pw.ap;
                        var perHit:Number = Dmg.average(pw, 1.0, caster ? "SP2" : "AP2", caster ? "magic" : "phys") * GEAR;
                        var hits:Number = 1000 / Dmg.cooldown(1500, pw.haste) * tick / 1000;
                        d += Dmg.taken(perHit, 1, CAP) * hits;
                    }
                }
                d *= takenMult();
                if (d > 0)
                {
                    bossHp = Math.max(0, bossHp - d);
                    host2.bossDamage(int(d), false, "party");
                    checkThresholds();
                    if (over)
                    {
                        return;
                    }
                }
                partyAt = t + tick;
            }
        }
    }
}

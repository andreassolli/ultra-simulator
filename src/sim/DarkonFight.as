package sim
{
    /**
     * Ultra Darkon fight rules (the Lord of Order's fight), from the AQW wiki (Darkon the Conductor) and the community guide.
     *
     * Darkon: Phase 1 22 222 222 -> 15 555 555 HP, Phase 2 15 555 555 -> 4 444 444 HP, then he regains his health (Phase 3, 20 000 000 -> 0).
     * He attacks in fixed blocks of 15 s: autos (every 2.25 s), a nuke now and then, and one "Elegy" (the mouth animation, tauntable) that
     * lands 12 s into each block. Pattern, as in the guide: opening block auto, auto, Elegy; second block auto, auto, nuke, Elegy; then it
     * loops auto, auto, Elegy / auto, nuke, Elegy. Every attack only hits whoever holds the taunt, and one that lands with nobody holding
     * it loses the fight.
     *
     * Taunts: the Legion Revenant (played by the sim) taunts at the start and then every 10 s (the skill's cooldown); the player's Lord of
     * Order has to taunt when the Revenant's 6 s taunt is nearly over (it has to be between 4 and 6 s after it, aim for 4.5 s) and
     * keeps that up, so the two of them keep the boss held for the whole fight and the Elegies fall on them in turn. The other two
     * characters (StoneCrusher and Chrono ShadowSlayer) are played by the sim.
     *   Phase 1: every auto -50 % hit chance (does not stack); two Elegies on the same character stun it (loses); the phase has to end
     *            before 72 s or Darkon one-shots everybody.
     *   Phase 2: every auto -6 % haste on the one it hits (22 stacks); taunting an Elegy removes the haste stacks; the same character
     *            holding two Elegies in a row has its crits reversed (they heal Darkon), three in a row kills it.
     *   Phase 3: autos hit harder until 50 s into the phase; taunting an Elegy raises your mana costs; nukes add a damage over time for
     *            8 s; autos give an 80 % healing debuff.
     * Quix (Lord of Order, skill 5): it may be used from the start, but not any more from 13 000 000 HP on (before he regains health), and
     * it has to be used once between 5 000 000 and 4 500 000 HP. Using it in between, or missing the window, loses. Anybody dying loses too.
     *
     * The raid's damage is tuned so that the fight takes about three minutes: see GEAR and PHASE_DAMAGE.
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
        private static const BLOCK_MS:int = 15000;
        private static const FIRST_BLOCK:int = 1000;
        private static const ELEGY_CHARGE_AT:int = 8000;
        private static const ELEGY_HIT_AT:int = 12000;
        private static const TAUNT_MS:int = 6000;
        private static const LR_LOOP_MS:int = 10000;          // the Revenant taunts whenever its cooldown allows
        private static const LOO_CUE_AFTER:int = 4200;        // "taunt now" this long after the Revenant's taunt
        private static const CAP:Number = 150000;
        private static const GEAR:Number = 33;
        /** how much of the raid's damage is kept in each phase: tuned for roughly 40 s / 60 s / 85 s */
        private static const PHASE_DAMAGE:Object = {1: 1.0, 2: 1.0, 3: 1.0};
        private static const AUTO:Number = 850;               // Darkon's auto on a tank (tuned, see README)
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
        private var blockIdx:int = 0;
        private var blockStart:Number = FIRST_BLOCK;
        private var lastElegyHolder:String = "";
        private var npcLrAt:Number = 300;
        private var npcLrLast:Number = -99999;
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
            return "Use any skill to start the fight (Legion Revenant taunts first; you taunt 4.5 s later)";
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
            return t < manaDebuffUntil && name != "taunt" ? base * 1.5 : base;
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
                label = "Auto attack in " + Math.max(0, Math.ceil((blockStart + BLOCK_MS + 500 - t) / 1000)) + " s";
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
            var d:int = int(Dmg.taken(dmg * PHASE_DAMAGE[phase] * (t < depravedUntil ? 1.3 : 1), 1, CAP));
            if (who == "player" && crit && critReversed[playerRole])
            {
                // the Elegies were taunted twice in a row: the player's crits heal Darkon
                bossHp = Math.min(bossMaxHp, bossHp + d);
                host2.floater(null, "Crit heals Darkon", "bad");
                return;
            }
            bossHp = Math.max(0, bossHp - d);
            host2.bossDamage(d, crit, who);
            checkThresholds();
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
            if (phase == 1 && bossHp <= HP_P2)
            {
                phase = 2;
                phaseStart = t;
                host2.log("Phase 2: every auto takes 6 % haste (22 stacks); taunting the mouth removes it, but not twice in a row", "bad");
                host2.announce("The Conductor raises his baton!");
                host2.bossAnim("PowerUp", false);
                later(1600, function():void { host2.bossAnim("Idle", false); });
            }
            if (phase == 2)
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
                    transform();
                }
            }
        }

        /** Darkon regains his health: Phase 3 */
        private function transform():void
        {
            transforming = true;
            // what he had queued is cancelled; the blocks go on on the same beat (the Elegies stay on alternate characters)
            var keep:Array = [];
            for each (var tm:Object in timers2)
            {
                if (tm.kind == "")
                {
                    keep.push(tm); // (the boss' own attacks and the block clock are cancelled)
                }
            }
            timers2 = keep;
            host2.announce("Darkon: \"The song is not over!\"");
            host2.log("Darkon regains his health: Phase 3 (20 000 000 HP)", "bad");
            host2.bossAnim("PowerUp", false);
            var from:Number = bossHp;
            later(1000, function():void { bossHp = from + (HP_P3 - from) * 0.4; });
            later(2000, function():void { bossHp = from + (HP_P3 - from) * 0.8; });
            later(3000, function():void {
                bossMaxHp = HP_P3;
                bossHp = HP_P3;
                phase = 3;
                phaseStart = t;
                transforming = false;
                for each (var r:String in DK_ROLES)
                {
                    elegyRun[r] = 0;
                    critReversed[r] = false;
                    hasteStacks[r] = 0;
                }
                lastElegyHolder = "";
                host2.bossAnim("Idle", false);
                // the next block on the old beat
                var next:Number = blockStart + BLOCK_MS;
                while (next < t + 500)
                {
                    next += BLOCK_MS;
                }
                scheduleBlock(next);
            });
        }

        // ------------------------------------------------------------------ the pattern
        /** the attacks of block n: [kind, offset in ms] */
        private function blockPlan(n:int):Array
        {
            if (n == 0)
            {
                return [["auto", 500], ["auto", 2750]];
            }
            if (n == 1)
            {
                return [["auto", 500], ["auto", 2750], ["nuke", 5000]];
            }
            return (n % 2 == 0) ? [["auto", 500], ["auto", 2750]] : [["auto", 500], ["nuke", 2750]];
        }

        private function scheduleBlock(start:Number):void
        {
            blockStart = start;
            var plan:Array = blockPlan(blockIdx);
            for each (var a:Array in plan)
            {
                var kind:String = a[0];
                laterAt(start + a[1], makeAttack(kind), kind);
            }
            laterAt(start + ELEGY_CHARGE_AT, function():void { elegyStart(); }, "elegy");
            laterAt(start + ELEGY_HIT_AT, function():void { elegyHit(); }, "x");
            blockIdx++;
            laterAt(start + BLOCK_MS - 200, function():void {
                if (!transforming && !over)
                {
                    scheduleBlock(start + BLOCK_MS);
                }
            }, "blk");
        }

        private function makeAttack(kind:String):Function
        {
            return function():void {
                if (transforming)
                {
                    return;
                }
                if (kind == "auto")
                {
                    auto();
                }
                else
                {
                    nuke();
                }
            };
        }

        private var autoSwing:int = 0;

        private function autoPower():Number
        {
            if (phase == 3 && t - phaseStart < 50000)
            {
                return 1.3; // "auto attacks hit harder until 50 s into the phase"
            }
            return phase == 2 ? 1.2 : 1;
        }

        private function takenBy(r:String, base:Number):Number
        {
            return base * (Dmg.takenMul(Dmg.profile(r), false) / 0.55) * (r == playerRole ? 1 : 0.6);
        }

        private function missedTaunt(what:String):void
        {
            casts.missedTaunt++;
            host2.floater(playerClass, "Missed Taunt", "bad");
            finish("lose", "Missed Taunt (" + what + ": nobody held Darkon)");
        }

        private function auto():void
        {
            host2.bossAnim((autoSwing++ % 2 == 0) ? "Attack1" : "Attack2", false);
            later(450, function():void {
                var h:String = holder();
                if (h == null)
                {
                    missedTaunt("auto attack");
                    return;
                }
                casts.taunted++;
                hit(h, takenBy(h, AUTO * rnd(0.9, 1.1) * autoPower()), "Darkon's auto attack");
                if (over)
                {
                    return;
                }
                if (phase == 2)
                {
                    hasteStacks[h] = Math.min(22, hasteStacks[h] + 1); // -6 % haste, stacking
                }
                if (phase == 3)
                {
                    healDebuffUntil[h] = t + 8000; // -80 % healing
                }
            });
            later(1200, function():void { host2.bossAnim("Idle", false); });
        }

        private function nuke():void
        {
            host2.bossAnim("Attack3", false);
            later(800, function():void {
                var h:String = holder();
                if (h == null)
                {
                    missedTaunt("nuke");
                    return;
                }
                casts.taunted++;
                hit(h, takenBy(h, AUTO * 2.3 * rnd(0.9, 1.1) * (phase == 3 ? 1.15 : 1)), "Darkon's nuke");
                if (!over && phase == 3)
                {
                    dotUntil[h] = t + 8000; // the nukes add a damage over time for 8 s
                }
            });
            later(1500, function():void { host2.bossAnim("Idle", false); });
        }

        private function elegyStart():void
        {
            if (transforming)
            {
                return;
            }
            host2.log("Darkon opens his mouth: Elegy (taunt it, it lands in 4 s)", "");
            host2.bossAnim("Charge", false);
            later(900, function():void { host2.bossAnim("Chargeloop", true); });
        }

        private function elegyHit():void
        {
            if (transforming || over)
            {
                return;
            }
            host2.bossAnim("ChargeAttack", false);
            later(1500, function():void { host2.bossAnim("Idle", false); });
            var h:String = holder();
            if (h == null)
            {
                missedTaunt("Elegy");
                return;
            }
            casts.taunted++;
            var run:int = (h == lastElegyHolder) ? elegyRun[h] + 1 : 1;
            for each (var r:String in DK_ROLES)
            {
                elegyRun[r] = r == h ? run : 0;
            }
            lastElegyHolder = h;
            hit(h, takenBy(h, AUTO * (phase == 1 ? 1.9 : (phase == 2 ? 2.3 : 2.7))), "Elegy");
            if (over)
            {
                return;
            }
            if (phase == 1)
            {
                if (run >= 2)
                {
                    host2.log(DK_NAMES[h] + " was hit by two Elegies: stunned", "bad");
                    finish("lose", DK_NAMES[h] + " was hit by two Elegies in a row and got stunned (taunt them in turn)");
                }
            }
            else if (phase == 2)
            {
                hasteStacks[h] = 0; // taunting the mouth removes the haste debuff
                if (run == 2)
                {
                    critReversed[h] = true;
                    host2.log(DK_NAMES[h] + " taunted two Elegies in a row: crits are reversed (they heal Darkon) - stop taunting", "bad");
                }
                else if (run >= 3)
                {
                    host2.log(DK_NAMES[h] + " taunted three Elegies in a row", "bad");
                    finish("lose", DK_NAMES[h] + " taunted three Elegies in a row");
                }
            }
            else if (h == playerRole)
            {
                manaDebuffUntil = t + 20000; // taunting the mouth in Phase 3 costs mana
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
                scheduleBlock(FIRST_BLOCK);
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
            // the Legion Revenant takes the taunt first and then every time its 10 s cooldown is up
            if (alive("lr") && t >= npcLrAt)
            {
                npcLrAt = t + LR_LOOP_MS;
                npcLrLast = t;
                doSkill("taunt", "lr", false);
                laterAt(t + LOO_CUE_AFTER, function():void { host2.mechanic("loo", "taunt", 0, 0); });
            }
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
                if (d > 0)
                {
                    d *= PHASE_DAMAGE[phase];
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

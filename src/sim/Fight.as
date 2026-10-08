package sim
{
    /**
     * Ultra Speaker fight rules. Boss rotation, cast times, cooldowns, damage
     * ranges, taunt / seal / quix / zone requirements and the Lord of Order,
     * ArchPaladin and Legion Revenant numbers come from the web simulator
     * (speaker.js, lordoforder.js, archpaladin.js, legionrevenant.js,
     * party-manager.js). All times are in milliseconds.
     */
    public class Fight
    {
        public static const PATTERN:Array = [
            "auto", "auto", "auto", "auto", "truth", "listen",
            "zone", // new cycle starts here (index 6)
            "truth", "auto", "listen", "truth", "auto", "auto",
            "zone", "listen", "truth", "auto", "auto", "truth", "listen",
            "zone", "truth", "auto", "listen", "truth", "auto", "auto",
            "zone", "listen", "truth", "auto", "auto", "truth", "listen"
        ];

        /** pattern index -> role that must hold the boss for that cast */
        public static const MECHANICS:Object = {
            4: "lr", 5: "loo", 7: "ap", 9: "loo", 10: "loo", 14: "lr", 15: "lr", 18: "loo", 19: "loo",
            21: "ap", 23: "lr", 24: "lr", 27: "loo", 28: "loo", 31: "lr", 32: "loo", 33: "loo"
        };

        public static const ZONE_ROLES:Object = {1: "dps", 2: "lr", 3: "ap", 4: "loo"};
        public static const ROLES:Array = ["ap", "lr", "loo", "dps"];
        public static const ROLE_NAMES:Object = {ap: "ArchPaladin", lr: "Legion Revenant", loo: "Lord of Order", dps: "DPS"};

        private static const TIMINGS:Object = {auto: 2000, truth: 7000, listen: 12000, zone: 16000};
        private static const CAST:Object = {auto: 1200, truth: 2000, listen: 2000, zone: 3000};

        private static const MAX_HP:Object = {
            ap: [3670, 4000, 4400],
            lr: [2910, 3090, 3310],
            loo: [3505, 3745, 4035],
            dps: [2810, 2975, 3170]
        };
        private static const START_HP:Object = {ap: 3670, lr: 2910, loo: 3505, dps: 2450};

        private static const AP_ROTATION:Object = {
            1: [2, 4], 2: [2, 3], 3: [2], 4: [2], 5: [3, 2], 6: [2], 7: [4, 2], 8: [2, 3], 9: [2], 10: [4, 2],
            11: [2], 12: [2], 13: [3], 14: [3, 2], 15: [4, 2], 16: [3, 2], 17: [2], 18: [2], 19: [3, 2], 20: [4, 2],
            21: [3, 2], 22: [2], 23: [3, 2], 24: [4, 2], 25: [2, 3], 26: [2, 3], 27: [], 28: [3, 2], 29: [4, 2],
            30: [2], 31: [3, 2], 32: [2], 33: [3, 2]
        };

        private static const LOO_ROTATION:Object = {
            1: [3, 2, 4, 5], 2: [3, 2, 4], 3: [3, 2, 4, 5], 4: [], 5: [3, 2, 4], 7: [2, 4], 8: [3], 9: [2, 4],
            12: [2, 4, 3], 14: [4, 3, 2], 16: [], 17: [2, 4, 5], 18: [3], 19: [3, 2, 4], 21: [2, 4], 22: [], 23: [3, 2, 4],
            24: [], 25: [3], 26: [], 27: [3, 4, 2], 28: [4, 3, 2], 31: [2, 4, 5], 32: [3], 33: [2, 4]
        };

        /** player skill slots 2-6 per class (slot 1 is the auto attack) */
        public static const CLASS_SKILLS:Object = {
            loo: {2: "harmony", 3: "ordinance", 4: "axiom", 5: "quix", 6: "taunt"},
            ap: {2: "commandment", 3: "heal", 4: "seal", 5: "eden", 6: "taunt"},
            lr: {2: "shade", 3: "wicked", 4: "empowerment", 5: "anathema", 6: "taunt"}
        };
        public static const SKILL_CD:Object = {
            harmony: 4000, ordinance: 8000, axiom: 4000, quix: 4000, taunt: 10000,
            commandment: 2500, heal: 5000, seal: 12500, eden: 12500,
            shade: 3000, wicked: 3000, empowerment: 3000, anathema: 6000
        };

        private static const HARMONY_DUR:int = 10000;
        private static const ORDINANCE_DUR:int = 25000;
        private static const ORDINANCE_HEAL:int = 2700;
        private static const AXIOM_DUR:int = 10000;
        private static const QUIX_DUR:int = 4000;
        private static const QUIX_LOCKOUT:int = 25000;
        private static const TAUNT_DUR:int = 6000;
        private static const GCD:int = 400;
        /** the Speaker's autos and Truths hit harder than the first calibration (they felt too weak) */
        private static const DAMAGE_BOOST:Number = 1.4;

        // ---------------------------------------------------------------- state
        public var t:Number = 0;
        public var started:Boolean = false; // the fight starts with the player's first skill
        public var targetIsBlade:Boolean = false; // Ultra Nulgath: the Overfiend Blade is the player's target
        public var targetSel:String = "boss"; // Ultra Gramiel: the player's target, "boss" | "cl" | "cr" (left / right Grace Crystal)
        public var mana:Number = 100; // 0-100, only the Dage / Drakath fights spend it
        public var playerRole:String;
        public var over:Object = null; // {result, reason}
        public var bossMaxHp:Number;
        public var bossHp:Number;
        public var hp:Object;
        public var somber:Object;
        public var armor:Object;
        public var harmonyBuff:Boolean = false;
        public var apHealBuff:Boolean = false;
        public var harmonyUntil:Number = 0;
        public var apHealUntil:Number = 0;
        public var tauntRole:String = null;
        public var tauntUntil:Number = 0;
        public var stunUntil:Number = 0;
        public var magiaBurnUntil:Number = 0;
        public var ordinanceUntil:Number = 0;
        public var axiomUntil:Number = 0;
        public var quixUntil:Number = 0;
        public var quixAvailableAt:Number = 0;
        public var lrEmpowerUntil:Number = 0;
        public var lrEmpowerReady:Number = 0;
        public var apReduction:String = null; // null | seal | eden
        public var apReductionUntil:Number = 0;
        public var cd:Array = [0, 0, 0, 0, 0, 0, 0];
        public var counters:Object = {harmony: 0, ordinance: 0, axiom: 0, seal: 0, quix: 0, notBroken: 0};
        public var ruleIdx:int = 0; // current position in PATTERN
        public var zoneAt:Number = -99999;     // when the last Equal zone appeared (Legion Revenant has to use Decay in the 3 s after it)
        public var decayUsed:Boolean = false;
        public var lastTruthHit:Number = -99999; // when the last Truth landed
        public var raidDps:Array;

        private var host:IFightHost;
        private var timers:Array = [];
        private var sealToken:int = 0;
        private var edenToken:int = 0;
        private var busy:Boolean = false;
        private var busyUntil:Number = 0;
        private var truthN:int = 1;
        private var zoneN:int = 1;
        private var last:Object = {};
        private var mech:String = null;
        private var partyDrainAt:Number = 600;

        public function Fight(host:IFightHost, role:String, bossHp:Number, raidDps:Array)
        {
            this.host = host;
            this.playerRole = role;
            this.bossMaxHp = bossHp;
            this.bossHp = bossHp;
            this.raidDps = raidDps;
            hp = {};
            somber = {};
            armor = {};
            for each (var r:String in ROLES)
            {
                hp[r] = START_HP[r];
                somber[r] = 0;
                armor[r] = 0.8;
            }
        }

        // -------------------------------------------------------------- helpers
        private static function rnd(a:Number, b:Number):Number
        {
            return a + Math.random() * (b - a);
        }

        private static function irnd(a:int, b:int):int
        {
            return int(Math.floor(rnd(a, b + 1)));
        }

        /** Truth number n (1-9 per cycle of four zones) needs a Seal: 2, 3, 4, 6, 7, 8. 5 and 9 need Quix, 1 nothing. */
        public static function truthNeedsSeal(n:int):Boolean
        {
            var k:int = ((n - 1) % 9) + 1;
            return k >= 2 && k <= 8 && k != 5;
        }

        public static function fmt(n:Number):String
        {
            var s:String = String(int(Math.round(n)));
            var out:String = "";
            while (s.length > 3)
            {
                out = "," + s.substr(s.length - 3) + out;
                s = s.substr(0, s.length - 3);
            }
            return s + out;
        }

        private function after(ms:Number, fn:Function):void
        {
            timers.push({at: t + ms, fn: fn});
        }

        public function maxHp(role:String):int
        {
            var n:int = (harmonyBuff ? 1 : 0) + (apHealBuff ? 1 : 0);
            return MAX_HP[role][n];
        }

        private function setBuff(name:String, on:Boolean):void
        {
            if ((name == "harmony" ? harmonyBuff : apHealBuff) == on)
            {
                return;
            }
            var old:Object = {};
            var r:String;
            for each (r in ROLES)
            {
                old[r] = maxHp(r);
            }
            if (name == "harmony")
            {
                harmonyBuff = on;
            }
            else
            {
                apHealBuff = on;
            }
            for each (r in ROLES)
            {
                hp[r] = Math.round((hp[r] / old[r]) * maxHp(r));
            }
        }

        /** the Dmg stats of the player's class (the numbers given for the project) */
        private function stats():Object
        {
            return Dmg.profile(playerRole);
        }

        /** auto attack: cooldown, damage factor, damage source, type (classes.json) */
        private static const AA:Object = {
            loo: {cd: 2000, f: 0.7, src: "APSP1", type: "phys"},
            ap: {cd: 2000, f: 1.1, src: "AP2", type: "phys"},
            lr: {cd: 1500, f: 0.57, src: "AoE1", type: "magic"}
        };
        /** mana cost of the player's skills (classes.json) */
        private static const MP:Object = {
            harmony: 20, ordinance: 20, axiom: 20, quix: 30, taunt: 0,
            commandment: 10, heal: 40, seal: 20, eden: 40,
            shade: 10, wicked: 15, empowerment: 15, anathema: 20
        };

        /** every hit is multiplied by this: an ultra build is stronger than the stat blocks alone, tuned so the fight lasts as long as it did */
        private static const GEAR:Number = 2.5;

        /** Seconds between the player's auto attacks. */
        public function swingEvery():Number
        {
            return Dmg.cooldown(AA[playerRole].cd, stats().haste) / 1000;
        }

        /** The player's next auto attack: {dmg, crit}. */
        public function swing():Object
        {
            var p:Object = stats();
            var a:Object = AA[playerRole];
            var c:Boolean = Dmg.rollCrit(p);
            var d:Number = Dmg.hit(p, a.f, a.src, a.type, c, hp[playerRole], GEAR) * (0.95 + Math.random() * 0.1);
            // Legion Revenant: "recovers 15 mana on hit"; the others by the damage compared to their HP
            mana = Math.min(100, mana + (playerRole == "lr" ? 15 : Dmg.manaFor(d, c, p.hp)));
            return {dmg: d, crit: c};
        }

        /** Cooldown length of a skill by name, for the action bar overlay. */
        /** mana a skill costs (the action bar greys the slot out when there is not enough) */
        public function skillCost(name:String):Number
        {
            return MP[name] ? MP[name] : 0;
        }

        public function skillCdMs(name:String):Number
        {
            // SKILL_CD is the listed cooldown halved: in a perfect run (Lord of Order never failing) everybody has a permanent 50 % cooldown reduction
            return SKILL_CD[name];
        }

        /** The effects shown as buff icons, [{name, count, frac}]; null = the Ultra Speaker HUD builds them from the fields. */
        public function activeBuffs():Array
        {
            return null;
        }

        /** Multi-target scenes (Ultra Gramiel, Ultra Drago): what `role` is attacking, "boss" | "cl" | "cr" */
        public function targetOf(role:String):String
        {
            return role == playerRole ? targetSel : "boss";
        }

        /** HP / max HP of one of the targets ("boss", "cl", "cr") for the target frame */
        public function selHp(sel:String):Number
        {
            return bossHp;
        }

        public function selMax(sel:String):Number
        {
            return bossMaxHp;
        }

        /** A line the player typed in the chat field (Ultra Gramiel: tells the others to taunt). */
        public function chat(text:String):void
        {
        }

        /** What to tell the player while the fight waits for their first skill. */
        public function startHint():String
        {
            return "Use any skill to start the fight";
        }

        /** What the boss does next, for the "Next:" panel. */
        public function nextLabel():String
        {
            var names:Object = {auto: "Auto attack", truth: "Truth", listen: "Listen", zone: "Equal (zone)"};
            return names[PATTERN[ruleIdx]];
        }

        public function currentTaunt():String
        {
            return t < tauntUntil ? tauntRole : null;
        }

        public function stunned():Boolean
        {
            return t < stunUntil;
        }

        private function reductionFor(role:String, isTruth:Boolean):Number
        {
            var r:Number = 0;
            if (role == "lr" && t < lrEmpowerUntil)
            {
                r = 1 - (1 - r) * (1 - 0.3);
            }
            if (isTruth)
            {
                if (apReduction == "seal")
                {
                    r = 1 - (1 - r) * (1 - 0.9);
                }
                else if (apReduction == "eden")
                {
                    r = 1 - (1 - r) * (1 - 0.15);
                }
            }
            return r;
        }

        private function hurt(role:String, dmg:Number, why:String, kind:String = "dmg"):void
        {
            if (over)
            {
                return;
            }
            dmg = Math.max(0, Math.round(dmg));
            hp[role] = Math.max(0, hp[role] - dmg);
            host.floater(role, "-" + fmt(dmg), kind);
            if (hp[role] <= 0)
            {
                end("lose", ROLE_NAMES[role] + " died (" + why + ")");
            }
        }

        private function heal(role:String, amount:Number):void
        {
            if (over || hp[role] <= 0)
            {
                return;
            }
            var real:Number = Math.min(maxHp(role) - hp[role], amount);
            hp[role] += real;
            if (real > 0)
            {
                host.floater(role, "+" + fmt(real), "heal");
            }
        }

        private function healParty(amount:Number):void
        {
            for each (var r:String in ROLES)
            {
                heal(r, amount);
            }
        }

        private function end(result:String, reason:String):void
        {
            if (over)
            {
                return;
            }
            over = {result: result, reason: reason};
            host.zone(false, "");
            host.ended(result, reason);
        }

        // ------------------------------------------------------- boss abilities
        private function autoAttack():void
        {
            last["auto"] = t;
            host.bossAnim("Attack1", false);
            var base:int = irnd(804, 981);
            var crit:Boolean = base > 904;
            after(850, function():void {
                for each (var role:String in ROLES)
                {
                    var dmg:Number = base * DAMAGE_BOOST * (1 + 0.07 * somber[role]) * (1 - armor[role]) * (1 - reductionFor(role, false));
                    hurt(role, Math.ceil(dmg), "Auto attack", crit ? "crit" : "dmg");
                    somber[role]++;
                }
                for each (var r2:String in ROLES)
                {
                    armor[r2] = Math.max(0, armor[r2] - 0.07);
                }
            });
            after(1320, function():void { host.bossAnim("Idle", false); });
        }

        private function truth(n:int):void
        {
            last["truth"] = t;
            // Truth: ChargeB -> ChargeBLoop -> Attack2, timed so the hit lands at 2.0 s
            host.bossAnim("ChargeB", false);
            after(750, function():void { host.bossAnim("ChargeBLoop", true); });
            after(1165, function():void { host.bossAnim("Attack2", false); });
            host.announce("I will make you see the truth.");
            var base:int = irnd(1447, 1766);
            var crit:Boolean = base > 1447 + 220;
            var holder:String = mech;
            after(2000, function():void {
                lastTruthHit = t;
                var k:int = ((n - 1) % 9) + 1;
                var need:String = "";
                if (k == 5 || k == 9)
                {
                    need = "quix";
                }
                else if (k >= 2 && k <= 8)
                {
                    need = "seal";
                }
                if (need == "seal" && apReduction != "seal")
                {
                    host.floater(null, "Missed Seal", "bad");
                    counters.seal++;
                    end("lose", "Missed Seal: Truth #" + n + " needed the ArchPaladin's Seal");
                    return;
                }
                if (need == "quix" && t >= quixUntil)
                {
                    host.floater(null, "Missed Quix", "bad");
                    counters.quix++;
                    return;
                }
                if (holder == playerRole && currentTaunt() != holder)
                {
                    end("lose", "Missed Taunt");
                    return;
                }
                if (holder == null)
                {
                    return;
                }
                if (holder == playerRole)
                {
                    magiaBurnUntil = t + 18000; // Magia Burn debuff on the tank who takes the Truth
                }
                var dmg:Number = base * DAMAGE_BOOST * (1 - armor[holder]) * (1 - reductionFor(holder, true));
                hurt(holder, Math.ceil(dmg), "Truth", crit ? "crit" : "dmg");
            });
            after(2120, function():void { host.bossAnim("Idle", false); });
        }

        private function listen():void
        {
            last["listen"] = t;
            // Listen: ChargeA -> ChargeALoop -> Absorption, timed so the stun lands at 2.0 s
            host.bossAnim("ChargeA", false);
            after(880, function():void { host.bossAnim("ChargeALoop", true); });
            after(1300, function():void { host.bossAnim("Absorption", false); });
            host.announce("You shall listen.");
            var holder:String = mech;
            after(2000, function():void {
                if (holder == playerRole && currentTaunt() != holder)
                {
                    end("lose", "Missed Taunt");
                    return;
                }
                if (currentTaunt() == playerRole)
                {
                    stunUntil = t + 6000;
                    host.log("Stasis - you cannot use skills 2-6 for 6s", "bad");
                }
            });
            after(2100, function():void { host.bossAnim("Idle", false); });
        }

        private function equal(n:int):void
        {
            last["zone"] = t;
            zoneAt = t;
            decayUsed = false;
            var role:String = ZONE_ROLES[n];
            host.announce("All stand equal beneath the eyes of the Eternal.");
            host.log("Equal - zone " + n + ": " + ROLE_NAMES[role] + " must stand inside", "bad");
            after(100, function():void {
                host.bossAnim("PowerUp", false);
                host.zone(true, role);
            });
            after(810, function():void { host.bossAnim("PowerLoop", true); });
            after(2200, function():void { host.bossAnim("Magic", false); });
            after(3000, function():void {
                if (playerRole == "lr" && !decayUsed)
                {
                    end("lose", "Missed Decay: Legion Revenant has to use Decay (2) when the Zone appears");
                    return;
                }
                var dmg:int = irnd(2411, 2946);
                var inZone:Boolean = host.playerInZone();
                var shouldBeIn:Boolean = (role == playerRole);
                hurt(role, dmg, "Equal zone");
                if (!shouldBeIn && inZone)
                {
                    hp[playerRole] = 0;
                    end("lose", "Stood inside someone else's zone");
                }
                else if (shouldBeIn && !inZone)
                {
                    end("lose", "Missed Zone");
                }
                else
                {
                    somber[role] = 0;
                    armor[role] = 0.8;
                    host.log(ROLE_NAMES[role] + " cleansed (Somber/armor reset)", "good");
                }
                host.zone(false, "");
            });
            after(3400, function():void { host.bossAnim("Idle", false); });
        }

        // -------------------------------------- class skills (every role uses these)
        private function doSkill(name:String, actor:String, manual:Boolean):void
        {
            var t0:Number = t;
            var tok:int;
            switch (name)
            {
                case "harmony":
                    after(250, function():void {
                        setBuff("harmony", true);
                        harmonyUntil = t + HARMONY_DUR;
                        host.castFx("harmony", actor);
                    });
                    after(250 + HARMONY_DUR, function():void {
                        if (t >= harmonyUntil)
                        {
                            counters.harmony++;
                            setBuff("harmony", false);
                        }
                    });
                    break;
                case "ordinance":
                    after(250, function():void {
                        ordinanceUntil = t + ORDINANCE_DUR;
                        healParty(ORDINANCE_HEAL);
                        host.castFx("ordinance", actor);
                    });
                    after(250 + ORDINANCE_DUR, function():void {
                        if (t >= ordinanceUntil)
                        {
                            counters.ordinance++;
                        }
                    });
                    break;
                case "axiom":
                    after(250, function():void {
                        axiomUntil = t + AXIOM_DUR;
                        host.castFx("axiom", actor);
                    });
                    after(250 + AXIOM_DUR, function():void {
                        if (t >= axiomUntil)
                        {
                            counters.axiom++;
                        }
                    });
                    break;
                case "quix":
                    after(250, function():void {
                        if (t < quixAvailableAt)
                        {
                            quixAvailableAt = t + QUIX_LOCKOUT; // spamming resets the lockout
                            return;
                        }
                        quixAvailableAt = t + QUIX_LOCKOUT;
                        quixUntil = t + QUIX_DUR;
                        host.castFx("quix", actor);
                    });
                    break;
                case "taunt":
                    tauntRole = actor;
                    tauntUntil = t0 + TAUNT_DUR;
                    host.castFx("taunt", actor);
                    break;
                case "commandment":
                    host.castFx("commandment", actor);
                    break;
                case "heal":
                    after(250, function():void {
                        setBuff("apHeal", true);
                        apHealUntil = t + 15000;
                        healParty(6682);
                        host.castFx("heal", actor);
                    });
                    break;
                case "seal":
                    tok = ++sealToken;
                    after(250, function():void {
                        apReduction = "seal";
                        apReductionUntil = t + 7000;
                        host.castFx("seal", actor);
                    });
                    if (!manual)
                    {
                        after(250 + 5500, function():void {
                            if (sealToken == tok && apReduction == "seal")
                            {
                                doSkill("eden", actor, false);
                            }
                        });
                    }
                    after(7250, function():void {
                        if (sealToken == tok && apReduction == "seal")
                        {
                            apReduction = null;
                            counters.notBroken++;
                        }
                    });
                    break;
                case "eden":
                    if (manual && apReduction != "seal")
                    {
                        break; // nothing to break
                    }
                    tok = ++edenToken;
                    after(250, function():void {
                        apReduction = "eden";
                        apReductionUntil = t + 25000;
                        host.castFx("eden", actor);
                    });
                    after(25250, function():void {
                        if (edenToken == tok && apReduction == "eden")
                        {
                            apReduction = null;
                        }
                    });
                    break;
                case "shade":
                case "wicked":
                    host.castFx(name, actor);
                    if (name == "shade" && manual && t >= zoneAt && t <= zoneAt + 3000)
                    {
                        decayUsed = true; // Legion Revenant's Decay (2) while the Zone is up
                    }
                    break;
                case "empowerment":
                    after(250, function():void {
                        lrEmpowerUntil = t + 12000;
                        host.castFx("empowerment", actor);
                    });
                    break;
                case "anathema":
                    host.castFx("anathema", actor);
                    if (manual)
                    {
                        var ac:Boolean = Dmg.rollCrit(stats());
                        var ad:Number = Dmg.hit(stats(), 3, "AoE1", "magic", ac, hp[playerRole], GEAR);
                        playerHit(ad, ac);
                        mana = Math.min(100, mana + Dmg.manaFor(ad, ac, stats().hp));
                    }
                    break;
            }
        }

        private function scripted(idx:int):void
        {
            var p:String = playerRole;
            var list:Array;
            var i:int;
            if (p != "ap")
            {
                list = AP_ROTATION[idx] || [];
                for (i = 0; i < list.length; i++)
                {
                    queueSkill({2: "commandment", 3: "heal", 4: "seal", 5: "eden"}[list[i]], "ap", i * 500);
                }
            }
            if (p != "loo")
            {
                list = LOO_ROTATION[idx] || [];
                for (i = 0; i < list.length; i++)
                {
                    queueSkill({2: "harmony", 3: "ordinance", 4: "axiom", 5: "quix"}[list[i]], "loo", i * 500);
                }
            }
            if (p != "lr")
            {
                // Legion Revenant keeps Empowerment (-30% damage taken) rolling off cooldown
                after(750, function():void {
                    if (t >= lrEmpowerReady)
                    {
                        lrEmpowerReady = t + 3000;
                        doSkill("empowerment", "lr", false);
                    }
                });
            }
        }

        private function queueSkill(name:String, actor:String, delay:Number):void
        {
            after(delay, function():void { doSkill(name, actor, false); });
        }

        // ------------------------------------------------- the player's own skills
        public function skillName(n:int):String
        {
            var c:Object = CLASS_SKILLS[playerRole];
            return c && c[n] ? c[n] : null;
        }

        public function skillReady(n:int):Boolean
        {
            if (over || t < cd[n])
            {
                return false;
            }
            return !(n >= 2 && stunned());
        }

        /** Cast skill slot 2-6 of the player's class. Returns true if it went off. */
        public function cast(n:int):Boolean
        {
            var name:String = skillName(n);
            if (name == null || !skillReady(n))
            {
                return false;
            }
            if (playerRole == "ap" && (n == 2 || n == 4 || n == 5 || n == 6) && !host.playerCentered())
            {
                host.floater(playerRole, "Too far from center", "bad");
                return false;
            }
            if (mana < MP[name])
            {
                host.floater(playerRole, "Not enough mana", "bad");
                return false;
            }
            mana -= MP[name];
            started = true; // the first skill starts the fight
            cd[n] = t + skillCdMs(name);
            doSkill(name, playerRole, true);
            for (var k:int = 2; k <= 6; k++)
            {
                if (cd[k] - t < 1000)
                {
                    cd[k] = Math.max(cd[k], t + GCD);
                }
            }
            return true;
        }

        public function playerHit(dmg:Number, crit:Boolean):void
        {
            if (over)
            {
                return;
            }
            bossHp = Math.max(0, bossHp - dmg);
            host.bossDamage(int(dmg), crit, "player");
            if (bossHp <= 0)
            {
                end("win", "Ultra Speaker defeated");
            }
        }

        // --------------------------------------------------------------- engine
        private function fireAbility():void
        {
            var ability:String = PATTERN[ruleIdx];
            mech = MECHANICS[ruleIdx] ? MECHANICS[ruleIdx] : null;
            if (mech != null && mech != playerRole)
            {
                tauntRole = mech;
                tauntUntil = t + 6000;
            }
            host.mechanic(mech, ability, truthN, zoneN);
            scripted(ruleIdx);
            switch (ability)
            {
                case "auto":
                    autoAttack();
                    break;
                case "truth":
                    var needsSeal:Boolean = truthNeedsSeal(truthN);
                    if (needsSeal && playerRole != "ap")
                    {
                        doSkill("seal", "ap", false);
                    }
                    truth(truthN);
                    truthN++;
                    break;
                case "listen":
                    listen();
                    break;
                case "zone":
                    equal(zoneN);
                    zoneN++;
                    break;
            }
            busyUntil = t + CAST[ability] + 1000;
            busy = true;
        }

        public function step(dtMs:Number):void
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
                for (var i:int = 0; i < timers.length; i++)
                {
                    if (timers[i].at <= t && (k < 0 || timers[i].at < timers[k].at))
                    {
                        k = i;
                    }
                }
                if (k < 0)
                {
                    break;
                }
                var tm:Object = timers.splice(k, 1)[0];
                tm.fn();
                if (over)
                {
                    return;
                }
            }
            if (apHealBuff && t >= apHealUntil)
            {
                setBuff("apHeal", false);
            }
            if (!busy)
            {
                var ability:String = PATTERN[ruleIdx];
                var start:Number = last[ability] != undefined ? last[ability] : 0;
                if (t >= start + TIMINGS[ability])
                {
                    fireAbility();
                }
            }
            else if (t >= busyUntil)
            {
                ruleIdx++;
                if (ruleIdx >= PATTERN.length)
                {
                    ruleIdx = 6;
                    zoneN = 1;
                    truthN = 2;
                }
                busy = false;
            }
            // the rest of the raid drains the boss: 42-52k every 0.6-1.1 s
            if (t >= partyDrainAt)
            {
                var d:int = irnd(raidDps[0], raidDps[1]);
                bossHp = Math.max(0, bossHp - d);
                host.bossDamage(d, d > raidDps[0] + (raidDps[1] - raidDps[0]) * 0.7, "party");
                partyDrainAt = t + rnd(600, 1100);
                if (bossHp <= 0)
                {
                    end("win", "Ultra Speaker defeated");
                }
            }
        }
    }
}

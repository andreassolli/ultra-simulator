package sim
{
    /**
     * Ultra Speaker fight rules. Boss rotation, cast times, cooldowns, damage
     * ranges, taunt / seal / quix / zone requirements and the Lord of Order,
     * Arch Paladin and Legion Revenant numbers come from the web simulator
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

        private static const TIMINGS:Object = {auto: 2000, truth: 7000, listen: 12000, zone: 16000};
        private static const CAST:Object = {auto: 1200, truth: 2000, listen: 2000, zone: 3000};

        private static const MAX_HP:Object = {
            ap: [3670, 4000, 4400],
            lr: [2910, 3090, 3310],
            loo: [3205, 3445, 3735],
            dps: [2810, 2975, 3170]
        };
        private static const START_HP:Object = {ap: 3670, lr: 2910, loo: 3205, dps: 2450};

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
            harmony: 4000, ordinance: 6000, axiom: 4000, quix: 4000, taunt: 10000,
            commandment: 2500, heal: 5000, seal: 12500, eden: 12500,
            shade: 3000, wicked: 3000, empowerment: 3000, anathema: 6000
        };

        private static const HARMONY_DUR:int = 10000;
        private static const ORDINANCE_DUR:int = 12000;
        private static const ORDINANCE_HEAL:int = 2700;
        private static const AXIOM_DUR:int = 10000;
        private static const QUIX_DUR:int = 4000;
        private static const QUIX_LOCKOUT:int = 25000;
        private static const TAUNT_DUR:int = 6000;
        private static const GCD:int = 400;

        // ---------------------------------------------------------------- state
        public var t:Number = 0;
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
        public var cd:Array = [0, 0, 0, 0, 0, 0, 0];
        public var counters:Object = {harmony: 0, ordinance: 0, axiom: 0, seal: 0, quix: 0, notBroken: 0};
        public var ruleIdx:int = 0; // current position in PATTERN
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
            if (t < ordinanceUntil)
            {
                r = 1 - (1 - r) * (1 - 0.3);
            }
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
                end("lose", role.toUpperCase() + " died (" + why + ")");
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
                    var dmg:Number = base * (1 + 0.07 * somber[role]) * (1 - armor[role]) * (1 - reductionFor(role, false));
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
            // charge up (PowerUp -> PowerLoop), then Shadowflame timed to finish as the hit lands at 2.0 s
            host.bossAnim("PowerUp", false);
            after(710, function():void { host.bossAnim("PowerLoop", true); });
            after(1250, function():void { host.bossAnim("Shadowflame", false); });
            host.announce("I will make you see the truth.");
            var base:int = irnd(1447, 1766);
            var crit:Boolean = base > 1447 + 220;
            var holder:String = mech;
            after(2000, function():void {
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
                var dmg:Number = base * (1 - armor[holder]) * (1 - reductionFor(holder, true));
                hurt(holder, Math.ceil(dmg), "Truth", crit ? "crit" : "dmg");
            });
            after(2120, function():void { host.bossAnim("Idle", false); });
        }

        private function listen():void
        {
            last["listen"] = t;
            // ChargeB -> ChargeBLoop, then Magic timed to finish as the stun lands at 2.0 s
            host.bossAnim("ChargeB", false);
            after(750, function():void { host.bossAnim("ChargeBLoop", true); });
            after(1165, function():void { host.bossAnim("Magic", false); });
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
            after(2280, function():void { host.bossAnim("Idle", false); });
        }

        private function equal(n:int):void
        {
            last["zone"] = t;
            var role:String = ZONE_ROLES[n];
            host.announce("All stand equal beneath the eyes of the Eternal.");
            host.log("Equal - zone " + n + ": " + role.toUpperCase() + " must stand inside", "bad");
            after(100, function():void {
                host.bossAnim("ChargeA", false);
                host.zone(true, role);
            });
            after(900, function():void { host.bossAnim("ChargeALoop", true); });
            after(2600, function():void { host.bossAnim("Absorption", false); });
            after(3000, function():void {
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
                    host.log(role.toUpperCase() + " cleansed (Somber/armor reset)", "good");
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
                    break;
                case "empowerment":
                    after(250, function():void {
                        lrEmpowerUntil = t + 12000;
                        host.castFx("empowerment", actor);
                    });
                    break;
                case "anathema":
                    var d:int = int(Math.floor(6000 + Math.random() * 3000));
                    host.castFx("anathema", actor);
                    if (manual)
                    {
                        playerHit(d, d > 8000);
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
            cd[n] = t + SKILL_CD[name];
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
                    var needsSeal:Boolean = (truthN >= 1 && truthN <= 3) || (truthN >= 5 && truthN <= 7);
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
            if (over)
            {
                return;
            }
            t += dtMs;
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

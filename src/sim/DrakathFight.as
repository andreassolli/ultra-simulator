package sim
{
    /**
     * Champion Drakath fight rules (Legion Revenant / Paladin Chronomancer).
     *
     * From the wiki guide (championdrakath.mdx): 20 000 000 HP, an auto attack every 2.25 s that cannot be taunted,
     * Chaos Slam / Chaos Blast (exactly 3 000 / 3 500 true damage to everyone, tauntable) every 2 000 000 HP lost,
     * the transformation at 10 000 000 HP and the 20 s Summoning Meteor at 2 000 000 HP. Slams at 18, 16, 14 and 12M,
     * blasts at 8, 6 and 4M (see SLAMS).
     *
     * Taunts: the Legion Revenant has to have its taunt (skill 6) active when the boss reaches 16M and 12M, the
     * Paladin Chronomancer at 18M, 14M, 8M, 6M and 4M. The class the player is not is played by the sim and taunts
     * its own thresholds. Missing one of the player's lose the fight, and so does the meteor going off.
     *
     * Phase 2 slows the damage dealt to Drakath (more resistance) and his Gaining Power stacks make his autos hit
     * harder. Party HP, healing and the raid's damage are not in the guide, they are tuned, see README.
     * All times are in milliseconds.
     */
    public class DrakathFight extends Fight
    {
        public static const DRAK_ROLES:Array = ["lr", "pc", "da", "db"];
        public static const DRAK_NAMES:Object = {lr: "Legion Revenant", pc: "Paladin Chronomancer", da: "DPS 1", db: "DPS 2"};

        /** player skill slots 2-6 (slot 1 is the auto attack, slot 6 the taunt) */
        public static const DRAK_SKILLS:Object = {
            lr: {2: "shade", 3: "wicked", 4: "depraved", 5: "anathema", 6: "taunt"},
            pc: {2: "rift", 3: "vow", 4: "intervention", 5: "retribution", 6: "taunt"}
        };
        private static const LISTED_CD:Object = {
            shade: 6000, wicked: 6000, depraved: 6000, anathema: 12000, taunt: 10000,
            rift: 3000, vow: 5000, intervention: 36000, retribution: 18000
        };

        /** boss HP (in millions) at which the next special happens: Chaos Slam, Transform, Chaos Blast, Summoning Meteor */
        private static const EVENTS:Array = [
            {hp: 18, kind: "slam"}, {hp: 16, kind: "slam"}, {hp: 14, kind: "slam"}, {hp: 12, kind: "slam"},
            {hp: 10, kind: "transform"},
            {hp: 8, kind: "blast"}, {hp: 6, kind: "blast"}, {hp: 4, kind: "blast"},
            {hp: 2, kind: "meteor"}
        ];
        /** the taunts each class owns (millions of HP) */
        private static const TAUNTS:Object = {lr: [16, 12], pc: [18, 14, 8, 6, 4]};

        private static const START_HP:Object = {lr: 4800, pc: 4800, da: 3600, db: 3600};
        private static const AUTO_EVERY:int = 2250;
        private static const AUTO_CAST:int = 500;
        private static const TAUNT_MS:int = 6000;
        private static const CHAOS_MS:int = 60000;
        private static const METEOR_MS:int = 20000;
        private static const PHASE2_RESIST:Number = 0.55; // damage dealt to Drakath after the transformation
        private static const METEOR_TAKEN:Number = 8.5;   // "increases their damage taken by 750 %"
        private static const UNIT:Number = 4000;
        private static const LIFESTEAL:Number = 300;      // hp per second every character gets back
        private static const ARMOR:Number = 0.08;         // what is left of the listed physical damage
        private static const GCD:int = 400;

        // ---- state shared with the HUD ------------------------------------------------------------
        public var phase:int = 1;
        public var power:int = 0;            // Gaining Power stacks
        public var chaosUntil:Number = 0;    // Chaorrupted on the party
        public var cripUntil:Number = 0;     // Crippled (phase 2)
        public var meteorUntil:Number = 0;   // Summoning Meteor charge
        public var depravedUntil:Number = 0;
        public var vowUntil:Number = 0;
        public var guardUntil:Number = 0;    // Divine Intervention
        public var casts:Object = {taunted: 0, missedTaunt: 0};

        private var host2:IFightHost;
        private var timers2:Array = [];
        private var playerClass:String;
        private var nextEvent:int = 0;
        private var autoAt:Number = 2500;
        private var autoPausedUntil:Number = 0;
        private var tickAt:Number = 1000;
        private var partyAt:Number = 600;
        private var npcVowAt:Number = 3000;
        private var npcGuardAt:Number = 20000;
        private var npcDepravedAt:Number = 2000;
        private var recent:Array = [];       // [time, damage] of recent hits on Drakath, for the dps estimate
        private var cued:Object = {};
        private var npcTauntedFor:Object = {};

        public function DrakathFight(host:IFightHost, role:String, bossHp:Number, raidDps:Array)
        {
            super(host, role, bossHp, raidDps);
            host2 = host;
            playerClass = role;
            hp = {};
            somber = {};
            armor = {};
            for each (var r:String in DRAK_ROLES)
            {
                hp[r] = START_HP[r];
                somber[r] = 0;
                armor[r] = 0;
            }
        }

        // ------------------------------------------------------------------ helpers
        private static function rnd(a:Number, b:Number):Number
        {
            return a + Math.random() * (b - a);
        }

        private function later(ms:Number, fn:Function):void
        {
            timers2.push({at: t + ms, fn: fn});
        }

        private function alive(r:String):Boolean
        {
            return hp[r] > 0;
        }

        private function npcClass():String
        {
            return playerClass == "lr" ? "pc" : "lr";
        }

        override public function maxHp(role:String):int
        {
            return START_HP[role];
        }

        override public function stunned():Boolean
        {
            return false;
        }

        override public function skillName(n:int):String
        {
            var c:Object = DRAK_SKILLS[playerClass];
            return c && c[n] ? c[n] : null;
        }

        override public function skillCdMs(name:String):Number
        {
            return LISTED_CD[name];
        }

        override public function nextLabel():String
        {
            if (nextEvent >= EVENTS.length)
            {
                return "Finish him";
            }
            var e:Object = EVENTS[nextEvent];
            var names:Object = {slam: "Chaos Slam", blast: "Chaos Blast", transform: "Transformation", meteor: "Summoning Meteor"};
            var owner:String = "";
            if (e.kind == "slam" || e.kind == "blast")
            {
                owner = TAUNTS[playerClass].indexOf(e.hp) >= 0 ? " (YOUR taunt)" : " (ally taunts)";
            }
            return names[e.kind] + " " + e.hp + "M" + owner;
        }

        private function hit(role:String, dmg:Number, why:String):void
        {
            if (over || !alive(role))
            {
                return;
            }
            dmg = Math.max(0, Math.round(dmg));
            hp[role] = Math.max(0, hp[role] - dmg);
            host2.floater(role, "-" + Fight.fmt(dmg), "dmg");
            if (hp[role] <= 0)
            {
                host2.log(DRAK_NAMES[role] + " died (" + why + ")", "bad");
                if (role == playerRole)
                {
                    finish("lose", DRAK_NAMES[role] + " died (" + why + ")");
                    return;
                }
                var any:Boolean = false;
                for each (var r:String in DRAK_ROLES)
                {
                    any = any || alive(r);
                }
                if (!any)
                {
                    finish("lose", "The party was wiped");
                }
            }
        }

        private function restore(role:String, amount:Number, shown:Boolean):void
        {
            if (over || !alive(role))
            {
                return;
            }
            var real:Number = Math.min(START_HP[role] - hp[role], amount);
            hp[role] += real;
            if (real > 0 && shown)
            {
                host2.floater(role, "+" + Fight.fmt(real), "heal");
            }
        }

        private function healAll(amount:Number, shown:Boolean):void
        {
            for each (var r:String in DRAK_ROLES)
            {
                restore(r, amount, shown && r == playerRole);
            }
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

        // --------------------------------------------------- damage to Drakath
        private function dmgBoss(dmg:Number, crit:Boolean, who:String):void
        {
            if (over)
            {
                return;
            }
            var m:Number = t < meteorUntil ? METEOR_TAKEN : (phase == 2 ? PHASE2_RESIST : 1);
            if (t < depravedUntil)
            {
                m *= 1.3;
            }
            var d:int = int(dmg * m);
            bossHp = Math.max(0, bossHp - d);
            recent.push([t, d]);
            host2.bossDamage(d, crit, who);
            if (bossHp <= 0)
            {
                finish("win", "Champion Drakath defeated");
                return;
            }
            checkEvents();
        }

        /** damage per second over the last few seconds */
        private function dps():Number
        {
            var sum:Number = 0;
            var from:Number = t - 3000;
            var keep:Array = [];
            for each (var e:Array in recent)
            {
                if (e[0] >= from)
                {
                    sum += e[1];
                    keep.push(e);
                }
            }
            recent = keep;
            return Math.max(40000, sum / 3);
        }

        private function checkEvents():void
        {
            while (!over && nextEvent < EVENTS.length && bossHp <= EVENTS[nextEvent].hp * 1000000)
            {
                var e:Object = EVENTS[nextEvent++];
                switch (e.kind)
                {
                    case "slam":
                    case "blast":
                        special(e);
                        break;
                    case "transform":
                        transform();
                        break;
                    case "meteor":
                        meteor();
                        break;
                }
            }
        }

        /** Chaos Slam / Chaos Blast: tauntable, exactly 3 000 / 3 500 true damage */
        private function special(e:Object):void
        {
            var blast:Boolean = e.kind == "blast";
            host2.bossAnim(blast ? "FSpecial" : "Special", false);
            host2.announce(blast ? "Drakath gains power and evasion, and unleashes a devastating attack!" : "Drakath gains power, and unleashes a destructive attack!");
            var holder:String = currentTaunt();
            var mine:Boolean = TAUNTS[playerClass].indexOf(e.hp) >= 0;
            if (mine && holder != playerClass)
            {
                casts.missedTaunt++;
                host2.floater(playerClass, "Missed Taunt", "bad");
                finish("lose", "Missed Taunt (" + e.hp + "M HP)");
                return;
            }
            if (holder != null)
            {
                casts.taunted++;
            }
            for each (var r:String in DRAK_ROLES)
            {
                if (alive(r) && (holder == null || r == holder))
                {
                    hit(r, blast ? 3500 : 3000, blast ? "Chaos Blast" : "Chaos Slam");
                    if (over)
                    {
                        return;
                    }
                }
            }
            power++;
            host2.log((blast ? "Chaos Blast" : "Chaos Slam") + " at " + e.hp + "M - " + (holder != null ? DRAK_NAMES[holder] + " took it" : "everyone took it") + ", Gaining Power x" + power, holder != null ? "good" : "bad");
            later(1100, function():void { idle(); });
        }

        private function idle():void
        {
            if (t >= meteorUntil || meteorUntil == 0)
            {
                host2.bossAnim(phase == 2 ? "FIdle" : "Idle", false);
            }
        }

        private function transform():void
        {
            phase = 2;
            cripUntil = 0;
            autoPausedUntil = t + 3500;
            host2.announce("Do you really think you stand a chance against me?");
            host2.log("Drakath transforms: more damage resistance, Crippled on every auto", "bad");
            host2.bossAnim("Transform", false);
        }

        private function meteor():void
        {
            meteorUntil = t + METEOR_MS;
            autoPausedUntil = meteorUntil + 1000;
            host2.announce("I WILL NOT LOSE EVERYTHING! NOT AGAIN!");
            host2.log("Summoning Meteor - 20 s to kill Drakath (he takes 8.5x damage)", "bad");
            host2.bossAnim("Charge", false);
            later(METEOR_MS, function():void {
                if (bossHp > 0)
                {
                    host2.bossAnim("Execute", false);
                    finish("lose", "Summoning Meteor went off");
                }
            });
        }

        // -------------------------------------------------- Drakath's auto attack
        private function autoAttack():void
        {
            host2.bossAnim(phase == 2 ? "FAttack1" : "Attack1", false);
            later(AUTO_CAST, function():void {
                for each (var r:String in DRAK_ROLES)
                {
                    if (!alive(r))
                    {
                        continue;
                    }
                    var d:Number = rnd(1285, 1570) * (1 + 0.5 * power) * ARMOR * (t < chaosUntil ? 2 : 1);
                    if (t < vowUntil)
                    {
                        d *= 0.67;
                    }
                    if (t < guardUntil)
                    {
                        d *= 0.2;
                    }
                    hit(r, d, "Auto attack");
                    if (over)
                    {
                        return;
                    }
                }
                chaosUntil = t + CHAOS_MS; // Chaorrupted: +100 % damage taken
                if (phase == 2)
                {
                    cripUntil = t + CHAOS_MS;
                }
            });
            later(1200, function():void { idle(); });
        }

        // ------------------------------------------------------ the player's skills
        override public function skillReady(n:int):Boolean
        {
            return !over && t >= cd[n];
        }

        override public function swingEvery():Number
        {
            return playerClass == "lr" ? 1.5 : 2.5;
        }

        override public function swing():Object
        {
            var c:Boolean = playerClass == "lr" && Math.random() < 0.25;
            var f:Number = playerClass == "lr" ? 0.57 : 0.4;
            return {dmg: UNIT * f * rnd(0.9, 1.1) * (c ? 1.7 : 1) * (t < cripUntil ? 0.4 : 1), crit: c};
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
            cd[n] = t + LISTED_CD[name];
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

        private function strike(factor:Number):void
        {
            var c:Boolean = Math.random() < 0.25;
            dmgBoss(UNIT * factor * rnd(0.9, 1.1) * (c ? 1.7 : 1) * (t < cripUntil ? 0.4 : 1), c, "player");
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
                case "shade":
                    if (manual) strike(0.85);
                    break;
                case "wicked":
                    if (manual) strike(1);
                    break;
                case "depraved":
                    depravedUntil = t + 15000; // Depravity: the party deals more damage
                    break;
                case "anathema":
                    if (manual) strike(3);
                    break;
                case "rift":
                    if (manual) strike(0.5);
                    break;
                case "vow":
                    vowUntil = t + 15000;
                    healAll(1100, manual);
                    break;
                case "intervention":
                    guardUntil = t + 5000;
                    healAll(2500, manual);
                    break;
                case "retribution":
                    if (manual) strike(3);
                    break;
            }
        }

        /** What is on Drakath / on the player, for the buff icons: {name, count, frac}. */
        override public function activeBuffs():Array
        {
            var list:Array = [];
            var frac:Function = function(until:Number, total:Number):Number { return Math.max(0, Math.min(1, (until - t) / total)); };
            var left:Function = function(until:Number):String { return String(Math.ceil((until - t) / 1000)); };
            // on Drakath
            if (currentTaunt() != null)
            {
                list.push({name: "focus", count: "", frac: frac(tauntUntil, TAUNT_MS)});
            }
            if (power > 0)
            {
                list.push({name: "power", count: String(power), frac: -1});
            }
            if (phase == 2)
            {
                list.push({name: "unleashed", count: "", frac: -1});
            }
            if (t < meteorUntil)
            {
                list.push({name: "meteor", count: left(meteorUntil), frac: frac(meteorUntil, METEOR_MS)});
            }
            // on the player
            if (t < chaosUntil)
            {
                list.push({name: "chaos", count: "", frac: frac(chaosUntil, CHAOS_MS)});
            }
            if (t < cripUntil)
            {
                list.push({name: "cripple", count: "", frac: frac(cripUntil, CHAOS_MS)});
            }
            if (t < depravedUntil)
            {
                list.push({name: "depraved", count: left(depravedUntil), frac: frac(depravedUntil, 15000)});
            }
            if (t < vowUntil)
            {
                list.push({name: "vow", count: left(vowUntil), frac: frac(vowUntil, 15000)});
            }
            if (t < guardUntil)
            {
                list.push({name: "intervention", count: left(guardUntil), frac: frac(guardUntil, 5000)});
            }
            return list;
        }

        // ------------------------------------------------------------ the sim's own class
        private function npcPlay():void
        {
            var c:String = npcClass();
            if (!alive(c))
            {
                return;
            }
            // taunt the thresholds it owns: shortly before the boss gets there
            if (nextEvent < EVENTS.length)
            {
                var e:Object = EVENTS[nextEvent];
                if ((e.kind == "slam" || e.kind == "blast") && TAUNTS[c].indexOf(e.hp) >= 0 && !npcTauntedFor[e.hp] && bossHp - e.hp * 1000000 <= dps() * 2.5)
                {
                    npcTauntedFor[e.hp] = true;
                    doSkill("taunt", c, false);
                }
            }
            if (c == "pc")
            {
                if (t >= npcVowAt)
                {
                    npcVowAt = t + 5000;
                    doSkill("vow", c, false);
                }
                if (t >= npcGuardAt)
                {
                    npcGuardAt = t + 36000;
                    doSkill("intervention", c, false);
                }
            }
            else if (t >= npcDepravedAt)
            {
                npcDepravedAt = t + 6000;
                doSkill("depraved", c, false);
            }
        }

        // ------------------------------------------------------------ engine
        override public function step(dtMs:Number):void
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
            if (t >= autoAt && t >= autoPausedUntil)
            {
                autoAttack();
                autoAt = t + AUTO_EVERY;
            }
            npcPlay();
            // cue for the player: taunt before the boss reaches one of the class' thresholds
            if (nextEvent < EVENTS.length)
            {
                var e:Object = EVENTS[nextEvent];
                var key:String = String(e.hp);
                if ((e.kind == "slam" || e.kind == "blast") && TAUNTS[playerClass].indexOf(e.hp) >= 0 && !cued[key] && bossHp - e.hp * 1000000 <= dps() * 3.5)
                {
                    cued[key] = true;
                    host2.mechanic(playerClass, "taunt", e.hp, 0);
                }
            }
            for each (var r:String in DRAK_ROLES)
            {
                somber[r] = 0;
            }
            if (t >= tickAt)
            {
                tickAt += 1000;
                for each (var q:String in DRAK_ROLES)
                {
                    restore(q, LIFESTEAL, false);
                }
            }
            // the other characters: raid damage every 0.6-1.1 s
            if (t >= partyAt)
            {
                var d:Number = rnd(raidDps[0], raidDps[1]);
                var others:Number = 0;
                for each (var w:String in DRAK_ROLES)
                {
                    if (w != playerRole && alive(w))
                    {
                        others++;
                    }
                }
                d = d * others / 3;
                if (d > 0)
                {
                    dmgBoss(d, d > raidDps[0] + (raidDps[1] - raidDps[0]) * 0.7, "party");
                }
                partyAt = t + rnd(600, 1100);
            }
        }
    }
}

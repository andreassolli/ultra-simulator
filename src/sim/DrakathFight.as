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
        /** classes.json: damage factor, damage source, mana cost (negative: recovers) of the damaging skills */
        private static const SKILL:Object = {
            shade: {f: 0.85, src: "AoE1", mp: 10, type: "magic", crit: true}, wicked: {f: 1, src: "AoE1", mp: 15, type: "magic"},
            depraved: {f: 0, src: "SP1", mp: 15, type: "magic"}, anathema: {f: 3, src: "AoE1", mp: 20, type: "magic"},
            rift: {f: 0.5, src: "EX1", mp: 5, type: "magic", noCrit: true}, vow: {f: -2.2, src: "AP1", mp: 40, type: "magic"},
            intervention: {f: -30, src: "SP1", mp: 20, type: "magic"}, retribution: {f: 0.45, src: "Chrono2", mp: 10, type: "magic", noCrit: true},
            taunt: {f: 0, src: "AP1", mp: 0, type: "phys"}
        };
        /** every hit and heal is multiplied by this: see GEAR in DageFight (tuned so the fight lasts about as long as before the calculator maths) */
        private static const GEAR:Number = 5.4;
        private static const CAP:Number = 75000; // "damage over 75 000 is reduced": excess ^ 0.8
        private static const HEAL_SCALE:Number = 0.35; // what is left of a heal after the boss' damage was tuned (see README)

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
        public var guardUntil:Number = 0;    // Divine Intervention (Indomitable)
        public var angelUntil:Number = 0;    // Guardian Angel
        public var wickedUntil:Number = 0;
        public var wickedStacks:int = 0;
        public var riftStacks:Array = [];    // Temporal Rift, expiry times (max 4)
        public var reprisal:Array = [];      // Ascendancy / Reprisal on Drakath, expiry times (max 5)
        public var noxStacks:Array = [];     // Infinita Nox: Drakath takes +7 % each (max 15)
        public var dotUntil:Number = 0;      // Atramentous Shade
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
        private var npcNoxAt:Number = 3000;
        private var npcRiftAt:Number = 1000;
        private var recent:Array = [];       // [time, damage] of recent hits on Drakath, for the dps estimate
        private var cued:Object = {};
        private var me:Object;                // the player's stats (Dmg.profile)
        private var ally:Object = Dmg.profile("dps");
        private var riftLog:Array = [];       // [time, damage] the player dealt while Temporal Rift was up
        private var dotAt:Number = 0;
        private var hotUntil:Number = 0;      // Intervention: a massive heal over time
        private var spiritsUntil:Number = 0;  // Spirits Within: 45 mana over 5 s
        private var depravedHeal:Number = 0;
        private var npcTauntedFor:Object = {};

        public function DrakathFight(host:IFightHost, role:String, bossHp:Number, raidDps:Array)
        {
            super(host, role, bossHp, raidDps);
            host2 = host;
            playerClass = role;
            me = Dmg.profile(role);
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
            return name == "taunt" ? LISTED_CD[name] : Dmg.cooldown(LISTED_CD[name], me.haste + (t < depravedUntil && playerClass == "lr" ? 20 : 0));
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
        private function live(list:Array):int
        {
            var n:int = 0;
            for each (var until:Number in list)
            {
                if (until > t)
                {
                    n++;
                }
            }
            return n;
        }

        private function dmgBoss(dmg:Number, crit:Boolean, who:String):void
        {
            if (over)
            {
                return;
            }
            var m:Number = t < meteorUntil ? METEOR_TAKEN : (phase == 2 ? PHASE2_RESIST : 1);
            if (t < depravedUntil)
            {
                m *= 1.3; // Depravity: outgoing damage +30 % for the party
            }
            m *= 1 + 0.07 * live(noxStacks) + 0.1 * live(reprisal); // Infinita Nox, Ascendancy / Reprisal (defence -10 % per stack)
            var d:int = int(Dmg.taken(dmg * m, 1, CAP));
            bossHp = Math.max(0, bossHp - d);
            recent.push([t, d]);
            if (who == "player" && live(riftStacks) > 0)
            {
                riftLog.push([t, d]);
            }
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
            var from:Number = t - 8000;
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
            return Math.max(40000, sum / 8);
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
                    d *= 1 - 0.1 * live(reprisal); // Reprisal: Drakath's outgoing damage -10 % per stack
                    if (t < vowUntil)
                    {
                        d *= 0.67; // Holy Shield: +33 % defence
                    }
                    if (t < guardUntil)
                    {
                        d *= 0.3; // Indomitable: Endurance +400 %
                    }
                    if (r == "lr" && t < wickedUntil)
                    {
                        d *= 1 - Math.min(0.4, 0.2 + 0.04 * wickedStacks); // Wicked Purgatory
                    }
                    if (r == "lr" && t < depravedUntil)
                    {
                        d *= 0.7; // Arcane Shield
                    }
                    if (r == "pc" && playerClass == "pc")
                    {
                        mana = Math.min(100, mana + 3); // struck: Paladin Chronomancers gain mana
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

        private function haste():Number
        {
            var h:Number = me.haste;
            if (t < depravedUntil && playerClass == "lr")
            {
                h += 20;
            }
            if (t < vowUntil && playerClass == "pc")
            {
                h += 10;
            }
            return h;
        }

        private function myMe():Object
        {
            // Depravity (LR): crit damage +30 %, and Crippled (phase 2) cuts strength / intellect / luck by 60 %
            var o:Object = {};
            for (var k:String in me)
            {
                o[k] = me[k];
            }
            if (t < depravedUntil && playerClass == "lr")
            {
                o.critMod += 30;
            }
            if (t < depravedUntil)
            {
                o.critChance = Math.min(100, o.critChance + 30);
            }
            if (t < cripUntil)
            {
                o.ap *= 0.4;
                o.sp *= 0.4;
            }
            return o;
        }

        override public function swingEvery():Number
        {
            return Dmg.cooldown(playerClass == "lr" ? 1500 : 2500, haste()) / 1000;
        }

        override public function swing():Object
        {
            var o:Object = myMe();
            var c:Boolean = playerClass == "lr" && Dmg.rollCrit(o); // Hammer of Virtue can't crit
            var d:Number;
            if (playerClass == "lr")
            {
                d = Dmg.hit(o, 0.57, "AoE1", "magic", c, hp[playerRole], GEAR);
                mana = Math.min(100, mana + 15); // "recovers 15 mana on hit"
            }
            else
            {
                d = Dmg.hit(o, 0.15, "intHP", "phys", false, hp[playerRole], GEAR);
                mana = Math.min(100, mana + 3);
            }
            return {dmg: d * rnd(0.95, 1.05), crit: c};
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
            var cost:Number = SKILL[name].mp;
            if (mana < cost)
            {
                host2.floater(playerRole, "Not enough mana", "bad");
                return false;
            }
            mana -= cost;
            cd[n] = t + skillCdMs(name);
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

        /** a hit by the player's skill; the sim's own class (manual false) only has its buffs and heals here */
        private function strike(name:String, factor:Number, src:String, type:String, noCrit:Boolean, force:Boolean):void
        {
            var o:Object = myMe();
            var c:Boolean = force || (!noCrit && Dmg.rollCrit(o));
            dmgBoss(Dmg.hit(o, factor, src, type, c, hp[playerRole], GEAR) * rnd(0.95, 1.05), c, "player");
        }

        private function infinitaNox():void
        {
            // Legion Revenant passive: Shade, Wicked Purgatory and Anathema have a 50 % chance for +7 % damage taken, 30 s, stacks to 15
            if (Math.random() < 0.5 && live(noxStacks) < 15)
            {
                noxStacks.push(t + 30000);
            }
        }

        private function healing(actor:String, name:String):Number
        {
            var k:Object = SKILL[name];
            var prof:Object = actor == playerClass ? myMe() : Dmg.profile(actor);
            return Dmg.heal(prof, k.f, k.src, true, hp[actor]) * GEAR * HEAL_SCALE;
        }

        private function doSkill(name:String, actor:String, manual:Boolean):void
        {
            host2.castFx(name, actor);
            var k:Object = SKILL[name];
            switch (name)
            {
                case "taunt":
                    tauntRole = actor;
                    tauntUntil = t + TAUNT_MS;
                    break;
                case "shade":
                    if (manual) strike(name, k.f, k.src, k.type, false, true); // always crits
                    dotUntil = t + 12000; // plus damage over time for 12 s
                    dotAt = t + 1000;
                    infinitaNox();
                    break;
                case "wicked":
                    if (manual) strike(name, k.f, k.src, k.type, false, false);
                    wickedStacks = t < wickedUntil ? Math.min(4, wickedStacks + 1) : 0; // +3 % crit reduction, -4 % damage taken per stack
                    wickedUntil = t + 12000;
                    infinitaNox();
                    break;
                case "depraved":
                    depravedUntil = t + 12000; // you and your allies: dodge / crit / damage +30 %; you: haste +20 %, crit damage +30 %, arcane shield
                    break;
                case "anathema":
                    if (manual) strike(name, k.f, k.src, k.type, false, false);
                    infinitaNox();
                    break;
                case "rift":
                    if (manual) strike(name, k.f, k.src, k.type, true, true); // "can't crit", hits
                    if (live(riftStacks) < 4)
                    {
                        riftStacks.push(t + 30000);
                    }
                    if (live(reprisal) < 5)
                    {
                        reprisal.push(t + 10000);
                    }
                    break;
                case "vow":
                    vowUntil = t + 15000;
                    healAll(healing(actor, name), manual);
                    if (t < angelUntil)
                    {
                        angelUntil = 0;
                        hotUntil = t + 5000; // Intervention: a massive heal over time
                    }
                    break;
                case "intervention":
                    guardUntil = t + 5000;
                    angelUntil = t + 15000;
                    healAll(healing(actor, name), manual);
                    break;
                case "retribution":
                    // damage dealt in the last 10 s while Temporal Rift was up, times the stacks, then the stacks are gone
                    var sum:Number = 0;
                    for each (var e:Array in riftLog)
                    {
                        if (e[0] >= t - 10000)
                        {
                            sum += e[1];
                        }
                    }
                    var stacks:int = Math.max(1, live(riftStacks));
                    if (manual)
                    {
                        dmgBoss(sum * (0.45 + 0.1 * stacks) * stacks / 4 + Dmg.hit(myMe(), 0.45, "SP1", "magic", false, 0, GEAR) * 0.25, false, "player");
                    }
                    riftStacks = [];
                    riftLog = [];
                    spiritsUntil = t + 5000;
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
            if (live(noxStacks) > 0)
            {
                list.push({name: "nox", count: String(live(noxStacks)), frac: frac(Math.max.apply(null, noxStacks), 30000)});
            }
            if (live(reprisal) > 0)
            {
                list.push({name: "reprisal", count: String(live(reprisal)), frac: frac(Math.max.apply(null, reprisal), 10000)});
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
            if (t < wickedUntil && playerClass == "lr")
            {
                list.push({name: "wicked", count: String(wickedStacks + 1), frac: frac(wickedUntil, 12000)});
            }
            if (playerClass == "pc" && live(riftStacks) > 0)
            {
                list.push({name: "rift", count: String(live(riftStacks)), frac: frac(Math.max.apply(null, riftStacks), 30000)});
            }
            if (t < angelUntil && playerClass == "pc")
            {
                list.push({name: "angel", count: left(angelUntil), frac: frac(angelUntil, 15000)});
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
            else
            {
                if (t >= npcDepravedAt)
                {
                    npcDepravedAt = t + 6000;
                    doSkill("depraved", c, false);
                }
                if (t >= npcNoxAt)
                {
                    npcNoxAt = t + 2500;
                    doSkill(npcNoxAt % 3 < 1 ? "anathema" : (npcNoxAt % 2 < 1 ? "wicked" : "shade"), c, false);
                }
            }
            if (c == "pc" && t >= npcRiftAt)
            {
                npcRiftAt = t + 3000;
                doSkill("rift", c, false);
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
                if ((e.kind == "slam" || e.kind == "blast") && TAUNTS[playerClass].indexOf(e.hp) >= 0 && !cued[key] && bossHp - e.hp * 1000000 <= dps() * 3)
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
                    if (t < hotUntil)
                    {
                        restore(q, 0.2 * START_HP[q], false);
                    }
                    if (q == "lr" && t < depravedUntil)
                    {
                        restore(q, 150, false); // Depravity heals over time
                    }
                }
                mana = Math.min(100, mana + 2 + (t < spiritsUntil ? 9 : 0)); // base regeneration, Spirits Within
                if (t < dotUntil && playerClass == "lr")
                {
                    dmgBoss(Dmg.hit(myMe(), 0.15, "AoE1", "dot", false, 0, GEAR), false, "player"); // Atramentous Shade's damage over time
                }
            }
            // the other characters play on their own: the calculator's hit of a standard build, at its haste
            if (t >= partyAt)
            {
                var tick:Number = rnd(600, 1100);
                var d:Number = 0;
                var perHit:Number = Dmg.average(ally, 1.0, "AP2", "phys") * GEAR;
                var hitsPerSec:Number = 1000 / Dmg.cooldown(1500, ally.haste);
                for each (var w:String in DRAK_ROLES)
                {
                    if (w != playerRole && alive(w))
                    {
                        d += perHit * hitsPerSec * tick / 1000 * (w == "da" || w == "db" ? 1 : 0.5);
                    }
                }
                if (d > 0)
                {
                    dmgBoss(d, false, "party");
                }
                partyAt = t + tick;
            }
        }
    }
}

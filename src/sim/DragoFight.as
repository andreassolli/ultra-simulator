package sim
{
    /**
     * Ultra Drago fight rules (Legion Revenant or ArchPaladin, with the sim's Chrono ShadowSlayer and Lord of Order), from ultradrago.mdx.
     *
     * Executioner Dene (left, 3 500 000 HP): auto attacks every 2.25 s (tauntable; each hit stacks Defenses Shattered on the one hit and
     * makes Dene take 1 % less damage per player hit) and, after 8 autos, Execution, the special that nukes and has to be Sealed by the
     * ArchPaladin. Bowmaster Algie (right, 2 000 000 HP): auto attacks (tauntable; Damage Drained on the one hit, he deals 1 % more per
     * player hit) and, after 5 autos, Triple Shot with Bleeding. Damage over 75 000 a hit is cut (excess ^ 0.7). When one of the two dies the
     * other heals fully and gains Ally Boost (x2 damage, half damage taken). King Drago (1 000 HP) cannot be damaged until both are dead and
     * simply dies with them; if the fight lasts 160 s he starts Judgement Day, which kills everybody 20 s later.
     *
     * The Legion Revenant taunts Algie and the ArchPaladin taunts Dene on repeat (the one that is not the player's class is played by the
     * sim). Lord of Order and the ArchPaladin fight Dene from the start (range); the Legion Revenant and the Chrono ShadowSlayer kill
     * Algie first and then join on Dene. Execution is not listed with a seal window in the guide: it is a nuke that the ArchPaladin's Seal
     * (skill 4, 7 s) has to be up for, a missed Seal loses. Raid damage is tuned so everything is dead in under a minute.
     */
    public class DragoFight extends Fight
    {
        public static const D_ROLES:Array = ["lr", "ap", "cs", "loo"];
        public static const D_NAMES:Object = {lr: "Legion Revenant", ap: "ArchPaladin", cs: "Chrono ShadowSlayer", loo: "Lord of Order"};
        public static const D_SKILLS:Object = {
            lr: {2: "shade", 3: "wicked", 4: "depraved", 5: "anathema", 6: "taunt"},
            ap: {2: "commandment", 3: "heal", 4: "seal", 5: "eden", 6: "taunt"}
        };
        private static const LISTED_CD:Object = {
            shade: 6000, wicked: 6000, depraved: 6000, anathema: 12000, taunt: 10000,
            commandment: 2500, heal: 5000, seal: 12500, eden: 12500 // the ArchPaladin's are the raid values (50 % cooldown reduction), as in the Speaker fight
        };
        private static const SKILL:Object = {
            shade: {f: 0.85, mp: 10, crit: true}, wicked: {f: 1, mp: 15}, depraved: {f: 0, mp: 15}, anathema: {f: 3, mp: 20},
            commandment: {f: 1.5, mp: 10}, heal: {mp: 40}, seal: {mp: 20}, eden: {mp: 40}, taunt: {mp: 0}
        };
        private static const AA:Object = {
            lr: {cd: 1500, f: 0.57, src: "AoE1", type: "magic"},
            ap: {cd: 2000, f: 1.1, src: "AP2", type: "phys"}
        };
        /** the sim's characters' auto attacks (classes.json), and how much of the time they spend attacking */
        private static const NPC_AA:Object = {
            lr: {cd: 1500, f: 0.57, src: "AoE1", type: "magic", share: 1},
            ap: {cd: 2000, f: 1.1, src: "AP2", type: "phys", share: 0.45},
            loo: {cd: 2000, f: 0.7, src: "APSP1", type: "phys", share: 0.4},
            cs: {cd: 1500, f: 1.0, src: "AP2", type: "phys", share: 1}
        };
        private static const START_HP:Object = {lr: 2910, ap: 3670, cs: 2835, loo: 3505};
        private static const DENE_HP:Number = 3500000;
        private static const ALGIE_HP:Number = 2000000;
        private static const CAP:Number = 75000;        // damage over this is reduced: excess ^ 0.7
        private static const CAP_EXP:Number = 0.7;
        private static const GEAR:Number = 85;          // tuned so the three of them are dead in under a minute
        private static const ARMOR:Number = 0.2 / 0.55; // what is left of the listed monster damage (as in the other fights)
        private static const EXEC_K:Number = 20;        // Execution hits like this many autos when it is not Sealed
        private static const SEAL_MS:int = 7000;
        private static const TAUNT_MS:int = 6000;
        private static const GCD:int = 400;
        private static const REGEN:Number = 0.035;      // of max HP per second

        // ---- state shared with the HUD ------------------------------------------------------------
        public var deneHp:Number = DENE_HP;
        public var algieHp:Number = ALGIE_HP;
        public var deneBoost:Boolean = false;           // Ally Boost
        public var algieBoost:Boolean = false;
        public var deneDefense:int = 0;                 // "Defense Increasing": Dene takes 1 % less per player hit
        public var algieRage:int = 0;                   // "Damage Increasing": Algie deals 1 % more per player hit
        public var sealUntil:Number = 0;
        public var shatter:Object = {};                 // role -> expiry times of Defenses Shattered
        public var drained:Object = {};                 // role -> expiry times of Damage Drained
        public var bleedUntil:Object = {};
        public var focusOn:Object = {dene: {role: null, until: 0}, algie: {role: null, until: 0}};
        public var depravedUntil:Number = 0;
        public var executionAt:Number = -1;             // when the next Execution lands (for the Next: line)
        public var casts:Object = {taunted: 0};
        public var algieTaunts:int = 0;                 // the player's taunts on the boss their class holds (Legion Revenant: Algie, ArchPaladin: Dene)

        private var host2:IFightHost;
        private var timers2:Array = [];
        private var me:Object;
        private var playerClass:String;
        private var partyAt:Number = 700;
        private var tickAt:Number = 1000;
        private var npcCd:Object = {taunt: 0, seal: 0, heal: 0};
        private var judgementAt:Number = 160000;
        private var judging:Boolean = false;
        private var lrShield:Number = 0;
        private var lrShieldUntil:Number = 0;

        public function DragoFight(host:IFightHost, role:String, bossHp:Number, raidDps:Array)
        {
            super(host, role, 1000, raidDps);
            host2 = host;
            playerClass = role;
            me = Dmg.profile(role);
            started = false;
            targetSel = role == "lr" ? "cr" : "cl";
            hp = {};
            somber = {};
            armor = {};
            for each (var r:String in D_ROLES)
            {
                hp[r] = START_HP[r];
                somber[r] = 0;
                armor[r] = 0;
                shatter[r] = [];
                drained[r] = [];
                bleedUntil[r] = 0;
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
            return playerClass == "lr" ? "ap" : "lr";
        }

        private static function count(list:Array, now:Number):int
        {
            var n:int = 0;
            for each (var u:Number in list)
            {
                if (u > now)
                {
                    n++;
                }
            }
            return n;
        }

        override public function maxHp(role:String):int
        {
            return START_HP[role];
        }

        override public function stunned():Boolean
        {
            return false;
        }

        override public function startHint():String
        {
            return playerClass == "lr" ? "Use a skill to start - target Bowmaster Algie (right) and taunt him on repeat" : "Use a skill to start - target Executioner Dene (left), taunt him on repeat and Seal his Execution";
        }

        override public function skillName(n:int):String
        {
            var c:Object = D_SKILLS[playerClass];
            return c && c[n] ? c[n] : null;
        }

        override public function skillCdMs(name:String):Number
        {
            if (name == "taunt" || playerClass == "ap")
            {
                return LISTED_CD[name];
            }
            return Dmg.cooldown(LISTED_CD[name], me.haste);
        }

        override public function skillCost(name:String):Number
        {
            return SKILL[name] ? SKILL[name].mp : 0;
        }

        override public function skillReady(n:int):Boolean
        {
            return !over && t >= cd[n];
        }

        /** who each character attacks: Lord of Order and the ArchPaladin stay on Dene; the others kill Algie, then Dene */
        override public function targetOf(role:String):String
        {
            if (role == playerRole)
            {
                return targetSel;
            }
            var wantsAlgie:Boolean = role == "lr" || role == "cs";
            if (wantsAlgie && algieHp > 0)
            {
                return "cr";
            }
            if (deneHp > 0)
            {
                return "cl";
            }
            return algieHp > 0 ? "cr" : "boss";
        }

        override public function selHp(sel:String):Number
        {
            return sel == "cl" ? deneHp : (sel == "cr" ? algieHp : bossHp);
        }

        override public function selMax(sel:String):Number
        {
            return sel == "cl" ? DENE_HP : (sel == "cr" ? ALGIE_HP : bossMaxHp);
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

        private function hurt(role:String, dmg:Number, why:String, shown:Boolean = true):void
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
            if (shown && dmg > 0)
            {
                host2.floater(role, "-" + Fight.fmt(dmg), "dmg");
            }
            if (hp[role] <= 0)
            {
                host2.log(D_NAMES[role] + " died (" + why + ")", "bad");
                finish("lose", D_NAMES[role] + " died (" + why + ")");
            }
        }

        private function restore(role:String, amount:Number, shown:Boolean):void
        {
            if (over || !alive(role))
            {
                return;
            }
            var real:Number = Math.min(maxHp(role) - hp[role], amount);
            hp[role] += real;
            if (real > 0 && shown)
            {
                host2.floater(role, "+" + Fight.fmt(real), "heal");
            }
        }

        // ------------------------------------------------------------ the fight's start
        private function begin():void
        {
            started = true;
            host2.log("Taunt the side bosses on repeat; the ArchPaladin Seals Executioner Dene's Execution", "");
            host2.bossAnim("Idle", false);
            deneCycle(2000);
            algieCycle(3000);
        }

        // ---------------------------------------------------- Executioner Dene (left): 8 autos, Execution
        private function deneCycle(first:Number):void
        {
            var base:Number = first;
            for (var k:int = 0; k < 8; k++)
            {
                later(base + k * 2250, function():void { deneAuto(); });
            }
            var execAt:Number = base + 8 * 2250 + 300;
            executionAt = t + execAt + 2500;
            later(execAt, function():void { execution(); });
            later(execAt + 3000, function():void { deneCycle(0); });
        }

        private function takenFor(role:String):Number
        {
            return Dmg.takenMul(Dmg.profile(role), false);
        }

        private function deneAuto():void
        {
            if (over || deneHp <= 0)
            {
                return;
            }
            host2.crystalAnim("cl", "Attack1", false);
            later(1100, function():void { if (deneHp > 0) { host2.crystalAnim("cl", "Idle", false); } });
            later(500, function():void {
                if (over || deneHp <= 0)
                {
                    return;
                }
                var tk:Object = focusOn.dene;
                var list:Array = [];
                if (tk.role != null && t < tk.until && alive(tk.role))
                {
                    list.push(tk.role);
                }
                else
                {
                    for each (var r:String in D_ROLES)
                    {
                        if (alive(r))
                        {
                            list.push(r);
                        }
                    }
                }
                for each (var w:String in list)
                {
                    var stacks:int = count(shatter[w], t);
                    var d:Number = rnd(1044, 1276) * ARMOR * takenFor(w) * (1 + 0.05 * stacks) * (deneBoost ? 2 : 1);
                    shatter[w].push(t + 4000);
                    hurt(w, d, "Executioner Dene", w == playerRole);
                    if (over)
                    {
                        return;
                    }
                }
                deneDefense += list.length; // Defense Increasing: -1 % damage taken for each player hit
            });
        }

        private function execution():void
        {
            if (over || deneHp <= 0)
            {
                return;
            }
            host2.announce("Executioner Dene raises his axe!");
            host2.crystalAnim("cl", "Attack2", false);
            host2.mechanic(playerRole, "execution", 0, 0);
            if (npcClass() == "ap" && alive("ap"))
            {
                later(700, function():void { sealBy("ap"); });
            }
            later(2500, function():void {
                if (over || deneHp <= 0)
                {
                    return;
                }
                if (t >= sealUntil)
                {
                    host2.log("Execution was not Sealed", "bad");
                    finish("lose", "Missed Seal: Executioner Dene's Execution hit everybody (ArchPaladin Seal, skill 4)");
                    return;
                }
                for each (var r:String in D_ROLES)
                {
                    if (alive(r))
                    {
                        hurt(r, rnd(1044, 1276) * ARMOR * takenFor(r) * EXEC_K * 0.1 * (deneBoost ? 2 : 1), "Execution", r == playerRole);
                        if (over)
                        {
                            return;
                        }
                    }
                }
                later(1000, function():void { if (deneHp > 0) { host2.crystalAnim("cl", "Idle", false); } });
            });
        }

        // -------------------------------------------------- Bowmaster Algie (right): 5 autos, Triple Shot
        private function algieCycle(first:Number):void
        {
            var base:Number = first;
            for (var k:int = 0; k < 5; k++)
            {
                later(base + k * 2250, function():void { algieAuto(); });
            }
            later(base + 5 * 2250, function():void { tripleShot(); });
            later(base + 6 * 2250, function():void { algieCycle(0); });
        }

        private function algieAuto():void
        {
            if (over || algieHp <= 0)
            {
                return;
            }
            host2.crystalAnim("cr", "Attack1", false);
            later(1000, function():void { if (algieHp > 0) { host2.crystalAnim("cr", "Idle", false); } });
            later(450, function():void {
                if (over || algieHp <= 0)
                {
                    return;
                }
                var tk:Object = focusOn.algie;
                var list:Array = [];
                if (tk.role != null && t < tk.until && alive(tk.role))
                {
                    list.push(tk.role);
                }
                else
                {
                    for each (var r:String in D_ROLES)
                    {
                        if (alive(r))
                        {
                            list.push(r);
                        }
                    }
                }
                for each (var w:String in list)
                {
                    var d:Number = rnd(1044, 1276) * ARMOR * takenFor(w) * (1 + 0.01 * algieRage) * (algieBoost ? 2 : 1);
                    drained[w].push(t + 4000);
                    hurt(w, d, "Bowmaster Algie", w == playerRole);
                    if (over)
                    {
                        return;
                    }
                }
                algieRage += list.length; // Damage Increasing: +1 % damage for each player hit
            });
        }

        private function tripleShot():void
        {
            if (over || algieHp <= 0)
            {
                return;
            }
            host2.crystalAnim("cr", "Attack2", false);
            later(1100, function():void { if (algieHp > 0) { host2.crystalAnim("cr", "Idle", false); } });
            later(600, function():void {
                for each (var r:String in D_ROLES)
                {
                    if (alive(r))
                    {
                        hurt(r, rnd(1044, 1276) * ARMOR * takenFor(r) * (1 + 0.01 * algieRage) * (algieBoost ? 2 : 1), "Triple Shot", r == playerRole);
                        bleedUntil[r] = t + 20000; // Bleeding
                        if (over)
                        {
                            return;
                        }
                    }
                }
            });
        }

        // ------------------------------------------------------------------ damage to the bosses
        private function dealt(sel:String, dmg:Number, crit:Boolean, who:String, hits:Number = 1):void
        {
            if (over || sel == "boss" || dmg <= 0)
            {
                return;
            }
            var mult:Number = 1;
            var boosted:Boolean = sel == "cl" ? deneBoost : algieBoost;
            if (boosted)
            {
                mult *= 0.5; // Ally Boost
            }
            if (sel == "cl")
            {
                mult *= Math.max(0.1, 1 - 0.01 * deneDefense);
            }
            var d:Number = dmg * mult;
            if (d > CAP)
            {
                d = CAP + Math.pow(d - CAP, CAP_EXP); // per hit
            }
            d = int(d * hits);
            if (sel == "cl")
            {
                if (deneHp <= 0)
                {
                    return;
                }
                deneHp = Math.max(0, deneHp - d);
            }
            else
            {
                if (algieHp <= 0)
                {
                    return;
                }
                algieHp = Math.max(0, algieHp - d);
            }
            host2.bossDamage(d, crit, who);
            if ((sel == "cl" ? deneHp : algieHp) <= 0)
            {
                died(sel);
            }
        }

        private function died(sel:String):void
        {
            host2.crystalAnim(sel, "Die", false);
            var name:String = sel == "cl" ? "Executioner Dene" : "Bowmaster Algie";
            host2.log(name + " is dead", "good");
            if ((sel == "cr" && playerClass == "lr") || playerClass == "ap")
            {
                // the tank has to keep its boss taunted (Legion Revenant: Algie, ArchPaladin: Dene): at least one taunt, two after 10 s, three after 20 s
                var need:int = Math.min(3, 1 + int(t / 10000));
                if (algieTaunts < need)
                {
                    var who:String = playerClass == "lr" ? "Legion Revenant only taunted Bowmaster Algie " : "ArchPaladin only taunted Executioner Dene ";
                    finish("lose", who + algieTaunts + " time(s): taunt him (6) on repeat, at least " + need + " times by now");
                    return;
                }
            }
            var other:String = sel == "cl" ? "cr" : "cl";
            if ((other == "cl" ? deneHp : algieHp) > 0)
            {
                // the other heals fully and gains Ally Boost
                if (other == "cl")
                {
                    deneHp = DENE_HP;
                    deneBoost = true;
                }
                else
                {
                    algieHp = ALGIE_HP;
                    algieBoost = true;
                }
                host2.announce((other == "cl" ? "Executioner Dene" : "Bowmaster Algie") + " is enraged by his ally's death!");
                host2.log("Ally Boost: " + (other == "cl" ? "Executioner Dene" : "Bowmaster Algie") + " healed fully, x2 damage, takes half damage", "bad");
                host2.mechanic(playerRole, "enraged", other == "cl" ? 1 : 2, 0);
            }
            else
            {
                bossHp = 0;
                host2.log("King Drago falls with them", "good");
                finish("win", "Ultra Drago defeated");
            }
        }

        // ------------------------------------------------------- the player's skills
        private function haste():Number
        {
            return me.haste + (playerClass == "lr" && t < depravedUntil ? 20 : 0);
        }

        override public function swingEvery():Number
        {
            return Dmg.cooldown(AA[playerClass].cd, haste()) / 1000;
        }

        private function drainMul(role:String):Number
        {
            return Math.max(0.2, 1 - 0.05 * count(drained[role], t)); // Damage Drained
        }

        override public function swing():Object
        {
            var a:Object = AA[playerClass];
            var c:Boolean = Dmg.rollCrit(me);
            var d:Number = Dmg.hit(me, a.f, a.src, a.type, c, hp[playerRole], GEAR) * rnd(0.95, 1.05) * drainMul(playerRole);
            mana = Math.min(100, mana + (playerClass == "lr" ? 15 : Dmg.manaFor(d, c, me.hp)));
            return {dmg: d, crit: c};
        }

        override public function playerHit(dmg:Number, isCrit:Boolean):void
        {
            dealt(targetSel, dmg, isCrit, "player");
        }

        override public function cast(n:int):Boolean
        {
            var name:String = skillName(n);
            if (name == null || !skillReady(n))
            {
                return false;
            }
            if (!host2.inRange(playerRole))
            {
                host2.floater(playerRole, "Too far from your target", "bad");
                return false;
            }
            var cost:Number = SKILL[name].mp;
            if (mana < cost)
            {
                host2.floater(playerRole, "Not enough mana", "bad");
                return false;
            }
            mana -= cost;
            if (!started)
            {
                begin();
            }
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

        private function sealBy(actor:String):void
        {
            sealUntil = t + SEAL_MS;
            host2.castFx("seal", actor);
            if (actor == playerRole)
            {
                host2.log("Seal up for " + (SEAL_MS / 1000) + " s", "good");
            }
        }

        private function healAll(amount:Number, shownRole:String):void
        {
            for each (var r:String in D_ROLES)
            {
                restore(r, amount, r == shownRole);
            }
        }

        private function healPower(actor:String):Number
        {
            var prof:Object = actor == playerClass ? me : Dmg.profile(actor);
            return Dmg.heal(prof, 0.5, "SP2", true, 0) * GEAR / 6 * 1.4;
        }

        private function doSkill(name:String, actor:String, manual:Boolean):void
        {
            host2.castFx(name, actor);
            var k:Object = SKILL[name];
            switch (name)
            {
                case "taunt":
                    if (!manual)
                    {
                        break;
                    }
                    if (targetSel == "boss")
                    {
                        host2.log("Taunt wasted: select a side boss", "bad");
                        break;
                    }
                    focusOn[targetSel == "cl" ? "dene" : "algie"] = {role: actor, until: t + TAUNT_MS};
                    casts.taunted++;
                    if (targetSel == (playerClass == "lr" ? "cr" : "cl"))
                    {
                        algieTaunts++; // taunts on the boss this class is meant to hold
                    }
                    break;
                case "shade":
                case "wicked":
                case "anathema":
                case "commandment":
                    if (manual)
                    {
                        var c:Boolean = k.crit ? true : Dmg.rollCrit(me);
                        var lr:Boolean = playerClass == "lr";
                        var d:Number = Dmg.hit(me, k.f, lr ? "AoE1" : "AP2", lr ? "magic" : "phys", c, hp[playerRole], GEAR) * rnd(0.95, 1.05) * drainMul(playerRole);
                        dealt(targetSel, d, c, "player");
                        mana = Math.min(100, mana + (lr ? Dmg.manaFor(d, c, me.hp) : Dmg.manaFor(d, c, me.hp)));
                    }
                    break;
                case "depraved":
                    depravedUntil = t + 12000;
                    lrShield = 0.3 * Dmg.profile("lr").sp * Dmg.WEAPON_BOOST;
                    lrShieldUntil = t + 12000;
                    break;
                case "heal":
                    healAll(healPower(actor), manual ? playerRole : "");
                    break;
                case "seal":
                    sealBy(actor);
                    break;
                case "eden":
                    healAll(healPower(actor) * 0.7, manual ? playerRole : "");
                    break;
            }
        }

        override public function activeBuffs():Array
        {
            var list:Array = [];
            var frac:Function = function(until:Number, total:Number):Number { return Math.max(0, Math.min(1, (until - t) / total)); };
            var left:Function = function(until:Number):String { return String(Math.ceil((until - t) / 1000)); };
            // on the selected boss
            if (targetSel != "boss")
            {
                var tk:Object = focusOn[targetSel == "cl" ? "dene" : "algie"];
                if (tk.role != null && t < tk.until)
                {
                    list.push({name: "focus", count: "", frac: frac(tk.until, TAUNT_MS)});
                }
                if (targetSel == "cl" ? deneBoost : algieBoost)
                {
                    list.push({name: "ally", count: "", frac: -1});
                }
                if (targetSel == "cl" && deneDefense > 0)
                {
                    list.push({name: "defup", count: String(Math.min(99, deneDefense)), frac: -1});
                }
            }
            // on us
            if (t < sealUntil)
            {
                list.push({name: "sealed", count: left(sealUntil), frac: frac(sealUntil, SEAL_MS)});
            }
            var sh:int = count(shatter[playerRole], t);
            if (sh > 0)
            {
                list.push({name: "defshatter", count: String(sh), frac: -1});
            }
            var dr:int = count(drained[playerRole], t);
            if (dr > 0)
            {
                list.push({name: "drained", count: String(dr), frac: -1});
            }
            if (t < bleedUntil[playerRole])
            {
                list.push({name: "bleed", count: left(bleedUntil[playerRole]), frac: frac(bleedUntil[playerRole], 20000)});
            }
            if (playerClass == "lr" && t < depravedUntil)
            {
                list.push({name: "depraved", count: left(depravedUntil), frac: frac(depravedUntil, 12000)});
            }
            return list;
        }

        override public function nextLabel():String
        {
            if (!started)
            {
                return "Waiting for your first skill";
            }
            if (deneHp > 0 && executionAt > t)
            {
                return "Execution in " + Math.max(0, Math.ceil((executionAt - t) / 1000)) + " s" + (playerClass == "ap" ? " - Seal (4)" : "");
            }
            if (deneHp > 0 || algieHp > 0)
            {
                return (algieHp > 0 && deneHp > 0 ? "Kill Algie, then Dene" : "Finish him");
            }
            return "King Drago";
        }

        // ------------------------------------------------------------ the sim's characters
        private function npcPlay():void
        {
            // the sim's tank (ArchPaladin on Dene / Legion Revenant on Algie) taunts on repeat
            var nc:String = npcClass();
            if (alive(nc) && t >= npcCd.taunt && t > 1000)
            {
                var side:String = nc == "ap" ? "dene" : "algie";
                if ((side == "dene" ? deneHp : algieHp) > 0)
                {
                    npcCd.taunt = t + 10000;
                    focusOn[side] = {role: nc, until: t + TAUNT_MS};
                    host2.castFx("taunt", nc);
                }
            }
            if (nc == "lr" && alive("lr") && t >= npcCd.seal)
            {
                npcCd.seal = t + 12000;
                lrShield = 0.3 * Dmg.profile("lr").sp * Dmg.WEAPON_BOOST;
                lrShieldUntil = t + 12000;
            }
            // Lord of Order heals when somebody is low
            if (alive("loo") && t >= npcCd.heal)
            {
                var low:Boolean = false;
                for each (var r:String in D_ROLES)
                {
                    if (alive(r) && hp[r] < maxHp(r) * 0.6)
                    {
                        low = true;
                    }
                }
                if (low)
                {
                    npcCd.heal = t + 8000;
                    healAll(healPower("loo"), "");
                    host2.castFx("ordinance", "loo");
                }
            }
        }

        private function partyDamage():void
        {
            if (t < partyAt)
            {
                return;
            }
            var tick:Number = rnd(600, 1100);
            partyAt = t + tick;
            for each (var w:String in D_ROLES)
            {
                if (w == playerRole || !alive(w) || !host2.inPlace(w))
                {
                    continue;
                }
                var pw:Object = Dmg.profile(w);
                var aa:Object = NPC_AA[w];
                // the ArchPaladin and Lord of Order spend most of their time on heals, Seals and taunts: they only add a share
                var perHit:Number = Dmg.average(pw, aa.f, aa.src, aa.type) * GEAR * aa.share;
                var hits:Number = 1000 / Dmg.cooldown(aa.cd, pw.haste) * tick / 1000;
                var sel:String = targetOf(w);
                dealt(sel, perHit * drainMul(w), false, "party", hits);
                if (over)
                {
                    return;
                }
            }
        }

        // ------------------------------------------------------------------ engine
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
            npcPlay();
            partyDamage();
            if (over)
            {
                return;
            }
            if (!judging && t >= judgementAt)
            {
                judging = true;
                host2.announce("King Drago begins to laugh...");
                host2.bossAnim("Charge", false);
                host2.log("Judgement Day: everybody dies in 20 s", "bad");
                later(20000, function():void {
                    host2.bossAnim("Execute", false);
                    finish("lose", "Judgement Day: King Drago was still alive after 180 s");
                });
            }
            if (t >= tickAt)
            {
                tickAt += 1000;
                for each (var q:String in D_ROLES)
                {
                    restore(q, REGEN * maxHp(q), false);
                    if (t < bleedUntil[q])
                    {
                        hurt(q, 30 * takenFor(q) * (algieBoost ? 2 : 1), "Bleeding", false);
                        if (over)
                        {
                            return;
                        }
                    }
                }
            }
        }

        public function debug():String
        {
            return "{\"dene\":" + Math.round(deneHp) + ",\"algie\":" + Math.round(algieHp) + ",\"deneBoost\":" + deneBoost + ",\"algieBoost\":" + algieBoost +
                ",\"sealed\":" + (t < sealUntil) + ",\"target\":\"" + targetSel + "\"}";
        }
    }
}

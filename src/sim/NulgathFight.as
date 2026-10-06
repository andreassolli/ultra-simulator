package sim
{
    /**
     * Ultra Nulgath fight rules (Legion Revenant / Lord of Order), from ultranulgath.mdx and classes.json.
     *
     * Nulgath (10 000 000 HP): Contracts of the Abyss every 7 s (no damage, tauntable; Frailty, then Despair for those who already have
     * Frailty, then Stagnation) and Abyssal Charge ("Behold the power of the Abyss!", 4 s, 500 physical, cooldown 14 s).
     * Overfiend Blade: an auto attack every 2.25 s (1 750-2 150) and Sword Charge ("I will shatter you to the core!", 5 s) which kills
     * everybody unless the Lord of Order has used Quix (skill 5) on the Blade before the fight. Nobody attacks the Blade.
     *
     * The fight starts with the player's first skill (Lord of Order: that has to be Quix). Taunts: the Lord of Order taunts 5 s into the
     * fight and each time his Contract debuff wears off (16 s, 30 s), the Legion Revenant at each "Behold the power of the Abyss!" (9, 23,
     * 37 s); the other class is played by the sim. A Contract that nobody has taunted, or that lands on somebody who still has the
     * previous one, loses the fight, and so does anybody dying. Raid damage is tuned so the run takes about 38 seconds.
     */
    public class NulgathFight extends Fight
    {
        public static const NUL_ROLES:Array = ["lr", "loo", "ap", "cs"];
        public static const NUL_NAMES:Object = {lr: "Legion Revenant", loo: "Lord of Order", ap: "Arch Paladin", cs: "Chrono ShadowSlayer"};
        public static const NUL_SKILLS:Object = {
            lr: {2: "shade", 3: "wicked", 4: "depraved", 5: "anathema", 6: "taunt"},
            loo: {2: "harmony", 3: "ordinance", 4: "axiom", 5: "quix", 6: "taunt"}
        };
        private static const LISTED_CD:Object = {
            shade: 6000, wicked: 6000, depraved: 6000, anathema: 12000, taunt: 10000,
            harmony: 8000, ordinance: 12000, axiom: 8000, quix: 8000
        };
        private static const SKILL:Object = {
            shade: {f: 0.85, mp: 10, crit: true}, wicked: {f: 1, mp: 15}, depraved: {f: 0, mp: 15}, anathema: {f: 3, mp: 20},
            harmony: {mp: 20}, ordinance: {mp: 20}, axiom: {mp: 20}, quix: {mp: 30}, taunt: {mp: 0}
        };
        private static const AA:Object = {
            lr: {cd: 1500, f: 0.57, src: "AoE1", type: "magic"},
            loo: {cd: 2000, f: 0.7, src: "APSP1", type: "phys"}
        };
        private static const START_HP:Object = {lr: 2910, loo: 3505, ap: 3670, cs: 2835};
        private static const HARMONY_HP:Number = 0.0685; // Lord of Order's Harmony: 3505 -> 3745 as in the Speaker fight

        private static const CONTRACTS:Array = [6000, 13000, 20000, 27000, 34000];
        private static const BEHOLD:Array = [9000, 23000, 37000];
        private static const NPC_LOO_TAUNTS:Array = [5000, 16000, 30000];
        private static const CONTRACT_MS:int = 10000;
        private static const TAUNT_MS:int = 6000;
        private static const CAP:Number = 100000;      // "damage above 100 000 is reduced": excess ^ 0.8
        private static const GEAR_LR:Number = 42;      // tuned so Nulgath dies about 38 s into the fight (the sim's other class differs)
        private static const GEAR_LOO:Number = 66;
        private function get GEAR():Number
        {
            return playerClass == "loo" ? GEAR_LOO : GEAR_LR;
        }
        private static const BLADE_ARMOR:Number = 0.2; // what is left of the Blade's listed damage (tuned)
        private static const LIFESTEAL:Number = 300;
        private static const HEAL_BOOST:Number = 1.4;
        private static const GCD:int = 400;

        // ---- state shared with the HUD ------------------------------------------------------------
        public var quixed:Boolean = false;    // Quix was used on the Blade before the fight
        public var frailUntil:Object = {};
        public var despairUntil:Object = {};
        public var depravedUntil:Number = 0;
        public var ordUntil:Number = 0;
        public var casts:Object = {taunted: 0, missedTaunt: 0};

        private var host2:IFightHost;
        private var timers2:Array = [];
        private var playerClass:String;
        private var me:Object;
        private var bladeAt:Number = 2000;
        private var contractIdx:int = 0;
        private var beholdIdx:int = 0;
        private var tickAt:Number = 1000;
        private var partyAt:Number = 600;
        private var npcLooIdx:int = 0;
        private var npcLrIdx:int = 0;
        private var npcHarmonyAt:Number = 1500;
        private var npcOrdAt:Number = 0;
        private var npcDepravedAt:Number = 2500;
        private var cued:Object = {};
        private var looTauntCued:Object = {};
        private var nextCue:Object = {};
        private var lrShield:Number = 0;
        private var lrShieldUntil:Number = 0;
        private var lrHotUntil:Number = 0;

        public function NulgathFight(host:IFightHost, role:String, bossHp:Number, raidDps:Array)
        {
            super(host, role, bossHp, raidDps);
            host2 = host;
            playerClass = role;
            me = Dmg.profile(role);
            started = false;
            hp = {};
            somber = {};
            armor = {};
            for each (var r:String in NUL_ROLES)
            {
                hp[r] = START_HP[r];
                somber[r] = 0;
                armor[r] = 0;
                frailUntil[r] = 0;
                despairUntil[r] = 0;
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
            return playerClass == "lr" ? "loo" : "lr";
        }

        override public function startHint():String
        {
            return playerClass == "loo" ? "Use QUIX (5) on the Overfiend Blade to start the fight" : "Use a skill to start the fight (Lord of Order quixes the Blade)";
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
            var c:Object = NUL_SKILLS[playerClass];
            return c && c[n] ? c[n] : null;
        }

        override public function skillCdMs(name:String):Number
        {
            return name == "taunt" ? LISTED_CD[name] : Dmg.cooldown(LISTED_CD[name], me.haste);
        }

        override public function nextLabel():String
        {
            if (!started)
            {
                return "Waiting for your first skill";
            }
            var c:Number = contractIdx < CONTRACTS.length ? CONTRACTS[contractIdx] : 1e9;
            var b:Number = beholdIdx < BEHOLD.length ? BEHOLD[beholdIdx] : 1e9;
            if (c == 1e9 && b == 1e9)
            {
                return "Finish him";
            }
            return b < c ? "Abyssal Charge in " + Math.max(0, Math.ceil((b - t) / 1000)) + " s" : "Contract of the Abyss in " + Math.max(0, Math.ceil((c - t) / 1000)) + " s";
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
                host2.log(NUL_NAMES[role] + " died (" + why + ")", "bad");
                finish("lose", NUL_NAMES[role] + " died (" + why + ")"); // anybody dying loses the fight
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

        private function healAll(amount:Number, shown:Boolean):void
        {
            for each (var r:String in NUL_ROLES)
            {
                restore(r, amount, shown && r == playerRole);
            }
        }

        private function buffMax(until:Number):void
        {
            var old:Object = {};
            var r:String;
            for each (r in NUL_ROLES)
            {
                old[r] = maxHp(r);
            }
            harmonyUntil = until;
            for each (r in NUL_ROLES)
            {
                hp[r] = Math.round(hp[r] / old[r] * maxHp(r));
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

        private function dmgBoss(dmg:Number, crit:Boolean, who:String):void
        {
            if (over)
            {
                return;
            }
            var m:Number = t < depravedUntil ? 1.3 : 1;
            var d:int = int(Dmg.taken(dmg * m, 1, CAP));
            bossHp = Math.max(0, bossHp - d);
            host2.bossDamage(d, crit, who);
            if (bossHp <= 0)
            {
                finish("win", "Ultra Nulgath defeated");
            }
        }

        // ------------------------------------------------------------ the fight's start
        private function begin(firstSkill:String):void
        {
            started = true;
            if (playerClass == "loo")
            {
                quixed = firstSkill == "quix";
            }
            else
            {
                quixed = true; // the sim's Lord of Order quixes the Blade before the fight
            }
            if (quixed)
            {
                host2.log("Quix on the Overfiend Blade: its Sword Charge is stopped", "good");
            }
            else
            {
                host2.announce("I will shatter you to the core!");
                host2.bladeAnim("Charge", false);
                later(1000, function():void { host2.bladeAnim("Chargeloop", true); });
                later(5000, function():void {
                    host2.bladeAnim("ChargeAttack", false);
                    finish("lose", "Sword Charge: the Overfiend Blade needed Quix (skill 5) before the fight");
                });
            }
        }

        // -------------------------------------------------------------- Nulgath
        private function targets():Array
        {
            var holder:String = currentTaunt();
            var list:Array = [];
            if (holder != null && alive(holder))
            {
                list.push(holder);
                return list;
            }
            for each (var r:String in NUL_ROLES)
            {
                if (alive(r))
                {
                    list.push(r);
                }
            }
            return list;
        }

        private function contract():void
        {
            host2.bossAnim("Attack1", false);
            var holder:String = currentTaunt();
            if (holder == null)
            {
                casts.missedTaunt++;
                host2.floater(playerClass, "Missed Taunt", "bad");
                finish("lose", "Missed Taunt (Contract of the Abyss)");
                return;
            }
            casts.taunted++;
            for each (var r:String in targets())
            {
                if (t < despairUntil[r])
                {
                    host2.log("Contract of Stagnation on " + NUL_NAMES[r], "bad");
                    finish("lose", "Contract of Stagnation on " + NUL_NAMES[r] + ": taunt with somebody else each time");
                    return;
                }
                else if (t < frailUntil[r])
                {
                    despairUntil[r] = t + CONTRACT_MS;
                    host2.log("Contract of Despair on " + NUL_NAMES[r], "bad");
                    finish("lose", "Contract of Despair on " + NUL_NAMES[r] + ": taunt with somebody else each time");
                    return;
                }
                frailUntil[r] = t + CONTRACT_MS; // Contract of Frailty: defence -50 %
                host2.log("Contract of Frailty on " + NUL_NAMES[r], "");
            }
            later(1300, function():void { host2.bossAnim("Idle", false); });
        }

        private function abyssalCharge():void
        {
            host2.announce("Behold the power of the Abyss!");
            host2.bossAnim("Charge", false);
            later(800, function():void { host2.bossAnim("Chargeloop", true); });
            later(3000, function():void { host2.bossAnim("ChargeAttack", false); });
            later(4000, function():void {
                for each (var r:String in NUL_ROLES)
                {
                    if (alive(r))
                    {
                        var d:Number = 500 * Dmg.takenMul(Dmg.profile(r), false) / 0.55 * (t < frailUntil[r] ? 2 : 1);
                        hit(r, d, "Abyssal Charge");
                        if (over)
                        {
                            return;
                        }
                    }
                }
            });
            later(5200, function():void { host2.bossAnim("Idle", false); });
        }

        private function bladeAttack():void
        {
            host2.bladeAnim("Attack1", false);
            later(500, function():void {
                for each (var r:String in NUL_ROLES)
                {
                    if (!alive(r))
                    {
                        continue;
                    }
                    var d:Number = rnd(1750, 2150) * BLADE_ARMOR * (Dmg.takenMul(Dmg.profile(r), false) / 0.55) * (t < frailUntil[r] ? 2 : 1);
                    if (t < ordUntil)
                    {
                        d *= 0.7; // Ordinance
                    }
                    hit(r, d, "Overfiend Blade");
                    if (over)
                    {
                        return;
                    }
                }
            });
            later(1000, function():void { host2.bladeAnim("Idle", false); });
        }

        // ------------------------------------------------------- the player's skills
        override public function skillReady(n:int):Boolean
        {
            return !over && t >= cd[n];
        }

        private function haste():Number
        {
            return me.haste + (playerClass == "lr" && t < depravedUntil ? 20 : 0);
        }

        override public function swingEvery():Number
        {
            return Dmg.cooldown(AA[playerClass].cd, haste()) / 1000;
        }

        override public function swing():Object
        {
            var a:Object = AA[playerClass];
            var c:Boolean = Dmg.rollCrit(me);
            var d:Number = Dmg.hit(me, a.f, a.src, a.type, c, hp[playerRole], GEAR) * rnd(0.95, 1.05);
            mana = Math.min(100, mana + (playerClass == "lr" ? 15 : Dmg.manaFor(d, c, me.hp)));
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
            var cost:Number = SKILL[name].mp;
            if (mana < cost)
            {
                host2.floater(playerRole, "Not enough mana", "bad");
                return false;
            }
            mana -= cost;
            if (!started)
            {
                begin(name);
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

        private function healingOrdinance(actor:String):Number
        {
            var prof:Object = actor == playerClass ? me : Dmg.profile(actor);
            return Dmg.heal(prof, 0.5, "SP2", true, 0) * GEAR / 6 * HEAL_BOOST;
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
                case "wicked":
                case "anathema":
                    if (manual)
                    {
                        var c:Boolean = k.crit ? true : Dmg.rollCrit(me);
                        var d:Number = Dmg.hit(me, k.f, "AoE1", "magic", c, hp[playerRole], GEAR) * rnd(0.95, 1.05);
                        dmgBoss(d, c, "player");
                        mana = Math.min(100, mana + Dmg.manaFor(d, c, me.hp));
                    }
                    break;
                case "depraved":
                    depravedUntil = t + 12000;
                    lrShield = 0.3 * Dmg.profile("lr").sp * Dmg.WEAPON_BOOST; // Arcane Shield
                    lrShieldUntil = t + 12000;
                    lrHotUntil = t + 12000;
                    break;
                case "harmony":
                    buffMax(t + 10000);
                    break;
                case "ordinance":
                    ordUntil = t + 12000;
                    healAll(healingOrdinance(actor), manual);
                    break;
                case "axiom":
                    axiomUntil = t + 10000;
                    break;
                case "quix":
                    break; // on the Blade: handled when the fight starts
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
            if (t < frailUntil[playerRole])
            {
                list.push({name: "frailty", count: left(frailUntil[playerRole]), frac: frac(frailUntil[playerRole], CONTRACT_MS)});
            }
            if (t < depravedUntil)
            {
                list.push({name: "depraved", count: left(depravedUntil), frac: frac(depravedUntil, 12000)});
            }
            if (t < harmonyUntil)
            {
                list.push({name: "harmony", count: left(harmonyUntil), frac: frac(harmonyUntil, 10000)});
            }
            if (t < ordUntil)
            {
                list.push({name: "ordinance", count: left(ordUntil), frac: frac(ordUntil, 12000)});
            }
            if (t < axiomUntil)
            {
                list.push({name: "axiom", count: left(axiomUntil), frac: frac(axiomUntil, 10000)});
            }
            return list;
        }

        // ------------------------------------------------------ the sim's own class
        private function npcPlay():void
        {
            if (npcClass() == "loo" && alive("loo"))
            {
                if (npcLooIdx < NPC_LOO_TAUNTS.length && t >= NPC_LOO_TAUNTS[npcLooIdx])
                {
                    npcLooIdx++;
                    doSkill("taunt", "loo", false);
                }
                if (t >= npcHarmonyAt)
                {
                    npcHarmonyAt = t + 4200;
                    doSkill("harmony", "loo", false);
                }
                // heals when somebody is low
                var low:Boolean = false;
                for each (var r:String in NUL_ROLES)
                {
                    if (alive(r) && hp[r] < maxHp(r) * 0.6)
                    {
                        low = true;
                    }
                }
                if (low && t >= npcOrdAt)
                {
                    npcOrdAt = t + 6000;
                    doSkill("ordinance", "loo", false);
                }
            }
            else if (npcClass() == "lr" && alive("lr"))
            {
                if (npcLrIdx < BEHOLD.length && t >= BEHOLD[npcLrIdx] + 200)
                {
                    npcLrIdx++;
                    doSkill("taunt", "lr", false);
                }
                if (t >= npcDepravedAt)
                {
                    npcDepravedAt = t + 6000;
                    doSkill("depraved", "lr", false);
                }
            }
            // the player's cues
            if (playerClass == "loo")
            {
                // 5 s into the fight, then when the Contract debuff wears off
                var times:Array = [5000, 16000, 30000];
                for each (var at:Number in times)
                {
                    if (t >= at - 1200 && !looTauntCued[at])
                    {
                        looTauntCued[at] = true;
                        host2.mechanic("loo", "contract", int(at / 1000), 0);
                    }
                }
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
            if (t >= bladeAt)
            {
                bladeAt += 2250;
                bladeAttack();
            }
            if (contractIdx < CONTRACTS.length && t >= CONTRACTS[contractIdx])
            {
                contractIdx++;
                contract();
                if (over)
                {
                    return;
                }
            }
            if (beholdIdx < BEHOLD.length && t >= BEHOLD[beholdIdx])
            {
                beholdIdx++;
                abyssalCharge();
                if (playerClass == "lr")
                {
                    host2.mechanic("lr", "behold", beholdIdx, 0); // taunt now
                }
            }
            npcPlay();
            if (t >= tickAt)
            {
                tickAt += 1000;
                for each (var q:String in NUL_ROLES)
                {
                    restore(q, LIFESTEAL, false);
                    if (q == "lr" && t < lrHotUntil)
                    {
                        restore(q, 0.1 * maxHp("lr"), false);
                    }
                }
            }
            // the other characters play on their own, hit by hit (each hit is capped)
            if (t >= partyAt)
            {
                var tick:Number = rnd(600, 1100);
                var d:Number = 0;
                for each (var w:String in NUL_ROLES)
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
                    bossHp = Math.max(0, bossHp - d);
                    host2.bossDamage(int(d), false, "party");
                    if (bossHp <= 0)
                    {
                        finish("win", "Ultra Nulgath defeated");
                        return;
                    }
                }
                partyAt = t + tick;
            }
        }
    }
}

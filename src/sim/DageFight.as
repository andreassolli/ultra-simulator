package sim
{
    /**
     * Ultra Dage fight rules (Chaos Avenger / Classic Ninja).
     *
     * The boss' attacks, charge times, cooldowns, damage ranges, buffs / debuffs and the attack pattern are from the
     * wiki guide (ultradage.mdx); the class skills from classes.json (cooldowns shrink with the class' haste, see Dmg).
     * Numbers the guide does not give - party HP, the raid's damage, healing - are tuned so a correct run wins and
     * missed taunts / plates lose, see README. All times are in milliseconds.
     *
     * The party is Chaos Avenger, Classic Ninja and two DPS. Whoever the player is not is played by the sim: the
     * Chaos Avenger flux-taunts on cue, everybody runs to the lit plate and back.
     */
    public class DageFight extends Fight
    {
        public static const DAGE_ROLES:Array = ["ca", "cn", "da", "db"];
        public static const DAGE_NAMES:Object = {ca: "Chaos Avenger", cn: "ArchFiend", da: "Verus DoomKnight", db: "Low DPS"};

        /** player skill slots 2-6 per class (slot 1 is the auto attack, slot 6 is the potion slot) */
        public static const DAGE_SKILLS:Object = {
            ca: {2: "siphon", 3: "flux", 4: "bulwark", 5: "fury"},
            cn: {2: "crosscut", 3: "shadowblade", 4: "shadowburn", 5: "thinair"}
        };
        /** listed cooldowns (classes.json) before haste */
        private static const LISTED_CD:Object = {
            siphon: 6000, flux: 15000, bulwark: 6000, fury: 35000,
            crosscut: 2000, shadowblade: 12000, shadowburn: 6000, thinair: 30000
        };
        /** per skill: damage factor, damage source, mana cost (classes.json); flux always crits */
        private static const SKILL:Object = {
            siphon: {f: 1.2, src: "Leech1", mp: 50}, flux: {f: 1, src: "AP2", mp: 50, crit: true},
            bulwark: {f: 1, src: "AP2", mp: 50}, fury: {f: 2.5, src: "AP2", mp: 50},
            crosscut: {f: 1.5, src: "AP2", mp: 15}, shadowblade: {f: 0.5, src: "APSP2", mp: 25},
            shadowburn: {f: 0.5, src: "APSP2", mp: 5}, thinair: {f: 0, src: "AP1", mp: 30}
        };
        /**
         * Ultra builds have far larger stats than the calculator's test build, so every hit and heal is multiplied by
         * this to make the raid kill Dage in about the time it took before the calculator maths was put in.
         */
        private static const GEAR:Number = 14;
        private static const RESIST:Number = 0.5;   // Dage: 50 % physical and magical resistance
        private static const CAP:Number = 150000;   // "damage over 150 000 is reduced": excess ^ 0.8

        private static const CAST:Object = {auto: 500, decay: 500, zone: 3000, regen: 10000};
        private static const SLOT:Object = {auto: 2250, decay: 2250, zone: 4500, regen: 11500};
        /** the player may already have left the plate this long before the damage lands and still counts as on it (ms) */
        private static const PLATE_GRACE:int = 700;
        private static const START_AT:int = 400; // the first auto attack comes right after the player's first attack (it used to wait 2.5 s)

        private static const START_HP:Object = {ca: 4910, cn: 3670, da: 3670, db: 3670};
        private static const FOCUS_MS:int = 4000;
        private static const AETERNA_MS:int = 11000;
        private static const DECAY_MS:int = 11000;
        private static const ALLY_LIFESTEAL:Number = 330; // hp per second each ally gets back

        private static const GCD:int = 400;

        // ---- state shared with the HUD ------------------------------------------------------------
        public var aeterna:Object = {};      // role -> expiry times of its Aeterna Nox stacks
        public var decayUntil:Object = {};   // role -> Noxious Decay (healing inverted)
        public var cloak:Array = [];         // expiry times of Dage's Cloak of Darkness stacks
        public var mightUntil:Number = 0;    // Might of the Legion
        public var legionUntil:Number = 0;   // Legionnaire (Dage heals)
        public var bloodUntil:Number = 0;    // Blood Price
        public var siphonStacks:Array = [];  // Chaorrupt on Dage (+10 % damage taken each)
        public var bulwarkUntil:Number = 0;
        public var furyUntil:Number = 0;
        public var thinAirUntil:Number = 0;
        public var thinAirHits:int = 0;
        public var ravaged:int = 0;
        public var branded:Boolean = false;
        public var plateId:String = "";
        private var lastOnPlate:Number = -99999; // when the player was last on the lit plate
        public var casts:Object = {taunted: 0, missedTaunt: 0, plates: 0, missedPlate: 0};

        private var host2:IFightHost;
        private var timers2:Array = [];
        private var seqIdx:int = 0;       // position in the intro / loop
        private var zoneCount:int = 0;
        private var nextAt:Number = START_AT;
        private var regenAt:Number = 60000;
        private var queue:Array = [];     // abilities that come before the pattern resumes
        private var tauntDue:int = 0;     // autos still to be tanked after a Decaying Strike
        private var hpTickAt:Number = 1000;
        private var partyAt:Number = 600;
        private var legionTickAt:Number = 0;
        private var allyAt:Number = 0;
        private var playerClass:String;
        private var introCue:Boolean = false;
        private var me:Object;       // the player's stats (Dmg.profile)
        private var ally:Object = Dmg.profile("dps");

        public function DageFight(host:IFightHost, role:String, bossHp:Number, raidDps:Array)
        {
            super(host, role, bossHp, raidDps);
            host2 = host;
            playerClass = role;
            me = Dmg.profile(role);
            hp = {};
            somber = {};
            armor = {};
            for each (var r:String in DAGE_ROLES)
            {
                hp[r] = START_HP[r];
                somber[r] = 0;
                armor[r] = 0;
                aeterna[r] = [];
                decayUntil[r] = 0;
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

        private function newest(list:Array):Number
        {
            var m:Number = 0;
            for each (var until:Number in list)
            {
                m = Math.max(m, until);
            }
            return m;
        }

        public function aeternaStacks(r:String):int
        {
            return live(aeterna[r]);
        }

        public function cloakStacks():int
        {
            return live(cloak);
        }

        public function siphonCount():int
        {
            return live(siphonStacks);
        }

        public function newestAeterna(r:String):Number
        {
            return newest(aeterna[r]);
        }

        public function newestCloak():Number
        {
            return newest(cloak);
        }

        public function newestSiphon():Number
        {
            return newest(siphonStacks);
        }

        public function mightOn():Boolean
        {
            return t < mightUntil;
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
            var c:Object = DAGE_SKILLS[playerClass];
            return c && c[n] ? c[n] : null;
        }

        override public function skillCost(name:String):Number
        {
            return SKILL[name] ? (SKILL[name].mp) : 0;
        }

        override public function skillCdMs(name:String):Number
        {
            // Flux: the guide has a taunt for every Decaying Strike (9 s apart), which the listed 15 s and the class' cooldown reduction cannot do
            return name == "flux" ? 6000 : Dmg.cooldown(LISTED_CD[name], me.haste);
        }

        private function isTank(r:String):Boolean
        {
            return r == "ca";
        }

        /** damage taken multiplier of a role's armour against physical hits (autos, Summon Legion Mages) */
        private function physMul(r:String):Number
        {
            if (!isTank(r))
            {
                return Dmg.takenMul(Dmg.profile("ap"), false);
            }
            var m:Number = Dmg.takenMul(Dmg.profile("ca"), false); // Death Defiant: physical resistance 35 %
            if (playerClass != "ca" || t < bulwarkUntil)
            {
                m *= 0.4; // Chaotic Armor: the sim's Chaos Avenger keeps it up
            }
            return m;
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
            if (role == playerRole && playerClass == "cn")
            {
                thinAirHits++;
            }
            if (hp[role] <= 0)
            {
                fall(role, why);
            }
        }

        private function fall(role:String, why:String):void
        {
            host2.log(DAGE_NAMES[role] + " died (" + why + ")", "bad");
            host2.announce("Another soul to empower the Legion.");
            bossHp = Math.min(bossMaxHp, bossHp + 500000);
            finish("lose", DAGE_NAMES[role] + " died (" + why + ")"); // anybody dying loses the fight
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

        private function finish(result:String, reason:String):void
        {
            if (over)
            {
                return;
            }
            over = {result: result, reason: reason};
            host2.plate("");
            host2.ended(result, reason);
        }

        private function strike(dmg:Number, who:String):int
        {
            // Cloak of Darkness: +10 % defence per stack; Chaorrupt +10 % taken; Blood Price -30 % defence
            var m:Number = 1 / (1 + 0.1 * cloakStacks());
            m *= 1 + 0.1 * siphonCount();
            m *= t < bloodUntil ? 1.3 : 1;
            return int(Dmg.taken(dmg * m, RESIST, CAP));
        }

        private function dmgBoss(dmg:Number, crit:Boolean, who:String):void
        {
            if (over)
            {
                return;
            }
            var d:int = strike(dmg, who);
            bossHp = Math.max(0, bossHp - d);
            host2.bossDamage(d, crit, who);
            if (bossHp <= 0)
            {
                finish("win", "Ultra Dage defeated");
            }
        }

        // ------------------------------------------------------- boss pattern
        /** the ability at position i of the pattern */
        private function abilityAt(i:int):String
        {
            var intro:Array = ["auto", "auto", "auto", "auto", "decay", "auto", "auto"];
            if (i < intro.length)
            {
                return intro[i];
            }
            var loop:Array = ["zone", "decay", "auto", "auto", "X", "decay", "auto", "auto"];
            var k:int = (i - intro.length) % loop.length;
            if (loop[k] != "X")
            {
                return loop[k];
            }
            return "auto"; // Summon Legion Mages is on the clock instead, see regenDue()
        }

        /** Summon Legion Mages always starts at 1:00 (and every minute after): the next ability waits for it if it would run into it. */
        private function regenDue(ability:String):Boolean
        {
            return nextAt + SLOT[ability] > regenAt;
        }

        override public function nextLabel():String
        {
            var names:Object = {auto: "Auto attack", decay: "Decaying Strike", zone: "Summon Brute Undead (plate)", regen: "Summon Legion Mages"};
            var a:String = abilityAt(seqIdx);
            return names[regenDue(a) ? "regen" : a];
        }

        private function fire(ability:String):void
        {
            switch (ability)
            {
                case "auto":
                    autoAttack();
                    break;
                case "decay":
                    decaying();
                    break;
                case "zone":
                    brutes();
                    break;
                case "regen":
                    mages();
                    break;
            }
        }

        /** Focus is a taunt: while it lasts the boss' tauntable attacks go to the taunter only. */
        private function targets():Array
        {
            var list:Array = [];
            var holder:String = currentTaunt();
            if (holder != null && alive(holder))
            {
                list.push(holder);
                return list;
            }
            for each (var r:String in DAGE_ROLES)
            {
                if (alive(r))
                {
                    list.push(r);
                }
            }
            return list;
        }

        private function npcTank(delay:Number):void
        {
            if (playerClass == "ca" || !alive("ca"))
            {
                return;
            }
            later(delay, function():void {
                tauntRole = "ca";
                tauntUntil = t + FOCUS_MS;
                host2.castFx("taunt", "ca");
            });
        }

        private function autoAttack():void
        {
            host2.bossAnim("Attack1", false);
            // who is targeted is decided as the swing starts
            var picked:Array = targets();
            var taunted:Boolean = currentTaunt() != null;
            if (tauntDue > 0)
            {
                tauntDue--;
                if (playerClass == "ca" && !taunted)
                {
                    casts.missedTaunt++;
                    host2.floater("ca", "Missed Taunt", "bad");
                    host2.log("Auto attack hit everyone: no Focus after Decaying Strike", "bad");
                    later(CAST.auto, function():void { finish("lose", "Missed Taunt (auto attack)"); });
                }
                else if (taunted)
                {
                    casts.taunted++;
                }
            }
            later(CAST.auto, function():void {
                var mul:Number = mightOn() ? 2 : 1;
                for each (var r:String in picked)
                {
                    var d:Number = rnd(1495, 1827) * mul * physMul(r) * (1 + 0.15 * aeternaStacks(r));
                    hit(r, d, "Auto attack");
                    aeterna[r].push(t + AETERNA_MS);
                    if (over)
                    {
                        return;
                    }
                }
                cloak.push(t + AETERNA_MS);
            });
            later(1200, function():void { host2.bossAnim("Idle", false); });
        }

        private function decaying():void
        {
            host2.bossAnim("Attack2", false);
            later(CAST.decay, function():void {
                for each (var r:String in DAGE_ROLES)
                {
                    if (!alive(r))
                    {
                        continue;
                    }
                    hit(r, rnd(897, 1096), "Decaying Strike"); // true damage
                    decayUntil[r] = t + DECAY_MS;
                    if (over)
                    {
                        return;
                    }
                }
                tauntDue = 2;
                host2.log("Decaying Strike - healing is inverted for 11 s (Noxious Decay)", "bad");
                host2.mechanic("ca", "decay", 0, 0); // banner / bot cue: taunt now
            });
            npcTank(CAST.decay + 250);
            later(1300, function():void { host2.bossAnim("Idle", false); });
        }

        private function brutes():void
        {
            host2.announce("Cower behind your meager protection spells!");
            var id:String = Math.random() < 0.5 ? "a" : "b";
            plateId = id;
            host2.bossAnim("Powerup", false);
            host2.log("Summon Brute Undead - the " + (id == "a" ? "left" : "right") + " plate lights up", "bad");
            later(100, function():void { host2.plate(id); });
            later(800, function():void { host2.bossAnim("PowerLoop", true); });
            later(1900, function():void { host2.bossAnim("Aoe", false); });
            var missedBefore:int = casts.missedPlate;
            later(CAST.zone, function():void {
                for each (var r:String in DAGE_ROLES)
                {
                    if (!alive(r))
                    {
                        continue;
                    }
                    var on:Boolean = host2.roleOnPlate(r, id);
                    if (r == playerRole)
                    {
                        on = on || t - lastOnPlate <= PLATE_GRACE; // running off as the blast lands (or a moment before) is fine
                        casts[on ? "plates" : "missedPlate"]++;
                        if (!on)
                        {
                            finish("lose", "Missed the plate");
                            return;
                        }
                    }
                    hit(r, rnd(3986, 4871) * (on ? 0.2 : 1), on ? "Brute Undead (on the plate)" : "Brute Undead - off the plate");
                    if (over)
                    {
                        return;
                    }
                }
                host2.log(casts.missedPlate > missedBefore ? "You were off the plate!" : "Brute Undead absorbed by the plate (20 % damage)", casts.missedPlate > missedBefore ? "bad" : "good");
                plateId = "";
                host2.plate("");
            });
            later(CAST.zone + 800, function():void { host2.bossAnim("Idle", false); });
        }

        private function mages():void
        {
            host2.announce("I possess the full power of the Legion at my disposal.");
            tauntDue = 0; // a Decaying Strike's autos that the Legion Mages cut short no longer count
            mightUntil = t + 120000;
            legionUntil = t + 14000;
            legionTickAt = t + 1000;
            host2.log("Might of the Legion: Dage hits twice as hard for 120 s and heals", "bad");
            host2.bossAnim("Charge", false);
            later(3500, function():void { host2.bossAnim("ChargeLoop", true); });
            later(8000, function():void { host2.bossAnim("DageNuke", false); });
            later(6000, function():void { host2.mechanic("ca", "regen", 0, 0); }); // tauntable: taunt now
            npcTank(8200);
            var picked:Array = null;
            later(CAST.regen, function():void {
                picked = targets();
                var tauntedNow:Boolean = currentTaunt() != null;
                if (playerClass == "ca" && !tauntedNow)
                {
                    casts.missedTaunt++;
                    host2.floater("ca", "Missed Taunt", "bad");
                    finish("lose", "Missed Taunt (Summon Legion Mages)");
                    return;
                }
                else if (tauntedNow)
                {
                    casts.taunted++;
                }
                for each (var r:String in picked)
                {
                    hit(r, rnd(2989, 3654) * 2 * physMul(r), "Summon Legion Mages");
                    if (over)
                    {
                        return;
                    }
                }
                bloodUntil = t + 20000;
                host2.log("Blood Price - Dage takes more damage for 20 s", "good");
                host2.announce("I will feast on your souls, mortals!");
            });
            later(CAST.regen + 1000, function():void { host2.bossAnim("Idle", false); });
        }

        // ------------------------------------------------- the player's skills
        override public function skillReady(n:int):Boolean
        {
            return !over && t >= cd[n];
        }

        /** haste in %: the class' own, Unstoppable Force (Fury Unleashed) +25, Thin Air +5 per hit */
        private function haste():Number
        {
            var h:Number = me.haste;
            if (playerClass == "ca" && t < furyUntil)
            {
                h += 25;
            }
            if (t < thinAirUntil)
            {
                h += 5 * thinAirHits;
            }
            return h;
        }

        override public function swingEvery():Number
        {
            return Dmg.cooldown(playerClass == "ca" ? 3000 : 1500, haste()) / 1000;
        }

        private function outMul():Number
        {
            return t < furyUntil ? 1.5 : 1;
        }

        private function variance():Number
        {
            return rnd(0.95, 1.05);
        }

        override public function swing():Object
        {
            var c:Boolean = Dmg.rollCrit(me);
            var base:Number = Dmg.hit(me, playerClass == "ca" ? 1.3 : 0.8, playerClass == "ca" ? "Avenger1" : "AP1", "phys", c, hp[playerRole], GEAR) * variance() * outMul();
            if (playerClass == "ca")
            {
                mana = Math.min(100, mana + 60); // "recovers 60 mana on hit"
                if (branded)
                {
                    branded = false;
                    base *= 2; // Chaos Greatsword on a Branded target
                    ravaged = Math.min(8, ravaged + 1);
                }
            }
            var d:int = strike(base, "player");
            restore(playerRole, d * 0.1, false);
            return {dmg: base, crit: c};
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
            started = true; // the first skill starts the fight
            cd[n] = t + skillCdMs(name);
            doSkill(name);
            for (var k:int = 2; k <= 6; k++)
            {
                if (cd[k] - t < 1000)
                {
                    cd[k] = Math.max(cd[k], t + GCD);
                }
            }
            return true;
        }

        private function skillDamage(name:String):void
        {
            var k:Object = SKILL[name];
            var c:Boolean = k.crit ? true : Dmg.rollCrit(me);
            var d:Number = Dmg.hit(me, k.f, k.src, name == "shadowblade" || name == "shadowburn" ? "magic" : "phys", c, hp[playerRole], GEAR) * variance() * outMul();
            dmgBoss(d, c, "player");
            restore(playerRole, strike(d, "player") * 0.1, false);
        }

        private function doSkill(name:String):void
        {
            host2.castFx(name, playerRole);
            switch (name)
            {
                case "siphon":
                    skillDamage("siphon");
                    siphonStacks = pruned(siphonStacks);
                    if (live(siphonStacks) < 4)
                    {
                        siphonStacks.push(t + 15000);
                    }
                    branded = true;
                    restore(playerRole, 600, true); // drains life
                    break;
                case "flux":
                    skillDamage("flux");
                    tauntRole = "ca";
                    tauntUntil = t + FOCUS_MS;
                    branded = true;
                    break;
                case "bulwark":
                    skillDamage("bulwark");
                    bulwarkUntil = t + 15000;
                    branded = true;
                    break;
                case "fury":
                    skillDamage("fury");
                    if (ravaged > 0)
                    {
                        furyUntil = t + 10000;
                        ravaged = 0;
                    }
                    else
                    {
                        furyUntil = Math.max(furyUntil, t + 1); // Unstoppable Force (haste) only
                    }
                    branded = true;
                    break;
                case "crosscut":
                    skillDamage("crosscut");
                    break;
                case "shadowblade":
                case "shadowburn":
                    skillDamage(name);
                    break;
                case "thinair":
                    thinAirUntil = t + 30000;
                    thinAirHits = 0;
                    break;
            }
        }

        private function pruned(list:Array):Array
        {
            var out:Array = [];
            for each (var until:Number in list)
            {
                if (until > t)
                {
                    out.push(until);
                }
            }
            return out;
        }

        /** What is on Dage / on the player, for the buff icons: {name, count, frac}. */
        override public function activeBuffs():Array
        {
            var list:Array = [];
            var frac:Function = function(until:Number, total:Number):Number { return Math.max(0, Math.min(1, (until - t) / total)); };
            var left:Function = function(until:Number):String { return String(Math.ceil((until - t) / 1000)); };
            // on Dage
            if (currentTaunt() != null)
            {
                list.push({name: "focusflux", count: "", frac: frac(tauntUntil, FOCUS_MS)}); // Chaos Avenger taunts with Flux (3): its icon, not the taunt skull
            }
            var n:int = cloakStacks();
            if (n > 0)
            {
                list.push({name: "cloak", count: String(n), frac: frac(newestCloak(), AETERNA_MS)});
            }
            if (mightOn())
            {
                list.push({name: "might", count: left(mightUntil), frac: frac(mightUntil, 120000)});
            }
            if (t < legionUntil)
            {
                list.push({name: "legion", count: left(legionUntil), frac: frac(legionUntil, 14000)});
            }
            if (t < bloodUntil)
            {
                list.push({name: "blood", count: left(bloodUntil), frac: frac(bloodUntil, 20000)});
            }
            n = siphonCount();
            if (n > 0)
            {
                list.push({name: "siphon", count: String(n), frac: frac(newestSiphon(), 15000)});
            }
            // on the player
            n = aeternaStacks(playerRole);
            if (n > 0)
            {
                list.push({name: "aeterna", count: String(n), frac: frac(newestAeterna(playerRole), AETERNA_MS)});
            }
            if (t < decayUntil[playerRole])
            {
                list.push({name: "decay", count: left(decayUntil[playerRole]), frac: frac(decayUntil[playerRole], DECAY_MS)});
            }
            if (playerClass == "ca" && t < bulwarkUntil)
            {
                list.push({name: "bulwark", count: left(bulwarkUntil), frac: frac(bulwarkUntil, 15000)});
            }
            if (playerClass == "ca" && t < furyUntil && furyUntil - t > 1)
            {
                list.push({name: "fury", count: left(furyUntil), frac: frac(furyUntil, 10000)});
            }
            if (playerClass == "cn" && t < thinAirUntil)
            {
                list.push({name: "thinair", count: String(thinAirHits), frac: frac(thinAirUntil, 30000)});
            }
            return list;
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
            if (plateId != "" && host2.roleOnPlate(playerRole, plateId))
            {
                lastOnPlate = t;
            }
            if (!introCue && t >= START_AT + 1100)
            {
                // the guide: flux the 2nd auto attack of the opening (it and the 3rd are covered by Focus)
                introCue = true;
                tauntDue = 2;
                host2.mechanic("ca", "intro", 0, 0);
                npcTank(200);
            }
            if (t >= nextAt)
            {
                var ability:String = abilityAt(seqIdx);
                if (queue.length > 0)
                {
                    var q1:String = queue.shift();
                    fire(q1);
                    nextAt = t + SLOT[q1];
                }
                else if (regenDue(ability))
                {
                    if (t >= regenAt)
                    {
                        fire("regen");
                        nextAt = t + SLOT.regen;
                        queue = ["decay", "auto", "auto"]; // as in the guide: Legion Mages, Decaying Strike, 2 autos
                        regenAt += 60000;
                    }
                }
                else
                {
                    fire(ability);
                    nextAt = t + SLOT[ability];
                    seqIdx++;
                }
            }
            for each (var r:String in DAGE_ROLES)
            {
                somber[r] = aeternaStacks(r);
            }
            // once a second: Chaotic Armor ticks (inverted by Noxious Decay), allies' life steal, Dage's Legionnaire heal
            if (t >= hpTickAt)
            {
                hpTickAt += 1000;
                for each (var q:String in DAGE_ROLES)
                {
                    if (!alive(q))
                    {
                        continue;
                    }
                    if (q != playerRole)
                    {
                        restore(q, ALLY_LIFESTEAL + (isTank(q) ? 450 : 0), false); // the Avenger also drains with Chaos Siphon
                    }
                    if (isTank(q) && (playerClass != "ca" || t < bulwarkUntil))
                    {
                        if (t < decayUntil[q])
                        {
                            hit(q, 150, "Noxious Decay (Chaotic Armor)");
                        }
                        else
                        {
                            restore(q, 150, false);
                        }
                    }
                    if (over)
                    {
                        return;
                    }
                }
                if (t < legionUntil)
                {
                    bossHp = Math.min(bossMaxHp, bossHp + 55000);
                }
            }
            // the other three characters play on their own: the calculator's hit of a standard build, at its haste
            if (t >= partyAt)
            {
                var tick:Number = rnd(600, 1100);
                var d:Number = 0;
                var perHit:Number = Dmg.average(ally, 1.3, "AP2", "phys") * GEAR;
                var hitsPerSec:Number = 1000 / Dmg.cooldown(1500, ally.haste);
                for each (var w:String in DAGE_ROLES)
                {
                    if (w != playerRole && alive(w))
                    {
                        d += perHit * hitsPerSec * tick / 1000;
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

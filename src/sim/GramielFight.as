package sim
{
    /**
     * Ultra Gramiel fight rules (Shaman + the sim's Legion Revenant, StoneCrusher and Lord of Order), from ultragramiel.mdx.
     *
     * Phase 1: two Grace Crystals (400 HP, 1 damage from each attack, every hit on them reflects 150 damage back) and Gramiel (every hit
     * does 1 damage). Gramiel: Glory of Grace every 2.25 s on everybody, Grace Burst (60 % of everybody's current HP) after four of them,
     * and after the third Burst Grace Drain ("break his guard!", 5 s): Safeguard soaks 20 hits, everybody has to hit Gramiel until it is gone.
     * Crystal Charge every 14 s ("The Grace Crystal prepares a defense shattering attack!", 4 s) has to be taunted on both crystals by two
     * different characters each time: the player sends "1" in the chat (the player on the right crystal + StoneCrusher on the left) or "2"
     * (Lord of Order on the right + Legion Revenant on the left); the same pair twice in a row gets Grace Shattered twice. If a Crystal dies
     * more than 5 s before the other one (Crystal Unstable) the fight is lost, so the player has to balance his hits between the two.
     *
     * Phase 2 (7 500 000 HP, damage over 125 000 reduced): Celestial Ruin (tauntable) on whoever taunts the boss, each hit is a Vendetta
     * stack (45 s); more than four hits in a row on the same character lose. The player taunts first and then types "LOO" / "SC" / "LR" to
     * have the next one taunt. Death's Door (60 % of current HP) every four auto attacks on everybody with Vendetta, Grace Unleashed after
     * three of them (kills five stacks) and Celestial Vanquish at 70 / 40 / 10 % (everybody needs a Vendetta stack, then they are cleared).
     *
     * Anybody dying, a missed taunt or an unbroken shield loses the fight. Hit rates, regeneration and the Burning Ward reflect are tuned.
     */
    public class GramielFight extends Fight
    {
        public static const G_ROLES:Array = ["sh", "lr", "sc", "loo"];
        public static const G_NAMES:Object = {sh: "Shaman", lr: "Legion Revenant", sc: "StoneCrusher", loo: "Lord of Order"};
        public static const G_SKILLS:Object = {2: "flame", 3: "hydro", 4: "lightning", 5: "embrace", 6: "taunt"};
        private static const LISTED_CD:Object = {flame: 4000, hydro: 4000, lightning: 16000, embrace: 16000, taunt: 10000};
        private static const MP:Object = {flame: 15, hydro: 15, lightning: 30, embrace: 30, taunt: 0};
        // damage factor / source of the Shaman's spells (classes.json: EE1 / Pyro1 / EE3 are taken as SP1, Elemental Embrace is SP2)
        private static const SPELL:Object = {flame: {f: 2, src: "SP1", aoe: true}, hydro: {f: 1, src: "SP1", aoe: true}, lightning: {f: 3, src: "SP1"}, embrace: {f: 0.3, src: "SP2"}};
        private static const START_HP:Object = {sh: 3125, lr: 2910, sc: 2810, loo: 3505};
        private static const SIDE:Object = {sh: "cr", loo: "cr", lr: "cl", sc: "cl"};
        private static const GROUP:Object = {1: ["sh", "sc"], 2: ["lr", "loo"]};
        /** hits per second of the sim's characters on a crystal (auto attacks + skills + DoT ticks) */
        private static const RATE:Object = {lr: 1.0, sc: 1.1, loo: 1.2};
        private static const SIDE_NAME:Object = {cl: "left", cr: "right"};

        private static const CRYSTAL_HP:int = 400;
        private static const SHIELD:int = 20;
        private static const TAUNT_MS:int = 7000;
        private static const CAP:Number = 125000;
        private static const GEAR:Number = 12;            // tuned so each leg between Celestial Vanquishes lasts about 25 s
        private static const PARTY_GEAR:Number = 1.5;    // the sim's characters deal a small steady share in Phase 2; the Shaman does most of the damage
        private static const STOP_MARGIN:Number = 450000; // "stop around" this much above the next threshold
        private static const PARTY_STOP:Number = 300000;  // the others stop attacking this close to it until the Unleashed text
        private static const ARMOR:Number = 0.2 / 0.55;  // what is left of the listed monster damage (as in the Nulgath fight)
        private static const REFLECT_K:Number = 0.1;     // Burning Ward: listed reflect x this x the character's damage taken
        private static const REGEN:Number = 0.065;       // of max HP per second: lifesteal, potions, the other healers
        private static const GCD:int = 400;
        private static const THRESHOLDS:Array = [0.7, 0.4, 0.1];

        // ---- state shared with the HUD ------------------------------------------------------------
        public var phase:int = 1;                      // 1, 15 = Grace Charge (transition), 2
        public var crystalHp:Object = {cl: CRYSTAL_HP, cr: CRYSTAL_HP};
        public var crystalMax:int = CRYSTAL_HP;
        public var shield:int = 0;                     // Safeguard hits left while Gramiel drains
        public var draining:Boolean = false;
        public var crystalTaunt:Object = {cl: {role: null, until: 0}, cr: {role: null, until: 0}};
        public var shattered:Object = {};              // role -> expiry times of Grace Shattered
        public var vendetta:Object = {};               // role -> expiry times of Vendetta stacks
        public var holder:String = null;               // Phase 2: who holds Gramiel
        public var holderHits:int = 0;                 // consecutive auto attacks on the holder
        public var invulnUntil:Number = 0;             // Celestial Vanquish
        public var scorchedUntil:Number = 0;           // the player's Ancestor's Flame
        public var embraceUntil:Number = 0;
        public var hotUntil:Number = 0;
        public var startAtPhase2:Boolean = false;      // the start screen's option: begin right when the crystals die
        public var chargeN:int = 0;                    // Crystal Charges so far
        public var casts:Object = {hits: 0, taunted: 0};

        private var host2:IFightHost;
        private var timers2:Array = [];
        private var me:Object;
        private var p1Token:int = 0;
        private var p1Seq:int = 0;
        private var p2Seq:int = 0;
        private var gloryUntil:Number = 0;
        private var glory:int = 0;
        private var nextChargeAt:Number = -1;
        private var nextGroup:int = 1;
        private var crystalAaAt:Number = 3000;
        private var crystalAaSeen:Boolean = false;
        private var unstableAt:Number = 0;
        private var drainEndedAt:Number = -99999;
        private var drainStartAt:Number = 0;
        private var acc:Object = {lr: 0, sc: 0, loo: 0};
        private var wobble:Object = {};
        private var tickAt:Number = 1000;
        private var partyAt:Number = 600;
        private var npcCd:Object = {lr: 0, sc: 0, loo: 0};
        private var vanquishIdx:int = 0;
        private var lastBalanceNote:Number = 0;
        private var chargeBusyUntil:Number = 0;
        private var cued:Boolean = false;
        private var dotTarget:String = "";
        private var nextCueRole:String = "loo";

        public function GramielFight(host:IFightHost, role:String, bossHp:Number, raidDps:Array)
        {
            super(host, role, bossHp, raidDps);
            host2 = host;
            me = Dmg.profile("shaman");
            started = false;
            targetSel = "cr";
            hp = {};
            somber = {};
            armor = {};
            for each (var r:String in G_ROLES)
            {
                hp[r] = START_HP[r];
                somber[r] = 0;
                armor[r] = 0;
                shattered[r] = [];
                vendetta[r] = [];
            }
            for each (var w:String in ["lr", "sc", "loo"])
            {
                wobble[w] = {amp: 0.22 + Math.random() * 0.1, period: 17000 + Math.random() * 22000, phase: Math.random() * 6.28};
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

        public function stacks(role:String):int
        {
            return count(vendetta[role], t);
        }

        public function shatteredStacks(role:String):int
        {
            return count(shattered[role], t);
        }

        override public function startHint():String
        {
            return startAtPhase2 ? "Use a skill to start Phase 2 (Gramiel transforms for 5 s)" : "Use a skill to start the fight - target a Grace Crystal (click) and keep both crystals even";
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
            return G_SKILLS[n] ? G_SKILLS[n] : null;
        }

        override public function skillCdMs(name:String):Number
        {
            return name == "taunt" ? LISTED_CD[name] : Dmg.cooldown(LISTED_CD[name], me.haste);
        }

        override public function skillReady(n:int):Boolean
        {
            return !over && t >= cd[n];
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
            hp[role] = Math.max(0, hp[role] - dmg);
            if (shown && dmg > 0)
            {
                host2.floater(role, "-" + Fight.fmt(dmg), "dmg");
            }
            if (role == playerRole)
            {
                mana = Math.min(100, mana + 1.2); // a Shaman gains mana when struck
            }
            if (hp[role] <= 0)
            {
                host2.log(G_NAMES[role] + " died (" + why + ")", "bad");
                finish("lose", G_NAMES[role] + " died (" + why + ")");
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

        private function listed(a:Number, b:Number, role:String, magical:Boolean = false):Number
        {
            return rnd(a, b) * ARMOR * Dmg.takenMul(Dmg.profile(role == "sh" ? "shaman" : role), magical);
        }

        // ------------------------------------------------------------ the fight's start
        private function begin():void
        {
            started = true;
            if (startAtPhase2)
            {
                crystalHp = {cl: 0, cr: 0};
                targetSel = "boss";
                startPhase2();
                return;
            }
            host2.log("Phase 1: keep both Grace Crystals even and taunt every Crystal Charge (chat: 1 or 2)", "");
            host2.bossAnim("Idle", false);
            p1Next();
        }

        // ------------------------------------------------------------ Phase 1: Gramiel
        private function p1Next():void
        {
            if (over || phase != 1)
            {
                return;
            }
            var token:int = p1Token;
            var seq:int = p1Seq % 16;
            p1Seq++;
            if (seq == 0)
            {
                // exactly two Crystal Charges before each Grace Drain: group 1, then group 2
                nextChargeAt = t + 7000;
                nextGroup = 1;
                later(7000, function():void {
                    if (token == p1Token && !over && phase == 1)
                    {
                        crystalCharge(1);
                        nextChargeAt = t + 14000;
                        nextGroup = 2;
                    }
                });
                later(21000, function():void {
                    if (token == p1Token && !over && phase == 1)
                    {
                        crystalCharge(2);
                        nextChargeAt = -1;
                    }
                });
            }
            if (seq == 15)
            {
                startDrain();
                return;
            }
            var burst:Boolean = seq % 5 == 4;
            later(burst ? 1000 : 2250, function():void {
                if (token != p1Token || over || phase != 1)
                {
                    return;
                }
                if (burst)
                {
                    graceBurst();
                }
                else
                {
                    gloryOfGrace();
                }
                p1Next();
            });
        }

        private function gloryOfGrace():void
        {
            host2.bossAnim("Attack1", false);
            later(1300, function():void { restIdle(); });
            if (t > gloryUntil)
            {
                glory = 0;
            }
            var m:Number = 1 + 0.02 * Math.min(glory, 30);
            for each (var r:String in G_ROLES)
            {
                if (alive(r))
                {
                    hurt(r, listed(204, 249, r) * m, "Glory of Grace", r == playerRole);
                    if (over)
                    {
                        return;
                    }
                }
            }
            glory += 4;
            gloryUntil = t + 12000;
        }

        private function graceBurst():void
        {
            host2.bossAnim("Attack2", false);
            later(1300, function():void { restIdle(); });
            for each (var r:String in G_ROLES)
            {
                if (alive(r))
                {
                    hurt(r, hp[r] * 0.6, "Grace Burst", r == playerRole);
                    if (over)
                    {
                        return;
                    }
                }
            }
        }

        private function restIdle():void
        {
            if (!over && !draining && invulnUntil < t && !unleashing)
            {
                host2.bossAnim("Idle", false);
            }
        }

        private function startDrain():void
        {
            draining = true;
            shield = SHIELD;
            drainStartAt = t;
            var token:int = p1Token;
            host2.announce("Gramiel attempts to drain your power... break his guard!");
            host2.bossAnim("Charge1", false);
            host2.mechanic(playerRole, "drain", 0, 0);
            later(900, function():void { if (draining) { host2.bossAnim("ChargeLoop1", true); } });
            later(5000, function():void {
                if (token != p1Token || over || !draining)
                {
                    return;
                }
                host2.bossAnim("ChargeAttack1", false);
                finish("lose", "Grace Drain: the shield was not broken in time (Grace Drained / Grace Absorbed)");
            });
        }

        private function shieldBroken():void
        {
            draining = false;
            drainEndedAt = t;
            host2.log("Safeguard broken: Grace Drain stopped", "good");
            host2.bossAnim("Hit", false);
            later(900, function():void { restIdle(); });
            later(1500, function():void { p1Next(); });
        }

        // --------------------------------------------------------- Phase 1: the crystals
        private function crystalCharge(group:int):void
        {
            chargeN++;
            chargeBusyUntil = t + 5300;
            host2.announce("The Grace Crystal prepares a defense shattering attack!");
            host2.mechanic(playerRole, "charge", group, chargeN);
            var token:int = p1Token;
            for each (var s:String in ["cl", "cr"])
            {
                if (crystalHp[s] > 0)
                {
                    host2.crystalAnim(s, "Charge", false);
                }
            }
            later(900, function():void {
                for each (var s2:String in ["cl", "cr"])
                {
                    if (crystalHp[s2] > 0 && phase == 1)
                    {
                        host2.crystalAnim(s2, "ChargeLoop", true);
                    }
                }
            });
            later(4000, function():void {
                if (token != p1Token || over || phase != 1)
                {
                    return;
                }
                resolveCharge();
            });
        }

        private function resolveCharge():void
        {
            for each (var s:String in ["cl", "cr"])
            {
                if (crystalHp[s] <= 0)
                {
                    continue;
                }
                host2.crystalAnim(s, "ChargeAttack", false);
                var tk:Object = crystalTaunt[s];
                if (tk.role == null || t > tk.until || !alive(tk.role))
                {
                    host2.log("Nobody taunted the " + SIDE_NAME[s] + " Crystal Charge", "bad");
                    finish("lose", "Missed Taunt: the " + SIDE_NAME[s] + " Grace Crystal's Charge hit everybody");
                    return;
                }
                casts.taunted++;
                var who:String = tk.role;
                if (shatteredStacks(who) >= 1)
                {
                    host2.log("Grace Shattered x2 on " + G_NAMES[who], "bad");
                    finish("lose", "Grace Shattered twice on " + G_NAMES[who] + ": taunt the Crystal Charges with the other pair each time");
                    return;
                }
                shattered[who].push(t + 20000);
                host2.floater(who, "Grace Shattered", "bad");
                if (shatteredStacks(who) >= 1 && who == playerRole)
                {
                    host2.log("Grace Shattered on you (20 s): the next charge is for the other pair", "");
                }
            }
            later(1300, function():void {
                for each (var s2:String in ["cl", "cr"])
                {
                    if (crystalHp[s2] > 0 && phase == 1)
                    {
                        host2.crystalAnim(s2, "Idle", false);
                    }
                }
            });
        }

        private function crystalAutoAttack():void
        {
            if (!crystalAaSeen)
            {
                crystalAaSeen = true;
                host2.announce("The crystals damages all attackers!");
            }
            for each (var s:String in ["cl", "cr"])
            {
                if (crystalHp[s] > 0)
                {
                    host2.crystalAnim(s, "Attack1", false);
                }
            }
            for each (var r:String in G_ROLES)
            {
                if (alive(r))
                {
                    hurt(r, rnd(27, 33) * Dmg.takenMul(Dmg.profile(r == "sh" ? "shaman" : r), false), "Grace Crystal", false); // the default monster damage 27-33
                    if (over)
                    {
                        return;
                    }
                }
            }
            later(1500, function():void {
                for each (var s2:String in ["cl", "cr"])
                {
                    if (crystalHp[s2] > 0 && phase == 1 && !crystalCharging())
                    {
                        host2.crystalAnim(s2, "Idle", false);
                    }
                }
            });
        }

        private function crystalCharging():Boolean
        {
            return t < chargeBusyUntil;
        }

        /** One hit on whatever `role` is attacking, with Burning Ward's reflect on the attacker. */
        private function hitTarget(role:String, sel:String, shown:Boolean):void
        {
            if (over || !alive(role))
            {
                return;
            }
            if (phase != 1)
            {
                return;
            }
            casts.hits++;
            if (sel == "boss")
            {
                bossHp = Math.max(1, bossHp - 1);
                if (draining)
                {
                    shield--;
                    if (shield <= 0)
                    {
                        shieldBroken();
                    }
                    return;
                }
                hurt(role, 300 * REFLECT_K * Dmg.takenMul(Dmg.profile(role == "sh" ? "shaman" : role), false), "Burning Ward", shown);
                return;
            }
            if (crystalHp[sel] <= 0)
            {
                return;
            }
            crystalHp[sel]--;
            if (role == playerRole)
            {
                mana = Math.min(100, mana + 0.6);
            }
            hurt(role, 150 * REFLECT_K * Dmg.takenMul(Dmg.profile(role == "sh" ? "shaman" : role), false), "Burning Ward", false);
            if (crystalHp[sel] <= 0)
            {
                crystalDied(sel);
            }
        }

        private function crystalDied(side:String):void
        {
            host2.crystalAnim(side, "Die", false);
            host2.log("The " + SIDE_NAME[side] + " Grace Crystal is destroyed", "good");
            var other:String = side == "cl" ? "cr" : "cl";
            if (crystalHp[other] > 0)
            {
                unstableAt = t + 5000;
                host2.announce("The remaining Grace Crystal is unstable, destroy it quickly!");
                host2.mechanic(playerRole, "unstable", 0, 0);
                var token:int = p1Token;
                later(5000, function():void {
                    if (token == p1Token && !over && phase == 1 && crystalHp[other] > 0)
                    {
                        host2.crystalAnim(other, "ChargeAttack", false);
                        finish("lose", "Crystal Unstable: the " + SIDE_NAME[other] + " Grace Crystal was not destroyed within 5 s of the other one - keep them even");
                    }
                });
            }
            else
            {
                startPhase2();
            }
        }

        // ---------------------------------------------------------------- Phase 2
        private var unleashing:Boolean = false;
        public var burstOpen:Boolean = false;           // Grace Unleashed has been shouted: burst Gramiel down to the threshold
        private var stopCued:Boolean = false;
        public var auraUntil:Number = 0;                // Grace Unleashed's icon: no taunting until it fades
        public var tauntedLeg:Object = {sh: false, lr: false, sc: false, loo: false}; // who has taunted since the last Celestial Vanquish

        private function startPhase2():void
        {
            phase = 15;
            p1Token++;
            draining = false;
            glory = 0;
            holder = null;
            host2.announce("I will usher the world into an age of prosperity!");
            host2.bossAnim("Charge1", false);
            host2.log("Phase 2: Gramiel is transforming - taunt him when it is over", "");
            later(900, function():void { host2.bossAnim("ChargeLoop1", true); });
            later(5000, function():void {
                if (over)
                {
                    return;
                }
                phase = 2;
                host2.bossAnim("ChargeAttack1", false);
                later(1000, function():void { restIdle(); });
                host2.mechanic(playerRole, "p2start", 0, 0);
                p2Next(4500);
            });
        }

        private function p2Next(delay:Number):void
        {
            if (over)
            {
                return;
            }
            var seq:int = p2Seq % 16;
            p2Seq++;
            later(delay, function():void {
                if (over)
                {
                    return;
                }
                if (seq == 15)
                {
                    graceUnleashed();
                    return;
                }
                if (seq % 5 == 4)
                {
                    deathsDoor();
                    p2Next(1000);
                }
                else
                {
                    celestialRuin();
                    p2Next(2250);
                }
            });
        }

        private function celestialRuin():void
        {
            host2.bossAnim("Attack3", false);
            later(1300, function():void { restIdle(); });
            if (holder == null || !alive(holder))
            {
                host2.log("Nobody taunted Gramiel", "bad");
                finish("lose", "Missed Taunt: Celestial Ruin hit everybody");
                return;
            }
            if (t < invulnUntil)
            {
                return; // Invulnerable: the hit does nothing and adds no stack
            }
            holderHits++;
            var n:int = stacks(holder);
            vendetta[holder].push(t + 45000);
            hurt(holder, listed(626, 765, holder) * (1 + 0.4 * n), "Celestial Ruin", holder == playerRole);
            if (over)
            {
                return;
            }
            if (holderHits > 4)
            {
                finish("lose", G_NAMES[holder] + " was hit " + holderHits + " times in a row by Celestial Ruin: pass the taunt on after two hits");
                return;
            }
        }

        private function deathsDoor():void
        {
            host2.bossAnim("Attack2", false);
            later(1300, function():void { restIdle(); });
            for each (var r:String in G_ROLES)
            {
                if (alive(r) && stacks(r) > 0 && t >= invulnUntil)
                {
                    hurt(r, hp[r] * 0.6, "Death's Door", r == playerRole);
                    if (over)
                    {
                        return;
                    }
                }
            }
        }

        private function graceUnleashed():void
        {
            unleashing = true;
            auraUntil = t + 8000;
            burstOpen = true;
            stopCued = false;
            host2.mechanic(playerRole, "burst", 0, 0);
            host2.announce("All servants of the 'Liberator' must die!");
            host2.bossAnim("Charge1", false);
            later(900, function():void { host2.bossAnim("ChargeLoop1", true); });
            later(5000, function():void {
                if (over)
                {
                    return;
                }
                unleashing = false;
                host2.bossAnim("ChargeAttack1", false);
                for each (var r:String in G_ROLES)
                {
                    if (alive(r))
                    {
                        if (stacks(r) >= 5)
                        {
                            finish("lose", G_NAMES[r] + " had 5 stacks of Vendetta when Grace Unleashed hit");
                            return;
                        }
                        hurt(r, listed(157, 192, r, true) * (stacks(r) > 0 ? 1.5 : 1), "Grace Unleashed", r == playerRole);
                        if (over)
                        {
                            return;
                        }
                    }
                }
                later(1000, function():void { restIdle(); });
                p2Next(1500);
            });
        }

        private function checkVanquish():void
        {
            if (vanquishIdx >= THRESHOLDS.length || phase != 2 || t < invulnUntil)
            {
                return;
            }
            var limit:Number = bossMaxHp * THRESHOLDS[vanquishIdx];
            if (bossHp > limit)
            {
                return;
            }
            vanquishIdx++;
            bossHp = limit;
            invulnUntil = t + 5000;
            burstOpen = false;
            stopCued = false;
            host2.announce("The Shadow Fiend lends their aid to those at Death's Door.");
            host2.bossAnim("Charge2", false);
            later(900, function():void { host2.bossAnim("ChargeLoop2", true); });
            host2.mechanic(playerRole, "vanquish", vanquishIdx, 0);
            var without:Array = [];
            for each (var r:String in G_ROLES)
            {
                if (alive(r) && stacks(r) == 0)
                {
                    without.push(r);
                }
            }
            later(5000, function():void {
                if (over)
                {
                    return;
                }
                host2.bossAnim("ChargeAttack2", false);
                later(1000, function():void { restIdle(); });
                if (without.length > 0)
                {
                    host2.announce("What? You Survived? What parlour trick is this?");
                    finish("lose", "Celestial Vanquish: " + G_NAMES[without[0]] + " had no Vendetta stack (everybody has to taunt once before each threshold)");
                    return;
                }
                for each (var q:String in G_ROLES)
                {
                    vendetta[q] = [];
                }
                holderHits = 0; // whoever taunts him keeps the aggro until the Shaman takes it again
                cued = false;
                tauntedLeg = {sh: false, lr: false, sc: false, loo: false};
                host2.log("Vendetta cleared - taunt again, starting with you", "");
                host2.mechanic(playerRole, "p2start", 0, 0);
            });
        }

        // -------------------------------------------------------------- taunts and chat
        private function tauntBy(role:String):void
        {
            if (phase == 1)
            {
                var side:String = SIDE[role];
                crystalTaunt[side] = {role: role, until: t + TAUNT_MS};
                host2.castFx("taunt", role);
                host2.log(G_NAMES[role] + " taunts the " + SIDE_NAME[side] + " Grace Crystal", "");
            }
            else if (phase == 2 || phase == 15)
            {
                if (t < auraUntil)
                {
                    finish("lose", G_NAMES[role] + " taunted while Gramiel's aura was still up: wait for the icon to fade");
                    return;
                }
                if (tauntedLeg[role])
                {
                    finish("lose", G_NAMES[role] + " taunted twice before the Shadow Fiend: everybody taunts once between the thresholds");
                    return;
                }
                tauntedLeg[role] = true;
                if (holder != role)
                {
                    holderHits = 0;
                    holder = role;
                    cued = false;
                }
                host2.castFx("taunt", role);
                host2.log(G_NAMES[role] + " taunts Gramiel", "");
            }
        }

        private function npcTaunt(role:String, delayMs:Number):void
        {
            if (!alive(role) || t < npcCd[role])
            {
                host2.log(G_NAMES[role] + "'s taunt is not ready", "bad");
                return;
            }
            npcCd[role] = t + 10000 + delayMs;
            later(delayMs, function():void {
                if (!over && alive(role))
                {
                    tauntBy(role);
                }
            });
        }

        override public function chat(text:String):void
        {
            if (over || !started)
            {
                return;
            }
            var s:String = text.toLowerCase();
            if (phase == 1)
            {
                var one:int = s.indexOf("1");
                var two:int = s.indexOf("2");
                var g:int = one >= 0 && (two < 0 || one < two) ? 1 : (two >= 0 ? 2 : 0);
                if (g == 1)
                {
                    npcTaunt("sc", rnd(450, 800));
                }
                else if (g == 2)
                {
                    npcTaunt("lr", rnd(450, 800));
                    npcTaunt("loo", rnd(450, 800));
                }
                return;
            }
            // Phase 2: who is asked to taunt next
            var asked:String = null;
            if (s.indexOf("loo") >= 0 || s.indexOf("lord") >= 0 || s.indexOf("order") >= 0)
            {
                asked = "loo";
            }
            else if (s.indexOf("sc") >= 0 || s.indexOf("stone") >= 0 || s.indexOf("crush") >= 0)
            {
                asked = "sc";
            }
            else if (s.indexOf("lr") >= 0 || s.indexOf("legion") >= 0 || s.indexOf("rev") >= 0)
            {
                asked = "lr";
            }
            if (asked != null)
            {
                npcTaunt(asked, rnd(450, 800));
            }
        }

        // ------------------------------------------------------- the player's skills
        private function haste():Number
        {
            return me.haste;
        }

        override public function swingEvery():Number
        {
            return Dmg.cooldown(2000, haste()) / 1000;
        }

        override public function swing():Object
        {
            var c:Boolean = Dmg.rollCrit(me);
            var d:Number = Dmg.hit(me, 0.9, "AP2", "phys", c, hp[playerRole], GEAR) * rnd(0.95, 1.05);
            mana = Math.min(100, mana + (c ? 6 : 4));
            return {dmg: d, crit: c};
        }

        override public function playerHit(dmg:Number, isCrit:Boolean):void
        {
            playerStrike(dmg, isCrit, 1);
        }

        /** the player's attack on his target: Phase 1 = `hits` hits of 1 damage, Phase 2 = real damage */
        private function playerStrike(dmg:Number, crit:Boolean, hits:int):void
        {
            if (!host2.inPlace(playerRole))
            {
                return; // not next to the target
            }
            if (phase == 1)
            {
                for (var i:int = 0; i < hits; i++)
                {
                    hitTarget(playerRole, targetSel, false);
                }
            }
            else if (phase == 2 && targetSel == "boss")
            {
                dmgBoss(dmg, crit, "player");
            }
        }

        private function dmgBoss(dmg:Number, crit:Boolean, who:String):void
        {
            if (over || t < invulnUntil)
            {
                return;
            }
            var d:int = int(Dmg.taken(dmg, 1, CAP));
            bossHp = Math.max(0, bossHp - d);
            host2.bossDamage(d, crit, who);
            if (bossHp <= 0)
            {
                finish("win", "Ultra Gramiel defeated");
                return;
            }
            checkVanquish();
        }

        override public function cast(n:int):Boolean
        {
            var name:String = skillName(n);
            if (name == null || !skillReady(n))
            {
                return false;
            }
            var cost:Number = MP[name];
            if (mana < cost)
            {
                host2.floater(playerRole, "Not enough mana", "bad");
                return false;
            }
            if (phase != 15 && !host2.inPlace(playerRole))
            {
                host2.floater(playerRole, "Move next to your target", "bad");
                return false;
            }
            mana -= cost;
            if (!started)
            {
                begin();
            }
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

        private function doSkill(name:String):void
        {
            host2.castFx(name, playerRole);
            if (name == "taunt")
            {
                if (phase == 1)
                {
                    if (targetSel == "boss")
                    {
                        host2.log("Taunt wasted: select a Grace Crystal (the right one)", "bad");
                        return;
                    }
                    crystalTaunt[targetSel] = {role: playerRole, until: t + TAUNT_MS};
                    host2.log("You taunt the " + SIDE_NAME[targetSel] + " Grace Crystal", "");
                }
                else
                {
                    if (targetSel != "boss")
                    {
                        targetSel = "boss";
                    }
                    tauntBy(playerRole);
                }
                return;
            }
            var k:Object = SPELL[name];
            var c:Boolean = Dmg.rollCrit(me);
            var boost:Number = t < embraceUntil && name != "embrace" ? 1.4 : 1;
            var f:Number = k.f * (name == "hydro" && t < scorchedUntil ? 2 : 1);
            var d:Number = Dmg.hit(me, f, k.src, "magic", c, 0, GEAR) * boost * rnd(0.95, 1.05);
            mana = Math.min(100, mana + (c ? 3 : 2));
            switch (name)
            {
                case "flame":
                    scorchedUntil = t + 5000;
                    dotTarget = targetSel;
                    if (phase == 1)
                    {
                        // Scorched Spirit: a DoT tick each second for 5 s on what it was cast on
                        var sel:String = targetSel;
                        for (var i:int = 1; i <= 5; i++)
                        {
                            later(i * 1000, function():void { aoeHit(sel); });
                        }
                    }
                    else
                    {
                        for (var j:int = 1; j <= 5; j++)
                        {
                            later(j * 1000, function():void { if (targetSel == "boss") { dmgBoss(d * 0.18, false, "player"); } });
                        }
                    }
                    break;
                case "hydro":
                    hotUntil = t + 6000;
                    break;
                case "embrace":
                    embraceUntil = t + 15000;
                    break;
            }
            if (SPELL[name].aoe)
            {
                if (phase == 1)
                {
                    aoeHit(targetSel);
                }
                else
                {
                    playerStrike(d, c, 1);
                }
            }
            else
            {
                playerStrike(d, c, 1);
            }
        }

        /** Flame / Hydrophobia hit up to three targets: both crystals, and Gramiel too when he is the target */
        private function aoeHit(sel:String):void
        {
            if (!host2.inPlace(playerRole))
            {
                return;
            }
            hitTarget(playerRole, "cl", false);
            hitTarget(playerRole, "cr", false);
            if (sel == "boss")
            {
                hitTarget(playerRole, "boss", false);
            }
        }

        override public function activeBuffs():Array
        {
            var list:Array = [];
            var frac:Function = function(until:Number, total:Number):Number { return Math.max(0, Math.min(1, (until - t) / total)); };
            var left:Function = function(until:Number):String { return String(Math.ceil((until - t) / 1000)); };
            // on the boss / crystals
            if (draining)
            {
                list.push({name: "safeguard", count: String(shield), frac: -1});
            }
            if (t < invulnUntil)
            {
                list.push({name: "invuln", count: left(invulnUntil), frac: frac(invulnUntil, 5000)});
            }
            if (phase == 1 && started)
            {
                var tk:Object = crystalTaunt[targetSel == "cl" ? "cl" : "cr"];
                if (targetSel != "boss" && tk.role != null && t < tk.until)
                {
                    list.push({name: "focus", count: "", frac: frac(tk.until, TAUNT_MS)});
                }
            }
            else if (phase == 2 && holder != null)
            {
                list.push({name: "focus", count: "", frac: -1});
            }
            // on us
            var n:int = stacks(playerRole);
            if (t < auraUntil)
            {
                list.push({name: "aura", count: "", frac: frac(auraUntil, 8000)});
            }
            if (n > 0)
            {
                list.push({name: "vendetta", count: String(n), frac: -1});
            }
            if (shatteredStacks(playerRole) > 0)
            {
                list.push({name: "shattered", count: "", frac: frac(shattered[playerRole][shattered[playerRole].length - 1], 20000)});
            }
            if (t < embraceUntil)
            {
                list.push({name: "embrace", count: left(embraceUntil), frac: frac(embraceUntil, 15000)});
            }
            if (t < scorchedUntil)
            {
                list.push({name: "scorched", count: left(scorchedUntil), frac: frac(scorchedUntil, 5000)});
            }
            if (t < hotUntil)
            {
                list.push({name: "hot", count: left(hotUntil), frac: frac(hotUntil, 6000)});
            }
            return list;
        }

        override public function nextLabel():String
        {
            if (!started)
            {
                return "Waiting for your first skill";
            }
            if (phase == 1)
            {
                if (draining)
                {
                    return "Shield: " + shield + " hits left - hit him";
                }
                if (nextChargeAt < 0)
                {
                    return "Grace Drain is coming";
                }
                return "Crystal Charge in " + Math.max(0, Math.ceil((nextChargeAt - t) / 1000)) + " s - send " + nextGroup;
            }
            if (phase == 15)
            {
                return "Gramiel transforms...";
            }
            return holder == null ? "Taunt Gramiel (6)" : G_NAMES[holder] + " taunts him (" + holderHits + " hits)" + (cued ? " - send " + (nextCueRole == "sh" ? "nothing: taunt yourself (6)" : G_NAMES[nextCueRole]) : "");
        }

        /** what `role` is attacking right now: "boss" | "cl" | "cr" (the characters stand next to it and face it) */
        public function targetOf(role:String):String
        {
            if (role == playerRole)
            {
                return targetSel;
            }
            if (startAtPhase2 || phase != 1 || (draining && t - drainStartAt > 600))
            {
                return "boss";
            }
            var sel:String = SIDE[role];
            if (crystalHp[sel] <= 0)
            {
                sel = sel == "cl" ? "cr" : "cl";
            }
            return sel;
        }

        // ------------------------------------------------------------ the sim's characters
        private function npcHits(dtMs:Number):void
        {
            var anyAlive:Boolean = crystalHp.cl > 0 || crystalHp.cr > 0;
            for each (var r:String in ["lr", "sc", "loo"])
            {
                if (!alive(r))
                {
                    continue;
                }
                var w:Object = wobble[r];
                var mult:Number = 1 + w.amp * Math.sin(t / w.period * 6.28 + w.phase);
                var rate:Number = RATE[r] * mult;
                var sel:String = targetOf(r);
                if (draining)
                {
                    rate *= 1.4;
                }
                if (!host2.inPlace(r))
                {
                    continue; // still walking to its target
                }
                acc[r] += rate * dtMs / 1000;
                while (acc[r] >= 1)
                {
                    acc[r] -= 1;
                    hitTarget(r, sel, false);
                    if (over || phase != 1)
                    {
                        return;
                    }
                }
            }
        }

        private function partyDamage():void
        {
            if (t < partyAt || phase != 2)
            {
                return;
            }
            var tick:Number = rnd(600, 1100);
            var d:Number = 0;
            for each (var w:String in ["lr", "sc", "loo"])
            {
                if (alive(w))
                {
                    var pw:Object = Dmg.profile(w);
                    var caster:Boolean = pw.sp > pw.ap;
                    var perHit:Number = Dmg.average(pw, 1.0, caster ? "SP2" : "AP2", caster ? "magic" : "phys") * PARTY_GEAR;
                    var hits:Number = 1000 / Dmg.cooldown(1500, pw.haste) * tick / 1000;
                    d += Dmg.taken(perHit, 1, CAP) * hits;
                }
            }
            partyAt = t + tick;
            var nextLimit:Number = vanquishIdx < THRESHOLDS.length ? bossMaxHp * THRESHOLDS[vanquishIdx] : 0;
            if (d > 0 && t >= invulnUntil && !(vanquishIdx < THRESHOLDS.length && !burstOpen && bossHp <= nextLimit + PARTY_STOP))
            {
                bossHp = Math.max(0, bossHp - d);
                host2.bossDamage(int(d), false, "party");
                if (bossHp <= 0)
                {
                    finish("win", "Ultra Gramiel defeated");
                    return;
                }
                checkVanquish();
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
            if (phase == 1)
            {
                if (t >= crystalAaAt)
                {
                    crystalAaAt += 2250;
                    crystalAutoAttack();
                    if (over)
                    {
                        return;
                    }
                }
                npcHits(dtMs);
                if (over)
                {
                    return;
                }
            }
            else
            {
                partyDamage();
                if (over)
                {
                    return;
                }
                if (phase == 2 && !stopCued && !burstOpen && vanquishIdx < THRESHOLDS.length && t >= invulnUntil && bossHp <= bossMaxHp * THRESHOLDS[vanquishIdx] + STOP_MARGIN)
                {
                    stopCued = true;
                    host2.mechanic(playerRole, "stop", vanquishIdx + 1, 0);
                }
                phase2Cues();
            }
            if (t >= tickAt)
            {
                tickAt += 1000;
                for each (var q:String in G_ROLES)
                {
                    restore(q, REGEN * maxHp(q) * (q == "sh" && t < hotUntil ? 1.8 : 1), false);
                }
            }
        }

        private function balanceHint():void
        {
            if (t - lastBalanceNote < 6000 || (crystalHp.cl <= 0 || crystalHp.cr <= 0))
            {
                return;
            }
            var diff:int = crystalHp.cl - crystalHp.cr; // positive: the left one is ahead (more HP left)
            if (Math.abs(diff) >= 22)
            {
                lastBalanceNote = t;
                host2.showBanner("Uneven crystals: hit the " + (diff > 0 ? "LEFT" : "RIGHT") + " one (" + Math.abs(diff) + " HP more)", false, 2500);
            }
        }

        /** Phase 2 prompt: two hits on the holder, the player sends the next one's name */
        private function phase2Cues():void
        {
            if (phase != 2 || holder == null || t < invulnUntil || cued || holderHits < 2)
            {
                return;
            }
            if (tauntedLeg.sh && tauntedLeg.lr && tauntedLeg.sc && tauntedLeg.loo)
            {
                cued = true; // everybody has taunted: wait for the Shadow Fiend
                return;
            }
            cued = true;
            nextCueRole = nextInOrder(holder);
            host2.mechanic(playerRole, "pass", holderHits, 0);
        }

        /** the recommended order: Shaman (DPS), Lord of Order, StoneCrusher, Legion Revenant */
        public static function nextInOrder(role:String):String
        {
            switch (role)
            {
                case "sh":
                    return "loo";
                case "loo":
                    return "sc";
                case "sc":
                    return "lr";
                default:
                    return "sh";
            }
        }

        /** a short JSON of what a test needs to see */
        public function debug():String
        {
            return "{\"phase\":" + phase + ",\"cl\":" + crystalHp.cl + ",\"cr\":" + crystalHp.cr + ",\"charge\":" + chargeN + ",\"drain\":" + draining + ",\"shield\":" + shield +
                ",\"holder\":\"" + holder + "\",\"holderHits\":" + holderHits + ",\"vend\":{\"sh\":" + stacks("sh") + ",\"lr\":" + stacks("lr") + ",\"sc\":" + stacks("sc") + ",\"loo\":" + stacks("loo") + "},\"hits\":" + casts.hits + ",\"target\":\"" + targetSel + "\"}";
        }
    }
}

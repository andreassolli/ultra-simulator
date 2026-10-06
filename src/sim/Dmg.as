package sim
{
    /**
     * Damage / healing maths of the AQWDex calculator (github.com/Shell1010/aqwdex, backend/src/damage.rs and
     * player.rs), used for everything the players deal and heal in the Ultra Dage and Champion Drakath fights:
     *
     *   damage = source * typeModifier * weaponBoost * skill.damage
     *   source:  AP1 = weaponDps + 0.1 AP,  AP2 = 2 * AP1 * range   (SP1 / SP2 with spell power, APSP = both)
     *   type:    physical = allOut * physOut * crit,  magical = allOut * magOut * crit,
     *            true = crit,  DoT = allOut^2 * magOut * dotOut
     *   crit:    critMod (%) of the stats when the hit crits, 100 % otherwise
     *   cooldowns and cast speed shrink with haste: cd * (1 - haste)
     *
     * What the calculator does not have - the attack sources AoE1 / EX1 / Chrono2 / Avenger1 / Leech1 of classes.json
     * and the real stat totals of an ultra build (class_builds.json in its repository is empty) - is assumed, see
     * the comments at each place and README.
     */
    public class Dmg
    {
        // weapon of the calculator's defaults
        public static const WEAPON_DPS:Number = 85;
        public static const WEAPON_RANGE:Number = 1;
        public static const WEAPON_BOOST:Number = 1.51 * 1.5; // Boost51x50

        /**
         * Stat totals of each class at level 100 with its enhancements, as given for this project (resistances and
         * boosts in %, `haste` is the Cooldown Reduction stat, `hit` the Hit Chance).
         *   Paladin Chronomancer: Lucky Mana Vamp weapon, Lucky class, Healer helm, Penitence cape
         *   Legion Revenant:      Arcana's Concerto weapon, Lucky class, Forge helm, Penitence cape
         *   Lord of Order:        Lucky Awe Blast weapon, Lucky class, Healer helm, Penitence cape
         *   Chaos Avenger:        Dauntless weapon, Lucky class, Anima helm, Vainglory cape
         *   ArchPaladin:          Valiance weapon, Lucky class, Forge helm, Penitence cape
         *   Shaman (later boss):  Elysium weapon, Wizard class and helm, Vainglory cape, Sage Tonic + Malevolence Elixir
         */
        private static const CLASSES:Object = {
            pc: {ap: 737, sp: 741, critChance: 25.24, critMod: 276.35, hit: 107.40, haste: 26.31, dodge: 22.37, hp: 4970,
                dmgRes: 45, physRes: 0, magRes: 38.22, allOut: 100, physOut: 100, magOut: 138.22, dotOut: 75, healOut: 120, healIn: 100},
            lr: {ap: 282, sp: 1108, critChance: 31.63, critMod: 391.27, hit: 99.68, haste: 20.86, dodge: 19.87, hp: 2910,
                dmgRes: 25, physRes: 0, magRes: 53.46, allOut: 100, physOut: 100, magOut: 193.46, dotOut: 75, healOut: 100, healIn: 100},
            loo: {ap: 252, sp: 969, critChance: 20.70, critMod: 372.22, hit: 109.75, haste: 47.43, dodge: 17.78, hp: 3505,
                dmgRes: 50, physRes: 0, magRes: 45.97, allOut: 100, physOut: 100, magOut: 145.97, dotOut: 75, healOut: 100, healIn: 100},
            ca: {ap: 1757, sp: 284, critChance: 76.02, critMod: 265.56, hit: 108.53, haste: 11.64, dodge: 20.03, hp: 4910,
                dmgRes: 0, physRes: 35, magRes: 13.59, allOut: 115, physOut: 100, magOut: 100, dotOut: 100, healOut: 100, healIn: 50},
            ap: {ap: 877, sp: 877, critChance: 29.94, critMod: 372.22, hit: 108.69, haste: 11.64, dodge: 21.64, hp: 3670,
                dmgRes: 45, physRes: 0, magRes: 40.13, allOut: 120, physOut: 100, magOut: 140.13, dotOut: 75, healOut: 100, healIn: 100},
            shaman: {ap: 152, sp: 1706, critChance: 39.69, critMod: 300.48, hit: 103.35, haste: 32.34, dodge: 23.96, hp: 3125,
                dmgRes: 0, physRes: 0, magRes: 80, allOut: 115, physOut: 100, magOut: 222.78, dotOut: 75, healOut: 100, healIn: 50}
        };

        /** The stats of a class; any other key (the sim's DPS characters) gets the ArchPaladin's. */
        public static function profile(cls:String):Object
        {
            var src:Object = CLASSES[cls] ? CLASSES[cls] : CLASSES.ap;
            var p:Object = {};
            for (var k:String in src)
            {
                p[k] = src[k];
            }
            return p;
        }

        /** Multiplier on the physical / magical damage a character takes: (1 - damage resistance) x (1 - type resistance). */
        public static function takenMul(p:Object, magical:Boolean):Number
        {
            return (1 - p.dmgRes / 100) * (1 - (magical ? p.magRes : p.physRes) / 100);
        }

        /** The value a skill's damage source gives, `curHp` is the caster's current HP (intHP). */
        public static function source(src:String, p:Object, curHp:Number):Number
        {
            var ap1:Number = WEAPON_DPS + 0.1 * p.ap;
            var sp1:Number = WEAPON_DPS + 0.1 * p.sp;
            switch (src)
            {
                case "AP2":
                    return 2 * ap1 * WEAPON_RANGE;
                case "SP2":
                    return 2 * sp1 * WEAPON_RANGE;
                case "APSP1":
                    return WEAPON_DPS + 0.1 * p.ap + 0.1 * p.sp;
                case "APSP2":
                    return 2 * (WEAPON_DPS + 0.1 * p.ap + 0.1 * p.sp) * WEAPON_RANGE;
                case "intHP":
                    return curHp;
                case "cHPm":
                    return p.hp;
                case "SP1":
                case "AoE1": // not in the calculator: a spell source, taken as SP1
                case "EX1":
                    return sp1;
                default: // AP1, Avenger1 and Leech1 (not in the calculator) are taken as AP1
                    return ap1;
            }
        }

        /** type: "phys" | "magic" | "true" | "dot" */
        public static function typeMod(type:String, p:Object, crit:Boolean):Number
        {
            var c:Number = crit ? p.critMod / 100 : 1;
            switch (type)
            {
                case "magic":
                    return (p.allOut / 100) * (p.magOut / 100) * c;
                case "true":
                    return c;
                case "dot":
                    return Math.pow(p.allOut / 100, 2) * (p.magOut / 100) * (p.dotOut / 100);
                default:
                    return (p.allOut / 100) * (p.physOut / 100) * c;
            }
        }

        public static function rollCrit(p:Object):Boolean
        {
            return Math.random() * 100 < p.critChance;
        }

        /** One hit of a skill with `factor` (the JSON's "damage") before the target's resistances. */
        public static function hit(p:Object, factor:Number, src:String, type:String, crit:Boolean, curHp:Number = 0, boost:Number = 1):Number
        {
            return source(src, p, curHp) * typeMod(type, p, crit) * WEAPON_BOOST * factor * boost;
        }

        /** Average damage of a hit with the crit chance taken into account. */
        public static function average(p:Object, factor:Number, src:String, type:String):Number
        {
            var c:Number = p.critChance / 100;
            return hit(p, factor, src, type, false) * (1 - c) + hit(p, factor, src, type, true) * c;
        }

        /** What is left after the target's resistance (a multiplier, 0.5 = takes half) and the "damage over X" cap: the excess is raised to 0.8. */
        public static function taken(dmg:Number, resist:Number, cap:Number):Number
        {
            var d:Number = dmg * resist;
            if (d > cap)
            {
                d = cap + Math.pow(d - cap, 0.8);
            }
            return d;
        }

        /** Cooldown after haste, in ms. */
        public static function cooldown(listedMs:Number, hastePct:Number):Number
        {
            return listedMs * (1 - Math.min(hastePct, 90) / 100);
        }

        /** A heal (JSON "damage" below zero): same as a hit on the healing power, never above the target's maximum. */
        public static function heal(p:Object, factor:Number, src:String, crit:Boolean, curHp:Number = 0):Number
        {
            return Math.abs(factor) * source(src, p, curHp) * (crit ? p.critMod / 100 : 1) * (p.healOut / 100) * WEAPON_BOOST;
        }
    }
}

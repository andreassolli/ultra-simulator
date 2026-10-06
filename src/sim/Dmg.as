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
         * Stat totals of an ultra build. The numbers are the calculator's own test build (AP 1156, SP 798, crit 56.44 %,
         * crit damage 323.97 %, haste 32.72 %, hit 118.63 %, +20 % all damage) changed by each class' passives from classes.json.
         */
        public static function profile(cls:String):Object
        {
            var p:Object = {ap: 1156, sp: 798, critChance: 56.44, critMod: 323.97, haste: 32.72, hit: 118.63,
                allOut: 120, physOut: 100, magOut: 138.35, dotOut: 100, healOut: 100, hp: 3600};
            switch (cls)
            {
                case "ca": // Unending Rage: STR +50 %, crit +10 %; Wall of Chaorruption: crit +15 %
                    p.ap = 1156 * 1.5;
                    p.critChance += 25;
                    p.magOut = 100;
                    p.haste = 60; // the guide needs a Flux for every Decaying Strike, which only works with this much haste
                    p.hp = 4800;
                    break;
                case "lr": // Shadow Step: WIS +20 %; Dark Scholar: magic damage +40 %, crit damage +40 %
                    p.ap = 300;
                    p.sp = 1156;
                    p.magOut = 138.35 + 40;
                    p.critMod += 40;
                    p.hp = 4800;
                    break;
                case "pc": // Dauntless / Virtuous: hit +10 %; Sacred Blessing: haste +5 %, healing +20 %
                    p.hit += 10;
                    p.haste += 5;
                    p.healOut = 120;
                    p.hp = 4800;
                    break;
            }
            p.critChance = Math.min(100, p.critChance);
            return p;
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

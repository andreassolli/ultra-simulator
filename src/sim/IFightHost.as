package sim
{
    /**
     * What the Fight needs from the scene around it (boss clip, zone overlay,
     * floating text, the player's position ...).
     */
    public interface IFightHost
    {
        /** Play a boss animation label (Idle, Attack1, Shadowflame, ChargeA, ...). */
        function bossAnim(label:String, loop:Boolean):void;

        /** Equal zone telegraph on/off; role is the role that must stand inside. */
        function zone(on:Boolean, role:String):void;

        function announce(text:String):void;

        /** Floating combat text; role == null means "centre of the screen". kind: dmg|crit|heal|bad */
        function floater(role:String, text:String, kind:String):void;

        function log(message:String, kind:String):void;

        /** Is the player standing inside the SafeA box? */
        function playerInZone():Boolean;

        /** Is the player close enough to the middle to use Arch Paladin skills? */
        function playerCentered():Boolean;

        /** Cosmetic cast effect (kind = skill id) on a role's character. */
        function castFx(kind:String, role:String):void;

        /** Damage to the boss; who = "party" | "player". */
        function bossDamage(amount:int, crit:Boolean, who:String):void;

        /** The cast that is about to start requires `role` to hold the boss. */
        function mechanic(role:String, ability:String, truthN:int, zoneN:int):void;

        function ended(result:String, reason:String):void;

        /** Ultra Nulgath: an animation label for the Overfiend Blade. */
        function bladeAnim(label:String, loop:Boolean):void;

        /** Ultra Gramiel: an animation label for the left ("cl") or right ("cr") Grace Crystal. */
        function crystalAnim(side:String, label:String, loop:Boolean):void;

        /** Ultra Gramiel: a chat line said by `role` (speech bubble over the character and a line in the log). */
        function say(role:String, text:String):void;

        /** A banner line over the boss, `alert` = red (do something now) instead of yellow. */
        function showBanner(text:String, alert:Boolean, ms:Number):void;

        /** Ultra Dage: light the plate `id` ("a" | "b"), or switch the plates off with "". */
        function plate(id:String):void;

        /** Ultra Dage: is `role`'s character standing on plate `id`? */
        function roleOnPlate(role:String, id:String):Boolean;
    }
}

package ui
{
    import flash.display.Bitmap;

    /** Buff / debuff icon shown next to the HUD frames. */
    [Embed(source="/_assets/buffs/vendetta_shield.png")]
    public class BuffVendettaShield extends Bitmap
    {
        public function BuffVendettaShield()
        {
            super();
            smoothing = true;
        }
    }
}

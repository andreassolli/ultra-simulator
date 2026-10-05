package ui
{
    import flash.display.Bitmap;

    /** Buff / debuff icon shown next to the HUD frames. */
    [Embed(source="/_assets/buffs/noxiousdecay.png")]
    public class BuffNoxiousDecay extends Bitmap
    {
        public function BuffNoxiousDecay()
        {
            super();
            smoothing = true;
        }
    }
}

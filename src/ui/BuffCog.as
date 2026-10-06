package ui
{
    import flash.display.Bitmap;

    /** Buff / debuff icon shown next to the HUD frames. */
    [Embed(source="/_assets/buffs/cog.png")]
    public class BuffCog extends Bitmap
    {
        public function BuffCog()
        {
            super();
            smoothing = true;
        }
    }
}

package ui
{
    import flash.display.Bitmap;

    /** Buff / debuff icon shown next to the HUD frames. */
    [Embed(source="/_assets/buffs/stasis.png")]
    public class BuffStasis extends Bitmap
    {
        public function BuffStasis()
        {
            super();
            smoothing = true;
        }
    }
}

package ui
{
    import flash.display.Bitmap;

    /** Buff / debuff icon shown next to the HUD frames. */
    [Embed(source="/_assets/buffs/aeternanox.png")]
    public class BuffAeternaNox extends Bitmap
    {
        public function BuffAeternaNox()
        {
            super();
            smoothing = true;
        }
    }
}

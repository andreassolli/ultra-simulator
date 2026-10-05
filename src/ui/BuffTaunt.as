package ui
{
    import flash.display.Bitmap;

    /** Buff / debuff icon shown next to the HUD frames. */
    [Embed(source="/_assets/buffs/taunt.png")]
    public class BuffTaunt extends Bitmap
    {
        public function BuffTaunt()
        {
            super();
            smoothing = true;
        }
    }
}

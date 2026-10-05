package ui
{
    import flash.display.Bitmap;

    /** Buff / debuff icon shown next to the HUD frames. */
    [Embed(source="/_assets/buffs/magiaburn.png")]
    public class BuffMagiaBurn extends Bitmap
    {
        public function BuffMagiaBurn()
        {
            super();
            smoothing = true;
        }
    }
}

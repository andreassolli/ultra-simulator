package ui
{
    import flash.display.Bitmap;

    /** Buff / debuff icon shown next to the HUD frames. */
    [Embed(source="/_assets/buffs/somber.png")]
    public class BuffSomber extends Bitmap
    {
        public function BuffSomber()
        {
            super();
            smoothing = true;
        }
    }
}

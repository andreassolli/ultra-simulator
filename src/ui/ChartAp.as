package ui
{
    import flash.display.Bitmap;

    /** Buff / debuff icon shown next to the HUD frames. */
    [Embed(source="/_assets/charts/ap.png")]
    public class ChartAp extends Bitmap
    {
        public function ChartAp()
        {
            super();
            smoothing = true;
        }
    }
}

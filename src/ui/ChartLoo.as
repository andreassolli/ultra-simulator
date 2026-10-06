package ui
{
    import flash.display.Bitmap;

    /** Buff / debuff icon shown next to the HUD frames. */
    [Embed(source="/_assets/charts/loo.png")]
    public class ChartLoo extends Bitmap
    {
        public function ChartLoo()
        {
            super();
            smoothing = true;
        }
    }
}

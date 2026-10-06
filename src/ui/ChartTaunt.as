package ui
{
    import flash.display.Bitmap;

    /** Buff / debuff icon shown next to the HUD frames. */
    [Embed(source="/_assets/charts/taunt.png")]
    public class ChartTaunt extends Bitmap
    {
        public function ChartTaunt()
        {
            super();
            smoothing = true;
        }
    }
}

package ui
{
    import flash.display.Bitmap;

    /** Buff / debuff icon shown next to the HUD frames. */
    [Embed(source="/_assets/buffs/gramiel_aura.png")]
    public class BuffGramielAura extends Bitmap
    {
        public function BuffGramielAura()
        {
            super();
            smoothing = true;
        }
    }
}

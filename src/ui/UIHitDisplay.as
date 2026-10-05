package ui
{
    import flash.display.MovieClip;

    /** Artwork from Spider.swf (see tools/extract_ui.py), embedded the same way the recovered classes are. */
    [Embed(source="/_assets/ui.swf", symbol="UI_HitDisplay")]
    public dynamic class UIHitDisplay extends MovieClip
    {
        public function UIHitDisplay()
        {
            super();
        }
    }
}

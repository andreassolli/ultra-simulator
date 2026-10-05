package ui
{
    import flash.display.MovieClip;

    /** Artwork from game.swf (see tools/extract_ui.py), embedded the same way the recovered classes are. */
    [Embed(source="/_assets/ui.swf", symbol="UI_TargetBox")]
    public dynamic class UITargetBox extends MovieClip
    {
        public function UITargetBox()
        {
            super();
        }
    }
}

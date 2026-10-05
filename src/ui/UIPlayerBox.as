package ui
{
    import flash.display.MovieClip;

    /** Artwork from Spider.swf (see tools/extract_ui.py), embedded the same way the recovered classes are. */
    [Embed(source="/_assets/ui.swf", symbol="UI_PlayerBox")]
    public dynamic class UIPlayerBox extends MovieClip
    {
        public function UIPlayerBox()
        {
            super();
        }
    }
}

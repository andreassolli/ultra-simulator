package ui
{
    import flash.display.MovieClip;

    /** Spider.swf's whole bottom overlay (see tools/extract_ui.py): chat bar, skill bar, menu icons and the XP bars. */
    [Embed(source="/_assets/ui.swf", symbol="UI_Interface")]
    public dynamic class UIInterface extends MovieClip
    {
        public function UIInterface()
        {
            super();
        }
    }
}

package ui
{
    import flash.display.SimpleButton;

    /** Artwork from Spider.swf (see tools/extract_ui.py). */
    [Embed(source="/_assets/ui.swf", symbol="UI_PlayBtn")]
    public dynamic class UIPlayBtn extends SimpleButton
    {
        public function UIPlayBtn()
        {
            super();
        }
    }
}

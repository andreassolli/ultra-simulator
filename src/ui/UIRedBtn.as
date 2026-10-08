package ui
{
    import flash.display.SimpleButton;

    /** The red glossy button of Spider.swf's Options window (109 x 28, no text; see tools/extract_ui.py). */
    [Embed(source="/_assets/ui.swf", symbol="UI_RedBtn")]
    public dynamic class UIRedBtn extends SimpleButton
    {
        public function UIRedBtn()
        {
            super();
        }
    }
}

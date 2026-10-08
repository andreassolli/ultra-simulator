package ui
{
    import flash.display.SimpleButton;

    /** The in-game menu bar's gear (Options) button, from Spider.swf (see tools/extract_ui.py). */
    [Embed(source="/_assets/ui.swf", symbol="UI_GearBtn")]
    public dynamic class UIGearBtn extends SimpleButton
    {
        public function UIGearBtn()
        {
            super();
        }
    }
}

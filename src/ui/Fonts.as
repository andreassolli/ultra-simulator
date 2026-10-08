package ui
{
    import flash.text.Font;

    /**
     * The fonts AdventureQuest Worlds draws its interface with, taken out of the game's own SWF (Arial and Arial Bold for the
     * texts, BD Merced for window titles). Embedding them means the text looks the same in every browser, and does not depend on
     * which font Ruffle maps "_sans" to (those fonts have different line heights, which put the text too low in its boxes).
     */
    public class Fonts
    {
        [Embed(source="/_assets/fonts/arial.ttf", fontName="AqwArial", mimeType="application/x-font-truetype", embedAsCFF="false")]
        private static var arialClass:Class;
        [Embed(source="/_assets/fonts/arialbd.ttf", fontName="AqwArialBold", mimeType="application/x-font-truetype", embedAsCFF="false")]
        private static var arialBoldClass:Class;
        [Embed(source="/_assets/fonts/merced.ttf", fontName="AqwTitle", mimeType="application/x-font-truetype", embedAsCFF="false")]
        private static var titleClass:Class;

        public static const TEXT:String = "AqwArial";
        public static const BOLD:String = "AqwArialBold";
        public static const TITLE:String = "AqwTitle";

        private static var done:Boolean = false;

        public static function register():void
        {
            if (done)
            {
                return;
            }
            done = true;
            Font.registerFont(arialClass);
            Font.registerFont(arialBoldClass);
            Font.registerFont(titleClass);
        }
    }
}

package sim
{
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;

    /** Text / bar helpers shared by the HUD and the floating combat text. */
    public class Hud
    {
        public static function label(text:String, size:int = 12, color:uint = 0xFFFFFF, bold:Boolean = false, align:String = "left", width:Number = 0):TextField
        {
            var f:TextField = new TextField();
            var fmt:TextFormat = new TextFormat("_sans", size, color, bold);
            fmt.align = align;
            f.defaultTextFormat = fmt;
            f.selectable = false;
            f.mouseEnabled = false;
            f.autoSize = width > 0 ? "none" : "left";
            if (width > 0)
            {
                f.width = width;
                f.height = size + 6;
            }
            f.text = text;
            return f;
        }

        /** Draw a health / resource bar into a Shape. */
        public static function bar(g:Shape, w:Number, h:Number, frac:Number, top:uint, bottom:uint):void
        {
            frac = Math.max(0, Math.min(1, frac));
            g.graphics.clear();
            g.graphics.beginFill(0x10131c);
            g.graphics.drawRect(0, 0, w, h);
            g.graphics.endFill();
            g.graphics.beginFill(top);
            g.graphics.drawRect(0, 0, w * frac, h / 2);
            g.graphics.endFill();
            g.graphics.beginFill(bottom);
            g.graphics.drawRect(0, h / 2, w * frac, h / 2);
            g.graphics.endFill();
            g.graphics.lineStyle(1, 0xFFFFFF, 0.35);
            g.graphics.drawRect(0.5, 0.5, w - 1, h - 1);
        }

        /**
         * Round "time left" overlay centred on (0,0): `remaining` (0..1) of the disc stays dark and the cleared part
         * grows clockwise from 12 o'clock, like a cooldown wipe.
         */
        public static function pie(g:Shape, r:Number, remaining:Number, color:uint = 0x000000, alpha:Number = 0.62):void
        {
            g.graphics.clear();
            if (remaining <= 0)
            {
                return;
            }
            g.graphics.beginFill(color, alpha);
            if (remaining >= 0.999)
            {
                g.graphics.drawCircle(0, 0, r);
                g.graphics.endFill();
                return;
            }
            var start:Number = -Math.PI / 2 + (1 - remaining) * Math.PI * 2;
            var end:Number = -Math.PI / 2 + Math.PI * 2;
            var steps:int = int(Math.ceil(remaining * 48)) + 1;
            g.graphics.moveTo(0, 0);
            g.graphics.lineTo(Math.cos(start) * r, Math.sin(start) * r);
            for (var i:int = 1; i <= steps; i++)
            {
                var a:Number = start + (end - start) * i / steps;
                g.graphics.lineTo(Math.cos(a) * r, Math.sin(a) * r);
            }
            g.graphics.lineTo(0, 0);
            g.graphics.endFill();
        }

        public static function panel(s:Sprite, x:Number, y:Number, w:Number, h:Number):void
        {
            s.graphics.beginFill(0x080a12, 0.72);
            s.graphics.drawRoundRect(x, y, w, h, 8, 8);
            s.graphics.endFill();
        }
    }
}

package ui
{
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.filters.DropShadowFilter;
    import flash.geom.Matrix;
    import flash.text.TextField;
    import sim.Hud;
    import flash.display.GradientType;

    /** The look of AdventureQuest Worlds' windows, buttons and option rows, built from Spider.swf's own art where there is some. */
    public class Aqw
    {
        public static const GOLD:uint = 0xE9B84A;
        public static const WIN_W:Number = 350;
        public static const WIN_H:Number = 432;

        /** a click handler that does not reach the game behind the menu */
        public static function onClick(d:DisplayObject, fn:Function):void
        {
            d.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void {
                e.stopPropagation();
                fn();
            });
            if (d is Sprite)
            {
                Sprite(d).buttonMode = true;
            }
        }

        /** the red glossy button with a white bold text; `on` false draws it dimmed (Music off) */
        public static function redButton(text:String, w:Number, fn:Function):MovieClip
        {
            var s:MovieClip = new MovieClip();
            var art:UIRedBtn = new UIRedBtn();
            art.scaleX = w / 109;
            s.addChild(art);
            var t:TextField = Hud.label(text, 12, 0xFFFFFF, true, "center", w);
            t.y = 5;
            t.filters = [new DropShadowFilter(1, 90, 0, 1, 1, 1, 1)];
            s.addChild(t);
            s.cacheAsBitmap = true;
            onClick(s, fn);
            s["text"] = t;
            return s;
        }

        /** the gold-framed dark window with its red close button; the title is in the game's title font */
        public static function window(title:String, w:Number, onClose:Function, hgt:Number = 432):Sprite
        {
            var s:Sprite = new Sprite();
            s.graphics.beginFill(0x1B1B1B, 1);
            s.graphics.drawRoundRect(5, 5, w - 10, hgt - 10, 18, 18);
            s.graphics.endFill();
            var bg:MovieClip = new UIOptBg();
            if (w != WIN_W || hgt != WIN_H)
            {
                bg.scale9Grid = new flash.geom.Rectangle(50, 50, WIN_W - 100, WIN_H - 100);
                bg.width = w;
                bg.height = hgt;
            }
            s.addChild(bg);
            var t:TextField = Hud.label(title, 22, 0xFFFFFF, false, "center", w, Fonts.TITLE);
            t.y = 9;
            s.addChild(t);
            var hit:Sprite = new Sprite();
            hit.graphics.beginFill(0xFF0000, 0);
            hit.graphics.drawRect(w - 44, 2, 42, 34);
            hit.graphics.endFill();
            onClick(hit, onClose);
            s.addChild(hit);
            return s;
        }

        /** a tab like the Options window's: black with a rounded top */
        public static function tab(text:String, w:Number):Sprite
        {
            var s:Sprite = new Sprite();
            s.graphics.lineStyle(1, 0x3A3A3A, 1);
            s.graphics.beginFill(0x000000, 1);
            s.graphics.moveTo(0, 20);
            s.graphics.lineTo(0, 7);
            s.graphics.curveTo(0, 0, 7, 0);
            s.graphics.lineTo(w - 7, 0);
            s.graphics.curveTo(w, 0, w, 7);
            s.graphics.lineTo(w, 20);
            s.graphics.endFill();
            var t:TextField = Hud.label(text, 12, 0xFFFFFF, false, "center", w);
            t.y = 2;
            s.addChild(t);
            return s;
        }

        /** a black option row; the label sits at the left */
        public static function row(text:String, w:Number, h:Number = 32):MovieClip
        {
            var s:MovieClip = new MovieClip();
            s.graphics.beginFill(0x000000, 1);
            s.graphics.lineStyle(1, 0x2A2A2A, 1);
            s.graphics.drawRect(0, 0, w, h);
            s.graphics.endFill();
            var t:TextField = Hud.label(text, 12, 0xFFFFFF, false, "left", w - 120);
            t.x = 10;
            t.y = (h - 17) / 2;
            s.addChild(t);
            return s;
        }

        /** a red arrow, like the ones in the game's option rows */
        public static function arrow(dir:int):Shape
        {
            var a:Shape = new Shape();
            var g:* = a.graphics;
            g.lineStyle(1.5, 0x3A0A0A, 1);
            g.beginGradientFill(GradientType.LINEAR, [0xE23B3B, 0x7A0F0F], [1, 1], [0, 255], new Matrix(0, 0.05, -0.05, 0, 0, 0));
            g.moveTo(dir * 11, 0);
            g.lineTo(0, -9);
            g.lineTo(0, -4);
            g.lineTo(-dir * 11, -4);
            g.lineTo(-dir * 11, 4);
            g.lineTo(0, 4);
            g.lineTo(0, 9);
            g.lineTo(dir * 11, 0);
            g.endFill();
            return a;
        }

        /**
         * A row with "< ON >" at the right; clicking either arrow (or the row) calls fn. Returns the row; call refresh() with
         * the new value after fn.
         */
        public static function toggleRow(text:String, w:Number, value:Function, fn:Function):MovieClip
        {
            var r:MovieClip = row(text, w);
            var left:Shape = arrow(-1);
            left.x = w - 110;
            left.y = 16;
            var right:Shape = arrow(1);
            right.x = w - 20;
            right.y = 16;
            var v:TextField = Hud.label("", 12, 0xFFFFFF, false, "center", 60);
            v.x = w - 95;
            v.y = 7;
            r.addChild(left);
            r.addChild(right);
            r.addChild(v);
            var refresh:Function = function():void {
                v.text = value() ? "ON" : "OFF";
            };
            refresh();
            onClick(r, function():void {
                fn();
                refresh();
            });
            r["refresh"] = refresh;
            return r;
        }

        /** the dark round button with a white > at the right of the home screen's rows */
        public static function chevron(d:Number):Sprite
        {
            var s:Sprite = new Sprite();
            s.graphics.lineStyle(2, 0x3A3A3A, 1);
            s.graphics.beginFill(0x050505, 1);
            s.graphics.drawCircle(0, 0, d / 2);
            s.graphics.endFill();
            s.graphics.lineStyle(3, 0xFFFFFF, 1);
            s.graphics.moveTo(-d * 0.08, -d * 0.2);
            s.graphics.lineTo(d * 0.12, 0);
            s.graphics.lineTo(-d * 0.08, d * 0.2);
            return s;
        }
    }
}

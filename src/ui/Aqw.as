package ui
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.filters.DropShadowFilter;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
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

        private static var frameBD:BitmapData = null;

        /**
         * The Options window's gold frame at any size, cut in nine: the corners (with the close button) as they are, the edges and the
         * middle stretched. (Ruffle's scale9Grid stretched the close button too.)
         */
        public static function frame(w:Number, h:Number):Sprite
        {
            if (frameBD == null)
            {
                frameBD = new BitmapData(WIN_W * 2, WIN_H * 2, true, 0x00000000);
                frameBD.draw(new UIOptBg(), new Matrix(2, 0, 0, 2, 0, 0), null, null, null, true);
            }
            var s:Sprite = new Sprite();
            var c:int = 100; // the corner, in source pixels (twice the stage's)
            var W:int = WIN_W * 2, H:int = WIN_H * 2;
            var piece:Function = function(sx:int, sy:int, sw:int, sh:int, dx:Number, dy:Number, dw:Number, dh:Number):void {
                var bd:BitmapData = new BitmapData(sw, sh, true, 0x00000000);
                bd.copyPixels(frameBD, new Rectangle(sx, sy, sw, sh), new Point(0, 0));
                var bm:Bitmap = new Bitmap(bd, "auto", true);
                bm.x = dx;
                bm.y = dy;
                bm.width = dw;
                bm.height = dh;
                s.addChild(bm);
            };
            piece(c, c, W - 2 * c, H - 2 * c, 50, 50, w - 100, h - 100);
            piece(c, 0, W - 2 * c, c, 50, 0, w - 100, 50);
            piece(c, H - c, W - 2 * c, c, 50, h - 50, w - 100, 50);
            piece(0, c, c, H - 2 * c, 0, 50, 50, h - 100);
            piece(W - c, c, c, H - 2 * c, w - 50, 50, 50, h - 100);
            piece(0, 0, c, c, 0, 0, 50, 50);
            piece(W - c, 0, c, c, w - 50, 0, 50, 50);
            piece(0, H - c, c, c, 0, h - 50, 50, 50);
            piece(W - c, H - c, c, c, w - 50, h - 50, 50, 50);
            return s;
        }

        /** the gold-framed dark window with its red close button; the title is in the game's title font */
        public static function window(title:String, w:Number, onClose:Function, hgt:Number = 432):Sprite
        {
            var s:Sprite = new Sprite();
            s.graphics.beginFill(0x1B1B1B, 1);
            s.graphics.drawRoundRect(5, 5, w - 10, hgt - 10, 18, 18);
            s.graphics.endFill();
            s.addChild(frame(w, hgt));
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

        /** one of the Options window's tabs (0 General, 1 Gameplay): Spider.swf's own art, which has its text in it */
        public static function tab(kind:int):MovieClip
        {
            return kind == 0 ? new UIOptTab() : new UITabGameplay();
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

        /** the red arrow of the game's option rows (Spider.swf's own), pointing left (dir -1) or right (1) */
        public static function arrow(dir:int):Sprite
        {
            var art:UIArrow = new UIArrow();
            var b:Rectangle = art.getBounds(art);
            art.x = -(b.x + b.width / 2);
            art.y = -(b.y + b.height / 2);
            var s:Sprite = new Sprite();
            s.addChild(art);
            s.rotation = dir * 90;
            s.scaleX = s.scaleY = 0.69;
            return s;
        }

        /**
         * A row with "< ON >" at the right; clicking either arrow (or the row) calls fn. Returns the row; call refresh() with
         * the new value after fn.
         */
        public static function toggleRow(text:String, w:Number, value:Function, fn:Function):MovieClip
        {
            var r:MovieClip = row(text, w);
            var left:Sprite = arrow(-1);
            left.x = w - 110;
            left.y = 16;
            var right:Sprite = arrow(1);
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

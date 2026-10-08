package ui
{
    import flash.display.Bitmap;
    import flash.display.DisplayObject;
    import flash.display.GradientType;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.filters.DropShadowFilter;
    import flash.filters.GlowFilter;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.text.TextField;
    import sim.Hud;

    /**
     * The main screen, laid out like AdventureQuest Worlds' home screen: the title, two rows for what is picked (the boss and the
     * class, where the character and the gold are in the game; a click goes to the page to change it), the menu rows
     * (Tutorial, Options, Credits) and a big Play button. `h` is the game (see UltraSim.menu*).
     */
    public class HomeView extends Sprite
    {
        private static const COL_X:Number = 290;
        private static const COL_W:Number = 380;

        public function HomeView(h:Object, w:Number, hgt:Number)
        {
            graphics.beginFill(0x000000, 0.8);
            graphics.drawRect(0, 0, w, hgt);
            graphics.endFill();
            var title:TextField = Hud.label(h.menuBossName(), 34, 0xFFC93C, false, "center", w, Fonts.TITLE);
            title.y = 12;
            title.filters = [new GlowFilter(0x4A2300, 1, 4, 4, 8, 1), new DropShadowFilter(3, 90, 0, 0.8, 4, 4, 1)];
            addChild(title);
            var sub:TextField = Hud.label("Ultra boss practice", 14, 0xE8A850, false, "center", w);
            sub.y = 58;
            addChild(sub);
            bigRow(88, h.menuBossFace(34, 34), "BOSS", h.menuBossName().toUpperCase(), h.menuOpenBosses);
            bigRow(134, h.menuClassIcon(30), "CLASS", h.menuClassName().toUpperCase(), h.menuOpenClasses);
            menuRow(184, "TUTORIAL", 0, h.menuTutorial);
            menuRow(222, "OPTIONS", 1, h.menuOptions);
            menuRow(260, "CREDITS", 2, h.menuCredits);
            addChild(playButton(h.menuPlay, w));
            var help:TextField = Hud.label(h.menuHelpLine(), 12, 0x9BA6BD, false, "center", w);
            help.y = 410;
            addChild(help);
        }

        private function panel(y:Number, hgt:Number):Sprite
        {
            var s:Sprite = new Sprite();
            s.graphics.lineStyle(2, 0x000000, 0.9);
            s.graphics.beginFill(0x15130F, 0.82);
            s.graphics.drawRoundRect(0, 0, COL_W, hgt, 14, 14);
            s.graphics.endFill();
            s.graphics.lineStyle(1, 0x4A4636, 0.9);
            s.graphics.drawRoundRect(1.5, 1.5, COL_W - 3, hgt - 3, 12, 12);
            s.x = COL_X;
            s.y = y;
            addChild(s);
            return s;
        }

        /** a row that shows a pick: its picture, a small grey caption and the name in bold capitals */
        private function bigRow(y:Number, pic:DisplayObject, caption:String, name:String, fn:Function):void
        {
            var s:Sprite = panel(y, 42);
            pic.x = 14 + 20 - pic.width / 2 + (pic is Bitmap ? 0 : 0);
            pic.y = 5;
            if (pic is Bitmap)
            {
                pic.x = 12;
                pic.y = 4;
            }
            else
            {
                pic.x = 29;
                pic.y = 21;
            }
            s.addChild(pic);
            var c:TextField = Hud.label(caption, 10, 0x8E8E8E, true, "left", 200);
            c.x = 58;
            c.y = 4;
            s.addChild(c);
            var n:TextField = Hud.label(name, 15, 0xFFFFFF, true, "left", COL_W - 140);
            n.x = 58;
            n.y = 17;
            s.addChild(n);
            var ch:Sprite = Aqw.chevron(26);
            ch.x = COL_W - 24;
            ch.y = 21;
            s.addChild(ch);
            Aqw.onClick(s, fn);
        }

        private function menuRow(y:Number, text:String, icon:int, fn:Function):void
        {
            var s:Sprite = panel(y, 34);
            var ic:Shape = new Shape();
            drawIcon(ic, icon);
            ic.scaleX = ic.scaleY = 0.8;
            ic.x = 30;
            ic.y = 17;
            s.addChild(ic);
            var t:TextField = Hud.label(text, 14, 0xFFFFFF, true, "left", COL_W - 120);
            t.x = 66;
            t.y = 7;
            s.addChild(t);
            var ch:Sprite = Aqw.chevron(22);
            ch.x = COL_W - 22;
            ch.y = 17;
            s.addChild(ch);
            Aqw.onClick(s, fn);
        }

        /** 0 = a play triangle (the tutorial video), 1 = a gear (options), 2 = a scroll with a star (credits) */
        private static function drawIcon(s:Shape, kind:int):void
        {
            var g:* = s.graphics;
            g.lineStyle(1.5, 0x5A4310, 1);
            g.beginGradientFill(GradientType.LINEAR, [0xFFE08A, 0xB07A1C], [1, 1], [0, 255], new Matrix(0, 0.06, -0.06, 0, 0, 0));
            if (kind == 0)
            {
                g.drawCircle(0, 0, 14);
                g.endFill();
                g.lineStyle(0, 0, 0);
                g.beginFill(0x3A2A08, 1);
                g.moveTo(-4, -8);
                g.lineTo(9, 0);
                g.lineTo(-4, 8);
                g.endFill();
            }
            else if (kind == 1)
            {
                var teeth:int = 8;
                for (var i:int = 0; i < teeth * 2; i++)
                {
                    var a:Number = Math.PI * 2 * i / (teeth * 2);
                    var r:Number = i % 2 == 0 ? 15 : 11;
                    if (i == 0)
                    {
                        g.moveTo(Math.cos(a) * r, Math.sin(a) * r);
                    }
                    else
                    {
                        g.lineTo(Math.cos(a) * r, Math.sin(a) * r);
                    }
                }
                g.endFill();
                g.lineStyle(0, 0, 0);
                g.beginFill(0x3A2A08, 1);
                g.drawCircle(0, 0, 5);
                g.endFill();
            }
            else
            {
                g.drawRoundRect(-12, -14, 24, 28, 4, 4);
                g.endFill();
                g.lineStyle(0, 0, 0);
                g.beginFill(0x3A2A08, 1);
                for (var k:int = 0; k < 10; k++)
                {
                    var b:Number = Math.PI * 2 * k / 10 - Math.PI / 2;
                    var rr:Number = k % 2 == 0 ? 8 : 3.5;
                    if (k == 0)
                    {
                        g.moveTo(Math.cos(b) * rr, Math.sin(b) * rr);
                    }
                    else
                    {
                        g.lineTo(Math.cos(b) * rr, Math.sin(b) * rr);
                    }
                }
                g.endFill();
            }
        }

        /** Spider.swf's ornate red and gold button (the login screen's, without its "Login") with "Play" in the game's title font */
        private function playButton(fn:Function, w:Number):Sprite
        {
            var s:Sprite = new Sprite();
            var art:UIPlayBtn = new UIPlayBtn();
            var b:Rectangle = art.getBounds(art);
            var k:Number = 1.7;
            art.scaleX = art.scaleY = k;
            art.x = -b.x * k;
            art.y = -b.y * k;
            s.addChild(art);
            var bw:Number = b.width * k, bh:Number = b.height * k;
            var t:TextField = Hud.label("Play", 30, 0xFFF3E0, false, "center", bw, Fonts.TITLE);
            t.y = (bh - 40) / 2;
            t.mouseEnabled = false;
            t.filters = [new DropShadowFilter(2, 90, 0x300000, 0.9, 3, 3, 1)];
            s.addChild(t);
            s.x = (w - bw) / 2;
            s.y = 308;
            Aqw.onClick(s, fn);
            return s;
        }
    }
}

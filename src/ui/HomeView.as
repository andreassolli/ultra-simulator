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
    import flash.text.TextField;
    import sim.Hud;

    /**
     * The main screen, laid out like AdventureQuest Worlds' home screen: the title, two rows for what is picked (the boss and the
     * class, where the character and the gold are in the game; a click goes to the page to change it), the menu rows
     * (Tutorial, Options, Credits) and a big Play button. `h` is the game (see UltraSim.menu*).
     */
    public class HomeView extends Sprite
    {
        private static const COL_X:Number = 250;
        private static const COL_W:Number = 460;

        public function HomeView(h:Object, w:Number, hgt:Number)
        {
            graphics.beginFill(0x000000, 0.8);
            graphics.drawRect(0, 0, w, hgt);
            graphics.endFill();
            var title:TextField = Hud.label(h.menuBossName(), 40, 0xFFC93C, false, "center", w, Fonts.TITLE);
            title.y = 14;
            title.filters = [new GlowFilter(0x4A2300, 1, 4, 4, 8, 1), new DropShadowFilter(3, 90, 0, 0.8, 4, 4, 1)];
            addChild(title);
            var sub:TextField = Hud.label("Ultra boss practice", 16, 0xE8A850, false, "center", w);
            sub.y = 66;
            addChild(sub);
            bigRow(96, h.menuBossFace(40, 40), "BOSS", h.menuBossName().toUpperCase(), h.menuOpenBosses);
            bigRow(152, h.menuClassIcon(36), "CLASS", h.menuClassName().toUpperCase(), h.menuOpenClasses);
            menuRow(212, "TUTORIAL", 0, h.menuTutorial);
            menuRow(258, "OPTIONS", 1, h.menuOptions);
            menuRow(304, "CREDITS", 2, h.menuCredits);
            addChild(playButton(h.menuPlay, w));
            var help:TextField = Hud.label(h.menuHelpLine(), 12, 0x9BA6BD, false, "center", w);
            help.y = 448;
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
            var s:Sprite = panel(y, 50);
            pic.x = 14 + 20 - pic.width / 2 + (pic is Bitmap ? 0 : 0);
            pic.y = 5;
            if (pic is Bitmap)
            {
                pic.x = 14;
                pic.y = 5;
            }
            else
            {
                pic.x = 34;
                pic.y = 25;
            }
            s.addChild(pic);
            var c:TextField = Hud.label(caption, 11, 0x8E8E8E, true, "left", 200);
            c.x = 70;
            c.y = 6;
            s.addChild(c);
            var n:TextField = Hud.label(name, 18, 0xFFFFFF, true, "left", COL_W - 140);
            n.x = 70;
            n.y = 22;
            s.addChild(n);
            var ch:Sprite = Aqw.chevron(32);
            ch.x = COL_W - 30;
            ch.y = 25;
            s.addChild(ch);
            Aqw.onClick(s, fn);
        }

        private function menuRow(y:Number, text:String, icon:int, fn:Function):void
        {
            var s:Sprite = panel(y, 40);
            var ic:Shape = new Shape();
            drawIcon(ic, icon);
            ic.x = 38;
            ic.y = 20;
            s.addChild(ic);
            var t:TextField = Hud.label(text, 16, 0xFFFFFF, true, "left", COL_W - 150);
            t.x = 90;
            t.y = 9;
            s.addChild(t);
            var ch:Sprite = Aqw.chevron(28);
            ch.x = COL_W - 26;
            ch.y = 20;
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

        /** the big gold-framed red button */
        private function playButton(fn:Function, w:Number):Sprite
        {
            var bw:Number = COL_W + 20, bh:Number = 62;
            var s:Sprite = new Sprite();
            var g:* = s.graphics;
            var m:Matrix = new Matrix();
            m.createGradientBox(bw, bh, Math.PI / 2);
            g.lineStyle(2, 0x5A3A06, 1);
            g.beginGradientFill(GradientType.LINEAR, [0xFFE27A, 0xD39A1E, 0x8E5A08], [1, 1, 1], [0, 120, 255], m);
            g.drawRoundRect(0, 0, bw, bh, 30, 30);
            g.endFill();
            var m2:Matrix = new Matrix();
            m2.createGradientBox(bw - 24, bh - 18, Math.PI / 2);
            g.lineStyle(2, 0x3A0000, 1);
            g.beginGradientFill(GradientType.LINEAR, [0xFF3B2F, 0xC00F12, 0x7A060A], [1, 1, 1], [0, 140, 255], m2);
            g.drawRoundRect(12, 9, bw - 24, bh - 18, 20, 20);
            g.endFill();
            g.lineStyle(0, 0, 0);
            g.beginFill(0xFFFFFF, 0.16);
            g.drawRoundRect(20, 12, bw - 40, (bh - 18) / 2 - 3, 12, 12);
            g.endFill();
            var t:TextField = Hud.label("Play", 38, 0xFFFFFF, false, "center", bw, Fonts.TITLE);
            t.y = 8;
            t.filters = [new DropShadowFilter(2, 90, 0, 0.9, 3, 3, 1)];
            s.addChild(t);
            s.x = (w - bw) / 2;
            s.y = 362;
            s.cacheAsBitmap = true;
            Aqw.onClick(s, fn);
            return s;
        }
    }
}

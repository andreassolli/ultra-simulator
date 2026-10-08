package ui
{
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.text.TextField;
    import sim.Hud;

    /** The class page: one card per class the boss is played with (Shaman has a Phase 1 and a Phase 2 card). */
    public class ClassView extends Sprite
    {
        public function ClassView(h:Object, w:Number, hgt:Number)
        {
            graphics.beginFill(0x05070d, 0.96);
            graphics.drawRect(0, 0, w, hgt);
            graphics.endFill();
            var title:TextField = Hud.label("Choose a class", 34, 0xFFC93C, false, "center", w, Fonts.TITLE);
            title.y = 40;
            addChild(title);
            var classes:Array = h.menuClasses();
            var cw:Number = 200, gap:Number = 20;
            var x0:Number = (w - (classes.length * cw + (classes.length - 1) * gap)) / 2;
            for (var i:int = 0; i < classes.length; i++)
            {
                var c:Object = classes[i];
                var card:Sprite = new Sprite();
                card.graphics.lineStyle(c.selected ? 3 : 2, c.selected ? 0xFFC93C : 0x4A4636, 1);
                card.graphics.beginFill(0x15130F, 0.92);
                card.graphics.drawRoundRect(0, 0, cw, 150, 14, 14);
                card.graphics.endFill();
                var icon:DisplayObject = h.menuClassIcon(76, c.id);
                icon.x = cw / 2;
                icon.y = 62;
                card.addChild(icon);
                var nm:TextField = Hud.label(c.name, 16, 0xFFFFFF, true, "center", cw);
                nm.y = 112;
                card.addChild(nm);
                card.x = x0 + i * (cw + gap);
                card.y = 150;
                Aqw.onClick(card, h.menuPick(c.id));
                addChild(card);
            }
            var back:Sprite = Aqw.redButton("Back", 120, h.menuHome);
            back.x = (w - 120) / 2;
            back.y = 340;
            addChild(back);
        }
    }
}

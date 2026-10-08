package ui
{
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.text.TextField;
    import sim.Hud;

    /**
     * Spider.swf's Options window (General / Gameplay tabs, red buttons, black rows with red arrows) and, beside it, a Keybinds
     * window in the place the game puts its Advanced Options. `h` is the game (see UltraSim.menu*).
     */
    public class OptionsView extends Sprite
    {
        private var h:Object;
        private var win:Sprite;
        private var keysWin:Sprite;
        private var tabs:Array = [];
        private var pages:Array = [];
        private var capturing:String = "";
        private var keyButtons:Object = {};
        private var rows:Array = [];
        private var musicBtn:Sprite;
        private var W:Number, H:Number;

        public function OptionsView(host:Object, w:Number, hgt:Number)
        {
            h = host;
            W = w;
            H = hgt;
            graphics.beginFill(0x000000, 0.6);
            graphics.drawRect(0, 0, w, hgt);
            graphics.endFill();
            addEventListener("mouseDown", function(e:Object):void { e.stopPropagation(); });
            build();
        }

        private function build():void
        {
            win = Aqw.window("Options", Aqw.WIN_W, h.menuCloseOptions);
            win.x = (W - Aqw.WIN_W) / 2;
            win.y = (H - Aqw.WIN_H) / 2;
            addChild(win);
            for (var i:int = 0; i < 2; i++)
            {
                var tab:MovieClip = Aqw.tab(i);
                tab.x = 22 + i * 82;
                tab.y = 44;
                tab.addEventListener("mouseDown", makeTabHandler(i));
                tab.buttonMode = true;
                win.addChild(tab);
                tabs.push(tab);
                var page:Sprite = new Sprite();
                page.y = 76;
                win.addChild(page);
                pages.push(page);
            }
            // General: the Music button like the game's, the rows, then the buttons
            musicBtn = Aqw.redButton("Music", 150, function():void { h.menuToggle("music"); refresh(); });
            musicBtn.x = 18;
            musicBtn.y = 4;
            pages[0].addChild(musicBtn);
            var kb:Sprite = Aqw.redButton("Keybinds", 150, toggleKeys);
            kb.x = 182;
            kb.y = 4;
            pages[0].addChild(kb);
            addRow(0, "Hints (" + Keys.name(Keys.code("hints")) + ")", "hints", 44);
            addRow(0, "Party HP frames (" + Keys.name(Keys.code("party")) + ")", "party", 82);
            addRow(0, "Skill chart (" + Keys.name(Keys.code("chart")) + ")", "chart", 120);
            var vr:Sprite = Aqw.toggleRow("Visuals (GPU use)", 314, function():String { return h.menuVisuals(); }, function():void { h.menuCycleVisuals(); });
            vr.x = 18;
            vr.y = 158;
            pages[0].addChild(vr);
            addRow(1, "Auto-pilot", "bot", 4);
            addRow(1, "Paused (" + Keys.name(Keys.code("pause")) + ")", "pause", 42);
            var rs:Sprite = Aqw.redButton("Restart fight", 150, function():void { h.menuRun("restart"); });
            rs.x = 18;
            rs.y = 378;
            win.addChild(rs);
            var mm:Sprite = Aqw.redButton("Main menu", 150, function():void { h.menuRun("home"); });
            mm.x = 182;
            mm.y = 378;
            win.addChild(mm);
            var ver:TextField = Hud.label("Ultra boss simulator - not affiliated with Artix Entertainment", 10, 0x8E8E8E, false, "center", Aqw.WIN_W);
            ver.y = 406;
            win.addChild(ver);
            showTab(0);
            refresh();
        }

        private function addRow(page:int, label:String, name:String, y:Number):void
        {
            var r:Sprite = Aqw.toggleRow(label, 314, function():Boolean { return h.menuState(name); }, function():void { h.menuToggle(name); });
            r.x = 18;
            r.y = y;
            pages[page].addChild(r);
            rows.push(r);
        }

        private function makeTabHandler(i:int):Function
        {
            return function(e:Object):void {
                e.stopPropagation();
                showTab(i);
            };
        }

        private function showTab(i:int):void
        {
            for (var k:int = 0; k < pages.length; k++)
            {
                pages[k].visible = k == i;
                tabs[k].gotoAndStop(k == i ? 2 : 1);
            }
        }

        /** re-read what the rows show (after a hotkey changed something behind the window) */
        public function refresh():void
        {
            for each (var r:Sprite in rows)
            {
                r["refresh"]();
            }
            musicBtn.alpha = h.menuState("music") ? 1 : 0.5;
            musicBtn["text"].text = h.menuState("music") ? "Music" : "Music (off)";
        }

        // ------------------------------------------------------------ keybinds
        private function toggleKeys():void
        {
            if (keysWin != null && keysWin.parent)
            {
                removeChild(keysWin);
                win.x = (W - Aqw.WIN_W) / 2;
                capturing = "";
                return;
            }
            win.x = (W - 2 * Aqw.WIN_W - 8) / 2;
            keysWin = Aqw.window("Keybinds", Aqw.WIN_W, toggleKeys);
            keysWin.x = win.x + Aqw.WIN_W + 8;
            keysWin.y = win.y;
            addChild(keysWin);
            keyButtons = {};
            var y:Number = 46;
            for each (var a:Object in Keys.ACTIONS)
            {
                var r:Sprite = Aqw.row(a.label, 314, 23);
                r.x = 18;
                r.y = y;
                keysWin.addChild(r);
                var kb:Sprite = Aqw.redButton(Keys.name(Keys.code(a.id)), 96, makeCapture(a.id));
                kb.scaleY = 0.78;
                kb.x = 314 - 100 + 18;
                kb.y = y + 2;
                keysWin.addChild(kb);
                keyButtons[a.id] = kb;
                y += 24;
            }
            var reset:Sprite = Aqw.redButton("Reset keys", 130, function():void { Keys.reset(); capturing = ""; renameKeys(); });
            reset.x = 18;
            reset.y = 386;
            keysWin.addChild(reset);
            var hint:TextField = Hud.label("Click a key, then press the new one (Esc: cancel)", 10, 0x9BA6BD, false, "left", 190);
            hint.x = 154;
            hint.y = 386;
            hint.wordWrap = true;
            hint.multiline = true;
            hint.height = 30;
            keysWin.addChild(hint);
        }

        private function makeCapture(id:String):Function
        {
            return function():void {
                capturing = id;
                renameKeys();
                keyButtons[id]["text"].text = "Press a key...";
            };
        }

        private function renameKeys():void
        {
            for (var id:String in keyButtons)
            {
                keyButtons[id]["text"].text = Keys.name(Keys.code(id));
            }
        }

        /** a key press while the window is open: true when it was used (a new binding), false when it should close the window */
        public function key(code:int):Boolean
        {
            if (capturing != "")
            {
                if (code != 27 && code != 13 && code != 16 && code != 17 && code != 18)
                {
                    Keys.bind(capturing, code);
                }
                capturing = "";
                renameKeys();
                return true;
            }
            if (code == 27)
            {
                if (keysWin != null && keysWin.parent)
                {
                    toggleKeys();
                    return true;
                }
                return false;
            }
            return true;
        }

        public function get isCapturing():Boolean
        {
            return capturing != "";
        }
    }
}

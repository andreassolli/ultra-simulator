package
{
    import AQWorlds.Avatar;
    import AQWorlds.AvatarMC;

    import flash.display.Bitmap;
    import flash.display.DisplayObject;
    import flash.display.Loader;
    import flash.display.MovieClip;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.display.StageDisplayState;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.external.ExternalInterface;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.net.URLRequest;
    import flash.system.ApplicationDomain;
    import flash.system.LoaderContext;
    import flash.text.TextField;
    import flash.utils.getTimer;

    import sim.Fight;
    import sim.Hud;
    import sim.IFightHost;

    import flash.filters.GlowFilter;

    import ui.BuffMagiaBurn;
    import ui.BuffSomber;
    import ui.BuffStasis;
    import ui.BuffTaunt;
    import ui.UIActBar;
    import ui.UIAutoIcon;
    import ui.UIAvoidDisplay;
    import ui.UICritDisplay;
    import ui.UIHitDisplay;
    import ui.UIPartyPanel;
    import ui.UIPlayerBox;
    import ui.UISlotBg;
    import ui.UITargetBox;

    /**
     * Ultra Speaker boss simulator, running as a Flash movie.
     *
     * The map, boss, skill icons / cast effect and the player's gear are the original SWFs
     * (runtime/*.swf); the four players are AvatarMC instances from the recovered project.
     * Rules live in sim/Fight.as.
     *
     * Document class must extend MovieClip: the loaded SWFs do MovieClip(stage.getChildAt(0)).world
     * so `world` below is a small stand-in for the game client they expect.
     */
    [SWF(width="960", height="550", frameRate="24", backgroundColor="#000000")]
    public dynamic class UltraSim extends MovieClip implements IFightHost
    {
        // ---- geometry (twips/20 from the map's Boss frame, see README) ------------------
        private static const BOSS_PAD:Point = new Point(492.5, 315.7);
        private static const MIDDLE_AT:Point = new Point(470, 420);
        private static const RIGHT_AT:Point = new Point(868, 410);
        private static const SAFE_A:Object = {x: 180.65, y: 220.55, w: 612.7, h: 294.7};
        private static const WALK:Object = {x0: 24, x1: 936, y0: 240, y1: 488};
        private static const STACK:Object = {ap: [-6, -2], lr: [6, -1], dps: [-2, 2], loo: [2, 0]};
        private static const CHAR_SCALE:Number = 0.65;
        private static const BOSS_SCALE:Number = 0.3;
        private static const BOSS_NAME:String = "Ultra Speaker";
        // centre / size of the portrait ring in the local coordinates of the status box's mcHead
        private static const PORTRAIT_CX:Number = 50;
        private static const PORTRAIT_CY:Number = 25;
        private static const PORTRAIT_SIZE:Number = 58;

        private static const ROLE_COLOR:Object = {ap: 0xE8D9A0, lr: 0xE0507A, loo: 0xE0B84A, dps: 0x5AA86A};
        private static const ROLE_SHORT:Object = {ap: "AP", lr: "LR", loo: "LoO", dps: "DPS"};
        private static const CLASS_NAMES:Object = {loo: "Lord of Order", ap: "Arch Paladin", lr: "Legion Revenant"};

        // skill bar: slot -> [label, icon class in Assets.swf]. The SWF ships aa + 4 numbered icons per class.
        private static const SKILLS:Object = {
            loo: [["Attack", "LoOaa"], ["Harmony", "LoO1"], ["Ordinance", "LoO2"], ["Axiom", "LoO3"], ["Quix", "LoO4"], ["Taunt", null]],
            ap: [["Attack", null], ["Commandment", "apal1"], ["Heal", "apal2"], ["Seal", "apal3"], ["Eden", "apal4"], ["Taunt", null]],
            lr: [["Attack", "LRaa"], ["Shade", "LR1"], ["Wicked", "LR2"], ["Empowerment", "LR3"], ["Anathema", "LR4"], ["Taunt", null]]
        };

        private static const BOSS_FRAMES:Object = {ChargeALoop: [154, 172]};

        // skin / hair / eye tones applied to the colour-keyed layers of the equipped items
        private static const COLORS:Object = {intColorSkin: 0xF0C9A0, intColorHair: 0xB9B9C4, intColorEye: 0x4A90D9};

        // ---- stand-in game client for the loaded SWFs --------------------------------------
        public var world:Object;

        /** The item SWFs call this on their colour-keyed layers (stage.getChildAt(0).mcSetColor). */
        public function mcSetColor(mc:MovieClip, part:String, shade:String):void
        {
            mc.isColored = true;
            mc.strLocation = part;
            mc.strShade = shade;
        }

        // ---- loading ----------------------------------------------------------------------
        private var mapDomain:ApplicationDomain;
        private var bossDomain:ApplicationDomain;
        private var assetsDomain:ApplicationDomain;
        private var mapHolder:MovieClip;
        private var mapMC:MovieClip;
        private var pending:int = 0;
        private var loadingText:TextField;

        // ---- scene ------------------------------------------------------------------------
        private var mapLayer:Sprite = new Sprite();
        private var actorLayer:Sprite = new Sprite();
        private var fxLayer:Sprite = new Sprite();
        private var hudLayer:Sprite = new Sprite();
        private var bossMC:MovieClip;
        private var targetRing:Shape = new Shape();
        private var runeMC:MovieClip;
        private var safeMC:MovieClip;

        // ---- game state -------------------------------------------------------------------
        private var fight:Fight;
        private var role:String = "loo";
        private var actors:Object = {};
        private var floaters:Array = [];
        private var fxClips:Array = [];
        private var zoneRole:String = "";
        private var banner:String = "";
        private var bannerUntil:Number = 0;
        private var bannerColor:uint = 0xFFD24A;
        private var shout:String = "";
        private var shoutUntil:Number = 0;
        private var bossLabel:String = "Idle";
        private var bossLoop:Boolean = false;
        private var targeted:Boolean = true;
        private var paused:Boolean = false;
        private var hintsOn:Boolean = true; // context hints: who's zone it is, taunt / quix / seal prompts, next cast, log
        private var hintsLabel:TextField;
        private var simSpeed:Number = 1;
        private var botOn:Boolean = false;
        private var botQueue:Array = [];
        private var lastTime:int;
        private var raidDamage:Number = 0;
        private var ownDamage:Number = 0;
        private var ready:Boolean = false;
        private var lastColor:int = 0;
        private var startTime:int = 0;

        // ---- HUD pieces ---------------------------------------------------------------------
        private var playerBox:MovieClip;
        private var targetBox:MovieClip;
        private var actBar:MovieClip;
        private var partyPanels:Object = {};
        private var buffIcons:Object = {};
        private var armorDomain:ApplicationDomain;
        private var helmDomain:ApplicationDomain;
        private var portraitAt:int = 0;
        private var chipTexts:Array = [];
        private var clockText:TextField;
        private var nextText:TextField;
        private var bannerText:TextField;
        private var shoutText:TextField;
        private var overText:TextField;
        private var overSub:TextField;
        private var skillSlots:Array = [];
        private var logText:TextField;
        private var logLines:Array = [];

        public function UltraSim()
        {
            world = {
                map: {bossChargeSpell: onBossChargeSpell},
                getQuestValue: function(id:int):int { return 20; }, // quest 488 done: the Boss frame is open
                moveToCell: function(cell:*, pad:*):void {},
                initMap: function():Object {
                    return {
                        initObjSess: function(a:*, b:*):void {},
                        updateSessArray: function(a:*, b:* = null):void {},
                        checkSess: function(a:*):Boolean { return true; }
                    };
                },
                initSound: function(s:*):Object {
                    return {checkSound: function(b:*):void {}, stopMusic: function(b:*):void {}};
                },
                initCutscenes: function():Object {
                    return {showCutscene: function(u:*):void {}, setCutsceneTarget: function(a:*, b:*):void {}};
                },
                getMonster: function(id:*):Object { return {pMC: bossMC}; }
            };
            if (stage)
            {
                init();
            }
            else
            {
                addEventListener(Event.ADDED_TO_STAGE, init);
            }
        }

        private function init(e:Event = null):void
        {
            removeEventListener(Event.ADDED_TO_STAGE, init);
            stage.frameRate = 24;
            // scale the whole 960x550 game to the window / full screen, keeping the aspect ratio
            stage.scaleMode = StageScaleMode.SHOW_ALL;
            stage.align = "";
            var p:Object = loaderInfo.parameters;
            if (p["class"] && CLASS_NAMES[p["class"]])
            {
                role = p["class"];
            }
            botOn = p["bot"] == "1";
            hintsOn = p["hints"] != "0";
            if (p["speed"])
            {
                simSpeed = Number(p["speed"]);
            }
            addChild(mapLayer);
            addChild(actorLayer);
            addChild(fxLayer);
            addChild(hudLayer);
            loadingText = Hud.label("Loading...", 18, 0xFFFFFF, true);
            loadingText.x = 400;
            loadingText.y = 240;
            addChild(loadingText);

            mapHolder = new MovieClip();
            mapHolder.strFrame = "Boss";
            mapHolder.cellSetup = function(a:*, b:*, c:*):void {};
            mapHolder.onWalkClick = function():void {};
            mapLayer.addChild(mapHolder);

            pending = 5;
            mapDomain = loadSwf("runtime/town-ultraspeaker.swf", onMapLoaded);
            bossDomain = loadSwf("runtime/monster-UltraMalg.swf", onBossLoaded);
            assetsDomain = loadSwf("runtime/Assets.swf", onAssetsLoaded);
            armorDomain = loadSwf("runtime/Armor.swf", onAssetsLoaded);
            helmDomain = loadSwf("runtime/Helm.swf", onAssetsLoaded);
        }

        private function loadSwf(url:String, done:Function):ApplicationDomain
        {
            var domain:ApplicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain);
            var l:Loader = new Loader();
            l.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void { done(l); step(); });
            l.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void {
                loadingText.text = "Failed to load " + url;
            });
            l.load(new URLRequest(url), new LoaderContext(false, domain));
            return domain;
        }

        private var mapLoader:Loader;
        private var bossLoader:Loader;

        private function onMapLoaded(l:Loader):void
        {
            mapLoader = l;
        }

        private function onBossLoaded(l:Loader):void
        {
            bossLoader = l;
        }

        private function onAssetsLoaded(l:Loader):void
        {
        }

        private function step():void
        {
            if (--pending > 0)
            {
                return;
            }
            removeChild(loadingText);
            start();
        }

        // ================================================================== scene setup
        private function start():void
        {
            buildMap();
            buildBoss();
            buildHud();
            newFight(role);
            stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
            lastTime = getTimer();
            startTime = lastTime;
            addEventListener(Event.ENTER_FRAME, onFrame);
            try
            {
                if (ExternalInterface.available)
                {
                    ExternalInterface.addCallback("getState", getState);
                    ExternalInterface.addCallback("setBot", function(on:Boolean):void { botOn = on; });
                    ExternalInterface.addCallback("setSpeed", function(s:Number):void { simSpeed = s; });
                    ExternalInterface.addCallback("setPaused", function(p:Boolean):void { paused = p; });
                    ExternalInterface.addCallback("startClass", function(r:String):void { newFight(r); });
                }
            }
            catch (err:Error)
            {
            }
            ready = true;
        }

        private function buildMap():void
        {
            mapMC = mapLoader.content as MovieClip;
            mapHolder.addChild(mapMC);
            mapMC.gotoAndStop("Boss");
            // keep the painted backdrop and the two zone clips, hide the map-editor furniture
            for (var i:int = 0; i < mapMC.numChildren; i++)
            {
                var c:DisplayObject = mapMC.getChildAt(i);
                if (c.name == "rune1" || c.name == "safe1")
                {
                    continue;
                }
                if (i > 0)
                {
                    c.visible = false;
                }
            }
            runeMC = mapMC.getChildByName("rune1") as MovieClip;
            safeMC = mapMC.getChildByName("safe1") as MovieClip;
            if (runeMC)
            {
                runeMC.gotoAndStop("off");
            }
            if (safeMC)
            {
                safeMC.gotoAndStop("off");
            }
        }

        private function buildBoss():void
        {
            var UltraMalg:Class = bossDomain.getDefinition("UltraMalg") as Class;
            bossMC = new UltraMalg() as MovieClip;
            bossMC.onMove = false;
            bossMC.scaleX = bossMC.scaleY = BOSS_SCALE;
            bossMC.x = BOSS_PAD.x;
            bossMC.y = BOSS_PAD.y;
            bossMC.mouseEnabled = false;
            bossMC.mouseChildren = false;
            actorLayer.addChild(bossMC);
            targetRing.graphics.lineStyle(2, 0xFFD24A, 0.9);
            targetRing.graphics.drawEllipse(-120, -10, 240, 28);
            targetRing.x = BOSS_PAD.x;
            targetRing.y = BOSS_PAD.y;
            actorLayer.addChildAt(targetRing, 0);
            bossAnim("Idle", false);
        }

        private function onBossChargeSpell(on:Boolean):void
        {
            // called by the boss clip's own frame script on Attack2: rune off
            if (!on && runeMC)
            {
                runeMC.gotoAndStop("off");
            }
        }

        private function spot(base:Point, r:String):Point
        {
            return new Point(base.x + STACK[r][0], base.y + STACK[r][1]);
        }

        private function buildActors():void
        {
            for each (var old:Object in actors)
            {
                if (old.mc && old.mc.parent)
                {
                    old.mc.parent.removeChild(old.mc);
                }
                if (old.bar && old.bar.parent)
                {
                    old.bar.parent.removeChild(old.bar);
                }
            }
            actors = {};
            var root:CharacterRoot = new CharacterRoot();
            for each (var r:String in Fight.ROLES)
            {
                var a:Object = {role: r, moveTo: null, moving: false, aaT: Math.random() * 1.3, pose: "", poseUntil: 0};
                var holder:MovieClip = new MovieClip();
                holder._avatarScaling = CHAR_SCALE;
                holder.ActiveSet = {
                    itemLinks: {Armor: "", Weapon: "", Cape: "", Helmet: "", Hair: "", Pet: "", Ground: ""},
                    itemShow: {Weapon: true, Cape: true, Helmet: true, Robe: true, "Back Robe": true},
                    weaponType: "Rifle"
                };
                var mc:AvatarMC = new AvatarMC(root);
                var av:Avatar = new Avatar(holder);
                av.pMC = mc;
                av.objData = {intColorSkin: COLORS.intColorSkin, intColorHair: COLORS.intColorHair, intColorEye: COLORS.intColorEye};
                mc.pAV = av;
                var p:Point = spot(MIDDLE_AT, r);
                mc.x = p.x;
                mc.y = p.y;
                mc.scale(CHAR_SCALE);
                mc.pname.ti.text = ROLE_SHORT[r] + (r == role ? " (you)" : "");
                mc.mouseEnabled = false;
                mc.mouseChildren = false;
                actorLayer.addChild(mc);
                a.mc = mc;
                a.bar = new Shape();
                fxLayer.addChild(a.bar);
                a.dir = 1;
                actors[r] = a;
            }
            equipPlayer();
        }

        /** Same call sequence AvatarMC.as expects: ActiveSet filled in, then each item SWF loaded with its callback. */
        private function equipPlayer():void
        {
            var mc:AvatarMC = actors[role].mc;
            var set:Object = actors[role].mc.pAV.m.ActiveSet;
            set.itemLinks.Armor = "CoastalRF";
            set.itemLinks.Weapon = "NoxiousRifle2";
            set.itemLinks.Cape = "NecroPCSheathedCutlass";
            set.itemLinks.Helmet = "SteelSeasVisage";
            mc.load("runtime/Armor.swf", mc.onLoadArmorComplete);
            mc.load("runtime/Weapon.swf", mc.onLoadWeaponComplete);
            mc.load("runtime/Cape.swf", mc.onLoadCapeComplete);
            mc.load("runtime/Helm.swf", mc.onLoadHelmComplete);
        }

        private function ui(name:String):MovieClip
        {
            switch (name)
            {
                case "UI_PlayerBox":
                    return new UIPlayerBox();
                case "UI_TargetBox":
                    return new UITargetBox();
                case "UI_PartyPanel":
                    return new UIPartyPanel();
                default:
                    return new UIActBar();
            }
        }

        private static function setFace(head:MovieClip, face:DisplayObject):void
        {
            var old:DisplayObject = head.head.getChildByName("face");
            if (old)
            {
                head.head.removeChild(old);
            }
            head.head.addChildAt(face, 0).name = "face";
        }

        /** Same recolouring AvatarMC.scanColor() does, applied to the portrait's item layers. */
        private function tintPortrait(c:DisplayObject):void
        {
            var mc:MovieClip = c as MovieClip;
            if (mc == null)
            {
                return;
            }
            if ("isColored" in mc)
            {
                actors[role].mc.changeColor(mc, Number(COLORS["intColor" + mc.strLocation]), mc.strShade);
            }
            for (var i:int = 0; i < mc.numChildren; i++)
            {
                tintPortrait(mc.getChildAt(i));
            }
        }

        private function buildHud():void
        {
            var g:Sprite = hudLayer;
            // Spider.swf's own HUD pieces (bin/runtime/ui.swf, see tools/extract_ui.py), at their in-game positions
            playerBox = ui("UI_PlayerBox");
            playerBox.x = 1;
            playerBox.y = 2;
            g.addChild(playerBox);
            targetBox = ui("UI_TargetBox");
            targetBox.x = 235;
            targetBox.y = 2;
            g.addChild(targetBox);
            // portrait rings, filled the way World/Game showPortraitBox() does it: swap the face (and helm) classes into mcHead.head
            var BossHead:Class = bossDomain.getDefinition("mcHeadUltraMalg") as Class;
            setFace(targetBox["mcHead"], new BossHead() as DisplayObject);
            targetBox["mcHead"].head.hair.visible = false;
            targetBox["mcHead"].head.helm.visible = false;
            targetBox["mcHead"].backhair.visible = false;
            targetBox["btnOption"].visible = false;
            targetBox["stars"].visible = false;
            var head:MovieClip = playerBox["mcHead"];
            setFace(head, new (armorDomain.getDefinition("CoastalRFHead") as Class)() as DisplayObject);
            head.head.hair.visible = false;
            while (head.head.helm.numChildren > 0)
            {
                head.head.helm.removeChildAt(0);
            }
            head.head.helm.addChild(new (helmDomain.getDefinition("SteelSeasVisage") as Class)() as DisplayObject);
            head.head.helm.visible = true;
            while (head.backhair.numChildren > 0)
            {
                head.backhair.removeChildAt(0);
            }
            head.backhair.addChild(new (helmDomain.getDefinition("SteelSeasVisage_backhair") as Class)() as DisplayObject);
            head.backhair.visible = true;
            playerBox["strName"].text = "Hero";
            playerBox["strLevel"].text = "100";
            targetBox["strName"].text = BOSS_NAME;
            targetBox["strClass"].text = "Boss";
            targetBox["strLevel"].text = "100";
            for (var i:int = 0; i < 9; i++)
            {
                var chip:TextField = Hud.label("", 11, 0xFFFFFF);
                chip.x = 14;
                chip.y = 240 + i * 18;
                chip.background = true;
                chip.backgroundColor = 0x080a12;
                chip.visible = false;
                g.addChild(chip);
                chipTexts.push(chip);
            }
            clockText = Hud.label("0:00", 14, 0xFFFFFF, true, "right", 100);
            clockText.x = 850;
            clockText.y = 6;
            g.addChild(clockText);
            nextText = Hud.label("", 11, 0x8A95AB, false, "right", 140);
            nextText.x = 810;
            nextText.y = 26;
            g.addChild(nextText);
            bannerText = Hud.label("", 16, 0xFFD24A, true, "center", 700);
            bannerText.x = 260;
            bannerText.y = 76;
            g.addChild(bannerText);
            shoutText = Hud.label("", 13, 0xE9E2FF, false, "center", 700);
            shoutText.x = 260;
            shoutText.y = 100;
            g.addChild(shoutText);
            overText = Hud.label("", 40, 0xFFFFFF, true, "center", 960);
            overText.y = 180;
            g.addChild(overText);
            overSub = Hud.label("", 15, 0xFFFFFF, false, "center", 960);
            overSub.y = 232;
            g.addChild(overSub);
            logText = Hud.label("", 10, 0xB8C1D6, false, "left", 360);
            logText.multiline = true;
            logText.wordWrap = true;
            logText.height = 90;
            logText.x = 596;
            logText.y = 396;
            logText.autoSize = "none";
            g.addChild(logText);
            buildBuffIcons();
            actBar = ui("UI_ActBar");
            actBar.x = 347;
            actBar.y = 494;
            g.addChild(actBar);
            buildButtons();
        }

        /**
         * One boxed icon per effect, in the same round slot art as the skills. Boss effects (Taunt) sit under the boss
         * frame, effects on our character (Stasis, Somber, Magia Burn) between our frame and the party frames.
         */
        private function buildBuffIcons():void
        {
            // skill-icon buffs reuse the class skill icons from Assets.swf (the same pictures as on the action bar)
            var defs:Array = [
                {name: "taunt", icon: BuffTaunt, boss: true},
                {name: "seal", icon: "apal3", boss: true},
                {name: "eden", icon: "apal4", boss: true}, // "Broken Seal"
                {name: "quix", icon: "LoO4", boss: true},
                {name: "stasis", icon: BuffStasis, boss: false},
                {name: "somber", icon: BuffSomber, boss: false},
                {name: "magiaBurn", icon: BuffMagiaBurn, boss: false},
                {name: "empowerment", icon: "LR3", boss: false},
                {name: "heal", icon: "apal2", boss: false},
                {name: "harmony", icon: "LoO1", boss: false},
                {name: "axiom", icon: "LoO3", boss: false},
                {name: "ordinance", icon: "LoO2", boss: false}
            ];
            for each (var d:Object in defs)
            {
                var size:Number = d.boss ? 30 : 23;
                var slot:Sprite = new Sprite();
                var bg:MovieClip = new UISlotBg();
                var bb:Rectangle = bg.getBounds(bg);
                var k:Number = size / Math.max(bb.width, bb.height);
                bg.scaleX = bg.scaleY = k;
                bg.x = -bb.x * k;
                bg.y = -bb.y * k;
                slot.addChild(bg);
                var icon:DisplayObject;
                if (d.icon is String)
                {
                    var AC:Class = assetsDomain.getDefinition(d.icon) as Class;
                    icon = new AC() as DisplayObject;
                }
                else
                {
                    icon = new d.icon() as DisplayObject;
                }
                var ib:Rectangle = icon.getBounds(icon);
                var ik:Number = (size * (d.icon is String ? 0.8 : 0.64)) / Math.max(ib.width, ib.height);
                icon.scaleX = icon.scaleY = ik;
                icon.x = size / 2 - (ib.x + ib.width / 2) * ik;
                icon.y = size / 2 - (ib.y + ib.height / 2) * ik;
                slot.addChild(icon);
                var cnt:TextField = Hud.label("", d.boss ? 10 : 9, 0xFFFFFF, true, "right", size);
                cnt.x = 0;
                cnt.y = size - (d.boss ? 15 : 14);
                slot.addChild(cnt);
                slot.mouseEnabled = false;
                slot.mouseChildren = false;
                slot.visible = false;
                hudLayer.addChild(slot);
                buffIcons[d.name] = {sp: slot, cnt: cnt, size: size, boss: d.boss};
            }
        }

        /** Lay out the active effects in a row; `count` is the little number in the corner. */
        private function showBuffs(active:Array):void
        {
            for each (var b:Object in buffIcons)
            {
                b.sp.visible = false;
            }
            var bx:Number = 245; // under the boss frame
            var px:Number = 8; // under our frame
            for each (var a:Object in active)
            {
                var ic:Object = buffIcons[a.name];
                ic.cnt.text = a.count;
                ic.sp.visible = true;
                if (ic.boss)
                {
                    ic.sp.x = bx;
                    ic.sp.y = 76;
                    bx += ic.size + 4;
                }
                else
                {
                    ic.sp.x = px;
                    ic.sp.y = 86;
                    px += ic.size + 3;
                }
            }
        }

        private function buildParty():void
        {
            for each (var old:MovieClip in partyPanels)
            {
                if (old.parent)
                {
                    old.parent.removeChild(old);
                }
            }
            partyPanels = {};
            var y:Number = 111;
            for each (var r:String in ["ap", "lr", "loo", "dps"])
            {
                if (r == role)
                {
                    continue;
                }
                var p:MovieClip = ui("UI_PartyPanel");
                p.x = 10;
                p.y = y;
                p["strName"].text = ROLE_SHORT[r] + " - " + (r == "dps" ? "DPS" : CLASS_NAMES[r]);
                hudLayer.addChild(p);
                partyPanels[r] = p;
                y += p.height + 4;
            }
        }

        /** HP / MP style bar of a Spider.swf frame: scale the fill and set its number. */
        private static function setBar(box:MovieClip, group:String, bar:String, text:String, frac:Number, value:String):void
        {
            var g:MovieClip = box[group] as MovieClip;
            if (g == null)
            {
                return;
            }
            var b:DisplayObject = g[bar];
            if (b)
            {
                b.scaleX = Math.max(0, Math.min(1, frac));
            }
            var t:TextField = g[text] as TextField;
            if (t)
            {
                t.text = value;
            }
        }

        private function button(text:String, x:Number, y:Number, w:Number, fn:Function):TextField
        {
            var b:Sprite = new Sprite();
            b.graphics.beginFill(0x161b26, 0.9);
            b.graphics.lineStyle(1, 0x273044);
            b.graphics.drawRoundRect(0, 0, w, 20, 6, 6);
            b.graphics.endFill();
            var t:TextField = Hud.label(text, 11, 0xD8DEEA, false, "center", w);
            t.y = 2;
            b.addChild(t);
            b.x = x;
            b.y = y;
            b.buttonMode = true;
            b.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void {
                e.stopPropagation();
                fn();
            });
            hudLayer.addChild(b);
            return t;
        }

        private function buildButtons():void
        {
            button("Lord of Order", 676, 52, 90, function():void { newFight("loo"); });
            button("Arch Paladin", 770, 52, 90, function():void { newFight("ap"); });
            button("Legion Rev.", 864, 52, 90, function():void { newFight("lr"); });
            button("Restart", 676, 76, 60, function():void { newFight(role); });
            button("Auto-pilot", 740, 76, 70, function():void { botOn = !botOn; });
            button("Pause", 814, 76, 50, function():void { paused = !paused; });
            button("1x/2x/4x", 868, 76, 86, function():void { simSpeed = simSpeed >= 4 ? 1 : simSpeed * 2; });
            hintsLabel = button("", 676, 100, 150, toggleHints);
            hintsLabel.text = "Hints: " + (hintsOn ? "ON" : "OFF") + " (H)";
            button("Fullscreen (F)", 836, 100, 118, toggleFullscreen);
        }

        private function toggleHints():void
        {
            hintsOn = !hintsOn;
            hintsLabel.text = "Hints: " + (hintsOn ? "ON" : "OFF") + " (H)";
        }

        private function toggleFullscreen():void
        {
            try
            {
                // inside a web page the page owns full screen (index.html defines toggleGameFullscreen)
                if (ExternalInterface.available && ExternalInterface.call("window.toggleGameFullscreen") === true)
                {
                    return;
                }
            }
            catch (err1:Error)
            {
            }
            try
            {
                stage.displayState = stage.displayState == StageDisplayState.NORMAL ? StageDisplayState.FULL_SCREEN_INTERACTIVE : StageDisplayState.NORMAL;
            }
            catch (err:Error)
            {
            }
        }

        private function buildSkillbar():void
        {
            for each (var old:Object in skillSlots)
            {
                for each (var d:DisplayObject in [old.icon, old.cd, old.key])
                {
                    if (d && d.parent)
                    {
                        d.parent.removeChild(d);
                    }
                }
            }
            skillSlots = [];
            var defs:Array = SKILLS[role];
            for (var i:int = 0; i < 6; i++)
            {
                var slot:MovieClip = actBar["blank" + i];
                var b:Rectangle = slot.getBounds(actBar);
                var cx:Number = b.x + b.width / 2;
                var cy:Number = b.y + b.height / 2;
                var icon:DisplayObject = null;
                if (defs[i][1] != null && assetsDomain.hasDefinition(defs[i][1]))
                {
                    var C:Class = assetsDomain.getDefinition(defs[i][1]) as Class;
                    icon = new C() as DisplayObject;
                    var ib:Rectangle = icon.getBounds(icon);
                    var k:Number = (b.width * 0.86) / Math.max(ib.width, ib.height);
                    icon.scaleX = icon.scaleY = k;
                    icon.x = cx - (ib.x + ib.width / 2) * k;
                    icon.y = cy - (ib.y + ib.height / 2) * k;
                }
                else if (i == 0 || i == 5)
                {
                    // Spider.swf's default icon (sprite 2811): auto attack for classes without their own, Taunt for everyone
                    icon = new UIAutoIcon();
                    var ab:Rectangle = icon.getBounds(icon);
                    var ak:Number = (b.width * 0.58) / Math.max(ab.width, ab.height);
                    icon.scaleX = icon.scaleY = ak;
                    icon.x = cx - (ab.x + ab.width / 2) * ak;
                    icon.y = cy - (ab.y + ab.height / 2) * ak;
                }
                else
                {
                    var nm:TextField = Hud.label(defs[i][0], 9, 0xD8DEEA, false, "center", b.width);
                    nm.x = b.x;
                    nm.y = cy - 7;
                    icon = nm;
                }
                (icon as Object).mouseEnabled = false;
                actBar.addChild(icon);
                var cd:Shape = new Shape();
                cd.x = cx;
                cd.y = cy;
                actBar.addChild(cd);
                var key:TextField = Hud.label(String(i + 1), 10, 0xFFFFFF, true);
                key.x = b.x + 1;
                key.y = b.y - 3;
                actBar.addChild(key);
                var cdt:TextField = actBar["txtCD" + i] as TextField;
                if (cdt)
                {
                    cdt.text = "";
                    actBar.setChildIndex(cdt, actBar.numChildren - 1);
                }
                slot.buttonMode = true;
                slot.addEventListener(MouseEvent.MOUSE_DOWN, makeSlotHandler(i + 1));
                skillSlots.push({sp: slot, cd: cd, txt: cdt, icon: icon, key: key, r: b.width / 2});
            }
        }

        private function makeSlotHandler(k:int):Function
        {
            return function(e:MouseEvent):void {
                e.stopPropagation();
                castKey(k);
            };
        }

        // ================================================================ fight lifecycle
        private function newFight(r:String):void
        {
            role = r;
            fight = new Fight(this, role, 10000000, [42000, 52000]);
            zoneRole = "";
            banner = "";
            shout = "";
            overText.text = "";
            overSub.text = "";
            targeted = true;
            raidDamage = 0;
            ownDamage = 0;
            botQueue = [];
            logLines = [];
            for each (var fc:MovieClip in floaters)
            {
                if (fc.parent)
                {
                    fc.parent.removeChild(fc);
                }
            }
            floaters = [];
            if (runeMC)
            {
                runeMC.gotoAndStop("off");
            }
            if (safeMC)
            {
                safeMC.gotoAndStop("off");
            }
            bossAnim("Idle", false);
            buildActors();
            startTime = getTimer();
            buildParty();
            buildSkillbar();
            portraitAt = 0;
            log("Engaged " + BOSS_NAME + " as " + CLASS_NAMES[role], "");
        }

        // ---------------------------------------------------------------- IFightHost
        public function bossAnim(label:String, loop:Boolean):void
        {
            if (fight && fight.over && fight.over.result == "win")
            {
                return;
            }
            bossLabel = label;
            bossLoop = loop;
            if (bossMC)
            {
                bossMC.gotoAndPlay(label);
            }
        }

        public function zone(on:Boolean, r:String):void
        {
            zoneRole = on ? r : "";
            if (runeMC)
            {
                runeMC.gotoAndStop(on ? "on" : "off");
            }
            if (safeMC)
            {
                safeMC.gotoAndStop(on ? "on" : "off");
            }
            if (on && fight)
            {
                var mine:Boolean = (r == role);
                setBanner(mine ? "EQUAL - zone " + zoneNumber(r) + ": STAND INSIDE THE BOX" : "EQUAL - " + ROLE_SHORT[r] + " inside; step OUTSIDE the box (right)", mine ? 0x6FD98A : 0xFFD24A, 3400);
            }
        }

        private function zoneNumber(r:String):int
        {
            for (var k:String in Fight.ZONE_ROLES)
            {
                if (Fight.ZONE_ROLES[k] == r)
                {
                    return int(k);
                }
            }
            return 0;
        }

        public function announce(text:String):void
        {
            shout = "\"" + text + "\"";
            shoutUntil = fight.t + 3500;
        }

        public function floater(r:String, text:String, kind:String):void
        {
            var x:Number = 480;
            var y:Number = 190;
            if (r != null && actors[r])
            {
                x = actors[r].mc.x + (Math.random() - 0.5) * 24;
                y = actors[r].mc.y - 108;
            }
            showNumber(x, y, text, kind);
        }

        /**
         * Floating combat text with Spider.swf's own clips, set up like World.showHitDisplay():
         * hit = white number, crit = orange with a red glow, heal = "+N+" in green, avoid text for the rest.
         */
        private function showNumber(x:Number, y:Number, text:String, kind:String):void
        {
            var clip:MovieClip;
            var label:String = text.replace(/[-+,]/g, "");
            var color:uint = 0xFFFFFF;
            var glow:uint = 0x000000;
            switch (kind)
            {
                case "crit":
                    clip = new UICritDisplay();
                    color = 0xFF9944;
                    glow = 0x330000;
                    break;
                case "heal":
                    clip = new UIHitDisplay();
                    label = "+" + label + "+";
                    color = 0x00FFAA;
                    break;
                case "bad":
                    clip = new UIAvoidDisplay();
                    label = text;
                    break;
                default:
                    clip = new UIHitDisplay();
            }
            var ti:TextField = clip["t"]["ti"] as TextField;
            ti.autoSize = "center";
            ti.text = label;
            ti.textColor = color;
            ti.filters = [new GlowFilter(glow, 1, 5, 5, 5, 1, false, false)];
            clip.mouseEnabled = false;
            clip.mouseChildren = false;
            clip.x = x;
            clip.y = y;
            fxLayer.addChild(clip);
            floaters.push(clip);
        }

        public function log(message:String, kind:String):void
        {
            var t:Number = fight ? fight.t / 1000 : 0;
            logLines.push("[" + t.toFixed(1) + "s] " + message);
            while (logLines.length > 7)
            {
                logLines.shift();
            }
            logText.text = logLines.join("\n");
        }

        public function playerInZone():Boolean
        {
            var m:AvatarMC = actors[role].mc;
            return m.x >= SAFE_A.x && m.x <= SAFE_A.x + SAFE_A.w && m.y >= SAFE_A.y && m.y <= SAFE_A.y + SAFE_A.h;
        }

        public function playerCentered():Boolean
        {
            var x:Number = actors[role].mc.x;
            return x >= 166 && x <= 812;
        }

        public function castFx(kind:String, r:String):void
        {
            // healing (Ordinance, Heal) plays no cast effect; the heal numbers are enough
            if (kind != "ordinance" && kind != "heal")
            {
                var C:Class = assetsDomain.getDefinition("Assets_20260702_fla.Symbol3aaaaa_loo_757") as Class;
                var clip:MovieClip = new C() as MovieClip;
                clip.mouseEnabled = false;
                clip.x = actors[r].mc.x;
                clip.y = actors[r].mc.y - 50;
                fxLayer.addChild(clip);
                fxClips.push(clip);
            }
            if (kind != "taunt")
            {
                pose(actors[r], "Cast1", 0.7);
            }
        }

        public function bossDamage(amount:int, crit:Boolean, who:String):void
        {
            if (who == "party")
            {
                raidDamage += amount;
                if (Math.random() < 0.35)
                {
                    bossFloater(amount, crit);
                }
            }
            else
            {
                ownDamage += amount;
                bossFloater(amount, crit);
            }
        }

        private function bossFloater(amount:int, crit:Boolean):void
        {
            showNumber(BOSS_PAD.x + (Math.random() - 0.5) * 200, BOSS_PAD.y - 150 - Math.random() * 60, String(amount), crit ? "crit" : "hit");
        }

        public function mechanic(holder:String, ability:String, truthN:int, zoneN:int):void
        {
            var label:String = ability == "truth" ? "Truth" : (ability == "listen" ? "Listen" : "");
            var mine:Boolean = (holder == role);
            if (holder != null && label != "")
            {
                setBanner(mine ? "TAUNT NOW - " + label + " on YOU (6)" : ROLE_SHORT[holder] + " holds the boss - " + label, mine ? 0xFF5B5B : 0xFFD24A, 2400);
            }
            if (ability == "truth")
            {
                var n:int = ((truthN - 1) % 9) + 1;
                var needSeal:Boolean = (truthN >= 1 && truthN <= 3) || (truthN >= 5 && truthN <= 7);
                if (role == "loo" && (n == 5 || n == 9))
                {
                    setBanner("QUIX NOW - Truth #" + n + " (5)" + (mine ? " + TAUNT (6)" : ""), 0xFF5B5B, 2400);
                }
                else if (role == "ap" && needSeal)
                {
                    setBanner("SEAL NOW (4) - Truth #" + truthN + (mine ? " + TAUNT (6)" : ""), 0xFF5B5B, 2400);
                }
            }
            if (botOn)
            {
                botReact(holder, ability, truthN);
            }
        }

        public function ended(result:String, reason:String):void
        {
            if (result == "win")
            {
                bossMC.gotoAndPlay("Die");
                log("Victory - " + reason, "good");
            }
            else
            {
                log("Defeat - " + reason, "bad");
            }
            overText.text = result == "win" ? "VICTORY" : "DEFEATED";
            overText.textColor = result == "win" ? 0x6FD98A : 0xFF5B5B;
            overSub.text = reason + " - press Restart";
        }

        private function setBanner(text:String, color:uint, ms:Number):void
        {
            banner = text;
            bannerColor = color;
            bannerUntil = fight.t + ms;
        }

        // ===================================================================== input
        private function onMouseDown(e:MouseEvent):void
        {
            if (!ready || fight.over)
            {
                return;
            }
            var a:Object = actors[role];
            var mx:Number = stage.mouseX;
            var my:Number = stage.mouseY;
            // the wings' pixels, or the boss' body column (the clip is mostly glow and gaps)
            if (bossMC.hitTestPoint(mx, my, true) || (Math.abs(mx - BOSS_PAD.x) <= 150 && my >= 40 && my <= BOSS_PAD.y + 30))
            {
                moveToBoss(); // click the boss: target it and walk into range
                return;
            }
            a.moveTo = new Point(clamp(stage.mouseX, WALK.x0, WALK.x1), clamp(stage.mouseY, WALK.y0, WALK.y1));
        }

        private function onKeyDown(e:KeyboardEvent):void
        {
            var k:int = e.keyCode - 48; // keys 1-6
            if (k >= 1 && k <= 6)
            {
                castKey(k);
            }
            else if (e.keyCode == 72)
            {
                toggleHints();
            }
            else if (e.keyCode == 70)
            {
                toggleFullscreen();
            }
            else if (e.keyCode == 80)
            {
                paused = !paused;
            }
        }

        private function moveToBoss():void
        {
            targeted = true;
            actors[role].moveTo = new Point(BOSS_PAD.x - 90, BOSS_PAD.y + 70);
        }

        private function castKey(k:int):Boolean
        {
            if (fight.over)
            {
                return false;
            }
            if (k == 1)
            {
                moveToBoss();
                return true;
            }
            return fight.cast(k);
        }

        private static function clamp(v:Number, a:Number, b:Number):Number
        {
            return Math.max(a, Math.min(b, v));
        }

        // ===================================================================== update
        private function onFrame(e:Event):void
        {
            var now:int = getTimer();
            var dt:Number = Math.min((now - lastTime) / 1000, 0.1);
            lastTime = now;
            if (!paused)
            {
                var sdt:Number = dt * simSpeed;
                var steps:int = Math.max(1, Math.ceil(sdt / 0.05));
                for (var i:int = 0; i < steps; i++)
                {
                    fight.step((sdt / steps) * 1000);
                    runBot();
                    updateActors(sdt / steps);
                }
                updateFloaters(sdt);
            }
            if (now - lastColor > 400 && now - startTime < 15000)
            {
                lastColor = now; // re-tint item layers as the gear SWFs finish loading
                actors[role].mc.updateColor();
                tintPortrait(playerBox["mcHead"]);
            }
            updateBoss();
            updateFx();
            sortActors();
            updateHud();
        }

        private function updateActors(dt:Number):void
        {
            var f:Fight = fight;
            for each (var r:String in Fight.ROLES)
            {
                var a:Object = actors[r];
                var mc:AvatarMC = a.mc;
                if (f.hp[r] <= 0)
                {
                    setMoving(a, false);
                    pose(a, "Dead", 99);
                    continue;
                }
                var isMe:Boolean = (r == role);
                var goal:Point = null;
                if (isMe)
                {
                    goal = f.over ? null : a.moveTo;
                }
                else if (zoneRole != "")
                {
                    goal = zoneRole == r ? MIDDLE_AT : spot(RIGHT_AT, r);
                }
                else
                {
                    goal = spot(MIDDLE_AT, r);
                }
                stepActor(a, goal, dt, isMe ? 250 : 300);
                // swing at the boss when standing still near it
                a.aaT -= dt;
                var near:Boolean = Math.abs(BOSS_PAD.x - mc.x) <= 260 && Math.abs(BOSS_PAD.y - mc.y) <= 130;
                if (!a.moving && near && a.aaT <= 0 && !f.over && (!isMe || targeted))
                {
                    a.aaT = 1.33;
                    face(a, BOSS_PAD.x >= mc.x ? 1 : -1);
                    pose(a, isMe ? "RifleAttack" : "Attack1", 0.7);
                    if (isMe && !f.stunned())
                    {
                        var d:int = int(Math.floor(1800 + Math.random() * 500));
                        f.playerHit(d, d > 2200);
                    }
                }
                else if (!a.moving && a.poseUntil < f.t / 1000)
                {
                    pose(a, isMe && targeted && near ? "RifleFight" : "Idle", 0);
                }
            }
        }

        private function stepActor(a:Object, goal:Point, dt:Number, speed:Number):void
        {
            var mc:AvatarMC = a.mc;
            if (goal == null)
            {
                setMoving(a, false);
                return;
            }
            var dx:Number = goal.x - mc.x;
            var dy:Number = goal.y - mc.y;
            var d:Number = Math.sqrt(dx * dx + dy * dy);
            if (d < 3)
            {
                setMoving(a, false);
                if (a.moveTo == goal)
                {
                    a.moveTo = null;
                }
                return;
            }
            var st:Number = Math.min(d, speed * dt);
            mc.x += (dx / d) * st;
            mc.y += (dy / d) * st;
            if (Math.abs(dx) > 1)
            {
                face(a, dx > 0 ? 1 : -1);
            }
            setMoving(a, true);
        }

        private function face(a:Object, dir:int):void
        {
            if (a.dir != dir)
            {
                a.dir = dir;
                a.mc.turn(dir > 0 ? "right" : "left");
            }
        }

        private function setMoving(a:Object, on:Boolean):void
        {
            if (a.moving == on)
            {
                return;
            }
            a.moving = on;
            a.mc.mcChar.onMove = on;
            if (on)
            {
                a.pose = "Walk";
                a.mc.mcChar.gotoAndPlay("Walk");
            }
            else
            {
                a.pose = "";
            }
        }

        /** Switch a character to an animation label; `seconds` keeps idle poses from overriding it. */
        private function pose(a:Object, label:String, seconds:Number):void
        {
            var force:Boolean = seconds > 0;
            if (a.pose == label && !force)
            {
                return;
            }
            if (a.pose == label && a.poseUntil > fight.t / 1000)
            {
                return;
            }
            a.pose = label;
            a.poseUntil = fight.t / 1000 + seconds;
            a.mc.mcChar.gotoAndPlay(label);
        }

        private function updateBoss():void
        {
            // ChargeALoop ends on a stop(): restart it so the charge keeps animating
            if (bossLoop && BOSS_FRAMES[bossLabel] && bossMC.currentFrame >= BOSS_FRAMES[bossLabel][1])
            {
                bossMC.gotoAndPlay(bossLabel);
            }
            targetRing.visible = targeted;
        }

        private function updateFx():void
        {
            for (var i:int = fxClips.length - 1; i >= 0; i--)
            {
                var c:MovieClip = fxClips[i];
                if (c.currentFrame >= c.totalFrames)
                {
                    c.parent.removeChild(c);
                    fxClips.splice(i, 1);
                }
            }
        }

        private function updateFloaters(dt:Number):void
        {
            // the clips animate themselves (and used to remove themselves in game scripts, which are not part of the art)
            for (var i:int = floaters.length - 1; i >= 0; i--)
            {
                var c:MovieClip = floaters[i];
                if (c.currentFrame >= c.totalFrames)
                {
                    c.parent.removeChild(c);
                    floaters.splice(i, 1);
                }
            }
        }

        private function sortActors():void
        {
            var list:Array = [{y: BOSS_PAD.y, o: bossMC}];
            for each (var r:String in Fight.ROLES)
            {
                list.push({y: actors[r].mc.y, o: actors[r].mc});
            }
            list.sortOn("y", Array.NUMERIC);
            for (var i:int = 0; i < list.length; i++)
            {
                actorLayer.setChildIndex(list[i].o, i + 1);
            }
        }

        // ====================================================================== HUD
        private function updateHud():void
        {
            var f:Fight = fight;
            // Spider.swf status boxes: player and target (the boss)
            playerBox["strClass"].text = CLASS_NAMES[role];
            setBar(playerBox, "HP", "intHPbar", "strIntHP", f.hp[role] / f.maxHp(role), Fight.fmt(f.hp[role]));
            setBar(playerBox, "MP", "intMPbar", "strIntMP", 1, "100");
            setBar(playerBox, "SP", "intSPbar", "strIntSP", 1, "100");
            setBar(targetBox, "HP", "intHPbar", "strIntHP", f.bossHp / f.bossMaxHp, Fight.fmt(f.bossHp));
            setBar(targetBox, "MP", "intMPbar", "strIntMP", 1, "100");
            for (var r:String in partyPanels)
            {
                setBar(partyPanels[r], "HP", "intHPbar", "strIntHP", f.hp[r] / f.maxHp(r), Fight.fmt(f.hp[r]));
                setBar(partyPanels[r], "MP", "intMPbar", "strIntMP", 1, "");
                var sm:int = f.somber[r];
                partyPanels[r]["strName"].text = ROLE_SHORT[r] + " - " + (r == "dps" ? "DPS" : CLASS_NAMES[r]) + (sm > 0 ? "  x" + sm : "");
            }
            // buff chips
            var chips:Array = [];
            var t:Number = f.t;
            var active:Array = [];
            var remain:Function = function(until:Number):String { return String(Math.ceil((until - t) / 1000)); };
            // on the boss
            if (f.currentTaunt() != null)
            {
                active.push({name: "taunt", count: ROLE_SHORT[f.currentTaunt()]});
            }
            if (f.apReduction == "seal")
            {
                active.push({name: "seal", count: ""});
            }
            else if (f.apReduction == "eden")
            {
                active.push({name: "eden", count: ""});
            }
            if (t < f.quixUntil)
            {
                active.push({name: "quix", count: remain(f.quixUntil)});
            }
            // on us
            if (f.stunned())
            {
                active.push({name: "stasis", count: remain(f.stunUntil)});
            }
            if (f.somber[role] > 0)
            {
                active.push({name: "somber", count: String(f.somber[role])});
            }
            if (t < f.magiaBurnUntil)
            {
                active.push({name: "magiaBurn", count: remain(f.magiaBurnUntil)});
            }
            if (role == "lr" && t < f.lrEmpowerUntil)
            {
                active.push({name: "empowerment", count: remain(f.lrEmpowerUntil)});
            }
            if (f.apHealBuff)
            {
                active.push({name: "heal", count: remain(f.apHealUntil)});
            }
            if (f.harmonyBuff)
            {
                active.push({name: "harmony", count: remain(f.harmonyUntil)});
            }
            if (t < f.axiomUntil)
            {
                active.push({name: "axiom", count: remain(f.axiomUntil)});
            }
            if (t < f.ordinanceUntil)
            {
                active.push({name: "ordinance", count: remain(f.ordinanceUntil)});
            }
            showBuffs(active);
            for (var c:int = 0; c < chipTexts.length; c++)
            {
                chipTexts[c].visible = c < chips.length;
                if (c < chips.length)
                {
                    chipTexts[c].text = chips[c];
                }
            }
            var secs:Number = f.t / 1000;
            clockText.text = int(secs / 60) + ":" + (int(secs % 60) < 10 ? "0" : "") + int(secs % 60);
            // with hints off nothing says whose zone it is, who must taunt, or what is coming next
            nextText.text = hintsOn ? "Next: " + Fight.PATTERN[f.ruleIdx] : "";
            logText.visible = hintsOn;
            bannerText.text = (hintsOn && banner != "" && f.t < bannerUntil) ? banner : "";
            bannerText.textColor = bannerColor;
            shoutText.text = (shout != "" && f.t < shoutUntil) ? shout : "";
            // skill cooldowns on the action bar
            for (var s:int = 0; s < skillSlots.length; s++)
            {
                var slot:Object = skillSlots[s];
                var k:int = s + 1;
                var name:String = f.skillName(k);
                var left:Number = k == 1 ? 0 : Math.max(0, f.cd[k] - f.t);
                var len:Number = name != null ? Fight.SKILL_CD[name] : 1;
                slot.cd.graphics.clear();
                if (left > 0)
                {
                    slot.cd.graphics.beginFill(0x000000, 0.6);
                    slot.cd.graphics.drawCircle(0, 0, slot.r);
                    slot.cd.graphics.endFill();
                }
                if (slot.txt)
                {
                    slot.txt.text = left > 50 ? (left / 1000).toFixed(left > 9950 ? 0 : 1) : "";
                }
                slot.icon.alpha = f.stunned() && k >= 2 ? 0.5 : 1;
            }
            // health bars over each character
            for each (var who:String in Fight.ROLES)
            {
                var a:Object = actors[who];
                Hud.bar(a.bar, 56, 6, f.hp[who] / f.maxHp(who), 0x6FE08A, 0x1D8A3A);
                a.bar.x = a.mc.x - 28;
                a.bar.y = a.mc.y - 104;
            }
        }

        private function botReact(holder:String, ability:String, truthN:int):void
        {
            var at:Number = fight.t + 350;
            if (holder == role)
            {
                botQueue.push({at: at, until: at + 1400, k: 6});
            }
            if (ability == "truth")
            {
                var n:int = ((truthN - 1) % 9) + 1;
                if (role == "loo" && (n == 5 || n == 9))
                {
                    botQueue.push({at: at, until: at + 1400, k: 5});
                }
                if (role == "ap" && ((truthN >= 1 && truthN <= 3) || (truthN >= 5 && truthN <= 7)))
                {
                    botQueue.push({at: at, until: at + 1400, k: 4});
                    botQueue.push({at: fight.t + 5000, until: fight.t + 6500, k: 5});
                }
            }
        }

        private function runBot():void
        {
            if (!botOn || fight.over)
            {
                return;
            }
            var f:Fight = fight;
            var a:Object = actors[role];
            for (var i:int = botQueue.length - 1; i >= 0; i--)
            {
                var q:Object = botQueue[i];
                if (f.t > q.until)
                {
                    botQueue.splice(i, 1);
                }
                else if (f.t >= q.at && f.cast(q.k))
                {
                    botQueue.splice(i, 1);
                }
            }
            // positioning: the clicks a player would make
            if (zoneRole != "")
            {
                var wantIn:Boolean = (zoneRole == role);
                if (wantIn != playerInZone())
                {
                    a.moveTo = wantIn ? MIDDLE_AT.clone() : spot(RIGHT_AT, role);
                }
            }
            else
            {
                var home:Point = spot(MIDDLE_AT, role);
                if (a.moveTo == null && Point.distance(new Point(a.mc.x, a.mc.y), home) > 20)
                {
                    a.moveTo = home;
                }
            }
            var low:Boolean = false;
            for each (var r:String in Fight.ROLES)
            {
                if (f.hp[r] < f.maxHp(r) * 0.65)
                {
                    low = true;
                }
            }
            if (zoneRole == role && f.hp[role] < 3400)
            {
                low = true;
            }
            if (role == "loo")
            {
                if (low) f.cast(3);
                f.cast(2);
                f.cast(4);
            }
            else if (role == "ap")
            {
                if (low) f.cast(3);
                f.cast(2);
            }
            else
            {
                f.cast(4);
                f.cast(5);
                f.cast(3);
            }
        }

        // ============================================================ state for tests
        public function getState():String
        {
            var f:Fight = fight;
            return "{\"t\":" + Math.round(f.t) + ",\"bossHp\":" + Math.round(f.bossHp) +
                ",\"hp\":{\"ap\":" + f.hp.ap + ",\"lr\":" + f.hp.lr + ",\"loo\":" + f.hp.loo + ",\"dps\":" + f.hp.dps + "}" +
                ",\"over\":" + (f.over ? "\"" + f.over.result + ": " + f.over.reason + "\"" : "null") +
                ",\"zone\":\"" + zoneRole + "\",\"role\":\"" + role + "\"" +
                ",\"player\":[" + Math.round(actors[role].mc.x) + "," + Math.round(actors[role].mc.y) + "]" +
                ",\"gear\":\"" + gearState() + "\"}";
        }

        private function gearState():String
        {
            var mc:AvatarMC = actors[role].mc;
            return (mc.mcChar.weapon.visible ? "weapon " : "") + (mc.mcChar.cape.visible ? "cape " : "") + (mc.mcChar.head.helm.visible ? "helm" : "");
        }
    }
}

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
    import flash.text.TextFieldType;
    import flash.text.TextFormat;
    import flash.utils.getQualifiedClassName;
    import flash.utils.getTimer;
    import flash.utils.setTimeout;

    import sim.DageFight;
    import sim.DrakathFight;
    import sim.Fight;
    import sim.GramielFight;
    import sim.Hud;
    import sim.IFightHost;
    import sim.NulgathFight;

    import flash.filters.GlowFilter;

    import ui.BuffAeternaNox;
    import ui.BuffCog;
    import ui.BuffMagiaBurn;
    import ui.BuffNoxiousDecay;
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
    [SWF(width="960", height="500", frameRate="24", backgroundColor="#000000")]
    public dynamic class UltraSim extends MovieClip implements IFightHost
    {
        // ---- geometry (twips/20 from the map's Boss frame, see README) ------------------
        private static const RIGHT_AT:Point = new Point(868, 410);
        private static const SAFE_A:Object = {x: 180.65, y: 220.55, w: 612.7, h: 294.7};
        private static const WALK:Object = {x0: 24, x1: 936, y0: 240, y1: 488};
        private static const STACK:Object = {ap: [-6, -2], lr: [6, -1], dps: [-2, 2], loo: [2, 0], ca: [-6, -2], cn: [6, -1], pc: [6, -1], cs: [-6, -2], da: [-2, 2], db: [2, 0], sh: [-2, 2], sc: [-6, -2]};
        private static const STAGE_W:Number = 960;
        private static const STAGE_H:Number = 500;
        private static const BUFFS_PER_ROW:int = 4;
        private static const RETURN_MS:int = 3500; // delay before the start screen returns after victory/defeat
        /** Selectable bosses: map / boss SWFs, party roles, boss spot and playable classes of each. */
        private static const BOSSES:Array = [
            {id: "speaker", name: "Ultra Speaker", classes: ["loo", "ap", "lr"],
                mapFrame: "Boss", mapSwf: "runtime/town-ultraspeaker.swf", bossSwf: "runtime/monster-UltraMalg.swf", bossClass: "UltraMalg", headClass: "mcHeadUltraMalg",
                roles: ["ap", "lr", "loo", "dps"], pad: new Point(492.5, 305), home: new Point(480, 315), scale: 0.43, charScale: 0.42,
                loops: {ChargeALoop: [154, 172], PowerLoop: [95, 111], ChargeBLoop: [209, 228]}},
            {id: "dage", name: "Ultra Dage", classes: ["ca"],
                mapFrame: "Boss", idleStop: true, dieLabel: "Die", mapSwf: "runtime/town-ultradage.swf", bossSwf: "runtime/monster-UltraDage.swf", bossClass: "UltraDage", headClass: "mcHeadUltraDage",
                roles: ["ca", "cn", "da", "db"], pad: new Point(486, 288), home: new Point(480, 302), scale: 0.78, charScale: 0.75, flip: true,
                loops: {PowerLoop: [351, 363], ChargeLoop: [193, 208]}},
            {id: "drakath", name: "Champion Drakath", classes: ["lr", "pc"], mapFrame: "r2", hideIdx: [1], idleStop: true, dieLabel: "Die",
                mapSwf: "runtime/town-championdrakath.swf", bossSwf: "runtime/monster-DoubleDrak.swf", bossClass: "DoubleDrak", headClass: "mcHeadDoubleDrak",
                roles: ["lr", "pc", "loo", "cs"], pad: new Point(800, 317), home: new Point(677, 377), scale: 0.72, charScale: 0.75, flip: true, originDy: 66,
                loops: {}},
            {id: "nulgath", name: "Ultra Nulgath", classes: ["lr", "loo"], mapFrame: "Boss", idleStop: true, dieLabel: "Die",
                mapSwf: "runtime/town-ultranulgath.swf", bossSwf: "runtime/monster-UltraNulgath.swf", bossClass: "UltraNulgath", headClass: "mcHeadUltraNulgath",
                bladeSwf: "runtime/monster-OverfiendBlade.swf", bladeClass: "OverfiendBlade",
                roles: ["lr", "loo", "ap", "cs"], pad: new Point(150, 350), home: new Point(745, 440), scale: 1.0, charScale: 1.4,
                bladePad: new Point(367, 477), bladeScale: 1.35,
                loops: {Chargeloop: [185, 206]}},
            {id: "gramiel", name: "Ultra Gramiel", classes: ["sh"], mapFrame: "r2", idleStop: true, dieLabel: "Die",
                mapSwf: "runtime/town-ultragramiel.swf", bossSwf: "runtime/monster-UltraGramiel.swf", bossClass: "UltraGramiel", headClass: "mcHeadUltraGramiel",
                crystalSwf: "runtime/monster-GraceCrystal.swf", crystalClass: "GraceCrystal", crystalHead: "mcHeadGraceCrystal",
                roles: ["sh", "lr", "sc", "loo"], pad: new Point(492, 284), home: new Point(492, 385), scale: 0.85, charScale: 0.8,
                crystalPads: [new Point(182, 359), new Point(806, 368)], crystalScale: 0.7, crystalBarY: 236, stack: {lr: [-150, -4], sc: [-78, 6], sh: [62, 6], loo: [138, -3]},
                loops: {ChargeLoop1: [151, 164], ChargeLoop2: [213, 230]}, crystalLoops: {ChargeLoop: [157, 177]}}
        ];
        // centre / size of the portrait ring in the local coordinates of the status box's mcHead
        private static const PORTRAIT_CX:Number = 50;
        private static const PORTRAIT_CY:Number = 25;
        private static const PORTRAIT_SIZE:Number = 58;

        private static const ROLE_COLOR:Object = {ap: 0xE8D9A0, lr: 0xE0507A, loo: 0xE0B84A, dps: 0x5AA86A};
        private static const ROLE_FULL:Object = {ap: "Arch Paladin", lr: "Legion Revenant", loo: "Lord of Order", dps: "DPS",
            ca: "Chaos Avenger", cn: "Classic Ninja", pc: "Paladin Chronomancer", cs: "Chrono ShadowSlayer", da: "DPS 1", db: "DPS 2", sh: "Shaman", sc: "StoneCrusher"};
        private static const CLASS_NAMES:Object = {loo: "Lord of Order", ap: "Arch Paladin", lr: "Legion Revenant", ca: "Chaos Avenger", cn: "Classic Ninja", pc: "Paladin Chronomancer", sh: "Shaman"};

        // skill bar: slot -> [label, icon class in Assets.swf]. The SWF ships aa + 4 numbered icons per class.
        private static const SKILLS:Object = {
            loo: [["Attack", "LoOaa"], ["Harmony", "LoO1"], ["Ordinance", "LoO2"], ["Axiom", "LoO3"], ["Quix", "LoO4"], ["Taunt", null]],
            ap: [["Attack", null], ["Commandment", "apal1"], ["Heal", "apal2"], ["Seal", "apal3"], ["Eden", "apal4"], ["Taunt", null]],
            lr: [["Attack", "LRaa"], ["Shade", "LR1"], ["Wicked", "LR2"], ["Empowerment", "LR3"], ["Anathema", "LR4"], ["Taunt", null]],
            // Ultra Dage classes (classes.json): aa, four skills, potions. Flux (3) is the Chaos Avenger's taunt.
            ca: [["Greatsword", "Chavengeaa"], ["Siphon", "Chavengea1"], ["Flux", "Chavengea2"], ["Bulwark", "Chavengea3"], ["Fury", "Chavengea4"], ["Potions", "icu1"]],
            pc: [["Hammer", "PallyChAA"], ["Rift", "PallyChA1"], ["Vow", "PallyChA2"], ["Intervention", "PallyChA3"], ["Retribution", "PallyChA4"], ["Taunt", null]],
            cn: [["Attack", "iwd1"], ["Crosscut", "imr1"], ["Shadowblade", "ied2"], ["Shadowburn", "ief2"], ["Thin Air", "iea1"], ["Potions", "icu1"]],
            // Ultra Gramiel's DPS (classes.json: Shaman); slot 6 is the taunt
            sh: [["Attack", "iwd1"], ["Ancestor's Flame", "ief1"], ["Hydrophobia", "iew1"], ["Dry Lightning", "iee2"], ["Elemental Embrace", "iea1"], ["Taunt", null]]
        };


        // skin / hair / eye tones applied to the colour-keyed layers of the equipped items
        private static const COLORS:Object = {intColorSkin: 0xF0C9A0, intColorHair: 0xFFCC99, intColorEye: 0x4A90D9};

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
        private var bossDomain:ApplicationDomain;
        private var bossScenes:Object = {};   // boss id -> {map, boss, rune, safe, safe2, domain, def}
        private var bossId:String = "speaker";
        private var initialBoss:String = "speaker";
        private var bossDef:Object = BOSSES[0];
        private var roles:Array = BOSSES[0].roles;
        private var bossPad:Point = BOSSES[0].pad;
        private var homeAt:Point = BOSSES[0].home;
        private var bossLoops:Object = BOSSES[0].loops;
        private var plateId:String = "";
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
        private var bladeMC:MovieClip;
        private var targetBlade:Boolean = false; // Ultra Nulgath: the clicked Overfiend Blade is the target
        private var crystalMCs:Array = [];         // Ultra Gramiel: the left / right Grace Crystal clips
        private var crystalLabel:Array = ["Idle", "Idle"];
        private var crystalLoop:Array = [false, false];
        private var crystalBars:Array = [];
        private var crystalTexts:Array = [];
        private var targetSel:String = "boss";     // Ultra Gramiel: "boss" | "cl" | "cr"
        private var chatField:TextField;
        private var chatHint:TextField;
        private var bubbles:Object = {};
        private var targetRing:Shape = new Shape();
        private var runeMC:MovieClip;
        private var safeMC:MovieClip;
        private var safe2MC:MovieClip;

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
        private var startScreen:Sprite;
        private var cards:Object = {};
        private var simSpeed:Number = 1;
        private var cacheMap:Boolean = false;
        private var glowText:Boolean = true; // FlashVars fx=0: plain combat text (cheaper to draw)
        private var stamina:Number = 100;      // the green bar: a sprint (Space + click) costs SPRINT_COST, standing still refills it
        private var spaceHeld:Boolean = false;
        private static const SPRINT_COST:Number = 50;
        private static const STAMINA_REGEN:Number = 20; // per second while standing still
        private static const WALK_SPEED:Number = 250;
        private static const SPRINT_SPEED:Number = 480;
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
        private var bossBuffX:Number = 245;
        private var playerBuffX:Number = 8;
        private var armorDomain:ApplicationDomain;
        private var helmDomain:ApplicationDomain;
        private var portraitAt:int = 0;
        private var chipTexts:Array = [];
        private var clockText:TextField;
        private var nextText:TextField;
        private var nextPanel:Sprite;
        private var bannerText:TextField;
        private var shoutText:TextField;
        private var overText:TextField;
        private var overSub:TextField;
        private var skillSlots:Array = [];
        private var logText:TextField;
        private var logPanel:Sprite;
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
            // scale the whole 960x500 game to the window / full screen, keeping the aspect ratio
            stage.scaleMode = StageScaleMode.SHOW_ALL;
            stage.align = "";
            var p:Object = loaderInfo.parameters;
            if (p["class"] && CLASS_NAMES[p["class"]])
            {
                role = p["class"];
            }
            initialBoss = ["dage", "drakath", "nulgath", "gramiel"].indexOf(p["boss"]) >= 0 ? p["boss"] : "speaker";
            glowText = p["fx"] != "0";
            cacheMap = p["cache"] == "1";
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
            loadingText = Hud.label("Loading...", 18, 0xFFFFFF, true, "center", STAGE_W);
            loadingText.x = 0;
            loadingText.y = (STAGE_H - 24) / 2;
            addChild(loadingText);

            mapHolder = new MovieClip();
            mapHolder.strFrame = "Boss";
            mapHolder.cellSetup = function(a:*, b:*, c:*):void {};
            mapHolder.onWalkClick = function():void {};
            mapLayer.addChild(mapHolder);

            pending = 3 + 2 * BOSSES.length + 2; // + the Overfiend Blade, the Grace Crystal
            for each (var bd:Object in BOSSES)
            {
                var sc:Object = {def: bd};
                bossScenes[bd.id] = sc;
                sc.mapDomain = loadSwf(bd.mapSwf, makeLoaded(sc, "mapLoader"));
                sc.domain = loadSwf(bd.bossSwf, makeLoaded(sc, "bossLoader"));
                if (bd.bladeSwf)
                {
                    sc.bladeDomain = loadSwf(bd.bladeSwf, makeLoaded(sc, "bladeLoader"));
                }
                if (bd.crystalSwf)
                {
                    sc.crystalDomain = loadSwf(bd.crystalSwf, makeLoaded(sc, "crystalLoader"));
                }
            }
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

        private function makeLoaded(sc:Object, key:String):Function
        {
            return function(l:Loader):void { sc[key] = l; };
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
            for each (var bd:Object in BOSSES)
            {
                buildMap(bossScenes[bd.id]);
                buildBoss(bossScenes[bd.id]);
            }
            buildHud();
            selectBoss(initialBoss);
            stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
            stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
            stage.focus = stage; // keys work from the first frame
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
                    ExternalInterface.addCallback("play", playGame);
                    ExternalInterface.addCallback("mapChildren", function():String {
                        var out:Array = [];
                        for (var mi:int = 0; mi < mapMC.numChildren; mi++)
                        {
                            var mc:DisplayObject = mapMC.getChildAt(mi);
                            out.push(mi + " " + getQualifiedClassName(mc) + " " + mc.name + " " + mc.visible + " " + Math.round(mc.x) + "," + Math.round(mc.y));
                        }
                        return out.join("\n");
                    });
                }
            }
            catch (err:Error)
            {
            }
            ready = true;
            if (loaderInfo.parameters["autoplay"] == "1")
            {
                paused = false;
            }
            else
            {
                showStartScreen();
            }
        }

        private function buildMap(sc:Object):void
        {
            var m:MovieClip = sc.mapLoader.content as MovieClip;
            sc.map = m;
            m.visible = false;
            mapHolder.addChild(m);
            m.gotoAndStop(sc.def.mapFrame);
            // keep the painted backdrop and the zone clips, hide the map-editor furniture
            for (var i:int = 0; i < m.numChildren; i++)
            {
                var c:DisplayObject = m.getChildAt(i);
                if (c.name == "rune1" || c.name == "safe1" || c.name == "safe2")
                {
                    continue;
                }
                if (sc.def.id == "speaker" ? i > 0 : (isFurniture(c) || (sc.def.hideIdx && sc.def.hideIdx.indexOf(i) >= 0)))
                {
                    c.visible = false;
                }
            }
            sc.rune = m.getChildByName("rune1") as MovieClip;
            sc.safe = m.getChildByName("safe1") as MovieClip;
            sc.safe2 = m.getChildByName("safe2") as MovieClip;
            for each (var z:MovieClip in [sc.rune, sc.safe, sc.safe2])
            {
                if (z)
                {
                    z.gotoAndStop("off");
                }
            }
        }

        /** Ultra Dage's map keeps its art in several layers; only the editor / game-logic clips are hidden. */
        private static function isFurniture(c:DisplayObject):Boolean
        {
            var cn:String = getQualifiedClassName(c);
            for each (var key:String in ["Plate_", "Box_Generic", "Setup_", "checkQS", "mcShadow", "mcWalkingArea", "Pad_", "comp_", "Popup", "mcCrystals"])
            {
                if (cn.indexOf(key) >= 0)
                {
                    return true;
                }
            }
            return false;
        }

        /** the target frame shows the boss, or the Overfiend Blade (Ultra Nulgath) when that was clicked */
        private function showTarget(blade:Boolean):void
        {
            targetBlade = blade;
            var domain:ApplicationDomain = blade ? bossScenes[bossId].bladeDomain : bossDomain;
            setFace(targetBox["mcHead"], new (domain.getDefinition(blade ? "mcHeadOverfiendBlade" : bossDef.headClass) as Class)() as DisplayObject);
            targetBox["mcHead"].head.hair.visible = false;
            targetBox["mcHead"].head.helm.visible = false;
            targetBox["mcHead"].backhair.visible = false;
            targetBox["strName"].text = blade ? "Overfiend Blade" : bossDef.name;
        }

        /** Ultra Gramiel: the target frame shows Gramiel ("boss") or the left / right Grace Crystal */
        private function selectTarget(sel:String):void
        {
            targetSel = sel;
            targetBlade = false;
            if (fight)
            {
                fight.targetSel = sel;
            }
            if (actors[role])
            {
                actors[role].follow = true; // walk next to the new target
            }
            var crystal:Boolean = sel != "boss";
            var domain:ApplicationDomain = crystal ? bossScenes[bossId].crystalDomain : bossDomain;
            setFace(targetBox["mcHead"], new (domain.getDefinition(crystal ? bossDef.crystalHead : bossDef.headClass) as Class)() as DisplayObject);
            targetBox["mcHead"].head.hair.visible = false;
            targetBox["mcHead"].head.helm.visible = false;
            targetBox["mcHead"].backhair.visible = false;
            targetBox["strName"].text = !crystal ? bossDef.name : (sel == "cl" ? "Grace Crystal (left)" : "Grace Crystal (right)");
        }

        private function buildBoss(sc:Object):void
        {
            var Boss:Class = sc.domain.getDefinition(sc.def.bossClass) as Class;
            var b:MovieClip = new Boss() as MovieClip;
            sc.boss = b;
            b.onMove = false;
            b.scaleX = (sc.def.flip ? -1 : 1) * sc.def.scale; // Drakath stands on the right and looks left
            b.scaleY = sc.def.scale;
            b.x = sc.def.pad.x;
            b.y = sc.def.pad.y + (sc.def.originDy ? sc.def.originDy : 0);
            b.mouseEnabled = false;
            b.mouseChildren = false;
            b.visible = false;
            actorLayer.addChild(b);
            if (sc.def.bladeSwf)
            {
                var Blade:Class = sc.bladeDomain.getDefinition(sc.def.bladeClass) as Class;
                var bl:MovieClip = new Blade() as MovieClip;
                sc.blade = bl;
                bl.onMove = false;
                bl.scaleX = bl.scaleY = sc.def.bladeScale;
                bl.x = sc.def.bladePad.x;
                bl.y = sc.def.bladePad.y;
                bl.mouseEnabled = false;
                bl.mouseChildren = false;
                bl.visible = false;
                actorLayer.addChild(bl);
            }
            if (sc.def.crystalSwf)
            {
                var Crystal:Class = sc.crystalDomain.getDefinition(sc.def.crystalClass) as Class;
                sc.crystals = [];
                for (var ci:int = 0; ci < 2; ci++)
                {
                    var cr:MovieClip = new Crystal() as MovieClip;
                    cr.onMove = false;
                    cr.scaleX = cr.scaleY = sc.def.crystalScale;
                    cr.x = sc.def.crystalPads[ci].x;
                    cr.y = sc.def.crystalPads[ci].y;
                    cr.mouseEnabled = false;
                    cr.mouseChildren = false;
                    cr.visible = false;
                    actorLayer.addChild(cr);
                    sc.crystals.push(cr);
                }
            }
            if (sc.def.id == "speaker")
            {
                targetRing.graphics.lineStyle(2, 0xFFD24A, 0.9);
                targetRing.graphics.drawEllipse(-120, -10, 240, 28);
                targetRing.scaleX = targetRing.scaleY = sc.def.scale / 0.3;
                // (no ring under the bosses)
            }
        }

        /** Show the map / boss / HUD portrait of a boss and make its party and rules current. */
        private function selectBoss(id:String):void
        {
            for each (var o:Object in bossScenes)
            {
                o.map.visible = false;
                o.boss.visible = false;
                if (o.blade)
                {
                    o.blade.visible = false;
                }
                for each (var oc:MovieClip in (o.crystals ? o.crystals : []))
                {
                    oc.visible = false;
                }
            }
            var sc:Object = bossScenes[id];
            bossId = id;
            bossDef = sc.def;
            roles = bossDef.roles;
            bossPad = bossDef.pad;
            homeAt = bossDef.home;
            bossLoops = bossDef.loops;
            bossDomain = sc.domain;
            mapMC = sc.map;
            mapMC.cacheAsBitmap = cacheMap; // the painted backdrop is drawn once instead of every frame
            bossMC = sc.boss;
            bladeMC = sc.blade;
            if (bladeMC)
            {
                bladeMC.visible = true;
                bladeAnim("Idle", false);
            }
            crystalMCs = sc.crystals ? sc.crystals : [];
            for (var cj:int = 0; cj < crystalMCs.length; cj++)
            {
                crystalMCs[cj].visible = true;
                crystalAnim(cj == 0 ? "cl" : "cr", "Idle", false);
            }
            if (chatField)
            {
                chatField.visible = chatHint.visible = bossId == "gramiel";
            }
            runeMC = sc.rune;
            safeMC = sc.safe;
            safe2MC = sc.safe2;
            mapMC.visible = true;
            bossMC.visible = true;
            targetRing.x = bossPad.x;
            targetRing.y = bossPad.y;
            targetRing.scaleX = targetRing.scaleY = bossId == "dage" ? 1.15 : bossDef.scale / 0.3;
            if (bossDef.classes.indexOf(role) < 0)
            {
                role = bossDef.classes[0];
            }
            // the target frame's face and name
            targetBlade = false;
            showTarget(false);
            targetSel = "boss";
            plateId = "";
            bossAnim("Idle", false);
            newFight(role);
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
            var st:Object = bossDef.stack ? bossDef.stack : STACK;
            return new Point(base.x + st[r][0], base.y + st[r][1]);
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
            for each (var r:String in roles)
            {
                var a:Object = {role: r, moveTo: null, moving: false, aaT: Math.random() * 1.3, pose: "", poseUntil: 0};
                var holder:MovieClip = new MovieClip();
                holder._avatarScaling = bossDef.charScale;
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
                var p:Point = spot(homeAt, r);
                mc.x = p.x;
                mc.y = p.y;
                mc.scale(bossDef.charScale);
                mc.pname.ti.text = ROLE_FULL[r] + (r == role ? " (you)" : "");
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
            clockText.x = 854;
            clockText.y = 54;
            g.addChild(clockText);
            nextPanel = new Sprite();
            Hud.panel(nextPanel, 0, 0, 262, 26);
            nextPanel.x = 690;
            nextPanel.y = 78;
            g.addChild(nextPanel);
            nextText = Hud.label("", 14, 0xFFFFFF, true, "left", 252);
            nextText.x = 695;
            nextText.y = 81;
            g.addChild(nextText);
            bannerText = Hud.label("", 16, 0xFFD24A, true, "center", 960);
            bannerText.x = 0;
            bannerText.y = 114;
            g.addChild(bannerText);
            shoutText = Hud.label("", 19, 0xFFD24A, true, "center", 960); // boss speech: yellow, larger
            shoutText.x = 0;
            shoutText.y = 136;
            g.addChild(shoutText);
            overText = Hud.label("", 40, 0xFFFFFF, true, "center", 960);
            overText.y = 180;
            g.addChild(overText);
            overSub = Hud.label("", 15, 0xFFFFFF, false, "center", 960);
            overSub.y = 232;
            g.addChild(overSub);
            logPanel = new Sprite();
            Hud.panel(logPanel, 0, 0, 262, 98);
            logPanel.x = 690;
            logPanel.y = 398;
            g.addChild(logPanel);
            logText = Hud.label("", 11, 0xFFFFFF, false, "left", 252);
            logText.multiline = true;
            logText.wordWrap = true;
            logText.height = 92;
            logText.x = 695;
            logText.y = 401;
            logText.autoSize = "none";
            g.addChild(logText);
            bossBuffX = targetBox.x + targetBox["HP"].x;
            playerBuffX = playerBox.x + playerBox["HP"].x;
            buildBuffIcons();
            actBar = ui("UI_ActBar");
            // centre the six round slots on the stage
            actBar.x = 0;
            actBar.x = STAGE_W / 2 - (actBar["blank0"].getBounds(actBar).left + actBar["blank5"].getBounds(actBar).right) / 2;
            actBar.y = STAGE_H - actBar["blank0"].getBounds(actBar).bottom - 6; // on the map, no black strip below
            actBar.addEventListener(MouseEvent.MOUSE_DOWN, onBarDown);
            g.addChild(actBar);
            buildButtons();
            // Ultra Gramiel: crystal HP bars and the chat field
            for (var cb:int = 0; cb < 2; cb++)
            {
                var bar:Shape = new Shape();
                bar.visible = false;
                fxLayer.addChild(bar);
                crystalBars.push(bar);
                var ctx:TextField = Hud.label("", 11, 0xFFFFFF, true, "center", 120);
                ctx.visible = false;
                fxLayer.addChild(ctx);
                crystalTexts.push(ctx);
            }
            chatHint = Hud.label("Enter = chat   1: you + SC   2: LR + LoO", 10, 0xD8DEEA, false, "left", 230);
            chatHint.x = 8;
            chatHint.y = 452;
            chatField = new TextField();
            chatField.type = TextFieldType.INPUT;
            chatField.defaultTextFormat = new TextFormat("_sans", 13, 0xFFFFFF);
            chatField.background = true;
            chatField.backgroundColor = 0x10141f;
            chatField.border = true;
            chatField.borderColor = 0x3A4560;
            chatField.maxChars = 40;
            chatField.x = 8;
            chatField.y = 470;
            chatField.width = 230;
            chatField.height = 22;
            chatField.visible = chatHint.visible = false;
            g.addChild(chatHint);
            g.addChild(chatField);
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
                {name: "ordinance", icon: "LoO2", boss: false},
                // Ultra Dage: Aeterna Nox's picture stands for all of his effects except Noxious Decay
                {name: "focus", icon: BuffTaunt, boss: true},
                {name: "cloak", icon: BuffAeternaNox, fill: true, boss: true},
                {name: "might", icon: BuffAeternaNox, fill: true, boss: true},
                {name: "legion", icon: BuffAeternaNox, fill: true, boss: true},
                {name: "blood", icon: BuffAeternaNox, fill: true, boss: true},
                {name: "siphon", icon: "Chavengea1", boss: true},
                {name: "aeterna", icon: BuffAeternaNox, fill: true, boss: false},
                {name: "decay", icon: BuffNoxiousDecay, fill: true, boss: false},
                {name: "bulwark", icon: "Chavengea3", boss: false},
                {name: "fury", icon: "Chavengea4", boss: false},
                {name: "thinair", icon: "iea1", boss: false},
                // Champion Drakath
                {name: "power", icon: BuffCog, boss: true},
                {name: "unleashed", icon: BuffCog, boss: true},
                {name: "meteor", icon: BuffCog, boss: true},
                {name: "chaos", icon: BuffCog, boss: false},
                {name: "cripple", icon: BuffCog, boss: false},
                {name: "depraved", icon: "LR3", boss: false},
                {name: "vow", icon: "PallyChA2", boss: false},
                {name: "frailty", icon: BuffCog, boss: false},
                {name: "intervention", icon: "PallyChA3", boss: false},
                {name: "wicked", icon: "LR2", boss: false},
                {name: "rift", icon: "PallyChA1", boss: false},
                {name: "angel", icon: "PallyChA3", boss: false},
                {name: "nox", icon: BuffCog, boss: true},
                {name: "reprisal", icon: "PallyChA1", boss: true},
                // Ultra Gramiel
                {name: "safeguard", icon: BuffCog, boss: true},
                {name: "invuln", icon: BuffCog, boss: true},
                {name: "vendetta", icon: BuffCog, boss: false},
                {name: "shattered", icon: BuffCog, boss: false},
                {name: "embrace", icon: "iea1", boss: false},
                {name: "scorched", icon: "ief1", boss: false},
                {name: "hot", icon: "iew1", boss: false}
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
                var ik:Number = (size * (d.fill ? 0.9 : (d.icon is String ? 0.8 : 0.64))) / Math.max(ib.width, ib.height);
                icon.scaleX = icon.scaleY = ik;
                icon.x = size / 2 - (ib.x + ib.width / 2) * ik;
                icon.y = size / 2 - (ib.y + ib.height / 2) * ik;
                slot.addChild(icon);
                var ov:Shape = new Shape();
                ov.x = size / 2;
                ov.y = size / 2;
                slot.addChild(ov);
                var cnt:TextField = Hud.label("", d.boss ? 10 : 9, 0xFFFFFF, true, "right", size);
                cnt.x = 0;
                cnt.y = size - (d.boss ? 15 : 14);
                slot.addChild(cnt);
                slot.mouseEnabled = false;
                slot.mouseChildren = false;
                slot.visible = false;
                hudLayer.addChild(slot);
                buffIcons[d.name] = {sp: slot, cnt: cnt, ov: ov, size: size, boss: d.boss};
            }
        }

        /** Lay out the active effects in a row; `count` is the little number in the corner. */
        private function showBuffs(active:Array):void
        {
            for each (var b:Object in buffIcons)
            {
                b.sp.visible = false;
            }
            var bossN:int = 0;
            var meN:int = 0;
            for each (var a:Object in active)
            {
                var ic:Object = buffIcons[a.name];
                ic.cnt.text = a.count;
                Hud.pie(ic.ov, ic.size * 0.46, a.frac >= 0 ? a.frac : 0); // dark overlay clears clockwise as it runs out
                ic.sp.visible = true;
                var n:int = ic.boss ? bossN++ : meN++;
                var col:int = n % BUFFS_PER_ROW;
                var row:int = int(n / BUFFS_PER_ROW);
                if (ic.boss)
                {
                    ic.sp.x = bossBuffX + col * (ic.size + 4); // directly under the boss' bars
                    ic.sp.y = 76 + row * (ic.size + 4);
                }
                else
                {
                    ic.sp.x = playerBuffX + col * (ic.size + 3); // directly under our bars
                    ic.sp.y = 86 + row * (ic.size + 3);
                }
            }
            // a second row of our effects pushes the party frames down so nothing overlaps
            var extra:Number = Math.max(0, int((meN + BUFFS_PER_ROW - 1) / BUFFS_PER_ROW) - 1) * 26;
            for each (var pp:MovieClip in partyPanels)
            {
                pp.y = pp.baseY + extra;
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
            for each (var r:String in roles)
            {
                if (r == role)
                {
                    continue;
                }
                var p:MovieClip = ui("UI_PartyPanel");
                p.x = 10;
                p.y = y;
                p.baseY = y;
                p["strName"].text = ROLE_FULL[r];
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
            button("Restart", 676, 4, 70, function():void { newFight(role); showStartScreen(); });
            button("Auto-pilot", 750, 4, 90, function():void { botOn = !botOn; });
            button("Pause", 844, 4, 110, function():void { paused = !paused; });
            hintsLabel = button("", 676, 28, 150, toggleHints);
            hintsLabel.text = "Hints: " + (hintsOn ? "ON" : "OFF") + " (H)";
            button("Fullscreen (F)", 836, 28, 118, toggleFullscreen);
        }

        private static const TAB_W:Number = 172;
        private static const CARD_ICON:Object = {loo: "LoOaa", ap: "apal1", lr: "LRaa", ca: "Chavengeaa", cn: "iwd1", pc: "PallyChAA", sh: "iwd1"};

        /** Boss + class selection and Play; the fight sits paused (and untouched) behind it until Play is pressed. */
        private function showStartScreen():void
        {
            if (startScreen && startScreen.parent)
            {
                return;
            }
            paused = true;
            startScreen = new Sprite();
            startScreen.graphics.beginFill(0x05070d, 0.84);
            startScreen.graphics.drawRect(0, 0, STAGE_W, STAGE_H);
            startScreen.graphics.endFill();
            var title:TextField = Hud.label(bossDef.name, 44, 0xFFD24A, true, "center", STAGE_W);
            title.y = 36;
            startScreen.addChild(title);
            for (var bi:int = 0; bi < BOSSES.length; bi++)
            {
                var bd:Object = BOSSES[bi];
                var sel:Boolean = bd.id == bossId;
                var bt:Sprite = new Sprite();
                bt.graphics.lineStyle(sel ? 2 : 1, sel ? 0xFFD24A : 0x3A4560, 1);
                bt.graphics.beginFill(sel ? 0x1d2433 : 0x10141f, 0.95);
                bt.graphics.drawRoundRect(0, 0, TAB_W, 30, 8, 8);
                bt.graphics.endFill();
                var bl:TextField = Hud.label(bd.name, 13, sel ? 0xFFFFFF : 0x9BA6BD, true, "center", TAB_W);
                bl.y = 4;
                bt.addChild(bl);
                bt.x = (STAGE_W - (BOSSES.length * TAB_W + (BOSSES.length - 1) * 10)) / 2 + bi * (TAB_W + 10);
                bt.y = 98;
                bt.buttonMode = true;
                bt.addEventListener(MouseEvent.MOUSE_DOWN, makeBossHandler(bd.id));
                startScreen.addChild(bt);
            }
            var sub:TextField = Hud.label("Select your class", 18, 0xFFFFFF, false, "center", STAGE_W);
            sub.y = 134;
            startScreen.addChild(sub);
            var classes:Array = bossDef.classes;
            cards = {};
            var x0:Number = (STAGE_W - (classes.length * 200 + (classes.length - 1) * 20)) / 2;
            for (var i:int = 0; i < classes.length; i++)
            {
                var card:Sprite = new Sprite();
                card.x = x0 + i * 220;
                card.y = 166;
                card.buttonMode = true;
                var cr:String = classes[i];
                var C:Class = assetsDomain.getDefinition(CARD_ICON[cr]) as Class;
                var icon:DisplayObject = new C() as DisplayObject;
                var ib:Rectangle = icon.getBounds(icon);
                var k:Number = 76 / Math.max(ib.width, ib.height);
                icon.scaleX = icon.scaleY = k;
                icon.x = 100 - (ib.x + ib.width / 2) * k;
                icon.y = 58 - (ib.y + ib.height / 2) * k;
                card.addChild(icon);
                var nm:TextField = Hud.label(CLASS_NAMES[cr], 16, 0xFFFFFF, true, "center", 200);
                nm.y = 106;
                card.addChild(nm);
                card.addEventListener(MouseEvent.MOUSE_DOWN, makeCardHandler(cr));
                startScreen.addChild(card);
                cards[cr] = card;
            }
            var play:Sprite = new Sprite();
            play.graphics.beginFill(0xE0B84A, 1);
            play.graphics.drawRoundRect(0, 0, 220, 52, 12, 12);
            play.graphics.endFill();
            var pt:TextField = Hud.label("Play", 26, 0x15110a, true, "center", 220);
            pt.y = 9;
            play.addChild(pt);
            play.x = (STAGE_W - 220) / 2;
            play.y = 350;
            play.buttonMode = true;
            play.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void {
                e.stopPropagation();
                playGame();
            });
            startScreen.addChild(play);
            var help:TextField = Hud.label("Left-click: move / target the boss  |  1-6: skills  |  H: hints  |  F: fullscreen", 12, 0x9BA6BD, false, "center", STAGE_W);
            help.y = 424;
            startScreen.addChild(help);
            startScreen.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
            addChild(startScreen);
            markCard();
        }

        private function makeBossHandler(id:String):Function
        {
            return function(e:MouseEvent):void {
                e.stopPropagation();
                if (id != bossId)
                {
                    removeChild(startScreen);
                    selectBoss(id); // swaps map, boss, party and class list while the screen is down
                    showStartScreen();
                }
            };
        }

        private function makeCardHandler(r:String):Function
        {
            return function(e:MouseEvent):void {
                e.stopPropagation();
                if (r != role)
                {
                    newFight(r); // rebuilds the party with this class and equips the gear while the screen is up
                }
                markCard();
            };
        }

        private function markCard():void
        {
            for (var r:String in cards)
            {
                var c:Sprite = cards[r];
                c.graphics.clear();
                c.graphics.lineStyle(r == role ? 3 : 1, r == role ? 0xFFD24A : 0x3A4560, 1);
                c.graphics.beginFill(r == role ? 0x1d2433 : 0x10141f, 0.95);
                c.graphics.drawRoundRect(0, 0, 200, 140, 12, 12);
                c.graphics.endFill();
            }
        }

        private function playGame():void
        {
            if (startScreen && startScreen.parent)
            {
                removeChild(startScreen);
            }
            paused = false;
            lastTime = getTimer();
            refocus(); // the Play button the focus was on is gone: without this the keys 1-6 do nothing until the next click on the map
        }

        private function sendChat():void
        {
            var text:String = chatField.text.replace(/^\s+|\s+$/g, "");
            chatField.text = "";
            refocus();
            if (text == "" || fight.over || !fight.started)
            {
                return;
            }
            say(role, text);
            fight.chat(text);
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
                    var k:Number = (b.width * (role == "sh" ? 0.58 : 0.86)) / Math.max(ib.width, ib.height);
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
                    cdt.mouseEnabled = false; // the countdown sits on top of the slot, clicks must go through it
                    actBar.setChildIndex(cdt, actBar.numChildren - 1);
                }
                slot.buttonMode = true;
                skillSlots.push({sp: slot, cd: cd, txt: cdt, icon: icon, key: key, r: b.width / 2});
            }
        }

        /** a click on a skill slot uses the skill (the slot under the mouse, whatever is drawn on top of it) */
        private function onBarDown(e:MouseEvent):void
        {
            refocus();
            if (startScreen && startScreen.parent)
            {
                return;
            }
            for (var i:int = 0; i < skillSlots.length; i++)
            {
                if (skillSlots[i].sp.getBounds(stage).contains(stage.mouseX, stage.mouseY))
                {
                    e.stopPropagation(); // not a walk click
                    castKey(i + 1);
                    return;
                }
            }
        }

        // ================================================================ fight lifecycle
        private function newFight(r:String):void
        {
            role = r;
            if (bossId == "dage")
            {
                fight = new DageFight(this, role, 6500000, [26000, 34000]);
            }
            else if (bossId == "drakath")
            {
                fight = new DrakathFight(this, role, 20000000, [70000, 90000]);
            }
            else if (bossId == "nulgath")
            {
                fight = new NulgathFight(this, role, 10000000, [0, 0]);
            }
            else if (bossId == "gramiel")
            {
                fight = new GramielFight(this, role, 7500000, [0, 0]);
                if (loaderInfo.parameters["p2"] == "1")
                {
                    (fight as GramielFight).crystalHp = {cl: 3, cr: 3}; // for tests: skip most of Phase 1
                }
                targetSel = fight.targetSel;
                selectTarget(targetSel);
                for each (var bb:Object in bubbles)
                {
                    if (bb.sp.parent)
                    {
                        bb.sp.parent.removeChild(bb.sp);
                    }
                }
                bubbles = {};
                for (var ci:int = 0; ci < crystalMCs.length; ci++)
                {
                    crystalMCs[ci].x = bossDef.crystalPads[ci].x;
                    crystalMCs[ci].y = bossDef.crystalPads[ci].y;
                    crystalAnim(ci == 0 ? "cl" : "cr", "Idle", false);
                }
            }
            else
            {
                fight = new Fight(this, role, 10000000, [42000, 52000]);
            }
            zoneRole = "";
            plateId = "";
            stamina = 100;
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
            if (safe2MC)
            {
                safe2MC.gotoAndStop("off");
            }
            bossMC.x = bossPad.x;
            bossMC.y = bossPad.y + (bossDef.originDy ? bossDef.originDy : 0); // the clip's origin is below its feet
            bossAnim("Idle", false);
            buildActors();
            if (bossId == "gramiel")
            {
                actors[role].follow = true;
                for each (var sr:String in roles)
                {
                    var sp0:Point = gramielStation(sr, (fight as GramielFight).targetOf(sr));
                    actors[sr].mc.x = sp0.x;
                    actors[sr].mc.y = sp0.y;
                    face(actors[sr], gramielDir(sr));
                }
            }
            startTime = getTimer();
            buildParty();
            buildSkillbar();
            portraitAt = 0;
            log("Engaged " + bossDef.name + " as " + CLASS_NAMES[role], "");
        }

        // ---------------------------------------------------------------- IFightHost
        public function bladeAnim(label:String, loop:Boolean):void
        {
            if (bladeMC)
            {
                if (label == "Idle")
                {
                    bladeMC.gotoAndStop(label);
                }
                else
                {
                    bladeMC.gotoAndPlay(label);
                }
            }
        }

        public function crystalAnim(side:String, label:String, loop:Boolean):void
        {
            var i:int = side == "cl" ? 0 : 1;
            if (i >= crystalMCs.length)
            {
                return;
            }
            crystalLabel[i] = label;
            crystalLoop[i] = loop;
            if (label == "Idle")
            {
                crystalMCs[i].gotoAndStop(label);
            }
            else
            {
                crystalMCs[i].gotoAndPlay(label);
            }
        }

        /** a chat line over the character's head (and in the log) */
        public function say(r:String, text:String):void
        {
            log(ROLE_FULL[r] + ": " + text, "");
            if (!actors[r])
            {
                return;
            }
            var old:Object = bubbles[r];
            if (old && old.sp.parent)
            {
                old.sp.parent.removeChild(old.sp);
            }
            var sp:Sprite = new Sprite();
            var tf:TextField = Hud.label(text, 12, 0x15110a, true);
            tf.x = 6;
            tf.y = 3;
            sp.graphics.beginFill(0xFFF3C4, 0.95);
            sp.graphics.lineStyle(1, 0x3A2F14, 1);
            sp.graphics.drawRoundRect(0, 0, tf.width + 12, 22, 8, 8);
            sp.graphics.endFill();
            sp.addChild(tf);
            sp.mouseEnabled = false;
            sp.mouseChildren = false;
            fxLayer.addChild(sp);
            bubbles[r] = {sp: sp, until: getTimer() + 3200, w: tf.width + 12};
        }

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
                if (bossDef.idleStop && (label == "Idle" || label == "FIdle"))
                {
                    bossMC.gotoAndStop(label); // Ruffle runs on from the Idle label into Walk; he would jog on the spot
                }
                else
                {
                    bossMC.gotoAndPlay(label);
                }
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
                setBanner(mine ? "EQUAL - zone " + zoneNumber(r) + ": STAND INSIDE THE BOX" : "EQUAL - " + ROLE_FULL[r] + " inside; step OUTSIDE the box (right)", mine ? 0x6FD98A : 0xFFD24A, 3400);
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

        /** Ultra Dage: the lit plate. The boss walks onto the rune while it charges, like the map's own script does. */
        public function plate(id:String):void
        {
            plateId = id;
            if (safeMC)
            {
                safeMC.gotoAndStop(id == "a" ? "on" : "off");
            }
            if (safe2MC)
            {
                safe2MC.gotoAndStop(id == "b" ? "on" : "off");
            }
            if (runeMC)
            {
                runeMC.gotoAndStop(id != "" ? "on" : "off");
            }
            if (id != "")
            {
                setBanner("PLATE LIT - run to the glowing plate (" + (id == "a" ? "left" : "right") + ")", 0xFFD24A, 3000);
            }
        }

        private function plateRect(id:String):Rectangle
        {
            var clip:MovieClip = id == "a" ? safeMC : safe2MC;
            if (clip == null)
            {
                return new Rectangle(0, 0, 0, 0);
            }
            var b:Rectangle = clip.getBounds(mapHolder);
            b.inflate(-b.width * 0.1, 0);
            b.y -= 20; // the characters' feet stand a little below the plate's edge
            b.height += 50;
            return b;
        }

        public function roleOnPlate(r:String, id:String):Boolean
        {
            var mc:AvatarMC = actors[r].mc;
            return plateRect(id).contains(mc.x, mc.y);
        }

        private function plateSpot(r:String, id:String):Point
        {
            var b:Rectangle = plateRect(id);
            var st:Array = STACK[r];
            return new Point(b.x + b.width / 2 + st[0] * 3, b.y + b.height / 2 + st[1] * 2);
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
                y = actors[r].mc.y - 108 * bossDef.charScale / 0.65;
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
            if (glowText)
            {
                ti.filters = [new GlowFilter(glow, 1, 5, 5, 5, 1, false, false)];
            }
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
            while (logLines.length > 80)
            {
                logLines.shift();
            }
            logText.text = logLines.join("\n");
            logText.scrollV = logText.maxScrollV; // keep the newest line in view
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
            // the sparkle is the healing effect: it plays only when the player casts a heal themselves, on everyone it heals
            if ((kind == "ordinance" || kind == "heal") && r == role)
            {
                var C:Class = assetsDomain.getDefinition("Assets_20260702_fla.Symbol3aaaaa_loo_757") as Class;
                for each (var who:String in roles)
                {
                    var clip:MovieClip = new C() as MovieClip;
                    clip.mouseEnabled = false;
                    clip.x = actors[who].mc.x;
                    clip.y = actors[who].mc.y - 50 * bossDef.charScale / 0.65;
                    fxLayer.addChild(clip);
                    fxClips.push(clip);
                }
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
            showNumber(bossPad.x + (Math.random() - 0.5) * 200, bossPad.y - 150 - Math.random() * 60, String(amount), crit ? "crit" : "hit");
        }

        public function mechanic(holder:String, ability:String, truthN:int, zoneN:int):void
        {
            if (bossId == "nulgath")
            {
                // truthN: 1.. = which Behold (Legion Revenant) / seconds into the fight (Lord of Order)
                setBanner(ability == "behold" ? "TAUNT NOW (6) - \"Behold the power of the Abyss!\"" : "TAUNT NOW (6) - Contract of the Abyss (" + (truthN == 5 ? "5 s into the fight" : "your debuff wears off") + ")", 0xFF5B5B, 3000);
                if (botOn)
                {
                    botQueue.push({at: fight.t, until: fight.t + 3000, k: 6});
                }
                return;
            }
            if (bossId == "gramiel")
            {
                gramielCue(ability, truthN, zoneN);
                return;
            }
            if (bossId == "drakath")
            {
                // the boss is about to reach one of the player's taunt thresholds (truthN = millions of HP)
                setBanner("TAUNT NOW (6) - before " + truthN + "M HP", 0xFF5B5B, 3200);
                if (botOn)
                {
                    botQueue.push({at: fight.t, until: fight.t + 3000, k: 6});
                }
                return;
            }
            if (bossId == "dage")
            {
                // cue from the fight: the tauntable attack is about to land, Flux (3) is the Chaos Avenger's taunt
                if (role == "ca")
                {
                    setBanner(ability == "regen" ? "TAUNT NOW - Flux (3) before the Legion Mages land" : (ability == "intro" ? "TAUNT NOW - Flux (3) the 2nd auto attack" : "TAUNT NOW - Flux (3) the next auto attack"), 0xFF5B5B, 2400);
                }
                if (botOn && role == "ca")
                {
                    botQueue.push({at: fight.t + 250, until: fight.t + 1800, k: 3});
                }
                return;
            }
            var label:String = ability == "truth" ? "Truth" : (ability == "listen" ? "Listen" : "");
            var mine:Boolean = (holder == role);
            if (holder != null && label != "")
            {
                setBanner(mine ? "TAUNT NOW - " + label + " on YOU (6)" : ROLE_FULL[holder] + " holds the boss - " + label, mine ? 0xFF5B5B : 0xFFD24A, 2400);
            }
            if (ability == "truth")
            {
                var n:int = ((truthN - 1) % 9) + 1;
                var needSeal:Boolean = Fight.truthNeedsSeal(truthN);
                if (role == "loo" && (n == 5 || n == 9))
                {
                    setBanner("QUIX NOW - Truth #" + n + " (5)" + (mine ? " + TAUNT (6)" : ""), 0xFF5B5B, 2400);
                }
                else if (role == "ap" && needSeal && n != 2 && n != 6) // the Truths after the DPS and AP zones are sealed at the zone
                {
                    setBanner("SEAL NOW (4) - Truth #" + truthN + (mine ? " + TAUNT (6)" : ""), 0xFF5B5B, 2400);
                }
            }
            else if (ability == "zone" && role == "ap" && (zoneN == 1 || zoneN == 3))
            {
                setBanner("SEAL NOW (4) - it covers the Truth that follows this zone", 0xFF5B5B, 3000);
            }
            if (botOn)
            {
                botReact(holder, ability, truthN, zoneN);
            }
        }

        /** Ultra Gramiel: the cues of the fight (banner text and, on auto-pilot, the player's answer) */
        private function gramielCue(ability:String, n:int, extra:int):void
        {
            var t:Number = fight.t;
            var gf:GramielFight = fight as GramielFight;
            switch (ability)
            {
                case "charge":
                    setBanner(n == 1 ? "CRYSTAL CHARGE - type 1 (Enter) and TAUNT (6) the RIGHT crystal" : "CRYSTAL CHARGE - type 2 (Enter): Legion Revenant + Lord of Order taunt", 0xFF5B5B, 3800);
                    if (botOn)
                    {
                        if (n == 1)
                        {
                            botQueue.push({at: t + 300, target: "cr"});
                            botQueue.push({at: t + 400, chat: "1"});
                            botQueue.push({at: t + 900, until: t + 3000, k: 6});
                        }
                        else
                        {
                            botQueue.push({at: t + 600, chat: "2"});
                        }
                    }
                    break;
                case "drain":
                    setBanner("GRACE DRAIN - click Gramiel and attack him until his shield breaks", 0xFF5B5B, 4800);
                    if (botOn)
                    {
                        botQueue.push({at: t + 450, target: "boss"});
                    }
                    break;
                case "unstable":
                    setBanner("CRYSTAL UNSTABLE - destroy the other crystal within 5 s!", 0xFF5B5B, 4800);
                    break;
                case "p2start":
                    setBanner("TAUNT GRAMIEL (6) now - then pass it on after two hits", 0xFF5B5B, 3600);
                    if (botOn)
                    {
                        botQueue.push({at: t + 400, until: t + 3000, k: 6});
                    }
                    break;
                case "pass":
                    var nr:String = GramielFight.nextInOrder(gf.holder);
                    setBanner(nr == "sh" ? "TAUNT (6) yourself now" : "Two hits taken - type " + (nr == "loo" ? "LOO" : (nr == "sc" ? "SC" : "LR")) + " (Enter)", 0xFF5B5B, 3600);
                    if (botOn)
                    {
                        if (nr == "sh")
                        {
                            botQueue.push({at: t + 300, until: t + 3000, k: 6});
                        }
                        else
                        {
                            botQueue.push({at: t + 300, chat: nr == "loo" ? "LOO" : (nr == "sc" ? "SC" : "LR")});
                        }
                    }
                    break;
                case "vanquish":
                    setBanner("Celestial Vanquish - everybody needs a Vendetta stack; taunt again when it fades", 0xFFD24A, 4800);
                    break;
            }
        }

        public function ended(result:String, reason:String):void
        {
            if (result == "win")
            {
                if (bossId == "gramiel")
                {
                    for (var ci:int = 0; ci < crystalMCs.length; ci++)
                    {
                        crystalAnim(ci == 0 ? "cl" : "cr", "Die", false);
                    }
                }
                bossMC.gotoAndPlay(bossId == "drakath" && DrakathFight(fight).phase == 2 ? "FDie" : "Die");
                log("Victory - " + reason, "good");
            }
            else
            {
                log("Defeat - " + reason, "bad");
            }
            overText.text = result == "win" ? "VICTORY" : "DEFEATED";
            overText.textColor = result == "win" ? 0x6FD98A : 0xFF5B5B;
            overSub.text = reason + " - press Restart";
            var f:Fight = fight;
            setTimeout(function():void {
                if (fight === f) // not already restarted by hand
                {
                    newFight(role);
                    showStartScreen();
                }
            }, RETURN_MS);
        }

        public function showBanner(text:String, alert:Boolean, ms:Number):void
        {
            setBanner(text, alert ? 0xFF5B5B : 0xFFD24A, ms);
        }

        private function setBanner(text:String, color:uint, ms:Number):void
        {
            banner = text;
            bannerColor = color;
            bannerUntil = fight.t + ms;
        }

        // ===================================================================== input
        /** keep the keyboard focus on the stage so the keys always reach onKeyDown */
        private function refocus():void
        {
            try
            {
                stage.focus = stage;
            }
            catch (err:Error)
            {
            }
        }

        private function onMouseDown(e:MouseEvent):void
        {
            if (chatField && e.target == chatField)
            {
                return; // a click in the chat field keeps its focus
            }
            refocus();
            if (!ready || fight.over || (startScreen && startScreen.parent))
            {
                return;
            }
            var a:Object = actors[role];
            var mx:Number = stage.mouseX;
            var my:Number = stage.mouseY;
            if (bossId == "gramiel")
            {
                for (var ci:int = 0; ci < crystalMCs.length; ci++)
                {
                    var cm:MovieClip = crystalMCs[ci];
                    if (cm.hitTestPoint(mx, my, true) || (Math.abs(mx - cm.x) <= 46 && my >= cm.y - 150 * bossDef.crystalScale && my <= cm.y + 20))
                    {
                        selectTarget(ci == 0 ? "cl" : "cr");
                        return;
                    }
                }
                if (bossMC.hitTestPoint(mx, my, true) || (Math.abs(mx - bossPad.x) <= 110 && my >= 40 && my <= bossPad.y + 30))
                {
                    selectTarget("boss");
                    return;
                }
                beginWalk(a, new Point(clamp(stage.mouseX, WALK.x0, WALK.x1), clamp(stage.mouseY, WALK.y0, WALK.y1)));
                return;
            }
            // the wings' pixels, or the boss' body column (the clip is mostly glow and gaps)
            if (bladeMC && bladeMC.visible && bladeMC.hitTestPoint(mx, my, true))
            {
                showTarget(true); // not attacked, only a target for Quix
                return;
            }
            if (bossMC.hitTestPoint(mx, my, true) || (Math.abs(mx - bossPad.x) <= 150 && my >= 40 && my <= bossPad.y + 30))
            {
                if (targetBlade)
                {
                    showTarget(false);
                }
                moveToBoss(); // click the boss: target it and walk into range
                return;
            }
            beginWalk(a, new Point(clamp(stage.mouseX, WALK.x0, WALK.x1), clamp(stage.mouseY, WALK.y0, WALK.y1)));
        }

        private function onKeyDown(e:KeyboardEvent):void
        {
            if (startScreen && startScreen.parent)
            {
                if (e.keyCode == 13) // Enter = Play
                {
                    playGame();
                }
                return;
            }
            if (chatField && stage.focus == chatField)
            {
                if (e.keyCode == 13)
                {
                    sendChat();
                }
                else if (e.keyCode == 27)
                {
                    chatField.text = "";
                    refocus();
                }
                return; // typing: no skill / move keys
            }
            if (e.keyCode == 13 && chatField && chatField.visible)
            {
                stage.focus = chatField;
                return;
            }
            if (e.keyCode == 9 && bossId == "gramiel")
            {
                var order:Array = ["cl", "cr", "boss"];
                selectTarget(order[(order.indexOf(targetSel) + 1) % 3]);
                return;
            }
            if (e.keyCode == 32)
            {
                spaceHeld = true;
                return;
            }
            var k:int = e.keyCode - 48; // keys 1-6 (the number row)
            if (e.keyCode >= 97 && e.keyCode <= 102)
            {
                k = e.keyCode - 96; // ... and the numeric keypad
            }
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

        /** the player's clicks: with Space held and enough stamina the walk is a sprint */
        private function beginWalk(a:Object, to:Point):void
        {
            a.moveTo = to;
            a.follow = false;
            a.sprint = false;
            if (spaceHeld && stamina >= SPRINT_COST)
            {
                stamina -= SPRINT_COST;
                a.sprint = true;
            }
        }

        private function onKeyUp(e:KeyboardEvent):void
        {
            if (e.keyCode == 32)
            {
                spaceHeld = false;
            }
        }

        private function moveToBoss():void
        {
            targeted = true;
            if (bossId == "gramiel")
            {
                actors[role].follow = true; // walk next to the current target (crystal or Gramiel)
                return;
            }
            if (targetBlade && bladeMC)
            {
                beginWalk(actors[role], new Point(clamp(bossDef.bladePad.x + 90, WALK.x0, WALK.x1), clamp(bossDef.bladePad.y + 10, WALK.y0, WALK.y1)));
                return;
            }
            beginWalk(actors[role], new Point(clamp(bossPad.x - 90, WALK.x0, WALK.x1), clamp(bossPad.y + 70, WALK.y0, WALK.y1)));
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
            fight.targetIsBlade = targetBlade;
            fight.targetSel = targetSel;
            return fight.cast(k);
        }

        private static function clamp(v:Number, a:Number, b:Number):Number
        {
            return Math.max(a, Math.min(b, v));
        }

        // ===================================================================== update
        private var frameCount:int = 0;

        private function onFrame(e:Event):void
        {
            frameCount++;
            if (targetBlade && fight.started)
            {
                showTarget(false); // after the opening Quix the target is Nulgath again
            }
            if (bossId == "gramiel")
            {
                var gf:GramielFight = fight as GramielFight;
                if (gf.phase != 1 && targetSel != "boss")
                {
                    selectTarget("boss"); // the crystals are gone
                }
                else if (gf.phase == 1 && targetSel != "boss" && gf.crystalHp[targetSel] <= 0)
                {
                    selectTarget(targetSel == "cl" ? "cr" : "cl"); // the destroyed crystal is no target any more
                }
            }
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
            for each (var r:String in roles)
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
                if (bossId == "gramiel")
                {
                    goal = f.over ? null : ((isMe && !a.follow) ? a.moveTo : gramielStation(r, (f as GramielFight).targetOf(r)));
                }
                else if (isMe)
                {
                    goal = f.over ? null : a.moveTo;
                }
                else if (plateId != "")
                {
                    goal = plateSpot(r, plateId); // everybody runs to the lit plate and back
                }
                else if (zoneRole != "")
                {
                    goal = zoneRole == r ? homeAt : spot(RIGHT_AT, r);
                }
                else
                {
                    goal = spot(homeAt, r);
                }
                stepActor(a, goal, dt, isMe ? (a.sprint ? SPRINT_SPEED : WALK_SPEED) : 300);
                if (isMe)
                {
                    if (!a.moving)
                    {
                        stamina = Math.min(100, stamina + STAMINA_REGEN * dt);
                        a.sprint = false;
                    }
                }
                // swing at the boss when standing still near it
                a.aaT -= dt;
                var near:Boolean = bossId == "gramiel" ? inPlace(r) : (Math.abs(bossPad.x - mc.x) <= 260 && Math.abs(bossPad.y - mc.y) <= 130);
                if (bossId == "gramiel" && near)
                {
                    face(a, gramielDir(r)); // standing next to its target, facing it
                }
                if (!a.moving && near && a.aaT <= 0 && !f.over && f.started && (!isMe || targeted))
                {
                    a.aaT = isMe ? f.swingEvery() : 1.33;
                    face(a, bossId == "gramiel" ? gramielDir(r) : (bossPad.x >= mc.x ? 1 : -1));
                    pose(a, isMe ? "RifleAttack" : "Attack1", 0.7);
                    if (isMe && !f.stunned())
                    {
                        var sw:Object = f.swing();
                        f.playerHit(sw.dmg, sw.crit);
                    }
                }
                else if (!a.moving && a.poseUntil < getTimer() / 1000)
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
            if (a.pose == label && a.poseUntil > getTimer() / 1000)
            {
                return;
            }
            a.pose = label;
            a.poseUntil = getTimer() / 1000 + seconds;
            a.mc.mcChar.gotoAndPlay(label);
        }

        private function updateBoss():void
        {
            // ChargeALoop ends on a stop(): restart it so the charge keeps animating
            if (bossLoop && bossLoops[bossLabel] && bossMC.currentFrame >= bossLoops[bossLabel][1])
            {
                bossMC.gotoAndPlay(bossLabel);
            }
            for (var ci:int = 0; ci < crystalMCs.length; ci++)
            {
                var cl:Object = bossDef.crystalLoops;
                if (crystalLoop[ci] && cl[crystalLabel[ci]] && crystalMCs[ci].currentFrame >= cl[crystalLabel[ci]][1])
                {
                    crystalMCs[ci].gotoAndPlay(crystalLabel[ci]);
                }
            }
            targetRing.visible = false; // no circle under the bosses
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
            var list:Array = [{y: bossPad.y, o: bossMC}];
            if (bladeMC)
            {
                list.push({y: bossDef.bladePad.y, o: bladeMC});
            }
            for (var ci:int = 0; ci < crystalMCs.length; ci++)
            {
                list.push({y: crystalMCs[ci].y, o: crystalMCs[ci]});
            }
            for each (var r:String in roles)
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
            setBar(playerBox, "MP", "intMPbar", "strIntMP", f.mana / 100, String(Math.round(f.mana)));
            setBar(playerBox, "SP", "intSPbar", "strIntSP", stamina / 100, String(Math.round(stamina)));
            if (targetBlade)
            {
                setBar(targetBox, "HP", "intHPbar", "strIntHP", 1, "1,000,000"); // the Overfiend Blade (1 000 000 HP) is never attacked
            }
            else if (bossId == "gramiel" && targetSel == "boss" && (f as GramielFight).draining)
            {
                var sh:int = (f as GramielFight).shield;
                setBar(targetBox, "HP", "intHPbar", "strIntHP", sh / 20, "Safeguard " + sh + "/20");
            }
            else if (bossId == "gramiel" && targetSel != "boss")
            {
                var gh:Number = (f as GramielFight).crystalHp[targetSel];
                setBar(targetBox, "HP", "intHPbar", "strIntHP", gh / 400, String(gh));
            }
            else
            {
                setBar(targetBox, "HP", "intHPbar", "strIntHP", f.bossHp / f.bossMaxHp, Fight.fmt(f.bossHp));
            }
            setBar(targetBox, "MP", "intMPbar", "strIntMP", 1, "100");
            for (var r:String in partyPanels)
            {
                setBar(partyPanels[r], "HP", "intHPbar", "strIntHP", f.hp[r] / f.maxHp(r), Fight.fmt(f.hp[r]));
                setBar(partyPanels[r], "MP", "intMPbar", "strIntMP", 1, "");
                var sm:int = f.somber[r];
                partyPanels[r]["strName"].text = ROLE_FULL[r] + (sm > 0 ? "  x" + sm : "");
            }
            // buff chips
            var chips:Array = [];
            var t:Number = f.t;
            var active:Array = [];
            var remain:Function = function(until:Number):String { return String(Math.ceil((until - t) / 1000)); };
            var frac:Function = function(until:Number, total:Number):Number { return Math.max(0, Math.min(1, (until - t) / total)); };
            var custom:Array = f.activeBuffs();
            var dage:Fight = custom != null ? f : null; // Dage / Drakath build their own effect list
            if (custom != null)
            {
                active = custom;
            }
            // on the boss
            if (dage == null && f.currentTaunt() != null)
            {
                active.push({name: "taunt", count: "", frac: frac(f.tauntUntil, 6000)});
            }
            if (dage == null && f.apReduction == "seal")
            {
                active.push({name: "seal", count: remain(f.apReductionUntil), frac: frac(f.apReductionUntil, 7000)});
            }
            else if (dage == null && f.apReduction == "eden")
            {
                active.push({name: "eden", count: remain(f.apReductionUntil), frac: frac(f.apReductionUntil, 25000)});
            }
            if (dage == null && t < f.quixUntil)
            {
                active.push({name: "quix", count: remain(f.quixUntil), frac: frac(f.quixUntil, 4000)});
            }
            // on us
            if (dage == null && f.stunned())
            {
                active.push({name: "stasis", count: remain(f.stunUntil), frac: frac(f.stunUntil, 6000)});
            }
            if (dage == null && f.somber[role] > 0)
            {
                active.push({name: "somber", count: String(f.somber[role]), frac: -1}); // stacks, no timer
            }
            if (dage == null && t < f.magiaBurnUntil)
            {
                active.push({name: "magiaBurn", count: remain(f.magiaBurnUntil), frac: frac(f.magiaBurnUntil, 18000)});
            }
            if (dage == null && role == "lr" && t < f.lrEmpowerUntil)
            {
                active.push({name: "empowerment", count: remain(f.lrEmpowerUntil), frac: frac(f.lrEmpowerUntil, 12000)});
            }
            if (dage == null && f.apHealBuff)
            {
                active.push({name: "heal", count: remain(f.apHealUntil), frac: frac(f.apHealUntil, 15000)});
            }
            if (dage == null && f.harmonyBuff)
            {
                active.push({name: "harmony", count: remain(f.harmonyUntil), frac: frac(f.harmonyUntil, 10000)});
            }
            if (dage == null && t < f.axiomUntil)
            {
                active.push({name: "axiom", count: remain(f.axiomUntil), frac: frac(f.axiomUntil, 10000)});
            }
            if (dage == null && t < f.ordinanceUntil)
            {
                active.push({name: "ordinance", count: remain(f.ordinanceUntil), frac: frac(f.ordinanceUntil, 12000)});
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
            nextText.text = hintsOn ? "Next: " + f.nextLabel() : "";
            nextText.visible = hintsOn;
            nextPanel.visible = hintsOn;
            logText.visible = hintsOn;
            logPanel.visible = hintsOn;
            bannerText.text = (hintsOn && banner != "" && f.t < bannerUntil) ? banner : "";
            if (!f.started && hintsOn)
            {
                bannerText.text = f.startHint();
            }
            bannerText.textColor = bannerColor;
            shoutText.text = (shout != "" && f.t < shoutUntil) ? shout : "";
            // skill cooldowns on the action bar
            for (var s:int = 0; s < skillSlots.length; s++)
            {
                var slot:Object = skillSlots[s];
                var k:int = s + 1;
                var name:String = f.skillName(k);
                var left:Number = k == 1 ? 0 : Math.max(0, f.cd[k] - f.t);
                var len:Number = name != null ? f.skillCdMs(name) : 1;
                // dark overlay that clears clockwise as the skill comes off cooldown
                Hud.pie(slot.cd, slot.r * 0.92, left > 0 ? Math.min(1, left / Math.max(len, left)) : 0);
                if (slot.txt)
                {
                    slot.txt.text = left > 50 ? (left / 1000).toFixed(left > 9950 ? 0 : 1) : "";
                }
                slot.icon.alpha = f.stunned() && k >= 2 ? 0.5 : 1;
            }
            if (bossId == "gramiel")
            {
                updateGramielHud(f as GramielFight);
            }
            // health bars over each character
            for each (var who:String in roles)
            {
                var a:Object = actors[who];
                Hud.bar(a.bar, 56, 6, f.hp[who] / f.maxHp(who), 0x6FE08A, 0x1D8A3A);
                a.bar.x = a.mc.x - 28;
                a.bar.y = a.mc.y - 104 * bossDef.charScale / 0.65;
            }
        }

        /** Ultra Gramiel: where `r` stands to attack `sel` - beside the crystal (on its inner side) or in a row below Gramiel */
        private function gramielStation(r:String, sel:String):Point
        {
            var gf:GramielFight = fight as GramielFight;
            var idx:int = 0;
            var n:int = 0;
            for each (var q:String in roles)
            {
                if (q == role ? sel == gf.targetSel : gf.targetOf(q) == sel)
                {
                    if (q == r)
                    {
                        idx = n;
                    }
                    n++;
                }
            }
            if (sel == "boss")
            {
                return new Point(bossPad.x + (idx - (n - 1) / 2) * 62, bossPad.y + 46);
            }
            var i:int = sel == "cl" ? 0 : 1;
            var c:MovieClip = crystalMCs[i];
            return new Point(c.x + (i == 0 ? 1 : -1) * (62 + 52 * idx), c.y + 14 + (idx % 2) * 9);
        }

        private function gramielDir(r:String):int
        {
            var sel:String = (fight as GramielFight).targetOf(r);
            var x:Number = sel == "boss" ? bossPad.x : crystalMCs[sel == "cl" ? 0 : 1].x;
            return x >= actors[r].mc.x ? 1 : -1;
        }

        public function inPlace(r:String):Boolean
        {
            var a:Object = actors[r];
            if (!a || a.moving || !(fight is GramielFight))
            {
                return false;
            }
            var p:Point = gramielStation(r, (fight as GramielFight).targetOf(r));
            return Point.distance(new Point(a.mc.x, a.mc.y), p) <= 45;
        }

        /** crystal HP bars (the left / right one is the one you keep even), the selected one outlined, and the chat bubbles */
        private function updateGramielHud(f:GramielFight):void
        {
            for (var i:int = 0; i < crystalBars.length; i++)
            {
                var side:String = i == 0 ? "cl" : "cr";
                var c:MovieClip = crystalMCs[i];
                var left:Number = f.crystalHp[side];
                var on:Boolean = false; // the crystals' HP is only shown in the target frame, after clicking them
                crystalBars[i].visible = crystalTexts[i].visible = on;
                if (on)
                {
                    Hud.bar(crystalBars[i], 70, 7, left / 400, targetSel == side ? 0xFFD24A : 0xE0507A, targetSel == side ? 0xB8861F : 0x8A1D3A);
                    crystalBars[i].x = c.x - 35;
                    crystalBars[i].y = bossDef.crystalBarY;
                    crystalTexts[i].text = (i == 0 ? "Left " : "Right ") + left + "/400";
                    crystalTexts[i].x = c.x - 60;
                    crystalTexts[i].y = bossDef.crystalBarY - 17;
                }
            }
            var now:int = getTimer();
            for (var r:String in bubbles)
            {
                var b:Object = bubbles[r];
                if (now > b.until || !actors[r])
                {
                    if (b.sp.parent)
                    {
                        b.sp.parent.removeChild(b.sp);
                    }
                    delete bubbles[r];
                    continue;
                }
                b.sp.x = actors[r].mc.x - b.w / 2;
                b.sp.y = actors[r].mc.y - 128 * bossDef.charScale / 0.65;
            }
        }

        private function botReact(holder:String, ability:String, truthN:int, zoneN:int = 0):void
        {
            if (bossId != "speaker")
            {
                return;
            }
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
                // seal Truths 2, 3, 4, 6, 7, 8 of the cycle; 2 and 6 (right after the DPS / AP zone) were sealed at the zone already
                if (role == "ap" && Fight.truthNeedsSeal(truthN))
                {
                    botQueue.push({at: at, until: at + 1400, k: 4});
                }
            }
            else if (ability == "zone" && role == "ap" && (zoneN == 1 || zoneN == 3))
            {
                // still standing in the middle: seal now, it lasts into the Truth after the zone
                botQueue.push({at: fight.t, until: fight.t + 1000, k: 4});
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
            if (bossId == "dage")
            {
                runDageBot(f, a);
                return;
            }
            if (bossId == "drakath")
            {
                runDrakathBot(f, a);
                return;
            }
            if (bossId == "nulgath")
            {
                runNulgathBot(f, a);
                return;
            }
            if (bossId == "gramiel")
            {
                runGramielBot(f as GramielFight, a);
                return;
            }
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
                    a.moveTo = wantIn ? homeAt.clone() : spot(RIGHT_AT, role);
                }
            }
            else
            {
                var home:Point = spot(homeAt, role);
                if (a.moveTo == null && Point.distance(new Point(a.mc.x, a.mc.y), home) > 20)
                {
                    a.moveTo = home;
                }
            }
            // Eden (5) right after the Truth hit the Seal, while the Seal is still up
            if (role == "ap" && f.apReduction == "seal" && f.lastTruthHit >= f.apReductionUntil - 7000 && f.t > f.lastTruthHit)
            {
                f.cast(5);
            }
            var low:Boolean = false;
            for each (var r:String in roles)
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

        /** Auto-pilot for Ultra Dage: Flux on cue, run to the lit plate and back, skills off cooldown. */
        private function runDageBot(f:Fight, a:Object):void
        {
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
            if (plateId != "")
            {
                if (!roleOnPlate(role, plateId))
                {
                    a.moveTo = plateSpot(role, plateId);
                }
            }
            else
            {
                var home:Point = spot(homeAt, role);
                if (a.moveTo == null && Point.distance(new Point(a.mc.x, a.mc.y), home) > 20)
                {
                    a.moveTo = home;
                }
            }
            if (role == "ca")
            {
                if (f.mana >= 100) // keep the mana for Flux (3)
                {
                    f.cast(4);
                    f.cast(2);
                    f.cast(5);
                }
            }
            else
            {
                f.cast(2);
                f.cast(3);
                f.cast(4);
                f.cast(5);
            }
        }

        /** Auto-pilot for Ultra Gramiel: answers the cues, keeps the crystals even, rotates the Shaman's skills. */
        private function runGramielBot(f:GramielFight, a:Object):void
        {
            for (var i:int = botQueue.length - 1; i >= 0; i--)
            {
                var q:Object = botQueue[i];
                if (q.until && f.t > q.until)
                {
                    botQueue.splice(i, 1);
                }
                else if (f.t >= q.at)
                {
                    var done:Boolean = true;
                    if (q.target)
                    {
                        selectTarget(q.target);
                        botHold = f.t + 1500;
                    }
                    else if (q.chat)
                    {
                        say(role, q.chat);
                        f.chat(q.chat);
                    }
                    else if (q.k)
                    {
                        done = inPlace(role) && f.cast(q.k);
                    }
                    if (done)
                    {
                        botQueue.splice(i, 1);
                    }
                }
            }
            var home:Point = spot(homeAt, role);
            if (a.moveTo == null && Point.distance(new Point(a.mc.x, a.mc.y), home) > 20)
            {
                a.moveTo = home;
            }
            if (!f.started)
            {
                f.cast(2);
                return;
            }
            if (f.phase == 1 && !f.draining && f.t > botHold)
            {
                // keep the crystals even: hit the one with more HP left
                var diff:int = f.crystalHp.cl - f.crystalHp.cr;
                if (f.crystalHp.cl <= 0 || diff <= -12)
                {
                    if (targetSel != "cr")
                    {
                        selectTarget("cr");
                    }
                }
                else if (f.crystalHp.cr <= 0 || diff >= 12)
                {
                    if (targetSel != "cl")
                    {
                        selectTarget("cl");
                    }
                }
            }
            else if (f.phase == 1 && !f.draining && targetSel == "boss")
            {
                selectTarget(f.crystalHp.cl > f.crystalHp.cr ? "cl" : "cr");
            }
            if (!inPlace(role))
            {
                return;
            }
            if (f.mana >= 30)
            {
                f.cast(5);
                f.cast(4);
            }
            if (f.mana >= 15)
            {
                f.cast(2);
                f.cast(3);
            }
        }

        private var botHold:Number = 0;

        /** Auto-pilot for Ultra Nulgath: Quix on the Blade first (Lord of Order), taunt on cue, heal when somebody is low. */
        private function runNulgathBot(f:Fight, a:Object):void
        {
            for (var i:int = botQueue.length - 1; i >= 0; i--)
            {
                var q:Object = botQueue[i];
                if (f.t > q.until)
                {
                    botQueue.splice(i, 1);
                }
                else if (f.started && f.t >= q.at && f.cast(q.k))
                {
                    botQueue.splice(i, 1);
                }
            }
            var home:Point = spot(homeAt, role);
            if (a.moveTo == null && Point.distance(new Point(a.mc.x, a.mc.y), home) > 20)
            {
                a.moveTo = home;
            }
            if (!f.started)
            {
                if (role == "loo")
                {
                    if (!targetBlade)
                    {
                        showTarget(true); // click the Blade, then Quix (5) starts the fight
                    }
                    f.targetIsBlade = true;
                    f.cast(5);
                }
                else
                {
                    f.cast(2);
                }
                return;
            }
            var lowest:Number = 1;
            for each (var al:String in roles)
            {
                if (f.hp[al] > 0)
                {
                    lowest = Math.min(lowest, f.hp[al] / f.maxHp(al));
                }
            }
            if (role == "loo")
            {
                if (lowest < 0.6)
                {
                    f.cast(3);
                }
                f.cast(2);
                f.cast(4);
            }
            else
            {
                f.cast(4);
                f.cast(5);
                f.cast(3);
                f.cast(2);
            }
        }

        /** Auto-pilot for Champion Drakath: taunt on cue, stay by the boss, skills off cooldown. */
        private function runDrakathBot(f:Fight, a:Object):void
        {
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
            var home:Point = spot(homeAt, role);
            if (a.moveTo == null && Point.distance(new Point(a.mc.x, a.mc.y), home) > 20)
            {
                a.moveTo = home;
            }
            if (role == "lr")
            {
                f.cast(4);
                f.cast(5);
                f.cast(3);
                f.cast(2);
            }
            else
            {
                var lowest:Number = 1;
                for each (var al:String in roles)
                {
                    if (f.hp[al] > 0)
                    {
                        lowest = Math.min(lowest, f.hp[al] / f.maxHp(al));
                    }
                }
                if (lowest < 0.7)
                {
                    f.cast(4);
                }
                f.cast(3);
                f.cast(5);
                f.cast(2);
            }
        }

        // ============================================================ state for tests
        public function getState():String
        {
            var f:Fight = fight;
            return "{\"t\":" + Math.round(f.t) + ",\"bossHp\":" + Math.round(f.bossHp) +
                ",\"hp\":" + hpJson() +
                ",\"over\":" + (f.over ? "\"" + f.over.result + ": " + f.over.reason + "\"" : "null") +
                ",\"boss\":\"" + bossLabel + "\",\"frame\":" + bossMC.currentFrame + ",\"zone\":\"" + zoneRole + "\",\"role\":\"" + role + "\",\"boss_id\":\"" + bossId + "\",\"plate\":\"" + plateId + "\"" +
                ",\"player\":[" + Math.round(actors[role].mc.x) + "," + Math.round(actors[role].mc.y) + "]" +
                ",\"gear\":\"" + gearState() + "\",\"bossBox\":" + box(bossMC) + ",\"playerBox\":" + box(actors[role].mc) + ",\"pose\":\"" + actors[role].pose + "\",\"moving\":" + actors[role].moving + ",\"gram\":" + (bossId == "gramiel" ? (f as GramielFight).debug() : "null") + ",\"started\":" + f.started + ",\"frames\":" + frameCount + ",\"mana\":" + Math.round(f.mana) + ",\"counters\":" + JSON.stringify(f.counters) + ",\"log\":" + JSON.stringify(logLines.slice(-6)) + "}";
        }

        private function box(d:DisplayObject):String
        {
            var b:Rectangle = d.getBounds(this);
            return "[" + Math.round(b.x) + "," + Math.round(b.y) + "," + Math.round(b.width) + "," + Math.round(b.height) + "]";
        }

        private function hpJson():String
        {
            var parts:Array = [];
            for each (var r:String in roles)
            {
                parts.push("\"" + r + "\":" + fight.hp[r]);
            }
            return "{" + parts.join(",") + "}";
        }

        private function gearState():String
        {
            var mc:AvatarMC = actors[role].mc;
            return (mc.mcChar.weapon.visible ? "weapon " : "") + (mc.mcChar.cape.visible ? "cape " : "") + (mc.mcChar.head.helm.visible ? "helm" : "");
        }
    }
}

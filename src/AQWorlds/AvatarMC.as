package AQWorlds
{
   import flash.display.DisplayObject;
   import flash.display.Loader;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.geom.ColorTransform;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.net.URLLoader;
   import flash.net.URLLoaderDataFormat;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.ByteArray;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2427")]
   public class AvatarMC extends MovieClip
   {
      
      public var bubble:MovieClip;
      
      public var cShadow:MovieClip;
      
      public var fx:MovieClip;
      
      public var mcChar:mcSkel;
      
      public var pname:MovieClip;
      
      public var proxy:MovieClip;
      
      public var shadow:MovieClip;
      
      private var headPoint:Point;
      
      private var totalTransform:Object = {
         "alphaMultiplier":1,
         "alphaOffset":0,
         "redMultiplier":1,
         "redOffset":0,
         "greenMultiplier":1,
         "greenOffset":0,
         "blueMultiplier":1,
         "blueOffset":0
      };
      
      private var clampedTransform:ColorTransform = new ColorTransform();
      
      public var spFX:Object = {};
      
      public var spellDur:int = 0;
      
      public var isLoaded:Boolean = false;
      
      public var defaultCT:ColorTransform = MovieClip(this).transform.colorTransform;
      
      public var CT3:ColorTransform = new ColorTransform(1,1,1,1,255,255,255,0);
      
      public var CT2:ColorTransform = new ColorTransform(1,1,1,1,127,127,127,0);
      
      public var CT1:ColorTransform = new ColorTransform(1,1,1,1,0,0,0,0);
      
      public var pAV:Avatar;
      
      public var strGender:String;
      
      public var bBackHair:Boolean = false;
      
      public var helmBackHair:Boolean = false;
      
      private var animEvents:Object = new Object();
      
      private var Ancestor:MovieClip;
      
      private var tLoader:Loader = new Loader();
      
      private var AD:ApplicationDomain;
      
      private var LC:LoaderContext;
      
      private var stream:URLLoader;
      
      private var fileQueue:Array = [];
      
      private var inProgress:Boolean = false;
      
      public var attackFrames:Array = [];
      
      private var op:*;
      
      private var tp:*;
      
      private var walkTS:*;
      
      private var walkD:*;
      
      public function AvatarMC(param1:MovieClip)
      {
         super();
         addFrameScript(0,this.frame1,4,this.frame5,9,this.frame10,11,this.frame12,12,this.frame13,13,this.frame14,19,this.frame20,22,this.frame23);
         this.Ancestor = param1;
         this.tLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,this.destroyCallback,false,0,true);
         this.tLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,this.onLoadError,false,0,true);
         this.gotoAndPlay("in1");
         this.mcChar.buttonMode = true;
         this.pname.mouseChildren = false;
         this.pname.buttonMode = false;
         this.mcChar.mouseChildren = true;
         this.pname.ti.text = "";
         this.bubble.visible = false;
         this.headPoint = new Point(0,this.mcChar.head.y - 1.4 * this.mcChar.head.height);
         this.hideOptionalParts();
         this.addEventListener(Event.ENTER_FRAME,this.onFileCheck,false,0,true);
      }
      
      public function get ActiveSet() : *
      {
         return this.pAV.m.ActiveSet;
      }
      
      public function load(param1:String, param2:*) : *
      {
         this.fileQueue.push({
            "value":param1,
            "callback":param2
         });
      }
      
      private function onFileCheck(param1:Event) : void
      {
         if(this.inProgress || this.fileQueue.length < 1)
         {
            return;
         }
         this.inProgress = true;
         // Recovered code read the file through AIR's FileStream. URLLoader works the same in
         // AIR (paths are relative to the application directory) and in Flash Player / Ruffle.
         this.stream = new URLLoader();
         this.stream.dataFormat = URLLoaderDataFormat.BINARY;
         this.stream.addEventListener(IOErrorEvent.IO_ERROR,this.onError,false,0,true);
         this.stream.addEventListener(Event.COMPLETE,this.onFileComplete,false,0,true);
         this.stream.load(new URLRequest(this.fileQueue[0].value));
      }
      
      private function onError(param1:IOErrorEvent) : void
      {
         this.fileQueue.shift();
         this.inProgress = false;
      }
      
      private function onFileComplete(param1:Event) : void
      {
         this.AD = new ApplicationDomain();
         this.LC = new LoaderContext(false,this.AD);
         this.tLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,this.fileQueue[0].callback,false,0,true);
         try
         {
            // AIR-only flag (needed there to run code from loadBytes); Flash Player / Ruffle don't have it
            this.LC["allowLoadBytesCodeExecution"] = true;
         }
         catch(e:Error)
         {
         }
         var _loc2_:ByteArray = ByteArray(this.stream.data);
         this.tLoader.loadBytes(_loc2_,this.LC);
      }
      
      private function onLoadError(param1:IOErrorEvent) : void
      {
         this.tLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE,this.fileQueue[0].callback);
         this.fileQueue.shift();
         this.inProgress = false;
      }
      
      private function destroyCallback(param1:Event = null) : void
      {
         this.tLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE,this.fileQueue[0].callback);
         this.fileQueue.shift();
         this.inProgress = false;
      }
      
      private function getDef(param1:String) : Class
      {
         return this.tLoader.contentLoaderInfo.applicationDomain.getDefinition(param1) as Class;
      }
      
      private function hasDef(param1:String) : Boolean
      {
         return this.tLoader.contentLoaderInfo.applicationDomain.hasDefinition(param1);
      }
      
      public function findDef(param1:String = "", param2:Object = null) : Class
      {
         var _loc4_:String = null;
         var _loc8_:Boolean = false;
         if(param2 == null)
         {
            param2 = {};
         }
         var _loc3_:Vector.<String> = this.tLoader.contentLoaderInfo.applicationDomain.getQualifiedDefinitionNames();
         if(_loc3_.length < 1)
         {
            return null;
         }
         var _loc5_:* = 0;
         while(_loc5_ < _loc3_.length)
         {
            if(_loc3_[_loc5_].indexOf("::") != -1)
            {
               _loc3_.removeAt(_loc5_);
               _loc5_--;
            }
            _loc5_++;
         }
         if(param2.hasOwnProperty("or"))
         {
            if(this.tLoader.contentLoaderInfo.applicationDomain.hasDefinition(param1))
            {
               return this.tLoader.contentLoaderInfo.applicationDomain.getDefinition(param1) as Class;
            }
         }
         var _loc6_:String = "";
         var _loc7_:Array = [];
         for each(_loc4_ in _loc3_)
         {
            if(_loc4_.indexOf("MChest") != -1 || _loc4_.indexOf("FChest") != -1)
            {
               this.strGender = _loc4_.indexOf("MChest") == _loc4_.length - 6 ? "M" : "F";
            }
            else if(_loc4_.indexOf("MHead") != -1 || _loc4_.indexOf("FHead") != -1)
            {
               this.strGender = _loc4_.indexOf("MHead") == _loc4_.length - 5 ? "M" : "F";
            }
            if(param2.hasOwnProperty("suffix"))
            {
               if(_loc4_.indexOf(param1) == _loc4_.length - param1.length)
               {
                  _loc7_.push(_loc4_);
               }
            }
            else if(param2.hasOwnProperty("prefix"))
            {
               if(_loc4_.indexOf(param1) == 0)
               {
                  _loc7_.push(_loc4_);
               }
            }
            else if(_loc4_.indexOf(param1) != -1)
            {
               _loc7_.push(_loc4_);
            }
         }
         _loc8_ = !param2.hasOwnProperty("suffix") && !param2.hasOwnProperty("prefix");
         if((_loc8_) && _loc7_.length < 1 && _loc3_.length > 0)
         {
            if(_loc3_.length < 1)
            {
               return null;
            }
            _loc6_ = _loc3_[0];
         }
         else if(_loc7_.length > 0)
         {
            _loc6_ = _loc7_[0];
         }
         if(_loc7_.length > 1)
         {
            this.reportLinkages(_loc3_);
         }
         if(_loc6_ == "")
         {
            return null;
         }
         return this.tLoader.contentLoaderInfo.applicationDomain.getDefinition(_loc6_) as Class;
      }
      
      private function reportLinkages(param1:Vector.<String>) : void
      {
         var _loc3_:String = null;
         var _loc2_:String = "";
         _loc2_ += "<font size=\"10\" style=\"roboto medium\" color=\"#727272\">LINKAGES REPORT</font>\n";
         _loc2_ += "<font size=\"10\" color=\"#FFFFFF\"><b>" + param1.length + "</b></font> <font color=\"#727272\" size=\"10\">Linkage(s) found.</font>\n";
         for each(_loc3_ in param1)
         {
            _loc2_ += "<font size=\"10\" color=\"#FFFFFF\">" + _loc3_ + "</font>\n";
         }
         new messagebox(this.Ancestor,_loc2_);
      }
      
      override public function gotoAndPlay(param1:Object, param2:String = null) : void
      {
         this.handleAnimEvent(String(param1));
         super.gotoAndPlay(param1);
      }
      
      public function hasLabel(param1:String) : Boolean
      {
         var _loc2_:Array = this.mcChar.currentLabels;
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            if(_loc2_[_loc3_].name == param1)
            {
               return true;
            }
            _loc3_++;
         }
         return false;
      }
      
      private function hideOptionalParts() : void
      {
         var _loc1_:* = ["cape","backhair","robe","backrobe"];
         var _loc2_:* = ["weapon","weaponOff","weaponFist","weaponFistOff","shield"];
         var _loc3_:String = "";
         for(_loc3_ in _loc1_)
         {
            if(typeof this.mcChar[_loc1_[_loc3_]] != undefined)
            {
               this.mcChar[_loc1_[_loc3_]].visible = false;
            }
         }
         for(_loc3_ in _loc2_)
         {
            if(typeof this.mcChar[_loc2_[_loc3_]] != undefined)
            {
               this.mcChar[_loc2_[_loc3_]].visible = false;
            }
         }
         this.cShadow.visible = false;
      }
      
      public function onLoadMiscComplete(param1:Event) : void
      {
         var _loc2_:Class = this.findDef(this.ActiveSet["itemLinks"]["Ground"],{"or":1});
         if(_loc2_ != null)
         {
            this.cShadow.visible = true;
            this.cShadow.removeChildAt(0);
            this.cShadow.addChild(new _loc2_());
            this.cShadow.scaleX = this.mcChar.scaleX;
            this.cShadow.scaleY = this.mcChar.scaleY;
            this.cShadow.mouseEnabled = this.cShadow.mouseChildren = false;
            this.shadow.alpha = 0;
         }
         else
         {
            this.cShadow.visible = false;
            this.shadow.alpha = 1;
         }
         this.handleVisibilities();
      }
      
      public function onLoadArmorComplete(param1:Event) : void
      {
         this.clearAnimEvents();
         this.loadArmorPieces();
      }
      
      public function loadArmorPieces() : void
      {
         var _loc1_:Class = null;
         var _loc2_:DisplayObject = null;
         var _loc3_:DisplayObject = null;
         try
         {
            _loc1_ = this.findDef("Head",{"suffix":1});
            if(_loc1_ != null)
            {
               _loc2_ = this.mcChar.head.getChildByName("face");
               if(_loc2_ != null)
               {
                  this.mcChar.head.removeChild(_loc2_);
               }
               _loc3_ = this.mcChar.head.addChildAt(new _loc1_(),0);
               _loc3_.name = "face";
            }
            else
            {
               _loc1_ = ApplicationDomain.currentDomain.getDefinition("mcHead" + this.strGender) as Class;
               _loc2_ = this.mcChar.head.getChildByName("face");
               if(_loc2_ != null)
               {
                  this.mcChar.head.removeChild(_loc2_);
               }
               _loc3_ = this.mcChar.head.addChildAt(new _loc1_(),0);
               _loc3_.name = "face";
            }
         }
         catch(err:Error)
         {
         }
         try
         {
            _loc1_ = this.findDef("Chest",{"suffix":1});
            if(_loc1_ != null)
            {
               this.mcChar.chest.removeChildAt(0);
               this.mcChar.chest.addChild(new _loc1_());
            }
         }
         catch(e:Error)
         {
         }
         try
         {
            _loc1_ = this.findDef("Hip",{"suffix":1});
            if(_loc1_ != null)
            {
               this.mcChar.hip.removeChildAt(0);
               this.mcChar.hip.addChild(new _loc1_());
            }
         }
         catch(e:Error)
         {
         }
         try
         {
            _loc1_ = this.findDef("FootIdle",{"suffix":1});
            if(_loc1_ != null)
            {
               this.mcChar.idlefoot.removeChildAt(0);
               this.mcChar.idlefoot.addChild(new _loc1_());
            }
         }
         catch(e:Error)
         {
         }
         try
         {
            _loc1_ = this.findDef("Foot",{"suffix":1});
            if(_loc1_ != null)
            {
               this.mcChar.frontfoot.removeChildAt(0);
               this.mcChar.frontfoot.addChild(new _loc1_());
               this.mcChar.frontfoot.visible = false;
               this.mcChar.backfoot.removeChildAt(0);
               this.mcChar.backfoot.addChild(new _loc1_());
            }
         }
         catch(e:Error)
         {
         }
         try
         {
            _loc1_ = this.findDef("Shoulder",{"suffix":1});
            if(_loc1_ != null)
            {
               this.mcChar.frontshoulder.removeChildAt(0);
               this.mcChar.frontshoulder.addChild(new _loc1_());
               this.mcChar.backshoulder.removeChildAt(0);
               this.mcChar.backshoulder.addChild(new _loc1_());
            }
         }
         catch(e:Error)
         {
         }
         try
         {
            _loc1_ = this.findDef("Hand",{"suffix":1});
            if(_loc1_ != null)
            {
               this.mcChar.fronthand.removeChildAt(0);
               this.mcChar.fronthand.addChildAt(new _loc1_(),0);
               this.mcChar.backhand.removeChildAt(0);
               this.mcChar.backhand.addChildAt(new _loc1_(),0);
               this.mcChar.backhand.getChildAt(0).transform.colorTransform = new ColorTransform(1,1,1,1,-255,-255,-255,0);
            }
         }
         catch(e:Error)
         {
         }
         try
         {
            _loc1_ = this.findDef("Thigh",{"suffix":1});
            if(_loc1_ != null)
            {
               this.mcChar.frontthigh.removeChildAt(0);
               this.mcChar.frontthigh.addChild(new _loc1_());
               this.mcChar.backthigh.removeChildAt(0);
               this.mcChar.backthigh.addChild(new _loc1_());
            }
         }
         catch(e:Error)
         {
         }
         try
         {
            _loc1_ = this.findDef("Shin",{"suffix":1});
            if(_loc1_ != null)
            {
               this.mcChar.frontshin.removeChildAt(0);
               this.mcChar.frontshin.addChild(new _loc1_());
               this.mcChar.backshin.removeChildAt(0);
               this.mcChar.backshin.addChild(new _loc1_());
            }
         }
         catch(e:Error)
         {
         }
         try
         {
            _loc1_ = this.findDef("Robe",{"suffix":1});
            if(_loc1_ != null)
            {
               this.mcChar.robe.removeChildAt(0);
               this.mcChar.robe.addChild(new _loc1_());
               this.mcChar.robe.visible = true;
            }
            else
            {
               this.mcChar.robe.visible = false;
            }
         }
         catch(e:Error)
         {
         }
         try
         {
            _loc1_ = this.findDef("RobeBack",{"suffix":1});
            if(_loc1_ != null)
            {
               this.mcChar.backrobe.removeChildAt(0);
               this.mcChar.backrobe.addChild(new _loc1_());
               this.mcChar.backrobe.visible = true;
            }
            else
            {
               this.mcChar.backrobe.visible = false;
            }
         }
         catch(e:Error)
         {
         }
         this.handleVisibilities();
      }
      
      public function onHairLoadComplete(param1:Event) : void
      {
         var _loc2_:Class = null;
         try
         {
            _loc2_ = this.findDef("Hair",{"suffix":1});
            if(_loc2_ != null)
            {
               if(this.mcChar.head.hair.numChildren > 0)
               {
                  this.mcChar.head.hair.removeChildAt(0);
               }
               this.mcChar.head.hair.addChild(new _loc2_());
               this.mcChar.head.hair.visible = true;
            }
            else
            {
               this.mcChar.head.hair.visible = false;
            }
            _loc2_ = this.findDef("HairBack",{"suffix":1});
            if(_loc2_ != null)
            {
               if(!this.helmBackHair || this.helmBackHair && !this.ActiveSet["itemShow"]["Helmet"])
               {
                  if(this.mcChar.backhair.numChildren > 0)
                  {
                     this.mcChar.backhair.removeChildAt(0);
                  }
                  this.mcChar.backhair.addChild(new _loc2_());
                  this.mcChar.backhair.visible = true;
               }
               this.bBackHair = true;
            }
            else
            {
               this.mcChar.backhair.visible = false;
               this.bBackHair = false;
            }
         }
         catch(e:Error)
         {
         }
         this.handleVisibilities();
      }
      
      public function onLoadWeaponComplete(param1:Event) : void
      {
         if(this.mcChar.weaponFist.numChildren > 0)
         {
            this.mcChar.weaponFist.removeChildAt(0);
         }
         if(this.mcChar.weaponFistOff.numChildren > 0)
         {
            this.mcChar.weaponFistOff.removeChildAt(0);
         }
         if(this.mcChar.weapon.numChildren > 0)
         {
            this.mcChar.weapon.removeChildAt(0);
         }
         if(this.mcChar.fronthand.numChildren > 1)
         {
            this.mcChar.fronthand.removeChildAt(1);
         }
         if(this.mcChar.backhand.numChildren > 1)
         {
            this.mcChar.backhand.removeChildAt(1);
         }
         var _loc2_:Class = this.findDef(this.ActiveSet["itemLinks"]["Weapon"],{"or":1});
         if(_loc2_ != null)
         {
            if(this.ActiveSet["weaponType"] == "Gauntlet")
            {
               this.mcChar.fronthand.addChildAt(new _loc2_(),1);
               this.mcChar.fronthand.getChildAt(1).scaleX = 0.8;
               this.mcChar.fronthand.getChildAt(1).scaleY = 0.8;
               this.mcChar.fronthand.getChildAt(1).scaleX = this.mcChar.fronthand.getChildAt(1).scaleX * -1;
               this.mcChar.backhand.addChildAt(new _loc2_(),1);
               this.mcChar.backhand.getChildAt(1).scaleX = 0.8;
               this.mcChar.backhand.getChildAt(1).scaleY = 0.8;
               this.mcChar.backhand.getChildAt(1).scaleX = this.mcChar.backhand.getChildAt(1).scaleX * -1;
               this.mcChar.weapon.mcWeapon = new MovieClip();
            }
            else
            {
               this.mcChar.weapon.mcWeapon = new _loc2_();
               this.mcChar.weapon.addChild(this.mcChar.weapon.mcWeapon);
            }
         }
         else if(this.ActiveSet["weaponType"] != "Gauntlet")
         {
            this.mcChar.weapon.mcWeapon = MovieClip(param1.target.content);
            this.mcChar.weapon.addChild(this.mcChar.weapon.mcWeapon);
         }
         this.mcChar.weapon.visible = false;
         this.mcChar.weaponOff.visible = false;
         this.mcChar.weaponFist.visible = false;
         this.mcChar.weaponFistOff.visible = false;
         if(this.ActiveSet["weaponType"] != "Gauntlet")
         {
            this.mcChar.weapon.visible = true;
         }
         if(this.ActiveSet["weaponType"] == "Dagger")
         {
            this.onLoadWeaponOffComplete(param1);
         }
         else
         {
            this.handleVisibilities();
         }
      }
      
      public function onLoadWeaponOffComplete(param1:Event) : void
      {
         if(this.mcChar.weaponOff.numChildren > 0)
         {
            this.mcChar.weaponOff.removeChildAt(0);
         }
         var _loc2_:Class = this.findDef(this.ActiveSet["itemLinks"]["Weapon"],{"or":1});
         if(_loc2_ != null)
         {
            this.mcChar.weaponOff.addChild(new _loc2_());
         }
         else
         {
            this.mcChar.weaponOff.addChild(param1.target.content);
         }
         this.mcChar.weaponOff.visible = true;
         this.handleVisibilities();
      }
      
      public function onLoadCapeComplete(param1:Event) : void
      {
         var _loc2_:Class = this.findDef(this.ActiveSet["itemLinks"]["Cape"],{"or":1});
         if(_loc2_ != null)
         {
            this.mcChar.cape.removeChildAt(0);
            this.mcChar.cape.cape = new _loc2_();
            this.mcChar.cape.addChild(this.mcChar.cape.cape);
         }
         this.handleVisibilities();
      }
      
      public function onLoadHelmComplete(param1:Event = null) : void
      {
         var _loc2_:Class = this.findDef(this.ActiveSet["itemLinks"]["Helmet"],{"or":1});
         if(_loc2_ != null)
         {
            if(this.mcChar.head.helm.numChildren > 0)
            {
               this.mcChar.head.helm.removeChildAt(0);
            }
            this.mcChar.head.helm.visible = this.ActiveSet["itemShow"]["Helmet"];
            this.mcChar.head.hair.visible = !this.mcChar.head.helm.visible;
            this.mcChar.backhair.visible = Boolean(this.mcChar.head.hair.visible) && this.bBackHair;
            this.mcChar.head.helm.addChild(new _loc2_());
            _loc2_ = this.findDef("_backhair",{"suffix":1});
            if(_loc2_ != null)
            {
               if(this.ActiveSet["itemShow"]["Helmet"])
               {
                  if(this.mcChar.backhair.numChildren > 0)
                  {
                     this.mcChar.backhair.removeChildAt(0);
                  }
                  this.mcChar.backhair.visible = true;
                  this.mcChar.backhair.addChild(new _loc2_());
               }
               this.helmBackHair = true;
            }
            else
            {
               this.helmBackHair = false;
            }
         }
         this.handleVisibilities();
      }
      
      public function handleVisibilities() : void
      {
         var _loc1_:String = null;
         var _loc2_:Boolean = false;
         for(_loc1_ in this.ActiveSet["itemShow"])
         {
            _loc2_ = Boolean(this.ActiveSet["itemShow"][_loc1_]);
            switch(_loc1_)
            {
               case "Weapon":
                  if(this.ActiveSet["itemLinks"]["Weapon"] != "")
                  {
                     if(_loc2_)
                     {
                        switch(this.ActiveSet["weaponType"])
                        {
                           case "Sword":
                              this.mcChar.weapon.visible = true;
                              break;
                           case "Dagger":
                              this.mcChar.weapon.visible = true;
                              this.mcChar.weaponOff.visible = true;
                              break;
                           case "Gauntlet":
                              if(this.mcChar.fronthand.numChildren > 1)
                              {
                                 this.mcChar.fronthand.getChildAt(1).visible = true;
                              }
                              if(this.mcChar.backhand.numChildren > 1)
                              {
                                 this.mcChar.backhand.getChildAt(1).visible = true;
                              }
                        }
                     }
                     else
                     {
                        this.mcChar.weapon.visible = false;
                        this.mcChar.weaponOff.visible = false;
                        if(this.mcChar.fronthand.numChildren > 1)
                        {
                           this.mcChar.fronthand.getChildAt(1).visible = false;
                        }
                        if(this.mcChar.backhand.numChildren > 1)
                        {
                           this.mcChar.backhand.getChildAt(1).visible = false;
                        }
                     }
                  }
                  break;
               case "Helmet":
                  if(this.ActiveSet["itemLinks"]["Helmet"] != "")
                  {
                     if(_loc2_)
                     {
                        if(this.helmBackHair && this.bBackHair)
                        {
                           this.onLoadHelmComplete();
                           return;
                        }
                        this.mcChar.head.helm.visible = true;
                        this.mcChar.head.hair.visible = false;
                        this.mcChar.backhair.visible = this.helmBackHair;
                     }
                     else
                     {
                        if(this.helmBackHair && this.bBackHair)
                        {
                           return;
                        }
                        this.mcChar.head.helm.visible = false;
                        this.mcChar.head.hair.visible = true;
                        this.mcChar.backhair.visible = this.bBackHair;
                     }
                  }
                  break;
               case "Back Hair":
                  if(this.ActiveSet["itemLinks"]["Hair"] != "")
                  {
                     this.mcChar.backhair.visible = _loc2_;
                  }
                  break;
               case "Cape":
                  if(this.ActiveSet["itemLinks"]["Cape"] != "")
                  {
                     this.mcChar.cape.visible = _loc2_;
                  }
                  break;
               case "Robe":
                  if(this.ActiveSet["itemLinks"]["Armor"] != "")
                  {
                     this.mcChar.robe.visible = _loc2_;
                  }
                  break;
               case "Back Robe":
                  if(this.ActiveSet["itemLinks"]["Armor"] != "")
                  {
                     this.mcChar.backrobe.visible = _loc2_;
                  }
                  break;
               case "Ground":
                  this.cShadow.visible = _loc2_;
                  break;
               case "Pet":
                  if(this.ActiveSet["itemLinks"]["Pet"] != "")
                  {
                     this.pAV.petMC.visible = _loc2_;
                  }
            }
         }
      }
      
      public function setColor(param1:MovieClip, param2:String, param3:String) : void
      {
         if(this.pAV.objData == null)
         {
            this.pAV.objData = {};
         }
         var _loc4_:Number = Number(this.pAV.objData["intColor" + param2]);
         param1.isColored = true;
         param1.intColor = _loc4_;
         param1.strLocation = param2;
         param1.strShade = param3;
         this.changeColor(param1,_loc4_,param3);
      }
      
      public function changeColor(param1:MovieClip, param2:Number, param3:String, param4:String = "") : void
      {
         var _loc5_:ColorTransform = new ColorTransform();
         if(param4 == "")
         {
            _loc5_.color = param2;
         }
         switch(param3.toUpperCase())
         {
            case "LIGHT":
               _loc5_.redOffset += 100;
               _loc5_.greenOffset += 100;
               _loc5_.blueOffset += 100;
               break;
            case "DARK":
               _loc5_.redOffset -= param1.strLocation == "Skin" ? 25 : 50;
               _loc5_.greenOffset -= 50;
               _loc5_.blueOffset -= 50;
               break;
            case "DARKER":
               _loc5_.redOffset -= 125;
               _loc5_.greenOffset -= 125;
               _loc5_.blueOffset -= 125;
         }
         if(param4 == "-")
         {
            _loc5_.redOffset *= -1;
            _loc5_.greenOffset *= -1;
            _loc5_.blueOffset *= -1;
         }
         if(param4 == "" || param1.transform.colorTransform.redOffset != _loc5_.redOffset)
         {
            param1.transform.colorTransform = _loc5_;
         }
      }
      
      public function modulateColor(param1:ColorTransform, param2:String) : void
      {
         var _loc3_:MovieClip = this.stage.getChildAt(0) as MovieClip;
         if(param2 == "+")
         {
            this.totalTransform.alphaMultiplier += param1.alphaMultiplier;
            this.totalTransform.alphaOffset += param1.alphaOffset;
            this.totalTransform.redMultiplier += param1.redMultiplier;
            this.totalTransform.redOffset += param1.redOffset;
            this.totalTransform.greenMultiplier += param1.greenMultiplier;
            this.totalTransform.greenOffset += param1.greenOffset;
            this.totalTransform.blueMultiplier += param1.blueMultiplier;
            this.totalTransform.blueOffset += param1.blueOffset;
         }
         else if(param2 == "-")
         {
            this.totalTransform.alphaMultiplier -= param1.alphaMultiplier;
            this.totalTransform.alphaOffset -= param1.alphaOffset;
            this.totalTransform.redMultiplier -= param1.redMultiplier;
            this.totalTransform.redOffset -= param1.redOffset;
            this.totalTransform.greenMultiplier -= param1.greenMultiplier;
            this.totalTransform.greenOffset -= param1.greenOffset;
            this.totalTransform.blueMultiplier -= param1.blueMultiplier;
            this.totalTransform.blueOffset -= param1.blueOffset;
         }
         this.clampedTransform.alphaMultiplier = _loc3_.clamp(this.totalTransform.alphaMultiplier,-1,1);
         this.clampedTransform.alphaOffset = _loc3_.clamp(this.totalTransform.alphaOffset,-255,255);
         this.clampedTransform.redMultiplier = _loc3_.clamp(this.totalTransform.redMultiplier,-1,1);
         this.clampedTransform.redOffset = _loc3_.clamp(this.totalTransform.redOffset,-255,255);
         this.clampedTransform.greenMultiplier = _loc3_.clamp(this.totalTransform.greenMultiplier,-1,1);
         this.clampedTransform.greenOffset = _loc3_.clamp(this.totalTransform.greenOffset,-255,255);
         this.clampedTransform.blueMultiplier = _loc3_.clamp(this.totalTransform.blueMultiplier,-1,1);
         this.clampedTransform.blueOffset = _loc3_.clamp(this.totalTransform.blueOffset,-255,255);
         this.transform.colorTransform = this.clampedTransform;
      }
      
      public function updateColor(param1:Object = null) : *
      {
         var _loc2_:* = undefined;
         if(param1 != null)
         {
            if(this.pAV.objData == null)
            {
               this.pAV.objData = {};
            }
            for(_loc2_ in param1)
            {
               this.pAV.objData[_loc2_] = param1[_loc2_];
            }
         }
         this.scanColor(this);
      }
      
      private function scanColor(param1:MovieClip) : void
      {
         var _loc3_:DisplayObject = null;
         if("isColored" in param1)
         {
            this.changeColor(param1,Number(this.pAV.objData["intColor" + param1.strLocation]),param1.strShade);
         }
         var _loc2_:int = 0;
         while(_loc2_ < param1.numChildren)
         {
            _loc3_ = param1.getChildAt(_loc2_);
            if(_loc3_ is MovieClip)
            {
               this.scanColor(MovieClip(_loc3_));
            }
            _loc2_++;
         }
      }
      
      public function performAttack(param1:*) : void
      {
         var _loc2_:int = 0;
         param1 = MovieClip(param1);
         while(true)
         {
            if(!(_loc2_ < 4 && Boolean(param1)))
            {
               return;
            }
            if(param1.hasOwnProperty("bAttack"))
            {
               param1.gotoAndPlay("Attack");
               break;
            }
            if(!(param1.numChildren > 0 && param1.getChildAt(0) is MovieClip))
            {
               break;
            }
            param1 = MovieClip(param1.getChildAt(0));
            _loc2_++;
         }
      }
      
      public function handleAttack() : void
      {
         var _loc1_:* = undefined;
         var _loc2_:Array = null;
         var _loc3_:* = undefined;
         var _loc5_:* = undefined;
         if(this.ActiveSet["weaponType"] == "Gauntlet")
         {
            _loc2_ = [(this.mcChar.fronthand.getChildAt(1) as MovieClip).getChildAt(1),(this.mcChar.backhand.getChildAt(1) as MovieClip).getChildAt(0)];
            for each(_loc3_ in _loc2_)
            {
               this.performAttack(_loc3_);
            }
         }
         else if(this.ActiveSet["weaponType"] == "Dagger")
         {
            _loc2_ = [this.mcChar.weapon.mcWeapon,this.mcChar.weaponOff];
            if(this.mcChar.weapon.mcWeapon.numChildren > 1)
            {
               _loc2_ = [(this.mcChar.weapon.mcWeapon as MovieClip).getChildAt(1),(this.mcChar.weaponOff as MovieClip).getChildAt(0)];
            }
            for each(_loc3_ in _loc2_)
            {
               this.performAttack(_loc3_);
            }
         }
         else
         {
            _loc1_ = this.mcChar.weapon.mcWeapon;
            this.performAttack(_loc1_);
         }
         var _loc4_:* = 0;
         while(_loc4_ < this.attackFrames.length)
         {
            _loc5_ = this.attackFrames[_loc4_];
            if(!_loc5_)
            {
               this.attackFrames.splice(_loc4_,1);
               _loc4_--;
            }
            else if(_loc5_ is MovieClip)
            {
               MovieClip(_loc5_).gotoAndPlay("Attack");
            }
            _loc4_++;
         }
      }
      
      public function turn(param1:String) : void
      {
         if(param1 == "right" && this.mcChar.scaleX < 0 || param1 == "left" && this.mcChar.scaleX > 0)
         {
            this.mcChar.scaleX *= -1;
         }
      }
      
      public function scale(param1:Number) : void
      {
         if(this.mcChar.scaleX >= 0)
         {
            this.mcChar.scaleX = param1;
         }
         else
         {
            this.mcChar.scaleX = -param1;
         }
         this.mcChar.scaleY = param1;
         this.shadow.scaleX = this.shadow.scaleY = param1;
         this.cShadow.scaleX = this.cShadow.scaleY = param1;
         var _loc2_:Point = this.mcChar.localToGlobal(this.headPoint);
         _loc2_ = this.globalToLocal(_loc2_);
         this.pname.y = int(_loc2_.y);
      }
      
      public function endAction() : void
      {
         this.mcChar.gotoAndPlay("Idle");
      }
      
      public function addAnimationListener(param1:String, param2:Function, param3:Boolean = true) : void
      {
         if(this.animEvents[param1] == null)
         {
            this.animEvents[param1] = new Array();
         }
         if(!this.hasAnimationListener(param1,param2))
         {
            this.animEvents[param1].push(param2);
            this.animEvents[param1].push(param3);
         }
      }
      
      public function removeAnimationListener(param1:String, param2:Function) : void
      {
         if(this.animEvents[param1] == null)
         {
            return;
         }
         var _loc3_:uint = 0;
         while(_loc3_ < this.animEvents[param1].length)
         {
            if(this.animEvents[param1][_loc3_] == param2)
            {
               this.animEvents[param1].splice(_loc3_,1);
               break;
            }
            _loc3_ += 2;
         }
      }
      
      public function hasAnimationListener(param1:String, param2:Function) : Boolean
      {
         if(this.animEvents[param1] == null)
         {
            return false;
         }
         var _loc3_:uint = 0;
         while(_loc3_ < this.animEvents[param1].length)
         {
            if(this.animEvents[param1][_loc3_] == param2)
            {
               return true;
            }
            _loc3_ += 2;
         }
         return false;
      }
      
      private function handleAnimEvent(param1:String) : void
      {
         var _loc2_:Function = null;
         if(this.animEvents[param1] == null)
         {
            return;
         }
         var _loc3_:uint = 0;
         while(_loc3_ < this.animEvents[param1].length)
         {
            _loc2_ = this.animEvents[param1][_loc3_];
            _loc2_();
            _loc3_ += 2;
         }
      }
      
      public function clearAnimEvents() : void
      {
         this.animEvents = new Object();
      }
      
      public function get AnimEvent() : Object
      {
         return this.animEvents;
      }
      
      public function walkTo(param1:int, param2:int, param3:int) : void
      {
         var _loc4_:Number = NaN;
         var _loc5_:Number = NaN;
         param1 = param1;
         param2 = param2;
         param3 = param3;
         this.op = new Point(x,y);
         this.tp = new Point(param1,param2);
         _loc4_ = Point.distance(this.op,this.tp);
         this.walkTS = new Date().getTime();
         this.walkD = Math.round(1000 * (_loc4_ / (param3 * 22)));
         if(this.walkD > 0)
         {
            _loc5_ = this.op.x - this.tp.x;
            if(_loc5_ < 0)
            {
               this.turn("right");
            }
            else
            {
               this.turn("left");
            }
            if(!this.mcChar.onMove)
            {
               this.mcChar.onMove = true;
               if(this.mcChar.currentLabel != "Walk")
               {
                  this.mcChar.gotoAndPlay("Walk");
               }
            }
            removeEventListener(Event.ENTER_FRAME,this.onEnterFrameWalk);
            addEventListener(Event.ENTER_FRAME,this.onEnterFrameWalk,false,0,true);
         }
      }
      
      public function onEnterFrameWalk(param1:Event) : void
      {
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc4_:* = undefined;
         var _loc5_:* = undefined;
         var _loc6_:Boolean = false;
         var _loc7_:Point = null;
         var _loc8_:Rectangle = null;
         _loc2_ = new Date().getTime();
         _loc3_ = (_loc2_ - this.walkTS) / this.walkD;
         if(_loc3_ > 1)
         {
            _loc3_ = 1;
         }
         if(Point.distance(this.op,this.tp) > 0.5 && this.mcChar.onMove)
         {
            _loc4_ = x;
            _loc5_ = y;
            x = Point.interpolate(this.tp,this.op,_loc3_).x;
            y = Point.interpolate(this.tp,this.op,_loc3_).y;
            if(Math.round(_loc4_) == Math.round(x) && Math.round(_loc5_) == Math.round(y) && _loc2_ > this.walkTS + 50)
            {
               this.stopWalking();
            }
         }
         else
         {
            this.stopWalking();
         }
      }
      
      public function stopWalking() : void
      {
         if(this.mcChar.onMove)
         {
            removeEventListener(Event.ENTER_FRAME,this.onEnterFrameWalk);
         }
         this.mcChar.onMove = false;
         this.mcChar.gotoAndPlay("Idle");
      }
      
      internal function frame1() : *
      {
         this.mcChar.transform.colorTransform = this.CT1;
         this.mcChar.alpha = 0;
         stop();
      }
      
      internal function frame5() : *
      {
         this.mcChar.transform.colorTransform = this.CT1;
         this.mcChar.alpha = 0;
      }
      
      internal function frame10() : *
      {
         this.mcChar.alpha = 0;
      }
      
      internal function frame12() : *
      {
         this.mcChar.transform.colorTransform = this.CT3;
      }
      
      internal function frame13() : *
      {
         this.mcChar.transform.colorTransform = this.CT2;
      }
      
      internal function frame14() : *
      {
         this.mcChar.transform.colorTransform = this.CT1;
      }
      
      internal function frame20() : *
      {
         this.mcChar.transform.colorTransform = this.CT1;
      }
      
      internal function frame23() : *
      {
         stop();
      }
   }
}


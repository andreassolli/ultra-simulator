package EpicDuel
{
   import flash.display.Loader;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.geom.ColorTransform;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.ByteArray;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2185")]
   public class CharacterBase extends MovieClip
   {
      
      public var multicannon:MovieClip;
      
      internal var _loadContext:LoaderContext;
      
      internal var hideCharacter:Boolean;
      
      private var onVehicle:Boolean;
      
      private var flightModuleEquipped:Boolean;
      
      internal var ItemBox:*;
      
      internal var iVeh:int;
      
      internal var _armorId:int;
      
      internal var _armorRecord:*;
      
      internal var charGender:String;
      
      internal var clientClassGender:String;
      
      public var bodyHolder:MovieClip;
      
      private const MALE:String = "M";
      
      private const FEMALE:String = "F";
      
      private const POOL_BODY:String = "Body";
      
      private const POOL_HIP:String = "Hip";
      
      private const POOL_FOREARM_L:String = "ForearmL";
      
      private const POOL_FOREARM_R:String = "ForearmR";
      
      private const POOL_BICEP_L:String = "BicepL";
      
      private const POOL_BICEP_R:String = "BicepR";
      
      private const POOL_SHIN_L:String = "ShinL";
      
      private const POOL_SHIN_R:String = "ShinR";
      
      private const POOL_THIGH_L:String = "ThighL";
      
      private const POOL_THIGH_R:String = "ThighR";
      
      private const POOL_FOOT_L:String = "FootL";
      
      private const POOL_FOOT_R:String = "FootR";
      
      private const POOL_HEAD:String = "Head";
      
      private const POOL_HAIR:String = "Hair";
      
      private const POOL_HAIR_ABOVE:String = "HairAbove";
      
      private const POOL_CORE:String = "Core";
      
      private const POOL_STAFF:String = "Staff";
      
      private const POOL_GUN:String = "Gun";
      
      private const POOL_SWORD:String = "Sword";
      
      private const POOL_CLUB:String = "Club";
      
      private const POOL_WRIST_R:String = "WristR";
      
      private const POOL_WRIST_L:String = "WristL";
      
      private const POOL_AUXILIARY:String = "Auxiliary";
      
      private const POOL_CRAFT:String = "Vehicle";
      
      private const POOL_ROBOT:String = "Robot";
      
      private const FACE_STATUS_NORMAL:String = "normal";
      
      private const FACE_STATUS_READY:String = "ready";
      
      private const FACE_STATUS_ATTACK:String = "attack";
      
      private const FACE_STATUS_HURT:String = "hurt";
      
      private const FACE_STATUS_DEAD:String = "dead";
      
      private var _savedColorPrimary:int;
      
      private var _savedColorSecondary:int;
      
      private var _savedColorAccent:int;
      
      private var _savedColorAccent2:int;
      
      public var _ctPrimary:ColorTransform;
      
      private var _ctSecondary:ColorTransform;
      
      private var _ctHair:ColorTransform;
      
      private var _ctSkin:ColorTransform;
      
      private var _ctAccent:ColorTransform;
      
      private var _ctAccent2:ColorTransform;
      
      private var _ctEye:ColorTransform;
      
      private var charPri:String = "000000";
      
      private var charSec:String = "000000";
      
      private var charHair:String = "000000";
      
      private var charSkin:String = "000000";
      
      private var charAccnt:String = "000000";
      
      private var charAccnt2:String = "000000";
      
      private var charEye:String = "000000";
      
      public var _params:Object;
      
      public var _classPrefix:String;
      
      public var head:MovieClip;
      
      public var eye:MovieClip;
      
      public var mouth:MovieClip;
      
      public var hairAbove:MovieClip;
      
      public var hair:MovieClip;
      
      public var ear:MovieClip;
      
      public var mainBody:MovieClip;
      
      public var hip:MovieClip;
      
      public var bicepR:MovieClip;
      
      public var bicepL:MovieClip;
      
      public var forearmR:MovieClip;
      
      public var forearmL:MovieClip;
      
      public var shinR:MovieClip;
      
      public var shinL:MovieClip;
      
      public var thighR:MovieClip;
      
      public var thighL:MovieClip;
      
      public var footR:MovieClip;
      
      public var footL:MovieClip;
      
      public var weapon1:MovieClip;
      
      public var weapon2:MovieClip;
      
      public var weapon3:MovieClip;
      
      public var club:MovieClip;
      
      public var sword:MovieClip;
      
      public var gun:MovieClip;
      
      public var staff:MovieClip;
      
      public var wristR:MovieClip;
      
      public var wristL:MovieClip;
      
      public var auxiliary:MovieClip;
      
      public var gunHolder:MovieClip;
      
      public var auxiliaryHolder:MovieClip;
      
      public var craft:MovieClip;
      
      public var grenadeLoader:MovieClip;
      
      private var headHolder:MovieClip;
      
      private var eyeHolder:MovieClip;
      
      private var mouthHolder:MovieClip;
      
      private var hairHolder:MovieClip;
      
      private var hairAboveHolder:MovieClip;
      
      private var hipHolder:MovieClip;
      
      private var bicepRHolder:MovieClip;
      
      private var bicepLHolder:MovieClip;
      
      private var forearmRHolder:MovieClip;
      
      private var forearmLHolder:MovieClip;
      
      private var shinRHolder:MovieClip;
      
      private var shinLHolder:MovieClip;
      
      private var thighRHolder:MovieClip;
      
      private var f_thighRHolder:MovieClip;
      
      private var thighLHolder:MovieClip;
      
      private var footRHolder:MovieClip;
      
      private var footLHolder:MovieClip;
      
      private var staffHolder:MovieClip;
      
      private var swordHolder:MovieClip;
      
      private var clubHolder:MovieClip;
      
      private var wristRHolder:MovieClip;
      
      private var wristLHolder:MovieClip;
      
      public var craftHolder:MovieClip;
      
      private var Ancestor:MovieClip;
      
      public var queued:Array;
      
      private var tLoader:Loader;
      
      private var AD:ApplicationDomain;
      
      private var LC:LoaderContext;
      
      private var onMove:Boolean = false;
      
      private var op:*;
      
      private var tp:*;
      
      private var walkTS:*;
      
      private var walkD:*;
      
      public function CharacterBase(param1:MovieClip)
      {
         var _loc4_:* = undefined;
         var _loc5_:* = undefined;
         this.queued = [];
         this.tLoader = new Loader();
         super();
         addFrameScript(0,this.frame1,8,this.frame9,20,this.frame21,32,this.frame33,95,this.frame96,134,this.frame135,138,this.frame139,144,this.frame145,154,this.frame155,162,this.frame163,192,this.frame193,219,this.frame220,249,this.frame250,279,this.frame280,287,this.frame288,294,this.frame295,315,this.frame316,323,this.frame324,328,this.frame329,345,this.frame346,368,this.frame369,380,this.frame381,388,this.frame389,392,this.frame393,422,this.frame423,436,this.frame437,456,this.frame457,463,this.frame464,468,this.frame469,482,this.frame483,505,this.frame506,518,this.frame519,525,this.frame526,530,this.frame531,555,this.frame556,563,this.frame564,577,this.frame578,583,this.frame584,586,this.frame587,603,this.frame604,624,this.frame625,638,this.frame639,644,this.frame645,647,this.frame648,673,this.frame674,680,this.frame681,711,this.frame712,725,this.frame726,751,this.frame752,767,this.frame768,788,this.frame789,814,this.frame815,876,this.frame877,887,this.frame888,904,this.frame905,933,this.frame934
         ,953,this.frame954,985,this.frame986,1006,this.frame1007,1021,this.frame1022,1036,this.frame1037,1049,this.frame1050,1061,this.frame1062,1074,this.frame1075,1086,this.frame1087,1100,this.frame1101,1112,this.frame1113,1129,this.frame1130,1144,this.frame1145,1161,this.frame1162,1187,this.frame1188,1212,this.frame1213,1232,this.frame1233,1260,this.frame1261,1303,this.frame1304,1354,this.frame1355,1413,this.frame1414,1449,this.frame1450,1481,this.frame1482,1507,this.frame1508,1521,this.frame1522,1536,this.frame1537,1551,this.frame1552,1569,this.frame1570,1625,this.frame1626,1648,this.frame1649,1683,this.frame1684,1694,this.frame1695,1781,this.frame1782,1835,this.frame1836,1861,this.frame1862,1917,this.frame1918,1972,this.frame1973,1997,this.frame1998,2043,this.frame2044,2099,this.frame2100,2138,this.frame2139,2154,this.frame2155,2179,this.frame2180,2200,this.frame2201,2276,this.frame2277,2280,this.frame2281,2293,this.frame2294,2310,this.frame2311,2329,this.frame2330,2359,this.frame2360,2374
         ,this.frame2375,2384,this.frame2385,2427,this.frame2428,2450,this.frame2451,2476,this.frame2477,2502,this.frame2503,2522,this.frame2523,2553,this.frame2554,2587,this.frame2588,2607,this.frame2608,2636,this.frame2637,2717,this.frame2718,2797,this.frame2798,2857,this.frame2858,2916,this.frame2917,2917,this.frame2918,2930,this.frame2931,2931,this.frame2932,2944,this.frame2945,2951,this.frame2952,2970,this.frame2971,3003,this.frame3004,3142,this.frame3143,3257,this.frame3258,3265,this.frame3266,3301,this.frame3302,3307,this.frame3308,3310,this.frame3311,3327,this.frame3328,3348,this.frame3349,3385,this.frame3386,3391,this.frame3392,3422,this.frame3423,3493,this.frame3494,3503,this.frame3504,3604,this.frame3605,3606,this.frame3607,3612,this.frame3613,3625,this.frame3626,3638,this.frame3639,3649,this.frame3650,3658,this.frame3659,3669,this.frame3670,3683,this.frame3684,3704,this.frame3705,3724,this.frame3725,3781,this.frame3782,3795,this.frame3796,3822,this.frame3823,3834,this.frame3835,3861,this
         .frame3862,3868,this.frame3869,3899,this.frame3900,3913,this.frame3914,3955,this.frame3956,3976,this.frame3977,4002,this.frame4003,4064,this.frame4065,4095,this.frame4096,4110,this.frame4111,4135,this.frame4136,4151,this.frame4152,4167,this.frame4168,4180,this.frame4181,4276,this.frame4277,4297,this.frame4298,4328,this.frame4329,4350,this.frame4351,4377,this.frame4378,4444,this.frame4445,4478,this.frame4479,4549,this.frame4550,4640,this.frame4641,4651,this.frame4652,4661,this.frame4662,4682,this.frame4683,4688,this.frame4689,4694,this.frame4695,4700,this.frame4701,4714,this.frame4715,4740,this.frame4741,4750,this.frame4751,4849,this.frame4850,4869,this.frame4870,4885,this.frame4886,4897,this.frame4898,4928,this.frame4929,4961,this.frame4962,4981,this.frame4982,5005,this.frame5006,5031,this.frame5032,5060,this.frame5061,5089,this.frame5090,5141,this.frame5142,5192,this.frame5193,5216,this.frame5217,5238,this.frame5239,5261,this.frame5262,5283,this.frame5284,5305,this.frame5306,5328,this.frame5329
         ,5390,this.frame5391,5444,this.frame5445,5544,this.frame5545,5583,this.frame5584,5657,this.frame5658,5751,this.frame5752,5854,this.frame5855,5917,this.frame5918,5985,this.frame5986,6034,this.frame6035,6051,this.frame6052,6079,this.frame6080,6104,this.frame6105,6148,this.frame6149,6230,this.frame6231,6331,this.frame6332,6350,this.frame6351,6397,this.frame6398,6423,this.frame6424,6492,this.frame6493,6602,this.frame6603,6668,this.frame6669,6728,this.frame6729,6739,this.frame6740,6764,this.frame6765,6776,this.frame6777,6802,this.frame6803,6868,this.frame6869,6921,this.frame6922,6992,this.frame6993,7062,this.frame7063,7104,this.frame7105,7161,this.frame7162,7223,this.frame7224,7305,this.frame7306,7382,this.frame7383,7544,this.frame7545,7556,this.frame7557,7623,this.frame7624,7665,this.frame7666,7734,this.frame7735,7772,this.frame7773,7834,this.frame7835,7903,this.frame7904,8011,this.frame8012,8070,this.frame8071,8136,this.frame8137,8167,this.frame8168,8251,this.frame8252,8333,this.frame8334,8422
         ,this.frame8423,8437,this.frame8438,8507,this.frame8508,8523,this.frame8524,8562,this.frame8563,8596,this.frame8597,8638,this.frame8639,8704,this.frame8705,8722,this.frame8723,8750,this.frame8751,8775,this.frame8776,8830,this.frame8831,8871,this.frame8872,8916,this.frame8917,8923,this.frame8924,8929,this.frame8930,8939,this.frame8940,8947,this.frame8948,8977,this.frame8978,8981,this.frame8982,8987,this.frame8988,9026,this.frame9027,9030,this.frame9031,9036,this.frame9037,9046,this.frame9047,9054,this.frame9055,9084,this.frame9085,9088,this.frame9089,9094,this.frame9095,9142,this.frame9143,9183,this.frame9184,9187,this.frame9188,9193,this.frame9194,9203,this.frame9204,9211,this.frame9212,9241,this.frame9242,9245,this.frame9246,9250,this.frame9251,9297,this.frame9298,9338,this.frame9339,9342,this.frame9343,9348,this.frame9349,9358,this.frame9359,9365,this.frame9366,9395,this.frame9396,9400,this.frame9401,9406,this.frame9407,9453,this.frame9454,9493,this.frame9494,9497,this.frame9498,9511,this
         .frame9512,9519,this.frame9520,9549,this.frame9550,9553,this.frame9554,9561,this.frame9562,9585,this.frame9586,9603,this.frame9604,9681,this.frame9682,9716,this.frame9717,9773,this.frame9774,9892,this.frame9893,9903,this.frame9904,9913,this.frame9914,9931,this.frame9932,9940,this.frame9941,9949,this.frame9950,9960,this.frame9961,9986,this.frame9987,10001,this.frame10002,10065,this.frame10066,10081,this.frame10082);
         this.Ancestor = param1;
         this.scaleX = 0.5;
         this.scaleY = 0.5;
         this.visible = true;
         var _loc2_:Array = [Weapon_Grenade,Craft,Thigh_R_Female,Weapon_Wrist_L,Weapon_Wrist_R,Weapon_Staff];
         var _loc3_:int = 0;
         while(_loc3_ < numChildren)
         {
            _loc4_ = getChildAt(_loc3_) as MovieClip;
            this.setHolder(_loc4_);
            for each(_loc5_ in _loc2_)
            {
               if(_loc4_ is _loc5_)
               {
                  _loc4_.visible = false;
               }
            }
            _loc3_++;
         }
         this._ctPrimary = new ColorTransform();
         this._ctSecondary = new ColorTransform();
         this._ctHair = new ColorTransform();
         this._ctSkin = new ColorTransform();
         this._ctAccent = new ColorTransform();
         this._ctAccent2 = new ColorTransform();
         this._ctEye = new ColorTransform();
         this._ctPrimary.color = parseInt("0x" + this.charPri,16);
         this._ctSecondary.color = parseInt("0x" + this.charSec,16);
         this._ctHair.color = parseInt("0x" + this.charHair,16);
         this._ctSkin.color = parseInt("0x" + this.charSkin,16);
         this._ctAccent.color = parseInt("0x" + this.charAccnt,16);
         this._ctAccent2.color = parseInt("0x" + this.charAccnt2,16);
         this._ctEye.color = parseInt("0x" + this.charEye,16);
         this.setColors();
         this.tLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,this.onLoadError,false,0,true);
      }
      
      public function get ActiveSet() : *
      {
         return this.Ancestor.ActiveSet;
      }
      
      public function handleVisibilities() : void
      {
         var _loc3_:* = undefined;
         var _loc4_:* = undefined;
         var _loc1_:Array = [this.hipHolder,this.bicepRHolder,this.bicepLHolder,this.forearmRHolder,this.forearmLHolder,this.shinRHolder,this.shinLHolder,this.thighLHolder,this.footRHolder,this.footLHolder,this.bodyHolder];
         if(this.ActiveSet["thighType"] == "Male Thigh")
         {
            _loc1_.push(this.thighRHolder);
         }
         else
         {
            _loc1_.push(this.f_thighRHolder);
         }
         var _loc2_:int = 0;
         while(_loc2_ < numChildren)
         {
            _loc3_ = getChildAt(_loc2_) as MovieClip;
            for each(_loc4_ in _loc1_)
            {
               if(_loc3_ == _loc4_)
               {
                  _loc3_.visible = this.ActiveSet["itemShow"]["Player"];
               }
            }
            _loc2_++;
         }
         this.swordHolder.visible = false;
         this.staffHolder.visible = false;
         this.wristLHolder.visible = false;
         this.wristRHolder.visible = false;
         if(this.ActiveSet["itemShow"]["Primary"])
         {
            switch(this.ActiveSet["weaponType"])
            {
               case "Blade":
                  this.swordHolder.visible = true;
                  break;
               case "Staff":
                  this.staffHolder.visible = true;
                  break;
               case "Wrist":
                  this.wristLHolder.visible = true;
                  this.wristRHolder.visible = true;
            }
         }
         if(this.gunHolder)
         {
            this.gunHolder.visible = this.ActiveSet["itemShow"]["Secondary"];
         }
         if(this.auxiliaryHolder)
         {
            this.auxiliaryHolder.visible = this.ActiveSet["itemShow"]["Auxiliary"];
         }
         if(this.hairHolder)
         {
            this.hairHolder.visible = this.ActiveSet["itemShow"]["Hair"];
         }
         if(this.hairAboveHolder)
         {
            this.hairAboveHolder.visible = this.ActiveSet["itemShow"]["Hair Above"];
         }
         if(this.headHolder)
         {
            this.headHolder.visible = this.ActiveSet["itemShow"]["Head"];
         }
         if(this.craftHolder)
         {
            this.craftHolder.visible = this.ActiveSet["itemShow"]["Craft"];
         }
         if(this.craftHolder.visible)
         {
            gotoAndPlay("craft_idle");
         }
         else
         {
            gotoAndPlay("still");
         }
      }
      
      public function swapThighs() : void
      {
         this.thighRHolder.visible = false;
         this.f_thighRHolder.visible = false;
         switch(this.ActiveSet["thighType"])
         {
            case "Male Thigh":
               this.thighRHolder.visible = true;
               break;
            case "Female Thigh":
               this.f_thighRHolder.visible = true;
         }
      }
      
      public function swapPrimary() : void
      {
         this.swordHolder.visible = false;
         this.staffHolder.visible = false;
         this.wristLHolder.visible = false;
         this.wristRHolder.visible = false;
         if(this.ActiveSet["itemShow"]["Primary"])
         {
            switch(this.ActiveSet["weaponType"])
            {
               case "Blade":
                  this.swordHolder.visible = true;
                  break;
               case "Staff":
                  this.staffHolder.visible = true;
                  break;
               case "Wrist":
                  this.wristLHolder.visible = true;
                  this.wristRHolder.visible = true;
            }
         }
      }
      
      public function setHolder(param1:MovieClip) : void
      {
         if(param1 is Bicep_R)
         {
            this.bicepRHolder = param1;
         }
         else if(param1 is Bicep_L)
         {
            this.bicepLHolder = param1;
         }
         else if(param1 is Forearm_R)
         {
            this.forearmRHolder = param1;
         }
         else if(param1 is Forearm_L)
         {
            this.forearmLHolder = param1;
         }
         else if(param1 is Body)
         {
            this.bodyHolder = param1;
         }
         else if(param1 is Hip)
         {
            this.hipHolder = param1;
         }
         else if(param1 is Thigh_R_Female)
         {
            this.f_thighRHolder = param1;
         }
         else if(param1 is Thigh_R)
         {
            this.thighRHolder = param1;
         }
         else if(param1 is Thigh_L)
         {
            this.thighLHolder = param1;
         }
         else if(param1 is Shin_R)
         {
            this.shinRHolder = param1;
         }
         else if(param1 is Shin_L)
         {
            this.shinLHolder = param1;
         }
         else if(param1 is Foot_L)
         {
            this.footLHolder = param1;
         }
         else if(param1 is Foot_R)
         {
            this.footRHolder = param1;
         }
         else if(param1 is Head)
         {
            this.headHolder = param1;
         }
         else if(param1 is HairAbove)
         {
            this.hairAboveHolder = param1;
         }
         else if(param1 is Craft)
         {
            this.craftHolder = param1;
         }
         else if(param1 is Weapon_Blade)
         {
            param1.mouseEnabled = false;
            param1.mouseChildren = false;
            this.swordHolder = param1;
         }
         else if(param1 is Weapon_Gun)
         {
            param1.mouseEnabled = false;
            param1.mouseChildren = false;
            this.gunHolder = param1;
         }
         else if(param1 is Weapon_Wrist_L)
         {
            param1.mouseEnabled = false;
            param1.mouseChildren = false;
            this.wristLHolder = param1;
         }
         else if(param1 is Weapon_Wrist_R)
         {
            param1.mouseEnabled = false;
            param1.mouseChildren = false;
            this.wristRHolder = param1;
         }
         else if(param1 is Weapon_Staff)
         {
            param1.mouseEnabled = false;
            param1.mouseChildren = false;
            this.staffHolder = param1;
         }
         else if(param1 is Weapon_Auxiliary)
         {
            param1.mouseEnabled = false;
            param1.mouseChildren = false;
            this.auxiliaryHolder = param1;
         }
      }
      
      public function setColors(param1:Object = null) : void
      {
         var _loc3_:* = undefined;
         if(param1 == null)
         {
            return;
         }
         if(param1["intColorPrimary"])
         {
            this._ctPrimary.color = param1.intColorPrimary;
            this._savedColorPrimary = this._ctPrimary.color;
         }
         if(param1["intColorSecondary"])
         {
            this._ctSecondary.color = param1.intColorSecondary;
            this._savedColorSecondary = this._ctSecondary.color;
         }
         if(param1["intColorHair"])
         {
            this._ctHair.color = param1.intColorHair;
         }
         if(param1["intColorSkin"])
         {
            this._ctSkin.color = param1.intColorSkin;
         }
         if(param1["intColorAccent"])
         {
            this._ctAccent.color = param1.intColorAccent;
            this._savedColorAccent = this._ctAccent.color;
         }
         if(param1["intColorAccent 2"])
         {
            this._ctAccent2.color = param1["intColorAccent 2"];
            this._savedColorAccent2 = this._ctAccent2.color;
         }
         if(param1["intColorEye"])
         {
            this._ctEye.color = param1.intColorEye;
         }
         var _loc2_:Array = [this.staff,this.sword,this.gun,this.auxiliary,this.wristR,this.wristL,this.mainBody,this.hip,this.forearmR,this.forearmL,this.bicepR,this.bicepL,this.shinR,this.shinL,this.thighR,this.thighL,this.footR,this.footL,this.head,this.hair,this.hairAbove,this.craft];
         for each(_loc3_ in _loc2_)
         {
            this.searchForSubPartsToColor(_loc3_);
         }
      }
      
      public function queueLoad(param1:String, param2:*) : void
      {
         this.queued.push({
            "value":param1,
            "callback":param2
         });
      }
      
      public function processQueue() : void
      {
         if(this.queued.length < 1)
         {
            return;
         }
         this.load(this.queued[0].value,this.queued[0].callback);
      }
      
      public function load(param1:String, param2:*) : *
      {
         var _loc3_:ByteArray = new ByteArray();
         var _loc4_:File = File.applicationDirectory.resolvePath(param1);
         var _loc5_:FileStream = new FileStream();
         _loc5_.open(_loc4_,FileMode.READ);
         _loc5_.readBytes(_loc3_);
         _loc5_.close();
         this.tLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,param2,false,0,true);
         this.AD = new ApplicationDomain();
         this.LC = new LoaderContext(false,this.AD);
         this.LC.allowLoadBytesCodeExecution = true;
         this.tLoader.loadBytes(_loc3_,this.LC);
      }
      
      private function onLoadError(param1:IOErrorEvent) : void
      {
         this.tLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE,this.queued[0].callback);
         this.queued.shift();
         this.processQueue();
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
         if(param2 == null)
         {
            param2 = {};
         }
         var _loc3_:Vector.<String> = this.tLoader.contentLoaderInfo.applicationDomain.getQualifiedDefinitionNames();
         if(_loc3_.length < 1)
         {
            return null;
         }
         if(param2.hasOwnProperty("or"))
         {
            if(this.tLoader.contentLoaderInfo.applicationDomain.hasDefinition(param1))
            {
               return this.tLoader.contentLoaderInfo.applicationDomain.getDefinition(param1) as Class;
            }
         }
         var _loc5_:String = "";
         var _loc6_:Array = [];
         for each(_loc4_ in _loc3_)
         {
            if(param2.hasOwnProperty("suffix"))
            {
               if(_loc4_.indexOf(param1) == _loc4_.length - param1.length)
               {
                  _loc6_.push(_loc4_);
               }
            }
            else if(param2.hasOwnProperty("prefix"))
            {
               if(_loc4_.indexOf(param1) == 0)
               {
                  _loc6_.push(_loc4_);
               }
            }
            else if(_loc4_.indexOf(param1) != -1)
            {
               _loc6_.push(_loc4_);
            }
         }
         if(_loc6_.length < 1 && _loc3_.length > 0)
         {
            return null;
         }
         if(_loc6_.length > 0)
         {
            _loc5_ = _loc6_[0];
         }
         if(_loc6_.length > 1)
         {
            this.reportLinkages(_loc3_);
         }
         return this.tLoader.contentLoaderInfo.applicationDomain.getDefinition(_loc5_) as Class;
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
      
      public function assetCompleteHandler(param1:Event) : void
      {
         var _loc2_:MovieClip = MovieClip(param1.target.content);
         var _loc3_:MovieClip = MovieClip(_loc2_.getChildAt(0));
         _loc3_._pool = _loc2_._pool;
         _loc3_._link = _loc2_._link;
         _loc3_._showEar = _loc2_._showEar;
         _loc3_._params = _loc2_._params;
         this.addAssetToHolder(_loc3_);
         this.tLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE,this.assetCompleteHandler);
         this.queued.shift();
         this.processQueue();
      }
      
      private function addAssetToHolder(param1:MovieClip) : void
      {
         var _loc2_:Class = null;
         var _loc3_:MovieClip = null;
         switch(param1._pool)
         {
            case this.POOL_STAFF:
               this.staff = param1;
               if(this.staffHolder.numChildren > 0)
               {
                  this.staffHolder.removeChildAt(0);
               }
               this.staffHolder.addChild(this.staff);
               this.searchForSubPartsToColor(this.staff);
               this.weapon1 = this.staff;
               break;
            case this.POOL_SWORD:
               this.sword = param1;
               if(this.swordHolder.numChildren > 0)
               {
                  this.swordHolder.removeChildAt(0);
               }
               this.swordHolder.addChild(this.sword);
               this.searchForSubPartsToColor(this.sword);
               this.weapon1 = this.sword;
               break;
            case this.POOL_GUN:
               this.gun = param1;
               if(this.gunHolder.numChildren > 0)
               {
                  this.gunHolder.removeChildAt(0);
               }
               this.gunHolder.addChild(this.gun);
               this.searchForSubPartsToColor(this.gun);
               break;
            case this.POOL_AUXILIARY:
               this.auxiliary = param1;
               if(this.auxiliaryHolder.numChildren > 0)
               {
                  this.auxiliaryHolder.removeChildAt(0);
               }
               this.auxiliaryHolder.addChild(this.auxiliary);
               this.searchForSubPartsToColor(this.auxiliary);
               this.weapon3 = this.auxiliary;
               break;
            case this.POOL_WRIST_R:
               this.wristR = param1;
               if(this.wristRHolder.numChildren > 0)
               {
                  this.wristRHolder.removeChildAt(0);
               }
               this.wristRHolder.addChild(this.wristR);
               this.searchForSubPartsToColor(this.wristR);
               this.weapon2 = this.wristR;
               break;
            case this.POOL_WRIST_L:
               this.wristL = param1;
               if(this.wristLHolder.numChildren > 0)
               {
                  this.wristLHolder.removeChildAt(0);
               }
               this.wristLHolder.addChild(this.wristL);
               this.searchForSubPartsToColor(this.wristL);
               this.weapon1 = this.wristL;
               break;
            case this.POOL_BODY:
               this.mainBody = param1;
               if(this.bodyHolder.numChildren > 0)
               {
                  this.bodyHolder.removeChildAt(0);
               }
               this.bodyHolder.addChild(this.mainBody);
               this.searchForSubPartsToColor(this.mainBody);
               break;
            case this.POOL_HIP:
               this.hip = param1;
               if(this.hipHolder.numChildren > 0)
               {
                  this.hipHolder.removeChildAt(0);
               }
               this.hipHolder.addChild(this.hip);
               this.searchForSubPartsToColor(this.hip);
               break;
            case this.POOL_FOREARM_R:
               this.forearmR = param1;
               if(this.forearmRHolder.numChildren > 0)
               {
                  this.forearmRHolder.removeChildAt(0);
               }
               this.forearmRHolder.addChild(this.forearmR);
               this.searchForSubPartsToColor(this.forearmR);
               break;
            case this.POOL_FOREARM_L:
               this.forearmL = param1;
               if(this.forearmLHolder.numChildren > 0)
               {
                  this.forearmLHolder.removeChildAt(0);
               }
               this.forearmLHolder.addChild(this.forearmL);
               this.searchForSubPartsToColor(this.forearmL);
               break;
            case this.POOL_BICEP_R:
               this.bicepR = param1;
               if(this.bicepRHolder.numChildren > 0)
               {
                  this.bicepRHolder.removeChildAt(0);
               }
               this.bicepRHolder.addChild(this.bicepR);
               this.searchForSubPartsToColor(this.bicepR);
               break;
            case this.POOL_BICEP_L:
               this.bicepL = param1;
               if(this.bicepLHolder.numChildren > 0)
               {
                  this.bicepLHolder.removeChildAt(0);
               }
               this.bicepLHolder.addChild(this.bicepL);
               this.searchForSubPartsToColor(this.bicepL);
               break;
            case this.POOL_SHIN_R:
               this.shinR = param1;
               if(this.shinRHolder.numChildren > 0)
               {
                  this.shinRHolder.removeChildAt(0);
               }
               this.shinRHolder.addChild(this.shinR);
               this.searchForSubPartsToColor(this.shinR);
               break;
            case this.POOL_SHIN_L:
               this.shinL = param1;
               if(this.shinLHolder.numChildren > 0)
               {
                  this.shinLHolder.removeChildAt(0);
               }
               this.shinLHolder.addChild(this.shinL);
               this.searchForSubPartsToColor(this.shinL);
               break;
            case this.POOL_THIGH_R:
               this.thighR = param1;
               if(this.thighRHolder.numChildren > 0)
               {
                  this.thighRHolder.removeChildAt(0);
               }
               this.thighRHolder.addChild(this.thighR);
               this.searchForSubPartsToColor(this.thighR);
               _loc2_ = MovieClip(this.thighR).constructor;
               _loc3_ = new _loc2_();
               if(this.f_thighRHolder.numChildren > 0)
               {
                  this.f_thighRHolder.removeChildAt(0);
               }
               this.f_thighRHolder.addChild(_loc3_);
               this.searchForSubPartsToColor(_loc3_);
               break;
            case this.POOL_THIGH_L:
               this.thighL = param1;
               if(this.thighLHolder.numChildren > 0)
               {
                  this.thighLHolder.removeChildAt(0);
               }
               this.thighLHolder.addChild(this.thighL);
               this.searchForSubPartsToColor(this.thighL);
               break;
            case this.POOL_FOOT_R:
               this.footR = param1;
               if(this.footRHolder.numChildren > 0)
               {
                  this.footRHolder.removeChildAt(0);
               }
               this.footRHolder.addChild(this.footR);
               this.searchForSubPartsToColor(this.footR);
               break;
            case this.POOL_FOOT_L:
               this.footL = param1;
               if(this.footLHolder.numChildren > 0)
               {
                  this.footLHolder.removeChildAt(0);
               }
               this.footLHolder.addChild(this.footL);
               this.searchForSubPartsToColor(this.footL);
               break;
            case this.POOL_HEAD:
               this.head = param1;
               if(this.headHolder != null)
               {
                  while(this.headHolder.numChildren > 0)
                  {
                     this.headHolder.removeChildAt(0);
                  }
                  this.headHolder.addChild(this.head);
               }
               if(this.head != null)
               {
                  this.hairHolder = MovieClip(this.head.getChildByName("hair_loader"));
                  this.eye = MovieClip(this.head.getChildByName("eye_mc"));
                  this.mouth = MovieClip(this.head.getChildByName("mouth_mc"));
                  this.ear = MovieClip(this.head.getChildByName("ear_mc"));
               }
               this.searchForSubPartsToColor(this.head);
               break;
            case this.POOL_HAIR:
               this.hair = param1;
               if(this.ear != null && this.hair != null)
               {
                  this.ear.visible = this.hair._showEar;
               }
               if(this.hairHolder != null)
               {
                  if(this.hairHolder.numChildren > 0)
                  {
                     this.hairHolder.removeChildAt(0);
                  }
                  this.hairHolder.addChild(this.hair);
               }
               else
               {
                  this.hairHolder = this.headHolder.addChild(new MovieClip()) as MovieClip;
                  this.hairHolder.addChild(this.hair);
               }
               this.searchForSubPartsToColor(this.hair);
               break;
            case this.POOL_HAIR_ABOVE:
               this.hairAbove = param1;
               if(this.hairAboveHolder.numChildren > 0)
               {
                  this.hairAboveHolder.removeChildAt(0);
               }
               this.hairAboveHolder.addChild(this.hairAbove);
               this.searchForSubPartsToColor(this.hairAbove);
               break;
            case "Craft":
            case this.POOL_CRAFT:
               this.craft = param1;
               if(this.craftHolder.numChildren > 0)
               {
                  this.craftHolder.removeChildAt(0);
               }
               this.craftHolder.addChild(this.craft);
               this.searchForSubPartsToColor(this.craft);
         }
         this.handleVisibilities();
      }
      
      public function searchForSubPartsToColor(param1:MovieClip) : void
      {
         var _loc2_:MovieClip = null;
         if(param1 == null)
         {
            return;
         }
         var _loc3_:uint = 0;
         for(; _loc3_ < param1.numChildren; _loc3_++)
         {
            if(!(param1.getChildAt(_loc3_) is MovieClip))
            {
               continue;
            }
            _loc2_ = param1.getChildAt(_loc3_) as MovieClip;
            switch(_loc2_.name)
            {
               case "primary":
                  _loc2_.transform.colorTransform = this._ctPrimary;
                  break;
               case "secondary":
                  _loc2_.transform.colorTransform = this._ctSecondary;
                  break;
               case "hair":
                  _loc2_.transform.colorTransform = this._ctHair;
                  break;
               case "skin":
                  _loc2_.transform.colorTransform = this._ctSkin;
                  break;
               case "eye":
                  _loc2_.transform.colorTransform = this._ctEye;
                  break;
               case "accent":
                  _loc2_.transform.colorTransform = this._ctAccent;
                  break;
               case "accent2":
                  _loc2_.transform.colorTransform = this._ctAccent2;
                  break;
               default:
                  if(_loc2_.numChildren > 0)
                  {
                     this.searchForSubPartsToColor(_loc2_);
                  }
            }
         }
      }
      
      public function customChangeColor(param1:Array) : void
      {
         this._ctPrimary = new ColorTransform();
         this._ctPrimary.color = param1[Math.floor(Math.random() * param1.length)];
         this._ctSecondary = new ColorTransform();
         this._ctSecondary.color = param1[Math.floor(Math.random() * param1.length)];
         this._ctAccent = new ColorTransform();
         this._ctAccent.color = param1[Math.floor(Math.random() * param1.length)];
         this._ctAccent2 = new ColorTransform();
         this._ctAccent2.color = param1[Math.floor(Math.random() * param1.length)];
         this.searchForSubPartsToColor(this.sword);
         this.searchForSubPartsToColor(this.staff);
         this.searchForSubPartsToColor(this.gun);
         this.searchForSubPartsToColor(this.auxiliary);
         this.searchForSubPartsToColor(this.wristR);
         this.searchForSubPartsToColor(this.wristL);
         this.searchForSubPartsToColor(this.mainBody);
         this.searchForSubPartsToColor(this.forearmL);
         this.searchForSubPartsToColor(this.forearmR);
         this.searchForSubPartsToColor(this.thighL);
         this.searchForSubPartsToColor(this.thighR);
         this.searchForSubPartsToColor(this.shinL);
         this.searchForSubPartsToColor(this.shinR);
         this.searchForSubPartsToColor(this.footL);
         this.searchForSubPartsToColor(this.footR);
         this.searchForSubPartsToColor(this.bicepL);
         this.searchForSubPartsToColor(this.bicepR);
         this.searchForSubPartsToColor(this.hip);
         this.searchForSubPartsToColor(this.head);
      }
      
      public function customRestoreColor() : void
      {
         this._ctPrimary = new ColorTransform();
         this._ctPrimary.color = this._savedColorPrimary;
         this._ctSecondary = new ColorTransform();
         this._ctSecondary.color = this._savedColorSecondary;
         this._ctAccent = new ColorTransform();
         this._ctAccent.color = this._savedColorAccent;
         this._ctAccent2 = new ColorTransform();
         this._ctAccent2.color = this._savedColorAccent2;
         this.searchForSubPartsToColor(this.sword);
         this.searchForSubPartsToColor(this.staff);
         this.searchForSubPartsToColor(this.gun);
         this.searchForSubPartsToColor(this.auxiliary);
         this.searchForSubPartsToColor(this.wristR);
         this.searchForSubPartsToColor(this.wristL);
         this.searchForSubPartsToColor(this.mainBody);
         this.searchForSubPartsToColor(this.forearmL);
         this.searchForSubPartsToColor(this.forearmR);
         this.searchForSubPartsToColor(this.thighL);
         this.searchForSubPartsToColor(this.thighR);
         this.searchForSubPartsToColor(this.shinL);
         this.searchForSubPartsToColor(this.shinR);
         this.searchForSubPartsToColor(this.footL);
         this.searchForSubPartsToColor(this.footR);
         this.searchForSubPartsToColor(this.bicepL);
         this.searchForSubPartsToColor(this.bicepR);
         this.searchForSubPartsToColor(this.hip);
         this.searchForSubPartsToColor(this.head);
      }
      
      private function turn(param1:String) : void
      {
         if(scaleX < 0)
         {
            scaleX *= param1 == "right" ? -1 : 1;
         }
         else
         {
            scaleX *= param1 == "left" ? -1 : 1;
         }
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
            if(!this.onMove)
            {
               this.onMove = true;
               if(!this.ActiveSet["itemShow"]["Craft"])
               {
                  if(currentLabel != "walk")
                  {
                     gotoAndPlay("walk");
                  }
               }
               else if(currentLabel != "craft_move")
               {
                  gotoAndPlay("craft_move");
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
         if(Point.distance(this.op,this.tp) > 0.5 && this.onMove)
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
         if(this.onMove)
         {
            removeEventListener(Event.ENTER_FRAME,this.onEnterFrameWalk);
         }
         this.onMove = false;
         if(!this.ActiveSet["itemShow"]["Craft"])
         {
            gotoAndPlay("still");
         }
         else
         {
            try
            {
               this.craft.gotoAndPlay("off");
            }
            catch(e:*)
            {
            }
            gotoAndPlay("craft_idle");
         }
      }
      
      public function onWeapons() : void
      {
         if(this.weapon1 != null)
         {
            this.weapon1.gotoAndPlay("on");
         }
         if(this.weapon2 != null)
         {
            this.weapon2.gotoAndPlay("on");
         }
         if(this.auxiliary != null)
         {
            this.auxiliary.gotoAndPlay("on");
         }
         if(this.gun != null)
         {
            this.gun.gotoAndPlay("on");
         }
      }
      
      public function offWeapons() : void
      {
         if(this.weapon1 != null)
         {
            this.weapon1.gotoAndPlay("off");
         }
         if(this.weapon2 != null)
         {
            this.weapon2.gotoAndPlay("off");
         }
         if(this.auxiliary != null)
         {
            this.auxiliary.gotoAndPlay("off");
         }
         if(this.gun != null)
         {
            this.gun.gotoAndPlay("off");
         }
      }
      
      public function TIMELINE_ACTOR_gotoAndPlay(param1:MovieClip, param2:*, param3:* = null) : void
      {
         if(param1 == null)
         {
            return;
         }
         try
         {
            param1.gotoAndPlay(param2,param3);
         }
         catch(e:*)
         {
         }
      }
      
      public function TIMELINE_CHARACTER_turnWeapons(param1:String, param2:String = null) : void
      {
         try
         {
            if(this.weapon1 != null)
            {
               this.weapon1.gotoAndPlay(param1,param2);
            }
            if(this.weapon2 != null)
            {
               this.weapon2.gotoAndPlay(param1,param2);
            }
         }
         catch(e:*)
         {
         }
      }
      
      public function TIMELINE_CHARACTER_craftOn() : void
      {
         if(this.craft == null)
         {
            return;
         }
         this.craft.gotoAndPlay("on");
      }
      
      public function TIMELINE_CHARACTER_craftIdle() : void
      {
         gotoAndPlay("craft_idle");
      }
      
      internal function frame1() : *
      {
         stop();
      }
      
      internal function frame9() : *
      {
         stop();
      }
      
      internal function frame21() : *
      {
         stop();
      }
      
      internal function frame33() : *
      {
         stop();
      }
      
      internal function frame96() : *
      {
         gotoAndPlay("ready_idle");
      }
      
      internal function frame135() : *
      {
         gotoAndPlay("stun_idle");
      }
      
      internal function frame139() : *
      {
         gotoAndPlay("stun_idle");
      }
      
      internal function frame145() : *
      {
         stop();
      }
      
      internal function frame155() : *
      {
         gotoAndPlay("idle_hurt");
      }
      
      internal function frame163() : *
      {
         stop();
      }
      
      internal function frame193() : *
      {
         gotoAndPlay("idle_hurt");
      }
      
      internal function frame220() : *
      {
         gotoAndPlay("walk");
      }
      
      internal function frame250() : *
      {
         gotoAndPlay("walk_weapons");
      }
      
      internal function frame280() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
      }
      
      internal function frame288() : *
      {
         stop();
      }
      
      internal function frame295() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("return");
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"on");
      }
      
      internal function frame316() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame324() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame329() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
      }
      
      internal function frame346() : *
      {
         stop();
      }
      
      internal function frame369() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"on");
      }
      
      internal function frame381() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame389() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame393() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
      }
      
      internal function frame423() : *
      {
         stop();
      }
      
      internal function frame437() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("return");
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"on");
      }
      
      internal function frame457() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame464() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame469() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
      }
      
      internal function frame483() : *
      {
         stop();
      }
      
      internal function frame506() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"on");
      }
      
      internal function frame519() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame526() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame531() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
      }
      
      internal function frame556() : *
      {
         stop();
      }
      
      internal function frame564() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("return");
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"on");
      }
      
      internal function frame578() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame584() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame587() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
      }
      
      internal function frame604() : *
      {
         stop();
      }
      
      internal function frame625() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"on");
      }
      
      internal function frame639() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame645() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame648() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
      }
      
      internal function frame674() : *
      {
         stop();
      }
      
      internal function frame681() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("return");
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"on");
      }
      
      internal function frame712() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame726() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
      }
      
      internal function frame752() : *
      {
         stop();
      }
      
      internal function frame768() : *
      {
         stop();
      }
      
      internal function frame789() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"on");
      }
      
      internal function frame815() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame877() : *
      {
         stop();
      }
      
      internal function frame888() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
      }
      
      internal function frame905() : *
      {
         stop();
      }
      
      internal function frame934() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
      }
      
      internal function frame954() : *
      {
         stop();
      }
      
      internal function frame986() : *
      {
         gotoAndPlay("walk_hurt");
      }
      
      internal function frame1007() : *
      {
         stop();
      }
      
      internal function frame1022() : *
      {
         stop();
      }
      
      internal function frame1037() : *
      {
         stop();
      }
      
      internal function frame1050() : *
      {
         stop();
      }
      
      internal function frame1062() : *
      {
         stop();
      }
      
      internal function frame1075() : *
      {
         stop();
      }
      
      internal function frame1087() : *
      {
         stop();
      }
      
      internal function frame1101() : *
      {
         stop();
      }
      
      internal function frame1113() : *
      {
         stop();
      }
      
      internal function frame1130() : *
      {
         stop();
      }
      
      internal function frame1145() : *
      {
         stop();
      }
      
      internal function frame1162() : *
      {
         stop();
      }
      
      internal function frame1188() : *
      {
         stop();
      }
      
      internal function frame1213() : *
      {
         stop();
      }
      
      internal function frame1233() : *
      {
         stop();
      }
      
      internal function frame1261() : *
      {
         stop();
      }
      
      internal function frame1304() : *
      {
         stop();
      }
      
      internal function frame1355() : *
      {
         stop();
      }
      
      internal function frame1414() : *
      {
         stop();
      }
      
      internal function frame1450() : *
      {
         stop();
      }
      
      internal function frame1482() : *
      {
         stop();
      }
      
      internal function frame1508() : *
      {
         stop();
      }
      
      internal function frame1522() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.staff,"charging");
      }
      
      internal function frame1537() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.staff,"fire");
      }
      
      internal function frame1552() : *
      {
         stop();
      }
      
      internal function frame1570() : *
      {
         stop();
      }
      
      internal function frame1626() : *
      {
         stop();
      }
      
      internal function frame1649() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.mouth,"attack");
      }
      
      internal function frame1684() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.mouth,"ready");
      }
      
      internal function frame1695() : *
      {
         stop();
      }
      
      internal function frame1782() : *
      {
         stop();
      }
      
      internal function frame1836() : *
      {
         stop();
      }
      
      internal function frame1862() : *
      {
         stop();
      }
      
      internal function frame1918() : *
      {
         stop();
      }
      
      internal function frame1973() : *
      {
         stop();
      }
      
      internal function frame1998() : *
      {
         stop();
      }
      
      internal function frame2044() : *
      {
         stop();
      }
      
      internal function frame2100() : *
      {
         stop();
      }
      
      internal function frame2139() : *
      {
         stop();
      }
      
      internal function frame2155() : *
      {
         stop();
      }
      
      internal function frame2180() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.auxiliary,"on");
      }
      
      internal function frame2201() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.auxiliary,"fire");
      }
      
      internal function frame2277() : *
      {
         stop();
      }
      
      internal function frame2281() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("return");
      }
      
      internal function frame2294() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.auxiliary,"on");
      }
      
      internal function frame2311() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.auxiliary,"fire");
      }
      
      internal function frame2330() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
      }
      
      internal function frame2360() : *
      {
      }
      
      internal function frame2375() : *
      {
         stop();
      }
      
      internal function frame2385() : *
      {
         stop();
      }
      
      internal function frame2428() : *
      {
         stop();
      }
      
      internal function frame2451() : *
      {
         stop();
      }
      
      internal function frame2477() : *
      {
         stop();
      }
      
      internal function frame2503() : *
      {
         stop();
      }
      
      internal function frame2523() : *
      {
         stop();
      }
      
      internal function frame2554() : *
      {
         stop();
      }
      
      internal function frame2588() : *
      {
         stop();
      }
      
      internal function frame2608() : *
      {
         stop();
      }
      
      internal function frame2637() : *
      {
         stop();
      }
      
      internal function frame2718() : *
      {
         stop();
      }
      
      internal function frame2798() : *
      {
         stop();
      }
      
      internal function frame2858() : *
      {
         stop();
      }
      
      internal function frame2917() : *
      {
         stop();
      }
      
      internal function frame2918() : *
      {
         stop();
      }
      
      internal function frame2931() : *
      {
         stop();
      }
      
      internal function frame2932() : *
      {
         this.TIMELINE_CHARACTER_craftOn();
      }
      
      internal function frame2945() : *
      {
         stop();
      }
      
      internal function frame2952() : *
      {
         this.TIMELINE_CHARACTER_craftIdle();
      }
      
      internal function frame2971() : *
      {
         stop();
      }
      
      internal function frame3004() : *
      {
         gotoAndPlay("craft_idle");
      }
      
      internal function frame3143() : *
      {
         stop();
      }
      
      internal function frame3258() : *
      {
         stop();
      }
      
      internal function frame3266() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("return");
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"on");
      }
      
      internal function frame3302() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame3308() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame3311() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
      }
      
      internal function frame3328() : *
      {
         stop();
      }
      
      internal function frame3349() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"on");
      }
      
      internal function frame3386() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame3392() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame3423() : *
      {
         stop();
      }
      
      internal function frame3494() : *
      {
         stop();
      }
      
      internal function frame3504() : *
      {
         this.visible = false;
      }
      
      internal function frame3605() : *
      {
         stop();
      }
      
      internal function frame3607() : *
      {
         this.visible = true;
      }
      
      internal function frame3613() : *
      {
         stop();
      }
      
      internal function frame3626() : *
      {
         stop();
      }
      
      internal function frame3639() : *
      {
         stop();
      }
      
      internal function frame3650() : *
      {
         stop();
      }
      
      internal function frame3659() : *
      {
         stop();
      }
      
      internal function frame3670() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("return");
      }
      
      internal function frame3684() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.auxiliary,"on");
      }
      
      internal function frame3705() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.auxiliary,"fire");
      }
      
      internal function frame3725() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
      }
      
      internal function frame3782() : *
      {
         stop();
      }
      
      internal function frame3796() : *
      {
         this.multicannon.gotoAndPlay("activate");
      }
      
      internal function frame3823() : *
      {
         this.multicannon.gotoAndPlay("fire");
      }
      
      internal function frame3835() : *
      {
         this.multicannon.gotoAndPlay("retract");
      }
      
      internal function frame3862() : *
      {
         stop();
      }
      
      internal function frame3869() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("return");
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"on");
      }
      
      internal function frame3900() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame3914() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
      }
      
      internal function frame3956() : *
      {
         stop();
      }
      
      internal function frame3977() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"on");
      }
      
      internal function frame4003() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame4065() : *
      {
         stop();
      }
      
      internal function frame4096() : *
      {
         stop();
      }
      
      internal function frame4111() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("return");
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"on");
      }
      
      internal function frame4136() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"fire");
      }
      
      internal function frame4152() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"off");
      }
      
      internal function frame4168() : *
      {
         stop();
      }
      
      internal function frame4181() : *
      {
         stop();
      }
      
      internal function frame4277() : *
      {
         stop();
      }
      
      internal function frame4298() : *
      {
         this.multicannon.gotoAndPlay("activate");
      }
      
      internal function frame4329() : *
      {
         this.multicannon.gotoAndPlay("fire");
      }
      
      internal function frame4351() : *
      {
         this.multicannon.gotoAndPlay("retract");
      }
      
      internal function frame4378() : *
      {
         stop();
      }
      
      internal function frame4445() : *
      {
         stop();
      }
      
      internal function frame4479() : *
      {
         stop();
      }
      
      internal function frame4550() : *
      {
         stop();
      }
      
      internal function frame4641() : *
      {
         stop();
      }
      
      internal function frame4652() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("return");
      }
      
      internal function frame4662() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.auxiliary,"on");
      }
      
      internal function frame4683() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.auxiliary,"fire");
      }
      
      internal function frame4689() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.auxiliary,"fire");
      }
      
      internal function frame4695() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.auxiliary,"fire");
      }
      
      internal function frame4701() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.auxiliary,"fire");
      }
      
      internal function frame4715() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
      }
      
      internal function frame4741() : *
      {
         stop();
      }
      
      internal function frame4751() : *
      {
      }
      
      internal function frame4850() : *
      {
         stop();
      }
      
      internal function frame4870() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
      }
      
      internal function frame4886() : *
      {
         stop();
      }
      
      internal function frame4898() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
      }
      
      internal function frame4929() : *
      {
         stop();
      }
      
      internal function frame4962() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
      }
      
      internal function frame4982() : *
      {
         stop();
      }
      
      internal function frame5006() : *
      {
         stop();
      }
      
      internal function frame5032() : *
      {
         stop();
      }
      
      internal function frame5061() : *
      {
         stop();
      }
      
      internal function frame5090() : *
      {
         stop();
      }
      
      internal function frame5142() : *
      {
         stop();
      }
      
      internal function frame5193() : *
      {
         stop();
      }
      
      internal function frame5217() : *
      {
         stop();
      }
      
      internal function frame5239() : *
      {
         stop();
      }
      
      internal function frame5262() : *
      {
         stop();
      }
      
      internal function frame5284() : *
      {
         stop();
      }
      
      internal function frame5306() : *
      {
         stop();
      }
      
      internal function frame5329() : *
      {
         stop();
      }
      
      internal function frame5391() : *
      {
         stop();
      }
      
      internal function frame5445() : *
      {
         stop();
      }
      
      internal function frame5545() : *
      {
         stop();
      }
      
      internal function frame5584() : *
      {
         stop();
      }
      
      internal function frame5658() : *
      {
         stop();
      }
      
      internal function frame5752() : *
      {
         stop();
      }
      
      internal function frame5855() : *
      {
         stop();
      }
      
      internal function frame5918() : *
      {
         stop();
      }
      
      internal function frame5986() : *
      {
         stop();
      }
      
      internal function frame6035() : *
      {
         stop();
      }
      
      internal function frame6052() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.staff,"charging");
      }
      
      internal function frame6080() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.staff,"fire");
      }
      
      internal function frame6105() : *
      {
         stop();
      }
      
      internal function frame6149() : *
      {
         stop();
      }
      
      internal function frame6231() : *
      {
         stop();
      }
      
      internal function frame6332() : *
      {
         stop();
      }
      
      internal function frame6351() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.mouth,"attack");
      }
      
      internal function frame6398() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.mouth,"ready");
      }
      
      internal function frame6424() : *
      {
         stop();
      }
      
      internal function frame6493() : *
      {
         stop();
      }
      
      internal function frame6603() : *
      {
         stop();
      }
      
      internal function frame6669() : *
      {
         stop();
      }
      
      internal function frame6729() : *
      {
         stop();
      }
      
      internal function frame6740() : *
      {
         this.multicannon.gotoAndPlay("activate");
      }
      
      internal function frame6765() : *
      {
         this.multicannon.gotoAndPlay("fire");
      }
      
      internal function frame6777() : *
      {
         this.multicannon.gotoAndPlay("retract");
      }
      
      internal function frame6803() : *
      {
         stop();
      }
      
      internal function frame6869() : *
      {
         stop();
      }
      
      internal function frame6922() : *
      {
         stop();
      }
      
      internal function frame6993() : *
      {
         stop();
      }
      
      internal function frame7063() : *
      {
         stop();
      }
      
      internal function frame7105() : *
      {
         stop();
      }
      
      internal function frame7162() : *
      {
         stop();
      }
      
      internal function frame7224() : *
      {
         stop();
      }
      
      internal function frame7306() : *
      {
         stop();
      }
      
      internal function frame7383() : *
      {
         stop();
      }
      
      internal function frame7545() : *
      {
         stop();
      }
      
      internal function frame7557() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.staff,"charging");
      }
      
      internal function frame7624() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.staff,"fire");
      }
      
      internal function frame7666() : *
      {
         stop();
      }
      
      internal function frame7735() : *
      {
         stop();
      }
      
      internal function frame7773() : *
      {
         stop();
      }
      
      internal function frame7835() : *
      {
         stop();
      }
      
      internal function frame7904() : *
      {
         stop();
      }
      
      internal function frame8012() : *
      {
         stop();
      }
      
      internal function frame8071() : *
      {
         stop();
      }
      
      internal function frame8137() : *
      {
         stop();
      }
      
      internal function frame8168() : *
      {
         stop();
      }
      
      internal function frame8252() : *
      {
         stop();
      }
      
      internal function frame8334() : *
      {
         stop();
      }
      
      internal function frame8423() : *
      {
         stop();
      }
      
      internal function frame8438() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("return");
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"on");
      }
      
      internal function frame8508() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
         this.TIMELINE_ACTOR_gotoAndPlay(this.gun,"off");
      }
      
      internal function frame8524() : *
      {
         stop();
      }
      
      internal function frame8563() : *
      {
         stop();
      }
      
      internal function frame8597() : *
      {
         stop();
      }
      
      internal function frame8639() : *
      {
         stop();
      }
      
      internal function frame8705() : *
      {
         stop();
      }
      
      internal function frame8723() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.staff,"charging");
      }
      
      internal function frame8751() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.staff,"fire");
      }
      
      internal function frame8776() : *
      {
         stop();
      }
      
      internal function frame8831() : *
      {
         stop();
      }
      
      internal function frame8872() : *
      {
         gotoAndPlay("ready_idle_blades");
      }
      
      internal function frame8917() : *
      {
         gotoAndPlay("ready_idle_katana");
      }
      
      internal function frame8924() : *
      {
         gotoAndPlay("stun_idle");
      }
      
      internal function frame8930() : *
      {
         stop();
      }
      
      internal function frame8940() : *
      {
         gotoAndPlay("idle_hurt");
      }
      
      internal function frame8948() : *
      {
         stop();
      }
      
      internal function frame8978() : *
      {
         gotoAndPlay("idle_hurt_blades");
      }
      
      internal function frame8982() : *
      {
         gotoAndPlay("ready_idle_blades");
      }
      
      internal function frame8988() : *
      {
         gotoAndPlay("ready_idle");
      }
      
      internal function frame9027() : *
      {
         gotoAndPlay("stun_idle_katana");
      }
      
      internal function frame9031() : *
      {
         gotoAndPlay("stun_idle_katana");
      }
      
      internal function frame9037() : *
      {
         stop();
      }
      
      internal function frame9047() : *
      {
         gotoAndPlay("idle_hurt_katana");
      }
      
      internal function frame9055() : *
      {
         stop();
      }
      
      internal function frame9085() : *
      {
         gotoAndPlay("idle_hurt_katana");
      }
      
      internal function frame9089() : *
      {
         gotoAndPlay("ready_idle_katana");
      }
      
      internal function frame9095() : *
      {
         gotoAndPlay("ready_idle");
      }
      
      internal function frame9143() : *
      {
         gotoAndPlay("ready_idle_club");
      }
      
      internal function frame9184() : *
      {
         gotoAndPlay("stun_idle_club");
      }
      
      internal function frame9188() : *
      {
         gotoAndPlay("stun_idle_club");
      }
      
      internal function frame9194() : *
      {
         stop();
      }
      
      internal function frame9204() : *
      {
         gotoAndPlay("idle_hurt_club");
      }
      
      internal function frame9212() : *
      {
         stop();
      }
      
      internal function frame9242() : *
      {
         gotoAndPlay("idle_hurt_club");
      }
      
      internal function frame9246() : *
      {
         gotoAndPlay("ready_idle_club");
      }
      
      internal function frame9251() : *
      {
         gotoAndPlay("ready_idle");
      }
      
      internal function frame9298() : *
      {
         gotoAndPlay("ready_idle_staff");
      }
      
      internal function frame9339() : *
      {
         gotoAndPlay("stun_idle_staff");
      }
      
      internal function frame9343() : *
      {
         gotoAndPlay("stun_idle_staff");
      }
      
      internal function frame9349() : *
      {
         stop();
      }
      
      internal function frame9359() : *
      {
         gotoAndPlay("idle_hurt_staff");
      }
      
      internal function frame9366() : *
      {
         stop();
      }
      
      internal function frame9396() : *
      {
         gotoAndPlay("ready_idle_staff");
      }
      
      internal function frame9401() : *
      {
         gotoAndPlay("ready_idle_staff");
      }
      
      internal function frame9407() : *
      {
         gotoAndPlay("ready_idle");
      }
      
      internal function frame9454() : *
      {
         gotoAndPlay("ready_idle_sword");
      }
      
      internal function frame9494() : *
      {
         gotoAndPlay("stun_idle_sword");
      }
      
      internal function frame9498() : *
      {
         gotoAndPlay("stun_idle_sword");
      }
      
      internal function frame9512() : *
      {
         gotoAndPlay("idle_hurt_sword");
      }
      
      internal function frame9520() : *
      {
         stop();
      }
      
      internal function frame9550() : *
      {
         gotoAndPlay("idle_hurt_sword");
      }
      
      internal function frame9554() : *
      {
         gotoAndPlay("ready_idle_sword");
      }
      
      internal function frame9562() : *
      {
         gotoAndPlay("ready_idle");
      }
      
      internal function frame9586() : *
      {
         stop();
      }
      
      internal function frame9604() : *
      {
         stop();
      }
      
      internal function frame9682() : *
      {
         stop();
      }
      
      internal function frame9717() : *
      {
         stop();
      }
      
      internal function frame9774() : *
      {
         stop();
      }
      
      internal function frame9893() : *
      {
         stop();
      }
      
      internal function frame9904() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("return");
      }
      
      internal function frame9914() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.auxiliary,"on");
      }
      
      internal function frame9932() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.auxiliary,"fire");
      }
      
      internal function frame9941() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.auxiliary,"fire");
      }
      
      internal function frame9950() : *
      {
         this.TIMELINE_ACTOR_gotoAndPlay(this.auxiliary,"fire");
      }
      
      internal function frame9961() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
      }
      
      internal function frame9987() : *
      {
         stop();
      }
      
      internal function frame10002() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("return");
         this.TIMELINE_ACTOR_gotoAndPlay(this.auxiliary,"on");
      }
      
      internal function frame10066() : *
      {
         this.TIMELINE_CHARACTER_turnWeapons("on");
         this.TIMELINE_ACTOR_gotoAndPlay(this.auxiliary,"off");
      }
      
      internal function frame10082() : *
      {
         stop();
      }
   }
}


package
{
   import AQWorlds.*;
   import EpicDuel.*;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.filesystem.File;
   import flash.geom.ColorTransform;
   import flash.geom.Rectangle;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2449")]
   public class sets extends MovieClip
   {
      
      public var active:MovieClip;
      
      public var create:SimpleButton;
      
      public var left:SimpleButton;
      
      public var remove:SimpleButton;
      
      public var right:SimpleButton;
      
      private const START_X:Number = 20.45;
      
      private const START_Y:Number = 3.45;
      
      private const SEPARATOR_X:Number = 30.5;
      
      public var items:Array = [];
      
      public var btns:Object = [];
      
      public var active_set:uint = 0;
      
      private var offset:int = 0;
      
      public function sets()
      {
         super();
         this.create.addEventListener(MouseEvent.CLICK,this.onCreate,false,0,true);
         this.remove.addEventListener(MouseEvent.CLICK,this.onRemove,false,0,true);
         this.left.addEventListener(MouseEvent.CLICK,this.onLeft,false,0,true);
         this.right.addEventListener(MouseEvent.CLICK,this.onRight,false,0,true);
         stage.addEventListener(MouseEvent.CLICK,this.onStageWalk,false,0,true);
         if(this.ActiveGame == "AQWorlds")
         {
            this.addEventListener(Event.ENTER_FRAME,this.checkForNewFile,false,0,true);
         }
         this.newSet();
      }
      
      private function itemType(param1:*, param2:String) : Function
      {
         switch(this.ActiveGame)
         {
            case "AQWorlds":
               switch(param2)
               {
                  case "Weapon":
                     return param1.pMC.onLoadWeaponComplete;
                  case "Helmet":
                     return param1.pMC.onLoadHelmComplete;
                  case "Hair":
                     return param1.pMC.onHairLoadComplete;
                  case "Cape":
                     return param1.pMC.onLoadCapeComplete;
                  case "Armor":
                     return param1.pMC.onLoadArmorComplete;
                  case "Ground":
                     return param1.pMC.onLoadMiscComplete;
                  case "Pet":
                     return param1.onLoadPetComplete;
               }
               break;
            case "EpicDuel":
               switch(param2)
               {
                  case "Primary":
                  case "Secondary":
                  case "Auxiliary":
                  case "Hair Above":
                  case "Hair":
                  case "Head":
                  case "Armor":
                  case "Craft":
                     return param1.assetCompleteHandler;
               }
         }
         return null;
      }
      
      private function checkForNewFile(param1:Event) : void
      {
         var _loc2_:int = 0;
         var _loc3_:Object = null;
         var _loc4_:Array = null;
         var _loc5_:File = null;
         var _loc6_:String = null;
         var _loc7_:Object = null;
         try
         {
            _loc2_ = 0;
            while(_loc2_ < this.items.length)
            {
               _loc3_ = this.items[_loc2_];
               if(!_loc3_)
               {
                  break;
               }
               _loc4_ = ["Weapon","Helmet","Hair","Cape","Armor","Ground","Pet"];
               for each(_loc6_ in _loc4_)
               {
                  _loc7_ = _loc3_["item_file_" + _loc6_];
                  if(_loc7_)
                  {
                     _loc5_ = new File(_loc7_.path);
                     if(_loc5_ != null)
                     {
                        if(_loc5_.modificationDate > _loc7_.date)
                        {
                           _loc7_.date = _loc5_.modificationDate;
                           _loc3_.avt.pMC.load(_loc7_.path,this.itemType(_loc3_.avt,_loc6_));
                        }
                     }
                  }
               }
               _loc2_++;
            }
         }
         catch(_:*)
         {
         }
      }
      
      public function get ActiveAvatar() : *
      {
         return this.items[this.active_set].avt;
      }
      
      public function get ActiveSet() : *
      {
         return this.items[this.active_set];
      }
      
      public function get Ancestor() : MovieClip
      {
         return MovieClip(MovieClip(parent).parent);
      }
      
      public function get ActiveGame() : String
      {
         return this.Ancestor._activeGame;
      }
      
      public function get ActiveAvatars() : Array
      {
         var _loc2_:* = undefined;
         var _loc3_:Boolean = false;
         var _loc1_:Array = [];
         for each(_loc2_ in this.items)
         {
            _loc3_ = this.ActiveGame == "AQWorlds" ? Boolean(_loc2_.avt.pMC.visible) : Boolean(_loc2_.avt.visible);
            if(_loc3_)
            {
               _loc1_.push(this.ActiveGame == "AQWorlds" ? _loc2_.avt.pMC : _loc2_.avt);
            }
         }
         return _loc1_;
      }
      
      public function ResetSets() : void
      {
         var _loc1_:* = undefined;
         for each(_loc1_ in this.items)
         {
            if(Boolean(this.ActiveGame == "AQWorlds") && Boolean(_loc1_.avt.petMC) && Boolean(_loc1_.avt.petMC.mcChar))
            {
               this.Ancestor.removeChild(_loc1_.avt.petMC);
            }
            this.Ancestor.removeChild(this.ActiveGame == "AQWorlds" ? _loc1_.avt.pMC : _loc1_.avt);
         }
         this.items = [];
         this.active_set = 0;
         this.newSet();
         MovieClip(parent).characters_content.SwitchGames();
      }
      
      public function SwitchGames() : void
      {
         var _loc1_:uint = 0;
         while(_loc1_ < this.items.length)
         {
            this.Ancestor.removeChild(this.ActiveGame == "EpicDuel" ? this.items[_loc1_].avt.pMC : this.items[_loc1_].avt);
            _loc1_++;
         }
         this.items = [];
         this.newSet();
      }
      
      public function ResizeAvatars(param1:Number) : void
      {
         var _loc2_:* = undefined;
         for each(_loc2_ in this.items)
         {
            switch(this.ActiveGame)
            {
               case "AQWorlds":
                  _loc2_.avt.pMC.scaleX = param1;
                  _loc2_.avt.pMC.scaleY = param1;
                  if(_loc2_.avt.petMC.mcChar != null)
                  {
                     _loc2_.avt.petMC.mcChar.scaleX = param1;
                     _loc2_.avt.petMC.mcChar.scaleY = param1;
                     _loc2_.avt.petMC.shadow.scaleX = param1;
                     _loc2_.avt.petMC.shadow.scaleY = param1;
                  }
                  break;
               case "EpicDuel":
                  _loc2_.avt.scaleX = param1 / 2;
                  _loc2_.avt.scaleY = param1 / 2;
            }
         }
      }
      
      private function onStageWalk(param1:MouseEvent) : void
      {
         if(this.items.length < 1)
         {
            return;
         }
         if(this.ActiveAvatar == null)
         {
            return;
         }
         if(param1.target != stage)
         {
            return;
         }
         switch(this.ActiveGame)
         {
            case "AQWorlds":
               this.Ancestor.setChildIndex(this.ActiveAvatar.pMC,this.Ancestor.numChildren - 1);
               this.ActiveAvatar.pMC.walkTo(stage.mouseX,stage.mouseY,16);
               if(this.ActiveAvatar.petMC.mcChar)
               {
                  this.Ancestor.setChildIndex(this.ActiveAvatar.petMC,this.Ancestor.numChildren - 1);
                  this.ActiveAvatar.petMC.turn(this.ActiveAvatar.pMC.mcChar.scaleX < 0 ? "left" : "right");
                  this.ActiveAvatar.petMC.walkTo(stage.mouseX - 20,stage.mouseY + 5,16 - 3);
               }
               break;
            case "EpicDuel":
               this.Ancestor.setChildIndex(this.ActiveAvatar,this.Ancestor.numChildren - 1);
               this.ActiveAvatar.walkTo(stage.mouseX,stage.mouseY,16);
         }
         this.Ancestor.LayerInterface();
      }
      
      public function newSet() : void
      {
         var _loc1_:* = undefined;
         var _loc2_:Rectangle = null;
         var _loc3_:Rectangle = stage.nativeWindow.bounds;
         var _loc4_:Object = {};
         switch(this.ActiveGame)
         {
            case "AQWorlds":
               _loc4_["weaponType"] = "Sword";
               _loc4_["itemLinks"] = {
                  "Weapon":"",
                  "Helmet":"",
                  "Hair":"",
                  "Cape":"",
                  "Armor":"",
                  "Ground":"",
                  "Pet":""
               };
               _loc4_["itemShow"] = {
                  "Weapon":true,
                  "Helmet":true,
                  "Hair":true,
                  "Back Hair":true,
                  "Cape":true,
                  "Robe":true,
                  "Back Robe":true,
                  "Ground":true,
                  "Pet":true
               };
               _loc1_ = new Avatar(this.Ancestor);
               _loc1_.pMC = new AvatarMC(this.Ancestor);
               _loc1_.pMC.pAV = _loc1_;
               _loc2_ = _loc1_.pMC.getBounds(this.Ancestor);
               _loc1_.pMC.x = (_loc3_.width - 248.2) / 2 - _loc2_.width / 2 + _loc2_.width / 2.3;
               _loc1_.pMC.y = (_loc3_.height - 32.25) / 2 - _loc2_.height / 2 + _loc2_.height / 1.2;
               _loc1_.pMC.scaleX = this.Ancestor._avatarScaling;
               _loc1_.pMC.scaleY = this.Ancestor._avatarScaling;
               this.Ancestor.addChild(_loc1_.pMC);
               break;
            case "EpicDuel":
               _loc4_["weaponType"] = "Blade";
               _loc4_["thighType"] = "Male Thigh";
               _loc4_["itemShow"] = {
                  "Player":true,
                  "Primary":true,
                  "Secondary":true,
                  "Auxiliary":true,
                  "Hair Above":false,
                  "Hair":true,
                  "Head":true,
                  "Craft":false
               };
               _loc1_ = new CharacterBase(this.Ancestor);
               _loc2_ = _loc1_.getBounds(this.Ancestor);
               _loc1_.x = (_loc3_.width - 248.2) / 2 - _loc2_.width / 2 + _loc2_.width / 2.3;
               _loc1_.y = (_loc3_.height - 32.25) / 2 - _loc2_.height / 2 + _loc2_.height;
               _loc1_.scaleX = this.Ancestor._avatarScaling / 2;
               _loc1_.scaleY = this.Ancestor._avatarScaling / 2;
               this.Ancestor.addChild(_loc1_);
         }
         this.Ancestor.LayerInterface();
         _loc4_["avt"] = _loc1_;
         this.items.push(_loc4_);
         this.UpdateList();
      }
      
      private function onLeft(param1:MouseEvent) : void
      {
         if(this.offset == 0)
         {
            return;
         }
         --this.offset;
         this.UpdateList();
      }
      
      private function onRight(param1:MouseEvent) : void
      {
         if(this.offset >= this.items.length - 1 || this.items.length <= 4)
         {
            return;
         }
         ++this.offset;
         this.UpdateList();
      }
      
      public function UpdateList() : void
      {
         while(numChildren > 7)
         {
            removeChildAt(7);
         }
         this.btns = {};
         var _loc1_:uint = 0;
         while(_loc1_ < Math.min(4,this.items.length))
         {
            if(!this.items[this.offset + _loc1_])
            {
               break;
            }
            this.btns[this.offset + _loc1_] = new setbtn((this.offset + _loc1_ + 1).toString());
            addChild(this.btns[this.offset + _loc1_]);
            this.btns[this.offset + _loc1_].x = this.START_X + this.SEPARATOR_X * _loc1_;
            this.btns[this.offset + _loc1_].y = this.START_Y;
            _loc1_++;
         }
         this.UpdateButtonBrightness();
         this.active.visible = this.btns[this.active_set];
         this.active.x = this.active.visible ? Number(this.btns[this.active_set].x) : this.START_X;
         this.active.x += 2;
      }
      
      public function UpdateButtonBrightness() : void
      {
         var _loc1_:* = undefined;
         var _loc2_:* = undefined;
         var _loc3_:Boolean = false;
         for(_loc1_ in this.btns)
         {
            _loc2_ = this.btns[_loc1_];
            switch(this.ActiveGame)
            {
               case "AQWorlds":
                  _loc3_ = !this.items[_loc1_].avt.pMC.visible;
                  break;
               case "EpicDuel":
                  _loc3_ = !this.items[_loc1_].avt.visible;
            }
            if(_loc3_)
            {
               _loc2_.transform.colorTransform = new ColorTransform(1,1,1,1,-127,-127,-127,0);
            }
            else
            {
               _loc2_.transform.colorTransform = new ColorTransform();
            }
         }
      }
      
      public function setActive(param1:int) : void
      {
         this.Ancestor.ClearCanvas();
         param1--;
         this.active_set = param1;
         switch(this.ActiveGame)
         {
            case "AQWorlds":
               MovieClip(parent).characters_content.buildAQWItems();
               break;
            case "EpicDuel":
               MovieClip(parent).characters_content.buildEDItems();
         }
         if(!this.btns[param1])
         {
            return;
         }
         this.UpdateButtonBrightness();
         this.active.x = this.btns[param1].x + 2;
         this.active.visible = true;
      }
      
      private function onCreate(param1:MouseEvent) : void
      {
         this.newSet();
      }
      
      private function onRemove(param1:MouseEvent) : void
      {
         if(this.items.length < 2)
         {
            return;
         }
         if(Boolean(this.ActiveGame == "AQWorlds") && Boolean(this.items[this.active_set].avt.petMC) && Boolean(this.items[this.active_set].avt.petMC.mcChar))
         {
            this.Ancestor.removeChild(this.items[this.active_set].avt.petMC);
         }
         this.Ancestor.removeChild(this.ActiveGame == "AQWorlds" ? this.items[this.active_set].avt.pMC : this.items[this.active_set].avt);
         this.items.splice(this.active_set,1);
         this.active_set = this.active_set - 1 < 0 ? 0 : uint(this.active_set - 1);
         this.UpdateList();
         MovieClip(parent).characters_content.SwitchGames();
      }
   }
}


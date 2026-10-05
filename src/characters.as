package
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.ui.Mouse;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2434")]
   public class characters extends MovieClip
   {
      
      public var visiblity:MovieClip;
      
      private const START_X:Number = 4.5;
      
      private const START_Y:Number = 37.55;
      
      private const SECTION_SEPARATOR:Number = 27.55;
      
      private const SECTION_CHILDS_SEPARATOR:Number = 26.1;
      
      private const SEPARATOR_Y:Number = 41;
      
      public var items:Array = [];
      
      public function characters()
      {
         super();
         this.visiblity.addEventListener(MouseEvent.CLICK,this.onVisibility,false,0,true);
         this.visiblity.addEventListener(MouseEvent.MOUSE_OVER,this.onOver,false,0,true);
         this.visiblity.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.SwitchGames();
      }
      
      private function onOver(param1:MouseEvent) : void
      {
         Mouse.cursor = "button";
      }
      
      private function onOut(param1:MouseEvent) : void
      {
         Mouse.cursor = "arrow";
      }
      
      public function get Ancestor() : MovieClip
      {
         return MovieClip(MovieClip(parent).parent);
      }
      
      public function get ActiveGame() : String
      {
         return this.Ancestor._activeGame;
      }
      
      public function get AvatarReady() : Boolean
      {
         return MovieClip(parent).setswitcher != null;
      }
      
      public function get ActiveAvatar() : *
      {
         return MovieClip(parent).setswitcher.ActiveAvatar;
      }
      
      public function get ActiveSet() : *
      {
         return MovieClip(parent).setswitcher.ActiveSet;
      }
      
      public function SwitchGames() : void
      {
         switch(this.ActiveGame)
         {
            case "AQWorlds":
               this.buildAQWItems();
               break;
            case "EpicDuel":
               this.buildEDItems();
         }
      }
      
      private function toggleVisibility(param1:Boolean) : Boolean
      {
         this.visiblity.toggle.gotoAndPlay(param1 ? "TurningOn" : "TurningOff");
         return this.visiblity.toggle.currentLabel == "On";
      }
      
      private function onVisibility(param1:MouseEvent) : void
      {
         this.visiblity.toggle.gotoAndPlay(this.visiblity.toggle.currentLabel == "On" ? "TurningOff" : "TurningOn");
         switch(this.ActiveGame)
         {
            case "AQWorlds":
               this.ActiveAvatar.pMC.visible = this.visiblity.toggle.currentLabel == "TurningOn";
               MovieClip(parent).setswitcher.UpdateButtonBrightness();
               break;
            case "EpicDuel":
               this.ActiveAvatar.visible = this.visiblity.toggle.currentLabel == "TurningOn";
               MovieClip(parent).setswitcher.UpdateButtonBrightness();
         }
      }
      
      public function buildAQWItems() : void
      {
         var _loc2_:Number = NaN;
         var _loc3_:Array = null;
         var _loc4_:String = null;
         var _loc5_:String = null;
         var _loc6_:uint = 0;
         while(this.numChildren > 1)
         {
            this.removeChildAt(1);
         }
         var _loc1_:uint = 0;
         this.items = [];
         if(this.AvatarReady && Boolean(this.ActiveAvatar))
         {
            this.toggleVisibility(this.ActiveAvatar.pMC.visible);
         }
         else
         {
            this.toggleVisibility(true);
         }
         _loc2_ = this.newSection("ITEM FILES");
         _loc3_ = ["Weapon","Helmet","Hair","Cape","Armor","Ground","Pet"];
         _loc1_ = 0;
         while(_loc1_ < _loc3_.length)
         {
            _loc4_ = _loc3_[_loc1_];
            this.instantiate(new itemfile(_loc4_));
            this.items[this.items.length - 1].x = this.START_X;
            this.items[this.items.length - 1].y = _loc2_ + this.SEPARATOR_Y * _loc1_;
            _loc1_++;
         }
         _loc2_ = this.newSection("COLOR CUSTOMIZATION");
         _loc3_ = ["Hair Color","Skin Color","Eye Color","Base Color","Trim Color","Accessory Color"];
         _loc1_ = 0;
         while(_loc1_ < _loc3_.length)
         {
            _loc5_ = _loc3_[_loc1_].split(" Color")[0];
            _loc6_ = this.ActiveSet["color_" + _loc5_] ? uint(this.ActiveSet["color_" + _loc5_].color) : uint(-1);
            this.instantiate(new colorcomponent(_loc3_[_loc1_],_loc6_));
            this.items[this.items.length - 1].x = this.START_X;
            this.items[this.items.length - 1].y = _loc2_ + (this.SEPARATOR_Y - 10) * _loc1_;
            _loc1_++;
         }
         _loc2_ = this.newSection("WEAPON TYPE");
         _loc3_ = ["Sword","Dagger","Gauntlet"];
         _loc1_ = 0;
         while(_loc1_ < _loc3_.length)
         {
            _loc4_ = _loc3_[_loc1_];
            this.instantiate(new radiocomponent(_loc4_,this.ActiveSet["weaponType"] == _loc4_));
            this.items[this.items.length - 1].x = this.START_X;
            this.items[this.items.length - 1].y = _loc2_ + 26 * _loc1_;
            _loc1_++;
         }
         _loc2_ = this.newSection("ITEM VISIBILITY");
         _loc3_ = ["Weapon","Helmet","Hair","Back Hair","Cape","Robe","Back Robe","Ground","Pet"];
         _loc1_ = 0;
         while(_loc1_ < _loc3_.length)
         {
            _loc4_ = _loc3_[_loc1_];
            this.instantiate(new optioncomponent(_loc4_,this.ActiveSet["itemShow"][_loc4_]));
            this.items[this.items.length - 1].x = this.START_X;
            this.items[this.items.length - 1].y = _loc2_ + 26 * _loc1_;
            _loc1_++;
         }
         _loc2_ = this.newSection("EXTRAS");
         _loc3_ = ["Combat Animations","PetBuff","PetAttack1","PetAttack2"];
         _loc1_ = 0;
         while(_loc1_ < _loc3_.length)
         {
            _loc4_ = _loc3_[_loc1_];
            this.instantiate(new buttoncomponent(_loc4_));
            this.items[this.items.length - 1].x = this.START_X;
            this.items[this.items.length - 1].y = _loc2_ + (26 + 16) * _loc1_;
            _loc1_++;
         }
      }
      
      public function buildEDItems() : void
      {
         var _loc2_:Number = NaN;
         var _loc3_:Array = null;
         var _loc4_:String = null;
         var _loc5_:String = null;
         var _loc6_:uint = 0;
         while(this.numChildren > 1)
         {
            this.removeChildAt(1);
         }
         var _loc1_:uint = 0;
         this.items = [];
         if(this.AvatarReady && Boolean(this.ActiveAvatar))
         {
            this.toggleVisibility(this.ActiveAvatar.visible);
         }
         else
         {
            this.toggleVisibility(true);
         }
         _loc2_ = this.newSection("ITEM FILES");
         _loc3_ = ["Primary","Secondary","Auxiliary","Hair Above","Hair","Head","Armor","Craft"];
         _loc1_ = 0;
         while(_loc1_ < _loc3_.length)
         {
            _loc4_ = _loc3_[_loc1_];
            this.instantiate(new itemfile(_loc4_));
            this.items[this.items.length - 1].x = this.START_X;
            this.items[this.items.length - 1].y = _loc2_ + this.SEPARATOR_Y * _loc1_;
            _loc1_++;
         }
         _loc2_ = this.newSection("COLOR CUSTOMIZATION");
         _loc3_ = ["Hair Color","Skin Color","Eye Color","Primary Color","Secondary Color","Accent Color","Accent 2 Color"];
         _loc1_ = 0;
         while(_loc1_ < _loc3_.length)
         {
            _loc5_ = _loc3_[_loc1_].split(" Color")[0];
            _loc6_ = this.ActiveSet["color_" + _loc5_] ? uint(this.ActiveSet["color_" + _loc5_].color) : uint(-1);
            this.instantiate(new colorcomponent(_loc3_[_loc1_],_loc6_));
            this.items[this.items.length - 1].x = this.START_X;
            this.items[this.items.length - 1].y = _loc2_ + (this.SEPARATOR_Y - 10) * _loc1_;
            _loc1_++;
         }
         _loc2_ = this.newSection("ARMOR TYPES");
         _loc3_ = ["Male Thigh","Female Thigh"];
         _loc1_ = 0;
         while(_loc1_ < _loc3_.length)
         {
            _loc4_ = _loc3_[_loc1_];
            this.instantiate(new radiocomponent(_loc4_,this.ActiveSet["thighType"] == _loc4_));
            this.items[this.items.length - 1].x = this.START_X;
            this.items[this.items.length - 1].y = _loc2_ + 26 * _loc1_;
            _loc1_++;
         }
         _loc2_ = this.newSection("PRIMARY WEAPON TYPE");
         _loc3_ = ["Blade","Staff","Wrist"];
         _loc1_ = 0;
         while(_loc1_ < _loc3_.length)
         {
            _loc4_ = _loc3_[_loc1_];
            this.instantiate(new radiocomponent(_loc4_,this.ActiveSet["weaponType"] == _loc4_));
            this.items[this.items.length - 1].x = this.START_X;
            this.items[this.items.length - 1].y = _loc2_ + 26 * _loc1_;
            _loc1_++;
         }
         _loc2_ = this.newSection("WEAPON FRAMES");
         _loc3_ = ["on","off"];
         _loc1_ = 0;
         while(_loc1_ < _loc3_.length)
         {
            _loc4_ = _loc3_[_loc1_];
            this.instantiate(new buttoncomponent(_loc4_));
            this.items[this.items.length - 1].x = this.START_X;
            this.items[this.items.length - 1].y = _loc2_ + (26 + 16) * _loc1_;
            _loc1_++;
         }
         _loc2_ = this.newSection("ITEM VISIBILITY");
         _loc3_ = ["Player","Primary","Secondary","Auxiliary","Hair Above","Hair","Head","Craft"];
         _loc1_ = 0;
         while(_loc1_ < _loc3_.length)
         {
            _loc4_ = _loc3_[_loc1_];
            this.instantiate(new optioncomponent(_loc4_,this.ActiveSet["itemShow"][_loc4_]));
            this.items[this.items.length - 1].x = this.START_X;
            this.items[this.items.length - 1].y = _loc2_ + 26 * _loc1_;
            _loc1_++;
         }
      }
      
      private function newSection(param1:String) : Number
      {
         this.instantiate(new sectiontext());
         this.items[this.items.length - 1].label.text = param1;
         this.items[this.items.length - 1].x = this.START_X + 0.15;
         if(this.items.length - 2 < 0)
         {
            this.items[this.items.length - 1].y = this.START_Y;
         }
         else
         {
            this.items[this.items.length - 1].y = this.items[this.items.length - 2].y + this.items[this.items.length - 2].height + this.SECTION_SEPARATOR;
         }
         return this.items[this.items.length - 1].y + this.SECTION_CHILDS_SEPARATOR;
      }
      
      private function instantiate(param1:*) : void
      {
         this.items.push(addChild(param1));
      }
   }
}


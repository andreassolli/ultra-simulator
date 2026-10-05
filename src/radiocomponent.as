package
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.ui.Mouse;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol99")]
   public class radiocomponent extends MovieClip
   {
      
      public var label:TextField;
      
      public var radio:MovieClip;
      
      private var active:Boolean;
      
      public function radiocomponent(param1:String, param2:Boolean)
      {
         super();
         this.label.text = param1;
         this.active = param2;
         this.radio.gotoAndStop(param2 ? "On" : "Off");
         this.addEventListener(MouseEvent.CLICK,this.onRadio,false,0,true);
         this.addEventListener(MouseEvent.MOUSE_OVER,this.onHover,false,0,true);
         this.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
      }
      
      private function IsolateActiveToSelf() : void
      {
         var _loc1_:* = undefined;
         for each(_loc1_ in MovieClip(parent).items)
         {
            if(_loc1_ is radiocomponent)
            {
               if(_loc1_.label.text == "Sword" || _loc1_.label.text == "Dagger" || _loc1_.label.text == "Gauntlet")
               {
                  if(_loc1_.label.text != this.label.text && Boolean(_loc1_.active))
                  {
                     _loc1_.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                  }
               }
            }
         }
      }
      
      private function ED_IsolateActiveToSelf() : void
      {
         var _loc1_:* = undefined;
         for each(_loc1_ in MovieClip(parent).items)
         {
            if(_loc1_ is radiocomponent)
            {
               if(_loc1_.label.text == "Male Thigh" || _loc1_.label.text == "Female Thigh")
               {
                  if(_loc1_.label.text != this.label.text && Boolean(_loc1_.active))
                  {
                     _loc1_.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                  }
               }
            }
         }
      }
      
      private function ED2_IsolateActiveToSelf() : void
      {
         var _loc1_:* = undefined;
         for each(_loc1_ in MovieClip(parent).items)
         {
            if(_loc1_ is radiocomponent)
            {
               if(_loc1_.label.text == "Blade" || _loc1_.label.text == "Staff" || _loc1_.label.text == "Wrist")
               {
                  if(_loc1_.label.text != this.label.text && Boolean(_loc1_.active))
                  {
                     _loc1_.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                  }
               }
            }
         }
      }
      
      private function onRadio(param1:MouseEvent) : void
      {
         var _loc2_:* = undefined;
         switch(MovieClip(parent).ActiveGame)
         {
            case "AQWorlds":
               _loc2_ = MovieClip(parent).ActiveAvatar.pMC;
               break;
            case "EpicDuel":
               _loc2_ = MovieClip(parent).ActiveAvatar;
         }
         var _loc3_:* = MovieClip(parent).ActiveSet;
         if((_loc3_["thighType"] == this.label.text || _loc3_["weaponType"] == this.label.text) && this.active)
         {
            return;
         }
         this.active = !this.active;
         this.radio.gotoAndStop(this.active ? "On" : "Off");
         switch(this.label.text)
         {
            case "Sword":
            case "Dagger":
            case "Gauntlet":
               if(this.active)
               {
                  _loc3_["weaponType"] = this.label.text;
                  if(_loc3_["itemLinks"]["Weapon"] != "")
                  {
                     _loc2_.load(_loc3_["item_file_Weapon"].path,_loc2_.onLoadWeaponComplete);
                  }
                  this.IsolateActiveToSelf();
               }
               break;
            case "Male Thigh":
            case "Female Thigh":
               if(this.active)
               {
                  _loc3_["thighType"] = this.label.text;
                  _loc2_.swapThighs();
                  this.ED_IsolateActiveToSelf();
               }
               break;
            case "Blade":
            case "Staff":
            case "Wrist":
               if(this.active)
               {
                  _loc3_["weaponType"] = this.label.text;
                  _loc2_.swapPrimary();
                  this.ED2_IsolateActiveToSelf();
               }
         }
      }
      
      private function onHover(param1:MouseEvent) : void
      {
         Mouse.cursor = "button";
         if(this.radio.currentLabel == "Off")
         {
            this.radio.gotoAndStop("OffHover");
         }
      }
      
      private function onOut(param1:MouseEvent) : void
      {
         Mouse.cursor = "arrow";
         if(this.radio.currentLabel == "OffHover")
         {
            this.radio.gotoAndStop("Off");
         }
      }
   }
}

